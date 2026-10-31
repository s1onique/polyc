// tools/bootstrap/selfhost-core-operator.HC
//
// ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C2 IMPL -- PolyC
// AbiCoreClassifyCompoundAssign, AbiCoreIsValidPointerOperator,
// AbiCoreIsRangeOperator.
//
// THE PRODUCTION CORE-OPERATOR CLASSIFIER (BUNDLE-OPERATOR-CORE-01).
//
// This component owns THREE operator-classification decisions that used
// to live in C:
//
//   SITE-COMPOUND-ASSIGN   src/prslib.c:1328..1348  parseCompoundAssign
//   SITE-VALID-POINTER-OP  src/ast.c:974..990        astIsValidPointerOp
//   SITE-RANGE-OPERATOR    src/ast.c:2348..2358      astIsRangeOperator
//
// It is compiled from PolyC source by the real hcc producer and linked
// into the production compiler.
//
// THE ABI (ABI-CORE-OP-1)
// =======================
//
//   I64 AbiCoreClassifyCompoundAssign(I64 token_type, I64 token_value,
//                                     I64 *out_operator);
//   I64 AbiCoreIsValidPointerOperator(I64 binary_operator);
//   I64 AbiCoreIsRangeOperator(I64 binary_operator);
//
// The exact contract is frozen in
// evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c1/abi-core-op-1.tsv.
//
// RESULT/STATUS SEPARATION
// ========================
//
// Every function returns a value in {0,1}. A NEGATIVE return value is
// reserved for a host status code and is disjoint from {0,1}. The
// functions are TOTAL over the whole I64 domain, so the status range is
// never actually produced; it exists so that a future failure mode can
// never be confused with a legitimate classification.
//
// For SITE-COMPOUND-ASSIGN the operator value does NOT travel in the
// return value: it travels in the out-parameter. That is deliberate.
// AST_BIN_OP_MUL is 0, which would collide with the "not a compound
// assignment" result 0. Splitting the two keeps them unambiguous.
//
// THE CONSTANTS ARE SOURCE VALUES, NOT LAYOUT ASSUMPTIONS
// ========================================================
//
// The component cannot include the C headers, so the enum and token
// values are written as their NUMERIC values. Every one of them was
// resolved from the LIVE source by the independent deriver
// (tools/quality/core-operator-implement01-enum-domain.sh) and is
// recorded in
// evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c1/enum-domain.tsv.
//
//   from src/lexer.h:
//     TK_IDENT        768   (0x300)
//     TK_PUNCT        809   (0x329)
//     TK_SHL_EQU      786   (0x312)
//     TK_SHR_EQU      787   (0x313)
//     TK_MUL_EQU      788   (0x314)
//     TK_DIV_EQU      789   (0x315)
//     TK_AND_EQU      790   (0x316)
//     TK_OR_EQU       791   (0x317)
//     TK_XOR_EQU      792   (0x318)
//     TK_ADD_EQU      793   (0x319)
//     TK_SUB_EQU      794   (0x31A)
//     TK_MOD_EQU      802   (0x322)
//
//   from src/ast.h (AstBinOp):
//     AST_BIN_OP_MUL        0
//     AST_BIN_OP_DIV        1
//     AST_BIN_OP_MOD        2
//     AST_BIN_OP_ADD        3
//     AST_BIN_OP_SUB        4
//     AST_BIN_OP_SHL        5
//     AST_BIN_OP_SHR        6
//     AST_BIN_OP_LT         7
//     AST_BIN_OP_LE         8
//     AST_BIN_OP_GT         9
//     AST_BIN_OP_GE        10
//     AST_BIN_OP_EQ        11
//     AST_BIN_OP_NE        12
//     AST_BIN_OP_BIT_AND   13
//     AST_BIN_OP_BIT_XOR   14
//     AST_BIN_OP_BIT_OR    15
//     AST_BIN_OP_LOG_AND   16
//     AST_BIN_OP_LOG_OR    17
//     AST_BIN_OP_ASSIGN    18
//
// PURITY CONSTRAINTS
// ==================
//
//   - no host AST, Lexeme, List, Map, Cctrl or Arena pointer;
//   - no allocation;
//   - no global mutable state;
//   - no callbacks;
//   - no setjmp / longjmp / recovery dependency;
//   - no diagnostics;
//   - TOTAL over the whole I64 domain.
//
// The ONLY side effect permitted anywhere in this component is the single
// scalar store into the caller-provided out-parameter cell of
// AbiCoreClassifyCompoundAssign, and only on success.
//
// NOTE ON THE REDUNDANT extern "c" DECLARATION
// =============================================
//
// The exported functions are NOT declared `extern "c"` here before their
// definitions. The PolyC parser mis-handles a file that declares the
// same function both as an extern and as a definition (it loses the
// function body and then fails on the following `return`). The subject
// still exports ordinary C symbols, as the existing production subjects
// (tools/bootstrap/selfhost-abi-compile-print-ast.HC) do.

