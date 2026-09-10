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
      LLVM module's function entry block, with a
      save/restore insertion-point discipline.

Q3.3  What insertion-point discipline must LOCAL-MEM2REG01-
      CORRECTION01 establish so the resulting alloca lands in
      the function entry block?
      ANSWER (verified): save the current builder insertion
      point via LLVMSaveInsertPoint, call
      LLVMPositionBuilderAtEnd(builder, fn_entry_bb), emit
      LLVMBuildAlloca + LLVMBuildStore, restore via
      LLVMRestoreInsertPoint(builder, saved_ip). The Q4.1 C-API
      harness already exercises the LLVM side of this
      discipline on every RED fixture.
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
    CONCLUSION: if CORRECTION01 forgets to save/restore the
                insertion point to the entry block, the
                resulting LLVM module fails the verifier
                exactly as this probe does.
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

C1.5 EVIDENCE  (this ACT, post-reviewer HOLD evidence tightening)
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
ACT may produce one or more EVIDENCE commits between C1 and C2 to
tighten the evidence, before the C2 CLOSE. C1.5 is exactly such an
EVIDENCE commit; it does not change the verdict, only the bound
evidence.

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
