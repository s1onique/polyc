// ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C4 IMPL-B
// Fixture: P6 Option-W regression -- multi-def LOCAL. The LLDefMap
// domain filter (IR_VAL_TMP only) MUST NOT halt on this; Option-W
// handles the multi-def LOCAL via mem2reg.
I64 P6MultiDefLocal(I64 a, I64 b)
{
    I64 v;
    if (a > 0)
        v = a;
    else
        v = b;
    return v;
}
