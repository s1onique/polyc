# ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / ABI_FOUNDATION / OWNERSHIP / EXECUTABLE_RECON / GRAPH_CUT
**Priority:** P0
**Repository:** `s1onique/polyc` (canonical local checkout; remote availability is not presumed)
**Branch:** existing `main`; no ceremonial per-ACT branch
**Expected ENTRY_HEAD:** `facadfc29bd5284568b6fc1d5c9f96c07e82a07c`
**Expected ENTRY_TREE:** `d778bbe13d913134f76efcb643dd75491df31222`
**Binding predecessor:** `ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01` — reported CLOSE/PASS, `PASS_CENSUS_AND_ROADMAP`
**Existing active PolyC compiler decision sites:** 9 (reverified at C0)
**New production semantic authorities authorized:** 0
**Tracked production semantic delta:** 0
**Next migration target:** NONE; this ACT cannot authorize SLICE10, RECON09 or a migration bundle.

---

## 0. Mission and scope of proof

Determine whether the actual PolyC dialect can call a bounded C-owned state API
through a real compiled PolyC object, without embedding C layouts or taking over
storage ownership, and determine which specific, measured whole-compiler
dependency edges such an interface could cut.

The named state families are `AoStr`, `List`, `Map`, `Ast`, `Cctrl` and `Arena`.
The result is a frozen ABI / ownership / recovery contract, a real
object-linked non-production executable probe, and a counterfactual graph delta
grounded in individual source/edge witnesses. It is not a production migration
and not a claim of M1/M2 self-hosting.

The CENSUS01 handoff records 2,156 source functions, 2,233 authority rows
(2,218 C decisions, 6 C mechanical adapters and 9 PolyC decisions), 52 graph
nodes, 34 SCCs, and a mandatory-edge SCC containing 19 of 20 compiler
subsystems. Those values are entry baselines to verify, not constants to copy
into a new proof. CENSUS01's `M2 = 159/355/961` ACT estimate remains a
historical scenario, not a calibrated promise; no arbitrary forecast reduction
is permitted.

### 0.1 Questions that must be answered

1. Can the current compiler express a stable C host -> compiled PolyC -> C host
   ABI with genuinely opaque state handles and checked result/status codes?
2. Which handle representation actually works on the production target? Do not
   assume an integer is a pointer, that pointers can be freely cast, or that
   `Bool` and `I64` are interchangeable.
3. Which party owns allocation, retention, borrowing, invalidation, mutation,
   callbacks, diagnostics and recovery? What happens on null, stale,
   wrong-kind, out-of-range and post-release handles?
4. Can a real AST-aware read and a real container/state mutation be driven
   through this boundary using production types, rather than toy duplicates?
5. Does any source-identified type/state/callback/recovery dependency cease to
   require shared structure representation under the proven API? Which edges
   are only candidate cuts pending a migration?
6. After replacing only proved edges with ABI dependencies, how do the
   mandatory SCC partition and the migration-critical bundles change?
7. What new work does this enable, and which dialect and bootstrap blockers
   remain unaddressed?

### 0.2 Non-goals

No AST rewrite, parser slice, active component selector, compiler source
change, canonical gate/checker modification, permanent runtime/ABI
installation, CMake change, new compiler generation, or self-hosting milestone
claim. No modification of CENSUS01 history, including its known
forecast/scope defects. No claim that the entire 19-subsystem SCC is
migration-inseparable merely because it is cyclic under today's C headers.

---

## 1. Binding entry and predecessor checks (C0)

Read the committed local bytes, not only this prompt or a digest:

1. `AGENTS.md`, `docs/factory/DOCTRINE.md` (including governance/HALT
   classification), `docs/factory/ACT-TEMPLATE.md`, Factory-v2
   trailers/range/append-only/F14/closure policy, canonical roadmap/handoff map
   and actual available validation targets.
2. CENSUS01 C0–C4 ACT/HANDOFF and
   `evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/**`.
3. The actual CENSUS01 CLOSE/PASS five-commit chain, frozen hashes, current
   HEAD/TREE, current main, clean index/worktree, zero Git replace refs and
   absence of post-CLOSE changes. No reset/amend/rebase/replay to manufacture
   entry matching.
4. All nine active production PolyC authorities from selector, subject object
   symbol, C caller import, actual link and caller relocation evidence.
5. Live C definitions and actual uses of `AoStr`, `List`, `Map`, `Ast`,
   `Cctrl`, `Arena`; exact declarations, typedef aliases, lifetime and callback
   ownership.
