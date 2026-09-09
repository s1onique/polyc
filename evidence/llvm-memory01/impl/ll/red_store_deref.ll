; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Store(ptr %0, i64 %1) {
bb1:
  store i64 %1, ptr %0, align 4
  ret i64 0

dead_exit:                                        ; No predecessors!
  unreachable
}
