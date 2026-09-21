// tools/quality/parser-padding-oracle-impl.c
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
//
// C oracle for the CalcPadding differential. Mirrors the body of
// `src/parser.c::CalcPadding` exactly (frozen by
// evidence/.../c1-legacy-baseline.txt). It is a SEMANTIC REFERENCE
// only — terminal verdict authority belongs to the PolyC
// differential verifier (tools/quality/parser-padding-differential.HC).
//
// ACT §31 requires:
//   - call or expose the actual legacy CalcPadding semantics
//   - NOT implement a second independent expected-value algorithm
//   - NOT make terminal PASS/FAIL policy
//
// The oracle accepts I64 inputs (matching the PolyC ABI) and returns
// I64. Inputs are accepted as signed long long for ABI parity with the
// PolyC subject. The qualified domain is non-negative (ACT §18); the
// signed type is purely an ABI choice.
//
// Invariant: this file MUST remain byte-for-byte consistent with the
// frozen CalcPadding body. Any change to the source of this oracle
// is a HALT_C2_IMPLEMENTATION_DEFECT unless re-frozen by a successor
// correction ACT.

typedef long long I64;

I64 OracleCalcPadding(I64 offset, I64 size)
{
  /* Zero-size guard first (do not depend on platform UB for `% 0`). */
  if (size == 0) return 0;
  return offset % size == 0 ? 0 : size - offset % size;
}
