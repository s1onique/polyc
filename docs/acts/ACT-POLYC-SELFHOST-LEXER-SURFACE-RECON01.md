# ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01

**Title:** Reconstruct the remaining production-lexer ownership graph and select the next coherent PolyC migration region

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** COMPILER / SELF-HOST / ARCHITECTURE-RECON

**Predecessor:** `ACT-POLYC-SELFHOST-LEXER01-CORRECTION01` CLOSED `PASS_WITH_CORRECTION_RESIDUE`

**Production semantic mutation:** **FORBIDDEN** — recon/design only; no `src/lexer.c` mutation; no new bootstrap component; no new registry row; no Python mutation.

**VERDICT (target):** `PASS` (winner) or `PASS` (no-winner with mechanically explained cause). No migration occurs in this ACT.

---

# 0. Mission

Determine the **next correct semantic ownership boundary** in the production lexer.

The previous `LEXER01` decomposition scored four remaining microscopic candidates (`numeric_length_scan`, `comment_skip`, `char_const_scan`, `numeric_value_parse`) and every one scored **negatively** under the old function-level model. This ACT treats that result as evidence that the next useful boundary may be **larger than an individual helper**: individually migrating helpers repeatedly pay ABI/state-boundary costs that could disappear when migrated as one coherent region.

The ACT must therefore answer:

```text
1. What semantic work remains in host-C lexer ownership?

2. Which functions are coupled strongly enough that treating
   them independently creates an artificial ABI penalty?

3. Which coherent regions can expose a narrow scalar/offset ABI?

4. Which region gives the largest meaningful ownership expansion
   at acceptable semantic and state risk?

5. Is there a mechanically defensible next PolyC component?

6. If there is not, what exact capability/boundary prevents
   further lexer self-hosting?
```

No migration occurs in this ACT. The C2 IMPL phase implements the **recon/architecture artifact** (region graph, eligibility matrix, ABI sketches, ranking), not the lexer.

---

# 1. Why a recon ACT instead of LEXER02

`LEXER01` consumed the sole positive candidate:

```text
operator_punctuation_recognizer  +952
```

while the remainder was negative. Changing the old eligibility gates (E1..E14) or score weights now merely to manufacture another positive candidate would invalidate the selection mechanism.

Therefore:

```text
OLD_FUNCTION_LEVEL_MODEL = FROZEN_AS_HISTORICAL_EVIDENCE
E1..E14                  = PRESERVED (binding for any future migration ACT)
LEXER01_RANKING_WEIGHTS  = NOT RETROACTIVELY CHANGED
```

This ACT introduces a **second-level region model**, not weaker gates.

---

# 2. Design principle

The unit of future migration is:

```text
COHERENT_SEMANTIC_REGION
```

not necessarily `ONE_C_FUNCTION`. A region is a connected set of lexer semantics whose internal state coupling is greater than its external boundary coupling.

Conceptually:

```text
host-C Lexer state
       |
       | one narrow ABI
       v
+----------------------------+
| PolyC semantic region      |
|                            |
| helper A                   |
| helper B                   |
| helper C                   |
| shared cursor machinery    |
+----------------------------+
       |
       | bounded result
       v
host-C token construction /
diagnostic machinery
```

This mirrors a conventional lexer architecture where number, string, and comment scanning are often separate coherent lexical operations rather than arbitrary one-function migration units. The PolyC candidate boundaries remain mechanically derived from this repository, not borrowed wholesale.

---

# 3. Truth boundary

Success means:

```text
LEXER_SURFACE_RECON     = COMPLETE
HOST_C_SEMANTIC_GRAPH   = COMPLETE
REGION_CANDIDATES       = MECHANICALLY_DERIVED
WINNER                  = EXACTLY_ONE
```

or, legitimately:

```text
WINNER = NONE
HALT   = MECHANICALLY_EXPLAINED
```

Success does **not** mean:

```text
NEW_POLYC_COMPONENT     = YES
LEXER02_IMPLEMENTED     = YES
FULL_LEXER_SELFHOST     = YES
```

---

# 4. Entry-gate reconstruction

Before analysis:

```text
branch = main
worktree = clean
git replace -l = empty
```

Re-run enough predecessor truth to ensure the recon is based on a valid substrate:

```text
identifier I0 == I1 == I2 == I3
operator   N0 == N1 == N2 == N3

operator direct differential    47/47
operator production seam        33/33 at stage0
                                33/33 at stage1
                                33/33 at stage2
                                33/33 at stage3

broad corpus 175/175 BYTE_IDENTICAL + 6/6 BOTH_FAIL across stage0/1/2/3
formal-dafny   PASS
F_NO_PYTHON    = entry count (expected 12)
gate-fast      PASS
```

Fresh truth wins. If the self-host predecessor cannot reproduce:

```text
HALT_LEXER_RECON_PREDECESSOR_NOT_GREEN
```

---

# 5. Scope

## Authorized

```text
docs/acts/
  ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01.md

docs/ROADMAP.md
  bounded status transition only

evidence/
  ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/**

tools/quality/
  optional PolyC-only static/recon helper
```

A temporary build-local C probe may be used for measurement. Any persistent new repository tool must be PolyC (F-POLYC-TOOLS).

## Read-only inputs

```text
src/lexer.c
src/lexer.h
src/lexer_bridge.h

docs/factory/SELF-HOST-COMPONENTS.tsv

tools/bootstrap/bootstrap02-ident.HC
tools/bootstrap/selfhost-lexer-operator-classify.HC

Makefile
src/CMakeLists.txt
```

## Forbidden mutation

```text
src/**                     (semantic changes forbidden)
tools/bootstrap/**        (no new component file)
SELF-HOST-COMPONENTS.tsv  (no new registry row)
Makefile
src/CMakeLists.txt

parser
AST
IR
backend
runtime

formal/dafny/**           (no formal source mutation)
no-Python tooling
```

No compiler behavior changes. No registry mutation. No new bootstrap component.

---

# 6. First principle: reconstruct actual state flow

Build a field-level map for every relevant `Lexer` field:

```text
field
readers
writers
semantic purpose
pointer/scalar/container
cross-file behavior
diagnostic relevance
already self-host-owned?
```

At minimum classify:

```text
ptr
start
cur_ch

lineno
line_start_ptr

cur_i64
cur_f64
cur_strlen
cur_str

ishex
flags

files
all_source
cur_file

symbol_table
seen_files

collecting
skip_else

cc
```

Use the actual current `Lexer` definition.

---

# 7. Ownership classes

Every semantic operation in `src/lexer.c` receives one primary class from the frozen list:

```text
SELFHOSTED_IDENTIFIER
SELFHOSTED_OPERATOR

CORE_CURSOR
CORE_WHITESPACE
CORE_COMMENT

CORE_NUMERIC_EXTENT
CORE_NUMERIC_VALUE

CORE_CHAR_LITERAL
CORE_STRING_LITERAL

CORE_KEYWORD_CLASSIFICATION

PREPROCESSOR
MACRO_EXPANSION
INCLUDE_FILE_STACK

DIAGNOSTIC
TOKEN_CONSTRUCTION
MEMORY_MANAGEMENT

RENDERING / DEBUG
SUPPORT
```

Do not silently count rendering, allocation, or preprocessing as "lexer semantic surface" merely because it lives in `lexer.c`.

---

# 8. Function inventory

Produce `c1/lexer-function-inventory.tsv`. Schema:

```text
function
line_start
line_end
semantic_loc
primary_class

calls
called_by

lexer_fields_read
lexer_fields_written

containers_read
containers_written

allocates
frees

diagnostic_edges
file_stack_edges
preprocessor_edges

token_kinds_produced

already_selfhosted
region_candidate
```

Every static and externally visible lexer-related function must appear exactly once.

---

# 9. Call graph

Construct the relevant directed graph `function -> function` and separately `function -> Lexer field R/W`.

Required outputs: `c1/lexer-callgraph.tsv` and `c1/lexer-stategraph.tsv`. The state graph is essential: two helpers that never call each other may still belong to one region when they manipulate the same cursor/value state.

---

# 10. State-coupling graph

Construct a semantic coupling weight between operation A and B:

```text
SHARED_STATE(A,B) =
    8  * shared_pointer_fields_written
  + 4  * shared_scalar_fields_written
  + 2  * shared_fields_read
  + 8  * ordered cursor dependency
  + 4  * shared token/result representation
```

Record the components, not just the final number. This yields `operation A <---- coupling ----> operation B`.

---

# 11. Dependency-boundary graph

For each operation calculate its outward coupling to:

```text
containers
preprocessor state
file stack
diagnostic engine
parser
AST
allocator
runtime callback
```

Formula:

```text
BOUNDARY_COST(operation) =
    64 * container mutation
  + 64 * preprocessor mutation
  + 64 * file-stack mutation
  + 48 * diagnostic callback
  + 96 * parser/AST dependency
  + 32 * allocation ownership crossing
```

Values are frozen by this ACT before candidate rankings are examined.

---

# 12. Preserve E1..E14

A **region**, like the old functions, must still pass the original hard eligibility principles:

```text
E1  reached by ordinary production lexer path
E2  lexical semantics only
E3  bounded input/state representation
E4  bounded output representation
E5  no container ownership across ABI
E6  no AST/parser mutation
E7  no preprocessor symbol-table mutation
E8  no file-stack ownership crossing
E9  no required callbacks
E10 no unsupported PolyC feature
E11 real C oracle possible
E12 real production seam observable
E13 stage0 can retain legacy implementation
E14 stage1+ can use PolyC with no runtime fallback
```

