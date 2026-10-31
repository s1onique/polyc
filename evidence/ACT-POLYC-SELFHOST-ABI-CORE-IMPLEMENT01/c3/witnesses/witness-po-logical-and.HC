// A pointer logical-AND: the PO decision must classify AST_BIN_OP_LOG_AND
// as a VALID pointer operator.
I64 Main() {
  I64 x = 1; I64 y = 2;
  I64 *p = &x; I64 *q = &y;
  if (p && q) {
    return 1;
  }
  return 0;
}
