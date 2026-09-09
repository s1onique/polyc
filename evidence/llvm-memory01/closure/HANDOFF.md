# HANDOFF -- ACT-POLYC-LLVM-MEMORY01

Factory-Version: 2

## Result

PASS. The LLVM backend now supports the smallest real memory
slice: function parameters of type `I64 *`, lowered to LLVM
opaque `ptr`, with `IR_LOAD_DEREF` and `IR_STORE_DEREF`
emitting `load i64, ptr %p` and `store i64 %v, ptr %p` for the
strict proven shape (address-space-0 ptr + I64 access).

The closure verdict is authoritative in the `ACT-Verdict`
trailer of the ACT's CLOSE commit.

## What changed

### Production code
- `src/llvm-backend.c`:
  - `llParamTypeSupported()` for parameter-only pointer admission.
  - `llType()` maps `IR_TYPE_PTR` to opaque ptr
    (`LLVMPointerTypeInContext(ctx, 0)`).
  - `llPass1()` emits per-parameter LLVM type mapping (I64 or ptr).
  - `llBindParams()` is unchanged (already direct via `LLVMGetParam`).
  - `llLowerPointerValue()` resolves SSA pointer values from the
    cache (no `LLVMBuildLoad2` for pointers).
  - `llLowerValue()` bypasses cache for `IR_VAL_CONST_INT`. This
    is a local fix to the constant-id-aliasing bug that also
    incidentally corrects a pre-existing silent miscompilation
    (`x + 1` -> `x + x` in the scalar spike).
  - `IR_STORE` handler now also accepts `IR_TYPE_PTR` locals
    (pointer values flow through SSA locals without memory).
  - New `IR_LOAD_DEREF` and `IR_STORE_DEREF` dispatch arms with
    explicit shape guards (I64 access type, opaque ptr addr,
    no GEP/idx/disp).
  - The grouped REJECTED arm reduced to `IR_ALLOCA / IR_RMW_DEREF /
    IR_LEA`.
  - Updated matrix comment block.
- `src/llvm-backend-cap.c`:
  - `IR_LOAD_DEREF` and `IR_STORE_DEREF` rows promoted from
    `REJECTED` to `SHAPE_DEPENDENT`.

### Tooling
- `scripts/quality/llvm-memory01-test.sh` (NEW): bounded GREEN
  harness with llvm-as + LLVM 22 verifier (`opt --passes=verify`).
- `scripts/quality/llvm-memory01-red-test.sh` (NEW): RED-phase
  harness for the four RED fixtures.
- `scripts/quality/llvm-spike-test.sh`:
  - Removed `neg_pointer.HC` from the negative matrix.
  - Redirected `$EVID` and `$EVID_CORR` to MEMORY01 evidence
    dirs to keep historical evidence bit-identical (F14).

### Tests
- `src/tests/llvm-memory01/` (NEW): five positive fixtures
  (red_pointer_param, red_load_deref, red_store_deref,
  p4_load_add, p5_store_inc), one RED-shaped baseline
  (red_ssa_local_baseline), and the moved historical
  negative fixture (moved_neg_pointer.HC).
- `src/tests/llvm-spike/neg_pointer.HC` -> moved.

## Evidence

- `entry/`: pre-RED gate snapshots.
- `recon/`: Phase 0 recon (R1-R6) captured against the real
  compiler.
- `red/`: RED-phase harness and per-fixture transcripts.
- `impl/`: post-IMPL harness run, positive .ll snapshots,
  native `.s` snapshots for conservation, and an `addone-fixed-byproduct.ll`
  showing the pre-existing scalar-spike bug is also fixed.
- `negative-controls/`: NC2/NC3 direct grep witnesses.
- `closure/`: final closure run of every required gate.
- `spike/`: spike-test redirects (`.ll`, transcripts) under
  MEMORY01 evidence dir.

## Production delta

- New LLVM IR opcodes supported: `IR_LOAD_DEREF`,
  `IR_STORE_DEREF` (SHAPE_DEPENDENT class, I64-only access).
- New LLVM IR type supported: `ptr` (opaque, address space 0)
  as a function parameter type only.
- No native backend change. Native AOT/JIT semantics
  byte-identical (byte-for-byte re-emission not asserted; the
  fix touches only `src/llvm-backend.c` so the native code
  path is provably unchanged).

## Residue

- P1: neutral-IR-level fix for the `as._i64` / `as.var.id`
  union aliasing is out of scope (HALT_NEUTRAL_IR_CHANGE_REQUIRED);
  the LLVM backend currently works around it locally. A
  separate IR ACT could either separate the storage or assign
  constants a unique id space.
- P2: N1-N4 in ACT §14 are NOT_EXPRESSIBLE_IN_CURRENT_LANGUAGE.
  No source-level path currently produces a non-I64 pointee
  dereference, ptr-to-ptr, aggregate pointee, or pointer
  arithmetic through the supported path. Recorded as not-yet-
  expressible; revisited when the corresponding language
  features land.
- P2: `LLVM_SPIKE_EVID_OVERRIDE` / `LLVM_SPIKE_EVID_CORR_OVERRIDE`
  env vars added to `llvm-spike-test.sh` so future ACTs can
  isolate the spike evidence without touching the historical
  dirs.

## Recommended next ACT

`ACT-POLYC-LLVM-FLOAT01` (F64 parameters / F64 constants /
FADD / FSUB / FMUL / FCMP + branch / F64 return). Per ACT §28,
do NOT combine F64 with pointer generalization; close FLOAT01
separately and only then consider broader memory/aggregate
extension.
