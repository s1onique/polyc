# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / STRUCTURAL-SURFACE-RECON / NEXT-ATOMIC-SLICE-SELECTION
**Priority:** P0
**Repository:** `s1onique/polyc`
**Branch:** `main`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE05`
**Expected ENTRY_HEAD:** `22107263561dfbc8f09df2b6dca066cf25d939c1`
**Successor:** `ACT-POLYC-SELFHOST-PARSER-SLICE06` (conditional on successful selection)

---

## 0. Mission

After five parser semantic authorities have been migrated into
production-authoritative PolyC, mechanically re-inventory the remaining
legacy-C parser and AST semantic authorities.

Find the next bounded migration surface, preferably within structural
parsing, without reproducing the dependency explosion encountered in
PARSER01.

**This is a reconnaissance and successor-contract ACT. It does not
implement the successor.**

Required result:

```text
PARSER_SURFACE_INVENTORY=COMPLETE
LEGACY_C_AUTHORITY_INVENTORY=COMPLETE
CURRENT_SELFHOSTED_AUTHORITY_INVENTORY=COMPLETE

STRUCTURAL_SUBSLICE_DISCOVERY=COMPLETE
HOST_STATE_BOUNDARIES_CLASSIFIED=YES
UNCLASSIFIED_DEPENDENCIES=0

ALL_CANDIDATES_EVALUATED=YES
ELIGIBILITY_MECHANICALLY_VERIFIED=YES
RANKING_MECHANICALLY_VERIFIED=YES

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_ELIGIBLE=YES
SELECTED_BOUNDARY_BOUNDED=YES

SELECTED_ABI_FROZEN=YES
SELECTED_LEGACY_ORACLE_IDENTIFIED=YES
SELECTED_RED_REPRODUCIBLE=YES
SELECTED_CAUSAL_PROOF_FEASIBLE=YES

PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE06
```

Selection must be computed from live source and mechanically verified
candidate facts.

No target is preselected.

A structural candidate is preferred over another routine scalar helper
only when it satisfies the independently frozen eligibility and
boundedness requirements.

**Never select an ineligible structural candidate merely to demonstrate
architectural progress.**

---

## 1. Entry identity

Before creating or modifying tracked files:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git replace -l

git log -1 --format='%B' |
  git interpret-trailers --parse

git log -5 --format='%H %s'
```

Expected:

```text
BRANCH=main
ENTRY_HEAD=22107263561dfbc8f09df2b6dca066cf25d939c1
WORKTREE_CLEAN=YES
GIT_REPLACE_REFS=0

PREDECESSOR_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE05
PREDECESSOR_PHASE=CLOSE
PREDECESSOR_VERDICT=PASS
```

If the expected commit is not HEAD, establish the real current identity
and inventory every intervening change before continuing.

Do not mistake a remote branch that has not received SLICE05 for the
authoritative local entry.

Do not perform a reset, rebase, amend, or force-push to recreate an
expected state.

### 1.1 Mandatory predecessor reads

```text
AGENTS.md
docs/factory/DOCTRINE.md
docs/factory/GIT-METADATA.md

docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE05.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE05.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE04.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03.md

docs/factory/LEXER07-BASELINE-AUTHORITY.tsv

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c1/
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c3/

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c1/
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c2/
```

Also read the original PARSER01 dependency-halt evidence:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER01-CORRECTION01.md

evidence/ACT-POLYC-SELFHOST-PARSER01-CORRECTION01/
  c1/c1-dependency-map.tsv
  c1/c1-state-read-write.tsv
  c1/c1-setjmp-recovery.tsv
  c1/c1-subordinate-parser-deps.tsv
  c1/c1-bounded-dependency-graph.tsv
```

These historical artifacts are evidence and input to reconciliation.
They do not override the current source.

---

## 2. Previous engineering authority

Five qualified parser migrations must remain active:

| Surface | PolyC authority |
|---|---|
| Parser padding | `BootstrapCalcPadding` |
| Post-control-flow token validity | `BootstrapValidPostControlFlowToken` |
| Operator precedence | `BootstrapOperatorPrecedence` |
| AST binary operator classification | `BootstrapAstBinOpFromToken` |
| AST unary operator classification | `BootstrapAstUnaryOpFromToken` |

All five must be confirmed from the actual production configuration and
object linkage.

Require:

```text
PARSER_POLYC_AUTHORITIES_EXPECTED=5
PARSER_POLYC_AUTHORITIES_VERIFIED=5

AST_BINARY_AUTHORITY=POLYC
AST_UNARY_AUTHORITY=POLYC
AST_OPERATOR_CLASSIFICATION=COMPLETE
```

A symbol merely present in the final binary is not sufficient.

Verify production branch selection and the real call path. A C fallback
that still owns the decision does not qualify as PolyC authority.

### 2.1 Baseline conservation

Freeze entry-tree identities for:

```text
src/parser.c
src/prslib.c
src/prsutil.c
src/ast.c
src/ast.h
src/cctrl.c
src/cctrl.h
src/lexer.c
src/lexer.h
src/CMakeLists.txt

tools/bootstrap/selfhost-parser-padding.HC
tools/bootstrap/selfhost-parser-control-flow-token.HC
tools/bootstrap/selfhost-parser-operator-precedence.HC
tools/bootstrap/selfhost-parser-slice04.HC
tools/bootstrap/selfhost-parser-slice05.HC
```

The ACT must not change any of them.

### 2.2 Conservation baseline

Measure on ENTRY_HEAD:

```text
PARSER_HOST_ARCH_ASSERTIONS
PARSER_HOST_ARCH_FAILURE_IDENTITIES

PARSER_CROSS_TARGET_STATUS
PARSER_CROSS_TARGET_FAILURE_IDENTITIES

LEXER_DIRECT_DIFFERENTIAL_RESULTS
LEXER07_BROAD_CORPUS_COUNTERS
LEXER07_BROAD_CORPUS_FAILURE_IDENTITIES

