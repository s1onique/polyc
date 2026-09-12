# C1 RED — ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01

## Defect under proof

The GEP01 test harness
(`tools/quality/llvm-gep01-test.HC`) transitively compiles
libtos implementation source via its include chain:

```
tools/quality/llvm-gep01-test.HC
  -> #include "../../src/holyc-lib/tooling.HC"   (line 49)
       -> #include "./memory.HC"                 (tooling.HC line 19)
       -> #include "../../src/holyc-lib/io.HC"   (harness line 50)
            -> #include "./memory.HC"             (io.HC line 2)
```

The harness's compiled translation unit therefore DEFINES the
same global symbols that libtos defines. When linked against
`libtos.a` (the archive path used by `-ltos` after the C2.1
symlink-removal workaround), the linker sees 26 duplicate
global definitions and rejects the link with `ld: 26
duplicate symbols`.

## RED reproduction

```sh
cd /tmp/polyc-red
/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc/hcc \
  --install-dir=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc/build/test-prefix \
  /Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc/tools/quality/llvm-gep01-test.HC \
  -o harness.o -c

nm -g harness.o | awk '$2 ~ /^[TBD]$/ { print $3 }' | sort -u > harness.defs
nm -g /Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc/build/test-prefix/lib/libtos.a 2>/dev/null \
  | awk '$2 ~ /^[TBD]$/ { print $3 }' | sort -u > libtos.defs

comm -12 harness.defs libtos.defs
```

## RED evidence captured in this directory

- `red-harness-defined-symbols.txt` (57 entries) — every
  defined global in the harness object.
- `red-libtos-defined-symbols.txt` (317 entries) — every
  defined global in libtos.a.
- `red-symbol-intersection.txt` (26 entries) — the actual
  collision set:

```
_CALLOC
_Cd
_CmpDirHuman
_Contains
_Dir
_DirHumanColor
_DirHumanNew
_DirHumanRelease
_FREE
_FileExists
_FileRead
_FileWrite
_MALLOC
_MEMCPY
_MEMSET
_MSIZE
_PollIntr
_Pwd
_QSortDirHuman
_REALLOC
_ReadIntr
_SpawnAndCapture
_Stat
_TmpFile
_WaitDecode
_WaitPidIntr
```

## R1 PASS criterion

`comm -12` is non-empty → 26 symbols. RED confirmed.

## R2 (separate reproduction in full gate-push)

`bash scripts/quality/gate-push.sh HEAD` exits
`VERDICT=FAIL` at `CHECK=gep01` with `ld: 26 duplicate
symbols`. Reproduced in the predecessor ACT's c3 evidence
(`gate-push-final.log`). Re-running it under the same
predecessor tree is not required for this CORRECTION01
because the predecessor tree is the unmodified entry HEAD
of this ACT.

## R3 (Layer 2 independent defect)

Documented in `red-layer2-independent.txt` — temporarily
restoring the libtos.dylib symlink and re-running
`make unit-test` fails with
`ld: invalid use of ADRP in '_CmpFileNames' to '_FREE'`.
Layer 2 is therefore a SEPARATE defect that the boundary
repair alone is not expected to fix.
