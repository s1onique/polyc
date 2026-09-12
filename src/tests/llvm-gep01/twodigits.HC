/* src/tests/llvm-gep01/twodigits.HC
 *
 * ACT-POLYC-LLVM-GEP01 F4: B0-shaped multi-read consumer.
 *
 * Reads two distinct byte indices from the same base
 * pointer and computes the two-digit decimal value.
 *
 * Expected runtime:
 *   TwoDigits("42") = 42
 *   TwoDigits("07") = 7
 *   TwoDigits("99") = 99
 *
 * Per ACT §23, this proves the practical B0 walking
 * requirement (same base, different byte indices,
 * existing byte conversion / comparison / arithmetic)
 * without introducing a loop or token representation.
 */

I64 TwoDigits(U8 *p) {
    I64 a = p[0] - '0';
    I64 b = p[1] - '0';
    return a * 10 + b;
}