GATE_FAST_RESULT
GATE_PUSH_RESULT
```

SLICE05 reported 90 passing host-architecture parser test files and
376/376 assertions. Re-measure; do not copy those values into the
current ledger without executing the suite.

The existing LEXER07 broad corpus can remain `STATUS=FAIL` while the
regression delta is zero.

The installation-prefix limitations are historical conditions, not a
license to hide new failures.

---

## 3. Scope

### 3.1 Authorized tracked additions

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md

evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/**
```

At most one new substantive PolyC quality tool may be introduced if
existing tools cannot satisfy a required mechanical check:

```text
tools/quality/parser-surface-recon04-verify.HC
```

Its exact responsibility must be frozen in C1.

Prefer reusing these existing tools read-only:

```text
tools/quality/parser-slice-recon03-eligibility.HC
tools/quality/parser-slice-recon03-ranking.HC
```

Do not rewrite their historical predicates or ranking semantics.

Bounded C oracle drivers and temporary proof probes may be created under
ignored `build/` directories. They must be reproducible from commands
and inputs frozen in committed evidence.

Any probe required to reproduce a binding successor claim must have its
complete source or exact reproducible construction committed in the new
ACT's evidence tree.

### 3.2 Forbidden tracked mutations

```text
src/**
tools/bootstrap/**

existing tools/quality/parser-slice*.HC
existing Factory checkers
existing shell gates
pre-push hooks

closed ACT documents
closed evidence trees
closed HANDOFF files
```

No parser implementation, compiler configuration change, lexer change,
AST allocation redesign, or production CMake modification.

No new Python.

No unrelated build-system changes.

### 3.3 Permitted scratch experiments

The ACT may use ignored scratch workspaces to:

- Build the actual entry compiler.
- Compile C oracle probes.
- Execute candidate-level differential witnesses.
- Test a prospective PolyC/C ABI.
- Apply a bounded mutation to an isolated source copy.
- Compile and run a mutated production compiler to demonstrate causal
  feasibility.

No scratch experiment may mutate tracked production source.

No experiment may be passed off as an implemented successor.

---

## 4. Inventory boundaries

Inventory the actual functions and semantic sub-slices in:

```text
src/parser.c
src/prslib.c
src/prsutil.c
src/ast.c
```

Include relevant dependency edges into:

```text
src/cctrl.c
src/cctrl.h
src/lexer.c
src/lexer.h
src/ast.h
src/transpiler.c
src/main.c
```

The latter files are dependency and consumer surfaces, not automatically
authorized parser migration targets.

### 4.1 Function inventory

Record for every live function:

```text
surface_id
symbol
source_file
source_start
source_end
source_sha256

semantic_owner
authority_class
production_reachable
production_callers

input_domain
output_domain

direct_callees
indirect_callbacks

global_state_reads
global_state_writes

host_graph_reads
host_graph_writes

allocation_dependencies
recovery_dependencies
diagnostic_dependencies

already_selfhosted
candidate_class
classification_reason
```

The function census must be mechanically derived from the live source.

RECON03's historical count of 118 functions is a reference, not a
mandatory current count.

### 4.2 Canonical authority classes

Use the existing authority taxonomy:

```text
SELFHOSTED_TRUE_GREEN
LEGACY_C_AUTHORITY
LEGACY_NON_POLYC_AUTHORITY
BUILD_ORCHESTRATION
QUALITY_TOOLING
UNKNOWN
```

Do not count a C ABI forwarding wrapper as `LEGACY_C_AUTHORITY` if PolyC
genuinely owns the semantic decision in production.

Conversely, do not mark a legacy decision self-hosted merely because a
PolyC implementation exists somewhere in `tools/bootstrap/`.

Every runtime semantic authority must receive exactly one current
classification.

Required:

```text
UNCLASSIFIED_LIVE_SURFACES=0
DUPLICATE_SURFACE_IDS=0
CONFLICTING_AUTHORITY_CLASSES=0
```

### 4.3 Conservation identity

Produce:

```text
OLD_SURFACES
NEW_SURFACES
REMOVED_SURFACES
RENAMED_SURFACES
MIGRATED_SURFACES
SPLIT_SURFACES
MERGED_SURFACES
```

Every change from RECON03 must be explained by an exact source or
production-authority difference.

Do not infer the new inventory count by subtracting five from RECON03's
total.

---

## 5. Previously eligible candidate reconciliation

RECON03 reported ten eligible candidates.

Three have since migrated:

```text
CAND-017 parseGetPriority
CAND-019 astBinOpFromToken
CAND-020 astUnaryOpFromToken
```

The remaining historically eligible candidates are:

| Historical ID | Function | Historical source |
|---|---|---|
| CAND-018 | `parseCompoundAssign` | `src/prslib.c` |
| CAND-021 | `astBinOpToTokenPunct` | `src/prslib.c` |
| CAND-022 | `parseCountPrintfFormatSpecs` | `src/prslib.c` |
| CAND-023 | `parseFormatArgIdx` | `src/prslib.c` |
| CAND-025 | `astIsAssignment` | `src/ast.c` |
| CAND-026 | `astIsValidPointerOp` | `src/ast.c` |
| CAND-030 | `parseIsClassOrUnion` | `src/prsutil.c` |

These seven must be reevaluated.

They are not automatically eligible today, and their historical rankings
are not frozen recommendations.

For each:

```text
SOURCE_STILL_EXISTS
BODY_SEMANTICS_CHANGED
PRODUCTION_REACHABILITY_CHANGED
DEPENDENCIES_CHANGED

CURRENT_AUTHORITY
CURRENT_ELIGIBILITY
CURRENT_RANK_VECTOR
```

Preserve historical IDs.

Do not reuse a historical ID for a different semantic slice.

New candidate IDs must come from the next unallocated canonical
candidate-ID range after reconciling the live registry. Do not assume an
ID is free merely because it is absent from a historical summary.

---

## 6. Structural dependency reconnaissance

This is the load-bearing new work.

The earlier parser effort halted because `parseCompoundStatementInternal`
combined incompatible authorities across a proposed pure-data-flow ABI.

