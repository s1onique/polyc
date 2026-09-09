; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @StoreInc(ptr %0) {
bb1:
  %ld_deref = load i64, ptr %0, align 4
  %1 = add i64 %ld_deref, 1
  store i64 %1, ptr %0, align 4
  %ld_deref1 = load i64, ptr %0, align 4
  ret i64 %ld_deref1

dead_exit:                                        ; No predecessors!
  unreachable
}
