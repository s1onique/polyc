; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Max(i64 %0, i64 %1) {
bb1:
  %2 = alloca i64, align 8
  %3 = alloca i64, align 8
  store i64 %0, ptr %2, align 4
  store i64 %1, ptr %3, align 4
  %4 = icmp eq i64 %0, %1
  br i1 %4, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  %5 = load i64, ptr %2, align 4
  ret i64 %5

bb4:                                              ; preds = %bb1
  %6 = load i64, ptr %3, align 4
  ret i64 %6

bb2:                                              ; No predecessors!
  unreachable
}
