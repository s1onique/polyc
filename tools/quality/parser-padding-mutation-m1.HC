// tools/quality/parser-padding-mutation-m1.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
// MUTATION M1 -- zero-size guard broken.
//
// Variant of tools/bootstrap/selfhost-parser-padding.HC where the
// `offset % size` computation is performed BEFORE the zero-size
// guard AND the early-return for size==0 is REMOVED so the
// UB-tainted `rem` flows through to the final return.
//
// On x86_64 the `% 0` operation compiles to a `div` instruction
// which traps on dividend > 0 (SIGFPE / exit code 136), explicitly
// classifying as semantic rejection of M1 by the harness.
//
// On platforms where `% 0` returns the dividend, the final
// `return size - rem` evaluates to `0 - offset`, which the
// differential verifier catches as a divergent result.
//
// IMPORTANT: this implementation must still COMPILE, LINK, and
// non-zero-size cases must run without divergence. A mere compile
// failure is invalid (ACT §24, HALT_MUTATION_NOT_CAUSAL).

I64 BootstrapCalcPadding(I64 offset, I64 size)
{
  // Compute remainder BEFORE zero-size guard; the guard is now
  // a no-op (the return-0 branch was deleted so the UB-tainted
  // `rem` flows into the final return).
  I64 rem = offset % size;
  if (rem == 0) return 0;
  return size - rem;
}
