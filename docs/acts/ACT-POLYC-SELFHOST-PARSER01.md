# ACT-POLYC-SELFHOST-PARSER01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Migrate `parseCompoundStatementInternal` from legacy C authority to a production-authoritative PolyC parser component

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / PARSER / PRODUCTION-MIGRATION

**Priority:** P0

---

# 0. Mission

Migrate exactly one parser semantic authority:

```text
INV.PARSER.COMPOUND
```

Atomic slice:

```text
src/parser.c::parseCompoundStatementInternal
```

from:

```text
LEGACY_C_AUTHORITY
```

to:

```text
SELFHOSTED_TRUE_GREEN
```

by introducing:

```text
tools/bootstrap/selfhost-parser-compound-statement-internal.HC
```

and production bridge:

```text
ABI 7
BootstrapParseCompoundStatementInternal
```

The new PolyC component SHALL become **load-bearing production authority** in stage1+ bootstrap compiler generations.

This ACT SHALL prove:

```text
PARSER01_POLYC_COMPONENT_EXISTS=YES

PARSER01_ABI7_DEFINED=YES
PARSER01_ABI7_LOAD_BEARING=YES

PARSER01_DIRECT_DIFFERENTIAL=PASS
PARSER01_PRODUCTION_SEAM=PASS

PARSER01_G0_G1_G2_G3_COMPONENT_FIXEDPOINT=PASS
PARSER01_GENERATION_PROVENANCE=PASS

PARSER01_NEGATIVE_CONTROL_LOAD_BEARING=YES

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS
NEW_LEXER07_FAILURES=0

F_POLYC_TOOLS=PASS
F_NO_PYTHON=PASS
F14=PASS

PRODUCTION_AUTHORITY=POLYC_STAGE1_PLUS

VERDICT=PASS_TRUE_GREEN
```

---

# 1. Authority

This ACT is authorized by:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03
```

which mechanically selected:

```text
NEXT_ACT_ID         = ACT-POLYC-SELFHOST-PARSER01
NEXT_TARGET_SURFACE = INV.PARSER.COMPOUND
NEXT_ATOMIC_SLICE   = parseCompoundStatementInternal
NEXT_ABI            = ABI 7
```

The recon ranked `INV.PARSER.COMPOUND` ahead of
`INV.PARSER.TOPLEVEL` because R1..R3 tied and compound had the smaller
dependency/coupling score at R4.

Do not rerun target selection inside this ACT.

---

# 2. Selected semantic surface

Binding target:

```text
surface_id:
  INV.PARSER.COMPOUND

legacy authority:
  src/parser.c::parseCompoundStatementInternal

approximate source region at authorization:
  src/parser.c ~1752..2012

responsibility:
  parse a compound statement body and advance parser state through
  declarations/statements until matching close-brace or error
```

Supporting legacy entry:

```text
parseCompoundStatement
```

is **not** itself migrated unless the bounded production seam requires a
minimal call-site delegation change explicitly authorized below.

---

# 3. C0 entry gate

At C0 run:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git log -5 --oneline
```

Required:

```text
BRANCH=main
WORKTREE_CLEAN_AT_C0=YES
```

Expected predecessor:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03 C4 CLOSE
```

Bind:

```text
ENTRY_HEAD=<actual HEAD>
PATCH_HYGIENE_BASELINE=<ENTRY_HEAD>
```

If dirty:

```text
HALT_ENTRY_DIRTY
```

Do not auto-clean unrelated user work.

---

# 4. Authorization must precede implementation

C0 SHALL commit:

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER01.md

evidence/ACT-POLYC-SELFHOST-PARSER01/c0/
  c0-entry-identity.txt
  c0-scope.txt
  c0-predecessor-selection.txt
```

before:

```text
new PolyC subject
bridge implementation
parser mutation
new parser10 fixtures
new parser10 verifier implementation
```

Required:

```text
C0_AUTH_BEFORE_WORK=YES
```
---

# 5. Scope principle

This is a **production migration ACT**.

It may change parser behavior only insofar as necessary to replace the
selected C authority with semantically equivalent PolyC authority.

The intended semantic delta is:

```text
authority implementation:
  C -> PolyC

language semantics:
  unchanged
```

Therefore:

```text
INTENDED_LANGUAGE_SEMANTIC_DELTA=0
INTENDED_AUTHORITY_DELTA=LEGACY_C_TO_POLYC
```

---

# 6. Allowed production files

Only:

```text
src/parser.c
src/parser_bridge.h
src/CMakeLists.txt
Makefile
tools/bootstrap/selfhost-parser-compound-statement-internal.HC
```

are authorized for production/build-seam mutation.

## `src/parser.c`

Allowed:

```text
parseCompoundStatementInternal body
minimal immediately-adjacent #ifdef delegation plumbing
minimal declarations necessary to call ABI 7
```

Forbidden:

```text
unrelated parser functions
parser expression semantics
declaration semantics
statement semantics outside the bounded delegation seam
toplevel parsing
constant evaluation
AST representation changes
```

## `src/parser_bridge.h`

Allowed:

```text
ABI 7 declaration
ABI 7 enums/contract constants
```

## `src/CMakeLists.txt` / `Makefile`

Allowed only for:

```text
PARSER10 component build
stage1..stage4 bootstrap linkage
quality target wiring
```

---

# 7. Forbidden production surfaces

Do not modify:

```text
src/lexer.c
src/lexer_bridge.h

src/ast.c
src/cctrl.c

src/prslib.c
src/prsutil.c
src/prsasm.c

src/ir.c
src/ir-*.c
src/ir-optimise.c
src/ir-types.c
src/ir-regalloc.c
src/ir-eval.c
src/ir-debug.c

src/x86.c
src/x86_64.c
src/aarch64.c
src/llvm-backend.c

src/x86_64-jit.c
src/aarch64-jit.c
src/jit-common.c

src/main.c
src/cli.c
src/compile.c
src/repl.c
src/lsp.c
src/transpiler.c

src/holyc-lib/**
src/asm/**

tools/bootstrap/selfhost-lexer-*.HC
tools/bootstrap/bootstrap02-ident.HC
```

