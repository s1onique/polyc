/*
 * Negative fixture: F64-to-integer conversion must remain rejected.
 * ACT §1.2 explicitly excludes IR_FPTOSI / IR_FPTOUI.
 *
 * PolyC's `(int) x` cast syntax is not supported at parse time, so
 * the comparable source form is mixed-type arithmetic via `+ 0`:
 *     I64 ToInt(F64 x) { return x + 0; }
 * which lowers via IR_FPTOSI per src/ir.c:662-672. The LLVM backend
 * must reject this with LLVM_BACKEND_UNSUPPORTED_CONVERSION.
 *
 * If PolyC later supports explicit casts, this fixture remains valid
 * because the IR-level FPTOSI lowering is unchanged.
 */
I64 ToInt(F64 x)
{
    return x + 0;
}
