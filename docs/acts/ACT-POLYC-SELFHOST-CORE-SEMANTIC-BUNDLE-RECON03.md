# ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT — execution contract, not an execution report
Class: SELFHOST / CORE_SEMANTIC / BUNDLE_RECONNAISSANCE / CAUSAL_SELECTION
Priority: P0
Prepared: 2026-10-31
Repository: existing local PolyC checkout, reported as s1onique/polyc; remote availability not assumed
Branch: existing local main — no per-ACT branch
Expected ENTRY_HEAD: f850be2dbd175ed06cc8b3c6bed8ad261fbe3cbb
Expected ENTRY_TREE: e879d00fe7ed41da857dcd05c6e3c4d8fb3c199d
Immediate predecessor: ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01, reported PASS / PASS_EVIDENCE_SUPPLEMENTED
Earlier predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02, historical HALT_PREDECESSOR_PROOF_INCOMPLETE, not superseded technically
Production PolyC authorities: 13 structurally active; 12/13 with causal proof at IMPLEMENT01 CLOSE, 13/13 including later correction
Production graph: 52 nodes, 134 mandatory edges, 34 SCCs, largest 19; sole historical proven cut E-TYP-0136
Disputed edge: E-MUT-0137 = UNSUPPORTED_WITNESS, not a proven cut
Entry next bundle: NONE; no inherited selection from RECON02
Authorized production migrations: ZERO
New authorities and new production dependency cuts: ZERO
SELFHOST_M2_ACHIEVED=NO; SLICE10_AUTHORIZED=NO
Publication: No push, fetch, rebase, amend, reset or force-update.

## 0. Mission and exact meaning of PASS

Run a fresh, source-and-object-derived selection of exactly one coherent
multi-site bundle of core compiler semantics for a later PolyC
implementation ACT. Prefer type analysis, expression semantics, CFG, IR
construction/transformation, instruction selection or code generation,
with demonstrated influence on compiler acceptance, generated IR/assembly/
object, or compiled-program behavior. A diagnostic-only or already
migrated predicate cannot win.

Unlike the halted RECON02, this ACT may proceed beyond C0 only after
independently binding the subsequent append-only range-operator
correction and reconciling terminal history. It must not resurrect
RECON02's nonexistent selection, assume that every function is a
semantic authority, equate symbol counts with causal evidence, or claim a
production graph cut from a planned ABI.

PASS_SELECTED_CORE_BUNDLE requires: exact entry and history
verification; full census and transparent candidate exclusions; a frozen
16-clause eligibility contract; canonical deterministic ranking and
separate independent PolyC recomputation; one actual C-source causal
mutation per selected site, each built into a real whole compiler with a
discriminating witness and restoration; one frozen successor contract
that describes ownership, ABI and bootstrap producer chain; 24 sensitive
adverse controls; all 50 independently evidenced acceptance criteria;
conserved production and historical failure identities; a valid five-commit
Factory-v2 CLOSE; and an external post-CLOSE receipt.

If no qualifying 2–6-site bundle can be demonstrated,
HALT_NO_ELIGIBLE_CORE_BUNDLE with a complete census, candidate ledger and
reason-specific failures. An explicit, measured HALT is better than a
fabricated selected bundle. There is no permission to downgrade to one
site silently.

### 0.1 Hard non-goals

- No production delegation, source refactoring, ABI rollout, new runtime
  capability, compiler bug fix or four-generation successor object
  implementation.
