# ACT-POLYC-SELFHOST-SURFACE01 — C1 — RED

This directory contains the **C1 RED evidence packet** for
`ACT-POLYC-SELFHOST-SURFACE01` (first-class self-host
component registry and deterministic build graph).

C1 mechanically establishes that:

1. The B3 predecessor is GREEN at entry.
2. The RED is not that the existing bootstrap is broken —
   it is that **no generic self-host component model
   exists**.
3. The bespoke B1/B2/B3 wiring is mechanically inventoried
   and classified.
4. The proposed registry schema and the registry-resolved
   build path are described concretely enough that C2 can
   implement them.
5. Negative controls (no `bootstrap05`, no
   `HCC_ENABLE_BOOTSTRAP05_*`) are binding for this ACT.

C1 performs **no production mutation**. C1 only adds:

- `docs/acts/ACT-POLYC-SELFHOST-SURFACE01.md`
  (authorization artifact)
- `docs/ROADMAP.md` (board transition at C1; the S0
  sub-board opening is recorded here so that future ACTs
  do not have to re-litigate the post-B3 milestone naming)
- this evidence directory.

No compiler semantic files modified.

Files in this directory:

- `b3-predecessor-freeze.txt`
- `bespoke-wiring-inventory.tsv`
- `build-graph-map.txt`
- `semantic-vs-generation-coupling.txt`
- `registry-red.txt`
- `principal-red.txt`
- `c1-required-result.txt`

Plus (this file).
