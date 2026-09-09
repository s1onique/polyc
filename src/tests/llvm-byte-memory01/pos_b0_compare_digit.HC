/* POS-B0-COMPARE-DIGIT: B0-shaped byte load + comparison + digit path.
 *
 * This fixture exercises the full B0 lexer byte-load fragment:
 *   load byte from pointer
 *   promote via ZEXT (unsigned byte -> I64)
 *   compare to a constant
 *   branch
 *   subtract digit offset
 *   multiply-accumulate
 *
 * No pointer increment. No indexing. Pure byte-load fragment.
 *
 * Source semantically equivalent to:
 *
 *   I64 ReadDigit(U8 *p) {
 *     U8 c = *p;
 *     I64 d = 0;
 *     if (c >= '0') {
 *       if (c <= '9') {
 *         d = (I64)c - (I64)'0';
 *       }
 *     }
 *     return d;
 *   }
 *
 *   I64 AccDigit(I64 acc, U8 *p) {
 *     U8 c = *p;
 *     if (c >= '0') {
 *       if (c <= '9') {
 *         I64 d = (I64)c - (I64)'0';
 *         acc = acc * 10 + d;
 *       }
 *     }
 *     return acc;
 *   }
 */
I64 ReadDigit(U8 *p) {
    U8 c = *p;
    I64 d = 0;
    if (c >= '0') {
        if (c <= '9') {
            d = c - '0';
        }
    }
    return d;
}

I64 AccDigit(I64 acc, U8 *p) {
    U8 c = *p;
    if (c >= '0') {
        if (c <= '9') {
            I64 d = c - '0';
            acc = acc * 10 + d;
        }
    }
    return acc;
}
