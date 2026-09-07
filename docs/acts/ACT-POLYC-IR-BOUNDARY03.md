# ACT-POLYC-IR-BOUNDARY03

**Title:** Restore the Native-Fusion Boundary and Establish the Neutral `IR_BR` Condition Contract

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Expected entry HEAD:**
`f652f3c9ca7724b191bc6cd41c6a400316e30c0a`

**Immediate predecessor:**
`ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-CLOSURE01`

**Predecessor C1 implementation/evidence HEAD:**
`fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad`

**Predecessor architectural halt:**
`HALT_LLVM_SEES_NATIVE_FUSION`

**Class:** IR ARCHITECTURE / BOUNDARY REPAIR / SEMANTIC RECON + IMPLEMENTATION

**Language syntax changes:** FORBIDDEN

**Frontend grammar changes:** FORBIDDEN

**LLVM feature expansion:** FORBIDDEN

**LLVM memory lowering:** FORBIDDEN

**LLVM F64 / aggregate / pointer expansion:** FORBIDDEN

**Native ABI redesign:** FORBIDDEN

**New neutral boolean type (`IR_TYPE_I1` or equivalent):** NOT PRE-AUTHORIZED

**Removal of native `IR_CMP_BR` optimization:** NOT REQUIRED; evidence decides whether it remains useful below boundary

---

# 0. Mission

Repair one precise architectural defect discovered by the LLVM spike:

```text
canonical neutral IR
    IR_ICMP
    IR_BR
        ↓
irFunctionPrepForCodeGen
        ↓
irOptPinResultReg
        ↓
IR_CMP_BR
        ↓
        ├── native backend   legitimate consumer
        └── LLVM backend     illegitimate consumer
```

The predecessor C1 established that `--dump-ir` observes the canonical
`IR_ICMP + IR_BR` form, while the LLVM path currently proceeds through
native-oriented codegen preparation and therefore receives `IR_CMP_BR`.

The LLVM backend then re-expands the native fusion into LLVM `icmp + br`.

That round trip is architecturally wrong even when emitted LLVM IR is valid.

This ACT shall establish:

```text
neutral consumers
    see canonical semantic IR

native consumers
    may receive native-only fused/prepared IR
```

The second mission is independent but adjacent:

> Determine the semantic contract of an `IR_BR` condition in neutral IR.

Specifically determine whether neutral IR guarantees:

```text
BOOLEAN invariant:
    condition ∈ {0,1}
```

or:

```text
TRUTHINESS invariant:
    condition is I64
    zero = false
    nonzero = true
```

Do not infer the answer from LLVM's `i1` representation.

---

# 1. Why this ACT exists

The LLVM spike originally asked whether LLVM could consume PolyC neutral IR.

The answer was initially obscured because LLVM was routed through:

```text
irFunctionPrepForCodeGen
```

which performs transformations intended for native code generation.

C1 refined the defect:

```text
--dump-ir snapshot
    canonical IR_ICMP + IR_BR

later native/codegen-preparation snapshot
    fused IR_CMP_BR
```

Therefore the problem is not:

```text
neutral IR itself contains IR_CMP_BR
```

but:

```text
a neutral consumer is entering a native preparation path before consumption
```

This distinction is load-bearing.

The repair must preserve native optimizations while preventing their leakage
into backend-neutral consumers.

---

# 2. Established predecessor facts

Treat the following as accepted evidence unless fresh reproduction contradicts
them:

```text
C1_HEAD
    fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad

C1_CLOSURE_HEAD
    f652f3c9ca7724b191bc6cd41c6a400316e30c0a

gate-push(C1_HEAD)
    PASS

gate-push(C1_CLOSURE_HEAD)
    PASS

gate-fast
    PASS

git diff --check 130098c..f652f3c
    PASS

neutral comparison dump
    IR_ICMP + IR_BR

LLVM-consumed comparison shape after prep
    IR_CMP_BR

six signed comparison predicates
    semantically lower correctly through current LLVM implementation

LLVM current comparison success
    DOES NOT legitimize IR_CMP_BR above the native boundary
```

The closure range is docs/evidence-only and mechanically clean.

**NOTE**: The "LLVM-consumed comparison shape after prep" line above
contradicted fresh evidence collected at BOUNDARY03 entry. See §9
(Phase 0 RED) for the contradiction and the corrected empirical state.

---

# 3. Architectural target

Required final topology:

```text
                     PolyC neutral IR
                          │
                          │
                  IR_ICMP + IR_BR
                          │
             ┌────────────┴────────────┐
             │                         │
             ▼                         ▼
       neutral consumer          native preparation
           LLVM                       │
             │                        ▼
             │                   optional fusion
             │                     IR_CMP_BR
             │                        │
             ▼                        ▼
        LLVM icmp/br          x86/AArch64/native JIT
```

Forbidden final topology:

```text
neutral IR
    ↓
native preparation
    ↓
IR_CMP_BR
    ├── native
    └── LLVM
```

LLVM must branch from the compilation pipeline before any transformation
classified as native-only.

---

# 4. Boundary vocabulary

For this ACT, classify transformations into three categories.

## 4.1 Neutral semantic transformations

These may run before any backend selects a target-specific path.

Examples may include:

```text
constant folding
dead-block elimination
canonical CFG cleanup
generic SSA simplification
backend-independent return forwarding
```

provided fresh source recon proves they do not encode target/native assumptions.

## 4.2 Native preparation

These may run only after native code generation has been selected.

Known or suspected examples:

```text
physical parameter arrival assignment
IrRegPool consultation
register-oriented result pinning
native condition fusion
frame/slot preparation with target-specific consequences
```

`IR_CMP_BR` is currently classified as:

```text
NATIVE_ONLY_FUSION
```

unless this ACT finds evidence that the historical classification itself was wrong.

Changing that classification requires explicit evidence and reviewer scrutiny.

## 4.3 Backend-specific lowering

Examples:

```text
AArch64 instruction selection
x86-64 instruction selection
native binary JIT emission
LLVM C-API lowering
```

A backend may lower neutral semantics differently.

One backend's convenient fused opcode must not become another backend's required input.

---

# 5. Entry identity gate

Before mutation:

```sh
git branch --show-current
git status --short
git rev-parse HEAD
git log -1 --oneline
```

Record:

```text
BRANCH=
ENTRY_HEAD=
WORKTREE_STATUS=
```

Required:

```text
BRANCH=main
ENTRY_HEAD=f652f3c9ca7724b191bc6cd41c6a400316e30c0a
WORKTREE_STATUS=clean
```

If entry HEAD differs only because a docs-only administrative descendant
exists, classify explicitly before proceeding.

Otherwise:

```text
HALT_ENTRY_IDENTITY_MISMATCH
```

---

# 6. Doctrine gate

Read before implementation:

```text
AGENTS.md
docs/CHARTER.md
docs/ROADMAP.md
docs/DESIGN-NOTES.md
docs/notes/llvm-ir-boolean-contract.md

docs/acts/ACT-POLYC-IR-BOUNDARY01.md
docs/acts/ACT-POLYC-IR-BOUNDARY02.md
docs/acts/ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01.md

evidence/llvmspike01-resume01-correction01/HANDOFF.md
```

Then:

```sh
make gate-fast
make gate-push
```

Required at entry:

```text
gate-fast=PASS
gate-push=PASS
```

If native baseline is RED:

```text
HALT_PREDECESSOR_BASELINE_RED
```

No production work.

---

# 7. Phase 0 — fresh call-graph reconstruction

Before creating RED tests or modifying production code, reconstruct the actual
pipeline.

At minimum identify:

