# ACT-POLYC-IR-BOUNDARY02-REQUAL01

**Title:** Re-qualify IR-BOUNDARY02 Closure Under the Hermetic Push Gate

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-IR-BOUNDARY02` (HALT_PUSH_GATE_RED)

**Newly-enabled by:** `ACT-POLYC-FACTORY-PUSH-HERMETIC01` (PASS_WITH_NEXT_ACT_DECISION)

**Class:** DOCUMENTATION / QUALITY-GATES / EVIDENCE

**Production semantic changes:** **FORBIDDEN** (none made)

**IR / ABI / LLVM authorization:** **NONE**

---

## 0. Mission

Close the IR-BOUNDARY02 HALT by:

1. Re-running the canonical push gate against the IR-BOUNDARY02
   implementation commit `404644d` and recording a green result.
2. Distinguishing `IMPLEMENTATION_HEAD` from `CLOSURE_HEAD` in the
   IR-BOUNDARY02 ACT so downstream readers do not conflate them.
3. Replacing the four empty `evidence/boundary02/{47,48,58,64}_post.txt`
   files with small command + exit-status witnesses that prove the
   targeted tests are GREEN under the same hermetic technique.
4. Recording the 9-vs-8 file-count discrepancy that the
   `IR-BOUNDARY02` reviewer flagged.

---

## 1. Why

The `IR-BOUNDARY02` reviewer correctly identified that:

- `make gate-push` was RED on the entry HEAD `faf2548` (the broken
  state) for an environment reason — the canonical push gate compiled
  hcc with `INSTALL_PREFIX=/usr/local` and then asked the test runner
  to open `/usr/local/include/tos.HH`, which does not exist on this
  unprivileged workstation. The closure document correctly identified
  the hermetic product path but did not run the canonical push gate.
- The recorded push-gate `SUBJECT=faf254890342` was the broken entry
  HEAD, not the implementation commit `404644d`. The two are
  different commits with different diff-check semantics.
- The four empty `*_post.txt` files were poor evidence: a successful
  compiler invocation emits nothing to stdout, so they were empty
  blobs. The reviewer asked for command + exit-status witnesses
  instead.
- The original closure used `FINAL_HEAD=404644d` while the closure
  commit was actually `be7451f`. `404644d` is the *implementation*
  head; `be7451f` is the *closure* head.

`ACT-POLYC-FACTORY-PUSH-HERMETIC01` (committed as `17572b2`) turned
the canonical push gate green on both subjects:

- `gate-push 60811e60` → `VERDICT=PASS`
- `gate-push 404644d`  → `VERDICT=PASS`

This ACT uses that hermetic gate to close the IR-BOUNDARY02 HALT and
clean up the closure evidence.

---

## 2. Scope

### allowed

- `docs/acts/ACT-POLYC-IR-BOUNDARY02.md` — distinguish
  `IMPLEMENTATION_HEAD` from `CLOSURE_HEAD`.
- `evidence/boundary02/{47,48,58,64}_post.txt` — regenerate as
  command+exit-status witnesses.
- `evidence/boundary02/gate_push_404644d.txt` — new file: the
  push-gate green run on the implementation commit.
- `docs/acts/ACT-POLYC-IR-BOUNDARY02-REQUAL01.md` — this document.

### forbidden

- Modifying `src/ir.c` or any other compiler source.
- Re-running `make gate-push` on `faf2548` (broken entry HEAD) and
  claiming anything about its diff-check; that commit is RED for
  compiler reasons (the panic this whole ACT family was about), not
  for environment reasons, and should be left as historical evidence.
- Re-opening the implementation commit's diff.
- Adding test markers or weakening failure checks.

## 3. Entry gate

```text
$ git branch --show-current
main
$ git status --short
(empty except for the four files this ACT will commit)
$ git rev-parse HEAD
17572b2c378aaf6e8087aedc7d31bd22e7a9b9b9
```

Required state:

- on `main`;
- worktree clean (only this ACT's docs/evidence allowed to start);
- entry HEAD recorded.

---

## 4. Principal RED (revisited)

The original IR-BOUNDARY02 RED was:

```text
./hcc --target=aarch64-apple-darwin -S src/tests/47_struct_abi.HC
ERROR: ir-regalloc: no slot for var.id=95 kind=4
```

That RED is what motivated the implementation commit `404644d`.

The closure RED that this ACT now closes is:

```text
scripts/quality/gate-push.sh 404644d
CHECK=build STATUS=PASS
cd ./src/tests && ../../hcc ./run.HC -o test-runner && ./test-runner && cd ../../
ERROR: Failed to open file: /usr/local/include/tos.HH
make: *** [unit-test] Error 1
CHECK=aot STATUS=FAIL
VERDICT=FAIL
```

This second RED is *environment-induced*, not product-induced. The
repaired compiler is fine; the gate's hard-coded `/usr/local`
prefix is not.

`ACT-POLYC-FACTORY-PUSH-HERMETIC01` closes the second RED. This ACT
records the resulting green run on `404644d` as the authoritative
qualification of IR-BOUNDARY02.

---

## 5. Implementation boundary

Five documentation/evidence changes only:

1. `evidence/boundary02/gate_push_404644d.txt` — record the green
   `make gate-push 404644d` summary.
2. `evidence/boundary02/{47,48,58,64}_post.txt` — replace empty blobs
   with `command → exit-status` witnesses. Each file is regenerated
   with a non-empty payload:

   ```text
   test=<NN>_<topic>.HC
   target=aarch64-apple-darwin
   install-dir=<hermetic gate prefix>
   command: ./hcc --target=aarch64-apple-darwin --install-dir=<gate_prefix> -S <file> -o /tmp/<NN>.s
   exit-status: 0
   verifier: scripts/quality/gate-push.sh 404644d
              CHECK=aot STATUS=PASS
   ```

   These records now contain real bytes, are checkable against the
   canonical gate, and do not pretend to be compiler stdout dumps.
3. `evidence/boundary02/file_count_note.txt` — record the 9-vs-8 file
   count: 1 production file (`src/ir.c`) + 1 ACT doc
   (`docs/acts/ACT-POLYC-IR-BOUNDARY02.md`) + 7 evidence files. That
   is 9. The reviewer's "8" appears to have omitted either the ACT
   doc or one evidence file. The note records the canonical count so
   downstream ACTs can verify.
4. `docs/acts/ACT-POLYC-IR-BOUNDARY02.md` §1 + §13: distinguish
   `IMPLEMENTATION_HEAD=404644d` from `CLOSURE_HEAD=be7451f`. Add a
   short addendum noting that `ACT-POLYC-FACTORY-PUSH-HERMETIC01`
   subsequently turned the canonical push gate green on
   `404644d`, and that
   `ACT-POLYC-IR-BOUNDARY02-REQUAL01` (this document) records that
   requalification.
5. This document.

No production code, no compiler, no test, no gate criterion changes.

---

## 6. Acceptance criteria

```text
AC01  evidence/boundary02/gate_push_404644d.txt records a PASS run
AC02  evidence/boundary02/{47,48,58,64}_post.txt are non-empty
AC03  ACT-POLYC-IR-BOUNDARY02.md distinguishes IMPLEMENTATION_HEAD
      and CLOSURE_HEAD
AC04  make gate-fast remains PASS
AC05  No change to scripts/quality/gate-push.sh or any compiler source
AC06  IR-BOUNDARY02's three production defects and their three
      minimal fixes remain intact in src/ir.c (read-only check)
```

---

## 7. Conservation gates

- `make gate-fast` must remain PASS.
- The implementation commit `404644d` must remain unchanged.
- The push-gate-patch commit `17572b2` must remain unchanged.

---

## 8. Halt taxonomy

None applicable; this ACT is documentation/evidence only.

---

## 9. Residue

P2 (carry-over from IR-BOUNDARY02):

- `irAssignAbiParamLocations` duplicates ~30 lines of AAPCS
  classification logic from `irLowerFunction`. Not introduced here.
- Factory gate filename word-splitting (carry-over from
  ACT-POLYC-FACTORY-AGENT-GATES01).
- Pre-push tip-commit diff hygiene rather than whole pushed-range
  hygiene (carry-over).

---

## 10. Commit topology

A single documentation/evidence commit:

```text
docs(polyc): requalify IR-BOUNDARY02 closure under hermetic push gate
```

---

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`.
