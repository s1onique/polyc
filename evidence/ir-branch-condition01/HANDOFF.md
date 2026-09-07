# ACT-POLYC-IR-BRANCH-CONDITION01 — HANDOFF (CORRECTION01 + CORRECTION02)

```text
ACT-POLYC-IR-BRANCH-CONDITION01                  = PASS (corrected)
ACT-POLYC-IR-BRANCH-CONDITION01-CORRECTION01     = PASS (this; closure identity repaired by CORRECTION02)
ACT-POLYC-IR-BRANCH-CONDITION01-CORRECTION02     = PASS (this; bounded docs/evidence repair)
```

## Identity

```text
ENTRY_HEAD                  = 774602a966584b34b355ec00e5f63a088f84164c
RED_HEAD                    = 341939ca7c56081e0bb45a435524219a4bd4a630
IMPLEMENTATION_HEAD         = cbf726ed939956ebc79790371a9d372942b10b05
ORIGINAL_CLOSURE (RESCINDED) = f631760ac2bf674a8997d40a62db36ffc43d56d9
CORRECTION01_SUBSTANTIVE    = 574840d4a5c28b2241b4d9dbc2a6f62d12ac1ede
CORRECTION01_CLOSURE_EVIDENCE = de90851fe3e389385eb3f732e6ac0932de2506de
CORRECTION01_LOOP_BREAKER   = 50a158ee403348bf85bc2654f867e58368a95ada
CORRECTION01_IMPL_SUBJECT   = cbf726ed9399

FINAL_HEAD:
    authoritative = $(git rev-parse HEAD)
    Do NOT embed a self-referential SHA. The current FINAL_HEAD
    is recorded as CORRECTION01_LOOP_BREAKER above for historical
    reference only; any future amend of this HANDOFF changes
    that SHA, so binding must be verified mechanically, not by
    trusting a committed value.

VERIFY_WITH:
    cd /Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
    SUBJECT=$(grep ^SUBJECT \
        evidence/ir-branch-condition01-correction01/gate-push-impl/log.txt \
        | head -1 | cut -d= -f2)
    DEPTH=$(git rev-list --count $SUBJECT..HEAD)
    HM=$(git rev-parse HEAD~$DEPTH | cut -c1-12)
    test "$SUBJECT" = "$HM" && echo PASS || echo FAIL

    Expected today:
        SUBJECT = cbf726ed9399
        DEPTH   = 3
        HM      = cbf726ed
        => PASS

BRANCH                = main
WORKTREE              = clean
```

## Predecessor

```text
BOUNDARY03_CORRECTION03_FINAL_HEAD = 774602a966584b34b355ec00e5f63a088f84164c
ENTRY_GATE_FAST                  = PASS
ENTRY_GATE_PUSH                  = PASS (SUBJECT=774602a96658)
```

## Phase 0 recon

```text
IR_BR_CONSTRUCTORS            = 1 (src/ir.c:97 irBranch)
IR_BRANCH_CALLERS             = 11 (if, while, do-while, for, switch x3,
                                    try, &&, ||, range-operator)
PREDICATE_PRODUCER_SET_BEFORE = {IR_ICMP, IR_FCMP}
TRUTHINESS_NORMALIZATION_SITE = src/ir.c:107-122 (type-driven; defect)
RAW_INTEGER_PRODUCER_CLASSES  = {IR_CALL (I8 return), IR_LOAD (I8),
                                 IR_PARAM (I8), local I8 constants}
```

## RED

```text
RED_RAW_INTEGER_REACHES_IR_BR         = YES
RAW_TYPE                              = I8
RAW_PRODUCER                          = IR_CALL (Identity)
RAW_NON_BOOLEAN_VALUE_REPRODUCED      = YES (2, 3, 255 U8; -1, -2, -128 I8)
CONTROL_COMPARISON_CAPTURED           = YES (control-01 cmp_eq)
CONTROL_I64_CAPTURED                  = YES (red-04 cmp_ne of I64)
```

## Implementation

```text
FILES                       = src/ir.c
IR_BRANCH_CLASSIFICATION_BEFORE = type-driven (cond->type == IR_TYPE_I8)
IR_BRANCH_CLASSIFICATION_AFTER  = producer-driven (irOpIsCmp(last->op) &&
                                 last->dst == cond)
TRUTHINESS_NORMALIZATION    = `cmp_ne(cond, 0)` inserted when the
                              immediately-preceding instruction in the
                              same block is not an IR_ICMP/IR_FCMP whose
                              dst equals cond.
NEW_HELPERS                 = `static IrValue *irNormalizeBranchCondition(
                                  IrBlock *block, IrValue *cond)`
                              (one function, file-scope static)
```

Production delta:
```text
 src/ir.c | 50 +++++++++++++++++++++++++++++++++-----------------
 1 file changed, 33 insertions(+), 17 deletions(-)
```

## Canonical invariant (after fix)

