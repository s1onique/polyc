// ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C4 IMPL-B
// Fixture: short-circuit logical AND.
I64 PhiShortCircuitAnd(I64 a, I64 b)
{
    if (a > 0 && b > 0)
        return 1;
    return 0;
}
