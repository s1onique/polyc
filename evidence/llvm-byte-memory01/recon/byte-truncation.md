# R6 — I64-to-Byte Authority

## Question

Does B0 require byte stores (and therefore `IR_TRUNC` from I64 to byte)?

## B0 demand

See `evidence/llvm-byte-memory01/recon/b0-byte-demand.md`. The B0
fragment for this ACT reads bytes from the source buffer and writes
**scalar integer results** (the parsed integer accumulator) to the
caller's output slot. There is no requirement to write bytes back to
the source buffer or to any other byte-typed output.

## Conclusion

`I64_TO_BYTE = DEFER`. The B0 read-only byte path does not need
`IR_TRUNC` for byte narrowing. The existing narrowing path through
`irNarrowToTargetWidth` (`src/ir.c:184-217`) emits `IR_TRUNC` whenever
the IR builder determines the destination slot is narrower than the
source value, but B0 does not produce such a shape at the IR level for
the byte-output case.

`BYTE_STORE = DEFER`. The byte-store seam is also deferred because B0's
output is not a byte buffer.

## If byte store were required

The lowering would be:

```c
/* src/llvm-backend.c IR_STORE_DEREF arm, hypothetical extension */
if (ins->r1->type == IR_TYPE_I64) {
    /* neutral IR must have already emitted IR_TRUNC; reject otherwise */
    LLVMValueRef val = llLowerI64Value(lc, ins->r1);
    /* the LLVM store value must be i8; if the IR allowed I64 -> store i8
     * without an explicit IR_TRUNC, the LLVM IR would be ill-typed */
    ...
}
```

This is **explicitly not authorised by this ACT** (per §37 of the ACT
contract). If a future ACT needs it, that ACT must extend the cap-table
row for `IR_STORE_DEREF` to admit the byte shape AND lower `IR_TRUNC`
for the I64 -> byte narrowing case.

## HALT status

`BYTE_TRUNCATION_SEMANTICS_UNPROVEN = NOT_TRIGGERED` (the question does
not arise for the bounded B0 read-only path).

`BYTE_STORE_DEMAND = DEFER` per ACT §37.
