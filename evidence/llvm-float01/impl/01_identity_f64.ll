; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define double @Identity(double %0) {
bb1:
  ret double %0

dead_exit:                                        ; No predecessors!
  unreachable
}
