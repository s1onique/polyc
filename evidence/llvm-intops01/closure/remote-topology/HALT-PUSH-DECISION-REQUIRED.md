# HALT — Push-decision required (F15: never self-authorize scope expansion)

## Final status of INTOPS01

INTOPS01 evidence and CLOSE commit are complete and immutable on
local main:

```
HEAD     = adb202c0ce45577b36b3685d59cab93ed192dc3e
ACT      = ACT-POLYC-LLVM-INTOPS01
ACT-Phase= CLOSE
ACT-Verdict=HALT_RED_NOT_REPRODUCED
```

All into-scope gates pass:

```
gate-fast.sh                         STATUS=PASS  VERDICT=PASS
factory-v2-test.sh                   PASS=35      FAIL=0
llvm-intops01-test.sh                PASS=4       FAIL=0
llvm-spike-test.sh                   PASS=18      FAIL=0
llvm-memory01-test.sh                PASS=6       FAIL=0
llvm-float01-test.sh                 PASS=29      FAIL=0
llvm-cap-table-verifier.py           PASS
```

`git diff --check` clean. Tracked tree is clean. Worktree is
git-dirty only because of one untracked build directory
(`build_test_prefix/`), which is correctly excluded from the ACT
commit (it is a `make install DESTDIR=...` artifact required
because `tos.HH` is only available post-install, and it is listed
in `.gitignore`-equivalent scope: never tracked, never intended
to be tracked, see ENTRY/env note in HANDOFF.md).

## Why the count looks alarming but is mostly Git noise

`git status -sb` style divergence:

```
382 commits reachable only from local main
374 commits reachable only from origin/main
```

The cherry-equivalence breakdown (per reviewer recommendation):

```
git rev-list --left-right --cherry-mark --count HEAD...origin/main
  => 13   5   738
```

That is:

```
LOCAL_PATCH_UNIQUE  =  13
REMOTE_PATCH_UNIQUE =   5
CHERRY_EQUIVALENT   = 738
TOTAL_SHA_DELTA     = 756
```

Of the 13 local-unique commits:

```
 8 commits: substantive PolyC Factory work not on remote at all
           - 0778954 PARITY01 RED: x86_64 native FCMP NaN defect reproducer
           - 4102adc PARITY01 IMPL: x86_64 SETcc encoder ModR/M + float-cmp composition
           - f8bb456 PARITY01 EVIDENCE: IR_FCMP witness + harness + ACT + HANDOFF + evidence
           - be6a54a PARITY01 EVIDENCE: refactor fixtures to TRUE/FALSE format for clarity
           - 590f37b PARITY01 CLOSE: PASS verdict (8/8 positive + 8/8 NC)
           - 62d5128 ROADMAP: pivot critical path to self-hosting substrate
           - 28c778e ROADMAP: tighten P3 transition wording
           - adb202c test(llvm): close INTOPS01 after B0-demand recon
 5 commits: merge-commits with same content as remote's merges
           but different SHAs because each rewrite gave them
           different parent commits:
           - 1539200 Merge pull request #1 (linux)
           - 060b957 Merge pull request #2 (io-library)
           - 33b369d Merge pull request #222 (finish-ir)
           - 33e68a2 Merge pull request #223 (hashtable)
           - a589d42 Merge pull request #224 (mem2reg)
```

Of the 5 remote-unique commits: all 5 are merge-commits that are
**the same conceptual merges** as local's 5 above, just with
different parents on the remote rewrite chain:

```
  - 283a176 Merge pull request #1 (linux)
  - 6afe5f5 Merge pull request #2 (io-library)
  - 753344b Merge pull request #222 (finish-ir)
  - 04fa184 Merge pull request #223 (hashtable)
  - fc01ffd Merge pull request #224 (mem2reg)
```

So the **substantive semantic divergence is 8 commits on local**:
PARITY01's 5-chain + ROADMAP×2 + INTOPS01 CLOSE. Everything else
in the 756-commit SHA delta is plumbing noise from two parallel
history rewrites of the same conceptual commits.

## Both tips now archived (no rewriting)

```
git branch archive/local-main-before-reconcile    HEAD          (=adb202c)
git branch archive/origin-main-before-reconcile   origin/main   (=429b804)
git tag    archive-local-main-2026-09             HEAD          (=adb202c)
git tag    archive-origin-main-2026-09            origin/main   (=429b804)
```

