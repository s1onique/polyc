// tools/quality/lexer07-direct-differential.c
//
// ACT-POLYC-SELFHOST-LEXER02 C2 — direct differential test.
//
// Links the C oracle AND the PolyC component (compiled to a
// .o file) and compares every observable field for all 40
// fixtures. Same fixture matrix as the oracle.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

extern long long BootstrapScanScalarLiteral(
    unsigned char *src,
    long long src_len,
    long long cursor,
    long long flags,
    long long *out_end,
    long long *out_kind,
    long long *out_i64,
    unsigned long long *out_f64_bits,
    long long *out_ishex,
    long long *out_error,
    long long *out_strlen);

extern long long BootstrapScalarLiteralOracle(
    unsigned char *src,
    long long src_len,
    long long cursor,
    long long flags,
    long long *out_end,
    long long *out_kind,
    long long *out_i64,
    unsigned long long *out_f64_bits,
    long long *out_ishex,
    long long *out_error,
    long long *out_strlen);

typedef struct {
    const char *name;
    const char *src;
    long long cursor;
    long long flags;
} input_t;

static input_t INPUTS[] = {
    {"dec_0",        "0;",       0, 0},
    {"dec_1",        "1;",       0, 0},
    {"dec_9",        "9;",       0, 0},
    {"dec_10",       "10;",      0, 0},
    {"dec_42",       "42;",      0, 0},
    {"dec_123456789","123456789;",0,0},
    {"hex_0x0",       "0x0;",   0, 0},
    {"hex_0x1",       "0x1;",   0, 0},
    {"hex_0x7f",      "0x7f;",  0, 0},
    {"hex_0XFF",      "0XFF;",  0, 0},
    {"hex_0xdeadbeef","0xdeadbeef;", 0, 0},
    {"hex_0XDEADBEEF","0XDEADBEEF;", 0, 0},
    {"hex_0x_empty",  "0x;",    0, 0},
    {"hex_0xG",       "0xG;",   0, 0},
    {"flt_0_0",    "0.0;",   0, 0},
    {"flt_1_0",    "1.0;",   0, 0},
    {"flt_1_",     "1.;",    0, 0},
    {"flt_123_456","123.456;", 0, 0},
    {"exp_1e2_i64",  "1e2;",    0, 0},
    {"exp_1e_neg",   "1e-2;",   0, 0},
    {"chr_a",     "'a';",    0, 0},
    {"chr_0",     "'0';",    0, 0},
    {"chr_sp",    "' ';",    0, 0},
    {"chr_nl",    "'\\n';",  0, 0},
    {"chr_cr",    "'\\r';",  0, 0},
    {"chr_tab",   "'\\t';",  0, 0},
    {"chr_bsl",   "'\\\\';", 0, 0},
    {"chr_sq",    "'\\'';", 0, 0},
    {"chr_dq",    "'\\\"';", 0, 0},
    {"chr_x41",   "'\\x41';",0, 0},
    {"chr_overflow", "'abcdefghij';", 0, 0},
    {"chr_unterm",   "'abc",   0, 0},
    {"nz_xx123",   "xx123;",  2, 0},
    {"nz_xx0xff",  "xx0xff;", 2, 0},
    {"nz_xx1_5",   "xx1.5;",  2, 0},
    {"nz_xx_a_",   "xx'a';",  2, 0},
    {"nas_id",     "abc;",    0, 0},
    {"nas_op",     "+abc;",   0, 0},
    {"nas_str",    "\"x\";",  0, 0},
    {"eof_cursor", "42",      2, 0},
};

int main(void) {
    int total = (int)(sizeof(INPUTS) / sizeof(INPUTS[0]));
    int pass = 0, fail = 0;
    printf("ACT_SELFHOST_LEXER02_DIRECT_DIFF_CASES=%d\n", total);

    for (int i = 0; i < total; ++i) {
        input_t *in = &INPUTS[i];
        size_t n = strlen(in->src);
        unsigned char buf[256];
        memcpy(buf, in->src, n);
        memset(buf + n, 0, sizeof(buf) - n);
        long long src_len = (long long)n;

        long long c_end = 0, c_kind = 0, c_i64 = 0;
        long long c_ishex = 0, c_err = 0, c_strlen = 0;
        unsigned long long c_f64_bits = 0;
        long long c_got = BootstrapScalarLiteralOracle(buf, src_len, in->cursor,
                                                       in->flags, &c_end,
                                                       &c_kind, &c_i64,
                                                       &c_f64_bits, &c_ishex,
                                                       &c_err, &c_strlen);

        long long p_end = 0, p_kind = 0, p_i64 = 0;
        long long p_ishex = 0, p_err = 0, p_strlen = 0;
        unsigned long long p_f64_bits = 0;
        long long p_got = BootstrapScanScalarLiteral(buf, src_len, in->cursor,
                                                      in->flags, &p_end,
                                                      &p_kind, &p_i64,
                                                      &p_f64_bits, &p_ishex,
                                                      &p_err, &p_strlen);

        int ok = (c_got == p_got) && (c_end == p_end) &&
                 (c_kind == p_kind) && (c_i64 == p_i64) &&
                 (c_f64_bits == p_f64_bits) &&
                 (c_ishex == p_ishex) && (c_err == p_err) &&
                 (c_strlen == p_strlen);

        if (ok) {
            pass++;
            printf("OK   %s kind=%lld/%lld end=%lld/%lld i64=0x%llx/0x%llx f64=0x%016llx/0x%016llx ishex=%lld/%lld err=%lld/%lld slen=%lld/%lld\n",
                   in->name,
                   (long long)c_got, (long long)p_got,
                   (long long)c_end, (long long)p_end,
                   (unsigned long long)c_i64, (unsigned long long)p_i64,
                   (unsigned long long)c_f64_bits, (unsigned long long)p_f64_bits,
                   (long long)c_ishex, (long long)p_ishex,
                   (long long)c_err, (long long)p_err,
                   (long long)c_strlen, (long long)p_strlen);
        } else {
            fail++;
            printf("FAIL %s C=(k=%lld,e=%lld,i=0x%llx,f=0x%016llx,h=%lld,r=%lld,s=%lld) P=(k=%lld,e=%lld,i=0x%llx,f=0x%016llx,h=%lld,r=%lld,s=%lld)\n",
                   in->name,
                   (long long)c_kind, (long long)c_end, (unsigned long long)c_i64,
                   (unsigned long long)c_f64_bits, (long long)c_ishex, (long long)c_err, (long long)c_strlen,
                   (long long)p_kind, (long long)p_end, (unsigned long long)p_i64,
                   (unsigned long long)p_f64_bits, (long long)p_ishex, (long long)p_err, (long long)p_strlen);
        }
    }
    printf("ACT_SELFHOST_LEXER02_DIRECT_DIFF_PASS=%d\n", pass);
    printf("ACT_SELFHOST_LEXER02_DIRECT_DIFF_FAIL=%d\n", fail);
    printf("STATUS=%s\n", fail ? "FAIL" : "PASS");
    return fail ? 1 : 0;
}
