; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Locals(i64 %0, i64 %1) {
bb1:
  %2 = add i64 %0, %1
  ret i64 %2

dead_exit:                                        ; No predecessors!
  unreachable
}
