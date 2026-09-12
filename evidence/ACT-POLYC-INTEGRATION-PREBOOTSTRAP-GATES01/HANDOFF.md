# HANDOFF — ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01

VERDICT: **HALT_SCOPE_EXPANSION_REQUIRED**

HALT_CLASS: PRODUCTION
BLOCKS_NEXT: YES

## Summary

D1 (GEP01 binding), D2 (canonical install seam), D3 (shell ratchet)
were implemented and verified against the existing factory gates.
C3 cannot close because `GPUSH-3 aot` (`make unit-test`) and
`GPUSH-GEP01 gep01` (`make llvm-gep01-test`) require mutually
exclusive configurations of the canonical install in the gate's
hermetic prefix.

The architectural defect is a **library-ownership collision** in
the GEP01 harness: it transitively `#include`s libtos implementation
source (`tooling.HC` -> `memory.HC`) so the harness object defines
libtos symbols. When linked against `libtos.a` (archive path) the
linker sees duplicate global definitions. The previous absence of
this conflict (commit `a5818c6`) was an artifact of the gate-push
not yet exercising llvm-gep01-test.

Conflict resolution requires one of three changes, all OUTSIDE
this ACT's scope:

1. **Option A (compiler backend)**: AOT codegen in `src/aarch64.c`
   / `src/x86_64.c` emits PIC-safe GOT page references for
   externally supplied symbols (e.g. `adrp xN, _FREE@GOTPAGE` /
   `ldr xN, [xN, _FREE@GOTPAGEOFF]` + `blr`). Touches production
   codegen, requires arm64 + x86_64 dual testing, and is a real
   future compiler ACT — not a pre-BOOTSTRAP fix.
2. **Option B (linker flag)**: ~~`-Wl,-Bsymbolic` on libtos dylib
   creation~~ — **REJECTED**. `-Bsymbolic` is an ELF/GNU-linker
   option. Apple's `ld64` and `ld-classic` do not expose it
   (verified locally: `xcrun ld-classic -help | grep -i bsymbolic`
   returns no matches). Any Mach-O equivalent would require
   `-exported_symbol` allowlists or `-flat_namespace` semantics,
   which are intrusive and weaken the canonical-install contract.
3. **Option C (library boundary)**: Refactor
   `tools/quality/llvm-gep01-test.HC` to use declaration-only
   consumption of `tooling.HC`'s API (e.g. via a new
   `tooling_defs.HH` header that exposes the public API surface
   without dragging in `memory.HC`). Then link against the
   canonical `libtos.a` (already produced by `test-prefix-install`)
   without dragging libtos implementation symbols into the harness
   object. This restores a single library-ownership boundary and
   eliminates the artificial requirement that GEP01 needs the dylib
   to hide a self-linking mistake.

**Recommended next ACT**:
`ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01`,
bounded to Option C.

Per F15, the agent halts rather than self-authorize scope
expansion.

## IDENTITY

```
branch:  main
ENTRY_HEAD:    8f398be (merge: integrate Track B before BOOTSTRAP01)
C1 RED:        eb31ec5 (ACT doc + RED packet)
C2 IMPL:       0ad89db (Makefile test-prefix-install + llvm-gep01-test;
                gate-push GPUSH-2/GPUSH-GEP01 wiring;
                factory-halt-classification Python migration)
C2.1 IMPL:     655b7bd (unit-test / jit-unit-test consume hermetic
                test prefix; test-prefix-install removes unversioned
                libtos.dylib symlink hermetic-prefix-locally)
C3 HALT:       6223aad (gate-push log + conflict diagnosis + halt
                classification)
ROADMAP:       a7664f8 (record HALT_SCOPE_EXPANSION_REQUIRED)
HANDOFF v1:    d5288c4 (structured closure handoff)
DOC CLARIFY:   6f885bf (FAILURE MODE A transcript provenance)
HANDOFF v2:    b326bb8 (reviewer-revised: two-layer model; Option B
                REJECTED; Option C promoted; commit count
                corrected; RED + GREEN contract added)
FINAL_HEAD:    b326bb8
WORKTREE:      clean
COMMITS:       8 new commits on main since 8f398be (append-only).
```

