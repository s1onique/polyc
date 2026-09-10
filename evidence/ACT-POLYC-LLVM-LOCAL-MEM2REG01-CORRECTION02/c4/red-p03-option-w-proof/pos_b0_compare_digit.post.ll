; ModuleID = '/tmp/c4.bc'
source_filename = "pos_b0_compare_digit.pre.ll"

define i64 @ReadDigit(ptr %p) {
bb_entry:
  %c = load i8, ptr %p, align 1
  %c_ext = zext i8 %c to i64
  %cond_ge = icmp sge i64 %c_ext, 48
  br i1 %cond_ge, label %bb3, label %bb4

bb3:                                              ; preds = %bb_entry
  %cond_le = icmp sle i64 %c_ext, 57
  br i1 %cond_le, label %bb5, label %bb4

bb5:                                              ; preds = %bb3
  %sub_rhs = sub i64 %c_ext, 48
  br label %bb4

bb4:                                              ; preds = %bb5, %bb3, %bb_entry
  %slot.0 = phi i64 [ %sub_rhs, %bb5 ], [ 0, %bb3 ], [ 0, %bb_entry ]
  br label %bb_exit

bb_exit:                                          ; preds = %bb4
  ret i64 %slot.0
}

define i64 @AccDigit(i64 %p16, ptr %p18) {
bb_entry:
  %c = load i8, ptr %p18, align 1
  %c_ext = zext i8 %c to i64
  %cond_ge = icmp sge i64 %c_ext, 48
  br i1 %cond_ge, label %bb9, label %bb10

bb9:                                              ; preds = %bb_entry
  %cond_le = icmp sle i64 %c_ext, 57
  br i1 %cond_le, label %bb11, label %bb10

bb11:                                             ; preds = %bb9
  %mul_rhs = mul i64 %p16, 10
  %sub_rhs = sub i64 %c_ext, 48
  %add_rhs = add i64 %mul_rhs, %sub_rhs
  br label %bb10

bb10:                                             ; preds = %bb11, %bb9, %bb_entry
  %slot.0 = phi i64 [ %add_rhs, %bb11 ], [ %p16, %bb9 ], [ %p16, %bb_entry ]
  br label %bb_exit

bb_exit:                                          ; preds = %bb10
  ret i64 %slot.0
}
