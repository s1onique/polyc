/* ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 - finite six-op matrix.
 *
 * Captures the current finite (non-NaN) behaviour of the x86_64
 * native backend. The IMPL phase must keep these results unchanged.
 */

U0 Main() {
  "PARITY01_FINITE_MATRIX\n"
  "  1.0 == 1.0 -> %d  (expected 1)\n"
  "  1.0 != 1.0 -> %d  (expected 0)\n"
  "  1.0 <  2.0 -> %d  (expected 1)\n"
  "  1.0 <= 1.0 -> %d  (expected 1)\n"
  "  2.0 >  1.0 -> %d  (expected 1)\n"
  "  2.0 >= 2.0 -> %d  (expected 1)\n"
  "  1.0 == -1.0 -> %d  (expected 0)\n"
  "  2.0 <  1.0 -> %d  (expected 0)\n"
  "  1.0 >  2.0 -> %d  (expected 0)\n"
  "  1.0 <  2.0 -> %d  (expected 1)\n"
  "  2.0 <  1.0 -> %d  (expected 0)\n",
    1.0 == 1.0, 1.0 != 1.0, 1.0 < 2.0, 1.0 <= 1.0, 2.0 > 1.0, 2.0 >= 2.0,
    1.0 == -1.0, 2.0 < 1.0, 1.0 > 2.0, 1.0 < 2.0, 2.0 < 1.0;
}
