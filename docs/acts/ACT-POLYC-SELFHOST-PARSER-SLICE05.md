# ACT-POLYC-SELFHOST-PARSER-SLICE05

**Factory-Version:** 2
**Lifecycle:** AUTHORIZATION_ARTIFACT
**Class:** SELFHOST / PARSER / AST-UNARY-OPERATOR / PRODUCTION-AUTHORITY-MIGRATION
**Priority:** P0
**Repository:** `s1onique/polyc`
**Branch:** `main`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE04`
(closed with `ACT-Verdict: PASS`; its evidence tree, HANDOFF and ACT
document are closed evidence under F14 and are NOT modified here)
**Expected ENTRY_HEAD:** `b7634f9afb6b530f7bac987317754ab35b8dbead`
**Target:** `CAND-020 astUnaryOpFromToken`
**Successor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04` (proposed; no
target preselected)

---

## 0. Mission

Migrate the remaining AST token-to-operator classifier from legacy C to a
production-authoritative PolyC component.

The predecessor has already migrated:

```text
astBinOpFromToken
  -> BootstrapAstBinOpFromToken
  -> POLYC production authority
```

SLICE05 must migrate:

```text
astUnaryOpFromToken
  -> BootstrapAstUnaryOpFromToken
  -> POLYC production authority
```

### Required final result

```text
AST_BINARY_OPERATOR_AUTHORITY = POLYC
AST_UNARY_OPERATOR_AUTHORITY  = POLYC

LEGACY_BINARY_C_AUTHORITY     = RETIRED
LEGACY_UNARY_C_AUTHORITY      = RETIRED

AST_OPERATOR_CLASSIFIER_FAMILY = SELFHOSTED_TRUE_GREEN

PARSER_PADDING_AUTHORITY      = POLYC
PARSER_CONTROL_FLOW_AUTHORITY = POLYC
PARSER_PRECEDENCE_AUTHORITY   = POLYC

PRODUCTION_SEMANTIC_DELTA     = 0
NEW_SEMANTIC_REGRESSIONS      = 0
```

This is an implementation ACT, not another reconnaissance or
documentation correction.

Do not migrate other AST functions, parser expressions, declaration
parsing, statement parsing, or allocation machinery.

Do not consider the presence of a PolyC implementation sufficient.  The
**production compiler must actually depend on it**.

---

## 1. Entry identity and predecessor binding

Mandatory entry commands:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git replace -l

git log -1 --format='%B' | git interpret-trailers --parse
git log -5 --format='%H %s'
```

Required:

```text
BRANCH=main
ENTRY_HEAD=<actual full SHA>
WORKTREE_CLEAN=YES
GIT_REPLACE_REFS=0