6. The actual stage0 producer separately from production. Prefer a fresh
   producer with measured digest/configuration when feasible.

### 1.1 Historical-accuracy audit (mandatory, bounded)

A read-only predecessor-integrity and modeling audit with exact local Git
blobs:

* compare the actual permitted CENSUS01 scope with the currently tracked
  `tools/quality/tl-tmp.HC` and `tools/quality/tn-tmp.HC` paths;
* distinguish B-1 C authorities from six C mechanical adapters, check whether
  B-2 includes the vendored line editor and whether B-3 charges for nine
  already migrated PolyC authorities;
* reproduce the malformed `ONE_DECISION_PER_ACT` scenario row and the
  unsupported claim that critical-path length equals summed ACT effort;
* check graph edge typing: a C `#include` or type name alone is evidence of
  current structural coupling, not proof that two compiler implementations
  must migrate atomically. Record `OBSERVED_LAYOUT_COUPLING` separately from a
  proved migration-order constraint.

This audit is not a retroactive correction of CENSUS01. If doctrine classifies
an issue as an active production/Factory blocker, HALT with exact reason. If it
is historical/nonblocking governance or forecast debt, proceed, record the
facts in this ACT's evidence/HANDOFF, and recommend a separate bounded
correction; never claim the original file was compliant.

### 1.2 Frozen conservation baseline

Freshly measure C0 and C3, comparing exact failure identities and provenance:

| Dimension | Historical baseline to verify | Required interpretation |
|---|---|---|
| Parser | 376/376 over 90 files; assertion-sequence MD5 `b6f117eb1386ca80f81bc06226e2a741` | Exact identity; no new failures |
| Direct lexer | 89/89, 45/45, 23/23 | Execute and preserve all three |
| LEXER07 broad | `FAIL_KNOWN_BASELINE`; 15 identities; MD5 `7ee761440de83552e751e3c3976c1683` | Known FAIL remains FAIL; REGRESSION=0, DIVERGED=0 |
| Cross-target | `FAIL_ENVIRONMENT_PREFIX`, 67 missing-prefix cases | Keep status honest |
| F-NO-PYTHON | FAIL, exactly 12 historical violations | Zero new, never relabel PASS |
| F-POLYC-TOOLS | UNAVAILABLE (checker not landed) | Never invent PASS |
| gate-fast / gate-push | PASS | Fresh execution, serialized |
| Factory-v2 / F14 / append-only | PASS | Exact local validators, predecessor freeze |

Use a fresh corpus output directory. Explicitly set a valid `TMPDIR` and
preserve failed environment attempts. Serialize all compiler/JIT/AOT/gate
activity, including tests in detached worktrees, owing to `/tmp/holyc-asm.s`.

---

## 2. Permitted tracked scope

```text
docs/acts/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01.md
docs/factory/act-handoff-map.tsv                 # one new mapping row
docs/ROADMAP.md                                  # one bounded additive section
evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/**
tools/quality/abi-foundation-recon01-*.HC         # new substantive PolyC verifier/probe coordinator
Makefile                                         # only additive, isolated `abi-foundation-recon01-*` targets
```

Conditional path: if repository doctrine requires a tracked C probe or C ABI
header, its only permitted location is under this ACT's new evidence namespace;
use it solely for detached, off-production test builds. Do not install it into
`src/`, the production include tree or any real compiler target. If the test
harness cannot be built from that namespace, HALT rather than broadening scope
silently.

**Forbidden tracked edits:** `src/**`, `tools/bootstrap/**`, pre-existing
quality tools, `src/CMakeLists.txt`, existing gate/CI scripts, canonical
checker/ranker, tests outside this ACT evidence namespace, runtime headers,
compiler/toolchain dependencies, `.githooks`, existing
ACTs/HANDOFFs/evidence, and production-active build selector definitions.

New substantive verifier and probe logic must be PolyC where the dialect
supports it; C is allowed only as a bounded fixture host using real types and
ownership APIs, not as a second source of compiler decisions. A short
shell/`awk` carrier may run tools and collect raw evidence. No Python, no new
dependencies, no large shell orchestration or self-reporting verifier that
always returns PASS.

Use the existing main checkout. For mutations and object linkage experiments
use temporary directories or a detached Git worktree; do not push and remove
ACT-created worktrees before CLOSE. Never modify the authoritative source tree
for experiments.


---

## 3. Five-phase Factory-v2 execution contract

### C0 — RED: entry, freeze, baseline, executable feasibility questions

