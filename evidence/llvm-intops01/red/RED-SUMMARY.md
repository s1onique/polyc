# RED-SUMMARY — ACT-POLYC-LLVM-INTOPS01

## Outcome: HALT_RED_NOT_REPRODUCED (Outcome E per ACT §36)

The ACT premise has been invalidated by fresh recon.

The smallest credible B0 lexer/tokenizer can be expressed using **only**
scalar integer operations that are already SUPPORTED in the LLVM backend.
No new integer opcode requires a real RED against an LLVM capability seam.

### Decision matrix

| Row | B0 required? | LLVM ENTRY state | Decision | RED needed? |
|-----|--------------|------------------|----------|-------------|
| IADD        | yes | SUPPORTED       | ALREADY_SUPPORTED | no |
| ISUB        | yes | SUPPORTED       | ALREADY_SUPPORTED | no |
| IMUL        | yes | SUPPORTED       | ALREADY_SUPPORTED | no |
| ICMP        | yes | SUPPORTED       | ALREADY_SUPPORTED | no |
| BR/CMP_BR   | yes | SUPPORTED       | ALREADY_SUPPORTED | no |
| CALL/RET    | yes | SUPPORTED       | ALREADY_SUPPORTED | no |
| LOAD_DEREF  | yes | SUPPORTED       | ALREADY_SUPPORTED | no (MEMORY01) |
| STORE_DEREF | yes | SUPPORTED       | ALREADY_SUPPORTED | no (MEMORY01) |
| AND / OR / XOR / NOT | no  | REJECTED | DEFER | no |
| SHL / SHR / SAR      | no  | REJECTED | DEFER | no |
| IDIV / UDIV          | no  | REJECTED | DEFER | no |
| IREM / UREM          | no  | REJECTED | DEFER | no |
| TRUNC / ZEXT / SEXT  | no (BYTE-MEMORY01 territory) | REJECTED | DEFER | no |
| INEG                 | no  | REJECTED | DEFER | no |

### Mechanical confirmation

Two probe fixtures were written to mechanically confirm the recon:

- `evidence/llvm-intops01/recon/b0_probe.ll` — full single-token recognizer
- `evidence/llvm-intops01/recon/b0_digit_accum.ll` — decimal digit accumulation

Both compile to clean LLVM IR using only already-SUPPORTED ops.
Both pass `llvm-as` and `opt --passes=verify`.

### Why no principal RED was authored

Per ACT §8:

> Each RED must prove:
>     source syntax
>         ↓
>     expected neutral IR opcode
>         ↓
>     LLVM entry failure at the intended capability seam
>
> A failure earlier at an unrelated type/admission seam does not count
> as the opcode RED.

The recon produced ZERO rows with `decision = IMPLEMENT`. With no IMPLEMENT
rows, there are no opcodes to author REDs against. Per ACT §36 Outcome E:

> If fresh recon shows the ACT premise is stale:
>     HALT_RED_NOT_REPRODUCED
>     and advance to BYTE-MEMORY01 instead of manufacturing work.

This is the honest halt.

### What was NOT proven

This halt does NOT prove:
- That bitwise / shift / division / remainder / conversion ops are
  unnecessary for ALL future PolyC programs. They are unnecessary for
  the B0 mission only.
- That the LLVM backend's IR_REJECTED state for these opcodes is
  semantically correct. (They may need to remain rejected or be
  added later for unrelated programs.)
- That B0 is achievable. B0 also needs pointer-arithmetic indexing
  (`*(src + n)`) to walk the source buffer, which MEMORY01 currently
  REJECTS. That gap is BYTE-MEMORY01 / GEP01 territory, not INTOPS01.
