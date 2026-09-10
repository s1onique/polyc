/* ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q4.1 C-API probe (v3)
 * --------------------------------------------------------
 * Independent module vs function API verification harness
 * with EXPLICIT, MECHANICAL buffer ownership.
 *
 * Reviewer corrections applied in v3:
 *
 * (a) FUNCTION-API INDEPENDENCE (was v2, kept here):
 *     Each fixture is parsed TWICE from disk into two
 *     independent MemoryBuffers + two independent Modules.
 *     The module API runs on module A; the function API runs
 *     on module B. They share no state. This makes the
 *     function-API evidence load-bearing for the
 *     LLVMRunPassesOnFunction recommendation in CORRECTION01.
 *
 * (b) BUFFER OWNERSHIP (the SIGSEGV root cause):
 *     LLVMParseIRInContext DOCS ITSELF AS CONSUMING THE
 *     MEMORY BUFFER ("The memory buffer is consumed by this
 *     function. This is deprecated. Use LLVMParseIRInContext2
 *     instead."). The v2 harness used it and then called
 *     LLVMDisposeMemoryBuffer on the buffer it had already
 *     consumed, producing a double-free / use-after-free
 *     during cleanup.
 *
 *     v3 uses LLVMParseIRInContext2 which does NOT consume
 *     the buffer; the caller owns it and disposes it exactly
 *     once, on the success path AND on every error path.
 *     This is the explicit, mechanical ownership contract.
 *
 * (c) FLUSH BEFORE DISPOSE (was v2, kept here):
 *     printf("%s", ir) on a redirected stdout is fully
 *     buffered. The dispose sequence can crash on this LLVM
 *     build; fflush(stdout) before any dispose keeps the IR
 *     capture durable.
 *
 * (d) CLEANUP-EXIT-0 (new in v3):
 *     The harness prints a final
 *         [probe] CLEANUP-EXIT-0 (return 0)
 *     line on stderr ONLY after every dispose has run and
 *     the function is about to return 0. The reviewer
 *     requires process exit = 0 across all 3 fixtures;
 *     that line is the in-process witness. The shell
 *     exit code is independently verified by the runner
 *     script (cleanup-exit.txt).
 *
 * argv[1] is REQUIRED (path to an .ll file).
 *
 * Captured output:
 *   stdout : post-pipeline IR for both APIs in two sections.
 *   stderr : verdict, any error from each API call, and the
 *            final CLEANUP-EXIT-0 confirmation.
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

/* Parse a .ll file into a freshly-allocated module.
 *
 * OWNERSHIP CONTRACT (v3):
 *   On success, *out_mb holds a LLVMMemoryBufferRef that the
 *   caller OWNS and MUST dispose exactly once via
 *   LLVMDisposeMemoryBuffer. The module is parsed via
 *   LLVMParseIRInContext2 which does NOT consume the buffer.
 *
 *   On failure, the buffer has already been disposed
 *   internally by this function (cannot leak on error) and
 *   *out_mb is set to NULL so the caller does not double-
 *   dispose.
 *
 * Returns NULL on failure (and prints a diagnostic). */
