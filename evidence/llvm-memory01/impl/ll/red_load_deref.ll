; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Load(ptr %0) {
bb1:
  %ld_deref = load i64, ptr %0, align 4
  ret i64 %ld_deref

dead_exit:                                        ; No predecessors!
  unreachable
}
