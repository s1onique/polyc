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
  %1 = call i64 @Inc(i64 %0)
  ret i64 %1

dead_exit:                                        ; No predecessors!
  unreachable
}
