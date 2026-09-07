sign_bit:
	.quad 0x8000000000000000
one_dbl:
	.double 1.0
.L0:
	.asciz "./"
.globl argc
	.comm argc, 8, 8
.globl argv
	.comm argv, 8, 8
	.text
	.p2align 4
	.globl _Identity
_Identity:
	pushq   %rbp
	movq    %rsp, %rbp
	subq    $16, %rsp
	movb    %dil, -8(%rbp)
	movzbq  -8(%rbp), %rax
	movzbq  %al, %rax
	leaveq
	retq
.text
	.p2align 4
	.globl _TestId
_TestId:
	pushq   %rbp
	movq    %rsp, %rbp
	subq    $16, %rsp
	movb    %dil, -8(%rbp)
	movzbq  -8(%rbp), %rax
	movzbq  %al, %rax
	movq    %rax, %rdi
	callq   _Identity
	testq   %rax, %rax
	jz      .LIRBB1_6
	movq    $1, %rax
	movq    %rax, -16(%rbp)
	jmp     .LIRBB1_4
.LIRBB1_6:
	xorl    %eax, %eax
	movq    %rax, -16(%rbp)
.LIRBB1_4:
	movzbq  -16(%rbp), %rax
	leaveq
	retq
.ident      "hcc: apple x86_64-apple-darwin v0.0.15-beta hash: 075e9f66eb7389f260a1a9a9a53b81ec71e464b1"
