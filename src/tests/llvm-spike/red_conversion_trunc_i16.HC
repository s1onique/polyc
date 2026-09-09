// ACT-POLYC-LLVM-CORE01-CORRECTION01 RED-2 (AC06, refresh per
// ACT-POLYC-LLVM-BYTE-MEMORY01):
//
// A narrowing integer conversion lowers to IR_TRUNC. BYTE-MEMORY01
// promotes IR_TRUNC to SHAPE_DEPENDENT for the I64 -> I8 shape
// (the natural byte-local narrowing), so the original
// `red_conversion_trunc.HC` fixture (which narrows I64 -> I8) is
// now ADMITTED and is no longer a valid RED fixture.
//
// This fixture narrows I64 -> I16 (a shape BYTE-MEMORY01 does
// NOT admit) and must FAIL with the named diagnostic
// LLVM_BACKEND_UNSUPPORTED_CONVERSION.
I64 NarrowToI16(I64 x) {
    I16 y = x;
    return y;
}
