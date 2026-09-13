# ACT-POLYC-TOOLING-SHELL-BUDGET01 / C2 IMPL evidence

Entry identity at C2 start:

```text
branch:       main
parent:       6d822df (C2 IMPL part 3)
worktree:     clean
```

This directory captures the C2 implementation evidence:
the budget manifest, the verifier, the negative test
packet, the migration queue, and the migrated-path
zero-budget ratchet test.

## Files

| File                              | Purpose                                |
|-----------------------------------|----------------------------------------|
| `budget-before.tsv`               | SHELL-BUDGET.tsv at C2 IMPL start      |
| `budget-after.tsv`                | SHELL-BUDGET.tsv at C2 IMPL end (identical to before; this ACT does not change existing rows) |
| `migration-queue.tsv`             | Mechanically ranked Track-B candidates |
| `score.py`                        | Reproducible scoring script            |
| `verifier-tests.txt`              | N1..N10 negative test packet results   |
| `migrated-path-test.txt`          | B3 zero-budget invariant witness       |
| `aggregate-monotonicity.txt`      | B9 aggregate monotonicity freeze       |
| `gate-results.txt`                | Fresh current-tree gate output         |
| `README.md`                       | This file                              |

## New artifacts created in C2 IMPL

```text
docs/factory/SHELL-BUDGET.tsv              43 rows, 1 MIGRATED
scripts/quality/shell-budget-gate.sh        38 LOC, hard cap compliant
scripts/quality/shell-budget-gate-test.sh   42 LOC, hard cap compliant
```

## Aggregate measurements (C2 freeze)

```text
TRACKED_SHELL_FILES     = 43   (42 tracked + 1 MIGRATED row)
TOTAL_SHELL_LOC         = 9337
GRANDFATHERED_FILES     = 36
GRANDFATHERED_LOC       = 9173
CURRENT_SHELL_DEBT      = 9173
SHELL_DEBT_BUDGET       = 9175   (2 LOC slack for MIGRATED baseline)
TINY_FILES              = 7      (incl. new shell-budget-gate.sh + shell-budget-gate-test.sh)
```

## Migration queue winner

```text
rank=1  scripts/quality/factory-halt-classification-test.sh  (182 LOC)
        score=17  category=NEEDS_FACTORY_REDESIGN  iso=1  runtime=4
        oracle=5  dep=5  risk=1
```

The migration queue's top row becomes the next Track-B
migration ACT. Subject is `factory-halt-classification`
(checker + test runner migrate together as a unit).
