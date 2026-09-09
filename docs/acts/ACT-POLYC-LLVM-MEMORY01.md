# ACT-POLYC-LLVM-MEMORY01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Smallest real LLVM memory slice — pointer-parameter I64 load/store

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**
- `ACT-POLYC-LLVM-SPIKE01` + RESUME01 + CORRECTION chains (PASS)
- `ACT-POLYC-LLVM-CORE01` (REJECTED, f4ac2e7) → CORRECTION02 (PASS, 75983a8)
- `ACT-POLYC-LLVM-CORE02` (PASS_WITH_NONBLOCKING_RECON_RESIDUE)
- `ACT-POLYC-LLVM-CORE03` + CORRECTION01..05 (PASS chain)
- `ACT-POLYC-LLVM-CORE04` (HALT_RED_NOT_REPRODUCED, 4be5df3)
- `ACT-POLYC-LLVM-CORE04-RESUME01` (PASS, 82cde85)
- `ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01` + CORRECTION01 (PASS chain)

**Class:** MACHINE-ENFORCED CAPABILITY CONTRACT — semantic extension

**Production semantic changes:** **NONE** (language semantics preserved via native backend; LLVM backend adds IR_LOAD_DEREF / IR_STORE_DEREF for one proven shape)

**Source change scope (bounded):**
1. `src/llvm-backend.c` / `.h` — accept `IR_TYPE_PTR` as a function-parameter type; lower to LLVM opaque `ptr`; add `IR_LOAD_DEREF` / `IR_STORE_DEREF` dispatch arms with explicit I64 access-type guard.
2. `src/llvm-backend-cap.c` — promote `IR_LOAD_DEREF` and `IR_STORE_DEREF` from `REJECTED` to `SHAPE_DEPENDENT`.
3. `scripts/quality/llvm-spike-contract-check.sh` — revise the existing forbidden-in-positive-fixtures `load`/`store` grep to permit semantic `load i64, ptr %p` / `store i64 %v, ptr %p` while continuing to forbid `alloca` and local-spill memory ops.
4. `scripts/quality/llvm-memory01-test.sh` (NEW) — bounded memory test harness.
5. `src/tests/llvm-memory01/*` (NEW) — bounded positive/negative memory fixtures.

**IR / ABI / neutral-IR boundary changes:** **NONE**

**LLVM IR lowering additions:** pointer-parameter opaque-`ptr` lowering + `load i64, ptr` + `store i64, ptr` for one proven shape

**Language change authorization:** **NONE**

---

## 0. Mission
Extend the deliberately-supported LLVM backend from its current scalar-I64 SSA core to the **smallest real memory slice**:

```text
pointer parameter carrying address of I64
        ↓
IR_LOAD_DEREF
IR_STORE_DEREF
        ↓
LLVM opaque `ptr`
        ↓
load i64, ptr %p
store i64 %v, ptr %p
```

This ACT adds semantic memory access.

It does **not** reintroduce memory as an implementation mechanism for SSA locals.

The distinction is binding:

```text
SEMANTIC_MEMORY
    user program explicitly dereferences a pointer
    -> allowed in this ACT

COMPILER_SPILL_MEMORY
    backend converts SSA locals into alloca/store/load
    -> remains forbidden
```

No GEP. No pointer arithmetic. No aggregate access. No arrays. No structs. No pointer-to-pointer. No global variables. No heap allocation. No LLVM `alloca`. No PHI. No TargetMachine. No ORC/JIT. No optimizer pipeline.

Factory v2 remains frozen.

---

# 1. Why this is the next slice

The LLVM core now has:
- verifier-clean scalar I64 emission
- SSA-only local contract
- explicit rejected capability classes
- mechanically-bound dispatch/capability table
- permanent adversarial verifier tests
- per-class execution counters
- clean stderr instrumentation

The highest-value next step is to add **real semantics** rather than another contract layer.

`IR_LOAD_DEREF` and `IR_STORE_DEREF` are already known capability gaps.

This ACT promotes only a tightly-proven subset of those opcodes.

---

# 2. LLVM-side model

LLVM uses opaque pointers: `ptr` rather than embedding a pointee type.

A load carries the accessed type explicitly: `%v = load i64, ptr %p`
A store carries the value type explicitly: `store i64 %v, ptr %p`

The backend must derive the accessed type from **PolyC IR semantics**, not from LLVM pointer-element introspection.

Binding rule: PolyC must provide enough neutral-IR information to determine that a dereference accesses an I64 object.

The backend may not guess pointee type from: LLVM pointer identity, pointer size, native ABI, source spelling, previous store, value history.

---

# 3. Factory v2 lifecycle

The ACT document is authorization only.

