/*
 * ACT-POLYC-LLVM-FLOAT01: this negative fixture's scope changed.
 *
 * PRE-FLOAT01 (CORE04 + predecessors): neg_f64.HC tested that an
 * F64 parameter was rejected with LLVM_BACKEND_UNSUPPORTED_TYPE.
 *
 * POST-FLOAT01: F64 parameters are SUPPORTED. The original
 * I64-returning variant now reaches the LLVM verifier, which
 * detects the f64-vs-i64 return-type mismatch and refuses with
 * LLVM_BACKEND_VERIFY_FAILED. That is a STRICTER rejection than
 * the original UNSUPPORTED_TYPE — the verifier guards the module
 * from being emitted at all — but the SPIKE-test harness greps
 * for LLVM_BACKEND_UNSUPPORTED_TYPE specifically.
 *
 * To keep the spike harness GREEN without modifying it (per
 * Factory F7 / ACT §22 allowed files: the spike harness is
 * explicitly listed as conservable), this fixture is now scoped
 * to a STILL-rejected shape: an F32 parameter, which the F64-only
 * supported subset cannot lower.
 *
 * The original F64-with-I64-return rejection is now covered by
 * scripts/quality/llvm-float01-test.sh (mixed-type return is
 * rejected with LLVM_BACKEND_VERIFY_FAILED, which is a strict
 * superset of UNSUPPORTED_TYPE semantically).
 */
I64 F32Arith(F32 a, F32 b)
{
    return a + b;
}
