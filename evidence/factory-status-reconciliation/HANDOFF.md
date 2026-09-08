HANDOFF -- ACT-POLYC-FACTORY-STATUS-RECONCILIATION
=================================================

VERDICT
-------
PASS

ACT-POLYC-FACTORY-STATUS-RECONCILIATION closes the closure-status
reconciliation defect that was reproduced three times in a row in
CORE03-CORRECTION02/03/04 and surfaced as
HALT_CORRECTION05_OWN_GATE_RED in CORE03-CORRECTION05.

The seed oracle (scripts/quality/llvm-closure-status-check.sh) was
RED at the entry HEAD (OK=2 FAIL=3 rc=1) and structurally
incapable of enforcing the desired invariant: it collapsed
HALT_<...> to HALT and silently omitted ACTs whose HANDOFF was
absent or at a non-inferred path.

This ACT introduces:

  M1: scripts/quality/factory-closure-status-check.sh
      exact-token oracle with manifest bijection
  M2: docs/factory/act-handoff-map.tsv
      five-pair bijection of the bounded managed universe
  M3: docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION.md
      exact-token contract and binding reconciliation table
  M4: scripts/quality/llvm-closure-status-check.sh
      compatibility wrapper delegating to M1
  M5: GFAST-6 factory-closure-status block in scripts/quality/gate-fast.sh
      .githooks/pre-commit already aborts git commit on non-zero
  M6: HANDOFF reconciliation for CORRECTION01..04
      CORRECTION05 untouched; per-pair Supersession block records
      the historical verdict as evidence (F14)

IDENTITY
--------

Entry:    862d2cc8c9c0873158c9b60707ab625e08794260 (main, clean)
RED:      636af24 (C1: ACT + 4 RED witnesses)
IMPL:     68bc107 (C2 IMPL pre-reconciliation: exact checker +
                   manifest + gate wiring + RED-2B captured)
IMPL2:    (this commit)  (C2 IMPL post-reconciliation: 4 HANDOFF
                          verdicts updated to exact tokens,
                          CORRECTION05 ACT prose annotated as
                          superseded)
DOCS:     (this commit)
HEAD:     (this commit)

Total commits: 3 (C1 + C2 + DOCS in this commit). At cap.

ROOT CAUSE
----------

The legacy closure-status oracle lost information in two ways:

1. Lifecycle normalization: case "HALT*") norm=HALT collapsed every
   distinct HALT_<...> reason to the same normalized class. Two
   distinct failures (e.g. CORRECTION01's HALT_TOPOLOGY_RECORDED
   vs CORRECTION02's HALT_SCOPE_CONTRACT_VIOLATED) were reported
   as identical.

2. Inference-based pair discovery: the seed discovered ACT/HANDOFF
   pairs by lowercasing the ACT filename tail and special-casing
   two prefixes. ACTs whose filenames did not match any special
   case (or whose HANDOFF was absent) were silently skipped.

Combined with the third-time reviewer's verdict, the cure is an
exact-token, manifest-driven, hard-gated oracle.

RED MATRIX (binding)
--------------------

RED-1   OK=2 FAIL=3 rc=1                              (live, ENTRY_HEAD)
RED-2   HALT_<...> -> HALT lossy collapse             (source-grounded)
RED-3A1 ACT/HANDOFF at non-inferred path -> seed OMIT (live, fixture)
RED-3A2 same pair explicitly in manifest -> PASS     (N11 hermetic)
RED-3A3 manifest row removed -> UNMAPPED + FAIL      (N12 hermetic)
RED-3B  managed ACT, absent HANDOFF -> MISSING + FAIL (live, fixture)

RED-2B  PAIR_OK=1 PAIR_FAIL=4 EXACT_VERDICT_MISMATCHES=4 rc=1
        (captured at C2 IMPL pre-reconciliation commit,
         before HANDOFF edits, per load-bearing C2 ordering)

GREEN
-----

  PAIR_OK=5  PAIR_FAIL=0  EXACT_VERDICT_MISMATCHES=0
  MANIFEST_ROWS=5
  MANIFEST_PARSE_ERRORS=0
  DUPLICATE_ACT_PATHS=0
  DUPLICATE_HANDOFF_PATHS=0
  MISSING_ACT_FILES=0
  MISSING_HANDOFF_FILES=0
  MALFORMED_ACT_STATUS=0
  MALFORMED_HANDOFF_VERDICT=0
  factory-closure-status-check.sh rc=0
  gate-fast rc=0  (GFAST-1..6 all PASS)
  .githooks/pre-commit rc=0
  git diff --check rc=0
  worktree clean
  commit count = 3  (at cap)

NEGATIVE TESTS
--------------

N1..N15 = 32 assertions PASS (15 tests + baseline). Output in
evidence/factory-status-reconciliation/n1-n15/output.txt.

N14 (PASS != PASS_WITH_NEXT_ACT_DECISION) explicitly prevents the
lossy-normalization bug from returning via PASS qualifiers.

RECONCILIATION TABLE (binding)
------------------------------

| Pair | ACT authority                                          | HANDOFF after reconciliation                       |
| ---- | ------------------------------------------------------ | -------------------------------------------------- |
| 01   | HALT_TOPOLOGY_RECORDED                                 | HALT_TOPOLOGY_RECORDED                             |
| 02   | HALT_SCOPE_CONTRACT_VIOLATED                           | HALT_SCOPE_CONTRACT_VIOLATED                       |
| 03   | HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT           | HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT       |
| 04   | HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE               | HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE           |
| 05   | HALT_CORRECTION05_OWN_GATE_RED                         | unchanged                                          |

Each of the four updated HANDOFFs carries a per-pair SUPERSESSION
block recording the historical verdict as evidence (F14).

SCOPE
-----

In scope:
  - factory tooling (checker, manifest, gate-fast wiring)
  - pre-commit hook integration (no wiring change required;
    inheritance from gate-fast.sh)
  - HANDOFF verdict reconciliation for the bounded 5-pair universe
  - per-pair Supersession blocks preserving historical evidence
  - CORRECTION05 ACT prose annotated as superseded (not rewritten)

Out of scope (residue):
  - extending the exact-token checker to the broader FACTORY-*
    ACT universe (ir-boundary*, llvmspike01-core*, etc.); P2
  - phasing out the legacy llvm-closure-status-check.sh
    compatibility wrapper once all consumers migrate; P2

CONSERVATION
------------

The legacy seed oracle still exists as a thin compatibility
wrapper that delegates to the new exact-token checker; it is
never the authority anymore. Historical ACTs, HANDOFFs, and
reviewer evidence are preserved unchanged in their original
locations.

NEXT ACT
--------

ACT-POLYC-LLVM-CORE04.
