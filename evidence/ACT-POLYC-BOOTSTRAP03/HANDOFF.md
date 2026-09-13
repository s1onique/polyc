# ACT-POLYC-BOOTSTRAP03 — HANDOFF

**Title:** B2 first self-host — stage1-produced PolyC compiler
component consumed by stage2.

**Status:** CLOSED PASS.

**Verdict:** `PASS`. `FIRST_SELF_HOST = YES`. `FULL_SELF_HOST = NO`.

## What B2 proved

B2 established the **first mechanically demonstrated
self-host cycle** in PolyC:

```text
stage1 compiler (hcc-bootstrap02)
    compiles tools/bootstrap/bootstrap02-ident.HC  (PolyC)
        ->
stage1-produced component object (build/bootstrap03-ident.stage1.o)
    is linked into stage2 compiler (hcc-bootstrap03)
        ->
stage2 compiler
    actually calls the B1 component in lexIdentifier
        ->
stage2 reproduces the proven compiler behaviour
```

This closes the loop for the first time:

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

## Why B2 is genuinely the first self-host edge (not B1++)

B1 proved that PolyC code can live inside the compiler
(stage1's lexIdentifier delegates to BootstrapScanIdent
compiled by stage0). B2 proves that the compiler
**containing** that PolyC code can compile that same
PolyC compiler code for its **successor**, and the
successor actually consumes it.

The structural guarantee is:

```text
stage1 -> build/bootstrap03-ident.stage1.o
stage2 -> target_link_libraries(hcc-bootstrap03
            ${BOOTSTRAP03_IDENT_OBJECT} m)
```

with `${BOOTSTRAP03_IDENT_OBJECT}` resolved at CMake
configure time to the stage1-produced object. The
distinct path (`build/bootstrap03-ident.stage1.o`)
makes accidental reuse of the stage0-produced object
impossible. The producer/consumer link is recorded in
the build graph, not in any hash coincidence.

## Build graph added

```text
make bootstrap03-component-build
  -> build/bootstrap03-ident.stage1.o   (built by stage1)

make bootstrap03-stage2
  -> build/hcc-bootstrap03              (links the stage1 object)

make bootstrap03-test
  -> BOOTSTRAP03_DIFFERENTIAL = PASS 15/15

make bootstrap03-lexer-seam-test
  -> BOOTSTRAP03_LEXER_SEAM_DOWNSTREAM = PASS (6/6)
```

## Files modified by B2

```text
Makefile                     (added 4 .PHONY targets + recipes)
src/CMakeLists.txt           (added HCC_ENABLE_BOOTSTRAP03_STAGE2)
docs/ROADMAP.md              (transitioned B2 -> GREEN, B3 -> UNLOCKED)
docs/acts/ACT-POLYC-BOOTSTRAP03.md  (the B2 ACT document)
tools/quality/bootstrap03-corpus-runner.py  (test-only)
tools/quality/bootstrap03-error-corpus.py  (test-only)
evidence/ACT-POLYC-BOOTSTRAP03/    (textual evidence)
```

Production source delta: **ZERO**. No `src/*.c`, no
`src/*.h`, no `tools/bootstrap/bootstrap02-ident.HC`,
no `src/lexer.c`, no `src/lexer_bridge.h` modifications.

## Numbers

```text
B0                         15/15
B1 component differential  15/15
B1 cursor                   6/6
B1 production Lexer seam    6/6
B2 component differential  15/15
B2 cursor                   6/6
B2 production Lexer seam    6/6
B2 stage1↔stage2 corpus   175/175 byte-identical
B2 error corpus            4/4 equivalent
LSP                        43/43
factory-v2-test            35/35
factory-append-only-test   11/11
factory-halt-class-test    12/12
factory-closure-status      6/6
shell-loc-gate             PASS
gate-fast                  PASS

Reproducibility           PASS  (Build A == Build B)

All conservation gates PASS.
All Factory gates PASS.
```

## Truth boundary

