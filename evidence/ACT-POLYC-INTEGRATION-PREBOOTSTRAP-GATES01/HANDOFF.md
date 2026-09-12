# HANDOFF — ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01

VERDICT: **HALT_SCOPE_EXPANSION_REQUIRED**

## Summary

D1 (GEP01 binding), D2 (canonical install seam), D3 (shell ratchet)
were implemented and verified against the existing factory gates.
C3 cannot close because `GPUSH-3 aot` (`make unit-test`) and
`GPUSH-GEP01 gep01` (`make llvm-gep01-test`) require mutually
exclusive configurations of the canonical install in the gate's
hermetic prefix.

Conflict resolution requires one of three changes, all OUTSIDE
this ACT's scope:

1. AOT codegen fix in `src/aarch64.c` / `src/x86_64.c` to emit
   PLT-style indirect calls for cross-translation-unit function
   references (so the AOT code's `adrp`/`add` pairs against `_FREE`
   are not needed when linking against a dylib).
2. libtos dylib build flag in `src/CMakeLists.txt` such as
   `-Wl,-Bsymbolic` for the canonical dylib creation.
3. GEP01 harness refactor in `tools/quality/llvm-gep01-test.HC`
   to not transitively `#include` libtos source via
   `tooling.HC` -> `memory.HC`.

Per F15, the agent halts rather than self-authorize scope
expansion.

## IDENTITY

```
branch:  main
ENTRY_HEAD: 8f398be (merge: integrate Track B before BOOTSTRAP01)
C1 RED:     eb31ec5 (ACT doc + RED packet)
C2 IMPL:    0ad89db (Makefile test-prefix-install + llvm-gep01-test;
             gate-push GPUSH-2/GPUSH-GEP01 wiring;
             factory-halt-classification Python migration)
C2.1 IMPL:  655b7bd (unit-test / jit-unit-test consume hermetic test
             prefix; test-prefix-install removes unversioned
             libtos.dylib symlink hermetic-prefix-locally)
C3 HALT:    6223aad (gate-push log + conflict diagnosis + halt
             classification)
ROADMAP:    a7664f8 (record HALT_SCOPE_EXPANSION_REQUIRED)
FINAL_HEAD: a7664f8
WORKTREE:   clean
```

## ROOT CAUSE / FINDING

The canonical install dance in `src/CMakeLists.txt` CORRECTION03
creates an unversioned `libtos.dylib -> libtos.0.0.1.dylib`
symlink so that downstream `-ltos` linkage pulls in the dylib.
This symlink is the source of two mutually exclusive failure
modes on arm64:

  **A. libtos.dylib symlink PRESENT** (canonical install default)
  - llvm-gep01-test PASSES. The dylib supplies `_FREE`, `_MEMCPY`,
    `_MSIZE`, etc. at link time. The harness's
    `tooling.HC` -> `memory.HC` -> ... include chain's copies are
    dedup'd by the dylib's NOUNDEFS layout.
  - unit-test FAILS with `ld: invalid use of ADRP in
    '_CmpFileNames' to '_FREE'`. The AOT codegen emits
    `adrp x0, _FREE@PAGE` + `add x0, x0, _FREE@PAGEOFF` to compute
    `_FREE`'s address. macOS's ld64 rejects these because the
    dylib's `nreloc=0` in `__text` cannot satisfy the link-time
    PIC requirement.

  **B. libtos.dylib symlink ABSENT** (test-prefix-install removes
     it hermetic-prefix-locally; per 655b7bd)
  - unit-test PASSES. `libtos.a` ships archive-style relocations
    (`nreloc=560` in `__text`) that the AOT code's `adrp`/`add`
    pairs satisfy at link time.
  - llvm-gep01-test FAILS with 26 duplicate symbols. The harness
    defines `_FREE`, `_MEMCPY`, `_MSIZE`, `_Stat`,
    `_WaitPidIntr`, etc. via the `tooling.HC` -> `memory.HC`
    include chain; `libtos.a[2](all.o)` also defines them; the
    linker refuses to choose.

The conflict pre-dates this ACT. The previous successful
gate-push at commit `a5818c6` did not include `llvm-gep01-test`
(the GEP01 binding is a D1 deliverable of this ACT), so the
conflict was never exercised in production.

## RED

