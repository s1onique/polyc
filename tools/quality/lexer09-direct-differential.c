// tools/quality/lexer09-direct-differential.c
//
// ACT-POLYC-SELFHOST-LEXER04 C2 IMPL -- direct differential
// between the PolyC subject (tools/bootstrap/selfhost-lexer-link.HC)
// and the C99 oracle (tools/quality/lexer09-link-oracle-impl.c).
//
// Compares, for each fixture:
//   - rc (return code from each)
//   - out_consumed
//   - out_is_path
//   - out_stored_len
//   - out_error
//   - the stored name bytes (strcmp)
//
// On success: prints DIRECT_DIFFERENTIAL_TOTAL=N PASS=N FAIL=0
// STATUS=PASS and exits 0. On any mismatch prints the first
// failing case and exits 1.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef long long I64;
typedef unsigned char U8;

extern I64 BootstrapLinkDirective(U8 *src, I64 src_len, I64 flags,
                                  I64 *out_consumed, I64 *out_is_path,
                                  I64 *out_stored_len, I64 *out_error);

extern I64 OracleScanLinkDirective(const char *src, I64 src_len, I64 flags,
                                   I64 *out_consumed, I64 *out_is_path,
                                   I64 *out_stored_len, I64 *out_error,
                                   char *out_stored_name,
                                   int out_stored_name_cap);

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
    /* Class 3: multiple-link (treated as one directive per call) */
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
        I64 p_consumed = 0, p_is_path = 0, p_stored_len = 0, p_error = 0;
        char p_stored[256] = {0};
        I64 prc = BootstrapLinkDirective((U8*)FXS[i].src,
                                         FXS[i].src_len, 0,
                                         &p_consumed, &p_is_path,
                                         &p_stored_len, &p_error);
        /* Skip the opening punctuation byte to extract body
         * bytes: 1 for '"', 1 for '<', 0 otherwise. */
        I64 body_offset = 0;
        if (FXS[i].src_len > 0) {
            U8 first_byte = FXS[i].src[0];
            if (first_byte == '"' || first_byte == '<') body_offset = 1;
        }
        if (p_error == 0 && p_stored_len > 0 &&
            body_offset + p_stored_len < (I64)sizeof(p_stored)) {
            memcpy(p_stored, FXS[i].src + body_offset,
                   (size_t)p_stored_len);
        }

        I64 o_consumed = 0, o_is_path = 0, o_stored_len = 0, o_error = 0;
        char o_stored[256] = {0};
        I64 orc = OracleScanLinkDirective((const char *)FXS[i].src,
                                           FXS[i].src_len, 0,
                                           &o_consumed, &o_is_path,
                                           &o_stored_len, &o_error,
                                           o_stored, (int)sizeof(o_stored));

        int ok = (prc == orc) &&
                 (p_consumed   == o_consumed) &&
                 (p_is_path    == o_is_path) &&
                 (p_stored_len == o_stored_len) &&
                 (p_error      == o_error) &&
                 (memcmp(p_stored, o_stored,
                         (size_t)(p_stored_len < o_stored_len
                                  ? p_stored_len : o_stored_len)) == 0);
        if (ok) {
            pass = pass + 1;
        } else {
            fail = fail + 1;
            if (first_fail_idx < 0) {
                first_fail_idx = (int)i;
                snprintf(first_msg, sizeof(first_msg),
                    "first_fail=%s "
                    "poly=(rc=%lld consumed=%lld is_path=%lld "
                    "stored_len=%lld error=%lld stored=\"%.*s\") "
                    "oracle=(rc=%lld consumed=%lld is_path=%lld "
                    "stored_len=%lld error=%lld stored=\"%.*s\")",
                    FXS[i].name,
                    prc, p_consumed, p_is_path, p_stored_len, p_error,
                    (int)p_stored_len, p_stored,
                    orc, o_consumed, o_is_path, o_stored_len, o_error,
                    (int)o_stored_len, o_stored);
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
