// tools/bootstrap/selfhost-lexer-scalar-literal.HC
//
// ACT-POLYC-SELFHOST-LEXER02 C2 IMPL — PolyC scalar
// literal scanning component.
//
// WINNER SUBJECT (scalar_literal_scanner). Self-contained
// compiler-shaped executable proof: bytes in, kind +
// integer/float/char value out, written in PolyC,
// allocation-free, no AST, no parser mutation.
//
// Frozen ABI (must match
// evidence/ACT-POLYC-SELFHOST-LEXER02/c1/region-abi-contract.txt
// and tools/quality/lexer07-scalar-literal-oracle.c):
//
//   I64 BootstrapScanScalarLiteral(
//       U8  *src,
//       I64  src_len,
//       I64  cursor,
//       I64  flags,
//       I64 *out_end,
//       I64 *out_kind,
//       I64 *out_i64,
//       U64 *out_f64_bits,
//       I64 *out_ishex,
//       I64 *out_error
//   );
//
// Result kinds:
//   SCALAR_NONE  0
//   SCALAR_I64   1
//   SCALAR_F64   2
//   SCALAR_CHAR  3
//   SCALAR_ERROR 4
//
// Error codes:
//   SCALAR_ERR_NONE              0
//   SCALAR_ERR_MALFORMED_NUMERIC 1
//   SCALAR_ERR_CHAR_UNTERMINATED 2
//   SCALAR_ERR_CHAR_OVERFLOW     3
//   SCALAR_ERR_BAD_ESCAPE        4
//   SCALAR_ERR_HEX_FLOAT         5
//   SCALAR_ERR_HEX_EXP           6
//   SCALAR_ERR_INVALID_BYTE      7
//
// Implementation requirements:
//   - single forward scan
//   - no dynamic allocation
//   - bounded reads
//   - explicit byte comparisons
//   - numeric conversion via libc strtoll / strtoul / strtod
//     (the canonical PolyC -> libc pattern)

// PolyC -> libc numeric conversion bindings.
// These are the same signatures declared in src/holyc-lib/strings.HC.
extern "c" I64 strtoll(U8 *nptr, U8 **endptr, I64 base);
extern "c" U64 strtoul(U8 *nptr, U8 **endptr, I64 base);
extern "c" F64 strtod(U8 *nptr, U8 **endptr);
extern "c" U0 *memcpy(U0 *__dst, U0 *__src, U64 __n);

#define SCALAR_NONE     0
#define SCALAR_I64      1
#define SCALAR_F64      2
#define SCALAR_CHAR     3
#define SCALAR_ERROR    4

#define SCALAR_ERR_NONE                0
#define SCALAR_ERR_MALFORMED_NUMERIC   1
#define SCALAR_ERR_CHAR_UNTERMINATED   2
#define SCALAR_ERR_CHAR_OVERFLOW       3
#define SCALAR_ERR_BAD_ESCAPE          4
#define SCALAR_ERR_HEX_FLOAT           5
#define SCALAR_ERR_HEX_EXP             6
#define SCALAR_ERR_INVALID_BYTE        7

#define SCALAR_LEX_CHAR_CONST_LEN 8

I64 SC_IsNum(I64 ch)
{
  return ch >= '0' && ch <= '9';
}

I64 SC_IsHex(I64 ch)
{
  if (SC_IsNum(ch)) return 1;
  if (ch >= 'a' && ch <= 'f') return 1;
  if (ch >= 'A' && ch <= 'F') return 1;
  return 0;
}

I64 SC_IsNumTerminator(I64 ch)
{
  if (SC_IsNum(ch)) return 0;
  if (SC_IsHex(ch)) return 0;
  if (ch == '.') return 0;
  if (ch == 'x') return 0;
  if (ch == 'X') return 0;
  if (ch == '\\') return 0;
  return 1;
}

// Bounded peek: returns 0 for idx < 0 or idx >= src_len.
U8 SC_PeekAt(U8 *src, I64 src_len, I64 idx)
{
  if (idx < 0 || idx >= src_len) return 0;
  return src[idx];
}

