# ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Qualify and, where mechanically necessary, boundedly correct HolyC global-scope `static` function linkage across parser → AST → native codegen → object symbol tables → JIT publication

**Repository:** PolyC
**Branch:** `main`

**Class:** COMPILER / LANGUAGE SEMANTICS / LINKAGE / JIT

**Entry lineage:**

```text
ACT-POLYC-SELFHOST-LEXER04-CORRECTION01
    = HALT_MECHANICAL_BLOCKING_B5

HEAD = 06c7951
```

**Important distinction:**

This ACT does **not** attempt to resume LEXER04-CORRECTION01.

It takes one useful compiler repair discovered during that HALT and qualifies it as a first-class compiler feature.

The historical C2A change already exists in Git.

This ACT does not retroactively authorize that historical mutation.

It authorizes:

1. qualification of the existing static-function-linkage implementation;
2. permanent regression tests;
3. bounded corrections to that implementation if C1 falsification finds defects.


# 0. Mission

Before the C2A repair, HolyC accepted:

```text
static <return-type> Foo(...)
```

at global scope but discarded the linkage intent.

The parser explicitly recorded:

```text
is_static = 1;
(void)is_static;
```

and the compiler subsequently treated the function as externally visible.

Mechanical evidence demonstrated the consequence:

```text
TU A:
    static ROTR
        ↓
    _ROTR = global T

TU B:
    static ROTR
        ↓
    _ROTR = global T

ld -r A.o B.o
    ↓
duplicate symbol _ROTR
```

The existing repair changes the pipeline to carry function-static linkage through:

```text
source syntax
    ↓
parser
    ↓
AST.fn_is_static
    ↓
native codegen visibility
    ↓
JIT publication policy
```

The current RED/GREEN witness proves one important case:

```text
before: _ROTR = T / T → duplicate-symbol failure
after:  _ROTR = t / t → coexistence
```

But that single witness is not sufficient to establish complete compiler semantics.

This ACT SHALL answer:

> Does HolyC now implement global-scope static **function** linkage coherently across all supported compiler paths, without breaking external functions, declaration rules, JIT chunk isolation, native backends, or existing programs?

A TRUE_GREEN close establishes:

```text
STATIC_FUNCTION_INTERNAL_LINKAGE = IMPLEMENTED
STATIC_FUNCTION_TU_ISOLATION     = PROVEN
PUBLIC_FUNCTION_EXTERNAL_LINKAGE = CONSERVED
JIT_PRIVATE_FUNCTION_ISOLATION   = PROVEN
NATIVE_BACKEND_LINKAGE           = PROVEN
COMPILER_REGRESSION              = NONE
```

---

# 1. Non-goals

This ACT is limited to **function linkage**.

It SHALL NOT expand into:

```text
static global variables
thread-local storage
C visibility attributes
weak symbols
COMDAT
inline semantics
anonymous namespaces
shared-library visibility policy
LTO
general symbol-resolution redesign
```

It SHALL NOT repair the independent libtos symbol gaps:

```text
_FREE
_STRNCMP
_SpawnAndCapture
_MEMSET
_STRLEN_FAST
```

Those remain the subject of:

```text
ACT-POLYC-LIBTOS-SYMBOL-GAPS01
```

The libtos blocker was independently reproduced with the static-linkage fix reverted, so it is outside this ACT. The existing HALT evidence records that directly.

---

# 2. Semantic model

The compiler's required model is:

```text
GLOBAL FUNCTION WITHOUT static
    => external linkage
    => externally visible object symbol
    => eligible for global JIT publication

GLOBAL FUNCTION WITH static
    => translation-unit/internal linkage
    => local/private object symbol
    => callable within its translation unit/chunk
    => not globally published by JIT
    => same spelling may independently exist in another TU
```

This aligns with the conventional compiler model in which C `static` maps to internal linkage; LLVM documents `internal` linkage as corresponding to C `static`.

This external model is a cross-check only.

The exact HolyC syntax/error behavior is frozen mechanically in C1 from the live compiler.

---

# 3. Historical implementation under qualification

Current implementation touches:

```text
src/ast.h
src/ast.c
src/parser.c
src/jit-common.h
src/jit-common.c
src/aarch64.c
src/x86_64.c
```

Observed implementation architecture:

```text
AST
  fn_is_static

PARSER
  KW_STATIC
      ↓
  function declaration/definition path
      ↓
  fn_is_static

NATIVE CODEGEN
  static fn
      ↓
  suppress unconditional global export

JIT
  private_fns
      ↓
  suppress symbols / host_symbols registration
```

The ACT SHALL verify that this list is complete.

It MUST NOT assume those seven files cover every relevant backend merely because the historical patch touched seven files.

---

# 4. C0 AUTH

This document must be committed before new qualification evidence, tests or corrections.

Record:

```sh
git rev-parse HEAD
git branch --show-current
git status --porcelain=v1
```

Required:

```text
BRANCH=main
WORKTREE_CLEAN_AT_AUTH=YES
```

Bind:

```text
ENTRY_HEAD=<C0-parent>
STATIC_LINKAGE_HISTORICAL_FIX=5e967c8
LEXER04_C01_HALT=06c7951
```