Freeze AC01..AC50 and AB-EN-01..AB-PV-02 control contracts before implementing
the solution. Use new stable IDs and exact expected detectors. Run and commit
substantive RED observations:

1. Baseline: nine PolyC decisions are active, but no production PolyC
   component owns or directly manipulates a C `Ast` / `List` / `Cctrl` object
   through a proved generic opaque-handle ABI. Discover any counterexample in
   the real tree and record it; do not assert absence without scanning.
2. Capture the 19-subsystem mandatory SCC and the actual edge witnesses (blob,
   line/range, object/configuration, edge type). State how many are based only
   on C headers/shared layouts and how many require runtime state semantics.
3. Show that the existing scalar-only parser components cannot be used as proof
   of shared-state ownership/borrow/recovery semantics.
4. Reproduce a real dialect/FFI uncertainty (opaque handle representation,
   pointer/`I64` ABI or cross-language call) with a small compile/link probe;
   if the originally predicted failure is not present, capture the actual
   measured behavior instead.
5. Reproduce at least one negative wrong-ownership or stale-handle case in an
   isolated C fixture (it must be rejected by the intended check, not a
   process-crashing anecdote). These are C0 RED witnesses, not substitutes for
   the C3 controls.
6. Capture bounded historical scope and forecast discrepancies from §1.1,
   clearly classifying each as blocker or governance/modeling debt.

Artifacts: `c0/entry-identity.txt`, `c0/predecessor-freeze.tsv`,
`c0/nine-authorities.tsv`, `c0/baselines.txt`, `c0/five-reds.tsv`,
`c0/frozen-50-ac.tsv`, `c0/frozen-24-controls.tsv`,
`c0/census01-integrity-audit.tsv`, `c0/initial-abi-feasibility.txt`.

Commit C0 with valid Factory-v2 `ACT` and `ACT-Phase: RED` trailers, validated
before commit.

### C1 — EVIDENCE: derive the actual ABI problem and choose the minimum boundary

Inventory each of `AoStr`, `List`, `Map`, `Ast`, `Cctrl`, `Arena` from real
source bytes, including declaration/definition provenance, allocation and
deallocation owners, aliases, transitive containment, mutability, callbacks,
invalidation triggers, error and recovery modes, and cross-subsystem users.
Every asserted property must reference actual source ranges and/or actual
object symbols.

For every family classify the proposed handle:

* `OPAQUE_BORROW`: usable only while the C host guarantees lifetime; no
  retention and no dereference in PolyC.
* `OPAQUE_OWNED`: explicit host-side retain/release with exactly-once lifetime
  proof, only if ownership transfer is supported by existing C semantics.
* `NO_HANDLE_YET`: source or dialect requirements are unproven; assign a
  blocker instead of fabricating an interface.

The representation (typed opaque pointer, index+generation table, or another
checked token) must be selected after object-level ABI experiments. A numeric
`I64` is not a portable pointer by assertion. If tokens can be forged, the host
must validate kind, generation, ownership domain and lifetime before touching
state; no raw C object address may be dereferenced or arithmetically
manipulated in PolyC.

Define and test an operation/result contract including all of: null,
wrong-kind, stale generation, released handle, aliasing, zero-length,
out-of-range, mutation while borrowed, callback reentrancy, recovery/error
propagation, and ordinary valid operations. Publicly exposed signatures must
have stable widths, signedness, calling convention, return-value/error
discipline and documented target assumptions; validate from real C and PolyC
compiled objects.

Required real-source-derived candidate operations (the actual names/signatures
are determined by the investigation, not predeclared here):

1. Read-only AST operation on a C-owned `Ast` value, potentially using
   `AoStr`/`Arena` during its real lifetime. The PolyC component must make an
   observable, source-bound decision based on host accessor results.
2. Container mutation operation on C-owned `List` or `Map`, or an actual
   container object reachable from `Ast`/`Cctrl`, with the PolyC component
   choosing an operation and the host applying it. Require before/after values
   and failure atomicity.
3. Recovery boundary: establish whether a host-side `Cctrl` error can be
   reported via a status/result channel without `longjmp` crossing active PolyC
   stack frames. If not currently possible, `NO_HANDLE_YET`/`BLOCKED` with
   exact failure.
4. Arena lifetime witness: demonstrate invalidation, borrow expiry or a proved
   host-managed lifetime that will not outlive its arena; never silently
   pretend arena-owned AST survives arena teardown.

