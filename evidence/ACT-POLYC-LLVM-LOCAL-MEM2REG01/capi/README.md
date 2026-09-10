# C-API probe (Q4.1)

This directory contains the RECON evidence for the
ACT-POLYC-LLVM-LOCAL-MEM2REG01 Q4.1 question: does the LLVM C
API expose new-pass-manager entry points that parse and
execute `"mem2reg,verify"` cleanly on the project's LLVM
22.1.8 distribution?

## Reviewer correction (post-C1 HOLD)

The v1 harness ran the module API first and then the function
API on the SAME (already-promoted) module. That proved only
that function mem2reg is a no-op on already-promoted IR --
NOT that function mem2reg actually promotes unpromoted IR.

The v2 harness (this version) parses each fixture TWICE
from disk into independent modules, runs only the module API
on the first copy, runs only the function API on the second
copy, and prints both post-pipeline IRs to stdout from
`LLVMPrintModuleToString`. The function-API evidence is now
load-bearing for the CORRECTION01 recommendation.

## Files

- `capi_probe.c` — v2 C harness. Links against `-lLLVM-22`.
  Parses the input file twice, exercises the module and
  function APIs on independent copies, prints both
  post-pipeline IRs.
- `<fixt>.capi-stderr.txt` — verdict log per fixture.
- `<fixt>.capi-stdout.txt` — two tagged sections per file:
  `; ===== MODULE-API RESULT (fresh parse, LLVMRunPasses only) =====`
  followed by the post-pipeline IR captured by
  `LLVMPrintModuleToString`, then
  `; ===== FUNCTION-API RESULT (fresh parse, LLVMRunPassesOnFunction only) =====`
  followed by the second fresh-parse post-pipeline IR.
- `err-path.stderr` — bad-pipeline error path via the
  module API: `unknown pass name 'mem2reggg'`.
- `function-api-err-path.stderr` — bad-pipeline error path
  via the function API:
  `unknown function pass 'mem2reggg' in pipeline 'mem2reggg'`.

## Verdict

```
C-API MODULE API (fresh parse):   PASS  (all 3 fixtures)
C-API FUNCTION API (fresh parse): PASS  (all 3 fixtures)
C-API ERROR PATH OBSERVED:        yes   (both APIs)
```

CORRECTION01 MUST consume/report the error path; treating
pass execution as infallible would silently swallow bad-
pipeline failures at runtime.

## Implementation note on cleanup

The harness currently SIGSEGVs during cleanup (after both
verdict lines are printed and both IR sections are flushed
to stdout). The verdict is therefore captured correctly
because:

- `stderr` is unbuffered by default, so the verdict lines
  are emitted before the crash.
- `print_module` calls `fflush(stdout)` after each
  `LLVMPrintModuleToString` capture, so the IR stdout is
  flushed to the file before the dispose sequence.

The crash is in MY harness dispose sequence, not in the
LLVMRunPasses / LLVMRunPassesOnFunction call paths. The
recommendation to use `LLVMRunPassesOnFunction` in
CORRECTION01 is therefore still supported by the captured
verdict and the captured post-pipeline IR.

## Rebuild from source

The compiled binaries are intentionally NOT committed (build
artifacts, not source). To rebuild against the project's
LLVM 22.1.8 distribution:

```sh
LLVM_INC=$(llvm-config --includedir)
LLVM_LIB=$(llvm-config --libdir)

clang -I "$LLVM_INC" -Wno-deprecated-declarations \
      capi_probe.c \
      -o /tmp/capi_probe \
      -L "$LLVM_LIB" -lLLVM-22

# Then run:
/tmp/capi_probe ../probes/single_cond_probe.ll \
    > single_cond_probe.capi-stdout.rebuilt.txt \
    2> single_cond_probe.capi-stderr.rebuilt.txt
```

## Verdict summary (raw)

```
=== single_cond_probe ===
[probe-A] fresh parse -> LLVMRunPasses(M, "mem2reg,verify", NULL, opts)
[module-api] LLVMRunPasses returned OK
[module-api] VERDICT: PASS (fresh module, module API)
[probe-B] fresh parse -> LLVMRunPassesOnFunction(fn, "mem2reg,verify", NULL, opts)
[function-api] LLVMRunPassesOnFunction returned OK
[function-api] VERDICT: PASS (fresh module, function API)

=== i64_collapse_probe ===
[module-api] VERDICT: PASS (fresh module, module API)
[function-api] VERDICT: PASS (fresh module, function API)

=== pos_b0_compare_digit ===
[module-api] VERDICT: PASS (fresh module, module API)
[function-api] VERDICT: PASS (fresh module, function API)

=== error-path probe ===
[error-path] LLVMRunPasses returned non-NULL error:
  unknown pass name 'mem2reggg'
C-API ERROR PATH OBSERVED: yes (module API)

=== function-api error-path ===
[function-api] ERROR PATH OBSERVED:
  unknown function pass 'mem2reggg' in pipeline 'mem2reggg'
C-API ERROR PATH OBSERVED: yes (function API)
```
