# ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05
# ACT_PHASE=C2-RANK-SELECT
# EVIDENCE_KIND=selected-production-seam
#
# THE PRODUCTION SEAM.  ONE CONDITION, ONE DELEGATION.
#
# THE CURRENT ACTIVE C DECISION (src/parser.c:2047..2053)
#
#   2047  } else {
#   2048      if ((stmt = parseStatement(cc)) != NULL) {
#   2049          if (stmt->kind == AST_DECL && stmt->declvar->kind == AST_GVAR) {
#   2050              tok = cctrlTokenPeek(cc);
#   2051              continue;
#   2052          }
#   2053          listAppend(body->stms,stmt);
#;
# THE PROPOSED ONE-CONDITION DELEGATION
#
#   2047  } else {
#   2048      if ((stmt = parseStatement(cc)) != NULL) {
#   2049  #ifdef HCC_USE_SELFHOST_PARSER_COMPOUND_APPEND
#            int declvar_kind = (stmt->kind == AST_DECL)
#                                    ? (int)stmt->declvar->kind : 0;
#            if (!BootstrapCompoundBlockAppendsStatement((long long)stmt->kind,
#                                                     (long long)declvar_kind)) {
#                tok = cctrlTokenPeek(cc);
#                continue;
#            }
#   #else
#            if (stmt->kind == AST_DECL && stmt->declvar->kind == AST_GVAR) {
#                tok = cctrlTokenPeek(cc);
#                continue;
#            }
#   #endif
#            listAppend(body->stms,stmt);
#
# THE SEAM PROPERTIES
#
#   ONE condition.  The delegation replaces exactly one
#   decision.  No other line of the enclosing function changes.
#   The C side still owns the `continue` (the SKIP action) and the
#   `listAppend` (the APPEND action).  The PolyC component only
#   DECIDES.
#
#   NO SHADOW CALL.  The legacy condition is NOT evaluated before,
#   after or alongside the delegation, and there is no fallback to C.
#   The legacy body survives only in the non-delegated build, which
#   is the G0 oracle object.
#
#   THE SHORT-CIRCUIT IS PRESERVED.  The C side evaluates
#   `stmt->declvar->kind` ONLY when `stmt->kind == AST_DECL`, exactly
#   as the legacy && did.  The component therefore never sees an
#   unevaluated host pointer.
#
#   THE DEDICATED SELECTOR.  A new dedicated macro
#   HCC_USE_SELFHOST_PARSER_COMPOUND_APPEND, independent of the six
#   existing selectors, so this migration does not couple itself to
#   the padding, control-flow-token, precedence, AST-binop,
#   AST-unary, switch-arm or generic-lexer selectors.
#
#   THE FAIL-CLOSED DISCIPLINE.  If the producer is configured but
#   the component is missing, the build MUST fail, never silently
#   fall back to the legacy C body.  This mirrors the discipline of
#   the six already-migrated authorities.
#
#   THE VERIFIER.  src/cmake/VerifyAstTokenMapObject.cmake is already
#   fully PARAMETERIZED and is reused READ-ONLY with the expected
#   symbol and the TARGET OBJECT FORMAT passed EXPLICITLY, exactly as
#   SLICE06 did.  There is no second, weaker verifier to drift.
#
# PRODUCTION_CALL_SITE=src/parser.c:2049
# DELEGATION_SITES=1
# SHADOW_CALLS=0
# FALLBACK_TO_C=0
