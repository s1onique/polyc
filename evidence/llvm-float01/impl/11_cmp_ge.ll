; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @CmpGe(double %0, double %1) {
bb1:
  %2 = fcmp oge double %0, %1
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  ret i64 1

bb4:                                              ; preds = %bb1
  ret i64 0

bb2:                                              ; No predecessors!
  unreachable
}
