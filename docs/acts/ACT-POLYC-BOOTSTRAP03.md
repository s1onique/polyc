# ACT-POLYC-BOOTSTRAP03

**Title:** B2 first self-host — stage1-produced PolyC compiler component
consumed by stage2.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-BOOTSTRAP02` CLOSED PASS
(15/15 component differential, 6/6 cursor, 6/6 production
Lexer seam, 175/175 broad corpus stage0↔stage1, EOF cursor
state equivalence, EOF pointer safety)

**Class:** BOOTSTRAP / FIRST-SELF-HOST / COMPILER-CLOSURE

**Production compiler semantic changes:** **NONE**
(only build-graph addition for stage2; B1 component source
frozen)

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**MEMORY01 widening:** **FORBIDDEN**

**B0 lexer changes:** **FORBIDDEN**

**B1 component source changes:** **FORBIDDEN**
(`tools/bootstrap/bootstrap02-ident.HC` is frozen by §5
of the predecessor ACT and §14 of this ACT)

**B1 production lexer changes:** **FORBIDDEN**
(`src/lexer.c`, `src/lexer_bridge.h` frozen)

**VERDICT (target):** `PASS`

---

# 0. Mission

Establish the **first mechanically demonstrated self-host
cycle** in PolyC.

B2 succeeds only if:

```text
stage1 compiler
    compiles a PolyC-authored compiler component
        ->
stage1-produced component object
    is linked into stage2 compiler
        ->
stage2 compiler
    actually calls that component
        ->
stage2 reproduces the proven compiler behaviour
```

Binding success predicate:

```text
FIRST_SELF_HOST := PASS
```

with this exact definition:

```text
FIRST_SELF_HOST :=
    B1_COMPONENT_LANGUAGE          == POLYC
 && B1_COMPONENT_PRODUCER_STAGE2   == STAGE1
 && STAGE2_LINKS_STAGE1_ARTIFACT   == YES
 && STAGE2_USES_STAGE1_ARTIFACT    == YES
 && STAGE1_STAGE2_BEHAVIOR_EQ      == PASS
```

B2 explicitly does **not** establish:

```text
FULL_SELF_HOST              = YES
COMPILER_IMPLEMENTED_POLYC  = YES
HOST_C_DEPENDENCY           = ZERO
BOOTSTRAP_STABILITY         = PASS
TRUSTING_TRUST_RESOLVED     = YES
```

Those claims are forbidden.

---

# 1. Why B2 exists

B1 crossed the language boundary but did not yet close
the production chain.

At B1:

```text
stage0 (host-built hcc)
  -> compiles bootstrap02-ident.HC
  -> links bootstrap02-ident.o into stage1
```

C3 proved stage1 **can** compile that same source, but its
output was only compared against the stage0 object. It was
not used to construct a successor compiler.

Therefore:

```text
B1_PARTIAL_SELF_HOST = PASS
FIRST_SELF_HOST      = NO
```

The B2 transition is exactly:

```text
stage1-produced bootstrap component
        becomes
an input to stage2
```

That is the smallest honest step that deserves the board
label **FIRST SELF-HOST**.

---

# 2. Predecessor contract

C1 must mechanically re-establish the following
predecessor facts rather than trusting prose:

```text
ACT-POLYC-BOOTSTRAP02_CLOSE_CARDINALITY = 1

B1_PARTIAL_SELF_HOST              = PASS
B1_COMPONENT_POLYC                = YES
B1_COMPONENT_STAGE0_BUILT         = YES
B1_COMPONENT_STAGE1_BOUND         = YES
B1_REAL_LEXER_EQ                  = PASS_6_OF_6
B1_BROAD_CORPUS_EQ                = PASS_175_OF_175
B1_STAGE1_COMPILES_OWN_COMPONENT  = YES
B1_REPRODUCIBLE                   = YES

FIRST_SELF_HOST                   = NO
STAGE2_CREATED                    = NO

B2_UNLOCKED                       = YES
```

Also re-establish:

```text
worktree      = clean
branch        = main
git replace   = empty
```

Any contradiction in the executable B1 predecessor
evidence:

```text
HALT_B1_PREDECESSOR_NOT_GREEN
```

---

# 3. Inherited governance residue

The B1 closure omitted three forward-bound
C1-CORRECTION01 descriptive fields.

Carry them into this ACT without reopening B1:

```text
B1_ASCII_DOMAIN =
  YES

B1_NON_ASCII_EQUIVALENCE =
  NOT_CLAIMED

B1_REFERENCE_MODEL_ORACLE =
  tools/quality/bootstrap02-ident-oracle.c
