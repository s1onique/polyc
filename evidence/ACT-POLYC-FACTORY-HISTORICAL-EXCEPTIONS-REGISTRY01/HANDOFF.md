# HANDOFF — ACT-POLYC-FACTORY-HISTORICAL-EXCEPTIONS-REGISTRY01

## VERDICT

PASS_WITH_HYGIENE_RESIDUE

## IDENTITY

- ACT: `ACT-POLYC-FACTORY-HISTORICAL-EXCEPTIONS-REGISTRY01`
- Branch: `main`
- ENTRY: `14519ecf41ab70ef1efca9ebe07d64ace7d08a4b` (C1 RED)
- C1 RED: `14519ecf`
- C2 IMPL: `0429937b`
- C3 EVID: `c2a0b818`
- C4 CLOSE: this commit

## DEFECTS ADDRESSED

- D-1 (P0): `correction04/historical-cardinality-exceptions.txt` no longer mutated; bit-identically restored to its pre-BOOTSTRAP state. Migration to canonical TSV.
- D-2 (P1): EXCEPTION 5 wording corrected from "reclassified" (mechanically false) to "annotation added; commit body unchanged" (mechanically accurate).
- D-3 (P1): Canonical TSV registry established at `docs/factory/HISTORICAL-CARDINALITY-EXCEPTIONS.tsv`, outside any `evidence/ACT-*/` tree.

## KEY FILES

- New: `docs/factory/HISTORICAL-CARDINALITY-EXCEPTIONS.tsv` — 5 EXCEPTION rows, append-only
- Modified: `docs/factory/DOCTRINE.md` — §24.1 Truth hierarchy, §24.2 Registry location, §24.3 Notes don't reclassify
- Modified: `evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction04/historical-cardinality-exceptions.txt` — bit-identically restored to SHA `1f6e5ded` (pre-BOOTSTRAP)

## ACCEPTANCE GATES

All 10 gates (AG1..AG10) verified PASS — see `c3/gate-matrix.txt`.

## NEXT ACT

`ACT-POLYC-BOOTSTRAP02` (B1 partial self-host). B0 substrate is GREEN_WITH_CLOSURE_CORRECTION; no further BOOTSTRAP corrections required.
