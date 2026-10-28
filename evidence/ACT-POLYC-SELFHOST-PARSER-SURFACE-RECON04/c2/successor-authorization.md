# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SUCCESSOR AUTHORIZATION

**AUTHORIZED SUCCESSOR:** `ACT-POLYC-SELFHOST-PARSER-SLICE06`
**SINGLE-VALUED SUCCESSOR AUTHORIZATION:** `SUB-001`

---

## The inherited freeze

The successor inherits, unchanged, from this ACT's C2 freeze:

```text
SELECTED_CANDIDATE_ID=SUB-001
SELECTED_CANDIDATE_CLASS=STRUCTURAL_BOUNDARY
SELECTED_SOURCE_IDENTITY=src/parser.c:1551..1553
SELECTED_SOURCE_SHA256=31dc9ae8f87d26be429a565356820d8913c9a7cbc0e37d64470049c3b5948707
SELECTED_ABI=I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64
SELECTED_BOUNDARY_CLASS=SCALAR_TO_SCALAR
SELECTED_LEGACY_ORACLE=c2/probes/legacy-sub001-oracle.c (source-bound
    extraction of src/parser.c:1551..1553), with the object-level
    strengthening required by c2/selected-oracle-contract.md section 4
SELECTED_FIXTURE_CONTRACT=c2/selected-fixture-contract.tsv
SELECTED_NEGATIVE_CONTROLS=c2/selected-negative-controls.md
SELECTED_RED_CONTRACT=c2/selected-red-contract.md
SELECTED_CAUSAL_CONTRACT=c2/selected-causal-contract.md
SELECTED_PRODUCTION_SEAM=src/parser.c:1551..1553 (the single `if`
    condition in parseCaseLabel)
SELECTED_CONSERVATION_BASELINE=c2/successor-scope.md section 5
SELECTED_OUT_OF_SCOPE=c2/successor-scope.md section 2
SELECTED_STATE_PROJECTION=c2/selected-state-projection.tsv
```

## The single-valued authorization

```text
NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE06
NEXT_TARGET=SUB-001
NEXT_TARGET_CLASS=STRUCTURAL_BOUNDARY
NEXT_ABI=I64 BootstrapSwitchArmTerminates(I64 ast_kind) -> I64
NEXT_SCOPE_FROZEN=YES
```

There is exactly ONE authorized next target.  The other three eligible
structural sub-slices (`SUB-002`, `SUB-003`, `SUB-004`) and the twelve
eligible scalar candidates remain authorized for LATER acts; they are
NOT authorized here.

## Why this target, in one paragraph

It is the rank-1 of the eligible structural class under the ACT's
canonical R0..R6 vector, computed by the UNMODIFIED canonical ranker
over the committed fact table, and confirmed by the ACT's own
anti-bias controls (row permutation, winner removal, R0 perturbation,
ineligible-ideal-score, source-order tie break, structural-class
removal, false structural classification, stale candidate id, and a
historical ranking replay that reproduces the RECON03 ordering exactly).
Its decision is a pure `SCALAR -> SCALAR` set-membership over one
copied `AstKind` value, it has a real production call path, it has a
real legacy oracle, it has a REPRODUCIBLE causal experiment (already
executed: the compiled program output changes when the decision
changes and returns byte-identical on restoration), and its migration
retires a real C decision instead of duplicating one.  It keeps the
whole recovery, graph, symbol-table, token-stream and diagnostic
ownership on the C side, exactly as PARSER01 required.

## What the successor is NOT authorized to do

It is NOT authorized to:

```text
* re-run the ranking and choose a different target
* migrate SUB-002, SUB-003, SUB-004 or any historical scalar candidate
* move any host graph, recovery, symbol-table, token-stream or
  diagnostic authority into PolyC
* change the AstKind enum values
* change any diagnostic text
* introduce Python
* weaken the 13-clause eligibility model or the canonical ranking
```

## The structural blockers that REMAIN

The reconnaissance did NOT resolve the PARSER01 whole-function
blockers.  They remain open engineering work and are NOT deferred by
this authorization:

```text
STILL_BLOCKED=parseCompoundStatementInternal as a whole function
               (owns the setjmp recovery point, the block scope, the
                AST-list tail rollback and the tmp_locals rollback)
STILL_BLOCKED=parseStatement as a whole function
               (owns the scope, the global AST list and the asm-block
                list, and invokes 20 subordinate parsers)
STILL_BLOCKED=parseExpr as a whole function
               (builds the host AST through a recursive precedence loop)
STILL_BLOCKED=the recursive flow-analysis walks
               (astStmtFallsThrough, astStmtHasBreak)
STILL_BLOCKED=the declaration-versus-statement routing decision
               (SUB-005: cctrlIsKeyword consults the mutable host
                symbol table, so its projection is not bounded)
```

This authorization deliberately migrates a SMALLER decision while the
enclosing authorities stay on the C side.
