; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @LexOneToken(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4) {
bb1:
  %ld_deref = load i64, ptr %2, align 4
  %5 = icmp sge i64 %ld_deref, 48
  br i1 %5, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %6 = icmp sle i64 %ld_deref, 57
  br i1 %6, label %bb5, label %bb4

bb5:                                              ; preds = %bb3
  store i64 2, ptr %3, align 4
  %7 = sub i64 %ld_deref, 48
  store i64 %7, ptr %4, align 4
  %ld_deref1 = load i64, ptr %0, align 4
  %8 = add i64 %ld_deref1, 1
  store i64 %8, ptr %0, align 4
  ret i64 1

bb4:                                              ; preds = %bb3, %bb1
  store i64 3, ptr %3, align 4
  store i64 0, ptr %4, align 4
  ret i64 0

bb2:                                              ; No predecessors!
  unreachable
}

define i64 @LexMain(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4) {
bb7:
  %5 = call i64 @LexOneToken(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4)
  ret i64 %5

dead_exit:                                        ; No predecessors!
  unreachable
}
