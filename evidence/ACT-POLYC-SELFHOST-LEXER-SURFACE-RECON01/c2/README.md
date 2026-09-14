ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01 — C2 — IMPL (region derivation)
========================================================================

This packet derives region candidates from the C1 graphs, applies
the frozen E1..E14 eligibility, the frozen region scoring formula,
and selects the rank-1 region.

Files in this packet:

  README.md
  region-construction-log.txt   (ACT §13: three deterministic passes)
  region-membership.tsv          (12 region candidates)
  lexer-region-inventory.tsv    (schema from §16; populated below)
  eligibility-matrix.tsv         (E1..E14 verdict per region)
  abi-sketches.tsv               (bounded ABI per region)
  oracle-feasibility.tsv         (direct oracle strategy per region)
  production-seam-feasibility.tsv
  corpus-region-map.tsv          (real corpus examples per region)
  dynamic-region-coverage.tsv    (DYNAMIC_COVERAGE = UNAVAILABLE_NONBLOCKING)
  legacy-candidate-mapping.tsv   (LEXER01 microscopic -> region mapping)
  region-scores.tsv              (frozen formula per region)
  ranking.txt                    (final rank order)
  sensitivity.txt                (margin classification)
  winner.txt                     (rank-1 detail)
  runner-ups.txt                 (why losers lost)
  projected-surface-delta.txt    (post-migration surface projections)
  c2-required-result.txt         (binding)

WINNER = R-F (scalar_literal_scanner)
FINAL_SCORE = +627
E1..E14 = PASS
MARGIN = 342 (ROBUST)
NEXT_ACT = ACT-POLYC-SELFHOST-LEXER02 (EXACTLY scalar_literal_scanner)
