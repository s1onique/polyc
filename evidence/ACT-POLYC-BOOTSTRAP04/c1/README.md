# ACT-POLYC-BOOTSTRAP04 — C1 — RED

This directory contains the C1 RED evidence for
`ACT-POLYC-BOOTSTRAP04` (B3 bootstrap stability).

C1 mechanically establishes:

1. B2 is GREEN (predecessor freeze).
2. stage2 exists and can compile the B1 source.
3. Canonical stage3 does NOT yet exist.
4. The build seam from B2 is mapped and the smallest B3
   extension is identified.
5. No production mutation occurred during C1.

The principal RED:

> The first self-host edge exists (B2 PASS), but there is
> no next-generation compiler consuming stage2's output and
> therefore no later-stage stability comparison.

Files:

- `predecessor-freeze.txt`     — B2 closure re-established
- `b2-governance-residue.txt`  — inherited non-blocking B2 review findings
- `stage-identity.txt`         — stage0/1/2 binaries, hashes, symbols
- `stage2-self-compile.txt`    — transient S2 object captured from stage2
- `stage3-absence.txt`         — canonical stage3 absent
- `build-seam-map.txt`         — B2 build seam + B3 extension
- `principal-red.txt`          — the RED statement
- `c1-required-result.txt`     — binding C1 end block