- No changing src/**, tools/bootstrap/**, tests/**, Makefile, CMake or
  canonical gates in the authoritative checkout.
- No rewriting historical ACT/HANDOFF/evidence, including the false
  original M-POLYC-RO record, RECON02 HALT, or forward-only corrections.
- No spontaneous repair of the fail-open test prefix, /tmp/holyc-asm.s
  collision, parallel object race, ARM64 indexed-byte-load defect,
  F-POLYC-TOOLS, F-NO-PYTHON, LEXER07 or the 67 prefix failures.
- No assumption that SCC reduction or under-100 ACT self-hosting is
  established. No authorization of SLICE10 or of any implementation ACT by
  this reconnaissance itself.

### 0.2 Terminal status taxonomy

PASS_SELECTED_CORE_BUNDLE, HALT_ENTRY_IDENTITY, HALT_PREDECESSOR_BINDING,
HALT_POST_CLOSE_HISTORY, HALT_SOURCE_CENSUS, HALT_INDEPENDENT_SELECTION,
HALT_NO_ELIGIBLE_CORE_BUNDLE, HALT_CAUSAL_BUILD, HALT_CAUSAL_ATTRIBUTION,
HALT_ABI_UNPROVEN, HALT_CONTROLS, HALT_CONSERVATION,
HALT_FACTORY_TERMINALITY, or a more precise evidence-backed reason. The
terminal commit trailer is ACT-Verdict: PASS or the repository's valid HALT
convention; disposition is separately stated in HANDOFF/report.

## 1. Source of truth, authority and expected entry

At entry, read the actual repository's AGENTS.md, docs/factory/DOCTRINE.md,
docs/factory/GIT-METADATA.md, roadmap and handoff map, Factory-v2
commit-message/range/closure validators, F14 and append-only rules. If
this proposed contract conflicts with the committed doctrine, HALT with a
contract conflict, rather than silently reinterpret requirements. Actual
Git objects outrank narrative digests.

### 1.1 Identity commands and post-CLOSE reconciliation

```sh
set -eu
pwd
git branch --show-current
git rev-parse HEAD 'HEAD^{tree}'
git status --porcelain=v1
git replace -l
git worktree list --porcelain
# Bind the predecessor's reported exact entry and corrected causal evidence:
git cat-file -t f850be2dbd175ed06cc8b3c6bed8ad261fbe3cbb
git log --reverse --format='%H%x09%P%x09%s%n%b' 30432271ab1f56079be3a33dbddc415392b5034e..HEAD
# Inspect the locally existing tracking ref only; never fetch:
git show-ref --verify --quiet refs/remotes/origin/main && git rev-parse origin/main || true
```

Expected at C0: main, exact HEAD and tree declared above, clean tracked/index
and no untracked ACT source residue, zero replace refs, no unexplained merge
or replace/rewritten commits. Distinguish ignored build output, untracked
files, and pre-existing worktrees. Never remove worktrees not created by this
ACT.

Critical chronology check: locate the unique
ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01 C4 CLOSE by exact ACT
trailer in the real Git graph; verify its five ACT commits in strict RED →
EVIDENCE → IMPL → EVIDENCE → CLOSE sequence, the single CLOSE, and original
external receipt's claimed SHA/tree binding. Measure both
POST_CLOSE_ALL_COMMITS = git rev-list --count <CLOSE>..HEAD and
POST_CLOSE_THIS_ACT_COMMITS by ACT trailer. The earlier report's
"POST_CLOSE_COMMITS=0 (carrying this ACT id)" may coexist with an ordinary
later commit; never misreport the former as zero all-commit descendants.

Inspect every descendant commit after CLOSE: subject, trailers, parent(s),
touched paths, tree delta, whether any prior terminal evidence/source or gate
was changed, and whether it introduces an undocumented semantic/authority
change. An ordinary non-ACT receipt/checkpoint commit is not automatically
disallowed, but its authorization and effect must be established from
doctrine. If ordinary post-CLOSE commits have changed the effective state or
cannot be explained, HALT_POST_CLOSE_HISTORY. Do not make a retroactive CLOSE
claim, undo the commit, or silently choose another entry. If there is no
descendant, explicitly record count zero. Do not guess the CLOSE SHA from
HEAD~N.

Bind origin/main only if present; it may be behind by multiple local ACTs.
No publication. Freeze an entry-tree hash manifest and a complete
closed-predecessor F14 manifest by path + SHA-256. Preserve every frozen path
byte-identically.

### 1.2 Historical evidence reconciliation: two counts, different dates

Read actual committed bytes, not only the latest summary, of:

- docs/acts/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01.md
- evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/mutant-ro.tsv
- evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c3/site-isolation.tsv
- docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02.md
- docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01.md
- docs/acts/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01.md
- docs/factory/HANDOFF-ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01.md
- evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01/c2/source-object-witness-execution-join.tsv
- evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01/c2/ca-po-ro-site-isolation-corrected.tsv
- evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01/c3/authority-conservation.tsv
- evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01/c3/corrected-causal-evidence-ledger.tsv

Find missing renamed paths via git ls-tree; bind exact OIDs and explain the
mapping, never fill absent data from memory. Independently recompute enough
of the correction to prove that the historical M-POLYC-RO source/object
hashes are a PO mutation, while the correction's own EXEC-RO-CORR01-MUTANT
genuinely mutates AbiCoreIsRangeOperator and changes the discriminating
compiled 5 < 1 < 3 witness 0 → 1 → 0, leaving the pointer-only witness
unchanged. Require actual source/object/witness joining and link provenance;
a copied intended diff is not enough.

Conserve these time-scoped assertions:

```text
AT_IMPLEMENT01_CLOSE_STRUCTURAL_AUTHORITIES=13
AT_IMPLEMENT01_CLOSE_CAUSALLY_BACKED=12
HISTORICAL_M_POLYC_RO_ACTUAL_SUBJECT=AbiCoreIsValidPointerOperator
HISTORICAL_RO_CAUSAL=UNPROVEN_AS_RECORDED
RECON02_TECHNICAL_VERDICT=HALT_PREDECESSOR_PROOF_INCOMPLETE
RECON02_CARDINALITY_CORRECTION_VERDICT=PASS
CORRECTION_RO_EXECUTION_ID=EXEC-RO-CORR01-MUTANT
CORRECTION_RO_CAUSAL=PROVEN (new, separate execution)
CURRENT_STRUCTURAL_AUTHORITIES=13
CURRENT_CAUSALLY_BACKED_INCLUDING_CORRECTION=13
```

Verify the 13 live production symbols by actual producer/linked-object/caller
evidence and retain their canonical mapping; no invented 14th authority.
Failure to prove the correction-inclusive identity is HALT_PREDECESSOR_BINDING;
RECON03 does not fix the correction or silently reuse the historical
mislabeled experiment.

## 2. Authorized scope and execution hygiene

Only these tracked paths may be added/changed:

```text
docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03.md
docs/factory/act-handoff-map.tsv              # exactly one append row
docs/ROADMAP.md                               # bounded append only
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03/**
tools/quality/core-semantic-bundle-recon03-*.HC  # bounded substantive PolyC verification
```

All new substantive tooling must be PolyC-authored (*.HC); use existing POSIX
shell/`awk` only for short, narrowly scoped evidence/control drivers. No
Python, new dependency, generated test binary or permanently stored
machine-local logs committed. Existing canonical checkers/rankers are read
only; do not weaken canonical gates. No new Makefile target unless explicitly
reauthorized by separate ACT.

Experiments belong exclusively in disposable git worktree add --detach trees
at verified entry HEAD with unique worktree/build/install directories. Record
actual applied bytes, producer SHA, full compiler command/exit, final
executable and witness identity. Do not run compiler invocations
concurrently: shared /tmp/holyc-asm.s and observed make -j object races are
open. Serializing one make alone does not protect independent compiler
processes; schedule the entire compiler-execution surface serially. Never
cleanup another ACT's or user's worktrees. No pushes or network operations.

### 2.1 Conservation baseline at entry and C3

Measure with fresh, populated install/test prefix and real runner
identities, never only a wrapper exit status:

| Check | Frozen comparison target | Acceptable interpretation |
|-------|--------------------------|--------------------------|
| Parser | 376/376, 90 files, assertion-sequence MD5 b6f117eb1386ca80f81bc06226e2a741 | Identical ordered sequence; zero new failures |
| Direct lexer07 / 08 / 09 | 89/89, 45/45, 23/23 | No regressions |
| Broad LEXER07 | historical 15 failure IDs, MD5 7ee761440de83552e751e3c3976c1683 | FAIL_KNOWN_BASELINE is not PASS |
| Cross-target | missing-prefix environmental condition, historically 67 | Distinguish freshly measured vs imported historical count; do not claim remeasurement if unavailable |
| F-NO-PYTHON | 12 historical violations, zero new | FAIL_KNOWN_BASELINE is not PASS |
| F-POLYC-TOOLS | authoritative checker not landed | UNAVAILABLE until demonstrably present |
| Production graph | 52 nodes / 134 mandatory edges / 34 SCC / largest 19 | Zero new cuts under this RECON; E-TYP-0136 only |
| Existing authorities | 13 live, correction-inclusive 13 causally backed | No loss/new authority |

make unit-test returning zero with a missing test runner/prefix is a FAIL, not
conservation; inspect raw runner output and presence of installed
headers/libraries. If concurrency causes a failure, record the failure and
distinguish a separately evidenced serial rerun; do not silently delete the
first observation.

## 3. Factory-v2 execution lifecycle

Five linear non-merge commits, validated with the repository's actual
commit-message validator before writing each commit:

| Commit | ACT phase | Purpose | Production semantic delta |
|--------|-----------|---------|---------------------------|
| C0 | RED | Entry binding, immutable freeze, baselines, control contract, five genuine REDs | 0 |
| C1 | EVIDENCE | Fresh production-linked core census, eligible candidate bundles and their dependencies | 0 |
| C2 | IMPL | PolyC selection verifier, independent ranking, real C-source causal qualification, selected successor contract | 0 |
| C3 | EVIDENCE | Independent rederivation, 24 adverse controls, baseline/gates and AC01–AC49 | 0 |
| C4 | CLOSE | One handoff/roadmap/map entry, one terminal CLOSE and external post-CLOSE verification | 0 |

C2 IMPL means reconnaissance tooling and proof artifacts, never production
compiler migration. The C4 tracked terminality-plan.txt is a plan, not a
fabricated receipt. At C3 AC50 remains DEFERRED; after CLOSE only an external
read-only receipt bound to its exact SHA/tree may discharge AC50. If the
repository's doctrine does not permit an external receipt plus an ordinary
post-CLOSE tracked commit, do not create one.

### 3.1 C0 RED — measured failure before fixes or ranking

Freeze 50 mandatory AC IDs, 24 negative-control IDs, detector reason
classes, evidence paths, and 16 eligibility predicates before running the
selection. Execute five different fail-on-adverse/return-on-pristine REDs
against real entry inputs; minimum cases:

1. Historical M-POLYC-RO mislabeled as its actual RO target must be rejected
   by a source-digest attribution detector; correction-inclusive evidence
   joins correctly.
2. A fake post-CLOSE ordinary commit containing a production source delta
   must fail the entry-history detector; a legitimate unchanged local history
   must pass.
3. An already PolyC-owned decision offered as a new C authority must fail
   eligibility.
4. A site without real compilation-semantic witness (diagnostic-only or
   dormant) must fail selection.
5. A fabricated "SCC cut" based solely on an interface sketch must fail the
   graph verifier.

Controls 1–5 may use isolated immutable copies of records; they must not
mutate canonical history. Each RED needs actual command, result, exact
reject reason, pristine recovery and own execution ID. Freeze source-tree
identity and baselines before C1. If mandatory predecessor proof fails, HALT
here; do not run ranking on partial authority data.

### 3.2 C1 EVIDENCE — complete core-semantic census

Build a fresh compiler and derive the production-linked census from source +
build graph + object/link map. The scope includes parser expression
semantics, types/symbols, AST/IR, CFG, instruction selection, machine code
generation, compiler driver and supporting semantic boundaries actually linked
by the current build. Discover actual files and names from source; these
headings are categories, not invented existing implementation layers. Link
every row to a Git source object/hash, line or byte range, TU,
object/symbol or inlining evidence, entry-to-operation reachability, selector
state, C-vs-PolyC authority, graph edges and owner.

Create disjoint inventories:

- core-sites.tsv: every production-reachable unmigrated C semantic decision in
  the scoped core plus explicit tested exclusions. Do not count control-flow
  syntax as separate authorities unless it represents distinct behavior and is
  source-bound.
- core-authorities.tsv: current 13 PolyC authorities and all remaining C
  authorities, keeping site count, functions, symbols and graph edges
  distinct.
- core-dependencies.tsv: type layout, mutable state, ownership/lifetime,
  callbacks, recovery/jump-frame, token/AST/IR graph, allocation, diagnostics
  and codegen dependencies; each with a source/object witness.
- core-candidates.tsv: coherent prospective 2–6-site groups; include every
  considered group plus exclusions and deterministic stable candidate ID.
- bootstrap-path.tsv: observed build stages, real producers,
  compiler-source generation dependency, entry points, and per-bundle impact
  on first genuine self-compiled compiler generation (M2).

Do not scan only src/parser.c or infer a complete compiler from the CENSUS01
inventory. Cover all production-linked core components; scope constraints and
incompleteness must be explicit rather than silently treated as complete.
Audit the previously unsupported E-MUT-0137 source/object witness and mark it
UNSUPPORTED_WITNESS unless new source/compiled proof supports a separate
future correction. Do not alter the historical graph or claim a new cut under
this ACT.

For each candidate, freeze site-by-site input domains, complete operator/tag
values derived from source (including implicit enum zero), C side effects,
pointer dereferences, caller host projections, error/recovery paths, source
ranges+SHA, planned allowed ABI and handling of unknown inputs. Evidence must
distinguish read-only scalar classification from stateful compiler operations;
prefer meaningful state transitions while requiring a credible ownership
boundary.

## 4. Freeze 16 eligibility predicates and rank independently

Apply the following all-required eligibility clauses. Freeze implementation of
the checker before observing the final selection. An excluded site cannot be
promoted by editing an input eligible flag. Source-derived facts, not manually
supplied booleans, are the authority.

| ID | Mandatory candidate predicate |
|----|-------------------------------|
| E01 | All members presently C-authoritative in the linked production compiler; not merely leftover forwarding adapters. |
| E02 | Exactly 2–6 distinct sites, with stable IDs and disjoint source ranges. |
| E03 | Every site has source OID, byte range, source SHA-256, TU and object/inline reachability. |
| E04 | Each site is a semantic decision affecting compilation acceptance, IR/assembly/object or runtime behavior; diagnostic-only excluded. |
| E05 | A separate discriminating compiler witness is identified per member, not one shared undifferentiated outcome. |
| E06 | The member operations are coherently related by a named invariant/dataflow/operator family, not arbitrary proximity. |
| E07 | The bundle has a credible path to M1/M2 compiler semantic or bootstrap work; derived evidence, not a prose promise. |
| E08 | ABI projection has bounded copied scalars or rigorously typed borrowed handles; no unrestricted void*/callback table. |
| E09 | Ownership and lifetime of AST/IR/token/container data remain explicit and non-leaking across the seam. |
| E10 | No cross-frame setjmp/`longjmp`, unbounded recursive recovery transfer or unverified exception across PolyC/C. |
| E11 | Diagnostics, allocation and mutable host state remain correctly sequenced; no hidden double evaluation. |
| E12 | Each member has a genuine C-only G0 path in a complete compiler and can be compiled into a future PolyC subject. |
| E13 | Full production C causal mutation can be built without changing unrelated sites; source/object restoration observable. |
| E14 | Fixtures can derive from live enum/source semantics and cover valid, invalid, boundary and fallback input partitions. |
| E15 | ABI has explicit status/data separation, especially valid numeric zero, negative values and error domains. |
| E16 | The proposed changes fit a bounded implementation with deterministic build prerequisites and no unproven graph or SCC claim. |