At least one AST read and one stateful container mutation must be selected for
genuine C2 linkage experiments. They must be built using real production C
definitions and non-production object copies or fixture hosts, never parallel
fake structs.

Artifacts: `c1/type-family-inventory.tsv`, `c1/real-layout-and-lifetime.tsv`,
`c1/operation-candidates.tsv`, `c1/abi-representations.tsv`,
`c1/ownership-state-machine.tsv`, `c1/callback-recovery-analysis.tsv`,
`c1/dialect-ffi-probes.tsv`, `c1/mandatory-edge-witnesses.tsv`,
`c1/selected-probes.md`.

Commit C1 (`ACT-Phase: EVIDENCE`). Do not publish a verdict or cut a graph edge
merely because a candidate interface has been sketched.


### C2 — IMPL: real isolated ABI proof and counterfactual graph cuts

Implement non-production C host fixtures and a PolyC-compiled probe, within the
permitted paths. A qualified execution must record the complete chain:

```text
real C source definitions + host adapter object
       |
       | C-owned typed state + checked handle table / opaque token
       v
compiled PolyC probe object (real hcc producer identity, source digest)
       |
       | status/result + C function symbol call/relocation
       v
real C host accessor/mutator object -> observed AST/container state
```

For each of the AST-read and container-mutation probes require:

* actual compiler-produced PolyC object and exact producer executable digest,
  source digest and flags; no handwritten pretend PolyC object;
* actual C fixture object referencing genuine library/compiler definitions
  (with provenance), not mirror structs;
* link closure showing PolyC -> C host imports (or the actual supported
  equivalent), no unresolved target and no duplicate definition;
* a real executable using both the compiled PolyC object and real host object,
  with pristine behavioral oracle and typed result verification;
* correct handle-kind validation, lifetime checks, source/destination
  ownership, invalidation and failure atomicity, with distinct adverse tests;
* a causal PolyC-source mutation (only the selected probe behavior changed),
  successfully rebuilt and linked, with an externally observable result
  different from pristine; restoring source and object yields byte-identical
  input/output;
* an independent C-only host reference witness over the same operations, not
  merely an expected value hardcoded into the PolyC test.

Recovery: no `setjmp`/`longjmp` crossing PolyC frames, including in negative
tests. Translate host failures to status outside the PolyC frame, or mark the
recovery contract unproven. A trap/segfault is not a successful
negative-control detector.

Graph counterfactual: For each candidate removable
`TYPE_REPRESENTATION` / `CALLBACK` / `MUTABLE_STATE` / `RECOVERY` edge:

* preserve its original edge ID, source hash, evidence, owner and reason;
* mark `CUT_PROVEN_BY_EXECUTION` only if a source-representative consumer was
  actually recompiled against the bounded interface with direct C layout/state
  dependence removed, and the C host remained accountable for the dependency;
* mark `CUT_CANDIDATE_NOT_PROVEN` for a demo that shows possible API
  expressibility but not a source-representative edge replacement;
* mark `NOT_CUT` for all other edges, including all unidentified, callback and
  recovery edges without executed proof;
* do not turn ordinary `CALLS` availability edges into mandatory migration
  edges.

Run Tarjan on the original mandatory graph and on the proved-cut-only graph;
have a distinct verifier independently recompute the SCC partition (e.g.
Kosaraju), verify edge diff by original IDs, and prohibit manual deletion of
difficult edges. If no cut is proven, report `SCC_UNCHANGED` and still preserve
genuine ABI viability evidence. Do not claim that all 19 subsystems can now
migrate separately.

Forecast analysis at C2 is scenario-only: derive prospective per-bundle bounds
with/without proved cuts; exclude `C_MECHANICAL_ADAPTER`, vendored out-of-scope
code and already-migrated authorities from remaining semantic work.
Independently preserve the original CENSUS01 159/355/961 claim as a historical
baseline. Unknowns produce conditional or unproven estimates; do not invent an
under-100 verdict.

Artifacts: `c2/abi-contract-v1.md`, `c2/abi-signatures.tsv`,
`c2/real-object-linkage.tsv`, `c2/ast-read-proof.txt`,
`c2/container-mutation-proof.txt`, `c2/causal-mutation-restoration.txt`,
`c2/recovery-and-arena-proof.txt`, `c2/probe-build-and-selftests.txt`,
`c2/graph-cut-ledger.tsv`, `c2/graph-before-after-scc.tsv`,
`c2/forecast-impact.tsv`, `c2/next-act-class-and-why.md`.

