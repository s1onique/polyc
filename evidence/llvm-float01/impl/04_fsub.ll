; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define double @Fsub(double %0, double %1) {
bb1:
  %2 = fsub double %0, %1
  ret double %2

dead_exit:                                        ; No predecessors!
  unreachable
}
