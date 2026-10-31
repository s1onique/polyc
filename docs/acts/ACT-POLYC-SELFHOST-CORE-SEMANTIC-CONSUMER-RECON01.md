# ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT — not a completion report
Class: SELFHOST / CORE_SEMANTIC_CONSUMER_RECON / BUNDLE_SELECTION / ABI_FEASIBILITY / BOOTSTRAP_CRITICAL_PATH
Priority: P0
Repository: the existing canonical local PolyC checkout (s1onique/polyc); remote availability is not assumed
Branch: existing main — no ceremonial per-ACT branch
Expected ENTRY_HEAD: eb5eb78524fecc875c1629ffa0e448926a45c75b
Expected ENTRY_TREE: 6ae357df1113e4c80c29201b7e27417518107371
Binding predecessor: ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01, terminal CLOSE/PASS, external receipt executor-reported
Current active PolyC decision authorities: 10 = nine parser + one non-parser (AbiCpaShouldPrintAst)
Current graph: 52 nodes, 134 mandatory edges, exactly one source/object-proven production cut E-TYP-0136
Current SCC: 34, largest = 19 subsystems
Selection at entry: NONE; no chosen source function, edge, ABI, or implementation bundle
Permitted production semantic delta: 0
Permitted production authority transfer: 0
Permitted additional graph cuts: 0
Next implementation: a separately authorized successor only after this ACT produces an eligible, load-bearing, source-bound frozen contract
Explicit exclusions: SLICE10 not authorized; M2 genuine self-hosting not achieved.

## 0. Mission and definition of success

Select exactly one coherent, bootstrap-relevant compiler semantic consumer or
bundle for the next separately authorized migration. The selected work must
concern real compiler semantics in the active parse → type/semantic analysis →
CFG/IR → code-generation path; it must not merely classify AST output for
`-ast` or repeat the previously proven diagnostic `AbiCpaShouldPrintAst`
transfer.

The ACT must freshly inventory production-reachable C-owned semantic sites,
relate them to the live compiled/linkable production configuration, group
compatible sites by shared state and ABI requirements, rank them mechanically,
and execute a source-bound C-side causal experiment with a rebuilt real
compiler before freezing one successor. It must establish a viable proposed
PolyC/C ABI boundary and an executable implementation plan, without
implementing the boundary in production.

A PASS means:

1. The exact entry and closed evidence are conserved; the production compiler
   still has 10 PolyC decision authorities.
2. The candidate register is source/object-derived, with explicit exclusions,
   including parser/type/CFG/IR/codegen consumer families as applicable to
   the actual linked graph.
3. At least one eligible core candidate/bundle is selected by a frozen,
   independently recomputed ranker; no candidate ID is assumed in advance.
4. The selected semantic decision has a real load-bearing witness, obtained
   after rebuilding the production compiler in an isolated mutant checkout. A
   cosmetic or diagnostic-output-only mutation cannot qualify.
5. The selector/ABI plan specifies each permitted C-owned read/mutation,
   lifetime, host return/status channel, ownership and recovery behavior;
   feasibility is grounded by actual compiled object/source evidence rather
   than an invented function signature.
6. The successor contract freezes exact source identity, group identity, ABI,
   C-oracle, causal witness, bootstrap producer/selector requirements, and
   per-subject negative-control obligations.
7. The historical 134-edge graph is not falsified; suspected E-MUT-0137 is
   audited and its witness-quality disposition recorded without falsely
   claiming a new graph cut or changing closed evidence.
8. 24 adverse controls and 50 acceptance criteria are independently
   evidenced; repository gates and external terminality satisfy Factory-v2.

A HALT is the only honest outcome if no bounded core candidate can be proven
causally load-bearing and implementable. No fallback to an easy diagnostic
predicate to manufacture a PASS.

### 0.1 Distinguish three different kinds of progress

| Metric | What may change in this ACT | What must not be inferred |
|---|---|---|
| Semantic selection | One future migration bundle may be frozen | A selected bundle is not a migrated authority |
| Graph fidelity | A disputed witness may be independently reclassified in a correction-owned view | A disproven historical witness is not a newly implemented production cut |
| Self-hosting | A bootstrap-critical path hypothesis may become better supported | No M1/M2 claim, no new calibrated ACT forecast, no SCC decrease absent executed source changes |

E-TYP-0136 is the only currently demonstrated production layout cut.
E-MUT-0137 remains an unresolved witness-quality issue in the historical
134-edge ledger; do not treat its presence or absence as a demonstrated change
in compilation.

## 1. Binding entry material and source-of-truth hierarchy

Read before edits:

- AGENTS.md, docs/factory/DOCTRINE.md, docs/factory/ACT-TEMPLATE.md,
  Factory-v2 trailer/range/append-only/F14/closure checkers and gate scripts
  from the entry checkout.
- docs/acts/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01.md and
  corresponding HANDOFF, actual C0–C4 evidence, especially C2
  source/relocation/edge-cut proof and C3 independent graph, generation and
  control joins.
- IMPLEMENT01 and RECON01 ABI documents, actual compiled src/abi-cpa-host.c and
  .h, tools/bootstrap/selfhost-abi-compile-print-ast.HC, actual producer
  rules, and the C-OFF / C-ON selector contract.
- CENSUS01's function/authority inventory, 52-node graph, 135-edge mandatory
  baseline, 34-SCC calculation and unqualified scenario forecast; do not copy
  its questionable cost categories as validated facts.
- Closed parser surface contracts for nine genuine parser authorities and the
  latest actual parser/AST source if relevant to a candidate.

