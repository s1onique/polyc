# ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Reconcile and close the BYTE-MEMORY01 B0 byte substrate after LOCAL-MEM2REG — fresh production proof only, no new compiler semantics

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Entry HEAD:** `246be50a373425541eee2c8e00f900e5ffab505c`

**Predecessors (F14 preserved):**

- `ACT-POLYC-LLVM-BYTE-MEMORY01` — `HALT_SCOPE_EXPANSION_REQUIRED` (H1 frozen-set exceeded; H2 B0 multi-block SSA dominance bug). Canonical trailers issued by `ACT-POLYC-LLVM-BYTE-MEMORY01-BOOKKEEPING01` at `db6404e`.
- `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01` — `HALT_SCOPE_EXPANSION_REQUIRED` at `a48e40f` (C1 proved the smallest repair is in `src/ir-optimise.c`, outside RESUME01's authorized `llCollapseStoreValue` seam).
- `ACT-POLYC-IR-RETURN-SLOT-FORWARDING01` — `HALT_SECOND_SEAM_REQUIRED` at `69f7d3a` (forwarding guard is conservative; the multi-predecessor exit still requires a second seam — mem2reg).
- `ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02` — `PASS / CLOSED` at `246be50a` (faithful Option-W memory form: entry alloca + original-site stores + original-site loads; LLVM mem2reg owns SSA/PHI).

**Class:** MACHINE-ENFORCED EVIDENCE / CLOSURE CONTRACT

**Production semantic changes:** **FORBIDDEN**

**Neutral-IR changes:** **FORBIDDEN**

**ABI changes:** **FORBIDDEN**

**New LLVM opcode/capability admission:** **FORBIDDEN**

---

## 0. Mission

`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02` exists to answer one question:

> After the completed LOCAL-MEM2REG / Option-W repair, is the bounded byte-memory substrate that B0 currently needs genuinely GREEN, so that the project may leave the BYTE-MEMORY lineage and proceed to `ACT-POLYC-LLVM-GEP01`?

This is deliberately an **evidence-only closure ACT**.

It does NOT implement GEP.

It does NOT widen byte-memory semantics.

It does NOT add byte stores merely for completeness.

It does NOT revisit the Option-W implementation.

It does NOT repair unrelated Factory/tooling residue.

The expected result, if current behavior reproduces cleanly, is:

```text
VERDICT = PASS
BYTE-MEMORY B0 SUBSTRATE = CLOSED
NEXT ACT = ACT-POLYC-LLVM-GEP01
```

A HALT is required if fresh evidence proves that B0's current byte-reading/comparison path still needs a semantic capability absent from the frozen supported set.

---

# 1. Historical predecessor truth

Preserve the history exactly; do not rewrite or reinterpret old commits.

## 1.1 BYTE-MEMORY01

`ACT-POLYC-LLVM-BYTE-MEMORY01` closed:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

for two reasons:

```text
H1
  The implementation admitted shapes that recon had frozen as DEFER:

    IR_SEXT I8 -> I64
    IR_TRUNC I64 -> I8

H2
  pos_b0_compare_digit.HC produced invalid LLVM in a
  multi-block conditional-return shape due to SSA/dominance handling.
```

The useful production code from that attempt remained in history under F14.

## 1.2 BYTE-MEMORY01-RESUME01

`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01` explicitly authorized the proven byte conversion shapes, but recon established that the multi-block failure was not fundamentally a byte-lowering defect.

The root cause moved upstream/downstream into return/local-state representation.

RESUME01 therefore closed:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

rather than modifying an unauthorized seam.

## 1.3 IR-RETURN-SLOT-FORWARDING01

`ACT-POLYC-IR-RETURN-SLOT-FORWARDING01` made `irForwardReturnSlot` conservative for multi-predecessor exits.

That removed one invalid dominance rewrite but exposed the second seam:

```text
IR_ALLOCA + store/load return-state geometry
was still rejected by the SSA-only LLVM backend.
```

It closed:

```text
HALT_SECOND_SEAM_REQUIRED
```

and recommended LLVM `mem2reg` rather than increasingly complicated bespoke CFG reconstruction.

## 1.4 LOCAL-MEM2REG lineage

The LOCAL-MEM2REG work ultimately established the production architecture:

```text
eligible mutable local

    entry-block alloca

    store at ORIGINAL definition sites
    load at ORIGINAL read sites

    LLVM mem2reg

    SSA + PHIs owned by LLVM
```

`ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02` closed PASS at:

```text
246be50a373425541eee2c8e00f900e5ffab505c
```

Its production fixtures include the previously blocking byte-shaped:

```text
pos_b0_compare_digit.HC
  ReadDigit
  AccDigit
```

and prove verifier-clean multi-block behavior.

Therefore RESUME02 does not invent a new fix.

It verifies that the fix already delivered by the predecessor lineage discharges BYTE-MEMORY's historical blocker.

---

# 2. Frozen capability boundary

RESUME02 must derive the current supported byte surface mechanically from the current tree and existing BYTE-MEMORY contracts.

The expected bounded surface is:

```text
SUPPORTED / ADMITTED

  source I8 / U8 scalar parameter shapes
    -> neutral IR_TYPE_I8

  byte pointer parameter
    -> pointer value whose accessed element width is I8

  IR_LOAD_DEREF byte shape
    -> LLVM load i8, ptr

  IR_ZEXT I8 -> I64

  IR_SEXT I8 -> I64
    only the shape already admitted by BYTE-MEMORY lineage

  IR_TRUNC I64 -> I8
    only the shape already admitted by BYTE-MEMORY lineage

  byte comparisons used by B0-shaped digit recognition

  multi-block mutable I64 result state required by:
    ReadDigit
    AccDigit
    pos_b0_compare_digit
    now handled by Option-W / mem2reg
```

Do not infer a larger set merely because LLVM itself supports it.

## 2.1 Explicitly NOT authorized by this ACT

```text
IR_STORE_DEREF byte support if not already in the frozen positive set
general byte mutation
GEP
pointer arithmetic
ptrtoint
inttoptr
array lowering
struct lowering
aggregate allocas
I8 Option-W allocas
arbitrary-width integer memory
unaligned memory policy
volatile memory
atomic memory
F32/F64 conversions
new frontend syntax
new neutral IR opcodes
new capability-table rows
new native-backend semantics
```

Any newly discovered need in that list is:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

not permission to implement it here.

---

# 3. B0 requirement boundary

The B0 milestone immediately following the substrate ACTs is a PolyC-written lexer/tokenizer.

For RESUME02, byte-memory's responsibility is only the already demonstrated class:

```text
given ptr to input byte
    ↓
load i8
    ↓
interpret signedness correctly
    ↓
promote when required
    ↓
compare / perform bounded arithmetic
    ↓
produce verifier-clean control-flow result
```

Walking from one byte to another is NOT part of this ACT.

That responsibility belongs to:

```text
ACT-POLYC-LLVM-GEP01
```

The closure evidence must mechanically establish that BYTE-MEMORY positive fixtures contain no GEP requirement.

Expected:

```text
BYTE_MEMORY_GEP_COUNT = 0
```

This is a boundary proof, not a statement that B0 never needs GEP.

B0 does need indexed address computation later.

---

# 4. Commit topology

Use three commits unless evidence falsifies the expected state.

```text
C1  RED       current-state reconciliation / capability freeze
C2  EVIDENCE  fresh compiler + LLVM + runtime proof
C3  CLOSE     acceptance matrix + verdict
```

There is deliberately:

```text
NO IMPL COMMIT
```

If an implementation change becomes necessary:

```text
STOP
HALT_SCOPE_EXPANSION_REQUIRED
```

and return to reviewer with the smallest counterexample.

Do not silently insert an IMPL phase.

---

# 5. C1 RED — current-state reconciliation

Authoritative trailer:

```text
ACT: ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02
ACT-Phase: RED
```

No `ACT-Verdict` on RED.

C1 makes **no production changes**.

## 5.1 Inventory current fixtures

At minimum reconcile these existing BYTE-MEMORY fixtures:

```text
src/tests/llvm-byte-memory01/red_u8_param.HC
src/tests/llvm-byte-memory01/red_i8_param.HC
src/tests/llvm-byte-memory01/red_byte_load.HC
src/tests/llvm-byte-memory01/red_byte_pointer_param.HC
src/tests/llvm-byte-memory01/red_byte_to_i64.HC
src/tests/llvm-byte-memory01/red_i16_trunc_negative.HC
src/tests/llvm-byte-memory01/pos_byte_compare_simple.HC
src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC
```

Also include the regression fixtures introduced while solving the generic state problem when relevant to conservation:

```text
i64_collapse_probe.HC
single_cond_probe.HC
safe_fwd_single_pred.HC
Diamond.HC
```

Do not rename historical `red_*` fixtures merely because some are now positive. Their historical names are evidence.

## 5.2 Produce a capability matrix

Create:

```text
evidence/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02/c1/
    current-capability-matrix.tsv
    fixture-inventory.txt
    predecessor-verdicts.txt
    b0-byte-demand.txt
```

`current-capability-matrix.tsv` must contain at least:

```text
shape
neutral_ir_opcode
source_width
destination_width
signedness
current_status
positive_fixture
negative_fixture
backend_path
b0_required
notes
```

Expected rows include:

```text
I8/U8 parameter
byte pointer parameter
IR_LOAD_DEREF I8
IR_ZEXT I8->I64
IR_SEXT I8->I64
IR_TRUNC I64->I8
I64->I16 narrowing negative control
byte comparison
byte store
GEP/indexing
```

Do not pre-fill unsupported rows as supported.

Derive them from the actual current compiler/tests.

## 5.3 Explicit historical-HALT mapping

Create a two-row reconciliation table:

```text
H1 — scope expansion
  old problem:
    SEXT/TRUNC implemented despite DEFER
  current disposition:
    explicitly authorized by successor contract?
    implementation present?
    regression bound?
  expected:
    RESOLVED_BY_AUTHORIZATION

H2 — multi-block SSA dominance
  old problem:
    pos_b0_compare_digit invalid/rejected
  current disposition:
    current compiler emits valid LLVM?
    Option-W real production path used?
    independent verify succeeds?
  expected:
    RESOLVED_BY_LOCAL_MEM2REG
```

If either cannot be mechanically established:

```text
C1 verdict = BLOCKED
STOP
```

Do not proceed to CLOSE by historical inference.

---

# 6. C1 boundary recon: is another byte capability required before GEP?

Compile/dump the B0-shaped fixture from the CURRENT tree:

```text
pos_b0_compare_digit.HC
```

Capture:

```text
--dump-ir or equivalent neutral IR
--emit-llvm
independent llvm-as
independent opt -passes=verify
```

Answer mechanically:

```text
Q1
Does the fixture require any byte-memory opcode not in the
current frozen supported set?

Q2
Does it require IR_STORE_DEREF byte semantics?

Q3
Does it require GEP?

Q4
Does it require an I8 Option-W alloca?

Q5
Does it require a new conversion width?

Q6
Does current emitted LLVM verify independently?
```

Expected:

```text
Q1 NO
Q2 NO
Q3 NO
Q4 NO
Q5 NO
Q6 YES
```

If Q1–Q5 differ:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

and report the exact neutral-IR instruction / source construct.

Do not implement it.

---

# 7. C2 EVIDENCE — fresh current-tree proof

Authoritative trailer:

```text
ACT: ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02
ACT-Phase: EVIDENCE
```

No verdict on EVIDENCE.

C2 must regenerate evidence from the current tree.

Do not copy old PASS text and call it fresh evidence.

Evidence root:

```text
evidence/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02/c2/
```

## 7.1 Byte type admission

Prove current compilation accepts the already authorized byte scalar shapes.

Expected examples:

```text
red_u8_param.HC
red_i8_param.HC
```

Record:

```text
hcc exit
LLVM emitted
LLVM type used
conversion generated
independent verify
```

## 7.2 Direct byte load

Prove:

```text
red_byte_load.HC
red_byte_pointer_param.HC
```

produce the intended byte memory operation:

```llvm
load i8, ptr ...
```

and not:

```text
load i64
ptrtoint arithmetic
integer-address reconstruction
```

unless such output is already part of the frozen contract.

## 7.3 Extension

Prove the frozen conversions independently.

### Unsigned path

Expected LLVM semantic form:

```llvm
zext i8 ... to i64
```

### Signed path

Expected LLVM semantic form when source semantics require signed extension:

```llvm
sext i8 ... to i64
```

Do not infer source signedness from LLVM `i8` alone.

Both PolyC `I8` and `U8` may share `IR_TYPE_I8`; the conversion opcode carries the extension semantics.

## 7.4 Truncation

Prove the admitted:

```text
I64 -> I8
```

shape remains GREEN.

Preserve the negative control proving that an unapproved narrowing remains rejected, currently expected to include:

```text
I64 -> I16
```

with the existing named diagnostic / capability result.

Do not broaden narrowing merely to make a fixture compile.

## 7.5 Byte comparisons

Prove the current comparison path required for digit recognition.

At minimum exercise values around:

```text
'0' = 48
'9' = 57
```

including:

```text
below range
lower endpoint
interior digit
upper endpoint
above range
```

Bind source result to emitted verifier-clean LLVM.

## 7.6 B0-shaped multi-block fixture

`pos_b0_compare_digit.HC` is closure-critical.

It MUST:

```text
hcc --emit-llvm             PASS
LLVM module emitted         YES
llvm-as                     PASS
opt -passes=verify          PASS
```

Bind both:

```text
ReadDigit
AccDigit
```

For the mutable accumulator path, capture enough pre/post-mem2reg evidence to establish that the previously blocking multi-block state is now using the closed Option-W production architecture rather than an accidental stale collapse path.

Required semantic facts:

```text
original mutable-state definitions preserved
original mutable-state reads preserved
mem2reg owns PHI construction
LLVM verifier PASS
```

Do not duplicate the entire LOCAL-MEM2REG closure packet.

Reference it where possible and capture only the fresh BYTE-MEMORY-facing witness.

---

# 8. Runtime proof

Where the current harness supports execution, bind runtime/source semantics.

At minimum for the digit path:

```text
ReadDigit('0') -> 0
ReadDigit('5') -> 5
ReadDigit('9') -> 9
non-digit behavior -> the current documented source semantics
```

For accumulator behavior, at minimum preserve:

```text
AccDigit(12, '5') -> 125
AccDigit(12, non-digit) -> 12
```

Use the actual function/source contract if the fixture differs.

Do not invent an expected value that the fixture does not define.

If runtime execution is not directly available for one fixture, classify its evidence honestly as:

```text
STRUCTURAL + VERIFY
```

rather than claiming runtime proof.

---

# 9. GEP boundary proof

RESUME02 must prove that it has not accidentally swallowed GEP01.

Mechanically inspect the BYTE-MEMORY positive fixtures / emitted LLVM.

Expected:

```text
getelementptr count = 0
```

for the frozen BYTE-MEMORY positive set.

Also inspect current neutral IR for:

```text
IR_LEA
GEP-shaped offset/index operations
pointer arithmetic
```

If a current mandatory BYTE-MEMORY fixture requires indexed address computation:

```text
HALT_DEPENDS_ON_GEP01
```

Do not implement GEP here.

The intended next architecture is:

```text
BYTE-MEMORY01-RESUME02
    byte-at-current-address semantics

GEP01
    compute address of src[n]

load
    read byte at computed address
```

LLVM GEP is address computation only; memory access remains a separate load/store operation.

---

# 10. Byte-store disposition

Do not accidentally turn "BYTE-MEMORY" into "all byte memory operations must exist".

Inspect current evidence.

If `IR_STORE_DEREF` byte shape remains deferred and B0 does not currently require it, record:

```text
BYTE_STORE_STATUS = DEFERRED_NOT_B0_BLOCKING
```

That is a valid PASS state.

If current B0 recon proves byte store is required before B0:

```text
HALT_SCOPE_EXPANSION_REQUIRED
NEXT ACT = dedicated byte-store ACT
```

Do not implement it inside RESUME02.

---

# 11. LOCAL-MEM2REG conservation

RESUME02 must not reopen Option-W.

Freshly establish that the predecessor remains GREEN through existing tests:

```text
llvm-byte-memory01-test
ir-return-slot-forwarding01-test
llvm-spike-test
```

and, where practical, reference the closed LOCAL-MEM2REG C7 acceptance evidence.

Required invariant:

```text
C9 predecessor-store synthesis remains absent.
```

Do not add:

```text
new predecessor inference
manual PHIs
terminator-driven mutable-local stores
new Option-W eligibility
```

---

# 12. Current BYTE-MEMORY regression target

Run the dedicated current suite:

```text
scripts/quality/llvm-byte-memory01-test.sh
```

The previously observed current baseline is:

```text
PASS=37
FAIL=0
```

RESUME02 closure requires:

```text
FAIL=0
```

Do not freeze `37` as an eternal exact count if this ACT adds evidence-only checks through another harness.

If the existing harness itself remains unchanged, record the fresh exact result.

Also bind its major sections:

```text
toolchain
authorized-set echo
byte type admission
direct byte load
promotion
truncation boundary
LLVM textual structure
llvm-as / opt verify
capability counters
per-fixture attribution
GEP purity
```

Any existing intentionally deferred section must remain explicitly marked deferred rather than silently reported as PASS.

---

# 13. Capability-table conservation

Run the capability-table verifier.

No new capability row may become globally SUPPORTED merely as a consequence of this evidence ACT.

Expected:

```text
current capability-table rows unchanged
ordinal binding PASS
```

Specifically protect the distinction:

```text
SUPPORTED
SHAPE_DEPENDENT
REJECTED/DEFERRED
```

Do not promote `SHAPE_DEPENDENT` operations globally.

---

# 14. Production-delta invariant

Because RESUME02 is evidence-only:

```text
git diff <ENTRY_HEAD>..HEAD -- src/
```

must show no compiler production change attributable to this ACT.

Likewise no new semantics under:

```text
src/ir*
src/llvm-backend*
```

Expected allowed changes:

```text
docs/acts/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02.md
docs/ROADMAP.md
evidence/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02/**
small evidence harness under scripts/quality/** only if necessary
```

A new harness is permitted only if it measures current behavior.

It must not alter production behavior.

If a production fix is required:

```text
STOP
HALT_SCOPE_EXPANSION_REQUIRED
```

---

# 15. Evidence truthfulness

Any new evidence validator introduced by RESUME02 must obey:

```text
assertion fails -> row FAIL
row FAIL -> process non-zero
```

No unconditional:

```sh
exit 0
```

after a failure counter.

If the harness reports:

```text
PASS=N FAIL=M
```

then:

```text
M > 0 -> exit != 0
```

Mechanically self-test the verdict channel if a new validator is written.

Do not repeat the false-GREEN evidence defects fixed during LOCAL-MEM2REG.

---

# 16. Conservation gates

Run fresh from the candidate tree.

At minimum:

```text
make clean
make
make llvm-all

llvm-byte-memory01-test
llvm-spike-test
llvm-intops01-test
ir-return-slot-forwarding01-test
harness-evidence-isolation-test

llvm-cap-table-verifier

factory-v2-commit-msg-check
factory-append-only-test
factory-closure-status
gate-fast

git diff --check HEAD^ HEAD
git status --short
```

Also run independent LLVM validation on all closure-critical emitted modules:

```text
llvm-as <file.ll>
opt -passes=verify <file.ll> -disable-output
```

If the repository still carries an unrelated pre-existing failure in:

```text
llvm-spike-contract-check
```

such as the stale `neg_pointer.HC` reference, record it honestly as inherited residue if it is still outside the authoritative conservation set.

Do not call a command GREEN if it actually fails.

---

# 17. Historical evidence hygiene

Do not rewrite historical BYTE-MEMORY / RESUME01 / LOCAL-MEM2REG evidence.

F14 applies.

Historical malformed trailers, HALT evidence, superseded hypotheses, and preserved whitespace defects remain historical evidence.

RESUME02 may state:

```text
historical fact = X
current authoritative fact = Y
```

but must not mutate old commits to make history look cleaner.

---

# 18. C2 required evidence files

Recommended:

```text
evidence/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02/c2/
    capability-matrix.txt
    historical-halt-reconciliation.txt
    byte-type-admission.txt
    byte-load.txt
    conversions.txt
    truncation-boundary.txt
    byte-compare.txt
    pos-b0-dump-ir.txt
    pos-b0-emit-llvm.ll
    pos-b0-llvm-as.txt
    pos-b0-verify.txt
    runtime.txt
    gep-boundary.txt
    byte-store-disposition.txt
    capability-table.txt
    conservation-gates.txt
    production-delta.txt
```

Do not create duplicate evidence merely to inflate the packet.

One mechanically authoritative artifact per claim is preferable.

---

# 19. C3 CLOSE

Authoritative trailer:

```text
ACT: ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

only if every closure criterion below is satisfied.

Otherwise use the appropriate:

```text
ACT-Verdict: HALT_<REASON>
```

Do not repair production semantics inside CLOSE.

---

# 20. Acceptance criteria

## AC01 — predecessor truth

PASS iff the closure packet records truthfully:

```text
BYTE-MEMORY01
  HALT_SCOPE_EXPANSION_REQUIRED

BYTE-MEMORY01-RESUME01
  HALT_SCOPE_EXPANSION_REQUIRED

IR-RETURN-SLOT-FORWARDING01
  HALT_SECOND_SEAM_REQUIRED

LOCAL-MEM2REG01-CORRECTION02
  PASS / CLOSED at 246be50a
```

No old HALT is rewritten as if it had originally passed.

## AC02 — frozen byte capability matrix

PASS iff every currently claimed byte capability is bound to an actual current fixture and compiler path.

## AC03 — I8/U8 parameter admission

PASS iff current compilation proves the frozen scalar parameter shapes.

## AC04 — direct byte load

PASS iff current emitted LLVM contains the expected:

```llvm
load i8, ptr
```

shape for the direct byte-load fixtures.

## AC05 — unsigned promotion

PASS iff the current unsigned path produces the frozen:

```llvm
zext i8 -> i64
```

behavior.

## AC06 — signed promotion

PASS iff the current signed path, where required by source semantics, produces the frozen:

```llvm
sext i8 -> i64
```

behavior.

## AC07 — truncation boundary

PASS iff:

```text
authorized I64 -> I8      GREEN
unauthorized comparison narrowing control remains rejected
```

without widening.

## AC08 — byte comparison

PASS iff the current digit-range comparison fixture produces verifier-clean LLVM and correct semantics.

## AC09 — B0-shaped multi-block byte fixture

PASS iff `pos_b0_compare_digit.HC`:

```text
compiles
emits LLVM
assembles
passes independent verify
```

for both `ReadDigit` and `AccDigit`.

## AC10 — historical H2 resolved by actual successor architecture

PASS iff fresh evidence shows the multi-block state now flows through the closed Option-W/mem2reg architecture rather than a bespoke predecessor-store or stale collapse workaround.

## AC11 — no new byte-memory capability required

PASS iff C1 recon finds no new mandatory byte opcode/width/store form before GEP01.

## AC12 — GEP boundary

PASS iff mandatory BYTE-MEMORY positive fixtures do not require GEP and:

```text
GEP remains owned by ACT-POLYC-LLVM-GEP01
```

## AC13 — byte-store disposition

PASS iff one of these is explicitly established:

```text
already-supported bounded byte store
```

or:

```text
DEFERRED_NOT_B0_BLOCKING
```

A vague/unknown status is not sufficient for closure.

## AC14 — Option-W conservation

PASS iff existing LOCAL-MEM2REG-sensitive regressions remain GREEN and C9 synthesis remains absent.

## AC15 — BYTE-MEMORY suite

PASS iff:

```text
llvm-byte-memory01-test
FAIL = 0
```

with the fresh exact count recorded.

## AC16 — independent LLVM validation

PASS iff all closure-critical emitted modules pass:

```text
llvm-as
opt -passes=verify
```

## AC17 — capability table

PASS iff the capability verifier succeeds and no global status is silently widened.

## AC18 — production delta

PASS iff RESUME02 introduces no production semantic change.

## AC19 — evidence truth channel

PASS iff any RESUME02-produced validator returns non-zero on seeded mechanical failure.

If no new validator exists, mark:

```text
NOT_APPLICABLE — existing authoritative harnesses consumed
```

and identify them.

## AC20 — patch hygiene

PASS iff the RESUME02 commit ranges themselves satisfy:

```text
git diff --check
```

Historical unrelated hygiene failures must be classified separately, not laundered into PASS.

## AC21 — conservation gates

PASS iff all authoritative conservation gates are GREEN.

## AC22 — working tree

PASS iff:

```text
git status --porcelain
```

is empty after C3 CLOSE.

---

# 21. HALT taxonomy

Use the narrowest applicable verdict.

```text
HALT_SCOPE_EXPANSION_REQUIRED

  Fresh B0 byte recon requires a byte semantic not
  already in the frozen supported set.

HALT_DEPENDS_ON_GEP01

  The next failure is purely indexed address calculation.
  BYTE-MEMORY itself is otherwise sufficient, but this
  ACT cannot claim standalone closure under its chosen
  acceptance wording.

HALT_BYTE_REGRESSION

  A previously admitted byte capability no longer works.

HALT_LOCAL_MEM2REG_REGRESSION

  pos_b0_compare_digit or another mandatory fixture exposes
  a regression in the recently closed Option-W architecture.

HALT_EVIDENCE_DEFECT

  The evidence harness cannot mechanically support its
  claimed verdict.

HALT_CONSERVATION_REGRESSION

  An unrelated mandatory regression suite becomes RED.
```

Do not invent an implementation under the same ACT after a HALT condition is discovered.

Return to reviewer.

---

# 22. Explicit non-goals

RESUME02 is NOT:

```text
GEP01
STRUCT01
ARRAY01
BYTE-STORE01
a general integer-conversion ACT
a general pointer ACT
a general memory ACT
a LOCAL-MEM2REG correction
a Factory cleanup ACT
```

No opportunistic fixes.

F7/F15 scope conservation applies.

---

# 23. Expected closure statement

If all evidence reproduces as expected, C3 should be able to state:

```text
ROOT_CAUSE HISTORY

  BYTE-MEMORY's apparent multi-block byte failure was not
  fundamentally a byte access defect.

  The byte path exposed a generic mutable-local / return-state
  representation defect.

  That defect class was subsequently eliminated by the
  LOCAL-MEM2REG Option-W architecture.

CURRENT BYTE SUBSTRATE

  source I8/U8 scalar admission       GREEN
  byte pointer parameter              GREEN
  byte load                           GREEN
  byte -> I64 extension               GREEN
  bounded I64 -> I8 truncation        GREEN
  byte comparisons                    GREEN
  B0-shaped multi-block digit path    GREEN

  byte store                          <actual disposition>
  GEP/indexing                        OUT OF SCOPE / NEXT ACT

ARCHITECTURE

  byte access       = LLVM load i8
  widening          = zext/sext according to source semantics
  narrowing         = frozen bounded truncation only
  mutable result    = Option-W + LLVM mem2reg
  address indexing  = NOT handled here

PRODUCTION CHANGES IN RESUME02 = NONE

VERDICT = PASS
```

---

# 24. Roadmap transition on PASS

On `PASS`, update the roadmap so the critical path reads:

```text
ACT-POLYC-LLVM-BYTE-MEMORY01
    historical HALT

ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01
    historical HALT

IR-RETURN-SLOT-FORWARDING01
    historical HALT_SECOND_SEAM_REQUIRED

ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
    CLOSED PASS

ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02
    CLOSED PASS
    current B0 byte-at-current-address substrate proven

ACT-POLYC-LLVM-GEP01
    NEXT

then fresh B0 substrate recon

STRUCT01 / ARRAY01
    only if concrete B0 representation proves required

BOOTSTRAP01
    B0 lexer/tokenizer
```

Do NOT automatically mark STRUCT01 or ARRAY01 as mandatory successors.

GEP01 is the only successor currently justified by the known requirement to walk input bytes.

---

# 25. Required ClineMM final report

Return exactly enough detail to allow reviewer closure inspection:

```text
VERDICT

IDENTITY
  ENTRY_HEAD = 246be50a373425541eee2c8e00f900e5ffab505c
  C1_RED =
  C2_EVIDENCE =
  C3_CLOSE =
  FINAL_HEAD =
  WORKTREE =

HISTORICAL HALT RECONCILIATION
  H1 SEXT/TRUNC scope issue =
  H2 multi-block SSA issue =

CURRENT CAPABILITY MATRIX
  I8/U8 params =
  byte pointer =
  byte load =
  ZEXT =
  SEXT =
  TRUNC I64->I8 =
  negative narrowing control =
  byte comparison =
  byte store =
  GEP =

B0 FIXTURE
  pos_b0_compare_digit compile =
  llvm-as =
  opt verify =
  ReadDigit =
  AccDigit =
  runtime =

OPTION-W CONSERVATION =
GEP BOUNDARY =
PRODUCTION DELTA =

GATES
  llvm-byte-memory01-test =
  llvm-spike-test =
  llvm-intops01-test =
  ir-return-slot-forwarding01-test =
  harness-evidence-isolation-test =
  llvm-cap-table-verifier =
  factory-v2-commit-msg-check =
  factory-append-only-test =
  factory-closure-status =
  gate-fast =

PATCH HYGIENE =
WORKTREE =

RESIDUE =
NEXT ACT =
```

Expected successful final lines:

```text
VERDICT = PASS
ROADMAP STATE = CLOSED
NEXT ACT = ACT-POLYC-LLVM-GEP01
```

---

# 26. Hard rule

If current evidence is already GREEN:

**close the ACT.**

Do not manufacture implementation work merely because this is named `RESUME02`.

The whole point of this ACT is to prove that the work which originally blocked BYTE-MEMORY was ultimately solved in a different, more general lineage.

If fresh evidence proves that statement false, HALT with the smallest counterexample.
