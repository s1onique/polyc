# ACT-POLYC-SELFHOST-DRIVER-MIGRATION01

Factory-Version: 2
Lifecycle: AUTHORIZATION ARTIFACT — this document is not an execution report
Class: SELFHOST / M2_PRECURSOR / DRIVER / PRODUCTION_AUTHORITY / WP-001
Priority: P0 — first production compiler-root migration along the frozen M2 work-package DAG
Prepared: 2026-11-02
Repository: canonical local PolyC checkout, existing main branch; no per-ACT branch
Expected ENTRY_HEAD: 2288a80330b9907341cd8a7d62d33cbfe9da5452
Expected ENTRY_TREE: DERIVE FROM THAT EXACT GIT COMMIT AT C0
Predecessor: ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01, reported PASS, terminal CLOSE at the pinned HEAD
Selected work package: WP-001 — PolyC-authored compiler driver
Source scope reported by predecessor: src/main.c + src/cli.c, approximately 1,257 LOC / 32 historical authority rows (verify, do not assume)
Production PolyC authorities at entry: 15 (source/object/link verification required)
Publication: NO_PUSH / NO_FETCH / NO_REBASE / NO_AMEND / NO_FORCE_PUSH

## 0. Mission and binding outcome

Implement the first production-linked PolyC-authored compiler driver as the
source-bounded successor selected by WP-001. The actual executable's
entry/CLI route must be driven by compiled PolyC code: interpret the
supported compile invocation, select the compiler action, construct and
validate its request, invoke the existing compiler engine through a
contract-checked host bridge, propagate status, and establish the
executable's exit behavior. Keep a real selector-OFF C-only driver oracle.
Retain unrelated parser/AST/type/IR/codegen functionality and the existing
15 PolyC delegates unchanged.

The minimum selected executable witness, quoted from REBASE01, is:

```text
hcc --install-dir=X -c input.HC -o out.o
```

`X`, `input.HC`, and `out.o` must be populated from live valid
test-prefix/source fixtures; they are placeholders, not hard-coded literal
paths. A passing `-c` invocation must actually produce a valid target
object; successful command parsing alone is insufficient. The output must
be inspected through the actual object toolchain and, where the baseline
supports it, linked/executed by a separately qualified runner.

### 0.1 Distinguish four results

1. **WP-001 completed.** A production compiler driver genuinely authored
   in PolyC owns every decision on the frozen required driver/compile
   route and has a source-bound remaining-driver authority ledger. The C
   entry becomes a strictly mechanical trampoline/platform bridge. G0 and
   the migrated production compiler agree on the frozen observable corpus.
2. **P0 precursor partial.** This ACT can establish the WP-001 driver
   portion of the compiler-producing vertical slice. The other nine
   reported precursor semantic units are not migrated here. `P0_COMPLETE`
   is not claimed unless the repository's separately frozen entire P0
   closure has actually been demonstrated.
3. **M1/M2/M3.** All remain NOT ACHIEVED without their own semantic
   ownership, producer provenance and bootstrap-generation acceptance
   predicates. A C-rooted compiler linking a PolyC driver is still hybrid.
4. **No fake authority accounting.** The historical 32 authority rows are
   a review roster, not 32 automatically migrated decisions.
   `NEW_POLYC_AUTHORITIES` equals independently attributable
   production-owned semantic decisions actually proven;
   `REMAINING_C_DRIVER_AUTHORITIES` must be counted separately.

### 0.2 Strict PASS predicate

`PASS_DRIVER_POLYC_OWNED_BOOTSTRAP_WP001` requires all of the following:

- Exact entry/history and untouched frozen predecessor artifacts; binding
  WP-001 contract and source IDs reread from the real repository.
- A complete, documented driver/CLI authority table for `src/main.c` +
  `src/cli.c`, with 32 historical rows individually reconciled (no coerced
  32/32 PASS).
- Source-defined argument, action-selection, request formation and
  exit-status decisions for the required compiler-producing invocation
  executed in production PolyC, not merely linked or copied into a
  dormant subject.
- Retained C code contains only the explicitly enumerated platform and
  mechanical bridge duties for those migrated decisions; no hidden C
  parsing/fallback, C switch table, second CLI policy or
  delegation-disabled production default.
- C-only driver G0 completely excludes the new PolyC driver subject/bridge
  symbols; G1–G3 producers are qualified as distinct where claimed;
  equivalence and causal isolation actually executed.
- Exactly the observed transferred authorities are added to the 15 entry
  authorities. A zero-transfer result cannot PASS this ACT.
- Real output object/witness, negative controls, conservation gates and
  post-CLOSE external terminality PASS, with non-green baselines honestly
  classified.

No PASS may claim that 1,257 LOC or 32 rows have migrated merely because a
driver symbol exists.

### 0.3 Mandatory predecessor source contract: fail closed

