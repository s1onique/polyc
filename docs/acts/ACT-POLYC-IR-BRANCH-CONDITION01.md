# ACT-POLYC-IR-BRANCH-CONDITION01

**Title:** Canonicalize Truthiness Before `IR_BR`

**Repository:** PolyC

**Branch:** `main`

**ENTRY_HEAD:** `774602a966584b34b355ec00e5f63a088f84164c`

**Immediate predecessor:** `ACT-POLYC-IR-BOUNDARY03-CORRECTION03` rev5 (PASS)

**Class:** IR SEMANTICS / CANONICALIZATION / BACKEND CONSERVATION

**Primary production area:** `src/ir.c` (function `irBranch`, lines 97-136)

**Language syntax change:** FORBIDDEN

**Source-language truthiness change:** FORBIDDEN

**New Boolean IR type (`IR_TYPE_I1`, `IR_TYPE_BOOL`):** FORBIDDEN

**LLVM feature expansion:** FORBIDDEN

**Native ABI redesign:** FORBIDDEN

**JIT/AOT instruction-selection redesign:** FORBIDDEN

**Broad integer-type normalization:** FORBIDDEN

**Primary expected implementation:** bounded `IR_BR` condition canonicalization

---

## §0. Mission

PolyC currently has one source-language condition contract (`0` -> false,
`nonzero` -> true) but more than one neutral-IR shape can encode that
condition. A normalized path looks approximately like:

```text
value
  | zext / ordinary lowering as needed
  v
IR_ICMP NE value, 0
  v
IR_BR comparison-result
```

while a real reachable bypass path currently looks like:

```text
IR_CALL returns I8
  v
IR_BR raw-I8-value
```

with no preceding `cmp_ne`. The source semantics are correct today on
the native backends, but the neutral IR makes a backend know too much
about the provenance and width of a branch operand.

This ACT establishes and mechanically enforces:

> Every `IR_BR` operand represents an explicit branch predicate. Any
> arbitrary integer condition must be converted to `value != 0` before
> `IR_BR` is constructed.

This ACT does not require a dedicated Boolean IR type. It does not
require all branch predicates to have one physical width. The primary
goal is semantic canonicalization, not type-system redesign.

---

## §1. Predecessor facts accepted as inputs

```text
PREDECESSOR_FINAL_HEAD
    774602a966584b34b355ec00e5f63a088f84164c

SOURCE_CONDITION_CONTRACT
    I64_ZERO_NONZERO_TRUTHINESS

IR_BR_VALUE_CONTRACT (CORRECTION03 verdict, post-L1/L2)
    I8_OR_I64_ZERO_NONZERO_TRUTHINESS

IR_BR_TYPE_CONTRACT
    MIXED_I64_I8

REAL_BYPASS
    IR_CALL -> i8 value -> IR_BR
    no cmp_ne

NORMALIZED_PATH
    arbitrary non-I8 condition -> compare-to-zero -> IR_BR

NATIVE_RUNTIME
    tested bypass cases correct

LLVM
    rejects unsupported I8 branch path cleanly

L1
    IR_BR backend emission tests condition register
L2
    demonstrated IR_CALL narrow-return path may establish
    widening before L1 consumes the value
L3
    L1 + L2 compose to correct observed native behavior

L1/L2 analysis location:
    evidence/ir-boundary03-correction03/l1l2l3-analysis.md
```

---

## §2. Why this ACT exists

The predecessor chain demonstrated a reachable class where
`cond->type == IR_TYPE_I8` causes `irBranch()` (src/ir.c:97-136) to
bypass truthiness normalization. The relevant historical logic is:

```c
if (cond->type != IR_TYPE_I8) {
    int isa_bool = 0;
    if (!listEmpty(block->instructions)) {
        IrInstr *last = block->instructions->prev->value;
        if (irOpIsCmp(last->op) && last->dst == cond) {
            isa_bool = 1;
        }
    }
    if (!isa_bool) {
        IrValue *zero = irConstInt(IR_TYPE_I8, 0);
        IrValue *bool_cond = irTmp(IR_TYPE_I8, 1);
        IrInstr *cmp = irICmp(bool_cond, IR_CMP_NE, cond, zero);
        listAppend(block->instructions, cmp);
        cond = bool_cond;
    }
}
irInstrNew(IR_BR, cond, NULL, NULL);
```