No production mutation before C0.

---

# 5. C1 — implementation-path inventory

Mechanically discover every path that can emit, publish or resolve a function symbol.

Search at minimum:

```text
parseToplevelDef
parseFunctionOrDef
parseFunctionDef
astFunction
astFunctionWithLinkage
astFunctionSetStatic
fn_is_static

.globl
.global
private
local
visibility

symbols
host_symbols
private_fns
hccJitCompileChunk
hccJitFinalize

aarch64
x86_64
jit
llvm
object
```

Produce:

```text
evidence/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01/c1/
c1-function-linkage-paths.tsv
```

Schema:

```text
path_id
source_file
symbol
role
native_or_jit
backend
static_aware
extern_aware
runtime_reachable
qualification_method
evidence
```

Required:

```text
FUNCTION_LINKAGE_PATH_UNKNOWN=0
```

---

# 6. Backend completeness

C1 SHALL explicitly determine whether each of these exists and participates in function emission:

```text
AARCH64_NATIVE
X86_64_NATIVE
AARCH64_JIT
X86_64_JIT
LLVM_BACKEND
OTHER
```

For every live path classify:

```text
STATIC_LINKAGE_HANDLED
STATIC_LINKAGE_NOT_HANDLED
NOT_APPLICABLE
```

Required:

```text
LIVE_BACKEND_UNKNOWN=0
```

If a live backend ignores static linkage:

```text
RED_BACKEND_STATIC_LINKAGE_GAP=YES
```

and C2 may repair it only if the file is authorized by §18.

---

# 7. C1 — semantic contract matrix

Create:

```text
c1-static-function-contract.tsv
```

The minimum cases follow.

## S01 — one private function

```text
static U64 Foo() { return 1; }
public U64 Entry() { return Foo(); }
```

Required:

```text
Foo callable inside TU
Foo object symbol local/private
Entry externally visible
program result correct
```

---

## S02 — same static spelling in two TUs

TU A:

```text
static U64 Foo() { return 11; }
public U64 A() { return Foo(); }
```

TU B:

```text
static U64 Foo() { return 22; }
public U64 B() { return Foo(); }
```

Required:

```text
both objects compile
both private Foo symbols coexist
combined object links
A() == 11
B() == 22
```

This is the canonical isolation witness.

---

## S03 — two external definitions

TU A:

```text
U64 Foo() { return 11; }
```

TU B:

```text
U64 Foo() { return 22; }
```

Required:

```text
both Foo symbols external
combined duplicate definition rejected
```

The static fix MUST NOT accidentally privatize normal functions.

---

## S04 — private + external same spelling across TUs

TU A:

```text
static U64 Foo() { return 11; }
public U64 A() { return Foo(); }
```

TU B:

```text
U64 Foo() { return 22; }
public U64 B() { return Foo(); }
```

Required:

```text
private Foo(A) coexists with external Foo(B)
A() == 11
B() == 22
external Foo resolves to B's definition
```

---

## S05 — duplicate static definition in one TU

```text
static U64 Foo() { return 1; }
static U64 Foo() { return 2; }
```

Freeze the current intended parser behavior.

Expected baseline from historical evidence:

```text
REJECT duplicate definition
```

Required:

```text
SAME_TU_STATIC_DUPLICATE_REJECTED=YES
```

---

## S06 — static forward declaration + static definition

If HolyC supports function prototypes/declarations in this form, test:

```text
static U64 Foo();
static U64 Foo() { return 1; }
```

Required behavior shall be frozen from current language rules.

If syntax is unsupported:

```text
S06=N/A_SYNTAX_UNSUPPORTED
```

This N/A must be determined in C1, not at closure.

---

## S07 — external/public forward declaration + definition

Verify ordinary function declaration behavior remains unchanged.

---

## S08 — mixed-linkage declarations

Test relevant supported combinations such as:

```text
U64 Foo();
static U64 Foo() { ... }
```

and:

```text
static U64 Foo();
U64 Foo() { ... }
```

C1 SHALL determine current intended HolyC semantics.

If intended semantics cannot be derived from current compiler/tests/specification:

```text
HALT_MIXED_LINKAGE_SEMANTICS_UNSPECIFIED
```

Do not invent C compatibility silently.

---

# 8. C1 — JIT contract

Native object behavior alone is insufficient.

The JIT must satisfy:

```text
STATIC_FUNCTION:
    callable by code in owning chunk
    not published as global symbol

PUBLIC_FUNCTION:
    published normally
```

The ACT SHALL test at least the following.

---

## J01 — static helper works within one JIT chunk

```text
static Foo
public Entry -> Foo
```

Required:

```text
Entry executes
Foo executes
Foo not globally discoverable
```

---

## J02 — identical static names in independent chunks

Chunk A:

```text
static Foo -> 11
A -> Foo
```

Chunk B:

```text
static Foo -> 22
B -> Foo
```

Required:

```text
A()==11
B()==22
no collision
no cross-binding
```

---

## J03 — static then public same spelling in later chunk

This is a critical lifetime test.

Chunk 1:

```text
static Foo -> 11
A -> Foo
```

Chunk 2:

```text
public Foo -> 22
B -> Foo
```

Required:

```text
public Foo in chunk2 IS globally published
B()==22
A()==11
```

This falsifies stale `private_fns` state leaking between chunks.

---

## J04 — public then static same spelling in later chunk

Chunk 1:

```text
public Foo -> 11
A -> Foo
```

Chunk 2:

```text
static Foo -> 22
B -> Foo
```

Required behavior:

```text
static Foo does not overwrite/publish as global
B binds to its own private Foo
A retains prior semantics
global Foo remains the public definition according to JIT policy
```

Freeze exact lookup behavior in C1.

---

## J05 — static symbols absent from public JIT lookup

Where the API permits:

```text
hccJitLookup("Foo")
```

must not expose a private-only Foo.

Required:

```text
PRIVATE_FN_GLOBAL_LOOKUP=NOT_FOUND
```

---

# 9. `private_fns` lifetime audit

The current implementation introduced:

```text
Map *private_fns
```

on `HccJit`.

C1 SHALL determine:

```text
where allocated
where cleared/reset
where freed
whether state is per-JIT or per-chunk
```

Produce:

```text
c1-private-fns-lifetime.txt
```

Required:

```text
PRIVATE_FNS_LIFETIME_CLASSIFIED=YES
```

If the map persists across chunks without correct removal/reset semantics:

```text
RED_PRIVATE_FNS_STALE_STATE=YES
```

This is an in-scope compiler bug.

---

# 10. Native symbol contract

For every supported native backend, generate an object containing:

```text
static PrivateFn
public PublicFn
```

Inspect the symbol table using the platform's canonical `nm`/object tool.

Normalize only platform spelling decoration such as leading `_`.

Required logical output:

```text
PrivateFn:
    binding = LOCAL/PRIVATE
    externally_visible = NO

PublicFn:
    binding = GLOBAL/EXTERNAL
    externally_visible = YES
```

LLVM's own object/linkage model explicitly distinguishes internal symbols from external ones, and internal linkage corresponds to C `static`.

---

# 11. AArch64 qualification

C1 discovers the canonical way to exercise the AArch64 backend.

Required:

```text
AARCH64_STATIC_EXPORT_SUPPRESSED=YES
AARCH64_PUBLIC_EXPORT_PRESERVED=YES
```

Prefer object-level symbol proof.

Assembly-level evidence is additionally useful:

```text
static function:
    no externally-visible .globl/.global directive

public function:
    global directive remains
```

If the current host cannot execute AArch64 output, symbol/codegen qualification is still required.

---

# 12. x86_64 qualification

Likewise:

```text
X86_64_STATIC_EXPORT_SUPPRESSED=YES
X86_64_PUBLIC_EXPORT_PRESERVED=YES
```

The ACT may use cross-target object/assembly generation.

Execution is not required on a non-x86 host if the repository cannot execute cross-target output locally.

But codegen/symbol qualification IS required because `src/x86_64.c` was modified by the existing repair.

If the backend cannot be exercised mechanically:

```text
HALT_CHANGED_BACKEND_UNQUALIFIABLE
```

Do not close with an untested modified backend.

---

# 13. Additional backend qualification

If C1 discovers another live emitter, e.g.:

```text
src/aarch64-jit.c
LLVM backend
```

then it must be included.

If it currently ignores `fn_is_static`:

```text
RED_ADDITIONAL_BACKEND_STATIC_GAP=YES
```

No live changed/relevant function-emission backend may remain unclassified.

---

# 14. Parser/AST propagation contract

Mechanically prove:

```text
KW_STATIC
    ↓
parser remembers function staticness
    ↓
AST_FUNC.fn_is_static = 1
    ↓
downstream emitters observe same flag
```

Also prove normal functions default:

```text
AST_FUNC.fn_is_static = 0
```

Required:

```text
STATIC_FLAG_TRUE_PATH=PASS
STATIC_FLAG_FALSE_PATH=PASS
```

No uninitialized-state acceptance.

---

# 15. Redefinition/upgrade paths

The existing repair touched function-definition upgrade/redefinition behavior.

C1 SHALL enumerate every branch that can convert:

```text
declaration -> definition
existing symbol -> new definition
prototype -> function body
```

and verify `fn_is_static` is preserved correctly.

Produce:

```text
c1-function-upgrade-paths.tsv
```

Required:

```text
UPGRADE_PATH_UNKNOWN=0
```

This is especially important for:

```text
static declaration
    ↓
later static definition
```

and any existing compiler "upgrade" path.

---

# 16. C1 RED outcomes

C1 may discover:

```text
NO_NEW_DEFECTS
```

or one/more bounded REDs such as:

```text
RED_PRIVATE_FNS_STALE_STATE
RED_X86_64_STATIC_EXPORT
RED_AARCH64_STATIC_EXPORT
RED_JIT_GLOBAL_LOOKUP
RED_DECLARATION_UPGRADE_LINKAGE
RED_ADDITIONAL_BACKEND_STATIC_GAP
```

All REDs must be mechanically reproduced before C2.