The uploaded targeted digest names but does not print the full
`evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/selected-successor-contract.md`.
This authorization does not invent its ABI, permitted-glue list, line
ranges, or hidden frozen acceptance details. At C0 the executor MUST read
that exact committed file, its blob OID/digest, along with the predecessor's
`c1/source-closure.tsv`, `c1/m2-target-semantics.tsv`,
`c1/bootstrap-blockers.tsv`, `c1/generation-producer-dag.tsv`,
`c2/work-packages.tsv`, `c2/work-package-dependencies.tsv`,
`c2/selected-successor-contract.md` and the predecessor HANDOFF. Verify
WP-001, the driver source range, reported 32 rows, no predecessors, named
compile witness, and the contract's actual authorized scope. If any frozen
obligation disagrees with this proposed ACT, report the exact discrepancy.
A materially impossible or contradictory binding contract triggers
`HALT_FROZEN_SUCCESSOR_CONTRACT`; do not silently modify predecessor
evidence or invent an ABI. The new ACT may choose an ABI implementation
detail only inside explicitly authorized flexibility, frozen at C1 and
proven causally.

### 0.4 Authoritative repository and history policy

Read `AGENTS.md`, `docs/factory/DOCTRINE.md`, `docs/factory/GIT-METADATA.md`,
current Factory-v2 range/trailer/closure/append-only/F14 tools,
Make/CMake production rules, and the pinned predecessor. Obey actual
repository doctrine. When this authorization is stricter, satisfy the
stricter applicable rule or HALT with the conflicting clauses. No
historical rewrites, no substitute missing receipt, no force push.

Work on the existing local integration branch, `main`, only if its HEAD
equals the exact pinned CLOSE and the initial tracked state is clean (or
every existing residue is independently classified and harmless under
doctrine). Do not create a per-ACT feature branch. Mutations and
cross-producer experiments belong in separately named disposable git
worktree `add --detach` worktrees; preserve any worktrees that predate
this ACT. Serialize all compiler invocations until the hard-coded
`/tmp/holyc-asm.s` and Make object races are resolved in separate
authorized work.

### 0.5 Authorized change boundaries

```text
src/main.c                                  # strictly WP-001 entry / bootstrap seam
src/cli.c                                   # strictly WP-001 CLI and compile request decisions
src/main.h / src/cli.h                       # ONLY if already present and genuinely necessary
src/selfhost-driver-wp001.h                 # OPTIONAL new bounded C-facing ABI declaration
src/selfhost-driver-wp001.c                 # OPTIONAL small, source-measured mechanical host shim
src/CMakeLists.txt                          # selector, linking, generation, fail-closed verification only
Makefile                                    # subject build/prerequisite and test targets only
tools/bootstrap/selfhost-driver-wp001.HC    # new substantive compiled PolyC driver component
tools/quality/driver-migration01-*.HC       # PolyC verifiers, controls and fixtures only
tests/driver-wp001/**                       # NEW canonical regression fixtures/tests only
docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01.md
docs/factory/act-handoff-map.tsv            # exactly one append-only row
docs/ROADMAP.md                             # one bounded append-only section
evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/**
```

Permitted additional new driver-only test files may reside under `tests/`
if the existing test framework requires its specific conventional
location; record the exact pattern at C0 and demonstrate no change to old
test expectations. Any other production file outside this set requires a
separate authorization, not an opportunistic fix. In particular, do not
edit parser, AST, IR, codegen, lexer, other `tools/bootstrap/**`,
canonical gates, historical ACT/HANDOFF/evidence or third-party
dependencies.

New C host bridge must be strictly mechanical with measured bounded LOC
and exact symbols, not a copy of `main.c`'s argument handling. No Python
and no new external dependency. Existing compiler dialect constraints may
be worked around only with locally proven equivalent PolyC code (for
example, explicit `if` rather than unsupported pointer-valued ternaries);
do not alter compiler language semantics here.

### 0.6 Terminal outcomes

```text
PASS_DRIVER_POLYC_OWNED_BOOTSTRAP_WP001
HALT_ENTRY_OR_PREDECESSOR_IDENTITY
HALT_FROZEN_SUCCESSOR_CONTRACT
HALT_DRIVER_AUTHORITY_ROSTER_UNPROVEN
HALT_DRIVER_ABI_OWNERSHIP_OR_RECOVERY
HALT_POLYC_LANGUAGE_BLOCKER
HALT_PRODUCER_OR_BUILD_PROVENANCE
HALT_NO_REAL_POLYC_DRIVER_AUTHORITY
HALT_C_ONLY_ORACLE_CONTAMINATED
HALT_DRIVER_SEMANTIC_DIFFERENTIAL
HALT_C_CAUSAL_OR_POLYC_CAUSAL_UNPROVEN
HALT_CONTROL_OR_VERIFIER
HALT_CONSERVATION_OR_GATES
HALT_FACTORY_OR_TERMINALITY
```

Do not weaken a frozen requirement to avoid a HALT. A HALT must preserve
observed evidence and say exactly what smaller prerequisite ACT is
required; no production partial PASS.

## 1. Factory-v2 lifecycle, commit invariants

PASS path is exactly five distinct linear commits:

```text
C0 RED -> C1 EVIDENCE -> C2 IMPL -> C3 EVIDENCE -> C4 CLOSE
```

