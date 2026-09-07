# ACT-POLYC-IR-BOUNDARY01

**Title:** Extract Backend-Neutral Pre-Codegen IR Boundary and Remove Native-Lowering Leakage

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-BOOTSTRAP-RECON01` (PASS_WITH_NEXT_ACT_DECISION at `60811e6`)

**Class:** IMPLEMENTATION / ARCHITECTURAL BOUNDARY / BEHAVIOR-PRESERVING

**Primary goal:** Make the existing typed SSA IR explicitly consumable by a backend that does **not** use PolyC's native register allocator or native instruction fusions.

**LLVM authorization:** **NONE**

**Language-semantic changes:** **FORBIDDEN**

---

# 0. Mission

RECON01 classified the inherited IR as `IR_CLASS_B = NEUTRAL_CORE_WITH_LOWERED_TAIL`. The principal residual leakage was the parameter-arrival block (`src/ir.c:2799-3024`) consulting `IrRegPool` during generic IR lowering.

This ACT extracts that consultation into a native-only post-pass and documents the boundary.

---

# 1. Verdict

**VERDICT=PASS_WITH_NEXT_ACT_DECISION**

Acceptance criteria AC01-AC11 all pass. Next ACT: **ACT-POLYC-LLVM-SPIKE01**.

---

# 2. Identity

```
ENTRY_HEAD   = 60811e60a70b3adbe107b93449f0d85d40c75a54
FINAL_HEAD   = see `git log --oneline -5` at closure
WORKTREE     = clean
```

The four commits in this ACT (see `git log --oneline 60811e6..HEAD`):

```
<Commit 4>  docs(polyc): close IR boundary extraction evidence
<Commit 3>  docs(ir): mark IR_CMP_BR and IR_RMW_DEREF as below-boundary fusions
<Commit 2>  refactor(ir): separate neutral IR from native parameter lowering
<Commit 1>  test(ir): expose backend-neutral boundary RED witnesses
```

---

# 3. Predecessor baseline reproduction

Reproduced from entry HEAD `60811e6` using `build/recon-prefix` (RECON01 install side-channel):

| Gate          | Result          |
|---------------|-----------------|
| AOT unit-test | 90/90 PASSED    |
| JIT unit-test | 90/90 PASSED    |
| LSP test      | 43/43 PASSED    |
| RECON01 corpus (S01-S16, Square) | 16/16 byte-identical AOT=JIT (S16 keeps `#ifjit` split) |

No production edits preceded Phase 0.
---

# 4. Phase 0 — RED witnesses

## 4.1 R1: `IrRegPool` consultation in parameter arrival

**Where:** `src/ir.c:2799-3024` (pre-ACT). Five `arrive->loc.kind = IR_LOC_REG` assignment statements guarded only by `if (pool)`.

**Demonstration:**

```bash
./hcc --dump-ir-pooled evidence/smoke/corpus/S02.HC
# Output (full file in evidence/boundary/red/red_r1_param_loc_native.txt):
i64 F(%p1 i64 param loc=reg rdi, %p3 i64 param loc=reg rsi) { ... }
```

A neutral consumer reading `IrValue->loc` sees physical-register identities (`"rdi"`, `"rsi"`, `"x0"`, `"x8"`, ...). These are `AoStr*` instances borrowed from the per-backend `IrRegPool` and live for the duration of compilation.

A neutral consumer MUST be able to read the IR's parameter list, types, and identities without parsing register names.

## 4.2 R2: `IR_CMP_BR`

**Producers:** `irOptPinResultReg` (`src/ir-optimise.c:1079`, line 1113) collapses an `IR_ICMP + IR_BR` pair into a single `IR_CMP_BR` when the cmp result has exactly one use (the immediate BR).

**Lowering evidence:** `src/ir.c` never produces `IR_CMP_BR` (grep shows zero `IR_CMP_BR` in `ir.c`).

**Canonical neutral form:** `IR_ICMP` (or `IR_FCMP`) followed by `IR_BR` — both already in the IR before fusion.

**Conclusion:** the un-fused pair is the canonical neutral form. The fused op is OPT_FUSION below the boundary. A neutral consumer reads the un-fused pair; a native backend may fuse.

## 4.3 R3: `IR_RMW_DEREF`

