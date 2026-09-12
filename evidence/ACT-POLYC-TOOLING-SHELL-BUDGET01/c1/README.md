# ACT-POLYC-TOOLING-SHELL-BUDGET01 / C1 RED evidence

Entry identity at C1:

```text
branch: main
commit: e544a48f192606256af9f348befec0c852b6387b
worktree clean: true
```

This directory contains the RED-phase evidence for the
shell-budget ACT. No production code was modified in C1.

## Files

| File                              | Purpose                                           |
|-----------------------------------|---------------------------------------------------|
| `shell-inventory.tsv`             | Every tracked `.sh` with LOC, exec bit, shebang   |
| `tiny-files.txt`                  | Subset of inventory with LOC <= 50                |
| `grandfathered-files.txt`         | Subset of inventory with LOC > 50 (sorted asc)    |
| `current-loc-summary.txt`         | Aggregate measurements and domain breakdown       |
| `existing-gate-capabilities.txt`  | shell-loc-gate.sh capability matrix vs ACT §8 REDs |
| `migrated-files.txt`              | llvm-gep01-test.sh absence proof + RED R3/R4 ref  |
| `red-reproduction.txt`            | Six ACT §15 REDs mechanically demonstrated        |
| `r4-probe.txt`                    | Verbatim probe transcripts for R4                 |
| `migration-score-inputs.tsv`      | Score inputs (sub/redir/if/for/hd/hcc/hp/tf) per file |
| `README.md`                       | This file                                         |

## RED summary

```text
R1  no per-file monotonic budget manifest         RED REPRODUCED
R2  no per-file downward ratchet                  RED REPRODUCED
R3  no MIGRATED-path encoding                     RED REPRODUCED
R4  resurrected migrated path undetected          RED REPRODUCED
R5  no deterministic migration queue              RED REPRODUCED
R6  no aggregate monotonic debt invariant         RED REPRODUCED
```

## Conservation state at C1

The C1 phase makes no production mutation. All existing
conservation gates are preserved. C2 will add the verifier
and re-validate.
