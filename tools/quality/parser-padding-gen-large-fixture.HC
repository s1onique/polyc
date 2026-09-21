// tools/quality/parser-padding-gen-large-fixture.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
//
// Generates the large-value corpus (>=24 cases) for the parser-padding
// differential. Picks offsets near 2^15, 2^16, 2^17, 2^18 and sizes 1..64.
//
// USAGE:
//   build/parser-padding-gen-large-fixture > large.tsv

I64 main(I64 argc, U8 **argv)
{
  "case_id\tclasses\toffset\tsize\texpected_padding\n";
  I64 big_offs[8];
  big_offs[0] = 32767;
  big_offs[1] = 32768;
  big_offs[2] = 65535;
  big_offs[3] = 65536;
  big_offs[4] = 131071;
  big_offs[5] = 131072;
  big_offs[6] = 262143;
  big_offs[7] = 262144;
  I64 sizes[8];
  sizes[0] = 1;
  sizes[1] = 2;
  sizes[2] = 3;
  sizes[3] = 7;
  sizes[4] = 8;
  sizes[5] = 16;
  sizes[6] = 32;
  sizes[7] = 64;
  I64 n = 0;
  for (I64 i = 0; i < 8; i = i + 1) {
    for (I64 j = 0; j < 8; j = j + 1) {
      n = n + 1;
      I64 o = big_offs[i];
      I64 s = sizes[j];
      I64 exp;
      if (s == 0) {
        exp = 0;
      } else {
        I64 rem = o % s;
        if (rem == 0) exp = 0;
        else exp = s - rem;
      }
      "LV%03d\tLARGE_OFFSET|LARGE_SIZE\t%d\t%d\t%d\n", n, o, s, exp;
    }
  }
  return 0;
}