C1 closes with:

```text
STATIC_LINKAGE_CONTRACT_FROZEN=YES
QUALIFICATION_MATRIX_FROZEN=YES
RED_COUNT=N
```

---

# 17. Production mutation scope

This ACT authorizes bounded correction only within linkage propagation.

Pre-authorized files:

```text
src/ast.h
src/ast.c
src/parser.c
src/jit-common.h
src/jit-common.c
src/aarch64.c
src/x86_64.c
```

Conditionally authorized only if C1 proves they are live function-emission paths:

```text
src/aarch64-jit.c
src/llvm-backend.c
```

No other production file is authorized.

If another file is required:

```text
HALT_SCOPE_EXPANSION_REQUIRED
```

---

# 18. Allowed mutation semantics

C2 may change only:

```text
function static-linkage propagation
object symbol visibility/binding
JIT private-symbol publication/lifetime
declaration->definition linkage preservation
```

C2 may NOT alter:

```text
function calling convention
name mangling except visibility-local mechanics
parameter passing
return ABI
parser grammar unrelated to static function declarations
variable static semantics
lexer behavior
optimization
code layout except consequences of local linkage
```

---

# 19. Test fixtures

Add durable fixtures under a bounded directory such as:

```text
tests/compiler/static-function-linkage/
```

Required fixture families:

```text
s01-single-static
s02-two-tu-same-static
s03-two-tu-same-external
s04-static-plus-external
s05-same-tu-static-duplicate
s06-static-forward-definition       # if syntax supported
s07-public-forward-definition
s08-mixed-linkage                   # after C1 freezes semantics

j01-jit-single-private
j02-jit-two-private-same-name
j03-jit-private-then-public
j04-jit-public-then-private
j05-jit-private-lookup
```

Target names may follow repo convention.

---

# 20. Test runner

Preferred durable target:

```text
make static-function-linkage-test
```

Permitted orchestration:

```text
Makefile
<=50 LOC shell dispatch
existing hcc
nm
ld
repository-native test executables
```

No new Python.

No large shell semantic implementation.

The compiler's own observable outputs and object symbol tables are the oracle.

---

# 21. C2 behavior

If C1 finds no new implementation defect:

```text
C2 = REGRESSION TEST INSTALLATION
```

Do not mutate production gratuitously.

If C1 finds bounded defects:

```text
C2 = MINIMAL STATIC-LINKAGE CORRECTION
```

Only the failing path(s) may change.

Every repair must have:

```text
RED_BEFORE
GREEN_AFTER
```

using the same test.

---

# 22. JIT stale-state negative control

This is mandatory even if it passes immediately.

Execute:

```text
chunk1:
    static Foo -> 11

chunk2:
    public Foo -> 22
```

Then prove:

```text
PUBLIC_FOO_AFTER_PRIVATE_FOO_VISIBLE=YES
PUBLIC_FOO_VALUE=22
```

If not:

```text
HALT_JIT_PRIVATE_STATE_LEAK
```

The test exists specifically because `private_fns` is stored on `HccJit`, and the current implementation must prove its lifetime is appropriate.

---

# 23. Cross-TU binding control

S02 must prove more than "link succeeds".

Execute both wrappers.

Required:

```text
A()==11
B()==22
```

If both return the same value:

```text
HALT_STATIC_CROSS_BIND
```

even if symbol-table inspection looks local.

---

# 24. External-linkage conservation control

The repair must not over-privatize functions.

Required:

```text
PUBLIC_FUNCTION_OBJECT_SYMBOL=GLOBAL
PUBLIC_FUNCTION_JIT_LOOKUP=VISIBLE
PUBLIC_FUNCTION_CROSS_TU_CALL=PASS
```

Failure:

```text
HALT_EXTERNAL_LINKAGE_REGRESSION
```

---

# 25. Genuine unresolved external control

Compile/link a fixture referencing a truly undefined external function.

Required:

```text
UNRESOLVED_EXTERNAL_STILL_FAILS=YES
```

The static-linkage fix must not broadly suppress linker errors.

---

# 26. Same-TU duplicate control

Required:

```text
SAME_TU_STATIC_DUPLICATE_REJECTED=YES
```

The fix must not reinterpret local linkage as permission for duplicate definitions within one translation unit.

---

# 27. Symbol identity evidence

For S02 and S04, store:

```text
object path
object SHA-256
nm/symbol-table output
symbol binding classification
link rc
runtime result
```

Create:

```text
c3-symbol-provenance.tsv
```

Schema:

```text
fixture
tu
object
object_sha256
symbol
binding
visibility
expected
status
```

---

# 28. Backend evidence

Produce independently:

```text
c3-aarch64-linkage.txt
c3-x86_64-linkage.txt
```

and, if discovered:

```text
c3-aarch64-jit-linkage.txt
c3-llvm-linkage.txt
```

Each must state:

```text
BACKEND=<name>
STATIC_LOCAL=PASS
PUBLIC_GLOBAL=PASS
```

No inference from another backend.

---

# 29. JIT evidence

Produce:

```text
c3-jit-linkage.txt
```

Required ledger:

```text
J01_SINGLE_STATIC=PASS
J02_TWO_PRIVATE_SAME_NAME=PASS
J03_PRIVATE_THEN_PUBLIC=PASS
J04_PUBLIC_THEN_PRIVATE=PASS
J05_PRIVATE_GLOBAL_LOOKUP=PASS
```

---

# 30. Parser/AST evidence

Produce:

```text
c3-parser-ast-linkage.txt
```

Required:

```text
KW_STATIC_CAPTURED=YES
AST_FN_IS_STATIC_TRUE=YES
NORMAL_FN_IS_STATIC_FALSE=YES
UPGRADE_PATHS_PASS=YES
```

---

# 31. Compiler conservation

Run the authoritative existing compiler suite.

At minimum:

```text
make gate-fast
```

plus the repository's current compiler tests discovered at execution time.

Also rerun the relevant self-host conservation set:

```text
LEXER01 = PASS
LEXER02 = PASS
LEXER03 = PASS
LEXER04_PRESERVED_ENGINEERING = PASS
```

This ACT must not regress the working `BootstrapLinkDirective` implementation.

---

# 32. Bootstrap compiler conservation

Because static functions can affect generated objects globally, rebuild the canonical bootstrap chain:

```text
G0
G1
G2
G3
```

Required:

```text
BOOTSTRAP_CHAIN_BUILD=PASS
```

If canonical fixed-point gates exist for broader compiler generations, run them.

A changed compiler binary is not automatically a failure because this ACT intentionally changes static symbol linkage.

Any divergence must be explained by the static-linkage feature or treated as:

```text
HALT_UNEXPLAINED_BOOTSTRAP_DRIFT
```

---

# 33. Existing ROTR witness

Re-run the original reproducer fresh.

Required:

```text
ROTR_TU_A_STATIC_SYMBOL=LOCAL
ROTR_TU_B_STATIC_SYMBOL=LOCAL
ROTR_COMBINED_LINK_RC=0
A_ROTR_EXTERNAL=YES
B_ROTR_EXTERNAL=YES
```

This retains continuity with the discovery lineage.

---

# 34. Mutation controls

The qualification machinery must reject broken linkage.

At minimum run three temporary controls.

## M01 — force static function global

Temporarily mutate a generated/object test path so `Foo` becomes global.

Expected:

```text
S02 verifier/test FAIL
duplicate collision detected
```

## M02 — force public function local

Expected:

```text
external-linkage conservation FAIL
```

## M03 — stale private JIT name

Inject/retain `Foo` in private tracking across chunk boundary.

Expected:

```text
J03 FAIL
```

Canonical production files must be restored before final evidence.

Required:

```text
M01=PASS
M02=PASS
M03=PASS
```

Here PASS means the test suite detected the injected defect.

---

# 35. F-NO-PYTHON

Required:

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
NEW_PYTHON_VIOLATIONS=0
```

---

# 36. F-POLYC-TOOLS

No new substantive non-PolyC quality tool.

Allowed:

```text
HC fixtures
existing compiler binaries
existing nm/ld
<=50 LOC dispatch shell
Makefile orchestration
```

Required:

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
SHELL_LOC_GATE=PASS
```

This ACT does not need the currently blocked PolyC fixed-point verifier and therefore does not depend on resolving the libtos gap.

---

# 37. Historical evidence immutability

Do not modify:

```text
evidence/ACT-POLYC-SELFHOST-LEXER04/**
```

except this ACT's own namespace if placed elsewhere.

Preferred namespace:

```text
evidence/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01/
```

Do not modify closed Lexer04 HANDOFFs.

Do not "clean up" the previous HALT's whitespace residue inside its evidence.

---

# 38. Evidence namespace

Use:

```text
evidence/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01/
```

Suggested layout:

```text
c1/
  c1-entry-identity.txt
  c1-function-linkage-paths.tsv
  c1-static-function-contract.tsv
  c1-private-fns-lifetime.txt
  c1-function-upgrade-paths.tsv
  c1-backend-inventory.tsv
  c1-red-summary.txt
  c1-scope-freeze.txt

c2/
  c2-entry-identity.txt
  c2-repair-summary.txt

c3/
  c3-entry-identity.txt

  c3-s01-single-static.txt
  c3-s02-two-tu-static.txt
  c3-s03-two-tu-external.txt
  c3-s04-static-plus-external.txt
  c3-s05-same-tu-duplicate.txt
  c3-s06-forward-static.txt
  c3-s07-forward-public.txt
  c3-s08-mixed-linkage.txt

  c3-aarch64-linkage.txt
  c3-x86_64-linkage.txt

  c3-jit-linkage.txt
  c3-parser-ast-linkage.txt

  c3-symbol-provenance.tsv
  c3-rotr-regression.txt

  c3-mutation-globalized-static.txt
  c3-mutation-privatized-public.txt
  c3-mutation-jit-stale-private.txt

  c3-bootstrap-conservation.txt
  c3-selfhost-conservation.txt

  c3-f-no-python.txt
  c3-f-polyc-tools.txt
  c3-factory-gates.txt
  c3-patch-hygiene.txt

  mandatory-ac-status.tsv
  c3-required-result.txt

c4/
  c4-entry-identity.txt
```

