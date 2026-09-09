; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define double @Mixed(double %0, double %1, double %2, double %3) {
bb1:
  %4 = fadd double %0, %1
  %5 = fmul double %4, %2
  %6 = fsub double %5, %3
  ret double %6

dead_exit:                                        ; No predecessors!
  unreachable
}
