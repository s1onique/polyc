# Q1–Q6 RED evidence summary (ACT-POLYC-LLVM-LOCAL-MEM2REG01)

**Subject tree:** `d2ffe21` (ACT OPEN) → C1 RED commit (this commit)
**Date:** 2026-09-10
**Toolchain:** `opt --version` = LLVM 22.1.8 (Nix store)
**Hypothesis under test:** option D from
ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 §11 — lower compiler-
generated scalar local/return slots to LLVM entry-block
allocas with direct loads/stores, then run LLVM's `mem2reg`
pass to construct SSA.

---

## Q1. Producer surface enumeration

Three candidate sites exist for `IR_ALLOCA` in `src/`:

| Site | Source location | Slot type | Producer | Consumers | Escapes? |
|---|---|---|---|---|---|
| `irAlloca(AstType*)` | `src/ir.c:72` | depends on AstType | `buf_alloca` at `src/ir.c:443` (array/buffer), `ir_return_alloca` at `src/ir.c:3043` (return-by-value small aggregates) | various IR_LOAD / IR_STORE | usually yes (address binds via IR_LEA) |
| `frame_alloca` | `src/ir.c:1916` | depends on size | `irCgBindAstLoffs` | various IR_LOAD / IR_STORE | usually yes (frame address binds) |
| Forwarder-emitted `IR_ALLOCA` | `src/ir-optimise.c::ir_forwardReturnSlot` | synthetic return slot, I64 | RSF01 §4 produces this candidate only on multi-predecessor exit blocks | exit-block IR_LOAD of the slot, then IR_RET | **no** (slot consumed locally) |

The **bounded candidate class for this ACT** is the third row:
the IR_ALLOCA arriving from the forwarder's multi-predecessor
exit case. It is I64 at the slot (the byte source for
`pos_b0_compare_digit` is `zext`-promoted to I64 before the
slot write).

The other two sites are **out of scope** for this ACT:

- `buf_alloca` / `ir_return_alloca` carry an array or aggregate
  type and/or escape. They are REJECTed by Q2 (aggregate →
  `REJECT_SCOPE_LOCAL_MEM2REG01`; escape → `REJECT_PRODUCT_BOUNDARY`).
- `frame_alloca` similarly escapes.

---

## Q2. Promotability classification

| Candidate | Direct loads/stores only? | Volatile? | Atomic? | Escapes? | Aggregate? | Q2 verdict |
|---|---|---|---|---|---|---|
| `pos_b0_compare_digit` synthetic return slot (I64) | yes | no | no | no | no | **PASS** |
| `i64_collapse_probe` synthetic return slot (I64) | yes | no | no | no | no | **PASS** |
| `single_cond_probe` synthetic return slot (I64) | yes | no | no | no | no | **PASS** |
| `buf_alloca` (array/buffer) | mixed | no | no | usually yes (LEA) | yes | **REJECT_SCOPE_LOCAL_MEM2REG01** (future SROA ACT) |
| `frame_alloca` | mixed | no | no | usually yes | yes | **REJECT_PRODUCT_BOUNDARY** (PolyC language semantic; future ACT only) |

The three RED fixtures are all PASS. The first authorised IMPL
slice is I64 single-slot scalar local/return slots; other shapes
are DEFERRED.

---

## Q3. Entry-block placement requirement

**Q3.1** Where does the neutral-IR IR_ALLOCA currently occur?

The synthetic return slot's IR_ALLOCA is materialised in the
**exit block** of the forwarder's multi-predecessor shape
(after PolyC's basic optimisations, this is bb4 in each of
the three fixtures). The IR_ALLOCA's entry into the LLVM
backend is at `src/llvm-backend.c:1397-1418` (the spike-stage
accept site).

**Q3.2** If lowered literally using the current builder position,
where does it land?

**It never lands.** The current spike at `src/llvm-backend.c:1397-
1418` only checks for the presence of an `IR_ALLOCA` whose dst
matches `lc->collapse_slot`; it never calls `LLVMBuildAlloca`.
The alloca is rejected with `LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL`
before any LLVM-level alloca is constructed.

