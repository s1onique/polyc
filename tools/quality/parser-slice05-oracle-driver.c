// tools/quality/parser-slice05-oracle-driver.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE05 C1.
//
// THE REAL LEGACY C ORACLE DRIVER FOR THE UNARY CLASSIFIER.
//
// WHAT THIS FILE IS
// =================
//
// A NARROW ADAPTER AND EXECUTABLE DRIVER.  It contains NO mapping table
// of its own.  It calls the REAL legacy function
//
//   int astUnaryOpFromToken(s64 op, AstUnOp *result);
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
// The driver is linked against an ast.c object built WITHOUT
// HCC_USE_SELFHOST_PARSER_AST_UNARY, so the legacy C switch -- the
// byte-identical legacy source -- is the code that executes.  A
// differential run against the DELEGATED build would compare the PolyC
// component against itself and would be vacuous.
//
// The adapter entry point (Slice05LegacyUnaryOpOracle) is compiled
// WITHOUT main() when NO_ORACLE_MAIN is defined, so that the PolyC
// differential can link the SAME adapter object without a duplicate
// main() symbol.
//
// F-POLYC-TOOLS: this file is a legacy C ORACLE ADAPTER, which the ACT
// explicitly permits ("The C oracle may call the actual legacy unary
// classifier but must not implement a duplicate mapping").  It is not a
// new tool implementation: the tool implementations are PolyC.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ast.h"

/* The REAL legacy classifier under test.  Declared here so that this
 * driver does not need the whole ast.h surface beyond the enum. */
int astUnaryOpFromToken(s64 op, AstUnOp *result);

/* The distinguished initial output value.  It is deliberately OUTSIDE
 * the range of every real mapped enum (the live AstUnOp spans 0..12)
 * so that "the output was overwritten" is unambiguous. */
#define AST_UN_OP_SENTINEL_INIT 12345

/* The NARROW ORACLE ADAPTER used by the PolyC differential.
 *
 * It takes the token value and the caller's INITIAL output value, calls
 * the REAL legacy function, and reports:
 *   - the observed success flag (the function's return value), and
 *   - the FINAL value of the caller's output slot.
 *
 * It contains NO mapping table and NO decision logic: the decision is
 * the real astUnaryOpFromToken's. */
long long Slice05LegacyUnaryOpOracle(long long token_value,
                                     long long initial_output,
                                     long long *out_after_call)
{
    AstUnOp out = (AstUnOp)initial_output;
    int ok = astUnaryOpFromToken((s64)token_value, &out);
    if (out_after_call) *out_after_call = (long long)(int)out;
    return (long long)ok;
}

#ifndef NO_ORACLE_MAIN
int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <token_value>... [--initial=<value>]\n",
                argv[0]);
        return 2;
    }

    /* The DISTINGUISHED initial output value the caller's storage holds
     * BEFORE the call.  It defaults to the canonical sentinel, and may
     * be overridden so that the fixture's SECOND distinct initial value
     * (54321) can be exercised against the real legacy function too. */
    long long initial = AST_UN_OP_SENTINEL_INIT;

    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--initial=", 10) == 0) {
            char *end = NULL;
            initial = strtoll(argv[i] + 10, &end, 10);
            if (end == argv[i] + 10 || (end != NULL && *end != 0)) {
                fprintf(stderr, "oracle: cannot parse initial value '%s'\n",
                        argv[i]);
                return 2;
            }
            continue;
        }

        /* Exact signed 64-bit parsing: strtoll, not atoi. */
        char *end = NULL;
        long long tok = strtoll(argv[i], &end, 10);
        if (end == argv[i] || (end != NULL && *end != 0)) {
            fprintf(stderr, "oracle: cannot parse token value '%s'\n", argv[i]);
            return 2;
        }

        AstUnOp out = (AstUnOp)initial;
        int ok = astUnaryOpFromToken((s64)tok, &out);

        /* The output is printed with %d: the enum values are small
         * non-negative integers, and the distinguished sentinel is a
         * small non-negative integer too, so a 32-bit conversion is
         * exact here.  (The FIXTURE VALUES themselves are printed
         * with a full 64-bit conversion by the PolyC side.) */
        printf("%lld\t%d\t%d\n", tok, ok, (int)out);
    }

    return 0;
}
#endif
