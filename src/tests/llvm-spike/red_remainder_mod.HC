// ACT-POLYC-LLVM-CORE01-CORRECTION02 RED-2 (AC02):
// Integer remainder (`%`) lowers to IR_IREM, which is classified
// REJECTED in the capability matrix (INT_REMAINDER class).
// This fixture must FAIL the LLVM backend with the named
// diagnostic LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER.
I64 Mod(I64 a, I64 b)
{
    return a % b;
}
