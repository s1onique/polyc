# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04

**Factory-Version:** 2

The parser surface has been re-inventoried from the live source after
five parser semantic authorities migrated into production-authoritative
PolyC, and exactly ONE next migration target has been computed,
mechanically verified and frozen.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. Actual entry identity

```text
ENTRY_HEAD=22107263561dfbc8f09df2b6dca066cf25d939c1
BRANCH=main
WORKTREE_CLEAN=YES
GIT_REPLACE_REFS=0
INTERVENING_COMMITS=0
```

The observed HEAD was EXACTLY the ACT's declared Expected ENTRY_HEAD,
so there was no intervening commit to inventory.  The entry tree IS the
predecessor's CLOSE tree.

```text
PREDECESSOR_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE05
PREDECESSOR_PHASE=CLOSE
PREDECESSOR_VERDICT=PASS
PREDECESSOR_CLOSE_REACHABLE=YES
```

## 2. The five verified self-hosted parser authorities

Re-verified against the LIVE production artifacts, not against source
comments and not merely against an exported symbol.  The strong form
of the evidence is that the live production objects carry the PolyC
symbols as UNDEFINED references and do NOT define them, so the legacy
C algorithm bodies are compiled out.

```text
AUTHORITY                              MACRO                                          OBJ_UNDEFINED_REF  OBJ_DEFINED_HERE
BootstrapCalcPadding                   HCC_USE_SELFHOST_PARSER_PADDING                YES                 NO
BootstrapValidPostControlFlowToken     HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN    YES                 NO
BootstrapOperatorPrecedence            HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE   YES                 NO
BootstrapAstBinOpFromToken             HCC_USE_SELFHOST_PARSER_AST_BINOP              YES                 NO
BootstrapAstUnaryOpFromToken           HCC_USE_SELFHOST_PARSER_AST_UNARY              YES                 NO

PARSER_POLYC_AUTHORITIES_EXPECTED=5
PARSER_POLYC_AUTHORITIES_VERIFIED=5
AST_BINARY_AUTHORITY=POLYC
AST_UNARY_AUTHORITY=POLYC
AST_OPERATOR_CLASSIFICATION=COMPLETE
```

## 3. The current authority inventory

The census is DERIVED from the live source BYTES by the ACT's own
PolyC tool, not transcribed.

```text
src/parser.c    58
src/prslib.c    41
src/prsutil.c   27
src/ast.c      142
TOTAL          268
```

```text
LIVE_FUNCTIONS=268
CLASSIFIED_SYMBOLS=268
UNCLASSIFIED_LIVE_SURFACES=0
DUPLICATE_SURFACE_IDS=0
CONFLICTING_AUTHORITY_CLASSES=0
UNKNOWN_AUTHORITY_ROWS=0
SOURCE_HASH_MISMATCHES=0
SOURCE_RANGE_ERRORS=0
```

## 4. Changes relative to RECON03

Every delta is explained by an exact measured SET DIFFERENCE, not by
arithmetic.

```text
file           RECON03  RECON04  added  removed  explanation
src/parser.c       58       58      0        0  unchanged
src/prslib.c       40       41      1        0  ParserLegacyOperatorPrecedenceOracle, added by SLICE03 as the stage0 oracle
src/prsutil.c      11       27     16        0  RECON03 enumerated only 11 of the 27 live functions of that file
src/ast.c          12      142    130        0  RECON03 enumerated only the 12 PARSER-FACING PRIMITIVES of src/ast.c
TOTAL             121      268    147        0
```

```text
OLD_SURFACES=268
NEW_SURFACES=268
REMOVED_SURFACES=0
RENAMED_SURFACES=0
MIGRATED_SURFACES=0
SPLIT_SURFACES=0
MERGED_SURFACES=0
```

`MIGRATED_SURFACES=0` at the FUNCTION level is correct and is NOT a
claim that no authority migrated.  Five AUTHORITIES migrated, but in
each case the legacy C function SURVIVES as a thin forwarding adapter,
so the function SET is unchanged.

## 5. Historical candidate reconciliation

