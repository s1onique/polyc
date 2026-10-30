static I64 D[8];
static I64 I2[8];
I32 Main(I32 argc, U8 **argv) {
  I64 i = 0;
  while (i < 5) { D[i] = 0; i++; }
  I64 ord = 0;
  while (ord < 5) {
    I64 best = -1;
    I64 c = 0;
    while (c < 5) {
      if (!D[c]) { if (best < 0) best = c; }
      c++;
    }
    "ITER=%d BEST=%d\n", ord, best;
    D[best] = 1;
    ord++;
  }
  return 0;
}
