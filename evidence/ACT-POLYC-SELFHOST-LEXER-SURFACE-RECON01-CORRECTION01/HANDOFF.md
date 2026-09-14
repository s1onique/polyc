# HANDOFF -- ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01

Factory-Version: 2

## Result

The bounded governance-correction ACT closed three mechanical
closure defects in ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01
(CLOSED at 7adb9e8) without mutating the closed predecessor
evidence tree (F14 honored).

The engineering result is preserved verbatim:
  WINNER = R-F (scalar_literal_scanner)
  WINNER FINAL_SCORE = +627
  WINNER MARGIN = 342 (ROBUST)
  WINNER E1..E14 = PASS
  WINNER ABI = BOUNDED (4 in / 7 out)
  WINNER ORACLE = feasible
  WINNER PRODUCTION_SEAM = POSSIBLE

Closure verdict is authoritative in the `ACT-Verdict`
trailer of the ACT's CLOSE commit.

## What changed

- docs/acts/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01.md (NEW)
- evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c1/defect-summary.txt (NEW)
- evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c2/ac40-patch-hygiene-corrected.txt (NEW)
- evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c2/ac40-transform.tsv (NEW)
- evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c2/winner-invariance.tsv (NEW)
- evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c2/ranking-repaired.txt (NEW)
- evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c2/conservation-language-repaired.txt (NEW)
- evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c3/independent-re-derivation.txt (NEW)
- evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c4/ (NEW; 10 files)
- docs/ROADMAP.md (bounded CORRECTION01 status block added)

## Evidence

- C1 RED: c1/defect-summary.txt (3 defects enumerated)
- C2 IMPL: c2/ forward-fix ledger (5 files)
- C3 EVIDENCE: c3/independent-re-derivation.txt (V-1..V-7)
- C4 CLOSE: c4/ acceptance matrix + closure summary + forward-fix summary
- gates: gate-fast PASS, Dafny 17/17 PASS, F_NO_PYTHON=12 (unchanged)

## Production delta

- NO compiler source changes (src/** unchanged)
- NO parser/AST/IR/backend/runtime/llvm/formal/libtos mutation
- NO new registry row
- NO new bootstrap component
- NO Python mutation (POLYC_TOOLS_TRACKED_PYTHON=12 unchanged)
- NO mutation of closed predecessor evidence tree (F14 honored)

## Residue

- P2: ARM libtos/strings.HC assembly residue blocks stage1/2/3 builds
      on Apple Silicon (inherited from LEXER01; root cause of the
      BROAD_CORPUS_CURRENT_EXECUTION=ENVIRONMENTALLY_UNAVAILABLE
      disposition).
- P2: Wrapper synthetic l->ptr advance unification residue (LEXER01).
- P2: Wrapper strlen(start) buffer-bound tightening residue (LEXER01).

## Recommended next ACT

ACT-POLYC-SELFHOST-LEXER02
LEXER02_SCOPE = EXACTLY (scalar_literal_scanner covering
                        countNumberLen + lexNumeric + lexCharConst)

The recon ACT result is bound; the correction ACT does not begin
migration. LEXER02 must open with its own C1 RED phase against
the frozen subject.
