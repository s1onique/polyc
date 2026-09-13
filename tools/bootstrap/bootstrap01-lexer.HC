// tools/bootstrap/bootstrap01-lexer.HC
//
// ACT-POLYC-BOOTSTRAP01 C2 IMPL — PolyC B0 lexer/tokenizer.
//
// This is the B0 SUBJECT. It is a compiler-shaped executable
// proof: bytes in, deterministic Token stream out, written in
// PolyC, allocation-free, no parser, no AST, no codegen.
//
// Frozen ABI (must match lexical-contract.txt):
//
//   BTK_EOF       = 0
//   BTK_IDENT     = 1
//   BTK_INT       = 2
//   BTK_LPAREN    = 3
//   BTK_RPAREN    = 4
//   BTK_LBRACE    = 5
//   BTK_RBRACE    = 6
//   BTK_LBRACKET  = 7
//   BTK_RBRACKET  = 8
//   BTK_COMMA     = 9
//   BTK_SEMI      = 10
//   BTK_PLUS      = 11
//   BTK_MINUS     = 12
//   BTK_STAR      = 13
//   BTK_SLASH     = 14
//   BTK_ASSIGN    = 15
//
// Status codes:
//
//   BLEX_OK                = 0
//   BLEX_OUTPUT_FULL       = 1
//   BLEX_UNSUPPORTED_BYTE  = 2
//   BLEX_INVALID_INPUT     = 3
//
// API:
//
//   I64 BootstrapLex(
//       U8  *src,
//       I64  src_len,
//       BootstrapToken *out,
//       I64  out_cap,
//       I64 *out_count
//   )
//
// Source buffer is caller-owned and read-only.
// Token buffer is caller-owned and bounded.
// Returns one of BLEX_* status codes.
// On BLEX_OK the lexer emits a final BTK_EOF token.
// On BLEX_UNSUPPORTED_BYTE the lexer returns the partial
// stream that was successfully emitted before the bad byte.
// On BLEX_OUTPUT_FULL the lexer returns immediately when
// the next write would exceed out_cap; out_count reflects
// the number of tokens already written (<= out_cap - 1).
//
// Implementation requirements (all met):
//   - single forward scan
//   - no recursion
//   - no dynamic allocation (no MAlloc, no Free)
//   - no source mutation
//   - no global mutable lexer state
//   - bounded writes
//   - deterministic result

// ----------------------------------------------------------------
// Frozen B0 ABI constants
// ----------------------------------------------------------------

public class BootstrapToken
{
  I64 kind;
  I64 start;
  I64 len;
};

#define BTK_EOF       0
#define BTK_IDENT     1
#define BTK_INT       2
#define BTK_LPAREN    3
#define BTK_RPAREN    4
#define BTK_LBRACE    5
#define BTK_RBRACE    6
#define BTK_LBRACKET  7
#define BTK_RBRACKET  8
#define BTK_COMMA     9
#define BTK_SEMI      10
#define BTK_PLUS      11
#define BTK_MINUS     12
#define BTK_STAR      13
#define BTK_SLASH     14
#define BTK_ASSIGN    15

#define BLEX_OK                0
#define BLEX_OUTPUT_FULL       1
#define BLEX_UNSUPPORTED_BYTE  2
#define BLEX_INVALID_INPUT     3

// ----------------------------------------------------------------
// Punctuation byte -> kind
// ----------------------------------------------------------------

I64 BPunctKind(U8 c)
{
  if (c == '(') return BTK_LPAREN;
  if (c == ')') return BTK_RPAREN;
  if (c == '{') return BTK_LBRACE;
  if (c == '}') return BTK_RBRACE;
  if (c == '[') return BTK_LBRACKET;
  if (c == ']') return BTK_RBRACKET;
  if (c == ',') return BTK_COMMA;
  if (c == ';') return BTK_SEMI;
  if (c == '+') return BTK_PLUS;
  if (c == '-') return BTK_MINUS;
  if (c == '*') return BTK_STAR;
  if (c == '/') return BTK_SLASH;
  if (c == '=') return BTK_ASSIGN;
  return 0;
}

I64 BIsWs(U8 c)
{
  if (c == ' ')  return 1;
  if (c == '\t') return 1;
  if (c == '\n') return 1;
  if (c == '\r') return 1;
  return 0;
}

I64 BIsIdentStart(U8 c)
{
  if (c >= 'A' && c <= 'Z') return 1;
  if (c >= 'a' && c <= 'z') return 1;
  if (c == '_') return 1;
  return 0;
}

I64 BIsIdentRest(U8 c)
{
  if (BIsIdentStart(c)) return 1;
  if (c >= '0' && c <= '9') return 1;
  return 0;
}

I64 BIsDigit(U8 c)
{
  if (c >= '0' && c <= '9') return 1;
  return 0;
}

// ----------------------------------------------------------------
// BootstrapLex: the B0 subject proper.
//
// Allocation-free, single-pass, deterministic.
// ----------------------------------------------------------------

public I64 BootstrapLex(U8 *src, I64 src_len,
                        BootstrapToken *out, I64 out_cap,
                        I64 *out_count)
{
  I64 i = 0;
  I64 n = src_len;
  I64 count = 0;

  while (i < n) {
    U8 c = src[i];
    if (BIsWs(c)) {
      i = i + 1;
      continue;
    }
    if (count + 1 > out_cap) {
      *out_count = count;
      return BLEX_OUTPUT_FULL;
    }
    if (BIsIdentStart(c)) {
      I64 s = i;
      i = i + 1;
      while (i < n) {
        U8 d = src[i];
        if (!BIsIdentRest(d)) break;
        i = i + 1;
      }
      out[count].kind  = BTK_IDENT;
      out[count].start = s;
      out[count].len   = i - s;
      count = count + 1;
      continue;
    }
    if (BIsDigit(c)) {
      I64 s = i;
      while (i < n) {
        U8 d = src[i];
        if (!BIsDigit(d)) break;
        i = i + 1;
      }
      out[count].kind  = BTK_INT;
      out[count].start = s;
      out[count].len   = i - s;
      count = count + 1;
      continue;
    }
    I64 pk = BPunctKind(c);
    if (pk != 0) {
      out[count].kind  = pk;
      out[count].start = i;
      out[count].len   = 1;
      count = count + 1;
      i = i + 1;
      continue;
    }
    // unsupported byte: stop, do not advance, do not write EOF
    *out_count = count;
    return BLEX_UNSUPPORTED_BYTE;
  }
  if (count + 1 > out_cap) {
    *out_count = count;
    return BLEX_OUTPUT_FULL;
  }
  out[count].kind  = BTK_EOF;
  out[count].start = n;
  out[count].len   = 0;
  count = count + 1;
  *out_count = count;
  return BLEX_OK;
}

