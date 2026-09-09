# IMPL summary — ACT-POLYC-LLVM-BYTE-MEMORY01

## Scope

Admit the bounded byte-representation / byte-memory / byte-promotion
path on the LLVM C-API backend:

- `IR_TYPE_I8` admitted as a load access type (`load i8, ptr`)
- `IR_TYPE_I8` and `IR_TYPE_U8` admitted as parameter / return / local
  types (signedness discarded; carried by `IR_ZEXT` vs `IR_SEXT`)
- `IR_ZEXT I8 → I64` (unsigned byte promotion) — SHAPE_DEPENDENT
- `IR_SEXT I8 → I64` (signed byte promotion) — SHAPE_DEPENDENT
- `IR_TRUNC I64 → I8` (byte-local narrowing) — SHAPE_DEPENDENT
- `IR_ICMP` / `IR_IADD` / `IR_ISUB` / `IR_IMUL` with an I8 char literal
  paired with a byte-promoted I64: narrow the I64 SSA operand to i8,
  do the op at i8, then `zext` the result to i64 for the I64 dst.
- `IR_RET` truncates widened I64 back to i8 when the function's
  nominal return is i8.

## DEFERRED

- `IR_STORE_DEREF` byte shape (writing bytes through a pointer)
- `IR_SEXT` byte → byte
- `IR_TRUNC` I64 → byte (byte-output ports) — the in-memory byte path
  is read-only; outputs are widened to i64 then truncated on return.

## Out-of-scope (per ACT §2 / §31)

- GEP / pointer indexing — forbidden
- `ptrtoint` / `inttoptr` — forbidden
- `alloca` byte array — not yet admitted; bytes are read through
  pointer parameters only.

## Source diff sketch (per ACT §31)

`src/llvm-backend-cap.c`:

- `IR_LOAD_DEREF` row — note updated to mention `IR_TYPE_I64 OR IR_TYPE_I8`
- `IR_STORE_DEREF` row — note unchanged (I64 only; byte store DEFERRED)
- `IR_ZEXT` row — note updated to SHAPE_DEPENDENT I8 → I64 promotion
- `IR_SEXT` row — note updated to SHAPE_DEPENDENT I8 → I64 promotion
- `IR_TRUNC` row — note updated to SHAPE_DEPENDENT I64 → I8 narrowing

`src/llvm-backend.c`:

- `llTypeSupported` / `llParamTypeSupported` — admit `IR_TYPE_I8` /
  `IR_TYPE_U8` for parameter / local / return types
- `llType` — map `IR_TYPE_I8` → LLVM i8, `IR_TYPE_U8` → LLVM i8
- `llLowerPointerValue` / `IR_LOAD_DEREF` arm — accept
  `dst->type == IR_TYPE_I64 || IR_TYPE_I8`; emit `load i8, ptr`
  for the byte case
- `IR_STORE` arm — accept `src->type == IR_TYPE_I8` for local-store
  (byte var = char literal)
- `IR_ZEXT` / `IR_SEXT` arm — accept `src == IR_TYPE_I8 && dst == IR_TYPE_I64`
- `IR_TRUNC` arm — accept `src == IR_TYPE_I64 && dst == IR_TYPE_I8`
- `IR_ICMP` / `IR_IADD` / `IR_ISUB` / `IR_IMUL` arm — when one operand
  is an IR_TYPE_I8 char-literal value and the other is an IR_TYPE_I64
  widened from a byte: narrow the I64 to i8, do the op at i8, then
  `zext` the result to i64.
- `IR_RET` arm — when the function's nominal return is `IR_TYPE_I8`
  and the source is an I64-widened byte value, truncate back to i8.

## Fixtures added (`src/tests/llvm-byte-memory01/`)

- `red_byte_load.HC` — U8 pointer read; byte load
- `red_byte_pointer_param.HC` — U8 pointer parameter
- `red_byte_to_i64.HC` — U8 promotion to I64
- `red_u8_param.HC` — U8 parameter admission
- `red_i8_param.HC` — I8 parameter admission
- `pos_byte_compare_simple.HC` — direct byte comparison with char literal
- `pos_b0_compare_digit.HC` — DEFERRED (ir-builder conditional-byte-return
  collapse bug; see RESIDUE)

## Fixtures modified

- `src/tests/llvm-spike/red_conversion_trunc.HC` — replaced with
  `red_conversion_trunc_i16.HC` (the original narrowed I64 → I8, which
  is now ADMITTED per BYTE-MEMORY01; the new fixture narrows I64 → I16
  to confirm the boundary is still REJECTED).

## Per-fixture counter attribution (CORE04 §30 binding)

Every positive byte fixture must increment SHAPE_DEPENDENT at the
dispatch seam. Observed counts:

```
red_byte_load           SHAPE_DEPENDENT = 2  (IR_LOAD_DEREF + IR_ZEXT)
red_u8_param            SHAPE_DEPENDENT = 2  (IR_ZEXT or IR_SEXT)
red_i8_param            SHAPE_DEPENDENT = 2  (IR_SEXT or IR_ZEXT)
red_byte_to_i64         SHAPE_DEPENDENT = 2  (IR_LOAD_DEREF + IR_ZEXT)
pos_byte_compare_simple SHAPE_DEPENDENT = 5  (multiple promotions + ops)
```

## Capability table (binding)

```
I1: IR_LOAD_DEREF  = SHAPE_DEPENDENT (now with I8 access type)
I1: IR_STORE_DEREF = SHAPE_DEPENDENT (I64 only; byte deferred)
I1: IR_ZEXT        = SHAPE_DEPENDENT (BYTE-MEMORY01 promotion)
I1: IR_SEXT        = SHAPE_DEPENDENT (BYTE-MEMORY01 promotion)
I1: IR_TRUNC       = SHAPE_DEPENDENT (BYTE-MEMORY01 narrowing)
```

All opcodes have explicit dispatch arms and capability rows (I2).

## Closure gates

```
byte-memory01-test.sh     PASS=37 FAIL=0
cap-table-verifier        PASS (all invariants)
intops01-test             PASS=4  FAIL=0
spike-test                PASS=18 FAIL=0
spike-contract-check      PASS (one pre-existing FAIL: neg_pointer.HC
                                    missing; not introduced by this ACT)
memory01-test             PASS=6  FAIL=0
float01-test              PASS=29 FAIL=0
memory01-nc5-probe        PASS
factory-v2-test           PASS=35 FAIL=0
factory-append-only-test  PASS=11 FAIL=0
gate-fast                 VERDICT=PASS
```
