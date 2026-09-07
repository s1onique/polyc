U8 TestU8(U8 x) {
    if (x) return 1;
    return 0;
}

I64 Test() {
    return TestU8(2);
}
