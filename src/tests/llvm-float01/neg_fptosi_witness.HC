/*
 * Negative fixture: F64-to-I64 conversion MUST be rejected with
 * diagnostic naming IR_FPTOSI.
 *
 * The IR-level opcode we are exercising here is IR_FPTOSI (F64 -> I64
 * saturation), produced by the AST_ASSIGN lowering at src/ir.c:944:
 *
 *   if (from_float && to_int) {
 *       ...
 *       irBlockAddInstr(ctx, irInstrNew(IR_FPTOSI, dst, src, NULL));
 *
 * `j = x` where x is F64 and j is I64 lowers to IR_FPTOSI.  The
 * LLVM backend's IR_FPTOSI arm (src/llvm-backend.c:1660) REJECTs
 * with diagnostic `(opcode fptosi)`.
 *
 * This fixture supplements neg_float_to_int.HC (which actually trips
 * on IR_SITOFP for the int->float 0.0 conversion rather than the
 * FPTOSI we wanted) by providing an independent IR_FPTOSI witness.
 */
I64 ToInt(F64 x)
{
    I64 j;
    j = x;
    return j;
}
