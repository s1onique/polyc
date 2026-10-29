# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / STRUCTURAL-SURFACE-RECON / POST-N06-SUPPLEMENT / SUCCESSOR-SELECTION
**Priority:** P0
**Repository:** `s1onique/polyc` (local canonical checkout)
**Branch:** existing main checkout; no ceremonial ACT branch
**Expected ENTRY_HEAD:** `34c2b6babbffc15c10cf2515085a6414bb8e3d77`
**Expected ENTRY_TREE:** `17e2d5b0170763c55dff93a26e896e21efc98bbf`
**Immediate predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01`
— historical CLOSE `PASS` / disposition `PASS_EVIDENCE_SUPPLEMENTED`.
**Historical governance predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06`
— immutable `HALT_N06_FROZEN_OBLIGATION_UNPROVEN`, `HALT_CLASS=GOVERNANCE`,
`BLOCKS_NEXT=NO`.
**Prospective successor:** conditional `ACT-POLYC-SELFHOST-PARSER-SLICE08`, only
after this ACT successfully freezes one selected candidate.

---

## 0. Mission, decision and boundaries

**Mission.** From the current live source after seven production-authoritative
compiled PolyC parser decisions and the separate literal N-06 evidence
supplement, select exactly one remaining, genuinely independent,
production-reachable, bounded and causally observable legacy-C parser/AST
semantic authority suitable for the next PolyC migration. If none qualifies,
finish with a specific, evidence-backed HALT. **This is not an implementation
ACT.**

### 0.1 Required terminal distinction

- **PASS** — complete fresh census and source binding, canonical eligibility
  and full ranking, independent re-derivation, executed selected-candidate
  causality and twenty sensitive negative controls, conservative compiler
  behavior, one immutable successor contract and a valid Factory-v2 CLOSE.
- **HALT_*** — genuine unfulfilled obligation; preserve measured evidence,
  record the exact blocker and close truthfully. A HALT is not an implied
  compiler regression.
- `SELECTED_CANDIDATE_ID=NONE` unless and until all gates required for a
  selection are satisfied. No fallback to a hand-chosen candidate.

### 0.2 Hard non-goals

No eighth production-authoritative PolyC parser component. No tracked
`src/**` or `tools/bootstrap/**` changes. No production selector flip. No AST
graph port. No parser rewrite. No edits to historical ACT/HANDOFF/evidence
trees. No retroactive alteration of N-06 or RECON06's HALT. No premature
SLICE08 implementation.

### 0.3 Material change from halted RECON06

RECON06 halted at C0 before its source census, its canonical checker/ranker,
its twenty candidate controls and any selection. **None of those unperformed
stages can be inherited as evidence.** RECON07 is a new authorization and new
measurement, with a new entry identity, new evidence namespace and a new full
C0–C4 commit range.

The later N-06 correction is separate supplemental evidence:

```text
RECON06_HISTORICAL_VERDICT=HALT_N06_FROZEN_OBLIGATION_UNPROVEN
RECON06_HISTORICAL_BLOCKS_NEXT=NO
SLICE07_HISTORICAL_N06_EXECUTED_AS_WRITTEN=NO
SLICE07_HISTORICAL_S7_CC01_POLYC_MUTATION=PROVEN
CORRECTION01_N06_LITERAL_C_MUTANT=PROVEN        # verify current committed evidence
CORRECTION01_DISPOSITION=PASS_EVIDENCE_SUPPLEMENTED   # verify trailers
RECON07_N06_GATE=CORRECTED_SUPPLEMENT_VERIFIED   # only after read-only audit
```

Never replace RECON06's HALT with PASS, claim the C mutant ran in SLICE07, or
double-count the historical PolyC experiment as independent C evidence. A
direct read-only check of the corrective ACT's CLOSE and new C-source
experiment is mandatory. Unlike RECON06, the historical mismatch itself is not
a newly unmet blocker once its later supplement is verified. If the correction
cannot be verified at this exact tree, HALT on the new, specific missing
verification — not on an automatic replay of RECON06's historical finding.

---

## 1. Binding source hierarchy and entry checks

Read the actual committed bytes, not just this document, prior prose or a
range digest:

1. `docs/factory/DOCTRINE.md`, relevant Factory-v2/F14/append-only rules,
   repository `AGENTS.md`, `.factory/epic-board.md` and `docs/ROADMAP.md`.
2. RECON05 `docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05.md`, its HANDOFF
   and `evidence/...RECON05/c2/selected-*` source/ABI/causality/controls, current
   RECON05 census and rankings.
3. RECON06 `docs/acts/...SURFACE-RECON06.md`, its HANDOFF,
   `C0/mandatory-ac-contract.tsv`, `frozen-negative-controls.tsv`,
   `n06-literal-control-audit.{md,tsv}` and `n06-machine-verification.txt`. It
   is a frozen definition and historical HALT, **not** evidence for 20 executed
   controls.
4. SLICE07 `docs/acts/...SLICE07.md`, its HANDOFF, C0/C3 control contracts/joins,
   source-bound fixture, four-generation evidence and production-authority
   measurements.
5. `docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01.md`,
   HANDOFF, `c0/frozen-n06-contract.md`, `c1/compiled-oracle-and-provenance.tsv`,
   `c2/c-only-build-and-causality.txt`, `c2/dormant-branch-anti-control.txt`,
   `c3/independent-n06-join.tsv`, `c3/independent-controls-join.tsv`,
   `c3/mandatory-ac-status.tsv`, and terminality evidence.
6. Current parser, AST and token sources, current producer/build objects, current
   Makefile/CMake graph and the unmodified canonical eligibility checker/ranker.

Read and verify the exact full ENTRY_HEAD and tree before any tracked write;
require correct main checkout, clean worktree, no Git replace refs, no
unexpected intervening commit and an intact five-commit predecessor CLOSE. If
the entry has moved, HALT; do not silently rebase the frozen authorization or
guess a new entry.

**Read-only verification of the correction** must establish that a genuine
C-authoritative selector-OFF compiler was built, only the selected legacy C
decision was mutated in a disposable worktree, that mutant compiler built
successfully, witness acceptance changed, the selector-ON build was invariant,
restoration was byte-identical, and the experiment had an identity distinct from
historical S7-CC-01. Check actual raw evidence and frozen hashes, not just a
summary verdict. The new correction is a prospective supplement, not a
retroactive SLICE07 event.

