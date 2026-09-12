# R4: R1-R7 test matrix preview

The new verifier
`scripts/quality/factory-halt-classification-test.sh`
will exercise the following matrix against synthetic
commit-message fixtures. Each fixture is a complete
commit-message subject + body + trailers block. The
verifier inspects only trailer text. It MUST NOT infer
blocking from the literal word `HALT`.

| Fixture | ACT-Verdict | HALT_CLASS    | BLOCKS_NEXT | Expected |
|---------|-------------|---------------|-------------|----------|
| R1      | HALT_X      | GOVERNANCE    | NO          | PASS     |
| R2      | HALT_X      | PRODUCTION    | YES         | PASS     |
| R3      | HALT_X      | (absent)      | NO          | FAIL     |
| R4      | HALT_X      | GOVERNANCE    | (absent)    | FAIL     |
| R5      | PASS        | (absent)      | YES         | FAIL     |
| R6      | HALT_X      | GOVERNANCE    | YES         | FAIL     |
| R7      | HALT_X      | PRODUCTION    | NO          | FAIL     |

The matrix matches the user's specification verbatim:

```
R1 ACT-Corrected-Verdict=HALT_AC07_NOT_SATISFIED
   HALT_CLASS=GOVERNANCE
   BLOCKS_NEXT=NO
   => VALID
R2 HALT_FOO
   HALT_CLASS=PRODUCTION
   BLOCKS_NEXT=YES
   => VALID
R3 HALT_FOO affecting roadmap, no HALT_CLASS
   => verifier FAIL
R4 HALT_FOO affecting roadmap, no BLOCKS_NEXT
   => verifier FAIL
R5 PASS + BLOCKS_NEXT=YES
   => verifier FAIL / contradictory metadata
R6 GOVERNANCE + BLOCKS_NEXT=YES
   => allowed only with explicit mechanically-bound
      dependency evidence; otherwise FAIL
R7 PRODUCTION + BLOCKS_NEXT=NO
   => FAIL unless successor-dependency exemption is
      explicitly mechanically demonstrated
```

The verifier does NOT in v1 attempt to interpret
"explicit mechanically-bound dependency evidence" --
per the user's note: "I would keep the first
implementation even simpler than R6/R7 if necessary:
require the fields and validate the enum/boolean;
don't build an ontology engine in v1." So R6 and R7
are mechanically: HALT_CLASS=GOVERNANCE requires
BLOCKS_NEXT=NO; HALT_CLASS=PRODUCTION requires
BLOCKS_NEXT=YES. The DEPENDENCY class is the only one
where the verifier accepts either value in v1.

## Why the verifier must not infer blocking from `HALT`

The Factory v2 verdict grammar already accepts any
`HALT_<token>` form. A naive downstream reader will
therefore treat any `HALT_*` as "stop everything". The
new doctrine F-MECHANICAL-BLOCKING explicitly forbids
that behavior:

  - `HALT_*` is a verdict grammar symbol; it carries
    no blocking intent by itself.
  - `HALT_CLASS` declares the class of halt.
  - `BLOCKS_NEXT` declares whether the halt is
    blocking at the board-transition level.

The verifier enforces this separation mechanically
because the closure-status oracle
(`factory-closure-status-check.sh`) currently does not
distinguish a `HALT_AC07_NOT_SATISFIED` (whose only
production defect is the closure contract itself, not
the harness) from a `HALT_PRODUCTION_REGRESSION`
(which actually has a failing production gate).

This is the failure mode this ACT exists to repair.
