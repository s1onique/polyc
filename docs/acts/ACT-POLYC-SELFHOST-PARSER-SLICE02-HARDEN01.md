# ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Harden the build and qualification mechanisms of the
already-migrated PolyC control-flow-token component so that an
incorrect object, an incomplete fixture set, a malformed input, or an
unsupported symbol-table configuration cannot produce a false PASS

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** SELFHOST / PARSER / PRODUCTION-QUALIFICATION-HARDENING

**Priority:** P1 — before the next parser authority migration

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE02` (closed `PASS`)

**Successor:** `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03`

**Entry HEAD:** `da4ab7db9e9f4382f53514db7678b86ca6c6416f`
(the predecessor's CLOSE commit)

---

## 0. Mission

Strengthen the already-migrated PolyC control-flow-token component's
build and qualification mechanisms so that incorrect objects,
incomplete fixture sets, malformed inputs, and unsupported symbol-table
configurations cannot produce a false PASS.

Preserve the successful production-authority transfer:

```text
CONTROL_FLOW_TOKEN_PRODUCTION_AUTHORITY = POLYC
LEGACY_C_PRODUCTION_AUTHORITY           = RETIRED
BootstrapValidPostControlFlowToken     = LOAD_BEARING
```

This ACT is **not** a semantic migration and **not** a retrospective
closure-verdict rewrite.

It repairs three qualification mechanisms, verifies their negative
controls, runs the canonical conservation suites, and hands off to the
next parser-slice reconnaissance ACT.

Successful execution must establish:

```text
OBJECT_VERIFICATION              = FAIL_CLOSED
OBJECT_PRODUCER_MODES           = VERIFIED
SYMBOL_FORMATS                  = MACH_O_AND_ELF
DIFFERENTIAL_FIXTURE_AUTHORITY   = COMPLETE
INTEGER_PARSER_BOUNDARIES       = SAFE
NEGATIVE_CONTROLS               = PASS
PRODUCTION_AUTHORITY            = POLYC
PRODUCTION_SEMANTIC_DELTA       = 0
PARSER_CONSERVATION             = PASS_AGAINST_ENTRY
FACTORY_GATES                   = PASS
NEXT_ACT                        = ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
```

---

## 1. Entry identity

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git log -8 --format='%H %s'
git replace -l
```

Observed at C0 (`evidence/.../c0/entry-identity.txt`):

```text
BRANCH                        = main
ENTRY_HEAD                    = da4ab7db9e9f4382f53514db7678b86ca6c6416f
WORKTREE_CLEAN                = YES (no tracked-file modification)
GIT_REPLACE_REFS              = 0
PREDECESSOR_CLOSE_REACHABLE   = YES
ACTIVE_CONFLICTING_FACTORY_ACT= NONE
```

The entry equals the predecessor's CLOSE commit, so there is nothing to
reconcile.

---

## 2. Scope

### Allowed production and qualification files

```text
src/cmake/VerifyControlFlowTokenObject.cmake
src/CMakeLists.txt
tools/quality/parser-control-flow-token-differential.HC
Makefile
```

New small, directly related test fixtures or PolyC-native quality tools
are permitted if required for executable negative controls.

### Read-only surfaces

```text
src/parser.c
src/lexer.h
tools/bootstrap/selfhost-parser-control-flow-token.HC
tools/quality/parser-slice02-oracle.c
tools/quality/parser-slice02-oracle.h
tools/quality/parser-control-flow-token-oracle-impl.c
tools/bootstrap/selfhost-parser-padding.HC
docs/factory/LEXER07-BASELINE-AUTHORITY.tsv
```

### Forbidden

- Changing `BootstrapValidPostControlFlowToken` semantics.
- Changing the frozen ABI.
- Changing the 42 canonical fixture expectations.
- Editing historical SLICE02 evidence or HANDOFF.
- Replacing the real legacy-C oracle with a mocked oracle.
- Disabling or weakening any existing negative control.
- Adding Python.
- Adding substantive C or shell quality tooling contrary to F-POLYC-TOOLS.
- Modifying the LLVM backend, lexer authority, parser recovery semantics,
  or AST representation.
- Altering Factory gate scripts, trailer validators, or hooks.
- Claiming Linux production qualification from a macOS-only test.

