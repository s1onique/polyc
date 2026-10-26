// tools/bootstrap/selfhost-parser-control-flow-token.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE02 C2 IMPL -- PolyC
// ValidPostControlFlowToken.
//
// WINNER SUBJECT. Decides whether the token that follows a control-flow
// header may begin a statement.
//
// Frozen ABI (ACT §3):
//   I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value);
//
// Inputs:
//   present : I64,  1 when a token is present, 0 when the token is absent
//                     (the legacy NULL Lexeme case)
//   kind    : I64,  the token kind NUMBER, bound to the live src/lexer.h
//                     values (see the constant table below)
//   value   : I64,  the token payload, meaningful only for the kinds that
//                     dispatch on a payload
//
// Output:
//   1 = the token MAY begin a statement after a control-flow header
//   0 = it may not
//
// Mathematical contract (ACT §2) -- this is the legacy C function
// src/parser.c:832..864, transcribed exactly:
//
//   present == 0                       => 0
//   kind == TK_IDENT  (0x300)          => 1
//   kind == TK_STR    (0x301)          => 1
//   kind == TK_PUNCT  (0x329)          => 1 if value is one of
//                                         TK_MINUS_MINUS (0x306),
//                                         TK_PLUS_PLUS   (0x305),
//                                         '{'            (0x7B),
//                                         ';'            (0x3B),
//                                         '*'            (0x2A)
//                                         otherwise 0
//   kind == TK_KEYWORD(0x332)          => 1 if value is one of
//                                         KW_DO      (66)  KW_FOR    (38)
//                                         KW_GOTO    (44)  KW_IF     (46)
//                                         KW_RETURN  (18)  KW_SWITCH (20)
//                                         KW_WHILE   (40)  KW_BREAK  (24)
//                                         KW_CONTINUE(26)  KW_TRY    (80)
//                                         KW_THROW   (82)  KW_ASM    (28)
//                                         otherwise 0
//   otherwise                          => 0
//
// THE ALIASING THAT MUST BE HONOURED (ACT §5).
// src/lexer.h defines
//   line 15:  #define TK_SUPERSCRIPT  0x301
//   line 19:  #define TK_STR          0x301
// The two names denote the SAME NUMBER.  The legacy C body compares the
// kind BY NUMBER (`tok->tk_type == TK_STR`), so kind 0x301 is TK_STR and
// is ACCEPTED, whatever the payload.  At the ABI level there is no
// distinct "superscript" kind.  A subject that assumed a distinct value
// would produce a different result and would FAIL the differential.
//
// The kind constants are therefore bound BY NUMBER below.  They are
// written as literals, not as names, because the PolyC component cannot
// include the legacy C header, and because the binding that matters is
// the numeric one.
//
// Purity constraints (ACT §6):
//   - no external dependencies on parser / lexer / cctrl / ast
//   - no allocation
//   - no global mutable state
//   - no host identity fields: the ABI is three I64 in, one I64 out
//
// This file is a candidate self-hosted PolyC component.
// ACT-POLYC-SELFHOST-PARSER-SLICE02 qualifies it and delegates
// production authority to it.

I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value)
{
  // Absent token (the legacy NULL Lexeme): the CALLER raises the
  // diagnostic, not this component.
  if (present == 0) return 0;

  // TK_IDENT (0x300): accepted regardless of payload.
  if (kind == 0x300) return 1;

  // TK_STR (0x301): accepted regardless of payload.  This is the SAME
  // NUMBER as TK_SUPERSCRIPT (src/lexer.h:15) -- the aliasing is
  // intentional and load-bearing.  See the header comment.
  if (kind == 0x301) return 1;

  // TK_PUNCT (0x329): accepted only for the five accepted payloads.
  if (kind == 0x329) {
    if (value == 0x306) return 1;  // TK_MINUS_MINUS
    if (value == 0x305) return 1;  // TK_PLUS_PLUS
    if (value == 0x7B)  return 1;  // '{'
    if (value == 0x3B)  return 1;  // ';'
    if (value == 0x2A)  return 1;  // '*'
    return 0;
  }

  // TK_KEYWORD (0x332): accepted only for the twelve accepted keywords.
  if (kind == 0x332) {
    if (value == 66) return 1;  // KW_DO
    if (value == 38) return 1;  // KW_FOR
    if (value == 44) return 1;  // KW_GOTO
    if (value == 46) return 1;  // KW_IF
    if (value == 18) return 1;  // KW_RETURN
    if (value == 20) return 1;  // KW_SWITCH
    if (value == 40) return 1;  // KW_WHILE
    if (value == 24) return 1;  // KW_BREAK
    if (value == 26) return 1;  // KW_CONTINUE
    if (value == 80) return 1;  // KW_TRY
    if (value == 82) return 1;  // KW_THROW
    if (value == 28) return 1;  // KW_ASM
    return 0;
  }

  // Every other kind is rejected.
  return 0;
}
