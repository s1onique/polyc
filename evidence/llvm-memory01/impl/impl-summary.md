# MEMORY01 IMPL phase summary

Implementation transforms the LLVM backend from "scalar I64 SSA only"
to "scalar I64 SSA + address-space-0 ptr parameter + I64 load/store
through that pointer". The change is local to `src/llvm-backend.c`
and `src/llvm-backend-cap.c`; no neutral IR, native backend, parser,
or type checker is touched.

## Files changed

- `src/llvm-backend.c`
  - Added `llParamTypeSupported()` (function-parameter-only type
    admission: I64 or PTR).
  - `llType()` now maps `IR_TYPE_PTR` to `LLVMPointerTypeInContext(ctx, 0)`
    (LLVM 22 opaque pointer in address space 0).
  - `llPass1()` builds the per-parameter LLVM type vector with the
    new mapping. No `inttoptr`, `ptrtoint`, `alloca`, or
    `store-to-local` is involved.
  - `llBindParams()` is unchanged: `LLVMGetParam()` already returns
    the right LLVMValueRef when the function signature uses opaque
    `ptr`.
  - Added `llLowerPointerValue()` for resolving SSA pointer values
    from the cache (no `LLVMBuildLoad2` for pointers).
  - `llLowerValue()` now bypasses the SSA cache for
    `IR_VAL_CONST_INT`. The pre-existing scalar spike has been
    silently miscompiling `x + 1` as `x + x` because the constant
    `1`'s `as._i64 = 1` overlays `as.var.id = 1`, colliding with
    the parameter id. The fix is local: do not cache constants.
    A neutral-IR-level correction is out of scope for MEMORY01
    and is recorded as P1 residue.
  - The IR_STORE handler now also accepts `IR_TYPE_PTR` locals
    (pointer values flow through SSA locals without materialising
    memory). The `llLowerI64Value` / `llLowerPointerValue`
    selection is `dst->type`-driven.
  - Added `case IR_LOAD_DEREF:` arm with explicit shape guards:
    `dst->type == IR_TYPE_I64`, `r1->type == IR_TYPE_PTR`,
    `disp == 0`, `idx == NULL`, `scale == 0`. Other shapes are
    rejected with `LLVM_BACKEND_UNSUPPORTED_POINTER` or
    `LLVM_BACKEND_UNSUPPORTED_TYPE`.
  - Added `case IR_STORE_DEREF:` arm with the mirror guards on
    `dst->type` and `r1->type`.
  - The grouped REJECTED arm is now reduced to `IR_ALLOCA /
    IR_RMW_DEREF / IR_LEA` (the pointer / address-of opcodes that
    remain unsupported). `IR_LOAD_DEREF` and `IR_STORE_DEREF` are
    no longer in this group.
  - Updated the matrix comment block to mark `IR_LOAD_DEREF` /
    `IR_STORE_DEREF` as `SHAPE-DEPENDENT` and `IR_TYPE_PTR` as
    SUPPORTED for function parameters only.
- `src/llvm-backend-cap.c`
  - `IR_LOAD_DEREF` and `IR_STORE_DEREF` rows promoted from
    `LLVMBC_REJECTED` to `LLVMBC_SHAPE_DEPENDENT`. The note
    describes the proven supported shape and the rejection
    taxonomy for everything else.
- `scripts/quality/llvm-spike-test.sh`
  - Removed `neg_pointer.HC` from the negative matrix (it is now
    a positive fixture). The total test count drops from 19 to 18
    (this is documented in the ROADMAP).
- `src/tests/llvm-spike/neg_pointer.HC` -> moved to
  `src/tests/llvm-memory01/moved_neg_pointer.HC` (kept as a
  sibling reference; the canonical positive fixtures are
  `red_pointer_param.HC`, `red_load_deref.HC`,
  `red_store_deref.HC`, `p4_load_add.HC`, `p5_store_inc.HC`).

## New tooling

- `scripts/quality/llvm-memory01-test.sh` - bounded memory
  harness (positive matrix, llvm-as round-trip, `opt
  --passes=verify` LLVM 22 verifier, alloca/GEP/cast purity,
  counter gate).
- `scripts/quality/llvm-memory01-red-test.sh` - RED-phase
  harness (already committed in C1).

## GREEN fixtures (5 positive, 1 negative)

| Fixture | Expected `.ll` shape | llvm-as | opt verify |
| --- | --- | --- | --- |
| `red_pointer_param.HC` | `define i64 @PtrParam(ptr %0)` | PASS | PASS |
| `red_load_deref.HC`    | `define i64 @Load(ptr %0) { %v = load i64, ptr %0; ret i64 %v }` | PASS | PASS |
| `red_store_deref.HC`   | `define i64 @Store(ptr %0, i64 %1) { store i64 %1, ptr %0; ret i64 0 }` | PASS | PASS |
| `p4_load_add.HC`       | `load i64, ptr; add i64 %ld, 1; ret` | PASS | PASS |
| `p5_store_inc.HC`      | `load i64, ptr; add; store i64, ptr; load; ret` | PASS | PASS |
| `neg_struct.HC`        | negative: `LLVM_BACKEND_UNSUPPORTED_TYPE` | n/a | n/a |

## Counter gate (memory01-test.sh)

```
SUPPORTED           : 7
REJECTED            : 0
SHAPE_DEPENDENT     : 8
DEFENSIVE_INVARIANT : 0
UNREACHABLE_ON_LLVM : 0
```

- SUPPORTED > 0: yes (7)
- SHAPE_DEPENDENT >= 1: yes (8; IR_LOAD_DEREF + IR_STORE_DEREF
  in each fixture plus IR_STORE shape-handling)
- DEFENSIVE = 0: yes
- UNREACHABLE = 0: yes

## Existing spike (preserved)

```
Summary: PASS=18  FAIL=0
SUPPORTED           : 14
REJECTED            : 4
SHAPE_DEPENDENT     : 7
DEFENSIVE_INVARIANT : 0
UNREACHABLE_ON_LLVM : 0
```

The spike count dropped from 19 to 18 because `neg_pointer.HC`
moved to MEMORY01 (now positive). All other fixtures unchanged.

## Native conservation

The native AOT/JIT path is untouched by this ACT (the changes
are confined to `src/llvm-backend.c`). The native `.s` for
`Load(I64 *p)` is `ldr x0, [x0]` (aarch64) and for
`Store(I64 *p, I64 x)` is `str x0, [x1]`, both semantically
equivalent to the emitted LLVM IR.

## Conservation witness

- cap-table verifier: PASS
- factory-v2-test: PASS (PASS=35 FAIL=0)
- gate-fast: PASS (VERDICT=PASS)
- existing spike: PASS=18 FAIL=0 (was 19 before; one fixture moved
  to MEMORY01)
- cap-table rows: 56 (unchanged; row classifications changed but
  ordinal count preserved)