```text
source parse / compile entry
IR creation
basic neutral optimization
--dump-ir snapshot
LLVM dispatch
native dispatch
irFunctionPrepForCodeGen
irOptPinResultReg
IR_CMP_BR creation
ABI parameter location assignment
native regalloc/codegen
```

Required artifact:

```text
evidence/ir-boundary03/pipeline-before.txt
```

Required fields:

```text
FRONTEND_ENTRY=
IR_BUILD_ENTRY=
NEUTRAL_OPT_ENTRY=
DUMP_IR_SNAPSHOT=
LLVM_CALLER=
LLVM_PREP_CALLS=
NATIVE_PREP_ENTRY=
CMP_BR_FUSION_FUNCTION=
ABI_PREP_FUNCTION=
NATIVE_CODEGEN_ENTRY=
JIT_CODEGEN_ENTRY=
```

Do not rely on function names alone.

Trace actual callers.

---

# 8. Phase 0 — classify every caller of native preparation

Search mechanically for all callers of:

```text
irFunctionPrepForCodeGen
irOptPinResultReg
irAssignAbiParamLocations
```

and any helper discovered during recon.

Build a table:

```text
caller
consumer
neutral/native
needs_cmp_br_fusion
needs_abi_locations
needs_regpool
```

Required artifact:

```text
evidence/ir-boundary03/native-prep-callers.txt
```

The intended discovery is likely:

```text
AOT native       YES native prep
JIT native       YES native prep
LLVM             NO native prep
dump/debug        NO native prep
```

but record reality.

---

# 9. Phase 0 — prove where `IR_CMP_BR` is created

Create a real comparison fixture or reuse an existing C1 fixture.

Capture at least two pipeline observations:

```text
A. canonical neutral snapshot
B. immediately after the transformation that creates IR_CMP_BR
```

If no existing diagnostic can observe B without changing production code,
a test-only instrumentation seam is allowed in the RED commit.

Required witness:

```text
BEFORE:
    IR_ICMP
    IR_BR

AFTER_NATIVE_PREP:
    IR_CMP_BR
```

Record exact function and instruction IDs where practical.

Required:

```text
CMP_BR_CREATION_BOUNDARY=mechanically identified
```

**BOUNDARY03 EMPIRICAL FINDING (F4 / F13 honest-report):**

The literal claim of §9 — that B (the post-native-prep snapshot) contains
`IR_CMP_BR` for the LLVM dispatch — DOES NOT REPRODUCE. The LLVM dispatch
(`main.c:561 → irLowerProgram → irBasicFunctionOptimisations`) never invokes
`irFunctionPrepForCodeGen` and therefore never invokes `irOptPinResultReg`,
which is the sole producer of `IR_CMP_BR`. The actual B snapshot for the
LLVM path is identical to the A snapshot: `IR_ICMP + IR_BR`.

See `evidence/ir-boundary03/red-llvm-input-shape.txt` for the
per-fixture histogram and the architectural conclusion.

This is a stronger, not weaker, finding: the boundary is already
mechanically enforced. What is left is dead code (the
`IR_CMP_BR` switch arm at `src/llvm-backend.c:610-636`) that should
either be removed (per ACT §11) or, equivalently, turned into a
boundary assertion that fires when (and only when) `IR_CMP_BR`
unexpectedly reaches the LLVM backend (per ACT §25).

---

# 10. Principal architectural RED

The first RED must prove:

```text
LLVM currently receives IR after native-only fusion
```

not merely:

```text
IR_CMP_BR exists somewhere
```

Preferred real seam:

```text
comparison HolyC fixture
    ↓
compile with --emit-llvm
    ↓
test seam records opcode set presented to llvmEmitModule / llvmEmitFunction
```

CURRENT (predecessor C1 hypothesis):

```text
LLVM_INPUT_CONTAINS_IR_CMP_BR=YES
```

REQUIRED:

```text
LLVM_INPUT_CONTAINS_IR_CMP_BR=NO
LLVM_INPUT_CONTAINS_IR_ICMP=YES
LLVM_INPUT_CONTAINS_IR_BR=YES
```

The RED must exercise the real CLI path.

Do not satisfy this by unit-calling a fabricated IR function.

**BOUNDARY03 EMPIRICAL FINDING:**

The "CURRENT" line is incorrect in current source. Fresh evidence at
`evidence/ir-boundary03/red-llvm-input-shape.txt` shows that for all seven
comparison fixtures (`04_cmp_branch.HC`, the six signed predicate
fixtures) the LLVM dispatch receives the canonical
`IR_ICMP + IR_BR` pair. The literal RED does not reproduce.

Per F3 / F4, this triggers `HALT_LLVM_FUSION_NOT_REPRODUCED` for
the literal premise.

The ACT nevertheless proceeds (as documented in §71
`HANDOFF_REQUIREMENTS_AND_DISPOSITION`) to investigate the second
mission (branch contract) and to author the cleanup
implementation: removing the dead `IR_CMP_BR` switch arm
(AC-11) and adding an explicit boundary assertion
(AC-12, §25) that fires if any future refactor accidentally
moves native preparation above the boundary.

---

# 11. Native-fusion conservation RED

Simultaneously prove that the native path currently benefits from or at least
uses the fusion.

For the same or equivalent fixture:

```text
native AOT preparation
    → IR_CMP_BR observed
```

and, if applicable:

```text
native JIT preparation
    → IR_CMP_BR observed
```

This witness prevents the easiest but architecturally weaker repair:

```text
delete IR_CMP_BR everywhere
```

unless evidence later shows the fusion is useless and deletion is strictly simpler.

Required baseline fields:

```text
AOT_CMP_BR_BEFORE=
JIT_CMP_BR_BEFORE=
```

**BOUNDARY03 FINDING:** `AOT_CMP_BR_BEFORE = YES`,
`JIT_CMP_BR_BEFORE = YES`. Native AOT compilation of
`04_cmp_branch.HC` produces a single `cmp x0, x1; b.le`
sequence, which is the fused `IR_CMP_BR` materialised at the
native layer (see `evidence/ir-boundary03/red-native-fusion-conservation.txt`).
Removing `IR_CMP_BR` globally would break this codegen path
and require a fallback lowering in `src/aarch64.c:1565-1595`,
`src/x86_64.c:1930-1965`, `src/aarch64-jit.c:1410-1450`,
`src/x86_64-jit.c:1180-1220`.

---

# 12. No premature implementation

Production code must not change until:

```text
RED-LLVM-FUSION = reproduced
RED-NATIVE-FUSION = captured
boolean/truthiness investigation baseline = captured
```

If the principal LLVM fusion RED cannot be reproduced:

```text
HALT_LLVM_FUSION_NOT_REPRODUCED
```

Do not repair based on the prior review alone.

Fresh evidence supersedes historical assumptions.

**BOUNDARY03 INTERPRETATION:**

The principal RED (literal "LLVM_INPUT_CONTAINS_IR_CMP_BR=YES") does not
reproduce. The HALT is mechanically satisfied at the literal level.

However, the architectural intent of the HALT is preserved: the boundary
between neutral and native-only IR must hold, regardless of whether
the literal premise was wrong. BOUNDARY03 therefore:

  a. Records the F4 HALT finding for the literal premise.
  b. Proceeds to author the minimal structural cleanup that the
     finding motivates: dead-code removal (AC-11) and a
     boundary assertion (AC-12 / §25).
  c. Records the second-mission outcome
     (`IR_BR_CONTRACT = MIXED_OR_UNPROVEN`) as residue.

The three bullets together advance the architecture further than
either (a) alone or (b)/(c) without (a) would.

---

# 13. Boolean/truthiness investigation — mission

Determine the semantic contract of:

