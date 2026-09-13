# ACT-POLYC-BOOTSTRAP04 — C4 — CLOSE

This directory contains the C4 CLOSE evidence for
`ACT-POLYC-BOOTSTRAP04` (B3 bootstrap stability).

C4 performs **zero implementation**.

C4 freshly re-proves the entire B3 evidence chain from
the C4 candidate tree:

- stage2 produces S2
- stage3 consumes exact S2
- stage3 links B1
- stage3 calls B1
- stage2↔stage3 direct semantics
- stage2↔stage3 broad corpus
- stage2↔stage3 errors
- stage3 self-source
- S2 == S3 B1 object
- two-build reproducibility
- B0/B1/B2 conservation
- Factory gates
- scope freeze
- evidence hygiene

Files:

- `acceptance-matrix.txt`   — re-verified AC-C3-01..AC-C3-63
- `closure-summary.txt`     — canonical B3 closure block
- `final-generation-chain.txt`
- `final-provenance.txt`
- `final-stage-binding.txt`
- `final-direct-tests.txt`
- `final-lexer-stability.txt`
- `final-corpus.txt`
- `corpus-matrix.tsv`
- `final-error-corpus.txt`
- `error-corpus.tsv`
- `final-self-source.txt`
- `final-fixed-point.txt`
- `final-reproducibility.txt`
- `final-conservation.txt`
- `factory-gates.txt`
- `patch-hygiene.txt`
- `scope-audit.txt`
- `residue.txt`
- `roadmap-transition.txt`

Plus:

- `../HANDOFF.md` — human-readable summary (no verdict)
