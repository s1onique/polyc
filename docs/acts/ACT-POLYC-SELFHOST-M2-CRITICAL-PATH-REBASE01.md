# ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01

Factory-Version: 2
Lifecycle: AUTHORIZATION ARTIFACT — not an execution or completion report
Class: SELFHOST / M2_BOOTSTRAP / CRITICAL_PATH / AUTHORITY_GRAPH / FORECAST_REBASE
Priority: P0 — architectural rebase; measurement and quality tooling only

## 0. Mission

Replace the historical, unqualified whole-compiler ACT forecast with a
source-derived, measured M2 critical-path plan.

* Establish the smallest defensible **compiler-producing PolyC source and
  build dependency closure** (not a single linked PolyC helper).
* Distinguish **actual compiler bootstrap blockers** from **incidental
  migration work**.
* Compute an auditable dependency DAG with a corrected
  low/base/high remaining-ACT estimate.
* Select exactly **one** next ACT class / bounded bootstrap work package by
  deterministic, independently recomputable criteria.
* Do **not** implement it.

This is a **rebase**, not another broad migration census. The existing
CENSUS01 and ABI foundation artifacts are reused as historical input: their
committed bytes are independently re-read, and only the facts that
materially govern M2 are updated.

The original 355-ACT forecast is preserved exactly as historical evidence
while explicitly marked **UNQUALIFIED**.

## 0.1 Mandatory conceptual boundaries

**Authority count.** A production-linked PolyC decision site with
independent C-callsite load-bearing evidence. The entry claim is **15**,
including exactly two AArch64 FOR/INV decisions and **not** the CSET
mechanical adapter.

**M0 (hybrid).** C-rooted compiler with some compiled PolyC semantic
delegates. This is the current state.

**M1 (semantic ownership).** All in-scope compiler-semantic decisions are
PolyC-authored, with any remaining C support explicitly proved
mechanical/platform-only. C function count is **not** M1 decision count.

**M2 (first genuine self-hosted generation).** A qualified earlier
compiler produces a working next-generation compiler **from the declared
PolyC-authored compiler source set**, with source manifest,
producer/link provenance, operational compiler test, and no remaining
unaccounted C semantic authority in that in-scope source boundary.

* A C-built host-stage0/hcc compiling `.HC` subject objects is **not** M2.
* A PolyC-authored toy front end linked into the C compiler is **not** M2.

**M2-PRECURSOR.** An executable and reproducible PolyC-authored compiler
vertical slice (driver → source/lexer/parser/semantic/codegen output) with
permitted and explicitly inventoried C glue. Valuable, but **not** M2
until the M2 predicates are discharged.

**M3.** Independently produced successive compiler generations agree under a
predeclared semantic or normalized-artifact comparison, without producer
aliasing. Raw binary identity is **not** required when embedded paths or
hashes differ.

**M4.** Optional broader C retirement / portability / formalization. Not
silently in scope for M2.

## 0.2 Immutable entry expectations

Disputes are **measurements, not overrides**.

```text
EXPECTED_ENTRY_HEAD=9ba4ba5ddbbfacb10393514874c829c9f21d5ea4
EXPECTED_ENTRY_TREE=78e6c706863aea2858d1dadb850b0fc30f78d6c4
EXPECTED_BRANCH=main
EXPECTED_PREDECESSOR_VERDICT=PASS
EXPECTED_PREDECESSOR_DISPOSITION=PASS_TWO_A64_CONDITION_AUTHORITIES_WITH_CSET_ADAPTER
EXPECTED_PRODUCTION_POLYC_AUTHORITIES=15
EXPECTED_A64_BUNDLE=FOR+INV PolyC, CSET mechanical C adapter
EXPECTED_M2_STATUS=NOT_ACHIEVED
HISTORICAL_CENSUS01_M2_FORECAST_LOW_BASE_HIGH=159/355/961 (UNQUALIFIED)
HISTORICAL_OLD_FORECAST_M2_CATEGORY_SUM=290
HISTORICAL_OLD_FORECAST_M2_REPORTED_TOTAL=355
HISTORICAL_OLD_FORECAST_UNRECONCILED_DELTA=65
HISTORICAL_GRAPH_PREVIOUS_NARRATIVE=52/134/34/19
HISTORICAL_GRAPH_LATEST_TOOL_OUTPUT=52/135/34/19
GRAPH_TRUE_CURRENT_MANDATORY_EDGES=REMEASURE_REQUIRED
PRODUCTION_GRAPH_CUTS=REMEASURE_REQUIRED
M2_PRODUCER_SOURCE_SET=NOT_YET_PROVEN
NEXT_TARGET_AUTHORIZED=NO
SLICE10_AUTHORIZED=NO
```

The **134 vs 135** disagreement is **NOT** resolved by picking the newer
or the larger number. The ACT must determine whether `E-TYP-0136` is
included, excluded, historically marked cut, or actually absent from the
current production source/object graph; and must identify the exact graph
version, selected edges and configuration.

Each recorded count is preserved in its own named graph scope.
`E-MUT-0137` remains an unsupported witness unless new source/object
evidence proves otherwise. **No speculative cut or SCC improvement is a
PASS.**

## 0.3 Repository authority, entry and publication policy

`AGENTS.md`, `docs/factory/DOCTRINE.md`, `docs/factory/GIT-METADATA.md`, the
actual Factory-v2 range/trailer/closure/append-only/F14 tools, and the live
Make/CMake target rules govern the actual legal lifecycle shapes. A
contradiction between this authorization and canonical doctrine must be
**surfaced and classified**; evidence is never falsified to pass a gate.

Work is performed on the existing integration branch (`main`, which matches
the pinned entry). **No push, no fetch, no rebase, no amend, no reset, no
force-push.** No new per-ACT branch. Only disposable detached worktrees are
used for independent probes; ACT-created worktrees are cleaned at
terminality without modifying pre-existing worktrees.

### Predecessor chronology obligation

