# ACT-POLYC-SELFHOST-PARSER-PADDING01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Implement and mechanically qualify the PolyC `CalcPadding` semantic component without changing production parser authority

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / PARSER / COMPONENT-QUALIFICATION

**Priority:** P0

---

# 0. Mission

Implement the parser-layout primitive selected mechanically by:

```text
ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01
```

as:

```text
tools/bootstrap/selfhost-parser-padding.HC
```

with frozen ABI:

```text
I64 BootstrapCalcPadding(I64 offset, I64 size);
```

and prove that it is semantically equivalent to the legacy C:

```text
src/parser.c::CalcPadding
```

across a mechanically bounded input partition.

This ACT SHALL:

1. reproduce the predecessor's five RED conditions before implementation;
2. add the PolyC component;
3. create a PolyC-authoritative differential qualification path;
4. prove deterministic component-object fixed point across the available bootstrap compiler generations;
5. prove compiler-generation provenance independently;
6. execute causal semantic mutations that **compile, link, execute, and diverge**;
7. prove the zero-size guard is load-bearing;
8. prove no parser production caller has been switched to the PolyC component;
9. rerun parser-layout conservation plus LEXER01..04 conservation;
10. close only if all mandatory predicates are mechanically green.

This ACT does **not** migrate production authority.

The intended terminal distinction is:

```text
PARSER_PADDING_COMPONENT_IMPLEMENTED=YES
PARSER_PADDING_COMPONENT_QUALIFIED=YES

PARSER_PADDING_PRODUCTION_AUTHORITY=LEGACY_C
PARSER_PADDING_PRODUCTION_DELEGATION=NOT_PERFORMED
```

A successful close authorizes a separate delegation ACT.

---

# 1. Frozen predecessor binding

The authoritative predecessor is:

```text
ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01
VERDICT=PASS_TRUE_GREEN
```

Frozen successor contract:

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-PADDING01

NEXT_TARGET_ID=CAND-002
NEXT_TARGET=CalcPadding
NEXT_FILE=src/parser.c
NEXT_LINE_START=430
NEXT_LINE_END=438

NEXT_R0=0
NEXT_SCOPE_FROZEN=YES
```

The predecessor's selection SHALL NOT be reranked in this ACT.

If the live source no longer matches the selected region at C0:

```text
HALT_SELECTED_SOURCE_DRIFT
```

---

# 2. Frozen semantic purpose

Legacy semantic authority computes the number of padding bytes required to
align the next field.

Frozen mathematical behavior:

```text
CalcPadding(offset, size):

    if size == 0:
        return 0

    remainder = offset % size

    if remainder == 0:
        return 0

    return size - remainder
```

Expected range for positive `size`:

```text
0 <= result < size
```

For:

```text
size == 0
```

required:

```text
result == 0
```

The zero-size guard must precede any remainder operation.

---

# 3. Frozen ABI

The PolyC component SHALL export exactly:

```text
I64 BootstrapCalcPadding(I64 offset, I64 size);
```

Inputs:

```text
offset : I64
size   : I64
```

Output:

```text
pad_bytes : I64
```

Forbidden ABI content:

```text
Cctrl *
Ast *
Map *
List *
Lexeme *
jmp_buf *
void * host_context
opaque host pointer encoded as integer
function-pointer callback table
```

Required:

```text
ABI_HOST_IDENTITY_FIELDS=0
ABI_CALLBACK_FIELDS=0
ABI_POINTER_FIELDS=0
```

---

# 4. Authority semantics

This ACT creates a **qualified PolyC implementation**.

It SHALL NOT claim:

```text
CalcPadding is production self-hosted
```

because `src/parser.c` remains production authority.

Truthful terminology:

```text
COMPONENT_AUTHORITY        = POLYC_QUALIFIED
PRODUCTION_AUTHORITY       = LEGACY_C
PRODUCTION_DELEGATION      = NOT_PERFORMED
```

Forbidden closure claim:

```text
PARSER_PADDING_SELFHOST_COMPLETE=YES
```

Allowed closure claim:

```text
PARSER_PADDING_COMPONENT_QUALIFICATION=PASS_TRUE_GREEN
```

---

# 5. C0 entry identity

At C0 run:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git log -8 --oneline
git diff --check
```

Required:

```text
BRANCH=main
WORKTREE_CLEAN_AT_C0=YES
PATCH_HYGIENE_AT_C0=PASS
```

Bind:

```text
ENTRY_HEAD=<actual HEAD>
ENTRY_TREE=<git rev-parse HEAD^{tree}>
```

Expected predecessor:

```text
ACT-POLYC-SELFHOST-PARSER-SLICE-RECON01 C4 CLOSE
```

Mismatch:

```text
HALT_ENTRY_IDENTITY_MISMATCH
```

Dirty tree:

```text
HALT_ENTRY_DIRTY
```

---

# 6. Authorization before implementation

C0 SHALL introduce this ACT before any implementation file.

Allowed C0 writes:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-PADDING01.md

evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01/c0/
  c0-entry-identity.txt
  c0-predecessor-binding.txt
  c0-scope.txt