PREDECESSOR_CLOSE_REACHABLE=YES
PREDECESSOR_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE04
PREDECESSOR_VERDICT=PASS
```

The predecessor CLOSE SHA is resolved through local Git history; no full
SHA is fabricated from the abbreviated form.

If HEAD has advanced, intervening changes are inventoried and a new
explicit entry baseline is established.

If another ACT has already migrated the unary classifier, the ACT halts
as `HALT_TARGET_ALREADY_SELFHOSTED`.

### F14 protection

The hashes of all closed SLICE04 ACT, evidence, and HANDOFF files are
frozen at C0.  No modification to those files is permitted anywhere in
the SLICE05 range.

Historical SLICE04 claims remain historical, including any unproven
provenance-control conclusions.

---

## 2. Frozen target and dependency boundary

### 2.1 Function

```c
int astUnaryOpFromToken(s64 op, AstUnOp *_result);
```

Historical location: `src/ast.c:238..254` (SLICE04's observation).

Known production callers from SLICE04 reconnaissance:
`src/prslib.c:1450` and `src/prslib.c:1757`.  The actual call graph is
reconfirmed against ENTRY_HEAD at C0.

The function is a scalar token-to-enum mapping with a conditional
output-pointer store.

### 2.2 Complete candidate token domain

The predecessor recorded ten accepted unary tokens.  Those numbers are
**predecessor observations, not a substitute for C1 measurement**: the
live `src/lexer.h` and `src/ast.h` are recompiled to establish the
numeric values and enums.  The canonical token-to-enum table is
generated from the actual legacy function and its compiled enum
declarations.  Enum values are NOT inferred from names or ordinal
positions.

### 2.3 State and side effects

Required:

```text
GLOBAL_STATE_READS=0
HOST_AST_GRAPH_MUTATIONS=0
CALLBACK_DEPENDENCIES=0
NONLOCAL_RECOVERY_DEPENDENCIES=0
HOST_POINTER_IDENTITY_REQUIRED=NO
```

The C output-pointer write is ABI storage, not AST graph authority.  The
PolyC component must never receive that pointer.

### 2.4 Existing semantics are binding

```text
success: return_value=1, output_after_call=<mapped AstUnOp>
failure: return_value=0, output_after_call=output_before_call
```

A failed lookup must not overwrite the caller's output storage.

---

## 3. Predecessor provenance-control hardening

SLICE04 has two unresolved negative-control witness defects.  Their
proof implications are addressed in SLICE05's new evidence and
qualification infrastructure.  SLICE04's closed evidence is not edited
and its historical verdict is not changed.

### D-PROV-01 — G1 witness substituted for G3

The historical control's observed rejection was
`REJECT_STAGE_LABELS` ("witness carries 3 generations, expected 4"),
which proves rejection of a missing-generation condition, not rejection
of substitution in an otherwise complete four-generation manifest.

**Required corrected control.**  Start from a complete, valid
four-generation witness.  Preserve
`GENERATION_ROWS=4`, `STAGE_LABELS=G0,G1,G2,G3` and
`ALL_REQUIRED_RECEIPTS_PRESENT=YES`.  Replace **only the G3 witness
payload** with the G1 witness payload.  Retain G3 as the expected
generation and leave the other rows unchanged.  Run the real provenance
verifier.  Required:

```text
NC_G3_SUBSTITUTION_MANIFEST_COMPLETE=YES
NC_G3_SUBSTITUTION_CHANGED_TARGET=G3
NC_G3_SUBSTITUTION_OTHER_ROWS_UNCHANGED=YES

NC_G3_SUBSTITUTION_REJECTED=YES
NC_G3_SUBSTITUTION_REJECTION_REASON=G3_BINDING_MISMATCH
```

A row-count, missing-generation, or malformed-input rejection is not
sufficient.

### D-PROV-02 — G3 receipt omission

The historical control's observed rejection was
"g0 has no PROBE_EXECUTION_OUTPUT", which does not prove a G3-specific
omission detector.

**Required corrected control.**  Start from the same complete valid
four-generation baseline.  Remove only the G3 execution receipt.
Retain every G0, G1, and G2 receipt byte-for-byte.  Required:

```text
NC_G3_OMISSION_TARGET=G3
NC_G0_RECEIPT_PRESERVED=YES
NC_G1_RECEIPT_PRESERVED=YES
NC_G2_RECEIPT_PRESERVED=YES

NC_G3_OMISSION_REJECTED=YES
NC_G3_OMISSION_REJECTION_REASON=G3_EXECUTION_RECEIPT_MISSING
```

### Validation ordering

The controls record all parsing and structural diagnostics.  A verifier
that rejects because an earlier unrelated field is broken has not proven
the intended negative control.

If the existing SLICE04 verifier cannot evaluate these correctly, a
bounded SLICE05-owned verifier or adapter is implemented, with
prospective C1 authorization.  The closed SLICE04 verifier is not
modified.

### Pristine recheck

After every negative control:

```text
PRISTINE_MANIFEST_VALID=YES
PRISTINE_PROVENANCE_VERDICT=PASS
```

### Security and proof boundary

Byte-identical G1/G2/G3 objects do not carry their own build identity.
A locally recorded compiler SHA, execution receipt, and object SHA can
prove consistency with independently retained build observations, but
not resistance to an adversary who can rewrite the entire evidence
store.  That distinction is stated honestly.

SLICE05 requires detection of the specified witness substitutions and
omissions, not a fabricated claim of cryptographically unforgeable
provenance.

---

## 4. Scope

### 4.1 Authorized production mutations

```text
src/ast.c
src/CMakeLists.txt
```

`src/ast.c` may change only the selected unary-classifier body and the
minimum declaration or conditional compilation needed for its
delegation.  The binary-classifier decision, ABI, and source body are
frozen.

### 4.2 Authorized component

```text
tools/bootstrap/selfhost-parser-slice05.HC
```

Expected symbol: `BootstrapAstUnaryOpFromToken`.

### 4.3 Authorized qualification files

```text
tools/quality/parser-slice05-*.HC
tools/quality/parser-slice05-oracle-*.c
tools/quality/parser-slice05-oracle-*.h
src/cmake/VerifyAstUnaryTokenMapObject.cmake
src/cmake/WriteAstUnaryTokenMapObjectStamp.cmake
Makefile
```

The new CMake files are optional.  SLICE04's already-qualified generic
verifier is preferred where it can be reused without modifying its
closed behavior.

The C oracle may call the actual legacy unary classifier but must not
implement a duplicate mapping.  All substantial new validation logic is
PolyC.

### 4.4 Authorized documentation/evidence

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE05.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE05.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/**
```

