# ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT

**Title:** Mechanically select the next bounded, production-reachable legacy-C parser semantic slice for the third production-authoritative PolyC parser component

**Repository:** `s1onique/polyc`
**Branch:** `main`

**Class:** SELFHOST / PARSER / ATOMIC-SLICE-RECON / TARGET-SELECTION

**Priority:** P0

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02`

**Verified predecessor HEAD:** `4e001cc5c92041a65bfb31f6199a5edb0f231473`

**Prospective successor:** `ACT-POLYC-SELFHOST-PARSER-SLICE03`

---

## 0. Mission

Identify, rank, and select **exactly one bounded, production-reachable legacy-C parser semantic slice** for the next PolyC self-hosting migration.

RECON03 must advance beyond the two already migrated parser components:

```text
PARSER_PADDING_PRODUCTION_AUTHORITY           = POLYC
PARSER_CONTROL_FLOW_TOKEN_PRODUCTION_AUTHORITY = POLYC

REMAINING_PARSER_AUTHORITY = PARTIALLY_LEGACY_C
```

RECON02 selected `parseValidPostControlFlowToken`, which has now been implemented, qualified, hardened, and made production-authoritative.

RECON03 must therefore:

1. Re-inventory the actual remaining legacy-C parser semantic authorities.
2. Exclude both previously migrated parser slices.
3. Reassess the remaining candidates against actual production dependencies.
4. Discover smaller, independently bridgeable semantic sub-slices where existing whole-function boundaries are too coupled.
5. Apply the established R0-first eligibility and ranking model.
6. Select exactly one feasible migration target.
7. Freeze the successor's ABI, actual-C oracle, fixture model, RED witnesses, and production-delegation proof obligations.
8. Close with an executable successor authorization.

**No new compiler component or production delegation is implemented in RECON03.**

The objective is meaningful movement toward a self-hosted compiler, not another cycle of historical Factory prose corrections.

---

## 1. Entry identity and predecessors

### 1.1 Required entry verification

Execute:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git replace -l

git merge-base --is-ancestor \
  4e001cc5c92041a65bfb31f6199a5edb0f231473 \
  HEAD
```

Required observations:

```text
BRANCH=main
WORKTREE_CLEAN=YES
PREDECESSOR_REACHABLE=YES
GIT_REPLACE_REFS=0
```

If HEAD has advanced legitimately since the predecessor, inventory the intervening changes. The actual entry HEAD, not a historical hard-coded SHA, becomes the ACT's baseline.

Record the entry before any new tracked changes.

### 1.2 Authoritative predecessor artifacts

Read:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE02.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02.md

docs/factory/LEXER07-BASELINE-AUTHORITY.tsv

docs/factory/GIT-METADATA.md
docs/factory/DOCTRINE.md
AGENTS.md
```

Relevant predecessors establish:

- The R0 state-boundary model.
- The 13-clause eligibility conjunction.
- The historical R1..R6 ranking dimensions.
- The invalidity of the old `CalcClassSize` R0=0 classification.
- The invalidity of treating an ineligible ranking fallback as an eligible winner.
- The requirement for actual production authority, rather than shadow verification.
- The SHA-bound prospective LEXER07 baseline.
- Factory-v2 append-only commit and evidence rules.

Do not reinterpret the historical contract merely to produce a preferred winner.

---

## 2. Scope

### 2.1 Readable engineering surfaces

At minimum:

```text
src/parser.c
src/parser.h
src/prslib.c
src/prsutil.c
src/prsutil.h
src/cctrl.c
src/cctrl.h
src/ast.c
src/ast.h
src/lexer.c
src/lexer.h
src/CMakeLists.txt

tools/bootstrap/
tools/quality/

src/tests/
Makefile
```

Read other directly related files when necessary to resolve callbacks, aliases, AST layout, allocation, or recovery dependencies.

### 2.2 Authorized tracked mutations

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03.md

docs/factory/act-handoff-map.tsv

docs/ROADMAP.md

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/**
```

If the existing eligibility/ranking tools cannot mechanically express a required check, one bounded PolyC-native quality tool may be added under:

```text
tools/quality/parser-slice-recon03-*.HC
```

A corresponding Makefile target may be introduced if required.

