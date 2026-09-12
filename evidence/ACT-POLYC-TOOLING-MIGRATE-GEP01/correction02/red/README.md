# correction02/red — C1 RED evidence

This directory contains the principal RED witnesses for
`ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02`. The ACT
is evidence-only; there is no IMPL phase.

## Files

| File                            | RED witness | Reproduction                                              |
|---------------------------------|-------------|-----------------------------------------------------------|
| `r1-ac07-three-gates.txt`       | R1          | `sh /tmp/r1_run2.sh` (mechanical `make` invocations)      |
| `r2-c4-baseline.txt`            | R2          | `grep -n 'unit-test\|jit-unit-test\|lsp-test' c4/conservation-gates.txt` + manual review of c4 closure-summary |
| `r3-ac08-close-tree.txt`        | R3          | `git diff --check 1732c3f~1..1732c3f`                     |
| `r4-direct-argv-audit.txt`      | R4          | `grep -nE '<pattern>' tools/quality/llvm-gep01-test.HC src/holyc-lib/{tooling,strings}.HC` |

## RED summary

| RED | Finding                                                              | Conclusion                                  |
|-----|----------------------------------------------------------------------|---------------------------------------------|
| R1  | `make unit-test`, `make jit-unit-test`, `make lsp-test` all rc=2     | AC07 NOT_SATISFIED                          |
| R2  | c4 baseline never measured those three gates                        | "counts unchanged" is UNDEFINED for AC07    |
| R3  | `git diff --check 1732c3f~1..1732c3f` flags trailing blank line      | CLOSE tree FAILED AC08                      |
| R4  | Direct-argv: raw=3, comment=3, executable=0                         | DIRECT_ARGV_AUDIT=PASS (executable=0)       |

## Allowed CORRECTION02 production change

NONE. This ACT is evidence-only.
