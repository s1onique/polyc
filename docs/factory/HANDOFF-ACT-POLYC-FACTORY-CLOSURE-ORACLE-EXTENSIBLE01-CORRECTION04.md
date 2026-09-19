HANDOFF for ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04

VERDICT

PASS_FALSE_GREEN_HALTTED_AT_HANDBOFF_LEVEL

  This ACT does NOT issue a PASS_TRUE_GREEN. It records the
  reviewer's FALSE_GREEN reclassification of CORRECTION03 and
  freezes CORRECTION04's own narrower verdict. The closure
  oracle's lineage as a whole is reclassified FALSE_GREEN
  pending a future CORRECTION05 ACT.

  This is the explicit, reviewer-acknowledged outcome of this
  ACT's scope. It is NOT a regression from CORRECTION03's
  claimed PASS_TRUE_GREEN; that claim was the defect.

IDENTITY

  ACT: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04
  Predecessor: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03
    Open (C0):               87aec89
    C1 RED:                  1669bce
    C2 PRE:                  6370707
    C2 IMPL:                 f9906f1
    C3 VERIFY:               26cbee8
    C4 CLOSE (claimed):      aa47d58
    C4 patch hygiene:        8fbf51d
    HANDOFF verdict recorded: PASS_TRUE_GREEN
    Reviewer verdict:        FALSE_GREEN
    Reclassification:        PREDECESSOR_RECLASSIFICATION = FALSE_GREEN
  This ACT:
    Open (C0):               0b33cf7
    C1 RED + C3 VERIFY:      0edaae2
    C4 CLOSE:                <this commit>

