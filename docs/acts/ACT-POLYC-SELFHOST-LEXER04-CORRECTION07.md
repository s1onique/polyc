# ACT-POLYC-SELFHOST-LEXER04-CORRECTION07

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair CORRECTION06 C3 EVIDENCE regression that removed the
aggregate counts needed for AC25 to pass

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / LEXER / QUALIFICATION-INFRA / CORRECTION-CORRECTION

**Priority:** P0

---

# 0. Mission

`ACT-POLYC-SELFHOST-LEXER04-CORRECTION06` C3 EVIDENCE commit (f61ed77)
removed the aggregate counts (WITNESS_FAIL=0, WITNESS_MISSING=0) that
C2 IMPL had appended to `c3-ac-witness-results.tsv`. The C3 commit's
"aggregate counts appended after final verifier run" message was a
self-fulfilling lie: the verifier overwrites its output file, so the
final verifier run REMOVED the previously-appended aggregates.

Result at CORRECTION06 C4 close:

```text
WITNESS_TOTAL=75
WITNESS_PASS=73  (should be 75)
WITNESS_FAIL=0
WITNESS_MISSING=2  (should be 0)
WITNESS_RC=1 verdict=FAIL

AC_LEDGER_EVIDENCE_SHA_MISMATCH=2  (AC25, AC28 SHA drift)
AC_LEDGER_RC=1 verdict=FAIL
```

CORRECTION07 restores the missing aggregate counts via a single new
commit (the AC25 WITNESS_FAIL=0 / WITNESS_MISSING=0 lines). It also
fixes the trailing-blank-line residue in
`CORRECTION06/c1/c1-ac41-ac42-restore-plan.txt` and the ledger SHAs.

## Topology (3 commits: C0, C1, C2)

```text
C0 AUTH         -- this ACT + entry identity + scope + residue capture
C1 RED/IMPL     -- append aggregate counts to c3-ac-witness-results.tsv;
                   fix c1-ac41-ac42-restore-plan.txt trailing blank;
                   regenerate mandatory-ac-status.tsv
C2 CLOSE        -- final HANDOFF; verify all gates pass
```

No C3/C4 — this ACT is a tightly-scoped one-pass repair.

## Authorized scope

- `evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/c3-ac-witness-results.tsv` (append aggregate counts)
- `evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/mandatory-ac-status.tsv` (regenerate SHAs)
- `evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION06/c1/c1-ac41-ac42-restore-plan.txt` (fix trailing blank)
- `evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION07/*` (NEW evidence)
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION07.md` (NEW)

## Forbidden

- Amend any prior commit
- Modify production tools
- Weaken authorized AC predicates

## Verdict

PASS_TRUE_GREEN requires:

```text
WITNESS_TOTAL=75
WITNESS_PASS=75
WITNESS_FAIL=0
WITNESS_MISSING=0
WITNESS_RC=0

AC_LEDGER_EVIDENCE_SHA_MISMATCH=0
AC_LEDGER_TOTAL=44
AC_LEDGER_RC=0

PATCH_HYGIENE_ERRORS=0 (cumulative 87106d6..HEAD)
WORKTREE_CLEAN_AT_C2=YES
```