**No relaxation is authorized.**

---

# 13. Region construction algorithm

Candidate regions must not be hand-written first. Derive them from the graph. Create candidate regions using three deterministic passes.

### Pass A — single ownership classes

Group eligible operations by the primary semantic classes from §7. `CORE_NUMERIC_EXTENT` and `CORE_NUMERIC_VALUE` remain separate in Pass A.

### Pass B — high-coupling merge

Merge two candidate groups when `INTERNAL_COUPLING_GAIN >= 16` AND `combined region still passes E1..E14`. Repeat deterministically until no merge qualifies.

### Pass C — boundary-amortization merge

Consider adjacent groups where a merged ABI removes duplicated state crossings. Merge only when:

```text
BOUNDARY_SLOTS(A) + BOUNDARY_SLOTS(B) - BOUNDARY_SLOTS(A+B) >= 3
```

and E1..E14 remain true. Sort merge consideration by candidate IDs for determinism.

---

# 14. Explicit anti-gaming rule

Candidate construction must occur **before final scoring**. Required evidence order:

```text
graph freeze -> region construction -> eligibility -> score -> winner
```

Forbidden: score functions, notice preferred winner loses, merge convenient functions, rescore.

---

# 15. Candidate identity

Region IDs must describe semantics, not implementation intent.

Good:

```text
scalar_literal_scanner
numeric_literal_scanner
comment_whitespace_scanner
quoted_literal_scanner
```

Bad: `next_component`, `easy_region`, `lexer02`, `winning_candidate`.

---

# 16. Region inventory

Produce `c2/lexer-region-inventory.tsv`. Schema:

```text
region_id
member_functions
member_classes
semantic_loc
token_kinds
fields_read
fields_written
pointer_fields_written
scalar_fields_written
internal_coupling
external_boundary_cost
container_edges
preprocessor_edges
file_stack_edges
diagnostic_edges
abi_input_slots
abi_output_slots
direct_oracle_possible
production_seam_possible
E1..E14
eligible
ineligible_reason
ownership_gain
cohesion_gain
boundary_amortization
risk_score
final_score
rank
```

---

# 17. New region scoring model

Unlike E1..E14, the old function score was calibrated for tiny units. This ACT therefore freezes a **region-specific** model.

For each **eligible** region:

```text
OWNERSHIP_GAIN =
    semantic_loc
  + 24 * distinct_token_kinds
  + 12 * host_C_functions_absorbed
  + 16 * scalar_fields_semantically_owned
```

```text
COHESION_GAIN = internal_coupling
```

```text
BOUNDARY_AMORTIZATION =
    24 * eliminated_abi_slots
  + 32 * eliminated_cross_boundary_cursor_transitions
```

```text
RISK =
    16 * final_abi_input_slots
  + 16 * final_abi_output_slots
  + 40 * pointer_fields_written
  + 48 * diagnostic_edges
  + 64 * allocation_ownership_edges
  + 96 * container_edges
```

```text
FINAL_SCORE = OWNERSHIP_GAIN + COHESION_GAIN + BOUNDARY_AMORTIZATION - RISK
```

Freeze this before seeing final ranks.

---

# 18. Why cohesion gets explicit credit

Previously three helpers each paid a separate ABI boundary. A coherent region may instead have one cursor/state record shared across helpers. If that actually reduces boundary complexity, the scoring model should recognize it. If it does not, the region will still lose.

---

# 19. Cursor ownership analysis

For every eligible region determine whether the component can operate using `src`, `src_len`, `cursor offset`, `flags`, `bounded scalar state` instead of owning `Lexer *`.

Preferred conceptual form:

```text
Result BootstrapScanRegion(
    U8  *src,
    I64  src_len,
    I64  cursor,
    I64  flags,
    ...
);
```

Result fields should be POD/scalar: `end_cursor`, `kind`, `subkind`, `length`, `i64_value`, `f64_value bits/value`, `status`, `error_offset`. No pointer one-past-end semantics.

---

# 20. Shared cursor primitive hypothesis

Explicitly test whether several remaining helpers could be combined because their main shared dependency is byte traversal. Inventory use of `lexNextChar`, `lexRewindChar`, `lexPeekMatch`, `lexPeek`, and direct manipulation of `l->ptr`, `l->start`. Determine whether a PolyC-local cursor abstraction could remove repeated ABI crossings without changing language semantics. Do **not** implement it in this ACT.

---

# 21. Numeric region hypothesis

Evaluate, but do not assume, `numeric_extent + numeric_value_parse + numeric escape/base recognition` as one region. Mechanically determine shared cursor logic, shared ishex/base state, shared token type, shared cur_i64/cur_f64 outputs, shared termination semantics. Also record any use of libc parsing routines or diagnostics that would prevent a bounded PolyC implementation.

