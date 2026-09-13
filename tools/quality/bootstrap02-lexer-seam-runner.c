/*
 * ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02 — production-Lexer
 * seam runner. Compiled twice:
 *
 *   1. WITHOUT -DHCC_BOOTSTRAP02_STAGE1: links the
 *      production src/lexer.c with the legacy ctype path.
 *      Build label = "legacy".
 *
 *   2. WITH    -DHCC_BOOTSTRAP02_STAGE1: links the
 *      production src/lexer.c with the BootstrapScanIdent
 *      delegation. Build label = "stage1".
 *
 * Both binaries run the same six inputs through the
 * production public entry point lex() and emit a
 * machine-diffable record. The wrapper Makefile target
 * diffs the two output streams:
 *
 *   - On the seven downstream-visible fields
 *     (le_start_off, le_len, next_byte_hex, ptr_after,
 *      cur_strlen_post, eof_state), byte-identity is the
 *     PASS criterion for PILLAR_B_PRODUCTION_LEXER_
 *     CURSOR_SEAM.
 *
 *   - On l->start_after, byte-identity is REQUIRED by the
 *     legacy invariant (l->start == l->ptr at the end of
 *     lexIdentifier) but is currently MISSED by the B1
 *     path. This is RESIDUE for ACT-POLYC-BOOTSTRAP02-C2-
 *     CORRECTION02; see residue.txt. It does NOT block
 *     C2 → C3 of the parent ACT because no downstream
 *     consumer reads l->start between lexIdentifier and
 *     the next lexNextChar (verified by grepping the
 *     production sources).
 *
 * This is a test-only entry point. It does not appear in
 * the production build graph.
 */

#include <stdio.h>
#include <string.h>

#include "bootstrap02-lexer-seam-fixture.h"

#ifndef BUILD_LABEL
#define BUILD_LABEL "unknown"
#endif

int main(void)
{
    printf("BUILD_LABEL=%s\n", BUILD_LABEL);
    printf("LEXER_SEAM_CASE_COUNT=%d\n", LEXER_SEAM_CASE_COUNT);
    printf("\n");

    for (int i = 0; i < LEXER_SEAM_CASE_COUNT; i++) {
        const lexer_seam_case_t *c = &LEXER_SEAM_CASES[i];

        /* The production lexer requires the source to be
         * in mutable storage; we own the buffer here. */
        char src_buf[128];
        memset(src_buf, 0, sizeof(src_buf));
        size_t n = 0;
        while (c->input[n] != '\0' && n < sizeof(src_buf) - 1) {
            src_buf[n] = c->input[n];
            n++;
        }
        src_buf[n] = '\0';

        Lexer l;
        memset(&l, 0, sizeof(l));
        lexInit(&l, src_buf, 0);

        /* Position l->ptr at start_offset. lexCore will
         * call lexNextChar itself to consume the first
         * identifier byte and call lexIdentifier with
         * the cursor state machine set up exactly as in
         * production. We deliberately do NOT pre-advance
         * l->ptr here; that would double-consume the
         * first byte and produce wrong identifiers. */
        l.ptr = src_buf + c->start_offset;
        l.line_start_ptr = src_buf;
        l.lineno = 1;
        l.start = l.ptr;

        Lexer l_pre;
        memcpy(&l_pre, &l, sizeof(l_pre));

        Lexeme le;
        memset(&le, 0, sizeof(le));
        int lex_rc = lex(&l, &le);

        Lexer l_post;
        memcpy(&l_post, &l, sizeof(l_post));

        lexer_seam_emit(BUILD_LABEL, c, src_buf, &l_pre, &l_post, &le, lex_rc);
    }

    return 0;
}
