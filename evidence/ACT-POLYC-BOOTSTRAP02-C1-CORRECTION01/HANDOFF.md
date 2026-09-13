# ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01 — handoff

# Title:        C1 contract correction — replace malformed
#               grammar predicate with corrected four-clause
#               gate; bound the ctype non-ASCII claim;
#               reframe the oracle evidentiary role
# Class:        GOVERNANCE / DOC-STRUCTURE / CONTRACT-CORRECTION
# Branch:       main
# Predecessor:  ACT-POLYC-BOOTSTRAP02 (C1 RED: aa29e16, db038e9)
# Successor:    ACT-POLYC-BOOTSTRAP02 C2 IMPL (next; not yet
#               authored as separate commits)
# VERDICT:      PASS_WITH_CORRECTION_RESIDUE
# HALT_CLASS:   NONE_FIRED

# Summary
# -------
#
# Three C1 governance defects in the predecessor ACT's
# required-result block were repaired without any
# production-source mutation:
#
#   P0  IDENTITY_GRAMMAR_EQUIVALENT replaced by
#       IDENTIFIER_GRAMMAR_GATE (4-clause);
#       HALT_B1_IDENTIFIER_CONTRACT_MISMATCH clause
#       replaced by the 3-clause corrected predicate.
#
#   P1  ctype non-ASCII equivalence bounded;
#       B1_IDENTIFIER_CHARACTER_DOMAIN = ASCII;
#       B1 component must use explicit byte comparisons.
#
#   P2  oracle evidentiary role reframed as REFERENCE_MODEL;
#       C3 must additionally test stage0/stage1 compiler
#       corpus on a real production source.

# Identity
# --------
#
# Entry HEAD:  db038e9553133b5dc1c1d639e41f3c6306888f70
# Final HEAD:  <this-close-commit>
# Working tree at close: clean
# git replace -l at close: empty
# APPEND_ONLY_START_POINT (baf5dbd7...): not violated

# Quality gates at close
# ----------------------
#
# BOOTSTRAP01_CASES        = 15
# BOOTSTRAP01_PASS         = 15
# BOOTSTRAP01_FAIL         = 0
# BOOTSTRAP01_STATUS       = PASS
#
# gate-fast_verdict        = PASS
# factory-v2               = PASS=35 FAIL=0
# factory-append-only      = PASS=11 FAIL=0
# factory-halt-class       = PASS=12 FAIL=0
# shell-loc-gate           = PASS
# factory-closure-status   = PASS (6/0)
# git replace -l           = empty
# git diff --check         = clean

# Scope discipline
# ----------------
#
# Authorized production source mutation: NONE.
# src/lexer.c, src/lexer.h, src/CMakeLists.txt, Makefile,
# tools/bootstrap/bootstrap02-ident.HC, src/lexer_bridge.h
# are all UNCHANGED across this correction ACT.

# Cardinality-1 invariant
# -----------------------
#
# Exactly one CLOSE commit for ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01:
#
#   git log --all-match --oneline \
#       --grep='^ACT: ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01$' \
#       --grep='^ACT-Phase: CLOSE$'
#
# returns exactly 1 commit (<this-close-commit>).

# Residue
# -------
#
# See evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c4/residue.txt
#
#   P0 — REPAIRED
#   P1 — BOUNDED (B1 ASCII-only)
#   P2 — DEFERRED (non-ASCII production behavior; not in B1 scope)
#   P3 — INFORMATIONAL (ctype normalization; documented)

# Next ACT
# --------
#
# ACT-POLYC-BOOTSTRAP02 C2 IMPL is now authorized with the
# corrected gate. The C2 IMPL must:
#
#   1. Write tools/bootstrap/bootstrap02-ident.HC using
#      EXPLICIT BYTE COMPARISONS (no ctype.h).
#   2. Add src/lexer_bridge.h declaring BootstrapScanIdent.
#   3. Modify src/lexer.c::lexIdentifier to delegate to
#      BootstrapScanIdent. No fallback.
#   4. Add a Makefile / CMake stage1 build target producing
#      build/hcc-bootstrap02 (separate from ./hcc).
#   5. Capture C2 evidence:
#      implementation-delta.txt, stage0-component-build.txt,
#      stage1-link.txt, symbol-binding.txt, b0-conservation.txt.
#
# C3 EVIDENCE (after C2) must additionally include a
# stage0/stage1 differential on a real production source
# corpus (e.g. src/holyc-lib/dir.HC::_opendir$INODE64),
# per the corrected oracle evidentiary role.

# No SHA-of-self claims (DOCTRINE.md §22).
