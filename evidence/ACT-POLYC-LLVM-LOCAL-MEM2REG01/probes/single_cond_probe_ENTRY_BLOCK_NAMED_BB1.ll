; ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q3 placement POSITIVE CONTROL
; ------------------------------------------------------------
; Same CFG as single_cond_probe, but the function's first
; basic block is named "bb1" instead of "entry".
;
; This is NOT a placement negative probe -- there is no
; preceding basic block in the function, so bb1 IS the
; function entry block. LLVM entry-ness is STRUCTURAL, not
; driven by the block name.
;
; Originally misnamed "single_cond_probe_NOT_IN_ENTRY" in
; C1; reviewer (post-C1 HOLD) correctly observed that bb1
; with no predecessor is the entry block. Renamed in C2
; evidence commit.
;
; EXPECTED: opt -passes=mem2reg succeeds and produces the
; same PHI at bb4 that single_cond_probe produces, because
; the alloca is structurally in the entry block.

define i64 @Probe(i64 %p1, ptr %p3) {
bb1:
  %slot = alloca i64
  store i64 %p1, ptr %slot
  %l6 = load i64, ptr %p3
  %t8 = icmp sge i64 %l6, 10
  br i1 %t8, label %bb3, label %bb4

bb3:
  %slot.bb3.in = load i64, ptr %slot
  %slot.bb3.next = add i64 %slot.bb3.in, %l6
  store i64 %slot.bb3.next, ptr %slot
  br label %bb4

bb4:
  br label %bb2

bb2:
  %t10 = load i64, ptr %slot
  ret i64 %t10
}
