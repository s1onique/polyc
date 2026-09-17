// tools/bootstrap/selfhost-lexer-trivia.HC
//
// ACT-POLYC-SELFHOST-LEXER03 C2 IMPL -- PolyC trivia (comment +
// whitespace) cursor-advance + line-accounting component.
//
// WINNER SUBJECT (trivia_scanner). Self-contained compiler-shaped
// executable proof: bytes in, (end_cursor, kind, lineno_delta,
// comment_started) out, written in PolyC, allocation-free, no AST,
// no parser mutation.
//
// Frozen ABI (must match
// evidence/ACT-POLYC-SELFHOST-LEXER03/c1/c1-target-behavioral-contract.txt
// and tools/quality/lexer08-trivia-oracle.c):
//
//   I64 BootstrapScanTrivia(
//       U8  *src,
//       I64  src_len,
//       I64  cursor,
//       I64  flags,
//       I64 *out_end,
//       I64 *out_kind,
//       I64 *out_lineno_delta,
//       I64 *out_comment_started
//   );
//
// Result kinds (frozen; matching c1-target-behavioral-contract.txt):
//   TRIVIA_NONE     0  -- not a trivia byte at cursor; no consumption
//   TRIVIA_WS       1  -- single whitespace byte (consumed 1 byte)
//   TRIVIA_NL       2  -- single newline byte   (consumed 1 byte)
//   TRIVIA_COMMENT  3  -- full comment span consumed (// .. \n or /* .. */)
//
// Character domain (binding):
//   LEXER03_TRIVIA_CHARACTER_DOMAIN      = ASCII
//   LEXER03_TRIVIA_CTYPE_DEPENDENCY       = NONE
//   LEXER03_TRIVIA_NON_ASCII_EQUIVALENCE  = NOT_CLAIMED

#define TRIVIA_NONE       0
#define TRIVIA_WS         1
#define TRIVIA_NL         2
#define TRIVIA_COMMENT    3

#define TRIVIA_CCF_ASM_BLOCK         (1 << 4)
#define TRIVIA_CCF_ACCEPT_WHITESPACE (1 << 6)
#define TRIVIA_CCF_ACCEPT_NEWLINES   (1 << 2)
#define TRIVIA_CCF_ACCEPT_COMMENTS   (1 << 7)

// Safe byte fetch: returns 0 if pos >= src_len (the legacy C
// implementation also reads past src_len via its '\0'-terminated
// buffer model, but the explicit bound makes the ABI testable
// against a tightly-bounded fixture).
U8 TR_Peek(U8 *src, I64 src_len, I64 pos)
{
  if (pos < 0) return 0;
  if (pos >= src_len) return 0;
  return src[pos];
}

// Forward single whitespace byte under CCF_ACCEPT_WHITESPACE.
// Returns 1 and emits TRIVIA_WS if consumed; otherwise emits
// TRIVIA_NONE with end=cursor+1 (caller sees the cursor advanced).
I64 TR_TryWhitespace(U8 *src, I64 src_len, I64 cursor, I64 flags,
                     I64 *out_end, I64 *out_kind, I64 *out_lineno_delta)
{
  U8 ch = TR_Peek(src, src_len, cursor);
  if (ch == ' ' || ch == '\t') {
    *out_end = cursor + 1;
    if (flags & TRIVIA_CCF_ACCEPT_WHITESPACE) {
      *out_kind = TRIVIA_WS;
      *out_lineno_delta = 0;
      return 1;
    }
    *out_kind = TRIVIA_NONE;
    *out_lineno_delta = 0;
    return 0;
  }
  return -1;  // not a whitespace byte
}

// Forward single newline byte under CCF_ACCEPT_NEWLINES.
// '\r' alone (without '\n') is treated as a CR-only newline for
// portability: lineno delta is 0 for '\r' alone (matches the legacy
// lexSkipCodeComment / lexCore whitespace logic that increments
// lineno on '\n' but not on '\r').
I64 TR_TryNewline(U8 *src, I64 src_len, I64 cursor, I64 flags,
                  I64 *out_end, I64 *out_kind, I64 *out_lineno_delta)
{
  U8 ch = TR_Peek(src, src_len, cursor);
  if (ch == '\n' || ch == '\r') {
    I64 nl_delta;
    if (ch == '\n') nl_delta = 1;
    else nl_delta = 0;
    *out_end = cursor + 1;
    if (flags & TRIVIA_CCF_ACCEPT_NEWLINES) {
      *out_kind = TRIVIA_NL;
      *out_lineno_delta = nl_delta;
      return 1;
    }
    *out_kind = TRIVIA_NONE;
    *out_lineno_delta = nl_delta;
    return 0;
  }
  return -1;  // not a newline byte
}