Execution commits use:
```
ACT: ACT-POLYC-LLVM-MEMORY01
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
```
CLOSE additionally carries `ACT-Verdict: PASS` or the exact HALT token.

No SHA table. No numeric commit cap. No mutable Markdown Status field. No Factory implementation changes are authorized.

---

# 4. Entry gates

Before any RED: branch=main, worktree=clean, LLVM 22, cap-table PASS, spike PASS=19 FAIL=0, factory-v2-test PASS, gate-fast PASS.

If predecessor RED: HALT_PREDECESSOR_BASELINE_RED.

---

# 5. Phase 0 - mandatory recon

R1-R6 must be answered from current tree. See evidence/llvm-memory01/recon/.

R5 pointee-type authority must resolve to A/B/C. If D: HALT_POINTEE_TYPE_NOT_AVAILABLE_AT_LLVM_BOUNDARY.

R6 parameter lowering seam must show pointer parameter can map to LLVM opaque ptr without alloca/store-to-local/load-from-local/inttoptr/ptrtoint. If not: HALT_POINTER_PARAMETER_REQUIRES_UNAUTHORIZED_LOWERING.

---

# 6. Principal REDs

RED-1: pointer parameter fails with named unsupported-type boundary.
RED-2: I64 pointer read fails with named unsupported diagnostic; neutral IR contains IR_LOAD_DEREF.
RED-3: I64 pointer write fails with named unsupported diagnostic; neutral IR contains IR_STORE_DEREF.
RED-4: SSA-local fixture has zero alloca/load/store in .ll.

---

# 7. Authorized semantic subset

Pointer address space 0, parameter origin only, I64 only, IR_LOAD_DEREF/IR_STORE_DEREF only, I64 load result, I64 stored value.

Excluded: I8/I16/I32/U*/F64/struct/array/class/pointer/fnptr pointee, pointer return, pointer locals, pointer arithmetic, null, comparison, ptrtoint/inttoptr/bitcast, GEP, LEA, globals, alloca, heap, volatile, atomic, non-zero AS.

---

# 8. LLVM type mapping

8.1 Pointer: LLVMPointerTypeInContext(ctx, 0) opaque.
8.2 Load: LLVMBuildLoad2(builder, i64_ty, ptr_value, name).
8.3 Store: LLVMBuildStore(builder, i64_value, ptr_value).
8.4 No GEP.

---

# 9. Capability-table changes

Promote IR_LOAD_DEREF, IR_STORE_DEREF from REJECTED to SHAPE_DEPENDENT. Update table, verifier, harness atomically.

---

# 10. Diagnostics

Reuse LLVM_BACKEND_UNSUPPORTED_POINTER for now (F8 minimum useful classification). No new diagnostic unless REDs prove distinct seams.

---

# 11. Counter semantics

IR_LOAD_DEREF dispatch -> SHAPE_DEPENDENT +1
IR_STORE_DEREF dispatch -> SHAPE_DEPENDENT +1
regardless of accept/reject. Do not double-count.

Expected: SHAPE_DEPENDENT baseline increases, SUPPORTED > 0, REJECTED > 0, DEFENSIVE = 0, UNREACHABLE = 0.

---

# 12. SSA-only local contract revision

Replace:
- LLVM_LOAD = 0 / LLVM_STORE = 0
with:
- LLVM_ALLOCA_FOR_LOCALS = 0
- LLVM_LOCAL_SPILL_LOAD = 0
- LLVM_LOCAL_SPILL_STORE = 0
- LLVM_SEMANTIC_LOAD_DEREF >= 1 in load fixture
- LLVM_SEMANTIC_STORE_DEREF >= 1 in store fixture

Classify instructions by fixture/expected shape rather than grep.

---

# 13. Implementation scope

