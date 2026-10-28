# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05

**Factory-Version:** 2

The parser surface has been re-inventoried from the live source after
six parser semantic authorities migrated into production-authoritative
PolyC, and exactly ONE next migration target has been computed,
mechanically verified, proven causally feasible and frozen.

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. Actual entry identity

```text
ENTRY_HEAD=005790c53bb4e4798d58809940548552f0993d47
ENTRY_TREE=5734052f648d486ca9cc822601079fbafdbdd5e1
BRANCH=main
HEAD_MATCHES_EXPECTED=YES
TREE_MATCHES_EXPECTED=YES
TRACKED_STATE_CLEAN=YES
GIT_REPLACE_REFS=0
INTERVENING_COMMITS=0
```

The entry state was EXACTLY the ACT's declared ENTRY_HEAD and
ENTRY_TREE.  The predecessor
`ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01` is CLOSED at
that very commit with verdict `PASS_CORRECTED`, and its four-commit
range is verified (C0 RED, C1 EVIDENCE, C3 EVIDENCE, C4 CLOSE).

## 2. The six verified self-hosted parser authorities

Re-verified against the LIVE production OBJECTS.  The strong form is
used: each production object carries the PolyC symbol as an UNDEFINED
reference and does NOT define it, so the legacy C body is compiled
out.

```text
AUTHORITY                              MACRO                                          OBJ_UNDEFINED_REF  OBJ_DEFINED_HERE
BootstrapCalcPadding                   HCC_USE_SELFHOST_PARSER_PADDING                YES                 NO
BootstrapValidPostControlFlowToken     HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN    YES                 NO
BootstrapOperatorPrecedence            HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE   YES                 NO
BootstrapAstBinOpFromToken             HCC_USE_SELFHOST_PARSER_AST_BINOP              YES                 NO
BootstrapAstUnaryOpFromToken           HCC_USE_SELFHOST_PARSER_AST_UNARY              YES                 NO
BootstrapSwitchArmTerminates           HCC_USE_SELFHOST_PARSER_SWITCH_ARM             YES                 NO

PARSER_POLYC_AUTHORITIES_EXPECTED=6
PARSER_POLYC_AUTHORITIES_VERIFIED=6
```

## 3. The live census and the RECON04 reconciliation

The census is DERIVED from the live source BYTES by the ACT's own PolyC
tool, and is CROSS-VALIDATED against the CLOSED predecessor verifier
(used READ-ONLY, NOT modified).  The two tools produce BYTE-IDENTICAL
census output.

```text
src/parser.c    60
src/prslib.c    41
src/prsutil.c   27
src/ast.c      142
TOTAL          270
```

```text
LIVE_FUNCTIONS=270
CLASSIFIED_SYMBOLS=270
UNCLASSIFIED_LIVE_SURFACES=0
DUPLICATE_SURFACE_IDS=0
CONFLICTING_AUTHORITY_CLASSES=0
UNKNOWN_AUTHORITY_ROWS=0
SOURCE_HASH_MISMATCHES=0
SOURCE_RANGE_ERRORS=0
```

```text
file           RECON04  RECON05  added  removed  changed  unchanged
src/parser.c       58       60      2        0       22         36
src/prslib.c       41       41      0        0        0         41
src/prsutil.c      27       27      0        0        0         27
src/ast.c         142      142      0        0        0        142
TOTAL             268      270      2        0       22        246
```

The two additions were added by SLICE06 and NEITHER is a remaining
legacy C semantic authority: `parseSwitchArmTerminates` (the C
delegation adapter) and `ParserLegacySwitchArmTerminatesOracle` (the
G0 stage0 oracle).

The 22 changes are all in `src/parser.c`.  Eighteen moved by exactly
+101 lines (the SLICE06 insertion).  Four kept their line numbers but
changed their digest, because the census range convention (declarator
line to last body line) makes the SAME line span cover different bytes
after the insertion; their function BODIES are byte-identical.  This
is a property of the RANGE CONVENTION, and it is reported rather than
hidden.

