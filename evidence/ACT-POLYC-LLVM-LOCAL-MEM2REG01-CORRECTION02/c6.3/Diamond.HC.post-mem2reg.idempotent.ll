; ModuleID = '/tmp/c6.3/Diamond.post.ll'
source_filename = "polyc_module"

define i64 @Diamond(i64 %0, i64 %1) {
bb1:
  %2 = icmp ne i64 %0, 0
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %3 = add i64 %1, 1
  br label %bb5

bb4:                                              ; preds = %bb1
  %4 = sub i64 %1, 1
  br label %bb5

bb5:                                              ; preds = %bb4, %bb3
  %polyc.optionw.slot.6.0 = phi i64 [ %3, %bb3 ], [ %4, %bb4 ]
  ret i64 %polyc.optionw.slot.6.0

dead_exit:                                        ; No predecessors!
  unreachable
}
