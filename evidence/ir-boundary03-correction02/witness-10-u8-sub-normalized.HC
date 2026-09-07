U8 Identity(U8 x) { return x; }
U8 TestSub(U8 a, U8 b) {
    if (Identity(a) - Identity(b)) return 1;
    return 0;
}
