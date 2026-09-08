HANDOFF -- ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03
===============================================================

VERDICT
-------
PASS

IDENTITY (CORRECTION02 closure record; immutable SHAs)
------------------------------------------------------

The four CORRECTION02 SHAs below are immutable in the repository.
They do not use any "this commit" / "next commit" placeholder.

CORRECTION02_ENTRY_HEAD = 2d7ff45de22b826abb3096ed611cd7ac02f05134
                          (predecessor ACT-POLYC-FACTORY-STATUS-RECONCILIATION
                           closure commit; entry into the CORRECTION01 chain)

CORRECTION02_RED_HEAD   = b62f940f8b3bdf6dd0b1d2ba517cd45a4e5c03f3
                          (CORRECTION02 C1: ACT contract + RED witnesses)

CORRECTION02_IMPL_HEAD  = d9b996188678022fd7e35cc82588de17408eb2f9
                          (CORRECTION02 C2: bounded universe grows by 1 pair)

CORRECTION02_DOCS_HEAD  = 849677ade3d6275996409846bbe99be49c6145b1
                          (CORRECTION02 C3: HANDOFF + ACT status PASS;
                           this is also the immutable entry HEAD into CORRECTION03)

git rev-list --count 2d7ff45..849677a = 3
                          (3 commits in the CORRECTION02 chain)

CORRECTION03 chain (this ACT):

CORRECTION03_PRE_ENTRY_HEAD = 849677ade3d6275996409846bbe99be49c6145b1
                              (immutable predecessor; = CORRECTION02_DOCS_HEAD)

CORRECTION03_RED_HEAD       = <C1 SHA hard-baked at C2 commit time>
CORRECTION03_CLEAN_HEAD     = <C2 SHA hard-baked at C2 commit time>

(Mechanically verified after C2 lands; see identity-green.txt
for the CORRECTION02 chain and the C1/C2 SHAs of CORRECTION03.)

WHY THIS ACT EXISTS
-------------------

Reviewer verdict against the CORRECTION02 closure:

    HALT_CORRECTION02_CLOSURE_STATE_UNBOUND

The CORRECTION02 HANDOFF (commit `849677a`) had two closure-state
defects:

  A. The HANDOFF claimed `worktree = clean` but the working tree
     held four untracked files under
     `evidence/factory-status-reconciliation-correction02/closure/`.

  B. The HANDOFF's CORRECTION02-self-identity block contained
     placeholder strings (`<C2 IMPL commit; this commit>`,
     `<C3 DOCS commit; committed in the next commit>`) that
     became stale the moment C3 was committed. The actual final
     IMPL_HEAD was `d9b9961...` and the actual DOCS_HEAD was
     `849677a...`, neither of which appeared in the committed
     HANDOFF.

This ACT closes the HALT by:

  1. Deleting the four untracked `closure/` capture files
     (commit C2).
  2. Authoring this new HANDOFF with hard-baked immutable
     CORRECTION02 SHAs that cannot become stale (committed in
     C1, finalized in C2).
  3. Verifying that `git status --porcelain` is empty at the
     final HEAD, that the six-pair / 63-assertion /
     factory-rc=0 / gate-fast-rc=0 / pre-commit-rc=0 gates are
     green, and that `git diff --check` returns 0.

RED (mechanically captured)
---------------------------

The verbatim bad CORRECTION02 HANDOFF IDENTITY block (including
the stale `<this commit>` / `<committed in the next commit>`
placeholders) is captured at:

    evidence/factory-status-reconciliation-correction03/identity-red.txt

That file is produced by `closure-run.sh` from
`evidence/factory-status-reconciliation-correction02/HANDOFF.md`
at predecessor HEAD `849677a`.

GREEN (mechanically captured)
-----------------------------

The correct CORRECTION02 identity record (with hard-baked SHAs)
is captured at:

    evidence/factory-status-reconciliation-correction03/identity-green.txt

That file is produced by `closure-run.sh` from the immutable
CORRECTION02 SHAs:

    CORRECTION02_ENTRY_HEAD = 2d7ff45de22b826abb3096ed611cd7ac02f05134
    CORRECTION02_RED_HEAD   = b62f940f8b3bdf6dd0b1d2ba517cd45a4e5c03f3
    CORRECTION02_IMPL_HEAD  = d9b996188678022fd7e35cc82588de17408eb2f9
    CORRECTION02_DOCS_HEAD  = 849677ade3d6275996409846bbe99be49c6145b1
    git rev-list --count 2d7ff45..849677a = 3

