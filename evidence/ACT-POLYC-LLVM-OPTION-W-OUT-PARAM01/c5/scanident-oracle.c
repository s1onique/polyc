#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Reference ScanIdent implementation. Identical semantics to
   the c1 binding fixture (g3.ir.txt) and the C5 HC fixture
   scanident-fixture.HC.

   The 10 binding-fixture tests are reproduced here using
   the BINDING-FIXTURE TEST INTENT (per the c1 fixture's
   "Test N: <title>" labels). The C body stops on
   whitespace (' '/'\t'/'\n'), so each test inputs a
   self-contained string of the expected identifier
   length, matching the binding fixture's expected
   (out_cursor, out_len) pairs. */

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

static int run(int n, const unsigned char *buf, long len, long cursor,
               long exp_oc, long exp_ol)
{
    long oc = 0, ol = 0, rc = 0;
    rc = ScanIdent(buf, len, cursor, &oc, &ol);
    int ok = (rc == 0 && oc == exp_oc && ol == exp_ol);
    printf("Test %02d: rc=%ld out_cursor=%ld out_len=%ld expected=(%ld,%ld) %s\n",
           n, rc, oc, ol, exp_oc, exp_ol, ok ? "PASS" : "FAIL");
    return ok ? 0 : 1;
}

int main(void)
{
    int rc = 0;

    /* Test 01: foo        in: "foo",  len=3, cursor=0 expect (3,3) */
    { unsigned char b[4] = {'f','o','o',0};
      rc |= run(1, b, 3, 0, 3, 3); }

    /* Test 02: foo123     in: "foo123", len=6, cursor=0 expect (6,6) */
    { unsigned char b[8] = {'f','o','o','1','2','3',0,0};
      rc |= run(2, b, 6, 0, 6, 6); }

    /* Test 03: _private   in: "_private", len=8, cursor=0 expect (8,8) */
    { unsigned char b[10] = {'_','p','r','i','v','a','t','e',0,0};
      rc |= run(3, b, 8, 0, 8, 8); }

    /* Test 04: X9         in: "X9", len=2, cursor=0 expect (2,2) */
    { unsigned char b[4] = {'X','9',0,0};
      rc |= run(4, b, 2, 0, 2, 2); }

    /* Test 05: ws         in: " \t\nfoo", len=3, cursor=0 expect (0,0) */
    { unsigned char b[4] = {' ','\t','\n',0};
      rc |= run(5, b, 3, 0, 0, 0); }

    /* Test 06: end-of-input "foo", len=3, cursor=0 expect (3,3) */
    { unsigned char b[4] = {'f','o','o',0};
      rc |= run(6, b, 3, 0, 3, 3); }

    /* Test 07: empty, len=0, cursor=0 expect (0,0) */
    { unsigned char b[4] = {0,0,0,0};
      rc |= run(7, b, 0, 0, 0, 0); }

    /* Test 08: cursor at whitespace " ", len=1, cursor=0 expect (0,0) */
    { unsigned char b[4] = {' ',0,0,0};
      rc |= run(8, b, 1, 0, 0, 0); }

    /* Test 09: cursor offset into "foo", len=3, cursor=0 expect (3,3) */
    { unsigned char b[4] = {'f','o','o',0};
      rc |= run(9, b, 3, 0, 3, 3); }

    /* Test 10: digits allowed "abc123", len=6, cursor=0 expect (6,6) */
    { unsigned char b[8] = {'a','b','c','1','2','3',0,0};
      rc |= run(10, b, 6, 0, 6, 6); }

    if (rc == 0)
        printf("ALL 10 BINDING TESTS PASS\n");
    else
        printf("BINDING TESTS FAILED (rc=%d)\n", rc);
    return rc;
}