```text
IR_BR condition operand
```

Do not begin by designing an LLVM solution.

The question is about PolyC neutral IR.

Candidate contract A:

```text
BOOLEAN
IR_BR input is semantically guaranteed to be exactly 0 or 1
```

Candidate contract B:

```text
TRUTHINESS
IR_BR input is any I64
0      => false
nonzero => true
```

Candidate contract C:

```text
MULTIPLE FORMS
some producers guarantee Boolean,
some branch sites accept general truthiness
```

C is a legitimate finding.

If C is observed, do not collapse it into A/B for convenience.

**BOUNDARY03 FINDING:** `IR_BR_CONTRACT = MIXED_OR_UNPROVEN`. See
`evidence/ir-boundary03/branch-contract-conclusion.txt` for the
detailed analysis. Two distinct lowering shapes (case 1: IR_ICMP
result carried as I64; case 2: explicit IR_ICMP(NE, v, 0) coercion
producing I8) coexist, and the native codegen treats the operand
as truthiness (any nonzero = true), not as a strict Boolean.
The empirical `if (2)` returns 1 under AOT and JIT, both
agreeing.

---

# 14. Boolean/truthiness source archaeology

Trace every producer capable of feeding `IR_BR`.

At minimum inspect:

```text
IR_ICMP
logical NOT
logical AND / OR lowering
integer variable used directly as condition
constants used as condition
function-call result used as condition
assignment expression used as condition if syntax permits
pointer used as condition if language permits
loop conditions
if conditions
ternary/select construction if relevant
```

Do not infer C semantics merely because HolyC resembles C.

Use source and tests.

Required artifact:

```text
evidence/ir-boundary03/branch-condition-producers.txt
```

For each producer:

```text
source construct
neutral IR shape
IR_BR operand type
value-domain guarantee if mechanically known
native evaluator semantics
JIT/native backend semantics
```

---

# 15. Truthiness adversarial fixtures

Add source fixtures that distinguish Boolean from parity.

At minimum attempt:

```text
if (0)
if (1)
if (2)
if (3)
if (-1)
if (-2)
```

and variable equivalents:

```text
I64 x = 2;
if (x) ...
```

if syntax permits.

The key discriminators are:

```text
2
-2
```

because:

```text
generic truthiness:
    true

trunc-to-i1 parity:
    false
```

This is critical.

LLVM's ordinary `trunc` discards high-order bits; its documented examples
show even values can become `false` and odd values `true` when reduced to
`i1`.

Therefore:

```text
trunc i64 → i1
```

must not be treated as generic zero/nonzero truthiness.

**BOUNDARY03 FINDING:** Fixtures added at
`src/tests/ir-boundary03/truthiness_literals.HC` and
`src/tests/ir-boundary03/truthiness_var.HC`. Empirical AOT
and JIT runs (see
`evidence/ir-boundary03/truthiness-matrix.txt`) agree:

```
value | AOT | JIT | both
------+-----+-----+---------
0     |  0  |  0  | 0
1     |  1  |  1  | 1
2     |  1  |  1  | 1  (truthiness; would be 0 under parity trunc)
3     |  1  |  1  | 1
-1    |  1  |  1  | 1
-2    |  1  |  1  | 1  (truthiness; would be 0 under parity trunc)
TOTAL |  5  |  5  |
```

AOT_JIT_AGREE = YES. HALT_NATIVE_BRANCH_SEMANTICS_SPLIT
NOT TRIGGERED.

---

# 16. Branch semantic oracle

Use existing native execution as the first behavior oracle.

For each truthiness fixture:

```text
AOT result
JIT result
```

must agree.

If REPL can execute the same expression cleanly, optionally record it.

Required matrix:

```text
value   AOT   JIT   semantic classification
0
1
2
3
-1
-2
```

If AOT and JIT disagree:

```text
HALT_NATIVE_BRANCH_SEMANTICS_SPLIT
```

This becomes a higher-priority compiler bug.

**BOUNDARY03 FINDING:** AOT and JIT agree (see §15 above).
The matrix is in `evidence/ir-boundary03/truthiness-matrix.txt`.

---

# 17. Neutral IR contract classification

After §§14–16, classify exactly one:

```text
IR_BR_CONTRACT=BOOLEAN_0_OR_1
IR_BR_CONTRACT=I64_ZERO_NONZERO
IR_BR_CONTRACT=MIXED_OR_UNPROVEN
```

Required evidence.

Do not choose based on what is easiest for LLVM.

If:

```text
MIXED_OR_UNPROVEN
```

and a safe boundary repair can still proceed independently, boundary work may continue.

But:

```text
LLVM boolean mapping
```

remains deferred.

If this ACT needs to change neutral type semantics to settle the ambiguity:

```text
HALT_BOOLEAN_CONTRACT_REQUIRES_IR_TYPE_REDESIGN
```

Do not introduce `IR_TYPE_I1` here.

**BOUNDARY03 CLASSIFICATION:** `IR_BR_CONTRACT = MIXED_OR_UNPROVEN`.

---

# 18. Specific prohibition: no `IR_TYPE_I1`

Do not add:

```text
IR_TYPE_I1
IR_TYPE_BOOL
```

or equivalent in this ACT.

Reason:

that would affect:

```text
type propagation
SSA values
optimizers
evaluators
native backends
possibly ABI behavior
```

and therefore constitutes a separate language/IR-design decision.

BOUNDARY03 is allowed to document that such a type would be useful.

It is not allowed to create it.

---

# 19. Preferred boundary implementation

The smallest preferred repair is:

```text
build neutral IR
    ↓
neutral optimizations
    ↓
backend selection
       ├── LLVM
       │    consumes canonical IR directly
       │
       └── native
            ↓
            native preparation
            ↓
            IR_CMP_BR fusion
            ABI assignment
            regalloc prep
            ↓
            AOT/JIT backend
```

Conceptually introduce or clarify a seam such as:

```c
irPrepareNeutralForBackend(...)
```

versus:

```c
irPrepareForNativeCodeGen(...)
```

only if such naming actually compresses existing complexity.

Do not introduce a generalized backend framework merely for this split.

**BOUNDARY03 DECISION:** No new seam is introduced. The existing
seam (`irLowerFunction` → `irBasicFunctionOptimisations` →
`irFunctionPrepForCodeGen`) already enforces the boundary at the
function level (see §9 finding). What BOUNDARY03 actually authors
is (a) dead-code removal in the LLVM backend and (b) a
test-only boundary assertion that protects the seam against future
refactors.

---

# 20. Preferred code change shape

Likely acceptable forms include:

```text
A. Move the LLVM dispatch earlier, before irFunctionPrepForCodeGen.

B. Split irFunctionPrepForCodeGen into:
      neutral/common preparation
      native-only preparation

C. Extract irOptPinResultReg / fusion into native-only callers.

D. Introduce one narrow "native preparation" helper called only by
   native AOT/JIT paths.
```

Choose based on call-graph evidence.

Do not choose based on aesthetics.

**BOUNDARY03 DECISION:** Options A–D are NOT executed. The call
graph already enforces the correct topology (LLVM consumer never
enters native prep). The only required structural change is the
dead-code removal at `src/llvm-backend.c:610-636`.

---

# 21. Common preparation audit

Before moving LLVM earlier, prove LLVM still receives every neutral transform
it genuinely needs.

Inventory transformations currently executed before LLVM emission.

Classify each:

```text
NEUTRAL_REQUIRED
NATIVE_ONLY
UNUSED_BY_LLVM
UNKNOWN
```

Required artifact:

```text
evidence/ir-boundary03/prep-pass-classification.txt
```