```

Classification:

```text
CLASS             = GOVERNANCE / CLOSURE_COMPLETENESS
PRODUCTION_IMPACT = NONE
BLOCKS_B2         = NO
```

This ACT records them in its C1 predecessor freeze and
moves on.

Do **not** create another BOOTSTRAP02 correction.

---

# 4. The B2 architecture

Use three compiler identities.

```text
STAGE0
  ordinary ./hcc
  does NOT contain _BootstrapScanIdent

STAGE1
  build/hcc-bootstrap02
  contains B1 component compiled by stage0

STAGE2
  build/hcc-bootstrap03
  contains B1 component compiled BY STAGE1
```

Critical artifact provenance:

```text
S0_B1_OBJ =
  B1 component compiled with stage0
  -> build/bootstrap02-ident.o

S1_B1_OBJ =
  B1 component compiled with stage1
  -> build/bootstrap03-ident.stage1.o

STAGE1 links S0_B1_OBJ
STAGE2 links S1_B1_OBJ
```

The build graph must make that distinction explicit.

It is **forbidden** for stage2 accidentally to reuse the
stage0-generated B1 object.

---

# 5. B2 defining invariant

This is the central acceptance rule:

```text
STAGE2_B1_ARTIFACT_PROVENANCE = STAGE1
```

Mechanical evidence must prove both:

```text
1. stage1 invoked on:
     tools/bootstrap/bootstrap02-ident.HC

2. the exact resulting object is the object passed into
   stage2's link
```

A matching SHA between stage0 and stage1 B1 objects is
desirable but **not sufficient** to prove provenance.

You need causal binding, not merely equal bytes.

Therefore evidence must include:

```text
producer command
output path
artifact hash
stage2 link command
stage2 symbol table
stage2 call site
```

---

# 6. Authorized implementation scope

B2 may change only the bootstrap construction seam
necessary to produce stage2.

Expected authorized files:

```text
Makefile
src/CMakeLists.txt
```

if required for the bounded stage2 build path.

New evidence/build helpers are allowed under:

```text
tools/quality/bootstrap03-*
```

only if the existing machinery cannot establish
provenance mechanically.

New production PolyC compiler functionality is **not
required**.

The following B1 files should remain unchanged unless a
RED proves otherwise:

```text
tools/bootstrap/bootstrap02-ident.HC
src/lexer.c
src/lexer_bridge.h
```

Preferred implementation:

```text
make bootstrap03-component-build
make bootstrap03-stage2
make bootstrap03-test
```

where:

```text
bootstrap03-component-build:
    stage1 -> stage1-produced B1 object

bootstrap03-stage2:
    normal compiler objects
    + stage1-produced B1 object
    -> build/hcc-bootstrap03
```

---

# 7. Forbidden scope

No:

```text
new parser self-hosting
new AST self-hosting
new IR self-hosting
new LLVM backend self-hosting
new AArch64 work
new x86_64 work
MEMORY01 widening
GEP01 repair
unit/jit runner repair
token-dump API
B1 semantic changes
identifier grammar widening
non-ASCII claims
full compiler rewrite
stage3 construction
B3 work
push plumbing
historical evidence cleanup
```

Especially forbidden:

```text
changing BootstrapScanIdent merely to make stage hashes differ
```

The stage provenance must come from the build graph, not
artificial source perturbation.

---

# 8. C1 RED mission

C1 must prove that the self-host loop is currently
**open**.

Expected RED:

```text
STAGE1_EXISTS = YES

STAGE1_CAN_COMPILE_B1_SOURCE = YES

STAGE1_PRODUCED_B1_OBJECT_EXISTS =
    possibly transient / evidence-only

STAGE2_EXISTS = NO

STAGE2_LINKS_STAGE1_B1_OBJECT = NO

STAGE2_USES_STAGE1_B1_OBJECT = NO

FIRST_SELF_HOST = NO
```

Principal RED is **not** "stage1 cannot compile the B1
source."

B1 already proved that it can.

Principal RED is:

> The artifact produced by stage1 has not yet been
> consumed to construct a successor compiler stage.

Binding C1 result:

```text
FIRST_SELF_HOST_EDGE_CLOSED = NO
```

---

# 9. C1 provenance experiment

Before production mutation, manually perform the future
stage2 artifact chain in a temporary directory if
existing commands permit it.

Conceptually:

```bash
build/hcc-bootstrap02 \
  -c tools/bootstrap/bootstrap02-ident.HC \
  -o /tmp/bootstrap03-ident.stage1.o