Any required mutation outside the allowed production set:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

---

# 8. Explicitly deferred parser surfaces

Not in scope:

```text
INV.PARSER.STMT
INV.PARSER.TOPLEVEL
INV.PARSER.DECL
INV.PARSER.EXPR
INV.PREPROC.PP
```

In particular:

```text
parseStatement
parseDeclOrStatement
parseToplevelDef
parseToAst
parseDecl*
parseExpr*
```

remain legacy C authority.

They may be **called through bounded bridge callbacks/seams** but SHALL NOT
be migrated here.

---

# 9. ABI 7 objective

Define:

```c
I64 BootstrapParseCompoundStatementInternal(
    U8  *src,
    I64  src_len,
    I64  cursor,
    I64  flags,
    I64 *out_end,
    I64 *out_ast_kind,
    I64 *out_node_count,
    I64 *out_error
);
```

Contract:

```text
src:
  immutable parser-input byte sequence

src_len:
  byte length

cursor:
  first byte inside compound body
  i.e. immediately after opening '{'

flags:
  bounded parser-mode flags required by this component

out_end:
  first byte after matching '}'
  or src_len for unterminated input

out_ast_kind:
  stable state-contract projection;
  must not expose host pointer identity

out_node_count:
  number of top-level body elements accepted by component

out_error:
  PARSE_OK or PARSE_ERR_*
```

Character/input domain for the component harness:

```text
ASCII punctuation used by compound syntax
identifier bytes
declaration/statement-shaped token sequences
preprocessor-shaped text where included in frozen fixture corpus
```

---

# 10. ABI design constraint: no raw pointer proof

Do not compare:

```text
Ast *
Lexeme *
arena addresses
Cctrl internal addresses
malloc addresses
```

across generations.

All observable proof fields must be stable semantic projections.

Examples:

```text
end offset
node count
node-kind sequence
token consumption
error classification
serialized AST projection
```

---

# 11. Parser-state boundary

`parseCompoundStatementInternal` currently depends on surrounding parser
machinery.

PARSER01 SHALL separate:

```text
component-owned logic
```

from:

```text
legacy callback/dependency logic
```

without migrating the latter.

Allowed architecture:

```text
PolyC component
  ↓
bounded ABI/context adapter
  ↓
legacy parseStatement / parseDeclOrStatement where explicitly required
```

Forbidden architecture:

```text
copy the entire Cctrl/Ast implementation into PolyC
```

or:

```text
reimplement parser statement/expression semantics opportunistically
```
---

# 12. C1 RED / RECON

C1 SHALL mechanically reproduce at least these REDs.

## RED-1 — component absent

```sh
test -f tools/bootstrap/selfhost-parser-compound-statement-internal.HC
```

Expected pre-implementation:

```text
COMPONENT_PRESENT=NO
```

## RED-2 — ABI absent

Search:

```sh
grep -R "BootstrapParseCompoundStatementInternal" src/parser_bridge.h src 2>/dev/null
```

Expected:

```text
ABI7_PRESENT=NO
```

If `src/parser_bridge.h` itself is absent:

```text
ABI7_PRESENT=NO
PARSER_BRIDGE_FILE_PRESENT=NO
```

is valid RED.

## RED-3 — legacy authority remains linked

Mechanically demonstrate:

```text
src/parser.c defines parseCompoundStatementInternal
stage0 hcc links/contains legacy implementation
no PolyC subject participates
```

Prefer symbol/object provenance rather than prose.

Required:

```text
LEGACY_AUTHORITY_PRESENT=YES
POLYC_PRODUCTION_AUTHORITY_PRESENT=NO
```

---

# 13. C1 live-function recon

Before implementation, capture the real function body and dependency graph.

Produce:

```text
c1-function-shape.txt
c1-dependency-map.tsv
c1-state-read-write.tsv
```

For every state dependency classify:

```text
READ_ONLY_INPUT
OUTPUT
LEGACY_CALLBACK
OPAQUE_CONTEXT
SHARED_MUTABLE_STATE
```

Required:

```text
UNCLASSIFIED_STATE_DEPENDENCIES=0
```

---

# 14. Bounded dependency requirement

Expected dependencies from RECON03 include:

```text
Cctrl *cc
Ast *body
lexer/token stream
parseStatement
parseDeclOrStatement
lexToken or equivalent parser token advancement
```

C1 SHALL verify them against the live tree.

If the selected function actually requires simultaneous semantic migration
of any forbidden parser region:

```text
HALT_DEPENDENCY_EXPLOSION
```

Do not silently enlarge PARSER01.

---

# 15. Fixture corpus

Freeze exactly 23 initial fixtures across six classes unless C1 proves the
recon assumptions materially wrong.

Target shape:

```text
empty_compound           3
single_stmt_compound     5
decl_in_compound         5
nested_compound          4
unclosed_brace           3
mid_body_preproc         3
---------------------------
TOTAL                    23
```

Produce:

```text
evidence/.../c1/c1-fixture-contract.tsv
```

Columns:

```text
fixture_id
class
source_sha256
expected_legacy_rc
expected_error_class
expected_end_offset
expected_node_count
required_in_production_seam
negative_control_expected_affected
notes
```

---

# 16. Fixture authority

Fixture expectations must come from:

```text
legacy C implementation at ENTRY_HEAD
```

not from hand-authored desired PolyC behavior.

Capture legacy baseline **before C2 production mutation**.

Required:

```text
FIXTURE_TOTAL=23
FIXTURE_BASELINE_BOUND_TO_ENTRY_HEAD=YES
```

If fixture cardinality must change because C1 discovers the recon model was
wrong:

```text
HALT_FIXTURE_CONTRACT_CHANGE_REQUIRED
```

Do not silently change 23 during C2/C3.

---

# 17. Oracle architecture

A C **reference oracle** is allowed because it represents the preserved
legacy-C semantics being migrated.

