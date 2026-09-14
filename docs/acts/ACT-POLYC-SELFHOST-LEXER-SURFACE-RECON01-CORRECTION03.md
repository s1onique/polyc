# ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03

**Title:** Microscopic governance correction — repair single evidence-path defect in ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02 (C1 and C3 cite a nonexistent CORRECTION01/c3/fresh-scores.tsv; the canonical score source is the original recon ACT's c3/fresh-scores.tsv); preserve engineering result; finalize binding for LEXER02

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02` CLOSE commit `8698423` (closed with `ACT-Verdict: PASS_WITH_CORRECTION_RESIDUE`, but with one residual evidence-path defect per review audit)

**Class:** GOVERNANCE / EVIDENCE-CORRECTION / PATH-BOOKKEEPING

**Production compiler semantic changes:** **FORBIDDEN** — no `src/**`, no `tools/bootstrap/**`, no `docs/factory/SELF-HOST-COMPONENTS.tsv` mutation in this correction ACT; corrections live in a forward-only `CORRECTION03/` evidence tree per F14

**IR/ABI repair authorization:** NONE

**LLVM authorization:** NONE

**Language-change authorization:** NONE

**No-Python authorization:** NONE — `POLYC_TOOLS_TRACKED_PYTHON = 12` remains the canonical pre-state

**VERDICT (target):** `PASS_WITH_CORRECTION_RESIDUE`

**ACT-Supersedes:** `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02`

**ACT-Corrected-Verdict:** `PASS_WITH_CORRECTION_RESIDUE` (no engineering claim changed; only the cited evidence path is corrected to the actual canonical source)

---

# 0. Mission

The review audit of `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02`
closure (commit `8698423`) identified one residual evidence-path defect:

**DEFECT-6 (P1):** `CORRECTION02/c1/defect-summary.txt` and
`CORRECTION02/c3/independent-re-derivation.txt` both cite
`evidence/.../CORRECTION01/c3/fresh-scores.tsv` as the source
for the awk sort. The CORRECTION01 evidence tree at
`c3/` contains only `independent-re-derivation.txt`; there is
no `fresh-scores.tsv` in `CORRECTION01/c3/`. The literal command
recorded in the CORRECTION02 evidence fails with
"No such file or directory".

The actual canonical score source is the **original recon
ACT**'s `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c3/
fresh-scores.tsv` (created at the recon ACT C3 phase and
preserved immutable per F14).

This is provenance/path bookkeeping, not a ranking or scoring
defect. The numerical sort values are unchanged. The reviewer
explicitly notes: "The ranking values themselves remain correct;
this is provenance/path bookkeeping, not another ranking defect."

After this correction closes, the reviewer recommends:
**"stop auditing this recon lineage unless a semantic defect
appears. LEXER02 is very clearly the next engineering work;
we are now paying more transaction cost on bookkeeping than
on uncertainty in the selected compiler boundary."**

This CORRECTION03 ACT records and re-issues the corrected
evidence path WITHOUT mutating the closed CORRECTION02
evidence tree (F14 honored). No new lexical semantics are
introduced; no new candidate slice is migrated; no Python
is touched.


---

# 1. Authorized surface

This correction ACT authorizes ONLY the following mutations:

1. `docs/acts/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03.md` — new ACT contract document (this file).

2. `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03/` — new evidence directory containing:
   - `c1/` — defect summary (this RED).
   - `c2/` — corrected evidence path (forward-fix file).
   - `c3/` — independent re-execution of the corrected command.
   - `c4/` — closure packet.
   - `HANDOFF.md` — human-readable closure summary.

3. `docs/ROADMAP.md` — append a CORRECTION03 status block (only).

No production semantic mutation is authorized. The CORRECTION02,
CORRECTION01, and recon ACT evidence trees are preserved
immutable per F14.

---

# 2. Phases

## C1 RED (DEFECT RECORD)

Capture the failing evidence for the single path defect:

- `c1/defect-summary.txt` records the literal failure of the
  CORRECTION02 command path and the actual canonical source
  path.

## C2 IMPL (FORWARD-FIX WITHOUT MUTATING CLOSED EVIDENCE)

Per F14, the CORRECTION02 evidence tree is immutable. The
forward-fix lives in this correction ACT's evidence directory
as a single forward-fix file:

- `c2/canonical-score-source.txt` records the correct
  provenance statement:

  ```text
  CANONICAL_SCORE_SOURCE =
    evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c3/fresh-scores.tsv
  ```

  along with the lineage that establishes authority:

  ```text
  SURFACE-RECON01  -> owns the measured 17-region score table
  CORRECTION01     -> interpreted/corrected claims about that table
  CORRECTION02     -> fixed CORRECTION01's presentation mistakes
  CORRECTION03     -> binds CORRECTION02's sort command to the actual source
  ```

## C3 EVIDENCE (INDEPENDENT RE-EXECUTION)

Re-execute the corrected command against the canonical source
and verify it produces the same ranking as
`CORRECTION02/c2/ranking-repaired-v2.txt`:

- `c3/re-executed-sort.txt` records:

  ```sh
  awk -F'\t' 'NR>1 && $1 ~ /^R-/ {gsub(/=/,""); print $1"\t"$NF}' \
      evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01/c3/fresh-scores.tsv \
    | sort -k2,2nr
  ```

  plus the verbatim output of that command.

## C4 CLOSE (CORRECTION VERDICT)

Commit the closure packet. The ACT-Phase is `CLOSE` and the
ACT-Verdict is `PASS_WITH_CORRECTION_RESIDUE` only if:

```text
DEFECT_6_FORWARD_FIX_PRESENT   = YES
CANONICAL_PATH_CORRECT         = YES
SORT_COMMAND_REPRODUCIBLE      = YES (literal re-execution succeeds)
CLOSED_CORRECTION02_MUTATED    = NO (F14 honored)
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

## HALT_CORRECTION02_EVIDENCE_ALREADY_MUTATED

If inspection reveals that the closed CORRECTION02 evidence
tree has been modified since commit `8698423`, this ACT halts.
F14 forbids forward mutations of closed evidence.

## HALT_SCOPE_EXPANSION_REQUIRED

If closing this defect requires semantic changes to `src/**`,
parser/AST/IR/backend, runtime, llvm, formal, tools/bootstrap,
or `docs/factory/SELF-HOST-COMPONENTS.tsv`, this ACT halts.

## HALT_ENGINEERING_RESULT_DRIFTED

If the corrected sort produces a ranking that differs from
`CORRECTION02/c2/ranking-repaired-v2.txt` in any region
placement (i.e. the source file actually referenced in
CORRECTION02 was different from what was stated), this ACT
halts. The numerical sort values must be unchanged.

## HALT_REGISTRY_OR_BOOTSTRAP_MUTATED

If this ACT adds a row to
`docs/factory/SELF-HOST-COMPONENTS.tsv` or creates a
`tools/bootstrap/*.HC` file, this ACT halts.

---

# 4. Residue budget

This ACT's residue is bounded to:

- The single path defect repaired in
  `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03/c2/`.
- The `F-NO-PYTHON` campaign residue (12 grandfathered
  Python files; not in scope).
- The inherited ARM `libtos/strings.HC` platform residue
  (P2; carried from LEXER01).
- One new evidence directory:
  `evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03/`.
- One new ACT contract document:
  `docs/acts/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03.md`.
- One bounded ROADMAP.md status transition block.

No new candidate slices, no new COMPONENT registry rows, no
new tests outside this ACT's scope, no Python mutations.

---

# 5. Predecessor gates

Predecessor `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02`
is recorded as CLOSED at `8698423`. Per F14, the historical
CLOSE is preserved.

---

# 6. Commit topology

This ACT closes in four sequential commits:

```text
1. C1 RED      ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03
               ACT-Phase: RED

2. C2 IMPL     ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03
               ACT-Phase: IMPL

3. C3 EVIDENCE ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03
               ACT-Phase: EVIDENCE

4. C4 CLOSE    ACT: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03
               ACT-Phase: CLOSE
               ACT-Verdict: PASS_WITH_CORRECTION_RESIDUE
               ACT-Supersedes: ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION02
               ACT-Corrected-Verdict: PASS_WITH_CORRECTION_RESIDUE
```

---

# 7. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`. The HANDOFF file
lives at
`evidence/ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01-CORRECTION03/HANDOFF.md`.

---

# 8. After closure — FINAL STOP

After this correction ACT closes, the recon lineage is
considered governance-clean.

Per the reviewer's explicit recommendation:

  "After that, stop auditing this recon lineage unless a
   semantic defect appears. LEXER02 is very clearly the next
   engineering work; we are now paying more transaction cost
   on bookkeeping than on uncertainty in the selected
   compiler boundary."

`ACT-POLYC-SELFHOST-LEXER02` may now open with the **frozen
subject** exactly `scalar_literal_scanner` (members:
`countNumberLen`, `lexNumeric`, `lexCharConst`).

No further CORRECTION04 ACTs are planned in this lineage
unless a semantic defect is observed.
