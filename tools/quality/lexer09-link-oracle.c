// tools/quality/lexer09-link-oracle.c
//
// ACT-POLYC-SELFHOST-LEXER04 C2 IMPL -- standalone oracle
// binary for the C99 truth. Links the implementation in
// lexer09-link-oracle-impl.c (which mirrors src/lexer.c
// ::lexLink scanning logic byte-for-byte).
//
// Invocation:
//   ./build/lexer09-link-oracle --selftest
//
// Self-test mode runs a fixed battery of inputs through
// OracleScanLinkDirective and prints the results.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef long long I64;
typedef unsigned char U8;

#define ORACLE_LINK_OK              0
#define ORACLE_LINK_ERR_MISSING     1
#define ORACLE_LINK_ERR_INVALID     2
#define ORACLE_LINK_ERR_UNTERM_ANG  3
#define ORACLE_LINK_ERR_UNTERM_QUOT 4
#define ORACLE_LINK_ERR_LEX_FAIL    5

extern I64 OracleScanLinkDirective(const char *src, I64 src_len, I64 flags,
                                   I64 *out_consumed, I64 *out_is_path,
                                   I64 *out_stored_len, I64 *out_error);

#define F(name, src_lit) \
    { #name, (src_lit), sizeof(src_lit) - 1 }

typedef struct {
    const char *name;
    const char *src;
    I64         src_len;
} SELFTEST_CASE;

static const SELFTEST_CASE SELFTEST_CASES[] = {
    F(st_01_qpath,      "\"foo.so\""),
    F(st_02_angle,      "<m>"),
    F(st_03_angle_id,   "<libname>"),
    F(st_04_empty_q,    "\"\""),
    F(st_05_empty_a,    "<>"),
    F(st_06_q_escape,   "\"a\\\"b\""),
    F(st_07_unterm_q,   "\"abc"),
    F(st_08_unterm_a,   "<abc"),
    F(st_09_invalid_t,  "42"),
    F(st_10_no_target,  ""),
    F(st_11_qpath_dots, "\"./foo/bar.so\""),
    F(st_12_angle_nest, "<a/b/c>"),
};

static const char *err_name(I64 e)
{
    switch (e) {
    case ORACLE_LINK_OK:              return "OK";
    case ORACLE_LINK_ERR_MISSING:     return "MISSING";
    case ORACLE_LINK_ERR_INVALID:     return "INVALID";
    case ORACLE_LINK_ERR_UNTERM_ANG:  return "UNTERM_ANG";
    case ORACLE_LINK_ERR_UNTERM_QUOT: return "UNTERM_QUOT";
    case ORACLE_LINK_ERR_LEX_FAIL:    return "LEX_FAIL";
    default:                          return "?";
    }
}

int main(int argc, char **argv)
{
    int selftest = 0;
    for (int i = 1; i < argc; i = i + 1) {
        if (strcmp(argv[i], "--selftest") == 0) selftest = 1;
    }
    if (!selftest) {
        fprintf(stderr,
                "Usage: %s --selftest\n", argv[0]);
        return 2;
    }

    int total = (int)(sizeof(SELFTEST_CASES) / sizeof(SELFTEST_CASES[0]));
    int pass = 0;
    int fail = 0;

    printf("ORACLE_SELFTEST_TOTAL=%d\n", total);
    for (int i = 0; i < total; i = i + 1) {
        I64 out_consumed = 0;
        I64 out_is_path = 0;
        I64 out_stored_len = 0;
        I64 out_error = 0;
        I64 rc = OracleScanLinkDirective(
            SELFTEST_CASES[i].src,
            SELFTEST_CASES[i].src_len,
            0,
            &out_consumed, &out_is_path,
            &out_stored_len, &out_error);
        printf("CASE %s rc=%lld consumed=%lld is_path=%lld "
               "stored_len=%lld err=%s\n",
               SELFTEST_CASES[i].name,
               rc, out_consumed, out_is_path,
               out_stored_len, err_name(out_error));
        int ok = (rc == out_error) &&
                 ((rc == ORACLE_LINK_OK) == (out_consumed > 0));
        if (ok) pass = pass + 1;
        else    fail = fail + 1;
    }

    printf("ORACLE_SELFTEST_PASS=%d\n", pass);
    printf("ORACLE_SELFTEST_FAIL=%d\n", fail);
    if (fail) {
        printf("STATUS=FAIL\n");
        return 1;
    }
    printf("STATUS=PASS\n");
    return 0;
}
