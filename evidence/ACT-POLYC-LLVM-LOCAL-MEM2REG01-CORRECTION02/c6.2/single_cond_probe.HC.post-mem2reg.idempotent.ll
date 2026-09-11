; ModuleID = '/tmp/c6.2/single_cond_probe.post.ll'
source_filename = "polyc_module"

define i64 @Probe(i64 %0, ptr %1) {
bb1:
  %ld_deref = load i64, ptr %1, align 4
  %2 = icmp sge i64 %ld_deref, 10
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %3 = add i64 %0, %ld_deref
  br label %bb4

bb4:                                              ; preds = %bb3, %bb1
  %polyc.optionw.slot.2.0 = phi i64 [ %3, %bb3 ], [ %0, %bb1 ]
  ret i64 %polyc.optionw.slot.2.0

dead_exit:                                        ; No predecessors!
  unreachable
}