static LLVMModuleRef parse_fresh(const char *path,
                                 LLVMContextRef Ctx,
                                 LLVMMemoryBufferRef *out_mb) {
    LLVMMemoryBufferRef MB = NULL;
    char *err = NULL;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path, &MB, &err) != 0) {
        fprintf(stderr, "[probe] create membuffer failed for %s: %s\n",
                path, err ? err : "(null)");
        LLVMDisposeMessage(err);
        *out_mb = NULL;
        return NULL;
    }
    LLVMModuleRef M = NULL;
    /* LLVMParseIRInContext2: caller OWNS the buffer; do NOT
     * dispose it on the success path here. */
    if (LLVMParseIRInContext2(Ctx, MB, &M, &err) != 0) {
        fprintf(stderr, "[probe] parse IR failed for %s: %s\n",
                path, err ? err : "(null)");
        LLVMDisposeMessage(err);
        LLVMDisposeMemoryBuffer(MB);
        *out_mb = NULL;
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
         * follows can crash. The verdict line on stderr is
         * unbuffered, so it survives; the IR stdout must be
         * flushed explicitly to do the same. */
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

    int exit_code = 0;
    LLVMMemoryBufferRef mbA = NULL;
    LLVMMemoryBufferRef mbB = NULL;
    LLVMModuleRef MA = NULL;
    LLVMModuleRef MB = NULL;
    LLVMValueRef first_fn = NULL;

    /* ---- Probe A: MODULE API, fresh module ---- */
    fprintf(stderr,
            "[probe-A] fresh parse -> LLVMRunPasses(M, \"mem2reg,verify\", NULL, opts)\n");
    MA = parse_fresh(path, Ctx, &mbA);
    if (!MA) {
        exit_code = 1;
        goto cleanup;
    }
    LLVMErrorRef eA = LLVMRunPasses(MA, "mem2reg,verify", NULL, opts);
    if (eA) {
        char *emsg = LLVMGetErrorMessage(eA);
        fprintf(stderr, "[module-api] LLVMRunPasses returned error: %s\n",
                emsg ? emsg : "(null)");
        LLVMDisposeErrorMessage(emsg);
        fprintf(stderr, "[module-api] VERDICT: FAIL\n");
        exit_code = 1;
    } else {
        fprintf(stderr, "[module-api] LLVMRunPasses returned OK\n");
        fprintf(stderr, "[module-api] VERDICT: PASS (fresh module, module API)\n");
    }
    print_module(MA, "MODULE-API RESULT (fresh parse, LLVMRunPasses only)");

    /* ---- Probe B: FUNCTION API, fresh module ----
     *
     * CRITICAL: this is a FRESH PARSE (mbB, MB), not the
     * same module that the module API just promoted. This
     * is what makes the function-API evidence load-bearing
     * for the recommendation in CORRECTION01. */
    fprintf(stderr,
            "[probe-B] fresh parse -> LLVMRunPassesOnFunction(fn, \"mem2reg,verify\", NULL, opts)\n");
    MB = parse_fresh(path, Ctx, &mbB);
    if (!MB) {
        exit_code = 1;
        goto cleanup;
    }
    first_fn = LLVMGetFirstFunction(MB);
    if (!first_fn) {
        fprintf(stderr, "[probe-B] no first function found in fresh module\n");
        exit_code = 1;
        goto cleanup;
    }
    LLVMErrorRef eB = LLVMRunPassesOnFunction(first_fn, "mem2reg,verify", NULL, opts);
    if (eB) {
        char *emsg = LLVMGetErrorMessage(eB);
        fprintf(stderr, "[function-api] LLVMRunPassesOnFunction returned error: %s\n",
                emsg ? emsg : "(null)");
        LLVMDisposeErrorMessage(emsg);
        fprintf(stderr, "[function-api] VERDICT: FAIL\n");
        exit_code = 1;
    } else {
        fprintf(stderr, "[function-api] LLVMRunPassesOnFunction returned OK\n");
        fprintf(stderr, "[function-api] VERDICT: PASS (fresh module, function API)\n");
    }
    print_module(MB, "FUNCTION-API RESULT (fresh parse, LLVMRunPassesOnFunction only)");

cleanup:
    /* ---- Cleanup ----
     *
     * v3 OWNERSHIP CONTRACT:
     *   - Each LLVMMemoryBufferRef was obtained via
     *     LLVMCreateMemoryBufferWithContentsOfFile and
     *     survives (because LLVMParseIRInContext2 does NOT
     *     consume it). Dispose exactly once here, only if
     *     the pointer is non-NULL.
     *   - Each LLVMModuleRef was obtained via
     *     LLVMParseIRInContext2; dispose only if non-NULL.
     *   - LLVMPassBuilderOptionsRef always non-NULL here.
     *   - first_fn is owned by MB; do NOT dispose it.
     *
     * On the success path this disposes: MB, mbB, MA, mbA,
     * opts. On every early-exit path it disposes whatever
     * subset was actually allocated. No double-free is
     * possible because every pointer is nulled before
     * disposal would re-run.
     */
    if (MB)  LLVMDisposeModule(MB);
    if (mbB) LLVMDisposeMemoryBuffer(mbB);
    if (MA)  LLVMDisposeModule(MA);
    if (mbA) LLVMDisposeMemoryBuffer(mbA);
    if (opts) LLVMDisposePassBuilderOptions(opts);

    if (exit_code == 0) {
        fprintf(stderr, "[probe] CLEANUP-EXIT-0 (return 0)\n");
    } else {
        fprintf(stderr, "[probe] CLEANUP-EXIT-NONZERO (return %d)\n", exit_code);
    }
    return exit_code;
}
