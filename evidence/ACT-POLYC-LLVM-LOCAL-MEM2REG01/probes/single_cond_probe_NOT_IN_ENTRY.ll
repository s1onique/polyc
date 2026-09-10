; ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q3 placement negative-control probe
; ------------------------------------------------------------
; Same CFG as single_cond_probe, but the alloca is placed in
; bb1 (NOT in the entry block). This is what the current
; spike would emit if it were to call LLVMBuildAlloca
; literally without first establishing the entry-block
; insertion point.
;
; EXPECTED: opt -passes=mem2reg either fails to eliminate
; the alloca (because mem2reg only operates on entry-block
; allocas) or emits a warning to that effect.

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
