# ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q4.1 C-API probe

## What this directory contains

| File                          | Purpose |
|-------------------------------|---------|
| `capi_probe.c` (v3)           | Q4.1 harness: independent module + function C-API probes. |
| `errpath_probe.c`             | Companion: deliberately-bad pipeline string ("mem2reggg,verify"). |
| `run_capi_probes.sh`          | Runner: builds, runs all fixtures + err-path, captures exit codes. |
| `capi_probe` (binary, not in git) | Built locally by the runner. |
| `errpath_probe` (binary, not in git) | Built locally by the runner. |
| `<fixt>.capi-stdout.txt`      | Per-fixture post-pipeline IR for both APIs. |
| `<fixt>.capi-stderr.txt`      | Per-fixture verdicts + `CLEANUP-EXIT-0` confirmation. |
| `err-path.stderr`             | Both APIs' "unknown pass" error messages + cleanup exit. |
| `cleanup-exit.txt`            | Fixture-by-fixture shell exit-code table. |
| `cleanup-exit-summary.txt`    | One-line `STATUS=PASS\|FAIL` summary. |

## Reviewer corrections across versions

### v1 → v2 (C1.5 RED evidence tightening)

The v1 harness (in C1) ran the module API first and then
the function API on the SAME (already-promoted) module.
That proved only that function mem2reg is a no-op on
already-promoted IR -- NOT that function mem2reg actually
promotes unpromoted IR. The function-API evidence was
vacuous.

v2 fixed this by parsing each fixture TWICE from disk
into independent MemoryBuffers + independent Modules.
The module API runs on module A; the function API runs
on module B. They share no state.

### v2 → v3 (C3 RED evidence tightening)

The v2 harness used `LLVMParseIRInContext` and then
`LLVMDisposeMemoryBuffer(MB)` during cleanup. The LLVM
C API documents `LLVMParseIRInContext` as consuming
the memory buffer:

```c
/**
 * ... The memory buffer is consumed by this function.
 * This is deprecated. Use LLVMParseIRInContext2 instead.
 */
LLVM_C_ABI LLVMBool LLVMParseIRInContext(...);
```

This produced a double-free / use-after-free during
cleanup. The probe crashed AFTER the verdict line on
stderr and AFTER the `fflush(stdout)` of the captured
IR, so the substantive evidence was durable, but the
process did not exit cleanly. The reviewer required
exit=0 across all 3 fixtures as a hard precondition.

v3 fixes this by using `LLVMParseIRInContext2`, which
does NOT consume the buffer. The caller OWNS the
buffer and disposes it exactly once. The captured
substance is unchanged (the IR was already correct),
but the process now exits 0 cleanly.

The v3 ownership contract is documented at the top of
`capi_probe.c` and is mirrored in `errpath_probe.c`.

## How to build + run

```sh
cd evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi

# One-time build
LLVM_INC=/nix/store/b6fykfvclbq81yis03blk6bqsmapmhdm-llvm-22.1.8-dev/include
LLVM_LIB=/nix/store/a1hnp3fv6y7jjl8j3vkcp3qwclxmknba-llvm-22.1.8-lib/lib
clang -O0 -g -I"$LLVM_INC" -L"$LLVM_LIB" \
      -Wl,-rpath,"$LLVM_LIB" capi_probe.c -lLLVM -o capi_probe
clang -O0 -g -I"$LLVM_INC" -L"$LLVM_LIB" \
      -Wl,-rpath,"$LLVM_LIB" errpath_probe.c -lLLVM -o errpath_probe

# Run
./run_capi_probes.sh
cat cleanup-exit-summary.txt
# STATUS=PASS ...
```

## Expected output (current tree)

```text
fixture=single_cond_probe_ENTRY_BLOCK_NAMED_BB1   shell_exit=0  CLEANUP-EXIT-0=1  module-PASS=1  function-PASS=1
fixture=i64_collapse_probe                        shell_exit=0  CLEANUP-EXIT-0=1  module-PASS=1  function-PASS=1
fixture=pos_b0_compare_digit                      shell_exit=0  CLEANUP-EXIT-0=1  module-PASS=1  function-PASS=1
errpath=single_cond_probe_ENTRY_BLOCK_NAMED_BB1   shell_exit=0  CLEANUP-EXIT-0=1  module-err=1  function-err=1

STATUS=PASS  (all 3 fixtures: shell_exit=0, CLEANUP-EXIT-0=1, module-PASS=1, function-PASS=1;
              err-path: shell_exit=0, both-error-msgs=1, CLEANUP-EXIT-0=1)
```

## What the captured IR proves

Each `<fixt>.capi-stdout.txt` has TWO tagged sections:

```text
; ===== MODULE-API RESULT (fresh parse, LLVMRunPasses only) =====
    [post-pipeline IR from LLVMPrintModuleToString]

; ===== FUNCTION-API RESULT (fresh parse, LLVMRunPassesOnFunction only) =====
    [post-pipeline IR from LLVMPrintModuleToString]
```

For each section:
* target `alloca` is gone,
* target `load`/`store` are gone,
* a single `phi` at the natural successor block holds
  per-edge operands matching original PolyC semantics.

The two sections are byte-for-byte identical, proving
that `LLVMRunPassesOnFunction` is a sufficient standalone
promotion API for the bounded IMPL (CORRECTION01).

## What `err-path.stderr` proves

```text
[errpath] MODULE API with bad pipeline 'mem2reggg,verify'
[errpath] module-api error: unknown pass name 'mem2reggg'
[errpath] FUNCTION API with bad pipeline 'mem2reggg,verify'
[errpath] function-api error: unknown function pass 'mem2reggg' in pipeline 'mem2reggg,verify'
[errpath] CLEANUP-EXIT-0 (return 0)
```

Both APIs return a non-NULL `LLVMErrorRef` whose message
the harness consumes via `LLVMGetErrorMessage` +
`LLVMDisposeErrorMessage`. The consumed-error path
cleans up correctly (exit=0). CORRECTION01 must wire
this consumption.

## Out of scope for this ACT id

The probe is RECON-only evidence; it is NOT part of the
PolyC build. CORRECTION01 is the bounded IMPL freeze
that introduces production-grade calls into
`src/llvm-backend.c`. The deferred insertion-point
contract there uses a dedicated entry-block builder
(see ACT §12 RESIDUE P2 / CORRECTION01), NOT a
nonexistent C-API `LLVMSaveInsertPoint`.
