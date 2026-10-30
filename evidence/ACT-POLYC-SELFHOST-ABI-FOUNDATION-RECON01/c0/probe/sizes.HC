extern "c" I64 AbiHostReport(I64 which, I64 value);
I64 AbiProbeTypeSizes() {
  I64 a = sizeof(I64);
  I64 b = sizeof(Bool);
  I64 c = sizeof(U8 *);
  I64 d = sizeof(I32);
  AbiHostReport(1, a);
  AbiHostReport(2, b);
  AbiHostReport(3, c);
  AbiHostReport(4, d);
  return a * 1000000 + b * 10000 + c * 100 + d;
}
I64 AbiProbePtrToI64(U8 *p) {
  I64 v = p(I64);
  return v;
}
U8 *AbiProbeI64ToPtr(I64 v) {
  U8 *p = v(U8 *);
  return p;
}
