// tools/quality/lexer08-direct-differential.c
//
// ACT-POLYC-SELFHOST-LEXER03 C2 IMPL -- direct differential
// between the PolyC subject (tools/bootstrap/selfhost-lexer-trivia.HC)
// and the C99 oracle (tools/quality/lexer08-trivia-oracle.c).
//
// On success: prints DIRECT_DIFFERENTIAL_TOTAL=N PASS=N FAIL=0
// STATUS=PASS and exits 0.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef long long I64;
typedef unsigned char U8;

extern I64 BootstrapScanTrivia(U8 *src, I64 src_len, I64 cursor, I64 flags,
                               I64 *out_end, I64 *out_kind,
                               I64 *out_lineno_delta,
                               I64 *out_comment_started);
extern I64 OracleScanTrivia(const U8 *src, I64 src_len, I64 cursor, I64 flags,
                            I64 *out_end, I64 *out_kind,
                            I64 *out_lineno_delta,
                            I64 *out_comment_started);

#define CCF_AW (1 << 0)
#define CCF_AN (1 << 1)
#define CCF_AC (1 << 2)

#define F(name, src_lit, cursor, flags) \
    { #name, (const U8 *)(src_lit), sizeof(src_lit)-1, (cursor), (flags) }

typedef struct {
    const char *name;
    const U8 *src;
    I64 src_len;
    I64 cursor;
    I64 flags;
} FX;

int main(int argc, char **argv)
{
    if (argc < 2) return 1;
    FILE *f = fopen(argv[1], "rb");
    if (!f) { fprintf(stderr, "FAIL: cannot open object %s\n", argv[1]); return 1; }
    fclose(f);

    FX fxs[] = {
        /* Class 1: WS-only (5) */
        F(ws_01,        " ",               0, CCF_AW),
        F(ws_02,        "\t",              0, CCF_AW),
        F(ws_03,        "  abc",           0, CCF_AW),
        F(ws_04,        " \tabc",          0, CCF_AW),
        F(ws_05,        "   \t\t  end",    0, CCF_AW),
        /* Class 2: NL-only (5) */
        F(nl_01,        "\nfoo",           0, CCF_AN),
        F(nl_02,        "\rfoo",           0, CCF_AN),
        F(nl_03,        "\r\nfoo",         0, CCF_AN),
        F(nl_04,        "\n",              0, CCF_AN),
        F(nl_05,        "\r",              0, CCF_AN),
        /* Class 3: WS+NL mixed (5) */
        F(mix_01,       " \nfoo",          0, CCF_AW|CCF_AN),
        F(mix_02,       "\t\nfoo",         0, CCF_AW|CCF_AN),
        F(mix_03,       "\n abc",          1, CCF_AW|CCF_AN),
        F(mix_04,       "  \t\nfoo",       0, CCF_AW|CCF_AN),
        F(mix_05,       " \n",             1, CCF_AW|CCF_AN),
        /* Class 4: // to '\n' (5) */
        F(lc_01,        "// hi\nfoo",      0, CCF_AC),
        F(lc_02,        "//\nfoo",         0, CCF_AC),
        F(lc_03,        "// a long comment\nfoo", 0, CCF_AC),
        F(lc_04,        "abc // hi\nfoo",  4, CCF_AC),
        F(lc_05,        "// hi",           0, CCF_AC),
        /* Class 5: // to EOF (5) */
        F(le_01,        "// hi",           0, CCF_AC),
        F(le_02,        "//",              0, CCF_AC),
        F(le_03,        "abc //",          4, CCF_AC),
        F(le_04,        "//",              0, CCF_AC),
        F(le_05,        "// end of source", 0, CCF_AC),
        /* Class 6: block-comment single line (5) */
        F(bs_01,        "/* hi */\nfoo",   0, CCF_AC),
        F(bs_02,        "/**/\nfoo",       0, CCF_AC),
        F(bs_03,        "/*hi*/\nfoo",     0, CCF_AC),
        F(bs_04,        "abc /* hi */ xyz", 4, CCF_AC),
        F(bs_05,        "/* * ** */\nfoo", 0, CCF_AC),
        /* Class 7: block-comment multi-line (5) */
        F(bm_01,        "/* line1\nline2\n*/\nfoo", 0, CCF_AC),
        F(bm_02,        "/* a\nb\nc\n*/foo", 0, CCF_AC),
        F(bm_03,        "/**\n*/\nfoo",    0, CCF_AC),
        F(bm_04,        "x /* a\nb\n*/ y", 2, CCF_AC),
        F(bm_05,        "/* *\n**/\nfoo",  0, CCF_AC),
        /* Class 8: block-comment truncated at EOF (5) */
        F(bt_01,        "/* never closed", 0, CCF_AC),
        F(bt_02,        "/*",              0, CCF_AC),
        F(bt_03,        "/* line1\nline2", 0, CCF_AC),
        F(bt_04,        "abc /* trunc",   4, CCF_AC),
        F(bt_05,        "/* long block comment that never ends", 0, CCF_AC),
        /* Boundary / negative (5) */
        F(neg_01,       "abc",             3, CCF_AW),
        F(neg_02,       "abc",             5, CCF_AW),
        F(neg_03,       "abc",            -1, CCF_AW),
        F(neg_04,       "/abc",            0, CCF_AC),
        F(neg_05,       "/=abc",           0, CCF_AC),
    };

    I64 n = sizeof(fxs)/sizeof(fxs[0]);
    I64 pass = 0, fail = 0, first_fail = -1;
    char first_msg[512] = {0};

    for (I64 i = 0; i < n; i++) {
        I64 pe=0, pk=0, pl=0, pc=0;
        I64 oe=0, ok=0, ol=0, oc=0;
        I64 pr = BootstrapScanTrivia((U8*)fxs[i].src, fxs[i].src_len,
                                      fxs[i].cursor, fxs[i].flags,
                                      &pe, &pk, &pl, &pc);
        I64 or_ = OracleScanTrivia(fxs[i].src, fxs[i].src_len,
                                    fxs[i].cursor, fxs[i].flags,
                                    &oe, &ok, &ol, &oc);
        I64 good = (pr == or_) && (pe == oe) && (pk == ok) &&
                   (pl == ol) && (pc == oc);
        if (good) pass++;
        else {
            fail++;
            if (first_fail < 0) {
                first_fail = i;
                snprintf(first_msg, sizeof(first_msg),
                    "first_fail=%s poly=(rc=%lld end=%lld kind=%lld lineno=%lld cstart=%lld) oracle=(rc=%lld end=%lld kind=%lld lineno=%lld cstart=%lld)",
                    fxs[i].name, pr, pe, pk, pl, pc, or_, oe, ok, ol, oc);
            }
        }
    }

    printf("DIRECT_DIFFERENTIAL_TOTAL=%lld\n", n);
    printf("DIRECT_DIFFERENTIAL_PASS=%lld\n", pass);
    printf("DIRECT_DIFFERENTIAL_FAIL=%lld\n", fail);
    if (fail) { printf("%s\nSTATUS=FAIL\n", first_msg); return 1; }
    printf("STATUS=PASS\n");
    return 0;
}

