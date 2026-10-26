# ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Mechanically select the next bounded production-authoritative PolyC parser component after the completed padding migration

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / PARSER / SURFACE-RECON / TARGET-SELECTION

**Priority:** P0

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01`

**Next milestone:** Second production-authoritative PolyC parser component

---

## 1. Mission

Reconstruct the remaining legacy-C parser semantic-authority surface
following the successful migration of `CalcPadding` to
`BootstrapCalcPadding`.

Mechanically select exactly one bounded, bridgeable parser semantic slice
for the next production self-hosting migration.

The ACT must:

1. Establish current parser ownership, including the completed padding
   migration.
2. Refresh the candidate inventory from actual production code.
3. Reclassify state-boundary costs, without blindly preserving historical
   classifications.
4. Rank eligible candidates under the existing R0-first model.
5. Select exactly one migration target.
6. Freeze a bounded ABI proposal, mechanically reproducible RED, and
   successor proof contract.
7. Authorize a production migration successor ACT.

**No compiler semantic implementation is performed by this ACT.**

The result must advance compiler self-hosting, not reopen unrelated
Factory governance work.

---

## 2. Entry authority

The following historical work is authoritative as evidence, but must be
checked against the current tree:

| ACT | Relevant result |
|---|---|
| SELFHOST-PARSER01-CORRECTION01 | Whole `parseCompoundStatementInternal` migration halted due to dependency explosion |
| SELFHOST-PARSER-SLICE-RECON01 | R0 state-boundary ranking model introduced |
| SELFHOST-PARSER-PADDING01 | `BootstrapCalcPadding` component implemented and qualified |
| PARSER-PADDING01-CORRECTION01..04 | Proof and baseline governance requalification |
| PARSER-PADDING-DELEGATE01 | Production `CalcPadding` delegation implemented |
| PARSER-PADDING-DELEGATE01-CORRECTION01 | Dedicated macro and independent generation evidence qualified |
| FACTORY-V2-HALT-TRAILER-PARSER01 | Factory-v2 HALT trailer interpretation repaired |
| TOOLING-GEP01-GATE-REPAIR01 | Full pre-push GEP01 gate unblocked |

Do not reopen these ACTs merely to rewrite historical disposition prose.

The previous `PARSER-SLICE-RECON01` HANDOFF selected:

```text
CAND-002 CalcPadding
R0=0
ABI=I64 BootstrapCalcPadding(I64 offset, I64 size)
```

That component has subsequently become production-authoritative.

Therefore:

```text
CAND-002_SELECTED_AGAIN=FORBIDDEN
PARSER_PADDING_MIGRATION_STATUS=ALREADY_SELFHOSTED
```

At C0, verify the live production configuration rather than accepting that
status solely from documentation.

---

## 3. Binding engineering invariants

### 3.1 State boundary before leverage

Preserve the established ordering:

```text
1. Can authority cross the language boundary safely?
2. Can behavior be observed?
3. Can incorrect behavior be falsified?
4. Can production actually delegate?
5. What self-hosting leverage does the migration provide?
```

R0 remains the strongest ranking dimension.

### 3.2 R0 classification

| R0 | Meaning |
|---|---|
| 0 | Scalar, enum, or byte data only |
| 1 | Immutable copied token/value record |
| 2 | Bounded copied semantic record, deterministic reconstruction |
| 3 | Opaque host reference required, no host-graph mutation |
| 4 | Host-owned mutable graph or identity-dependent state |
| 5 | Recovery ownership, nonlocal control transfer, or callback authority |

Normal self-hosting eligibility requires:

```text
R0 <= 2
```

A candidate requiring R0=3..5 is excluded unless a genuinely smaller
independent semantic sub-slice can be identified and separately
classified.

### 3.3 Production authority

A PolyC component is not self-hosted merely because:

- its object is linked;
- its output matches a C implementation;
- bootstrap generations reach a fixed point;
- a shadow verifier calls it.

A production-authoritative migration requires the actual compiler path to
consume the PolyC result.

The successor proof contract must include a production-causal negative
control.

### 3.4 No historical rewriting

F14 closed evidence and HANDOFFs remain untouched.

No amendments, rebases, reset/recommit, force-push, or replacement
objects.

Historical failed predicates remain historical failures.

---

## 4. Scope

### Allowed

Read and analyze:

```text
src/parser.c
src/parser.h
src/cctrl.h
src/ast.c
src/ast.h
src/lexer.c
src/lexer.h
src/CMakeLists.txt

