ACT-POLYC-BOOTSTRAP03 — C2 — IMPL packet README
==============================================

C2 implements the canonical stage1 → stage2 artifact flow.
Three build targets are added; one CMake option is added.

## Files changed

```text
Makefile             .PHONY added 3 targets (bootstrap03-*);
                     appended 3 new targets at the bottom:
                       bootstrap03-component-build
                       bootstrap03-stage2
                       bootstrap03-test

src/CMakeLists.txt   Added HCC_ENABLE_BOOTSTRAP03_STAGE2 option
                     (default OFF; mirrors the B1 pattern);
                     when ON, builds hcc-bootstrap03 linked
                     against BOOTSTRAP03_IDENT_OBJECT.
```

No production source files changed. No B1 source files
changed. No `tools/bootstrap/bootstrap02-ident.HC`
modifications. No `src/lexer.c` modifications.

## Build graph added

```text
make bootstrap03-component-build
  build/hcc-bootstrap02 (stage1)
      |
      | -c tools/bootstrap/bootstrap02-ident.HC
      | -o build/bootstrap03-ident.stage1.o
      v
  build/bootstrap03-ident.stage1.o
  (sha256 = a1b620c0...78cd854f, _BootstrapScanIdent exported)


make bootstrap03-stage2
  ordinary compiler objects (incl. src/lexer.c with the
  existing #ifdef HCC_BOOTSTRAP02_STAGE1 dispatch, now
  additionally gated by HCC_BOOTSTRAP03_STAGE2)
      +
  build/bootstrap03-ident.stage1.o   <-- the stage1-produced B1 object
      |
      v
  build/hcc-bootstrap03 (stage2)
  (sha256 = f885d612...00ec1ac, _BootstrapScanIdent exported)


make bootstrap03-test
  links build/bootstrap03-ident.stage1.o into the host
  harness; runs 15-fixture differential against the
  same C reference oracle as B1.
  BOOTSTRAP03_DIFFERENTIAL = PASS 15/15
```

## Binding result

```text
STAGE1_B1_ARTIFACT_CREATED    = YES  (build/bootstrap03-ident.stage1.o)
STAGE2_CREATED                = YES  (build/hcc-bootstrap03)
STAGE2_LINKS_STAGE1_B1_ARTIFACT = YES  (-DBOOTSTRAP03_IDENT_OBJECT=...)
STAGE2_USES_B1_COMPONENT      = YES  (lexIdentifier dispatches to it)
C2_TO_C3_GATE                 = OPEN
```
