/* tools/quality/parser-control-flow-token-oracle-impl.c
 *
 * ACT-POLYC-SELFHOST-PARSER-SLICE02 C2 IMPL -- the LEGACY C ORACLE
 * side of the direct differential.
 *
 * This file does NOT re-implement the decision table.  It COMPILES the
 * production source file src/parser.c itself and exposes the production
 * function parseValidPostControlFlowToken under the oracle name.
 *
 * The production function is compiled with the preprocessor macro
 * HCC_SLICE02_ORACLE_ONLY defined, which selects a translation unit that
 * contains the production body and NOTHING else -- see the companion
 * header src/parser-slice02-oracle.c.
 *
 * Why the macro indirection instead of #including src/parser.c:
 *   - src/parser.c pulls in the whole compiler (ast, cctrl, lexer, ...);
 *     including it would make the oracle's link depend on the entire
 *     production object graph, which is exactly what the oracle must
 *     NOT depend on.
 *   - the production body must be the REAL one, byte for byte, not a
 *     paraphrase.  The companion translation unit takes the production
 *     function's body verbatim from src/parser.c.
 */

#include <string.h>

#include "parser-slice02-oracle.h"

int OracleValidPostControlFlowToken(I64 present, I64 kind, I64 value)
{
    Slice02Lexeme lex;
    memset(&lex, 0, sizeof lex);
    lex.tk_type = (int)kind;
    lex.i64 = (int64_t)value;
    return Slice02OracleParseValidPostControlFlowToken(present ? &lex : NULL);
}