Do not add a tool simply to reformat TSV or produce more evidence prose.

If a temporary ranker is used from ignored `build/`, preserve enough of its source, execution command, and input identities in the ACT evidence to reproduce its result after deleting `build/`.

### 2.3 Forbidden mutations

```text
src/parser.c
src/prslib.c
src/cctrl.c
src/ast.c
src/lexer.c
src/CMakeLists.txt

tools/bootstrap/**

existing closed evidence/**
existing closed HANDOFFs
existing Factory validators
pre-push hooks

---

## 3. Architectural state at entry

### 3.1 Already migrated

The following must be excluded from selection:

```text
CAND-002 CalcPadding
  AUTHORITY=POLYC
  COMPONENT=BootstrapCalcPadding
  ELIGIBILITY=ALREADY_SELFHOSTED

CAND-001 parseValidPostControlFlowToken
  AUTHORITY=POLYC
  COMPONENT=BootstrapValidPostControlFlowToken
  ELIGIBILITY=ALREADY_SELFHOSTED
```

Verify both using the live CMake configuration and actual production linkage, not merely source comments or an exported symbol.

The new control-flow-token component must remain connected to its five production caller paths.

### 3.2 Known problematic candidates

Revisit the historical classifications.

| Candidate | Previous observation | Required RECON03 analysis |
|---|---|---|
| `CalcUnionSize` | R0=0, whole-function seam rejected | Investigate a genuinely production-reachable bounded size-reduction sub-slice |
| `CalcClassSize` | R0=4, writes `AstType.offset` | Keep whole function excluded; inspect pure arithmetic sub-slices separately |
| `astIsConstTrueCond` | R0=2, AST projection | Determine minimal immutable scalar projection |
| `astStmtHasBreak` | R0=2, recursive AST | Determine if a bounded local predicate can be extracted without shadow-only authority |
| `astStmtFallsThrough` | R0=2, recursive AST | Evaluate control-flow classification boundaries |
| `asmTextHasReturn` | R0=1, unbounded AoStr | Investigate explicit byte-buffer/length semantics without hidden truncation |
| `parseFlattenAnnonymous` | R0=4, host-graph mutation | Exclude whole function; inspect independent arithmetic only if a real production use exists |
| `parseCompoundStatementInternal` | R0=5, recovery ownership | Exclude whole function; only reconsider independent semantics below its state boundary |

The table is a **recon worklist, not a shortlist with a predetermined winner**.

### 3.3 Previously overlooked candidates

Search the current parser for other semantic classifications, predicates, reductions, and state-free decisions.

Look beyond named `parse*` functions where appropriate.

Useful candidate patterns include:

```text
pure scalar classifications
token-kind or keyword predicates
bounded size/alignment calculations
integer-domain decisions
small immutable AST-property projections
bounded local control-flow classifications
```

Do not select a generic numerical helper that cannot be shown to carry compiler semantic authority in an actual production path.

---

## 4. R0 — State-boundary classification

Preserve the established definition:

| R0 | Meaning |
|---|---|
| 0 | Scalar, enum, or byte-data boundary |
| 1 | Immutable copied token/value record |
| 2 | Bounded copied semantic record |
| 3 | Opaque host handle or identity dependency |
| 4 | Host-owned mutable graph or identity-dependent mutation |
| 5 | Recovery ownership, nonlocal control transfer, or callback authority |

Eligibility normally requires:

```text
R0 <= 2
```

### Important rule

**Classify the semantic boundary, not the return type.**

A function returning `I64` is not R0=0 if it mutates AST nodes, relies on host pointer identity, or crosses an unbounded callback boundary.

A function receiving `Ast *` is not necessarily R0=4 if its complete observable semantics can be projected into a finite immutable record.

But that projection must be mechanically justified.

---

## 5. New requirement — semantic sub-slice discovery

RECON02 left only one fully eligible candidate, and that candidate has since migrated.

Merely rerunning RECON02's inventory may now produce:

```text
ELIGIBLE_COUNT=0
```

That is a useful observation but insufficient exploration for RECON03.

### 5.1 Sub-slice discovery procedure

For each ineligible legacy-C candidate:

1. Enumerate independent semantic operations inside the function.
2. Locate every read and write dependency.
3. Distinguish scalar computation from host-object traversal.
4. Identify the smallest complete semantic operation that could be independently implemented in PolyC.
5. Check that production can delegate that operation without also executing the legacy-C semantic calculation.
6. Determine whether the operation is observable in an actual compiled program.
7. Create a separate candidate identity for a legitimate sub-slice.

A sub-slice does not become eligible merely because its proposed signature accepts scalar values.

### 5.2 Requirements for a valid extracted sub-slice

```text
REAL_LEGACY_SEMANTIC_OPERATION=YES
SOURCE_ANCHORED=YES
PRODUCTION_CALL_PATH_EXISTS=YES