### 4.5 Forbidden

```text
existing closed ACT documents
existing closed HANDOFFs
existing closed evidence directories

src/prslib.c
src/parser.c
src/lexer.c
src/lexer.h
src/ast.h
src/cctrl.c
src/cctrl.h

existing tools/bootstrap/**
existing tools/quality/parser-slice04-*.HC
existing Factory validators
pre-push hooks
```

No LLVM/JIT backend changes.  No unrelated parser, lexer,
AST-allocation, or exception-handling changes.  No new Python tools or
Python fallback.  No new substantive shell tools above the project's
established glue budget.  The SLICE04 implementation is not copied and
renamed without removing binary-specific assumptions.

---

## 5. C0 — AUTH / RED

The ACT authorization artifact and the real entry tree are frozen.

Required evidence (`c0/`):

```text
entry-identity.txt
predecessor-identity.txt
predecessor-provenance-findings.txt
source-freeze.tsv
production-authority.txt
real-call-graph.txt
baseline-gates.txt
baseline-parser-results.txt
baseline-lexer-results.txt
red-component-absent.txt
red-legacy-authority.txt
required-result.txt
```

### C0 RED predicates

```text
POLYC_UNARY_COMPONENT_EXISTS=NO
UNARY_PRODUCTION_DELEGATION=NO
UNARY_LEGACY_AUTHORITY=YES

BINARY_PRODUCTION_AUTHORITY=POLYC
PADDING_PRODUCTION_AUTHORITY=POLYC
CONTROL_FLOW_PRODUCTION_AUTHORITY=POLYC
PRECEDENCE_PRODUCTION_AUTHORITY=POLYC
```

These are proven against a fresh build, not merely `grep` or a stale
`build/` object.  The disassembly of the legacy unary mapping and of
the production caller is captured, along with a test program that
exercises a real unary operator path.

### Baseline

The entry compiler is built from the frozen entry tree in an isolated
directory.  Parser tests, the relevant lexer differential suites, and
the broad lexer corpus are executed.  Actual result identities,
including existing failures, are stored.  A pre-existing failing suite
is not relabelled PASS.

### C0 commit

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE05
ACT-Phase: RED
```

C0 contains no production implementation.

---

## 6. C1 — CONTRACT

The target's exact semantics, source boundaries, ABI, fixture matrix,
and causal mutation are frozen.

### 6.1 PolyC ABI

```text
I64 BootstrapAstUnaryOpFromToken(I64 token_value) -> I64
```

Return: `>=0` exact AstUnOp enum value; `-1` unrecognized token.

C1 recompiles the live header and confirms that `-1` remains disjoint
from the successful values.  Required:

```text
ABI_HOST_POINTER_FIELDS=0
ABI_GLOBAL_STATE_FIELDS=0

ENUM_VALUES_NONNEGATIVE=YES
FAILURE_SENTINEL=-1
SENTINEL_COLLISION=NO

