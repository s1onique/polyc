# ACT-POLYC-FACTORY-HISTORICAL-EXCEPTIONS-REGISTRY01

**Title:** Establish canonical append-only historical-exceptions registry; restore F14 immutability of `correction04/historical-cardinality-exceptions.txt`; codify truth hierarchy

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-NO-SHA-OF-SELF01-CORRECTION04` (PASS_WITH_HYGIENE_RESIDUE) — also surfaces defects in `ACT-POLYC-BOOTSTRAP01-CORRECTION01` (PASS_WITH_HYGIENE_RESIDUE) discovered post-CLOSE by reviewer audit.

**Class:** DOCUMENTATION / FACTORY-CONTRACT / GOVERNANCE

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**VERDICT (target):** `PASS_WITH_HYGIENE_RESIDUE`

---

# 0. Mission

Three small, structural repairs to the Factory governance substrate, all
purely documentation. No source code, no IR, no language semantics.

## Defect landscape (consolidated by reviewer audit)

| ID    | Severity | Defect                                                                                                 | Source       |
|-------|----------|--------------------------------------------------------------------------------------------------------|--------------|
| D-1   | P0       | `evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction04/historical-cardinality-exceptions.txt` was mutated by `ACT-POLYC-BOOTSTRAP01-CORRECTION01` to append EXCEPTIONs 4 and 5, violating strict F14. | BOOTSTRAP01-CORRECTION01 C2 |
| D-2   | P1       | The phrase "`git notes` annotation reclassified it as EVIDENCE" is mechanically false — git notes are supplemental metadata, not commit-body modifications. | BOOTSTRAP01-CORRECTION01 EXCEPTION 5 wording |
| D-3   | P1       | The architecture of the exceptions file under a closed correction ACT's evidence tree makes F14 mutable-by-default. The "exceptions registry" pattern must be relocated. | Both        |

## Resolutions

| Defect | Resolution                                                                                |
|--------|-------------------------------------------------------------------------------------------|
| D-1    | Forward commit restores `correction04/historical-cardinality-exceptions.txt` to its pre-BOOTSTRAP content (textually identical); new canonical registry at `docs/factory/HISTORICAL-CARDINALITY-EXCEPTIONS.tsv` holds all 5 EXCEPTIONs. |
| D-2    | Re-author EXCEPTION 5 wording to state "annotation added; commit body unchanged per F14". Update DOCTRINE.md §24 to forbid "reclassified" phrasing for git notes. |
| D-3    | Establish canonical TSV registry outside any `evidence/ACT-*/` tree. Strengthen DOCTRINE.md §24 to enumerate this as the only forward-compatible location. |

## Strict non-goals

- Do NOT rewrite commit history.
- Do NOT amend any closed ACT's commit messages.
- Do NOT retroactively reclassify commits as EVIDENCE via any mechanism
  other than a new bounded correction ACT.
- Do NOT open another BOOTSTRAP correction.
- Do NOT alter the production source tree, IR, or LLVM/ABI behavior.

---

# 1. Truth hierarchy (codified)

The Factory recognizes three separate channels for commit/ACT metadata,
each with distinct authority and distinct mutability semantics:

```text
COMMIT TRAILERS       = mechanical truth (immutable; F-GIT-IMMUTABILITY)
GIT NOTES             = annotation only (do not modify commit object)
EXCEPTION REGISTRY    = governance disposition (append-only)
```

A verifier that queries commit trailers reads **mechanical truth**.
A verifier that reads git notes reads **annotation**, never truth.
A verifier that consults the exception registry reads **governance
disposition**, which may downgrade a mechanical-truth violation to
non-blocking but cannot repair the underlying commit body.

This trichotomy is binding going forward; DOCTRINE.md §24 codifies it.

---

# 2. Allowed edits (exhaustive list)

| File | Allowed mutation | Disallowed |
|------|------------------|-----------|
| `docs/factory/HISTORICAL-CARDINALITY-EXCEPTIONS.tsv` | CREATE; then APPEND rows for EXCEPTION 1..5 | rewrite existing rows |
| `docs/factory/DOCTRINE.md` | APPEND §24.1 "Truth hierarchy" block; APPEND §24.2 "Exception registry location"; APPEND §24.3 "git notes do not reclassify" | rewrite existing §22 / §23 / §24 prose beyond additive insertions |
| `evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction04/historical-cardinality-exceptions.txt` | FORWARD COMMIT with bit-identical restoration of pre-BOOTSTRAP content (EXCEPTIONs 1..3 only); cannot append per strict F14 | any mutation that changes the EXCEPTION 1..3 content; any append |
| `evidence/ACT-POLYC-FACTORY-HISTORICAL-EXCEPTIONS-REGISTRY01/c{1,2,3,4}/` | CREATE new evidence files (README, RED, IMPL, EVIDENCE, CLOSE) | n/a (new tree) |
| `docs/ROADMAP.md` | APPEND a small ACT-status block under P5 or a new section | rewrite B0 outcome block |

Nothing else.

---

# 3. Phases

## C1 RED — open this ACT

- Author this ACT document.
- Establish RED: confirm by mechanical query that
  `correction04/historical-cardinality-exceptions.txt` currently
  contains EXCEPTIONs 1..5 and was last modified by the BOOTSTRAP
  correction's C2 IMPL (`9e6f6ab`).
- Capture RED evidence in `c1/`.

## C2 IMPL — registry migration + forward restoration

- CREATE `docs/factory/HISTORICAL-CARDINALITY-EXCEPTIONS.tsv` containing
  EXCEPTIONs 1..5.
- Forward-commit a bit-identical restoration of
  `correction04/historical-cardinality-exceptions.txt` to its
  pre-BOOTSTRAP-CORRECTION01 state. The legacy file's content
  becomes exactly what it was at commit `4a78bdf^`.
- Capture IMPL evidence in `c2/`.

Note: this restoration does NOT delete EXCEPTIONs 4..5 from the world —
those rows exist in the new canonical registry. The legacy file is
restored to its pre-BOOTSTRAP state because that state was the
F14-immutable state, and the new registry is the authoritative
forward location.

## C3 EVIDENCE — gate checks

- Verify: canonical registry exists with 5 EXCEPTION rows.
- Verify: legacy file content is bit-identical to its pre-BOOTSTRAP
  state (compute SHA of the legacy file's pre-BOOTSTRAP version
  via `git show 4a78bdf^:evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction04/historical-cardinality-exceptions.txt`,
  then `git hash-object` the post-restoration working-copy file;
  SHAs must match).
- Verify: `git diff --check 4a78bdf..HEAD` returns clean (excluding
  the pre-existing DEFECT-3 captured-evidence residue line).
- Verify: `--all-match --oneline` cardinality queries return the same
  counts as before (2 / 2).
- Verify: EXCEPTION 5's wording in the new registry explicitly
  distinguishes "annotation added" from "commit body reclassified".
- Capture EVIDENCE in `c3/`.

## C4 CLOSE — verdict and HANDOFF

- Single CLOSE commit.
- `ACT-Verdict: PASS_WITH_HYGIENE_RESIDUE`.
- HANDOFF.md summarizing the registry relocation and the bit-identical
  restoration of the legacy file.

---

# 4. Acceptance gates

| ID  | Gate                                                          | Required state |
|-----|---------------------------------------------------------------|----------------|
| AG1 | Canonical TSV registry exists at `docs/factory/HISTORICAL-CARDINALITY-EXCEPTIONS.tsv` | yes       |
| AG2 | TSV has exactly 5 EXCEPTION rows                              | yes            |
| AG3 | Legacy file bit-identical to its `4a78bdf^` SHA               | yes            |
| AG4 | DOCTRINE.md §24 strengthened with truth-hierarchy block       | yes            |
| AG5 | EXCEPTION 5 wording in new registry says "annotation" not "reclassified" | yes |
| AG6 | Cardinality-1 query still returns 2/2 (no further violations) | yes            |
| AG7 | `git diff --check 4a78bdf..HEAD` clean (modulo DEFECT-3)      | yes            |
| AG8 | Worktree clean                                                | yes            |
| AG9 | No amendment of any historical commit                         | yes            |
| AG10| No new commits carry `ACT-Phase: CLOSE` for any historical ACT id beyond the one authoritative CLOSE each | yes |

---

# 5. Residue forecast

P0: NONE
P1: (forecasted) further exception migrations if a 6th exception is
    discovered; the registry is now the single forward-compatible
    location.
P2: (forecasted) tool that mechanically reads the TSV registry and
    cross-checks against `git log --all-match --grep`; would close
    the loop on AG6.

---

# 6. Forward recommendation (out of ACT scope)

`ACT-POLYC-BOOTSTRAP02` may open immediately after this ACT closes
to begin B1 work. The B0 substrate is GREEN_WITH_CLOSURE_CORRECTION;
no further BOOTSTRAP corrections are required.

End of ACT.
