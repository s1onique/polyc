; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Eq1(double %0, double %1) {
bb1:
  %2 = fcmp oeq double %0, %1
  br i1 %2, label %bb3, label %bb4

bb3:                                              ; preds = %bb1
  ret i64 1

bb4:                                              ; preds = %bb1
  ret i64 0

bb2:                                              ; No predecessors!
  unreachable
}

define i64 @Eq2(double %0, double %1) {
bb5:
  %2 = fcmp oeq double %0, %1
  br i1 %2, label %bb7, label %bb8

bb7:                                              ; preds = %bb5
  ret i64 1

bb8:                                              ; preds = %bb5
  ret i64 0

bb6:                                              ; No predecessors!
  unreachable
}

define i64 @PZeroEqNZero(double %0, double %1) {
bb9:
  %2 = fcmp oeq double %0, %1
  br i1 %2, label %bb11, label %bb12

bb11:                                             ; preds = %bb9
  ret i64 1

bb12:                                             ; preds = %bb9
  ret i64 0

bb10:                                             ; No predecessors!
  unreachable
}

define i64 @PInfGtZero(double %0, double %1) {
bb13:
  %2 = fcmp ogt double %0, %1
  br i1 %2, label %bb15, label %bb16

bb15:                                             ; preds = %bb13
  ret i64 1

bb16:                                             ; preds = %bb13
  ret i64 0

bb14:                                             ; No predecessors!
  unreachable
}

define i64 @NInfLtZero(double %0, double %1) {
bb17:
  %2 = fcmp olt double %0, %1
  br i1 %2, label %bb19, label %bb20

bb19:                                             ; preds = %bb17
  ret i64 1

bb20:                                             ; preds = %bb17
  ret i64 0

bb18:                                             ; No predecessors!
  unreachable
}

define i64 @NaN_compare(double %0, double %1) {
bb21:
  %2 = fcmp oeq double %0, %1
  br i1 %2, label %bb23, label %bb24

bb23:                                             ; preds = %bb21
  ret i64 1

bb24:                                             ; preds = %bb21
  %3 = fcmp une double %0, %1
  br i1 %3, label %bb25, label %bb26

bb25:                                             ; preds = %bb24
  ret i64 2

bb26:                                             ; preds = %bb24
  %4 = fcmp olt double %0, %1
  br i1 %4, label %bb27, label %bb28

bb27:                                             ; preds = %bb26
  ret i64 3

bb28:                                             ; preds = %bb26
  %5 = fcmp ole double %0, %1
  br i1 %5, label %bb29, label %bb30

bb29:                                             ; preds = %bb28
  ret i64 4

bb30:                                             ; preds = %bb28
  %6 = fcmp ogt double %0, %1
  br i1 %6, label %bb31, label %bb32

bb31:                                             ; preds = %bb30
  ret i64 5

bb32:                                             ; preds = %bb30
  %7 = fcmp oge double %0, %1
  br i1 %7, label %bb33, label %bb34

bb33:                                             ; preds = %bb32
  ret i64 6

bb34:                                             ; preds = %bb32
  ret i64 0

bb22:                                             ; No predecessors!
  unreachable
}