INTEGER_PROJECTION_LOSSLESS=YES
```

If these conditions are false, the sentinel ABI is not silently
retained: the ACT halts for an explicit bounded redesign.

### 6.2 C adapter contract

The production wrapper retains the original C signature.  The C adapter
is permitted to own argument projection, failure/success conversion,
and conditional enum storage.  It must not own token classification.

### 6.3 Production switch

```text
HCC_USE_SELFHOST_PARSER_AST_UNARY
```

Expected behavior:

```text
PRODUCTION_DEFAULT=ON
STAGE0_BUILD=OFF
LEGACY_ORACLE_BUILD=OFF
```

Fail-closed operation when ON.  No automatic fallback when the PolyC
object is unavailable.

### 6.4 Real legacy oracle

The actual `src/ast.c::astUnaryOpFromToken` is compiled with the unary
delegation macro OFF.  The driver calls that function and records
`token_value`, `initial_output`, `legacy_success`,
`legacy_output_after_call`.  No duplicate mapping table exists in the C
oracle driver.  The oracle object's selected function contains the
legacy decision and does not reference `BootstrapAstUnaryOpFromToken`.

### 6.5 Fixtures

Mandatory semantic partitions:

| Partition | Requirement |
|---|---|
| U01 | All ten accepted unary tokens |
| U02 | Accepted tokens with alternate initialized outputs |
| U03 | Rejected printable ASCII values |
| U04 | Neighbors of accepted token constants |
| U05 | Prefix/postfix distinction |
| U06 | Unary plus/minus distinction |
| U07 | Address-of/dereference distinction |
| U08 | Lexer aliases and equal numeric values |
| U09 | Signed 64-bit boundary values |
| U10 | Unrecognized lexer tokens |
| U11 | Failure preserves original output |
| U12 | Real production caller behavior |

The exact row count is **computed from the live token set and frozen
partition rules**.  SLICE05 is not forced to reproduce SLICE04's 322
rows.  Exact signed 64-bit numbers are preserved: no `%d` truncation and
no numeric fragments extracted from symbolic identifiers.

### 6.6 Independent fixture integrity

```text
EXPECTED_ID_SET=OBSERVED_ID_SET
EXPECTED_VALUE_SET=OBSERVED_VALUE_SET
EXPECTED_PARTITIONS=OBSERVED_PARTITIONS

DUPLICATE_IDS=0
MISSING_IDS=0
UNKNOWN_IDS=0

MALFORMED_ROWS=0
INVALID_I64_VALUES=0
UNTESTED_ACCEPTED_TOKENS=0

UNTESTED_FAILURE_STORAGE_CASES=0
```

### 6.7 Negative controls

At least eight executable controls: (1) delete a required
accepted-token row; (2) duplicate a fixture ID; (3) insert an unknown
ID; (4) insert an indented unknown row; (5) replace `INT64_MAX` with a
truncated value; (6) remove one prefix/postfix case without changing
row count; (7) change a successful expected enum; (8) change a failed
lookup to overwrite its initialized output.  Each must make the real
verifier reject with a relevant failure reason.

### 6.8 Production-causal mutation

Preferred candidate: token `'-'` maps to `AST_UN_OP_PLUS` instead of
`AST_UN_OP_MINUS`.  A nonzero unary operand exposes the difference.
The witness is a real PolyC program compiled by the real compiler, not
a direct call to the mapping function as the sole causal witness.  The
observation produces an unambiguous value in stdout; process exit codes
that truncate negative values are not relied upon.  Exact source, input,
expected pristine output, mutation, and observation command are frozen.

### C1 artifacts

```text
c1/
  unary-source-recon.txt
  token-to-enum.tsv
  compiled-enum-values.tsv
  ABI-contract.md
  oracle-contract.md
  fixture-contract.tsv
  fixture.tsv
  fixture-integrity-contract.md
  negative-control-contract.tsv
  production-delegation-contract.md
  mutation-contract.md
  provenance-control-contract.md
  mandatory-ac-contract.tsv
  required-result.txt
```

Commit:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE05
ACT-Phase: EVIDENCE
```

No production implementation before this freeze.

---

## 7. C2 — IMPLEMENT

### 7.1 PolyC component

`tools/bootstrap/selfhost-parser-slice05.HC` implements
`BootstrapAstUnaryOpFromToken` with:

```text
NO_GLOBAL_STATE=YES
NO_ALLOCATION=YES
NO_CALLBACKS=YES
NO_AST_POINTERS=YES
NO_NONLOCAL_RECOVERY=YES

PURE_SCALAR_MAPPING=YES
```

It is compiled with the appropriate stage0 compiler and preserves the
exact accepted-token behavior frozen at C1.

### 7.2 Production migration

