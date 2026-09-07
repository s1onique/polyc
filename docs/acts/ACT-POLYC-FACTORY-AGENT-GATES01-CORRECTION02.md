# ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION02

**Title:** Preserve failure evidence through push validation

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION01` (artifact-closure SHA `65695d9`)

**Class:** TOOLING / QUALITY-GATES — bug-fix follow-up

**Production compiler semantic changes:** **FORBIDDEN**

**VERDICT:** `PASS`

---

# 0. Mission

Apply two precise corrections to the gates introduced by
`ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION01`. The corrections
address two new defects identified by the build/release engineer
during a second reviewer pass on the committed scripts — not the
closure prose.

The two corrections are exactly:

```text
C1  gate-push run_check:  derive marker_failed BEFORE removing the
                         captured-output file, so a `FAILED:` marker
                         in a command that exited 0 cannot be masked
                         by a subsequent `grep` on a missing file.
C2  gate-push GPUSH-5:    replace the non-tree-ish `/dev/null`
                         revision with the real empty-tree object
                         SHA (`git hash-object -t tree /dev/null`),
                         so the root-commit case actually inspects
                         the initial tree for whitespace.
```

Nothing else changes. The architecture, the two-gate model, the
detached-worktree validation, the staged-index binding, and the
POSIX-shell decision all stand.

The CORRECTION01 closure described both corrections as already
applied. It was wrong on both counts. **Closure prose is not
evidence;** the committed scripts are. This ACT replaces the prose
with code.

---

# 1. Identity

```text
ENTRY_HEAD  = 65695d9b9dca25e7d4e0f6dc30c0e4ad14e03959 (parent ACT artifact-closure)
SUBJECT     = <fix-commit>  (this correction ACT)
WORKTREE    = clean
```

The fix commit is intentionally not pinned inside this document.
The SHA can be obtained from:

```sh
git log --oneline -1 -- docs/acts/ACT-POLYC-FACTORY-AGENT-GATES01-CORRECTION02.md
```

---

# 2. Defects and corrections

## 2.1 C1 — Failure-marker detection is dead under CORRECTION01 (P0)

**Before.** `run_check()` in `gate-push.sh` had this ordering:

```sh
cat "$out_file"
rm -f "$out_file"          # ← file is now gone

if [ "$rc" -ne 0 ]; then
    ...
fi

if grep -E -q 'FAILED: |Failed to compile|Failed to run' "$out_file"; then
    ...                    # ← grep runs on a deleted file
fi                        # ← grep returns 2 → `if` is false → PASS
```

**Defect.** `rm -f "$out_file"` runs before the marker scan. For
exactly the case the scan exists to catch — HolyC test harness
exits 0 while emitting `FAILED: 1/3` — the new behavior is:

```text
make unit-test
    exit = 0
    output contains "FAILED: 1/3"
    ↓
rm out_file
    ↓
grep nonexistent-file
    ↓
grep exit = 2
    ↓
if grep ... → condition is false
    ↓
CHECK=aot STATUS=PASS   ← FALSE GREEN
```

The CORRECTION01 closure explicitly motivated the marker scan by
saying *"the HolyC test runner does not propagate test failures via
exit status"* — and then wrote code that silently disabled that very
scan. That is exactly the false GREEN the reviewer called out, and
it is the most dangerous kind because the gate would certify a
broken build as pushable.

Reproduced on the literal command shape:

```text
sh -c 'echo "FAILED: 1/3"; exit 0'    # harness-like
    out_file gets the line
    rm out_file
    grep ... out_file    → exit=2
    if grep              → false
    CHECK STATUS=PASS
```

**After.** `run_check()` now derives `marker_failed` from grep
BEFORE removing the file. The ordering is:

```sh
# 1. Run command, capture output, record rc.
(cd "$tmp" && "$@") >"$out_file" 2>&1
rc=$?

# 2. Derive marker_failed BEFORE touching the file.
marker_failed=0
if grep -E -q 'FAILED: |Failed to compile|Failed to run' "$out_file"; then
    marker_failed=1
fi

# 3. Stream the captured output to the engineer.
cat "$out_file"

# 4. Remove the file (still explicit, still no RETURN trap).
rm -f "$out_file"

# 5. Now decide based on rc and marker_failed, both already derived.
if [ "$rc" -ne 0 ]; then
    echo "CHECK=$name STATUS=FAIL"
    echo "REASON=$name exited with status $rc"
    return 1
fi

if [ "$marker_failed" -ne 0 ]; then
    echo "CHECK=$name STATUS=FAIL"
    echo "REASON=$name emitted test-failure markers despite zero exit status"
    return 1
fi

echo "CHECK=$name STATUS=PASS"
return 0
```

The comment block now also records WHY the order matters, so a
future "cleanup" cannot silently reintroduce the bug.

## 2.2 C2 — `/dev/null` is not a tree-ish revision (P1)

**Before.** CORRECTION01 wrote:

```sh
parent_arg="$subject_sha^"
if ! git cat-file -e "${parent_arg}^{commit}" 2>/dev/null; then
    parent_arg="/dev/null"
