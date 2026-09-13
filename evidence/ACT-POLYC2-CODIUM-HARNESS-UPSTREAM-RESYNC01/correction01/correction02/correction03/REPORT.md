# CORRECTION03 — Epistemic-classification closure

## VERDICT

```
VERDICT=PASS

RESYNC_OPERATION=PASS

D1=FIXED
D2=FIXED
R3=FIXED
R4=FIXED_BY_EVIDENCE_QUALIFICATION

HISTORICAL_PARENT_IMMUTABILITY_MECHANICALLY_PROVEN=false
HISTORICAL_PARENT_MUTATION_OBSERVED=false

FORWARD_PARENT_IMMUTABILITY_MECHANICALLY_PROVEN=true

EPISTEMIC_LIMITATION=NO_PRE_CORRECTION_CONTENT_ANCHOR
EPISTEMIC_LIMITATION_STATUS=ACCEPTED_AND_CLOSED

REMAINING_RESIDUE=NONE
```

## Why this exists

CORRECTION02 closed the substantive findings but its closing wording
implied that a future comparison against the CORRECTION01 forward
anchor could mechanically prove historical parent immutability for
the whole CORRECTION01 interval.

A forward anchor can only prove immutability from its own time
forward; it cannot retroactively bind an earlier interval.

CORRECTION03 therefore separates two distinct claims:

1. **Forward immutability** (from CORRECTION01 anchor to present):
   mechanically proven in this CORRECTION03 cycle.
2. **Historical immutability** (before CORRECTION01 anchor):
   irreversibly unrecoverable, because no pre-CORRECTION01 content
   anchor exists. This is a permanent epistemic limitation.

The limitation is now explicitly classified and accepted as closed
under truthful limitation. It is not an open engineering task.

## Mechanical evidence

### Y04 / Y05 — Forward anchor recheck

The CORRECTION01 anchor
`evidence/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01/correction01/parent-files-current-hashes.txt`
recorded SHA-256 hashes of the 18 parent ACT files at
`2026-09-13 22:33:58`.

CORRECTION03 recomputed the hashes of the same 18 files; the
results are in `parent-files-current-hashes.recheck.txt`.

Sorted-hash-set comparison:

```
$ shasum -a 256 ../*.txt ../*.md | awk '{print $1}' | sort > now.txt
$ awk '{print $1}' ../parent-files-current-hashes.txt | sort > then.txt
$ cmp -s then.txt now.txt
$ echo $?
0
```

`cmp_exit=0`. Both sorted-hash files have SHA-256
`54673a5797ca1148b9467511fee24598df857290c7f7807b250e7bc736d32dae`
(identical, recorded in `forward-anchor-set-digest.txt`).

**FORWARD_PARENT_IMMUTABILITY_MECHANICALLY_PROVEN = true**
(no parent content change since the CORRECTION01 anchor).

### Y07 — Historical immutability remains observational

No pre-CORRECTION01 content anchor exists. The strongest available
historical claim is:

* Filesystem mtime corroboration: all 18 parent files have mtimes
  strictly within the parent ACT window (22:25:12 .. 22:27:40).
* No corrective command path writes to any parent ACT file.

**HISTORICAL_PARENT_IMMUTABILITY_MECHANICALLY_PROVEN = false**
**HISTORICAL_PARENT_MUTATION_OBSERVED = false**
**HISTORICAL_PARENT_EVIDENCE_STRENGTH =
    OBSERVATIONAL_WITH_MTIME_CORROBORATION**
**HISTORICAL_PARENT_IMMUTABILITY_REASON = NO_PRE_CORRECTION_CONTENT_ANCHOR**

This MUST NOT later be upgraded to mechanical proof unless an
independent retained pre-CORRECTION01 content anchor is actually
discovered. No such anchor is known to exist; the gap is permanent.

## Prior-artifact immutability — current state

Recorded as forward anchors only (no comparison against any earlier
anchor, because none exists):

* `parent-files-current-hashes.recheck.txt`
  — 18 parent ACT files, recomputed now; matches the CORRECTION01
  anchor (cmp_exit=0 on sorted-hash set; SHA-256 54673a57...).
* `correction01-files-current-hashes.txt`
  — 11 CORRECTION01 files, current hashes recorded as a forward
  anchor for any future CORRECTION04.
* `correction02-files-current-hashes.txt`
  — 5 CORRECTION02 files, current hashes recorded as a forward
  anchor for any future CORRECTION04.

## Repository invariants (Y08)

* `HEAD`               = `12e4e7a2e093c08a8308b73b172a6192cda89c3d`
* `main`               = `7d7b983686fac2239a47288fe4b8e5dbbb617d55`
* `origin/main`        = `7d7b983686fac2239a47288fe4b8e5dbbb617d55`
* `backup/ACT-...-1f8250b` = `1f8250b97d0f203dcb81772e8e715feee2401a90`
* `harness/codium-polyc2` HEAD = `12e4e7a2e093c08a8308b73b172a6192cda89c3d`

All unchanged from CORRECTION01 / CORRECTION02.

## Prior-evidence mtime table (Y09 corroboration)