The goal is to determine whether a **smaller semantic decision** can be
extracted while C retains graph ownership, parser callbacks, and recovery
orchestration.

### 6.1 Required state classification

Every dependency of a proposed sub-slice must be assigned to exactly one
category:

| Category | Meaning |
|---|---|
| `SCALAR_VALUE` | Immutable integer, enum, boolean, or bounded scalar |
| `BOUNDED_COPY` | Explicitly bounded copied token/semantic record |
| `HOST_GRAPH_READ` | Direct read from a host-owned AST/Cctrl/List/Map/Vec graph |
| `HOST_GRAPH_WRITE` | Mutation of host-owned pointer graph or compiler state |
| `HOST_ALLOCATION` | Allocation whose ownership remains with C |
| `CALLBACK` | Invocation of subordinate parser or arbitrary semantic function |
| `RECOVERY` | `setjmp`, `longjmp`, recovery target, or nonlocal control transfer |
| `DIAGNOSTIC` | Error construction, token rewind, source-range diagnostics |
| `GLOBAL_AUTHORITY` | Process-wide mutable or externally controlled semantic state |

Do not classify a function by its return type alone.

A function returning an integer can still own a mutable AST graph or
recovery boundary.

### 6.2 Required structural regions

At minimum, revisit these source regions and their immediate
dependencies:

**A. Compound-statement orchestration**

```text
parseCompoundStatementInternal
parseCompoundStatement
```

Inspect the per-statement recovery checkpoint, block scope, AST-list tail
rollback, temporary locals, and declaration/statement loop.

**B. Statement dispatch**

```text
parseStatement
parseDeclOrStatement
```

Inspect keyword dispatch, punctuation classification,
declaration/statement routing, and the boundary between classification
and AST construction.

**C. Expression parser**

```text
parseExpr
parseUnaryExpr
parsePostFixExpr
parseSubscriptExpr
parseGetClassField
parseCompoundAssign
```

Inspect the semantic decisions remaining after operator precedence and
unary/binary token classification were migrated.

**D. Declarations and types**

```text
parseDecl
parseDeclInternal
parseDeclSpec
parsePointerType
parseArrayDimensions
```

Inspect candidate decisions that can be expressed without moving mutable
symbol tables or AST allocations across the ABI.

**E. AST construction and validation**

Inspect bounded semantic checks surrounding:

```text
astBinaryOp
astUnaryOperator
astIsAssignment
astIsValidPointerOp
```

Do not assume an AST-construction function is eligible merely because a
scalar predicate can be found inside it.

**F. Statement/flow analysis**

Inspect any live helpers responsible for control-flow classification,
fallthrough detection, switch/case termination, and structural AST
validation.

Every discovered candidate must be bound to an actual source range and
production consumer.

### 6.3 PARSER01 dependency replay

Recompute the historical PARSER01 findings.

The current source retains a recovery structure in
`parseCompoundStatementInternal` involving:

```text
setjmp
cc->current_recovery
cc->localenv
body->stms
cc->tmp_locals
cctrlSyncStatement
subordinate parser calls
```

The original C1 reported 24 subordinate calls, nine deferred surfaces, and
an unbounded graph for the whole-function ABI.

Do not simply copy those numbers.

Report:

```text
HISTORICAL_SUBORDINATE_CALLS=24
CURRENT_SUBORDINATE_CALLS=<measured>

HISTORICAL_DEFERRED_SURFACES=9
CURRENT_DEFERRED_SURFACES=<measured>

HISTORICAL_WHOLE_FUNCTION_BOUNDED=NO
CURRENT_WHOLE_FUNCTION_BOUNDED=<measured>
```

A change in the whole-function verdict requires actual new source
evidence.

### 6.4 Recovery ownership invariant

For any proposed bounded slice:

```text
RECOVERY_OWNER=C
AST_GRAPH_OWNER=C
SYMBOL_TABLE_OWNER=C
TOKEN_STREAM_OWNER=C
DIAGNOSTIC_OWNER=C
```

PolyC may own a deterministic decision based on copied, bounded inputs.

PolyC must not directly own:

```text
jmp_buf
Cctrl *
Ast *
AstType *
List *
Map *
Vec *
```

unless a separate explicitly authorized ABI design and ownership proof
establishes safety.

SURFACE-RECON04 does not authorize moving those graph or recovery
authorities.

---

## 7. Structural sub-slice discovery

For each structural region, identify candidate decisions inside the
enclosing C function.

Candidate examples for investigation—not preselected targets—include:

```text
statement keyword dispatch decision
declaration-versus-statement routing decision

compound-block continuation decision
statement append / skip decision

switch/case termination decision
post-expression continuation decision

bounded AST-kind validity decision
bounded parser recovery/resynchronization classification
```

The actual candidates must arise from live code and call-graph
inspection.

### 7.1 Structural candidate requirements

A proposed structural candidate is valid only if it has:

1. A bounded, explicit input projection.
2. A bounded, explicit output representation.
3. An independently identifiable semantic decision currently owned by C.
4. A real production call path.
5. A legitimate C oracle or executable semantic reference.
6. No hidden ownership of host mutable graph, allocation, callbacks, or
   recovery.
7. A demonstrable route for production delegation.
8. A falsifiable production-level causal observation.

The candidate must not be invented as a detached utility that no
production caller needs.

### 7.2 Structural significance

Classify:

```text
STRUCTURAL_BOUNDARY
SCALAR_FOLLOWUP
INELIGIBLE_STRUCTURAL
ALREADY_SELFHOSTED
NONRUNTIME
```

To qualify as `STRUCTURAL_BOUNDARY`, the decision must materially affect
at least one:

```text
AST_SHAPE
PARSER_ACCEPTANCE
PARSER_ROUTING
STATEMENT_SEQUENCE
CONTROL_FLOW_CLASSIFICATION
RECOVERY_RESYNCHRONIZATION_CHOICE
```

A purely diagnostic string formatter, enum-to-string conversion, or
unrelated small scalar helper is `SCALAR_FOLLOWUP`, not
`STRUCTURAL_BOUNDARY`.

