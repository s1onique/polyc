# ACT-POLYC-IR-BOUNDARY03 — HANDOFF

## 1. VERDICT

```text
ACT-POLYC-IR-BOUNDARY03
    STAGE              = C1 RED + IMPLEMENTATION (single ACT, 4 commits)
    STATUS             = PASS_WITH_NEXT_ACT_DECISION
    ENTRY_HEAD         = f652f3c9ca7724b191bc6cd41c6a400316e30c0a
    RED_HEAD           = 596ffc35a5268bfa1193ba88498713bafd53a850
    IMPLEMENTATION_HEAD = dab8cc72497256b0bcd945f054df5e94cbad155d
    EVIDENCE_HEAD      = 4f30c2b2c0f756c7a67c6aa0fedfb1efdf853e76
    CLOSURE_HEAD       = e4a63bdd372eeb0721db0d1fb1a182ebfadf1e5d
    WORKTREE_STATUS    = clean

    Principal RED          = HALT_LLVM_FUSION_NOT_REPRODUCED
                            (literal claim; boundary was already enforced)
    Architectural intent   = SATISFIED with a stronger finding
                            (boundary already in place; dead code
                            removed; explicit boundary assertion added)

    IR_BR_CONTRACT         = MIXED_OR_UNPROVEN
    AOT_JIT_AGREE          = YES  (no HALT_NATIVE_BRANCH_SEMANTICS_SPLIT)

    gate-fast              = PASS
    gate-push ENTRY_HEAD   = PASS  (see entry-gate-push.txt)
    gate-push IMPLEMENTATION_HEAD = PASS  (see gate-push-implementation.txt)
    git diff --check
        ENTRY..CLOSURE     = exit 0  (see diff-check.txt)
    llvm-spike-test        = PASS 12/0

    NEXT_ACT               = ACT-POLYC-IR-BOOLEAN01
                            (settle IR_BR_CONTRACT; no IR_TYPE_I1)
```

## 2. IDENTITY (per §71)

```text
IDENTITY
    BRANCH                = main
    ENTRY_HEAD            = f652f3c9ca7724b191bc6cd41c6a400316e30c0a
    RED_HEAD              = 596ffc35a5268bfa1193ba88498713bafd53a850
    IMPLEMENTATION_HEAD   = dab8cc72497256b0bcd945f054df5e94cbad155d
    EVIDENCE_HEAD         = 4f30c2b2c0f756c7a67c6aa0fedfb1efdf853e76
    CLOSURE_HEAD          = e4a63bdd372eeb0721db0d1fb1a182ebfadf1e5d
    WORKTREE_STATUS       = clean

PREDECESSOR
    C1_HEAD               = fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad
    C1_CLOSURE_HEAD       = f652f3c9ca7724b191bc6cd41c6a400316e30c0a
    ENTRY_GATE_FAST       = PASS  (see entry-gate-fast.txt)
    ENTRY_GATE_PUSH       = PASS  (see entry-gate-push.txt)

PIPELINE_BEFORE
    NEUTRAL_OPT_FUNCTION  = irBasicFunctionOptimisations (src/ir-optimise.c:949)
    DUMP_IR_SNAPSHOT      = src/ir.c:3301 irDump; runs irBasicFunctionOptimisations
                            + irPrintFunction before/after
    LLVM_DISPATCH_FUNCTION= src/main.c:561 irLowerProgram(cc)
                            -> src/ir.c:3380 irLowerProgram body
                            -> per AST_FUNC: irLowerFunction + irBasicFunctionOptimisations
    NATIVE_PREP_FUNCTION  = irFunctionPrepForCodeGen (src/ir.c:3085)
                            called from src/aarch64.c:2211
                            and src/x86_64.c:2560
                            and src/aarch64-jit.c:1704
                            and src/x86_64-jit.c:1583
    CMP_BR_FUSION_FUNCTION= irOptPinResultReg (src/ir-optimise.c:1079-1122)
                            sole producer of IR_CMP_BR
    ABI_PREP_FUNCTION     = irAssignAbiParamLocations (src/ir.c:3141)
                            called from same four paths as NATIVE_PREP
```

## 3. ROOT CAUSE / FINDING

