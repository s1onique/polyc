/* RED-BYTE-3: U8 pointer parameter is currently rejected at the
 * LLVM backend's function-parameter type admission seam
 * (src/llvm-backend.c:530-532). The IR for this source is
 * `U8 ReadByte(%p1 ptr param)` — IR_TYPE_PTR is admitted (per
 * MEMORY01) but the access type IR_TYPE_I8 is not.
 *
 * Expected behavior under BYTE-MEMORY01 §23: the function pointer
 * parameter should compile to LLVM opaque ptr; the dereference
 * of `*p` should compile to `load i8, ptr %p`.
 *
 * Source semantically equivalent to:
 *   U8 ReadByte(U8 *p) { return *p; }
 */
U8 ReadByte(U8 *p)
{
    return *p;
}
