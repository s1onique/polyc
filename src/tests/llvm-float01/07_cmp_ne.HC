/*
 * RED-6 (ne): IR_FCMP cmp_ne unsupported by LLVM backend.
 * Source produces IR_FCMP with extra.cmp_kind == IR_CMP_NE per recon at src/ir.c:758.
 */
I64 CmpNe(F64 a, F64 b) {
    if (a != b) return 1;
    return 0;
}
