// ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C4 IMPL-B
// Fixture: short-circuit logical OR.
// Covers fence: valid PhiOnly (counter delta exactly 1).
I64 PhiShortCircuitOr(I64 a, I64 b)
{
    if (a > 0 || b > 0)
        return 1;
    return 0;
}
