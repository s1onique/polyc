# ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01-CORRECTION01 — Closure Report

## VERDICT

```
VERDICT=PASS
RESYNC_OPERATION_VERDICT=PASS
PARENT_EVIDENCE_VERDICT=PASS_WITH_EVIDENCE_QUALIFICATION

D1_CLASSIFICATION=EVIDENCE_CAPTURE_ORDERING (F3_OPERATIONAL_CLAIM=PLAUSIBLE_BUT_NOT_PROVEN_BY_RETAINED_PRE_ACT_STATUS)
D2_CLASSIFICATION=RAW_LOGS_NOT_BYTE_EQUAL;_SIGNATURES_BYTE_EQUAL

RAW_GATE_LOGS_EQUAL=false
FAILURE_SIGNATURES_EQUAL=true
GEP01_PASS_HARNESS=26
GEP01_FAIL_HARNESS=4
GEP01_PASS_MAIN=26
GEP01_FAIL_MAIN=4

A2_RECLASSIFICATION=PASS_WITH_EVIDENCE_QUALIFICATION
A12_RECLASSIFICATION=PASS_WITH_EVIDENCE_QUALIFICATION

MAIN_EQUALS_ORIGIN=true
BACKUP_EQUALS_OLD_HEAD=true
UPSTREAM_ANCESTOR_OF_HARNESS=true
RANGE_DIFF_STILL_ACCOUNTED=true
PARENT_EVIDENCE_MUTATED=false
HISTORY_REWRITTEN=false
```

## Defects addressed

### D1 — Pre-ACT clean-worktree evidence overclaim

The parent captured `git status --short` AFTER `mkdir -p evidence/...`,
which is why the retained `pre-ACT-status.txt` reads:

```
?? evidence/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01/
```

This is the parent ACT's own evidence directory; it is consistent with
the parent's first `git status --short` having been empty before that
mkdir, but the captured artifact itself does NOT mechanically establish
that earlier empty observation.

**Truthful classification**: `EVIDENCE_CAPTURE_ORDERING`. The parent's
operational claim ("worktree was clean before history mutation") is
**PLAUSIBLE_BUT_NOT_PROVEN_BY_RETAINED_PRE_ACT_STATUS**. It is not
fabricated, and the observed untracked path is the ACT's own evidence
directory — not an unrelated user file. But the strongest claim that
can be cited from the retained evidence is weaker than what the
parent stated.

No fake empty status was written.

### D2 — Raw-log byte-equality claim is false

The two raw gate logs are NOT byte-for-byte equal:

```
cmp -s ../gate-push-harness.txt ../gate-push-main.txt
  -> exit 1
SHA-256 harness = b8e05bfa88cf94aa95154f349a1b40ca7f20f62e2b9bdcf8a17d95832d195b64
SHA-256 main    = 7cee64fed6e2e05cdfe648b9f1d7020d80af14f8791d7daf3c6816bdef9d36ad
```

They differ in:

* `SUBJECT=` SHA prefix (`12e4e7a` vs `7d7b983`).
* Sandbox tmpdir names (`cline*-polyc-gate.fgDaAX` vs `cline*-polyc-gate.w27blm`).
* `xcrun_db-XXXXXX` cache file names.
* Build progress percentages.
* Compile timings (`-- Configuring done (0.7s)` vs `(1.0s)`).
* Source-line path prefixes embedded in compiler warnings.

**Corrected claim**: the deterministic **GEP01 failure signatures** ARE
byte-for-byte equal. A signature extraction procedure
(`extract-signature.sh`) produces, from each raw log, a normalized text
file containing only semantically relevant fields (see
`signature-extraction.txt`). Applying it:

```
sh extract-signature.sh ../gate-push-harness.txt gate-push-harness.signature.txt
sh extract-signature.sh ../gate-push-main.txt    gate-push-main.signature.txt
cmp -s gate-push-harness.signature.txt gate-push-main.signature.txt
  -> exit 0
```

Both signatures contain exactly:

```
GEP01_PASS=26
GEP01_FAIL=4
STATUS=FAIL
CHECK=gep01 STATUS=FAIL
REASON=gep01 exited with status 2
VERDICT=FAIL
```

with 26 `PASS  ` lines and 4 `FAIL  ` lines, the four FAIL classes being
identical across both runs:

1. `readat.HC: SHAPE_DEPENDENT counter = ? (expected >= 1): shape_dependent marker not found in stderr`
2. `IR_GEP = REJECTED (sibling opcode still rejected): could not read cap verifier output`
3. `IR_LEA = REJECTED (sibling opcode still rejected): could not read cap verifier output`
4. `IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset): could not read cap verifier output`

## Resync safety revalidation

Re-executed from the current tree without any history rewrite:

| Invariant                                                          | Result                |
|--------------------------------------------------------------------|-----------------------|
| `main == origin/main`                                              | TRUE (`7d7b983`)      |
| backup branch == OLD_HEAD                                          | TRUE (`1f8250b`)      |
| `origin/main` ancestor of `harness/codium-polyc2`                  | TRUE                  |
| 9 rebased harness commits remain past `origin/main`                | TRUE (count = 9)      |
| range-diff accounting still valid (1–6 byte-equal, 7–9 ROADMAP drift) | TRUE               |
| Remote URLs unchanged                                              | TRUE                  |
| Local `pull.ff=only` and `pull.rebase=false` preserved             | TRUE                  |
| Final checkout on `harness/codium-polyc2`                          | TRUE                  |
| Backup branch still present                                        | TRUE                  |
| Parent evidence directory untouched (19 files)                     | TRUE (forward hashes in `parent-files-current-hashes.txt`) |

