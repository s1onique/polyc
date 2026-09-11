// ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01:
// RED witness for the SSA-local multi-definition rejection contract.
//
// Two stores to the same local `y` produce a local with multiple
// reaching definitions. In real SSA this needs a phi or a rejection;
// the bounded I64 spike is authorised to be SSA-only WITHOUT phi.
//
// ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6.1: RE-PURPOSED.
// The C6 IMPL replaces the broken C9 predecessor-store synthesis with
// Option-W (memory-backed mutable locals + LLVM mem2reg). Under C6,
// eligible multi-def I64 locals are HANDLED, not rejected.
//
//   before CORRECTION02:
//     witness for SSA-only multi-def rejection
//     expected: hcc rejects with LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
//
//   after CORRECTION02:
//     positive regression proving Option-W handles the defect class
//     expected: hcc emits verifier-clean LLVM IR with a single entry
//     alloca + store-at-each-original-defn-site + load-at-each-original
//     read-site, then mem2reg promotes the alloca to iterated-DF PHIs
//
// The single-def local `x` is still legal in the same function and
// remains on the legacy SSA path (no alloca for `x`), proving the
// `llOptionW_RequiresMem2Reg` gate is narrower than `llIsOptionWEligible`.
// The branch condition uses I64 comparisons to match the existing
// I64-only subset.
I64 MultiDef(I64 a, I64 b, I64 c)
{
    I64 x = a;
    I64 y = b;
    if (c > 0)
        y = a;
    return x + y;
}