Allowed: src/llvm-backend.c, src/llvm-backend.h, src/llvm-backend-cap.c, src/llvm-backend-cap.h, scripts/quality/llvm-spike*.sh, scripts/quality/llvm-cap-table-verifier.py, src/tests/llvm-memory01/* (NEW), evidence/llvm-memory01/*, docs/ROADMAP.md.

Forbidden: src/ir.c, src/ir-types.*, src/ir-optimise.c, src/ir-regalloc.c, native backends, parser, lexer, type checker, language syntax, Factory files, Makefile semantics, CMake feature expansion, LLVM optimization pipeline, TargetMachine, ORC/JIT.

If neutral IR must change: HALT_NEUTRAL_IR_CHANGE_REQUIRED.

---

# 14. GREEN fixtures

Positive: P1 pointer-param signature, P2 load, P3 store, P4 load+arith, P5 store from arith, P6 fn-call forward (optional).

Negative: N1 unsupported pointee, N2 ptr-to-ptr, N3 aggregate, N4 arithmetic (if expressible). Use NOT_EXPRESSIBLE_IN_CURRENT_LANGUAGE marker for unavailable.

---

# 15. Expected LLVM IR

Load: define i64 @Load(ptr %p) { %v = load i64, ptr %p; ret i64 %v }
Store: define ... @Store(ptr %p, i64 %x) { store i64 %x, ptr %p; ... }
Bind structurally; do not golden-test numbering.

---

# 16. LLVM verification

llvm-as fixture.ll -o /tmp/fixture.bc
opt -passes=verify fixture.ll -disable-output (or LLVM 22 actual invocation)
No .bc committed.

---

# 17. Native semantic conservation

native AOT/JIT result before == after MEMORY01 for each positive fixture. byte-identical where practical.

---

# 18. LLVM semantic validation boundary

Closure proves: source -> neutral IR -> LLVM IR -> LLVM verifier. NOT LLVM-generated machine code execution.

Do not silently invoke lli.

---

# 19. Permanent negative controls

NC1 missing access type -> refuse. NC2 GEP -> MEMORY01 purity FAIL. NC3 alloca -> purity FAIL. NC4 unsupported pointee -> rc!=0 named diagnostic. NC5 counter regression -> counter FAIL.

---

# 20. Acceptance criteria

Entry/recon AC01-AC09; RED AC10-AC14; Implementation AC15-AC24; Verification/conservation AC25-AC35. See full list in body.

---

# 21. Required gates

make clean; make llvm-all; llvm-cap-table-verifier.py; llvm-spike-test.sh; llvm-memory01-test.sh; factory-v2-test.sh; gate-fast.sh; git diff --check <MEMORY01-FIRST>..HEAD; factory-v2-range-check.sh ACT-POLYC-LLVM-MEMORY01 <CLOSE>.

---

# 22. Evidence

evidence/llvm-memory01/{entry,recon,red,impl,negative-controls,closure,HANDOFF.md}. Text only. No .bc/.o/binaries. Normalize whitespace via established hash/base64 pattern.

---

# 23. Halt taxonomy

HALT_PREDECESSOR_BASELINE_RED, HALT_RED_NOT_REPRODUCED, HALT_IR_SHAPE_DIFFERS_FROM_ACT, HALT_POINTEE_TYPE_NOT_AVAILABLE_AT_LLVM_BOUNDARY, HALT_POINTER_PARAMETER_REQUIRES_UNAUTHORIZED_LOWERING, HALT_NEUTRAL_IR_CHANGE_REQUIRED, HALT_POINTER_SHAPE_AMBIGUOUS, HALT_LLVM_VERIFIER_RED, HALT_SSA_LOCAL_MEMORY_REGRESSION, HALT_GEP_REQUIRED, HALT_COUNTER_REGRESSION, HALT_NATIVE_SEMANTICS_CHANGED, HALT_HISTORICAL_EVIDENCE_MUTATION, HALT_FACTORY_V2_INVALIDATES_MEMORY01, HALT_SCOPE_EXPANSION_REQUIRED.

---

# 24. Commit phases

RED -> IMPL -> EVIDENCE -> CLOSE. Trailers required.

---

# 25. HANDOFF

VERDICT, MISSION OUTCOME, RECON, RED, IMPLEMENTATION, SEMANTIC MEMORY vs SSA MEMORY, LLVM VERIFICATION, NATIVE CONSERVATION, COUNTERS, GATES, RESIDUE, NEXT ACT. No SHA identity.

---

# 26. Closure decision

PASS only when: load+store supported, opaque ptr correct, llvm-as+verifier PASS, no GEP/alloca/casts, no SSA memory fallback, native unchanged, core GREEN, Factory GREEN, ACT-range hygiene GREEN.

HALT on any scope expansion with matching token.

---

# 27. Residue

Do not address: F64 memory, narrow int, struct, array, field, GEP, arithmetic, comparison, casts, globals, heap, stack, volatile, atomic, non-zero AS, pointer ABI, LLVM execution, TargetMachine, ORC/JIT.

---

# 28. Recommended next ACT

If PASS: NEXT_ACT = ACT-POLYC-LLVM-FLOAT01 (F64 params/consts/FADD/FSUB/FMUL/FCMP+branch/F64 return).

If HALT: NEXT_ACT determined by HALT evidence, do not pre-authorize GEP.

---

# 29. Architectural invariant

LLVM memory instructions are emitted only for explicit PolyC memory semantics. Never a fallback for SSA lowering. Binding for all later pointer/aggregate ACTs.

---

## Execution metadata

```
ACT: ACT-POLYC-LLVM-MEMORY01
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
ACT-Verdict: <token>      (CLOSE only)
```

The original authorization artifact remains historically stable. No OPEN -> PASS / HALT mutation. ACT document NOT modified at closure. Verdict lives on the CLOSE commit trailer.
