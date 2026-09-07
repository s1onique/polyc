// ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01 / RED-2 fixture.
// Two local I64 variables; passing them through the function body
// forces alloca/store/load materialisation at the LLVM boundary,
// unless the collapse-elimination pass folds them away.
I64 Locals(I64 a, I64 b)
{
    I64 x = a;
    I64 y = b;
    return x + y;
}