```

Required:

```text
C0_AUTH_BEFORE_WORK=YES
```

---

# 7. Exact lifecycle

Exactly five commits:

```text
C0 AUTH
C1 RED / CONTRACT
C2 IMPL
C3 VERIFY
C4 CLOSE
```

Maximum:

```text
5 commits
```

No:

```text
C0.1
C2 fix
C2.5
C3 fix
C3.5
C4 fill
post-C4 cleanup
```

If an implementation correction becomes necessary after C2:

```text
HALT_PHASE_CORRECTION_REQUIRED
```

The correction must live in a successor correction ACT.

---

# 8. In-scope production files

Allowed new production source:

```text
tools/bootstrap/selfhost-parser-padding.HC
```

Optional, only if needed for an independent PolyC driver:

```text
tools/bootstrap/selfhost-parser-padding-driver.HC
```

Allowed quality sources:

```text
tools/quality/parser-padding-*.HC
```

Allowed small shell dispatch:

```text
scripts/quality/parser-padding-*.sh
```

only if:

```text
LOC <= 50
substantive logic = PolyC
```

Allowed build wiring:

```text
Makefile
```

only for bounded component/oracle/fixed-point targets.

---

# 9. Explicitly forbidden production mutations

This ACT SHALL NOT modify:

```text
src/parser.c
src/parser.h

src/cctrl.c
src/cctrl.h

src/ast.c
src/ast.h

src/lexer.c
src/lexer.h

src/list.h
src/map.h

src/prslib.c
src/prslib.h
```

It SHALL NOT change:

```text
parseClassOffsets
parseUnionOffsets
CalcPadding legacy C implementation
any existing CalcPadding call site
```

Required:

```text
PARSER_PRODUCTION_SOURCE_DELTA=0
```

---

# 10. F14 immutable history

Do not modify closed evidence/HANDOFFs belonging to:

```text
LEXER01
LEXER02
LEXER03
LEXER04

SURFACE-RECON03

PARSER01
PARSER01-CORRECTION01
PARSER-SLICE-RECON01
```

Required:

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

---

# 11. C1 — RED/CONTRACT mission

C1 SHALL reproduce the five frozen predecessor REDs against the actual
entry tree.

No implementation mutation in C1.

---

# 12. RED-1 — PolyC subject absent

Command:

```sh
test -f tools/bootstrap/selfhost-parser-padding.HC
```

Required at RED:

```text
RC!=0
RED_SUBJECT_ABSENT=PASS
```

If subject already exists unexpectedly:

```text
HALT_RED_NOT_REPRODUCIBLE
```

unless it can be mechanically traced to an authorized predecessor artifact.

---

# 13. RED-2 — ABI absent

Search:

```sh
git grep -n 'BootstrapCalcPadding' -- tools/bootstrap src tools/quality
```

Required pre-implementation:

```text
PRODUCTION_BOOTSTRAP_CALC_PADDING_REFERENCES=0
RED_ABI_ABSENT=PASS
```

The ACT document/evidence itself is excluded from this source query.

---

# 14. RED-3 — legacy production authority active

Mechanically locate:

```text
src/parser.c::CalcPadding
```

and every live production caller.

Expected frozen caller family:

```text
parseClassOffsets
parseUnionOffsets
```

Required:

```text
LEGACY_CALC_PADDING_DEFINED=YES
LEGACY_CALLER_COUNT>=1
POLYC_PRODUCTION_CALLER_COUNT=0
RED_LEGACY_AUTHORITY_ACTIVE=PASS
```

Capture source SHA-256 of:

```text
src/parser.c
```

for later conservation.

---

# 15. RED-4 — differential verifier absent

Required:

```sh
test -x ./build/parser-padding-differential
```

must fail.

Record:

```text
RED_DIRECT_DIFFERENTIAL_ABSENT=PASS
```

---

# 16. RED-5 — fixed-point verifier absent

Required:

```sh
test -x ./build/parser-padding-fixedpoint-verify
```

must fail.

Record:

```text
RED_FIXEDPOINT_EVIDENCE_ABSENT=PASS
```

---

# 17. Legacy semantic baseline

C1 SHALL freeze the C implementation's semantic projection independently
of the future PolyC implementation.

Capture:

```text
legacy function source region
legacy source SHA-256
function signature
caller identities
```

Also freeze the mathematical contract:

```text
size == 0            => 0
size > 0 && aligned  => 0
size > 0 && unaligned => size - offset%size
```

Required:

```text
LEGACY_BASELINE_FROZEN=YES
```

---

# 18. Input domain

The production contract inherited from predecessor recon is:

```text
offset >= 0
size   >= 0
```

This ACT SHALL qualify that domain.

Do not silently extend the language contract to negative values.

Negative integer values may be used only as robustness diagnostics and SHALL
NOT contribute to semantic-equivalence PASS.

Required:

```text
QUALIFIED_DOMAIN=offset>=0,size>=0
```

---

# 19. Fixture partition

C1 SHALL convert the predecessor fixture model into a concrete immutable
fixture table.

Minimum required classes:

```text
ALIGNED
UNALIGNED
ZERO_OFFSET
ZERO_SIZE
SIZE_ONE
ODD_SIZE
POWER_OF_TWO_SIZE
NON_POWER_OF_TWO_SIZE
LARGE_OFFSET
LARGE_SIZE
REMAINDER_ONE
REMAINDER_SIZE_MINUS_ONE
```

Required fixture count:

```text
>=74
```

Prefer a mechanically generated matrix substantially larger than the
minimum.

---

# 20. Exhaustive bounded arithmetic corpus

In addition to named fixtures, generate:

```text
offset = 0..255
size   = 0..64
```

for:

```text
256 * 65 = 16640
```

input pairs.

Every pair is compared:

```text
legacy C
vs
PolyC
```

Required:

```text
BOUNDED_MATRIX_TOTAL=16640
```

This is the semantic broad corpus for this 2-input primitive.

---

# 21. Large-value corpus

Add deterministic large-value cases to detect arithmetic mistakes that
small residues might miss.

At minimum include:

```text
offset = 2^15 - 1
offset = 2^16
offset = 2^31 - 1