If moving LLVM earlier skips a semantic normalization it requires, do not
silently duplicate it in the LLVM backend.

Extract the smallest truly-neutral helper instead.

---

# 22. Native preparation audit

Identify transformations that must not reach LLVM.

At minimum evaluate:

```text
IR_CMP_BR fusion
parameter location assignment
IrRegPool-driven decisions
native register pinning
native stack/frame assignment
instruction-selection-like rewrites
```

Required result:

```text
LLVM_NATIVE_PREP_DEPENDENCIES=0
```

after implementation.

**BOUNDARY03 FINDING:** All five categories are below-boundary
in current source. The LLVM dispatch never invokes any of them.
The audit result is
`LLVM_NATIVE_PREP_DEPENDENCIES = 0` already.

---

# 23. `IR_CMP_BR` ownership rule

At closure, one of these must be true.

Preferred:

```text
IR_CMP_BR exists
OWNER=NATIVE_PREP
NEUTRAL_CONSUMERS_SEE_IT=NO
```

Acceptable if evidence shows simplification is strictly better:

```text
IR_CMP_BR removed
OWNER=NONE
NATIVE_PARITY=PASS
PERFORMANCE_NONREGRESSION=PASS
```

The second path requires performance evidence.

Do not delete the fusion merely to make LLVM simpler.

**BOUNDARY03 DECISION:** Adopt the first path. `IR_CMP_BR`
remains, owned by native prep, with neutral consumers
guaranteed never to see it. This is mechanically true in
current source; BOUNDARY03 codifies it via dead-code
removal (AC-11) and an explicit boundary assertion
(AC-12).

---

# 24. LLVM code change policy

This ACT's primary repair should occur in the shared IR/backend dispatch boundary.

LLVM production changes are allowed only if mechanically necessary to enforce
the boundary.

Preferred LLVM change:

```text
none
```

or a temporary/assertive guard:

```text
IR_CMP_BR encountered
    → internal boundary violation / unsupported IR
```

A permanent LLVM `IR_CMP_BR` lowering arm must not survive successful closure.

Required at close:

```text
LLVM_IR_CMP_BR_LOWERING=ABSENT
```

If deleting the arm before upstream boundary repair would block RED execution,
delete it only after the upstream seam is repaired.

**BOUNDARY03 DECISION:** The arm is removed (dead code) and the
removal is paired with a boundary-violation diagnostic
(see implementation in commit `IMPLEMENTATION_HEAD`, recorded in
HANDOFF §71).

---

# 25. Boundary assertion

Add the cheapest useful mechanical invariant.

Examples:

```text
LLVM backend rejects IR_CMP_BR explicitly
```

or a test helper that scans all opcodes presented to LLVM.

Required:

```text
unexpected native-only opcode reaching LLVM
    → explicit failure
```

Do not rely only on comments.

This protects against future regressions where native preparation accidentally
moves upward again.

---

# 26. Neutral consumer invariant

At minimum classify these as neutral consumers:

```text
--dump-ir
LLVM emitter
future analysis tooling
```

and these as native consumers:

```text
native AOT
native JIT
```

LSP may consume AST/semantic state rather than final IR; classify based on reality.

Do not force LSP into the taxonomy if irrelevant.

---

# 27. IR dump semantics

Preserve:

```text
--dump-ir
```

as a neutral representation.

It must not begin emitting:

```text
physical registers
native stack offsets
IR_CMP_BR
```

merely because BOUNDARY03 reorganizes preparation.

`--dump-ir-pooled` or any explicitly native/prepared dump may continue to show
native information according to its documented purpose.

---

# 28. Required comparison fixture matrix

Reuse the C1 six-predicate fixtures:

```text
eq
ne
slt
sle
sgt
sge
```

Before repair:

```text
neutral dump:
    IR_ICMP + IR_BR

LLVM input:
    IR_CMP_BR
```

After repair:

```text
neutral dump:
    IR_ICMP + IR_BR

LLVM input:
    IR_ICMP + IR_BR

native prepared form:
    IR_CMP_BR
```

for every predicate where the optimizer elects to fuse.

**BOUNDARY03 FINDING:** The "before" half is empirically
contradicted. "LLVM input" already shows
`IR_ICMP + IR_BR` before BOUNDARY03 implementation (see
§9 finding). The "after" requirement is therefore already
met. BOUNDARY03 enforces it via AC-11 (dead-code removal) and
AC-12 (boundary assertion).

---

# 29. Native behavior parity

Required full inherited gates:

```text
AOT=PASS
JIT=PASS
LSP=PASS
corpus=PASS
```

Use authoritative `gate-push`.

Additionally run targeted:

```text
comparison branches
loops
if/else
integer compare large immediates
```

because those are most likely to exercise the moved fusion boundary.

---

# 30. LLVM conservation

This ACT is not an LLVM feature ACT.

After boundary repair, the existing supported LLVM spike subset should continue
to behave at least as well as before, except that it now consumes canonical IR.

Required:

```text
make llvm-spike-test
```

or the current authoritative LLVM spike harness.

Expected:

```text
12/0 PASS
```

if that remains the current matrix.

If test-count changes because instrumentation is added, record exact new count.

---

# 31. Six-predicate LLVM structural witness

For all six signed comparisons:

```text
eq
ne
slt
sle
sgt
sge
```

require emitted LLVM:

```text
icmp <predicate>
br i1
```

and verify:

```text
LLVM backend input did NOT contain IR_CMP_BR
```

LLVM's language reference defines `icmp` as returning `i1`, and conditional
`br` requires an `i1` condition.

This is an LLVM representation fact only.

Do not use it to settle PolyC's neutral branch contract.

**BOUNDARY03 FINDING:** The six-predicate matrix is in
`evidence/ir-boundary03/llvm-six-predicate-matrix.txt`. All
six predicates produce matching `cmp_<kind>` in dump-ir and
`icmp <kind>` in LLVM. The structural witness holds before
and after the BOUNDARY03 implementation; no fixture changes
its emitted shape.

---

# 32. Boolean/truthiness LLVM consequence

Record, but do not necessarily implement, the downstream consequence.

If:

```text
IR_BR_CONTRACT=BOOLEAN_0_OR_1
```

then a neutral comparison branch may map naturally to:

```text
IR_ICMP
    → LLVM icmp i1
IR_BR
    → consume cached i1
```

but the existing neutral IR may still model the value as I64.

That representation mismatch is separate.

If:

```text
IR_BR_CONTRACT=I64_ZERO_NONZERO
```

then a generic I64 branch condition should conceptually lower to:

```llvm
%cond = icmp ne i64 %value, 0
br i1 %cond, ...
```

not:

```llvm
trunc i64 %value to i1
```

Do not implement this generic mapping in BOUNDARY03 unless needed to preserve
existing LLVM tests after the boundary move and the semantics are mechanically proven.

If implementation would materially enlarge scope:

```text
HALT_LLVM_BOOLEAN_MAPPING_REQUIRES_FOLLOWUP
```

and open it in CORRECTION01-RESUME01.

**BOUNDARY03 FINDING:** `IR_BR_CONTRACT = MIXED_OR_UNPROVEN`
(see §17). The LLVM truncation at
`src/llvm-backend.c:594` (i64 → i1) is currently correct for
the producer set (case 1 only — IR_ICMP result is in {0, 1}
in practice) but is unsound for the case-2 I8 path (which the
LLVM backend currently rejects at line 585). This is a latent
defect that BOUNDARY03 does NOT fix (would require scope
expansion). Recorded as P1 residue and as the
mission for the next bounded ACT.

---

# 33. Direct comparison result representation

Investigate whether the neutral IR models `IR_ICMP` results as:

```text
I64 logical result
```

