; ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q3 placement adversarial probe
; ------------------------------------------------------------
; Same CFG as single_cond_probe, but the alloca is placed in
; bb3 (a conditional predecessor, NOT the function entry).
;
; EXPECTED: opt -passes=mem2reg either fails to eliminate
; the alloca, or (in modern LLVM) emits it as-is. The probe
; characterises what LLVM 22.1.8 actually does in this case.

define i64 @Probe(i64 %p1, ptr %p3) {
bb1:
  %l6 = load i64, ptr %p3
  %t8 = icmp sge i64 %l6, 10
  br i1 %t8, label %bb3, label %bb4

bb3:
  %slot = alloca i64
  store i64 %p1, ptr %slot
  %slot.bb3.next = add i64 %p1, %l6
  store i64 %slot.bb3.next, ptr %slot
  br label %bb4

bb4:
  br label %bb2

bb2:
  %t10 = load i64, ptr %slot
  ret i64 %t10
}
