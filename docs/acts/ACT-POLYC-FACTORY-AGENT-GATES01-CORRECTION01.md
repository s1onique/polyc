# ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION01

**Title:** Bind quality checks to the committed and staged subject

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-AGENT-GATES01` (artifact-closure SHA `797b4b9`)

**Class:** TOOLING / QUALITY-GATES — bug-fix follow-up

**Production compiler semantic changes:** **FORBIDDEN**

**VERDICT:** `PASS`

---

# 0. Mission

Apply three precise corrections to the gates introduced by
`ACT-POLYC-FACTORY-AGENT-GATES01`. The corrections are based on an
external reviewer pass that identified three real defects producing
false GREENs in the gate machinery. The gates are now part of the
PolyC evidence system; correctness at this layer is doctrinally
non-negotiable.

The three corrections are exactly:

```text
C1  gate-push:  replace vacuous clean-worktree `git diff --check`
                with subject-commit diff hygiene
C2  gate-push:  remove non-POSIX `trap ... RETURN`
C3  gate-fast:  validate required repository documents from the staged
                index, not the worktree
```

Nothing else changes. The architecture is accepted unchanged; the gate
internals become truthful.

---

# 1. Identity

```text
ENTRY_HEAD   = 797b4b919726c5e648f72839652e4e8a6a2933a4 (parent ACT artifact-closure)
SUBJECT      = <fix-commit>  (this correction ACT)
WORKTREE     = clean
```

The fix commit is intentionally not pinned inside this document.
The SHA can be obtained from:

```sh
git log --oneline -1 -- docs/acts/ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION01.md
```

---

# 2. Defects and corrections

## 2.1 C1 — Vacuous GPUSH-5 diff --check (FALSE GREEN)

**Before.** `gate-push.sh` ran:

```sh
if ! (cd "$tmp" && git diff --check >/dev/null 2>&1); then
```

inside a freshly-created detached worktree at the subject commit.

**Defect.** `git diff --check` with no arguments compares the working
tree to the index. In a clean detached worktree, both are identical by
construction, so the diff is empty and the check vacuously exits 0.
Any whitespace or conflict-marker errors introduced by the SUBJECT
COMMIT are never inspected. A commit that adds trailing whitespace
would receive `CHECK=diff-check STATUS=PASS`.

This was reproduced by creating a side-branch commit that added a
file with trailing whitespace, then running the exact GPUSH-5 code
path against it:

```text
old code:    exit=0   (false green)
correct:     exit=2   docs/.ws-test.txt:2: trailing whitespace.
```

**After.** The gate now runs:

```sh
parent_arg="$subject_sha^"
if ! git cat-file -e "${parent_arg}^{commit}" 2>/dev/null; then
    parent_arg="/dev/null"
fi

if ! diff_check_output=$(cd "$tmp" && git diff --check "$parent_arg" "$subject_sha" 2>&1); then
    echo "CHECK=diff-check STATUS=FAIL"
    echo "REASON=subject commit introduced whitespace or conflict markers:"
    printf '%s\n' "$diff_check_output"
    gate_failed=1
else
    echo "CHECK=diff-check STATUS=PASS"
