# `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03`

**Title:** Discharge the DUPLICATE `C4` / DUPLICATE `ACT-Phase: CLOSE`
created in `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01` by a premature
intermediate close, WITHOUT rewriting any committed history, and
re-establish the parent's EXACTLY-FIVE-COMMIT phase path.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** GOVERNANCE / GIT-METADATA / CORRECTION

**Predecessor:** `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01`,
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01`,
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02`

**Factory-Version:** 2

**Production semantic changes:** **FORBIDDEN**. The parent's
production delta is mechanically GREEN and must not be re-mutated.

**Re-mutation of committed evidence directories:** **FORBIDDEN**
(F14).

---

## 0. Mission

This ACT establishes the single mechanical claim:

```text
the_parent_ACT_id_carries_TWO_close_commits = YES
the_parent_ACT_path_is_EXACTLY_five_commits   = NO
a_single_validated_five_commit_path_exists  = YES
```

and only that.

---

## 1. Why this ACT exists

The parent's ACT contract states:

> The PASS path is exactly five distinct linear commits:
> `C0 RED -> C1 EVIDENCE -> C2 IMPL -> C3 EVIDENCE -> C4 CLOSE`

and

> Create the unique fifth CLOSE commit with exact Factory-v2
> trailers.

The parent ACT's execution produced SIX commits carrying the parent's
ACT identity, with the phase label `C4` on THREE of them:

| order | commit | subject phase label | `ACT-Phase` trailer |
|---|---|---|---|
| 1 (oldest) | `0be7c87e` | C0 | RED |
| 2 | `3645738a` | C1 | *(none)* |
| 3 | `aa243059` | C2 | *(none)* |
| 4 | `1e0dd97d` | C3 | *(none)* |
| 5 | `c57a4e8b` | **C4** | **CLOSE** |
| 6 | `ec36285c` | **C4** | **EVIDENCE** |
| 7 (newest) | `2b061fe3` | **C4** | **CLOSE** |

THE CAUSE. The intermediate close `c57a4e8b` was created BEFORE the
external terminality receipt existed, which was premature: the
parent's contract says the receipt may only be produced AFTER the
CLOSE, and the receipt's ten checks must observe the terminal state.
The terminality receipt then had to be recorded in a further commit,
and the terminal close had to follow it. Both further commits
re-used the `C4` label, so the path carries a DUPLICATE C4 and TWO
`ACT-Phase: CLOSE` commits under the parent's ACT id.

THE DEFECT WAS CAUGHT BY EXECUTION, NOT BY REVIEW. The external
read-only terminality probe's `CHECK_01_FIVE_PHASE_SEQUENCE` reported

```text
ordered=[C0 C1 C2 C3 C4 C4 C4 ] close_count=2
```

and `PROBE_RESULT=FAIL`. That is the probe working as designed: it
refused to certify a path that does not match the contract. The
probe's failure was the RED for this ACT.

THE HISTORY IS APPEND-ONLY. The extra commits cannot be removed by
amend, rebase, filter-branch, filter-repo, `git replace`,
reset+recommit, squash merge or force push; every one of those
mechanisms is forbidden and the local pre-push hook enforces the
graph properties of the destination ref.

---

## 2. Scope

### allowed

- `docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03.md`
- `evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03/**`
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION03.md`
- `docs/factory/act-handoff-map.tsv` (one appended row)
- `docs/ROADMAP.md` (the current-truth section for this correction)
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-MIGRATION01.md`
  (the parent handoff's disclosure of the duplicate)

### forbidden

- Any modification of ANY production file: `src/**`, `tools/**`.
- Any modification of the canonical gates, scripts or tests.
- Any modification of ANY committed evidence directory.
- Any amendment, rebase, replay or history rewrite of ANY commit.

---

## 3. The correction

### 3.1 The disclosure

The parent's handoff, the ROADMAP and this ACT's evidence MUST state
plainly that the parent's committed path carries SIX commits under its
ACT id, that three of them carry the `C4` label, that TWO of them
carry `ACT-Phase: CLOSE`, and that this is a consequence of a
premature intermediate close. The duplicate is **not** concealed and
**not** relabelled as correct.

### 3.2 The valid five-commit path

THIS ACT establishes a NEW, mechanically valid five-commit path that
carries the parent's evidence and the parent's acceptance ledger:

```text
R0 RED      the measured trailer defect, read from the git objects
R1 EVIDENCE the five-phase path inventory and the duplicate inventory
R2 IMPL     the parent's acceptance ledger discharge (AC48..AC50)
R3 EVIDENCE the external terminality receipt, re-bound to R3
R4 CLOSE    the single terminal close, with ACT-Supersedes
```

Every one of those commits carries a complete git-parseable trailer
block, so the canonical range validator's rule 2 and rule 3 are both
satisfied for this path, and rule 4 holds because there is exactly
ONE `ACT-Phase: CLOSE` in it.

### 3.3 The terminality receipt is re-executed

Because the parent's terminal CLOSE was premature, the receipt that
was bound to it certified a path that the ACT's contract does not
allow. This ACT therefore executes the read-only terminality probe
again, AFTER its own terminal close, and binds the new receipt to the
new terminal HEAD and TREE. The receipt still lives OUTSIDE the
repository and is never backdated.

### 3.4 What this ACT does NOT claim

- It does NOT claim the parent's original committed path was valid.
- It does NOT claim the parent's earlier receipt certified a valid
  path.
- It does NOT change any compiler behaviour.
- It does NOT discharge the parent's duplicate; it DISCLOSES it.

---

## 4. Exit gate

This ACT closes when, MEASURED BY EXECUTION:

1. the canonical commit-message validator reports `MODE=ACT` and
   `STATUS=PASS` for every commit of this ACT;
2. the canonical range validator reports `STATUS=PASS` for this
   ACT's own five-commit range;
3. the parent's committed path inventory is recorded, by measurement,
   in this ACT's evidence, including the duplicate and the fact that
   it is irreparable;
4. the external read-only terminality probe is re-executed after this
   ACT's CLOSE and reports `PROBE_RESULT=PASS`;
5. the parent's production delta is byte-identical, i.e. this ACT
   changed NO production file;
6. no committed evidence file was modified.