Commit C2 (`ACT-Phase: IMPL`). No production files or active selector changes.


### C3 — EVIDENCE: independent verification and adversarial controls

An independently authored PolyC verifier and a different implementation for
critical hash/link/graph counts (e.g. POSIX utilities and a separate SCC
algorithm) must recompute from raw source, build, object and control records.
They may not read the C2 PASS column as truth. Require an exact-ID set join of
all frozen 24 control IDs and AC01–AC49. No self-referential evidence rows or
duplicate experiment aliases disguised as independent executions.

Execute all 24 negative controls from §4 against isolated copies. For each,
collect `control_id`, exact mutant input hash, target detector, command, actual
exit, actual detector class, actual raw diagnostic, pristine PASS, targeted
adverse FAIL, restoration PASS and independent verifier status. Failed builds
or environmental errors do not satisfy a behavioral detector unless the
control specifically expects that build failure.

Recheck producer identity and the ABI with disassembly/object symbol evidence;
restore source/object bytes after causal mutations. Independently reproduce
graph-cut/SCC results and any remaining ACT forecast. Re-run conservation
baselines and gates, serially. Verify the complete predecessor freeze and
Factory-v2 append-only invariants; the temporary fixture/worktree must not leak
into tracked production.

Artifacts: `c3/independent-abi-and-object-recompute.tsv`,
`c3/independent-cut-and-scc-recompute.tsv`,
`c3/negative-control-raw-results.tsv`,
`c3/frozen-control-execution-join.tsv`, `c3/independent-forecast-audit.tsv`,
`c3/mandatory-50-ac-status.tsv`, `c3/source-history-conservation.txt`,
`c3/baselines.txt`, `c3/gate-fast.txt`, `c3/gate-push.txt`,
`c3/factory-v2-f14-append-only.txt`.

At C3, AC01–AC49 must be 49 PASS, 0 FAIL, 0 UNPROVEN for a PASS route, with
AC50 explicitly `DEFERRED` until after CLOSE. If a required real PolyC/host ABI
probe is impossible, HALT with the exact dialect/FFI reason and preserve valid
partial evidence; do not weaken the acceptance predicate.

Commit C3 (`ACT-Phase: EVIDENCE`).

### C4 — CLOSE: handoff, roadmap and external terminality

Create a correction-free additive HANDOFF and roadmap section that distinguish:

* viable ABI v1 contract vs blocked families/operations;
* number of actually proved graph edges cut, candidate-only cuts and untouched
  edges;
* SCC partition before/after using only proved cuts;
* M0/M1/M2 unchanged; nine PolyC authorities conserved;
* recommendations for next bounded ACT (e.g.
  `ABI-FOUNDATION-IMPLEMENT01`, `DIALECT-FFI-CORRECTION01`, or
  `BUNDLE-QUALIFICATION01`) without authorizing it;
* CENSUS01 provenance/scope/forecast issues as historical debt, not concealed
  or rewritten;
* exact remaining bootstrap blockers BB-01..BB-04 and updated uncertainty.

Append exactly one `act-handoff-map.tsv` row, append only a bounded roadmap
section, and commit one terminal CLOSE carrying repository-valid Factory-v2
trailers `ACT`, `ACT-Phase: CLOSE`, `ACT-Verdict: PASS` only when all mandatory
proof predicates are actually discharged. Store a `c4/terminality-plan.txt`
plan, not a fabricated post-CLOSE receipt.

After CLOSE run the external, read-only terminality check: HEAD/TREE, trailer
grammar, five-phase sequence/range, clean index/worktree, zero replace refs,
zero extra ACT-created worktrees, 9 active PolyC authorities, frozen artifact
hashes, closure-status, gate-push as required, and AC50. Preserve that receipt
outside the repository. If an external check fails, report `HALT_TERMINALITY`;
do not append a second CLOSE, amend, reset or invent success.

Exactly five linear forward commits for a fully completed PASS:

| Commit | Phase | Non-production substance |
|---|---|---|
| C0 | RED | entry, frozen 50 AC/24 controls, baseline, initial REDs, historical-integrity audit |
| C1 | EVIDENCE | exact C type/ownership/edge/dialect facts |
| C2 | IMPL | non-production real PolyC/C ABI prototype and graph-cut computation |
| C3 | EVIDENCE | independent proofs, 24 controls, preservation, gates |
| C4 | CLOSE | HANDOFF, roadmap/map, one terminal closure |


---

## 4. Frozen negative-control specification — 24 IDs