---

# 39. Acceptance criteria

## AC01 — authorization precedes work

```text
C0_AUTH_PRECEDES_C1=YES
C0_AUTH_PRECEDES_ANY_NEW_MUTATION=YES
```

Mandatory.

## AC02 — implementation-path inventory complete

```text
FUNCTION_LINKAGE_PATH_UNKNOWN=0
```

Mandatory.

## AC03 — backend inventory complete

```text
LIVE_BACKEND_UNKNOWN=0
```

Mandatory.

## AC04 — semantic contract frozen

```text
STATIC_LINKAGE_CONTRACT_FROZEN=YES
```

Mandatory.

## AC05 — static flag propagation

```text
STATIC_FLAG_TRUE_PATH=PASS
STATIC_FLAG_FALSE_PATH=PASS
```

Mandatory.

## AC06 — single-TU private function

```text
S01=PASS
```

Mandatory.

## AC07 — two-TU private isolation

```text
S02=PASS
A_VALUE=11
B_VALUE=22
```

Mandatory.

## AC08 — ordinary external collision

```text
S03=PASS
DUPLICATE_EXTERNAL_REJECTED=YES
```

Mandatory.

## AC09 — private/external coexistence

```text
S04=PASS
```

Mandatory.

## AC10 — same-TU duplicate static

```text
S05=PASS
```

Mandatory.

## AC11 — supported declaration/definition linkage

```text
FORWARD_DECLARATION_MATRIX=PASS
```

Mandatory for syntactically-supported rows.

## AC12 — AArch64 native linkage

```text
AARCH64_STATIC_EXPORT_SUPPRESSED=YES
AARCH64_PUBLIC_EXPORT_PRESERVED=YES
```

Mandatory.

## AC13 — x86_64 native linkage

```text
X86_64_STATIC_EXPORT_SUPPRESSED=YES
X86_64_PUBLIC_EXPORT_PRESERVED=YES
```

Mandatory.

## AC14 — every additional live emitter

```text
ADDITIONAL_BACKEND_LINKAGE=PASS
```

Mandatory where C1 discovers one.

## AC15 — JIT single private function

```text
J01=PASS
```

Mandatory.

## AC16 — JIT same private name across chunks

```text
J02=PASS
```

Mandatory.

## AC17 — JIT private→public lifetime

```text
J03=PASS
```

Mandatory.

## AC18 — JIT public→private lifetime

```text
J04=PASS
```

Mandatory.

## AC19 — private JIT symbol not globally exposed

```text
J05=PASS
```

Mandatory.

## AC20 — genuine public JIT symbols remain visible

```text
PUBLIC_FUNCTION_JIT_LOOKUP=VISIBLE
```

Mandatory.

## AC21 — unresolved external remains error

```text
UNRESOLVED_EXTERNAL_STILL_FAILS=YES
```

Mandatory.

## AC22 — original ROTR RED/GREEN remains green

```text
ROTR_REPRO_AFTER=PASS
```

Mandatory.

## AC23 — upgrade/redefinition paths

```text
UPGRADE_PATH_UNKNOWN=0
UPGRADE_PATHS_PASS=YES
```

Mandatory.

## AC24 — mutation M01

```text
M01=PASS
```

Mandatory.

## AC25 — mutation M02

```text
M02=PASS
```

Mandatory.

## AC26 — mutation M03

```text
M03=PASS
```

Mandatory.

## AC27 — compiler suite

```text
COMPILER_REGRESSION_SUITE=PASS
```

Mandatory.

## AC28 — bootstrap conservation

```text
BOOTSTRAP_CHAIN_BUILD=PASS
```

Mandatory.

## AC29 — prior self-host conservation

```text
LEXER01=PASS
LEXER02=PASS
LEXER03=PASS
LEXER04_PRESERVED_ENGINEERING=PASS
```

Mandatory.

## AC30 — F-NO-PYTHON

```text
NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0
```

Mandatory.

## AC31 — F-POLYC-TOOLS

```text
NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
SHELL_LOC_GATE=PASS
```

Mandatory.

## AC32 — Factory gates

```text
gate-fast=PASS
factory-append-only-test=PASS
```

plus current authoritative gates.

Mandatory.

## AC33 — patch hygiene

For this ACT's range:

```text
git diff --check <ENTRY_HEAD>..<CANDIDATE_CLOSE>
```

must be clean.

Historical HALT evidence whitespace outside this ACT's range is not in scope.

Mandatory.

## AC34 — historical evidence immutable

```text
CLOSED_PREDECESSOR_EVIDENCE_DELTA=0
```

Mandatory.

## AC35 — C3 frozen at C4

```text
C4_C3_EVIDENCE_DELTA=0
```

Mandatory.

## AC36 — worktree clean

```text
WORKTREE_CLEAN_AT_CLOSE=YES
```

Mandatory.

## AC37 — append-only history

```text
APPEND_ONLY_HISTORY=TRUE
```

Mandatory.

---

# 40. Mandatory status table

Create:

```text
evidence/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01/c3/
mandatory-ac-status.tsv
```

Schema:

```text
ac_id
description
mandatory
status
evidence_path
```

Permitted statuses:

```text
PASS
FAIL
N/A
```

`N/A` is legal only for syntax/backend cases explicitly determined conditionally applicable in C1.

For unconditional criteria:

```text
mandatory=1
```

Required at TRUE_GREEN:

```text
MANDATORY_FAIL=0
MANDATORY_UNKNOWN=0
MANDATORY_MISSING_EVIDENCE=0
```

No `PARTIAL`.

No `DEFERRED`.

---

# 41. C3 required-result ledger

C3 shall mechanically emit at least:

```text
ACT=ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01

ENTRY_HEAD=<sha>

FUNCTION_LINKAGE_PATH_UNKNOWN=0
LIVE_BACKEND_UNKNOWN=0

STATIC_LINKAGE_CONTRACT_FROZEN=YES

STATIC_FLAG_TRUE_PATH=PASS
STATIC_FLAG_FALSE_PATH=PASS

S01=PASS
S02=PASS
S03=PASS
S04=PASS
S05=PASS
FORWARD_DECLARATION_MATRIX=PASS

AARCH64_STATIC_EXPORT_SUPPRESSED=YES
AARCH64_PUBLIC_EXPORT_PRESERVED=YES

X86_64_STATIC_EXPORT_SUPPRESSED=YES
X86_64_PUBLIC_EXPORT_PRESERVED=YES

J01=PASS
J02=PASS
J03=PASS
J04=PASS
J05=PASS

PRIVATE_FN_GLOBAL_LOOKUP=NOT_FOUND
PUBLIC_FUNCTION_JIT_LOOKUP=VISIBLE

UNRESOLVED_EXTERNAL_STILL_FAILS=YES

ROTR_REPRO_AFTER=PASS

UPGRADE_PATHS_PASS=YES

M01=PASS
M02=PASS
M03=PASS

COMPILER_REGRESSION_SUITE=PASS
BOOTSTRAP_CHAIN_BUILD=PASS

LEXER01_CONSERVATION=PASS
LEXER02_CONSERVATION=PASS
LEXER03_CONSERVATION=PASS
LEXER04_PRESERVED_ENGINEERING=PASS

NEW_PYTHON_SOURCES=0
NEW_PYTHON_INVOCATIONS=0

NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0
SHELL_LOC_GATE=PASS

FACTORY_GATES=PASS
PATCH_HYGIENE=PASS

CLOSED_PREDECESSOR_EVIDENCE_DELTA=0
C4_C3_EVIDENCE_DELTA=0

WORKTREE_CLEAN=TRUE
APPEND_ONLY_HISTORY=TRUE

VERDICT=PASS_TRUE_GREEN
```

---

# 42. HALT taxonomy

## `HALT_ENTRY_DIRTY`

Unexplained entry dirt.

## `HALT_FUNCTION_LINKAGE_PATH_UNKNOWN`

An emission/publication path cannot be classified.

## `HALT_CHANGED_BACKEND_UNQUALIFIABLE`

A modified/live backend cannot be mechanically exercised.

## `HALT_MIXED_LINKAGE_SEMANTICS_UNSPECIFIED`

Declaration linkage semantics cannot be safely inferred.

## `HALT_STATIC_TU_COLLISION`

Two identical private names still collide across TUs.

## `HALT_STATIC_CROSS_BIND`

Two TUs' private functions bind to the wrong body.

## `HALT_EXTERNAL_LINKAGE_REGRESSION`

Ordinary public functions become private/unavailable.

## `HALT_JIT_PRIVATE_STATE_LEAK`

A private symbol contaminates later JIT chunks.

## `HALT_JIT_PRIVATE_SYMBOL_EXPOSED`

Private function is globally discoverable.

## `HALT_UNRESOLVED_EXTERNAL_MASKED`

A true missing external no longer produces failure.

## `HALT_SAME_TU_DUPLICATE_ACCEPTED`

Duplicate static definitions in one TU become silently accepted contrary to frozen semantics.

## `HALT_UPGRADE_PATH_LINKAGE_LOSS`

Declaration→definition processing loses staticness.

## `HALT_BACKEND_STATIC_LINKAGE_GAP`

A live backend still exports a static function.

## `HALT_MUTATION_CONTROL_FAILED`

M01/M02/M03 fails to detect its injected defect.

## `HALT_COMPILER_REGRESSION`

Existing compiler tests regress.

## `HALT_UNEXPLAINED_BOOTSTRAP_DRIFT`

Bootstrap output changes outside explained static-linkage effects.

## `HALT_SCOPE_EXPANSION_REQUIRED`

Repair requires production files outside §17.

## `HALT_F_NO_PYTHON_REGRESSION`

New Python authority introduced.

## `HALT_F_POLYC_TOOLS_REGRESSION`

New substantive non-PolyC tooling introduced.

## `HALT_PREDECESSOR_EVIDENCE_MUTATED`

Closed prior artifacts changed.

## `HALT_C3_MUTATED_AFTER_FREEZE`

C4 modifies C3 evidence.

---

