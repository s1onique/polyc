# `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01`

**Title:** Reconcile the WP-001 driver-boundary audit's frozen acceptance
contract, repair evidence binding, and requalify route-scoped semantic
ownership without rewriting history or changing production code.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main` — reuse the existing checkout. Do not create a
per-ACT branch.

**Class:** CORRECTION / EVIDENCE INTEGRITY / SEMANTIC QUALIFICATION

**Predecessor:** `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01`

**Factory-Version:** 2

**Production semantic changes:** **FORBIDDEN**.

**Historical evidence mutation:** **FORBIDDEN**.

**History rewrite:** **FORBIDDEN**.

**New production authority credited:** **ZERO**.

---

## 0. Mission

The predecessor audit closed with:

```text
VERDICT = PASS_FINDINGS_WITH_REMAINDER
```

It reported two retained C-semantic decisions, correctly rejected an
unqualified PolyC driver-ownership claim, and disclosed historical
terminality uncertainty.

However, its own evidence contains inconsistencies that were not
qualified before closure.

This correction must establish:

```text
FROZEN_AC_CONTRACT_RECONCILED       = TO_BE_MEASURED
AC_PREDICATE_WITNESSES_VALIDATED    = TO_BE_MEASURED
AC_LEDGER_CARDINALITY_CORRECT       = TO_BE_MEASURED
ROUTE_SCOPE_ATTRIBUTION_VALIDATED   = TO_BE_MEASURED
DECISION_OWNER_CAUSALLY_QUALIFIED   = TO_BE_MEASURED
BASELINE_STATUS_CONSERVED           = TO_BE_MEASURED
HISTORICAL_PROVENANCE_PRESERVED     = TO_BE_MEASURED
```

The task is to determine what the predecessor evidence actually
supports, correct the present interpretation, and provide an
independent verification mechanism.

**Do not optimize for reproducing the predecessor's PASS verdict.**

A correction that establishes that some predecessor acceptance
criteria were not discharged is a valid correction outcome.

This ACT must not change the compiler, migrate driver logic, invent
missing historical measurements, or retroactively repair the
predecessor's authorization chronology.

---

## 1. Frozen entry identity

The reported predecessor state is:

```text
PREDECESSOR_HEAD =
907af8c82abfb2292d5eccfdf18b63080da767f2

PREDECESSOR_TREE =
8e60f304c91980e89c05305af508d08aba88f241

PREDECESSOR_CLOSE =
edfc3b16

PREDECESSOR_POST_CLOSE_OUTCOME =
907af8c8

PREDECESSOR_VERDICT =
PASS_FINDINGS_WITH_REMAINDER
```

Before modifying anything:

```sh
git branch --show-current
git status --porcelain=v1
git rev-parse HEAD
git rev-parse HEAD^{tree}
git replace -l
git log -8 --format='%H %s'
```

Verify the exact predecessor objects exist:

```sh
git cat-file -t \
  907af8c82abfb2292d5eccfdf18b63080da767f2

git rev-parse \
  907af8c82abfb2292d5eccfdf18b63080da767f2^{tree}
```

The expected predecessor tree is the SHA stated above.

The current HEAD may have advanced linearly since the predecessor. If
so, record the actual entry HEAD/TREE and verify that the predecessor
is its ancestor.

Do not silently reset to the predecessor.

If the branch has diverged, relevant production code has changed, the
working tree contains unrelated changes, or the expected predecessor
identities cannot be established:

```text
HALT_ENTRY_IDENTITY_OR_SCOPE_UNPROVEN
```

Do not discard or stash user changes.

### 1.1 Mandatory reading

Read the actual committed contents of:

```text
AGENTS.md
docs/CHARTER.md
docs/ROADMAP.md
docs/factory/DOCTRINE.md

docs/acts/
  ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md

docs/factory/
  HANDOFF-ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md
```

Read the predecessor evidence under:

```text
evidence/
  ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/
```

Read the relevant historical WP-001 driver migration ACTs, corrections,
and their committed receipts.

All historical material is read-only for this correction.

**The supplied review findings are hypotheses until reproduced against
the actual committed objects.**

If a reported defect is not reproducible, mark it `NOT_REPRODUCED`; do
not implement a speculative correction.

---

## 2. Scope

### 2.1 Allowed modifications

Only:

```text
docs/acts/
  ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01.md

docs/factory/
  HANDOFF-ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01.md

docs/factory/act-handoff-map.tsv

docs/ROADMAP.md

