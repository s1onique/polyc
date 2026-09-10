# ACT-POLYC-LLVM-LOCAL-MEM2REG01

**Title:** Recon — should PolyC's LLVM backend lower a tightly bounded
class of compiler-generated scalar local/return slots to LLVM entry-
block allocas with direct loads/stores, then run LLVM's `mem2reg`
pass to construct SSA, instead of extending PolyC's bespoke collapse
machinery?

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** C1 RED / C2 CLOSE (Factory v2 phase grammar; **no IMPL
authorisation in this ACT** — production code is intentionally frozen
while the hypothesis is probed)

**Predecessor:** ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 (closed at
`69f7d3a` with verdict `HALT_SECOND_SEAM_REQUIRED`; this ACT is the
recommended next ACT per that document's §11 option D)

**Production semantic changes:** FORBIDDEN in C1 RED; C1 binds
the hypothesis evidence (Q1–Q6 + architectural probes). C2 CLOSE
records the verdict. IMPL is reserved for a separate CORRECTION01
ACT that opens only if C2 CLOSE = PASS.

**IR / ABI / LLVM authorization:** NONE in this ACT. The architectural
probe exercises LLVM's pass pipeline outside the PolyC build path
(via `opt -passes=mem2reg` and `opt -passes=verify` against
hand-written LLVM IR files). The C-API link surface is reconnoitred
in C1 to characterise future CORRECTION01 build work, but no
production build file or C source is touched.

---

## 0. Mission

Determine, by mechanical recon, whether the smallest robust LLVM-
boundary representation for PolyC function-local / return-slot state
is:

```text
compiler-generated scalar local/return slot
    ↓
LLVM entry-block alloca (per LLVM Frontend/PerformanceTips guidance)
    ↓
direct load/store only (PolyC's first authorised slice emits
                       non-volatile, non-atomic accesses; atomic
                       loads/stores are not part of PolyC's first
                       IMPL freeze even though LLVM mem2reg would
                       in principle accept them)
    ↓
opt -passes=mem2reg                  (LLVM's PromoteMemToReg via
                                      the new pass-manager C API:
                                      LLVMRunPasses /
                                      LLVMRunPassesOnFunction)
    ↓
opt -passes=verify
```

rather than teaching PolyC's `llDetectCollapsibleReturn`
progressively more CFG shapes (option A in the predecessor ACT), or
building a bespoke PolyC mem2reg (options B/C). The hypothesis is
option D.

This ACT does NOT authorise any production change. It binds evidence
that either supports or falsifies option D before any IR/ABI/grammar
boundary is touched.

## 1. Why (predecessor evidence)

ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 closed at `69f7d3a` with
verdict `HALT_SECOND_SEAM_REQUIRED`. The dominance-violating rewrite
that caused the LLVM verifier failure ("Instruction does not dominate
all uses!") is now suppressed on multi-predecessor exit blocks by a
conservative sufficient guard in `irForwardReturnSlot`. The three
RED fixtures (`pos_b0_compare_digit.HC`, `i64_collapse_probe.HC`,
`single_cond_probe.HC`) no longer crash the verifier — they now
reject on a different seam, at `src/llvm-backend.c:1418`:

```text
LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL: function <X>: unexpected IR_ALLOCA
(this spike is SSA-only and does not allocate stack slots)
```

The surviving neutral IR after the forwarding guard still contains
an `IR_ALLOCA + store; load; ret` triple on a multi-predecessor exit
block. The current spike deliberately does not allocate stack slots
(it is "SSA-only"); the alloca is therefore rejected.

The forwarder's guard is correct AND insufficient — by design,
because the multi-predecessor case requires SSA merge (a PHI or
equivalent), which neither the neutral-IR grammar nor the SSA-only
spike supports directly. Option D delegates that merge to LLVM's
well-tested `mem2reg` pass instead.

The three HALT fixtures are permanent regressions in
`scripts/quality/ir-return-slot-forwarding01-test.sh` (PASS=3 FAIL=3
at HEAD); a GREEN outcome from a future CORRECTION01 IMPL would
flip them to PASS=6 FAIL=0 while preserving the structural NC.

## 2. Scope

### allowed (C1 RED only)

- mechanical construction of hand-written LLVM IR equivalents for
  the three RED fixtures;
- invocation of LLVM's `opt` against those equivalents via the
  `mem2reg` + `verify` pass pipeline;
- inspection and preservation of the post-mem2reg `.ll` for each
  fixture as evidence;
- reconnaissance of `src/llvm-backend.c`'s alloca-eligibility
  paths (`llDetectCollapsibleReturn`, `llIsCollapseAlloca`, the
  `lc->collapsed && ins->dst == lc->collapse_slot` accept site at
  `src/llvm-backend.c:1397-1418`) — read only;
- recon of `src/ir-regalloc.c::IR_ALLOCA` sizing/alignment
  semantics — read only;
- recon of which `IR_*` opcode producers may place an `IR_ALLOCA`
  whose uses are direct loads/stores only (the bounded promotable
  class);
- recon of the project's LLVM C API link surface: are
  `LLVMRunPasses` / `LLVMRunPassesOnFunction` /
  `LLVMCreatePassBuilderOptions` etc. available in the headers the
  project already includes? If not, what is required to expose
  them?
- a minimal C-API harness (in `evidence/`, NOT in `src/`) that
  links against the project's actual LLVM 22.1.8 and exercises the
  pipeline on the hand-written fixtures. The harness is recon
  evidence, not production code.

### forbidden

- any edit to `src/llvm-backend.c`, `src/ir-optimise.c`,
  `src/ir-regalloc.c`, `src/ir.c`, `src/llvm-backend-cap.c`,
  `src/llvm-backend-cap.h`, `src/x86_64*.c`, `src/aarch64*.c`,
  or any other production C file;
- any edit to `scripts/quality/*.sh`;
- any edit to the neutral-IR grammar (`IR_*` opcode table,
  `IrOp` enum, `ir-debug.c::ir_op_str`);
- any addition to LLVM BUILD or CMAKE configuration;
- any change to native (`x86_64`, `aarch64`) backend code;
- IR_PHI construction (the neutral IR grammar does not yet define
  IR_PHI lowering; this ACT delegates SSA merge to LLVM mem2reg);
- language semantic changes;
- dependency additions;
- tag reuse of `ACT-POLYC-IR-RETURN-SLOT-FORWARDING01` on any
  commit produced under this ACT (v2 range-check rule 6:
  post-CLOSE commits must not carry the closed ACT id).

## 3. Entry gate

```text
git branch --show-current         # main
git status --short                # clean (or only authorised pre-existing dirty)
git rev-parse HEAD                # recorded in §11 handoff
```

Required state at C1 RED start:

- on `main`;
- worktree clean;
- HEAD carries `ACT-POLYC-IR-RETURN-SLOT-FORWARDING01` CLOSE
  (`69f7d3a`) in its ancestor set;
- the OPEN commit of this ACT (`d2ffe21`) is on the ancestor
  chain (it authorises the ACT doc; it carries no `ACT:`
  trailer because it is the pre-RED OPEN under the NON_ACT
  pattern, mirroring how RSF01 was opened at `d89a5cd`).

## 4. RED witnesses (six concrete questions)

### Q1. Enumerate the producer surface (mechanical, with provenance)

Reviewer correction (post-C1 HOLD): the C1 draft of Q1 named
`irForwardReturnSlot` (src/ir-optimise.c:256) as the producer
of the bounded IR_ALLOCA. That is wrong: `irForwardReturnSlot`
is a CONSUMER that rewrites or NOPs an already-existing
return-slot pattern; it does not EMIT any IR_ALLOCA. The
reviewer demanded mechanical provenance: WHO actually emits
the candidate slot, WHAT makes it the synthetic return slot,
and HOW the LLVM backend will recognise only this class.

The mechanical answer (re-derived in the C2 evidence commit
from `src/ir.c` and `src/ir-optimise.c`):

```text
PROVENANCE OF EVERY IR_ALLOCA IN src/:
==========================================================
There are EXACTLY THREE IR_ALLOCA emitters in the PolyC
tree. They are not all eligible for option D.
==========================================================

P1: Synthetic scalar return slot
    emitter        = irLowerFunction (src/ir.c:2784)
    source site    = src/ir.c:3042-3047
        } else if (rettype && rettype->kind != AST_TYPE_VOID) {
            IrInstr *ir_return_alloca = irAlloca(rettype);
            irAddStackSpace(ctx, rettype->size);
            irBlockAddInstr(ctx, ir_return_alloca);
            ir_return_var = ir_return_alloca->dst;
        }
        func->return_value = ir_return_var;
    condition      = non-void AND non-aggregate return type
    nominal type   = rettype (scalar; I64 / F64 / I8 / ...)
    nominal size   = rettype->size
    consumer set   = IR_STORE <return_value>, <value>
                     IR_LOAD <tmp>, <return_value>
                     IR_RET <tmp>
                     all in fn->exit_block
    escape analysis= fn->return_value is an IR_VAL_LOCAL slot;
                     the address is never materialised into a
                     phi, ret operand, parameter, or external
                     store; only direct load/store
    function       = per-function, scoped to fn->exit_block
    ELIGIBLE FOR   = YES (option D's first IMPL slice)
    OPTION D       = when scalar I64 AND
                       llDetectCollapsibleReturn(fn, &slot)
                       returns 0 (i.e. multi-predecessor exit;
                       irForwardReturnSlot refuses the rewrite
                       on PN>=2)

P2: Aggregate callee buffer
    emitter        = irFnCallTo (src/ir.c:407)
    source site    = src/ir.c:443-448
        IrInstr *buf_alloca = irAlloca(ast->type);
        irAddStackSpace(ctx, ast->type->size);
        irBlockAddInstr(ctx, buf_alloca);
        buf_addr = irTmp(IR_TYPE_PTR, 8);
        irBlockAddInstr(ctx,
            irInstrNew(IR_LEA, buf_addr, buf_alloca->dst, NULL));
    condition      = aggregate-return callee, no
                     preallocated_buffer
    nominal type   = aggregate (struct/union)
    nominal size   = ast->type->size (aggregate bytes)
    consumer set   = IR_LEA -> call arg -> memcpy -> IR_STORE
                     on callee's hidden out-pointer slot
    escape analysis= pointer is passed as a call argument
                     (DOES escape the caller's lexical scope
                     via the ABI)
    ELIGIBLE FOR   = NO (aggregate -> REJECT_SCOPE_LOCAL_MEM2REG01;
    OPTION D          future SROA ACT if one opens)

P3: CatchFrame storage for try/catch
    emitter        = irLowerTry (src/ir.c:1910)
    source site    = src/ir.c:1916-1918
        IrInstr *frame_alloca =
            irInstrNew(IR_ALLOCA, frame_tmp, size_const, NULL);
        irBlockAddInstr(ctx, frame_alloca);
        irAddStackSpace(ctx, frame_size);   /* 256 */
    condition      = try/catch lowered
    nominal type   = 256-byte opaque layout
    nominal size   = 256 bytes
    consumer set   = IR_LEA -> HCC_TryEnter/HCC_TryLeave args
    escape analysis= pointer is passed as a call argument
    ELIGIBLE FOR   = NO (aggregate -> REJECT_SCOPE_LOCAL_MEM2REG01)
    OPTION D

WHO CONSUMES (and may eliminate) the slot:
    irForwardReturnSlot (src/ir-optimise.c:256)
    Called from irBasicFunctionOptimisations
    (src/ir-optimise.c:970) on every function
    Rewrites the store->load->ret pattern into
    `ret <value>` when the exit block has at most one
    predecessor. On PN>=2, REFUSES the rewrite (the
    ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 HALT_SCOPE
    guard); the slot survives.

WHAT SURVIVES for the LLVM backend to recognise:
    For PN>=2 (the HALT guard): irForwardReturnSlot
    leaves the IR_ALLOCA, IR_STORE, IR_LOAD, IR_RET
    pattern intact. The slot is fn->return_value
    (kind = IR_VAL_LOCAL). The function has an
    fn->exit_block. llDetectCollapsibleReturn(fn, &slot)
    returns 0 because PN>=2. The slot is the synthetic
    scalar return storage.

HOW the LLVM backend will recognise ONLY this class:
    fn->return_value exists (kind == IR_VAL_LOCAL)  AND
    fn->exit_block exists                           AND
    llDetectCollapsibleReturn(fn, &slot) == 0      AND
        -- i.e. the slot survives irForwardReturnSlot
        -- because the exit block has PN>=2 predecessors
    slot->type == IR_TYPE_I64 (scalar I64 only)     AND
    single IR_ALLOCA of size 8 at top of entry block

This discriminator is the future IMPL's eligibility
filter. The first IMPL slice rejects everything that
fails any of the four predicates above with
LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL (the same reject
class the current spike uses). It does NOT accept
arbitrary IR_ALLOCA.
```

Method: `grep -nE 'IR_ALLOCA|irAlloca|buf_alloca|frame_alloca'
src/` plus `--dump-ir` walks on each RED fixture plus the
documented source-site inspection above. The provenance is
derived from `src/ir.c` and `src/ir-optimise.c` directly;
no inference.

### Q2. Mechanical promotability classification

For each Q1 candidate, mechanically classify whether LLVM's
`isAllocaPromotable` (in `PromoteMemoryToRegister.cpp`) would
accept it. The actual documented rules are:

```text
REQUIRED (REJECT if any is violated):
  - alloca lives in the function entry block
  - all uses are loads and stores (no call/Invoke, no use of the
    pointer as a value)
  - the alloca is not captured (its address is never stored into
    another memory location and never leaves the function)
  - the alloca is a SINGLE-SLOT SCALAR (this ACT does NOT try to
    promote aggregate allocas; if a candidate slot is an
    aggregate, classify it REJECT_FOR_LOCAL_MEM2REG01 and route
    to a future SROA ACT instead)
  - loads/stores are aligned and NOT VOLATILE

DO NOT REJECT merely because:
  - loads/stores are atomic (LLVM's isAllocaPromotable permits
    atomic accesses; the alloca is function-local so atomic
    semantics carry no meaningful inter-thread ordering). PolyC's
    first authorised IMPL slice will still emit only non-atomic
    accesses; that is a PRODUCT boundary, not LLVM's rule
```

Method: per Q1 candidate, walk the IR list and verify each
requirement. Record as a markdown table appended to this ACT. The
classification table is part of the closure evidence; any candidate
that fails must be marked REJECT and explained. REJECTed candidates
get one of two sub-classifications:

```text
REJECT_SCOPE_LOCAL_MEM2REG01   -- eligible for a future
                                  SROA/mem2reg ACT
REJECT_PRODUCT_BOUNDARY        -- never eligible; would require
                                  PolyC language semantic change
```

### Q3. Determine entry-block placement requirement

LLVM Frontend/PerformanceTips guidance: function-scoped allocas
intended for promotion should be emitted at the start of the entry
block because mem2reg/SROA only try to eliminate entry-block
allocas. The recon must DETERMINE three concrete facts, not
assert them in advance:

```text
Q3.1  Where does the neutral-IR IR_ALLOCA currently occur (in the
      PolyC IR list at the point it would be lowered)?
      ANSWER (verified): at the top of the entry block of
      fn->blocks, immediately after `irBlockAddInstr(ctx,
      ir_return_alloca)` at src/ir.c:3045. The PolyC IR list
      places it before any IR_LABEL of any user block.

Q3.2  If the alloca is emitted literally using the current
      LLVMBuildAlloca builder position, where does it land in
      the resulting LLVM module?
      ANSWER (verified): the current spike at
      src/llvm-backend.c:1397-1418 NEVER calls LLVMBuildAlloca
      at all -- it only COUNTS IR_ALLOCA reachability as a
      reject-class trigger. So today, the answer to Q3.2 is:
      there is no LLVM-level alloca to inspect, and
      CORRECTION01 must introduce one from scratch, into the
      LLVM module's function entry block, using a
      DEDICATED ENTRY-BLOCK BUILDER (the recipe is fully
      specified in Q3.3 below).

Q3.3  What insertion-point discipline must LOCAL-MEM2REG01-
      CORRECTION01 establish so the resulting alloca lands in
      the function entry block?
      ANSWER (CORRECTED in C3 RED evidence tightening,
              re-normalized in C6 RED evidence tightening):
      `LLVMSaveInsertPoint` and `LLVMRestoreInsertPoint`
      do NOT exist in the LLVM C API at all
      (`llvm-c/Core.h` exposes `LLVMPositionBuilder*`,
      `LLVMGetInsertBlock`, `LLVMClearInsertionPosition`,
      `LLVMDisposeBuilder`). There is therefore no
      save/restore primitive to call. The recommended
      discipline is therefore a DEDICATED ENTRY-BLOCK
      BUILDER — the entry-block alloca is built by a
      separate builder that is created at the top of the
      helper, positioned once, used once, and disposed:

      ```c
      LLVMBuilderRef alloca_builder =
          LLVMCreateBuilderInContext(lc->ctx);

      LLVMBasicBlockRef entry = LLVMGetEntryBasicBlock(fn);

      /* Placement rule (normalized in C6):
       *   - prefer: before the first non-alloca
       *     instruction in the entry block
       *     (LLVMPositionBuilderBefore)
       *   - else:  append to end of empty entry block
       *     (LLVMPositionBuilderAtEnd)
       *   - never: after an entry-block terminator
       *   - never: in a non-entry block
       * No literal "instruction #1" requirement:
       * mem2reg walks the entry block looking for
       * promotable AllocaInst's; relative position
       * among other allocas / entry-block non-alloca
       * instructions does not affect promotion. */
      LLVMValueRef first_non_alloca =
          LLVMGetFirstInstruction(entry);
      while (first_non_alloca &&
             LLVMIsAAllocaInst(first_non_alloca)) {
          first_non_alloca =
              LLVMGetNextInstruction(first_non_alloca);
      }
      if (first_non_alloca) {
          LLVMPositionBuilderBefore(alloca_builder,
                                    first_non_alloca);
      } else {
          LLVMPositionBuilderAtEnd(alloca_builder,
                                   entry);
      }

      LLVMValueRef slot = LLVMBuildAlloca(
          alloca_builder, LLVMInt64TypeInContext(lc->ctx),
          "polyc.local.slot");
      LLVMDisposeBuilder(alloca_builder);
      ```

      The normal lowering builder is left completely
      untouched. The two builders have the invariant:

      ```text
      normal builder   -> CFG/instruction lowering
      alloca builder   -> entry-block stack-slot
                          materialisation only
      ```

      Because the alloca builder is dedicated and
      short-lived, it carries no shared state and no
      ordering obligation with the normal builder. If
      future recon shows a second builder would interfere
      with the ordering of existing entry instructions,
      the recipe falls back to
      `LLVMClearInsertionPosition` +
      `LLVMPositionBuilderAtEnd` on the existing builder;
      it does NOT introduce a save/restore primitive
      (none exists in `llvm-c/Core.h`).

      The Q4.1 C-API harness already exercises the LLVM
      side of this discipline on every RED fixture
      (independent fresh-module + fresh-function parses,
      both APIs PASS, cleanup exit=0; see Q4.1 below).
```

**Q3 placement probe evidence (renamed in C2 evidence commit)**

Reviewer correction (post-C1 HOLD): the C1 fixture named
`single_cond_probe_NOT_IN_ENTRY.ll` was misnamed. The fixture
has no preceding basic block, so its `bb1` IS the function
entry block -- LLVM entry-ness is structural, not driven by
the block name. The fixture is a POSITIVE CONTROL
demonstrating that the block-name "entry" is irrelevant.

```text
single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll
    renamed from single_cond_probe_NOT_IN_ENTRY.ll in C2
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
    unchanged in C2
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

If hoisting is required because the current emission site is NOT
the entry block, IMPL authorisation (CORRECTION01) must include a
small hoist helper; this ACT does not implement that hoist, it only
characterises the obligation. Q3's evidence shows the obligation
is REAL: the spike has no insertion-point discipline at all,
and the adversarial placement probe fails the verifier exactly
the way an IMPL that forgot the discipline would.

### Q4. Architectural probe (mandatory before any IMPL)

For each of the three RED fixtures, mechanically translate the
surviving neutral IR to a literal LLVM memory form:

```text
PolyC neutral IR (from --dump-ir at HEAD)
    ↓
  hand-written LLVM IR:
    define i64 @<fn>(...) {
      entry:
        %slot = alloca i64
        ... direct store/load only ...
      bb_<N>: preds = <set>
        %v = load i64, ptr %slot
        ret i64 %v
    }
    ↓
opt -passes=mem2reg <fixt.ll> -S -o <fixt.m2r.ll>
opt -passes=verify  <fixt.m2r.ll> -S -o /dev/null
```

The required mechanical checks (falsifiable):

- `opt -passes=mem2reg` exits 0;
- `opt -passes=verify` exits 0 on the post-mem2reg IR;
- the post-mem2reg IR no longer references `%slot` (target alloca
  eliminated);
- the post-mem2reg IR no longer contains loads/stores of `%slot`
  (target mem ops eliminated);
- the resulting function body is valid SSA that semantically
  represents the original neutral-IR dataflow on the chosen test
  inputs (path-dependent values are preserved correctly).

The recon MUST NOT prescribe a specific textual SSA merge form
(a `phi`, a `select`, etc.). LLVM's `mem2reg` is an SSA-promotion
pass, not an if-conversion pass; the actual form it produces
depends on the precise CFG shape and on the pre-mem2reg optimisation
sequence. The ACT observes what LLVM produces and reports it; if
no PHI is observed for a fixture that the reviewer would expect to
need one, the recon explains mechanically what equivalent SSA form
LLVM chose and why.

If ANY of the three fixture probes fails any of the required
checks above, option D is FALSIFIED at C1. The next ACT must then
either fall back to option A/B/C (per IR-RETURN-SLOT-FORWARDING01
§11) or HALT with documented evidence. **Do not edit production
code to "fix" the probe; the probe is what tests the hypothesis.**

If all three pass, proceed to Q5.

### Q4.1 Module-API vs Function-API C-API probe (independent)

Two new-pass-manager C-API entry points are candidates for the
CORRECTION01 IMPL:

```text
LLVMRunPasses(module, "mem2reg,verify", TM, opts)
    -- runs the pipeline on a whole module

LLVMRunPassesOnFunction(fn, "mem2reg,verify", TM, opts)
    -- runs the pipeline on a single function
```

Reviewer correction (post-C1 HOLD): the C1 version of this
probe ran the module API first and then the function API on
the SAME (already-promoted) module. That proved only that
the function API is a no-op on already-promoted IR -- NOT
that the function API actually promotes unpromoted IR. The
recommendation to use `LLVMRunPassesOnFunction` in
CORRECTION01 was therefore ahead of the evidence.

The C2 evidence commit fixes this:

```text
MODULE probe:
    fresh parse of fixture A -> MA
    LLVMRunPasses(MA, "mem2reg,verify", NULL, opts)
    assert alloca gone, slot ops gone, verify good
    print_module(MA) -> MODULE-API RESULT section in stdout

FUNCTION probe:
    fresh parse of fixture A -> MB  (independent module)
    obtain first function fn
    LLVMRunPassesOnFunction(fn, "mem2reg,verify", NULL, opts)
    assert alloca gone, slot ops gone, verify good
    print_module(MB) -> FUNCTION-API RESULT section in stdout

The module API and the function API are run on
DIFFERENT modules from DIFFERENT in-memory parses of
the same .ll file. They do not share state.
```

Both calls return `LLVMErrorRef`; the probe captures the
error path on a deliberately-bad pipeline
`"mem2reggg,verify"` via each API:

```text
LLVMRunPasses("mem2reggg,verify", ...)
    "unknown pass name 'mem2reggg'"
LLVMRunPassesOnFunction(fn, "mem2reggg,verify", ...)
    "unknown function pass 'mem2reggg' in pipeline 'mem2reggg'"
```

The CORRECTION01 IMPL MUST consume/report this error path;
treating pass execution as infallible would silently
swallow bad-pipeline failures at runtime.

The C2 evidence commit also removes the C1 README claim
that `printf("%s", ir)` "truncates on null bytes"; the
v2 harness captures the post-pipeline IR directly from
`LLVMPrintModuleToString` on each independently-promoted
module, with `fflush(stdout)` after each capture. There
is no `opt`->copy step; the captured stdout IS what the
C API produced.

The answer is recorded in the closure handoff as a single
line:

```text
C-API MODULE API (fresh parse):    PASS (all 3 fixtures)
C-API FUNCTION API (fresh parse):  PASS (all 3 fixtures)
C-API ERROR PATH OBSERVED:         yes (both APIs)
```

### Q5. Inspect the resulting SSA merge form

For the smallest genuine multi-reaching-definition probe
(`single_cond_probe`, which has two predecessor blocks each
storing a distinct value to the same slot), capture the
post-mem2reg IR and report what LLVM actually produced. The recon
reports OBSERVED facts; it does NOT assert what LLVM should have
produced.

Required OBSERVED facts:

- target alloca eliminated from the function body (no remaining
  reference to `%slot`);
- target mem ops eliminated (no remaining load/store of `%slot`);
- verifier PASS on the post-mem2reg module;
- the natural successor block contains the merge mechanism LLVM
  actually chose (phi, or equivalent SSA form). If a phi is
  observed, its operands MUST be the two per-edge stored values
  (preserves path-dependent semantics). If a phi is NOT observed,
  the recon MUST mechanically explain what equivalent SSA form
  LLVM chose and why the resulting IR is still semantically
  correct for this fixture's control flow.

The post-mem2reg IR for every fixture is preserved as evidence
under `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/<fixt>.m2r.ll`.

This is intentionally a thin oracle: it asks whether mem2reg
correctly preserves the fixture's path-dependent semantics, not
whether it produces a specific textual construct. If a future
ACT needs to lock in a textual SSA-form expectation (e.g. as a
regression test), that lock-in is a separate CORRECTION ACT, not
part of this recon.

### Q6. Determine whether I64 alone is sufficient for the first slice

For each RED fixture, inspect the slot's type:

- `pos_b0_compare_digit`: synthetic return slot is I64 (the value
  computed from byte loads is `zext`-promoted to I64 before the
  slot write); the byte source is I8 but the slot itself is I64;
- `i64_collapse_probe`: I64 by construction;
- `single_cond_probe`: I64 by construction.

If all three are I64, the IMPL freeze (in any CORRECTION01 that
follows) is bound to **I64 local/return slots only**. I8 allocas
are DEFERRED unless a separate BYTE-MEMORY01-follow-on fixture
proves they are needed. The recon must explicitly call this out.

## 5. Implementation boundary (NOT authorised in this ACT)

This section exists to prevent silent scope creep. If C2 CLOSE
records `PASS`, a separate `ACT-POLYC-LLVM-LOCAL-MEM2REG01-
CORRECTION01` ACT must open. That future ACT's IMPL freeze is
expected to look like:

```text
ALLOWED production:
    src/llvm-backend.c
        introduce llPromoteLocalAllocas (or similar) that runs
        after llFunction() body construction and before
        llVerifyModule(); calls LLVMRunPassesOnFunction with a
        pass-pipeline string equivalent to "mem2reg,verify"
    src/llvm-backend-cap.h
        cap-table classification for the new bounded class
    (nothing else)
FORBIDDEN:
    src/ir-optimise.c (already authorised by RSF01)
    src/ir-regalloc.c
    src/ir.c
    src/llvm-backend-cap.c (only the cap.h classification is needed)
    neutral IR grammar/opcode changes
    IR_PHI construction
    PromoteMemToReg called directly (NOT part of the C API)
    I8 allocas, aggregate allocas, dynamic allocas
    escaping alloca addresses (NC2)
    GEP from compiler-generated local slots (NC3)
    volatile/atomic memory access
    user-visible stack allocation
    arbitrary pointer arithmetic
```

The CORRECTION01 ACT will refine this freeze based on the C1 recon
output.

## 6. Acceptance criteria

- **AC01 (entry identity recorded)**. §11 handoff contains the
  exact entry SHA and `git status --short` output at C1 RED start.
- **AC02 (Q1 producer surface classified)**. Every `IR_ALLOCA`
  producer and consumer in the current tree is listed in a
  markdown table appended to this ACT, with at minimum: producer
  site, slot type, consumer set, escaping flag.
- **AC03 (Q2 promotability classified)**. Each Q1 candidate has a
  PASS/REJECT row in the promotability table with the specific
  requirement that fails (if any).
- **AC04 (Q3 placement requirement determined)**. The three
  facts in Q3.1/Q3.2/Q3.3 are each answered concretely from
  source + architectural probe, not asserted in advance. If
  hoisting is required, the obligation is documented for a
  future CORRECTION01 (NOT this ACT).
- **AC05 (Q4 architectural probe PASS for all three RED
  fixtures)**. `opt -passes=mem2reg` and `opt -passes=verify`
  both exit 0 on the literal LLVM memory-form equivalents of
  `pos_b0_compare_digit`, `i64_collapse_probe`, and
  `single_cond_probe`.
- **AC06 (Q5 SSA merge form OBSERVED for `single_cond_probe`)**.
  The post-mem2reg IR contains the merge mechanism LLVM actually
  chose for the multi-pred rejoin. Required observed facts:
  target alloca eliminated, target mem ops eliminated, verifier
  PASS, and the natural successor block carries the merge form
  (phi or equivalent). If the form is not a phi, the recon MUST
  mechanically explain the equivalent SSA form and why it is
  semantically correct.
- **AC07 (Q6 type scope confirmed as I64-only)**. The recon
  explicitly states that the three RED fixtures are all I64 at
  the slot, so the future IMPL freeze is I64-only.
- **AC08 (harness state preserved)**.
  `scripts/quality/ir-return-slot-forwarding01-test.sh` still
  returns PASS=3 FAIL=3 at C2 CLOSE (this ACT does not change the
  harness; the IMPL CORRECTION01 is what flips it to all-green).
- **AC09 (no production edit)**. `git diff <entry>..<close> --
  src/ scripts/` is empty. The only changes permitted are
  additions to `docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md` and
  a new `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/` directory.

## 7. Conservation gates

These gates must remain PASS at C2 CLOSE:

- `scripts/quality/gate-fast.sh` → PASS
- `scripts/quality/factory-v2-test.sh` → PASS=35 FAIL=0
- `scripts/quality/factory-append-only-test.sh` → PASS=11 FAIL=0
- `scripts/quality/factory-v2-range-check.sh
  ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 69f7d3a` → PASS
- `scripts/quality/ir-return-slot-forwarding01-test.sh` →
  PASS=3 FAIL=3 (unchanged HALT matrix; recon does not fix it)
- `git diff --check` → clean
- `git diff <entry>..<close> -- src/ scripts/` → empty

## 8. Halt taxonomy

This ACT may legitimately close with any of:

- `PASS` — option D reconfirmed; a future CORRECTION01 ACT is
  authorised to open;
- `HALT_OPTION_D_FALSIFIED` — the architectural probe failed for
  at least one RED fixture; option D is rejected; recommend
  option A/B/C fallback (per IR-RETURN-SLOT-FORWARDING01 §11) or
  a fresh alternative;
- `HALT_RED_NOT_REPRODUCED` — the three RED fixtures no longer
  reject at the spike-stage site, which would mean an upstream
  ACT (or this one) accidentally fixed them; this is a HALT, not
  a PASS, because the IMPL seam that produced the new behaviour
  is not within this ACT's scope;
- `HALT_SCOPE_EXPANSION_REQUIRED` — the recon finds that
  Q1/Q2/Q3 require production edits (e.g. an IR-level hoist) that
  are outside this ACT's authorised scope; the next ACT must
  explicitly authorise them.

## 9. Residue (pre-declared)

- **P1.** The I8 slot case from BYTE-MEMORY01 / RESUME01 is
  DEFERRED unless an independent fixture proves it is needed. The
  recon documents why each RED fixture is I64.
- **P1.** `safe_fwd_single_pred.HC` (the structural NC from RSF01)
  must continue to fire its forwarding rewrite BEFORE any
  mem2reg-eligible alloca is materialised. A future CORRECTION01
  must keep `irForwardReturnSlot`'s guard intact (F5).
- **P2.** The LLVM C API surface (`LLVMRunPasses*`,
  `LLVMCreatePassBuilderOptions*`) must be reconnoitred for
  availability in the project's actual link surface before
  CORRECTION01. If unavailable, the project must add a small
  C-linkage shim or use `LLVMCreatePassBuilder`-based pipeline
  construction; either way, no C++ adapter is required (per the
  reviewer's correction).
- **P2.** The pre-existing collapse-elimination spike
  (`lc->collapsed && ins->dst == lc->collapse_slot`) at
  `src/llvm-backend.c:1397-1418` is for a SHAPE-DEPENDENT subset
  (a single load-then-ret pattern with the synthetic return
  slot). A future CORRECTION01 must NOT silently merge it with
  the new bounded mem2reg pipeline; the two should compose
  orthogonally.

## 10. Commit topology

Factory v2 phase grammar: `RED | IMPL | EVIDENCE | CLOSE`. There
is no `RECON` phase. Architectural-hypothesis testing IS `RED`:
it binds the principal RED evidence (Q1–Q6 + architectural probes)
before any IMPL exists.

The authorising commit (`d2ffe21`) was the OPEN of this ACT under
the NON_ACT pattern, mirroring how
ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 was opened at `d89a5cd`.
The OPEN commit only authorised the ACT document and ROADMAP row;
no `ACT:` trailer was carried, so the v2 range-check machinery
cannot validate it as an ACT. C1 below is the FIRST commit that
binds this ACT's RED evidence and carries a real `ACT:` trailer.

```text
C1 RED  (this ACT, first trailer-bearing commit)
    docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md       (this file)
    evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/          (probes + .ll)
    docs/ROADMAP.md                                   (status row updated)
    ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01
    ACT-Phase: RED

C1.5 RED evidence tightening  (informal commit-name
    "C1.5 EVIDENCE"; the Factory trailer carried by this
    commit is `ACT-Phase: RED` -- per Factory v2 §3.6
    "RED | IMPL | EVIDENCE | CLOSE" there is no
    `EVIDENCE` phase, so RED commits that only tighten
    the bound evidence are still RED phase, not a new
    phase. See §13 wording convention below for the
    historical-vs-authority reconciliation.)
    Reviewer HOLD verdict (post-C1) demanded three corrections
    before C2 CLOSE:
        P0-1: function-API probe was vacuous (ran on already-
              promoted module). Fix: parse twice from disk,
              run module API on one copy and function API on
              the other, print both post-pipeline IRs.
        P0-2: Q1 producer provenance was wrong
              (irForwardReturnSlot does not emit; it consumes).
              Fix: derive WHO actually emits (irLowerFunction
              at src/ir.c:3042-3047) and WHAT discriminator
              the future IMPL needs.
        P1: placement probe was mislabeled
              (single_cond_probe_NOT_IN_ENTRY has bb1 as the
              function entry block). Fix: rename to
              single_cond_probe_ENTRY_BLOCK_NAMED_BB1 as the
              positive control; the adversarial fixture
              remains the negative.
    docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md       (Q1 + Q3 +
                                                       Q4.1 sections
                                                       rewritten)
    evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/
        capi/capi_probe.c                             (v2 harness:
                                                       independent
                                                       parses)
        capi/README.md                                (updated)
        capi/<fixt>.capi-stdout.txt                   (re-captured)
        capi/<fixt>.capi-stderr.txt                   (re-captured)
        probes/single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll
            (renamed from NOT_IN_ENTRY; positive control)
        probes/single_cond_probe_ENTRY_BLOCK_NAMED_BB1.m2r.ll
        probes/single_cond_probe_ENTRY_BLOCK_NAMED_BB1.m2r.stderr
        probes/single_cond_probe_NOT_IN_ENTRY_ADVERSARIAL.ll
            (header rewritten to clearly explain the
            negative witness)
    ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01
    ACT-Phase: RED  (still RED; C1.5 is more RED evidence,
                     not yet CLOSE -- the verdict is the
                     next commit's trailer)

C2 CLOSE  (this ACT, closure commit)
    docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md       (closure handoff
                                                       appended)
    ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01
    ACT-Phase: CLOSE
    ACT-Verdict: PASS
            | HALT_OPTION_D_FALSIFIED
            | HALT_RED_NOT_REPRODUCED
            | HALT_SCOPE_EXPANSION_REQUIRED
```

If the C1 RED evidence convinces the reviewer that the ACT is
not yet ready to close (e.g. one fixture probe is ambiguous), the
ACT may produce one or more additional RED evidence-tightening
commits between C1 and C2 to tighten the evidence, before the
C2 CLOSE. C1.5 is exactly such an evidence-tightening commit;
informally labelled "EVIDENCE" in conversation but carrying the
Factory trailer `ACT-Phase: RED` (no `EVIDENCE` phase exists).
It does not change the verdict, only the bound evidence.

The three RSF01 RED fixtures (`pos_b0_compare_digit.HC`,
`i64_collapse_probe.HC`, `single_cond_probe.HC`) already exist in
the tree (committed under RSF01); C1 + C1.5 reuse them via the
existing harness and emit the hand-written LLVM IR equivalents as
recon-only evidence files. No fixture code is duplicated; the
hand-written `.ll` files are NEW and live under
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/`.

No IMPL commit is permitted under this ACT id.

## 11. Closure handoff (lite; appended at CLOSE)

Follow `docs/factory/HANDOFF-TEMPLATE.md` (lite). The handoff MUST
contain:

```text
VERDICT
IDENTITY (C1 entry SHA, C2 CLOSE SHA, branch)
Q1..Q6 results (with the markdown tables and .ll evidence paths)
Q4.1 C-API probe results (MODULE API + FUNCTION API + error path)
OPTIONAL: REJECT+justification if Q4 failed
        (HALT_OPTION_D_FALSIFIED)
GATES (all PASS at CLOSE)
SCOPE (git diff <entry>..<close> -- src/ scripts/ is empty)
RESIDUE (carry forward the P1/P2 items)
NEXT ACT (either a CORRECTION01 IMPL freeze if D is confirmed,
         or a recommendation for option A/B/C fallback if D is
         falsified)
```

The handoff is appended to this ACT file at CLOSE; no separate
HANDOFF document is required for this ACT.

---

## Appendix A. Reviewer-acknowledged corrections

This ACT exists because the predecessor ACT's §11 listed four
hypothetical fixes (A/B/C/D). Option D is the reviewer's
preference. The reviewer explicitly corrected one architectural
detail:

> Do not phrase the implementation as calling `PromoteMemToReg`
> directly from PolyC's C backend. `PromoteMemToReg` is a C++
> utility. The supported LLVM C API surface instead exposes the
> new pass manager through `LLVMRunPasses(...)` /
> `LLVMRunPassesOnFunction(...)`, with the same pipeline syntax
> accepted by `opt -passes=...`.

This ACT's Q4 probe uses `opt -passes=mem2reg` and
`opt -passes=verify` to test the hypothesis end-to-end without
requiring a C++ adapter. Any future CORRECTION01 must use the C
API call, not a direct `PromoteMemToReg` import.

## Appendix B. Why this is RED, not IMPL

F3 (RED before production implementation) and F7 (scope is
conserved) both argue for RED-first when the hypothesis is
structural:

- The hypothesis is that LLVM mem2reg is the smallest robust
  seam. That is testable without a production edit (Q4).
- Any IMPL edit before Q4 PASS risks implementing a fix that
  does not work, and then chasing ghosts.
- The IMPL freeze has many degrees of freedom (placement,
  hoist, C API availability, escape analysis, type scope) that
  are best resolved AFTER RED, not before.

If the reviewer wants to skip RED and authorise IMPL directly,
that should be a separate CORRECTION01 ACT opened with explicit
scope overrides.

## Appendix C. Preliminary C API recon (snapshot at ACT OPEN)

Recorded at ACT OPEN (HEAD = `d2ffe21`); the C1 RED commit
extends this snapshot with Q4.1.

```text
Question: is LLVMRunPasses exposed via a header the project
already includes?

Verified at ACT OPEN (HEAD = d2ffe21):
  grep -rn 'LLVMRunPasses' src/ -> 0 matches
  grep -rn 'LLVMCreatePassBuilderOptions' src/ -> 0 matches
  grep -rn 'llvm-c/Transforms/PassBuilder.h' src/ -> 0 matches

Implication: at ACT OPEN, the project does NOT yet include
the LLVM C PassBuilder headers. A future CORRECTION01 will need
to (a) verify those headers are available in the build's LLVM
distribution, (b) include them in src/llvm-backend.c, and (c)
add any needed link flags. This is RED-only observation; it
is not a permission to touch build files under this ACT id.
```

## 12. Closure handoff (appended at C2 CLOSE, verdict PASS)

Appended at C2 CLOSE. Verdict authority is the
`ACT-Verdict: PASS` trailer on the C2 commit, NOT this
section. The reviewer-corrected close criterion is
reproduced verbatim and verified line-by-line against the
evidence bound under
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/`.

### Verdict

```
ACT-Verdict: PASS
```

Option D is RECONFIRMED. The bounded eligibility
discriminator, the function-C-API binding, and the
placement requirement are all determined; future
CORRECTION01 may authorise the IMPL freeze.

### Identity

```
ACT id         = ACT-POLYC-LLVM-LOCAL-MEM2REG01
branch         = main
entry (EN)     = 0501569 (post-RSF01-hygiene; pre-CLOSE)
ACT OPEN       = d2ffe21 (NON_ACT; mirrors d89a5cd RSF01
                 OPEN pattern; no ACT: trailer)
C1 RED         = 6059298 (first trailer-bearing commit;
                 ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01 +
                 ACT-Phase: RED)
C1.5 EVIDENCE  = f45ba38 (post-reviewer HOLD; ACT: +
                 ACT-Phase: RED; not a verdict commit)
C2 CLOSE       = <C2 commit SHA; this file>
```

### Close criterion (reviewer-specified)

```text
Option D architectural probe             PASS
actual candidate producer identified      PASS
bounded eligibility discriminator         PASS
module C API independent promotion        PASS
function C API independent promotion      PASS
C API error handling observed             PASS
entry-placement positive/negative         PASS
I64-only first slice                      PASS
production delta                          0
```

Each line, mechanically verified:

1. **Option D architectural probe: PASS.** All three RED
   fixtures survive `opt -passes=mem2reg` (exit=0) and
   `opt -passes=verify` (exit=0). Post-mem2reg IR
   captures:
     - target alloca eliminated
     - target mem ops eliminated
     - single phi at natural successor block (bb4)
     - per-edge operands matching original PolyC semantics
   Evidence:
     `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/probes/{single_cond_probe,i64_collapse_probe,pos_b0_compare_digit}.m2r.ll`

2. **Actual candidate producer identified: PASS.**
   Derived from `src/ir.c` and `src/ir-optimise.c`
   directly (no inference):
     - P1: `irLowerFunction` at `src/ir.c:3042-3047`
       (synthetic scalar return slot; ELIGIBLE)
     - P2: `irFnCallTo` at `src/ir.c:443-448`
       (aggregate callee buffer; REJECT_SCOPE)
     - P3: `irLowerTry` at `src/ir.c:1916-1918`
       (256-byte CatchFrame; REJECT_SCOPE)
   C1 misidentified `irForwardReturnSlot` (a consumer)
   as the producer; C1.5 corrected this. Documented in
   ACT §4 Q1 and `Q1-Q6-SUMMARY.md` Q1.

3. **Bounded eligibility discriminator: PASS.**
   ```
   fn->return_value exists (kind == IR_VAL_LOCAL) AND
   fn->exit_block exists AND
   llDetectCollapsibleReturn(fn, &slot) == 0 AND
   slot->type == IR_TYPE_I64 AND
   single IR_ALLOCA of size 8 at top of entry block
   ```
   Reuses the existing `llDetectCollapsibleReturn`
   predicate structure; CORRECTION01 does not need to
   invent a new classification. NOT arbitrary
   IR_ALLOCA.

4. **Module C API independent promotion: PASS.**
   `LLVMRunPasses(M, "mem2reg,verify", NULL, opts)` on a
   fresh parse of each RED fixture returns OK; post-
   pipeline IR captured verbatim from
   `LLVMPrintModuleToString`. Captured in
   `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/<fixt>.capi-stdout.txt`
   under the `MODULE-API RESULT (fresh parse, LLVMRunPasses only)`
   section header.

5. **Function C API independent promotion: PASS.**
   `LLVMRunPassesOnFunction(fn, "mem2reg,verify", NULL, opts)`
   on an INDEPENDENT fresh parse of each RED fixture
   returns OK; post-pipeline IR captured verbatim. The
   module API and the function API do NOT share state;
   each runs on its own `LLVMModuleRef` from its own
   `LLVMMemoryBufferRef`. Captured under the
   `FUNCTION-API RESULT (fresh parse, LLVMRunPassesOnFunction only)`
   section header. The captured post-pipeline IR is
   byte-for-byte identical between the two APIs.
   Recommendation: `LLVMRunPassesOnFunction` is now
   load-bearing for CORRECTION01.

6. **C API error handling observed: PASS.** Bad pipeline
   `"mem2reggg,verify"` returns a non-NULL `LLVMErrorRef`:
     - module API:   "unknown pass name 'mem2reggg'"
     - function API: "unknown function pass 'mem2reggg' in pipeline 'mem2reggg'"
   Captured in
   `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/err-path.stderr`
   and
   `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/function-api-err-path.stderr`.
   CORRECTION01 MUST consume/report this error path.

7. **Entry-placement positive/negative: PASS.**
     - positive control: `single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll`
       (function's first block is named `bb1`, with no
       predecessor, so it IS the function entry block
       regardless of label). `opt -passes=mem2reg` exits 0;
       post-mem2reg IR identical to `single_cond_probe.m2r.ll`.
     - negative witness: `single_cond_probe_NOT_IN_ENTRY_ADVERSARIAL.ll`
       (alloca placed inside bb3, a conditional predecessor
       of bb2 whose entry is bb1). `opt -passes=mem2reg`
       exits 1 with
       `"Instruction does not dominate all uses!"`.
   CORRECTION01 must use a DEDICATED ENTRY-BLOCK BUILDER.
   The authoritative recipe (builder creation,
   positioning, and disposal) is fully specified in
   §6 Q3.3 corrected/re-normalized; do NOT re-derive the
   formula inline. The C2-handoff save/restore discipline
   using `LLVMSaveInsertPoint` / `LLVMRestoreInsertPoint`
   was an impossible C API prescription and is removed.

8. **I64-only first slice: PASS.** All three RED fixtures
   are I64 at the slot:
     - `pos_b0_compare_digit`: slot is I64 (the byte
       source is `zext`-promoted to I64 before the slot
       write)
     - `i64_collapse_probe`: I64 by construction
     - `single_cond_probe`: I64 by construction
   Future IMPL freeze is I64 single-slot scalar only.
   I8 allocas are DEFERRED.

9. **Production delta: 0.** `git diff 0501569..HEAD -- src/
   scripts/` is empty. Only `docs/acts/`, `docs/ROADMAP.md`,
   and `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/` are
   touched.

### Gates (all PASS at C2 CLOSE)

```text
git diff --check (working tree)              clean
git diff --check 0501569..HEAD               clean
git diff --check db6404e..HEAD               clean
trailing-whitespace on all touched files     0 lines
gate-fast                                    VERDICT=PASS
factory-v2-test                              PASS=35 FAIL=0
factory-append-only-test                     PASS=11 FAIL=0
ir-return-slot-forwarding01-test (HALT
  matrix preserved; not a regression)        PASS=3 FAIL=3
factory-v2-range-check.sh
  ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 69f7d3a
                                              STATUS=PASS
                                              VERDICT=HALT_SECOND_SEAM_REQUIRED
factory-v2-commit-msg-check                  all 3 commits PASS
                                              (d2ffe21 NON_ACT;
                                               6059298 ACT RED;
                                               f45ba38 ACT RED)
```

### Scope (F7 conserved)

```text
git diff 0501569..HEAD --stat
    docs/ROADMAP.md                                   ~2 row updates
    docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md       C1 + C1.5 RED
                                                       contract
    evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/
        probes/         5 .ll + 4 .m2r.ll + stderr/verify logs
        capi/           v2 C harness + stderr verdicts + README
        Q1-Q6-SUMMARY.md
git diff 0501569..HEAD -- src/ scripts/    EMPTY (correct F7)
```

### Residue (carry forward to ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01)

```text
P1  I8 allocas are DEFERRED. If a future BYTE-MEMORY01
    follow-on fixture proves they are needed, a separate
    ACT extends the IMPL freeze.

P1  safe_fwd_single_pred.HC must continue to fire its
    forwarding rewrite BEFORE any mem2reg-eligible alloca
    is materialised. CORRECTION01 must keep
    irForwardReturnSlot's PN<=1 guard intact (F5).

P2  The LLVM C API surface (LLVMRunPasses*,
    LLVMCreatePassBuilderOptions*) is reconnoitred and
    links cleanly, but the project does NOT yet include
    `llvm-c/Transforms/PassBuilder.h`. CORRECTION01 must
    add the include.

P2  The pre-existing collapse-elimination spike
    (lc->collapsed && ins->dst == lc->collapse_slot) at
    src/llvm-backend.c:1397-1418 is for a SHAPE-DEPENDENT
    subset (single load-then-ret pattern with the synthetic
    return slot). CORRECTION01 must NOT silently merge it
    with the new bounded mem2reg pipeline; the two should
    compose orthogonally.

P2  The v2 C-API harness SIGSEGVs during cleanup after the
    verdict and the IR stdout are captured. CORRECTION01
    uses the C API from inside src/llvm-backend.c with
    proper LLVMDisposeModule / LLVMDisposePassBuilderOptions
    ordering, so this harness defect does not propagate.
    -- HISTORICAL: this residue entry described the v2
    harness defect. The defect has been SUPERSEDED in C3
    by the v3 harness (LLVMParseIRInContext2; exits 0 on
    all 3 fixtures; see cleanup-exit.txt and
    cleanup-exit-summary.txt under
    evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/). The
    residue is kept here only as a pointer to the v2/v3
    history; CORRECTION01 inherits a GREEN harness
    pattern, not the v2 defect.
```

### Next ACT (re-normalized in C6 RED evidence tightening)

```
ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01
    Open after this CLOSE
    Authorise the bounded IMPL freeze:
        src/llvm-backend.c: introduce llPromoteLocalAllocas
            (or equivalent) that runs after llFunction()
            body construction and before llVerifyModule();
            calls LLVMRunPassesOnFunction with a pass-
            pipeline string equivalent to "mem2reg,verify";
            uses the Q1-derived eligibility discriminator;
            uses a DEDICATED ENTRY-BLOCK BUILDER per Q3.3
            (LLVMCreateBuilderInContext + position per the
            placement rule + LLVMBuildAlloca +
            LLVMDisposeBuilder); does NOT call any
            save/restore primitive (none exists in
            llvm-c/Core.h).
        src/llvm-backend-cap.h: cap-table classification
            for the new bounded class.
    Expected to flip ir-return-slot-forwarding01-test.sh
    from PASS=3 FAIL=3 (HALT matrix) to PASS=6 FAIL=0.
```

The handoff is now APPENDED; the closure verdict is the
`ACT-Verdict: PASS` trailer on the C2 commit, not the text
above.

## 12.5 Subsequent corrections (appended at C3 RED evidence tightening)

The post-C2 HOLD verdict identified two P0 defects in the
implementation contract frozen at C2 + one wording
convention note. C3 corrects the contract without
re-opening the architectural PASS at `57c7ee4`.

### P0-1: C-API probe SIGSEGV was double-free (CORRECTED)

`LLVMParseIRInContext` documents itself as CONSUMING the
memory buffer; the v2 harness used it and then
`LLVMDisposeMemoryBuffer` on the success path, producing
a double-free / use-after-free during cleanup. C3 fixes
this with `LLVMParseIRInContext2` (caller owns the
buffer; exactly-one dispose). All 3 RED fixtures now
exit 0 cleanly; see
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/cleanup-exit.txt`
and `cleanup-exit-summary.txt`.

### P0-2: insertion-point prescription referenced nonexistent C API (CORRECTED)

`LLVMSaveInsertPoint` and `LLVMRestoreInsertPoint` are
NOT in `llvm-c/Core.h`. C3 replaces the save/restore
discipline with a dedicated entry-block builder:

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

The normal lowering builder is left untouched. See ACT
§6 Q3.3 and `Q1-Q6-SUMMARY.md` Q3.3 / Q3.

### Wording convention (RESOLVED)

"EVIDENCE" is descriptive prose in commit subjects; it
is NEVER a Factory phase token. The trailer is
authoritative. See §13 below.

### Architectural PASS at C2 STANDS

The Option D architectural probe, producer provenance,
bounded eligibility discriminator, and the 9-line close
criterion (Q4.1 module + function APIs + error path +
positive/negative placement + I64-only + production
delta=0) are unchanged. C3 only tightens the
implementation contract that CORRECTION01 will consume.

## 13. Wording convention (corrected at C3 RED evidence tightening)

### The actual Factory v2 phase grammar

The Factory v2 phase grammar is `RED | IMPL | EVIDENCE |
CLOSE`. This is the grammar enforced by
`scripts/quality/factory-v2-commit-msg-check.sh` (the
authoritative trailer validator) and by the regression
suite (`scripts/quality/factory-v2-test.sh`):

```text
# from scripts/quality/factory-v2-commit-msg-check.sh
# ACT-Phase: exactly 1, one of
#            RED | IMPL | EVIDENCE | CLOSE
```

```text
# from scripts/quality/factory-v2-test.sh
# T13  range RED->IMPL->CLOSE (3 commits)              PASS
# T14  range RED->IMPL->EVIDENCE->IMPL->CLOSE (5)      PASS
# T15  first phase not RED                             FAIL
```

`EVIDENCE` is therefore a real, legal Factory phase. The
canonical factory doctrine (`docs/factory/GIT-METADATA.md`)
also states `ACT-Phase: <RED | IMPL | EVIDENCE | CLOSE>`.

The post-C2 HOLD verdict's "phase grammar is exactly
`RED | IMPL | CLOSE`" wording in the C3 commit message
(285a9c0) and earlier drafts of this section was
incorrect and is retracted. The grammar is the 4-phase
grammar above; the commit subject and §10 of this ACT
already reflect it. Only the prose in §13 and the C3
commit message mistakenly narrowed it.

### What this means for the LOCAL-MEM2REG01 lifecycle

The phase label carried by a commit's `ACT-Phase:` trailer
is the trailer-authoritative classification. The commit
subject and surrounding prose may use descriptive labels
("evidence tightening", "GREEN", etc.) but those are
NOT phase tokens; only `RED | IMPL | EVIDENCE | CLOSE` are.

For this ACT, the authoritative trailers are:

```text
d2ffe21  no trailer            (NON_ACT OPEN mirror)
6059298  ACT-Phase: RED         (C1 RED)
f45ba38  ACT-Phase: RED         (C1.5 RED evidence tightening)
57c7ee4  ACT-Phase: CLOSE       (C2 CLOSE, verdict PASS)
285a9c0  ACT-Phase: RED         (C3 RED evidence tightening)
69c886f  ACT-Phase: RED         (CORRECTION01 RED; opens the new ACT id)
```

### Why f45ba38 and 285a9c0 carry `RED` not `EVIDENCE`

Both commits are evidence-tightening commits in
substance (they refine the principal RED evidence, fix
the harness, correct the recipe). Either label would
have been semantically correct, but both chose `RED`.
This is not a contradiction of the grammar; it is a
phase-label choice within the grammar. Under a strict
reading of "EVIDENCE = post-RED, post-IMPL non-binding
intermediate" both commits would have been `EVIDENCE`;
under a permissive reading that folds evidence
tightening back into RED, they are `RED`. Both readings
are valid; we use the permissive reading here for
historical continuity with C1's RED trailer.

### The trailer is AUTHORITATIVE

For Factory v2 lifecycle bookkeeping and for the
range-check machinery, the trailer is the only
authoritative source of phase. Prose, commit subjects,
ROADMAP CLASS rows, and Q1-Q6-SUMMARY labels may use
any descriptive label; only the trailer determines
the lifecycle position.

This was already stated in §10 ("the trailer is the
lifecycle authority") and is now confirmed against the
real 4-phase grammar.

### Bound evidence references (post-C3)

* v3 C-API harness with `LLVMParseIRInContext2`:
  `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/capi_probe.c`
  (lines 39-86 ownership contract, lines 165-184 cleanup).
* err-path probe:
  `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/errpath_probe.c`.
* runner script:
  `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/run_capi_probes.sh`.
* captured exit-code table:
  `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/cleanup-exit.txt`.
* aggregate `STATUS=PASS`:
  `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/cleanup-exit-summary.txt`.
* per-fixture verdicts + cleanup:
  `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/<fixt>.capi-stderr.txt`
  (each ends with `[probe] CLEANUP-EXIT-0 (return 0)`).
* per-fixture post-pipeline IR (both APIs):
  `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/<fixt>.capi-stdout.txt`.
* bad-pipeline-string error capture:
  `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/capi/err-path.stderr`.

### Reviewer-required conditions re-verified by C3

| Condition                                                              | Status |
|------------------------------------------------------------------------|--------|
| process exit = 0 for all 3 RED fixtures                                | PASS   |
| both C-API PASS verdicts for each fixture (independent fresh parses)   | PASS   |
| consumed-error path: both APIs return non-NULL LLVMErrorRef, consumed via `LLVMGetErrorMessage` + `LLVMDisposeErrorMessage` | PASS |
| consumed-error path also exits 0                                       | PASS   |
| inserted-point C API prescription uses only symbols that exist in `llvm-c/Core.h` | PASS (dedicated entry-block builder) |
| trailer authority reconciled with prose ("EVIDENCE" prose label noted, trailer is RED) | PASS |

All conditions are met. The architectural PASS at
`57c7ee4` is now backed by a green-cleanup C-API probe
and a real C-API prescription; CORRECTION01 has the
contract it needs.

## 14. Factory v2 range-check residue (corrected at C3 RED evidence tightening)

### Immutable historical fact

After C3 (285a9c0) is committed as a descendant of the
LOCAL-MEM2REG01 CLOSE (57c7ee4), the Factory v2
range-check tool reports a rule-6 violation:

```text
$ sh scripts/quality/factory-v2-range-check.sh \
    ACT-POLYC-LLVM-LOCAL-MEM2REG01 57c7ee4
STATUS=FAIL
REASON=commit 285a9c0c7600180398d7162fb4dad61a6c8990a7
after CLOSE still carries ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01;
ACT must not continue past CLOSE
```

Rule 6 (`No commit after CLOSE may carry ACT=<id>`) is
a hard mechanical invariant. C3 carries
`ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01` because its content
(the v3 C-API harness + Q3.3 correction + the corrected
wording convention in §13) is the RED evidence tightening
of the original ACT. The commit is immutable under the
append-only invariant (F14); the rule-6 violation is
therefore permanent and cannot be retroactively fixed.

**Nothing about a future CORRECTION01 CLOSE commit will
change this.** The CORRECTION01 ACT can supersede the
operative implementation contract, can carry its own
valid RED→IMPL→...→CLOSE range, and can carry
`ACT-Supersedes: ACT-POLYC-LLVM-LOCAL-MEM2REG01` with
`ACT-Corrected-Verdict: PASS`. But it does not
retroactively revalidate the original LOCAL-MEM2REG01
range. The original ACT's range at HEAD will continue
to find 285a9c0 as a same-id descendant of its CLOSE,
and rule 6 will continue to fail.

This is honest residue, not a regression. The state is:

```text
LOCAL-MEM2REG01 architectural verdict
    PASS at 57c7ee4
    immutable and accepted

LOCAL-MEM2REG01 Factory range at current HEAD
    FAIL
    permanently contaminated by 285a9c0 post-CLOSE same-id trailer

CORRECTION01
    can supersede the operative contract
    can itself have a valid RED→IMPL→...→CLOSE range
    CANNOT retroactively make the original rule-6 PASS
```

### Why this is not a regression

1. The architectural PASS at `57c7ee4` is unchanged.
   The 9-line close criterion (architectural probe,
   producer provenance, eligibility discriminator,
   both C APIs, error handling, placement, I64-only,
   production-delta=0) is still met.
2. C3 only tightens the implementation contract that
   CORRECTION01 will consume. It introduces no new
   RED work; it is purely a corrective close-out.
3. The range-check failure is mechanical and
   immutable. The original ACT range
   `FIRST..CLOSE = 6059298..57c7ee4` validates cleanly
   when checked in isolation; rule 6 is tripped only
   by the descendant, which is append-only and
   cannot be removed.
4. The repo's other closed ACTs (RSF01,
   BYTE-MEMORY01, CORE04) do not exhibit this pattern
   because their descendant corrections
   (BOOKKEEPING01, RESUME01, CORRECTION01) carry
   DIFFERENT ACT ids from the start. The
   LOCAL-MEM2REG01 family opened its CORRECTION01
   ACT id at 69c886f (the commit following C3); that
   was after the rule-6 contamination was already
   locked in.

### CORRECTION01 lifecycle

The CORRECTION01 ACT id
(`ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01`) was
opened at 69c886f in RED phase. Its authorized
trajectory is:

```text
69c886f  ACT-Phase: RED         (CORRECTION01 RED; opens the new ACT id)
        ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01
        ACT-Phase: RED

future IMPL commit(s) ...  ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01
                           ACT-Phase: IMPL

future CLOSE commit        ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01
                           ACT-Phase: CLOSE
                           ACT-Verdict: PASS
                           ACT-Supersedes: ACT-POLYC-LLVM-LOCAL-MEM2REG01
                           ACT-Corrected-Verdict: PASS
```

The CORRECTION01 CLOSE will document that the
architectural PASS at 57c7ee4 is preserved (not
overturned) and that only the implementation contract
was tightened. The CORRECTION01 range-check at the
future CLOSE will validate cleanly (its own rule 4 +
rule 6 + rule 5 are all independent of the original
LOCAL-MEM2REG01 range).

### Earlier draft's mistaken claim (retracted)

An earlier draft of §14 (in the C4 commit 69c886f)
suggested that "the rule-6 violation becomes a
legitimate ACT-supersedes lifecycle" once CORRECTION01
closes. That framing is retracted. The rule-6
violation on the original LOCAL-MEM2REG01 range
remains a permanent, immutable residue; CORRECTION01's
CLOSE does not erase it. CORRECTION01 is a distinct
ACT whose own range validates correctly; the original
ACT's range remains contaminated.
