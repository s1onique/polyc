// tools/quality/parser-padding-is-terminal-stub.c
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
//
// Tiny stub defining `is_terminal = 0` so that the parser-padding
// differential tool can link against the actual compiled
// src/parser.c (which transitively references is_terminal via
// aostr.c, cli.c, containers.c, etc.) without dragging in main.c
// (which defines is_terminal as a runtime-initialized global).
//
// The differential tool is non-interactive; it always reports
// is_terminal == 0, so the production colour logic degrades to
// plain text and the verifier still produces correct verdicts.
//
// This file does NOT define or duplicate the CalcPadding formula.
// It is a single-line stub.

int is_terminal = 0;