Authority order: source bytes at declared Git object → real build/link/object/
mutant observations → frozen committed ACT evidence → summaries/LEAMAS digest
(non-authoritative). If a required raw predecessor file is absent, record
UNAVAILABLE and HALT its dependent assertion; do not reconstruct missing bytes
from a summary.

Require precisely:

```text
ENTRY_HEAD=eb5eb78524fecc875c1629ffa0e448926a45c75b
ENTRY_TREE=6ae357df1113e4c80c29201b7e27417518107371
BRANCH=main
TRACKED_AND_INDEX_CLEAN=YES
GIT_REPLACE_REFS=0
PREDECESSOR_CLOSE=PASS
PREDECESSOR_POST_CLOSE_COMMITS=0
PRODUCTION_POLYC_AUTHORITIES=10 (9 parser + 1 CPA)
PRODUCTION_PROVEN_CUTS={E-TYP-0136}
PRODUCTION_MANDATORY_EDGE_SET_SIZE=134
PRODUCTION_GRAPH_NODES=52
SCC_COUNT=34
SCC_LARGEST=19
```

Record pre-existing detached worktrees and their owners separately. An
untracked path at entry is not automatically an ACT-owned file; preserve it
and report its actual count. Do not clean, reset, rebase, amend, force-push,
replace refs, fetch/checkout an alternate entry, or delete someone else's
worktrees. Any entry mismatch is HALT_ENTRY_IDENTITY.

### 1.1 Non-negotiable conservation reference

```text
PARSER_ASSERTIONS              376/376 over 90 files
PARSER_ASSERTION_SEQUENCE_MD5  b6f117eb1386ca80f81bc06226e2a741
LEXER07_DIRECT                 89/89
LEXER08_DIRECT                 45/45
LEXER09_DIRECT                 23/23
LEXER07_BROAD                  FAIL_KNOWN_BASELINE; 15 failure identities
LEXER07_FAILURE_IDENTITY_MD5   7ee761440de83552e751e3c3976c1683
CROSS_TARGET_PREFIX           FAIL_ENVIRONMENT_PREFIX; 67 missing-file failures
F_NO_PYTHON                    FAIL_KNOWN_BASELINE; 12 historical violations, 0 new
F_POLYC_TOOLS                  UNAVAILABLE until canonical checker actually lands
GATE_FAST                      PASS
GATE_PUSH                      PASS (build, install, gep01, aot, jit, lsp, diff-check)
APPEND_ONLY                    11/11
SELFHOST_M2                    NOT_ACHIEVED
```

Freshly rebuild both C0 and C3 unit-test runners with the same hermetic
install-prefix method used by gate-push. Verify runner binary hash, compiler
hash, installed header-prefix identity and test command. A stale
src/tests/test-runner or missing /usr/local/include must not be counted as a
new semantic regression nor quietly hidden. The historical 67 missing-prefix
observations remain separately classified.

## 2. Scope and prohibitions

Permitted tracked modifications only:

```text
docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01.md
docs/factory/act-handoff-map.tsv        # exactly one new row
docs/ROADMAP.md                         # one bounded append
Makefile                                # optional bounded additive census/replay targets
tools/quality/core-semantic-consumer-recon01-*.HC
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01/**
```

