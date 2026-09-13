# ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01 — Closure Report

## VERDICT

**PASS**

## Identity

| Field               | Value                                                        |
|---------------------|--------------------------------------------------------------|
| OLD_HEAD            | `1f8250b97d0f203dcb81772e8e715feee2401a90`                   |
| UPSTREAM_HEAD       | `7d7b983686fac2239a47288fe4b8e5dbbb617d55`                   |
| MERGE_BASE          | `e544a48f192606256af9f348befec0c852b6387b`                   |
| LOCAL_ONLY_COUNT    | 9                                                            |
| UPSTREAM_ONLY_COUNT | 132                                                          |
| Classification      | `DIVERGED`                                                   |
| BACKUP_BRANCH       | `backup/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01-1f8250b` |
| HARNESS_BRANCH      | `harness/codium-polyc2`                                      |
| FINAL_MAIN          | `7d7b983686fac2239a47288fe4b8e5dbbb617d55` (= `origin/main`) |
| FINAL_HARNESS_HEAD  | `12e4e7a2e093c08a8308b73b172a6192cda89c3d`                   |
| REMOTE_MUTATED      | `false` (no `git push` of any kind performed)                |

## Worktree pre-state

`git status --short` was empty before any history mutation (F3 satisfied).
No stashing, no auto-commit, no reset of dirty work.

## Preservation

Backup branch `backup/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01-1f8250b`
points exactly at OLD_HEAD (verified by `git rev-parse`).

Harness branch `harness/codium-polyc2` initially also pointed at OLD_HEAD
(pre-rebase head confirmed as `1f8250b`).

## Rebase

Rebase of `harness/codium-polyc2` onto `origin/main` (post-fetch) was clean:

* 9/9 commits replayed without conflict.
* No merge commit introduced.
* No `--ours` / `--theirs` resolution required.

## Range-diff verdict

`git range-diff $MERGE_BASE..backup/... origin/main..harness/codium-polyc2`

Conclusion: every pre-ACT local-only logical change is represented by a
corresponding rebased commit.

| Pre-ACT local SHA | Rebased SHA | Marker | Interpretation |
|-------------------|-------------|--------|----------------|
| `c2bce5d` | `eab9d8a` | `=` | byte-equal patch, identity preserved |
| `e4a743c` | `1855dce` | `=` | byte-equal patch |
| `1cd22d4` | `f9780c2` | `=` | byte-equal patch |
| `6d822df` | `84036fc` | `=` | byte-equal patch |
| `908d085` | `c063ea3` | `=` | byte-equal patch |
| `631879d` | `295e056` | `=` | byte-equal patch |
| `424ed55` | `6a2be24` | `!` | content-equivalent; only upstream ROADMAP.md context lines around the SHELL-BUDGET01 status block shifted due to BOOTSTRAP04 closure that landed upstream between MERGE_BASE and UPSTREAM_HEAD |
| `09000e9` | `c9caf7b` | `!` | content-equivalent; same upstream ROADMAP.md context drift |
| `1f8250b` | `12e4e7a` | `!` | content-equivalent; same upstream ROADMAP.md context drift |

No local logical change was dropped. The only diffs are hunks the
upstream ROADMAP picked up after our local diverged (BOOTSTRAP03/04
closure announcements). The new file `docs/acts/ACT-POLYC-TOOLING-SHELL-BUDGET01-CORRECTION01.md`,
`docs/factory/SHELL-BUDGET.tsv`, and the entire `evidence/.../SHELL-BUDGET01/*`
tree ride forward unchanged in content.

**RANGE_DIFF_VERDICT = PASS** (every original local logical change accounted for).

## Ancestry verification

```text
git merge-base --is-ancestor origin/main harness/codium-polyc2
  → exit 0  (PASS)

git rev-parse main              == git rev-parse origin/main
  → 7d7b983686fac2239a47288fe4b8e5dbbb617d55  (PASS)

git rev-parse backup/ACT-...-1f8250b  == OLD_HEAD
  → 1f8250b97d0f203dcb81772e8e715feee2401a90  (PASS)
```

## Local commits before / after

| Phase  | Count | Recorded at                                                                       |
|--------|-------|-----------------------------------------------------------------------------------|
| BEFORE | 9     | `pre-ACT-local-only-commits.txt`                                                  |
| AFTER  | 9     | `post-ACT-harness-commits.txt` (rebased; patch content preserved per range-diff)  |

No commit was lost. No merge commit was created on `main`.

## Repository validation

### `gate-fast.sh` (PolyC canonical fast gate)

| Subject                 | Result | Log                                                              |
|-------------------------|--------|------------------------------------------------------------------|
| `harness/codium-polyc2` | PASS   | `gate-fast-output.txt` (`VERDICT=PASS`, all four subchecks PASS) |
| `main` (= origin/main)  | PASS   | `gate-fast-main.txt`  (`VERDICT=PASS`, all four subchecks PASS)  |

### `gate-push.sh` (PolyC canonical exhaustive gate)

`gate-push.sh HEAD --new-branch origin` was run on the rebased harness,
and `gate-push.sh main --root-range` was run on `origin/main` to establish
the upstream baseline.