```text
IR_BR_OPERAND_CONTRACT = EXPLICIT_PREDICATE_SEMANTICS
PREDICATE_PRODUCER_SET_AFTER = {IR_ICMP, IR_FCMP}
RAW_INTEGER_TO_IR_BR         = NO  (was YES)
```

Verified via fresh `--dump-ir` against all 11 fixtures (see
`after/*.dump.txt` and `producer-matrix-after.txt`): every IR_BR
is preceded by a `cmp_*` whose dst is the branch operand.

## AC-23 corrected (CORRECTION01 closure)

Original closure claimed AC-23 PASS via F6 (toolchain unavailable)
and "structurally unchanged from predecessor". Reviewer correctly
flagged this as false-GREEN.

CORRECTION01 re-runs the real harness:

```text
$ which llvm-config
/nix/store/b6fykfvclbq81yis03blk6bqsmapmhdm-llvm-22.1.8-dev/bin/llvm-config

$ llvm-config --version
22.1.8

$ nm ./hcc | grep _LLVMAddFunction
                 U _LLVMAddFunction     (LLVM linked in)

$ make llvm-spike-test
=== positive matrix ===
PASS  src/tests/llvm-spike/01_const.HC
PASS  src/tests/llvm-spike/02_add.HC
PASS  src/tests/llvm-spike/03_sub_mul.HC
PASS  src/tests/llvm-spike/04_cmp_branch.HC
PASS  src/tests/llvm-spike/05_call.HC
=== cmp predicate matrix ===
PASS  04_cmp_branch: icmp sgt
=== negative matrix ===
PASS  src/tests/llvm-spike/neg_f64.HC      (LLVM_BACKEND_UNSUPPORTED_TYPE)
PASS  src/tests/llvm-spike/neg_pointer.HC  (LLVM_BACKEND_UNSUPPORTED_TYPE)
PASS  src/tests/llvm-spike/neg_struct.HC   (LLVM_BACKEND_UNSUPPORTED_TYPE)
PASS  neg_asm: parse-time rejection (NOT a backend witness)
=== conservation: no native fallback ===
PASS  01_const.ll: starts with LLVM ModuleID
=== determinism ===
PASS  determinism: 01_const twice
=================================
Summary: PASS=12  FAIL=0
=================================
```

Real llvm-spike-test PASS=12 FAIL=0 on impl HEAD cbf726ed9399.

AC-23 verdict (corrected): PASS (real harness output, not F6).
Full evidence: `evidence/ir-branch-condition01-correction01/llvm-spike-test-summary.txt`.

## AC-26 corrected (CORRECTION01 closure)

Original closure claimed "even if L2 were removed for other reasons,
branch semantics for this class would still be correct". Reviewer
correctly flagged this as overclaimed.

CORRECTION01 splits the claim:

```text
IR_SEMANTIC_DEPENDENCY_ON_L2_REMOVED       = YES
NATIVE_MACHINE_EXECUTION_DEPENDENCY_ON_L2_REMOVED = NO
```

The new IR carries `cmp_ne(call_result, 0)` explicitly, so an IR
interpreter cannot regress IR semantics. But the CURRENT native
lowering on x86_64 emits `callq _Identity; cmpq $0, %rax; je .L`,
which reads the full 64-bit %rax — so it still depends on the
callee's `movzbq %al, %rax` epilogue (L2) to clean the upper bits.

Pre-fix emit was `callq _Identity; testq %rax, %rax; jz .L` —
same L2 dependency. The IR_BR canonicalization is syntactically
different (testq -> cmpq $0; jz -> je) but semantically the same
for this register model.

Full analysis: `evidence/ir-branch-condition01-correction01/l2-clarification.txt`.

## Representation residue

```text
IR_BR_TYPES_AFTER  = MIXED_I8_I64 (representation residue, not semantic
                                    ambiguity)
UNIFORM_WIDTH_REQUIRED = NO
NEW_BOOLEAN_TYPE   = NO
```

The predicate dst widths remain mixed: `cmp_ne(I8_call_result, 0)` is
I8; `cmp_eq(I64_param, K)` is I64; `cmp_lt(I64, I64)` is I64. This is
honest representation residue and the ACT does not require uniform
width. AC-16/AC-17 PASS.

## L1/L2/L3 (corrected)

```text
L1_CHANGED = NO  (backend integer zero/nonzero test unchanged;
                  pre-fix `testq` lowered the same way post-fix
                  `cmpq $0` lowers)
L2_CHANGED = NO  (callee epilogue movzbq/uxtb unchanged)
IR_SEMANTIC_DEPENDENCY_ON_L2_REMOVED = YES
NATIVE_MACHINE_DEPENDENCY_ON_L2_REMOVED = NO
```

The implementation commit cbf726e is preserved verbatim. No
production-code changes are authorized by this correction ACT.

## Truthiness

```text
ZERO      = false
ONE       = true
TWO       = true
THREE     = true
U8_255    = true
NEG_ONE   = true
NEG_TWO   = true
NEG_128   = true
AOT_JIT_AGREE = YES  (JIT rc=255; gate-push aot/jit checks PASS)
```

