// tools/bootstrap/selfhost-lexer-link.HC
//
// ACT-POLYC-SELFHOST-LEXER04 C2 IMPL -- PolyC `#link`
// directive scanner.
//
// This file is the WINNER SUBJECT. It owns the byte-level
// scanning for the `#link` preprocessor directive once the
// `#link` keyword itself has been consumed by lexCore/lexToken.
//
// Scope (frozen by c1/c1-scope-freeze.txt):
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
//   - any of lexSetAsmFlags / lexUnSetAsmFlags
//
// Frozen ABI (must match c2-link-abi.txt):
//
//   I64 BootstrapLinkDirective(
//       U8  *src,
//       I64  src_len,
//       I64  flags,
//       I64 *out_consumed,
//       I64 *out_is_path,
//       I64 *out_stored_len,
//       I64 *out_error
//   );
//
// Inputs:
//   src        - pointer to the byte immediately AFTER the `#link`
//                keyword's terminating space; that is, the first
//                byte of the directive's target token ("\"", '<',
//                ident, digit, or end-of-input).
//   src_len    - bounded length of the remaining input from src.
//                Equivalent to strlen(src) at call time but the
//                wrapper passes an explicit bound so the scanner
//                never reads past EOF.
//   flags      - l->flags (CCF_*). Currently unused (the directive
//                does not branch on flags; recorded for ABI
//                stability with other self-host components).
//
// Outputs (on success, out_error == 0):
//   out_consumed   - total bytes consumed from src by this call,
//                    i.e. how many bytes the C wrapper must
//                    advance l->ptr by.
//   out_is_path    - 1 if the target was a quoted string (path
//                    form, lands in cc->shared_object_files); 0
//                    if it was the angle-bracket form (name form,
//                    lands in cc->link_libs).
//   out_stored_len - number of bytes in the name/path string,
//                    excluding any quotes or angle brackets. This
//                    is what the C wrapper passes to aoStrDupRaw
//                    to produce the canonical stored AoStr.
//   out_error      - 0 on success; 1..5 for the five error classes.
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

I64 LinkScanQuoted(U8 *src, I64 src_len, I64 *out_consumed,
                   I64 *out_stored_len, I64 *out_error)
{
  if (LinkPeek(src, src_len, 0) != '"') {
    *out_consumed   = 0;
    *out_stored_len = 0;
    *out_error      = LINK_ERR_INVALID_TOK;
    return LINK_ERR_INVALID_TOK;
  }
  I64 i = 1;
  while (i < src_len) {
    I64 ch = LinkPeek(src, src_len, i);
    if (ch == '\\') {
      i = i + 2;
      continue;
    }
    if (ch == '"') {
      *out_consumed   = i + 1;
      *out_stored_len = i - 1;
      *out_error      = LINK_OK;
      return LINK_OK;
    }
    i = i + 1;
  }
  *out_consumed   = 0;
  *out_stored_len = 0;
  *out_error      = LINK_ERR_UNTERM_QUOT;
  return LINK_ERR_UNTERM_QUOT;
}

I64 LinkScanAngle(U8 *src, I64 src_len, I64 *out_consumed,
                  I64 *out_stored_len, I64 *out_error)
{
  if (LinkPeek(src, src_len, 0) != '<') {
    *out_consumed   = 0;
    *out_stored_len = 0;
    *out_error      = LINK_ERR_INVALID_TOK;
    return LINK_ERR_INVALID_TOK;
  }
  I64 i = 1;
  I64 body_bytes = 0;
  while (i < src_len) {
    I64 ch = LinkPeek(src, src_len, i);
    if (ch == '>') {
      *out_consumed   = i + 1;
      *out_stored_len = body_bytes;
      *out_error      = LINK_OK;
      return LINK_OK;
    }
    if (ch == -1) break;
    body_bytes = body_bytes + 1;
    i = i + 1;
  }
  *out_consumed   = 0;
  *out_stored_len = 0;
  *out_error      = LINK_ERR_UNTERM_ANG;
  return LINK_ERR_UNTERM_ANG;
}

// Frozen ABI entry point. See file-level comment.
I64 BootstrapLinkDirective(U8 *src, I64 src_len, I64 flags,
                           I64 *out_consumed, I64 *out_is_path,
                           I64 *out_stored_len, I64 *out_error)
{
  // flags is part of the ABI but not consulted in this slice;
  // the directive does not branch on l->flags.
  flags = flags;

  *out_consumed   = 0;
  *out_is_path    = 0;
  *out_stored_len = 0;
  *out_error      = LINK_OK;

  if (src_len == 0) {
    *out_error = LINK_ERR_MISSING;
    return LINK_ERR_MISSING;
  }

  I64 first = LinkPeek(src, src_len, 0);
  if (first == '<') {
    return LinkScanAngle(src, src_len, out_consumed,
                         out_stored_len, out_error);
  }
  if (first == '"') {
    I64 rc = LinkScanQuoted(src, src_len, out_consumed,
                            out_stored_len, out_error);
    if (rc == LINK_OK) *out_is_path = 1;
    return rc;
  }
  *out_error = LINK_ERR_INVALID_TOK;
  return LINK_ERR_INVALID_TOK;
}

