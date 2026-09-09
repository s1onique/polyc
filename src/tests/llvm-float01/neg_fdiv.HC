/*
 * Negative fixture: IR_FDIV must remain rejected by LLVM backend.
 * ACT §1.2 explicitly excludes FDIV.
 */
F64 Fdiv(F64 a, F64 b)
{
    return a / b;
}
