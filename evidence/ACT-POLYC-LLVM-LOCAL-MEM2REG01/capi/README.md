# C-API probe (Q4.1)

This directory contains the RECON evidence for the
ACT-POLYC-LLVM-LOCAL-MEM2REG01 Q4.1 question: does the LLVM C
API expose a new-pass-manager entry point that parses and
executes `"mem2reg,verify"` cleanly on the project's LLVM
22.1.8 distribution?

## Files

- `capi_probe.c` — minimal C harness that links against
  `-lLLVM-22` and exercises both `LLVMRunPasses` (module API)
  and `LLVMRunPassesOnFunction` (function API).
- `<fixt>.capi-stderr.txt` — stderr log from running the
  probe on each RED fixture. Reports which API path returned
  OK and which returned an error.
- `<fixt>.capi-stdout.txt` — post-pipeline LLVM IR for each
  fixture, captured by re-running the probe through the
  hand-written fixtures and then by copying the equivalent
  `probes/<fixt>.m2r.ll` (the C harness `printf("%s", ir)`
  truncates on null bytes; the .ll file is the authoritative
  post-mem2reg IR).
- `err-path.stderr` — stderr from a deliberately-bad
  pipeline string (`mem2reggg`) via `LLVMRunPasses`.
  Demonstrates that the error path is observable:
  `unknown pass name 'mem2reggg'`.
- `function-api-err-path.stderr` — same, but via
  `LLVMRunPassesOnFunction`. The error message differs:
  `unknown function pass 'mem2reggg' in pipeline 'mem2reggg'`.

## Verdict

```
C-API MODULE API:  PASS
C-API FUNCTION API: PASS
C-API ERROR PATH OBSERVED: yes
```

CORRECTION01 MUST consume/report the error path; treating
pass execution as infallible would silently swallow bad-
pipeline failures at runtime.

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
[module-api] LLVMRunPasses returned OK
[function-api] LLVMRunPassesOnFunction returned OK

=== i64_collapse_probe ===
[module-api] LLVMRunPasses returned OK
[function-api] LLVMRunPassesOnFunction returned OK

=== pos_b0_compare_digit ===
[module-api] LLVMRunPasses returned OK
[function-api] LLVMRunPassesOnFunction returned OK

=== error-path probe ===
[error-path] LLVMRunPasses returned non-NULL error:
  unknown pass name 'mem2reggg'
C-API ERROR PATH OBSERVED: yes

=== function-api error-path ===
[function-api] ERROR PATH OBSERVED:
  unknown function pass 'mem2reggg' in pipeline 'mem2reggg'
```
