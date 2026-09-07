# ACT-POLYC-IR-BOUNDARY03-CORRECTION02 HANDOFF

## VERDICT

    HALT_IR_BR_I8_ORIGIN_UNPROVEN  ->  REVISED via real witnesses.

    The CORRECTION01 claim IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1
    was an over-proven inference. Real witnesses (witness-02-
    u8-identity-bypass.HC, witness-04-u8-passthrough-bypass.HC,
    witness-05-i8-identity-bypass.HC) show that IR_BR operands
    can carry values in [0, 255] (U8) or [-128, 127] (I8) when
    the source is a function-call return.

    The ACTUAL neutral-IR contract is:

        IR_BR_VALUE_CONTRACT =
            I8_OR_I64_ZERO_NONZERO_TRUTHINESS

    The runtime is correct under this contract because all 4
    native backends (x86_64 AOT, x86_64 JIT, aarch64 AOT,
    aarch64 JIT) zero-extend the operand and test the full
    register against zero. The LLVM backend rejects the bypass
    class entirely (LLVM_BACKEND_UNSUPPORTED_IR at
    src/llvm-backend.c:585).

    The CORRECTION01 verdict for the IR_BR_VALUE_CONTRACT
    claim is downgraded from PROVEN to OVERPROVEN; the rest of
    the CORRECTION01 ACT stands (FACTORY + predecessor HALT
    correction + 3-axis decomposition are sound).

## IDENTITY

    ENTRY_HEAD             = 075e9f66eb7389f260a1a9a9a53b81ec71e464b1  (CORRECTION01 FINAL_HEAD)
    ENTRY_BRANCH           = main
    CORRECTION02_RED_HEAD  = <pinned at commit 1>
    CORRECTION02_CLOSURE_HEAD = 0971c4d678eeb7884f5a59337bce9d9d5bf9a40a
    FINAL_HEAD             = 0971c4d678eeb7884f5a59337bce9d9d5bf9a40a
    BRANCH                 = main
    WORKTREE               = clean

## ROOT CAUSE / FINDING

    The CORRECTION01 reviewer identified a real P0 proof hole:
    the IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1 claim was based
    on the inference "cond->type == IR_TYPE_I8 implies cond
    originated from IR_ICMP". That inference is not supported
    by src/ir.c:107-123. The actual code at src/ir.c:107 says
    `if (cond->type != IR_TYPE_I8)`, meaning an already-I8 cond
    BYPASSES normalization entirely.

    The only thing provable from the source alone is:
    irBranch accepts cond in three shapes (I8 passthrough,
    immediate-ICMP result, else insert cmp_ne). The first
    shape does NOT have a value-domain guarantee.

    Real witnesses (10 in this directory) demonstrate:
        * The bypass is reachable from real source.
        * The IR contains `br %t9 i8 tmp, ...` with raw i8
          values from function calls.
        * The runtime is still correct (full-register test).

## RED

    Principal RED: real witnesses with `if (Identity(x))` where
    Identity returns U8/I8 produce raw `br %t i8` IR with no
    preceding cmp_ne (see dump-ir-witness-02-u8-identity-bypass.txt
    lines containing `br %t9 i8 tmp, bb5, bb6`).

    Empirical confirmation:
        witness 02: call Identity -> br %t9 i8 (no cmp_ne)
        witness 04: call Passthru -> br %t9 i8 (no cmp_ne)
        witness 05: call NegIdentity -> br %t9 i8 (no cmp_ne)
        witness 01: local ref -> cmp_ne inserted (normalized)
        witness 03: x == 2 -> cmp_eq inserted (normalized)
        witness 06: I16/I32 -> cmp_ne inserted (normalized)
        witness 07: x == 0 -> cmp_eq inserted (normalized)
        witness 08: local literal -> cmp_ne inserted (normalized)
        witness 09: arithmetic -> cmp_ne inserted (normalized)
        witness 10: subtraction -> cmp_ne inserted (normalized)

    Runtime witnesses:
        runtime-correctness-u8.HC: exit 23 = 1+2+4+0+16
            (Identity(2,3,255,0,1) interpreted correctly)
        runtime-correctness-i8u8-bypass.HC: exit 55 = 1+2+4+16+32
            (Identity(2,127,-1,0,2u,255u,0u) interpreted correctly)

