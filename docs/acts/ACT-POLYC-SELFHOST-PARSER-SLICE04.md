# ACT-POLYC-SELFHOST-PARSER-SLICE04

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT

**Class:** SELFHOST / PARSER / AST-OPERATOR / PRODUCTION-AUTHORITY-MIGRATION

**Priority:** P0

**Repository:** `s1onique/polyc`
**Branch:** `main`

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01`
(closed with `ACT-Verdict: PASS`; its evidence tree, HANDOFF and ACT
document are closed evidence under F14 and are NOT modified here)

**Expected ENTRY_HEAD:** `e3eaf38c2e0a1183d8fd4969443c32c92f075e58`

**Successor:** TBD after SLICE04 closes

---

## 0. Mission

Migrate **exactly one** legacy-C AST operator-classification function
into production-authoritative PolyC.

The candidate must be selected mechanically from:

```text
CAND-019  astBinOpFromToken
          src/ast.c:206..236 (historical location)

CAND-020  astUnaryOpFromToken
          src/ast.c:238..254 (historical location)
```

The actual C1 selection is binding.  Neither candidate is preselected by
this ACT.

**Required engineering result:**

```text
SELECTED_AST_OPERATOR_AUTHORITY = POLYC
SELECTED_LEGACY_C_AUTHORITY     = RETIRED
SELECTED_PRODUCTION_DELEGATION  = LOAD_BEARING

OTHER_AST_OPERATOR_AUTHORITY    = LEGACY_C
OTHER_AST_OPERATOR_SEMANTICS    = UNCHANGED

PARSER_PADDING_AUTHORITY        = POLYC
PARSER_CONTROL_FLOW_AUTHORITY   = POLYC
PARSER_PRECEDENCE_AUTHORITY     = POLYC

PRODUCTION_SEMANTIC_DELTA       = 0
NEW_SEMANTIC_REGRESSIONS        = 0
```

The selected mapping must no longer be computed by C in a production
build.  The legacy implementation may remain solely for stage0 and
differential-oracle qualification.

This ACT includes selection, implementation, production delegation,
differential verification, independent G0-G3 builds, causal mutation,
and conservation.

**Do not stop after C0 authorization or C1 reconnaissance merely
because implementation is substantial.**  A session boundary or
anticipated engineering effort is not a Factory HALT condition.

---

## 1. Mandatory entry checks

At start:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git replace -l

git merge-base --is-ancestor \
  e3eaf38c2e0a1183d8fd4969443c32c92f075e58 \
  HEAD
```

Require:

```text
BRANCH=main
WORKTREE_CLEAN=YES
PREDECESSOR_REACHABLE=YES
GIT_REPLACE_REFS=0
```

If HEAD has advanced, inventory all intervening changes.  If they alter
either candidate's semantics, ownership, or build path, redo candidate
discovery before committing C0.

Record the actual full entry HEAD and source hashes.  Do not silently
substitute the public GitHub branch for a newer local tree.

Read:

```text
AGENTS.md
docs/factory/DOCTRINE.md
docs/factory/GIT-METADATA.md
docs/factory/LEXER07-BASELINE-AUTHORITY.tsv

docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE03.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01.md

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c2/
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01/c3/
```

Read the actual source:

```text
src/ast.c
src/ast.h
src/prslib.c
src/prslib.h
src/lexer.h
src/CMakeLists.txt
```

Historical line numbers are anchors, not source identities.

---

## 2. Predecessor qualification reconciliation

The previous correction's migration is preserved.

Two non-production bookkeeping defects must be acknowledged before
SLICE04 freezes its own proof contract.

### D-PREV-01 -- AC count

The predecessor's acceptance TSV contains **24 predicate rows** while
its aggregate counters say 25.

Require:

```text
PREDECESSOR_ACTUAL_AC_COUNT=24
PREDECESSOR_REPORTED_AC_COUNT=25
PREDECESSOR_LEDGER_COUNT_DRIFT=ACKNOWLEDGED
```

Do not edit the predecessor's closed ledger, re-label a row, or claim
that the historical 25/25 was mechanically correct.

SLICE04 must derive its own total from the actual frozen acceptance rows
and verify uniqueness and completeness.

### D-PREV-02 -- G0 compiler provenance

The predecessor has two conflicting representations:

```text
Independent G0 receipt:
  compiler = /usr/bin/cc
  producing compiler SHA = 9b11ead1...

Raw generations transcript:
  G0 compiler SHA = same as PolyC G1
```

The independent receipt provides the corrected observation; the raw
older generation output remains historically inconsistent.

For SLICE04, implement one canonical provenance path in which the
producing executable is resolved and hashed from the **actual invoked
command**.

Require:

```text
PREDECESSOR_G0_REPORT_DRIFT=ACKNOWLEDGED
SLICE04_G0_COMPILER_IDENTITY=LIVE_AND_BOUND
SLICE04_PROVENANCE_SINGLE_VALUED=YES
```

