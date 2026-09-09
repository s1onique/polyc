/* RED-2: I64 pointer read through a pointer parameter is currently
 * unsupported by the LLVM backend. The IR for `*p` is
 * `load* %t4 i64 tmp, %p1 ptr param` (IR_LOAD_DEREF with dst
 * type IR_TYPE_I64 and addr type IR_TYPE_PTR). Currently the
 * pointer-parameter type check at src/llvm-backend.c:517 fails
 * first with LLVM_BACKEND_UNSUPPORTED_TYPE before reaching the
 * IR_LOAD_DEREF dispatch arm.
 *
 * Source semantically equivalent to:
 *   I64 Load(I64 *p)
 *   {
 *       return *p;
 *   }
 */
I64 Load(I64 *p)
{
    return *p;
}
