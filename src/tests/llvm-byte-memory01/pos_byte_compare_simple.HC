/* POS-B0-COMPARE-SIMPLE: byte load + comparison, no conditional return.
 *
 * This fixture exercises the byte load + comparison path without
 * the IR builder's collapse optimization for conditional byte
 * returns. The function returns a single boolean based on a byte
 * comparison.
 *
 * Source semantically equivalent to:
 *
 *   I64 IsDigit(U8 *p) {
 *     U8 c = *p;
 *     if (c >= '0') {
 *       if (c <= '9') {
 *         return 1;
 *       }
 *     }
 *     return 0;
 *   }
 *
 * The return value is a literal (not a conditional byte local),
 * so the IR builder's collapse pattern does not produce SSA holes.
 */
I64 IsDigit(U8 *p) {
    U8 c = *p;
    if (c >= '0') {
        if (c <= '9') {
            return 1;
        }
    }
    return 0;
}
