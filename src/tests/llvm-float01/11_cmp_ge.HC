/*
 * RED-6 (ge): IR_FCMP cmp_ge unsupported by LLVM backend.
 * Source produces IR_FCMP with extra.cmp_kind == IR_CMP_GE per recon at src/ir.c:749.
 */
I64 CmpGe(F64 a, F64 b) {
    if (a >= b) return 1;
    return 0;
}
