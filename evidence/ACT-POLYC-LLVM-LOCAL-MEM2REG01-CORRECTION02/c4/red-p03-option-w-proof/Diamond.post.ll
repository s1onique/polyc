; ModuleID = '/tmp/c4.bc'
source_filename = "Diamond.pre.ll"

define i64 @Diamond(i64 %p1, i64 %p3) {
bb_entry:
  %flag_ne = icmp ne i64 %p1, 0
  br i1 %flag_ne, label %bb3, label %bb4

bb3:                                              ; preds = %bb_entry
  %add_rhs = add i64 %p3, 1
  br label %bb5

bb4:                                              ; preds = %bb_entry
  %sub_rhs = sub i64 %p3, 1
  br label %bb5

bb5:                                              ; preds = %bb4, %bb3
  %slot.0 = phi i64 [ %add_rhs, %bb3 ], [ %sub_rhs, %bb4 ]
  br label %bb_exit

bb_exit:                                          ; preds = %bb5
  ret i64 %slot.0
}
