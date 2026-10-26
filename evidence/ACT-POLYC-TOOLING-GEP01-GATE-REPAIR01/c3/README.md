# ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01 — C3 (EVIDENCE)

## Identity

```text
git branch --show-current  -> main
ENTRY_HEAD                 -> c734c9c31b3e3a53d6878e67b76809470ac9e1e0
                               (the predecessor's CLOSE; left intact)
RED   commit               -> 81168dd
IMPL  commit               -> 4ee3398
```

## Headline

The mandatory `gep01` gate step that blocked the push of `c734c9c` now
passes, and the **unmodified** complete pre-push gate reaches `VERDICT=PASS`.

```text
$ bash scripts/quality/gate-push.sh HEAD     (rc=0)
POLYC_GATE=push
CHECK=build      STATUS=PASS
CHECK=install    STATUS=PASS
CHECK=gep01      STATUS=PASS      <- was FAIL before this ACT
CHECK=aot        STATUS=PASS
CHECK=jit        STATUS=PASS
CHECK=lsp        STATUS=PASS
CHECK=diff-check STATUS=PASS
VERDICT=PASS
```

The gate script itself was not modified:

```text
$ git diff --name-only c734c9c..HEAD -- scripts/quality/gate-push.sh
(empty)
```

## Acceptance matrix

See `acceptance-matrix.txt` for the full per-AC detail. Summary:

```text
AC01  PASS   GEP01_PASS=30  GEP01_FAIL=0  STATUS=PASS
AC02  PASS   30/30 rows identical to the frozen legacy oracle; 0 FAIL
AC03  PASS   verifier default preserved; both legacy shell callers PASS
AC04  PASS   NC-A: reverting io_defs.HH restores the exact 26/4 RED
AC05  PASS   NC-B: verifier -> non-LLVM compiler fails with rc=-11 named
AC06  PASS   capability rows carry the verifier's stderr + compiler + rc
AC07  PASS   unit-test rc=0, jit-unit-test rc=0, lsp-test rc=0 (43/43)
AC08  PASS   gate-fast VERDICT=PASS (rc=0)
AC09  PASS   unmodified gate-push VERDICT=PASS (rc=0)
AC10  PASS   factory-v2-test 53/0, factory-append-only-test 11/0
AC11  PENDING at C3 by design -- requires the CLOSE commit; measured in c4/
```

## Negative controls

Both controls are captured, and both demonstrate that the repair is
SENSITIVE to the two distinct defects -- not merely that it turns the
harness green.

### NC-A — `nc-a-filewrite-reverted.txt`

Reverting **only** the `io_defs.HH` `FileWrite` declaration (nothing else)
restores the C1 RED exactly:

```text
FAIL  readat.HC: SHAPE_DEPENDENT counter = ? (expected >= 1): shape_dependent marker not found in stderr
FAIL  IR_GEP = REJECTED (sibling opcode still rejected): cap-table verifier failed (rc=0, compiler=./hcc); verifier stderr:
FAIL  IR_LEA = REJECTED (sibling opcode still rejected): cap-table verifier failed (rc=0, compiler=./hcc); verifier stderr:
FAIL  IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset): cap-table verifier failed (rc=0, compiler=./hcc); verifier stderr:
GEP01_PASS=26
GEP01_FAIL=4
STATUS=FAIL
```

### NC-B — `nc-b-verifier-wrong-compiler.txt`

Pointing the verifier at a non-LLVM compiler fails, through BOTH the
positional argument and the `POLYC_HCC` environment variable:

```text
FAIL  hcc --print-cap-table exited non-zero (rc=-11) for /private/tmp/hcc.nonllvm.bak: <no output>
FAIL  hcc --print-cap-table was killed by a signal or crashed (rc=-11); a non-LLVM build does not implement --print-cap-table (the dispatch is inside #ifdef HCC_ENABLE_LLVM in src/main.c)
FAIL  could not load capability table from hcc --print-cap-table
rc=1
```

Compare with the C1 RED, whose diagnostic was the undiagnosable
`hcc --print-cap-table exited non-zero: ` with an EMPTY tail.

## Environment note (not a defect)

Two legacy shell scripts default `HCC_INSTALL_DIR` to `/tmp/polyc-install`,
which does not exist on this host. They therefore fail with
`Failed to open file: /tmp/polyc-install/include/tos.HH` unless the
install dir is supplied. With `HCC_INSTALL_DIR` pointed at the canonical
test prefix, both PASS:

```text
llvm-intops01-test.sh      INTOPS01 PASS=4  FAIL=0  (rc=0)
llvm-byte-memory01-test.sh  BYTE_MEMORY01 PASS=37 FAIL=0 (rc=0)
```

This is a pre-existing environment property of the legacy scripts and is
unrelated to this ACT.

Similarly, `make jit-unit-test` / `make lsp-test` initially failed with a
CMake `CMakeDetermineCXXCompiler` `configure_file` error caused by a
stale `build/test-prefix-install-build` CMake cache in the warm tree.
Removing that stale directory makes both pass. Also unrelated to this ACT
(no file this ACT touches participates in CXX compiler detection).

## Files

```text
acceptance-matrix.txt          per-AC detail
ac02-oracle-preservation.txt   AC02 row-set comparison
ac06-stderr-surfaced.txt       AC06 diagnostic comparison
gep01-green-run.txt            the 30/0 harness run
nc-a-filewrite-reverted.txt    NC-A
nc-b-verifier-wrong-compiler.txt  NC-B
gate-push-full.log             the unmodified full push gate (2302 lines)
gate-fast.log
factory-v2-test.log
factory-append-only-test.log
unit-test.log  jit-unit-test.log  lsp-test.log
llvm-intops01-test.log  llvm-byte-memory01-test.log
```
