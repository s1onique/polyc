/*
 * RED-6 (eq): IR_FCMP cmp_eq unsupported by LLVM backend.
 * Source produces IR_FCMP with extra.cmp_kind == IR_CMP_EQ per recon at src/ir.c:754.
 */
I64 CmpEq(F64 a, F64 b) {
    if (a == b) return 1;
    return 0;
}
