/*
 * RED-5: FMUL unsupported by LLVM backend.
 * Source produces IR_FMUL per recon at src/ir.c:727.
 */
F64 Fmul(F64 a, F64 b)
{
    return a * b;
}