Allowed:

```text
tools/quality/parser10-compound-oracle.c
tools/quality/parser10-compound-oracle-impl.c
```

These files:

```text
may encode frozen legacy behavior
may expose stable serialized output
must not issue terminal Factory/PARSER01 verdicts
```

They are **reference subjects**, not authority-bearing quality tools.

All terminal comparison, orchestration, provenance and verdict tooling SHALL
be PolyC.

---

# 18. F-POLYC-TOOLS binding

New substantive tooling SHALL be PolyC.

Expected PolyC tools:

```text
tools/quality/parser10-direct-differential.HC
tools/quality/parser10-4stage-fixedpoint-verify.HC
tools/quality/parser10-real-seam-runner.HC
tools/quality/parser10-generation-provenance-verify.HC
tools/quality/parser10-n01-mutation-runner.HC
tools/quality/parser10-n01-witness-verify.HC
tools/quality/parser10-ac-ledger-verify.HC
tools/quality/parser10-ac-witness-verify.HC
```

Shell wrappers:

```text
<=50 LOC
dispatch only
```

Required:

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
```

The C legacy oracle does not count as terminal tooling; its outputs must
always be consumed and judged by PolyC.

---

# 19. Direct differential contract

For each of 23 fixtures compare:

```text
legacy C oracle projection
vs
PolyC component projection
```

At minimum compare:

```text
return/error class
out_end
out_node_count
stable AST-kind projection
normalized serialized semantic projection
```

Forbidden:

```text
pointer identity
arena addresses
unstable diagnostics
build labels
host timestamps
```

Required:

```text
DIRECT_DIFFERENTIAL_TOTAL=23
DIRECT_DIFFERENTIAL_PASS=23
DIRECT_DIFFERENTIAL_FAIL=0
```

---

# 20. Differential projection schema

Use a stable machine-readable shape such as:

```text
fixture_id=<id>
rc=<n>
error=<enum>
end=<offset>
node_count=<n>
ast_kind=<n>
ast_projection_sha256=<sha>
```

If stable AST serialization proves unavailable without migrating forbidden
surfaces, use a strictly weaker projection only after C1/C2 records why it
still distinguishes the fixture classes.

Do not invent an opaque `"PASS"` token without state evidence.

---

# 21. Production authority migration

In stage0:

```text
legacy C path remains authoritative
```

In stage1+ with:

```text
HCC_USE_SELFHOST_COMPONENTS
```

`parseCompoundStatementInternal` SHALL delegate to ABI 7.

The PolyC outputs must influence actual parser behavior.

Required proof:

```text
ABI7_CALL_EXECUTED=YES
OUT_END_CONSUMED=YES
OUT_ERROR_CONSUMED=YES
POLYC_RESULT_CHANGES_PRODUCTION_STATE=YES
```

A shadow call whose outputs are discarded:

```text
HALT_SHADOW_AUTHORITY
```

---

# 22. No LEXER04-style shadow mistake

PARSER01 explicitly forbids:

```c
(void)out_end;
(void)out_error;
(void)out_node_count;
```

where the corresponding field is semantically required.

A component that is called but whose output does not control the parser does
not satisfy this ACT.
---

# 23. Production seam

Build two classes:

```text
G0 legacy production compiler
G1+ production compiler with ABI7 PolyC authority
```

Run the frozen 23 fixtures through production-shaped compilation/parser
paths.

Compare stable parser/AST projection.

Required migration contract:

```text
EXPECTED_LANGUAGE_SEMANTIC_DELTA=0
```

Therefore:

```text
G0_vs_G1_SEMANTIC_DIFF=0
```

unless C1 explicitly identifies an existing legacy bug and this ACT is
prospectively authorized to fix it.

No bug fix is presently authorized.

---

# 24. Four-generation requirement

PARSER01 requires independently built:

```text
G0
G1
G2
G3
```

component objects.

Compiler identities must be distinct/provenance-bound where expected.

No copying of prior outputs.

Forbidden:

```text
cp g1.o g2.o
cp g1.o g3.o
reuse one seam output for multiple generations
```

---

# 25. Component fixed point

Compile the PolyC subject independently with:

```text
G0 compiler
G1 compiler
G2 compiler
G3 compiler
```

Produce:

```text
parser10-compound.g0.o
parser10-compound.g1.o
parser10-compound.g2.o
parser10-compound.g3.o
```

Required:

```text
G0_G1_BYTE_EQUAL=YES
G0_G2_BYTE_EQUAL=YES
G0_G3_BYTE_EQUAL=YES
G1_G2_BYTE_EQUAL=YES
G1_G3_BYTE_EQUAL=YES
G2_G3_BYTE_EQUAL=YES

FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0
```

Use real byte equality.

SHA-256 is provenance/identity metadata, not a substitute for `MemCmp`.

---

# 26. Fixedpoint verifier

`parser10-4stage-fixedpoint-verify.HC` SHALL:

```text
read all four objects
compare bytes
report sizes
report SHA-256
report all 6 pair outcomes
fail non-zero on any mismatch
```

Required selftests:

```text
pristine four-way set -> PASS
single-byte mutation of temporary copy -> FAIL
pristine rerun -> PASS
```

---

# 27. Generation provenance

For G0..G3 record:

```text
generation
compiler_path
compiler_sha256
subject_source_sha256
object_path
object_sha256
object_size
build_command_sha256
```

Required:

```text
PROVENANCE_ROWS=4
PROVENANCE_FAIL=0
```

---

# 28. Generation-copy negative control

Because previous LEXER work exposed the danger of copied generation
artifacts, run:

```text
temporary copy:
  replace expected G3 object with G1 object