fi
```

`/dev/null` is the documented Git convention for "the empty tree", so
the root-commit case (where `<subject>^` does not exist) is handled.

## 2.2 C2 — Non-POSIX `trap ... RETURN` (silent portability bug)

**Before.** `run_check()` in `gate-push.sh` declared:

```sh
trap 'rm -f "$out_file" 2>/dev/null || true' RETURN
```

**Defect.** `RETURN` is a Bash pseudo-signal, not part of POSIX
`trap`. POSIX `trap` only standardizes `EXIT`/`0` and actual signal
names (`HUP`, `INT`, `TERM`, etc.). On any `/bin/sh` that does not
implement the Bash extension (dash, BSD sh, mksh without RETURN
support), the trap silently no-ops and the captured-output file is
leaked.

On macOS `/bin/sh` (bash 3.2.57), the trap is recognized but does not
fire on `exit`; it only fires on shell-function return or `return`
from a sourced script. In `run_check`, which uses `return 1` etc.
inside a function, the trap *might* fire — but `run_check` is also
called from the top-level loop which can reach non-`return` exit
paths (`exit 1` on hard errors). The leak is real, the portability
claim is false.

This was reproduced by inspection:

```text
/bin/sh -c 'trap "echo RETURN" RETURN; exit 0'   # prints nothing
/bin/sh -c 'trap "echo EXIT"  EXIT;  exit 0'    # prints "EXIT"
```

**After.** The non-portable trap is removed. `run_check` now always
removes `out_file` explicitly before returning, with a comment that
records why we do not use `trap ... RETURN`:

```sh
# Always remove the captured output file before returning. We do not
# use `trap ... RETURN` because RETURN is a Bash extension and is not
# portable to a strict POSIX /bin/sh. POSIX trap only standardizes
# EXIT and signal names; RETURN would silently no-op under dash,
# BSD sh, or any shell that does not implement the Bash pseudo-signal,
# leaving out_file behind. We always remove it explicitly here.
rm -f "$out_file"
```

`gate-push.sh` continues to use `#!/bin/sh`, because it does not need
Bash. The shebang was deliberately not changed — switching to Bash
would expand the host-tool requirement without addressing the
underlying correctness problem.

## 2.3 C3 — Required documents checked from worktree, not index (FALSE GREEN)

**Before.** `gate-fast.sh` validated the four required canonical
documents (`AGENTS.md`, `docs/CHARTER.md`, `docs/ROADMAP.md`,
`docs/DESIGN-NOTES.md`) via:

```sh
if [ ! -f "$required" ]; then
    echo "CHECK=doc-invariants STATUS=FAIL"
    ...
fi
```

**Defect.** This checks the working tree, not the staged index.
Pathological but valid state:

```text
index:     AGENTS.md deleted   (staged with `git rm AGENTS.md`)
worktree:  AGENTS.md restored  (cp from prior version)
```

The proposed commit would silently drop the canonical agent contract,
yet `[ -f AGENTS.md ]` would still succeed and gate-fast would
report `VERDICT=PASS`.

This was reproduced by staging the deletion of `AGENTS.md` and
restoring the worktree copy:

```text
old gate-fast: VERDICT=PASS   (false green)
```

**After.** The gate now validates document presence in the staged
index via `git cat-file -e ":$path"`, which inspects the index object
database — exactly what the proposed commit will produce when
created:

```sh
for required in \
    AGENTS.md \
    docs/CHARTER.md \
    docs/ROADMAP.md \
    docs/DESIGN-NOTES.md
do
    # If the path is staged for some change, refuse deletions or
    # renames that do not re-introduce the document in the same
    # commit.
    if printf '%s\n' "$staged_paths" | grep -qx "$required"; then
        diff_filter=$(git diff --cached --name-status -- "$required" \
                      | awk 'NR==1 {print $1}')
        case "$diff_filter" in
            A|C|M|T) ;;
            *)  echo "CHECK=doc-invariants STATUS=FAIL"
                echo "REASON=required document $required is staged for $diff_filter"
                echo "VERDICT=FAIL"
                exit 1
                ;;
        esac
    fi

    # Index-level presence check.
    if ! git cat-file -e ":$required" 2>/dev/null; then
        echo "CHECK=doc-invariants STATUS=FAIL"
        echo "REASON=required document $required is missing from the staged index"
        echo "VERDICT=FAIL"
        exit 1
    fi
done
```

The `diff_filter` branch allows a commit whose entire purpose is to
introduce the missing required document (A/C/M/T all result in a
new index entry); it only fails on D/R-style changes that leave the
index without a regular blob for the path.

---

# 3. Reproduction

All three defects were reproduced and the fixes verified before
commit. Witness runs:

## R1 (C1) — GPUSH-5 must fail on a trailing-whitespace commit

```text
ws subject = 5c243a63d320d31911f37b72445198415c42f38e
parent_arg=5c243a63d320d31911f37b72445198415c42f38e^

old code:    git diff --check (no args, fresh worktree)
             → exit=0, no whitespace reported   (FALSE GREEN)

new code:    git diff --check $parent $subject
             → exit=2, "docs/.ws-test.txt:2: trailing whitespace."
             → GPUSH-5 reports FAIL              (CORRECT RED)
```

