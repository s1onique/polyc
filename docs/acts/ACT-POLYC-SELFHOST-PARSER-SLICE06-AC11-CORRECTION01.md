# ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Priority:** P0
**Repository:** `s1onique/polyc`
**Branch:** `main`
**Expected ENTRY_HEAD:** `cd902c33129a3e57421bbf2fa8c871feb37e29de`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE06`
**Target:** Frozen AC11 negative-control proof integrity

---

## 0. Mission

Establish whether every frozen SLICE06 AC11 negative control actually
failed for its intended reason.  Where evidence is missing, perform the
adverse experiment with real production objects, independently verify the
detector, and append new correction evidence.

This is a bounded proof-correction ACT.  It does not reopen SLICE06's
production migration, change the selected candidate, or revise the
historical CLOSE/PASS commit.

Required final result:

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

Permitted dispositions are `PASS_CORRECTED`, `PASS_REVIEW_ONLY`, and
`HALT_AC11_UNPROVEN`.  The disposition is recorded in the HANDOFF; the
Factory-v2 close commit carries the corresponding repository-approved
verdict trailer.

---

## 1. Binding historical contracts

The correction binds, without rewriting them:

```text
RECON04_CONTRACT=docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04.md
RECON04_NEGATIVE_CONTROLS=evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/selected-negative-controls.md
RECON04_FIXTURE_CONTRACT=evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/selected-fixture-contract.tsv
RECON04_CAUSAL_CONTRACT=evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/selected-causal-contract.md
SLICE06_CONTRACT=docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE06.md
SLICE06_AC11_CONTRACT=evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/c0/mandatory-ac-contract.tsv
SLICE06_CLOSED_EVIDENCE=evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/**
```

The original AC11 predicate is frozen and is not weakened:

```text
AC11: every frozen negative control (FC-01..FC-08, PD-01..PD-04,
PS-01..PS-03) fails for its INTENDED reason
```

The frozen AC11 set contains exactly 15 controls.  The predecessor's
structural-boundary controls SB-01..SB-03 are not part of AC11 and the
closed ranking is not reopened.

The known historical proof gaps are hypotheses to test, not presumed
facts:

1. FC-03 was recorded as `MISSING_IDS=934`, not `UNKNOWN_IDS=1`.
2. PD-01..PD-03 were observed with multiple mismatches where the frozen
   predicate says exactly one mismatch.
3. PD-04 was classified sensitive from pristine evidence rather than
   adversely executed.
4. PS-01 was classified sensitive from pristine evidence rather than
   adversely executed.
5. The final SLICE06 AC11 status row named only FC-01..FC-08 and
   PD-01..PD-03, although AC11's frozen scope also includes PD-04 and
   PS-01..PS-03.

---

## 2. Authorized scope

Permitted tracked mutations:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01/**
tools/quality/parser-slice06-ac11-correction01-*.HC
Makefile
```

New substantive quality verifiers MUST be PolyC.  Shell is permitted only
as bounded bootstrap glue of at most 50 lines per file.

Forbidden mutations:

```text
src/**
tools/bootstrap/**
docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04.md
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE06.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE06.md
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/**
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/**
the original fixture contract
the bootstrap ABI
candidate ranking
successor authorization
```

No new Python.  No new dependencies.  No reset, amend, rebase, force
push, hidden shell-budget workaround, or new parser migration.  This ACT
does not authorize SLICE07 or preselect SUB-002.

---

## 3. C0 — Authorization and baseline

Before tracked mutation, verify and record:

1. actual branch, HEAD, tree, clean status, and zero Git replace refs;
2. predecessor CLOSE reachability and identity;
3. hashes of every closed RECON04 and SLICE06 artifact;
4. a 15-ID reconciliation against actual execution evidence;
5. the exact 28-predicate correction acceptance contract.

Commit C0 with `ACT-Phase: RED`.

---

## 4. C1 — Reproduce discrepancies

Execute the original pristine differential and existing negative-control
targets.  Independently verify FC-03's intended unknown-ID detector.
Reconcile PD-01..PD-03 fixture-row and semantic-kind counts.  Determine
whether PD-04 and PS-01 were executed or only classified sensitive from
pristine evidence.  Recheck PS-02/03.  Preserve exact observed outcomes
and identify every unproven control.

Commit C1 with `ACT-Phase: EVIDENCE`.

---

## 5. C2 — Execute bounded corrections

Repair only proven proof-instrumentation gaps.

1. Prove FC-03's unknown-ID detector fires for exactly one unknown ID.
2. For PD-01..PD-03, retain the original full-fixture observations and
   separately demonstrate the frozen cardinality requirement without
   redefining its meaning.
3. For PD-04, build a selector-enabled adverse production object that
   retains an active legacy C decision and demonstrate the intended
   detector failure.
4. For PS-01, build a delegation-disabled production object while
   preserving the PolyC component and demonstrate the intended detector
   failure.
5. Reconfirm the PolyC-source causal mutation and restoration.
6. Require pristine PASS, adverse targeted FAIL, and restored PASS for
   each relevant control.

If the frozen cardinality or detector obligation cannot be satisfied
without weakening the contract, halt.

Commit C2 with `ACT-Phase: EVIDENCE`.

---

## 6. C3 — Independent verification

Independently join all 15 frozen IDs to their exact input mutation,
intended detector, observed exit, observed failure class, provenance, and
restoration evidence.

Require:

- zero missing, duplicate, or unknown control IDs;
- every adverse control executed against the intended subject;
- every intended detector sensitive;
- no vacuous PASS;
- no production semantic changes;
- previous six PolyC parser authorities conserved;
- parser suite 376/376 and no new failure identities;
- historical LEXER07 and cross-target failures recorded truthfully;
- `gate-fast=PASS` and `gate-push=PASS`;
- Factory-v2, append-only, F14, closure-status and patch-hygiene checks
  PASS;
- no changes to closed predecessor artifacts.

Verify all 28 correction acceptance criteria by exact ID and commit C3
with `ACT-Phase: EVIDENCE`.

---

## 7. C4 — Terminal closure

Only after independently demonstrated acceptance:

1. write a new correction HANDOFF;
2. append the managed handoff-map entry;
3. update the roadmap without editing historical closure evidence;
4. make exactly one terminal CLOSE commit with valid Factory-v2 trailers;
5. run external read-only terminality verification.

The HANDOFF records the specific disposition.  Terminality verification
is read-only and its output is retained outside tracked closed evidence.

---

## 8. Mandatory acceptance contract — exactly 28 predicates

| ID | Required predicate |
|---|---|
| CAC01 | Entry branch, full HEAD, tree, clean worktree, and zero replace refs are verified. |
| CAC02 | The predecessor SLICE06 CLOSE is reachable and its identity is verified. |
| CAC03 | Every closed RECON04 and SLICE06 artifact is hash-frozen and remains byte-unchanged. |
| CAC04 | The original RECON04 and SLICE06 contracts and AC11 predicate are read and bound without rewrite. |
| CAC05 | Exactly 15 frozen AC11 IDs are reconciled with no missing, duplicate, or unknown ID. |
| CAC06 | Each of the 15 IDs has an exact input mutation, intended detector, observed exit, failure class, provenance, and restoration disposition. |
| CAC07 | The original pristine differential is executed against the real legacy oracle and PolyC subject. |
| CAC08 | The original existing negative-control targets are executed and their exact outcomes preserved. |
| CAC09 | FC-03's unknown-ID detector is independently implemented/verified and fires for exactly one unknown ID. |
| CAC10 | The original full-fixture PD-01..PD-03 observations remain recorded without redefinition. |
| CAC11 | PD-01..PD-03 separately demonstrate the frozen exactly-one semantic mismatch cardinality. |
| CAC12 | PD-04 is adversely executed against a selector-enabled production object retaining an active legacy C decision. |
| CAC13 | PD-04's object-level legacy-condition detector is independently verified sensitive. |
| CAC14 | PS-01 is adversely executed against a delegation-disabled production object while the PolyC component remains present. |
| CAC15 | PS-01's delegation-load-bearing detector is independently verified sensitive. |
| CAC16 | PS-02's PolyC-source causal mutation changes compiled-program output with a successful build. |
| CAC17 | PS-03 restores byte-identical source and output after the causal mutation. |
| CAC18 | Every relevant control has pristine PASS, adverse targeted FAIL, and restored PASS evidence. |
| CAC19 | No adverse control passes vacuously or is classified from pristine evidence alone. |
| CAC20 | Production source, bootstrap ABI, fixture contract, ranking, and successor authorization are unchanged. |
| CAC21 | The previous six PolyC parser authorities remain production-authoritative. |
| CAC22 | Parser host-architecture assertions are 376/376 with no new failure identities. |
| CAC23 | Historical LEXER07 and cross-target failures are recorded truthfully with no new failure identities. |
| CAC24 | `make gate-fast` and `make gate-push` actually run and PASS. |
| CAC25 | Factory-v2, append-only, F14, closure-status, patch-hygiene, no-Python, and PolyC-tools checks run with truthful outcomes. |
| CAC26 | The 28 predicates are joined by exact ID with 28 PASS, zero FAIL, and zero UNPROVEN. |
| CAC27 | The HANDOFF, handoff-map, roadmap, and one terminal CLOSE carry the exact disposition without rewriting historical evidence. |
| CAC28 | External read-only terminality verification confirms the final commit, trailers, range, and immutable predecessor artifacts. |

---

## 9. Halt conditions

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_CONTRACT_MISMATCH
HALT_CLOSED_ARTIFACT_MUTATED
HALT_AC11_UNPROVEN
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_FROZEN_CARDINALITY_UNSATISFIABLE
HALT_PRODUCTION_SEMANTIC_CHANGE
HALT_NEW_FAILURE_IDENTITY
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_INVARIANT
HALT_MANDATORY_AC
HALT_TERMINALITY
```

A HALT is a valid outcome.  Preserve successful observations; do not
weaken a frozen predicate to obtain PASS.
