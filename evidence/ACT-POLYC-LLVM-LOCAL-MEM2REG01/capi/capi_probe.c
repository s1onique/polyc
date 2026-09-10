/* ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q4.1 C-API probe
 * --------------------------------------------------------
 * Minimal harness that links against LLVM 22.1.8 via the
 * C API and exercises both LLVMRunPasses (module-level)
 * and LLVMRunPassesOnFunction (function-level) on a
 * hand-built module whose CFG matches the single_cond_probe
 * RED fixture.
 *
 * Required: LLVM 22.x development files on disk.
 *
 * The harness:
 *   1. parses a hand-written LLVM IR file (argv[1]),
 *      OR builds an in-memory module equivalent;
 *   2. calls LLVMRunPasses(M, "mem2reg,verify", NULL, opts);
 *   3. prints the module IR to stdout;
 *   4. disposes.
 *
 * argv[1] is REQUIRED (path to an .ll file).
 *
 * Captured output: stdout prints the post-pipeline IR;
 *                  stderr prints the verdict and any error.
 *
 * This file is RECON-only evidence; it is NOT part of the
 * PolyC build. It links against the project's LLVM
 * distribution to characterise the C API surface for the
 * future CORRECTION01 IMPL.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <llvm-c/Core.h>
#include <llvm-c/Error.h>
#include <llvm-c/IRReader.h>
#include <llvm-c/Transforms/PassBuilder.h>

static void diagnostic_handler(LLVMDiagnosticInfoRef DI, void *Ctx) {
    (void)DI; (void)Ctx;
    fprintf(stderr, "LLVM diagnostic emitted (handler stub)\n");
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <input.ll>\n", argv[0]);
        return 2;
    }

    /* 1. Parse the .ll file */
    LLVMMemoryBufferRef MB = NULL;
    char *err = NULL;
    if (LLVMCreateMemoryBufferWithContentsOfFile(argv[1], &MB, &err) != 0) {
        fprintf(stderr, "create membuffer failed: %s\n", err ? err : "(null)");
        LLVMDisposeMessage(err);
        return 1;
    }
    LLVMContextRef Ctx = LLVMGetGlobalContext();
    LLVMModuleRef M = NULL;
    if (LLVMParseIRInContext(Ctx, MB, &M, &err) != 0) {
        fprintf(stderr, "parse IR failed: %s\n", err ? err : "(null)");
        LLVMDisposeMessage(err);
        return 1;
    }

    /* 2. Set up pass builder options */
    LLVMPassBuilderOptionsRef opts = LLVMCreatePassBuilderOptions();
    if (!opts) {
        fprintf(stderr, "LLVMCreatePassBuilderOptions returned NULL\n");
        return 1;
    }

    /* 3. Run LLVMRunPasses (MODULE API) */
    fprintf(stderr, "[probe] calling LLVMRunPasses(M, \"mem2reg,verify\", NULL, opts)\n");
    LLVMErrorRef e1 = LLVMRunPasses(M, "mem2reg,verify", NULL, opts);
    if (e1) {
        char *emsg = LLVMGetErrorMessage(e1); /* consumes e1 */
        fprintf(stderr, "[module-api] LLVMRunPasses returned error: %s\n", emsg ? emsg : "(null)");
        LLVMDisposeErrorMessage(emsg);
    } else {
        fprintf(stderr, "[module-api] LLVMRunPasses returned OK\n");
    }

    /* 4. Run LLVMRunPassesOnFunction (FUNCTION API) on the first
     *    function of the (already-promoted) module. This is a
     *    secondary sanity check. */
    LLVMValueRef first_fn = LLVMGetFirstFunction(M);
    if (first_fn) {
        fprintf(stderr, "[probe] calling LLVMRunPassesOnFunction(fn, \"mem2reg,verify\", NULL, opts)\n");
        LLVMErrorRef e2 = LLVMRunPassesOnFunction(first_fn, "mem2reg,verify", NULL, opts);
        if (e2) {
            char *emsg = LLVMGetErrorMessage(e2); /* consumes e2 */
            fprintf(stderr, "[function-api] LLVMRunPassesOnFunction returned error: %s\n", emsg ? emsg : "(null)");
            LLVMDisposeErrorMessage(emsg);
        } else {
            fprintf(stderr, "[function-api] LLVMRunPassesOnFunction returned OK\n");
        }
    } else {
        fprintf(stderr, "[probe] no first function found in module\n");
    }

    /* 5. Print the module IR */
    char *ir = LLVMPrintModuleToString(M);
    if (ir) {
        printf("%s", ir);
        LLVMDisposeMessage(ir);
    }

    /* 6. Dispose */
    LLVMDisposePassBuilderOptions(opts);
    LLVMDisposeModule(M);
    LLVMDisposeMemoryBuffer(MB);

    fprintf(stderr, "[probe] done\n");
    return 0;
}
