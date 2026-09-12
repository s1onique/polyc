# ACT-POLYC-LLVM-GEP01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-LLVM-GEP01
ACT-Phase: RED

**Title:** Minimum B0 byte-buffer indexed address computation — one-dimensional `I8* + I64 index` only

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Entry HEAD:** `b0c6ff6881e3dae1b8c4c7f6166680b3f7c5e6e1`

**Predecessor:** `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02` — `PASS / CLOSED`

**Class:** MACHINE-ENFORCED RED → IMPL → EVIDENCE → CLOSE CONTRACT

**Primary production seam:** LLVM backend indexed pointer lowering

**Neutral-IR widening:** only if RED proves an already-existing neutral-IR opcode is the exact correct representation; adding a new neutral-IR opcode is NOT automatically authorized

**ABI changes:** FORBIDDEN

**STRUCT/ARRAY aggregate lowering:** FORBIDDEN

**Byte-store support:** FORBIDDEN

---

# 0. Mission

`ACT-POLYC-LLVM-GEP01` exists to provide exactly one new B0-critical capability:

```text
given:
  base pointer to bytes
  I64 index

compute:
  pointer to byte base[index]

then allow the already-supported byte load path to read that byte.
```

Conceptually:

```text
U8 *src
I64 i

src[i]
```

must lower into the equivalent of:

```llvm
%addr = getelementptr i8, ptr %src, i64 %i
%byte = load i8, ptr %addr
```

The GEP operation itself performs **address calculation only**.

The byte load remains owned by the already-closed BYTE-MEMORY substrate.

This ACT is NOT a general aggregate-addressing ACT.

Expected closure:

```text
VERDICT = PASS
SUPPORTED_GEP_SHAPE =
  base ptr
  + I64 scalar index
  + byte element type I8

NEXT = fresh B0 substrate recon
```

---

# 1. Why this ACT exists now

`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02` closed at:

```text
b0c6ff6881e3dae1b8c4c7f6166680b3f7c5e6e1
```

and proved:

```text
I8/U8 scalar admission              GREEN
byte pointer parameter              GREEN
load i8 from current address        GREEN
ZEXT / SEXT                         GREEN
bounded I64 -> I8 TRUNC             GREEN
byte comparisons                    GREEN
B0-shaped multi-block state         GREEN
byte store                          DEFERRED_NOT_B0_BLOCKING
GEP / indexing                      REJECTED
```

It also proved:

```text
BYTE_MEMORY_GEP_COUNT = 0
```

because BYTE-MEMORY deliberately covered only byte-at-current-address semantics.

Its B0 demand analysis explicitly established:

```text
GEP_REQUIRED_FOR_B0_AT_CURRENT_ADDRESS = NO
GEP_REQUIRED_FOR_B0_WALKING            = YES
```

Therefore this ACT owns the next missing operation:

```text
walk input bytes
```

not byte access itself.

---

# 2. External LLVM contract

LLVM `getelementptr`:

```text
computes addresses
does NOT load memory
does NOT store memory
```

For the first B0 shape, the intended LLVM semantic form is:

```llvm
%p = getelementptr i8, ptr %base, i64 %index
```

followed independently by:

```llvm
%v = load i8, ptr %p
```

The LLVM C API provides:

```text
LLVMBuildGEP2
LLVMBuildInBoundsGEP2
LLVMBuildGEPWithNoWrapFlags
```

This ACT defaults to:

```text
LLVMBuildGEP2
```

unless RED mechanically proves that the PolyC source contract already guarantees the stronger `inbounds` preconditions.

**Do not use `inbounds` merely because the fixture happens to stay within bounds.**

That is a semantic promise, not an optimization spelling preference.

---

# 3. Frozen target shape

The only initially authorized GEP shape is:

```text
BASE:
  pointer-valued PARAM, LOCAL, or TMP
  mechanically proven to represent a byte-addressable base

ELEMENT TYPE:
  I8

INDEX:
  one scalar I64 value

RESULT:
  pointer

INDEX COUNT:
  exactly 1
```

Equivalent source geometry:

```text
U8 *p;
I64 i;
p[i]
```

or:

```text
*(p + i)
```

only if the current PolyC frontend / neutral IR already represents that source form consistently.

## 3.1 Explicitly NOT authorized

```text
struct field GEP
array aggregate GEP with nested indices
multi-dimensional indexing
multiple GEP index operands
constant struct indices
pointer-to-pointer dereference through GEP
pointer difference
pointer comparison
ptrtoint
inttoptr
bitcast-based pointer arithmetic
negative-index language semantics beyond existing I64 expression semantics
I32 index special cases
I16/I8 index special cases
I64 element GEP
F32/F64 element GEP
aggregate GEP
vector GEP
inbounds GEP unless separately proven
GEP no-wrap flags
byte store through computed pointer
new allocation semantics
new lifetime semantics
```

Any required shape outside the frozen target causes:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

