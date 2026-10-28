// tools/quality/parser-slice06-oracle-driver.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06 C1.
//
// THE REAL LEGACY C ORACLE DRIVER FOR THE SWITCH-ARM TERMINATION
// DECISION.
//
// WHAT THIS FILE IS
// =================
//
// An EXECUTABLE DRIVER over the REAL legacy decision.  It contains NO
// terminating-set table of its own.  It calls
//
//   long long ParserLegacySwitchArmTerminatesOracle(long long ast_kind);
//
// -- the tiny wrapper that src/parser.c itself exposes adjacent to the
// real legacy condition -- and reports what the real decision did:
//
//   <ast_kind>\t<terminates>
//
// The driver is linked against a parser.c object built WITHOUT
// HCC_USE_SELFHOST_PARSER_SWITCH_ARM, so the legacy condition -- the
// byte-identical legacy source -- is the code that executes.  A
// differential run against the DELEGATED build would compare the PolyC
// component against itself and would be vacuous.
//
// The PROBED SET is the domain the frozen predecessor's oracle probed:
// every live AstKind value, plus the out-of-enum probes -4..0 and
// 296..300.  The values are written here as the numeric enum values
// the live src/ast.h defines; the legacy decision reads only the
// number, so the numeric domain is what matters.
//
// F-POLYC-TOOLS: this file is a legacy C ORACLE DRIVER, which the ACT
// explicitly permits.  It is not a tool implementation: the tool
// implementations are PolyC.

#include <stdio.h>

extern long long ParserLegacySwitchArmTerminatesOracle(long long ast_kind);

/* Every AstKind value the live src/ast.h defines (41 values). */
static const long long LIVE_AST_KINDS[41] = {
    256, 258, 259, 261, 262, 263, 264, 265, 266, 267,
    268, 269, 270, 271, 273, 274, 275, 276, 277, 278,
    279, 280, 281, 282, 283, 284, 285, 286, 287, 288,
    289, 290, 291, 292, 293, 294, 295, 296, 297, 298,
    299
};

int main(void)
{
    int i;
    long long k;

    for (i = 0; i < 41; i++) {
        printf("%lld\t%lld\n", LIVE_AST_KINDS[i],
               ParserLegacySwitchArmTerminatesOracle(LIVE_AST_KINDS[i]));
    }
    /* Also probe the values OUTSIDE the enum, to bound the domain. */
    for (k = -4; k <= 0; k++) {
        printf("%lld\t%lld\n", k, ParserLegacySwitchArmTerminatesOracle(k));
    }
    for (k = 296; k <= 300; k++) {
        printf("%lld\t%lld\n", k, ParserLegacySwitchArmTerminatesOracle(k));
    }
    return 0;
}
