ACT-POLYC-SELFHOST-SURFACE01 — HANDOFF
=======================================

VERDICT: PASS

The C4 CLOSE commit's `ACT-Verdict` trailer is the
authoritative verdict; this document is descriptive.

Identity
--------

Branch:     main
C1 entry:   3289b36
C1.1:       00dbfd4
C2 IMPL:    22ba1d1
C2 EVID:    3a101db
C3 EVID:    f2ca6ee
C4 CLOSE:   authoritative CLOSE commit (no SHA-of-self)

Mission
-------

Replace the bespoke B1/B2/B3 component plumbing with one
mechanically-defined self-host component model so that
subsequent ACTs can migrate the rest of the production
Lexer without authoring a new stage-N recipe per function.

Outcome
-------

```text
SELF_HOST_COMPONENT_MODEL     = PASS
SELF_HOST_COMPONENT_REGISTRY  = PASS
REGISTERED_COMPONENT_COUNT    = 1
IDENTIFIER_SCANNER_STATE      = STABLE

GENERIC_STAGE0_BUILD          = PASS
GENERIC_STAGE1_BUILD          = PASS
GENERIC_STAGE2_BUILD          = PASS
GENERIC_PROVENANCE            = PASS
GENERIC_RECONSTRUCTION        = PASS
GENERIC_SURFACE_INDEPENDENT_OF_BESPOKE_PRODUCERS = YES

HISTORICAL_BOOTSTRAP_COMPATIBILITY  = PASS
B1_RECONSTRUCTION                   = PASS
B2_RECONSTRUCTION                   = PASS
B3_RECONSTRUCTION                   = PASS

GENERIC_HISTORICAL_ARTIFACT_EQ      = PASS_3_OF_3
  G0 == S0  YES
  G1 == S1  YES
  G2 == S2  YES

B3_CORPUS_CONSERVATION              = PASS
  175/175 byte-equal
  6/6 FAIL/FAIL equivalent
  0 divergence
B3_ERROR_CONSERVATION               = PASS
  4/4 equivalent
  0 mismatch

GENERATION_SPECIFIC_BUILD_WIRING    = GENERICIZED_FOR_COMPONENT_PRODUCTION
GENERATION_SPECIFIC_SOURCE_SELECTOR = PRESERVED
SEMANTIC_SELECTOR_GENERICIZATION    = DEFERRED

COMPILER_SEMANTIC_DELTA             = ZERO
NEW_COMPILER_COMPONENT_MIGRATED     = NO
NEW_BOOTSTRAP_STAGE                 = NO

FULL_SELF_HOST                      = NO
NEXT_COMPONENT_MIGRATION_READY      = YES
P0_BLOCKERS                         = NONE
```

What this ACT deliberately does NOT solve
----------------------------------------

```text
SOURCE-LEVEL COMPONENT SELECTION =
  still implemented using the existing B1 compile-time selector
  #ifdef HCC_BOOTSTRAP02_STAGE1 in src/lexer.c::lexIdentifier

WHY:
  only one self-hosted component exists today;
  genericizing source composition now would be speculative.

OWNER:
  first multi-component lexer migration ACT,
  if and only if the second component demonstrates the need.
```

This is an important design success, not unfinished C2 work.
The architectural defect identified in the original C1
build-graph wiring is fully genericized. The source-level
selector is preserved by design (see C1.1 amendment).

What is now possible
--------------------

With `docs/factory/SELF-HOST-COMPONENTS.tsv` and the
generic `selfhost-component-build` / `selfhost-component-test`
operations in place, the next migration ACT can:

  1. Add a new data row to the registry.
  2. Run `make selfhost-component-build COMPONENT=<id> STAGE=N`
     for any N in {0, 1, 2}.
  3. Run `make selfhost-component-test COMPONENT=<id> STAGE=N`
     to invoke the registered oracle/cursor/production_seam gates.

No new Makefile/CMake plumbing is required per component.
The registry validator ensures each new row is well-formed.

New files added by this ACT
----------------------------

  docs/factory/SELF-HOST-COMPONENTS.tsv
  scripts/quality/selfhost-component-registry.py
  scripts/quality/selfhost-component-registry-test.sh
  tools/selfhost/selfhost-component.sh
  Makefile                                    (+28 lines)

Modified files
--------------

  Makefile                                    (.PHONY + 3 targets)
  docs/ROADMAP.md                             (S0 → GREEN)

Untouched (binding):
  src/lexer.c                                 (selector frozen)
  src/lexer_bridge.h                          (ABI frozen)
  tools/bootstrap/bootstrap02-ident.HC        (B1 source frozen)
  src/CMakeLists.txt                          (build plumbing frozen)

Next ACT
--------

ACT-POLYC-SELFHOST-LEXER01 — will inventory and rank
candidate lexer-function slices mechanically, then pick
the first to migrate. See ACT §43 for the candidate
classification axes.

Hard stop
---------

```text
STOP.
```

Do not migrate the next lexer function in this ACT.
Do not create a second registry row for a real component.
Do not modify the source selector.
Do not introduce stage4.

The next operation is the new ACT:
ACT-POLYC-SELFHOST-LEXER01.
