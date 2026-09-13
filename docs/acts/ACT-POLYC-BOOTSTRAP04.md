# ACT-POLYC-BOOTSTRAP04

**Title:** B3 bootstrap stability — stage2-produced PolyC compiler component
consumed by stage3, with stage2↔stage3 equivalence over the entire
currently self-hosted behavioural domain.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-BOOTSTRAP03` CLOSED PASS
(stage1-produced B1 component consumed by stage2;
15/15 component differential, 6/6 cursor, 6/6 production
Lexer seam, 175/175 broad corpus stage1↔stage2, EOF cursor
state equivalence, EOF pointer safety, reproducibility PASS,
FIRST_SELF_HOST = YES)

**Class:** BOOTSTRAP / STABILITY / SUCCESSIVE-STAGE-COMPARISON

**Production compiler semantic changes:** **NONE**
(only build-graph addition for stage3; B1 component source
frozen; B1 production lexer frozen; src/lexer.c dispatch
frozen; parser/AST/IR/backend frozen)

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**MEMORY01 widening:** **FORBIDDEN**

**B0 lexer changes:** **FORBIDDEN**

**B1 component source changes:** **FORBIDDEN**
(`tools/bootstrap/bootstrap02-ident.HC` is frozen by §5
of the predecessor ACT and §9 of this ACT)

**B1 production lexer changes:** **FORBIDDEN**
(`src/lexer.c`, `src/lexer_bridge.h` frozen)

**VERDICT (target):** `PASS`

---

# 0. Mission

Establish **bootstrap stability over PolyC's currently
self-hosted compiler domain**.

The required generational chain is:

```text
stage0
  -> compiles PolyC B1 component
  -> stage1

stage1
  -> compiles same PolyC B1 component
  -> stage2

stage2
  -> compiles same PolyC B1 component
  -> stage3
```

B3 succeeds only if:

```text
1. stage2 actually produces the B1 object consumed by stage3;
2. stage3 actually links and executes that object;
3. stage2 and stage3 agree over the complete B3 comparison domain;
4. two independent clean B3 constructions reproduce the same result;
5. B0/B1/B2 conservation remains GREEN.
```

Binding result:

```text
BOOTSTRAP_STABILITY = PASS
```

with the mandatory scope qualifier:

```text
BOOTSTRAP_STABILITY_DOMAIN =
  CURRENT_SELF_HOSTED_COMPILER_COMPONENT
```

This ACT explicitly refuses to interpret `BOOTSTRAP_STABILITY = PASS`
as whole-compiler self-hosting.

---

# 1. Truth boundary

A successful B3 means:

> The currently self-hosted PolyC compiler component reaches
> a stable fixed point across successive self-hosted generations:
> stage2 compiles the component used by stage3, and stage2 and
> stage3 remain observationally equivalent over the complete
> frozen comparison domain.

It does **not** mean:

```text
FULL_SELF_HOST              = YES
COMPILER_IMPLEMENTED_POLYC  = YES
HOST_C_DEPENDENCY           = ZERO
WHOLE_COMPILER_BOOTSTRAP    = PASS
TRUSTING_TRUST_RESOLVED     = YES
REPRODUCIBLE_BUILD_PROJECT  = COMPLETE
```

Required closure boundary:

```text
B0_COMPILER_SHAPED        = PASS
B1_PARTIAL_SELF_HOST      = PASS
B2_FIRST_SELF_HOST        = PASS

B3_BOOTSTRAP_STABILITY    = PASS
B3_STABILITY_DOMAIN       = CURRENT_SELF_HOSTED_COMPILER_COMPONENT

FIRST_SELF_HOST           = YES
FULL_SELF_HOST            = NO
HOST_C_DEPENDENCY         = PRESENT
```

---

# 2. Why B3 is not just "build stage3"

Merely producing:

```text
build/hcc-bootstrap04
```

does **not** satisfy B3.

Likewise, merely showing:

```text
stage2 can compile bootstrap02-ident.HC
```

does not satisfy B3; B2 already established that capability.

The decisive B3 transition is:

```text
stage2-produced component
        |
        v
      stage3
        |
        +--> component semantics stable
        +--> production Lexer seam stable
        +--> broad corpus stable
        +--> diagnostics stable
        +--> self-source stable
        +--> repeated bootstrap stable
```

So the RED is not "stage3 absent" by itself.

The RED is:

```text
NO SUCCESSIVE SELF-HOSTED STAGE COMPARISON EXISTS
```

---

# 3. Predecessor freeze

C1 must mechanically re-establish B2 rather than trusting
closure prose.

Required entry predicates:

```text
ACT-POLYC-BOOTSTRAP03_CLOSE_CARDINALITY = 1

B0_COMPILER_SHAPED              = PASS
B1_PARTIAL_SELF_HOST            = PASS
B2_FIRST_SELF_HOST              = PASS

STAGE0_PRESENT                  = YES
STAGE1_PRESENT                  = YES
STAGE2_PRESENT                  = YES

STAGE1_COMPILES_B1_COMPONENT    = PASS
STAGE2_LINKS_STAGE1_ARTIFACT    = YES
STAGE2_USES_B1_COMPONENT        = YES

STAGE1_STAGE2_DIRECT_EQ         = PASS
STAGE1_STAGE2_CORPUS_EQ         = PASS
STAGE1_STAGE2_ERROR_EQ          = PASS
STAGE2_COMPILES_B1_SOURCE       = PASS

B2_REPRODUCIBILITY              = PASS

FIRST_SELF_HOST                 = YES
FULL_SELF_HOST                  = NO