Use PolyC for substantive new qualification logic. CMake may be used for
native build validation.

---

## 3. Defect D1 — Symbol verifier is fail-open

### 3.1 Current implementation

`src/cmake/VerifyControlFlowTokenObject.cmake` defaults to:

```cmake
set(
  CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL
  "_BootstrapValidPostControlFlowToken"
)
```

It invokes `nm` and searches its raw output with a prefix-style
regular expression.

Three defects follow.

**D1-A — Platform-dependent symbol spelling.** Mach-O commonly exposes a
leading underscore for this C symbol. ELF normally exposes the unmangled
name without that prefix. A perfectly valid ELF object can therefore be
rejected solely because of its platform.

**D1-B — Undefined symbols accepted.** The current search does not
require a definition. An object containing
`U _BootstrapValidPostControlFlowToken` can satisfy the textual match
despite containing no implementation.

**D1-C — Prefix collisions accepted.** A symbol such as
`T _BootstrapValidPostControlFlowTokenExtra` can match the expected name
prefix.

### 3.2 Required implementation

Rewrite the verification to establish a complete symbol identity:

```text
SYMBOL_NAME_EXACT         = YES
SYMBOL_IS_DEFINED        = YES
SYMBOL_IS_GLOBAL         = YES
SYMBOL_IS_CODE           = YES
SYMBOL_DEFINITION_COUNT  = 1
OBJECT_NONEMPTY          = YES
NM_EXECUTION_SUCCESSFUL  = YES
```

The canonical logical symbol remains `BootstrapValidPostControlFlowToken`.
Resolve its object-format spelling using the target toolchain/object
format, rather than assuming host macOS naming. Use the configured
toolchain's `CMAKE_NM` when available. Pass required tool and
target-format information explicitly from `src/CMakeLists.txt` to the
verification script. Do not silently substitute a host `nm` during a
cross-compile if the target object cannot be inspected correctly.

The verifier must parse the complete symbol-table record. It must reject:
`U` (undefined reference); lowercase `t` (local text symbol); weak or
common declarations that are not the required strong external code
definition; symbols that merely contain the target name as a substring;
symbols with extra prefixes or suffixes beyond the target-format
spelling; empty files; invalid objects; missing or failing `nm`; and
multiple matching definitions.

Expected success:

```text
CONTROL_FLOW_TOKEN_OBJECT_STATUS=PASS
EXPECTED_SYMBOL=BootstrapValidPostControlFlowToken
DEFINED_GLOBAL_TEXT_SYMBOL_COUNT=1
```

Failure must include a concrete reason token:

```text
REJECT_UNDEFINED_SYMBOL
REJECT_LOCAL_SYMBOL
REJECT_SYMBOL_NAME_MISMATCH
REJECT_DUPLICATE_DEFINITION
REJECT_INVALID_OBJECT
REJECT_UNSUPPORTED_OBJECT_FORMAT
REJECT_NM_FAILURE
```

---

## 4. Defect D2 — Verification depends on the producer configuration

The current CMake build graph has two modes:

```text
Mode A: CONTROL_FLOW_TOKEN_PRODUCER specified
Mode B: pre-existing CONTROL_FLOW_TOKEN_OBJECT supplied
```

In Mode A, the producer path schedules object verification. In Mode B, the
existing logic checks only that the object exists during configuration.

### Required repair

Both paths must converge on the same verifier before linking production
`hcc`:

```text
                        +-----------------------+
                        | PolyC component object|
                        +-----------------------+
                                   |
                     +-------------+-------------+
                     |                           |
               Producer mode              Prebuilt-object mode
                     |                           |
                     +-------------+-------------+
                                   |
                           Strict verifier
                                   |
                           Verified symbol
                                   |
                            Production hcc
```

Required behavior:

```text
PRODUCER_MODE_VERIFY=YES
PREBUILT_MODE_VERIFY=YES

MISSING_OBJECT=REJECTED
EMPTY_OBJECT=REJECTED
WRONG_SYMBOL=REJECTED
UNDEFINED_SYMBOL=REJECTED
VALID_OBJECT=ACCEPTED
```

