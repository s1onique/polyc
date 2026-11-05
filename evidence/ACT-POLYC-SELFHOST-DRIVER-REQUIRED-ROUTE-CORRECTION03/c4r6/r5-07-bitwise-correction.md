# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03 -- C4 ROUND 6

## R5-07 -- THE BITWISE-AND DISPOSITION (FORWARD-ONLY CORRECTION)

    FINDING_ID   R5-07
    CLASS        P2
    DISPOSITION  THE PRIOR CHARACTERISATION WAS WRONG; THE OBSERVED VALUE
                 IS CORRECT. NO CODE CHANGE IS REQUIRED OR MADE.
    SUBJECT      the C4 ROUND 5 interim status, `P1` residue line, and the
                 matching line in the C4 ROUND 5 independent-review prompt

### THE PRIOR CHARACTERISATION

The C4 ROUND 5 interim status recorded, as a P1 residue:

> THE PRODUCTION COMPILER'S `&` OPERATOR DOES NOT BEHAVE AS A BITWISE AND
> ON A HEX LITERAL. `0x18EB1AFA & 0xF000` evaluates to `0x1000`.

The same sentence appears in the C4 ROUND 5 independent-review prompt, so
a reviewer who read the prompt was told that the production compiler
mis-evaluates a bitwise AND.

### THE OBSERVED VALUE IS CORRECT

The claim is a claim about ARITHMETIC, and arithmetic is decidable:

    0x18EB1AFA = 418061050
    0xF000     =      61440
    AND        =       4096 = 0x1000

The bits of `0x18EB1AFA` in the `0xF000` mask are exactly the one bit at
`0x1000`: the nibble at `0xA000` is `0xA` (binary `1010`), so the `0x1000`
bit is SET and the `0x2000` and `0x4000` and `0x8000` bits are CLEAR. The
mask `0xF000` selects exactly those four bits, so the result is `0x1000`.

The observed value is therefore THE CORRECT VALUE. The production
compiler's `&` operator did NOT mis-evaluate the expression.

### WHY THE PRIOR CHARACTERISATION WAS WRONG

The prior status read the observation `the result was 0x1000` as evidence
of an operator defect, WITHOUT checking the expected value. The
observation is consistent with BOTH hypotheses:

  * the compiler computes the bitwise AND correctly and the expected
    value happens to be `0x1000`; or
  * the compiler computes something else that also happens to be `0x1000`.

Only the first hypothesis survives an arithmetic check. The prior status
confused "the observed value is `0x1000`" with "the observed value is
WRONG", and the second reading requires the value to be wrong, which it
is not.

### WHAT IS DISPOSED

The P1 residue line is DISPOSED AS INCORRECT. It is NOT carried forward
as a defect in the production compiler's `&` operator, and no audit of
the `&` operator's semantics is authorised or performed by this ACT.

The DEFENSIVE PRACTICE that the shared contract already follows is NOT
reversed and is NOT a bug: `ContractWordAt` reads its fields
arithmetically rather than with `&`. That is a deliberate choice, not a
workaround for a defect, and this ACT does not change it.

### THE FORWARD-ONLY RULE

This file is a NEW artefact under `c4r6/`. It does NOT edit, append to,
or supersede the C4 ROUND 5 interim status or the C4 ROUND 5
independent-review prompt. Per the repository's F14 rule, a historical
document is historical evidence: the C4 ROUND 5 characterisation remains
in the record as what it said at the time, and this file states what is
true now.

### THE REPRODUCING COMMAND

    printf '0x18EB1AFA = %d (0x%X)\n0xF000 = %d (0x%X)\nAND = %d (0x%X)\n' \
      0x18EB1AFA 0x18EB1AFA 0xF000 0xF000 \
      $((0x18EB1AFA & 0xF000)) $((0x18EB1AFA & 0xF000))

    0x18EB1AFA = 418061050 (0x18EB1AFA)
    0xF000 = 61440 (0xF000)
    AND = 4096 (0x1000)