`IMPLEMENT02-CORRECTED01` committed RED, IMPL, EVIDENCE, CLOSE (four
commits) although its frozen AC50 text asked for five and the
authorization specified a C1 EVIDENCE commit. Its canonical range checker
reportedly passed.

This ACT independently establishes the literal AC50 conflict, the actual
Git trailers and the external receipt binding, and reports:

```text
CANONICAL_RANGE_STATUS
FROZEN_AC50_LITERAL_STATUS
C1_EVIDENCE_COMMIT_PRESENT
TERMINALITY_RECEIPT_BINDING
```

separately. If the missing historical phase is disallowed by doctrine and
materially blocks next authority: `HALT` with a narrowly described
governance successor. Otherwise: record a historical governance debt row
with the actual doctrine exemption. The predecessor is **not** retroactively
rewritten and a five-commit history is **not** inferred.

## 0.4 Authorized tracked scope

```text
docs/acts/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01.md
docs/factory/act-handoff-map.tsv      # exactly one append-only row
docs/ROADMAP.md                        # one bounded section appended
evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/**
tools/quality/m2-critical-path-rebase01-*.HC   # genuinely compiled PolyC tools
Makefile                               # OPTIONAL additive, fail-closed quality targets
```

Forbidden: edits to `src/**`, `tools/bootstrap/**`, existing `tests/**`,
canonical Factory/quality gates, historical ACT/HANDOFF/evidence, or current
compiler-production selectors.

No Python. No new external dependency. No platform upgrade. No production
code change. Build intermediate proof artifacts outside tracked state or in
ignored isolated build directories.

`Makefile` modification is permissible only if an additive read-only
verification target is useful and introduces no existing-target behavior
change.

## 0.5 Terminal dispositions

```text
PASS_M2_CRITICAL_PATH_REBASED
HALT_ENTRY_IDENTITY_OR_HISTORY
HALT_PREDECESSOR_GOVERNANCE_UNRESOLVED
HALT_SOURCE_OR_GENERATION_PROVENANCE
HALT_CENSUS_SCOPE_UNRECONCILED
HALT_GRAPH_VERSION_OR_EDGE_PROVENANCE
HALT_M2_BOOTSTRAP_CLOSURE_UNPROVEN
HALT_FORECAST_MODEL_UNVERIFIABLE
HALT_NEXT_BOUNDED_ACT_NOT_SELECTABLE
HALT_NEGATIVE_CONTROLS_OR_VERIFIER
HALT_CONSERVATION_OR_FACTORY
HALT_EXTERNAL_TERMINALITY
```

If M2 cannot presently be built, that is an **expected measured blocker**,
not an automatic HALT. A PASS requires an **executable, source-bound path
to M2** and a **qualified, bounded next ACT** — not an invented working
self-hosted compiler.

If evidence cannot even determine a defensible first compiler-producing
vertical slice, **HALT** instead of selecting a convenient scalar decision.

## 1. Factory-v2 lifecycle

Successful planned chain: `C0 RED → C1 EVIDENCE → C2 IMPL → C3 EVIDENCE →
C4 CLOSE`.

This ACT explicitly requires **five distinct linear commits** on PASS, even
if the canonical validator accepts shorter shapes. The C1 evidence is
committed **before** the C2 verifier implementation, ensuring the historical
frozen-source/measurement phase cannot be regenerated after conclusions.
Each commit's Factory trailers are pre-validated.

A single CLOSE carries `ACT`, `ACT-Phase: CLOSE`, `ACT-Verdict: PASS`. No
tracked commits follow. The true external read-only AC50 terminality
receipt is produced **after** CLOSE, **outside Git**, bound to exact
HEAD/TREE, never backdated, and never replaced by an ordinary compensating
commit.

For a legitimate early HALT, the actual repository doctrine for a shorter,
explicitly documented HALT lifecycle applies. Every unrun criterion is
reported `NOT_RUN` or `UNPROVEN`. Phases, receipts, experiments and
successful baseline results are never fabricated.

## 2. C0 — RED: identity, historical provenance and five adverse probes

### 2.1 Entry, original census and current authority conservation

Record real commands, UTC/local timestamps with offsets, exit codes and
relevant output SHA-256:

```sh
set -eu
git branch --show-current
git rev-parse HEAD 'HEAD^{tree}'
git status --porcelain=v1
git replace -l
git worktree list --porcelain
git log --format='%H%x09%P%x09%s%n%b' -40
```

Verify the exact pinned HEAD/TREE and the unique valid predecessor CLOSE.
Inspect the predecessor ACT authorization, HANDOFF, the four ACT commit
trailers, the committed AC ledger, and the read-only external receipt if it
is available. If the receipt cannot be read, label it **unavailable**; its
contents are never invented from a handoff claim.

Reproduce the branch's producer/source/object symbol census of all fifteen
PolyC authorities; distinguish linked symbol presence from active semantic
delegation, source-bounded decision authority, and independently executed
causal evidence. Prove FOR/INV are separate and that CSET has no exported
authority.

Freeze the actual CENSUS01 evidence at Git blob/SHA level: its 2,156
function count, 2,233 authority rows, 2,218 C authority rows, six adapters,
nine PolyC rows at the historical snapshot, 88 vendored/excluded rows (scope
to be verified), three unknowns and four header-inline unknown-bearing
symbols.

These are **historical claims pending denominator reconciliation**, not as
additive current counts. Re-derive which rows were originally reachable in
the selected build and which are still current after 15 authorities;
classify eliminated, superseded, duplicated, coarse-function,
inactive/test-only, vendored/excluded and unresolved rows by stable source
IDs. A remaining C count is **not** computed by subtracting unlike
populations.

### 2.2 Exactly five independently sensitive REDs

Freeze AC01..AC50 and NC01..NC24 before work. Execute them in isolated
copies / disposable worktrees with a genuine compiled PolyC detector plus
an independent Git/POSIX method.

Each RED must exhibit pristine PASS, adverse reason-specific failure,
restored PASS and byte-identical restoration:

| RED | Adverse input | Required reason |
|---|---|---|
| R01_HISTORY | fabricate five predecessor phases from the actual four, or falsely assert literal AC50 satisfied | `FALSE_PHASE_OR_AC50_TERMINALITY` |
| R02_GRAPH | substitute the historical 134 edge count for 135 without graph-version evidence, or claim E-TYP-0136 cut twice | `GRAPH_SCOPE_OR_CUT_CONFLATION` |
| R03_FORECAST | accept historical M2 total 355 when displayed cost columns sum to 290 without a named 65-row allocation | `FORECAST_SUM_RECONCILIATION` |
| R04_SOURCE | count `aarch64EmitCSet` as a third semantic authority, or treat a dormant C function as production-reachable | `AUTHORITY_DENOMINATOR_MISMATCH` |
| R05_BOOTSTRAP | label a GCC-built C-rooted compiler plus PolyC helper objects as a self-hosted PolyC producer | `M2_PRODUCER_SOURCE_NOT_CLOSED` |

If any detector accepts its intended adverse input, **HALT**, not a paper
PASS. Actual mutated facts and outputs are stored — not hand-authored
verdict fields.

### 2.3 Real conservation baseline

Build/reuse only provenance-qualified compiler inputs. The test-prefix
population is explicitly verified before executing `make unit-test`; known
fail-open prefix behavior is not success.

Run the parser (historical 376/376 over 90 files, ordered MD5
`b6f117eb1386ca80f81bc06226e2a741`) and direct lexers (89/89, 45/45, 23/23).

LEXER07 broad corpus has historical 15 S0 failure identities, MD5
`7ee761440de83552e751e3c3976c1683`; cross-target prefix has historical 67
failures; F-NO-PYTHON has historical 12; F-POLYC-TOOLS is historical
UNAVAILABLE.

Measure afresh when safe and affordable; otherwise report `NOT_REMEASURED`
alongside the historical identity. A known non-green is **never** labeled
PASS.

Compiler execution is **serialized** because `/tmp/holyc-asm.s` is shared;
isolated `TMPDIR` alone is not claimed to fix a hard-coded path. Hashes,
commands and the actual baseline are frozen.

**C0 gate:** exact entry and history; source/object authority census;
historical count/graph/forecast contradictions reproduced; five REDs fire;
baseline valid. A governance conflict may be recorded nonblocking only if
actual doctrine supports that classification.

## 3. C1 — EVIDENCE: freeze source-based M2 boundary before modelling

### 3.1 What does a working PolyC-authored compiler actually require?

Independently read real source, header dependencies, call sites, build/link
commands, root entry points, cross-module static data, target
runtime/prefix, type/layout/ownership/recovery surfaces. Use the production
link graph and available `.HC` sources. Modules are not invented and C
functions are not assumed to translate unchanged.

Construct `c1/m2-target-semantics.tsv` and `c1/source-closure.tsv` with
these columns:

```text
source_id,blob_oid,sha256,source_range,role,producer,reachability,
semantic_authority_id,owning_subsystem,required_at_m2,allowed_c_glue,
transitive_dependencies,abi_surface,state_lifetime,language_features,
blocking_feature_ids,validation_witness,confidence,evidence_path
```

Identify the smallest viable **compiler-producing** vertical slice covering
actual input/source reading, lexing/parsing, a minimal semantically
meaningful construct, lowering/code generation or another real compiler
output, driver argument handling, and a tested resulting compiler operation.

If the current dialect cannot express the selected slice without a C
semantic decision, name that exact blocker and either select a narrower
still compiler-producing slice or **prove that no such slice exists**.
M2-PRECURSOR is a separate milestone; M2 is not awarded for it.

Build a two-boundary manifest:

* **(A)** smallest credible precursor compiler source closure.
* **(B)** complete, explicit M2 in-scope PolyC compiler semantic source set.

For (B), every remaining C-linked object must have a source-derived
justification as mechanically permitted C/platform glue; C semantic fallback
is not silently allowed. Missing sources and irreducible cycles are marked
`OPEN` with an experiment that would resolve them.

### 3.2 Producer DAG and generation qualification

Reconstruct the actual `C-toolchain → C-rooted stage0 → current hybrid PolyC
subject compilers`, using Git source manifests, executable hashes, object
link lines, install prefixes, runtime identity and actual commands.

Classify every stage as `C_ROOTED`, `HYBRID`, `POLYC_AUTHORED_PRECURSOR`,
`POLYC_AUTHORED_COMPILER`, or `UNKNOWN`, with factual reason. Producers
compiling PolyC helper subjects are clearly distinguished from producers
compiling their own compiler source set.

Define executable gates:

* **P0** — source-bound compiler-producing precursor.
* **P1** — precursor actually compiled by an earlier qualified producer and
  runs on representative input.
* **M2** — the complete in-scope compiler source set and permitted C glue
  genuinely compiled by an earlier qualified compiler, program runs.
* **M3** — two independently produced generations converge under a frozen
  agreement rule.

These gate names are **local to this rebase**; they are not Factory phases
and not the existing G0/G1/G2/G3 labels. Each gate is classified `PROVEN`,
`UNPROVEN` or `BLOCKED` with command/output provenance.

**Production migration is not executed under this ACT.**

### 3.3 Reconcile language/runtime/build blockers against source needs

Inventory previously observed blockers by actual consequence, not anecdote:

* Initialized file-scope global changes `Main(argc,argv)` behavior
  (BB-01, also recent A64 RES-01).
* Pointer-valued ternary and Bool/I64 type-inference instability; general
  `?:` unsupported (BB-02, recent RES-04): separate unsupported grammar from
  inference/optimizer hang.
* Hard-coded shared `/tmp/holyc-asm.s` plus independently reported parallel
  Make/object race (BB-03); serialize tests rather than claiming fixed.
* No complete PolyC-authored compiler source set (BB-04).
* Conflicting duplicate `extern "c"` return types can yield a broken
  call/segfault (recent RES-02).