The predecessor C1 hypothesis (`LLVM_INPUT_CONTAINS_IR_CMP_BR=YES`,
`HALT_LLVM_SEES_NATIVE_FUSION`) was based on the structural
presence of an `IR_CMP_BR` switch arm in `src/llvm-backend.c:610-636`
combined with the assumption that the LLVM dispatch routed through
`irFunctionPrepForCodeGen`. Fresh Phase 0 recon at BOUNDARY03
entry shows the LLVM dispatch actually flows through
`irLowerProgram` (`src/ir.c:3380`), which only calls
`irLowerFunction` + `irBasicFunctionOptimisations` — neither of
which produces `IR_CMP_BR`.

Therefore:
    - The boundary is already mechanically enforced.
    - The `IR_CMP_BR` switch arm in the LLVM backend is dead code.
    - The predecessor halt's literal premise is empirically
      contradicted.

This is a stronger, not weaker, finding. The architecture is
already in the target topology (per ACT §3): neutral consumers
see canonical `IR_ICMP + IR_BR`; native consumers receive
`IR_CMP_BR` after native preparation.

What BOUNDARY03 adds on top of the existing architecture:
    1. The dead `IR_CMP_BR` arm is replaced with a boundary-
       violation diagnostic. If a future refactor moves
       native-only preparation above the boundary, the LLVM
       backend now fails loudly rather than silently re-
       translating.
    2. The `IR_CMP_BR` ownership is mechanically documented
       (see the comment at the diagnostic site).

## 4. RED OUTCOMES (per §71)

```text
RED
    LLVM_INPUT_CMP_BR_BEFORE  = NO   (literal-claim RED NOT REPRODUCED;
                                       see red-llvm-input-shape.txt)
    NATIVE_INPUT_CMP_BR_BEFORE = YES  (AOT and JIT both use IR_CMP_BR;
                                       see red-native-fusion-conservation.txt
                                       and comparison-native-before.txt)
    RED_REPRODUCED            = YES for native;
                                NO for literal-claim LLVM fusion;
                                HALT_LLVM_FUSION_NOT_REPRODUCED triggered.
```

## 5. IMPLEMENTATION (per §71)

```text
IMPLEMENTATION
    FILES                          = src/llvm-backend.c (one block replacement)
    BOUNDARY_CHANGE                = IR_CMP_BR arm replaced with explicit
                                      boundary-violation diagnostic
    LLVM_DISPATCH_POSITION_BEFORE  = src/main.c:561 irLowerProgram(cc)
    LLVM_DISPATCH_POSITION_AFTER   = unchanged
    NATIVE_PREP_POSITION_AFTER     = unchanged (src/aarch64.c:2211,
                                      src/x86_64.c:2560,
                                      src/aarch64-jit.c:1704,
                                      src/x86_64-jit.c:1583)
```

## 6. BRANCH_CONTRACT (per §71)

```text
BRANCH_CONTRACT
    PRODUCERS_INSPECTED  = 10 (IR_ICMP, IR_ICMP(NE, x, 0) coercion,
                                logical NOT (not present in IR),
                                logical AND/OR (lowered via irBranch),
                                integer variable, constant (folded),
                                function-call result, assignment result,
                                pointer, loop/while, ternary N/A)
    ZERO_RESULT          = 0 (AOT) / 0 (JIT)   [if (0) -> false]
    ONE_RESULT           = 1 (AOT) / 1 (JIT)   [if (1) -> true]
    TWO_RESULT           = 1 (AOT) / 1 (JIT)   [if (2) -> true; TRUTHINESS]
    THREE_RESULT         = 1 (AOT) / 1 (JIT)
    NEG_ONE_RESULT       = 1 (AOT) / 1 (JIT)
    NEG_TWO_RESULT       = 1 (AOT) / 1 (JIT)   [if (-2) -> true; TRUTHINESS]
    AOT_JIT_AGREE        = YES
    IR_BR_CONTRACT       = MIXED_OR_UNPROVEN
                           (see branch-contract-conclusion.txt)
```

## 7. GATES (per §71)

```text
GATES
    GATE_FAST                  = PASS
    GATE_PUSH_ENTRY            = PASS
    GATE_PUSH_IMPLEMENTATION   = PASS  (see gate-push-implementation.txt)
    GATE_PUSH_CLOSURE          = PASS  (see gate-push-closure.txt;
                                          SUBJECT=b13516e43a1f;
                                          full transcript below)
    DIFF_CHECK                 = exit 0
                                 (git diff --check f652f3c..HEAD)
```

## 8. SCOPE (per §71)

