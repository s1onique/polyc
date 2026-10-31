// Negative companion: a chained NON-range operator (==) must NOT take the
// range lowering path.
I64 Main() {
  I64 a = 1;
  I64 b = 1;
  I64 c = 1;
  if (a == b == c) {
    return 1;
  }
  return 0;
}