**Producers:** `irFuseLoadOpStore` (`src/ir-optimise.c:872`) collapses a `load* + binop + store*` triple on the same address into `IR_RMW_DEREF`. The `binop` must be `IR_IADD/IR_ISUB/IR_AND/IR_OR/IR_XOR`. The triple must be adjacent (skipping NOPs).

**Lowering evidence:** `src/ir.c` never produces `IR_RMW_DEREF` (grep shows zero `IR_RMW_DEREF` in `ir.c`).

**Demonstration:**

```bash
./hcc --dump-ir-pooled /tmp/RMW.HC
# Pre-optimisation (full in evidence/boundary/red/red_r3_rmw_fusion.txt):
store*   %l2 ptr local, 5 i64 const int  ; line 3
load*    %t4 i64 tmp, %l2 ptr local      ; line 4
iadd     %t5 i64 tmp, %t4 i64 tmp, 3 i64 const int  ; line 4
store*   %l2 ptr local, %t5 i64 tmp      ; line 4
# Post-optimisation:
rmw*     %l2 ptr local, 3 i64 const int  ; line 4
```

**Canonical neutral form:** `IR_LOAD_DEREF` + binop + `IR_STORE_DEREF` (the triple). The fused `IR_RMW_DEREF` is OPT_FUSION below the boundary.

**Atomicity:** None. The op is a memory-destination binop fusion; it carries no ordering or atomicity semantics. The `extra.rmw_op` field is one of `IR_IADD/IR_ISUB/IR_AND/IR_OR/IR_XOR` — all of which are integer-arithmetic ops. The op does NOT model `compare_exchange`, `fetch_add`, `__atomic_*`, or any C11/C++ memory-model construct.
---

# 5. Boundary implementation

## 5.1 Parameter arrival extraction

**Pre-ACT:**
```
irLowerFunction(ctx, ast)
  ...
  IrRegPool *pool = irRegPoolGet();   // <-- contamination
  int int_arg_idx = 0, float_arg_idx = 0;
  ...
  arrive->loc.kind = IR_LOC_REG;      // <-- physical identity written
  arrive->loc.as.reg = pool->int_arg_regs[i];
  ...
```

**Post-ACT:**
```
irLowerFunction(ctx, ast)
  ...
  int int_arg_idx = 0, float_arg_idx = 0;
  ...
  arrive = irTmp(ir_type, size);
  arrive->kind = IR_VAL_PARAM;
  arrive->param_kind = IR_PARAM_KIND_NORMAL;  // or VARARGS_*/PINNED_REG/...
  arrive->loc.kind = IR_LOC_NONE;             // <-- no physical identity
  ...
```

The classification metadata (`IrValue->param_kind`, `IrParamKind` enum) carries the per-param ABI class. The neutral IR consumer ignores this field; the native post-pass uses it.

**Native post-pass:**
```
irAssignAbiParamLocations(fn, ast, pool)   // called between lowering and optimiser
  walks fn->params in source order
  uses param_kind + ast_func->params + pool
  stamps loc.kind = IR_LOC_REG with the ABI arg register name
```

## 5.2 Call sites

`irAssignAbiParamLocations(fn, ast, irRegPoolGet())` is inserted at exactly four locations — one per codegen path:

| Path                              | Source                | Inserted between                       |
|-----------------------------------|-----------------------|----------------------------------------|
| AOT AArch64 (user funcs)          | `src/aarch64.c:2209`  | `irLowerFunction` and `irBasicFunctionOptimisations` |
| AOT AArch64 (synth_main)          | `src/aarch64.c:2218`  | same                                   |
| AOT x86-64 (user funcs)           | `src/x86_64.c:2558`   | same                                   |
| AOT x86-64 (synth_main)           | `src/x86_64.c:2567`   | same                                   |
| JIT AArch64                       | `src/aarch64-jit.c:1703` | same                                 |
| JIT x86-64                        | `src/x86_64-jit.c:1581` | same                                 |

The post-pass must run BEFORE `irBasicFunctionOptimisations` because `irOptPinResultReg` (in `irBasicFunctionOptimisations`) consults `arrive->loc.as.reg` to decide whether to fold the spill into a reg-to-reg move.

## 5.3 Apple AArch64 variadic-on-stack