| ID | Adverse alteration | Expected detector |
|---|---|---|
| AB-EN-01 | Tamper with a predecessor file's frozen hash | `PREDECESSOR_HASH_MISMATCH` |
| AB-EN-02 | Claim a dormant selector-OFF PolyC symbol is a tenth authority | `DORMANT_AUTHORITY_NOT_LINKED` |
| AB-EN-03 | Accept an unauthorized tracked `*-tmp.HC` path as if under the frozen predecessor glob | `PREDECESSOR_SCOPE_MISMATCH` |
| AB-EN-04 | Count a vendored/out-of-scope or already-migrated row as remaining C semantic work | `FORECAST_SCOPE_OR_DOUBLE_COUNT` |
| AB-HD-01 | Pass a null handle to an accessor requiring a live object | `NULL_HANDLE` |
| AB-HD-02 | Pass an `Ast` handle to a `List`-only operation | `WRONG_HANDLE_KIND` |
| AB-HD-03 | Release a handle, then use it | `STALE_OR_RELEASED_HANDLE` |
| AB-HD-04 | Reuse an index with an earlier generation token | `HANDLE_GENERATION_MISMATCH` |
| AB-HD-05 | Forge a raw address or arbitrary integer as a valid handle | `HANDLE_NOT_ISSUED` |
| AB-HD-06 | Borrow an arena-owned AST beyond its arena lifetime | `EXPIRED_BORROW_OR_ARENA` |
| AB-HD-07 | Reuse a handle in the wrong ownership domain/host instance | `HANDLE_DOMAIN_MISMATCH` |
| AB-HD-08 | Release an owned token twice | `DOUBLE_RELEASE` |
| AB-HD-09 | Fetch a C struct field by PolyC-side layout/offset assumption | `OPAQUE_LAYOUT_VIOLATION` |
| AB-HD-10 | Change signature width/ABI while keeping function name constant | `CALL_ABI_MISMATCH` |
| AB-ST-01 | Mutate a C-owned `List`/`Map` outside its permitted borrow/mutation scope | `MUTATION_WITHOUT_CAPABILITY` |
| AB-ST-02 | Out-of-range container operation that partially mutates state | `ATOMICITY_OR_RANGE_FAILURE` |
| AB-ST-03 | Retain a callback or operation beyond its host scope | `CALLBACK_LIFETIME_OR_REENTRANCY` |
| AB-ST-04 | Attempt to `longjmp` across a live PolyC frame | `CROSS_FRAME_RECOVERY_UNSAFE` (reject before execution, never actually jump) |
| AB-ST-05 | Silently swallow a real C host error and return success | `HOST_ERROR_NOT_PROPAGATED` |
| AB-GR-01 | Remove a mandatory graph edge with no ABI witness | `UNPROVEN_EDGE_CUT` |
| AB-GR-02 | Mark a header-only observation as a proved immutable migration-order dependency | `EDGE_EVIDENCE_OVERCLAIM` |
| AB-GR-03 | Hand-edit an SCC or critical-path summary after changing edges | `SCC_OR_DAG_RECOMPUTE_MISMATCH` |
| AB-PV-01 | Replace genuine PolyC subject with handwritten C/assembly or wrong producer object | `POLYC_PRODUCER_SUBJECT_MISMATCH` |
| AB-PV-02 | Run a dormant/unchanged PolyC mutant and claim production-shaped causality | `DORMANT_OR_NO_CAUSAL_DELTA` |

Controls must be valid for the selected actual handle representation. If an
operation does not exist (e.g. owned release is deliberately unsupported), test
that the forbidden operation is rejected by the API contract, not a simulated
fake release. If a detector cannot exist in the selected representation, prove
an equivalent fail-closed contract without changing the frozen intended failure
semantics, or HALT; do not mark a skipped experiment PASS.


---

## 5. Mandatory acceptance contract — exactly 50 predicates

Each PASS requires an independently verifiable raw witness, not a narrative
claim.

