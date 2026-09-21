# HANDOFF: ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01

Factory-Version: 2

## VERDICT

```text
VERDICT=PASS_TRUE_GREEN

NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-PADDING01
NEXT_TARGET=CAND-002 CalcPadding (src/parser.c:430..438)
NEXT_R0=0
NEXT_SCOPE_FROZEN=YES
```

## IDENTITY

| Field | Value |
| --- | --- |
| Repository | PolyC |
| Branch | `main` |
| Entry head | `b1aa4ab6c8567a5626fbb1094121b32b4bbee669` |
| Final head | (set in c4-parent-identity.txt) |
| Working tree | clean at every C0/C1/C2/C3/C4 boundary |
| Total commits in ACT | 5 |

## MISSION

After `ACT-POLYC-SELFHOST-PARSER01-CORRECTION01 HALT_DEPENDENCY_EXPLOSION`,
mechanically decompose the live parser into self-hostable semantic slices,
introduce R0 STATE_BOUNDARY_COST as the first ranking dimension, exclude
candidates that cross execution-context ownership or mutable host-graph
identity, rank all eligible candidates, and select exactly one bounded
next production migration target.

Zero production source mutation.

## PREDECESSOR HALT

```text
PREDECESSOR=ACT-POLYC-SELFHOST-PARSER01-CORRECTION01
PREDECESSOR_HALT=HALT_DEPENDENCY_EXPLOSION
PREDECESSOR_HALT_CLASS=GOVERNANCE
PREDECESSOR_BLOCKS_NEXT=YES

FAILED_SLICE=src/parser.c::parseCompoundStatementInternal (1752..1880, 129 LOC)
FAILED_REASON=BOUNDED_DEPENDENCY_GRAPH=NO
  ABI 7 (pure-data-flow) incompatible with jmp_buf ownership,
  AST-list pointer identity, and 9 subordinate-parser callbacks.
```

## LESSONS FROM PARSER01

From the PARSER01-CORRECTION01 finding, the ordering of selection criteria
is now binding:

```text
1. can authority cross safely?
2. can behavior be observed?
3. can the component be falsified?
4. can production actually delegate?
5. only then: how much leverage does it provide?
```

`STATE_BOUNDARY_COST` precedes `SELFHOST_LEVERAGE`. A small low-coupling
semantic primitive is preferred over a strategically attractive
orchestration function whose real authority still lives in C.

## INVENTORY

| Class | Count |
| --- | --- |
| Parser functions / static helpers inspected | 64 |
| Bounded candidate slices classified | 14 |
| Eligible (R0 <= 2) | 8 |
| Ineligible | 6 |

Ineligible breakdown:
- 1 STATE_BOUNDARY_COST_TOO_HIGH (CAND-014 whole compound function)
- 2 NON_SEMANTIC (clsFieldNew malloc wrapper, getRangeLoopIdx static counter)
- 1 HOST_GRAPH_WRITES>0 (parseFlattenAnnonymous)
- 1 PARSER_CALLBACK_COUNT>0 (parseRegModifier)
- 1 POINTER_IDENTITY_OPS>0 (parseFoldInitElement)

## R0 STATE-BOUNDARY MODEL

R0 is the first and strongest ranking dimension. Values:

```text
0 = bytes/scalars/enums only
1 = immutable copied token/value records; no host identity required
2 = bounded copied semantic record; deterministic reconstruction possible
3 = opaque host handle needed but candidate does not mutate referenced graph
4 = candidate mutates host-owned graph/state whose identity matters
5 = candidate owns or depends on execution-context/recovery authority,
    mutable callback authority, or non-local control transfer
```

Hard eligibility: `R0 <= 2` for normal semantic migration path.

The whole `parseCompoundStatementInternal` function lands at R0=5 (jmp_buf
ownership, AST-list pointer arithmetic, 9 subordinate-parser callbacks,
arbitrary stream mutation, LONGJMP error model). Lexer-family ABIs that
succeeded in LEXER01..04 land at R0=0 (byte/string -> scalar).

## ELIGIBILITY

A candidate is eligible iff (ACT SECT_33 conjunction):

```text
semantic_authority == YES
AND already_selfhosted == NO
AND r0_state_boundary_cost <= 2
AND owns_setjmp == NO
AND writes_current_recovery == NO
AND requires_nonlocal_recovery == NO
AND host_graph_writes == 0
AND pointer_identity_ops == 0
AND parser_callback_count == 0
AND semantic_callback_count == 0
AND deterministic_projection == YES
AND candidate_kind != NON_SEMANTIC
AND candidate_kind != DEAD_OR_NONRUNTIME
```