INPUT_PROJECTION_COMPLETE=YES
OUTPUT_PROJECTION_COMPLETE=YES

BOUNDED_DATA_REPRESENTATION=YES
HOST_IDENTITY_REQUIRED=NO
HOST_GRAPH_MUTATION=NO
NONLOCAL_RECOVERY=NO
SEMANTIC_CALLBACK=NO

POLYC_PRODUCTION_DELEGATION_FEASIBLE=YES
```

For a bounded copied sequence, document maximum size, overflow behavior, ownership, allocation, and what happens when the bound is exceeded.

An arbitrary array-size limit that changes previously accepted programs is forbidden.

### 5.3 No fake self-hosting

Reject a proposed migration if production would:

- Execute the legacy C decision first.
- Pass its answer to PolyC for confirmation.
- Link a PolyC function without calling it.
- Pass an already-computed result into a trivial PolyC identity function.
- Retain an alternative C implementation as the production authority when PolyC delegation is enabled.

The actual semantic decision must cross into PolyC.

```

No new production delegation, AST or parser recovery changes, compiler backend changes, or broad parser redesign.

No new Python or substantive non-PolyC qualification tooling.


---

## 6. C0 — AUTH / baseline freeze

### Required evidence

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c0/
  entry-identity.txt
  predecessor-binding.txt
  production-authority.tsv
  source-freeze.tsv
  baseline-authority.txt
  scope.txt
```

### C0 observations

Capture:

```text
ENTRY_HEAD
BRANCH
WORKTREE_CLEAN
GIT_REPLACE_REFS

PARSER_PADDING_AUTHORITY
PARSER_CONTROL_FLOW_TOKEN_AUTHORITY

PARSER_SOURCE_SHA256
PRSLIB_SOURCE_SHA256
CCTRL_SOURCE_SHA256
AST_SOURCE_SHA256

LEXER07_BASELINE_REGISTRY_SHA256
```

Inspect the production binary or rebuild against a clean, supported configuration when the existing binary's provenance is uncertain.

Use existing production smoke and mutation evidence as supporting authority, but do not claim a new causal proof merely from `nm`.

Commit authorization and C0 evidence with the Factory-v2 `ACT-Phase: RED` trailer.

---

## 7. C1 — Live semantic-authority inventory

### 7.1 Required inventory

Enumerate the current parser functions and candidate sub-slices.

Revisit all 17 RECON02 candidate records, including the rejected hypothetical sub-slice, and separately enumerate any newly discovered candidates.

For every row record:

```text
candidate_id
historical_candidate_id
candidate_kind

function_name
source_file
source_start
source_end
source_sha256

semantic_authority
production_reachable
already_selfhosted

production_call_sites
estimated_semantic_complexity

state_reads
state_writes
pointer_identity_dependencies

allocation_dependencies
callback_dependencies
recovery_dependencies

r0
eligibility_status
exclusion_reason
```

Use current line numbers and source identities. Old line numbers are historical anchors only.

### 7.2 State dependency matrix

For each serious candidate, classify:

```text
Cctrl reads/writes
Ast reads/writes
Lexeme reads/writes
List/Map/Vec traversal
pointer identity
arena ownership
setjmp/longjmp
diagnostic ownership
subordinate semantic callbacks
global and static state
```

Every dependency must be either classified or explicitly unresolved.

Required result:

```text
UNCLASSIFIED_STATE_DEPENDENCIES=0
```

### 7.3 Actual call-path analysis

A candidate may be logically pure yet unsuitable for production delegation.

For each candidate, capture the call graph:

```text
production caller
    -> legacy authority function
        -> candidate semantic sub-operation

---

