/*
 * ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02 — production-Lexer
 * seam fixture header (test-only).
 *
 * Shared by bootstrap02-lexer-seam-legacy.c and
 * bootstrap02-lexer-seam-stage1.c. Both programs link the
 * REAL production src/lexer.c (and its real dependencies)
 * — once with the legacy ctype path (default), once with
 * -DHCC_BOOTSTRAP02_STAGE1 — and exercise the same public
 * entry point lex() on the same six inputs. The two output
 * streams are then diffed; byte-identity establishes
 * PILLAR_B_PRODUCTION_LEXER_CURSOR_SEAM = PASS.
 *
 * This header is test-only. It does not appear in the
 * production build graph; the production graph links
 * src/lexer.c exactly once and through the hcc executable,
 * not through this harness.
 *
 * Why this exercises the production seam:
 *
 *   - The struct Lexer comes from src/lexer.h.
 *   - lexInit, lexCore, lexIdentifier, lexNextChar,
 *     lexRewindChar, lexRaise are all real production
 *     functions from src/lexer.c.
 *   - The harness sets up l->start and l->ptr exactly as
 *     the dispatcher at src/lexer.c:1532 would, then calls
 *     lexIdentifier through lex(). No re-implementation
 *     of the lexer.
 *
 * The reviewer's demand was: "execute the old production
 * scanner and expose l->ptr before, l->ptr after
 * lexIdentifier, l->cur_strlen, the byte subsequently
 * observed by lexCore, EOF/pushback state in the real
 * Lexer." This fixture does exactly that.
 */

/* The production graph defines this in src/main.c (and
 * re-uses src/json-test.c for tests). The harness is a
 * test-only entry point with its own main(), so we provide
 * a stub here to satisfy aostr.c and cli.c references. */
int is_terminal = 0;


#ifndef BOOTSTRAP02_LEXER_SEAM_FIXTURE_H
#define BOOTSTRAP02_LEXER_SEAM_FIXTURE_H

#include <stdio.h>
#include <string.h>

#include "lexer.h"

/* Six reviewer-specified inputs. Each is a NUL-terminated
 * source buffer. The fixture position l->ptr at
 * start_offset, call lexNextChar to simulate the
 * dispatcher's pre-advance (so l->start = start_byte,
 * l->ptr = start_byte + 1), and call lex(). */
typedef struct {
    const char *name;
    const char *input;
    long long   start_offset;
} lexer_seam_case_t;

static const lexer_seam_case_t LEXER_SEAM_CASES[] = {
    { "E1_abc_semicolon", "abc;",       0 },
    { "E2_abc_plus",      "abc+",       0 },
    { "E3_abc_space",     "abc ",       0 },
    { "E4_abc_eof",       "abc",        0 },  /* ends at NUL */
    { "E5_xxabc_offset2", "xxabc;",     2 },
    { "E6_abc_dollar",    "abc$def;",   0 },
};

#define LEXER_SEAM_CASE_COUNT \
    (int)(sizeof(LEXER_SEAM_CASES) / sizeof(LEXER_SEAM_CASES[0]))

/* Emit one record per case. Format is whitespace-tolerant
 * so we can diff with diff(1) directly. We emit RELATIVE
 * OFFSETS (not absolute addresses) so that ASLR between
 * the two builds does not pollute the diff. */
static void lexer_seam_emit(const char *build_label,
                            const lexer_seam_case_t *c,
                            const char *src_base,
                            const Lexer *l_pre,
                            const Lexer *l_post,
                            const Lexeme *le,
                            int lex_rc)
{
    char input_buf[128];
    /* Safe-truncate the input for printing; the buffer is
     * always < 16 bytes in our six cases. */
    size_t n = 0;
    while (c->input[n] != '\0' && n < sizeof(input_buf) - 1) {
        input_buf[n] = c->input[n];
        n++;
    }
    input_buf[n] = '\0';

    /* next_byte: what the next dispatch cycle would read.
     * The production dispatcher does ch = lexNextChar(l),
     * which sets ch = *l->ptr. At end-of-source, ch = 0
     * (NUL) because production source buffers are
     * NUL-terminated. */
    char next_byte = '\0';
    int  eof_state = 0;
    if (l_post->ptr != NULL) {
        next_byte = *l_post->ptr;
        if (next_byte == '\0') {
            eof_state = 1;
        }
        if (l_post->ptr > l_post->start &&
            *(l_post->ptr - 1) == '\0') {
            eof_state = 2;  /* pushback past NUL */
        }
    } else {
        eof_state = 3;  /* ptr is NULL: severe EOF */
    }

    /* Compute relative offsets so diff is ASLR-stable. */
    long long start_before_off = (long long)(l_pre->start - src_base);
    long long ptr_before_off   = (long long)(l_pre->ptr   - src_base);
    long long start_after_off  = (long long)(l_post->start - src_base);
    long long ptr_after_off    = (long long)(l_post->ptr   - src_base);
    long long le_start_off     = (long long)(le->start - src_base);

    printf("CASE %s build=%s\n",
           c->name, build_label);
    printf("  input           = %s\n", input_buf);
    printf("  start_offset    = %lld\n", c->start_offset);
    printf("  lex_rc          = %d\n", lex_rc);
    printf("  tk_type         = %d\n", le->tk_type);
    printf("  start_before    = %lld\n", start_before_off);
    printf("  ptr_before      = %lld\n", ptr_before_off);
    printf("  cur_strlen_pre  = %lld\n",
           (long long)l_pre->cur_strlen);
    printf("  start_after     = %lld\n", start_after_off);
    printf("  ptr_after       = %lld\n", ptr_after_off);
    printf("  cur_strlen_post = %lld\n",
           (long long)l_post->cur_strlen);
    printf("  next_byte_hex   = %02x\n",
           (unsigned int)(unsigned char)next_byte);
    printf("  eof_state       = %d\n", eof_state);
    printf("  le_start_off    = %lld\n", le_start_off);
    printf("  le_len          = %d\n", le->len);
    printf("\n");
}

#endif /* BOOTSTRAP02_LEXER_SEAM_FIXTURE_H */