```

while retaining expected G3 provenance metadata.

Verifier must reject.

Required:

```text
GENERATION_COPY_DETECTED=YES
```

---

# 29. N01 production causal negative control

Purpose:

> prove ABI 7 is actually load-bearing in production.

Mutation SHALL:

```text
compile successfully
link successfully
run successfully far enough to produce parser output
change at least one expected production semantic observation
```

A build failure is **not** a valid causal witness.

---

# 30. N01 mutation choice

Preferred mutation:

```text
off-by-one out_end / consumed cursor
```

or another bounded mutation known to alter compound parsing without making
the component uncompilable.

The mutation runner must record:

```text
PRISTINE_COMPONENT_SHA256=<non-empty>
MUTATED_COMPONENT_SHA256=<non-empty>
COMPONENT_SHA_DIFFERS=YES

PRISTINE_SEAM_SHA256=<non-empty>
MUTATED_SEAM_SHA256=<non-empty>
SEAM_SHA_DIFFERS=YES or justified NO if linkage deterministic identity differs elsewhere

MUTATED_EXECUTION_RC=<executed>

AFFECTED_FIXTURE_COUNT>=1
AFFECTED_FIXTURE_SET=<explicit IDs>

N01_OUTCOME=PASS
```

---

# 31. Negative-control success criterion

Do **not** require all 23 fixtures to fail.

Required:

```text
AFFECTED_FIXTURE_COUNT>=1
```

and every affected fixture must be one whose path actually executes the
mutated behavior.

Also require:

```text
UNAFFECTED_FIXTURES_REMAIN_VALID=YES
```

The purpose is causal load-bearing evidence, not maximal destruction.

---

# 32. N01 forged/incomplete witness control

Create a temporary malformed/incomplete N01 evidence record.

`parser10-n01-witness-verify.HC` must reject it.

Required:

```text
N01_INCOMPLETE_WITNESS_REJECTED=YES
```

---

# 33. Parser bridge causal proof

Instrument or project enough state to prove:

```text
legacy stage0:
  parseCompoundStatementInternal C path executes

selfhost stage1+:
  BootstrapParseCompoundStatementInternal executes
```

Required:

```text
G0_AUTHORITY=LEGACY_C
G1_AUTHORITY=POLYC
G2_AUTHORITY=POLYC
G3_AUTHORITY=POLYC
```

No source-inspection-only claim.

---

# 34. Semantic production outputs

For each fixture and generation capture:

```text
fixture_id
generation
parse_rc
error_class
end_offset
node_count
ast_projection_sha256
```

Compare:

```text
G0 vs G1
G0 vs G2
G0 vs G3
G1 vs G2
G1 vs G3
G2 vs G3
```

Because the migration is intended semantics-preserving:

```text
SEMANTIC_PAIR_PASS=6
SEMANTIC_PAIR_FAIL=0
```

for each fixture unless explicitly marked invalid-input/error fixture, where
the error projection must still match.

---

# 35. No fake generation output

Every G0/G1/G2/G3 semantic output file must be produced by executing the
corresponding generation binary.

Required provenance fields:

```text
compiler_sha256
seam_binary_sha256
output_sha256
generation
```

No:

```text
copy previous generation output
rename previous generation output
post-process previous output into next generation evidence
```
---

# 36. Parser-specific malformed-input proof

At least:

```text
3 unclosed_brace fixtures
```

must prove the legacy and PolyC paths agree on:

```text
error class
consumed/end offset
no successful-close claim
```

Required:

```text
UNCLOSED_BRACE_EQUIVALENCE=PASS
```

---

# 37. Nested compound proof

At least:

```text
4 nested_compound fixtures
```

must prove:

```text
matching brace handling
nested node accounting
outer cursor/end position
```

Required:

```text
NESTED_COMPOUND_EQUIVALENCE=PASS
```

---

# 38. Declaration/statement boundary proof

The corpus deliberately includes:

```text
declaration in compound
ordinary statement
```

because the selected function dispatches into still-legacy subordinate
parser surfaces.

Required:

```text
DECL_CALLBACK_PATH_EXERCISED=YES
STMT_CALLBACK_PATH_EXERCISED=YES
```

and:

```text
POLYC_COMPONENT_DID_NOT_REIMPLEMENT_SUBORDINATE_PARSER_SEMANTICS=YES
```

---

# 39. Mid-body preprocessor fixtures

Three fixtures exercise preprocessor-shaped input within a compound body.

Purpose:

```text
prove PARSER01 preserves lexer/preprocessor interaction
without migrating INV.PREPROC.PP
```

Required:

```text
MID_BODY_PREPROC_EQUIVALENCE=PASS
```

If migration requires changes to `lexPreProc*`:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

---

# 40. C2 implementation boundary

C2 may create/modify only authorized files.

C2 SHALL implement:

```text
PolyC subject
ABI7 bridge
stage1+ delegation
PolyC terminal verifier/orchestrator tools
legacy C reference oracle
quality/build targets
23-fixture test corpus
```

C2 SHALL NOT:

```text
change parser language semantics intentionally
fix unrelated parser bugs
migrate parseStatement
migrate parseDeclOrStatement
migrate parseToplevelDef
change AST data structures
touch expression parser
```

---

# 41. C2 phase purity

C2 is implementation.

It may run developer tests, but closure evidence belongs to C3.

If a substantive implementation defect is discovered during C3:

```text
HALT_C2_DEFECT_FOUND_DURING_C3
```

Do not patch production code inside C3 and continue.

Open a bounded phase-correction ACT if needed.

---

# 42. Direct differential target

Provide:

```text
make parser10-direct-differential
```

Expected:

```text
DIRECT_DIFFERENTIAL_TOTAL=23
DIRECT_DIFFERENTIAL_PASS=23
DIRECT_DIFFERENTIAL_FAIL=0
STATUS=PASS
```

---

# 43. Fixedpoint target

Provide:

```text
make parser10-4stage-fixedpoint
```

Expected:

```text
PAIR_PASS=6
PAIR_FAIL=0
STATUS=PASS
```

---

# 44. Production seam target

Provide:

```text
make parser10-4stage-semantic-seam
```

Expected:

```text
FIXTURE_TOTAL=23
SEMANTIC_PAIR_PASS=<complete expected count>
SEMANTIC_PAIR_FAIL=0

