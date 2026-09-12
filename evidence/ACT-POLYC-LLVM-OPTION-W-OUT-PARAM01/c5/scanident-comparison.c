/* scanident-comparison.c
 *
 * C5 RUNTIME COMPARISON (reference vs hcc-emitted subject,
 * FROZEN C1 vectors).
 *
 * Runs the C reference implementation AND the hcc-emitted
 * subject side-by-side on each of the FROZEN C1 binding
 * fixture Tests 05-10 (the subset internally consistent
 * with the frozen function body). Both must agree AND
 * match the frozen expected outputs.
 *
 * The reviewer-prescribed nonzero-cursor probes (T08, T09)
 * are explicitly marked in the output.
 *
 * LINK:  cc -Wall -Wextra -c scanident-comparison.c
 *                    -o scanident-comparison.o
 *        clang scanident-comparison.o scanident-subject.o
 *              -o scanident-comparison
 * RUN:   /tmp/scanident-comparison
 */

#include <stdio.h>
#include <string.h>

/* C reference (identical to the frozen body in c1) */
static long ScanIdent_ref(const unsigned char *src, long len, long cursor,
                          long *out_cursor, long *out_len) {
    long start = cursor;
    while (cursor < len) {
        unsigned char ch = src[cursor];
        if (ch == ' ' || ch == '\t' || ch == '\n') break;
        cursor = cursor + 1;
    }
    *out_cursor = cursor;
    *out_len = cursor - start;
    return 0;
}

/* hcc-emitted subject is linked in from scanident-subject.o */
extern long ScanIdent(const unsigned char *src, long len, long cursor,
                      long *out_cursor, long *out_len);

struct vec {
    const char *name;
    const char *src;
    long        len;
    long        cursor;
    long        exp_oc;
    long        exp_ol;
    int         nonzero_cursor_probe;
};

static const struct vec FROZEN_VECTORS[] = {
    {"T05", " \t\nfoo", 6, 0, 0, 0, 0},
    {"T06", "foo",      3, 0, 3, 3, 0},
    {"T07", "",         0, 0, 0, 0, 0},
    {"T08", "abc foo",  7, 3, 3, 0, 1},  /* NONZERO-CURSOR PROBE */
    {"T09", "abc foo",  7, 4, 7, 3, 1},  /* NONZERO-CURSOR PROBE */
    {"T10", "abc123",   6, 0, 6, 6, 0},
};

int main(void) {
    int n = (int)(sizeof(FROZEN_VECTORS) / sizeof(FROZEN_VECTORS[0]));
    int pass = 0;
    for (int i = 0; i < n; ++i) {
        const struct vec *v = &FROZEN_VECTORS[i];
        long ref_oc = -1, ref_ol = -1, sub_oc = -1, sub_ol = -1;
        long ref_rc = ScanIdent_ref((const unsigned char *)v->src, v->len,
                                    v->cursor, &ref_oc, &ref_ol);
        long sub_rc = ScanIdent    ((const unsigned char *)v->src, v->len,
                                    v->cursor, &sub_oc, &sub_ol);
        int sub_ok = (sub_rc == 0 && sub_oc == v->exp_oc && sub_ol == v->exp_ol);
        int agree  = (ref_rc == sub_rc && ref_oc == sub_oc && ref_ol == sub_ol);
        int ok     = sub_ok && agree;
        if (ok) pass++;
        printf("Test %s%s: ref=(rc=%ld,oc=%ld,ol=%ld) sub=(rc=%ld,oc=%ld,ol=%ld) exp=(oc=%ld,ol=%ld) sub_ok=%s agree=%s %s\n",
               v->name,
               v->nonzero_cursor_probe ? "_NZCURSOR" : "",
               ref_rc, ref_oc, ref_ol,
               sub_rc, sub_oc, sub_ol,
               v->exp_oc, v->exp_ol,
               sub_ok ? "Y" : "N",
               agree ? "Y" : "N",
               ok ? "PASS" : "FAIL");
    }
    if (pass == n) {
        printf("ALL %d FROZEN BINDING TESTS PASS (ref == sub == expected)\n", n);
        return 0;
    } else {
        printf("BINDING FAILURES: %d/%d PASSED\n", pass, n);
        return 1;
    }
}
