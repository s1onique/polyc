// tools/quality/parser-slice04-oracle-adapter.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE04 C2 IMPL.
//
// THE NARROW ORACLE ADAPTER.
//
// It is compiled and linked TOGETHER WITH the legacy oracle object
// (src/ast.c compiled WITHOUT HCC_USE_SELFHOST_PARSER_AST_BINOP), and
// it exposes ONE entry point to the PolyC differential:
//
//   long long Slice04LegacyBinOpOracle(long long token_value,
//                                       long long initial_output,
//                                       long long *out_after_call);
//
// The adapter:
//
//   * preinitialises the caller's output slot with `initial_output`;
//   * calls the REAL astBinOpFromToken;
//   * reports the observed success flag (the function's return value);
//   * reports the FINAL value of the output slot.
//
// It contains NO mapping table and NO decision logic.  The
// token-to-operator DECISION is the real astBinOpFromToken's, and the
// legacy source it executes is the byte-identical production source.
//
// F-POLYC-TOOLS: this file is a legacy C ORACLE ADAPTER, which the ACT
// explicitly permits ("The optional C oracle files are permitted only
// as narrow adapters or executable drivers.  They must not reimplement
// the operator mapping.").  It is not a tool implementation: the tool
// implementations are PolyC.

#include "ast.h"

/* The REAL legacy classifier under test. */
int astBinOpFromToken(s64 op, AstBinOp *result);

long long Slice04LegacyBinOpOracle(long long token_value,
                                    long long initial_output,
                                    long long *out_after_call)
{
    AstBinOp out = (AstBinOp)initial_output;
    int ok = astBinOpFromToken((s64)token_value, &out);
    if (out_after_call != NULL) *out_after_call = (long long)(int)out;
    return (long long)ok;
}