G0_AUTHORITY=LEGACY_C
G1_AUTHORITY=POLYC
G2_AUTHORITY=POLYC
G3_AUTHORITY=POLYC

STATUS=PASS
```

The exact aggregate pair count must be computed mechanically as:

```text
23 fixtures × 6 generation pairs = 138
```

if the tool reports per-fixture pair comparisons.

Therefore preferable terminal token:

```text
SEMANTIC_PAIR_PASS=138
SEMANTIC_PAIR_FAIL=0
```

---

# 45. N01 target

Provide:

```text
make parser10-n01
```

Expected:

```text
MUTATED_BUILD=PASS
MUTATED_LINK=PASS
MUTATED_EXECUTION=PASS

AFFECTED_FIXTURE_COUNT>=1
N01_OUTCOME=PASS
```

---

# 46. Quality-tool authority

Terminal verdict-producing code SHALL be PolyC.

Allowed C:

```text
legacy semantic oracle only
```

Forbidden new substantive C:

```text
fixedpoint verifier
semantic verifier
mutation orchestrator
ledger verifier
witness verifier
provenance verifier
```

Required:

```text
TERMINAL_VERDICT_NON_POLYC_TOOL_COUNT=0
```

---

# 47. Shell budget

Any new shell file:

```text
<=50 LOC
```

and only:

```text
environment setup
path resolution
exec PolyC binary
```

No:

```text
semantic parsing
fixture classification
PASS/FAIL aggregation
hash comparison authority
```

Required:

```text
SHELL_BUDGET_VIOLATIONS=0
```

---

# 48. F-NO-PYTHON

Required:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

Historical Python baseline is forward-only residue, not this ACT's job.

---

# 49. Conservation: LEXER01/02

Run current canonical:

```text
lexer07-direct-differential
```

Required baseline:

```text
89/89 PASS
```

Required:

```text
LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
```

---

# 50. Conservation: LEXER03

Run:

```text
lexer08-direct-differential
```

Required:

```text
45/45 PASS
LEXER03_CONSERVATION=PASS
```

---

# 51. Conservation: LEXER04

Run at least:

```text
lexer09-direct-differential
lexer09 production-authority/seam check
```

Required:

```text
23/23 PASS
LEXER04_PRODUCTION_AUTHORITY_STILL_LIVE=YES
LEXER04_CONSERVATION=PASS
```
---

# 52. LEXER07 broad-corpus baseline

Frozen predecessor context:

```text
TOTAL=181
PASS_S0=166
PASS_S1=175
PASS_S2=175
PASS_S3=175

FAIL_S0=15
FAIL_S1=6
FAIL_S2=6
FAIL_S3=6

REGRESSION=6
```

This gate is historically red.

PARSER01 requirement is only:

```text
NEW_LEXER07_FAILURES=0
```

Compare failure identities, not merely counts.

Allowed:

```text
unchanged
improved
```

Forbidden:

```text
new failing corpus member
```

---

# 53. Parser-specific broad corpus

Create a bounded parser10 corpus that contains at least:

```text
all 23 direct fixtures
real source snippets containing nested bodies
function bodies with declarations
control-flow bodies
malformed brace cases
preprocessor-inside-body cases
```

Required:

```text
PARSER10_BROAD_CORPUS_NEW_REGRESSION=0
```

Do not make this an enormous repository-wide corpus in PARSER01.

---

# 54. F14

Do not modify closed evidence/HANDOFF trees from:

```text
LEXER01
LEXER02
LEXER03
LEXER04
SURFACE-RECON03
```

Required:

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

All PARSER01 evidence lives under:

```text
evidence/ACT-POLYC-SELFHOST-PARSER01/
```

---

# 55. Patch hygiene

Binding range:

```text
ENTRY_HEAD..HEAD
```

At every phase:

```sh
git diff --check "$ENTRY_HEAD"..HEAD
```

Required:

```text
PATCH_HYGIENE_ERRORS=0
```

No evidence-file exemption.

---

# 56. C1 artifacts

Produce:

```text
evidence/ACT-POLYC-SELFHOST-PARSER01/c1/

c1-entry-identity.txt
c1-red-component-absent.txt
c1-red-abi-absent.txt
c1-red-legacy-authority.txt

c1-function-shape.txt
c1-dependency-map.tsv
c1-state-read-write.tsv

c1-fixture-contract.tsv
c1-legacy-baseline.tsv

c1-proof-contract.tsv
c1-negative-control-contract.txt

c1-authorized-ac-contract.tsv
c1-required-result.txt
```

---

# 57. C1 required result

```text
COMPONENT_PRESENT=NO
ABI7_PRESENT=NO

LEGACY_AUTHORITY_PRESENT=YES
POLYC_PRODUCTION_AUTHORITY_PRESENT=NO

UNCLASSIFIED_STATE_DEPENDENCIES=0

FIXTURE_TOTAL=23
FIXTURE_BASELINE_BOUND_TO_ENTRY_HEAD=YES

N01_CONTRACT_DEFINED=YES

PRODUCTION_SOURCE_DELTA=0
```

---

# 58. C2 artifacts

C2 may add implementation and test/tool source only.

Expected:

```text
src/parser_bridge.h
src/parser.c
src/CMakeLists.txt
Makefile

tools/bootstrap/selfhost-parser-compound-statement-internal.HC

tools/quality/parser10-compound-oracle.c
tools/quality/parser10-compound-oracle-impl.c

tools/quality/parser10-direct-differential.HC
tools/quality/parser10-4stage-fixedpoint-verify.HC
tools/quality/parser10-real-seam-runner.HC
tools/quality/parser10-generation-provenance-verify.HC
tools/quality/parser10-n01-mutation-runner.HC
tools/quality/parser10-n01-witness-verify.HC
tools/quality/parser10-ac-ledger-verify.HC
tools/quality/parser10-ac-witness-verify.HC

