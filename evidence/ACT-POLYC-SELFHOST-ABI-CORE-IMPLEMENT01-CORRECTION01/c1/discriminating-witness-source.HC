// W-CORR-RO-DISCRIM -- the correction-owned DISCRIMINATING witness for
// SITE-RANGE-OPERATOR / AUTH-13.
//
// The chained relational expression a < b < c is lowered by the range
// path as the SHORT-CIRCUIT AND (a < b) && (b < c). When the range
// lowering does NOT apply, the same expression is left-associated:
// (a < b) < c.
//
// The two readings disagree for this input:
//
//   a = 5, b = 1, c = 3
//     range lowering : (5 < 1) && (1 < 3)  = FALSE && TRUE  = FALSE = 0
//     left-assoc     : (5 < 1) < 3        = FALSE < 3        = TRUE  = 1
//
// The program's exit status is therefore 0 when the range lowering
// applies and 1 when it does not. This is the DISCRIMINATING channel.
//
// The historical witness `1 < 2 < 3` is NOT discriminating: for that
// input both readings are TRUE (1), so it cannot distinguish the two
// lowerings. It is retained separately as W-HISTORICAL-NONDISCRIM.
I64 Main() {
  I64 a = 5;
  I64 b = 1;
  I64 c = 3;
  if (a < b < c) {
    return 1;
  }
  return 0;
}