| AC | Predicate |
|---|---|
| AC01 | Exact entry HEAD, TREE, branch, clean worktree and zero replace refs verified. |
| AC02 | CENSUS01 five-commit terminal CLOSE/PASS established from real local Git commits. |
| AC03 | Frozen predecessor paths/hashes established and their historical verdicts preserved. |
| AC04 | All nine active PolyC compiler decision sites re-proved at production object/link/call level. |
| AC05 | C0 baselines measured with exact parser/lexer/cross-target/policy identities. |
| AC06 | Five real RED observations with actual measured outcomes, not scripted assertions. |
| AC07 | Fifty AC IDs and twenty-four control IDs frozen before C2 and set-join without duplicates. |
| AC08 | Two `*-tmp.HC` scope questions resolved as historical compliance classifications, not silently dropped. |
| AC09 | Historical census bundle cost/adapter/vendored/pre-migrated units classified without rewriting CENSUS01. |
| AC10 | CENSUS01 SCC/graph assumptions distinguished from genuinely mandatory migration dependencies. |
| AC11 | Each of six named state families inventoried against live source and object provenance. |
| AC12 | All retained source range facts include blob/phase/range SHA and real call/use evidence. |
| AC13 | Allocation, owner, aliasing, borrow and lifetime properties recorded for each family. |
| AC14 | Callback, state and recovery constraints independently enumerated, including unresolved edges. |
| AC15 | PolyC dialect/FFI compatibility tested through real compiler and executable probes. |
| AC16 | Handle token representation chosen from measured ABI results, not unsafe pointer/`I64` assumption. |
| AC17 | Host never exposes direct C struct layout, field offsets or raw dereference to PolyC. |
| AC18 | Host validates token kind, generation, lifetime and ownership domain where applicable. |
| AC19 | Null, wrong-kind, stale and unissued handle results are specified and observable. |
| AC20 | Borrow, invalidation, arena teardown and aliasing semantics explicitly specified. |
| AC21 | Container mutation authorization and failure atomicity specified from real C semantics. |
| AC22 | Callback reentrancy and recovery are status-bound or explicitly blocked; no cross-frame `longjmp`. |
| AC23 | Selected AST-read probe uses genuine production C type/library code, not a mirror struct. |
| AC24 | Selected container mutation probe uses genuine production C type/library code. |
| AC25 | PolyC probe genuinely compiled by a digest-bound compiler producer. |

| AC26 | Object/disassembly proves actual PolyC-to-C host symbol linkage and correct calling convention. |
| AC27 | AST read result matches independent C-only oracle and is externally observable. |
| AC28 | Container mutation result matches independent C-only oracle and is externally observable. |
| AC29 | Host errors and invalid token scenarios are observed without process crash or UB-based detector. |
| AC30 | PolyC-source causal mutation changes actual linked probe behavior and restores byte-identically. |
| AC31 | Probe tool/verifier compiles and its genuine selftest rejects tampered inputs. |
| AC32 | Real C host, PolyC object, link closure and runtime provenance fully recorded. |
| AC33 | C2 handle/ownership contract versioned with precise signatures, target assumptions and negative operations. |
| AC34 | Original mandatory-edge graph reconstructed from CENSUS01 raw IDs/hashes, not recopied summary. |
| AC35 | Every proposed edge cut bound to an actual original edge and an ABI experiment or marked unproven. |
| AC36 | Only source-representative executed cuts classified `CUT_PROVEN_BY_EXECUTION`. |
| AC37 | Before/after graph partition computed mechanically; no invented cut or SCC shrinkage. |
| AC38 | Distinct independent SCC implementation reproduces both partitions and edge sets. |
| AC39 | Remaining uncut `CALLBACK`, `MUTABLE_STATE` and `RECOVERY` constraints preserved as blockers. |
| AC40 | Forecast impact excludes out-of-scope, adapters and already-migrated work, with unresolved uncertainty. |
| AC41 | Independent model recompute agrees with any scenario changes; historical 355 remains labeled a baseline. |
| AC42 | All 24 controls executed with exact detector, input identity and pristine/adverse/restored evidence. |
| AC43 | Negative-control exact-ID join has zero missing, extra, duplicate, vacuous or wrong-subject rows. |
| AC44 | Parser baseline 376/376 and exact assertion sequence conserved; no new parser failures. |
| AC45 | All three direct lexer differentials conserved; LEXER07 15-ID historical failure set unchanged. |
| AC46 | Cross-target 67, F-NO-PYTHON 12 and unavailable F-POLYC-TOOLS reported honestly. |
| AC47 | Production `src/**`, bootstrap tools, active selectors and all closed evidence byte-unchanged. |
| AC48 | gate-fast, gate-push, F14, append-only, Factory-v2, closure-status and patch hygiene PASS. |
| AC49 | Independent C3 ledger proves AC01..AC49; HANDOFF selects only an ACT class, not a new migration target. |
| AC50 | One terminal CLOSE with external post-CLOSE read-only terminality PASS, clean tree, no continuation/worktree residue. |

### PASS/HALT semantics