// ---------------------------------------------------------------------------
// SITE-COMPOUND-ASSIGN
//
// A verbatim transcription of src/prslib.c:1328..1348:
//
//     static int parseCompoundAssign(Lexeme *tok, AstBinOp *_op) {
//         if (tok->tk_type != TK_PUNCT) {
//             return 0;
//         }
//
//         switch (tok->i64) {
//             case TK_ADD_EQU: *_op = AST_BIN_OP_ADD; return 1;
//             ...
//             default: return 0;
//         }
//     }
//
// The token_type is tested FIRST and the token_value is not examined when
// the type is not TK_PUNCT: that short-circuit is preserved exactly.
// ---------------------------------------------------------------------------
I64 AbiCoreClassifyCompoundAssign(I64 token_type, I64 token_value, I64 *out_operator)
{
  if (token_type != 809) {          // TK_PUNCT
    return 0;
  }

  if (token_value == 793) {         // TK_ADD_EQU
    *out_operator = 3;              // AST_BIN_OP_ADD
    return 1;
  }
  if (token_value == 794) {         // TK_SUB_EQU
    *out_operator = 4;              // AST_BIN_OP_SUB
    return 1;
  }
  if (token_value == 788) {         // TK_MUL_EQU
    *out_operator = 0;              // AST_BIN_OP_MUL
    return 1;
  }
  if (token_value == 789) {         // TK_DIV_EQU
    *out_operator = 1;              // AST_BIN_OP_DIV
    return 1;
  }
  if (token_value == 802) {         // TK_MOD_EQU
    *out_operator = 2;              // AST_BIN_OP_MOD
    return 1;
  }
  if (token_value == 790) {         // TK_AND_EQU
    *out_operator = 13;             // AST_BIN_OP_BIT_AND
    return 1;
  }
  if (token_value == 791) {         // TK_OR_EQU
    *out_operator = 15;             // AST_BIN_OP_BIT_OR
    return 1;
  }
  if (token_value == 792) {         // TK_XOR_EQU
    *out_operator = 14;             // AST_BIN_OP_BIT_XOR
    return 1;
  }
  if (token_value == 786) {         // TK_SHL_EQU
    *out_operator = 5;              // AST_BIN_OP_SHL
    return 1;
  }
  if (token_value == 787) {         // TK_SHR_EQU
    *out_operator = 6;              // AST_BIN_OP_SHR
    return 1;
  }

  // Every other token is not a compound assignment. The out-parameter is
  // NOT written, exactly as the original C leaves *_op untouched.
  return 0;
}

// ---------------------------------------------------------------------------
// SITE-VALID-POINTER-OP
//
// A verbatim transcription of src/ast.c:974..990:
//
//     int astIsValidPointerOp(AstBinOp op) {
//         switch (op) {
//             case AST_BIN_OP_SUB:
//             ...
//             case AST_BIN_OP_LOG_AND:
//                 return 1;
//             default:
//                 return 0;
//         }
//     }
// ---------------------------------------------------------------------------
I64 AbiCoreIsValidPointerOperator(I64 binary_operator)
{
  if (binary_operator == 4)  { return 1; }   // AST_BIN_OP_SUB
  if (binary_operator == 3)  { return 1; }   // AST_BIN_OP_ADD
  if (binary_operator == 7)  { return 1; }   // AST_BIN_OP_LT
  if (binary_operator == 8)  { return 1; }   // AST_BIN_OP_LE
  if (binary_operator == 9)  { return 1; }   // AST_BIN_OP_GT
  if (binary_operator == 10) { return 1; }   // AST_BIN_OP_GE
  if (binary_operator == 11) { return 1; }   // AST_BIN_OP_EQ
  if (binary_operator == 12) { return 1; }   // AST_BIN_OP_NE
  if (binary_operator == 17) { return 1; }   // AST_BIN_OP_LOG_OR
  if (binary_operator == 16) { return 1; }   // AST_BIN_OP_LOG_AND

  return 0;
}

// ---------------------------------------------------------------------------
// SITE-RANGE-OPERATOR
//
// A verbatim transcription of src/ast.c:2348..2358:
//
//     int astIsRangeOperator(AstBinOp op) {
//         switch (op) {
//             case AST_BIN_OP_GE:
//             case AST_BIN_OP_GT:
//             case AST_BIN_OP_LE:
//             case AST_BIN_OP_LT:
//                 return 1;
//             default:
//                 return 0;
//         }
//     }
// ---------------------------------------------------------------------------
I64 AbiCoreIsRangeOperator(I64 binary_operator)
{
  if (binary_operator == 10) { return 1; }   // AST_BIN_OP_GE
  if (binary_operator == 9)  { return 1; }   // AST_BIN_OP_GT
  if (binary_operator == 8)  { return 1; }   // AST_BIN_OP_LE
  if (binary_operator == 7)  { return 1; }   // AST_BIN_OP_LT

  return 0;
}
