// tools/bootstrap/selfhost-parser-slice05.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE05 C2 IMPL -- PolyC
// BootstrapAstUnaryOpFromToken.
//
// WINNER SUBJECT.  Decides the unary-operator classification.
//
// Frozen ABI (ACT section 6.1, and c1/ABI-contract.md):
//   I64 BootstrapAstUnaryOpFromToken(I64 token_value) -> I64;
//
// Input:
//   token_value : I64, the NUMERIC punct token value, bound to the live
//                 src/lexer.h values (see the constant table below)
//
// Output:
//   0 .. 9       the AstUnOp enum value, exactly as the live src/ast.h
//                 defines it
//   -1           the token is NOT a unary operator (the failure sentinel)
//
// THE MAPPING IS TRANSCRIBED FROM THE REAL LEGACY FUNCTION
// ==========================================================
//
// This is the legacy C function src/ast.c:287..305, transcribed
// exactly:
//
//   int astUnaryOpFromToken(s64 op, AstUnOp *_result) {
//       switch (op) {
//           case TK_PRE_PLUS_PLUS:   *_result = AST_UN_OP_PRE_INC; break;
//           case TK_PRE_MINUS_MINUS: *_result = AST_UN_OP_PRE_DEC; break;
//           case TK_PLUS_PLUS:       *_result = AST_UN_OP_POST_INC; break;
//           case TK_MINUS_MINUS:     *_result = AST_UN_OP_POST_DEC; break;
//           case '+':                *_result = AST_UN_OP_PLUS;    break;
//           case '-':                *_result = AST_UN_OP_MINUS;   break;
//           case '~':                *_result = AST_UN_OP_BIT_NOT; break;
//           case '!':                *_result = AST_UN_OP_LOG_NOT; break;
//           case '&':                *_result = AST_UN_OP_ADDR_OF; break;
//           case '*':                *_result = AST_UN_OP_DEREF;   break;
//           default:
//               return 0;
//       }
//       return 1;
//   }
//
// The 10 mappings and their enum values were MEASURED by executing the
// real legacy function (see c1/token-to-enum.tsv and
// c1/oracle-contract.md), and the enum values were extracted by
// COMPILING the live src/ast.h (see c1/compiled-enum-values.tsv).
//
// THE CONSTANTS ARE WRITTEN AS NUMBERS
// ======================================
//
// The PolyC component cannot include the legacy C header, so the
// constants are written as their NUMERIC values.  The binding that
// matters is the numeric one, and every value below was resolved from
// the live src/lexer.h by compiling it:
//
//   TK_PRE_PLUS_PLUS     816   (0x330)
//   TK_PRE_MINUS_MINUS   817   (0x331)
//   TK_PLUS_PLUS         773   (0x305)
//   TK_MINUS_MINUS       774   (0x306)
//   '+'                   43
//   '-'                   45
//   '~'                  126
//   '!'                   33
//   '&'                   38
//   '*'                   42
//
// and the enum values, from the live src/ast.h:
//
//   AST_UN_OP_POST_INC    0
//   AST_UN_OP_POST_DEC    1
//   AST_UN_OP_PRE_INC     2
//   AST_UN_OP_PRE_DEC     3
//   AST_UN_OP_PLUS        4
//   AST_UN_OP_MINUS       5
//   AST_UN_OP_LOG_NOT     6
//   AST_UN_OP_BIT_NOT     7
//   AST_UN_OP_ADDR_OF     8
//   AST_UN_OP_DEREF       9
//
// THE -1 SENTINEL IS LOAD-BEARING AND UNAMBIGUOUS
// ================================================
//
// The live AstUnOp enum spans 0..12, so -1 is NOT a valid mapped enum
// and can never collide with a successful mapping.  The value -1 is
// the ONLY failure signal, and it is the value the production adapter
// tests for.
//
// NO tk_type CHECK.  The legacy body never inspects tk_type: the
// decision is made on the NUMERIC punct value alone.  Adding a tk_type
// check would change the result for any caller that reaches the
// function with a non-TK_PUNCT token, so this component does not add
// one.
//
// THE OUTPUT POINTER IS NEVER SEEN
// ================================
//
// The legacy function writes through the caller's output pointer.  That
// pointer is ABI STORAGE, not AST graph authority, and it is NOT
// passed to this component: the PolyC ABI is a pure scalar in, scalar
// out.  The C adapter owns the conditional storage.
//
// Purity constraints (ACT section 7.1):
//   - no host AST pointers
//   - no allocation
//   - no global mutable state
//   - no callbacks
//   - no recovery dependency
//   - the function is TOTAL over the whole I64 domain
//
// This file is a candidate self-hosted PolyC component.
// ACT-POLYC-SELFHOST-PARSER-SLICE05 qualifies it and delegates
// production authority to it.

I64 BootstrapAstUnaryOpFromToken(I64 token_value)
{
  if (token_value == 816) return 2;   // TK_PRE_PLUS_PLUS   -> AST_UN_OP_PRE_INC
  if (token_value == 817) return 3;   // TK_PRE_MINUS_MINUS -> AST_UN_OP_PRE_DEC
  if (token_value == 773) return 0;   // TK_PLUS_PLUS       -> AST_UN_OP_POST_INC
  if (token_value == 774) return 1;   // TK_MINUS_MINUS     -> AST_UN_OP_POST_DEC
  if (token_value == 43)  return 4;   // '+'                -> AST_UN_OP_PLUS
  if (token_value == 45)  return 5;   // '-'                -> AST_UN_OP_MINUS
  if (token_value == 126) return 7;   // '~'                -> AST_UN_OP_BIT_NOT
  if (token_value == 33)  return 6;   // '!'                -> AST_UN_OP_LOG_NOT
  if (token_value == 38)  return 8;   // '&'                -> AST_UN_OP_ADDR_OF
  if (token_value == 42)  return 9;   // '*'                -> AST_UN_OP_DEREF

  // Every other token value is not a unary operator.
  return -1;
}
