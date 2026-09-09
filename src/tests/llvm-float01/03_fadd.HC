/*
 * RED-3: FADD unsupported by LLVM backend.
 * Source produces IR_FADD per recon at src/ir.c:724.
 */
F64 Fadd(F64 a, F64 b)
{
    return a + b;
}
