; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Inc(i64 %0) {
bb1:
  %1 = add i64 %0, %0
  ret i64 %1

dead_exit:                                        ; No predecessors!
  unreachable
}

define i64 @Caller(i64 %0) {
bb3:
  %1 = alloca i64, align 8
  store i64 %0, ptr %1, align 4
  %2 = load i64, ptr %1, align 4
  %3 = call i64 @Inc(i64 %2)
  ret i64 %3

dead_exit:                                        ; No predecessors!
  unreachable
}
