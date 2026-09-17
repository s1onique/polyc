HANDOFF-ACT-POLYC-SELFHOST-LEXER03-CORRECTION01
=================================================

## VERDICT

  CORRECTION01:       PASS (4 of 4 repairs green)
  Predecessor:        ACT-POLYC-SELFHOST-LEXER03 CLOSED at `746880c`
                      (reviewer verdict: LEXER03_PASS_TRUE_GREEN = FALSE_GREEN)

  Truth-state after CORRECTION01 closes:

    ENGINEERING_RESULT         = GREEN
    STAGE0_STAGE1_EQUIVALENCE  = GREEN
    LINEAGE_PASS_TRUE_GREEN    = FALSE_GREEN (reclassified;
                                              ACT-after-work F15
                                              lineage is preserved
                                              as historical fact)
    FULL_4_STAGE_EQUIVALENCE   = N/A    (amended prospectively;
                                         out of CORRECTION01 scope;
                                         residue for CORRECTION02)
    WHITESPACE_HYGIENE         = GREEN  (repaired)
    AC_AUTHORITY_TEXT          = ALIGNED (29 ACs = authoritative;
                                          original ACT text's "24"
                                          is F14 historical evidence)
    AC28 SPLIT                 = AC28a (F7 scope, pre-existing)
                                + AC28b (mechanical `git diff --check`,
                                         new in CORRECTION01)

## IDENTITY

  ACT:                  ACT-POLYC-SELFHOST-LEXER03-CORRECTION01
  Title:                Repair four closure-truth defects in
                        ACT-POLYC-SELFHOST-LEXER03 closure (`746880c`)
  Authorization:        docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION01.md
                        (added at C0)
  Predecessor:          ACT-POLYC-SELFHOST-LEXER03 CLOSED `746880c`
                        (FALSE_GREEN per reviewer)
  C0 AUTH:              f27e1c7
  C2 IMPL repair 1:     8db7f01  (whitespace hygiene on 3 source files)
  C2 IMPL repair 2/4:   fd4fd60  (ROADMAP annotation + status block)
  C3 EVIDENCE:          <this commit>
  C4 CLOSE:             d0b55891699be20427437cf7b370cbc0085ba648

## ROOT CAUSE / FINDING

  The LEXER03 closure at `746880c` was labelled PASS_TRUE_GREEN
  but had four closure-truth defects that the reviewer correctly
  identified as a FALSE_GREEN verdict:

  1. `git diff --check` reported 4 trailing-blank-line errors
     on committed files. The C3 evidence directory's
     AC28 row was labelled "Patch hygiene" but tested only
     F7 scope traceability (not mechanical `git diff --check`).

  2. The original ACT text claimed "24 acceptance criteria"
     but the C3 evidence directory's mandatory-ac-status.tsv
     enumerated 29 rows. The TSV is the authoritative evidence;
     the ACT text's "24" is a historical inaccuracy.

  3. The ACT title and mission claimed "four-stage semantic
     equivalence" but the C3 evidence directory's c3-stage2.txt
     and c3-stage3.txt were explicit "N/A" with stage2/3
     evidence recorded as P2 residue in the original HANDOFF.
     The ACT title overreached the proven predicate surfaces.

  4. The LEXER03 ACT document itself admits the ACT was
     authored AFTER the C1 and C2 commits (8ae0c2a, AFTER
     6f9dbcc and d8046fc). This is an F15 violation that was
     repaired retroactively but is preserved as historical
     evidence per F14.

## RED (reproduction)

  C1 RED at evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/
  c1/c1-red-lineage-defect.txt independently re-ran all four
  predicates against the committed tree:

  - Defect 1 (whitespace):  REPRODUCED (4 trailing-blank errors)
  - Defect 2 (AC count):    REPRODUCED (24 in text, 29 in TSV)
  - Defect 3 (AC28 mislabel): REPRODUCED (scope, not whitespace)
  - Defect 4 (4-stage overreach): REPRODUCED (stage2/3 N/A)
  - Lineage (F15):          CONFIRMED (ACT at 8ae0c2a, after C1/C2)