# 43. Phase topology

## C0 AUTH

This document.

## C1 CONTRACT / FALSIFICATION

No production mutation.

Produce:

```text
path inventory
backend inventory
semantic matrix
JIT lifetime analysis
upgrade-path inventory
RED witnesses
scope freeze
```

## C2 IMPLEMENT / REGRESSION GUARD

If RED_COUNT=0:

```text
install durable regression fixtures/gate only
```

If RED_COUNT>0:

```text
apply smallest correction within §17
install corresponding regression tests
```

## C3 EVIDENCE

Fresh execution only.

No implementation edits.

If a defect is found:

```text
HALT_C2_DEFECT_FOUND_DURING_C3
```

Do not patch inside C3.

## C4 CLOSE

Only:

```text
HANDOFF
ROADMAP
C4 identity
```

C3 frozen.

---

# 44. Commit topology

Prospectively authorized maximum:

```text
5 commits
```

Expected:

```text
C0 AUTH
C1 CONTRACT/RED
C2 IMPL/TESTS
C3 EVIDENCE
C4 CLOSE
```

If a defect discovered during C3 needs another implementation commit:

```text
HALT_COMMIT_TOPOLOGY_EXHAUSTED
```

Obtain an explicit amendment before another commit.

No amend.

No rebase.

No force-push.

No reset+recommit.

---

# 45. Successful closure meaning

TRUE_GREEN authorizes the statement:

```text
HolyC global-scope static functions now have
translation-unit/internal linkage.

Their staticness survives parsing and AST construction.

Native object emission keeps them local.

Independent translation units may use the same private
function spelling without collision or cross-binding.

Public functions remain externally visible.

The JIT does not publish private functions globally and
does not leak private-name state across chunks.

All live native/JIT backends under the current compiler
implement the same linkage distinction.

The behavior is guarded by durable adversarial tests.
```

It does NOT authorize claims about:

```text
static variables
weak symbols
visibility attributes
inline linkage
shared-library visibility
```

---

# 46. C4 HANDOFF

Create:

```text
docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md
```

Required sections:

```text
VERDICT
IDENTITY
DISCOVERY LINEAGE
SEMANTIC CONTRACT
IMPLEMENTATION UNDER QUALIFICATION
RED
CORRECTIONS, IF ANY
NATIVE BACKENDS
JIT
NEGATIVE CONTROLS
CONSERVATION
FACTORY GATES
RESIDUE
NEXT
```

The HANDOFF must state explicitly whether the seven-file historical repair was accepted unchanged or required additional correction.

---

# 47. NEXT

After PASS_TRUE_GREEN:

```text
NEXT = ACT-POLYC-LIBTOS-SYMBOL-GAPS01
```

That ACT restores the PolyC-native verifier substrate blocked by the missing libtos symbols.

Then:

```text
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
```

can finish:

```text
PolyC-native LEXER09 fixed-point verification
true G0/G1/G2/G3 production #link semantic seam
remaining LEXER04 requalification
```

After that:

```text
ACT-POLYC-SELFHOST-SURFACE-RECON03
```

---

# 48. Execution instruction

Start with C0.

C1's most valuable early tests are:

```text
1. J03:
   static Foo in chunk 1
   public Foo in chunk 2
   prove public Foo is still globally visible.

2. S04:
   static Foo in TU A
   external Foo in TU B
   prove both coexist and bind correctly.

3. Backend inventory:
   prove every live function emitter respects fn_is_static.
```

If all three are green, the historical fix is much more credible.

If any fails, we have found a real compiler bug worth fixing inside this ACT.

---

## Status

PASS_TRUE_GREEN

C0 AUTH committed (4ac7810). C1 RED + ROOT CAUSE committed (1f24d6b) with RED_PRIVATE_FNS_STALE_STATE found and mechanically reproduced against entry HEAD 06c7951. C2 IMPL committed (5542c1c) with a bounded 2-line JIT-lifetime correction in src/jit-common.c plus 8-line comment hygiene and a durable regression fixture set (tests/compiler/static-function-linkage/, scripts/quality/static-function-linkage-test.sh at 44 LOC, Makefile target). C3 EVIDENCE committed (97f421c) with 27 evidence files covering S01..S08 native, J01..J05 JIT, AArch64 + x86_64 native backends, M01..M03 mutations, parser/AST propagation, conservation, factory gates, and the mandatory AC ledger (AC01..AC37 all PASS). C4 CLOSE: this entry + HANDOFF committed.

The seven-file historical repair at commit 5e967c8 was ACCEPTED UNCHANGED for its intended semantics. The bounded JIT-lifetime correction found during C1 falsification is recorded as RED_PRIVATE_FNS_STALE_STATE; it is the only production-code change in this ACT.

The bounded managed universe for the closure-status oracle includes this ACT pair (added in C4). The oracle-acceptable Status token is PASS_TRUE_GREEN; the matching HANDOFF VERDICT token is PASS_TRUE_GREEN; the trailers in the C4 commit are `ACT: ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01`, `ACT-Phase: C4`, `ACT-Verdict: CLOSE_PASS_TRUE_GREEN`.