Eight candidates pass:
CAND-001 parseValidPostControlFlowToken,
CAND-002 CalcPadding,
CAND-003 CalcClassSize,
CAND-004 CalcUnionSize,
CAND-005 astIsConstTrueCond,
CAND-006 astStmtHasBreak,
CAND-007 astStmtFallsThrough,
CAND-008 asmTextHasReturn.

## RANKING

Lexicographic on `(R0, R1, R2, R3, R4, R5, R6)`; lower wins.

| rank | candidate | R0 | R1 | R2 | R3 | R4 | R5 | R6 |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 (SELECTED) | CAND-002 CalcPadding | 0 | 1 | 2 | 0 | 0 | 0 | src/parser.c:430 |
| 2 | CAND-001 parseValidPostControlFlowToken | 0 | 1 | 2 | 0 | 0 | 1 | src/parser.c:791 |
| 3 | CAND-003 CalcClassSize | 0 | 2 | 2 | 0 | 0 | 0 | src/parser.c:410 |
| 4 | CAND-004 CalcUnionSize | 0 | 2 | 2 | 0 | 0 | 0 | src/parser.c:397 |
| 5 | CAND-008 asmTextHasReturn | 1 | 2 | 2 | 0 | 0 | 1 | src/parser.c:1980 |
| 6 | CAND-005 astIsConstTrueCond | 2 | 2 | 2 | 1 | 0 | 0 | src/parser.c:1899 |
| 7 | CAND-006 astStmtHasBreak | 2 | 1 | 2 | 1 | 0 | 0 | src/parser.c:1907 |
| 8 | CAND-007 astStmtFallsThrough | 2 | 1 | 2 | 1 | 0 | 1 | src/parser.c:1932 |

## CONTROLS

All five negative controls PASS:

```text
RANKING_RESPONDS_TO_R0_PERTURBATION       YES
SELECTED_REMOVED_FROM_RANKING             YES
R0_ALONE_CANNOT_GREEN_INELIGIBLE_CANDIDATE YES
OPAQUE_HANDLE_RECLASSIFICATION_REJECTED   YES
CALLBACK_TABLE_RECLASSIFICATION_REJECTED  YES
```

Known-negative control (CAND-014 whole compound function) reproduced
ineligible at both C1 and C3. Known-positive calibration control
(LEXER01 operator-classify) reproduced R0=0 + ALREADY_SELFHOSTED.

## SELECTED TARGET

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-PADDING01
NEXT_TARGET_ID=CAND-002 CalcPadding
NEXT_TARGET_KIND=TYPE_MODIFIER_PRIMITIVE
NEXT_FILE=src/parser.c
NEXT_LINE_START=430
NEXT_LINE_END=438
NEXT_SEMANTIC_PURPOSE=Decide how many padding bytes are required to align
  the next field at offset to a size-byte boundary, with a guard for
  zero-size fields.
NEXT_R0=0

SELECTED_STATE_BOUNDARY_COST=0
SELECTED_OWNS_SETJMP=NO
SELECTED_WRITES_CURRENT_RECOVERY=NO
SELECTED_REQUIRES_NONLOCAL_RECOVERY=NO
SELECTED_HOST_GRAPH_WRITES=0
SELECTED_POINTER_IDENTITY_OPS=0
SELECTED_PARSER_CALLBACK_COUNT=0
SELECTED_SEMANTIC_CALLBACK_COUNT=0
SELECTED_DETERMINISTIC_PROJECTION=YES
```

## SELECTED ABI SHAPE

```text
I64 BootstrapCalcPadding(I64 offset, I64 size);
```

Returns the number of padding bytes (0..size-1) needed to align the
next field. Special cases:

```text
size == 0            -> return 0  (zero-size fields need no padding;
                                     guards against % 0 UB)
