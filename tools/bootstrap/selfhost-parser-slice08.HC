// tools/bootstrap/selfhost-parser-slice08.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE08 C2 IMPL -- PolyC
// BootstrapDefaultArmTerminates.
//
// WINNER SUBJECT.  Decides the DEFAULT-ARM TERMINATION.
//
// Frozen ABI (the predecessor's c2/selected-abi.md):
//   I64 BootstrapDefaultArmTerminates(I64 ast_kind) -> I64;
//
// Input:
//   ast_kind : I64, the NUMERIC AstKind enum value of the statement
//              that was just parsed by parseStatement
//
// Output:
//   1        the default arm TERMINATES (the C side executes the `break`)
//   0        the default arm CONTINUES (the C side keeps parsing the arm)
//
// THE MAPPING IS TRANSCRIBED FROM THE REAL LEGACY CONDITION
// =========================================================
//
// This is the legacy decision at src/parser.c:1683..1684, transcribed
// exactly:
//
//   if (stmt->kind == AST_COMPOUND_STMT || stmt->kind == AST_CASE ||
//           stmt->kind == AST_BREAK || stmt->kind == AST_RETURN
//           || stmt->kind == AST_GOTO) break;
//
// The five terminating kinds are the live src/ast.h values:
//
//   AST_COMPOUND_STMT    274
//   AST_CASE             287
//   AST_BREAK            280
//   AST_RETURN           270
//   AST_GOTO             258
//
// These five values were MEASURED by COMPILING the LIVE src/ast.h and
// by executing the REAL legacy oracle (the actual production
// src/parser.c object with the delegation OFF) over the whole derived
// fixture matrix.  See
// evidence/ACT-POLYC-SELFHOST-PARSER-SLICE08/c1/live-enums-and-rule.tsv
// and c1/source-bound-fixture.tsv.
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
// The legacy condition is a BOOLEAN: the statement terminates the
// default arm or it does not.  There is NO "not found" case, so there
// is NO failure sentinel and no error return.  Every I64 maps to
// exactly one of {0, 1}.
//
// NO ENUM RANGE CHECK
// ===================
//
// The legacy condition does NOT check whether the value is a valid
// AstKind: it compares the value against five constants and terminates
// the arm if any of them matches.  An out-of-enum value simply matches
// none of them, so the arm CONTINUES.  Adding a range check here would
// CHANGE the result for the out-of-enum probes, so this component does
// not add one.
//
// THIS IS NOT THE SUB-001 DECISION
// =================================
//
// The already-migrated switch-CASE-arm decision is owned by
// BootstrapSwitchArmTerminates (SLICE06).  That decision terminates on
// SIX kinds: the five above PLUS AST_DEFAULT (293).
//
// THIS decision terminates on FIVE kinds and DELIBERATELY EXCLUDES
// AST_DEFAULT (293).  A `default:` arm that contains a nested
// `default:` label does NOT terminate on that label here.
//
// The two decisions therefore have DIFFERENT semantics, DIFFERENT
// production call sites (parseCaseLabel vs parseDefaultStatement) and
// DIFFERENT exported symbols.  Reusing the SUB-001 symbol here would
// silently change the default-arm behaviour, and the C0 RED-5
// experiment demonstrated that by REAL EXECUTION: the SUB-001 PolyC
// object returns 1 for kind 293, where the frozen SUB-002 fixture
// requires 0 at row 35.
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
// ACT-POLYC-SELFHOST-PARSER-SLICE08 qualifies it and delegates
// production authority to it.

I64 BootstrapDefaultArmTerminates(I64 ast_kind)
{
  if (ast_kind == 274) return 1;   // AST_COMPOUND_STMT
  if (ast_kind == 287) return 1;   // AST_CASE
  if (ast_kind == 280) return 1;   // AST_BREAK
  if (ast_kind == 270) return 1;   // AST_RETURN
  if (ast_kind == 258) return 1;   // AST_GOTO

  // Every other value -- including AST_DEFAULT (293) and every
  // out-of-enum probe -- does NOT terminate the default arm.
  return 0;
}
