I8 IdentityI8(I8 x) { return x; }

I8 TestI8call(I8 x) {
    if (IdentityI8(x)) return 1;
    return 0;
}