The classification itself is independently checked against a production
consumer and a specified observable effect.

### 7.3 No phantom authority transfer

A candidate cannot qualify merely because PolyC could duplicate a C
computation.

The successor must be able to retire a real C semantic decision.

Required:

```text
REAL_LEGACY_DECISION_IDENTIFIED=YES
PRODUCTION_DELEGATION_SEAM_IDENTIFIED=YES
LEGACY_DECISION_RETIREMENT_FEASIBLE=YES
```

If C continues to make the same decision after receiving the PolyC
result, the candidate is not a valid authority-transfer slice.

### 7.4 Bounded input projection

For every candidate, write the actual projection:

```text
C-owned source values
        |
        v
explicit scalar/copy projection
        |
        v
PolyC decision
        |
        v
bounded result
        |
        v
C-owned mutation/orchestration
```

For a candidate extracted from a graph-using function, list each accessed
host field and classify whether it is copied into a value or remains
host-owned.

No opaque `void *` or encoded pointer pretending to be a scalar.

No undocumented callback table.

No direct `jmp_buf` transfer.

---

## 8. Eligibility

Reuse RECON03's canonical 13-clause eligibility checker wherever
possible.

The exact clauses and accepted input schema must be read from the
committed checker and its frozen contract.

Do not invent a new approximation and call it the RECON03 eligibility
model.

### 8.1 Input facts

Candidate fact tables must not contain a manually authored final
`eligible=YES` result.

Eligibility must be derived from the actual dependency and boundary
facts.

Require a mechanical cross-check:

```text
CANDIDATE_FACTS_BOUND_TO_SOURCE=YES
ELIGIBILITY_COMPUTED=YES
ELIGIBILITY_CLAUSES_APPLIED=13

UNCLASSIFIED_DEPENDENCIES=0
UNSUPPORTED_INPUT_SCHEMA_ROWS=0
```

If a proposed bounded graph projection requires an extension to the
historical checker, preserve the original 13-clause result and record any
new structural-safety predicate separately.

Do not silently weaken the old 13 clauses.

### 8.2 Eligibility negative controls

Execute against the actual checker:

```text
NC-E01  ALREADY_SELFHOSTED candidate
NC-E02  NONRUNTIME candidate
NC-E03  graph-writing candidate
NC-E04  recovery-owning candidate
NC-E05  callback-owning candidate
NC-E06  unbounded input record
NC-E07  no production call path
NC-E08  no real oracle
NC-E09  no causal production observable
```

Controls targeting a canonical clause must cause that clause to fail.

For new structural-only predicates, exercise the new independent
structural checker.

A control rejected for a different unrelated reason does not demonstrate
the intended detector.

### 8.3 Full-function versus sub-slice distinction

For each structural candidate record both:

```text
ENCLOSING_FUNCTION_ELIGIBLE
SUBSLICE_ELIGIBLE
```

It is valid for:

```text
ENCLOSING_FUNCTION_ELIGIBLE=NO
SUBSLICE_ELIGIBLE=YES
```

only when the sub-slice's narrower ABI and delegated semantics are
independently proven.

The enclosing function's stateful dependencies do not disappear; they
remain on the C side of the seam.

---

## 9. Ranking and selection

### 9.1 Canonical dimensions

Use the historically frozen vector:

```text
(R0, R1, R2, R3, R4, R5, R6)
```

Keep the canonical definitions:

```text
R0 = STATE_BOUNDARY_COST
R1 = SELFHOST_STAGE_LEVERAGE
R2 = SEMANTIC_CENTRALITY
R3 = PROOF_OBSERVABILITY
R4 = DEPENDENCY_COUPLING_COST
R5 = MIGRATION_SIZE
R6 = SOURCE_ORDER
```

Use the existing checker/ranker semantics exactly for the primary
mechanical ranking.

Do not replace historical dimensions with a new undocumented weighted
score.

### 9.2 Structural progress policy

This ACT explicitly authorizes a two-class selection policy:

```text
CLASS_1 = ELIGIBLE_STRUCTURAL_BOUNDARY
CLASS_2 = ELIGIBLE_SCALAR_FOLLOWUP
```

Selection procedure:

1. Evaluate eligibility for all candidates.
2. Rank all eligible candidates using the canonical vector.
3. Produce separate mechanically sorted rankings for both classes.
4. If at least one eligible structural candidate exists, select its rank-1
   candidate.
5. Otherwise, select rank-1 from the eligible scalar-followup class.
6. If neither class contains an eligible candidate, HALT with the complete
   rejection matrix.

This class preference is a **new, explicitly authorized recon policy**,
not a retrospective redefinition of R0..R6.

It prioritizes meaningful structural self-hosting only after the
structural candidate passes every safety and feasibility predicate.

### 9.3 Ranker controls

Required:

```text
NC-R01 candidate row permutation
NC-R02 winner removal
NC-R03 ranking-value perturbation
NC-R04 ineligible candidate with ideal scores
NC-R05 source-order tie break
NC-R06 structural-class removal
NC-R07 false structural classification
NC-R08 stale candidate ID
NC-R09 historical ranking replay
```

At least the perturbation, winner-removal, and ineligible-ideal-score
controls must produce the expected changes in winner or eligibility.

Replay an old frozen ranking input to prove the existing ranker still
produces its historical ordering.

### 9.4 No handpicked winner

The winner must be recomputed from the committed input fact table.

Required:

```text
ELIGIBLE_CANDIDATES=<measured>
ELIGIBLE_STRUCTURAL_CANDIDATES=<measured>
ELIGIBLE_SCALAR_CANDIDATES=<measured>

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE=<computed>
SELECTED_RANK=1
SELECTED_ELIGIBLE=YES
```

The selected ID must be unique and consistent across all C2, C3, C4,
ROADMAP, and HANDOFF artifacts.

No prose recommendation may override the computed winner.

---

## 10. Successor ABI proof model

For the selected candidate, freeze:

