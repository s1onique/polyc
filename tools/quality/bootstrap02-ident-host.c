// tools/quality/bootstrap02-ident-host.c
//
// ACT-POLYC-BOOTSTRAP02 C2 IMPL — C host harness for the
// B1 PolyC component BootstrapScanIdent.
//
// This harness exercises the SAME 15 fixtures as the
// independent C oracle (tools/quality/bootstrap02-ident-
// oracle.c) but invokes the PolyC-compiled
// BootstrapScanIdent symbol directly. The two outputs are
// compared by a Makefile diff to establish the
// stage0-vs-reference differential (the B1 component
// produces byte-equivalent results to the C reference
// model on all 15 fixtures).
//
// ABI (see src/lexer_bridge.h):
//
//   extern long long BootstrapScanIdent(
//       unsigned char *src,
//       long long      src_len,
//       long long      start,
//       long long     *out_end);
//
// Output format (matches the C oracle for trivial diff):
//
//   I01 OK a 1
//   I02 OK _ 1
//   ...
//   I12 NOK 0
//   ...
//
//   BOOTSTRAP02_IDENT_HOST_CASES=15
//   BOOTSTRAP02_IDENT_HOST_PASS=<N>
//   BOOTSTRAP02_IDENT_HOST_FAIL=<N>
//   STATUS=<PASS|FAIL>
//
// Exit codes:
//   0  all 15 cases match expected output
//   1  at least one case failed
//   2  argument error / ABI link failure
//
// IMPORTANT: This harness does NOT include or link to the
// C oracle. The two are compiled and linked separately so
// the diff is a real differential, not a tautology.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern long long BootstrapScanIdent(unsigned char *src,
                                    long long src_len,
                                    long long start,
                                    long long *out_end);

typedef struct {
    const char *id;
    const char *input;
    long long   start;
    long long   expected_end;
    int         expected_ok;
} IdentFixture;

static long long ilen(const char *s) {
    return (long long)strlen(s);
}

static IdentFixture FIXTURES[15] = {
    /* I01..I06: simple identifier cases */
    { "I01", "a",        0, 1, 1 },
    { "I02", "_",        0, 1, 1 },
    { "I03", "abc",      0, 3, 1 },
    { "I04", "_foo9",    0, 5, 1 },
    { "I05", "abc123",   0, 6, 1 },
    { "I06", "a_b_c",    0, 5, 1 },
    /* I07..I09: punctuation boundary */
    { "I07", "abc;",     0, 3, 1 },
    { "I08", "abc+",     0, 3, 1 },
    { "I09", "abc ",     0, 3, 1 },
    /* I10: nonzero cursor */
    { "I10", "xxabc;",   2, 5, 1 },
    /* I11: long identifier (60 chars) */
    { "I11",
      "abcdefghijklmnopqrstuvwxyz0123456789_ABCDEFGHIJKLMNOPQRSTUVW",
      0, 60, 1 },
    /* I12..I15: boundary / negative probes */
    { "I12", "9abc",     0, 0, 0 },   /* digit start */
    { "I13", "abc",      3, 0, 0 },   /* start >= len */
    { "I14", "abc",      3, 0, 0 },   /* exact end-of-buffer */
    { "I15", "abc$def",  0, 7, 1 },   /* $ in continuation */
};

int main(int argc, char **argv)
{
    (void)argc; (void)argv;

    int pass = 0, fail = 0;

    for (int i = 0; i < 15; i++) {
        IdentFixture *f = &FIXTURES[i];
        long long src_len = ilen(f->input);

        long long out_end = -1;
        int ok = (int)BootstrapScanIdent((unsigned char *)f->input,
                                          src_len,
                                          f->start,
                                          &out_end);

        int this_pass = 1;
        if (ok != f->expected_ok)     this_pass = 0;
        if (ok == 1 && out_end != f->expected_end) this_pass = 0;

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

    printf("BOOTSTRAP02_IDENT_HOST_CASES=15\n");
    printf("BOOTSTRAP02_IDENT_HOST_PASS=%d\n", pass);
    printf("BOOTSTRAP02_IDENT_HOST_FAIL=%d\n", fail);
    if (fail == 0) {
        printf("STATUS=PASS\n");
        return 0;
    } else {
        printf("STATUS=FAIL\n");
        return 1;
    }
}