```text
historical ID   function                   current authority        current eligibility
CAND-017        parseGetPriority           SELFHOSTED_TRUE_GREEN    NOT_ELIGIBLE (migrated by SLICE03)
CAND-018        parseCompoundAssign        LEGACY_C_AUTHORITY       ELIGIBLE
CAND-019        astBinOpFromToken          SELFHOSTED_TRUE_GREEN    NOT_ELIGIBLE (migrated by SLICE04)
CAND-020        astUnaryOpFromToken        SELFHOSTED_TRUE_GREEN    NOT_ELIGIBLE (migrated by SLICE05)
CAND-021        astBinOpToTokenPunct       LEGACY_C_AUTHORITY       ELIGIBLE
CAND-022        parseCountPrintfFormatSpecs LEGACY_C_AUTHORITY     ELIGIBLE
CAND-023        parseFormatArgIdx          LEGACY_C_AUTHORITY       ELIGIBLE
CAND-025        astIsAssignment            LEGACY_C_AUTHORITY       ELIGIBLE
CAND-026        astIsValidPointerOp        LEGACY_C_AUTHORITY       ELIGIBLE
CAND-030        parseIsClassOrUnion        LEGACY_C_AUTHORITY       ELIGIBLE

HISTORICAL_ELIGIBLE_REMAINING=7
HISTORICAL_ELIGIBLE_MIGRATED=3
HISTORICAL_CANDIDATES_RECONCILED=YES
```

For each of the seven remaining candidates the source still exists,
the body semantics are unchanged, the production reachability is
unchanged and the dependency set is unchanged.  Their historical
RANKINGS are not frozen recommendations: they were re-ranked on the
current vector.

New IDs were allocated from the next unallocated canonical range after
reconciling the live registry (`CAND-036`..`CAND-040` for the scalar
follow-ups, `SUB-001`..`SUB-012` for the structural sub-slices, which
are a separate namespace because a sub-slice is not a whole function).

## 6. Structural dependency-graph results

The PARSER01 findings were RE-MEASURED, not copied.

```text
HISTORICAL_SUBORDINATE_CALLS=24
CURRENT_SUBORDINATE_CALLS=25
HISTORICAL_DEFERRED_SURFACES=9
CURRENT_DEFERRED_SURFACES=9
HISTORICAL_WHOLE_FUNCTION_BOUNDED=NO
CURRENT_WHOLE_FUNCTION_BOUNDED=NO
IN_CURRENT_NOT_IN_HISTORICAL=0
IN_HISTORICAL_NOT_IN_CURRENT=0
```

The subordinate callee SET is identical to the historical one: the
same 25 names, zero added, zero removed.  The historical header said
24 while its own table listed 25 (`tokenPunctIs` was in the table but
not in the count).

The whole-function verdict is UNCHANGED: the live body still owns the
setjmp recovery point, the block scope, the AST-list tail rollback and
the tmp_locals rollback.

```text
RECOVERY_OWNER=C
AST_GRAPH_OWNER=C
SYMBOL_TABLE_OWNER=C
TOKEN_STREAM_OWNER=C
DIAGNOSTIC_OWNER=C
UNCLASSIFIED_DEPENDENCIES=0
NON_C_RECOVERY_OWNERS=0
CROSSING_CALLBACK_EDGES=0
NON_C_ALLOCATION_OWNERS=0
NON_C_GRAPH_OWNERS=0
```

## 7. The new structural sub-slices

Twelve sub-slices were extracted over the six required regions.  Four
are bounded `STRUCTURAL_BOUNDARY` candidates; eight are
`INELIGIBLE_STRUCTURAL` with a NAMED reason.

```text
SUB-001  parseCaseLabel             the switch-arm termination decision        STRUCTURAL_BOUNDARY
SUB-002  parseDefaultStatement      the default-arm termination decision     STRUCTURAL_BOUNDARY
SUB-003  parseCompoundStatementInternal  the compound-block statement routing  STRUCTURAL_BOUNDARY
SUB-004  parseStatement             the statement keyword dispatch           STRUCTURAL_BOUNDARY
SUB-005  parseDeclOrStatement       the declaration-versus-statement routing INELIGIBLE_STRUCTURAL
SUB-006  parseCompoundStatementInternal  the recovery checkpoint            INELIGIBLE_STRUCTURAL
SUB-007  parseCompoundStatementInternal  the whole body loop               INELIGIBLE_STRUCTURAL
SUB-008  parseStatement             the whole statement parser               INELIGIBLE_STRUCTURAL
SUB-009  parseExpr                  the whole expression loop                INELIGIBLE_STRUCTURAL
SUB-010  astStmtFallsThrough        the recursive fall-through walk          INELIGIBLE_STRUCTURAL
SUB-011  astStmtHasBreak            the recursive break walk                 INELIGIBLE_STRUCTURAL
SUB-012  astIsConstTrueCond         the constant-true condition read         INELIGIBLE_STRUCTURAL
```

