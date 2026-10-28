/* ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SUB-001 REAL LEGACY ORACLE.
 *
 * This driver reproduces the REAL legacy C decision at
 * src/parser.c:1551..1553 EXACTLY as the live production source
 * writes it, and prints the result for each AstKind value.
 *
 * The decision body below is a SOURCE-BOUND EXTRACTION: it is the
 * three source lines, with `stmt->kind` replaced by the parameter
 * `kind`.  The extraction is verified mechanically by
 * c2/selected-oracle-contract.md, which records the SHA-256 of the
 * live source range and the SHA-256 of this extraction.
 *
 * The oracle is a DRIVER over the extracted decision; it does not
 * re-implement the semantics in a different way.
 */
#include <stdio.h>

#include "ast.h"

/* The extracted legacy decision (src/parser.c:1551..1553). */
static int legacy_arm_terminates(int kind)
{
    if (kind == AST_CASE ||
            kind == AST_DEFAULT || kind == AST_BREAK || kind == AST_RETURN
            || kind == AST_GOTO) return 1;
    return 0;
}

int main(void)
{
    /* Every AstKind value the live enum defines. */
    static const int kinds[] = {
        AST_GVAR, AST_GOTO, AST_LABEL, AST_LVAR, AST_FUNC, AST_DECL,
        AST_STRING, AST_FUNCALL, AST_LITERAL, AST_ARRAY_INIT, AST_IF,
        AST_FOR, AST_RETURN, AST_WHILE, AST_CLASS_REF, AST_COMPOUND_STMT,
        AST_ASM_STMT, AST_ASM_FUNC_BIND, AST_ASM_FUNCALL, AST_FUNPTR,
        AST_FUNPTR_CALL, AST_BREAK, AST_CONTINUE, AST_DEFAULT_PARAM,
        AST_VAR_ARGS, AST_ASM_FUNCDEF, AST_CAST, AST_FUN_PROTO, AST_CASE,
        AST_JUMP, AST_EXTERN_FUNC, AST_DO_WHILE, AST_PLACEHOLDER,
        AST_SWITCH, AST_DEFAULT, AST_SIZEOF, AST_COMMENT, AST_BINOP,
        AST_UNOP, AST_TRY, AST_THROW
    };
    int n = (int)(sizeof(kinds) / sizeof(kinds[0]));
    for (int i = 0; i < n; i++) {
        printf("%d\t%d\n", kinds[i], legacy_arm_terminates(kinds[i]));
    }
    /* Also probe the values OUTSIDE the enum, to bound the domain. */
    for (int k = -4; k <= 0; k++) {
        printf("%d\t%d\n", k, legacy_arm_terminates(k));
    }
    for (int k = 296; k <= 300; k++) {
        printf("%d\t%d\n", k, legacy_arm_terminates(k));
    }
    return 0;
}
