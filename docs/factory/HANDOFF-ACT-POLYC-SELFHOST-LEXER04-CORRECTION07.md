# HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION07

## VERDICT

`ACT-Verdict: PASS_TRUE_GREEN`

CORRECTION06's C3 EVIDENCE regression (removed aggregate counts needed
for AC25 to pass) and the patch hygiene residue in
`CORRECTION06/c1/c1-ac41-ac42-restore-plan.txt` are repaired.

## IDENTITY

```text
BRANCH: main
ACT: ACT-POLYC-SELFHOST-LEXER04-CORRECTION07
ENTRY_HEAD: c9c31894a0431a3a2be7b0f1bdd65a4ac7ce0277
FINAL_HEAD: <C2 commit>
COMMIT_COUNT: 3 (C0, C1, C2)
```

## ROOT CAUSE / FINDING

`ACT-POLYC-SELFHOST-LEXER04-CORRECTION06` C3 EVIDENCE commit (f61ed77)
ran the AC witness verifier with output destination
`c3-ac-witness-results.tsv`. The verifier overwrites its output file,
so the final verifier run REMOVED the aggregate counts
(`WITNESS_FAIL=0`, `WITNESS_MISSING=0`) that C2 IMPL had appended to
that file.

This regressed AC25:
- AC25 w49: `WITNESS_FAIL EQ 0` -> MISSING (no KV in file)
- AC25 w50: `WITNESS_MISSING EQ 0` -> MISSING (no KV in file)

Two ledger SHAs also drifted because the witness-results file was
overwritten.

## RED

C0 entry identity captures the regression at f61ed77/c9c3189:
- WITNESS_TOTAL=75, WITNESS_PASS=73, WITNESS_MISSING=2
- AC_LEDGER_EVIDENCE_SHA_MISMATCH=2

## IMPLEMENTATION (ACT §22-§24)

C1 IMPL made three repairs in a single commit:

1. `c3-ac-witness-results.tsv`: appended aggregate counts
   `WITNESS_TOTAL=75`, `WITNESS_PASS=75`, `WITNESS_FAIL=0`,
   `WITNESS_MISSING=0`.
2. `mandatory-ac-status.tsv`: regenerated with fresh SHAs after all
   evidence file changes; `AC_LEDGER_EVIDENCE_SHA_MISMATCH=0`.
3. `CORRECTION06/c1/c1-ac41-ac42-restore-plan.txt`: removed trailing
   blank line. Cumulative `git diff --check 87106d6..HEAD` is now
   clean.

## GATES

```text
git diff --check 87106d6..HEAD: 0 errors
WITNESS_TOTAL=75, WITNESS_PASS=75, WITNESS_FAIL=0, WITNESS_MISSING=0
WITNESS_RC=0 verdict=PASS
AC_LEDGER_TOTAL=44, AC_LEDGER_EVIDENCE_SHA_MISMATCH=0
AC_LEDGER_RC=0 verdict=PASS
TOKEN_SCHEMA_VERIFY_RC=0
WORKTREE_CLEAN_AT_C2=YES
```

## SCOPE

Modified:

- `evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/c3-ac-witness-results.tsv` (aggregate counts appended)
- `evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/mandatory-ac-status.tsv` (SHAs regenerated)
- `evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION06/c1/c1-ac41-ac42-restore-plan.txt` (trailing blank removed)
- `evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION07/c1/c1-impl-evidence.txt` (NEW)
- `docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION07.md` (NEW)
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION07.md` (NEW)

CORRECTION05 (5 commits, d0bfc27) and CORRECTION06 (5 commits,
c9c3189) history remain immutable.

## RESIDUE

None. All gates pass; tree is clean.

## NEXT ACT

LEXER04 is complete. The natural next ACT is
`ACT-POLYC-SELFHOST-SURFACE-RECON03` as recommended by the Factory
reviewer.
