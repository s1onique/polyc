# Factory v2: Git Metadata

This document is the canonical binding detail for the
metadata model that Factory v2 ACTs MUST follow.

Factory v2 is the authoritative process contract for **ACTs
opened after ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01 closes**.
Historical Factory v1 ACTs remain grandfathered per V2-13
and F14.

---

## 1. Source-of-truth hierarchy

```
Git               = execution identity and topology
ACT document      = authorization and intent
Commit trailers   = execution phase and closure verdict
HANDOFF document  = human summary, NOT verdict authority
```

A HANDOFF MUST NOT carry an authoritative verdict field; the
verdict lives on the CLOSE commit's `ACT-Verdict` trailer.

---

## 2. Trailer grammar

Every ACT commit message MUST follow the standard Git
trailer format (subject line, blank, body, blank, trailers
as `Key: value` lines). Parsing is delegated to
`git interpret-trailers --parse`.

### 2.1 Required trailers

```
ACT: ACT-POLYC-<id>
ACT-Phase: <RED | IMPL | EVIDENCE | CLOSE>
```

`<id>` regex:

```
^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+$
```

The `+` quantifier requires at least two characters after
the `ACT-POLYC-` prefix. A single-character suffix such as
`ACT-POLYC-A` is rejected.

Cardinality:

* `ACT:`       -- exactly 1
* `ACT-Phase:` -- exactly 1
* `ACT-Verdict:` -- exactly 0 for RED / IMPL / EVIDENCE;
  exactly 1 for CLOSE.

### 2.2 Verdict grammar

When present (CLOSE only), `ACT-Verdict:` MUST match:

```
^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$
```

`OPEN` is not a closure verdict.

This is POSIX-ERE (used by `grep -E`). Do NOT use
shell-glob `case` patterns or PCRE-only constructs
(`(?:...)`, lookarounds, backreferences).

Examples:

* `ACT-Verdict: PASS`
* `ACT-Verdict: PASS_WITH_NEXT_ACT_DECISION`
* `ACT-Verdict: PASS_WITH_NONBLOCKING_RESIDUE`
* `ACT-Verdict: HALT_RED_NOT_REPRODUCED`
* `ACT-Verdict: HALT_SCOPE_CONTRACT_VIOLATED`

### 2.3 Supersession trailers (CLOSE only)

For correction ACTs that supersede a predecessor:

```
ACT-Supersedes: ACT-POLYC-<predecessor-id>
ACT-Corrected-Verdict: <token>
```

Rules:

1. `ACT-Supersedes` is OPTIONAL. If present, it appears
   ONLY on the CLOSE commit.
2. `ACT-Corrected-Verdict` is OPTIONAL. If present, it
   appears ONLY on the CLOSE commit AND
   `ACT-Supersedes` MUST also be present.
3. `ACT-Corrected-Verdict` value MUST itself match the
   verdict grammar (it is a verdict about the predecessor).
4. The correction's own CLOSE carries its own `ACT-Verdict`
   (typically `PASS`); the corrected verdict is recorded in
   `ACT-Corrected-Verdict`.

Example:

```
ACT: ACT-POLYC-LLVM-CORE04-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-LLVM-CORE04
ACT-Corrected-Verdict: HALT_RED_NOT_REPRODUCED
```

Interpretation:

* the correction ACT itself PASSES;
* the predecessor's historical closure is corrected to
  `HALT_RED_NOT_REPRODUCED`;
* no HANDOFF rewrite is needed.

### 2.4 HALT classification trailers (additive)

Per `ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01` (and
`docs/factory/DOCTRINE.md` §25), two ADDITIVE trailers
classify every HALT_* CLOSE commit. They are required
on every new `HALT_*` CLOSE commit and forbidden on
every new `PASS(_...)*` CLOSE commit. Historical CLOSE
commits are grandfathered (see §0.1 of the ACT).

```
HALT_CLASS:  GOVERNANCE | PRODUCTION | SAFETY |
             AUTHORIZATION | DEPENDENCY

BLOCKS_NEXT: YES | NO
```

Cardinality rules:

* `HALT_CLASS` -- exactly 0 on a `PASS(_...)*` CLOSE;
  exactly 1 on a `HALT_*` CLOSE.
* `BLOCKS_NEXT` -- exactly 0 on a `PASS(_...)*` CLOSE;
  exactly 1 on a `HALT_*` CLOSE.

Combination rules:

| HALT_CLASS      | BLOCKS_NEXT     |
|-----------------|-----------------|
| `GOVERNANCE`    | `NO`            |
| `PRODUCTION`    | `YES`           |
| `SAFETY`        | `YES`           |
| `AUTHORIZATION` | `YES`           |
| `DEPENDENCY`    | `YES` or `NO`   |

Example:

```
ACT: ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
ACT-Phase: CLOSE
ACT-Verdict: HALT_GOVERNANCE_HALT
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

Interpretation: this ACT closed with a HALT verdict;
the halt is classified as governance (procedural,
narrative, or bookkeeping) and DOES NOT block the
next same-scope ACT from opening.

### 2.5 Parsing note

The `HALT_CLASS` and `BLOCKS_NEXT` keys contain
underscores. `git interpret-trailers --parse` (as of
git 2.54.0) does NOT accept underscores in trailer
keys and silently drops such trailers. The bounded
verifier at
`scripts/quality/factory-halt-classification-check.sh`
therefore parses trailers directly with `grep -E`
against the documented `<KEY>:[[:space:]]+<VALUE>`
shape, instead of delegating to
`git interpret-trailers --parse`.

This implementation choice is a v1 simplification. If
a future git version accepts underscores in trailer
keys, the verifier MAY delegate to
`git interpret-trailers --parse` and the parsing note
MUST be updated to record the new behavior. The
trailer semantics are unchanged.

---

## 3. ACT range derivation

For a closed Factory-v2 ACT:

```
CLOSE  = commit carrying ACT=<id> and ACT-Phase=CLOSE
FIRST  = first commit in the immediately contiguous
         backwards run carrying ACT=<id>
ENTRY  = FIRST^
RANGE  = ENTRY..CLOSE
```

These are computed facts, not pre-baked SHAs in a Markdown
document.

Mechanical recipe (see `factory-v2-range-check.sh`):

1. Resolve `<CLOSE-COMMIT>` via `git rev-parse`.
2. Verify CLOSE has exactly one `ACT: <id>`, exactly one
   `ACT-Phase: CLOSE`, exactly one `ACT-Verdict:`.
3. Walk parents backwards while each commit carries
   `ACT: <id>`. The first parent that does NOT carry this
   ACT marks the boundary.
4. FIRST must have `ACT-Phase: RED`.
5. FIRST..CLOSE must contain exactly one CLOSE, and CLOSE
   must be the last commit in the range.
6. Every commit in FIRST..CLOSE must carry `ACT: <id>` with
   a valid `ACT-Phase:` in `{RED, IMPL, EVIDENCE, CLOSE}`.
7. No commit after CLOSE may carry `ACT: <id>`.

---

## 4. Identity ownership

No Factory-v2 ACT, HANDOFF, closure report, or evidence file
MAY claim the SHA of the commit that contains it.

Forbidden:

* `FINAL_HEAD=this commit`
* `FINAL_HEAD=<literal SHA of containing commit>`
* `DOCS_HEAD=next commit`
* `CLOSURE_HEAD=<self>`
* `ENTRY_HEAD=<self>`
* `RED_HEAD=<self>`
* `IMPLEMENTATION_HEAD=<self>`

Evidence files MAY reference immutable subjects (commits
that already exist when the evidence is generated). They
MUST NOT reference the SHA of the evidence-carrying commit.

---

## 5. Commit topology

There is no numeric commit-count cap in Factory v2.

Commits MUST be:

* **bounded by ACT scope**;
* **contiguous** (one ACT = one linear range);
* **honestly classified** (each commit's `ACT-Phase`
  trailer reflects what the commit actually is);
* **individually meaningful** (no manufactured commits).

Reviewers may still reject an ACT for scope explosion; they
MAY NOT reject an ACT merely because `count > arbitrary
integer`.

When unrelated work must intervene mid-ACT, the current ACT
MUST be HALTed (or finished and CLOSEd), and the unrelated
work becomes a separate ACT.

---

## 6. HANDOFF template (Factory v2)

A Factory-v2 HANDOFF is descriptive only. It MUST NOT carry:

* `Status:`
* `VERDICT:`
* `FINAL_HEAD:`
* `CLOSURE_HEAD:`
* `DOCS_HEAD:`
* `IMPLEMENTATION_HEAD:`
* `worktree=clean`

Recommended structure:

```markdown
# HANDOFF -- <ACT-ID>

Factory-Version: 2

## Result

<short human-readable result>

Closure verdict is authoritative in the `ACT-Verdict`
trailer of the ACT's CLOSE commit.

## What changed

- ...

## Evidence

- ...

## Production delta

- ...

## Residue

- P1 ...
- P2 ...

## Recommended next ACT

<ACT-ID>
```

---

## 7. ACT template (Factory v2)

A Factory-v2 ACT is an authorization artifact. It MUST NOT
carry:

* mutable `Status:` field;
* SHA identity tables;
* `FINAL_HEAD`, `ENTRY_HEAD`, `DOCS_HEAD`, `CLOSURE_HEAD`,
  `IMPLEMENTATION_HEAD` fields;
* a numeric commit cap.

Recommended header:

```markdown
# <ACT-ID>

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

## Mission
...

## Scope
...

## Forbidden
...

## Principal RED
...

## Acceptance criteria
...

## HALT conditions
...

## Execution metadata

Execution identity is stored in Git commit trailers.

Every ACT commit:
    ACT: <ACT-ID>
    ACT-Phase: RED|IMPL|EVIDENCE|CLOSE

CLOSE additionally:
    ACT-Verdict: <exact verdict>