Verification must run before linking when the object content changes. A
stale `.verified` stamp must not turn an altered or replaced object into
an accepted object. Prefer a build-graph arrangement that performs the
verification on each relevant production build, or use an equally strong
content-sensitive invalidation mechanism.

Do not compile a replacement C implementation when the PolyC object fails
verification.

### Mode B negative control

Supply a non-empty object containing only an undefined reference to the
expected symbol. Expected outcome:

```text
CMAKE_CONFIGURE_OR_BUILD = FAIL
PRODUCTION_HCC_LINKED    = NO
FALLBACK_TO_LEGACY_C     = NO
```

Repeat with a valid object to prove the gate accepts genuine production
inputs.

---

## 5. Defect D3 — Differential can pass on incomplete fixtures

### 5.1 Current condition

The PolyC differential currently returns PASS when:

```text
fail == 0
parse_errors == 0
oracle_vs_expected_mismatch == 0
```

It does not require the complete canonical 42-fixture set. A fixture
containing only one passing row produces
`TOTAL=1 PASS=1 FAIL=0 STATUS=PASS`. Likewise, removing F041 leaves 41
passing rows and conceals loss of the aliasing control.

### 5.2 Required acceptance contract

```text
EXPECTED_FIXTURE_COUNT = 42
OBSERVED_FIXTURE_COUNT = 42

FIXTURE_IDS_UNIQUE      = YES
FIXTURE_IDS_COMPLETE    = YES
FIXTURE_SCHEMA_VALID    = YES

ORACLE_VS_EXPECTED_MISMATCH = 0
SUBJECT_VS_ORACLE_MISMATCH  = 0
PARSE_ERRORS               = 0

STATUS=PASS
```

The canonical ID set is exactly `F001..F042`. Each ID must occur exactly
once, independent of row order. Require exact field parsing for the
declared TSV schema. Reject malformed, empty, truncated, duplicated,
unknown-ID, or otherwise incomplete fixture rows. Do not infer that a
skipped or unparseable row was successfully checked. An input with zero
candidate rows must return nonzero.

### 5.3 Negative controls

| Control | Mutation | Expected |
|---|---|---|
| NC-D1 | Remove F041 | FAIL — missing ID |
| NC-D2 | Remove another fixture | FAIL — incomplete set |
| NC-D3 | Duplicate F041 while omitting F042 | FAIL — duplicate and missing IDs |
| NC-D4 | Replace F041 with unknown F043 | FAIL — unknown and missing ID |
| NC-D5 | Empty fixture file | FAIL |
| NC-D6 | Malformed integer | FAIL |
| NC-D7 | Truncate fixture row | FAIL |
| NC-D8 | Supply a valid 42-row fixture in shuffled order | PASS |
| NC-D9 | Use predecessor matrix with F041 expected 0 | FAIL — oracle/expected disagreement |
| NC-D10 | Deliberately change the PolyC subject | FAIL — subject/oracle disagreement |

No new test may remove or weaken the existing M1..M4 mutation controls.

The positive control must use the actual corrected fixture file:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/c1/c1-corrected-fixture-model.tsv
```

That file is read-only.

---

## 6. Defect D4 — Signed integer parser overflow

The existing PolyC fixture parser accumulates signed integers
approximately as:

```c
I64 v = 0;
v = v * 10 + digit;
if (negative) v = -v;
```

The frozen matrix includes `-9223372036854775808` and
`9223372036854775807`. A signed accumulator cannot safely represent the
positive magnitude of `INT64_MIN` before negation.

### Required behavior

Accept exactly representable `I64` values, including:

```text
INT64_MIN = -9223372036854775808
INT64_MAX =  9223372036854775807
```

Reject out-of-range values, including:

```text
-9223372036854775809
 9223372036854775808