### 4.1 Deterministic rank contract (only after eligibility)

Rank all provisionally eligible bundles with a fully specified lexicographic
key; every input must have a source/evidence witness. Eligibility clause E13
is an independently checked feasibility predicate, not a claim that the mutant
was already built; the actual build is mandatory at C2:

1. R0: bootstrap dependency (2 if shown to be on an observed M2-critical path,
   1 if compiler-core semantic progress but not demonstrated M2-critical, else
   0). Do not label R0=2 merely for being inside the 19-subsystem SCC.
2. R1: pristine-source/witness-validated semantic impact diversity (compiler
   acceptance, emitted IR/object, runtime) — count observed channels from
   actual entry compiler runs, not predicted mutant results.
3. R2: number of uniquely identifiable, independently testable C authority
   sites, capped at six; this is a pre-mutation ranking proxy, not a claim of
   causal qualification. At C2 the selected member count must equal
   independently proven physical causal experiments before PASS.
4. R3: strength of coherent shared ABI and invariants (source-derived
   boundedness, validation and ownership) using a frozen documented 0/1/2
   rubric.
5. R4: graph reduction potential computed against current 134-edge graph, with
   POTENTIAL_ONLY explicitly not CUT_PROVEN; do not weight unsupported
   E-MUT-0137.
