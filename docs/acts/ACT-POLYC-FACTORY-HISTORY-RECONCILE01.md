# ACT-POLYC-FACTORY-HISTORY-RECONCILE01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Class:** TOOLING

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01
(the ACT that established the Factory v2 metadata model under
which this ACT executes). The historical
`HALT-PUSH-DECISION-REQUIRED.md` evidence file in
`evidence/llvm-intops01/closure/remote-topology/` records the
divergent-graph state this ACT is bounded to resolve.

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Adjacent historical evidence:** `ACT-POLYC-LLVM-INTOPS01`
(`evidence/llvm-intops01/HANDOFF.md` and `HANDOFF-ADDENDUM.md`)
is **CLOSED at HALT_RED_NOT_REPRODUCED** and MUST NOT be edited,
amended, rewritten, or polished by this ACT (per panel direction
turn-3: refined append-only policy belongs in the *new* Factory
surface, not retroactively in INTOPS01 evidence).

---

## Mission

Create **one new append-only history descendant** that contains
both divergent authoritative lineages (local archive tip and
remote archive tip) without altering any existing commit, and
make that descendant the new canonical tip of `main` so that an
ordinary (non-force) push to `origin/main` becomes possible.

In one sentence:

> Rejoin the two archived authoritative histories via a true
> non-fast-forward merge whose parents are exactly the two
> archive tips, and codify the prospective append-only doctrine
> at the boundary from which this ACT operates forward.

---

## Why

Local `main` and `origin/main` are non-fast-forward divergent:

```text
LOCAL_PATCH_UNIQUE  =  13  (8 substantive PolyC commits + 5
                             merge SHA collisions)
REMOTE_PATCH_UNIQUE =   5  (5 merge SHA collisions, same
                             content as local's 5 above)
CHERRY_EQUIVALENT   = 738  (same content, different SHAs from
                             parallel history rewrites)
```

