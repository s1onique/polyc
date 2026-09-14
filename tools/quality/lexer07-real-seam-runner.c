/*
 * tools/quality/lexer07-real-seam-runner.c
 *
 * ACT-POLYC-SELFHOST-LEXER02 — production seam runner for
 * the scalar literal slice.
 *
 * Compiled twice (build-time selection):
 *
 *   1. WITHOUT -DHCC_USE_SELFHOST_COMPONENTS: links the
 *      production src/lexer.c with the legacy C scalar
 *      literal code. Build label = "stage0".
 *
 *   2. WITH    -DHCC_USE_SELFHOST_COMPONENTS: links the
 *      production src/lexer.c with the
 *      BootstrapScanScalarLiteral delegation.
 *      Build label = "stage1".
 *
 * Both binaries run the same scalar-literal inputs through
 * the production public entry point lex() and emit a
 * machine-diffable record. Byte-identity across stages
 * proves PILLAR_C_SCALAR_SEAM = PASS.
 */

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "lexer.h"

#ifndef BUILD_LABEL
#define BUILD_LABEL "unknown"
#endif

/* Stub required by aostr.c. */
int is_terminal = 0;

typedef struct {
    const char *name;
    const char *input;
    long long   cursor; /* offset into input */
} scalar_seam_case_t;

static const scalar_seam_case_t SCALAR_SEAM_CASES[] = {
    /* Decimal integers */
    { "D01_zero",         "0;",          0 },
    { "D02_one",          "1;",          0 },
    { "D03_big",          "123456789;",  0 },
    /* Hex integers */
    { "H01_hex0",         "0x0;",        0 },
    { "H02_hexFF",        "0xFF;",       0 },
    { "H03_deadbeef",     "0xdeadbeef;", 0 },
    /* Floats */
    { "F01_zero_dot",     "0.0;",        0 },
    { "F02_one_dot",      "1.0;",        0 },
    { "F03_decimal",      "123.456;",    0 },
    { "F04_trailing",     "1.;",        0 },
    /* Chars */
    { "C01_a",            "'a';",        0 },
    { "C02_nl",           "'\\n';",      0 },
    { "C03_x41",          "'\\x41';",    0 },
    { "C04_bsl",          "'\\\\';",     0 },
    /* Nonzero cursor (prefixed with bytes that would form an
     * identifier; the lexer must continue past and scan the
     * scalar that follows). */
    { "N01_xx_int",       "xx 123;",     3 },
    { "N02_xx_hex",       "xx 0xff;",    3 },
    { "N03_xx_flt",       "xx 1.5;",     3 },
    { "N04_xx_chr",       "xx 'a';",     3 },
    /* Combined identifier+digit prefix (no space) */
    { "N05_xx_int_nospc", "xx123;",      2 },
    { "N06_xx_hex_nospc", "xx0xff;",     2 },
    { "N07_xx_flt_nospc", "xx1.5;",      2 },
    { "N08_xx_chr_nospc", "xx'a';",      2 },
    /* Hex with E */
    { "H04_hexE",         "0xAB;",       0 },
    /* Float exponent */
    { "F05_exp",          "1e2;",        0 },
    { "F06_exp_neg",      "1e-2;",       0 },
    /* Numbers followed by various terminators */
    { "T01_paren",        "42);",        0 },
    { "T02_plus",         "42+1;",       0 },
    { "T03_eof",          "42",          0 },
};

#define SCALAR_SEAM_CASE_COUNT \
    (int)(sizeof(SCALAR_SEAM_CASES) / sizeof(SCALAR_SEAM_CASES[0]))

/* Render a u64 as 16 hex digits. */
static void hex16(char *out, uint64_t v) {
    static const char *H = "0123456789abcdef";
    for (int i = 15; i >= 0; --i) { out[i] = H[v & 0xF]; v >>= 4; }
    out[16] = '\0';
}

/* Render a byte sequence as escaped hex for diagnostic clarity. */
static void render_src(char *out, const unsigned char *src, int len) {
    static const char *H = "0123456789abcdef";
    int j = 0;
    for (int i = 0; i < len && j < 200; ++i) {
        unsigned char b = src[i];
        if (b >= 32 && b < 127 && b != '\\') {
            out[j++] = b;
        } else {
            out[j++] = '\\';
            out[j++] = H[(b >> 4) & 0xF];
            out[j++] = H[b & 0xF];
        }
    }
    out[j] = '\0';
}

int main(void)
{
    printf("BUILD_LABEL=%s\n", BUILD_LABEL);
    printf("SCALAR_SEAM_CASE_COUNT=%d\n\n", SCALAR_SEAM_CASE_COUNT);

    for (int i = 0; i < SCALAR_SEAM_CASE_COUNT; i++) {
        const scalar_seam_case_t *c = &SCALAR_SEAM_CASES[i];

        char src_buf[256];
        memset(src_buf, 0, sizeof(src_buf));
        size_t n = 0;
        while (c->input[n] != '\0' && n < sizeof(src_buf) - 1) {
            src_buf[n] = c->input[n];
            n++;
        }
        src_buf[n] = '\0';

        Lexer l;
        memset(&l, 0, sizeof(l));
        lexInit(&l, src_buf, 0);

        /* Position l->ptr at cursor. lexCore will call lexNextChar
         * which sets l->start = l->ptr and then advances. */
        l.ptr = src_buf + c->cursor;
        l.line_start_ptr = src_buf;
        l.lineno = 1;

        Lexeme le;
        memset(&le, 0, sizeof(le));

        int rc = lex(&l, &le);

        char render[256];
        render_src(render, (unsigned char *)src_buf, (int)n);

        /* Compute cursor advance: end - start (within input). */
        long long consumed = 0;
        if (le.start) {
            consumed = (long long)((le.start + le.len) - src_buf) - c->cursor;
            if (consumed < 0) consumed = 0;
        }

        char hexbuf[17];
        uint64_t f64bits = 0;
        if (le.tk_type == TK_F64) {
            memcpy(&f64bits, &le.f64, sizeof(f64bits));
        }
        hex16(hexbuf, f64bits);

        printf("CASE %s src=%s cursor=%lld rc=%d kind=0x%x len=%d consumed=%lld "
               "i64=0x%llx f64_bits=0x%016s ishex=%d\n",
               c->name, render, c->cursor, rc, le.tk_type, le.len,
               consumed,
               (unsigned long long)le.i64,
               hexbuf,
               le.ishex);
    }
    printf("\nEND\n");
    return 0;
}
