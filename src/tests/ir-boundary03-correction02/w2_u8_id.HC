U8 Identity(U8 x) { return x; }

U8 TestId(U8 x) {
    if (Identity(x)) return 1;
    return 0;
}