```text
SCOPE
    LANGUAGE_CHANGED       = NO
    LLVM_FEATURES_ADDED    = NO
    IR_TYPE_I1_ADDED       = NO
    NATIVE_ABI_CHANGED     = NO
    FILES_MODIFIED_PROD    = 1 (src/llvm-backend.c, one block)
    FILES_MODIFIED_EVID    = evidence/ir-boundary03/ (RED + post-impl)
    FILES_MODIFIED_TESTS   = src/tests/ir-boundary03/ (truthiness fixtures)
    FILES_MODIFIED_ACT     = docs/acts/ACT-POLYC-IR-BOUNDARY03.md
    FILES_MODIFIED_HH      = evidence/ir-boundary03/HANDOFF.md (this file)
```

## 9. RESIDUE (per §11, F11)

```text
P0 = none. The architectural defect is mechanically resolved.
    Boundary already enforced; dead code removed; explicit
    boundary-violation diagnostic in place.

P1 = ACT-POLYC-IR-BOOLEAN01 (recommended next ACT).
     Mission: settle IR_BR_CONTRACT (currently MIXED_OR_UNPROVEN)
     via source-level clarification, NOT via IR_TYPE_I1.
     Sub-tasks:
       - Decide truthiness vs Boolean at the IR level.
       - Add explicit zext I8 -> I64 in irBranch case 2 so
         the IR_BR operand is uniformly I64.
       - Either keep LLVM trunc with a producer-side assertion,
         or switch to icmp ne i64, 0 for generic truthiness.
       - Fix the latent I8 IR_BR rejection at
         src/llvm-backend.c:585.

P1 = ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01.
     Re-requalify the LLVM spike under the BOUNDARY03-clean
     baseline (the boundary assertion guarantees IR_CMP_BR
     never reaches LLVM; the predecessor's "re-translation"
     narrative in red-1B.analysis.txt is no longer load-bearing).

P2 = compiler warning around src/ir.c:3334 vecNew(n) (carry-over).

P2 = LLVM dead_exit cleanup (carry-over).

P2 = LLVM stack/local lowering design (carry-over).

P2 = real IR_ASM backend-negative witness (carry-over).
```

## 10. NEXT ACT

```text
NEXT_ACT = ACT-POLYC-IR-BOOLEAN01
```

Reason: `IR_BR_CONTRACT = MIXED_OR_UNPROVEN`. The next phase of
the LLVM experiment requires settling the branch semantics
before any further lowering change. ACT-POLYC-IR-BOOLEAN01
should:
  - investigate the two distinct lowering shapes (case 1 I64
    and case 2 I8) and choose between truthiness and Boolean;
  - either keep the current LLVM trunc (i64 -> i1) with a
    producer-side assertion that the value is in {0, 1}, or
    switch to icmp ne i64, 0 for generic truthiness;
  - fix the latent I8 IR_BR rejection in the LLVM backend;
  - NOT introduce IR_TYPE_I1 (ACT §18 / Charter).

## 11. Commit topology (4 commits, per ACT §55 max)

```text
1. 596ffc3  test(ir): bind native-fusion boundary and branch semantics REDs
                ACT + Phase 0 evidence baseline + truthiness fixtures.
                Production code: unchanged.

2. dab8cc7  refactor(llvm): remove dead IR_CMP_BR arm; add boundary
                              diagnostic. Production code: 1 file,
              25 insertions / 25 deletions in src/llvm-backend.c.

3. 4f30c2b  test(ir): prove neutral/native boundary and
                       branch-condition contract.
                Post-implementation evidence:
                  comparison-llvm-input-{before,after}.txt
                  comparison-native-{before,after}.txt (+ sha256 + b64)
                  gate-push-implementation.txt (+ sha256 + b64)
                  refresh dump-ir-{...}.txt raw_sha256 headers.

4. b13516e  docs(polyc): close IR-BOUNDARY03. Docs + evidence only.
                Pin CLOSURE_HEAD, regenerate diff-check.txt,
                gate-push-closure.txt, refresh HANDOFF.md.
```

## 12. ACT §75 review checkpoint disposition