tools/bootstrap/*
tools/quality/parser-*
tools/quality/lexer-*

docs/factory/*
docs/acts/ACT-POLYC-SELFHOST-PARSER*
evidence/ACT-POLYC-SELFHOST-PARSER*/
```

Other directly related source files may be read when resolving a
dependency.

Allowed tracked changes:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02.md

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02.md

docs/factory/act-handoff-map.tsv

docs/ROADMAP.md

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02/**
```

Existing non-production test binaries and tools may be run.

Disposable diagnostic outputs belong in ignored build/scratch directories
and must not mutate tracked production sources.

### Forbidden

- Editing parser, lexer, backend, runtime, or CMake production sources.
- Implementing a new PolyC parser component.
- Adding a production ABI bridge.
- Introducing a new compiler build switch.
- Replacing `Ast`, `Cctrl`, `Lexeme`, `Map`, or `List` layouts.
- Changing parser recovery behavior.
- Migrating `parseStatement`, `parseDecl`, `parseExpr`, or
  `parseToplevel` wholesale.
- Modifying canonical test oracles.
- Changing Factory validators or hooks.
- Adding Python.
- Adding a substantive shell or C tool.
- Modifying closed ACT evidence or HANDOFFs.

This is reconnaissance and successor authorization only.

---

## 5. Principal hypotheses

### H1 — `parseValidPostControlFlowToken` is the leading candidate

Current location:

```text
src/parser.c:832
int parseValidPostControlFlowToken(Lexeme *tok)
```

The implementation examines:

```text
tok == NULL
tok->tk_type
tok->i64
```

It classifies whether a token may begin a statement following a
control-flow header.

Its current callers include the parser paths for `if`, `else`, `for`,
`while`, and `do/while` bodies.

A possible projected ABI is:

```c
I64 BootstrapValidPostControlFlowToken(
    I64 token_present,
    I64 token_kind,
    I64 token_value
);
```

This is a **hypothesis, not a frozen ABI**.

C1 must check all reads, value domains, type widths, error behavior, and
call sites before C2 can accept it.

Required verification:

```text
USES_RAW_LEXEME_IDENTITY=NO
MUTATES_TOKEN=NO
MUTATES_CCTRL=NO
USES_NONLOCAL_RECOVERY=NO
CALLBACK_COUNT=0
DETERMINISTIC_SCALAR_PROJECTION=YES
```

If true, R0=0 is justified despite the legacy C signature accepting
`Lexeme *`.

The PolyC ABI must not accept the raw pointer.

### H2 — `CalcClassSize` was historically underclassified

Current implementation:

```text
src/parser.c::CalcClassSize
```

Its loop contains:

```c
type->offset = offset;
```

This writes a field on an `AstType` object.

Consequently the prior R0=0 classification cannot be carried forward
without additional analysis.

C1 must distinguish:

- the actual current whole-function behavior;
- a hypothetical pure size-calculation sub-slice;
- the identity-sensitive offset-write behavior.

Do not reclassify the whole function as pure merely because its return
value is scalar.

A pure sub-slice may be independently nominated, but must have its own
candidate identity and production-delegation feasibility proof.

### H3 — `CalcUnionSize` may be a useful independent candidate

Current implementation:

```text
src/parser.c::CalcUnionSize
```

It walks field definitions and returns a maximum size.

The operation may be expressible over a bounded copied sequence of sizes.

However, the live implementation uses an `int max`, compares it with
`type->size`, and returns `u32`.

C1 must preserve exact integer promotion, signedness, empty-list
behavior, and overflow-relevant domains.

Do not assume mathematical `max()` semantics are sufficient.

### H4 — Other historical candidates remain available

Revisit:

```text
CAND-005 astIsConstTrueCond
CAND-006 astStmtHasBreak
CAND-007 astStmtFallsThrough
CAND-008 asmTextHasReturn
```

Also search for newly introduced or previously missed bounded parser
semantic primitives.

The previous eight eligible candidates are an inventory baseline, not a
mandatory final count.

---

## 6. C0 — Authorization and entry freeze

Before any new implementation:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git log -10 --format='%H %s'
```

Require a clean working tree.

Check that the latest GEP01 repair and Factory-v2 trailer repair are
reachable from HEAD.

Read the current Factory metadata rules.

Record:

```text
c0/
  entry-identity.txt
  predecessor-binding.txt
  parser-source-identities.tsv
  baseline-authority.txt
  padding-production-authority.txt
  scope.txt
```

### C0 mandatory observations

Verify in production source:

```text
HCC_USE_SELFHOST_PARSER_PADDING=ON_BY_DEFAULT
CalcPadding_DELEGATES_TO_BootstrapCalcPadding=YES
LEGACY_C_CALC_PADDING_PRODUCTION_PATH=INACTIVE
```

Check the actual CMake target and production linkage configuration.

Do not infer runtime authority from symbol presence alone. Reuse already
qualified load-bearing evidence and execute an existing production smoke
where available.

Confirm the prospective LEXER07 baseline registry:

```text
docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
```

Freeze its current Git blob and canonical baseline identity.

Commit the C0 authorization and entry evidence using the Factory-v2
`RED` phase trailer.

Do not put mutable HEAD SHA claims into the ACT body.

---

## 7. C1 — Live parser inventory

### 7.1 Function inventory

Inspect the current parser source and enumerate semantic functions and
candidate sub-slices.

At minimum, revisit all 14 candidates from `PARSER-SLICE-RECON01`.

Account for all 64 historically inspected parser helpers, with identity
mapping where names, locations, or behavior have changed.

Do not require the current number of functions to equal the historical
64. Record added, removed, merged, or renamed surfaces.

For every candidate, capture:

```text
candidate_id
function_name
source_file
source_start
source_end
candidate_kind
semantic_authority
already_selfhosted
production_call_sites
```

### 7.2 Dependency classification

For every candidate, enumerate:

```text
reads_global_state
writes_global_state

reads_cctrl
writes_cctrl

reads_ast_graph
writes_ast_graph

pointer_identity_operations
allocation_or_deallocation

owns_setjmp
writes_current_recovery
requires_nonlocal_recovery

parser_callback_count
semantic_callback_count

external_semantic_dependencies
```

Distinguish a function that reads a pointer as a container of immutable
values from a function whose behavior depends on pointer identity.

Classify all host-state dependencies. Unknowns must be resolved or cause
an explicit HALT.

### 7.3 Observable behavior

For every eligible candidate, identify:

- Exact input domains.
- Observable outputs.
- Return-value semantics.
- Side effects, if any.
- Exceptional or malformed-input behavior.
- Relevant production callers.
- Candidate fixture partitions.
- Whether the legacy implementation can serve as the actual reference
  oracle.
- Whether the production path can be made PolyC-authoritative without
  moving an entire parser state machine.

A candidate with no credible production delegation path is ineligible
regardless of its scalar signature.

### 7.4 C1 evidence

```text
c1/
  function-inventory.tsv
  candidate-inventory.tsv
  candidate-delta-vs-recon01.tsv
  dependency-map.tsv
  state-read-write.tsv
  recovery-coupling.tsv
  callback-coupling.tsv
  production-call-sites.tsv
  observable-projections.tsv
  eligibility-preconditions.tsv
  required-result.txt
```

Commit C1 as `ACT-Phase: EVIDENCE`.

No tracked compiler changes.

---

## 8. C2 — Eligibility, ranking and selection

### 8.1 Hard eligibility

A candidate is eligible only when:

```text
semantic_authority == YES
already_selfhosted == NO
r0_state_boundary_cost <= 2

owns_setjmp == NO
writes_current_recovery == NO
requires_nonlocal_recovery == NO

