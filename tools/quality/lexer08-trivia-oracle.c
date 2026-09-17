// tools/quality/lexer08-trivia-oracle.c
//
// ACT-POLYC-SELFHOST-LEXER03 C2 IMPL -- production trivia
// (comment + whitespace) oracle.
//
// Independent C99 reference of EXACTLY the production trivia
// scanning logic from src/lexer.c (lexSkipCodeComment plus the
// inline whitespace cases in lexCore; "the R-H region"). It is
// parameterised by (src, src_len, cursor, flags) so it can be
// exercised from a standalone harness.
//
// ORACLE_CLASS = TEST_ONLY_PRODUCTION_EXTRACTION:
//   the body of this file is a verbatim extraction of the
//   production logic, byte-for-byte, modulo two mechanical
//   adaptations required to make it standalone:
//     - The cursor/buffer model is bounded (no Lexer struct).
//     - The CCF_* flags are simulated via a parameter.
//     - Diagnostics are not raised: EOF cases are surfaced as
//       truncated comments (no raise; matches the legacy
//       "editor reality" behavior).
//
// The PolyC subject (tools/bootstrap/selfhost-lexer-trivia.HC)
// is compared against this oracle via
// tools/quality/lexer08-direct-differential.c.
//
// Result kind grammar (binding):
//   TRIVIA_NONE     0  -- not a trivia byte at cursor
//   TRIVIA_WS       1  -- single whitespace byte
//   TRIVIA_NL       2  -- single newline byte
//   TRIVIA_COMMENT  3  -- full comment span consumed
//
// Flag bits (matching src/lexer.h CCF_* definitions):
//   CCF_ACCEPT_WHITESPACE  (1 << 0)
//   CCF_ACCEPT_NEWLINES    (1 << 1)
//   CCF_ACCEPT_COMMENTS    (1 << 2)
//   CCF_ASM_BLOCK          (1 << 4)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef long long I64;
typedef unsigned long long U64;
typedef unsigned char U8;

#define TRIVIA_NONE       0
#define TRIVIA_WS         1
#define TRIVIA_NL         2
#define TRIVIA_COMMENT    3

#define TRIVIA_CCF_ASM_BLOCK         (1 << 4)
#define TRIVIA_CCF_ACCEPT_WHITESPACE (1 << 0)
#define TRIVIA_CCF_ACCEPT_NEWLINES   (1 << 1)
#define TRIVIA_CCF_ACCEPT_COMMENTS   (1 << 2)

static U8 oracle_peek(const U8 *src, I64 src_len, I64 pos)
{
    if (pos < 0) return 0;
    if (pos >= src_len) return 0;
    return src[pos];
}

/* Exact port of lexSkipCodeComment's cursor advance + lineno
 * accounting. The 'end' cursor and lineno delta are returned
 * via out parameters; the wrapper applies state mutations. */
static I64 oracle_skip_code_comment(const U8 *src, I64 src_len, I64 cursor,
                                    I64 *out_end, I64 *out_lineno_delta)
{
    I64 start = cursor;
    I64 delta = 0;
    I64 p = cursor;
    U8 ch = oracle_peek(src, src_len, p);
    U8 next = oracle_peek(src, src_len, p + 1);
    if (ch != '/' || (next != '/' && next != '*')) {
        *out_end = cursor;
        *out_lineno_delta = 0;
        return -1; /* not a comment */
    }
    p += 2;
    if (next == '/') {
        /* // .. \n */
        while (p < src_len) {
            U8 b = src[p];
            if (b == '\n') break;
            if (b == 0) break;
            p++;
        }
    } else {
        /* /\* .. *\/ */
        while (p < src_len) {
            U8 b = src[p];
            if (b == 0) break;
            if (b == '*' && oracle_peek(src, src_len, p + 1) == '/') {
                p += 2;
                *out_end = p;
                *out_lineno_delta = delta;
                return 0; /* comment consumed */
            }
            if (b == '\n') delta++;
            p++;
        }
        /* truncated at EOF: consume to end-of-buffer (no raise) */
    }
    *out_end = p;
    *out_lineno_delta = delta;
    return 0;
}

/* Exact port of the lexCore whitespace cases ('\r' '\n' '\t' ' ').
 * Returns the kind that lexCore would emit (after CCF_ACCEPT_*
 * filtering) and the lineno delta; end is cursor+1. */
static I64 oracle_try_whitespace(U8 ch, I64 flags)
{
    if (ch == ' ' || ch == '\t') {
        if (flags & TRIVIA_CCF_ACCEPT_WHITESPACE) return TRIVIA_WS;
        return TRIVIA_NONE;
    }
    if (ch == '\n' || ch == '\r') {
        if (flags & TRIVIA_CCF_ACCEPT_NEWLINES) return TRIVIA_NL;
        return TRIVIA_NONE;
    }
    return -1;
}

/* The oracle mirrors the legacy lexCore dispatch ordering:
 *   1. whitespace cases first ('\r' '\n' '\t' ' ')
 *   2. comments second ('/' '+ '/' or '/' '+ '*')
 * For non-trivia bytes the oracle returns NO_OUTPUT with end=cursor.
 */
