// tools/quality/parser-padding-gen-matrix-fixture.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
//
// Generates the 16640-row bounded matrix fixture for the
// parser-padding differential: offset 0..255 x size 0..64.
//
// The expected_padding column is computed by mirroring the
// legacy C `CalcPadding` semantics so the row is informative.
// The differential verifier uses its own runtime C oracle as the
// terminal ground truth.
//
// USAGE:
//   build/parser-padding-gen-matrix-fixture > matrix.tsv
//
// This tool is a fixture generator, not a verifier. It is
// intentionally PolyC and emits no PASS/FAIL judgement.

I64 main(I64 argc, U8 **argv)
{
  "case_id\tclasses\toffset\tsize\texpected_padding\n";
  I64 n = 0;
  for (I64 off = 0; off <= 255; off = off + 1) {
    for (I64 sz = 0; sz <= 64; sz = sz + 1) {
      n = n + 1;
      I64 exp;
      if (sz == 0) {
        exp = 0;
      } else {
        I64 rem = off % sz;
        if (rem == 0) {
          exp = 0;
        } else {
          exp = sz - rem;
        }
      }
      "MX%05d\tMATRIX\t%d\t%d\t%d\n", n, off, sz, exp;
    }
  }
  return 0;
}
