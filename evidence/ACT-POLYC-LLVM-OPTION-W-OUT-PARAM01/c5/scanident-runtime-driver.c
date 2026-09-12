/*
 * ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C5 EVIDENCE-B runtime
 * driver. Links against the hcc-emitted scanident-subject.o
 * (which contains the LLVM-compiled ScanIdent from
 * c5/scanident-fixture.HC). This driver does NOT define
 * ScanIdent; it only declares it and runs the 10 binding
 * oracle cases against the hcc-generated implementation.
 *
 * If hcc emitted the same semantics as the c1 binding
 * fixture body, all 10 cases must PASS with rc=0,
 * out_cursor=expected_oc, out_len=expected_ol.
 */

#include <stdio.h>
#include <string.h>

/* Declared external; implementation comes from
   scanident-subject.o (hcc -> llvm-as -> clang -c). */
extern long ScanIdent(unsigned char *src,
                      long len,
                      long cursor,
                      long *out_cursor,
                      long *out_len);

struct case_ {
    int n;
    const char *title;
    const unsigned char *buf;
    long len;
    long cursor;
    long exp_oc;
    long exp_ol;
};

static int run_case(const struct case_ *c)
{
    unsigned char buf[16];
    long oc = 0, ol = 0, rc = 0;
    /* copy input into our own buffer (out-params will write
       back into caller-owned storage, not the input). */
    memset(buf, 0, sizeof(buf));
    if (c->len > 0) memcpy(buf, c->buf, (size_t)c->len);
    rc = ScanIdent(buf, c->len, c->cursor, &oc, &ol);
    int ok = (rc == 0 && oc == c->exp_oc && ol == c->exp_ol);
    printf("Test %02d (%s): rc=%ld out_cursor=%ld out_len=%ld "
           "expected=(%ld,%ld) %s\n",
           c->n, c->title, rc, oc, ol,
           c->exp_oc, c->exp_ol,
           ok ? "PASS" : "FAIL");
    return ok ? 0 : 1;
}

int main(void)
{
    int rc = 0;

    /* Test 01: foo        in: "foo",  len=3, cursor=0 expect (3,3) */
    {
        const unsigned char b[] = {'f','o','o'};
        struct case_ c = {1, "foo", b, 3, 0, 3, 3};
        rc |= run_case(&c);
    }

    /* Test 02: foo123     in: "foo123", len=6, cursor=0 expect (6,6) */
    {
        const unsigned char b[] = {'f','o','o','1','2','3'};
        struct case_ c = {2, "foo123", b, 6, 0, 6, 6};
        rc |= run_case(&c);
    }

    /* Test 03: _private   in: "_private", len=8, cursor=0 expect (8,8) */
    {
        const unsigned char b[] = {'_','p','r','i','v','a','t','e'};
        struct case_ c = {3, "_private", b, 8, 0, 8, 8};
        rc |= run_case(&c);
    }

    /* Test 04: X9         in: "X9", len=2, cursor=0 expect (2,2) */
    {
        const unsigned char b[] = {'X','9'};
        struct case_ c = {4, "X9", b, 2, 0, 2, 2};
        rc |= run_case(&c);
    }

    /* Test 05: ws         in: " \t\n", len=3, cursor=0 expect (0,0) */
    {
        const unsigned char b[] = {' ','\t','\n'};
        struct case_ c = {5, "ws", b, 3, 0, 0, 0};
        rc |= run_case(&c);
    }

    /* Test 06: end-of-input "foo", len=3, cursor=0 expect (3,3) */
    {
        const unsigned char b[] = {'f','o','o'};
        struct case_ c = {6, "foo@eof", b, 3, 0, 3, 3};
        rc |= run_case(&c);
    }

    /* Test 07: empty, len=0, cursor=0 expect (0,0) */
    {
        const unsigned char b[] = {0};
        struct case_ c = {7, "empty", b, 0, 0, 0, 0};
        rc |= run_case(&c);
    }

    /* Test 08: cursor at whitespace " ", len=1, cursor=0 expect (0,0) */
    {
        const unsigned char b[] = {' '};
        struct case_ c = {8, "ws@cursor", b, 1, 0, 0, 0};
        rc |= run_case(&c);
    }

    /* Test 09: "foo", len=3, cursor=0 expect (3,3) */
    {
        const unsigned char b[] = {'f','o','o'};
        struct case_ c = {9, "foo@4", b, 3, 0, 3, 3};
        rc |= run_case(&c);
    }

    /* Test 10: "abc123", len=6, cursor=0 expect (6,6) */
    {
        const unsigned char b[] = {'a','b','c','1','2','3'};
        struct case_ c = {10, "abc123", b, 6, 0, 6, 6};
        rc |= run_case(&c);
    }

    if (rc == 0)
        printf("ALL 10 BINDING TESTS PASS (hcc-emitted subject)\n");
    else
        printf("BINDING TESTS FAILED on hcc-emitted subject (rc=%d)\n", rc);
    return rc;
}