Freeze all prior ACT/HANDOFF/evidence hashes with a correction-independent
path list. The latest report mentioned 1,155 frozen paths at that correction's
C0, but this ACT must **measure its own real set** and compare exact
paths/hashes; never require an unexplained hard-coded count.

---

## 2. Hard scope, tools, environment and isolation

### 2.1 Permitted tracked changes

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/**
tools/quality/parser-surface-recon07-*.HC    # bounded new PolyC verifier(s)
Makefile                                     # additive bounded targets only
.factory/epic-board.md                       # ONLY if explicitly required by policy
```

No edits to `src/**`, `tools/bootstrap/**`, historical evidence, previous
tools/checkers/rankers, `.factory/` gate semantics, existing tests or fixtures.
No Python, new dependencies, substantial Bash driver logic, no
weakening/bypassing of any quality gate. All substantive new verifier/checker
code must be PolyC `.HC` compiled/executed with a real compiler. F-POLYC-TOOLS is
historically UNAVAILABLE; do not claim its gate PASS merely because new code is
PolyC.

### 2.2 Isolation

Use the existing checkout/branch. Use detached temporary worktrees (no new
branch) for causal C-source mutants. Isolate output roots, installation
prefixes, object files and build caches; mutation must not appear in the
authoritative working tree. The shared `/tmp/holyc-asm.s` is a known collision
hazard: execute build/JIT/test/gate steps **serially** unless independence of
temporary namespaces has been independently established. Do not repair this race
here.

If adding a Makefile target, audit prerequisite evaluation at parse time, check
that the required object actually appears in the effective dependency graph,
and that no continuation/backslash swallows a recipe. Check the real command and
exit, not an empty/no-op target. If using CMake, use isolated `-S` / `-B`
source/build directories and verify selector/compile flags from the generated
cache and objects. These are execution safeguards, not permission to change old
producer wiring.

---

## 3. Frozen baseline and programme boundaries

Entry observations to independently remeasure (historic values are hypotheses,
not fabricated current results):

| Dimension | Prior recorded identity | Mandatory treatment |
|---|---|---|
| Production parser authorities | Seven | Reprove symbol definition, caller import, selector ON, executable link and retired legacy C decision from current objects |
| Host parser suite | 376/376 assertions, 90 files | Record per-test sequence and MD5 `b6f117eb1386ca80f81bc06226e2a741`; zero new failed IDs |
| Lexer direct differentials | 89/89, 45/45, 23/23 | Require exact ID and outcome comparison |
| LEXER07 broad corpus | Historical FAIL, 15 stage-0 IDs; MD5 `7ee761440de83552e751e3c3976c1683` | Preserve failure-identity bytes; never call suite PASS |
| Cross-target | 67 `include/tos.HH` missing-prefix cases | `FAIL_ENVIRONMENT_PREFIX`; don't infer green from runner exit 0 |
| F-NO-PYTHON | 12 historical paths | Preserve exact set; zero new; report `FAIL_KNOWN_BASELINE` |
| F-POLYC-TOOLS | Authoritative checker not landed | `UNAVAILABLE`, not PASS |
| Gates | gate-fast, gate-push, F14, append-only, closure-status, patch hygiene | Execute, record command/exit and truly observed PASS |

Preserve seven authorities: `BootstrapCalcPadding`,
`BootstrapValidPostControlFlowToken`, `BootstrapOperatorPrecedence`,
`BootstrapAstBinOpFromToken`, `BootstrapAstUnaryOpFromToken`,
`BootstrapSwitchArmTerminates`, `BootstrapCompoundBlockAppendsStatement`.
Confirm exact current symbols from the binary, not name-only prose; accept no
silent relocation to C, and do not treat old C adapters as active C semantic
authority.

A healthy post-SLICE07 compiler is a prerequisite, but no whole-parser or
whole-AST self-hosting claim is authorized.

---

## 4. Full live-source census and candidate registry

Re-inventory from live bytes all functions and semantic sub-decisions in:

```text
src/parser.c
src/prslib.c
src/prsutil.c
src/ast.c
```

Use the existing source-byte RECON04/RECON05 verifier read-only as a cross-check
where applicable, and independent PolyC-derived source-range/function binding.
Each census row must include file, function, start/end byte offset, start/end
line, SHA-256 of exact source range, active production call path, classifier,
authority owner, and an explicit change reason against RECON05. RECON05
historically reported 270 functions; RECON06 did not conduct a newer census.
**Current total is not assumed to be 270 or any extrapolation.** Compute
two-way set differences added/removed/changed/unchanged from exact source
identities; explain every row; `UNCLASSIFIED=0`, `UNKNOWN=0`, `DUPLICATE=0`, no
invalid or overlapping ranges.

### 4.1 Mandatory historical structural IDs

| Candidate | Historical description / treatment | RECON07 obligation |
|---|---|---|
| SUB-001 | Switch-arm termination, migrated SLICE06 | Exclude as remaining legacy-C authority; preserve active PolyC authority |
| SUB-002 | Default-arm termination in `parseDefaultStatement` | Rebind source/caller. RECON05's AST_DEFAULT-addition mutant had no observed effect; one no-effect mutant does not prove every possible mutation is inert. Establish actual distinctness and reachability with controlled source-specific probes; no automatic promotion |
| SUB-003 | Compound-block append/skip, migrated SLICE07 | Exclude as remaining legacy-C authority; preserve active PolyC authority |
| SUB-004 | Keyword-to-statement-constructor dispatch in `parseStatement` | Fresh source/range/ABI, token semantics, reachable caller, and current successful real-compiler causal probe. Prior KW_WHILE probe is historical, not proof of today's behavior |
| SUB-005 | `cctrlIsKeyword` mutable symbol-table dependence | Treat as ineligible until live transitive dependence on mutable `cc->symbol_table`, class/union definitions or other host state is actually eliminated or bounded and proven |
| SUB-006..SUB-012 | Recovery, compound loop, whole statement/expression parser and recursive flow walks (historically excluded) | Re-evaluate every ID from current source; record exact control-flow/graph/recovery blocker. Whole-function ineligibility must not conceal an independently bounded sub-decision |

Also account for all twelve historical scalar follow-ups by their actual
canonical IDs (do not fabricate identifiers) and any genuinely new discovered
candidate. Preserve RECON05's CAND-022/CAND-023 R0 correction as current facts;
do not edit RECON04's historical ranking or guess any new R0 semantics.
Identify and disposition PARSER01's `parseCompoundStatementInternal`,
`parseStatement`, `parseExpr` and recursive-flow whole-function blockers,
explaining graph ownership, callbacks, diagnostics, recovery, token cursor,
mutable table dependence and feasibility. A candidate's eligibility is
evaluated for its precise sub-decision, not by applying whole-function blockers
to unrelated independent scalar branches.

### 4.2 Required per-candidate record

```text
candidate_id, class, exact source range/hash, function, caller, call path
input projection and its conditional reads, value domain, sentinel/output semantics
production reachability and branch preconditions
semantic authority (legacy C / PolyC / passive adapter / dead)
C host ownership retained (AST, token, allocations, callbacks, recovery, diagnostics)
transitive mutable-host-state dependencies and source-bound call edges
host graph writes / pointer identity / callback / recovery gate values
13 raw eligibility facts, R0..R6 facts, evidence paths and exclusion explanation
candidate-specific causal witness feasibility, not just boolean labels
```

Never use an ad-hoc `eligible` column in the raw C1 facts. A candidate that
relies on an unbounded mutable symbol table, pointer graph mutation,
parser/semantic callbacks, nonlocal recovery or unexamined short-circuit reads
is not silently scalarized into an apparently safe ABI.

---

## 5. Canonical eligibility, ranking, exclusion and selection

Use the unmodified compiled PolyC checker
`tools/quality/parser-slice-recon03-eligibility.HC` and ranker
`tools/quality/parser-slice-recon03-ranking.HC`. Bind executable hashes,
input hashes, schema, output IDs and exit status. If the canonical schema
cannot express a genuinely discovered dependency, `HALT_CANONICAL_SCHEMA_UNFIT`;
do not fork the ranker inside this ACT or emit hand-authored eligibility.

### 5.1 The thirteen established eligibility clauses (in order)

1. Actual semantic authority
2. Not already self-hosted
3. Bounded R0
4. No setjmp ownership
5. No writes to current recovery state
6. No nonlocal recovery
7. No host AST/graph writes
8. No pointer-identity operation
9. No parser callbacks
10. No semantic callbacks
11. Deterministic bounded projection
12. Feasible production delegation
13. Runtime semantic authority

Additionally require actual production reachability, not merely a syntactically
present branch.

Run the canonical R0..R6 ranker on the checker-qualified current population.
Preserve the canonical rank order and tie-break rules, including source binding.
Record the complete eligible order and the complete excluded set. The first
eligible structural candidate must be tested for successful causal feasibility
before proceeding to the next. On a concrete failed causal/provenance gate,
record the exact measured disqualification, then deterministically continue;
never hand-pick a favorite. If no bounded independent causal structural
candidate passes, consider eligible scalar follow-ups under the same canonical
policy with explicit proof of a distinct production effect. If none passes,
HALT.

A top-ranked candidate rejected by execution is not automatically eligible again
because a different, untested mutant could be imagined. Conversely, one harmless
mutant is not universal proof of semantic duplication. Require a bounded,
source-derived mutation set covering distinct decision outcomes and reachability;
distinguish `UNOBSERVED`, `UNREACHABLE`, `DUPLICATED_AUTHORITY`,
`FAILED_COMPILER_BUILD`, and `INELIGIBLE` rather than collapsing them into an
undocumented exclusion. If a decisive classification cannot be proved, HALT
rather than promote an unproven candidate.

### 5.2 Independent C3 recomputation

C3 must independently derive all thirteen clause results from the raw C1 facts
**without reading C2's eligible output**, and reconstruct the full R0..R6 order
**without reading C2's ranking or selected ID**. Use an independently implemented
PolyC recomputer (or an independently verified existing implementation if it
genuinely has separate dataflow and authority), not the canonical ranker's
output with labels changed. Join by exact candidate IDs and source range hashes.
Require 0 missing, extra, duplicate, clause disagreements, wrong ties and
full-order mismatches. Prove the selected ID equals the deterministic first
feasible winner after recorded exclusions.

---

## 6. Real object-level oracle, source-bound fixtures and compiler causality

For each tested provisional leader and the final selected candidate:

1. **G0.** Produce G0 from the actual production C translation unit, compiled
   from the current entry source with the relevant prospective delegation
   disabled/not yet introduced. No synthetic equivalent C function, hand-written
   oracle or PolyC-dependent G0. Inspect the real object, compiler command and
   object imports. If there is already a selector, use a genuine isolated
   C-authoritative configuration. If a selector/ABI assumption is wrong, HALT.
2. **Fixture.** Derive fixture partitions from live enum/token/source values,
   including positive, negative, boundary, unreachable/sentinel and
   short-circuit cases as appropriate. Record unique ordered row IDs, input
   value tuples, expected outputs, source hashes and provenance. Independently
   parse live definitions to verify constants rather than copying fixtures into
   the verifier.
3. **Witness.** Identify a predeclared authentic real-compiler witness and
   observation channel **before** mutations: e.g. compile acceptance plus
   diagnostic identity, emitted compiled-program semantics, or exact parser
   assertion identity. Compiler build must succeed for pristine, mutant and
   restored compilers; a witness compile failure after a successful mutant
   compiler rebuild can be a valid `COMPILER_ACCEPTANCE_CHANGED` observation,
   and must not be mislabeled `RUNTIME_OUTPUT_CHANGED`.
4. **Mutation.** In a detached worktree rooted at exact entry, mutate only that
   selected legacy C decision (not its oracle, PolyC code, fixture or tests),
   successfully rebuild the real compiler, execute the same witness and targeted
   regression probes, record a candidate-specific observable change and the exact
   affected row IDs. Rebuild once after restoring the C source and prove
   byte-identical source restoration and pristine witness identity. Keep
   authoritative main untouched.
5. **Function-scoped authority.** Require compiled authority and function-scoped
   object evidence: source/range binding, call path, relocation/calls and
   relevant comparisons within the selected function, not unrelated cmp/tst
   instructions elsewhere. Negative-control a false attribution from another
   function.
6. **Four-generation plan.** For the eventual SLICE08, freeze a four-generation
   plan (G0 genuine C TU; G1/G2/G3 distinct compiler-binary identities, expected
   subject objects, fixture/semantic differential and independent provenance
   negative controls). **RECON07 MUST NOT falsely claim G1/G2/G3 were executed**
   if they are to be executed in SLICE08.

### 6.1 Prevent the N-06 proof-subject mistake in the next successor

Do not freeze an ambiguous instruction saying merely "mutate the selected
decision" while expecting a post-migration C mutation. The selected successor
contract must contain **two named, separate, time-scoped controls** (identifiers
frozen in C2, not invented afterward):

- **PRE-C-MUTANT** — pre-migration / C-authoritative legacy source, actual C
  decision, detached worktree, successful real compiler rebuild and
  source-specific causal observation. This may cite a RECON07 experiment with
  its own execution ID, but only as a recorded pre-migration event.
- **POST-POLYC-MUTANT** — post-migration / production PolyC-authoritative
  source, actual compiled PolyC component, successful real compiler rebuild,
  causal observation and byte-identical restoration. This must be **newly
  executed by SLICE08 after delegation**, not merely inferred from the C
  experiment.

If the successor also inherits a demand for a C mutant during SLICE08, specify
a separate selector-OFF C-authoritative experiment under a distinct ID, just as
the N-06 correction did. Each control must bind phase, source subject, selector
state, compiler producer, object hash, actual build/exit, witness channel,
execution ID, restoration and whether reusing a prior experiment is explicitly
allowed. Default is no reuse of another subject/phase. One experiment must not
silently discharge two independently required controls; multiple IDs referring
to one permitted shared execution must explicitly say they share it and must not
claim experiment independence.

---

## 7. Frozen 20-control plan (new ACT ownership, unchanged control semantics)

Freeze a new RECON07-owned ledger at C0 with these exact IDs, intended adverse
action and detector class. The definitions originate in RECON06 C0 but RECON06
executed none; do not inherit its observed statuses. Every control requires an
actual adverse execution, a positive baseline, an exact reason-specific
detector, an exit/result, scope and restoration/containment. All twenty must be
executed and independently verified (**no PASS by pristine-only inspection**).

| ID | Adverse action | Required nonvacuous detector |
|---|---|---|
| IC-01 | Delete one live inventory function | Missing exact source/function ID |
| IC-02 | Duplicate one function/candidate ID | Duplicate exact ID |
| IC-03 | Alter one source-range SHA-256 | Exact source hash mismatch |
| IC-04 | Invalid, out-of-file or overlapping identity range | Invalid range/overlap, not generic parse failure |
| EC-01 | Mark SUB-001 or SUB-003 newly eligible C authority | Already-self-hosted exclusion |
| EC-02 | Suppress an actual transitive mutable-host-state dependence (SUB-005 or current equivalent) | Source/call-graph dependency detector |
| EC-03 | Insert nonzero host AST graph write in candidate facts | Host-graph-write clause |
| EC-04 | Inject callback or recovery ownership | Correct separate eligibility clause |
| EC-05 | Add unreachable candidate with excellent rank | Actual reachability exclusion |
| EC-06 | Unknown ID or missing required eligibility fact | Unknown-ID or missing-fact-specific detector |
| RC-01 | Shuffle genuine facts; then submit forged order-dependent ranking | Genuine ranker invariant; independent full-order comparator rejects forged order |
| RC-02 | Give an excluded candidate lowest numeric rank | Remains excluded, not promoted |
| RC-03 | Remove provisional feasible leader | Deterministic next selection or explicit NONE, not stale leader |
| RC-04 | Perturb one controlled R0..R6 dimension | Predicted complete-order change checked |
| RC-05 | Preserve ID but substitute stale source range/call site | Source identity/reachability rejection |
| CC-01 | Mutate selected C decision and rebuild real compiler | Successful mutant build + changed correct witness channel |
| CC-02 | Substitute handwritten/PolyC-dependent G0 oracle | Production-object provenance rejection |
| CC-03 | Corrupt one fixture expected output | Exact semantic row ID mismatch |
| CC-04 | Put comparison instructions in unrelated function/object | Function-scoped authority detector rejects |
| PV-01 | Relabel one producer compiler as another bootstrap binary | Actual binary identity/provenance rejection |

For **RC-01**, the real ranker's order must be identical under genuine shuffled
inputs; the forged order must be rejected by the independent comparator — both
halves required. For **EC-02**, prove transitive source/call-graph binding, not
regex matching only the candidate body. For **CC-01**, distinguish the selected
pristine/mutant/restored compiler build exit from the witness compile/run
exits. Re-run CC-01 through CC-04 on the final selected subject if it differs
from the provisional leader; do not borrow the provisional subject's controls.
The C3 independent join requires exactly 20 control IDs with zero missing,
extra, duplicates, vacuous, unexecuted or unrestored subjects.

---

## 8. C0 — RED: identity, N-06 supplement audit, freeze, fresh baselines

1. Verify full ENTRY_HEAD/TREE, exact current branch and worktree, no replace
   refs, no new intervening commits. Confirm this new ACT has no prior CLOSE.
   HALT if entry does not match.
2. Verify the correction's five-commit Factory-v2 range, terminal trailers,
   freeze, `PASS_EVIDENCE_SUPPLEMENTED`, distinct C-mutant and PolyC-mutant
   identities and actual raw causal/anti-control evidence. Preserve RECON06's
   literal HALT. Record `RECON07_N06_SUPPLEMENT_VERIFIED=YES` only on direct
   independent evidence.
3. Freeze all prior ACT/HANDOFF/evidence hashes with an ACT-owned manifest and
   verify path identity as well as hashes. Reject missing or altered historical
   paths.
4. Object-verify the seven production PolyC authorities (definitions, imports,
   selectors, relocation/link, compiled-out C decision), with exact
   source/object hashes.
5. Freshly measure parser/lexer/LEXER07/cross-target/tool-policy/Factory/gate
   baselines, including exact failure identity sets, under serialized builds.
   Preserve historical nonzero statuses honestly.
6. Freeze this ACT's exactly 50 acceptance predicates (section 13) and twenty
   negative controls (section 7) as actual committed machine-readable source
   **before** seeing adverse outcomes. Record five independently executable
   REDs: an unmapped function, an unbound candidate hash, a forged eligibility
   decision, a forged full ranking and a mutant with no provenance/witness link.
   Record actual rejection outputs; do not assert a RED if only planned.
7. Validate exact Factory-v2 trailers with the repository's canonical checker
   before committing C0 as `ACT-Phase: RED`.

**C0 HALT cases:** entry mismatch, correction evidence absent/contradictory,
freeze mismatch, unverified production authority, unexplainable new regression,
or inability to freeze authoritative contracts.

---

## 9. C1 — EVIDENCE: source-derived inventory and dependency analysis

1. Produce full source-byte census of all four translation units with exact
   ranges/hashes, independently cross-check with known source inventory
   methodology; reconcile RECON05's 270 rows through true two-way set
   differences. Do not guess a current total or copy old rows.
2. Enumerate SUB-001..012 and twelve scalar candidates by their canonical IDs,
   including all truly new candidates with unique IDs. Separate adapters left
   in C from active C semantic decisions.
3. Build source-bound call paths and transitive host-state dependency graph;
   measure actual callback, token, graph, symbol-table, diagnostic, recovery and
   short-circuit/conditional read constraints.
4. Re-evaluate SUB-002 causal duplication, SUB-004 keyword dispatch, SUB-005
   mutable state and all PARSER01 whole-function blockers without presuming
   eligibility or rank.
6. Demonstrate source-range/hash sensitivity with actual adverse input before
   accepting the census. C1 artifacts and census must be reproducible and
   current-tree-bound.
7. Commit C1 `ACT-Phase: EVIDENCE`; no tracked compiler source changed.

**C1 HALT cases:** incomplete/misaligned function inventory, unresolved
candidate ID, unbound production path, unknown transitive dependence, source
hash/range errors or unclassified candidate.

---

## 10. C2 — IMPL (selection tooling only): eligibility, ranking and causal selection

**IMPL refers to the ACT-owned selection evidence/tools, not to a production
compiler implementation.**

1. Compile/run the unmodified canonical 13-clause eligibility checker and
   R0..R6 ranker, verify executable identities, zero unknown/malformed/duplicate
   IDs, complete eligible/excluded populations and full deterministic ordering.
   If current schema is invalid, HALT rather than edit canonical tools.
2. For each provisional top candidate, validate exact real production
   reachability and bounded, deterministic ABI with all C host ownership
   explicitly retained. Check scalar decision independence from already-migrated
   authorities.
3. Build a real production C TU G0 oracle and source-derived fixture. Execute a
   source-bound real-compiler C mutation in a disposable worktree. Record
   successful pristine/mutant/restored compiler builds, exact witness channel,
   exact differentiated row IDs, source/object provenance and byte-identical
   restoration. Distinguish wrong-subject, no-effect and failed compiler build.
   If a candidate fails, append its specific exclusion and continue strictly in
   canonical order.
4. Exercise all twenty control identities, including final selected subject's
   CC-*, and produce raw outcomes/provenance. No false-green skip or reuse of
   unrelated C2 evidence.
5. Select exactly one candidate with complete full ranking + executable
   feasibility, or HALT without any successor authorization. Freeze successor
   source hash, production seam, ABI, oracle, fixture, causal contract,
   generation/provenance plan, conservation, stage-specific negative controls,
   prerequisites, disqualifications and authority limits. Sign/bind these
   artifacts by SHA-256. **Do not implement the selected decision in PolyC.**
6. Commit C2 `ACT-Phase: IMPL` with the verified selection artifacts only.

**C2 HALT cases:** canonical schema mismatch, no bounded observable candidate,
defective G0 object provenance, successful compiler build unproven, mutation
detector insensitive, incomplete control IDs, incomplete restoration or
ambiguous selected ID.

---

## 11. C3 — EVIDENCE: independent verification and conservation

1. Independently parse C1 raw facts and rederive each of the thirteen
   eligibility bits, the complete R0..R6 order and deterministic winner
   **without reading the canonical C2 eligibility/ranking/winner columns**.
   Exact ID+source hash join required; `ELIGIBILITY_MISMATCH=0`,
   `FULL_RANKING_MISMATCH=0`, `SELECTED_ID_MISMATCH=0`.
2. Independently verify the C2 G0 object is real production C, the C source
   mutation affects exactly the selected range, the genuine compiler rebuild
   succeeds, the predeclared witness changes on the correct channel, and
   restoration restores exact source and behavior. Function-scoped disassembly
   and real provenance controls must reject decoy instructions/objects.
3. Independently join all twenty controls by exact ID to concrete adverse
   commands, intended/observed detector classes, subjects, input/object/producer
   hashes, exit codes, restored bytes and positive controls. All 20 genuinely
   sensitive. Verify no duplicated experiment falsely represented as two
   independently executed events.
4. Cross-check every frozen successor artifact: selected ID/range/hash,
   conditional projections, host-owned AST/recovery/callback/token state,
   stage-specific PRE-C-MUTANT / POST-POLYC-MUTANT controls and G0→G3
   four-generation feasibility. Do not misreport future four-stage proof as
   executed.
5. Re-run parser (376/376 over 90 files and identity-sequence), lexer direct
   differentials and LEXER07 broad-corpus failure-identity file; verify exact
   new regressions = 0. Record cross-target 67 prefix failures, 12 F-NO-PYTHON
   violations, unlanded F-POLYC-TOOLS checker truthfully. No reclassification to
   all-green.
6. Run gate-fast, gate-push, Factory-v2, append-only, F14, closure status and
   patch hygiene **serially**. Require real command exit 0 and canonical PASS
   for mandatory gates. Verify closed predecessor hashes, `git replace -l`
   empty, scoped tracked diff, and actual dependency graph for any new Makefile
   target.
7. Join AC01..AC49 by exact frozen ID, each PASS; only AC50 may be
   `DEFERRED_TO_CLOSE`. A failing or unproven mandatory predicate forces an
   exact HALT, not a PASS in prose.
8. Commit C3 `ACT-Phase: EVIDENCE` and include immutable evidence/hashes.
   **Never write a claimed after-CLOSE receipt to C3/C4 as if it were already
   observed.**

---

## 12. C4 — one terminal CLOSE, conditional successor handoff

1. Prepare ACT-specific HANDOFF, managed `act-handoff-map.tsv` row, bounded
   roadmap update and (only if repo policy requires) epic-board state. The
   HANDOFF must say what this ACT actually established. Include the full ranked
   candidate population, disqualification reasons, selected exact ID/ABI or
   explicit NONE, the read-only N-06 supplement check, historical HALT
   preservation and all honest residual failures.
2. Prevalidate all four earlier commit trailers and the intended CLOSE message
   with the repository's Factory-v2 message/range checks. **Exactly one C4
   CLOSE**; no amend/rebase/replay/force-push of published history. If the
   repository's exact trailer schema is stricter than this document, follow the
   canonical checker and HALT on conflict.
3. Close with `ACT: ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07`,
   `ACT-Phase: CLOSE` and `ACT-Verdict: PASS` **only when** the 49 C3 criteria
   and all prerequisite controls are satisfied. For a HALT, use the canonical
   `HALT_*` verdict and required doctrine HALT_CLASS/BLOCKS_NEXT metadata, with
   no fake selected candidate.
4. Perform external read-only post-CLOSE terminality checks: full final
   HEAD/tree, linear range count, exact CLOSE trailer, clean worktree, zero
   replace refs, no post-CLOSE commits, Factory-v2 range, F14 and append-only,
   complete 50-AC ledger with AC50 post-CLOSE, and one intact handoff. **Do not
   retroactively place this receipt into the tracked terminal CLOSE commit or
   create a sixth commit to store it.**
5. Only a terminal PASS may set `NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE08`,
   `NEXT_ACT_STATUS=READY_TO_DRAFT` and a single `NEXT_TARGET=<selected ID>`. A
   PASS does not authorize executing or closing SLICE08 without its own ACT and
   entry check. A HALT must leave `NEXT_TARGET=NONE` and
   `SLICE08_AUTHORIZED=NO`.

---

## 13. Exactly 50 mandatory acceptance criteria

The `c0/mandatory-ac-contract.tsv` must freeze precisely these predicates by ID
and phase, and the C3 ledger must join them by ID to real evidence (not just
descriptions).

| ID | Phase | Mandatory predicate |
|---|---|---|
| AC01 | C0 | Exact entry HEAD, tree, branch, clean tracked/untracked state, zero replace refs |
| AC02 | C0 | Correction01 five-commit CLOSE and supplemental N-06 execution independently verified |
| AC03 | C0 | RECON06 historical HALT and SLICE07 historical PASS preserved exactly, without retroactive relabeling |
| AC04 | C0 | Frozen predecessor path/hash manifest complete; zero mutations or missing paths |
| AC05 | C0 | Seven current PolyC parser authorities independently proven from selectors/objects/binary |
| AC06 | C0 | Fresh parser/lexer/LEXER07/cross-target/tool-policy/gate baseline recorded with honest statuses |
| AC07 | C0 | No unauthorized production/bootstrap source change, Python, dependency or ceremonial branch |
| AC08 | C0 | Exactly 50 AC and 20 negative-control definitions frozen before adverse observations |
| AC09 | C0 | Five distinct nonvacuous REDs executed and recorded with actual rejections |
| AC10 | C0 | No RECON06 halted execution status reused as RECON07 evidence |
| AC11 | C1 | Full source-byte census of parser.c/prslib.c/prsutil.c/ast.c |
| AC12 | C1 | Each live function has independently valid range, exact source SHA-256 and call/source identity |
| AC13 | C1 | No missing, UNKNOWN, duplicate, overlapping or conflicting classification |
| AC14 | C1 | RECON05 270-row census reconciled via exact added/removed/changed/unchanged sets |
| AC15 | C1 | All seven retired legacy decisions distinguished from remaining C adapters and semantic owners |
| AC16 | C1 | SUB-001..SUB-012 exhaustively reconciled to current source with classifications |
| AC17 | C1 | SUB-001 and SUB-003 excluded as remaining C authority without losing production PolyC owners |
| AC18 | C1 | SUB-002 duplication/causality grounded in current controlled observations, not stale assumption |
| AC19 | C1 | SUB-004 keyword dispatch source, reachable callers and distinct semantic effect rebound |
| AC20 | C1 | Twelve historical scalar follow-ups present with real canonical IDs or justified disposition |
| AC21 | C1 | PARSER01 whole-function/recursive-flow candidates explicitly classified, sub-decision boundaries preserved |
| AC22 | C1 | SUB-005 and all transitive mutable symbol-table/host-state edges checked against live graph |
| AC23 | C1 | Newly found candidates source-bound under collision-free IDs, no invented/wrong identity |
| AC24 | C1 | All candidates have complete raw 13-clause/R0..R6 facts, without handwritten eligibility/rank |
| AC25 | C2 | Selected ABI copy-only, deterministic, source-bound and explicitly covers conditional reads/sentinels |
| AC26 | C2 | C retains AST/token/allocation/callback/recovery/diagnostic ownership for selected seam |
| AC27 | C2 | Exactly one chosen production-reachable independent legacy-C decision; else no PASS |
| AC28 | C2 | Real compiled unmodified canonical 13-clause eligibility checker executed on source-derived facts |
| AC29 | C2 | Full eligibility population/exclusions computed from checker with no manual eligible column |
| AC30 | C2 | Real compiled unmodified canonical R0..R6 ranker executed on complete eligible population |
| AC31 | C2 | RECON05 CAND-022/023 R0 correction preserved without rewriting RECON04 history |
| AC32 | C3 | Independent 13-clause re-derivation from raw facts matches every ID and clause |
| AC33 | C3 | Independent entire R0..R6 rank and tie/order recomputation matches every eligible candidate |
| AC34 | C3 | Each ranked exclusion/failure has precise source-bound executable reason; winner is deterministic |
| AC35 | C2/C3 | All 20 negative controls actually executed, subject-specific, sensitive and independently joined |
| AC36 | C2 | G0 oracle is genuine production C TU object, no PolyC dependence or hand-written substitute |
| AC37 | C2 | Fixture complete, source-derived and independently bound to live enums/semantic partitions |
| AC38 | C2 | Pristine, C-mutant and restored real compilers build successfully in isolated worktree |
| AC39 | C2 | Predeclared real witness changes on declared causal channel; wrong-channel/failure rejected |
| AC40 | C2 | Restored C source bytes and pristine real-compiler witness behavior identical |
| AC41 | C3 | Four-stage future G1/G2/G3 compiler/object identity and producer feasibility documented, not claimed executed |
| AC42 | C2/C3 | Selected frozen contract complete, source/ABI/causal/control hashes internally consistent |
| AC43 | C3 | Parser 376/376 sequence identities preserved; zero new parser failures |
| AC44 | C3 | Lexer direct diffs and exact historical LEXER07 failure IDs preserved; zero new failures |
| AC45 | C3 | Cross-target 67, F-NO-PYTHON 12 and F-POLYC-TOOLS UNAVAILABLE reported truthfully |
| AC46 | C3 | Serialized real gate-fast and gate-push execute and PASS, commands/exits captured |
| AC47 | C3 | Factory-v2/F14/append-only/closure/hygiene and exact predecessor freeze PASS |
| AC48 | C0–C4 | Validated trailers before commits, no replay/amend/force-push, correct tracked scope |
| AC49 | C3 | AC01–AC49 have exact-ID real evidence PASS; only AC50 is DEFERRED_TO_CLOSE |
| AC50 | C4 | Exactly one terminal CLOSE and independently observed external read-only post-CLOSE terminality PASS |

**Interpretation.** A C0..C3 HALT leaves undischarged criteria UNPROVEN rather
than retrospectively marking them FAIL or PASS. A terminal PASS requires
AC01..AC50 evidenced, including AC50's post-CLOSE verification. A precommitted
post-CLOSE checklist is not proof that post-CLOSE observations have already
occurred.

---

## 14. Frozen successor contract — required on PASS only

Place an ACT-owned `c2/selected-*` set with exact SHA-256 entries and at least
these files (names may vary only if the repository's canonical HANDOFF scheme
requires it):

```text
selected-source-and-identity.md
selected-production-seam.md
selected-abi.md
selected-enums-fixture.tsv
selected-real-c-oracle.md
selected-causal-contract.md
selected-generation-and-provenance.md
selected-negative-controls.md
selected-conservation-contract.md
selected-red-contract.md
selected-scope-and-ownership.md
selected-ranking-and-exclusions.tsv
successor-authorization.md
selected-contract-hashes.tsv
```

The frozen successor must specify which source field reads are conditional and
why; exact candidate/ABI, output sentinels, host ownership exclusions,
original G0 object producer, exact production selector and build linkage, G1–G3
distinct producer identities expected, fixture partitions and equality rules,
full negative controls with explicit pre-C vs post-PolyC subjects, independent
proof and mutation/restoration instructions, authorized files/forbidden files,
known baseline failures, and the single next ACT identity. Explicitly state
`SUCCESSOR_IMPLEMENTATION_DELTA=0` for RECON07.

**Do not prewrite a selected SUB-004, SUB-002 or scalar ID into these files.**
The chosen ID is a computed output of the live evidence and canonical procedure.

---

## 15. ACT-owned evidence tree

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07/
  c0/
    entry-identity.txt
    predecessor-and-n06-supplement-audit.md
    predecessor-freeze.tsv
    seven-production-authorities.tsv
    baseline-parser.txt
    baseline-lexer.txt
    baseline-lexer07.txt
    baseline-cross-target.txt
    baseline-tool-policy.txt
    baseline-gates.txt
    mandatory-ac-contract.tsv
    negative-controls-contract.tsv
    red-reproduction.txt
  c1/
    live-functions.tsv
    function-range-hashes.tsv
    recon05-two-way-reconciliation.tsv
    structural-subslices.tsv
    scalar-candidates.tsv
    candidate-registry.tsv
    production-callgraph.tsv
    host-state-and-recovery-dependencies.tsv
    raw-eligibility-facts.tsv
    raw-ranking-facts.tsv
    census-controls.txt
  c2/
    canonical-eligibility-input.tsv
    canonical-eligibility-output.tsv
    canonical-full-ranking.tsv
    provisional-candidates-and-dispositions.tsv
    candidate-causality-raw.tsv
    controls-raw.tsv
    source-fixture-and-oracle.txt
    selected-*                # only after selection
    successor-authorization.md  # only after selection
  c3/
    independent-eligibility-join.tsv
    independent-full-ranking-join.tsv
    independent-controls-join.tsv
    independent-causal-proof.txt
    provenance-and-freeze.txt
    parser-conservation.txt
    lexer-conservation.txt
    lexer07-failure-identities.txt
    cross-target-and-policy-residue.txt
    gate-fast.txt
    gate-push.txt
    factory-invariants.txt
    mandatory-ac-status.tsv
  c4/
    terminality-plan.txt   # pre-CLOSE checks/plan only; not forged after-CLOSE receipt
```

Raw transcripts must either be stored or referenced by exact digest and
reproducible command. A claimed `STATUS=PASS` with no input/output identity,
command, or detector is not evidence. External post-CLOSE receipts remain
outside the tracked terminal commit; no subsequent tracked changes.

---

## 16. Exact HALT taxonomy (use first true blocker)

```text
HALT_ENTRY_IDENTITY
HALT_PREDECESSOR_TERMINALITY_UNVERIFIED
HALT_N06_SUPPLEMENT_UNVERIFIED
HALT_FROZEN_ARTIFACT_MUTATED
HALT_EXISTING_AUTHORITY_UNVERIFIED
HALT_INCOMPLETE_CENSUS
HALT_UNBOUND_SOURCE_OR_RANGE
HALT_UNCLASSIFIED_DEPENDENCY
HALT_MUTABLE_HOST_STATE_LEAK
HALT_GRAPH_CALLBACK_OR_RECOVERY_OWNERSHIP
HALT_CANONICAL_SCHEMA_UNFIT
HALT_ELIGIBILITY_MISMATCH
HALT_FULL_RANKING_MISMATCH
HALT_UNREACHABLE_OR_DUPLICATE_DECISION
HALT_NO_BOUNDED_CAUSAL_CANDIDATE
HALT_G0_NOT_REAL_PRODUCTION_OBJECT
HALT_FIXTURE_ORACLE_UNPROVEN
HALT_MUTANT_COMPILER_BUILD_FAILURE
HALT_WRONG_CAUSAL_OBSERVATION_CHANNEL
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_SOURCE_RESTORATION_NOT_IDENTICAL
HALT_NEW_PARSER_OR_LEXER_FAILURE
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_V2_OR_F14_OR_APPEND_ONLY
HALT_MANDATORY_AC
HALT_TERMINALITY
```

For any HALT, preserve all completed evidence, record unexecuted controls/ACs
as UNPROVEN, leave `SELECTED_CANDIDATE_ID=NONE` unless a candidate had been
provisionally measured (never authorize it on HALT), and apply actual current
DOCTRINE §25 blocking classification — **not a guessed BLOCKS_NEXT value**. No
corrective source changes under this ACT. If a bounded correction is needed,
authorize separately and preserve this ACT's terminal result.

---

## 17. Exact terminal report schema

```text
ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07
VERDICT=<PASS|HALT_*>
HALT_REASON=<NONE|exact>
ENTRY_HEAD=34c2b6babbffc15c10cf2515085a6414bb8e3d77
ENTRY_TREE=17e2d5b0170763c55dff93a26e896e21efc98bbf
FINAL_HEAD=<measured>
FINAL_TREE=<measured>
ACT_COMMIT_COUNT=<measured>
WORKTREE_CLEAN=<YES|NO>
GIT_REPLACE_REFS=<measured>
POST_CLOSE_COMMITS=<measured>
PREDECESSOR_CORRECTION_PASS_VERIFIED=<YES|NO>
RECON06_HISTORICAL_VERDICT=HALT_N06_FROZEN_OBLIGATION_UNPROVEN
RECON06_HISTORICAL_ARTIFACTS_UNCHANGED=<YES|NO>
SLICE07_HISTORICAL_N06_EXECUTED_AS_WRITTEN=NO
CORRECTION01_NEW_LITERAL_N06_VERIFIED=<YES|NO>
N06_AND_S7_CC01_HISTORICALLY_INDEPENDENT=NO
PREDECESSOR_HASH_PATHS=<measured>
PREDECESSOR_HASH_MISMATCHES=<measured>
CURRENT_POLYC_PARSER_AUTHORITIES=<measured>
LIVE_FUNCTIONS_TOTAL=<measured|NOT_REACHED>
RECON05_FUNCTIONS_ADDED=<measured|NOT_REACHED>
RECON05_FUNCTIONS_REMOVED=<measured|NOT_REACHED>
RECON05_FUNCTIONS_CHANGED=<measured|NOT_REACHED>
RECON05_FUNCTIONS_UNCHANGED=<measured|NOT_REACHED>
UNCLASSIFIED_FUNCTIONS=<measured|NOT_REACHED>
UNCLASSIFIED_SUBSLICES=<measured|NOT_REACHED>
UNCLASSIFIED_DEPENDENCIES=<measured|NOT_REACHED>
CANDIDATE_POPULATION=<measured|NOT_REACHED>
ELIGIBLE_STRUCTURAL=<measured|NOT_REACHED>
ELIGIBLE_SCALAR=<measured|NOT_REACHED>
SUB002_DISPOSITION=<source-bound|NOT_REACHED>
SUB003_ALREADY_MIGRATED=YES
SUB004_DISPOSITION=<source-bound|NOT_REACHED>
SUB005_DISPOSITION=<source-bound|NOT_REACHED>
CANONICAL_ELIGIBILITY_MISMATCH=<measured|NOT_REACHED>
INDEPENDENT_ELIGIBILITY_MISMATCH=<measured|NOT_REACHED>
INDEPENDENT_FULL_RANKING_MISMATCH=<measured|NOT_REACHED>
SELECTED_CANDIDATE_ID=<exact ID|NONE>
SELECTED_CLASS=<class|NONE>
SELECTED_SOURCE_FILE=<path|NONE>
SELECTED_SOURCE_RANGE=<range|NONE>
SELECTED_SOURCE_SHA256=<sha256|NONE>
SELECTED_ABI=<signature|NONE>
SELECTED_PRODUCTION_SEAM=<source-bound|NONE>
SELECTED_REAL_G0_PRODUCTION_C_OBJECT=<path/hash|NONE>
SELECTED_PRISTINE_COMPILER_BUILD=<PASS|NONE>
SELECTED_MUTANT_COMPILER_BUILD=<PASS|NONE>
SELECTED_RESTORED_COMPILER_BUILD=<PASS|NONE>
SELECTED_CAUSAL_OBSERVATION_CHANNEL=<channel|NONE>
SELECTED_PRISTINE_WITNESS=<observation/hash|NONE>
SELECTED_MUTANT_WITNESS=<observation/hash|NONE>
SELECTED_RESTORED_WITNESS=<observation/hash|NONE>
SELECTED_RESTORATION_BYTE_IDENTICAL=<YES|NO|NONE>
FUTURE_G1_G2_G3_EXECUTED=NO
FUTURE_G1_G2_G3_FEASIBILITY=<PROVEN|NOT_REACHED>
NEGATIVE_CONTROLS_TOTAL=20
NEGATIVE_CONTROLS_PASS=<measured>
NEGATIVE_CONTROLS_UNPROVEN=<measured>
NEGATIVE_CONTROLS_VACUOUS=<measured>
PARSER_ASSERTIONS=<measured>
PARSER_ASSERTION_SEQUENCE_MD5=<measured>
NEW_PARSER_FAILURE_IDENTITIES=<measured>
NEW_LEXER_FAILURE_IDENTITIES=<measured>
LEXER07_HISTORICAL_STATUS=<FAIL_KNOWN_BASELINE|measured>
LEXER07_FAILURE_IDENTITY_MD5=<measured>
CROSS_TARGET_PREFIX_STATUS=<FAIL_ENVIRONMENT_PREFIX|measured>
F_NO_PYTHON=<FAIL_KNOWN_BASELINE|measured>
F_POLYC_TOOLS=<UNAVAILABLE|measured>
GATE_FAST=<PASS|FAIL|NOT_REACHED>
GATE_PUSH=<PASS|FAIL|NOT_REACHED>
APPEND_ONLY=<PASS|FAIL|NOT_REACHED>
F14=<PASS|FAIL|NOT_REACHED>
FACTORY_V2_RANGE_CHECK=<PASS|FAIL|NOT_REACHED>
CLOSURE_STATUS=<PASS|FAIL|NOT_REACHED>
PATCH_HYGIENE=<PASS|FAIL|NOT_REACHED>
MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=<measured>
MANDATORY_AC_FAIL=<measured>
MANDATORY_AC_UNPROVEN=<measured>
PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0
NEXT_ACT=<ACT-POLYC-SELFHOST-PARSER-SLICE08|NONE>
NEXT_ACT_STATUS=<READY_TO_DRAFT|NOT_AUTHORIZED>
NEXT_TARGET=<computed candidate|NONE>
SLICE08_IMPLEMENTED=NO
POST_CLOSE_CONTINUATION=NO
```

On PASS, `MANDATORY_AC_PASS=50`, controls 20/20 and exactly one selected
candidate. On HALT, no invented PASS, no selected-authority transfer and no
future implementation authorization. **The Factory-v2 trailer verdict, not
HANDOFF prose, is terminal authority.**

---

## 18. Separate backlog: excluded from this ACT

The following must remain visible but must not be pulled into this
reconnaissance scope: SLICE06 stale CMake `--install-dir` producer wiring;
factory-halt-classification inline-assembly tool-build failure; unlanded
F-POLYC-TOOLS; twelve historical F-NO-PYTHON violations; fifteen historical
LEXER07 broad-corpus failure identities; 67 cross-target missing-prefix cases;
shared `/tmp/holyc-asm.s` assembly temp collision; ARM64 stage-0 portability;
Dafny proof stability, stage identity and optional external provers. If the
user wants any of these fixed, create a separate bounded ACT with its own
baseline and acceptance evidence.

---

**Final instruction to executor.** The important product of RECON07 is one
trustworthy successor contract or an honest HALT, not an impressive volume of
generated evidence. Do not forge coverage, backfill missing observations,
reclassify historical failures or import implementation changes from SLICE08
into RECON07.
