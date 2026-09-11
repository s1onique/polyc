; ModuleID = 'ProbePath.pre.ll'
source_filename = "ProbePath.pre.ll"

define i64 @ProbePath(i64 %p1, i64 %p3) {
bb_entry:
  %cond = icmp sgt i64 %p1, 0
  br i1 %cond, label %bb3, label %bb4

bb3:                                              ; preds = %bb_entry
  %add_rhs = add i64 %p3, 1
  br label %bb4

bb4:                                              ; preds = %bb3, %bb_entry
  %slot.0 = phi i64 [ %add_rhs, %bb3 ], [ 10, %bb_entry ]
  %cond2 = icmp slt i64 %p1, 0
  br i1 %cond2, label %bb5, label %bb6

bb5:                                              ; preds = %bb4
  %sub_rhs = sub i64 0, %p3
  br label %bb6

bb6:                                              ; preds = %bb5, %bb4
  %slot.1 = phi i64 [ %sub_rhs, %bb5 ], [ %slot.0, %bb4 ]
  br label %bb_exit

bb_exit:                                          ; preds = %bb6
  ret i64 %slot.1
}