scripts/quality/parser10-*.sh
```

subject to the shell cap.

---

# 59. C2 mandatory developer checks

Before C2 commit, run:

```text
PolyC subject builds
direct differential developer run
stage1 production binary builds
fixedpoint verifier selftest
N01 mutation builds/links/runs
```

Do not claim closure from C2.

---

# 60. C2 freeze

At C2 commit freeze SHA-256 for:

```text
ACT body
PolyC subject
parser bridge
modified parser.c
fixture contract
legacy baseline
all terminal verifier source
```

C3 must prove no C2 production/tool source mutation.

Required:

```text
C2_TO_C3_IMPLEMENTATION_FROZEN=YES
```

---

# 61. C3 phase

C3 is evidence only.

It SHALL execute fresh:

```text
direct differential
4-gen fixedpoint
4-gen semantic seam
N01 causal mutation
N01 malformed-witness control
generation-copy control
generation provenance
parser10 broad corpus
LEXER conservation
LEXER07 baseline-delta
Factory gates
F-POLYC-TOOLS
F-NO-PYTHON
F14
patch hygiene
```

No production mutation.

---

# 62. C3 evidence set

At minimum:

```text
evidence/.../c3/

c3-entry-identity.txt
c3-freeze-replay.tsv

c3-direct-differential.txt
c3-production-seam.txt

c3-fixedpoint-g0.txt
c3-fixedpoint-g1.txt
c3-fixedpoint-g2.txt
c3-fixedpoint-g3.txt
c3-fixedpoint-verify.txt

c3-generation-provenance.tsv
c3-generation-copy-control.txt

c3-n01-production-causal-control.txt
c3-n01-incomplete-witness-control.txt

c3-unclosed-brace.txt
c3-nested-compound.txt
c3-decl-stmt-boundary.txt
c3-mid-body-preproc.txt

c3-parser10-broad-corpus.txt

c3-lexer01-conservation.txt
c3-lexer02-conservation.txt
c3-lexer03-conservation.txt
c3-lexer04-conservation.txt
c3-lexer07-baseline-delta.txt

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
---

# 63. C3 required result

```text
DIRECT_DIFFERENTIAL_TOTAL=23
DIRECT_DIFFERENTIAL_PASS=23
DIRECT_DIFFERENTIAL_FAIL=0

FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0

SEMANTIC_FIXTURE_TOTAL=23
SEMANTIC_PAIR_PASS=138
SEMANTIC_PAIR_FAIL=0

G0_AUTHORITY=LEGACY_C
G1_AUTHORITY=POLYC
G2_AUTHORITY=POLYC
G3_AUTHORITY=POLYC

PROVENANCE_ROWS=4
PROVENANCE_FAIL=0

GENERATION_COPY_DETECTED=YES

MUTATED_BUILD=PASS
MUTATED_LINK=PASS
MUTATED_EXECUTION=PASS
AFFECTED_FIXTURE_COUNT>=1
N01_OUTCOME=PASS
N01_INCOMPLETE_WITNESS_REJECTED=YES

UNCLOSED_BRACE_EQUIVALENCE=PASS
NESTED_COMPOUND_EQUIVALENCE=PASS
DECL_CALLBACK_PATH_EXERCISED=YES
STMT_CALLBACK_PATH_EXERCISED=YES
MID_BODY_PREPROC_EQUIVALENCE=PASS

PARSER10_BROAD_CORPUS_NEW_REGRESSION=0

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS
NEW_LEXER07_FAILURES=0

TERMINAL_VERDICT_NON_POLYC_TOOL_COUNT=0
SHELL_BUDGET_VIOLATIONS=0

NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

C2_TO_C3_IMPLEMENTATION_FROZEN=YES
C3_PHASE_PURITY=PASS

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0
```

---

# 64. Acceptance criteria

All are mandatory.

## AC01

```text
C0_AUTH_BEFORE_WORK=YES
```

## AC02

```text
WORKTREE_CLEAN_AT_C0=YES
```

## AC03

```text
LEGACY_AUTHORITY_PRESENT=YES
POLYC_PRODUCTION_AUTHORITY_PRESENT=NO
```

at C1 RED.

## AC04

```text
UNCLASSIFIED_STATE_DEPENDENCIES=0
```

## AC05

```text
FIXTURE_TOTAL=23
```

## AC06

```text
FIXTURE_BASELINE_BOUND_TO_ENTRY_HEAD=YES
```

## AC07

```text
PARSER01_POLYC_COMPONENT_EXISTS=YES
```

## AC08

```text
ABI7_DEFINED=YES
```

## AC09

```text
ABI7_CALL_EXECUTED=YES
```

## AC10

```text
ABI7_LOAD_BEARING=YES
```

## AC11

```text
DIRECT_DIFFERENTIAL_PASS=23
DIRECT_DIFFERENTIAL_FAIL=0
```

## AC12

```text
G0_AUTHORITY=LEGACY_C
G1_AUTHORITY=POLYC
G2_AUTHORITY=POLYC
G3_AUTHORITY=POLYC
```

## AC13

```text
SEMANTIC_PAIR_PASS=138
SEMANTIC_PAIR_FAIL=0
```

## AC14

```text
FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0
```

## AC15

```text
PROVENANCE_ROWS=4
PROVENANCE_FAIL=0
```

## AC16

```text
GENERATION_COPY_DETECTED=YES
```

## AC17

```text
MUTATED_BUILD=PASS
MUTATED_LINK=PASS
MUTATED_EXECUTION=PASS
```

## AC18

```text
AFFECTED_FIXTURE_COUNT>=1
```

## AC19

```text
N01_OUTCOME=PASS
```

## AC20

```text
N01_INCOMPLETE_WITNESS_REJECTED=YES
```

## AC21

```text
UNCLOSED_BRACE_EQUIVALENCE=PASS
```

## AC22

```text
NESTED_COMPOUND_EQUIVALENCE=PASS
```

## AC23

```text
DECL_CALLBACK_PATH_EXERCISED=YES
```

## AC24

```text
STMT_CALLBACK_PATH_EXERCISED=YES
```

