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

  "PARITY01_NAN_MATRIX\n";
  if (nan == 1.0) "  NaN == 1.0  -> TRUE  (expected false)\n"; else "  NaN == 1.0  -> FALSE (expected false)\n";
  if (nan != 1.0) "  NaN != 1.0  -> TRUE  (expected true)\n";  else "  NaN != 1.0  -> FALSE (expected true)\n";
  if (nan <  1.0) "  NaN <  1.0  -> TRUE  (expected false)\n"; else "  NaN <  1.0  -> FALSE (expected false)\n";
  if (nan <= 1.0) "  NaN <= 1.0  -> TRUE  (expected false)\n"; else "  NaN <= 1.0  -> FALSE (expected false)\n";
  if (nan >  1.0) "  NaN >  1.0  -> TRUE  (expected false)\n"; else "  NaN >  1.0  -> FALSE (expected false)\n";
  if (nan >= 1.0) "  NaN >= 1.0  -> TRUE  (expected false)\n"; else "  NaN >= 1.0  -> FALSE (expected false)\n";

  if (1.0 == nan) "  1.0 == NaN  -> TRUE  (expected false)\n"; else "  1.0 == NaN  -> FALSE (expected false)\n";
  if (1.0 != nan) "  1.0 != NaN  -> TRUE  (expected true)\n";  else "  1.0 != NaN  -> FALSE (expected true)\n";
  if (1.0 <  nan) "  1.0 <  NaN  -> TRUE  (expected false)\n"; else "  1.0 <  NaN  -> FALSE (expected false)\n";
  if (1.0 <= nan) "  1.0 <= NaN  -> TRUE  (expected false)\n"; else "  1.0 <= NaN  -> FALSE (expected false)\n";
  if (1.0 >  nan) "  1.0 >  NaN  -> TRUE  (expected false)\n"; else "  1.0 >  NaN  -> FALSE (expected false)\n";
  if (1.0 >= nan) "  1.0 >= NaN  -> TRUE  (expected false)\n"; else "  1.0 >= NaN  -> FALSE (expected false)\n";

  if (nan == nan) "  NaN == NaN  -> TRUE  (expected false)\n"; else "  NaN == NaN  -> FALSE (expected false)\n";
  if (nan != nan) "  NaN != NaN  -> TRUE  (expected true)\n";  else "  NaN != NaN  -> FALSE (expected true)\n";
  if (nan <  nan) "  NaN <  NaN  -> TRUE  (expected false)\n"; else "  NaN <  NaN  -> FALSE (expected false)\n";
  if (nan <= nan) "  NaN <= NaN  -> TRUE  (expected false)\n"; else "  NaN <= NaN  -> FALSE (expected false)\n";
  if (nan >  nan) "  NaN >  NaN  -> TRUE  (expected false)\n"; else "  NaN >  NaN  -> FALSE (expected false)\n";
  if (nan >= nan) "  NaN >= NaN  -> TRUE  (expected false)\n"; else "  NaN >= NaN  -> FALSE (expected false)\n";
}
