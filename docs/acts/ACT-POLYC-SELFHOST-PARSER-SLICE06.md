# ACT-POLYC-SELFHOST-PARSER-SLICE06

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / STRUCTURAL-SUBSLICE / PRODUCTION-AUTHORITY-MIGRATION
**Priority:** P0
**Repository:** `s1onique/polyc`
**Branch:** `main`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04`
(closed with `ACT-Verdict: PASS`; its evidence tree, HANDOFF and ACT
document are closed evidence under F14 and are NOT modified here)
**Expected ENTRY_HEAD:** `1ccf28d58fec9c856c12ad1f71bab9a2ca6e18e0`
**Target:** `SUB-001` -- the switch-case arm termination decision
**Successor:** none preselected

---

## 0. Mission

Migrate only the switch-arm termination decision inside
`parseCaseLabel` from production-authoritative C into
production-authoritative, compiled PolyC.

The predecessor has already migrated:

```text
BootstrapCalcPadding                   -> POLYC production authority
BootstrapValidPostControlFlowToken     -> POLYC production authority
BootstrapOperatorPrecedence             -> POLYC production authority
BootstrapAstBinOpFromToken              -> POLYC production authority
BootstrapAstUnaryOpFromToken            -> POLYC production authority
```

SLICE06 must migrate:

```text
the switch-case arm termination decision
  -> BootstrapSwitchArmTerminates
  -> POLYC production authority
```

### Required final result

```text
SWITCH_ARM_TERMINATION_AUTHORITY = POLYC
LEGACY_SWITCH_ARM_C_AUTHORITY     = RETIRED
SIXTH_POLYC_PARSER_AUTHORITY      = ESTABLISHED
```

### The frozen target

```text
SELECTED_CANDIDATE=SUB-001
SELECTED_CANDIDATE_CLASS=STRUCTURAL_BOUNDARY
SELECTED_ENCLOSING_FUNCTION=parseCaseLabel
SELECTED_SOURCE_RANGE=src/parser.c:1551..1553
SELECTED_SOURCE_SHA256=31dc9ae8f87d26be429a565356820d8913c9a7cbc0e37d64470049c3b5948707
SELECTED_ABI=I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64
SELECTED_BOUNDARY_CLASS=SCALAR_TO_SCALAR
```

The selection is INHERITED from the predecessor's frozen contract.  The
ranking is CLOSED and this ACT does NOT re-run it.

### The frozen terminating set

```text
AST_COMPOUND_STMT = 274
AST_CASE          = 287
AST_DEFAULT       = 293
AST_BREAK         = 280
AST_RETURN        = 270
AST_GOTO          = 258
```

These six values are the live `src/ast.h` values.  They are NOT
hard-coded assumptions: they are bound to the live header by COMPILING
it and, independently, by PARSING the live `src/parser.c` condition
text.

### The frozen projection

```text
PROJECTION_FIELD_COUNT=1
PROJECTION_FIELD=stmt->kind
PROJECTION_ACCESS=READ
PROJECTION_SCALAR_TYPE=I64
PROJECTION_RESULT_TYPE=I64
PROJECTION_BOUNDED=YES
PROJECTION_POINTER_CROSSING=NONE
PROJECTION_CALLBACK_CROSSING=NONE
PROJECTION_JMP_BUF_CROSSING=NONE
```

### The ownership that must be preserved

```text
RECOVERY_OWNER=C
AST_GRAPH_OWNER=C
SYMBOL_TABLE_OWNER=C
TOKEN_STREAM_OWNER=C
DIAGNOSTIC_OWNER=C
LONGJMP_TARGET_OWNER=C
ERROR_MESSAGE_OWNER=C
TOKEN_REWIND_OWNER=C
ALLOCATION_OWNER=C
```

## 1. In scope

1. The PolyC component implementing the frozen ABI.
2. The dedicated delegation selector `HCC_USE_SELFHOST_PARSER_SWITCH_ARM`
   and the subject link, following the pattern of the five already
   migrated authorities.
3. EXACTLY ONE condition in `src/parser.c` -- the `if` at
   `src/parser.c:1551..1553` -- replaced by a call to the PolyC
   component.
4. The four independently compiled generations (G0 legacy C from the
   real production object, G1/G2/G3 PolyC) and their comparisons.
5. The direct differential against the REAL legacy oracle over the
   derived fixture matrix.
6. The production causal experiment with the POLYC decision mutated,
   and the restoration.
7. The parser and lexer conservation suites and the required Factory
   gates.

## 2. Out of scope

```text
NO_CHANGE_TO=src/ast.h                (the AstKind enum values are FROZEN)
NO_CHANGE_TO=any other parser function
NO_CHANGE_TO=src/lexer.c, src/lexer.h
NO_CHANGE_TO=src/ast.c, src/ast.h, src/prslib.c, src/prsutil.c
NO_CHANGE_TO=src/cctrl.c, src/cctrl.h
NO_CHANGE_TO=src/transpiler.c, src/main.c
NO_CHANGE_TO=the recovery protocol
NO_CHANGE_TO=the diagnostic texts
NO_CHANGE_TO=the arm-loop structure
NO_CHANGE_TO=the other three structural sub-slices (SUB-002, SUB-003, SUB-004)
NO_CHANGE_TO=the seven historical scalar candidates
NO_CHANGE_TO=the closed evidence trees
NO_CHANGE_TO=the hook policy
NO_CHANGE_TO=compiler feature flags or dependency versions
NO_NEW_PYTHON
NO_REOPEN_OF=the ranking
```

## 3. The mandatory acceptance ledger

The 36 mandatory acceptance predicates are frozen, with unique IDs and
independently checkable predicates, in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/c0/mandatory-ac-contract.tsv`.
Each ID is joined to its evidence and its observed result in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/c3/mandatory-ac-status.tsv`.

## 4. The halt conditions

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_CONTRACT_MISMATCH
HALT_SOURCE_SHA_CHANGED
HALT_SCOPE_EXPANSION
HALT_MISSING_REAL_C_ORACLE
HALT_UNBOUNDED_ABI
HALT_PRODUCTION_DELEGATION_NOT_LOAD_BEARING
HALT_LEGACY_C_STILL_AUTHORITATIVE
HALT_FIXTURE_INCOMPLETE
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_STAGE_PROVENANCE_UNPROVEN
HALT_CAUSAL_MUTATION_NOT_OBSERVED
HALT_NEW_FAILURE_IDENTITY
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_INVARIANT
HALT_MANDATORY_AC
HALT_TERMINALITY
```

A preexisting F-NO-PYTHON violation, the missing F-POLYC-TOOLS checker
and the unchanged historical cross-target prefix failure are recorded
RESIDUE, not permission to waive a new ACT-owned violation.