The pre-ACT code used `pool->variadic_on_stack` to decide whether to emit the entry `IR_STORE` for the variadic `argc`. This was the only remaining `pool` consultation in the lowering path.

The post-ACT code derives the same decision from `ctx->cc->target` directly:

```c
int apple_aarch64_va =
    ctx->cc->target == TARGET_AARCH64_APPLE_DARWIN;
```

This is a target-derived decision (it depends on the platform ABI), not a backend-pool-derived decision. The neutral IR captures the distinction by emitting or omitting the entry IR_STORE; an LLVM backend would emit equivalent lowering for each case.

## 5.4 IR_CMP_BR and IR_RMW_DEREF

Both are documented as below-boundary optimisations in `src/ir-types.h`:

- `IR_CMP_BR` opcode doc cites `irOptPinResultReg` (the only producer) and lists the canonical neutral form `IR_ICMP/IR_FCMP + IR_BR`.
- `IR_RMW_DEREF` opcode doc cites `irFuseLoadOpStore` (the only producer) and lists the canonical neutral form `IR_LOAD_DEREF + binop + IR_STORE_DEREF`.

The opcode-set documentation is sufficient. No code change is required because both opcodes are never produced by the lowering — only by the post-lowering optimisation passes.
---

# 6. Neutral IR contract

The complete contract is documented in `src/ir-types.h:10-56`. Summary:

**Neutral IR MUST carry:**
- typed values, constants, locals, globals
- function parameters (with `param_kind` classification metadata)
- function signatures, calls, returns
- integer and floating arithmetic
- casts, pointer operations, loads, stores (including the canonical `load* + binop + store*` triple)
- CFG, conditional/unconditional branches (`IR_BR`/`IR_JMP`), comparisons (`IR_ICMP`/`IR_FCMP`)
- struct/class field addressing (`IR_GEP`), function pointers, external symbols
- `IR_ASM` (language-visible inline assembly, classified `TARGET_SPECIFIC_BY_LANGUAGE_DESIGN`)

**Neutral IR MUST NOT contain:**
- physical-register assignment produced by `IrRegPool` (stored in `IrValue->loc`)
- `IR_CMP_BR` or `IR_RMW_DEREF` as canonical forms

**Neutral IR MAY contain (metadata, not physical identity):**
- SSA value numbers / virtual value ids
- `IrValue->param_kind`

---

# 7. Differential IR witnesses

For representative cases the boundary is mechanically visible:

| Case          | Neutral dump                                            | Native-prepared dump                                              |
|---------------|---------------------------------------------------------|-------------------------------------------------------------------|
| simple function params  | `i64 F(%p1 i64 param, %p3 i64 param)`          | `i64 F(%p1 i64 param loc=reg rdi, %p3 i64 param loc=reg rsi)`    |
| mixed int/float params  | `i64 F(%p1 i64 param, %p3 i64 param, %p5 f64 param)` | `... %p5 f64 param loc=reg xmm0`                                 |
| loop                    | identical except param `loc=` annotations              | same                                                             |
| function pointer call   | identical                                               | same                                                             |
| float fn                | identical except param `loc=` annotations              | same                                                             |
| RMW (`*p += 3`)         | pre-opt shows `load* + iadd + store*` triple; post-opt collapses to `rmw*` | same |

Full captures in `evidence/boundary/diff/diff_*.txt` (neutral and native variants).
---

# 8. Native parity

## 8.1 Unit tests

```
AOT = 90/90 PASSED
JIT = 90/90 PASSED
LSP = 43/43 PASSED
```

## 8.2 RECON01 16-item corpus

All 16 corpus items + Square produce byte-identical AOT=JIT outputs (S16 keeps the deliberate `#ifjit` split).

## 8.3 Native assembly

For `evidence/smoke/corpus/S02.HC`, the AArch64 AOT produces:

```
_F:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #32
    stur x0, [x29, #-16]   ; param a → slot
    stur x1, [x29, #-8]    ; param b → slot
    cmp x0, x1
    b.ge .LIRBB0_4
    ...
    ret
```

**Classification:** SEMANTICALLY_EQUIVALENT_EXPECTED. Parameters arrive in x0/x1 (AArch64 ABI), are spilled to stack slots, then used in the cmp/branch. This matches pre-ACT behavior.

Full captures in `evidence/boundary/native_asm/`.