## ROOT CAUSE / FINDING

The canonical install dance in `src/CMakeLists.txt` CORRECTION03
creates an unversioned `libtos.dylib -> libtos.0.0.1.dylib`
symlink so that downstream `-ltos` linkage pulls in the dylib.
On arm64 this interacts with a real bug in the GEP01 harness
**and** with a separate (latent) AOT codegen limitation. The two
problems are coupled by the hermetic install's binary layout.

### Two-layer causal model

**Layer 1: Mach-O image separation under two-level namespace.**

Mach-O dynamic linking uses a two-level namespace: each symbol
reference is bound in the context of the image that defined it.
When an executable links against a dylib, the executable's
definitions and the dylib's definitions live in **separate
images**, and the dynamic loader binds each call site to the
correct owner. When an executable links against a static archive
(`.a`), archive members are pulled into the **same final
executable image**, so two definitions of the same global symbol
become a hard error.

The GEP01 harness's `tooling.HC` -> `memory.HC` include chain
causes the harness's compiled object to define libtos symbols
(`_FREE`, `_MEMCPY`, `_MSIZE`, `_Stat`, `_WaitPidIntr`, etc.).
With `-ltos` resolving to `libtos.dylib`, these definitions are
in the executable image and the libtos definitions are in the
dylib image — two-level namespace binding keeps them separate.
With `-ltos` resolving to `libtos.a`, `all.o` is pulled into the
executable image and now the executable image contains two
definitions of each symbol — `ld: 26 duplicate symbols`.

So the `unit-test` + `libtos.dylib` failure is **NOT** a dylib
deduplication story. It is a separate (real) AOT codegen
limitation.

**Layer 2: AOT codegen limitation on cross-translation-unit refs.**

The existing AOT codegen (`src/aarch64.c`, `src/x86_64.c`) emits
`adrp xN, _SYM@PAGE` + `add xN, xN, _SYM@PAGEOFF` + `ldr xN, [xN]`
+ `blr xN` for cross-translation-unit function references.
mach-O's ld64 requires PIC-safe external references from a dylib
to use GOT page relocations (`@GOTPAGE` / `@GOTPAGEOFF`) rather
than direct page relocations, because the dylib's `__text`
section carries `nreloc=0` (no relocations). When the executable
links against `libtos.dylib` and references `_FREE` via the
direct-page pattern, `ld` rejects with `invalid use of ADRP in
'X' to '_FREE'`.

This is a **separate** defect from Layer 1, and it is the reason
`unit-test` cannot link against `libtos.dylib` even after the
harness's symbol-collision is fixed.

### Two failure modes

  **A. libtos.dylib symlink PRESENT** (canonical install default)
  - llvm-gep01-test PASSES: two-level namespace binding tolerates
    the harness's redundant definitions.
  - unit-test FAILS (Layer 2): `ld: invalid use of ADRP in
    '_CmpFileNames' to '_FREE'`.

  **B. libtos.dylib symlink ABSENT** (test-prefix-install removes
     it hermetic-prefix-locally; per 655b7bd)
  - unit-test PASSES: `libtos.a`'s archive-style relocations
    (`nreloc=560` in `__text`) satisfy the AOT code's `adrp`/`add`
    pairs at link time.
  - llvm-gep01-test FAILS (Layer 1): 26 duplicate symbols.

The conflict is two **independent** defects that the hermetic
install can flip between but cannot satisfy simultaneously.