See `current-ref-verification.txt` for the raw commands and outputs.

## Acceptance item reclassification (A2, A12)

* **A2_RECLASSIFICATION = PASS_WITH_EVIDENCE_QUALIFICATION**
  (Parent claim is plausible; the retained artifact proves it only weakly.
   Operational safety was unaffected.)

* **A12_RECLASSIFICATION = PASS_WITH_EVIDENCE_QUALIFICATION**
  (Same logical conclusion; the supporting claim is now stated as
   **failure-signature equality**, the strongest level mechanically
   demonstrable from the retained logs.)

All other parent acceptance items (A1, A3–A11, A13–A16) are mechanically
re-proven from the current tree and reclassified `PASS_MECHANICALLY_PROVEN`
in `acceptance-reclassification.txt`.

## Hard invariant compliance

| Invariant                                                     | Compliance |
|---------------------------------------------------------------|------------|
| C1 closed parent evidence is immutable                        | PASS — 19 parent files hashed in `parent-files-current-hashes.txt`; no edits performed. |
| C2 no history rewrite                                         | PASS — no `git rebase`, `git reset`, `git push`, `git replace`, or ref-deletion during this correction. The branch graph is exactly as the parent left it. |
| C3 no product change                                          | PASS — no source file under `src/`, `scripts/quality/`, `tools/`, `Makefile`, or `CMakeLists.txt` was edited. `extract-signature.sh` lives only inside the correction01 evidence directory. |
| C4 no retroactive fabrication                                 | PASS — no fake empty `git status` was written; `pre-ACT-status.txt` left as-is. |
| C5 claim strength matches evidence                            | PASS — the strongest mechanically demonstrated claim is now used (signature equality). |

## Acceptance contract checklist

| ID  | Criterion                                                                            | Status |
|-----|--------------------------------------------------------------------------------------|--------|
| C01 | parent evidence unchanged                                                            | PASS (`parent-files-current-hashes.txt`) |
| C02 | raw gate logs proven non-byte-equal                                                  | PASS (`original-log-hashes.txt`, `raw-log-cmp.txt` exit=1) |
| C03 | semantic failure signatures extracted deterministically                              | PASS (`extract-signature.sh`, `signature-extraction.txt`) |
| C04 | semantic failure signatures byte-equal                                                | PASS (`signature-cmp.txt` exit=0) |
| C05 | identical 26/4 GEP01 result mechanically confirmed                                   | PASS (both signatures contain `GEP01_PASS=26`, `GEP01_FAIL=4`, `STATUS=FAIL`) |
| C06 | same four logical failure classes mechanically confirmed                             | PASS (4 distinct `FAIL  ` lines in each signature, identical text) |
| C07 | D1 honestly classified as historical evidence-capture defect                         | PASS (`acceptance-reclassification.txt`) |
| C08 | no retrospective clean-worktree evidence fabricated                                  | PASS (no fake status written; parent `pre-ACT-status.txt` unchanged) |
| C09 | main still equals origin/main                                                        | PASS (`current-ref-verification.txt`) |
| C10 | backup still points exactly to OLD_HEAD                                              | PASS (`current-ref-verification.txt`) |
| C11 | origin/main remains ancestor of harness                                              | PASS (`current-ref-verification.txt`) |
| C12 | original 9-change range-diff preservation conclusion remains valid                   | PASS (range-diff re-executed; 6 byte-equal `=`, 3 content-equivalent `!`) |
| C13 | A2/A12 explicitly reclassified                                                       | PASS (`acceptance-reclassification.txt`) |
| C14 | no closed parent evidence mutated                                                    | PASS (no edits to `../` files) |
| C15 | no repository history rewritten                                                      | PASS (no `git rebase`/`reset`/`push` invoked; HEAD unchanged) |
| C16 | no product code changed                                                              | PASS (no edits under `src/`, `scripts/quality/`, `tools/`, `Makefile`) |

## Files in this evidence packet

```
evidence/ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01/correction01/
  REPORT.md                       (this file)
  extract-signature.sh            (deterministic GEP01 signature extractor)
  signature-extraction.txt        (procedure transcript and invariants)
  original-log-hashes.txt         (SHA-256 of the two raw gate logs)
  raw-log-cmp.txt                 (cmp exit code on raw logs)
  gate-push-harness.signature.txt (extracted semantic signature, harness run)
  gate-push-main.signature.txt    (extracted semantic signature, main run)
  signature-cmp.txt               (cmp exit code on extracted signatures)
  current-ref-verification.txt    (live revalidation of all resync invariants)
  acceptance-reclassification.txt (A2/A12 and other items reclassified)
  parent-files-current-hashes.txt (SHA-256 of every parent evidence file)
```

## Residue (out of scope per CORRECTION01 §Out of scope)

None — this is an evidence/truthfulness correction only. No code, no
docs, no other ACT are in scope.