---

# 22. Quoted-literal hypothesis

Evaluate whether character constants, string literal scanning, and escape recognition share enough state to form one region. Do not force them together if allocation/string ownership crosses E5. A region that requires passing owned `AoStr`/allocated buffers across the boundary may correctly be ineligible.

---

# 23. Comment/whitespace hypothesis

Evaluate whitespace, line accounting, and comments carefully. This area can look simple while owning `lineno`, `line_start_ptr`, `comments-as-tokens`, `preprocessor line semantics`. If the state boundary is wide, record that mechanically. No "comments are easy" assumption.

---

# 24. Keyword classification

Separately determine whether keyword classification is pure lexical semantics or currently tied to `symbol_table`, `Map`, or preprocessor/builtin type metadata. If it requires a `Map *` crossing or reproducing the keyword table in two owners, likely mark ineligible under E5/E7. Again: measure.

---

# 25. Diagnostics ownership

For every region distinguish `DETECTION` from `RENDERING / TERMINATION`. A region may still be eligible if PolyC can return `status`, `error_kind`, `error_offset` and host C retains `lexRaise`. Do not automatically penalize every error path as requiring diagnostic-engine ownership. This distinction should materially improve the graph model compared with LEXER01.

---

# 26. Region ABI sketch

For each eligible region produce an **ABI sketch**, not implementation. Required:

```text
region_id
inputs
outputs
ownership
error model
cursor postcondition
EOF postcondition
maximum scalar slot count
```

No headers/source changes.

---

# 27. ABI slot accounting

Count one slot for each independent scalar/pointer argument or output. Do not game the metric by wrapping 15 values into a struct pointer. Record:

```text
logical_slots
physical_C_parameters
```

Scoring uses **logical_slots**.

---

# 28. Direct oracle feasibility

Every eligible region needs a credible C oracle strategy. Classify:

```text
DIRECT_EXISTING_FUNCTION
TEST_ONLY_PRODUCTION_EXTRACTION
PRODUCTION_SEAM_COMPARISON
TRANSCRIPTION_ONLY
IMPOSSIBLE
```

Eligibility requires one of the first three. `TRANSCRIPTION_ONLY` is not enough for the next self-host migration.

---

# 29. Production seam feasibility

A candidate remains eligible only if the future migration can measure the real `Lexer` pre/post state. Required potential observables:

```text
ptr offset
start offset
line
line-start offset
cur_i64
cur_f64
cur_strlen
token type
token extent
next byte
EOF state
status/error
```

Use the subset the region genuinely affects.

---

# 30. Fixed-point feasibility

For each region verify its projected PolyC implementation should be compilable by stage0/stage1/stage2/stage3 without unsupported PolyC syntax, new runtime primitive, new backend capability, or new LLVM requirement. This is architectural feasibility, not implementation proof.

---

# 31. Source corpus relevance

For each candidate region find real production corpus examples exercising it. Record at least:

```text
source
line
lexical construct
region
```

A winner must have a nontrivial real corpus slice. Synthetic fixtures alone are insufficient.

---

# 32. Dynamic coverage

Where practical, instrument a **test-local** lexer build to count candidate-region hits over the current broad corpus. Capture:

```text
region_id
invocation_count
files_hit
successful_compile_files_hit
error_fixture_hits
```

Instrumentation must not enter production commits. If instrumentation is disproportionately invasive, classify `DYNAMIC_COVERAGE = UNAVAILABLE_NONBLOCKING` and rely on static + corpus search evidence.

---

# 33. Selection hard floor

A region may win only when:

```text
eligible                = YES
final_score             > 0
direct_oracle_possible  = YES
production_seam_possible= YES
real_corpus_files      >= 1
```

If rank 1 is still `<= 0`: `NO_WINNER`. Do not choose "least negative."

---

# 34. Deterministic tie-break

If scores tie:

```text
1. greater semantic LOC
2. more existing host-C functions absorbed
3. more real corpus files hit
4. fewer logical ABI slots
5. fewer diagnostic edges
6. lexical region_id
```

---

# 35. Winner result

Produce `c2/winner.txt`:

```text
WINNER=<region_id>
RANK=1
FINAL_SCORE=<n>
MEMBERS=<...>
OWNERSHIP_GAIN=<n>
COHESION_GAIN=<n>
BOUNDARY_AMORTIZATION=<n>
RISK=<n>
E1..E14=PASS
DIRECT_ORACLE=<strategy>
PRODUCTION_SEAM=YES
PROJECTED_ABI_INPUT_SLOTS=<n>
PROJECTED_ABI_OUTPUT_SLOTS=<n>
REAL_CORPUS_FILES=<n>
```

Or `WINNER=NONE` with mechanically explicit cause.

