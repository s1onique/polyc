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
^ACT-POLYC-[A-Z0-9][A-Z0-9_-]*$
```

The identifier MUST contain at least two characters after
the `ACT-POLYC-` prefix.

Cardinality:

* `ACT:`       -- exactly 1
* `ACT-Phase:` -- exactly 1
* `ACT-Verdict:` -- exactly 0 for RED / IMPL / EVIDENCE;
  exactly 1 for CLOSE.

### 2.2 Verdict grammar

When present (CLOSE only), `ACT-Verdict:` MUST match:

```
^(PASS(?:_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$
```

`OPEN` is not a closure verdict.

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