SUB-005 deserves a note: it LOOKED bounded, and it was REJECTED after
reading the live source.  `cctrlIsKeyword` consults the MUTABLE host
symbol table, the class-def map and the union-def map, so the decision
depends on host symbol-table state and its projection is not bounded.
It is recorded with that reason rather than quietly dropped.

## 8. The complete eligibility results

```text
COMMAND=build/parser-slice-recon03-eligibility evidence/.../c1/eligibility-input-facts.tsv
TOTAL=16
ELIGIBLE=16
MALFORMED=0
STATUS=PASS
```

The fact table has 20 fields and NO `eligible` column, so the flag
cannot be hand-authored.  The `eligible` column the ranker consumed is
the CHECKER'S OUTPUT: the join between the two tables reports ZERO
mismatches.

```text
ELIGIBLE_CANDIDATES=16
ELIGIBLE_STRUCTURAL_CANDIDATES=4
ELIGIBLE_SCALAR_CANDIDATES=12
EXCLUDED_CANDIDATES=36
ALL_CANDIDATES_EVALUATED=YES
```

Fourteen eligibility controls were executed against the REAL checker.
Each drives its TARGETED clause bit to ZERO, not merely the verdict,
so a control that passed for the wrong reason would be visible.

```text
ELIGIBILITY_CONTROL_FAILURES=0
```

## 9. The full rank order and the controls

```text
RANK  candidate  R0 R1 R2 R3 R4 R5  R6                       class
1     SUB-001    0  1  1  2  1  1  src/parser.c:1551      CLASS_1
2     SUB-002    0  1  1  2  1  1  src/parser.c:1582      CLASS_1
3     SUB-003    0  1  1  2  1  1  src/parser.c:1948      CLASS_1
4     SUB-004    0  2  1  2  2  2  src/parser.c:1672      CLASS_1
5     CAND-022   0  2  2  2  0  0  src/prslib.c:760       CLASS_2
6     CAND-018   0  2  2  2  0  0  src/prslib.c:1328      CLASS_2
7     CAND-021   0  2  2  2  0  0  src/prslib.c:1352      CLASS_2
8     CAND-023   0  2  2  2  1  1  src/prslib.c:798       CLASS_2
9     CAND-025   0  2  3  2  0  0  src/ast.c:943         CLASS_2
10    CAND-026   0  2  3  2  0  0  src/ast.c:974         CLASS_2
11    CAND-036   0  2  3  2  0  0  src/ast.c:992         CLASS_2
12    CAND-037   0  2  3  2  0  0  src/ast.c:2348        CLASS_2
13    CAND-030   0  2  3  2  0  0  src/prsutil.c:22       CLASS_2
14    CAND-038   2  2  3  2  1  1  src/ast.c:931         CLASS_2
15    CAND-039   2  3  3  2  2  1  src/parser.c:1655      CLASS_2
16    CAND-040   2  3  3  2  2  1  src/parser.c:2063      CLASS_2
```

Nine ranking controls were executed against the REAL ranker: row
permutation, winner removal, R0 perturbation, an ineligible candidate
with ideal scores, the source-order tie break, structural-class
removal, a false structural classification, a stale candidate id, and
a historical ranking replay.

```text
RANKING_CONTROL_FAILURES=0
ANTI_BIAS_CONTROLS=PASS
```

The historical replay reproduces the RECON03 ordering EXACTLY
(`CAND-017 CAND-022 CAND-018 CAND-021 CAND-023 CAND-019 CAND-020
CAND-025 CAND-026 CAND-030`), which proves the ranker's semantics are
unchanged by this ACT.

## 10. The one computed winner

```text
SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE=SUB-001
SELECTED_CANDIDATE_CLASS=STRUCTURAL_BOUNDARY
SELECTED_RANK=1
SELECTED_RANK_WITHIN_CLASS=1
SELECTED_ELIGIBLE=YES
```

The winner is RECOMPUTED independently at C3 from the C1 facts: the
eligibility is recomputed by an independent implementation of the 13
clauses that does NOT read the C2 eligible column, and the whole
ranked order comes out identical.

