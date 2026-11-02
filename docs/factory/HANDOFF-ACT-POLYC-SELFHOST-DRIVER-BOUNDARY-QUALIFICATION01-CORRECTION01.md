# ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01 — CLOSE

VERDICT

PASS_WITH_DISCLOSED_PRE_EXISTING_FAILURE

The correction was performed properly and its machinery is sound. The
PREDECESSOR'S AUDITED CLAIM DID NOT HOLD: **fourteen of the
predecessor's forty-nine reported PASSes are NOT supported by the
witness the predecessor cited**, and the predecessor's three count
representations of the same fifty-row ledger all disagree with each
other.

This close changed **no** production file. The `F_NO_PYTHON` check is
NON-GREEN with twelve violations, every one of them PRE-EXISTING at
the predecessor close and none touched by this correction. That
failure is DISCLOSED with the exact identity of each violation and is
NOT converted into a PASS.

```text
ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01

IDENTITY
ENTRY_HEAD=8e84a6d8a35b174543cd5a994834eeb625979c16
ENTRY_TREE=8ac90db197bc406f8eb06341b00a7e509c2e5dfd
FINAL_HEAD=<the terminal CLOSE commit, queried from Git>
FINAL_TREE=<the terminal CLOSE commit's tree, queried from Git>
WORKTREE_STATUS=CLEAN
BRANCH=main
REPLACE_REFS=0
PREDECESSOR_CLOSE=edfc3b16620e8d84b00a276984109a3b2fa8b338
PREDECESSOR_POST_CLOSE=907af8c82abfb2292d5eccfdf18b63080da767f2

RED
The THREE PRINCIPAL REDs REPRODUCE against the committed predecessor
objects. They were measured at C1, before the correction verifier
existed.

  R1  FROZEN PHASE DRIFT
      5 rows drift: AC14 AC15 AC16 AC17 AC18.
      The frozen phase and the ledger phase disagree.

  R3  THE THREE COUNT REPRESENTATIONS DISAGREE
      criterion rows PASS:49 FAIL:0 DEFERRED:1
      ledger summary    PASS:49 FAIL:0 DEFERRED:2
      handoff           PASS:46 FAIL:0 DEFERRED:5
      Three representations of the same 50-row ledger. None of the
      three agrees with the others.

  R5  WITNESS BINDING
      2 cited witness paths are ABSENT from the predecessor close tree.
      10 cited witnesses were committed by a phase other than the
      frozen criterion phase.

IMPLEMENTATION
A NEW COMPILED POLYC VERIFIER, DISTINCT FROM THE PREDECESSOR'S.

  tools/quality/driver-boundary-qualification01-correction01-verify.HC

It is compiled by the REAL production compiler. The predecessor's Q2
verifier is NOT modified and NOT overwritten.

  MODES=10  ACSET ACPHASE ACPREDICATE ACWITNESS ACCOUNTING ROUTES
             DECISION BASELINE CHRONOLOGY SELFTEST
  BUILD=PASS   SELFTEST=PASS   ALL_TEN_MODES_SILENT_ON_PRISTINE=PASS

THREE FAIL-CLOSED DEFECTS WERE FOUND AND REPAIRED DURING C2. Each was
a mode that SILENTLY PASSED because it skipped the rows it could not
check:

  * ACWITNESS read ledger columns that did not exist and skipped every
    row. It now consumes the 50-row witness binding table BY NAME.
  * ACPREDICATE compared against a column that did not exist and
    compared nothing. It now compares the ledger against the frozen
    table against the IMMUTABLE C0 contract.
  * ACWITNESS read the existence table POSITIONALLY, so it read the
    chronology column as the relevance column. Every column is now
    addressed BY NAME.

THE C0 CONTRACT IS THE ANCHOR. With only two tables a predicate
substituted on the ledger side and a predicate rewritten in the frozen
contract are indistinguishable. The C0 contract separates them, and
each condition produces its OWN reason token.

THE 18 NEGATIVE CONTROLS fire their OWN EXACT reason token.

  EXACT_TOKEN_MATCHED=18  PRISTINE_SILENT_EXIT_0=18
  RESTORED_SILENT_EXIT_0=18  MUTATION_ISOLATED=18

GATES
BUILD=PASS
TARGETED=18/18
UNIT=PASS
JIT=PASS
LSP=PASS
DIFF_CHECK=PASS
GATE_FAST=PASS
GATE_PUSH=PASS
APPEND_ONLY=PASS
FACTORY_V2_RANGE=PASS
FACTORY_V2_TEST=PASS
FACTORY_CLOSURE_STATUS=PASS
F_NO_PYTHON=FAIL (PRE-EXISTING, DISCLOSED)
GATE_FAILURES=1
GATE_FAILURES_INTRODUCED_BY_THIS_CORRECTION=0
HALT_REQUIRED_GATE_FAILED=NO

SCOPE
FILES_CHANGED=60
DIFF_CHECK=PASS
PRODUCTION_SEMANTICS_CHANGED=NO
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO
HISTORICAL_EVIDENCE_MODIFIED=NO

The production source set and the production compiler bytes are
UNCHANGED against the predecessor close. The predecessor evidence,
the predecessor handoff and the predecessor closed ACT document are
UNCHANGED. The predecessor close and its post-close outcome commit are
both still present, and the close is an ancestor of the subject.

RESIDUE
P0=NONE
P1=NONE
P2=THE F_NO_PYTHON CHECK IS NON-GREEN WITH TWELVE VIOLATIONS, ALL
   PRE-EXISTING AT THE PREDECESSOR CLOSE AND NONE TOUCHED BY THIS
   CORRECTION. The exact identity of each is in
   evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01/c3/no-python-disposition.tsv.
   The checker is ALSO not yet wired into gate-fast, which is C2.9 of
   the bound correction ACT. Neither is repaired here: both are
   outside this correction's scope.

NEXT_ACT=NONE
```

