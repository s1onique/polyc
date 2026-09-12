# c2 IMPL evidence — ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01

Implementation surface, scoped exactly to the three defects frozen
in `c1/`. No compiler / parser / IR / LLVM / ABI changes.

## Files changed (production)

| File                                                 | Lines (pre -> post) | Why                                   |
|------------------------------------------------------|---------------------|---------------------------------------|
| `Makefile`                                           | 149 -> 215          | +`test-prefix-install`, +`llvm-gep01-test`; `lsp-test` depends on `test-prefix-install`. |
| `scripts/quality/gate-push.sh`                       | 480 -> 477          | GPUSH-2 -> `make test-prefix-install`; GPUSH-GEP01 -> `make llvm-gep01-test`. |
| `scripts/quality/factory-halt-classification-check.sh` | 187 -> 18         | Thin launcher only; substantive logic in `.py`. |
| `scripts/quality/factory-halt-classification-test.sh`  | 182 -> 15         | Thin launcher only; matrix in `.py`. |
| `scripts/quality/factory-halt-classification.py`     | NEW (244 LOC)      | Substantive trailer-classification logic + 12-fixture regression matrix. |

No file under `src/`, no compiler source, no IR/parser/LLVM ABI.

## D1 — Makefile binding (canonical GEP01 target)

The new `make llvm-gep01-test` target:

1. depends on `test-prefix-install` (the canonical install seam);
2. compiles `tools/quality/llvm-gep01-test.HC` from source via `./hcc`;
3. runs the resulting binary against the fresh install prefix;
4. propagates its real exit status;
5. removes the binary on exit so no stale artifact can satisfy the gate.

The build/test-prefix/ tree is the canonical install prefix and is
rebuilt fresh per invocation. AC02 satisfied. AC07 satisfied.

## D1 — gate-push binding (mandatory GPUSH-GEP01 step)

`gate-push.sh` GPUSH-2 now invokes the same `make test-prefix-install`
target the Makefile exposes, and adds an immediately-following
GPUSH-GEP01 step that invokes `make llvm-gep01-test`. Both steps fail
closed on any non-zero exit. AC05 satisfied.

The added lines are below the gate-push baseline budget (488 -> after
shrinking redundant comments we land at 477, under the 480 baseline).
shell-loc-gate stays PASS for the new state.

## D2 — canonical install seam (`make test-prefix-install`)

The new target runs a clean CMake configure against
`./build/test-prefix-install-build` with
`-DCMAKE_INSTALL_PREFIX=$(CURDIR)/build/test-prefix` and then
`make install` in that build dir. The CMake install machinery invokes
the seven-step `install(CODE ...)` dance in `src/CMakeLists.txt`,
which:

1. removes stale producer outputs (CORRECTION05 fresh-output invariant);
2. runs `hcc -lib tos` to produce `all.o`;
3. compiles `errno_shim.c` -> `errno_shim.o`;
4. re-archives `libtos.a` with `errno_shim.o`;
5. ranlib the archive;
6. cc -dynamiclib with `errno_shim.o` -> `libtos.0.0.1.dylib`;
7. installs both archive + dylib + the `libtos.dylib` symlink into the
   prefix.

`lsp-test` and `gate-push.sh` GPUSH-2 both delegate to this target.
AC09, AC10 satisfied (no direct `hcc -lib tos` callers remain).

The fresh-output invariant (stale producer defense, AC15) is preserved
verbatim: the `install(CODE "file(REMOVE ...) ")` step in
`src/CMakeLists.txt` lines 269-275 removes stale artifacts before each
install, so a failed `hcc -lib` cannot be papered over by yesterday's
`all.o`.

## D3 — halt-classification logic moved to Python

The substantive 12-case matrix and all trailer-parsing logic now
live in `scripts/quality/factory-halt-classification.py` (244 LOC).
The two .sh scripts are thin launchers (`exec python3 ...`) under 20
LOC each. The Python implementation preserves the prior shell's exact
line-oriented output format (`STATUS=`, `MODE=`, `ACT=`, `PHASE=`,
`VERDICT=`, `HALT_CLASS=`, `BLOCKS_NEXT=`, optional `REASON=`),
so existing call-sites in `gate-fast.sh` and `gate-push.sh` work
unchanged. AC16, AC17, AC18, AC19 satisfied.

Python is the chosen non-shell implementation per ACT §6 order: PolyC
would have introduced a Factory-bootstrap cycle (the matrix runs in
gate-fast, before any PolyC harness can be built), but Python is
already an established, required host facility in the repository
(`scripts/quality/llvm-cap-table-verifier.py` is invoked by
`llvm-intops01-test.sh` and `llvm-byte-memory01-test.sh` today). No
new dependency. No cyclic dependency. AC20 satisfied (logic is not
merely fragmented; the substantive code moved to a non-shell
implementation wholesale).

## Semantic conservation

The matrix is bit-for-bit equivalent to the prior shell implementation:

```text
R1  HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO  -> PASS
R2  HALT_CLASS=PRODUCTION / BLOCKS_NEXT=YES -> PASS
R3  HALT_* missing HALT_CLASS               -> FAIL
R4  HALT_* missing BLOCKS_NEXT              -> FAIL
R5  PASS verdict carrying BLOCKS_NEXT=YES   -> FAIL
R6  GOVERNANCE / YES combination            -> FAIL
R7  PRODUCTION / NO combination             -> FAIL
R8  PASS verdict, no trailers               -> PASS
R9  DEPENDENCY / YES                        -> PASS
R10 DEPENDENCY / NO                         -> PASS
R11 non-ACT commit                          -> PASS (MODE=NON_ACT)
R12 RED phase, HALT_DRAFT, no trailers      -> PASS
```

12/0 PASS expected.

## Out of scope

The ACT explicitly forbids:

- changes to `src/`, `src/CMakeLists.txt`, `src/holyc-lib/`,
  `tools/quality/` (other than what is in this file), or any compiler
  semantic / IR / LLVM / ABI work;
- rewriting of MIGRATE-GEP01 / RUNTIME01 / MECHANICAL-BLOCKING01 /
  OPTION-W evidence;
- new shell files grandfathered into baseline.txt;
- raising the shell-loc-gate threshold.

None of those happened.
