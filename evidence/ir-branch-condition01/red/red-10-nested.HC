U8 Identity(U8 x) { return x; }

U8 Nested(U8 a, U8 b) {
    if (Identity(a)) {
        if (Identity(b)) return 1;
    }
    return 0;
}
