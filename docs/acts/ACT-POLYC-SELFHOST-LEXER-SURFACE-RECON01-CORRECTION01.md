# ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01

**Title:** Bounded governance correction — repair three mechanical closure defects in ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01 (AC40 patch hygiene, "C2 == C3 ranking" overstatement, broad-corpus conservation language); preserve engineering result; bind LEXER02 to the same frozen subject

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01` CLOSE commit `7adb9e8` (closed with `ACT-Verdict: PASS`, but with three mechanically checkable closure defects per review audit)

**Class:** GOVERNANCE / EVIDENCE-CORRECTION / CLOSURE-DEFECT-REPAIR

**Production compiler semantic changes:** **FORBIDDEN** — no `src/**`, no `tools/bootstrap/**`, no `docs/factory/SELF-HOST-COMPONENTS.tsv` mutation in this correction ACT; the recon ACT's result is preserved verbatim and the corrections live in a forward-only `CORRECTION01/` evidence tree

**IR/ABI repair authorization:** NONE

**LLVM authorization:** NONE

**Language-change authorization:** NONE

**No-Python authorization:** NONE — `POLYC_TOOLS_TRACKED_PYTHON = 12` remains the canonical pre-state; this ACT must not introduce or remove Python

**VERDICT (target):** `PASS_WITH_CORRECTION_RESIDUE`

**ACT-Supersedes:** `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01`

**ACT-Corrected-Verdict:** `PASS` (the engineering result is preserved and verified; the three mechanical closure defects are repaired)


---

# 0. Mission

The review audit of the `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01`
closure (commit `7adb9e8`) identified three closure defects:

1. **DEFECT-1 (P0 governance):** `AC40` (`ACT-range diff-check clean`)
   is false on the closed range. The committed ACT evidence contains
   three "new blank line at EOF" diagnostics on files the recon ACT
   itself created:

   ```text
   evidence/.../c1/prior-negative-score-red.txt:37
     new blank line at EOF
   evidence/.../c1/selfhost-surface-baseline.txt:79
     new blank line at EOF
   evidence/.../c4/final-region-map.txt:35
     new blank line at EOF
   ```

   `c3/patch-hygiene.txt`, `c4/patch-hygiene.txt`, and
   `c4/acceptance-matrix.txt` all claim `PATCH_HYGIENE = PASS` and
   `AC40 = PASS`, which is mechanically false. The C4 verdict
   `PASS` is therefore a false-green closure.

2. **DEFECT-2 (P1 overstatement):** The claim
   "`C2 ranking == C3 ranking`" overstates what was actually
   reproduced. C2 enumerated 12 region candidates; C3 enumerated
   17 (with 5 additional candidates R-M..R-Q produced by an
   exhaustive Pass B application). The only literal claim that
   survives is **rank #1 invariance under expanded enumeration**.
   The full-ranking text in `c4/final-ranking.txt` is additionally
   **non-monotonic**: it lists `R-Q +201` at rank 8 and
   `R-H +200` at rank 9, although `R-Q` numerically outranks
   `R-H`.

3. **DEFECT-3 (P2 conservation language):** `c3/current-selfhost-conservation.txt`
   and `c4/final-conservation.txt` describe the broad four-stage
   corpus as "PASS 175/175 + 6/6", but C3 did not execute a fresh
   four-stage corpus run. The Apple Silicon host environment hit
   the inherited `libtos/strings.HC` ARM-assembly residue
   (carried from LEXER01; see `c1/predecessor-freeze.txt`), so
   C3 reused the predecessor's `175/175 + 6/6` evidence based on
   a zero semantic-delta inference. The correct phrasing is
   `LAST_KNOWN_GOOD` plus `ATTRIBUTABLE_MUTATION = NONE`, not
   "fresh rerun PASS".

The substantive recon result — `R-F = scalar_literal_scanner`
(countNumberLen + lexNumeric + lexCharConst) as rank #1 with
`FINAL_SCORE = +627`, ROBUST margin 342, `E1..E14 = PASS`, ABI
bounded, oracle feasible, production seam possible — is real
and correct. The correction ACT preserves that engineering
result verbatim and repairs only the three closure defects.

This correction ACT records, repairs, and re-classifies the
defects in a bounded pass. No new lexical semantics are
introduced; no new candidate slice is migrated; no Python is
touched; the closed predecessor evidence tree
(`evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c1/...`,
`c2/...`, `c3/...`, `c4/...`) is preserved immutable per F14.


---

# 1. Authorized surface

This correction ACT authorizes ONLY the following mutations:

1. `docs/acts/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01.md` — new ACT contract document (this file).

2. `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/` — new evidence directory containing:
   - `c1/` — defect summary (this RED).
   - `c2/` — corrected claim ledger (per-defect forward-fix files).
   - `c3/` — independent re-derivation evidence.
   - `c4/` — closure packet.
   - `HANDOFF.md` — human-readable closure summary.

3. `docs/ROADMAP.md` — append a CORRECTION01 status block (only).

No production semantic mutation is authorized. No compiler
source, parser/AST/IR/backend, runtime, llvm, or formal
directory is touched. No new registry row. No Python mutation.
No bootstrap component created.

---

# 2. Phases

## C1 RED (DEFECT RECORD)

Capture the failing evidence for the three closure defects:

- DEFECT-1: `git diff --check a386810^..HEAD` output, file:line
  triple for each of the three "new blank line at EOF"
  diagnostics. Verified empirically against the closed
  predecessor commits.
- DEFECT-2: `c2/region-membership.tsv` and
  `c3/fresh-region-inventory.tsv` row counts (12 vs 17), plus
  `c4/final-ranking.txt` lines 8–9 showing the non-monotonic
  ordering.
- DEFECT-3: `c3/current-selfhost-conservation.txt` text
  showing the overstated "broad corpus ... fresh rerun PASS"
  phrasing.

`evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c1/defect-summary.txt`
captures all three.

## C2 IMPL (FORWARD-FIX WITHOUT MUTATING CLOSED EVIDENCE)

Per F14, the closed predecessor evidence tree is immutable.
The forward-fix lives in this correction ACT's evidence
directory and is expressed as a "corrected claim ledger":

- DEFECT-1 forward-fix: `c2/ac40-patch-hygiene-corrected.txt`
  records the exact trailing blank-line corrections as
  forward-fix data. The three closed files remain immutable;
  the corrected content is reproduced alongside with the
  trailing blank lines removed. The `corrected = original
  with trailing blank line removed` transformation is
  recorded in `c2/ac40-transform.tsv`.

- DEFECT-2 forward-fix: `c2/winner-invariance.tsv` records
  the precise, defensible claim that replaces
  "C2 == C3 ranking":

  ```text
  C2_WINNER_REPRODUCED_IN_C3     = YES
  C3_SEARCH_SPACE_SUPERSET_OF_C2= YES (12 -> 17 candidates)
  WINNER_INVARIANT_UNDER_EXTENSION = YES (R-F +627 in both)
  WINNER_MARGIN                 = 342 (ROBUST)
  RANKING_MONOTONIC_IN_C4_LIST  = NO (R-Q 201 > R-H 200 swapped)
  RANKING_MONOTONIC_IN_REPAIRED = YES (per c2/ranking-repaired.txt)
  ```

  `c2/ranking-repaired.txt` reproduces the corrected
  monotonic ranking.

- DEFECT-3 forward-fix: `c2/conservation-language-repaired.txt`
  records the corrected broad-corpus conservation phrasing:

  ```text
  BROAD_CORPUS_CURRENT_EXECUTION =
    ENVIRONMENTALLY_UNAVAILABLE (Apple Silicon libtos ARM asm)

  BROAD_CORPUS_LAST_KNOWN_GOOD =
    PASS 175/175 BYTE_IDENTICAL + 6/6 BOTH_FAIL across stage0..3
    (per ACT-POLYC-SELFHOST-LEXER01-CORRECTION01 c2/corpus-4-stages.txt)

  ATTRIBUTABLE_MUTATION =
    NONE (this ACT; recon ACT; correction ACT)

  CONSERVATION_INFERENCE =
    PASS_BY_ZERO_SEMANTIC_DELTA
  ```


## C3 EVIDENCE (INDEPENDENT RE-DERIVATION)

Re-derive the corrected claims from independent inputs:

- Independent re-count of `c2/region-membership.tsv` rows
  (12 candidates) and `c3/fresh-region-inventory.tsv` rows
  (17 candidates).
- Independent re-sort of all 17 eligible regions by
  `FINAL_SCORE` descending; verify `R-F +627` rank 1 and
  `R-Q +201` rank 7 / `R-H +200` rank 8.
- Re-emit the ACT-range `git diff --check` against the
  immutable closed commits to confirm DEFECT-1 is real.
- Re-emit the corrected ranking and conservation phrasing.
- Re-run gate-fast, Dafny, no-Python (must remain 12),
  conservation hash for identifier and operator.

`c3/independent-re-derivation.txt` is the consolidated
evidence.

## C4 CLOSE (CORRECTION VERDICT)

Commit the closure packet. The ACT-Phase is `CLOSE` and the
ACT-Verdict is `PASS_WITH_CORRECTION_RESIDUE` only if:

```text
DEFECT_1_FORWARD_FIX_PRESENT   = YES
DEFECT_2_FORWARD_FIX_PRESENT   = YES
DEFECT_3_FORWARD_FIX_PRESENT   = YES
RANKING_MONOTONIC              = YES
WINNER_INVARIANT_UNDER_EXT     = YES
CONSERVATION_LANGUAGE_REPAIRED = YES
CLOSED_PREDECESSOR_EVIDENCE_MUTATED = NO (F14 honored)
PRODUCTION_SEMANTIC_DELTA      = NONE
LLVM_CHANGED                   = NO
REGISTRY_ROW_ADDED             = NO
NEW_BOOTSTRAP_COMPONENT        = NO
PYTHON_DELTA                   = NONE (still 12)
GATE_FAST                      = PASS
DAFNY                          = PASS (17/17)
FACTORY_GATES                  = PASS
DIFF_CHECK_ACT_RANGE           = PASS
```

If any of the above is `NO`, the ACT halts with the
appropriate HALT_* token. The expected residue is the
**two-level archive**:

```text
  Level 1 (immutable historical evidence):
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c1/...
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c2/...
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c3/...
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c4/...
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/HANDOFF.md

  Level 2 (this correction's forward-only evidence):
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c1/...
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c2/...
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c3/...
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c4/...
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/HANDOFF.md
```


---

# 3. Halts

## HALT_PREDECESSOR_EVIDENCE_ALREADY_MUTATED

If inspection reveals that the closed predecessor evidence
tree (`evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c1|2|3|4/...`)
has been modified since commit `7adb9e8`, this ACT halts.
F14 forbids forward mutations of closed evidence; the
correction must live in `CORRECTION01/`, not in the
predecessor tree.

## HALT_SCOPE_EXPANSION_REQUIRED

If closing the three defects requires semantic changes to
`src/**`, parser/AST/IR/backend, runtime, llvm, formal,
tools/bootstrap, or `docs/factory/SELF-HOST-COMPONENTS.tsv`,
this ACT halts with `HALT_SCOPE_EXPANSION_REQUIRED`.

## HALT_FORWARD_FIX_PRODUCES_DIFFERENT_ENGINEERING_RESULT

If the corrected winner is not `R-F = scalar_literal_scanner`,
or the corrected margin is not ROBUST (≥ 100), this ACT halts.
The reviewer's engineering result must be preserved, not
re-derived from scratch.

## HALT_REGISTRY_OR_BOOTSTRAP_MUTATED

If this ACT adds a row to
`docs/factory/SELF-HOST-COMPONENTS.tsv` or creates a
`tools/bootstrap/*.HC` file, this ACT halts. The recon ACT
result is bound to a successor `ACT-POLYC-SELFHOST-LEXER02`,
not implemented by this correction.

---

# 4. Residue budget

This ACT's residue is bounded to:

- The three closed defects repaired in
  `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/c2/`.
- The `F-NO-PYTHON` campaign residue (12 grandfathered
  Python files; not in scope).
- The inherited ARM `libtos/strings.HC` platform residue
  (P2; carried from LEXER01).
- One new evidence directory:
  `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/`.
- One new ACT contract document:
  `docs/acts/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01.md`.
- One bounded ROADMAP.md status transition block.

No new candidate slices, no new COMPONENT registry rows, no
new tests outside this ACT's scope, no Python mutations.


---

# 5. Predecessor gates

Predecessor `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01` is
recorded as CLOSED at `7adb9e8`. Per F14, the historical
CLOSE is preserved; this correction ACT does not modify
the historical document. Instead:

1. The corrected closure evidence is recorded under a new
   `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/`
   evidence directory.
2. The correction ACT itself becomes the authoritative
   post-correction record.
3. The `docs/ROADMAP.md` S1 status block is updated with a
   new `CORRECTION01` sub-block recording the
   `PASS_WITH_CORRECTION_RESIDUE` verdict and the corrected
   verdict `PASS`.
4. The original engineering result (R-F winner, score,
   margin, ABI, oracle, seam) is preserved verbatim and
   re-cited in this correction ACT's evidence.

The F14 doctrine is binding here. Any review hypothesis
that "the closed evidence could be quietly fixed by
editing in place" is rejected; corrections live in new
`-CORRECTION<N+1>/` directories.

---

# 6. Commit topology

This ACT closes in four sequential commits, each
topologically distinct and each carrying the correct
trailer:

```text
1. C1 RED     ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01
              ACT-Phase: RED
              (defect-summary.txt + ACT contract document)

2. C2 IMPL    ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01
              ACT-Phase: IMPL
              (forward-fix ledger files)

3. C3 EVIDENCE ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01
              ACT-Phase: EVIDENCE
              (independent re-derivation)

4. C4 CLOSE   ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01
              ACT-Phase: CLOSE
              ACT-Verdict: PASS_WITH_CORRECTION_RESIDUE
              (closure packet + HANDOFF + ROADMAP status block)
```

No commit count beyond these four is authorized.

---

# 7. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`. The HANDOFF
file lives at
`evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01/HANDOFF.md`
and is descriptive only; the authoritative verdict is the
`ACT-Verdict` trailer of the CLOSE commit.

---

# 8. After closure

After this correction ACT closes:

- `ACT-POLYC-SELFHOST-LEXER02` may open with the **frozen
  subject** exactly `scalar_literal_scanner` (members:
  `countNumberLen`, `lexNumeric`, `lexCharConst`), per
  `c4/next-act-binding.txt` of the recon ACT.
- The recon ACT's verdict is updated by inheritance:
  `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01` -> CORRECTION01
  -> `ACT-Verdict: PASS_WITH_CORRECTION_RESIDUE`,
  `ACT-Corrected-Verdict: PASS`.
- No LEXER02 work is in scope of this correction ACT.