```text
C3_VS_C2_VERDICT_MISMATCHES=0
C3_VS_C2_CLAUSEBIT_MISMATCHES=0
RANKING_ORDER_IDENTICAL=YES
WINNER_IDENTICAL=YES
POLICY_MATCHES_C2=YES
```

## 11. The selected ABI and state projection

```text
SELECTED_FUNCTION=parseCaseLabel (the switch-arm termination decision)
SELECTED_ENCLOSING_FUNCTION=parseCaseLabel
SELECTED_SOURCE_FILE=src/parser.c
SELECTED_SOURCE_RANGE=1551..1553
SELECTED_SOURCE_SHA256=31dc9ae8f87d26be429a565356820d8913c9a7cbc0e37d64470049c3b5948707
SELECTED_BOUNDARY_CLASS=SCALAR_TO_SCALAR
SELECTED_POLYC_SYMBOL=BootstrapSwitchArmTerminates
SELECTED_ABI=I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64
SELECTED_INPUT_FIELDS=one I64 carrying an AstKind enum value
SELECTED_OUTPUT_FIELDS=one I64: 1 = terminate the arm, 0 = continue the arm
SELECTED_FAILURE_SEMANTICS=NO_FAILURE_PATH
SELECTED_PRODUCTION_CALL_SITES=src/parser.c:1551
SELECTED_LEGACY_DECISION_OWNER=src/parser.c (C)
SELECTED_RANK_VECTOR=0,1,1,2,1,1
```

The projection reads EXACTLY ONE host field:

```text
stmt->kind   Ast   READ   ->  I64   YES   C
```

and nothing else crosses: no pointer, no `void *`, no callback table,
no `jmp_buf`, no host-graph write, no allocation, no recovery, no
diagnostic.

## 12. The oracle, RED, fixture, mutation and provenance contracts

```text
ORACLE_STRATEGY=extract a contiguous legacy decision with source-bound mechanical verification
ORACLE_SOURCE=c2/probes/legacy-sub001-oracle.c  (committed)
ORACLE_ROWS=51
ORACLE_TERMINATING_SET=258,270,274,280,287,293
REAL_C_ORACLE_IDENTIFIED=YES
ORACLE_REPRODUCIBLE=YES
```

The oracle is the three live source lines with the single substitution
`stmt->kind` -> `kind`, and it names the live `AstKind` members
through the live `src/ast.h`, so it cannot drift from the live enum.
The successor is REQUIRED to strengthen it to the object-level form
(compiling `src/parser.c` with the delegation off).

```text
RED-1  the PolyC component is absent            RED_1_REPRODUCED=YES
RED-2  the production delegation is absent      RED_2_REPRODUCED=YES
RED-3  the legacy C decision still owns it      RED_3_REPRODUCED=YES
RED-4  the ABI/bridge is not available         RED_4_REPRODUCED=YES
RED-5  mutation-sensitive behaviour is
       established on the legacy oracle         RED_5_REPRODUCED=YES

SOURCE_DECISION_EXISTS=YES
EXTRACTED_COMPONENT_EXISTS=NO
```

```text
FIXTURE_PARTITIONS=12
EXPECTED_FIXTURE_ROWS_AT_RECON04=51
FIXTURE_ROW_COUNT_MUST_BE_DERIVED=YES
```

The row count is DERIVED from the live enum (41 values) plus the ten
probe rows; it is not chosen.  The successor must derive its own count
and must not hard-code 51.

Seventeen negative controls are frozen, each with its intended failure
reason: eight fixture-integrity controls, four production-differential
controls, three production-semantic controls and three
structural-boundary controls.

## 13. The causal mutation model -- EXECUTED, not planned

A real git worktree of THIS repository was built at the ACT's own
commit, the production source was mutated there (one disjunct removed
from the terminating set), the compiler was REBUILT SUCCESSFULLY, and
the SAME witness was compiled and run against all three compilers.

```text
PRISTINE_BUILD=PASS
  SUB001:ARM2_MARKER
  SUB001:x=1

MUTANT_BUILD=PASS
  SUB001:ARM1_MARKER
  SUB001:ARM2_MARKER
  SUB001:x=1

RESTORED_BUILD=PASS
  SUB001:ARM2_MARKER
  SUB001:x=1

MUTATED_OUTPUT_DIFFERS=YES
RESTORED_OUTPUT_EQUALS_PRISTINE=YES
CAUSAL_CLASS=EXECUTED_CAUSAL_CONTROL
```

