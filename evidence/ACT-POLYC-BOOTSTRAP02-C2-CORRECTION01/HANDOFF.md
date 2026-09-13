# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01 — handoff

# Title:        C2 contract correction — re-author §14
#               wording; add pillar-B direct cursor witness
# Class:        GOVERNANCE / DOC-STRUCTURE / CONTRACT-CORRECTION
# Branch:       main
# Predecessor:  ACT-POLYC-BOOTSTRAP02 C2 IMPL
#               (27cbb33, 92f44f5, 0534db2, 46ba567, 3942df2)
# Successor:    ACT-POLYC-BOOTSTRAP02 C3 EVIDENCE (next;
#               unlocked by this correction)
# VERDICT:      PASS_WITH_CORRECTION_RESIDUE
# HALT_CLASS:   NONE_FIRED

# Summary
# -------
#
# A reviewer audit of the C2 IMPL trail identified two
# bounded defects, both governance / evidence
# classification issues, neither requiring semantic code
# change:
#
#   P0 — ACT §14 wording over-narrow ("No #ifdef"
#        forbidden literally; C2 IMPL uses a build-time
#        #ifdef for stage separation; semantically
#        correct, literally violates the wording).
#        Correction: re-author §14 to forbid only runtime
#        fallback in hcc-bootstrap02.
#
#   P1 — cursor-equivalence.txt over-claims that byte-
#        identical objects imply identical token streams.
#        Correction: reframe as two-pillar taxonomy (A =
#        end-to-end conservation; B = direct seam-level
#        cursor witness). Pillar B is added in C2 IMPL
#        with a 6-input reviewer matrix.

# Identity
# --------
#
# Entry HEAD:  3942df26c496e18d1ebbe7b6423c7aa1b195a920
#              (end of ACT-POLYC-BOOTSTRAP02 C2 IMPL trail)
# Final HEAD:  <this-close-commit>
# Working tree at close: clean
# Branch:      main
# git replace -l at close: empty
# APPEND_ONLY_START_POINT (baf5dbd7...): not violated

# Quality gates at close
# ----------------------
#
# BOOTSTRAP01_CASES            = 15
# BOOTSTRAP01_PASS             = 15
# BOOTSTRAP01_FAIL             = 0
# BOOTSTRAP02_DIFFERENTIAL     = PASS 15/15 byte-identical
# BOOTSTRAP02_CURSOR_DIFF      = PASS 6/6 byte-identical
# BOOTSTRAP02_STAGE1_BINARY    = PRESENT
# END_TO_END_CONSERVATION      = PASS 5/5 real sources
# PRODUCTION_HERMETIC          = PASS
#
# gate-fast                    = PASS
# factory-v2                   = PASS=35 FAIL=0
# factory-append-only          = PASS=11 FAIL=0
# factory-halt-classification  = PASS=12 FAIL=0
# shell-loc-gate               = PASS
# factory-closure-status       = PASS (6/0)

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
#   docs/acts/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01.md
#   evidence/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01/{c1,c3,c4}/
#   evidence/ACT-POLYC-BOOTSTRAP02/c2/cursor-direct-witness.txt
#   tools/quality/bootstrap02-cursor-{host,oracle}.c
#   Makefile (one new target: bootstrap02-cursor-test)
# In-scope rewrites:
#   evidence/ACT-POLYC-BOOTSTRAP02/c2/cursor-equivalence.txt
#   evidence/ACT-POLYC-BOOTSTRAP02/c2/implementation-delta.txt
#   evidence/ACT-POLYC-BOOTSTRAP02/c2/required-result.txt

# Cardinality-1 invariant
# -----------------------
#
# Exactly one CLOSE commit for
# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01:
#
#   git log --all-match --oneline \
#       --grep='^ACT: ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01$' \
#       --grep='^ACT-Phase: CLOSE$'
#
# returns exactly 1 commit (<this-close-commit>).

# Residue
# -------
#
#   P0 — REPAIRED
#   P1 — REPAIRED
#   P2 — UNCHANGED (pre-existing GEP01_D1_D2)
#   P3 — INFORMATIONAL (factory-v2 PASS_WITH_NONBLOCKING_RESIDUE)
#
# See c4/residue.txt.

# Next ACT
# --------
#
# ACT-POLYC-BOOTSTRAP02 C3 EVIDENCE is now UNLOCKED.
#
# The corrected two-pillar cursor evidence
# (pillar A: end-to-end conservation; pillar B: direct
# seam-level cursor witness) satisfies the reviewer-
# blocked C2-to-C3 transition.
#
# C3 EVIDENCE should:
#   - Extend the production-source corpus (compile every
#     .HC file in src/holyc-lib/ and src/tests/ with both
#     stage0 and stage1; capture byte-parity diff).
#   - If a token-dump seam exists in the production
#     lexer, capture identical-token-stream diffs.
#   - Consolidate all gates into the C3 required-result
#     block per ACT §15.
#   - Open C4 CLOSE for ACT-POLYC-BOOTSTRAP02.
#
# No further governance correction is warranted before
# C3 EVIDENCE may proceed.

# No SHA-of-self claims (DOCTRINE.md §22).
