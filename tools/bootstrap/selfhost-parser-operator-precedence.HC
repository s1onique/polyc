// tools/bootstrap/selfhost-parser-operator-precedence.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE03 C2 IMPL -- PolyC
// OperatorPrecedence.
//
// WINNER SUBJECT. Decides the precedence of a binary operator.
//
// Frozen ABI (ACT §2, and the predecessor's frozen contract):
//   I64 BootstrapOperatorPrecedence(I64 punct_value) -> I64 precedence;
//
// Input:
//   punct_value : I64, the NUMERIC punct token value, bound to the live
//                 src/lexer.h values (see the constant table below)
//
// Output:
//   1 .. 14     the precedence level of the operator
//   -1          the token is NOT a binary operator (the legacy sentinel)
//
// Mathematical contract (ACT §2) -- this is the legacy C function
// src/prslib.c:1139..1207, transcribed exactly:
//
//   precedence  1 : TK_ARROW (0x328), '.' (0x2E), '(' (0x28)
//   precedence  2 : '[' (0x5B)
//   precedence  3 : '!' (0x21), '~' (0x7E), TK_PLUS_PLUS (0x305),
//                   TK_MINUS_MINUS (0x306), TK_PRE_PLUS_PLUS (0x330),
//                   TK_PRE_MINUS_MINUS (0x331)
//   precedence  4 : '*' (0x2A), '/' (0x2F), '%' (0x25)
//   precedence  5 : '-' (0x2D), '+' (0x2B)
//   precedence  6 : TK_SHL (0x309), TK_SHR (0x30A)
//   precedence  7 : TK_LESS_EQU (0x30D), TK_GREATER_EQU (0x30E),
//                   '<' (0x3C), '>' (0x3E)
//   precedence  8 : TK_EQU_EQU (0x30B), TK_NOT_EQU (0x30C)
//   precedence  9 : '^' (0x5E)
//   precedence 10 : '&' (0x26)
//   precedence 11 : '|' (0x7C)
//   precedence 12 : TK_AND_AND (0x30F)
//   precedence 13 : TK_OR_OR (0x310)
//   precedence 14 : '=' (0x3D), TK_ADD_EQU (0x319), TK_SUB_EQU (0x31A),
//                   TK_MUL_EQU (0x314), TK_DIV_EQU (0x315),
//                   TK_MOD_EQU (0x322), TK_AND_EQU (0x316),
//                   TK_OR_EQU (0x317), TK_XOR_EQU (0x318),
//                   TK_SHL_EQU (0x312), TK_SHR_EQU (0x313)
//   any other    : -1
//
// THE -1 SENTINEL IS LOAD-BEARING.  parseExpr consumes the value in
// exactly three ways (src/prslib.c:1364, :1430, :1431):
//
//     if (prec2 < 0 || prec <= prec2) { rewind; return LHS; }
//     next_prec = prec2;
//     if (tok->i64 == '=') next_prec++;
//
// so -1 means "this token is not a binary operator" and MUST be
// preserved exactly.
//
// NO tk_type CHECK.  The legacy body never inspects tk_type: the
// decision is made on the NUMERIC punct value alone.  Adding a
// tk_type check would change the result for any caller that reaches
// the function with a non-TK_PUNCT token, so this component does not
// add one.
//
// THE TK_STR / TK_SUPERSCRIPT ALIASING.  src/lexer.h:15 defines
// TK_SUPERSCRIPT 0x301 and src/lexer.h:19 defines TK_STR 0x301.  The
// two names denote the SAME NUMBER.  Neither value appears in the
// precedence table, so 0x301 returns -1.  The component MUST NOT
// distinguish them, and it does not: the table is defined on the
// numeric value and nothing else.
//
// The constants are written as NUMBERS, for the same reason the
// control-flow-token component writes its constants as numbers: the
// PolyC component cannot include the legacy C header, and the binding
// that matters is the numeric one.  Every value above was read from
// the live src/lexer.h and re-derived mechanically from the live
// src/prslib.c by
//   tools/quality/parser-slice03-contract-requalify.HC
// whose derivation is in
//   evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/c1/precedence-table-derived.tsv
//
// Purity constraints (ACT §5.2):
//   - no external dependencies on parser / lexer / cctrl / ast
//   - no allocation
//   - no global mutable state
//   - no host identity fields: the ABI is one I64 in, one I64 out
//   - the function is TOTAL over the whole I64 domain
//
// This file is a candidate self-hosted PolyC component.
// ACT-POLYC-SELFHOST-PARSER-SLICE03 qualifies it and delegates
// production authority to it.