Both runs produce the **same** result:

```text
GEP01_PASS=26
GEP01_FAIL=4
STATUS=FAIL
CHECK=gep01 STATUS=FAIL
REASON=gep01 exited with status 2
VERDICT=FAIL
```

The four failures are:

1. `readat.HC: SHAPE_DEPENDENT counter = ? (expected >= 1): shape_dependent marker not found in stderr`
2. `IR_GEP = REJECTED (sibling opcode still rejected): could not read cap verifier output`
3. `IR_LEA = REJECTED (sibling opcode still rejected): could not read cap verifier output`
4. `IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset): could not read cap verifier output`

Failures 2–4 share root cause: `could not read cap verifier output` —
a sandbox/env failure (`ar: error: couldn't create cache file
'/var/folders/0g/.../xcrun_db-...': errno=Operation not permitted`).
Failure 1 is a `stderr` marker scan in the same environment.
**All four reproduce on upstream `main` byte-for-byte**, so they are
**UPSTREAM_BASELINE_FAILURE**, not REBASE_REGRESSION.

The harness delta vs `origin/main` is 29 files / +2218/-1, identical to
the pre-ACT local-only delta — proving no rebase regression.

**VALIDATION_VERDICT = PASS_FOR_THIS_ACT_SCOPE**
(Existing applicable validation gates pass on both the harness and on
`main`. The pre-existing upstream `gep01` toolchain-env failure is
truthfully classified as `UPSTREAM_BASELINE_FAILURE` and explicitly
out of scope per the ACT's §9 classification rules; this ACT does not
weaken or skip any gate.)

## Local git pull configuration (steady-state)

```text
git config --local pull.ff only
git config --local pull.rebase false
```

Global git config unchanged (`(no global pull config)`).

## Final git status

```text
On branch harness/codium-polyc2
Untracked: evidence/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01/   (this ACT's evidence directory)
```

No staged, no unstaged, no other untracked files. Final checkout is
`HARNESS_BRANCH` (Section 11 satisfied).

## Acceptance contract checklist

| ID  | Criterion                                                                                       | Status |
|-----|-------------------------------------------------------------------------------------------------|--------|
| A1  | pre-ACT OLD_HEAD recorded                                                                       | PASS   |
| A2  | worktree was clean before history mutation                                                      | PASS   |
| A3  | explicit `git fetch origin main` performed                                                      | PASS   |
| A4  | backup branch points exactly to OLD_HEAD                                                        | PASS   |
| A5  | local-only history classified before mutation (DIVERGED)                                        | PASS   |
| A6  | local-only work preserved on `harness/codium-polyc2`                                            | PASS   |
| A7  | `main == origin/main` (byte-for-byte)                                                           | PASS   |
| A8  | no reconciliation merge commit introduced                                                       | PASS   |
| A9  | harness successfully rebased onto current `origin/main` (clean, 9/9)                            | PASS   |
| A10 | `origin/main` is ancestor of `harness/codium-polyc2`                                            | PASS   |
| A11 | range-diff accounts for every original local logical change                                     | PASS   |
| A12 | existing applicable PolyC validation passes; baseline failures truthfully classified             | PASS   |
| A13 | no remote refs were modified (`git push` not invoked; remote URLs unchanged)                    | PASS   |
| A14 | `pull.ff=only` configured repository-locally only                                               | PASS   |
| A15 | final checkout is `HARNESS_BRANCH`                                                              | PASS   |
| A16 | backup branch remains present and will not be auto-garbage-collected (kept as named branch ref)  | PASS   |

## Files in this evidence packet

```
evidence/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01/
  REPORT.md                         (this file)
  OLD_HEAD.txt
  BACKUP_BRANCH.txt
  HARNESS_BRANCH.txt
  pre-ACT-status.txt
  pre-ACT-branches.txt
  pre-ACT-remotes.txt
  pre-ACT-left-right.txt            (graph of HEAD vs origin/main)
  pre-ACT-local-only-commits.txt    (9 commits that had to be preserved)
  pre-ACT-diff-stat.txt             (29 files / +2218/-1 pre-rebase diff)
  rebase-output.txt                 (clean rebase: 9/9)
  range-diff.txt                    (range-diff: every local change preserved)
  post-ACT-harness-commits.txt      (9 rebased SHAs)
  gate-fast-output.txt              (fast gate on harness: PASS)
  gate-fast-main.txt                (fast gate on main:    PASS)
  gate-push-harness.txt             (push gate on harness: UPSTREAM_BASELINE_FAILURE)
  gate-push-main.txt                (push gate on main:    UPSTREAM_BASELINE_FAILURE — same 26/4)
  final-graph.txt                   (--all --decorate --max-count=80)
```

## Residue (out of scope per ACT §Out of scope)

* The upstream `gep01` toolchain env failures are `UPSTREAM_BASELINE_FAILURE`
  and belong to whatever upstream ACT currently owns `GEP01`.
* Stale orphan local-only branches (`__budget_probe_*`, `__n8*`) predate
  this ACT and are unrelated to upstream-resync. They are NOT removed
  per F7 (no silent scope expansion). Recorded here for transparency.
