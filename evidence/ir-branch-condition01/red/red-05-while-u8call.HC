U8 Identity(U8 x) { return x; }

U8 FirstPositive(U8 x) {
    U8 n = 0;
    while (Identity(x)) {
        if (n == 10) break;
        n = n + 1;
    }
    return n;
}
