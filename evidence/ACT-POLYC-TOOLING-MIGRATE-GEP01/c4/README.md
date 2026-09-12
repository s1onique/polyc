# ACT-POLYC-TOOLING-MIGRATE-GEP01 — C4 CLOSE Evidence

The PolyC GEP01 migration is closed PASS.

## Required result (mechanically checkable)

```text
VERDICT = PASS
FUNCTIONAL_EQUIVALENCE = TRUE
SHELL_DEBT_REDUCTION   = TRUE

PRE_GEP_SHELL_LOC = 232
POST_GEP_SHELL_LOC = 0

POLYC_FINAL_RC = 0
POLYC_FINAL_GEP01_PASS = 30
POLYC_FINAL_GEP01_FAIL = 0
POLYC_FINAL_STATUS = PASS

CONSERVATION_GATES = PASS (2 ENVIRONMENTALLY_UNAVAILABLE)
BUILD_FRESHNESS = PASS
DIRECT_ARGV_AUDIT = PASS
PATCH_HYGIENE = PASS
FALSE_GREEN_CONTROL = PASS
HISTORICAL_EVIDENCE_INTEGRITY = PRESERVED
WORKTREE = clean
```

## Files

| File                          | Purpose                                       |
|-------------------------------|-----------------------------------------------|
| `polyc-final.stdout.txt`      | Final fresh PolyC run stdout                  |
| `polyc-final.stderr.txt`      | Empty                                         |
| `polyc-final.rc.txt`          | Final PolyC run exit code (0)                 |
| `llvm-byte-memory01.stdout.txt` | Final conservation gate stdout              |
| `ac-matrix.txt`               | 45-row AC matrix (all PASS)                  |
| `closure-summary.txt`         | Authoritative closure summary                 |
| `residue.txt`                 | F11 residue classification                    |
| `c4-required-result.txt`      | Machine-readable C4 freeze summary            |
| `README.md`                   | This directory index                          |

## Verification

```sh
# Confirm 4 ACT commits in trajectory
git log --all-match \
        --grep='^ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01$' \
        --grep='^ACT-Phase: \(RED\|IMPL\|EVIDENCE\|CLOSE\)$' \
        --pretty=format:'%H %s' | wc -l
# expect: 4

# Confirm C4 commit carries ACT-Phase: CLOSE / ACT-Verdict: PASS
git log -1 --pretty=format:%B | grep -E '^ACT-Phase: CLOSE$|^ACT-Verdict: PASS$'

# Confirm legacy Bash file is deleted
git log --diff-filter=D --name-only --pretty=format: \
  | grep -E '^scripts/quality/llvm-gep01-test\.sh$'
# expect: 1 line (the C3 delete commit)

# Confirm PolyC harness still works
./llvm-gep01-test --scratch=build/quality/gep01 | tail -3
# expect: GEP01_PASS=30 STATUS=PASS
```

## What this ACT accomplished

- Replaced 232 lines of legacy Bash GEP testing with a
  PolyC-native harness that produces identical 30-row
  PASS output.
- Preserved every assertion_id from the legacy oracle
  matrix (PARITY_MATCH=30 PARITY_MISMATCH=0).
- Deleted the legacy Bash harness (preferred Outcome A).
- Reduced tracked shell LOC by 232 (-3.75%).
- Proved the verdict channel is honest via a seeded
  failure gate.
- Did not change any compiler / parser / IR / backend /
  ABI / factory-doctrine semantics.
- Did not mutate any historical evidence packet (F14).
- Did not open SHELL-BUDGET01 (NEXT ACT is named only).

End of file.