STAGE3_CREATED                  = NO
BOOTSTRAP_STABILITY             = NOT_YET
B3_UNLOCKED                     = YES
```

Any executable contradiction:

```text
HALT_B2_PREDECESSOR_NOT_GREEN
```

with:

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

---

# 4. Inherited non-blocking B2 residue

Carry exactly these two B2 review findings without reopening
B2:

```text
B2_HANDOFF_C2_POINTER_TYPO =
  evidence/ACT-POLYC-BOOTSTRAP02/c2/
  SHOULD_HAVE_BEEN
  evidence/ACT-POLYC-BOOTSTRAP03/c2/

CLASS             = GOVERNANCE / DOCUMENTATION
PRODUCTION_IMPACT = NONE
BLOCKS_B3         = NO
```

and:

```text
B2_PROVENANCE_WORDING =
  "same file by inode" was stronger than the captured evidence

CORRECT_INTERPRETATION =
  producer command
  + unique output path
  + consumer build-graph path
  + matching content hash
  establish causal provenance

CLASS             = GOVERNANCE / EVIDENCE_WORDING
PRODUCTION_IMPACT = NONE
BLOCKS_B3         = NO
```

Do **not** create `BOOTSTRAP03-CORRECTION01` for either item.

The golden rule applies: prose-only deficiencies do not block
engineering when executable truth is intact.

---

# 5. B3 compiler identities

Freeze four generation names:

```text
STAGE0 =
  ordinary ./hcc

STAGE1 =
  build/hcc-bootstrap02

STAGE2 =
  build/hcc-bootstrap03

STAGE3 =
  build/hcc-bootstrap04
```

Artifact lineage:

```text
S0_B1_OBJ =
  produced by stage0
  linked into stage1

S1_B1_OBJ =
  produced by stage1
  linked into stage2

S2_B1_OBJ =
  produced by stage2
  linked into stage3
```

Canonical paths encode lineage explicitly:

```text
build/bootstrap02-ident.o              # S0
build/bootstrap03-ident.stage1.o       # S1
build/bootstrap04-ident.stage2.o       # S2
```

Do not reuse one generic mutable object path for multiple
generations.

---

# 6. B3 defining invariant

The central structural predicate is:

```text
STAGE3_B1_ARTIFACT_PROVENANCE = STAGE2
```

It requires all of:

```text
STAGE2_PRODUCER_BINARY =
  build/hcc-bootstrap03

STAGE2_PRODUCER_INPUT =
  tools/bootstrap/bootstrap02-ident.HC

STAGE2_PRODUCER_OUTPUT =
  build/bootstrap04-ident.stage2.o

STAGE3_LINK_INPUT =
  build/bootstrap04-ident.stage2.o

STAGE3_LINKS_EXACT_STAGE2_OUTPUT =
  YES
```

And stage3 must demonstrably use it:

```text
STAGE3_CONTAINS_B1_SYMBOL = YES
STAGE3_LEXER_CALLS_B1     = YES
```

Hash equality alone is **not** provenance.

Required causal evidence:

```text
producer binary identity
producer command
output path
output hash

consumer configure/link command
consumer input path
consumer input hash

stage3 symbol table
stage3 call-site disassembly
```

---

# 7. Stability invariant

The central semantic predicate is:

```text
STAGE2_STAGE3_STABILITY = PASS
```

defined as:

```text
STAGE2_STAGE3_STABILITY :=
    STAGE3_PROVENANCE_PASS
 && COMPONENT_EQ_PASS
 && CURSOR_EQ_PASS
 && PRODUCTION_LEXER_EQ_PASS
 && SUCCESS_CORPUS_EQ_PASS
 && FAILURE_CORPUS_EQ_PASS
 && SELF_SOURCE_EQ_PASS
 && ERROR_CORPUS_EQ_PASS
 && REPRODUCIBILITY_PASS