The type check is therefore doing two jobs:

```text
representation question: is this value I8?
semantic question:       is this value already a predicate?
```

Those are not equivalent. That coupling is the defect under
investigation.

---

## §3. Phase 0 -- recon (FRESH from ENTRY_HEAD)

Mechanical checks (rg from ACT §9):

```text
irBranch() call sites (rg 'irBranch\(' src):
    src/ir.c:97   irBranch definition (THE seam)
    src/ir.c:501  range-operator short-circuit (a OP1 b)
    src/ir.c:538  logical && short-circuit
    src/ir.c:564  logical || short-circuit
    src/ir.c:1930 try/catch enter_ret != 0 branch
    src/ir.c:1978 if-statement (irLowerIf)
    src/ir.c:2026 for-loop condition
    src/ir.c:2072 while-loop condition
    src/ir.c:2116 do-while condition
    src/ir.c:2358 switch single-value case (==)
    src/ir.c:2368 switch range-case lower bound (>=)
    src/ir.c:2377 switch range-case upper bound (<=)
```

```text
IR_BR constructors (rg 'IR_BR' src):
    Only ONE: irBranch() at src/ir.c:97-136.
    All 11 callers route through that one function.
```

```text
PREDICATE_PRODUCER_SET_BEFORE = {IR_ICMP, IR_FCMP}
    (semantically known; structurally exploited only via the
    fragile `last->dst==cond` fallback at src/ir.c:111)
```

```text
TRUTHINESS_NORMALIZATION_SITE = src/ir.c:107-122
    (type-driven, NOT producer-driven; the defect)
```

Full evidence: `evidence/ir-branch-condition01/recon.txt`

---

## §4. Phase 0 -- producer taxonomy

Eleven fresh `--dump-ir` witnesses (run from ENTRY_HEAD on the actual
`./hcc` binary) classified IR_BR operand source shapes:

| fixture          | source expr                | pre-fix cond type | pre-fix producer          | normalized? |
|------------------|----------------------------|-------------------|---------------------------|-------------|
| red-01           | `if (IdentityU8(x))`       | i8 tmp            | IR_CALL (Identity)        | NO BYPASS |
| red-02           | `if (x)` U8 param          | i8 (cmp_ne dst)   | IR_ICMP                   | YES |
| red-03           | `if (IdentityI8(x))`       | i8 tmp            | IR_CALL (IdentityI8)      | NO BYPASS |
| red-04           | `if (x)` I64 param         | i8 (cmp_ne dst)   | IR_ICMP                   | YES |
| red-05           | `while (IdentityU8(x))`    | i8 tmp            | IR_CALL (Identity)        | NO BYPASS |
| red-06           | `do { } while (NegOne(x))` | i8 tmp            | IR_CALL (NegOne)          | NO BYPASS |
| red-07           | `for (i<x; i++)`           | i64 (cmp_lt dst)  | IR_ICMP                   | YES (cmp) |
| red-08           | `if (!x)` U8               | i64 (cmp_eq dst)  | IR_ICMP                   | YES (cmp) |
| red-09           | `if (a && b)` U8 U8        | i8 (cmp_ne dst) / phi | IR_ICMP / IR_PHI        | YES (first) |
| red-10           | nested `Identity(a)` `Identity(b)` | i8 tmp    | IR_CALL x2                | NO BYPASS x2 |
| control-01       | `if (x == 2)` U8           | i64 (cmp_eq dst)  | IR_ICMP                   | YES (cmp) |

Full matrix: `evidence/ir-branch-condition01/producer-matrix-before.txt`

Summary:

- 5 bypass occurrences across 4 fixtures (red-01, red-03, red-05, red-06, red-10 x2)
- 6 normalized (predicate-producer) paths
- The 5 bypass occurrences all share the same root cause: cond arrives
  at irBranch() with type IR_TYPE_I8, so the entire normalization
  block at src/ir.c:107-122 is skipped.

