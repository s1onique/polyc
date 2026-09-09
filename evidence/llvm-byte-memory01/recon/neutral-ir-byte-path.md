# R2 — Existing Neutral IR Byte Support

## IR type enum

`src/ir-types.h:170-187` defines `IrValueType`. The byte-relevant entries
are:

```c
IR_TYPE_I8,          /* 8-bit integer (char) */
IR_TYPE_I16,         /* 16-bit integer (short) */
IR_TYPE_I32,         /* 32-bit integer (int) */
IR_TYPE_I64,         /* 64-bit integer (long) */
```

There is **no** `IR_TYPE_U8` (no unsigned-distinct variant at IR layer).

## IR value representation

`src/ir-types.h:267-272` (`IrVar`):

```c
typedef struct IrVar {
    u32 id;
    u16 size;        /* byte size */
} IrVar;
```

**No signedness flag** at IR layer. The size carries the width (1 for I8).
Signedness is not a property of the SSA value; it is encoded by the
**extension opcode** at widening sites.

## IR_LOAD_DEREF / IR_STORE_DEREF

`src/ir.c:288-314` lists IR_LOAD_DEREF among the producers that may
SSA-substitute an instruction (used by the optimiser for SSA value
forwarding).

The neutral IR **does carry** `dst->type` (for load) or `r1->type` (for
store) as the access type. Verified by `--dump-ir`:

```text
load     %t5 i8 tmp, %t3 i8 tmp  ; line 5
```

The `i8` suffix on the load operand reflects `r1->type` (the address slot
type). The destination type would also be visible at the source line.

The IR_LOAD_DEREF arm in `src/llvm-backend.c:1744-1821` currently reads:

```c
if (ins->dst->type != IR_TYPE_I64) {
    /* rejected with LLVM_BACKEND_UNSUPPORTED_TYPE */
}
```

This is the **entry-point gate** for the byte load path. To support byte
loads, this gate must accept `IR_TYPE_I8` (additive extension).

The IR_STORE_DEREF arm at `src/llvm-backend.c:1822-1897` is symmetric:
the value-type gate currently requires `IR_TYPE_I64`.

## IR_LOAD / IR_STORE

These are scalar SSA-style loads/stores (mem2reg-optimised). The IR
LOAD/STORE arms in the dispatch are also `SHAPE_DEPENDENT`
(`src/llvm-backend-cap.c:50-51`). They handle the case where the IR has
been optimised to SSA form (no actual `alloca`/`load`/`store` emitted
to LLVM).

For BYTE-MEMORY01 purposes, the IR_LOAD_DEREF / IR_STORE_DEREF path is
the load-bearing one (this is the path that emits real `load i8` and
`store i8` instructions).

## Conversion opcodes

`src/ir-types.h:118-131`:

```c
IR_TRUNC,       /* Truncate (larger to smaller int) */
IR_ZEXT,        /* Zero extend (smaller to larger int) */
IR_SEXT,        /* Sign extend (smaller to larger int) */
...
```

All three are defined. The IR builder emits `IR_ZEXT` / `IR_SEXT` at
widening sites via `irWidenToTargetWidth` (`src/ir.c:218-232`) and emits
`IR_TRUNC` at narrowing sites via `irNarrowToTargetWidth`
(`src/ir.c:184-217`).

The LLVM backend's capability table currently has all three as
`LLVMBC_REJECTED` (`src/llvm-backend-cap.c:79-83`):

```c
{ IR_TRUNC, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "..." },
{ IR_ZEXT,  LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "..." },
{ IR_SEXT,  LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "..." },
```

## R2 questions answered

1. **Can neutral IR represent an 8-bit scalar?** YES. `IR_TYPE_I8` is a
   first-class value type; `irConvertType(AST_TYPE_CHAR)` returns it
   (`src/ir-types.c:320`).

2. **Can it represent pointer-to-byte as distinct language metadata, even
   though LLVM uses opaque ptr?** YES. The IR carries `IR_TYPE_PTR` as the
   pointer type; the pointee/access type is carried by `IR_LOAD_DEREF` /
   `IR_STORE_DEREF`'s `dst->type` / `r1->type`. This matches LLVM's
   opaque-pointer semantics where the type lives on the load/store
   instruction, not on the pointer.

3. **Does IR_LOAD_DEREF carry the access type?** YES. `dst->type`.

4. **Does IR_STORE_DEREF carry the stored/access type?** YES. `r1->type`.

5. **Does byte -> I64 already appear as an explicit IR conversion?** YES.
   `IR_ZEXT` (unsigned) and `IR_SEXT` (signed) are emitted by
   `irWidenToTargetWidth` at every widening site. Empirically confirmed
   via `--dump-ir`: a `U8` use emits `zext` and an `I8` use emits `sext`.

6. **Does I64 -> byte already appear as an explicit IR conversion?** YES.
   `IR_TRUNC` is emitted by `irNarrowToTargetWidth` at narrowing sites.

## Conclusion

`NEUTRAL_IR_BYTE_PATH = OK`. No neutral-IR change is required. The IR
already has:

* `IR_TYPE_I8` for 8-bit scalars
* `IR_LOAD_DEREF` / `IR_STORE_DEREF` with explicit access-type operands
* `IR_ZEXT` / `IR_SEXT` (with signedness authority from `AstType->issigned`)
* `IR_TRUNC` for narrowing

The LLVM backend simply does not yet admit `IR_TYPE_I8` as a value type,
nor does it lower `IR_ZEXT` / `IR_SEXT`. This is a backend-only gap.

`NEUTRAL_IR_CHANGE_REQUIRED = NO`.
