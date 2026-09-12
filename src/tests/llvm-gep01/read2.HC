/* src/tests/llvm-gep01/read2.HC
 *
 * ACT-POLYC-LLVM-GEP01 F2: constant positive byte index.
 *
 * Expected LLVM (per ACT §3 frozen shape):
 *   %gep = getelementptr i8, ptr %p, i64 2
 *   %ld  = load i8, ptr %gep
 *
 * Or after basic-optimisation constant folding:
 *   %ld = load i8, ptr %p   (constant-offset load)
 *
 * Source semantically equivalent to:
 *   I64 Read2(U8 *p) { return p[2]; }
 *
 * Expected runtime: Read2("ABC") -> 'C' (0x43 = 67).
 */

I64 Read2(U8 *p) {
    return p[2];
}
