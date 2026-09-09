; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Arithmetic(i64 %0, i64 %1) {
bb1:
  %2 = sub i64 %0, %1
  %3 = mul i64 %2, 3
  ret i64 %3

dead_exit:                                        ; No predecessors!
  unreachable
}
