// tools/quality/slice02-is-terminal-stub.c
//
// ACT-POLYC-SELFHOST-PARSER-SLICE02 C2 IMPL.
//
// Tiny stub defining `is_terminal = 0` so that the control-flow-token
// differential tool can link against the production parser objects
// (which transitively reference is_terminal via aostr.c, cli.c,
// containers.c, ...) without dragging in main.c (which defines
// is_terminal as a runtime-initialized global and also defines main()).
//
// The differential tool is non-interactive; it always reports
// is_terminal == 0, so the production colour logic degrades to plain
// text and the verifier still produces correct verdicts.
//
// This file does NOT define or duplicate the control-flow-token
// decision. It is a single-line stub.

int is_terminal = 0;