```text
SELECTED_FUNCTION
SELECTED_SOURCE_RANGE
SELECTED_SOURCE_SHA256

SELECTED_BOUNDARY_CLASS
SELECTED_HOST_STATE_PROJECTION

SELECTED_POLYC_SYMBOL
SELECTED_INPUT_FIELDS
SELECTED_OUTPUT_FIELDS

SELECTED_ABI
SELECTED_FAILURE_SEMANTICS
SELECTED_PRODUCTION_CALL_SITES
SELECTED_LEGACY_DECISION_OWNER
```

The ABI must be expressible as either:

```text
SCALAR -> SCALAR
```

or:

```text
BOUNDED_COPIED_RECORD -> BOUNDED_RESULT
```

No unbounded pointer graph may cross.

If a copied record is proposed, freeze its exact field order, types,
maximum size, serialization/calling convention, validity rules, and
failure behavior.

### 10.1 Stage boundary

Define the G0 legacy reference and prospective G1/G2/G3 PolyC build path.

The successor must be able to produce four independently compiled
generations with semantically comparable outputs.

Do not assert that independent compilation occurred during this
reconnaissance merely because a build plan exists.

### 10.2 Real legacy oracle

The oracle must execute the actual C semantic decision.

Permitted strategies:

```text
compile the actual legacy function

compile an actual production source object with
delegation disabled

extract a contiguous legacy decision with
source-bound mechanical verification
```

A separately rewritten C lookalike is not sufficient as the sole oracle.

If a structural sub-slice lacks an existing standalone function,
establish a reproducible source-bound oracle strategy before declaring it
eligible for the successor.

### 10.3 Recovery and diagnostics

For any candidate near parser recovery:

```text
RECOVERY_OWNER=C
LONGJMP_TARGET_OWNER=C
ERROR_MESSAGE_OWNER=C
TOKEN_REWIND_OWNER=C
```

The prospective PolyC result may influence a bounded decision, but it
must not change where exceptions are caught or which parser frame owns
recovery.

### 10.4 Negative control model

Freeze at least one mutation that produces:

```text
PRISTINE_OBSERVATION
MUTATED_OBSERVATION
RESTORED_OBSERVATION
```

A mutation that merely makes the compiler crash or prevents linking is
insufficient.

The successor must demonstrate a successfully built mutant compiler whose
changed PolyC decision changes a real production observation.

---

## 11. Fixture contract

Freeze a reproducible fixture specification for the chosen candidate.

Its exact number of rows depends on the selected domain.

Do not invent the count before observing the source.

Minimum dimensions:

```text
accepted cases
rejected cases

all semantic branches
all boundary values

aliasing-sensitive cases
state projection edge cases

error/failure behavior
real production caller cases
mutation-sensitive cases
```

For structural candidates, additionally cover:

```text
AST shape
statement ordering
scope-sensitive decisions
nested contexts
recovery-adjacent cases
```

Include only dimensions actually meaningful to the selected slice.

### 11.1 Independent fixture integrity

The fixture producer and integrity verifier must not share the same logic
for deriving semantic coverage.

Require:

```text
EXPECTED_IDS=OBSERVED_IDS
EXPECTED_PARTITIONS=OBSERVED_PARTITIONS

DUPLICATE_IDS=0
UNKNOWN_IDS=0
MISSING_IDS=0

MALFORMED_ROWS=0
INVALID_INPUT_VALUES=0
UNTESTED_SEMANTIC_BRANCHES=0
```

The fixture count is a result of coverage, not the definition of
coverage.

### 11.2 Fixture negative controls

Freeze controls for:

```text
missing mandatory semantic case
duplicate ID
unknown ID
indented unknown row
malformed copied record
out-of-range numeric input
missing boundary value
incorrect expected result
```

The successor contract must require each control to fail for the intended
reason.

---

## 12. RED contract

The selected successor requires reproducible REDs.

At least:

```text
RED-1  selected PolyC component absent

RED-2  production delegation absent

RED-3  legacy C decision still owns production semantics

RED-4  expected ABI/bridge not yet available

RED-5  mutation-sensitive production behavior established
       on the legacy oracle
```

If the selected candidate is a newly extracted sub-slice, distinguish:

```text
SOURCE_DECISION_EXISTS=YES
EXTRACTED_COMPONENT_EXISTS=NO
```

Do not claim the original source function is absent when only the
proposed extracted component is absent.

Every RED must have an exact rerunnable command and real observed result.

The successor must be able to reproduce those REDs at its own entry HEAD.

---

## 13. Causal proof feasibility

For the selected target, perform an isolated causal feasibility experiment
if the source and build boundary allow it.

The preferred experiment:

```text
G0 pristine legacy decision
   -> compile
   -> run witness
   -> output A

G0 bounded legacy-decision mutation
   -> compile
   -> run SAME witness
   -> output B

G0 pristine restoration
   -> compile
   -> run SAME witness
   -> output A
```

Require:

```text
PRISTINE_BUILD=PASS
MUTANT_BUILD=PASS
RESTORED_BUILD=PASS

MUTATED_OUTPUT_DIFFERS=YES
RESTORED_OUTPUT_EQUALS_PRISTINE=YES
```

This demonstrates that the selected semantic decision is actually
observable.

It does not demonstrate a future PolyC implementation or production
migration.

If the direct mutation experiment is not feasible at recon time, the
candidate must instead provide a precise executable causal proof strategy
with independently confirmed call-path reachability. Such a weaker
feasibility result must be explicitly distinguished from an executed
causal control and may not satisfy a stricter frozen requirement by
relabeling it.

### Production observable

Prefer an observation whose meaning is clear:

```text
compiled program output
AST structure serialization
parser acceptance/rejection
specific diagnostic
statement/control-flow result
```

An object symbol existing without an observable effect is insufficient.

---

## 14. C0 — AUTH / baseline