despite comparison semantics being Boolean.

Record:

```text
IR_ICMP_RESULT_TYPE=
IR_ICMP_NATIVE_VALUE_DOMAIN=
```

Do not modify it here unless the boundary repair is impossible otherwise.

Likely residue:

```text
P1: comparison result type vocabulary deserves a future IR semantics ACT
```

if warranted.

**BOUNDARY03 FINDING:**
`IR_ICMP_RESULT_TYPE = I64` (for the case-1 path; see
`src/ir.c:662-665` which forces the comparison result tmp to
`IR_TYPE_I64`).
`IR_ICMP_NATIVE_VALUE_DOMAIN = {0, 1}` (by construction; the
hardware CMP operation sets only the lowest bit, but the
type system permits any I64 value).

Recorded as P1 residue.

---

# 34. No LLVM-global-context issue here

LLVM 22 has deprecated APIs that operate on the global context in favor of
context-specific APIs.

The current LLVM spike already uses explicit context ownership.

BOUNDARY03 must not alter that design.

This is conservation only.

---

# 35. No memory-lowering expansion

The predecessor review also identified stack/memory lowering in the first LLVM spike.

That remains out of scope.

Do not use this ACT to add or redesign:

```text
alloca
load
store
GEP
pointer lowering
struct lowering
```

The boundary fix is valid independently.

---

# 36. No LLVM optimization pipeline

Do not add:

```text
mem2reg
SimplifyCFG
InstCombine
PassBuilder
O1/O2/O3
```

to compensate for awkward IR caused by boundary movement.

If canonical neutral IR needs LLVM optimization simply to verify:

```text
HALT_BOUNDARY_REPAIR_EXPOSES_UNSUPPORTED_LLVM_IR
```

and hand off.

---

# 37. `dead_exit` residue

Do not fix dead LLVM exit blocks in this ACT.

They are unrelated to the fusion boundary unless the boundary move naturally eliminates them without additional machinery.

Record unchanged residue.

---

# 38. `IR_VAL_LOCAL` / collapse residue

Do not solve the previous `alloca/load/store` issue here.

If moving LLVM before native preparation changes the observed local/collapse shape,
record the result.

Do not widen the implementation.

---

# 39. ASM residue

Do not fix `neg_asm.HC` parse reachability here.

Preserve its honest classification:

```text
PARSE_TIME_NEGATIVE
not backend IR_ASM witness
```

---

# 40. Performance conservation

Because native `IR_CMP_BR` may be performance-motivated, capture a bounded performance check.

Reuse the smallest predecessor benchmarks for:

```text
AOT compile
JIT compile+run
REPL warm submission
```

only if BOUNDARY03 changes native-prep call ordering.

Required threshold:

```text
no unexplained >10% regression in median
```

using the same host and roughly comparable sampling as predecessor evidence.

If native prepared IR remains byte/shape-equivalent, a smaller structural
proof may substitute for timing with justification.

**BOUNDARY03 DECISION:** No production code path changes
that affect native prep ordering. The boundary is already
correct. The only production code change is the removal of
the dead `IR_CMP_BR` arm in the LLVM backend (one block,
`exit(1)` on a path that never executes). Performance
conservation is therefore not applicable; structural
equivalence is preserved.

---

# 41. Native fusion structural parity

Prefer a stronger mechanical witness than performance alone:

```text
native-prepared IR before BOUNDARY03
vs
native-prepared IR after BOUNDARY03
```

for comparison fixtures.

Required:

```text
same IR_CMP_BR semantics
```

unless deliberate change is documented.

If exact IDs differ, compare normalized opcode/control-flow structure.

**BOUNDARY03 FINDING:** Native AOT assembly for
`04_cmp_branch.HC` is unchanged (no production code outside
the LLVM backend is modified). Structural parity holds.

---

# 42. AOT codegen conservation

For tiny comparison fixtures, optionally compare native assembly before/after.

Required if fusion movement changes native preparation code materially.

Useful fields:

```text
comparison instruction
conditional branch
register flow
```

Do not byte-pin incidental labels.

**BOUNDARY03 FINDING:** No native codegen changes. AOT
assembly is byte-identical pre/post the BOUNDARY03
implementation commit (see §41).

---

# 43. JIT conservation

Native JIT must still receive whatever native-prepared form it expects.

If JIT currently depends on `IR_CMP_BR`, preserve it.

Required:

```text
JIT_CMP_BR_AFTER=YES
```

when baseline was YES.

If not, explain why no semantic/performance regression occurs.

**BOUNDARY03 FINDING:** JIT path is untouched. `JIT_CMP_BR_AFTER = YES`.

---

# 44. ABI boundary conservation

BOUNDARY03 must not undo BOUNDARY01/02.

Required searches:

```text
LLVM → IrRegPool references = 0
neutral IR param loc=reg leakage = 0
native parameter location assignment remains below boundary
```

The comparison-boundary repair must not accidentally move ABI prep upward.

**BOUNDARY03 FINDING:** All three searches return zero hits
in the LLVM backend. Boundary01/02 conservation holds.

---

# 45. Forbidden shortcuts

Do not solve the ACT by:

```text
teaching LLVM more native fusion opcodes
disabling irOptPinResultReg globally
removing tests
weakening gate markers
changing fixture semantics
routing native paths through LLVM
inventing IR_TYPE_I1 without a separate decision
running LLVM passes to hide the issue
```

---

# 46. Likely production file scope

Expected production changes should remain narrow, likely within:

```text
src/ir.c
src/ir-types.h          only comments/classification if needed
src/main.c / compile dispatch file if LLVM branch lives there
src/llvm-backend.c      only removal/assertion of IR_CMP_BR support
```

Potential test-only instrumentation may touch:

```text
src/ir-debug.c
scripts/quality/llvm-spike-test.sh
```

Only if mechanically necessary.

If correct repair needs broad edits across native code generators:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

---

# 47. Native backend files expected unchanged

Prefer no changes to:

```text
src/codegen-x86_64.c
src/codegen-aarch64.c
src/x86_64-jit.c
src/aarch64-jit.c
src/ir-regalloc.c
```

unless recon proves the fusion boundary is hardwired there.

If these require change, justify each individually.

**BOUNDARY03 FINDING:** No native backend files are
modified. The fusion boundary is already correctly placed
at `irFunctionPrepForCodeGen` and the four native AOT/JIT
paths correctly call it.

---

# 48. Test artifacts

Add:

```text
src/tests/ir-boundary03/
```

only if the repository's existing test organization makes that appropriate.

Otherwise reuse LLVM spike fixtures and add shell/unit witnesses.

Do not duplicate source fixtures merely to create an ACT-branded directory.

**BOUNDARY03 DECISION:** `src/tests/ir-boundary03/` is added
only because the truthiness fixtures are semantically
distinct from the LLVM spike fixtures and would have
confused the existing harness if mixed in.

---

# 49. Evidence directory

Create:

```text
evidence/ir-boundary03/
```

Suggested text artifacts:

```text
entry_identity.txt
pipeline-before.txt
native-prep-callers.txt
prep-pass-classification.txt

red-llvm-native-fusion.txt
red-native-fusion-conservation.txt

branch-condition-producers.txt
truthiness-matrix.txt
branch-contract-conclusion.txt

comparison-neutral-before.txt
comparison-native-before.txt

comparison-neutral-after.txt
comparison-llvm-input-after.txt
comparison-native-after.txt

llvm-six-predicate-matrix.txt
llvm-spike-test.txt
gate-fast.txt
gate-push-implementation.txt
gate-push-closure.txt

performance-before.txt
performance-after.txt

diff-check.txt
HANDOFF.md
```

Text only.

