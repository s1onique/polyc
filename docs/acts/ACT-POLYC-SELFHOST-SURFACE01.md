# ACT-POLYC-SELFHOST-SURFACE01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** First-class self-host component registry and
deterministic build graph — replace the bespoke B1/B2/B3
component plumbing with one mechanically-defined
self-host component model so that subsequent ACTs can migrate
the rest of the production Lexer without authoring a new
stage-N recipe per function.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** SELF-HOST / BUILD-ARCHITECTURE / MIGRATION-ENABLER

**Predecessor:** `ACT-POLYC-BOOTSTRAP04` CLOSED PASS
(B3 bootstrap stability — stage2↔stage3 fixed point
over the currently self-hosted compiler component;
15/15 component differential, 6/6 cursor, 6/6 production
Lexer seam, 175/175 successful-corpus byte equality,
6/6 equivalent failures, 4/4 error equivalence,
two-build reproducibility, BOOTSTRAP_STABILITY = PASS,
STAGE3_CREATED = NO)

**Production compiler semantic changes:** **NONE**

**New compiler subsystem migration:** **NONE**

**Language changes:** **NONE**

**Parser/AST/IR/backend changes:** **NONE**

**LLVM authorization:** **NONE**

**MEMORY01 widening:** **FORBIDDEN**

**B0 lexer changes:** **FORBIDDEN**

**B1 component source changes:** **FORBIDDEN**
(`tools/bootstrap/bootstrap02-ident.HC` remains frozen by
predecessor §5 / §9)

**B1 production lexer changes:** **FORBIDDEN**
(`src/lexer.c`, `src/lexer_bridge.h` remain frozen by
predecessor §5 / §9)

**New bootstrap stage creation:** **FORBIDDEN**
(no `HCC_ENABLE_BOOTSTRAP05_*`, no `build/hcc-bootstrap05`)

**VERDICT (target):** `PASS`

---
## Mission

Replace the bespoke B1/B2/B3 component plumbing with one
mechanically-defined self-host component model.

Today the successful lineage is effectively:

```text
bootstrap02-ident.HC
  stage0 -> bootstrap02-ident.o
  stage1 -> bootstrap03-ident.stage1.o
  stage2 -> bootstrap04-ident.stage2.o
```

and each generation has its own manually-authored
Makefile / CMakeLists.txt wiring.

That was exactly right for proving bootstrap.

It is the wrong abstraction for migrating twenty more
compiler functions.

The post-B3 architecture should become:

```text
SELF_HOST_COMPONENTS
        |
        +-- identifier_scanner
        |
        +-- future lexer component
        |
        +-- future parser component
        ...
```

with generic operations:

```text
component source
    ↓
compile with requested stage
    ↓
generation-qualified object
    ↓
link into requested compiler stage
    ↓
run component-specific oracle
    ↓
run global conservation
```

The output of this ACT is **migration machinery**, not
another migrated compiler feature.

---

## Truth boundary

Success means:

```text
SELF_HOST_COMPONENT_MODEL        = PASS
IDENTIFIER_COMPONENT_REGISTERED  = YES
B3_BEHAVIOR_PRESERVED            = YES
BESPOKE_STAGE4_REQUIRED          = NO
NEXT_COMPONENT_MIGRATION_READY   = YES
```

It does **not** mean:

```text
FULL_SELF_HOST         = YES
LEXER_SELF_HOSTED      = YES
PARSER_SELF_HOSTED     = YES
NEW_COMPONENT_MIGRATED = YES
```

No compiler semantics change in this ACT.

---

## Principal RED

The RED is not that the existing bootstrap is broken.

The RED is:

```text
SELF_HOST_COMPONENT_MODEL = ABSENT
```

Current state (mechanically observable):

```text
identifier component exists              YES
component source is PolyC                 YES
component self-host chain stable          YES

generic component registry                NO
generic component metadata                NO
generic stage producer abstraction        NO
generic component verification entrypoint NO

B1/B2/B3 wiring is encoded directly in:
  Makefile
  src/CMakeLists.txt
  bootstrap02/bootstrap03/bootstrap04 naming
```