// Frozen countNumberLen body (translated from src/lexer.c).
I64 SC_CountNumberLen(U8 *ptr, I64 *isfloat, I64 *ishex, I64 *err)
{
  U8 *start = ptr;
  I64 seen_e = 0;

  while (!SC_IsNumTerminator(*ptr)) {
    switch (*ptr) {
      case 'e':
      case 'E':
        if (!*ishex) {
          if (seen_e) {
            *err = 1;
            return -1;
          }
          seen_e = 1;
        }
        break;
      case 'x':
      case 'X':
        if (*ishex) {
          *err = 1;
          return -1;
        }
        *ishex = 1;
        break;
      case '-':
      case '+':
        break;
      case '.':
        if (*isfloat) {
          *err = 1;
          return -1;
        }
        *isfloat = 1;
        break;
      default:
        if (*ptr == 'f') {
          if (*(ptr+1) != 0 && *(ptr+1) == '3' &&
             *(ptr+2) != 0 && *(ptr+2) == '2') {
            ptr += 2;
            *isfloat = 1;
            break;
          } else if (*(ptr+1) != 0 && *(ptr+1) == '6' &&
                     *(ptr+2) != 0 && *(ptr+2) == '4') {
            ptr += 2;
            *isfloat = 1;
            break;
          }
        } else if (!SC_IsHex(*ptr)) {
          *err = 1;
          return -1;
        }
        break;
    }
    ptr++;
  }

  if (*isfloat && *ishex) {
    *err = 1;
    return -1;
  }
  if (*ishex && seen_e) {
    *err = 1;
    return -1;
  }

  return ptr - start;
}

// Frozen lexCharConst body.
I64 SC_LexCharConst(U8 *src, I64 src_len, I64 cursor,
                     I64 *out_i64_bits, I64 *out_strlen,
                     I64 *out_overflowed, I64 *out_err)
{
  U64 char_const = 0;
  I64 idx;
  I64 hex_num = 0;
  I64 len, overflowed = 0;
  U8 ch;
  I64 p = cursor;

  // The dispatcher's cursor model: src[cursor] is the byte AFTER
  // the opening quote (the body). We scan body bytes until we hit
  // the trailing `'` or end-of-input. The returned `out_end` is
  // `p - cursor`, i.e. the number of bytes from cursor up to (but
  // NOT including) the trailing quote. `out_strlen` is the number
  // of body bytes (between the two quotes).

  for (len = 0; ; ++len) {
    ch = SC_PeekAt(src, src_len, p);
    p++;
    if (!ch || ch == '\'') {
      break;
    }
    if (len >= SCALAR_LEX_CHAR_CONST_LEN) {
      overflowed = 1;
      if (ch == '\\') {
        SC_PeekAt(src, src_len, p);
        p++;
      }
      continue;
    }
    idx = len * 8;
    if (ch == '\\') {
      ch = SC_PeekAt(src, src_len, p);
      p++;
      switch (ch) {
        case '0':  char_const |= 0 << idx; break;
        case '\'': char_const |= '\'' << idx; break;
        case '`':  char_const |= '`'  << idx; break;
        case '"':  char_const |= '"'  << idx; break;
        case 'd':  char_const |= '$'  << idx; break;
        case 'n':  char_const |= '\n' << idx; break;
        case 'r':  char_const |= '\r' << idx; break;
        case 't':  char_const |= '\t' << idx; break;
        case 'v':  char_const |= 11 << idx; break;  /* \v */
        case 'f':  char_const |= '\f' << idx; break;
        case 'x':
        case 'X': {
          hex_num = 0;
          for (I64 i = 0; i < 2; ++i) {
            U8 h = SC_PeekAt(src, src_len, p);
            U8 hu = h;
            if (hu >= 'a' && hu <= 'z') hu -= 32;
            if (!SC_IsHex(hu)) break;
            p++;
            if (hu <= '9') {
              hex_num = (hex_num<<4)+hu-'0';
            } else {
              hex_num = (hex_num<<4)+hu-'A'+10;
            }
          }
          char_const |= hex_num << idx;
          break;
        }
        default:
          char_const |= '\\' << idx;
          break;
      }
    } else {
      char_const |= ch << idx;
    }
  }

  *out_i64_bits = char_const;
  *out_strlen = len;
  *out_overflowed = overflowed;
  if (overflowed) {
    *out_err = SCALAR_ERR_CHAR_OVERFLOW;
  } else if (!ch) {
    *out_err = SCALAR_ERR_CHAR_UNTERMINATED;
  } else {
    *out_err = SCALAR_ERR_NONE;
  }
  return p - cursor;
}