host_graph_writes == 0
pointer_identity_ops == 0

parser_callback_count == 0
semantic_callback_count == 0

deterministic_projection == YES

production_delegation_feasible == YES

candidate_kind != NON_SEMANTIC
candidate_kind != DEAD_OR_NONRUNTIME
```

Every exclusion must have a reason anchored to the current source.

### 8.2 Ranking

Reuse the historical lexicographic ranking:

```text
(R0, R1, R2, R3, R4, R5, R6)
```

Lower values win.

Preserve the frozen historical meanings of R1..R6. Do not invent new
weights or silently redefine an old column.

R0 is the first and strongest dimension.

If new candidates require additional discriminators, use deterministic
tie-break fields after the frozen dimensions, and document the extension
before selecting the winner.

Every ranked row must include the current source location.

### 8.3 Anti-bias controls

Mandatory controls:

| Control | Expected result |
|---|---|
| Previously migrated CalcPadding | Excluded as ALREADY_SELFHOSTED |
| Whole `parseCompoundStatementInternal` | Excluded as recovery-coupled |
| Current `CalcClassSize` graph writes | Detected, not ignored |
| R0 perturbation of provisional leader | Ranking changes appropriately |
| Remove selected candidate | Next eligible candidate wins |
| Shuffle inventory row order | Selected candidate unchanged |
| Ineligible candidate with artificially favorable R1..R6 | Still excluded |
| Opaque host handle disguised as scalar | Rejected |
| Callback dependency hidden inside helper | Rejected |

No ranking control may pass purely because an expected result was
hardcoded in a report.

### 8.4 Winner selection

Exactly one selected candidate.

If multiple candidates tie through all authorized ranking dimensions,
apply a frozen deterministic tie-break.

The selected candidate must be an actual legacy-C semantic authority, not
merely a convenient test function.

If no candidate passes the hard eligibility conjunction:

```text
HALT_NO_BRIDGEABLE_PARSER_SLICE
```

Do not select an R0=3..5 candidate just to avoid HALT.

### 8.5 C2 artifacts

```text
c2/
  eligibility-results.tsv
  ranked-candidates.tsv
  ranking-controls.txt
  selected-candidate.txt
  selected-source-freeze.tsv
  selected-abi-contract.md
  selected-fixture-model.tsv
  selected-red-model.md
  selected-proof-contract.md
  selected-production-seam.md
  required-result.txt
```

Commit C2 as `ACT-Phase: EVIDENCE`.

---

## 9. Selected candidate ABI contract

Freeze a minimal PolyC ABI for the winner.

The contract must describe:

```text
symbol_name
input_field_count
input_field_types
output_field_count
output_field_types

null_and_empty_semantics
integer_widths
signedness
value_ranges

