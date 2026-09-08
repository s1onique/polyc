ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02
====================================================

## Status

PASS

## Predecessor

ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION01
(HALT_CORRECTION01_CLOSURE_IDENTITY_MISBOUND)

## Bounded objective

Repair the closure-identity record of
ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION01 by
authoring a new closure record that supplies the correct
authoritative identity chain. The historical bad record in
`evidence/factory-status-reconciliation-correction01/HANDOFF.md`
remains visible (F14) and is named as the RED witness.

The factory closure-status oracle (checker) is NOT modified by
this ACT. The bounded managed universe grows by exactly one
new bounded pair (this CORRECTION02 ACT + its own HANDOFF).

## Defect being repaired

The CORRECTION01 HANDOFF (commit `2d7ff45de22b826abb3096ed611cd7ac02f05134`)
contains an identity error. It states:

```text
Entry:    c014d1f8f561dba18ecdad2d53035174408d9a47
RED:      c014d1f8f561dba18ecdad2d53035174408d9a47
IMPL:     15070c3
DOCS:     (this commit)
HEAD:     (this commit)
```

If `Entry = c014d1f8` were true, then `c014d1f8` is already
the C1/RED commit and only two further commits would exist in
the CORRECTION01 chain, not three.

The actual repository facts (mechanically captured in
`evidence/factory-status-reconciliation-correction02/identity-red.txt`):

```text
predecessor HEAD (entry into CORRECTION01) = 31564feb987dbe725305658712170d899caa6798
CORRECTION01 C1 RED_HEAD                  = c014d1f8f561dba18ecdad2d53035174408d9a47
CORRECTION01 C2 IMPL_HEAD                 = 15070c306e6c7e902722d6d1ae34e830b3e2a74c
CORRECTION01 C3 closure HEAD              = 2d7ff45de22b826abb3096ed611cd7ac02f05134
git rev-list --count 31564feb..2d7ff45    = 3
```

`Entry` in the CORRECTION01 HANDOFF missed `31564feb`
(predecessor `ACT-POLYC-FACTORY-STATUS-RECONCILIATION`
closure commit). That omission is the reviewer-flagged defect.

## Scope

### allowed

- this ACT contract (`docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md`);
- this ACT's closure evidence
  (`evidence/factory-status-reconciliation-correction02/`);
- one additional row in `docs/factory/act-handoff-map.tsv`
  binding this ACT to its own HANDOFF;
- the bounded managed universe in
  `scripts/quality/factory-closure-status-check.sh` grows by
  exactly one ACT and one HANDOFF (this CORRECTION02 pair);
- the n1-n18 negative-test runner grows a single N19 negative
  test that proves the new bounded pair is also enforced by the
  bounded-completeness invariant (N16-style: remove the
  CORRECTION02 manifest row -> UNMAPPED_MANAGED_ACTS=1
  UNMAPPED_MANAGED_HANDOFFS=1 rc=1).

### forbidden

- any rewrite, amend, rebase, or history edit of commits
  `c014d1f8`, `15070c3`, or `2d7ff45` (F14);
- any edit to
  `evidence/factory-status-reconciliation-correction01/HANDOFF.md`
  (the bad identity record remains visible as historical evidence);
- any edit to the factory closure-status oracle semantics
  (R1-R6 from CORRECTION01 stay binding);
- widening the bounded managed universe beyond the single new
  CORRECTION02 pair;
- removing the legacy `llvm-closure-status-check.sh` wrapper;
- dependency additions, IR/LLVM/compiler changes, semantic changes.

## Required invariants

R1. Historical bad identity record preserved
   `evidence/factory-status-reconciliation-correction01/HANDOFF.md`
   remains committed at HEAD~0 and is NOT amended. The RED
   witness for this ACT is the verbatim text of that record
   captured in `evidence/factory-status-reconciliation-correction02/identity-red.txt`.

R2. New authoritative identity record supplied
   `evidence/factory-status-reconciliation-correction02/identity-green.txt`
   mechanically captures:

       ENTRY_HEAD    = 31564feb987dbe725305658712170d899caa6798
       RED_HEAD      = c014d1f8f561dba18ecdad2d53035174408d9a47
       IMPL_HEAD     = 15070c306e6c7e902722d6d1ae34e830b3e2a74c
       CLOSURE_HEAD  = 2d7ff45de22b826abb3096ed611cd7ac02f05134
       rev-list count 31564feb..2d7ff45 = 3

   produced by an explicit `git rev-parse` / `git rev-list`
   command, not by hand-typed strings.

