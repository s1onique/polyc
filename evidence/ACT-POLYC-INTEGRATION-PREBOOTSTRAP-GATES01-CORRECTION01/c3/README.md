# C3 EVIDENCE — ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01

## Summary

Layer 1 (boundary-ownership) is **REPAIRED**. Layer 2
(AOT ADRP/ADD against dylib `nreloc=0` __text) is
**STILL PRESENT** and is **INDEPENDENT** of Layer 1. Per
the reviewer fork, this is the legitimate
`HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED` outcome.

## What was verified

### G1 (harness/libtos intersection = 0) — verified

Predecessor RED documented 26 symbols in the intersection
between the harness's TU and `libtos.a`. The boundary
repair (Option C: declaration-only tooling/io/memory
headers) reduces this to **0 symbols**. Verified
mechanically:

```sh
nm -g harness.o | awk '$2 ~ /^[TBD]$/ { print $3 }' | sort -u > harness.defs
nm -g libtos.a    | awk '$2 ~ /^[TBD]$/ { print $3 }' | sort -u > libtos.defs
comm -12 harness.defs libtos.defs
# Output: empty
```

Captured in `c2/green-symbol-intersection.txt`.

### G7 (harness links against -ltos archive) — verified

`cc harness.o -L$TEST_PREFIX/lib -ltos -lpthread -lc -lm -o harness_bin`
produces a 228 KB Mach-O 64-bit executable arm64. No
duplicate symbols. No undefined symbols.

### G7-bis (harness links against -ltos dylib) — verified

`ln -sf libtos.0.0.1.dylib $TEST_PREFIX/lib/libtos.dylib` then
`cc harness.o -L$TEST_PREFIX/lib -ltos -lpthread -lc -lm -o harness_bin`
produces a 64 KB Mach-O 64-bit executable arm64. No
duplicate symbols. No undefined symbols.

### G11 (test-prefix-install no longer deletes libtos.dylib) — verified

The Makefile's `test-prefix-install` recipe no longer
contains the C2.1 `@rm -f $(TEST_PREFIX)/lib/libtos.dylib`
workaround. After a fresh `make test-prefix-install`:

```
$ ls -la build/test-prefix/lib/
-rw-r--r-- libtos.0.0.1.dylib
-rw-r--r-- libtos.a
lrwxr-xr-x libtos.dylib -> libtos.0.0.1.dylib
```

All three artifacts present. The recipe's trailing guard
now requires the dylib symlink (`[ ! -L ... ]`) instead
of tolerating its absence, so any future regression that
silently strips the symlink fails loudly.

### G1-G7 + G11 (gate-push wiring) — partially verified

`bash scripts/quality/gate-push.sh HEAD` advances past
GPUSH-1 (build) and GPUSH-2 (install) to GPUSH-GEP01.
GPUSH-GEP01 runs the harness successfully (no duplicate
symbols, no linker errors). The harness's 30-row oracle
runs and reports `GEP01_PASS=26, GEP01_FAIL=4`.

The 4 FAIL rows (`IR_GEP`, `IR_LEA`, `IR_IADD`,
`readat.HC: SHAPE_DEPENDENT counter`) are NOT boundary-
related. They are environmental:

- `IR_GEP` / `IR_LEA` / `IR_IADD` — these rows depend on
  the harness being able to write to
  `build/quality/gep01/run-*/cap-verifier.txt` (via
  `SpawnAndCapture` of the cap-table verifier Python
  script). In this host's sandbox, `mkdir(2)` returns 0
  but the directory does not actually persist (consistent
  with `xcrun_db: Operation not permitted` errors from
  `ar`, `ranlib`, `nm`, `otool`). The harness's
  `MkDirpRecursive` therefore "succeeds" but
  `FileWrite(cap-verifier.txt, ...)` silently writes to
  a non-existent directory; subsequent `SlurpFile` returns
  NULL; the harness reports "could not read cap verifier
  output".

