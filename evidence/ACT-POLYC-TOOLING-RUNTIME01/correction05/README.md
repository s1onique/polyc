# ACT-POLYC-TOOLING-RUNTIME01-CORRECTION05 — Evidence Index

Bounded build-integrity correction. No production semantic
change beyond the producer-cleanup invariant; no modification
of any pre-existing evidence file (F14 doctrine honored).

## What CORRECTION05 fixes

### P0-A: Stale-producer false GREEN

The CORRECTION03 install step permitted `hcc -lib` to exit
non-zero (because hcc's own dylib-link attempt fails on
_Errno pre-shim). The downstream guard `if(NOT EXISTS all.o)`
was supposed to ensure the producer actually ran. But
`LIBTOS_BUILD_DIR` was never cleaned at install time, so:

  - First cmake --install: fresh dir, hcc produces all.o,
    install succeeds.
  - Second cmake --install: dir still has yesterday's all.o.
    hcc is invoked, fails BEFORE producing a new all.o.
    CMake warns ("hcc -lib exited with code X; this is
    expected..."), then checks `if(NOT EXISTS all.o)`. The
    stale all.o exists. Install proceeds using yesterday's
    object. FALSE GREEN.

Reproduced by the negative test in
`stale-producer-negative-test.txt`.

FIX: Added `file(REMOVE all.o errno_shim.o libtos.a
libtos.0.0.1.dylib)` as the first install(CODE) step,
before invoking hcc. After this, `if(NOT EXISTS all.o)`
genuinely tests that *this* hcc invocation produced all.o.

### P0-B: Mechanical negative test

The negative test (sabotaged hcc + stale all.o) MUST now
cause the install to FATAL_ERROR with the message
"hcc -lib did not produce all.o". Verified end-to-end on
2026-09-12, see `stale-producer-negative-test.txt`.

### P1: F14 evidence-contract reconciliation

CORRECTION04 (the previous ACT) modified three files in
correction03/ (ac-matrix-correction03.txt, eintr-red-argv-
broken.txt, patch-hygiene.txt). Under F14, those were
immutable historical evidence. CORRECTION05 designates
CORRECTION05's own packet as the authoritative reconciliation
going forward; it does NOT revert the c04 mutations but
documents them as a known exception (the alternative was a
revert + reopen which would have left the closure evidence
gap in place indefinitely).

### P1: Hygiene truth

CORRECTION04 incorrectly stated "0 CORRECTION03-introduced".
The correct statement is:

  C03 introduced 3 hygiene findings:
    1. ac-matrix-correction03.txt:79 EOF blank   → remediated by c04
    2. eintr-red-argv-broken.txt:30 EOF blank    → remediated by c04
    3. cmake-install.log:15 trailing WS          → P2 residue (verbatim argv)

  C04 introduced 0 findings.
  C05 introduces 0 findings (this commit).

### P2: Date typo

CORRECTION03/CORRECTION04 evidence files reference
"2025-09-12". Actual date is 2026-09-12. Only NEW c05
evidence is corrected (F14 forbids rewriting historical
captions in older files).

### P2: Identity binding

CORRECTION04's closure-summary.txt identified HEAD as
`8d1d961` but the real HEAD after its third follow-up was
`b13a580`. CORRECTION05's closure summary binds to the
real final HEAD at commit time.

## Files

- `stale-producer-negative-test.txt` — full reproduction of
  the bug + verification of the fix
- `install-prefix-witness.txt` — direct `test -f/-L/readlink`
  triple against a fresh install prefix
- `install-rc-table.txt` — per-step return codes
- `hygiene-rollup.txt` — classified diagnostic table
- `f14-reconciliation.txt` — documents the c04 mutation
  exception and c05's authoritative role
- `closure-summary.txt` — bounded verdict + conservation
  + next ACT

## Reproduction

```sh
# Negative test (must FAIL the install):
mkdir -p /tmp/c05-red /tmp/c05-red-install
cp ./all.o /tmp/c05-red/all.o
cmake -S src -B /tmp/c05-red \
  -DCMAKE_INSTALL_PREFIX=/tmp/c05-red-install
# Inject sabotage AFTER hcc is installed:
python3 -c "
import re
with open('/tmp/c05-red/cmake_install.cmake') as f: c = f.read()
sab = '''
  file(WRITE \"/tmp/c05-red-install/bin/hcc\" \"#!/bin/sh\\nexit 1\\n\")
  file(CHMOD \"/tmp/c05-red-install/bin/hcc\" FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
'''
c = c.replace('if(CMAKE_INSTALL_COMPONENT STREQUAL \"Unspecified\" OR NOT CMAKE_INSTALL_COMPONENT)\n  \n        file(REMOVE',
              sab + 'if(CMAKE_INSTALL_COMPONENT STREQUAL \"Unspecified\" OR NOT CMAKE_INSTALL_COMPONENT)\n  \n        file(REMOVE')
with open('/tmp/c05-red/cmake_install.cmake', 'w') as f: f.write(c)
"
cmake --install /tmp/c05-red
# Expected: rc != 0; /tmp/c05-red-install/lib/ stays empty;
# CMake error "hcc -lib did not produce all.o".

# Conservation test (real hcc, fresh build dir):
rm -rf /tmp/c05-conserv /tmp/c05-conserv-install
cmake -S src -B /tmp/c05-conserv \
  -DCMAKE_INSTALL_PREFIX=/tmp/c05-conserv-install \
  -DHCC_PATH=$(pwd)/hcc -DHCC_LINK_SQLITE3=ON
cmake --install /tmp/c05-conserv
# Expected: rc=0; libtos.a + libtos.0.0.1.dylib + libtos.dylib
# symlink all present; libtos.a contains _Errno.
```
