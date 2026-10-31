# ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT — not an execution or closure report
Class: SELFHOST / CORE_SEMANTIC / BUNDLE_SELECTION / SOURCE_AND_OBJECT_RECONNAISSANCE
Priority: P0
Prepared: 2026-10-31
Repository: existing canonical local PolyC checkout (s1onique/polyc); remote access is not assumed
Branch: existing main; do not create a per-ACT branch
Expected ENTRY_HEAD: c05a028276ac3eff3976c113c16b220c7de1331a
Expected ENTRY_TREE: 47283adc6df6c6494ea636a193021856c1f8b364
Binding predecessor: ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01, local five-commit CLOSE/PASS (executor-reported)
Expected pre-entry publication state: five predecessor commits are local; origin/main reportedly remains at 030e115ce8ed14ce41eacc3019e8787bad06ebfb
Source-derived production authority baseline: 13 decision sites (9 parser, 1 CPA, 3 core operators), subject to the C0 independent proof audit
Production mandatory graph: 52 nodes / 134 active edges / 34 SCCs / largest SCC 19
Proven historical cut: E-TYP-0136 only; E-MUT-0137 remains UNSUPPORTED_WITNESS
Known parser baseline: 376/376 over 90 files, sequence MD5 b6f117eb1386ca80f81bc06226e2a741
Selected next bundle: NONE at entry
Authorized production migrations: ZERO
New production authorities: ZERO
SELFHOST_M2_ACHIEVED=NO; SLICE10_AUTHORIZED=NO

## 0. Mission and boundaries

Select exactly one evidence-backed, coherent, bootstrap-relevant core-semantic migration bundle, preferably in type analysis, IR construction/transformation, CFG, or native code generation. This is a fresh source/production-object census and selection, not permission to copy an earlier list, select the easiest scalar predicates, or migrate the next parser sub-slice by default.

The central advancement over RECON01 is that the selection must demonstrate compiler semantic consequence and an executable migration boundary for multiple related live decision sites, with a credible path toward reducing C-owned compiler semantics. It must not assume a reduction in shared-layout dependency graph edges or the 19-subsystem SCC.

Required outcome is one of:
- PASS_SELECTED_CORE_BUNDLE: one eligible multi-site bundle passes every gate, is independently ranked, is causally demonstrated site-by-site, and has a frozen successor contract.
- HALT_NO_ELIGIBLE_CORE_BUNDLE: no bundle meets the frozen criteria; complete evidence and blockers, no fake selection.
- HALT_PREDECESSOR_PROOF_OR_IDENTITY: the prerequisite local predecessor identity, authority proof, or required raw evidence cannot be established.
- Another explicit, measured HALT from §9.

A source function, a compiled PolyC symbol, a decision site, an authority, and a graph dependency edge are different accounting units. Do not substitute one for another.

### 0.1 Required PASS predicates

1. Entry and predecessor binding verified against actual Git objects and actual local production compiler, with no force-reset/fetch/rebase to manufacture identity.
2. The open M-POLYC-RO witness attribution is independently reconciled from actual predecessor C3 raw files, not the HANDOFF summary; a genuine selector-OFF full compiler is also proven. If either remains unproven, report it and HALT before declaring a complete 13-authority baseline.
3. Fresh linked-core census identifies semantically meaningful, not-yet-PolyC-authoritative sites and all source/object/ABI/ownership/recovery constraints. No arbitrary eligibility input.
4. Exactly one selected multi-site bundle; independent selection, demonstrated C causality for each claimed site, a safe and bounded future PolyC/C ABI, and a frozen future implementation contract.
5. No production semantic change, no new authority or graph cut, all historical failures preserved, canonical gates green, 24 adverse controls reason-specifically sensitive, 50 mandatory acceptance criteria, and terminal Factory-v2 CLOSE with external verification.

### 0.2 Explicit non-goals

No production delegation, new compiler runtime feature, ABI refactor, source-level cleanup, changing legacy functions, fixing E-MUT-0137, fixing assembly-temp races, repairing historical ACT files, or self-hosting/M2 claim. No canonical migration candidate is preauthorized. RECON02 cannot retroactively certify a failed RECON01 causal obligation.

## 0.3 C0 outcome recorded during execution

The C0 phase executed the §1.2 predecessor-proof audit and produced a
**measured** result that changes the shape of this ACT. It is recorded here
because the ACT document is the authorization artifact and the binding
predecessor proof is an input to it.

`PREDECESSOR_RO_PROOF = UNPROVEN_AS_RECORDED`.

The predecessor's recorded `M-POLYC-RO` experiment did **not** mutate
`AbiCoreIsRangeOperator` (SITE-RANGE-OPERATOR). It mutated
`AbiCoreIsValidPointerOperator` (SITE-VALID-POINTER-OP). This is proved by
digest identity, not by inference:

