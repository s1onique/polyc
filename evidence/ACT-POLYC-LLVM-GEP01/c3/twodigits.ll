; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @TwoDigits(ptr %0) {
bb1:
  %ld_deref = load i8, ptr %0, align 1
  %zext_i8_i64 = zext i8 %ld_deref to i64
  %i8_arg_trunc = trunc i64 %zext_i8_i64 to i8
  %1 = sub i8 %i8_arg_trunc, 48
  %i8_arith_zext = zext i8 %1 to i64
  %gep_i8 = getelementptr i8, ptr %0, i64 1
  %ld_deref1 = load i8, ptr %gep_i8, align 1
  %zext_i8_i642 = zext i8 %ld_deref1 to i64
  %i8_arg_trunc3 = trunc i64 %zext_i8_i642 to i8
  %2 = sub i8 %i8_arg_trunc3, 48
  %i8_arith_zext4 = zext i8 %2 to i64
  %3 = mul i64 %i8_arith_zext, 10
  %4 = add i64 %3, %i8_arith_zext4
  ret i64 %4

dead_exit:                                        ; No predecessors!
  unreachable
}
