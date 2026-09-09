/*
 * RED-7: IR_FCMP + IR_BR (i1 cond) branch path unsupported by LLVM backend.
 *
 * Pre-FLOAT01 the LLVM backend rejects F64 params (RED-1) so this fixture cannot
 * even reach the FCMP dispatch; it produces a parameter-type rejection.
 *
 * Post-FLOAT01 the path is: IR_FCMP -> i1 cond via LLVMBuildFCmp -> IR_BR consumes
 * i1 directly via LLVMBuildCondBr. No trunc, no zext, no integer-cmp substitution.
 */
I64 Test(F64 a, F64 b) {
    if (a > b)
        return 1;
    return 0;
}