Only experimental untracked disposable worktrees may alter src/**, existing
tools/bootstrap/**, CMake, test source or compiler semantic code to run
adverse experiments; those mutations may never be committed on authoritative
main. Test corpus inputs, synthetic source mutants and independent shell/AWK
witnesses belong to the ACT evidence tree or disposable worktrees. No Python,
new third-party dependencies, broad refactoring, modifications to historical
ACT/evidence, canonical quality/factory gates, or previously migrated
production subjects.

A new substantive verifier must be PolyC (.HC); POSIX shell/AWK may serve as
bounded independent proof/control drivers under the evidence tree. Do not add
giant unstructured shell-based canonical tooling or claim F-POLYC-TOOLS=PASS
when the authoritative checker remains absent.

Do not modify src/compile.c to migrate more semantics, enlarge ABI host
surface, change actual compiler semantics, add an eleventh production
authority, or claim a second production graph cut. PARSER-SURFACE-RECON09,
SLICE10, and the compiler static-global / pointer-ternary / assembly-temp /
F-POLYC-TOOLS repairs are independent work.

Builds and gates must be serialized until the shared /tmp/holyc-asm.s
collision is fixed. Detached-worktree paths and build/install prefixes must be
unique per experiment. No background task may be left unconsumed when issuing
the terminal completion report.

## 3. Canonical machine-readable schemas

These are logical TSV schemas; additional columns are allowed when frozen at
C0/C1, but no required field can be omitted or silently populated as PASS.

```text
source_roster.tsv:
  source_id,git_blob,source_path,function_or_site,range_start,range_end,
  range_sha256,build_config,object_path,object_sha256,producer_sha256,
  linker_reachable,caller_witness,semantic_family,authority_class

semantic_sites.tsv:
  site_id,source_id,source_range_sha256,site_kind,behavior,decision_inputs,
  decision_effect,host_state_read,host_state_write,ownership,recovery,
  outgoing_edge_ids,existing_polyc_authority,object_witness,classification_reason

bundle_registry.tsv:
  bundle_id,site_id_list,shared_semantic_goal,bootstrap_path,witness_ids,
  proposed_abi_version,host_operations,rollback_selector,blocking_edges,
  owned_state,recovery_class,causal_state,eligibility,exclusion_reason

selected_bundle.tsv:
  bundle_id,site_ids,source_blobs,range_hashes,entry_object_hashes,
  linked_relocation_evidence,ABI,selector,host_owned_state,
  G0_oracle,witness_ids,executed_C_mutation_id,rank_tuple,
  successor_contract_sha256

edge_witness_audit.tsv:
  edge_id,original_src,original_dst,type,declared_witness,
  actual_source_reads,actual_object_refs,live_under_config,
  verdict,reason,alternative_graph_membership
```

Every register needs an exact-ID set join to its predecessor inputs;
UNKNOWN, duplicate IDs, absent hashes, orphan graph edges, and ambiguous build
configuration are explicit non-PASS conditions. Count source functions,
semantic sites, compiler authority decisions, build objects, and graph edges
separately. Do not mistake helper functions or raw symbols for new semantic
authorities.

## 4. Candidate search and bundle feasibility

### 4.1 Population: compiler-core semantics only

Begin with the production-linked C authority rows from CENSUS01 and freshly
join each against actual production objects and C source. Include parser
semantic work, AST construction where it changes meaning, type checking/
inference and symbol decisions, CFG and IR construction/verification,
optimization if present in the actual production graph, instruction selection/
codegen, lowering and linking decisions where implemented in this compiler.
Classify driver/debug-only, logging, formatting, REPL, LSP and vendored/
platform/runtime glue separately; do not rank diagnostic-only nodes as core
M1/M2 progress.

Preserve whole-function PARSER01 blockers (parseExpr, parseStatement,
parseCompoundStatementInternal, recursive graph walks and mutable symbol-table
routing) explicitly as candidates or blocked work; they must not disappear
because their boundaries are difficult. Do not presume those are the winners.
Respect historical SUB-001/002/003/004 migrations as already PolyC-owned, and
exclude them from remaining-C candidate counts.

A candidate is a bounded semantic operation or a coherent group with a common
state/ownership boundary, not an arbitrary set of distant source lines. Bundle
multiple related decisions if they can share one ABI and have independent
witness attribution. Single-decision selection is allowed only if it
demonstrably unblocks later coherent core work, and this exception must be
evidenced rather than defaulted.

### 4.2 Exact eligibility predicates (E01–E14)

The selected bundle must pass all predicates; any failure means INELIGIBLE
with the actual reason. Freeze predicates and their interpretations before
ranking.

| ID | Required property |
|---|---|
| E01 | All sites are live in the declared normal production compiler config; source/object/reachability joins complete. |
| E02 | Each selected decision is C-authoritative at entry, not already delegated to compiled PolyC or an external provider. |
| E03 | Its effect changes compiled-program behavior, acceptance, emitted IR/assembly/object, or a compiler semantic invariant; not debug/format/diagnostics alone. |
| E04 | The semantic rule and site boundaries are exact and source-hashed at the frozen entry tree. |
| E05 | A callable, bounded PolyC/C seam can be expressed without exposing raw AST/Map/List/Cctrl/Arena layout to PolyC. |
| E06 | All host reads/writes, aliases, arenas, epochs, borrowed handles, error statuses and lifetime transitions are enumerated. |
| E07 | Recovery and callbacks cannot cross an active PolyC frame unsafely; a verified boundary exists or a blocking dependency is explicitly resolved by plan. |
| E08 | G0 genuinely compiles the unchanged C rule, with source/object provenance and no future PolyC subject dependency. |
| E09 | Source-derived fixture includes reachable positive, negative, boundary and invalid-input behavior as applicable. |
| E10 | A bounded C-side adverse mutation can rebuild the real compiler and produce a core semantic observable difference; restoration is source/object-identical. |
| E11 | There is a plausible selector-OFF/ON producer and link plan, including stage0 OFF, without make prerequisite-expansion hazards. |
| E12 | Scope has finite, named touched source/caller/header/host paths, or else must be deferred as an explicit ABI-foundation blocker. |
| E13 | Bundle has measurable impact on a bootstrap-critical dependency or actual C-owned core semantic decision set (with no invented SCC reduction). |
| E14 | No frozen predecessor evidence rewrite, no unrelated compiler defect fix, no extra unauthorized semantic migration required. |

If all candidates are ineligible, produce an accurate
HALT_NO_ELIGIBLE_CORE_BUNDLE and an evidence-backed list of required enabling
ABI ACTs. Do not weaken E01–E14 or switch to a diagnostic candidate.

### 4.3 Frozen deterministic ranker: core impact precedes convenience

For each eligible bundle derive, and independently recompute, the lexicographic
tuple below (not weighted summed scores that can hide an unsafe boundary).
Tie-break with bundle_id lexical order; do not alter rules after observing a
preferred candidate.

| Rank key | Direction | Source of evidence |
|---|---|---|
| R0: bootstrap semantic criticality | Descending | Real call path for compiling PolyC-authored compiler sources and generating a working compiler, not a guessed project dependency. 2 direct M2-critical, 1 plausible M1/core enabling, 0 none (E13 prevents selecting 0). |
| R1: number of distinct C-owned core semantic decisions retireable in one bounded ABI | Descending | Exact site_id union; adapters, existing authorities and diagnostics excluded. |
| R2: independent core-semantic causal witnesses | Descending | Successfully rebuilt real C-mutant channels, uniquely identified; one experiment under two IDs counts once. |
| R3: number of current core dependencies meaningfully replaceable | Descending | Candidate replacement only, actual source reads/calls and required ABI operations. Not a completed production cut. |
| R4: safety readiness | Descending | Explicit complete lifetime/status/recovery/ownership contract preferred; any unresolved safety obligation already fails E05–E07. |
| R5: bounded implementation surface and reversibility | Ascending | Count of touched source/host/producer files, selector strategy and bounded witness cost. |
| R6: source-stable tie-break | Ascending | Exact bundle_id, then source IDs, not recommendation order. |

A single canonical ranker may be implemented new under the ACT evidence/tools
namespace; do not misapply the old parser-specific R0–R6 or trust a pre-filled
eligible column. Feed the ranker the measured checker output. An independent
implementation must recompute eligibility from source facts, not read the
canonical eligible column, and must reproduce the full ordered list and
selection.

## 5. Executable C0–C4 lifecycle

Each phase owns exactly one append-only commit with correct Factory-v2 trailers
validated before committing. Do not amend/replay published commits; stop for
legitimate entry or trailer-policy failures. The only terminal CLOSE is C4;
post-CLOSE receipts are external and must not create a sixth commit.

### C0 — RED: provenance, freeze, falsifiable gaps

- Prove exact HEAD/TREE/branch, predecessor terminal close, clean tracked/index
  state, zero Git replace refs; make a SHA-256 manifest of frozen predecessor
  paths and compare by path, not totals.
- Rebuild C0 reference ./hcc/runner in a fresh hermetic build/install prefix;
  freeze normal ON + selector OFF producer/link identity and C0 baselines,
  including known non-green historical identities.
- Re-read 10 authorities from actual symbols + caller/linked object proof.
  Re-establish graph 52/134, cut E-TYP-0136, SCC 34/largest 19; do not copy
  summary figures without recomputing from edge set.
- Freeze c0/frozen-50-ac.tsv, c0/frozen-24-controls.tsv,
  c0/ranking-and-eligibility-contract.md, source scope and allowed mutated
  worktree protocol. All 50 ACs and 24 control IDs must be individually unique.
- Execute five real RED observations: RED-1 no selected core successor exists
  at entry; RED-2 a diagnostic-only -ast decision is not a core semantic
  witness; RED-3 E-MUT-0137 lacks sufficient source/object consumer proof
  until audited; RED-4 candidate status/eligible flag can be forged if the
  ranker trusts text; RED-5 stale runner, omitted Makefile prerequisite, or a
  source-range hash taken from the wrong phase can lead to false evidence.
  Each has pristine/adverse measurements with distinct detectors; do not
  assume it fails without running.
- Record all REDs and the source/object identity of each adverse probe. RED
  status is the measured status, not a promise.

Commit C0 RED only after controls are frozen and RED evidence exists.

### C1 — EVIDENCE: exhaustive provenance and graph-witness audit

- Inventory the production build graph and its source object/configuration with
  concrete source ranges and SHA-256 of actual bytes. Reconcile CENSUS01's
  remaining C authorities, existing nine parser plus one CPA, and candidate
  ownership; every omission or classification change is a recorded set
  difference.
- For each relevant core family, trace live caller → semantic operation →
  output effect, including direct and transitive headers, mutable globals,
  callback tables, longjmp/recovery, allocations and type representations.
  Label inaccessible/unprovable sources as UNKNOWN; do not quietly exclude them
  from denominators.
- Revalidate E-MUT-0137 in the entry production build, including all five
  named ast_* globals: declarations are not consumption. Search source
  reads/writes, object symbols and relocation references, and transitive usages.
  Record VERIFIED, UNSUPPORTED_WITNESS, or UNDETERMINED with exact evidence.
  Preserve the frozen ledger as history. If independently unsupported, model a
  separate alternative graph scenario, not a production CUT_PROVEN.
- Build proposed bundles by common state/ABI and semantic objective, calculate
  possible dependencies and bootstrap paths. Preserve ineligible and
  whole-function blockers; the set must be complete against the measured
  candidate roster.
- For each potentially eligible bundle, freeze exact G0 C-only oracle plan,
  expected source-bound fixtures, ABI host operations and forbidden status/
  recovery cases. Establish actual normal/stage0 build flags and producer
  identities.
- Prepare a source-bound C-mutant plan for more than one top eligible candidate
  where feasible to reduce “one weak mutant ⇒ inert decision” mistakes; at
  least one successful rebuilt causal mutant is mandatory for the eventual
  selected bundle.

Commit C1 EVIDENCE. C1 cannot claim causal success until actual C2 execution.

### C2 — IMPL: implement selection verifier and execute causal qualification; no production change

IMPL refers to implementing the selection verifier and experimental proof, not
a compiler migration.

- Implement the source-derived roster/eligibility/rank/graph-check verifier as
  new PolyC .HC code (or extend with a new ACT-owned PolyC module), compiling
  it with the actual recorded hcc producer. Fail closed for missing rows,
  malformed SHA, duplicate IDs, unavailable source files, phase-stale blobs,
  unknown statuses, forged eligibility, and inconsistently bound graph edge IDs.
- Execute the canonical checker E01–E14, feed its actual output to the
  deterministic ranker R0–R6, and freeze the full population, not just the
  winner. An independent AWK/POSIX witness or distinct PolyC implementation
  recomputes the full eligibility set and rank order from C1 source facts.
- For the rank leader, in a disposable git worktree add --detach at the frozen
  entry/C1 source tree, mutate only the selected C semantic decision. Build a
  real full compiler with isolated installed prefix. Confirm changed source SHA
  and object digest, live symbol/call-site or relocation evidence, successful
  compiler build, and a witness that differs in semantic acceptance, generated
  IR/object, or executed compiled-program behavior. Generic build failure,
  diagnostics-only changes, stale object, test fixture-only changes or edits to
  a dormant branch are UNQUALIFIED.
- Where a first mutation is build-invalid or empirically inert, preserve its
  transcript and attempt at least one additional bounded live-rule mutation
  justified by source coverage before declaring the candidate causally
  unqualified. If the current leader fails qualification, record disqualification
  and re-run deterministic selection on the measured survivor set; preserve each
  version of the roster and ranker input. No post-hoc rank tweaking.
- Restore mutant source byte-identically in the disposable tree, rebuild and
  confirm object and witness recovery. Remove only ACT-created worktrees. Never
  touch authoritative src/**.
- Determine whether a single operation or coherent multi-decision bundle is
  most credible; if multi-site, each claimed decision must have its own
  source-to-witness attribution (shared physical experiment allowed only with
  explicitly separated detection).
- Produce c2/selected-core-bundle-contract.md with the selected source ranges,
  exact SHA-256s, expected future PolyC ABI (no raw pointer layout), host
  status/handle safety, G0 oracle, fixture partitions, selector OFF/ON,
  stage0/production producer, C and later PolyC causal subject separation,
  object criteria and successor negative controls.
- Recompute candidate graph edge removals as prospective only. Historical active
  production stays 52 nodes/134 mandatory edges; no claim of actual SCC shrink
  or time-to-M2 reduction.

Commit C2 IMPL. If no eligible causally qualified candidate survives, close a
truthful HALT, preserving all qualified evidence and identifying a bounded
enabling ABI ACT instead of fabricating PASS.

### C3 — EVIDENCE: independent replay, 24 adverse controls and gates

- Independently recompute from committed C1/C2 facts: complete ID sets,
  semantic ownership, source and object digests, checker eligibility, full
  ranking, causal mutation/source/object/witness identity, ABI safety, 134-edge
  historical graph and conditional scenario.
- Execute all 24 controls using actual isolated copies/mutants, not just data
  literals or labels. Each control has pristine PASS → intentionally adverse
  reason-specific FAIL → byte-restored PASS, and a unique execution ID. A crash,
  timeout, missing compiler, unrelated failed build or unverifiable subject is
  not a successful detector.
- Prove controls remain sensitive to a deleted row, fake PASS, fabricated bundle
  count and substituted source/hash by direct false-PASS selftests. Exact ID
  join FROZEN ⨝ OBSERVED: zero missing/extra/duplicate/unknown; record aliases
  sharing experiments explicitly without double counting.
- Run fresh hermetic parser and lexer baselines, controlled historical non-green
  suites, actual gate-fast, serial gate-push, append-only/F14/patch-hygiene.
  Confirm zero production src/**/bootstrap semantic changes and preservation of
  10 compiled PolyC authorities.