C1 source/ABI/fixtures/oracle contracts must be committed before C2
production implementation. Commit trailers for each phase must be
prevalidated by repository tools. Do not combine C1 with C3 or later
repair unpublished commits by replays if the repository's append-only
contract prohibits doing so. One terminal `ACT-Phase: CLOSE` plus
`ACT-Verdict: PASS` with `ACT: ACT-POLYC-SELFHOST-DRIVER-MIGRATION01` and
no tracked follow-up; AC50 is discharged only by external, read-only,
post-CLOSE verification bound to final HEAD/TREE. A technical HALT uses the
canonical permissible shortened HALT phase sequence with actual unrun AC
statuses.

## 2. C0 — RED: exact entry, 32-row driver audit, frozen controls

### 2.1 Identity and baseline

Execute and preserve exact output and exit codes:

```sh
set -eu
git branch --show-current
git rev-parse HEAD 'HEAD^{tree}'
git status --porcelain=v1
git replace -l
git log -1 --format='%H%n%P%n%B'
git worktree list --porcelain
git ls-tree -r --name-only HEAD evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/
git show HEAD:evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/selected-successor-contract.md
```

Require HEAD `2288a80330b9907341cd8a7d62d33cbfe9da5452` and reproduce the
actual TREE without guessing. Verify unique predecessor CLOSE, five
phase-bearing commits, external receipt if accessible, 15 existing
production authority sources/subject objects/importing callers, and all
older historical evidence intact. An inaccessible predecessor receipt is
`UNAVAILABLE`, never reconstructed from a claimed PASS.

Freeze `src/main.c` and `src/cli.c` by Git OID, SHA-256, function
intervals, and actual C compile/link inputs. Read the live implementation
of command parsing, default flags, install prefix, output path,
compiler-mode selection, error handling, status propagation, and entry
point. Make the exact 32-row predecessor roster a materialized C0 input,
join it to C source, and classify each row `DRIVER_SEMANTIC`,
`C_MECHANICAL`, `OUT_OF_WP001`, `DORMANT`, `DUPLICATE`, or `UNRESOLVED`,
with evidence. Missing/extra/unresolved IDs block claims of complete
driver coverage.

Capture the true installed-prefix configuration and avoid the known
false-green unit-test path. Run the actual parser baseline (historical
376/376, ordered MD5 `b6f117eb1386ca80f81bc06226e2a741`), direct lexer
differentials (89/89, 45/45, 23/23) and a fresh CLI fixture population.
Known broad lexer corpus (15 historical failures, identity MD5
`7ee761440de83552e751e3c3976c1683`), cross-target-prefix (67 historical
environment failures), F-NO-PYTHON (12 historical violations),
F-POLYC-TOOLS (`UNAVAILABLE`) must be measured where safe or recorded
`NOT_REMEASURED`/`FAIL_KNOWN_BASELINE`, never PASS by relabeling.

### 2.2 Driver feature/decision census

Derive a frozen `driver-cases.tsv` from live CLI source and actual
executable behavior, not from a handpicked happy path. Include at minimum
when supported by G0: `--install-dir`, `-c`, `-o`, order/permutation,
missing argument, unexpected option, nonexistent source, unwritable
output, invalid prefix, no arguments, success/fit exit status, and
help/version/error output. If a flag is not supported at entry, record
`UNSUPPORTED_IN_G0` rather than adding it speculatively.

Each row requires a stable case ID, argv vector in an unambiguous encoded
representation, working directory, input fixture SHA, expected
output/exit/stderr/stdout identity class, side effects, decision owner and
source-line witness. Named `WP001_COMPILE_OBJECT` must exercise a real
`.HC` program that generates a real inspectable object file.

### 2.3 Five executable REDs

Freeze AC01..AC50 and NC01..NC24 before modifications. Execute these
distinct negative claims with an independent detector and
pristine/adverse/restored outputs (new substantive detector must be
compiled PolyC; POSIX witness independent):

```text
RED                  Actual adverse change                     Required detector
R01_FAKE_DRIVER      A C-owned CLI decoder calls one inert PolyC function
                                                             POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY
R02_ORACLE_LEAK     Selector-OFF driver still links/imports driver PolyC object
                                                             C_ORACLE_CONTAMINATED
R03_DORMANT_C       Production ON still performs flag/action/status choice in legacy C
                                                             LEGACY_C_DRIVER_DECISION_ACTIVE
R04_ARGUMENT_LIFETIME Stale/invalid argv handle, truncated scalar or cross-frame recovery
                                                             DRIVER_ABI_LIFETIME_OR_DOMAIN
R05_FALSE_P0        Hybrid object compile claimed as fully PolyC-authored compiler P0/M2
                                                             BOOTSTRAP_SOURCE_CLOSURE_FALSE
```

A detector passing a fabricated outcome is vacuous. Record exact
commands, source/object digests and reason tokens. C0 PASS requires all
REDs fire for intended reasons, with input bytes restored.

## 3. C1 — EVIDENCE: independent oracle and frozen executable ABI

### 3.1 Pure C reference driver (G0)

Build an independent full C-driver compiler from the pinned entry source,
using only genuine predecessor C driver code with the new selector
disabled. It MAY retain the 15 pre-existing PolyC helper subjects (it is
C-only for the driver, not all compiler semantics). It MUST have no
definition, undefined reference, relocation, static import, link-line
input or dynamic symbol for the new driver subject/host bridge. Record all
build commands, binary SHA, entrypoint disassembly and source ranges. A
mere shell-script expected-output table is not G0.