* Three-dimensional array unsupported (recent RES-03).
* Existing fail-open test-prefix and ARM64 scaled-index byte-load emission
  faults.

For each: exact source path, witness/producer (if available), observed vs
historical-only status, minimal compiler source whose compilation requires
it, `BLOCKS_PRECURSOR`, `BLOCKS_M2`, `BLOCKS_M3`, safe workaround (if
source-derived), and the exact regression probe needed.

**No unauthorized fix.** An unsupported feature is not assumed to block the
minimal slice if the selected PolyC compiler source does not use it.

### 3.4 Repair graph semantics and bootstrap dependencies

Recompute the graph from the live current production build and the archived
CENSUS01 graph **separately**. Reconcile 52 nodes, mandatory 134 vs 135, 34
SCCs and largest SCC 19, with named, source-backed edge differences;
distinguish `BASE_GRAPH`, `CURRENT_PRODUCTION_GRAPH`, `SHADOW_GRAPH` and
`CONTRACT_GRAPH`.

Historical raw edge types: 95 `TYPE_REPRESENTATION`, 14 `CALLBACK`, 14
`MUTABLE_STATE`, 12 `RECOVERY`, 103 `CALLS`-availability = 238 historical
rows (verify).

Header inclusion alone is `OBSERVED_LAYOUT_COUPLING`, not automatically a
mandatory atomic-migration edge. Each suspected mandatory edge is
classified `PROVEN_STATE`, `PROVEN_RECOVERY`, `PROVEN_CALLBACK`,
`LAYOUT_ONLY`, `CALL_AVAILABILITY`, `DISPROVEN` or `UNKNOWN`, with concrete
code/object evidence, potential ABI cut, cost and risk.

SCC/condensed DAGs are computed only over explicitly selected edge scopes,
with independent Tarjan/Kosaraju (or equivalent distinct) implementations
and exact node partition comparison. The same 19-component SCC is **not**
used as an unproved mandate to migrate 2,136 authority rows atomically. The
exact historical partition is preserved separately; any updated partition is
a **new evidence-versioned graph**, never a historical correction.

Graph critical path may **not** be equated with the sum of costs for all
nodes. The longest dependent chain is computed from the newly scoped DAG,
and unresolved edge cases are labelled with scenario intervals.

### 3.5 Baseline measurement package for forecasting

Reconstruct historical actual ACT sequences from **Git trailers**, not
hand-counted memory: migration implementation, reconnaissance/selection,
corrections/HALTs, ABI/shared infrastructure, bootstrap integration,
external terminality overhead.

Record `act_id`, entry/close, implemented independent authority IDs, count,
subsystem class, C/PolyC source scope, proof rounds, defects found,
correction dependencies, actual physical experiment IDs, and status.
Timestamps are **not** implied to be engineering labor hours.

Unique implementation ACTs are counted **separately** from total ACT
effort. Early HALTs are distinguished from completed implementations, and
a correction is never double-counted as a newly migrated site.

The historical forecast numbers are carried as **unqualified**, not as
corrected output:

```text
CENSUS01_M1_LOW_BASE_HIGH=154/348/948
CENSUS01_M2_LOW_BASE_HIGH=159/355/961
CENSUS01_M3_LOW_BASE_HIGH=161/358/967
CENSUS01_M4_LOW_BASE_HIGH=201/447/1208
CENSUS01_M2_DISPLAYED_COSTS=3+187+3+10+84+3=290
CENSUS01_M2_REPORTED_TOTAL=355
CENSUS01_M2_UNACCOUNTED_DELTA=65
CENSUS01_M2_CRITICAL_PATH_EQUAL_TOTAL=UNPROVEN
```

The original FA-04 throughput of 12 decision sites/implementation ACT is an
**assumption**, not demonstrated production throughput. The historical 0.44
correction rate (4/9 parser implementation history) is a **narrow cohort**,
not automatically transferrable to stateful compiler modules.

The already-migrated B-3 group is excluded, and 88 vendored, nine historical
migrated and all unknown-bearing authority rows are separately classified
before costing. Every historical-row mapping and the positive/negative
source scope proof are frozen at C1.

**C1 must be independently committed before any C2 quality-code/model
implementation.**

## 4. C2 — IMPL: implement the rebase measurement model, not compiler semantics

### 4.1 One authoritative compiled PolyC verifier plus independent witness

Create bounded `tools/quality/m2-critical-path-rebase01-verify.HC` (and
small additional `.HC` helpers only if necessary), compiled and executed by
the actual production compiler.

Its non-vacuous modes include: `SOURCE`, `PRODUCER`, `GRAPH`, `DAG`,
`FORECAST`, `ROSTER`, `SELFTEST`, `FREEZE`. Each **independently
recalculates** facts from primary source-derived rows and digests, not a
stamped `status=PASS` field.

Provide an independent POSIX/Git/awk implementation of material graph/cost
joins. No Python. Both methods must reject missing/duplicated IDs and
tampered hashes.

If PolyC dialect constraints prevent implementation, **HALT** and report
the precise source-level blocker — not a hand-authored substitute PASS.

### 4.2 Explicit bootstrap work-package DAG

Generate `c2/work-packages.tsv` with source-derived bounded work packages,
**not one row per if/switch**. Each row includes:

```text
wp_id,source_set_ids,subsystem,goal,milestone,blocking_abi_or_feature,
predecessor_wp_ids,required_gate,allowed_C_glue,owned_semantics,
smallest_runnable_witness,actual_proof_ready,low_acts,base_acts,
high_acts,cost_basis,confidence,priority,reason,next_act_class
```

Admit packages for: compiler source manifest and driver precursor,
necessary language/ABI blockers, core front-end, AST/IR/type state
transitions, codegen/object emission, producer/runtime linkage,
stage-generation qualification, shared proof infrastructure, and remaining
semantic migrations required by M2.