// Forward a '// comment' to its terminating '\n' (or '\0' / EOF).
// Does NOT consume the terminating '\n' (the legacy behavior in
// lexSkipCodeComment stops AT '\n'; the wrapper sees '\n' as a
// separate trivia candidate in the next iteration).
I64 TR_TryLineComment(U8 *src, I64 src_len, I64 cursor, I64 flags,
                      I64 *out_end, I64 *out_kind, I64 *out_lineno_delta,
                      I64 *out_comment_started)
{
  U8 ch = TR_Peek(src, src_len, cursor);
  U8 next = TR_Peek(src, src_len, cursor + 1);
  if (ch != '/' || next != '/') return -1;

  *out_comment_started = 1;
  I64 p = cursor + 2;
  I64 delta = 0;
  while (p < src_len) {
    U8 b = src[p];
    if (b == '\n') break;
    if (b == '\0') break;
    p++;
  }
  *out_end = p;
  *out_lineno_delta = delta;
  if (flags & TRIVIA_CCF_ACCEPT_COMMENTS) {
    *out_kind = TRIVIA_COMMENT;
    return 1;
  }
  *out_kind = TRIVIA_NONE;
  return 0;
}

// Forward a '/* ... */' block comment to its closing '*/'.
// '\n' bytes inside the block increment the lineno delta (matching
// the legacy lexSkipCodeComment behavior).
// Truncated at EOF: if we hit '\0' or src_len without seeing '*/',
// we treat the comment as running to EOF (no raise; matches the
// legacy "editor reality" behavior in lexSkipCodeComment).
I64 TR_TryBlockComment(U8 *src, I64 src_len, I64 cursor, I64 flags,
                       I64 *out_end, I64 *out_kind, I64 *out_lineno_delta,
                       I64 *out_comment_started)
{
  U8 ch = TR_Peek(src, src_len, cursor);
  U8 next = TR_Peek(src, src_len, cursor + 1);
  if (ch != '/' || next != '*') return -1;

  *out_comment_started = 1;
  I64 p = cursor + 2;
  I64 delta = 0;
  while (p < src_len) {
    U8 b = src[p];
    if (b == '\0') break;
    if (b == '*') {
      U8 bnext = TR_Peek(src, src_len, p + 1);
      if (bnext == '/') {
        p += 2;
        *out_end = p;
        *out_lineno_delta = delta;
        if (flags & TRIVIA_CCF_ACCEPT_COMMENTS) {
          *out_kind = TRIVIA_COMMENT;
          return 1;
        }
        *out_kind = TRIVIA_NONE;
        return 0;
      }
    }
    if (b == '\n') {
      delta++;
    }
    p++;
  }
  // Truncated at EOF: consume up to end-of-buffer (no raise).
  *out_end = p;
  *out_lineno_delta = delta;
  if (flags & TRIVIA_CCF_ACCEPT_COMMENTS) {
    *out_kind = TRIVIA_COMMENT;
    return 1;
  }
  *out_kind = TRIVIA_NONE;
  return 0;
}

// Top-level dispatcher.
I64 BootstrapScanTrivia(U8 *src, I64 src_len, I64 cursor, I64 flags,
                        I64 *out_end, I64 *out_kind,
                        I64 *out_lineno_delta, I64 *out_comment_started)
{
  // Default state.
  *out_end = cursor;
  *out_kind = TRIVIA_NONE;
  *out_lineno_delta = 0;
  *out_comment_started = 0;

  // Bound checks (matches legacy lexCore fallthrough).
  if (cursor < 0) return 0;
  if (cursor >= src_len) return 0;

  // Whitespace (single byte).
  {
    I64 rc = TR_TryWhitespace(src, src_len, cursor, flags,
                              out_end, out_kind, out_lineno_delta);
    if (rc >= 0) return rc;
  }

  // Newline (single byte).
  {
    I64 rc = TR_TryNewline(src, src_len, cursor, flags,
                           out_end, out_kind, out_lineno_delta);
    if (rc >= 0) return rc;
  }

  // // line comment.
  {
    I64 rc = TR_TryLineComment(src, src_len, cursor, flags,
                               out_end, out_kind, out_lineno_delta,
                               out_comment_started);
    if (rc >= 0) return rc;
  }

  // /* block comment.
  {
    I64 rc = TR_TryBlockComment(src, src_len, cursor, flags,
                                out_end, out_kind, out_lineno_delta,
                                out_comment_started);
    if (rc >= 0) return rc;
  }

  // Not a trivia byte.
  *out_end = cursor;
  *out_kind = TRIVIA_NONE;
  *out_lineno_delta = 0;
  *out_comment_started = 0;
  return 0;
}
