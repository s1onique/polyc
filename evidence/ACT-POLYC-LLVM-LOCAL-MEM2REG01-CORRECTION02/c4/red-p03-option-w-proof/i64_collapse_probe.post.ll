; ModuleID = '/tmp/c4.bc'
source_filename = "i64_collapse_probe.pre.ll"

define i64 @Probe(i64 %p1, ptr %p3) {
bb_entry:
  %x = load i64, ptr %p3, align 4
  %cond_ge = icmp sge i64 %x, 10
  br i1 %cond_ge, label %bb3, label %bb4

bb3:                                              ; preds = %bb_entry
  %cond_le = icmp sle i64 %x, 99
  br i1 %cond_le, label %bb5, label %bb4

bb5:                                              ; preds = %bb3
  %add_rhs = add i64 %p1, %x
  br label %bb4

bb4:                                              ; preds = %bb5, %bb3, %bb_entry
  %slot.0 = phi i64 [ %add_rhs, %bb5 ], [ %p1, %bb3 ], [ %p1, %bb_entry ]
  br label %bb_exit

bb_exit:                                          ; preds = %bb4
  ret i64 %slot.0
}
