/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe/abi_oracle.c
 *
 * Independent C-only reference witness. It is compiled from the real
 * src/ast.h/src/list.h definitions and reads the objects DIRECTLY. It
 * does not call the handle layer and does not call the PolyC object.
 * Its only job is to produce the expected classification and container
 * state against which the PolyC-driven result is compared.
 */
#include "ast.h"
#include "list.h"

typedef s64 I64;

I64 OracleAstClassify(Ast *a) {
    if (a == NULL) return -1;
    if (a->kind != AST_BINOP) return 100;
    if (a->binop != AST_BIN_OP_ADD) return 300 + (I64)a->binop;
    if (a->left == NULL || a->right == NULL) return -1;
    if (a->left->kind != AST_LITERAL || a->right->kind != AST_LITERAL) return 200;
    return (I64)a->left->i64 * 1000 + (I64)a->right->i64;
}

I64 OracleListCount(List *l) {
    return (I64)listCount(l);
}

I64 OracleListAt(List *l, I64 index) {
    I64 i = 0;
    List *it = l->next;
    while (it != l) {
        if (i == index) return (I64)(u64)it->value;
        i++;
        it = it->next;
    }
    return -1;
}
