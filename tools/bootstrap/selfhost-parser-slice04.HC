// tools/bootstrap/selfhost-parser-slice04.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE04 C2 IMPL -- PolyC
// BootstrapAstBinOpFromToken.
//
// WINNER SUBJECT.  Decides the binary-operator classification.
//
// Frozen ABI (ACT section 4.1, and c1/ABI-contract.md):
//   I64 BootstrapAstBinOpFromToken(I64 token_value) -> I64;
//
// Input:
//   token_value : I64, the NUMERIC punct token value, bound to the live
//                 src/lexer.h values (see the constant table below)
//
// Output:
//   0 .. 18      the AstBinOp enum value, exactly as the live src/ast.h
//                 defines it
//   -1          the token is NOT a binary operator (the failure sentinel)
//
// THE MAPPING IS TRANSCRIBED FROM THE REAL LEGACY FUNCTION
// ==========================================================
//
// This is the legacy C function src/ast.c:206..236, transcribed
// exactly:
//
//   int astBinOpFromToken(s64 op, AstBinOp *_result) {
//       switch (op) {
//           case '+': *_result = AST_BIN_OP_ADD;     break;
//           case '-': *_result = AST_BIN_OP_SUB;     break;
//           case '*': *_result = AST_BIN_OP_MUL;     break;
//           case '/': *_result = AST_BIN_OP_DIV;     break;
//           case '%': *_result = AST_BIN_OP_MOD;     break;
//
//           case '=': *_result = AST_BIN_OP_ASSIGN; break;
//           case '<': *_result = AST_BIN_OP_LT;     break;
//           case '>': *_result = AST_BIN_OP_GT;     break;
//           case TK_GREATER_EQU: *_result = AST_BIN_OP_GE;  break;
//           case TK_LESS_EQU: *_result = AST_BIN_OP_LE;  break;
//
//           case TK_EQU_EQU: *_result = AST_BIN_OP_EQ; break;
//           case TK_NOT_EQU: *_result = AST_BIN_OP_NE; break;
//
//           case TK_AND_AND: *_result = AST_BIN_OP_LOG_AND; break;
//           case TK_OR_OR: *_result = AST_BIN_OP_LOG_OR; break;
//
//           case '^': *_result = AST_BIN_OP_BIT_XOR; break;
//           case '&': *_result = AST_BIN_OP_BIT_AND; break;
//           case '|': *_result = AST_BIN_OP_BIT_OR;  break;
//
//           case TK_SHL: *_result = AST_BIN_OP_SHL;  break;
//           case TK_SHR: *_result = AST_BIN_OP_SHR;  break;
//           default:
//               return 0;
//       }
//       return 1;
//   }
//
// The 19 mappings and their enum values were MEASURED by executing the
// real legacy function (see c1/token-mapping.tsv and
// c1/oracle-linkage-contract.txt), and the enum values were extracted
// by COMPILING the live src/ast.h (see c1/enum-values.tsv).
//
// THE CONSTANTS ARE WRITTEN AS NUMBERS
// ======================================
//
// The PolyC component cannot include the legacy C header, so the
// constants are written as their NUMERIC values.  The binding that
// matters is the numeric one, and every value below was resolved from
// the live src/lexer.h by compiling it:
//
//   '+'                 43
//   '-'                 45
//   '*'                 42
//   '/'                 47
//   '%'                 37
//   '='                 61
//   '<'                 60
//   '>'                 62
//   TK_GREATER_EQU      782   (0x30E)
//   TK_LESS_EQU         781   (0x30D)
//   TK_EQU_EQU          779   (0x30B)
//   TK_NOT_EQU          780   (0x30C)
//   TK_AND_AND          783   (0x30F)
//   TK_OR_OR            784   (0x310)
//   '^'                 94
//   '&'                 38
//   '|'                 124
//   TK_SHL              777   (0x309)
//   TK_SHR              778   (0x30A)
//
// and the enum values, from the live src/ast.h:
//
//   AST_BIN_OP_ADD       3
//   AST_BIN_OP_SUB       4
//   AST_BIN_OP_MUL       0
//   AST_BIN_OP_DIV       1
//   AST_BIN_OP_MOD       2
//   AST_BIN_OP_ASSIGN   18
//   AST_BIN_OP_LT        7
//   AST_BIN_OP_GT        9
//   AST_BIN_OP_GE       10
//   AST_BIN_OP_LE        8
//   AST_BIN_OP_EQ       11
//   AST_BIN_OP_NE       12
//   AST_BIN_OP_LOG_AND  16
//   AST_BIN_OP_LOG_OR   17
//   AST_BIN_OP_BIT_XOR  14
//   AST_BIN_OP_BIT_AND  13
//   AST_BIN_OP_BIT_OR   15
//   AST_BIN_OP_SHL       5
//   AST_BIN_OP_SHR       6
//
// THE -1 SENTINEL IS LOAD-BEARING AND UNAMBIGUOUS
// ================================================
//
// The live AstBinOp enum spans 0..28, so -1 is NOT a valid mapped
// enum and can never collide with a successful mapping.  The value -1
// is the ONLY failure signal, and it is the value the production
// adapter tests for.
//
// NO tk_type CHECK.  The legacy body never inspects tk_type: the
// decision is made on the NUMERIC punct value alone.  Adding a tk_type
// check would change the result for any caller that reaches the
// function with a non-TK_PUNCT token, so this component does not add
// one.
//
// Purity constraints (ACT section 8.1):
//   - no host AST pointers
//   - no allocation
//   - no global mutable state
//   - no callbacks
//   - no recovery dependency
//   - the function is TOTAL over the whole I64 domain
//
// This file is a candidate self-hosted PolyC component.
// ACT-POLYC-SELFHOST-PARSER-SLICE04 qualifies it and delegates
// production authority to it.

