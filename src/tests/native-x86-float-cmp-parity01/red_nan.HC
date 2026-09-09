/* ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 - RED fixture: NaN matrix.
 *
 * Source-level check that the x86_64 native backend produces the
 * IEEE-754 / LangRef "ordered" result on NaN for EQ, NE, LT, LE,
 * and the "always false" result for GT, GE.
 *
 * Expected (per ACT):
 *   NaN == 1.0  -> 0      (RED: current = 1)
 *   NaN != 1.0  -> 1      (RED: current = 0)
 *   NaN <  1.0  -> 0      (RED: current = 1)
 *   NaN <= 1.0  -> 0      (RED: current = 1)
 *   NaN >  1.0  -> 0      (CONSERVATION: must remain 0)
 *   NaN >= 1.0  -> 0      (CONSERVATION: must remain 0)
 *
 * Built with -DHCC_PARITY01_RED=1 for the RED phase witness.
 */

#ifndef HCC_PARITY01_RED
#define HCC_PARITY01_RED 1
#endif

U0 Main() {
  F64 nan;
  U64 qnan;
  qnan = 0x7FF8000000000000;
  MemCpy(&nan, &qnan, 8);

  "PARITY01_NAN_MATRIX\n"
  "  NaN == 1.0  -> %d  (expected 0)\n"
  "  NaN != 1.0  -> %d  (expected 1)\n"
  "  NaN <  1.0  -> %d  (expected 0)\n"
  "  NaN <= 1.0  -> %d  (expected 0)\n"
  "  NaN >  1.0  -> %d  (expected 0)\n"
  "  NaN >= 1.0  -> %d  (expected 0)\n"
  "  1.0 == NaN  -> %d  (expected 0)\n"
  "  1.0 != NaN  -> %d  (expected 1)\n"
  "  1.0 <  NaN  -> %d  (expected 0)\n"
  "  1.0 <= NaN  -> %d  (expected 0)\n"
  "  1.0 >  NaN  -> %d  (expected 0)\n"
  "  1.0 >= NaN  -> %d  (expected 0)\n"
  "  NaN == NaN  -> %d  (expected 0)\n"
  "  NaN != NaN  -> %d  (expected 1)\n"
  "  NaN <  NaN  -> %d  (expected 0)\n"
  "  NaN <= NaN  -> %d  (expected 0)\n"
  "  NaN >  NaN  -> %d  (expected 0)\n"
  "  NaN >= NaN  -> %d  (expected 0)\n",
    nan == 1.0, nan != 1.0, nan <  1.0, nan <= 1.0, nan >  1.0, nan >= 1.0,
    1.0 == nan, 1.0 != nan, 1.0 <  nan, 1.0 <= nan, 1.0 >  nan, 1.0 >= nan,
    nan == nan, nan != nan, nan <  nan, nan <= nan, nan >  nan, nan >= nan;
}
