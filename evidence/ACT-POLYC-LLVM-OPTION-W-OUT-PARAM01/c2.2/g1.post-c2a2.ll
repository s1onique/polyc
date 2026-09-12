; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @G1(i64 %0, ptr %1) {
bb1:
  %2 = icmp sgt i64 %0, 0
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %3 = add i64 %0, 1
  br label %bb4

bb4:                                              ; preds = %bb3, %bb1
  %polyc.optionw.slot.6.0 = phi i64 [ %3, %bb3 ], [ %0, %bb1 ]
  store i64 %polyc.optionw.slot.6.0, ptr %1, align 4
  ret i64 0

dead_exit:                                        ; No predecessors!
  unreachable
}
