/* RED-BYTE-5: U8 -> I64 widening via IR_ZEXT is currently
 * rejected. The IR for this source is:
 *   U8 Identity(%p1 i8 param) {
 *     ...
 *     zext     %t4 i64 tmp, %l2 i8 local  ; <-- IR_ZEXT (unsigned)
 *     ...
 *   }
 *
 * IR_ZEXT is currently LLVMBC_REJECTED with diagnostic
 * LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * (src/llvm-backend-cap.c:80). Without promotion, the return
 * type widens at the IR layer but the LLVM backend cannot lower
 * the IR_ZEXT.
 *
 * Expected behavior under BYTE-MEMORY01 §26: this should compile
 * to `zext i8 %v to i64`.
 *
 * Source semantically equivalent to:
 *   U8 Id(U8 x) { return x; }
 *
 * The IR builder's `irWidenToTargetWidth` chooses ZEXT (not SEXT)
 * because `x`'s AstType has issigned == 0 (U8).
 */
U8 Id(U8 x)
{
    return x;
}
