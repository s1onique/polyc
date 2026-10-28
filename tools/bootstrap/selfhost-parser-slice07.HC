// tools/bootstrap/selfhost-parser-slice07.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE07 C2 IMPL -- PolyC
// BootstrapCompoundBlockAppendsStatement.
//
// WINNER SUBJECT.  Decides the COMPOUND-BLOCK STATEMENT APPEND/SKIP
// ROUTING.
//
// Frozen ABI (the predecessor's c2/selected-abi.md):
//   I64 BootstrapCompoundBlockAppendsStatement(I64 stmt_kind,
//                                               I64 declvar_kind) -> I64;
//
// Input:
//   stmt_kind    : I64, the NUMERIC AstKind enum value of the parsed
//                  statement
//   declvar_kind : I64, the NUMERIC AstKind enum value of
//                  stmt->declvar
//
// Output:
//   1        APPEND the statement to the compound block's statement
//            list (the C side acts)
//   0        SKIP the statement (the C side acts)
//
// THE MAPPING IS TRANSCRIBED FROM THE REAL LEGACY CONDITION
// =========================================================
//
// This is the legacy decision at src/parser.c:2049, transcribed
// exactly:
//
//   if (stmt->kind == AST_DECL && stmt->declvar->kind == AST_GVAR) {
//       tok = cctrlTokenPeek(cc);
//       continue;
//   }
//   listAppend(body->stms,stmt);
//
// The two relevant enum values are the live src/ast.h values:
//
//   AST_DECL          263
//   AST_GVAR          256
//
// These two values were MEASURED by compiling the LIVE src/ast.h (see
// evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c1/live-ast-enums.tsv)
// and by executing the REAL legacy oracle (the actual production
// src/parser.c object with the delegation OFF) over the whole derived
// fixture matrix.
//
// THE CONSTANTS ARE WRITTEN AS NUMBERS
// =====================================
//
// The PolyC component cannot include the legacy C header, so the
// constants are written as their NUMERIC values.  The binding that
// matters is the numeric one, and every value below was resolved from
// the live src/ast.h by compiling it.
//
// THE COMPONENT IS TOTAL
// ======================
//
// The legacy condition is a BOOLEAN: the statement is a global-variable
// declaration or it is not.  There is NO "not found" case, so there is
// NO failure sentinel and no error return.  Every I64 pair maps to
// exactly one of {0, 1}.
//
// NO ENUM RANGE CHECK
// ===================
//
// The legacy condition does NOT check whether the value is a valid
// AstKind: it compares the value against two constants.  An
// out-of-enum value simply matches neither of them, so the statement
// is APPENDED.  Adding a range check here would CHANGE the result for
// the out-of-enum probes, so this component does not add one.
//
// THE SECOND ARGUMENT IS IRRELEVANT FOR NON-DECLARATIONS
// =====================================================
//
// The legacy `&&` short-circuits: `stmt->declvar->kind` is consulted
// ONLY when `stmt->kind == AST_DECL`.  This component preserves that
// short-circuit: when `stmt_kind != AST_DECL` the `declvar_kind`
// argument is NOT consulted at all, exactly as the legacy condition
// did.  The C side never reads `stmt->declvar` in that case either
// (see the projection guard in parseCompoundStatementInternal).
//
// Purity constraints:
//   - no host AST pointers
//   - no allocation
//   - no global mutable state
//   - no callbacks
//   - no recovery dependency
//   - the function is TOTAL over the whole I64 domain
//
// This file is a candidate self-hosted PolyC component.
// ACT-POLYC-SELFHOST-PARSER-SLICE07 qualifies it and delegates
// production authority to it.

I64 BootstrapCompoundBlockAppendsStatement(I64 stmt_kind, I64 declvar_kind)
{
  // The one and only semantic decision.  The short-circuit is
  // preserved: the second comparison happens ONLY when the first
  // matches.
  if (stmt_kind == 263) {   // AST_DECL
    if (declvar_kind == 256) {   // AST_GVAR
      return 0;   // SKIP: a global-variable declaration inside a block
    }
  }

  // Every other value -- including every out-of-enum probe, every
  // negative probe and every extreme I64 -- APPENDS.
  return 1;
}
