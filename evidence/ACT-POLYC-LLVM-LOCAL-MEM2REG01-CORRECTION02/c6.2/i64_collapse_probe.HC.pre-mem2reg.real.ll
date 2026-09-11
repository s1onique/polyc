; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Probe(i64 %0, ptr %1) {
bb1:
  %polyc.optionw.slot.2 = alloca i64, align 8
  store i64 %0, ptr %polyc.optionw.slot.2, align 4
  %ld_deref = load i64, ptr %1, align 4
  %2 = icmp sge i64 %ld_deref, 10
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %3 = icmp sle i64 %ld_deref, 99
  br i1 %3, label %bb5, label %bb4

bb5:                                              ; preds = %bb3
  %polyc.optionw.load = load i64, ptr %polyc.optionw.slot.2, align 4
  %4 = add i64 %polyc.optionw.load, %ld_deref
  store i64 %4, ptr %polyc.optionw.slot.2, align 4
  br label %bb4

bb4:                                              ; preds = %bb5, %bb3, %bb1
  %polyc.optionw.load1 = load i64, ptr %polyc.optionw.slot.2, align 4
  ret i64 %polyc.optionw.load1

dead_exit:                                        ; No predecessors!
  unreachable
}