6. R5: estimated implementation complexity/risk from frozen source-derived
   dimensions (numbers of host fields, mutable writes, recovery crossings,
   build producer changes), minimize the risk score.
7. R6: exact candidate identity in bytewise ascending order, tie-break only.

Rank by descending R0–R4, ascending R5–R6. Record full scored roster
including rejected candidates and reason-specific exclusion IDs, not just the
winning row. The checker must own its eligible column; the ranker must join
by stable candidate ID from checker output, never trust a freehand flag. Use
the repository's canonical checker/ranker only where its schema matches these
frozen predicates; if not, create new PolyC-owned quality verifier for
RECON03 without changing canonical tools, and explicitly name it ACT-local.

An independent second PolyC implementation (separate source and computation
route) must rederive eligibility from C1 source facts without reading the
first checker's eligible flags, then recompute the complete rank order. A
POSIX awk cross-check may supplement but may not substitute for a required
independent PolyC recomputation. Every candidate and every rank position
must match; join mismatches, missing IDs and duplicate IDs must be zero.
Deliberately forge an excluded candidate's eligible=1 as an adverse control;
it must never be promoted.

## 5. C2 IMPL — causal qualification of exactly one selected bundle

Only after C1 has enumerated candidates, eligibility and ranking independently
agree, and the best eligible candidate has a declared bounded ABI, freeze the
provisional selection identity and per-site mutation plans, not yet a PASS
successor. Produce the terminal selected-bundle-contract.md only after every
selected site passes the real C2 causality tests. Do not pick an easier
runner-up based on convenience. If the rank-1 candidate's real causal witness
proves non-load-bearing, disqualify with executed evidence, re-run the same
frozen eligibility/ranking across remaining candidates, record the reason and
complete order, and do not silently amend the rubric.

### 5.1 One independent full-C-mutant experiment per selected member

For each selected site S (each 2–6 sites; no combined mutation), execute a
physically separate mutation in a dedicated detached worktree derived from
exact C0 entry, changing only the selected C semantic decision. Before
editing, freeze a single-site mutation plan; then independently verify the
actual applied source bytes and SHA-256 (not the planned diff), and prove
every other bundle member and unrelated source is byte-identical. Rebuild the
complete real C-authoritative compiler with supported selector configuration
and clean subject inputs; no stub oracle, stale object, failed build or
hand-written evaluator can substitute.

Required for each S:

```text
SITE_ID
FUNCTION_AND_TU
SOURCE_GIT_BLOB_OID
SOURCE_BYTE_RANGE_AND_SHA256
ACTUAL_MUTATION_DIFF_SHA256
MUTANT_SOURCE_SHA256
COMPILER_PRODUCER_ID_AND_SHA256
COMPILER_OBJECT_SHA256_BEFORE_AND_AFTER
LINKED_EXECUTABLE_SHA256_BEFORE_AND_AFTER
G0_SELECTOR_CONFIGURATION_AND_PROOF
DISTINCT_PHYSICAL_EXECUTION_ID
WITNESS_SOURCE_SHA256
WITNESS_COMPILER_BUILD_RC
WITNESS_PRISTINE_SEMANTIC_OBSERVATION
WITNESS_MUTATED_SEMANTIC_OBSERVATION
WITNESS_RESTORED_SEMANTIC_OBSERVATION
ADJACENT_SITE_CONTROL_OUTCOMES
RESTORATION_SOURCE_AND_OBJECT_PROOF
```