## 8. C2 — Eligibility and selection

### 8.1 Preserve the 13-clause eligibility model

Apply the complete predicate to every candidate:

```text
01 semantic_authority == YES
02 already_selfhosted == NO
03 R0 <= 2
04 owns_setjmp == NO
05 writes_current_recovery == NO
06 requires_nonlocal_recovery == NO
07 host_graph_writes == 0
08 pointer_identity_operations == 0
09 parser_callback_count == 0
10 semantic_callback_count == 0
11 deterministic_projection == YES
12 production_delegation_feasible == YES
13 candidate_kind is runtime semantic authority
```

Do not hand-author an `eligible=YES` field that bypasses the eligibility checker.

For extracted sub-slices, the checker must evaluate the actual extracted boundary, not silently reuse the whole function's classification.

### 8.2 Ranking

Use the established frozen lexicographic dimensions:

```text
(R0, R1, R2, R3, R4, R5, R6)
```

Lower values win.

R0 remains first.

Retain the historical meanings of R1..R6; record exact provenance from the earlier ranking contract.

Tie-breaking must be deterministic and independent of TSV row order.

### 8.3 Mandatory selection controls

| Control | Expected behavior |
|---|---|
| Existing PolyC `CalcPadding` | Excluded |
| Existing PolyC `parseValidPostControlFlowToken` | Excluded |
| Whole recovery-coupled compound parser | Excluded |
| `CalcClassSize` graph mutation | Detected |
| Ineligible candidate with artificially perfect ranking | Rejected |
| Shuffled inventory | Winner unchanged |
| Winner removed | Remaining eligible candidates reranked; NONE if none remain |
| Eligibility-field mutation | Eligibility changes when the relevant clause changes |
| R0 perturbation | Ranking changes when competing eligible candidates make that possible |
| Synthetic second eligible candidate | Must pass the real eligibility checker before entering the ranking |
| Hidden callback dependency | Rejected |
| Host pointer disguised as scalar | Rejected |
| Pure but production-unreachable helper | Rejected |

Do not require a winner to change when the real eligible set has only one candidate.

Controls testing ranking behavior and controls testing eligibility behavior must remain distinct.

### 8.4 Candidate selection

Required normal outcome:

```text
SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_R0<=2

SELECTED_PRODUCTION_REACHABLE=YES
SELECTED_DELEGATION_FEASIBLE=YES

SELECTED_ABI_BOUNDED=YES
SELECTED_ORACLE_EXECUTABLE=YES
SELECTED_CAUSAL_MUTATION_FEASIBLE=YES
```

If zero eligible candidates remain after an actual sub-slice exploration:

```text
HALT_NO_SAFE_PARSER_SLICE
```

Record exactly which boundaries prevented selection and which enabling engineering operation would make progress possible.

Do not manufacture an eligible candidate to force PASS.

### 8.5 C2 evidence

```text
c2/
  eligibility-results.tsv
  eligible-candidates.tsv
  excluded-candidates.tsv

  ranked-candidates.tsv
  ranking-replay.txt
  ranking-negative-controls.txt

  selected-candidate.txt
  selected-source-freeze.tsv
  selected-abi-contract.md
  selected-production-seam.md

  fixture-partitions.tsv
  legacy-oracle-contract.md
  red-contract.md
  causal-mutation-contract.md
  successor-proof-contract.md

  required-result.txt
```

Commit C2 with `ACT-Phase: EVIDENCE`.

---

## 9. Successor ABI contract

---

## 11. RED and causal proof contract

The next implementation ACT must be able to reproduce the following REDs.

### RED-1 — Legacy semantic authority

The selected semantic decision remains in C.

### RED-2 — PolyC implementation absent

The new PolyC component has not yet implemented the selected decision.

### RED-3 — No production delegation

Production still executes the C semantic path.

### RED-4 — No qualified component evidence

No valid four-generation qualification exists for the new selected component.

### RED-5 — Production-causal sensitivity

A bounded semantic mutation of the proposed PolyC component would be observable in the compiled program once delegation is enabled.

The mutation must remain syntactically valid and link successfully.

Freeze:

```text
MUTATION_LOCATION
MUTATION_KIND
EXPECTED_AFFECTED_FIXTURE
EXPECTED_PRODUCTION_OBSERVABLE
EXPECTED_PRISTINE_RESULT
EXPECTED_MUTATED_RESULT
```

The future implementation must run:

```text
pristine component -> build/link -> execute
mutated component  -> build/link -> execute
compare semantic outputs
restore pristine
reverify pristine output
```

A failed build or missing output is not semantic divergence.

---

## 12. Four-generation successor qualification

The selected successor must be capable of the established PolyC proof model:

```text
G0 = legacy/stage0 reference
G1 = stage1 PolyC production path
G2 = independently built stage2
G3 = independently built stage3
```

The successor contract must require:

- All generation compiler identities.
- Exact build command and source identities.
- Distinct independently executed production builds.
- Six component-object pairwise comparisons.
- Six production semantic pair comparisons, where contractually applicable.
- Generation provenance checking.
- Copy-forgery rejection, including byte-identical object substitution.
- Negative control for copied seam outputs.
- Direct C-oracle differential.
- Production-causal mutation.
- Actual production authority transfer.

Do not require a mutation-specific semantic delta to count as normal-generation equivalence.

If stage0 is an intentional legacy reference, freeze the permitted stage0-versus-PolyC comparison contract explicitly.

RECON03 freezes the proof model; it does not build all four new generations.

---

## 13. C3 — Independent verification

C3 must independently recompute the C1/C2 findings using frozen inputs and the unchanged live parser source.

### 13.1 Inventory controls

```text
HISTORICAL_CANDIDATES_ACCOUNTED_FOR=ALL
NEW_CANDIDATES_ACCOUNTED_FOR=ALL

UNKNOWN_CANDIDATES=0
UNCLASSIFIED_STATE_DEPENDENCIES=0

ALREADY_SELFHOSTED_SELECTED=0
RECOVERY_COUPLED_SELECTED=0
```

Do not invent a fixed expected total of current parser helpers. Reconcile any count change with renamed, relocated, added, or removed functions.

### 13.2 Eligibility controls

Re-run the actual 13-clause checker against every candidate.

Required:

```text
ELIGIBILITY_RECOMPUTE_MATCH=YES
SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_ELIGIBLE=YES
```

### 13.3 Ranking controls

Re-run all negative controls from C2.

The final ranking and selected candidate must be byte-identical or semantically identical under a documented canonical TSV normalization.

No ranking value may be derived from an uncommitted historical script whose implementation is unavailable.

### 13.4 Production conservation

Verify there are no changes to:

```text
src/
tools/bootstrap/
src/CMakeLists.txt
```

Reconfirm both existing PolyC parser components remain production-authoritative.

### 13.5 Parser conservation

Inspect Makefile targets before running them.

Run canonical parser tests against the existing production compiler. Record actual source identities, commands, compile results, execution results, and assertions.

Use the entry snapshot as the conservation baseline.

Previously reported parser failures related to install-directory handling must not be hidden or silently relabeled PASS.

Required:

```text
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_PARSER_SEMANTIC_REGRESSIONS=0
```

If an existing failure disappears, record it as an improvement.

### 13.6 Lexer conservation

Run the canonical existing lexer qualification targets applicable to LEXER01..04, including direct differential checks.

Run the actual LEXER07 broad-corpus target:

```sh
make lexer07-broad-corpus-4-stage
```

Compare outcomes to:

```text
docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
```

Record separately:

