# ACT-POLYC-TOOLING-RUNTIME01-CORRECTION02 — Evidence Index

This directory collects evidence for the CORRECTION02 phase of
ACT-POLYC-TOOLING-RUNTIME01. CORRECTION02 fixes three defects
flagged by the post-CORRECTION01 reviewer:

1. **P1 runtime robustness**: `poll(2)`, `read(2)`, and `waitpid(2)`
   in `SpawnAndCapture` did not retry on `EINTR`, causing
   spurious failures when benign signals arrived during the
   drain loop. CORRECTION02 wraps each syscall in an
   EINTR-retry helper and adds the `errno` accessor via a
   tiny C shim (`src/holyc-lib/errno_shim.c`).

2. **P0 evidence truth**: AC13 (signal-killed child) was
   marked "PASS / not exercised" — a contradiction. CORRECTION02
   adds a SIGABRT child fixture and exercises it. AC22
   (missing executable) was marked "rc=-1" but the implementation
   actually returns rc=127; the matrix now reflects the real
   contract with the rc=127 ambiguity noted as P2 residue.

3. **P0 worktree hygiene**: `tools/quality/rt01-child-fixture`
   was an untracked binary in the source tree. CORRECTION02
   relocates the build target to `/tmp/` and documents the
   new build command in `tools/quality/rt01-child-fixture.c`.

## Files

### Witnesses

- `eintr-red.txt`, `eintr-red-raw.txt` — RED witness showing
  CORRECTION01 returning `rc=-1` under SIGALRM-spam
- `eintr-green.txt`, `eintr-green-stderr.log`,
  `eintr-green-stdout.log`, `eintr-green-both.log` — GREEN
  witnesses showing CORRECTION02 capturing full bytes with
  `rc=0` under identical SIGALRM-spam

### AC matrix

- `ac-matrix-correction02.txt` — corrected 31-row matrix with
  AC13 honestly PASS (SIGABRT fixture) and AC22 honestly
  PASS-with-documented-contract (rc=127)

### Conservation

- `regression-matrix.txt` — `runtime01-selftest 18/18 PASS`
  on CORRECTION02 libtos
- `gep-dogfood-rerun.txt` — `llvm-gep01-test.sh 30/30 PASS`
  on CORRECTION02 libtos (conservation)

### Residue & hygiene

- `residue-correction02.txt` — 8 residue items (P0 none,
  P1 PARSER-TERNARY-HANG01, LINUX-PORT01, args overrun,
  rc=127 ambiguity; P2 EOF hygiene, binary location,
  external-SIGTERM, child-pgroup detection)
- `patch-hygiene.txt` — `git diff --check` over full ACT range
  456b71c..HEAD; 5 historical findings (F14-protected) +
  CORRECTION02 patch itself is clean

### Source artifacts

- `signal-injector.c` — C host that calls SpawnAndCapture
  under SIGALRM-spam (used to build eintr-{red,green})
- `sig_child.c` — C child fixture with stderr/stdout-flood modes
- `sig_child_both.c` — C child fixture that floods BOTH streams
- `sig_child_abrt.c` — C child fixture that self-raises SIGABRT
  (used to exercise AC13)
- `ac13_simple.c` — minimal SpawnAndCapture harness for AC13

## Reproduction

```sh
# 1. Build libtos with CORRECTION02 (already done; verify):
cd src/holyc-lib
rm -f *.o libtos.a libtos.dylib
hcc --install-dir=$(pwd)/../../build/test-prefix -DHCC_LINK_SQLITE3 -lib tos all.HC
cc -O0 -c errno_shim.c -o errno_shim.o
ar rcs libtos.a all.o errno_shim.o
ranlib libtos.a
cc -dynamiclib -Wl,-install_name,$PWD/../../build/test-prefix/lib/libtos.0.0.1.dylib \
   all.o errno_shim.o -o libtos.dylib -lpthread -lc -lm
cp libtos.a libtos.dylib ../../build/test-prefix/lib/

# 2. Build the test binaries:
cd ../..
gcc -O0 -o /tmp/rt01-child-fixture tools/quality/rt01-child-fixture.c
gcc -O0 -o /tmp/sig_child          /tmp/sig_child.c
gcc -O0 -o /tmp/sig_child_both     /tmp/sig_child_both.c
gcc -O0 -o /tmp/sig_child_abrt     /tmp/sig_child_abrt.c
gcc -O0 -o /tmp/signal-injector    /tmp/signal-injector.c src/holyc-lib/libtos.a -lpthread
gcc -O0 -o /tmp/ac13_simple        /tmp/ac13_simple.c   src/holyc-lib/libtos.a -lpthread

# 3. Run EINTR RED-vs-GREEN:
/tmp/signal-injector /tmp/sig_child stderr-flood-4194304
#   CORRECTION02: rc=0 out=0 err=4194304  (GREEN)

# 4. Run AC13:
/tmp/ac13_simple /tmp/sig_child_abrt sigabrt
#   rc=134 (= 128 + SIGABRT)              (PASS)

# 5. Run AC22:
/tmp/ac13_simple /nonexistent/path/foo
#   rc=127                                  (PASS, documented contract)

# 6. Run full conservation:
pkill -9 -f hcc 2>/dev/null; sleep 1
hcc --install-dir=$(pwd)/build/test-prefix tools/quality/runtime01-selftest.HC \
  -o /tmp/runtime01-selftest
/tmp/runtime01-selftest --child=/tmp/rt01-child-fixture \
  --hcc=$(pwd)/hcc --llvm-install-dir=$(pwd)/build/test-prefix
#   RT01_PASS=18 / RT01_FAIL=0

bash scripts/quality/llvm-gep01-test.sh
#   GEP01_PASS=30 / GEP01_FAIL=0
```

## Linked commits

- Subject: `ACT-POLYC-TOOLING-RUNTIME01-CORRECTION02`
- Trailers:
  ```
  ACT: ACT-POLYC-TOOLING-RUNTIME01-CORRECTION02
  ACT-Phase: CLOSE
  ACT-Verdict: PASS
  ACT-Supersedes: ACT-POLYC-TOOLING-RUNTIME01-CORRECTION01
  ACT-Corrected-Verdict: PASS_WITH_NONBLOCKING_RESIDUE
  ```