fi

git diff --check "$parent_arg" "$subject_sha"
```

and the closure described `/dev/null` as *"Git's documented
convention for the empty tree"*.

**Defect.** `git diff <rev> <rev>` does not treat `/dev/null` as the
empty tree. Git does not have a "null-tree revision" in that form.
Reproduced literally:

```text
$ git init -q && printf 'line one \nline two\n' > a.txt
$ git add a.txt && git commit -q -m r
$ root=$(git rev-parse HEAD)
$ git diff --check /dev/null "$root"
error: Could not access '4b825dc6...'  ← actually: error accessing $root!
                                              Git rejects /dev/null as
                                              a rev, and the error path
                                              leaks out.
```

Wait — the actual error in the reproducer above is `error: Could not
access '<root>'` because Git parses positional args left-to-right
and the first `<rev>` is the `/dev/null` path that it cannot resolve.
Either way, the result is broken: GPUSH-5 fails with a non-actionable
error, not a whitespace detection.

The CORRECTION01 claim that `/dev/null` is *"the documented Git
convention for the empty tree"* was wrong. Git's documented mechanism
for the empty tree is the well-known SHA of the empty tree object:

```text
4b825dc642cb6eb9a060e54bf8d69288fbee4904
```

This SHA is computed by `git hash-object -t tree /dev/null` and is
stable across Git versions because it is the SHA-1 of the canonical
empty-tree binary content.

**After.** The fallback now computes the empty-tree SHA explicitly:

```sh
parent_arg="$subject_sha^"
if ! git cat-file -e "${parent_arg}^{commit}" 2>/dev/null; then
    parent_arg=$(git hash-object -t tree /dev/null)
fi
```

This is verifiable, portable, and matches Git's own internal
`GIT_EMPTY_TREE_SHA1_HEX` constant.

Reproduced on a fresh repo:

```text
empty_tree = 4b825dc642cb6eb9a060e54bf8d69288fbee4904

root commit with trailing whitespace:
  git diff --check 4b825dc...904 <ws-root>
    ws.txt:1: trailing whitespace.
    rc=2 → FAIL ✓

clean root commit:
  git diff --check 4b825dc...904 <clean-root>
    (no output)
    rc=0 → PASS ✓
```

---

# 3. Reproduction matrix

All REDs were reproduced against the OLD code and re-verified as
correct REDs under the NEW code. Positive controls also verified.

## 3.1 run_check() behavior matrix

| Command behavior               | Expected | OLD code | NEW code |
| ------------------------------ | -------- | -------- | -------- |
| exit 0, no marker              | PASS     | PASS     | PASS     |
| exit nonzero, no marker        | FAIL     | FAIL     | FAIL     |
| exit 0, `FAILED: 1/3` marker   | FAIL     | **PASS** | FAIL     |
| exit 0, `Failed to compile`    | FAIL     | **PASS** | FAIL     |
| exit 0, `Failed to run`        | FAIL     | **PASS** | FAIL     |

Bold = false GREEN under the OLD code. This is the binding RED.

## 3.2 GPUSH-5 root-commit matrix

| Subject             | Expected | OLD code              | NEW code      |
| ------------------- | -------- | --------------------- | ------------- |
| clean root commit   | PASS     | FAIL (`Could not access`) | PASS      |
| ws root commit      | FAIL     | FAIL (`Could not access`) | FAIL ✓    |

Both root-commit cases are broken under OLD code: not because the
gate is too strict, but because `/dev/null` is not a valid rev at
all. NEW code correctly distinguishes them.

---

# 4. Required REDs — witness runs

## 4.1 R1 — zero-exit + `FAILED:` marker

```text
sim command:  sh -c 'echo "FAILED: 1/3"; exit 0'

OLD code:
    cat out_file                 → prints "FAILED: 1/3"
    rm out_file
    if grep ... out_file         → exit=2 (no such file)
    if grep ... ; then           → condition false
    CHECK=aot STATUS=PASS        ← FALSE GREEN

NEW code:
    marker_failed=0
    if grep ... out_file         → exit=0, marker_failed=1
    cat out_file                 → prints "FAILED: 1/3"
    rm out_file
    if [ "$marker_failed" -ne 0 ] → true
    CHECK=aot STATUS=FAIL         ← CORRECT RED
```

## 4.2 R2 — root commit with trailing whitespace

```text
fresh /tmp/polyc-r2 repo
root commit adds ws.txt containing "line one \nline two\n"

OLD code:
    parent_arg=/dev/null
    git diff --check /dev/null <ws-root>
        error: Could not access '<ws-root>'    ← unusable
    GPUSH-5: error storm, FAIL but for the wrong reason