| Predecessor record | Predecessor digest | Recomputed mutation | Recomputed digest | Match |
|---|---|---|---|---|
| pristine subject object | `b9a76fe8a23b38468e78b67ed428226592fa270347674299c1be1be57f4de756` | pristine | `b9a76fe8a23b38468e78b67ed428226592fa270347674299c1be1be57f4de756` | YES |
| M-POLYC-CA mutant source | `cea1ca063884dd5ebf4019110cd36816ae4950cc8fef9ceb2621a2f126cfdae1` | CA mutation | `cea1ca063884dd5ebf4019110cd36816ae4950cc8fef9ceb2621a2f126cfdae1` | YES |
| M-POLYC-PO mutant source | `f61d7ea0b50aabedc6db9377909f16c16dfac9dac33767477a73be563278a4b4` | PO mutation | `f61d7ea0b50aabedc6db9377909f16c16dfac9dac33767477a73be563278a4b4` | YES |
| M-POLYC-PO mutant object | `af566dfb6f184898942ae5138c4f2662b259a33d259ce0807612d1544854b58a` | PO mutation | `af566dfb6f184898942ae5138c4f2662b259a33d259ce0807612d1544854b58a` | YES |
| **M-POLYC-RO mutant source** | **`f0599f79900cf406415283a9742c2b3d794c03f107e7a959ce021db91b916615`** | **PO-LT mutation (LT removed from `AbiCoreIsValidPointerOperator`)** | **`f0599f79900cf406415283a9742c2b3d794c03f107e7a959ce021db91b916615`** | **YES** |
| **M-POLYC-RO mutant object** | **`2d6a1394dffa8b513af092971338692e113cbf893c4d52a0b554afda9d58c1f8`** | **PO-LT mutation** | **`2d6a1394dffa8b513af092971338692e113cbf893c4d52a0b554afda9d58c1f8`** | **YES** |
| (no predecessor record) | — | RO mutation (LT removed from `AbiCoreIsRangeOperator`) | `dc068867b66ded3786531b3755a99438334ef4438d1ab658051337082f88b3d1` / `c73e734dc6b735bd738fd2e3f5735f10b577d5048730d586d2892b153ca77eff` | NOT RECORDED |

Four of the five recomputed source digests are **bit-identical** to the
predecessor's records, so the one mismatch is not a build-environment
artifact. The predecessor's `mutation-diffs/M-POLYC-RO.diff` is a
transcription of the *intended* mutation, not the mutation that was compiled.

Consequences, all measured:

- The 13-authority **count** is structurally verified: all 13 sites are
  defined exactly once and imported by exactly one caller object in a
  freshly built production compiler.
- The 13-authority **causal backing** is not: SITE-RANGE-OPERATOR
  (AUTH-13) has no executed causal experiment in the predecessor.
- The recorded `site-isolation.tsv` row for `M-POLYC-RO` is false as
  written. No RO mutation changes `witness-po-pointer-less-than`, and no
  mutation changes it except a PO-site mutation.
- The range site is nevertheless **genuinely live**: a discriminating
  chained-range witness (`5 < 1 < 3`) changes the program's exit status
  from 0 (pristine, range lowering active) to 1 (RO mutation, range
  lowering removed), while the PO mutation leaves it at 0. The predecessor's
  own witness (`1 < 2 < 3`) is **not discriminating**: both lowerings agree
  for that input.

Per §1.2 of this ACT, an unproven predecessor RO proof requires
`HALT_PREDECESSOR_PROOF_INCOMPLETE` **and** a separate append-only
evidence correction. §9 forbids writing that correction experiment under
this reconnaissance, and F14 forbids editing predecessor evidence.

## 1. C0 entry gate — proof before ranking

### 1.1 Identity and publication boundary

Record the exact output of:
```
pwd
git branch --show-current
git rev-parse HEAD HEAD^{tree}
git status --porcelain=v1
git replace -l
git rev-list --count 030e115ce8ed14ce41eacc3019e8787bad06ebfb..HEAD
git log -5 --format='%H%x09%s%n%b'
git show --no-patch --format='%B' HEAD
# Inspect origin/main only if the ref exists locally; no fetch required:
git show-ref --verify --quiet refs/remotes/origin/main && \
  git merge-base --is-ancestor origin/main HEAD && \
  git rev-parse origin/main || true
```
- Expected local HEAD/TREE exactly as header; main, clean tracked/index and no untracked ACT residue, zero replace refs, predecessor last commit CLOSE/PASS, exactly 5 matching Factory-v2 phase/trailer commits from RECON01 CLOSE.
- origin/main lag is not a defect. Never push, rebase, pull, reset, amend or rewrite the unpublished predecessor in this ACT. No origin reachability assumption.
- For all closed predecessor ACTs, snapshot a path-and-hash F14 manifest. The new ACT must not alter their bytes. Differentiate tracked files from untracked leftovers explicitly.
- A mismatch is terminal HALT_ENTRY_IDENTITY, never silently repaired.

### 1.2 Predecessor proof integrity — mandatory separate audit

