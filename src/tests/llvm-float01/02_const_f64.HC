/*
 * RED-2: F64 constant unsupported by LLVM backend.
 *
 * Source semantically equivalent to:
 *   F64 Const() { return 3.14; }
 *
 * Expected pre-FLOAT01:
 *   rc != 0
 *   named diagnostic LLVM_BACKEND_UNSUPPORTED_TYPE or LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH
 *   on stderr
 *
 * Expected post-FLOAT01:
 *   rc == 0
 *   verifier-clean LLVM 22 IR
 *   constant materialised from neutral-IR as._f64 (double bit pattern for 3.14)
 */
F64 Const()
{
    return 3.14;
}