That is acceptable for the bootstrap experiment, but it
does not scale to subsystem migration.

---
## Scope

### allowed

- New file `docs/factory/SELF-HOST-COMPONENTS.tsv`
  (registry schema + initial row for the existing
  `identifier_scanner` component).
- Minimum build support needed to consume the registry:
  `Makefile` helpers, optional `CMake` helper, and/or
  `tools/selfhost/*.sh` driver, chosen as the smallest
  mechanism that proves the abstraction.
- Mechanical machinery for:
    - `selfhost-component-build COMPONENT=<id> STAGE=<n>`
    - `selfhost-component-test  COMPONENT=<id> STAGE=<n>`
    - generic provenance emission
    - generic negative-control validation of the registry.
- Compatibility aliases for historical Make targets
  (`bootstrap02-component-build`,
  `bootstrap03-component-build`,
  `bootstrap04-component-build`,
  `bootstrap02-stage1`, `bootstrap03-stage2`,
  `bootstrap04-stage3`) implemented as thin wrappers
  over the generic machinery where this preserves frozen
  output.
- New ACT document at
  `docs/acts/ACT-POLYC-SELFHOST-SURFACE01.md` (this file).
- C1/C2/C3/C4 evidence packets under
  `evidence/ACT-POLYC-SELFHOST-SURFACE01/`.

### forbidden

- Any edit to `src/lexer.c`, `src/lexer_bridge.h`,
  `tools/bootstrap/bootstrap02-ident.HC`, or any
  parser/AST/IR/backend source.
- Any edit to the existing successful bootstrap chain's
  frozen output:
  `build/bootstrap02-ident.o`,
  `build/bootstrap03-ident.stage1.o`,
  `build/bootstrap04-ident.stage2.o`,
  `build/hcc-bootstrap02`, `build/hcc-bootstrap03`,
  `build/hcc-bootstrap04`.
- Any new `HCC_ENABLE_BOOTSTRAP0N_STAGEn` macro for
  `N >= 5`.
- Any new compiler subsystem migration
  (no new PolyC-written lexer / parser / IR / backend
  function).
- Renaming of historical bootstrap artifacts in a way that
  invalidates `B1_OUTPUT_EQ_BEFORE_AFTER`,
  `B2_OUTPUT_EQ_BEFORE_AFTER`, or
  `B3_OUTPUT_EQ_BEFORE_AFTER`.
- New dependencies.
- Edit of historical evidence directories under
  `evidence/ACT-POLYC-BOOTSTRAP0[1-4]/`.

---

## Why

After B3 closes PASS the bootstrap board has reached its
natural terminal condition:

```text
stage2 == stage3 (byte-equal)
BOOTSTRAP_STABILITY = PASS
STAGE3_CREATED      = NO   (per binding ACT §52)
FULL_SELF_HOST      = NO   (per truth boundary)
```

A fourth generation (`stage4`) would add no information
beyond what B3 already established. Per `AGENTS.md` P10
("no speculative machinery") and the user's board
decision, the next ACT must move **sideways from staging
into ownership expansion** rather than upward to another
generation.

The post-B3 self-hosting ratchet we actually want is:

```text
1 stable PolyC compiler component
       ↓
2
       ↓
3
       ↓
entire lexer
       ↓
parser
       ↓
frontend
       ↓
compiler
```

To grow that ratchet we need a registry-driven build
abstraction that does not require authoring one bespoke
stage recipe per migrated function. That abstraction does
not exist today; this ACT creates it without changing
compiler semantics.

References:

- `docs/ROADMAP.md` — "P4 bootstrap milestones (current
  status)" — B3 closed; no B4 planned.
- `evidence/ACT-POLYC-BOOTSTRAP04/HANDOFF.md` §"What comes
  next" — "the next ACT operation is board design."