```text
BASELINE_FAILURE_IDENTITIES
CURRENT_FAILURE_IDENTITIES

---

## 14. Mandatory acceptance criteria

| ID | Binding predicate |
|---|---|
| AC01 | Entry identity established from live HEAD |
| AC02 | Worktree clean before authorization |
| AC03 | Predecessor closure reachable |
| AC04 | Both existing parser PolyC authorities verified |
| AC05 | Both migrated candidates excluded |
| AC06 | All historical RECON02 candidates accounted for |
| AC07 | Current parser helper inventory complete |
| AC08 | Newly discovered semantic sub-slices inventoried |
| AC09 | All candidate source identities frozen |
| AC10 | State reads/writes classified |
| AC11 | AST graph coupling classified |
| AC12 | Cctrl/recovery coupling classified |
| AC13 | Callback dependencies classified |
| AC14 | Host identity dependencies classified |
| AC15 | R0 computed from real boundary rather than return type |
| AC16 | Sub-slice candidates are real legacy-C operations |
| AC17 | Sub-slice delegation is genuinely production-reachable |
| AC18 | Thirteen eligibility clauses applied mechanically |
| AC19 | Eligibility flags cannot be hand-overridden |
| AC20 | R0 remains the leading ranking dimension |
| AC21 | R1..R6 historical semantics unchanged |
| AC22 | Ineligible-favorable-rank control rejected |
| AC23 | Synthetic eligibility control genuinely falsifiable |
| AC24 | Inventory row-order perturbation does not alter selection |
| AC25 | Removal of winner handled correctly |
| AC26 | Exactly one eligible winner selected |
| AC27 | Winner has no recovery ownership |
| AC28 | Winner has no host graph writes or identity dependence |
| AC29 | Winner has no semantic callback authority |
| AC30 | Winner has deterministic bounded projection |
| AC31 | Winner's production callers identified |
| AC32 | Winner's ABI contract complete |
| AC33 | Real legacy-C oracle strategy frozen |
| AC34 | Successor fixture model complete |
| AC35 | Successor RED model reproducible |
| AC36 | Production-causal mutation plan feasible |
| AC37 | Four-generation proof contract frozen |
| AC38 | Generation provenance and copy-forgery controls required |
| AC39 | Parser conservation run, zero new failures |
| AC40 | LEXER01..04 conservation run |
| AC41 | LEXER07 prospective baseline comparison run |
| AC42 | Existing production compiler source unchanged |
| AC43 | No newly introduced F-NO-PYTHON violations |
| AC44 | No newly introduced F-POLYC-TOOLS violations |
| AC45 | F14 closed surfaces unchanged |
| AC46 | gate-fast passes |
| AC47 | gate-push passes |
| AC48 | Factory-v2 and append-only tests pass |
| AC49 | Committed-range patch hygiene clean |
| AC50 | HANDOFF and managed registry valid |
| AC51 | Exactly one successor ACT identity frozen |
| AC52 | External terminality verified after CLOSE |

AC52 remains DEFERRED until the actual CLOSE commit exists.

Do not promote a deferred, missing, or unproven AC to PASS.

---

## 15. HALT taxonomy

```text
HALT_ENTRY_INVALID
HALT_AUTHORIZATION_MISSING

HALT_INVENTORY_INCOMPLETE
HALT_UNCLASSIFIED_DEPENDENCY
HALT_ELIGIBILITY_INCONSISTENT
HALT_RANKING_INCONSISTENT

HALT_NO_SAFE_PARSER_SLICE
HALT_UNBOUNDED_PROJECTION

---

## 16. C4 — Closure

On success create:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03.md
```

The HANDOFF must contain:

1. Entry identity and baseline.
2. Current self-hosted versus legacy-C parser authority inventory.
3. Newly discovered semantic sub-slices.
4. Full eligibility results.
5. Full ranked candidate set.
6. Selected target and production call graph.
7. ABI and fixture contract.
8. RED and causal proof model.
9. Conservation outcomes and genuine residue.
10. Single successor ACT identity.

Append one managed registry row to:

```text
docs/factory/act-handoff-map.tsv
```

Update `docs/ROADMAP.md` with the selected target and its successor.

Do not modify any predecessor's closed evidence or HANDOFF.

### Closure trailer

A successful CLOSE uses a single contiguous trailer block:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

Use the live Factory-v2 validator's accepted syntax.

The HANDOFF is a human summary, not the authority for the verdict.

Do not embed a predicted SHA of the containing CLOSE commit.

### External terminality

After C4 is committed, perform read-only checks:

```sh
git status --porcelain=v1

git diff --check <ENTRY_HEAD>..HEAD

sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 HEAD

git log -1 --format='%B' |
  git interpret-trailers --parse
```

Require:

```text
FACTORY_V2_RANGE_CHECK=PASS
WORKTREE_CLEAN=YES
PATCH_HYGIENE_ERRORS=0
POST_CLOSE_CONTINUATION=NO
```

Do not add post-CLOSE evidence, whitespace cleanup, or metadata-fixup commits inside this ACT's closed namespace.

Factory v2 has no arbitrary commit-count cap. Every phase commit must be meaningful and correctly classified.

---

## 17. Required successful result

```text
ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
VERDICT=PASS

