# Backend emission analysis for the I8 bypass class

Witness used: witness-02-u8-identity-bypass.HC
    U8 Identity(U8 x) { return x; }
    U8 TestId(U8 x) {
        if (Identity(x)) return 1;
        return 0;
    }

`--dump-ir` shows the IR_BR operand is `%t9 i8 tmp` (raw call
result) with NO preceding cmp_ne. The bypass is real.

## Per-target emitted assembly (L1/L2/L3 split)

The runtime correctness of the bypass class is REAL but depends
on a three-layer interaction between IR_BR emission (L1) and
the callee's IR_RET lowering (L2). The CORRECTION02 ACT conflated
L1 with L2; this CORRECTION03 file fixes that.

Emitted-assembly files for verbatim inspection:
    evidence/ir-boundary03-correction03/witness-02-emitted/
        witness-02-x86_64-apple-darwin.s
        witness-02-aarch64-apple-darwin.s

## x86_64 AOT — _Identity body (L2 site)

Source: witness-02-x86_64-apple-darwin.s

    _Identity:                       ; callee
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $16, %rsp
        movb    %dil, -8(%rbp)       ; store i8 param
        movzbq  -8(%rbp), %rax       ; L2: load with zero-extension
        movzbq  %al, %rax            ; L2: explicit zero-extension
        leaveq
        retq                         ; %rax holds zero-extended i8

The IR-level `ret` in `_Identity` is `ret %t4 i64 tmp` because the
IR widens the narrow type on store. The backend lowers
`ret i64` with a narrow source by emitting `movzbq %al, %rax`.
This is the L2 zero-extension, performed by the callee.

## x86_64 AOT — _TestId body (L1 site, IR_BR)

    _TestId:                         ; caller
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $16, %rsp
        movb    %dil, -8(%rbp)
        movzbq  -8(%rbp), %rax       ; load param with zext
        movzbq  %al, %rax            ; explicit zext
        movq    %rax, %rdi
        callq   _Identity            ; %rax = result
        testq   %rax, %rax           ; L1: IR_BR emission (no zext)
        jz      .LIRBB1_6
        ...

IR_BR emits `testq %rax, %rax; jz` (L1). It does NOT emit a
movzbq. The movzbq was already done in the callee's IR_RET
epilogue (L2). When control returns to the caller, %rax holds
the zero-extended value, so `testq %rax, %rax` is correct.

L3 = L1 + L2 by composition: caller tests a register whose value
is already zero-extended by the callee.

Source reference: src/x86_64.c:1883-1908 (IR_BR handler emits
`x86_64LoadFirstSrc + x86_64_enc_test_reg_reg(enc, R_RAX, R_RAX)`).
The CORRECTION02 analysis was correct that the load helper
performs zext for stack-slot loads (src/x86_64.c:190-197); that
is the parameter-arrival zext. The IR_BR emission itself is
just `testq`.

## x86_64 JIT (src/x86_64-jit.c:1229-1257)

    jitLoadFirstSrc(ctx, instr->dst)  ; L1 path
        -> per ctx->fn->ra, IR_TYPE_I8 -> ldrb + uxtb
    x86_64_enc_test_reg_reg(enc, R_RAX, R_RAX)   ; L1: testq
    jitEmitJccLocal(... X86_CC_E ...)

The JIT IR_BR handler follows the same L1/L2 split as the AOT
handler. The IR_BR emit itself is `x86_64_enc_test_reg_reg`.
The zext comes from `jitLoadFirstSrc` which loads from a stack
slot (regalloc-promoted), or from the callee's IR_RET lowering.
This JIT path is NOT exercised on this host (aarch64-only JIT),
but the source structure is symmetric.

## aarch64 AOT — _Identity body (L2 site)

    _Identity:
        stp x29, x30, [sp, #-16]!
        mov x29, sp
        sub sp, sp, #16
        sturb   w0, [x29, #-8]
        ldurb   w0, [x29, #-8]
        uxtb    w0, w0               ; L2: zero-extension
        ret

## aarch64 AOT — _TestId body (L1 site)

    _TestId:
        stp x29, x30, [sp, #-16]!
        mov x29, sp
        sub sp, sp, #16
        sturb   w0, [x29, #-8]
        ldurb   w0, [x29, #-8]
        uxtb    w0, w0
        bl  _Identity
        cmp x0, #0                  ; L1: IR_BR emission (no uxtb)
        b.eq    .LIRBB1_6
        ...

Same L1/L2 split: `cmp x0, #0` is the IR_BR emit (L1); the uxtb
is in the callee's IR_RET epilogue (L2). Source: src/aarch64.c:
1635-1670.

## aarch64 JIT (src/aarch64-jit.c:1466-1494)

    jitLoadFirstSrc(ctx, instr->dst)
        -> ldrb + uxtb
    aarch64_enc_cmp_imm(enc, 1, A_X0, 0)   ; L1: cmp
    jitEmitBcondLocal(... A_EQ ...)

## LLVM backend (src/llvm-backend.c:583-609 IR_BR handler)

    if (!ins->dst || ins->dst->type != IR_TYPE_I64) {
        fprintf(stderr, "IR_BR condition must be i64...");
        exit(1);
    }

The LLVM backend REJECTS the bypass class at line 585 with
LLVM_BACKEND_UNSUPPORTED_IR. This is a clean refusal, not a
silent fallback. In the LLVM backend's currently-supported
subset (IR_TYPE_I64 only; llTypeSupported at src/llvm-backend.c:
327-329), the bypass class cannot arise.

If a future change broadens the LLVM backend to accept
IR_TYPE_I8 IR_BR operands, the existing trunc path at line 594
would silently produce wrong code for the bypass class (trunc
255 i8 -> 1 i1 == 1, but the IR's `br %t9 i8` semantics require
`t9 != 0` interpretation). This is an open residue item for
ACT-POLYC-IR-BRANCH-CONDITION01.

## Runtime witnesses (CORRECTION02 evidence, unchanged)

    evidence/ir-boundary03-correction02/runtime-correctness-u8.rc:
        u8 exit=23  (1+2+4+0+16, correct truthiness)
    evidence/ir-boundary03-correction02/runtime-correctness-i8u8-bypass.rc:
        i8u8 exit=55  (1+2+4+16+32, correct truthiness)

The non-{0,1} values 2, 16, 32 exercise the truthiness contract
for arbitrary non-zero values. Runtime correctness is proven.

## Summary: L1/L2/L3 (CORRECTION03 correction)

    L1:  IR_BR emission performs an integer test on the operand
         register (testq/cmp) without zero-extension.
    L2:  For the bypass class (IR_BR i8 from IR_CALL), the
         callee's IR_RET lowering performs zero-extension
         because the IR-level ret is i64 (narrow widened on
         store/parameter-arrival).
    L3:  L1 + L2 compose: the IR_BR tests a register whose value
         is already zero-extended by L2, so the runtime
         truthiness semantics is correct.

The CORRECTION02 sentence "all four native backends zero-extend
the operand" was an overclaim because it attributed L2 (callee
zero-extension) to the IR_BR emission (L1). The corrected model
is L1/L2/L3 as above.