- Compare all frozen predecessor files by path and SHA; do not touch historical
  CLOSE/HANDOFF/evidence.
- The pre-CLOSE ledger must be AC01..AC49 PASS, AC50 DEFERRED, 0 FAIL/UNPROVEN;
  otherwise HALT. Never pre-record a post-CLOSE observation in C3.

Commit C3 EVIDENCE.

### C4 — CLOSE: one successor contract, no implementation

- Commit exactly one additive HANDOFF, one handoff-map row and one bounded
  ROADMAP append, with a reproducible selected-bundle contract, excluded
  alternatives, source/object hashes, ABI plan, causal witness, graph caveats,
  remaining failures and next proposed ACT class.
- c4/terminality-plan.txt describes future external checks only; it may not
  state a fabricated post-CLOSE PASS or include the future CLOSE SHA.
- Validate the pending commit message with the repository's real Factory-v2
  commit-message checker. Make the last commit exactly ACT-Phase: CLOSE /
  ACT-Verdict: PASS (or properly classified HALT if evidence blocks success).
  Observe Factory-v2 range and append-only policy without amend/replay.
- After C4, run external read-only terminality: exact HEAD/TREE, clean
  worktree/index, zero replace refs, single CLOSE, expected five-commit phase
  order, no post-CLOSE commit, F14/freeze, actual authority count and graph,
  fresh gate-push against CLOSE, and AC50. Store receipt outside the repo; do not
  create tracked post-CLOSE content.
