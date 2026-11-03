# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Class:** IMPLEMENTATION / SELFHOST / WP-001 / PRODUCTION-SEMANTIC-AUTHORITY / BOUNDED CORRECTION

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02
(its production source and immutable historical evidence are the baseline)

**Production semantic changes:** AUTHORIZED (scoped) -- emission-option
selection precedence in the PolyC-owned required compiler-producing route.

**IR / ABI / LLVM authorization:** NONE.

---

## Mission

Correct the PolyC-owned emission-selection decision so that the real C-only
compiler and the real selector-ON PolyC compiler select the same artifact
class for every frozen emission-option combination, independent of argv
order. The complete precedence rules SHALL be derived from the C-only
production compiler rather than hardcoded to the known `-c -S` case. The
implementation SHALL remain PolyC-owned and SHALL NOT return semantic
authority to C.

## Why

An independent production review falsified CORRECTION02's claimed
`PASS_PRECEDENCE_RESTORED_WITH_ROUTE_REMAINDER`. In fresh isolated builds,
`-c -S`, `-c -c -S`, and `-S -c -S` select an assembly artifact under the
PolyC selector but an object artifact under the C oracle. The defect is
visible in `WpDriverSelectedEmission()`: the selected emission is overwritten
as options are scanned, so the last recognized emission option wins despite
the documented object-emission priority.

CORRECTION02's genuine improvements to PolyC-owned `-o-` handling and
invalid-status fail-closed behavior remain conserved. Its frozen evidence and
acceptance ledgers remain immutable historical findings; this ACT does not
repair or endorse them.

## Execution phases

### C0 RED

Reproduce all eight required flag cases against fresh isolated selector-OFF
and selector-ON production builds. The mandatory witness is `-c -S`; it may
not be replaced by an `-o-` fixture. Freeze exact source and artifact
identities for both builds and the observed exit, stdout, stderr, artifact
class, and artifact bytes. The RED must fail because of the artifact-class
mismatch, not because of a build or fixture error.

### C1 EVIDENCE

Derive the complete object, assembly, library, and default precedence rules
from the C-only production compiler. Freeze a comprehensive flag matrix and
the comparator contract before implementation. Every valid emission status
must have observed dispatch behavior; a declared status alone is insufficient.

### C2 IMPL

Correct `WpDriverSelectedEmission()` with the minimum scoped production
change that preserves the C oracle's complete precedence rules. The C oracle
source SHALL remain byte-identical and independent. The PolyC driver SHALL
remain the semantic owner of the selected emission.

### C3 EVIDENCE

Measure fresh G0/ON equivalence across the frozen matrix, a discriminating
PolyC causal mutation, C-policy dormancy, artifact and regression comparisons,
and independent Codex review. The comparator SHALL check exit, stdout,
stderr, artifact class, actual artifact bytes, architecture, and symbols;
link/run behavior SHALL be checked where applicable. A fresh gate failure
SHALL be recorded as a failure until its retry or environmental classification
is independently demonstrated.

### C4 CLOSE

C4 is permitted only after every new mandatory semantic obligation passes
and the independent Codex review has no unresolved substantive P0/P1 finding.
The closure verdict SHALL NOT claim whole-CLI ownership, WP-001 completion,
M2 self-hosting, or evidence reconciliation.

## Scope

### allowed

- `docs/acts/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03.md`
- `tools/bootstrap/selfhost-driver-wp001.HC`
- `tools/quality/driver-required-route-correction03-*.HC`
- `tests/driver-wp001/required-route/` fixtures required by the frozen
  emission matrix
- `Makefile` only as needed to bind the CORRECTION03 RED and GREEN checks
- `evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/`
- the Factory v2 HANDOFF and ACT bookkeeping required for this ACT

### forbidden

- modifying the C-only oracle implementation or its source bytes
- changing CORRECTION02's frozen evidence, acceptance ledgers, predictions,
  generation matrix, or NC17 record
- repairing the 15 contradicted and three unproven CORRECTION02 criteria
- changing the PolyC/C status ABI, IR, LLVM backend, parser, AST, linker,
  language semantics, or whole-CLI behavior
