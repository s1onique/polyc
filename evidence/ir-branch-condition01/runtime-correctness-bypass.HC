U8 IdentityU8(U8 x) { return x; }
I8 IdentityI8(I8 x) { return x; }

U8 TestU8_0()    { if (IdentityU8(0))   return 1; return 0; }
U8 TestU8_1()    { if (IdentityU8(1))   return 1; return 0; }
U8 TestU8_2()    { if (IdentityU8(2))   return 1; return 0; }
U8 TestU8_3()    { if (IdentityU8(3))   return 1; return 0; }
U8 TestU8_255()  { if (IdentityU8(255)) return 1; return 0; }

I8 TestI8_0()    { if (IdentityI8(0))   return 1; return 0; }
I8 TestI8_1()    { if (IdentityI8(1))   return 1; return 0; }
I8 TestI8_neg1() { if (IdentityI8(-1))  return 1; return 0; }
I8 TestI8_neg2() { if (IdentityI8(-2))  return 1; return 0; }
I8 TestI8_n128() { if (IdentityI8(-128)) return 1; return 0; }

I64 Main() {
    I64 sum = 0;
    if (TestU8_0())    sum += 0;
    if (TestU8_1())    sum += 1;
    if (TestU8_2())    sum += 2;
    if (TestU8_3())    sum += 4;
    if (TestU8_255())  sum += 8;
    if (TestI8_0())    sum += 0;
    if (TestI8_1())    sum += 16;
    if (TestI8_neg1()) sum += 32;
    if (TestI8_neg2()) sum += 64;
    if (TestI8_n128()) sum += 128;
    return sum;
}
