I8 NegOne(I8 x) { return x; }

U8 Count(I8 x) {
    U8 n = 0;
    do {
        n = n + 1;
    } while (NegOne(x));
    return n;
}