size = 1
size = 2
size = 3
size = 7
size = 8
size = 16
size = 63
size = 64
```

provided values remain inside the frozen non-negative domain.

Required:

```text
LARGE_VALUE_CASES>=24
```

---

# 22. Oracle separation

The differential verifier SHALL NOT derive the expected result by copying
the PolyC algorithm into the same authority path.

Required architecture:

```text
legacy C CalcPadding
        |
        +---- actual result C

PolyC BootstrapCalcPadding
        |
        +---- actual result PolyC

comparison layer
```

The legacy C result is the primary compatibility oracle.

A mathematical reference implementation may exist only as a third
cross-check.

Required:

```text
LEGACY_ORACLE_INDEPENDENT_FROM_POLYC=YES
```

---

# 23. Differential result schema

For every case record at least:

```text
case_id
offset
size
legacy_result
polyc_result
equal
```

Terminal summary:

```text
DIRECT_DIFFERENTIAL_TOTAL=<N>
DIRECT_DIFFERENTIAL_PASS=<N>
DIRECT_DIFFERENTIAL_FAIL=0
```

---

# 24. C1 mutation contract

Freeze four semantic mutation classes.

## M1 — zero-size guard broken

Mutated implementation performs or attempts remainder calculation before
handling:

```text
size == 0
```

Mutation must:

```text
compile=YES
link=YES
execute=YES
```

and be rejected.

If a particular mutation causes process failure due to divide-by-zero or
undefined runtime behavior, that counts as semantic rejection only if the
harness explicitly classifies the executed failure.

A mere compile failure is invalid.

## M2 — aligned case wrong

For aligned positive-size input, return:

```text
size
```

instead of:

```text
0
```

Must compile/link/execute/diverge.

## M3 — remainder returned directly

Return:

```text
offset % size
```

instead of:

```text
size - offset % size
```

for unaligned input.

Must compile/link/execute/diverge.

## M4 — boolean classifier

Return:

```text
(offset % size == 0)
```

instead of pad-byte count.

Must compile/link/execute/diverge.

---

# 25. Mutation control load-bearing requirement

For each M1..M4:

```text
MUTATED_COMPONENT_BUILT=YES
MUTATED_COMPONENT_LINKED=YES
MUTATED_COMPONENT_EXECUTED=YES
MUTATED_COMPONENT_SHA256=<nonempty>
PRISTINE_COMPONENT_SHA256=<nonempty>
MUTATED_COMPONENT_SHA_DIFFERS=YES

MUTATION_DIVERGENCE_COUNT>=1
VERIFIER_REJECTED_MUTATION=YES
```

Then rerun pristine:

```text
PRISTINE_AFTER_MUTATION=PASS
```

No mutation PASS may be inferred from missing output.

---

# 26. C1 required evidence

Create:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01/c1/

c1-entry-identity.txt

c1-red-subject-absent.txt
c1-red-abi-absent.txt
c1-red-legacy-authority.txt
c1-red-differential-absent.txt
c1-red-fixedpoint-absent.txt

c1-legacy-source-identity.txt
c1-legacy-baseline.txt

c1-fixture-contract.tsv
c1-mutation-contract.tsv
c1-proof-contract.tsv

c1-required-result.txt
```

---

# 27. C1 required result

```text
RED_SUBJECT_ABSENT=PASS
RED_ABI_ABSENT=PASS
RED_LEGACY_AUTHORITY_ACTIVE=PASS
RED_DIRECT_DIFFERENTIAL_ABSENT=PASS
RED_FIXEDPOINT_EVIDENCE_ABSENT=PASS

LEGACY_BASELINE_FROZEN=YES

FIXTURE_CLASSES>=12
FIXTURE_MINIMUM>=74
BOUNDED_MATRIX_TOTAL=16640
LARGE_VALUE_CASES>=24

MUTATION_CLASSES=4

PRODUCTION_SOURCE_DELTA=0

C1_PHASE_PURITY=PASS
```

Failure:

```text
HALT_C1_CONTRACT_NOT_FROZEN
```

---

# 28. C2 — implementation mission

Implement:

```text
tools/bootstrap/selfhost-parser-padding.HC
```

with the frozen ABI and semantics.

The implementation SHALL be small, direct, and dependency-free.

No parser mutation.

---

# 29. PolyC subject implementation constraint

Expected logical shape:

```text
if size == 0
    return 0

rem = offset % size

if rem == 0
    return 0

return size - rem
```

Do not optimize the expression into a form whose zero-size behavior becomes
ambiguous.

No allocation.

No global mutable state.

No calls into parser/lexer/Cctrl.

Required:

```text
SUBJECT_EXTERNAL_DEPENDENCY_COUNT=0
SUBJECT_GLOBAL_MUTABLE_STATE=0
SUBJECT_ALLOCATION_COUNT=0
```

---

# 30. PolyC tooling authority

Terminal semantic verdicts SHALL be produced by PolyC tooling.

Expected tools:

```text
tools/quality/parser-padding-differential.HC
tools/quality/parser-padding-fixedpoint-verify.HC
tools/quality/parser-padding-mutation-verify.HC
```

They may be combined if one PolyC program cleanly owns multiple proof roles.

Substantive C quality tools are forbidden.

C is permitted only for the frozen **legacy oracle seam** exposing the
actual existing C `CalcPadding` implementation if unavoidable.

Required:

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

---

# 31. C legacy oracle restriction

If a C oracle source is added, it must:

```text
call or expose the actual legacy CalcPadding semantics
not implement a second independent expected-value algorithm
not make terminal PASS/FAIL policy
```

Terminal comparison/verdict authority remains PolyC.

Required:

```text
C_ORACLE_IS_SEMANTIC_REFERENCE_ONLY=YES
```

---

# 32. Build targets

Add narrowly-scoped Make targets, preferably:

```text
parser-padding-component
parser-padding-differential
parser-padding-fixedpoint
parser-padding-mutation-test
parser-padding-test
```

`parser-padding-test` SHALL aggregate the qualification gates.

No unrelated build cleanup.

---

# 33. Component isolation

The PolyC subject must compile independently from parser production
translation units.

Required:

```text
COMPONENT_REQUIRES_SRC_PARSER_OBJECT=NO
```

It may use normal runtime/link substrate required for HC compilation, but
its semantics must not depend on parser state.

---

# 34. Four-generation component build

Build the subject independently using the established available compiler
generations.

Canonical intent:

```text
G0 = ./hcc
G1 = ./build/hcc-bootstrap02
G2 = ./build/hcc-bootstrap03
G3 = ./build/hcc-bootstrap04
```

Before using these literal paths, C1/C2 must verify the actual live
bootstrap identities and record them.

No copied generation artifacts.

Each generation output SHALL be absent before its own build.

---

# 35. Independent-generation requirement

For every generation:

```text
remove output
invoke that generation compiler
capture compiler SHA-256
capture command
capture output SHA-256
capture output size
```

Required:

```text
G0_INDEPENDENT_BUILD=YES
G1_INDEPENDENT_BUILD=YES
G2_INDEPENDENT_BUILD=YES
G3_INDEPENDENT_BUILD=YES
```

Forbidden:

```text
cp g1.o g2.o
cp g2.o g3.o
```

or equivalent reuse.

---

# 36. Fixed-point requirement

Compare all six pairs:

```text
G0 == G1
G0 == G2
G0 == G3
G1 == G2
G1 == G3
G2 == G3
```

Required:

```text
FIXEDPOINT_PAIR_TOTAL=6
FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0
```

All object SHA-256 values must be recorded.

If G0 is expected to differ for a documented bootstrap reason, that must be
discovered at C2 and causes:

```text
HALT_FIXEDPOINT_CONTRACT_MISMATCH
```

Do not silently redefine the contract.

---

# 37. Generation provenance negative control

The provenance verifier must detect artifact substitution.

Test:

1. preserve expected G3 compiler identity and expected G3 row;
2. replace a temporary G3 object path with the G1 object;
3. run provenance/fixedpoint verifier;
4. require rejection;
5. restore pristine independent G3 output;
6. require PASS.

Required:

```text
GENERATION_COPY_DETECTED=YES
```

---

# 38. Fixed-point mutation control

Mutate one copied component object byte in a temporary artifact.

Required:

```text
PRISTINE_FIXEDPOINT=PASS
MUTATED_FIXEDPOINT=FAIL
PRISTINE_RECHECK=PASS
```

This proves the byte-equality verifier is load-bearing.

---

# 39. C2 direct differential preliminary run

Before C2 commit, the implemented component must pass at least:

```text
named fixtures
16640 bounded matrix
large-value corpus
```

Required:

```text
DIRECT_DIFFERENTIAL_FAIL=0
```

Otherwise:

```text
HALT_C2_IMPLEMENTATION_DEFECT
```

Do not repair during C3.

---

# 40. C2 semantic mutation preliminary run

All four mutations must be mechanically executable before C2 closes.

Required:

```text
M1_REJECTED=YES
M2_REJECTED=YES
M3_REJECTED=YES
M4_REJECTED=YES
```

If any mutation merely fails to compile:

```text
HALT_MUTATION_NOT_CAUSAL
```

---

# 41. C2 allowed files

C2 may touch only:

```text
tools/bootstrap/selfhost-parser-padding.HC
tools/bootstrap/selfhost-parser-padding-driver.HC   optional

tools/quality/parser-padding-*.HC

scripts/quality/parser-padding-*.sh                <=50 LOC glue

Makefile
```

No evidence rewriting from C1.

---

# 42. C2 required result

```text
POLYC_SUBJECT_EXISTS=YES
POLYC_SUBJECT_ABI_MATCH=YES

SUBJECT_EXTERNAL_DEPENDENCY_COUNT=0
SUBJECT_GLOBAL_MUTABLE_STATE=0
SUBJECT_ALLOCATION_COUNT=0

COMPONENT_REQUIRES_SRC_PARSER_OBJECT=NO

DIRECT_DIFFERENTIAL_FAIL=0

M1_REJECTED=YES
M2_REJECTED=YES
M3_REJECTED=YES
M4_REJECTED=YES

FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0

GENERATION_COPY_DETECTED=YES

PARSER_PRODUCTION_SOURCE_DELTA=0

C2_PHASE_PURITY=PASS
```

---

# 43. C3 — verification mission

C3 is evidence-only.

No implementation source changes.

If C3 reveals an implementation defect:

```text
HALT_C2_DEFECT_FOUND_DURING_C3
```

Do not patch and continue.

---

# 44. C3 source identity

Capture committed SHA-256 for:

```text
tools/bootstrap/selfhost-parser-padding.HC

every PolyC quality tool
every shell wrapper
Makefile
src/parser.c
```

Required:

```text
C2_TO_C3_IMPLEMENTATION_FREEZE=PASS
```

---

# 45. C3 direct differential — named fixtures

Run every frozen named fixture.

Required:

```text
NAMED_FIXTURE_FAIL=0
```

Record full case table.

---

# 46. C3 direct differential — bounded matrix

Run all:

```text
offset = 0..255
size = 0..64
```

Required:

```text
BOUNDED_MATRIX_TOTAL=16640
BOUNDED_MATRIX_PASS=16640
BOUNDED_MATRIX_FAIL=0
```

---

# 47. C3 direct differential — large values

Required:

```text
LARGE_VALUE_CASES>=24
LARGE_VALUE_FAIL=0
```

---

# 48. Algebraic invariants

