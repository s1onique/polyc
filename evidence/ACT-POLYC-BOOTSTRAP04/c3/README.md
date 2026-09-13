# ACT-POLYC-BOOTSTRAP04 — C3 — EVIDENCE

This directory contains the C3 EVIDENCE packet for
`ACT-POLYC-BOOTSTRAP04` (B3 bootstrap stability).

C3 mechanically establishes:

1. Stage2↔stage3 generation provenance
2. Stage3 binding (`_BootstrapScanIdent` linked + called)
3. Direct semantic equivalence (15/15 component + 6/6 cursor + 6/6 Lexer seam)
4. Broad-corpus stage2↔stage3 equivalence (181/181 sources)
5. Error-corpus stage2↔stage3 equivalence (4/4 fixtures)
6. Stage3 self-source (stage3 compiles B1 source, byte-equal to stage2)
7. Two-build reproducibility (Build A == Build B)
8. B0/B1/B2 conservation (all gates re-run)
9. Factory gates (gate-fast, factory-v2-test, etc.)

Files:

- `fresh-tree.txt`              — C3 capture identity
- `stage-identities.txt`        — stage0..stage3 binaries, hashes, symbols
- `generation-chain.txt`        — the 3-generation diagram
- `artifact-provenance.txt`     — full S0/S1/S2 provenance witness
- `stage3-symbol-binding.txt`   — `_BootstrapScanIdent` in stage3
- `stage3-delegation-witness.txt` — `bl _BootstrapScanIdent` sites
- `component-stage2-stage3.txt` — direct 15/15 differential
- `production-lexer-stage2-stage3.txt` — 6/6 production Lexer seam
- `corpus-inventory.txt`        — 181-source corpus
- `corpus-matrix-stage2-stage3.tsv` — canonical stage2↔stage3 matrix
- `corpus-matrix-buildA.tsv`    — Build A matrix
- `corpus-matrix-buildB.tsv`    — Build B matrix
- `corpus-summary.txt`          — corpus summary
- `dollar-identifier-slice.txt` — `dir.HC` `$` slice
- `normal-source-slice.txt`     — ordinary library source
- `test-source-slice.txt`       — test source
- `error-corpus.tsv`            — 4-fixture error corpus
- `error-corpus-summary.txt`    — error summary
- `stage3-self-source.txt`      — stage3(B1 source) == stage2(B1 source)
- `fixed-point.txt`             — compact fixed-point witness
- `reproducibility.txt`         — Build A vs Build B
- `compiler-conservation.txt`   — B0/B1/B2 gates
- `factory-gates.txt`           — gate-fast etc.
- `patch-hygiene.txt`           — `git diff --check`
- `scope-audit.txt`             — file scope audit
- `c3-required-result.txt`      — binding C3 end block