not implementation widening.

---

# 4. Critical design question: IR_GEP vs IR_LEA

The current backend rejects both:

```text
IR_GEP
IR_LEA
```

Do not assume which one should represent B0 indexing.

C1 RED must determine mechanically:

```text
Q1
What neutral IR does current PolyC frontend emit for:

  U8 *p
  I64 i
  p[i]

Q2
Does the parser/typechecker already admit that source form?

Q3
Does it emit:
  IR_GEP
  IR_LEA
  something else
  or fail before neutral IR?

Q4
What are the operand roles and types?

Q5
Is one existing opcode already intended to mean typed
element-address computation?

Q6
Would choosing the other opcode duplicate or contradict its
existing semantic intent?
```

Only after this evidence may the implementation seam be frozen.

Do NOT implement both `IR_GEP` and `IR_LEA` "for completeness".

### 4.1 C1 empirical finding

Per `evidence/ACT-POLYC-LLVM-GEP01/c1/opcode-selection.txt`:

  Q1/Q3: emits **`IR_IADD`** (followed by `IR_LOAD_DEREF`)
  Q2:    YES
  Q4:    IR_IADD dst=IR_TYPE_PTR, r1=IR_TYPE_PTR (base),
         r2=IR_TYPE_I64 (index)
  Q5:    NO existing opcode is designated as "typed element
         address computation"; IR_IADD with ptr operands is
         integer addition that happens to apply to pointers
  Q6:    N/A (neither IR_GEP nor IR_LEA is emitted)

### 4.2 Frozen opcode

```text
FROZEN_GEP_NEUTRAL_OPCODE = IR_IADD
```

The IR_IADD shape `dst=PTR, r1=PTR, r2=I64` is the
**only** existing neutral-IR shape whose operand roles
match the ACT §3 frozen target shape. The IR_IADD is the
canonical lowerer's output for pointer arithmetic on
`p + i` (src/ir.c:626-649).

Adding a new IR_GEP emission would be a neutral-IR
widening, which the ACT explicitly forbids unless RED
proves the existing opcode is "the exact correct
representation" — which is what C1 has established.

The implementation will treat the IR_IADD subset
(dst=PTR, r1=PTR, r2=I64) as **SHAPE_DEPENDENT** at the
LLVM backend's IR_IADD dispatch arm, emitting
`LLVMBuildGEP2(i8, base, [idx])` for that subset and
preserving the existing integer-add path for the
remaining IR_IADD shapes.

The IR_IADD row in the capability table remains
`SUPPORTED` (its overall opcode classification is
unchanged); the GEP-shaped subset is attributed as
SHAPE_DEPENDENT via the per-shape counter increment at
the dispatch seam.

---

# 5. Commit topology

Expected topology:

```text
C1  RED
    source→neutral-IR recon
    exact opcode + operand contract freeze
    negative-boundary freeze

C2  IMPL
    minimum backend implementation only

C3  EVIDENCE
    real compiler output + runtime + negative boundaries

C4  CLOSE
    acceptance matrix + roadmap transition
```

If C1 proves the required source syntax cannot yet reach an existing neutral IR representation:

```text
HALT_FRONTEND_SEAM_REQUIRED
```

Do not silently expand C2 into frontend/compiler-wide implementation.

If C1 proves a tiny already-intended frontend emission seam is missing and the ACT document explicitly updates authorization before IMPL, return to reviewer first.

### 5.1 C1 outcome

C1 PASSED. See `evidence/ACT-POLYC-LLVM-GEP01/c1/`. The
current frontend already emits an existing neutral-IR
shape (IR_IADD with ptr operands) that matches the
frozen GEP01 contract. No HALT.

---

# 6. C1 RED — minimum consumer recon

Authoritative trailers:

```text
ACT: ACT-POLYC-LLVM-GEP01
ACT-Phase: RED
```

No verdict trailer.

C1 may add only:

```text
docs/acts/ACT-POLYC-LLVM-GEP01.md
evidence/ACT-POLYC-LLVM-GEP01/c1/**
bounded RED fixtures if necessary
```

No production changes.

---

# 7. C1 mandatory source fixtures

Create or reuse the smallest fixtures that answer the design questions.

## 7.1 Constant zero

```text
I64 Read0(U8 *p) {
    return p[0];
}
```

Purpose:

```text
base pointer
constant I64 index 0
byte element
```

Expected semantics:

```text
Read0("A") -> 65
```

This fixture may optimize heavily, but RED must capture neutral IR before relying on optimized output.

## 7.2 Constant positive index

```text
I64 Read2(U8 *p) {
    return p[2];
}
```

Expected:

```text
['A','B','C'] -> 'C'
```

Purpose:

```text
prove non-zero address calculation
```

## 7.3 Dynamic index

```text
I64 ReadAt(U8 *p, I64 i) {
    return p[i];
}
```

This is the closure-critical shape.

Expected:

```text
ReadAt("012345", 0) = '0'
ReadAt("012345", 3) = '3'
ReadAt("012345", 5) = '5'
```

## 7.4 Walking loop / sequential consumer

If loops are already available and stable, use a bounded B0-shaped consumer such as:

```text
I64 Sum3(U8 *p) {
    return p[0] + p[1] + p[2];
}
```

or:

```text
I64 ReadSecondDigit(U8 *p) {
    U8 c = p[1];
    ...
}
```

Do not introduce a new loop feature merely for this ACT.

A sequence of indexed reads is enough to prove walking semantics.

---

# 8. C1 exact neutral-IR freeze

For each positive fixture capture:

```text
source
pre-optimization neutral IR
post-basic-optimization neutral IR
current failure diagnostic from LLVM backend
```

Freeze an explicit table:

```text
fixture
source expression
neutral opcode
dst
base operand
index operand(s)
element type
result type
backend diagnostic
```

Expected candidate shape if `IR_GEP` is the correct opcode:

```text
IR_GEP
  dst   = ptr
  base  = ptr
  index = I64
  elem  = I8
```

Expected candidate shape if `IR_LEA` is actually the intended opcode:

```text
IR_LEA
  dst   = ptr
  base  = ptr
  offset/index = I64
  scale/element contract = mechanically frozen
```

Do not infer fields from opcode names.

Use the actual IR definition and emitted instruction.

C1 must conclude exactly one:

```text
FROZEN_GEP_NEUTRAL_OPCODE = IR_GEP
```

or:

```text
FROZEN_GEP_NEUTRAL_OPCODE = IR_LEA
```

or:

```text
HALT_FRONTEND_SEAM_REQUIRED
```

### 8.1 C1 freeze outcome

```text
FROZEN_GEP_NEUTRAL_OPCODE = IR_IADD
```

Per `evidence/ACT-POLYC-LLVM-GEP01/c1/opcode-selection.txt`
and `evidence/ACT-POLYC-LLVM-GEP01/c1/operand-contract.txt`.

The IR_IADD subset with `dst=PTR, r1=PTR, r2=I64` is the
exact operand contract frozen for GEP01. Per ACT §4 hard
rule "Implement one existing neutral opcode, not both
IR_GEP and IR_LEA", IR_IADD is the single consumed
opcode; no new neutral-IR opcode is added.

---

# 9. C1 distinguish element indexing from byte offset

This distinction is important.

For the B0 first shape:

```text
element type = I8
```

therefore:

```text
element index == byte offset
```

numerically.

But the implementation contract must still state whether the neutral operation means:

```text
typed element index
```

or:

```text
raw byte offset
```

Do not leave this ambiguous merely because `sizeof(i8) == 1`.

Why:

```text
future I64 / struct / array GEP semantics differ
```

and we do not want GEP01 accidentally defining the wrong generic abstraction.

C1 must record one of:

```text
SEMANTICS = TYPED_ELEMENT_INDEX
```

or:

```text
SEMANTICS = BYTE_OFFSET_ONLY
```

If existing neutral IR cannot distinguish these meanings, record that as future-design residue but keep C2 limited to I8.

### 9.1 C1 outcome

```text
FROZEN_SEMANTICS = TYPED_ELEMENT_INDEX
```

See `evidence/ACT-POLYC-LLVM-GEP01/c1/semantics-freeze.txt`.

The IR_IADD's index operand is an element index whose
stride is implicit in the lowerer. For I8 (sizeof=1) the
stride is 1 and no IR_IMUL is emitted. The IMPL will use
`LLVMBuildGEP2(I8, base, [idx])` which respects LLVM's
typed-element semantics (the element type determines the
GEP stride; for I8 the stride is 1 byte).

---

# 10. C1 `inbounds` decision

Freeze:

```text
GEP_INBOUNDS_POLICY
```

Expected default:

```text
PLAIN_GEP
```

Reason:

PolyC currently has no demonstrated object-length proof attached to the pointer/index pair.

Use:

```text
LLVMBuildGEP2
```

not:

```text
LLVMBuildInBoundsGEP2
```

unless the RED evidence mechanically establishes source/object-bounds guarantees sufficient for every emitted instance.

Fixture-level known bounds are insufficient to justify globally emitting `inbounds`.

No no-wrap flags are authorized in GEP01.

### 10.1 C1 outcome

```text
GEP_INBOUNDS_POLICY = PLAIN_GEP
```

---

# 11. C1 negative boundary fixtures

At least one negative control per excluded dimension where the current frontend can express the form.

Examples:

```text
I64 *p; p[i]           -> NOT authorized in GEP01
nested p[i][j]         -> NOT authorized
structPtr[i].field     -> NOT authorized
byte pointer + I8 idx  -> normalize/reject according to actual IR contract;
                          do not silently admit new index widths
```

The most important negative control is:

```text
non-I8 element GEP
```

If current frontend can express:

```text
I64 *p;
return p[i];
```

