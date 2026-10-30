// tools/quality/parser-slice09-oracle-adapter.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE09 C3.
//
// THE NARROW ORACLE ADAPTER.
//
// It is compiled and linked TOGETHER WITH the legacy oracle object
// (src/parser.c compiled WITHOUT
// HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH), and it exposes ONE
// entry point to the PolyC differential:
//
//   long long Slice09LegacyStatementDispatchOracle(long long token_type,
//                                                   long long keyword_id);
//
// The adapter calls the REAL legacy decision -- the byte-identical
// legacy keyword comparison chain that was at src/parser.c:1864..1877
// and the three complex arms that follow it -- through the tiny wrapper
// that src/parser.c itself exposes adjacent to that decision.
//
// It contains NO decision table and NO decision logic.  The
// statement-constructor dispatch DECISION is the real legacy chain's,
// and the legacy source it executes is the byte-identical production
// source.
//
// F-POLYC-TOOLS: this file is a legacy C ORACLE ADAPTER, which the ACT
// explicitly permits.  It is not a tool implementation: the tool
// implementations are PolyC.

/* The REAL legacy decision, reached through the wrapper that
 * src/parser.c exposes adjacent to it. */
extern long long ParserLegacyStatementDispatchOracle(long long token_type,
                                                     long long keyword_id);

long long Slice09LegacyStatementDispatchOracle(long long token_type,
                                               long long keyword_id)
{
    return ParserLegacyStatementDispatchOracle(token_type, keyword_id);
}
