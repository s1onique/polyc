# R5 — Byte-to-I64 Authority

## Load-bearing question

Is the source-byte-to-I64 promotion a `zext` (zero-extend) or `sext`
(sign-extend)?

## Source authority

The signedness authority in PolyC is `AstType->issigned` (set by the
lexer / cctrl at `src/cctrl.c:96-115`):

| Source lexeme | issigned |
|---------------|----------|
| `Bool`        | 1        |
| `I8`          | 1        |
| `U8`          | 0        |
| `I16`         | 1        |
| `U16`         | 0        |
| ...           |          |

The IR builder consumes `issigned` at every widening site via
`irWidenToTargetWidth` (`src/ir.c:218-232`):

```c
int sext = src_ty && src_ty->issigned;
IrOp ext = sext ? IR_SEXT : IR_ZEXT;
```

The resulting `IR_SEXT` / `IR_ZEXT` instruction **carries** the
signedness decision. There is no per-value signedness flag; the choice
is encoded in the widening opcode.

## Empirical confirmation (--dump-ir)

For `I8 Id(I8 x)` (`src/tests/ir-boundary03-correction02/w_i8_id_direct.HC`):

```text
sext     %t4 i64 tmp, %l2 i8 local  ; line 1
```

For `U8 TestLocal()` (`src/tests/ir-boundary03-correction02/w_u8_local.HC`):

```text
zext     %t3 i64 tmp, %l2 i8 local  ; line 5
```

## LLVM semantic authority

LLVM LangRef (Language Reference Manual):

* `zext`: zero-extend to a larger integer type (high bits filled with 0).
* `sext`: sign-extend to a larger integer type (high bits filled with
  the sign bit).

The mapping is therefore:

| IR widening | LLVM opcode | result for source value 0x80 | result for source value 0xFF |
|-------------|-------------|------------------------------|------------------------------|
| `IR_ZEXT`   | `zext i8 -> i64` | 128                       | 255                          |
| `IR_SEXT`   | `sext i8 -> i64` | -128 (0xFFFFFFFFFFFFFF80) | -1   (0xFFFFFFFFFFFFFFFF) |

The 0x00, 0x01, 0x7F cases cannot distinguish `zext` from `sext`.

## R5 question answered

The mapping is **legal** because:

1. The neutral IR emits `IR_ZEXT` / `IR_SEXT` based on the
   `AstType->issigned` of the source byte.
2. `IR_ZEXT` maps to `zext i8 -> i64` (unsigned promotion).
3. `IR_SEXT` maps to `sext i8 -> i64` (signed promotion).
4. The LLVM backend must lower both, and the choice of which to emit
   comes **only** from the neutral IR opcode, never from LLVM i8 bit
   width alone (LLVM `i8` has no inherent signedness).

## No HALT required

`BYTE_EXTENSION_SEMANTICS = OK`. Both unsigned (`zext`) and signed
(`sext`) promotion have neutral-IR authority; the LLVM backend lowering
is straightforward. The ACT's Outcome B (signed `I8` semantics) is
naturally supported by the IR builder's existing choice of `IR_SEXT`
for signed sources.
