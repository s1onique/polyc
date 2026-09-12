/* src/tests/llvm-gep01/read0.HC
 *
 * ACT-POLYC-LLVM-GEP01 F1: constant-zero byte index.
 *
 * Expected LLVM (per ACT §3 frozen shape):
 *   %ld = load i8, ptr %p          (constant 0 folded)
 *
 * GEP01 contract:
 *   base pointer + const 0 + byte element
 *   const-0 index may fold into a bare `load i8, ptr`.
 *   No getelementptr is REQUIRED in this fixture; the
 *   address-arithmetic IR_IADD may be optimised away.
 *
 * Source semantically equivalent to:
 *   I64 Read0(U8 *p) { return p[0]; }
 */

I64 Read0(U8 *p) {
    return p[0];
}
