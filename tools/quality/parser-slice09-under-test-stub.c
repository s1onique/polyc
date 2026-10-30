// tools/quality/parser-slice09-under-test-stub.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE09 C3.
//
// THE UNDER-TEST STUB.
//
// The PolyC differential links EXACTLY ONE decision object: the
// generation's own object.  That object supplies the decision under
// one of two symbol names:
//
//   the legacy C oracle object (src/parser.c compiled WITHOUT
//   HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH) exposes
//   ParserLegacyStatementDispatchOracle;
//
//   the compiled PolyC generations expose
//   BootstrapStatementDispatch.
//
// This stub exposes the SINGLE name the comparison layer calls
// (Slice09StatementDispatchUnderTest) and forwards to whichever of the
// two the linked object provides.
//
// It contains NO decision table and NO decision logic.  It is a
// rename, not a re-implementation.
//
// HOW THE LINK IS MADE TO SELECT ONE AND NOT THE OTHER
// ====================================================
//
// The PolyC generations are linked into the differential's OWN
// executable.  The legacy oracle object is a WHOLE TRANSLATION UNIT
// with many symbols, so it cannot be linked into the same executable
// as the PolyC generation without pulling in the whole parser.
//
// Therefore the comparison layer calls the DECISION SYMBOL DIRECTLY
// for the PolyC generations, and the G0 differential links the legacy
// oracle object with a stub that renames the oracle's wrapper.
//
// The Makefile builds FOUR separate differential executables, one per
// generation, and each links the decision object that belongs to that
// generation.  See the SLICE09_GEN_DIFF definition in the Makefile.
//
// F-POLYC-TOOLS: this file is a legacy C SHIM, which the ACT
// explicitly permits.  It is not a tool implementation: the tool
// implementations are PolyC.

#ifdef SLICE09_UNDER_TEST_IS_LEGACY_ORACLE
/* The G0 build: the decision is the REAL legacy C chain, reached
 * through the wrapper src/parser.c exposes adjacent to it. */
extern long long ParserLegacyStatementDispatchOracle(long long token_type,
                                                     long long keyword_id);

long long Slice09StatementDispatchUnderTest(long long token_type,
                                             long long keyword_id)
{
    return ParserLegacyStatementDispatchOracle(token_type, keyword_id);
}
#else
/* The G1/G2/G3 builds: the decision is the compiled PolyC component.
 * Its exported name is BootstrapStatementDispatch, so the comparison
 * layer's call is renamed to the single under-test name. */
extern long long BootstrapStatementDispatch(long long token_type,
                                            long long keyword_id);

long long Slice09StatementDispatchUnderTest(long long token_type,
                                             long long keyword_id)
{
    return BootstrapStatementDispatch(token_type, keyword_id);
}
#endif
