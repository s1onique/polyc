# ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION01

## 0. Mission

Promote the long-standing P2 residue

> pre-push tip-commit diff hygiene rather than whole pushed-range hygiene

to a P0/P1 correction. The IR-BOUNDARY02-REQUAL01 reviewer observed
that `gate-push HEAD` checks only `parent..subject`, so whitespace
introduced in a non-tip commit of the same push is invisible.

Three bounded corrections:

1. normalize the trailing whitespace in
   `evidence/pushhermetic01/diff.txt` (evidence file only; semantic
   content unchanged);
2. pin `REQUAL_HEAD=a345afd3...` in
   `docs/acts/ACT-POLYC-IR-BOUNDARY02.md` (placeholder remediation);
3. extend `scripts/quality/gate-push.sh` and `.githooks/pre-push`
   so the diff-check covers the **entire pushed range** rather than
   the tip commit alone.

No compiler changes. No test changes. No marker changes.

---

## 1. Verdict

**VERDICT=PASS_WITH_NEXT_ACT_DECISION** (to be confirmed at closure).

---

## 2. Identity

```text
ENTRY_HEAD          = a345afd3e4493c16a359f7ab6ce5f58d1646d3a2
FINAL_HEAD          = (filled in at closure)
WORKTREE            = clean at entry
REMOTE_BASE_FOR_RED = be7451f64cb1c551e085f1a5a1732f8367b6399a
LOCAL_TIP_FOR_RED   = a345afd3e4493c16a359f7ab6ce5f58d1646d3a2
```

---

## 3. Entry gate

```text
$ git branch --show-current
main
$ git status --short
(empty at entry)
$ git rev-parse HEAD
a345afd3e4493c16a359f7ab6ce5f58d1646d3a2
```

---

## 4. Principal RED

```text
$ git diff --check be7451f..a345afd
evidence/pushhermetic01/diff.txt:8: trailing whitespace.
+<SP>
evidence/pushhermetic01/diff.txt:25: trailing whitespace.
+<SP>
evidence/pushhermetic01/diff.txt:49: trailing whitespace.
+<SP>
evidence/pushhermetic01/diff.txt:52: trailing whitespace.
+<SP>
evidence/pushhermetic01/diff.txt:58: trailing whitespace.
+<SP>
evidence/pushhermetic01/diff.txt:61: trailing whitespace.
+<SP>
$ echo $?
2
```

The six errors were introduced by commit `17572b2` and persisted
through `a345afd`. The current `gate-push.sh` `GPUSH-5` phase
inspects only `subject^..subject`, so it reports PASS on HEAD even
though the pushed range `be7451f..a345afd` is not whitespace-clean.

Recorded in `evidence/pushhermetic01_correction01/red_range_diff.txt`.

---

## 5. Design — separation of concerns

The reviewer's invariant is the load-bearing rule of this ACT:

> **Expensive tests qualify the pushed tree; cheap hygiene qualifies
> every change being pushed.**

Concretely:

```text
EXPENSIVE  (the existing GPUSH-1..4):  build, install, AOT, JIT, LSP
            still run on the FINAL TREE only (subject_sha).
            Do not iterate them across every commit in the range —
            a 3-commit push would not need 3 builds.

CHEAP      (new GPUSH-6):              git diff --check <range>
            runs once per pushed range. Cheap enough to do per-ref.
```

`gate-push.sh` is therefore extended with a new optional range
argument supplied by the pre-push hook:

```text
scripts/quality/gate-push.sh <subject> [<remote_sha>]
```

When `<remote_sha>` is supplied (and is not the all-zeros sentinel),
GPUSH-6 runs `git diff --check <remote_sha> <subject>` over the
entire range. When `<remote_sha>` is omitted, GPUSH-6 falls back to
the existing `<subject>^..<subject>` behavior — preserving every
existing manual invocation pattern.

The pre-push hook passes the range per Git's documented stdin
contract:

```text
<local_ref> <local_sha> <remote_ref> <remote_sha>
```

For ordinary updates we pass `<remote_sha> <local_sha>` to gate-push.
For new branches where `<remote_sha>` is `0000...0000` we pass
`<empty-tree-sha> <local_sha>` (the Git null tree). For deletes we
skip gate-push entirely (existing behavior, unchanged).

---

## 6. Implementation boundary

Five files:

| File                                                     | Change                                                              |
|----------------------------------------------------------|---------------------------------------------------------------------|
| `evidence/pushhermetic01/diff.txt`                       | whitespace-only normalization (semantic content identical)          |
| `docs/acts/ACT-POLYC-IR-BOUNDARY02.md`                   | pin `REQUAL_HEAD=a345afd3e4493c16a359f7ab6ce5f58d1646d3a2`          |
| `scripts/quality/gate-push.sh`                           | add GPUSH-6 range-diff-check, accept optional `<remote_sha>`        |
| `.githooks/pre-push`                                     | pass `<remote_sha> <local_sha>` to gate-push; handle 000...0 sentinel|
| `docs/acts/ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION01.md` | this document                                                   |

No production compiler changes. No test changes. No marker regex
changes. Existing GPUSH-1..5 untouched.

---

## 7. Acceptance criteria

```text
AC01  evidence/pushhermetic01/diff.txt:  git diff --check be7451f..HEAD exit=0
AC02  ACT-POLYC-IR-BOUNDARY02.md:        REQUAL_HEAD=a345afd3e4493c16a359f7ab6ce5f58d1646d3a2
AC03  gate-push.sh:                       new GPUSH-6 range-diff-check
AC04  gate-push.sh:                       accepts optional <remote_sha> argument
AC05  pre-push hook:                      passes remote_sha..local_sha to gate-push
AC06  pre-push hook:                      treats remote_sha=0000...0 as new-branch (empty tree base)
AC07  gate-push.sh:                       when remote_sha omitted, GPUSH-6 falls back to parent..subject
AC08  Existing GPUSH-1..5:                 untouched (byte-identical)
AC09  run_check marker regex:              untouched (byte-identical)
AC10  Positive control: gate-push.sh 404644d <be7451f> returns GPUSH-6 PASS
AC11  Positive control: gate-push.sh a345afd <be7451f> returns GPUSH-6 PASS
AC12  Negative control (in-process):     simulate a whitespace-bearing commit
      and confirm GPUSH-6 catches it.
AC13  make gate-fast:                      PASS
AC14  gate-push HEAD:                      PASS (range a345afd^..a345afd clean anyway)
AC15  gate-push <be7451f..a345afd>:        via the new range-aware path returns GPUSH-6 PASS
```

---

## 8. Conservation

- `src/ir.c` at 404644d: untouched.
- `scripts/quality/gate-fast.sh`: untouched.
- `make install`, `make unit-test`, `make jit-unit-test`, `make lsp-test`: untouched.
- `run_check` regex (`FAILED: `, `Failed to compile`, `Failed to run`): untouched.
- diff-check semantics on tip-only invocation: preserved as a fallback.

---

## 9. Residue

P2 (carry-over):

- Factory gate filename word-splitting (carry-over).
- LLVM-SPIKE01 B2 dev-toolchain witness (carry-over, blocks next ACT).

P1 promoted to closed:

- pre-push tip-commit diff hygiene rather than whole pushed-range
  hygiene. CLOSED by this ACT.

---

## 10. Commit topology

A single small commit:

```text
docs+tooling(polyc): range-aware pre-push diff hygiene + ACT-typo pin
```

(splitting into separate docs/tooling commits is permitted if it
simplifies review.)

---

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`.