A mutation that fails to build is UNQUALIFIED_BUILD_FAILURE, not proof of
semantic causality. A mutant that only changes diagnostics without a
demonstrated semantic channel is ineligible. A changed object that is not
linked into the actual compiler is dormant, not proven. For every witness,
verify emitted IR/assembly/object as a second channel when available, plus
actual compiled-program exit/output or compiler acceptance. A witness must be
discriminating: demonstrate that the intended semantic alternative produces a
different result; e.g., the predecessor's 1 < 2 < 3 could not separate range
lowering while 5 < 1 < 3 could.

For every site S, run an isolation anti-control: an independently mutated
adjacent decision must not satisfy S's witness (or, where true functional
coupling makes this impossible, document why and use a different
discriminator; if no separating witness exists, do not count two distinct
causal sites). Each site gets its own physical execution ID and
object/source/witness join. An intended patch or reused execution cannot be
counted twice. Restore source byte-identically and verify object byte-identity
under matched producers, or explicitly explain embedded provenance/environment
differences rather than inventing identical binaries. Confirm no authoritative
main source changed.

### 5.2 Freeze future successor implementation contract

After all site mutations qualify, freeze one and only one successor contract
containing:

- bundle ID and semantic invariant; exact selected member IDs, live source
  ranges, full source digests, object/caller provenance and per-site causal
  execution IDs;
- ABI name/version and exact PolyC exports, host projection semantics,
  status/out-param domains, endianness/width/target ABI and load-bearing
  selector behavior;
- explicit ownership, lifetime, aliasing, C allocations, mutation order,
  token cursor, diagnostics, recovery and callback restrictions;
- genuine selector-OFF whole-compiler C oracle and G0 fixture producer;
  G1/G2/G3 PolyC producers with three independently identified compiler
  binary digests and 12 ordered differential comparisons required of the
  successor, not falsely executed by RECON03;
- derived fixture specification with partitions, unknown inputs, zero-valued
  discriminants and independent source parser, plus a separate post-migration
  PolyC mutation and legacy C-dormancy anti-control for each member;
- permitted production source/build paths, fail-closed Make/CMake producer
  prerequisites and explicit serialization until races are fixed;
- estimated next implementation ACT workload low/base/high, actual evidence per
  member, explicit remaining blockers, graph impact POTENTIAL_ONLY, and M1/M2
  impact with no invented critical-path percentage;
- selected contract hashes frozen by C2 and independently verified at C3/C4.

The contract does not authorize implementation. If it is not feasible to
define one ABI that safely covers all selected sites, reject the bundle; do
not implement a speculative PolyC prototype in authoritative production.

## 6. Frozen 24 negative controls

Exactly NC01..NC24; no aliasing to inherited IDs and no double count for two
controls sharing a single physical test. Each uses SILENT on authentic →
FIRED on adverse for its own named detector reason → SILENT on restored.
Structural/ledger attacks may run on isolated copies; causal semantic
controls must derive from actual built compiler/objects, not handwritten mocked
return values. Log actual execution IDs and reject vacuous PASS.

| ID | Injected adverse condition | Expected detector reason | Required surface |
|----|----------------------------|--------------------------|------------------|
| NC01 | Wrong HEAD/tree substituted | ENTRY_IDENTITY_MISMATCH | Git object/record copy |
| NC02 | Inject a replace ref or forged commit object | REPLACE_OR_OBJECT_PROVENANCE | isolated ref/record, never live refs |
| NC03 | A post-CLOSE ordinary commit changes compiler source | UNAUTHORIZED_POST_CLOSE_SOURCE_CHANGE | synthetic commit manifest |
| NC04 | Report 0 all-commit descendants when only 0 ACT-trailer descendants | POST_CLOSE_COUNT_CONFLATION | isolated history table |
| NC05 | Retroactively label IMPLEMENT01 13/13 causally backed | HISTORICAL_CAUSAL_DATE_MISMATCH | historical attribution join copy |
| NC06 | Bind historical M-POLYC-RO to RO rather than pointer site | MUTANT_SOURCE_OBJECT_MISATTRIBUTION | source SHA recreation |
| NC07 | Modify one frozen predecessor digest/path | F14_PREDECESSOR_TAMPER | isolated path manifest |
| NC08 | Invent 14th or drop one of 13 current authorities | AUTHORITY_SET_MISMATCH | authority roster copy |
| NC09 | Omit production-linked core TU/site from census without exclusion | CENSUS_COVERAGE_GAP | source/object roster copy |
| NC10 | Offer already PolyC-owned authority as C candidate | ALREADY_MIGRATED_EXCLUSION | eligibility input copy |
| NC11 | Forge eligible=1 for excluded candidate at ranker input | ELIGIBLE_FLAG_FORGERY | checker/ranker join copy |
| NC12 | Insert unknown bundle/site ID | UNKNOWN_CANDIDATE_ID | selection roster copy |
| NC13 | Delete one frozen candidate/site row | MISSING_CANDIDATE_ID | selection roster copy |
| NC14 | Duplicate a candidate or execution ID | DUPLICATE_ID | selection/execution roster copy |
| NC15 | Remove a mandatory source SHA/object/reachability fact | MISSING_SOURCE_FACT | census copy |
| NC16 | Swap the first two rank positions or alter one rank score | RANK_ORDER_MISMATCH | rank file copy and independent PolyC ranker |
| NC17 | Qualify a diagnostic-only / non-discriminating semantic witness | NON_SEMANTIC_OR_VACUOUS_WITNESS | real witness or isolated semantic ledger |
| NC18 | Count failed full compiler mutant build as causal proof | UNQUALIFIED_BUILD_FAILURE_ACCEPTED | actual failed-build evidence plus ledger copy |
| NC19 | Use intended .diff instead of actual applied source SHA | APPLIED_SOURCE_PROVENANCE_FAILURE | mutant source/ledger copy |
| NC20 | Use object absent from final linked compiler | UNLINKED_OR_DORMANT_MUTANT | link map/object proof |
| NC21 | Count one physical mutation for two sites | SHARED_EXECUTION_DOUBLE_COUNT | site-to-execution join copy |
| NC22 | Swap two site-specific witnesses or accept adjacent-site causal effect | SITE_ISOLATION_FAILURE | real discriminator and witness join |
| NC23 | Claim graph cut/SCC reduction from unimplemented ABI sketch or E-MUT-0137 | UNPROVEN_GRAPH_CUT | graph ledger copy |
| NC24 | Omit AC ID or mark AC50 PASS before post-CLOSE receipt | LEDGER_OR_TERMINALITY_FALSE_PASS | AC/NC ledger copy |

