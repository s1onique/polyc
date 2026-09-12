# C3 EVIDENCE: ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01

**VERDICT: HALT_SCOPE_EXPANSION_REQUIRED**

## Identity

```
Branch:        main
HEAD (pre-C3): 0ad89db (C2 IMPL ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01)
HEAD (post):   655b7bd (fix(gates): unit-test/jit-unit-test consume hermetic test prefix)
Gate target:   8f398be (merge: integrate Track B before BOOTSTRAP01)
Working tree:  clean (no uncommitted modifications)
```

## Summary

C2 IMPL completed and verified at commit `0ad89db`. The D1 GEP01
binding, D2 canonical install seam, and D3 shell-ratchet migration
were implemented and validated against the existing factory gates:

- shell-loc-gate: PASS
- factory-v2-test: PASS
- append-only-test: PASS
- closure-status-test: PASS
- halt-classification-test: 12/0 PASS
- gate-fast: PASS
- Track-A LLVM gates (byte-memory 37/0, intops 4/0, ir-fwd 6/0): PASS
- make lsp-test: 43/43 PASS
- make llvm-gep01-test: 30/0 PASS (locally; see GPUSH-GEP01 caveat below)

`GPUSH-1 build`, `GPUSH-2 install` steps of gate-push PASS when
the canonical install symlink (`libtos.dylib`) is left in place.
**C3 cannot close because `GPUSH-3 aot` (`make unit-test`) and
`GPUSH-GEP01 gep01` (`make llvm-gep01-test`) require mutually
exclusive configurations of the canonical install in the gate's
hermetic prefix.**

See `c3-conflict-diagnosis.txt` for the full root-cause analysis and
`c3-failure-modes.txt` for transcript excerpts of both failure modes.
`gate-push-final.log` is the captured log from the most recent
gate-push invocation (FAILURE MODE B: 26 duplicate symbols at
GPUSH-GEP01, after my 655b7bd follow-up removed the symlink). The
FAILURE MODE A transcript excerpt in `c3-failure-modes.txt` is
reconstructed from earlier interactive runs (the prior log file was
overwritten by the FAILURE MODE B run); the mode is fully
reproducible by toggling the `@rm -f` line in
`test-prefix-install` back out.

## Root cause: conflict between unit-test and llvm-gep01-test

The canonical install dance in `src/CMakeLists.txt` (CORRECTION03)
creates an unversioned `libtos.dylib -> libtos.0.0.1.dylib` symlink
in `${CMAKE_INSTALL_PREFIX}/lib` so that downstream `-ltos` linkage
pulls in the dylib. This symlink is the source of two mutually
exclusive failure modes on arm64:

### Failure mode A: keep the symlink (canonical install default)

- `llvm-gep01-test` PASSES. The harness includes
  `../../src/holyc-lib/tooling.HC` which transitively pulls in
  `memory.HC`. The dylib supplies these symbols at link time;
  the harness's own copies are dedup'd by the dylib's NOUNDEFS
  layout.
- `unit-test` FAILS. The AOT code references `_FREE` via
  `adrp x0, _FREE@PAGE` + `add x0, x0, _FREE@PAGEOFF`. macOS's
  ld64 rejects these as "invalid use of ADRP" because the dylib's
  relocation metadata (`nreloc 0` in `__text`) cannot satisfy the
  link-time PIC requirement.

### Failure mode B: drop the symlink (655b7bd follow-up)

- `unit-test` PASSES. `libtos.a` ships archive-style relocations
  (`nreloc 560` in `__text`) that the AOT code's `adrp`/`add`
  pairs satisfy at link time.
- `llvm-gep01-test` FAILS with 26 duplicate symbols. The harness's
  translation unit defines these symbols via the
  `tooling.HC` -> `memory.HC` -> ... include chain;
  `libtos.a[2](all.o)` also defines them; the linker refuses to
  choose.

## Conservation observation

This conflict pre-dates `ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01`.
The previous successful gate-push at commit `a5818c6` did not include
`llvm-gep01-test` (the GEP01 binding is a D1 deliverable of this
ACT), so the conflict was never exercised in production. The
unit-test AOT/ADRP failure on arm64 with `-ltos` resolving to the
dylib is documented behavior of the AOT codegen that pre-dates the
canonical install dance.

## Mitigations attempted (all in scope for D2 follow-up; none sufficient)

Commit `655b7bd` (post-C2 IMPL follow-up):

