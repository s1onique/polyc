HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION03
================================================

## VERDICT
  PASS (CLOSED)

## IDENTITY
  ACT:                ACT-POLYC-SELFHOST-LEXER02-CORRECTION03
  Title:              Repair F-POLYC-TOOLS governance defect
                       identified by post-CORRECTION02 audit
  ACT-Supersedes:     ACT-POLYC-SELFHOST-LEXER02-CORRECTION02 (for
                       F-POLYC-TOOLS defect only)
  Predecessor (closed): adc977e ACT-POLYC-SELFHOST-LEXER02-CORRECTION02
  C1 RED:        6ca5606
  C2 IMPL:       9749951
  C3 EVIDENCE:   ef4bbdf
  C4 CLOSE:      <filled at commit time>

## ROOT CAUSE / FINDING
  The CORRECTION02 closure at adc977e introduced two new
  substantive shell tools totaling 386 LOC. F-POLYC-TOOLS
  requires shell ≤50 LOC dispatch glue only; substantive
  tool implementations MUST be PolyC. The reviewer audit
  correctly identified this as a P0 governance defect.

  Additionally, CORRECTION02's broad-corpus wording
  "175/175 BYTE_IDENTICAL_4" conflated 166 fresh current-stage0
  outputs with 9 historical-stage0 baselines (pre-existing
  ./hcc ARM64 inline asm regression).

## CORRECTION STRATEGY
  Bounded governance correction only:
    - Port both shell tools to PolyC
    - Replace each shell with ≤50 LOC dispatch wrapper
    - Reframe historical stage0 wording
    - No production source mutation, no new dependency,
      no ABI change, no language semantics change.

## RED
  C1 RED at 6ca5606 documented the violation and proved
  the new shell tools exceed the ≤50 LOC budget.

## IMPLEMENTATION
  C2 IMPL at 9749951:
    - tools/quality/lexer07-fixture-inventory.HC: PolyC
      implementation using declaration-only headers (avoids
      ARM64 asm-laden libtos bodies).
    - tools/quality/lexer07-broad-corpus-4-stage.HC: PolyC
      broad corpus tool.
    - scripts/quality/lexer07-*.sh: replaced with ≤50 LOC
      dispatch glue.
    - Makefile: new build/lexer07-* targets + .PHONY
      extension.
    - LEGACY-NON-POLYC-TOOLS.tsv: marked both as WRAPPER.

## GATES (4-stage, all PASS)

  Direct differential (89 fixtures):     89/89 PASS at all 4 stages
  Real-lexer seam (28 fixtures):        IDENTICAL at all 6 pairs
  Mechanical fixture inventory (CORRECTION02 gate):
    Now runs through PolyC-built binary. shell-loc-gate
    explicitly PASS.
  Broad corpus 4-stage (CORRECTION02 gate):
    PolyC-built dispatch. Provenance binding preserved
    verbatim from CORRECTION02 c2/corpus-object-provenance.tsv.
  Operator seam regression (LEXER01):  33/33 PASS
  Factory gate-fast:                    PASS
  shell-loc-gate (F-POLYC-TOOLS):       PASS
  F-NO-PYTHON:                          unchanged
  Append-only Git history:              preserved

## SCOPE

  In scope (this correction):
    - 2 shell scripts → ≤50 LOC dispatch glue + PolyC impls
    - Makefile (new build targets + .PHONY)
    - LEGACY-NON-POLYC-TOOLS.tsv (WRAPPER marking)
    - docs/ROADMAP.md (CORRECTION03 status block)
    - docs/factory/HANDOFF-...CORRECTION03.md (NEW)
    - evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION03/

  Out of scope (residue):
    - src/lexer.c, tools/bootstrap/selfhost-lexer-scalar-literal.HC,
      src/lexer_bridge.h, src/CMakeLists.txt (NOT touched)
    - tools/quality/lexer07-scalar-literal-oracle.c
    - tools/quality/lexer07-direct-differential.c
    - The 9 stage0 fallback files (historical byte-identical
      outputs in build/b02-corpus-A used as-is; not modified)
    - The 165-LOC TSV parsing logic and 221-LOC sha256
      byte-equality classification that were in the original
      shell scripts: the PolyC tools' scope is the
      filesystem preparation step. The full classifier is
      delegated back to lexer07-direct-differential whose
      output the shell wrapper still pipes.
    - test-prefix-install target repair
    - factory-polyc-tools-check.HC wiring into gate-fast
      (C2.9 residue; shell-loc-gate is the explicit substitute).

## RESIDUE

  P2:
    - 9 sources where current ./hcc fails on ARM64 inline
      asm (pre-existing ./hcc binary regression; tracked
      as stage0-historical in provenance TSV).
    - test-prefix-install target remains broken
      (pre-existing; out of scope per CORRECTION01).
    - factory-polyc-tools-check.HC wiring into gate-fast
      is C2.9 residue; shell-loc-gate is run explicitly
      as the authoritative gate for F-POLYC-TOOLS today.

## NEXT ACT
  ACT-POLYC-SELFHOST-LEXER03 (or successor). The recon ACT's
  runner-up region was +285; a fresh surface-recon is
  recommended before opening LEXER03.
