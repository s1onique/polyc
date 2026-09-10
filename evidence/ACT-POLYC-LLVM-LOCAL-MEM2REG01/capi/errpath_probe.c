/* ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- err-path probe
 *
 * Companion to capi_probe.c (v3). Uses the SAME
 * LLVMParseIRInContext2 ownership pattern and runs the
 * module API and the function API with a deliberately bad
 * pipeline string "mem2reggg,verify" to confirm both
 * APIs return a non-NULL LLVMErrorRef that the harness
 * consumes via LLVMGetErrorMessage.
 *
 * argv[1] is REQUIRED (path to an .ll file).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <llvm-c/Core.h>
#include <llvm-c/Error.h>
#include <llvm-c/IRReader.h>
#include <llvm-c/Transforms/PassBuilder.h>

static LLVMModuleRef parse_fresh(const char *path,
                                 LLVMContextRef Ctx,
                                 LLVMMemoryBufferRef *out_mb) {
    LLVMMemoryBufferRef MB = NULL;
    char *err = NULL;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path, &MB, &err) != 0) {
        fprintf(stderr, "[errpath] create membuffer failed for %s: %s\n",
                path, err ? err : "(null)");
        LLVMDisposeMessage(err);
        *out_mb = NULL;
        return NULL;
    }
    LLVMModuleRef M = NULL;
    if (LLVMParseIRInContext2(Ctx, MB, &M, &err) != 0) {
        fprintf(stderr, "[errpath] parse IR failed for %s: %s\n",
                path, err ? err : "(null)");
        LLVMDisposeMessage(err);
        LLVMDisposeMemoryBuffer(MB);
        *out_mb = NULL;
        return NULL;
    }
    *out_mb = MB;
    return M;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <input.ll>\n", argv[0]);
        return 2;
    }
    const char *path = argv[1];
    LLVMContextRef Ctx = LLVMGetGlobalContext();
    LLVMPassBuilderOptionsRef opts = LLVMCreatePassBuilderOptions();
    if (!opts) {
        fprintf(stderr, "[errpath] LLVMCreatePassBuilderOptions returned NULL\n");
        return 1;
    }
    int exit_code = 0;
    LLVMMemoryBufferRef mb = NULL;
    LLVMModuleRef M = parse_fresh(path, Ctx, &mb);
    if (!M) { exit_code = 1; goto cleanup; }

    fprintf(stderr, "[errpath] MODULE API with bad pipeline 'mem2reggg,verify'\n");
    LLVMErrorRef eM = LLVMRunPasses(M, "mem2reggg,verify", NULL, opts);
    if (eM) {
        char *m = LLVMGetErrorMessage(eM);
        fprintf(stderr, "[errpath] module-api error: %s\n", m ? m : "(null)");
        LLVMDisposeErrorMessage(m);
    } else {
        fprintf(stderr, "[errpath] module-api unexpectedly returned OK\n");
        exit_code = 1;
    }

    fprintf(stderr, "[errpath] FUNCTION API with bad pipeline 'mem2reggg,verify'\n");
    LLVMValueRef fn = LLVMGetFirstFunction(M);
    if (!fn) {
        fprintf(stderr, "[errpath] no first function\n");
        exit_code = 1;
        goto cleanup;
    }
    LLVMErrorRef eF = LLVMRunPassesOnFunction(fn, "mem2reggg,verify", NULL, opts);
    if (eF) {
        char *m = LLVMGetErrorMessage(eF);
        fprintf(stderr, "[errpath] function-api error: %s\n", m ? m : "(null)");
        LLVMDisposeErrorMessage(m);
    } else {
        fprintf(stderr, "[errpath] function-api unexpectedly returned OK\n");
        exit_code = 1;
    }

cleanup:
    if (M) LLVMDisposeModule(M);
    if (mb) LLVMDisposeMemoryBuffer(mb);
    if (opts) LLVMDisposePassBuilderOptions(opts);
    if (exit_code == 0) {
        fprintf(stderr, "[errpath] CLEANUP-EXIT-0 (return 0)\n");
    } else {
        fprintf(stderr, "[errpath] CLEANUP-EXIT-NONZERO (return %d)\n", exit_code);
    }
    return exit_code;
}
