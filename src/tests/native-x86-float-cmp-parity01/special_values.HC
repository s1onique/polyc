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

  "PARITY01_SPECIAL_VALUES\n";
  if (pos_zero == neg_zero) "  +0.0 == -0.0 -> TRUE  (expected true)\n";  else "  +0.0 == -0.0 -> FALSE (expected true)\n";
  if (pos_zero != neg_zero) "  +0.0 != -0.0 -> TRUE  (expected false)\n"; else "  +0.0 != -0.0 -> FALSE (expected false)\n";
  if (neg_zero <  pos_zero) "  -0.0 <  +0.0 -> TRUE  (expected false)\n"; else "  -0.0 <  +0.0 -> FALSE (expected false)\n";
  if (neg_zero <= pos_zero) "  -0.0 <= +0.0 -> TRUE  (expected true)\n";  else "  -0.0 <= +0.0 -> FALSE (expected true)\n";
  if (pos_inf  >  1.0)     "  +Inf >  1.0  -> TRUE  (expected true)\n";  else "  +Inf >  1.0  -> FALSE (expected true)\n";
  if (pos_inf  >= 1.0)     "  +Inf >= 1.0  -> TRUE  (expected true)\n";  else "  +Inf >= 1.0  -> FALSE (expected true)\n";
  if (neg_inf  <  1.0)     "  -Inf <  1.0  -> TRUE  (expected true)\n";  else "  -Inf <  1.0  -> FALSE (expected true)\n";
  if (neg_inf  <= 1.0)     "  -Inf <= 1.0  -> TRUE  (expected true)\n";  else "  -Inf <= 1.0  -> FALSE (expected true)\n";
}
