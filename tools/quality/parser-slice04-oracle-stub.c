// tools/quality/parser-slice04-oracle-stub.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE04 C1.
//
// Tiny stub defining `is_terminal = 0` so that the SLICE04 oracle and
// differential tools can link against the production compiler objects
// (which transitively reference is_terminal via aostr.c, cli.c,
// containers.c, ...) without dragging in main.c (which defines
// is_terminal as a runtime-initialized global and also defines
// main()).
//
// The differential tools are non-interactive; they always report
// is_terminal == 0, so the production colour logic degrades to plain
// text and the verifiers still produce correct verdicts.
//
// This file does NOT define or duplicate the AST operator mapping.  It
// is a single-line stub.  It follows the SLICE03 precedent
// (tools/quality/slice03-is-terminal-stub.c).

int is_terminal = 0;
