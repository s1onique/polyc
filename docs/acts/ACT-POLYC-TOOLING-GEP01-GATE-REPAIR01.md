# ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair the LLVM GEP01 qualification harness subprocess/output contract so the canonical `make llvm-gep01-test` gate reaches 30/30 PASS and the unmodified `gate-push` gate is no longer blocked by GEP01

**Repository:** PolyC
**Branch:** `main`

**Class:** TOOLING / QUALITY-GATES / BUGFIX
**Priority:** P0

**Predecessor:** `ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01` (closed at C4 with
`PASS_TRUE_GREEN`; its CLOSE commit is a legitimate local closure whose push
is blocked solely by the GEP01 gate failure this ACT repairs)

**Production semantic changes:** FORBIDDEN
**IR / ABI / LLVM authorization:** NONE

---

## 1. Mission

Repair the LLVM GEP01 qualification harness so that all 30 assertions of the
frozen oracle pass against the canonical LLVM-enabled compiler, and so that
the unmodified complete pre-push gate (`scripts/quality/gate-push.sh`) is no
longer blocked at its `gep01` check.

This ACT diagnoses and repairs the **subprocess / output contract** of the
GEP01 harness. It does **not** change GEP lowering, LLVM backend semantics,
IR, ABI, or any compiler behaviour.

---

## 2. Why

`ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01` closed locally and correctly,
but its push was rejected by the pre-push hook because the mandatory
`gep01` gate step failed with `GEP01_PASS=26 / GEP01_FAIL=4`.

The four failing rows were:

```text
FAIL  readat.HC: SHAPE_DEPENDENT counter = ? (expected >= 1): shape_dependent marker not found in stderr
FAIL  IR_GEP  = REJECTED (sibling opcode still rejected): could not read cap verifier output
FAIL  IR_LEA  = REJECTED (sibling opcode still rejected): could not read cap verifier output
FAIL  IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset): could not read cap verifier output
```

Three prior ACTs recorded this identical failure as an accepted, separately
owned P1 residue (`ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01`,
`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`, `ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01`),
and `docs/ROADMAP.md` records it as blocking `gate-push` only.

No Factory closure correction is required or authorized by this ACT. The
prior CLOSE commit stays intact.

---

## 3. Verified root cause

The four failing rows are **two** independent defects, not four. They were
previously counted as one aggregate because the harness collapsed distinct
underlying causes into a single generic message.

### 3.1 Defect A — declaration/definition signature mismatch in `io_defs.HH`

`src/holyc-lib/io_defs.HH` is the **declaration-only** header used by the
PolyC harness. Its own comment demands verbatim mirroring of `io.HC`:

```text
src/holyc-lib/io_defs.HH:46
  // Public API (mirror io.HC signatures verbatim).
  public Bool FileWrite(U8 *filename, U8 *buf, I64 size,
                        Bool append=FALSE);          <-- WRONG
```

The canonical public header and the library definition both use an `I64`
flags parameter:

```text
src/holyc-lib/tos.HH:786
  public Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags = O_CREAT | O_RDWR);

src/holyc-lib/io.HC:211
  public Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags=O_CREAT|O_RDWR)
```

Because `tools/quality/llvm-gep01-test.HC` includes `io_defs.HH` (not
`io.HC`), the compiler lowers the call site against the `Bool append=FALSE`
signature. The fourth argument is therefore passed as the boolean `FALSE`
(`0`), so the library receives `flags == 0` and issues
`open(path, 0, 420)` — **without `O_CREAT`** — which fails with `ENOENT`.
`FileWrite` therefore returns `FALSE` and writes **nothing**.

Measured at the real seam (PolyC probe against the installed `libtos`):

```text
FileWrite(default)          = 0     (FALSE)
FileWrite(explicit 0x202)   = 1     (TRUE)   -> file written, 5 bytes
FileWrite(explicit O_CREAT|O_RDWR|O_TRUNC) = 1
direct open(0x202, 420)     = fd 3 ; write n=5   (file written)
```

Consequences:

* `readat.err` is never created, so the `SHAPE_DEPENDENT` row reports
  `shape_dependent marker not found in stderr` — **row 1**.
* `cap-verifier.txt` is never created, so the three capability rows report
  `could not read cap verifier output` — **rows 2..4**.

