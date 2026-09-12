# ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06

**Title:** Repair SHA-of-self violation in CORRECTION05 closure-summary; correct hygiene arithmetic

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-NO-SHA-OF-SELF01` (PASS — codifies the doctrine)
                `ACT-POLYC-TOOLING-RUNTIME01-CORRECTION05` (PASS_WITH_HYGIENE_RESIDUE — contains the violation)

**Class:** DOCUMENTATION / EVIDENCE-INTEGRITY

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**VERDICT:** `PASS_WITH_HYGIENE_RESIDUE`

---

# 0. Mission

The reviewer audit of ACT-POLYC-TOOLING-RUNTIME01-CORRECTION05
identified two non-blocking evidence issues that this ACT
repairs:

1. **SHA-of-self claim in CORRECTION05 closure-summary.**
   Line 4 of
   `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction05/closure-summary.txt`
   reads:

   ```
   IDENTITY: branch=main HEAD=31ad4615d12d (this commit; ...)
   ```

   `31ad4615d12d` IS one of the commits that wrote this file.
   The line `HEAD=31ad4615d12d` inside that commit is a
   SHA-of-self claim — exactly what DOCTRINE.md §22 forbids.

   The repair: create a new file under
   `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction06/`
   with the corrected identity pattern. The CORRECTION05 file
   itself is F14-protected historical evidence; it is NOT
   rewritten (per the strict F14 reading now codified in
   DOCTRINE.md §22).

2. **Hygiene arithmetic was off-by-one.**
   CORRECTION05 closure-summary stated "4 F14 c1/c4 findings"
   but there are actually 5 baseline F14 findings (4 in c1/c4
   evidence + 1 in src/holyc-lib/tooling.HC EOF). The
   repair: restate the rollup as three counts
   (baseline F14, P2 residue, newly introduced), per
   DOCTRINE.md §22 hygiene arithmetic convention.

This ACT is bounded: it does not touch any source code, does
not touch the CORRECTION05 closure-summary file itself, and
creates only new evidence under `correction06/`.

---

# 1. Scope

In scope:

- New directory
  `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction06/`
  containing:
  - `closure-summary-replacement.md` — corrected identity
    pattern; restated hygiene rollup
  - `hygiene-rollup.txt` — three-count classification
  - `f14-statement.txt` — explicit F14 doctrine statement
  - `no-sha-of-self-repair-record.txt` — what was replaced
    and why

Out of scope:

- Touching
  `evidence/ACT-POLYC-TOOLING-RUNTIME01/correction05/closure-summary.txt`
  (F14 immutable).
- Touching any earlier correction directory.
- Production code changes.

---

# 2. Acceptance criteria

AC01. `correction06/closure-summary-replacement.md` exists and
      contains NO `<LABEL>=<40-hex>` lines where the label is
      self-referential.

AC02. `correction06/closure-summary-replacement.md` IDENTI
      TY section uses the stable pattern:
      ```
      IDENTITY:
        branch = main
        working tree = clean (verified after each commit)
        predecessor = ACT-POLYC-TOOLING-RUNTIME01-CORRECTION05
                      (PASS_WITH_HYGIENE_RESIDUE)
        ACT id     = ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06
        phase      = CLOSE
        verdict    = PASS_WITH_HYGIENE_RESIDUE
      ```

AC03. `correction06/hygiene-rollup.txt` reports the ACT range
      hygiene as three counts:
      - baseline F14 findings (existed before the ACT range)
      - P2 residue findings (verbatim captured artifacts)
      - newly introduced findings (must equal zero)

AC04. The CORRECTION05 closure-summary file is NOT modified
      (F14 honored).

AC05. `git diff --check` on the closing commit is clean.

AC06. Working tree is clean after the closing commit.

AC07. Append-only invariant: still PASS.

AC08. F1–F15 still intact; F-GIT-IDENTITY (new) is honored.

---

# 3. HALT conditions

HALT_SCOPE_EXPANSION_REQUIRED — if any needed change is
discovered outside this scope.

---

# 4. Identity

```text
branch           = main
working tree     = clean (verified after each commit)
predecessor      = ACT-POLYC-TOOLING-RUNTIME01-CORRECTION05
                   (PASS_WITH_HYGIENE_RESIDUE)
                 = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01
                   (PASS — codifies the F-GIT-IDENTITY doctrine)
ACT id           = ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06
phase            = CLOSE
verdict          = PASS_WITH_HYGIENE_RESIDUE
```

The closing commit's SHA is NOT pinned inside this document.
Query it with:

```sh
git log --grep='^ACT: ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06$' \
        --grep='^ACT-Phase: CLOSE$' --pretty=format:'%H'
```

This is exactly the doctrine this ACT enforces.