- Consume every held terminal job individually before the final executor report.
  If the external receipt fails, report terminality failure and do not claim PASS
  or create an unauthorized sixth commit.

NEXT_ACT_CLASS: decide from measured bundle/ABI contract, typically
ABI_CORE_IMPLEMENT or a bounded prerequisite ABI_FOUNDATION_IMPLEMENT; no
target ID or SLICE10 is preauthorized by this ACT.

## 6. Frozen adverse-control roster (24 controls)

Each control is frozen in C0 with columns control_id, subject, adverse_action,
expected_detector_class, pristine_observation, adverse_observation,
restored_observation, execution_id, source_or_object_sha256, evidence_path. For
data-record controls, the verifier actually executes against an isolated
mutated copy; for causal controls, it executes against real compilations/
objects. Multi-stage controls cannot be labelled sensitive based only on
matching an expected text string.

| ID | Deliberate adverse condition | Exact required detector class |
|---|---|---|
| NC-01 | Wrong entry HEAD/TREE / fake predecessor CLOSE | ENTRY_OR_PREDECESSOR_IDENTITY_MISMATCH |
| NC-02 | Tamper one predecessor frozen path digest | PREDECESSOR_F14_HASH_MISMATCH |
| NC-03 | Duplicate or delete one semantic-site ID | CANDIDATE_ROSTER_SET_MISMATCH |
| NC-04 | Insert source site without linked production object | UNLINKED_OR_DORMANT_SOURCE_SITE |
| NC-05 | Rewrite a source-range SHA without changing Git blob | SOURCE_RANGE_HASH_MISMATCH |
| NC-06 | Supply a post-C2 hash for a C0/C1 range | SOURCE_PHASE_PROVENANCE_MISMATCH |
| NC-07 | Treat ten raw symbols as ten parser authorities | AUTHORITY_CLASSIFICATION_MISMATCH |
| NC-08 | Double-count the already-migrated CPA decision | EXISTING_AUTHORITY_DOUBLE_COUNT |
| NC-09 | Promote -ast diagnostic-only candidate into core | DIAGNOSTIC_AS_CORE_MISCLASSIFICATION |
| NC-10 | Omit a still-C-owned whole-function blocker | CANDIDATE_POPULATION_INCOMPLETE |
| NC-11 | Accept forged eligible flag contrary to E01–E14 | ELIGIBILITY_SOURCE_FACT_MISMATCH |
| NC-12 | Change a rank score / swap two eligible candidates | RANK_ORDER_MISMATCH |
| NC-13 | Substitute a different edge ID or graph endpoint | EDGE_ID_OR_ENDPOINT_BINDING_MISMATCH |
| NC-14 | Call E-MUT-0137 verified from declaration alone | MUTABLE_STATE_CONSUMPTION_UNPROVEN |
| NC-15 | Claim a speculative edge deletion as production cut | PROSPECTIVE_PRODUCTION_CUT_CONFLATION |
| NC-16 | Claim smaller SCC by decrementing edge count | SCC_INDEPENDENT_RECOMPUTE_MISMATCH |
| NC-17 | Use stale/handwritten object or non-production compiler | COMPILER_OBJECT_OR_PRODUCER_PROVENANCE |
| NC-18 | Mutate C source but retain prior linked object | CAUSAL_MUTATION_DORMANT_OR_STALE |
| NC-19 | Count a compile failure as causal semantic effect | UNQUALIFIED_BUILD_FAILURE |
| NC-20 | Count diagnostic-only change as core semantic proof | NONCORE_CAUSAL_WITNESS |
| NC-21 | Use one physical mutant for two claimed independent semantic sites without attribution | DUPLICATE_CAUSAL_EXECUTION |
| NC-22 | Propose raw-layout handle or negative-value ambiguous ABI | ABI_OWNERSHIP_OR_STATUS_UNSAFE |
| NC-23 | Propose callback/nonlocal recovery across PolyC frame | CROSS_FRAME_RECOVERY_UNSAFE |
| NC-24 | Forge one control PASS / omit AC / relabel known FAIL as PASS | EVIDENCE_LEDGER_OR_BASELINE_FALSE_PASS |