`PASS_ABI_FEASIBLE_AND_GRAPH_MEASURED` requires two distinct genuinely executed
AST-read/container-mutation PolyC/C probes, the real object/provenance proof,
AC01..AC50 all PASS and exact controls; the SCC may remain unchanged. A
successful API experiment does not require a fake graph cut to earn PASS.

`HALT_ABI_NOT_EXPRESSIBLE` if PolyC cannot express or link the minimum ABI
under the current dialect, even after bounded alternatives have been tried.
`HALT_OWNERSHIP_OR_RECOVERY_UNSAFE` if real lifetime/callback/recovery
obligations cannot be enforced; `HALT_PRODUCTION_SOURCE_DEPENDENCY` if a
genuine probe cannot be built without modifying forbidden production paths.
Other HALT reasons include `HALT_ENTRY_IDENTITY`,
`HALT_PREDECESSOR_INTEGRITY`, `HALT_CONTROL_NOT_SENSITIVE`,
`HALT_GRAPH_CUT_UNPROVEN`, `HALT_UNREPRODUCIBLE_RESULT`,
`HALT_NEW_REGRESSION`, `HALT_GATE`, `HALT_FACTORY`, `HALT_TERMINALITY`.

A blocker must produce a truthful HALT evidence package with exact observed
phase/AC/control counts; never manufacture all five PASS phases or defer
essential execution to a future untracked run. Historical PASS/HALT records
remain immutable.

---

## 6. Final executor report schema

```text
ACT_ID=ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01
VERDICT=PASS|HALT
DISPOSITION=PASS_ABI_FEASIBLE_AND_GRAPH_MEASURED|HALT_<EXACT_REASON>
ENTRY_HEAD=facadfc29bd5284568b6fc1d5c9f96c07e82a07c
ENTRY_TREE=d778bbe13d913134f76efcb643dd75491df31222
FINAL_HEAD=<observed>
FINAL_TREE=<observed>
BRANCH=<observed>
ACT_COMMIT_COUNT=<observed>
WORKTREE_CLEAN=<YES|NO>
GIT_REPLACE_REFS=<integer>
POST_CLOSE_COMMITS=<integer>
POLYC_PARSER_AUTHORITIES=9
NEW_PRODUCTION_AUTHORITIES=0
PRODUCTION_SEMANTIC_DELTA=0
ABI_REPRESENTATION=<measured>
ABI_TARGET_CONFIG=<measured>
AST_READ_REAL_LINK_PROVEN=<YES|NO>
CONTAINER_MUTATION_REAL_LINK_PROVEN=<YES|NO>
POLYC_SOURCE_CAUSAL_MUTATION=<PASS|FAIL|NOT_RUN>
OWNERSHIP_AND_LIFETIME=<PROVEN|BLOCKED|UNPROVEN>
CROSS_FRAME_LONGJMP=FORBIDDEN
GRAPH_BASE_NODES=<row-derived>
GRAPH_BASE_MANDATORY_EDGES=<row-derived>
SCC_BASE=<row-derived>
CUT_PROVEN_BY_EXECUTION=<row-derived>
CUT_CANDIDATE_NOT_PROVEN=<row-derived>
SCC_AFTER_PROVEN_CUTS=<row-derived>
HISTORICAL_M2_FORECAST=159/355/961_UNQUALIFIED
NEW_M2_ESTIMATE=<bounded scenario or UNPROVEN>
CENSUS01_SCOPE_AUDIT=<measured classification>
CENSUS01_FORECAST_AUDIT=<measured classification>
NEGATIVE_CONTROLS=<PASS/TOTAL, exact ID join>
MANDATORY_AC=<PASS/TOTAL, exact ID join>
PARSER_ASSERTIONS=<observed>
LEXER07_HISTORICAL_IDENTITY=<observed>
GATE_FAST=<observed>
GATE_PUSH=<observed>
FACTORY_V2=<observed>
F14=<observed>
APPEND_ONLY=<observed>
EXTERNAL_TERMINALITY=<PASS|FAIL|NOT_RUN>
NEXT_ACT_CLASS=<evidence-backed only>
NEXT_TARGET=NONE
SLICE10_AUTHORIZED=NO
SELFHOST_M2_ACHIEVED=NO
```

Final rule: demonstrate a reusable, bounded state interface and quantify how
much dependency coupling it truly removes. Do not count another tiny PolyC
helper as a new production authority, do not claim the whole SCC has
disappeared, and do not promise an ACT count that the executed ABI/graph
evidence cannot support.
