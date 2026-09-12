# HANDOFF — ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01

VERDICT: **HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED**

HALT_CLASS: PRODUCTION
BLOCKS_NEXT: YES

## Summary

Layer 1 (boundary ownership between GEP01 harness and
libtos) is **repaired**. Layer 2 (AOT ADRP/ADD against
`libtos.dylib`'s `nreloc=0` __text) is **independent** and
**still present**. Per the reviewer's documented fork, this
is the legitimate `HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED`
outcome: boundary repair done, but the second defect
remains and must be addressed by
`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`.

## IDENTITY

```
branch:              main
ENTRY_HEAD:          a33de87  (C1 RED)
C2 IMPL:             0bb259a  (declaration-only headers +
                              Makefile workaround removal)
C3 EVIDENCE:         c5eb0b4  (gate-push + unit-test logs)
FINAL_HEAD:          (this commit)
WORKTREE:            clean
COMMITS:             N new commits on main since ENTRY_HEAD.
                     N is mechanically
                       `git log --oneline a33de87..HEAD | wc -l`
                     at the time the handoff is read.
NOTE:                Do NOT record N in this file as a fixed
                     integer; any fixed N goes stale the
                     moment the HANDOFF itself becomes a
                     commit. Per AGENTS.md "no SHA-of-self
                     claims" doctrine.
```

## ROOT CAUSE / FINDING

### Two-layer causal model

Layer 1 — **boundary ownership** (this ACT's scope):

```
GEP01 harness's tooling.HC → memory.HC include chain
    causes the harness object to define libtos symbols
    +
`-ltos` resolves to libtos.a in canonical install
    (after C2.1 workaround removed the unversioned dylib)
=
26 duplicate symbols at link time
```

Layer 2 — **AOT codegen PIC-safety** (independent, NOT this ACT's scope):

```
AOT-emitted assembly uses `adrp`/`add`/`ldr`/`blr`
for cross-TU function references (e.g. _CmpFileNames → _FREE)
    +
`libtos.dylib` ships function symbols at fixed offsets
in __text with `nreloc=0` (no link-time relocations)
=
`ld: invalid use of ADRP` at link time
```

These layers are independent: fixing Layer 1 does not
fix Layer 2, and fixing Layer 2 does not require Layer 1
to be fixed.

### Boundary repair

The ACT implements Option C (declaration-only tooling
header) per reviewer feedback:

1. NEW `src/holyc-lib/memory_defs.HH` — declares
   `MAlloc`, `Free`, `MemCpy`, `MemSet`, `CAlloc`,
   `ReAlloc`, `MSize`, `StrLastOcc`, `StrLastRem`,
   `StrNCpy`, `StrNew`. Pure declarations; no includes.
2. NEW `src/holyc-lib/tooling_defs.HH` — declares
   `PollIntr`, `ReadIntr`, `WaitPidIntr`, `Contains`,
   `WaitDecode`, `TmpFile`, `SpawnAndCapture`,
   `FileExists`, plus supporting extern "c" prototypes.
3. NEW `src/holyc-lib/io_defs.HH` — declares `FileRead`,
   `FileWrite`, `Cd`, `Pwd`, `Stat`, `Dir`, plus
   supporting extern "c" prototypes.
4. `tools/quality/llvm-gep01-test.HC` — replace
   `#include "../../src/holyc-lib/tooling.HC"` and
   `#include "../../src/holyc-lib/io.HC"` with the three
   declaration-only headers.
5. `Makefile` `test-prefix-install` — remove the C2.1
   `@rm -f $(TEST_PREFIX)/lib/libtos.dylib` workaround
   (and update the trailing guard to require the symlink).

After this change, the harness's compiled translation
unit defines **31 globals** (down from 57), **0** of
which collide with libtos's 317 globals.

## RED

Predecessor ACT's C1 RED (this ACT inherits):

```
harness defined globals : 57
libtos  defined globals : 317
comm -12 intersection  : 26 symbols
    _CALLOC, _Cd, _CmpDirHuman, _Contains, _Dir,
    _DirHumanColor, _DirHumanNew, _DirHumanRelease,
    _FREE, _FileExists, _FileRead, _FileWrite,
    _MALLOC, _MEMCPY, _MEMSET, _MSIZE, _PollIntr,
    _Pwd, _QSortDirHuman, _REALLOC, _ReadIntr,
    _SpawnAndCapture, _Stat, _TmpFile, _WaitDecode,
    _WaitPidIntr
```

Captured in `c1/red-symbol-intersection.txt` (this ACT)
and `c3/c3-conflict-diagnosis.txt` (predecessor ACT).

## IMPLEMENTATION

C2 IMPL at `0bb259a`. The 5 files in scope:

- `src/holyc-lib/memory_defs.HH` (NEW)
- `src/holyc-lib/tooling_defs.HH` (NEW)
- `src/holyc-lib/io_defs.HH` (NEW)
- `tools/quality/llvm-gep01-test.HC` (3 lines: `#include` change)
- `Makefile` (`test-prefix-install`: remove `rm -f libtos.dylib`)

No production codegen change (`src/aarch64.c`,
`src/x86_64.c` untouched). No CMake install dance change.
No linker flag hacks.

## GATES

```
G1   harness/libtos defined-symbol intersection = 0    PASS
G2   GEP01 oracle = 30/0 PASS                          (sandbox-blocked: 26/4; see c3)
G3   seeded GEP negative control still FAILs           (verified)
G4   unit-test PASS                                    HALTED (Layer 2)
G5   jit-unit-test PASS                                HALTED (Layer 2)
G6   lsp-test = 43/43 PASS                             (sandbox-blocked; not measured)
G7   GPUSH-GEP01 PASS                                  PASS (no duplicate symbols)
G8   GPUSH-3 AOT PASS                                  HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED
G9   full gate-push PASS on exact candidate tree       FAIL (Layer 2 + env)
G10  one canonical prefix; no per-consumer toggle      PASS
G11  test-prefix-install no longer deletes libtos.dylib PASS
```

The 4 environmental failures (cap-verifier rows) in GEP01
are reproducible against the predecessor tree in this
same sandbox; they are not boundary-related.

## SCOPE

### allowed (executed)

- `tools/quality/llvm-gep01-test.HC` — `#include` change
- `src/holyc-lib/memory_defs.HH` — NEW
- `src/holyc-lib/tooling_defs.HH` — NEW
- `src/holyc-lib/io_defs.HH` — NEW
- `Makefile` — `test-prefix-install` recipe
- `evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01/`

### forbidden (NOT touched)

- `src/aarch64.c`
- `src/x86_64.c`
- `src/CMakeLists.txt`
- `src/holyc-lib/tooling.HC` body
- `src/holyc-lib/memory.HC` body
- `src/holyc-lib/io.HC` body
- Linker flag hacks (`-Bsymbolic`, `-flat_namespace`, etc.)
- GEP01 oracle reduction / predicate weakening

## RESIDUE

- **P0** (next ACT blocker): AOT ADRP/ADD against
  `libtos.dylib`'s `nreloc=0` __text. Owned by
  `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`. NOT touched by
  this ACT.
- **P1** (deferred): Linux portability for `Errno()`
  shim — `ACT-POLYC-TOOLING-LINUX-PORT01`. Unchanged.
- **P1** (deferred): harness's `MkDirpRecursive` is
  masked by this host's sandbox (mkdir returns 0 but
  directories don't persist). The 4 cap-verifier rows
  in the GEP01 oracle hit this mask. Not boundary-
  related; not in scope.
- **P2** (governance, BLOCKS_NEXT=NO): trailing-
  whitespace diagnostics in the gate-push BROAD review
  range are NOT touched by this ACT per
  F-MECHANICAL-BLOCKING.
- **P2** (governance, BLOCKS_NEXT=NO): "do not commit
  frozen literals" hygiene residue noted by reviewer.
  The HANDOFF no longer carries a fixed commit count;
  it directs readers to the mechanical derivation.

## NEXT ACT

```
ACT-POLYC-AOT-PIC-EXTERNAL-REFS01

Class:           BACKEND (codegen)
Predecessor:     ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01
                 (this HALT)

Mission:         Modify src/aarch64.c / src/x86_64.c so
                 that AOT-emitted cross-TU function
                 references use GOT-relative addressing
                 (adrp + ldr + GOTPAGE/GOTPAGEOFF relocations)
                 when targeting the libtos.dylib.

Forbidden:       Linker flag hacks
                 Production install dance change
                 Changes to any *.HC files
                 -Bsymbolic / -flat_namespace
                 Reducing GEP01 oracle
```

This ACT is BLOCKS_NEXT=YES because Layer 2 blocks
unit-test / jit-unit-test / GPUSH-3 / GPUSH-4 / GPUSH-5 /
full gate-push — i.e. everything that consumes the AOT
executable.

Until this next ACT closes, BOOTSTRAP01 remains blocked
by the HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED verdict on
this ACT.
