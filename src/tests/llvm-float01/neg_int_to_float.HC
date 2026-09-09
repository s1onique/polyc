/*
 * Negative fixture: integer-to-F64 conversion must remain rejected.
 * ACT §1.2 explicitly excludes IR_SITOFP / IR_UITOFP.
 *
 * PolyC's `(F64)x` cast syntax is not supported at parse time, so
 * the comparable source form is mixed-type arithmetic:
 *     F64 FromInt(I64 x) { return x + 0.0; }
 * which lowers via IR_SITOFP per src/ir.c:691-705. The LLVM backend
 * must reject this with LLVM_BACKEND_UNSUPPORTED_CONVERSION.
 *
 * If PolyC later supports explicit casts, this fixture remains valid
 * because the IR-level SITOFP lowering is unchanged.
 */
F64 FromInt(I64 x)
{
    return x + 0.0;
}