```

Use checked accumulation with a suitable unsigned magnitude
representation or another mechanically validated PolyC-safe approach.
Check the limit before multiply/add. Do not rely on signed wraparound,
undefined behavior, or compiler-specific overflow folding. Cover decimal
and hexadecimal inputs, including leading signs where supported by the
existing contract. The integer parser must also reject trailing garbage
and missing digits.

Required tokens:

```text
SIGNED_BOUNDARY_MIN=PASS
SIGNED_BOUNDARY_MAX=PASS
POSITIVE_OVERFLOW_REJECTED=YES
NEGATIVE_OVERFLOW_REJECTED=YES
HEX_BOUNDARY=PASS
TRAILING_GARBAGE_REJECTED=YES
```

The correction must affect only input parsing within the quality
verifier. The production PolyC component's ABI and logic remain untouched.

---

## 7. Legacy oracle conservation

Keep the existing actual production-function cross-check. The previous
SLICE02 qualification recorded:

```text
CROSS_ROWS=326
CROSS_SAME=326
CROSS_DIFF=0
```

C3 must reproduce or extend it. The oracle must remain bound to the live
`src/lexer.h` constants and the real legacy function behavior. Do not
substitute a handwritten decision table as the terminal oracle. A copied
legacy body may remain as the existing test adapter only while its
equivalence to the original production function is independently checked.

Retain the corrected F041 expectation (`kind=0x301`, `value=42`,
`expected=1`). Do not alter the fixture to accommodate a production
implementation.

---

## 8. Production-authority conservation

Prove that hardening did not inadvertently undo the SLICE02 migration.
Freeze the production source and component hashes at C0. At C3 require:

```text
BootstrapValidPostControlFlowToken_SOURCE_SHA_DELTA=0

CONTROL_FLOW_TOKEN_PRODUCTION_AUTHORITY=POLYC
LEGACY_C_PRODUCTION_AUTHORITY=RETIRED

PRODUCTION_DELEGATION=YES
PRODUCTION_CAUSAL_MUTATION=DETECTED
PRISTINE_RESTORATION=PASS
```

The production binary must call the PolyC symbol. Reproduce the existing
causal control using a disposable mutated component built in an isolated
scratch directory: build pristine; build a valid, linkable mutant; confirm
the mutant object has a different SHA; link a real production-seam
compiler with the mutant; compile the same parser fixture with pristine
and mutant compilers; observe the expected semantic difference; rebuild or
restore pristine; confirm pristine output returns.

Do not use a compile failure or a missing mutant binary as evidence of
semantic divergence. A mere `nm` match or disassembly reference is not
sufficient.

---

## 9. Platform qualification

Target at least:

```text
Darwin / Mach-O / ARM64
Linux  / ELF    / x86_64 or aarch64
```

On each available native runner, test: actual object format; correct
target-specific symbol spelling; global text definition; undefined symbol
rejection; near-match rejection; prebuilt and producer-mode verification;
valid production link.

Use genuinely compiled objects for the positive controls. A synthetic
textual `nm` output may test parser behavior, but does not substitute for
a native object/link test.

If Linux is unavailable locally, do not claim native Linux qualification.
Use a real Linux CI runner or an existing compatible execution environment.
Record per-platform status independently. The ACT's platform-portability
acceptance predicate cannot be marked PASS while a mandatory platform
remains untested.

Do not introduce a container runtime, CI service, or infrastructure
dependency solely for this ACT without separately authorized scope.

---

## 10. Canonical parser conservation

This is a mandatory part of the ACT, not optional residue. Inspect the
current Makefile targets and existing test harness first. Run the canonical
parser-oriented test suite against the actual post-hardening production
compiler. Preserve the previously recorded reference:

```text
PARSER_FILES=67
PARSER_ASSERTIONS=363
PARSER_COMPILE_FAILURES=0
PARSER_RUN_FAILURES=0
```

Compare actual test identities as well as totals. A different test count
requires explicit investigation rather than automatic acceptance.

Also execute:

```sh
make parser-padding-test
make static-function-linkage-test
make gate-fast
make gate-push
```

Run the existing control-flow-token differential and parser-padding
differential through the supported build targets or binaries. The previous
parser-padding differential reference is:

```text
TOTAL=16640
PASS=16640
FAIL=0
```

Run the canonical `make unit-test` target without silently changing its
expected meaning. If host installation behavior or `39_arg_count.HC` still
fails: capture actual failure commands and outputs; compare against the
frozen entry baseline; separate pre-existing failures from new ones;
require zero new failures; do not change `src/tests/run.HC` inside this
ACT; do not report a failed complete suite as `STATUS=PASS`.

For LEXER07, use the prospective baseline authority registry and compare
failure-source identities, not merely aggregate counts. Known pre-existing
failures are recorded separately.

---

## 11. Factory-v2 lifecycle

Use meaningful, contiguous, forward-only commits.

### C0 — AUTH / RED

Capture entry identity, SHA baselines, source scope and the actual
failing predicates D1..D4. Required evidence:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01/c0/
  entry-identity.txt
  source-freeze.tsv
  predecessor-binding.txt
  scope.txt
```