ROOT CAUSE / FINDING

  CORRECTION03 closed with PASS_TRUE_GREEN despite two binding
  governance defects:

  P0-1 CORRECTION03 ACT body line 125 froze:
       "git diff --check 0665ada..HEAD continues to report clean."
    Observed at HEAD = 8fbf51d (CORRECTION03 C4 hygiene):
       $ git diff --check 0665ada..HEAD
       ... 4 "new blank line at EOF" warnings in CORRECTION01 evidence
    Predicate is FALSE. The 4 errors are inherent to the b9a43f8
    historical blobs (re-introduced by F14 restoration).

  P0-2 CORRECTION03 ACT body line 91 declared:
       "docs/factory/act-handoff-map.tsv (working; do not touch)"
    Observed in C0 commit 87aec89:
       $ git show 87aec89 -- docs/factory/act-handoff-map.tsv
       ... +ACT-...-CORRECTION03 row added ...
    C0 ACT body declared this mutation out-of-scope; C0 commit
    performed it anyway. F15 self-authorization defect.

  Reviewer's verdict: FALSE_GREEN.
    ENGINEERING_GREEN          (F14 restoration, additive capture,
                                 12/12 regression, oracle mechanics)
    PATCH_HYGIENE_AUTH_FAIL    (predicate #6 false)
    MANIFEST_SCOPE_DISCIPLINE_FAIL (C0 modified declared-out-of-scope file)
    OVERALL                    FALSE_GREEN

RED

  c0/c0-p01-patch-hygiene-falsification.txt:
    SHA-pinned falsification of predicate #6 with line-count
    walk through the lineage showing the errors are inherent
    to b9a43f8 blobs.
  c0/c0-p02-manifest-scope-violation.txt:
    SHA-pinned falsification of out-of-scope declaration with
    git show 87aec89 evidence.
  c1/c1-baseline-freezing.txt:
    Patch-hygiene baseline freezing. 0665ada..HEAD is
    unsatisfiable; CORRECTION04 freezes aa47d58..HEAD.

IMPLEMENTATION

  None. CORRECTION04 is reclassification-only.

  The 4 closed CORRECTION01 evidence files remain bitwise
  identical to b9a43f8 (F14 restoration preserved). No further
  mutation of closed artifacts.

GATES (state at this C4 commit)

  12-pair closure oracle (current + after this commit):
    PRE-C4: PAIR_OK=12 PAIR_FAIL=0 STATUS=PASS
    POST-C4: PAIR_OK=13 PAIR_FAIL=0 STATUS=PASS
    (CORRECTION04 self-row added at this C4 commit; HANDOFF
     written at this same commit; transition is atomic.)

  12-case PolyC regression: 12/12 PASS

  F14 restoration (b9a43f8..HEAD on CORRECTION01 evidence):
    empty diff = preserved

  Patch hygiene aa47d58..HEAD: clean
    (frozen baseline; 0665ada..HEAD is FALSE but unsatisfiable
     while F14 restoration stands; resolution deferred)

  Patch hygiene aa47d58..HEAD on this C4 commit:
    Will be verified post-commit; the C4 commit only adds the
    HANDOFF file and a manifest self-row, both expected to be
    patch-hygiene clean.

SCOPE (bounded)

  This ACT mutated:
    - docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04.md (C0)
    - evidence/.../CORRECTION04/c0/*.txt (C0)
    - evidence/.../CORRECTION04/c1/*.txt (C1+C3)
    - evidence/.../CORRECTION04/c3/*.txt (C1+C3)
    - docs/factory/act-handoff-map.tsv (C4 self-row, EXPLICITLY
       authorized at C0)
    - docs/factory/HANDOFF-...-CORRECTION04.md (C4, this file)

  Out of scope (per F7/F15):
    - tools/quality/factory-closure-status-test.HC
    - scripts/quality/factory-closure-status-check.sh
    - All closed ACT bodies and HANDOFFs (F14 immutability)
    - The 4 closed CORRECTION01 evidence files (F14 restoration
       stands; 0665ada..HEAD predicate resolution deferred)
    - Any pending Factory roadmap ACT

RESIDUE

  The two binding P0s documented in c0/ are real and unresolved:

  (a) The 0665ada..HEAD patch-hygiene predicate is FALSE while
      F14 restoration to b9a43f8 stands. This is a tautological
      impossibility of CORRECTION03's chosen baseline, not a
      corruption of the F14 restoration itself.

  (b) The manifest self-row pattern (CORRECTION02's ca67d1a,
      CORRECTION03's 87aec89) was performed without explicit
      C0 authorization. CORRECTION04 explicitly authorizes its
      own self-row at C0 (deferred to C4); the prior rows remain
      forward-only history per F14.

  Resolution requires a CORRECTION05 (or later) ACT whose scope
  explicitly:

    (a1) selects a new patch-hygiene baseline and either ratifies
         the EOF blanks as canonical or performs a forward-only
         normalization that doesn't touch closed evidence;
    (a2) OR modifies the closure oracle to accept the EOF blanks
         under documented exceptions;
    (b1)  ratifies the manifest self-row pattern as established
          factory practice via a checker change;
    (b2)  OR removes the prior rows (impossible per F14).

  CORRECTION05 cannot be opened from this ACT. It requires its
  own C0 AUTH at a future session, with a clean worktree and a
  deliberately chosen baseline.

  Unblocked roadmap ACTs remain blocked:
    ACT-POLYC-LIBTOS-SYMBOL-GAPS01
    ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
    ACT-POLYC-SELFHOST-SURFACE-RECON03

  They will be unblocked when a subsequent ACT achieves
  PASS_TRUE_GREEN for the closure-oracle lineage. The closure-
  oracle's authority is presently REINSTATED FOR INTERNAL USE
  (mechanical gates work; self-pair math works; F14 restoration
  holds) but is NOT REINSTATED FOR UNBLOCKING NEW ROADMAP WORK
  because the HANDOFF verdict reclassification is FALSE_GREEN.

LIFECYCLE

  C0 (0b33cf7): ACT body + c0/ evidence (no manifest mutation)
  C1 + C3 (0edaae2): baseline freezing + gate measurements
  C4 (this commit): manifest self-row + HANDOFF, atomic
  No post-C4 cleanup commits. Lifecycle smell from CORRECTION03
  is not repeated.

ENTRY IDENTITY (C4 CLOSE)

  git branch --show-current = main
  HEAD before this commit:  0edaae20691e66a1743e4c58563fdfd164cd10f4
  Worktree:                 clean (modulo this commit's two files)
  This commit:              <queryable via git log>
