/*
 * RED-1: F64 parameter + F64 return unsupported by LLVM backend.
 *
 * Source semantically equivalent to:
 *   F64 Identity(F64 x) {
 *       return x;
 *   }
 *
 * Expected pre-FLOAT01:
 *   rc != 0
 *   named diagnostic LLVM_BACKEND_UNSUPPORTED_TYPE on stderr
 *   no .ll output
 *   no native fallback
 *
 * Expected post-FLOAT01:
 *   rc == 0
 *   verifier-clean LLVM 22 IR
 *   define double @Identity(double %x) { ret double %x }
 */
F64 Identity(F64 x)
{
    return x;
}
