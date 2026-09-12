/* src/tests/llvm-gep01/i64idx.HC
 *
 * ACT-POLYC-LLVM-GEP01 F5: NON-I8 element negative boundary.
 *
 * Per ACT §11: "non-I8 element GEP -> NOT authorized in GEP01".
 *
 * The IR's address-mode fusion pass folds the
 * (imul index 8) + (iadd ptr base) pair into
 * IR_LOAD_DEREF::idx+scale=8. The existing IR_LOAD_DEREF
 * guard at src/llvm-backend.c:2930-2941 rejects this with
 * LLVM_BACKEND_UNSUPPORTED_POINTER. GEP01 must NOT silently
 * admit this shape; the existing rejection must be preserved.
 *
 * Source semantically equivalent to:
 *   I64 ReadI64(I64 *p, I64 i) { return p[i]; }
 */

I64 ReadI64(I64 *p, I64 i) {
    return p[i];
}
