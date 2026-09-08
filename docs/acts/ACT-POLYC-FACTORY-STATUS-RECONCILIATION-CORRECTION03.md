ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03
====================================================

## Status

OPEN

## Predecessor

ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02
(closure-identity repair for CORRECTION01; had its own closure
state unbound at the time of review).

## Bounded objective

Resolve `HALT_CORRECTION02_CLOSURE_STATE_UNBOUND` by:

1. Removing the four untracked `closure/` capture files that
   contradicted the "worktree clean" claim at CORRECTION02 closure.
2. Authoring a non-self-pinning authoritative identity record for
   CORRECTION02 itself, with hard-baked immutable SHAs that
   resolve the stale `<this commit>` / `<committed in the next
   commit>` placeholders in the committed CORRECTION02 HANDOFF.
3. Closing the ACT's tree with `git status --porcelain` empty and
   the same six-pair / 63-assertion / factory-rc=0 / gate-fast-rc=0
   gates green as before.

The factory closure-status oracle (checker) is NOT modified. The
bounded managed universe is NOT widened (still 6 pairs). Manifest
is NOT touched.

## Defect being repaired

Two closure-state defects were observed at
`849677ade3d6275996409846bbe99be49c6145b1`.

### Defect A — current worktree was demonstrably not clean

The CORRECTION02 HANDOFF and closure summary both recorded:

```text
worktree = clean
```

but `git status --short` at the same HEAD showed:

```text
? evidence/factory-status-reconciliation-correction02/closure/gate-fast-green.txt
? evidence/factory-status-reconciliation-correction02/closure/green-run-dash.txt
? evidence/factory-status-reconciliation-correction02/closure/green-run-sh.txt
? evidence/factory-status-reconciliation-correction02/closure/n1-n19-summary.txt
```

`?` in short/porcelain status means untracked. By definition the
worktree was dirty. Adding these as a fourth CORRECTION02 commit
would violate the 3-commit cap. Removing them is the only valid
closure action.

### Defect B — CORRECTION02 own closure identity was unbound

The committed CORRECTION02 HANDOFF contains:

```text
ENTRY_HEAD (CORRECTION02)  = 2d7ff45de22b826abb3096ed611cd7ac02f05134
RED_HEAD   (CORRECTION02)  = b62f940 <C1 RED commit for this ACT>
IMPL_HEAD  (CORRECTION02)  = <C2 IMPL commit; this commit>
DOCS_HEAD  (CORRECTION02)  = <C3 DOCS commit; committed in the next commit>
```

The actual final topology at `849677a` is:

```text
ENTRY_HEAD = 2d7ff45de22b826abb3096ed611cd7ac02f05134
RED_HEAD   = b62f940f8b3bdf6dd0b1d2ba517cd45a4e5c03f3
IMPL_HEAD  = d9b996188678022fd7e35cc82588de17408eb2f9
DOCS_HEAD  = 849677ade3d6275996409846bbe99be49c6145b1
```

So:

- `IMPL_HEAD` was not bound to `d9b9961`.
- The C3 sentence "committed in the next commit" became false the
  moment C3 was committed.

The `identity-green.txt` produced by CORRECTION02 does NOT solve
this: it explicitly states its values are about CORRECTION01, and
it was generated at C2 (HEAD `d9b9961`), not at C3 closure.

The CORRECTION02 ACT's sole purpose was closure-identity
correctness. It cannot itself close while leaving another
unbound / stale identity in its own committed closure document.

## Scope

### allowed

- this ACT contract
  (`docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03.md`);
- this ACT's closure evidence
  (`evidence/factory-status-reconciliation-correction03/`);
- deletion of the four untracked `closure/` capture files at
  `evidence/factory-status-reconciliation-correction02/closure/`
  (restores the clean state);
- a single new HANDOFF at
  `evidence/factory-status-reconciliation-correction03/HANDOFF.md`
  whose CORRECTION02-self-identity block uses hard-baked
  immutable SHAs (not "this commit" placeholders).

### forbidden

- any rewrite, amend, rebase, or history edit of commits
  `b62f940`, `d9b9961`, or `849677a` (F14);
- any edit to
  `evidence/factory-status-reconciliation-correction01/HANDOFF.md`
  (still immutable historical evidence);
- any edit to
  `evidence/factory-status-reconciliation-correction02/HANDOFF.md`
  (the stale placeholders remain visible as historical evidence;
  the correction lives in the new HANDOFF);
- any edit to the factory closure-status oracle semantics
  (R1-R6 from CORRECTION01 stay binding; R1-R6 from CORRECTION02
  also stay binding);
- widening the bounded managed universe beyond the existing
  6 pairs;
- extending or modifying the n1-n19 negative test runner;
- removing the legacy `llvm-closure-status-check.sh` wrapper;
- dependency additions, IR/LLVM/compiler changes, semantic changes;
- claiming closure while `git status --porcelain` is non-empty;
- "this commit" / "next commit" self-pinning placeholders in any
  closure document produced by this ACT.

## RED (mechanically captured)

The verbatim bad CORRECTION02 HANDOFF IDENTITY block is captured
at:

    evidence/factory-status-reconciliation-correction03/identity-red.txt

