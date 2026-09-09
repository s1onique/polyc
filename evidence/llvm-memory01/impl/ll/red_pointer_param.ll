; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @PtrParam(ptr %0) {
bb1:
  ret i64 0

dead_exit:                                        ; No predecessors!
  unreachable
}
