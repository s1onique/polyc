ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01 — HANDOFF
==================================================

VERDICT: PASS
ENTRY_IDENTITY: git rev-parse HEAD at C1 entry
ROOT CAUSE: All LEXER01 microscopic candidates scored negative under
            the function-level model. The recon ACT tests the
            hypothesis that larger coherent REGIONS may absorb
            ABI/state-boundary costs that individually migrate as
            negative scores.

WINNER: R-F (scalar_literal_scanner)
  Members: countNumberLen + lexNumeric + lexCharConst
  FINAL_SCORE: +627 (ROBUST margin 342 over runner-up R-E +285)
  E1..E14: PASS
  ABI: BOUNDED (4 inputs / 7 outputs)
  DIRECT_ORACLE: TEST_ONLY_PRODUCTION_EXTRACTION (feasible)
  PRODUCTION_SEAM: POSSIBLE
  FIXED_POINT_FEASIBILITY: PASS

RED:           c1/prior-negative-score-red.txt
               c1/lexer-function-inventory.tsv (60 functions)
               c1/lexer-callgraph.tsv (192 edges)
               c1/lexer-stategraph.tsv (122 edges)
               c1/lexer-field-ownership.tsv (22 fields)
               c1/state-coupling.tsv (15 op-pair scores; frozen formula)
               c1/external-boundaries.tsv (12 ops; frozen formula)
               c1/selfhost-surface-baseline.txt (post-LEXER01 surface)

IMPLEMENTATION: c2/region-construction-log.txt (3 deterministic passes)
               c2/region-membership.tsv (12 candidates)
               c2/lexer-region-inventory.tsv (full schema)
               c2/eligibility-matrix.tsv (E1..E14 verdict per region)
               c2/abi-sketches.tsv (bounded ABI per region)
               c2/oracle-feasibility.tsv
               c2/production-seam-feasibility.tsv
               c2/corpus-region-map.tsv (real corpus evidence)
               c2/legacy-candidate-mapping.tsv (LEXER01 microscopic -> region)
               c2/region-scores.tsv (frozen formula applied)
               c2/ranking.txt (final rank order)
               c2/winner.txt (rank-1 detail)
               c2/runner-ups.txt
               c2/sensitivity.txt (margin classification ROBUST)
               c2/projected-surface-delta.txt

GATES (C3 independent re-derivation):
               c3/fresh-region-derivation.txt
               c3/fresh-region-inventory.tsv (17 candidates; includes R-M..R-Q)
               c3/fresh-scores.tsv
               c3/ranking-reproduction.txt (C2 == C3 rank 1)
               c3/winner-recheck.txt
               c3/abi-recheck.txt
               c3/oracle-recheck.txt
               c3/production-seam-recheck.txt
               c3/current-selfhost-conservation.txt
               c3/corpus-conservation.txt
               c3/dafny.txt
               c3/no-python.txt
               c3/factory-gates.txt
               c3/scope-audit.txt
               c3/patch-hygiene.txt

GATES (C4 closure):
               c4/acceptance-matrix.txt (AC01..AC45 all PASS)
               c4/closure-summary.txt
               c4/final-region-map.txt
               c4/final-ranking.txt
               c4/final-winner.txt
               c4/selfhost-surface-state.txt
               c4/next-act-binding.txt
               c4/final-conservation.txt
               c4/factory-gates.txt
               c4/scope-audit.txt
               c4/patch-hygiene.txt
               c4/residue.txt
               c4/roadmap-transition.txt

SCOPE:
  docs/acts/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01.md  (NEW; ~1412 lines)
  docs/ROADMAP.md                                        (bounded status transition only)
  evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/...  (NEW)

  NO compiler source changes.
  NO new bootstrap component.
  NO new registry row.
  NO Python mutation.

RESIDUE: (none new; carried P2s documented in c4/residue.txt)

NEXT ACT: ACT-POLYC-SELFHOST-LEXER02
         LEXER02_SCOPE = EXACTLY (scalar_literal_scanner covering
                                 countNumberLen + lexNumeric + lexCharConst)
         (The recon ACT stops here per ACT §72 hard stop.
          LEXER02 must open with its own C1 RED phase.)
