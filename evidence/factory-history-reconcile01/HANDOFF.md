# HANDOFF — ACT-POLYC-FACTORY-HISTORY-RECONCILE01

This HANDOFF is descriptive only. The closure verdict lives on the
CLOSE commit's `ACT-Verdict:` trailer. The HANDOFF records the
mechanical evidence and the final state for human readers.

## VERDICT

PASS (see CLOSE commit trailer).

## MISSION

Reconcile two independently rewritten `main` histories into one
authoritative descendant **without rewriting either existing
lineage**. Preserve both archive tips as ancestors of HEAD.
Produce a pushable main that requires no `--force`.

## APPEND-ONLY POLICY

```text
APPEND_ONLY_START_POINT = baf5dbd77cf89330699685dffd932c54031c815c
```

All authoritative history at and after this boundary is treated
as immutable. The reconciliation produces only new descendant
commits. The archive refs and tags are frozen at their ENTRY SHAs.

Mechanisms forbidden by ACT §2:

```text
amend, rebase, filter-branch, filter-repo, git replace,
reset + recommit, squash merge, force push, --force-with-lease
```

None were used.

## INPUT IDENTITIES (frozen at ENTRY)

```text
archive/local-main-before-reconcile   = adb202c0ce45577b36b3685d59cab93ed192dc3e
archive/origin-main-before-reconcile  = 429b804b275712432963391c7cd212858e06e3a0
archive-local-main-2026-09            = adb202c0ce45577b36b3685d59cab93ed192dc3e
archive-origin-main-2026-09           = 429b804b275712432963391c7cd212858e06e3a0
APPEND_ONLY_START_POINT (boundary)    = baf5dbd77cf89330699685dffd932c54031c815c
```

All archive refs and tags resolve identically at CLOSE.

## RED — divergent topology

`git rev-list --left-right --count HEAD...origin/main` returned
`383\t374`. `git rev-list --left-right --cherry-mark --count
HEAD...origin/main` returned `14\t5\t738`. Neither
`is-ancestor HEAD origin/main` nor `is-ancestor origin/main HEAD`
returned 0. Ordinary push could not safely advance remote main.

The RED was recorded as a single commit (`ACT-Phase: RED`).

## CHERRY-EQUIVALENCE REDUCTION

```text
archive/local...  vs archive/origin...  --cherry-mark --count
13 local   5 remote   738 equivalent
```

Of the 738 cherry-equivalent commits: 8 substantive local-only
PARITY01/ROADMAP/INTOPS01 commits and 10 topology-collision
merges (5 local + 5 remote, all tree-equal). Zero remote-only
substantive changes.

## UNIQUE PATCH LEDGER

See `evidence/factory-history-reconcile01/recon/unique-patch-ledger.tsv`.

Summary:
* 8 KEEP_LOCAL — PARITY01 chain, ROADMAP self-host pivot + wording,
  INTOPS01 close-with-addendum
* 5 KEEP_LOCAL (merge topology) — pre-cherry-equivalent PR merges
  identical to remote counterparts
* 5 MERGE_METADATA_ONLY — remote counterparts of the above
* 0 substantive KEEP_REMOTE
* 0 HALT_OPERATOR_DECISION_REQUIRED

## FINAL TREE CONTRACT

See `evidence/factory-history-reconcile01/recon/final-tree-contract.tsv`
and `evidence/factory-history-reconcile01/impl/final-tree-verification.txt`.

All 12 contract rows PASS at CLOSE.

## MERGE — true merge, append-only

Two merge commits bring both archive tips into HEAD's
reachability:

```
dc62493  merge: fold local-archive tip into main lineage
            parent 1: d7e82af (HEAD before this commit)
            parent 2: adb202c (archive/local-main-before-reconcile)
d7e82af  merge: reconcile local and remote main lineages
            parent 1: 8d84ad3 (RED commit)
            parent 2: 429b804 (archive/origin-main-before-reconcile)
```