**Empirical confirmation** (probe
`single_cond_probe_NOT_IN_ENTRY_ADVERSARIAL.ll`): when the
alloca is placed in a conditional block (bb3), the verifier
rejects the module with `Instruction does not dominate all
uses!` (opt exit=1). When placed at the start of the
unconditional entry block (entry), mem2reg promotes cleanly.
**CORRECTION01 must place the alloca in the entry block of the
function.**

**Q3.3** Insertion-point discipline required by CORRECTION01:

```c
// pseudocode for the future CORRECTION01 IMPL
LLVMBasicBlockRef entry = LLVMGetEntryBasicBlock(fn);
LLVMPositionBuilderAtStart(B, entry);
LLVMValueRef slot = LLVMBuildAlloca(B, LLVMInt64Type(), "polyc.slot");
// restore builder to its prior position
```

This is a save/restore pair around `LLVMBuildAlloca`. The new
helper will live in `src/llvm-backend.c` (CORRECTION01 scope).

---


## Q4. Architectural probe (mandatory before IMPL)

**Pipeline:** `opt -passes=mem2reg <in.ll> -S -o <out.ll>` then
`opt -passes=verify <out.ll> -S -o /dev/null`.

| Fixture | pre-mem2reg verify | mem2reg exit | post-mem2reg verify | alloca eliminated? | mem ops eliminated? | phi observed? |
|---|---|---|---|---|---|---|
| `single_cond_probe.ll` | exit=0 | exit=0 | exit=0 | YES | YES | YES — single phi in `bb4` with 2 operands |
| `i64_collapse_probe.ll` | exit=0 | exit=0 | exit=0 | YES | YES | YES — single phi in `bb4` with 3 operands |
| `pos_b0_compare_digit.ll` | exit=0 | exit=0 | exit=0 | YES | YES | YES — single phi in `bb4` with 3 operands |

**All three fixtures PASS the architectural probe.**

Post-mem2reg IR is preserved at
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/probes/<fixt>.m2r.ll`.

Full probe transcripts (stderr + stdout) are at
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/probes/<fixt>.m2r.stderr`
and `<fixt>.m2r.ll`.

---

## Q4.1 Module-API vs Function-API C-API probe

A minimal C harness
(`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/capi_probe.c`)
links against the project's LLVM 22.1.8 distribution and
exercises both API paths on each of the three fixtures.

| Fixture | LLVMRunPasses("mem2reg,verify") | LLVMRunPassesOnFunction("mem2reg,verify") |
|---|---|---|
| `single_cond_probe.ll` | **PASS** (no error) | **PASS** (no error) |
| `i64_collapse_probe.ll` | **PASS** | **PASS** |
| `pos_b0_compare_digit.ll` | **PASS** | **PASS** |

**C-API MODULE API:  PASS** (verified on all three fixtures;
LLVMRunPasses returns no error, post-pipeline IR is correctly
mem2reg-promoted, verifier passes inside the pipeline.)

**C-API FUNCTION API: PASS** (verified on all three fixtures;
LLVMRunPassesOnFunction returns no error, post-pipeline IR is
correctly mem2reg-promoted, verifier passes inside the pipeline.)

**C-API ERROR PATH OBSERVED: yes.** When given a deliberately
bad pipeline string (`mem2reggg`), both `LLVMRunPasses` and
`LLVMRunPassesOnFunction` return a non-NULL `LLVMErrorRef`:

```
LLVMRunPasses:           "unknown pass name 'mem2reggg'"
LLVMRunPassesOnFunction: "unknown function pass 'mem2reggg' in pipeline 'mem2reggg'"
```

CORRECTION01 MUST consume/report this error path; treating
pass execution as infallible would silently swallow bad-
pipeline failures at runtime.

**Header availability**: `llvm-c/Transforms/PassBuilder.h`
is present at
`/nix/store/b6fykfvclbq81yis03blk6bqsmapmhdm-llvm-22.1.8-dev/include/llvm-c/Transforms/PassBuilder.h`
(version 22.1.8). The project does not yet include it; that
inclusion is a CORRECTION01 IMPL task.

