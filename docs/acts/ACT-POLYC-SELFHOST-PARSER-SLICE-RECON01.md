# ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Mechanically decompose the live parser into self-hostable semantic slices and select exactly one bounded next production migration target

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / PARSER / RECON / TARGET-SELECTION

**Priority:** P0

---

## Mission

After PARSER01 (`HALT_PHASE_CORRECTION_REQUIRED`) and PARSER01-CORRECTION01
(`HALT_DEPENDENCY_EXPLOSION`), do not attempt another whole-function parser
migration by numbering or intuition.

Instead:

1. reconstruct the live parser semantic surface below the orchestration-function level;
2. enumerate bounded parser functions and extractable semantic sub-slices;
3. classify state ownership, recovery ownership, mutable-graph coupling,
   subordinate-parser dependencies, and observable semantic projections;
4. introduce **R0 STATE_BOUNDARY_COST** as the first ranking dimension;
5. exclude candidates that require `jmp_buf`, `Cctrl *`, `Ast *` graph ownership,
   or callback-table authority to cross the PolyC boundary;
6. rank all remaining eligible candidates mechanically;
7. select **exactly one** next production migration target;
8. freeze a mechanically reproducible RED and complete proof model for that target.

This ACT performs **zero compiler semantic mutation**.

Terminal success predicates are enumerated in section 9 of this document.

---

## Authority

Authorized by the terminal C1 result of
`ACT-POLYC-SELFHOST-PARSER01-CORRECTION01`
(`evidence/ACT-POLYC-SELFHOST-PARSER01-CORRECTION01/c1/c1-required-result.txt`):

```text
HALT_TOKEN=HALT_DEPENDENCY_EXPLOSION
HALT_CLASS=GOVERNANCE
BLOCKS_NEXT=YES
C1_VERDICT=BOUNDED_DEPENDENCY_GRAPH=NO
```

for the failed whole-function slice:

```text
LEGACY_C_AUTHORITY
src/parser.c::parseCompoundStatementInternal
```

The failed slice SHALL NOT be retried unchanged.

---

## Binding discoveries inherited from PARSER01-CORRECTION01

From `evidence/ACT-POLYC-SELFHOST-PARSER01-CORRECTION01/c1/`:

```text
FUNCTION=parseCompoundStatementInternal
FILE=src/parser.c
LINE_START=1752
LINE_END=1880
LOC=129

SUBORDINATE_PARSER_DEPENDENCY_COUNT=24
DEFERRED_SURFACE_CALLS=9
  parseBaseDeclSpec, parsePointerType, parseRegModifier,
  parseArrayDimensions, parseFunctionPointer (via parseFunctionPointerType),
  parseVariableInitialiser, parseAssignAuto,
  parseStatement (2 paths)

RECOVERY_OWNERSHIP=owns jmp_buf stmt_recovery; installs into cc->current_recovery
SETJMP_CALL=1789
RECOVERY_BODY_LINES=1790..1802
THREADED_ACROSS_ABI_FIELDS=4
MIRROR_IN_POLYC_NEEDED_FIELDS=4
```

The earlier `1752..2012` / 260 LOC estimate is superseded by the live C1 read.

---

## Governing invariant (F-ORDERING)

From PARSER01 the following ordering is now binding:

```text
can authority cross safely?
        |
        v
can behavior be observed?
        |
        v
can the component be falsified?
        |
        v
can production actually delegate?
        |
        v
only then:
how much leverage does it provide?
```

Therefore:

```text
STATE_BOUNDARY_COST precedes SELFHOST_LEVERAGE.
```

A small low-coupling semantic primitive is preferred over a strategically
attractive orchestration function whose real authority still lives in C.

---

## R0 -- STATE_BOUNDARY_COST

R0 is the **first and strongest ranking dimension**. Values:

```text
0 = bytes/scalars/enums only

1 = immutable copied token/value records;
    no host identity required

2 = bounded copied semantic record;
    deterministic reconstruction possible;
    no raw host graph identity required

3 = opaque host handle needed but candidate itself does not mutate
    referenced graph

4 = candidate mutates host-owned graph/state whose identity matters

5 = candidate owns or depends on execution-context/recovery authority,
    mutable callback authority, or non-local control transfer
```

Ranking is ascending. Lower is better.

Hard eligibility threshold for normal semantic migration path:

```text
R0 <= 2
```

---

## Hard eligibility predicate

A candidate is eligible iff:

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

No human override.

---

## What this ACT explicitly must NOT do

```text
implement the selected parser slice
create its PolyC production subject
add its bridge
modify src/parser.c
fix parser bugs
change setjmp/longjmp architecture
introduce callback tables
introduce opaque host handles
change Ast/Cctrl representation
migrate parseStatement
migrate parseDecl*
migrate parseExpr*
migrate parseToplevel*
```

This ACT answers **what to migrate next**, not performs that migration.

---

## HALT taxonomy

```text
HALT_ENTRY_DIRTY
HALT_AUTHORIZATION_MISSING

HALT_INVENTORY_INCOMPLETE
HALT_UNKNOWN_CANDIDATES
HALT_UNCLASSIFIED_COUPLING

HALT_CONTROL_FAILED

HALT_ELIGIBILITY_INCONSISTENT
HALT_RANKING_INCONSISTENT

HALT_NO_BRIDGEABLE_PARSER_SLICE

HALT_SELECTED_R0_TOO_HIGH
HALT_SELECTED_RECOVERY_COUPLED
HALT_SELECTED_GRAPH_COUPLED
HALT_SELECTED_CALLBACK_COUPLED
HALT_SELECTED_PROJECTION_UNSTABLE

HALT_ABI_SKETCH_HOST_IDENTITY
HALT_PRODUCTION_SEAM_NOT_FEASIBLE
HALT_FIXEDPOINT_NOT_FEASIBLE
HALT_CAUSAL_CONTROL_NOT_FEASIBLE

HALT_RED_MODEL_INCOMPLETE
HALT_PROOF_MODEL_INCOMPLETE

HALT_RECON_INCONSISTENCY

HALT_LEXER_CONSERVATION
HALT_LEXER07_NEW_REGRESSION

HALT_F_POLYC_TOOLS
HALT_F_NO_PYTHON
HALT_F14_VIOLATION

HALT_FACTORY_GATE
HALT_APPEND_ONLY
HALT_PATCH_HYGIENE
HALT_C3_PHASE_PURITY
HALT_C4_PRECONDITION

HALT_PHASE_CORRECTION_REQUIRED
```
