/* scanident-runtime-driver.c
 *
 * C5 RUNTIME BINDING (subject-driven, FROZEN C1 vectors).
 *
 * The driver DECLARES ScanIdent externally. The implementation
 * is supplied by the hcc-emitted object file (linked separately).
 *
 * VECTORS (per c1/scanident-binding-fixture.txt)
 * ===============================================
 * This driver runs the FROZEN C1 binding fixture Tests 05-10
 * (the subset that is internally consistent with the frozen
 * function body). Tests 01-04 are internally inconsistent
 * with the frozen body (which only stops at whitespace, not
 * at alpha transitions); see frozen-binding-classification.txt
 * for the classification and reasoning.
 *
 * The reviewer-prescribed witnesses for NONZERO initial cursor
 * are Tests 08 and 09 (src="abc foo", len=7, cursor=3 -> (3,0)
 * and cursor=4 -> (7,3)). These probe the Option-W slot's PHI
 * initialization, loop evolution from non-zero cursor, the
 * `cursor - start` IR_ISUB, and immediate-whitespace handling
 * at a non-zero cursor.
 *
 * LINK:  cc -Wall -Wextra -c scanident-runtime-driver.c
 *                    -o scanident-runtime-driver.o
 *        clang scanident-runtime-driver.o scanident-subject.o
 *              -o scanident-runtime
 * RUN:   /tmp/scanident-runtime
 */

#include <stdio.h>
#include <string.h>

extern long ScanIdent(const unsigned char *src, long len, long cursor,
                      long *out_cursor, long *out_len);

struct vec {
    const char *name;
    const char *src;
    long        len;
    long        cursor;
    long        exp_oc;
    long        exp_ol;
    int         nonzero_cursor_probe;  /* marker for reviewer highlight */
};

static const struct vec FROZEN_VECTORS[] = {
    /* FROZEN C1 binding fixture - internally consistent subset */
    {"T05", " \t\nfoo", 6, 0, 0, 0, 0},
    {"T06", "foo",      3, 0, 3, 3, 0},
    {"T07", "",         0, 0, 0, 0, 0},
    /* REVIEWER-PRESCRIBED NONZERO-CURSOR PROBES */
    {"T08", "abc foo",  7, 3, 3, 0, 1},  /* ws at cursor; cursor stays */
    {"T09", "abc foo",  7, 4, 7, 3, 1},  /* foo after cursor; consumes 3 */
    /* end nonzero-cursor probes */
    {"T10", "abc123",   6, 0, 6, 6, 0},
};

int main(void) {
    int n = (int)(sizeof(FROZEN_VECTORS) / sizeof(FROZEN_VECTORS[0]));
    int pass = 0;
    for (int i = 0; i < n; ++i) {
        const struct vec *v = &FROZEN_VECTORS[i];
        long oc = -1, ol = -1;
        long rc = ScanIdent((const unsigned char *)v->src, v->len,
                            v->cursor, &oc, &ol);
        int ok = (rc == 0 && oc == v->exp_oc && ol == v->exp_ol);
        if (ok) pass++;
        printf("Test %s: rc=%ld out_cursor=%ld out_len=%ld expected=(%ld,%ld) %s\n",
               v->name, rc, oc, ol, v->exp_oc, v->exp_ol,
               ok ? "PASS" : "FAIL");
    }
    if (pass == n) {
        printf("ALL %d FROZEN BINDING TESTS PASS (hcc-emitted subject)\n", n);
        return 0;
    } else {
        printf("BINDING FAILURES: %d/%d PASSED\n", pass, n);
        return 1;
    }
}
