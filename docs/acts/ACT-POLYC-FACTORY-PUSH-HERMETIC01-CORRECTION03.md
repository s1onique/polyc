# ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION03

Status: OPEN.
Inherits from: CORRECTION02.
Goal: fix two ref-set semantics defects in `.githooks/pre-push`
that survived CORRECTION02.

## Reviewer findings (CORRECTION02)

CORRECTION02 closed the GPUSH-6 primitive defects (merge commits,
conflict markers, awk parity) but did not address two semantic
defects in the **hook's range selection** that emerged only after
the primitive itself was sound:

- **P0-1 -- dedupe key is too coarse.** The hook deduplicates
  stdin lines by `local_sha` only. Git's pre-push contract permits
  the same `local_sha` to appear with **different** `remote_sha`
  values (one ref update can be a narrow clean existing-branch
  push, another can be a brand-new branch requiring broader
  inspection). Dedupe-by-`local_sha` collapses these and the
  new-branch range is never checked. This is a false-GREEN.

- **P0-2 -- root-range mode has the wrong meaning.** The current
  `0000...0000` handling makes "new branch" mean "validate every
  commit reachable from the new branch's tip, down to the empty
  tree." This conflates two distinct ideas:

  1. "the remote ref doesn't exist" (Git's actual contract for
     `remote_sha = 0000...0000`)
  2. "the destination remote has no shared history with this
     branch" (an empirical claim, not a Git-given fact)

  A new branch pushed against a remote that already has the
  branch's ancestors should NOT re-validate inherited history.
  Ancient whitespace in shared ancestors would block every new
  branch forever, which is wrong: those commits were already
  accepted when they were pushed to the remote.

## Correct new-branch semantics

For a new branch pushed against a remote that already holds its
ancestors, the set of commits being newly asked of the remote is:

```text
reachable(local_sha)
    MINUS
reachable(remote-tracking refs for the destination remote)
```

Implemented as:

```sh
git rev-list "$local_sha" --not --remotes="$remote_name"
```

This is the reviewer's literal recommendation.

Caveat: local remote-tracking refs can be stale. That is an
honest limitation of client-side pre-push hooks; Git only
provides the old OID for refs being updated, not a complete
remote reachability graph. We document this limitation rather
than calling the network.

## Fallback

For new branches pushed where the destination remote is unknown
or has no remote-tracking refs available locally (e.g. anonymous
URL push), `--remotes=<remote>` resolves to nothing and
`rev-list --not --remotes=<remote>` returns all ancestors. In
that degenerate case the behavior falls back to inspecting the
full reachable history, which is the previous CORRECTION02
behavior. We document this explicitly; we do NOT silently widen
or narrow the inspection set.

The hook extracts the destination remote name from the `remote_ref`
field. For example `refs/heads/feature` -> remote name = first
configured remote (`origin` by default), or `--root-range` if
none is configured.

## Scope

In scope (this ACT):

- `scripts/quality/gate-push.sh`:
    - accept a third argument form `--new-branch <remote_name>`
      that triggers `rev-list <subject> --not --remotes=<remote_name>`
    - keep `--root-range` as an explicit degenerate fallback
    - keep tip-only and range modes unchanged
- `.githooks/pre-push`:
    - dedupe by `(local_sha, remote_sha, remote_ref, mode)` so the
      reviewer's P0-1 RED closes
    - for new branches (remote_sha = 0000...0000), determine the
      destination remote name from `remote_ref` and pass
      `--new-branch <remote>` to gate-push.sh
    - if no remote is configured, fall back to `--root-range` and
      log the reason
- `docs/acts/ACT-POLYC-FACTORY-PUSH-HERMETIC01-CORRECTION03.md`:
    - this ACT
- `evidence/pushhermetic01_correction03/`:
    - negative controls T1..T8 from the reviewer's checklist

Out of scope (deferred to other ACTs):

- ACT-POLYC-HISTORY-HYGIENE01 -- not required. Ancient inherited
  whitespace is no longer our problem because new branches now
  inspect only newly-introduced commits.
- LLVM-SPIKE01-RESUME01
- IR-BOUNDARY02, hermetic install-prefix, and all earlier ACTs
- GPUSH-1..GPUSH-5 primitive logic (unchanged from CORRECTION02)

## Required RED (reviewer's checklist)