GEP01 must NOT silently support it unless reviewer explicitly widens scope after RED.

Expected diagnostic:

```text
LLVM_BACKEND_UNSUPPORTED_GEP_SHAPE
```

or an existing appropriately named capability diagnostic.

Do not create a generic SUPPORT status for all GEP merely because I8 succeeds.

---

# 12. C1 capability-table plan

Current state:

```text
IR_GEP = REJECTED
IR_LEA = REJECTED
```

C1 must propose, but not yet implement, the exact capability transition.

Expected if `IR_GEP` is selected:

```text
IR_GEP:
  REJECTED
    ↓
  SHAPE_DEPENDENT

supported iff:
  dst      = PTR
  base     = PTR
  elem     = I8
  index    = I64
  nindices = 1
```

All other GEP shapes:

```text
REJECTED
```

Do NOT mark:

```text
IR_GEP = SUPPORTED
```

globally.

If `IR_LEA` is selected instead, apply the same SHAPE_DEPENDENT discipline to that opcode and leave `IR_GEP` rejected.

### 12.1 C1 capability-plan outcome

Per `evidence/ACT-POLYC-LLVM-GEP01/c1/capability-plan.txt`:

- `IR_IADD` row remains `SUPPORTED` (existing integer-add contract preserved).
- The GEP01 frozen subset is enforced at the IR_IADD dispatch seam via a pre-dispatch short-circuit. Counter attribution increments SHAPE_DEPENDENT for the GEP-shaped instance and SUPPORTED for the integer-add instance.
- `IR_GEP` and `IR_LEA` rows remain `REJECTED` (untouched).

---

# 13. C1 RED exit conditions

C1 PASS only if it freezes:

```text
FROZEN_NEUTRAL_OPCODE =
FROZEN_OPERAND_LAYOUT =
FROZEN_ELEMENT_TYPE = I8
FROZEN_INDEX_TYPE = I64
FROZEN_INDEX_COUNT = 1
FROZEN_RESULT_TYPE = PTR
FROZEN_SEMANTICS = typed-element-index | byte-offset-only
GEP_INBOUNDS_POLICY = PLAIN_GEP
CAPABILITY_TRANSITION = REJECTED -> SHAPE_DEPENDENT
```

and identifies at least:

```text
3 positive fixtures
1 negative non-authorized fixture
```

If any of these cannot be determined mechanically:

```text
HALT_RECON_INCOMPLETE
```

### 13.1 C1 freeze table

```text
FROZEN_NEUTRAL_OPCODE     = IR_IADD
FROZEN_OPERAND_LAYOUT     = dst=PTR, r1=PTR, r2=I64
FROZEN_ELEMENT_TYPE       = I8
FROZEN_INDEX_TYPE         = I64
FROZEN_INDEX_COUNT        = 1
FROZEN_RESULT_TYPE        = PTR
FROZEN_SEMANTICS          = TYPED_ELEMENT_INDEX
GEP_INBOUNDS_POLICY       = PLAIN_GEP
CAPABILITY_TRANSITION     = (no row reclassification; per-shape
                            SHAPE_DEPENDENT counter attribution at
                            dispatch seam)
POSITIVE_FIXTURES         = 4  (Read0, Read2, ReadAt, TwoDigits)
NEGATIVE_FIXTURES         = 1  (ReadI64, non-I8 element)
```

C1 RED PASS. Proceed to C2 IMPL.

---

# 14. C2 IMPL — bounded backend support

Authoritative trailers:

```text
ACT: ACT-POLYC-LLVM-GEP01
ACT-Phase: IMPL
```

C2 may modify only the smallest frozen seams established by C1.

Expected likely scope:

```text
src/llvm-backend.c
tests/evidence directly required for GEP01
```

No parser/typechecker/neutral-IR changes unless separately re-authorized after C1.

---

# 15. C2 lowering contract

The IR_IADD arm in src/llvm-backend.c (line 2379) gains a
pre-dispatch short-circuit that, when the operand shape
matches the GEP01 frozen contract, emits
`LLVMBuildGEP2(i8, base, [idx])` and attributes the
emission as SHAPE_DEPENDENT.

Conceptual skeleton:

```c
case IR_IADD:
case IR_ISUB: {
    LL_INC_SUPPORTED(lc);    /* IR_IADD/IR_ISUB still SUPPORTED */
    if (ins->op == IR_IADD && llGepShapeSupported(ins)) {
        /* ACT-POLYC-LLVM-GEP01: typed-element-indexed byte
         * address computation. The IR_IADD shape (dst=PTR,
         * r1=PTR, r2=I64) is the canonical emission for
         * `p + i` of byte-pointer indexing. */
        LL_INC_SHAPE_DEPENDENT(lc);
        LLVMValueRef base = llLowerPointerValue(lc, ins->r1);
        LLVMValueRef idx  = llLowerI64Value(lc, ins->r2);
        LLVMValueRef indices[1] = { idx };
        LLVMValueRef addr = LLVMBuildGEP2(
            lc->bld,
            LLVMInt8TypeInContext(lc->ctx),
            base, indices, 1, "gep_i8");
        llvmSet(&lc->values, irVarId(ins->dst), addr);
        return addr;
    }
    /* existing integer-add path */
    ...
}
```

