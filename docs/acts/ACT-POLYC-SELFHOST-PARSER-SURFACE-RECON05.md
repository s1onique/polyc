# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / STRUCTURAL-SURFACE-RECON / POST-SLICE06-SELECTION
**Priority:** P0
**Repository:** `s1onique/polyc`
**Branch:** `main`
**Expected ENTRY_HEAD:** `005790c53bb4e4798d58809940548552f0993d47`
**Expected ENTRY_TREE:** `5734052f648d486ca9cc822601079fbafdbdd5e1`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01` (`PASS_CORRECTED`)
**Other bound closures:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04`; `ACT-POLYC-SELFHOST-PARSER-SLICE06`
**Successor:** NONE PRESELECTED. A possible `SLICE07` is NOT authorized by this ACT's name.

---

## 0. Mission and terminal contract

After six parser decisions became production-authoritative compiled PolyC,
re-inventory the remaining production-authoritative legacy-C parsing/AST
decisions. Choose the next one bounded, production-reachable authority
transfer on evidence; alternatively HALT with a complete, falsifiable
exclusion dossier.

**This ACT is NOT an implementation ACT.** It must not introduce, modify
or enable a seventh production PolyC decision. It must not port
`parseStatement`, `parseExpr`, `parseCompoundStatementInternal`, AST
graphs, token-stream ownership, diagnostics or recovery semantics.

Required result fields on PASS (observed, not assumed):

```text
ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05
VERDICT=PASS
ENTRY_HEAD=005790c53bb4e4798d58809940548552f0993d47
CURRENT_POLYC_PARSER_AUTHORITIES=6
PARSER_SURFACE_CENSUS=COMPLETE
LEGACY_C_AUTHORITY_CENSUS=COMPLETE
CURRENT_SOURCE_HASHES_VERIFIED=YES
RECON04_CANDIDATES_RECONCILED=ALL
UNCLASSIFIED_FUNCTIONS=0
UNCLASSIFIED_SUBSLICES=0
UNCLASSIFIED_DEPENDENCIES=0
ELIGIBILITY_COMPUTED_FROM_LIVE_FACTS=YES
RANKING_RECOMPUTED_INDEPENDENTLY=YES
SELECTED_CANDIDATE_COUNT=1
SELECTED_PRODUCTION_REACHABLE=YES
SELECTED_BOUNDARY_BOUNDED=YES
SELECTED_LEGACY_C_ORACLE=OBJECT_LEVEL
SELECTED_CAUSAL_FEASIBILITY=EXECUTED
SELECTED_SUCCESSOR_CONTRACT=FROZEN
PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_LEXER_FAILURE_IDENTITIES=0
GATE_FAST=PASS
GATE_PUSH=PASS
APPEND_ONLY=PASS
F14=PASS
FACTORY_V2_RANGE_CHECK=PASS
MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=50
MANDATORY_AC_FAIL=0
MANDATORY_AC_UNPROVEN=0
```

`SELECTED_CANDIDATE_ID`, `SELECTED_SOURCE_SHA256`, `SELECTED_ABI`,
`SELECTED_LEGACY_ORACLE`, `SELECTED_FIXTURE`, `SELECTED_CAUSAL_WITNESS`,
`NEXT_ACT` and the actual counts are filled by the executor from measured
evidence. They are intentionally NOT invented here.

**No PASS if there is no single executable-feasible winner.** A HALT is an
honest terminal outcome, never a synthetic selected candidate.

---

## 1. Binding authority and historical baseline