---

# 36. Runner-up record

Capture at least the top three. We want to understand **why** a region lost: ineligible, negative score, wide state boundary, Map/container dependency, diagnostic coupling, file-stack coupling, unsupported PolyC primitive. This helps determine subsequent architecture.

---

# 37. Candidate sensitivity check

Do not change weights. Report the winner's margin `winner_score - runner_up_score` and classify:

```text
>= 100  robust
25..99  moderate
1..24   narrow
```

A narrow win does not block execution, but should inform the future migration ACT's caution.

---

# 38. Old microscopic candidates

Map each previous candidate into the new region graph:

```text
numeric_length_scan
comment_skip
char_const_scan
numeric_value_parse
```

Record whether each is `absorbed into region X`, `remains standalone`, or `excluded by eligibility`. This provides continuity with LEXER01 rather than pretending the previous analysis never happened.

---

# 39. Self-host surface metrics

Freeze the post-LEXER01 state. Required metrics:

```text
SELFHOST_LEXER_COMPONENTS       = 2
  identifier_scanner
  operator_punctuation_recognizer

SELFHOSTED_SEMANTIC_LOC         = <n>
HOST_C_CORE_SEMANTIC_LOC        = <n>

SELFHOSTED_TOKEN_KINDS          = <n>
HOST_C_CORE_TOKEN_KINDS         = <n>

SELFHOSTED_ENTRY_SEAMS          = <n>
HOST_C_CORE_ENTRY_SEAMS         = <n>

POLYC_PRODUCTION_CALL_SITES     = <n>

HOST_C_CORE_REGION_COUNT        = <n>
```

No estimate. Derive mechanically.

---

# 40. Projected winner delta

If a winner exists, report what a future migration would change:

```text
PROJECTED_SELFHOST_COMPONENTS     = 2 -> 3
PROJECTED_SELFHOSTED_SEMANTIC_LOC = old -> old + N
PROJECTED_HOST_C_CORE_SEMANTIC_LOC= old -> old - N
PROJECTED_TOKEN_KIND_DELTA        = +N
PROJECTED_ENTRY_SEAM_DELTA        = +N
```

These are projections, clearly labeled — not closure claims.

---

# 41. S1 completion criterion

This ACT must define when the lexer-expansion milestone itself is done. Recommended mechanical definition:

```text
S1 can close when no remaining HOST_C_CORE_LEXER region:
  passes E1..E14
  AND
  has FINAL_SCORE > 0
```

Everything left would then belong to `preprocessor/file-stack infrastructure`, `diagnostics/memory infrastructure`, or `a capability gap requiring a separate architectural ACT`. This prevents "rewrite every line in lexer.c" from becoming the implicit goal.

---

# 42. Parser frontier condition

Parser self-host work is **not** automatically unlocked merely because one recon returns no winner. If no eligible lexer region remains, classify remaining host-C semantics as `CORE_LEXER = exhausted` or `CORE_LEXER = blocked by capability X`. Only the first can propose S1 closure. The second proposes a capability ACT.

---

# 43. Broad-generation conservation

Because this ACT changes no semantics, fresh broad-corpus generation behavior should remain identical. Run current corpus with stage0/stage1/stage2/stage3.

Required:

```text
successful output divergence = 0
success/failure divergence   = 0
```

Use the corrected four-stage form established by `LEXER01-CORRECTION01` (175 successful + 6 expected failures across all four stages).

---

# 44. Existing self-host conservation

Re-run:

```text
identifier fixed point I0 == I1 == I2 == I3
operator fixed point   N0 == N1 == N2 == N3
operator direct differential   47/47
operator production seam
  33/33 at stage0
  33/33 at stage1
  33/33 at stage2
  33/33 at stage3
```

The correction packet provides those as the authoritative baseline.

---

# 45. Static binding conservation

Confirm:

```text
stage0:  no _BootstrapClassifyOperator call
stage1:  bl _BootstrapClassifyOperator
stage2:  bl _BootstrapClassifyOperator
stage3:  bl _BootstrapClassifyOperator
```

Recon must not alter this topology.

---

# 46. Fail-closed linkage conservation

Run one bounded negative check that a missing required operator component still causes CMake configuration failure. Do not exhaustively retest all three unless cheap. The correction changed the build graph from optional `if(EXISTS)` linkage to explicit `FATAL_ERROR` guards for all three self-host stages.

---

# 47. Dafny conservation

Run `make formal-dafny`. Required: `errors = 0`, `audit findings = 0`. Current expected verified count is 17, but zero errors/audit findings is the binding property. No formal source mutation.

---

# 48. No-Python pause conservation

Run current checker. Required: `F_NO_PYTHON_EXIT = F_NO_PYTHON_ENTRY`. Expected: 12. No Python migration. No new Python source. No new Python execution edge.

