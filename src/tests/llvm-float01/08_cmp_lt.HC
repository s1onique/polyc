/*
 * RED-6 (lt): IR_FCMP cmp_lt unsupported by LLVM backend.
 * Source produces IR_FCMP with extra.cmp_kind == IR_CMP_LT per recon at src/ir.c:738.
 */
I64 CmpLt(F64 a, F64 b) {
    if (a <  b) return 1;
    return 0;
}
