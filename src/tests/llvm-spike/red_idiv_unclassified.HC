// RED-1 for ACT-POLYC-LLVM-CORE01:
// Integer division lowers to IR_IDIV, which is NOT handled by the
// current LLVM dispatch and therefore falls into the generic catch-all
// on line 922 of src/llvm-backend.c.
//
// Expected diagnostic class: LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
// Current actual diagnostic: LLVM_BACKEND_UNSUPPORTED_IR (generic)
//
// This fixture must FAIL the LLVM backend with the generic
// LLVM_BACKEND_UNSUPPORTED_IR token before the production fix
// (named diagnostic + capability matrix entry).
I64 DivMod(I64 a, I64 b)
{
    return a / b;
}
