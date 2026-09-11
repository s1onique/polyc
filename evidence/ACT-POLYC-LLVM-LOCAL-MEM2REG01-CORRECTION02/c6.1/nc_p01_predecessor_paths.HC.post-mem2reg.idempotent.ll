; ModuleID = '/tmp/c6.1/nc_p01_predecessor_paths.post.ll'
source_filename = "polyc_module"

define i64 @ProbePath(i64 %0, i64 %1) {
bb1:
  %2 = icmp sgt i64 %0, 0
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %3 = add i64 %1, 1
  br label %bb4

bb4:                                              ; preds = %bb3, %bb1
  %polyc.optionw.slot.6.0 = phi i64 [ %3, %bb3 ], [ 10, %bb1 ]
  %4 = icmp slt i64 %0, 0
  br i1 %4, label %bb5, label %bb6

bb5:                                              ; preds = %bb4
  %5 = sub i64 0, %1
  br label %bb6

bb6:                                              ; preds = %bb5, %bb4
  %polyc.optionw.slot.6.1 = phi i64 [ %5, %bb5 ], [ %polyc.optionw.slot.6.0, %bb4 ]
  ret i64 %polyc.optionw.slot.6.1

dead_exit:                                        ; No predecessors!
  unreachable
}