R3. Bounded managed universe grows by exactly one pair
   `scripts/quality/factory-closure-status-check.sh`'s
   `MANAGED_ACTS` and `MANAGED_HANDOFFS` lists each gain exactly
   one line: the CORRECTION02 ACT and HANDOFF. No other
   widening. The clean-state check continues to print:

       MANAGED_ACTS=6
       MANAGED_HANDOFFS=6
       MANIFEST_ROWS=6
       PAIR_OK=6 PAIR_FAIL=0 STATUS=PASS VERDICT=PASS rc=0

R4. Manifest bijection extended
   `docs/factory/act-handoff-map.tsv` gains one row binding
   `docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md`
   to `evidence/factory-status-reconciliation-correction02/HANDOFF.md`.
   No existing row is removed or reordered.

R5. Negative test added (N19)
   `evidence/factory-status-reconciliation-correction01/n1-n18/run.sh`
   is renamed to `n1-n19/run.sh` and gains a single N19
   bounded-completeness test for the new CORRECTION02 pair:
   remove the new manifest row -> the checker must print
   `UNMAPPED_MANAGED_ACTS=1 UNMAPPED_MANAGED_HANDOFFS=1` and
   exit 1.

R6. CORRECTION02 itself is on the manifest and in the universe
   At this ACT's closure HEAD, the new ACT's `## Status` is
   PASS, its HANDOFF is present with `VERDICT=PASS`, the
   manifest contains the new row, and the checker's hard-coded
   managed universe contains the new pair. The factory
   closure-status gate passes on this exact tree.

## Out of scope (residue)

- replacing the bad CORRECTION01 identity record with a corrected
  one (F14: history stays as historical evidence);
- widening the managed universe to other ACT prefixes
  (ir-boundary*, llvmspike01-core*, factory-*); P2.
- removing the legacy `llvm-closure-status-check.sh` wrapper; P2.
- reconciling `docs/ROADMAP.md`'s existing "P3.5 CORE01 authorized"
  claim with the reviewer-issued HALT on the CORRECTION01
  closure identity record (separate ACT); P1.
- addressing `ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01` (FT1 in
  ROADMAP); P2.

## Required closure state

```text
factory checker              rc=0  (under sh AND dash)
  MANAGED_ACTS               = 6
  MANAGED_HANDOFFS           = 6
  MANIFEST_ROWS              = 6
  UNMAPPED_MANAGED_ACTS      = 0
  UNMAPPED_MANAGED_HANDOFFS  = 0
  EXTRA_MANIFEST_ACTS        = 0
  EXTRA_MANIFEST_HANDOFFS    = 0
  PAIR_OK                    = 6
  PAIR_FAIL                  = 0

n1-n19 negative suite        PASS=N+4 FAIL=0   (N19 adds 4 assertions)

gate-fast                    rc=0
pre-commit regression        PASS
git diff --check             rc=0
worktree                     clean
```

## Halt taxonomy

- `HALT_CORRECTION01_CLOSURE_IDENTITY_MISBOUND` (reviewer-issued;
  recorded as historical residue, NOT closed by this ACT; this
  ACT only supersedes the identity record, the underlying
  defect remains on the historical committed tree).
- `HALT_CORRECTION02_SCOPE_EXPANSION` (in case correct completion
  requires touching production code, the legacy wrapper, or other
  ACT prefixes; per F15, the correct response is halt, not silent
  widening).

## Commit topology

Three commits at most:

```text
C1 RED: ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md
        + identity-red.txt (verbatim capture of the bad record)
        + identity-green.txt (mechanical capture of the correct record)
        + closure-run.sh
C2 IMPL: bounded universe grows by one pair (CORRECTION02 ACT + HANDOFF)
         + manifest bijection grows by one row
         + n1-n19 runner extends n1-n18
C3 DOCS+HANDOFF: evidence/factory-status-reconciliation-correction02/HANDOFF.md
                 + this ACT  ## Status OPEN -> PASS
```

Do not exceed three commits.