Exact local APIs/types follow current backend conventions.

## 15.1 No implicit load

The GEP-shaped subset of IR_IADD lowering returns a pointer.

It must NOT itself emit:

```text
load
store
```

The subsequent existing `IR_LOAD_DEREF` performs:

```llvm
load i8, ptr %gep
```

This separation is mandatory.

## 15.2 No integerized address arithmetic

Forbidden implementation:

```text
ptrtoint
integer add/mul
inttoptr
```

GEP01 must use LLVM GEP semantics directly.

## 15.3 No implicit scaling constant

For I8:

```text
LLVM GEP type = i8
index = source I64 index
```

Do not manually multiply the index by 1.

Do not add a scale layer merely for future types.

## 15.4 No `inbounds`

Unless C1 explicitly authorized it:

```text
LLVMBuildGEP2
```

not:

```text
LLVMBuildInBoundsGEP2
```

---

# 16. Capability enforcement

The selected opcode (IR_IADD) becomes:

```text
SHAPE_DEPENDENT (subset)
```

with a mechanical predicate corresponding exactly to C1.

Any mismatch must reject with a named diagnostic.

Recommended diagnostic for shape mismatch (only triggered
if C1's shape predicate fails for a ptr+ptr+i64 IR_IADD —
which should not normally happen because the IR's
address-mode fusion would have folded such a case into
LOAD_DEREF::idx+scale first):

```text
LLVM_BACKEND_UNSUPPORTED_GEP_SHAPE
```

For the byte case specifically, the IADD path is already
type-consistent (no scale != 1 IR_IMUL); the new diagnostic
fires only as a safety net.

Include mechanically useful details:

```text
function
opcode
base type
index type
element type
index count
```

Example concept:

```text
LLVM_BACKEND_UNSUPPORTED_GEP_SHAPE:
  function Foo:
  IR_IADD byte GEP requires dst=PTR, r1=PTR, r2=I64,
  disp=0, idx=NULL, scale=0
```

Do not mention ARRAY01/STRUCT01 as though those are guaranteed successors.

---

# 17. C2 forbidden widening

C2 must not:

```text
add I64-element GEP
support struct member access
support arrays as aggregate values
support multiple indices
support pointer difference
support arbitrary pointer addition
support byte stores
add pointer casts
change Option-W
change mem2reg behavior
change neutral IR optimization
change ABI
```

If a positive fixture requires any of these:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

---

# 18. C2 conservation of BYTE-MEMORY

The existing byte path must remain unchanged.

For:

```text
base pointer without GEP
```

the current output must still resemble:

```llvm
%v = load i8, ptr %base
```

For:

```text
base[index]
```

the new output becomes:

```llvm
%addr = getelementptr i8, ptr %base, i64 %index
%v = load i8, ptr %addr
```

No other BYTE-MEMORY capability status may widen.

Byte store remains:

```text
DEFERRED_NOT_B0_BLOCKING
```

---

# 19. C3 EVIDENCE

Authoritative trailers:

```text
ACT: ACT-POLYC-LLVM-GEP01
ACT-Phase: EVIDENCE
```

No verdict trailer.

Evidence root:

```text
evidence/ACT-POLYC-LLVM-GEP01/c3/
```

Capture fresh evidence from the C2 tree.

---

# 20. C3 textual LLVM proof

For each positive fixture capture complete emitted LLVM.

Required structural checks for dynamic `ReadAt`:

```text
exactly one appropriate getelementptr for p[i]
source element type = i8
base operand = pointer derived from source base
index operand = I64 source index
GEP result type = ptr

load i8 uses GEP result

no ptrtoint
no inttoptr
no bitcast for address arithmetic
```

Expected:

```llvm
%gep = getelementptr i8, ptr %0, i64 %1
%ld  = load i8, ptr %gep
```

SSA names are not frozen.

Instruction count may vary if optimization legally folds constant-index fixtures.

The dynamic-index fixture is authoritative for proving GEP emission.

---

# 21. C3 independent LLVM validation

For every closure-critical emitted module:

```text
llvm-as
opt -passes=verify
```

must PASS.

Capture:

```text
hcc rc
llvm-as rc
verify rc
```

No "compiler emitted text therefore valid" inference.

---

# 22. C3 runtime proof

Exercise at least:

```text
buffer = "0123456789"

ReadAt(buffer, 0) = '0'
ReadAt(buffer, 1) = '1'
ReadAt(buffer, 5) = '5'
ReadAt(buffer, 9) = '9'
```

Also:

```text
Read2("ABC") = 'C'
```