```

Capture:

```text
producer = build/hcc-bootstrap02
input    = tools/bootstrap/bootstrap02-ident.HC
output   = /tmp/bootstrap03-ident.stage1.o
symbol   = T _BootstrapScanIdent
sha256   = observed
```

Then determine exactly where the current stage1 link
consumes the stage0 component.

The C1 seam map must answer:

```text
Which build target creates stage1?
Where is the B1 object added?
What variable/path names it?
Can that input be parameterized cleanly for stage2?
```

No implementation in C1.

---

# 10. C1 RED packet

Create:

```text
evidence/ACT-POLYC-BOOTSTRAP03/c1/
```

Required:

```text
README.md
predecessor-freeze.txt
b1-governance-residue.txt
stage-identity.txt
stage1-self-compile.txt
stage2-absence.txt
build-seam-map.txt
principal-red.txt
c1-required-result.txt
```

`c1-required-result.txt` must end with:

```text
B1_PREDECESSOR_GREEN        = YES
STAGE1_SELF_SOURCE_COMPILE  = PASS
STAGE2_EXISTS               = NO
FIRST_SELF_HOST_EDGE        = OPEN
C1_TO_C2_GATE               = OPEN
```

---

# 11. C1 acceptance criteria

```text
AC01 main branch
AC02 clean worktree
AC03 git replace empty

AC04 B1 authoritative CLOSE count = 1
AC05 B1_PARTIAL_SELF_HOST = PASS
AC06 FIRST_SELF_HOST predecessor = NO

AC07 stage0 identity captured
AC08 stage1 identity captured
AC09 stage1 contains _BootstrapScanIdent
AC10 stage0 excludes _BootstrapScanIdent

AC11 stage1 freshly compiles B1 source
AC12 stage1-produced B1 object exports _BootstrapScanIdent

AC13 current stage1 build consumes stage0-produced B1 object
AC14 no canonical stage2 exists
AC15 no stage2 consumes the stage1-produced B1 object

AC16 build seam mechanically mapped
AC17 B1 ASCII-domain residue restated
AC18 no production mutation in C1

AC19 B0 conservation PASS
AC20 B1 conservation PASS

AC21 FIRST_SELF_HOST_EDGE = OPEN
AC22 C1_TO_C2_GATE = OPEN
```

---

# 12. C1 HALTs

### `HALT_B1_PREDECESSOR_NOT_GREEN`

Executable B1 predecessor truth contradicts closure.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_STAGE1_CANNOT_COMPILE_B1_SOURCE`

A B1 property regressed before B2.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_STAGE2_ALREADY_CANONICAL`

A canonical stage2 self-host edge already exists and the
RED premise is false.

```text
HALT_CLASS  = AUTHORIZATION
BLOCKS_NEXT = YES
```

This is a successful RED discovery requiring the ACT to
be redesigned around the actual current tree.

---

# 13. C2 IMPL mission

Implement **only** the canonical stage1→stage2 artifact
flow.

Expected build graph:

```text
make bootstrap03-component-build

  build/hcc-bootstrap02
      |
      | compile
      v
  build/bootstrap03-ident.stage1.o


make bootstrap03-stage2

  ordinary compiler build objects
      +
  build/bootstrap03-ident.stage1.o
      |
      v
  build/hcc-bootstrap03
```

Binding:

```text
STAGE2_B1_PRODUCER = STAGE1
```

---

# 14. Build provenance must be impossible to fake accidentally

Do not allow this:

```text
bootstrap03-stage2:
    bootstrap02-component-build
    ...
```

if `bootstrap02-component-build` uses stage0.

B2 needs a **distinct target and path**.

Recommended naming:

```text
build/bootstrap02-ident.stage0.o
build/bootstrap03-ident.stage1.o
```

or equivalent explicit lineage.

Avoid a generic:

```text
build/bootstrap02-ident.o
```

being silently overwritten by different producers during
the same proof.

The evidence must always be able to answer:

```text
WHO MADE THIS OBJECT?
```

---

# 15. Stage2 compiler identity

Stage2 must be a distinct compiler binary:

```text
build/hcc-bootstrap03
```

It must not overwrite:

```text
./hcc
build/hcc
build/hcc-bootstrap02
```

Required:

```text
STAGE0_PRESENT = YES
STAGE1_PRESENT = YES
STAGE2_PRESENT = YES
```

---

# 16. Static stage2 binding

Prove:

```text
nm build/hcc-bootstrap03
```

contains:

```text
_BootstrapScanIdent
```

and disassembly proves the production lexer calls it.

Equivalent to the B1 static binding proof:

```text
_lexIdentifier
   ...
   bl _BootstrapScanIdent