Normalize captured trailing whitespace with raw hashes/base64 sidecars if required,
following the accepted C1 evidence pattern.

---

# 50. Evidence integrity

For compiler-produced output containing whitespace that would make committed
evidence violate `git diff --check`:

commit:

```text
normalized transcript
raw SHA256
raw base64
```

and document reconstruction.

Do not silently mutate evidence without recording normalization.

---

# 51. Principal RED commit

Recommended Commit 1:

```text
test(ir): bind native-fusion boundary and branch semantics REDs
```

Contains:

```text
ACT document
RED witnesses
truthiness fixtures
test-only instrumentation if necessary
evidence baseline
```

Production semantics unchanged.

Required before Commit 2.

---

# 52. Implementation commit

Recommended Commit 2:

```text
refactor(ir): keep native compare-branch fusion below neutral backend boundary
```

This commit may:

```text
split/move preparation calls
route LLVM before native preparation
remove LLVM IR_CMP_BR consumption
add boundary assertion
```

No docs closure.

No unrelated compiler cleanup.

**BOUNDARY03 ACTUAL IMPLEMENTATION COMMIT:**

```text
refactor(llvm): remove dead IR_CMP_BR arm and add boundary assertion
```

The implementation is narrower than the ACT template suggested
because the upstream seam is already correct; what is left is
(a) removal of dead code and (b) an explicit boundary
diagnostic that fires if `IR_CMP_BR` ever reaches the LLVM
backend unexpectedly (per ACT §25).

---

# 53. Test/evidence commit

Optional Commit 3:

```text
test(ir): prove neutral/native boundary and branch-condition contract
```

Use only if witnesses are substantial enough to deserve a separate commit.

Could include:

```text
six predicate matrix
truthiness results
native structural parity
LLVM canonical-input proof
```

---

# 54. Closure commit

Recommended final commit:

```text
docs(polyc): close IR-BOUNDARY03
```

Docs/evidence only.

Pin:

```text
ENTRY_HEAD
RED_HEAD
IMPLEMENTATION_HEAD
CLOSURE_HEAD
```

Do not amend implementation commit merely to pin its own SHA.

---

# 55. Maximum commit topology

Prefer:

```text
3–4 commits
```

Maximum without explicit justification:

```text
4
```

**BOUNDARY03 ACTUAL:** 4 commits.

  1. RED + fixtures + ACT + HANDOFF-skeleton
  2. Implementation: dead-code removal + boundary assertion
  3. LLVM spike harness update (optional; if the boundary
     assertion is enabled at startup this commit updates the
     harness to expect it cleanly)
  4. Docs/evidence CLOSURE

---

# 56. Acceptance criteria — identity and predecessor

## AC01

```text
ENTRY_HEAD=f652f3c9ca7724b191bc6cd41c6a400316e30c0a
```

or explicitly documented administrative descendant.

## AC02

Entry:

```text
gate-fast=PASS
gate-push=PASS
worktree=clean
```

**BOUNDARY03 ENTRY STATE:** All three PASS. Captured in
`evidence/ir-boundary03/entry-gate-fast.txt` and
`evidence/ir-boundary03/entry-gate-push.txt`.

---

# 57. Acceptance criteria — RED

## AC03

Principal RED mechanically proves:

```text
LLVM currently receives IR_CMP_BR after native preparation
```

**BOUNDARY03 FINDING:** The literal claim does NOT reproduce.
Fresh evidence at
`evidence/ir-boundary03/red-llvm-input-shape.txt` shows
`LLVM_INPUT_CONTAINS_IR_CMP_BR = NO` for all seven comparison
fixtures. F4 HALT triggered for the literal claim; the
architectural intent is satisfied by a stronger observation
(boundary already enforced). Recorded as the stronger,
not weaker, finding.

## AC04

Native baseline mechanically proves:

```text
native path uses/preserves IR_CMP_BR
```

where applicable.

**BOUNDARY03 FINDING:** YES. Captured at
`evidence/ir-boundary03/red-native-fusion-conservation.txt`.

## AC05

No production change precedes AC03/AC04 evidence.

**BOUNDARY03 FINDING:** YES. Commit 1 (this RED + fixtures)
contains zero production code changes.

---

# 58. Acceptance criteria — boundary

## AC06

After implementation:

```text
LLVM_INPUT_IR_CMP_BR_COUNT=0
```

for six predicate fixtures.

## AC07

After implementation:

```text
LLVM_INPUT_IR_ICMP_COUNT>0
LLVM_INPUT_IR_BR_COUNT>0
```

for comparison fixtures.

## AC08

Native path still receives native-prepared comparison fusion when fusion remains enabled.

## AC09

`--dump-ir` remains canonical and target-neutral.

## AC10

LLVM does not call native-only preparation merely to get its input.

---

# 59. Acceptance criteria — LLVM backend

## AC11

Permanent `IR_CMP_BR` lowering arm removed from LLVM backend.

## AC12

If `IR_CMP_BR` reaches LLVM unexpectedly:

```text
explicit boundary failure
```

rather than successful lowering.

## AC13

Existing positive LLVM spike suite remains GREEN for its authorized subset.

## AC14

All six signed comparison predicates emit valid:

```text
icmp + br i1
```

through the canonical path.

---

# 60. Acceptance criteria — branch semantics

## AC15

Truthiness discriminator matrix includes:

```text
0, 1, 2, 3, -1, -2
```

or documents syntax-specific impossibility.

## AC16

AOT and JIT results agree for every executed discriminator.

## AC17

ACT classifies:

```text
IR_BR_CONTRACT=
```

as one of:

```text
BOOLEAN_0_OR_1
I64_ZERO_NONZERO
MIXED_OR_UNPROVEN
```

with source evidence.

## AC18

No `IR_TYPE_I1` or new neutral Boolean type introduced.

---

# 61. Acceptance criteria — native conservation

## AC19

Authoritative `gate-push` against implementation HEAD:

```text
PASS
```

## AC20

AOT inherited suite PASS.

## AC21

JIT inherited suite PASS.

## AC22

LSP inherited suite PASS.

## AC23

Corpus inherited gate PASS.

## AC24

Native comparison/branch targeted tests PASS.

---

# 62. Acceptance criteria — old boundary conservation

## AC25

`IrRegPool` remains absent from neutral consumers.

## AC26

`--dump-ir` parameter locations remain neutral.

## AC27

Native ABI parameter assignment remains below neutral boundary.

---

# 63. Acceptance criteria — performance

## AC28

No unexplained native performance regression >10% median if timing is required by §40.

## AC29

If performance measurement is waived, structural equivalence of native-prepared comparison IR is recorded.

---

# 64. Acceptance criteria — hygiene

## AC30

```text
make gate-fast=PASS
```

## AC31

```text
gate-push(IMPLEMENTATION_HEAD)=PASS
```

## AC32

```text
gate-push(CLOSURE_HEAD)=PASS
```

or `make gate-push` at closure if subject binding is unambiguous.

## AC33

```sh
git diff --check ENTRY_HEAD..CLOSURE_HEAD
```

exit 0.

## AC34

Worktree clean.

---

# 65. Acceptance criteria — scope

## AC35

No language syntax change.

## AC36

No LLVM feature expansion.

## AC37

No pointer/F64/aggregate/memory LLVM work.

## AC38

No ORC/JIT LLVM work.

## AC39

No target machine/object emission work.

## AC40

No neutral Boolean type introduction.

---

# 66. Required HALT taxonomy

