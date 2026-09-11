; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @FwdSafe(ptr %0) {
bb1:
  %polyc.optionw.slot.6 = alloca i64, align 8
  %ld_deref = load i64, ptr %0, align 4
  %1 = add i64 %ld_deref, 1
  store i64 %1, ptr %polyc.optionw.slot.6, align 4
  %polyc.optionw.load = load i64, ptr %polyc.optionw.slot.6, align 4
  ret i64 %polyc.optionw.load

dead_exit:                                        ; No predecessors!
  unreachable
}