- `docs/acts/ACT-POLYC-BOOTSTRAP04.md` §52 — hard stop
  on creating a stage4.

---
## Entry gate

```text
git branch --show-current = main
git status --short        = clean
git rev-parse HEAD        = 7d7b983686fac2239a47288fe4b8e5dbbb617d55
                           ACT-POLYC-BOOTSTRAP04 — CLOSE: B3 bootstrap stability PASS
```

Predecessor freeze:

```text
ACT-POLYC-BOOTSTRAP04 CLOSED PASS
  BOOTSTRAP_STABILITY_DOMAIN = CURRENT_SELF_HOSTED_COMPILER_COMPONENT
  S0 == S1 == S2 == S3 byte-equal
  Component differential 15/15 PASS
  Cursor model           6/6  PASS
  Production Lexer seam  6/6  PASS
  Broad corpus           175/175 byte-equal PASS
  Baseline failures      6/6  equivalent PASS
  Error corpus           4/4  equivalent PASS
  Reproducibility        Build A == Build B PASS
  STAGE3_CREATED         NO   (binding)
```

---

## Principal RED (mechanically established in C1)

The C1 RED for this ACT is recorded in
`evidence/ACT-POLYC-SELFHOST-SURFACE01/c1/`:

- `principal-red.txt` — the principal RED is the absence
  of a generic component registry and the bespoke nature
  of the per-generation wiring.
- `bespoke-wiring-inventory.tsv` — every reference to
  `bootstrap02-ident`, `bootstrap03-ident`,
  `bootstrap04-ident`, `HCC_ENABLE_BOOTSTRAP0N_STAGEn`,
  `BOOTSTRAP0N_IDENT_OBJECT`, classified by role.
- `build-graph-map.txt` — the bespoke build graph, before
  any generic abstraction.
- `semantic-vs-generation-coupling.txt` — where
  generation-specific macros leak into compiler semantics.
- `registry-red.txt` — what the registry would have to
  encode for `identifier_scanner`.
- `c1-required-result.txt` — binding C1 result block.
- `b3-predecessor-freeze.txt` — the predecessor PASS
  block re-stated as the C1 entry gate.

Negative control (binding):

```text
build/hcc-bootstrap05 = ABSENT
HCC_ENABLE_BOOTSTRAP05_STAGE4 = ABSENT
```

---

## Design choices (binding)

### Registry

```text
docs/factory/SELF-HOST-COMPONENTS.tsv
```

Schema:

```text
component_id
source
symbol
consumer_seam
language
state
oracle
cursor_gate
production_seam_gate
introduced_by
```

Initial row:

```text
identifier_scanner
tools/bootstrap/bootstrap02-ident.HC
BootstrapScanIdent
src/lexer.c::lexIdentifier
POLYC
STABLE
bootstrap02-ident-oracle
bootstrap02-cursor-test
bootstrap02-lexer-seam-test
ACT-POLYC-BOOTSTRAP02
```

The registry describes the **component**, not the
generation. The build graph describes the generation.

### Component identity vs stage identity

```text
component     = identifier_scanner
stage artifact = component(identifier_scanner, producer_stage=N)
```

Canonical generated paths:

```text
build/selfhost/stage0/identifier_scanner.o
build/selfhost/stage1/identifier_scanner.o
build/selfhost/stage2/identifier_scanner.o
```

Historical paths remain so that closed B1/B2/B3 evidence
remains reproducible:

```text
build/bootstrap02-ident.o
build/bootstrap03-ident.stage1.o
build/bootstrap04-ident.stage2.o
```
### Generic build operation

```text
BUILD_SELFHOST_COMPONENT(
    component_id,
    producer_stage,
    output_path
)
```

Driving example:

```sh
make selfhost-component-build \
  COMPONENT=identifier_scanner \
  STAGE=2
```

Produces:

```text
build/selfhost/stage2/identifier_scanner.o
```

Binding checks:

```text
correct producer compiler used
correct source used
expected exported symbol exists
output path deterministic
no fallback to prior-stage artifact
```

### Generic verification operation

```sh
make selfhost-component-test \
  COMPONENT=identifier_scanner \
  STAGE=2
```

Must reuse the proven oracle
(`bootstrap02-ident-oracle`,
`bootstrap02-cursor-test`,
`bootstrap02-lexer-seam-test`).

It must **not** create weaker generic tests.

### Consumer binding

Each registry row distinguishes:

```text
component source
component exported symbol
consumer seam
```

For `identifier_scanner`:

```text
source:
  tools/bootstrap/bootstrap02-ident.HC
symbol:
  BootstrapScanIdent
consumer:
  src/lexer.c::lexIdentifier
```

### Elimination of generation-specific semantic macros

End-state configuration shifts from:

```text
HCC_BOOTSTRAP02_STAGE1
HCC_BOOTSTRAP03_STAGE2
HCC_BOOTSTRAP04_STAGE3
```

to:

```text
HCC_SELFHOST_COMPONENTS=identifier_scanner[,...]
```

Meaning:

```text
compiler semantics depend on which components are enabled,
not on whether this happens to be "stage3".
```

Stage number belongs to artifact provenance.
Component selection belongs to compiler composition.

This separation is the most important architectural result
of the ACT.

### B3 chain preservation

Required targets continue to work:

```sh
make bootstrap02-stage1
make bootstrap03-stage2
make bootstrap04-stage3
```

Prefer implementing them as compatibility aliases over
the generic machinery where possible.

Required conservation:

```text
B1_OUTPUT_EQ_BEFORE_AFTER = PASS
B2_OUTPUT_EQ_BEFORE_AFTER = PASS
B3_OUTPUT_EQ_BEFORE_AFTER = PASS
```

### State model

```text
STABLE
MIGRATING
DISABLED
```

Initial:

```text
identifier_scanner = STABLE
```

Future ACTs may add a component as `MIGRATING` until its
oracle / corpus gates pass, then promote to `STABLE`.

No hidden "experimental but production-used" state.

### Generic provenance

Every generic component build emits or makes mechanically
derivable:

```text
component_id
source_path
producer_stage
producer_binary
producer_binary_hash
output_path
output_hash
expected_symbol
```
---

## Acceptance criteria

```text
AC01  docs/factory/SELF-HOST-COMPONENTS.tsv exists
AC02  registry schema mechanically validated
AC03  identifier_scanner registered exactly once
AC04  generic stage0 component build PASS
AC05  generic stage1 component build PASS
AC06  generic stage2 component build PASS
AC07  all three generic outputs export BootstrapScanIdent
AC08  provenance recorded for all three builds
AC09  component oracle 15/15 PASS
AC10  cursor oracle     6/6  PASS
AC11  production seam   6/6  PASS
AC12  bootstrap02-stage1 still PASS (compat alias)
AC13  bootstrap03-stage2 still PASS (compat alias)
AC14  bootstrap04-stage3 still PASS (compat alias)
AC15  generic vs historical artifact equivalence PASS
AC16  B3 corpus conservation PASS
AC17  B3 error-corpus conservation PASS
AC18  compiler semantic delta ZERO
AC19  no new compiler component migrated
AC20  no stage4 / no new generation
AC21  diff-check clean
AC22  Factory gates PASS
AC23  C2_TO_C3_GATE = OPEN
```

---

## Conservation gates

```text
make bootstrap02-test          # 15/15 + 6/6 + 6/6 PASS
make bootstrap03-test          # 15/15 + 6/6 + 6/6 PASS
make bootstrap04-test          # 15/15 + 6/6 + 6/6 PASS
make bootstrap04-cursor-test   # 6/6 PASS
make bootstrap04-lexer-seam-test  # 6/6 PASS
make unit-test                 # 90/90
make jit-unit-test             # 90/90
make lsp-test                  # 43/43
make gate-fast                 # PASS
sh scripts/quality/factory-v2-test.sh          # PASS 35/35
sh scripts/quality/factory-append-only-test.sh # PASS 11/11
sh scripts/quality/factory-halt-classification # PASS 12/12
sh scripts/quality/factory-closure-status      # PASS 6/6 pairs
sh scripts/quality/shell-loc-gate              # PASS
```

