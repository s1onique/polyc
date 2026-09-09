/* RED-3: I64 pointer write through a pointer parameter is currently
 * unsupported by the LLVM backend. The IR for `*p = x` includes
 * `store* %l2 ptr local, %x2 i64 param` (IR_STORE_DEREF). Currently
 * the pointer-parameter type check fails first.
 *
 * Source semantically equivalent to:
 *   I64 Store(I64 *p, I64 x)
 *   {
 *       *p = x;
 *       return 0;
 *   }
 */
I64 Store(I64 *p, I64 x)
{
    *p = x;
    return 0;
}
