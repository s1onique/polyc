# ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION01

**Title:** Fix git-log query semantics in DOCTRINE.md §22 (require `--all-match` + cardinality check)

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-NO-SHA-OF-SELF01` (PASS)

**Class:** DOCUMENTATION / FACTORY-CONTRACT

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**VERDICT:** `PASS`

---

# 0. Mission

The reviewer audit of the just-closed
ACT-POLYC-FACTORY-NO-SHA-OF-SELF01 identified that the
canonical "git-log queryable identity" recipe in DOCTRINE.md
§22 is INCORRECT and would mislead future consumers.

The bug:

```sh
# As written in DOCTRINE.md §22 (WRONG):
git log --grep='^ACT: ACT-POLYC-FOO01$' \
        --grep='^ACT-Phase: CLOSE$' \
        --pretty=format:'%H'
```

Git's `--grep` semantics: with multiple `--grep` flags,
Git selects commits matching **any** of the patterns (OR),
not all (AND). The flag that switches to AND is `--all-match`.

The naive recipe returns commits that match either pattern:

  - commits carrying `ACT: ACT-POLYC-FOO01` (correct)
  - AND commits carrying `ACT-Phase: CLOSE` (any ACT's CLOSE)

For a non-existent ACT id, the recipe still returns 50+
matches (the entire CLOSE history of the repo). This is
not just imprecise; it actively defeats the "query Git for
the closure SHA" pattern.

The fix:

```sh
git log --all-match \
        --grep='^ACT: ACT-POLYC-FOO01$' \
        --grep='^ACT-Phase: CLOSE$' \
        --pretty=format:'%H'
```

Additionally, where the Factory contract expects exactly one
CLOSE per ACT (the canonical Cardinality-1 invariant for
closure identity), consumers SHOULD verify cardinality
explicitly rather than silently taking `-1`.

This ACT also sharpens the Git object-model wording in
§22 (commit ID identifies the full commit object, not
merely the tree; this is documentation precision, not a
blocker).

---

# 1. Scope

In scope:

- `docs/factory/DOCTRINE.md` §22: replace the naive
  `git log` recipe with the `--all-match` version; add
  cardinality guidance; sharpen the Git object-model
  wording.
- `docs/acts/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01.md`:
  identical fixes for the recipe shown there (same bug).
- `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction06/closure-summary-replacement.md`:
  identical fix for the recipe shown there (same bug).
- `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction06/no-sha-of-self-repair-record.txt`:
  identical fix.

Out of scope:

- Production code. (No production code is touched.)
- Earlier ACT docs that may show the naive recipe (the
  recipe was newly codified in this doctrine; only
  newly-written instances are fixed).
- CORRECTION05 closure-summary.txt (F14 immutable).

---

# 2. Acceptance criteria

AC01. `docs/factory/DOCTRINE.md` §22 contains the
      `--all-match` recipe (not the naive OR-semantics
      version).

AC02. §22 explicitly states that Git `--grep` is OR by
      default and that `--all-match` switches to AND.

AC03. §22 contains the cardinality-1 guidance: "if the
      Factory contract expects exactly one CLOSE per ACT,
      verify cardinality explicitly rather than silently
      taking `-1`."

AC04. §22 contains the sharpened Git object-model wording:
      "a commit ID identifies the full commit object
      (parents + tree + identities + timestamps + message),
      not merely the tree."

AC05. The newly-written artifacts under
      `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction06/`
      and the original ACT doc
      `docs/acts/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01.md`
      contain the corrected recipe (not the naive one).

AC06. `git diff --check` on the closing commit is clean
      (no new hygiene findings).

AC07. Working tree is clean after the closing commit.

AC08. Append-only invariant: still PASS.

AC09. F1–F15 still intact; F-GIT-IDENTITY (now v2 with
      `--all-match` and cardinality) is honored.

---

# 3. HALT conditions

HALT_SCOPE_EXPANSION_REQUIRED — if a needed change is
discovered outside this scope (e.g. a broader recipe audit
across all historical ACTs).

---

# 4. Identity

```text
branch           = main
working tree     = clean (verified after each commit)
predecessor      = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01 (PASS)
ACT id           = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION01
phase            = CLOSE
verdict          = PASS
```

The closing commit's SHA is NOT pinned inside this document.
Query it with:

```sh
git log --all-match -1 \
        --grep='^ACT: ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION01$' \
        --grep='^ACT-Phase: CLOSE$' \
        --pretty=format:'%H'
```

This recipe now correctly returns exactly one SHA (or zero,
if the closing commit doesn't exist yet — a useful negative
test).