I64 BootstrapAstBinOpFromToken(I64 token_value)
{
  if (token_value == 43)  return 3;    // '+'  -> AST_BIN_OP_ADD
  if (token_value == 45)  return 4;    // '-'  -> AST_BIN_OP_SUB
  if (token_value == 42)  return 0;    // '*'  -> AST_BIN_OP_MUL
  if (token_value == 47)  return 1;    // '/'  -> AST_BIN_OP_DIV
  if (token_value == 37)  return 2;    // '%'  -> AST_BIN_OP_MOD

  if (token_value == 61)  return 18;   // '='  -> AST_BIN_OP_ASSIGN
  if (token_value == 60)  return 7;    // '<'  -> AST_BIN_OP_LT
  if (token_value == 62)  return 9;    // '>'  -> AST_BIN_OP_GT
  if (token_value == 782) return 10;   // TK_GREATER_EQU -> AST_BIN_OP_GE
  if (token_value == 781) return 8;    // TK_LESS_EQU    -> AST_BIN_OP_LE

  if (token_value == 779) return 11;   // TK_EQU_EQU     -> AST_BIN_OP_EQ
  if (token_value == 780) return 12;   // TK_NOT_EQU     -> AST_BIN_OP_NE

  if (token_value == 783) return 16;   // TK_AND_AND     -> AST_BIN_OP_LOG_AND
  if (token_value == 784) return 17;   // TK_OR_OR       -> AST_BIN_OP_LOG_OR

  if (token_value == 94)  return 14;   // '^'  -> AST_BIN_OP_BIT_XOR
  if (token_value == 38)  return 13;   // '&'  -> AST_BIN_OP_BIT_AND
  if (token_value == 124) return 15;   // '|'  -> AST_BIN_OP_BIT_OR

  if (token_value == 777) return 5;    // TK_SHL -> AST_BIN_OP_SHL
  if (token_value == 778) return 6;    // TK_SHR -> AST_BIN_OP_SHR

  // Every other token value is not a binary operator.
  return -1;
}
