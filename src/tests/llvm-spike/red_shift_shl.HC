// ACT-POLYC-LLVM-CORE01-CORRECTION02 RED-2 (AC02):
// Integer left shift (`<<`) lowers to IR_SHL, which is classified
// REJECTED in the capability matrix (INT_SHIFT class).
// This fixture must FAIL the LLVM backend with the named
// diagnostic LLVM_BACKEND_UNSUPPORTED_INT_SHIFT.
I64 Shl1(I64 a)
{
    return a << 1;
}
