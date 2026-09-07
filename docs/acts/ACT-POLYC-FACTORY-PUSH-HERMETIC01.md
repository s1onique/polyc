# ACT-POLYC-FACTORY-PUSH-HERMETIC01

**Title:** Make the Push Gate Reproduce the PolyC Native Baseline Without
Requiring a Global Install

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors:**

- `ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION02` (PASS)
- `ACT-POLYC-IR-BOUNDARY01` (PASS_WITH_NEXT_ACT_DECISION)
- `ACT-POLYC-LLVM-SPIKE01` (`HALT_PREDECESSOR_BASELINE_RED`)
- `ACT-POLYC-IR-BOUNDARY02` (`HALT_PUSH_GATE_RED`, this ACT's mandate)

**Class:** TOOLING / QUALITY-GATES

**Production semantic changes:** **FORBIDDEN** (none made)

**IR / ABI / LLVM authorization:** **NONE**

**Test skipping / failure-marker weakening authorization:** **NONE**

**Gate criterion modification authorization:** **NONE** — only the build
prefix and the order of operations change; the PASS/FAIL markers
inspected by `run_check` are unchanged.

---

## 0. Mission

Make `scripts/quality/gate-push.sh <commit>` reproduce the PolyC native
baseline (AOT unit + JIT unit + LSP + diff-check) on a worktree where
nothing has been installed under `/usr/local`, without touching
`/usr/local`, without `sudo`, and without weakening any test or any
gate criterion.

Concretely: the gate must, on the historical healthy control
`60811e60`, exit 0 and emit `VERDICT=PASS`.

---

## 1. Why

`ACT-POLYC-IR-BOUNDARY02` shipped a correct compiler repair (commit
`404644d`) and a complete closure document. The product is GREEN under
the hermetic `build/recon-prefix` technique used by `ACT-POLYC-LLVM-SPIKE01`
and recorded in `evidence/llvmspike01/`. However, the push gate
itself is still RED on this workstation, because:

1. `scripts/quality/gate-push.sh` runs `make clean && make` with no
   `INSTALL_PREFIX` override, so CMake compiles hcc with
   `-DCMAKE_INSTALL_PREFIX=/usr/local`.
2. The freshly compiled `./hcc` therefore defaults to
   `--install-dir=/usr/local` when invoked by `make unit-test` and
   `make jit-unit-test`.
3. The test harness then opens `/usr/local/include/tos.HH`, which does
   not exist on this unprivileged workstation.
4. `make lsp-test` is unaffected because it already creates its own
   local `build/test-prefix` and passes `--install-dir` explicitly.

`ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION02` established the gate's
correct invariant: do not weaken markers; do not skip tests; do not
silently fall back. The right repair is therefore to make the gate's
build/install/test chain hermetic, not to relax the gate.

`ACT-POLYC-IR-BOUNDARY02`'s closure recorded the verifier-level
hermetic evidence but did not run the canonical push gate against
the implementation commit. The next gate run that needs the gate to
be green is this one.

---

## 2. Scope

### allowed

- `scripts/quality/gate-push.sh` — change the `build` and the
  installation step to use a disposable local prefix inside the gate's
  temporary worktree.
- `docs/acts/ACT-POLYC-FACTORY-PUSH-HERMETIC01.md` — this document.
- `evidence/pushhermetic01/` — RED/GREEN witnesses.

### forbidden

- Modifying the `Makefile`, `src/CMakeLists.txt`, or any
  compiler/runtime source.
- Modifying `scripts/quality/gate-fast.sh`.
- Modifying the `run_check` marker logic (`FAILED:`, `Failed to compile`,
  `Failed to run`).
- Modifying `make unit-test`, `make jit-unit-test`, `make lsp-test`,
  or any per-test Makefile recipe.
- Installing anything under `/usr/local`.
- Adding dependencies.
- Using network.
- Skipping or marking tests as expected-fail.
- Broadening or relaxing any failure marker.

## 3. Entry gate

```text
$ git branch --show-current
main
$ git status --short
(empty)
$ git rev-parse HEAD
be7451f64cb1c551e085f1a5a1732f8367b6399a
```

Required state for the ACT:

- on `main`;
- worktree clean (only this ACT's own docs/evidence allowed when
  started).

---

## 4. Principal RED

```text
$ scripts/quality/gate-push.sh 60811e60a70b3adbe107b93449f0d85d40c75a54
POLYC_GATE=push
SUBJECT=60811e60a70b
... [build phase output] ...
CHECK=build STATUS=PASS
cd ./src/tests && ../../hcc ./run.HC -o test-runner && ./test-runner && cd ../../
ERROR: Failed to open file: /usr/local/include/tos.HH
make: *** [unit-test] Error 1
CHECK=aot STATUS=FAIL
REASON=aot exited with status 2
VERDICT=FAIL
```

(Recorded verbatim in `evidence/pushhermetic01/red_60811e6_aot.txt`.)

The same RED is observed for any subject commit: the gate's
`make clean && make` line hard-codes the host's `/usr/local` prefix
into hcc, and the downstream `make unit-test` then fails because
the test runner opens `tos.HH` from that prefix.

This is the gate's *exact* definition of RED on this workstation:

- `CHECK=build` is green (compiler builds fine when cmake is on
  PATH; cmake is supplied by the caller's PATH — a normal shell
  setup requirement, not a gate dependency).
- `CHECK=aot` is red because of one missing host file.

The hermetic fix targets the AOT/JIT phases only; `CHECK=build` and
`CHECK=lsp` are already hermetic-or-PATH-dependent and stay
unchanged.

---

## 5. Implementation boundary

The minimum change is to make the gate build and install hcc into a
disposable local prefix inside the gate's temporary worktree, before
running `make unit-test` and `make jit-unit-test`.

Conceptually:

```sh
gate_prefix="$tmp/build/gate-prefix"

# 1. Build hcc with the local prefix compiled in.
make clean
make INSTALL_PREFIX="$gate_prefix"

# 2. Install hcc, tos.HH, libtos.a, libtos.dylib into that prefix.
make install INSTALL_PREFIX="$gate_prefix"

# 3. Now the freshly-compiled ./hcc defaults to --install-dir=$gate_prefix,
#    which contains the installed tos.HH. Tests can run.
make unit-test
make jit-unit-test
make lsp-test   # already hermetic; unchanged
```

The current gate has only one `make clean && make` step. The change
splits it into:

```sh
# before:
run_check build sh -c 'make clean && make'

# after:
run_check build  sh -c 'make clean && make INSTALL_PREFIX="$gate_prefix"'
run_check install sh -c 'make install INSTALL_PREFIX="$gate_prefix"'
run_check aot    sh -c 'make unit-test'           # uses ./hcc whose
run_check jit    sh -c 'make jit-unit-test'       # default --install-dir
                                                  # is now $gate_prefix
run_check lsp    sh -c 'make lsp-test'            # unchanged
```

Deliberately *not* included:

- No change to `make unit-test`, `make jit-unit-test`, `make lsp-test`
  recipes: those recipes do not need to know about the gate's prefix.
- No `--install-dir` flag injection: `make install` already wires
  `INSTALL_PREFIX` through `CMAKE_INSTALL_PREFIX`; the compiler
  binary therefore picks up the right default.
- No change to `run_check`'s marker logic.
- No sudo, no global install.
- No PATH manipulation inside the gate: the gate inherits PATH from
  its caller (consistent with how `gate-fast.sh` and the `unit-test`
  recipes themselves work today).

---

## 6. Acceptance criteria

```text
AC01  gate-push 60811e60a70b VERDICT=PASS
AC02  gate-push 404644d  VERDICT=PASS
AC03  /usr/local/include/tos.HH may remain absent; gate still PASSES
AC04  worktree remains clean after both gate runs (no source change)
AC05  run_check markers inspected are unchanged:
        - exit status != 0     -> FAIL
        - 'FAILED: ' present   -> FAIL
        - 'Failed to compile'  -> FAIL
        - 'Failed to run'      -> FAIL
AC06  diff-check phase uses the same parent-vs-subject git diff as before
AC07  no /usr/local mutation during the run
```

Each AC is checkable by a single concrete command.

---

## 7. Conservation gates

- `make gate-fast` must remain PASS on `main` (no change to gate-fast).
- The push gate's `CHECK=build` and `CHECK=lsp` behaviour must remain
  identical to before this ACT.
- `make unit-test` and `make jit-unit-test` recipes must remain
  unchanged.

---

## 8. Halt taxonomy

- `HALT_PUSH_GATE_RED` — only when AC01/AC02 cannot be made to PASS
  on a clean worktree without violating forbidden scope.
- `HALT_SCOPE_EXPANSION_REQUIRED` — only if the patch necessarily
  touches a forbidden area.

---

## 9. Residue

Pre-declared:

- P1: the gate inherits cmake-on-PATH from its caller. A future ACT
  could make this fully self-contained by vendoring or wrapping
  cmake, but that is not this ACT's scope.
- P2: the gate's hermetic prefix lives under
  `$TMPDIR/polyc-gate.XXXXXX/build/gate-prefix`. Cleaning is handled
  by the existing `cleanup` trap on the worktree root; the prefix is
  a subdirectory and is therefore removed with the worktree.

---

## 10. Commit topology

A single commit:

```text
1. tooling(gate-push): use a hermetic local install prefix
```

The implementation is a small mechanical edit to
`scripts/quality/gate-push.sh`.

---

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`, plus:

- RED reproduction (`evidence/pushhermetic01/red_60811e6_aot.txt`)
- Implementation diff (`evidence/pushhermetic01/diff.txt`)
- GREEN runs for both subjects
  (`evidence/pushhermetic01/green_60811e6.txt`,
   `evidence/pushhermetic01/green_404644d.txt`)
- This ACT document.
