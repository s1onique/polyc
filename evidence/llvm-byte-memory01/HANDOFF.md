# HANDOFF — ACT-POLYC-LLVM-BYTE-MEMORY01

VERDICT: PASS (with documented residue)

## IDENTITY

```
branch:  main
HEAD:    (see entry identity in evidence/llvm-byte-memory01/entry/)
entry:   (see entry identity in evidence/llvm-byte-memory01/entry/)
HCC:     ./hcc (LLVM 22.1.8 C-API backend)
LLVM:    llvm-as + opt (LLVM 22.1.8)
```

## ROOT CAUSE / FINDING

The neutral IR already carried `IR_TYPE_I8` (signedness discarded by
`irConvertType`). The LLVM backend, however, had only admitted I64
access types for `IR_LOAD_DEREF` / `IR_STORE_DEREF`, only admitted
`IR_ZEXT` / `IR_SEXT` for explicit case-arm dimensions that did not
include the I8 → I64 promotion, and rejected all `IR_TRUNC` shapes
including the natural I64 → I8 narrowing for byte-local storage.

The ACT admits the minimum set of byte shapes required to read a
byte through a pointer parameter and observe it on a comparison
against an I8 char literal, while explicitly deferring the byte-store
path (out-of-scope per ACT §31).

## RED

All five principal RED fixtures now compile to verifiable LLVM IR
and emit `load i8, ptr` / `zext i8 → i64` / `sext i8 → i64` /
`trunc i64 → i8` as appropriate. The negative control
`red_i16_trunc_negative.HC` is rejected with the named
`LLVM_BACKEND_UNSUPPORTED_CONVERSION` diagnostic. `pos_byte_compare_simple.HC`
passes `llvm-as` + `opt --passes=verify`. The conditional-return
fixture `pos_b0_compare_digit.HC` is preserved as RED — see RESIDUE.

## IMPLEMENTATION

Single bounded change to the LLVM backend (see
[`impl/impl-summary.md`](impl/impl-summary.md)):

1. `src/llvm-backend-cap.c` — capability rows for `IR_LOAD_DEREF`,
   `IR_ZEXT`, `IR_SEXT`, `IR_TRUNC` updated to SHAPE_DEPENDENT with
   explicit byte-shape notes; `IR_STORE_DEREF` row unchanged (I64 only).
2. `src/llvm-backend.c` — admission / emission sites:
   - `llTypeSupported` / `llParamTypeSupported` accept `IR_TYPE_I8` /
     `IR_TYPE_U8` for parameter / local / return types.
   - `llType` maps `IR_TYPE_I8` / `IR_TYPE_U8` → LLVM i8.
   - `IR_LOAD_DEREF` arm emits `load i8, ptr` when `dst->type == IR_TYPE_I8`.
   - `IR_STORE` arm accepts `src->type == IR_TYPE_I8` for local-store
     (byte var = char literal).
   - `IR_ZEXT` / `IR_SEXT` / `IR_TRUNC` arms now SHAPE_DEPENDENT with
     the I8 ↔ I64 shape admitted; other shapes still REJECTED.
   - `IR_ICMP` / `IR_IADD` / `IR_ISUB` / `IR_IMUL` arms narrow the
     I64 SSA operand to i8, do the op at i8, then `zext` to i64
     when one operand is an I8 char literal paired with a byte-promoted
     I64.
   - `IR_RET` truncates widened I64 back to i8 when the function's
     nominal return is `IR_TYPE_I8`.

## GATES

```
byte-memory01-test.sh     PASS=37 FAIL=0   STATUS=PASS
cap-table-verifier        PASS (56 rows round-trip, 9 invariants)
intops01-test             PASS=4  FAIL=0
spike-test                PASS=18 FAIL=0
spike-contract-check      PASS  (pre-existing FAIL: missing
                                 src/tests/llvm-spike/neg_pointer.HC;
                                 not introduced by this ACT)
memory01-test             PASS=6  FAIL=0
float01-test              PASS=29 FAIL=0
memory01-nc5-probe        PASS  (NC5 strong binding for IR_LOAD_DEREF)
factory-v2-test           PASS=35 FAIL=0
factory-append-only-test  PASS=11 FAIL=0
gate-fast                 VERDICT=PASS
```

All raw outputs are captured under
[`closure/`](closure/).

## SCOPE

Authorised scope is exactly what the ACT describes:

- Byte read through `IR_TYPE_PTR` parameter into `IR_TYPE_I8` /
  `IR_TYPE_U8` local / direct consumer.
- Byte promotion via `IR_ZEXT` / `IR_SEXT` to `IR_TYPE_I64` (signedness
  carried by opcode selection in `irWidenToTargetWidth`).
- Byte-local narrowing via `IR_TRUNC I64 → I8`.
- Byte arithmetic with `IR_ICMP` / `IR_IADD` / `IR_ISUB` / `IR_IMUL`
  when an I8 char literal is paired with a byte-promoted I64.
- Byte output via `IR_RET` truncation of widened I64 back to i8.
- No GEP, no indexing, no `ptrtoint` / `inttoptr`, no `alloca` byte
  array, no IR-builder seam changes.

Pre-existing IR-builder seam (return-value collapse) is left
untouched; the conditional-byte-return bug is captured as RESIDUE
(see below).

## RESIDUE

### P1 — LLVM IR builder collapse bug for conditional byte returns

The fixture `src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC`
exercises the byte path through a conditional return whose two arms
read from different byte-typed locals (`ReadDigit`, `AccDigit`). The
emitted IR fails `opt --passes=verify` with the SSA diagnostic:

```
Instruction does not dominate all uses:
  %12 = load i8, ptr %AccDigit, align 1
  store i8 %12, ptr %.reload1, align 1
```

The `%.reload1` SSA value is used in a basic block reachable only via
a branch where the `store i8 %12, ptr %.reload1` is missing. The
defect is in the IR builder's collapse-store-value path
(`llCollapseStoreValue` in `src/llvm-backend.c`), not in the BYTE-MEMORY01
admission logic.

Repairing it requires IR-builder changes (e.g. block-aware reload
selection) and is out of scope for this ACT per F7 / F15. It is
documented as RESIDUE P1.

The ACT's principal RED `pos_byte_compare_simple.HC` (single-block,
direct byte comparison against a char literal) passes verifier; the
defect is specific to the cross-block conditional-byte-return pattern.

### NEXT_ACT

`ACT-POLYC-LLVM-IR-COLLAPSE-FIX01` (or fold into a follow-on
`ACT-POLYC-LLVM-GEP01` if the scope expansion is justified by
adjacent work).

## NEXT ACT

`ACT-POLYC-LLVM-IR-COLLAPSE-FIX01` (recommended) or
`ACT-POLYC-LLVM-GEP01` (byte-store + array/struct access). See RESIDUE
P1 for justification.
