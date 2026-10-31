// Negative companion: pointer multiply is a REJECTED pointer operation.
I64 Main() {
  I64 x = 1;
  I64 y = 2;
  I64 *p = &x;
  I64 *q = &y;
  I64 *r = p * q;
  return 0;
}