## AC25

```text
MID_BODY_PREPROC_EQUIVALENCE=PASS
```

## AC26

```text
PARSER10_BROAD_CORPUS_NEW_REGRESSION=0
```

## AC27

```text
LEXER01_CONSERVATION=PASS
```

## AC28

```text
LEXER02_CONSERVATION=PASS
```

## AC29

```text
LEXER03_CONSERVATION=PASS
```

## AC30

```text
LEXER04_CONSERVATION=PASS
```

## AC31

```text
NEW_LEXER07_FAILURES=0
```

## AC32

```text
TERMINAL_VERDICT_NON_POLYC_TOOL_COUNT=0
```

## AC33

```text
SHELL_BUDGET_VIOLATIONS=0
```

## AC34

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

## AC35

```text
CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0
```

## AC36

```text
C2_TO_C3_IMPLEMENTATION_FROZEN=YES
```

## AC37

```text
C3_PHASE_PURITY=PASS
```

## AC38

```text
GATE_FAST=PASS
```

## AC39

```text
APPEND_ONLY_FAIL=0
```

## AC40

```text
PATCH_HYGIENE_ERRORS=0
```

## AC41

```text
WORKTREE_CLEAN_BEFORE_C4=YES
```

## AC42

```text
EXACT_COMMIT_COUNT_AT_CLOSE=5
```

## AC43

```text
POST_C4_COMMIT_COUNT=0
```
---

# 65. AC ledger binding

`mandatory-ac-status.tsv` SHALL have exactly AC01..AC43.

Columns:

```text
ac_id
predicate_sha256
status
evidence_path
evidence_sha256
witness_key
notes
```

Allowed statuses:

```text
PASS
FAIL
DEFERRED_TO_C4
```

At C3:

```text
AC01..AC40 must be PASS
AC41 may be PASS if measured before C4
AC42/AC43 = DEFERRED_TO_C4
```

At terminal close:

```text
43 PASS
0 FAIL
```

No alternative token vocabulary.

---

# 66. Evidence truth binding

Ledger identity alone is insufficient.

Every PASS row must point to evidence containing a machine-checkable witness
for the actual predicate.

`parser10-ac-witness-verify.HC` SHALL verify:

```text
evidence file exists
SHA matches
required witness token exists
token value satisfies AC predicate
```

Required:

```text
WITNESS_FAIL=0
WITNESS_MISSING=0
```

---

# 67. False-PASS control

Construct a temporary ledger/evidence combination where:

```text
status=PASS
```

but the evidence witness says:

```text
FAIL
```

Verifier must reject.

Required:

```text
PREDICATE_LIE_DETECTED=YES
```

---

# 68. Evidence-SHA mutation control

Mutate a temporary evidence copy without updating ledger SHA.

Required:

```text
EVIDENCE_SHA_MUTATION_DETECTED=YES
```

---

# 69. AC-ID shuffle control

Shuffle two temporary AC IDs/evidence bindings.

Required:

```text
AC_ID_SHUFFLE_DETECTED=YES
```

---

# 70. C4 precondition

Before creating C4:

```sh
git status --short
git diff --check "$ENTRY_HEAD"..HEAD
```

Required:

```text
WORKTREE_CLEAN_BEFORE_C4=YES
PATCH_HYGIENE_ERRORS=0
```

Also:

```text
C3_PHASE_PURITY=PASS
```

If false:

```text
HALT_C4_PRECONDITION
```

Do not repair and close in the same C4.

---

# 71. C4 scope

C4 may add only:

```text
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER01.md

evidence/ACT-POLYC-SELFHOST-PARSER01/c4/
  c4-parent-identity.txt
  c4-terminal-ledger.txt

docs/ROADMAP.md
```

No C1/C2/C3 evidence edits.

No production edits.

---

# 72. C4 terminal measurements

C4 terminal ledger records:

```text
C0_SHA
C1_SHA
C2_SHA
C3_SHA
C4_PARENT_SHA

COMMIT_COUNT_BEFORE_C4=4
EXPECTED_COMMIT_COUNT_AFTER_C4=5

WORKTREE_CLEAN_PRE_C4=YES
PATCH_HYGIENE_PRE_C4=PASS
```

The C4 commit itself carries the final ACT verdict.

Do not claim its own SHA from inside itself.

---

# 73. Commit topology

Exactly:

```text
C0 AUTH
C1 RED/CONTRACT
C2 IMPL
C3 VERIFY
C4 CLOSE
```

Five commits.

No:

```text
C0+C1
C2.1
C2.5
C3.5
C4 fill
SHA fill
whitespace cleanup
post-close ledger
```

If another commit is required:

```text
HALT_PHASE_CORRECTION_REQUIRED
```

Do not make a sixth PARSER01 commit.

---

# 74. C4 HANDOFF

Required sections:

```text
VERDICT
IDENTITY
MISSION
SELECTION LINEAGE
ROOT CAUSE / LEGACY AUTHORITY
RED
ABI 7
IMPLEMENTATION
DIRECT DIFFERENTIAL
PRODUCTION AUTHORITY
4-GENERATION FIXEDPOINT
4-GENERATION SEMANTIC SEAM
NEGATIVE CONTROLS
GENERATION PROVENANCE
PARSER-SPECIFIC CONTROLS
CONSERVATION
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

# 75. PASS_TRUE_GREEN terminal predicate

Requires all:

```text
AC_TOTAL=43
AC_PASS=43
AC_FAIL=0

DIRECT_DIFFERENTIAL_PASS=23
DIRECT_DIFFERENTIAL_FAIL=0

SEMANTIC_PAIR_PASS=138
SEMANTIC_PAIR_FAIL=0

FIXEDPOINT_PAIR_PASS=6
FIXEDPOINT_PAIR_FAIL=0

G0_AUTHORITY=LEGACY_C
G1_AUTHORITY=POLYC
G2_AUTHORITY=POLYC
G3_AUTHORITY=POLYC

GENERATION_COPY_DETECTED=YES