Prioritize the smallest end-to-end runnable compiler path that removes a
**measured** M2 blocker. A small scalar classifier is **not** promoted
solely on ease. Existing 15 authorities count as accomplished only to the
extent their real linkage/use is demonstrated.

Dependency edges are defined with source evidence. DAG acyclicity or
explicit SCC condensation, zero dangling refs, and unique membership or
justified shared infrastructure are required. Dependency transitive
reduction is applied only after preserving the full graph.

Produce both `TOTAL_EFFORT_ACTS` (work across all packages) and
`CRITICAL_PATH_ACTS` (longest dependent route to M2) by deterministic
recomputation. Parallel work opportunities are separate from critical path,
with a feasibility ceiling; total effort is **never** equated to critical
path by assumption.

For unknown costs/edges, provide scenario bounds or
`UNBOUNDED_BY_EVIDENCE` rather than arbitrary precision.

### 4.3 Forecast modelling, calibration and scenarios

Construct at least three explicitly labeled forward-looking scenarios:

* **(i)** current per-decision proof granularity;
* **(ii)** moderate whole-function/related-group migration;
* **(iii)** ambitious whole-subsystem migration.

For each compute M2 remaining total effort, M2 critical path,
correction/verification reserve, and optional later M1/M3/M4 scope
separately.

Use a consistent denominator of remaining, production-reachable in-scope
semantic authority, with distinct units for function, decision site,
subsystem and ACT. Already completed work, vendored/excluded scope,
equivalent adapters and shared ABI infrastructure are **not** double
charged. Each assumption cites either a measured cohort or a declared
judgmental range; model outputs never silently become observations.

Implement arithmetic checks: sum displayed work categories to total; check
`low <= base <= high`; `critical-path <= total effort` where comparable;
ensure every package is counted exactly once in totals; no cycles;
propagate unknowns.

Reconcile historical `355 - 290 = 65` as a **model defect**, not a
mysterious residual future work item. Historical evidence is not changed.

Report calibrated scenario outputs without claiming statistical confidence
intervals unless a defensible probability model and sample exist.

Test the **below-100-ACT hypothesis** with explicit throughput and overhead
necessary conditions; classify `SUPPORTED`, `NOT_SUPPORTED` or `UNPROVEN`.
The historical `M2_BELOW_100_ACTS=NOT_SUPPORTED` remains a historical
conclusion and may change only under new executed evidence.

Include measured sensitivity to correction rate, source closure breadth, ABI
cut success, compiler-feature blockers and semantic throughput. Update
forecast after 3 real migration bundles (future cadence only; not an
automated background task).

### 4.4 Select exactly one next ACT by executed deterministic ranking

Rank candidate successor work packages by a frozen, source-backed rubric:

* **R0** blocks earliest compiler-producing precursor;
* **R1** blocks strict M2;
* **R2** unlocks multiple dependencies / real ABI cuts;
* **R3** has directly executable regression witness;
* **R4** is bounded and safe in one ACT;
* **R5** has reusable verification.

Apply in deterministic priority order: earliest required gate first; then
unlocked dependency count; confidence; boundedness; stable ID.

The ranker input is joined from **actual verifier output**, not trusted
eligible flags. An independent second implementation reproduces eligibility,
full rank order and selected ID.

The selected successor specifies explicit `ENTRY_EXPECTATIONS`, source
functions/files, minimum test corpus, implementation/non-implementation
boundaries, ABI, predecessor packages, migration success/failure conditions
and a concrete C-only or earlier-compiler oracle where applicable.

```text
NEXT_ACT_PROPOSED=<one ID>
NEXT_TARGET_AUTHORIZED=NO
```

If no bounded source-qualified action advances the earliest bootstrap gate:
`HALT_NEXT_BOUNDED_ACT_NOT_SELECTABLE`.

### 4.5 Allowed execution probes

Run read-only / disposable bootstrap feasibility probes when possible:
compile a minimal PolyC-authored compiler component in a detached temporary
worktree, inspect genuine object provenance, exercise emitted compiler output
on representative source, then remove all temporary changes.

Each probe is recorded as `EXPERIMENT_ONLY`; no source transfer to
production and no unqualified M2 claim. If execution is impossible, mark
`NOT_RUN` with the exact blocker and select a bounded follow-up that makes
execution possible; a successful compiler-producing stage is never invented.

**C2 exit gate:** verifier compiles, independent witnesses agree, work
packages/DAG and forecasts mechanically reconcile, one bounded
source-qualified next ACT selected. Any unproven required condition is a
named HALT, not an override.

## 5. C3 — EVIDENCE: independent recomputation, adversarial controls and gates

All C1 primary data and C2 conclusions are recomputed independently
**without reading the primary model's precomputed status/rank/total
cells**. Original versus current graph versions and edge membership,
four-commit history findings, source/producer closure, package DAG, cost
totals/critical path and sensitivity are reproduced. Stable IDs, exact
source hashes, counts, labels and critical-path witness route are compared.
Require 0 missing, 0 duplicate, 0 unmatched, 0 unqualified PASS.

All 24 frozen controls execute with distinct physical IDs, pristine →
adverse → restored reason-specific detector results, and actual
byte/digest restoration. Explicitly verify the checker rejects: changing
the answer without changing source facts; counting a duplicate ACT twice; a
graph edge under the wrong version; a fabricated PolyC self-producer; an
excluded vendored function counted as remaining; a false 355=290
reconciliation.

Re-run parser/direct lexer baseline, historical failures or explicitly
labeled `NOT_REMEASURED`, gate-fast, serialized gate-push (all seven live
checks), patch hygiene, append-only, Factory-v2 range, F14 and
closure-status with a populated test-prefix.

Production `src/**`, bootstrap subjects and existing tests must be
**byte-identical** to entry. Report F14 strict and the one authorized
handoff-map append independently. No new compiler decision authorities, no
planned successor code, no M2 milestone claim.

If a newly executed bootstrap experiment happens to succeed, label it only
at the qualified gate its source/producer/semantics actually satisfy.

