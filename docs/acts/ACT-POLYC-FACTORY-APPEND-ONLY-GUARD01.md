# ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Class:** TOOLING / FACTORY / PROCESS (hardening)

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** ACT-POLYC-FACTORY-HISTORY-RECONCILE01
(the reconciliation ACT that bound `APPEND_ONLY_START_POINT` and
forbade rewrite mechanisms, but did not deliver executable
enforcement.)

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

---

## Mission

Make append-only Git history a mechanically enforced Factory
invariant for authoritative `main` by giving the existing
pre-push hook the small set of graph-property checks it needs
and binding those checks with an executable regression suite.

In one sentence:

> The pre-push hook enforces graph properties of the resulting
> ref transition; the test suite proves the hook refuses every
> shape of rewrite we declared forbidden in
> ACT-POLYC-FACTORY-HISTORY-RECONCILE01 §19.

This ACT does NOT reopen reconciliation, does NOT redesign the
hook, does NOT add a blacklist of Git command strings, and does
NOT change any compiler, IR, ABI, or LLVM code.

---

## Why

`ACT-POLYC-FACTORY-HISTORY-RECONCILE01` froze the append-only
doctrine and recorded one narrow pre-push guard:

```sh
git replace -l  # must be empty
```

That was the minimum needed at the time. The doctrine also
forbids the broader rewrite space:

```text
amend, rebase, filter-branch, filter-repo,
git replace, reset + recommit,
squash merge, --force push
```

...with the normative correction mechanism being a new commit,
and the only legal ways to advance authoritative `main` being
a fast-forward or a true merge. But none of those rules was
mechanically enforced at the local push boundary; they lived
as Markdown.

The fork graph (`main` is 551 commits ahead of the upstream
head) is historical baggage. We accept it. But we should not
let future work reintroduce the same pathology by accident.
The minimum that prevents accidental regression of the
append-only invariant is:

1. refuse to push if `refs/replace` is non-empty (already in
   place; bind with a permanent regression test);
2. refuse to push if `refs/heads/main` would be deleted;
3. refuse to push if the resulting `refs/heads/main`
   transition is not a fast-forward.

These are graph properties of the proposed ref update. Git's
pre-push hook contract gives us the local and remote SHAs of
every ref being pushed, which is precisely the information we
need. We do NOT need to parse `git push` command-line arguments
to detect force pushes; a non-fast-forward transition is what
matters, regardless of how the user typed it.

---

## Scope

### allowed

* `.githooks/pre-push`
* `AGENTS.md`
* `docs/factory/DOCTRINE.md`
* `docs/factory/GIT-METADATA.md`
* `scripts/quality/factory-append-only-test.sh`
* `evidence/factory-append-only-guard01/`
* `docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01.md`
* `docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-HANDOFF.md`
  (HANDOFF may not carry an authoritative verdict per Factory
  v2 HANDOFF template; verdict lives on the CLOSE commit's
  `ACT-Verdict` trailer.)

### forbidden

* any `src/**` change;
* any compiler, IR, ABI, LLVM, or production semantic change;
* any rewrite of historical ACT/HANDOFF files
  (V2-13 / F14 grandfather policy);
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
* a new Git-command-string blacklist (the hook enforces graph
  properties, not command strings);
* daemon / registry / DB additions;
* any third-party dependency;
* reconciliation work on the 551-ahead graph
  (F14: historical topology is frozen as evidence).

If a forbidden action turns out to be required for correctness:
`HALT_SCOPE_EXPANSION_REQUIRED`.

---

## Principal RED

The hook already partially enforces the invariant
(`refs/replace` non-empty is rejected). The principal RED is
that two of the three graph-property checks declared in
ACT-POLYC-FACTORY-HISTORY-RECONCILE01 §19 are *not*
mechanically enforced and have no permanent regression test.

The four RED witnesses captured in
`evidence/factory-append-only-guard01/red-*.txt`:

```text
RED-1  no rejection of refs/heads/main deletion
RED-2  no rejection of non-fast-forward update of main
RED-3  refs/replace non-empty rejection exists in the hook but
       has no regression test binding it permanently
RED-4  no executable regression suite for the append-only
       invariant as a whole
```

Reproduction for RED-1 and RED-2:

```sh
# Synthetic repo only. Does not touch production.
TMP=$(mktemp -d)
cd "$TMP" && git init -q -b main .
echo s > s && git add s && git -c core.hooksPath=/dev/null commit -qm s
# Plumb the production pre-push hook into the synthetic repo.
git config core.hooksPath "$REPO_ROOT/.githooks"
# Pretend remote main is the seed SHA.
printf 'refs/heads/main %s refs/heads/main 0000000000000000000000000000000000000000\n' \
  "$(git rev-parse HEAD)" | sh "$REPO_ROOT/.githooks/pre-push" origin "$TMP"
# Expected after this ACT: rc=1 (delete rejected).
# Observed before IMPL: rc=0 (delete accepted).
```

A second reproduction exercises a non-fast-forward update:

