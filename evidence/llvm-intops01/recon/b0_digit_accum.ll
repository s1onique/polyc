; ModuleID = 'polyc_module'
source_filename = "polyc_module"

define i64 @DigitAccum(i64 %0, i64 %1) {
bb1:
  %2 = mul i64 %0, 10
  %3 = sub i64 %1, 48
  %4 = add i64 %2, %3
  ret i64 %4

dead_exit:                                        ; No predecessors!
  unreachable
}

define i64 @Main(ptr %0) {
bb3:
  %1 = call i64 @DigitAccum(i64 0, i64 53)
  %2 = call i64 @DigitAccum(i64 %1, i64 50)
  %3 = call i64 @DigitAccum(i64 %2, i64 55)
  store i64 %3, ptr %0, align 4
  ret i64 0

dead_exit:                                        ; No predecessors!
  unreachable
}