---

## §5. RED -- Principal (AC-03)

Real source fixture (mirrors the predecessor's witness-02 shape):

```c
U8 Identity(U8 x) { return x; }

U8 TestId(U8 x) {
    if (Identity(x)) return 1;
    return 0;
}
```

Captured via `--dump-ir` on ENTRY_HEAD. The IR for `TestId` (after
basic optimisations) is:

```text
i8 TestId(%p6 i8 param) {
  bb3 -> predecessors:  {}  successors: {5, 6}
    store    %l7 i8 local, %p6 i8 param  ; line 3
    alloca   %t8 i8 tmp, 1 i8 const int  ; line 3
    zext     %t10 i64 tmp, %l7 i8 local  ; line 4
    arg       %t10 i64 tmp
    call     %t9 i8 tmp, Identity  ; line 4
    br       %t9 i8 tmp, bb5, bb6  ; line 4        RAW i8 branch
  ...
}
```

Classification:

```text
RED_RAW_INTEGER_REACHES_IR_BR = YES
RAW_TYPE                      = I8
RAW_PRODUCER                  = IR_CALL (Identity)
```

NO immediate predicate-producing instruction between call and br.
This reproduces the principal defect at src/ir.c:107
(`if (cond->type != IR_TYPE_I8)` skips normalization entirely).

Full evidence: `evidence/ir-branch-condition01/red-raw-i8-branch.txt`,
`evidence/ir-branch-condition01/red/red-01-identity-bypass.dump.txt`.

---

## §6. RED -- Secondary (AC-04)

The raw-I8 branch operand can carry values outside `{0, 1}`. The
runtime-correctness-bypass.HC fixture exercises the principal bypass
class with values:

```text
IdentityU8(0), (1), (2), (3), (255)
IdentityI8(0), (1), (-1), (-2), (-128)
```

The IR dump shows `br %t9 i8 tmp, bb5, bb6` with cond carrying
whatever value the call returned; no normalization to {0, 1} occurs at
IR level.

Runtime correctness (JIT exit code = `Main`'s I64 return value):

```text
./hcc --install-dir=build/hermetic-prefix -jit \
    evidence/ir-branch-condition01/runtime-correctness-bypass.HC
rc=255
```

Decoded: 0+1+2+4+8+0+16+32+64+128 = 255.

Classification:

```text
RAW_BRANCH_OPERAND_DOMAIN_CONTAINS_NON_BOOLEAN = YES
```

Full evidence: `evidence/ir-branch-condition01/red-nonboolean-domain.txt`.

---

## §7. Control REDs (AC-05)

### §7.1 -- already-canonical comparison (`if (x == 2)`)

```c
U8 TestEq(U8 x) {
    if (x == 2) return 1;
    return 0;
}
```

Observed IR: `zext` + `cmp_eq` + `br`. The `cmp_eq` is the LAST
instruction in the same block and its dst is the IR_BR operand;
triggers the fallback at src/ir.c:111. This is the canonical
"already a predicate" shape.

```text
COMPARISON_ALREADY_PREDICATE = YES
```

Required post-fix shape: same one-cmp-one-branch structure; FORBIDDEN
double normalization `cmp_ne(cmp_eq, 0)`.

Full evidence: `evidence/ir-branch-condition01/control-comparison-before.txt`.

### §7.2 -- I64 truthiness path (`if (x)` I64)

```c
I64 TestI64(I64 x) {
    if (x) return 1;
    return 0;
}
```

Observed IR: `cmp_ne` + `br`. Goes through the existing
src/ir.c:107-122 normalization block.

```text
I64_TRUTHINESS_ALREADY_NORMALIZED = YES
```

Full evidence: `evidence/ir-branch-condition01/control-i64-before.txt`.

---

## §8. Acceptance criteria

(Full acceptance criteria are listed at §15.)

---

## §9. Commit topology (cap = 3)

- Commit 1 (this): RED + ACT + recon + before evidence (no production code)
- Commit 2: implementation in src/ir.c (the only production delta)
- Commit 3: closure (after evidence, HANDOFF, gate evidence)

---

## §10. Mandatory HALT taxonomy (selected)

```text
HALT_PRINCIPAL_RED_NOT_REPRODUCED
    Real I8 raw-condition bypass cannot be reproduced.

HALT_BRANCH_PREDICATE_REQUIRES_TYPE_DECISION
    Canonical truthiness cannot be expressed correctly without
    choosing/redesigning neutral predicate types.

HALT_FCMP_PREDICATE_CONTRACT_UNPROVEN
    Floating comparison cannot be safely classified under the same
    predicate rule.

HALT_NATIVE_BRANCH_SEMANTICS_SPLIT
    AOT and JIT disagree.

HALT_BACKEND_CHANGES_REQUIRED
    Correct neutral canonicalization unexpectedly requires native
    backend redesign.

HALT_PUSH_GATE_RED
    Immutable implementation tree fails gate-push.
```

HALT is successful execution.

---

## §11. Implementation target (Commit 2 sketch)

Replace the type-driven check at src/ir.c:107 with a
producer-driven check. The new seam is the single function
`irBranch`; no other production files need to change for the
semantic canonicalization itself.

Sketch (illustrative only):

```c
static IrValue *irNormalizeBranchCondition(IrBlock *block, IrValue *cond) {
    /* If the previous instruction in this same block is a recognized
     * predicate producer whose dst equals cond, cond is already a
     * predicate. (Same fragile shape as today, but now SEMANTIC.) */
    if (!listEmpty(block->instructions)) {
        IrInstr *last = (IrInstr *)block->instructions->prev->value;
        if (irOpIsCmp(last->op) && last->dst == cond) {
            return cond;
        }
    }
    /* Otherwise form explicit (cond != 0) predicate. */
    IrValue *zero = irConstInt(IR_TYPE_I8, 0);
    IrValue *bool_cond = irTmp(IR_TYPE_I8, 1);
    IrInstr *cmp = irICmp(bool_cond, IR_CMP_NE, cond, zero);
    listAppend(block->instructions, cmp);
    return bool_cond;
}

IrInstr *irBranch(IrFunction *func, IrBlock *block,
                  IrValue *cond, IrBlock *true_block, IrBlock *false_block) {
    if (!block || !cond || !true_block || !false_block) {
        loggerPanic("irBranch: NULL parameter provided\n");
    }
    cond = irNormalizeBranchCondition(block, cond);
    IrInstr *instr = irInstrNew(IR_BR, cond, NULL, NULL);
    instr->extra.blocks.target_block = true_block;
    instr->extra.blocks.fallthrough_block = false_block;
    listAppend(block->instructions, instr);
    block->sealed = 1;
    irFunctionAddMapping(func, block, true_block);
    irFunctionAddMapping(func, block, false_block);
    return instr;
}
```

Differences from current behavior:

- Type (I8 vs I64 vs ...) no longer gates normalization.
- Predicate classification is by producer opcode (`irOpIsCmp`).
- For the I8 bypass class (call-return, cross-block), explicit
  `cmp_ne(cond, 0)` is now inserted before IR_BR.
- For the already-canonical comparison class (e.g. `if (x==2)`),
  no extra normalization is inserted (the previous instruction
  matches `irOpIsCmp` and its dst is cond).

---

## §12. Why not simply force I64?

Uniform I64 would simplify one representation dimension, but it does
not by itself establish a semantic branch predicate. An arbitrary
I64 255 still bypasses truthiness normalization. The stronger
invariant is:

```text
arbitrary integer -> explicit truthiness predicate -> IR_BR
```

Representation can then evolve independently.

---

## §13. Why not simply force I8?

I8 is exactly the current bypass. Forcing I8 does not address the
predicate-semantics question at all.

---

## §14. Architecture rationale

This ACT compresses backend reasoning:

```text
Before:
  backend sees I8 branch value
  -> asks where it came from
  -> perhaps relies on call-return widening (L2)
  -> performs truthiness test (L1)

After:
  backend sees IR_BR predicate
  -> lowers branch
```

That is a smaller conceptual contract. It aligns with PolyC's
charter preference (P1/P2: comprehensibility over generality;
minimize conceptual count) for reducing conceptual count rather than
multiplying backend-specific knowledge.

---

## §15. Acceptance criteria (full)

### Entry

- AC-01: `ENTRY_HEAD = 774602a966584b34b355ec00e5f63a088f84164c` or
  explicitly accepted administrative descendant.
- AC-02: entry gate-fast=PASS, entry gate-push=PASS, worktree=clean.

### RED

- AC-03: Fresh real-source RED reproduces `IR_CALL i8 -> IR_BR i8` with
  no immediate truthiness predicate.
- AC-04: At least one reproduced raw branch operand can carry a value
  outside `{0, 1}`.
- AC-05: An already-comparison condition is captured as the non-bypass
  control (control-01).
- AC-06: No production semantics changed before `RED_HEAD`.

### Implementation

- AC-07: After implementation, the principal bypass becomes
  `IR_CALL -> explicit truthiness predicate -> IR_BR`.
- AC-08: No real tested arbitrary integer producer reaches `IR_BR`
  directly.
- AC-09: Already-predicate comparison paths do not receive redundant
  truthiness wrapping.
- AC-10: `IR_BR` predicate classification is based on semantic producer
  identity, not solely `IR_TYPE_I8`.

### Semantics

- AC-11: Source zero/nonzero behavior unchanged for 0, 1, 2, 3, -1, -2
  (plus 255 for U8 where valid). Proven via runtime-correctness-bypass.
- AC-12: AOT/JIT agree on the bypass fixtures.
- AC-13: `SOURCE_CONDITION_CONTRACT = ZERO_NONZERO_TRUTHINESS` unchanged.
- AC-14: Closure states
  `IR_BR_OPERAND_CONTRACT = EXPLICIT_PREDICATE_SEMANTICS` with the
  approved producer set recorded.

### Representation

- AC-15: No `IR_TYPE_I1` or new Boolean type.
- AC-16: If I8/I64 predicate-result width remains mixed, it is
  documented as representation residue, not semantic ambiguity.
- AC-17: If uniform width becomes mechanically required:
  `HALT_BRANCH_PREDICATE_REQUIRES_TYPE_DECISION`.

### Native conservation

- AC-18: AOT inherited suite PASS.
- AC-19: JIT inherited suite PASS.
- AC-20: LSP inherited suite PASS.
- AC-21: Corpus/gate inherited baseline PASS.
- AC-22: Native `IR_CMP_BR` optimization still works on canonical
  compare+branch input (proven via control-01 fixture).

### LLVM conservation

- AC-23: Existing LLVM spike harness PASS.
- AC-24: No LLVM feature expansion.
- AC-25: No generic trunc-to-i1 truthiness implementation added.

### Architecture

- AC-26: The demonstrated `IR_CALL` bypass no longer requires L2
  call-return widening to establish branch semantic correctness.
- AC-27: Backend branch emitters do not need producer-history knowledge.
- AC-28: No native ABI code changes.
- AC-29: No regalloc changes.
- AC-30: No native-fusion boundary regression.

### Gates/hygiene

- AC-31: `make gate-fast=PASS`.
- AC-32: `gate-push(IMPLEMENTATION_HEAD) = PASS`.
- AC-33: `git diff --check ENTRY_HEAD..FINAL_TREE` exit 0.
- AC-34: Worktree clean.
- AC-35: Commit count <= 3.

---

## §16. Successful closure statement

```text
SOURCE_CONDITION_CONTRACT    = ZERO_NONZERO_TRUTHINESS
IR_BR_OPERAND_CONTRACT       = EXPLICIT_PREDICATE_SEMANTICS
RAW_INTEGER_TO_IR_BR         = FORBIDDEN
IR_CALL_I8_BYPASS            = ELIMINATED
PREDICATE_PRODUCER_SET       = {IR_ICMP, IR_FCMP}
IR_BR_TYPE_CONTRACT          = MIXED_I8_I64 (representation residue)
NEW_BOOLEAN_TYPE             = NO
NATIVE_AOT                   = PASS
NATIVE_JIT                   = PASS
LLVM_SPIKE                   = PASS
GATE_PUSH_IMPLEMENTATION     = PASS
```
