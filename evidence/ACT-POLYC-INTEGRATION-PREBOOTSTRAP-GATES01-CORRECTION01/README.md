# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Class:** ARCHITECTURAL-BOUNDARY

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01
(HALT_SCOPE_EXPANSION_REQUIRED, BLOCKS_NEXT=YES,
HALT_CLASS=PRODUCTION)

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

---

## Mission

Restore the library-ownership boundary between the GEP01 test
harness (`tools/quality/llvm-gep01-test.HC`) and the canonical
`libtos` so that the same hermetic install prefix satisfies
both `make llvm-gep01-test` (GPUSH-GEP01) and `make unit-test`
(GPUSH-3) without per-step dylib/archive toggles.

The bound is: the harness's compiled translation unit must
define ZERO symbols that libtos also defines. We verify this
mechanically via `comm -12` of `nm -g` outputs.

If this repair alone closes GPUSH-3 + GPUSH-GEP01 + full
gate-push with the canonical install (libtos.dylib symlink
PRESENT), the ACT PASSes and BOOTSTRAP01 is unblocked.

If GPUSH-3 still fails with the dylib symlink present AFTER
the boundary repair (AOT ADRP defect, Layer 2), the ACT
HALTs with `HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED` and routes
to the next backend ACT
(`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`). Both outcomes are
legitimate.

---

## Scope

### allowed

- `tools/quality/llvm-gep01-test.HC` (change the includes)
- `src/holyc-lib/tooling_defs.HH` (NEW: declaration-only
  header exposing `tooling.HC`'s public surface without
  dragging in `memory.HC`)
