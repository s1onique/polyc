; ModuleID = '/tmp/scanident-fixture.bc'
source_filename = "polyc_module"

define i64 @ScanIdent(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4) {
bb1:
  br label %bb3

bb3:                                              ; preds = %bb11, %bb1
  %polyc.optionw.slot.6.0 = phi i64 [ %2, %bb1 ], [ %11, %bb11 ]
  %5 = icmp slt i64 %polyc.optionw.slot.6.0, %1
  br i1 %5, label %bb4, label %bb5

bb4:                                              ; preds = %bb3
  %gep_i8 = getelementptr i8, ptr %0, i64 %polyc.optionw.slot.6.0
  %ld_deref = load i8, ptr %gep_i8, align 1
  %zext_i8_i64 = zext i8 %ld_deref to i64
  %trunc_i64_i8 = trunc i64 %zext_i8_i64 to i8
  %zext_i8_i642 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc = trunc i64 %zext_i8_i642 to i8
  %6 = icmp eq i8 %i8_arg_trunc, 32
  br i1 %6, label %bb9, label %bb8

bb8:                                              ; preds = %bb4
  %zext_i8_i643 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc4 = trunc i64 %zext_i8_i643 to i8
  %7 = icmp eq i8 %i8_arg_trunc4, 9
  %phi_icmp_zext = zext i1 %7 to i8
  br label %bb9

bb9:                                              ; preds = %bb8, %bb4
  %phi = phi i8 [ 1, %bb4 ], [ %phi_icmp_zext, %bb8 ]
  %8 = icmp ne i8 %phi, 0
  br i1 %8, label %bb7, label %bb6

bb6:                                              ; preds = %bb9
  %zext_i8_i645 = zext i8 %trunc_i64_i8 to i64
  %i8_arg_trunc6 = trunc i64 %zext_i8_i645 to i8
  %9 = icmp eq i8 %i8_arg_trunc6, 10
  %phi_icmp_zext8 = zext i1 %9 to i8
  br label %bb7

bb7:                                              ; preds = %bb6, %bb9
  %phi7 = phi i8 [ 1, %bb9 ], [ %phi_icmp_zext8, %bb6 ]
  %10 = icmp ne i8 %phi7, 0
  br i1 %10, label %bb5, label %bb11

bb11:                                             ; preds = %bb7
  %11 = add i64 %polyc.optionw.slot.6.0, 1
  br label %bb3

bb5:                                              ; preds = %bb7, %bb3
  store i64 %polyc.optionw.slot.6.0, ptr %3, align 4
  %12 = sub i64 %polyc.optionw.slot.6.0, %2
  store i64 %12, ptr %4, align 4
  ret i64 0

dead_exit:                                        ; No predecessors!
  unreachable
}
