; ModuleID = '/tmp/c6.3/safe_fwd_single_pred.post.ll'
source_filename = "polyc_module"

define i64 @FwdSafe(ptr %0) {
bb1:
  %ld_deref = load i64, ptr %0, align 4
  %1 = add i64 %ld_deref, 1
  ret i64 %1

dead_exit:                                        ; No predecessors!
  unreachable
}
