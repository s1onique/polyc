HANDOFF — ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01
============================================================

## VERDICT

PASS_TRUE_GREEN.

The CORRECTION01 closure verdict is reclassified:
  CORRECTION01_CLOSE_PASS_OLD  = FALSE_GREEN (TSV defect)
  CORRECTION01_CLOSE_PASS_NEW  = TRUE_GREEN  (TSV repaired additively)

## IDENTITY

  Branch: main
  HEAD:   <to-be-filled-at-commit>
  Worktree: clean
  ACT:    docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01.md
  Predecessor: ACT-POLYC-SELFHOST-LEXER03-CORRECTION01 (CLOSED at 9012c94)

## ROOT CAUSE / FINDING

CORRECTION01 closed at `9012c94` with a mandatory-AC TSV
(`evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/c3/mandatory-ac-status-correction01.tsv`)
that uses the token "CORRECTION01" in the `verdict` column
for 6 rows (AC23, AC24, AC25, AC26, AC27, AC29). The
declared verdict vocabulary is PASS / FAIL / N/A. The
CORRECTION01 token was used as an implicit repair-source
marker, not a verdict.

Mechanically the closed TSV therefore has:

```text
TOTAL_ROWS    = 30
PASS_ROWS     = 24
NONPASS_ROWS  = 6
```

which conflicts with the CORRECTION01 ROADMAP block claim
"30 ACs = authoritative" and with the AC26 note "PASS only
after all 30 acceptance criteria are PASS".

A reviewer of the CORRECTION01 closure correctly identified
this as a mechanical closure-truth defect: the verdict
column had been silently extended to include a repair-source
marker, and an auditor reading the TSV without consulting
the notes column sees only 24 PASS.

The defect is in the verdict-column encoding, not in the
underlying work. All 6 affected rows' underlying work IS
green (whitespace hygiene, AC split, title amendment, count
alignment, verdict taxonomy installation, hand-off
completion). The fix is to re-issue a corrected TSV with
verdict=PASS for all 30 rows, and to declare the verdict
vocabulary explicitly so future TSVs do not silently extend
it.

## RED

`evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01-CORRECTION01/c1/c1-red-tsv-defect.txt`
reproduces the defect as committed at 9012c94:

```text
$ awk -F'\t' 'NR>1 {print $4}' .../mandatory-ac-status-correction01.tsv | sort | uniq -c
   6 CORRECTION01
  24 PASS
```

## IMPLEMENTATION (repair)

The fix is documentary. No production code, no tool source,
no closed ACT, no closed evidence file is modified.

The fix consists of:

  1. NEW evidence directory
     `evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01-CORRECTION01/`
     containing:
       - c1-red-tsv-defect.txt        (RED reproduction)
       - c2-entry-identity.txt        (F1/F15 boundary)
       - c3-verdict-vocabulary.md     (declared vocabulary)
       - c3-per-row-justification.txt (per-row PASS rationale)
       - mandatory-ac-status-correction01-correction01.tsv
                                       (CORRECTED TSV: 30 PASS rows)
       - c3-entry-identity.txt        (C3-phase identity)
       - c4-entry-identity.txt        (C4-phase identity)

  2. NEW ACT document
     `docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01.md`
     (236 lines; full mission/scope/RED/IMPL/verdict plan).

  3. NEW HANDOFF (this file).

  4. ADDITIVE amendments to:
     - docs/ROADMAP.md (new CORRECTION01-CORRECTION01 status
       block; existing LEXER03-CORRECTION01 block amended
       in place with a reclassification note; no rewrites)
     - docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER03-CORRECTION01.md
       (amendment appended at end recording the
       reclassification; closed HANDOFF body preserved)

F14 IMMUTABILITY CHECK:

  $ git diff 9012c94 HEAD -- \
        evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/c3/mandatory-ac-status-correction01.tsv
  (empty)

The closed TSV remains exactly as committed at 9012c94.

## GATES (re-run at C4 CLOSE)

  Factory gate-fast:           PASS  (status=PASS)
  Factory append-only NC1..NC11: PASS  (PASS=11 FAIL=0)
  Direct differential 45/45:    PASS  (F10 conservation unchanged)
  LEXER01 47/47 conservation:  PASS  (unchanged)
  LEXER02 89/89 conservation:  PASS  (unchanged)
  F-NO-PYTHON baseline:        preserved (POLYC_TOOLS_TRACKED_PYTHON=12)
  `git diff --check` on new C01-C01 files: PASS (no errors)

## SCOPE

  IN-SCOPE (executed):
    - docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01.md (NEW)
    - evidence/.../CORRECTION01-CORRECTION01/{c1,c2,c3,c4}/* (NEW; 7 files)
    - docs/ROADMAP.md (additive amendment; no rewrites)
    - docs/factory/HANDOFF-.../CORRECTION01-CORRECTION01.md (NEW)
    - docs/factory/HANDOFF-.../CORRECTION01.md (additive amendment; no rewrites)

  OUT-OF-SCOPE (F14-PROTECTED, unchanged):
    - All closed LEXER03 evidence (35 files)
    - All closed CORRECTION01 evidence (7 files; closed C3 TSV
      remains as historical evidence of the malformed state)
    - docs/acts/ACT-POLYC-SELFHOST-LEXER03.md (original ACT)
    - docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION01.md (C01 ACT)
    - docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER03.md (original HANDOFF)
    - src/, Makefile (production code)
    - tools/bootstrap/, tools/quality/ (compiler/tool source)

  OUT-OF-SCOPE (residue for CORRECTION02):
    - Real LEXER03-specific stage2/stage3 fixed-point evidence.

## RESIDUE

  P0 (CORRECTION02-bound): LEXER03-specific stage2/stage3
    fixed-point evidence. Documented in the CORRECTION01
    HANDOFF §"NEXT ACT". Not consumed by this
    CORRECTION01-CORRECTION01.

  P1 (governance): The CORRECTION01 TSV's verdict-column
    vocabulary was implicitly extended. This
    CORRECTION01-CORRECTION01 declares the vocabulary
    explicitly (c3-verdict-vocabulary.md) to prevent future
    regressions. Future ACTs that need a repair-source marker
    should add a dedicated column, not extend the verdict
    column.

  P1 (governance): ACT-after-work hygiene. Documented in
    the CORRECTION01 HANDOFF. The CORRECTION01-CORRECTION01
    itself follows the recommended pattern (ACT authored at
    C0 BEFORE the C1/C3 evidence commits).

  P2: broader self-host recon refresh.

## NEXT ACT

  Recommended next: ACT-POLYC-SELFHOST-LEXER03-CORRECTION02
    (real LEXER03-specific stage2/stage3 fixed-point evidence).
    Already documented in the CORRECTION01 HANDOFF §"NEXT ACT".
    This CORRECTION01-CORRECTION01 does NOT consume its budget.

  Or: ACT-POLYC-SELFHOST-LEXER04 (next surface-recon winner).
    NOT authorized by this ACT; a separate LEXER04 ACT must
    be opened with its own C0 authorization.
