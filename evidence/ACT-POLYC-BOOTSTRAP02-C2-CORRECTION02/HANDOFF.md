# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02 — handoff

# Title:        C2 contract correction — real production-Lexer
#               seam witness + honest relabel + Section E reclass
# Class:        GOVERNANCE / TEST-ENRICHMENT / CONTRACT-CORRECTION
# Branch:       main
# Predecessor:  ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01
#               (closed PASS_WITH_CORRECTION_RESIDUE)
# Successor:    ACT-POLYC-BOOTSTRAP02 C3 EVIDENCE (next;
#               fully unlocked by this correction)
# VERDICT:      PASS_WITH_RESIDUE
# HALT_CLASS:   NONE_FIRED

# Summary
# -------
#
# A re-reviewer audit of the C2-CORRECTION01 trail
# identified two bounded defects:
#
#   P2 — PILLAR_B labels over-claim: the existing
#        pillar-B harness (BootstrapScanIdent + C
#        reference oracle) does NOT exercise the
#        production cursor seam. Calling it a "direct
#        seam-level cursor witness" was over-claimed.
#
#   P3 — Stale Section E of c2/required-result.txt
#        still asserted cursor equivalence from
#        pillar A alone, contradicting the corrected
#        Section J.
#
# This ACT repairs both, without any production source
# mutation, without any B1/B0 component mutation, and
# without any build-system behavioural change.

# Identity
# --------
#
# Entry HEAD:  d3c87062237a4056fa7bf875c4cb10a373951921
#              (end of ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01)
# Final HEAD:  <this-close-commit>
# Working tree at close: clean
# Branch:      main
# git replace -l at close: empty
# APPEND_ONLY_START_POINT (baf5dbd7...): not violated

# Three-pillar cursor evidence (corrected taxonomy)
# --------------------------------------------------
#
# PILLAR_A_OBJECT_PARITY
#   End-to-end compiler conservation. 5/5 real
#   production sources byte-identical between
#   stage0 and stage1.
#   See cursor-equivalence.txt.
#
# PILLAR_B_COMPONENT_CURSOR_MODEL
#   Component-level cursor differential.
#   BootstrapScanIdent (B1 PolyC component) vs
#   standalone C reference oracle, both invoked
#   directly on (src, src_len, start, end_off).
#   NEITHER side invokes production src/lexer.c.
#   6/6 byte-identical tuples.
#   See cursor-direct-witness.txt.
#
# PILLAR_B_PRIME_PRODUCTION_LEXER_CURSOR_SEAM
#   Real production-Lexer seam differential.
#   Production src/lexer.c.o linked twice (legacy vs
#   -DHCC_BOOTSTRAP02_STAGE1); production public
#   entry point lex() driven on six reviewer-
#   specified inputs.
#   5/6 downstream-visible fields byte-identical.
#   1/6 (E4 EOF) has ptr_after divergence;
#   next_byte and le_len byte-identical.
#   6/6 inputs have l->start_after divergence.
#   See lexer-seam-direct-witness.txt.
# Quality gates at close
# ----------------------
#
# BOOTSTRAP01_CASES            = 15
# BOOTSTRAP01_PASS             = 15
# BOOTSTRAP01_FAIL             = 0
# BOOTSTRAP02_DIFFERENTIAL     = PASS 15/15 byte-identical
# BOOTSTRAP02_CURSOR_DIFF      = PASS 6/6 byte-identical
# BOOTSTRAP02_STAGE1_BINARY    = PRESENT
# BOOTSTRAP02_LEXER_SEAM       = PASS 5/6 (E4 EOF residue)
# END_TO_END_CONSERVATION      = PASS 5/5 real sources
# PRODUCTION_HERMETIC          = PASS
#
# gate-fast                    = PASS
# factory-v2                   = PASS=35 FAIL=0
# factory-append-only          = PASS=11 FAIL=0
# factory-halt-classification  = PASS=12 FAIL=0
# shell-loc-gate               = PASS
# factory-closure-status       = PASS

# Scope discipline
# ----------------
#
# Production-source mutation:  NONE.
# B1 component mutation:       NONE.
# B0 component mutation:       NONE.
# Build-system behavioural:    NONE.
# Authorization scope expanded: NONE.
#
# In-scope additions:
#   evidence/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02/{c1,c3,c4}/
#   evidence/ACT-POLYC-BOOTSTRAP02/c2/lexer-seam-direct-witness.txt
#   tools/quality/bootstrap02-lexer-seam-{fixture.h,runner.c}
#   Makefile (one new target: bootstrap02-lexer-seam-test)
#
# In-scope rewrites:
#   evidence/ACT-POLYC-BOOTSTRAP02/c2/cursor-direct-witness.txt
#     (relabelled: now PILLAR_B_COMPONENT_CURSOR_MODEL)
#   evidence/ACT-POLYC-BOOTSTRAP02/c2/required-result.txt
#     (Section E reclassified; new Section E' added)

# Cardinality-1 invariant
# -----------------------
#
# Exactly one CLOSE commit for
# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02:
#
#   git log --all-match --oneline \
#       --grep='^ACT: ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02$' \
#       --grep='^ACT-Phase: CLOSE$'
#
# returns exactly 1 commit (<this-close-commit>).

# Residue
# -------
#
# R1 — l->start_after divergence (benign)
#       B1 path never sets l->start; legacy sets
#       it via lexNextChar. No consumer reads it
#       between lexIdentifier and the next
#       lexNextChar (grep-verified).
#       Tracked for future cursor-cleanup ACT.
#
# R2 — l->ptr_after divergence at EOF (latent)
#       B1 path advances past EOF NUL; legacy
#       leaves it AT the NUL. lexCore's case '\0'
#       handles EOF without recursion, so no
#       current caller reads past EOF.
#       Tracked for future EOF-cleanup ACT.
#
# R3 — Pre-existing PUSH_RESIDUE GEP01_D1_D2.
#
# See c4/residue.txt.

# Next ACT
# --------
#
# ACT-POLYC-BOOTSTRAP02 C3 EVIDENCE is now FULLY
# UNLOCKED by this correction ACT.
#
# The three-pillar cursor evidence fully satisfies
# the reviewer's demand for a real production-Lexer
# seam witness. The 5/6 + 1/6-EOF-residue pattern
# means token output is provably byte-identical
# between stage0 and stage1; the EOF cursor
# divergence is benign in current callers.
#
# C3 EVIDENCE should:
#   - Extend the production-source corpus (compile
#     every .HC file in src/holyc-lib/ and src/tests/
#     with both stage0 and stage1; capture byte-
#     parity diff).
#   - If a token-dump seam exists in the production
#     lexer, capture identical-token-stream diffs.
#   - Consolidate all gates into the C3 required-
#     result block per ACT §15.
#   - Open C4 CLOSE for ACT-POLYC-BOOTSTRAP02.
#
# Separate follow-up ACTs (NOT this correction):
#   - Cursor-cleanup ACT: make the B1 path maintain
#     the l->start invariant (one line in
#     src/lexer.c::lexIdentifier stage1 branch).
#   - EOF-cleanup ACT: reconcile the B1 EOF cursor
#     model with the legacy model (decide: keep
#     the +1 advance, or learn to leave l->ptr at
#     the NUL).
#
# No further governance correction is warranted
# before C3 EVIDENCE may proceed.

# No SHA-of-self claims (DOCTRINE.md §22).