I64 BootstrapOperatorPrecedence(I64 punct_value)
{
  // precedence 1
  if (punct_value == 0x328) return 1;   // TK_ARROW
  if (punct_value == 0x2E)  return 1;   // '.'
  if (punct_value == 0x28)  return 1;   // '('

  // precedence 2
  if (punct_value == 0x5B)  return 2;   // '['

  // precedence 3
  if (punct_value == 0x21)  return 3;   // '!'
  if (punct_value == 0x7E)  return 3;   // '~'
  if (punct_value == 0x305) return 3;   // TK_PLUS_PLUS
  if (punct_value == 0x306) return 3;   // TK_MINUS_MINUS
  if (punct_value == 0x330) return 3;   // TK_PRE_PLUS_PLUS
  if (punct_value == 0x331) return 3;   // TK_PRE_MINUS_MINUS

  // precedence 4
  if (punct_value == 0x2A)  return 4;   // '*'
  if (punct_value == 0x2F)  return 4;   // '/'
  if (punct_value == 0x25)  return 4;   // '%'

  // precedence 5
  if (punct_value == 0x2D)  return 5;   // '-'
  if (punct_value == 0x2B)  return 5;   // '+'

  // precedence 6
  if (punct_value == 0x309) return 6;   // TK_SHL
  if (punct_value == 0x30A) return 6;   // TK_SHR

  // precedence 7
  if (punct_value == 0x30D) return 7;   // TK_LESS_EQU
  if (punct_value == 0x30E) return 7;   // TK_GREATER_EQU
  if (punct_value == 0x3C)  return 7;   // '<'
  if (punct_value == 0x3E)  return 7;   // '>'

  // precedence 8
  if (punct_value == 0x30B) return 8;   // TK_EQU_EQU
  if (punct_value == 0x30C) return 8;   // TK_NOT_EQU

  // precedence 9
  if (punct_value == 0x5E)  return 9;   // '^'

  // precedence 10
  if (punct_value == 0x26)  return 10;  // '&'

  // precedence 11
  if (punct_value == 0x7C)  return 11;  // '|'

  // precedence 12
  if (punct_value == 0x30F) return 12;  // TK_AND_AND

  // precedence 13
  if (punct_value == 0x310) return 13;  // TK_OR_OR

  // precedence 14
  if (punct_value == 0x3D)  return 14;  // '='
  if (punct_value == 0x319) return 14;  // TK_ADD_EQU
  if (punct_value == 0x31A) return 14;  // TK_SUB_EQU
  if (punct_value == 0x314) return 14;  // TK_MUL_EQU
  if (punct_value == 0x315) return 14;  // TK_DIV_EQU
  if (punct_value == 0x322) return 14;  // TK_MOD_EQU
  if (punct_value == 0x316) return 14;  // TK_AND_EQU
  if (punct_value == 0x317) return 14;  // TK_OR_EQU
  if (punct_value == 0x318) return 14;  // TK_XOR_EQU
  if (punct_value == 0x312) return 14;  // TK_SHL_EQU
  if (punct_value == 0x313) return 14;  // TK_SHR_EQU

  // Every other punct value is not a binary operator.
  return -1;
}
