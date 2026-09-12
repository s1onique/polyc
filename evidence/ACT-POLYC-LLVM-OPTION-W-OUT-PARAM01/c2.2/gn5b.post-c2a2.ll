; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @GN5b(ptr %0, i64 %1) {
bb1:
  %2 = add i64 %1, 1
  store i64 %2, ptr %0, align 4
  %3 = sub i64 %2, 1
  %4 = add i64 %3, 1
  ret i64 0

dead_exit:                                        ; No predecessors!
  unreachable
}
