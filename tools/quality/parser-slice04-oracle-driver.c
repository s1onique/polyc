// tools/quality/parser-slice04-oracle-driver.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE04 C1.
//
// THE REAL LEGACY C ORACLE DRIVER FOR THE SELECTED CANDIDATE.
//
// WHAT THIS FILE IS
// =================
//
// A NARROW ADAPTER AND EXECUTABLE DRIVER.  It contains NO mapping table
// of its own.  It calls the REAL legacy function
//
//   int astBinOpFromToken(s64 op, AstBinOp *result);
//
// from the LIVE src/ast.c, compiled with the PolyC delegation OFF, and
// reports what the real function did:
//
//   <token_value>\t<success>\t<output_after_call>
//
// The driver preinitialises the caller's output storage to a
// DISTINGUISHED value before the call, so that the "output unchanged
// on failure" property is observable: a failure that overwrote the
// output would show the distinguished value replaced.
//
// This driver is linked against an ast.c object built WITHOUT
// HCC_USE_SELFHOST_PARSER_AST_BINOP, so the legacy C switch -- the
// byte-identical legacy source -- is the code that executes.  A
// differential run against the DELEGATED build would compare the PolyC
// component against itself and would be vacuous.
//
// F-POLYC-TOOLS: this file is a legacy C ORACLE ADAPTER, which the ACT
// explicitly permits ("The optional C oracle files are permitted only
// as narrow adapters or executable drivers.  They must not reimplement
// the operator mapping.").  It is not a new tool implementation: the
// tool implementations are PolyC.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ast.h"

/* The REAL legacy classifier under test.  Declared here so that this
 * driver does not need the whole ast.h surface beyond the enum. */
int astBinOpFromToken(s64 op, AstBinOp *result);

/* The distinguished initial output value.  It is deliberately OUTSIDE
 * the range of every real mapped enum (the live AstBinOp spans 0..28)
 * so that "the output was overwritten" is unambiguous. */
#define AST_BIN_OP_SENTINEL_INIT 12345

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <token_value>...\n", argv[0]);
        return 2;
    }

    for (int i = 1; i < argc; i++) {
        /* Exact signed 64-bit parsing: strtoll, not atoi. */
        char *end = NULL;
        long long tok = strtoll(argv[i], &end, 10);
        if (end == argv[i] || (end != NULL && *end != 0)) {
            fprintf(stderr, "oracle: cannot parse token value '%s'\n", argv[i]);
            return 2;
        }

        AstBinOp out = (AstBinOp)AST_BIN_OP_SENTINEL_INIT;
        int ok = astBinOpFromToken((s64)tok, &out);

        /* The output is printed with %d: the enum values are small
         * non-negative integers, and the distinguished sentinel is a
         * small non-negative integer too, so a 32-bit conversion is
         * exact here.  (The FIXTURE VALUES themselves are printed
         * with a full 64-bit conversion by the PolyC side.) */
        printf("%lld\t%d\t%d\n", tok, ok, (int)out);
    }

    return 0;
}
