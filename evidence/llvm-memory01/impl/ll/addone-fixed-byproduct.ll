; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @AddOne(i64 %0) {
bb1:
  %1 = add i64 %0, 1
  ret i64 %1

dead_exit:                                        ; No predecessors!
  unreachable
}
