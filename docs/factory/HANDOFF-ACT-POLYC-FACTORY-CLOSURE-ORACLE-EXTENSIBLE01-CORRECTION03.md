HANDOFF for ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03

VERDICT

PASS_TRUE_GREEN

IDENTITY

  ACT: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03
  Predecessor: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02
    Open:                ca67d1a
    Close:               08365aa
    HANDOFF verdict:     PASS_TRUE_GREEN
    Reviewer verdict:    FALSE_GREEN
    Engineering GREEN;   governance FAIL
    Reclassification:    PREDECESSOR_RECLASSIFICATION = FALSE_GREEN
  This ACT open:         87aec89 (C0 AUTH)
  This ACT C1 RED:       1669bce
  This ACT C2 PRE:       6370707 (additive capture)
  This ACT C2 IMPL:      f9906f1 (F14 restoration)
  This ACT C3 VERIFY:    26cbee8
  This ACT C4 CLOSE:     <this commit>

ROOT CAUSE / FINDING

  The closed CORRECTION02 reached PASS_TRUE_GREEN with two
  governance defects that survived its engineering repair:

    P0-G1 C0 pre-existing-work authorization:
      CORRECTION02's own C0 ACT body admitted "git status --short
      = clean (modulo unstaged whitespace fixes to CORRECTION01
      evidence files; those are committed in C2 of this ACT)".
      This "modulo" clause enumerated implementation work that
      existed at C0 AUTH time, demonstrating a F15 self-
      authorization defect.

    P0-G2 F14 closed-evidence immutability:
      CORRECTION02 physically rewrote 4 closed CORRECTION01
      evidence files (removed trailing blank lines), even though
      its own HANDOFF stated "per F14, CORRECTION01 evidence is
      immutable". Forward-only Git history does not excuse
      modification of a closed artifact's current repository
      blob.

RED

  c1-red-p01-c0-admission.txt:
    Quotes the exact CORRECTION02 C0 ACT body lines 14-19
    containing the "clean modulo" admission. Provides
    line-citation pointer into the immutable ACT body.

  c1-red-p02-f14-immutability.txt:
    SHA-pair audit of the 4 closed CORRECTION01 evidence files.
    For each file: historical SHA at b9a43f8 vs current SHA at
    C0 boundary (87aec89) -> DIFFER. Confirms F14 violation.

IMPLEMENTATION

  C2 PRE (6370707): additive capture
    Captured the CORRECTION02-modified (whitespace-cleaned)
    content as additive files under
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE02-
    CORRECTION02-CAPTURE/c2/
    This is OUTSIDE both the closed CORRECTION01 and CORRECTION02
    evidence trees. No F14 violation; no information loss.

  C2 IMPL (f9906f1): F14 restoration
    Restored the 4 closed CORRECTION01 evidence files to their
    exact historical b9a43f8 blobs via `git checkout b9a43f8 --`.
    Forward-only restoration. Git history preserves both the
    CORRECTION02 modification and this restoration.

GATES

  F14 restoration proof:
    git diff b9a43f8..HEAD -- evidence/.../CORRECTION01/ = empty
    -> All 4 files at HEAD are bitwise identical to their
       historical b9a43f8 blobs.

  11-pair oracle:
    C3 verify state: PAIR_OK=11 PAIR_FAIL=1 STATUS=FAIL
      (CORRECTION03 self-pair missing HANDOFF, expected)
    C4 close state:  PAIR_OK=12 PAIR_FAIL=0 STATUS=PASS
      (HANDOFF added, no other changes)

  12-case PolyC regression:
    PASS 12/12

  Patch hygiene (meaningful range):
    git diff --check b9a43f8..HEAD = clean.
    The 08365aa..HEAD range reports the 4 restored files as
    "new blank line at EOF"; this is the CORRECTION03
    restoration in progress, not a violation. See
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
    CORRECTION03/c3/c3-patch-hygiene.txt for detailed analysis.

SCOPE

  All changes bounded to:
    - 4 closed CORRECTION01 evidence files: restored to b9a43f8
      blobs (F14 restoration; production neutral)
    - 4 new additive files under CORRECTION02-CAPTURE/c2/
      namespace: CORRECTION02-modified content preserved
    - 1 ACT body (this ACT)
    - 1 self-row in docs/factory/act-handoff-map.tsv
    - 1 HANDOFF file (this file)
    - 1 README at the CORRECTION02-CAPTURE/c2/ namespace

  Out of scope (per F7/F15):
    - tools/quality/factory-closure-status-test.HC (working)
    - scripts/quality/factory-closure-status-check.sh (working)
    - all closed ACT bodies and HANDOFFs (immutable)
    - all CORRECTION02 evidence (closed; additive capture only)
    - any pending Factory roadmap ACT

RESIDUE

  - The CORRECTION02 C0 ACT body remains immutable with its
    "clean modulo" admission preserved as historical evidence.
    Its lineage consequence is recorded here and in this ACT's
    c1/ evidence; the ACT body itself is not rewritten.
  - The CORRECTION02-produced whitespace-clean content lives
    additively at CORRECTION02-CAPTURE/c2/. It is not used
    anywhere downstream; the F14 restoration is canonical.
  - The "10-pair vs 11-pair" narrative mismatch flagged by the
    reviewer (CORRECTION02 HANDOFF said "10-pair" but the
    manifest grew to 11 by C4 close) is preserved as-is in
    CORRECTION02's HANDOFF per F14. Future ACTs that touch
    the closure oracle should reference both pair counts.

NEXT ACT

  After this ACT closes, the Factory closure oracle's authority
  is finally restored with both engineering AND governance
  defects resolved. Subsequent Factory ACTs may proceed:

    ACT-POLYC-LIBTOS-SYMBOL-GAPS01
    ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
    ACT-POLYC-SELFHOST-SURFACE-RECON03

  No further blocked-by-this-ACT residue.

ENTRY IDENTITY (C4 CLOSE)

  git branch --show-current = main
  HEAD before this HANDOFF addition: 26cbee89abb79e4f1f83769e3691d7662938afb5
  Worktree: clean (after this commit)
