# ACT-POLYC-SELFHOST-SURFACE-RECON03

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Reconstruct the post-LEXER04 PolyC self-host boundary, mechanically rank remaining legacy compiler authority, and freeze exactly one next bounded production migration

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / SURFACE-RECON / SELECTION

**Priority:** P0

---

# 0. Mission

LEXER01 through LEXER04 have moved multiple compiler surfaces from legacy
C authority toward PolyC self-host authority.

The immediate purpose of this ACT is **not** to perform another migration.

It SHALL answer:

```text
What compiler semantics remain authoritative in legacy C now?

Which of those surfaces genuinely block further self-host progress?

Which remaining surface is small enough to migrate under one bounded ACT?

What is the exact next ACT and exact atomic slice?
```

This ACT SHALL:

1. inventory the live self-host boundary from the current repository;
2. classify every inventoried surface using one authoritative taxonomy;
3. identify all remaining `LEGACY_C_AUTHORITY` compiler surfaces;
4. mechanically determine which are eligible for a bounded next migration;
5. rank eligible candidates lexicographically using frozen criteria;
6. select exactly one rank-1 candidate;
7. identify its smallest useful atomic slice;
8. prove that the selected slice has a reproducible RED and a complete proof model;
9. freeze exactly one successor ACT ID and scope;
10. make **zero compiler semantic changes**.

Successful terminal state:

```text
SURFACE_INVENTORY_COMPLETE=YES
UNKNOWN_SURFACES=0

LIVE_SELFHOST_BOUNDARY_KNOWN=YES

ELIGIBLE_CANDIDATES>=1

UNIQUE_RANK1=YES

NEXT_ACT_ID=<one ACT>
NEXT_TARGET=<one surface>
NEXT_ATOMIC_SLICE=<one bounded slice>

NEXT_ACT_SCOPE_FROZEN=YES
NEXT_ACT_RED_MECHANICALLY_REPRODUCIBLE=YES
NEXT_ACT_PROOF_MODEL_COMPLETE=YES

PRODUCTION_SEMANTIC_DELTA=0

VERDICT=PASS_TRUE_GREEN
```

---

# 1. Entry lineage

Expected predecessor engineering state:

```text
LEXER01 = COMPLETE
LEXER02 = COMPLETE
LEXER03 = COMPLETE
LEXER04 = accepted for forward engineering work
```

LEXER04 historical correction/governance residue SHALL NOT be reopened here.

Historical proof-artifact cleanup is not a recon blocker unless live compiler
behavior itself is unknown.

Expected forward entry includes the LEXER04 production migration:

```text
BootstrapLinkDirective = production-authoritative
#link self-hosted path = live
```

At C0 bind actual HEAD mechanically.

Do not hardcode a stale SHA into the contract.

---

# 2. C0 entry gate

Run:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
```

Required:

```text
BRANCH=main
WORKTREE_CLEAN_AT_C0=YES
```

Freeze:

```text
ENTRY_HEAD=<actual clean HEAD>
PATCH_HYGIENE_BASELINE=<ENTRY_HEAD>
```

If dirty:

```text
HALT_ENTRY_DIRTY
```

Do not auto-clean unrelated work.

---

# 3. Complete authorization before recon

C0 SHALL commit this ACT before C1 inventory work.

C0 artifacts:

```text
docs/acts/ACT-POLYC-SELFHOST-SURFACE-RECON03.md

evidence/ACT-POLYC-SELFHOST-SURFACE-RECON03/c0/
  c0-entry-identity.txt
  c0-scope.txt
  c0-predecessor-state.txt