## 4. The candidate population

```text
RECON04_CANDIDATES_RECONCILED=ALL (24 of 24)
  SUB-001..SUB-012       12 structural sub-slices
  CAND-018..CAND-040     12 scalar follow-ups
CANDIDATE_ID_REUSE=0
NEW_CANDIDATES=0
UNCLASSIFIED_FUNCTIONS=0
UNCLASSIFIED_SUBSLICES=0
UNCLASSIFIED_DEPENDENCIES=0
```

No new candidate was discovered: a source-census difference alone does
not authorize an added candidate, and no bounded sub-decision outside
the historical registry met the bar.

`SUB-005` REMAINS INELIGIBLE on LIVE evidence: `cctrlGetKeyWord`
consults the mutable `cc->symbol_table`, `cc->clsdefs` and
`cc->uniondefs`, and the RECON05 verifier detects that dependence
TRANSITIVELY through `cctrlIsKeyword`.

## 5. The canonical eligibility and ranking

Both the checker and the ranker are CLOSED predecessor artifacts, used
READ-ONLY and NOT modified.

```text
ELIGIBLE=15   INELIGIBLE=9
ELIGIBLE_STRUCTURAL=3   (SUB-002, SUB-003, SUB-004)
ELIGIBLE_SCALAR=12
INELIGIBLE_STRUCTURAL=8  (SUB-005..SUB-012)
INELIGIBLE_ALREADY_SELFHOSTED=1  (SUB-001)
```

The facts file carries NO `eligible` column, so the eligibility flag
cannot be hand-authored.

**R0 CONSISTENCY CORRECTION.** The RECON04 ranking table violated its
own stated invariant that "R0 is MECHANICALLY the same value the
eligibility checker used as its clause 03 input": `CAND-022` and
`CAND-023` had `facts_r0=1` but `dims_r0=0`.  RECON05 corrects both to
`R0=1`, so the ranking and the eligibility fact cannot drift apart.
The correction is recorded in `c2/ranking-dimensions.tsv`.

## 6. THE SELECTION, AND WHY IT IS NOT SUB-002

The canonical ranker selected **SUB-002**.  The EXECUTABLE CAUSALITY
GATE then FAILED for SUB-002, so it was removed from the feasible
subset by a machine-verifiable reason and the selection was RE-RUN.

SUB-002's live condition tests FIVE `AstKind` values
(`AST_COMPOUND_STMT`, `AST_CASE`, `AST_BREAK`, `AST_RETURN`,
`AST_GOTO`).  The already-migrated SUB-001 decision tests the SAME
FIVE plus `AST_DEFAULT`.  `AST_DEFAULT` is UNREACHABLE at that
position: `src/parser.c:1669` raises `"Duplicate default case"` when
`cc->tmp_default_case` is already set, so the inner
`parseDefaultStatement` never returns.

**THIS WAS PROVED BY EXECUTION, NOT BY ARGUMENT.**  A mutant that ADDS
`AST_DEFAULT` to the SUB-002 condition was built into the REAL compiler
in a disposable detached worktree, and the full 90-file production
suite was run with it:

```text
PRISTINE  376/376  md5=b6f117eb1386ca80f81bc06226e2a741
MUTANT    376/376  md5=b6f117eb1386ca80f81bc06226e2a741
```

The assertion sequences are BYTE-IDENTICAL.  The mutation has ZERO
observable effect, so **SUB-002 is DUPLICATED CODE, not a distinct
decision**.  Transferring it would create a SECOND PolyC authority for a
decision the first authority already owns.

## 7. The selected candidate