Inspect actual committed bytes under:
```
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c1/scope-and-mutant-plan.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c1/semantic-witnesses.md
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/mutant-ro.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/site-isolation.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/semantic-conservation.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/mutant-po.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/c-off-on-dormancy.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c2/selector-build-matrix.tsv
evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c1/g0-oracle-build.txt
```
Reconstruct, independently and by exact site ID:
- M-POLYC-RO changed the range-operator rule (AST_BIN_OP_LT in AbiCoreIsRangeOperator), compiled into a changed live production subject/object and produced the frozen range-specific W-RO semantic channel. Verify its original C1 expectation, intended output, actual C3 observation and restored state. Investigate HANDOFF's surprising W-PO-LT attribution; verify no accidental use of a pointer-operation witness as range proof.
- Site-isolation controls demonstrate other sites' outputs/fixtures remained unaltered by the RO-only mutation. No reuse of M-POLYC-PO's physical execution identity.
- An actual selector-OFF whole production compiler existed, with live legacy C rules and zero subject imports. A standalone copied C oracle is insufficient by itself. Use actual build objects/link line and C-OFF/C-ON dormancy evidence.
- AST_BIN_OP_MUL=0: source-derived implicit enum zero is recovered as numerical zero, not treated as unknown because of a blank TSV cell. Record an independent check of c1/enum-domain.tsv.
- All 13 reported prior authorities remain reachable and active in a newly built production compiler. A symbol-only count is insufficient.

Produce PREDECESSOR_RO_PROOF=VERIFIED_INDEPENDENT or UNPROVEN_AS_RECORDED with explicit reason, source and execution IDs. If unproven, stop with HALT_PREDECESSOR_PROOF_INCOMPLETE and propose a separate append-only evidence correction. Do not write a new correction experiment under this reconnaissance, and never edit predecessor evidence.

### 1.3 Fresh conservation baseline

Use isolated, fully specified install/test prefixes, reconstruct fresh binary/object identities, and serialize compiler builds. Measure:
- parser 376/376 over 90 files, frozen assertion-sequence MD5;
- lexer07/08/09 direct 89/89, 45/45, 23/23;
- broad LEXER07 FAIL_KNOWN_BASELINE 15 identities / MD5 7ee761440de83552e751e3c3976c1683;
- cross-target prefix 67 FAIL_ENVIRONMENT_PREFIX (if still applicable); F-NO-PYTHON 12 historical/0 new; F-POLYC-TOOLS UNAVAILABLE unless the checker actually landed;
- ten-plus-three live PolyC authority objects/callers, 52/134 graph, 34 SCC / largest 19;
- gate-fast/gate-push baseline as appropriate; do not mislabel failure identities green.

The previously repaired test-prefix-install CMake argument chain must be checked for effective -D propagation (not just command text). A configure that exits zero while ignoring an essential selector is a failure.

### 1.4 Five genuine RED observations

Record five reproducible entry-state deficiencies and their detector anti-controls:
```
RED	Unmet property at entry	Required sensitive observation
RED-01	No RECON02 fresh source/object core bundle roster	Missing roster detected, existing RECON01 roster positively found
RED-02	No selected RECON02 migration successor	Missing frozen successor detected, prior selected contract positively found
RED-03	No independently qualified all-site core semantic causal evidence for future bundle	Missing per-site executions detected; prior CA/PO/RO records findable
RED-04	No ABI/ownership cut contract for the new candidate	Unbound typed/state boundary rejected; prior ABI-CORE-OP-1 positively found
RED-05	No new bootstrap-criticality/graph-impact justification	Missing machine-joined M2 path evidence rejected; historical baseline graph measurable
```

A RED is not proved by printing RED_CONFIRMED; it must inspect an actual file/object/state and show the detector changes on the specified positive/negative control.

## 2. C1 — Fresh compiler-core semantic census

Census must follow the actual production build graph, not only the names of C source directories. Include actual active call paths in src/ for parser, type analysis, AST semantics, IR/CFG, optimization/transforms if present, assembler/backend, and compiler driver. Only include subsystems proven to exist and link. Exclude vendored line-editing, optional diagnostics and unlinked code from bootstrap-critical work with explicit reasons.

### 2.1 Source/object site ledger

Inventory coherent decision sites and host state transitions, with one row per semantic authority (not per C function). Every row contains:
```
site_id  repo_source_path  git_blob_oid  byte_range_or_line_range
source_range_sha256  enclosing_function  C_object_id  production_linked
caller_ids  imported_symbols  semantic_effect  witness_channel
input_types  output_types  host_state_read  host_state_write
ownership  allocation  callback  recovery  longjmp_boundary
predecessor_polyc_authority  graph_edge_ids  M2_reachability
supported_abi_shape  exclusion_reason  classification
```
Each source_range_sha256 must be recomputed from a frozen Git blob and physical bytes; detect stale ranges and overlapping source ranges. The row must have an independently linkable production function or meaningful embedded decision with a source-derived caller.

Classification set: C_CORE_SEMANTIC, POLYC_AUTHORITY, C_MECHANICAL_ADAPTER, C_NONBOOTSTRAP, EXTERNAL, BLOCKED_STATEFUL, UNKNOWN. Do not count unknowns as eligible or migrated.

### 2.2 Dependency and ownership graph

Start from the committed 52-node / 134-edge active mandatory graph and the E-TYP-0136 historical cut; recompute it independently from actual source/link evidence. Mark E-MUT-0137 UNSUPPORTED_WITNESS until separately proven. Do not remove it as a second demonstrated production cut or silently upgrade its supporting text.