evidence/
  ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01/**

tools/quality/
  driver-boundary-qualification01-correction01-*.HC
```

Changes to `docs/ROADMAP.md` are limited to an append-only
correction/outcome section or the minimal existing status-index linkage
required by Factory doctrine.

The historical `WP001_DRIVER_MIGRATION = ACHIEVED` claim must remain
identifiable as the historical claim, even if the correction records
that the claim is not presently supported.

### 2.2 Forbidden modifications

```text
src/**
tests/**
tools/bootstrap/**
scripts/**
Makefile
src/CMakeLists.txt
AGENTS.md
docs/factory/DOCTRINE.md
```

Also forbidden:

- Modifying any existing predecessor evidence file.
- Editing the frozen AC01–AC50 roster.
- Editing the frozen NC01–NC24 roster.
- Rewriting old acceptance ledgers.
- Amending, rebasing, replacing, or force-pushing Git history.
- Changing canonical Factory gates.
- Weakening existing tests or detectors.
- Introducing Python or new dependencies.
- Changing LLVM, compiler-driver, parser, lexer, or ABI production
  semantics.
- Crediting new PolyC authority from an audit.
- Claiming M2 or whole-compiler self-hosting progress.

New verification programs may be introduced under the authorized
`tools/quality/` prefix.

Disposable source mutations for counterfactual experiments are allowed
only in isolated temporary checkouts or worktrees. They must never
enter production commits.

Do not push unless separately authorized.

---

## 3. Defect D1 — Frozen acceptance contract drift

### 3.1 The frozen authority

The predecessor's Q0 roster is:

```text
evidence/.../q0/frozen-ac01-ac50.tsv
```

It contains exactly 50 acceptance criteria:

```text
AC01 ... AC50
```

Each criterion has:

```text
ac_id
phase
mandatory_predicate
```

The authoritative interpretation is the exact committed frozen row, not
a later paraphrase.

### 3.2 The suspect ledger

The Q3 acceptance ledger is:

```text
evidence/.../q3/acceptance-ledger.tsv
```

It contains:

```text
ac_id
phase
status
witness_artifact
measured
```

The review identified at least five phase mismatches:

```text
AC14 frozen=Q1 ledger=Q0
AC15 frozen=Q1 ledger=Q0
AC16 frozen=Q1 ledger=Q0
AC17 frozen=Q1 ledger=Q0
AC18 frozen=Q1 ledger=Q0
```

More importantly, the ledger's descriptions do not discharge the
original frozen predicates.

For example:

```text
FROZEN AC14:
Per-branch driver/engine/mechanical/PolyC
ownership definitions frozen.

LEDGER AC14:
An independent POSIX witness agrees with
the compiled detector on 5 of 5.
```

Those are different predicates.

A matching AC identifier does not make them equivalent.

### 3.3 Required measurement

Reconstruct the original AC roster and acceptance ledger from Git
objects.

Produce a complete 50-row join:

```text
ac_id
frozen_phase
ledger_phase
frozen_predicate
ledger_status
ledger_claim
claimed_witness_path
witness_exists
witness_is_relevant
witness_is_sufficient
verified_status
reason
```

All 50 IDs must be present exactly once.

Compare phases exactly.

Do not compare only row IDs or row counts.

For every reported `PASS`, verify that the named evidence supports the
actual frozen predicate.

Distinguish:

```text
WITNESS_EXISTS
WITNESS_MATCHES_PREDICATE
WITNESS_SUPPORTS_CLAIM
WITNESS_PRODUCER_IDENTITY_VALID
WITNESS_TIMING_VALID
```

Existence alone is not sufficient.

When a witness is relevant but insufficient, record the precise
insufficiency.

### 3.4 AC12 special case

Frozen AC12 requires:

```text
Real compile-output fixture succeeds and
produces inspected object.
```

The ledger instead cites G0 producer independence.

Determine whether the required real compile-output fixture exists
elsewhere in the frozen evidence.

If it exists, bind the correct evidence.

If not, do not accept AC12 merely because G0 independence was
established.

### 3.5 Required verdicts

Each predecessor criterion must receive one of:

```text
PROVEN_AS_FROZEN
PROVEN_BY_ALTERNATE_EXISTING_WITNESS
UNSUPPORTED_BY_CITED_WITNESS
CONTRADICTED
UNPROVEN
NOT_APPLICABLE_WITH_PROOF
DEFERRED_AT_HISTORICAL_CHECKPOINT
```

Do not silently replace missing evidence with a new measurement and
call the historical criterion fulfilled at Q3.

Fresh evidence must be recorded in a separate successor column.

**Historical validity and present reproducibility are separate facts.**

---

## 4. Defect D2 — Acceptance cardinality and status accounting

The committed Q3 ledger contains 50 AC rows:

```text
AC01 ... AC50
```

It also contains:

```text
AC_ROSTER_SIZE
```

The latter is metadata, not acceptance criterion AC51.

The as-committed ledger reports:

```text
AC01..AC49 = PASS
AC50       = DEFERRED
```

Therefore its criterion-only status count is:

```text
PASS      = 49
FAIL      = 0
DEFERRED  = 1
TOTAL     = 50
```

But its written summary includes:

```text
LEDGER_PASS     = 49
LEDGER_FAIL     = 0
LEDGER_DEFERRED = 2
AC_ROSTER_SIZE  = 50
```

That summary counts an additional deferred metadata row.

The handoff separately reports:

```text
ACCEPTANCE_LEDGER = 46 PASS, 0 FAIL, 5 DEFERRED
```

These are not equivalent representations.

### 4.1 Required correction

Implement a cardinality verifier that:

1. Recognizes only the exact `AC01` through `AC50` identifier set as
   criteria.
2. Rejects missing or duplicate IDs.
3. Rejects unexpected criterion IDs.
4. Excludes `AC_ROSTER_SIZE` from status arithmetic.
5. Verifies `PASS + FAIL + DEFERRED = 50` for the historical Q3
   snapshot.
6. Distinguishes actual ledger-row counts from handoff summary claims.
7. Preserves the original historical values in the audit report.

Do not rewrite the original ledger to 49/0/1.

Instead produce a forward-only reconciliation:

```text
HISTORICAL_LEDGER_ROWS
HISTORICAL_LEDGER_STATUS_COUNTS
HISTORICAL_SUMMARY_COUNTS
RECOMPUTED_CRITERION_COUNTS
COUNT_DISAGREEMENTS
```

### 4.2 AC50 chronology

At Q3, AC50 was legitimately deferred because the external post-close
probe had not yet executed.

The subsequent external probe reportedly passed 12/12 after the
predecessor close.

These are two separate observations.

The correction must record:

```text
AC50_AT_Q3 = DEFERRED

AC50_EXTERNAL_POST_CLOSE_OBSERVATION =
TO_BE_INDEPENDENTLY_VERIFIED
```

If the external receipt cannot be inspected as actual bytes, do not
promote the result based on a handoff or filename.

A successful later observation does not retroactively change the Q3
snapshot.

---

## 5. Defect D3 — Missing or misbound evidence

The Q3 acceptance ledger contains:

```text
AC38
witness_artifact =
q3/causal-execution-and-provenance.tsv
```

The supplied changeset identifies the corresponding causal execution
artifact under:

```text
q2/causal-execution-and-provenance.tsv
```

No `q3/causal-execution-and-provenance.tsv` appears in the changeset.

This must be verified against the actual predecessor close tree.

### Required checks

For every acceptance witness:

```text
PATH_PRESENT_IN_CLOSE_TREE
PATH_PRESENT_AT_RELEVANT_PHASE
PATH_HAS_EXPECTED_CONTENT
PATH_MATCHES_FROZEN_PREDICATE
PATH_HAS_VALID_PROVENANCE
```

Do not silently repair a missing path by searching for a similarly
named file.

Record the claimed path and discovered candidate path separately.

If a valid alternative witness exists, classify it:

```text
PROVEN_BY_ALTERNATE_EXISTING_WITNESS
```

only after independently verifying its contents and chronology.

Do not use an artifact committed after the claimed phase as proof that
it existed during that phase.

Produce:

```text
evidence-binding-audit.tsv
```

covering all 50 criteria, not merely AC38.

---

## 6. Defect D4 — Route-scoped semantic ownership

This is the principal technical qualification.

The predecessor concluded:

```text
POLYC_OWNED_DECISION_PROVEN       = 9
C_MECHANICAL_EXECUTION_PROVEN    = 12
C_SEMANTIC_RETAINED_WP001        = 2
DORMANT_OR_UNREACHABLE_PROVEN    = 9

WP001_REQUIRED_ROUTE_REMAINDER   = 2
GLOBAL_DRIVER_REMAINDER          = 2
```

The two cited C counterfactuals are:

```text
BR_EMITFILE_EMIT_OBJECT
src/main.c:250

BR_MAIN_PRINT_TOKENS
src/main.c:519
```

The frozen required route is:

```text
--install-dir=X -c input.HC -o out.o
```

### 6.1 The scope mismatch

The predecessor's branch matrix records:

```text
BR_EMITFILE_EMIT_OBJECT:
  route_scope = WP001_REQUIRED_ROUTE

BR_MAIN_PRINT_TOKENS:
  route_scope = WHOLE_CLI_SURFACE
```

The `main()` witness uses:

```text
-tokens input.HC
```

This proves that the token-dispatch branch affects an executable CLI
route.

It does not, by itself, establish that the same branch selects
behavior when the required compile-object route executes.

The 32-row classification marks the entire `main()` function as
required-route reachable.

But:

```text
FUNCTION_REACHABLE_ON_ROUTE
```

does not imply:

```text
EVERY_BRANCH_WITHIN_FUNCTION_REACHABLE_ON_ROUTE
```

The correction must enforce that distinction.

### 6.2 Required branch-level analysis

Build a source-derived decision matrix for `main()` and `emitFile()`.

For every relevant decision-bearing branch, record:

```text
branch_id
function
source_blob_oid
source_interval
condition
input_or_control_origin
required_route_reachable
whole_cli_reachable
selected_behavior
semantic_owner_candidate
linked_execution_witness
counterfactual_result
confidence
```

Do not use a whole-function classification as branch-level proof.

Classify route reachability as:

```text
PROVEN_REACHABLE
PROVEN_UNREACHABLE
UNPROVEN
```

`PROVEN_UNREACHABLE` requires a concrete control-flow or execution
argument, not merely absence from a small fixture corpus.

### 6.3 Mandatory counterfactuals

Use the actual production CMake build, not an ad-hoc object link.

For `emitFile()`:

```text
BASELINE:
if (args->emit_object)

MUTANT:
if (0 && args->emit_object)
```

Exercise the exact frozen required route.

Record:

```text
source SHA
mutant source SHA
object SHA
linked binary SHA
real compiler build command
build exit code
selected artifact path
artifact type
artifact size
stdout/stderr
restored source SHA
```

For `main()`:

```text
BASELINE:
if (args.print_tokens)

MUTANT:
if (0 && args.print_tokens)
```

Repeat the original discriminating token-route witness.

Then independently analyze the required compile-object route and identify
which `main()` branch actually selects or executes that action.

If a separate C branch governs compile-object behavior, construct and
execute an additional linked counterfactual for that branch.

If no discriminating required-route witness can be produced, record the
specific missing proof and leave the route-scoped total unproven.

**Do not automatically assert that the required-route remainder is one
or two. Measure it.**

### 6.4 Keep distinct result dimensions

Report:

```text
RETAINED_C_SEMANTIC_ROWS_WITHIN_32
RETAINED_C_SEMANTIC_BRANCHES_PROVEN_GLOBAL
RETAINED_C_SEMANTIC_BRANCHES_PROVEN_REQUIRED_ROUTE

REQUIRED_ROUTE_UNPROVEN_BRANCHES
WHOLE_CLI_UNPROVEN_BRANCHES
```

The historical 32-row classification and the new branch-level
classification must not be conflated.

A count of two historical retained-C rows can coexist with a different
number of route-specific proven branches.

Provide an explicit crosswalk.

---

## 7. Defect D5 — Semantic decision versus mechanical execution

Both reported C branches consume fields ultimately derived from
PolyC-selected options:

```text
WP_DRIVER_FIELD_PRINT_TOKENS
WP_DRIVER_FIELD_EMIT_OBJECT
```

A C conditional responding to a PolyC-selected field does not
automatically establish independent C policy ownership.

Equally, the fact that PolyC selected a field does not automatically
prove that all downstream C behavior is mechanical.

### 7.1 Required decision-owner test

Separate three questions:

```text
WHO SELECTS THE INTENT?

WHO SELECTS THE RESULTING ACTION?

WHO EXECUTES THE ACTION?
```

For each retained-C candidate, establish whether C:

- Merely transports a selected PolyC decision.
- Mechanically executes a fully specified PolyC decision.
- Maps a PolyC-selected value to a separate C policy choice.
- Independently selects an output behavior not fully specified by the
  PolyC decision.

Use the following conceptual classification:

```text
POLYC_SEMANTIC_OWNER_C_EXECUTOR
C_SEMANTIC_OWNER_PROVEN
SHARED_DECISION_OR_INSUFFICIENT_SEPARATION
UNPROVEN
```

These are correction-level analysis labels, not replacements for
historical frozen roster terminology.

### 7.2 Two-sided causal evidence

Where technically possible, perform both:

**PolyC-side intervention**

Mutate the decision selected by the PolyC driver while preserving the C
consumer.

Observe whether the resulting action changes.

**C-side intervention**

Mutate the C consumer while preserving the PolyC-selected value.

Observe whether the resulting action changes.

These interventions establish causal influence, but not exclusive
authority by themselves.

Add source-derived analysis showing whether the C branch implements its
own policy or merely realizes the already selected action.

Do not infer independent decision ownership solely because suppressing
a branch suppresses behavior.

### 7.3 Qualification outcome

For each branch, produce:

```text
branch-ownership-qualification.tsv
```

with:

```text
POLYC_INTENT_PROVEN
C_ACTION_MAPPING_PROVEN
C_INDEPENDENT_POLICY_PROVEN
MECHANICAL_EXECUTION_PROVEN
FINAL_QUALIFICATION
```

If the distinction cannot be established, use:

```text
UNPROVEN
```

The next migration ACT must not treat an unproven policy boundary as a
proven migration target.

---

## 8. Defect D6 — Baseline status conservation

The predecessor reports successful baseline conservation, including
parser 376/376 and lexer direct-diff values.

However, the committed baseline ledger contains:

```text
LEXER07_DIRECT_DIFF_PASS
  historical = 89
  measured = COUNTS_NOT_REPORTED
  status = NOT_REMEASURED

LEXER07_DIRECT_DIFF_FAIL
  historical = 0
  measured = COUNTS_NOT_REPORTED
  status = NOT_REMEASURED
```

That is not equivalent to freshly measuring 89 PASS and zero FAIL.

### Required handling

Preserve three distinct states:

```text
HISTORICAL_VALUE
FRESH_MEASUREMENT
CONSERVATION_VERDICT
```

For LEXER07, verify whether a separate executable witness actually
remeasured the direct-diff counts.

If yes, bind its exact command, output, and producer identity.

If no, retain:

```text
FRESH_MEASUREMENT = NOT_REMEASURED
```

Do not rewrite the predecessor's result.

Reconcile the handoff's textual statement with the committed ledger's
actual measurement state.

Repeat the same treatment for:

```text
LEXER07_BROAD_CORPUS
CROSS_TARGET_PREFIX
F_NO_PYTHON
```

The historical known failure must remain a known failure.

A correction may perform new measurements, but those are new evidence,
not changes to historical observations.

---

## 9. Defect D7 — Detector parity and negative-control integrity

The predecessor froze NC01–NC24.

Six expected reason tokens were initially missing from its detectors and
were later implemented in the Q2 verifier:

```text
CORRECTION_CLOSE_IDENTITY_WRONG
NON_ACT_TRAILER_PROMOTED
HISTORICAL_CLOSE_DUPLICATE_HIDDEN
MUTATION_LINK_PROVENANCE_MISSING
G0_DRIVER_CONTAMINATED
COMPILER_SEMANTIC_COMPARATOR_INSENSITIVE
```

The correction must determine the exact frozen detector capabilities at
Q0 and the implemented verifier capabilities at Q2/Q3.

Do not claim that the Q0 detector supported controls that were
introduced later.

A historical Q0 capability cannot be backdated by a correction.

### Required output

Produce:

```text
negative-control-capability-matrix.tsv
```

with:

```text
nc_id
frozen_reason
q0_detector_supported
q2_verifier_supported
q3_execution_proven
current_correction_detector_supported
historical_discrepancy
```

If parity is needed, implement it in the new correction verifier or a
new copied detector under authorized paths.

**Do not modify or overwrite the original Q0 detector.**

The correction's verifier must reject at least the following 18
adverse conditions, each with its own exact reason:

| ID | Adverse condition | Required reason |
|---|---|---|
| NC-C01 | AC14 phase altered | `FROZEN_AC_PHASE_DRIFT` |
| NC-C02 | AC14 predicate substituted | `FROZEN_AC_PREDICATE_DRIFT` |
| NC-C03 | AC12 irrelevant witness accepted | `AC_WITNESS_PREDICATE_MISMATCH` |
| NC-C04 | Duplicate AC ID accepted | `AC_ID_DUPLICATE` |
| NC-C05 | Missing AC ID accepted | `AC_ID_MISSING` |
| NC-C06 | Metadata counted as criterion | `AC_METADATA_COUNTED` |
| NC-C07 | False status totals accepted | `AC_STATUS_TOTAL_FORGED` |
| NC-C08 | Missing witness path accepted | `AC_WITNESS_MISSING` |
| NC-C09 | Witness from wrong phase accepted | `AC_WITNESS_CHRONOLOGY_INVALID` |
| NC-C10 | Token-route witness counted as required-route proof | `BRANCH_ROUTE_SCOPE_LAUNDERED` |
| NC-C11 | Function reachability substituted for branch reachability | `FUNCTION_BRANCH_REACHABILITY_CONFLATED` |
| NC-C12 | C execution automatically equated with C policy | `DECISION_OWNER_NOT_CAUSALLY_SEPARATED` |
| NC-C13 | Unlinked mutant accepted | `MUTANT_LINK_PROVENANCE_MISSING` |
| NC-C14 | Comparator ignores artifact type, exit, stdout or stderr | `SEMANTIC_COMPARATOR_INSENSITIVE` |
| NC-C15 | `NOT_REMEASURED` converted into fresh PASS | `BASELINE_NOT_REMEASURED_LAUNDERED` |
| NC-C16 | AC50 claimed before close | `PRECOMMITTED_EXTERNAL_SUCCESS` |
| NC-C17 | Historical receipt chronology invented | `HISTORICAL_TERMINALITY_LAUNDERED` |
| NC-C18 | Original acceptance predicate changed to obtain PASS | `FROZEN_CONTRACT_REWRITTEN` |

For every adverse control execute:

```text
PRISTINE  -> exit 0, silent
ADVERSE   -> nonzero, exact reason token
RESTORED  -> exit 0, silent
```

The restoration must be byte-identical.

Use isolated disposable inputs for adverse mutations.

A test that fails for the wrong reason does not pass.

A substring or prefix match that accepts a forged reason token does not
pass.

---

## 10. Required implementation

### 10.1 Correction verifier

Implement a compiled PolyC verifier under:

```text
tools/quality/
  driver-boundary-qualification01-correction01-verify.HC
```

It must be built using the actual production PolyC compiler.

The verifier must consume committed source-derived tables, not a
precomputed `PASS` field.

Required verification modes:

```text
ACSET
ACPHASE
ACPREDICATE
ACWITNESS
ACCOUNTING
ROUTES
DECISION
BASELINE
CHRONOLOGY
SELFTEST
```

If the existing verifier provides reusable logic, reuse its proven
design where possible without mutating the previous artifact.

Do not implement a general-purpose Factory framework.

### 10.2 Independent POSIX/Git witness

Implement an independent witness using the existing repository
toolchain.

Use:

```text
git
awk
sort
uniq
comm
cmp
shasum
standard shell utilities
```

No Python.

It must independently recompute the same critical facts without
sharing the compiled verifier's comparison algorithms.

The independent witness must validate:

```text
AC_IDENTITY
AC_PHASES
AC_PREDICATE_BINDING
AC_COUNTS
WITNESS_PATH_EXISTENCE
WITNESS_CHRONOLOGY
BRANCH_ROUTE_SCOPES
BASELINE_STATUS
```

Agreement must be measured per fact.

A matching overall PASS string is not sufficient.

### 10.3 Source and object provenance

For every new counterfactual:

```text
BASELINE_SOURCE_SHA
MUTANT_SOURCE_SHA
RESTORED_SOURCE_SHA

BASELINE_OBJECT_SHA
MUTANT_OBJECT_SHA

BASELINE_BINARY_SHA
MUTANT_BINARY_SHA

REAL_BUILD_COMMAND
REAL_LINK_EVIDENCE
```

A source mutation that was never linked into the executed binary is not
valid causal evidence.

Use the real CMake build and the actual production link route.

Protect the pristine stage0 compiler from the mutation.

Do not replace the working production compiler with the mutant.

### 10.4 Output artifacts

Create a new evidence tree:

```text
evidence/
  ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01/
    c0/
      entry-identity.tsv
      frozen-targets.tsv
      frozen-ac-contract.tsv
      frozen-negative-controls.tsv
      red-contract.md

    c1/
      red-execution-matrix.tsv
      frozen-ac-to-ledger-join.tsv
      predicate-drift.tsv
      witness-binding-audit.tsv
      historical-count-reconciliation.tsv
      source-branch-inventory.tsv
      route-and-decision-contract.tsv

    c2/
      verifier-build-and-selftest.tsv
      independent-witness.tsv
      branch-causal-executions.tsv
      branch-ownership-qualification.tsv
      detector-capability-matrix.tsv

    c3/
      acceptance-ledger.tsv
      negative-control-matrix.tsv
      independent-recomputation.tsv
      baseline-conservation.tsv
      gate-results.tsv
      final-qualification.tsv

    c4/
      close-summary.md
      terminality-plan.txt
```

These are required logical artifacts. A small number of additional
directly relevant files may be added inside this evidence tree.

Do not create unnecessary wrappers or generated reports.

---

## 11. Phase contract

### C0 — RED / AUTHORIZATION

Before implementation:

1. Establish entry HEAD/TREE and branch.
2. Read the actual Factory doctrine.
3. Freeze the predecessor file/object identities.
4. Write this ACT authorization document.
5. Freeze the new correction acceptance and negative-control rosters.
6. Create the bounded RED fixtures and commands.
7. Commit the authorization document and C0 frozen contract in the
   first ACT commit.

The ACT document must exist in the first ACT commit, not first appear at
C2 or C3.

The first phase commit must carry the correct Factory trailer
identifying C0 RED.

The RED fixtures must be specified before implementing the correction
verifier.

Execute the REDs using the existing vulnerable acceptance machinery and
capture their actual results at C1 before the fix.

If the principal REDs cannot be reproduced:

```text
HALT_RED_NOT_REPRODUCED
```

Do not implement the presumed defect.

### C1 — EVIDENCE

Execute the frozen REDs.

Recompute the 50-row contract comparison.

Perform the initial evidence-path audit.

Establish source-derived branch and route matrices.

Freeze the interpretation contract before writing the new verifier.

Required outcomes:

```text
AC_ID_CARDINALITY = 50
FROZEN_PHASE_DRIFT = MEASURED
FROZEN_PREDICATE_DRIFT = MEASURED
WITNESS_BINDING_ERRORS = MEASURED
ROUTE_SCOPE_CONFLICTS = MEASURED
```

Measurements may be zero if the alleged defect is not reproduced; report
that accurately.

Do not modify the original frozen inputs to manufacture RED results.

Commit C1 evidence.

### C2 — IMPL

Implement the correction verifier and independent witness.

Run all specified modes.

Perform linked C and PolyC counterfactuals where needed to qualify the
disputed semantic ownership.

Record the actual semantic outcome, including `UNPROVEN` where
appropriate.

Required:

```text
VERIFIER_BUILDS = PASS
VERIFIER_SELFTESTS = PASS
INDEPENDENT_WITNESS = PASS

AC_PREDICATE_COMPARISON = EXECUTED
AC_WITNESS_BINDING = EXECUTED

BRANCH_ROUTE_QUALIFICATION = EXECUTED
DECISION_OWNER_QUALIFICATION = EXECUTED
```

A verifier that only checks AC IDs and status strings is insufficient.

A verifier that accepts every historical PASS regardless of witness
relevance is insufficient.

Commit C2 implementation and evidence.

### C3 — EVIDENCE / GATES

Run the complete negative-control matrix.

Independently recompute all critical measurements.

Verify source restoration and production-byte conservation.

Run the canonical project gates, including:

```text
gate-fast
gate-push
append-only
closure-status
Factory v2 range validation
```

Use the exact canonical invocations discovered in the repository.

Do not invent a replacement test command.

Record subject HEAD and TREE for every gate result.

Keep gate execution serial where the existing doctrine requires it.

The phase must establish:

```text
NEGATIVE_CONTROLS = 18/18
INDEPENDENT_FACT_RECOMPUTATION = ALL_AGREE
PRODUCTION_SEMANTICS_CHANGED = NO
HISTORICAL_EVIDENCE_MODIFIED = NO
```

If a pre-existing non-green gate remains non-green, disclose it with its
exact identity. Do not convert it into a PASS.

If a required gate fails and cannot be corrected inside the authorized
scope:

```text
HALT_REQUIRED_GATE_FAILED
```

Commit C3 evidence.

### C4 — CLOSE

Produce the final handoff and an append-only ROADMAP correction entry.

Record:

```text
HISTORICAL_AUDIT_VERDICT
CURRENT_CORRECTION_VERDICT

HISTORICAL_AC_COUNTS
RECOMPUTED_AC_COUNTS

PREDICATE_DRIFT_COUNT
UNSUPPORTED_WITNESS_COUNT

HISTORICAL_RETAINED_C_ROWS
REQUALIFIED_REQUIRED_ROUTE_REMAINDER
REQUALIFIED_GLOBAL_REMAINDER

HISTORICAL_TERMINALITY_STATUS
CURRENT_CORRECTION_TERMINALITY_STATUS
```

The values must derive from executed evidence, not from the proposed
result.

Create exactly one terminal CLOSE commit for this ACT.

Its committed terminality artifact must be a PLAN, not a post-close
success assertion.

The close commit is the last commit carrying this ACT's ID.

After the close, execute an external read-only probe against the exact
CLOSE HEAD/TREE.

The receipt must live outside the repository.

If the outcome is recorded in Git, use an ordinary subsequent commit
with no ACT trailer and no false claim that it is part of the closed ACT
range.

Do not amend the close.

---

## 12. Acceptance criteria

Freeze these criteria at C0.

| ID | Required acceptance condition |
|---|---|
| AC01 | Entry HEAD/TREE, branch, ancestry and clean state established |
| AC02 | Predecessor close and post-close outcome identities verified |
| AC03 | All 50 frozen AC IDs recovered from exact Git objects |
| AC04 | Frozen AC phases and predicates preserved byte-for-byte |
| AC05 | Phase drift independently detected or disproven |
| AC06 | Predicate substitution independently detected or disproven |
| AC07 | All 50 ledger witnesses checked against frozen predicates |
| AC08 | Missing, irrelevant and chronologically invalid witnesses classified |
| AC09 | Criterion-only status totals independently computed |
| AC10 | `AC_ROSTER_SIZE` excluded from criterion status counts |
| AC11 | Handoff counts reconciled with actual ledger counts |
| AC12 | AC50 Q3 and external post-close observations distinguished |
| AC13 | Historical evidence and receipt provenance conserved |
| AC14 | Every decision-bearing `main()` branch in scope classified |
| AC15 | Every decision-bearing `emitFile()` branch in scope classified |
| AC16 | Required-route and whole-CLI branch reachability measured separately |
| AC17 | `emitFile()` counterfactual re-executed with real production build |
| AC18 | `main()` token counterfactual re-executed with real production build |
| AC19 | Actual required-route `main()` decision independently qualified |
| AC20 | PolyC decision influence and C action mapping distinguished |
| AC21 | C semantic policy not inferred solely from causal branch execution |
| AC22 | New route/global remainder counts derived from branch-level witnesses |
| AC23 | Historical 32-row counts preserved and crosswalk provided |
| AC24 | LEXER07 and known baseline statuses accurately conserved |
| AC25 | Q0 versus Q2 verifier capabilities independently compared |
| AC26 | Compiled PolyC correction verifier builds and passes selftests |
| AC27 | Independent POSIX/Git witness agrees on each required fact |
| AC28 | All 18 correction negative controls pass pristine/adverse/restored |
| AC29 | Source/object/binary restoration and production conservation proven |
| AC30 | Canonical gates and Factory checks pass or trigger accurate HALT |
| AC31 | Exactly one terminal CLOSE, with no precommitted post-close success |
| AC32 | External post-close probe binds to the exact CLOSE HEAD/TREE |

An acceptance criterion cannot be marked PASS merely because a
corresponding file exists.

The C3 acceptance ledger must include:

```text
ac_id
status
required_predicate
witness
measurement
producer_identity
reason
```

All 32 IDs must occur exactly once.

External AC32 must remain deferred until the external event has actually
occurred.

---

## 13. Verdict policy

The correction may close successfully without proving that the
historical migration succeeded.

Allowed outcomes:

### PASS_EVIDENCE_RECONCILED_WITH_REMAINDER

All required correction machinery operates correctly.

Every predecessor inconsistency is either resolved by valid evidence or
disclosed as a measured, bounded remainder.

No historical claim is silently promoted.

Any unresolved semantic ownership is explicitly `UNPROVEN`.

All required correction gates and controls pass.

### PASS_CORRECTED_QUALIFICATION

All correction evidence requirements pass, and the disputed route and
decision-owner classifications are fully qualified.

This still does not imply that PolyC owns the complete driver boundary.

### HALT

Use a precise reason, including:

```text
HALT_ENTRY_IDENTITY_OR_SCOPE_UNPROVEN
HALT_RED_NOT_REPRODUCED
HALT_FROZEN_CONTRACT_UNAVAILABLE
HALT_VERIFIER_NOT_INDEPENDENT
HALT_MUTANT_PROVENANCE_UNPROVEN
HALT_REQUIRED_ROUTE_UNQUALIFIABLE
HALT_EVIDENCE_INTEGRITY_FAILURE
HALT_REQUIRED_GATE_FAILED
HALT_FACTORY_CONTRACT_VIOLATION
```

If the required-route ownership cannot be established and the frozen
correction contract requires it, HALT rather than manufacturing a route
count.

Do not use an overall PASS as a substitute for an accurate
per-criterion ledger.

---

## 14. Historical invariants

Preserve these facts unless new, independently valid evidence
specifically contradicts the current interpretation:

```text
WP001_HISTORICAL_DRIVER_ROWS = 32

WP001_HISTORICAL_ACT_FAMILY_COST = 5

HISTORICAL_TRACKED_OUTCOME_PROVENANCE =
PRECOMMITTED_PROSPECTIVE_RESULT

HISTORICAL_ACT_TERMINALITY_CONFIRMED =
UNPROVEN
```

The fresh correction must not make an original historical event
retroactively provable.

The original audit's reported classification:

```text
9 PolyC-owned
12 C-mechanical
2 C-retained
9 dormant
```

must remain readable as the original classification.

New measurements must use separate correction-qualified fields.

Do not rewrite the historical status merely to simplify the ROADMAP.

The correction is additional governance work, not one of the original
five WP-001 driver-migration-family ACTs. Report the wider
qualification/correction effort separately when calculating total
project cost.

---

## 15. Conservation and terminality

Before CLOSE, establish:

```text
PRODUCTION_FILES_MODIFIED = 0
CANONICAL_GATES_MODIFIED = 0
HISTORICAL_EVIDENCE_MODIFIED = 0
HISTORY_REWRITTEN = NO
GIT_REPLACE_REFS = 0
UNRELATED_WORKTREE_CHANGES = 0
```

Verify the exact allowed-path changeset.

Verify:

```text
git diff --check
```

Run the canonical Factory validators.

The external terminality probe must independently verify:

```text
CLOSE_HEAD_EXISTS
CLOSE_TREE_MATCHES
EXACTLY_ONE_CLOSE
VALID_TRAILERS
NO_ACT_ID_CARRIER_AFTER_CLOSE
NO_GIT_REPLACE_REFS
CLEAN_WORKTREE
PRODUCTION_CONSERVATION
ACCEPTANCE_LEDGER_VALID
VERDICT_SUPPORTED
```

The external receipt must report the actual observation, not a
predicted value.

A failed post-close probe cannot be repaired by amending the CLOSE
commit.

Any subsequent correction requires a new forward-only authorization.

---

## 16. Required final handoff

Produce:

```text
docs/factory/
HANDOFF-ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01.md
```

The handoff must contain these sections:

```text
VERDICT

IDENTITY

FROZEN_CONTRACT_FINDINGS

ACCEPTANCE_RECONCILIATION

WITNESS_BINDING_FINDINGS

BRANCH_AND_ROUTE_FINDINGS

DECISION_OWNER_QUALIFICATION

BASELINE_CONSERVATION

NEGATIVE_CONTROLS

INDEPENDENT_RECOMPUTATION

GATES

SCOPE

HISTORICAL_PROVENANCE

RESIDUE

TERMINALITY

NEXT_ACT
```

Include exact commit IDs, trees, commands, results, artifact paths, and
reasons for every unresolved item.

Do not summarize 32 acceptance criteria as "all passed" without the
actual ledger.

### Final response format

Return:

```text
ACT:
ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01

VERDICT:
<actual verdict>

ENTRY_HEAD:
<sha>

TERMINAL_CLOSE:
<sha>

FINAL_HEAD:
<sha>

AC_RECONCILIATION:
<counts and unresolved criteria>

WITNESS_BINDING:
<valid/invalid/unproven counts>

REQUIRED_ROUTE_C_REMAINDER:
<measured value or UNPROVEN>

GLOBAL_C_REMAINDER:
<measured value or UNPROVEN>

DECISION_OWNER_QUALIFICATION:
<summary>

NEGATIVE_CONTROLS:
<actual result>

INDEPENDENT_RECOMPUTATION:
<actual result>

GATE_FAST:
<actual result>

GATE_PUSH:
<actual result>

APPEND_ONLY:
<actual result>

CLOSURE_STATUS:
<actual result>

EXTERNAL_TERMINALITY:
<actual result>

PRODUCTION_SEMANTICS_CHANGED:
NO

RESIDUE:
<exact unresolved items>

NEXT_ACT:
<authorized recommendation only>
```
