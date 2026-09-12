# ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION03

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION03
ACT-Phase: RED

Inherits from: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION02
(closed PASS at 4a7205f — its own closure truth contained
a defect the act was correcting).

**Class:** EVIDENCE / CLOSURE-MECHANICS CORRECTION
(of CORRECTION02, of CORRECTION01)

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION02`
(closed PASS at 4a7205f — but the CLOSE verdict was premature;
CORRECTION02 IMPL introduced the same EOF blank-line defect
the act was correcting).

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Language-change authorization:** NONE

**New tooling:** NONE

**Non-blocking:** NO. C5 ScanIdent remains BLOCKED on this
correction closing PASS because CORRECTION02's CLOSE trailer
declared PASS while AC05 (CORRECTION02 range diff-check) had
not been verified before CLOSE.

---

## Mission

Repair CORRECTION02's own IMPL-introduced defect without
amending any commit past APPEND_ONLY_START_POINT:

1. Strip the trailing blank line at EOF from the CORRECTION02
   ACT document (line 294: `\n\n` → `\n`).
2. Acknowledge that the CORRECTION02 CLOSE commit (4a7205f)
   declared PASS prematurely; the verdict in that historical
   commit is preserved as F14 evidence, and a corrected
   verdict is recorded in this ACT's CLOSE trailer.
3. Reaffirm the C4 / CORRECTION01 / CORRECTION02 closure
   truths in c4-correction03/closure-truth.txt.
4. Add NO production code; NO source mutation; NO mutation
   of c4/, c4-correction01/, c4-correction02/, or the
   CORRECTION01 ACT document (F14 immutability).
5. The CORRECTION02 ACT document is mutable ONLY because
   it has not yet been published (no push has occurred);
   its IMPL commit (`b6e58b9`) and CLOSE commit (`4a7205f`)
   remain immutable per F14 — the file content change is
   recorded in a new CORRECTION03 IMPL commit on top.

---

## Scope

### allowed

- Adding this CORRECTION03 ACT document.
- Adding the c4-correction03/ evidence packet.
- Editing the CORRECTION02 ACT document to strip the EOF
  blank line (this is a content change in the WORKING
  TREE; the historical CORRECTION02 IMPL commit retains
  the bugged file in its snapshot — F14 is preserved
  because the CORRECTION02 IMPL commit itself is not
  amended).
- Committing one IMPL commit with the corrected
  CORRECTION02 ACT doc + c4-correction03/ evidence, plus
  a CLOSE trailer commit.

### forbidden

- Modifying any production source under `src/`.
- Modifying any LLVM backend file.
- Modifying any c3.*, c4/, c4-correction01/, or
  c4-correction02/* file.
- Modifying the CORRECTION01 ACT document.
- `git commit --amend`, `git rebase`, `git reset`, or any
  other history-rewriting operation on commits at or
  after APPEND_ONLY_START_POINT.
- Modifying `scripts/`, `.githooks/`, `Makefile`,
  `package.json`, `AGENTS.md`, or any Factory doctrine doc.
- Touching C5, C6, or BOOTSTRAP01 scope.
- Carrying `ACT-Supersedes:` on any commit other than the
  CORRECTION03 CLOSE commit.

---

## Principal RED

```text
R-RED-1  CORRECTION02 IMPL introduced the same EOF blank-
         line defect the act was correcting (line 294 of
         the CORRECTION02 ACT doc has trailing `\n\n`).
         `git diff --check 9b44ab4 HEAD` exits 2 with:
           docs/acts/.../C4-CORRECTION02.md:294:
             new blank line at EOF.
         (TRUE at entry; mechanical, not semantic.)

R-RED-2  CORRECTION02 CLOSE commit (4a7205f) declared
         `ACT-Verdict: PASS` without first verifying AC05
         (CORRECTION02 range diff-check). The CLOSE
         trailer's PASS verdict is therefore premature.
         The CLOSE commit itself is F14-immutable; the
         corrected verdict is recorded in CORRECTION03.
         (TRUE at entry; documentation defect.)

R-RED-3  CORRECTION02 IMPL did not run `git diff --check
         9b44ab4 HEAD` before declaring PASS in CLOSE. The
         gate-fast diff-check line PASS at CORRECTION02
         CLOSE only verified a fresh-staged diff, not the
         CORRECTION02 RANGE diff. Range diff-check failed.
         (TRUE at entry; process defect.)

R-RED-4  C4 PHI production implementation remains GREEN.
         6/6 real-hcc witnesses pass; all 7 conservation
         gates pass; both prior range-checks pass.
         (TRUE at entry and remains TRUE.)

R-RED-5  F14 baseline: c4/, c4-correction01/,
         c4-correction02/, and the CORRECTION01 ACT
         document are immutable across CORRECTION03. The
         CORRECTION02 EOF defect (R-RED-1) and the
         CORRECTION02 CLOSE premature-verdict (R-RED-2)
         are F14-historical evidence, NOT modified.
         (TRUE at entry and remains TRUE.)
```

RED is GREEN only when R-RED-1 is mechanically repaired
(EOF blank line stripped from CORRECTION02 ACT doc tree),
R-RED-2 is acknowledged in CORRECTION03's evidence
packet, and the CORRECTION03 IMPL range carries its own
diff-check PASS.

---

## Acceptance criteria

```text
AC01  CORRECTION02 range diff-check exit status recorded.
      Command: git diff --check 9b44ab4 4a7205f
      Expected: exit 2; 1 diagnostic at line 294 of the
      CORRECTION02 ACT document (blank line at EOF).