For candidate sites, add exact edges for shared layout, mutable-state ownership, tokens, maps, AST graph, IR/CFG mutation, recovery, callbacks and producer link requirements. Record whether an edge is EXISTING, NEWLY_PROVEN, CANDIDATE_ABI_CUT_NOT_EXECUTED, or UNSUPPORTED. Compute SCC/condensation independently. No count of graph cuts is authorized by this reconnaissance.

### 2.3 Candidate bundles

Derive a non-empty candidate registry only if source warrants it. Preferred bundle size: 2–6 related live semantic sites under one coherent ABI/ownership transition, spanning at least one real type/IR/codegen consequence. Alternatives may include a single substantially larger function boundary only if that is the only defensible dependency cluster; such a case must be marked EXCEPTION_SINGLE_BOUNDARY and cannot satisfy an unqualified multi-site selection PASS without explicit recorded rationale and a separate decision by the frozen eligibility policy.

For every candidate record the exact membership, why sites should migrate together, why separation would require repeated state bridging, shared transaction/rollback semantics, scope, recovery boundaries, downstream consumers, possible compiler generations and cost of authoritative migration. A bundle is not coherent merely because its functions are in the same file or share an enum.

Never preselect parseExpr, CFG, IR, codegen or any named function. Those are census categories, not guaranteed eligible targets.

## 3. C1 eligibility and candidate-cost contract (freeze before ranking)

Implement an explicit 16-predicate boolean eligibility contract, applied to each site and bundle. No mutable caller-supplied eligible flags.
```
ID	Mandatory qualification
EL-01	Exact stable candidate/bundle ID and source SHA from live compiler bytes
EL-02	All sites production-linked, reachable and presently C-semantic-authoritative
EL-03	At least two sites with nonduplicated semantic effects (or explicit single-boundary exception, non-PASS by default)
EL-04	Cross-site coherence proven by shared semantic transaction, ABI or dependency cut boundary
EL-05	At least one typed/IR/CFG/object/runtime consequence, not diagnostic-only
EL-06	Direct or indirect measured bootstrap M1/M2 reachability; not just parser proximity
EL-07	Each site has a genuine independent C oracle, not a handmade oracle alone
EL-08	ABI inputs/output/status representable in the current PolyC compiler or a bounded proven host ABI
EL-09	Host retains well-defined ownership, allocation, mutation atomicity and lifetime until separately migrated
EL-10	No forbidden nonlocal recovery through a PolyC frame; callbacks either forbidden or explicitly safe
EL-11	Exact error/status, out-parameter and scalar-zero semantics preserved
EL-12	Every site has a plausible, independently observable causal mutant and witness
EL-13	Real production build and producer G0–G3 paths definable; stage0 not cyclic
EL-14	Original C selector-OFF branch can remain independent and be proven load-bearing
EL-15	Candidate and control evidence can be independently re-derived; no source/phase mismatch
EL-16	No preexisting PolyC authority duplication, excluded vendored code or prohibited new dependency
```
Each row: PASS, FAIL, or UNPROVEN, with source/object/evidence path and detector. UNPROVEN is ineligible. Freeze the schema and scoring before computing rankings. The canonical ranker may be reused only if its semantics match the new scoring; otherwise use a new, versioned, reproducible PolyC ranker with a frozen spec. Do not silently treat parser R0–R6 as a core-bundle ranking contract.

### 3.1 Ranking for eligible bundles

Compute deterministic lexicographic BR0..BR7:
1. BR0 measured M2 bootstrap critical-path proximity (strongest first).
2. BR1 in-scope compiler semantic effect (IR/codegen > type acceptance > parse semantics; justify actual meaning).
3. BR2 number of independently proven nonduplicate decision sites (prefer coherent bundle, capped to prevent inflating sites).
4. BR3 measured potential ABI/ownership-cycle resolution, counterfactual only; never credit as production cut.
5. BR4 number/severity of unsafe ownership/recovery blockers (fewer first).
6. BR5 size/complexity of required cross-language ABI (smaller safer boundary first).
7. BR6 quality/diversity of already executable compiler semantic witnesses.
8. BR7 deterministic stable ID and source-hash tiebreak.

Every ranking input must be joined from measured C1 facts and frozen eligibility checker output, never copied from a mutable ranker's eligible column. An independent PolyC recomputer must derive entire eligibility and ranking from raw C1 facts without reading the primary result columns.

If high-rank candidates are rejected after real source review or failed causal experiments, retain their original rank plus a reason-specific disqualification; do not pretend they were never ranked. If all fail, HALT.

## 4. C2 — Executable candidate qualification and frozen successor

### 4.1 Site-by-site C-source causality

For the first eligible bundle in ranked order, execute one distinct, bounded C-source adverse mutation per claimed decision site, not one mutation for an entire site list:
1. Create a disposable detached Git worktree at frozen C1 source identity. Never mutate authoritative main; isolated build, install and temporary directories, including ASM temp output.
2. Freeze pristine source blob, selected range hash, produced production caller-object hash and complete compiler binary digest.
3. Apply one-token or otherwise minimal source mutation to only the selected C semantic decision; record exact diff and source hash; no mutation of diagnostic printing unless diagnostic behavior is the only effect of a genuine semantic decision.
4. Build the actual full production compiler successfully, independently verify changed caller object and linked decision reachability.
5. Run a source-bound compiler witness. Observe a supported semantic channel: accepted/rejected status with a meaningful type/range/IR reason, changed emitted IR/object, or changed compiled-program output. A build failure or a diagnostic-only string change without semantic effect is not sufficient.
6. Restore source byte-identically; recompile and verify original compiler object, witness output, and no mutated worktrees remain.
7. Repeat for every site with a different execution ID and site-specific discriminator. Where a mutant changes more than its own site, identify overlap and disqualify if independent attribution fails.