```
2026-09-13 22:25:16  ../BACKUP_BRANCH.txt             (parent ACT)
2026-09-13 22:25:16  ../HARNESS_BRANCH.txt            (parent ACT)
2026-09-13 22:25:16  ../OLD_HEAD.txt                  (parent ACT)
2026-09-13 22:27:40  ../REPORT.md                     (parent ACT)
2026-09-13 22:26:39  ../final-graph.txt               (parent ACT)
2026-09-13 22:25:33  ../gate-fast-main.txt            (parent ACT)
2026-09-13 22:25:31  ../gate-fast-output.txt          (parent ACT)
2026-09-13 22:25:56  ../gate-push-harness.txt         (parent ACT)
2026-09-13 22:26:23  ../gate-push-main.txt            (parent ACT)
2026-09-13 22:26:37  ../post-ACT-harness-commits.txt  (parent ACT)
2026-09-13 22:25:12  ../pre-ACT-branches.txt          (parent ACT)
2026-09-13 22:25:12  ../pre-ACT-diff-stat.txt         (parent ACT)
2026-09-13 22:25:12  ../pre-ACT-left-right.txt        (parent ACT)
2026-09-13 22:25:12  ../pre-ACT-local-only-commits.txt(parent ACT)
2026-09-13 22:25:12  ../pre-ACT-remotes.txt           (parent ACT)
2026-09-13 22:25:12  ../pre-ACT-status.txt            (parent ACT)
2026-09-13 22:25:22  ../range-diff.txt                (parent ACT)
2026-09-13 22:25:20  ../rebase-output.txt             (parent ACT)
2026-09-13 22:35:05  ../../correction01/REPORT.md
2026-09-13 22:34:34  ../../correction01/acceptance-reclassification.txt
2026-09-13 22:33:53  ../../correction01/current-ref-verification.txt
2026-09-13 22:33:09  ../../correction01/extract-signature.sh
2026-09-13 22:33:11  ../../correction01/gate-push-harness.signature.txt
2026-09-13 22:33:11  ../../correction01/gate-push-main.signature.txt
2026-09-13 22:32:30  ../../correction01/original-log-hashes.txt
2026-09-13 22:33:58  ../../correction01/parent-files-current-hashes.txt
2026-09-13 22:32:30  ../../correction01/raw-log-cmp.txt
2026-09-13 22:33:11  ../../correction01/signature-cmp.txt
2026-09-13 22:33:31  ../../correction01/signature-extraction.txt
2026-09-13 22:38:33  ../../correction01/correction02/REPORT.md
2026-09-13 22:38:15  ../../correction01/correction02/parent-immutability.txt
2026-09-13 22:38:02  ../../correction01/correction02/range-diff-left-side-commits.txt
2026-09-13 22:38:02  ../../correction01/correction02/range-diff-right-side-commits.txt
2026-09-13 22:37:58  ../../correction01/correction02/range-diff-terminology.txt
```

No prior-evidence file has an mtime within the CORRECTION03 window.
Every prior file is untouched.

## Acceptance contract

| ID  | Criterion                                                                | Status |
|-----|--------------------------------------------------------------------------|--------|
| Y01 | CORRECTION02 residue-field inconsistency explicitly identified           | PASS (this REPORT's "Why this exists") |
| Y02 | historical proof gap explicitly classified as irreversible               | PASS (`HISTORICAL_PARENT_IMMUTABILITY_REASON=NO_PRE_CORRECTION_CONTENT_ANCHOR`) |
| Y03 | no retrospective evidence fabricated                                     | PASS (no new parent ACT file written; no earlier-time claim made) |
| Y04 | CORRECTION01 forward hash anchor rechecked                               | PASS (`parent-files-current-hashes.recheck.txt`) |
| Y05 | current parent hashes equal forward anchor                               | PASS (cmp_exit=0 on sorted-hash set; SHA-256 54673a57...) |
| Y06 | forward immutability claim scoped only from anchor onward                | PASS (this REPORT explicitly scopes the claim) |
| Y07 | historical immutability remains observational                            | PASS (`HISTORICAL_PARENT_IMMUTABILITY_MECHANICALLY_PROVEN=false`) |
| Y08 | all repository SHAs remain unchanged                                     | PASS (entry identity above) |
| Y09 | no prior evidence artifact modified                                      | PASS (mtime table above) |
| Y10 | REMAINING_RESIDUE=NONE                                                    | PASS (`REMAINING_RESIDUE=NONE` declared in VERDICT block) |

## Final principle applied

An unknowable historical fact does not remain an open engineering
task forever.

The missing pre-CORRECTION01 content anchor is now explicitly
classified as unrecoverable, bounded, and irrelevant to the already-
proven operational result (RESYNC_OPERATION = PASS, with all
in-chain facts mechanically re-verified and forward immutability
proven). The residue is closed by **truthful limitation**, not by
pretending stronger evidence exists.

## Files added by CORRECTION03

```
evidence/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01/correction01/correction02/correction03/
  REPORT.md                                  (this file)
  parent-files-current-hashes.recheck.txt    (18 SHA-256, recomputed now)
  parent-files-hashes-sorted-from-anchor.txt (sorted hash set from CORRECTION01 anchor)
  parent-files-hashes-sorted-now.txt         (sorted hash set, recomputed now)
  forward-anchor-cmp.txt                     (cmp -s exit code on sorted hash sets)
  forward-anchor-set-digest.txt              (SHA-256 of both sorted-hash files; identical)
  correction01-files-current-hashes.txt      (11 SHA-256, first anchor for CORRECTION01 set)
  correction02-files-current-hashes.txt      (5 SHA-256, first anchor for CORRECTION02 set)
```

No prior-evidence artifact was modified. No repository history was
rewritten. No product code was touched. No retrospective evidence
was fabricated.



