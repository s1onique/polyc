# ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02

## Verdicts so far

**HALT_CORRECTION01_CLOSURE_IDENTITY** raised by review against
`a5818c66cbbb6f447ea636f30925b63e408d0aa4` after the prior ACT was
declared PASS — resolved by this ACT's first phase.

**HALT_CORRECTION02_DYNAMIC_BINDING_SCOPE** raised by review after
this ACT's first phase declared PASS — also resolved by this ACT's
second phase (commit `6e7bc4d`).

## Scope (bounded)

Docs/evidence-only repair of the closure identity for the previous ACT.
**No source code changes.** No new compiler behaviour.

The reviewer accepted:

```text
P0-1 compiler repair                        PASS
P0-2 historical evidence restoration        PASS
harness isolation from historical C1 dir    PASS
13/0 LLVM matrix                            PASS
```

The reviewer rejected:

```text
closure HEAD identity                       FAIL / STALE
committed final gate binding                FAIL / STALE
declared 3-commit topology                  FAIL / CONTRADICTED
```

This ACT mechanically repairs those three closure-bookkeeping items
without touching the compiler.

## Required actions

1. **Reconcile topology honestly.** Record the complete lineage from
   `ENTRY_HEAD = bde6045a200a1526435fd161f41b59e02df012b7` through
   `HEAD` (which is currently `a5818c66cbbb6f447ea636f30925b63e408d0aa4`).
   Do not collapse intermediate commits into "part of closure" or
   "part of IMPL"; record every commit that exists in the range.

2. **Replace self-pinned `HEAD=` identity with dynamic binding.**
   Use:

   ```sh
   SUBJECT=$(grep '^SUBJECT=' <final-gate-log> | head -1 | cut -d= -f2)
   SUBJECT_FULL=$(git rev-parse "$SUBJECT^{commit}")
   git merge-base --is-ancestor "$SUBJECT_FULL" HEAD
   ```

   The committed gate transcript must be the one whose `SUBJECT`
   matches `git rev-parse HEAD` AT THE TIME the tree was qualified,
   i.e. the gate log committed in the same docs commit.

3. **Commit the real final gate transcript.** The previously
   committed transcript in this ACT's evidence dir has
   `SUBJECT=f703cecab5c5`; HEAD at that commit was `a5818c6`. Replace
   it with the transcript produced by running `gate-push.sh HEAD`
   against the substantive final tree (`a5818c6`), so that
   `SUBJECT=a5818c66cbbb6f447ea636f30925b63e408d0aa4`.

4. **Re-run the P0-2 historical-evidence diff and `git diff --check`.**
   These must still pass after the docs-only repair; if they don't,
   HALT (not silently fix the source).

## Out of scope

* Any change to `src/llvm-backend.c`.
* Any change to `scripts/quality/llvm-spike-test.sh`.
* Any change to `src/tests/llvm-spike/red_local_multi_def.HC`.
* Any new RED/IMPL work.
* Renaming the previous ACT or rewriting its own committed text
  (F14: historical evidence stays historical).

## Identity

```text
ENTRY_HEAD  = bde6045a200a1526435fd161f41b59e02df012b7
PREV_ACT    = ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01
PREV_HEAD   = a5818c66cbbb6f447ea636f30925b63e408d0aa4  (was the previous ACT's HEAD)
HEAD        = (this ACT)
CLOSURE     = (this ACT)
```

## Acceptance criteria

1. `git log --oneline bde6045a..HEAD` enumerates the same lineage as
   the previous ACT plus the docs commits added by this ACT.
2. `git rev-list --count bde6045a..HEAD` is `previous_count + N`
   where `N` is the number of commits this ACT adds.
3. The committed final gate transcript has
   `SUBJECT=$(git rev-parse HEAD)` at the time of the substantive
   tree's closure commit.
4. The committed HANDOFF and identity files use dynamic binding
   (`grep SUBJECT <gate log>`) instead of a hard-coded `HEAD=`.
5. The P0-2 mechanical AC
   `git diff bde6045a..HEAD -- <three C1 files>` remains empty.
6. `git diff --check HEAD` returns rc=0.
7. No production source files are modified.

## Required actions (CORRECTION02-RESUME01 phase)

After this ACT's first phase declared PASS, the reviewer raised
**HALT_CORRECTION02_DYNAMIC_BINDING_SCOPE**:

> merge-base --is-ancestor alone does not prove that later descendants
> are docs/evidence-only descendants.

Three corrections required (all docs/evidence-only; no source changes):

1. **Strengthen the dynamic oracle with descendant-scope conservation.**
   Add invariant B to `identity.sh`:

   ```sh
   DELTA=$(git diff --name-only "$SUBJECT_FULL"..HEAD)
   BAD=$(printf '%s\n' "$DELTA" | grep -Ev "$(IFS='|'; echo "${ALLOWED_PATHS[*]}")" || true)
   [ -z "$BAD" ] || { echo FAIL; exit 2; }
   ```

   ALLOWED_PATHS = (^docs/, ^evidence/...01/, ^evidence/...02/)

2. **Make `identity.sh` exit nonzero on failure.**
   Replace `[ -z "$x" ] && echo PASS || echo FAIL` with explicit
   `|| { echo FAIL >&2; exit N; }` constructions under `set -e`.

3. **Snapshot-vs-authority terminology.**
   Rename generated HEAD/commit-count values from "authoritative identity"
   to "SNAPSHOT (NOT authoritative)." The authoritative oracle is the
   script's exit status, not the regenerated file.

## Acceptance criteria (CORRECTION02-RESUME01)

8. `identity.sh` exits 0 at HEAD iff all four invariants (A, B, C, D) hold.
9. `identity.sh` exits 2 on a side-branch that modifies `src/llvm-backend.c`
   post-SUBJECT (negative test for invariant B).
10. `identity.sh` exits 3 on a side-branch that mutates any of the three
    C1 files post-ENTRY_HEAD (negative test for invariant C).
11. `identity.sh` exits 4 on a tree that violates `git diff --check`.
12. `identity.sh` correctly identifies the repo root when invoked from
    any cwd (negative test for portability).
13. `snapshot.txt` and `identity.txt` are explicitly labelled SNAPSHOT
    (NOT authoritative) at every header.