Principal RED captured at C1 (commit `eb31ec5`):
- D1 RED: GEP01 oracle harness was a `.sh` file (139 LOC) with
  no gate-push binding. See
  `evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c1/d1-gep-unbound.txt`.
- D2 RED: tooling-runtime install was duplicated in 3 call sites
  (lsp-test, gate-push, runtime01-selftest) using
  `hcc -lib tos all.HC` directly. See
  `evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c1/d2-install-callgraph.txt`.
- D3 RED: shell-loc-gate approaching 480 baseline; halt-classification
  logic was 187 LOC of shell. See
  `evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c1/d3-shell-loc-red.txt`.

The C3 conflict (unit-test vs. llvm-gep01-test) was NOT a principal
RED of this ACT — it surfaced during C3 evidence capture as an
uncovered interaction between D1 (GEP01 binding to gate-push) and
a pre-existing AOT codegen limitation on arm64.

## IMPLEMENTATION

C2 IMPL (commit `0ad89db`):
- `Makefile`: added `test-prefix-install` (canonical install via
  CMake install dance; consumes `TEST_PREFIX ?=`); added
  `llvm-gep01-test` (depends on `test-prefix-install`, compiles
  harness from source, runs against fresh prefix, exits with real
  status); `lsp-test` now depends on `test-prefix-install` with
  `--install-dir=$(TEST_PREFIX)`.
- `scripts/quality/gate-push.sh`: GPUSH-2 invokes `make
  test-prefix-install` with `TEST_PREFIX=$gate_prefix`; GPUSH-GEP01
  invokes `make llvm-gep01-test`; both with `HCC_ENABLE_LLVM=ON` so
  host hcc carries the LLVM backend for the GEP01 oracle harness.
- `scripts/quality/factory-halt-classification.py` (NEW, 244 LOC):
  Python re-implementation of the 12-case halt-classification
  matrix; replaces 187 LOC of shell logic.
- `scripts/quality/factory-halt-classification-check.sh` (now 18 LOC
  launcher) and `factory-halt-classification-test.sh` (now 15 LOC
  launcher): thin `exec python3 ...` launchers.

C2.1 IMPL (commit `655b7bd`):
- `Makefile`: `unit-test` and `jit-unit-test` now depend on
  `test-prefix-install` and pass `--install-dir=$(TEST_PREFIX)`,
  matching the lsp-test pattern. Resolves "Failed to open file:
  /usr/local/include/tos.HH" on hosts without a writable /usr/local.
- `Makefile`: `test-prefix-install` adds `@rm -f
  $(TEST_PREFIX)/lib/libtos.dylib` after the canonical install,
  hermetic-prefix-locally removing the unversioned symlink that
  triggers the AOT/ADRP failure. Production `make install` is
  untouched.

C3 HALT (commit `6223aad`):
- `evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c3/`: full
  EVIDENCE packet — README, conflict diagnosis, two-failure-mode
  transcript, captured gate-push-final.log.

ROADMAP update (commit `a7664f8`):
- Critical-path transition table records the HALT.
- Per-ACT status section explains the conflict and the three
  resolution options.

## GATES

