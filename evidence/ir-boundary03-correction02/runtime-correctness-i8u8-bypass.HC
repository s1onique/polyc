I8 Id8(I8 x) { return x; }
U8 Id8u(U8 x) { return x; }

I64 Main() {
    I64 sum = 0;
    if (Id8(2))   sum += 1;
    if (Id8(127)) sum += 2;
    if (Id8(-1))  sum += 4;
    if (Id8(0))   sum += 8;
    if (Id8u(2))  sum += 16;
    if (Id8u(255)) sum += 32;
    if (Id8u(0))  sum += 64;
    return sum;
}
