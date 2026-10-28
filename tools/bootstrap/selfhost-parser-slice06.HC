// tools/bootstrap/selfhost-parser-slice06.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06 C2 IMPL -- PolyC
// BootstrapSwitchArmTerminates.
//
// WINNER SUBJECT.  Decides the switch-case ARM TERMINATION.
//
// Frozen ABI (the predecessor's c2/selected-abi-contract.md):
//   I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64;
//
// Input:
//   ast_kind : I64, the NUMERIC AstKind enum value of the statement that
//              was just parsed by parseStatement
//
// Output:
//   1        the arm TERMINATES (the C side executes the `break`)
//   0        the arm CONTINUES (the C side keeps parsing the arm)
//
// THE MAPPING IS TRANSCRIBED FROM THE REAL LEGACY CONDITION
// =========================================================
//
// This is the legacy decision at src/parser.c:1551..1553, transcribed
// exactly:
//
//   if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE ||
//           stmt->kind == AST_DEFAULT || stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
//           || stmt->kind == AST_GOTO) break;
//
// The six terminating kinds are the live src/ast.h values:
//
//   AST_COMPOUND_STMT    274
//   AST_CASE             287
//   AST_DEFAULT          293
//   AST_BREAK            280
//   AST_RETURN           270
//   AST_GOTO             258
//
// These six values were MEASURED by executing the REAL legacy oracle
// (the actual production src/parser.c object with the delegation OFF)
// over the whole derived fixture matrix, and the values were resolved
// from the live src/ast.h by COMPILING it.  See
// evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/c1/compiled-enum-values.tsv
// and c1/real-oracle.txt.
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
// The legacy condition is a BOOLEAN: every AstKind value is either in
// the terminating set or it is not.  There is NO "not found" case, so
// there is NO failure sentinel and no error return.  Every I64 maps to
// exactly one of {0, 1}.
//
// NO ENUM RANGE CHECK
// ===================
//
// The legacy condition does NOT check whether the value is a valid
// AstKind: it compares the value against six constants and terminates
// the arm if any of them matches.  An out-of-enum value simply matches
// none of them, so the arm CONTINUES.  Adding a range check here would
// CHANGE the result for the out-of-enum probes, so this component does
// not add one.
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
// ACT-POLYC-SELFHOST-PARSER-SLICE06 qualifies it and delegates
// production authority to it.

I64 BootstrapSwitchArmTerminates(I64 ast_kind)
{
  if (ast_kind == 274) return 1;   // AST_COMPOUND_STMT
  if (ast_kind == 287) return 1;   // AST_CASE
  if (ast_kind == 293) return 1;   // AST_DEFAULT
  if (ast_kind == 280) return 1;   // AST_BREAK
  if (ast_kind == 270) return 1;   // AST_RETURN
  if (ast_kind == 258) return 1;   // AST_GOTO

  // Every other value -- including every out-of-enum probe -- does not
  // terminate the arm.
  return 0;
}