That file is produced by `closure-run.sh` from
`evidence/factory-status-reconciliation-correction02/HANDOFF.md`
at HEAD `849677a` and contains the stale placeholders.

## Required invariants

R1. Historical bad identity records preserved (no amendment)
   - `evidence/factory-status-reconciliation-correction01/HANDOFF.md`
     remains immutable.
   - `evidence/factory-status-reconciliation-correction02/HANDOFF.md`
     is also immutable as a record of what was committed at
     `849677a`; this ACT does NOT amend it.
   - The CORRECTION02 HANDOFF with the stale placeholders remains
     visible as historical evidence (F14); the correction lives in
     a new HANDOFF at
     `evidence/factory-status-reconciliation-correction03/HANDOFF.md`.

R2. CORRECTION02 closure identity is recorded with hard-baked SHAs
   The new CORRECTION03 HANDOFF records:

       CORRECTION02_ENTRY_HEAD = 2d7ff45de22b826abb3096ed611cd7ac02f05134
       CORRECTION02_RED_HEAD   = b62f940f8b3bdf6dd0b1d2ba517cd45a4e5c03f3
       CORRECTION02_IMPL_HEAD  = d9b996188678022fd7e35cc82588de17408eb2f9
       CORRECTION02_DOCS_HEAD  = 849677ade3d6275996409846bbe99be49c6145b1

       git rev-list --count 2d7ff45..849677a = 3

   No "this commit" / "next commit" / "TBD" / "FINAL_HEAD=this
   commit" loops anywhere in the new HANDOFF. The four SHAs are
   already immutable in the repository, so they cannot become
   stale.

R3. Worktree is genuinely clean at closure
   `git status --porcelain` returns no lines at the closure HEAD.

R4. The six-pair managed universe is unchanged
   `factory-closure-status-check.sh` continues to print:

       MANAGED_ACTS=6  MANAGED_HANDOFFS=6  MANIFEST_ROWS=6
       PAIR_OK=6 PAIR_FAIL=0 STATUS=PASS VERDICT=PASS rc=0

R5. Manifest bijection unchanged
   `docs/factory/act-handoff-map.tsv` continues to have 6 rows,
   binding the original 5 pairs plus the CORRECTION02 pair.

R6. Negative suite unchanged
   `n1-n19/run.sh` continues to report PASS=63 FAIL=0 rc=0.

R7. Checker semantics unchanged
   R1-R6 from CORRECTION01 stay binding. R1-R6 from CORRECTION02
   stay binding. Nothing in `factory-closure-status-check.sh`
   changes.

## Out of scope (residue)

- addressing `ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01` (FT1 in
  ROADMAP); P2.
- reconciling `docs/ROADMAP.md`'s "P3.5 CORE01 authorized" claim
  with the CORRECTION01/CORRECTION02 HALT sequence; P1.
- widening the bounded managed universe to other ACT prefixes;
  P2.
- removing the legacy `llvm-closure-status-check.sh` wrapper;
  P2.
- "this commit" / "next commit" patterns in any other committed
  ACT or HANDOFF outside the immediate CORRECTION02 chain; P2.

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

n1-n19 negative suite        PASS=63 FAIL=0

gate-fast                    rc=0
git diff --check             rc=0
worktree                     clean   (git status --porcelain empty)
```

## Halt taxonomy

- `HALT_CORRECTION02_CLOSURE_STATE_UNBOUND` (reviewer-issued;
  this ACT exists to close it).
- `HALT_CORRECTION02_CLOSURE_DOCUMENT_AMENDMENT` (in case correct
  completion requires editing
  `evidence/factory-status-reconciliation-correction02/HANDOFF.md`;
  per F14, the correct response is halt, not silent widening or
  amendment).
- `HALT_CORRECTION03_SCOPE_EXPANSION` (in case correct completion
  requires touching the checker, widening the universe, or
  extending the n-test runner; per F15, the correct response is
  halt, not silent widening).

## Commit topology

Two commits at most:

```text
C1 RED:   ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03.md
          + closure-run.sh
          + identity-red.txt   (verbatim capture of stale CORRECTION02 HANDOFF)
          + identity-green.txt (mechanical capture of CORRECTION02 endpoints)
          + HANDOFF.md         (initial; reviewer-resolved identity; VERDICT=PASS)
C2 CLEAN: deletion of evidence/factory-status-reconciliation-correction02/closure/
          + HANDOFF.md         (final; VERDICT confirmed; entry HEAD = C1 SHA hard-baked)
```

Do not exceed two commits.

The two-commit structure is deliberate: this ACT is a pure
docs/evidence repair with no production change. C1 establishes the
RED, the new ACT contract, the new HANDOFF (authored against the
current `849677a` HEAD with immutable CORRECTION02 SHAs and the
C1 HEAD itself recorded as the entry into CORRECTION03), and the
two identity capture files. C2 closes the worktree (deletes the
residue `closure/` captures) and flips the new HANDOFF's VERDICT
once the worktree is clean. There is no separate "implementation"
commit because no production code is touched.

## Why not amend / rebase / reorder commits

F14: the historical committed CORRECTION02 chain (`b62f940`,
`d9b9961`, `849677a`) is the evidence this ACT is correcting.
Amending it would destroy the very record being cited.