Capture the pre-repair negative controls as actual observed behavior. Do
not assert RED based only on reading source.

### C1 — CONTRACT / NEGATIVE CONTROL

Freeze:

```text
c1/
  object-symbol-contract.tsv
  object-negative-controls.tsv
  differential-negative-controls.tsv
  integer-boundary-contract.tsv
  platform-matrix.tsv
  conservation-baseline.tsv
  required-result.txt
```

All negative-control expectations must be explicit before implementation.
The C1 evidence must identify which controls reproduce against the
original SLICE02 implementation. A RED that unexpectedly passes must be
investigated, not silently reported as reproduced.

### C2 — IMPLEMENTATION

Implement the minimal qualified changes:

```text
src/cmake/VerifyControlFlowTokenObject.cmake
src/CMakeLists.txt
tools/quality/parser-control-flow-token-differential.HC
```

Extend Makefile targets only as necessary to expose repeatable hardening
tests. New PolyC-native test logic is allowed under the frozen scope. Do
not modify the production PolyC subject or parser decision.

### C3 — VERIFY

Rerun every negative and positive control against the post-C2 tree.
Record:

```text
c3/
  symbol-verifier-positive.txt
  symbol-verifier-negative.txt
  producer-mode.txt
  prebuilt-mode.txt
  platform-matrix.txt

  fixture-integrity.txt
  differential-positive.txt
  differential-negative.txt
  integer-boundaries.txt

  production-authority.txt
  production-causal-mutation.txt
  oracle-crosscheck.txt

  parser-conservation.txt
  lexer07-conservation.txt
  parser-padding-conservation.txt

  gate-fast.txt
  gate-push.txt
  factory-v2.txt
  append-only.txt
  f14-conservation.txt
  f-no-python.txt
  f-polyc-tools.txt
  patch-hygiene.txt

  mandatory-ac-status.tsv
  required-result.txt
```

Evidence must contain actual commands, return codes, relevant outputs, and
file identities. A PASS ledger entry without an establishing witness is
insufficient.

### C4 — CLOSE

Create the HANDOFF, append its managed factory manifest row and update the
roadmap. The HANDOFF must describe: defects reproduced; production repairs
made; negative controls executed; platform coverage actually achieved;
parser and lexer conservation; remaining independent defects; successor
ACT.

The CLOSE commit carries the final Factory-v2 verdict. No predicted CLOSE
SHA inside the containing commit. After CLOSE, perform read-only external
terminality verification. Do not create a cleanup commit.

---

## 12. Mandatory acceptance criteria

| AC | Predicate |
|---|---|
| AC01 | Clean entry and predecessor identity |
| AC02 | Authorized scope frozen before implementation |
| AC03 | D1 original fail-open behavior reproduced |
| AC04 | D2 prebuilt-object verification gap reproduced |
| AC05 | D3 incomplete-fixture false PASS reproduced |
| AC06 | D4 integer boundary issue reproduced or its risk mechanically resolved |
| AC07 | Exact symbol name checked |
| AC08 | Undefined, local, weak and near-match symbols rejected |
| AC09 | One global strong text definition required |
| AC10 | Invalid, missing, empty objects rejected |
| AC11 | Target-format-aware name selection |
| AC12 | Correct toolchain `nm` used |
| AC13 | Producer mode invokes verifier |
| AC14 | Prebuilt mode invokes verifier |
| AC15 | Stale verification stamp cannot bypass checking |
| AC16 | All canonical 42 fixture IDs required |
| AC17 | Duplicate and missing fixture IDs rejected |
| AC18 | All malformed TSV controls detected |
| AC19 | Predecessor incorrect F041 matrix rejected |
| AC20 | Corrected fixture matrix 42/42 PASS |
| AC21 | Existing four subject mutations still detected |
| AC22 | Signed `I64` bounds handled correctly |
| AC23 | Overflowing and malformed integers rejected |
| AC24 | Legacy oracle cross-check conserved |
| AC25 | PolyC component source and frozen ABI unchanged |
| AC26 | Production compiler still delegates to PolyC |
| AC27 | Production causal mutation detected and pristine restored |
| AC28 | Platform matrix honestly satisfied |
| AC29 | Canonical parser suite executed |
| AC30 | No new parser or lexer failures |
| AC31 | Parser-padding differential conserved |
| AC32 | Factory-v2 suite passes |
| AC33 | Append-only suite passes |
| AC34 | gate-fast passes |
| AC35 | Unmodified gate-push passes |
| AC36 | No new F-NO-PYTHON violations |
| AC37 | No new F-POLYC-TOOLS violations |
| AC38 | F14 closed surfaces untouched |
| AC39 | Committed-range patch hygiene clean |
| AC40 | C4 HANDOFF and managed registry valid |
| AC41 | External terminality verified after CLOSE |