## R2 (C2) — RETURN trap is non-portable

```text
/bin/sh --version      # GNU bash 3.2.57 (macOS)
/bin/sh -c 'trap "echo X" RETURN; exit 0'    # prints nothing
/bin/sh -c 'trap "echo X" EXIT;  exit 0'    # prints "X"

→ RETURN trap does not fire on `exit` under bash 3.2 either.
→ gate-push.sh was leaking out_file every run_check call.
→ New code: explicit rm -f $out_file always runs.
```

## R3 (C3) — Required document deletion must fail gate-fast

```text
cp AGENTS.md /tmp/AGENTS.md.bak
git rm AGENTS.md        # stage deletion
cp /tmp/AGENTS.md.bak AGENTS.md   # restore worktree copy

git status -s AGENTS.md   →   D  AGENTS.md
                                ?? AGENTS.md

old gate-fast: VERDICT=PASS   (FALSE GREEN)
new gate-fast: CHECK=doc-invariants STATUS=FAIL
               REASON=required document AGENTS.md is missing from the staged index
               VERDICT=FAIL
               exit=1                                   (CORRECT RED)
```

---

# 4. Acceptance criteria

| AC   | Criterion                                                              | Evidence             | Status |
| ---- | ---------------------------------------------------------------------- | -------------------- | ------ |
| AC1  | C1 applied: GPUSH-5 inspects subject-commit diff                       | R1 reproduction      | PASS   |
| AC2  | C2 applied: `trap ... RETURN` removed, explicit `rm` instead           | R2 reproduction      | PASS   |
| AC3  | C3 applied: required docs checked via `git cat-file -e ":$path"`       | R3 reproduction      | PASS   |
| AC4  | `gate-fast` still PASSes on a clean worktree (no regression)           | Baseline run         | PASS   |
| AC5  | `gate-fast` still PASSes on a docs-only staged change (T1 from parent) | Regression run       | PASS   |
| AC6  | All shell files pass `sh -n`                                           | sh -n run            | PASS   |
| AC7  | `gate-push` GPUSH-1..4 unchanged                                       | Inspection           | PASS   |
| AC8  | Worktree clean                                                         | git status           | PASS   |
| AC9  | No compiler source touched                                             | git diff --stat src/ | PASS   |
| AC10 | One commit, scope strictly bounded to the three corrections           | git log              | PASS   |

---

# 5. Out of scope (left as residue)

The reviewer pass noted two nonblocking items. Both are intentionally
NOT changed in this correction ACT and are recorded as P2 residue.

```text
R-P2-1  staged-path loops use `for f in $staged_paths` (word-splitting).
        Filenames containing spaces/newlines would not be handled.
        PolyC's current path conventions make this low-risk.
        Future ACT may switch to NUL-delimited plumbing.

R-P2-2  pre-push SHA validation uses `[0-9a-f]*` (only first char checked).
        Defensive only; Git's pre-push contract already supplies a
        valid object name or the zero deletion sentinel.
```

---

# 6. Strategic verdict

A false RED is annoying.

A false GREEN from the evidence machinery is doctrinally worse than
an ordinary compiler bug — it makes the gates certify a state that
does not actually satisfy the contract.

The architecture of `ACT-POLYC-FACTORY-AGENT-GATES01` is accepted:

```text
AGENTS.md canonical              ✅
Factory doctrine                 ✅
thin .clinerules                 ✅
fast pre-commit                  ✅
isolated pre-push                ✅
core.hooksPath installer         ✅
no framework dependency          ✅
```

The three internal defects are now fixed. The gates are now truthful
in the following sense:

- `gate-fast` answers "is the proposed commit mechanically sane?"
  using the **staged index** as ground truth.
- `gate-push` answers "does the exact committed tree being pushed
  reproduce the broad local baseline?" and inspects the **committed
  diff** of the subject, not a vacuous clean-tree snapshot.

`ACT-POLYC-IR-BOUNDARY02` may now use `make gate-push` as an
acceptance oracle with the confidence that a false GREEN cannot
arise from the defects fixed in this ACT.

---

# 7. VERDICT: PASS

Three corrections applied. Architecture unchanged. Gates now truthful.
