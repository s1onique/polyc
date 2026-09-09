/* RED-1: Pointer parameter is currently unsupported by the LLVM
 * backend (src/llvm-backend.c:517-554 rejects non-IR_TYPE_I64
 * parameter types). The expected behavior under MEMORY01 is for
 * this to compile to an LLVM opaque-ptr function parameter.
 *
 * Source semantically equivalent to:
 *   I64 PtrParam(I64 *p)
 *   {
 *       return 0;
 *   }
 */
I64 PtrParam(I64 *p)
{
    return 0;
}
