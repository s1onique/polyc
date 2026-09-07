I8 NegIdentity(I8 x) { return x; }

U8 TestNegId(I8 x) {
    if (NegIdentity(x)) return 1;
    return 0;
}