Both commits have exactly two parents. No `--squash`, no `--ff`,
no global `--ours`/`--theirs` shortcut.

## CONFLICTS

Two merge operations produced conflicts. Total: 16 add/add
conflict blocks across 8 files. All 16 were resolved by retaining
the HEAD content (KEEP_LOCAL per ledger). The resolution rationale
is captured in
`evidence/factory-history-reconcile01/impl/merge-resolution-ledger.tsv`.

## ANCESTRY PROOF

```text
git merge-base --is-ancestor archive/local-main-before-reconcile HEAD  -> 0
git merge-base --is-ancestor archive/origin-main-before-reconcile HEAD -> 0
git merge-base --is-ancestor baf5dbd...                              HEAD -> 0
```

All three return rc=0 (PASS).

## NO-REWRITE PROOF

```text
git replace -l  ->  (empty)
amend count     ->  0
rebase count    ->  0
force push      ->  0
```

The pre-push hook was tightened to refuse pushes when
`git replace -l` is non-empty.

## COMPILER CONSERVATION

All baseline gates PASS at CLOSE (PARITY01 unavailable on host;
all other gates confirmed):

```text
gate-fast           PASS
Factory v2          PASS (35/0)
cap-table verifier  PASS
INTOPS01            PASS (4/0)
SPIKE               PASS (18/0)
MEMORY01            PASS (6/0)
MEMORY01 NC5 load   PASS (probe trip confirmed)
MEMORY01 NC5 store  PASS (probe trip confirmed)
FLOAT01             PASS (29/0)
PARITY01            UNAVAILABLE_ON_HOST (darwin/arm64 vs x86_64)
```

## FACTORY CONSERVATION

Factory v2 trailer grammar unchanged. No SHA self-pinning.
No legacy ACT or HANDOFF evidence mutated. No numeric commit cap.
No migration of Factory-v1 evidence.

## PATCH HYGIENE

```text
git diff --check <RED-FIRST>~1..HEAD  ->  rc=0  PASS
git status --porcelain=v1             ->  empty (after staging evidence)
```

A whitespace-only fixup commit (`63b44ac`) normalises
trailing-newline hygiene introduced during the RED phase.

## PUSH

Pre-push ancestry check passed. `git push origin HEAD:main`
succeeded without `--force`. After push, `origin/main == HEAD`.

```text
git merge-base --is-ancestor origin/main HEAD   -> 0
git push origin HEAD:main                       -> 429b804..63b44ac HEAD -> main
git rev-parse origin/main                       == git rev-parse HEAD   -> PASS
```

## RESIDUE

P2 — Factory-v2 INTOPS01 single-commit HALT range check still
needs its own bounded fixup ACT. HISTORY-RECONCILE01 did not
need the HALT exception (its range is multi-commit and
closed normally) so it does not depend on that fixup.

P2 — Cross-architecture PARITY01 evidence is bound via
`frozen prior CLOSE evidence + source-tree conservation` because
the current host (darwin/arm64) cannot run the x86_64 native
test. This is not a regression introduced by this ACT.

P2 — `docs/ROADMAP.md:842` whitespace hygiene residue inherited
from PARITY01 closure is preserved by F14 (historical HALT
evidence is not rewritten). Not a regression.

P2 — Larger Git-command firewall concept (blocking `--force`,
`rebase`, etc. as process policy) is a separate future Factory
ACT. This ACT only added the minimum mechanical enforcement
(`refs/replace` empty check) per ACT §20.

## NEXT ACT

Per ACT §46:

```text
ACT-POLYC-LLVM-BYTE-MEMORY01
    ↓
ACT-POLYC-LLVM-GEP01
    ↓
ACT-POLYC-LLVM-STRUCT01
    ↓
ACT-POLYC-LLVM-ARRAY01
    ↓
ACT-POLYC-LLVM-BOOTSTRAP01
```

The compiler self-hosting path resumes immediately. Do not
insert another Factory cleanup ACT unless reconciliation itself
exposes a real blocker.