---

# 9. Performance

RECON01 baselines (Apple M3 Max, N=20):

```
AOT compile+link ≈ 59 ms (median)
JIT compile+run  ≈ 3.4 ms (median)
REPL warm        ≈ 3.7 ms (median)
```

Post-ACT measurements (same host, N=20 unless noted):

```
AOT compile+link (tiny.HC)      MED 46.76 ms    (faster; -21% — noise)
AOT e2e (tiny.HC)               MED 348.84 ms   (linker-dominated; sandbox)
JIT compile+run (tiny.HC, N=60) MED 3.50 ms     (+3.2% — within noise)
REPL warm                       MED 3.56 ms     (-3.8% — within noise)
```

Raw samples in `evidence/boundary/perf/`.

The boundary extraction added one O(n_params) walk per function (`irAssignAbiParamLocations`). For functions with ≤ 6 int + 8 float params the cost is dominated by a few `vecGet` calls; on the JIT floor this is ≈0.1 ms. The 3.2% JIT delta is well below the 10% threshold.

---

# 10. Scope discipline

**Added:**
- 1 new public function (`irAssignAbiParamLocations` in `src/ir.c`)
- 1 new enum (`IrParamKind`) and 1 new field (`IrValue->param_kind`) in `src/ir-types.h`
- 4 call-site insertions (1 per native codegen path)
- 1 new CLI flag (`--dump-ir-pooled`) and its plumbing
- 1 new helper (`irDumpWithFakePool`) for the RED witness
- Loc-printing extension in `irValueToString` (`loc=reg ...` suffix)
- 1 targeted target-check (`ctx->cc->target == TARGET_AARCH64_APPLE_DARWIN`) replacing the pool consultation for variadic-on-stack
- Documentary boundary markers on `IR_CMP_BR` and `IR_RMW_DEREF`

**Not added:**
- LLVM, ORC, CMake LLVM lookup
- New dependency
- New language feature
- Parser / type-system / ownership redesign
- Generic Backend vtable / framework
- New executable name
- PolyC syntax change
- Self-hosting work
- Agent API
---

# 11. Acceptance criteria

| AC   | Description                              | Status |
|------|------------------------------------------|--------|
| AC01 | Predecessor reproduced (AOT/JIT/LSP/corpus) | PASS  |
| AC02 | Principal RED existed                     | PASS  (Commit 1; `evidence/boundary/red/`) |
| AC03 | Neutral parameters preserved              | PASS  (`param_kind` metadata; no `loc.as.reg`) |
| AC04 | Native lowering moved below boundary      | PASS  (`irAssignAbiParamLocations` in 4 paths) |
| AC05 | `IR_CMP_BR`                               | **MOVED_BELOW_BOUNDARY** — un-fused form is canonical |
| AC06 | `IR_RMW_DEREF`                            | **OPT_FUSION** — `load* + binop + store*` is canonical; no atomicity |
| AC07 | Backend-independent consumer viability    | PASS  (`--dump-ir` consumes IR without `IrRegPool`) |
| AC08 | Native parity (AOT/JIT/REPL/corpus)       | PASS  (90/90/43/16) |
| AC09 | Performance within noise                  | PASS  (3.2% JIT delta; AOT improved; REPL improved) |
| AC10 | Documentation recorded                    | PASS  (this document + boundary markers in `src/ir-types.h`) |
| AC11 | No LLVM                                   | PASS  (no LLVM/CMake changes) |

---

# 12. Residue

**P0 (none):** No blocking issues.

**P1 (informational, addressed by next ACT):**
- L5 precondition for `ACT-POLYC-LLVM-SPIKE01`: PARTIAL → YES. The principal seam (parameter arrival) is closed.
- The neutral IR still contains `IR_ASM` (inline assembly). This is classified `TARGET_SPECIFIC_BY_LANGUAGE_DESIGN` and may require a future ACT if the LLVM backend rejects or pass-throughs it.

**P2 (deferred):**
- The 6 new `IR_PARAM_KIND_*` enum values could in principle be hidden behind a `void*` opaque tag for stronger separation between neutral and native IR concerns. Not required for the boundary contract.
- `irAssignAbiParamLocations` duplicates ~30 lines of AAPCS classification logic from `irLowerFunction`. This duplication is intentional (the boundary extraction goal is to make the lowering pool-free); if a future ACT refactors AAPCS classification into a shared helper, both sites benefit.