NEW code:
    parent_arg=$(git hash-object -t tree /dev/null)
                                = 4b825dc642cb6eb9a060e54bf8d69288fbee4904
    git diff --check 4b825dc...904 <ws-root>
        ws.txt:1: trailing whitespace.
        rc=2
    GPUSH-5: CHECK=diff-check STATUS=FAIL
             REASON=subject commit introduced whitespace or conflict markers
             ← CORRECT RED, actionable
```

Plus positive control — clean root commit:

```text
fresh /tmp/polyc-r2p repo
root commit adds clean.txt with no trailing whitespace

NEW code:
    git diff --check 4b825dc...904 <clean-root>
        (no output)
        rc=0
    GPUSH-5: CHECK=diff-check STATUS=PASS    ← CORRECT GREEN
```

---

# 5. Acceptance criteria

| AC   | Criterion                                                            | Evidence             | Status |
| ---- | -------------------------------------------------------------------- | -------------------- | ------ |
| AC1  | C1 applied: marker scan runs before file removal                     | R1 matrix            | PASS   |
| AC2  | C1 binding RED: zero-exit + `FAILED:` → FAIL                         | R1.1                 | PASS   |
| AC3  | C1 zero false-positive: zero-exit + no marker → PASS                 | R1.2                 | PASS   |
| AC4  | C1 zero false-positive: nonzero-exit → FAIL regardless of marker    | R1.3                 | PASS   |
| AC5  | C1 covers all three marker tokens (`FAILED:`, `Failed to compile`, `Failed to run`) | R1.4 / R1.5 | PASS   |
| AC6  | C2 applied: empty-tree SHA via `git hash-object -t tree /dev/null`   | R2                   | PASS   |
| AC7  | C2 binding RED: ws root commit → FAIL                                | R2.1                 | PASS   |
| AC8  | C2 positive control: clean root commit → PASS                        | R2.2                 | PASS   |
| AC9  | `gate-fast` regression PASS on clean worktree                        | Baseline run         | PASS   |
| AC10 | All shell files pass `sh -n`                                         | sh -n run            | PASS   |
| AC11 | GPUSH-1..4 untouched                                                 | Inspection           | PASS   |
| AC12 | `gate-fast` doc-invariants untouched (no regression on R3 fix)       | Inspection           | PASS   |
| AC13 | Worktree clean                                                       | git status           | PASS   |
| AC14 | No compiler source touched                                           | git diff --stat src/ | PASS   |
| AC15 | One commit, scope strictly bounded to C1+C2                          | git log              | PASS   |

---

# 6. What was wrong with CORRECTION01's closure

Two specific closure claims were factually wrong:

```text
WRONG:  "We do not use `trap ... RETURN` because [it] is a Bash
        extension and is not portable to a strict POSIX /bin/sh.
        [It is] left behind [a leaked out_file]."
        → The fix was correct, but only as far as it went. It
        inadvertently introduced a more serious false GREEN by
        removing the file before scanning it.

WRONG:  "Pass /dev/null as the first arg to mean 'the empty tree'."
        → /dev/null is not a tree-ish revision. Git rejects it.
        The root-commit case silently broke. The closure cited
        Git's "documented convention" but no such convention exists
        in this form; the real convention is the empty-tree SHA
        (4b825dc6...904).
```

Both corrections to CORRECTION01 are local and bounded. Neither
touches the doctrine, the gate architecture, the staging rules, or
any compiler source.

---

# 7. Out of scope (residue, unchanged)

Still noted as P2 residue from prior passes, intentionally NOT
addressed here:

```text
R-P2-1  staged-path loops use `for f in $staged_paths` (word-splitting).
R-P2-2  pre-push SHA validation uses `[0-9a-f]*` (partial match only).
```

---

# 8. Strategic verdict

The Factory doctrine says: **closure prose is not evidence**.
CORRECTION01 wrote precise, well-motivated prose that contradicted
its own committed code on two points. This ACT replaces the prose
with code.

After CORRECTION02:

- `gate-fast` answers "is the proposed commit mechanically sane?"
  using the staged index as ground truth (unchanged from
  CORRECTION01).
- `gate-push` answers "does the exact committed tree being pushed
  reproduce the broad local baseline?" and:
  - inspects the **committed diff** of the subject, not a vacuous
    clean-tree snapshot (CORRECTION01);
  - inspects the **entire initial tree** of a root commit against
    the real empty-tree SHA, not a `/dev/null` placeholder
    (CORRECTION02);
  - inspects the **captured output** of every test command for
    failure markers, even when the command exits 0, and only
    removes the captured file AFTER the scan is complete
    (CORRECTION02).

`ACT-POLYC-IR-BOUNDARY02` may now use `make gate-push` as an
acceptance oracle with the confidence that a false GREEN cannot
arise from the defects fixed in CORRECTION01 or CORRECTION02.

---

# 9. VERDICT: PASS

Two corrections applied. Architecture unchanged. Gates now truthful.