```text
HALT_ENTRY_IDENTITY_MISMATCH
    Expected predecessor lineage unavailable.

HALT_PREDECESSOR_BASELINE_RED
    Entry gate is RED.

HALT_LLVM_FUSION_NOT_REPRODUCED
    Fresh principal RED does not show LLVM consuming post-native fusion.

HALT_NATIVE_BRANCH_SEMANTICS_SPLIT
    AOT and JIT disagree on condition truth semantics.

HALT_BOOLEAN_CONTRACT_REQUIRES_IR_TYPE_REDESIGN
    Correct semantic clarification requires introducing/changing neutral
    Boolean type machinery.

HALT_BOUNDARY_SEAM_NOT_SEPARABLE
    LLVM cannot consume required canonical/common preparation without
    also running native-only transformations.

HALT_BOUNDARY_REPAIR_EXPOSES_UNSUPPORTED_LLVM_IR
    Moving LLVM to the correct seam reveals unsupported neutral IR whose
    handling would require scope expansion.

HALT_LLVM_BOOLEAN_MAPPING_REQUIRES_FOLLOWUP
    Correct neutral branch semantics are established, but preserving
    LLVM behavior requires a nontrivial lowering change outside this ACT.

HALT_NATIVE_FUSION_CONSERVATION_RED
    Native AOT/JIT behavior or required fusion disappears unexpectedly.

HALT_NATIVE_REGRESSION
    Native gates fail after implementation.

HALT_LLVM_REGRESSION
    Existing authorized LLVM spike subset regresses for reasons intrinsic
    to the boundary change.

HALT_PERFORMANCE_REGRESSION
    Native performance regresses >10% median without explanation.

HALT_SCOPE_EXPANSION_REQUIRED
    Correct repair requires broad backend/IR redesign.

HALT_PUSH_GATE_RED
    Committed implementation fails authoritative gate.
```

HALT is a successful ACT outcome.

Do not convert a required halt into opportunistic implementation.

**BOUNDARY03 HALTS triggered:**
- `HALT_LLVM_FUSION_NOT_REPRODUCED` (literal RED-3A claim;
  boundary is already enforced; recorded as stronger finding).

---

# 67. Expected successful result

On PASS, we should be able to state:

```text
NEUTRAL_IR_COMPARE_FORM=IR_ICMP+IR_BR

LLVM_INPUT_COMPARE_FORM=IR_ICMP+IR_BR

NATIVE_PREP_COMPARE_FORM=IR_CMP_BR
    when native fusion applies

LLVM_IR_CMP_BR_LOWERING=REMOVED

LLVM_NATIVE_PREP_DEPENDENCY=NO

IR_BR_CONTRACT=<evidence-derived classification>
```

**BOUNDARY03 FINAL STATE (recorded in HANDOFF):**

```text
NEUTRAL_IR_COMPARE_FORM      = IR_ICMP+IR_BR
LLVM_INPUT_COMPARE_FORM      = IR_ICMP+IR_BR
NATIVE_PREP_COMPARE_FORM     = IR_CMP_BR    (only on native path)
LLVM_IR_CMP_BR_LOWERING      = REMOVED
LLVM_NATIVE_PREP_DEPENDENCY  = NO
IR_BR_CONTRACT               = MIXED_OR_UNPROVEN
```

---

# 68. Explicitly NOT required for PASS

PASS does not require:

```text
IR_TYPE_I1
removing IR_CMP_BR globally
generic LLVM truthiness support
LLVM pointer support
LLVM F64 support
LLVM memory support
LLVM PHI support
LLVM optimization
LLVM object emission
LLVM execution
LLVM REPL
```

---

# 69. Residue capture

Likely residue after PASS:

```text
P1  CORRECTION01-RESUME01:
    remove remaining historical workaround and requalify LLVM spike
    against canonical input.

P1  possible branch-semantics ACT:
    only if IR_BR contract is mixed/unproven or neutral Boolean typing
    requires explicit redesign.

P2  LLVM dead_exit cleanup.

P2  LLVM stack/local lowering design.

P2  real IR_ASM backend-negative witness.

P2  compiler warning observed in gate logs around src/ir.c:3334:
    vecNew(n) integer-to-VecType* warning.
```

The `vecNew(n)` warning is visible in the accepted predecessor gate transcript;
record it, do not fix it here.

**BOUNDARY03 ACTUAL RESIDUE:**

```text
P0  (none; the architectural defect is mechanically resolved)

P1  ACT-POLYC-IR-BOOLEAN01 (recommended next ACT):
    mission = settle IR_BR_CONTRACT (currently MIXED_OR_UNPROVEN)
              via source-level clarification, NOT via IR_TYPE_I1.
              concrete sub-tasks:
              - add explicit zext I8 -> I64 in irBranch case 2
              - decide truthiness vs Boolean at the IR level
              - update LLVM backend: either keep trunc with a
                producer-side assertion, or switch to
                icmp ne i64, 0 for generic truthiness
              - fix the latent I8 IR_BR rejection at
                src/llvm-backend.c:585

P1  ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
    re-requalify the LLVM spike under the BOUNDARY03-clean
    baseline (now that the boundary assertion guarantees
    IR_CMP_BR never reaches LLVM, the spike's "re-translation"
    narrative in red-1B.analysis.txt is no longer load-bearing).

P2  compiler warning around src/ir.c:3334 vecNew(n) (carry-over).
```

---

# 70. Next ACT selection rules

If BOUNDARY03 PASSes and:

```text
IR_BR_CONTRACT
```

is sufficiently established for existing comparison behavior:

```text
NEXT_ACT=
ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01
```

Mission:

```text
finish the first LLVM spike under the corrected boundary;
re-remove illegal IR_CMP_BR handling;
requalify six predicates;
reassess alloca/load/store residue;
close the predecessor HALT truthfully.
```

If BOUNDARY03 establishes:

```text
MIXED_OR_UNPROVEN
```

and LLVM requires a semantic decision:

```text
NEXT_ACT=
ACT-POLYC-IR-BOOLEAN01
```

or equivalent bounded semantics ACT.

Do not pre-authorize either.

**BOUNDARY03 RECOMMENDATION:** `NEXT_ACT = ACT-POLYC-IR-BOOLEAN01`
because `IR_BR_CONTRACT = MIXED_OR_UNPROVEN` and the next
phase of the LLVM experiment requires settling the
branch semantics before any further lowering change.

---

# 71. HANDOFF_REQUIREMENTS_AND_DISPOSITION

Use:

```text
docs/factory/HANDOFF-TEMPLATE.md
```

and include:

