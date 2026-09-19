# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03

## Identity

- ACT id: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03
- Phase:  C0 AUTH (authorization; no production mutation)
- Predecessor: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02
- Predecessor verdict recorded: PASS_TRUE_GREEN (rejected by reviewer
  on governance grounds)
- Reclassification of predecessor: PREDECESSOR_RECLASSIFICATION =
  FALSE_GREEN (engineering repairs GREEN; governance lineage FAIL)
- Reviewer-disposition evidence:
  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03/
    c0/c0-predecessor-review-disposition.txt
- Entry identity:
    git branch --show-current = main
    git rev-parse HEAD        = 08365aad59ac59b1d7dc303278aab2bbca446660
    git status --short        = clean

## Predecessor in scope

- ACT id: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02
- Open:   ca67d1a
- Close:  08365aa
- HANDOFF verdict recorded at close: PASS_TRUE_GREEN
- Post-closure reviewer verdict: FALSE_GREEN
- Engineering defects: GREEN (12/12 PolyC test, real C3 commit, patch
  hygiene, shell engine deleted)
- Governance defects (this ACT's scope):
    P0-G1 C0 pre-existing-work authorization:
      CORRECTION02 C0 ACT body itself admitted
      "git status --short = clean (modulo unstaged whitespace fixes
      to CORRECTION01 evidence files; those are committed in C2 of
      this ACT)". The "modulo" admission is a F15 self-authorization
      defect: implementation work existed before authorization.
    P0-G2 F14 closed-evidence immutability:
      CORRECTION02 physically rewrote 4 closed CORRECTION01 evidence
      files (removed trailing blank lines), even though CORRECTION02's
      own HANDOFF said "per F14, CORRECTION01 evidence is immutable".
      Forward-only history does not excuse modification of a closed
      artifact's current repository content.

## Scope (bounded)

This ACT is purely governance/additive. No production mutation.
No checker, manifest, ACT body, or test implementation is touched.

### P0-G1 -- record (not rewrite) the C0 pre-work defect

CORRECTION02's C0 ACT body explicitly admitted pre-existing
unstaged whitespace work that was later committed as the C2
P0-3 "repair". That admission is a fact, not history to be
rewritten. Per F14, CORRECTION02's C0 ACT body remains
immutable. The defect is recorded as additive evidence under
this ACT's c0/ namespace, with a citation pointer to the
exact lines in CORRECTION02's C0 body.

### P0-G2 -- restore F14 immutability of closed CORRECTION01 evidence

The 4 closed CORRECTION01 evidence files
  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01/
    c2/c2-p02-n01-n05-regression.txt
    c3/c3-act-body-unchanged.txt
    c3/c3-checker-unchanged.txt
    c3/c3-manifest-unchanged.txt
were physically modified by CORRECTION02 (their current SHA differs
from the b9a43f8 SHA). This violates F14 ("once a commit exists,
it is immutable evidence"). CORRECTION02's prose claim that the
modifications were "forward-only replacement" is structurally
incompatible with the closed evidence's immutable status.

Repair (this ACT):
  - Restore each of the 4 files to its exact historical blob
    (sha256 at b9a43f8) via `git checkout b9a43f8 -- <path>`.
  - Preserve the whitespace-clean content as additive files under
    this ACT's evidence namespace:
      evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
        CORRECTION02/c2/correction02-c2-p02-n01-n05-regression-
        cleaned.txt
      ... (one additive copy per restored file)
  - Record the SHA-pair (historical at b9a43f8 vs current at this
    ACT's entry vs current at this ACT's C3 boundary) for each file.

After this ACT, `git diff b9a43f8..HEAD -- evidence/.../CORRECTION01/`
shows the 4 files as bitwise identical to their b9a43f8 blobs.

## Out of scope (per F7/F15)

- tools/quality/factory-closure-status-test.HC (working; do not touch)
- scripts/quality/factory-closure-status-check.sh (working; do not touch)
- docs/factory/act-handoff-map.tsv (working; do not touch)
- docs/factory/SHELL-BUDGET.tsv (working; do not touch)
- docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01.md
  (closed ACT body; immutable)
- docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02.md
  (C0 admission is historical evidence, not to be rewritten)
- docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-
  EXTENSIBLE01-CORRECTION01.md (immutable HANDOFF)
- docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-
  EXTENSIBLE01-CORRECTION02.md (HANDOFF recorded verdict;
  reclassification recorded as additive evidence under this ACT,
  not by rewriting CORRECTION02's HANDOFF)
- evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02/*
  (CORRECTION02 evidence is itself closed; only ADDITIVE copies
  of the P0-3 whitespace-clean content are added under this ACT's
  CORRECTION02/c2/ namespace, not as modifications to CORRECTION02
  evidence)
- Any pending Factory roadmap ACT:
    ACT-POLYC-LIBTOS-SYMBOL-GAPS01
    ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
    ACT-POLYC-SELFHOST-SURFACE-RECON03

## Success criteria

1. All 4 closed CORRECTION01 evidence files have current SHA equal to
   their b9a43f8 SHA.
2. The whitespace-clean content is preserved as additive evidence.
3. The C0 pre-work defect is recorded as additive evidence with a
   line-citation pointer into CORRECTION02's C0 ACT body.
4. `bash scripts/quality/factory-closure-status-check.sh` continues
   to report `PAIR_OK=11 PAIR_FAIL=0 STATUS=PASS VERDICT=PASS` on
   the current 11-row manifest.
5. `sh scripts/quality/factory-closure-status-check-test.sh` continues
   to report 12/12 PASS through the PolyC binary.
6. `git diff --check 0665ada..HEAD` continues to report clean.
