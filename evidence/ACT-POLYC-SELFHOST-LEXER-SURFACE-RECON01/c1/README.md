ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01 — C1 — RED/recon
========================================================

This packet performs the production-lexer ownership census required
by ACT §4-§11 and prepares the substrate for the C2 region
derivation.

Files in this packet:

  README.md                        (this file)
  entry-identity.txt               (F1: HEAD, branch, worktree state)
  predecessor-freeze.txt           (ACT §4: predecessor truth at C1 entry)
  prior-candidate-freeze.tsv       (LEXER01 microscopic candidates + scores)
  prior-negative-score-red.txt     (ACT §51 binding RED)

  lexer-function-inventory.tsv     (ACT §8: 60 functions, schema)
  lexer-callgraph.tsv              (ACT §9: 192 edges caller->callee)
  lexer-stategraph.tsv             (ACT §9: 122 edges function -> Lexer field R/W)
  lexer-field-ownership.tsv        (ACT §6: 22 Lexer fields mapped)
  semantic-classes.tsv             (ACT §7: 60 functions mapped to 17 classes)
  state-coupling.tsv               (ACT §10: 15 op-pair SHARED_STATE scores)
  external-boundaries.tsv          (ACT §11: 12 op-pair BOUNDARY_COST scores)

  selfhost-surface-baseline.txt    (ACT §39: post-LEXER01 surface metrics)
  identifier-fixed-point.txt       (re-hashed; I0==I1==I2==I3)
  operator-fixed-point.txt         (re-hashed; N0==N1==N2==N3)
  operator-seam-stage1.txt         (33/33 seam reproduced at stage1)

  bootstrap06-direct-differential.txt (47/47 reproduced)
  bootstrap06-stage1-build.txt     (stage1 build attempt log; ARM residue)
  selfhost-registry-baseline.txt   (selfhost-registry-validate log)
  factory-baseline.txt             (gate-fast output)
  no-python-baseline.txt           (F_NO_PYTHON = 12)
  dafny-baseline.txt               (Dafny 17/17)

  c1-required-result.txt           (binding)

C1 binding verdicts:

  ACT_PHASE                = RED
  PREDECESSOR_GREEN        = YES
  SELFHOST_LEXER_COMPONENTS= 2
  OLD_POSITIVE_CANDIDATES  = 0
  LEXER_FUNCTION_INVENTORY = COMPLETE (60 functions)
  LEXER_STATE_GRAPH        = COMPLETE (122 edges)
  REGION_MODEL             = ABSENT_AT_ENTRY
  PRODUCTION_MUTATION      = ZERO
  C1_TO_C2_GATE            = OPEN

NO HALT conditions triggered.