```

Required:

```text
STAGE2_COMPONENT_LINKED = YES
STAGE2_COMPONENT_USED   = YES
```

---

# 17. Strong provenance witness

This is the most important B2 test.

Capture textual evidence of:

```text
stage1 compile command
stage1 component object SHA
stage2 link command
```

and verify the path/hash consumed by the stage2 link
equals the stage1 output.

Binding:

```text
STAGE1_B1_OUTPUT_SHA =
  <observed>

STAGE2_B1_LINK_INPUT_SHA =
  <observed>

STAGE1_B1_OUTPUT_SHA ==
STAGE2_B1_LINK_INPUT_SHA
```

plus:

```text
STAGE2_LINK_INPUT_PATH ==
STAGE1_OUTPUT_PATH
```

The hash proves identity.

The command graph proves provenance.

You need both.

---

# 18. Stage0/stage1/stage2 B1 component comparison

Compile:

```text
tools/bootstrap/bootstrap02-ident.HC
```

with:

```text
stage0
stage1
stage2
```

Capture all three object hashes.

Expected, but do not presuppose:

```text
S0_B1_OBJ == S1_B1_OBJ == S2_B1_OBJ
```

If stage2 object differs, do not automatically fail.
Determine whether the difference is semantically
irrelevant metadata or executable/code difference.

For this ACT, preferred strong pass:

```text
B1_OBJECT_STAGE0_STAGE1_EQ = PASS
B1_OBJECT_STAGE1_STAGE2_EQ = PASS
```

A code-bearing mismatch:

```text
HALT_SELF_HOST_DIVERGENCE
```

---

# 19. Stage2 direct B1 gates

Run all existing B1 direct witnesses against stage2.

At minimum:

```text
component differential        15/15
component cursor               6/6
real production Lexer seam     6/6
EOF cursor equivalence         PASS
EOF pointer safety             PASS
```

Do not create a weaker stage2 test path.

Where possible use the same fixtures/harnesses as B1,
parameterized by compiler identity.

Required:

```text
STAGE2_B1_DIRECT_EQ = PASS
```

---

# 20. Broad stage1 ↔ stage2 corpus differential

B2's principal corpus comparison changes.

B1 compared:

```text
stage0 ↔ stage1
```

B2 must compare:

```text
stage1 ↔ stage2
```

Freeze the current eligible corpus mechanically.

The B1 inventory was:

```text
181 total
175 compile success
6 baseline failures
```

Do not hard-code 181 as eternal truth. Re-enumerate at B2
C3 entry.

For every eligible source:

```text
stage1 rc
stage2 rc
stage1 artifact hash
stage2 artifact hash
diagnostic class if failed
```

Strong success:

```text
ALL stage1-success rows:
  stage2 success
  artifact byte-identical

ALL stage1-failure rows:
  stage2 same failure class

UNACCOUNTED = 0
```

---

# 21. Mandatory binding slices

At least these must be individually called out:

```text
src/holyc-lib/dir.HC
```

for `$` identifiers.

Also:

```text
one normal src/holyc-lib source
one src/tests source
tools/bootstrap/bootstrap02-ident.HC
```

Required:

```text
DOLLAR_IDENTIFIER_STAGE1_STAGE2 = PASS
NORMAL_SOURCE_STAGE1_STAGE2     = PASS
TEST_SOURCE_STAGE1_STAGE2       = PASS
SELF_SOURCE_STAGE1_STAGE2       = PASS
```

---

# 22. Error differential

Reuse the C3 error corpus.

For every error fixture compare:

```text
stage1 exit class
stage2 exit class
path
line
column
diagnostic class
```

Exact message bytes are preferred if stable, but binding
minimum is the same normalized diagnostic contract already
used in B1.

Required:

```text
ERROR_CORPUS_STAGE1_STAGE2_MISMATCH = 0
```

---

# 23. Dynamic delegation witness

Static symbol presence is not enough.

Freshly compile at least one source that exercises
identifier scanning using stage2 and prove the result
matches stage1.

Mandatory:

```text
src/holyc-lib/dir.HC
```

because `_opendir$INODE64` binds the `$` continuation
rule.

Required:

```text
STAGE2_B1_DELEGATION_PROVEN_NONZERO = YES
```

Prefer:

```text
static proof + successful dynamic compile
```

just as B1 did.

---

# 24. Stage2 self-source property

Stage2 must compile the PolyC B1 component:

```bash
build/hcc-bootstrap03 \
  -c tools/bootstrap/bootstrap02-ident.HC \
  ...