offset % size == 0   -> return 0
otherwise            -> return size - (offset % size)
```

Inputs are pure scalar integers; no pointers, no host identity.

```text
SELECTED_ABI_HOST_IDENTITY_FIELDS=0
```

## RED MODEL

Five mechanically reproducible REDs frozen for the successor ACT:

| ID | Subject | Witness |
| --- | --- | --- |
| RED-1 | subject absent | `[ ! -f tools/bootstrap/selfhost-parser-padding.HC ]` |
| RED-2 | bridge/API absent | `git grep -n 'BootstrapCalcPadding' tools/bootstrap src` returns nothing |
| RED-3 | legacy authority still production-active | parseClassOffsets and parseUnionOffsets still call C CalcPadding |
| RED-4 | no direct differential target exists | `[ ! -x ./build/parser-padding-oracle ]` |
| RED-5 | no independent fixedpoint evidence exists | `[ ! -x ./build/parser-padding-driver ]` |

```text
NEXT_RED_COUNT=5
NEXT_RED_MECHANICALLY_REPRODUCIBLE=YES
```

## PROOF MODEL

```text
DIRECT_DIFFERENTIAL                  REQUIRED
COMPONENT_OBJECT_FIXEDPOINT          REQUIRED
GENERATION_PROVENANCE                REQUIRED
CAUSAL_NEGATIVE_CONTROL              REQUIRED
LEXER_CONSERVATION                   REQUIRED
PARSER_CONSERVATION                  REQUIRED
PATCH_HYGIENE                        REQUIRED
F_POLYC_TOOLS                        REQUIRED
F_NO_PYTHON                          REQUIRED
F14                                  REQUIRED
PRODUCTION_SEAM                      NOT_APPLICABLE_WITH_REASON (reserved for next-next ACT)
BROAD_CORPUS                         NOT_APPLICABLE_WITH_REASON (2-input primitive; corpus partition covers it)

PROOF_MODEL_UNKNOWN=0
NEXT_PROOF_MODEL_COMPLETE=YES
```

Causal mutation classes:
- Class A: returns `size - offset%size` even when `size == 0`
- Class B: omits the `size == 0` guard
- Class C: returns `(offset % size == 0)` as a bool
- Class D: returns `offset % size` instead of `size - offset % size`

## CONSERVATION

By construction (no production source mutation):

```text
LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS
NEW_LEXER07_FAILURES=0
```

## FACTORY GATES

```text
GATE_FAST=PASS
APPEND_ONLY_FAIL=0  (11/11 NC tests PASS)
PATCH_HYGIENE_ERRORS=0
C3_PHASE_PURITY=PASS
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

## SCOPE

Files actually changed in this ACT (all under docs/ or evidence/):

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01.md
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01/{c0,c1,c2,c3,c4}/**
```

Production source delta:

```text
PRODUCTION_SOURCE_DELTA=0
COMPILER_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0
```

## RESIDUE

| Priority | Item | Disposition |
| --- | --- | --- |
| P1 | The 7 unselected eligible candidates remain in the inventory; a future parser-selfhost ACT may pick them once R0 dominates them out of the way. | Carry forward as residue; do not migrate in this ACT. |
| P1 | The PARSER01-CORRECTION01 finding "ABI 7 incompatible with jmp_buf" is a permanent architectural observation; it remains open for the parser-state-representation architecture ACT. | Do not address in this ACT. |
| P2 | The `parseClassOffsets` and `parseUnionOffsets` callers of `CalcPadding` remain C; production delegation to the PolyC `BootstrapCalcPadding` is the next-next ACT's responsibility. | Carry forward. |

## NEXT

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-PADDING01
NEXT_TARGET=CAND-002 CalcPadding (src/parser.c:430..438)
NEXT_R0=0
NEXT_SCOPE_FROZEN=YES

NEXT_ACT_OBJECTIVES (binding for the successor ACT):
  1. Add tools/bootstrap/selfhost-parser-padding.HC implementing
     I64 BootstrapCalcPadding(I64 offset, I64 size).
  2. Add a direct-differential oracle binary that runs the C
     CalcPadding and the PolyC BootstrapCalcPadding side-by-side
     on the corpus recorded in c2-selected-fixture-model.tsv.
  3. Add a stub-mutation harness that exercises Class A-D mutation
     classes and confirms the oracle flags every input.
  4. Demonstrate component-object fixedpoint by linking a small HC
     driver that loops over the corpus and exits 0.
  5. NOT modify src/parser.c or any production caller of CalcPadding.

NEXT_ACT_OUT_OF_SCOPE:
  - parseCompoundStatementInternal migration
  - parseStatement / parseDecl* / parseExpr* / parseToplevel* migration
  - introduction of callback tables or opaque host handles
  - changes to Ast/Cctrl/Map/List representation
```
