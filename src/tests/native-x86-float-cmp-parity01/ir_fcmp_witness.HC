/* ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 - IR_FCMP witness.
 *
 * The common HolyC pattern `if (a OP b)` lowers to IR_CMP_BR
 * (branch-form), which carries the masked SETcc composition. The
 * IR_FCMP-only path (used when the result is stored / passed to
 * printf-style variadic args) is exercised separately by this
 * fixture.
 *
 * For each predicate, the FCMP result is fed directly to printf's
 * %d format - bypassing the broken IR_FPTOSI path that some
 * `I64 x = ...; print x;` patterns hit. This gives a clean
 * observable witness for the IR_FCMP dispatch arm in src/x86_64.c
 * (and the JIT IR_FCMP arm in src/x86_64-jit.c via -jit).
 */
U0 Main() {
  F64 nan;
  U64 qnan = 0x7FF8000000000000;
  MemCpy(&nan, &qnan, 8);

  "PARITY01_IR_FCMP\n";
  "  NaN == 1.0 -> %d (expected 0)\n", nan == 1.0;
  "  NaN != 1.0 -> %d (expected 1)\n", nan != 1.0;
  "  NaN <  1.0 -> %d (expected 0)\n", nan <  1.0;
  "  NaN <= 1.0 -> %d (expected 0)\n", nan <= 1.0;
  "  NaN >  1.0 -> %d (expected 0)\n", nan >  1.0;
  "  NaN >= 1.0 -> %d (expected 0)\n", nan >= 1.0;

  "  1.0 == NaN -> %d (expected 0)\n", 1.0 == nan;
  "  1.0 != NaN -> %d (expected 1)\n", 1.0 != nan;
  "  1.0 <  NaN -> %d (expected 0)\n", 1.0 <  nan;
  "  1.0 <= NaN -> %d (expected 0)\n", 1.0 <= nan;
  "  1.0 >  NaN -> %d (expected 0)\n", 1.0 >  nan;
  "  1.0 >= NaN -> %d (expected 0)\n", 1.0 >= nan;

  "  NaN == NaN -> %d (expected 0)\n", nan == nan;
  "  NaN != NaN -> %d (expected 1)\n", nan != nan;
  "  NaN <  NaN -> %d (expected 0)\n", nan <  nan;
  "  NaN <= NaN -> %d (expected 0)\n", nan <= nan;
  "  NaN >  NaN -> %d (expected 0)\n", nan >  nan;
  "  NaN >= NaN -> %d (expected 0)\n", nan >= nan;

  /* Finite baseline (no NaN) - used to detect the encoder bug
   * which gives the right answer for NaN by coincidence. */
  "  1.0 == 1.0 -> %d (expected 1)\n", 1.0 == 1.0;
  "  1.0 != 1.0 -> %d (expected 0)\n", 1.0 != 1.0;
  "  1.0 <  2.0 -> %d (expected 1)\n", 1.0 <  2.0;
  "  1.0 <= 1.0 -> %d (expected 1)\n", 1.0 <= 1.0;
  "  2.0 >  1.0 -> %d (expected 1)\n", 2.0 >  1.0;
  "  2.0 >= 2.0 -> %d (expected 1)\n", 2.0 >= 2.0;
}
