/* ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 - special-value matrix.
 *
 * Captures the current behaviour for signed zero and infinity.
 * The IMPL phase must keep these results unchanged / correct.
 */

U0 Main() {
  F64 pos_zero = 0.0;
  F64 neg_zero = -0.0;
  F64 pos_inf  = 1.0 / 0.0;   /* +Inf */
  F64 neg_inf  = -1.0 / 0.0;  /* -Inf */

  "PARITY01_SPECIAL_VALUES\n"
  "  +0.0 == -0.0 -> %d  (expected 1)\n"
  "  +0.0 != -0.0 -> %d  (expected 0)\n"
  "  -0.0 <  +0.0 -> %d  (expected 0)\n"
  "  -0.0 <= +0.0 -> %d  (expected 1)\n"
  "  +Inf >  1.0  -> %d  (expected 1)\n"
  "  +Inf >= 1.0  -> %d  (expected 1)\n"
  "  -Inf <  1.0  -> %d  (expected 1)\n"
  "  -Inf <= 1.0  -> %d  (expected 1)\n",
    pos_zero == neg_zero, pos_zero != neg_zero,
    neg_zero < pos_zero, neg_zero <= pos_zero,
    pos_inf > 1.0, pos_inf >= 1.0,
    neg_inf < 1.0, neg_inf <= 1.0;
}