PARSER_PADDING_AUTHORITY=POLYC
PARSER_CONTROL_FLOW_TOKEN_AUTHORITY=POLYC

CURRENT_PARSER_INVENTORY=COMPLETE
LEGACY_AUTHORITY_INVENTORY=COMPLETE

NEW_ATOMIC_SLICES_CLASSIFIED=YES
UNCLASSIFIED_DEPENDENCIES=0

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_R0<=2
SELECTED_CANDIDATE_ELIGIBLE=YES

SELECTED_PRODUCTION_SEAM=FEASIBLE
SELECTED_ABI_CONTRACT=FROZEN
SELECTED_REAL_C_ORACLE=IDENTIFIED
SELECTED_RED_MODEL=REPRODUCIBLE
SELECTED_CAUSAL_PROOF=FEASIBLE

PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

NEW_PARSER_FAILURES=0
NEW_LEXER_FAILURES=0

F14=PASS
FACTORY_V2=PASS
APPEND_ONLY=PASS
PATCH_HYGIENE=PASS

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE03
```

The actual selected function, source location, ABI, fixtures, and mutation model are filled in only after mechanical C2 selection.

Do not preselect a winner.

If the inventory proves that no safe bounded parser sub-slice remains, close with the appropriate evidence-backed HALT and identify the smallest necessary enabling engineering ACT rather than inventing a candidate.

---

## 18. Execution instruction

Execute C0 through C4 as one bounded Factory-v2 ACT.

Prioritize actual parser semantic analysis, production call-graph evidence, and a credible future PolyC delegation boundary.

Do not merely create the authorization document and stop.

Do not reopen historical SLICE02 corrections, Git trailer repair, LLVM GEP01, or unrelated Factory governance work.

Do not confuse a shadow verifier with production authority.

Do not mark ineligible candidates as eligible to avoid a HALT.

Do not implement the selected component during reconnaissance.

**The purpose of RECON03 is to discover the next genuinely migratable parser semantic decision and authorize its production PolyC implementation.**

The next engineering milestone is one more production-authoritative PolyC parser component—not another documentation-only closure cycle.

HALT_HOST_GRAPH_COUPLING
HALT_CALLBACK_COUPLING
HALT_RECOVERY_COUPLING

HALT_ABI_NOT_BOUNDED
HALT_REAL_ORACLE_UNAVAILABLE
HALT_PRODUCTION_DELEGATION_NOT_FEASIBLE
HALT_CAUSAL_PROOF_NOT_FEASIBLE

HALT_CONSERVATION_REGRESSION
HALT_FACTORY_GATE_NOT_GREEN
HALT_F14_VIOLATION
HALT_SCOPE_CONTRACT_VIOLATED
HALT_MANDATORY_AC_NOT_GREEN
```

For a HALT verdict, apply the actual Factory-v2 `HALT_CLASS` and `BLOCKS_NEXT` requirements.

A legitimate HALT preserves engineering findings and identifies the blocking prerequisite.

Task complexity or crossing a session boundary is not a HALT condition.


NEW_FAILURE_IDENTITIES
REMOVED_FAILURE_IDENTITIES

BASELINE_PASS_IDENTITIES
CURRENT_PASS_IDENTITIES
```

The historical baseline and current failure set are not interchangeable.

The full broad corpus may report `STATUS=FAIL` while prospective conservation still shows zero new failures. Preserve both facts.

### 13.7 Factory gates

Run:

```sh
make gate-fast
make gate-push

sh scripts/quality/factory-v2-test.sh
sh scripts/quality/factory-append-only-test.sh

git diff --check <ENTRY_HEAD>..HEAD
```

Use the live F-NO-PYTHON and F-POLYC-TOOLS checks where applicable.

Known pre-existing violations are not new violations.

Record their actual results instead of manufacturing an all-green status.

### 13.8 C3 evidence

```text
c3/
  inventory-recomputed.tsv
  eligibility-recomputed.tsv
  ranking-recomputed.tsv

  ranking-controls.txt
  selected-target-verify.txt
  abi-contract-verify.txt
  red-contract-verify.txt
  causal-contract-verify.txt

  parser-conservation.txt
  lexer-conservation.txt
  lexer07-baseline-comparison.txt

  gate-fast.txt
  gate-push.txt
  factory-v2.txt
  append-only.txt
  f-no-python.txt
  f-polyc-tools.txt
  f14-conservation.txt
  patch-hygiene.txt

  mandatory-ac-status.tsv
  required-result.txt