The G0 CLI corpus and compiler-produced objects form the frozen
reference. Derive outputs from executed binaries, including failures;
normalize only environment-created unstable fields under a predeclared
justified comparison rule. Never normalize away semantically meaningful
stderr, exit statuses, CLI side effects, emitted target instructions or
object sections.

### 3.2 Executable driver ABI

Read WP-001's committed successor contract and select the smallest
implementable seam with actual compiler support. The following are design
constraints, not a claim of preapproved function signatures:

- Native C entry is permitted only as an observable mechanical trampoline
  into a compiled PolyC driver (or fully PolyC-native entry if the
  existing ABI/toolchain permits). It cannot implement the CLI decision
  table or select the compiler mode.
- PolyC owns option interpretation, argument arity/validation,
  compile-versus-other-action choice for the authorized route, request
  construction, failure/exit-status mapping and decision-bearing error
  classification.
- C owns only documented platform entry ABI, safe argument byte
  access/copying, file-descriptor I/O, target-specific process
  termination, allocation/arena handles, and mechanical calls into the
  retained C compilation engine during this precursor stage. The bridge
  may not independently parse flags or override PolyC decisions.
- Choose either a checked-index+generation+domain handle as already
  established in ABI foundation, or a source-proven constrained
  scalar/borrowed representation. Raw argv and `void*` crossing an
  unverified PolyC ABI, unchecked ownership, `longjmp` across PolyC
  frames, or a pointer-valued ternary inference workaround with unproven
  semantics are forbidden.
- Define opaque request/argument access operations with stable host
  lifetime and explicit end-of-argument checks. Distinguish absent,
  invalid, empty and valid values without conflating legitimate zero-value
  enums with failure statuses.
- Engine failure and return code must be a tested explicit status domain,
  including invalid pointer/handle, exhaustion, source rejection, output
  error and successful compilation.
- Reentrancy and concurrent calls are not assumed safe; no global mutable
  argv decoder may silently reuse stale state.

Freeze exact ABI prototypes, machine symbol spellings versus ordinary C
identifiers, ownership/lifetime matrix, valid/invalid token ranges,
callback prohibition/allowance, bridge C source LOC, link contract and all
rule identifiers. Implement a small standalone prototype in an isolated
worktree compiled by real `./hcc`, linked with a C host, and run positive
and adverse cases. No C2 edits before this ABI demonstrably works.

### 3.3 Frozen producer DAG and fixtures

Identify G0 (real C-driver oracle), G1 (driver PolyC compiled by existing
C-rooted stage0), G2 (same PolyC source compiled by current `./hcc`), G3
(same source compiled by an independently built qualified bootstrap
generation). Producers must be distinct executables by content SHA; if any
claimed generation aliases a predecessor, mark `PRODUCER_ALIAS` and HALT
instead of quietly counting all four. Object identity expected between
G1–G3 only if target flags, source bytes and deterministic compiler
settings match. G0's C object is not expected to be byte-equal to the
PolyC subject.

Freeze two separate 12-pair rosters if predecessor rules distinguish
object-side and semantic-stream comparisons. Independently enumerate all 12
ordered G0/G1/G2/G3 pairs and report both object identity (where
meaningful) and behavior equivalence without conflating them.

### 3.4 Test and authority contracts frozen before C2

Produce source-derived driver authority mapping `driver-32-row-join.tsv`
with every 32 historical row, caller and owner. Mark the expected
migrations for this ACT by independently named decision IDs; don't assign a
target count from file size. Freeze semantic cases, output comparator,
ABI, G0/G1/G2/G3 provenance, C-dormancy mutants and at least three
distinct future PolyC mutation targets: (a) flag/arity classification,
(b) compile-action dispatch and (c) status/error propagation. Where the
live source makes these inseparable, record an alternative
three-distinct-decision grouping with source and execution evidence; don't
manufacture independence.

C1 exit gate: complete contract, valid real G0, valid source-derived
fixtures, proven ABI, independently named producers and a genuinely
measurable production delegation path. Commit C1 as EVIDENCE before C2.

## 4. C2 — IMPL: real production PolyC driver

Create the new compiled PolyC driver component under `tools/bootstrap/`.
Wire a dedicated, default-ON-for-production selector (choose the exact
name at C1 and freeze it), and a selector-OFF production C-driver oracle.
The new driver owns the decision graph for the frozen compile invocation.
If a bridge is required, it must be the mechanically checked C API frozen
in C1. Never replace an existing C switch with another C switch that only
calls a decorative PolyC symbol.

The Makefile/CMake graph must fail closed when the subject object is
missing, stale, built by the wrong compiler, linked twice, compiled with
the wrong selector or not actually imported by the production entry. Place
generated-object prerequisite variables before the consuming rule (normal
GNU Make prerequisites are expanded at read time). Assert exact new PolyC
global symbol roster, expected C U relocations, absence of the new symbols
in G0, and absence of legacy C decision comparisons along the migrated
production entry route.

Do not modify other compiler subsystems. Unchanged C compilation-engine
calls are permitted as precursor host operations but are explicitly tagged
`C_SEMANTIC_ENGINE_RETAINED`, never renamed platform glue. The resulting
compiler must successfully execute the frozen end-to-end command and emit
a validated object. A PolyC driver that merely returns a fixed exit status
cannot PASS.