The unary function's body in `src/ast.c` delegates to the PolyC symbol.
The legacy switch may remain in the OFF branch for stage0 and oracle
purposes.  Production ON branch:

```text
TOKEN_DECISION_OWNER=POLYC
C_ADAPTER_CONDITIONAL_STORAGE=YES
LEGACY_SWITCH_EXECUTED=NO
```

No shadow verification.  No fallback call to the legacy C mapping.

### 7.3 Binary operator preservation

`astBinOpFromToken` retains `BootstrapAstBinOpFromToken` as its
production authority.  Its function source remains byte-identical to
ENTRY_HEAD, and the existing binary-operator production causal path
remains functional.

### 7.4 CMake integration

A new unary subject object is wired into the production compiler.  The
existing verifier is reused as a parameterized, read-only facility where
it is already suitable; otherwise the authorized new unary-specific
CMake verifier is used.  Both producer and prebuilt-object modes must
reject:

```text
MISSING_OBJECT
EMPTY_OBJECT
INVALID_OBJECT_FORMAT
UNDEFINED_ONLY_SYMBOL
LOCAL_ONLY_SYMBOL
WEAK_ONLY_SYMBOL
DUPLICATE_STRONG_DEFINITION
WRONG_SYMBOL_NAME
```

A legitimate strong global symbol must pass on the actual target
platform.  Mach-O naming is not hard-coded into generic ELF
verification.  The verifier must execute for the current subject rather
than trusting an old stamp.

### 7.5 Fresh-tree link integrity

From a pristine build:

```text
EACH_PRODUCTION_SUBJECT_LINKED_ONCE=YES
DUPLICATE_BOOTSTRAP_SYMBOLS=0
STANDALONE_DIFFERENTIAL_LINK=PASS
```

Archive and standalone-object membership are inspected explicitly.  The
warm-tree link is not merely passed.

### 7.6 Direct differential

For every frozen fixture:

```text
LEGACY_SUCCESS = POLYC_ADAPTER_SUCCESS
LEGACY_OUTPUT  = POLYC_ADAPTER_OUTPUT
```

Both are compared to the independently frozen expected results.  Required:

```text
DIFFERENTIAL_MISMATCHES=0
ORACLE_EXPECTED_MISMATCHES=0
POLYC_EXPECTED_MISMATCHES=0
OUTPUT_PRESERVATION_FAILURES=0
```

All negative controls are run.

### C2 evidence

```text
c2/
  component-source.txt
  component-build.txt
  implementation-scope.txt
  production-delegation.txt
  production-linkage.txt
  fail-closed-controls.txt
  fresh-tree-link.txt
  real-oracle-build.txt
  direct-differential.txt
  fixture-integrity.txt
  negative-controls.txt
  required-result.txt
```

