.section __TEXT,__cstring,cstring_literals
.L0:
	.asciz "./"
.globl argc
	.comm argc, 8, 8
.globl argv
	.comm argv, 8, 8
.text
	.p2align 2
	.globl _TestEq
_TestEq:
	stp x29, x30, [sp, #-16]!
	mov x29, sp
	sub sp, sp, #16
	sturb w0, [x29, #-8]
	ldurb w0, [x29, #-8]
	uxtb    w0, w0
	cmp x0, #2
	b.ne    .LIRBB0_4
	mov x0, #1
	sturb w0, [x29, #-16]
	b   .LIRBB0_2
.LIRBB0_4:
	mov x0, xzr
	sturb w0, [x29, #-16]
.LIRBB0_2:
	ldurb w0, [x29, #-16]
	add sp, sp, #16
	ldp x29, x30, [sp], #16
	ret
.ident      "hcc: apple aarch64-apple-darwin v0.0.15-beta hash: cbf726ed939956ebc79790371a9d372942b10b05"
