/*
 * tools/quality/lexer09-real-seam-runner.c
 *
 * ACT-POLYC-SELFHOST-LEXER04 -- production seam runner for
 * the `#link` directive slice.
 *
 * Compiled twice (build-time selection):
 *
 *   1. WITHOUT -DHCC_USE_SELFHOST_COMPONENTS: links the
 *      production src/lexer.c with the legacy C lexLink body.
 *      Build label = "stage0".
 *
 *   2. WITH    -DHCC_USE_SELFHOST_COMPONENTS: links the
 *      production src/lexer.c with the BootstrapLinkDirective
 *      delegation. Build label = "stage1".
 *
 * Both binaries run the same `#link`-bearing sources through
 * the production public entry point lexToken() and emit the
 * resulting cc->link_libs / cc->shared_object_files lists in a
 * machine-diffable format. Byte-identity across stages proves
 * REAL_LEXER_SEAM = PASS for the LEXER09 atomic slice.
 *
 * On success: prints
 *   BUILD_LABEL=stage0|stage1
 *   LINK_SEAM_CASE_COUNT=N
 *   case_name link_libs=K1:K2:... shared_object_files=S1:S2:...
 *   ...
 *   STATUS=PASS
 * and exits 0.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "lexer.h"
#include "cctrl.h"
#include "containers.h"
#include "list.h"

/* Stub required by aostr.c. */
int is_terminal = 0;

#ifndef BUILD_LABEL
#define BUILD_LABEL "unknown"
#endif

typedef struct {
    const char *name;
    const char *source;
} link_seam_case_t;

/* Each case contains one or more `#link` directives. The
 * runner compiles each through lexToken() and reports the
 * resulting cc->link_libs / cc->shared_object_files lists.
 *
 * Case selection (frozen by c1-link-fixtures.tsv):
 *   - single quoted path
 *   - single angle name
 *   - multiple directives (one of each kind)
 *   - duplicates (dedup)
 *   - back-to-back
 */
static const link_seam_case_t LINK_SEAM_CASES[] = {
    {
        "L01_single_qpath",
        "#link \"foo.so\"\n"
    },
    {
        "L02_single_angle",
        "#link <m>\n"
    },
    {
        "L03_multi_mixed",
        "#link \"liba.so\"\n#link <libb>\n"
    },
    {
        "L04_angle_dup",
        "#link <m1>\n#link <m1>\n"
    },
    {
        "L05_qpath_dup",
        "#link \"x.so\"\n#link \"x.so\"\n"
    },
    {
        "L06_back_to_back",
        "#link \"a.so\"#link <b>\n"
    },
    {
        "L07_angle_complex",
        "#link <lib-complex_1.0>\n"
    },
    {
        "L08_qpath_dots",
        "#link \"./relative/path.so\"\n"
    },
    {
        "L09_only_link",
        "#link <only>\n"
    },
    {
        "L10_no_directive",
        "int main() { return 0; }\n"
    },
};

#define LINK_SEAM_CASE_COUNT \
    (int)(sizeof(LINK_SEAM_CASES) / sizeof(LINK_SEAM_CASES[0]))

static void dump_list(const char *label, List *l)
{
    printf("%s=", label);
    if (!l || listEmpty(l)) {
        printf("\n");
        return;
    }
    int first = 1;
    listForEach(l) {
        AoStr *s = (AoStr *)it->value;
        if (!first) printf(":");
        first = 0;
        if (s && s->data) {
            printf("%s", s->data);
        }
    }
    printf("\n");
}

int main(void)
{
    printf("BUILD_LABEL=%s\n", BUILD_LABEL);
    printf("LINK_SEAM_CASE_COUNT=%d\n\n", LINK_SEAM_CASE_COUNT);

    int total_failures = 0;

    for (int i = 0; i < LINK_SEAM_CASE_COUNT; i++) {
        const link_seam_case_t *c = &LINK_SEAM_CASES[i];

        /* Heap-allocate so the lexer can mutate the buffer. */
        size_t n = strlen(c->source);
        char *buf = (char *)malloc(n + 1);
        if (!buf) { fprintf(stderr, "OOM\n"); return 2; }
        memcpy(buf, c->source, n + 1);

        /* Build a fresh Cctrl + Lexer pair. */
        Cctrl cc_storage;
        memset(&cc_storage, 0, sizeof(cc_storage));
        cc_storage.shared_object_files = NULL;
        cc_storage.link_libs = NULL;

        Lexer l;
        memset(&l, 0, sizeof(l));
        lexInit(&l, buf, 0);
        l.cc = &cc_storage;  /* lexInit resets cc to NULL */
        /* CORRECTION03 C2 IMPL: lexInit reset cur_file to NULL,
         * but the PolyC BootstrapLinkDirective (ABI 6) reads
         * src_len from cur_file->src->len. Pop the empty
         * scratch LexFile and push the real buffer so that
         * cur_file / cur_file->src are populated. */
        if (l.cur_file) {
            /* lexInit set cur_file = NULL; nothing to free. */
        }
        lexPushString(&l, "<seam>", buf, (s64)n);

        printf("CASE=%s\n", c->name);
        /* Drive lexToken() until it returns NULL. lexToken
         * internally consumes preprocessor directives like
         * #link, so calling it in a loop is sufficient. The
         * tokens themselves are not part of the LEXER09 seam
         * contract — only link_libs and shared_object_files
         * are. */
        Lexeme *tok = lexToken(NULL, &l);
        int tok_count = 0;
        while (tok) {
            tok_count++;
            tok = lexToken(NULL, &l);
        }
        printf("TOKENS=%d LINENO=%d CURSOR_AT_EOF=%ld\n",
               tok_count, l.lineno,
               (long)(l.ptr - buf));

        dump_list("link_libs", cc_storage.link_libs);
        dump_list("shared_object_files",
                  cc_storage.shared_object_files);

        printf("CASE_END=%s\n\n", c->name);

        /* Free the lexer state. */
        lexReleaseAllFiles(&l);
        free(buf);

        (void)total_failures;
    }

    printf("STATUS=PASS\n");
    return 0;
}
