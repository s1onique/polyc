// tools/bootstrap/selfhost-parser-statement-dispatch.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE09 C2 IMPL -- PolyC
// BootstrapStatementDispatch.
//
// WINNER SUBJECT.  Decides the STATEMENT-CONSTRUCTOR DISPATCH.
//
// Frozen ABI (the predecessor's c2/selected-abi-and-projection.md):
//   I64 BootstrapStatementDispatch(I64 token_type, I64 keyword_id) -> I64;
//
// Input:
//   token_type : I64, the lexer's token class (tok->tk_type)
//   keyword_id : I64, the keyword enum value (tok->i64), meaningful
//                only when token_type is TK_KEYWORD
//
// Output:
//   the statement-constructor SELECTOR: a bounded enum value in
//   [0,15] that names which statement constructor the C side must
//   invoke.
//
// THE SELECTOR ENCODING
// =====================
//
// The encoding is the one DERIVED and FROZEN at C0 in
// evidence/ACT-POLYC-SELFHOST-PARSER-SLICE09/c0/selected-contract-bindings.tsv
// (PART 4).  It is dense and SOURCE-BOUND: the not-a-keyword-statement
// value is 0, and the fifteen constructor arms are numbered 1..15 in
// the SOURCE ORDER of the `case KW_*:` labels.
//
//   0  STMT_NOT_A_KEYWORD_STATEMENT
//   1  STMT_IF        2  STMT_FOR       3  STMT_WHILE
//   4  STMT_DO        5  STMT_RETURN    6  STMT_TRY
//   7  STMT_THROW     8  STMT_SWITCH    9  STMT_CASE
//  10  STMT_DEFAULT  11  STMT_BREAK    12  STMT_CONTINUE
//  13  STMT_ASM      14  STMT_STATIC   15  STMT_GOTO
//
// The encoding is derived from the SOURCE ORDER of the case labels, NOT
// from the numeric order of the KW_* enum values, so it does not
// depend on how the lexer happens to number its keywords.
//
// THE MAPPING IS TRANSCRIBED FROM THE REAL LEGACY SWITCH
// =======================================================
//
// This is the decision at src/parser.c:1864..1972, transcribed
// exactly.  The frozen range src/parser.c:1864..1877 digests to
// cd138cc52588fe48c2eab37421b4e25abbacd7ea10491bc696a1acab9a66d7e0.
//
// The switch's arms, in SOURCE ORDER, with the LIVE src/lexer.h
// keyword values:
//
//   KW_IF       46 -> parseIfStatement          (selector  1)
//   KW_FOR      38 -> parseForStatement         (selector  2)
//   KW_WHILE    40 -> parseWhileStatement       (selector  3)
//   KW_DO       66 -> parseDoWhileStatement     (selector  4)
//   KW_RETURN   18 -> parseReturnStatement      (selector  5)
//   KW_TRY      80 -> parseTryStatement         (selector  6)
//   KW_THROW    82 -> parseThrowStatement       (selector  7)
//   KW_SWITCH   20 -> parseSwitchStatement      (selector  8)
//   KW_CASE     22 -> parseCaseLabel            (selector  9)
//   KW_DEFAULT  64 -> parseDefaultStatement     (selector 10)
//   KW_BREAK    24 -> parseBreakStatement       (selector 11)
//   KW_CONTINUE 26 -> parseContinueStatement    (selector 12)
//   KW_ASM      28 -> prsAsm + listAppend        (selector 13)
//   KW_STATIC   67 -> the local-static path      (selector 14)
//   KW_GOTO     44 -> astGoto + label            (selector 15)
//
// The `default:` arm is the NOT-A-RECOGNISED-KEYWORD route: it
// rewinds the token and raises "Keyword '%.*s' cannot be used in this
// context".  It is NOT a constructor, so it is represented by the
// not-a-keyword-statement selector, 0, and the C side routes selector
// 0 to the identical legacy default path.

//
// THE CONSTANTS ARE WRITTEN AS NUMBERS
// =====================================
//
// The PolyC component cannot include the legacy C header, so the
// keyword values are written as their NUMERIC values.  The binding
// that matters is the numeric one, and every value below was resolved
// from the LIVE src/lexer.h by COMPILING it (see
// evidence/ACT-POLYC-SELFHOST-PARSER-SLICE09/c1/original-dispatch-enum-facts.tsv).
//
// THE TOKEN-TYPE CLASS
// ====================
//
// TK_KEYWORD is 0x332 == 818 (src/lexer.h:62).  The decision needs
// only whether the token is a keyword.
//
// A token that is NOT a keyword maps to the not-a-keyword-statement
// selector.  In production the C side's own `tok->tk_type ==
// TK_KEYWORD` guard means the dispatch is not entered for such a
// token at all, but the value is DEFINED here so that the component
// is total and has no undefined behaviour on any input.
//
// THE COMPONENT IS TOTAL
// ======================
//
// Every (token_type, keyword_id) pair maps to exactly one value in
// [0,15].  There is NO failure sentinel and no error return, exactly
// as the frozen ABI requires.
//
// A keyword_id that is not one of the fifteen arms -- including an
// out-of-enum value and the I64 extremes -- maps to the
// not-a-keyword-statement selector.
//
// Purity constraints:
//   - no host AST pointers
//   - no allocation
//   - no global mutable state
//   - no callbacks
//   - no recovery dependency
//   - no token cursor
//   - the function is TOTAL over the whole I64 domain
//
// This file is a candidate self-hosted PolyC component.
// ACT-POLYC-SELFHOST-PARSER-SLICE09 qualifies it and delegates
// production authority to it.

#define STMT_NOT_A_KEYWORD_STATEMENT 0

I64 BootstrapStatementDispatch(I64 token_type, I64 keyword_id)
{
  // The token is not in the keyword class: the C side's guard means
  // the dispatch is not entered, and the not-a-keyword-statement
  // selector is the defined answer.
  if (token_type != 818) return STMT_NOT_A_KEYWORD_STATEMENT;

  // The fifteen dispatch arms, in the SOURCE ORDER of the case labels.
  if (keyword_id == 46) return 1;   // KW_IF       -> parseIfStatement
  if (keyword_id == 38) return 2;   // KW_FOR      -> parseForStatement
  if (keyword_id == 40) return 3;   // KW_WHILE    -> parseWhileStatement
  if (keyword_id == 66) return 4;   // KW_DO       -> parseDoWhileStatement
  if (keyword_id == 18) return 5;   // KW_RETURN   -> parseReturnStatement
  if (keyword_id == 80) return 6;   // KW_TRY      -> parseTryStatement
  if (keyword_id == 82) return 7;   // KW_THROW    -> parseThrowStatement
  if (keyword_id == 20) return 8;   // KW_SWITCH   -> parseSwitchStatement
  if (keyword_id == 22) return 9;   // KW_CASE     -> parseCaseLabel
  if (keyword_id == 64) return 10;  // KW_DEFAULT  -> parseDefaultStatement
  if (keyword_id == 24) return 11;  // KW_BREAK    -> parseBreakStatement
  if (keyword_id == 26) return 12;  // KW_CONTINUE -> parseContinueStatement
  if (keyword_id == 28) return 13;  // KW_ASM      -> prsAsm
  if (keyword_id == 67) return 14;  // KW_STATIC   -> the local-static path
  if (keyword_id == 44) return 15;  // KW_GOTO     -> astGoto

  // A keyword in the keyword class that is not one of the fifteen
  // arms: the legacy `default:` route.  It is not a constructor, so
  // the not-a-keyword-statement selector is the defined answer.
  return STMT_NOT_A_KEYWORD_STATEMENT;
}
