# ACT-POLYC-BOOTSTRAP01 — C1 RED Evidence Packet

This directory holds the C1 RED evidence pack for
`ACT-POLYC-BOOTSTRAP01` (B0 compiler-shaped bootstrap).

C1 obligation, per the ACT and the BOOTSTRAP-RECON01
correction chain, is **successor dependency determination
first**, plus recon artifacts that bind the frozen B0
contract to mechanically proven substrate ACTs.

C1 must run BEFORE any production mutation. The natural
RED for an implementation ACT of this shape is *not* a
compiler defect; it is the **mechanical proof that B0 can
be implemented** without expanding scope. A B0 that
cannot be implemented (HALT_*) is the legitimate C1
RED-equivalent outcome. A B0 that compiles, links,
executes, and matches the C reference oracle is the
authoritative C2/C3 GREEN.

## Files

| File                              | Purpose                                              |
| --------------------------------- | ---------------------------------------------------- |
| `successor-dependency.txt`        | The required dependency decision matrix.             |
| `b0-capability-map.txt`           | B0 source construct → proven substrate ACT.          |
| `allocation-decision.txt`         | `B0_ALLOCATION = NOT_REQUIRED` decision.             |
| `lexical-contract.txt`            | Frozen token-kind enum, status codes, API shape.     |
| `fixture-matrix.txt`              | T01..T14 inputs and required semantic points.        |
| `oracle-baseline.txt`             | Per-fixture expected C oracle output.                |
| `c1-required-result.txt`          | Required-result block for C1 closure.                |
| `bootstrap01-lexer-oracle.c`      | Independent reference lexer (in C).                  |
| `bootstrap01-fixtures.tsv`        | Machine-readable T01..T14 + NC6..NC8 fixtures.       |

## Outcome

Outcome A (proceed to B0 implementation) is established.

B0 does NOT require the broken GEP01 harness
infrastructure. B0 uses only the byte/pointer/scalar
substrate proven by `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02`
and `ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01`. The GEP01 D1/D2
failures remain `NON_BLOCKING_GOVERNANCE_RESIDUE` for B0.
