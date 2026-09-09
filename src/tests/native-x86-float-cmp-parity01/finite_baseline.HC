/* ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 - finite six-op matrix.
 *
 * Captures the current finite (non-NaN) behaviour of the x86_64
 * native backend. The IMPL phase must keep these results unchanged.
 */

U0 Main() {
  "PARITY01_FINITE_MATRIX\n";
  if (1.0 == 1.0) "  1.0 == 1.0 -> TRUE  (expected true)\n";  else "  1.0 == 1.0 -> FALSE (expected true)\n";
  if (1.0 != 1.0) "  1.0 != 1.0 -> TRUE  (expected false)\n"; else "  1.0 != 1.0 -> FALSE (expected false)\n";
  if (1.0 <  2.0) "  1.0 <  2.0 -> TRUE  (expected true)\n";  else "  1.0 <  2.0 -> FALSE (expected true)\n";
  if (1.0 <= 1.0) "  1.0 <= 1.0 -> TRUE  (expected true)\n";  else "  1.0 <= 1.0 -> FALSE (expected true)\n";
  if (2.0 >  1.0) "  2.0 >  1.0 -> TRUE  (expected true)\n";  else "  2.0 >  1.0 -> FALSE (expected true)\n";
  if (2.0 >= 2.0) "  2.0 >= 2.0 -> TRUE  (expected true)\n";  else "  2.0 >= 2.0 -> FALSE (expected true)\n";
  if (1.0 == -1.0) "  1.0 == -1.0 -> TRUE  (expected false)\n"; else "  1.0 == -1.0 -> FALSE (expected false)\n";
  if (2.0 <  1.0) "  2.0 <  1.0 -> TRUE  (expected false)\n"; else "  2.0 <  1.0 -> FALSE (expected false)\n";
  if (1.0 >  2.0) "  1.0 >  2.0 -> TRUE  (expected false)\n"; else "  1.0 >  2.0 -> FALSE (expected false)\n";
  if (1.0 <  2.0) "  1.0 <  2.0 -> TRUE  (expected true)\n";   else "  1.0 <  2.0 -> FALSE (expected true)\n";
  if (2.0 <  1.0) "  2.0 <  1.0 -> TRUE  (expected false)\n";  else "  2.0 <  1.0 -> FALSE (expected false)\n";
}
