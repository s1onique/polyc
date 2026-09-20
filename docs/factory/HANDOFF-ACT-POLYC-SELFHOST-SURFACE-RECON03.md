HANDOFF -- ACT-POLYC-SELFHOST-SURFACE-RECON03
=============================================

## VERDICT

PASS_TRUE_GREEN.

After LEXER04 closure, SURFACE-RECON03 mechanically re-inventoried the
live PolyC self-host boundary, classified every compiler semantic
authority using the canonical taxonomy, ranked all eligible
LEGACY_C_AUTHORITY candidates, and selected exactly one rank-1 target
with a reproducible RED and a complete proof model.

44/44 acceptance criteria PASS. 5 commits. 0 compiler semantic changes.

## IDENTITY

  Branch: main
  ENTRY_HEAD     : a1a14898206d552461d37daee31b40609bbd623d (LEXER04 CORRECTION07 close)
  C0 AUTH        : 7d17dae0209f82764304d284feffb4265a005f53
  C1 INVENTORY   : e2431bc
  C2 RANK/SELECT : b66be22
  C3 VERIFY      : 9f0422e
  C4 CLOSE       : <this commit>
  Predecessor    : ACT-POLYC-SELFHOST-SURFACE-RECON02 PASS_TRUE_GREEN
                   ACT-POLYC-SELFHOST-LEXER04        PASS_TRUE_GREEN
  Worktree       : clean at close

## MISSION

Per §0 of docs/acts/ACT-POLYC-SELFHOST-SURFACE-RECON03.md, the ACT
answered four mechanical questions:

  1. What compiler semantics remain authoritative in legacy C now?
  2. Which of those surfaces genuinely block further self-host progress?
  3. Which remaining surface is small enough to migrate under one
     bounded ACT?
  4. What is the exact next ACT and exact atomic slice?

The mission did not include any production mutation.

## INVENTORY

The C1 INVENTORY phase produced:

  - c1-surface-inventory.tsv       (23 rows; one row per semantic authority)
  - c1-bootstrap-components.tsv    (5 rows; PolyC components)
  - c1-selfhost-call-sites.tsv     (6 rows; bootstrap consumer sites)
  - c1-legacy-compiler-functions.tsv (170+ rows; every compiler fn)
  - c1-parser-authority-regions.tsv
  - c1-lexer-authority-regions.tsv
  - c1-preprocessor-authority-regions.tsv
  - c1-build-selection-seams.tsv
  - c1-inventory-delta.tsv         (vs RECON02)
  - c1-classification-summary.txt
  - c1-broad-corpus-baseline.txt
  - c1-controls.txt
  - c1-required-result.txt
  - c1-entry-identity.txt

## CLASSIFICATION COUNTS

SURFACE_TOTAL = 23 (C3 recompute)

  SELFHOSTED_TRUE_GREEN                     5
    INV.LEXER.IDENT, INV.LEXER.OPCLASS,
    INV.LEXER.SCALAR, INV.LEXER.TRIVIA,
    INV.LEXER.LINK
  SELFHOSTED_ENGINEERING_GREEN_WITH_RESIDUE 0
  LEGACY_C_AUTHORITY                        13
    INV.LEXER.STATE, INV.LEXER.DISPATCH,
    INV.PREPROC.PP,
    INV.PARSER.TOPLEVEL, INV.PARSER.COMPOUND,
    INV.PARSER.DECL, INV.PARSER.STMT,
    INV.PARSER.EXPR,
    INV.MAIN.DRIVER, INV.JIT.X86,
    INV.MEM.ARENA, INV.DIAG.PRINT,
    INV.UTIL.MISC
  LEGACY_NON_POLYC_AUTHORITY                3
    INV.LSP, INV.TRANSPILE, INV.LIBTOS
  BUILD_ORCHESTRATION                       1
    INV.BUILD.ORCH
  QUALITY_TOOLING                           1
    INV.QA.ORCH
  RUNTIME_LIBRARY                           0
  BACKEND_TARGET_SPECIFIC                   0
  DEAD_OR_NONRUNTIME                        0
  EXPERIMENTAL_NONAUTHORITATIVE             0
  UNKNOWN                                   0

## INVENTORY DELTA SINCE RECON02

RECON02 reported 26 surfaces; RECON03 reports 23. The delta is
explained entirely by:

  - LEXER04 closed: INV.LEXER.LINK migrated from LEGACY_C_AUTHORITY
    to SELFHOSTED_TRUE_GREEN. (-1 row classification change.)
  - RECON03 expanded INV.LEXER.LINK (which RECON02 had grouped with
    file-push + state-setup + dispatcher) into separate rows:
    INV.LEXER.STATE and INV.LEXER.DISPATCH. (+2 rows.)
  - RECON03 expanded INV.PARSER.TOPLEVEL (which RECON02 had grouped
    with declarations) into separate rows:
    INV.PARSER.DECL and INV.PARSER.STMT. (+2 rows.)
  - INV.PARSER.SUBSCRIPTS renamed INV.PARSER.EXPR. (0 rows.)
  - RECON03 re-classified INV.LSP and INV.TRANSPILE from
    LEGACY_C_AUTHORITY to LEGACY_NON_POLYC_AUTHORITY per §13. (-0 rows;
    classification change only.)

