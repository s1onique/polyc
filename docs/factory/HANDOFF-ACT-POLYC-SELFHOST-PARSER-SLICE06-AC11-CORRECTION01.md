# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01

Factory-Version: 2

## Result

**DISPOSITION: PASS_CORRECTED.**

VERDICT

PASS_CORRECTED

The frozen SLICE06 AC11 set contained 15 negative controls.  The
historical closure did not prove all 15 for their intended reasons:
FC-03 fired the wrong detector, PD-01..PD-03 reported multiple fixture
rows for one semantic-kind mutation, PD-04 and PS-01 were classified
from pristine evidence rather than adversely executed, and the final
AC11 status row omitted PD-04 and PS-01..PS-03.

This correction executed the missing adverse experiments and now joins
all 15 controls to their mutation, intended detector, observed exit,
failure class, provenance, and restoration evidence.

```text
FROZEN_AC11_CONTROL_COUNT=15
EXECUTED_FROZEN_AC11_CONTROL_COUNT=15
UNPROVEN_FROZEN_AC11_CONTROL_COUNT=0
VACUOUS_AC11_PASS_COUNT=0
PRODUCTION_SEMANTIC_DELTA=0
CORRECTION_AC_TOTAL=28
CORRECTION_AC_PASS=28
CORRECTION_AC_FAIL=0
CORRECTION_AC_UNPROVEN=0
```

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.

## What changed

- Added correction-owned PolyC verifiers for exactly-one unknown fixture
  ID and semantic-kind mismatch cardinality.
- Adversely executed PD-04 against a selector-enabled production object
  retaining an active legacy C decision.
- Adversely executed PS-01 against a delegation-disabled production
  object while preserving the PolyC component.
- Re-executed the original pristine differential and historical negative
  targets without changing their frozen meaning.
- Reconfirmed the PolyC-source causal mutation and byte-identical
  restoration using a real production compiler.
- Did not modify production source, bootstrap components, the original
  fixture contract, the ranking, successor authorization, or any closed
  predecessor artifact.

## Evidence

- `c0/closed-artifact-freeze.tsv` -- 126 closed RECON04/SLICE06
  artifacts hash-frozen.
- `c1/reproduction-summary.txt` -- exact historical discrepancies.
- `c2/corrected-controls.txt` -- corrected FC-03, PD-01..PD-04, and
  PS-01..PS-03 execution.
- `c3/control-join.tsv` -- independent 15-ID join.
- `c3/mandatory-ac-status.tsv` -- 28/28 acceptance ledger.
- `c3/parser-conservation-summary.txt` -- 376/376 over 90 files with
  the unchanged assertion-sequence digest.
- `c3/gate-fast.txt`, `c3/gate-push.txt` -- actual PASS gates.

## Production delta

```text
PRODUCTION_SEMANTIC_DELTA=0
PRODUCTION_SOURCE_FILES_CHANGED=0
BOOTSTRAP_COMPONENTS_CHANGED=0
CLOSED_PREDECESSOR_ARTIFACTS_CHANGED=0
```

## Residue

- P1: the F-NO-PYTHON checker still reports its 12 preexisting
  violations and zero new ones; the F-POLYC-TOOLS checker remains
  unavailable.  Both are historical residue, not ACT-owned failures.
- P1: the LEXER07 broad corpus remains FAIL with the unchanged 15
  failure identities; the cross-target run remains the historical 67
  missing-prefix environment failures.  Neither was relabelled PASS.
- P2: no successor is recommended or authorized by this correction.
  SLICE07 and SUB-002 are not selected.

## Recommended next ACT

None.  This correction does not authorize a parser successor.
