# ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01

**Title:** Repair mechanical TSV verdict-column defect in
`ACT-POLYC-SELFHOST-LEXER03-CORRECTION01`'s mandatory-AC table,
and additively reclassify the C01 closure verdict.

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** DOCUMENTATION (closure-truth repair). No production
code touched. No compiler/tool source touched.

**Predecessor:** ACT-POLYC-SELFHOST-LEXER03-CORRECTION01 (CLOSED
PASS at `9012c94`, but the C3 mandatory-AC TSV is semantically
malformed — see Mission).

**Production semantic changes:** FORBIDDEN.

**IR / ABI / LLVM authorization:** NONE.

---

## 0. Mission

The C3 mandatory-AC TSV
`evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/c3/mandatory-ac-status-correction01.tsv`
declares its schema as `ac_id | ac_description | evidence_file |
verdict | notes` and uses `PASS`, `FAIL`, and `N/A` as the
verdict vocabulary.

Six rows (AC23, AC24, AC25, AC26, AC27, AC29) put the token
`CORRECTION01` in the verdict column. That token is NOT in the
declared verdict vocabulary, so mechanically these rows are
non-PASS, non-FAIL, non-N/A — i.e. **malformed / unverified**.
The committed TSV therefore reads:

```text
TOTAL_ROWS    = 30
PASS_ROWS     = 24
NONPASS_ROWS  = 6   (CORRECTION01 token in verdict column)
```

But
`evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/c3/c3-ac-count-alignment.txt`
establishes:

> "PASS only after all 30 acceptance criteria are PASS."

So `CORRECTION01 CLOSED PASS` at `9012c94` is **false at the
mechanical TSV layer** even though the underlying repairs
(whitespace hygiene, AC split, count alignment, title
amendment) are themselves green.

The bounded repair is:

1. RED: re-prove the malformed verdict-column defect as
   committed.
2. Add a **NEW** corrected mandatory-AC TSV under
   `evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01-CORRECTION01/c3/`
   that uses only `PASS` in the verdict column for the 30 ACs.
   Do NOT rewrite the closed C3 TSV (F14-protected).
3. Document the additive verdict reclassification:
   - Pre-CORRECTION01-CORRECTION01: `MANDATORY_AC_TABLE =
     MALFORMED_SEMANTICALLY`, `MANDATORY_AC_PASS_COUNT = 24/30`,
     `CORRECTION01_CLOSE_PASS = FALSE_GREEN`.
   - Post-CORRECTION01-CORRECTION01: `MANDATORY_AC_TABLE =
     GREEN`, `MANDATORY_AC_PASS_COUNT = 30/30`,
     `CORRECTION01_CLOSE_PASS = TRUE_GREEN`.
4. Update ROADMAP and HANDOFF additively (no rewrite of any
   closed artifact).

This ACT is small, bounded, and mechanical. It does not touch
production code, compiler tools, or the existing 35-file
original LEXER03 evidence directory. It only adds a new
correction-of-correction evidence directory, the new corrected
TSV, and additive ROADMAP/HANDOFF entries.

## 1. Why

A reviewer of the CORRECTION01 closure identified that the
mandatory-AC TSV does not actually have 30 PASS rows; it has 24
PASS rows and 6 rows using a non-declared verdict token. This
is a TSV construction defect (verdict column vocabulary was
extended implicitly without declaring the new token). The
underlying engineering repairs are all green — only the
closure truth-statement was malformed.

The CORRECTION01-CORRECTION01 does NOT consume the CORRECTION02
budget (which is reserved for the real LEXER03-specific
stage2/stage3 fixed-point evidence) and does NOT consume the
LEXER04 budget.

## 2. Scope

### allowed

- `evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01-CORRECTION01/`
  (NEW directory; c1 RED, c2 entry identity, c3 corrected TSV
  + per-row PASS justification, c4 closure summary)
