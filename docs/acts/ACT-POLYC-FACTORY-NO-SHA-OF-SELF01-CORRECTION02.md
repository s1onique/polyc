# ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION02

**Title:** Restore strict F14 geometry; do not mutate CORRECTION06 evidence from this correction chain

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION01` (PASS_WITH_HYGIENE_RESIDUE)

**Class:** DOCUMENTATION / FACTORY-CONTRACT / GOVERNANCE

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**VERDICT:** `PASS_WITH_HYGIENE_RESIDUE`

---

# 0. Mission

The reviewer audit of CORRECTION01 identified a Factory-
contract inconsistency: CORRECTION01 modified two files in
the CORRECTION06 evidence directory (closure-summary-
replacement.md and no-sha-of-self-repair-record.txt) by
updating the naive `git log --grep=...` recipe to the
correct `--all-match` form.

The new DOCTRINE.md §22 explicitly forbids this:

```text
historical erroneous evidence = immutable
new correction packet         = authoritative successor

[corrections] MUST NOT modify any file under ACT-N/.
```

But CORRECTION01 did exactly that to ACT-POLYC-TOOLING-
RUNTIME01-CORRECTION06's evidence directory. The Git
semantics fix is correct, but the correction geometry is
not F14-clean.

The repair is bounded:

1. Do NOT revert the CORRECTION01 commit (F-GIT-IDENTITY
   + F-GIT-IMMUTABILITY forbid rewriting history).
2. Do NOT re-mutate the CORRECTION06 evidence files; that
   would compound the F14 violation.
3. Create a new `correction02/` evidence packet that:
   - Documents the F14 violation that occurred
   - States the authoritative successor recipe
   - Carries the cardinality witness
   - Classifies the older C05 "ADDENDUM is acceptable"
     text as historical superseded doctrine (without
     editing the C05 file)
4. Update DOCTRINE.md §22 with an explicit "common
   mistake to avoid" callout so future corrections don't
   repeat the same error.

This ACT does NOT touch any file in
`evidence/ACT-POLYC-TOOLING-RUNTIME01/correction06/`.
That directory remains in its CORRECTION01-mutated state;
the F14 violation is documented but not "fixed" by
re-mutation.

---

# 1. Scope

In scope:

- New `docs/acts/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION02.md`
- New `evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction02/`
  containing:
  - `README.md` — index
  - `f14-violation-record.txt` — what CORRECTION01 did wrong
  - `authoritative-recipe.txt` — the canonical recipe
    (correct --all-match + cardinality check)
  - `cardinality-witness.txt` — empirical proof of the
    semantic difference between naive and --all-match
  - `c05-doctrine-classification.txt` — explicit statement
    that the C05 "ADDENDUM is acceptable" text is historical
    superseded doctrine (no C05 file modification)
- DOCTRINE.md §22: add explicit "common mistake to avoid"
  callout naming this exact failure mode (corrections
  mutating older evidence directories to "fix" things
  they just discovered).

Out of scope:

- Reverting the CORRECTION01 commit (F-GIT-IMMUTABILITY).
- Re-mutating the CORRECTION06 evidence directory
  (would compound the F14 violation).
- Re-mutating the CORRECTION05 evidence directory
  (F14; the "ADDENDUM is acceptable" text is historical
  evidence and is classified as superseded without
  modification).
- Production code.
- Tooling-runtime chain (reopening forbidden).

---

# 2. Acceptance criteria

AC01. `evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction02/`
      exists with README.md, f14-violation-record.txt,
      authoritative-recipe.txt, cardinality-witness.txt,
      c05-doctrine-classification.txt.

AC02. NO file under
      `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction06/`
      is modified by this ACT.

AC03. NO file under
      `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction05/`
      is modified by this ACT.

AC04. DOCTRINE.md §22 contains a new "Common mistake to
      avoid" callout that names the exact failure mode
      (corrections re-mutating older evidence files to
      fix things they discovered) and points future
      corrections at the successor-packet pattern.

AC05. `cardinality-witness.txt` contains empirical proof:
      naive query for a non-existent ACT returns >0 matches
      (the bug); --all-match returns 0 matches (the fix).

AC06. `c05-doctrine-classification.txt` explicitly states
      that the C05 "ADDENDUM is acceptable" text is
      historical superseded doctrine, NOT current
      guidance, without modifying the C05 file.

AC07. `git diff --check` on the closing commit is clean
      (no new hygiene findings).

AC08. Working tree is clean after the closing commit.

AC09. Append-only invariant: still PASS.

AC10. F1-F15 still intact; F-GIT-IDENTITY (v2) and the
      strict F14 reading are honored by THIS correction
      (we do not repeat the same mistake).

---

# 3. HALT conditions

HALT_SCOPE_EXPANSION_REQUIRED — if a needed change is
discovered outside this scope (e.g. we discover another
evidence directory was similarly mutated and needs
analogous treatment).

---

# 4. Identity

```text
branch           = main
working tree     = clean (verified after each commit)
predecessor      = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION01
                   (PASS_WITH_HYGIENE_RESIDUE — contains the F14
                   geometry violation that this ACT documents
                   and stops repeating)
ACT id           = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION02
phase            = CLOSE
verdict          = PASS_WITH_HYGIENE_RESIDUE
```

The closing commit's SHA is NOT pinned inside this document.
Query it with:

```sh
git log --all-match -1 \
        --grep='^ACT: ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION02$' \
        --grep='^ACT-Phase: CLOSE$' \
        --pretty=format:'%H'
matches=$(... | wc -l)
test "$matches" -eq 1 && echo OK
```