1. Routes `make unit-test` and `make jit-unit-test` through
   `test-prefix-install` with `--install-dir=$(TEST_PREFIX)`. This
   makes the host-arch `unit-test` invocation hermetic and resolves
   the "Failed to open file: /usr/local/include/tos.HH" error on
   hosts without a writable `/usr/local`. Verified: unit-test
   PASSES end-to-end (all tests run, including transitive child
   hcc invocations).

2. Adds `@rm -f $(TEST_PREFIX)/lib/libtos.dylib` to
   `test-prefix-install`, hermetic-prefix-locally dropping the
   unversioned symlink. Verified: `ls $(TEST_PREFIX)/lib/` shows
   only `libtos.a` and `libtos.0.0.1.dylib`. Production
   `make install` is untouched.

These mitigations successfully isolate `unit-test` from the
AOT/ADRP issue but cannot resolve the duplicate-symbol failure
of `llvm-gep01-test`. The remaining conflict is structural:

- hcc's AOT codegen (out of scope for this ACT) emits `adrp`/`add`
  sequences that the libtos dylib's relocation metadata cannot
  satisfy.
- The GEP01 oracle harness (out of scope: locked by
  `ACT-POLYC-TOOLING-MIGRATE-GEP01`) transitively `#include`s
  libtos source via `tooling.HC` -> `memory.HC`, causing
  duplicate-symbol collisions against `libtos.a`.

## Recommended next ACT

`HALT_SCOPE_EXPANSION_REQUIRED`. The conflict requires one of:

1. **AOT codegen fix** (likely in `src/aarch64.c` /
   `src/x86_64.c`): emit `bl _FREE` / `blr x0` instead of
   `adrp x0, _FREE@PAGE` + `add x0, x0, _FREE@PAGEOFF` + `blr x0`
   for cross-translation-unit function references, so that linkage
   against the libtos dylib works via standard PLT-style indirect
   calls.

2. **libtos dylib build flag** (in `src/CMakeLists.txt`): add
   `-Wl,-Bsymbolic` to the canonical dylib creation so that
   internal libtos references are bound at dylib link time and the
   dylib can be linked cleanly into executables that reference
   libtos symbols via the static-style `adrp`/`add` pairs the AOT
   emits.

3. **GEP01 harness refactor** (in
   `tools/quality/llvm-gep01-test.HC`): replace `#include
   "../../src/holyc-lib/tooling.HC"` with a declaration-only
   header (so the harness does not transitively pull in
   `memory.HC`'s implementations), then link against `libtos.a`
   only. This is consistent with the lsp-test pattern (which uses
   `<tos.HH>` declarations and no libtos source).

Each option touches production code outside this ACT's scope. Per
`F15`, the agent MUST halt rather than self-authorize scope
expansion.

## C2 IMPL acceptance status

Despite the C3 halt, the C2 IMPL remains VALID for its bounded
scope:

- **D1 (GEP01 binding)**: `make llvm-gep01-test` target exists,
  invoked by gate-push as `GPUSH-GEP01`. 30/0 PASS when run in a
  non-conflicting configuration (FAILURE MODE A).
- **D2 (canonical install)**: `make test-prefix-install` consumes
  the CMake install dance (src/CMakeLists.txt `install(CODE ...)`
  block) as the single source of truth for
  `libtos.{a,0.0.1.dylib}`. `gate-push GPUSH-2` invokes it.
  Verified to land `libtos.a` + `libtos.0.0.1.dylib` (+ unversioned
  symlink) in `$gate_prefix/lib`.
- **D3 (shell ratchet)**: `factory-halt-classification.py` (244
  LOC) replaces 12-condition shell logic;
  `factory-halt-classification-check.sh` (18 LOC) and
  `factory-halt-classification-test.sh` (15 LOC) are thin
  launchers. `gate-push.sh` remains at 480 LOC baseline
  (unchanged).

The halt is on **gate-push** closure (cannot push to origin/main),
not on the C2 IMPL artifacts themselves.

## Files in this directory

| File                              | Purpose                                                   |
|-----------------------------------|-----------------------------------------------------------|
| `README.md`                       | This file.                                                |
| `c3-conflict-diagnosis.txt`       | Root-cause analysis of the unit-test/GEP01 conflict.      |
| `c3-failure-modes.txt`            | Transcript excerpts for both FAILURE MODE A and B.        |
| `gate-push-final.log`             | Most recent gate-push invocation log (FAILURE MODE B).    |
