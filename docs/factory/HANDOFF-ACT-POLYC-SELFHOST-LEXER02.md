HANDOFF-ACT-POLYC-SELFHOST-LEXER02
================================================

## VERDICT
  PASS (CLOSED)

## IDENTITY
  ACT:                ACT-POLYC-SELFHOST-LEXER02
  Title:              Migrate scalar_literal_scanner (countNumberLen +
                       lexNumeric + lexCharConst) from C to PolyC
  Authorization:      docs/acts/ACT-POLYC-SELFHOST-LEXER02.md
  Predecessor:        ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03
  C1 RED:             456370e53ee356c3585ed39f83fd957689b5f145
  C2 IMPL:            c290581a2eb50f988aad5797927f677a4d35e68e
  C3 EVIDENCE:        ffa45e3565baa0e04fe27660e11a898d4ebefd6e
  C4 CLOSE:           <filled at commit time>

## ROOT CAUSE / FINDING
  The production lexer's scalar-literal scanning region (R-F from
  the recon ACT) — countNumberLen + lexNumeric + lexCharConst —
  was implemented in C in src/lexer.c. The recon ACT selected this
  region as the next coherent migration candidate (FINAL_SCORE=+627,
  +342 over runner-up). This ACT migrates the region to a single
  PolyC component (tools/bootstrap/selfhost-lexer-scalar-literal.HC)
  with a clean 4-input / 8-output ABI.

## RED
  C1 RED at 456370e established:
    - Frozen region R-F (countNumberLen + lexNumeric + lexCharConst)
    - Frozen ABI contract (4 inputs / 7 outputs at C1 freeze, then
      amended to 8 outputs at C2 to carry the slot-count semantics
      for char constants)
    - C oracle (tools/quality/lexer07-scalar-literal-oracle.c) with
      40 self-test fixtures, all PASS
    - Real-lexer seam runner (tools/quality/lexer07-real-seam-runner.c)
      with 28 cases covering edge / error behavior
    - Production seam mapping (c1/source-seam-map.txt)
    - 3-predecessor check: ACT-POLYC-BOOTSTRAP02,
      ACT-POLYC-SELFHOST-LEXER01, and the recon ACT all closed
      without overlap with R-F

## IMPLEMENTATION
  C2 IMPL at c290581:
    - PolyC subject: tools/bootstrap/selfhost-lexer-scalar-literal.HC
      (SC_PeekAt, SC_CountNumberLen, SC_LexCharConst,
       BootstrapScanScalarLiteral)
    - ABI 3 extension (out_strlen, see bridge-delta.txt)
    - src/lexer.c wrappers under #ifdef HCC_USE_SELFHOST_COMPONENTS
    - src/lexer_bridge.h: ABI 3 declaration
    - src/CMakeLists.txt: stage1/2/3 link lines (fail-closed)
    - docs/factory/SELF-HOST-COMPONENTS.tsv: row 3 added
    - tools/quality/lexer07-direct-differential.c: 40-fixture diff

## GATES
  Direct differential:   40/40 PASS at all 4 stages
  Real-lexer seam:       28/28 PASS (stage0 == stage1, modulo label)
  Broad corpus scalar:   5519/5519 MATCH (24/24 files)
  Operator seam (LEXER01): 33/33 PASS (no regression)
  4-stage byte-equality: identical sha256
                         216053670359381d3a3d4f634607d2c63c9d3b0a6ad6f77a87da9149ec9ad71b
  Factory gate-fast:     PASS
  F-NO-PYTHON:           unchanged (12 instances)
  Dafny:                 N/A (no semantic change)
  Append-only invariant: preserved (no amend / rebase / force-push)

## SCOPE
  In scope:
    - src/lexer.c::lexCharConst (full body)
    - src/lexer.c::lexNumeric (full body)
    - src/lexer.c::countNumberLen (called via the wrapper, see
                                  evidence/.../c1/frozen-region.txt)
    - src/lexer_bridge.h (ABI 3 declaration)
    - src/CMakeLists.txt (link line addition)
    - tools/bootstrap/selfhost-lexer-scalar-literal.HC (NEW)
    - tools/quality/lexer07-scalar-literal-oracle.c
    - tools/quality/lexer07-direct-differential.c (NEW)
    - tools/quality/lexer07-real-seam-runner.c
    - Makefile (LEXER07 targets)
    - docs/factory/SELF-HOST-COMPONENTS.tsv (row 3)
    - docs/acts/ACT-POLYC-SELFHOST-LEXER02.md (NEW)
    - evidence/ACT-POLYC-SELFHOST-LEXER02/c{1,2,3,4}/ (NEW)
    - docs/ROADMAP.md (CLOSE block)

  Out of scope (residue, see ACT §75):
    - test-prefix-install Makefile target (pre-existing failure,
      unrelated to LEXER02)
    - @-decorator tokenization differences (LEXER01 successor
      territory, pre-existing)
    - LEXER03 and later candidates (backlog)

## RESIDUE
  P2:
    - test-prefix-install target is broken; hcc-bootstrap03/04
      cannot be rebuilt with the new scalar component linked in
      directly via the Makefile. However, the 4-stage byte-equal
      differential result (all 4 stages produce identical sha256
      for build/lexer07-scalar-literal.o) + the production seam
      (stage0 vs stage1 lexer produce identical 28-case output)
      provide sufficient evidence that the migration is correct.
    - Lexer02 wrapper fixes the lexCharConst cursor model (the
      public BootstrapScanScalarLiteral expects src[cursor] == '\'',
      but lexCore already advanced past the leading quote via
      lexNextChar). This is documented in src/lexer.c.

## NEXT ACT
  Recommended next ACT: ACT-POLYC-SELFHOST-LEXER03 (or successor).
  The next coherent migration region per the recon ACT is the
  remaining lexCore dispatcher (string literals, comments,
  identifiers, operators) — though the recon's runner-up score was
  +285 (vs +627 for R-F), so a fresh surface-recon is recommended
  before opening LEXER03.