Read, hash and bind these actual repository files, not text copied from a
digest:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04.md
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/**
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE06.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE06.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/**
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01/**
```

Important RECON04 inputs for historical comparison (NOT current truth):

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/function-inventory.tsv
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/structural-subslices.tsv
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/scalar-followups.tsv
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/eligibility-input-facts.tsv
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/eligibility-results.tsv
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/ranked-all-candidates.tsv
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/selection-result.tsv
```

Known reported historical starting point: 268 live functions from
`src/parser.c` (58), `src/prslib.c` (41), `src/prsutil.c` (27),
`src/ast.c` (142); 12 structural sub-slices (4 formerly eligible, 8
ineligible); 16 eligible candidates (4 structural, 12 scalar). `SUB-001`
was consumed by SLICE06; do not call its still-present legacy C
forwarding function a remaining production C authority. **The current
counts are to be MEASURED, not assumed equal to historical counts.**

Six production PolyC parser authority claims to verify in compiled
artifacts:

1. `BootstrapCalcPadding` — parser padding;
2. `BootstrapValidPostControlFlowToken` — control-flow-token decision;
3. `BootstrapOperatorPrecedence` — precedence decision;
4. `BootstrapAstBinOpFromToken` — binary operator classification;
5. `BootstrapAstUnaryOpFromToken` — unary operator classification;
6. `BootstrapSwitchArmTerminates` — switch/case-arm termination (SUB-001).

A surviving C wrapper does not mean the wrapped semantic authority
remains C-owned. Verify selector, object linkage, undefined symbol
references, active code path and absence of the obsolete C decision.
Preserve the corrected AC11 proof as immutable history; it need not be
re-prosecuted.

---

## 2. Candidate population — mandatory starting set

### A. Remaining historical structural boundaries

| ID | Historical source range (locator only) | Decision / bounded projection | Historical class |
|---|---|---|---|
| SUB-002 | `src/parser.c:1582..1583` | `parseDefaultStatement`: default-arm termination from one statement `AstKind` | STRUCTURAL_BOUNDARY |
| SUB-003 | `src/parser.c:1948` | `parseCompoundStatementInternal`: append/skip statement in a compound-block, projecting `stmt->kind` and `stmt->declvar->kind` as two bounded scalar values | STRUCTURAL_BOUNDARY |
| SUB-004 | `src/parser.c:1672..1685` | `parseStatement`: keyword-token to statement-constructor dispatch discriminator | STRUCTURAL_BOUNDARY |

These are neither current source freezes nor an authorization. Fresh range
hashes, reachable callers and AST/token enum values must be obtained. Do
not treat SUB-002 as selected on RECON04 rank alone. Test whether its
effect is independently observable after SUB-001 migration, and whether it
is truly a distinct decision rather than only duplicated code.

### B. Twelve formerly eligible scalar follow-ups

| ID | Function | File |
|---|---|---|
| CAND-018 | `parseCompoundAssign` | `src/prslib.c` |
| CAND-021 | `astBinOpToTokenPunct` | `src/prslib.c` |
| CAND-022 | `parseCountPrintfFormatSpecs` | `src/prslib.c` |
| CAND-023 | `parseFormatArgIdx` | `src/prslib.c` |
| CAND-025 | `astIsAssignment` | `src/ast.c` |
| CAND-026 | `astIsValidPointerOp` | `src/ast.c` |
| CAND-030 | `parseIsClassOrUnion` | `src/prsutil.c` |
| CAND-036 | `astIsBinCmp` | `src/ast.c` |
| CAND-037 | `astIsRangeOperator` | `src/ast.c` |
| CAND-038 | `astNormaliseFunctionName` | `src/ast.c` |
| CAND-039 | `createFunctionLevelGotoLabel` | `src/parser.c` |
| CAND-040 | `asmTextHasReturn` | `src/parser.c` |

Treat diagnostics-only candidates as diagnostics-only. Do not upgrade them
to structural significance because they are easy to migrate. For any
candidate whose input includes string or host storage (CAND-038 in
particular), verify ABI/storage and lifetime before claiming a bounded
projection.

### C. Previously excluded structural and whole-function surfaces

Re-examine all eight historically ineligible `SUB-005..SUB-012` plus the
PARSER01 blocked functions / recursive flow walks. Explicitly preserve
SUB-005 as ineligible unless new live evidence proves that
`cctrlIsKeyword` no longer consults the mutable `cc->symbol_table`, class
definitions, union definitions or other unbounded host state. SUB-006
recovery checkpoint / longjmp, SUB-007 compound loop, SUB-008 whole
statement parser, SUB-009 expression loop, SUB-010 and SUB-011 recursive
control-flow walks are NOT made eligible by wishful scalarization. Include
SUB-012 and any new live sub-slices in the full classification. **A
whole-function rejection must not suppress independently bounded
sub-decisions inside it.**

### D. Newly discovered candidates

Preserve all historical IDs, allocate from the actual current candidate
registry without collisions (never recycle retired IDs), record source
ranges, reasons for discovery and disjoint decision boundaries. A
source-census difference alone does not authorize an added candidate.

---

## 3. Hard scope and implementation constraints

Tracked changes permitted only in this ACT's new artifacts and bounded
integration points:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/**
tools/quality/parser-surface-recon05-*.HC
Makefile   # only if truly necessary for the ACT's executable checks
```

Prohibited tracked modifications: `src/**`, `tools/bootstrap/**`,
compiler production selectors, existing tools/checkers/rankers, historical
ACTs/HANDOFFs/evidence trees, original fixtures, original candidate
IDs/ranking, `.factory/` gate semantics, and unrelated tests. Existing
`.factory/epic-board.md` may be updated only if required by an
established repository Factory rule, with its change independently audited
and without asserting a new implementation close. Use the managed
roadmap/handoff map as normal.

Source mutation for feasibility is allowed only in **disposable detached
worktrees**, never on the tracked main worktree; restore and verify bytes
before removing the worktree. Never merge or commit those mutations. No
new Python, no new dependencies, no broad Bash orchestration, no unbounded
shell drivers, no force push/rebase/amend/reset. Any necessary new
substantive verifier is **source-authored in PolyC**, compiled by a real
PolyC compiler and shown to run. Shell, if unavoidable, is bounded command
glue (≤50 lines per new shell file) and not the source of
eligibility/ranking authority. **Do not bypass the still-unavailable
F-POLYC-TOOLS checker by reporting it PASS.**

Never rewrite a predecessor to fix missing evidence; create new RECON05
evidence, or HALT.

---

## 4. Canonical decision model

Source of truth: **freshly scanned source bytes and compiled production
objects**, not the inherited inventory TSV or prose.

Every C function row contains exact path, line start/end, name, semantic
authority, source-range SHA-256, production reachability, class, and
separate evidence location. Verify unique IDs, no overlaps that corrupt
identity, exactly one classification per live function, zero
missing/unknown/unbound rows and zero invalid ranges. Reconcile BOTH
directions with RECON04 (added, removed, renamed, range-shifted,
body-changed, authority-changed); explain each set difference
individually.

**Eligibility:** invoke the unmodified canonical PolyC eligibility
checker `tools/quality/parser-slice-recon03-eligibility.HC` on newly
computed facts, if its schema remains applicable. The established 13
gates are: (1) semantic authority, (2) not already self-hosted, (3)
bounded R0, (4) no setjmp ownership, (5) no writes to current recovery,
(6) no nonlocal recovery, (7) zero host-graph writes, (8) zero
pointer-identity operations, (9) zero parser callbacks, (10) zero semantic
callbacks, (11) deterministic projection, (12) feasible production
delegation, (13) runtime semantic authority; in addition production
reachability must be YES. **The facts file must not carry a hand-authored
`eligible` field.**

For a sub-slice, measure the exact sub-decision rather than the entire
enclosing function, while retaining the enclosing function's host graph,
callback, recovery and mutable state on the C side.

**Ranking:** invoke the unmodified canonical PolyC ranker
`tools/quality/parser-slice-recon03-ranking.HC` using a current,
source-bound R0–R6 input. Preserve the original ranker's ordering and tie
breaks (including source identity). Never promote ineligible,
already-migrated, or unreachable candidates.

Selection policy: choose the first independently verified eligible,
production-reachable, causal-feasible structural boundary under the
canonical ranking; if none, consider eligible scalar follow-ups under the
same ordering but distinguish their actual effects. If a ranked candidate
is disqualified by executable feasibility, append the concrete failed
proof and re-run the documented deterministic selection on the remaining
eligible set. No manual preference, hand-edited eligible column,
cherry-picked fixture, or invented rank dimension. If canonical checkers
cannot express new live semantics safely, `HALT_CHECKER_SCHEMA_UNFIT`
rather than patching the closed ranker or bypassing it.

**Independent C3:** use a second PolyC implementation which reads the raw
C1 facts and current source bindings and does NOT read the C2 eligible
decision or selected-winner/rank columns as its oracle. It must recompute
every eligibility clause, class partition, total candidate population,
complete ordered rank list and selected winner. Check C2 versus C3 by
stable candidate IDs and complete row sets, not row order by accident,
hash equality alone or winner-only agreement.

---

## 5. Executable negative-control plan (19 IDs)

Freeze exact inputs, expected failure class, command, observed return code,
output and restored pristine outcome in C0; add controls only through an
explicit new correction ACT if this frozen set later proves insufficient.
All controls must run and fail for their intended reason, not receive a
vacuous `SENSITIVE=YES` from a pristine pass.

| ID | Adverse action | Required detector (not generic nonzero) |
|---|---|---|
| IC-01 | Delete one live census function row | `MISSING_FUNCTION` identifies its ID |
| IC-02 | Duplicate a function or candidate ID | `DUPLICATE_ID` |
| IC-03 | Change a frozen source-range hash | `SOURCE_HASH_MISMATCH` at the actual range |
| IC-04 | Provide reversed/out-of-file or overlapping identity range | `INVALID_RANGE` / explicit identity conflict |
| EC-01 | Re-mark migrated SUB-001 as eligible legacy authority | `ALREADY_SELFHOSTED` clause rejects it |
| EC-02 | Mark a candidate as owning setjmp | `OWNS_SETJMP` gate rejects it |
| EC-03 | Add nonzero host-graph writes | `HOST_GRAPH_WRITES` gate rejects it |
| EC-04 | Add a parser or semantic callback dependency | Appropriate callback gate rejects it |
| EC-05 | Suppress SUB-005's mutable symbol-table dependence | Live source-dependency verifier rejects false bounded projection |
| EC-06 | Add unknown/malformed candidate or a missing eligibility fact | `UNKNOWN_ID` / `MALFORMED_FACT`, no reinterpretation |
| RC-01 | Shuffle C1 facts and substitute an intentionally order-dependent reported ranking | Independent complete-order comparator detects `RANK_ORDER_MISMATCH`; authentic ranker remains invariant |
| RC-02 | Give an ineligible candidate an artificially perfect rank | Ranker excludes it, not merely deprioritizes it |
| RC-03 | Remove computed winner from the eligible candidate set | New deterministic result or explicit `NONE`; old winner must not survive |
| RC-04 | Perturb a ranking dimension or tie breaker with known effect | Canonical ranker reports the expected controlled order change |
| RC-05 | Substitute stale source range/call site while keeping candidate ID | Source binding and production-reachability verifier rejects it |
| CC-01 | Mutate selected C decision in a disposable real-source worktree and rebuild | Real compiled-program diagnostic/AST/output changes in intended direction |
| CC-02 | Make the C oracle depend on the new PolyC target or substitute a hand-written oracle | Object provenance / independence verifier rejects it |
| CC-03 | Flip exactly one fixture expected semantic outcome | Differential reports the exact affected semantic input ID and reason |
| CC-04 | Supply disassembly with unrelated `cmp`/`tst` outside selected function | Function-scoped code/identity detector rejects a fabricated in-function authority claim |

For RC-01, the authentic unmodified ranker must produce the same complete
order on shuffled facts (positive metamorphic check); the adverse control
is the deliberately order-dependent reported result substituted into the
independent comparator, which must reject it with `RANK_ORDER_MISMATCH`.
Record BOTH executions. **Do not mutate or replace the canonical ranker.**

All controls require independent bookkeeping of `CONTROL_ID`, `SUBJECT`,
`MUTATION`, `PRISTINE_STATUS`, `MUTANT_STATUS`, `EXPECTED_DETECTOR`,
`ACTUAL_DETECTOR`, `RESTORED_STATUS`, `EXIT_CODE`, `SOURCE_OBJECT_ID`,
`STATUS`; zero omitted, invented or repurposed IDs.

---

## 6. C0 — Entry lock / baseline / RED

Before tracked mutation:

1. Verify `main`, expected full HEAD and tree, clean tracked/untracked
   state, zero Git replace refs, predecessor CLOSE trailers and the exact
   four-commit correction range. If local state differs, HALT; do not
   auto-reset.
2. Freeze hashes of all RECON04, SLICE06 and correction ACT/HANDOFF/evidence
   paths (including the correction's PolyC quality tools). Record the number
   of files and independent rehash proof. No retrospective modification.
3. Measure baseline: `make gate-fast`, `make gate-push`, parser 376/376 over
   90 files with original assertion-sequence MD5
   `b6f117eb1386ca80f81bc06226e2a741` if still applicable, lexer
   differentials, LEXER07 corpus failure identities, cross-target
   test-prefix-install, F-NO-PYTHON, F-POLYC-TOOLS, F14 and patch hygiene.
   Run in an isolated clean environment or detached worktree if possible.
   Record exact command, exit, stdout/stderr, time-bound and compiler
   provenance. **No invented all-green claim.**
4. Bind the actual source/object evidence for the existing six PolyC
   authorities; record selectors and undefined references, compiler
   architectures and G0/G1/G2/G3 availability. Distinguish current
   authority from legacy C adapters.
5. Freeze a 50-ID acceptance contract from §10 and the 19-ID control
   contract from §5, each with canonical ID joins. C0 MAY freeze them
   before C1 measurements; **never backfill observed outcomes into a C0
   contract as if pre-existing.**
6. Reproduce deliberate REDs: unbound missing source-range digest, missing
   current-function census, missing original candidate disposition, missing
   independent eligibility and ranking, missing selected-C-object oracle,
   missing semantic causal mutation. Each must fail for its own reason
   against real entry state rather than an artificial stub.
7. Commit C0 (ACT, entry, baseline, frozen contracts, RED reproduction),
   with Factory-valid phase trailers. **No migration source code.**

---

## 7. C1 — Live source census and dependency graph

1. Compile/run a PolyC source inventory verifier against live
   `src/parser.c`, `src/prslib.c`, `src/prsutil.c`, `src/ast.c`; derive
   each function boundary and SHA-256 from bytes. Independently re-scan to
   validate no lost or synthetic entries. A changed count from 268 is
   acceptable only with exact measured set differences.
2. Reconcile RECON04's 12 structural sub-slices by ID and source interval,
   and re-discover all actual bounded sub-decisions within the required
   structural regions, including compound, case/default, dispatch,
   expression, AST construction, and control-flow handling.
   `UNCLASSIFIED_SUBSLICES=0`.
3. For every candidate and enclosing function, generate directed production
   call graph, callback and semantic callback edges, allocation and
   aliasing ownership, AST graph writes, token-stream read/write ownership,
   diagnostic side effects, `jmp_buf`/recovery checkpoint ownership,
   scope/symbol-table dependencies, and target-architecture risks. Link
   facts to verified source locations, not generic descriptions.
4. Preserve the bounded/non-bounded separation: the host C parser owns AST
   allocations, graph mutation, token stream, symbol tables, callbacks,
   recovery, diagnostics and list structures unless separately proved
   otherwise. SUB-003 has TWO `AstKind` projections; do not accidentally
   record only `stmt->kind`. SUB-004 is token dispatch, not a broad
   `parseStatement` port. SUB-005 remains ineligible without new proof that
   mutable symbol state has been eliminated from the decision.
5. Produce ONE current classification for every live function, every
   sub-slice and each historical candidate. Bind retired IDs rather than
   deleting them; no historical CAND or SUB ID reuse. Report unclassified
   and mutually inconsistent facts explicitly.
6. Commit C1 with current census, hashes, classification, graph and
   reconciliation evidence. **No ranking or winner claim before the C1
   population is frozen.**

---

## 8. C2 — Eligibility, ranking, successor-contract freeze

1. Build the canonical C1 facts file (**no `eligible` column**); compile and
   invoke the unmodified 13-clause checker. Verify its executable
   path/hash and exact input identities. Record all clause bits for
   eligible and ineligible candidates and independent evidence for each
   rejection.
2. Build current ranking dimensions R0–R6 only for checker-qualified
   eligible candidates. Invoke the unmodified ranker and record the entire
   ranked population, structural/scalar class subsets, tie breaks, reasons,
   exact source identities, and selection. **Do not simply reuse
   RECON04's `NC-07_new_winner=SUB-002` counterfactual**; it only proves
   what happened to the old 16-candidate set when SUB-001 was removed.
3. Run the 19 frozen controls, including BOTH sides of RC-01 (or halt if
   the exact applicable control semantics cannot be maintained); preserve
   raw observations, including both expected rejection and correct positive
   outcomes. Any renamed detector or invented success is UNPROVEN.
4. For each still-leading candidate in ranking order, confirm feasibility
   before selecting: current real production call site, bounded copy-only
   inputs and scalar outputs, stable ABI, no state ownership migration, no
   hidden callbacks, no silent exceptional/recovery side effects, and
   distinct production behavior. If the top candidate cannot meet the
   executable causal criterion, record the specific failed gate, remove it
   from the feasible subset by machine-verifiable reason, and recalculate;
   **never pick manually.**
5. Freeze ONE selected candidate only after source-bound oracle and
   executable feasibility evidence exist. For a single winner, create
   correction-owned/fresh successor-contract files:

```text
c2/selected-id-and-source.tsv
c2/selected-abi.md
c2/selected-production-seam.md
c2/selected-state-and-ownership.tsv
c2/selected-legacy-oracle.md
c2/selected-fixture-contract.tsv
c2/selected-red-contract.md
c2/selected-causal-contract.md
c2/selected-negative-controls.md
c2/selected-provenance-contract.md
c2/selected-conservation-contract.md
c2/selected-out-of-scope.md
c2/successor-authorization.md
```

6. Derive a complete fixture from live token/AST definitions and decision
   inputs. Independently verify partition coverage, invalid values,
   aliasing/normalization, duplicate IDs, missing IDs and exact semantic
   distinctions. **A source-extracted standalone C condition alone is NOT
   an acceptable G0 oracle: compile the actual production C translation unit
   with the proposed delegation disabled, and prove that object does not
   reference the proposed PolyC symbol.** Compare any extracted helper
   against that object-level oracle.
7. In a detached disposable worktree build the real compiler from the same
   tree, compile a witness, mutate ONLY the prospective C decision (the
   PolyC successor does not yet exist), successfully rebuild and run the
   same witness, then restore byte-identical source and compiler output.
   Prove an actual structural compiled-output change for a structural
   candidate, or identify a precise externally observable
   diagnostic/type/IR behavior for an eligible scalar candidate. A mutation
   detected by a source parser only, an oracle-only change, or a failed
   build CANNOT discharge this gate. Record pristine/mutant/restored exact
   bytes and expected directional change.
8. Freeze the exact predecessor and successor evidence by hash. Commit C2
   only after successful selection and contract freeze. Otherwise HALT with
   measured exclusions, not a partial PASS.

---

## 9. C3 — Independent witness / conservation / Factory qualification

1. Re-run the complete census on the current same source tree; compare
   source-range hashes and original historical source-identity set
   differences. Verify 268 only if it is measured; count differences must
   be enumerated.
2. Independently derive 13-clause eligibility from raw source-bound C1
   facts WITHOUT reading C2 eligible status, then calculate the entire
   R0–R6 ordered output without using C2 rankings or selected ID as input.
   Compare by exact IDs: zero missing, extra, duplicate, inconsistent or
   unranked eligible entries. Verify structural preference follows
   canonical policy, with complete disqualified-candidate reasons.
3. Check all 19 control IDs for executed subject-specific mutations,
   intended detector, correct exit and restoration; reject summary-only
   PASS, harmless input changes and vacuous no-mutation controls. Verify
   CC-04 scopes machine-code claims to the selected function and producer
   object, not `cmp`/`tst` anywhere in a file. Treat PD-04 correction
   history as immutable; this is a new recon quality constraint, not a
   retroactive verdict change.
4. Independently replay the selected G0 oracle, fixture and C-source causal
   proof. The object and compiled witness must bind to the actual source,
   compiler binaries, flags, architecture, linker and executable outputs.
   Confirm proposed G1/G2/G3 producers are available and distinct, but
   **do not claim a four-generation PolyC candidate semantic differential
   was executed**: that is the future successor's job.
5. Independently verify every selected contract field is populated and
   internally consistent. Successor contract is single-valued and may NOT
   authorize one of the other candidates by implication. **No seventh PolyC
   authority may be introduced by RECON05.**
6. Run host parser test suite, lexer differentials, LEXER07 identity and
   cross-target condition against both entry and proposed CLOSE source
   trees, with same commands, architecture, prefix and environmental
   equivalence. Record status separately: historical LEXER07 nonzero 15 IDs
   with MD5 `7ee761440de83552e751e3c3976c1683` is NOT a PASS; historical 67
   cross-target prefix misses are NOT silently waived; F-NO-PYTHON 12
   pre-existing violations and F-POLYC-TOOLS checker UNAVAILABLE are
   reported exactly, and any NEW violation is a HALT.
7. Actually execute `make gate-fast`, `make gate-push`, Factory-v2 checks,
   append-only, F14, patch hygiene and closure-status (as appropriate to
   the stage), retaining raw command, exit and result, not just a summary.
   Makefile changes, if any, MUST NOT weaken gates or create false-green
   checks. Freeze previous ACT evidence hashes and prove no modifications.
8. Independently join all 50 §10 AC predicates by exact ID to named
   artifacts and observed outcomes. C3 should show 49 PASS, 1
   `DEFERRED_TO_CLOSE` (AC50), 0 FAIL and 0 UNPROVEN only if all pre-close
   gates truly pass; do not prematurely count AC50 as completed.
9. Commit C3 as the final evidence commit. If any required predicate
   fails, stop and record a truthful terminal HALT rather than proceeding
   to C4 PASS.

---

## 10. Mandatory acceptance predicates (exactly 50)

| ID | Mandatory predicate |
|---|---|
| AC01 | Exact entry branch, full HEAD and tree, clean state and zero replace refs verified. |
| AC02 | Correction01 predecessor CLOSE identity, reachability and trailers verified. |
| AC03 | All RECON04, SLICE06 and Correction01 closed artifacts frozen and unchanged. |
| AC04 | Entry baseline gates, parser, lexer, LEXER07, cross-target and tool policy measured honestly. |
| AC05 | Tracked mutation scope restricted to RECON05-owned artifacts and allowed integration. |
| AC06 | No new Python, dependency, bootstrapping, production or hidden shell-policy violation. |
| AC07 | Source-byte-derived live function census from all four canonical C files. |
| AC08 | Every current function source range has an independently checked SHA-256 and valid range. |
| AC09 | Exactly one classification per live function; zero unknown/unclassified/duplicate functions. |
| AC10 | RECON04-to-current function and authority differences reconciled in both directions. |
| AC11 | All six compiled PolyC production authorities verified, distinct and still active. |
| AC12 | Production C adapters are distinguished from active legacy semantic authority. |
| AC13 | No already-migrated authority (especially SUB-001) enters eligible legacy set. |
| AC14 | Production call graph and AST/callback/recovery ownership evidence source-bound. |
| AC15 | Every RECON04 structural region is freshly enumerated with no silent omissions. |
| AC16 | All 12 prior sub-slices reconciled, including previously ineligible decisions. |
| AC17 | SUB-002/003/004 each re-bound to live decision, caller, range and hash. |
| AC18 | All 12 scalar follow-ups reconciled with real current production reachability. |
| AC19 | PARSER01 whole-function, recursive-walk and stateful blockers explicitly dispositioned. |
| AC20 | SUB-005 mutable symbol-table dependence remains excluded unless disproved by live evidence. |
| AC21 | Every new candidate assigned unique registry-backed ID, with no historical ID reuse. |
| AC22 | Structural significance (AST shape, statement sequence, routing, recovery, etc.) source-proven. |
| AC23 | Every eligible candidate genuinely production-reachable. |
| AC24 | No selected boundary transfers AST/host graph allocation, recovery, callbacks or pointer identity. |
| AC25 | Each proposed input projection is bounded, deterministic, copy-only and unaliased. |
| AC26 | Selected output/ABI is bounded and its success/error/sentinel contract exact. |
| AC27 | All candidate source identities independently verified from live bytes. |
| AC28 | Unmodified 13-clause canonical eligibility checker runs on source-derived facts. |
| AC29 | Checker outcome joins by ID; no hand-authored eligible flag or silent excluded rows. |
| AC30 | Unmodified canonical R0–R6 ranker runs on exact checker-qualified population. |
| AC31 | C3 independent verifier recomputes every eligibility clause without C2 eligible output. |
| AC32 | C3 independent verifier reproduces the entire ranking without C2 ranked output. |
| AC33 | Structural/scalar priority and tie-break rules follow the canonical policy. |
| AC34 | All 19 new controls have nonvacuous, intended-reason evidence or HALT. |
| AC35 | Exactly one candidate selected, or no PASS; no accidental selection of SUB-002. |
| AC36 | Selected candidate ID, live source hash, range and production call-site frozen. |
| AC37 | Exact ABI, complete state projection, C-retained ownership and seam frozen. |
| AC38 | Real production C translation-unit object-level G0 oracle independently verified. |
| AC39 | Selected fixture/domain and partitions derived from live source, not historical counts. |
| AC40 | Fixture coverage and expected semantics independently verified against real C oracle. |
| AC41 | Real compiler is successfully rebuilt with selected C mutation in isolated worktree. |
| AC42 | Real compiled witness changes in correct direction and restores byte-identically. |
| AC43 | G0/G1/G2/G3 future compiler/producer feasibility and distinct stage provenance documented honestly. |
| AC44 | Successor RED, causal, oracle, source, fixture and scope contracts frozen. |
| AC45 | Successor negative controls, conservation, out-of-scope and single authorization frozen. |
| AC46 | Parser host tests (historically 376/376) and assertion sequence conserved; zero new failures. |
| AC47 | Lexer differential, LEXER07 failure identity, prefix failures and tool policies reported honestly. |
| AC48 | gate-fast/gate-push and all applicable pre-CLOSE Factory-v2, append-only, F14, closure status and patch-hygiene checks PASS; post-CLOSE range verification is AC50. |
| AC49 | All 50 mandatory ACs are ID-joined, with 49 pre-CLOSE PASS and AC50 deferred only. |
| AC50 | Exactly one terminal C4 CLOSE, valid trailers, correct range, immutable history and read-only post-CLOSE verification. |

**No aggregate PASS without complete per-ID evidence.** A
`DEFERRED_TO_CLOSE` applies only to AC50, and external terminality must
discharge it after the CLOSE. No predecessor's 50 ACs are copied as
RECON05's own observations.

---

## 11. C4 — Closure and single-valued handoff

If and only if C3 has demonstrated AC01..AC49 and there is exactly one
eligible, independently proven selected candidate:

1. Write `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05.md`,
   including selection ID, source hash, input/output projection, frozen
   successor-contract paths, exact observed gates, known failures and
   rejected runners-up.
2. Append precisely ONE mapping to `docs/factory/act-handoff-map.tsv`.
   Update `docs/ROADMAP.md` with RECON05 closure and conditional proposed
   next implementation ACT; **do not create that next ACT nor say it has
   executed.**
3. Create exactly ONE C4 terminal CLOSE commit with repository-valid
   Factory trailers, including:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

4. Perform read-only external post-CLOSE validation: exact commit range and
   count, commit phases, trailer parsing, old artifact SHA-256 set,
   worktree cleanliness, zero replace refs, Factory-v2 range check,
   append-only, F14, F-POLYC-TOOLS availability truth, patch hygiene, zero
   post-close commits, exact C4 AC50 disposition. Retain the terminal
   receipt externally if the repository prohibits post-CLOSE tracked
   modifications.
5. A single next implementation ACT name (provisionally
   `ACT-POLYC-SELFHOST-PARSER-SLICE07`) may be recorded in the **pre-CLOSE
   HANDOFF** only after C3 has proven AC01..AC49 and exactly one complete
   frozen selected-candidate contract exists. Label this successor
   authorization CONDITIONAL upon subsequent external C4/AC50 terminality
   PASS. If that external check fails, the proposed successor remains
   INACTIVE and is NOT authorized to execute. This HANDOFF does not
   implement the successor.

If there is no viable winner or any invariant fails, produce a HALT
dossier with the exact stage and blockers. Use only repository-approved
HALT evidence/trailers, and **never emit `ACT-Verdict: PASS` or an
invented successor.** Do not close with PASS just because the census and
ranking ran.

---

## 12. Required evidence tree

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/
  c0/
    entry-identity.txt
    predecessor-trailers.txt
    predecessor-freeze.tsv
    baseline-parser.txt
    baseline-lexer.txt
    baseline-lexer07.txt
    baseline-cross-target.txt
    baseline-gates.txt
    baseline-tool-policy.txt
    current-production-authorities.tsv
    mandatory-ac-contract.tsv
    frozen-negative-controls.tsv
    red-reproduction.txt
  c1/
    live-function-inventory.tsv
    inventory-range-hashes.tsv
    recon04-function-difference.tsv
    recon04-authority-difference.tsv
    structural-regions.tsv
    structural-subslices.tsv
    candidate-registry-reconciliation.tsv
    scalar-followups.tsv
    production-call-graph.tsv
    callback-ownership.tsv
    recovery-ownership.tsv
    ast-graph-and-allocation.tsv
    state-read-write.tsv
    eligibility-input-facts.tsv
    source-identity-verification.txt
  c2/
    eligibility-results.tsv
    eligibility-rejections.tsv
    ranking-dimensions.tsv
    ranked-all-candidates.tsv
    ranked-structural-candidates.tsv
    ranked-scalar-candidates.tsv
    eligibility-and-ranking-controls.txt
    selected-id-and-source.tsv
    selected-abi.md
    selected-production-seam.md
    selected-state-and-ownership.tsv
    selected-legacy-oracle.md
    selected-fixture-contract.tsv
    selected-red-contract.md
    selected-causal-contract.md
    selected-negative-controls.md
    selected-provenance-contract.md
    selected-conservation-contract.md
    selected-out-of-scope.md
    successor-authorization.md
  c3/
    inventory-recompute.txt
    dependency-graph-verify.txt
    eligibility-recompute.tsv
    ranking-recompute.tsv
    full-ranking-join.tsv
    negative-control-join.tsv
    selected-oracle-verification.txt
    fixture-independent-verification.txt
    causal-mutation-and-restoration.txt
    generation-feasibility.txt
    parser-conservation.txt
    lexer-conservation.txt
    lexer07-delta.txt
    cross-target-delta.txt
    tool-policy.txt
    gate-fast.txt
    gate-push.txt
    factory-invariants.txt
    immutable-predecessor-check.txt
    patch-hygiene.txt
    mandatory-ac-status.tsv
  c4/
    terminality.txt   # only if legal before CLOSE; external receipt otherwise
```

Data filenames above are intended contracts; if the canonical Factory
requires a different naming pattern, record an exact name map before
using it and keep all required meanings independently auditable. Raw
outputs need not be duplicated inside enormous prose logs when their
immutable hashes, command, exit code and subject identifiers provide
direct evidence. **Never cite an absent log as a PASS.**

---

## 13. Halt taxonomy

```text
HALT_ENTRY_IDENTITY
HALT_UNCLEAN_WORKTREE
HALT_PREDECESSOR_NOT_CLOSED
HALT_HISTORICAL_ARTIFACT_MODIFIED
HALT_UNBOUND_SOURCE_IDENTITY
HALT_INCOMPLETE_CENSUS
HALT_UNCLASSIFIED_DEPENDENCY
HALT_MUTABLE_HOST_STATE_LEAK
HALT_CALLBACK_OR_RECOVERY_COUPLING
HALT_CHECKER_SCHEMA_UNFIT
HALT_ELIGIBILITY_UNPROVEN
HALT_RANKING_MISMATCH
HALT_NEGATIVE_CONTROL_INSENSITIVE
HALT_NO_BOUNDED_CANDIDATE
HALT_SELECTED_ORACLE_NOT_INDEPENDENT
HALT_SELECTED_CAUSAL_WITNESS
HALT_PRODUCTION_SOURCE_DELTA
HALT_NEW_PARSER_OR_LEXER_FAILURE
HALT_GATE_FAST
HALT_GATE_PUSH
HALT_FACTORY_INVARIANT
HALT_MANDATORY_AC
HALT_TERMINALITY
```

A HALT must preserve all completed measurements and must NOT alter
historical ACT evidence. Do not initiate a remedial migration, alternate
ranker rewrite, or schema redefinition inside this ACT. An unresolved HALT
requires a separate explicitly authorized correction or redesigned
reconnaissance.

---

## 14. Terminal report schema

```text
ACT_ID=
VERDICT=PASS|HALT
HALT_REASON=NONE|<exact code>
ENTRY_HEAD=
ENTRY_TREE=
FINAL_HEAD=
FINAL_TREE=
ACT_COMMIT_COUNT=
WORKTREE_CLEAN=
GIT_REPLACE_REFS=
PREDECESSOR_CLOSE_VERIFIED=
CLOSED_ARTIFACT_HASHES_MATCH=
CENSUS_FUNCTIONS_TOTAL=
RECON04_FUNCTIONS_ADDED=
RECON04_FUNCTIONS_REMOVED=
RECON04_FUNCTIONS_CHANGED=
CLASSIFIED_FUNCTIONS=
UNCLASSIFIED_FUNCTIONS=
STRUCTURAL_SUBSLICES_TOTAL=
ELIGIBLE_STRUCTURAL=
ELIGIBLE_SCALAR=
INELIGIBLE_STRUCTURAL=
RECON04_CANDIDATES_RECONCILED=
EXISTING_POLYC_PARSER_AUTHORITIES=6
SELECTED_CANDIDATE_ID=
SELECTED_CLASS=
SELECTED_SOURCE_PATH=
SELECTED_SOURCE_RANGE=
SELECTED_SOURCE_SHA256=
SELECTED_ABI=
SELECTED_PRODUCTION_SEAM=
G0_REAL_PRODUCTION_C_OBJECT=
G0_ORACLE_POLYC_REFERENCE=ABSENT
G1_G2_G3_COMPILER_PROVENANCE=
CAUSAL_PRISTINE_OUTPUT_SHA256=
CAUSAL_MUTANT_OUTPUT_SHA256=
CAUSAL_RESTORED_OUTPUT_SHA256=
CAUSAL_MUTANT_BUILD=
CAUSAL_RESTORATION_BYTE_IDENTICAL=
INDEPENDENT_ELIGIBILITY_JOIN=
INDEPENDENT_FULL_RANKING_JOIN=
NEGATIVE_CONTROLS_TOTAL=19
NEGATIVE_CONTROLS_INTENDED_PASS=
NEGATIVE_CONTROLS_UNPROVEN=
PRODUCTION_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0
PARSER_ASSERTIONS=
PARSER_ASSERTION_SEQUENCE_MD5=
NEW_PARSER_FAILURE_IDENTITIES=
NEW_LEXER_FAILURE_IDENTITIES=
LEXER07_HISTORICAL_STATUS=
LEXER07_FAILURE_IDENTITY_MD5=
CROSS_TARGET_PREFIX_STATUS=
F_NO_PYTHON=
F_POLYC_TOOLS=
GATE_FAST=
GATE_PUSH=
APPEND_ONLY=
F14=
FACTORY_V2_RANGE_CHECK=
PATCH_HYGIENE=
MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=
MANDATORY_AC_FAIL=
MANDATORY_AC_UNPROVEN=
NEXT_ACT=
NEXT_TARGET=
POST_CLOSE_CONTINUATION=NO
```

Interpretation: A proper RECON05 PASS demonstrates an exhaustive,
falsifiable selection and feasibility contract, NOT a seventh self-hosted
parser authority. The next implementation ACT inherits precisely one
frozen candidate. If no candidate can meet the real production-oracle and
executable-causality requirements, the correct result is HALT, with all
historical and current candidate facts preserved.