A failed mutant shape may be retained as UNQUALIFIED_BUILD_FAILURE and replaced by a bounded alternative; never call it a successful causal experiment. Cap mutation search to an explicit C1 frozen budget of at most three planned shapes per site; no indefinite fishing. If no qualifying mutant exists for one required site, reject the whole bundle and consider the next-ranked bundle within a frozen exploration cap of three bundles. If none qualify, HALT.

### 4.2 ABI and migration-boundary feasibility

Freeze for each selected site: exact C caller, proposed PolyC export, input projection order/conditional reads, output/status domains, side effects remaining in C, memory ownership, failure atomicity, lifetime, callbacks, recovery, typed-layout edges, producer dependencies and rollback path.

If mutable state crosses the bridge, specify a checked handle/host-operation sequence and run a bounded isolated ABI probe only if necessary to prove feasibility. This ACT cannot modify the normal production semantic owner. Do not infer source-TU graph cuts from a standalone ABI prototype. An unsafe ABI means candidate ineligible; do not invent pointer-bitcasts or longjmp crossing PolyC frames.

### 4.3 Source-bound future G0–G3 contract

Freeze C-OFF object-level oracle and link separation; actual producer executables and expected distinct digest identities; new component object provenance; coverage-complete source-derived fixture partitions; one post-migration PolyC-source mutant and C-dormancy anti-control per site; expected pristine/mutated/restored semantic channels. Real future PolyC mutations are not executed as production transfers in RECON02.

### 4.4 The single selected successor

Only if §4.1–4.3 pass, write:
```
SELECTED_BUNDLE_ID=<source-derived stable ID>
SELECTED_SITE_IDS=<exact stable set>
SELECTED_SOURCE_OIDS=<full OIDs>
SELECTED_RANGE_SHA256=<per site>
SELECTED_ABI_VERSION=<new bounded contract ID>
SELECTED_G0_ORACLE=<real production object provenance>
SELECTED_MUTANT_EXECUTION_IDS=<one per selected site>
SELECTED_COMPILER_WITNESSES=<one independently attributable per site>
SELECTED_GRAPH_IMPACT=COUNTERFACTUAL_ONLY
PRODUCTION_GRAPH_CUTS=0_NEW
NEXT_ACT_CLASS=CORE_SEMANTIC_BUNDLE_IMPLEMENT
NEXT_ACT_STATUS=PROPOSED_NOT_AUTHORIZED
```
An empty, incomplete or inconsistent selection cannot be represented as PASS. Do not authorize production implementation by writing a proposed ACT name.

## 5. C3 — Independent verification and conservation

A separate, newly compiled PolyC verifier independently reconstructs:
- function/caller/semantic-site roster, source SHA and inclusion/exclusion;
- exact site↔bundle set joins; EL-01..16 and BR0..BR7 order for every eligible candidate;
- selected causal experiment identities and pristine/mutant/restored object + witness proofs;
- ABI safety and G0/G1/G2/G3 future producer feasibility;
- 52/134 production graph baseline (unless the actual source evidence proves a census correction requiring explicit qualification), historical cut only E-TYP-0136, 34 SCC / largest 19;
- no changed production source, no previously closed ACT bytes changed, 13 existing authority sites conserved;
- all 24 NCs and 50 ACs joined by exact ID, not summary arithmetic.

Use an independent implementation route for census/control recomputation (for example bounded POSIX awk/`sh` over Git objects plus independent PolyC auditor). Do not duplicate the same normalization function and claim independence. Tooling must be real PolyC for new substantive verifiers; bounded shell/AWK evidence drivers permitted. No Python.

Preserve parser, direct lexers and historical broad/prefix/non-Python identities. Run make gate-fast, serialized make gate-push, append-only, F14, patch hygiene, closure-status, commit-trailer checks, Factory-v2 range check. C3 may record the in-progress range as NOT_TERMINAL_EXPECTED but not PASS until CLOSE. A known baseline may remain non-green only with identical source-derived failure identities.

### 5.1 Build isolation

Build in independent roots and install prefixes; no parallel compiler invocations sharing /tmp/holyc-asm.s. Check effective, expanded Make prerequisites and actual CMake generated producers—not merely text declarations. GNU Make's first-phase prerequisite expansion and CMake OUTPUT/`DEPENDS` relationships are explicitly relevant. Freshness/stale-object, missing-subject and ignored-exit-127 controls must fail closed. Do not fix the assembly-temp race inside this reconnaissance.

## 6. Frozen 24 negative controls (each executed and reason-specific)