**Link surface**: against `-lLLVM-22`, both APIs and
`LLVMCreatePassBuilderOptions` / `LLVMDisposePassBuilderOptions`
link cleanly. No additional libs needed beyond the project's
existing `libLLVM-22` link.

**Recommendation for CORRECTION01 IMPL**: use
`LLVMRunPassesOnFunction` (function-scoped). Rationale: the
forwarder's multi-predecessor case is per-function; running
the pipeline module-wide would needlessly re-process unrelated
functions. (Either API is mechanically sound; this is a product
boundary.)

---

## Q5. Observed SSA merge form (single_cond_probe)

Post-mem2reg IR for `single_cond_probe.ll`:

```llvm
define i64 @Probe(i64 %p1, ptr %p3) {
entry:
  %l6 = load i64, ptr %p3, align 4
  %t8 = icmp sge i64 %l6, 10
  br i1 %t8, label %bb3, label %bb4

bb3:                                              ; preds = %entry
  %slot.bb3.next = add i64 %p1, %l6
  br label %bb4

bb4:                                              ; preds = %bb3, %entry
  %slot.0 = phi i64 [ %slot.bb3.next, %bb3 ], [ %p1, %entry ]
  br label %bb2

bb2:                                              ; preds = %bb4
  ret i64 %slot.0
}
```

**Observed**: a single phi instruction in the natural
successor block (`bb4`), with two per-edge operands. The
SSA-rename of the original `%slot` SSA value (`%slot.0`) is
a result of LLVM's standard SSA naming; the underlying
storage has been eliminated.

**Semantic preservation**: `bb2` returns `%slot.0`. On the
path where control flows through `bb3`, `%slot.0` is
`%slot.bb3.next = %p1 + %l6`. On the path where control
falls through directly from `entry`, `%slot.0` is `%p1`.
This matches the original PolyC semantics: on the bb3 path,
the return value is the original `p1` plus the loaded `l6`;
on the bb4-direct path, the return value is `p1`.

**No `select` is produced** because the merge is at a join
block with multiple predecessors, which is the canonical
case for a phi. LLVM mem2reg produces a phi because that is
the canonical SSA merge form for multiple-reaching-
definition promotion.

---

## Q6. I64-only type scope

| Fixture | Slot type | Byte source |
|---|---|---|
| `pos_b0_compare_digit` | I64 | I8 (`zext`-promoted to I64 before slot write) |
| `i64_collapse_probe` | I64 | n/a |
| `single_cond_probe` | I64 | n/a |

All three RED fixtures are I64 at the slot. The future IMPL
freeze is therefore I64 single-slot scalar local/return slots
only. I8 allocas are DEFERRED unless a separate BYTE-MEMORY01-
follow-on fixture proves they are needed (P1 residue).

---

## Conclusion

**Q1 PASS.** Three RED-fixture slots are the bounded candidate
class; other IR_ALLOCA sites are out of scope or REJECTed.

**Q2 PASS.** All three candidates are PASS (single-slot
scalar, direct, non-volatile, non-escaping).

**Q3 PASS.** Placement requirement is determined: entry-block
alloca, with a save/restore insertion-point discipline
prescribed for CORRECTION01.

**Q4 PASS.** Architectural probe succeeds for all three
fixtures with the project's LLVM 22.1.8.

**Q4.1 PASS.** Both `LLVMRunPasses` and `LLVMRunPassesOnFunction`
parse and execute `"mem2reg,verify"` cleanly on all three
fixtures. Error path observed and documented.

**Q5 PASS.** LLVM mem2reg constructs a single phi at the
natural successor block (`bb4` for `single_cond_probe`),
with per-edge operands that match the original PolyC semantics.

**Q6 PASS.** All three RED fixtures are I64 at the slot.
Future IMPL freeze is I64 single-slot scalar only.

**Option D is RECONFIRMED.** Recommend opening
`ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01` for the bounded
IMPL freeze.
