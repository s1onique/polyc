/* RED-I16-TRUNC-NEGATIVE: I64 -> I16 narrowing is rejected by
 * the BYTE-MEMORY01 LLVM backend. BYTE-MEMORY01 promotes
 * IR_TRUNC to SHAPE_DEPENDENT but only for the I64 -> I8 byte
 * narrowing shape. The I64 -> I16 shape (and any other
 * narrowing) remains REJECTED with
 * LLVM_BACKEND_UNSUPPORTED_CONVERSION.
 *
 * Expected behaviour: `hcc --emit-llvm` exits 1 with the named
 * LLVM_BACKEND_UNSUPPORTED_CONVERSION diagnostic.
 */
I64 NarrowToI16(I64 x) {
    I16 y = x;
    return y;
}