For every qualified-domain input mechanically test:

For:

```text
size == 0
```

require:

```text
padding == 0
```

For:

```text
size > 0
```

require:

```text
0 <= padding
padding < size
(offset + padding) % size == 0
```

Required:

```text
ALGEBRAIC_INVARIANT_FAIL=0
```

This is independent of simple equality with the C result.

---

# 49. Zero-size causal witness

Explicitly execute multiple:

```text
size=0
```

cases against pristine and M1 mutation.

Required:

```text
PRISTINE_ZERO_SIZE_PASS=YES
M1_ZERO_SIZE_REJECTED=YES
```

No missing-result inference.

---

# 50. Semantic mutation evidence

For M1..M4 produce separate evidence containing:

```text
mutation_id
source_delta
build_rc
link_rc
run_rc
pristine_sha256
mutated_sha256
first_divergent_case
divergence_count
verifier_rc
```

Required each:

```text
build_rc=0
link_rc=0
mutation_divergence_count>=1
verifier_rc!=0
```

Then pristine rerun:

```text
PRISTINE_REVERIFY=PASS
```

---

# 51. Four-generation provenance

For G0..G3 record:

```text
generation
compiler_path
compiler_sha256
command
source_sha256
object_path
object_sha256
object_size
built_from_absent_output
```

Required:

```text
GENERATION_ROWS=4
UNKNOWN_PROVENANCE_ROWS=0
```

---

# 52. Fixed-point terminal proof

PolyC verifier produces:

```text
PAIR_TOTAL=6
PAIR_PASS=6
PAIR_FAIL=0
STATUS=PASS
```

No shell `cmp` alone may own the terminal verdict, although shell commands
may be recorded as secondary evidence.

---

# 53. Generation-copy control

Actually execute the forged-generation control.

Required:

```text
GENERATION_COPY_ATTEMPTED=YES
GENERATION_COPY_DETECTED=YES
FORGED_PROVENANCE_VERDICT=FAIL
PRISTINE_PROVENANCE_REVERIFY=PASS
```

---

# 54. Production-authority conservation

This ACT intentionally leaves C production authority active.

C3 shall prove:

```text
src/parser.c SHA matches C0
legacy CalcPadding body matches C0
all CalcPadding production callers match C0
no BootstrapCalcPadding call from src/parser.c
```

Required:

```text
LEGACY_PRODUCTION_AUTHORITY_PRESERVED=YES
POLYC_PRODUCTION_DELEGATION_COUNT=0
```

This is a PASS condition, not residue.

---

# 55. Parser-layout conservation

Run a bounded production compiler corpus containing at least:

```text
class with naturally aligned fields
class with padding
class with mixed 1/2/4/8-byte fields
class with zero-size U0 field if supported by existing grammar
union with mixed field sizes
nested class/union where already supported
```

Compare behavior against C0/legacy baseline.

Because production source is unchanged, required:

```text
PARSER_LAYOUT_CONSERVATION=PASS
```

Any delta:

```text
HALT_UNEXPECTED_PRODUCTION_DELTA
```

---

# 56. Existing parser test conservation

Run whatever current repository targets exercise parser/class/union layout.

Do not invent success if no dedicated target exists.

Record exact target availability.

Required:

```text
AVAILABLE_PARSER_CONSERVATION_TARGETS_RUN=YES
PARSER_CONSERVATION_NEW_FAILURES=0
```

---

# 57. LEXER conservation

Run canonical current conservation:

```text
LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS
```

Carry historical baselines truthfully.

---

# 58. LEXER07 historical failures

Do not require historical red cases to become green.

Require:

```text
NEW_LEXER07_FAILURES=0
```

relative to the C0 frozen baseline.

---

# 59. F-POLYC-TOOLS

Required:

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

Shell wrappers:

```text
<=50 LOC
dispatch only
```

C oracle exception:

```text
semantic reference only
not terminal verifier authority
```

---

# 60. F-NO-PYTHON

Required:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_PYTHON_FALLBACKS=0
```

Pre-existing baseline is not part of this ACT.

---

# 61. Factory gates

Run:

```sh
make gate-fast
bash scripts/quality/factory-append-only-test.sh
```

plus current Factory v2 commit-message validation.

Required:

```text
GATE_FAST=PASS
APPEND_ONLY_PASS=11
APPEND_ONLY_FAIL=0
```

---

# 62. Patch hygiene

Run against the entire ACT range:

```sh
git diff --check "$ENTRY_HEAD"..HEAD
```

Required:

```text
PATCH_HYGIENE_ERRORS=0
```

No evidence-file exemption.

---

# 63. Worktree cleanliness

At every committed phase boundary:

```text
WORKTREE_CLEAN=YES
```

Especially before C4:

```text
WORKTREE_CLEAN_BEFORE_C4=YES
```

---

# 64. C3 evidence artifacts

Produce at minimum:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01/c3/

c3-entry-identity.txt
c3-source-identities.tsv

c3-direct-differential-named.tsv
c3-direct-differential-matrix.txt
c3-direct-differential-large.txt
c3-algebraic-invariants.txt

c3-zero-size-guard.txt

c3-mutation-m1.txt
c3-mutation-m2.txt
c3-mutation-m3.txt
c3-mutation-m4.txt
c3-mutation-summary.txt

c3-generation-provenance.tsv
c3-fixedpoint.txt
c3-fixedpoint-negative-control.txt
c3-generation-copy-control.txt

c3-production-authority.txt
c3-parser-layout-conservation.txt
c3-parser-test-conservation.txt

c3-lexer01-conservation.txt
c3-lexer02-conservation.txt
c3-lexer03-conservation.txt
c3-lexer04-conservation.txt
c3-lexer07-delta.txt

c3-f-polyc-tools.txt
c3-f-no-python.txt
c3-f14.txt

c3-factory-gates.txt
c3-append-only.txt
c3-patch-hygiene.txt
c3-phase-purity.txt

mandatory-ac-status.tsv
c3-required-result.txt
```