Create:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c0/
```

Required files:

```text
entry-identity.txt
predecessor-close.txt
selfhosted-authority-baseline.tsv
source-freeze.tsv
historical-recon-binding.txt
scope-contract.txt
baseline-gates.txt
baseline-parser.txt
baseline-lexer.txt
required-result.txt
```

Commit the ACT body and C0 evidence.

C0 must freeze the authority taxonomy, structural preference policy,
eligibility/ranking semantics, and scope before C1 inventory.

Commit trailers:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
ACT-Phase: RED
```

No successor implementation.

---

## 15. C1 — INVENTORY / DEPENDENCY GRAPH

Perform the full live-source census.

Create:

```text
c1/
  function-inventory.tsv
  semantic-authority.tsv

  historical-surface-reconciliation.tsv
  historical-candidate-reconciliation.tsv

  production-call-graph.tsv
  dependency-edges.tsv
  state-read-write.tsv

  recovery-ownership.tsv
  callback-ownership.tsv
  allocation-ownership.tsv
  host-graph-ownership.tsv

  structural-regions.tsv
  structural-subslices.tsv
  scalar-followups.tsv

  candidate-source-bindings.tsv
  eligibility-input-facts.tsv

  inventory-controls.txt
  required-result.txt
```

Every new sub-slice must identify an exact source range and semantic
owner.

Every rejected sub-slice must retain a named rejection reason.

### C1 verification

Require:

```text
INVENTORY_COVERAGE=COMPLETE
LIVE_SURFACES_WITHOUT_CLASSIFICATION=0
UNCLASSIFIED_STATE_DEPENDENCIES=0
UNCLASSIFIED_CALLBACKS=0
UNCLASSIFIED_RECOVERY_EDGES=0

HISTORICAL_CANDIDATES_RECONCILED=YES
```

Commit:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
ACT-Phase: EVIDENCE
```

No tracked production mutation.

---

## 16. C2 — ELIGIBILITY / RANK / SELECT

Execute the actual eligibility checker and ranker against C1's committed
candidate facts.

Generate:

```text
c2/
  eligibility-results.tsv
  excluded-candidates.tsv
  eligible-candidates.tsv

  ranking-dimensions.tsv
  ranked-all-candidates.tsv
  ranked-structural-candidates.tsv
  ranked-scalar-followups.tsv

  eligibility-controls.txt
  ranking-controls.txt
  historical-replay.txt

  selection-result.tsv
  selection-rationale.txt

  selected-state-projection.tsv
  selected-abi-contract.md
  selected-oracle-contract.md
  selected-fixture-contract.tsv
  selected-negative-controls.md
  selected-red-contract.md
  selected-causal-contract.md

  successor-scope.md
  successor-authorization.md

  mandatory-ac-contract.tsv
  required-result.txt
```

### C2 decision gate

Require:

```text
ALL_CANDIDATES_EVALUATED=YES
ELIGIBILITY_CONTROL_FAILURES=0
RANKING_CONTROL_FAILURES=0

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_ELIGIBLE=YES

SELECTED_ABI_BOUNDED=YES
SELECTED_REAL_C_ORACLE_FEASIBLE=YES
SELECTED_PRODUCTION_DELEGATION_FEASIBLE=YES
SELECTED_CAUSAL_PROOF_FEASIBLE=YES
```

If no candidate satisfies the contract, halt truthfully with complete
evidence. Do not fabricate a rank-1 winner.

Commit:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
ACT-Phase: EVIDENCE
```

---

## 17. C3 — INDEPENDENT VERIFICATION

Re-run the entire decision pipeline from the committed C1 and C2 inputs.

### 17.1 Inventory verification

Independently compare the live source against the frozen inventory.

Check:

```text
SOURCE_RANGE_MATCHES=YES
SOURCE_HASH_BINDINGS_VALID=YES
CALL_GRAPH_BINDINGS_VALID=YES

UNCLASSIFIED_DEPENDENCIES=0
```

### 17.2 Eligibility verification

The independent verifier must recompute eligibility from facts, not copy
the already computed `eligible` column.

Require:

```text
C1_FACTS_TO_C3_ELIGIBILITY=DETERMINISTIC
C2_ELIGIBILITY_EQUALS_C3=YES
```

### 17.3 Ranking verification

The C3 recomputation must reproduce:

```text
ALL_RANKED_CANDIDATES
STRUCTURAL_RANKING
SCALAR_RANKING
SELECTED_WINNER
```

Byte-identical results are preferred when the output format is canonical.

A superficially matching winner with a different ranking order is not
sufficient.

### 17.4 Mutation and anti-bias controls

Rerun all eligibility and ranking controls.

The controls must actually change the inputs.

Require explicit:

```text
INPUT_MUTATION_OBSERVED=YES
EXPECTED_VERDICT_CHANGE_OBSERVED=YES
PRISTINE_RECHECK=PASS
```

### 17.5 Successor contract completeness

Independently validate that the selected target has:

```text
source-bound decision
bounded ABI
real oracle
fixture coverage
RED witnesses
negative controls
production call graph
causal mutation model
four-generation proof model
conservation requirements
out-of-scope contract
```

An incomplete successor contract may not be classified as READY.

### 17.6 Conservation

Run the canonical current targets:

```sh
make gate-fast
make gate-push

make lexer07-direct-differential
make lexer08-direct-differential
make lexer09-direct-differential
make lexer07-broad-corpus-4-stage
```

Run the canonical parser test suite using the appropriate qualified
install prefix.

The broad-corpus command may exit nonzero for its known baseline
failures. Record the real command outcome and compare its failure
identities to the canonical registry.

Required:

```text
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_LEXER_FAILURE_IDENTITIES=0
NEW_LEXER07_FAILURE_IDENTITIES=0
```

Require actual `gate-push=PASS` for the frozen mandatory gate. If it is
not green, halt rather than substitute a no-new-regressions claim.

### 17.7 Factory invariants

Run:

```text
factory-v2 validation
factory-append-only test
factory-closure-status check
F-NO-PYTHON check
F-POLYC-TOOLS check if available
```

Report unavailable tooling as unavailable.

Zero new Python sources, invocations, or unauthorized tooling violations.

### C3 artifacts

