# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02 — C1 RED — README

This packet records the bounded defects identified
in the **re-review** of ACT-POLYC-BOOTSTRAP02-C2-
CORRECTION01 and proposes the bounded forward
correction.

See:

* `defect-pillar-b-over-claim.txt`
* `defect-stale-section-e.txt`
* `corrected-pillar-b-wording.txt`
* `corrected-section-e-wording.txt`
* `required-result.txt`

The correction ACT is bounded to:

1. Adding a real-`Lexer`-seam differential harness
   that executes the production `lexIdentifier` on
   the production `Lexer` struct (full dispatcher
   state, EOF/pushback visibility).
2. Reclassifying the stale Section E predicates in
   `c2/required-result.txt` so they no longer falsely
   claim cursor equivalence from pillar A.
3. Relabelling the existing pillar-B harness
   (component-level cursor model) to what it actually
   proves.

No production source mutation. No B1/B0 component
mutation. No build-system behavioural change.

ACT-POLYC-BOOTSTRAP02 C3 EVIDENCE remains locked until
this correction ACT closes.