`SpawnAndCapture` and `FileRead` are **not** defective: a direct probe
through the same `SpawnAndCapture` seam captures the full 215-byte stderr
including `CAPABILITY_COUNTERS supported=2 rejected=0 shape_dependent=3 ...`.

### 3.2 Defect B — the cap-table verifier queries a different compiler

`scripts/quality/llvm-cap-table-verifier.py` hardcodes the compiler path:

```text
scripts/quality/llvm-cap-table-verifier.py:55
  HCC = REPO_ROOT / "hcc"
```

The PolyC harness is explicitly parameterised by `--hcc=<path>`, but it
invokes the verifier with no way to tell it which compiler to query:

```text
tools/quality/llvm-gep01-test.HC:791
  args[1] = StrPrint(NULL, "scripts/quality/llvm-cap-table-verifier.py");
```

So the verifier silently queries `REPO_ROOT/"hcc"` regardless of the
`--hcc` path the harness was given. When that binary is not LLVM-enabled,
`hcc --print-cap-table` is not handled at all: the `--print-cap-table`
dispatch lives inside `#ifdef HCC_ENABLE_LLVM` in `src/main.c`, so the flag
is parsed and then ignored, the compiler falls through to the normal
compile path with no input file, and the process dies on SIGSEGV.

Measured:

```text
./hcc --print-cap-table ; echo $?    -> 139   (SIGSEGV), stdout 0 bytes
strings hcc | grep -c CAPABILITY_COUNTERS       -> 0   (non-LLVM build)
strings build/hcc | grep -c CAPABILITY_COUNTERS -> 1   (LLVM build)
```

The verifier then reports, on **stdout** (its stderr is empty):

```text
FAIL  hcc --print-cap-table exited non-zero:
FAIL  could not load capability table from hcc --print-cap-table
```

The harness writes only the verifier's **stdout** to `cap-verifier.txt` and
**discards** the captured stderr, so the underlying diagnostic is lost and
all three capability rows collapse to one generic message.

---

## 4. Principal RED

The RED witness is the canonical, unmodified gate itself.

```sh
# From the repository root, with an LLVM-enabled compiler in place:
make test-prefix-install HCC_ENABLE_LLVM=ON
make llvm-gep01-test HCC_ENABLE_LLVM=ON
```