```text
FIRST_SELF_HOST         = YES
FULL_SELF_HOST          = NO   (host-C still dominates the compiler)
HOST_C_DEPENDENCY       = PRESENT
BOOTSTRAP_STABILITY     = NOT_YET  (B3 next)
STAGE3_CREATED          = NO
```

## Residue

```text
P0_BLOCKERS             = NONE
P1_RESIDUE              = NONE  (within B2 scope)
P2_RESIDUE              = CARRIED FROM PRIOR ACTs:
                          - unit-test / jit-unit-test runner false-green
                          - GEP01/push residue
                          - historical evidence whitespace
                          - B1 closure-prose omissions (carried into C1)
                          - B1 reference-model byte-equivalent = NO
PUSH_RESIDUE            = GEP01_D1_D2 (pre-existing, non-blocking)
```

All carried residue is non-blocking per F-MECHANICAL-BLOCKING.

## Card-1 invariant

Exactly one CLOSE commit for ACT-POLYC-BOOTSTRAP03:
this commit (the C4 CLOSE trailer carrier).

```text
$ git log --all-match --oneline \
    --grep='^ACT: ACT-POLYC-BOOTSTRAP03$' \
    --grep='^ACT-Phase: CLOSE$'
<the C4 CLOSE commit only>
```

## What is forbidden after this ACT CLOSE

Per ACT §44:

```text
Do NOT:
  - build stage3
  - open B3
  - migrate another subsystem
  - repair unit/jit
  - repair GEP01
  - clean historical evidence
  - push unless independently authorized
```

STOP.

## What's next (B3)

B3 is now UNLOCKED. The recommended next ACT is
`ACT-POLYC-BOOTSTRAP04` (or equivalent bounded B3 ACT):
construct stage3 by repeating the stage1→stage2 artifact
flow, then prove stage2 ≈ stage3 over the binding
comparison domain (component, direct, corpus, error,
self-source). This is the GCC-style "later-stage
comparison" closing the bootstrap-stability milestone.

## Pointers

```text
ACT document:          docs/acts/ACT-POLYC-BOOTSTRAP03.md
C1 RED packet:         evidence/ACT-POLYC-BOOTSTRAP03/c1/
C2 IMPL packet:        evidence/ACT-POLYC-BOOTSTRAP02/c2/
C3 EVIDENCE packet:    evidence/ACT-POLYC-BOOTSTRAP03/c3/
C4 CLOSE packet:       evidence/ACT-POLYC-BOOTSTRAP03/c4/
Closure summary:       evidence/ACT-POLYC-BOOTSTRAP03/c4/closure-summary.txt
Acceptance matrix:     evidence/ACT-POLYC-BOOTSTRAP03/c4/acceptance-matrix.txt
Residue:               evidence/ACT-POLYC-BOOTSTRAP03/c4/residue.txt
ROADMAP transition:    evidence/ACT-POLYC-BOOTSTRAP03/c4/roadmap-transition.txt
```

## Final report

```text
VERDICT: PASS

ACT-POLYC-BOOTSTRAP03 is CLOSED.

B0:  GREEN
B1:  GREEN
B2 FIRST SELF-HOST: PASS

Self-host chain:
  PolyC B1 source
    -> compiled by stage1
    -> exact stage1 object consumed by stage2
    -> stage2 links and executes B1 component

Artifact provenance:  PASS
Stage2 binding:       PASS
Direct equivalence:    PASS
Stage1/stage2 corpus: PASS  (divergences = 0)
Stage2 self-source:   PASS
Stage1/stage2 B1 obj: equivalent
Reproducibility:       PASS
B0/B1 conservation:   PASS

FIRST_SELF_HOST:      YES
FULL_SELF_HOST:       NO
BOOTSTRAP_STABILITY:  NOT_YET

ROADMAP:
  B0 GREEN
  B1 GREEN
  B2 GREEN
  B3 UNLOCKED / NEXT

P0: NONE
```