```

No single hash, test, or fixture may stand in for the aggregate.

---

# 8. Authorized implementation scope

Expected production/build changes:

```text
Makefile
src/CMakeLists.txt
```

Authorized new test/evidence helpers:

```text
tools/quality/bootstrap04-*
```

Only where needed to establish B3 mechanically.

Authorized evidence:

```text
docs/acts/ACT-POLYC-BOOTSTRAP04.md
evidence/ACT-POLYC-BOOTSTRAP04/**
docs/ROADMAP.md   (C4 only)
```

Expected B3 implementation is a **build-graph extension**,
not a compiler semantic change.

---

# 9. Frozen semantic files

Unless C1 discovers a genuine blocker requiring a separate
correction/authorization ACT, these are frozen:

```text
tools/bootstrap/bootstrap02-ident.HC
src/lexer.c
src/lexer_bridge.h

src/aarch64.c
src/x86_64.c

parser / AST / IR / LLVM implementation
B0 subject
B1 semantic tests
```

Binding:

```text
B3_COMPILER_SEMANTIC_DELTA = ZERO
```

---

# 10. Forbidden scope

Do not:

```text
migrate another compiler function to PolyC
change identifier grammar
change B1 semantics
change parser behavior
change AST behavior
change neutral IR
change native backend semantics
change LLVM backend semantics
widen MEMORY01
repair GEP01
repair unit/jit runner
repair historical evidence
repair old closure prose
build stage4
begin full self-host conversion
push unless separately authorized
```

Most importantly:

```text
NO "B3 needs more PolyC code" scope creep.
```

B3 tests **stability of the self-host chain already established**.

---

# 11. C1 RED mission

C1 must prove the current B2 state and the absence of B3
closure.

Expected RED:

```text
STAGE2_EXISTS = YES

STAGE2_CAN_COMPILE_B1_SOURCE = YES

STAGE2_PRODUCED_B1_OBJECT =
  possible transient experiment only

CANONICAL_STAGE3_EXISTS = NO

STAGE3_LINKS_STAGE2_OBJECT = NO

STAGE3_USES_STAGE2_OBJECT = NO

STAGE2_STAGE3_COMPARISON_EXISTS = NO

BOOTSTRAP_STABILITY = NOT_YET
```

Principal RED:

> The first self-host edge exists, but there is no
> next-generation compiler consuming stage2's output and
> therefore no later-stage stability comparison.

Binding:

```text
BOOTSTRAP_STABILITY_PROVEN = NO
```

---

# 12. C1 transient provenance experiment

Before production mutation, use stage2 to compile the B1 source
into a temporary path:

```bash
build/hcc-bootstrap03 \
  --install-dir=<test-prefix> \
  -c tools/bootstrap/bootstrap02-ident.HC \
  -o <scratch>/bootstrap04-ident.stage2.o
```

Capture:

```text
producer = stage2
input    = bootstrap02-ident.HC
output   = transient stage2 object
symbol   = _BootstrapScanIdent
hash     = observed
rc       = 0
```

This proves stage2 capability.

It does **not** prove B3 because no stage3 yet consumes the
artifact.

---

# 13. C1 build seam map

Map exactly:

```text
how bootstrap03-component-build creates S1_B1_OBJ
how bootstrap03-stage2 links S1_B1_OBJ
how HCC_ENABLE_BOOTSTRAP03_STAGE2 is expressed
how BOOTSTRAP03_IDENT_OBJECT is passed
```

Then identify the smallest B3 extension:

```text
bootstrap04-component-build:
  stage2 -> S2_B1_OBJ

bootstrap04-stage3:
  stage3 links S2_B1_OBJ
```

No implementation during C1.

---

# 14. C1 evidence packet

Create:

```text
evidence/ACT-POLYC-BOOTSTRAP04/c1/
```

Required:

```text
README.md
predecessor-freeze.txt
b2-governance-residue.txt
stage-identity.txt
stage2-self-compile.txt
stage3-absence.txt
build-seam-map.txt
principal-red.txt
c1-required-result.txt
```

Binding end block:

```text
B2_PREDECESSOR_GREEN       = YES
FIRST_SELF_HOST            = PASS

STAGE2_SELF_SOURCE_COMPILE = PASS
STAGE3_EXISTS              = NO

BOOTSTRAP_STABILITY        = NOT_YET
C1_TO_C2_GATE              = OPEN
```

---

# 15. C1 acceptance criteria

```text
AC01 branch = main
AC02 worktree clean
AC03 git replace empty

AC04 B2 authoritative CLOSE count = 1
AC05 B2_FIRST_SELF_HOST = PASS
AC06 B2 broad corpus = PASS
AC07 B2 error corpus = PASS
AC08 B2 reproducibility = PASS

AC09 stage0 captured
AC10 stage1 captured
AC11 stage2 captured

AC12 stage2 contains _BootstrapScanIdent
AC13 stage2 calls _BootstrapScanIdent

AC14 stage2 freshly compiles B1 source
AC15 stage2 output exports _BootstrapScanIdent

AC16 canonical stage3 absent
AC17 no stage3 link consumes stage2 output
AC18 no stage2↔stage3 comparison exists

AC19 build seam mapped
AC20 B2 governance residue recorded as non-blocking

AC21 B0 conservation PASS
AC22 B1 conservation PASS
AC23 B2 conservation PASS

AC24 no production mutation in C1

AC25 BOOTSTRAP_STABILITY = NOT_YET
AC26 C1_TO_C2_GATE = OPEN
```

---

# 16. C1 HALTs

### `HALT_B2_PREDECESSOR_NOT_GREEN`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_STAGE2_CANNOT_COMPILE_B1_SOURCE`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_STAGE3_ALREADY_CANONICAL`

Canonical B3 already exists, falsifying this ACT's RED premise.

```text
HALT_CLASS  = AUTHORIZATION
BLOCKS_NEXT = YES
```

### `HALT_SCOPE_EXPANSION_REQUIRED`

The stage3 chain requires semantic compiler work rather than
bounded build-graph extension.

```text
HALT_CLASS  = AUTHORIZATION
BLOCKS_NEXT = YES
```

---

# 17. C2 IMPL mission

Add exactly the stage2→stage3 build edge.

Expected:

```text
make bootstrap04-component-build

  build/hcc-bootstrap03
      |
      | compiles PolyC B1 source
      v
  build/bootstrap04-ident.stage2.o


make bootstrap04-stage3

  compiler source/build graph
      +
  build/bootstrap04-ident.stage2.o
      |
      v
  build/hcc-bootstrap04
```

Binding:

```text
STAGE3_B1_PRODUCER = STAGE2
```

---

# 18. Canonical B3 target names

Preferred:

```text
bootstrap04-component-build
bootstrap04-stage3
bootstrap04-test
bootstrap04-cursor-test
bootstrap04-lexer-seam-test
```

If direct existing runners can be parameterized without
weakening them, reuse them rather than cloning logic.

But the generation-producing target must remain explicit:

```text
bootstrap04-component-build
```

must invoke **stage2**, not stage1.

---

# 19. Stage3 CMake identity

Add a distinct stage3 option/target, e.g.:

```text
HCC_ENABLE_BOOTSTRAP04_STAGE3
BOOTSTRAP04_IDENT_OBJECT
hcc-bootstrap04
```

Stage3 must also retain the existing production delegation:

```text
HCC_BOOTSTRAP02_STAGE1
```

or whatever current source-level compile definition activates
the B1 lexer seam.

Do not modify `src/lexer.c` merely to invent a new macro if the
existing semantic selector correctly activates the same path.

The generation distinction belongs in the **build graph**, not
duplicated semantic branches.

---

# 20. Artifact path separation

Require:

```text
S0 = build/bootstrap02-ident.o
S1 = build/bootstrap03-ident.stage1.o
S2 = build/bootstrap04-ident.stage2.o
```

Then:

```text
stage1 consumes S0
stage2 consumes S1
stage3 consumes S2
```

Explicitly reject:

```text
stage3 consumes S1
stage3 consumes S0
stage3 rebuilds S2 with stage1
stage3 accepts whichever object happens to exist
```

---

# 21. Strong provenance witness

C2 and C3 must record:

```text
STAGE2_B1_OUTPUT_PATH
STAGE2_B1_OUTPUT_SHA

STAGE3_B1_LINK_INPUT_PATH
STAGE3_B1_LINK_INPUT_SHA
```

Required:

```text
PATH_EQ = YES
HASH_EQ = YES
```

But state the interpretation carefully:

```text
PROVENANCE_PRIMARY =
  PRODUCER_COMMAND_PLUS_DISTINCT_BUILD_PATH_PLUS_CONSUMER_GRAPH

CONTENT_IDENTITY_SECONDARY =
  SHA256_MATCH
```

Do not claim inode identity unless inode/device values were
actually captured.

---

# 22. Stage3 static binding

Required:

```bash
nm build/hcc-bootstrap04
```

contains:

```text
_BootstrapScanIdent
```

and disassembly contains actual lexer delegation:

```text
bl _BootstrapScanIdent
```

Required:

```text
STAGE3_COMPONENT_LINKED = YES
STAGE3_COMPONENT_USED   = YES
```

---

# 23. Direct stage2↔stage3 component comparison

Compile the B1 source with:

```text
stage2
stage3
```

Capture output objects separately.

Strong result:

```text
STAGE2_B1_OBJECT == STAGE3_B1_OBJECT
```

byte-for-byte.

If unequal:

1. do not normalize blindly;
2. classify the difference;
3. compare code/data/relocation-bearing content
   mechanically;
4. HALT on material code-bearing divergence.

Material mismatch:

```text
HALT_BOOTSTRAP_COMPONENT_DIVERGENCE
```

---

# 24. Direct semantic gates

Run the complete direct comparison domain against stage3:

```text
component differential       15/15
component cursor              6/6
production Lexer seam         6/6
EOF cursor state              PASS
EOF pointer safety            PASS
$ identifier                  PASS
```

B3 requires the existing semantic oracle, not a weaker
stage3-specific test.

Binding:

```text
STAGE3_DIRECT_EQ = PASS
```

---

# 25. Stage2↔stage3 production Lexer seam

This is load-bearing.

Use the same six real production Lexer-seam fixtures that
discovered the prior EOF defect.

Compare every measured field.

Required:

```text
STAGE2_STAGE3_LEXER_SEAM =
  PASS_6_OF_6_NO_RESIDUE
```

Specifically preserve:

```text
l->ptr
l->start
EOF state
next byte
cursor offsets
```

where present in the existing witness.

No "outputs looked equivalent" prose substitute.

---

# 26. Broad corpus

Regenerate the corpus from the current tree.

Do not hard-code:

```text
181
175
6
```

as eternal constants.

B2 happened to report those numbers.

For each enumerated source record:

```text
path

stage2_rc
stage3_rc

stage2_class
stage3_class

stage2_artifact_hash
stage3_artifact_hash

byte_equal

verdict
reason
```

Required:

```text
stage2-success -> stage3-success
successful artifact mismatch = 0

stage2-failure -> stage3-equivalent-failure
failure divergence = 0

unaccounted = 0
```

---

# 27. Mandatory broad-corpus slices

Separately identify:

```text
src/holyc-lib/dir.HC
```

for `$` grammar.

Also:

```text
one ordinary src/holyc-lib file
one src/tests file
tools/bootstrap/bootstrap02-ident.HC
```

Required:

```text
DOLLAR_IDENTIFIER_STAGE2_STAGE3 = PASS
NORMAL_SOURCE_STAGE2_STAGE3     = PASS
TEST_SOURCE_STAGE2_STAGE3       = PASS
SELF_SOURCE_STAGE2_STAGE3       = PASS
```

---

# 28. Error corpus

Reuse the frozen four-case B2 error corpus.

Compare:

```text
rc
failure class
path
line
column
normalized diagnostic class
```

Required:

```text
ERROR_CORPUS_STAGE2_STAGE3_MISMATCH = 0
```

Do not discard error-path stability; bootstrap bugs often
reveal themselves through path-dependent behavior even when
happy paths agree.

---

# 29. Success-corpus object comparison is primary

For every source where stage2 succeeds:

```text
stage2 object
stage3 object
```

must be byte-identical unless this ACT encounters and
explicitly classifies nondeterministic metadata.

Default:

```text
BYTE_EQUAL_REQUIRED = YES
```

Do not weaken to semantic/runtime-only equivalence preemptively.

---

# 30. Stage3 self-source

Stage3 must compile:

```text
tools/bootstrap/bootstrap02-ident.HC
```

Then compare:

```text
S2-produced object
S3-produced object
```

Required strong result:

```text
STAGE2_STAGE3_B1_OBJECT_EQ = PASS
```

This is the compact fixed-point witness:

```text
stage2(B1 source) == stage3(B1 source)
```

---

# 31. What constitutes bootstrap stability

The canonical proof chain must read:

```text
SOURCE:
  bootstrap02-ident.HC
  language = PolyC

GENERATION 1:
  stage0 -> component -> stage1

GENERATION 2:
  stage1 -> component -> stage2

GENERATION 3:
  stage2 -> component -> stage3

STAGE3:
  consumes exact stage2-produced component
  uses component in production lexIdentifier

STABILITY:
  stage2 and stage3 agree on:
    component output
    cursor semantics
    production lexer semantics
    broad successful corpus
    baseline failure corpus
    explicit error corpus
    self-source output

REPEATED BOOTSTRAP:
  independent Build A and Build B agree

THEREFORE:
  BOOTSTRAP_STABILITY = PASS
  within CURRENT_SELF_HOSTED_COMPILER_COMPONENT domain
```

---

# 32. Reproducibility experiment

Perform at least two independent clean constructions.

For example:

```text
Build A:
  clean bootstrap scratch A
  stage0
  stage1
  S1
  stage2
  S2
  stage3
  comparison matrix A

Build B:
  clean bootstrap scratch B
  stage0
  stage1
  S1
  stage2
  S2
  stage3
  comparison matrix B
```

Required comparisons:

```text
S1_A == S1_B
S2_A == S2_B

stage1_A behavior == stage1_B
stage2_A behavior == stage2_B
stage3_A behavior == stage3_B

stage2↔stage3 corpus matrix A ==
stage2↔stage3 corpus matrix B

error matrix A == error matrix B
```

Prefer compiler binary byte equality if it naturally holds,
but do not make path-sensitive executable bytes the sole
stability criterion.

The primary stability product is compiler **output behavior
over the frozen domain**.

---

# 33. Why stage2/stage3 executable byte identity is optional

Unlike the B1 object comparison, the compiler executables
may embed:

```text
paths
link ordering artifacts
load-command details
timestamps if any remain
```

Therefore:

```text
STAGE2_BINARY_SHA == STAGE3_BINARY_SHA
```

is useful evidence if true, but not binding by itself.

Required instead:

```text
STAGE2_STAGE3_OUTPUT_FIXED_POINT = PASS
```

over the B3 domain.

If the binaries are byte-identical, record it as a stronger
result.

If they are not, classify why.

Never silently normalize until equality appears.

---

# 34. B0/B1/B2 conservation

Freshly run all presently authoritative bootstrap gates:

```text
make bootstrap01-test

make bootstrap02-test
make bootstrap02-cursor-test
make bootstrap02-lexer-seam-test
make bootstrap02-stage1

make bootstrap03-component-build
make bootstrap03-stage2
make bootstrap03-test
make bootstrap03-lexer-seam-test

make lsp-test
make gate-fast
```

Expected predecessor baselines:

```text
B0                           15/15

B1 component                 15/15
B1 cursor                     6/6
B1 Lexer                      6/6

B2 component                 15/15
B2 cursor                     6/6
B2 Lexer                      6/6

LSP                           43/43
gate-fast                     PASS
```

Any attributable regression:

```text
HALT_CONSERVATION_GATE_REGRESSION
```

---

# 35. Unit/JIT classification

Carry current truth, do not invent a stronger claim.

If the inherited runner situation is unchanged:

```text
UNIT_TEST_CURRENT =
  ENVIRONMENTALLY_UNAVAILABLE / RUNNER_FALSE_GREEN

UNIT_TEST_LAST_KNOWN_GOOD =
  90/90

JIT_UNIT_TEST_CURRENT =
  ENVIRONMENTALLY_UNAVAILABLE / RUNNER_FALSE_GREEN

JIT_UNIT_TEST_LAST_KNOWN_GOOD =
  90/90

ATTRIBUTABLE_B3_REGRESSION =
  NONE_OBSERVED
```

Classification:

```text
CLASS             = TEST_INFRASTRUCTURE
PRODUCTION_IMPACT = NONE
BLOCKS_B3         = NO
```

Do not repair it here.

If current mechanical reality differs, record current reality
rather than copying stale residue prose.

---

# 36. Factory gates

Fresh execution:

```text
factory-v2-test
factory-append-only-test
factory-halt-classification-test
factory-closure-status-check
shell-loc-gate
gate-fast
```

All executable authoritative gates must pass.

Patch hygiene for the new ACT range:

```text
git diff --check <ENTRY>..HEAD
```

must be clean.

Historical evidence whitespace remains non-blocking
governance residue.

---

# 37. No binary evidence

Under:

```text
evidence/ACT-POLYC-BOOTSTRAP04/
```

forbid committed:

```text
hcc
hcc-bootstrap02
hcc-bootstrap03
hcc-bootstrap04
*.o
*.a
*.so
*.dylib
other generated executables
```

Evidence stores:

```text
commands
paths
hashes
sizes
symbol excerpts
disassembly excerpts
matrices
logs
summaries
```

Generated binaries live only in `build/` or scratch.

---

# 38. C2 evidence packet

Create:

```text
evidence/ACT-POLYC-BOOTSTRAP04/c2/
```

Required/recommended:

```text
README.md

implementation-delta.txt

stage2-component-build.txt
stage3-link.txt

artifact-provenance.txt

stage3-symbol-binding.txt
stage3-disassembly-binding.txt

b0-b1-b2-conservation.txt

c2-required-result.txt
```

Binding C2 block:

```text
STAGE2_B1_ARTIFACT_CREATED       = YES

STAGE3_CREATED                   = YES
STAGE3_LINKS_STAGE2_B1_ARTIFACT  = YES
STAGE3_USES_B1_COMPONENT         = YES

STAGE3_B1_ARTIFACT_PROVENANCE    = STAGE2

C2_TO_C3_GATE                    = OPEN
```

---

# 39. C3 EVIDENCE mission

C3 proves stability.

No production semantics should change in C3.

It must simultaneously establish:

```text
generation provenance
stage3 binding
direct semantic equivalence
broad successful-corpus equivalence
failure equivalence
error equivalence
stage3 self-source
stage2/stage3 fixed point
two-build reproducibility
B0/B1/B2 conservation
Factory conservation
```

---

# 40. C3 evidence packet

Create:

```text
evidence/ACT-POLYC-BOOTSTRAP04/c3/
```

Recommended:

```text
README.md

fresh-tree.txt

stage-identities.txt
generation-chain.txt

artifact-provenance.txt
stage3-symbol-binding.txt
stage3-delegation-witness.txt

component-stage2-stage3.txt
production-lexer-stage2-stage3.txt

corpus-inventory.txt
corpus-matrix-stage2-stage3.tsv
corpus-matrix-buildA.tsv
corpus-matrix-buildB.tsv
corpus-summary.txt

dollar-identifier-slice.txt
normal-source-slice.txt
test-source-slice.txt

error-corpus.tsv
error-corpus-summary.txt

stage3-self-source.txt
fixed-point.txt

reproducibility.txt

compiler-conservation.txt
factory-gates.txt
patch-hygiene.txt
scope-audit.txt

c3-required-result.txt
```

---

# 41. C3 acceptance matrix

### Provenance

```text
AC-C3-01 stage0 fresh
AC-C3-02 stage1 fresh
AC-C3-03 stage2 fresh

AC-C3-04 stage2 compiles B1 source
AC-C3-05 S2 artifact provenance captured

AC-C3-06 stage3 fresh
AC-C3-07 stage3 consumes exact S2 path
AC-C3-08 stage3 input hash = S2 output hash
```

### Binding

```text
AC-C3-09 stage3 contains _BootstrapScanIdent
AC-C3-10 stage3 lexer calls _BootstrapScanIdent
AC-C3-11 dynamic $-identifier compile succeeds
```

### Direct stability

```text
AC-C3-12 stage3 component differential = 15/15
AC-C3-13 stage3 cursor = 6/6

AC-C3-14 stage2↔stage3 production Lexer = 6/6
AC-C3-15 EOF cursor state stable
AC-C3-16 EOF pointer safety stable
```

### Broad corpus

```text
AC-C3-17 corpus regenerated mechanically
AC-C3-18 every source accounted

AC-C3-19 every stage2 success succeeds on stage3
AC-C3-20 every successful object byte-identical
AC-C3-21 successful mismatch count = 0

AC-C3-22 every stage2 baseline failure remains equivalent
AC-C3-23 failure divergence count = 0

AC-C3-24 unaccounted = 0
```

### Mandatory slices

```text
AC-C3-25 dir.HC $ identifier = PASS
AC-C3-26 ordinary library source = PASS
AC-C3-27 test source = PASS
AC-C3-28 B1 source = PASS
```

### Error corpus

```text
AC-C3-29 error corpus 4/4 equivalent
AC-C3-30 error divergence = 0
```

### Fixed point

```text
AC-C3-31 stage3 compiles B1 source

AC-C3-32 S2 B1 object == S3 B1 object
AC-C3-33 STAGE2_STAGE3_COMPONENT_FIXED_POINT = PASS
```

### Reproducibility

```text
AC-C3-34 clean Build A complete
AC-C3-35 clean Build B complete

AC-C3-36 S2 artifact reproducible
AC-C3-37 S3 behavior reproducible

AC-C3-38 corpus matrices A/B identical
AC-C3-39 error matrices A/B identical
```

### Conservation

```text
AC-C3-40 B0 15/15
AC-C3-41 B1 component 15/15
AC-C3-42 B1 cursor 6/6
AC-C3-43 B1 Lexer 6/6

AC-C3-44 B2 component 15/15
AC-C3-45 B2 cursor 6/6
AC-C3-46 B2 Lexer 6/6

AC-C3-47 LSP 43/43
AC-C3-48 gate-fast PASS
AC-C3-49 Factory gates PASS
AC-C3-50 shell-loc PASS
```

### Scope/hygiene

```text
AC-C3-51 compiler semantic delta ZERO
AC-C3-52 B1 source delta ZERO
AC-C3-53 lexer semantic delta ZERO
AC-C3-54 parser/AST/IR/backend delta ZERO

AC-C3-55 prior evidence mutation ZERO
AC-C3-56 committed binary evidence ZERO
AC-C3-57 current ACT range diff-check clean
```

### Truth boundary

```text
AC-C3-58 B2_FIRST_SELF_HOST = PASS

AC-C3-59 B3_BOOTSTRAP_STABILITY = PASS
AC-C3-60 B3_STABILITY_DOMAIN =
           CURRENT_SELF_HOSTED_COMPILER_COMPONENT

AC-C3-61 FULL_SELF_HOST = NO
AC-C3-62 HOST_C_DEPENDENCY = PRESENT

AC-C3-63 stage4 absent
```

---

# 42. Binding C3 result

`c3-required-result.txt` should end with:

```text
ACT_PHASE = EVIDENCE

B0_COMPILER_SHAPED   = PASS
B1_PARTIAL_SELF_HOST = PASS
B2_FIRST_SELF_HOST   = PASS

STAGE2_COMPILER = PASS
STAGE3_COMPILER = PASS

B1_COMPONENT_LANGUAGE = POLYC

STAGE2_COMPILES_B1_COMPONENT = PASS
STAGE2_B1_ARTIFACT_PROVENANCE = PASS

STAGE3_LINKS_STAGE2_B1_ARTIFACT = PASS
STAGE3_USES_B1_COMPONENT         = PASS

STAGE3_DIRECT_B1_EQ = PASS

STAGE2_STAGE3_LEXER_EQ  = PASS
STAGE2_STAGE3_CORPUS_EQ = PASS
STAGE2_STAGE3_ERROR_EQ  = PASS

STAGE3_COMPILES_B1_SOURCE = PASS

STAGE2_STAGE3_B1_OBJECT_EQ = PASS

REPRODUCIBILITY = PASS

B0_CONSERVATION = PASS
B1_CONSERVATION = PASS
B2_CONSERVATION = PASS

BOOTSTRAP_STABILITY = PASS
BOOTSTRAP_STABILITY_DOMAIN =
  CURRENT_SELF_HOSTED_COMPILER_COMPONENT

FIRST_SELF_HOST = YES
FULL_SELF_HOST  = NO
HOST_C_DEPENDENCY = PRESENT

STAGE4_CREATED = NO

C3_TO_C4_CLOSE_GATE = OPEN
```

---

# 43. B3 HALT taxonomy

### `HALT_B2_PREDECESSOR_NOT_GREEN`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_STAGE2_SELF_COMPILE_REGRESSION`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_STAGE3_PROVENANCE_UNPROVEN`

Stage3 exists but causal production by stage2 is not
mechanically established.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_STAGE3_BINDING_LOST`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_BOOTSTRAP_COMPONENT_DIVERGENCE`

Stage2 and stage3 materially disagree when compiling the B1
component.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_BOOTSTRAP_CORPUS_DIVERGENCE`

Any attributable stage2↔stage3 successful-output or
failure-path divergence.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_BOOTSTRAP_ERROR_DIVERGENCE`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_REPRODUCIBILITY_REGRESSION`

Independent B3 constructions disagree.

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_CONSERVATION_GATE_REGRESSION`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

### `HALT_SCOPE_EXPANSION_REQUIRED`

B3 requires semantic changes outside the build/stability
envelope.

```text
HALT_CLASS  = AUTHORIZATION
BLOCKS_NEXT = YES
```

---

# 44. Explicitly non-blocking findings

Unless executable evidence demonstrates production impact:

```text
B2 HANDOFF pointer typo
B2 "same inode" over-wording

unit/jit environment limitation
unit/jit runner false-green

historical captured-evidence whitespace

token dump absence

GEP01/push historical residue

minor evidence prose defects
README pointer mistakes
section numbering/style mistakes
```

must remain:

```text
HALT_CLASS  = GOVERNANCE
BLOCKS_NEXT = NO
```

**Prose never blocks the engineering board by itself.**

---

# 45. C4 CLOSE mission

C4 performs **zero implementation**.

Freshly re-prove from the C4 candidate tree:

```text
stage2 produces S2
stage3 consumes exact S2

stage3 links B1
stage3 calls B1

stage2↔stage3 direct semantics
stage2↔stage3 broad corpus
stage2↔stage3 errors

stage3 self-source
S2 == S3 B1 object

two-build reproducibility

B0 conservation
B1 conservation
B2 conservation

Factory gates

scope freeze
evidence hygiene
```

If all binding criteria remain green:

```text
ACT-Verdict: PASS
```

---

# 46. Canonical B3 closure block

```text
ACT =
  ACT-POLYC-BOOTSTRAP04

ACT_PHASE =
  CLOSE

ACT_VERDICT =
  PASS


B0_COMPILER_SHAPED =
  PASS

B1_PARTIAL_SELF_HOST =
  PASS

B2_FIRST_SELF_HOST =
  PASS

B3_BOOTSTRAP_STABILITY =
  PASS


BOOTSTRAP_STABILITY_DOMAIN =
  CURRENT_SELF_HOSTED_COMPILER_COMPONENT


B1_COMPONENT_LANGUAGE =
  POLYC


STAGE2_COMPILER =
  PASS

STAGE2_COMPILES_B1_COMPONENT =
  PASS

STAGE2_B1_ARTIFACT =
  PASS

STAGE2_B1_PROVENANCE =
  PASS


STAGE3_COMPILER =
  PASS

STAGE3_LINKS_STAGE2_ARTIFACT =
  YES

STAGE3_USES_B1_COMPONENT =
  YES


STAGE2_STAGE3_DIRECT_EQ =
  PASS

STAGE2_STAGE3_LEXER_EQ =
  PASS

STAGE2_STAGE3_CORPUS_EQ =
  PASS

STAGE2_STAGE3_ERROR_EQ =
  PASS


STAGE3_COMPILES_B1_SOURCE =
  PASS

STAGE2_STAGE3_B1_OBJECT_EQ =
  PASS


REPRODUCIBILITY =
  PASS


FIRST_SELF_HOST =
  YES

FULL_SELF_HOST =
  NO

HOST_C_DEPENDENCY =
  PRESENT


B0_CONSERVATION =
  PASS

B1_CONSERVATION =
  PASS

B2_CONSERVATION =
  PASS


P0_BLOCKERS =
  NONE
```

---

# 47. ROADMAP transition

Perform it in the **same authoritative C4 CLOSE commit**.

```text
B0 — COMPILER-SHAPED      GREEN

B1 — PARTIAL SELF-HOST    GREEN

B2 — FIRST SELF-HOST      GREEN

B3 — BOOTSTRAP STABILITY  GREEN
```

Do **not** immediately invent B4 unless the existing roadmap
already defines one.

Recommended B3 outcome block:

```text
B3_BOOTSTRAP_STABILITY =
  GREEN

STABILITY_DOMAIN =
  CURRENT_SELF_HOSTED_COMPILER_COMPONENT

STAGE2_PRODUCES_COMPONENT =
  YES

STAGE3_CONSUMES_STAGE2_ARTIFACT =
  YES

STAGE3_EXECUTES_COMPONENT =
  YES

STAGE2_STAGE3_DIRECT_EQ =
  PASS

STAGE2_STAGE3_BROAD_CORPUS_EQ =
  PASS

STAGE2_STAGE3_ERROR_EQ =
  PASS

STAGE3_COMPILES_COMPONENT =
  PASS

STAGE2_STAGE3_COMPONENT_FIXED_POINT =
  PASS

REPRODUCIBILITY =
  PASS

FIRST_SELF_HOST =
  YES

FULL_SELF_HOST =
  NO
```

---

# 48. Commit topology

Use:

```text
C1 RED
C2 IMPL
C3 EVIDENCE
C4 CLOSE
```

Multiple C2/C3 commits are allowed when each is truthful and
bounded.

Exactly one commit may carry:

```text
ACT: ACT-POLYC-BOOTSTRAP04
ACT-Phase: CLOSE
```

Final PASS trailer:

```text
ACT: ACT-POLYC-BOOTSTRAP04
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

No:

```text
HALT_CLASS
BLOCKS_NEXT
```

on a PASS CLOSE.

No post-CLOSE commit carrying the same ACT id.

ROADMAP, HANDOFF, final evidence, and verdict belong in the
one authoritative CLOSE geometry.

---

# 49. Cardinality and historical integrity

Required:

```text
BOOTSTRAP04_CLOSE_COUNT = 1
```

No historical evidence mutation:

```text
evidence/ACT-POLYC-BOOTSTRAP01/**
evidence/ACT-POLYC-BOOTSTRAP02/**
evidence/ACT-POLYC-BOOTSTRAP03/**
```

must remain F14-frozen.

---

# 50. No SHA-of-self

Never write the current commit's future SHA into an artifact
that same commit will contain.

Allowed:

```text
ENTRY_HEAD=<immutable predecessor>
C1_RED=<already committed predecessor phase>
```

Not allowed:

```text
C4_CLOSE_SHA=<future/current commit's SHA>
FINAL_HEAD=<self SHA embedded in own tree>
```

For closure identity use:

```text
CLOSE_COMMIT = this authoritative CLOSE commit
```

and let Git supply the actual SHA externally.

---

# 51. Required final report

Successful B3 closure should reduce to:

```text
VERDICT: PASS

ACT-POLYC-BOOTSTRAP04 is CLOSED.

B0:
  GREEN

B1:
  GREEN

B2 FIRST SELF-HOST:
  GREEN

B3 BOOTSTRAP STABILITY:
  PASS

Stability domain:
  CURRENT_SELF_HOSTED_COMPILER_COMPONENT


Generation chain:

  stage0
    -> B1 component
    -> stage1

  stage1
    -> B1 component
    -> stage2

  stage2
    -> B1 component
    -> stage3


Stage3 provenance:
  exact stage2-produced artifact consumed
  PASS

Stage3 binding:
  component linked
  production lexer calls component
  PASS


Direct stage2↔stage3:
  component 15/15
  cursor 6/6
  Lexer seam 6/6

Broad corpus:
  all stage2-success sources matched stage3
  successful object mismatches = 0
  baseline failure divergences = 0
  unaccounted = 0

Error corpus:
  divergence = 0

Stage3 self-source:
  PASS

Stage2/stage3 B1 object:
  byte-identical

Repeated bootstrap:
  Build A == Build B
  PASS

B0/B1/B2 conservation:
  PASS

Factory:
  PASS

FIRST_SELF_HOST:
  YES

BOOTSTRAP_STABILITY:
  PASS

BOOTSTRAP_STABILITY_DOMAIN:
  CURRENT_SELF_HOSTED_COMPILER_COMPONENT

FULL_SELF_HOST:
  NO

HOST_C_DEPENDENCY:
  PRESENT

P0:
  NONE
```

---

# 52. Hard stop

After the authoritative B3 CLOSE:

```text
STOP.
```

Do not in the same execution:

```text
create stage4
migrate another compiler subsystem
declare FULL_SELF_HOST
repair unrelated runners
repair GEP01
rewrite previous evidence
clean governance residue
push without separate authorization
invent B4 scope
```

At B3 close, the correct next operation is **board design**.

---

## Board objective

The bootstrap epic then reads:

```text
B0  COMPILER-SHAPED
    ✅ GREEN

B1  PARTIAL SELF-HOST
    ✅ GREEN

B2  FIRST SELF-HOST
    ✅ GREEN

B3  BOOTSTRAP STABILITY
    🎯 ACT-POLYC-BOOTSTRAP04
```

B2 proved:

> **A compiler containing PolyC-authored compiler logic can
> compile that logic for its successor.**

B3 must prove:

> **Once that self-host chain is closed, another generation
> does not change what the compiler produces across the entire
> currently self-hosted domain.**

That is the first defensible point at which we call the PolyC
bootstrap chain **stable**, while still explicitly refusing the
much stronger claim of full compiler self-hosting.