No stub evidence.

Every PASS row must name an actual mechanical witness.

---

# 65. Evidence truth rule

An evidence file may not merely contain:

```text
FOO=PASS
```

as its proof.

Every terminal predicate must be backed by at least one of:

```text
captured command output
structured case table
SHA-256 identity
verifier-generated structured result
explicit source identity comparison
```

Required:

```text
PLACEHOLDER_EVIDENCE_COUNT=0
```

---

# 66. Mandatory acceptance criteria

## AC01 — entry identity

```text
WORKTREE_CLEAN_AT_C0=YES
```

## AC02 — authorization ordering

```text
C0_AUTH_BEFORE_WORK=YES
```

## AC03 — predecessor binding

```text
PREDECESSOR_SELECTION_MATCH=YES
```

## AC04 — selected source identity

```text
SELECTED_SOURCE_REGION_MATCH=YES
```

## AC05 — RED subject absence

```text
RED_SUBJECT_ABSENT=PASS
```

## AC06 — RED ABI absence

```text
RED_ABI_ABSENT=PASS
```

## AC07 — RED legacy authority

```text
RED_LEGACY_AUTHORITY_ACTIVE=PASS
```

## AC08 — RED differential absence

```text
RED_DIRECT_DIFFERENTIAL_ABSENT=PASS
```

## AC09 — RED fixedpoint absence

```text
RED_FIXEDPOINT_EVIDENCE_ABSENT=PASS
```

## AC10 — baseline frozen

```text
LEGACY_BASELINE_FROZEN=YES
```

## AC11 — ABI exact

```text
I64 BootstrapCalcPadding(I64 offset, I64 size)
```

## AC12 — no host identity

```text
ABI_HOST_IDENTITY_FIELDS=0
```

## AC13 — subject dependency purity

```text
SUBJECT_EXTERNAL_DEPENDENCY_COUNT=0
SUBJECT_GLOBAL_MUTABLE_STATE=0
SUBJECT_ALLOCATION_COUNT=0
```

## AC14 — named fixtures

```text
NAMED_FIXTURE_FAIL=0
```

## AC15 — bounded matrix

```text
BOUNDED_MATRIX_TOTAL=16640
BOUNDED_MATRIX_FAIL=0
```

## AC16 — large-value fixtures

```text
LARGE_VALUE_CASES>=24
LARGE_VALUE_FAIL=0
```

## AC17 — direct differential

```text
DIRECT_DIFFERENTIAL_FAIL=0
```

## AC18 — algebraic invariants

```text
ALGEBRAIC_INVARIANT_FAIL=0
```

## AC19 — zero-size semantics

```text
PRISTINE_ZERO_SIZE_PASS=YES
```

## AC20 — M1 causal mutation

```text
M1_BUILT=YES
M1_LINKED=YES
M1_EXECUTED=YES
M1_REJECTED=YES
```

## AC21 — M2 causal mutation

```text
M2_BUILT=YES
M2_LINKED=YES
M2_EXECUTED=YES
M2_REJECTED=YES
```

## AC22 — M3 causal mutation

```text
M3_BUILT=YES
M3_LINKED=YES
M3_EXECUTED=YES
M3_REJECTED=YES
```

## AC23 — M4 causal mutation

```text
M4_BUILT=YES
M4_LINKED=YES
M4_EXECUTED=YES
M4_REJECTED=YES
```

## AC24 — pristine after mutations

```text
PRISTINE_REVERIFY=PASS
```

## AC25 — generation provenance

```text
GENERATION_ROWS=4
UNKNOWN_PROVENANCE_ROWS=0
```

## AC26 — independent builds

```text
G0_INDEPENDENT_BUILD=YES
G1_INDEPENDENT_BUILD=YES
G2_INDEPENDENT_BUILD=YES
G3_INDEPENDENT_BUILD=YES
```

## AC27 — fixed point

```text
FIXEDPOINT_PAIR_TOTAL=6
FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0
```

## AC28 — fixedpoint verifier causal control

```text
PRISTINE_FIXEDPOINT=PASS
MUTATED_FIXEDPOINT=FAIL
PRISTINE_FIXEDPOINT_RECHECK=PASS
```

## AC29 — generation-copy detection

```text
GENERATION_COPY_DETECTED=YES
```

## AC30 — legacy production authority retained

```text
LEGACY_PRODUCTION_AUTHORITY_PRESERVED=YES
```

## AC31 — no production delegation

```text
POLYC_PRODUCTION_DELEGATION_COUNT=0
```

## AC32 — parser production source unchanged

```text
PARSER_PRODUCTION_SOURCE_DELTA=0
```

## AC33 — parser layout conservation

```text
PARSER_LAYOUT_CONSERVATION=PASS
```

## AC34 — parser tests

```text
PARSER_CONSERVATION_NEW_FAILURES=0
```

## AC35 — LEXER01

```text
LEXER01_CONSERVATION=PASS
```

## AC36 — LEXER02

```text
LEXER02_CONSERVATION=PASS
```

## AC37 — LEXER03

```text
LEXER03_CONSERVATION=PASS
```

## AC38 — LEXER04

```text
LEXER04_CONSERVATION=PASS
```

## AC39 — LEXER07 delta

```text
NEW_LEXER07_FAILURES=0
```

## AC40 — F-POLYC-TOOLS

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

## AC41 — shell budget

```text
NEW_SHELL_WRAPPERS_OVER_50_LOC=0
```

