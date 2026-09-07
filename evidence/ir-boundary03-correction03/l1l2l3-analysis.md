ACT-POLYC-IR-BOUNDARY03-CORRECTION03 / L1/L2/L3 analysis
========================================================

Context: the CORRECTION02 backend-emission-analysis.md stated
"all 4 native backends zero-extend the operand and test the full
register". The reviewer correctly noted this overclaims the
mechanism: the zero-extension is NOT emitted by IR_BR; it is
emitted by the callee's IR_RET epilogue. This file is the
CORRECTION03 correction.

Three-layer model
-----------------

L1: IR_BR emission
    Source: src/x86_64.c:1883..1908 (x86_64 AOT)
            src/aarch64.c:1635..1670 (aarch64 AOT)
            src/x86_64-jit.c:1229..1257 (x86_64 JIT — note:
               not exercised on this host; script llvm-spike-test
               does not include JIT-targeted x86_64)
            src/aarch64-jit.c:1466..1494 (aarch64 JIT)
    Behavior: emits an integer test on the operand register.
        x86_64:    testq %rax, %rax
        aarch64:   cmp x0, #0
        x86_64:    testq %rax, %rax       (matches x86_64 AOT)
        aarch64:   cmp x0, #0              (matches aarch64 AOT)
    IR_BR itself does NOT zero-extend. The operand value
    (whatever bit pattern) is tested as-is in the full register.

L2: IR_RET lowering for narrow-typed function callee
    Witness: witness-02-u8-identity-bypass.HC
    Captured emitted assembly (x86_64-apple-darwin):
        _Identity:                         (callee)
            movb    %dil, -8(%rbp)         ; store i8 param
            movzbq  -8(%rbp), %rax         ; load i8 with zext (L2 site 1)
            movzbq  %al, %rax              ; explicit zext (L2 site 2)
            leaveq
            retq                           ; %rax holds zero-extended i8
    aarch64-apple-darwin:
        _Identity:
            sturb   w0, [x29, #-8]
            ldurb   w0, [x29, #-8]
            uxtb    w0, w0                 ; L2 site
            ret                            ; w0/x0 holds zero-extended i8
    The IR-level `ret` in `Identity` is `ret %t4 i64 tmp` (because
    the IR-type of the narrow value after store is i64 per the
    parameter-arrival widening convention). The backend lowers
    `ret i64` of a narrow source by emitting `movzbq %al, %rax`
    (x86_64) or `uxtb w0, w0` (aarch64) to satisfy the call
    ABI: the return register must be fully defined, and the
    backend chose zero-extension as the conservative choice.

L3: composition
    Caller (_TestId) does IR_CALL `call %t9 i8 tmp, Identity`,
    then IR_BR `br %t9 i8 tmp, bb5, bb6`. IR_BR sees an i8
    operand (L1) but the runtime value in %rax is the
    zero-extended return from _Identity (L2). The IR_BR's
    `testq %rax, %rax` therefore tests a zero-extended value,
    and the zero/nonzero semantics is correct.

What this ACT downgrades
------------------------

CORRECTION02's claim that IR_BR itself performs zero-extension
was an overclaim. The actual invariant is L2 (the callee's
IR_RET lowering) that makes L1's plain integer test correct.
The two are coupled by the call-return convention, not by
the IR_BR emission itself.

What remains PROVEN
-------------------

Runtime correctness of the bypass class (witness-02):
    u8 RC=23 (1+2+4+0+16): pass
    i8u8 RC=55 (1+2+4+16+32): pass
The runtime tests have non-zero exit codes that exercise
non-{0,1} values (2, 16, 32) and confirm truthiness of
arbitrary non-zero values works at runtime on the existing
backends.

NEXT_ACT impact
---------------

ACT-POLYC-IR-BRANCH-CONDITION01 inherits the L1/L2/L3
distinction as additional input:
    option (i) uniform I8/I64 representation: touches L1 AND L2
    option (ii) tighter cmp_ne invariant in src/ir.c:107..122:
                only touches L1 (rejects i8 conditions); L2
                remains valid for non-IR_BR consumers.
The choice is left to that ACT.

Evidence files
--------------

  witness-02-x86_64-apple-darwin.s    (callee + caller bodies)
  witness-02-aarch64-apple-darwin.s   (callee + caller bodies)
  gate-push-final/log.txt             (gate at CORRECTION02 FINAL_HEAD)
  closure-facts.txt                   (identity binding, cap breach)
