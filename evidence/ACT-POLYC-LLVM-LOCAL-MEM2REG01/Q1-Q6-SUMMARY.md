# Q1–Q6 RED evidence summary (ACT-POLYC-LLVM-LOCAL-MEM2REG01)

**Subject tree:** `d2ffe21` (ACT OPEN) → `6059298` (C1 RED,
`ACT-Phase: RED`) → `f45ba38` (C1.5 RED evidence tightening,
`ACT-Phase: RED`) → `57c7ee4` (C2 CLOSE, `ACT-Phase: CLOSE
+ ACT-Verdict: PASS`) → `285a9c0` (C3 RED evidence tightening,
`ACT-Phase: RED`) → `69c886f` (CORRECTION01 RED, opens new ACT id,
`ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01`).
**Date:** 2026-09-10
**Toolchain:** `opt --version` = LLVM 22.1.8 (Nix store)
**Hypothesis under test:** option D from
ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 §11 — lower compiler-
generated scalar local/return slots to LLVM entry-block
allocas with direct loads/stores, then run LLVM's `mem2reg`
pass to construct SSA.

**Reviewer HOLD verdict (post-C1) addressed in C1.5 RED
evidence tightening**: Q1 producer provenance was wrong
(it named a consumer, `irForwardReturnSlot`, as the
producer). C1.5 derives the actual producers from `src/ir.c`
and `src/ir-optimise.c` directly. The function-API C-API
probe was vacuous (ran on an already-promoted module); C1.5
fixes it with two fresh parses. The placement probe was
mislabeled; C1.5 renames it.

**Reviewer HOLD verdict (post-C2) addressed in C3 RED
evidence tightening** (this update): the v2 C-API harness
used `LLVMParseIRInContext`, which consumes the buffer
(per its doc comment), and then `LLVMDisposeMemoryBuffer`
on the success path — a double-free / use-after-free
producing SIGSEGV during cleanup. C3 fixes this with
`LLVMParseIRInContext2` (caller owns the buffer; exactly-
one dispose). All 3 fixtures now exit 0 cleanly. The C2
handoff also prescribed `LLVMSaveInsertPoint` /
`LLVMRestoreInsertPoint`, which are NOT in
`llvm-c/Core.h`; C3 replaces this with a dedicated entry-
block builder (`LLVMCreateBuilderInContext` +
`LLVMPositionBuilderAtEnd(alloca_builder,
LLVMGetEntryBasicBlock(fn))` + `LLVMDisposeBuilder`).
The C2 architectural PASS substance at `57c7ee4` stands;
C3 only tightens the implementation contract.

---

## Q1. Producer surface enumeration (corrected in C1.5)

There are EXACTLY THREE `IR_ALLOCA` emitters in the PolyC
tree. They are not all eligible for option D.

| # | Source site | Slot type | Size | Consumer set | Escapes? | Eligible? |
|---|---|---|---|---|---|---|
| P1 | `irLowerFunction` at `src/ir.c:3042-3047` | scalar (I64 / F64 / I8 / ...) | rettype->size | IR_STORE + IR_LOAD + IR_RET in fn->exit_block | **no** | **YES** (first IMPL slice) |
| P2 | `irFnCallTo` at `src/ir.c:443-448` | aggregate | ast->type->size | IR_LEA → call arg → memcpy | yes (call arg) | NO (REJECT_SCOPE_LOCAL_MEM2REG01) |
| P3 | `irLowerTry` at `src/ir.c:1916-1918` | 256-byte opaque | 256 | IR_LEA → HCC_TryEnter/HCC_TryLeave args | yes (call arg) | NO (REJECT_SCOPE_LOCAL_MEM2REG01) |

**C1.5 correction**: the C1 draft of this table named
`irForwardReturnSlot` (src/ir-optimise.c:256) as a producer.
That is wrong: `irForwardReturnSlot` is a CONSUMER that
rewrites or NOPs an already-existing return-slot pattern; it
does NOT emit any `IR_ALLOCA`. The reviewer demanded
mechanical provenance.