**At C3:** all AC01..AC49 PASS, AC50 DEFERRED; 24/24 NC sensitive; no
FAIL/UNPROVEN/NOT_RUN among mandatory C0..C3 requirements. If a claimed
precise forecast cannot be source-reproduced, choose honest
`UNBOUNDED_BY_EVIDENCE` with full gap list — or HALT if the selected
successor itself depends on an unbounded claim.

## 6. C4 — CLOSE and external terminality

Create `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01.md`
and append one bounded roadmap section. Append **exactly one** row to
`docs/factory/act-handoff-map.tsv`; the historical prefix remains
byte-identical.

Commit `c4/terminality-plan.txt` that unmistakably says **PLAN**, not an
executed post-CLOSE receipt. Verify the C0–C4 sequence, expected five
commits, one unique CLOSE and trailers.

The CLOSE carries:

```text
ACT: ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

An external read-only terminality receipt is generated **AFTER** CLOSE,
outside the repository and bound to exact terminal HEAD/TREE. It verifies 15
unchanged authorities, 0 production semantic delta, accurate bootstrap
milestone labels, full source/producer/DAG/forecast joins, all AC/NC, five
commits, no post-CLOSE continuation, no ACT-created worktrees, no replace
refs, clean index/worktree and no push.

AC50 is discharged only from the actual receipt. If it fails, report
`HALT_EXTERNAL_TERMINALITY` — no second CLOSE, no Git history rewrite, no
ordinary receipt commit.

### 6.1 Required final report keys

```text
ACT_ID, ENTRY_HEAD, ENTRY_TREE, FINAL_HEAD, FINAL_TREE, BRANCH
FACTORY_PHASE_SEQUENCE, ACT_COMMIT_COUNT, CLOSE_SHA, ACT_VERDICT, DISPOSITION
PREDECESSOR_FOUR_COMMIT_RANGE, PREDECESSOR_FROZEN_AC50_LITERAL_STATUS
PREDECESSOR_CANONICAL_RANGE_STATUS, PREDECESSOR_TERMINALITY_BINDING
PRODUCTION_POLYC_AUTHORITIES_ENTRY, PRODUCTION_POLYC_AUTHORITIES_FINAL
CSET_ADAPTER_NOT_COUNTED, NEW_PRODUCTION_AUTHORITIES, PRODUCTION_SEMANTIC_DELTA
CENSUS01_HISTORICAL_AUTHORITY_ROWS, CURRENT_RECONCILED_REMAINING_SEMANTIC_SCOPE
VENDORED_EXCLUDED_COUNT, UNKNOWN_AUTHORITY_COUNT, COARSE_SITE_UNCERTAINTY
GRAPH_HISTORICAL_BASE, GRAPH_CURRENT_PRODUCTION, GRAPH_SHADOW, GRAPH_CONTRACT
GRAPH_134_VS_135_DISPOSITION, E_TYP_0136_CURRENT_STATUS, E_MUT_0137_STATUS
SCC_CURRENT_PARTITION, BOOTSTRAP_DAG_NODES_EDGES, BOOTSTRAP_CRITICAL_PATH_WITNESS
M2_PRECURSOR_SOURCE_SET, M2_FULL_SEMANTIC_SOURCE_SET, PERMITTED_C_GLUE
GENERATION_CHAIN_IDENTITIES, EARLIEST_UNSATISFIED_BOOTSTRAP_GATE
BB_01_TO_BB_04_DISPOSITION, RES_01_TO_RES_04_DISPOSITION, NEW_BLOCKERS
HISTORICAL_355_TOTAL, HISTORICAL_290_DISPLAYED_SUM, DELTA_65_CLASSIFICATION
FORECAST_SCENARIOS, FORECAST_LOW_BASE_HIGH_OR_UNBOUNDED, TOTAL_VS_CRITICAL_PATH
FORECAST_ASSUMPTION_COHORTS, BELOW_100_HYPOTHESIS_DISPOSITION
SELECTED_NEXT_WORK_PACKAGE, NEXT_ACT_PROPOSED, NEXT_TARGET_AUTHORIZED=NO
SELFHOST_M0_STATUS, SELFHOST_M1_STATUS, SELFHOST_M2_STATUS=NOT_ACHIEVED
SELFHOST_M3_STATUS, SLICE10_AUTHORIZED=NO
NC_PASS, NC_FAIL, NC_UNPROVEN, NC_NOT_RUN
AC_PASS, AC_FAIL, AC_UNPROVEN, AC_NOT_RUN, AC_DEFERRED
PARSER_ASSERTIONS, PARSER_MD5, DIRECT_LEXERS, LEXER07_BROAD, CROSS_TARGET
F_NO_PYTHON, F_POLYC_TOOLS, GATE_FAST, GATE_PUSH, F14_STRICT
F14_AUTHORIZED_APPEND, APPEND_ONLY, FACTORY_V2, CLOSURE_STATUS
EXTERNAL_TERMINALITY, GIT_REPLACE_REFS, POST_CLOSE_ALL_COMMITS
ACT_OWNED_WORKTREES_REMAINING, WORKTREE_CLEAN, PUSH_PERFORMED=NO
```

## 7. Frozen evidence structure

```text
evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/
  c0/
    entry-identity-and-history.tsv
    predecessor-phase-ac50-audit.tsv
    predecessor-frozen-paths.tsv
    fifteen-authorities-entry.tsv
    historical-forecast-reconciliation.tsv
    graph-baseline-conflict.tsv
    five-red-executions.tsv
    parser-lexer-baseline.txt
    known-non-green-baseline.txt
    frozen-50-ac.tsv
    frozen-24-nc.tsv
  c1/
    production-link-and-source-scope.tsv
    historical-current-authority-join.tsv
    m2-target-semantics.tsv
    source-closure.tsv
    compiler-producing-precursor-vs-m2.md
    generation-producer-dag.tsv
    bootstrap-blockers.tsv
    typed-graph-versioned.tsv
    graph-edge-witnesses.tsv
    original-forecast-provenance.tsv
    historical-act-throughput.tsv
  c2/
    verifier-build-and-selftest.txt
    verified-graph-scc-dag.tsv
    work-packages.tsv
    work-package-dependencies.tsv
    forecast-assumptions.tsv
    forecast-scenarios.tsv
    forecast-sensitivity.tsv
    critical-path-proof.tsv
    bootstrap-probe-results.tsv
    ranked-next-packages.tsv
    selected-successor-contract.md
  c3/
    independent-source-and-authority-join.tsv
    independent-generation-closure.tsv
    independent-graph-and-critical-path.tsv
    independent-forecast-recomputation.tsv
    negative-controls-raw.tsv
    negative-controls-join.tsv
    verifier-selftests.tsv
    ac01-ac50-ledger.tsv
    conservation-and-known-residue.txt
    gate-fast.txt
    gate-push.txt
    factory-f14-append-only.txt
  c4/
    terminality-plan.txt
