# ACT-POLYC-TOOLING-RUNTIME01-CORRECTION03 — Evidence Index

This directory collects evidence for the CORRECTION03 phase of
ACT-POLYC-TOOLING-RUNTIME01. CORRECTION03 fixes one P0 build-system
defect, two P1 platform/evidence defects, and one P2 documentation
defect that were flagged in the post-CORRECTION02 review:

1. **P0 build integration**: the CORRECTION02 CMake install step
   contained a literal `&&` in `execute_process(COMMAND ...)`,
   which CMake does NOT interpret as a shell operator on POSIX.
   The CORRECTION02 GREEN runtime was therefore built via manual
   shell commands, not through the committed install path.
   CORRECTION03 splits into separate execute_process calls,
   adds COMMAND_ERROR_IS_FATAL ANY, and adds the libtos.dylib
   symlink that the downstream `-ltos` linkage requires.

2. **P1 platform contract**: the CORRECTION02 install step passed
   `-D__APPLE__` to hcc unconditionally, lying about the platform.
   CORRECTION03 confines `-D__APPLE__` and the errno_shim
   compilation to the `if(APPLE)` branch and `message(FATAL_ERROR)`s
   on non-Apple, so we never silently produce a forged-Apple libtos.

3. **P1 evidence truth**: the CORRECTION02 acceptance matrix claimed
   "31/31 PASS" while enumerating AC01..AC33 (with the last two
   marked DEFERRED). CORRECTION03 makes the count and the enumeration
   consistent: AC01..AC31 = 31, all PASS; Linux/Windows portability
   moved to residue.

4. **P2 documentation**: the WaitPidIntr comment said "0 on reap"
   but the implementation returns the waitpid(2) value (>=0 on
   success). CORRECTION03 corrects the comment.

## Files

### Witnesses

- `cmake-configure.log` — fresh cmake configure with -DHCC_PATH,
  -DHCC_LINK_SQLITE3, -DCMAKE_INSTALL_PREFIX pointing at /tmp/c03-install
- `cmake-install.log` — fresh cmake --install; exit=0; the corrected
  install steps (hcc -lib, cc errno_shim.c, ar r, ranlib,
  cc -dynamiclib, ln -sf) all run independently; libtos.a and
  libtos.dylib are installed
- `libtos-installed-symbols.txt` — nm probe of the INSTALLED
  libtos.a: shows _Errno, _PollIntr, _ReadIntr, _WaitPidIntr,
  _SpawnAndCapture, _WaitDecode, _FileExists
- `regression-matrix.txt` — runtime01-selftest built against
  the installed prefix, runs 18/18 PASS
- `eintr-red-argv-broken.txt` — RED witness showing why the
  CORRECTION02 install step would have failed if executed
  (the `&&` is passed as a literal argv member to ar)
- `eintr-green-c03-install.log` — GREEN witness: signal-injector
  linked against the INSTALLED libtos.a, 4 MiB stderr flood under
  SIGALRM-spam returns rc=0 with exact byte count

### AC matrix

- `ac-matrix-correction03.txt` — AC01..AC31 = 31/31 PASS,
  consistent with the enumeration; Linux/Windows portability
  in residue (not AC32/AC33)

### Residue & hygiene

- `residue-correction03.txt` — 8 residue items (P0 none, P1 PARSER,
  LINUX, R8 reveals CORRECTION02 partial selftest, etc.)
- `patch-hygiene.txt` — git diff --check over full ACT range

## Reproduction

The mandatory witness is the actual cmake --install path:

```sh
# 1. Configure
rm -rf /tmp/c03-build /tmp/c03-install
mkdir -p /tmp/c03-build /tmp/c03-install
cp hcc /tmp/hcc    # hcc binary must be reachable by HCC_PATH
cmake -S src -B /tmp/c03-build \
  -DCMAKE_INSTALL_PREFIX=/tmp/c03-install \
  -DHCC_PATH=/tmp/hcc \
  -DHCC_LINK_SQLITE3=ON

# 2. Install (executes the corrected install(CODE ...) blocks)
cmake --install /tmp/c03-build

# 3. Inspect installed libtos.a
nm /tmp/c03-install/lib/libtos.a | grep ' T ' | grep -E '_(Errno|PollIntr|SpawnAndCapture)\b'

# 4. Build runtime01-selftest against the installed prefix
hcc --install-dir=/tmp/c03-install \
  tools/quality/runtime01-selftest.HC \
  -o /tmp/runtime01-selftest-c03

# 5. Run it
/tmp/runtime01-selftest-c03 \
  --child=/tmp/rt01-child-fixture \
  --hcc=$(pwd)/hcc \
  --llvm-install-dir=/tmp/c03-install

# Expected: RT01_PASS=18 RT01_FAIL=0 STATUS=PASS

# 6. Verify EINTR green against the installed prefix
gcc -O0 -o /tmp/signal-injector-c03 /tmp/signal-injector.c \
  /tmp/c03-install/lib/libtos.a -lpthread
/tmp/signal-injector-c03 /tmp/sig_child stderr-flood-4194304
# Expected: rc=0 out=0 err=4194304
```

## Linked commits

- Subject: `ACT-POLYC-TOOLING-RUNTIME01-CORRECTION02`
- Trailers:
  ```
  ACT: ACT-POLYC-TOOLING-RUNTIME01-CORRECTION03
  ACT-Phase: CLOSE
  ACT-Verdict: PASS
  ACT-Supersedes: ACT-POLYC-TOOLING-RUNTIME01-CORRECTION02
  ACT-Corrected-Verdict: PASS_WITH_NONBLOCKING_RESIDUE
  ```