The **bounded candidate class for this ACT** is **P1 only**:
the synthetic scalar return slot emitted by `irLowerFunction`
in `src/ir.c:3042-3047`. It survives neutral-IR optimisation
because `irForwardReturnSlot` (src/ir-optimise.c:256) refuses
the rewrite on exit blocks with >=2 predecessors (the
ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 HALT_SCOPE guard).

**Eligibility discriminator for the future IMPL** (what
`llvm-backend.c` will recognise):

```text
fn->return_value exists (kind == IR_VAL_LOCAL)  AND
fn->exit_block exists                           AND
llDetectCollapsibleReturn(fn, &slot) == 0      AND
    -- i.e. the slot survives irForwardReturnSlot
    -- because the exit block has PN>=2 predecessors
slot->type == IR_TYPE_I64 (scalar I64 only)     AND
single IR_ALLOCA of size 8 at top of entry block
```

This is NOT "arbitrary IR_ALLOCA". The discriminator uses
the same predicate structure `llDetectCollapsibleReturn`
already evaluates, so a future CORRECTION01 can reuse the
existing detection logic without inventing a new
classification.

---

## Q2. Promotability classification

| Candidate | Direct loads/stores only? | Volatile? | Atomic? | Escapes? | Aggregate? | Q2 verdict |
|---|---|---|---|---|---|---|
| `pos_b0_compare_digit` synthetic return slot (I64) | yes | no | no | no | no | **PASS** |
| `i64_collapse_probe` synthetic return slot (I64) | yes | no | no | no | no | **PASS** |
| `single_cond_probe` synthetic return slot (I64) | yes | no | no | no | no | **PASS** |
| P2 `buf_alloca` (array/buffer) | mixed | no | no | usually yes (LEA) | yes | **REJECT_SCOPE_LOCAL_MEM2REG01** (future SROA ACT) |
| P3 `frame_alloca` | mixed | no | no | usually yes | yes | **REJECT_SCOPE_LOCAL_MEM2REG01** |

The three RED fixtures are all PASS. The first authorised IMPL
slice is I64 single-slot scalar local/return slots; other shapes
are DEFERRED.

---

## Q3. Entry-block placement requirement (corrected in C1.5)

**Q3.1** Where does the neutral-IR IR_ALLOCA currently occur
(in the PolyC IR list at the point it would be lowered)?

ANSWER (verified): at the top of the entry block of
`fn->blocks`, immediately after `irBlockAddInstr(ctx,
ir_return_alloca)` at `src/ir.c:3045`. The PolyC IR list
places it before any IR_LABEL of any user block.

**Q3.2** If lowered literally using the current
LLVMBuildAlloca builder position, where does it land in
the resulting LLVM module?

ANSWER (verified): the current spike at
`src/llvm-backend.c:1397-1418` NEVER calls LLVMBuildAlloca
at all -- it only COUNTS IR_ALLOCA reachability as a
reject-class trigger. So today, the answer to Q3.2 is:
there is no LLVM-level alloca to inspect, and CORRECTION01
must introduce one from scratch, into the LLVM module's
function entry block, using a DEDICATED ENTRY-BLOCK BUILDER
per Q3.3 below.

**Q3.3** What insertion-point discipline must
LOCAL-MEM2REG01-CORRECTION01 establish so the resulting
alloca lands in the function entry block?

ANSWER (CORRECTED in C3 RED evidence tightening):
`LLVMSaveInsertPoint` and `LLVMRestoreInsertPoint` are NOT
exposed by `llvm-c/Core.h`. The actual C API surface for
builder positioning is `LLVMPositionBuilder*` +
`LLVMGetInsertBlock` + `LLVMClearInsertionPosition` +
`LLVMDisposeBuilder`. The recommended discipline is
therefore a DEDICATED ENTRY-BLOCK BUILDER:

```c
LLVMBuilderRef alloca_builder =
    LLVMCreateBuilderInContext(lc->ctx);
LLVMPositionBuilderAtEnd(alloca_builder,
                         LLVMGetEntryBasicBlock(fn));

LLVMValueRef slot = LLVMBuildAlloca(
    alloca_builder, LLVMInt64TypeInContext(lc->ctx),
    "polyc.local.slot");
LLVMDisposeBuilder(alloca_builder);
```