Use numeric I8/U8 values if the runtime harness reports integers.

Do not execute intentionally out-of-object loads.

GEP may compute addresses outside the object without `inbounds`, but dereferencing invalid memory is not a valid runtime test.

---

# 23. C3 B0 walking proof

Add a B0-shaped positive fixture that proves **multiple distinct indexed reads** from one base pointer.

Example:

```text
I64 TwoDigits(U8 *p) {
    I64 a = p[0] - '0';
    I64 b = p[1] - '0';
    return a * 10 + b;
}
```

Expected:

```text
"42" -> 42
"07" -> 7
"99" -> 99
```

This proves the practical B0 requirement:

```text
same base
different byte indices
existing byte conversion/comparison/arithmetic
```

without introducing a loop or token representation.

---

# 24. C3 negative evidence

Prove the frozen boundary remains enforced.

At minimum:

```text
non-I8 element indexing
```

must remain rejected if expressible.

Also demonstrate that the selected sibling opcode remains rejected.

Example if `IR_GEP` is implemented:

```text
IR_LEA remains REJECTED
```

unless C1 established that frontend emits IR_LEA and that became the selected opcode instead.

Capability verifier must distinguish:

```text
selected opcode = SHAPE_DEPENDENT
sibling opcode  = REJECTED
```

---

# 25. C3 `inbounds` audit

Mechanically inspect emitted LLVM.

Required:

```text
getelementptr inbounds count = 0
```

unless C1 specifically authorized `inbounds`.

Expected:

```text
plain getelementptr
```

Record:

```text
INBOUNDS_POLICY = PLAIN_GEP
```

This is a semantic correctness gate.

---

# 26. C3 capability counters

Bind the new shape through the capability accounting.

Expected:

```text
selected GEP opcode contributes SHAPE_DEPENDENT
```

and no new:

```text
SUPPORTED
DEFENSIVE
UNREACHABLE
```

classification appears accidentally.

Per-fixture attribution should establish:

```text
ReadAt:
  exactly the expected GEP shape-dependent hit(s)
```

without widening unrelated operations.

---

# 27. C3 BYTE-MEMORY conservation

Freshly rerun:

```text
llvm-byte-memory01-test
```

Expected current baseline before GEP01:

```text
37/0
```

Require:

```text
FAIL=0
```

Do not require exact 37 if a separate GEP harness changes no BYTE-MEMORY test count.

Also confirm:

```text
BYTE_MEMORY_GEP_COUNT
```

inside the historical BYTE-MEMORY fixture set remains whatever its contract expects.

Do not retrofit old BYTE-MEMORY fixtures to use indexing merely to exercise GEP.

---

# 28. Dedicated GEP harness

Create:

```text
scripts/quality/llvm-gep01-test.sh
```

or repository-consistent equivalent.

The harness must mechanically test:

```text
toolchain available
positive constant-zero fixture
positive constant-nonzero fixture
positive dynamic-index fixture
B0 multi-read fixture
LLVM textual GEP structure
independent llvm-as
independent verify
runtime
negative non-I8 shape
capability status
sibling opcode rejection
no ptrtoint/inttoptr address arithmetic
no unauthorized inbounds
determinism where applicable
```

Verdict channel:

```text
FAIL > 0 -> process non-zero
```

Add a seeded self-test only if this harness implements nontrivial custom aggregation whose exit semantics are not trivially evident.

---

# 29. C3 production-delta review

Review the implementation range:

```text
git diff <C1>..<C2> -- src/
```

It must show only the seams frozen in C1.

No unrelated cleanup.

Explicitly report:

```text
files changed
lines changed
selected opcode
capability-row change
backend lowering arm
diagnostic change
```

If frontend/IR optimizer/etc. changed unexpectedly:

```text
HALT_SCOPE_DRIFT
```

unless separately authorized before C2.

---

# 30. C4 CLOSE

Authoritative trailers:

```text
ACT: ACT-POLYC-LLVM-GEP01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

only when all ACs pass.

No semantic repair in CLOSE.

---

# 31. Acceptance criteria

## AC01 — predecessor state

PASS iff closure records:

```text
BYTE-MEMORY01-RESUME02
  CLOSED PASS at b0c6ff6
