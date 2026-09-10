I64 Probe(I64 acc, I64 *p) {
    I64 x = *p;
    if (x >= 10) {
        if (x <= 99) {
            acc = acc + x;
        }
    }
    return acc;
}