```

Then compare:

```text
stage1-produced B1 object
stage2-produced B1 object
```

Strong pass:

```text
STAGE1_STAGE2_B1_OBJECT_EQ = PASS
```

This is the immediate precursor to B3 stability.

---

# 25. What makes this FIRST SELF-HOST rather than B1++

The decisive proof chain must be recorded verbatim:

```text
SOURCE:
  bootstrap02-ident.HC
  language = PolyC

GENERATION 1:
  stage0 -> B1 object -> stage1

GENERATION 2:
  stage1 -> B1 object -> stage2

STAGE2:
  links the object emitted by stage1
  executes it as part of production lexIdentifier

THEREFORE:
  a compiler containing PolyC-authored compiler logic
  has compiled that PolyC compiler logic for the next
  compiler generation.

FIRST_SELF_HOST = PASS
```

This is the ACT's semantic heart.

---

# 26. Reproducibility

Perform the B2 stage chain at least twice from clean
scratch roots:

```text
Build A:
  stage0
  stage1 B1 object
  stage1
  stage2 B1 object
  stage2

Build B:
  same independently
```

Compare:

```text
stage0 A == stage0 B
stage1 B1 obj A == B
stage1 A == B
stage2 B1 obj A == B
stage2 A == B
stage1↔stage2 corpus matrix A == B
```

Do not commit generated binaries.

Record hashes and commands only.

This parallels GCC's bootstrap philosophy: successive
stages are rebuilt and later stages compared to catch
compiler-induced differences.

---

# 27. B0/B1 conservation

B2 must preserve B0 and B1.

Freshly run:

```text
make bootstrap01-test
make bootstrap02-test
make bootstrap02-cursor-test
make bootstrap02-lexer-seam-test
make bootstrap02-stage1
make lsp-test
make gate-fast
```

Expected baselines:

```text
B0                     15/15
B1 component           15/15
B1 cursor               6/6
B1 production Lexer     6/6
LSP                     43/43
gate-fast               PASS
```

Any attributable regression:

```text
HALT_CONSERVATION_GATE_REGRESSION
```

---

# 28. unit/jit classification

Carry current truth exactly.

```text
UNIT_TEST_CURRENT =
  ENVIRONMENTALLY_UNAVAILABLE / RUNNER_FALSE_GREEN

UNIT_TEST_LAST_KNOWN_GOOD =
  90/90

JIT_UNIT_TEST_CURRENT =
  ENVIRONMENTALLY_UNAVAILABLE / RUNNER_FALSE_GREEN

JIT_UNIT_TEST_LAST_KNOWN_GOOD =
  90/90
```

Do not repair the runner in B2.

Do not claim current PASS.

Classification:

```text
CLASS             = TEST_INFRASTRUCTURE
PRODUCTION_IMPACT = NONE
BLOCKS_B2         = NO
```

unless current executable evidence materially changes.

---

# 29. Factory gates

Freshly run:

```text
factory-v2-test
factory-append-only-test
factory-halt-classification-test
factory-closure-status-check
shell-loc-gate
gate-fast
```

Required all executable gates green.

Historical evidence whitespace remains:

```text
GOVERNANCE / BLOCKS_NEXT=NO
```

Do not mutate historical evidence.

---

# 30. No binary evidence

No generated:

```text
hcc
hcc-bootstrap02
hcc-bootstrap03
*.o
*.a
*.dylib
*.so
```

under the B2 evidence tree.

Only textual:

```text
commands
hashes
matrices
logs
summaries
```

---

# 31. C2 evidence packet

Create:

```text
evidence/ACT-POLYC-BOOTSTRAP03/c2/
```

Recommended:

```text
README.md
implementation-delta.txt
stage1-component-build.txt
stage2-link.txt
artifact-provenance.txt
stage2-symbol-binding.txt
stage2-disassembly-binding.txt
b0-b1-conservation.txt
c2-required-result.txt
```

Binding C2 result:

```text
STAGE1_B1_ARTIFACT_CREATED    = YES
STAGE2_CREATED                = YES
STAGE2_LINKS_STAGE1_B1_ARTIFACT  = YES
STAGE2_USES_B1_COMPONENT      = YES
C2_TO_C3_GATE                 = OPEN
```

---

# 32. C3 EVIDENCE mission

C3 is the real B2 proof.

No new semantics unless a RED-discovered defect requires
a separately authorized correction.

C3 establishes simultaneously:

```text
provenance
binding
self-host loop
broad equivalence
error equivalence
self-source equivalence
reproducibility
conservation
```

---

# 33. C3 evidence packet

Create:

```text
evidence/ACT-POLYC-BOOTSTRAP03/c3/
```

Recommended:

```text
README.md
fresh-tree.txt
stage-provenance.txt
artifact-provenance.txt
stage2-symbol-binding.txt
stage2-delegation-witness.txt