The three site types — arg interpretation, action dispatch, status mapping
— must be load-bearing. If source analysis proves an additional decision
is needed for the full selected route, either include it within WP-001's
authorized driver boundary with an independent proof or HALT with named
missing contract; do not conceal it in C.

C2 exit gate: new subject compiles with current bootstrap producer,
production executable links it and uses it on a real CLI request, full
source/ABI/build boundaries respected, initial G0 comparison green. No
closure claim yet.

## 5. C3 — EVIDENCE: generations, causality, conservation, controls

### 5.1 Four-generation comparison

Produce G0 / G1 / G2 / G3 executables in isolated, serialized build
directories with qualified producer hashes. Execute the same frozen CLI
cases through all four; compare exit, stdout/stderr under frozen
normalization, produced object/assembly semantics and file side effects.
Execute all 12 ordered pairwise semantic comparisons with per-row mismatch
counts. Check G1–G3 source identity and object identity separately.
Preserve differences arising from embedded build path/commit metadata as
explicit `ENVIRONMENT_EXPLAINED` only if proven unrelated to semantics;
never claim byte equality falsely.

### 5.2 PolyC-causal and C-dormancy proofs

In distinct disposable detached worktrees, apply at least three physically
independent single-rule PolyC mutations, one each against
flag/argument validation, action dispatch and status mapping, or the three
alternative C1-frozen distinct decisions. For each: verify changed bytes
confined to its own function/decision region, subject object digest
changes, real production binary rebuild returns exit 0, C caller still
imports correct symbol, witness observable changes in its own channel and
other unrelated site discriminators remain stable. Restore source/object
and behavior byte-identically where environment permits, explicitly
distinguishing environment-dependent binary identities.

For each retired legacy C driver decision, mutate its C-OFF branch: G0
behavior must change and migrated ON driver object must remain
byte-identical (or if the mutation affects a retained common object,
demonstrate by relocation/function-scoped disassembly that its decision
remains dormant and ON behavior is unaffected). Fail when active C
decision survives the selector-ON path. Poisoning the PolyC driver subject
must break real compile-output behavior; removing the object must fail
link/build, not silently fall back to C.

### 5.3 Explicit authority throughput and scope accounting

Recount the historical 32 driver rows from live C0 frozen input and map to
C3 source/output. Produce per-row `old_owner`, `new_owner`, `decision_id`,
`observable_witness`, `experiment_id`, `C_adapter_remaining`,
`claim_strength`, `status`. Count production new PolyC authorities only
when they are independently causal, live and source/caller bound. Report:

```text
DRIVER_HISTORICAL_ROWS_RECONCILED
DRIVER_ROWS_RETIRED
DRIVER_SEMANTIC_AUTHORITIES_MIGRATED
DRIVER_C_MECHANICAL_ROWS_RETAINED
DRIVER_C_SEMANTIC_ROWS_REMAINING
NEW_POLYC_PRODUCTION_AUTHORITIES
PRODUCTION_POLYC_AUTHORITIES_FINAL = 15 + NEW_POLYC_PRODUCTION_AUTHORITIES
ACTS_SPENT_FOR_WP001_SO_FAR = measured distinct real ACTs
WP001_ESTIMATE_LOW_BASE_HIGH = historical 2/3/5 (not automatically re-priced)
```

Never report transferred 32 if 32 is an authority row population rather
than independently measured semantic decisions. Record effort as actual ACT
counts, build attempts and corrections — not inferred engineering hours.
Update the WP-001 and 20-package forecast as a new versioned measurement,
not a historical rewrite. Do not report 121 total or 75 critical path as
empirically achieved.

### 5.4 Conservation and gates

Run fresh populated-prefix parser tests (376/376, identical ordered MD5);
three direct lexer differential sets; LEXER07 broad corpus if available
(15 known baseline identities, unchanged digest) or report
`NOT_REMEASURED`; cross-target likewise. Check F-NO-PYTHON's 12 historical
violations, zero new; F-POLYC-TOOLS `UNAVAILABLE` until actual checker
exists. Run `gate-fast`, then serialized `gate-push` and record all seven
check names and exit statuses. Recheck C oracle independence, F14
historical hashes (allow authorized current ACT files only), one-row map
append, append-only 11/11, closure-status, Factory-v2 range, patch
hygiene and actual worktree cleanup.

### 5.5 Adverse controls and ledger

Execute NC01..NC24, each with pristine `SILENT` -> adverse its own exact
reason -> restored `SILENT` and byte-identical state, through a compiled
PolyC verifier plus independent POSIX/Git witness. The controls must
include producer alias, orphan object, hidden C parse fallback, inaccurate
32-row counter, fake semantic equivalence, omitted error paths,
unpopulated prefix, and receipt backdating. Do not treat all controls as
satisfied by the same one synthetic label or one physical execution.

At C3: AC01..AC49 PASS and AC50 DEFERRED, no unexplained FAIL/UNPROVEN;
all controls sensitive. If any essential command has `NOT_RUN`, HALT or
explicitly narrow the claim to a non-PASS technical result.

## 6. C4 — CLOSE, external terminality and final report