```
ID	Adverse input / experiment	Required detector
NC-01	Wrong entry HEAD, TREE, branch or predecessor CLOSE	ENTRY_IDENTITY_MISMATCH
NC-02	Change frozen predecessor path digest	F14_FROZEN_PATH_TAMPER
NC-03	Attribute M-POLYC-PO execution to M-POLYC-RO	PREDECESSOR_CAUSAL_ID_MISBIND
NC-04	Replace real C-OFF compiler with copied oracle only	PREDECESSOR_G0_NOT_PRODUCTION
NC-05	Treat blank implicit enum zero as unknown/positive	SOURCE_ENUM_ZERO_NORMALIZATION
NC-06	Include unlinked or vendored function as M2-core authority	CENSUS_PRODUCTION_REACHABILITY
NC-07	Forge candidate source range/hash or later-phase blob	SOURCE_PHASE_RANGE_HASH_MISMATCH
NC-08	Drop/duplicate a site or bundle membership ID	BUNDLE_SITE_SET_INTEGRITY
NC-09	Promote site already PolyC-owned	ALREADY_MIGRATED_SITE_INELIGIBLE
NC-10	Forge eligible=YES with missing EL clause	ELIGIBILITY_FACT_JOIN_FAILURE
NC-11	Change one BR rank key or tie order	RANK_ORDER_MISMATCH
NC-12	Claim diagnostic-only behavior as compiler semantic effect	CORE_SEMANTIC_EFFECT_MISSING
NC-13	Give candidate M2 criticality without bootstrap linkage	BOOTSTRAP_REACHABILITY_UNPROVEN
NC-14	Use unowned raw AST/IR pointers as an ABI without ownership proof	ABI_OWNERSHIP_UNSAFE
NC-15	Introduce unsafe callback or cross-PolyC-frame longjmp	ABI_RECOVERY_BOUNDARY_UNSAFE
NC-16	Alias status with scalar result, including zero operator	ABI_RESULT_STATUS_COLLISION
NC-17	Use same C-source mutation/witness for every bundle site	CAUSAL_EXECUTION_DOUBLE_COUNT
NC-18	Accept mutant full-compiler build failure as semantic change	CAUSAL_BUILD_FAILURE_MISCLASSIFIED
NC-19	Accept mutant changed text but unchanged linked caller object	CAUSAL_MUTANT_DORMANT
NC-20	Fail to restore mutant source/object/witness	CAUSAL_RESTORATION_FAILURE
NC-21	Remove graph edge based solely on proposed ABI	SPECULATIVE_PRODUCTION_GRAPH_CUT
NC-22	Treat E-MUT-0137 unsupported witness as proven cut	UNSUPPORTED_GRAPH_WITNESS_PROMOTED
NC-23	Missing/late Make prerequisite or ignored CMake flag returns green	BUILD_GRAPH_FALSE_GREEN
NC-24	Fake AC PASS, omit control, reclassify historical FAIL or omit external terminality	AC_OR_BASELINE_FALSE_PASS
```

Each control has its own physical execution ID or explicitly disclosed shared physical experiment; avoid counting one execution twice as independent evidence. Record pristine → adverse → restored with exact source/evidence hashes. Control verifier must reject deletion, duplication, unknown ID, wrong reason, swapped executor ID and forged PASS; selftest controls cannot be no-op.

## 7. Exactly 50 mandatory acceptance criteria

