# ACT-POLYC-BOOTSTRAP04 — C2 — IMPL

This directory contains the C2 IMPL evidence for
`ACT-POLYC-BOOTSTRAP04` (B3 bootstrap stability).

C2 adds exactly the stage2→stage3 build edge:

- `HCC_ENABLE_BOOTSTRAP04_STAGE3` opt-in CMake option
  (`src/CMakeLists.txt`)
- `bootstrap04-component-build` Makefile target
  (uses `./build/hcc-bootstrap03` to produce
  `build/bootstrap04-ident.stage2.o`)
- `bootstrap04-stage3` Makefile target (produces
  `build/hcc-bootstrap04` linked against the S2 B1 object)
- `bootstrap04-test` Makefile target (component
  differential against B1 oracle)
- `bootstrap04-cursor-test` Makefile target (cursor
  model 6/6 against B1 cursor oracle)
- `bootstrap04-lexer-seam-test` Makefile target
  (production Lexer seam 6/6 stage2↔stage3)

No compiler semantic files were modified in C2. Only
build-graph extension.

Files in this packet:

- `implementation-delta.txt`        — files changed
- `stage2-component-build.txt`      — S2 artifact created
- `stage3-link.txt`                 — hcc-bootstrap04 produced
- `artifact-provenance.txt`         — provenance witness
- `stage3-symbol-binding.txt`       — `_BootstrapScanIdent` present in stage3
- `stage3-disassembly-binding.txt`  — `bl _BootstrapScanIdent` sites
- `b0-b1-b2-conservation.txt`       — predecessor gates re-run
- `c2-required-result.txt`          — binding C2 end block
