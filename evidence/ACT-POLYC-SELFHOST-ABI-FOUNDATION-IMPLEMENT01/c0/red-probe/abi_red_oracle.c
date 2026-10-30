/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c0/red-probe/abi_red_oracle.c
 *
 * The INDEPENDENT C oracle. It computes the same decision as the compiled PolyC
 * subject, but it does so WITHOUT the handle layer: it dereferences the real
 * Ast directly. It therefore shares no code path with the ABI under test and
 * can detect a wrong PolyC semantic choice.
 */
#include "ast.h"
#include "abi_red.h"

I64 OracleShouldPrint(Ast *a) {
    if (a == NULL) return -ABI_NULL_HANDLE;
    switch (a->kind) {
        case AST_FUN_PROTO:
        case AST_EXTERN_FUNC:
        case AST_ASM_FUNC_BIND:
            return 0;
        default:
            return 1;
    }
}
