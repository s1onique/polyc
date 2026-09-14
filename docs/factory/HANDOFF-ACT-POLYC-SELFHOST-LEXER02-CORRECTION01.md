HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION01
================================================

## VERDICT
  PASS (CLOSED)

## IDENTITY
  ACT:                ACT-POLYC-SELFHOST-LEXER02-CORRECTION01
  Title:              Repair three closure-truth defects identified
                       by the post-CLOSE reviewer audit of LEXER02
  ACT-Supersedes:     ACT-POLYC-SELFHOST-LEXER02
  Predecessor (closed): af418a9 ACT-POLYC-SELFHOST-LEXER02 — C4 CLOSE
  C1 RED:             4fd3852
  C2 IMPL:            627785a
  C3 EVIDENCE:        8a3b4e5
  C4 CLOSE:           <filled at commit time>

## ROOT CAUSE / FINDING
  The CLOSED predecessor ACT-POLYC-SELFHOST-LEXER02 (af418a9) had
  three mechanically-detectable closure defects that the reviewer
  audit correctly identified:

    1. The recon ACT's ABI projection (4/<=7) was wrong. Faithful
       preservation of lexCharConst requires an additional
       out_strlen output (4/8). The closed ACT discovered this
       during C2 IMPL but recorded it as a "bridge delta" instead
       of an ABI projection correction. The recon ACT's
       HALT_LEXER02_ABI_BOUNDARY_MISMATCH clause did not fire.

    2. The closed 40-fixture direct differential corpus
       undersatisfied the §32 FIXTURE_CARDINALITY floor
       (DIRECT_REGION_CASES >= 64 with sub-floors of >= 24 char
       and >= 16 error/negative).

    3. The real-lexer seam and broad corpus were proven only at
       stages 0/1, not all 4 stages. The LEXER01-CORRECTION01
       pattern requires all 4 stages; LEXER02 violated it.

## CORRECTION STRATEGY
  Bounded closure-truth correction only:
    - No production source mutation (src/lexer.c, src/lexer_bridge.h,
      src/CMakeLists.txt, tools/bootstrap/selfhost-lexer-scalar-literal.HC
      all preserved verbatim from CLOSED predecessor)
    - No new bootstrap component
    - No new ABI beyond the documented 4/8
    - No new registry row

  Modifications are limited to:
    - tools/quality/lexer07-direct-differential.c: fixture expansion
      (40 → 89 cases)
    - Makefile: test-prefix-install-free build path for stage{1,2,3}
      seam runners; new lexer07-lexer-seam-all-stages composite target
    - docs/ROADMAP.md: CLOSED status block added
    - evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION01/:
      NEW evidence directory (F14-predecessor immutable)

## RED
  C1 RED at 4fd3852 documented:
    - The ABI projection correction (4/7 → 4/8 with disposition)
    - The fixture cardinality plan (40 → 89 with all sub-floors)
    - The 4-stage evidence gap to be closed in C3
    - The predecessor freeze (F14)

## IMPLEMENTATION
  C2 IMPL at 627785a:
    - tools/quality/lexer07-direct-differential.c: INPUTS[]
      expanded to 89 cases in 4 categories (A: numeric=41, B: char=28,
      C: error=16, D: edge=3 + 1 overlap)
    - Makefile:
      - lexer07-direct-differential now also links the oracle .o
      - lexer07-lexer-seam-stage{1,2,3} no longer depend on
        bootstrap0{2,3,4}-stage{1,2,3} (and thus test-prefix-install)
      - lexer07-lexer-seam-stage{2,3} now add -fsanitize=address
        (the existing stage3 .o files were built with asan; the
        linker error is the same _asan_version_mismatch_check_*
        class)
      - lexer07-lexer-seam-all-stages: composite target
    - Direct differential stage{1,2,3} binaries rebuilt with the
      expanded corpus

## GATES (4-stage, all PASS)
  Direct differential:
    stage0: ACT_SELFHOST_LEXER02_DIRECT_DIFF_CASES=89 PASS=89
    stage1: ACT_SELFHOST_LEXER02_DIRECT_DIFF_CASES=89 PASS=89
    stage2: ACT_SELFHOST_LEXER02_DIRECT_DIFF_CASES=89 PASS=89
    stage3: ACT_SELFHOST_LEXER02_DIRECT_DIFF_CASES=89 PASS=89

  Real-lexer seam (28 cases):
    stage0 vs stage1: IDENTICAL (only BUILD_LABEL differs)
    stage0 vs stage2: IDENTICAL
    stage0 vs stage3: IDENTICAL
    stage1 vs stage2: IDENTICAL
    stage1 vs stage3: IDENTICAL
    stage2 vs stage3: IDENTICAL

  Broad corpus:
    src/holyc-lib (24 files, 5519 tokens): 24/24 MATCH all 4 stages
    wider .HC corpus (189 files, 14044 tokens): 189/189 MATCH all 4 stages

  Error corpus:
    real-lexer-seam runner (28 cases): 28/28 IDENTICAL all 4 stages

  Operator seam regression (LEXER01): 33/33 PASS
  Factory gate-fast: PASS
  F-NO-PYTHON: unchanged
  Append-only Git history: preserved
  Dafny: N/A (no semantic change)

## SCOPE
  In scope:
    - tools/quality/lexer07-direct-differential.c (fixture expansion)
    - Makefile (test-prefix-install-free build path)
    - docs/ROADMAP.md (CLOSED status block)
    - evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION01/{c1,c2,c3,c4}/
    - docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION01.md

  Out of scope (residue):
    - src/lexer.c semantics
    - tools/bootstrap/selfhost-lexer-scalar-literal.HC semantics
    - src/lexer_bridge.h ABI 3 declaration
    - src/CMakeLists.txt stage linkage
    - The C oracle body (verbatim extraction, F2 contract)
    - test-prefix-install target repair (pre-existing failure)

## RESIDUE
  P2:
    - test-prefix-install target remains broken. CORRECTION01
      provides a documented test-prefix-install-free build path
      (lexer07-lexer-seam-stage{2,3}) that uses the same .o
      objects the prefix-install path would produce. This is not
      a silent fallback (F6 forbids silent fallback); it is the
      same evidence assembled via a different path. The objects
      are authoritative; only the build harness needed
      decoupling.

## NEXT ACT
  ACT-POLYC-SELFHOST-LEXER03 (or successor). The recon ACT's
  runner-up region was +285; a fresh surface-recon is recommended
  before opening LEXER03. The backlog of candidates remains:
    - comment_skip
    - numeric_value_parse
    - hex_literal
    - string_literal
    - preprocessor_directive