component-stage0-stage1-stage2.txt
production-lexer-stage1-stage2.txt

corpus-inventory.txt
corpus-matrix-stage1-stage2.tsv
corpus-summary.txt
dollar-identifier-slice.txt

error-corpus.tsv
error-corpus-summary.txt

stage2-normal-source.txt
stage2-self-source.txt

reproducibility.txt
compiler-conservation.txt
factory-gates.txt
patch-hygiene.txt
scope-audit.txt
c3-required-result.txt
```

---

# 34. C3 acceptance matrix

## Provenance

```text
AC-C3-01 fresh stage0 PASS
AC-C3-02 fresh stage1 PASS
AC-C3-03 stage1 builds B1 source
AC-C3-04 stage1 B1 object provenance recorded
AC-C3-05 fresh stage2 PASS
AC-C3-06 stage2 link consumes exact stage1 B1 object
AC-C3-07 stage2 contains _BootstrapScanIdent
AC-C3-08 stage2 lexIdentifier calls _BootstrapScanIdent
```

## Self-host edge

```text
AC-C3-09  B1 source language = PolyC
AC-C3-10  producer of stage2 B1 artifact = stage1
AC-C3-11  stage2 consumes stage1 output
AC-C3-12  stage2 executes B1 component
AC-C3-13  FIRST_SELF_HOST_EDGE = CLOSED
```

## Direct semantics

```text
AC-C3-14 component differential stage2 = 15/15
AC-C3-15 cursor model stage2 = 6/6
AC-C3-16 production Lexer stage1↔stage2 = 6/6
AC-C3-17 EOF cursor state = PASS
AC-C3-18 EOF pointer safety = PASS
```

## Broad corpus

```text
AC-C3-19 inventory mechanically regenerated
AC-C3-20 every row accounted
AC-C3-21 stage1-success -> stage2-success
AC-C3-22 stage1/stage2 successful artifacts identical
AC-C3-23 baseline failures equivalent
AC-C3-24 divergence count = 0
AC-C3-25 unaccounted count = 0
```

## Binding slices

```text
AC-C3-26 $-identifier source PASS
AC-C3-27 ordinary library source PASS
AC-C3-28 tests source PASS
AC-C3-29 B1 self-source PASS
```

## Error behavior

```text
AC-C3-30 error corpus divergence = 0
```

## Stage2 self-source

```text
AC-C3-31 stage2 compiles B1 source
AC-C3-32 stage1/stage2 B1 object equivalence PASS
```

## Reproducibility

```text
AC-C3-33 Build A complete
AC-C3-34 Build B complete
AC-C3-35 stage1 artifacts reproducible
AC-C3-36 stage2 artifacts reproducible
AC-C3-37 corpus matrices reproducible
```

## Conservation

```text
AC-C3-38 B0 15/15
AC-C3-39 B1 component 15/15
AC-C3-40 B1 cursor 6/6
AC-C3-41 B1 Lexer 6/6
AC-C3-42 LSP baseline PASS
AC-C3-43 gate-fast PASS
AC-C3-44 Factory gates PASS
AC-C3-45 shell-loc PASS
```

## Scope

```text
AC-C3-46 B1 semantics unchanged
AC-C3-47 no parser/AST/IR/backend widening
AC-C3-48 stage3 absent
AC-C3-49 prior evidence mutation ZERO
AC-C3-50 committed binary evidence ZERO
```

## Truth boundary

```text
AC-C3-51 FIRST_SELF_HOST = PASS
AC-C3-52 FULL_SELF_HOST = NO
AC-C3-53 BOOTSTRAP_STABILITY = NOT_YET
AC-C3-54 B3 remains locked until C4
```

---

# 35. Binding C3 result

`c3-required-result.txt` should end with something
equivalent to:

```text
ACT_PHASE = EVIDENCE

B1_PARTIAL_SELF_HOST = PASS

STAGE1_COMPILER = PASS
STAGE2_COMPILER = PASS

B1_COMPONENT_LANGUAGE = POLYC

STAGE1_COMPILES_B1_COMPONENT = PASS
STAGE1_B1_ARTIFACT_PROVENANCE = PASS

STAGE2_LINKS_STAGE1_B1_ARTIFACT = PASS
STAGE2_USES_STAGE1_B1_ARTIFACT  = PASS

