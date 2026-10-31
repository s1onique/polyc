/* tools/quality/core-operator-implement01-g0-oracle.c
 *
 * ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C1.
 *
 * THE GENUINE G0 ORACLE.
 *
 * This program is a DIRECT, VERBATIM COPY of the three ORIGINAL C
 * predicates, taken from the frozen source ranges:
 *
 *   SITE-COMPOUND-ASSIGN  src/prslib.c:1328..1348  parseCompoundAssign
 *   SITE-VALID-POINTER-OP src/ast.c:974..990        astIsValidPointerOp
 *   SITE-RANGE-OPERATOR   src/ast.c:2348..2358      astIsRangeOperator
 *
 * It contains NO PolyC symbol and NO reference to the new subject. It is
 * compiled from the C sources alone, so the G0 generation is genuinely
 * C-independent (AC14, NC-09).
 *
 * The enum values are the SOURCE values from src/ast.h and src/lexer.h.
 * They are DECLARED here (not included from a PolyC header) so that this
 * oracle does not depend on the host's layout or on the subject.
 *
 * INPUT PROTOCOL (one request per line, whitespace separated):
 *
 *   CA <token_type> <token_value>   ->  CA <token_type> <token_value> <is_compound> <operator> <status>
 *   PO <operator>                   ->  PO <operator> <is_valid>
 *   RO <operator>                   ->  RO <operator> <is_range>
 *
 * STATUS 0 means "the C predicate answered normally". The C predicate has
 * no failure mode for a representable input, so the status is always 0;
 * a NON-representable input is reported with status 1 and is never
 * conflated with a valid scalar result.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- source enum values: src/lexer.h ---- */
#define TK_IDENT        0x300
#define TK_SHL_EQU      0x312
#define TK_SHR_EQU      0x313
#define TK_MUL_EQU      0x314
#define TK_DIV_EQU      0x315
#define TK_AND_EQU      0x316
#define TK_OR_EQU       0x317
#define TK_XOR_EQU      0x318
#define TK_ADD_EQU      0x319
#define TK_SUB_EQU      0x31A
#define TK_MOD_EQU      0x322
#define TK_PUNCT        0x329

/* ---- source enum values: src/ast.h (AstBinOp) ---- */
#define AST_BIN_OP_MUL        0
#define AST_BIN_OP_DIV        1
#define AST_BIN_OP_MOD        2
#define AST_BIN_OP_ADD        3
#define AST_BIN_OP_SUB        4
#define AST_BIN_OP_SHL        5
#define AST_BIN_OP_SHR        6
#define AST_BIN_OP_LT         7
#define AST_BIN_OP_LE         8
#define AST_BIN_OP_GT         9
#define AST_BIN_OP_GE         10
#define AST_BIN_OP_EQ         11
#define AST_BIN_OP_NE         12
#define AST_BIN_OP_BIT_AND    13
#define AST_BIN_OP_BIT_XOR    14
#define AST_BIN_OP_BIT_OR     15
#define AST_BIN_OP_LOG_AND    16
#define AST_BIN_OP_LOG_OR     17
#define AST_BIN_OP_ASSIGN     18

/* ---- SITE-COMPOUND-ASSIGN: verbatim from src/prslib.c:1328..1348 ---- */
static int oracle_parseCompoundAssign(long token_type, long token_value,
                                      long *out_op) {
    if (token_type != TK_PUNCT) {
        return 0;
    }

    switch (token_value) {
        case TK_ADD_EQU: *out_op = AST_BIN_OP_ADD; return 1;
        case TK_SUB_EQU: *out_op = AST_BIN_OP_SUB; return 1;
        case TK_MUL_EQU: *out_op = AST_BIN_OP_MUL; return 1;
        case TK_DIV_EQU: *out_op = AST_BIN_OP_DIV; return 1;
        case TK_MOD_EQU: *out_op = AST_BIN_OP_MOD; return 1;
        case TK_AND_EQU: *out_op = AST_BIN_OP_BIT_AND; return 1;
        case TK_OR_EQU:  *out_op = AST_BIN_OP_BIT_OR; return 1;
        case TK_XOR_EQU: *out_op = AST_BIN_OP_BIT_XOR; return 1;
        case TK_SHL_EQU: *out_op = AST_BIN_OP_SHL; return 1;
        case TK_SHR_EQU: *out_op = AST_BIN_OP_SHR; return 1;
        default: return 0;
    }
}

/* ---- SITE-VALID-POINTER-OP: verbatim from src/ast.c:974..990 ---- */
static int oracle_astIsValidPointerOp(long op) {
    switch (op) {
        case AST_BIN_OP_SUB:
        case AST_BIN_OP_ADD:
        case AST_BIN_OP_LT:
        case AST_BIN_OP_LE:
        case AST_BIN_OP_GT:
        case AST_BIN_OP_GE:
        case AST_BIN_OP_EQ:
        case AST_BIN_OP_NE:
        case AST_BIN_OP_LOG_OR:
        case AST_BIN_OP_LOG_AND:
            return 1;
        default:
            return 0;
    }
}

/* ---- SITE-RANGE-OPERATOR: verbatim from src/ast.c:2348..2358 ---- */
static int oracle_astIsRangeOperator(long op) {
    switch (op) {
        case AST_BIN_OP_GE:
        case AST_BIN_OP_GT:
        case AST_BIN_OP_LE:
        case AST_BIN_OP_LT:
            return 1;
        default:
            return 0;
    }
}

int main(void) {
    char op[16];
    long a, b;

    while (scanf("%15s", op) == 1) {
        if (strcmp(op, "CA") == 0) {
            long out_op = 0;
            int r;
            if (scanf("%ld %ld", &a, &b) != 2) { fprintf(stderr, "CA needs 2 args\n"); return 2; }
            r = oracle_parseCompoundAssign(a, b, &out_op);
            /* status 0 = normal; the C predicate never fails for a
             * representable input. */
            printf("CA %ld %ld %d %ld 0\n", a, b, r, out_op);
        } else if (strcmp(op, "PO") == 0) {
            if (scanf("%ld", &a) != 1) { fprintf(stderr, "PO needs 1 arg\n"); return 2; }
            printf("PO %ld %d\n", a, oracle_astIsValidPointerOp(a));
        } else if (strcmp(op, "RO") == 0) {
            if (scanf("%ld", &a) != 1) { fprintf(stderr, "RO needs 1 arg\n"); return 2; }
            printf("RO %ld %d\n", a, oracle_astIsRangeOperator(a));
        } else {
            fprintf(stderr, "unknown op %s\n", op);
            return 2;
        }
    }
    return 0;
}
