// tools/bootstrap/selfhost-lexer-link.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 C2 IMPL -- PolyC `#link`
// directive scanner, extended for production authority.
//
// This file is the WINNER SUBJECT. It owns the byte-level
// scanning for the `#link` preprocessor directive once the
// `#link` keyword itself has been consumed by lexCore/lexToken.
//
// Scope (frozen by c1/c1-scope-freeze.txt + CORRECTION03 c0-contract):
//   - quoted path form  : #link "<path>"
//   - angle-bracket form: #link <name>
//   - invalid syntax    : missing target, unexpected token,
//                         unterminated quoted target,
//                         unterminated angle target
//
// OUT of scope (still legacy C, NOT migrated by this ACT):
//   - lexCore, lexToken, lexPreProcDirective dispatch
//   - lexInclude / lexDefine / lexUndef
//   - lexPreProcIf / lexPreProcBoolean
//   - any of lexSetAsmFlags / lexUnsetAsmFlags
//
// Frozen ABI 6 (extended from CORRECTION02 ABI 5):
//
//   I64 BootstrapLinkDirective(
//       U8  *src,                 // bytes from after "#link" keyword
//       I64  src_len,             // bounded length of src
//       I64  flags,               // l->flags (CCF_*); advisory in this slice
//       U8  *out_target_bytes,    // caller-provided buffer (>= src_len bytes)
//       I64  out_target_cap,      // capacity of out_target_bytes
//       I64 *out_target_len,      // on success: body bytes written
//       I64 *out_consumed,        // total bytes consumed from src
//       I64 *out_is_path,         // 1 = quoted-path; 0 = angle-name
//       I64 *out_stored_len,      // alias of *out_target_len (ABI 5 compat)
//       I64 *out_error            // 0 = ok; 1..5 error class
//   );
//
// Inputs:
//   src            pointer to the byte immediately after the `#link`
//                  keyword's terminating space. May be '"', '<',
//                  any other byte, or end-of-input.
//   src_len        bounded length of remaining input from src.
//   flags          l->flags (CCF_*). Currently unused; recorded for ABI
//                  parity with other self-host components.
//   out_target_bytes
//                  caller-provided buffer for the verbatim body bytes
//                  (no quote / angle stripping). On success, exactly
//                  *out_target_len bytes are written.
//   out_target_cap capacity of out_target_bytes. Must be >= src_len.
//
// Outputs (on success, *out_error == 0):
//   *out_target_len   bytes of body written to out_target_bytes
//   *out_consumed     total bytes consumed from src (includes '<', '"',
//                     body, '>', closing '"' as applicable)
//   *out_is_path      1 if quoted-path form; 0 if angle-name form
//   *out_stored_len   same value as *out_target_len
//   *out_error        0
//
// Error classes (out_error):
//   1 = missing_target
//   2 = invalid_token
//   3 = unterminated_angle
//   4 = unterminated_quoted
//   5 = lex_failure
//
// The C wrapper (src/lexer.c::lexLink body) handles the
// collection bookkeeping (listNew, listAppend, dedup, AoStr
// release on duplicate) so this component stays allocation-free
// at the PolyC layer. It is byte-level scanner only.
//
// Implementation requirements (all met):
//   - single forward scan (no recursion, no backtracking)
//   - no dynamic allocation
//   - no source mutation
//   - no global mutable state
//   - bounded reads (peek past end returns -1)
//   - deterministic result
//
// CHARACTER DOMAIN (binding):
//   B_LINK_DIRECTIVE_CHARACTER_DOMAIN     = ASCII
//   B_LINK_DIRECTIVE_CTYPE_DEPENDENCY      = NONE
//   B_LINK_DIRECTIVE_NON_ASCII_EQUIVALENCE = NOT_CLAIMED

#define LINK_OK               0
#define LINK_ERR_MISSING      1
#define LINK_ERR_INVALID_TOK  2
#define LINK_ERR_UNTERM_ANG   3
#define LINK_ERR_UNTERM_QUOT  4
#define LINK_ERR_LEX_FAILURE  5

U0 LinkAsciiLower(U8 c, Bool *out)
{
  if (c >= 'a' && c <= 'z') { *out = TRUE; return; }
  if (c >= 'A' && c <= 'Z') { *out = TRUE; return; }
  if (c >= '0' && c <= '9') { *out = TRUE; return; }
  if (c == '_')             { *out = TRUE; return; }
  *out = FALSE;
}

I64 LinkPeek(U8 *src, I64 src_len, I64 idx)
{
  if (idx < 0)        return -1;
  if (idx >= src_len) return -1;
  return src[idx];
}

