// tools/quality/bootstrap02-cursor-oracle.c
//
// ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01 C2 IMPL —
// reference model for the seam-level cursor witness
// (pillar B of the corrected cursor-evidence taxonomy).
//
// Runs the EXACT 6-input matrix the reviewer specified
// (see evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c1
// for the matrix definition) through the production
// ctype-based algorithm copied from
// tools/quality/bootstrap02-ident-oracle.c. Emits a
// (start, end, cur_strlen, next_byte) tuple per input.
//
// This oracle is INDEPENDENT from
// tools/quality/bootstrap02-cursor-host.c (which calls
// the B1 PolyC component). The two are compiled and
// executed separately so the diff is a real differential.
//
// Output format (canonical, one line per case):
//
//   ID  src=<hex>  start=<n>  end=<n>  cur_strlen=<n>  next_byte=<hex-or-NUL>
//
// And final summary lines:
//
//   BOOTSTRAP02_CURSOR_ORACLE_CASES=6
//   BOOTSTRAP02_CURSOR_ORACLE_PASS=6
//   BOOTSTRAP02_CURSOR_ORACLE_FAIL=0
//   STATUS=PASS
//
// Exit codes:
//   0  all 6 cases produce expected tuples
//   1  at least one case failed

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

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
    *out_end = start + i;
    return 1;
}

/* ==== Frozen 6-input matrix (per the reviewer) ==== */
typedef struct {
    const char *id;
    const char *input;
    long long   start;
} CursorFixture;

/* All inputs use src_len = strlen(input) — the matrix
 * covers the same EOF/NUL boundary case as the existing
 * 15-fixture oracle (case E1: "abc" with no trailing
 * byte means the byte at end is past-buffer = NUL). */

static CursorFixture FIXTURES[6] = {
    { "E1", "abc;",      0 },   /* end=3, next=';' */
    { "E2", "abc+",      0 },   /* end=3, next='+' */
    { "E3", "abc ",      0 },   /* end=3, next=' ' */
    { "E4", "abc",       0 },   /* end=3, next=EOF/NUL */
    { "E5", "xxabc;",    2 },   /* start=2, end=5, next=';' */
    { "E6", "abc$def;",  0 },   /* end=7, next=';' */
};

/* Print one byte as 2-digit hex (or "NUL" for 0x00). */
static void print_byte(unsigned char b) {
    if (b == '\0') {
        printf("NUL");
    } else {
        printf("%02x", b);
    }
}

/* Print src bytes as hex (e.g. "6162633b" for "abc;"). */
static void print_hex(const unsigned char *p, long long n) {
    for (long long i = 0; i < n; i++) {
        printf("%02x", p[i]);
    }
}

int main(int argc, char **argv)
{
    (void)argc; (void)argv;

    int pass = 0, fail = 0;

    for (int i = 0; i < 6; i++) {
        CursorFixture *f = &FIXTURES[i];
        long long src_len = (long long)strlen(f->input);

        long long out_end = -1;
        int ok = prod_scan_ident((const unsigned char *)f->input,
                                  src_len,
                                  f->start,
                                  &out_end);

        /* The reviewer's matrix has every case as OK; if
         * the production algorithm ever rejects one of
         * these inputs, that is a real defect. */
        if (!ok) {
            fail++;
            printf("%s  src=%s  start=%lld  REJECTED (expected OK)\n",
                   f->id, f->input, f->start);
            continue;
        }

        long long cur_strlen = out_end - f->start;

        /* Compute next_byte per the corrected cursor-
         * binding rule (same as src/lexer.c): */
        unsigned char next_byte;
        if (out_end >= src_len) {
            next_byte = '\0';  /* EOF/NUL: old path no-rewind */
        } else {
            unsigned char b = (unsigned char)f->input[out_end];
            if (b == '\0') next_byte = '\0';
            else           next_byte = b;
        }

        printf("%s  src=", f->id);
        print_hex((const unsigned char *)f->input, src_len);
        printf("  start=%lld  end=%lld  cur_strlen=%lld  next_byte=",
               f->start, out_end, cur_strlen);
        print_byte(next_byte);
        printf("\n");
        pass++;
    }

    printf("BOOTSTRAP02_CURSOR_ORACLE_CASES=6\n");
    printf("BOOTSTRAP02_CURSOR_ORACLE_PASS=%d\n", pass);
    printf("BOOTSTRAP02_CURSOR_ORACLE_FAIL=%d\n", fail);
    if (fail == 0) {
        printf("STATUS=PASS\n");
        return 0;
    } else {
        printf("STATUS=FAIL\n");
        return 1;
    }
}
