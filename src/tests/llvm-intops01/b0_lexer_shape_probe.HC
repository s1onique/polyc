// ACT-POLYC-LLVM-INTOPS01 — B0-shape probe (no-pointer-arith).
//
// Exercises ONLY the integer operations the smallest credible B0 lexer
// can be expressed with, given the current MEMORY01 boundaries:
//
//   IR_IADD, IR_ISUB, IR_IMUL, IR_ICMP, IR_BR, IR_CALL, IR_RET,
//   IR_LOAD_DEREF, IR_STORE_DEREF (via MEMORY01).
//
// This fixture compiles to clean LLVM IR using only ops already
// proven SUPPORTED in the LLVM backend
// (LLVM-SPIKE01-RESUME01, CORE04-RESUME01, MEMORY01).
//
// Limitation acknowledged: the full B0 lexer needs pointer arithmetic
// (`*(src + n)`) to walk the source buffer, which MEMORY01 currently
// REJECTS. That gap is the planned BYTE-MEMORY01 / GEP01 ACT scope,
// NOT the INTOPS01 scope. INTOPS01 is the integer-ops ACT.

I64 LexOneToken(I64 *cur, I64 limit, I64 *src, I64 *out_kind, I64 *out_value)
{
    I64 c, cur_v;
    c = *src;
    if (c >= 48) {
        if (c <= 57) {
            *out_kind = 2;
            *out_value = c - 48;
            cur_v = *cur;
            cur_v = cur_v + 1;
            *cur = cur_v;
            return 1;
        }
    }
    *out_kind = 3;
    *out_value = 0;
    return 0;
}

I64 LexMain(I64 *cur, I64 limit, I64 *src, I64 *out_kind, I64 *out_value)
{
    return LexOneToken(cur, limit, src, out_kind, out_value);
}
