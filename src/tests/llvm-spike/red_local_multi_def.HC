// ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01:
// RED witness for the SSA-local multi-definition rejection contract.
//
// Two stores to the same local `y` produce a local with multiple
// reaching definitions. In real SSA this needs a phi or a rejection;
// the bounded I64 spike is authorised to be SSA-only WITHOUT phi.
//
// The bounded backend MUST reject this shape with
// LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL (non-zero exit). It MUST NOT
// emit verifier-clean LLVM IR that picks whichever store was
// lowered last.
//
// A single-def local (`x`) is still legal in the same function
// to make sure the rejection is specifically about the multi-def
// pattern, not about locals in general. The branch condition uses
// I64 comparisons to match the existing I64-only subset.
I64 MultiDef(I64 a, I64 b, I64 c)
{
    I64 x = a;
    I64 y = b;
    if (c > 0)
        y = a;
    return x + y;
}
