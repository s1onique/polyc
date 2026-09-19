// tools/quality/lexer09-direct-differential.c
//
// ACT-POLYC-SELFHOST-LEXER04 C2 IMPL -- direct differential
// between the PolyC subject (tools/bootstrap/selfhost-lexer-link.HC)
// and the C99 oracle (tools/quality/lexer09-link-oracle-impl.c).
//
// Compares, for each fixture, the four out parameters plus rc:
//   - out_consumed
//   - out_is_path
//   - out_stored_len
//   - out_error
//   - rc (the PolyC returns the body length or 0 on error;
//        oracle returns the same scalar)
//
// The stored-name byte sequence is implicit in (consumed,
// stored_len) agreement with the input layout, since for valid
// directives stored_len == consumed - 2 (the two punctuation
// bytes).
//
// On success: prints DIRECT_DIFFERENTIAL_TOTAL=N PASS=N FAIL=0
// STATUS=PASS and exits 0.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef long long I64;
typedef unsigned char U8;

/* ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 C2 IMPL -- ABI 6
 * signature (extended from CORRECTION02 ABI 5). The harness
 * supplies an out_target_bytes buffer so the production
 * authority path (which writes the verbatim body bytes there)
 * is exercised. */
extern I64 BootstrapLinkDirective(U8 *src, I64 src_len, I64 flags,
                                  U8 *out_target_bytes, I64 out_target_cap,
                                  I64 *out_target_len,
                                  I64 *out_consumed, I64 *out_is_path,
                                  I64 *out_stored_len,
                                  I64 *out_error);
extern I64 OracleScanLinkDirective(const char *src, I64 src_len, I64 flags,
                                   U8 *out_target_bytes, I64 out_target_cap,
                                   I64 *out_target_len,
                                   I64 *out_consumed, I64 *out_is_path,
                                   I64 *out_stored_len,
                                   I64 *out_error);

#define F(name, src_lit) \
    { #name, (const U8 *)(src_lit), sizeof(src_lit) - 1 }

typedef struct {
    const char *name;
    const U8   *src;
    I64         src_len;
} FX;

static const FX FXS[] = {
    /* Class 1: quoted-valid */
    F(LF01_qpath_basic,    "\"foo.so\""),
    F(LF02_qpath_dots,     "\"./foo/bar.so\""),
    F(LF03_qpath_escape,   "\"a\\\"b\""),
    F(LF04_qpath_empty,    "\"\""),
    F(LF05_qpath_single,   "\"x\""),
    /* Class 2: angle-valid */
    F(LF06_angle_basic,    "<m>"),
    F(LF07_angle_id,       "<libname>"),
    F(LF08_angle_empty,    "<>"),
    F(LF09_angle_nest,     "<a/b/c>"),
    F(LF10_angle_punct,    "<a-b_c>"),
    /* Class 3: multiple-link (each call: one directive) */
    F(LF11_multi_first,    "\"liba.so\""),
    F(LF12_multi_second,   "<libb>"),
    /* Class 4: invalid-token */
    F(LF13_invalid_int,    "42"),
    F(LF14_invalid_ident,  "ident"),
    F(LF15_invalid_punct,  ",;"),
    /* Class 5: missing-target */
    F(LF16_missing_empty,  ""),
    F(LF17_missing_ws,     " "),
    /* Class 6: unterminated-quoted */
    F(LF18_unterm_q,       "\"abc"),
    F(LF19_unterm_q_path,  "\"foo.so"),
    /* Class 7: unterminated-angle */
    F(LF20_unterm_a,       "<abc"),
    F(LF21_unterm_a_id,    "<libname"),
    /* Class 8: edge cases */
    F(LF22_angle_digit,    "<a1b2>"),
    F(LF23_angle_underscore, "<_priv>"),
};

int main(int argc, char **argv)
{
    (void)argc; (void)argv;

    I64 n    = (I64)(sizeof(FXS) / sizeof(FXS[0]));
    I64 pass = 0;
    I64 fail = 0;
    int first_fail_idx = -1;
    char first_msg[512] = {0};

    for (I64 i = 0; i < n; i = i + 1) {
        U8 p_target[256] = {0};
        U8 o_target[256] = {0};
        I64 p_target_len = 0, p_consumed = 0, p_is_path = 0;
        I64 p_stored_len = 0, p_error = 0;
        I64 prc = BootstrapLinkDirective((U8*)FXS[i].src,
                                         FXS[i].src_len, 0,
                                         p_target, sizeof(p_target),
                                         &p_target_len,
                                         &p_consumed, &p_is_path,
                                         &p_stored_len, &p_error);

        I64 o_target_len = 0, o_consumed = 0, o_is_path = 0;
        I64 o_stored_len = 0, o_error = 0;
        I64 orc = OracleScanLinkDirective((const char *)FXS[i].src,
                                           FXS[i].src_len, 0,
                                           o_target, sizeof(o_target),
                                           &o_target_len,
                                           &o_consumed, &o_is_path,
                                           &o_stored_len, &o_error);

        /* Compare outputs: scalars AND the verbatim target bytes. */
        int bytes_eq = (p_target_len == o_target_len) &&
                       (memcmp(p_target, o_target, (size_t)p_target_len) == 0);
        int ok = (prc == orc) &&
                 (p_consumed   == o_consumed) &&
                 (p_is_path    == o_is_path) &&
                 (p_stored_len == o_stored_len) &&
                 (p_error      == o_error) &&
                 bytes_eq;
        if (ok) {
            pass = pass + 1;
        } else {
            fail = fail + 1;
            if (first_fail_idx < 0) {
                first_fail_idx = (int)i;
                snprintf(first_msg, sizeof(first_msg),
                    "first_fail=%s "
                    "poly=(rc=%lld consumed=%lld is_path=%lld "
                    "stored_len=%lld error=%lld) "
                    "oracle=(rc=%lld consumed=%lld is_path=%lld "
                    "stored_len=%lld error=%lld)",
                    FXS[i].name,
                    prc, p_consumed, p_is_path, p_stored_len, p_error,
                    orc, o_consumed, o_is_path, o_stored_len, o_error);
            }
        }
    }

    printf("DIRECT_DIFFERENTIAL_TOTAL=%lld\n", n);
    printf("DIRECT_DIFFERENTIAL_PASS=%lld\n", pass);
    printf("DIRECT_DIFFERENTIAL_FAIL=%lld\n", fail);
    if (fail) {
        printf("%s\nSTATUS=FAIL\n", first_msg);
        return 1;
    }
    printf("STATUS=PASS\n");
    return 0;
}
