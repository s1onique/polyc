# CORRECTION01 C0 DEFECT DECOMPOSITION (frozen)

This file preserves the three binding-predicate failures that
predecessor DELEGATE01 handed off to CORRECTION01. The reviewer's
verdict was:

```text
EFFECTIVE_VERDICT = HALT_MULTIPLE_BINDING_PREDICATES
```

The production migration is acknowledged ENGINEERING_TRUE_GREEN
and is preserved intact.

## P0-1 / AC13 FAIL -- Dedicated macro vs C1 frozen seam

* C1 froze: `D-C = HCC_USE_SELFHOST_COMPONENTS`, `NO_NEW_MACRO=YES`.
* C2 implemented: `HCC_USE_SELFHOST_PARSER_PADDING` (dedicated seam).
* Reviewer: AC13 mechanically FAIL (C1 design violated).
* CORRECTION01 remediation: JOB 1 prospectively authorizes the
  dedicated seam. NO production source mutation. AC13 regrades
  to PASS under the CORRECTION01-authorized design.

## P0-2 / AC20 + AC32 + AC33 NOT_PROVEN -- G2/G3 placeholder text

* C3 generation-provenance TSV: G2/G3 rows contain placeholder text
  ("(distinct from G1 because...)").
* C3 production-semantic-verify.txt: actual build/run transcripts
  only for G0 and G1.
* Reviewer: G2/G3 independent production execution was asserted in
  prose, not mechanically recorded.
* CORRECTION01 remediation: JOB 2 actually produces G2 and G3
  production artifacts independently, freezing real SHA-256
  values for compiler, subject, production binary, and output.

## P0-3 / external terminality FAIL -- DELEGATE01 trailer geometry

* FACTORY_V2_RANGE_CHECK FAIL on the DELEGATE01 C0..C3 range.
* Reviewer: structurally impossible to repair ancestor commit
  messages from a child commit (per Git semantics).
* CORRECTION01 remediation: JOB 3 acknowledges
  `DELEGATE01_HISTORICAL_TRAILER_GEOMETRY = IMMUTABLE_FAIL_ACK`
  and demonstrates forward-only closure geometry on CORRECTION01's
  own C0..C4 range.

## Reviewer-disposition pattern

Per the reviewer's prescribed pattern, this CORRECTION01 evidence
file records `PREDECESSOR_EFFECTIVE_DISPOSITION`, NOT a back-edit
to the DELEGATE01 HANDOFF. The DELEGATE01 HANDOFF remains in its
closed state.