Commit:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE05
ACT-Phase: IMPL
```

---

## 8. C3 — FOUR-GENERATION PROOF

### 8.1 Generations

```text
G0 = actual legacy C unary authority
G1 = PolyC stage1 unary authority
G2 = PolyC stage2 unary authority
G3 = PolyC stage3 unary authority
```

Each is built and executed independently.  Another generation's output is
never copied as a substitute for compilation.

### 8.2 Required provenance

For every generation: `generation_id`, `source_sha256`,
`compiler_invocation`, `resolved_compiler_path`,
`compiler_executable_sha256`, `compiler_version`,
`exact_build_command`, `build_exit_code`, `object_sha256`,
`linked_binary_sha256`, `execution_command`, `execution_exit_code`,
`execution_output_sha256`, `execution_receipt_id`, `run_binding_id`.

G0's producing compiler is the actual host C compiler invoked for the
legacy oracle.  G1/G2/G3 record their actual PolyC compiler binaries.
No reporting-rule substitution of `./hcc` for G0's C compiler.

### 8.3 Comparison model

```text
G1 == G2
G1 == G3
G2 == G3
```

plus all six semantic pairs G0..G3, with equal semantic output across
the entire frozen fixture set.  G0 object bytes are not required to
equal PolyC object bytes.

### 8.4 Production execution

The generation proof includes production-compiler execution, not just
standalone component binaries.  The same frozen unary-observation
programs are compiled and executed per applicable generation; output
bytes, exit statuses, and relevant diagnostics are compared.  Any
expected host-specific nondeterminism is identified in C1 rather than
silently normalized at C3.

### 8.5 Provenance controls

| ID | Mutation | Required rejection |
|---|---|---|
| NC-P01 | G1 witness payload placed in G3 slot; all four generations remain present | G3 witness binding mismatch |
| NC-P02 | Only G3 execution receipt removed | G3 receipt missing |
| NC-P03 | One compiler SHA changed | Exact compiler-identity mismatch |
| NC-P04 | Validly linked but non-byte-identical subject substituted | Object identity mismatch |
| NC-P05 | G1 and G3 stage identities interchanged | Stage/run identity mismatch |

For every negative control:

```text
PRISTINE_VERDICT=PASS
MUTATION_TARGET=<exact field>
NON_TARGET_FIELDS_UNCHANGED=YES
MUTANT_VERDICT=REJECTED
REJECTION_REASON=<expected class>
PRISTINE_RECHECK=PASS
```

Unrelated parse errors, row-count errors, or G0 omissions are not
accepted as evidence of a G3-specific detector.  The controls exercise
the same verifier used for the pristine qualification.

### 8.6 Production-causal mutation

```text
A. pristine production compiler
B. production compiler linked with mutated unary subject
C. restored pristine production compiler
```

All three builds and executions succeed:

```text
A_BUILD_RC=0
A_EXEC_RC=0
B_BUILD_RC=0
B_EXEC_RC=0
B_OUTPUT_DIFFERS_FROM_A=YES
C_BUILD_RC=0
C_EXEC_RC=0
C_OUTPUT_EQUALS_A=YES
C_SUBJECT_SHA_EQUALS_A=YES
```

The real unary expression frozen at C1 is used.  The compiler executable
and component object identities are tracked for A, B, and C.  No
mutation to the tracked component file: scratch copies are used.

### 8.7 Production authority

```text
UNARY_PRODUCTION_OBJECT_REFERENCES_POLYC=YES
POLYC_UNARY_STRONG_DEFINITION_PRESENT=YES
LEGACY_UNARY_MAPPING_IN_PRODUCTION=NO

BINARY_PRODUCTION_AUTHORITY=POLYC
BINARY_SUBJECT_UNCHANGED=YES
```

The C wrapper symbol may remain for ABI compatibility, but its
classification logic must be delegated.

---

## 9. Conservation

### 9.1 Existing self-hosted parser subjects

Preserve `BootstrapCalcPadding`, `BootstrapValidPostControlFlowToken`,
`BootstrapOperatorPrecedence`, `BootstrapAstBinOpFromToken`: zero
changes to frozen source hashes and zero new semantic failures.

### 9.2 Parser suite

The canonical parser suite runs on both the entry compiler and the C2
implementation compiler.  Individual passing and failing test
identities are compared.  The predecessor's `PASSED=87 / FAILED=3` is
an expectation for reconnaissance, not a replacement for a fresh entry
measurement.  Required:

```text
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_PARSER_SEMANTIC_REGRESSIONS=0
```

Historical installation-prefix failures remain honestly preserved.

### 9.3 Lexer conservation

The canonical current lexer qualification targets run, including
LEXER07's broad corpus using
`docs/factory/LEXER07-BASELINE-AUTHORITY.tsv`.  Required:

```text
NEW_LEXER_FAILURE_IDENTITIES=0
NEW_LEXER07_FAILURE_IDENTITIES=0
```

The historical corpus may remain `STATUS=FAIL` while its regression
delta is zero.  The entire corpus is not relabelled PASS.

### 9.4 Production compiler features

The complete current `gate-push` pipeline runs:

```text
build
install
gep01
aot
jit
lsp
diff-check
```

Actual PASS is required for every mandatory gate.  No silent omission.

### 9.5 Host and tooling residue

The available F-NO-PYTHON and F-POLYC-TOOLS checks run.  Known
pre-existing Python findings remain visible.  Required:

```text
NEW_PYTHON_FILES=0
NEW_PYTHON_INVOCATIONS=0
NEW_UNAUTHORIZED_TOOL_VIOLATIONS=0
```

If the historical F-POLYC-TOOLS checker is still unavailable, it is
reported as unavailable; its PASS result is never invented.

---

## 10. Mandatory acceptance criteria

50 uniquely identified predicates are frozen at C1 (see
`c1/mandatory-ac-contract.tsv`).

```text
AC_TOTAL=50
AC_UNIQUE_IDS=50
AC_DUPLICATE_IDS=0
AC_MISSING_IDS=0

