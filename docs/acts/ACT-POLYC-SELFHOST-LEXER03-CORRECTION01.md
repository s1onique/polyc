# ACT-POLYC-SELFHOST-LEXER03-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair four closure-truth defects in
ACT-POLYC-SELFHOST-LEXER03 closure (`746880c`):

  1. `git diff --check` whitespace hygiene violations (4 trailing
     blank-line errors in files the ACT created).
  2. Authority-text mismatch: ACT §"ACT-Verdict (target)" claims
     "24 acceptance criteria" but the C3 mandatory-ac-status.tsv
     enumerates 29 rows (AC01..AC29).
  3. AC28 conflates "scope traceability" with "patch hygiene" —
     the row labels itself "Patch hygiene" but the evidence file
     proves only F7 scope discipline.
  4. ACT title and mission claim "four-stage semantic equivalence"
     but C3 evidence proves only two-stage semantic equivalence
     (stage0 vs stage1); c3-stage2.txt and c3-stage3.txt are
     explicit "N/A" with stage2/3 evidence recorded as P2 residue
     in the HANDOFF.

**Class:** CORRECTION (FACTORY-DETECT-CLOSE-MISMATCH +
CLOSURE-TRUTH)

**ACT-Supersedes:** ACT-POLYC-SELFHOST-LEXER03
(for the four closure-truth defects enumerated below; the
substantive PolyC tooling is retained and unchanged).

**Predecessor (binding):** ACT-POLYC-SELFHOST-LEXER03 CLOSED at
`746880c` (this branch's HEAD prior to CORRECTION01).

**Reviewer verdict on predecessor (`746880c`):**
`LEXER03_PASS_TRUE_GREEN = FALSE_GREEN`. The reviewer correctly
identified that:

  - STAGE0_vs_STAGE1_REAL_SEAM = PASS
  - STAGE2_STAGE3_BUILD_LINK   = PASS (4-generation build smoke)
  - LEXER03_4_STAGE_SEMANTIC_EQUIVALENCE = NOT_PROVEN

The reviewer correctly identified that AC28 is misnamed and
does not cover `git diff --check` whitespace hygiene.

The reviewer also flagged the ACT-after-work F15 lineage: the
LEXER03 ACT document itself admits "C1 and C2 were committed
prior to this document being authored". This lineage fact is
preserved as historical evidence (F14) and reclassified below
to a truthful verdict taxonomy.

**Engineering verdict preserved:** the LEXER03 implementation is
sound; the migration of `trivia_scanner` (lexSkipCodeComment +
lexCore whitespace cases) to PolyC is GREEN. Direct differential
is 45/45 PASS, real stage0/stage1 seam is byte-identical across
all 15 trivia cases, mutation control detects the `p += 3`
defect (10/45 FAIL), LEXER01 + LEXER02 conservation PASS,
Factory gates PASS, F-NO-PYTHON baseline preserved.

The CORRECTION01 ACT does NOT dispute any of these engineering
verdicts. It repairs the four documentation/governance defects
that allowed the closure to be labelled PASS_TRUE_GREEN.



**Mission (bounded):** closure-truth correction only — no
semantic mutation of the LEXER03 component. Repair:

  1. Whitespace hygiene: strip trailing blank lines from the
     three committed source files (`tools/bootstrap/selfhost-lexer-trivia.HC`,
     `tools/quality/lexer08-direct-differential.c`,
     `tools/quality/lexer08-trivia-oracle.c`)
     so that `git diff --check HEAD~9..HEAD` exits 0. F10
     conservation re-verified.
  2. AC count: align the ACT text ("24 acceptance criteria")
     with the actual C3 mandatory-ac-status.tsv (29 rows) by
     strengthening to "29 acceptance criteria" (the more
     inclusive number is the truthful one — the ACT cannot
     retroactively reduce what was actually checked).
  3. AC28 redefinition: split the conflated AC into two:
     - AC28a (existing): F7 scope traceability
       → evidence remains `c3-patch-hygiene.txt`
     - AC28b (new): mechanical `git diff --check` whitespace
       hygiene → evidence is the `c3-whitespace-hygiene.txt`
       summary produced inside this ACT.
  4. ACT title and mission amendment: amend the ACT title
     prospectively (NEW TITLE: "Migrate the mechanically-selected
     `trivia_scanner` region to PolyC and prove two-stage
     semantic equivalence (stage0 vs stage1) plus 4-generation
     build smoke"). The 4-generation build smoke remains
     observed via `LEXER08_BROAD_CORPUS_4_STAGE`. The
     "two-stage semantic equivalence" claim is exactly what
     `c3-real-lexer-seam.txt` proves.

**Scope (this CORRECTION01):**

  - `tools/bootstrap/selfhost-lexer-trivia.HC` (whitespace only)
  - `tools/quality/lexer08-direct-differential.c` (whitespace only)
  - `tools/quality/lexer08-trivia-oracle.c` (whitespace only)
  - `evidence/ACT-POLYC-SELFHOST-LEXER03/c3/c3-real-lexer-seam.txt`
    (whitespace only — F14 protected; trailing newlines are
    mechanical, but to be safe this file is left unchanged and
    the whitespace hygiene AC28b is verified against the
    source-code files only; the evidence file's own trailing
    newline is preserved as historical evidence per F14).
  - `docs/acts/ACT-POLYC-SELFHOST-LEXER03.md` (title + §AC count
    + AC28 split amendments)
  - `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER03.md`
    (verdict reclassification: ENGINEERING=GREEN,
    LINEAGE=RETROSPECTIVE_REPAIR, FULL_4_STAGE_PROOF=N/A)
  - `docs/ROADMAP.md` (LEXER03 status block reclassified)
  - `evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/c{1,2,3,4}/`
    (NEW evidence directory for the four repairs)

**Out of scope (residue for ACT-POLYC-SELFHOST-LEXER03-CORRECTION02):**

  - **P0**: actually produce LEXER03-specific stage2/stage3
    fixed-point evidence (compile `BootstrapScanTrivia` with
    stage1/2/3 binaries and verify byte-equality of the
    produced `.o` files). This requires extending the
    lex-bootstrap pipeline to stage4 for LEXER03 specifically,
    which is bounded-evidence work that exceeds CORRECTION01's
    scope.
  - **P1**: repair the pre-existing `test-prefix-install`
    target failure (pre-existing residue; not introduced by
    LEXER03).
  - **P1**: ACT-after-work governance hygiene — future ACTs
    should author the ACT document BEFORE the first evidence
    commit.
  - **P2**: broader self-host recon refresh — wait until
    CORRECTION01 closes to avoid stale snapshot artifacts.

**ACT-Verdict (target):** PASS only after all four repairs are
green, F10 conservation re-verified, and the new CORRECTION01
HANDOFF documents the truth-state of LEXER03.

**ACT-Verdict taxonomy (binding):**

  - `ENGINEERING_RESULT`         = GREEN  (preserved from predecessor)
  - `STAGE0_STAGE1_EQUIVALENCE`  = GREEN  (preserved from predecessor)
  - `LINEAGE_PASS_TRUE_GREEN`    = FALSE_GREEN (reviewer correct;
                                                repaired below)
  - `FULL_4_STAGE_EQUIVALENCE`   = N/A    (amended prospectively;
                                                out of CORRECTION01
                                                scope; residue for
                                                CORRECTION02)
  - `WHITESPACE_HYGIENE`         = repaired inside CORRECTION01
  - `AC_AUTHORITY_TEXT`          = aligned inside CORRECTION01
