# ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION03

**Title:** Fix `wc -l` cardinality check (--pretty=format:'%H' produces no trailing newline)

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION02` (PASS_WITH_HYGIENE_RESIDUE)

**Class:** DOCUMENTATION / FACTORY-CONTRACT / GOVERNANCE

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**VERDICT:** `PASS_WITH_HYGIENE_RESIDUE`

---

# 0. Mission

The reviewer-corrected cardinality check recipe in
DOCTRINE.md §22 (added by CORRECTION01) has a SECOND bug:

```sh
matches=$(git log --all-match \
                  --grep='^ACT: ACT-POLYC-FOO01-CORRECTION03$' \
                  --grep='^ACT-Phase: CLOSE$' \
                  --pretty=format:'%H' | wc -l)
```

`--pretty=format:'%H'` emits the SHA WITHOUT a trailing
newline. `wc -l` counts newlines, not records. So a query
that returns exactly 1 match produces output that has
ZERO newlines, and `wc -l` returns 0.

Empirical reproduction (captured 2026-09-12):

  $ git log --all-match \
            --grep='^ACT: ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION02$' \
            --grep='^ACT-Phase: CLOSE$' \
            --pretty=format:'%H' | xxd | head -3
  00000000: 6538 3361 6534 3532 3037 3233 3239 3037  e83ae45207232907
  00000010: 6633 3637 3434 3337 3237 3235 3932 3761  f36744372725927a
  00000020: 3530 3035 3061 3863                      50050a8c
  (no 0x0a trailing)

  $ ... | wc -l
  0   <- WRONG: should be 1

The recipe's cardinality check therefore fires FALSE_HALT
when the ACT exists and has exactly one CLOSE commit. Any
downstream tool relying on this recipe would erroneously
report "0 matches" and exit 1.

The fix:

  Option A (use %n):
    matches=$(git log --all-match ... --pretty=format:'%H%n' | grep -c .)

  Option B (use --oneline):
    matches=$(git log --all-match ... --oneline | wc -l)

  Option C (use grep -c on --pretty=tformat: which adds newlines):
    matches=$(git log --all-match ... --pretty=tformat:'%H' | grep -c .)

Option B is the simplest and least error-prone (--oneline
guarantees one-line-per-commit with newlines); Option A is
the most explicit.

---

# 1. Scope

In scope:

- DOCTRINE.md §22: replace the cardinality check recipe
  with a newline-safe version.
- authoritative-recipe.txt (in correction02): update the
  recipe to use newline-safe cardinality counting.

Out of scope:

- Re-mutating any file in correction02/ or earlier
  evidence directories (F14; the cardinal bug is documented
  but not "fixed" by re-mutating older evidence files).
- Production code.
- Reopening the tooling-runtime chain.

---

# 2. Acceptance criteria

AC01. DOCTRINE.md §22 cardinality recipe uses a newline-
      safe counting primitive (e.g. `%H%n` + `grep -c .`,
      OR `--oneline` + `wc -l`).

AC02. authoritative-recipe.txt (in correction02/) is NOT
      modified (F14). Instead, this ACT creates a new
      authoritative-recipe-v2.txt under correction03/ that
      supersedes it.

AC03. cardinality-witness.txt (in correction02/) is NOT
      modified (F14). Instead, this ACT creates a new
      cardinality-witness-v2.txt under correction03/ that
      documents the additional bug found.

AC04. c05-doctrine-classification.txt and
      f14-violation-record.txt (in correction02/) are NOT
      modified (F14). Their content remains valid; only the
      recipe they reference has been further refined.

AC05. The new evidence under correction03/ documents:
      - The second bug (wc -l + --pretty=format:'%H')
      - Empirical reproduction
      - Three fix options with trade-offs
      - Recommendation: use --oneline (Option B)

AC06. `git diff --check` on the closing commit is clean.

AC07. Working tree is clean after the closing commit.

AC08. Append-only invariant: still PASS.

AC09. F1-F15 still intact; F-GIT-IDENTITY v2 still honored;
      strict F14 still honored by THIS correction (we do
      not re-mutate correction02/ files).

---

# 3. HALT conditions

HALT_SCOPE_EXPANSION_REQUIRED — if a needed change is
discovered outside this scope (e.g. we discover yet
another bug in the recipe that requires broader fix).

---

# 4. Identity

```text
branch           = main
working tree     = clean (verified after each commit)
predecessor      = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION02
                   (PASS_WITH_HYGIENE_RESIDUE)
ACT id           = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION03
phase            = CLOSE
verdict          = PASS_WITH_HYGIENE_RESIDUE
```

The closing commit's SHA is NOT pinned inside this document.
Query it with:

```sh
git log --all-match \
        --grep='^ACT: ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION03$' \
        --grep='^ACT-Phase: CLOSE$' \
        --oneline | wc -l
test "$matches" -eq 1 && echo OK
```