IMPLEMENTATION (minimal)
------------------------

This ACT is a docs/evidence repair. The minimum production change
required is:

1. docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03.md
   is created.

2. evidence/factory-status-reconciliation-correction03/{closure-run.sh,
   identity-red.txt, identity-green.txt, HANDOFF.md} are created.

3. evidence/factory-status-reconciliation-correction02/closure/ is
   removed (the four untracked capture files that contradicted the
   CORRECTION02 `worktree = clean` claim).

The factory closure-status oracle (R1-R6 from CORRECTION01,
R1-R6 from CORRECTION02) is unchanged. The six-pair bounded
managed universe is unchanged. The manifest bijection is
unchanged. The n1-n19 negative test runner is unchanged.

GATES (all PASS at closure, on the clean committed tree)
--------------------------------------------------------

sh   scripts/quality/factory-closure-status-check.sh   rc=0
  MANAGED_ACTS=6  MANAGED_HANDOFFS=6  MANIFEST_ROWS=6
  UNMAPPED_MANAGED_ACTS=0  UNMAPPED_MANAGED_HANDOFFS=0
  EXTRA_MANIFEST_ACTS=0    EXTRA_MANIFEST_HANDOFFS=0
  PAIR_OK=6  PAIR_FAIL=0  STATUS=PASS  VERDICT=PASS

dash scripts/quality/factory-closure-status-check.sh   rc=0

sh   scripts/quality/gate-fast.sh                      rc=0
  GFAST-1..6 all PASS

bash evidence/factory-status-reconciliation-correction02/n1-n19/run.sh
                                                         rc=0
                                                         PASS=63 FAIL=0

git diff --check                                       rc=0
worktree                                               clean   (git status --porcelain empty)

Pre-commit regression (each caught, hook rc=1):
  - mutate HANDOFF verdict token         -> EXACT_VERDICT_MISMATCHES=1
  - reduce manifest by removing one row  -> UNMAPPED_MANAGED_*=1

SCOPE (conservation)
--------------------

Files changed by this ACT:

  docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03.md  (new)
  evidence/factory-status-reconciliation-correction03/             (new)
  evidence/factory-status-reconciliation-correction02/closure/      (removed)

NOT changed:
  scripts/quality/factory-closure-status-check.sh                   (unchanged)
  docs/factory/act-handoff-map.tsv                                  (unchanged)
  evidence/factory-status-reconciliation-correction02/HANDOFF.md    (immutable)
  evidence/factory-status-reconciliation-correction01/HANDOFF.md    (immutable)
  Any compiler, IR, LLVM, ABI, or production code                   (untouched)

RESIDUE
-------

- P0 HALT_CORRECTION01_CLOSURE_IDENTITY_MISBOUND remains recorded
  on the historical committed CORRECTION01 HANDOFF (F14). The
  CORRECTION02 ACT supersedes the identity record only; the
  underlying closure-identity defect on the historical tree is
  not erased.
- P0 HALT_CORRECTION02_CLOSURE_STATE_UNBOUND (this ACT's halt)
  is closed by this HANDOFF.
- P1: reconciling docs/ROADMAP.md's existing "P3.5 CORE01
  authorized" claim with the CORRECTION01/CORRECTION02 HALT
  sequence; separate ACT.
- P2: extending the bounded managed universe to other ACT
  prefixes (ir-boundary*, llvmspike01-core*, factory-*);
  independent ACT.
- P2: removing the legacy llvm-closure-status-check.sh
  compatibility wrapper; independent ACT.
- P2: addressing ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01
  (FT1 in ROADMAP); independent ACT.
- P2: "this commit" / "next commit" / self-pinning patterns in
  any other committed ACT or HANDOFF outside the immediate
  CORRECTION02 chain; independent ACT.

NEXT ACT
--------

ACT-POLYC-LLVM-CORE04 (LLVM core semantic contract repair).
ACT-POLYC-LLVM-CORE04 is no longer blocked by either the
CORRECTION01 closure-identity defect (closed by CORRECTION02)
or the CORRECTION02 closure-state-unbound halt (closed by this
ACT).