NC-18, NC-19, and NC-20 may use distinct probes of a single source-bound
candidate, but the execution ledger must explicitly identify physical
experiment IDs and must never claim them as three independent causal
demonstrations. C3 must independently run a deleted-control-row, altered-ID,
fabricated-PASS, substituted-subject, and wrong-source-phase selftest; all must
reject the false claim with a named detector.

## 7. Mandatory acceptance contract (50 acceptance criteria)

Freeze exactly these IDs and predicates at C0. Each AC must have a source/
object/command/evidence path and an actual result. For ACCEPTANCE, C3 is 49
PASS + AC50 DEFERRED, never a premature 50/50; only the external post-CLOSE
receipt may discharge AC50.

| AC | Binding predicate | Owner | Required evidence under ACT namespace |
|---|---|---|---|
| AC01 | Exact ENTRY_HEAD/TREE, existing main and clean tracked/index baseline | C0 | entry-identity.txt |
| AC02 | Predecessor terminal Factory-v2 PASS and five-commit range proved from trailers | C0 | predecessor-terminal-and-freeze.tsv |
| AC03 | Prior evidence paths hash-frozen by real committed source bytes | C0 | predecessor-terminal-and-freeze.tsv |
| AC04 | Ten real production authorities proven individually; 9 parser + 1 CPA | C0 | production-authorities.tsv |
| AC05 | Production graph 52 nodes, 134 mandatory edges and only E-TYP-0136 cut rederived | C0 | baseline-graph.tsv |
| AC06 | C0 hermetic compiler/test-runner/install-prefix provenance measured | C0 | baseline-provenance.tsv |
| AC07 | Parser/lexer/non-green baseline and exact historical identity freshly measured | C0 | baselines.txt |
| AC08 | Five reason-specific REDs executed and recorded honestly | C0 | five-reds.tsv |
| AC09 | 50 AC and 24 control IDs frozen before implementation phase | C0 | frozen-50-ac.tsv;frozen-24-controls.tsv |
| AC10 | Eligibility/ranking/selection/fail-closed contract frozen in C0 | C0 | eligibility-and-ranking-contract.md |
| AC11 | Build-config/object/source authority roster complete against CENSUS01 | C1 | source-roster.tsv |
| AC12 | C-owned core semantic sites individually source-hashed | C1 | semantic-sites.tsv |
| AC13 | Parser/type/CFG/IR/codegen families and exclusions classified from real build | C1 | core-family-reconciliation.tsv |
| AC14 | Previously PolyC-owned sites and diagnostic-only sites not charged as remaining core | C1 | core-family-reconciliation.tsv |
| AC15 | Open whole-function blockers and UNKNOWN sites preserved by ID | C1 | blocked-and-unknown.tsv |
| AC16 | Host object/layout/alias/arena/container/callback reads mapped | C1 | ownership-dependencies.tsv |
| AC17 | Recovery and nonlocal-jump requirements mapped with exact call/source paths | C1 | recovery-boundaries.tsv |
| AC18 | E-MUT-0137 declarations vs live mutable reads and object references audited | C1 | edge-mut-0137-audit.tsv |
| AC19 | Historical graph and conditional alternative graph never conflated | C1 | edge-mut-0137-audit.tsv |
| AC20 | Candidate coherent bundles enumerated by shared objective and ABI | C1 | bundle-registry.tsv |
| AC21 | Each bundle carries measured bootstrap path or exclusion reason | C1 | bootstrap-reachability.tsv |
| AC22 | Candidate G0/oracle and fixtures planned from live source | C1 | candidate-oracle-plan.tsv |
| AC23 | Mutant plans include at least two shapes when first may be non-observable | C1 | candidate-mutant-plan.tsv |
| AC24 | Stage0 OFF and effective Makefile producer and prerequisite plan derived | C1 | producer-and-rollback-plan.md |
| AC25 | No unauthorized production source/authority change through C1 | C1 | entry-to-c1-scope.tsv |
| AC26 | New PolyC verifier compiles with real producer; selftests pass | C2 | verifier-selftest.tsv |
| AC27 | Checker evaluates all 14 eligibility predicates from C1 fact rows | C2 | eligibility-checker-output.tsv |
| AC28 | Canonical ranking receives checker outputs, not user-supplied flags | C2 | ranked-candidates.tsv |
| AC29 | Independent recomputation agrees entire eligibility and rank order | C2 | independent-ranking.tsv |
| AC30 | Exactly one selected bundle or precise HALT; no source ID preselection | C2 | selected-core-bundle.tsv |
| AC31 | Selected bundle is core semantics not diagnostic output | C2 | selected-core-causality.md |
| AC32 | Selected C site is reachable in actual production compiler object and call path | C2 | selected-core-causality.md |
| AC33 | C mutant changes only selected frozen semantic source in detached worktree | C2 | c-mutation-restoration.tsv |
| AC34 | Mutant real production compiler rebuilt successfully, new object proven linked | C2 | c-mutation-restoration.tsv |
| AC35 | Semantic acceptance/emission/runtime witness differs for causally justified reason | C2 | c-mutation-restoration.tsv |
| AC36 | Mutant and restored source/object/witness hashes return exactly | C2 | c-mutation-restoration.tsv |
| AC37 | First failed/inert causal mutant documented, not silently converted to PASS | C2 | c-mutation-restoration.tsv |
| AC38 | Selected ABI host-owned state, lifetime/status/recovery contract frozen | C2 | selected-core-bundle-contract.md |
| AC39 | Selected G0, selector plan, G1–G3 producers, future PolyC mutant identities frozen | C2 | selected-core-bundle-contract.md |
| AC40 | Prospective graph benefits separate from implemented production cuts | C2 | prospective-graph-impact.tsv |
| AC41 | C3 independent source/object/authority and full candidate roster recomputation | C3 | independent-source-object-roster.tsv |
| AC42 | C3 independent E01–E14 and R0–R6 calculation matches | C3 | independent-eligibility-rank.tsv |
| AC43 | Selected semantic causality independently replayed and phase/source-bound | C3 | independent-causality.tsv |
| AC44 | NC-01..NC-24 sensitive, exact-ID join, 0 missing/extra/duplicate/unknown | C3 | control-execution-join.tsv |
| AC45 | False-PASS selftests reject missing rows, fake statuses, wrong subject/hash | C3 | control-verifier-selftest.tsv |
| AC46 | Production 10-authority and 134-edge state conserved; zero new cuts | C3 | conservation-authority-graph.tsv |
| AC47 | Parser/lexer identity, known non-greens and hermetic prefix conserved | C3 | baselines.txt |
| AC48 | gate-fast/gate-push, F14/append-only/closure/patch hygiene executed with correct status | C3 | factory-and-gates.txt |
| AC49 | AC01–AC49 evidenced, handoff plan scope exact, no M2 or SLICE10 claim | C3 | mandatory-50-ac-status.tsv |
| AC50 | External read-only post-CLOSE terminality on terminal HEAD, gates and clean tree PASS | POST_CLOSE | EXTERNAL-TERMINALITY-RECEIPT.txt |

