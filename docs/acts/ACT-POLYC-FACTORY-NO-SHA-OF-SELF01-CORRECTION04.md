# ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION04

**Title:** Sharpen `tformat:` guidance; codify Cardinality-1-CLOSE as a forward invariant (with historical exceptions)

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION03` (PASS_WITH_HYGIENE_RESIDUE)

**Class:** DOCUMENTATION / FACTORY-CONTRACT / GOVERNANCE

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**VERDICT:** `PASS_WITH_HYGIENE_RESIDUE`

---

# 0. Mission

Two small but real improvements to the canonical recipe in
DOCTRINE.md §22, plus one formal codification of a forward
invariant.

## Two wording fixes

### Fix 1: "head -1 may not terminate correctly" is wrong

The current §22 text says:

> The trailing `%n` is critical; without it, `head -1` may
> not terminate correctly depending on the consumer.

`head -1` does NOT need a terminal newline to terminate; EOF
terminates the record just fine. The real reason to prefer a
terminated record is **record-oriented composability**, not
`head` correctness. Git explicitly documents that `tformat:`
exists to ensure the final entry is terminated.

### Fix 2: prefer `tformat:` over `%H%n`

The current recipe uses `--pretty=format:'%H%n' | head -1`.
That works, but the more canonical form is
`--pretty=tformat:'%H'`, which uses Git's native terminator
semantics directly. `--pretty=tformat:` is documented to
append a terminator to every record, including the last.

Equivalent forms:

```sh
# Form A (current, valid):
git log --all-match -1 ... --pretty=format:'%H%n' | head -1

# Form B (preferred, uses native terminator):
git log --all-match -1 ... --pretty=tformat:'%H'
```

Form B is shorter and more semantically clear. Both work.

## One forward invariant

The reviewer identified that **the Cardinality-1 CLOSE
invariant has been violated historically**:

  $ git log --all-match \
            --grep='^ACT: ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06$' \
            --grep='^ACT-Phase: CLOSE$' \
            --oneline | wc -l
  2

CORRECTION06 has 2 commits carrying `ACT-Phase: CLOSE`:
  - f031bc7 (the main commit)
  - 23bc92a (the hygiene follow-up)

The same pattern exists for:
  - CORRECTION05 (2 CLOSE commits)
  - NO-SHA-OF-SELF01 (5 CLOSE commits, including 3 corrections)

This pattern is the result of how this session's corrections
were structured: each ACT had a main CLOSE commit, and some
had a hygiene follow-up that also carried the CLOSE trailer.
Going forward, this should not happen.

The invariant for future ACTs:

  Cardinality-1-CLOSE: For any ACT id, exactly ONE commit
  may carry both `ACT: <id>` AND `ACT-Phase: CLOSE`.

Hygiene follow-ups should carry `ACT-Phase: EVIDENCE` (or
similar non-CLOSE phase), or — if the hygiene fix is large
enough to warrant a separate correction ACT — open a new
bounded correction ACT with its own CLOSE.

This ACT formally codifies the invariant as a forward rule
and records the historical exceptions as classified residue.

## Why this is bounded and F14-clean

- DOCTRINE.md §22 is a canonical-contract file; mutating it
  is allowed.
- A new evidence packet under correction04/ carries the
  classified historical exceptions list.
- No earlier correction directory (correction02/, correction03/,
  correction05/, correction06/) is mutated.
- No production code is touched.

---

# 1. Scope

In scope:

- DOCTRINE.md §22: fix the "head -1 may not terminate
  correctly" wording; add `tformat:` as the preferred form.
- DOCTRINE.md §22: add explicit "Cardinality-1 CLOSE"
  forward invariant with reference to
  `evidence/.../correction04/historical-cardinality-exceptions.txt`.

Out of scope:

- Mutating any earlier correction directory (F14 strict
  reading; the historical duplicates remain in history).
- Production code.
- Opening a separate FACTORY-CLOSE-CARDINALITY01 ACT (the
  reviewer noted this as a future Factory cleanup; it's
  non-blocking).
- Reopening the tooling-runtime chain.

---

# 2. Acceptance criteria

AC01. DOCTRINE.md §22 no longer contains the claim
      "head -1 may not terminate correctly".

AC02. DOCTRINE.md §22 explicitly recommends
      `--pretty=tformat:` for SHA extraction.

AC03. DOCTRINE.md §22 codifies Cardinality-1 CLOSE as a
      forward invariant.

AC04. evidence/.../correction04/ contains a historical
      exceptions list enumerating every ACT that currently
      violates Cardinality-1 (with SHA citations as
      observations about immutable subjects, not self-claims).

AC05. NO earlier correction directory is modified.

AC06. `git diff --check` on the closing commit is clean.

AC07. Working tree is clean after the closing commit.

AC08. Append-only invariant: still PASS.

AC09. F1-F15 still intact.

---

# 3. HALT conditions

HALT_SCOPE_EXPANSION_REQUIRED — if a needed change is
discovered outside this scope.

---

# 4. Identity

```text
branch           = main
working tree     = clean (verified after each commit)
predecessor      = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION03
                   (PASS_WITH_HYGIENE_RESIDUE)
ACT id           = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION04
phase            = CLOSE
verdict          = PASS_WITH_HYGIENE_RESIDUE
```

The closing commit's SHA is NOT pinned inside this document.
Query it with:

```sh
git log --all-match \
        --grep='^ACT: ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION04$' \
        --grep='^ACT-Phase: CLOSE$' \
        --oneline | wc -l
test "$matches" -eq 1 && echo OK
```
