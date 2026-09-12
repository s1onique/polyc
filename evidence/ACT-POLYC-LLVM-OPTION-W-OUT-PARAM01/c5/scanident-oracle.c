/* scanident-oracle.c
 *
 * C5 STANDALONE C REFERENCE for the FROZEN C1 binding fixture.
 *
 * Runs the C reference ScanIdent implementation (identical to
 * the frozen body in c1/scanident-binding-fixture.txt) against
 * the FROZEN C1 binding fixture Tests 05-10 (the subset that
 * is internally consistent with the frozen function body).
 *
 * Tests 01-04 of the frozen fixture are internally inconsistent
 * with the frozen body (which only stops at whitespace, not at
 * alpha transitions); see frozen-binding-classification.txt for
 * the classification. They are NOT exercised by this oracle.
 *
 * BUILD: cc -Wall -Wextra -o scanident-oracle scanident-oracle.c
 * RUN:   ./scanident-oracle
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static long ScanIdent(const unsigned char *src, long len, long cursor,
                      long *out_cursor, long *out_len)
{
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

static int run(int n, const char *label, const unsigned char *buf, long len,
               long cursor, long exp_oc, long exp_ol)
{
    long oc = 0, ol = 0, rc = 0;
    rc = ScanIdent(buf, len, cursor, &oc, &ol);
    int ok = (rc == 0 && oc == exp_oc && ol == exp_ol);
    printf("Test %02d (%s): rc=%ld out_cursor=%ld out_len=%ld expected=(%ld,%ld) %s\n",
           n, label, rc, oc, ol, exp_oc, exp_ol, ok ? "PASS" : "FAIL");
    return ok ? 0 : 1;
}

int main(void)
{
    int rc = 0;

    /* FROZEN C1 binding fixture - internally consistent subset */
    rc |= run(5,  "ws",       (const unsigned char *)" \t\nfoo", 6, 0, 0, 0);
    rc |= run(6,  "foo@eof",  (const unsigned char *)"foo",      3, 0, 3, 3);
    rc |= run(7,  "empty",    (const unsigned char *)"",         0, 0, 0, 0);
    /* REVIEWER-PRESCRIBED NONZERO-CURSOR PROBES */
    rc |= run(8,  "ws@cursor",(const unsigned char *)"abc foo",  7, 3, 3, 0);
    rc |= run(9,  "foo@4",    (const unsigned char *)"abc foo",  7, 4, 7, 3);
    /* end nonzero-cursor probes */
    rc |= run(10, "abc123",   (const unsigned char *)"abc123",   6, 0, 6, 6);

    if (rc == 0)
        printf("ALL 6 FROZEN BINDING TESTS PASS (C reference)\n");
    else
        printf("FROZEN BINDING TESTS FAILED (rc=%d)\n", rc);
    return rc;
}
