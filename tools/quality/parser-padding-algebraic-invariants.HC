// tools/quality/parser-padding-algebraic-invariants.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
//
// PolyC-native algebraic-invariant verifier for CalcPadding.
//
// This tool is the AC18 proof-repair. It exercises
// BootstrapCalcPadding directly across the bounded matrix
//   offset in 0..255
//   size   in 0..64
// and mechanically checks four predicates WITHOUT invoking,
// reading, linking, forking, or otherwise observing the C
// oracle or any predecessor differential TSV.
//
// Frozen invariants (ACT §6):
//   I1  size == 0                            => padding == 0
//   I2  (qualified domain)                   => padding >= 0
//   I3  size > 0                             => padding < size
//   I4  size > 0                             => (offset + padding) % size == 0
//
// Domain:
//   offset in 0..255   (256 values)
//   size   in 0..64    (65  values)
//   total  = 256 * 65  = 16640 cases
//
// Mandatory terminal tokens (§19, ACT):
//   TOTAL=16640
//   ZERO_SIZE_CHECKED=256
//   ZERO_SIZE_FAIL=0
//   NONNEGATIVE_CHECKED=16640
//   NONNEGATIVE_FAIL=0
//   RANGE_CHECKED=16384
//   RANGE_FAIL=0
//   ALIGNMENT_CHECKED=16384
//   ALIGNMENT_FAIL=0
//   ALGEBRAIC_INVARIANT_FAIL=0
//   STATUS=PASS
//
// Exit code: 0 on PASS, 1 if any invariant fails.
//
// Build target: make build/parser-padding-algebraic-invariants
//
// Forbidden wiring (per ACT §6):
//   * invoke OracleCalcPadding or any oracle symbol
//   * read any oracle output (file, pipe, env, etc.)
//   * derive expected values from the predecessor differential TSV
//   * import libtos runtime oracle functions

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 BootstrapCalcPadding(I64 offset, I64 size);

#define OFFSET_MIN 0
#define OFFSET_MAX 255
#define SIZE_MIN   0
#define SIZE_MAX   64

I64 main(I64 argc, U8 **argv)
{
  I64 total                = 0;
  I64 zero_size_checked    = 0;
  I64 zero_size_fail       = 0;
  I64 nonnegative_checked  = 0;
  I64 nonnegative_fail     = 0;
  I64 range_checked        = 0;
  I64 range_fail           = 0;
  I64 alignment_checked    = 0;
  I64 alignment_fail       = 0;

  for (I64 off = OFFSET_MIN; off <= OFFSET_MAX; off = off + 1) {
    for (I64 sz = SIZE_MIN; sz <= SIZE_MAX; sz = sz + 1) {
      total = total + 1;

      // Direct call to the PolyC subject. No oracle.
      I64 pad = BootstrapCalcPadding(off, sz);

      // I1 — zero size
      if (sz == 0) {
        zero_size_checked = zero_size_checked + 1;
        if (pad != 0) zero_size_fail = zero_size_fail + 1;
      }

      // I2 — non-negative (qualified domain; this holds trivially
      // for non-negative inputs and the PolyC subject which never
      // returns negative on the qualified domain)
      nonnegative_checked = nonnegative_checked + 1;
      if (pad < 0) nonnegative_fail = nonnegative_fail + 1;

      // I3 — range (size > 0 => 0 <= pad < size)
      if (sz > 0) {
        range_checked = range_checked + 1;
        if (pad < 0) range_fail = range_fail + 1;
        if (pad >= sz) range_fail = range_fail + 1;

        // I4 — alignment (size > 0 => (offset + pad) % size == 0)
        alignment_checked = alignment_checked + 1;
        if (((off + pad) % sz) != 0) alignment_fail = alignment_fail + 1;
      }
    }
  }

  I64 algebraic_invariant_fail = zero_size_fail + nonnegative_fail +
                                 range_fail + alignment_fail;

  "TOTAL=%d\n", total;
  "ZERO_SIZE_CHECKED=%d\n", zero_size_checked;
  "ZERO_SIZE_FAIL=%d\n", zero_size_fail;
  "NONNEGATIVE_CHECKED=%d\n", nonnegative_checked;
  "NONNEGATIVE_FAIL=%d\n", nonnegative_fail;
  "RANGE_CHECKED=%d\n", range_checked;
  "RANGE_FAIL=%d\n", range_fail;
  "ALIGNMENT_CHECKED=%d\n", alignment_checked;
  "ALIGNMENT_FAIL=%d\n", alignment_fail;
  "ALGEBRAIC_INVARIANT_FAIL=%d\n", algebraic_invariant_fail;
  if (algebraic_invariant_fail == 0) {
    "STATUS=PASS\n";
    "AC18=PASS\n";
    "ORACLE_DEPENDENCY=0\n";
    return 0;
  }
  "STATUS=FAIL\n";
  "AC18=FAIL\n";
  "ORACLE_DEPENDENCY=0\n";
  return 1;
}