AC_PASS=50
AC_FAIL=0
AC_UNPROVEN=0
```

Each AC binds to actual predicate-establishing evidence.  An evidence
file existing is not itself proof that its contents establish the
predicate.  Negative-control dispositions include the intended failure
reason, not merely a nonzero verifier exit.  AC50 may be deferred at
C3 because the CLOSE commit does not yet exist; no other mandatory AC is
silently deferred.

---

## 11. C3 evidence requirements

`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c3/` contains the required
evidence files listed in the execution plan, capturing real commands,
exit statuses, compiler identities, input hashes, output hashes, and
failure details.  For closed predecessors, SHA-bound references are
used; their historical evidence is not modified.

C3 commit:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE05
ACT-Phase: EVIDENCE
```

---

## 12. HALT taxonomy

```text
HALT_ENTRY_IDENTITY_INVALID
HALT_TARGET_ALREADY_SELFHOSTED
HALT_PREDECESSOR_IDENTITY_UNBOUND
HALT_F14_VIOLATION

HALT_UNARY_BOUNDARY_NOT_SCALAR
HALT_AMBIGUOUS_ABI
HALT_ENUM_SENTINEL_COLLISION

HALT_REAL_LEGACY_ORACLE_UNAVAILABLE
HALT_FIXTURE_CONTRACT_INCONSISTENT
HALT_FIXTURE_COVERAGE_INCOMPLETE
HALT_DIFFERENTIAL_MISMATCH

HALT_PRODUCTION_DELEGATION_NOT_LOAD_BEARING
HALT_LEGACY_UNARY_AUTHORITY_REMAINS
HALT_INVALID_COMPONENT_ACCEPTED
HALT_DUPLICATE_LINK_SUBJECTS

HALT_GENERATION_NOT_INDEPENDENT
HALT_PROVENANCE_CONTROL_INVALID
HALT_PROVENANCE_NOT_PROVEN

HALT_CAUSAL_MUTATION_NOT_OBSERVED
HALT_MUTANT_BUILD_FAILED
HALT_PRISTINE_RESTORATION_FAILED

HALT_EXISTING_SELFHOST_REGRESSION
HALT_CONSERVATION_REGRESSION
HALT_SCOPE_VIOLATION
HALT_FACTORY_GATE_NOT_GREEN
HALT_MANDATORY_AC_NOT_GREEN
```

A HALT preserves truthful engineering evidence.  The already-qualified
production migrations are never undone merely because SLICE05 cannot
establish one of its proof obligations.  Complexity, elapsed work, or a
session boundary are not HALT conditions.

---

## 13. C4 — CLOSE

On successful C3 qualification:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE05.md
```

is created, and `docs/factory/act-handoff-map.tsv` and
`docs/ROADMAP.md` are updated.  The HANDOFF records: actual entry and
close identities; frozen unary mapping and ABI; real C oracle and
fixture counts; production delegation and object-symbol proof;
four-generation build identities and comparisons; precise
provenance-control results; production-causal mutation and restoration;
four previous PolyC parser migrations conserved; parser and lexer
result-identity comparisons; Factory gates and acceptance ledger;
honest residual problems; AST operator classifier family status; and
the recommended next reconnaissance scope.

### Exact commit topology

Five contiguous forward-only commits:

```text
C0  RED       authority and baseline
C1  EVIDENCE  contract freeze
C2  IMPL      PolyC component + production delegation
C3  EVIDENCE  executable qualification
C4  CLOSE     HANDOFF + final verdict
```

A successful C4 carries:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE05
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

No amend, reset, rebase, force-push, or sixth fixup commit.  No evidence
is committed after CLOSE.

---

## 14. External terminality

After C4 exists, read-only checks run:

```sh
git status --porcelain=v1
git replace -l
git diff --check <ENTRY_HEAD>..HEAD
git rev-list --count <ENTRY_HEAD>..HEAD
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-PARSER-SLICE05 HEAD
git log -1 --format='%B' | git interpret-trailers --parse
```

Required:

```text
ACT_COMMIT_COUNT=5
CLOSE_DIRECT_PARENT_IS_C3=YES
FACTORY_V2_RANGE_CHECK=PASS
WORKTREE_CLEAN=YES
GIT_REPLACE_REFS=0
PATCH_HYGIENE_ERRORS=0
CLOSE_IS_ACT_TIP=YES
POST_CLOSE_CONTINUATION=NO
```

External terminality results are not committed into the closed ACT
evidence tree.

---

## 15. Terminal result

The only acceptable full-success result is:

```text
ACT=ACT-POLYC-SELFHOST-PARSER-SLICE05
VERDICT=PASS

