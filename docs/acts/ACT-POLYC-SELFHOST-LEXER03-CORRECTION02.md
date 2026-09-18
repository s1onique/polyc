# ACT-POLYC-SELFHOST-LEXER03-CORRECTION02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Prove the LEXER03 `BootstrapScanTrivia` component reaches a
four-generation object-code fixed point under `./hcc`,
`hcc-bootstrap02`, `hcc-bootstrap03`, and `hcc-bootstrap04`.

**Repository:** PolyC (https://github.com/s1onique/polyc)

**Branch:** `main`

**Class:** SELFHOST / BOOTSTRAP / FIXED-POINT QUALIFICATION

**Predecessor workstream:** `ACT-POLYC-SELFHOST-LEXER03`

**Predecessor engineering state:**

```text
ENGINEERING_RESULT        = GREEN
STAGE0_STAGE1_EQUIVALENCE = GREEN
LEXER03_TRIVIA_FIXED_POINT_4_GENERATIONS = NOT_YET_PROVEN  (this ACT)
```

**Known missing predicate (this ACT's target):**

```text
LEXER03_COMPONENT_OBJECT_4GEN_FIXED_POINT = NOT_YET_PROVEN
```

**Production language-semantics changes:** FORBIDDEN.

**Lexer behavior changes:** FORBIDDEN.

**Parser / IR / codegen / ABI changes:** FORBIDDEN.

**Production-source changes to:** `src/lexer.c`, `src/lexer_bridge.h`,
`tools/bootstrap/selfhost-lexer-trivia.HC`: FORBIDDEN (subject to
§6 HALT_LATER_GENERATION_CANNOT_COMPILE_TRIVIA_SOURCE carve-out).

This ACT exists to perform the missing bootstrap qualification, not to
redesign trivia scanning.

---

## 0. Mission

LEXER03 migrated the `trivia_scanner` responsibility into:

```text
tools/bootstrap/selfhost-lexer-trivia.HC
```

with exported component:

```text
BootstrapScanTrivia
```

The existing qualification establishes:

```text
stage0 legacy-C lexer
    vs
stage1 lexer using BootstrapScanTrivia
```

is semantically equivalent on the real production seam.

The existing LEXER03 broad-corpus smoke test (`lexer08-broad-corpus-4-stage`)
also establishes that all four compiler generations can link a binary
containing `BootstrapScanTrivia`.

What has NOT yet been mechanically demonstrated is the stronger
self-hosting predicate:

> Compiling the exact same `selfhost-lexer-trivia.HC` source with each
> successive compiler generation produces the same object bytes.

This ACT shall establish that fixed point.

Canonical compiler-generation mapping:

```text
G0 = ./hcc
G1 = ./build/hcc-bootstrap02
G2 = ./build/hcc-bootstrap03
G3 = ./build/hcc-bootstrap04
```

For one immutable source blob:

```text
tools/bootstrap/selfhost-lexer-trivia.HC
```

produce:

```text
O0 = compile(source, G0)
O1 = compile(source, G1)
O2 = compile(source, G2)
O3 = compile(source, G3)
```

and prove:

```text
O0 == O1 == O2 == O3
```

by **actual byte equality**, not merely equal hashes.

SHA-256 binds provenance.

The successful terminal predicate is:

```text
LEXER03_TRIVIA_FIXED_POINT_4_GENERATIONS = PASS
```

---

## 1. Why

The CORRECTION01 closure recorded:

> P0: LEXER03-specific stage2/stage3 fixed-point evidence (out of
> CORRECTION01 scope; requires bounded-evidence work in a future ACT)

The generations are already available:

```text
./hcc
./build/hcc-bootstrap02
./build/hcc-bootstrap03
./build/hcc-bootstrap04
```

and the existing broad-corpus smoke test establishes they can all
build/link with LEXER03 present.

Therefore the remaining work is bounded:

1. determine the canonical compile invocation;
2. make all four generations compile the same `.HC` input independently;
3. preserve the resulting four `.o` files separately;
4. compare their bytes;
5. bind source/compiler/object identity;
6. prove the comparison gate detects an injected mismatch.

No lexer behavior needs to change.

---

## 2. Binding entry state

At C1 entry record:

```sh
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1

sha256sum tools/bootstrap/selfhost-lexer-trivia.HC
sha256sum ./hcc
sha256sum ./build/hcc-bootstrap02
sha256sum ./build/hcc-bootstrap03
sha256sum ./build/hcc-bootstrap04
```

Required:

```text
BRANCH = main
WORKTREE_CLEAN = TRUE

SOURCE_PATH = tools/bootstrap/selfhost-lexer-trivia.HC
SOURCE_SHA256 = <64hex>

G0_PRESENT = YES
G1_PRESENT = YES
G2_PRESENT = YES
G3_PRESENT = YES
```

If any compiler generation does not exist:

```text
HALT_COMPILER_GENERATION_MISSING
```

Do not silently substitute another compiler.

---

## 3. C1 RED — prove the missing fixed-point surface

C1 is evidence/recon only.

Do not mutate production or build logic before RED is frozen.

### 3.1 Existing LEXER03 evidence stops short of the fixed point

Mechanically inspect:

```text
evidence/ACT-POLYC-SELFHOST-LEXER03/c3/c3-stage0.txt
evidence/ACT-POLYC-SELFHOST-LEXER03/c3/c3-stage1.txt
evidence/ACT-POLYC-SELFHOST-LEXER03/c3/c3-stage2.txt
evidence/ACT-POLYC-SELFHOST-LEXER03/c3/c3-stage3.txt
```

Required entry observation:

```text
LEXER03_EXISTING_STAGE0_COMPONENT_OBJECT = NOT_PROVEN_AS_4GEN_SET
LEXER03_EXISTING_STAGE1_COMPONENT_OBJECT = NOT_PROVEN_AS_4GEN_SET
LEXER03_EXISTING_STAGE2_COMPONENT_OBJECT = N/A_OR_ABSENT
LEXER03_EXISTING_STAGE3_COMPONENT_OBJECT = N/A_OR_ABSENT

LEXER03_4GEN_COMPONENT_FIXED_POINT      = NOT_PROVEN
```

This is the principal RED.

### 3.2 Current Make topology does not preserve all four component objects

Required RED is either:

```text
INDEPENDENT_G0_OBJECT = NO
INDEPENDENT_G1_OBJECT = NO
INDEPENDENT_G2_OBJECT = NO
INDEPENDENT_G3_OBJECT = NO
```

or a truthful per-generation inventory.

If some already exist, reuse them only after proving how they were
produced.

---

## 4. C1 — discover canonical compile command

Do not guess compiler flags.

Mechanically derive the canonical command currently used to compile:

```text
tools/bootstrap/selfhost-lexer-trivia.HC
```

with `./hcc`.

Inspect:

* `Makefile` (the existing `lexer08-component-build` target);
* LEXER08 component build;
* bootstrap component build rules (`bootstrap03-component-build`,
  `bootstrap04-component-build` for the analogous B1 component).

Freeze a normalized compile template:

```text
<COMPILER> --install-dir=$(TEST_PREFIX) \
  -c tools/bootstrap/selfhost-lexer-trivia.HC \
  -o <OUTPUT_OBJECT>
```

Required C1 artifact:

```text
c1-canonical-compile-contract.txt
```

containing:

```text
SOURCE =
FLAGS =
OUTPUT_KIND = OBJECT
EXTRA_INCLUDE_PATHS =
EXTRA_DEFINES =
ENVIRONMENT_REQUIREMENTS =
```

The only variable between G0/G1/G2/G3 shall be:

```text
COMPILER_PATH
OUTPUT_PATH
```

unless the current toolchain mechanically requires a
generation-specific flag (none observed at C1 recon).

Any such difference must be explicitly justified before C2.

---

## 5. Scope

### Allowed

#### Build orchestration

Bounded modifications to:

```text
Makefile
```

to add explicit LEXER03 fixed-point targets.

Target family:

```text
lexer08-trivia-fixedpoint-g0
lexer08-trivia-fixedpoint-g1
lexer08-trivia-fixedpoint-g2
lexer08-trivia-fixedpoint-g3
lexer08-trivia-fixedpoint-build
lexer08-trivia-fixedpoint-verify
lexer08-trivia-fixedpoint
```

#### Verification tooling

Prefer existing PolyC verification primitives.

Add one small PolyC tool:

```text
tools/quality/lexer08-fixedpoint-verify.HC
```

Its responsibilities include:

* read N files (default 4) plus an optional 5th mutated copy;
* compare lengths and bytes (MemCmp-based ObjectsByteEqual);
* call `./build/lexer07-sha256 --file <path>` per file for
  provenance SHA-256;
* emit structured `PASS/FAIL` token per pairwise comparison;
* exit non-zero if any pairwise comparison is `FAIL` or any file
  is missing/empty;
* refuse to run if any closed-evidence path is targeted without
  `--allow-closed`.

Add a thin shell launcher (≤50 LOC) under:

```text
scripts/quality/lexer08-trivia-fixedpoint.sh
```

#### Evidence

New directory only:

```text
evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION02/
```

#### Documentation

Only:

```text
docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION02.md  (this file)
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER03-CORRECTION02.md
docs/ROADMAP.md   (additive amendment only)
```

No cleanup of older ACTs, HANDOFFs, or evidence.

---

## 6. Forbidden

This ACT SHALL NOT modify:

```text
src/lexer.c
src/lexer_bridge.h
tools/bootstrap/selfhost-lexer-trivia.HC
```

except if C1 proves the source itself cannot be compiled by a later
generation because of a **newly exposed compiler defect**.

In that case:

```text
HALT_LATER_GENERATION_CANNOT_COMPILE_TRIVIA_SOURCE
```

Do not patch the trivia implementation inside this ACT.

Also forbidden:

* parser changes;
* codegen changes;
* IR changes;
* ABI changes;
* libtos semantic changes;
* new Python;
* substantive shell tooling (≤50 LOC dispatch glue only);
* rewriting old evidence;
* rewriting old HANDOFFs;
* formatting/document cleanup;
* LEXER04 work;
* unrelated bootstrap work.

---

## 7. C2 implementation — produce four independent objects

From the exact source blob frozen at C1:

```text
S = tools/bootstrap/selfhost-lexer-trivia.HC
```

produce:

```text
O0 = G0(S)
O1 = G1(S)
O2 = G2(S)
O3 = G3(S)
```

Object paths:

```text
build/lexer08-fixedpoint/trivia.g0.o
build/lexer08-fixedpoint/trivia.g1.o
build/lexer08-fixedpoint/trivia.g2.o
build/lexer08-fixedpoint/trivia.g3.o
```

Each invocation MUST start from absent output.

Before each compile:

```sh
rm -f <object>
test ! -e <object>
```

After each compile:

```sh
test -s <object>
```

Capture compiler rc.

Required:

```text
G0_COMPILE_RC = 0
G1_COMPILE_RC = 0
G2_COMPILE_RC = 0
G3_COMPILE_RC = 0
```

---

## 8. Compiler identity binding

For every generation record:

```text
generation
compiler_path
compiler_sha256
source_path
source_sha256
object_path
object_size
object_sha256
compile_rc
```

Artifact:

```text
c3-fixedpoint-provenance.tsv
```

Schema:

```text
generation	compiler_path	compiler_sha256	source_path	source_sha256	object_path	object_size	object_sha256	compile_rc
```

Exactly:

```text
1 header
4 data rows
```

Required:

```text
PROVENANCE_ROWS         = 4
UNIQUE_GENERATIONS      = 4
SOURCE_SHA_UNIQUE_COUNT = 1
COMPILER_SHA_NONEMPTY   = 4
OBJECT_SHA_NONEMPTY     = 4
```

If two compiler binaries themselves happen to be byte-identical, that
is acceptable but must be recorded rather than assumed.

---

## 9. Actual byte equality

The fixed-point truth predicate MUST be byte equality.

Required checks:

```text
size(O0) == size(O1)
size(O0) == size(O2)
size(O0) == size(O3)

memcmp(O0,O1) == 0
memcmp(O0,O2) == 0
memcmp(O0,O3) == 0
memcmp(O1,O2) == 0
memcmp(O1,O3) == 0
memcmp(O2,O3) == 0
```

Equivalent `cmp` is acceptable as an independent cross-check.

SHA-256 equality alone is insufficient.

Required output:

```text
G0_G1_BYTE_EQUAL = YES
G0_G2_BYTE_EQUAL = YES
G0_G3_BYTE_EQUAL = YES
G1_G2_BYTE_EQUAL = YES
G1_G3_BYTE_EQUAL = YES
G2_G3_BYTE_EQUAL = YES

LEXER03_TRIVIA_FIXED_POINT_4_GENERATIONS = PASS
```

---

## 10. Symbol-level conservation

Even if object bytes match, record the expected exported component
identity.

Run `nm` per object and verify:

```text
BootstrapScanTrivia
```

is present in every object.

Required:

```text
G0_BOOTSTRAP_SCAN_TRIVIA_SYMBOL = YES
G1_BOOTSTRAP_SCAN_TRIVIA_SYMBOL = YES
G2_BOOTSTRAP_SCAN_TRIVIA_SYMBOL = YES
G3_BOOTSTRAP_SCAN_TRIVIA_SYMBOL = YES
```

If platform symbol decoration yields `_BootstrapScanTrivia`, normalize
only the leading platform decoration.

Do not normalize arbitrary symbol differences.

---

## 11. Determinism control

Compile the source twice with the **same compiler generation** into
two separate fresh outputs.

Prefer G3 because it is the deepest bootstrap generation:

```text
G3A = G3(S)
G3B = G3(S)
```

Require:

```text
G3A_G3B_BYTE_EQUAL = YES
```

This distinguishes:

```text
cross-generation mismatch
```

from:

```text
same-compiler nondeterministic object generation
```

If G3 self-repeat is non-deterministic:

```text
HALT_OBJECT_OUTPUT_NONDETERMINISTIC
```

Do not classify that as a LEXER03 semantic failure.

---

## 12. Negative control — prove the verifier is load-bearing

Create a temporary copy of one object:

```text
build/lexer08-fixedpoint/trivia.g3.mutated.o
```

Flip exactly one byte outside the source/build tree at the end of the
file (deterministic 0x00 ↔ 0x01 flip).

Do not mutate canonical build artifacts (O0..O3) directly.

Run the fixed-point verifier against:

```text
O0
O1
O2
mutated(O3)
```

Required:

```text
NEGATIVE_CONTROL_MUTATION_APPLIED = YES
FIXEDPOINT_VERIFIER_RC           != 0
BYTE_MISMATCH_DETECTED           = YES
NEGATIVE_CONTROL                 = PASS
```

Then rerun against pristine objects:

```text
FIXEDPOINT_VERIFIER_RC           = 0
LEXER03_TRIVIA_FIXED_POINT_4_GENERATIONS = PASS
```

---

## 13. Fresh-tree discipline

C3 qualification MUST rebuild from a clean fixed-point output directory.

Required:

```sh
rm -rf build/lexer08-fixedpoint
mkdir -p build/lexer08-fixedpoint
```

Do not reuse previous ACT object files as proof inputs.

The compiler binaries themselves may be existing canonical G0..G3
binaries, but their SHA-256 values must be bound before use.

---

## 14. C3 semantic conservation

Even though this ACT does not change trivia semantics, re-run the
important predecessor predicates.

Required:

```text
LEXER08_DIRECT_DIFFERENTIAL    = PASS
DIRECT_DIFFERENTIAL_TOTAL      = 45
DIRECT_DIFFERENTIAL_PASS       = 45
DIRECT_DIFFERENTIAL_FAIL       = 0
```

Required real seam:

```text
LEXER08_PRODUCTION_SEAM_STAGE0_VS_STAGE1 = PASS
```

The existing real seam has already shown all 15 trivia cases
identical except `BUILD_LABEL`; preserve that behavior.

---

## 15. Predecessor conservation

Re-run:

```text
LEXER01_CONSERVATION = PASS
LEXER02_CONSERVATION = PASS
```

Expected observed predecessor values:

```text
LEXER01                              = 47/47
LEXER02                              = 89/89
LEXER07_PRODUCTION_SEAM_4_STAGES     = PASS
```

Do not silently adjust expected counts if they drift.

If current repository state legitimately changes counts before this
ACT:

```text
HALT_PREDECESSOR_BASELINE_DRIFT
```

---

## 16. Broad compiler conservation

Run:

```sh
make lexer08-broad-corpus-4-stage
```

Required:

```text
LEXER08_BROAD_CORPUS_4_STAGE = PASS
```

This remains a build/link conservation test.

Do not use it as a substitute for the new fixed-point object proof.

Explicitly distinguish:

```text
FOUR_GENERATION_BUILD_SMOKE           = PASS
FOUR_GENERATION_COMPONENT_FIXED_POINT = PASS
```

Both are required.

---

## 17. Phase topology

### C0 AUTH

This ACT document exists before implementation/evidence mutation.

### C1 RED / RECON

Freeze:

* entry identity;
* source identity;
* compiler identities;
* missing fixed-point predicate;
* canonical compile command;
* allowed build changes.

### C2 IMPL

Only build orchestration and the bounded PolyC fixed-point verifier.

No trivia semantic changes.

### C3 EVIDENCE

Fresh four-generation compilation and qualification.

No C2 implementation changes during C3.

If implementation tooling is defective:

```text
HALT_C2_TOOLING_DEFECT_DURING_C3
```

### C4 CLOSE

HANDOFF / ROADMAP only.

Do not mutate C3 evidence at CLOSE.

---

## 18. Commit topology

```text
C0 AUTH
C1 RED
C2 IMPL
C3 EVIDENCE
C4 CLOSE
```

If C0 and C1 are intentionally combined according to current
repository convention, record that explicitly before implementation.

No retroactive authorization.
No amend.
No rebase.
No force-push.
No reset+recommit.

---

## 19. Acceptance criteria

| AC    | Predicate                                                                        | Required |
|-------|----------------------------------------------------------------------------------|----------|
| AC01  | `WORKTREE_CLEAN_AT_ENTRY = YES`                                                  | YES      |
| AC02  | `G0_PRESENT`, `G1_PRESENT`, `G2_PRESENT`, `G3_PRESENT = YES`                     | YES      |
| AC03  | `SOURCE_SHA_UNIQUE_COUNT = 1`                                                    | YES      |
| AC04  | `CANONICAL_COMPILE_CONTRACT = FROZEN`                                            | YES      |
| AC05  | `G0_COMPILE_RC = 0`                                                              | YES      |
| AC06  | `G1_COMPILE_RC = 0`                                                              | YES      |
| AC07  | `G2_COMPILE_RC = 0`                                                              | YES      |
| AC08  | `G3_COMPILE_RC = 0`                                                              | YES      |
| AC09  | `PROVENANCE_ROWS = 4`; `PROVENANCE_SCHEMA_VALID = YES`                           | YES      |
| AC10  | `OBJECT_SIZE_UNIQUE_COUNT = 1`                                                   | YES      |
| AC11  | `LEXER03_TRIVIA_FIXED_POINT_4_GENERATIONS = PASS`                                | YES      |
| AC12  | `OBJECT_SHA256_UNIQUE_COUNT = 1`                                                 | YES      |
| AC13  | `BOOTSTRAP_SCAN_TRIVIA_PRESENT_ALL_GENERATIONS = YES`                            | YES      |
| AC14  | `G3_REPEAT_BYTE_EQUAL = YES`                                                     | YES      |
| AC15  | `NEGATIVE_CONTROL = PASS`                                                        | YES      |
| AC16  | `LEXER08_DIRECT_DIFFERENTIAL = 45/45 PASS`                                       | YES      |
| AC17  | `LEXER08_PRODUCTION_SEAM_STAGE0_VS_STAGE1 = PASS`                                | YES      |
| AC18  | `LEXER01_CONSERVATION = 47/47 PASS`                                              | YES      |
| AC19  | `LEXER02_CONSERVATION = 89/89 PASS`; `LEXER07_PRODUCTION_SEAM_4_STAGES = PASS`    | YES      |
| AC20  | `LEXER08_BROAD_CORPUS_4_STAGE = PASS`                                            | YES      |
| AC21  | `git diff <ENTRY_HEAD>..<CANDIDATE_CLOSE> -- src/ tools/bootstrap/selfhost-lexer-trivia.HC` empty | YES |
| AC22  | `NEW_PYTHON_SOURCES = 0`; `NEW_PYTHON_INVOCATIONS = 0`                           | YES      |
| AC23  | `NEW_SUBSTANTIVE_NON_POLYC_TOOLS = 0`                                            | YES      |
| AC24  | `gate-fast = PASS`; `factory-append-only-test = PASS`                            | YES      |
| AC25  | `git diff --check <ENTRY_HEAD>..<CANDIDATE_CLOSE>` clean                          | YES      |
| AC26  | `git status --porcelain=v1` empty at CLOSE                                       | YES      |
| AC27  | `APPEND_ONLY_HISTORY = TRUE`                                                     | YES      |

---

## 20. Required result ledger

C3 must mechanically emit:

```text
ACT = ACT-POLYC-SELFHOST-LEXER03-CORRECTION02

SOURCE_SHA256 = <sha>

G0_COMPILER = ./hcc
G1_COMPILER = ./build/hcc-bootstrap02
G2_COMPILER = ./build/hcc-bootstrap03
G3_COMPILER = ./build/hcc-bootstrap04

G0_COMPILE = PASS
G1_COMPILE = PASS
G2_COMPILE = PASS
G3_COMPILE = PASS

G0_G1_BYTE_EQUAL = YES
G0_G2_BYTE_EQUAL = YES
G0_G3_BYTE_EQUAL = YES
G1_G2_BYTE_EQUAL = YES
G1_G3_BYTE_EQUAL = YES
G2_G3_BYTE_EQUAL = YES

OBJECT_SHA256_UNIQUE_COUNT = 1
OBJECT_SIZE_UNIQUE_COUNT  = 1

BOOTSTRAP_SCAN_TRIVIA_PRESENT_ALL_GENERATIONS = YES

G3_REPEAT_BYTE_EQUAL = YES

NEGATIVE_CONTROL = PASS

LEXER08_DIRECT_DIFFERENTIAL    = 45/45_PASS
LEXER08_PRODUCTION_SEAM_STAGE0_VS_STAGE1 = PASS

LEXER01_CONSERVATION = PASS
LEXER02_CONSERVATION = PASS

FOUR_GENERATION_BUILD_SMOKE            = PASS
FOUR_GENERATION_COMPONENT_FIXED_POINT  = PASS

VERDICT = PASS_TRUE_GREEN
```

---

## 21. Failure classification

| HALT token                                  | Meaning                                                      |
|---------------------------------------------|--------------------------------------------------------------|
| `HALT_COMPILER_GENERATION_MISSING`          | One of G0..G3 is absent.                                     |
| `HALT_CANONICAL_COMPILE_CONTRACT_UNKNOWN`   | Cannot determine a trustworthy compile invocation.           |
| `HALT_G0_COMPONENT_COMPILE`                 | G0 fails to compile source.                                  |
| `HALT_G1_COMPONENT_COMPILE`                 | G1 fails.                                                    |
| `HALT_G2_COMPONENT_COMPILE`                 | G2 fails.                                                    |
| `HALT_G3_COMPONENT_COMPILE`                 | G3 fails.                                                    |
| `HALT_OBJECT_OUTPUT_NONDETERMINISTIC`       | Same compiler + same source produces differing bytes.        |
| `HALT_FIXEDPOINT_BYTE_DIVERGENCE`           | All compilers succeed but resulting object bytes differ.     |
| `HALT_SYMBOL_DIVERGENCE`                    | `BootstrapScanTrivia` symbol differs/disappears.             |
| `HALT_NEGATIVE_CONTROL_FAILED`              | Verifier accepts mutated artifact.                           |
| `HALT_PREDECESSOR_BASELINE_DRIFT`           | LEXER01/02 or existing LEXER03 seam regresses.               |
| `HALT_FACTORY_GATE_REGRESSION`              | Factory gate fails.                                          |
| `HALT_SCOPE_EXPANSION_REQUIRED`             | Fix requires semantic/compiler changes beyond this ACT.      |

These are **real bootstrap findings** and should not be normalized
away.

---

## 22. If fixed-point divergence occurs

Do not immediately "fix" it.

If:

```text
O0 != O1
or
O1 != O2
or
O2 != O3
```

first classify the divergence.

Capture:

```text
object sizes
SHA-256
first differing offset
symbol table
section table
relocations
```

using platform-appropriate tooling.

Determine whether divergence is:

```text
SEMANTIC_CODEGEN
RELOCATION_ONLY
SYMBOL_ORDER
DEBUG_METADATA
TIMESTAMP_OR_BUILD_METADATA
SECTION_ORDER
UNKNOWN
```

The ACT HALTs after classification.

A true compiler/codegen correction requires a separate ACT.

Do not hide deterministic differences by stripping/normalizing
objects unless the authorization is explicitly amended to define a
normalized fixed-point predicate.

The default contract is **raw object byte identity**.

---

## 23. Conservation principle

This ACT does not improve trivia semantics.

It proves bootstrap stability.

Therefore:

```text
SOURCE_BEFORE_SHA256
    ==
SOURCE_AFTER_SHA256
```

for:

```text
tools/bootstrap/selfhost-lexer-trivia.HC
```

is mandatory.

Likewise no production lexer source mutation is expected.

If a later compiler cannot compile the current valid source, that is
useful evidence of a compiler-generation defect — not permission to
rewrite the component until it compiles.

---

## 24. Successful closure meaning

If this ACT closes TRUE GREEN, we may finally state:

```text
BootstrapScanTrivia source
    ↓ compiled by
G0 ./hcc
    ↓
O0
    =
O1 <- G1 hcc-bootstrap02
    =
O2 <- G2 hcc-bootstrap03
    =
O3 <- G3 hcc-bootstrap04
```

Therefore:

```text
LEXER03_STAGE0_STAGE1_SEMANTIC_EQUIVALENCE = PASS
LEXER03_4_GENERATION_BUILD_SMOKE           = PASS
LEXER03_COMPONENT_OBJECT_FIXED_POINT       = PASS

LEXER03_BOOTSTRAP_QUALIFICATION            = COMPLETE
```

This removes the remaining substantive LEXER03 fixed-point residue.

---

## 25. Next

Only after TRUE GREEN:

```text
NEXT = fresh SELFHOST surface recon
```

At that point `ACT-POLYC-SELFHOST-LEXER04` becomes a legitimate
candidate.

Do not automatically choose LEXER04 from numbering alone; run the
current surface recon and select the next actual self-host blocker.

---

## 26. Execution instruction

Start with the real experiment.

Do not spend the first cycle editing historical LEXER03 documents.

The first useful output from this ACT should answer:

```text
Can G0, G1, G2, and G3 each independently compile
tools/bootstrap/selfhost-lexer-trivia.HC?
```

If yes, immediately compare the four objects.

If the objects differ, **stop and classify the compiler-generation
divergence**.

If they are byte-identical, run determinism + mutation controls +
conservation and close the missing fixed-point proof.
