# ACT-POLYC-TOOLING-MIGRATE-GEP01 — C1 RED Evidence

This directory freezes the legacy behavior of
`scripts/quality/llvm-gep01-test.sh` before any migration
work begins.

## Required result (mechanically checkable)

```text
LEGACY_RC=0
LEGACY_GEP01_PASS=30
LEGACY_GEP01_FAIL=0
LEGACY_STATUS=PASS
LEGACY_SHELL_LOC=232
LEGACY_ROW_COUNT=30
LEGACY_PASS_COUNT=30
LEGACY_FAIL_COUNT=0
```

## Files

| File                       | Purpose                                       |
|----------------------------|-----------------------------------------------|
| `legacy.stdout.txt`        | Frozen stdout of legacy harness (61 lines,    |
|                            | 30 PASS rows + section headers + summary)     |
| `legacy.stderr.txt`        | Empty (legacy writes PASS/FAIL to stdout)     |
| `legacy.rc.txt`            | Process exit code from legacy run (0)         |
| `legacy-source.txt`        | Verbatim pre-migration bash source for        |
|                            | review only; `.txt` suffix prevents it being  |
|                            | mistaken for an executable script by the      |
|                            | shell-LOC ratchet                             |
| `legacy-loc.txt`           | `wc -l` of legacy harness (232)               |
| `legacy-toolchain.txt`     | hcc / llvm-as / opt version snapshot          |
| `legacy-rows-raw.txt`      | Full output of `llvm-cap-table-verifier.py`   |
|                            | captured for the capability-status rows       |
| `oracle-matrix.tsv`        | Exactly 30 logical PASS rows; one per legacy  |
|                            | stdout PASS line; columns: ordinal, section,  |
|                            | assertion_id, legacy_result, observable       |
| `environment-freeze.txt`   | HCC / HCC_INSTALL_DIR / LLVM_AS / LLVM_OPT    |
|                            | contract; toolchain prerequisites; exit-code  |
|                            | contract; output contract                     |
| `c1-required-result.txt`   | Machine-readable C1 freeze summary            |

## Verification

```sh
# Confirm 30 PASS rows
grep '^PASS' legacy.stdout.txt | wc -l         # expect 30
grep -c '^FAIL' legacy.stdout.txt              # expect 0
grep 'STATUS=' legacy.stdout.txt               # expect STATUS=PASS

# Confirm oracle-matrix.tsv shape
python3 -c "
import csv
with open('oracle-matrix.tsv') as f:
    r = list(csv.DictReader(f, delimiter='\t'))
assert len(r) == 30, len(r)
assert all(x['legacy_result'] == 'PASS' for x in r), 'expected all PASS'
print('oracle-matrix: OK 30/0')
"
```

End of file.