```

Required:

```text
C0_AUTH_BEFORE_RECON=YES
```

---

# 4. Non-goals

This ACT SHALL NOT:

```text
modify compiler semantics
migrate any compiler surface
modify lexer/parser/preprocessor behavior
fix LEXER07 historical broad-corpus failures
fix AArch64 inline-asm parsing
modify libtos semantics
modify JIT semantics
change ABI
add a new self-host bridge
select multiple next ACTs
start the selected ACT
```

This is:

```text
observe
classify
rank
select
freeze
```

only.

---

# 5. Production mutation prohibition

The following are read-only:

```text
src/**
tools/bootstrap/**
src/holyc-lib/**
```

except read-only generated build artifacts outside tracked source.

Required:

```text
PRODUCTION_SOURCE_DELTA=0
COMPILER_SEMANTIC_DELTA=0
```

If recon appears to require production changes:

```text
HALT_RECON_REQUIRES_IMPLEMENTATION
```

---

# 6. Inventory universe

C1 SHALL inventory all live surfaces relevant to compiler self-host
authority.

Do not merely copy SURFACE-RECON02's old table.

Recompute from the current tree.

At minimum scan:

```text
src/lexer.c
src/lexer.h
src/parser.c
src/parser.h

src/*preproc*
src/*pp*

src/ir*
src/ssa*
src/codegen*
src/x86*
src/x86_64*
src/aarch64*

src/jit*
src/link*
src/repl*

tools/bootstrap/**

Makefile
src/CMakeLists.txt
```

Also mechanically search for:

```text
HCC_USE_SELFHOST_COMPONENTS
Bootstrap*
selfhost
legacy
#ifdef / #if gates selecting migrated components
```

---

# 7. Surface granularity

An inventory surface is a **semantic authority region**, not necessarily a
file.

Examples:

```text
lexer numeric literal scanning
lexer trivia scanning
lexer #link handling
lexer #include handling
preprocessor conditional directive handling
parser top-level declaration handling
parser compound statement handling
type parsing
declaration parsing
expression parsing
```

Do not collapse all of `parser.c` into one row if separately bounded
semantic authorities can be identified.

Do not split individual helper functions so finely that ranking becomes
meaningless.

Granularity rule:

> one row = one independently migratable semantic authority or one
> explicitly non-migratable support surface.

---

# 8. Surface identity

Every surface receives a stable ID:

```text
INV.<REGION>.<SURFACE>
```

Examples:

```text
INV.LEXER.NUMERIC
INV.LEXER.TRIVIA
INV.LEXER.LINK
INV.LEXER.INCLUDE

INV.PREPROC.PP

INV.PARSER.TOPLEVEL
INV.PARSER.COMPOUND
INV.PARSER.EXPR
```

Reuse prior IDs where the semantic region is unchanged.

Do not renumber for cosmetic reasons.

---

# 9. Authoritative classification taxonomy

Exactly one primary classification per inventory row:

```text
SELFHOSTED_TRUE_GREEN

SELFHOSTED_ENGINEERING_GREEN_WITH_RESIDUE

LEGACY_C_AUTHORITY

LEGACY_NON_POLYC_AUTHORITY

BUILD_ORCHESTRATION

QUALITY_TOOLING

RUNTIME_LIBRARY

BACKEND_TARGET_SPECIFIC

DEAD_OR_NONRUNTIME

EXPERIMENTAL_NONAUTHORITATIVE

UNKNOWN
```

Required:

```text
UNKNOWN=0
```

---

# 10. Meaning of SELFHOSTED_TRUE_GREEN

Use only when all are true:

```text
PolyC implementation exists
production path actually consumes it
legacy duplicate semantics are retired or non-authoritative
bounded differential/proof exists
current behavior remains enabled in live build
```

Do not classify a shadow verifier as self-hosted.

---

# 11. Meaning of SELFHOSTED_ENGINEERING_GREEN_WITH_RESIDUE

Use when:

```text
PolyC owns live production semantics
but proof/governance residue remains
```

This allows recon to move forward without pretending historical artifact
governance is perfect.

LEXER04 may land here rather than `SELFHOSTED_TRUE_GREEN` if that best
represents the live tree.

The classification decision must be justified mechanically.

---

# 12. Meaning of LEGACY_C_AUTHORITY

Use when:

```text
semantic behavior still originates in C
AND
the behavior participates in the live compiler path
AND
it matters to compilation/self-host progression
```

This is the primary candidate class for the next migration.

---

# 13. Non-candidate classes

These are not next migration candidates merely because they contain C:

```text
RUNTIME_LIBRARY
BUILD_ORCHESTRATION
QUALITY_TOOLING
DEAD_OR_NONRUNTIME
EXPERIMENTAL_NONAUTHORITATIVE
```

`BACKEND_TARGET_SPECIFIC` may be eligible only if recon proves it blocks
the next self-host stage rather than merely one host/target combination.

---

# 14. Inventory schema

Create:

```text
evidence/ACT-POLYC-SELFHOST-SURFACE-RECON03/c1/
  c1-surface-inventory.tsv
```

Columns:

```text
surface_id
region
description
primary_source
entry_symbol
classification
production_reachable
semantic_authority
polyC_component
bridge_symbol
legacy_duplicate
current_test_surface
current_proof_surface
blocks_next_selfhost_stage
atomic_slice_available
estimated_source_span
dependency_count
coupling_count
existing_oracle
existing_fixture_set
known_residue
notes
```

No prose-only inventory.

---

# 15. Inventory completeness controls

Mechanically generate supporting inventories.

At minimum:

```text
c1-bootstrap-components.tsv
c1-selfhost-call-sites.tsv
c1-legacy-compiler-functions.tsv
c1-parser-authority-regions.tsv
c1-lexer-authority-regions.tsv
c1-preprocessor-authority-regions.tsv
c1-build-selection-seams.tsv
```

Cross-check counts.

Required:

```text
UNMAPPED_SELFHOST_COMPONENTS=0
UNMAPPED_SELFHOST_CALLS=0
UNCLASSIFIED_LIVE_AUTHORITY=0
```

---

# 16. Known migrated controls

At minimum verify current migrated controls corresponding to prior work.

Expected examples include:

```text
LEXER01 migrated component
LEXER02 scalar literal component
LEXER03 trivia component
LEXER04 BootstrapLinkDirective
```

Do not assume all deserve `SELFHOSTED_TRUE_GREEN`.

Classify using current live truth.

Required:

```text
KNOWN_MIGRATED_CONTROL_CLASSIFIED_NON_LEGACY=YES
```

---

# 17. Known residue control

At least one known still-legacy compiler surface must classify as:

```text
LEGACY_C_AUTHORITY
```

Historically likely candidates included:

```text
INV.PARSER.TOPLEVEL
INV.PARSER.COMPOUND
```

but C1 must verify live state.

Required:

```text
KNOWN_LEGACY_CONTROL_CLASSIFIED_LEGACY=YES
```

---

# 18. Dead/nonruntime negative control

Mechanically select at least one compiler-adjacent but non-blocking
surface, for example:

```text
transpiler-only
LSP-only
debug/disassembler-only
dead helper
experimental path
```

Required:

```text
NONRUNTIME_CONTROL_EXCLUDED_FROM_CANDIDATES=YES
```

---

# 19. Recompute current counts

C1 required summary:

```text
SURFACE_TOTAL=<n>

SELFHOSTED_TRUE_GREEN=<n>
SELFHOSTED_ENGINEERING_GREEN_WITH_RESIDUE=<n>
LEGACY_C_AUTHORITY=<n>
LEGACY_NON_POLYC_AUTHORITY=<n>
BUILD_ORCHESTRATION=<n>
QUALITY_TOOLING=<n>
RUNTIME_LIBRARY=<n>
BACKEND_TARGET_SPECIFIC=<n>
DEAD_OR_NONRUNTIME=<n>
EXPERIMENTAL_NONAUTHORITATIVE=<n>
UNKNOWN=0
```

Do not preserve SURFACE-RECON02's historical `26` count unless current
mechanical inventory still yields exactly 26.

---

# 20. Diff against SURFACE-RECON02

C1 SHALL compare current inventory to SURFACE-RECON02.

Produce:

```text
c1-inventory-delta.tsv
```

Rows:

```text
surface_id
recon02_classification
recon03_classification
delta_reason
expected
```

At minimum, the `INV.LEXER.LINK` state should reflect LEXER04's migration.

Required:

```text
INVENTORY_DELTA_EXPLAINED=YES
UNEXPLAINED_CLASSIFICATION_CHANGES=0
```

---

# 21. Candidate eligibility predicate

A candidate is eligible only if all are true:

```text
classification == LEGACY_C_AUTHORITY

production_reachable == YES

semantic_authority == YES

blocks_next_selfhost_stage == YES
  OR
meaningful_selfhost_leverage >= threshold

atomic_slice_available == YES

bounded_RED_possible == YES

bounded_oracle_or_differential_possible == YES

dependency_count <= bounded threshold

does_not_require_unrelated_architecture_rewrite == YES
```

Produce:

```text
c2-eligibility.tsv
```

with one boolean column per predicate.

---

# 22. Explicit ineligibility reasons

Allowed reasons include:

```text
NOT_PRODUCTION_AUTHORITY
DOES_NOT_BLOCK_SELFHOST
NO_ATOMIC_SLICE
NO_BOUNDED_ORACLE
REQUIRES_MULTI_REGION_REWRITE
BACKEND_ONLY
RUNTIME_NOT_COMPILER
EXPERIMENTAL
DEAD
ALREADY_SELFHOSTED
```

Every rejected legacy surface receives at least one reason.

---

# 23. No candidate by numbering

Forbidden selection logic:

```text
LEXER04 is done therefore choose LEXER05
```

Also forbidden:

```text
parser is next because lexer is finished
```

Selection is based only on eligibility + ranking.

---

# 24. Ranking universe

Only eligible candidates enter ranking.

Expected but not guaranteed candidates may include:

```text
lexer/include-related residue
preprocessor directive surface
parser top-level
parser compound
parser expression/type slice
```

C2 binds actual candidates.

---

# 25. Ranking model

Rank lexicographically by R1..R6.

Higher-priority criterion wins before lower criteria are considered.

## R1 — self-host stage leverage

Enum:

```text
BLOCKS_NEXT_SELFHOST_STAGE = 0
UNLOCKS_MULTIPLE_FOLLOWING_SURFACES = 1
UNLOCKS_ONE_FOLLOWING_SURFACE = 2
USEFUL_BUT_NONBLOCKING = 3
```

Lowest numeric value ranks first.

---

# 26. R2 — atomicity

```text
SINGLE_FUNCTION_OR_TIGHT_COMPONENT = 0
SMALL_COHESIVE_REGION = 1
MULTI_FUNCTION_COUPLED_REGION = 2
CROSS_FILE_REGION = 3
```

Prefer smaller atomic authority.

---

# 27. R3 — oracle strength

```text
EXISTING_PRODUCTION_DIFFERENTIAL = 0
EXISTING_DIRECT_ORACLE = 1
EASY_BOUNDED_ORACLE = 2
METAMORPHIC_ONLY = 3
WEAK_OR_NO_ORACLE = 4
```

---

# 28. R4 — dependency/coupling cost

Compute mechanical count from:

```text
direct helper dependencies
shared mutable compiler state
external semantic regions touched
```

Lower count ranks first.

---

# 29. R5 — proof cost

Score:

```text
1  small fixture matrix + simple differential
2  bounded component + production seam
3  multi-stage fixedpoint + production seam
4  parser/tree comparison
5  large cross-region semantic proof
```

Lower first.

---

# 30. R6 — estimated implementation span

Use source-span estimate from C1.

Lower LOC/span first.

This is only the final tie-breaker.

Never let "smallest LOC" outrank self-host leverage.

---

# 31. Ranking table

Produce:

```text
c2-ranked-candidates.tsv
```

Columns:

```text
rank
surface_id
atomic_slice
R1
R2
R3
R4
R5
R6
selection_state
rationale
```

Required:

```text
RANKED_CANDIDATE_COUNT>=1
SELECTED_COUNT=1
```

---

# 32. Ranking recomputation

Implement ranking either:

```text
in PolyC quality tooling
```

or as mechanically recomputable tabular/sort logic using already-approved
Factory machinery.

No substantive new shell >50 LOC.

C3 SHALL independently recompute ranking from the C1/C2 source tables.

Required:

```text
RANKING_RECOMPUTED=YES
RECOMPUTED_RANK1=<surface>
SELECTED_TARGET_MATCHES_RECOMPUTED_RANK1=YES
```

---

# 33. Tie handling

If two candidates tie on R1..R6:

```text
HALT_RANKING_TIE
```

Do not break ties by preference.

A future contract may add R7 explicitly.

---

# 34. Atomic-slice selection

After selecting one surface, identify the smallest useful semantic slice.

Required properties:

```text
one bounded authority
one explicit entry symbol or region
one describable ABI
one fixture universe
one expected production seam
```

Produce:

```text
c2-selected-atomic-slice.txt
```

---

# 35. Example of valid slice

A valid slice resembles:

```text
surface:
  INV.LEXER.LINK

atomic slice:
  lexLink #link directive handler
```

rather than:

```text
surface:
  parser

atomic slice:
  rewrite parser
```

For parser candidates, find a concrete semantic slice.

Examples might include:

```text
top-level declaration dispatch
compound statement dispatch
specific declaration parser
specific postfix/expression tier
```

but live C2 recon decides.

---

# 36. Selected surface dependency closure

Produce:

```text
c2-selected-dependencies.tsv
```

Columns:

```text
dependency
kind
already_selfhosted
legacy
must_migrate_with_slice
can_bridge
out_of_scope
```

Required:

```text
UNBOUNDED_REQUIRED_DEPENDENCY=0
```

Otherwise:

```text
HALT_SELECTED_SLICE_NOT_BOUNDED
```

and selection must not silently move to rank 2.

The ranking contract itself would need reconsideration.

---

# 37. RED model

The selected next slice must have at least one pre-implementation RED that
can be mechanically reproduced.

Examples:

```text
PolyC implementation absent
production bridge absent
differential target unavailable
legacy function remains sole authority
```

Produce:

```text
c2-next-act-red.txt
```

Required:

```text
RED_COMMAND_COUNT>=2
RED_REPRODUCIBLE=YES
```

Prefer three independent REDs where practical.

---

# 38. Proof model completeness

For the selected next slice classify every proof class:

```text
DIRECT_DIFFERENTIAL
PRODUCTION_SEAM
FIXEDPOINT
NEGATIVE_CONTROL
CONSERVATION
PROVENANCE
PATCH_HYGIENE
```

State:

```text
REQUIRED
NOT_REQUIRED
```

with rationale.

Produce:

```text
c2-next-proof-model.tsv
```

Required:

```text
UNCLASSIFIED_PROOF_CLASSES=0
```

---

# 39. Production-seam feasibility

If selected target changes production semantics:

```text
PRODUCTION_SEAM=REQUIRED
```

C2 SHALL identify:

```text
legacy control
migrated path
observable stable fields
fixture corpus
normalization rules
```

If no meaningful production seam can be defined:

```text
HALT_SELECTED_SLICE_NO_PRODUCTION_SEAM
```

unless the surface is provably compile-time-only and another stronger
oracle exists.

---

# 40. Differential feasibility

If a pure functional/component oracle is available, define:

```text
input
legacy result
future PolyC result
comparison function
```

Freeze fixture classes.

Do not implement the future component.

---

# 41. Fixedpoint requirement rule

`FIXEDPOINT=REQUIRED` only if the new component will itself be compiled by
successive bootstrap generations and object fixedpoint materially proves
self-host stability.

Do not mechanically demand fixedpoint for every future migration merely
because LEXER02–04 used it.

---

# 42. Negative control design

The successor scope SHALL include at least one mutation/control that would
fail if the migrated component were:

```text
shadow-only
unused
incorrectly wired
or the verifier were non-load-bearing
```

Freeze the control class now.

Required:

```text
NEXT_NEGATIVE_CONTROL_DEFINED=YES
```

---

# 43. Conservation model

Every successor ACT must conserve currently accepted earlier migrations.

At minimum successor scope SHALL plan:

```text
LEXER01 conservation
LEXER02 conservation
LEXER03 conservation
LEXER04 conservation
```

Use targeted/baseline-delta semantics where historical global failures
exist.

Do not require a known-failing global historical gate to magically become
green.

---

# 44. LEXER07 historical regression baseline

C1 SHALL measure the live broad-corpus baseline.

Freeze:

```text
LEXER07_ENTRY_REGRESSION=<actual>
LEXER07_ENTRY_FAILURE_SET=<actual>
```

This is recon context, not a blocker if unchanged.

Required successor conservation:

```text
NEW_LEXER07_FAILURES=0
```

---

# 45. Independent AArch64 residue

Inventory:

```text
ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01
```

as separate residue if still live.

Do not let it rank as the next self-host migration unless recon proves:

```text
blocks_next_selfhost_stage=YES
```

for the selected migration on the current host/build path.

---

# 46. Tooling doctrine

Any new substantive recon/ranking tool SHALL be PolyC.

Required:

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

Shell:

```text
<=50 LOC
dispatch only
```

---

# 47. F-NO-PYTHON

Required:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

---

# 48. F14

Do not modify closed evidence/HANDOFFs of earlier ACTs.

Required:

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

All recon evidence belongs under:

```text
evidence/ACT-POLYC-SELFHOST-SURFACE-RECON03/
```

---

# 49. Patch hygiene

Binding range:

```text
ENTRY_HEAD..HEAD
```

Every phase:

```sh
git diff --check "$ENTRY_HEAD"..HEAD
```

Required:

```text
PATCH_HYGIENE_ERRORS=0
```

No exclusions.

---

# 50. C1 phase — INVENTORY

C1 produces only recon evidence.

Expected evidence:

```text
evidence/ACT-POLYC-SELFHOST-SURFACE-RECON03/c1/

c1-entry-identity.txt
c1-surface-inventory.tsv
c1-bootstrap-components.tsv
c1-selfhost-call-sites.tsv
c1-legacy-compiler-functions.tsv
c1-parser-authority-regions.tsv
c1-lexer-authority-regions.tsv
c1-preprocessor-authority-regions.tsv
c1-build-selection-seams.tsv
c1-inventory-delta.tsv
c1-classification-summary.txt
c1-broad-corpus-baseline.txt
c1-controls.txt
c1-required-result.txt
```

No ranking selection yet.

---

# 51. C1 required result

```text
ACT=ACT-POLYC-SELFHOST-SURFACE-RECON03

SURFACE_TOTAL=<n>

SELFHOSTED_TRUE_GREEN=<n>
SELFHOSTED_ENGINEERING_GREEN_WITH_RESIDUE=<n>
LEGACY_C_AUTHORITY=<n>
LEGACY_NON_POLYC_AUTHORITY=<n>
BUILD_ORCHESTRATION=<n>
QUALITY_TOOLING=<n>
RUNTIME_LIBRARY=<n>
BACKEND_TARGET_SPECIFIC=<n>
DEAD_OR_NONRUNTIME=<n>
EXPERIMENTAL_NONAUTHORITATIVE=<n>
UNKNOWN=0

UNMAPPED_SELFHOST_COMPONENTS=0
UNMAPPED_SELFHOST_CALLS=0
UNCLASSIFIED_LIVE_AUTHORITY=0

KNOWN_MIGRATED_CONTROL_CLASSIFIED_NON_LEGACY=YES
KNOWN_LEGACY_CONTROL_CLASSIFIED_LEGACY=YES
NONRUNTIME_CONTROL_EXCLUDED_FROM_CANDIDATES=YES

INVENTORY_DELTA_EXPLAINED=YES
UNEXPLAINED_CLASSIFICATION_CHANGES=0

PRODUCTION_SOURCE_DELTA=0
```

If `UNKNOWN>0`:

```text
HALT_INVENTORY_UNKNOWN
```

---

# 52. C2 phase — RANK / SELECT

C2 may add only:

```text
ranking/selection evidence
PolyC ranking verifier/tool if needed
next-ACT contract evidence
```

Still no production mutation.

C2 produces:

```text
evidence/.../c2/

c2-eligibility.tsv
c2-ranked-candidates.tsv
c2-ranking-input-sha.txt

c2-selected-surface.txt
c2-selected-atomic-slice.txt
c2-selected-dependencies.tsv

c2-next-act-red.txt
c2-next-proof-model.tsv
c2-next-fixture-plan.tsv
c2-next-negative-control.txt
c2-next-conservation-plan.tsv

c2-next-act-scope.txt
c2-required-result.txt
```

---

# 53. Next ACT ID

The ID is derived from selected region.

Examples only:

```text
lexer successor:
  ACT-POLYC-SELFHOST-LEXER05

parser slice:
  ACT-POLYC-SELFHOST-PARSER01

preprocessor slice:
  ACT-POLYC-SELFHOST-PREPROC01

compiler infrastructure:
  ACT-POLYC-SELFHOST-<REGION>01
```

Do not force `LEXER05` if the selected surface is parser/preprocessor.

---

# 54. Frozen successor scope

`c2-next-act-scope.txt` SHALL contain:

```text
NEXT_ACT_ID
NEXT_TARGET_SURFACE_ID
NEXT_TARGET_DESCRIPTION
NEXT_ATOMIC_SLICE

ALLOWED_PRODUCTION_FILES
ALLOWED_BOOTSTRAP_FILES
ALLOWED_QUALITY_FILES

FORBIDDEN_SURFACES

EXPECTED_BRIDGE_OR_ABI

RED_COMMANDS

FIXTURE_CLASSES

PROOF_MODEL

NEGATIVE_CONTROL

CONSERVATION_REQUIREMENTS

KNOWN_RESIDUE_NOT_IN_SCOPE
```

Required:

```text
NEXT_ACT_SCOPE_FROZEN=YES
```

---

# 55. No implementation leakage

C2 SHALL NOT create:

```text
future production .HC component
future bridge implementation
future C delegation
future semantic fixtures that already encode implementation result
```

Recon may identify locations and fixture classes, not implement the next
ACT.

Required:

```text
SUCCESSOR_IMPLEMENTATION_DELTA=0
```

---

# 56. C2 required result

```text
ELIGIBLE_CANDIDATE_COUNT=<n>=1+

RANKED_CANDIDATE_COUNT=<same n>

SELECTED_COUNT=1

SELECTED_SURFACE=<id>
SELECTED_ATOMIC_SLICE=<slice>

UNIQUE_RANK1=YES

UNBOUNDED_REQUIRED_DEPENDENCY=0

RED_REPRODUCIBLE=YES
RED_COMMAND_COUNT>=2

UNCLASSIFIED_PROOF_CLASSES=0
NEXT_NEGATIVE_CONTROL_DEFINED=YES

NEXT_ACT_ID=<id>
NEXT_ACT_SCOPE_FROZEN=YES

SUCCESSOR_IMPLEMENTATION_DELTA=0
PRODUCTION_SOURCE_DELTA=0
```

---

# 57. C3 phase — VERIFY

C3 is verification only.

No C1/C2 table mutation after C2 commit.

C3 independently recomputes:

```text
inventory counts
candidate eligibility
candidate ranking
rank 1
selected atomic slice consistency
next ACT ID consistency
scope hash
```

Also rerun controls and conservation.

If C3 requires changing ranking inputs or selection:

```text
HALT_C2_SELECTION_DEFECT
```

Do not patch and continue.

---

# 58. C3 immutable inputs

At C2 freeze SHA-256:

```text
c1-surface-inventory.tsv
c2-eligibility.tsv
c2-ranked-candidates.tsv
c2-next-act-scope.txt
ranking tool/source if any
ACT body
```

C3 verifies identical hashes.

Required:

```text
C2_TO_C3_SELECTION_INPUTS_FROZEN=YES
```

---

# 59. C3 ranking recomputation

Required:

```text
RANKING_RECOMPUTED=YES
RECOMPUTED_ELIGIBLE_COUNT=<n>
RECOMPUTED_RANK1=<id>
SELECTED_TARGET_MATCHES_RECOMPUTED_RANK1=YES
```

---

# 60. C3 falsification controls

At minimum:

## Control A — known self-hosted

Inject/recompute a known migrated surface.

Expected:

```text
ELIGIBLE=NO
reason=ALREADY_SELFHOSTED
```

## Control B — known dead/nonruntime

Expected:

```text
ELIGIBLE=NO
```

## Control C — ranking perturbation

On a temporary copy only, worsen selected candidate R1 or improve another
candidate's R1.

Required:

```text
RANKING_RESPONDS_TO_PERTURBATION=YES
```

This proves rank-1 isn't hardcoded.

## Control D — eligibility removal

Make selected candidate temporarily fail one eligibility predicate.

Expected:

```text
SELECTED_REMOVED_FROM_RANKING=YES
```

---

# 61. C3 successor RED validation

Execute the frozen RED commands against the current unmodified tree.

Required:

```text
NEXT_ACT_RED_IS_MECHANICALLY_REPRODUCIBLE=YES
```

No implementation.

The RED should fail for the reason the successor ACT expects.

---

# 62. C3 proof-model validation

Verify every proof class has:

```text
classification
planned command/target
planned evidence artifact
falsification method if REQUIRED
```

Required:

```text
NEXT_ACT_PROOF_MODEL_COMPLETE=YES
```

---

# 63. Conservation gates

Run current canonical checks sufficient to establish recon introduced no
semantic change.

At minimum:

```text
LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS
```

LEXER04 conservation should exercise the current production-authority path,
not merely component compilation.

---

# 64. Factory gates

Run:

```text
make gate-fast
bash scripts/quality/factory-append-only-test.sh
```

Required:

```text
GATE_FAST=PASS
APPEND_ONLY_FAIL=0
```

Run relevant current Factory selftests as available.

---

# 65. C3 scope verification

Required:

```text
PRODUCTION_SOURCE_DELTA=0
COMPILER_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

PATCH_HYGIENE_ERRORS=0
```

---

# 66. C3 evidence

```text
evidence/.../c3/

c3-entry-identity.txt
c3-freeze-replay.tsv

c3-inventory-recompute.txt
c3-eligibility-recompute.tsv
c3-ranking-recompute.tsv

c3-known-selfhost-control.txt
c3-nonruntime-control.txt
c3-ranking-perturbation-control.txt
c3-eligibility-removal-control.txt

c3-next-red-reproduction.txt
c3-next-proof-model-verify.txt
c3-next-scope-verify.txt

c3-lexer01-conservation.txt
c3-lexer02-conservation.txt
c3-lexer03-conservation.txt
c3-lexer04-conservation.txt

c3-factory-gates.txt
c3-append-only.txt

c3-f-polyc-tools.txt
c3-f-no-python.txt
c3-f14.txt
c3-patch-hygiene.txt
c3-phase-purity.txt

mandatory-ac-status.tsv
c3-required-result.txt
```

---

# 67. C3 required result

```text
ACT=ACT-POLYC-SELFHOST-SURFACE-RECON03

SURFACE_INVENTORY_COMPLETE=YES
UNKNOWN=0

ELIGIBLE_CANDIDATE_COUNT=<n>

RANKING_RECOMPUTED=YES
UNIQUE_RANK1=YES

SELECTED_SURFACE=<id>
SELECTED_ATOMIC_SLICE=<slice>

SELECTED_TARGET_MATCHES_RECOMPUTED_RANK1=YES

NEXT_ACT_ID=<id>
NEXT_ACT_SCOPE_FROZEN=YES

NEXT_ACT_RED_IS_MECHANICALLY_REPRODUCIBLE=YES
NEXT_ACT_PROOF_MODEL_COMPLETE=YES
NEXT_NEGATIVE_CONTROL_DEFINED=YES

RANKING_RESPONDS_TO_PERTURBATION=YES
SELECTED_REMOVED_FROM_RANKING=YES

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS

PRODUCTION_SOURCE_DELTA=0
COMPILER_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

C2_TO_C3_SELECTION_INPUTS_FROZEN=YES
C3_PHASE_PURITY=PASS
```

---

# 68. Acceptance criteria

## AC01

```text
C0_AUTH_BEFORE_RECON=YES
```

## AC02

```text
WORKTREE_CLEAN_AT_C0=YES
```

## AC03

```text
SURFACE_INVENTORY_COMPLETE=YES
```

## AC04

```text
UNKNOWN=0
```

## AC05

```text
UNMAPPED_SELFHOST_COMPONENTS=0
```

## AC06

```text
UNMAPPED_SELFHOST_CALLS=0
```

## AC07

```text
UNCLASSIFIED_LIVE_AUTHORITY=0
```

## AC08

```text
KNOWN_MIGRATED_CONTROL_CLASSIFIED_NON_LEGACY=YES
```

## AC09

```text
KNOWN_LEGACY_CONTROL_CLASSIFIED_LEGACY=YES
```

## AC10

```text
NONRUNTIME_CONTROL_EXCLUDED_FROM_CANDIDATES=YES
```

## AC11

```text
INVENTORY_DELTA_EXPLAINED=YES
```

## AC12

```text
UNEXPLAINED_CLASSIFICATION_CHANGES=0
```

## AC13

```text
ELIGIBLE_CANDIDATE_COUNT>=1
```

## AC14

```text
RANKED_CANDIDATE_COUNT=ELIGIBLE_CANDIDATE_COUNT
```

## AC15

```text
SELECTED_COUNT=1
```

## AC16

```text
UNIQUE_RANK1=YES
```

## AC17

```text
SELECTED_TARGET_MATCHES_RECOMPUTED_RANK1=YES
```

## AC18

```text
RANKING_RESPONDS_TO_PERTURBATION=YES
```

## AC19

```text
SELECTED_REMOVED_FROM_RANKING=YES
```

## AC20

```text
UNBOUNDED_REQUIRED_DEPENDENCY=0
```

## AC21

```text
RED_REPRODUCIBLE=YES
```

## AC22

```text
RED_COMMAND_COUNT>=2
```

## AC23

```text
UNCLASSIFIED_PROOF_CLASSES=0
```

## AC24

```text
NEXT_NEGATIVE_CONTROL_DEFINED=YES
```

## AC25

```text
NEXT_ACT_SCOPE_FROZEN=YES
```

## AC26

```text
NEXT_ACT_RED_IS_MECHANICALLY_REPRODUCIBLE=YES
```

## AC27

```text
NEXT_ACT_PROOF_MODEL_COMPLETE=YES
```

## AC28

```text
LEXER01_CONSERVATION=PASS
```

## AC29

```text
LEXER02_CONSERVATION=PASS
```

## AC30

```text
LEXER03_CONSERVATION=PASS
```

## AC31

```text
LEXER04_CONSERVATION=PASS
```

## AC32

```text
NEW_LEXER07_FAILURES=0
```

## AC33

```text
PRODUCTION_SOURCE_DELTA=0
```

## AC34

```text
COMPILER_SEMANTIC_DELTA=0
```

## AC35

```text
SUCCESSOR_IMPLEMENTATION_DELTA=0
```

## AC36

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

## AC37

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

## AC38

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

## AC39

```text
GATE_FAST=PASS
```

## AC40

```text
APPEND_ONLY_FAIL=0
```

## AC41

```text
PATCH_HYGIENE_ERRORS=0
```

## AC42

```text
C2_TO_C3_SELECTION_INPUTS_FROZEN=YES
```

## AC43

```text
C3_PHASE_PURITY=PASS
```

## AC44

```text
WORKTREE_CLEAN_AT_CLOSE=YES
```

All AC01..AC44 are mandatory.

---

# 69. C4 preparation

Before C4:

```sh
git status --short
git diff --check "$ENTRY_HEAD"..HEAD
```

Required:

```text
C4_PREP_WORKTREE_CLEAN=YES
C4_PREP_PATCH_HYGIENE_ERRORS=0
```

If not:

```text
HALT_C4_PRECONDITION
```

No cleanup commit later.

---

# 70. C4 scope

C4 may add only:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-SURFACE-RECON03.md

evidence/ACT-POLYC-SELFHOST-SURFACE-RECON03/c4/
  c4-parent-identity.txt
  c4-terminal-ledger.txt

docs/ROADMAP.md
```

ROADMAP may receive only additive recon/selection state.

No C1/C2/C3 evidence edits.

No production changes.

---

# 71. C4 HANDOFF required sections

```text
VERDICT
IDENTITY
MISSION
INVENTORY
CLASSIFICATION COUNTS
INVENTORY DELTA SINCE RECON02
ELIGIBILITY
RANKING
SELECTED TARGET
ATOMIC SLICE
DEPENDENCIES
RED MODEL
PROOF MODEL
NEGATIVE CONTROL
CONSERVATION
FACTORY GATES
SCOPE
RESIDUE
NEXT ACT
```

---

# 72. Terminal verdict

`PASS_TRUE_GREEN` requires:

```text
AC_TOTAL=44
AC_PASS=44
AC_FAIL=0

SURFACE_INVENTORY_COMPLETE=YES
UNKNOWN=0

ELIGIBLE_CANDIDATE_COUNT>=1

UNIQUE_RANK1=YES
SELECTED_COUNT=1

RANKING_RECOMPUTED=YES
SELECTED_TARGET_MATCHES_RECOMPUTED_RANK1=YES

RANKING_RESPONDS_TO_PERTURBATION=YES
SELECTED_REMOVED_FROM_RANKING=YES

UNBOUNDED_REQUIRED_DEPENDENCY=0

NEXT_ACT_SCOPE_FROZEN=YES
NEXT_ACT_RED_IS_MECHANICALLY_REPRODUCIBLE=YES
NEXT_ACT_PROOF_MODEL_COMPLETE=YES

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS

PRODUCTION_SOURCE_DELTA=0
COMPILER_SEMANTIC_DELTA=0
SUCCESSOR_IMPLEMENTATION_DELTA=0

F_POLYC_TOOLS=PASS
F_NO_PYTHON=PASS
F14=PASS

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

WORKTREE_CLEAN_AT_CLOSE=YES
```

Anything weaker:

```text
HALT
```

---

# 73. HALT taxonomy

```text
HALT_ENTRY_DIRTY
HALT_AUTHORIZATION_MISSING

HALT_INVENTORY_UNKNOWN
HALT_UNMAPPED_SELFHOST_COMPONENT
HALT_UNCLASSIFIED_LIVE_AUTHORITY

HALT_NO_ELIGIBLE_CANDIDATE
HALT_RANKING_TIE
HALT_RANKING_NONDETERMINISTIC

HALT_SELECTED_SLICE_NOT_BOUNDED
HALT_SELECTED_SLICE_NO_PRODUCTION_SEAM
HALT_SELECTED_SLICE_NO_ORACLE
HALT_SELECTED_SLICE_DEPENDENCY_EXPLOSION

HALT_NEXT_RED_NOT_REPRODUCIBLE
HALT_NEXT_PROOF_MODEL_INCOMPLETE

HALT_RECON_REQUIRES_IMPLEMENTATION

HALT_LEXER01_CONSERVATION
HALT_LEXER02_CONSERVATION
HALT_LEXER03_CONSERVATION
HALT_LEXER04_CONSERVATION
HALT_BROAD_CORPUS_NEW_REGRESSION

HALT_F_POLYC_TOOLS
HALT_F_NO_PYTHON
HALT_F14_VIOLATION

HALT_C2_SELECTION_DEFECT
HALT_C2_TO_C3_DRIFT
HALT_C3_PHASE_PURITY

HALT_FACTORY_GATE
HALT_APPEND_ONLY
HALT_PATCH_HYGIENE
HALT_C4_PRECONDITION
```

A HALT is a successful recon outcome when its predicate is genuinely red.

---

# 74. Commit topology

Exactly:

```text
C0 AUTH
C1 INVENTORY
C2 RANK/SELECT
C3 VERIFY
C4 CLOSE
```

Five commits.

No:

```text
C1.1
C2.1
C3 fix
C4 fill
SHA backfill
post-close cleanup
```

If a sixth commit is required:

```text
HALT_PHASE_CORRECTION_REQUIRED
```

Do not create it.

---

# 75. Expected board effect

Before C4:

```text
LEXER04 = accepted forward engineering state

NEXT_SELFHOST_TARGET = UNKNOWN
```

After PASS:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03 = CLOSED PASS_TRUE_GREEN

NEXT_SELFHOST_TARGET = <mechanically selected surface>
NEXT_ATOMIC_SLICE    = <mechanically selected slice>
NEXT_ACT_ID          = <frozen successor>

NEXT_ACT_SCOPE_FROZEN = YES
```

---

# 76. Likely but nonbinding candidate context

Historical SURFACE-RECON02 ranking contained:

```text
INV.LEXER.LINK       selected
INV.PARSER.COMPOUND deferred
INV.PARSER.TOPLEVEL deferred
```

and also identified preprocessor/other lexer surfaces as tempting but
ineligible or lower-ranked.

LEXER04 has now consumed `INV.LEXER.LINK`.

Therefore parser/preprocessor/remaining lexer surfaces are reasonable
places to look.

This is **not** authorization to select any of them.

Live ranking decides.

---

# 77. What a useful result looks like

A good C4 result looks like:

```text
SURFACE_TOTAL=27
LEGACY_C_AUTHORITY=18
ELIGIBLE_CANDIDATE_COUNT=4

rank 1 INV.PARSER.COMPOUND
rank 2 INV.PARSER.TOPLEVEL
rank 3 INV.LEXER.INCLUDE
rank 4 INV.PREPROC.PP

SELECTED:
  INV.PARSER.COMPOUND

ATOMIC SLICE:
  <specific function/semantic subregion>

NEXT:
  ACT-POLYC-SELFHOST-PARSER01
```

Those values are illustrative only.

A result that simply says:

```text
NEXT=LEXER05
```

without inventory/ranking proof is a failed ACT.

---

# 78. First C1 commands

Start broad:

```sh
grep -RIn "HCC_USE_SELFHOST_COMPONENTS\|Bootstrap" src tools/bootstrap \
  --exclude-dir=build

grep -n "lex[A-Za-z0-9_]*(" src/lexer.c
grep -n "parse[A-Za-z0-9_]*(" src/parser.c
```

Then inspect call graph/authority regions rather than assuming function
names define the right surfaces.

Search for:

```text
#ifdef
#if
legacy/selfhost branch points
calls from parser to lexer/preprocessor
shared mutable parser/compiler state
```

Generate the inventory from evidence, not manually from memory.

---

# 79. First C2 decision questions

For every eligible candidate answer mechanically:

```text
Does it block the next self-host stage?

Can it be isolated without migrating adjacent compiler regions?

Is there a legacy implementation that can serve as oracle?

Can the future PolyC component be called under an existing or bounded ABI?

Can a mutation prove it is production-load-bearing?

Can we test it without rewriting the parser/compiler architecture?

What earlier migrations must be conserved?

What host/tooling residue could masquerade as a target defect?
```

Only then rank.

---

# 80. Governing principle

SURFACE-RECON03 exists to prevent:

```text
"we finished LEXER04, therefore let's invent LEXER05"
```

The next self-host migration must be discovered from the live compiler.

The governing pipeline is:

```text
live code
  ↓
semantic-authority inventory
  ↓
classification
  ↓
eligibility
  ↓
mechanical ranking
  ↓
bounded atomic slice
  ↓
reproducible RED
  ↓
complete proof model
  ↓
one frozen next ACT
```

No implementation belongs before the final arrow.

If the live repository says the next best target is parser work, choose
parser work.

If it says another lexer/preprocessor slice has greater leverage, choose
that instead.

If nothing is bounded enough:

```text
HALT_NO_ELIGIBLE_CANDIDATE
```

is preferable to fabricating a migration.