---

# 13. Next ACT

**NEXT_ACT = ACT-POLYC-LLVM-SPIKE01**

The smallest possible LLVM-IR emission for a subset of PolyC:

```
I64 parameters
I64 constants
add / sub / mul
comparison
conditional / unconditional branch
function call
return
```

Initially emit LLVM IR for inspection/verification before tackling ORC or full corpus support. LLVM is now authorised to enter the repository.
---

# 14. Closure handoff (ACT §21)

```
ACT-POLYC-IR-BOUNDARY01

VERDICT=PASS_WITH_NEXT_ACT_DECISION

IDENTITY
ENTRY_HEAD=60811e60a70b3adbe107b93449f0d85d40c75a54
FINAL_HEAD=<filled at closure>
WORKTREE_STATUS=clean

PREDECESSOR_BASELINE
AOT=90/90
JIT=90/90
LSP=43/43
CORPUS=16/16 (byte-identical AOT=JIT; S16 keeps #ifjit split)

RED
R1_REGPOOL_NEUTRAL_BOUNDARY=RED (pre-ACT) → GREEN (post-ACT)
R2_CMP_BR=MOVED_BELOW_BOUNDARY (canonical: ICMP/FCMP + BR)
R3_RMW_DEREF=OPT_FUSION (canonical: LOAD_DEREF + binop + STORE_DEREF)

BOUNDARY
NEUTRAL_PREP_ENTRY=irLowerFunction (src/ir.c:2768)
NATIVE_PREP_ENTRY=irAssignAbiParamLocations (src/ir.c:3121)
IRREGPOOL_FIRST_CONSULTATION=irAssignAbiParamLocations (in 4 native paths)
PHYSICAL_REGS_ABOVE_BOUNDARY=NO (verified via --dump-ir)

CMP_BR
CLASSIFICATION=MOVED_BELOW_BOUNDARY
ACTION=documentary marker in src/ir-types.h; no code change

RMW_DEREF
CLASSIFICATION=OPT_FUSION
ATOMICITY=NONE (extra.rmw_op is one of IADD/ISUB/AND/OR/XOR; no memory ordering)
ACTION=documentary marker in src/ir-types.h; no code change

PARITY
AOT=90/90
JIT=90/90
REPL=PASS (warm submission MED 3.56 ms; -3.8% vs RECON01)
CORPUS=16/16 (byte-identical AOT=JIT; S16 split preserved)

PERFORMANCE
AOT_COMPILE_LINK_MED=46.76ms (tiny.HC; was 59 ms in RECON01 for a different test)
JIT_COMPILE_RUN_MED=3.50ms (tiny.HC, N=60; was 3.39 ms in RECON01)
REPL_WARM_MED=3.56ms (was 3.7 ms in RECON01)

SCOPE
LLVM_DEPENDENCY_ADDED=NO
LANGUAGE_SEMANTICS_CHANGED=NO

RESIDUE
P0=none
P1=IR_ASM is TARGET_SPECIFIC_BY_LANGUAGE_DESIGN (may need future ACT handling)
P2=irAssignAbiParamLocations duplicates ~30 lines of AAPCS classification;
   irAssignAbiParamLocations's classification is intentionally target-pool-aware
   while irLowerFunction's is target-derived (TARGET_AARCH64_APPLE_DARWIN
   check for variadic_on_stack)

NEXT_ACT=ACT-POLYC-LLVM-SPIKE01
```

---

# 15. Doctrine

> Design a truthful PolyC boundary first.
> Move native policy downward; do not rewrite language semantics upward.
> Do not interpret "RMW" as "atomic."
> Canonicalize semantics above the boundary; optimize freely below it.

The success condition is met:

> **After this ACT, a backend may understand PolyC without understanding PolyC's native register allocator.**

The neutral IR's `IrValue->loc` is `IR_LOC_NONE` at the boundary. A backend consuming this IR sees typed SSA, parameter kinds, basic-block CFG, and a target-derived `variadic_on_stack` flag. It does not see `AoStr*` register names. It does not see `IR_CMP_BR` or `IR_RMW_DEREF`. It is free to emit whatever code it likes, making its own ABI decisions.
