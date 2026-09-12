// ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C4 IMPL-B
// Fixture: P5 Option-W regression -- canonical safe-forward single-
// predecessor. Must remain green (no LLDefMap halt).
I64 P5SafeFwd(I64 a)
{
    I64 v = a;
    return v;
}