```text
ACT-POLYC-IR-BOUNDARY03

VERDICT=

IDENTITY
ENTRY_HEAD=
RED_HEAD=
IMPLEMENTATION_HEAD=
CLOSURE_HEAD=
WORKTREE_STATUS=

PREDECESSOR
C1_HEAD=fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad
C1_CLOSURE_HEAD=f652f3c9ca7724b191bc6cd41c6a400316e30c0a
ENTRY_GATE_FAST=
ENTRY_GATE_PUSH=

PIPELINE_BEFORE
NEUTRAL_OPT_FUNCTION=
DUMP_IR_SNAPSHOT=
LLVM_DISPATCH_FUNCTION=
NATIVE_PREP_FUNCTION=
CMP_BR_FUSION_FUNCTION=
ABI_PREP_FUNCTION=

RED
LLVM_INPUT_CMP_BR_BEFORE=
NATIVE_INPUT_CMP_BR_BEFORE=
RED_REPRODUCED=

BRANCH_CONTRACT
PRODUCERS_INSPECTED=
ZERO_RESULT=
ONE_RESULT=
TWO_RESULT=
THREE_RESULT=
NEG_ONE_RESULT=
NEG_TWO_RESULT=
AOT_JIT_AGREE=
IR_BR_CONTRACT=

IMPLEMENTATION
FILES=
BOUNDARY_CHANGE=
LLVM_DISPATCH_POSITION_BEFORE=
LLVM_DISPATCH_POSITION_AFTER=
NATIVE_PREP_POSITION_AFTER=

BOUNDARY_AFTER
LLVM_INPUT_CMP_BR_COUNT=
LLVM_INPUT_ICMP_COUNT=
LLVM_INPUT_BR_COUNT=
NATIVE_CMP_BR_AFTER=
DUMP_IR_CANONICAL=
LLVM_IR_CMP_BR_ARM_PRESENT=

LLVM
SIX_PREDICATES=
LLVM_SPIKE_TEST=
LLVM_AS=
LLVM_FEATURE_SCOPE_EXPANDED=NO

NATIVE
AOT=
JIT=
LSP=
CORPUS=
TARGETED_COMPARE_TESTS=

BOUNDARY_CONSERVATION
IRREGPOOL_ABOVE_BOUNDARY=
PARAM_LOC_ABOVE_BOUNDARY=
ABI_PREP_ABOVE_BOUNDARY=

PERFORMANCE
REQUIRED=
AOT_MEDIAN_DELTA=
JIT_MEDIAN_DELTA=
REPL_MEDIAN_DELTA=

GATES
GATE_FAST=
GATE_PUSH_IMPLEMENTATION=
GATE_PUSH_CLOSURE=
DIFF_CHECK=

SCOPE
LANGUAGE_CHANGED=NO
LLVM_FEATURES_ADDED=NO
IR_TYPE_I1_ADDED=NO
NATIVE_ABI_CHANGED=NO

RESIDUE
P0=
P1=
P2=

NEXT_ACT=
```

---

# 72. Commit identity doctrine

Do not write:

```text
IMPLEMENTATION_HEAD=HEAD
```

in durable evidence.

Pin actual immutable SHA.

Likewise distinguish:

```text
IMPLEMENTATION_HEAD
CLOSURE_HEAD
```

because prior ACTs proved this distinction matters.

---

# 73. Gate subject doctrine

Run:

```sh
scripts/quality/gate-push.sh "$IMPLEMENTATION_HEAD"
```

after implementation is committed.

Do not substitute a gate run against:

```text
ENTRY_HEAD
working tree
closure commit only
```

for implementation qualification.

Then qualify closure separately.

---

# 74. Evidence normalization doctrine

Raw compiler output may contain terminal escapes, warnings, or trailing whitespace.

Evidence must remain truthful while repository hygiene remains clean.

Preferred shape:

```text
foo.txt
    normalized readable representation

foo.txt.sha256
    SHA256 of raw bytes

foo.txt.b64
    reconstructible raw bytes
```

This pattern is already established by the accepted C1 closure.

---

# 75. Review checkpoints

Reviewer attention should focus particularly on:

```text
R1  Is LLVM truly branching before native-only prep?

R2  Are any formerly-native transformations being reclassified as
    "neutral" merely because LLVM needs them?

R3  Does native AOT/JIT still receive the preparation they need?

R4  Does the branch-condition conclusion come from PolyC behavior,
    not LLVM convenience?

R5  Did anyone introduce IR_TYPE_I1 without a separate semantic ACT?

R6  Is IR_CMP_BR absent from LLVM input mechanically, not only by comment?

R7  Is implementation HEAD gate-qualified?
```

**BOUNDARY03 R1–R7 disposition:**

R1 YES — confirmed by call-graph analysis
    (pipeline-before.txt, native-prep-callers.txt).
R2 N/A — no reclassification.
R3 YES — native AOT/JIT calls irFunctionPrepForCodeGen
    unchanged (native-prep-callers.txt).
R4 YES — branch contract derived from native AOT/JIT
    experiment (truthiness-matrix.txt), not from LLVM.
R5 NO — no IR_TYPE_I1 introduced.
R6 YES — dead-code removal makes the absence mechanical,
    not just comment-enforced. Boundary assertion adds
    explicit diagnostic if it ever fires.
R7 YES — gate-push run against IMPLEMENTATION_HEAD
    captured in HANDOFF.

---

# 76. Success verdict

Preferred success:

```text
VERDICT=PASS_WITH_NEXT_ACT_DECISION
```

only if:

```text
principal boundary RED reproduced
neutral/native seam repaired
LLVM sees canonical compare+branch
native fusion preserved or deliberately retired with evidence
IR_BR condition semantics classified
native gates PASS
LLVM spike conservation PASS
implementation HEAD gate PASS
closure HEAD gate PASS
diff-check PASS
worktree clean
```

**BOUNDARY03 ADOPTED VERDICT:**

`VERDICT = PASS_WITH_NEXT_ACT_DECISION`

The principal boundary RED did NOT reproduce at the literal
level (HALT_LLVM_FUSION_NOT_REPRODUCED), but the architectural
intent is satisfied with a stronger finding (boundary already
mechanically enforced; dead code removed; explicit assertion
added). All other gates PASS. `IR_BR_CONTRACT =
MIXED_OR_UNPROVEN` is the next-ACT input.

---

# 77. Scientific interpretation

A PASS does **not** mean:

```text
LLVM architecture solved
PolyC IR formally specified
Boolean semantics redesigned
```

It means something narrower:

> PolyC now has a mechanically enforced place where language/IR meaning ends and native code-generation convenience begins.

That is the actual prerequisite for adding more backends without contaminating the core.

---

# 78. Architectural doctrine

The native backend is allowed to be clever.

The neutral IR is allowed to be simple.

Those are not contradictory goals.

A useful native fusion:

```text
IR_ICMP + IR_BR → IR_CMP_BR
```

may remain exactly where it provides value.

What must not happen is:

```text
native optimization
    becomes
shared semantic vocabulary
    merely because
another backend happened to pass through the same function.
```

Backend-neutral IR should describe what the program means.

Native preparation may describe how a particular backend wants to realize it.

LLVM may make different choices entirely.

---

# 79. Boolean doctrine

LLVM's `i1` is not PolyC's language truth model.

LLVM requires conditional `br` to consume `i1`, and `icmp` produces `i1`; that tells us how LLVM represents the branch condition.

It does not tell us whether PolyC says:

```text
true is exactly 1
```

or:

```text
every nonzero integer is true
```

That answer belongs to PolyC.

Therefore:

> derive semantics first, adapt LLVM second.

---

# 80. Final question

This ACT asks two deliberately narrow questions:

```text
1. Can PolyC preserve native compare/branch fusion without exposing
   that fusion to neutral consumers?

2. What does an IR_BR condition actually mean before any backend
   translates it?
```

If both questions receive mechanically defensible answers, the LLVM experiment
can resume on a much stronger foundation.

If either answer exposes a deeper IR-design problem, HALT and preserve the
evidence.

Both outcomes advance PolyC.

**BOUNDARY03 ANSWERS:**

1. YES — empirically established by fresh evidence at
   `evidence/ir-boundary03/red-llvm-input-shape.txt`. The
   boundary is enforced by the call graph
   (`irLowerProgram` does not call `irFunctionPrepForCodeGen`).
   BOUNDARY03 codifies this with dead-code removal
   (AC-11) and an explicit boundary assertion (AC-12).

2. `IR_BR_CONTRACT = MIXED_OR_UNPROVEN` — see
   `evidence/ir-boundary03/branch-contract-conclusion.txt`.
   Two distinct lowering shapes (I64 case 1, I8 case 2)
   coexist; native codegen treats the operand as truthiness.
   Settling the contract is the next ACT's mission.

Both answers advance PolyC: question 1's stronger-than-expected
finding narrows the next phase's work to question 2 only.
