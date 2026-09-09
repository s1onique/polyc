# ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Class:** TOOLING / FACTORY / PROCESS (correction)

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01
(closed `a537672`, `ACT-Verdict: PASS`; reviewer verdict
**HOLD** against the committed hook -- the protocol
binding was on the wrong field.)

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

---

## Mission

Bind the pre-push hook's append-only enforcement for
authoritative `main` to the **remote-side** protocol fields
that Git actually supplies, add protocol-shape negative
controls that the previous ACT was missing, and update the
doctrine / AGENTS.md so the corrected rule is the rule that
gets repeated.

In one sentence:

> The hook enforces graph properties of the
> `<remote_ref, remote_sha> -> <local_sha>` transition for
> `remote_ref = refs/heads/main`; the test suite proves the
> hook refuses every shape of rewrite Git can actually
> deliver to that ref, not just the shapes the original ACT
> happened to encode.

This ACT does NOT reopen the parent ACT's reconciliation,
does NOT redesign the hook, does NOT remove the
`gate-push.sh` hygiene, and does NOT change any compiler,
IR, ABI, or LLVM code.

---

## Why

A reviewer of the closed `APPEND-ONLY-GUARD01` committed
state (`a537672`, `ACT-Verdict: PASS`) returned verdict
**HOLD** with two binding bugs in the hook's append-only
block.

### Bug P0-1 -- deletion detection is backwards

Git's documented pre-push protocol (`githooks(5)`) encodes
a ref deletion as

```text
local_ref        = (delete)
local_sha        = 0000000000000000000000000000000000000000
remote_ref       = refs/heads/main
remote_sha       = <existing remote tip>
```