---

## HALT conditions

### `HALT_B3_PREDECESSOR_NOT_GREEN`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

Predecessor is not CLOSED PASS at entry.

### `HALT_COMPONENT_SEAM_NOT_REPRODUCIBLE`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

Existing identifier self-host cannot be mechanically
reconstructed via the generic path.

### `HALT_GENERIC_MODEL_REQUIRES_SEMANTIC_CHANGE`

```text
HALT_CLASS  = AUTHORIZATION
BLOCKS_NEXT = YES
```

Because this ACT is infrastructure-only.

### `HALT_REGISTRY_BESPOKE_FALLBACK`

```text
HALT_CLASS  = PRODUCTION
BLOCKS_NEXT = YES
```

A generic build secretly falls back to a prior-stage
artifact instead of compiling from the registry-resolved
source.

### `HALT_STAGE4_LITERAL_DETECTED`

```text
HALT_CLASS  = GOVERNANCE
BLOCKS_NEXT = YES
```

`build/hcc-bootstrap05` or
`HCC_ENABLE_BOOTSTRAP05_STAGE4` literal appears in the
ACT's implementation.

---
## Residue (predeclared)

```text
P0 : NONE
P1 : NONE
P2 : Carry forward the existing carried residue from
     BOOTSTRAP0[1-4]:
       - unit/jit runner (AOT codegen adrp/add vs dylib
         nreloc=0 collision)
       - GEP01 push cap-verifier 26/4
       - historical whitespace / blank-at-EOF hygiene
```

---

## Execution metadata

Execution identity is stored in Git commit trailers.

Every ACT commit:

```text
ACT: ACT-POLYC-SELFHOST-SURFACE01
ACT-Phase: RED|IMPL|EVIDENCE|CLOSE
```

CLOSE additionally:

```text
ACT-Verdict: PASS
```

The original authorization artifact remains historically
stable; there is no OPEN -> PASS mutation.

The ACT document is **NOT** modified at closure.
Closure happens via the CLOSE commit's `ACT-Verdict`
trailer.

---

## Closure handoff

Use the Factory v2 HANDOFF template at
`docs/factory/HANDOFF-TEMPLATE.md` (Factory v2 section).

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-SURFACE01 HEAD
```

---

## Roadmap transition (anticipated at CLOSE)

```text
BOOTSTRAP FOUNDATION
  B0 COMPILER-SHAPED          GREEN
  B1 PARTIAL SELF-HOST        GREEN
  B2 FIRST SELF-HOST          GREEN
  B3 BOOTSTRAP STABILITY      GREEN
  FOUNDATION                  COMPLETE

SELF-HOST EXPANSION
  S0 COMPONENT FRAMEWORK      ACT-POLYC-SELFHOST-SURFACE01
  S1 PRODUCTION LEXER         LOCKED
  S2 PARSER                   LOCKED
  S3 FRONTEND                 LOCKED
  S4 FULL COMPILER            LOCKED
```

---

## What immediately follows this ACT (anticipated)

If this ACT closes PASS, the next ACT is:

```text
ACT-POLYC-SELFHOST-LEXER01
```

Its mission should be **inventory and migrate the next
coherent production lexer slice**. The slice should be
chosen mechanically from the actual lexer seam map, not
by intuition:

```text
candidate categories:
  whitespace / comments
  numbers
  strings / chars
  operators / punctuation
  keywords
```

`SELFHOST-LEXER01` C1 should measure:

```text
host-C lexer functions
call graph
state mutated
token types produced
existing test coverage
ABI complexity
candidate migration size
```

and rank the next component.
