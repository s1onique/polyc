U8 Passthru(U8 x) { return x; }

U8 TestPassthru(U8 x) {
    if (Passthru(x)) return 1;
    return 0;
}