The conflict pre-dates this ACT. The previous successful
gate-push at commit `a5818c6` did not include `llvm-gep01-test`
(the GEP01 binding is a D1 deliverable of this ACT), so Layer 1
was never exercised in production.

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
| make llvm-gep01-test (local, with hermetic prefix)  | 30/0 PASS | Per C2 README. |
| gate-push GPUSH-1 build                             | PASS   | hcc compiled with HCC_ENABLE_LLVM=ON, INSTALL_PREFIX=$gate_prefix. |
| gate-push GPUSH-2 install                           | PASS   | `make test-prefix-install` lands libtos.a + libtos.0.0.1.dylib (+ symlink, then symlink removed hermetic-prefix-locally) in $gate_prefix/lib/. |
| gate-push GPUSH-GEP01 gep01                         | FAIL (FAILURE MODE B, Layer 1) | 26 duplicate symbols: harness.o defines `_FREE`, `_MEMCPY`, `_MSIZE`, `_Stat`, `_WaitPidIntr` etc. via `tooling.HC` -> `memory.HC`; `libtos.a[2](all.o)` defines them too. |
| gate-push GPUSH-3 aot                               | FAIL (FAILURE MODE A, Layer 2) | `ld: invalid use of ADRP in '_CmpFileNames' to '_FREE'`: AOT codegen's `adrp/add` direct-page relocations are rejected when the executable links against `libtos.dylib`'s `nreloc=0` __text. |
| gate-push GPUSH-3 + GPUSH-GEP01 simultaneously      | IMPOSSIBLE | The two failures stem from independent defects; toggling the symlink switches which one fires. |

## SCOPE

```
FILES_CHANGED (cumulative across C1-C3 + HANDOFF):
  docs/acts/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01.md
  evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/{README.md,HANDOFF.md,c1/*,c2/*,c3/*}
  Makefile (added test-prefix-install, llvm-gep01-test; unit-test uses TEST_PREFIX)
  scripts/quality/gate-push.sh (GPUSH-2/GPUSH-GEP01 wiring)
  scripts/quality/factory-halt-classification.py (NEW)
  scripts/quality/factory-halt-classification-check.sh (rewrite to 18 LOC launcher)
  scripts/quality/factory-halt-classification-test.sh (rewrite to 15 LOC launcher)
  docs/ROADMAP.md (record HALT)

PRODUCTION_SEMANTICS_CHANGED=NO (no src/ changes).
LLVM_CHANGED=NO (the harness uses --emit-llvm; no LLVM IR changes).
ABI_REPAIR_CHANGED=NO.

DIFF_CHECK (sources, executables, scripts):
  Clean. The 2 trailing-whitespace findings from
  `git diff --check` are inside the captured
  `c3/gate-push-final.log` (lines 237 and 372, both echoes of
  the `cc -dynamiclib ...` invocation captured verbatim from
  the upstream build log). They are evidence, not source.
```

## RESIDUE

P0 (blocks PREBOOTSTRAP gate-push closure):
  - **Layer 1: GEP01 harness symbol-ownership collision.**
    `tools/quality/llvm-gep01-test.HC` transitively
    `#include`s `tooling.HC` which `#include`s `memory.HC`,
    causing the harness object to define libtos implementation
    symbols. Fix via Option C (declaration-only tooling
    header). Blocks llvm-gep01-test linkage against `libtos.a`.
  - **Layer 2: AOT codegen PIC-safety on arm64.** The
    `adrp/add/ldr/blr` pattern emitted by `src/aarch64.c`
    for cross-translation-unit references is not PIC-safe
    against dylib `__text`. Real defect; needs a future
    backend ACT. After Option C lands, this defect
    surfaces for llvm-gep01-test too, so it must be
    addressed before the integrated gate-push is fully
    green. Track as separate ACT:
    `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01` (or equivalent).
  - Recommended near-term ACT:
    `ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01`,
    bounded to Option C (harness refactor) and a
    canonical-prefix-only invariant.

P1 (important near-term, not blocking):
  - **Linux build of libtos** (ACT-POLYC-TOOLING-LINUX-PORT01)
    — the canonical install's macOS-only branch (`if (APPLE)`)
    needs Linux support for hermetic testing on non-macOS CI.
  - **AOT codegen PIC-safety** as standalone backend ACT
    (see Layer 2 above).

P2 (governance residue, no engineering block):
  - **Two trailing-whitespace lines** in
    `c3/gate-push-final.log` at lines 237 and 372. Both are
    echoed `cc -dynamiclib -Wl,-install_name,...` command
    lines captured verbatim from the upstream build log. The
    lines belong to a captured log (evidence), not to
    executable source. No correction ACT required; flag
    remains in the record.
  - **shell-loc-gate threshold** — currently 480 LOC for
    gate-push.sh. If further quality gates are added, this
    baseline will need raising.

## NEXT ACT