AC02  CORRECTION03 EOF repair verified.
      Command: tail -c 5 docs/acts/.../C4-CORRECTION02.md \
                  | od -c | tail -1
      Expected: single trailing '\n', no extra blank line.

AC03  CORRECTION03 range diff-check is clean.
      Command: git diff --check 4a7205f HEAD
      Expected: exit 0.

AC04  CORRECTION03 introduced no production-code change.
      Command: git diff --numstat 4a7205f..HEAD -- src/ \
                  tests/ scripts/ .githooks/ .clinerules/ \
                  Makefile package.json
      Expected: empty.

AC05  c4/, c4-correction01/, c4-correction02/, and the
      CORRECTION01 ACT document untouched across
      CORRECTION03 (F14 immutability).
      Commands:
        git diff --name-only 4a7205f..HEAD \
          | grep -E '^evidence/.*/(c4|c4-correction01|c4-correction02)/'
        git diff --name-only 4a7205f..HEAD \
          | grep 'C4-CORRECTION01\.md'
      Expected: empty in both.

AC06  CORRECTION02 IMPL and CLOSE commits are not amended.
      Command: git log --format='%H %s' 4a7205f..HEAD
               | grep -E '(IMPL|CLOSE).*C4-CORRECTION02'
      Expected: empty (no commit rewrites CORRECTION02;
      the EOF fix lands as a CORRECTION03 file edit, not
      as an amend).

AC07  Only CORRECTION02 ACT doc (corrected EOF) and
      c4-correction03 evidence files changed across the
      CORRECTION03 range.
      Command: git diff --name-only 4a7205f..HEAD
      Expected:
          docs/acts/.../C4-CORRECTION02.md   (corrected EOF)
          docs/acts/.../C4-CORRECTION03.md
          evidence/.../c4-correction03/<files>

AC08  factory-v2-range-check PASS for CORRECTION03.
      Command: bash scripts/quality/factory-v2-range-check.sh \
                  ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION03 HEAD
      Expected: STATUS=PASS.

AC09  All 7 conservation gates PASS at CORRECTION03 CLOSE.
      Expected: factory-append-only 11/0, shell-loc PASS,
      gate-fast PASS, llvm-gep01 30/0, llvm-byte-memory01
      37/0, llvm-intops01 4/0, ir-return-slot-forwarding01
      6/0.

AC10  Reaffirmation of closure truths in
      c4-correction03/closure-truth.txt with corrected
      verdict chain:
        C4_COMPILER_SEMANTICS         = PASS
        C4_REAL_HCC_WITNESSES         = PASS (6/6)
        LLVM_AS                       = PASS (6/6)
        LLVM_OPT_VERIFY               = PASS (6/6)
        CONSERVATION_COUNTS           = PASS
        C4_HISTORICAL_DIFF_CHECK      = FAIL_WITH_CLASSIFIED_EVIDENCE_MARKERS
        CORRECTION01_DIFF_CHECK       = FAIL_WITH_CLASSIFIED_EOF_DEFECT
        CORRECTION02_DIFF_CHECK       = FAIL_WITH_CLASSIFIED_EOF_DEFECT
                                        (defect propagated to CORRECTION02;
                                         repaired in CORRECTION03 file tree,
                                         preserved in CORRECTION02 IMPL snapshot)
        CORRECTION03_DIFF_CHECK       = PASS
        P0_PRODUCTION                 = none
        F14                           = preserved
        C5_SCANIDENT_UNLOCK           = YES
```

---

## HALT conditions

- `HALT_RED_NOT_REPRODUCED`
- `HALT_SCOPE_EXPANSION_REQUIRED`
- `HALT_GIT_IDENTITY_LOST`
- `HALT_F14_BREACH` (any mutation of c4/, c4-correction01/,
  c4-correction02/, or the CORRECTION01 ACT document;
  any amend/rebase/reset of commits past the boundary)

---

## Residue

```text
P2  A future ACT template MUST add a step between IMPL and
    CLOSE that explicitly runs `git diff --check <ENTRY>
    <HEAD>` (range diff-check, not just staged diff-check).
    The CORRECTION02 defect class was: staging diff-check
    passed (no new files in stage added whitespace), but
    the committed range diff-check failed because the
    file's trailing-newline shape differed from baseline.
    Out of scope here.

P2  A future ACT template SHOULD enforce "no trailing
    blank line at EOF" on ACT documents, e.g. via a
    shell-guard or editorconfig rule. Out of scope here.
```

---

## Commit topology

```text
1. RED   (empty commit; captures R-RED-1..R-RED-5)
2. IMPL  (corrects CORRECTION02 ACT doc EOF + adds
          c4-correction03/ evidence)
3. CLOSE (empty trailer commit; ACT-Verdict=PASS;
          ACT-Supersedes on CORRECTION02 ACT)
```

Three commits. Bounded. Evidence-only.

---

## Execution metadata

```text
ACT:           ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION03
ACT-Phase:     RED | IMPL | CLOSE
ACT-Verdict:   PASS | HALT_<...>   (CLOSE only)
ACT-Supersedes: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION02
                                                   (CLOSE only)
```

---

## Closure handoff

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION03 HEAD
```

After CORRECTION03 closes PASS, C5 ScanIdent integrated
evidence becomes unlocked per the predecessor ACT §10
topology.