## IMPLEMENTATION (repairs)

  Repair 1: Whitespace hygiene (commit 8db7f01)
    - Stripped trailing blank lines from 3 source files:
      * tools/bootstrap/selfhost-lexer-trivia.HC
      * tools/quality/lexer08-direct-differential.c
      * tools/quality/lexer08-trivia-oracle.c
    - F14-protected evidence file
      (c3/c3-real-lexer-seam.txt) left unchanged per F14.
    - F10 conservation: re-ran direct differential
      (45/45 PASS, unchanged).

  Repair 2: AC count alignment (commit fd4fd60 + C3 evidence)
    - Original ACT text (F14-protected) cannot be edited.
    - CORRECTION01 ACT body supersedes the corrected
      predicate surfaces.
    - New AC table at evidence/.../CORRECTION01/c3/
      mandatory-ac-status-correction01.tsv enumerates
      the CORRECTION01 AC set (30 rows: AC01..AC29 +
      AC28a + AC28b split).
    - Honest count after CORRECTION01 closes: 30 ACs.

  Repair 3: AC28 split (commit fd4fd60 + C3 evidence)
    - AC28a (existing, unchanged): F7 scope traceability
      -> evidence remains c3-patch-hygiene.txt (F14-protected).
    - AC28b (new): mechanical `git diff --check` whitespace
      hygiene -> evidence is c3-whitespace-hygiene.txt in
      CORRECTION01/c3/.

  Repair 4: Title amendment (commit fd4fd60 + CORRECTION01 ACT)
    - Original ACT title (F14-protected) remains "four-stage
      semantic equivalence" as historical evidence.
    - CORRECTION01 ACT body establishes the prospective
      understanding: "two-stage semantic equivalence
      (stage0 vs stage1) plus 4-generation build smoke".
    - ROADMAP reviewer-audit annotation at the top of the
      LEXER03 status block documents the supersession
      pattern (LEXER02-CORRECTION04 precedent).

## GATES

  Factory gate-fast:           PASS  (re-verified post-repair)
  Factory append-only NC1..NC11: PASS  (re-verified post-repair)
  Direct differential 45/45:    PASS  (re-verified post-repair)
  LEXER01 47/47 conservation:  PASS  (unchanged)
  LEXER02 89/89 conservation:  PASS  (unchanged)
  F-NO-PYTHON baseline:        preserved (POLYC_TOOLS_TRACKED_PYTHON=12)
  `git diff --check d8046fc HEAD --`:
       3 source files          PASS  (whitespace clean)
       1 evidence file (F14)   preserved as historical

## SCOPE

  IN-SCOPE (this CORRECTION01, executed):
    - docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION01.md (NEW)
    - docs/ROADMAP.md (annotation + new CORRECTION01 status block)
    - tools/bootstrap/selfhost-lexer-trivia.HC (whitespace only)
    - tools/quality/lexer08-direct-differential.c (whitespace only)
    - tools/quality/lexer08-trivia-oracle.c (whitespace only)
    - evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/c{1,2,3,4}/
      (NEW evidence directory)

  OUT-OF-SCOPE (F14-PROTECTED, unchanged):
    - docs/acts/ACT-POLYC-SELFHOST-LEXER03.md (historical evidence)
    - docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER03.md (historical evidence)
    - evidence/ACT-POLYC-SELFHOST-LEXER03/c{1,2,3}/* (historical evidence)
    - src/lexer.c, src/lexer_bridge.h, Makefile (production code unchanged)

  OUT-OF-SCOPE (residue for CORRECTION02):
    - Actually producing LEXER03-specific stage2/3 fixed-point
      evidence (requires extending lex-bootstrap to stage4 for
      LEXER03 specifically).

## RESIDUE

  P0 (CORRECTION02-bound): LEXER03-specific stage2/stage3 fixed-point
    evidence. The lex-bootstrap pipeline does not currently
    produce bootstrap05-trivia.stage1.o or later. A future ACT
    could extend the pipeline to produce these; the property
    is already proven by LEXER02's 4-stage evidence at the
    corpus level.

  P1 (pre-existing): test-prefix-install Makefile target failure
    (unrelated to LEXER03).

  P1 (governance): ACT-after-work hygiene. Future ACTs should
    author the ACT document BEFORE the first evidence commit
    (this CORRECTION01 ACT itself was authored at C0 = f27e1c7
    BEFORE the C1/C2/C3 evidence commits inside CORRECTION01,
    so CORRECTION01 itself follows the recommended pattern).

  P2: broader self-host recon refresh.

## NEXT ACT

  Recommended next: ACT-POLYC-SELFHOST-LEXER03-CORRECTION02
  (LEXER03-specific stage2/stage3 fixed-point evidence).

  Or, if the reviewer's recommendation is to defer stage2/3
  and prioritize new surface migration: ACT-POLYC-SELFHOST-LEXER04
  (next surface-recon winner) with a fresh surface-recon first.

  LEXER04 is NOT authorized by this CORRECTION01; a separate
  LEXER04 ACT must be opened with its own C0 authorization.