I64 OracleScanTrivia(const U8 *src, I64 src_len, I64 cursor, I64 flags,
                     I64 *out_end, I64 *out_kind, I64 *out_lineno_delta,
                     I64 *out_comment_started)
{
    *out_end = cursor;
    *out_kind = TRIVIA_NONE;
    *out_lineno_delta = 0;
    *out_comment_started = 0;

    if (cursor < 0) return 0;
    if (cursor >= src_len) return 0;

    U8 ch = oracle_peek(src, src_len, cursor);
    I64 ws_kind = oracle_try_whitespace(ch, flags);
    if (ws_kind >= 0) {
        I64 nl_delta = 0;
        if (ch == '\n') nl_delta = 1;
        /* '\r' alone: nl_delta = 0 (matches legacy behavior) */
        *out_end = cursor + 1;
        *out_kind = ws_kind;
        *out_lineno_delta = nl_delta;
        return ws_kind == TRIVIA_NONE ? 0 : 1;
    }

    /* Comment path. */
    I64 comment_end = 0;
    I64 comment_delta = 0;
    I64 rc = oracle_skip_code_comment(src, src_len, cursor,
                                      &comment_end, &comment_delta);
    if (rc >= 0) {
        *out_end = comment_end;
        *out_comment_started = 1;
        *out_lineno_delta = comment_delta;
        if (flags & TRIVIA_CCF_ACCEPT_COMMENTS) {
            *out_kind = TRIVIA_COMMENT;
            return 1;
        }
        *out_kind = TRIVIA_NONE;
        return 0;
    }

    /* Not a trivia byte. */
    *out_end = cursor;
    *out_kind = TRIVIA_NONE;
    *out_lineno_delta = 0;
    *out_comment_started = 0;
    return 0;
}

/* Self-test entry point. */
int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <test-name>\n", argv[0]);
        return 1;
    }
    if (strcmp(argv[1], "selftest") == 0) {
        struct {
            const char *name;
            const U8 *src;
            I64 src_len;
            I64 cursor;
            I64 flags;
            I64 exp_rc;
            I64 exp_end;
            I64 exp_kind;
            I64 exp_lineno;
            I64 exp_cstart;
        } cases[] = {
            { "ws_only", (const U8 *)" \t abc", 6, 0,
              TRIVIA_CCF_ACCEPT_WHITESPACE,
              1, 1, TRIVIA_WS, 0, 0 },
            { "nl_only", (const U8 *)"\nabc", 4, 0,
              TRIVIA_CCF_ACCEPT_NEWLINES,
              1, 1, TRIVIA_NL, 1, 0 },
            { "ws_nl_mixed", (const U8 *)" \t\n abc", 7, 0,
              TRIVIA_CCF_ACCEPT_WHITESPACE | TRIVIA_CCF_ACCEPT_NEWLINES,
              1, 1, TRIVIA_WS, 0, 0 },
            { "line_comment_to_nl", (const U8 *)"// hi\nfoo", 8, 0,
              TRIVIA_CCF_ACCEPT_COMMENTS,
              1, 5, TRIVIA_COMMENT, 0, 1 },
            { "line_comment_to_eof", (const U8 *)"// hi", 5, 0,
              TRIVIA_CCF_ACCEPT_COMMENTS,
              1, 5, TRIVIA_COMMENT, 0, 1 },
            { "block_single", (const U8 *)"/* hi */\nfoo", 11, 0,
              TRIVIA_CCF_ACCEPT_COMMENTS,
              1, 8, TRIVIA_COMMENT, 0, 1 },
            { "block_multi", (const U8 *)"/* line1\nline2\n*/\nfoo", 19, 0,
              TRIVIA_CCF_ACCEPT_COMMENTS,
              1, 17, TRIVIA_COMMENT, 2, 1 },
            { "block_truncated", (const U8 *)"/* never closed", 14, 0,
              TRIVIA_CCF_ACCEPT_COMMENTS,
              1, 14, TRIVIA_COMMENT, 0, 1 },
        };
        I64 n = sizeof(cases) / sizeof(cases[0]);
        I64 pass = 0;
        I64 fail = 0;
        for (I64 i = 0; i < n; i++) {
            I64 end = 0, kind = 0, ldelta = 0, cstart = 0;
            I64 rc = OracleScanTrivia(cases[i].src, cases[i].src_len,
                                       cases[i].cursor, cases[i].flags,
                                       &end, &kind, &ldelta, &cstart);
            I64 ok = (rc == cases[i].exp_rc) &&
                     (end == cases[i].exp_end) &&
                     (kind == cases[i].exp_kind) &&
                     (ldelta == cases[i].exp_lineno) &&
                     (cstart == cases[i].exp_cstart);
            if (ok) {
                printf("PASS  %s\n", cases[i].name);
                pass++;
            } else {
                printf("FAIL  %s rc=%lld (exp %lld) end=%lld (exp %lld) kind=%lld (exp %lld) lineno=%lld (exp %lld) cstart=%lld (exp %lld)\n",
                       cases[i].name, rc, cases[i].exp_rc,
                       end, cases[i].exp_end,
                       kind, cases[i].exp_kind,
                       ldelta, cases[i].exp_lineno,
                       cstart, cases[i].exp_cstart);
                fail++;
            }
        }
        printf("PASS=%lld FAIL=%lld\n", pass, fail);
        return fail == 0 ? 0 : 1;
    }
    fprintf(stderr, "unknown test: %s\n", argv[1]);
    return 2;
}