```

and preserves its frozen boundary.

## AC02 — neutral opcode mechanically selected

PASS iff exactly one neutral opcode is frozen as the B0 byte indexing operation.

## AC03 — operand contract frozen

PASS iff:

```text
base       PTR
index      I64
element    I8
indices    1
result     PTR
```

or the exact mechanically discovered equivalent is frozen.

## AC04 — semantic meaning explicit

PASS iff closure records:

```text
TYPED_ELEMENT_INDEX
```

or:

```text
BYTE_OFFSET_ONLY
```

without ambiguity.

## AC05 — plain-GEP policy

PASS iff emitted GEP is non-`inbounds` unless RED proved the stronger contract.

Expected:

```text
PLAIN_GEP
```

## AC06 — dynamic indexed byte address

PASS iff:

```text
U8 *p
I64 i
p[i]
```

compiles through real frontend → neutral IR → LLVM.

## AC07 — LLVM GEP shape

PASS iff real output contains the equivalent of:

```llvm
getelementptr i8, ptr %base, i64 %index
```

for the dynamic fixture.

## AC08 — separation from memory access

PASS iff GEP lowering emits address computation only and the existing load path emits:

```llvm
load i8, ptr %gep
```

separately.

## AC09 — no integerized pointer arithmetic

PASS iff emitted GEP fixtures contain zero address-construction:

```text
ptrtoint
inttoptr
```

and no manual integer pointer arithmetic.

## AC10 — runtime indexing

PASS iff multiple indices retrieve the correct bytes.

## AC11 — B0 multi-read consumer

PASS iff one fixture successfully reads at least two different indices from the same base and computes the expected scalar result.

## AC12 — independent LLVM validation

PASS iff closure-critical modules pass:

```text
llvm-as
opt -passes=verify
```

## AC13 — capability status

PASS iff selected opcode is:

```text
SHAPE_DEPENDENT
```

not globally `SUPPORTED`.

## AC14 — negative non-I8 boundary

PASS iff an expressible non-I8 GEP shape remains rejected.

If the frontend cannot express the shape, record:

```text
FRONTEND_UNREACHABLE_NEGATIVE
```

and bind the backend capability predicate directly.

## AC15 — sibling opcode remains rejected

PASS iff whichever of:

```text
IR_GEP
IR_LEA
```

was not selected remains rejected.

## AC16 — byte store unchanged

PASS iff:

```text
BYTE_STORE_STATUS = DEFERRED_NOT_B0_BLOCKING
```

remains true.

## AC17 — BYTE-MEMORY conservation

PASS iff `llvm-byte-memory01-test` remains FAIL=0.

## AC18 — LOCAL-MEM2REG conservation

PASS iff:

```text
llvm-spike-test
ir-return-slot-forwarding01-test
```

remain GREEN and C9 synthesis is still absent.

## AC19 — capability-table verifier

PASS iff dispatch/capability/harness binding remains valid.

## AC20 — dedicated GEP harness

PASS iff:

```text
llvm-gep01-test
FAIL=0
```

and process rc=0.

## AC21 — no aggregate widening

PASS iff implementation introduces no struct/array/multi-index support.

## AC22 — no ABI change

PASS iff public calling convention / ABI remains unchanged.

## AC23 — no neutral-IR redesign

PASS iff only the C1-frozen existing representation is consumed.

If a neutral-IR redesign was necessary, this ACT must have HALTed rather than reaching C4.

## AC24 — patch hygiene

PASS iff each GEP01 commit range passes:

```text
git diff --check
```

## AC25 — Factory gates

PASS iff:

```text
factory-v2-commit-msg-check
factory-append-only-test
factory-closure-status
gate-fast
```

are all GREEN.

## AC26 — full compiler conservation

PASS iff at minimum:

```text
make clean
make
make llvm-all
llvm-byte-memory01-test
llvm-gep01-test
llvm-spike-test
llvm-intops01-test
ir-return-slot-forwarding01-test
harness-evidence-isolation-test
llvm-cap-table-verifier
```

all satisfy their authoritative contracts.

## AC27 — clean tree

PASS iff:

```text
git status --porcelain
```

is empty after CLOSE.

---

# 32. HALT taxonomy

Use the smallest applicable verdict.

```text
HALT_FRONTEND_SEAM_REQUIRED

  Current source indexing cannot reach an existing frozen
  neutral-IR representation without frontend work that GEP01
  did not authorize.

HALT_IR_SEMANTICS_AMBIGUOUS

  Existing IR_GEP / IR_LEA semantics cannot be distinguished
  mechanically enough to choose one safely.

HALT_SCOPE_EXPANSION_REQUIRED

  The minimum B0 consumer requires a shape outside:
    byte element
    pointer base
    single I64 index.

HALT_BACKEND_DEFECT

  Frozen GEP shape is correctly represented in neutral IR but
  bounded backend implementation cannot lower it correctly.

HALT_LLVM_VERIFY

  Emitted GEP LLVM fails assembler/verifier checks.

HALT_RUNTIME_MISMATCH

  Verifier-clean LLVM does not preserve indexed-read semantics.

HALT_CONSERVATION_REGRESSION

  Existing byte/mem2reg/intops or Factory mandatory gates regress.

HALT_SCOPE_DRIFT

  Implementation requires touching an unauthorized subsystem.
```

Do not continue implementing after a HALT condition is established.

---

# 33. Explicit non-goals

GEP01 is NOT:

```text
ARRAY01
STRUCT01
BYTE-STORE01
general pointer arithmetic
pointer casts
aggregate lowering
bounds checking
slice support
allocation support
token representation
loop implementation
BOOTSTRAP01
```

No opportunistic implementation.

---

# 34. Evidence layout

Recommended:

```text
evidence/ACT-POLYC-LLVM-GEP01/

