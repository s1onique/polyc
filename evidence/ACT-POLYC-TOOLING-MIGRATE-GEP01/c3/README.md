# ACT-POLYC-TOOLING-MIGRATE-GEP01 — C3 CUTOVER Evidence

The legacy Bash GEP harness `scripts/quality/llvm-gep01-test.sh`
(232 LOC) is **deleted**. The PolyC harness
`tools/quality/llvm-gep01-test.HC` is now canonical.

## Required result (mechanically checkable)

```text
GEP_SHELL_LOC_REDUCTION = 232 -> 0
GEP_SHELL_FILE_REDUCTION = 1 -> 0
TOTAL_SHELL_FILE_REDUCTION = 23 -> 22
TOTAL_SHELL_LOC_REDUCTION = 6184 -> 5952

POLYC_RC = 0
POLYC_GEP01_PASS = 30
POLYC_GEP01_FAIL = 0
POLYC_STATUS = PASS

CONSERVATION_GATES = PASS (2 ENVIRONMENTALLY_UNAVAILABLE documented)
BUILD_FRESHNESS = PASS
NO_STALE_BINARY = TRUE
```

## Files

| File                          | Purpose                                       |
|-------------------------------|-----------------------------------------------|
| `polyc.stdout.txt`            | Fresh PolyC run post-cutover                 |
| `polyc.stderr.txt`            | Empty                                         |
| `polyc.rc.txt`                | Exit code (0)                                 |
| `build_log.txt`               | Compile log showing fresh binary              |
| `shell-debt-accounting.txt`   | Pre/post LOC + file-count table              |
| `conservation-gates.txt`      | All gate results, with EA notes              |
| `build-freshness.txt`         | Evidence binary was freshly built             |
| `c3-required-result.txt`      | Machine-readable C3 freeze summary            |
| `README.md`                   | This directory index                          |

## Verification

```sh
# Confirm Bash file is gone
ls scripts/quality/llvm-gep01-test.sh
# expect: No such file or directory

# Confirm shell-LOC debt reduction
bash scripts/quality/inventory.sh | wc -l   # expect 22 (was 23)
bash scripts/quality/shell-loc-gate.sh      # expect PASS

# Confirm PolyC harness still works
./hcc --install-dir=$(pwd)/build/test-prefix \
      -o llvm-gep01-test tools/quality/llvm-gep01-test.HC
./llvm-gep01-test --scratch=build/quality/gep01
# expect: GEP01_PASS=30 STATUS=PASS rc=0

# Confirm historical GEP01 evidence untouched
git status --porcelain | grep '^.. evidence/ACT-POLYC-LLVM-GEP01/'
# expect: no output

# Confirm no Bash shell involvement in PolyC source
grep -nE '/bin/sh|sh -c|bash -c|system\(|popen\(|System\(|Sh\(|Shlurp\(' \
  tools/quality/llvm-gep01-test.HC | grep -v '^.*//' | grep -v '^.*\*'
# expect: no output
```

## What C3 is NOT

- C3 does not run a full `make clean && make` because the
  migration is harness-only; the `./hcc` binary in use is
  the same one used by the legacy harness in C1/C2, so
  the conservation claim is satisfied by the parity tests.
- C3 does not modify ROADMAP.md (that is C4 CLOSE work).
- C3 does not modify any historical evidence packet.

End of file.
