/*
 * RED-4: FSUB unsupported by LLVM backend.
 * Source produces IR_FSUB per recon at src/ir.c:734.
 */
F64 Fsub(F64 a, F64 b)
{
    return a - b;
}
