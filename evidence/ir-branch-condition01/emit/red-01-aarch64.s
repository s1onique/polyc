.section __TEXT,__cstring,cstring_literals
.L0:
	.asciz "./"
.globl argc
	.comm argc, 8, 8
.globl argv
	.comm argv, 8, 8
.text
	.p2align 2
	.globl _Identity
_Identity:
	stp x29, x30, [sp, #-16]!
	mov x29, sp
	sub sp, sp, #16
	sturb w0, [x29, #-8]
	ldurb w0, [x29, #-8]
	uxtb    w0, w0
	add sp, sp, #16
	ldp x29, x30, [sp], #16
	ret
.text
	.p2align 2
	.globl _TestId
_TestId:
	stp x29, x30, [sp, #-16]!
	mov x29, sp
	sub sp, sp, #16
	sturb w0, [x29, #-8]
	ldurb w0, [x29, #-8]
	uxtb    w0, w0
	bl  _Identity
	cmp x0, #0
	b.eq    .LIRBB1_6
	mov x0, #1
	sturb w0, [x29, #-16]
	b   .LIRBB1_4
.LIRBB1_6:
	mov x0, xzr
	sturb w0, [x29, #-16]
.LIRBB1_4:
	ldurb w0, [x29, #-16]
	add sp, sp, #16
	ldp x29, x30, [sp], #16
	ret
.ident      "hcc: apple aarch64-apple-darwin v0.0.15-beta hash: 075e9f66eb7389f260a1a9a9a53b81ec71e464b1"
