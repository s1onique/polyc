; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @ReadDigit(ptr %0) {
bb1:
  %polyc.optionw.slot.8 = alloca i64, align 8
  %ld_deref = load i8, ptr %0, align 1
  %zext_i8_i64 = zext i8 %ld_deref to i64
  %trunc_i64_i8 = trunc i64 %zext_i8_i64 to i8
  store i64 0, ptr %polyc.optionw.slot.8, align 4
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
  %zext_i8_i644 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc5 = trunc i64 %zext_i8_i644 to i8
  %3 = sub i8 %i8_arg_trunc5, 48
  %i8_arith_zext = zext i8 %3 to i64
  store i64 %i8_arith_zext, ptr %polyc.optionw.slot.8, align 4
  br label %bb4

bb4:                                              ; preds = %bb5, %bb3, %bb1
  %polyc.optionw.load = load i64, ptr %polyc.optionw.slot.8, align 4
  ret i64 %polyc.optionw.load

dead_exit:                                        ; No predecessors!
  unreachable
}

define i64 @AccDigit(i64 %0, ptr %1) {
bb7:
  %polyc.optionw.slot.17 = alloca i64, align 8
  store i64 %0, ptr %polyc.optionw.slot.17, align 4
  %ld_deref = load i8, ptr %1, align 1
  %zext_i8_i64 = zext i8 %ld_deref to i64
  %trunc_i64_i8 = trunc i64 %zext_i8_i64 to i8
  %zext_i8_i641 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc = trunc i64 %zext_i8_i641 to i8
  %2 = icmp sge i8 %i8_arg_trunc, 48
  br i1 %2, label %bb9, label %bb10

bb9:                                              ; preds = %bb7
  %zext_i8_i642 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc3 = trunc i64 %zext_i8_i642 to i8
  %3 = icmp sle i8 %i8_arg_trunc3, 57
  br i1 %3, label %bb11, label %bb10

bb11:                                             ; preds = %bb9
  %zext_i8_i644 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc5 = trunc i64 %zext_i8_i644 to i8
  %4 = sub i8 %i8_arg_trunc5, 48
  %i8_arith_zext = zext i8 %4 to i64
  %polyc.optionw.load = load i64, ptr %polyc.optionw.slot.17, align 4
  %5 = mul i64 %polyc.optionw.load, 10
  %6 = add i64 %5, %i8_arith_zext
  store i64 %6, ptr %polyc.optionw.slot.17, align 4
  br label %bb10

bb10:                                             ; preds = %bb11, %bb9, %bb7
  %polyc.optionw.load6 = load i64, ptr %polyc.optionw.slot.17, align 4
  ret i64 %polyc.optionw.load6

dead_exit:                                        ; No predecessors!
  unreachable
}
