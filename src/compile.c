#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "aostr.h"
#include "cctrl.h"
#include "cli.h"
#include "compile.h"
#include "memory.h"
#include "asm.h"
#include "lexer.h"
#include "list.h"
#include "parser.h"
#include "util.h"

/* ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01
 *
 * This translation unit used to include "ast.h" and to decide, inline, which
 * top-level nodes the -ast dump prints. That decision is now made by a
 * component compiled from PolyC source (`AbiCpaShouldPrintAst`), and this TU
 * sees `Ast` only as a forward-declared opaque type (see src/cctrl.h).
 *
 * The selector mirrors the nine existing parser authorities: the compiled
 * PolyC decision is authoritative whenever HCC_USE_SELFHOST_ABI_CPA is defined,
 * which is exactly the configuration the production ./hcc is built with. In a
 * bootstrap stage0 build, or in an explicit selector-OFF build, the legacy
 * inline predicate stays as an honest, independent C oracle -- exactly like
 * the legacy C bodies of the nine parser assistants. */
#ifdef HCC_USE_SELFHOST_ABI_CPA

#include "abi-cpa-host.h"

/* Declared here because this TU deliberately no longer includes "ast.h".
 * astToString takes the Ast as an opaque pointer and lives in src/ast.c, which
 * still owns the layout. */
extern char *astToString(Ast *ast);

#else

#include "ast.h"

#endif

void compilePrintAst(Cctrl *cc) {
    List *it;
    Ast *ast;
    char *tmp;

    printf("AST: \n");

    it = cc->ast_list->next;
    while (it != cc->ast_list) {
        ast = (Ast *)it->value;
        if (ast == NULL) {
            printf("here\n");
        }

#ifdef HCC_USE_SELFHOST_ABI_CPA
        /* The node-visibility decision, made by compiled PolyC. The host
         * owns the token table and the only dereference of the Ast object;
         * this TU decides nothing about kinds. `should_print` is 0 or 1 on
         * success and a negative status when the host refused the handle; a
         * refusal is reported as a compiler error rather than being
         * silently swallowed. */
        {
            s64 handle = AbiCpaIssueAst(ast);
            s64 should_print = AbiCpaShouldPrintAst(handle);
            AbiCpaRetireAst(handle);
            if (should_print < 0) {
                /* FAIL CLOSED: the host refused the borrow. This is an ABI
                 * failure, not a node to be skipped, so the compiler reports
                 * it and stops. It is never silently swallowed. */
                loggerPanic("Cannot decide AST visibility: ABI status %ld\n",
                            (long)should_print);
            }
            if (should_print > 0) {
                tmp = astToString(ast);
                printf("%s\n", tmp);
            }
        }
#else
        if (ast->kind != AST_FUN_PROTO &&
            ast->kind != AST_EXTERN_FUNC &&
            ast->kind != AST_ASM_FUNC_BIND)
        {
            tmp = astToString(ast);
            printf("%s\n", tmp);
        }
#endif
        it = it->next;
    }
}

AoStr *compileToAsm(Cctrl *cc) {
    if (cc->ast_list == NULL) {
        loggerWarning("Create AST before compiling AST\n");
        return NULL;
    }

    AoStr *asmbuf = asmGenerate(cc);
    return asmbuf;
}

void compileToTokens(Cctrl *cc, CliArgs *args, int lexer_flags) {
    Lexer *l = (Lexer *)globalArenaAllocate(sizeof(Lexer));
    char *root_dir = mprintf("%s/include/", args->install_dir);

    lexInit(l,NULL,CCF_PRE_PROC|lexer_flags);
    l->lineno = 1;
    lexSetBuiltinRoot(l,root_dir);

    lexPushFile(l,aoStrDupRaw(args->infile,strlen(args->infile)));

    Lexeme *token = NULL;
    while ((token = lexToken(cc->macro_defs,l))) {
        lexemePrint(token);
    }

    setRelease(l->seen_files);
}

int compileToAst(Cctrl *cc, CliArgs *args, int lexer_flags) {
    Lexer *l = (Lexer *)globalArenaAllocate(sizeof(Lexer));
    AoStr *builtin_path = aoStrPrintf("%s/include/tos.HH", args->install_dir);
    char *root_dir = mprintf("%s/include/", args->install_dir);

    lexInit(l,NULL,CCF_PRE_PROC|lexer_flags);
    l->lineno = 1;
    lexSetBuiltinRoot(l,root_dir);

    lexPushFile(l,aoStrDupRaw(args->infile,strlen(args->infile)));
    /* library files */
    /* the structure is a so this will get popped first */
    lexPushFile(l,builtin_path);

    cctrlInitParse(cc,l);

    parseToAst(cc);

    /* Print any accumulated diagnostics in source order. If the
     * parser saw real errors, bail before handing a half-built
     * AST to the backend - the IR / codegen still hard-panic on
     * malformed input. */
    int n_errors = cctrlDiagFlush(cc);

    lexReleaseAllFiles(l);
    listRelease(l->files,NULL);
    if (n_errors > 0) return 0;
    return 1;
}
