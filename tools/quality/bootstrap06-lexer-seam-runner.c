/*
 * ACT-POLYC-SELFHOST-LEXER01 C2 IMPL — production-seam
 * runner for the operator / punctuation classification
 * slice.
 *
 * Compiled twice (build-time selection):
 *
 *   1. WITHOUT -DHCC_USE_SELFHOST_COMPONENTS: links the
 *      production src/lexer.c with the legacy C switch.
 *      Build label = "stage0".
 *
 *   2. WITH    -DHCC_USE_SELFHOST_COMPONENTS: links the
 *      production src/lexer.c with the
 *      BootstrapClassifyOperator delegation.
 *      Build label = "stage1".
 *
 * Both binaries run the same operator/punctuation inputs
 * through the production public entry point lex() and emit
 * a machine-diffable record. Byte-identity across stages
 * proves PILLAR_B_OPERATOR_SEAM = PASS.
 *
 * This is a test-only entry point. It does not appear in
 * the production build graph.
 */

#include <stdio.h>
#include <string.h>

#include "lexer.h"

#ifndef BUILD_LABEL
#define BUILD_LABEL "unknown"
#endif

/* Stub required by aostr.c. */
int is_terminal = 0;

typedef struct {
    const char *name;
    const char *input;
    long long   start_offset;
} op_seam_case_t;

static const op_seam_case_t OP_SEAM_CASES[] = {
    /* Single-char operators/punctuation */
    { "P01_paren_open",     "(",          0 },
    { "P02_paren_close",    ")",          0 },
    { "P03_brace_open",     "{",          0 },
    { "P04_brace_close",    "}",          0 },
    { "P05_bracket_open",   "[",          0 },
    { "P06_bracket_close",  "]",          0 },
    { "P07_comma",          ",",          0 },
    { "P08_semi",           ";",          0 },
    { "P09_tilde",          "~",          0 },
    /* Multi-char operators */
    { "M01_eq_eq",          "==",         0 },
    { "M02_less_eq",        "<=",         0 },
    { "M03_shl",            "<<",         0 },
    { "M04_shl_eq",         "<<=",        0 },
    { "M05_greater_eq",     ">=",         0 },
    { "M06_shr",            ">>",         0 },
    { "M07_shr_eq",         ">>=",        0 },
    { "M08_plus_plus",      "++",         0 },
    { "M09_plus_eq",        "+=",         0 },
    { "M10_minus_minus",    "--",         0 },
    { "M11_arrow",          "->",         0 },
    { "M12_minus_eq",       "-=",         0 },
    { "M13_not_eq",         "!=",         0 },
    { "M14_and_and",        "&&",         0 },
    { "M15_and_eq",         "&=",         0 },
    { "M16_or_or",          "||",         0 },
    { "M17_or_eq",          "|=",         0 },
    { "M18_mul_eq",         "*=",         0 },
    { "M19_mod_eq",         "%=",         0 },
    { "M20_xor_eq",         "^=",         0 },
    /* Adjacent to identifier */
    { "A01_id_plus",        "abc+",       3 },
    { "A02_id_eq",          "abc=",       3 },
    /* Ellipsis / triple */
    { "T01_ellipsis",       "...",        0 },
    /* Backslash */
    { "T02_backslash",      "\\",         0 },
};

#define OP_SEAM_CASE_COUNT \
    (int)(sizeof(OP_SEAM_CASES) / sizeof(OP_SEAM_CASES[0]))

int main(void)
{
    printf("BUILD_LABEL=%s\n", BUILD_LABEL);
    printf("OP_SEAM_CASE_COUNT=%d\n", OP_SEAM_CASE_COUNT);
    printf("\n");

    int pass = 0, fail = 0;

    for (int i = 0; i < OP_SEAM_CASE_COUNT; i++) {
        const op_seam_case_t *c = &OP_SEAM_CASES[i];

        char src_buf[128];
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

        /* Position l->ptr at start_offset. lexCore will
         * call lexNextChar itself to consume the first
         * byte of the operator/punctuation. */
        l.ptr = src_buf + c->start_offset;
        l.line_start_ptr = src_buf;
        l.lineno = 1;

        Lexeme le;
        memset(&le, 0, sizeof(le));
        int rc = lex(&l, &le);

        /* Emit the observable fields. Use offsets not
         * pointers so ASLR doesn't pollute the diff. */
        printf("CASE %s input=%s start_off=%lld\n",
               c->name, c->input, c->start_offset);
        printf("  rc=%d\n", rc);
        printf("  tk_type=0x%x\n", (unsigned int)le.tk_type);
        printf("  len=%d\n", le.len);
        printf("  line=%d\n", le.line);
        printf("  le_start_off=%ld\n",
               (long)(le.start ? (le.start - src_buf) : -1));
        printf("  l_ptr_off=%ld\n",
               (long)(l.ptr ? (l.ptr - src_buf) : -1));
        printf("  l_start_off=%ld\n",
               (long)(l.start ? (l.start - src_buf) : -1));
        /* next byte after lex (post-lex cursor's byte) */
        unsigned char nb = 0;
        if (l.ptr && (l.ptr - src_buf) >= 0 &&
            (l.ptr - src_buf) < (long)sizeof(src_buf)) {
            nb = (unsigned char)*l.ptr;
        }
        printf("  next_byte=0x%02x\n", (unsigned)nb);
        printf("  eof_state=%d\n", l.ptr && *l.ptr == '\0' ? 1 : 0);
        printf("\n");

        /* Minimal sanity: lex() must return 1, the lexeme
         * must have non-zero tk_type and non-zero len. */
        if (rc == 1 && le.tk_type != 0 && le.len > 0) {
            pass++;
        } else {
            fail++;
            printf("  CASE %s FAIL\n", c->name);
        }
    }

    printf("OP_SEAM_PASS=%d\n", pass);
    printf("OP_SEAM_FAIL=%d\n", fail);
    printf("STATUS=%s\n", fail == 0 ? "PASS" : "FAIL");
    return fail == 0 ? 0 : 1;
}
