/* ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SUB-001 CAUSAL WITNESS.
 *
 * The witness exercises the switch-arm termination decision in a way
 * whose COMPILED OUTPUT changes when the decision changes.
 *
 * The decision at src/parser.c:1551..1553 decides whether the
 * switch-case arm's statement loop terminates after the statement just
 * parsed.  When it terminates the arm, the FOLLOWING statements are
 * parsed by the NEXT case arm; when it does not, they stay in the
 * CURRENT arm.
 *
 * The witness puts a COMPOUND STATEMENT ({ ... }) as the first
 * statement of the first case arm, and a marker statement AFTER it:
 *
 *   case 1: { x = 41; }        <-- one AST_COMPOUND_STMT
 *           Print("ARM1_MARKER");
 *   case 2: ...
 *
 *   - pristine decision: the compound statement TERMINATES the arm, so
 *     the marker statement is parsed by the `case 2:` arm.  The output
 *     shows ARM2_MARKER and then ARM1_MARKER (the arm bodies are
 *     emitted in source order), and x is 1 because the assignment `x=1`
 *     in case 2 runs after the fall-through.
 *   - mutated decision (AST_COMPOUND_STMT removed from the terminating
 *     set): the compound statement does NOT terminate the arm, so the
 *     marker statement stays in the `case 1:` arm.  The output shows
 *     ARM1_MARKER before ARM2_MARKER.
 *
 * The observable is COMPILED PROGRAM OUTPUT, and the ORDER of the two
 * markers changes.
 */
U0 Print(U8 *s)
{
    "SUB001:%s\n", s;
}

I32 Main(I32 argc, U8 **argv)
{
    I64 x = 0;
    switch (1) {
        case 1: { x = 41; }
            Print("ARM1_MARKER");
        case 2:
            x = 1;
            Print("ARM2_MARKER");
            break;
        default:
            x = 99;
            Print("DEFAULT_ARM_MARKER");
    }
    "SUB001:x=%d\n", x;
    return 0;
}
