I64 DigitAccum(I64 acc, I64 c)
{
    return acc * 10 + (c - 48);
}
I64 Main(I64 *out)
{
    I64 v, d1, d2, d3;
    v = 0;
    d1 = 53;
    v = DigitAccum(v, d1);
    d2 = 50;
    v = DigitAccum(v, d2);
    d3 = 55;
    v = DigitAccum(v, d3);
    *out = v;
    return 0;
}