The substantive semantic divergence is **8 commits on local**
(PARITY01's 5-chain + ROADMAP×2 + INTOPS01 CLOSE). The remote
contains no equivalent of any of those 8 commits.

Both tips have been preserved on archive refs:

```text
archive/local-main-before-reconcile   (local tip before reconciliation)
archive/origin-main-before-reconcile  (remote tip before reconciliation)
```

Their current SHA resolutions MUST be re-verified at ENTRY
gate time and recorded in `entry-identity.txt`. (The historical
SHA values at the time this ACT was authored are documented in
`evidence/llvm-intops01/closure/remote-topology/HALT-PUSH-DECISION-REQUIRED.md`
and the prior INTOPS01 HANDOFF; the ACT does not pin them.)

No legitimate append-only push can succeed in this state. A
force push would discard either the 8 local substantive commits
or remote's history. A rebase/replace of any descendant is
forbidden by the prospective append-only doctrine the project
has adopted. The only legitimate option is a true merge whose
parents are both archive tips.

---

## Scope

### allowed

- `docs/acts/ACT-POLYC-FACTORY-HISTORY-RECONCILE01.md` (this
  ACT contract);
- `evidence/factory-history-reconcile01/` (this ACT's closure
  evidence: identity, gates, diff-check, range-check);
- `AGENTS.md` (one additive section codifying the prospective
  append-only policy from `APPEND_ONLY_START_POINT` forward;
  existing F1–F15 laws unchanged);
- `docs/factory/DOCTRINE.md` (one additive section mirroring
  the policy and binding the `git replace -l` check at ENTRY
  and CLOSE for future Factory ACTs);
- `docs/factory/LLM-WORKFLOW.md` (one additive note pointing
  at the new policy section if not already covered).

### forbidden

- any modification to `evidence/llvm-intops01/**`;
- any modification to `docs/ROADMAP.md`;
- any modification to `docs/acts/ACT-POLYC-LLVM-INTOPS01*`;
  any past INTOPS01 commit (HALT CLOSE commit and its addendum
  commit, as documented in `evidence/llvm-intops01/`);
- any modification to
  `docs/acts/ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01*`;
- any `git commit --amend`, `git rebase`, `git filter-branch`,
  `git filter-repo`, `git replace`, `git reset --hard` against
  any existing commit;
- any `git push --force` (with or without `--force-with-lease`)
  to `origin/main`;
- any change under `src/`, `runtime/`, `compiler/`, `IR/`,
  `LLVM/`, or any production-semantic surface;
- any new third-party dependency, CI change, container change,
  framework change;
- investigation of reflogs, unreachable objects, `git fsck`
  archaeology, or any claim that the historical negative
  ("no rewrite ever occurred before `APPEND_ONLY_START_POINT`")
  is or is not true. The policy is prospective only;
- selecting between merge patterns A / B / C (see "Operator
  decision" below) — the ACT is authorized to execute only the
  pattern the operator has chosen. **The ACT MUST HALT
  (`HALT_OPERATOR_PATTERN_NOT_SELECTED`) if no pattern has been
  chosen before its RED phase begins.**

---

## Operator decision (must precede ACT execution)

Per `HALT-PUSH-DECISION-REQUIRED.md`, three legitimate append-only
patterns exist:

- **A.** `reconcile/main-history` is created at `origin/main`,
  then the local archive tip is merged in (no fast-forward).
  Push as new canonical `main` (FF or non-FF on the remote
  side).
- **B.** The opposite orientation: `reconcile/main-history`
  starts at the local archive tip, then the remote archive tip
  is merged in.
- **C.** Two-merge topology: first merge the local archive tip
  into a new branch off `origin/main`, then merge that branch
  back into `main`.

All three preserve both old lineages. The operator MUST choose
A, B, or C before this ACT enters its RED phase; the chosen
pattern becomes the operative scope of the merge commits.

This ACT is otherwise abstract about *which* pattern — only the
doctrine (append-only, no rewrite, both archive tips remain
ancestors) is fixed.

---

## Append-only policy at this boundary

This ACT operates from and codifies the following prospective
policy:

```text
APPEND_ONLY_START_POINT = <the commit named APPEND_ONLY_START_POINT
                            in evidence/llvm-intops01/HANDOFF-ADDENDUM.md>

POLICY:
All authoritative history at and after this boundary SHALL be
treated as immutable. No commit at or after this point may ever
be amended, rebased, filtered, replaced, squashed, or otherwise
rewritten.

OBSERVATION:
The currently available repository state shows no evidence of
rewriting at or after this boundary. `git replace -l` is empty.

SCOPE OF CLAIM:
The policy does not depend on proving the historical negative
claim that no rewrite ever occurred. Git reflogs are local, expire
by default (90 days reachable / 30 days unreachable), and cannot
serve as permanent proof of a negative historical fact.
```

This ACT's own commits are append-only descendants of
`APPEND_ONLY_START_POINT` and are themselves subject to the
same policy.

---

## Entry gate

Recorded at the start of this ACT's RED phase:

```sh
git branch --show-current    # expected: main
git status --short           # expected: empty
git rev-parse HEAD           # recorded as ENTRY_HEAD
git rev-parse --verify archive/local-main-before-reconcile^{commit}
git rev-parse --verify archive/origin-main-before-reconcile^{commit}
git replace -l               # expected: empty
```

Required state:

- on `main`;
- worktree clean;
- ENTRY_HEAD recorded;
- both archive refs resolve to expected tips;
- replacement-refs namespace empty.

If the divergence state has materially changed since this ACT
opened (e.g. someone ran a force push, replaced an object, or
moved an archive ref), this ACT MUST HALT
(`HALT_INPUT_INTEGRITY_DRIFT`) before any merge work.

---

## Principal RED

The real failing witness is the live divergence of `main` from
`origin/main` and the resulting inability to push:

```sh
# RED: ordinary push cannot proceed
git push origin main
# Expected: non-fast-forward rejection
# (non-fast-forward is itself the RED; it proves the divergence
#  state the ACT is bounded to resolve)
```

Additional corroborating witnesses:

```sh
# RED: divergence accounting
git rev-list --left-right --count HEAD...origin/main
# Expected: non-zero on both sides (currently 383 / 374)
```

These are pre-existing REDs; no new test fixture is required
because the witness is the live repository state itself.

---

## Implementation boundary

The minimum production change required is:

1. **One true merge commit** whose two parents are exactly the
   two archive tips (the local archive tip and the remote
   archive tip), in the orientation chosen by the operator
   (pattern A or B). If pattern C is chosen, two such merges.
   The merge commit MUST carry
   `ACT: ACT-POLYC-FACTORY-HISTORY-RECONCILE01`,
   `ACT-Phase: IMPL`, and a non-empty merge message describing
   the orientation chosen.
2. **One CLOSE commit** that updates `main`'s tip to the merge
   tip, with the full closure handoff in its body and the
   `ACT-Verdict: PASS` (or appropriate halt token) trailer.
3. **Prospective doctrine codification** in `AGENTS.md`,
   `docs/factory/DOCTRINE.md`, and (if needed)
   `docs/factory/LLM-WORKFLOW.md`, as additive sections that
   state the `APPEND_ONLY_START_POINT` policy verbatim. No
   existing F-rule is changed.

Deliberately **not** included:

- any rewrite of historical ACTs, HANDOFFs, or evidence;
- any cleanup of the `archive/*` refs (they remain in place
  permanently as historical anchors);
- any investigation of reflogs, unreachable objects, or
  pre-boundary rewriting;
- any change to `scripts/quality/factory-closure-status-check.sh`
  or `scripts/quality/llvm-closure-status-check.sh` (their
  bounded v1 managed universe is grandfathered per V2-13 / F14);
- any push itself (push is a separate decision and belongs to
  the operator; the ACT produces the pushable artifact, not the
  push).

---

## Acceptance criteria

Each AC is checkable by a single concrete command. Verdict
status is recorded in `evidence/factory-history-reconcile01/`.

### AC01 — ENTRY identity recorded

```sh
test -f evidence/factory-history-reconcile01/entry-identity.txt
```

Expected: file exists; contains `ENTRY_HEAD`, branch, status,
both archive SHA resolutions, and the empty `git replace -l`
observation.

### AC02 — Both archive tips remain ancestors of new HEAD

```sh
LOCAL=$(git rev-parse --verify archive/local-main-before-reconcile^{commit})
REMOTE=$(git rev-parse --verify archive/origin-main-before-reconcile^{commit})
git merge-base --is-ancestor "$LOCAL" HEAD \
  && git merge-base --is-ancestor "$REMOTE" HEAD
```

Expected: rc=0 from both. The actual SHA values used at
AC02-evaluation time are recorded in
`evidence/factory-history-reconcile01/gate-captures.txt`; the
ACT itself does not pin them.

### AC03 — No historical commit object is replaced

```sh
git rev-list archive/local-main-before-reconcile | wc -l
git rev-list archive/origin-main-before-reconcile | wc -l
git rev-list HEAD | wc -l
```

Expected: the third number is at least the sum of the first
two (plus the merge commits themselves). The exact delta is
recorded in the evidence file.

### AC04 — replacement-refs namespace remains empty

```sh
test -z "$(git replace -l)"
```

Expected: rc=0 (`git replace -l` produces no output).

### AC05 — Commit-message grammar

```sh
sh scripts/quality/factory-v2-commit-msg-check.sh HEAD~ HEAD
```

Expected: rc=0 (every ACT commit in the range has valid
trailers; CLOSE has exactly one `ACT-Verdict`; no duplicate
trailers).

### AC06 — Factory v2 range check

```sh
sh scripts/quality/factory-v2-range-check.sh ACT-POLYC-FACTORY-HISTORY-RECONCILE01 HEAD
```

Expected: `STATUS=PASS`, `COMMITS` ≥ 1, `VERDICT=<token>`.

### AC07 — Compiler conservation

```sh
git diff --name-only APPEND_ONLY_START_POINT HEAD -- src/ compiler/ runtime/
```

Expected: empty. (No production-semantic change is introduced
by the merge; both sides of the divergence preserved `src/`
as-is from the last common ancestor.)

### AC08 — `git diff --check` clean

```sh
git diff --check HEAD~..HEAD
```

Expected: rc=0.

### AC09 — Doctrine codification present

```sh
test -n "$(grep -c 'APPEND_ONLY_START_POINT' AGENTS.md)"
test -n "$(grep -c 'APPEND_ONLY_START_POINT' docs/factory/DOCTRINE.md)"
```

Expected: rc=0 from both. (The new additive doctrine section
exists in both canonical surfaces.)

### AC10 — Worktree clean at close

```sh
test -z "$(git status --porcelain)"
```

Expected: empty `git status --short` output.

---

## Conservation gates

The following gates from prior ACTs MUST remain PASS on the
merged tree (recorded in
`evidence/factory-history-reconcile01/gate-captures.txt`):

```sh
sh scripts/quality/gate-fast.sh
sh scripts/quality/factory-v2-test.sh
sh scripts/quality/factory-v2-range-check.sh ACT-POLYC-LLVM-INTOPS01 HEAD
sh scripts/quality/factory-v2-range-check.sh ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 HEAD
sh scripts/quality/llvm-intops01-test.sh
sh scripts/quality/llvm-memory01-test.sh
sh scripts/quality/llvm-float01-test.sh
sh scripts/quality/llvm-spike-test.sh
sh scripts/quality/llvm-spike-contract-check.sh
python3 scripts/quality/llvm-cap-table-verifier.py
sh scripts/quality/llvm-memory01-nc5-probe.sh load
sh scripts/quality/llvm-memory01-nc5-probe.sh store
```

Gates that are environmentally unavailable on the executing
host (e.g. `native-x86-float-cmp-parity01-test.sh` on a non-Rosetta
arm64 macOS host) are recorded as `N/A (host env)` rather than
`FAIL`. The closure HANDOFF must list each one explicitly with
its disposition.

If any conservation gate returns `FAIL` for a *content* reason
(not host environment), this ACT MUST HALT
(`HALT_CONSERVATION_GATE_REGRESSION`) and the failure must be
classified: either it is a pre-existing failure (residue, not
introduced by the merge) — in which case the verdict may still
be `PASS_WITH_NONBLOCKING_RESIDUE` — or it is merge-introduced,
in which case the merge is wrong and the ACT halts cleanly.

---

## HALT conditions

This ACT MUST halt (with the listed verdict trailer) if:

- `HALT_OPERATOR_PATTERN_NOT_SELECTED` — operator has not
  chosen merge pattern A, B, or C before the RED phase begins;
- `HALT_INPUT_INTEGRITY_DRIFT` — entry gate cannot be satisfied
  because archive refs have moved, replacement refs have
  appeared, or worktree is dirty;
- `HALT_CONSERVATION_GATE_REGRESSION` — a conservation gate
  fails for a content reason introduced by the merge;
- `HALT_SCOPE_EXPANSION_REQUIRED` — a real defect surfaces that
  cannot be resolved within this ACT's scope (per F15);
- `HALT_GIT_OPERATOR_ERROR` — the merge tool itself errors out
  in a way that cannot be resolved by re-running (e.g.
  conflicting archive refs, divergent archive tip identity).

A HALT is a successful execution outcome, not a failed PASS.

---

## Residue (pre-declared)

- **P0:** none (this ACT is the immediate blocker before
  `LLVM-BYTE-MEMORY01` resumes compiler work; once this ACT
  closes, no P0 remains in the project).
- **P1:** `archive/local-main-before-reconcile` and
  `archive/origin-main-before-reconcile` remain in place as
  permanent historical anchors. They are not removed by this
  ACT and should not be removed by future ACTs without their
  own bounded justification.
- **P1:** The INTOPS01 HALT CLOSE commit and its append-only
  addendum (the two-commit chain at the tip of the pre-merge
  local lineage, named as HALT CLOSE and ADDENDUM in
  `evidence/llvm-intops01/HANDOFF-ADDENDUM.md`) and the local
  archive tip are both reachable from the post-merge HEAD.
  This is by design: corrections are descendants, never
  replacements.
- **P2:** `scripts/quality/factory-v2-range-check.sh` currently
  has no HALT-exception (already recorded as residue in
  `ACT-POLYC-LLVM-INTOPS01` HANDOFF §Residue). The INTOPS01
  closure range-check succeeds because the legacy-oracle
  pattern reconciles it; no additional range-check teaching
  is required for this ACT.
- **P2:** The post-merge tree's `docs/ROADMAP.md` may diverge
  in tree-state from the local archive tip's `docs/ROADMAP.md`
  if the merge resolution picks `origin/main`'s version of the
  file. Either resolution is semantically equivalent for
  compiler work; this ACT does not adjudicate.

---

## Commit topology

Default Factory v2 topology (per
`docs/factory/ACT-TEMPLATE.md` v2 §Execution metadata, no numeric
cap):

```text
1. RED     -- capture entry-identity, gate captures, divergence
              evidence; record them under
              evidence/factory-history-reconcile01/
2. IMPL    -- execute the chosen merge pattern (A, B, or C);
              each merge commit is part of this ACT's range
              and carries ACT: ACT-POLYC-FACTORY-HISTORY-RECONCILE01
              with ACT-Phase: IMPL
3. EVIDENCE -- (optional) capture additional gate evidence, range
              check, doctrine diff
4. CLOSE   -- one final commit carrying the closure trailers and
              the full HANDOFF body; updates main to point at the
              merge tip; ACT-Phase: CLOSE, ACT-Verdict: PASS (or
              halt token)
```

If a fourth commit is unnecessary (e.g. RED captures everything
and the merge CLOSE itself is the single authoritative commit),
that is permitted — bounded by scope, contiguity, honest
classification, and individual meaning, not by an integer cap.

---

## Closure handoff

Follow the Factory v2 HANDOFF template at
`docs/factory/HANDOFF-TEMPLATE.md` (Factory v2 section).
The HANDOFF file lives at
`evidence/factory-history-reconcile01/HANDOFF.md` and is
descriptive only — it MUST NOT carry `VERDICT:`, `Status:`,
`FINAL_HEAD:`, `CLOSURE_HEAD:`, `DOCS_HEAD:`,
`IMPLEMENTATION_HEAD:`, or the literal token
`worktree=clean`. The verdict
authority is the `ACT-Verdict:` trailer on the CLOSE commit.

Reviewer procedure at closure:

```sh
sh scripts/quality/factory-v2-range-check.sh ACT-POLYC-FACTORY-HISTORY-RECONCILE01 HEAD
git show --stat HEAD
git log ENTRY..HEAD --format=full
git status --porcelain=v1
git diff --check ENTRY..HEAD
```