---

## THE HISTORICAL AUDIT VERDICT, AND THE CURRENT CORRECTION VERDICT

The two are recorded SEPARATELY. The correction does not overwrite the
predecessor's audit verdict, and the predecessor's audit verdict does
not overwrite the correction's.

```text
HISTORICAL_AUDIT_VERDICT   = PASS_FINDINGS_WITH_REMAINDER
CURRENT_CORRECTION_VERDICT = PASS_WITH_DISCLOSED_PRE_EXISTING_FAILURE
```

## THE ACCEPTANCE COUNTS

```text
HISTORICAL_AC_COUNTS   = PASS:49 FAIL:0 DEFERRED:1  (of 50)
RECOMPUTED_AC_COUNTS   = PROVEN_AS_FROZEN:3
                         PROVEN_BY_ALTERNATE_EXISTING_WITNESS:32
                         UNSUPPORTED_BY_CITED_WITNESS:14
                         DEFERRED_AT_HISTORICAL_CHECKPOINT:1
                         (of 50)
```

The predecessor reported 49 PASS. The correction re-derives the
adjudication of all 50 criteria from the evidence, and finds that 14
of the 49 reported PASSes are NOT supported by the witness the
predecessor cited.

## THE DRIFT AND THE UNSUPPORTED WITNESSES

```text
PREDICATE_DRIFT_COUNT     = 9
PHASE_DRIFT_COUNT         = 5  (AC14 AC15 AC16 AC17 AC18)
UNSUPPORTED_WITNESS_COUNT = 14
```

## THE REMAINERS

```text
HISTORICAL_RETAINED_C_ROWS            = 2   (function level)
REQUALIFIED_GLOBAL_REMAINDER           = 2   (branch level)
REQUALIFIED_REQUIRED_ROUTE_REMAINDER   = 1   (branch level)
```

The historical count of two and the branch-level required-route count
of one COEXIST. They are DIFFERENT UNITS and are reported apart.

The predecessor counted `main()` and `emitFile()` as two retained-C
rows and asserted that BOTH are on the required route. The branch-level
measurement shows that of the two C-semantic branches, only
`BR_EMITFILE_EMIT_OBJECT` is PROVEN_REACHABLE on the required route.
`BR_MAIN_PRINT_TOKENS` is a WHOLE-CLI-scope branch: it is reached by
the token route and NOT by the required route.

All 32 historical rows are crosswalked to the branches that discharge
them, or to NONE, in
`evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01/c2/ownership-remainder-crosswalk.tsv`.

## THE TERMINALITY

```text
HISTORICAL_TERMINALITY_STATUS    = UNPROVEN
CURRENT_CORRECTION_TERMINALITY_STATUS = PLAN_COMMITTED, PROBE_NOT_RUN
```

The predecessor's historical terminality remains UNPROVEN. The
predecessor's tracked outcome was PRE-COMMITTED and is not confirmed.

This correction's close commits the PLAN for its own external
read-only probe. The probe has NOT run. The plan carries no PASS for
an event that has not happened.

## THE AUDIT VERDICT IS DISTINCT FROM THE HISTORIC WP-001 STATUS

```text
AUDIT_VERDICT               = PASS_WITH_DISCLOSED_PRE_EXISTING_FAILURE
WP001_BOUNDARY_CONFIRMED    = NO
WP001_DRIVER_MIGRATION      = ACHIEVED   (the historic migration verdict)
HISTORICAL_ACT_TERMINALITY_CONFIRMED = UNPROVEN
```

The historic `WP001_DRIVER_MIGRATION = ACHIEVED` is the MIGRATION
ACT's own verdict and is NOT overwritten by this audit.

## THE DISCLOSED PRE-EXISTING FAILURE

The `F_NO_PYTHON` check is NON-GREEN. It is **NOT** converted into a
PASS.

Its twelve violations are ALL present at the predecessor close
`edfc3b16` and NONE of them is touched by this correction. The exact
identity of each is recorded in
`evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01/c3/no-python-disposition.tsv`.
