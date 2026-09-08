// ACT-POLYC-LLVM-CORE01-CORRECTION01 RED-2 (AC06):
// A narrowing integer conversion lowers to IR_TRUNC, which is
// classified REJECTED in the capability matrix (CONVERSION class).
// This fixture must FAIL the LLVM backend with the named
// diagnostic LLVM_BACKEND_UNSUPPORTED_CONVERSION.
I64 Narrow(I64 x) {
    I8 y = x;
    return y;
}
