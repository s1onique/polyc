# MEMORY01 RED phase summary

Real REDs reproduced against the production LLVM 22 backend:

| Fixture | RED type | Observed behavior |
| --- | --- | --- |
| `src/tests/llvm-memory01/red_pointer_param.HC` | RED-1 pointer parameter | `hcc --emit-llvm` exits 1 with `LLVM_BACKEND_UNSUPPORTED_TYPE: function PtrParam: type function parameter is not supported by the LLVM backend`. dump-ir shows `i64 PtrParam(%p1 ptr param)` — IR_TYPE_PTR PARAM. No `load*` in dump-ir (function returns 0 without dereferencing). |
| `src/tests/llvm-memory01/red_load_deref.HC` | RED-2 I64 pointer read | `hcc --emit-llvm` exits 1 with `LLVM_BACKEND_UNSUPPORTED_TYPE`. dump-ir (after optimisations) shows `load* %t4 i64 tmp, %p1 ptr param` — IR_LOAD_DEREF with dst type I64, addr IR_TYPE_PTR param. |
| `src/tests/llvm-memory01/red_store_deref.HC` | RED-3 I64 pointer write | `hcc --emit-llvm` exits 1 with `LLVM_BACKEND_UNSUPPORTED_TYPE`. dump-ir shows `store* %l2 ptr local, %p3 i64 param` — IR_STORE_DEREF with dst IR_TYPE_PTR local, value IR_TYPE_I64 param. |
| `src/tests/llvm-memory01/red_ssa_local_baseline.HC` (copy of `src/tests/llvm-spike/01_const.HC`) | RED-4 SSA-local baseline | `hcc --emit-llvm` succeeds. The resulting `.ll` contains zero alloca/load/store instructions. |

R5 (pointee-type authority) is satisfied: the IR_LOAD_DEREF dst is
IR_TYPE_I64 and the IR_STORE_DEREF r1 is IR_TYPE_I64 — both come
from the existing compiler's promotion/narrowing, not from
source-level smuggling.

R6 (parameter lowering seam) is satisfied: the only seam change is
in `src/llvm-backend.c:540-548` where `param_tys[p] = i64` is
replaced by per-param type mapping. The LLVMValueRef returned by
`LLVMGetParam` is the opaque `ptr` directly — no alloca, no
store-to-local, no load-from-local, no ptrtoint/inttoptr.

RED harness: `scripts/quality/llvm-memory01-red-test.sh`.
RED pass count: 8 (4 fixtures x 2 assertions each, plus 1 extra
non-IR_LOAD_DEREF check for the no-deref pointer-param fixture).
RED fail count: 0.