Write a HANDOFF with the actually measured WP-001 migration boundary and
work-package status, append one roadmap section and one handoff-map row
preserving the historical prefix. Commit `c4/terminality-plan.txt` marked
`PLAN`, not post-CLOSE evidence. Create the unique fifth CLOSE commit with
exact Factory-v2 trailers. Only after CLOSE, run an external read-only
terminality probe storing its receipt outside the repository, bound to exact
HEAD/TREE. It must confirm committed five-phase sequence and no subsequent
tracked commits, current source/object delegations, comparator and mutant
evidence, 15 old authorities conserved plus exactly counted new
authorities, production gates, empty repo status, zero replace refs, zero
ACT-created worktrees, and no push.

No tracked receipt commit. If external terminality fails, do not append
another CLOSE or amend history; report `HALT_FACTORY_OR_TERMINALITY` and
request an independently authorized forward-only correction.

Required result keys:

```text
ACT_ID, ENTRY_HEAD, ENTRY_TREE, FINAL_HEAD, FINAL_TREE, BRANCH
FACTORY_PHASE_SEQUENCE, ACT_COMMIT_COUNT, CLOSE_SHA, ACT_VERDICT, DISPOSITION
PREDECESSOR_SELECTED_WP, WP001_CONTRACT_BLOB_OID, WP001_SOURCE_IDS
C0_DRIVER_HISTORICAL_ROWS, C3_DRIVER_ROWS_RECONCILED
WP001_DRIVER_COMPLETE, P0_COMPLETE, M1_STATUS, M2_STATUS, M3_STATUS
C_ONLY_DRIVER_ORACLE_STATUS, C_ON_DRIVER_AUTHORITY_STATUS
DRIVER_ABI_VERSION, OWNERSHIP_LIFETIME_STATUS, DRIVER_BRIDGE_C_SEMANTIC_DECISIONS
G0_G1_G2_G3_PRODUCER_SHA256, G0_G1_G2_G3_GENERATION_MATCH
PAIR_12, OBJECT_IDENTITY_SCOPE, REAL_COMPILE_OBJECT_WITNESS
POLYC_CAUSAL_EXPERIMENTS, C_DORMANCY_EXPERIMENTS, LOAD_BEARING_SUBJECT
ENTRY_AUTHORITIES=15, NEW_AUTHORITIES, FINAL_AUTHORITIES
C_DRIVER_SEMANTIC_REMAINDER, C_DRIVER_MECHANICAL_REMAINDER
GRAPH_BASE=52/135/34/19, CURRENT_GRAPH_REMEASURED, NEW_GRAPH_CUTS_PROVEN
WP001_ACT_COST_MEASURED, WP001_ESTIMATE_2_3_5_RECALIBRATION
PARSER_ASSERTIONS, PARSER_SEQUENCE_MD5, DIRECT_LEXERS, LEXER07_BROAD
CROSS_TARGET_PREFIX, F_NO_PYTHON, F_POLYC_TOOLS
GATE_FAST, GATE_PUSH, F14_STRICT, F14_AUTHORIZED_APPEND
APPEND_ONLY, FACTORY_V2_RANGE, CLOSURE_STATUS, PATCH_HYGIENE
NEGATIVE_CONTROLS_PASS, MANDATORY_AC_PASS, EXTERNAL_TERMINALITY
WORKTREE_CLEAN, GIT_REPLACE_REFS, POST_CLOSE_COMMITS, PUSH_PERFORMED=NO
NEXT_ACT_PROPOSED, NEXT_TARGET_AUTHORIZED=NO, SLICE10_AUTHORIZED=NO
```

## 7. Required evidence namespace

```text
evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/
  c0/
    entry-and-predecessor.tsv
    wp001-source-and-contract-freeze.tsv
    driver-32-row-census.tsv
    existing-15-production-authorities.tsv
    real-cli-baseline.tsv
    real-compile-object-witness.tsv
    five-red-executions.tsv
    frozen-ac01-ac50.tsv
    frozen-nc01-nc24.tsv
    conservation-baseline.txt
  c1/
    abi-ownership-and-recovery.md
    frozen-driver-seam-and-glue.tsv
    host-abi-prototype-experiment.tsv
    g0-c-driver-build-provenance.tsv
    g0-driver-fixtures.tsv
    generation-producer-dag.tsv
    driver-source-derived-cases.tsv
    decision-authority-and-mutation-contract.tsv
    comparator-and-12-pair-contract.md
  c2/
    production-delegation-and-selector.tsv
    subject-build-and-link-provenance.tsv
    object-disassembly-and-relocations.tsv
    cset-oracle-absence-not-applicable.txt
    real-end-to-end-compile-witness.tsv
  c3/
    g0-g1-g2-g3-matrix.tsv
    12-ordered-comparisons.tsv
    polyc-mutation-a.tsv
    polyc-mutation-b.tsv
    polyc-mutation-c.tsv
    c-legacy-dormancy.tsv
    driver-32-row-reconciliation.tsv
    canonical-regression-cases.tsv
    forecast-calibration.tsv
    negative-controls-executions.tsv
    independent-control-witness.tsv
    ac01-ac50-ledger.tsv
    baseline-conservation.txt
    gate-fast.txt
    gate-push.txt
    f14-and-append-only.txt
  c4/
    terminality-plan.txt
```

