ACT-POLYC-BOOTSTRAP03 — C1 — RED packet README
==============================================

C1 establishes that the B1 predecessor (ACT-POLYC-BOOTSTRAP02)
is GREEN, that the stage1 self-host edge is mechanically
demonstrated, that no canonical stage2 currently exists, and
that the self-host loop is therefore **OPEN**.

## Contents

```text
predecessor-freeze.txt       Re-establishes B1 closure truth
                             from executable evidence on the
                             current tree.

b1-governance-residue.txt    Carries forward the three
                             C1-CORRECTION01 descriptive
                             fields omitted from B1
                             closure prose
                             (B1_ASCII_DOMAIN,
                              B1_NON_ASCII_EQUIVALENCE,
                              B1_REFERENCE_MODEL_ORACLE).

stage-identity.txt           Captures stage0 / stage1
                             identity: path, size, SHA-256,
                             presence/absence of
                             _BootstrapScanIdent.

stage1-self-compile.txt      Proves stage1 (hcc-bootstrap02)
                             can compile the B1 PolyC
                             source and exports
                             _BootstrapScanIdent.

stage2-absence.txt           Proves no canonical stage2
                             binary exists; no bootstrap03
                             reference in any build file.

build-seam-map.txt           Maps the existing B1 build
                             seam (Makefile + CMakeLists.txt)
                             and identifies the parameter that
                             must change to wire a stage2
                             build.

principal-red.txt            Captures the principal RED:
                             the artifact produced by stage1
                             has not been consumed to
                             construct a successor stage.

c1-required-result.txt       The required-result block
                             ending with the binding
                             C1 predicate.
```

## Binding summary

```text
B1_PREDECESSOR_GREEN        = YES
STAGE1_SELF_SOURCE_COMPILE  = PASS
STAGE2_EXISTS               = NO
FIRST_SELF_HOST_EDGE        = OPEN
C1_TO_C2_GATE               = OPEN
```

No production mutation in C1.