The normal lowering builder is left completely untouched.
The two builders have the invariant:

```text
normal builder   -> CFG/instruction lowering
alloca builder   -> entry-block stack-slot materialisation only
```

If the CORRECTION01 IMPL discovers a defect that the
dedicated entry-block builder cannot satisfy, that is
NEW EVIDENCE that triggers a HALT / new recon / new
ACT id — it is NOT a license to mutate the normal
lowering builder. There is NO fallback recipe.

**Q3 placement probe evidence (renamed in C1.5)**

Reviewer correction (post-C1 HOLD): the C1 fixture named
`single_cond_probe_NOT_IN_ENTRY.ll` was misnamed. The
fixture has no preceding basic block, so its `bb1` IS the
function entry block -- LLVM entry-ness is structural, not
driven by the block name. The fixture is a POSITIVE CONTROL
demonstrating that the block-name "entry" is irrelevant.

```text
single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll
    renamed from single_cond_probe_NOT_IN_ENTRY.ll in C1.5
    positive control: alloca structurally in entry block
                     (function's first block, just named bb1)
    opt -passes=mem2reg exits 0
    post-mem2reg IR identical to single_cond_probe.m2r.ll
    (target alloca eliminated, single phi at bb4)
    CONCLUSION: "block name entry" is irrelevant. mem2reg
                only cares that the alloca be in the function
                entry block. The first basic block is the
                entry block regardless of label.

single_cond_probe_NOT_IN_ENTRY_ADVERSARIAL.ll
    unchanged in C1.5
    actual negative witness: alloca placed inside bb3, a
    conditional predecessor of bb2 (the function has bb1
    as entry). The alloca does NOT dominate its only use.
    opt -passes=mem2reg exits 1 with:
        "Instruction does not dominate all uses!
          %slot = alloca i64, align 8
          %t10 = load i64, ptr %slot, align 4"
    CONCLUSION (re-normalized in C6): the placement
                invariant is "the alloca must sit in the
                function's entry block". A backend that
                emits the alloca anywhere other than the
                entry block (e.g. inside a conditional
                predecessor, or after an entry-block
                terminator, or in a non-entry block) fails
                the verifier exactly as this probe does.
                See the placement rule in Q3.3 above.
```
`single_cond_probe_NOT_IN_ENTRY_ADVERSARIAL.ll`): when the
alloca is placed in a conditional block (bb3), the verifier
rejects the module with `Instruction does not dominate all
uses!` (opt exit=1). When placed at the start of the
unconditional entry block (entry), mem2reg promotes cleanly.
**CORRECTION01 must place the alloca in the entry block of the
function.**

**Q3.3** Insertion-point discipline required by CORRECTION01
(re-normalized in C6 RED evidence tightening):

The pseudocode shown in C2's handoff (a save/restore pair on
the existing normal lowering builder) is REMOVED because the
required save/restore primitives do NOT exist in
`llvm-c/Core.h` and the pre-existing Q3.3 corrected recipe
already mandates a DEDICATED ENTRY-BLOCK BUILDER. The
authoritative pseudocode is therefore the dedicated-builder
recipe reproduced verbatim from ACT §6 Q3.3:

```c
LLVMBuilderRef alloca_builder =
    LLVMCreateBuilderInContext(lc->ctx);

LLVMBasicBlockRef entry = LLVMGetEntryBasicBlock(fn);

/* Placement rule:
 *   - prefer: before the first non-alloca instruction
 *     in the entry block (LLVMPositionBuilderBefore)
 *   - else:  append to end of empty entry block
 *     (LLVMPositionBuilderAtEnd)
 *   - never: after an entry-block terminator
 *   - never: in a non-entry block
 * No literal "instruction #1" requirement: mem2reg walks
 * the entry block looking for promotable AllocaInst's. */
LLVMValueRef first_non_alloca = LLVMGetFirstInstruction(entry);
while (first_non_alloca &&
       LLVMIsAAllocaInst(first_non_alloca)) {
    first_non_alloca = LLVMGetNextInstruction(first_non_alloca);
}
if (first_non_alloca) {
    LLVMPositionBuilderBefore(alloca_builder, first_non_alloca);
} else {
    LLVMPositionBuilderAtEnd(alloca_builder, entry);
}

LLVMValueRef slot = LLVMBuildAlloca(
    alloca_builder, LLVMInt64TypeInContext(lc->ctx),
    "polyc.local.slot");
LLVMDisposeBuilder(alloca_builder);
```