Expected RED (before this ACT's implementation):

```text
GEP01_PASS=26
GEP01_FAIL=4
STATUS=FAIL
```

with the four rows quoted in section 2.

An additional RED witness isolates Defect A from Defect B and is recorded at
`evidence/ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01/c1/`:

* `filewrite-signature-mismatch.txt` — the `FileWrite` probe matrix above,
  showing the default-argument call fails while an explicit-flags call
  succeeds.
* `cap-verifier-wrong-compiler.txt` — the verifier's `FAIL could not load
  capability table` output together with the `./hcc --print-cap-table`
  SIGSEGV measurement.
* `cap-verifier-stderr-discarded.txt` — the demonstration that the harness
  discards the verifier's captured stderr.

### 4.1 Negative controls required at closure

The repair MUST be proven sensitive to both defects. A repair that merely
makes the harness green without proving sensitivity is NOT acceptable.

* **NC-A** — with the `io_defs.HH` `FileWrite` signature reverted to
  `Bool append=FALSE`, the `SHAPE_DEPENDENT` row MUST fail again.
* **NC-B** — with the verifier pointed at a non-LLVM `hcc` (the SIGSEGV
  binary), the three capability rows MUST fail again.

---

## 5. Scope

### allowed

* `src/holyc-lib/io_defs.HH` — correct the `FileWrite` declaration so it
  mirrors `io.HC` / `tos.HH` verbatim (the header's own stated contract).
* `scripts/quality/llvm-cap-table-verifier.py` — let the caller select the
  compiler binary (argument and/or environment variable), keeping the
  current `REPO_ROOT/"hcc"` default for the existing legacy shell callers.
* `tools/quality/llvm-gep01-test.HC` — pass the `--hcc` path to the
  verifier, and stop discarding the verifier's captured stderr (surface it
  in the failure diagnostic).
* `docs/ROADMAP.md` — update the stale P1 residue entry for the GEP01
  cap-verifier gap once it is closed.
* `evidence/ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01/` — this ACT's evidence.
* `docs/acts/ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01.md` — this ACT.

### forbidden

* Any change to `src/llvm-backend*.c`, `src/ir*.c`, `src/aarch64.c`,
  `src/x86_64.c`, `src/main.c`, `src/cli.c`, or any other production
  compiler source. **Production semantic changes are FORBIDDEN.**
* Any change to the 30-row GEP01 oracle, to `GepDynamicI8Shape`,
  `ExtractShapeDependent`, `LineContainsOpcodeMarker`, or any other harness
  predicate. **No test weakening (F5).**
* Any change to `scripts/quality/gate-push.sh`, `scripts/quality/gate-fast.sh`,
  the pre-push hook, or any gate script.
* Any change to the `HCC_ENABLE_LLVM` build-switch wiring in the `Makefile`.
* Any change to `src/holyc-lib/io.HC` or `src/holyc-lib/tos.HH` (the
  definitions are already correct; only the declaration-only header is
  wrong).
* Any new dependency, any new Python file, any migration of the Python
  verifier to PolyC (out of scope; it is a tracked legacy tool recorded in
  `docs/factory/PYTHON-CALLGRAPH.tsv`).
* Any modification to the history of the predecessor ACT
  `ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01`, including its evidence
  directory (F14).
* Any bypass of the pre-push hook, any `--no-verify`, any weakening of a
  gate to obtain PASS.

---

## 6. Implementation boundary

Two minimal changes:

1. **`src/holyc-lib/io_defs.HH`** — change the `FileWrite` declaration's
   fourth parameter from `Bool append=FALSE` to
   `I64 flags=O_CREAT|O_RDWR`, matching `io.HC` and `tos.HH`. The
   `O_CREAT` / `O_RDWR` macros are already defined in that header.

2. **`scripts/quality/llvm-cap-table-verifier.py` +
   `tools/quality/llvm-gep01-test.HC`** — make the compiler path an explicit
   input to the verifier, with the current default preserved:
   * the verifier accepts the compiler path as its first positional
     argument, and/or via a `POLYC_HCC` environment variable, defaulting to
     `REPO_ROOT/"hcc"` when neither is supplied;
   * the harness passes the `--hcc` path it was given;
   * the harness no longer discards the verifier's captured stderr; the
     stderr text is included in the failure diagnostic so a future
     regression is diagnosable from the harness output alone.

Deliberately **not** included:

* Migrating the Python verifier to PolyC. That is a separate, larger ACT
  (F-NO-PYTHON's own migration backlog). This ACT repairs the existing
  tool in place.
* Changing `src/main.c` so that `--print-cap-table` fails loudly on a
  non-LLVM build instead of SIGSEGVing. That is a real, separate
  robustness defect in the production compiler (a non-LLVM build should
  reject the flag, not crash). It is **P1 residue** for this ACT, because
  fixing it would touch production compiler source, which this ACT
  forbids.

---

## 7. Acceptance criteria

Each AC is checkable by a single concrete command.

* **AC01** — `make llvm-gep01-test HCC_ENABLE_LLVM=ON` reports
  `GEP01_PASS=30` and `GEP01_FAIL=0` and `STATUS=PASS`.
* **AC02** — the harness's 30 PASS lines are the same 30 assertions as the
  frozen oracle in
  `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/oracle-matrix.tsv`; no
  assertion is removed, renamed, or weakened. Verified by diffing the
  harness's PASS/FAIL row set against the oracle row set.
* **AC03** — `scripts/quality/llvm-cap-table-verifier.py` still defaults to
  `REPO_ROOT/"hcc"` when no compiler path is supplied (the two legacy shell
  callers `scripts/quality/llvm-intops01-test.sh` and
  `scripts/quality/llvm-byte-memory01-test.sh` are unaffected).
* **AC04** — NC-A: reverting only the `io_defs.HH` `FileWrite` declaration
  makes the `SHAPE_DEPENDENT` row fail again with
  `shape_dependent marker not found in stderr`; restoring it makes the row
  pass. The harness output is captured in both states.
* **AC05** — NC-B: pointing the verifier at the non-LLVM SIGSEGV `hcc`
  makes the three capability rows fail again; pointing it at the
  LLVM-enabled `hcc` makes them pass. The harness output is captured in
  both states.
* **AC06** — when the cap-table verifier fails, the harness's failure
  diagnostic contains the verifier's captured stderr (no silent
  discarding).
* **AC07** — `make unit-test`, `make jit-unit-test`, `make lsp-test` remain
  PASS with their pre-existing counts.
* **AC08** — `scripts/quality/gate-fast.sh` reports `STATUS=PASS`.
* **AC09** — the unmodified `scripts/quality/gate-push.sh HEAD` reports
  `CHECK=gep01 STATUS=PASS` and reaches `VERDICT=PASS`. The gate script
  itself is not modified; `git diff --name-only <entry>..HEAD --
  scripts/quality/gate-push.sh` is empty.
* **AC10** — `scripts/quality/factory-v2-test.sh` and
  `scripts/quality/factory-append-only-test.sh` remain PASS.
* **AC11** — `scripts/quality/factory-v2-range-check.sh
  ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01 HEAD` reports `STATUS=PASS`.

---

## 8. Conservation gates

* `make unit-test`
* `make jit-unit-test`
* `make lsp-test`
* `scripts/quality/gate-fast.sh`
* `scripts/quality/factory-v2-test.sh`
* `scripts/quality/factory-append-only-test.sh`
* `scripts/quality/llvm-intops01-test.sh` (legacy caller of the repaired
  verifier)
* `scripts/quality/llvm-byte-memory01-test.sh` (legacy caller of the
  repaired verifier)
* `scripts/quality/gate-push.sh` (unmodified; the closure-critical gate)

---

## 9. Halt taxonomy

* `HALT_RED_NOT_REPRODUCED` — the four GEP01 rows cannot be reproduced
  against the canonical LLVM-enabled build.
* `HALT_SCOPE_EXPANSION_REQUIRED` — a correct completion requires touching
  production compiler source (`src/main.c` guard for
  `--print-cap-table`), which this ACT forbids.
* `HALT_DEPENDENCY_UNAVAILABLE` — LLVM 22 (`llvm-config`, `llvm-as`, `opt`)
  or `python3` is unavailable on the host, and no silent fallback is
  permitted (F6).
* `HALT_CONSERVATION_VIOLATION` — a conservation gate in section 8 regresses
  because of this ACT's change.
* `HALT_GATE_PUSH_FAIL_UNRELATED` — the unmodified `gate-push` fails at a
  check other than `gep01`, or at `gep01` for a cause this ACT does not
  own. The failure is reported truthfully with its own evidence.

---

## 10. Residue

Pre-declared:

* **P1** — `src/main.c`: `--print-cap-table` on a non-LLVM build falls
  through to the normal compile path and dies on SIGSEGV (exit 139)
  instead of failing loudly. This is a production-compiler robustness
  defect. Repairing it requires editing production compiler source, which
  this ACT forbids. It is recorded, not fixed. (It is *not* the cause of
  the GEP01 failure after this ACT, because the harness and the verifier
  are then pointed at the same LLVM-enabled compiler; it remains a latent
  crash for anyone who invokes the flag on a non-LLVM build.)
* **P1** — the cap-table verifier is a Python tool, in tension with
  F-NO-PYTHON (`docs/factory/DOCTRINE.md` §26). It is pre-existing and
  separately owned; this ACT repairs it in place and does not migrate it.
* **P2** — the harness historically resolved `python` from `PATH`; a
  `.venv` belonging to an unrelated project can shadow the interpreter.
  The harness resolves `python3` explicitly via its own `ResolveTool`
  helper, but the interpreter *selection* remains the caller's environment
  responsibility. Recorded as a documentation-level residue.
* **P2** — `scripts/quality/llvm-gep01-test.sh` (the legacy shell harness)
  is a tracked legacy tool superseded by the PolyC harness; it is not
  modified by this ACT.

---

## 11. Commit topology

```text
1. RED       -- evidence of the reproduced failure + the two isolated
                root causes (no production change).
2. IMPL      -- io_defs.HH declaration fix; verifier compiler-path
                plumbing; harness stderr surfacing.
3. EVIDENCE  -- AC01..AC11 measurements, including NC-A and NC-B.
4. CLOSE     -- verdict + residue + ROADMAP update.
```

Do not exceed four commits. Do not combine unrelated cleanup with the
semantic work (F12).

---

## 12. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`.

A CLOSE commit carries:

```text
ACT: ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01
ACT-Phase: CLOSE
ACT-Verdict: PASS_TRUE_GREEN
```

A HALT CLOSE commit additionally carries `HALT_CLASS` and `BLOCKS_NEXT`
per `docs/factory/GIT-METADATA.md` §2.4.