```text
c3/
  inventory-recompute.txt
  source-binding-verify.txt

  dependency-graph-verify.txt
  eligibility-recompute.tsv
  ranking-recompute.tsv

  eligibility-negative-controls.txt
  ranking-negative-controls.txt
  winner-recompute.txt

  selected-abi-verify.txt
  oracle-feasibility-verify.txt
  red-reproduction.txt
  causal-feasibility.txt
  fixture-contract-verify.txt

  parser-conservation.txt
  lexer-conservation.txt
  lexer07-delta.txt

  gate-fast.txt
  gate-push.txt
  factory-v2.txt
  append-only.txt
  closure-status.txt

  f14.txt
  f-no-python.txt
  f-polyc-tools.txt
  patch-hygiene.txt
  scope-verify.txt

  mandatory-ac-status.tsv
  required-result.txt
```

Commit:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
ACT-Phase: EVIDENCE
```

---

## 18. Mandatory acceptance criteria

Freeze exactly 50 AC rows in C2 and verify every row by ID.

| ID | Required predicate |
|---|---|
| AC01 | Entry branch and full HEAD verified |
| AC02 | Entry worktree clean |
| AC03 | Predecessor CLOSE reachable and identified |
| AC04 | Zero Git replace refs |
| AC05 | Five existing parser PolyC authorities proven live |
| AC06 | Closed predecessor evidence and HANDOFF immutable |
| AC07 | Current parser/AST function census complete |
| AC08 | Every live semantic authority classified |
| AC09 | No duplicate or conflicting surface identities |
| AC10 | Historical RECON03 inventory reconciled |
| AC11 | All seven historical remaining eligible candidates reevaluated |
| AC12 | Migrated CAND-017/019/020 excluded from legacy selection |
| AC13 | Compound-statement dependency graph recomputed |
| AC14 | Statement-dispatch dependencies classified |
| AC15 | Expression-parser dependencies classified |
| AC16 | Declaration/type dependencies classified |
| AC17 | AST validation/construction dependencies classified |
| AC18 | All relevant recovery ownership classified |
| AC19 | All relevant callback ownership classified |
| AC20 | All relevant graph reads/writes classified |
| AC21 | Structural sub-slices discovered or exhaustively rejected |
| AC22 | Every candidate bound to live source and production consumers |
| AC23 | No unclassified candidate dependencies |
| AC24 | Existing 13-clause eligibility applied mechanically |
| AC25 | Eligibility negative controls sensitive and passing |
| AC26 | Canonical R0–R6 definitions retained |
| AC27 | Canonical ranking mechanically executed |
| AC28 | Ranking anti-bias controls sensitive and passing |
| AC29 | Structural/scalar class policy applied exactly as authorized |
| AC30 | Selected winner independently recomputed |
| AC31 | Exactly one eligible target selected |
| AC32 | Selected host-state projection complete |
| AC33 | Selected ABI bounded and unambiguous |
| AC34 | Selected C semantic authority identified |
| AC35 | Real legacy oracle strategy reproducible |
| AC36 | Production delegation seam feasible |
| AC37 | Failure/recovery semantics frozen |
| AC38 | Fixture contract covers all required semantic branches |
| AC39 | Fixture-integrity and negative-control contract complete |
| AC40 | Component-absent RED reproducible |
| AC41 | Production legacy-authority RED reproducible |
| AC42 | Production causal proof feasible and correctly classified |
| AC43 | Four-generation successor proof model complete |
| AC44 | Successor mutation and restoration contract complete |
| AC45 | Existing parser/lexer conservation has zero new failures |
| AC46 | No production or successor implementation mutation |
| AC47 | F14, scope, no-new-tool violations, and patch hygiene pass |
| AC48 | `make gate-fast` passes |
| AC49 | `make gate-push` and required Factory tests pass |
| AC50 | Valid CLOSE, exact commit topology, and external terminality |

### AC ledger

At successful closure:

```text
AC_TOTAL=50
AC_UNIQUE=50
AC_MISSING=0
AC_DUPLICATE=0

AC_PASS=50
AC_FAIL=0
AC_UNPROVEN=0
```

AC50 may be deferred at C3 because its terminal observations require C4
to exist.

The ledger must be mechanically joined to the frozen contract by AC ID.

Do not prove the ledger by counting summary rows that the verifier itself
just generated without checking the actual predicate identities and
their evidence.

---

## 19. HALT taxonomy

Use the narrowest applicable halt:

```text
HALT_ENTRY_IDENTITY_INVALID
HALT_PREDECESSOR_UNBOUND
HALT_F14_VIOLATION

HALT_INVENTORY_INCOMPLETE
HALT_UNCLASSIFIED_SEMANTIC_AUTHORITY
HALT_UNCLASSIFIED_STATE_DEPENDENCY

HALT_RECOVERY_BOUNDARY_UNSAFE
HALT_CALLBACK_BOUNDARY_UNSAFE
HALT_HOST_GRAPH_BOUNDARY_UNSAFE

HALT_NO_BOUNDED_STRUCTURAL_SLICE
HALT_NO_ELIGIBLE_CANDIDATE
HALT_ELIGIBILITY_CHECKER_INCOMPATIBLE
HALT_RANKING_NOT_REPRODUCIBLE

HALT_SELECTED_ABI_UNBOUNDED
HALT_REAL_C_ORACLE_UNAVAILABLE
HALT_PRODUCTION_SEAM_NOT_FEASIBLE
HALT_CAUSAL_PROOF_NOT_FEASIBLE

HALT_FIXTURE_CONTRACT_INCOMPLETE
HALT_SUCCESSOR_CONTRACT_INCOMPLETE

HALT_CONSERVATION_REGRESSION
HALT_SCOPE_VIOLATION
HALT_FACTORY_GATE_NOT_GREEN
HALT_MANDATORY_AC_NOT_GREEN
```

`HALT_NO_BOUNDED_STRUCTURAL_SLICE` alone does not require halting if an
eligible scalar fallback exists under §9's authorized policy.

If no eligible candidate of either class exists, the ACT must HALT with
the full negative classification matrix.

A complexity estimate, long execution time, or session boundary is not a
halt condition.

A HALT must not be converted to PASS by weakening a frozen predicate.

---

## 20. C4 — CLOSE

If C3 establishes every mandatory nonterminal predicate, commit:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04.md
```