The new helper will live in `src/llvm-backend.c`
(CORRECTION01 scope). The normal lowering builder is left
completely untouched.

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

## Q4.1 Module-API vs Function-API C-API probe (independent)

Reviewer correction (post-C1 HOLD): the C1 version of this
probe ran the module API first and then the function API on
the SAME (already-promoted) module. That proved only that
the function API is a no-op on already-promoted IR -- NOT
that the function API actually promotes unpromoted IR.

The C1.5 harness (`capi_probe.c` v2) parses each fixture
TWICE from disk into independent modules, runs only the
module API on the first copy, runs only the function API on
the second copy, and prints both post-pipeline IRs to stdout
from `LLVMPrintModuleToString`. The captured stdout IS what
the C API produced (no `opt`->copy step).

| Fixture | LLVMRunPasses (fresh parse A) | LLVMRunPassesOnFunction (fresh parse B) |
|---|---|---|
| `single_cond_probe.ll` | **PASS** (alloca gone, phi at bb4, verifier clean) | **PASS** (alloca gone, phi at bb4, verifier clean) |
| `i64_collapse_probe.ll` | **PASS** (3-edge phi at bb4) | **PASS** (3-edge phi at bb4) |
| `pos_b0_compare_digit.ll` | **PASS** (3-edge phi at bb4) | **PASS** (3-edge phi at bb4) |

**C-API MODULE API (fresh parse): PASS** on all 3 fixtures.
**C-API FUNCTION API (fresh parse): PASS** on all 3 fixtures.

**Both post-pipeline IRs are captured verbatim in
`<fixt>.capi-stdout.txt`**, each in its own tagged section
(`===== MODULE-API RESULT (fresh parse, LLVMRunPasses only) =====`
and `===== FUNCTION-API RESULT (fresh parse, LLVMRunPassesOnFunction only) =====`).
The captured IRs are byte-for-byte identical between the two
APIs, which is the expected outcome: both APIs run the same
new-pass-manager pipeline and produce equivalent SSA.

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
functions. C1.5 evidence now proves (not merely asserts)
that the function API actually performs promotion on a fresh
unpromoted module.

**Implementation note on harness cleanup**: the v2 harness
currently SIGSEGVs during cleanup (after both verdict lines
are printed and both IR sections are flushed to stdout). The
verdict is captured correctly because:

- `stderr` is unbuffered by default, so the verdict lines
  are emitted before the crash.
- `print_module` calls `fflush(stdout)` after each
  `LLVMPrintModuleToString` capture, so the IR stdout is
  flushed to the file before the dispose sequence.

The crash is in the harness dispose sequence, not in the
`LLVMRunPasses` / `LLVMRunPassesOnFunction` call paths. The
recommendation to use `LLVMRunPassesOnFunction` in
CORRECTION01 is therefore still supported by the captured
verdict and the captured post-pipeline IR.

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

**Q1 PASS.** Three `IR_ALLOCA` emitters exist in `src/`;
only **P1** (`irLowerFunction` at `src/ir.c:3042-3047`,
synthetic scalar return slot) is eligible. P2
(`irFnCallTo` aggregate callee buffer) and P3 (`irLowerTry`
256-byte CatchFrame) are REJECT_SCOPE_LOCAL_MEM2REG01.
The bounded eligibility discriminator for the future
IMPL is derived from `llDetectCollapsibleReturn` + scalar
I64 type + single alloca at top of entry block.

**Q2 PASS.** All three RED-fixture slots are PASS (single-slot
scalar, direct, non-volatile, non-escaping, non-aggregate).

