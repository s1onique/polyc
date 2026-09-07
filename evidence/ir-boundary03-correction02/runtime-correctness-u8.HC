U8 Identity(U8 x) { return x; }

U8 Test_2() { if (Identity(2))   return 1; return 0; }
U8 Test_3() { if (Identity(3))   return 1; return 0; }
U8 Test_255() { if (Identity(255)) return 1; return 0; }
U8 Test_0() { if (Identity(0))   return 1; return 0; }
U8 Test_1() { if (Identity(1))   return 1; return 0; }

I64 Main() {
    I64 sum = 0;
    if (Test_2())   sum += 1;
    if (Test_3())   sum += 2;
    if (Test_255()) sum += 4;
    if (Test_0())   sum += 8;
    if (Test_1())   sum += 16;
    return sum;
}