c1/
  source-fixtures.txt
  opcode-selection.txt
  operand-contract.txt
  semantics-freeze.txt
  inbounds-policy.txt
  capability-plan.txt
  negative-boundary.txt
  _dump/                   (raw --dump-ir + --emit-llvm stderr captures)

c3/
  fixture-matrix.txt
  read0.ll
  read2.ll
  read-at.ll
  b0-multiread.ll
  llvm-as-results.txt
  verify-results.txt
  runtime-results.txt
  textual-structure.txt
  inbounds-audit.txt
  negative-boundary.txt
  capability-table.txt
  production-delta.txt
  conservation-gates.txt

c4/
  acceptance-matrix.txt
  closure-summary.txt
  residue.txt
  patch-hygiene.txt
  ROADMAP-update.txt
```

Do not store transient object files unless they materially improve reproducibility.

Textual LLVM plus command/output binding should normally suffice.

---

# 35. Roadmap transition on PASS

Do not automatically open ARRAY01 or STRUCT01.

On successful GEP01 closure:

```text
BYTE-MEMORY01-RESUME02
  CLOSED PASS

GEP01
  CLOSED PASS

NEXT:
  fresh B0 substrate recon
```

That recon must answer:

```text
Can the first PolyC lexer/tokenizer now be written with:

  U8 *src
  I64 cursor
  src[cursor]
  existing byte compare/conversion
  existing scalar arithmetic
  existing control flow
  existing mutable-local handling?

If YES:
  BOOTSTRAP01 directly.

If NO:
  identify the smallest concrete missing substrate.

Only then consider:
  ARRAY01
  STRUCT01
  allocation/buffer ownership work.
```

Do not inherit old speculative ordering.

---

# 36. Expected successful closure statement

If current architecture supports the RED-discovered shape as expected:

```text
ROOT CAUSE

  B0 could read a byte only at an already-computed pointer.
  It lacked typed indexed address computation for walking an
  input byte buffer.

FIX

  The frozen byte-index neutral opcode (IR_IADD with
  dst=PTR, r1=PTR, r2=I64) is lowered through LLVM plain
  getelementptr with:
    element type = i8
    base = pointer
    index = I64
    index count = 1

  The result remains a pointer.

  Existing IR_LOAD_DEREF performs the subsequent byte load.

SUPPORTED_GEP_SHAPE

  byte pointer + one I64 index only.

INBOUNDS

  NOT asserted.

INTEGERIZED POINTER ARITHMETIC

  NONE.

ARRAY / STRUCT SUPPORT

  NONE.

BYTE STORE

  remains DEFERRED_NOT_B0_BLOCKING.

VERDICT = PASS

NEXT = fresh B0 substrate recon
```

---

# 37. Required final ClineMM report

Return:

```text
VERDICT

IDENTITY
  ENTRY_HEAD = b0c6ff6881e3dae1b8c4c7f6166680b3f7c5e6e1
  C1_RED =
  C2_IMPL =
  C3_EVIDENCE =
  C4_CLOSE =
  FINAL_HEAD =
  WORKTREE =

RED RECON
  source indexing syntax =
  frozen neutral opcode =
  semantics =
  base type =
  index type =
  element type =
  result type =
  index count =
  inbounds policy =
  negative boundary =

IMPLEMENTATION
  capability transition =
  backend lowering seam =
  LLVM C API =
  GEP loads memory? =
  ptrtoint/inttoptr used? =
  aggregate support added? =

LLVM EVIDENCE
  dynamic ReadAt GEP shape =
  subsequent byte load =
  llvm-as =
  opt verify =

RUNTIME
  Read0 =
  Read2 =
  ReadAt indices =
  B0 multi-read =

NEGATIVE BOUNDARY =
BYTE-MEMORY CONSERVATION =
LOCAL-MEM2REG CONSERVATION =
CAPABILITY TABLE =

GATES
  llvm-gep01-test =
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
PRODUCTION DELTA =
RESIDUE =

ROADMAP STATE =
NEXT =
```

Expected success:

```text
VERDICT = PASS
ROADMAP STATE = CLOSED
NEXT = fresh B0 substrate recon
```

---

# 38. Hard rules

1. **Recon before implementation.**
2. Implement **one existing neutral opcode**, not both `IR_GEP` and `IR_LEA`.
3. Admit only **I8 element + pointer base + one I64 index**.
4. Use LLVM GEP directly; no `ptrtoint` arithmetic.
5. GEP computes an address; it does not load.
6. Do not assert `inbounds` without a real source/object-bounds proof.
7. Do not implement ARRAY01 or STRUCT01 here.
8. Do not add byte store.
9. If B0 needs a broader shape, HALT and report it.
10. On PASS, perform **fresh B0 recon before choosing another substrate ACT**.