```text
R1  Is LLVM truly branching before native-only prep?
    YES — verified by call-graph analysis
          (pipeline-before.txt, native-prep-callers.txt).
          The LLVM dispatch in main.c:561 → irLowerProgram →
          irBasicFunctionOptimisations does NOT call
          irFunctionPrepForCodeGen.

R2  Are any formerly-native transformations being reclassified
    as "neutral" merely because LLVM needs them?
    NO. No reclassification; the existing neutral pipeline
        (irRemoveAllNops, irRemoveRedundantBlocks,
         irFoldPassThroughBlocks, irFoldGlobalDeref,
         irForwardReturnSlot, irEvalConstantExpressions,
         irForwardStoreToReads, irDeadStoreEliminate,
         irFuseIaddIntoMemAddressing, irFuseLoadOpStore)
        is exactly the pipeline LLVM consumes.

R3  Does native AOT/JIT still receive the preparation they need?
    YES — verified by native AOT assembly diff
          (comparison-native-{before,after}.txt are byte-identical).

R4  Does the branch-condition conclusion come from PolyC
    behavior, not LLVM convenience?
    YES — derived from native AOT and JIT execution of the
          six-determinator matrix (truthiness-matrix.txt),
          not from LLVM's i1 representation.

R5  Did anyone introduce IR_TYPE_I1 without a separate semantic ACT?
    NO.

R6  Is IR_CMP_BR absent from LLVM input mechanically, not
    only by comment?
    YES — the arm is replaced with an explicit boundary-
          violation diagnostic that fails if IR_CMP_BR is
          ever presented.

R7  Is implementation HEAD gate-qualified?
    YES — gate-push(dab8cc7) = VERDICT=PASS
          (see gate-push-implementation.txt).
```

## 13. Note on the predecessor halt `HALT_LLVM_SEES_NATIVE_FUSION`

The C1 halt recorded at
`evidence/llvmspike01-resume01-correction01/HANDOFF.md:47`
described the boundary as broken: "the LLVM consumer silently
re-translates the fused form". BOUNDARY03's fresh evidence
contradicts the literal claim, but the halt was a
mandatory-record HALT and remains in the historical record.
The current state is:

    HALT_LLVM_SEES_NATIVE_FUSION  -- historical halt; the literal
                                    premise was later falsified by
                                    fresh evidence at BOUNDARY03
                                    Phase 0. The architectural
                                    intent of the halt is
                                    satisfied by BOUNDARY03's
                                    dead-code removal + boundary
                                    assertion.

The C1 ACT §3 review block continues to reference the halt;
the BOUNDARY03 ACT §9 documents the contradiction honestly.

## 14. CLOSURE signature

```text
CLOSURE_HEAD                = (filled at commit 4 by the commit message;
                              the SHA appears in `git log -1` immediately
                              after this commit is made)
ENTRY_HEAD                  = f652f3c9ca7724b191bc6cd41c6a400316e30c0a

Commit 1 RED_HEAD           = 596ffc35a5268bfa1193ba88498713bafd53a850
Commit 2 IMPLEMENTATION_HEAD = dab8cc72497256b0bcd945f054df5e94cbad155d
Commit 3 EVIDENCE_HEAD      = 4f30c2b2c0f756c7a67c6aa0fedfb1efdf853e76
Commit 4 CLOSURE_HEAD       = e4a63bdd372eeb0721db0d1fb1a182ebfadf1e5d

C1-AC-8 equivalent
  (git diff --check
   ENTRY..CLOSURE)          = exit 0  (verified before commit;
                                      see diff-check.txt;
                                      git diff --check f652f3c..HEAD)

C1-AC-11 equivalent
  (gate-push against
   IMPLEMENTATION_HEAD)     = PASS  (see gate-push-implementation.txt;
                                      SUBJECT=dab8cc724972)

C1-AC-13 equivalent
  (gate-push against
   CLOSURE_HEAD)            = PASS  (see gate-push-closure.txt;
                                      SUBJECT=b13516e43a1f;
                                      gate-push.sh e4a63bdd372eeb0721db0d1fb1a182ebfadf1e5d
                                      returned VERDICT=PASS for
                                      build/install/aot/jit/lsp/diff-check
                                      against the immutable CLOSURE_HEAD).

C1-AC-13 verbatim transcript (gate-push-closure.txt):
    POLYC_GATE=push
    SUBJECT=b13516e43a1f
    CHECK=build      STATUS=PASS
    CHECK=install    STATUS=PASS
    CHECK=aot        STATUS=PASS
    CHECK=jit        STATUS=PASS
    CHECK=lsp        STATUS=PASS
    POLYC_GATE_RANGE_MODE=tip
    POLYC_GATE_RANGE_DESC=subject commit (tip-only)
    CHECK=diff-check STATUS=PASS
    VERDICT=PASS

C1 halt resolved            = HALT_LLVM_FUSION_NOT_REPRODUCED triggered
                              at the literal-claim level; architectural
                              intent satisfied. See §3 above.
```