Bounded additional experiment files may be added only inside this
namespace and must be manifested. The external post-CLOSE receipt must be
outside the repository.

## 8. Frozen negative controls NC01..NC24

Controls require real adverse mutations on disposable copies and
reason-specific detector outputs; source and record state must restore
byte-identically. An output row with PASS copied from an expected field is
not a qualifying execution.

```text
ID    Adverse condition                                     Required reason token
NC01  Wrong entry HEAD/TREE or false CLOSE ancestor          ENTRY_OR_ANCESTRY_MISMATCH
NC02  Edit frozen WP-001 contract/source blob               FROZEN_SUCCESSOR_BLOB_CHANGED
NC03  Drop or duplicate historical 32 driver source row     DRIVER_32_ROSTER_MISMATCH
NC04  Count mechanical main trampoline as semantic migration MECHANICAL_TRAMPOLINE_MISCOUNT
NC05  Count dormant/unlinked subject as production authority UNLINKED_OR_DORMANT_POLYC_SUBJECT
NC06  Selector-OFF oracle still imports driver PolyC symbol  C_ORACLE_CONTAMINATED
NC07  Selector-ON C code still chooses recognized compiler action LEGACY_C_OPTION_DECISION_ACTIVE
NC08  Production fallback to C when PolyC subject absent     LOAD_BEARING_LINK_OR_DELEGATION
NC09  Missing effective Make prerequisite due to late expansion OBJECT_PREREQUISITE_MISSING
NC10  CMake configure flags become shell commands or fail-open CONFIGURATION_FLAG_NOT_APPLIED
NC11  Forged producer identity or aliased G1/G2/G3             GENERATION_PRODUCER_ALIAS
NC12  Cross-target or wrong-prefix compiler silently accepted TARGET_OR_PREFIX_MISMATCH
NC13  Invalid, stale or wrong-domain argv/request handle accepted DRIVER_HANDLE_LIFETIME_OR_DOMAIN
NC14  Cross-language longjmp or invalid recovery crossing accepted DRIVER_RECOVERY_BOUNDARY
NC15  Error status collides with a valid zero-value action/result DRIVER_STATUS_VALUE_COLLISION
NC16  No-argument or missing -o argument silently treated as valid DRIVER_ARGUMENT_ARITY_MISMATCH
NC17  Changing flag decision does not change real executable outcome POLYC_FLAG_CAUSAL_NOT_LOAD_BEARING
NC18  Changing action dispatch does not change produced object/behavior POLYC_DISPATCH_CAUSAL_NOT_LOAD_BEARING
NC19  Changing exit/error mapping has no independently observed effect POLYC_STATUS_CAUSAL_NOT_LOAD_BEARING
NC20  Comparator ignores changed exit, stderr, output or object semantics GENERATION_COMPARATOR_INSENSITIVE
NC21  Compiler success claimed without real valid output object  COMPILER_OUTPUT_WITNESS_MISSING
NC22  Driver counts 32 retired though only fewer decisions proven AUTHORITY_THROUGHPUT_FALSE_COUNT
NC23  Hybrid subject object improperly labelled as M2 generation M2_SOURCE_PRODUCER_MISCLASSIFIED
NC24  Forge AC IDs, controls, gates, or external terminality before CLOSE LEDGER_OR_TERMINALITY_FALSE_PASS
```

## 9. Frozen mandatory acceptance criteria AC01..AC50

At C3: AC01–AC49 PASS, AC50 DEFERRED. AC50 only PASS after an external
read-only receipt produced after fifth CLOSE. No missing/duplicate/extra
criteria; every ID must have a concrete execution or source-bound evidence
path.