```

---

## 8. Reviewer procedure

For a closed Factory-v2 ACT, a reviewer runs:

```sh
sh scripts/quality/factory-v2-range-check.sh <ACT-ID> HEAD
```

and obtains:

```
ACT=<id>
ENTRY=<derived>
FIRST=<derived>
CLOSE=<derived>
COMMITS=<derived>
VERDICT=<derived>
STATUS=PASS
```

Then the reviewer inspects the range:

```sh
git show --stat <close>
git log <entry>..<close> --format=full
git status --porcelain=v1
git diff --check <entry>..<close>
```

No reviewer needs to compare Markdown SHA tables.

---

## 9. Tooling surface

```
scripts/quality/factory-v2-commit-msg-check.sh
  - opt-in commit-message validator (rc=0 for non-ACT
    commits; rc=1 for invalid ACT trailers)

scripts/quality/factory-v2-range-check.sh
  - mechanical ACT-range reviewer helper
  - prints ACT/ENTRY/FIRST/CLOSE/COMMITS/VERDICT/STATUS

scripts/quality/factory-v2-test.sh
  - T1..T18 binding test matrix
  - synthetic repo only; no production state touched

.githooks/commit-msg
  - thin wrapper around the validator
  - enabled by core.hooksPath = .githooks
  - opt-in: ordinary commits pass; ACT commits are
    grammar-checked
```

These are the entire Factory v2 surface. There is no
database, daemon, registry, or external dependency.

---

## 10. Non-goals

Factory v2 does NOT decide:

* cryptographic signing of ACT commits;
* CI enforcement of trailers;
* GitHub branch protection integration;
* legacy ACT migration;
* deletion of `factory-closure-status-check.sh` or
  `llvm-closure-status-check.sh`;
* concurrent ACTs on multiple branches;
* merge-commit semantics;
* autonomous agent closure of ACTs.

---

## Append-only invariant (post-RECONCILE01)

Per ACT-POLYC-FACTORY-HISTORY-RECONCILE01 §19, the following
normative rule binds all Factory-v2 ACTs opened after that ACT
closes:

```text
Commits at and after APPEND_ONLY_START_POINT are immutable
evidence. Corrections are new commits. Authoritative main is
synchronized by fast-forward or true merge, never by history
replacement.
```

Where:

```text
APPEND_ONLY_START_POINT = baf5dbd77cf89330699685dffd932c54031c815c
```

### Prohibited mechanisms (additive, do not weaken existing rules)

* `git commit --amend` on any commit at or after the boundary
* `git rebase` / `git rebase -i` / autosquash / fixup rewriting
  on any commit at or after the boundary
* `git filter-branch` / `git filter-repo` on the authoritative
  repository state
* `git replace` (the replacement namespace must remain empty
  throughout every ACT lifecycle)
* `git push --force` / `--force-with-lease` / force refspec
  markers to the authoritative remote

### Mechanical binding (per ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01 and its CORRECTION01)

The local pre-push hook (`.githooks/pre-push`) is the binding
artifact. It enforces three graph-property checks against the
authoritative destination ref `refs/heads/main`, using the
protocol fields defined by `githooks(5)`:

```text
authoritative destination:
    remote_ref == refs/heads/main

deletion:
    local_sha == 0000...0000

existing-main update:
    remote_sha != 0000...0000

required FF condition:
    git merge-base --is-ancestor $remote_sha $local_sha

remote_sha == 0000...0000:
    creation of a previously nonexistent remote main,
    not deletion
```

Graph-property checks against `refs/heads/main`:

```text
1. git replace -l must be empty
2. local_sha == 0000...0000 is rejected (delete of main)
3. git merge-base --is-ancestor $remote_sha $local_sha must hold
   (every non-FF update of an existing main, including force-push
   shapes, is rejected)
```

Topic branches are intentionally not policed by this rule.

The hook enforces graph properties of the resulting ref
transition; it does NOT parse `git push` command-line flags.
The permanent regression suite is
`scripts/quality/factory-append-only-test.sh` (NC1..NC11); the
hook contract is locked to that suite and F5 forbids weakening
the suite to obtain a green PASS.

The binding to `remote_ref` (not `local_ref`) and to
`local_sha == ZERO` (not `remote_sha == ZERO`) is governed by
`ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01`.

### Required mechanism for divergence

If two authoritative lineages diverge (e.g. parallel rewrites
during ACT execution), they are reconciled by **true merge**:

```sh
git merge --no-ff --no-commit <archive-tip>
# resolve conflicts per unique-patch-ledger + final-tree-contract
git commit
```

The merge commit has both archive tips as parents. The archive
refs themselves remain frozen at their ENTRY SHAs.

### Compatibility with Factory v2 trailers

Append-only does not weaken F1–F15 or the Factory-v2 trailer
grammar. ACTs continue to carry `ACT:`, `ACT-Phase:`, and (for
CLOSE) `ACT-Verdict:` trailers. Merge commits inside an ACT range
follow the same grammar; their message documents the parent
identities and the resolution ledger.