Both archive branches are local-only (no upstream tracking).
Both archives point at the current tip of their respective lineage.
Neither history has been rewritten; both lineages remain fully
reachable from `adb202c` and `429b804` respectively.

## Why none of the three standard push strategies are safe under current rules

The Factory-v2 doctrine **forbids rewriting either lineage again**.
This rules out rebase, filter-branch, amend, reset-and-recommit,
force-push, and `git replace`. The only permissible operation is
**append-only merging**, which creates new commits but does not
change existing ones.

Concretely, the three push paths and why each is currently
inappropriate:

1. **`git push` (fast-forward)** — rejected by the remote.
   Confirmed by the 382/374 divergence. **Blocked.**

2. **Rebase + push** — would create *new* SHAs for every commit
   in the rewrite chain by changing their parents. This is exactly
   the operation that the "no rewriting" rule forbids. Even if it
   succeeded it would replace ~750 commit SHAs with new ones,
   violating the rule. **Forbidden by doctrine.**

3. **Force-with-lease** — overwrites remote's 374 commits with
   local's 382. The remote's MERGE01-CORRECTION01/02 chains (commits
   on remote but not on local with distinct content) would be lost
   in the rewrite even if we later cherry-picked them back. **Forbidden
   by doctrine.**

The only remaining option is **append-only reconciliation via merge**,
which creates a new merge commit and a new lineage but preserves
both old lineages.

## What the operator must decide

The append-only merge is a legitimate Factory-v2 operation, but it
is **outside INTOPS01's authorized scope**. Per F15 the merge must
be its own bounded Factory-v2 ACT. Three legitimate patterns, all
of which require a new ACT:

A. **`reconcile/main-history` branch as canonical**.
   Create `reconcile/main-history` pointing at `origin/main`,
   merge `archive/local-main-before-reconcile` (no fast-forward).
   This brings all 8 substantive local commits into a new lineage
   whose tip is reachable from `origin/main` and from `adb202c`.
   Push `reconcile/main-history` to `origin/main` via a fast-forward
   or a non-fast-forward merge commit on the remote side.

B. **The opposite orientation** — create `reconcile/main-history`
   pointing at `adb202c`, merge `archive/origin-main-before-reconcile`.
   The result has the same shape; the difference is which lineage
   is the "main line" of the merge and which is the "side branch".

C. **A two-merge topology** — first merge `adb202c` into a new
   branch off `origin/main` (preserves local's PARITY01+ROADMAP+INT
   work in remote's lineage), then merge the new branch back into
   `main`. This produces the same final tree state but with two
   merge commits instead of one, which is auditable but slightly
   uglier.

All three patterns preserve both old lineages (per the doctrine)
and bring the 8 substantive local commits into a single canonical
tree. The choice between A/B/C is a project-level policy decision
that this agent must not make unilaterally.

## Recommendation

1. Operator reviews this HALT.
2. Operator chooses pattern A, B, or C.
3. Operator opens `ACT-POLYC-FACTORY-HISTORY-RECONCILE01` (or
   equivalent) with the chosen pattern as its mission.
4. The new ACT executes the merge, runs the full closure gates
   on the merged tree, and (if PASS) pushes the result.
5. INTOPS01's CLOSE commit `adb202c` is preserved on the archive
   branch regardless of which pattern is chosen, and is reachable
   from the merged tree via `archive/local-main-before-reconcile`.

## Summary

```
Compiler:
  PARITY01       PASS  (8/8 positive + 8/8 NC)
  INTOPS01       honest HALT_RED_NOT_REPRODUCED

Self-host path:
  INTOPS01       eliminated as implementation work
  BYTE-MEMORY01  next compiler capability

Git:
  local/remote histories massively SHA-diverged (756 commits)
  but semantic divergence is only 8 substantive commits
  (PARITY01 chain + ROADMAP x2 + INTOPS01 CLOSE)
  plus 10 merge-commit SHA collisions (same content, different parents)
  both tips archived before any reconciliation

Immediate blocker:
  one append-only merge ACT to reconcile the two histories
  push decision deferred to that ACT
```

The INTOPS01 evidence and CLOSE commit are not at risk under any
pattern. The HALT predates the push decision, and the push decision
is a separate bounded ACT.
