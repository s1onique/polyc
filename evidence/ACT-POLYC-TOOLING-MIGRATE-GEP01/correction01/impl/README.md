# C2 IMPL proof packet — ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01

This directory holds the C2 IMPL evidence for
ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01.

## Production file changed

`tools/quality/llvm-gep01-test.HC` only.

The diff is `+600 / -22` lines, all confined to:

- New pure-local helper `GepDynamicI8Shape()` replacing the
  weakened `Contains("getelementptr i8, ptr %")` predicate
  on rows 04 / 07.
- New pure-local helper `LineContainsOpcodeMarker()`
  replacing the weakened
  `Contains(t, "opcode") && Contains(t, "(MARKER)")` pair on
  rows 26 / 27 / 28.
- New `--predicate-selftest` mode that walks the seven
  committed RED fixtures through the SAME helpers used by
  the production 30-row run, asserting per-fixture
  expected verdicts and exiting 0 iff all match.
- New option-B scratch lifecycle: caller owns
  `--scratch=<root>`, harness owns a unique per-run
  `<root>/<pid>-<tick>` child, harness deletes ONLY the
  child, harness enforces the
  `HALT_P1_CONTAINMENT_UNVERIFIED` precondition via
  `ContainmentVerify()` before any destructive op.
- Row-08 predicate tightened to
  `Contains(t, "load i8, ptr %gep_i8")` (specific SSA name
  binding, not collapsed to whole-file).
- New housekeeping helpers `MkDirpRecursive()` and
  `RmrRecursive()` use direct libc syscalls
  (mkdir(2) / rmdir(2) / unlink(2) / opendir(2) / readdir(3))
  instead of `SpawnAndCapture("/bin/mkdir", ...)` /
  `SpawnAndCapture("/bin/rm", ...)`. This avoids an
  intermittent SIGBUS observed in repeated SpawnAndCapture
  invocations on this hcc build. The direct-argv constraint
  is preserved: no subprocess is spawned for housekeeping.

## Files

| File                              | Purpose                                       |
|-----------------------------------|-----------------------------------------------|
| `proof-packet.txt`                | Mechanical transcript of all five proof steps |
| `README.md`                       | This file                                     |

## Reproduction

Run from the project root:

```bash
./hcc -jit --install-dir=./build/test-prefix \
  tools/quality/llvm-gep01-test.HC -- --predicate-selftest

./hcc -jit --install-dir=./build/test-prefix \
  tools/quality/llvm-gep01-test.HC -- \
  --hcc=./hcc \
  --llvm-install-dir=./build/test-prefix \
  --scratch=/tmp/c2-impl-scratch
```

## Scope discipline (per F7, F15)

- `src/holyc-lib/tooling.HC`: UNCHANGED
- `src/`, `src/asm/`, `src/x86*.c` (compiler): UNCHANGED
- `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/` (legacy
  oracle evidence): UNCHANGED
- `evidence/ACT-POLYC-LLVM-GEP01/` (other LLVM ACTs):
  UNCHANGED
- `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction01/red/`
  (RED fixtures): UNCHANGED in C2 (added in C1.2)
- Direct-argv constraint: preserved (no `Sh(`, no
  `Shlurp(`, no `bash -c`, no `sh -c`)

## Residue

- P0: **harness `Main` return-type truncation**.
  `public I32 Main` returns the `I64 rc` from `VerdictRc`.
  The compiler truncates `I64 1` to `I32 1`, which still
  shows as exit-1 on shell, so seeded-fail rc IS correct
  here. But this is a structural pre-existing issue (the
  prior baseline run reported the same). If a future ACT
  requires wider int return on Main, it must bound the
  fix narrowly.
