/* src/tests/llvm-gep01/readat.HC
 *
 * ACT-POLYC-LLVM-GEP01 F3: dynamic I64 byte index.
 *
 * Expected LLVM (per ACT §3 frozen shape):
 *   %gep = getelementptr i8, ptr %p, i64 %i
 *   %ld  = load i8, ptr %gep
 *
 * This is the closure-critical fixture. The dynamic
 * index is NOT subject to constant folding, so the
 * getelementptr MUST appear in the emitted LLVM.
 *
 * Source semantically equivalent to:
 *   I64 ReadAt(U8 *p, I64 i) { return p[i]; }
 *
 * Expected runtime:
 *   ReadAt("012345", 0) = '0' = 48
 *   ReadAt("012345", 3) = '3' = 51
 *   ReadAt("012345", 5) = '5' = 53
 */

I64 ReadAt(U8 *p, I64 i) {
    return p[i];
}
