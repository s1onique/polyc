// The G0 LEGACY REFERENCE component object.
//
// ACT-POLYC-SELFHOST-PARSER-SLICE03 C3.
//
// This is the LEGACY C implementation of the operator precedence
// decision, compiled as a standalone object so that it can be
// compared against the PolyC generations.
//
// The body is the VERBATIM legacy switch from src/prslib.c, with the
// constant names bound to the LIVE src/lexer.h values.
//
// G0 is an INTENTIONAL LEGACY REFERENCE.  It is built from C, not from
// PolyC, so it is NOT expected to be byte-identical to G1/G2/G3.  The
// permitted G0-versus-PolyC comparison contract is SEMANTIC (the oracle
// differential), not byte-identity.
#include "../../../src/lexer.h"

int Slice03LegacyOperatorPrecedence(long long punct_value)
{
    switch (punct_value) {
    case TK_ARROW:
    case '.':
    case '(':
        return 1;

    case '[':
        return 2;

    case '!':
    case '~':
    case TK_PLUS_PLUS:
    case TK_MINUS_MINUS:
    case TK_PRE_PLUS_PLUS:
    case TK_PRE_MINUS_MINUS:
        return 3;

    case '*': case '/': case '%':
        return 4;

    case '-':
    case '+':
        return 5;

    case TK_SHL:
    case TK_SHR:
        return 6;

    case TK_LESS_EQU:
    case TK_GREATER_EQU:
    case '<':
    case '>':
        return 7;

    case TK_EQU_EQU:
    case TK_NOT_EQU:
        return 8;

    case '^':
        return 9;
    case '&':
        return 10;
    case '|':
        return 11;

    case TK_AND_AND:
        return 12;

    case TK_OR_OR:
        return 13;

    case '=':
    case TK_ADD_EQU:
    case TK_SUB_EQU:
    case TK_MUL_EQU:
    case TK_DIV_EQU:
    case TK_MOD_EQU:
    case TK_AND_EQU:
    case TK_OR_EQU:
    case TK_XOR_EQU:
    case TK_SHL_EQU:
    case TK_SHR_EQU:
        return 14;

    default:
        return -1;
    }
}
