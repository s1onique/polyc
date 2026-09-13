ACT-POLYC-SELFHOST-LEXER01 — C1 — RED/RECON
============================================

This packet performs the production-lexer ownership census
required by ACT §4 and applies the frozen eligibility and
ranking formulas (ACT §6, §8) to mechanically select exactly
one rank-1 host-C lexer slice for migration in C2.

Files in this packet:

  README.md
  entry-identity.txt
  predecessor-freeze.txt

  lexer-function-map.tsv          (50 functions in src/lexer.c)
  lexer-ownership-map.tsv         (22 ownership slices)
  lexer-candidate-inventory.tsv   (8 candidates with full schema)
  candidate-ranking.txt           (formula + tie-break + winner)
  winner.txt                      (rank-1 detail)

  selfhost-surface-baseline.txt   (counts before this ACT)

  winner-source-seam.txt          (32 distinct token kinds)
  winner-state-contract.txt       (cursor / EOF / error semantics)
  winner-oracle.tsv               (47-fixture C reference, all PASS)
  winner-production-seam.tsv      (real Lexer state pre/post)

  winner-abi-contract.txt         (frozen ABI for the winner)
  winner-abi-witness.txt          (stage0 hcc ABI probe result)

  generation-corpus-baseline.tsv  (175 sources x 3 stages hashes)
  generation-corpus-summary.txt

  error-corpus-baseline.tsv       (4 fixtures, stages 2..3)
  error-corpus-summary.txt

  no-python-pause-baseline.txt    (F_NO_PYTHON = 12)
  formal-dafny-baseline.txt       (17 verified, 0 errors)

  c1-required-result.txt

C1 binding verdicts:

  WINNER = operator_punctuation_recognizer
  WINNER_RANK = 1
  WINNER_FINAL_SCORE = 952
  WINNER_ELIGIBLE = YES
  WINNER_DIRECT_ORACLE = PASS (47/47)
  WINNER_PRODUCTION_SEAM = FROZEN
  WINNER_ABI = PROVEN

  GENERATION_BASELINE = PASS
  ERROR_BASELINE = PASS

  PRODUCTION_MUTATION = ZERO
  C1_TO_C2_GATE = OPEN