STAGE2_DIRECT_B1_EQ = PASS

STAGE1_STAGE2_CORPUS_EQ = PASS
STAGE1_STAGE2_ERROR_EQ  = PASS

STAGE2_COMPILES_B1_SOURCE = PASS
STAGE1_STAGE2_B1_OBJECT_EQ = PASS

REPRODUCIBILITY = PASS

B0_CONSERVATION = PASS
B1_CONSERVATION = PASS

FIRST_SELF_HOST = PASS

FULL_SELF_HOST = NO
BOOTSTRAP_STABILITY = NOT_YET
STAGE3_CREATED = NO

C3_TO_C4_CLOSE_GATE = OPEN
```

---

# 36. B2 HALT taxonomy

### `HALT_STAGE1_SELF_COMPILE_REGRESSION`

Stage1 no longer compiles B1 source.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_STAGE2_PROVENANCE_UNPROVEN`

Stage2 exists but you cannot prove its B1 object came
from stage1.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

This is critical. Do not substitute hash coincidence for
provenance.

### `HALT_STAGE2_BINDING_LOST`

Stage2 lacks or does not call the B1 component.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_SELF_HOST_DIVERGENCE`

Stage1 and stage2 materially disagree.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_B0_REGRESSION`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_B1_REGRESSION`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_REPRODUCIBILITY_REGRESSION`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_SCOPE_EXPANSION_REQUIRED`

B2 requires parser/backend/runtime/compiler-semantic
work not authorized here.

```text
HALT_CLASS  = AUTHORIZATION
BLOCKS_NEXT = YES
```

### Explicitly non-blocking

```text
B1 omitted closure prose
current unit/jit environment limitation
runner false-green residue
historical evidence whitespace
token-dump seam absence
unchanged GEP01/push residue
```

remain:

```text
HALT_CLASS  = GOVERNANCE
BLOCKS_NEXT = NO
```

---

# 37. C4 CLOSE mission

C4 does no new implementation.

Freshly prove:

```text
stage1 builds B1
stage2 consumes that exact artifact
stage2 calls B1
stage1↔stage2 direct equivalence
stage1↔stage2 corpus equivalence
stage2 compiles B1
reproducibility
B0/B1 conservation
Factory conservation
```

If all pass:

```text
ACT-Verdict: PASS
```

---

# 38. B2 closure semantics

Canonical closure block:

```text
ACT                        = ACT-POLYC-BOOTSTRAP03
ACT_PHASE                  = CLOSE
ACT_VERDICT                = PASS

B0_COMPILER_SHAPED         = PASS
B1_PARTIAL_SELF_HOST       = PASS
B2_FIRST_SELF_HOST         = PASS

B1_COMPONENT_LANGUAGE      = POLYC

STAGE1_COMPILER            = PASS
STAGE1_COMPILES_B1_SOURCE  = PASS

STAGE1_B1_ARTIFACT         = PASS
STAGE1_B1_PROVENANCE       = PASS

STAGE2_COMPILER            = PASS
STAGE2_LINKS_STAGE1_B1_ARTIFACT = YES
STAGE2_USES_B1_COMPONENT     = YES

STAGE1_STAGE2_DIRECT_EQ    = PASS
STAGE1_STAGE2_CORPUS_EQ    = PASS
STAGE1_STAGE2_ERROR_EQ     = PASS

STAGE2_COMPILES_B1_SOURCE  = PASS
STAGE1_STAGE2_B1_OBJECT_EQ = PASS

REPRODUCIBILITY            = PASS

FIRST_SELF_HOST            = PASS

FULL_SELF_HOST             = NO
HOST_C_DEPENDENCY          = PRESENT
BOOTSTRAP_STABILITY        = NOT_YET

STAGE3_CREATED             = NO

B0_CONSERVATION            = PASS
B1_CONSERVATION            = PASS

