; ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q4 architectural probe
; --------------------------------------------------------
; Hand-written LLVM IR equivalent of
;     src/tests/llvm-byte-memory01/single_cond_probe.HC
; after the irForwardReturnSlot guard (the multi-pred case
; is NOT collapsed; the surviving IR is:
;     alloca + store + load + ret  on the rejoin block).
;
; This file is recon-only evidence (F7). It is NOT production
; code; it is the literal LLVM memory-form equivalent that a
; future CORRECTION01 IMPL would emit.
;
; The original PolyC IR (from --dump-ir at HEAD):
;
;     bb1: store %l2 i64, %p1 i64 param
;          alloca %t5 i64, 8
;          load %l6 i64, %p3 ptr param
;          cmp_ge %t8 i64, %l6, 10
;          br %t8, bb3, bb4
;     bb3: iadd %l2, %l2, %l6
;          jmp bb4
;     bb4: store %t5, %l2        ; <-- multi-predecessor store
;          jmp bb2
;     bb2: load %t10, %t5
;          ret %t10
;
; The candidate slot is %t5 (an i64). It is written in two
; distinct predecessors:
;   - bb1 writes %p1 directly into %slot, then falls through
;     to bb4;
;   - bb3 reads %slot, adds %l6, writes back, then jumps to
;     bb4.
; bb4 is the natural merge point (predecessors: bb1 and bb3).
; On entry to bb4, %slot has two distinct reaching values;
; mem2reg must construct SSA merge at bb4.
;
; Direct loads/stores only; no volatile; no atomic;
; single-slot scalar; entry-block alloca; not captured.

define i64 @Probe(i64 %p1, ptr %p3) {
entry:
  %slot = alloca i64
  ; bb1
  store i64 %p1, ptr %slot        ; initial bind
  %l6 = load i64, ptr %p3
  %t8 = icmp sge i64 %l6, 10
  br i1 %t8, label %bb3, label %bb4

bb3:
  %slot.bb3.in = load i64, ptr %slot  ; read-then-modify
  %slot.bb3.next = add i64 %slot.bb3.in, %l6
  store i64 %slot.bb3.next, ptr %slot
  br label %bb4

bb4:
  ; bb4 is the merge point: predecessors = {bb1, bb3}
  ; No additional store here -- let mem2reg see the merge.
  br label %bb2

bb2:
  %t10 = load i64, ptr %slot
  ret i64 %t10
}