## AC42 — F-NO-PYTHON

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_PYTHON_FALLBACKS=0
```

## AC43 — F14

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

## AC44 — placeholder evidence

```text
PLACEHOLDER_EVIDENCE_COUNT=0
```

## AC45 — Factory gate

```text
GATE_FAST=PASS
```

## AC46 — append-only

```text
APPEND_ONLY_FAIL=0
```

## AC47 — patch hygiene

```text
PATCH_HYGIENE_ERRORS=0
```

## AC48 — C3 phase purity

```text
C3_IMPLEMENTATION_SOURCE_DELTA=0
```

## AC49 — worktree close

```text
WORKTREE_CLEAN_AT_CLOSE=YES
```

## AC50 — exact lifecycle

```text
EXACT_COMMIT_COUNT_AT_CLOSE=5
POST_C4_COMMIT_COUNT=0
```

---

# 67. Mandatory AC ledger

Create at C3:

```text
evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01/c3/mandatory-ac-status.tsv
```

Columns:

```text
ac_id
predicate
status
evidence_path
witness
evidence_sha256
notes
```

Allowed C3 states:

```text
PASS
FAIL
DEFERRED_TO_C4
```

Only:

```text
AC49
AC50
```

may be:

```text
DEFERRED_TO_C4
```

No `PASS_BY_DESIGN`.

No `PASS_WITH_WARNING`.

A mandatory predicate is either mechanically satisfied or not.

---

# 68. AC ledger integrity

At C3 verify:

```text
AC_ID_UNIQUE=YES
AC_PREDICATE_COUNT=50
EVIDENCE_SHA_MISMATCH=0
MISSING_EVIDENCE=0
```

If an existing PolyC ledger verifier can express these predicates, reuse it.

Otherwise a new substantive verifier must be PolyC.

---

# 69. C3 required result

Before C4:

```text
AC_TOTAL=50
AC_PASS=48
AC_FAIL=0
AC_DEFERRED_TO_C4=2

DIRECT_DIFFERENTIAL_FAIL=0
BOUNDED_MATRIX_FAIL=0
ALGEBRAIC_INVARIANT_FAIL=0

MUTATION_PASS=4
MUTATION_FAIL=0

FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0

GENERATION_COPY_DETECTED=YES

LEGACY_PRODUCTION_AUTHORITY_PRESERVED=YES
POLYC_PRODUCTION_DELEGATION_COUNT=0

PARSER_LAYOUT_CONSERVATION=PASS
PARSER_CONSERVATION_NEW_FAILURES=0

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS
NEW_LEXER07_FAILURES=0

NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

PLACEHOLDER_EVIDENCE_COUNT=0

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0
C3_IMPLEMENTATION_SOURCE_DELTA=0
```

---

# 70. C4 precondition

Immediately before C4:

```sh
git status --short
git diff --check "$ENTRY_HEAD"..HEAD
```

Required:

```text
WORKTREE_CLEAN_BEFORE_C4=YES
PATCH_HYGIENE_ERRORS=0
```

Also rerun:

```text
parser-padding-test
gate-fast
factory-append-only-test
```

If anything is red:

```text
HALT_C4_PRECONDITION
```

No cleanup in C4.

---

# 71. C4 allowed scope

C4 may add only:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-PADDING01.md
docs/ROADMAP.md

evidence/ACT-POLYC-SELFHOST-PARSER-PADDING01/c4/
  c4-parent-identity.txt
  c4-required-result.txt
  c4-terminal-ledger.tsv
```

C4 must not modify:

```text
subject implementation
quality tooling
Makefile
C1/C2/C3 evidence
ACT authorization artifact
```

---

# 72. C4 temporal predicates

After the C4 commit verify:

```text
EXACT_COMMIT_COUNT_AT_CLOSE=5
WORKTREE_CLEAN_AT_CLOSE=YES
POST_C4_COMMIT_COUNT=0
```

Do not create a sixth commit to record these.

The C4 parent evidence records the pre-C4 parent.

The commit topology itself is the terminal witness.

---

# 73. Truthful terminal verdict

`PASS_TRUE_GREEN` applies to this statement only:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING01
COMPONENT_QUALIFICATION=PASS_TRUE_GREEN
```

It does NOT mean:

```text
PRODUCTION_SELFHOST_MIGRATION=COMPLETE
```

Required closure taxonomy:

```text
PARSER_PADDING_POLYC_COMPONENT      = GREEN
DIRECT_DIFFERENTIAL                = GREEN
BOUNDED_SEMANTIC_MATRIX            = GREEN
ALGEBRAIC_INVARIANTS               = GREEN
CAUSAL_MUTATION_CONTROLS           = GREEN
COMPONENT_4GEN_FIXEDPOINT          = GREEN
GENERATION_PROVENANCE              = GREEN

LEGACY_PRODUCTION_AUTHORITY        = PRESERVED
POLYC_PRODUCTION_DELEGATION        = NOT_PERFORMED

PARSER_PADDING_COMPONENT_QUALIFIED = TRUE_GREEN
PARSER_PADDING_SELFHOST_COMPLETE   = NO
```

---

# 74. PASS_TRUE_GREEN predicate

Close PASS only if:

```text
AC_TOTAL=50
AC_PASS=50
AC_FAIL=0

DIRECT_DIFFERENTIAL_FAIL=0
BOUNDED_MATRIX_PASS=16640
BOUNDED_MATRIX_FAIL=0

ALGEBRAIC_INVARIANT_FAIL=0

M1_REJECTED=YES
M2_REJECTED=YES
M3_REJECTED=YES
M4_REJECTED=YES
PRISTINE_REVERIFY=PASS

GENERATION_ROWS=4
FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0
GENERATION_COPY_DETECTED=YES