Freeze AC01..AC50 verbatim at C0 with owner phase, evidence path, status and independent checker. NOT_RUN, UNPROVEN, DEFERRED, FAIL and PASS remain distinct. No missing evidence gets PASS.
```
ID	Phase	Binding acceptance predicate
AC01	C0	Exact entry HEAD/TREE, branch, clean index and zero replace refs
AC02	C0	Five-commit predecessor CLOSE/PASS and exact trailer range
AC03	C0	Predecessor F14 path freeze recorded and independently rehashed
AC04	C0	M-POLYC-RO and M-POLYC-PO experiment IDs independently disambiguated
AC05	C0	Range-specific frozen W-RO semantic proof matched to actual execution or explicit HALT
AC06	C0	Real whole-compiler G0 OFF and C-dormancy evidenced; copied oracle not substituted
AC07	C0	Implicit zero AstBinOp enum/ABI semantics reconciled
AC08	C0	Thirteen prior production decision authorities freshly validated by source/object/caller
AC09	C0	52/134 graph and single historical E-TYP-0136 cut rederived
AC10	C0	Five REDs executed; 50 AC/24 NC frozen with no duplicate IDs
AC11	C1	Fresh production source/object census includes all relevant compiler-core subsystems
AC12	C1	Every site has source OID/range SHA and actual caller/object reachability
AC13	C1	Current C/PolyC/mechanical/external/unknown authority classifications disjoint
AC14	C1	Vendored/unlinked/diagnostic-only exclusions have measured explanations
AC15	C1	Ownership, layout, graph mutation, callback and recovery dependencies inventoried
AC16	C1	E-MUT-0137 remains unsupported without evidence; no false cut credit
AC17	C1	Candidate bundle registry has exact distinct site membership and nonduplicate effects
AC18	C1	Every candidate has measurable compiler semantic effect and M2 reachability facts
AC19	C1	EL01..EL16 eligibility contract frozen with fact-source references
AC20	C1	BR0..BR7 deterministic ranking contract frozen before rank execution
AC21	C1	C-only real oracle and producer plan for candidate site set frozen
AC22	C1	Bounded per-site C mutation and real semantic witnesses planned
AC23	C2	Primary eligibility checker executes from actual C1 facts without forged flag trust
AC24	C2	Independent PolyC recomputer matches entire eligibility set
AC25	C2	Primary ranker orders all eligible bundles with stable ties
AC26	C2	Independent PolyC rank recomputation matches entire order, not only winner
AC27	C2	Highest qualified bundle chosen or lower-rank disqualification recorded honestly
AC28	C2	Every selected site has independent successfully linked C-source mutation
AC29	C2	Every selected site has real compiler semantic change, not failed build/diagnostic-only
AC30	C2	Every mutant and object/witness restoration byte-identical
AC31	C2	Site-by-site mutant identity/source/object/witness attribution joins exactly
AC32	C2	ABI version, typed inputs/outputs/status and conditional host reads fully specified
AC33	C2	Host ownership, atomicity, recovery and callback safety boundary documented/proven
AC34	C2	Future G0–G3 producer/object/provenance plan source-bound and non-cyclic
AC35	C2	Future PolyC-source mutation and C-dormancy anti-control specified for EACH site
AC36	C2	Single frozen successor bundle contract has exact IDs, blobs, digests and witnesses
AC37	C3	Independent verifier recomputes source/blob/site/bundle roster from raw facts
AC38	C3	Independent eligibility/ranking/control joins have zero missing/extra/duplicate IDs
AC39	C3	All 24 adverse controls fire their reason-specific detectors
AC40	C3	Verifier selftests reject missing IDs, forged PASS and swapped causal executions
AC41	C3	Real production semantic authority remains at pre-ACT 13, no new migrations
AC42	C3	Production mandatory graph remains without speculative new cuts or SCC credit
AC43	C3	Parser 376/376 and exact assertion-sequence MD5 conserved
AC44	C3	Direct lexer differentials and historical broad-corpus failure identity conserved
AC45	C3	Cross-target prefix, F-NO-PYTHON and F-POLYC-TOOLS statuses honest
AC46	C3	gate-fast, serialized gate-push, build installation and subject freshness PASS
AC47	C3	F14, append-only, patch hygiene and no forbidden source changes PASS
AC48	C3	Full C3 per-ID ledger 48 predicates independently evidenced, no vacuous PASS
AC49	C3	Terminal HANDOFF/ROADMAP/factory map/scope frozen; no new migration authorization
AC50	External	After C4 CLOSE, exact HEAD/tree/trailers, final gates, path freeze and all PASS conditions checked read-only
```

AC48 note: "48 predicates" means AC01–AC48; AC49 and AC50 retain their distinct obligations. At the C3 stage AC49 may become PASS when all C4 plans are frozen; AC50 must remain DEFERRED until the external receipt exists. A final PASS requires all fifty, irrespective of C3 scheduling.

## 8. Factory-v2 phase, commit and evidence contract

Exactly one linear, non-merge commit per phase. Validate every message with the repository's current factory-v2-commit-msg-check.sh before committing. Never amend, rebase or replay published commits; this ACT also prohibits rewriting the unpublished predecessor. If a phase fails, HALT with measured evidence and follow local Factory doctrine; do not force an extra unauthorized close/fix commit. Post-CLOSE read-only receipt stored outside the repository.

- **C0 — RED**: Identity, predecessor proof audit, 13 authority conservation, baseline, frozen 50/24 contract and five executed REDs. If predecessor proof fails, terminal HALT without selecting a successor.
- **C1 — EVIDENCE**: Fresh linked compiler-core census, dependency/ownership graph, source-derived bundle registry, complete EL and BR contracts, C-only oracle plan, per-site causal witness/mutant plan, permitted build paths and immutability manifest.
- **C2 — IMPL (recon tools only)**: Add a bounded PolyC quality verifier, run primary and independently computed eligibility/ranking, select up to three ranked bundles for capped causal qualification, freeze exactly one successor on success. The IMPL phase implements evidence tooling only; no production semantics.
- **C3 — EVIDENCE**: Execute the 24 controls and independent recomputation, measure conservation and all gates, populate AC ledger AC01–AC49, freeze full future implementation prerequisites. Negative controls run in isolated copies; mutations restore byte-identically.
- **C4 — CLOSE**: One ACT doc, HANDOFF, exact one-row map append, one bounded ROADMAP append, c4/terminality-plan.txt (explicitly a plan, not an external receipt). Commit with trailers:
```
ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02
ACT-Phase: CLOSE
ACT-Verdict: PASS
```
Only after committing the terminal CLOSE, run external read-only verification and store receipt under an untracked path outside repo. A PASS receipt must bind exact HEAD, tree, 5-commit range and final gate identities. For HALT, use the exact repository-authorized HALT trailer/disposition rather than inventing PASS.

### 8.1 Authorized paths

