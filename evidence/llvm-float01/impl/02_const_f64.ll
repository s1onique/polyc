; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define double @Const() {
bb1:
  ret double 3.140000e+00

dead_exit:                                        ; No predecessors!
  unreachable
}