The HALT is a successful execution outcome, not a failed PASS.
The C2 IMPL artifacts remain valid; only the gate-push closure
is blocked. Recommended next ACT:

**`ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01`**
— restore the library boundary between the GEP01 harness and
libtos, then prove a SINGLE canonical hermetic prefix satisfies
both `GPUSH-GEP01` and `GPUSH-3` without per-consumer symlink
manipulation.

### Contract

```
MISSION
  Remove the GEP01 harness's libtos implementation-source
  ownership collision. Then verify that the canonical hermetic
  prefix (single configuration, no per-consumer symlink toggle)
  is sufficient for both unit-test and llvm-gep01-test.

AUTHORIZED PRODUCTION CHANGE
  tools/quality/llvm-gep01-test.HC
  Optionally introduce a new declaration-only header
  (e.g. src/holyc-lib/tooling_defs.HH) if a smaller
  declaration-only refactor is not possible without one.

AUTHORIZED BUILD CHANGE
  Remove the C2.1 `@rm -f $(TEST_PREFIX)/lib/libtos.dylib`
  workaround in Makefile test-prefix-install if no longer
  necessary. Production `make install` must remain
  untouched (libtos.dylib symlink continues to be created
  by the canonical CMake install dance).

FORBIDDEN
  src/aarch64.c
  src/x86_64.c
  general AOT relocation semantics
  linker namespace hacks
  -flat_namespace
  -undefined dynamic_lookup
  -multiply_defined suppress
  ELF-only -Bsymbolic
  weakening GEP01 predicates
  reducing the 30-row oracle
```

### RED (principal)

The principal RED must mechanically prove that the current
harness object exports the colliding symbols. Specifically:

```sh
./hcc tools/quality/llvm-gep01-test.HC -o /tmp/harness.o -c
nm -g /tmp/harness.o | grep -E ' [TU] (_FREE|_MEMCPY|_MSIZE|_Stat|_WaitPidIntr)$'
# Expected RED output: lines for each libtos symbol defined
# or referenced as undefined-external (T = defined, U = used).
```

If the harness object does NOT define or reference any of those
symbols, the defect is misdiagnosed and the CORRECTION01 should
HALT_RED_NOT_REPRODUCED rather than fabricate a refactor.

### GREEN gates

```
G1   harness object no longer defines libtos impl symbols
G2   llvm-gep01-test = 30/0
G3   unit-test = PASS
G4   jit-unit-test = PASS
G5   lsp-test = 43/43
G6   GPUSH-GEP01 = PASS
G7   GPUSH-3 = PASS
G8   full gate-push = PASS
G9   SAME canonical prefix used throughout (no per-step
     dylib/archive toggle; no per-call symlink removal)
G10  factory gates remain green (factory-v2, append-only,
     closure-status, halt-classification, gate-fast,
     shell-loc-gate)
```

### Push

Once G1..G10 are met AND the agent has verified the
append-only invariant on the new commit chain, the
CORRECTION01 ACT authorizes `git push origin main` of the
integrated tree, satisfying the task description ("Must pass
gate-push.sh on merged HEAD then push").

### Why not Option A here?

Option A (AOT codegen fix) is a real defect that should be
addressed, but it touches production codegen in `src/aarch64.c`
/ `src/x86_64.c`, requires arm64 + x86_64 dual testing, and
deserves its own bounded backend ACT. It is **not** the right
shape for the pre-BOOTSTRAP correction because it has a much
larger blast radius.

### Why not Option B?

Option B (linker flag) was the originally preferred option in
this HANDOFF's prior revision. **It is incorrect.** `-Bsymbolic`
is an ELF/GNU-linker option. Apple's `ld64` and `ld-classic` do
not expose it (verified locally:
`xcrun ld-classic -help | grep -i bsymbolic` returns no
matches). Any Mach-O equivalent would require
`-exported_symbol` allowlists or `-flat_namespace` semantics,
which are intrusive and weaken the canonical-install contract.

**No push to origin/main.** The HALT means this ACT's gate-push
closure cannot complete on the merged tree. Per the task
description ("Must pass gate-push.sh on merged HEAD then push"),
pushing is deferred to the CORRECTION01 ACT.
