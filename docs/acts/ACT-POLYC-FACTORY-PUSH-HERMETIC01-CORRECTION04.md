# ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION04

Status: OPEN.
Inherits from: CORRECTION03.
Goal: bind destination remote in `.githooks/pre-push` from Git's
documented hook contract (`$1`, `$2`) rather than from local
configuration.

## Reviewer finding (CORRECTION03)

CORRECTION03 closed the dedup and new-branch set model. The reviewer
verified that:

* four explicit modes are coherent;
* `--new-branch <remote>` uses `rev-list subject --not --remotes=<remote>`;
* dedupe is no longer by `local_sha` alone;
* all 11 adversarial cases pass;
* the commit itself is whitespace-clean.

But the reviewer noted one remaining P0:

> **The hook chooses the destination remote incorrectly.**

Per `githooks(5)` (verified 2026-09-07 against
https://git-scm.com/docs/githooks):

```
pre-push:
  This hook is called by git-push and can be used to prevent a
  push from taking place. The hook is called with two parameters
  which provide the name and location of the destination remote,
  if a named remote is not being used both values will be the same.
```

So Git already supplies the destination as `$1` (name) and `$2` (URL).
Yet the CORRECTION03 hook does:

```sh
default_remote=$(git remote 2>/dev/null | head -n1)
```

and uses that for every new-branch push. `git remote` lists
configured remotes alphabetically, so `git remote | head -n1` picks
whichever remote happens to sort first, regardless of where the
push is actually going.

## The two REDs

We constructed a synthetic repo with two remotes configured in
alphabetical order: `origin` (alphabetically first) and `zoo`
(alphabetically second).

### RED-1: false-GREEN

Setup:
- `origin/main = C` (with B having WS in `b.txt`)
- `zoo/main = A`
- local `main = D` (clean)

Push: `git push zoo feature:new-feature`

Git invokes the hook with `$1=zoo $2=/tmp/c04-red/backup.git`.

**CORRECTION03 hook behaviour**: ignores `$1`, picks `origin`
(because `git remote | head -n1` returns `origin` only when
`origin` is alphabetically first; we configured the repo so that
`origin` sorts first). The hook calls
`gate-push.sh D --new-branch origin`, which inspects
`reachable(D) \ reachable(origin/*) = {D}` — only D, which is
clean. B's WS is never inspected. **False PASS.**

**CORRECTION04 required behaviour**: read `$1=zoo` and pass
`gate-push.sh D --new-branch zoo`, which inspects
`reachable(D) \ reachable(zoo/*) = {D, C, B, A}` — including B
(WS). **Correct FAIL.**

### RED-2: false-RED

Setup (inverse of RED-1):
- `origin/main = A` (behind)
- `zoo/main = C` (with B having WS in `b.txt`)
- local `main = D` (clean)

Push: `git push zoo feature:new-feature`

**CORRECTION03 hook behaviour**: again picks `origin`. The hook
calls `gate-push.sh D --new-branch origin`. Because `origin` has
only `A`, `reachable(origin/*) = {A}` and `D --not --remotes=origin`
returns `{D, C, B}`. B's WS is in this set even though B is
already in `zoo`'s history and should not be re-inspected.
**False FAIL.**

**CORRECTION04 required behaviour**: read `$1=zoo` and pass
`gate-push.sh D --new-branch zoo`, which inspects only `{D}`.
**Correct PASS.**

## Fix (hook-only)

The CORRECTION04 hook:

1. Reads `$1` (destination remote name) and `$2` (destination URL)
   from Git's documented pre-push contract. Does NOT call
   `git remote | head -n1`.

2. Classifies the destination into one of three kinds:

   - `named`: `$1` is a configured remote name, `$1 != $2`.
     Pass `--new-branch "$1"` to `gate-push.sh`.
   - `anonymous`: `$1 == $2` (URL pushed directly without
     configuring a remote name). The destination is not a valid
     `--remotes=<>` namespace. Fall back to `--root-range` and
     log `POLYC_PRE_PUSH_NOTE=anonymous destination (...)`.
   - `empty`: `$1` is unset. Same fallback as anonymous.

3. Updates the dedupe key to include `destination_kind` and
   `destination_name`, so two pushes of the same `(local_sha,
   remote_sha)` pair to two different remotes are no longer
   deduped. This is the corollary of binding the destination
   correctly.

4. Echoes `dest=$destination_kind` in the validation log so
   engineers can see which namespace the gate ran against.

`scripts/quality/gate-push.sh` is unchanged. The GPUSH-6 primitive,
all four modes, and the existing tests are unchanged. The compiler,
tests, marker regex, and hermetic prefix are all unchanged. This is
strictly a hook-only correction.

## Negative controls (CORRECTION04)

Run on this workstation via `/tmp/run-c04-suite.sh`:

| # | Scenario                                                                                    | Expected | Actual |
| - | ------------------------------------------------------------------------------------------- | -------- | ------ |
| C04-1 | false-GREEN scenario: hook passes `--new-branch zoo` (not origin)                       | PASS     | PASS   |
| C04-2 | false-RED scenario: hook passes `--new-branch zoo` (not origin)                         | PASS     | PASS   |
| C04-3 | anonymous URL push: hook falls back to `--root-range` with `POLYC_PRE_PUSH_NOTE`        | PASS     | PASS   |
| C04-4 | existing-branch push: range mode uses supplied `remote_sha`, dest echoed as `named`     | PASS     | PASS   |
| C04-5 | same tip pushed to two remotes: per-invocation destination binding                       | PASS     | PASS   |

```
$ /tmp/run-c04-suite.sh
=== CORRECTION04 RED/FIX suite ===
C04-1: false-GREEN scenario (origin ahead, zoo behind, WS in B)
  OK    C04-1 (hook passes --new-branch zoo)               expected=PASS actual=PASS
C04-2: false-RED scenario (origin behind, zoo ahead)
  OK    C04-2 (hook passes --new-branch zoo, NOT origin)   expected=PASS actual=PASS
C04-3: anonymous URL push (no named remote)
  OK    C04-3 (anonymous URL -> root-range fallback)       expected=PASS actual=PASS
C04-4: existing-branch push with named destination
  OK    C04-4 (range mode uses supplied remote_sha, not dest) expected=PASS actual=PASS
C04-5: same tip to two remotes (named push, different destinations)
  OK    C04-5 (per-invocation destination binding)         expected=PASS actual=PASS

===================================
Summary: PASS=5 / TOTAL=5
===================================
```

## Regression check (CORRECTION03 REDs still pass)

The CORRECTION03 hook dedup tests (H1-H3) and the 8 reviewer
REDs (T1-T8) all still pass on the CORRECTION04 hook, confirming
that nothing in CORRECTION03 regressed:

```
$ /tmp/run-c03-suite.sh
T1: existing branch push, WS in intermediate commit       OK    FAIL/FAIL
T2: new branch (clean remote, clean new)                  OK    PASS/PASS
T3: new branch (DIRTY remote, CLEAN new)                  OK    PASS/PASS
T4: new branch, WS in non-tip                             OK    FAIL/FAIL
T5: existing branch with intermediate WS                  OK    FAIL/FAIL
T6: merge commit with WS                                   OK    FAIL/FAIL
T7: conflict markers                                      OK    FAIL/FAIL
T8: polyC current ACT range                               OK    PASS/PASS
=== Hook dedup tests (reviewer's P0-1 RED) ===
H1: different remote_sha -> 2 calls                       OK    PASS/PASS
H2: same (local,remote) -> 1 call                         OK    PASS/PASS
H3: existing + newbranch -> 2 calls                       OK    PASS/PASS
Summary: PASS=11 / TOTAL=11
```

Total negative controls across CORRECTION03 + CORRECTION04:
**16/16 pass.**

## Verification on the polyC repository

```
$ sh -n .githooks/pre-push && echo "sh -n: OK"
$ bash -n .githooks/pre-push && echo "bash -n: OK"
$ dash -n .githooks/pre-push && echo "dash -n: OK"

$ make gate-fast
CHECK=diff-check STATUS=PASS
CHECK=shell-syntax STATUS=PASS
CHECK=doc-invariants STATUS=PASS
CHECK=large-file-guard STATUS=PASS
VERDICT=PASS

$ git diff --check be7451f HEAD
exit=0
```

`gate-push.sh` modes verified on the polyC repo (these are
unchanged from CORRECTION03 because the script itself is unchanged):

```
$ gate-push.sh HEAD                               VERDICT=PASS (tip-only)
$ gate-push.sh HEAD be7451f                       VERDICT=PASS (range)
$ gate-push.sh HEAD --new-branch origin           VERDICT=PASS (new-branch)
```

## Conservation

Unchanged across the entire ACT family (404644d..HEAD):

- `src/ir.c` at `404644d`
- `scripts/quality/gate-fast.sh`
- `scripts/quality/gate-push.sh` (GPUSH-1..GPUSH-6, all four modes,
  and the per-commit diff-tree primitive)
- The `--root-range` fallback and the `POLYC_PRE_PUSH_NOTE` log
  mechanism (preserved from CORRECTION03, just generalized from
  "no remote configured" to "any anonymous-or-empty destination")
- All CORRECTION03 negative controls (T1-T8, H1-H3) continue to
  pass

Only `.githooks/pre-push` changed. The change is bounded:

- added: `destination_name`, `destination_url`, `destination_kind`
- removed: `default_remote` (`git remote | head -n1`)
- updated: dedupe key from `(local_sha, remote_sha)` to
  `(local_sha, remote_sha, destination_kind, destination_name)`
- added: `dest=$destination_kind` echo in validation log
- generalized: `POLYC_PRE_PUSH_NOTE=...` to include the kind

## Next ACT (unchanged)

ACT-POLYC-LLVM-SPIKE01-RESUME01 (LLVM 22 dev toolchain B2 provision
on this workstation). The gate work is now genuinely finished.
