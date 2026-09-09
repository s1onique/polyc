# ACT-POLYC-LLVM-FLOAT01 / HANDOFF

VERDICT: PASS

## Identity

- branch: main
- HEAD: (see FLOAT01 CLOSE commit; will be appended by `ACT-Verdict: PASS` trailer)
- predecessor HEAD: 4043579f (MEMORY01-CORRECTION02 CLOSE)
- ACT scope: scalar F64 (param/return/constants/FADD/FSUB/FMUL/FCMP/FCMP→BR)
- companion file: `docs/acts/ACT-POLYC-LLVM-FLOAT01.md` (M3 contract)

## Root cause / finding

The LLVM backend was rejecting the entire `IR_TYPE_F64` value family at
`llTypeSupported` with `LLVM_BACKEND_UNSUPPORTED_TYPE`, which prevented
any source-level F64 use from compiling. The FLOAT01 ACT authorises a
bounded scalar-F64 slice (param, return, constants, FADD/FSUB/FMUL,
FCMP, FCMP→IR_BR) and binds the comparison semantics to the host's
native aarch64 `fcmp` + `cset` oracle.

The mapping is:

| PolyC op | LLVM FCmp predicate |
|----------|---------------------|
| ==       | LLVMRealOEQ         |
| !=       | LLVMRealUNE         |
| <        | LLVMRealOLT         |
| <=       | LLVMRealOLE         |
| >        | LLVMRealOGT         |
| >=       | LLVMRealOGE         |

This is the unique semantics-preserving mapping for the
host-native (aarch64) target: `fcmp NaN, x` sets NZCV=0011, and
`cset mi/ls/gt/ge/eq` all return 0 while `cset ne` returns 1 — matching
`oeq/olt/ole/ogt/oge` (false on NaN) and `une` (true on NaN) exactly.

## RED (PR-1 RED commit: 4592d79)

Seven RED witnesses (RED-1 .. RED-7) reproduced at
`LLVM_BACKEND_UNSUPPORTED_TYPE` rc=1 in
`evidence/llvm-float01/red/`. The recon
(`evidence/llvm-float01/red/recon-f64-type.txt` and
`recon-comparison-semantics.txt`) captures:

- F64 neutral-IR shape (F64 params become `double %0`, F64 constants
  become `double 0x...`).
- `as._f64` representation in the IR value struct (aliasing with
  `as.var` — same union overlap MEMORY01 fixed for `as.var`).
- IR_FCMP returns i1 in LLVM, but IR_VAL_TMP target is i64 (the IR's
  neutral type for comparison results). The bridge uses `irDstVarId`
  which already handles i1-into-i64 binding.
- The 6-op comparison-semantic oracle derived from aarch64-native
  `fcmp` + `cset` semantics.

RED summary: `evidence/llvm-float01/red/RED-SUMMARY.md`.

## Implementation (IMPL commit: 99391c4)

Production changes (additive; F7 ledger: `evidence/llvm-float01/impl/scope.txt`):

- `src/llvm-backend.c`:
  - `llType`, `llTypeSupported`, `llParamTypeSupported` accept
    `IR_TYPE_F64`; mapped to `LLVMDoubleTypeInContext`.
  - `llPass1` derives the return type from `fn->return_value->type`
    (was hard-coded i64).
  - `llLowerValue` adds `IR_VAL_CONST_FLOAT` arm with cache-bypass
    (extends MEMORY01's union-aliasing fix to F64 constants).
  - `llDetectCollapsibleReturn` accepts F64 return slots.
  - `llLowerInstr` gains `IR_FADD/IR_FSUB/IR_FMUL/IR_FCMP` arms
    (LL_INC_SUPPORTED) with explicit F64 operand guards, zero
    fast-math flags, and the `llFloatCmpKindToLLVMPred` helper for
    `FCmp` predicates. `IR_RET` and `IR_STORE` accept `IR_TYPE_F64`.
  - `IR_FDIV` and `IR_FNEG` remain REJECTED with FLOAT01-annotated
    diagnostics.
- `src/llvm-backend-cap.c`: `IR_FADD/IR_FSUB/IR_FMUL/IR_FCMP` →
  SUPPORTED with notes; `IR_FDIV/IR_FNEG` remain REJECTED with
  FLOAT01-annotated notes.

Predecessor evidence conservation:

- `src/tests/llvm-spike/neg_f64.HC` re-scoped to F32 params
  (still rejected as `LLVM_BACKEND_UNSUPPORTED_TYPE` for F32 float
  arithmetic; the previous F64-with-I64-return shape is now caught
  by the LLVM verifier — a strict superset of `UNSUPPORTED_TYPE`).

## Test harness

- `scripts/quality/llvm-float01-test.sh` (NEW): 13 positive + 6
  comparison-predicate + 1 branch + 1 mixed + 3 negative fixtures.
  Per-fixture SUPPORTED attribution (7 attributions). 3 determinism
  fixtures. llvm-as + opt --passes=verify. Fast-math purity grep.
  DEFENSIVE/UNREACHABLE counter gates.

- `src/tests/llvm-float01/` (NEW): 13 positive .HC + 3 negative .HC
  + 1 special_values.HC exercising +/-0, +/-inf, NaN paths.

## Gates

```
scripts/quality/llvm-float01-test.sh        FLOAT01_PASS=28 FAIL=0
scripts/quality/llvm-spike-test.sh          PASS=18  FAIL=0
scripts/quality/llvm-memory01-test.sh       PASS=6   FAIL=0
scripts/quality/llvm-memory01-nc5-probe.sh  PASS  (NC5 strong binding confirmed for IR_LOAD_DEREF)
scripts/quality/llvm-cap-table-verifier.py  PASS  (IR_FCMP + new helper detected)
scripts/quality/factory-v2-test.sh          PASS=35 FAIL=0
scripts/quality/gate-fast.sh                VERDICT=PASS
```

## Scope (F7 ledger)

In-scope files modified:
- `src/llvm-backend.c` (additive F64 paths only)
- `src/llvm-backend-cap.c` (F64 promotion rows)
- `src/tests/llvm-float01/*.HC` (13 + 3 + 1 = 17 new fixtures)
- `src/tests/llvm-spike/neg_f64.HC` (predecessor conservation redirect)
- `scripts/quality/llvm-float01-test.sh` (new harness)
- `evidence/llvm-float01/{red,impl}/*` (capture)

Out of scope and NOT modified:
- `src/aarch64*.c`, `src/x86_64*.c`, `src/asm/*`, `src/cli.c`,
  `src/main.c`, `src/ir*.c`, `src/ir-types.{c,h}`.

## Residue (F11, classified)

P2 (acknowledged, NOT silently fixed):
- x86_64-native F64 float arithmetic. The x86_64 native backend uses
  `ucomisd` + `setb`, which on NaN returns 1 (unordered), differing
  from the aarch64 native semantic. FLOAT01 binds to host (aarch64)
  semantic per ACT author.
- `IR_FDIV` / `IR_FREM` on F64 via LLVM backend. Authorized by
  future ACT.
- F32 arithmetic on LLVM backend. Authorized by future ACT.
- F64 vector types. Out of scope of this ACT.

## Next ACT (recommendation)

`ACT-POLYC-LLVM-FLOAT02`: F64 FDIV/FREM, or F32 promotion, or
x86_64-native F64 parity. The choice depends on native-backend parity
decisions pending F14 historical review.
