# ACT-POLYC-FACTORY-APPEND-ONLY-LINEAGE-RECONCILE01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Class:** TOOLING / FACTORY / PROCESS

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** ACT-POLYC-FACTORY-HISTORY-RECONCILE01 and
ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01 (the historical
append-only doctrine and its mechanical guard). The confirmed
CORRECTION03 governance breach is recorded in the successor handoff
and is not hidden by this ACT.

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

---

## Mission

Freeze and permanently disclose the complete post-boundary ancestry
loss caused by local `main` resets, preserve every affected commit
identity and its object metadata, and reconcile the affected lineages
into a forward-only descendant of the current `main` without changing
the current production tree or rewriting any existing commit.

In one sentence:

> Preserve and reconcile the complete discarded ancestry behind true
> merge commits whose resulting tree is the already-verified current
> tree, while truthfully recording that the append-only invariant was
> historically breached.

This ACT does not erase the breach. Its successful verdict is
`PASS_LINEAGE_RECONCILED_WITH_HISTORICAL_VIOLATION`.

---

## Why

The confirmed governance audit established that local resets removed
13 post-boundary reset tips and 20 affected commit identities from
current `main` ancestry. The original commit objects remain present,
but content reintroduction does not restore commit identity or
parentage.

The affected lineages cannot be reconciled under CORRECTION03's
authorization. A separate governance ACT is required to authorize
recovery refs, non-linear commit topology, and true merges. This ACT
provides that narrow authority.

---

## Scope

### allowed

- `docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-LINEAGE-RECONCILE01.md` (this
  authorization artifact);
- `evidence/factory-append-only-lineage-reconcile01/` (the immutable
  inventory, simulation, implementation, and closure evidence);
- one or more namespaced recovery refs under `refs/archive/` that
  preserve the discarded tips before reconciliation;
- true-merge commits on `main` that make the required discarded
  identities ancestors while preserving the current tree;
- an additive disclosure in `AGENTS.md` and/or
  `docs/factory/DOCTRINE.md` if the measured reconciliation requires
  one;
- a narrowly scoped correction to the Factory-v2 range checker only if
  the measured merge topology makes the existing checker reject an
  otherwise valid governance ACT range.

### forbidden

- `git commit --amend`, `git rebase`, `git filter-branch`,
  `git filter-repo`, `git replace`, `reset + recommit`, cherry-pick
  used to rebuild/discard lineage, squash merge, or force push;
- changing, replacing, or discarding any existing commit object;
- changing compiler, language, IR, ABI, runtime, or production
  semantics;
- restoring obsolete discarded file content into the current tree;
- modifying CORRECTION03, replaying CORRECTION03 commits, or closing
  CORRECTION03 C4;
- pushing any ref;
- pruning, repacking, expiring, or otherwise collecting the discarded
  objects before preservation;
- broad ref cleanup or removal of existing unrelated refs.

---

## Required evidence

### E01 — Complete reset inventory

Record every post-boundary reset transition with old tip, new tip,
reflog timestamp, old/new trees, old/new parents, and the exact raw
reflog record. Completeness is proved by enumerating all `reset:`
records from the append-only boundary forward and classifying every
old tip by ancestry.

### E02 — Complete affected commit inventory

Record every affected commit identity with object ID, tree, parents,
author/committer metadata, subject, and trailer block. Prove:

- every required object exists as a commit and tree;
- every required identity is currently unreachable from `main`;
- the set is closed under the recorded parent relationships needed to
  explain the lost lineages;
- no identity is omitted merely because later content was reintroduced.

### E03 — Immutable external preservation

Before the live reconciliation, create a repository-external copy
outside the working tree that contains the complete inventory, raw
reflog records, object IDs and metadata, and a Git bundle containing
every required commit and ancestor. Record the external copy path and
SHA-256 digest. Live recovery refs are an additional mechanism, not a
substitute for the external copy.

### E04 — Minimal covering tips

Compute the minimum set of candidate tips whose ancestry covers every
required identity. Prove minimality by exhaustive set-cover search
over the bounded candidate set. Record all minimum solutions or the
selected one with the exclusion proof.

### E05 — Disposable reconciliation simulation

In a disposable repository, simulate the selected true-merge pattern.
Prove every required identity becomes an ancestor of the simulated
tip, the entry `main` remains an ancestor, the simulated tree equals
the frozen entry tree, and no obsolete production content is
restored.

### E06 — Factory-v2 topology decision

Before writing a live merge, mechanically test the selected topology
against `scripts/quality/factory-v2-range-check.sh`. If the checker
rejects a valid governance range because it enumerates the merged
side's unrelated ancestry, either use a topology whose ACT range
remains mechanically valid or make a narrowly scoped validator
correction under this ACT, with its own RED and synthetic negative
controls. The validator correction MUST NOT weaken phase, trailer, or
closure checks.

---

## Implementation boundary

The minimum implementation is:

1. record the E01/E02 inventories and E03 external backup;
2. create namespaced recovery refs for the selected covering tips;
3. create one or more true-merge commits on `main`, each carrying
   `ACT: ACT-POLYC-FACTORY-APPEND-ONLY-LINEAGE-RECONCILE01` and
   `ACT-Phase: IMPL`;
4. preserve the entry tree in the resulting tip;
5. record closure evidence and disclosure.

The merge strategy MAY be `-s ours` if E05 and E06 prove that it
creates real merge ancestry while preserving the frozen tree. The
selected strategy and its exact reason must be recorded. Doctrine §23
requires a true merge and both required lineages to become ancestors;
it does not itself prohibit the `ours` strategy, so this ACT must
qualify that choice mechanically rather than assume it.

---

## Acceptance criteria