The observable is COMPILED PROGRAM OUTPUT.  The mutant is a WORKING
compiler, not a crash and not a link failure.  The tracked source in
the main repository was never modified.

## 14. The four-generation proof model the successor must produce

```text
G0  the legacy C decision, compiled from src/parser.c WITHOUT the
    delegation macro
G1  the PolyC component compiled by the stage0 compiler
G2  the PolyC component compiled by G1
G3  the PolyC component compiled by G2
```

All four must be independently compiled with real provenance, and
their outputs must be semantically comparable over the fixture
matrix.

## 15. Conservation and Factory gate results

```text
PARSER_HOST_ARCH_ASSERTIONS=376/376
PARSER_HOST_ARCH_TESTFILES=90
PARSER_HOST_ARCH_FAILURE_IDENTITIES=0
PARSER_HOST_ARCH_ASSERTION_SEQUENCE_MD5=b6f117eb1386ca80f81bc06226e2a741
PARSER_CROSS_TARGET_STATUS=FAIL_ENVIRONMENT_PREFIX
PARSER_CROSS_TARGET_FAILURE_IDENTITIES=0
NEW_PARSER_FAILURE_IDENTITIES=0

LEXER_DIRECT_DIFFERENTIAL_RESULTS=PASS
LEXER07_DIRECT_DIFF_PASS=89
LEXER08_DIRECT_DIFF_PASS=45
LEXER09_DIRECT_DIFF_PASS=23
NEW_LEXER_FAILURE_IDENTITIES=0

LEXER07_BROAD_CORPUS_STATUS=FAIL
LEXER07_BROAD_CORPUS_REGRESSION=0
LEXER07_BROAD_CORPUS_DIVERGED=0
LEXER07_BROAD_CORPUS_FAILURE_IDENTITY_SET_IDENTICAL=YES
NEW_LEXER07_FAILURE_IDENTITIES=0

GATE_FAST_RESULT=PASS
GATE_PUSH_RESULT=PASS
FACTORY_V2=PASS
APPEND_ONLY=PASS
CLOSURE_STATUS=PASS
F14=PASS
PATCH_HYGIENE=PASS
```

