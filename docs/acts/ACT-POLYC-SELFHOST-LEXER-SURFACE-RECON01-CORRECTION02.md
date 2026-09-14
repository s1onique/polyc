# ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02

**Title:** Bounded governance correction — repair two bookkeeping defects in ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01 (negative-score block of ranking-repaired.txt not monotonic; ac40-transform.tsv byte-description misleading); preserve engineering result; finalize binding for LEXER02

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01` CLOSE commit `ec12b5c` (closed with `ACT-Verdict: PASS_WITH_CORRECTION_RESIDUE`, but with two bookkeeping closure defects per review audit)

**Class:** GOVERNANCE / EVIDENCE-CORRECTION / CLOSURE-DEFECT-REPAIR

**Production compiler semantic changes:** **FORBIDDEN** — no `src/**`, no `tools/bootstrap/**`, no `docs/factory/SELF-HOST-COMPONENTS.tsv` mutation in this correction ACT; corrections live in a forward-only `CORRECTION02/` evidence tree per F14

**IR/ABI repair authorization:** NONE

**LLVM authorization:** NONE

**Language-change authorization:** NONE

**No-Python authorization:** NONE — `POLYC_TOOLS_TRACKED_PYTHON = 12` remains the canonical pre-state; this ACT must not introduce or remove Python

**VERDICT (target):** `PASS_WITH_CORRECTION_RESIDUE`

**ACT-Supersedes:** `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01`

**ACT-Corrected-Verdict:** `PASS_WITH_CORRECTION_RESIDUE` (the engineering result was already preserved in CORRECTION01; only the bookkeeping defects are repaired here; the corrected verdict is the same as the predecessor's because no engineering claim changed)


---

# 0. Mission

The review audit of `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01`
closure (commit `ec12b5c`) identified two residual bookkeeping defects:

1. **DEFECT-4 (P1):** `c2/ranking-repaired.txt` claims
   "Strictly monotonic in FINAL_SCORE descending" but its
   negative-score block (rows 12..16) is not monotonic:

   ```text
   12  R-G  -53
   13  R-I  -45
   14  R-B  -49
   15  R-A  -38
   16  R-C  -70
   ```

   The strict descending order is:

   ```text
   12  R-A  -38
   13  R-I  -45
   14  R-B  -49
   15  R-G  -53
   16  R-C  -70
   ```

   The CORRECTION01's own C3 independent re-derivation
   (`c3/independent-re-derivation.txt` V-2) mechanically computed
   the correct order via `awk | sort -k2 -n -r`. The forward-fix
   ledger file disagrees with the C3 evidence inside the same
   correction ACT.

   This makes the following closure claims false:
     - `RANKING_MONOTONIC_IN_REPAIRED = YES`
     - `AC08 ranking monotonicity fixed = PASS`

   The winner is unaffected: R-F +627, R-E +285, +342 ROBUST
   margin. This is purely a presentation defect.

2. **DEFECT-5 (P2):** `c2/ac40-transform.tsv` describes the
   byte-level correction as:

   ```text
   original_eof_byte  = 0x0a (LF)
   corrected_eof_byte = (no trailing LF)
   ```

   For a Git `"new blank line at EOF"` diagnostic, the actual
   suffix is:

   ```text
   original_suffix  = 0x0a 0x0a  (one LF ending content + one extra LF for the blank line)
   corrected_suffix = 0x0a        (one LF ending content; no extra blank line)
   ```

   The TSV's `(no trailing LF)` description is misleading
   because removing the final LF entirely would create a
   different "no newline at end of file" diagnostic. The prose
   elsewhere in the CORRECTION01 evidence correctly says
   "remove the trailing blank line"; only the TSV byte column
   is misleading.

The substantive recon result — `R-F = scalar_literal_scanner`
with FINAL_SCORE +627, ROBUST margin 342, E1..E14 PASS, ABI
BOUNDED, oracle feasible, production seam possible — is
preserved verbatim and is unchanged by this correction ACT.

This CORRECTION02 ACT records, repairs, and re-classifies
the two bookkeeping defects in a bounded pass. No new lexical
semantics are introduced; no new candidate slice is migrated;
no Python is touched; the closed CORRECTION01 evidence tree
is preserved immutable per F14.

---

# 1. Authorized surface

This correction ACT authorizes ONLY the following mutations:

1. `docs/acts/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02.md` — new ACT contract document (this file).

2. `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02/` — new evidence directory containing:
   - `c1/` — defect summary (this RED).
   - `c2/` — corrected claim ledger (per-defect forward-fix files).
   - `c3/` — independent re-derivation evidence.
   - `c4/` — closure packet.
   - `HANDOFF.md` — human-readable closure summary.

3. `docs/ROADMAP.md` — append a CORRECTION02 status block (only).

No production semantic mutation is authorized. No compiler
source, parser/AST/IR/backend, runtime, llvm, or formal
directory is touched. No new registry row. No Python mutation.
No bootstrap component created. The CORRECTION01 evidence
tree is preserved immutable per F14.


---

# 2. Phases

## C1 RED (DEFECT RECORD)

Capture the failing evidence for the two residual bookkeeping
defects:

- DEFECT-4: `c2/ranking-repaired.txt` rows 12..16 do not match
  the mechanically-sorted order produced by C3 independent
  re-derivation. Side-by-side comparison recorded in
  `c1/defect-summary.txt`.

- DEFECT-5: `c2/ac40-transform.tsv` columns `original_eof_byte`
  and `corrected_eof_byte` are misleading. The correct
  description uses `original_suffix` and `corrected_suffix`
  with byte-pair values. Recorded in `c1/defect-summary.txt`.

## C2 IMPL (FORWARD-FIX WITHOUT MUTATING CLOSED EVIDENCE)

Per F14, the CORRECTION01 evidence tree is immutable. The
forward-fix lives in this correction ACT's evidence directory
and is expressed as a "corrected claim ledger":

- DEFECT-4 forward-fix: `c2/ranking-repaired-v2.txt` reproduces
  the corrected monotonic ranking for all 16 eligible regions
  (R-J excluded). The negative-score block (rows 12..16) is
  reordered to match the C3 mechanical sort:
  R-A -38, R-I -45, R-B -49, R-G -53, R-C -70.

- DEFECT-5 forward-fix: `c2/ac40-transform-v2.tsv` reproduces
  the corrected byte-level description with
  `original_suffix` and `corrected_suffix` columns:
  `original_suffix = 0x0a 0x0a`,
  `corrected_suffix = 0x0a`.

## C3 EVIDENCE (INDEPENDENT RE-DERIVATION)

Re-derive the corrected claims from independent inputs:

- Independent re-sort of all 16 eligible regions by
  `FINAL_SCORE` descending; verify the negative-score block
  is monotonic: R-A -38, R-I -45, R-B -49, R-G -53, R-C -70.
- Independent re-emit of the byte-level diagnostic on the
  three closed recon ACT evidence files; verify the suffix
  interpretation matches the corrected description.

## C4 CLOSE (CORRECTION VERDICT)

Commit the closure packet. The ACT-Phase is `CLOSE` and the
ACT-Verdict is `PASS_WITH_CORRECTION_RESIDUE` only if:

```text
DEFECT_4_FORWARD_FIX_PRESENT   = YES
DEFECT_5_FORWARD_FIX_PRESENT   = YES
RANKING_MONOTONIC              = YES (16 eligible, 1 ineligible)
BYTE_DESCRIPTION_REPAIRED      = YES (suffix-based, not single-byte)
CLOSED_CORRECTION01_MUTATED    = NO (F14 honored)
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


---

# 3. Halts

## HALT_CORRECTION01_EVIDENCE_ALREADY_MUTATED

If inspection reveals that the closed CORRECTION01 evidence
tree has been modified since commit `ec12b5c`, this ACT halts.
F14 forbids forward mutations of closed evidence; the
correction must live in `CORRECTION02/`, not in the
predecessor tree.

## HALT_SCOPE_EXPANSION_REQUIRED

If closing the two defects requires semantic changes to
`src/**`, parser/AST/IR/backend, runtime, llvm, formal,
tools/bootstrap, or `docs/factory/SELF-HOST-COMPONENTS.tsv`,
this ACT halts with `HALT_SCOPE_EXPANSION_REQUIRED`.

## HALT_ENGINEERING_RESULT_DRIFTED

If the corrected winner is not `R-F = scalar_literal_scanner`,
or the corrected margin is not ROBUST (≥ 100), or any other
engineering claim of the recon ACT differs from the values
recorded in `c2/winner-invariance.tsv` of CORRECTION01, this
ACT halts. The recon engineering result is preserved verbatim.

## HALT_REGISTRY_OR_BOOTSTRAP_MUTATED

If this ACT adds a row to
`docs/factory/SELF-HOST-COMPONENTS.tsv` or creates a
`tools/bootstrap/*.HC` file, this ACT halts.

---

# 4. Residue budget

This ACT's residue is bounded to:

- The two closed defects repaired in
  `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02/c2/`.
- The `F-NO-PYTHON` campaign residue (12 grandfathered
  Python files; not in scope).
- The inherited ARM `libtos/strings.HC` platform residue
  (P2; carried from LEXER01).
- One new evidence directory:
  `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02/`.
- One new ACT contract document:
  `docs/acts/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02.md`.
- One bounded ROADMAP.md status transition block.

No new candidate slices, no new COMPONENT registry rows, no
new tests outside this ACT's scope, no Python mutations.

---

# 5. Predecessor gates

Predecessor `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01`
is recorded as CLOSED at `ec12b5c`. Per F14, the historical
CLOSE is preserved; this correction ACT does not modify the
historical document.

---

# 6. Commit topology

This ACT closes in four sequential commits:

```text
1. C1 RED      ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02
               ACT-Phase: RED

2. C2 IMPL     ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02
               ACT-Phase: IMPL

3. C3 EVIDENCE ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02
               ACT-Phase: EVIDENCE

4. C4 CLOSE    ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02
               ACT-Phase: CLOSE
               ACT-Verdict: PASS_WITH_CORRECTION_RESIDUE
               ACT-Supersedes: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION01
               ACT-Corrected-Verdict: PASS_WITH_CORRECTION_RESIDUE
```

---

# 7. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`. The HANDOFF file
lives at
`evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02/HANDOFF.md`.

---

# 8. After closure

After this correction ACT closes:

- `ACT-POLYC-SELFHOST-LEXER02` may open with the **frozen
  subject** exactly `scalar_literal_scanner` (members:
  `countNumberLen`, `lexNumeric`, `lexCharConst`), per
  `c4/next-act-binding.txt` of the recon ACT.
- The recon ACT's corrected verdict lineage:
  - SURFACE-RECON01 → CORRECTION01 → CORRECTION02
  - Final corrected verdict: PASS_WITH_CORRECTION_RESIDUE
  - Engineering result preserved verbatim throughout.
- No LEXER02 work is in scope of this correction ACT.
