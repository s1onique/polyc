# HALT — Push-decision required (F15: never self-authorize scope expansion)

## Status

INTOPS01 evidence and CLOSE commit are complete and immutable on
local main:

```
HEAD     = 345d3f07c64f88a4d4e5221b4a1223b001b7cde8
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

`git diff --check` clean. Worktree is clean apart from the
build_test_prefix/ build artifact (excluded from the ACT commit).

## Why I cannot decide the push unilaterally

`origin/main` and local `main` are in a **deeply divergent state**,
not the clean "Case A: rebase" or "Case B: force-with-lease" the
reviewer described. The topology is:

```
merge-base = d629c897   (much earlier than a8ff7c7)

local-only commits past merge-base:  382
remote-only commits past merge-base: 374
local HEAD    is NOT an ancestor of origin/main  (no fast-forward)
origin/main   is NOT an ancestor of local HEAD   (no trivial no-op)
```

Both branches share the **same conceptual commits** past the
merge-base but with completely different SHAs. Both branches were
rewritten independently after FLOAT01-CORRECTION01-RE-CLOSE-2:

| Logical commit                          | Local SHA  | Remote SHA |
|-----------------------------------------|------------|------------|
| FLOAT01 CORRECTION01 RE-CLOSE-2         | a8ff7c7    | 429b804    |
| FLOAT01 CORRECTION01 RE-CLOSE           | 1b0b24f    | acc9d80    |
| FLOAT01 CORRECTION01 CLOSE              | af614b1    | 7a8fd61    |
| FLOAT01 CORRECTION01 CLOSE (ledger)     | b369802    | 6691088    |
| FLOAT01 CLOSE                           | 990fac8    | c73400b    |
| FLOAT01 EVIDENCE                        | 08a347b    | 41d825b    |
| FLOAT01 IMPL                            | 0f8bcee    | 99391c4    |
| FLOAT01 RED                             | 803d0d6    | 4592d79    |
| MEMORY01-CORRECTION02 CLOSE             | bf34aea    | 4043579    |
| MEMORY01-CORRECTION02 EVIDENCE          | 05cd829    | b637c68    |
| MEMORY01-CORRECTION02 IMPL              | 7e2dde7    | 825f7be    |
| MEMORY01-CORRECTION02 RED               | 1ac8a39    | 32e2e09    |
| MEMORY01-CORRECTION01 CLOSE             | 6fe6bb3    | 015b8d8    |
| MEMORY01-CORRECTION01 EVIDENCE          | 073e009    | 23a46c9    |
| MEMORY01-CORRECTION01 EVIDENCE          | 78274d0    | 5d51c37    |
| MEMORY01-CORRECTION01 IMPL              | cfa44a6    | e7351cb    |
| MEMORY01-CORRECTION01 RED               | a5424d5    | (not in remote?) |
| MEMORY01 CLOSE                          | 49c55f9    | (not in remote?) |
| MEMORY01 EVIDENCE                       | 02619a7    | (not in remote?) |
| MEMORY01 EVIDENCE                       | e1d5fd2    | (not in remote?) |
| MEMORY01 IMPL                           | 6d188c1    | (not in remote?) |
| MEMORY01 RED                            | f1b5891    | (not in remote?) |
| RESUME01 C4 CLOSE                       | 409a89e    | (not in remote?) |
| RESUME01 C3 EVIDENCE                    | 91b759a    | (not in remote?) |
| RESUME01 C3 EVIDENCE                    | 2369599    | (not in remote?) |
| ... and so on for ~382 local-only SHAs ...                             |

This is the **fallout from prior history rewrites** (per the reviewer's
"Case B" hypothesis). Neither side is a clean descendant of the other.

## Why none of the three standard push strategies are safe

1. **`git push`** — rejected by the remote as non-fast-forward. Confirmed.

2. **`git rebase origin/main` + push** — would replay all 7 local
   commits (PARITY01 RED through INTOPS01 CLOSE) on top of remote's
   374-commit chain. The replay would (a) introduce ~7 duplicate
   PARITY01 SHAs that are conceptually identical to remote's
   existing PARITY01, and (b) silently undo the local-only
   MEMORY01 chain (since remote's MEMORY01-CORRECTION01/02 already
   cover the same work with different SHAs). Net effect:
   resurrect the rewrite chaos this effort was supposed to clean up.
   **REJECTED**.

3. **`git push --force-with-lease`** — would overwrite remote's
   374 commits with local's 382 commits, including deleting
   MEMORY01-CORRECTION01/02 which exists on remote but not local
   (because the local rewrite didn't include them). Net effect:
   delete valid completed work that was the closure of two prior
   ACTs. **REJECTED**.

4. **`git push --force-with-lease` after a merge** — would create
   a merge commit combining both rewrites, but the resulting
   topology has duplicate-content commits with different SHAs.
   The repo's history becomes ambiguous: any new clone would have
   to choose one side. **REJECTED without operator judgment on
   which rewrite is canonical**.

## What the operator must decide

This is a **scope-expansion** situation: reconciling two parallel
rewrites is not part of INTOPS01's mission. Per F15, I must HALT
rather than guess.

Three legitimate next-step patterns (all require a new bounded ACT):

A. **Designate local as canonical** (force-with-lease, accepting
   that remote's MEMORY01-CORRECTION01/02 SHAs are lost — their
   content may need to be cherry-picked or re-derived).

B. **Designate remote as canonical** (force-with-lease in the
   opposite direction, accepting that local's PARITY01+ROADMAP+INT
   chain is lost — its content would need to be re-derived).

C. **Squash-merge the divergent parts** into a single coherent
   history. This is the cleanest outcome but requires manual
   reconciliation of:
   - which rewrite of FLOAT01-CORRECTION01-RE-CLOSE/RE-CLOSE-2 is
     authoritative
   - how to merge MEMORY01-CORRECTION01/02 (only on remote) with
     MEMORY01 (only on local) into one coherent chain
   - where PARITY01 and ROADMAP and INTOPS01 go in the merged
     topology

In all three cases the **decision belongs to a new Factory-v2 ACT**
named e.g. `ACT-POLYC-FACTORY-HISTORY-RECONCILIATION02` that
addresses history reconciliation as a first-class bounded task.
INTOPS01 must NOT do this work.

## What is preserved by this HALT

The INTOPS01 evidence and the immutable CLOSE commit remain on
local main. They are not lost. The next operator action (rebase,
force-with-lease, or open new ACT) starts from a clean reproducible
state where all gates are GREEN.

A snapshot of the divergent topology is saved at:
`evidence/llvm-intops01/closure/remote-topology/snapshot.txt`

## Recommendation

1. Operator reviews this HALT.
2. Operator decides which of A/B/C is correct for PolyC's history
   policy (this is a project-level decision, not a per-ACT one).
3. Operator opens `ACT-POLYC-FACTORY-HISTORY-RECONCILIATION02`
   (or equivalent) to execute the chosen reconciliation.
4. After reconciliation, push the merged main; then
   `git push origin main` succeeds as a fast-forward.
5. INTOPS01's CLOSE commit is preserved on whichever side wins.

The reviewer asked the right question. INTOPS01's job is to add
evidence for a HALT outcome (DONE) and document the I64-only
caveat (DONE). Pushing the resulting commit is a separate
human-judgment decision that this agent must not make.
