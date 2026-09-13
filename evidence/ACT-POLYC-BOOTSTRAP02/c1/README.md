# ACT-POLYC-BOOTSTRAP02 — C1 RED packet
# ======================================
# (current-truth revision after ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01)
#
# Class:    BOOTSTRAP / PARTIAL-SELF-HOST / LEXER
# Factory:  v2
# Phase:    C1 RED (no production mutation)
# Branch:   main
# HEAD at entry:    b565587d47b3bd6d0931f18cd443d00c9d7dea57
# HEAD at C1 close: db038e9553133b5dc1c1d639e41f3c6306888f70
# git status:       clean
# git replace -l:   empty
# APPEND_ONLY_START_POINT (baf5dbd7...): not violated
#
# Supersedes / corrected by:
#   ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01
#   evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c1/
#
# Mission
# -------
#
# Mechanically identify the real production identifier-span
# seam in the current hcc compiler, freeze the production
# identifier grammar, prove that a PolyC component using
# the same grammar can be safely compiled by stage0 hcc and
# called from a C harness (ABI witness), and prove the B1
# dependency matrix (MEMORY01 fence not needed, GEP01
# harness not needed).
#
# No production mutation happens in C1. C1 either HALTs at
# RED or produces the dependency decision required for C2
# to be authorized.

# Required-result block (AC01..AC08)
# ----------------------------------
#
# See c1-required-result.txt. The block is the binding
# contract between C1 and C2.
#
# Per C1-CORRECTION01, the predicate
# `IDENTIFIER_GRAMMAR_EQUIVALENT = YES` is replaced by
# `IDENTIFIER_GRAMMAR_GATE = PASS`. See
# evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c1/
# corrected-grammar-gate.txt for the new binding gate.

# Files (current truth, in this directory)
# ----------------------------------------
#
#   README.md                          this file
#   lexer-seam-map.txt                 AC01: production identifier seam
#   identifier-contract.txt            AC02, AC03: grammar freeze + B0 diff
#   legacy-ident-oracle.tsv            AC04: REFERENCE_MODEL oracle
#   abi-witness.txt                    AC05: PolyC -> C-callable object ABI
#   dependency-matrix.txt              AC06, AC07: MEMORY01/GEP01 dependency
#   entry-conservation-baseline.txt    AC08: frozen entry gate counts
#   principal-red.txt                  §32: STAGE0_IDENTIFIER_SELF_HOSTED = NO
#   c1-required-result.txt             binding result block (corrected)

# Cross-references
# ----------------
#
#   Predecessor ACT:     docs/acts/ACT-POLYC-BOOTSTRAP01.md
#                        docs/acts/ACT-POLYC-BOOTSTRAP01-CORRECTION01.md
#                        (B0 closure: GREEN_WITH_CLOSURE_CORRECTION)
#   This ACT:            docs/acts/ACT-POLYC-BOOTSTRAP02.md
#   C1 correction ACT:   docs/acts/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01.md
#                        evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c1/
#   Governance predec.:  docs/acts/ACT-POLYC-FACTORY-HISTORICAL-EXCEPTIONS-REGISTRY01.md
#   Production lexer:    src/lexer.c   (2163 lines)
#   Production lexer API: src/lexer.h   (TK_IDENT = 0x300,
#                                        Lexer / Lexeme / LexFile structs)
#   B0 subject:          tools/bootstrap/bootstrap01-lexer.HC
#                        (BTK_IDENT = 1; identifier grammar
#                         [A-Za-z_][A-Za-z0-9_]* — no $)
#   B0 fixtures:         evidence/ACT-POLYC-BOOTSTRAP01/c1/bootstrap01-fixtures.tsv
#   B0 lexical contract: evidence/ACT-POLYC-BOOTSTRAP01/c1/lexical-contract.txt

# What C1 does NOT do
# -------------------
#
# - does NOT modify src/lexer.c, src/lexer.h, src/CMakeLists.txt
# - does NOT introduce any new PolyC component yet (C2's job)
# - does NOT introduce any stage1 build target yet (C2's job)
# - does NOT touch parser/AST/IR/backend/runtime
# - does NOT push to origin/main
#
# Per C1-CORRECTION01, the corrected C1->C2 gate is:
#
#   IDENTIFIER_SEAM_ISOLATABLE         = YES
#   IDENTIFIER_GRAMMAR_GATE            = PASS
#   LEGACY_ORACLE_CAPTURED             = YES (REFERENCE_MODEL)
#   POLYC_C_ABI_PROVEN                 = YES
#   B1_REQUIRES_B0_LLVM_PATH           = NO
#   B1_REQUIRES_GEP01_HARNESS          = NO
#
# See evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c1/
# corrected-grammar-gate.txt for the full four-clause
# expansion of IDENTIFIER_GRAMMAR_GATE.
