// Chained relational range expression: a < b < c.
// The C side lowers this as the short-circuit AND (a<b) && (b<c).
I64 Main() {
  I64 a = 1;
  I64 b = 2;
  I64 c = 3;
  if (a < b < c) {
    return 1;
  }
  return 0;
}
