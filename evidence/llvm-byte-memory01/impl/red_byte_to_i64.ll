; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i8 @Id(i8 %0) {
bb1:
  %zext_i8_i64 = zext i8 %0 to i64
  %ret_trunc_to_i8 = trunc i64 %zext_i8_i64 to i8
  ret i8 %ret_trunc_to_i8

dead_exit:                                        ; No predecessors!
  unreachable
}
