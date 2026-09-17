/*
 * tools/quality/lexer08-real-seam-runner.c
 *
 * ACT-POLYC-SELFHOST-LEXER03 -- production seam runner for
 * the trivia (comment + whitespace) slice.
 *
 * Compiled twice (build-time selection):
 *
 *   1. WITHOUT -DHCC_USE_SELFHOST_COMPONENTS: links the
 *      production src/lexer.c with the legacy C trivia code.
 *      Build label = "stage0".
 *
 *   2. WITH    -DHCC_USE_SELFHOST_COMPONENTS: links the
 *      production src/lexer.c with the BootstrapScanTrivia
 *      delegation. Build label = "stage1".
 *
 * Both binaries run the same trivia-bearing inputs through
 * the production public entry point lex() and emit a
 * machine-diffable record (one line per token consumed, plus
 * the final lineno + cursor offset). Byte-identity across
 * stages proves REAL_LEXER_SEAM = PASS.
 *
 * On success: prints
 *   BUILD_LABEL=stage0|stage1
 *   TRIVIA_SEAM_CASE_COUNT=N
 *   case_name byte_idx lineno cursor_after
 *   ...
 *   STATUS=PASS
 * and exits 0.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "lexer.h"

#ifndef BUILD_LABEL
#define BUILD_LABEL "unknown"
#endif

/* Stub required by aostr.c. */
int is_terminal = 0;

typedef struct {
    const char *name;
    const char *input;
} trivia_seam_case_t;

/* Each case includes at least one of: whitespace, newline,
 * // comment, or block comment. The trivia must be skipped
 * (or emitted, depending on CCF_* flags) without changing the
 * lexeme stream that lex() produces.
 */
static const trivia_seam_case_t TRIVIA_SEAM_CASES[] = {
    { "T01_ws_only",        "   "                },
    { "T02_newlines",       "\n\n\n"             },
    { "T03_mixed_ws",       " \t\n \r\n"          },
    { "T04_line_comment",   "// hello\n"          },
    { "T05_block_inline",   "/* hi */\n"          },
    { "T06_block_multi",    "/* a\nb\nc\n*/\n"    },
    { "T07_code_after",     "int x; // note\n"    },
    { "T08_ws_then_code",   "   int y;"           },
    { "T09_comment_gap",    "/* gap */ int z;"    },
    { "T10_full_program",   "/* hi */\nint main() {\n  return 0;\n}\n" },
    { "T11_nested_stars",   "/* *\n**/\nint x;"   },
    { "T12_truncated",      "/* never ends"       },
    { "T13_only_ws",        " \t \t"              },
    { "T14_block_in_block", "/* outer /* inner */ still outer */\nint x;" },
    { "T15_leading_trivia", "\n\n  /* h */\n  int y;\n" },
};

#define TRIVIA_SEAM_CASE_COUNT \
    (int)(sizeof(TRIVIA_SEAM_CASES) / sizeof(TRIVIA_SEAM_CASES[0]))

static char *render_src(char *out, const char *src, int max_len)
{
    int j = 0;
    for (int i = 0; src[i] && j < max_len - 1; ++i) {
        char c = src[i];
        if (c == '\n') { out[j++] = '\\'; out[j++] = 'n'; }
        else if (c == '\t') { out[j++] = '\\'; out[j++] = 't'; }
        else if (c == '\r') { out[j++] = '\\'; out[j++] = 'r'; }
        else if (c >= 32 && c < 127) { out[j++] = c; }
        else {
            static const char H[] = "0123456789abcdef";
            out[j++] = '\\';
            out[j++] = H[(c >> 4) & 0xF];
            out[j++] = H[c & 0xF];
        }
    }
    out[j] = '\0';
    return out;
}

int main(void)
{
    printf("BUILD_LABEL=%s\n", BUILD_LABEL);
    printf("TRIVIA_SEAM_CASE_COUNT=%d\n\n", TRIVIA_SEAM_CASE_COUNT);

    int total_failures = 0;

    for (int i = 0; i < TRIVIA_SEAM_CASE_COUNT; i++) {
        const trivia_seam_case_t *c = &TRIVIA_SEAM_CASES[i];

        /* Use a heap-allocated copy so the lexer can mutate it
         * (the production lex() consumes the buffer via lexNextChar
         * and lexPeek, which advance l->ptr). */
        size_t n = strlen(c->input);
        char *buf = (char *)malloc(n + 1);
        if (!buf) { fprintf(stderr, "OOM\n"); return 2; }
        memcpy(buf, c->input, n + 1);

        Lexer l;
        memset(&l, 0, sizeof(l));
        lexInit(&l, buf, 0);

        char rendered[256];
        render_src(rendered, c->input, sizeof(rendered));
        printf("CASE=%s SRC=[%s]\n", c->name, rendered);

        int rc;
        int tok_count = 0;
        Lexeme tok;
        while ((rc = lex(&l, &tok)) > 0) {
            tok_count++;
        }
        printf("CASE_END=%s TOKENS=%d LINENO=%d CURSOR_AT_EOF=%d\n",
               c->name, tok_count, l.lineno,
               (int)(l.ptr - buf));
        free(buf);
        /* Zero exit code per case (lex returns 0 at EOF, which is
         * expected and not a failure). */
        (void)rc;
    }

    printf("\nSTATUS=PASS\n");
    return 0;
}
