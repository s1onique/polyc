# ACT-POLYC-LLVM-LOCAL-MEM2REG01

**Title:** Recon — should PolyC's LLVM backend lower a tightly bounded
class of compiler-generated scalar local/return slots to LLVM entry-
block allocas with direct loads/stores, then run LLVM's `mem2reg`
pass to construct SSA, instead of extending PolyC's bespoke collapse
machinery?

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** RECON (architectural-boundary hypothesis test; **no IMPL
authorisation in this ACT** — production code is intentionally frozen
while the hypothesis is probed)

**Predecessor:** ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 (closed at
`69f7d3a` with verdict `HALT_SECOND_SEAM_REQUIRED`; this ACT is the
recommended next ACT per that document's §11 option D)

**Production semantic changes:** FORBIDDEN (RECON only)

**IR / ABI / LLVM authorization:** NONE in RECON. The architectural
probe exercises LLVM's pass pipeline outside the PolyC build path.
IMPL authorisation requires a separate CORRECTION01 ACT that opens
only if the C1 RED/RECON concludes that the bounded mem2reg pipeline
is the smallest robust seam.

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
direct, non-volatile load/store only
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

### allowed (RECON only)

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
- IR_PHI construction (forbidden by
  ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 §4);
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

Required state at RECON start:

- on `main`;
- worktree clean;
- HEAD carries `ACT-POLYC-IR-RETURN-SLOT-FORWARDING01` CLOSE
  (`69f7d3a`) in its ancestor set.

## 4. RED / RECON witnesses (six concrete questions)

### Q1. Enumerate the producer surface

For every `IR_ALLOCA` that survives neutral-IR optimisation and
reaches the LLVM backend, classify:

- which AST/IR producer emitted it (e.g. `irAlloca` in
  `src/ir.c:72`, `buf_alloca` in `src/ir.c:443`, `frame_alloca` in
  `src/ir.c:1916`);
- the slot's nominal type and size;
- the consumer set: which `IR_LOAD` / `IR_STORE` use it;
- whether the address escapes (i.e. any IR that materialises the
  pointer value into a phi, ret, parameter, or external store);
- the function in which it occurs (`irRegalloc`'s local-slot
  bookkeeping, the synthetic return slot, a user-declared array
  buffer, etc.).

Method: `grep -nE 'IR_ALLOCA|irAlloca|buf_alloca|frame_alloca'
src/` plus a fresh `--dump-ir` run on each RED fixture plus a
positive user-declared-buffer fixture (residue from BYTE-MEMORY01 /
RESUME01 chains). Distinguish the synthetic return-slot alloc (the
one the forwarder already eliminates when safe) from "genuine
addressable local" allocas (which option D does NOT authorise).

### Q2. Mechanical promotability classification

For each Q1 candidate, mechanically verify the LLVM mem2reg
requirements:

```text
- alloca lives in the function entry block
- all uses are loads and stores (no call/Invoke/use-of-pointer-as-value)
- the alloca is not captured (its address is never stored into
  another memory location and never leaves the function)
- the alloca is a single-slot scalar OR a small aggregate that
  LLVM's SROA could split into scalars
- loads/stores are aligned and not volatile/atomic
```

Method: per Q1 candidate, walk the IR list and verify each
requirement. Record as a markdown table appended to this ACT. The
classification table is part of the closure evidence; any candidate
that fails must be marked REJECT and explained.

### Q3. Confirm placement

LLVM Frontend/PerformanceTips guidance: function-scoped allocas
should be emitted at the start of the entry block because
mem2reg/SROA only try to eliminate entry-block allocas. The recon
must verify that:

- the synthetic return slot is already emitted into the entry
  block (it is — see `lc->collapsed && ins->dst ==
  lc->collapse_slot` at `src/llvm-backend.c:1397-1418`), OR
- any non-entry-block allocas must be moved (a SROA-friendly hoist)
  before mem2reg sees them.

If hoisting is required, IMPL authorisation (CORRECTION01) must
include a small hoist helper; RECON only documents the requirement.

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
        ... direct non-volatile store/load only ...
      bb_<N>: preds = <set>
        %v = load i64, ptr %slot
        ret i64 %v
    }
    ↓
opt -passes=mem2reg <fixt.ll> -S -o <fixt.m2r.ll>
opt -passes=verify  <fixt.m2r.ll> -S -o /dev/null
```

Then check:

- `opt -passes=mem2reg` exits 0;
- `opt -passes=verify` exits 0 on the post-mem2reg IR;
- the post-mem2reg IR no longer references `%slot` (target alloca
  eliminated);
- for multi-pred fixtures (`single_cond_probe`, the multi-edge
  rejoin of `pos_b0_compare_digit`), the post-mem2reg function
  body contains either a `phi` or a `select` that merges per-edge
  values in the natural successor block.

If ANY of the three fails, option D is FALSIFIED at C1. The next
ACT must then either fall back to option A/B/C (per
IR-RETURN-SLOT-FORWARDING01 §11) or HALT with documented evidence.
**Do not edit production code to "fix" the probe; the probe is
what tests the hypothesis.**

If all three pass, proceed to Q5.

### Q5. Inspect the resulting SSA

For `single_cond_probe` (the smallest multi-pred probe), capture
the post-mem2reg IR and verify:

- a `phi` is constructed in the natural successor block;
- the operands of the `phi` are the per-edge stored values;
- no `alloca`, `load`, or `store` to `%slot` survives in the
  function body (except the entry-block alloca itself if mem2reg
  does not always delete it — verify empirically);
- `opt -passes=verify` PASS.

Preserve the post-mem2reg IR as
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/single_cond_probe.m2r.ll`
(or a similar path agreed at CLOSE).

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