allocation_ownership
pointer_ownership
error_semantics
```

The ABI must contain no unqualified host pointer identity.

If copied semantic records are necessary, prove that conversion and
reconstruction are deterministic and bounded.

For the provisional `parseValidPostControlFlowToken` target, explicitly
cover:

- NULL/EOF token.
- Identifier token.
- String token.
- Accepted punctuation tokens.
- Rejected punctuation tokens.
- Accepted keywords.
- Rejected keywords.
- Unknown token kinds.
- Unknown numeric payload values.
- Token kind/value combinations that are structurally valid but
  semantically rejected.

Bind all accepted token constants to their actual current lexer/header
definitions, not guessed numeric literals.

The ABI must not move diagnostic ownership or `cctrlRaiseException` into
PolyC. The production C caller retains error-reporting and recovery
ownership.

---

## 10. RED contract for successor migration

The selected candidate must have a reproducible RED demonstrating that
semantic production authority is still in C.

A successful RED model must establish:

### RED-1 — Legacy authority exists

The selected function's actual production source still implements the
semantic decision.

The witness must reference current source and live call sites.

### RED-2 — PolyC authority absent

The intended PolyC production delegate is not yet connected to the
selected production call path.

Existing unrelated PolyC helpers do not satisfy this RED.

### RED-3 — Production delegation absent

A production build with the current configuration does not execute the
proposed new PolyC component.

Do not mistake a shadow test or dead linked object for production
delegation.

### RED-4 — No qualified successor proof

The proposed successor does not yet have complete direct-differential,
independent-generation, provenance, and production-causal qualification.

This must describe actual missing evidence, not rely solely on an absent
filename.

### RED-5 — Observable causal sensitivity

Freeze a feasible mutation that changes a bounded candidate decision
without causing an unrelated compile or link failure.

The successor must later:

```text
build pristine subject
build mutated subject
link both successfully
run both on identical fixtures
observe a semantic difference
restore pristine subject
reverify pristine behavior
```

At reconnaissance time, freeze the mutation location, expected affected
fixture, and observability path. Do not implement the PolyC subject yet.

Required result:

```text
RED_MODEL_COMPLETE=YES
RED_MODEL_REPRODUCIBLE=YES
PRODUCTION_AUTHORITY_LEGACY_C=YES
```

---

## 11. Successor proof model

Freeze the following requirements for the future production migration ACT.

| Proof dimension | Requirement |
|---|---|
| Legacy reference | Execute the actual C implementation, not a handwritten substitute |
| Direct differential | Compare C authority against PolyC implementation |
| Fixture coverage | Normal, boundary, negative and malformed inputs |
| Component fixed point | Four generations and all six pairwise comparisons |
| Generation provenance | Actual compiler, input, object and output identities |
| Generation-copy control | Forged provenance rejected even for byte-equal objects |
| Production delegation | Real compiler consumes PolyC result |
| Production causal mutation | Mutated component produces observable divergence |
| Legacy authority retirement | No independent C semantic calculation on enabled production path |
| Parser conservation | Current canonical parser tests actually executed |
| Lexer conservation | Current canonical lexer tests actually executed |
| LEXER07 | Compare to the prospective SHA-bound baseline |
| F14 | Closed artifacts unchanged |
| F-POLYC-TOOLS | New substantive tooling is PolyC |
| F-NO-PYTHON | No new Python source or invocation |
| Factory gates | Unmodified required gates execute |

No all-green-by-construction claims.

Fixed-point equality demonstrates reproducibility, not semantic
correctness.

Production-causal testing is mandatory.

For an intentional stage0→stage1 migration, freeze whether stage0 is the
legacy control and whether stage1..stage3 are expected to match exactly.
Do not silently substitute migration deltas for required equality
assertions.

---

## 12. C3 — Independent verification

C3 must recompute the inventory, eligibility, and ranking from the frozen
C1/C2 artifacts and current unchanged production source.

### Structural checks

Verify:

```text
UNKNOWN_CANDIDATES=0
UNCLASSIFIED_STATE_DEPENDENCIES=0
RANKING_INCONSISTENCIES=0
ELIGIBLE_ALREADY_SELFHOSTED=0

SELECTED_CANDIDATE_COUNT=1
SELECTED_R0<=2

SELECTED_RECOVERY_COUPLING=0
SELECTED_HOST_GRAPH_WRITES=0
SELECTED_CALLBACKS=0
```

### Ranking checks

Recalculate the lexicographic order independently.

Run the ranking negative controls.

Verify the chosen candidate is the unique authorized winner.

### Source purity

Check:

```sh
git diff --name-only <ENTRY>..HEAD -- src/
git diff --name-only <ENTRY>..HEAD -- tools/bootstrap/
git diff --name-only <ENTRY>..HEAD -- src/CMakeLists.txt
```

All must be empty.

### Conservation

Execute the current canonical parser tests and lexer tests using their
existing Makefile targets.

Record actual command, return code, and output. Inspect Makefile to
select the live targets rather than relying on historical command names.

Rerun the LEXER07 corpus against the prospective baseline registry.

Record known baseline failures separately from newly introduced failures.
Do not relabel a failed full corpus as `STATUS=PASS` merely because the
failure set is known.

The relevant forward-conservation predicate is that the candidate
selection introduces no new compiler behavior or regression against the
frozen comparison baseline.

Run the unmodified full push gate where the required local toolchain is
available.

If a gate fails, preserve its exact result and classify it. Do not
silently waive it.

### Factory checks

```sh
make gate-fast
bash scripts/quality/factory-v2-test.sh
bash scripts/quality/factory-append-only-test.sh

