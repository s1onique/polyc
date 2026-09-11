; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Diamond(i64 %0, i64 %1) {
bb1:
  %polyc.optionw.slot.6 = alloca i64, align 8
  %2 = icmp ne i64 %0, 0
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %3 = add i64 %1, 1
  store i64 %3, ptr %polyc.optionw.slot.6, align 4
  br label %bb5

bb4:                                              ; preds = %bb1
  %4 = sub i64 %1, 1
  store i64 %4, ptr %polyc.optionw.slot.6, align 4
  br label %bb5

bb5:                                              ; preds = %bb4, %bb3
  %polyc.optionw.load = load i64, ptr %polyc.optionw.slot.6, align 4
  ret i64 %polyc.optionw.load

dead_exit:                                        ; No predecessors!
  unreachable
}
