/* ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q4.1 C-API probe (v2)
 * --------------------------------------------------------
 * Independent module vs function API verification harness.
 *
 * Reviewer correction (post-C1, pre-C2 HOLD): the v1 harness
 * ran the module API first and then the function API on the
 * SAME (already-promoted) module, which proved only that
 * function mem2reg is a no-op on already-promoted IR -- NOT
 * that function mem2reg actually promotes unpromoted IR.
 *
 * This v2 harness:
 *   1. parses the .ll file TWICE from disk (two independent
 *      MemoryBuffers + two independent Modules);
 *   2. on the FIRST module, calls only LLVMRunPasses;
 *   3. on the SECOND module, calls only
 *      LLVMRunPassesOnFunction on its first function;
 *   4. prints BOTH post-pipeline modules to stdout, tagged
 *      by section header, captured directly from
 *      LLVMPrintModuleToString (no opt out, no copy).
 *
 * argv[1] is REQUIRED (path to an .ll file).
 *
 * Captured output:
 *   stdout : post-pipeline IR for both APIs in two sections.
 *   stderr : verdict and any error from each API call.
 *
 * This file is RECON-only evidence; it is NOT part of the
 * PolyC build.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <llvm-c/Core.h>
#include <llvm-c/Error.h>
#include <llvm-c/IRReader.h>
#include <llvm-c/Transforms/PassBuilder.h>

/* Parse a .ll file into a freshly-allocated module. Returns
 * NULL on failure (and prints a diagnostic). The caller
 * owns the returned LLVMModuleRef and the returned
 * LLVMMemoryBufferRef (passed via *out_mb to dispose). */
static LLVMModuleRef parse_fresh(const char *path,
                                 LLVMContextRef Ctx,
                                 LLVMMemoryBufferRef *out_mb) {
    LLVMMemoryBufferRef MB = NULL;
    char *err = NULL;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path, &MB, &err) != 0) {
        fprintf(stderr, "[probe] create membuffer failed for %s: %s\n",
                path, err ? err : "(null)");
        LLVMDisposeMessage(err);
        return NULL;
    }
    LLVMModuleRef M = NULL;
    if (LLVMParseIRInContext(Ctx, MB, &M, &err) != 0) {
        fprintf(stderr, "[probe] parse IR failed for %s: %s\n",
                path, err ? err : "(null)");
        LLVMDisposeMessage(err);
        LLVMDisposeMemoryBuffer(MB);
        return NULL;
    }
    *out_mb = MB;
    return M;
}

static void print_module(LLVMModuleRef M, const char *tag) {
    char *ir = LLVMPrintModuleToString(M);
    if (ir) {
        printf("; ===== %s =====\n", tag);
        printf("%s", ir);
        /* fflush is REQUIRED here: when stdout is redirected to a
         * file it is fully buffered, and the dispose sequence that
         * follows has historically crashed on this LLVM build. The
         * verdict line on stderr is unbuffered, so it survives; the
         * IR stdout must be flushed explicitly to do the same. */
        fflush(stdout);
        LLVMDisposeMessage(ir);
    }
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
        fprintf(stderr, "[probe] LLVMCreatePassBuilderOptions returned NULL\n");
        return 1;
    }

    /* ---- Probe A: MODULE API, fresh module ---- */
    fprintf(stderr,
            "[probe-A] fresh parse -> LLVMRunPasses(M, \"mem2reg,verify\", NULL, opts)\n");
    LLVMMemoryBufferRef mbA = NULL;
    LLVMModuleRef MA = parse_fresh(path, Ctx, &mbA);
    if (!MA) {
        LLVMDisposePassBuilderOptions(opts);
        return 1;
    }
    LLVMErrorRef eA = LLVMRunPasses(MA, "mem2reg,verify", NULL, opts);
    if (eA) {
        char *emsg = LLVMGetErrorMessage(eA);
        fprintf(stderr, "[module-api] LLVMRunPasses returned error: %s\n",
                emsg ? emsg : "(null)");
        LLVMDisposeErrorMessage(emsg);
        fprintf(stderr, "[module-api] VERDICT: FAIL\n");
    } else {
        fprintf(stderr, "[module-api] LLVMRunPasses returned OK\n");
        fprintf(stderr, "[module-api] VERDICT: PASS (fresh module, module API)\n");
    }
    print_module(MA, "MODULE-API RESULT (fresh parse, LLVMRunPasses only)");

    /* ---- Probe B: FUNCTION API, fresh module ----
     *
     * CRITICAL: this is a FRESH PARSE, not the same module
     * that the module API just promoted. This is what makes
     * the function-API evidence load-bearing for the
     * recommendation in CORRECTION01. */
    fprintf(stderr,
            "[probe-B] fresh parse -> LLVMRunPassesOnFunction(fn, \"mem2reg,verify\", NULL, opts)\n");
    LLVMMemoryBufferRef mbB = NULL;
    LLVMModuleRef MB = parse_fresh(path, Ctx, &mbB);
    if (!MB) {
        LLVMDisposeModule(MA);
        LLVMDisposeMemoryBuffer(mbA);
        LLVMDisposePassBuilderOptions(opts);
        return 1;
    }
    LLVMValueRef first_fn = LLVMGetFirstFunction(MB);
    if (!first_fn) {
        fprintf(stderr, "[probe-B] no first function found in fresh module\n");
        LLVMDisposeModule(MB);
        LLVMDisposeMemoryBuffer(mbB);
        LLVMDisposeModule(MA);
        LLVMDisposeMemoryBuffer(mbA);
        LLVMDisposePassBuilderOptions(opts);
        return 1;
    }
    LLVMErrorRef eB = LLVMRunPassesOnFunction(first_fn, "mem2reg,verify", NULL, opts);
    if (eB) {
        char *emsg = LLVMGetErrorMessage(eB);
        fprintf(stderr, "[function-api] LLVMRunPassesOnFunction returned error: %s\n",
                emsg ? emsg : "(null)");
        LLVMDisposeErrorMessage(emsg);
        fprintf(stderr, "[function-api] VERDICT: FAIL\n");
    } else {
        fprintf(stderr, "[function-api] LLVMRunPassesOnFunction returned OK\n");
        fprintf(stderr, "[function-api] VERDICT: PASS (fresh module, function API)\n");
    }
    print_module(MB, "FUNCTION-API RESULT (fresh parse, LLVMRunPassesOnFunction only)");

    /* ---- Cleanup ---- */
    LLVMDisposeModule(MB);
    LLVMDisposeMemoryBuffer(mbB);
    LLVMDisposeModule(MA);
    LLVMDisposeMemoryBuffer(mbA);
    LLVMDisposePassBuilderOptions(opts);

    fprintf(stderr, "[probe] done\n");
    return 0;
}
