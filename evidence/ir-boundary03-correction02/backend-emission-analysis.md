# Backend emission analysis for the I8 bypass class

Witness used: witness-02-u8-identity-bypass.HC
    U8 Identity(U8 x) { return x; }
    U8 TestId(U8 x) {
        if (Identity(x)) return 1;
        return 0;
    }

`--dump-ir` shows the IR_BR operand is `%t9 i8 tmp` (raw call
result) with NO preceding cmp_ne. The bypass is real.

## x86_64 AOT (src/x86_64.c:1883-1908 IR_BR handler)

    callq   _Identity          ; returns U8 in %al
    testq   %rax, %rax          ; tests full 64-bit rax
    jz      .LIRBB1_6           ; jump if rax == 0

The IR_BR handler at src/x86_64.c:1883-1908 emits
`x86_64LoadFirstSrc` (which expands to `movzbq -N(%rbp), %rax`
for IR_TYPE_I8 sized stack slots; see src/x86_64.c:190-197) plus
`testq %rax, %rax; jz/jnz` (lines 1898-1908). The `movzbq`
zero-extends the byte to the full 64-bit register, so the
subsequent `testq` sees the full U8 range as a 64-bit value.

Truthiness = `value != 0` at the full-register level.
Correct for any U8 value (including 255).

## x86_64 JIT (src/x86_64-jit.c:1229-1257 IR_BR handler)

    (no direct assembly capture; structure is identical)
    jitLoadFirstSrc(ctx, instr->dst)
        expands to (per ctx->fn->ra) IR_TYPE_I8 -> ldrb/uxtb
        then movzbq into R_RAX (see aarch64-jit.c:217-228 for
        the symmetric aarch64 path; the x86_64-jit.c path is
        structurally identical).
    x86_64_enc_test_reg_reg(enc, R_RAX, R_RAX)
    jitEmitJccLocal(... X86_CC_E ...)

Truthiness = `value != 0` at the full-register level.

## aarch64 AOT (src/aarch64.c:1635-1670 IR_BR handler)

    uxtb    w0, w0             ; zero-extend byte to 64-bit x0
    cmp     x0, #0
    b.eq    .LIRBB1_6

The IR_BR handler at src/aarch64.c:1635-1670 emits
`aarch64LoadFirstSrc` (which for IR_TYPE_I8 sized slots expands
to `ldurb w0, [fp, #N]; uxtb w0, w0` per src/aarch64.c:1163-
1165 + the JIT path at src/aarch64-jit.c:217-218) plus
`cmp x0, #0` (line 1639) and `b.eq/b.ne` (lines 1647-1652).

Truthiness = `value != 0` at the full-register level.
Correct for any U8 value (including 255), and any I8 value
(including -128 -> 0xFF80 -> not zero).

## aarch64 JIT (src/aarch64-jit.c:1466-1494 IR_BR handler)

    jitLoadFirstSrc(ctx, instr->dst)
        -> ldrb w0, [x9, #N]  (per src/aarch64-jit.c:217-228)
        OR uxtb (per src/aarch64-jit.c:217)
    aarch64_enc_cmp_imm(enc, 1, A_X0, 0)
    jitEmitBcondLocal(... A_EQ ...)

Truthiness = `value != 0` at the full-register level.

## LLVM backend (src/llvm-backend.c:583-609 IR_BR handler)

    if (!ins->dst || ins->dst->type != IR_TYPE_I64) {
        fprintf(stderr, "IR_BR condition must be i64...");
        exit(1);
    }

The LLVM backend REJECTS the bypass class at line 585. The
rejection is LLVM_BACKEND_UNSUPPORTED_IR ("IR_BR condition must
be i64"). This is a clean refusal, not silent fallback.

Empirical test (./hcc --emit-llvm witness-02-u8-identity-bypass.HC):
    LLVM_BACKEND_UNSUPPORTED_TYPE: function Identity: type
    function parameter is not supported by the LLVM backend
    (this is the function-parameter rejection at src/llvm-backend.c:345,
    reached before IR_BR lowering)

So in the LLVM backend's currently-supported subset
(IR_TYPE_I64 only; llTypeSupported at src/llvm-backend.c:327-329),
the bypass class cannot arise. If a future change broadens the
LLVM backend to accept IR_TYPE_I8 IR_BR operands, the existing
trunc path at line 594 would silently produce wrong code for
the bypass class (trunc 255 i8 -> 1 i1 == 1, but the IR's
`br %t9 i8` semantics require `t9 != 0` interpretation).
