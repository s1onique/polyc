; ModuleID = '/tmp/c6.2/red_local_multi_def.post.ll'
source_filename = "polyc_module"

define i64 @MultiDef(i64 %0, i64 %1, i64 %2) {
bb1:
  %3 = icmp sgt i64 %2, 0
  br i1 %3, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  br label %bb4

bb4:                                              ; preds = %bb3, %bb1
  %polyc.optionw.slot.9.0 = phi i64 [ %0, %bb3 ], [ %1, %bb1 ]
  %4 = add i64 %0, %polyc.optionw.slot.9.0
  ret i64 %4

dead_exit:                                        ; No predecessors!
  unreachable
}