### 6.1 Verifier anti-selftests

Run an independent PolyC verifier selftest against deletion, duplication,
unknown IDs, swapped execution IDs, swapped witness/source hashes, missing
negative-control row, forged PASS, incorrect reason class and AC50 premature
terminal PASS. Require a reason-specific nonzero response rather than any
failure; demonstrate genuine pristine PASS and byte-identical record
restoration. Freeze exact IDs and detector classes at C0. If any control is
NOT_RUN, UNPROVEN, fires only because of a generic parse error, or relies on
its own expected outcome as input, the ACT cannot PASS.

## 7. Exactly 50 mandatory acceptance criteria

At C0 create a frozen acceptance-contract.tsv with exact AC01..AC50, phase,
predicate, required evidence path, independent checker, state. These
predicates are binding; the table below is complete. Status vocabulary is
PASS, FAIL, NOT_RUN, UNPROVEN, DEFERRED. Each acceptance criterion must have
a concrete independent witness and be joined by exact ID, never a count-only
check. AC50 can turn PASS only with the external post-CLOSE receipt.

| ID | Phase | Mandatory predicate |
|----|-------|----------------------|
| AC01 | C0 | Exact expected HEAD/tree/branch, clean index, zero replace refs and worktree ownership. |
| AC02 | C0 | Full ancestor chain and C4 CLOSE identity derived from actual Git objects; five phase commits proven. |
| AC03 | C0 | All-vs-ACT post-CLOSE descendant counts distinguished; every ordinary descendant classified and scoped. |
| AC04 | C0 | Local origin/main ancestry (if present) and no push/network/history rewrite established. |
| AC05 | C0 | Full predecessor frozen-path SHA-256 manifest established; all closed ACT and evidence identities bound. |
| AC06 | C0 | Original M-POLYC-RO physically pointer-site, historical 12/13 count retained. |
| AC07 | C0 | New correction-owned RO source/object/executable/discriminator proof independently bound and 13/13 inclusive. |
| AC08 | C0 | 13 live PolyC authority sites link/caller census fresh; no lost or invented sites. |
| AC09 | C0 | Fresh parser/lexer/historical non-green baseline with actual test runner/prefix provenance. |
| AC10 | C0 | 50 AC, 24 NC, 16 eligibility predicates, five independent REDs frozen and executed without vacuity. |
| AC11 | C1 | Production-linked core TU/object/symbol closure enumerated; scope and explicit exclusions recorded. |
| AC12 | C1 | Each unmigrated C authority site carries actual source OID, byte range, SHA-256 and link reachability. |
| AC13 | C1 | Current PolyC authorities, source functions, C semantic sites and graph edges remain disjoint accounting units. |
| AC14 | C1 | Complete typed core dependency graph with each included edge backed by source/object evidence. |
| AC15 | C1 | E-MUT-0137 re-audited and not falsely credited as a supported cut. |
| AC16 | C1 | All relevant source-derived type/operator/enum values, including zero-valued implicit enumerators, verified. |
| AC17 | C1 | Candidates enumerated as coherent bundles of 2–6 distinct sites; all exclusions and dependencies named. |
| AC18 | C1 | Each considered site's semantic class and production impact channels independently classified. |
| AC19 | C1 | Ownership, lifetime, aliasing, callback, recovery and mutation-order surfaces source-derived. |
| AC20 | C1 | Candidate ABI domains/status and out-param semantics defined without undocumented pointer transfer. |
| AC21 | C1 | Existing bootstrap producers, actual compiler generation paths and M1/M2 dependency evidence recorded. |
| AC22 | C1 | Source witnesses and discriminating future mutation plans separately identified for each candidate member. |
| AC23 | C1 | Eligibility E01..E16 facts and reason-specific failures fully populated, zero UNKNOWN silently coerced eligible. |
| AC24 | C1 | Ranking rubric R0..R6 and raw source facts frozen before final selection. |
| AC25 | C1 | No speculative graph cut/SCC improvement or fake M2 achievement reported. |
| AC26 | C2 | ACT-local PolyC eligibility checker compiled and independently selftested with live source facts. |
| AC27 | C2 | Ranker consumes only eligible IDs mechanically joined from authoritative eligibility checker output. |
| AC28 | C2 | Independent PolyC recomputation reconstructs all eligibility decisions without reading first eligible column. |
| AC29 | C2 | Independent rank order matches every eligible position and all source-derived scores. |
| AC30 | C2 | Exactly one rank-1 coherent bundle selected, or reason-backed HALT with full candidate ledger. |
| AC31 | C2 | Selected bundle member count 2–6; source ranges and one-to-one stable site identifiers frozen. |
| AC32 | C2 | One real C-only whole-compiler pristine oracle established for every selected site. |
| AC33 | C2 | Distinct real full-compiler C mutation rebuild completed successfully for each selected site. |
| AC34 | C2 | Actual applied C diff/source and changed linked object proven for each site; no intended-diff substitution. |
| AC35 | C2 | Each site independently changes compiler acceptance, IR/assembly/object or compiled-program behavior. |
| AC36 | C2 | Adjacent-site mutant/witness anti-controls prove independent attribution for every member. |
| AC37 | C2 | Every mutant/restored source and compiled-object provenance recorded; deterministic limitations honest. |
| AC38 | C2 | Selected ABI contract explicitly covers host projection, status/data, ownership, recovery and target ABI. |
| AC39 | C2 | Future G0/G1/G2/G3 producers, source-derived fixture partitions, per-site post-migration PolyC mutations specified. |
| AC40 | C2 | Exactly one source-hashed successor contract produced, no implementation or new authority/cut introduced. |
| AC41 | C3 | Independent verifier re-reads Git/source/object/witness evidence rather than echoing summary PASS values. |
| AC42 | C3 | All 24 negative controls executed with pristine-adverse-restored and correct distinct reasons. |
| AC43 | C3 | Checker anti-selftests reject missing/duplicate/unknown IDs, false PASS, swapped attributions. |
| AC44 | C3 | Independent AC/NC/eligibility/selection joins complete, 0 missing/duplicate/extra IDs. |
| AC45 | C3 | 13 current authorities and historical-vs-correction-inclusive proof attribution conserved. |
| AC46 | C3 | Parser/lexer baselines and known non-green failure-ID sets conserved, zero new failures. |
| AC47 | C3 | Production graph unchanged 52/134/34/19, sole historical cut E-TYP-0136; E-MUT-0137 unsupported. |
| AC48 | C3 | gate-fast, serialized gate-push, append-only, F14, patch hygiene and scope restrictions PASS. |
| AC49 | C3 | AC01..AC49 supported at C3; handoff/roadmap/map and post-CLOSE plan ready, AC50 correctly DEFERRED. |
| AC50 | External post-CLOSE | External read-only terminality receipt after unique C4 CLOSE binds final HEAD/tree, five ACT commits, ACs/controls, F14, exact source contract, gates, zero post-CLOSE ACT commits; no backdated PASS. |

