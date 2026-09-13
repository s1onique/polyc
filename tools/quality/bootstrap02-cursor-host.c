// tools/quality/bootstrap02-cursor-host.c
//
// ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01 C2 IMPL —
// seam-level cursor witness for the B1 PolyC component
// (pillar B of the corrected cursor-evidence taxonomy).
//
// Runs the EXACT 6-input matrix the reviewer specified
// through BootstrapScanIdent (the B1 PolyC component,
// linked in from build/bootstrap02-ident.o). Emits the
// same (start, end, cur_strlen, next_byte) tuple format
// as the C reference oracle
// (tools/quality/bootstrap02-cursor-oracle.c) so the two
// outputs can be diffed line-by-line.
//
// This harness is INDEPENDENT from the C oracle; the two
// are compiled and executed separately so the diff is a
// real differential, not a tautology.
//
// ABI (see src/lexer_bridge.h):
//
//   extern long long BootstrapScanIdent(
//       unsigned char *src,
//       long long      src_len,
//       long long      start,
//       long long     *out_end);
//
// Output format (matches the oracle exactly):
//
//   ID  src=<hex>  start=<n>  end=<n>  cur_strlen=<n>  next_byte=<hex-or-NUL>
//
// And final summary lines:
//
//   BOOTSTRAP02_CURSOR_HOST_CASES=6
//   BOOTSTRAP02_CURSOR_HOST_PASS=6
//   BOOTSTRAP02_CURSOR_HOST_FAIL=0
//   STATUS=PASS

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
} CursorFixture;

static CursorFixture FIXTURES[6] = {
    { "E1", "abc;",      0 },   /* end=3, next=';' */
    { "E2", "abc+",      0 },   /* end=3, next='+' */
    { "E3", "abc ",      0 },   /* end=3, next=' ' */
    { "E4", "abc",       0 },   /* end=3, next=EOF/NUL */
    { "E5", "xxabc;",    2 },   /* start=2, end=5, next=';' */
    { "E6", "abc$def;",  0 },   /* end=7, next=';' */
};

static void print_byte(unsigned char b) {
    if (b == '\0') {
        printf("NUL");
    } else {
        printf("%02x", b);
    }
}

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
        int ok = (int)BootstrapScanIdent((unsigned char *)f->input,
                                          src_len,
                                          f->start,
                                          &out_end);

        if (!ok) {
            fail++;
            printf("%s  src=%s  start=%lld  REJECTED (expected OK)\n",
                   f->id, f->input, f->start);
            continue;
        }

        long long cur_strlen = out_end - f->start;

        /* Compute next_byte per the corrected cursor-
         * binding rule (same as src/lexer.c). */
        unsigned char next_byte;
        if (out_end >= src_len) {
            next_byte = '\0';
        } else {
            unsigned char b = (unsigned char)f->input[out_end];
            next_byte = (b == '\0') ? '\0' : b;
        }

        printf("%s  src=", f->id);
        print_hex((const unsigned char *)f->input, src_len);
        printf("  start=%lld  end=%lld  cur_strlen=%lld  next_byte=",
               f->start, out_end, cur_strlen);
        print_byte(next_byte);
        printf("\n");
        pass++;
    }

    printf("BOOTSTRAP02_CURSOR_HOST_CASES=6\n");
    printf("BOOTSTRAP02_CURSOR_HOST_PASS=%d\n", pass);
    printf("BOOTSTRAP02_CURSOR_HOST_FAIL=%d\n", fail);
    if (fail == 0) {
        printf("STATUS=PASS\n");
        return 0;
    } else {
        printf("STATUS=FAIL\n");
        return 1;
    }
}