## 5. Implementation boundary (NOT authorised in this RECON ACT)

This section exists to prevent silent scope creep. If the C1 RECON
concludes that option D is the right path, a separate CORRECTION01
ACT must open. That future ACT's IMPL freeze is expected to look
like:

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
  exact entry SHA and `git status --short` output at RECON start.
- **AC02 (Q1 producer surface classified)**. Every `IR_ALLOCA`
  producer and consumer in the current tree is listed in a
  markdown table appended to this ACT, with at minimum: producer
  site, slot type, consumer set, escaping flag.
- **AC03 (Q2 promotability classified)**. Each Q1 candidate has a
  PASS/REJECT row in the promotability table with the specific
  requirement that fails (if any).
- **AC04 (Q3 placement verified)**. Entry-block placement is
  confirmed for each PASS candidate; non-entry candidates are
  flagged for hoisting (which a future CORRECTION01 may
  authorise, NOT this RECON).
- **AC05 (Q4 architectural probe PASS for all three RED
  fixtures)**. `opt -passes=mem2reg` and `opt -passes=verify`
  both exit 0 on the literal LLVM memory-form equivalents of
  `pos_b0_compare_digit`, `i64_collapse_probe`, and
  `single_cond_probe`.
- **AC06 (Q5 SSA inspection PASS for `single_cond_probe`)**. The
  post-mem2reg IR contains a `phi` (or equivalent select) in the
  rejoin block; no survivor `%slot` references remain.
- **AC07 (Q6 type scope confirmed as I64-only)**. The recon
  explicitly states that the three RED fixtures are all I64 at
  the slot, so the future IMPL freeze is I64-only.
- **AC08 (harness state preserved)**.
  `scripts/quality/ir-return-slot-forwarding01-test.sh` still
  returns PASS=3 FAIL=3 at RECON CLOSE (the recon does not change
  the harness; the IMPL CORRECTION01 is what flips it to
  all-green).
- **AC09 (no production edit)**. `git diff <entry>..<close> --
  src/ scripts/` is empty. The only changes permitted are
  additions to `docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md` and
  a new `evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/` directory.

## 7. Conservation gates

These gates must remain PASS at RECON CLOSE:

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

A single NON_ACT (or RECON) commit is the natural shape for this
ACT:

```text
RECON commit 1:
    docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md       (this file)
    evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/          (probes + .ll)
    docs/ROADMAP.md                                   (status row added)
```

Optionally split:

```text
RECON commit 1: ACT doc + ROADMAP row
RECON commit 2: probes + .ll evidence
```

No C1 RED commit is needed (the three RED fixtures already exist
from IR-RETURN-SLOT-FORWARDING01; the recon reuses them).

No IMPL commit is permitted under this ACT id.

## 11. Closure handoff (lite; appended at CLOSE)

Follow `docs/factory/HANDOFF-TEMPLATE.md` (lite). The handoff MUST
contain:

```text
VERDICT
IDENTITY (entry SHA, final SHA, branch)
Q1..Q6 results (with the markdown tables and .ll evidence paths)
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
HANDOFF document is required for this RECON.

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

## Appendix B. Why this is RECON, not IMPL

F3 (RED before production implementation) and F7 (scope is
conserved) both argue for RECON-first when the hypothesis is
structural:

- The hypothesis is that LLVM mem2reg is the smallest robust
  seam. That is testable without a production edit (Q4).
- Any IMPL edit before Q4 PASS risks implementing a fix that
  does not work, and then chasing ghosts.
- The IMPL freeze has many degrees of freedom (placement,
  hoist, C API availability, escape analysis, type scope) that
  are best resolved AFTER recon, not before.

If the reviewer wants to skip recon and authorise IMPL directly,
that should be a separate CORRECTION01 ACT opened with explicit
scope overrides.

## Appendix C. Preliminary C API recon (snapshot at entry)

Recorded at RECON open; the agent doing the recon must verify
and extend.

```text
Question: is LLVMRunPasses exposed via a header the project
already includes?

Verified at entry (HEAD = 0501569):
  grep -rn 'LLVMRunPasses' src/ -> 0 matches
  grep -rn 'LLVMCreatePassBuilderOptions' src/ -> 0 matches
  grep -rn 'llvm-c/Transforms/PassBuilder.h' src/ -> 0 matches

Implication: at RECON start, the project does NOT yet include
the LLVM C PassBuilder headers. A future CORRECTION01 will need
to (a) verify those headers are available in the build's LLVM
distribution, (b) include them in src/llvm-backend.c, and (c)
add any needed link flags. This is recon-only observation; it
is not a permission to touch build files under this ACT id.
```
