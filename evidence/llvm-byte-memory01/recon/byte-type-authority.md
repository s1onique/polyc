# R1 — Byte Type Authority in PolyC

## Source-level type table (canonical)

Per `src/cctrl.c:96-115` (the `built_in_types[]` table) and `src/lexer.c:109-114`:

| Lexeme | AST kind     | Size | issigned |
|--------|--------------|------|----------|
| `U0`   | AST_TYPE_VOID| 0    | 0        |
| `Bool` | AST_TYPE_CHAR| 1    | 1        |
| `I8`   | AST_TYPE_CHAR| 1    | **1** (signed)    |
| `U8`   | AST_TYPE_CHAR| 1    | **0** (unsigned)  |
| `I16`  | AST_TYPE_INT | 2    | 1        |
| `U16`  | AST_TYPE_INT | 2    | 0        |
| `I32`  | AST_TYPE_INT | 4    | 1        |
| `U32`  | AST_TYPE_INT | 4    | 0        |
| `I64`  | AST_TYPE_INT | 8    | 1        |
| `U64`  | AST_TYPE_INT | 8    | 0        |
| `F64`  | AST_TYPE_FLOAT| 8   | 0        |
| `F32`  | AST_TYPE_FLOAT| 4   | 0        |

`issigned` is preserved on `AstType` (`src/ast.h:172`).

## IR-level mapping

`src/ir-types.c:305-341` `irConvertType()`:

```c
case AST_TYPE_CHAR:    return IR_TYPE_I8;
case AST_TYPE_INT: {
    switch (type->size) {
        case 1: return IR_TYPE_I8;
        ...
    }
}
```

**Critical fact (F13 evidence-over-prose):** `irConvertType()` discards `issigned`. Both `I8` (signed) and `U8` (unsigned) become `IR_TYPE_I8`. The neutral IR does **not** have an `IR_TYPE_U8` distinction; signedness of the source byte is encoded by the **choice of extension opcode** (`IR_ZEXT` vs `IR_SEXT`) at every widening site.

## Where signedness is encoded in the IR

`src/ir.c:218-232` (`irWidenToTargetWidth`):

```c
int sext = src_ty && src_ty->issigned;
IrOp ext = sext ? IR_SEXT : IR_ZEXT;
```

The IR builder emits `IR_SEXT` for signed source types and `IR_ZEXT` for unsigned source types at every widening site.

**Empirical confirmation via `--dump-ir`** (`HCC_INSTALL_DIR=/tmp/polyc-install ./hcc --dump-ir`):

For `src/tests/ir-boundary03-correction02/w_i8_id_direct.HC`:

```text
i8 Id(%p1 i8 param) {
    ...
    sext     %t4 i64 tmp, %l2 i8 local  ; line 1
    ...
}
```

For `src/tests/ir-boundary03-correction02/w_u8_local.HC`:

```text
i8 TestLocal() {
    ...
    zext     %t3 i64 tmp, %l2 i8 local  ; line 5
    ...
}
```

For `src/tests/ir-boundary03-correction02/w2_u8_id.HC`:

```text
i8 Identity(%p1 i8 param) {
    ...
    zext     %t4 i64 tmp, %l2 i8 local  ; line 1
    ...
}
```

## AST type / native ABI / size

| Property                     | Value                                                     |
|------------------------------|-----------------------------------------------------------|
| Source syntax                | `I8` / `U8` / `Bool` (alias for `I8`)                     |
| AST type kind                | `AST_TYPE_CHAR`                                           |
| AST size                     | 1                                                         |
| Neutral IR type              | `IR_TYPE_I8` (no separate `IR_TYPE_U8`)                   |
| Native ABI size              | 1 byte (`src/tests/38_sizeof.HC:43-44`: `sizeof(I8) == 1`, `sizeof(U8) == 1`) |
| Native signedness            | Both 1-byte; signedness carried via ZEXT/SEXT in IR        |
| `bool` alias                 | `Bool` maps to `AST_TYPE_CHAR,1,1` (signed)               |

## Native AOT/JIT parity

The x86_64 / aarch64 backends (and JIT counterparts) lower `IR_ZEXT` /
`IR_SEXT` with explicit `movzbq` / `movsbq` (x86_64) and `uxtb` / `sxtb`
(aarch64) instructions, as required by `src/x86.c:81-83` and the aarch64
emitter at `src/aarch64-emit.h:402-405`. Native parity therefore already
agrees with the IR contract: the signedness decision lives in the
extension opcode that the LLVM backend will lower.

## Answer to R1 critical question

> Is the B0 source buffer element semantically signed or unsigned?

**Both exist** (`I8` and `U8`). The neutral IR does not encode signedness
on the byte value itself; signedness is recorded **at every widening site**
by the choice of `IR_ZEXT` (unsigned) vs `IR_SEXT` (signed).

For the **B0 lexer source-buffer element** specifically: the user has not
yet authorized a particular B0 source-buffer representation (see R3). The
ACT's `BYTE_DEREF_SEPARABLE_FROM_GEP = YES` outcome does not depend on the
choice between `I8` and `U8`: both follow identical byte-representation
machinery; only the **widening opcode** changes.

## Existing byte tests / fixtures

`src/tests/ir-boundary03-correction02/` contains 12 fixtures that
demonstrate the IR-level byte behavior:

* `w2_u8_id.HC`, `w4_u8_passthrough.HC`, `w5_i8_id.HC` — identity / passthrough
* `w_u8_arith.HC`, `w_u8_sub.HC` — arithmetic on byte
* `w3_u8_eq_2.HC`, `w_u8_local.HC` — local / comparison
* `w_i8_id_direct.HC` — signed identity (emits `sext` in IR)
* `runtime-correctness-u8.HC`, `runtime-correctness-i8u8-bypass.HC` —
  runtime probes
* `w1_u8_literal_2.HC`, `w6_other_widths.HC` — literals / other widths

`src/tests/52_narrow_signed_reads.HC` exercises the runtime signed-extension
contract (signed narrow reads must SEXT on load; unsigned must ZEXT).

All of these currently fail at the LLVM backend with
`LLVM_BACKEND_UNSUPPORTED_TYPE: ... type function parameter is not supported
by the LLVM backend` (verified; see R3 / R4).

## Conclusion

`BYTE_TYPE_AUTHORITY = OK`:
- `I8` and `U8` are first-class AST types (`AST_TYPE_CHAR` with size 1).
- The neutral IR represents both as `IR_TYPE_I8`.
- Signedness is encoded by the choice of `IR_ZEXT` vs `IR_SEXT` at widening
  sites.
- The LLVM backend must accept `IR_TYPE_I8` as both a value type and a
  function-parameter type, and map it to LLVM `i8` via
  `LLVMInt8TypeInContext`.
- The widening opcode (`IR_ZEXT` for unsigned, `IR_SEXT` for signed) is
  the load-bearing signedness carrier; it is the neutral-IR authority for
  signedness and must be lowered accordingly (but the per-load signedness
  is encoded by the IR, not by LLVM i8 bit width, per LLVM IR semantics).