```text
SELECTED_CANDIDATE_ID=SUB-003
SELECTED_CLASS=STRUCTURAL_BOUNDARY
SELECTED_SOURCE_FILE=src/parser.c
SELECTED_SOURCE_RANGE=2049..2049
SELECTED_SOURCE_SHA256=378a39d71eed7aaf673bde3857cc08df6f9c95c776723832e6e460553be361e8
SELECTED_ENCLOSING_FUNCTION=parseCompoundStatementInternal
SELECTED_PRODUCTION_CALL_SITE=src/parser.c:2049
SELECTED_DECISION=Compound-block statement routing: given a parsed statement, decide whether it is APPENDED to the block statement list or SKIPPED because it is a global-variable declaration
SELECTED_STRUCTURAL_EFFECT=STATEMENT_SEQUENCE
SELECTED_BOUNDARY_CLASS=SCALAR_TO_SCALAR
SELECTED_ABI=I64 BootstrapCompoundBlockAppendsStatement(I64 stmt_kind, I64 declvar_kind) -> I64
```

### 7.1 The input and output projection

```text
INPUT_1=stmt->kind      (the AstKind enum value of the parsed statement)
INPUT_2=stmt->declvar->kind  (the AstKind enum value of the declvar)
OUTPUT=1 to APPEND the statement, 0 to SKIP it
```

Both inputs are **copied out** of the host AST node.  The component
never sees a host pointer, never allocates, never calls back, and
never touches the scope, the token stream, the recovery point or the
host AST graph.  The component is **TOTAL** over the whole `I64` domain
and has **no failure sentinel**.

The legacy `&&` short-circuits, so the C side evaluates
`stmt->declvar->kind` only when `stmt->kind == AST_DECL`.  The frozen
ABI preserves exactly that short-circuit.

### 7.2 The executed causal proof

A mutant that REMOVES the SUB-003 decision was built into the REAL
compiler in the disposable worktree:

```text
PRISTINE  compiles and runs the witness -> WITNESS_OUTPUT=12 2 (exit 0)
MUTANT    FAILS TO COMPILE the witness  -> ERROR: Mapping exists for 1 -> %l2 i64 local

PRISTINE  376/376  md5=b6f117eb1386ca80f81bc06226e2a741
MUTANT    371/371  md5=dc2f36f1bd63bca22fc7ea57359a770d
```

The two affected tests are `33_static.HC` and `34_global_array.HC`.
The decision is therefore **observable in the EXISTING production test
suite**, so the suite is already a ready-made differential for the
successor.

```text
CAUSAL_MUTANT_BUILD=SUCCESS
CAUSAL_DIRECTION=THE_MUTANT_IS_STRICTLY_WORSE
CAUSAL_RESTORATION_BYTE_IDENTICAL=YES
TRACKED_MAIN_WORKTREE_MUTATED=NO
MUTATION_MERGED_OR_COMMITTED=NO
```

## 8. The runner-up

`SUB-004` (the statement keyword dispatch) was also tested.  Routing
`KW_WHILE` to `parseDoWhileStatement` makes the REAL compiler fail to
parse every `while` loop:

```text
error: Unexpected character `(` while parsing do while loop body
```

`SUB-004` is causally feasible but ranks BELOW `SUB-003` on the
canonical ranking, so it is the runner-up, not the selection.

The twelve scalar follow-ups were NOT selected: the canonical policy
selects from the structural class first.  Three of them
(`CAND-021`, `CAND-022`, `CAND-040`) are DIAGNOSTICS-ONLY and two
(`CAND-038`, `CAND-039`) have a HOST STRING boundary.

## 9. The G0 oracle

```text
G0_REAL_PRODUCTION_C_OBJECT=build/CMakeFiles/hcc.dir/parser.c.o
G0_ORACLE_POLYC_REFERENCE=ABSENT
G0_ORACLE_KIND=OBJECT_LEVEL
G0_ORACLE_IS_REAL_PRODUCTION_TU=YES
G0_ORACLE_HAND_WRITTEN=NO
```

The object carries NO undefined reference to the proposed PolyC symbol,
so the oracle is INDEPENDENT of the proposed target.  It imports the
six already-migrated authorities as UNDEFINED references and does not
define them, which proves it is the genuine production TU and not a
hand-written stand-in.

## 10. The independent C3 witness

```text
INDEPENDENT_ELIGIBILITY_JOIN=24/24 EXACT, ZERO MISMATCH
INDEPENDENT_FULL_RANKING_JOIN=15/15 EXACT, ZERO MISMATCH
RANK_COMPLETE_ORDER_MISMATCH=0
```

`tools/quality/parser-surface-recon05-independent.HC` is a SECOND,
INDEPENDENT PolyC implementation.  It reads the raw C1 facts and the
dimension facts.  It does NOT read the C2 eligible decision, the C2
ranked list or the C2 winner as an oracle.

## 11. The nineteen negative controls

```text
CONTROL_TOTAL=19  CONTROL_EXECUTED=19  CONTROL_SENSITIVE=19
CONTROL_VACUOUS=0  CONTROL_HARMLESS=0  CONTROL_SUMMARY_ONLY=0
CONTROL_NOT_RESTORED=0
```

Every control fired for its INTENDED reason.  Three verifier gaps were
found and CLOSED during this ACT rather than papered over:

| Gap | Closure |
|---|---|
| a per-row checker cannot see a DELETED row (IC-01) | the `REGISTRY` mode compares the EXPECTED-ID set against the CLAIMED-ID set |
| the canonical checker has no UNKNOWN-ID concept (EC-06) | the `REGISTRY` mode supplies it |
| a dependence search over the candidate's own bytes cannot see a TRANSITIVE dependence (EC-05) | the `DEPENDS` mode expands the search through the functions the candidate CALLS, two levels deep, and into the host-control TU |

CC-04 is scoped to the FUNCTION and the PRODUCER OBJECT: the producer
object has 175 `cmp`/`tst` instructions in total, but only 5 inside
`parseCompoundStatementInternal`, of which exactly 2 are the SUB-003
comparison pair (`cmp w8,#263` = `AST_DECL` and `cmp w8,#256` =
`AST_GVAR`).

## 12. The conservation, measured

```text
PARSER HOST ARCH   376/376, assertion-sequence MD5
                    b6f117eb1386ca80f81bc06226e2a741   (IDENTICAL to entry)
LEXER07/08/09      PASS / 45/45 / 23/23
LEXER07 BROAD      TOTAL=181, FAIL_S0=15, REGRESSION=0, DIVERGED=0,
                    failure-identity MD5
                    7ee761440de83552e751e3c3976c1683  (IDENTICAL to entry)
CROSS-TARGET       67 attempted / 67 failed-to-open-file / 0 passed
                    (the HISTORICAL environment condition, reported
                    honestly and NOT silently waived)
GATE-FAST          PASS
GATE-PUSH          PASS
APPEND-ONLY        11/11 PASS
FACTORY-V2 RANGE   PASS
F14                PASS
CLOSURE-STATUS     PASS (38 pairs)
```

A NOTE ON THE FIRST C3 GATE-PUSH ATTEMPT: it FAILED in the JIT
`#link` test with an undefined `_main`.  The cause was a CONCURRENCY
ARTIFACT: that attempt ran concurrently with the unit-test and both
used the shared `/tmp/holyc-asm.s` temporary.  Re-run ALONE, gate-push
PASSES.  The observation is recorded in `c3/gate-push.txt` rather than
hidden.

## 13. The tool policies, reported honestly

```text
F-NO-PYTHON    STATUS=FAIL with EXACTLY the 12 PRE-EXISTING violations.
               NEW violations = 0.
F-POLYC-TOOLS  UNAVAILABLE.  The authoritative checker is STILL NOT
               LANDED.  It is NEVER reported PASS.
```

## 14. The residue

| Pri | Residue |
|---|---|
| P1 | The `F-POLYC-TOOLS` checker is still not landed.  The authoritative checker `tools/factory/factory-polyc-tools-check.HC` does not exist; the C2.9 residue recorded by `AGENTS.md` remains open. |
| P1 | The RECON04 ranking table's R0 inconsistency for `CAND-022` and `CAND-023` is corrected in RECON05's own artifacts but the historical RECON04 evidence is NOT rewritten (F14). |
| P2 | The PARSER01 whole-function blockers REMAIN: `parseCompoundStatementInternal`, `parseStatement` and `parseExpr` as whole functions, the recursive flow-analysis walks, and SUB-005 (the declaration-versus-statement routing, whose projection is unbounded because `cctrlIsKeyword` consults the mutable host symbol table). |
| P2 | The eleven other eligible candidates remain unmigrated: the two remaining structural sub-slices (`SUB-002` disqualified, `SUB-004` the runner-up) and the twelve scalar follow-ups.  Each is a viable later target with its own fixture, oracle and conservation baseline. |

## 15. The single-valued successor authorization

```text
PROPOSED_NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE07
PROPOSED_NEXT_ACT_TARGET=SUB-003
PROPOSED_NEXT_ACT_STATUS=INACTIVE_UNTIL_TERMINALITY
```

The successor inherits, UNCHANGED, from this ACT's C2 freeze:

```text
c2/selected-id-and-source.tsv
c2/selected-abi.md
c2/selected-production-seam.md
c2/selected-state-and-ownership.tsv
c2/selected-legacy-oracle.md
c2/selected-fixture-contract.tsv
c2/selected-red-contract.md
c2/selected-causal-contract.md
c2/selected-negative-controls.md
c2/selected-provenance-contract.md
c2/selected-conservation-contract.md
c2/selected-out-of-scope.md
```

There is exactly ONE authorized next target.  `SUB-002`, `SUB-004` and
the twelve scalar candidates are NOT authorized here.

**THIS AUTHORIZATION IS CONDITIONAL.** It is active only if this ACT's
C4 CLOSE has been executed AND the external post-CLOSE terminality
check has passed.  If that external check fails, the proposed successor
remains **INACTIVE** and is **NOT** authorized to execute.

This HANDOFF does not implement the successor and does not create it.

## Terminal facts

```text
ACT                           = ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05
TARGET                        = SUB-003
TARGET_CLASS                  = STRUCTURAL_BOUNDARY
POLYC_SYMBOL                  = BootstrapCompoundBlockAppendsStatement
POLYC_ABI                     = I64 BootstrapCompoundBlockAppendsStatement(I64 stmt_kind, I64 declvar_kind) -> I64
SELECTED_SOURCE_RANGE         = src/parser.c:2049..2049
SELECTED_SOURCE_SHA256        = 378a39d71eed7aaf673bde3857cc08df6f9c95c776723832e6e460553be361e8
PARSER_POLYC_AUTHORITIES      = 6
LIVE_FUNCTIONS                = 270
ELIGIBLE_CANDIDATES           = 15
ELIGIBLE_STRUCTURAL_CANDIDATES = 3
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

AC50 is `DEFERRED_TO_CLOSE`: the exactly-one terminal C4 CLOSE has not
been executed at the time this HANDOFF is written.  It is discharged by
the external post-CLOSE verification.

VERDICT

PASS

The parser surface has been re-inventoried from the live source (270
functions, every one classified, zero unclassified), the historical
reconnaissance has been reconciled by exact set difference in BOTH
directions, the PARSER01 dependency blockers have been re-measured, the
canonical 13-clause eligibility and the canonical R0..R6 ranking have
been executed unmodified with sensitive anti-bias controls, the
rank-1 candidate has been DISQUALIFIED by an EXECUTED causal experiment
that showed it is semantically identical to an already-migrated
authority, and exactly ONE eligible, causally feasible, distinct
structural boundary has been selected and frozen with a bounded ABI, a
real object-level legacy oracle, reproducible REDs, a fixture contract
derived from the live enum, twenty-nine negative controls and an
EXECUTED causal mutation experiment.

The production semantic delta is zero, no production code was touched,
the six previously migrated PolyC parser authorities are still live, and
the conservation suites are unchanged.