```sh
# Same synthetic repo, now with two children.
echo a > a && git add a && git -c core.hooksPath=/dev/null commit -qm a
echo b > b && git add b && git -c core.hooksPath=/dev/null commit -qm b
# Pretend the remote main is the first child.
parent=$(git rev-parse HEAD^)
local=$(git rev-parse HEAD)
printf 'refs/heads/main %s refs/heads/main %s\n' "$local" "$parent" \
  | sh "$REPO_ROOT/.githooks/pre-push" origin "$TMP"
# Expected after this ACT: rc=1 (non-FF rejected).
# Observed before IMPL: rc=0 (non-FF accepted).
```

RED-3 and RED-4 are demonstrated by the fact that
`scripts/quality/factory-append-only-test.sh` does not exist
prior to this ACT.

---

## Acceptance criteria

### AC01 -- hook refuses main deletion

Synthetic repo; stdin simulates a push that deletes
`refs/heads/main`. Hook exits non-zero. Captured in
`evidence/factory-append-only-guard01/ac01-delete-main.txt`.

### AC02 -- hook refuses non-fast-forward main update

Synthetic repo; stdin simulates a push whose `local_sha` is
not a descendant of `remote_sha` for `refs/heads/main`. Hook
exits non-zero. Captured in
`evidence/factory-append-only-guard01/ac02-non-ff-main.txt`.

### AC03 -- hook accepts fast-forward main update

Synthetic repo; stdin simulates a normal fast-forward update
of `refs/heads/main`. Hook exits zero. Captured in
`evidence/factory-append-only-guard01/ac03-ff-main.txt`.

### AC04 -- hook accepts a non-main ref update unconditionally

Synthetic repo; stdin simulates a fast-forward of a topic
ref (e.g. `refs/heads/feature`). Hook exits zero. The hook
only polices `refs/heads/main`; topic branches remain
unpoliced by this ACT.

### AC05 -- hook refuses push when refs/replace is non-empty

Synthetic repo with `refs/replace` populated. Hook exits
non-zero before any ref is processed. Captured in
`evidence/factory-append-only-guard01/ac05-replace-non-empty.txt`.

### AC06 -- permanent regression suite exists and passes

`scripts/quality/factory-append-only-test.sh` exercises NC1..NC7
on synthetic repos and reports PASS for each. Captured in
`evidence/factory-append-only-guard01/ac06-test-suite.txt`.

### AC07 -- doctrine states the rule compactly

`docs/factory/DOCTRINE.md` carries a one-section
`F-GIT-APPEND-ONLY` rule that names the forbidden mechanisms,
the required mechanism, and the hook's enforcement posture
("graph properties, not a blacklist").

### AC08 -- AGENTS.md points to the binding detail

`AGENTS.md` carries the same compact rule (or a tighter
reference to it) under the existing "Append-only Git history"
section, with the test script path.

### AC09 -- production conservation

`git diff --name-only <ENTRY>..HEAD -- src/` is empty.

`gate-fast.sh` still PASSes; the existing
`factory-v2-test.sh` T1..T34 still PASS; no historical ACT
or HANDOFF is rewritten.

### AC10 -- hygiene at closure

At the live closure observation:

```sh
git diff --check               rc=0
sh scripts/quality/gate-fast.sh rc=0
git status --porcelain=v1      empty
```

---

## HALT conditions

* `HALT_RED_NOT_REPRODUCED` -- any of AC01, AC02, AC05 cannot
  be reproduced against the synthetic repo.
* `HALT_SCOPE_EXPANSION_REQUIRED` -- correct completion
  requires changing files outside the allowed list.
* `HALT_TEST_WEAKENING` -- closing the suite by relaxing an
  expected-rejection condition. (F5.)

---

## Residue (pre-declared)

* P0 -- none anticipated.
* P1 -- server-side enforcement
  (`receive.denyNonFastForwards=true` /
  `receive.denyDeletes=true`, plus the GitHub branch-protection
  equivalent) is an operator action and is intentionally
  out of scope for this ACT. Recorded here so it does not
  drift back into the Factory backlog as "Factory work".
* P2 -- merge-aware range checker (the Factory-v2 range check
  currently reports `COMMITS=1` on a merged ACT range and the
  reviewer must read the merge commit message to find the
  second tip). Not a defect, just an ergonomic shortcoming.
  Out of scope per the agreed board.
* P2 -- the historical 551-ahead graph. F14: frozen as
  evidence; do not reopen.

---

## Execution metadata

Execution identity lives in commit trailers:

```text
ACT: ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01
ACT-Phase: RED | IMPL | EVIDENCE | CLOSE
```

`ACT-Verdict:` on the CLOSE commit only.

Reviewer procedure:

```sh
sh scripts/quality/factory-v2-range-check.sh \
    ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01 HEAD
git show --stat <close>
git log <entry>..<close> --format=full
git status --porcelain=v1
git diff --check <entry>..<close>
sh scripts/quality/factory-append-only-test.sh
```

---

## Closure handoff

Factory v2 HANDOFF at
`docs/acts/ACT-POLYC-FACTORY-APPEND-ONLY-GUARD01-HANDOFF.md`.
No authoritative verdict field; verdict lives on the CLOSE
commit's `ACT-Verdict` trailer per `docs/factory/GIT-METADATA.md`
section 2.2.