### AC01 — inventory completeness

A command over the frozen inventory proves 13 post-boundary reset
transitions and 20 affected identities, with no unclassified
post-boundary reset old tip.

### AC02 — object and metadata preservation

Every affected identity and tree exists and its recorded metadata
matches `git cat-file` / `git show` output.

### AC03 — external backup integrity

The external bundle and inventory exist outside the repository, and
their recorded SHA-256 digests match freshly measured digests.

### AC04 — minimal cover

The exhaustive cover computation proves the selected covering-tip set
covers all 20 identities and no smaller candidate set does.

### AC05 — simulation qualification

The disposable simulation proves all required identities reachable,
entry `main` retained as ancestor, and exact tree equality.

### AC06 — live recovery refs

Each selected covering tip is reachable from a namespaced
`refs/archive/` recovery ref before the live merge.

### AC07 — live ancestry

Every required affected identity is an ancestor of the post-merge
`main`, and the pre-merge `main` tip is an ancestor of the post-merge
`main`.

### AC08 — live tree conservation

The post-merge `main` tree equals the frozen entry `main` tree.

### AC09 — no production delta

The path-level diff from entry `main` to post-merge `main` is limited
to this ACT's ACT/evidence/disclosure/validator files. Compiler
production paths are byte-identical.

### AC10 — no history rewrite

No replace ref exists, no existing commit identity changed, no force
push occurred, and the append-only guard suite passes.

### AC11 — Factory-v2 range validity

The current Factory-v2 range checker returns `STATUS=PASS` for this
ACT's close commit, or the separately justified and tested validator
correction is present and the range passes.

### AC12 — truthful disclosure

The closure evidence states that the append-only invariant was
historically breached and lists the 13 resets and 20 affected
identities. No evidence claims the breach never occurred.

### AC13 — hygiene and gates

The ACT range has clean `git diff --check`, the relevant Factory gates
pass, the worktree is clean, and no push occurred.

---

## Conservation gates

Run against the exact post-reconciliation subject:

```sh
sh scripts/quality/gate-fast.sh
sh scripts/quality/factory-v2-test.sh
sh scripts/quality/factory-append-only-test.sh
sh scripts/quality/factory-v2-range-check.sh ACT-POLYC-FACTORY-APPEND-ONLY-LINEAGE-RECONCILE01 HEAD
git diff --check <entry>..HEAD
git status --porcelain=v1
```

No compiler semantic test is required for a tree-preserving governance
merge beyond the existing broad gate, because AC08 proves byte-level
tree conservation for the production subject.

---

## HALT conditions

- `HALT_INVENTORY_INCOMPLETE` — the reset or affected-identity
  inventory cannot be proven complete;
- `HALT_OBJECT_MISSING` — a required commit or tree is unavailable;
- `HALT_PRESERVATION_INCOMPLETE` — the external bundle or inventory
  cannot be created and digest-verified before mutation;
- `HALT_COVER_UNPROVEN` — the minimum covering set cannot be proved;
- `HALT_SIMULATION_FAILED` — the disposable simulation cannot reach
  every identity while preserving the frozen tree;
- `HALT_TOPOLOGY_UNDECIDED` — Factory-v2 range semantics cannot be
  qualified before the live merge;
- `HALT_GIT_OPERATOR_ERROR` — an authorized Git operation fails;
- `HALT_CONSERVATION_GATE_REGRESSION` — a content regression is
  introduced by reconciliation;
- `HALT_SCOPE_EXPANSION_REQUIRED` — completion requires mutation
  outside this ACT's allowed scope.

---

## Residue (pre-declared)

- **P1:** local-main non-fast-forward protection is not supplied by
  the remote pre-push hook. A separate bounded ACT should evaluate a
  local update mechanism.
- **P1:** unreachable objects remain at collection risk until the
  external bundle and live recovery refs are in place. This ACT MUST
  create them before reconciliation.
- **P2:** the historical violation remains permanent fact even after
  successful reconciliation.

---

## Execution metadata

Execution identity is stored in Git commit trailers.

Every ACT commit:

```text
ACT: ACT-POLYC-FACTORY-APPEND-ONLY-LINEAGE-RECONCILE01
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
```

CLOSE additionally:

```text
ACT-Verdict: PASS_LINEAGE_RECONCILED_WITH_HISTORICAL_VIOLATION
```

or the applicable `HALT_*` verdict.

The ACT document is not modified at closure.

---

## Closure handoff

Use the Factory v2 HANDOFF template at
`docs/factory/HANDOFF-TEMPLATE.md`. The HANDOFF is descriptive only;
the CLOSE commit's `ACT-Verdict` trailer is authoritative.

The successor CORRECTION03 continuation remains a separate decision
after this ACT closes. This ACT does not itself resume CORRECTION03.

---

## Entry gate

Required before any mutation:

```sh
git branch --show-current
git status --short
git rev-parse HEAD
git rev-parse HEAD^{tree}
git replace -l
```

Required state:

- branch `main`;
- clean tracked and untracked worktree;
- replacement-ref namespace empty;
- entry HEAD and tree recorded;
- the current HEAD tree is frozen as the required post-reconciliation
  tree.

---

## Principal RED

The real failing witness is the repository graph itself:

1. enumerate every post-boundary `reset:` transition in the `main`
   reflog;
2. enumerate the complete affected commit-identity set;
3. prove each identity is currently unreachable from `main`;
4. prove the minimal covering-tip set required to make all identities
   ancestors;
5. prove in a disposable repository that the selected merge pattern
   reaches all required identities while preserving the frozen tree.

The pre-reconciliation RED is the fact that the affected identities
are not ancestors of current `main`. No production code is changed by
this ACT.

---