```

Additional bounded evidence files are permitted **only inside this ACT
namespace** and must be registered by a real manifest. The external
terminality receipt is **not** created under `c4/` before CLOSE.

Independent C/POSIX witness results are fine, but substantive new tools
under `tools/quality` must be compiled PolyC.

## 8. Frozen negative controls (NC01..NC24)

All controls are physically executed and require
`PRISTINE=SILENT → ADVERSE=FIRED(required_reason) → RESTORED=SILENT`, with
the actual detector command, input/output digests and source-backed reason.
A changed PASS label is **not** a qualifying adverse mutation.

| ID | Adverse input | Required detector reason |
|---|---|---|
| NC01 | Forge HEAD/TREE/branch to match an incorrect predecessor | `ENTRY_OR_PREDECESSOR_IDENTITY` |
| NC02 | Replace actual four predecessor commits with an invented five-phase chronology | `FALSE_PHASE_OR_AC50_TERMINALITY` |
| NC03 | Take an unbound external terminality receipt as proof of AC50 | `MISBOUND_EXTERNAL_TERMINALITY` |
| NC04 | Modify a frozen historical artifact or accept a bad SHA | `HISTORICAL_F14_BLOB_MISMATCH` |
| NC05 | Count CSET as the sixteenth PolyC authority | `MECHANICAL_ADAPTER_MISCOUNT` |
| NC06 | Count an inactive/unlinked C authority as production-reachable | `PRODUCTION_REACHABILITY_FALSE` |
| NC07 | Subtract excluded vendored rows twice or count historical PolyC again | `CENSUS_SCOPE_DOUBLE_COUNT` |
| NC08 | Lose a known unknown-bearing authority row from denominator | `UNKNOWN_AUTHORITY_SILENT_DROP` |
| NC09 | Replace current graph edge set with historical 134 or 135 without edge IDs | `GRAPH_VERSION_ALIAS` |
| NC10 | Claim shadow E-TYP-0136 cut as newly proven production retirement | `SHADOW_PRODUCTION_CUT_CONFLATION` |
| NC11 | Treat header inclusion alone as mandatory runtime migration dependency | `LAYOUT_OBSERVATION_AS_MANDATORY` |
| NC12 | Count availability CALLS edges as migration-order edges | `CALL_EDGE_SCOPE_CONFUSION` |
| NC13 | Drop one callback, mutable-state or recovery edge and keep graph PASS | `MANDATORY_EDGE_MISSING` |
| NC14 | Forge Tarjan/Kosaraju partition agreement when SCC member lists differ | `SCC_PARTITION_MISMATCH` |
| NC15 | Assert the C-rooted stage0 + helper objects satisfy genuine M2 | `M2_SOURCE_PRODUCER_NOT_CLOSED` |
| NC16 | Omit an actual PolyC language-feature blocker from source closure | `BOOTSTRAP_BLOCKER_OMITTED` |
| NC17 | Accept dangling, cyclic or duplicate work-package IDs as an acyclic DAG | `WORK_PACKAGE_DAG_INVALID` |
| NC18 | Make critical-path length equal all-package cost without a path witness | `CRITICAL_PATH_NOT_DERIVED` |
| NC19 | Accept the historical displayed 290 as equal to reported 355 | `FORECAST_SUM_RECONCILIATION` |
| NC20 | Introduce a missing 65 ACTs as fictional future work to force sums | `INVENTED_COST_RESIDUAL` |
| NC21 | Use assumed 12 sites/ACT as measured throughput or mix site/function units | `THROUGHPUT_PROVENANCE_OR_UNIT` |
| NC22 | Assign the same shared infrastructure/correction ACT to multiple package totals | `FORECAST_DOUBLE_CHARGE` |
| NC23 | Promote a convenient classifier ahead of a proven earliest bootstrap blocker | `RANKER_ELIGIBILITY_OR_ORDER` |
| NC24 | Forge PASS, omit/duplicate AC/NC ID or discharge AC50 before CLOSE | `AC_NC_OR_TERMINALITY_FALSE_PASS` |

## 9. Mandatory acceptance criteria (AC01..AC50)

Exactly these 50 stable IDs are frozen at C0, with physical evidence paths
and actual execution checks. For a PASS route, AC01..AC49 PASS and AC50
DEFERRED at C3; the post-CLOSE receipt changes AC50 to PASS outside the
immutable tracked ledger. There are **no** `NOT_APPLICABLE` placeholders: a
conditional exclusion needs affirmative evidence, or it is `UNPROVEN`.

| ID | Phase | Mandatory exact predicate |
|---|---|---|
| AC01 | C0 | Exact pinned HEAD/TREE/main; clean classified state, zero replace refs, no fetch/push |
| AC02 | C0 | Predecessor CLOSE and four real ACT trailers established from Git object history |
| AC03 | C0 | Literal frozen five-trailer AC50 and actual canonical range-check statuses separately classified |
| AC04 | C0 | Predecessor external receipt binding checked or honestly UNAVAILABLE, not invented |
| AC05 | C0 | All historical predecessor and CENSUS01 inputs frozen by path/OID/SHA-256 |
| AC06 | C0 | All 15 existing PolyC authorities independently production-linked and source/callsite bound |
| AC07 | C0 | CSET remains C mechanical adapter and historical 12/13/15 causal-count chronology preserved |
| AC08 | C0 | Historical source/scope census denominator and 88 excluded rows tagged for reconciliation |
| AC09 | C0 | Historical 134/135 graph disagreement reproduced with named graph versions |
| AC10 | C0 | Original M2 355 vs displayed 290 mismatch reproduced; 65 delta explicitly UNQUALIFIED |
| AC11 | C0 | Five distinct REDs are reason-sensitive and restore exact source/record bytes |
| AC12 | C0 | Real parser/direct-lexer baselines valid; known non-green statuses classified honestly |
| AC13 | C1 | Production link/source root, stage0 lineage and actual targets enumerated from commands and objects |
| AC14 | C1 | C compiler semantic decision source set and C platform-only glue boundary differentiated |
| AC15 | C1 | Minimal compiler-producing precursor source closure derived with transitive input dependencies |
| AC16 | C1 | Full strict M2 in-scope PolyC source closure and missing sources/gaps separately recorded |
| AC17 | C1 | Each precursor and M2 source row has content hash, reachability, owner and relevant blocker |
| AC18 | C1 | Actual producer DAG distinguishes C_ROOTED, HYBRID, POLYC_PRECURSOR and M2 producer |
| AC19 | C1 | M2 and M3 generation gates are executable acceptance predicates, not symbol counts |
| AC20 | C1 | BB-01..04, RES-01..04, build/ABI defects each evaluated against selected source closure |
| AC21 | C1 | All graph edge versions and E-TYP-0136/E-MUT-0137 claims assigned source/object witnesses |
| AC22 | C1 | Layout-only/call-availability separated from proven state/callback/recovery obligations |
| AC23 | C1 | Historical 52/34/19 SCC partition independently recomputed without rewriting history |
| AC24 | C1 | Real historical ACT history/throughput evidence classified by type and status, no double count |
| AC25 | C1 | C1 facts frozen in distinct EVIDENCE commit before C2 model/tool implementation |
| AC26 | C2 | New PolyC verifier compiles and selftests against source/digest/graph/forecast negative cases |
| AC27 | C2 | Independent Git/POSIX/awk witness agrees on primary source and graph facts |
| AC28 | C2 | Bootstrap work packages source-bound, complete, exact ID roster and bounded owners |
| AC29 | C2 | Work-package dependency graph acyclic after explicit SCC condensation and zero dangling IDs |
| AC30 | C2 | At least one complete precursor-to-M2 route with concrete source/producer proof obligations |
| AC31 | C2 | Total effort and critical path calculated separately with a real longest-chain witness |
| AC32 | C2 | All scenarios have unit-consistent scope, low/base/high or honest UNBOUNDED gaps |
| AC33 | C2 | Forecast categories sum exactly; no unexplained residual or double-billed work |
| AC34 | C2 | Sensitivity includes throughput, correction rate, source breadth, ABI edges and blocker costs |
| AC35 | C2 | Below-100-ACT hypothesis classified using executed evidence and necessary conditions |
| AC36 | C2 | One next package ranked source-bound and feasible, independently reproduced |
| AC37 | C2 | Selected successor contract includes entry, bounded source, build/witness and HALT conditions |
| AC38 | C2 | Any experimental precursor probe labeled EXPERIMENT_ONLY with actual producer provenance |
| AC39 | C2 | M1 full semantic-retirement and M2 compiler-generation scopes costed separately without circular prerequisites |
| AC40 | C3 | Independent source/authority join reproduces current denominator and exclusions |
| AC41 | C3 | Independent graph scopes reproduce edge sets, SCC partitions and all cut claims |
| AC42 | C3 | Independent producer closure reproduces earliest unsatisfied bootstrap generation gate |
| AC43 | C3 | Independent forecast recomputes totals, critical path and selected work package |
| AC44 | C3 | NC01..NC24 adversarial tests fire own reason and are byte-restored with no vacuity |
| AC45 | C3 | Verifier sensitivity/roster selftests reject missing, duplicate, alias and forged statuses |
| AC46 | C3 | Parser/direct lexers conserved, known failures unchanged or explicitly NOT_REMEASURED |
| AC47 | C3 | gate-fast/gate-push, patch hygiene, Factory range, F14/append-only/closure checks run honestly |
| AC48 | C3 | No production/source/bootstraps/tests changed; 15 authorities, zero new cuts claimed without proof |
| AC49 | C3 | AC01..49 PASS with AC50 explicitly DEFERRED and exact ID join |
| AC50 | C4 | Single fifth CLOSE; external read-only receipt verifies terminal HEAD/TREE and discharges AC50 |

## 10. Non-binding external methodological references

* GCC's native 3-stage bootstrap and later-stage comparison:
  <https://gcc.gnu.org/install/build.html>
* Rust compiler stage0/stage1/stage2/stage3 source/producer distinctions:
  <https://rustc-dev-guide.rust-lang.org/building/bootstrapping/what-bootstrapping-does.html>
* Git trailer parsing and detached worktrees:
  <https://git-scm.com/docs/git-interpret-trailers> and
  <https://git-scm.com/docs/git-worktree>

These sources inform methodology; they cannot override PolyC's live source,
actual producer lineage, Factory-v2 doctrine or a binding source-derived
acceptance contract. **No new self-hosting claim is authorized merely by
resemblance to GCC or Rust staging names.**

## 11. Final invariant

This ACT succeeds by producing a **defensible and independently reproduced
critical-path rebase and next bounded M2-oriented ACT**, not by migrating a
sixteenth or seventeenth decision.

Every missing compiler-producing source or unproven bootstrap dependency
remains **explicitly open**. A high-quality, bounded `UNPROVEN` is preferred
over an invented precise M2 date or ACT count.