TARGET=CAND-020
FUNCTION=astUnaryOpFromToken
POLYC_SYMBOL=BootstrapAstUnaryOpFromToken

UNARY_CLASSIFIER_AUTHORITY=POLYC
BINARY_CLASSIFIER_AUTHORITY=POLYC

LEGACY_UNARY_C_AUTHORITY=RETIRED
LEGACY_BINARY_C_AUTHORITY=RETIRED

AST_OPERATOR_CLASSIFIER_FAMILY=SELFHOSTED_TRUE_GREEN

REAL_C_ORACLE=PASS
DIRECT_DIFFERENTIAL=PASS
OUTPUT_STORAGE_SEMANTICS=PASS
FIXTURE_INTEGRITY=PASS
FIXTURE_NEGATIVE_CONTROLS=PASS

G0_G3_INDEPENDENT=YES
GENERATION_SEMANTICS=PASS
PROVENANCE_BINDING=PASS

G3_SUBSTITUTION_NEGATIVE_CONTROL=PASS
G3_OMISSION_NEGATIVE_CONTROL=PASS
OTHER_PROVENANCE_CONTROLS=PASS

PRODUCTION_DELEGATION=LOAD_BEARING
PRODUCTION_CAUSAL_MUTATION=PASS
PRISTINE_RESTORATION=PASS

PREVIOUS_PARSER_AUTHORITIES=CONSERVED
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_LEXER_FAILURE_IDENTITIES=0

GATE_FAST=PASS
GATE_PUSH=PASS
FACTORY_V2=PASS
APPEND_ONLY=PASS
F14=PASS
PATCH_HYGIENE=PASS

MANDATORY_AC_TOTAL=50
MANDATORY_AC_PASS=50
MANDATORY_AC_FAIL=0

ACT_COMMIT_COUNT=5
POST_CLOSE_CONTINUATION=NO
```

These values are not reported as observations before execution.

---

## 16. Epic board transition

Upon successful closure:

```text
SELFHOSTED PARSER COMPONENTS
----------------------------

CalcPadding                     POLYC
parseValidPostControlFlowToken  POLYC
parseGetPriority                POLYC
astBinOpFromToken               POLYC
astUnaryOpFromToken             POLYC

AST_OPERATOR_CLASSIFICATION     COMPLETE
PARSER_SELFHOSTING              IN_PROGRESS
```

This completes the bounded AST token-to-operator mapping family.  It does
**not** imply that the entire parser, AST construction subsystem, or
compiler is self-hosted.

### Next ACT

```text
ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04
```

Mission: re-inventory remaining parser and AST semantic authorities
after five qualified parser migrations, reclassify every candidate
against the live source, and select the next bounded migration surface.
No next winner is preselected.  A future reconnaissance should
reconsider structural parser slices previously excluded because of host
AST graph mutation, callback dependencies, or recovery coupling -- but
must not pretend those dependencies disappeared as a result of migrating
operator classifiers.

---

## 17. Execution directive

**Execute C0 through C4 as one authorized engineering ACT.**  The
priority is the actual compiler migration.

The essential correctness requirements are:

- The ten unary mappings remain exact.
- Output storage remains unchanged on failed lookups.
- The PolyC implementation owns the production decision.
- The legacy unary switch is absent from the production path.
- Four-generation compilation and execution are independently
  demonstrated.
- The two SLICE04 provenance-control deficiencies are not repeated.
- Mutation of the PolyC subject changes a real compiled program.
- Restoration reproduces pristine behavior.
- All previously migrated components remain production authorities.
- Closure is based on executable evidence, not summary prose.

**Successful outcome:** both AST token-to-operator classifiers are
PolyC-owned, and the compiler self-hosting epic advances to the next
substantive parser surface.