Append one managed mapping to:

```text
docs/factory/act-handoff-map.tsv
```

Update the roadmap.

The HANDOFF must contain:

1. Actual entry identity.
2. Five verified self-hosted parser authorities.
3. Current authority inventory.
4. Changes relative to RECON03.
5. Historical candidate reconciliation.
6. Structural dependency-graph results.
7. New structural sub-slices and rejection reasons.
8. Complete eligibility results.
9. Full rank order and controls.
10. Exactly one computed winner.
11. Selected ABI and state projection.
12. Oracle, RED, fixture, mutation and provenance contracts.
13. Conservation and Factory gate results.
14. Honest residue and blocked boundaries.
15. Single-valued successor authorization.

### Exact topology

Five forward-only commits:

```text
C0  RED       authorization + entry baseline
C1  EVIDENCE  full inventory + dependency graph
C2  EVIDENCE  eligibility + ranking + successor freeze
C3  EVIDENCE  independent verification
C4  CLOSE     HANDOFF + final verdict
```

One contiguous Git trailer block per commit.

Successful C4:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

No amend, reset, rebase, force-push, or sixth fixup commit.

No post-C4 evidence addition.

No modification to any closed predecessor.

---

## 21. External terminality

After C4 exists, perform read-only checks:

```sh
git status --porcelain=v1
git replace -l

git diff --check <ENTRY_HEAD>..HEAD

git rev-list --count <ENTRY_HEAD>..HEAD

sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 HEAD

git log -1 --format='%B' |
  git interpret-trailers --parse
```

Require:

```text
ACT_COMMIT_COUNT=5
C4_DIRECT_PARENT_IS_C3=YES

FACTORY_V2_RANGE_CHECK=PASS
WORKTREE_CLEAN=YES
GIT_REPLACE_REFS=0
PATCH_HYGIENE_ERRORS=0

CLOSE_IS_ACT_TIP=YES
POST_CLOSE_CONTINUATION=NO
```

Do not commit these observations into the closed ACT tree.

---

## 22. Terminal result

Successful closure must produce:

```text
ACT=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
VERDICT=PASS

PARSER_POLYC_AUTHORITIES=5

PARSER_SURFACE_INVENTORY=COMPLETE
LEGACY_AUTHORITY_INVENTORY=COMPLETE

HISTORICAL_CANDIDATES_RECONCILED=YES
STRUCTURAL_SUBSLICE_DISCOVERY=COMPLETE
UNCLASSIFIED_DEPENDENCIES=0

ELIGIBILITY_CHECK=PASS
RANKING_CHECK=PASS
ANTI_BIAS_CONTROLS=PASS

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_ID=<measured>
SELECTED_CANDIDATE_CLASS=<measured>

SELECTED_ABI_BOUNDED=YES
SELECTED_REAL_C_ORACLE=IDENTIFIED
SELECTED_PRODUCTION_SEAM=FEASIBLE

SELECTED_RED_MODEL=REPRODUCIBLE
SELECTED_FIXTURE_CONTRACT=COMPLETE
SELECTED_CAUSAL_MODEL=FEASIBLE

PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

NEW_PARSER_FAILURE_IDENTITIES=0
NEW_LEXER_FAILURE_IDENTITIES=0

F14=PASS
GATE_FAST=PASS
GATE_PUSH=PASS
FACTORY_V2=PASS
APPEND_ONLY=PASS
PATCH_HYGIENE=PASS

MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=50
MANDATORY_AC_FAIL=0

ACT_COMMIT_COUNT=5
POST_CLOSE_CONTINUATION=NO

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE06
```

No selected target, source SHA, ABI, fixture count, or gate result may be
fabricated before measurement.

---

## 23. Successor authorization

On a successful selection, authorize:

```text
ACT-POLYC-SELFHOST-PARSER-SLICE06
```

The successor inherits from the RECON04 C2 freeze:

```text
SELECTED_CANDIDATE_ID
SELECTED_SOURCE_IDENTITY
SELECTED_ABI
SELECTED_LEGACY_ORACLE
SELECTED_FIXTURE_CONTRACT
SELECTED_RED_CONTRACT
SELECTED_CAUSAL_CONTRACT
SELECTED_NEGATIVE_CONTROLS
SELECTED_PRODUCTION_SEAM
SELECTED_CONSERVATION_BASELINE
SELECTED_OUT_OF_SCOPE
```

SLICE06 must implement exactly the selected authority.

It must not reopen the ranking merely to choose an easier target.

If the selected candidate is a structural boundary, SLICE06 must retain C
ownership of recovery, allocation, diagnostics, and mutable AST graphs
as defined in RECON04.

If the selected candidate is a scalar fallback, the HANDOFF must
explicitly state that no eligible structural boundary was found and
retain the structural blockers as unresolved engineering work.

---

## 24. Execution directive

**Execute C0 through C4 as a complete Factory-v2 reconnaissance ACT.**

The essential work is source and semantic analysis, not document editing.

- Recompute the live parser/AST authority inventory.
- Reconcile every historical candidate.
- Revisit PARSER01's graph/recovery blockers.
- Discover real bounded structural decisions.
- Keep C ownership of mutable parser state.
- Evaluate all candidates with the real eligibility checker.
- Rank through the frozen dimensions and explicitly authorized
  structural-priority policy.
- Mechanically select exactly one eligible winner.
- Freeze its actual ABI, oracle, RED, fixtures, mutation model, and
  production seam.
- Prove the ranking and successor contract are reproducible.
- Preserve the five production-authoritative PolyC parser components.
- Close only with mechanically truthful evidence.

**Successful outcome:** One defensible next parser self-hosting target,
with enough source-bound evidence and executable contracts for SLICE06
to begin implementation immediately without another exploratory redesign.