- `docs/ROADMAP.md` (additive CORRECTION01-CORRECTION01 status
  block; existing LEXER03-CORRECTION01 block ADDITIVELY amended
  in place, no rewrite)
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER03-CORRECTION01.md`
  (additive amendment at end; do not rewrite closed HANDOFF body)
- A new HANDOFF for this CORRECTION01-CORRECTION01
  (`docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01.md`)

### forbidden

- Editing any file under `evidence/ACT-POLYC-SELFHOST-LEXER03/c{1,2,3}/*`
  (F14-protected original LEXER03 evidence)
- Editing `evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/c{1,2,3,4}/*`
  (F14-protected CORRECTION01 evidence; closed C3 TSV must remain
  as historical evidence of the malformed state)
- Editing `docs/acts/ACT-POLYC-SELFHOST-LEXER03.md` or
  `docs/acts/ACT-POLYC-SELFHOST-LEXER03-CORRECTION01.md`
  (F14-protected ACT documents)
- Any production code change (`src/`, `Makefile`)
- Any compiler/tool source change (`tools/bootstrap/`,
  `tools/quality/`)
- Renaming or restructuring the existing evidence directories
- Consuming `CORRECTION02` budget (out of scope)

## 3. Entry gate

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

Required state:

- on main;
- worktree clean;
- entry HEAD recorded (`9012c948c535e66806b025c436a585f5f0b2f0b2`).

## 4. Principal RED

Independent reproduction of the malformed verdict-column
defect as committed in `9012c94`:

```bash
awk -F'\t' 'NR>1 {print $4}' \
    evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01/c3/mandatory-ac-status-correction01.tsv \
    | sort | uniq -c
```

Expected as committed:

```text
   6 CORRECTION01
  24 PASS
```

This proves `MANDATORY_AC_PASS_COUNT = 24/30`,
not `30/30` as the ROADMAP block claims. The defect is
real and reproducible. RED lives in
`evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01-CORRECTION01/c1/c1-red-tsv-defect.txt`.

## 5. Implementation boundary

The C3 evidence directory for this ACT contains:

- `mandatory-ac-status-correction01-correction01.tsv` — the
  **new** corrected TSV with `verdict=PASS` for all 30 rows.
  The 6 previously-malformed rows are PASS because their notes
  document the underlying green repairs (whitespace hygiene,
  AC split, count alignment, title amendment, verdict
  taxonomy installation, hand-off completion).
- `c3-verdict-vocabulary.md` — declares the allowed verdict
  vocabulary explicitly: `PASS | FAIL | N/A | DEFERRED` only.
  `CORRECTION01` is NOT an allowed verdict token; it was
  implicit in the original TSV and that implicit extension was
  the bug.

No production code, no tool source, no closed ACT, no closed
evidence file is modified.

## 6. RED → IMPL → EVIDENCE → CLOSE discipline

F3: RED before production implementation. The production
"implementation" here is purely documentary (a new TSV +
new evidence files + additive ROADMAP/HANDOFF amendments).
The RED reproduction is the c1-red-tsv-defect.txt file.

F5: No test weakening. The new TSV is more strict than the
old one (it uses only the declared verdict vocabulary), not
less strict.

F10: Conservation. The closed C3 TSV remains untouched
(`git diff 9012c94 HEAD -- evidence/.../CORRECTION01/c3/mandatory-ac-status-correction01.tsv`
returns empty).

## 7. ACT-Phase plan

- C0 AUTH (this commit): ACT document authored first.
- C1 RED: `c1-red-tsv-defect.txt` reproduces the malformed
  verdict-column defect.
- C2 IMPL: none required (the fix is a new evidence file,
  not production code). The fix artifact is the new TSV
  authored in C3 EVIDENCE.
- C3 EVIDENCE: `c3-verdict-vocabulary.md` + new
  `mandatory-ac-status-correction01-correction01.tsv`
  (30 PASS rows).
- C4 CLOSE: `c4-entry-identity.txt`, new
  `HANDOFF-ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01.md`,
  additive ROADMAP entries, additive HANDOFF-CORRECTION01
  amendment. All gates re-run.

## 8. Verdict taxonomy (binding for this ACT)

```text
MANDATORY_AC_TABLE_OLD         = MALFORMED_SEMANTICALLY (24 PASS, 6 CORRECTION01)
MANDATORY_AC_TABLE_NEW         = GREEN (30 PASS, 0 non-PASS)
CORRECTION01_CLOSE_PASS_OLD    = FALSE_GREEN (defect)
CORRECTION01_CLOSE_PASS_NEW    = TRUE_GREEN  (after C01-C01 additive repair)
F14_IMMUTABILITY               = PRESERVED (closed c3 TSV untouched)
SCOPE_DISCIPLINE               = PRESERVED (no production/tool edits)
```

## 9. ACT-Verdict (target)

PASS_TRUE_GREEN only after:

1. c1-red-tsv-defect.txt exists and reproduces the defect.
2. New TSV has `TOTAL=30, PASS=30, OTHER=0` mechanically.
3. F14-immutability check passes
   (`git diff 9012c94 HEAD -- evidence/.../CORRECTION01/c3/mandatory-ac-status-correction01.tsv`
   is empty).
4. All factory gates re-run: `make gate-fast` PASS,
   `factory-append-only-test.sh` PASS=11 FAIL=0,
   `lexer08-direct-differential` 45/45 PASS,
   `git diff --check` clean on the new files.
5. ROADMAP and HANDOFF amendments are additive (no rewrites).