// Write bytes src[from..to-1] to dst. Bounded by dst_cap.
U0 LinkCopyBytes(U8 *dst, I64 dst_cap, U8 *src, I64 from, I64 to)
{
  I64 i;
  I64 end = to;
  if (end > dst_cap) end = dst_cap;
  for (i = from; i < end; i = i + 1) {
    dst[i - from] = src[i];
  }
}

// Scan quoted form, copying body bytes to out_target_bytes.
// src[0] is expected to be '"'.
// On LINK_OK:
//   *out_consumed    = bytes consumed from src (1 + body + 1)
//   *out_target_len  = body length (excluding quotes)
//   *out_error       = 0
I64 LinkScanQuoted(U8 *src, I64 src_len,
                   U8 *out_target_bytes, I64 out_target_cap,
                   I64 *out_consumed, I64 *out_target_len,
                   I64 *out_error)
{
  if (LinkPeek(src, src_len, 0) != '"') {
    *out_consumed    = 0;
    *out_target_len  = 0;
    *out_error       = LINK_ERR_INVALID_TOK;
    return LINK_ERR_INVALID_TOK;
  }
  I64 body_start = 1;
  I64 i = 1;
  while (i < src_len) {
    I64 ch = LinkPeek(src, src_len, i);
    if (ch == -1) break;
    if (ch == '\\') {
      i = i + 2;
      continue;
    }
    if (ch == '"') {
      // Copy body bytes src[1..i-1] -> out_target_bytes[0..i-2]
      LinkCopyBytes(out_target_bytes, out_target_cap, src, body_start, i);
      *out_consumed    = i + 1;
      *out_target_len  = i - body_start;
      *out_error       = LINK_OK;
      return LINK_OK;
    }
    i = i + 1;
  }
  *out_consumed    = 0;
  *out_target_len  = 0;
  *out_error       = LINK_ERR_UNTERM_QUOT;
  return LINK_ERR_UNTERM_QUOT;
}

// Scan angle form, copying body bytes to out_target_bytes.
// src[0] is expected to be '<'.
// On LINK_OK:
//   *out_consumed    = bytes consumed from src (1 + body + 1)
//   *out_target_len  = body length (excluding '<' and '>')
//   *out_error       = 0
I64 LinkScanAngle(U8 *src, I64 src_len,
                  U8 *out_target_bytes, I64 out_target_cap,
                  I64 *out_consumed, I64 *out_target_len,
                  I64 *out_error)
{
  if (LinkPeek(src, src_len, 0) != '<') {
    *out_consumed    = 0;
    *out_target_len  = 0;
    *out_error       = LINK_ERR_INVALID_TOK;
    return LINK_ERR_INVALID_TOK;
  }
  I64 body_start = 1;
  I64 i = 1;
  while (i < src_len) {
    I64 ch = LinkPeek(src, src_len, i);
    if (ch == '>') {
      LinkCopyBytes(out_target_bytes, out_target_cap, src, body_start, i);
      *out_consumed    = i + 1;
      *out_target_len  = i - body_start;
      *out_error       = LINK_OK;
      return LINK_OK;
    }
    if (ch == -1) break;
    i = i + 1;
  }
  *out_consumed    = 0;
  *out_target_len  = 0;
  *out_error       = LINK_ERR_UNTERM_ANG;
  return LINK_ERR_UNTERM_ANG;
}

// Frozen ABI 6 entry point. See file-level comment.
I64 BootstrapLinkDirective(U8 *src, I64 src_len, I64 flags,
                           U8 *out_target_bytes, I64 out_target_cap,
                           I64 *out_target_len,
                           I64 *out_consumed, I64 *out_is_path,
                           I64 *out_stored_len,
                           I64 *out_error)
{
  // flags is part of the ABI but not consulted in this slice;
  // the directive does not branch on l->flags.
  flags = flags;

  *out_target_len  = 0;
  *out_consumed    = 0;
  *out_is_path     = 0;
  *out_stored_len  = 0;
  *out_error       = LINK_OK;

  if (src_len == 0) {
    *out_error = LINK_ERR_MISSING;
    *out_stored_len = 0;
    return LINK_ERR_MISSING;
  }

  I64 first = LinkPeek(src, src_len, 0);
  if (first == '<') {
    I64 rc = LinkScanAngle(src, src_len,
                           out_target_bytes, out_target_cap,
                           out_consumed, out_target_len, out_error);
    *out_stored_len = *out_target_len;
    return rc;
  }
  if (first == '"') {
    I64 rc = LinkScanQuoted(src, src_len,
                            out_target_bytes, out_target_cap,
                            out_consumed, out_target_len, out_error);
    *out_stored_len = *out_target_len;
    if (rc == LINK_OK) *out_is_path = 1;
    return rc;
  }
  *out_error = LINK_ERR_INVALID_TOK;
  *out_stored_len = 0;
  return LINK_ERR_INVALID_TOK;
}