| Gate                                                | Result | Notes |
|-----------------------------------------------------|--------|-------|
| shell-loc-gate                                      | PASS   | gate-push.sh at 480 LOC (baseline); both .sh launchers under 20 LOC. |
| factory-v2-test                                     | PASS   | All factory v2 invariants satisfied. |
| append-only-test                                    | PASS   | History invariant maintained. |
| closure-status-test                                 | PASS   | Prior closures remain valid. |
| halt-classification-test                            | 12/0 PASS | Python matrix equivalent to shell. |
| gate-fast                                           | PASS   | Per C2 README. |
| Track-A LLVM gates (byte-memory 37/0, intops 4/0, ir-fwd 6/0) | PASS | Per C2 README. |
| make lsp-test                                       | 43/43 PASS | Per C2 README. |
| make llvm-gep01-test (local)                        | 30/0 PASS | Per C2 README. |
| gate-push GPUSH-1 build                             | PASS   | hcc compiled with HCC_ENABLE_LLVM=ON, INSTALL_PREFIX=$gate_prefix. |
| gate-push GPUSH-2 install                           | PASS   | `make test-prefix-install` lands libtos.a + libtos.0.0.1.dylib (+ symlink) in $gate_prefix/lib/. |
| gate-push GPUSH-GEP01 gep01                         | FAIL (FAILURE MODE B) | 26 duplicate symbols (linker rejects harness's libtos-source copies vs. libtos.a). |
| gate-push GPUSH-3 aot                               | FAIL (FAILURE MODE A) | `ld: invalid use of ADRP in '_CmpFileNames' to '_FREE'` (linker rejects AOT adrp/add pair against dylib). |
| gate-push GPUSH-3 + GPUSH-GEP01 simultaneously      | IMPOSSIBLE | Mutually exclusive configurations of the canonical install symlink. |

## SCOPE

```
FILES_CHANGED (cumulative across C1-C3):
  docs/acts/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01.md
  evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/{README.md,c1/*,c2/*,c3/*}
  Makefile (added test-prefix-install, llvm-gep01-test; unit-test uses TEST_PREFIX)
  scripts/quality/gate-push.sh (GPUSH-2/GPUSH-GEP01 wiring)
  scripts/quality/factory-halt-classification.py (NEW)
  scripts/quality/factory-halt-classification-check.sh (rewrite to 18 LOC launcher)
  scripts/quality/factory-halt-classification-test.sh (rewrite to 15 LOC launcher)
  docs/ROADMAP.md (record HALT)

DIFF_CHECK: clean.
PRODUCTION_SEMANTICS_CHANGED=NO (no src/ changes).
LLVM_CHANGED=NO (the harness uses --emit-llvm; no LLVM IR changes).
ABI_REPAIR_CHANGED=NO.
```

## RESIDUE

P0:
  - **unit-test / llvm-gep01-test conflict** on arm64 — requires one of:
    (1) AOT codegen fix in src/aarch64.c, src/x86_64.c; (2) libtos
    dylib build flag in src/CMakeLists.txt; (3) GEP01 harness refactor
    in tools/quality/llvm-gep01-test.HC. Blocks gate-push closure
    of THIS ACT (and any future gate-push that wants unit-test
    + GEP01).
  - Recommended next ACT: ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01,
    bounded to one of the three resolution options above.

P1:
  - **Linux build of libtos** (ACT-POLYC-TOOLING-LINUX-PORT01) — the
    canonical install's macOS-only branch (`if (APPLE)`) needs Linux
    support for hermetic testing on non-macOS CI.

P2:
  - **shell-loc-gate threshold** — currently 480 LOC for gate-push.sh.
    If further quality gates are added, this baseline will need
    raising.

## NEXT ACT

The HALT is a successful execution outcome, not a failed PASS.
The C2 IMPL artifacts remain valid; only the gate-push closure
is blocked. Recommended next ACT:

**ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01** —
resolve the unit-test / llvm-gep01-test conflict via one of:
- **Option A** (AOT codegen): modify `src/aarch64.c` /
  `src/x86_64.c` to emit `bl _sym@PLT` / `blr x0` instead of
  `adrp + add + ldr + blr` for cross-translation-unit function
  references. Bound to: existing GEP01 oracle 30/0 PASS must
  remain; existing Track-A LLVM gates must remain GREEN.
- **Option B** (libtos dylib build flag): modify
  `src/CMakeLists.txt` `cc -dynamiclib ...` command to add
  `-Wl,-Bsymbolic` so internal libtos references are bound at
  dylib link time and the dylib is link-cleanly usable by
  executables that reference libtos symbols via adrp/add. Bound
  to: pre-existing CORRECTION03 intent (deduplicate libtos
  source via dylib) must be preserved.
- **Option C** (GEP01 harness refactor): modify
  `tools/quality/llvm-gep01-test.HC` to NOT transitively include
  `tooling.HC` (which transitively pulls in `memory.HC`), and
  link against `libtos.a` directly. Bound to: 30-row oracle matrix
  and all process-determinism guarantees must remain identical.

The recommended option is Option B because it touches the smallest
production surface (a single linker flag in `src/CMakeLists.txt`)
and has the smallest blast radius (preserves all existing
canonical-install behavior; only changes dylib layout). Option A
is the most architecturally correct (the AOT codegen SHOULD emit
PLT-style calls for cross-translation-unit refs) but touches
production compiler code. Option C is the most localized but
regresses the GEP01 harness's documented design rationale.

**No push to origin/main.** The HALT means this ACT's gate-push
closure cannot complete on the merged tree. Per the task
description ("Must pass gate-push.sh on merged HEAD then push"),
pushing is deferred to the CORRECTION ACT.
