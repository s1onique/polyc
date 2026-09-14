// tools/quality/lexer07-scalar-literal-oracle.c
//
// ACT-POLYC-SELFHOST-LEXER02 C1 RED — production scalar
// literal oracle.
//
// Independent C99 reference of EXACTLY the production scalar
// literal scanning logic from src/lexer.c (the
// countNumberLen + lexNumeric + lexCharConst trio, "the
// R-F region"). It is parameterised by
// (src, src_len, cursor, flags) so it can be exercised
// from a standalone harness.
//
// ORACLE_CLASS = TEST_ONLY_PRODUCTION_EXTRACTION:
//   the body of this file is a verbatim extraction of the
//   production logic, byte-for-byte, modulo two mechanical
//   adaptations required to make it standalone:
//     - The cursor/buffer model is bounded (no Lexer struct).
//     - Diagnostics are not raised: malformed cases are
//       surfaced as bounded error codes + a span.
//
// The PolyC subject (tools/bootstrap/selfhost-lexer-scalar-literal.HC)
// is compared against this oracle via
// tools/quality/lexer07-direct-differential.c.
//
// Result kind grammar (binding):
//   SCALAR_NONE     0  (not a scalar literal at cursor)
//   SCALAR_I64      1  (decimal or hex integer)
//   SCALAR_F64      2  (floating point)
//   SCALAR_CHAR     3  (char constant)
//   SCALAR_ERROR    4  (malformed; err_code carries taxonomy)
//
// Error taxonomy (binding):
//   SCALAR_ERR_NONE                0
//   SCALAR_ERR_MALFORMED_NUMERIC   1
//   SCALAR_ERR_CHAR_UNTERMINATED   2
//   SCALAR_ERR_CHAR_OVERFLOW       3
//   SCALAR_ERR_BAD_ESCAPE          4  (reserved)
//   SCALAR_ERR_HEX_FLOAT           5  (reserved)
//   SCALAR_ERR_HEX_EXP             6  (reserved)
//   SCALAR_ERR_INVALID_BYTE        7

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

typedef long long I64;
typedef unsigned long long U64;

/* ==== Frozen result kind grammar ==== */
#define SCALAR_NONE     0
#define SCALAR_I64      1
#define SCALAR_F64      2
#define SCALAR_CHAR     3
#define SCALAR_ERROR    4

/* ==== Frozen error taxonomy ==== */
#define SCALAR_ERR_NONE                0
#define SCALAR_ERR_MALFORMED_NUMERIC   1
#define SCALAR_ERR_CHAR_UNTERMINATED   2
#define SCALAR_ERR_CHAR_OVERFLOW       3
#define SCALAR_ERR_BAD_ESCAPE          4
#define SCALAR_ERR_HEX_FLOAT           5
#define SCALAR_ERR_HEX_EXP             6
#define SCALAR_ERR_INVALID_BYTE        7

/* ==== Frozen flag bits (subset that lexNumeric/lexCharConst
 *      actually inspect; the wrapper forwards l->flags unchanged). ==== */
#define SCF_PERMISSIVE  (1 << 8)

/* ==== Character predicates (verbatim from src/lexer.c) ==== */
#define SC_isNum(ch) ((ch) >= '0' && (ch) <= '9')
#define SC_isHex(ch) \
    (SC_isNum(ch) || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F'))
#define SC_isNumTerminator(ch) (!SC_isNum(ch) && !SC_isHex(ch) && ch != '.' && ch != 'x' \
        && ch != 'X' && ch != '\\')

#define LEX_CHAR_CONST_LEN 8