**Q3 PASS.** Placement requirement is determined: entry-block
alloca, with a DEDICATED ENTRY-BLOCK BUILDER discipline
prescribed for CORRECTION01 (see Q3.3 corrected recipe:
`LLVMCreateBuilderInContext` +
`LLVMPositionBuilderAtEnd(alloca_builder,
                         LLVMGetEntryBasicBlock(fn))` +
`LLVMDisposeBuilder`). The C2 handoff had prescribed a
save/restore insertion-point discipline using
`LLVMSaveInsertPoint` / `LLVMRestoreInsertPoint`; that
discipline references primitives that do NOT exist in
`llvm-c/Core.h` and was replaced by the dedicated-builder
recipe in C3 and re-normalized in C6. Positive control
fixture (single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll)
confirms the block-name "entry" is irrelevant. Negative
witness fixture
(single_cond_probe_NOT_IN_ENTRY_ADVERSARIAL.ll) confirms
that a misplaced alloca breaks the verifier with
"Instruction does not dominate all uses!".

**Q4 PASS.** Architectural probe succeeds for all three
fixtures with the project's LLVM 22.1.8: opt -passes=mem2reg
exits 0, opt -passes=verify exits 0, target alloca
eliminated, target mem ops eliminated, single phi at the
natural successor block.

**Q4.1 PASS (independent).** `LLVMRunPasses` and
`LLVMRunPassesOnFunction` are run on TWO FRESHLY-PARSED
copies of each fixture (independent modules, no shared
state). Both APIs PASS on all three fixtures; both
post-pipeline IRs are captured verbatim from
`LLVMPrintModuleToString` (with `fflush(stdout)`); the
captured IRs are byte-for-byte identical between the two
APIs. Error path observed on both APIs via
`LLVMRunPasses("mem2reggg,verify", ...)` →
"unknown pass name 'mem2reggg'" and
`LLVMRunPassesOnFunction(fn, "mem2reggg,verify", ...)` →
"unknown function pass 'mem2reggg' in pipeline 'mem2reggg'".
Header `llvm-c/Transforms/PassBuilder.h` present at the
project's LLVM 22.1.8 include dir; link surface is
clean against `-lLLVM-22`.

**Q5 PASS.** LLVM mem2reg constructs a single phi at the
natural successor block (`bb4` for `single_cond_probe`,
with two per-edge operands; `bb4` for `i64_collapse_probe`,
with three per-edge operands; `bb4` for
`pos_b0_compare_digit`, with three per-edge operands).
The per-edge operands match the original PolyC semantics.

**Q6 PASS.** All three RED fixtures are I64 at the slot.
Future IMPL freeze is I64 single-slot scalar only.

**Option D is RECONFIRMED.** Recommend opening
`ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01` for the
bounded IMPL freeze (LLVMRunPassesOnFunction +
entry-block alloca + I64 scalar only, with the
Q1-derived eligibility discriminator).

## Phase grammar correction (appended at CORRECTION01 RED)

The earlier version of this file stated: "NOTE: 'EVIDENCE'
is descriptive prose, NEVER a Factory phase; the trailer
is authority." That wording was a paraphrase of the C3
commit message (285a9c0), which incorrectly narrowed
the Factory v2 phase grammar to `RED | IMPL | CLOSE`.

The actual Factory v2 phase grammar is
`RED | IMPL | EVIDENCE | CLOSE`, as enforced by
`scripts/quality/factory-v2-commit-msg-check.sh` and
as exercised by the regression suite
(`scripts/quality/factory-v2-test.sh` T14 explicitly
tests a `RED→IMPL→EVIDENCE→IMPL→CLOSE` range as PASS).
The canonical factory doctrine in
`docs/factory/GIT-METADATA.md` also lists the 4-phase
grammar.

The corrected framing for the LOCAL-MEM2REG01 family:

* the grammar is `RED | IMPL | EVIDENCE | CLOSE`;
* C1, C1.5, and C3 all carry `ACT-Phase: RED`;
* under a strict reading, C1.5 and C3 (both
  evidence-tightening) would carry `ACT-Phase:
  EVIDENCE`; under a permissive reading they remain
  `RED`. Both readings are valid; we use the
  permissive reading for historical continuity with
  C1's RED trailer;
* the trailer is the authoritative phase label;
  prose labels in commit subjects, ROADMAP rows, and
  Q1-Q6-SUMMARY may use any descriptive text but
  must not contradict the trailer.

See ACT §13 for the full corrected wording.
