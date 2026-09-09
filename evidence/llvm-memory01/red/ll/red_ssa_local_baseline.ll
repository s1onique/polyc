; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @Answer() {
bb1:
  ret i64 42

dead_exit:                                        ; No predecessors!
  unreachable
}
