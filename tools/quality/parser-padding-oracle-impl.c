// tools/quality/parser-padding-oracle-impl.c
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
// ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
//
// C oracle for the CalcPadding differential. The oracle reaches the
// actual legacy CalcPadding via the adjacent ABI wrapper
// ParserLegacyCalcPaddingOracle in src/parser.c — it does NOT
// duplicate the formula. Terminal verdict authority belongs to the
// PolyC differential verifier
// (tools/quality/parser-padding-differential.HC).
//
// ACT §31 (predecessor) and ACT §13 / §26 (correction) require:
//   - call or expose the actual legacy CalcPadding semantics
//   - NOT implement a second independent expected-value algorithm
//   - NOT make terminal PASS/FAIL policy
//
// The oracle accepts I64 inputs (matching the PolyC ABI) and returns
// I64. Inputs are accepted as signed long long for ABI parity with the
// PolyC subject. The qualified domain is non-negative (ACT §18); the
// signed type is purely an ABI choice.
//
// Invariant: this file MUST NOT contain a verbatim copy of the
// CalcPadding formula. Any re-introduction of the formula here is a
// HALT_ORACLE_NOT_ACTUAL_LEGACY unless re-frozen by a successor
// correction ACT.

typedef long long I64;

extern long long ParserLegacyCalcPaddingOracle(long long offset, long long size);

/* Symbol/ABI identity: OracleCalcPadding is the same address as
 * ParserLegacyCalcPaddingOracle; the differential tool
 * (parser-padding-differential.HC) declares extern "c" I64
 * OracleCalcPadding(I64, I64). The oracle simply forwards every
 * call to the actual legacy authority. */
I64 OracleCalcPadding(I64 offset, I64 size)
{
  return ParserLegacyCalcPaddingOracle(offset, size);
}