- adding dependencies, changing CI/framework/container behavior, or weakening
  existing tests or quality gates
- claiming strict M2 self-hosting, WP-002 authorization, WP-001 completion, or
  whole-CLI compiler ownership

## Principal RED

The RED SHALL use two fresh isolated production builds: the selector OFF
build as the independent C oracle and the selector ON build as the PolyC
production compiler. It SHALL invoke the mandatory matrix:

## Acceptance criteria

- **AC01** -- A fresh selector-OFF and selector-ON production-build pair is
  recorded with exact source, executable, and fixture identities; the C oracle
  source is byte-identical to the entry source.
- **AC02** -- The mandatory eight-case matrix is reproduced through the real
  production compilers, and the pre-C2 `-c -S` RED is recorded as an artifact
  mismatch with successful compiler exits.
- **AC03** -- The C1 precedence table is derived from source plus observed
  C-only behavior for object, assembly, library, and default routes and is
  frozen independently of the implementation change.
- **AC04** -- The selector-ON compiler selects the same artifact class as the
  selector-OFF compiler for every frozen matrix case after C2, with no
  last-option-wins discrepancy.
- **AC05** -- The comparator checks exit, stdout, stderr, artifact class,
  actual bytes, architecture, and symbols; applicable linked artifacts also
  pass link/run checks.
- **AC06** -- A discriminating mutation of the PolyC emission decision
  changes the selector-ON observable outcome while the selector-OFF oracle is
  unchanged, proving that PolyC owns the decision.
- **AC07** -- Mutating the relevant legacy C emission policy does not change
  selector-ON outcomes for the frozen matrix, proving C-policy dormancy.
- **AC08** -- All valid selected-emission statuses have observed dispatch
  behavior, and an invalid status still fails closed with no artifact or
  fallback.
- **AC09** -- The existing driver required-route, precedence, fail-closed,
  and production-consumption checks remain green.
- **AC10** -- Fresh `gate-fast` and `gate-push` are run against the exact
  closure subject; an intermittent failure remains a failure unless its
  environmental classification is independently demonstrated.
- **AC11** -- An independent Codex review is run against the fresh production
  evidence before C4 and reports no unresolved substantive P0/P1 finding.
- **AC12** -- No acceptance criterion passes through a declared status alone;
  missing or unobserved evidence is classified as unresolved and fails closed.

## Conservation gates

- `make driver-wp001-required-route-test`
- `make driver-wp001-precedence-test`
- the CORRECTION03 production equivalence check
- `make gate-fast`
- `make gate-push`

Any failure is evidence. Tests SHALL NOT be weakened to obtain PASS.

## HALT conditions

- `HALT_RED_NOT_REPRODUCED` -- the mandatory real-seam `-c -S` artifact
  mismatch cannot be reproduced before C2.
- `HALT_SCOPE_EXPANSION_REQUIRED` -- completion requires edits outside the
  allowed scope.
- `HALT_DEPENDENCY_UNAVAILABLE` -- a required toolchain or independent review
  harness is unavailable and no silent fallback is permitted.
- `HALT_SEMANTIC_EVIDENCE_INCOMPLETE` -- mandatory evidence cannot be
  independently established.

## Residue

- **P1** -- CORRECTION02's contradictory frozen predictions, generation
  matrix, NC17 conflict, and acceptance ledgers require a separate evidence
  reconciliation ACT after this production correction.
- **P1** -- Whole-CLI compiler ownership remains incomplete and out of scope.
- **P2** -- A reusable evidence verifier distinguishing PASS, FAIL,
  UNRESOLVED, and UNSUPPORTED is deferred to the evidence-reconciliation ACT.

## Execution metadata

Execution identity is stored in Git commit trailers. Every commit MUST carry:

```text
ACT: ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03
ACT-Phase: RED|IMPL|EVIDENCE|CLOSE
```

The CLOSE commit additionally carries `ACT-Verdict`. The original
authorization artifact remains historically stable; it is not updated to
claim PASS or HALT.

## Closure handoff

Use `docs/factory/HANDOFF-TEMPLATE.md`. Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03 HEAD
```