---

# 49. Factory conservation

Run current authoritative:

```text
factory-v2-test
factory-append-only-test
factory-halt-classification-test
factory-closure-status-check
shell-loc-gate
gate-fast
```

All runnable gates PASS.

---

# 50. Patch hygiene

For this ACT's own range:

```text
git diff --check <ENTRY>..HEAD
```

must be clean. Historical evidence whitespace remains nonblocking governance residue.

---

# 51. C1 phase — RED/recon

C1 proves the old candidate model is insufficient. Binding RED is **not** "lexer broken". It is:

```text
REMAINING_FUNCTION_CANDIDATES_POSITIVE = 0
COHERENT_REGION_MODEL                   = NOT YET DERIVED
NEXT_MIGRATION_BOUNDARY                 = UNKNOWN
```

No production mutation.

---

# 52. C1 evidence

Create:

```text
evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c1/
  README.md
  entry-identity.txt
  predecessor-freeze.txt
  prior-candidate-freeze.tsv
  prior-negative-score-red.txt
  lexer-function-inventory.tsv
  lexer-callgraph.tsv
  lexer-stategraph.tsv
  lexer-field-ownership.tsv
  semantic-classes.tsv
  state-coupling.tsv
  external-boundaries.tsv
  selfhost-surface-baseline.txt
  corpus-baseline.txt
  no-python-baseline.txt
  dafny-baseline.txt
  factory-baseline.txt
  c1-required-result.txt
```

---

# 53. C1 binding result

```text
ACT_PHASE                = RED
PREDECESSOR_GREEN        = YES
SELFHOST_LEXER_COMPONENTS = 2
OLD_MICRO_CANDIDATES      = 4
OLD_POSITIVE_CANDIDATES   = 0
LEXER_FUNCTION_INVENTORY  = COMPLETE
LEXER_STATE_GRAPH         = COMPLETE
REGION_MODEL              = ABSENT_AT_ENTRY
PRODUCTION_DELTA          = ZERO
C1_TO_C2_GATE             = OPEN
```

---

# 54. C2 phase — region derivation

Still **no compiler implementation**. C2 constructs semantic regions, coupling values, boundary values, E1..E14 eligibility, ABI sketches, oracle strategies, production-seam strategies, scores, ranking, winner. This is design derived from evidence.

---

# 55. C2 evidence

Create:

```text
evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c2/
  README.md
  region-construction-log.txt
  region-membership.tsv
  lexer-region-inventory.tsv
  eligibility-matrix.tsv
  abi-sketches.tsv
  oracle-feasibility.tsv
  production-seam-feasibility.tsv
  corpus-region-map.tsv
  dynamic-region-coverage.tsv       # if available
  region-scores.tsv
  ranking.txt
  sensitivity.txt
  legacy-candidate-mapping.tsv
  winner.txt
  runner-ups.txt
  projected-surface-delta.txt
  c2-required-result.txt
```

---

# 56. C2 binding result — winner case

If a winner exists:

```text
ACT_PHASE                       = IMPL
REGION_MODEL                    = COMPLETE
REGION_COUNT                    = <N>
ELIGIBLE_REGION_COUNT           = <N>
WINNER                          = <region>
WINNER_SCORE                    = > 0
WINNER_E1_E14                   = PASS
WINNER_ABI                      = BOUNDED
WINNER_DIRECT_ORACLE            = POSSIBLE
WINNER_PRODUCTION_SEAM          = POSSIBLE
WINNER_FIXED_POINT_FEASIBILITY  = PASS
PRODUCTION_DELTA                = ZERO
C2_TO_C3_GATE                   = OPEN
```

Despite the Factory phase label, **there is no compiler implementation**; C2 implements the architecture/recon artifact.

---

# 57. C2 binding result — no-winner case

A completely valid result:

```text
REGION_MODEL                   = COMPLETE
ELIGIBLE_POSITIVE_REGION_COUNT = 0
WINNER                         = NONE
ROOT_CAUSE                     = <mechanically classified>
S1_STATE                       = EXHAUSTED
```

or:

```text
S1_STATE = BLOCKED_BY_CAPABILITY
```

Then C3 verifies that conclusion.

---

# 58. C2 HALTs

### `HALT_LEXER_RECON_INVENTORY_INCOMPLETE`

Cannot account for production lexer semantics. `HALT_CLASS=PRODUCTION, BLOCKS_NEXT=YES`.

### `HALT_LEXER_RECON_REGION_NONDETERMINISTIC`

Region construction depends on subjective/manual grouping not captured by frozen rules. `HALT_CLASS=AUTHORIZATION, BLOCKS_NEXT=YES`.

### `HALT_LEXER_RECON_BASELINE_DIVERGENCE`

