// Pointer operation witness: a pointer comparison is a VALID pointer op.
I64 Main() {
  I64 x = 1;
  I64 y = 2;
  I64 *p = &x;
  I64 *q = &y;
  if (p < q) {
    return 1;
  }
  return 0;
}
