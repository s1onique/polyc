/*
 * ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C5 EVIDENCE-B comparison.
 *
 * For each of the 10 binding-fixture cases, runs BOTH:
 *   - the C reference implementation (in this file, compiled
 *     with cc); and
 *   - the hcc-emitted subject (linked from
 *     scanident-subject.o).
 *
 * Compares the two implementations' outputs case-by-case.
 * If both implementations agree and match the binding
 * fixture's expected outputs, the subject's runtime
 * semantics are equivalent to the reference.
 */

#include <stdio.h>
#include <string.h>

static long ref_ScanIdent(const unsigned char *src, long len, long cursor,
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
    unsigned char buf_ref[16];
    unsigned char buf_sub[16];
    long oc_ref = 0, ol_ref = 0, rc_ref = 0;
    long oc_sub = 0, ol_sub = 0, rc_sub = 0;

    memset(buf_ref, 0, sizeof(buf_ref));
    memset(buf_sub, 0, sizeof(buf_sub));
    if (c->len > 0) {
        memcpy(buf_ref, c->buf, (size_t)c->len);
        memcpy(buf_sub, c->buf, (size_t)c->len);
    }

    rc_ref = ref_ScanIdent(buf_ref, c->len, c->cursor, &oc_ref, &ol_ref);
    rc_sub = ScanIdent(buf_sub, c->len, c->cursor, &oc_sub, &ol_sub);

    int sub_ok = (rc_sub == 0 && oc_sub == c->exp_oc && ol_sub == c->exp_ol);
    int agree = (rc_ref == rc_sub && oc_ref == oc_sub && ol_ref == ol_sub);
    int pass = sub_ok && agree;
    printf("Test %02d (%s): ref=(rc=%ld,oc=%ld,ol=%ld) "
           "sub=(rc=%ld,oc=%ld,ol=%ld) exp=(oc=%ld,ol=%ld) "
           "sub_ok=%s agree=%s %s\n",
           c->n, c->title,
           rc_ref, oc_ref, ol_ref,
           rc_sub, oc_sub, ol_sub,
           c->exp_oc, c->exp_ol,
           sub_ok ? "Y" : "N",
           agree ? "Y" : "N",
           pass ? "PASS" : "FAIL");
    return pass ? 0 : 1;
}

int main(void)
{
    int rc = 0;
    {
        const unsigned char b[] = {'f','o','o'};
        struct case_ c = {1, "foo", b, 3, 0, 3, 3};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {'f','o','o','1','2','3'};
        struct case_ c = {2, "foo123", b, 6, 0, 6, 6};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {'_','p','r','i','v','a','t','e'};
        struct case_ c = {3, "_private", b, 8, 0, 8, 8};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {'X','9'};
        struct case_ c = {4, "X9", b, 2, 0, 2, 2};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {' ','\t','\n'};
        struct case_ c = {5, "ws", b, 3, 0, 0, 0};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {'f','o','o'};
        struct case_ c = {6, "foo@eof", b, 3, 0, 3, 3};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {0};
        struct case_ c = {7, "empty", b, 0, 0, 0, 0};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {' '};
        struct case_ c = {8, "ws@cursor", b, 1, 0, 0, 0};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {'f','o','o'};
        struct case_ c = {9, "foo@4", b, 3, 0, 3, 3};
        rc |= run_case(&c);
    }
    {
        const unsigned char b[] = {'a','b','c','1','2','3'};
        struct case_ c = {10, "abc123", b, 6, 0, 6, 6};
        rc |= run_case(&c);
    }

    if (rc == 0)
        printf("ALL 10 BINDING TESTS PASS (ref == sub == expected)\n");
    else
        printf("BINDING TESTS FAILED (rc=%d)\n", rc);
    return rc;
}