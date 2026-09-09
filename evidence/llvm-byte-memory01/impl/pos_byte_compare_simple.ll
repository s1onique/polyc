; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @IsDigit(ptr %0) {
bb1:
  %ld_deref = load i8, ptr %0, align 1
  %zext_i8_i64 = zext i8 %ld_deref to i64
  %trunc_i64_i8 = trunc i64 %zext_i8_i64 to i8
  %zext_i8_i641 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc = trunc i64 %zext_i8_i641 to i8
  %1 = icmp sge i8 %i8_arg_trunc, 48
  br i1 %1, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %zext_i8_i642 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc3 = trunc i64 %zext_i8_i642 to i8
  %2 = icmp sle i8 %i8_arg_trunc3, 57
  br i1 %2, label %bb5, label %bb4

bb5:                                              ; preds = %bb3
  ret i64 1

bb4:                                              ; preds = %bb3, %bb1
  ret i64 0

bb2:                                              ; No predecessors!
  unreachable
}
