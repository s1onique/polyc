// tools/quality/parser-slice08-oracle-adapter.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE08 C1.
//
// THE NARROW ORACLE ADAPTER.
//
// It is compiled and linked TOGETHER WITH the legacy oracle object
// (src/parser.c compiled WITHOUT
// HCC_USE_SELFHOST_PARSER_DEFAULT_ARM_TERMINATES), and it exposes ONE
// entry point to the PolyC differential:
//
//   long long Slice08LegacyDefaultArmOracle(long long ast_kind);
//
// The adapter calls the REAL legacy decision -- the byte-identical
// legacy condition that was at src/parser.c:1683..1684 -- through the
// tiny wrapper that src/parser.c itself exposes next to that decision.
//
// It contains NO decision table and NO decision logic.  The
// default-arm termination DECISION is the real legacy condition's,
// and the legacy source it executes is the byte-identical production
// source.
//
// WHY AN ADAPTER AT ALL, RATHER THAN A DRIVER
// ==========================================
//
// The decision is NOT a function in the original source: it was one
// source condition inside parseDefaultStatement.  src/parser.c
// therefore exposes a tiny ABI wrapper adjacent to that decision
// (ParserLegacyDefaultArmTerminatesOracle), exactly as the already
// migrated authorities do (ParserLegacySwitchArmTerminatesOracle,
// ParserLegacyCompoundBlockAppendsOracle).  The wrapper forwards to
// the real decision, so the oracle reaches the ACTUAL legacy authority
// rather than a copy of it.
//
// F-POLYC-TOOLS: this file is a legacy C ORACLE ADAPTER, which the ACT
// explicitly permits.  It is not a tool implementation: the tool
// implementations are PolyC.

/* The REAL legacy decision, reached through the wrapper that
 * src/parser.c exposes adjacent to it. */
extern long long ParserLegacyDefaultArmTerminatesOracle(long long ast_kind);

long long Slice08LegacyDefaultArmOracle(long long ast_kind)
{
    return ParserLegacyDefaultArmTerminatesOracle(ast_kind);
}