| # | Scenario                                                                | Expected | Actual |
| - | ----------------------------------------------------------------------- | -------- | ------ |
| T1 | existing branch: dirty intermediate in remote..local                    | FAIL     | FAIL   |
| T2 | new branch based on existing clean remote history: 2 new clean commits  | PASS     | PASS   |
| T3 | new branch based on existing remote history with ancient WS: clean new  | PASS     | PASS   |
| T4 | new branch: WS in one newly introduced non-tip commit                   | FAIL     | FAIL   |
| T5 | existing branch: dirty intermediate in remote..local (reviewer's RED variant) | FAIL | FAIL   |
| T6 | merge commit with WS in conflict resolution                             | FAIL     | FAIL   |
| T7 | non-merge commit with conflict markers                                  | FAIL     | FAIL   |
| T8 | gate-push HEAD / current ACT range                                      | PASS     | PASS   |

Plus 3 hook-level dedup tests that exercise the reviewer's P0-1 RED:

| # | Scenario                                                                                | Expected | Actual |
| - | --------------------------------------------------------------------------------------- | -------- | ------ |
| H1 | same local_sha, different remote_shas (existing + new-branch) -> 2 distinct gate runs  | PASS     | PASS   |
| H2 | same local_sha, same remote_sha, repeated lines -> exactly 1 gate run                   | PASS     | PASS   |
| H3 | same local_sha to existing-branch ref AND new-branch ref -> 2 distinct gate runs       | PASS     | PASS   |

The OLD hook (997d627) fails H1 (1 call instead of 2) and H3 (1 call
instead of 2). The NEW hook passes all 11 cases.

Run on this workstation:

```sh
$ /tmp/run-c03-suite.sh
=== CORRECTION03 RED/FIX suite ===
T1: existing branch push, WS in intermediate commit           OK    FAIL/FAIL
T2: new branch (clean remote, clean new)                      OK    PASS/PASS
T3: new branch (DIRTY remote, CLEAN new)                      OK    PASS/PASS
T4: new branch, WS in non-tip                                 OK    FAIL/FAIL
T5: existing branch with intermediate WS                      OK    FAIL/FAIL
T6: merge commit with WS                                       OK    FAIL/FAIL
T7: conflict markers                                          OK    FAIL/FAIL
T8: polyC current ACT range                                   OK    PASS/PASS
=== Hook dedup tests (reviewer's P0-1 RED) ===
H1: different remote_sha -> 2 calls                           OK    PASS/PASS
H2: same (local,remote) -> 1 call                             OK    PASS/PASS
H3: existing + newbranch -> 2 calls                           OK    PASS/PASS
Summary: PASS=11 / TOTAL=11
```

## Verification on the polyC repository

```
$ make gate-fast
CHECK=diff-check STATUS=PASS
CHECK=shell-syntax STATUS=PASS
CHECK=doc-invariants STATUS=PASS
CHECK=large-file-guard STATUS=PASS
VERDICT=PASS

$ scripts/quality/gate-push.sh HEAD                 # tip-only
VERDICT=PASS

$ scripts/quality/gate-push.sh HEAD be7451f         # range mode
VERDICT=PASS

$ scripts/quality/gate-push.sh HEAD --new-branch origin
POLYC_GATE_RANGE_MODE=new-branch
POLYC_GATE_RANGE_DESC=new branch (commits not in remote origin)
VERDICT=PASS

$ git diff --check be7451f HEAD                     # boundary hygiene
exit=0
```

Note: `gate-push.sh HEAD --new-branch origin` on the polyC repo
inspects only the 6 ACT-family commits (the diff between local
HEAD and origin/main). polyC's pre-history (238 commits with
pre-existing trailing-WS) is correctly excluded by `--not --remotes`.

## Boundary case (out of scope)

`git diff-tree --check` against a single commit inspects only the
changes that commit itself introduced. A range `remote..local`
inspects the commits in that range; if `remote` itself contains WS,
that WS is invisible to a `remote..local` inspection set. This is a
property of the CORRECTION02 primitive, not a CORRECTION03
regression, and is unchanged by this ACT.

## Conservation

Unchanged across the ACT family:

- `src/ir.c` at `404644d`
- `scripts/quality/gate-fast.sh`
- GPUSH-1..GPUSH-5 in `scripts/quality/gate-push.sh`
- GPUSH-6 primitive (per-commit `git diff-tree --check --root -m`)
  from CORRECTION02 -- the only change in gate-push.sh is the
  rev-list command line construction, not the per-commit check
- `run_check` helper and the surrounding test marker regex

## Next ACT (unchanged)

ACT-POLYC-LLVM-SPIKE01-RESUME01.
