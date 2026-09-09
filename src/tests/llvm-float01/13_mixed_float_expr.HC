/*
 * Positive fixture 13: mixed F64 expression using only authorised ops:
 *   (a + b) * c - d
 *
 * Exercises IR_FADD, IR_FMUL, IR_FSUB chained together; result is F64.
 * Per ACT §14, no conversions, no pointer memory, no division.
 */
F64 Mixed(F64 a, F64 b, F64 c, F64 d)
{
    return (a + b) * c - d;
}
