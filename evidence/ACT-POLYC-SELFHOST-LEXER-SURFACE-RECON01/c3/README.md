ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01 — C3 — independent verification
========================================================================

C3 changes no design inputs. It re-derives function inventory,
region membership, eligibility, and scores from the committed
C1 graphs (lexer-callgraph.tsv, lexer-stategraph.tsv,
state-coupling.tsv, external-boundaries.tsv) using the committed
rules.

The goal is to prove C2 ranking == C3 ranking, demonstrating
that the winner was not manually selected.

Files in this packet:
  README.md
  fresh-region-derivation.txt
  fresh-region-inventory.tsv
  fresh-scores.tsv
  ranking-reproduction.txt
  winner-recheck.txt
  abi-recheck.txt
  oracle-recheck.txt
  production-seam-recheck.txt
  current-selfhost-conservation.txt
  corpus-conservation.txt
  dafny.txt
  no-python.txt
  factory-gates.txt
  scope-audit.txt
  patch-hygiene.txt
  c3-required-result.txt