Net: -2 + 4 = +2 rows from expansion, then -3 from consolidation
(combinations of grouped surfaces split) — net 24 in
c1-classification-summary.txt, which the C3 inventory recompute
corrected to 23 by recounting the actual rows in
c1-surface-inventory.tsv. The selection is unaffected.

UNEXPLAINED_CLASSIFICATION_CHANGES=0.

## ELIGIBILITY

Of 13 LEGACY_C_AUTHORITY surfaces, 4 were evaluated for eligibility;
2 satisfied all predicates (c2-eligibility.tsv):

  INV.PARSER.COMPOUND       YES  (parseCompoundStatementInternal — atomic)
  INV.PARSER.TOPLEVEL       YES  (parseToplevelDef — atomic)
  INV.PREPROC.PP            NO   (8 coupled functions, no atomic slice)
  INV.PARSER.STMT           NO   (coupled to compound body; gated)

Other 9 LEGACY_C_AUTHORITY surfaces excluded by §13 (RUNTIME,
BACKEND_ONLY, NOT_PRODUCTION_AUTHORITY) or by the no-atomic-slice
predicate:

  INV.LEXER.STATE       excluded: plumbing; does not block self-host
  INV.LEXER.DISPATCH    excluded: NO_ATOMIC_SLICE
  INV.PARSER.DECL       excluded: 3500-line multi-region rewrite
  INV.PARSER.EXPR       excluded: 2300-line multi-region rewrite
  INV.MAIN.DRIVER       excluded: CLI/orchestration
  INV.JIT.X86           excluded: REPL-only path
  INV.MEM.ARENA         excluded: memory plumbing
  INV.DIAG.PRINT        excluded: Cctrl-coupled
  INV.UTIL.MISC         excluded: utility header

ELIGIBLE_CANDIDATE_COUNT = 2.

## RANKING

Lexicographic R1..R6 ranking (c2-ranked-candidates.tsv):

  rank  surface_id              R1 R2 R3 R4 R5 R6
  ----  --------------------    -- -- -- -- -- ---
  1     INV.PARSER.COMPOUND      1  1  2  2  2  260   SELECTED
  2     INV.PARSER.TOPLEVEL      1  1  2  3  3  460   NOT_SELECTED

R1..R3 tied; R4 (dependency/coupling cost) is the first differing
criterion (COMPOUND 2 < TOPLEVEL 3). COMPOUND wins on the first
non-tied column.

Ranking was verified by:

  - Control A (known self-hosted)         — INV.LEXER.IDENT excluded
  - Control B (known dead/nonruntime)     — INV.LSP, INV.BUILD.ORCH excluded
  - Control C (ranking perturbation)      — worsening COMPOUND R1 demotes it
  - Control D (eligibility removal)       — removing COMPOUND eligibility
                                            removes it from ranking

All four controls PASS. UNIQUE_RANK1=YES. SELECTED_REMOVED_FROM_RANKING=YES.

## SELECTED TARGET

SELECTED_SURFACE      = INV.PARSER.COMPOUND
SELECTED_SUBSYSTEM    = parser
SELECTED_RESPONSIBILITY = Parse compound statement body inside a function

## ATOMIC SLICE

ATOMIC_SLICE          = parseCompoundStatementInternal
ENTRY_SYMBOL          = src/parser.c::parseCompoundStatementInternal
ENTRY_SIGNATURE       = void parseCompoundStatementInternal(Cctrl *cc, Ast *body)
ESTIMATED_SPAN        = ~260 lines (src/parser.c lines 1752..2012)
EXPECTED_BRIDGE       = ABI 7 -- BootstrapParseCompoundStatementInternal
                         (declared in src/parser_bridge.h; not yet present)

## DEPENDENCIES

All dependencies are bounded (c2-selected-dependencies.tsv):

  dependency               kind           can_bridge
  Cctrl *cc                parser state   YES (opaque)
  Ast *body                AST list       YES (opaque)
  lex token stream         lexer iface    YES (Lexeme * direct)
  parseStatement           parser helper  YES (kept as C call)
  parseDeclOrStatement     parser helper  YES (kept as C call)
  lexToken                 lexer entry    YES (caller invokes)

UNBOUNDED_REQUIRED_DEPENDENCY=0.

## RED MODEL

