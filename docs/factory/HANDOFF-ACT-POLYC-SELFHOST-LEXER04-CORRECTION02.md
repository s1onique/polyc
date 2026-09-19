ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
========================================

VERDICT=PASS_TRUE_GREEN

IDENTITY
ENTRY_HEAD=ba45528691aa458b21137f7eae7723d81b9d9c92
FINAL_HEAD=d86ea84
WORKTREE_STATUS=CLEAN

RED
The principal RED is the TK_STR defect in production lexer.c:
  "#link <lib-complex_1.0>" yields link_libs="lib-complex_1co"
  (byte 13 changed from '.' to 'c').
Reproducible across all 4 generations.
C1 RED also identified two recipe regressions (R1, R2).

IMPLEMENTATION
Added 4 new PolyC tools (tools/quality/*.HC):
  - lexer07-sha256.HC (replaces sha256-tool.c)
  - lexer09-4stage-fixedpoint-verify.HC (replaces lexer09-fixedpoint-verify.c)
  - lexer09-4stage-semantic-runner.HC
  - lexer09-4stage-semantic-verify.HC

Makefile bounded changes (5 edits):
  - PolyC build for sha256 tool
  - PolyC build for fixedpoint verifier
  - R1 fix: BUILD_LABEL filter regex (correctness)
  - R2 fix: lexer07-scalar-literal-oracle.o separate recipe (correctness)
  - 4-stage semantic seam target (new)

GATES
BUILD=PASS (PolyC verifiers operational)
TARGETED=PASS (lexer09-link fixedpoint, 4-stage semantic seam)
DIFF_CHECK=PASS (git diff --check clean)

SCOPE
FILES_CHANGED=27 files (24 in C2, 33 evidence files in C3)
PRODUCTION_SEMANTICS_CHANGED=NO
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO

RESIDUE
P1=LEXER07 broad corpus: 6 pre-existing regressions (not in scope).
   Documented in: c3/c3-broad-corpus.txt
P2=L07 libname mangling in production lexer.c (pre-existing defect).
   Documented in: c3/c3-required-result.txt (residue section).

NEXT_ACT=ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 or
         ACT-POLYC-SELFHOST-LEXER05 (next self-host slice)

CLAIM EVIDENCE
- 32/32 PREV-ACY PASS (mandatory-ac-status.tsv)
- 4-stage semantic seam: 6/6 pairs byte-equal
- Component fixedpoint: 6/6 pairs byte-equal
- Component fixedpoint negative control: RC=1 (mutation detected)
- Direct differential: 23/23 PASS
- N01 semantic negative control: mutation detected
- N02 production causal negative control: semantic-independent confirmed
- SHA-256 NIST selftest: 5/5 PASS
- Factory gates: PASS (gate-fast, append-only 11/11, no-python)
- AC replay SHA matches C1 snapshot (0f99d852...)
- F14 conservation: zero deltas to closed LEXER01-03 evidence/HANDOFFs