public I64 BootstrapScanScalarLiteral(
    U8 *src,
    I64 src_len,
    I64 cursor,
    I64 flags,
    I64 *out_end,
    I64 *out_kind,
    I64 *out_i64,
    U64 *out_f64_bits,
    I64 *out_ishex,
    I64 *out_error,
    I64 *out_strlen)
{
  flags = flags; // unused; see C1 ABI contract
  if (src == NULL) {
    *out_end = cursor;
    *out_kind = SCALAR_ERROR;
    *out_i64 = 0;
    *out_f64_bits = 0;
    *out_ishex = 0;
    *out_error = SCALAR_ERR_INVALID_BYTE;
    *out_strlen = 0;
    return SCALAR_ERROR;
  }
  if (cursor < 0 || cursor >= src_len) {
    *out_end = cursor;
    *out_kind = SCALAR_NONE;
    *out_i64 = 0;
    *out_f64_bits = 0;
    *out_ishex = 0;
    *out_error = SCALAR_ERR_NONE;
    *out_strlen = 0;
    return SCALAR_NONE;
  }
  U8 ch = src[cursor];
  if (ch == '\'') {
    I64 bits = 0, slen = 0, ov = 0, e = 0;
    I64 consumed = SC_LexCharConst(src, src_len, cursor + 1,
                                    &bits, &slen, &ov, &e);
    ov = ov;
    *out_end = cursor + 1 + consumed;
    *out_kind = SCALAR_CHAR;
    *out_i64 = bits;
    *out_f64_bits = 0;
    *out_ishex = 0;
    *out_error = e;
    *out_strlen = slen;
    return SCALAR_CHAR;
  }
  if (!SC_IsNum(ch) && ch != '.') {
    *out_end = cursor;
    *out_kind = SCALAR_NONE;
    *out_i64 = 0;
    *out_f64_bits = 0;
    *out_ishex = 0;
    *out_error = SCALAR_ERR_NONE;
    *out_strlen = 0;
    return SCALAR_NONE;
  }

  I64 ishex = 0, isfloat = 0, err = 0;
  U8 *start = src + cursor;
  I64 numlen = SC_CountNumberLen(start, &isfloat, &ishex, &err);
  if (err || numlen < 0) {
    *out_end = cursor;
    *out_i64 = 0;
    *out_f64_bits = 0;
    *out_ishex = 0;
    *out_kind = SCALAR_ERROR;
    *out_error = SCALAR_ERR_MALFORMED_NUMERIC;
    *out_strlen = 0;
    return SCALAR_ERROR;
  }

  U8 tmp[256];
  if (numlen >= 256) {
    *out_end = cursor;
    *out_i64 = 0;
    *out_f64_bits = 0;
    *out_ishex = 0;
    *out_kind = SCALAR_ERROR;
    *out_error = SCALAR_ERR_MALFORMED_NUMERIC;
    *out_strlen = 0;
    return SCALAR_ERROR;
  }
  I64 k;
  for (k = 0; k < numlen; k++) tmp[k] = start[k];
  tmp[numlen] = 0;

  U8 *endptr = NULL;
  if (isfloat) {
    F64 v = strtod(tmp, &endptr);
    U64 bits = 0;
    memcpy(&bits, &v, 8);
    *out_f64_bits = bits;
    *out_i64 = 0;
    *out_ishex = 0;
    *out_end = cursor + numlen;
    *out_kind = SCALAR_F64;
    *out_error = SCALAR_ERR_NONE;
    *out_strlen = numlen;
    return SCALAR_F64;
  } else if (ishex) {
    U64 uv = strtoul(tmp, &endptr, 16);
    *out_i64 = uv;
    *out_f64_bits = 0;
    *out_ishex = 1;
    *out_end = cursor + numlen;
    *out_kind = SCALAR_I64;
    *out_error = SCALAR_ERR_NONE;
    *out_strlen = numlen;
    return SCALAR_I64;
  } else {
    I64 sv = strtoll(tmp, &endptr, 10);
    *out_i64 = sv;
    *out_f64_bits = 0;
    *out_ishex = 0;
    *out_end = cursor + numlen;
    *out_kind = SCALAR_I64;
    *out_error = SCALAR_ERR_NONE;
    *out_strlen = numlen;
    return SCALAR_I64;
  }
}