## 8. Expected evidence tree and replay interface

```text
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01/
  c0/
    entry-identity.txt predecessor-terminal-and-freeze.tsv
    production-authorities.tsv baseline-graph.tsv baseline-provenance.tsv
    baselines.txt baselines-raw.txt five-reds.tsv
    frozen-50-ac.tsv frozen-24-controls.tsv eligibility-and-ranking-contract.md
  c1/
    source-roster.tsv semantic-sites.tsv core-family-reconciliation.tsv
    blocked-and-unknown.tsv ownership-dependencies.tsv recovery-boundaries.tsv
    edge-mut-0137-audit.tsv bundle-registry.tsv bootstrap-reachability.tsv
    candidate-oracle-plan.tsv candidate-mutant-plan.tsv producer-and-rollback-plan.md
    entry-to-c1-scope.tsv
  c2/
    verifier-selftest.tsv eligibility-checker-output.tsv ranked-candidates.tsv
    independent-ranking.tsv selected-core-bundle.tsv selected-core-causality.md
    c-mutation-restoration.tsv selected-core-bundle-contract.md
    prospective-graph-impact.tsv
  c3/
    independent-source-object-roster.tsv independent-eligibility-rank.tsv
    independent-causality.tsv control-execution-join.tsv negative-controls-raw.tsv
    control-verifier-selftest.tsv conservation-authority-graph.tsv
    baselines-raw.txt baselines.txt factory-and-gates.txt
    mandatory-50-ac-status.tsv predecessor-freeze-recheck.tsv
  c4/
    terminality-plan.txt
```

The actual C0/C1/C2 contracts may name extra evidence artifacts where
necessary, but each added file must be source/commit/object addressable and
inside this namespace. The verifier must not rely on opaque prose summaries or
hardcoded aggregate PASS totals. Makefile replay targets, if added, must be
additive, require explicit inputs and work in isolated build roots; make -n,
actual object inputs, and a negative missing-object test prove the effective
prerequisite graph.

Minimum replay outputs:

```text
RECON01_STATUS=PASS|HALT
ENTRY_IDENTITY=PASS|FAIL
PRODUCTION_AUTHORITIES=10
PARSER_AUTHORITIES=9
CPA_AUTHORITIES=1
PRODUCTION_GRAPH_BASE_NODES=52
PRODUCTION_GRAPH_BASE_MANDATORY_EDGES=134
PRODUCTION_PROVEN_CUTS=1
PRODUCTION_SCC_COUNT=34
PRODUCTION_SCC_LARGEST=19
E_MUT_0137_VERDICT=VERIFIED|UNSUPPORTED_WITNESS|UNDETERMINED
CORE_CANDIDATE_ROSTER_COUNT=<derived>
CORE_ELIGIBLE_BUNDLE_COUNT=<derived>
SELECTED_BUNDLE=<source-derived ID or NONE>
SELECTED_SEMANTIC_MUTATION_QUALIFIED=YES|NO
PRODUCTION_SEMANTIC_DELTA=0
NEW_PRODUCTION_AUTHORITIES=0
NEW_PRODUCTION_GRAPH_CUTS=0
NEGATIVE_CONTROL_PASS_COUNT=<actually executed>
AC01_TO_AC49=PASS|FAIL|UNPROVEN
AC50=DEFERRED_UNTIL_EXTERNAL_RECEIPT
SELFHOST_M2_ACHIEVED=NO
```

The printed metrics are required only when reproduced by the actual checkout and
evidence. On mismatches, emit actual values and HALT, not the expected
constants.

## 9. Explicit HALT classes

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_EVIDENCE_UNAVAILABLE
HALT_FROZEN_EVIDENCE_OR_F14
HALT_PRODUCTION_AUTHORITY_BASELINE_MISMATCH
HALT_GRAPH_BASELINE_OR_PROVEN_CUT_MISMATCH
HALT_UNAUTHORIZED_SOURCE_OR_SCOPE
HALT_UNPROVEN_SOURCE_OBJECT_REACHABILITY
HALT_CANDIDATE_ROSTER_INCOMPLETE
HALT_UNSAFE_ABI_OR_OWNERSHIP_BOUNDARY
HALT_UNSAFE_RECOVERY_OR_CALLBACK_BOUNDARY
HALT_NO_ELIGIBLE_CORE_BUNDLE
HALT_NO_CAUSALLY_QUALIFIED_CORE_BUNDLE
HALT_NONSEMANTIC_OR_DIAGNOSTIC_ONLY_WITNESS
HALT_MUTANT_BUILD_OR_OBJECT_PROVENANCE
HALT_MUTANT_NOT_RESTORED
HALT_ELIGIBILITY_OR_RANK_RECOMPUTE_MISMATCH
HALT_NEGATIVE_CONTROL_NOT_SENSITIVE
HALT_BASELINE_OR_GATE_REGRESSION
HALT_FACTORY_V2_APPEND_ONLY_OR_TRAILERS
HALT_POST_CLOSE_TERMINALITY
```

A HALT may still preserve findings and a proposed enabling next ACT, but it
cannot label selection PASS or migrate any source. Record completed phases,
actual failure class, unresolved AC/control IDs, evidence paths and exact next
bounded prerequisite. Do not waive known non-green historical failures or
weaken the gates to obtain PASS.

## 10. HANDOFF and programme-level implications

The selected successor contract must distinguish explicitly:

- Already executed C-authority mutation from this reconnaissance, with its own
  execution ID, original source Git blob, changed object and causal channel.
- Future PolyC-source mutation after production authority transfer; never
  backdate, substitute or count the C mutant as that future experiment.
- The actual C/PolyC ABI ownership boundary (opaque borrowed object handles only
  for proven object families; no general signed List payload or unsafe callback/
  recovery claim).
- Genuine C-only G0, three distinct PolyC producer executables G1/G2/G3,
  stage0 OFF, selector ON/OFF provenance and object-level linkage/branch proofs
  required in a future implementation ACT.
- An expected bundle-level authority retirement count as a hypothesis, not
  migration credit, and a canonical source-based path for observing each
  decision.
- A fresh source-derived graph impact forecast and which, if any, current SCC
  edges could be retired after execution. An edge has not been cut because an
  interface was proposed.
- A real bootstrap-critical contribution, without claiming first self-hosted
  generation, reduced remaining ACT count, or bootstrapped compiler independence
  without actual generation proof.

The success criterion is one frozen coherent core semantic successor, even if
the 19-subsystem SCC does not yet split. Do not pick an easy single boolean
predicate merely to add an authority.

Proposed next class, if PASS:
ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 (name to be frozen according to
measured bundle; not authorized for execution here). If HALT: a narrowly
justified ABI_FOUNDATION prerequisite that unblocks the measured best core
candidate. No SLICE10; no production migration; M2 not achieved.

## 11. Execution directive for ClineMM

Execute ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01 using this complete
Markdown as the binding Factory-v2 authorization. Start at main
eb5eb78524fecc875c1629ffa0e448926a45c75b with tree
6ae357df1113e4c80c29201b7e27417518107371; HALT on mismatch without
resetting. Preserve ten existing PolyC authorities and the production graph's
only proven cut E-TYP-0136. Perform a source/object-derived core semantic
census, audit disputed E-MUT-0137 without rewriting history, create and
independently reproduce a deterministic E01–E14/R0–R6 bundle selection, and
execute a genuinely rebuilt real-compiler C-source causal mutation on the
selected core semantic decision. Freeze exactly one bundle with ABI, G0,
fixture, producer and future post-migration PolyC-mutation obligations. Run
24 reason-specific negative controls and 50 AC checks; conserve all historical
identities; serialize compiler/gate runs; close with exactly one Factory-v2
terminal CLOSE and an external post-CLOSE receipt. No production source edits,
new authority, new dependency, new Python, branch ceremony, graph-cut claims,
or SLICE10 authorization. If no safe causally qualified core bundle exists,
HALT with actual evidence and the narrow enabling-ABI successor.

END OF AUTHORIZATION ARTIFACT.