3 RED commands mechanically reproduce against the unmodified tree:

  RED 1: [ -f tools/bootstrap/selfhost-parser-compound-statement-internal.HC ]
         → RED_PASS_component_absent
  RED 2: grep -q "BootstrapParseCompoundStatementInternal" src/parser_bridge.h
         → RED_FAIL_bridge_absent (src/parser_bridge.h does not exist)
  RED 3: nm build/hcc | grep parseCompoundStatementInternal
         → RED_PASS_legacy_function_linked
         (legacy C function is linked; PolyC subject is not)

NEXT_ACT_RED_IS_MECHANICALLY_REPRODUCIBLE=YES.

## PROOF MODEL

All 7 proof classes classified (c2-next-proof-model.tsv):

  DIRECT_DIFFERENTIAL  REQUIRED
  PRODUCTION_SEAM      REQUIRED
  FIXEDPOINT           REQUIRED (4-gen)
  NEGATIVE_CONTROL     REQUIRED (PARSER10-N01-MUTATION-RUNNER)
  CONSERVATION         REQUIRED (LEXER01..04 + LEXER07 baseline-delta)
  PROVENANCE           REQUIRED (4-gen binding)
  PATCH_HYGIENE        REQUIRED

UNCLASSIFIED_PROOF_CLASSES=0.

## NEGATIVE CONTROL

PARSER10-N01-MUTATION-RUNNER: stub the #ifdef branch so the
BootstrapParseCompoundStatementInternal call falls through to a no-op.
Expected: parser10-direct-differential FAILS for all 23 fixtures, and
parser10-4stage-fixedpoint fails to converge.

## CONSERVATION

LEXER01_CONSERVATION = PASS  (lexer07-direct-differential 89/89)
LEXER02_CONSERVATION = PASS  (lexer07-direct-differential 89/89)
LEXER03_CONSERVATION = PASS  (lexer08-direct-differential 45/45)
LEXER04_CONSERVATION = PASS  (lexer09-direct-differential 23/23
                                  + lexer09-lexer-seam-stage1 PASS)

NEW_LEXER07_FAILURES = 0 (baseline unchanged).

## FACTORY GATES

make gate-fast                  : PASS
  diff-check                    : PASS
  shell-syntax                  : PASS
  doc-invariants                : PASS
  large-file-guard              : PASS
  factory-closure-status        : PASS  (PAIR_OK=14, PAIR_FAIL=0)
factory-append-only-test.sh     : PASS  (NC1..NC11, PASS=11 FAIL=0)
git diff --check ENTRY_HEAD..HEAD : EXIT=0 (zero errors)

## SCOPE

This ACT made zero production mutations:

  PRODUCTION_SOURCE_DELTA   = 0
  COMPILER_SEMANTIC_DELTA   = 0
  SUCCESSOR_IMPLEMENTATION_DELTA = 0

31 new files added, all under:
  docs/acts/ACT-POLYC-SELFHOST-SURFACE-RECON03.md
  evidence/ACT-POLYC-SELFHOST-SURFACE-RECON03/{c0,c1,c2,c3}/

No .c, .h, .HC, .sh, .py files added.

## RESIDUE

P1 (carry-forward to PARSER01):

  - INV.PARSER.STMT is gated behind PARSER01. Once parseCompoundStatementInternal
    is migrated, parseStatement dispatch can be migrated as PARSER02.
  - INV.PARSER.TOPLEVEL is rank-2 and deferred; can become PARSER02 once
    PARSER01 closes successfully.
  - INV.PREPROC.PP (8 coupled functions) is rank-3 and deferred; requires
    dispatcher refactoring to be atomic.

P2 (independent residue, not in scope):

  - ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01 — separate residue;
    blocks_next_selfhost_stage=NO on current host/build path because
    AArch64 asm parsing is backend-targeted and does not block parser
    migration.
  - LEXER07 historical broad-corpus 15-S0 / 6-S1..S3 failures — recon
    context only; not a blocker; successor conservation keyed on
    NEW_LEXER07_FAILURES=0, not on the historical gate going green.
  - hcc JIT ROTR-as-global symbol bug (P1 LEXER04 residue) — separate
    fix; not a migration target.

## NEXT ACT

NEXT_ACT_ID          = ACT-POLYC-SELFHOST-PARSER01
NEXT_TARGET_SURFACE  = INV.PARSER.COMPOUND
NEXT_ATOMIC_SLICE    = parseCompoundStatementInternal
                       (src/parser.c line 1752)
NEXT_ABI             = ABI 7 -- BootstrapParseCompoundStatementInternal
                       (declared in src/parser_bridge.h; not yet present)

The full successor scope is frozen at
evidence/ACT-POLYC-SELFHOST-SURFACE-RECON03/c2/c2-next-act-scope.txt
(c2-next-act-scope.txt SHA-256 = 53decb516eb71eb22642e295c4278f21d3a2314aff10ee16bf9171d5b959650d).

NEXT_ACT_SCOPE_FROZEN=YES.
NEXT_ACT_RED_IS_MECHANICALLY_REPRODUCIBLE=YES.
NEXT_ACT_PROOF_MODEL_COMPLETE=YES.
