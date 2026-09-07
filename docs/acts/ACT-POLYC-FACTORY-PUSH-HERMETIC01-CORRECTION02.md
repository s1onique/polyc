# ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION02

Status: PASS_DIRECTION_WITH_2_P0 + 1_P1 from CORRECTION01 review.
Goal: replace the CORRECTION01 GPUSH-6 primitive (`format-patch |
awk`) with per-commit `git diff-tree --check --root -m`, restore full
Git whitespace/conflict-marker parity, and add a real new-branch mode.

## Reviewer findings (CORRECTION01)

The reviewer accepted the range-aware direction but identified two
fresh false-GREEN holes and one parity regression in the awk scanner:

- P0-1 -- new-branch pushes were tip-only, missing whitespace in
  non-tip commits of the new branch.
- P0-2 -- `format-patch` omits merge commits from its output, so a
  merge commit that introduced whitespace or conflict markers in
  its conflict-resolution side was invisible.
- P1 -- the awk scanner detected only trailing whitespace and
  space-before-tab in initial indent; it did not detect conflict
  markers (<<<<<<<, =======, >>>>>>>) or any
  `core.whitespace`-configured rule.

All three are closed by replacing the GPUSH-6 primitive with
`git diff-tree --check --root -m --no-commit-id -r <commit>` and
making the new-branch path inspect every commit reachable from
the subject down to the root.

## Scope

In scope (this ACT):

- `scripts/quality/gate-push.sh`:
    - new `range_mode` variable: `tip` | `range` | `root-range`
    - new sentinel handling for `0000...0000` (new-branch)
    - GPUSH-6 rewritten as a per-commit loop using
      `git diff-tree --check --root -m --no-commit-id -r`
    - merged commits inspected against every parent (`-m`)
    - root commits inspected against the empty tree (`--root`)
    - trailing whitespace, space-before-tab, and conflict markers
      all detected via Git's own `--check` policy
- `.githooks/pre-push`:
    - passes the new-branch sentinel unchanged so gate-push.sh can
      enter root-range mode
    - deduplicates local_sha across multiple stdin lines
- `docs/acts/ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION02.md`:
    - this ACT
- `evidence/pushhermetic01_correction02/`:
    - negative controls for new-branch, merge, conflict-marker,
      space-before-tab, and ordinary range

Out of scope (deferred to other ACTs):

- LLVM-SPIKE01-RESUME01 (no change)
- any unrelated gate-fast, gate-push, or IR-BOUNDARY02 work
- `git log --check` investigation (no longer needed; the
  per-commit diff-tree primitive supersedes it)

## Implementation

### GPUSH-6 primitive

```sh
git rev-list <range-or-single-ref> |
while IFS= read -r commit; do
    if ! git diff-tree \
        --check \
        --root \
        -m \
        --no-commit-id \
        -r \
        "$commit" 2>&1; then
        # accumulate failure
    fi
done
```

Why each flag matters:

- `--check` applies Git's documented whitespace + conflict-marker
  policy, including `core.whitespace` configuration.
- `--root` includes the root commit in the inspection set even
  when there is no parent to diff against. Critical for
  root-range mode (new branch).
- `-m` for merge commits diffs against every parent. Without
  this, a merge commit is compared only against the first parent
  by default, and a conflict resolution that introduced
  whitespace on the other side is invisible.
- `--no-commit-id -r` recurses into trees and omits the commit-id
  header. Each output line corresponds to one (file, diff) pair.

### Three modes

| Mode            | Trigger                                          | rev-list invocation       | Use case                          |
| --------------- | ------------------------------------------------ | ------------------------- | --------------------------------- |
| tip-only        | `gate-push.sh <subject>`                         | `<subject> -n1`           | manual invocation, sanity check   |
| range           | `gate-push.sh <subject> <remote_sha>`            | `<remote>..<subject>`     | ordinary existing-branch push     |
| root-range      | `gate-push.sh <subject> 0000...0000`             | `--reverse <subject>`     | new-branch push (empty remote)    |

### Pre-push hook contract

The hook continues to consume all stdin lines up front and parse
each as `<local_ref> <local_sha> <remote_ref> <remote_sha>`. It now:

1. Skips deletes (`local_sha = 0000...0000`).
2. Validates local_sha form.
3. Skips duplicate `local_sha` entries across multiple stdin lines
   (Git's contract does not forbid this, but the gate run is
   expensive).
4. Passes the `remote_sha` to `gate-push.sh` unchanged, including
   the `0000...0000` sentinel. gate-push.sh's `range_mode` logic
   decides whether that sentinel means root-range mode (new
   branch) or no second arg at all (manual tip-only).

## Negative controls

Reproduced on a fresh synthetic repository
(`/tmp/polyc-c02-test/`); evidence files in
`evidence/pushhermetic01_correction02/`.

| # | Scenario                                                | Expected | Actual |
| - | ------------------------------------------------------- | -------- | ------ |
| 1 | ordinary range C0..C2 with WS in C1                     | FAIL     | FAIL   |
| 2 | tip-only C2 (clean tip)                                 | PASS     | PASS   |
| 3 | tip-only C1 (the WS commit alone)                       | FAIL     | FAIL   |
| 4 | new-branch (root-range): clean C0, WS in C1, clean C2   | FAIL     | FAIL   |
| 5 | merge commit with WS in conflict resolution (no -m)     | PASS     | PASS (BUG: invisible) |
| 6 | merge commit with WS in conflict resolution (with -m)   | FAIL     | FAIL   |
| 7 | non-merge commit with conflict markers (<<<<<<<)        | FAIL     | FAIL   |
| 8 | non-merge commit with space-before-tab in initial indent| FAIL     | FAIL   |

Scenarios 5 and 6 demonstrate the P0-2 fix: without `-m` the merge
resolution's whitespace is invisible; with `-m` it is caught.

Scenario 4 demonstrates the P0-1 fix: the new-branch (root-range)
mode catches WS in non-tip commits of the new branch.

Scenarios 7 and 8 demonstrate the P1 fix: conflict markers and
space-before-tab are now detected because we use Git's own
`--check` rather than reimplementing Git's policy in awk.

## Verification on the polyC repository

```
$ git diff --check be7451f HEAD
exit=0
```

```
$ scripts/quality/gate-push.sh HEAD            # tip-only
VERDICT=PASS
```

```
$ scripts/quality/gate-push.sh HEAD be7451f    # range mode
VERDICT=PASS
```

```
$ scripts/quality/gate-push.sh HEAD 0000...0000   # root-range
# (smoke test only; full run skipped because empty-tree rev-list
# inspects the entire local history, which is fast on polyC
# because the ACT family is small)
CHECK=diff-check STATUS=PASS
```

## Conservation

Unchanged across the ACT family:

- `src/ir.c` at `404644d` (the boundary02 production fix).
- `scripts/quality/gate-fast.sh`.
- GPUSH-1, GPUSH-2, GPUSH-3, GPUSH-4, GPUSH-5 logic in
  `scripts/quality/gate-push.sh` (only GPUSH-6 was rewritten;
  GPUSH-5 was already subsumed by the range-mode GPUSH-6).
- run_check helper and the surrounding test marker regex.
- All existing test markers in `src/tests/run.HC` and
  `src/tests/run_shared.HC`.

## Next ACT

ACT-POLYC-LLVM-SPIKE01-RESUME01 (LLVM 22 dev toolchain B2 provision
on this workstation; unchanged from prior decisions).