P0_BLOCKERS                = NONE
B3_UNLOCKED                = YES
```

---

# 39. Why `FULL_SELF_HOST = NO`

Even after successful B2, the compiler itself is still
predominantly host-C.

Only a bounded compiler subsystem has a closed PolyC
self-host generation chain.

Therefore:

```text
FIRST_SELF_HOST = YES
```

means:

> At least one production compiler component written in
> PolyC has been compiled by a compiler containing that
> component and the resulting artifact has been consumed
> in constructing the next compiler generation.

It does **not** mean:

> The PolyC compiler source is wholly PolyC and no foreign
> compiler implementation remains.

That stronger milestone belongs later.

---

# 40. What B3 will mean

B3 should be **bootstrap stability**, analogous in spirit
to GCC's later-stage comparison.

So after B2 closes, B3 can naturally ask:

```text
stage2 -> builds B1 artifact -> stage3
stage2 == stage3 over the binding comparison domain
```

Likely B3 core:

```text
STAGE2_STAGE3_COMPILER_STABILITY
STAGE2_STAGE3_COMPONENT_STABILITY
STAGE2_STAGE3_CORPUS_STABILITY
REPEATED_BUILD_DETERMINISM
```

But **B3 is forbidden in this ACT**.

---

# 41. C4 evidence packet

Create:

```text
evidence/ACT-POLYC-BOOTSTRAP03/c4/
```

Recommended:

```text
README.md
acceptance-matrix.txt
closure-summary.txt
final-provenance.txt
final-stage-binding.txt
final-self-host-chain.txt
final-direct-tests.txt
final-corpus.txt
final-self-source.txt
final-reproducibility.txt
final-conservation.txt
factory-gates.txt
patch-hygiene.txt
scope-audit.txt
residue.txt
roadmap-transition.txt
```

Plus:

```text
evidence/ACT-POLYC-BOOTSTRAP03/HANDOFF.md
```

Text only.

---

# 42. ROADMAP transition

In the **same authoritative C4 CLOSE commit**:

```text
B0 — COMPILER-SHAPED      GREEN
B1 — PARTIAL SELF-HOST    GREEN
B2 — FIRST SELF-HOST      GREEN
B3 — BOOTSTRAP STABILITY  UNLOCKED / NEXT
```

Recommended outcome block:

```text
B2_FIRST_SELF_HOST                 = GREEN
B1_COMPONENT_LANGUAGE              = POLYC

STAGE1_COMPILES_B1_COMPONENT       = YES
STAGE2_CONSUMES_STAGE1_ARTIFACT    = YES
STAGE2_EXECUTES_B1_COMPONENT       = YES

STAGE1_STAGE2_DIRECT_EQ            = PASS
STAGE1_STAGE2_BROAD_CORPUS_EQ      = PASS
STAGE2_COMPILES_B1_COMPONENT       = PASS
REPRODUCIBILITY                    = PASS

FULL_SELF_HOST                     = NO
BOOTSTRAP_STABILITY                = NOT_YET

NEXT                               = B3
```

Do not create a second CLOSE for the ROADMAP.

---

# 43. Commit topology

Use strict truthful steps:

```text
C1 RED
C2 IMPL
C3 EVIDENCE
C4 CLOSE
```

Multiple C2 or C3 commits are fine when each is a
truthful proof step.

Exactly one:

```text
ACT-Phase: CLOSE
```

for `ACT-POLYC-BOOTSTRAP03`.

Final PASS trailer:

```text
ACT: ACT-POLYC-BOOTSTRAP03
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

No `HALT_CLASS` / `BLOCKS_NEXT` on PASS.

No post-CLOSE commit carrying the same ACT id.

---

# 44. Hard stop

After B2 CLOSE:

```text
STOP.
```

Do not:

```text
build stage3
open B3
migrate another subsystem
repair unit/jit
repair GEP01
clean historical evidence
push unless independently authorized
```

---

# 45. Required final report

The successful execution report should reduce to:

```text
VERDICT: PASS

ACT-POLYC-BOOTSTRAP03 is CLOSED.

B0:
  GREEN

B1:
  GREEN

B2 FIRST SELF-HOST:
  PASS

Self-host chain:
  PolyC B1 source
    -> compiled by stage1
    -> exact stage1 object consumed by stage2
    -> stage2 links and executes B1 component

Artifact provenance:
  PASS

Stage2 component binding:
  PASS

Direct equivalence:
  PASS

Stage1/stage2 broad corpus:
  PASS
  divergences = 0

Stage2 compiles B1 source:
  PASS

Stage1/stage2 B1 object:
  equivalent

Reproducibility:
  PASS

B0/B1 conservation:
  PASS

FIRST_SELF_HOST:
  YES

FULL_SELF_HOST:
  NO

BOOTSTRAP_STABILITY:
  NOT_YET

ROADMAP:
  B0 GREEN
  B1 GREEN
  B2 GREEN
  B3 UNLOCKED / NEXT

P0:
  NONE
```

## Board intent

This is the smallest B2 I would accept as **"FIRST
SELF-HOST"** rather than merely "B1 with another test."

B1 showed:

**PolyC code can live inside the compiler.**

B2 must show:

**the compiler containing that PolyC code can compile
that same compiler code for its successor, and the
successor actually consumes it.**

That closes the loop for the first time.
