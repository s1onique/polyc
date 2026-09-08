HANDOFF -- ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02
================================================================

VERDICT
-------
OPEN

IDENTITY (mechanically derived; see identity-green.txt)
-------------------------------------------------------

ENTRY_HEAD       = 31564feb987dbe725305658712170d899caa6798
                  (predecessor ACT-POLYC-FACTORY-STATUS-RECONCILIATION
                  closure commit; entry into the CORRECTION01 chain)

RED_HEAD         = c014d1f8f561dba18ecdad2d53035174408d9a47
                  (CORRECTION01 C1: ACT contract + RED witnesses)

IMPL_HEAD        = 15070c306e6c7e902722d6d1ae34e830b3e2a74c
                  (CORRECTION01 C2: rewritten checker + 18-test suite)

CLOSURE_HEAD     = 2d7ff45de22b826abb3096ed611cd7ac02f05134
                  (CORRECTION01 C3: HANDOFF + ACT status PASS)

git rev-list --count 31564feb..2d7ff45 = 3
                  (3 commits in the CORRECTION01 chain between the
                  predecessor entry and the CORRECTION01 closure)

This ACT's IDENTITY chain (CORRECTION02):

ENTRY_HEAD (CORRECTION02)  = 2d7ff45de22b826abb3096ed611cd7ac02f05134
RED_HEAD   (CORRECTION02)  = b62f940 <C1 RED commit for this ACT>
IMPL_HEAD  (CORRECTION02)  = <C2 IMPL commit; this commit>
DOCS_HEAD  (CORRECTION02)  = <C3 DOCS commit; committed in the next commit>

See evidence/factory-status-reconciliation-correction02/identity-green.txt
for the mechanically captured HEAD at closure.

WHY THIS ACT EXISTS
-------------------

Reviewer verdict against the CORRECTION01 closure:

    HALT_CORRECTION01_CLOSURE_IDENTITY_MISBOUND

The CORRECTION01 HANDOFF stated:

    Entry:    c014d1f8f561dba18ecdad2d53035174408d9a47

But the actual predecessor entry into the CORRECTION01 chain
was `31564feb987dbe725305658712170d899caa6798` (the predecessor
ACT-POLYC-FACTORY-STATUS-RECONCILIATION closure commit). If the
CORRECTION01 HANDOFF's `Entry` claim were true, only two further
commits could exist in the CORRECTION01 chain, not three.

This CORRECTION02 ACT repairs the closure-identity record by
authoring a new authoritative identity chain for CORRECTION01
without amending the historical committed CORRECTION01 HANDOFF.
Per F14, the historical record remains visible as historical
evidence; a fresh correction supplies the authoritative chain.

RED (mechanically captured)
---------------------------

Verbatim text of the bad CORRECTION01 HANDOFF IDENTITY block is
captured in:

    evidence/factory-status-reconciliation-correction02/identity-red.txt

That file is produced by `evidence/factory-status-reconciliation-correction02/closure-run.sh`
from the committed source `evidence/factory-status-reconciliation-correction01/HANDOFF.md`.

GREEN (mechanically captured)
-----------------------------

The correct CORRECTION01 identity chain is captured in:

    evidence/factory-status-reconciliation-correction02/identity-green.txt

That file is produced by the same closure-run.sh from
`git rev-parse 31564feb...`, `git rev-parse c014d1f8...`, etc.,
and `git rev-list --count 31564feb..2d7ff45 = 3`.

IMPLEMENTATION (minimal)
------------------------

This ACT is a docs/evidence repair. The minimum production
change required is:

1. docs/factory/act-handoff-map.tsv gains one row binding this
   ACT to this HANDOFF.

2. scripts/quality/factory-closure-status-check.sh hard-coded
   MANAGED_ACTS and MANAGED_HANDOFFS each gain one line.

3. The n1-n18 negative test runner is extended to n1-n19, which
   also covers the new bounded pair (N19: remove the new row
   -> UNMAPPED_MANAGED_ACTS=1 UNMAPPED_MANAGED_HANDOFFS=1).

4. This HANDOFF and identity-red/green captures are committed.

The factory closure-status oracle's R1-R6 invariants from
CORRECTION01 are unchanged. The clean state must print:

    MANAGED_ACTS=6  MANAGED_HANDOFFS=6  MANIFEST_ROWS=6
    UNMAPPED_MANAGED_ACTS=0  UNMAPPED_MANAGED_HANDOFFS=0
    EXTRA_MANIFEST_ACTS=0    EXTRA_MANIFEST_HANDOFFS=0
    PAIR_OK=6  PAIR_FAIL=0  STATUS=PASS  VERDICT=PASS  rc=0

GATES (all PASS at C2 closure, on the clean tree)
-------------------------------------------------

sh   scripts/quality/factory-closure-status-check.sh   rc=0
dash scripts/quality/factory-closure-status-check.sh   rc=0
sh   scripts/quality/gate-fast.sh                      rc=0
bash evidence/factory-status-reconciliation-correction02/n1-n19/run.sh
                                                        rc=0
                                                        PASS=63 FAIL=0
git diff --check                                       rc=0
worktree                                               clean

Pre-commit regression (each caught, hook rc=1):
  - mutate HANDOFF verdict token         -> EXACT_VERDICT_MISMATCHES=1
  - reduce manifest by removing one row  -> UNMAPPED_MANAGED_*=1

SCOPE (conservation)
--------------------

Files changed by this ACT (and its predecessor CORRECTION01):

  scripts/quality/factory-closure-status-check.sh   (rewritten in CORRECTION01)
  docs/factory/act-handoff-map.tsv                  (extended in CORRECTION02)
  evidence/factory-status-reconciliation-correction01/HANDOFF.md  (immutable)
  evidence/factory-status-reconciliation-correction02/           (new)
  docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md  (new)

No compiler, IR, LLVM, ABI, or production code modified.

RESIDUE
-------

- P0 HALT_CORRECTION01_CLOSURE_IDENTITY_MISBOUND remains
  recorded on the historical committed CORRECTION01 HANDOFF
  (F14). This ACT supersedes the identity record only; the
  underlying closure-identity defect on the historical tree is
  not erased.
- P1: reconciling docs/ROADMAP.md's existing "P3.5 CORE01
  authorized" claim with this reviewer's HALT. Separate ACT.
- P2: extending the bounded managed universe to other ACT
  prefixes (ir-boundary*, llvmspike01-core*, factory-*);
  independent ACT.
- P2: removing the legacy llvm-closure-status-check.sh
  compatibility wrapper; independent ACT.
- P2: addressing ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01
  (FT1 in ROADMAP); independent ACT.

NEXT ACT
--------

ACT-POLYC-LLVM-CORE04 (LLVM core semantic contract repair),
or ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01, whichever the
human opens next. ACT-POLYC-LLVM-CORE04 is no longer blocked
by the CORRECTION01 closure-identity defect.