- `src/holyc-lib/io_defs.HH` (NEW: declaration-only header
  exposing `io.HC`'s public surface similarly)
- `Makefile` (`test-prefix-install` recipe — remove the
  `rm -f $(TEST_PREFIX)/lib/libtos.dylib` C2.1 workaround)
- `evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01/`
  (RED evidence, IMPL evidence, GREEN evidence, HANDOFF)

### forbidden

- `src/holyc-lib/tooling.HC` body — its PUBLIC surface is
  preserved verbatim; no API changes
- `src/holyc-lib/memory.HC` — pure declaration-only headers
  cannot transitively reach this; do not split or move
  definitions out of memory.HC
- `src/holyc-lib/io.HC` — same reason
- `src/aarch64.c` — AOT codegen is out of scope for Layer 1
- `src/x86_64.c` — AOT codegen is out of scope for Layer 1
- `src/CMakeLists.txt` — install dance is canonical; do not
  weaken or alter
- `-Wl,-Bsymbolic` (or any ELF/GNU-linker-only option) —
  Apple's `ld64`/`ld-classic` do not expose it
- `-flat_namespace`, `-undefined dynamic_lookup`,
  `-multiply_defined suppress` — namespace hacks are
  forbidden by the predecessor ACT
- Reducing the 30-row GEP01 oracle
- Weakening GEP01 predicates
- Forcing a particular `libtos.a` vs `libtos.dylib`
  resolution per-step (the whole point is to restore
  neutrality)
- Dependency additions
- CI / framework / container changes
- Push to `origin/main` until the full gate-push PASSes

---

## Principal RED

### R1 — harness object defines libtos implementation symbols

Build the current harness and inspect:

```sh
./hcc --install-dir=build/test-prefix \
       tools/quality/llvm-gep01-test.HC \
       -o /tmp/harness.o -c

nm -g /tmp/harness.o | awk '$2 ~ /^[TBD]$/ { print $3 }' \
  | sort -u > /tmp/harness.defs
nm -g build/test-prefix/lib/libtos.a 2>/dev/null \
  | awk '$2 ~ /^[TBD]$/ { print $3 }' \
  | sort -u > /tmp/libtos.defs

comm -12 /tmp/harness.defs /tmp/libtos.defs
# Expected RED: non-empty (the harness transitively compiles
# memory.HC which defines _FREE, _MEMCPY, _MSIZE, _Stat,
# _WaitPidIntr, _Contains, _MAlloc, _Free, _MemCpy,
# _SlurpFile, ...)
```

The exact symbol set is captured in
`c1/red-symbol-intersection.txt`.

### R2 — GPUSH-GEP01 fails (FAILURE MODE B reproduction)

```sh
bash scripts/quality/gate-push.sh HEAD
# Expected: CHECK=gep01 STATUS=FAIL with 26 duplicate symbols
# (this is the current state because the C2.1 symlink-removal
# workaround is in effect; reproducing the failure proves RED
# is real and not a stale-build artifact)
```

### R3 — Layer 2 is independent (GPUSH-3 fails with dylib symlink present)

```sh
# Temporarily restore the symlink and re-run GPUSH-3 in
# isolation. Demonstrates the AOT defect is independent of
# the boundary defect.
ln -sf libtos.0.0.1.dylib build/test-prefix/lib/libtos.dylib
cd ./src/tests && \
  ../../hcc --install-dir=build/test-prefix \
    ./run.HC -o test-runner && \
  ./test-runner
rm build/test-prefix/lib/libtos.dylib
# Expected: ld: invalid use of ADRP in '_CmpFileNames' to
# '_FREE'
# This proves Layer 2 is a separate defect (Layer 1 alone is
# what this ACT is bound to repair).
```

The three REDs together prove both layers are independent and
the boundary repair is the right scope for this ACT.

---

## Acceptance criteria

```
G1   harness/libtos defined-symbol intersection = 0
G2   GEP01 oracle = 30/0 PASS
G3   seeded GEP negative control still FAILs (no predicate
     weakening)
G4   unit-test PASS
G5   jit-unit-test PASS
G6   lsp-test = 43/43 PASS
G7   GPUSH-GEP01 PASS
G8   GPUSH-3 AOT PASS
G9   full gate-push PASS on exact candidate tree
G10  one canonical prefix; no per-consumer dylib/archive
     toggle; NO libtos.dylib symlink manipulation in
     test-prefix-install
G11  test-prefix-install no longer deletes libtos.dylib
     solely to make one consumer pass (per reviewer
     ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01
     feedback)
```

### HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED

If G1..G7, G9 (gate-push), G10, G11 are met (boundary repair
proven; canonical install neutral; GEP01 green; gate-push
green except for G8 = GPUSH-3) — but G8 (unit-test against
canonical install with dylib symlink PRESENT) still fails
with `ld: invalid use of ADRP in '_CmpFileNames' to '_FREE'`
— the ACT HALTs with
`HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED`.

This is a legitimate outcome per the reviewer fork:
boundary repair done, but the second defect (Layer 2) is a
real backend bug that requires
`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`.

---

## Conservation gates

The following existing gates must remain PASS at CLOSE
(or be HALTed with the named HALT_* token if an AOT PIC
defect is the documented boundary):

- `make unit-test`
- `make jit-unit-test`
- `make lsp-test`
- `bash scripts/quality/gate-fast.sh HEAD`
- `bash scripts/quality/factory-halt-classification-test.sh`
- `bash scripts/quality/factory-v2-test.sh`
- `bash scripts/quality/factory-append-only-test.sh`
- `bash scripts/quality/factory-closure-status-check.sh`
- `bash scripts/quality/shell-loc-gate.sh`
- `bash scripts/quality/factory-v2-range-check.sh ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01 HEAD`

---

## HALT conditions

- `HALT_RED_NOT_REPRODUCED` — if G1's `comm -12` returns
  empty, the boundary defect is misdiagnosed and this ACT
  must halt rather than fabricate a refactor.
- `HALT_SCOPE_EXPANSION_REQUIRED` — if closing G4..G11
  requires editing production codegen (e.g. `src/aarch64.c`)
  or linker flags, the AOT PIC defect must be HALTed off as
  `HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED` with the next ACT
  named.
- `HALT_TEST_WEAKENING` — if any GEP01 oracle row is
  weakened or any predicate relaxed.
- `HALT_REGRESSION` — if any of the conservation gates
  fails AND that failure is unrelated to the boundary
  repair.

---

## Residue

Pre-declared known side observations:

- **P0** (this ACT): AOT ADRP/ADD against `libtos.dylib`
  (`nreloc=0` __text). Either resolved by this ACT (if
  full gate-push passes) or HALTed to a dedicated backend
  ACT.
- **P1** (deferred): Linux portability for `Errno()` shim
  — see `ACT-POLYC-TOOLING-LINUX-PORT01`. Unchanged.
- **1** (governance): the `Makefile` `rm -f libtos.dylib`
  line removal in this ACT may surface hidden coupling
  between the GEP harness and the AOT codegen. Capture any
  newly-discovered coupling as P2 residue.
- **P2** (governance): the gate-push `BROAD` review range
  historically surfaces 11 whitespace diagnostics, of which
  2 are `c3/gate-push-final.log` lines (captured build
  output, not source). Per F-MECHANICAL-BLOCKING those are
  HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO and are NOT
  touched by this ACT.

---

## Execution metadata

Execution identity is stored in Git commit trailers.

Every ACT commit:

```
ACT: ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01
ACT-Phase: RED|IMPL|EVIDENCE|CLOSE
```

CLOSE additionally:

```
ACT-Verdict: PASS|HALT_*
```

The original authorization artifact remains historically
stable; there is no OPEN -> PASS / HALT mutation. The
ACT document is NOT modified at closure.

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01 HEAD
```

---

## Closure handoff

Use the Factory v2 HANDOFF template at
`docs/factory/HANDOFF-TEMPLATE.md`. Final handoff lives at
`evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01/HANDOFF.md`.
