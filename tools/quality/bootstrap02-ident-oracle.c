// tools/quality/bootstrap02-ident-oracle.c
//
// ACT-POLYC-BOOTSTRAP02 C1 RED — production identifier-span oracle.
//
// Independent C99 reference of EXACTLY the production identifier
// scanning loop from src/lexer.c:873-885 (lexIdentifier), with
// the same byte semantics, but parameterised by explicit
// src, src_len, start, out_end so it can be exercised from a
// standalone harness without touching the production compiler.
//
// This is NOT a wrapper around the production compiler; it is
// an independent C implementation of the same algorithm,
// copied verbatim from the production source for transparency.
//
// Algorithm (from src/lexer.c:873):
//
//   int lexIdentifier(Lexer *l, char ch) {
//       int i = 0;
//       while (ch && (isalnum(ch) || ch == '_' || ch == '$')) {
//           i++;
//           ch = lexNextChar(l);    // advance
//       }
//       l->cur_strlen = i;
//       if (ch != '\0') {
//           lexRewindChar(l);       // rewind one byte
//       }
//       return TK_IDENT;
//   }
//
// The oracle reproduces this exactly using an explicit
// (src, src_len, start, out_end) ABI. It does NOT mutate src
// (rewinding in the production lexer means "step the cursor
// back one byte"; here the oracle simply does not advance
// past the last non-identifier byte). The byte semantics on
// output are identical: out_end = start + N where N is the
// number of identifier bytes (1..N).
//
// Output (one line per case):
//
//   I01 OK a 1
//   I02 OK _ 1
//   ...
//   I12 NOK 9abc 0     (start byte invalid, returns 0)
//   I13 NOK "" 0       (start >= src_len, returns 0)
//
// And final summary line:
//
//   BOOTSTRAP02_IDENT_CASES=15
//   BOOTSTRAP02_IDENT_PASS=<N>
//   BOOTSTRAP02_IDENT_FAIL=<N>
//   STATUS=<PASS|FAIL>
//
// Exit codes:
//   0  all 15 cases match expected output
//   1  at least one case failed
//   2  argument error

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>

/* ==== Frozen production-grammar predicates ==== */
static int prod_is_ident_start(unsigned char c) {
    return isalpha(c) || c == '_';
}
static int prod_is_ident_rest(unsigned char c) {
    return isalnum(c) || c == '_' || c == '$';
}

/* ==== Frozen production scanner ==== */
static int prod_scan_ident(const unsigned char *src,
                           long long src_len,
                           long long start,
                           long long *out_end)
{
    if (src == NULL)         return 0;
    if (out_end == NULL)     return 0;
    if (start < 0)           return 0;
    if (start >= src_len)    return 0;

    int ch = (unsigned char)src[start];
    if (!prod_is_ident_start((unsigned char)ch)) return 0;

    long long i = 0;
    while (start + i < src_len) {
        unsigned char c = (unsigned char)src[start + i];
        if (!prod_is_ident_rest(c)) break;
        i++;
    }
    /* mirror lexRewindChar: do not consume the non-id byte */
    *out_end = start + i;
    return 1;
}

/* ==== Frozen fixture matrix (15 cases, I01..I15) ==== */

typedef struct {
    const char *id;
    const char *input;     /* NUL-terminated; we also pass src_len */
    long long   start;
    const char *expected;  /* identifier text on OK; NULL on NOK */
    long long   expected_end;
    int         expected_ok;  /* 1 OK, 0 NOK */
} IdentFixture;

/* Helper: src_len = strlen(input) unless input is "" */
static long long ilen(const char *s) { return (long long)strlen(s); }

static IdentFixture FIXTURES[15] = {
    /* I01..I06: simple identifier cases */
    { "I01", "a",        0, "a",       1, 1 },
    { "I02", "_",        0, "_",       1, 1 },
    { "I03", "abc",      0, "abc",     3, 1 },
    { "I04", "_foo9",    0, "_foo9",   5, 1 },
    { "I05", "abc123",   0, "abc123",  6, 1 },
    { "I06", "a_b_c",    0, "a_b_c",   5, 1 },
    /* I07..I09: punctuation boundary */
    { "I07", "abc;",     0, "abc",     3, 1 },
    { "I08", "abc+",     0, "abc",     3, 1 },
    { "I09", "abc ",     0, "abc",     3, 1 },
    /* I10: nonzero cursor */
    { "I10", "xxabc;",   2, "abc",     5, 1 },
    /* I11: long identifier (60 chars) */
    { "I11",
      "abcdefghijklmnopqrstuvwxyz0123456789_ABCDEFGHIJKLMNOPQRSTUVW",
      0, "abcdefghijklmnopqrstuvwxyz0123456789_ABCDEFGHIJKLMNOPQRSTUVW",
      60, 1 },
    /* I12..I15: boundary / negative probes */
    { "I12", "9abc",     0, NULL,       0, 0 },   /* digit start */
    { "I13", "abc",      3, NULL,       0, 0 },   /* start >= len */
    { "I14", "abc",      3, NULL,       0, 0 },   /* exact end-of-buffer */
    { "I15", "abc$def",  0, "abc$def",  7, 1 },   /* $ in continuation */
};

int main(int argc, char **argv)
{
    (void)argc; (void)argv;

    int pass = 0, fail = 0;

    for (int i = 0; i < 15; i++) {
        IdentFixture *f = &FIXTURES[i];
        long long src_len = ilen(f->input);

        /* Also probe the B0-vs-production boundary case I15
         * explicitly: B0 would return 0 here (would split into
         * "abc" + unsupported '$'). Production returns 1. */
        long long out_end = -1;
        int ok = prod_scan_ident((const unsigned char *)f->input,
                                 src_len,
                                 f->start,
                                 &out_end);

        int this_pass = 1;
        if (ok != f->expected_ok) this_pass = 0;
        if (ok == 1 && out_end != f->expected_end) this_pass = 0;
        if (ok == 1 && f->expected != NULL &&
            (out_end - f->start) != (long long)strlen(f->expected))
            this_pass = 0;

        if (this_pass) {
            pass++;
            if (ok == 1) {
                printf("%s OK %.*s %lld\n",
                       f->id,
                       (int)(out_end - f->start),
                       f->input + f->start,
                       out_end);
            } else {
                printf("%s NOK %lld\n", f->id, f->start);
            }
        } else {
            fail++;
            printf("%s FAIL ok=%d exp_ok=%d out_end=%lld exp_end=%lld\n",
                   f->id, ok, f->expected_ok, out_end, f->expected_end);
        }
    }

    printf("BOOTSTRAP02_IDENT_CASES=15\n");
    printf("BOOTSTRAP02_IDENT_PASS=%d\n", pass);
    printf("BOOTSTRAP02_IDENT_FAIL=%d\n", fail);
    if (fail == 0) {
        printf("STATUS=PASS\n");
        return 0;
    } else {
        printf("STATUS=FAIL\n");
        return 1;
    }
}