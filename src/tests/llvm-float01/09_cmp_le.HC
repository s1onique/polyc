/*
 * RED-6 (le): IR_FCMP cmp_le unsupported by LLVM backend.
 * Source produces IR_FCMP with extra.cmp_kind == IR_CMP_LE per recon at src/ir.c:742.
 */
I64 CmpLe(F64 a, F64 b) {
    if (a <= b) return 1;
    return 0;
}
