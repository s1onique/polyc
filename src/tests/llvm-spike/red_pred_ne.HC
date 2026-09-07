// ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01 / RED-6 fixture.
// Branching shape (mirrors 04_cmp_branch.HC) so RED-7 (boolean/i1
// contract) is not triggered by the i1->i64 widening on return.
I64 Max(I64 a, I64 b)
{
    if (a != b)
        return a;
    return b;
}