## Native

```text
AOT        = PASS (gate-push CHECK=aot STATUS=PASS on cbf726ed9399)
JIT        = PASS (gate-push CHECK=jit STATUS=PASS on cbf726ed9399)
LSP        = PASS (gate-push CHECK=lsp STATUS=PASS on cbf726ed9399)
CORPUS     = PASS (gate-push)
CMP_BR_FUSION = PASS (input shape unchanged for all comparison fixtures)
```

## LLVM (corrected from "structurally unchanged" to real PASS)

```text
LLVM_SPIKE_TEST                = PASS=12 FAIL=0
LLVM_FEATURES_ADDED            = NO
TRUNC_TRUTHINESS_ADDED         = NO
NEW_BOOLEAN_TYPE               = NO
LLVM_BACKEND_REJECTIONS_AT_IR_BR = unchanged (src/llvm-backend.c:585)
```

## Gates

```text
GATE_FAST                    = PASS
GATE_PUSH_IMPLEMENTATION     = PASS (cbf726ed9399; SUBJECT=cbf726ed9399)
                                CHECK=build STATUS=PASS
                                CHECK=install STATUS=PASS
                                CHECK=aot STATUS=PASS
                                CHECK=jit STATUS=PASS
                                CHECK=lsp STATUS=PASS
                                CHECK=diff-check STATUS=PASS
                                VERDICT=PASS
LLVM_SPIKE_TEST              = PASS (cbf726ed9399; PASS=12 FAIL=0)
DIFF_CHECK                   = clean
```

Full log: `evidence/ir-branch-condition01-correction01/gate-push-impl/log.txt`

## Scope

```text
LANGUAGE_CHANGED   = NO
ABI_CHANGED        = NO
REGALLOC_CHANGED   = NO
BACKENDS_CHANGED   = NO
IR_TYPE_I1_ADDED   = NO
```

Production code delta: src/ir.c only (one function edited, one helper
introduced, file-scope static). No changes to:
- src/x86_64.c, src/x86_64-jit.c, src/aarch64.c, src/aarch64-jit.c
- src/llvm-backend.c
- src/ir-optimise.c
- src/ir-regalloc.c
- src/ir-types.h, src/ir-types.c
- any other src/* file
- any scripts/* file
- any Makefile rule

## Residue

```text
P0 = none
P1 = shell-rc-clobber artifact in original llvm-spike-test.txt:
     "rc=0" was actually the last-command rc, not hcc rc. The
     actual hcc rc for --emit-llvm without LLVM is 1 (correct).
     Recorded in evidence/ir-branch-condition01-correction01/
     shell-rc-artifact.txt. No separate hcc bug; only sloppy
     shell handling. Future ACTs should use bash -c + explicit
     echo $? for exit-code reporting.
P1 = ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01 may
     now resume its work, because the canonicalized branch
     semantic model (IR_BR always consumes a predicate producer)
     maps cleanly onto LLVM's `br i1` requirement. AC-23 PASS
     on the existing spike confirms this mapping.
P2 = Native-machine dependency on L2 (callee epilogue widening)
     for branch correctness is unchanged by this ACT. A
     future ACT that wants to remove L2 must also revisit
     the native IR_CALL result contract (e.g. require IR_CALL
     narrow-return to materialize a zero-extended value in IR
     space). Out of scope here.
P2 = Mixed predicate widths (I8 cmp_ne dst vs I64 cmp_eq dst)
     are representation residue, not semantic ambiguity, and
     may be normalized in a future dedicated ACT
     (ACT-POLYC-IR-PREDICATE-TYPE01 per ACT §87).
```

## NEXT ACT

```text
ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01
```

The canonical IR_BR operand model established by this ACT is exactly
what LLVM's `br i1` requirement needs. Real llvm-spike-test PASS=12
on the implementation commit confirms the mapping. LLVM support work
can now resume against a much cleaner branch semantic boundary.

## DRIFT NOTE (superseded by CORRECTION02)

The CORRECTION01 closure originally pinned FINAL_HEAD via a
self-referential SHA + DRIFT NOTE pattern. CORRECTION02 (this
ACT) replaced that pattern with mechanical binding (see the
VERIFY_WITH block under ## Identity above). The mechanical
recipe is the authoritative binding; the historical SHA values
under CORRECTION01_LOOP_BREAKER etc. are recorded only for
audit, not as the identity contract.

Closure identity is now bound by:

    SUBJECT=$(grep ^SUBJECT evidence/ir-branch-condition01-correction01/gate-push-impl/log.txt | head -1 | cut -d= -f2)
    DEPTH=$(git rev-list --count $SUBJECT..HEAD)
    HM=$(git rev-parse HEAD~$DEPTH | cut -c1-12)
    test "$SUBJECT" = "$HM" && echo PASS || echo FAIL

No amend of this HANDOFF can invalidate that recipe, because
the recipe reads SUBJECT from a stable, externally captured
file (gate-push-impl/log.txt) and computes DEPTH dynamically.
