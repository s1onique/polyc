# c1 RED evidence — ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01

Mechanically captured **before** any implementation change, on the merged
HEAD `8f398be`. Each defect is reproduced by an isolated artifact so the
REPAIR can be cross-checked.

## Contents

| File                            | Defect | Witness                                                                            |
|---------------------------------|--------|------------------------------------------------------------------------------------|
| `integration-topology.txt`      | base   | Two-parent merge, both parents ancestor, replace empty, worktree clean.            |
| `d1-gep-unbound.txt`            | D1     | `tools/quality/llvm-gep01-test.HC` EXISTS, no Makefile/CMake/shell binding found.  |
| `d1-gate-graph-search.txt`      | D1     | Same as above; repeated for the §15 packet checklist.                              |
| `d2-install-callgraph.txt`      | D2     | Two direct `hcc -lib tos` callers (Makefile `lsp-test`, `gate-push.sh` GPUSH-2).    |
| `d2-errno-red-shape.txt`        | D2     | Seven-step CMake install dance missing in direct callers (textual proof).          |
| `d2-errno-live-red.txt`         | D2     | **Live** `nm src/holyc-lib/libtos.a` shows `_Errno` `U` undefined (post-shim).     |
| `d3-shell-loc-red.txt`          | D3     | `wc -l` + `shell-loc-gate.sh`; both files NEW and >50 LOC; gate FAIL.               |
| `baseline-gates.txt`            | base   | factory-v2/append-only/closure-status/halt-classification PASS; shell-loc FAIL.    |

## Mechanical summary (paste-friendly)

```text
D1_SOURCE_EXISTS      = YES    (tools/quality/llvm-gep01-test.HC, 1328 LOC)
D1_SHELL_HARNESS      = NO     (scripts/quality/llvm-gep01-test.sh deleted)
D1_GATE_BINDING       = NO     (no Makefile/CMake/shell reference)

D2_CALLERS_DIRECT_HCC_LIBS = 2  (Makefile lsp-test, gate-push GPUSH-2)
D2_INSTALL_DANCE_SKIPPED   = 6  (steps 2..7 from src/CMakeLists.txt)
D2_ERRNO_SYMBOL_LIVE       = U _Errno  (nm src/holyc-lib/libtos.a)

D3_CHECK_LOC          = 187    (limit 50)
D3_TEST_LOC           = 182    (limit 50)
D3_SHELL_LOC_GATE     = FAIL   (exit=1)

MERGE_HAS_TWO_PARENTS = YES
TRACK_A_ANCESTOR      = YES
TRACK_B_ANCESTOR      = YES
GIT_REPLACE_EMPTY     = YES
```

## Disposition

All three defects reproduced against the real production seam. Per F3 the
implementation phase (C2) is now authorised to proceed.