N01_OUTCOME=PASS
AFFECTED_FIXTURE_COUNT>=1
N01_INCOMPLETE_WITNESS_REJECTED=YES

UNCLOSED_BRACE_EQUIVALENCE=PASS
NESTED_COMPOUND_EQUIVALENCE=PASS
DECL_CALLBACK_PATH_EXERCISED=YES
STMT_CALLBACK_PATH_EXERCISED=YES
MID_BODY_PREPROC_EQUIVALENCE=PASS

PARSER10_BROAD_CORPUS_NEW_REGRESSION=0

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_CONSERVATION=PASS
NEW_LEXER07_FAILURES=0

TERMINAL_VERDICT_NON_POLYC_TOOL_COUNT=0
SHELL_BUDGET_VIOLATIONS=0

NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

CLOSED_EVIDENCE_DELTA=0
CLOSED_HANDOFF_DELTA=0

PREDICATE_LIE_DETECTED=YES
EVIDENCE_SHA_MUTATION_DETECTED=YES
AC_ID_SHUFFLE_DETECTED=YES

GATE_FAST=PASS
APPEND_ONLY_FAIL=0
PATCH_HYGIENE_ERRORS=0

WORKTREE_CLEAN_BEFORE_C4=YES
EXACT_COMMIT_COUNT_AT_CLOSE=5
POST_C4_COMMIT_COUNT=0
```

Anything weaker:

```text
HALT
```

---

# 76. HALT taxonomy

```text
HALT_ENTRY_DIRTY
HALT_AUTHORIZATION_MISSING

HALT_RED_NOT_REPRODUCED
HALT_DEPENDENCY_EXPLOSION
HALT_SCOPE_EXPANSION_REQUIRED
HALT_FIXTURE_CONTRACT_CHANGE_REQUIRED

HALT_COMPONENT_BUILD
HALT_ABI7_CONTRACT
HALT_SHADOW_AUTHORITY

HALT_DIRECT_DIFFERENTIAL
HALT_PRODUCTION_SEAM
HALT_FIXEDPOINT
HALT_PROVENANCE

HALT_GENERATION_COPY_NOT_DETECTED

HALT_N01_BUILD
HALT_N01_LINK
HALT_N01_EXECUTION
HALT_N01_NOT_LOAD_BEARING
HALT_N01_WITNESS_NOT_LOAD_BEARING

HALT_UNCLOSED_BRACE_DIVERGENCE
HALT_NESTED_COMPOUND_DIVERGENCE
HALT_DECL_CALLBACK_NOT_EXERCISED
HALT_STMT_CALLBACK_NOT_EXERCISED
HALT_PREPROC_INTERACTION_DIVERGENCE

HALT_PARSER10_BROAD_CORPUS_REGRESSION

HALT_LEXER01_CONSERVATION
HALT_LEXER02_CONSERVATION
HALT_LEXER03_CONSERVATION
HALT_LEXER04_CONSERVATION
HALT_LEXER07_NEW_REGRESSION

HALT_F_POLYC_TOOLS
HALT_SHELL_BUDGET
HALT_F_NO_PYTHON
HALT_F14_VIOLATION

HALT_AC_LEDGER
HALT_AC_WITNESS
HALT_PREDICATE_LIE_CONTROL
HALT_EVIDENCE_SHA_CONTROL
HALT_AC_ID_SHUFFLE_CONTROL

HALT_C2_DEFECT_FOUND_DURING_C3
HALT_C2_TO_C3_DRIFT
HALT_C3_PHASE_PURITY

HALT_FACTORY_GATE
HALT_APPEND_ONLY
HALT_PATCH_HYGIENE
HALT_C4_PRECONDITION
HALT_PHASE_CORRECTION_REQUIRED
```

A mechanically justified HALT is a successful execution outcome.

---

# 77. Residue explicitly not blocking PARSER01

Do not fix:

```text
ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01

LEXER07 historical:
  FAIL_S0=15
  FAIL_S1=6
  FAIL_S2=6
  FAIL_S3=6

hcc JIT ROTR-as-global residue

historical LEXER04 proof/governance residue
```

unless one becomes a direct mechanical blocker of PARSER01.

If that happens:

```text
HALT_DEPENDENCY
```

rather than silently absorbing it.

---

# 78. Expected board effect

Before:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03 = CLOSED
INV.PARSER.COMPOUND                = LEGACY_C_AUTHORITY
ACT-POLYC-SELFHOST-PARSER01        = READY
```

After PASS:

```text
ACT-POLYC-SELFHOST-PARSER01 = CLOSED PASS_TRUE_GREEN

INV.PARSER.COMPOUND = SELFHOSTED_TRUE_GREEN

BootstrapParseCompoundStatementInternal = PRODUCTION_AUTHORITATIVE

PARSER_SELFHOST_COMPONENT_COUNT += 1
```

---

# 79. Successor selection after PARSER01

Do **not** automatically declare:

```text
PARSER02 = parseStatement
```

or:

```text
PARSER02 = parseToplevelDef
```

PARSER01 HANDOFF should record newly unblocked candidates.

Then either:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON04
```

or a previously frozen successor may proceed only if PARSER01 produces
mechanical evidence that its preconditions remain valid.

Given the coupling discovered by RECON03, fresh recon is preferred.

---

# 80. Governing invariant

The purpose is not to make a PolyC function that resembles the C parser.

The purpose is:

```text
legacy parser authority
        ↓
bounded semantic contract
        ↓
PolyC implementation
        ↓
production delegation
        ↓
causal negative control
        ↓
generation-independent proof
        ↓
previous compiler behavior conserved
```

A component that merely compiles is insufficient.

A component that passes an isolated differential but is ignored by
production is insufficient.

A component whose mutation only breaks its build is insufficient.

A component whose stage2/stage3 evidence is copied is insufficient.

PARSER01 closes only when the real stage1+ compiler is demonstrably parsing
compound bodies through PolyC ABI 7 with behavior equivalent to the frozen
legacy C authority.
