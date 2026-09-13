# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION03 — handoff

# Title:        C2 contract correction — fix EOF cursor UB
#               + restore l->start legacy postcondition
# Class:        PRODUCTION_BUGFIX / CONTRACT-CORRECTION /
#               (the FIRST production-source mutation in this
#                bootstrap; explicitly authorized by the
#                re-reviewer)
# Branch:       main
# Predecessor:  ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02
#               (closed PASS_WITH_RESIDUE)
# Successor:    ACT-POLYC-BOOTSTRAP02 C3 EVIDENCE (next;
#               fully unlocked by this correction)
# VERDICT:      PASS (no residue)
# HALT_CLASS:   NONE_FIRED
# Summary
# -------
#
# The re-reviewer of CORRECTION02 re-classified two
# previously-documented residues:
#
#   R1 l->start_after divergence:
#        P2 cleanup. BLOCKS_NEXT=NO. (Grep audit
#        verified no consumer reads l->start between
#        lexIdentifier and the next lexNextChar.)
#
#   R2 l->ptr_after divergence at EOF:
#        RE-CLASSIFIED from P1 (latent) to P0
#        (production semantic defect). The +1 advance
#        at EOF is undefined behaviour per the C
#        memory model: src + 4 is a one-past-end
#        pointer that the next lexNextChar would
#        dereference.
#
#        C4 CLOSE of the parent ACT was BLOCKED until
#        this was fixed.
#
# The re-reviewer recommended ONE bounded correction
# (not two): fix the stage1 branch of
# src/lexer.c::lexIdentifier to maintain BOTH
# l->ptr and l->start in the legacy invariant.
# The re-reviewer explicitly authorized the
# production-source mutation.

# Identity
# --------
#
# Entry HEAD:  ddd24de9d2cacba2174aa2c08f80858bb863b3ab
#              (end of ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02)
# Final HEAD:  <this-close-commit>
# Working tree at close: clean
# Branch:      main
# git replace -l at close: empty
# APPEND_ONLY_START_POINT (baf5dbd7...): not violated

# The fix (the FIRST production mutation in this bootstrap)
# ----------------------------------------------------------
#
# src/lexer.c::lexIdentifier stage1 branch:
#
#     -      if (end_off >= src_len || *final_ptr == '\0') {
#     -          l->ptr = (char *)(final_ptr + 1);
#     -      } else {
#     -          l->ptr = (char *)final_ptr;
#     -      }
#     +    l->ptr = (char *)final_ptr;
#     +    l->start = (char *)final_ptr;
#
# Two lines. The +1 branch (which was UB at EOF) is
# removed; the AT-the-byte branch becomes
# unconditional. The legacy invariant
# `l->start == l->ptr` is now mechanical.

# Three-pillar cursor evidence (FINAL post-fix taxonomy)
# -------------------------------------------------------
#
# PILLAR_A_OBJECT_PARITY              PASS 5/5
# PILLAR_B_COMPONENT_CURSOR_MODEL     PASS 6/6
# PILLAR_B_PRIME_PRODUCTION_LEXER     PASS 6/6 (NO RESIDUE)
# EOF_CURSOR_STATE_EQUIVALENCE        PASS
# EOF_POINTER_SAFETY                  PASS
# NON_EOF_PRODUCTION_CURSOR_EQ        PASS 6/6

# Quality gates at close
# ----------------------
#
# BOOTSTRAP01_CASES            = 15
# BOOTSTRAP01_PASS             = 15
# BOOTSTRAP01_FAIL             = 0
# BOOTSTRAP02_DIFFERENTIAL     = PASS 15/15 byte-identical
# BOOTSTRAP02_CURSOR_DIFF      = PASS 6/6 byte-identical
# BOOTSTRAP02_STAGE1_BINARY    = PRESENT
# BOOTSTRAP02_LEXER_SEAM       = PASS 6/6 (NO RESIDUE)
# END_TO_END_CONSERVATION      = PASS 5/5 real sources
# PRODUCTION_HERMETIC          = PASS
#
# gate-fast                    = PASS
# factory-v2                   = PASS=35 FAIL=0
# factory-append-only          = PASS=11 FAIL=0
# factory-halt-classification  = PASS=12 FAIL=0
# shell-loc-gate               = PASS
# factory-closure-status       = PASS 6/6

# Scope discipline
# ----------------
#
# Production-source mutation:  YES (2 lines, bounded to
#                              lexIdentifier stage1
#                              branch).
# B1 component mutation:       NONE.
# B0 component mutation:       NONE.
# Other production sources:    NONE.
# Build-system behaviour:      ZERO_PRODUCTION_BUILD_
#                              SEMANTIC_CHANGE (only
#                              test-only Makefile target
#                              modified).
# Authorization scope:         lexIdentifier stage1
#                              branch ONLY.

# Cardinality-1 invariant
# -----------------------
#
# Exactly one CLOSE commit for
# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION03:
#
#   git log --all-match --oneline \
#       --grep='^ACT: ACT-POLYC-BOOTSTRAP02-C2-CORRECTION03$' \
#       --grep='^ACT-Phase: CLOSE$'
#
# returns exactly 1 commit (<this-close-commit>).

# Residue
# -------
#
# R1 — REPAIRED (l->start_after divergence).
# R2 — REPAIRED (EOF cursor UB).
# R3 — Pre-existing PUSH_RESIDUE GEP01_D1_D2.
# R4 — INFORMATIONAL (factory-v2 NONBLOCKING_RESIDUE).
# R5 — Mechanical hygiene items (trailing whitespace,
#      extra blank line at EOF, "build-system change"
#      wording) — all classified GOVERNANCE /
#      BLOCKS_NEXT=NO per the re-reviewer.
#
# See c4/residue.txt.

# Next ACT
# --------
#
# ACT-POLYC-BOOTSTRAP02 C3 EVIDENCE is now FULLY
# UNLOCKED with NO residue:
#
#   - PILLAR_A_OBJECT_PARITY              PASS 5/5
#   - PILLAR_B_COMPONENT_CURSOR_MODEL     PASS 6/6
#   - PILLAR_B_PRIME_PRODUCTION_LEXER     PASS 6/6 (NO RESIDUE)
#   - EOF_CURSOR_STATE_EQUIVALENCE        PASS
#   - EOF_POINTER_SAFETY                  PASS
#   - NON_EOF_PRODUCTION_CURSOR_EQ        PASS 6/6
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

# No SHA-of-self claims (DOCTRINE.md §22).
