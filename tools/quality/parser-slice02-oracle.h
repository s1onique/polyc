/* tools/quality/parser-slice02-oracle.h
 *
 * ACT-POLYC-SELFHOST-PARSER-SLICE02 C2 IMPL.
 *
 * The Lexeme shape the oracle uses is the REAL one from src/lexer.h:172
 * ..187, reduced to the two fields the production function reads
 * (tk_type and i64).  The full production struct is not required and is
 * not used: the production body reads no other field.
 */

#ifndef PARSER_SLICE02_ORACLE_H
#define PARSER_SLICE02_ORACLE_H

#include <stdint.h>

/* The PolyC ABI type. In C it is the 64-bit signed integer. */
typedef int64_t I64;

typedef struct Slice02Lexeme {
    int tk_type;
    int len;
    int line;
    int col;
    char *start;
    int ishex;
    union { int64_t i64; double f64; };
} Slice02Lexeme;

/* The PRODUCTION body, copied verbatim from src/parser.c (only the
 * function name differs, so that the copied oracle and the real
 * production function can be linked into the same cross-check binary). */
int Slice02OracleParseValidPostControlFlowToken(Slice02Lexeme *tok);

/* The oracle's exported entry point.
 *
 * It takes the SAME three scalars as the PolyC subject
 * BootstrapValidPostControlFlowToken, so that the PolyC comparison
 * layer can call both with one call shape and no adapter.  The oracle
 * builds the production Lexeme itself and passes NULL for the absent
 * token case. */
int OracleValidPostControlFlowToken(I64 present, I64 kind, I64 value);

#endif /* PARSER_SLICE02_ORACLE_H */