## IMPLEMENTATION

    None. This ACT is docs/test-recon only (F7/F15). Production
    code (src/) is unchanged since dab8cc7.

    The implementation is purely:
        (1) ACT-POLYC-IR-BOUNDARY03-CORRECTION02.md (new)
        (2) HANDOFF-CORRECTION02.md (this file, new)
        (3) branch-contract-conclusion.txt (replaces the
            CORRECTION01 IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1
            claim with IR_BR_VALUE_CONTRACT =
            I8_OR_I64_ZERO_NONZERO_TRUTHINESS, evidence-based)
        (4) 10 witness source files + dump-ir transcripts
        (5) runtime correctness witnesses + captured outputs
        (6) backend-emission-analysis.md (per-backend analysis)
        (7) entry-gate / gate-push-closure refresh

## GATES

    gate-fast                          PASS
    gate-push(ENTRY_HEAD)              PASS  (CORRECTION01 commit 1)
    gate-push(CLOSURE_HEAD)            PASS  (SUBJECT == CLOSURE_HEAD)
    gate-push(FINAL_HEAD)              PASS  (informationnal)
    llvm-spike-test                    PASS 12/0
    git diff --check ENTRY..HEAD       exit 0
    worktree                           clean
    src/ diff dab8cc7..HEAD            empty

## SCOPE

    In scope:
        * ACT, HANDOFF, branch-contract-conclusion (this dir)
        * Witness source + --dump-ir transcripts (this dir)
        * Runtime correctness witnesses + captured outputs (this dir)
        * Backend-emission analysis (this dir)
        * Entry/gate/closure evidence (this dir)

    Out of scope (NOT touched):
        * src/ir.c (no irBranch modification)
        * src/x86_64.c (no IR_BR handler modification)
        * src/x86_64-jit.c
        * src/aarch64.c
        * src/aarch64-jit.c
        * src/llvm-backend.c (no contract broadening)
        * dab8cc7 (still unauthorized-but-reviewed residue)

## RESIDUE

    P0 (none blocking)

    P1 = ACT-POLYC-IR-BRANCH-CONDITION01 (now narrowed to a
         choice between IR_BR_TYPE_CONTRACT uniform I8/I64 vs.
         IR_BR_VALUE_CONTRACT tightening to require cmp_ne
         even for already-I8 conditions; see branch-contract-
         conclusion.txt NEXT-ACT RECOMMENDATION)
    P1 = ACT-POLYC-IR-BOUNDARY03-CORRECTION01-DEAD-ARM-LEGITIMIZE01
         (formally authorise or revert dab8cc7; carry-over from
         CORRECTION01)
    P1 = CORRECTION01 IR_BR_VALUE_CONTRACT = BOOLEAN_0_OR_1
         claim downgraded (this ACT's main finding)

    P2 = src/ir.c:3334 vecNew(n) warning (carry-over)
    P2 = LLVM dead_exit cleanup (carry-over)
    P2 = LLVM stack/local lowering design (carry-over)
    P2 = real IR_ASM backend-negative witness (carry-over)

## NEXT ACT

    ACT-POLYC-IR-BRANCH-CONDITION01 with the choice:
        (i)  uniform representation (always i8 OR always i64
             IR_BR operand), or
        (ii) tighter invariant (always emit cmp_ne before br
             regardless of cond type).

    The witnesses show the bypass class is RUNTIME-CORRECT for
    the existing native backends, so this is a representation
    / future-LVM-portability decision, not a user-visible defect.

    The CORRECTION02 ACT itself does NOT pick between (i) and
    (ii); that is BRANCH-CONDITION01's bounded scope.

    NEXT_ACT = ACT-POLYC-IR-BRANCH-CONDITION01