```
docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02.md
docs/factory/act-handoff-map.tsv       # one row only
docs/ROADMAP.md                        # bounded append only
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02/**
tools/quality/core-semantic-bundle-recon02-*.HC  # substantive tools only; PolyC
Makefile                              # additive targets ONLY if genuinely necessary
```
No `src/**`, `tools/bootstrap/**`, existing quality tools, existing tests, previous ACT docs/HANDOFFs/evidence, factory doctrine, lockfiles, dependencies, Python or prod build reconfiguration. Narrow non-substantive POSIX shell/AWK evidence drivers under this ACT's evidence tree are permitted; no 1000-line shell implementation masquerading as PolyC verifier.

### 8.2 Minimum evidence index

```
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02/
  c0/ entry-identity.txt predecessor-terminal.tsv predecessor-freeze.tsv
      predecessor-ro-attribution.tsv predecessor-g0-proof.tsv enum-zero.tsv
      authority-conservation.tsv graph-baseline.tsv baseline-raw/ five-reds.tsv
      frozen-50-ac.tsv frozen-24-nc.tsv
  c1/ production-core-source-roster.tsv semantic-sites.tsv bundle-registry.tsv
      candidate-dependencies.tsv ownership-recovery.tsv graph-edge-witness.tsv
      bootstrap-reachability.tsv eligibility-contract.tsv ranking-contract.tsv
      oracle-plan.tsv witness-and-mutation-plan.tsv source-phase-freeze.tsv
  c2/ eligibility-results.tsv ranker-results.tsv independent-ranking.tsv
      disqualified-ranked-candidates.tsv selected-bundle.tsv
      selected-successor-contract.md selected-abi.tsv selected-causality.tsv
      selected-generation-plan.tsv real-c-mutant-executions.tsv
      restore-and-object-provenance.tsv verifier-selftest.tsv
  c3/ independent-census.tsv independent-graph.tsv control-execution.tsv
      control-join.tsv control-verifier-selftest.tsv authority-conservation.tsv
      graph-after.tsv parser-conservation.txt non-green-conservation.txt
      gates-and-factory.txt ac01-ac49-ledger.tsv predecessor-freeze-recheck.tsv
  c4/ terminality-plan.txt
```
All required tables include an explicit source, physical_execution_id, status, reason, path, sha256 where applicable. Store large raw transcripts via bounded, hash-named evidence with exact replay command. Do not claim a tool PASS without real output.

## 9. Explicit HALT classification

```
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_EVIDENCE_UNAVAILABLE
HALT_PREDECESSOR_PROOF_INCOMPLETE
HALT_F14_FROZEN_PREDECESSOR_MISMATCH
HALT_BASELINE_CONSERVATION
HALT_NO_ELIGIBLE_CORE_BUNDLE
HALT_SOURCE_ROSTER_INCOMPLETE
HALT_SOURCE_PHASE_HASH_MISMATCH
HALT_ELIGIBILITY_OR_RANK_MISMATCH
HALT_BOOTSTRAP_REACHABILITY_UNPROVEN
HALT_STATEFUL_ABI_UNSAFE
HALT_CALLBACK_OR_RECOVERY_UNSAFE
HALT_C_ORACLE_NOT_PRODUCTION_INDEPENDENT
HALT_C_MUTANT_FAILED_TO_BUILD
HALT_C_MUTANT_DORMANT_OR_UNLINKED
HALT_C_MUTANT_DIAGNOSTIC_ONLY
HALT_SITE_CAUSAL_ATTRIBUTION_UNPROVEN
HALT_MUTATION_RESTORATION_FAILURE
HALT_PRODUCER_GRAPH_UNPROVEN
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_EVIDENCE_ID_JOIN_OR_FALSE_PASS
HALT_PARSER_LEXER_OR_GATE_REGRESSION
HALT_FACTORY_V2_APPEND_ONLY_F14
HALT_EXTERNAL_POST_CLOSE_TERMINALITY
```
A HALT can preserve completed source census and correctly classified rejected candidates, but cannot claim a selected successor, 14th authority, graph cut or self-hosted compiler. Any remedy requiring production code, canonical test changes, predecessor correction or shared assembler temporary fix belongs to a separately authorized ACT.

## 10. Handoff and next authorized step

On PASS, HANDOFF must supply exact frozen bundle/site/ABI/producer/casual identity and evidence paths; indicate all forbidden unproved graph impacts; and propose (not authorize) ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-IMPLEMENT02 or a title derived from the selected actual dependency class. The successor must not invent source identities or treat RECON02 C mutations as post-migration PolyC mutations.

On HALT, HANDOFF reports the exact failing predicate and a bounded correction/recon proposal. No default SLICE10 selection. No publication or push as part of this ACT; the local predecessor and RECON02 commits may be published only through a separately authorized normal fast-forward process.

## 11. References and rationale

- GNU Make — How Makefiles Are Parsed: ordinary rule prerequisites expand while the rule is read, so late-defined objects can silently disappear from the dependency graph.
- Git — git-worktree: disposable detached worktrees enable adverse source mutations without editing authoritative main.
- CMake — add_custom_command: generated outputs and real file dependencies belong in the effective producer graph, not merely in comments or recipes.

The ACT's binding project facts are the local Git objects and committed predecessor evidence, not these general build-tool documents and not a public GitHub mirror. The public sources support only the procedural safeguards above.