git diff --check <ENTRY>..HEAD
```

Use the live no-Python and shell-budget checkers where applicable.
Record baseline violations separately from newly introduced ones.

### C3 evidence

```text
c3/
  inventory-recomputed.tsv
  eligibility-recomputed.tsv
  ranking-recomputed.tsv
  ranking-controls.txt

  selected-source-identity.txt
  selected-abi-check.txt
  selected-red-check.txt
  selected-proof-check.txt

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

Commit C3 as `ACT-Phase: EVIDENCE`.

---

## 13. Mandatory acceptance criteria

| AC | Predicate |
|---|---|
| AC01 | Actual entry identity captured |
| AC02 | C0 authorization precedes execution |
| AC03 | Production padding authority verified as PolyC |
| AC04 | All historically inventoried candidates revisited |
| AC05 | Current parser helper inventory complete |
| AC06 | All current candidate source identities recorded |
| AC07 | All state reads and writes classified |
| AC08 | Recovery dependencies classified |
| AC09 | Callback dependencies classified |
| AC10 | Pointer-identity dependencies classified |
| AC11 | Host-graph mutations classified |
| AC12 | `CalcClassSize` previous R0 classification independently checked |
| AC13 | Already-selfhosted candidates excluded |
| AC14 | Whole compound parser function excluded under R0 rules |
| AC15 | Eligibility conjunction applied without override |
| AC16 | R0 remains the first ranking dimension |
| AC17 | R1..R6 historical meanings preserved |
| AC18 | All candidates ranked deterministically |
| AC19 | Inventory row-order perturbation has no effect |
| AC20 | R0 ranking perturbation detected |
| AC21 | Removing winner changes selection correctly |
| AC22 | Ineligible-favorable-rank control rejected |
| AC23 | Exactly one candidate selected |
| AC24 | Selected candidate R0 ≤ 2 |
| AC25 | Selected candidate has no recovery ownership |
| AC26 | Selected candidate has no host-graph identity dependency |
| AC27 | Selected candidate has no semantic callback authority |
| AC28 | Selected behavior has deterministic observable projection |
| AC29 | Selected production callers identified |
| AC30 | Selected PolyC ABI shape complete |
| AC31 | Selected legacy C oracle identified |
| AC32 | Selected RED model mechanically reproducible |
| AC33 | Production delegation is demonstrably feasible |
| AC34 | Causal mutation plan is load-bearing |
| AC35 | Four-generation qualification model complete |
| AC36 | Generation provenance and copy-forgery controls required |
| AC37 | Current parser conservation actually run |
| AC38 | Current lexer conservation actually run |
| AC39 | LEXER07 prospective baseline comparison executed |
| AC40 | Full required Factory gates run |
| AC41 | Production semantic source delta = 0 |
| AC42 | New non-PolyC substantive tooling = 0 |
| AC43 | New Python sources/invocations = 0 |
| AC44 | Closed evidence and HANDOFF delta = 0 |
| AC45 | Patch hygiene clean |
| AC46 | Append-only history preserved |
| AC47 | Single successor ACT identity recorded |
| AC48 | HANDOFF does not claim containing commit SHA |
| AC49 | Closure verdict agrees with actual evidence |
| AC50 | External terminality check runs after CLOSE |

AC50 must remain deferred until a committed CLOSE exists.

Do not promote a deferred or unproven AC to PASS in C3.

An AC ledger must link each predicate to the actual establishing evidence.
A file merely containing `STATUS=PASS` is not sufficient.

---

## 14. Halt conditions

The executor must HALT on:

```text
HALT_ENTRY_DIRTY
HALT_AUTHORIZATION_MISSING

HALT_INVENTORY_INCOMPLETE
HALT_UNCLASSIFIED_COUPLING
HALT_ELIGIBILITY_INCONSISTENT
HALT_RANKING_INCONSISTENT

HALT_NO_BRIDGEABLE_PARSER_SLICE

HALT_SELECTED_RECOVERY_COUPLED
HALT_SELECTED_GRAPH_COUPLED
HALT_SELECTED_CALLBACK_COUPLED
HALT_SELECTED_PROJECTION_UNSTABLE

HALT_ABI_NOT_BOUNDED
HALT_PRODUCTION_SEAM_NOT_FEASIBLE
HALT_CAUSAL_CONTROL_NOT_FEASIBLE
HALT_PROOF_MODEL_INCOMPLETE

HALT_CONSERVATION_REGRESSION
HALT_FACTORY_GATE_NOT_GREEN
HALT_F14_VIOLATION
HALT_SCOPE_CONTRACT_VIOLATED
HALT_MANDATORY_AC_NOT_GREEN
```

HALT must carry the correct Factory-v2 classification:

```text
HALT_CLASS: <authorized class>
BLOCKS_NEXT: YES|NO
```

Follow the canonical Factory mechanical-blocking decision table.

A legitimate HALT is an execution outcome, not permission to silently
expand scope.

**Task complexity, long execution, or a session boundary are not HALT
conditions.**

---

## 15. C4 — CLOSE

Create:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02.md
```

Append one managed ACT/HANDOFF row where required by the current Factory
oracle.

Update the roadmap with the selected candidate and successor identity.

The HANDOFF must include:

1. Current parser self-hosting authority inventory.
2. Historical-vs-current candidate differences.
3. Full eligibility and ranking result.
4. Exactly one selected target.
5. ABI proposal and evidence.
6. Frozen RED and proof model.
7. Conservation and Factory gate results.
8. Explicit residue.
9. Next ACT.

The HANDOFF is descriptive. The authoritative verdict is the C4 commit
trailer.

If all criteria are met:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
ACT-Phase: CLOSE
ACT-Verdict: PASS_TRUE_GREEN
```

Do not insert `FINAL_HEAD` or a predicted CLOSE SHA into the containing
HANDOFF.

### External terminality

After C4 is committed, run read-only checks:

```sh
bash scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02 HEAD

git status --porcelain=v1
git diff --check <ENTRY>..HEAD
git rev-list --count <ENTRY>..HEAD
```

Confirm the range is contiguous and its CLOSE is terminal.

Factory v2 has no arbitrary commit-count cap; phase commits must be
meaningful and honestly classified.

Do not produce a post-C4 cleanup commit with this ACT identity.

---

## 16. Expected result

The preferred successful result is:

```text
VERDICT=PASS_TRUE_GREEN

PARSER_PADDING_PRODUCTION_AUTHORITY=POLYC
PARSER_SLICE_RECON02_INVENTORY=COMPLETE
PARSER_SLICE_RECON02_ELIGIBILITY=COMPLETE

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_R0<=2

SELECTED_ABI_CONTRACT=FROZEN
SELECTED_RED_MODEL=REPRODUCIBLE
SELECTED_PROOF_MODEL=COMPLETE
SELECTED_PRODUCTION_SEAM=FEASIBLE

PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE02
```

The selected candidate name, symbol, source location, and ABI are filled
in only after C2 selection.

If `parseValidPostControlFlowToken` wins, the successor's suggested
descriptive title is:

`ACT-POLYC-SELFHOST-PARSER-CONTROL-FLOW-TOKEN01`

The canonical next ACT ID should be fixed once, in C2, and repeated
unchanged at closure.

---

## 17. Execution instruction

Execute C0 through C4 as one bounded Factory-v2 ACT.

Do not merely write the authorization document and stop.

Do not substitute a narrative ranking for mechanical evidence.

Do not preselect the expected winner.

Do not implement the chosen PolyC component during reconnaissance.

Do not touch historical bootstrap, padding, or Factory evidence to
improve its prose.

When the C1 and C2 gates pass, continue executing the next authorized
phase in the same session.

If the ACT genuinely HALTs, report the binding failing predicate and
preserve its evidence. Do not automatically open a correction ACT.

**The objective is to select and authorize the next real compiler
self-hosting migration.**