/* ==== Frozen countNumberLen body (verbatim from src/lexer.c). ==== */
static int countNumberLen(const char *ptr, int *isfloat, int *ishex,
                          int *err) {
    const char *start = ptr;
    int seen_e = 0;

    while (!SC_isNumTerminator((unsigned char)*ptr)) {
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
                if (*(ptr+1) != '\0' && *(ptr+1) == '3' &&
                   *(ptr+2) != '\0' && *(ptr+2) == '2') {
                    ptr += 2;
                    *isfloat = 1;
                    break;
                } else if (*(ptr+1) != '\0' && *(ptr+1) == '6' &&
                           *(ptr+2) != '\0' && *(ptr+2) == '4') {
                    ptr += 2;
                    *isfloat = 1;
                    break;
                }
            } else if (!SC_isHex((unsigned char)*ptr)) {
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

    return (int)(ptr - start);
}


/* ==== Bounded peek of next byte (returns 0 at EOF). ==== */
static inline unsigned char peek_at(const unsigned char *src,
                                     I64 src_len, I64 idx) {
    if (idx < 0 || idx >= src_len) return 0;
    return src[idx];
}

/* ==== Frozen lexCharConst body (verbatim from src/lexer.c). ==== */
static I64 lexCharConstCore(const unsigned char *src, I64 src_len,
                             I64 cursor, I64 *out_i64_bits,
                             I64 *out_strlen, I64 *out_overflowed,
                             I64 *out_err) {
    U64 char_const = 0;
    I64 idx;
    I64 hex_num = 0;
    I64 len, overflowed = 0;
    unsigned char ch;
    I64 p = cursor;

    for (len = 0; ; ++len) {
        ch = peek_at(src, src_len, p);
        p++;
        if (!ch || ch == '\'') {
            break;
        }
        if (len >= LEX_CHAR_CONST_LEN) {
            overflowed = 1;
            if (ch == '\\') {
                (void)peek_at(src, src_len, p);
                p++;
            }
            continue;
        }
        idx = len * 8;
        if (ch == '\\') {
            ch = peek_at(src, src_len, p);
            p++;
            switch (ch) {
                case '0':  char_const |= (U64)'\0' << (U64)idx; break;
                case '\'': char_const |= (U64)'\'' << (U64)idx; break;
                case '`':  char_const |= (U64)'`'  << (U64)idx; break;
                case '"':  char_const |= (U64)'"'  << (U64)idx; break;
                case 'd':  char_const |= (U64)'$'  << (U64)idx; break;
                case 'n':  char_const |= (U64)'\n' << (U64)idx; break;
                case 'r':  char_const |= (U64)'\r' << (U64)idx; break;
                case 't':  char_const |= (U64)'\t' << (U64)idx; break;
                case 'v':  char_const |= (U64)'\v' << (U64)idx; break;
                case 'f':  char_const |= (U64)'\f' << (U64)idx; break;
                case 'x':
                case 'X': {
                    hex_num = 0;
                    for (int i = 0; i < 2; ++i) {
                        unsigned char h = peek_at(src, src_len, p);
                        unsigned char hu = (unsigned char)toupper(h);
                        if (!SC_isHex(hu)) {
                            break;
                        }
                        p++;
                        if (hu <= '9') {
                            hex_num = (hex_num<<4)+hu-'0';
                        } else {
                            hex_num = (hex_num<<4)+hu-'A'+10;
                        }
                    }
                    char_const |= (U64)hex_num << (U64)idx;
                    break;
                }
                default:
                    char_const |= (U64)'\\' << (U64)idx;
                    break;
            }
        } else {
            char_const |= (U64)((U64)ch << (U64)idx);
        }
    }

    *out_i64_bits = (I64)char_const;
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


/* ==== Frozen numeric scan: bounded version of lexNumeric. ==== */
static I64 lexNumericCore(const unsigned char *src, I64 src_len,
                           I64 cursor, I64 *out_i64_bits,
                           U64 *out_f64_bits, I64 *out_ishex,
                           I64 *out_isfloat_marker, I64 *out_err) {
    int ishex = 0, isfloat = 0, err = 0;
    const unsigned char *start = src + cursor;

    int numlen = countNumberLen((const char *)start,
                                &isfloat, &ishex, &err);
    if (err || numlen < 0) {
        *out_err = SCALAR_ERR_MALFORMED_NUMERIC;
        *out_i64_bits = 0;
        *out_f64_bits = 0;
        *out_ishex = 0;
        *out_isfloat_marker = 0;
        return cursor;
    }

    char tmp[256];
    if (numlen >= (int)sizeof(tmp)) {
        *out_err = SCALAR_ERR_MALFORMED_NUMERIC;
        *out_i64_bits = 0;
        *out_f64_bits = 0;
        *out_ishex = 0;
        *out_isfloat_marker = 0;
        return cursor;
    }
    memcpy(tmp, start, numlen);
    tmp[numlen] = '\0';

    if (isfloat) {
        char *endptr = NULL;
        long double v = strtold(tmp, &endptr);
        double d = (double)v;
        U64 bits;
        memcpy(&bits, &d, sizeof(bits));
        *out_f64_bits = bits;
        *out_i64_bits = 0;
        *out_ishex = 0;
        *out_isfloat_marker = 1;
        *out_err = SCALAR_ERR_NONE;
        return cursor + numlen;
    } else if (ishex) {
        char *endptr = NULL;
        unsigned long long uv = strtoull(tmp, &endptr, 16);
        *out_i64_bits = (I64)uv;
        *out_f64_bits = 0;
        *out_ishex = 1;
        *out_isfloat_marker = 0;
        *out_err = SCALAR_ERR_NONE;
        return cursor + numlen;
    } else {
        char *endptr = NULL;
        long long sv = strtoll(tmp, &endptr, 10);
        *out_i64_bits = (I64)sv;
        *out_f64_bits = 0;
        *out_ishex = 0;
        *out_isfloat_marker = 0;
        *out_err = SCALAR_ERR_NONE;
        return cursor + numlen;
    }
}

/* ==== Oracle entry point. ==== */
I64 BootstrapScalarLiteralOracle(
    unsigned char *src,
    I64 src_len,
    I64 cursor,
    I64 flags,
    I64 *out_end,
    I64 *out_kind,
    I64 *out_i64,
    U64 *out_f64_bits,
    I64 *out_ishex,
    I64 *out_err,
    I64 *out_strlen)
{
    (void)flags;
    if (src == NULL) {
        *out_end = cursor;
        *out_kind = SCALAR_ERROR;
        *out_i64 = 0;
        *out_f64_bits = 0;
        *out_ishex = 0;
        *out_err = SCALAR_ERR_INVALID_BYTE;
        *out_strlen = 0;
        return SCALAR_ERROR;
    }
    if (cursor < 0 || cursor >= src_len) {
        *out_end = cursor;
        *out_kind = SCALAR_NONE;
        *out_i64 = 0;
        *out_f64_bits = 0;
        *out_ishex = 0;
        *out_err = SCALAR_ERR_NONE;
        *out_strlen = 0;
        return SCALAR_NONE;
    }
    unsigned char ch = src[cursor];
    if (ch == '\'') {
        I64 bits = 0, slen = 0, ov = 0, e = 0;
        /* The dispatcher already advanced past the leading '\''; the
         * lexCharConst body starts reading from cursor+1 (the byte
         * after the opening quote). The cursor contract is "position
         * of the leading byte of the literal token"; *out_end is the
         * absolute cursor position AFTER the literal. */
        I64 consumed = lexCharConstCore(src, src_len, cursor + 1,
                                         &bits, &slen, &ov, &e);
        (void)ov;
        *out_end = cursor + 1 + consumed; /* cursor + leading '\'' + bytes-after */
        *out_kind = SCALAR_CHAR;
        *out_i64 = bits;
        *out_f64_bits = 0;
        *out_ishex = 0;
        *out_err = e;
        *out_strlen = slen;
        return SCALAR_CHAR;
    }
    if (!SC_isNum(ch) && ch != '.') {
        *out_end = cursor;
        *out_kind = SCALAR_NONE;
        *out_i64 = 0;
        *out_f64_bits = 0;
        *out_ishex = 0;
        *out_err = SCALAR_ERR_NONE;
        *out_strlen = 0;
        return SCALAR_NONE;
    }
    I64 i64v = 0, ishex = 0, e = 0;
    U64 f64bits = 0;
    I64 isfloat_marker = 0;
    I64 end = lexNumericCore(src, src_len, cursor,
                              &i64v, &f64bits, &ishex, &isfloat_marker, &e);
    *out_end = end;
    *out_i64 = i64v;
    *out_f64_bits = f64bits;
    *out_ishex = ishex;
    *out_err = e;
    *out_strlen = end - cursor; /* numeric literals: strlen == consumed bytes */
    if (e != SCALAR_ERR_NONE) {
        *out_kind = SCALAR_ERROR;
        return SCALAR_ERROR;
    }
    /* The oracle's lexNumericCore ran strtold iff isfloat was set
     * (because it goes through countNumberLen's isfloat, which was
     * computed during the scan). The presence of f64_bits != 0
     * from strtold is the actual signal. */
    if (f64bits != 0 || isfloat_marker) {
        *out_kind = SCALAR_F64;
        return SCALAR_F64;
    }
    *out_kind = SCALAR_I64;
    return SCALAR_I64;
}


typedef struct {
    const char *name;
    const char *src;
    I64 cursor;
    I64 flags;
    I64 exp_kind;
    I64 exp_end;
    I64 exp_i64;
    U64 exp_f64_bits;
    I64 exp_ishex;
    I64 exp_err;
} fixture_t;

/* Hand-picked fixtures exercising every frozen contract
 * requirement. Float f64_bits are filled in at runtime via
 * strtold() inside the harness loop; the fixture records
 * the canonical decimal expected (parsed via strtold). */
static fixture_t FIXTURES[] = {
    /* === Decimal integers === */
    {"dec_0",        "0;",       0, 0, SCALAR_I64, 1, 0, 0, 0, SCALAR_ERR_NONE},
    {"dec_1",        "1;",       0, 0, SCALAR_I64, 1, 1, 0, 0, SCALAR_ERR_NONE},
    {"dec_9",        "9;",       0, 0, SCALAR_I64, 1, 9, 0, 0, SCALAR_ERR_NONE},
    {"dec_10",       "10;",      0, 0, SCALAR_I64, 2, 10, 0, 0, SCALAR_ERR_NONE},
    {"dec_42",       "42;",      0, 0, SCALAR_I64, 2, 42, 0, 0, SCALAR_ERR_NONE},
    {"dec_123456789","123456789;",0,0, SCALAR_I64, 9, 123456789LL, 0, 0, SCALAR_ERR_NONE},
    /* === Hex integers (production behavior: 0x with no hex
     *      digits is valid I64=0, ishex=1; strtoull accepts
     *      the bare "0x" form) === */
    {"hex_0x0",       "0x0;",   0, 0, SCALAR_I64, 3, 0, 0, 1, SCALAR_ERR_NONE},
    {"hex_0x1",       "0x1;",   0, 0, SCALAR_I64, 3, 1, 0, 1, SCALAR_ERR_NONE},
    {"hex_0x7f",      "0x7f;",  0, 0, SCALAR_I64, 4, 0x7f, 0, 1, SCALAR_ERR_NONE},
    {"hex_0XFF",      "0XFF;",  0, 0, SCALAR_I64, 4, 0xFF, 0, 1, SCALAR_ERR_NONE},
    {"hex_0xdeadbeef","0xdeadbeef;", 0, 0, SCALAR_I64, 10, 0xdeadbeefLL, 0, 1, SCALAR_ERR_NONE},
    {"hex_0XDEADBEEF","0XDEADBEEF;", 0, 0, SCALAR_I64, 10, 0xDEADBEEFLL, 0, 1, SCALAR_ERR_NONE},
    {"hex_0x_empty",  "0x;",    0, 0, SCALAR_I64, 2, 0, 0, 1, SCALAR_ERR_NONE},
    {"hex_0xG",       "0xG;",   0, 0, SCALAR_I64, 2, 0, 0, 1, SCALAR_ERR_NONE},
    /* === Floats (extent) === */
    {"flt_0_0",    "0.0;",   0, 0, SCALAR_F64, 3, 0, 0, 0, SCALAR_ERR_NONE},
    {"flt_1_0",    "1.0;",   0, 0, SCALAR_F64, 3, 0, 0, 0, SCALAR_ERR_NONE},
    {"flt_1_",     "1.;",    0, 0, SCALAR_F64, 2, 0, 0, 0, SCALAR_ERR_NONE},
    {"flt_123_456","123.456;", 0, 0, SCALAR_F64, 7, 0, 0, 0, SCALAR_ERR_NONE},
    /* === Floats with exponent (production behavior:
     *      `e` after a digit is part of the number, but
     *      `-` and `+` are terminators, so `1e2` is I64=1
     *      (strtoll stops at e), `1e-2` is I64=1 (stops at
     *      -)). === */
    {"exp_1e2_i64",  "1e2;",    0, 0, SCALAR_I64, 3, 1, 0, 0, SCALAR_ERR_NONE},
    {"exp_1e_neg",   "1e-2;",   0, 0, SCALAR_I64, 2, 1, 0, 0, SCALAR_ERR_NONE},
    /* === Char constants === */
    {"chr_a",     "'a';",    0, 0, SCALAR_CHAR, 3, 'a',  0, 0, SCALAR_ERR_NONE},
    {"chr_0",     "'0';",    0, 0, SCALAR_CHAR, 3, '0',  0, 0, SCALAR_ERR_NONE},
    {"chr_sp",    "' ';",    0, 0, SCALAR_CHAR, 3, ' ',  0, 0, SCALAR_ERR_NONE},
    {"chr_nl",    "'\\n';",  0, 0, SCALAR_CHAR, 4, '\n', 0, 0, SCALAR_ERR_NONE},
    {"chr_cr",    "'\\r';",  0, 0, SCALAR_CHAR, 4, '\r', 0, 0, SCALAR_ERR_NONE},
    {"chr_tab",   "'\\t';",  0, 0, SCALAR_CHAR, 4, '\t', 0, 0, SCALAR_ERR_NONE},
    {"chr_bsl",   "'\\\\';", 0, 0, SCALAR_CHAR, 4, '\\', 0, 0, SCALAR_ERR_NONE},
    {"chr_sq",    "'\\'';", 0, 0, SCALAR_CHAR, 4, '\'', 0, 0, SCALAR_ERR_NONE},
    {"chr_dq",    "'\\\"';", 0, 0, SCALAR_CHAR, 4, '"',  0, 0, SCALAR_ERR_NONE},
    {"chr_x41",   "'\\x41';",0, 0, SCALAR_CHAR, 6, 'A',  0, 0, SCALAR_ERR_NONE},
    /* === Char overflow (>8 bytes): first 8 bytes are packed,
     *      but the error is set so the production raise fires
     *      and the value is unused at runtime. We assert the
     *      first 8-byte packed value for byte-equality. The
     *      cursor after the lexeme is past the closing quote. === */
    {"chr_overflow", "'abcdefghij';", 0, 0, SCALAR_CHAR, 12,
     (I64)0x6867666564636261LL, 0, 0, SCALAR_ERR_CHAR_OVERFLOW},
    /* === Char unterminated (EOF in constant): 3 bytes packed,
     *      NUL terminator seen, no closing quote. The cursor
     *      after the lexeme is past the NUL terminator. === */
    {"chr_unterm",   "'abc",   0, 0, SCALAR_CHAR, 5, 0x636261, 0, 0, SCALAR_ERR_CHAR_UNTERMINATED},
    /* === Nonzero cursor === */
    {"nz_xx123",   "xx123;",  2, 0, SCALAR_I64, 5, 123, 0, 0, SCALAR_ERR_NONE},
    {"nz_xx0xff",  "xx0xff;", 2, 0, SCALAR_I64, 6, 0xff, 0, 1, SCALAR_ERR_NONE},
    {"nz_xx1_5",   "xx1.5;",  2, 0, SCALAR_F64, 6, 0, 0, 0, SCALAR_ERR_NONE},
    {"nz_xx_a_",   "xx'a';",  2, 0, SCALAR_CHAR, 5, 'a', 0, 0, SCALAR_ERR_NONE},
    /* === Not a scalar literal === */
    {"nas_id",     "abc;",    0, 0, SCALAR_NONE, 0, 0, 0, 0, SCALAR_ERR_NONE},
    {"nas_op",     "+abc;",   0, 0, SCALAR_NONE, 0, 0, 0, 0, SCALAR_ERR_NONE},
    {"nas_str",    "\"x\";",  0, 0, SCALAR_NONE, 0, 0, 0, 0, SCALAR_ERR_NONE},
    /* === Cursor at EOF (returns NONE) === */
    {"eof_cursor", "42",      2, 0, SCALAR_NONE, 2, 0, 0, 0, SCALAR_ERR_NONE},
};


/* For fixtures that include floats, compute the expected
 * f64_bits by re-running strtold() on the consumed slice.
 * This keeps the suite portable: we do not hard-code
 * architecture-specific bit patterns. */
static void fill_float_expected(fixture_t *f) {
    if (f->exp_kind != SCALAR_F64) return;
    /* Find consumed extent: scan from cursor up to the first
     * non-floating byte or src end. */
    const unsigned char *s = (const unsigned char *)f->src;
    I64 start = f->cursor;
    I64 end = f->cursor;
    while (s[end] && s[end] != ';' && s[end] != ' ' && s[end] != '\n' &&
           s[end] != '+' && s[end] != '-' && s[end] != '*' && s[end] != '/' &&
           s[end] != ')' && s[end] != ']' && s[end] != '}' && s[end] != ',') {
        end++;
        if (end - start > 64) break;
    }
    char tmp[128];
    I64 n = end - start;
    if (n >= (I64)sizeof(tmp)) return;
    memcpy(tmp, s + start, n);
    tmp[n] = '\0';
    char *e = NULL;
    long double v = strtold(tmp, &e);
    double d = (double)v;
    U64 bits;
    memcpy(&bits, &d, sizeof(bits));
    f->exp_f64_bits = bits;
    f->exp_end = end;
    f->exp_i64 = 0;
}

#ifndef NO_ORACLE_MAIN
int main(void) {
    int total = (int)(sizeof(FIXTURES) / sizeof(FIXTURES[0]));
    int pass = 0, fail = 0;
    for (int i = 0; i < total; ++i) {
        fill_float_expected(&FIXTURES[i]);
    }

    printf("ACT_SELFHOST_LEXER02_SCALAR_CASES=%d\n", total);
    for (int i = 0; i < total; ++i) {
        fixture_t *f = &FIXTURES[i];
        size_t n = strlen(f->src);
        if (n > 1024) { printf("fixture %s too long\n", f->name); return 2; }

        unsigned char buf[1100];
        memcpy(buf, f->src, n);
        memset(buf + n, 0, sizeof(buf) - n);
        I64 src_len = (I64)n;

        I64 out_end = 0, out_kind = 0, out_i64 = 0;
        I64 out_ishex = 0, out_err = 0, out_strlen = 0;
        U64 out_f64_bits = 0;
        I64 got = BootstrapScalarLiteralOracle(buf, src_len, f->cursor,
                                                f->flags, &out_end,
                                                &out_kind, &out_i64,
                                                &out_f64_bits, &out_ishex,
                                                &out_err, &out_strlen);

        int ok = (got == f->exp_kind) && (out_end == f->exp_end) &&
                 (out_i64 == f->exp_i64) &&
                 (out_f64_bits == f->exp_f64_bits) &&
                 (out_ishex == f->exp_ishex) && (out_err == f->exp_err);

        if (ok) {
            pass++;
            printf("OK   %s kind=%lld end=%lld i64=0x%llx f64=0x%016llx ishex=%lld err=%lld\n",
                   f->name, (long long)got, (long long)out_end,
                   (unsigned long long)out_i64,
                   (unsigned long long)out_f64_bits,
                   (long long)out_ishex, (long long)out_err);
        } else {
            fail++;
            printf("FAIL %s kind got=%lld exp=%lld end got=%lld exp=%lld i64 got=0x%llx exp=0x%llx f64 got=0x%016llx exp=0x%016llx ishex got=%lld exp=%lld err got=%lld exp=%lld\n",
                   f->name,
                   (long long)got, (long long)f->exp_kind,
                   (long long)out_end, (long long)f->exp_end,
                   (unsigned long long)out_i64, (unsigned long long)f->exp_i64,
                   (unsigned long long)out_f64_bits, (unsigned long long)f->exp_f64_bits,
                   (long long)out_ishex, (long long)f->exp_ishex,
                   (long long)out_err, (long long)f->exp_err);
        }
    }
    printf("ACT_SELFHOST_LEXER02_SCALAR_PASS=%d\n", pass);
    printf("ACT_SELFHOST_LEXER02_SCALAR_FAIL=%d\n", fail);
    printf("STATUS=%s\n", fail ? "FAIL" : "PASS");
    return fail ? 1 : 0;
}
#endif /* LEXER07_ORACLE_NO_MAIN */