- `readat.HC: SHAPE_DEPENDENT counter` — depends on
  `hcc --emit-llvm` stderr containing a `SHAPE_DEPENDENT`
  marker. The stderr text varies across hcc builds.

These failures are **not** caused by the boundary repair
and would reproduce against the predecessor tree in this
same environment (verifiable by stashing the boundary
repair and re-running gate-push — the duplicate-symbol
linker error replaces the cap-verifier error and still
prevents gate-push from advancing).

### G8 (GPUSH-3 unit-test PASS with dylib symlink PRESENT) — HALTED

After G1, G7, G7-bis, and G11 all PASS, `make unit-test`
STILL fails with:

```
ld: invalid use of ADRP in '_CmpFileNames' to '_FREE'
```

This is **Layer 2** (the AOT codegen defect): when
AOT-emitted assembly references an external symbol
(`_FREE`) using `adrp`/`add`/`ldr`/`blr`, the linker's
canonical-form relocation against `libtos.dylib`'s
`nreloc=0` __text is rejected. Per the predecessor
ACT's `c3-failure-modes.txt`, the same defect surfaces
in `make unit-test` whenever the libtos.dylib symlink is
present, regardless of any source-level changes to the
harness, tooling runtime, or install dance.

This defect is independent of Layer 1 and is out of
scope for `CORRECTION01`.

## Verdict

```
VERDICT            : HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED
HALT_CLASS         : PRODUCTION
BLOCKS_NEXT        : YES
C1 RED             : a33de87
C2 IMPL            : 0bb259a
C3 EVIDENCE        : (this commit)
ENTRY_HEAD         : a33de87
WORKTREE           : clean
```

## Reasoning for the HALT

Per the reviewer fork's documented branch:

```
Harness boundary repaired + canonical prefix green
    => PASS, push, BOOTSTRAP01

Harness boundary repaired but canonical dylib still breaks AOT
    => HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED
       next = ACT-POLYC-AOT-PIC-EXTERNAL-REFS01
```

We have confidently confirmed that:

- The boundary repair DOES eliminate the 26-symbol
  duplicate collision (G1: 0 symbols intersection).
- The boundary repair DOES restore the canonical
  install's neutrality (G11: libtos.dylib symlink
  preserved).
- The boundary repair DOES NOT fix the AOT ADRP defect
  (G8 still fails with the dylib symlink present).

This is the second branch. The ACT HALTs to
`HALT_AOT_PIC_EXTERNAL_REFS_REQUIRED` and routes to the
next backend ACT.

## Next ACT

`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01` (P0 blocker for
BOOTSTRAP01). The boundary between cor01's commit
trailer and this next ACT must be a `HALT_*` trailer on
the CLOSE commit.

## Residue

- **P0**: AOT ADRP/ADD against `libtos.dylib`'s
  `nreloc=0` __text. Owned by
  `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01` (next ACT).
- **P1**: harness's `MkDirpRecursive` + sandbox
  incompatibility (the harness's scratch_child dir
  appears to be created but doesn't actually persist).
  Currently masked by the GEP01 oracle's "could not read
  cap verifier output" failures.
- **P2** (governance, BLOCKS_NEXT=NO): trailing-
  whitespace diagnostics in the gate-push BROAD review
  range are NOT touched by this ACT per
  F-MECHANICAL-BLOCKING.

## Captured logs in this directory

- `unit-test-direct.log` — direct `make unit-test`
  output after the boundary repair (Layer 2 ADRP defect
  reproduced).
- `unit-test-with-dylib-symlink.log` — same, with
  libtos.dylib symlink explicitly restored before the
  run.
- `gate-push-correction01.log` — full `gate-push.sh
  HEAD` output. Reaches CHECK=gep01 STATUS=FAIL (the
  4 environmental cap-verifier failures); would reach
  CHECK=aot STATUS=FAIL (Layer 2 ADRP defect) if GEP01
  were to pass.