(see `https://git-scm.com/docs/githooks` -- "If a ref is
to be deleted, the `<local-ref>` will be supplied as
`(delete)` and the `<local-object-name>` will be the
all-zeroes object name.").

The closed hook checks:

```sh
if [ "$local_ref" = "refs/heads/main" ]; then
    if [ "$remote_sha" = "$ZERO_SHA" ]; then
        ... halt main-deletion ...
```

For a real `git push origin :main`, `local_ref = (delete)`,
so the outer `if` is false and the deletion guard never
fires. The hook **accepts deletion of `main`**. Empirically
reproduced at HEAD before this correction: rc=0 for the
delete shape.

The original ACT's NC4 used the encoding

```text
local_ref  = refs/heads/main
local_sha  = <real SHA>
remote_ref = refs/heads/main
remote_sha = 0000000000000000000000000000000000000000
```

which per the protocol is **"create main"** (the remote has
no `main` yet; this push makes one). The hook therefore
"correctly" rejected a benign shape. The actual delete shape
was never tested.

### Bug P0-2 -- authoritative ref is the remote ref

Git documents `git push origin master:foreign` as

```text
refs/heads/master  <sha>  refs/heads/foreign  <sha>
```

so the source ref (`local_ref`) and the destination ref
(`remote_ref`) can differ. `git push origin feature:main`,
`git push origin HEAD:refs/heads/main`, and pushes from
detached SHAs are all legal and all produce a `remote_ref
= refs/heads/main` update with a `local_ref` that is NOT
`refs/heads/main`.

The closed hook keys the append-only guard on `local_ref`
and therefore **accepts every rewrite of `main` whose
source is not literally `refs/heads/main`**. Empirically
reproduced at HEAD before this correction.

The same hole covers `git push origin HEAD:refs/heads/main`
and any push whose source is a raw SHA or `HEAD~N`.

### Fix shape

Per `githooks(5)`, the rule that closes both holes is:

```sh
if [ "$remote_ref" = "refs/heads/main" ]; then
    # deletion
    if [ "$local_sha" = "$ZERO_SHA" ]; then
        ... halt main-deletion ...
    fi
    # update
    if [ "$remote_sha" != "$ZERO_SHA" ]; then
        if ! git merge-base --is-ancestor \
                "$remote_sha" "$local_sha"; then
            ... halt main-non-fast-forward ...
        fi
    fi
fi
```

The `local_sha == ZERO_SHA` predicate is the documented
deletion sentinel. The `remote_ref` predicate names the
authoritative ref, not the user's source branch. The
"remote is empty (no main yet)" branch is left alone --
Git's documented protocol for a fresh main is a legitimate
push shape, and the doctrine says the hook only polices
forbidden outcomes of an existing main, not creation.

This is a strictly smaller change than the parent ACT
imagined; it does not introduce a new rule, it just binds
the existing rule to the right protocol field.

---

## Scope

### allowed

* `.githooks/pre-push`
* `AGENTS.md`
* `docs/factory/DOCTRINE.md`
* `scripts/quality/factory-append-only-test.sh`
* `evidence/append-only-guard01-correction01/`
* `docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01.md`
* `docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01-HANDOFF.md`
  (verdict lives on the CLOSE commit's `ACT-Verdict`
  trailer per `docs/factory/GIT-METADATA.md` §2.2.)

### forbidden

* any `src/**` change;
* any compiler, IR, ABI, LLVM, or production semantic
  change;
* any rewrite of the parent ACT or its HANDOFF
  (F14 -- the parent commit is historical evidence of
  the reviewer's HOLD finding);
* retroactive trailers on historical commits;
* rebases, history rewriting, or amend chains;
* removing or weakening
  `scripts/quality/factory-closure-status-check.sh`,
  `scripts/quality/llvm-closure-status-check.sh`,
  `scripts/quality/factory-v2-test.sh`,
  `scripts/quality/factory-v2-commit-msg-check.sh`,
  `scripts/quality/factory-v2-range-check.sh`;
* removing or weakening the existing
  `gate-fast.sh` / `gate-push.sh` hygiene;
* a new Git-command-string blacklist (the hook enforces
  graph properties, not command strings);
* daemon / registry / DB additions;
* any third-party dependency;
* reconciliation work on the 551-ahead graph
  (F14: historical topology is frozen as evidence).

If a forbidden action turns out to be required for
correctness: `HALT_SCOPE_EXPANSION_REQUIRED`.

---

## Principal RED

The closed hook fails four adversarial cases that Git's
protocol can actually deliver. Reproduction captured at
HEAD before this correction:

```text
RED-1  (delete) ZERO refs/heads/main <tip>
       Expected: rc=1 (POLYC_PRE_PUSH_HALTED=main-deletion)
       Observed: rc=0 (delete accepted)

RED-2  refs/heads/feature <tip> refs/heads/main <old>
       Expected: rc=1 (POLYC_PRE_PUSH_HALTED=main-non-fast-forward)
       Observed: rc=0 (rewriting main via feature accepted)

RED-3  HEAD <tip> refs/heads/main <old>
       Expected: rc=1
       Observed: rc=0 (literal-source rewriting main accepted)

RED-4  The parent ACT's NC4 was encoding
       "create main when remote has none", not "delete main".
       The real delete shape was untested. NC8 below
       replaces NC4's encoding with the protocol-correct
       delete shape.
```

Full transcript (rc values, hook output) at
`evidence/append-only-guard01-correction01/red-pre-impl-extra.txt`
and notes at
`evidence/append-only-guard01-correction01/red-notes.txt`.

---

## Acceptance criteria

### AC01 -- hook refuses a real delete of `main`

Synthetic repo; stdin simulates
`(delete) ZERO refs/heads/main <tip>`. Hook exits
non-zero with `POLYC_PRE_PUSH_HALTED=main-deletion`.
Captured in
`evidence/append-only-guard01-correction01/ac01-real-delete.txt`.

### AC02 -- hook refuses a non-FF `feature:main` push

Synthetic repo; stdin simulates
`refs/heads/feature <NEW> refs/heads/main <OLD>` where
`OLD !ancestor NEW`. Hook exits non-zero with
`POLYC_PRE_PUSH_HALTED=main-non-fast-forward`. Captured
in
`evidence/append-only-guard01-correction01/ac02-feature-non-ff.txt`.

### AC03 -- hook refuses a non-FF `HEAD:main` push

Synthetic repo; stdin simulates
`HEAD <NEW> refs/heads/main <OLD>` where
`OLD !ancestor NEW`. Hook exits non-zero. Captured in
`evidence/append-only-guard01-correction01/ac03-head-non-ff.txt`.

### AC04 -- hook accepts a legitimate FF `feature:main`

Synthetic repo; stdin simulates
`refs/heads/feature <NEW> refs/heads/main <OLD>` where
`OLD ancestor NEW`. Hook exits zero. Captured in
`evidence/append-only-guard01-correction01/ac04-feature-ff.txt`.

### AC05 -- regression suite green with the corrected hook

`scripts/quality/factory-append-only-test.sh` exercises
NC1..NC11 and reports PASS for each. The parent's NC4
was renamed (NC8 below) to encode the real delete
shape; new NC8, NC9, NC10, NC11 cover the source-name
and literal-source shapes. Captured in
`evidence/append-only-guard01-correction01/ac05-suite.txt`.

### AC06 -- doctrine names the right fields

`docs/factory/DOCTRINE.md` §24
`F-GIT-APPEND-ONLY` says the guard is keyed on
`remote_ref == refs/heads/main` and that deletion is
detected by `local_sha == 0000...0000`, not the
previous (incorrect) `remote_sha == 0000...0000`.

### AC07 -- AGENTS.md mechanical-enforcement subsection
matches the hook

`AGENTS.md` "Append-only Git history / Mechanical
enforcement" enumerates the same three checks against
the correct fields.

### AC08 -- production conservation

`git diff --name-only <ENTRY>..HEAD -- src/` is empty.

`gate-fast.sh` still PASSes; the existing
`factory-v2-test.sh` PASS=35 FAIL=0; no historical
ACT/HANDOFF is rewritten.

### AC09 -- hygiene at closure

At the live closure observation:

```sh
git diff --check                rc=0
sh scripts/quality/gate-fast.sh rc=0
git status --porcelain=v1       empty
```

---

## HALT conditions

* `HALT_RED_NOT_REPRODUCED` -- any of AC01, AC02, AC03,
  AC04 cannot be reproduced against the synthetic repo.
* `HALT_SCOPE_EXPANSION_REQUIRED` -- correct completion
  requires changing files outside the allowed list.
* `HALT_TEST_WEAKENING` -- closing the suite by relaxing
  an expected-rejection condition, or by removing a new
  NC that exercises a real protocol shape. (F5.)

---

## Residue (pre-declared)

* P0 -- none anticipated.
* P1 -- server-side enforcement
  (`receive.denyNonFastForwards=true` /
  `receive.denyDeletes=true`, plus the GitHub
  branch-protection equivalent) is an operator action and
  remains intentionally out of scope.
* P2 -- merge-aware range checker (unchanged from parent
  ACT).
* P2 -- the historical 551-ahead graph (F14: frozen).

---

## Execution metadata

Execution identity lives in commit trailers:

```text
ACT: ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
```

`ACT-Verdict:` on the CLOSE commit only.

Reviewer procedure:

```sh
sh scripts/quality/factory-v2-range-check.sh \
    ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01 HEAD
git show --stat <close>
git log <entry>..<close> --format=full
git status --porcelain=v1
git diff --check <entry>..<close>
sh scripts/quality/factory-append-only-test.sh
```

---

## Closure handoff

Factory v2 HANDOFF at
`docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-CORRECTION01-HANDOFF.md`.
No authoritative verdict field; verdict lives on the
CLOSE commit's `ACT-Verdict` trailer per
`docs/factory/GIT-METADATA.md` §2.2.

