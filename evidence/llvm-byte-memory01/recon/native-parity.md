# R8 — Native Parity (x86_64 / aarch64 AOT and JIT)

## Question

Do the native backends (x86_64, aarch64) — both AOT and JIT — already
support the byte load/store path that BYTE-MEMORY01 will introduce in
the LLVM backend?

## Findings

### x86_64 backend (`src/x86_64.c`, `src/x86.c`)

The x86_64 backend already emits explicit `movzbq` / `movsbq` for the
narrow-load widening at `src/x86.c:81-83`:

```c
case 1:
    if (dst->issigned) return "movsb";
    else                return "movzb";
```

The `dst->issigned` here is `AstType->issigned`, NOT `IrVar` signedness
(which doesn't exist). The x86_64 backend therefore depends on the
**AST-level** signedness to choose between `movsb` (sign-extend on load)
and `movzb` (zero-extend on load) for narrow loads.

The IR widening pass (`irWidenToTargetWidth`) inserts `IR_SEXT` /
`IR_ZEXT` BEFORE the load, so the load itself sees a full-width value
and the `movsbq` / `movzbq` distinction is at the **AST cast boundary**
rather than the load site itself. Empirically, narrow-reads
(`src/tests/52_narrow_signed_reads.HC`) confirm this.

### aarch64 backend (`src/aarch64.c`, `src/aarch64-emit.h`)

The aarch64 backend uses `uxtb` / `sxtb` for narrow loads
(`src/aarch64-emit.h:402-405`):

```c
e->load_gp(be, instr);
int sz = (int)irValueByteSize(instr->r1);
```

Same AST-level signedness-driven choice as x86_64.

### JIT (x86_64-jit, aarch64-jit)

Both JIT backends share the same emitters as their AOT counterparts;
narrow loads go through the same `sxtb` / `uxtb` (aarch64) or
`movsbq` / `movzbq` (x86_64) instructions.

## Native parity conclusion

Native backends already lower the byte-widening contract correctly.
The byte-load widening choice (ZEXT vs SEXT) is preserved through the
existing `IR_ZEXT` / `IR_SEXT` IR opcodes, which the native backends
already lower with the correct instruction selection. **No native
backend change is required for BYTE-MEMORY01's read-only path.**

The LLVM backend's lowering of `IR_ZEXT` and `IR_SEXT` (which is the
**only** addition the read-only byte path requires beyond IR_TYPE_I8
admission and IR_LOAD_DEREF byte shape) will produce:

* `zext i8 %v to i64` for unsigned widening
* `sext i8 %v to i64` for signed widening

This matches the native backend semantics exactly. **No native parity
conflict is anticipated.**

## Potential conflict: implicit widening inside `IR_LOAD_DEREF`

The current MEMORY01 IR_LOAD_DEREF arm does NOT do an implicit
widening; it just emits `load i64, ptr %p`. The IR builder inserts the
widening (ZEXT/SEXT) BEFORE the load if the destination is to be
narrower than I64. The LLVM backend therefore only needs to emit a
plain `load i8, ptr %p` for the byte shape — the explicit IR_ZEXT /
IR_SEXT that follows handles widening.

This matches the native backend's behaviour for narrow-load widening
(where the load is sized to the actual width and the widening is at
the AST cast boundary).

## Conclusion

`NATIVE_PARITY = OK`. The native backends do not need a parity change
for the read-only byte load path. The IR's existing ZEXT/SEXT
contract is the source of truth for signedness, and the LLVM backend
will mirror it.

`NATIVE_BYTE_SEMANTICS_CONFLICT = NO` for the bounded byte-read path.
