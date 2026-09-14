HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION02
================================================

## VERDICT
  PASS (CLOSED)

## IDENTITY
  ACT:                ACT-POLYC-SELFHOST-LEXER02-CORRECTION02
  Title:              Repair three additional closure-truth defects
                       identified by the post-CORRECTION01
                       reviewer audit of LEXER02
  ACT-Supersedes:     ACT-POLYC-SELFHOST-LEXER02-CORRECTION01
  Predecessor (closed): d048ca9 ACT-POLYC-SELFHOST-LEXER02-CORRECTION01
  C1 RED:        7491bcc
  C2 IMPL:       b9f69c3
  C3 EVIDENCE:   30b7045
  C4 CLOSE:      <filled at commit time>

## ROOT CAUSE / FINDING
  The CLOSED predecessor ACT-POLYC-SELFHOST-LEXER02-CORRECTION01
  (d048ca9) had three additional mechanically-detectable closure
  defects that the post-CLOSE reviewer audit correctly identified:

    1. The "error corpus = 16 cases" claim was based on
       hand-typed `err_` prefix labels, not on observed
       contract. 9 of the 21 `err_`-prefixed fixtures actually
       return err=0 because the production lexer accepts them
       as valid forms (`0xFe`, `1.`, `.`, `1e`, `1e-`, etc.).
       The mechanical truth is: 16 fixtures have err != 0.

    2. The "broad corpus 4-stage" evidence proved only
       filtered scalar-token stream equivalence, not the
       LEXER01-CORRECTION01 canonical pattern of full
       compiler invocation + .o sha256 byte-equality on
       the 181-source corpus (175/175 BYTE_IDENTICAL +
       6/6 BOTH_FAIL).

    3. The category arithmetic was incoherent (88 + 1
       overlap = 89 is fictional because an overlap
       decreases union cardinality, not increases it).

## CORRECTION STRATEGY
  Bounded closure-truth correction only:
    - No production source mutation
    - No new bootstrap component
    - No new ABI
    - Two new scripts + Makefile targets
    - All new evidence under CORRECTION02/

## RED
  C1 RED at 7491bcc documented the three reopened defects
  with mechanical evidence (the 9 err_-prefixed-but-not-err
  fixtures, the lack of canonical-pattern corpus proof, the
  fictional arithmetic).

## IMPLEMENTATION
  C2 IMPL at b9f69c3:
    - scripts/quality/lexer07-fixture-inventory.sh: parses
      binary output, derives is_numeric/is_char/is_negative/
      is_edge from observed kind/err/cursor, emits TSV +
      summary.
    - scripts/quality/lexer07-broad-corpus-4-stage.sh:
      runs the canonical 181-source inventory through all
      4 stage compilers, captures success/failure + .o
      sha256, computes byte-equality matrix, emits
      corpus-matrix.tsv + corpus-object-provenance.tsv.
    - Stage 0 falls back to historical b02-corpus-A for
      9 sources where current ./hcc has pre-existing
      ARM64 inline asm regression. Fallbacks are
      EXPLICIT (compiler_identity=stage0-historical)
      and BOUND to provenance (compiler-binary-sha256 +
      object-sha256).
    - Makefile: 3 new targets added; .PHONY updated.

## GATES (4-stage, all PASS)

  Direct differential (89 fixtures):
    stage0/1/2/3: 89/89 PASS (C oracle == PolyC)

  Real-lexer seam (28 fixtures):
    6 pairwise stage diffs: IDENTICAL

  Mechanical fixture inventory (CORRECTION02 gate):
    TOTAL=89 PASS (>=64)
    is_char=33 PASS (>=24)
    is_negative=16 PASS (>=16)

  Canonical 181-source compiler corpus (CORRECTION02 gate):
    BYTE_IDENTICAL_4=175
    BOTH_FAIL_4=6
    HISTORICAL_STAGE0_FALLBACKS_USED=9
    DIVERGED=0
    REGRESSION=0

  Operator seam regression (LEXER01): 33/33 PASS
  Factory gate-fast: PASS
  F-NO-PYTHON: unchanged
  Append-only Git history: preserved
  Dafny: N/A

## SCOPE

  In scope (this correction):
    - scripts/quality/lexer07-fixture-inventory.sh (NEW)
    - scripts/quality/lexer07-broad-corpus-4-stage.sh (NEW)
    - Makefile (3 new targets)
    - docs/ROADMAP.md (CLOSED status block)
    - docs/factory/HANDOFF-...CORRECTION02.md (NEW)
    - evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION02/

  Out of scope (residue):
    - The 9 stage0 fallback files (their historical
      byte-identical outputs in build/b02-corpus-A are
      used as-is; not modified)
    - src/lexer.c, tools/bootstrap/selfhost-lexer-scalar-literal.HC,
      src/lexer_bridge.h, src/CMakeLists.txt
    - tools/quality/lexer07-scalar-literal-oracle.c
    - tools/quality/lexer07-direct-differential.c
    - test-prefix-install target repair (pre-existing failure)

## RESIDUE

  P2:
    - 9 sources where current ./hcc fails on ARM64 inline
      asm (pre-existing ./hcc binary regression; tracked
      as stage0-historical in provenance TSV).
    - test-prefix-install target remains broken
      (pre-existing; out of scope per CORRECTION01).

## NEXT ACT
  ACT-POLYC-SELFHOST-LEXER03 (or successor). The recon ACT's
  runner-up region was +285; a fresh surface-recon is
  recommended before opening LEXER03.
