// ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C4 IMPL-B
// Fixture: three-way OR producing an IR_PHI with 3 incoming edges.
// One constant edge (bb1) + two icmp edges (bb3, bb5).
I64 PhiMultiPred(I64 a, I64 b, I64 c)
{
    if (a > 0 || b > 0 || c > 0)
        return 1;
    return 0;
}
