/*
 * RED-6 (gt): IR_FCMP cmp_gt unsupported by LLVM backend.
 * Source produces IR_FCMP with extra.cmp_kind == IR_CMP_GT per recon at src/ir.c:745.
 */
I64 CmpGt(F64 a, F64 b) {
    if (a >  b) return 1;
    return 0;
}
