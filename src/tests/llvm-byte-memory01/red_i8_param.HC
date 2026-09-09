/* RED-BYTE-2: I8 parameter is currently rejected at the LLVM
 * backend's function-parameter type admission seam. The IR for
 * this source is `I8 IdI8(%p1 i8 param)` where i8 maps to
 * IR_TYPE_I8 with the signed-vs-unsigned distinction carried by
 * IR_SEXT (vs IR_ZEXT for U8) at widening sites.
 *
 * Expected behavior under BYTE-MEMORY01 §22: this should compile
 * to an LLVM function with an i8 parameter.
 *
 * Source semantically equivalent to:
 *   I8 IdI8(I8 x) { return x; }
 */
I8 IdI8(I8 x)
{
    return x;
}