LEGACY_PRODUCTION_AUTHORITY_PRESERVED=YES
POLYC_PRODUCTION_DELEGATION_COUNT=0

PARSER_LAYOUT_CONSERVATION=PASS
PARSER_CONSERVATION_NEW_FAILURES=0

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS
NEW_LEXER07_FAILURES=0

NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

PLACEHOLDER_EVIDENCE_COUNT=0

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

EXACT_COMMIT_COUNT_AT_CLOSE=5
WORKTREE_CLEAN_AT_CLOSE=YES
POST_C4_COMMIT_COUNT=0
```

---

# 75. HALT taxonomy

Valid halts:

```text
HALT_ENTRY_DIRTY
HALT_ENTRY_IDENTITY_MISMATCH
HALT_AUTHORIZATION_MISSING

HALT_SELECTED_SOURCE_DRIFT
HALT_RED_NOT_REPRODUCIBLE
HALT_C1_CONTRACT_NOT_FROZEN

HALT_ABI_DRIFT
HALT_C2_IMPLEMENTATION_DEFECT

HALT_MUTATION_NOT_CAUSAL
HALT_FIXEDPOINT_CONTRACT_MISMATCH
HALT_GENERATION_PROVENANCE

HALT_C2_DEFECT_FOUND_DURING_C3
HALT_DIFFERENTIAL_MISMATCH
HALT_ALGEBRAIC_INVARIANT
HALT_MUTATION_CONTROL
HALT_FIXEDPOINT
HALT_GENERATION_COPY_CONTROL

HALT_UNEXPECTED_PRODUCTION_DELTA
HALT_PARSER_CONSERVATION
HALT_LEXER_CONSERVATION
HALT_LEXER07_NEW_REGRESSION

HALT_F_POLYC_TOOLS
HALT_F_NO_PYTHON
HALT_F14_VIOLATION

HALT_PLACEHOLDER_EVIDENCE
HALT_AC_LEDGER_NOT_GREEN

HALT_FACTORY_GATE
HALT_APPEND_ONLY
HALT_PATCH_HYGIENE

HALT_C4_PRECONDITION
HALT_PHASE_CORRECTION_REQUIRED
```

A mechanically justified HALT is a successful ACT execution result.

Never reinterpret a failed mandatory predicate after the fact.

---

# 76. Explicit non-goals

Do NOT:

```text
modify src/parser.c
replace C CalcPadding
reroute parseClassOffsets
reroute parseUnionOffsets
claim production authority moved to PolyC

migrate CalcClassSize
migrate CalcUnionSize
migrate parseValidPostControlFlowToken
migrate AST fallthrough predicates

change class/union layout semantics
change ABI layout
change parser recovery
change Cctrl
change Ast
```

---

# 77. Successor after successful close

A successful component qualification should authorize:

```text
ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
```

Mission:

```text
replace production calls to legacy C CalcPadding with
BootstrapCalcPadding under an explicit stage/delegation seam
```

That successor must separately prove:

```text
real production authority transfer
G0 legacy vs G1+ PolyC semantic seam
class-layout byte equivalence
union-layout byte equivalence
negative control load-bearingness
4-generation production behavior
```

`PADDING01` itself SHALL NOT pre-claim any of these.

---

# 78. Expected board transition

Before:

```text
PARSER-SLICE-RECON01
  = CLOSED PASS_TRUE_GREEN

CAND-002 CalcPadding
  = SELECTED

PRODUCTION_AUTHORITY
  = LEGACY_C
```

After successful `PARSER-PADDING01`:

```text
PARSER-PADDING01
  = CLOSED PASS_TRUE_GREEN
    (component qualification only)

BootstrapCalcPadding
  = POLYC_COMPONENT_QUALIFIED

CalcPadding production authority
  = LEGACY_C

NEXT
  = ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
```

---

# 79. C4 HANDOFF required sections

The HANDOFF must contain:

```text
VERDICT
IDENTITY
PREDECESSOR BINDING
TARGET
SEMANTIC CONTRACT
ABI
RED
IMPLEMENTATION
DIRECT DIFFERENTIAL
BOUNDED MATRIX
ALGEBRAIC INVARIANTS
ZERO-SIZE GUARD
MUTATION CONTROLS
GENERATION PROVENANCE
FIXEDPOINT
GENERATION-COPY CONTROL
PRODUCTION AUTHORITY
PARSER CONSERVATION
LEXER CONSERVATION
FACTORY GATES
F-POLYC-TOOLS
F-NO-PYTHON
F14
PATCH HYGIENE
SCOPE
RESIDUE
NEXT
```

---

# 80. Required final summary

A successful final summary SHALL say, in substance:

```text
VERDICT=PASS_TRUE_GREEN

ACT=ACT-POLYC-SELFHOST-PARSER-PADDING01

BootstrapCalcPadding:
  IMPLEMENTED=YES
  QUALIFIED=YES

DIRECT_DIFFERENTIAL=PASS
BOUNDED_MATRIX=16640/16640
ALGEBRAIC_INVARIANTS=PASS

MUTATION_CONTROLS=4/4
FIXEDPOINT_PAIRS=6/6
GENERATION_PROVENANCE=4/4
GENERATION_COPY_DETECTED=YES

PRODUCTION_AUTHORITY=LEGACY_C
PRODUCTION_DELEGATION=NOT_PERFORMED

PARSER_LAYOUT_CONSERVATION=PASS
LEXER01..04_CONSERVATION=PASS

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

EXACT_COMMIT_COUNT=5
POST_C4_COMMIT_COUNT=0

NEXT=ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01
```

It SHALL NOT describe the parser padding migration as complete until the
separate production-delegation ACT closes.
