; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @MultiDef(i64 %0, i64 %1, i64 %2) {
bb1:
  %polyc.optionw.slot.9 = alloca i64, align 8
  store i64 %1, ptr %polyc.optionw.slot.9, align 4
  %3 = icmp sgt i64 %2, 0
  br i1 %3, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  store i64 %0, ptr %polyc.optionw.slot.9, align 4
  br label %bb4

bb4:                                              ; preds = %bb3, %bb1
  %polyc.optionw.load = load i64, ptr %polyc.optionw.slot.9, align 4
  %4 = add i64 %0, %polyc.optionw.load
  ret i64 %4

dead_exit:                                        ; No predecessors!
  unreachable
}
