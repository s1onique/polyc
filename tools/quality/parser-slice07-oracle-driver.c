// tools/quality/parser-slice07-oracle-driver.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE07 C1.
//
// THE REAL LEGACY C ORACLE DRIVER FOR THE COMPOUND-BLOCK STATEMENT
// APPEND/SKIP DECISION.
//
// WHAT THIS FILE IS
// =================
//
// An EXECUTABLE DRIVER over the REAL legacy decision.  It contains NO
// decision table of its own.  It calls
//
//   long long ParserLegacyCompoundBlockAppendsOracle(long long stmt_kind,
//                                                     long long declvar_kind);
//
// -- the tiny wrapper that src/parser.c itself exposes adjacent to the
// real legacy condition -- and reports what the real decision did:
//
//   <stmt_kind>\t<declvar_kind>\t<appends>
//
// The driver is linked against a parser.c object built WITHOUT
// HCC_USE_SELFHOST_PARSER_COMPOUND_BLOCK_APPEND, so the legacy
// condition -- the byte-identical legacy source -- is the code that
// executes.  A differential run against the DELEGATED build would
// compare the PolyC component against itself and would be vacuous.
//
// THE PROBED SET
// ==============
//
// The probed set is the domain the frozen fixture contract specifies:
// the full live AstKind domain for stmt_kind, crossed with the
// relevant declvar_kind values (AST_GVAR, AST_LVAR, AST_DECL), plus
// the out-of-enum, negative and extreme probes.
//
// The AstKind values are written here as the numeric enum values the
// live src/ast.h defines; the legacy decision reads only the number,
// so the numeric domain is what matters.  The values were DERIVED by
// compiling the live src/ast.h (see
// evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c1/live-ast-enums.tsv).
//
// F-POLYC-TOOLS: this file is a legacy C ORACLE DRIVER, which the ACT
// explicitly permits.  It is not a tool implementation: the tool
// implementations are PolyC.

#include <stdio.h>

extern long long ParserLegacyCompoundBlockAppendsOracle(long long stmt_kind,
                                                        long long declvar_kind);

/* Every AstKind value the live src/ast.h defines (41 values). */
static const long long LIVE_AST_KINDS[41] = {
    256, 258, 259, 261, 262, 263, 264, 265, 266, 267,
    268, 269, 270, 271, 273, 274, 275, 276, 277, 278,
    279, 280, 281, 282, 283, 284, 285, 286, 287, 288,
    289, 290, 291, 292, 293, 294, 295, 296, 297, 298,
    299
};

/* The declvar_kind values probed against every live stmt_kind. */
static const long long LIVE_DECLVAR_KINDS[3] = {
    256, /* AST_GVAR  -- the skipping declvar */
    261, /* AST_LVAR  -- a non-skipping declaration */
    263  /* AST_DECL  -- a declaration whose declvar is a declaration */
};

/* The out-of-enum, negative and extreme probes for declvar_kind. */
static const long long OUT_OF_ENUM_DECLVAR_KINDS[10] = {
    (-9223372036854775807LL - 1LL), /* INT64_MIN */
    -1LL, 0LL, 1LL, 255LL, 257LL, 260LL, 300LL,
    9223372036854775807LL /* INT64_MAX */
};

/* The out-of-enum, negative and extreme probes for stmt_kind.
 *
 * The INT64_MIN value is written as (-9223372036854775807LL - 1LL)
 * because the literal -9223372036854775808LL does not fit in a signed
 * long long in C either: it is one past INT64_MAX in magnitude, so the
 * compiler treats it as unsigned.  The parenthesised form is the
 * portable spelling and it is EXACTLY the same idiom the PolyC
 * fixture producer uses (INT64_MIN_VALUE). */
static const long long OUT_OF_ENUM_STMT_KINDS[17] = {
    (-9223372036854775807LL - 1LL), /* INT64_MIN */
    (-9223372036854775807LL + 1LL),
    -4LL, -3LL, -2LL, -1LL, 0LL, 1LL,
    250LL, 255LL, 257LL, 260LL,
    300LL, 301LL, 1000LL, 1000000LL,
    9223372036854775807LL /* INT64_MAX */
};

static void probe(long long stmt_kind, long long declvar_kind)
{
    printf("%lld\t%lld\t%lld\n", stmt_kind, declvar_kind,
           ParserLegacyCompoundBlockAppendsOracle(stmt_kind, declvar_kind));
}

int main(void)
{
    int i, j;

    /* The full live AstKind domain, crossed with the relevant
     * declvar_kind values. */
    for (i = 0; i < 41; i++) {
        for (j = 0; j < 3; j++) {
            probe(LIVE_AST_KINDS[i], LIVE_DECLVAR_KINDS[j]);
        }
    }

    /* The FULL live AstKind domain crossed with the FULL live
     * AstKind domain, so the oracle covers every pair the fixture's
     * P4_APPEND_GENERAL partition carries.  This is the exhaustive
     * two-input domain of the decision. */
    for (i = 0; i < 41; i++) {
        for (j = 0; j < 41; j++) {
            probe(LIVE_AST_KINDS[i], LIVE_AST_KINDS[j]);
        }
    }

    /* The out-of-enum, negative and extreme stmt_kind probes, paired
     * with AST_GVAR (the skipping declvar) and with AST_LVAR. */
    for (i = 0; i < 17; i++) {
        probe(OUT_OF_ENUM_STMT_KINDS[i], 256);
        probe(OUT_OF_ENUM_STMT_KINDS[i], 261);
    }

    /* The out-of-enum, negative and extreme declvar_kind probes,
     * against AST_DECL (the only stmt_kind that consults it) and
     * against a non-declaration stmt_kind (which must NOT consult
     * it). */
    for (j = 0; j < 10; j++) {
        probe(263, OUT_OF_ENUM_DECLVAR_KINDS[j]);
        probe(270, OUT_OF_ENUM_DECLVAR_KINDS[j]);
    }

    return 0;
}
