; ModuleID = 'evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/probes/single_cond_probe_NOT_IN_ENTRY.ll'
source_filename = "evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/probes/single_cond_probe_NOT_IN_ENTRY.ll"

define i64 @Probe(i64 %p1, ptr %p3) {
bb1:
  %l6 = load i64, ptr %p3, align 4
  %t8 = icmp sge i64 %l6, 10
  br i1 %t8, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %slot.bb3.next = add i64 %p1, %l6
  br label %bb4

bb4:                                              ; preds = %bb3, %bb1
  %slot.0 = phi i64 [ %slot.bb3.next, %bb3 ], [ %p1, %bb1 ]
  br label %bb2

bb2:                                              ; preds = %bb4
  ret i64 %slot.0
}