```

Commit C3 with `ACT-Phase: EVIDENCE`.


Freeze the successor's actual ABI only after the target is selected.

The ABI contract must specify:

```text
POLYC_SYMBOL
INPUT_COUNT
INPUT_TYPES
OUTPUT_COUNT
OUTPUT_TYPES

INTEGER_WIDTHS
SIGNEDNESS

NULL_AND_EMPTY_BEHAVIOR
INVALID_INPUT_BEHAVIOR

BUFFER_OWNERSHIP
BUFFER_CAPACITY
ALLOCATION_OWNERSHIP

ERROR_REPORTING_OWNER
RECOVERY_OWNER
```

The ABI must not expose unchecked C host-graph identity.

For a bounded copied record or sequence, document the precise representation and failure behavior.

If the selected function currently receives `Ast *`, `Lexeme *`, `List *`, or `AoStr *`, prove that the scalar/record projection includes everything that can influence its result.

Freeze a zero-copy projection only if pointer ownership and lifetime are actually safe across the component boundary. Do not assume that because C and PolyC compile into the same address space, arbitrary object layouts are a stable ABI.

---

## 10. Legacy oracle and fixture model

### 10.1 Oracle authority

The future migration must execute the **real legacy-C semantic function** or an actual linked legacy implementation exported through a narrow test seam.

Do not accept a handwritten reimplementation as the sole oracle.

When the C function cannot be linked directly because it is static, freeze the exact adapter strategy without altering its semantics.

### 10.2 Fixture partitions

The successor contract must contain concrete partitions for:

```text
ordinary accepted inputs
ordinary rejected inputs

null/empty inputs
boundary integer values
malformed inputs

aliasing-sensitive values
sign/width boundaries
minimum and maximum record sizes

recursive or nested semantics, if applicable
```

Fixture coverage must be appropriate to the selected semantic operation.

Do not inherit the control-flow-token component's 42 fixtures merely to preserve an old number.

### 10.3 Integrity of fixtures

Freeze:

```text
EXPECTED_FIXTURE_IDS
EXPECTED_FIXTURE_COUNT
FIXTURE_SCHEMA
FIXTURE_SOURCE_SHA256
```

Require an independent witness that every mandatory fixture is actually executed.

Unknown or additional fixture rows must be rejected unless expressly authorized as metadata by a strict, unambiguous grammar.

            -> observable compiler result
```

The intended PolyC delegation must replace the actual decision.

The caller and error-reporting seam may remain C-owned where necessary.

### 7.4 Evidence

```text
c1/
  function-inventory.tsv
  candidate-inventory.tsv
  historical-to-current-map.tsv
  newly-discovered-slices.tsv

  state-read-write.tsv
  ast-coupling.tsv
  cctrl-coupling.tsv
  recovery-coupling.tsv
  callback-coupling.tsv

  production-call-sites.tsv
  semantic-projections.tsv
  boundedness-analysis.tsv

  metadata-parser-residue.txt
  required-result.txt
```

### 7.5 Fixture-parser residue probe

The previous HARDEN01-CORRECTION02 left a narrow ambiguity concerning metadata continuation recognition.

RECON03 may execute this read-only probe:

```text
42 valid canonical fixture rows
+ arbitrary KEY=VALUE row
+ indented unknown X001 row
```

Record whether the qualification parser rejects the added row.

**This probe is diagnostic, not authorization to edit the old parser.**

If it passes incorrectly:

```text
FIXTURE_METADATA_BYPASS=REPRODUCED
QUALIFICATION_RESIDUE=P1
```

Do not use that parser alone as the future successor's proof authority for adversarial fixture completeness. Specify an independent fixture-ID and row-count witness in the successor contract.

The concern must not cause RECON03 to abandon unrelated parser-semantic reconnaissance.

Commit C1 evidence with `ACT-Phase: EVIDENCE`.
