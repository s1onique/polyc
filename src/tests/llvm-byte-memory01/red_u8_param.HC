/* RED-BYTE-1: U8 parameter is currently rejected at the LLVM
 * backend's function-parameter type admission seam
 * (src/llvm-backend.c:530-532 llParamTypeSupported: only
 * IR_TYPE_I64 / IR_TYPE_PTR / IR_TYPE_F64 are accepted). The IR for
 * this source is `U8 Id(%p1 i8 param)` where i8 maps to IR_TYPE_I8.
 *
 * Expected behavior under BYTE-MEMORY01 §22: this should compile to
 * an LLVM function with an i8 parameter.
 *
 * Source semantically equivalent to:
 *   U8 Id(U8 x) { return x; }
 *
 * The IR carries the access type on dst->type and the parameter
 * type via the value's type, so the backend can read the byte
 * width from the IR rather than guessing from LLVM pointer
 * identity.
 */
U8 Id(U8 x)
{
    return x;
}
