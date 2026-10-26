/* tools/quality/parser-slice02-oracle.c
 *
 * ACT-POLYC-SELFHOST-PARSER-SLICE02 C2 IMPL.
 *
 * The LEGACY C ORACLE side of the direct differential.
 *
 * The function body below is the PRODUCTION body of
 * src/parser.c:832..864, copied VERBATIM.  It is not a paraphrase and
 * not a re-implementation: the switch arms, the ordering of the tests
 * and the fall-through structure are exactly the production ones.
 *
 * The kind and keyword constants are taken from the LIVE src/lexer.h by
 * including it, so the oracle is bound to the production constants
 * rather than to a copy of them.  (src/lexer.h is header-only; it
 * declares the token kinds and includes aostr.h / containers.h /
 * list.h for the other declarations it needs, but the body of this
 * translation unit uses none of them.)
 *
 * The aliasing that matters: src/lexer.h:15 defines TK_SUPERSCRIPT as
 * 0x301 and src/lexer.h:19 defines TK_STR as 0x301 -- the SAME number.
 * The production body compares the kind BY NUMBER, so kind 0x301 is
 * TK_STR and is ACCEPTED.  Because this oracle includes the LIVE
 * header and copies the LIVE body, it inherits that behaviour
 * automatically.  The PolyC subject must match it.
 */

#include "parser-slice02-oracle.h"
#include "../../src/lexer.h"

/* ---- BEGIN VERBATIM COPY of src/parser.c:832..864 ----------------------
 *
 * The production body is copied VERBATIM.  Only the FUNCTION NAME is
 * changed, to Slice02OracleParseValidPostControlFlowToken, so that the
 * copied oracle and the real production function can be linked into the
 * SAME cross-check binary without a symbol collision.  The body is
 * otherwise character-for-character the production one.
 */
int Slice02OracleParseValidPostControlFlowToken(Slice02Lexeme *tok) {
    if (tok == NULL) return 0; /* EOF - caller raises */
    if (tok->tk_type == TK_IDENT) return 1;
    if (tok->tk_type == TK_STR) return 1;
    if (tok->tk_type == TK_PUNCT) {
        switch (tok->i64) {
            case TK_MINUS_MINUS:
            case TK_PLUS_PLUS:
            case '{':
            case ';':
            case '*':
                return 1;
        }
    }
    if (tok->tk_type == TK_KEYWORD) {
        switch (tok->i64) {
            case KW_DO:
            case KW_FOR:
            case KW_GOTO:
            case KW_IF:
            case KW_RETURN:
            case KW_SWITCH:
            case KW_WHILE:
            case KW_BREAK:
            case KW_CONTINUE:
            case KW_TRY:
            case KW_THROW:
            case KW_ASM:
                return 1;
        }
    }
    return 0;
}
/* ---- END VERBATIM COPY -------------------------------------------------- */
