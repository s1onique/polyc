// tools/quality/parser-slice06-oracle-stub.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06 C1.
//
// Tiny stub defining `is_terminal = 0` so that the SLICE06 oracle can
// link against the production compiler objects (which transitively
// reference is_terminal via aostr.c, cli.c, containers.c, ...) without
// dragging in main.c (which defines is_terminal as a runtime-initialized
// global and also defines main()).
//
// The oracle tools are non-interactive; they always report
// is_terminal == 0, so the production colour logic degrades to plain
// text and the verifiers still produce correct verdicts.
//
// This file does NOT define or duplicate the arm-termination decision.
// It is a single-line stub.  It follows the SLICE05 precedent
// (tools/quality/parser-slice05-oracle-stub.c).

int is_terminal = 0;