A newer explanatory paragraph must never override a contradictory raw
receipt while simultaneously calling the receipts consistent.

### Predecessor conservation lock

```text
PREDECESSOR_EVIDENCE_DELTA=0
PREDECESSOR_HANDOFF_DELTA=0
PREDECESSOR_ACT_DELTA=0
```

No separate historical correction ACT is authorized here.

---

## 3. Scope

### 3.1 Authorized tracked mutations

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE04.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE04.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md

evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/**

src/ast.c
src/CMakeLists.txt

src/cmake/VerifyAstTokenMapObject.cmake
src/cmake/WriteAstTokenMapObjectStamp.cmake

tools/bootstrap/selfhost-parser-slice04.HC

tools/quality/parser-slice04-*.HC
tools/quality/parser-slice04-oracle-*.c
tools/quality/parser-slice04-oracle-*.h

Makefile
```

The optional C oracle files are permitted only as narrow adapters or
executable drivers.  They must not reimplement the operator mapping.

The optional CMake files are explicitly authorized to avoid repeating
SLICE03's out-of-scope build-verifier mistake.

All substantive verification logic must be PolyC, except the real legacy
C oracle and indispensable external toolchain adapters.

### 3.2 Forbidden mutations

```text
existing closed ACT documents
existing closed evidence/**
existing closed HANDOFFs

src/parser.c
src/prslib.c
src/lexer.c
src/lexer.h
src/ast.h

src/cctrl.c
src/cctrl.h

other tools/bootstrap/**
existing Factory validators
pre-push hooks
```

The selected portion of `src/ast.c` alone may change semantically in
structure; its observed behavior must remain equivalent.

The non-selected `ast*OpFromToken` function must remain byte-identical
unless build-conditional wrapping absolutely requires a shared formatting
change.  Such an exception requires prospective C1 authorization before
C2 and an exact semantic conservation witness.

No new Python.

No new unrelated shell tooling.

No backend, lexer, parser-layout, exception-handling, or AST-allocation
redesign.

---

## 4. Core semantic contract

The existing functions have this shape:

```c
int astBinOpFromToken(s64 op, AstBinOp *result);
int astUnaryOpFromToken(s64 op, AstUnOp *result);
```

Both:

1. Return `1` when the token maps to an AST operator.
2. Return `0` otherwise.
3. Write the enum value through `result` only on success.
4. Leave the caller's existing result value unchanged on failure.

**All four properties are binding.**

A replacement that returns the correct enum but writes the output on
failure is incorrect.

A replacement that returns the correct success flag but writes a
different enum is incorrect.

A replacement that changes accepted token aliases, adds validation not
present in the legacy function, or changes integer width is incorrect.

### 4.1 Intended scalar PolyC ABI

The preferred bridge is a pure scalar mapping:

```text
Input:
  I64 token_value

Output:
  I64 mapped_operator_or_negative_sentinel
```

For the selected candidate:

```text
CAND-019:
  BootstrapAstBinOpFromToken(I64 token_value) -> I64

CAND-020:
  BootstrapAstUnaryOpFromToken(I64 token_value) -> I64
```

The preferred unsuccessful sentinel is `-1`.

This ABI is authorized **only after C1 proves** that:

- Every successful legacy mapping corresponds to a nonnegative enum
  value.
- `-1` cannot be a valid mapped enum.
- The C and PolyC representations preserve every accepted enum value
  exactly.
- The entire legacy decision depends only on the token scalar.

If these conditions fail, design a bounded, explicitly tagged result
without relying on host AST pointers or sentinel ambiguity.

Do not silently choose an unsafe sentinel.

### 4.2 Production C adapter

If the scalar/sentinel ABI is proven, the selected production function may
use the following pattern:

```c
I64 mapped = BootstrapAstOpFromToken((I64)op);
if (mapped < 0)
    return 0;

*_result = (SelectedAstOp)mapped;
return 1;
```

Here `BootstrapAstOpFromToken` and `SelectedAstOp` stand for the actual
selected names frozen in C1.

This C adapter does not own semantic classification.  PolyC performs the
token-to-operator decision.

The adapter may retain responsibility for the original C ABI: boolean
success and conditional output storage.

The function must not call the legacy switch before, after, or alongside
PolyC delegation.

### 4.3 Null output pointer

The original function dereferences the result pointer for successful
tokens.

The migration must not introduce a new externally observable null-pointer
contract without authorization.

The primary differential tests use valid output storage.

If null-pointer behavior is measured, classify it as a separate
compatibility observation.  Do not use undefined C behavior as a required
successful fixture.

---

## 5. C0 -- AUTH / baseline

Create:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c0/
  entry-identity.txt
  predecessor-reconciliation.txt
  source-freeze.tsv
  production-authority.tsv
  baseline-conservation.txt
  candidate-scope.txt
  required-result.txt
```

Capture SHA-256 for:

```text
src/ast.c
src/ast.h
src/prslib.c
src/parser.c
src/lexer.h
src/CMakeLists.txt

tools/bootstrap/selfhost-parser-padding.HC
tools/bootstrap/selfhost-parser-control-flow-token.HC
tools/bootstrap/selfhost-parser-operator-precedence.HC

docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
```

Capture the current production compiler identity, current test
configuration, stage0 compiler identity, and the actual parser/lexer
baseline.

### C0 RED requirements

Before implementation:

```text
SELECTED_COMPONENT_EXISTS=NO
SELECTED_PRODUCTION_DELEGATION=NO
SELECTED_POLYC_AUTHORITY=NO
LEGACY_AST_MAPPING_AUTHORITY=YES
```

These REDs must be demonstrated against the actual production function,
not a synthetic stand-in.

Verify that no stale object from an ignored `build/` directory can make a
missing-component RED appear green.

Commit with:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE04
ACT-Phase: RED
```

---

## 6. C1 -- Mechanical candidate selection

Recompute eligibility for both CAND-019 and CAND-020 from the live code.

### 6.1 Required candidate facts

For each function record:

```text
candidate_id
source_path
source_start
source_end
source_sha256

accepted_token_values
accepted_mapping_count

actual_production_call_sites
nonproduction_call_sites

state_reads
state_writes
callback_dependencies
recovery_dependencies

input_projection
output_projection

enum_minimum
enum_maximum
sentinel_collision

r0
r1
r2
r3
r4
r5
r6

eligible
exclusion_reason
```

The ranking tool must derive eligibility from facts, not from an
operator-authored `eligible=YES` column.

### 6.2 Required proof of bridgeability

For both candidates, prove or disprove:

```text
LEGACY_AUTHORITY=YES
ALREADY_SELFHOSTED=NO

SCALAR_INPUT_COMPLETE=YES
OUTPUT_RESULT_BOUNDED=YES

HOST_POINTER_IDENTITY_REQUIRED=NO
HOST_GRAPH_MUTATION=NO
SEMANTIC_CALLBACKS=0
NONLOCAL_RECOVERY=NO

PRODUCTION_CALL_PATH=YES
PRODUCTION_DELEGATION_FEASIBLE=YES
```

The existing output-pointer write must be classified as ABI output
storage, not automatically as host AST graph mutation.

A candidate is ineligible if it requires transferring an arbitrary AST
pointer or host allocation authority into PolyC.

### 6.3 Ranking

Apply the existing RECON03 lexicographic ranking:

```text
(R0, R1, R2, R3, R4, R5, R6)
```

Keep the original dimensional definitions.

Do not change the scores merely to prefer binary over unary or vice
versa.

Mandatory controls:

- Reversing candidate row order does not change the winner.
- Removing the winner reranks the remaining candidate correctly.
- An ineligible synthetic candidate with ideal ranking scores is
  rejected.
- Changing a relevant eligibility fact changes the computed eligibility
  outcome.
- The ranker cannot select a candidate excluded by the checker.
- The winner is the unique lexicographic minimum or a deterministic,
  contractually defined tie resolution.

Freeze exactly one:

```text
SELECTED_CANDIDATE_ID=CAND-019|CAND-020
SELECTED_FUNCTION=<actual name>
SELECTED_SOURCE_SHA256=<actual SHA>
SELECTED_POLYC_SYMBOL=<actual symbol>
SELECTED_ABI=<actual ABI>

SELECTED_PRODUCTION_CALLER_COUNT=<measured>
```

The non-selected candidate remains legacy C.

### 6.4 Enum mapping qualification

Extract enum numeric values from the live compiled `src/ast.h`
definitions rather than guessing their ordinal positions.

Construct the complete actual token-to-enum mapping from the real legacy
function.

Require:

```text
MAPPING_COUNT_EXACT=YES
ENUM_VALUES_BOUND_TO_LIVE_HEADER=YES
UNRECOGNIZED_TOKEN_RESULT=FAILURE
OUTPUT_UNCHANGED_ON_FAILURE=YES
```

The known source currently contains 19 binary mappings and 10 unary
mappings, but C1 must rederive the count from the actual entry tree.

Account for token aliases in `src/lexer.h`.  Do not collapse two
semantically distinct cases merely because their source spellings look
similar, and do not invent distinctions between aliased numeric tokens.

### 6.5 Real legacy C oracle

C1 must establish how to build and execute the **actual selected
function** with delegation disabled.

A hand-written duplicate switch is forbidden as the sole oracle.

Preferred authority:

```text
src/ast.c
  compiled with the selected PolyC delegation OFF
  actual ast*OpFromToken function
  actual Ast*Op enum definitions
```

A C test driver may call the real function, pass a preinitialized enum
output, and return the observed success flag and final enum value.

The driver must not contain its own mapping table.

Prove that the oracle object does not depend on the new PolyC symbol.

### 6.6 C1 freeze

Create:

```text
c1/
  candidate-inventory.tsv
  candidate-eligibility.tsv
  candidate-ranking.tsv
  ranking-controls.txt

  enum-values.tsv
  token-mapping.tsv
  ABI-contract.md

  oracle-linkage-contract.txt
  fixture-contract.tsv
  mutation-contract.txt
  production-seam.txt

  mandatory-ac-contract.tsv
  required-result.txt
```

Commit with `ACT-Phase: EVIDENCE`.

**No production implementation before this freeze.**

If neither candidate meets the required boundary, HALT with the actual
rejected dependency graph.  Do not select an ineligible candidate to
satisfy a preordained outcome.

---

## 7. Fixture contract

Fixtures must test both aspects of the original C API:

```text
(success, output_after_call)
```

### 7.1 Mandatory partitions

The selected fixture must contain:

| Partition | Requirement |
|---|---|
| M01 | Every accepted token mapped to its exact enum |
| M02 | Every accepted mapping repeated with a different initial output value |
| M03 | Unrecognized ASCII token values |
| M04 | Neighboring values around every accepted token constant |
| M05 | Relevant lexer aliases |
| M06 | Signed-I64 extremes and their neighbors |
| M07 | Duplicate/ambiguous source spellings, if present |
| M08 | Invalid input values that are not recognized operators |
| M09 | Output storage unchanged on every failure |
| M10 | Selected function exercised from a real production parser call path |

The exact canonical row count is **derived from the frozen values**, not
chosen in advance.

Use exact decimal signed-I64 formatting.  Do not use a 32-bit formatter
or fragment-scan digits from symbolic names.

### 7.2 Positive oracle semantics

For each valid token:

```text
success = 1
output_after_call = exact mapped enum
```

For each invalid token:

```text
success = 0
output_after_call = output_before_call
```

Require two distinct initialized output values for every invalid token
family to prove that the output was not overwritten with a hard-coded
default.

### 7.3 Fixture integrity

An independent verifier must check:

```text
EXPECTED_IDS=OBSERVED_IDS
EXPECTED_VALUES=OBSERVED_VALUES
EXPECTED_ROW_COUNT=OBSERVED_ROW_COUNT

DUPLICATE_IDS=0
UNKNOWN_IDS=0
MISSING_IDS=0
INVALID_NUMERIC_VALUES=0
SEMANTIC_PARTITION_GAPS=0
```

The verifier must not share the fixture producer's token-resolution code.

Require negative controls that reject:

1. Missing accepted token.
2. Duplicate fixture ID.
3. Unknown fixture ID.
4. Indented unknown row.
5. Out-of-range signed integer.
6. Correct row count but missing semantic value.
7. Invalid-token fixture whose output is incorrectly overwritten.
8. A changed expected enum value.

The controls must genuinely execute and fail, not merely assert that an
integrity check exists.

---

## 8. C2 -- PolyC implementation and production delegation

### 8.1 PolyC subject

Create:

```text
tools/bootstrap/selfhost-parser-slice04.HC
```

Implement only the selected mapping.

Required properties:

```text
NO_HOST_AST_POINTERS=YES
NO_ALLOCATION=YES
NO_GLOBAL_STATE=YES
NO_CALLBACKS=YES
NO_RECOVERY_DEPENDENCY=YES

PURE_DETERMINISTIC_MAPPING=YES
```

Compile the component using the appropriate stage0 compiler.

Do not make the stage0 bootstrap path depend on a PolyC component that
has not yet been built.

### 8.2 Production C delegation

Modify only the selected function in `src/ast.c`.

Use a dedicated component-selection macro, for example:

```text
HCC_USE_SELFHOST_PARSER_AST_BINOP
```

or

```text
HCC_USE_SELFHOST_PARSER_AST_UNARY
```

Select the actual name in C1, after the winner is known.

Production build default: ON.

Legacy stage0/oracle build: OFF.

Require:

- No C execution of the selected token-to-enum switch in production.
- No shadow call followed by the legacy decision.
- No silent fallback to C on missing component.
- No change to the other AST operator mapping.
- No change to AST allocation, enum definitions, parser recursion, or
  diagnostics.
- No write to the C output parameter when PolyC reports failure.

### 8.3 Build integration

Modify `src/CMakeLists.txt` and bounded helper CMake files if necessary.

Support producer and prebuilt-object modes where the existing build
architecture requires them.

Both must fail closed before producing a production compiler if the
selected component is missing, undefined-only, local-only, weak-only, or
multiply defined.

Use the platform's actual symbol spelling (Mach-O or ELF) and toolchain
`nm` semantics.

Do not equate the presence of a symbol name in `nm` output with a valid
strong global definition.

No stale verification stamp may bypass the current object check.

### 8.4 Real differential

Run a comparison against:

```text
G0_REAL_LEGACY_C_FUNCTION
vs
SELECTED_POLYC_COMPONENT
```

For every mandatory fixture, assert:

```text
LEGACY_SUCCESS=POLYC_SUCCESS
LEGACY_OUTPUT=POLYC_OUTPUT
EXPECTED_SUCCESS=LEGACY_SUCCESS
EXPECTED_OUTPUT=LEGACY_OUTPUT
```

For invalid tokens, additionally assert that the production adapter
preserves the caller's initial output value.

The differential must report concrete mismatched token values and
expected/observed enum values.

A zero exit caused by skipping missing rows is forbidden.

### 8.5 C2 evidence

```text
c2/
  component-source-sha.txt
  component-build-receipt.txt

  real-oracle-build.txt
  direct-differential.txt
  differential-negative-controls.txt
  fixture-integrity.txt

  production-delegation.txt
  fail-closed-build-controls.txt
  implementation-scope.txt
  required-result.txt
```

Commit C2 with `ACT-Phase: IMPL`.

---

## 9. C3 -- Four-generation qualification

### 9.1 Required generations

```text
G0  real legacy C mapping
G1  PolyC stage1 production mapping
G2  independently compiled PolyC stage2 mapping
G3  independently compiled PolyC stage3 mapping
```

Each generation must be independently compiled and independently executed.

For every generation record:

```text
generation
compiler_invocation
compiler_resolved_path
compiler_binary_sha256
compiler_version

source_path
source_sha256
exact_build_command

output_object_path
output_object_sha256

build_exit_code
execution_exit_code
semantic_output_sha256
build_receipt_identity
```

All paths, compilers, and commands must refer to actual executed subjects.

### 9.2 G0 provenance

The actual C compiler executable must be resolved and hashed.

Do not substitute `./hcc`'s SHA for the G0 C compiler.

The G0 raw build transcript, machine-readable manifest, and human-readable
summary must agree on compiler identity.

Required:

```text
G0_PRODUCER_FROM_ACTUAL_COMMAND=YES
G0_RAW_RECEIPT_MATCHES_MANIFEST=YES
G0_COMPILER_SHA_MATCHES_LIVE_BINARY=YES
```

### 9.3 Component comparisons

For PolyC generations:

```text
G1 vs G2 = BYTE_EQUAL
G1 vs G3 = BYTE_EQUAL
G2 vs G3 = BYTE_EQUAL
```

For G0 against each PolyC generation, require **semantic equality**, not
object-byte equality.

Record all six generation-pair comparisons with their appropriate
comparison kind.

No copying of G1 output into G2/G3 is allowed to satisfy independent
build requirements.

### 9.4 Production semantic comparisons

Build each generation's applicable compiler/runtime seam independently and
run the same frozen observation programs.

Require all six production semantic pairs to match.

The G0-vs-PolyC comparison must use the real legacy mapping.

### 9.5 Provenance negative controls

Verify that:

- Substituting G1's receipt for G3's is rejected.
- Omitting the G3 compiler execution receipt is rejected.
- Changing a recorded compiler SHA is rejected.
- Substituting a mutated, non-byte-identical component object is
  rejected.
- Swapping stage labels without changing their bound identities is
  rejected.

**Important distinction:** If G1 and G3 produce byte-identical objects,
replacing one finished object with the other is not detectable from the
output bytes alone.

Therefore, do not claim byte-identical substitution detection based
merely on `(object SHA, compiler SHA)` fields that an attacker or test can
copy or relabel.

Require an execution-linked provenance witness established during each
real independent build.  The negative control must corrupt or substitute
that witness and demonstrate rejection.

If the available build mechanism cannot establish that provenance, HALT
the provenance criterion rather than manufacturing a stronger claim.

---

## 10. Production-causal mutation

A mapping differential alone is insufficient.

The selected PolyC function must be proven load-bearing in the **real
production compiler**.

### 10.1 Freeze one mutation in C1

If CAND-019 wins, prefer a bounded mutation of a well-supported binary
operator, such as mapping `+` to the legacy enum for subtraction.

If CAND-020 wins, prefer a bounded mutation of a well-supported unary
operator, such as mapping unary minus to unary plus.

The actual mutation and observation must be frozen in C1 using a compiled
program known to exercise the chosen path.

Do not assume the illustrative mutations are safe without checking the
live implementation and language semantics.

### 10.2 Mandatory sequence

```text
A. Pristine component
   build -> link -> compile observation -> execute

B. Mutated component
   build -> link -> compile SAME observation -> execute

C. Restored pristine component
   build -> link -> compile SAME observation -> execute
```

Required:

```text
A_BUILD_RC=0
A_EXEC_RC=0

B_BUILD_RC=0
B_EXEC_RC=0
B_OUTPUT_DIFFERS_FROM_A=YES

C_BUILD_RC=0
C_EXEC_RC=0

C_OUTPUT_EQUALS_A=YES
C_COMPONENT_SHA_EQUALS_A=YES
```

Record every executable identity, output, and SHA.

A failed mutant build is not a successful causal control.

Use isolated scratch workspaces so the tracked PolyC subject is never
mutated.

### 10.3 Production authority verification

The production `ast.c` object must reference the selected PolyC symbol.

The final compiler must provide a strong definition of that symbol.

The legacy selected mapping body must be absent from the
production-compiled conditional path.

A retained C ABI wrapper is allowed only for argument projection, success
conversion, and conditional output storage.

The unselected legacy classifier remains unchanged.

---

## 11. Conservation

The correction entry commit is the conservation baseline, not a historical
HANDOFF's claimed result.

### 11.1 Selected mapping

```text
DIRECT_DIFFERENTIAL_FAILURES=0
OUTPUT_PRESERVATION_FAILURES=0
ENUM_MAPPING_MISMATCHES=0
```

### 11.2 Other operator mapping

The non-selected function must pass its legacy-oracle comparison unchanged.

```text
UNSELECTED_MAPPING_SEMANTIC_DELTA=0
```

### 11.3 Previous PolyC parser authorities

Verify production delegation remains active for:

```text
BootstrapCalcPadding
BootstrapValidPostControlFlowToken
BootstrapOperatorPrecedence
```

Require zero source-hash changes to these qualified PolyC subjects and no
new failure identities in their existing differentials and
causal/production seams.

### 11.4 Parser suite

Execute the canonical current parser suite against:

- The compiler built from ENTRY_HEAD.
- The compiler built after SLICE04 implementation.

Compare individual result identities.

Require:

```text
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_PARSER_SEMANTIC_REGRESSIONS=0
```

Do not suppress the pre-existing `/usr/local/include/tos.HH`
installation-prefix failures.

Record them exactly and preserve the distinction between a failing
historical suite and zero newly introduced regressions.

### 11.5 Lexer conservation

Execute current LEXER01..04 qualification targets.

Run the actual LEXER07 broad corpus, and compare against:

```text
docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
```

Record:

```text
BASELINE_FAILURE_IDENTITIES
CURRENT_FAILURE_IDENTITIES
NEW_FAILURE_IDENTITIES
REMOVED_FAILURE_IDENTITIES
```

Preserve an overall `STATUS=FAIL` for the historical corpus if that is its
real result.  Do not turn known old failures into a fabricated green
corpus.

Required:

```text
NEW_LEXER_FAILURE_IDENTITIES=0
NEW_LEXER07_FAILURE_IDENTITIES=0
```

---

## 12. Factory gates

Run the real current targets:

```sh
make gate-fast
make gate-push

sh scripts/quality/factory-v2-test.sh
sh scripts/quality/factory-append-only-test.sh
```

Also execute the available F-NO-PYTHON and F-POLYC-TOOLS checks.

Record baseline violations separately from newly introduced violations.

Run:

```sh
git diff --check <ENTRY_HEAD>..HEAD
```

Check that all tracked mutations fall within section 3.

Check F14 conservation against closed ACT, HANDOFF, and evidence surfaces.

### Gate truth

A gate that returns nonzero is not PASS.

A result from a different compiler identity, stale build, synthetic
fixture, or prior commit does not establish the gate for the current
implementation.

No `--no-verify`, skipped hooks, silent fallback, fabricated log, or
prose waiver.

---

## 13. C3 evidence

Commit under:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c3/
```

Required artifacts:

```text
generation-manifest.tsv
generation-build-receipts.tsv
generation-object-pairs.tsv
generation-semantic-pairs.tsv
generation-provenance.txt

copy-forgery-negative-controls.txt

production-authority.txt
production-causal-mutation.txt
pristine-restoration.txt

direct-differential.txt
fixture-integrity.txt
fixture-negative-controls.txt

unselected-mapping-conservation.txt
parser-conservation.txt
lexer-conservation.txt
lexer07-delta.txt

gate-fast.txt
gate-push.txt
factory-v2.txt
append-only.txt

f-no-python.txt
f-polyc-tools.txt
f14.txt
patch-hygiene.txt

mandatory-ac-status.tsv
required-result.txt
```

Every PASS in the acceptance ledger must refer to evidence that actually
establishes the predicate.

The ledger must be generated or independently audited by exact
acceptance-ID joins, not by relying on line order.

Commit C3 with `ACT-Phase: EVIDENCE`.

---

## 14. Mandatory acceptance criteria

The following 50 predicates are binding.

| ID | Predicate |
|---|---|
| AC01 | Live entry identity established |
| AC02 | Worktree clean at entry |
| AC03 | Predecessor closure reachable |
| AC04 | Previous AC-count drift acknowledged |
| AC05 | Previous G0 receipt contradiction acknowledged |
| AC06 | F14 predecessor surfaces preserved |
| AC07 | Both AST mapping candidates inventoried from live source |
| AC08 | Both candidates' dependencies fully classified |
| AC09 | Full eligibility predicates mechanically applied |
| AC10 | Ranking uses original R0..R6 dimensions |
| AC11 | Ranking and eligibility negative controls pass |
| AC12 | Exactly one eligible winner selected |
| AC13 | Selected production call sites verified |
| AC14 | Selected ABI is bounded and unambiguous |
| AC15 | Enum values bound to live `src/ast.h` |
| AC16 | No failure-sentinel collision |
| AC17 | Legacy success semantics frozen |
| AC18 | Legacy output-unchanged-on-failure semantics frozen |
| AC19 | Real legacy-C oracle executes |
| AC20 | Oracle compiled with PolyC delegation disabled |
| AC21 | All mandatory accepted tokens exercised |
| AC22 | Rejected-token and integer-boundary coverage complete |
| AC23 | Independent fixture-integrity verifier passes |
| AC24 | Fixture-integrity negative controls fire |
| AC25 | PolyC component implements frozen ABI |
| AC26 | Stage0 compilation of the subject succeeds |
| AC27 | Direct differential has zero mismatches |
| AC28 | Direct differential negative controls fire |
| AC29 | Output parameter remains unchanged on failure |
| AC30 | Production delegation is load-bearing |
| AC31 | Selected legacy C decision retired from production |
| AC32 | Build rejects missing/invalid PolyC object |
| AC33 | Unselected legacy mapping unchanged |
| AC34 | G0 actual C compiler identity verified |
| AC35 | G0-G3 independent builds and executions proven |
| AC36 | Component pair comparisons satisfy frozen contract |
| AC37 | All six production semantic pairs equivalent |
| AC38 | Generation provenance receipts consistent and verified |
| AC39 | Provenance forgery/omission negative controls fire |
| AC40 | Production mutation builds, links and changes observable output |
| AC41 | Pristine restoration produces identical output and subject SHA |
| AC42 | Previous three PolyC parser authorities conserved |
| AC43 | No new parser failure identities |
| AC44 | No new lexer or LEXER07 failure identities |
| AC45 | No newly introduced Python or disallowed tool violations |
| AC46 | Factory-v2, append-only and F14 checks pass |
| AC47 | `make gate-fast` passes |
| AC48 | `make gate-push` passes |
| AC49 | Tracked mutation scope and committed-range patch hygiene pass |
| AC50 | Valid closure, accurate ledger and external terminality |

### Ledger requirements

```text
AC_TOTAL=50
AC_ID_UNIQUE=YES
AC_MISSING=0
AC_DUPLICATE=0

AC_PASS=50
AC_FAIL=0
AC_UNPROVEN=0
```

At C3, AC50 may be `DEFERRED_TO_CLOSE` with the reason recorded
explicitly.

The final PASS requires its actual post-CLOSE satisfaction.

A summary counter is not itself proof that 50 predicates exist or pass.
Recompute the count from the actual AC-ID rows and independently check
evidence bindings.

---

## 15. HALT taxonomy

Use the narrowest truthful halt:

```text
HALT_ENTRY_IDENTITY_INVALID
HALT_PREDECESSOR_CONTRACT_UNBOUND
HALT_F14_VIOLATION

HALT_NO_ELIGIBLE_AST_OPERATOR
HALT_RANKING_INCONSISTENT
HALT_AMBIGUOUS_ABI
HALT_ENUM_SENTINEL_COLLISION

HALT_REAL_C_ORACLE_UNAVAILABLE
HALT_FIXTURE_COVERAGE_INCOMPLETE
HALT_DIFFERENTIAL_MISMATCH

HALT_PRODUCTION_NOT_LOAD_BEARING
HALT_LEGACY_AUTHORITY_NOT_RETIRED
HALT_INVALID_BUILD_SUBJECT

HALT_GENERATION_NOT_INDEPENDENT
HALT_PROVENANCE_NOT_PROVEN
HALT_NEGATIVE_CONTROL_NOT_LOAD_BEARING

HALT_MUTATION_NOT_CAUSAL
HALT_PRISTINE_NOT_RESTORED

HALT_CONSERVATION_REGRESSION
HALT_SCOPE_CONTRACT_VIOLATED
HALT_FACTORY_GATE_NOT_GREEN
HALT_MANDATORY_AC_NOT_GREEN
```

The previous three qualified parser components must not be removed merely
because SLICE04 halts.

If the implementation exposes a real unrelated compiler defect, capture it
as residue or create a bounded dependency HALT when it prevents mandatory
proof.  Do not redesign unrelated compiler functions inside this ACT.

---

## 16. C4 -- CLOSE

On successful C3 verification, commit:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE04.md
```

Append the managed mapping in:

```text
docs/factory/act-handoff-map.tsv
```

Update `docs/ROADMAP.md`.

The HANDOFF must identify:

1. Actual ENTRY_HEAD.
2. Two candidate classifications.
3. Mechanically selected winner.
4. Frozen ABI and enum mapping.
5. C oracle and fixture contract.
6. Production delegation.
7. Generation provenance and comparisons.
8. Causal mutation.
9. Conservation and Factory gates.
10. Honest residue.
11. Remaining unmigrated AST mapping.
12. Next candidate or next bounded reconnaissance requirement.

The HANDOFF is a summary, not terminal verdict authority.

### Commit topology

Use five contiguous, forward-only phase commits:

```text
C0 RED
C1 EVIDENCE
C2 IMPL
C3 EVIDENCE
C4 CLOSE
```

Use one parseable trailer block per commit.

For C4:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE04
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

No amend, reset, rebase, force-push, or post-C4 cleanup commit.

If a mandatory issue is discovered before C4, repair it in the authorized
implementation/evidence phase if possible.  Otherwise use the appropriate
HALT.

---

## 17. External terminality

After the CLOSE commit exists, run read-only checks:

```sh
git status --porcelain=v1
git replace -l

git diff --check <ENTRY_HEAD>..HEAD

sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-SLICE04 HEAD

git log -1 --format='%B' |
  git interpret-trailers --parse
```

Require:

```text
FACTORY_V2_RANGE_CHECK=PASS
WORKTREE_CLEAN=YES
PATCH_HYGIENE_ERRORS=0

CLOSE_IS_ACT_TIP=YES
POST_CLOSE_CONTINUATION=NO
```

No terminality evidence is added to a closed evidence tree after CLOSE.

---

## 18. Required result

The successful terminal result must be equivalent to:

```text
ACT=ACT-POLYC-SELFHOST-PARSER-SLICE04
VERDICT=PASS

SELECTED_CANDIDATE_COUNT=1
SELECTED_CANDIDATE_ELIGIBLE=YES

SELECTED_AST_OPERATOR_AUTHORITY=POLYC
SELECTED_LEGACY_C_AUTHORITY=RETIRED
OTHER_AST_OPERATOR_AUTHORITY=LEGACY_C

ABI_CORRECT=YES
RESULT_ON_SUCCESS_CORRECT=YES
OUTPUT_UNCHANGED_ON_FAILURE=YES

DIRECT_DIFFERENTIAL=PASS
FIXTURE_INTEGRITY=PASS
FIXTURE_NEGATIVE_CONTROLS=PASS

G0_REAL_C_ORACLE=YES
G1_G2_G3_INDEPENDENT=YES
G0_G3_PROVENANCE=PASS
GENERATION_SEMANTICS=PASS
PROVENANCE_CONTROLS=PASS

PRODUCTION_DELEGATION=LOAD_BEARING
PRODUCTION_CAUSAL_MUTATION=PASS
PRISTINE_RESTORATION=PASS

EXISTING_PARSER_POLYC_COMPONENTS=CONSERVED
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_LEXER_FAILURE_IDENTITIES=0
PRODUCTION_SEMANTIC_DELTA=0

MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=50
MANDATORY_AC_FAIL=0

GATE_FAST=PASS
GATE_PUSH=PASS
FACTORY_V2=PASS
APPEND_ONLY=PASS
F14=PASS
PATCH_HYGIENE=PASS
POST_CLOSE_CONTINUATION=NO
```

No selected symbol, fixture count, generated SHA, ranking result, or test
result may be inserted as a claimed observation before it is actually
measured.

---

## 19. Successor direction

SLICE04 migrates only one of the two shortlisted AST classifiers.

The other remains a natural follow-up candidate.

A later `ACT-POLYC-SELFHOST-PARSER-SLICE05` may migrate it, but only after
SLICE04's production authority and proof obligations are fully
established.

Do not implement both classifiers opportunistically within SLICE04.

---

## 20. Execution directive

**Execute the whole ACT, C0 through C4.**

Prioritize actual compiler implementation over document maintenance.

The essential engineering goal is not to add a PolyC symbol or pass a
standalone mapping test; it is to make an actual production parser
decision depend on that PolyC function while preserving the original C
API behavior.

In particular:

- Select one candidate mechanically.
- Derive the mapping from actual legacy source and enum values.
- Implement the PolyC decision.
- Make production C call it.
- Retire the selected C decision.
- Prove output-preservation semantics.
- Execute the real C differential.
- Independently build and execute G0-G3.
- Prove a production-causal mutation.
- Preserve all existing migrations.
- Close only with mechanically truthful evidence.

**A successful SLICE04 moves another real compiler semantic authority into
PolyC.**
