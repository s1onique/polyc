# ACT-POLYC-TOOLING-MIGRATE-GEP01 — C2 IMPL Evidence

This directory freezes the dual-run parity between the
legacy Bash harness and the new PolyC harness, plus the
seeded-failure gate that proves the verdict channel is
honest.

## Required result (mechanically checkable)

```text
BASH_LEGACY_RC=0
BASH_LEGACY_GEP01_PASS=30
BASH_LEGACY_GEP01_FAIL=0
BASH_LEGACY_STATUS=PASS

POLYC_RC=0
POLYC_GEP01_PASS=30
POLYC_GEP01_FAIL=0
POLYC_STATUS=PASS

PARITY_ROWS=30
PARITY_MATCH=30
PARITY_MISMATCH=0

SEEDED_FAIL_RC=1
SEEDED_FAIL_GEP01_PASS=29
SEEDED_FAIL_GEP01_FAIL=1
SEEDED_FAIL_STATUS=FAIL

SCRATCH_ISOLATION=PASS
DIRECT_ARGV_AUDIT=PASS
FORBIDDEN_TOKEN_COUNT=0

PATCH_HYGIENE=PASS
NEWLY_INTRODUCED_FINDINGS=0
```

## Files

| File                          | Purpose                                       |
|-------------------------------|-----------------------------------------------|
| `bash.stdout.txt`             | Fresh run of legacy Bash harness (authoritative)|
| `bash.stderr.txt`             | Empty (legacy writes to stdout)               |
| `bash.rc.txt`                 | Exit code from legacy run (0)                 |
| `polyc.stdout.txt`            | Fresh run of new PolyC harness               |
| `polyc.stderr.txt`            | Empty                                         |
| `polyc.rc.txt`                | Exit code from PolyC run (0)                  |
| `polyc.fail-stdout.txt`       | PolyC run with `--mode=fail`                  |
| `polyc.fail-rc.txt`           | Exit code from seeded-fail run (1)            |
| `polyc.fail-stderr.txt`       | Empty                                         |
| `parity-matrix.tsv`           | 30-row per-assertion parity matrix            |
| `verdict-negative-control.txt`| Seeded failure gate documentation             |
| `scratch-isolation.txt`       | Historical GEP01 evidence untouched           |
| `direct-argv-audit.txt`       | Forbidden-token audit on PolyC source         |
| `production-delta.txt`        | Files added vs files not modified in C2       |
| `patch-hygiene.txt`           | `git diff --check` result (rc=0, 0 findings) |
| `c2-required-result.txt`      | Machine-readable C2 freeze summary            |
| `README.md`                   | This directory index + verification recipe    |

## Verification

```sh
# Confirm 30 PASS rows in both harnesses
grep -c '^PASS' bash.stdout.txt        # expect 30
grep -c '^PASS' polyc.stdout.txt       # expect 30
grep 'GEP01_PASS' bash.stdout.txt      # expect GEP01_PASS=30
grep 'GEP01_PASS' polyc.stdout.txt     # expect GEP01_PASS=30

# Confirm seeded failure flips the channel
grep 'GEP01_PASS' polyc.fail-stdout.txt # expect GEP01_PASS=29
grep 'STATUS='      polyc.fail-stdout.txt # expect STATUS=FAIL

# Confirm no historical GEP01 evidence was touched
find evidence/ACT-POLYC-LLVM-GEP01/c3/_tmp -type f
# expect: no output

# Confirm parity row-by-row
awk -F'\t' 'NR>1 {if($6=="MATCH") m++; else mm++} END \
  {print "MATCH="m" MISMATCH="mm}' parity-matrix.tsv
# expect: MATCH=30 MISMATCH=
```

## What C2 is NOT

- C2 is not the cutover. `scripts/quality/llvm-gep01-test.sh`
  is still 232 LOC, untouched, and authoritative.
- C2 does not delete or shrink the Bash harness.
- C2 does not run the conservation gates (those are C3/C4).
- C2 does not move the build wiring into `make` targets.

End of file.
