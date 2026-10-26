# HANDOFF -- ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01

Factory-Version: 2

## Result

The LLVM GEP01 qualification harness reached 30/30 for the first time, and
the unmodified complete pre-push gate now reaches `VERDICT=PASS`.

The four failing rows that three predecessor ACTs had recorded as a single
pre-existing P1 residue (`GEP01_PASS=26 / GEP01_FAIL=4`) were, in fact, TWO
independent defects hiding behind one generic message. Both are repaired,
and the repair is proven sensitive to each defect by negative control.

The predecessor CLOSE `c734c9c` was left intact; its push was blocked
solely by the gate this ACT repairs.

## What changed

Three files, all inside the ACT's authorized scope:

- `src/holyc-lib/io_defs.HH` — the `FileWrite` 4th parameter was declared
  as `Bool append=FALSE` while `io.HC` and the canonical public header
  `tos.HH` both declare `I64 flags=O_CREAT|O_RDWR`. A caller compiled
  against this declaration-only header therefore passed the boolean `FALSE`
  (`0`) as the flags value; the library issued `open(path, 0, 420)` WITHOUT
  `O_CREAT` and every write silently failed. The declaration now mirrors
  `io.HC` verbatim, as the header's own comment already demanded.

- `scripts/quality/llvm-cap-table-verifier.py` — the queried compiler was
  hardcoded as `REPO_ROOT/"hcc"`, so the verifier silently queried a
  DIFFERENT binary than the harness was given via `--hcc=<path>`. The path
  is now an explicit input: first positional argument, else the `POLYC_HCC`
  environment variable, else the historical default (preserved for the two
  legacy shell callers). The non-zero-exit diagnostic now names the
  compiler and the exit status and distinguishes a crash or signal from an
  ordinary failure.

- `tools/quality/llvm-gep01-test.HC` — the harness passes its `--hcc` path
  to the verifier, and the verifier's captured stderr is no longer freed
  unread; it is included in the capability-row diagnostics.

Not changed: any production compiler source, any oracle row, any harness
predicate, any gate script, the `HCC_ENABLE_LLVM` build-switch wiring,
`io.HC`, `tos.HH`, and the predecessor ACT's history and evidence.

## Evidence

- `../c1/` — the reproduced RED (`GEP01_PASS=26 / GEP01_FAIL=4`) and the
  isolation of the two root causes, with two PolyC probes.
- `../c2/` — (the implementation commit `4ee3398`; its delta is the commit
  itself).
- `../c3/` — the acceptance matrix (AC01..AC11), both negative controls,
  and every gate log, including the unmodified `gate-push` run.
- `residue.txt` — the carried-forward residue.
- `closure-summary.txt` — the one-screen summary.

Headline measurements:

```text
GEP01 harness              GEP01_PASS=30  GEP01_FAIL=0  STATUS=PASS
unmodified gate-push       VERDICT=PASS   (rc=0)
  CHECK=build      PASS      CHECK=install    PASS
  CHECK=gep01      PASS      CHECK=aot        PASS
  CHECK=jit        PASS      CHECK=lsp        PASS
  CHECK=diff-check PASS
gate-fast                  VERDICT=PASS   (rc=0)
factory-v2-test            PASS=53 FAIL=0 (rc=0)
factory-append-only-test   PASS=11 FAIL=0 (rc=0)
make unit-test             rc=0
make jit-unit-test         rc=0
make lsp-test              rc=0   (lsp: 43/43 passed)
llvm-intops01-test.sh      PASS=4  FAIL=0  (rc=0)
llvm-byte-memory01-test.sh PASS=37 FAIL=0  (rc=0)
```

Negative controls (both captured, both demonstrating sensitivity):

- NC-A: reverting ONLY the `io_defs.HH` declaration restores the exact
  C1 RED (`GEP01_PASS=26 / GEP01_FAIL=4`) with the same failure messages.
- NC-B: pointing the verifier at the non-LLVM SIGSEGV compiler fails with
  `rc=-11` named, through BOTH the positional argument and `POLYC_HCC`.

AC02 (no test weakening): the harness's 30 PASS rows are identical, as a
set, to the frozen legacy Bash harness's own 30 rows captured at the
`ACT-POLYC-TOOLING-MIGRATE-GEP01` C1 close. The only difference is the
ORDER of two interleaved groups, and that ordering is pre-existing (it is
identical in the C1 RED run, before any change).

## Production delta

```text
PRODUCTION COMPILER SOURCE CHANGED = NO
LLVM BACKEND / IR / ABI CHANGED     = NO
ORACLE ROW / HARNESS PREDICATE      = NO
GATE SCRIPT / PRE-PUSH HOOK         = NO
BUILD-SWITCH WIRING                 = NO
FILES CHANGED                       = 3 (io_defs.HH, the verifier,
                                      the harness) + evidence + docs
```

## Residue

- **P1** — `src/main.c`: `--print-cap-table` on a NON-LLVM build falls
  through to the normal compile path and dies on SIGSEGV (exit 139) instead
  of failing loudly. A real production-compiler robustness defect.
  Repairing it requires editing production compiler source, which this
  ACT forbids. Recorded, not fixed. It is no longer the cause of the
  GEP01 failure (the harness and the verifier are now pointed at the same
  compiler), but it remains a latent crash for anyone who invokes the flag
  on a non-LLVM build.
- **P1** — the cap-table verifier remains a Python tool, in tension with
  F-NO-PYTHON (`docs/factory/DOCTRINE.md` §26). Pre-existing and
  separately owned; this ACT repaired it in place and did not migrate it.
- **P2** — the harness resolves `python3` from `PATH` via its own
  `ResolveTool` helper, so an unrelated project's `.venv` can still shadow
  the interpreter. Interpreter selection remains the caller's environment
  responsibility.
- **P2** — `scripts/quality/llvm-gep01-test.sh` (the legacy shell harness)
  is a tracked legacy tool superseded by the PolyC harness. Not modified.
- **P2** — the legacy shell scripts default `HCC_INSTALL_DIR` to
  `/tmp/polyc-install`, which does not exist on this host; they need the
  install dir supplied. Pre-existing environment property, unrelated to
  this ACT.

## Recommended next ACT

None required for this scope.

The push of the linear history `c734c9c .. HEAD` may now proceed
normally: the `gep01` gate step passes and the append-only pre-push hook
is unmodified.

If the board wants the two P1 items closed, they belong in their own
bounded ACTs:

- a production-compiler robustness ACT for the `src/main.c`
  `--print-cap-table` guard on non-LLVM builds;
- the existing F-NO-PYTHON migration backlog for the cap-table verifier.
