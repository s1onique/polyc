// A single "<" comparison between pointers. This exercises
// AST_BIN_OP_LT (7), which is one of the FOUR range operators, so it is
// also a range-operator channel witness.
I64 Main() {
  I64 x = 1; I64 y = 2;
  I64 *p = &x; I64 *q = &y;
  if (p < q) {
    return 1;
  }
  return 0;
}
