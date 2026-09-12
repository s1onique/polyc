// ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C4 IMPL-B
// Fixture: single IR_PHI-producing function (the canonical PhiOnly).
// Exercises the short-circuit OR shape with a single IR_PHI where
// both incoming edges are i1 IR_ICMP producers (the canonical
// Outcome B from C3.1: i1 -> i8 zext on both edges).
I64 PhiOnly(I64 a, I64 b)
{
    if (a > 0 || b > 0)
        return 1;
    return 0;
}