Do not infer PASS merely from the presence of an evidence file. Enforce
source/source-range/physical-execution/witness joins and exact
negative-control reason detectors. A C3 ledger may contain at most 49 PASS /
1 DEFERRED; an ACT HALT reports all FAIL, UNPROVEN and NOT_RUN accurately
without filling missing work with fabricated PASS.

## 8. C3 independent verification and conservation

Use at least two genuinely independent techniques to verify the result: (a) a
new PolyC source-driven verifier computing digests, eligibility, ranks, joins
and F14; (b) a read-only Git/POSIX implementation re-extracting source
ranges, object symbol/caller facts, causal mutations and the full ranked list
without reading the first verifier's decision summaries. The required
eligibility and rank recomputation must include an independent PolyC
implementation, so POSIX-only agreement cannot discharge that obligation.

Run each normal build/gate serially. Record command, actual exit, per-check
status, compiler executable identities, input tree, output SHA and elapsed
execution identity. gate-fast and gate-push must PASS; gate-push must include
build/install/gep01/aot/jit/lsp/diff-check with the actual canonical gate
definitions. The parser must report 376/376 and matching ordered MD5 with a
populated prefix. Direct lexer results 89/45/23 must match. Historical
LEXER07 broad 15 failure identities and MD5 must remain unchanged, explicitly
FAIL_KNOWN_BASELINE; the cross-target 67 and F-NO-PYTHON 12 must remain
honestly non-green if unchanged; F-POLYC-TOOLS unavailable until its checker
lands. Historical facts are recorded, not relabelled green.

Verify git diff --check, all authorized-path restrictions, no forbidden
src/**/`tools/bootstrap/**`/tests/Makefile/CMake changes, exactly zero new
PolyC production authorities or proven production graph cuts, 13 authorities
conserved, F14 predecessor path SHA set unchanged. Catch redirection or
background polling jobs and consume their final statuses before reporting
terminal success. Report any failed trial gate and its independently verified
reason; a later serial PASS does not erase the observation.

### 8.1 Evidence tree (minimum)

```text
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03/
  c0/
    entry-identity.txt
    post-close-ancestry-and-commit-scope.tsv
    correction-inclusive-predecessor-proof.tsv
    predecessor-f14-freeze.tsv
    existing-authorities.tsv
    baseline-parser.txt
    baseline-non-green.txt
    frozen-50-ac.tsv
    frozen-24-nc.tsv
    frozen-16-eligibility.tsv
    five-red-observations.tsv
  c1/
    linked-tu-and-symbol-census.tsv
    core-sites.tsv
    core-authorities.tsv
    core-dependencies.tsv
    core-candidates.tsv
    candidate-exclusions.tsv
    source-enum-and-abi-facts.tsv
    bootstrap-path.tsv
    ownership-recovery-witnesses.tsv
    eligibility-input-facts.tsv
    ranking-contract.md
  c2/
    eligibility-output.tsv
    independent-eligibility.tsv
    ranked-candidates.tsv
    independent-rank.tsv
    rank-selection-proof.tsv
    selected-bundle-contract.md
    selected-bundle-members.tsv
    causal-experiments/<SITE_ID>/source-and-build.tsv
    causal-experiments/<SITE_ID>/applied-diff-and-hashes.tsv
    causal-experiments/<SITE_ID>/witness-and-restoration.tsv
    causal-experiments/<SITE_ID>/site-isolation.tsv
    selected-causal-join.tsv
    abi-and-bootstrap-successor-contract.tsv
  c3/
    independent-source-and-object-audit.tsv
    negative-controls-executed.tsv
    verifier-selftests.tsv
    full-50-ac-ledger.tsv          # AC50 DEFERRED at C3
    conservation-parser-lexer.txt
    historic-non-green.txt
    graph-and-authority-conservation.tsv
    gates-and-factory.txt
    scope-and-f14.txt
  c4/
    terminality-plan.txt           # plan, NOT external receipt
```

Use ACT-local tools/quality/core-semantic-bundle-recon03-*.HC as needed. If an
experiment creates voluminous raw compiler logs outside the repo, record their
hash, producer, command and location plus sufficient bounded evidence in the
committed tree for verification if /tmp disappears. No raw log path alone is
proof. Member directory names must be derived from actual selected IDs and
never pre-created as fake evidence.

## 9. C4 CLOSE and external terminality

Produce the ACT document, a separate terminal HANDOFF, one
docs/factory/act-handoff-map.tsv append, a bounded docs/ROADMAP.md append,
new PolyC verifier source and ACT-owned evidence only. Validate every commit's
message with the actual Factory-v2 checkers before committing. Close with
exactly one terminal commit using the repository's required trailers:

```text
ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

A HALT must use the actual valid HALT trailer and preserve the failed criterion
statuses, with SELECTED_BUNDLE_ID=NONE unless selection had already been
validly frozen and later gates failed (in that case mark it invalid for
successor authorization). Do not produce a second CLOSE to store a terminality
receipt. The C4 committed terminality-plan.txt must explicitly say it is not an
observed result.

After C4, run an external, read-only terminality audit bound to the exact C4
HEAD/TREE, phase chain and trailers; verify 50-AC/24-control joins, candidate
contract, site causality, full frozen F14, gates and worktree cleanup; keep
the immutable receipt outside the repository. No additional commit is
authorized by this ACT. The checker's output can make AC50 PASS in the
executor's report; it cannot be backdated into C3. If the read-only receipt is
impossible or fails, report an honest terminality HALT/UNPROVEN, not a
manufactured PASS. Distinguish POST_CLOSE_ALL_COMMITS from
POST_CLOSE_ACT_COMMITS in the final report.

### 9.1 Next ACT only as a proposal

If PASS and a bundled successor contract is frozen: propose a separately
authorized ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02 (name may be
adjusted to the actual frozen bundle). The next implementation must reverify
this RECON03 contract and may not assume a particular file, operator, ABI, or
production graph cut not measured here. No SLICE10 authorization and no first
self-hosting/M2 claim.

If HALT with no qualifying coherent bundle, propose a bounded ABI/enabling ACT
tied to the specific measured blocker rather than selecting an easy diagnostic
predicate to inflate authority counts. Do not automatically open another
evidence correction absent a real provenance defect.

## 10. Final reporting schema (actual observed values only)

```text
ACT_ID=ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03
ENTRY_HEAD=f850be2dbd175ed06cc8b3c6bed8ad261fbe3cbb
ENTRY_TREE=e879d00fe7ed41da857dcd05c6e3c4d8fb3c199d
ENTRY_BRANCH=main
CORRECTION_CLOSE_SHA=<measured>
POST_CLOSE_ALL_COMMITS_AT_ENTRY=<integer>
POST_CLOSE_CORRECTION_ACT_COMMITS_AT_ENTRY=<integer>
POST_CLOSE_DESCENDANT_DIFF=<verified status>
ORIGIN_MAIN_ANCESTRY=<verified|missing-ref|not-proven>
RECON02_HISTORICAL_VERDICT=HALT_PREDECESSOR_PROOF_INCOMPLETE
HISTORICAL_M_POLYC_RO_ACTUAL_SUBJECT=AbiCoreIsValidPointerOperator
CORRECTION_RO_EXECUTION_ID=EXEC-RO-CORR01-MUTANT
CORRECTION_RO_CAUSAL=PROVEN
CURRENT_POLYC_AUTHORITIES=13
CORRECTION_INCLUSIVE_CAUSAL_AUTHORITIES=13
VERDICT=<PASS|HALT>
DISPOSITION=<PASS_SELECTED_CORE_BUNDLE|measured HALT reason>
FINAL_HEAD=<actual full SHA>
FINAL_TREE=<actual full SHA>
ACT_COMMIT_COUNT=<integer>
FACTORY_PHASE_SEQUENCE=<actual>
FACTORY_V2_RANGE_CHECK=<PASS|FAIL>
CLOSE_COUNT=<integer>
SOURCE_CENSUS_STATUS=<PASS|FAIL|UNPROVEN>
CORE_CANDIDATES_TOTAL=<integer>
ELIGIBLE_BUNDLES=<integer>
SELECTED_BUNDLE_ID=<actual ID|NONE>
SELECTED_MEMBER_IDS=<source-derived IDs|NONE>
SELECTED_MEMBER_COUNT=<integer>
ELIGIBILITY_INDEPENDENT_MISMATCHES=<integer>
RANK_INDEPENDENT_MISMATCHES=<integer>
CAUSAL_MEMBER_EXPERIMENTS_QUALIFIED=<integer>/<selected member count>
MUTANT_REBUILDS_AND_RESTORATIONS=<actual status>
NEXT_ABI_CONTRACT=<actual name|NONE>
PRODUCTION_AUTHORITIES=13
NEW_PRODUCTION_AUTHORITIES=0
PRODUCTION_SEMANTIC_DELTA=0
PRODUCTION_GRAPH=52_NODES_134_EDGES_34_SCC_LARGEST_19
NEW_PROVEN_GRAPH_CUTS=0
SELFHOST_M2_ACHIEVED=NO
SLICE10_AUTHORIZED=NO
PARSER_ASSERTIONS=<actual>/376
PARSER_ASSERTION_SEQUENCE_MD5=<actual>
LEXER07_BROAD_STATUS=<honest status>
LEXER07_FAILURE_IDENTITY_MD5=<actual or historically sourced>
CROSS_TARGET_PREFIX_STATUS=<honest status>
F_NO_PYTHON=<honest status>
F_POLYC_TOOLS=<honest status>
GATE_FAST=<PASS|FAIL>
GATE_PUSH=<PASS|FAIL>
NEGATIVE_CONTROLS=<N>/24
MANDATORY_AC_PASS=<N>/50
MANDATORY_AC_FAIL=<N>
MANDATORY_AC_UNPROVEN=<N>
MANDATORY_AC_NOT_RUN=<N>
MANDATORY_AC_DEFERRED=<N>
F14=<PASS|FAIL>
APPEND_ONLY=<PASS|FAIL>
EXTERNAL_TERMINALITY=<PASS|FAIL|UNPROVEN>
WORKTREE_CLEAN=<YES|NO>
GIT_REPLACE_REFS=<integer>
ACT_OWNED_WORKTREES_REMAINING=<integer>
POST_CLOSE_ACT_COMMITS=<integer>
POST_CLOSE_ALL_COMMITS=<integer>
PUSH_PERFORMED=NO
NEXT_ACT_CLASS=<CORE_BUNDLE_IMPLEMENT|ABI_FOUNDATION|NONE>
NEXT_TARGET_AUTHORIZED=NO
```

## 11. Procedural verification references

Use the current committed repository doctrine as the primary authority.
Outside references are procedural only, not evidence for PolyC-specific
semantics: Git git-rev-list (revision and ancestry ranges), Git git-worktree
(detached disposable worktrees), and GNU Make manual sections Reading
Makefiles and Parallel Execution (read-time prerequisite expansion and
scheduling). None authorizes a source or proof exception to this ACT.