```text
ID    Phase  Mandatory predicate
AC01  C0     Exact pinned HEAD, derived tree, branch and clean classified state; no push/fetch/rebase
AC02  C0     Unique REBASE01 CLOSE and binding predecessor PASS independently verified
AC03  C0     Full selected-successor-contract and source closure read from committed bytes
AC04  C0     Predecessor source ranges and WP-001 source/row identities frozen with SHA/OID
AC05  C0     All 15 existing production PolyC authorities independently source/link/callsite proven
AC06  C0     Existing A64 FOR/INV remain active, CSET remains mechanical and uncounted
AC07  C0     Original 32 driver authority rows each source-reconciled, 0 lost IDs
AC08  C0     Real entry/CLI/compile output baselines captured from correct populated prefix
AC09  C0     Five RED detectors fire independently for exact intended reason and restore
AC10  C0     Known parser/lexer/history non-greens classified without false PASS
AC11  C1     A real C-driver G0 built with new subject absent in full executable link
AC12  C1     C0 derived CLI fixtures cover normal and adverse reachable invocation forms
AC13  C1     Chosen driver ABI is source-justified, fully specified and frozen before C2
AC14  C1     Host ownership, argument lifetime, token domain and recovery invariants proven
AC15  C1     Actual PolyC host prototype compiles, links and passes positive/adverse tests
AC16  C1     Legacy C versus PolyC-owned semantic decision boundaries are explicit
AC17  C1     C glue roster proves platform/mechanical duties and forbids redundant parsing
AC18  C1     Source-derived status/result domain covers valid zero, errors and exhaustion
AC19  C1     G0-G3 producer identities and target/configuration are independently proved
AC20  C1     Twelve ordered generation-comparison contract pairs separately frozen
AC21  C1     Frozen driver fixture set includes real object-producing successful command
AC22  C1     Source-bound 32-row expected ownership map and future causal sites frozen
AC23  C1     Independent comparator is proven capable of detecting representative divergence
AC24  C1     C1 ABI, G0, fixture and causal contracts committed as independent EVIDENCE
AC25  C2     New PolyC driver owns actual CLI interpretation on production invocation
AC26  C2     New PolyC driver owns action selection, request formation and status mapping
AC27  C2     C entry/trampoline and bridge contain no duplicated C driver decisions
AC28  C2     Real production object imports new driver symbol with proven relocation/call
AC29  C2     Production build fails closed for missing, stale or wrong-selector subject
AC30  C2     Selector-OFF G0 remains driver-C-only, with zero driver subject symbols
AC31  C2     Compiled production driver produces a real inspected target object
AC32  C2     All 15 original authorities continue to be linked and actively used
AC33  C3     G0-G3 objects/executables have qualified producer and source provenance
AC34  C3     All twelve ordered semantic-stream pairs agree over frozen fixture roster
AC35  C3     Comparable PolyC object identities agree or exact difference is explained
AC36  C3     At least three independent PolyC mutations are causally load-bearing
AC37  C3     Legacy C mutations live in G0 and dormant in production ON
AC38  C3     Original 32-row roster remapped to measured transferred/retained authorities
AC39  C3     No falsely claimed M1, P0-complete, M2, M3 or new graph cut
AC40  C3     Canonical new driver regression tests cover positive/negative CLI cases
AC41  C3     Independent witness re-derives selected sources, build identities and decisions
AC42  C3     Twenty-four adverse controls fire named detectors and restore every input
AC43  C3     Original parser and direct lexer identities conserved; non-greens honest
AC44  C3     gate-fast and serialized gate-push PASS with seven check results
AC45  C3     Factory/F14/append-only/closure/patch hygiene PASS with one authorized map append
AC46  C3     New authority count and WP-001 ACT throughput calibrated from actual evidence
AC47  C3     AC roster has exactly 50 IDs; AC01..AC49 PASS, AC50 DEFERRED
AC48  C4     Single fifth CLOSE carries exact ACT/phase/verdict trailers; no tracked continuation
AC49  C4     External post-CLOSE read-only receipt bound to exact HEAD/TREE discharges AC50
AC50  C4     Clean tree, no replace refs, ACT worktrees cleaned, no push and accurate milestone labels
```

## 10. Decision provenance and honest reporting rules

- The reported 32 rows and 1,257 LOC are inherited selection facts, not
  accepted migration counts until the C0 live-source audit and C3 executed
  comparison join.
- The 20-package M2 DAG's 121 base total and 75 critical path are
  package-budget scenarios, not a measurement of driver migration
  productivity; do not conflate them with fine-grained 1,897 extrapolation.
- The original historical CENSUS01 355 and later 1897 figures remain
  historical model outputs, never rewritten or promoted to current
  completed work. P0/WP001 calibration should update the plan as an
  append-only new model revision.
- Graph baseline originally 52 nodes / 135 mandatory edge rows / 34 SCC /
  largest 19. Do not count E-TYP-0136 as a new cut, do not rehabilitate
  unsupported E-MUT-0137 evidence without actual source/object proof. Any
  new mandatory edge retirement requires independently verified
  production-specific witness.
- A source compiled by host-stage0/hcc and linked into C-rooted ./hcc is
  still part of a hybrid producer, even when it drives the CLI. Any
  self-host milestone claim requires source manifest, production executable
  provenance and actual generation acceptance, not names.
- Known infrastructure defects stay visible: fail-open unpopulated
  unit-test prefix, `/tmp/holyc-asm.s` race, parallel Make object race,
  global `Main(argc,argv)` collision, duplicate incompatible `extern "c"`
  ABI declaration, pointer-ternary/inference issues, ARM64 indexed
  byte-load emission, three-dimensional array and unsupported `?:` grammar.
  Only those proven to block WP-001 may trigger a named HALT or a
  source-equivalent local workaround. Do not repair unrelated compiler
  semantics inside this ACT.

## 11. Non-binding methodological references

- Git worktree isolation: https://git-scm.com/docs/git-worktree.
- Git trailers: https://git-scm.com/docs/git-interpret-trailers.
- GNU Make immediate prerequisite expansion:
  https://www.gnu.org/software/make/manual/html_node/Reading-Makefiles.html
  and
  https://www.gnu.org/software/make/manual/html_node/Secondary-Expansion.html.
- GCC stage comparison: https://gcc.gnu.org/install/build.html.

These are methodological, not replacements for the actual PolyC
source/Factory doctrine.

## 12. Final invariant

This ACT is successful only if a production-used PolyC-authored driver
controls a genuine compiler-producing CLI invocation, the C driver
decisions it supplants are demonstrably dormant, the independent C oracle
and generation comparators agree, and the milestone is reported **WP-001
driver migrated**, not self-hosted compiler. If the live repository or
frozen successor contract makes that impossible within this scope, HALT
accurately instead of manufacturing a PASS.