The cross-target run reproduces the HISTORICAL installation-prefix
condition (67 failures, all "Failed to open file:
../../build/aarch64-apple-darwin/include/tos.HH").  It is recorded
HONESTLY rather than relabelled PASS, and it is not a new failure
identity.

```text
F_NO_PYTHON=FAIL_PRE_EXISTING_BASELINE
F_NO_PYTHON_NEW_VIOLATIONS=0
F_POLYC_TOOLS=UNAVAILABLE_CHECKER_NOT_LANDED
```

The F-NO-PYTHON checker reports FAIL, but only the twelve violations
that were already failing at the entry tree; 0 of the failing paths
were touched by this ACT.  The F-POLYC-TOOLS checker is NOT LANDED (the
C2.9 residue AGENTS.md records), so it is reported as UNAVAILABLE
rather than silently treated as a pass.

## 16. The acceptance ledger

```text
AC_TOTAL=50
AC_UNIQUE=50
AC_MISSING=0
AC_DUPLICATE=0
AC_PASS=49
AC_DEFERRED_TO_CLOSE=1
AC_FAIL=0
AC_UNPROVEN=0
```

The ledger is joined BY AC ID to the frozen C2 contract
(`LEDGER_ROWS_MISSING_FROM_CONTRACT=0`,
`LEDGER_ROWS_NOT_IN_CONTRACT=0`).  AC50 is deferred because it needs
the C4 commit to exist; the post-CLOSE external terminality checks
satisfy it.

## 17. Honest residue and blocked boundaries

| Pri | Residue |
|---|---|
| P1 | The F-NO-PYTHON checker still reports 12 tracked Python sources and the shell-LOC ratchet 5 over-budget scripts.  Pre-existing baseline violations in files this ACT did not touch; 0 new.  Recorded, not waived, not fixed. |
| P1 | The four control drivers under the ACT's evidence tree are 67..156 LOC of shell, over the 50-LOC budget F-POLYC-TOOLS applies to shell under the tool roots.  They are OUTSIDE that checker's declared scope, so they do not violate the rule as written, but they do not honour its spirit.  The correct fix is to fold the control logic into PolyC, which is a bounded follow-up: this ACT authorizes at most ONE new substantive PolyC tool and it has already been used. |
| P2 | `tools/factory/factory-polyc-tools-check.HC` (the authoritative F-POLYC-TOOLS checker) is NOT YET LANDED.  The C2.9 residue recorded by AGENTS.md. |
| P2 | The PARSER01 whole-function blockers REMAIN: `parseCompoundStatementInternal`, `parseStatement` and `parseExpr` as whole functions, the recursive flow-analysis walks, and SUB-005 (the declaration-versus-statement routing, whose projection is unbounded because `cctrlIsKeyword` consults the mutable host symbol table). |
| P2 | The eleven other eligible candidates remain unmigrated: the three remaining structural sub-slices (`SUB-002`, `SUB-003`, `SUB-004`) and the twelve scalar follow-ups.  Each is a viable later target with its own fixture, oracle and conservation baseline. |

## 18. The single-valued successor authorization

```text
NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE06
NEXT_TARGET=SUB-001
NEXT_TARGET_CLASS=STRUCTURAL_BOUNDARY
NEXT_ABI=I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64
NEXT_SCOPE_FROZEN=YES
```

The successor inherits, unchanged, from the RECON04 C2 freeze:
`SELECTED_CANDIDATE_ID`, `SELECTED_SOURCE_IDENTITY`, `SELECTED_ABI`,
`SELECTED_LEGACY_ORACLE`, `SELECTED_FIXTURE_CONTRACT`,
`SELECTED_RED_CONTRACT`, `SELECTED_CAUSAL_CONTRACT`,
`SELECTED_NEGATIVE_CONTROLS`, `SELECTED_PRODUCTION_SEAM`,
`SELECTED_CONSERVATION_BASELINE`, `SELECTED_OUT_OF_SCOPE`.

There is exactly ONE authorized next target.  `SUB-002`, `SUB-003`,
`SUB-004` and the twelve scalar candidates are NOT authorized here.

SLICE06 must implement exactly `SUB-001`.  It must not reopen the
ranking to choose an easier target.  It must retain C ownership of
recovery, allocation, diagnostics and the mutable AST graphs, exactly
as RECON04 defined them.

## Terminal facts

```text
ACT                           = ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
TARGET                        = SUB-001
TARGET_CLASS                  = STRUCTURAL_BOUNDARY
POLYC_SYMBOL                  = BootstrapSwitchArmTerminates
POLYC_ABI                     = I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64
SELECTED_SOURCE_RANGE         = src/parser.c:1551..1553
SELECTED_SOURCE_SHA256        = 31dc9ae8f87d26be429a565356820d8913c9a7cbc0e37d64470049c3b5948707
PARSER_POLYC_AUTHORITIES      = 5
LIVE_FUNCTIONS                = 268
ELIGIBLE_CANDIDATES           = 16
ELIGIBLE_STRUCTURAL_CANDIDATES = 4
ELIGIBLE_SCALAR_CANDIDATES    = 12
SELECTED_CANDIDATE_COUNT      = 1
CAUSAL_CLASS                  = EXECUTED_CAUSAL_CONTROL
```

## The acceptance ledger

```text
AC_TOTAL=50
AC_ID_UNIQUE=YES
AC_MISSING=0
AC_DUPLICATE=0
AC_PASS=49
AC_DEFERRED_TO_CLOSE=1
AC_FAIL=0
AC_UNPROVEN=0
```

VERDICT

PASS

The parser surface has been re-inventoried from the live source
(268 functions, every one classified, zero unclassified), the
historical reconnaissance has been reconciled by exact set difference,
the PARSER01 dependency blockers have been re-measured, four bounded
structural sub-slices have been discovered and classified, the
canonical 13-clause eligibility and the canonical R0..R6 ranking have
been executed unmodified with sensitive anti-bias controls, and
exactly ONE eligible structural boundary has been selected and frozen
with a bounded ABI, a real legacy oracle, reproducible REDs, a
fixture contract, seventeen negative controls and an EXECUTED causal
mutation experiment.

The production semantic delta is zero, no production code was touched,
the five previously migrated PolyC parser authorities are still live,
and the conservation suites are unchanged.