AC41 remains DEFERRED until a real CLOSE commit exists. All other
mandatory ACs must be PASS before claiming successful closure.

---

## 13. HALT taxonomy

```text
HALT_ENTRY_IDENTITY_INVALID

HALT_RED_NOT_REPRODUCED
HALT_SCOPE_CONTRACT_VIOLATED
HALT_UNAUTHORIZED_PRODUCTION_MUTATION

HALT_OBJECT_VERIFIER_NOT_FAIL_CLOSED
HALT_UNDEFINED_SYMBOL_ACCEPTED
HALT_PREBUILT_MODE_UNVERIFIED
HALT_PLATFORM_NOT_QUALIFIED

HALT_DIFFERENTIAL_ACCEPTS_INCOMPLETE_FIXTURES
HALT_INTEGER_OVERFLOW_UNRESOLVED
HALT_NEGATIVE_CONTROL_NOT_LOAD_BEARING

HALT_PRODUCTION_AUTHORITY_REGRESSION
HALT_PRODUCTION_CAUSAL_CONTROL_FAILED

HALT_CONSERVATION_REGRESSION
HALT_FACTORY_GATE_NOT_GREEN
HALT_F14_VIOLATION
HALT_MANDATORY_AC_NOT_GREEN
```

A HALT records a real failing predicate and its evidence. It does not
authorize a workaround that weakens the contract. Do not HALT merely
because the work is substantial or requires more than one session.

---

## 14. Terminality and verdict

For successful closure:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

Use a single contiguous terminal trailer block accepted by the live
Factory-v2 validator. After committing C4, run:

```sh
git status --porcelain=v1

git diff --check <ENTRY_HEAD>..HEAD

sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01 HEAD

git log -1 --format='%B' |
  git interpret-trailers --parse
```

The read-only external check must establish:

```text
FACTORY_V2_RANGE_CHECK=PASS
WORKTREE_CLEAN=YES
POST_CLOSE_CONTINUATION=NO
PATCH_HYGIENE_ERRORS=0
```

Do not append a post-C4 metadata or whitespace fixup commit. A failed
mandatory predicate requires the appropriate HALT disposition, even if
most engineering work succeeds.

---

## 15. Next ACT

Upon successful qualification:

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

NEXT_MISSION=
  Refresh remaining legacy-C parser semantic authorities,
  remove the newly migrated control-flow-token slice from
  the eligible candidate pool, recompute dependency-boundary
  rankings, and select the next production-authoritative
  self-hosting migration.
```

The next reconnaissance must use the actual new parser authority state,
not historical assumptions. Do not open RECON03 within this ACT or
preselect its winner.

---

## 16. Explicit execution instruction

Execute the full bounded ACT, not just C0 authorization. Reproduce
D1..D4, repair the build and differential qualifications, run all negative
controls, run the full existing production conservation checks, and close
through Factory v2.

**Prioritize executable correctness over documentation elaboration.**

Preserve the successful PolyC parser migration. Do not revisit older
SLICE02 verdict prose, bootstrap history, Git trailer geometry, LLVM
GEP01, or unrelated Factory doctrine unless a directly binding failure
makes it necessary.

The required outcome is a production compiler whose PolyC
control-flow-token authority is unchanged, but whose build and
qualification systems can no longer accept an invalid object or an
incomplete differential as green.