Self-host generations regress during a supposedly nonsemantic ACT. `HALT_CLASS=PRODUCTION, BLOCKS_NEXT=YES`.

### `HALT_LEXER_RECON_SCOPE_EXPANSION_REQUIRED`

Analysis requires semantic/compiler changes rather than recon. `HALT_CLASS=AUTHORIZATION, BLOCKS_NEXT=YES`.

---

# 59. C3 phase — independent verification

C3 changes no design inputs. Recompute from a fresh tree: function inventory, region membership, eligibility, scores, rank using the committed rules. Required: `C2 ranking == C3 ranking`. This proves we did not manually choose the result.

---

# 60. C3 winner verification

For the winner, independently verify: all members really belong to region, all E1..E14 predicates, ABI slot count, shared state, boundary amortization, oracle feasibility, production seam feasibility, real corpus evidence.

If C3 produces a different rank #1: `HALT_LEXER_RECON_RANK_NOT_REPRODUCIBLE`.

---

# 61. C3 no-winner verification

If C2 found no winner, prove `every eligible region score <= 0` or `every positive raw region fails at least one E1..E14`. Then independently classify S1 as `EXHAUSTED` vs `BLOCKED_BY_CAPABILITY`.

---

# 62. C3 conservation

Fresh rerun: identifier I0..I3, operator N0..N3, 47/47 operator differential, 33/33 four-stage seam, four-stage broad corpus, formal Dafny, F_NO_PYTHON unchanged, Factory gates. No semantic drift.

---

# 63. C3 evidence

```text
evidence/.../c3/
  README.md
  fresh-region-derivation.txt
  fresh-region-inventory.tsv
  fresh-scores.tsv
  ranking-reproduction.txt
  winner-recheck.txt  (or no-winner-recheck.txt)
  abi-recheck.txt
  oracle-recheck.txt
  production-seam-recheck.txt
  current-selfhost-conservation.txt
  corpus-conservation.txt
  dafny.txt
  no-python.txt
  factory-gates.txt
  scope-audit.txt
  patch-hygiene.txt
  c3-required-result.txt
```

---

# 64. C3 binding result

Winner case:

```text
REGION_DERIVATION      = REPRODUCIBLE
RANKING                = REPRODUCIBLE
WINNER                 = <region>
WINNER_RANK            = 1
WINNER_SCORE           = <positive>
WINNER_E1_E14          = PASS
WINNER_MIGRATION_READY = YES
C3_TO_C4_GATE          = OPEN
```

No-winner case:

```text
REGION_DERIVATION          = REPRODUCIBLE
POSITIVE_ELIGIBLE_REGIONS  = 0
WINNER                     = NONE
S1_STATE                   = EXHAUSTED | BLOCKED_BY_CAPABILITY
C3_TO_C4_GATE              = OPEN
```

---

# 65. C4 phase — close the design decision

C4 is closure only. No source changes except `docs/ROADMAP.md`, new c4 evidence, HANDOFF. Recompute closure-critical ranking once more or at least verify committed C3 outputs from the candidate tree.

---

# 66. C4 winner verdict

If a winner exists: `ACT-Verdict: PASS`. Closure truth:

```text
LEXER_SURFACE_RECON          = PASS
REGION_MODEL                 = COMPLETE
WINNER                       = <region>
WINNER_SELECTED_MECHANICALLY = YES
WINNER_POSITIVE_SCORE        = YES
WINNER_E1_E14                = PASS
WINNER_ABI                   = BOUNDED
WINNER_DIRECT_ORACLE         = FEASIBLE
WINNER_PRODUCTION_SEAM       = FEASIBLE
NEXT_ACT                     = ACT-POLYC-SELFHOST-LEXER02
LEXER02_SCOPE                = EXACTLY <winner>
```

---

# 67. C4 no-winner verdict

If no positive eligible region exists, the ACT may still **PASS** because the mission was recon.

Case A: `S1_STATE = EXHAUSTED, NEXT = S1_EXIT_REVIEW`.
Case B: `S1_STATE = BLOCKED_BY_CAPABILITY, NEXT_ACT = <mechanically identified capability ACT>`.

Do not fabricate `LEXER02`.

---

# 68. C4 acceptance criteria

The ACT closes PASS only when:

```text
AC01  predecessor correction GREEN
AC02  current self-host components    = 2
AC03  prior microscopic candidates    frozen
AC04  full lexer function inventory   complete
AC05  full Lexer field R/W map        complete
AC06  call graph                       complete
AC07  state-coupling graph             complete
AC08  external-boundary graph          complete

AC09  semantic ownership classes       complete
AC10  region derivation rules          frozen before scoring
AC11  region candidate set             mechanically produced
AC12  no manual post-score merge/split

AC13  E1..E14 preserved
AC14  eligibility mechanically derived

AC15  region score formula             frozen before rank
AC16  all score inputs                 evidenced
AC17  deterministic tie-break          used

AC18  ABI sketch exists                for every eligible region
AC19  oracle strategy exists           for every eligible region
AC20  production-seam strategy exists  for every eligible region

AC21  old microscopic candidates       mapped to regions
AC22  self-host surface baseline       mechanically measured

AC23  C2 ranking reproducible in C3
AC24  winner rank reproducible OR no-winner reproducible

AC25  no production semantic delta
AC26  no new component
AC27  no registry row
AC28  no stage4
AC29  no parser/AST/IR/backend changes

AC30  identifier fixed point           conserved
AC31  operator fixed point             conserved
AC32  operator direct differential     conserved
AC33  real operator seam               conserved
AC34  broad four-stage corpus          conserved

AC35  formal Dafny                     PASS
AC36  F_NO_PYTHON                      unchanged
AC37  no new Python source
AC38  no new Python edge

AC39  Factory gates                    PASS
AC40  ACT-range diff-check             clean
AC41  historical closed evidence       unchanged
AC42  no binary evidence

AC43  exactly one CLOSE commit
AC44  no SHA-of-self claims

AC45  NEXT is derived from result, not decided before recon
```

---

# 69. Evidence packet

Final structure:

```text
evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/
  c1/  c2/  c3/  c4/
  HANDOFF.md
```

C4:

```text
README.md
acceptance-matrix.txt
closure-summary.txt
final-region-map.txt
final-ranking.txt
final-winner.txt  (or final-no-winner.txt)
selfhost-surface-state.txt
next-act-binding.txt
final-conservation.txt
factory-gates.txt
scope-audit.txt
patch-hygiene.txt
residue.txt
roadmap-transition.txt
```

Text only.

---

# 70. ROADMAP transition

Winner case:

```text
S0 COMPONENT FRAMEWORK — GREEN
S1 LEXER EXPANSION     — ACTIVE
  identifier_scanner            — GREEN
  operator_punctuation_recognizer — GREEN
  ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01 — CLOSED PASS
  NEXT: ACT-POLYC-SELFHOST-LEXER02, selected region = <winner>
```

No-winner/exhausted: `S1 LEXER EXPANSION — RECON COMPLETE, POSITIVE ELIGIBLE REGIONS = 0, S1 EXIT REVIEW = NEXT`.

Capability-blocked: `S1 LEXER EXPANSION — BLOCKED BY <capability>, NEXT = <bounded capability ACT>`.

Always preserve:

```text
NO-PYTHON CAMPAIGN — PAUSED at C2.3 GREEN, remaining count = 12
```

---

# 71. Trailer topology

C1: `ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01`, `ACT-Phase: RED`.
C2: `ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01`, `ACT-Phase: IMPL`.
C3: `ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01`, `ACT-Phase: EVIDENCE`.
C4: `ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01`, `ACT-Phase: CLOSE`, `ACT-Verdict: PASS`.

No HALT trailers on PASS. Exactly one CLOSE.

---

# 72. Hard stop

After C4: **STOP.** Even if the winner is obvious and migration looks trivial:

```text
DO NOT create its PolyC source.
DO NOT add its registry row.
DO NOT edit lexer.c.
DO NOT begin LEXER02.
```

The point of this ACT is to make the **migration boundary itself independently reviewable** before semantics change. If the result is `WINNER = scalar_literal_scanner` for example, that becomes the frozen subject of the next ACT. If it is something surprising, follow the mechanics.

---

# Execution directive

> **Execute `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01` end-to-end as a recon/design ACT with zero compiler-semantic mutation. Start from the corrected two-component lexer substrate (`identifier_scanner` and `operator_punctuation_recognizer`). Preserve the original E1–E14 hard eligibility gates and do not alter the old LEXER01 scoring merely because all remaining microscopic candidates were negative. Build a complete current `src/lexer.c` function, call, Lexer-field R/W, state-coupling, and external-boundary graph; deterministically derive larger coherent semantic regions before scoring; then rank eligible regions with the frozen region formula including ownership gain, cohesion gain, boundary amortization, and risk. For every eligible region produce a bounded ABI sketch, real-C-oracle strategy, production-seam strategy, fixed-point feasibility, and real production-corpus witnesses. Recompute the analysis independently in C3. A positive winner must have score >0, pass all E1–E14, and have real oracle/seam feasibility; never choose the least-negative candidate. If no winner exists, classify S1 as exhausted or blocked by a mechanically identified capability instead of weakening the gates. Throughout, preserve identifier/operator four-stage fixed points, four-stage broad-corpus behavior, operator direct/seam tests, Formal Dafny, F-NO-PYTHON=entry value, Factory gates, F14 and patch hygiene. C4 closes the architecture decision exactly once and binds the next ACT, then hard-stops before any migration implementation.**
