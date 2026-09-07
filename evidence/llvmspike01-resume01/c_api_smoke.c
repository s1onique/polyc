/* LLVM 22 C-API smoke test (ACT-POLYC-LLVM-SPIKE01-RESUME01 §9).
 *
 * No PolyC source code is touched. This program demonstrates the
 * minimum LLVM 22 C API required by the LLVM backend spike:
 *
 *   - explicit LLVMContextCreate (no global context APIs)
 *   - module + builder construction under that context
 *   - construct trivial function: define i64 @answer() { ret i64 42 }
 *   - LLVMVerifyModule (ReturnStatusAction)
 *   - LLVMPrintModuleToString
 *   - dispose owned objects in correct order
 *
 * Compile with flags derived mechanically from llvm-config:
 *   cc -cflags $(llvm-config --cflags) -ldflags $(llvm-config --ldflags)
 *      -libs core -lLLVM-22
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "llvm-c/Core.h"
#include "llvm-c/Analysis.h"

int main(void) {
    LLVMContextRef ctx = LLVMContextCreate();
    if (!ctx) {
        fprintf(stderr, "LLVMContextCreate failed\n");
        return 1;
    }

    LLVMModuleRef mod = LLVMModuleCreateWithNameInContext("smoke", ctx);
    if (!mod) {
        fprintf(stderr, "LLVMModuleCreateWithNameInContext failed\n");
        LLVMContextDispose(ctx);
        return 1;
    }

    LLVMTypeRef i64 = LLVMInt64TypeInContext(ctx);
    LLVMTypeRef ret_ty = i64;
    LLVMTypeRef param_tys[] = { };
    LLVMTypeRef fn_ty = LLVMFunctionType(ret_ty, param_tys, 0, 0);
    LLVMValueRef answer = LLVMAddFunction(mod, "answer", fn_ty);
    if (!answer) {
        fprintf(stderr, "LLVMAddFunction failed\n");
        LLVMDisposeModule(mod);
        LLVMContextDispose(ctx);
        return 1;
    }

    LLVMBasicBlockRef entry = LLVMAppendBasicBlockInContext(ctx, answer, "entry");
    if (!entry) {
        fprintf(stderr, "LLVMAppendBasicBlockInContext failed\n");
        LLVMDisposeModule(mod);
        LLVMContextDispose(ctx);
        return 1;
    }

    LLVMBuilderRef bld = LLVMCreateBuilderInContext(ctx);
    if (!bld) {
        fprintf(stderr, "LLVMCreateBuilderInContext failed\n");
        LLVMDisposeModule(mod);
        LLVMContextDispose(ctx);
        return 1;
    }
    LLVMPositionBuilderAtEnd(bld, entry);

    LLVMValueRef c42 = LLVMConstInt(i64, 42, 0);
    if (!c42) {
        fprintf(stderr, "LLVMConstInt failed\n");
        LLVMDisposeBuilder(bld);
        LLVMDisposeModule(mod);
        LLVMContextDispose(ctx);
        return 1;
    }
    LLVMValueRef ret = LLVMBuildRet(bld, c42);
    if (!ret) {
        fprintf(stderr, "LLVMBuildRet failed\n");
        LLVMDisposeBuilder(bld);
        LLVMDisposeModule(mod);
        LLVMContextDispose(ctx);
        return 1;
    }

    char *err = NULL;
    if (LLVMVerifyModule(mod, LLVMReturnStatusAction, &err) != 0) {
        fprintf(stderr, "LLVMVerifyModule: %s\n", err ? err : "(null)");
        if (err) LLVMDisposeMessage(err);
        LLVMDisposeBuilder(bld);
        LLVMDisposeModule(mod);
        LLVMContextDispose(ctx);
        return 1;
    }

    char *ir = LLVMPrintModuleToString(mod);
    if (!ir) {
        fprintf(stderr, "LLVMPrintModuleToString failed\n");
        LLVMDisposeBuilder(bld);
        LLVMDisposeModule(mod);
        LLVMContextDispose(ctx);
        return 1;
    }
    fputs(ir, stdout);
    LLVMDisposeMessage(ir);

    LLVMDisposeBuilder(bld);
    LLVMDisposeModule(mod);
    LLVMContextDispose(ctx);
    return 0;
}
