# ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION02
ACT-Phase: RED

Inherits from: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01
(closed PASS at 9b44ab4 — its closure mechanics now known
to have three defects; the compiler truth and the historical
C4/CORRECTION01 evidence remain authoritative).

**Class:** EVIDENCE / CLOSURE-MECHANICS CORRECTION

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01`
(closed PASS at 9b44ab4; three closure-mechanics defects
identified by review).

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Language-change authorization:** NONE

**New tooling:** NONE

**Non-blocking:** NO. C5 ScanIdent remains BLOCKED on this
correction closing PASS because CORRECTION01's own
`NEW_CORRECTION_DIFF_CHECK = PASS` verdict is false and
its AC05 mechanical command is impossible.

---

## Mission

Reconcile the CORRECTION01 closure mechanics under F14:

1. Record the three reviewer-identified defects in
   CORRECTION01's own closure contract.
2. Establish the correct predecessor-CLOSE .. CORRECTION01-
   CLOSE invariant (zero source delta under that range).
3. Reaffirm that the LLVM compiler implementation itself
   is GREEN: 6/6 real-hcc witnesses pass, all 7 conservation
   gates pass, both factory-v2-range-check chains pass.
4. Add NO production code, NO source-code changes, NO
   CORRECTION01 evidence mutations, NO mutation of the
   CORRECTION01 ACT document (F14 immutability).

---

## Scope

### allowed

- Adding this CORRECTION02 ACT document.
- Adding the c4-correction02/ evidence packet.
- Committing one IMPL commit with the ACT document + the
  evidence files, plus a CLOSE trailer commit.
- Running conservation gates; recording their output.

### forbidden

- Modifying any production source under `src/`.
- Modifying any LLVM backend file.
- Modifying any c3.*, c4/, or c4-correction01/* evidence file.
- Modifying the CORRECTION01 ACT document
  (`docs/acts/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01.md`).
- Modifying `scripts/`, `.githooks/`, `Makefile`,
  `package.json`, `AGENTS.md`, or any Factory doctrine doc.
- Touching C5, C6, or BOOTSTRAP01 scope.
- Carrying `ACT-Supersedes:` on any commit other than the
  CORRECTION02 CLOSE commit.

---

## Principal RED

```text
R-RED-1  CORRECTION01 ACT document ends with a trailing
         blank line at line 291.
         `git diff --check de31f88 HEAD` exits 2 with:
           docs/acts/.../C4-CORRECTION01.md:291:
             new blank line at EOF.
         Therefore the CORRECTION01 closure-truth line
           NEW_CORRECTION_DIFF_CHECK = PASS
         is FALSE for the CORRECTION01 actual range.
         (TRUE at entry; mechanical, not semantic.)

R-RED-2  CORRECTION01 AC05 mechanical command is impossible.
         AC05 says:
           git diff --numstat 6ef6e11..HEAD -- src/ ...
           Expected: empty.
         but 6ef6e11..HEAD contains the C4 production
         implementation (src/llvm-backend.c +670/-17,
         src/llvm-backend-cap.c +12/-1, src/llvm-backend.h
         +21/-0). The correct invariant is:
           git diff --numstat de31f88..9b44ab4 -- src/ ...
           Expected: empty.
         (TRUE at entry; documentation defect.)

R-RED-3  CORRECTION01 AC07 scope / AC declares "one ACT
         document + four evidence files", but the actual
         CORRECTION01 packet contains five evidence files:
           closure-truth.txt
           conservation-counts.txt
           diff-check-classification.txt
           fixture-fact.txt
           gates-fresh.txt
         plus the ACT document = six changed files.
         (TRUE at entry; documentation defect.)

R-RED-4  The C4 PHI production implementation is GREEN.
         Six real-hcc witnesses pass hcc + llvm-as + opt
         --passes=verify; all 7 conservation gates pass;
         both factory-v2-range-check chains (C4 and
         CORRECTION01) pass.
         (TRUE at entry and remains TRUE; this ACT does
         not touch production code.)

R-RED-5  F14 preservation: c4/, c4-correction01/, and the
         CORRECTION01 ACT document are immutable across
         CORRECTION02. The CORRECTION01 EOF defect
         (R-RED-1) is recorded as historical evidence,
         not repaired.
         (TRUE at entry and remains TRUE.)
```

RED is GREEN only when R-RED-1..3 are documented and
classified in the c4-correction02/ evidence packet and
when the CORRECTION02 IMPL range carries its own
diff-check PASS.

---

## Acceptance criteria

```text
AC01  CORRECTION01 range diff-check exit status recorded.
      Command: git diff --check de31f88 9b44ab4
      Expected: exit 2; 1 diagnostic at line 291 of the
      CORRECTION01 ACT document (blank line at EOF).

AC02  CORRECTION01 AC05 wrong-range invariant reproduced.
      Command: git diff --numstat 6ef6e11..9b44ab4 -- src/
               tests/ scripts/ .githooks/ .clinerules/
               Makefile package.json
      Expected: non-empty (C4 production diff is visible);
      confirms AC05's command is impossible.

AC03  CORRECTION01 correct-range invariant established.
      Command: git diff --numstat de31f88..9b44ab4 -- src/
               tests/ scripts/ .githooks/ .clinerules/
               Makefile package.json
      Expected: empty (CORRECTION01 introduced no source).

AC04  CORRECTION01 packet cardinality established.
      Command: git diff --name-only de31f88..9b44ab4
      Expected: 6 files (1 ACT doc + 5 evidence files).

AC05  CORRECTION02 range diff-check is clean.
      Command: git diff --check 9b44ab4 HEAD
      Expected: exit 0.

AC06  CORRECTION02 introduced no production-code change.
      Command: git diff --numstat 9b44ab4..HEAD -- src/
               tests/ scripts/ .githooks/ .clinerules/
               Makefile package.json
      Expected: empty.

AC07  c4/, c4-correction01/, and CORRECTION01 ACT document
      untouched across CORRECTION02 (F14 immutability).
      Command: git diff --name-only 9b44ab4..HEAD | \
                 grep -E '^evidence/.*/(c4|c4-correction01)/'
      Expected: empty.
      And:
      Command: git diff --name-only 9b44ab4..HEAD | \
                 grep 'C4-CORRECTION01\.md'
      Expected: empty.

AC08  Only this CORRECTION02 ACT document and the
      c4-correction02 evidence files changed across the
      CORRECTION02 range.
      Command: git diff --name-only 9b44ab4..HEAD
      Expected:
          docs/acts/.../C4-CORRECTION02.md
          evidence/.../c4-correction02/<files>

AC09  factory-v2-range-check PASS for CORRECTION02.
      Command: bash scripts/quality/factory-v2-range-check.sh \
                  ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION02 HEAD
      Expected: STATUS=PASS.

AC10  All 7 conservation gates PASS at CORRECTION02 CLOSE.
      Commands: factory-append-only-test,
                shell-loc-gate, gate-fast, llvm-gep01,
                llvm-byte-memory01, llvm-intops01,
                ir-return-slot-forwarding01.
      Expected: all STATUS=PASS.

AC11  Reaffirmation of C4 / CORRECTION01 truths in
      c4-correction02/closure-truth.txt:
        C4_COMPILER_SEMANTICS = PASS
        C4_REAL_HCC_WITNESSES = PASS (6/6)
        LLVM_AS = PASS (6/6)
        LLVM_OPT_VERIFY = PASS (6/6)
        CONSERVATION_COUNTS = PASS
        C4_HISTORICAL_DIFF_CHECK = FAIL_WITH_CLASSIFIED_EVIDENCE_MARKERS
        P0_PRODUCTION = none
        CORRECTION01_DIFF_CHECK = FAIL_WITH_CLASSIFIED_EOF_DEFECT
                                   (1 blank line at EOF on
                                   the CORRECTION01 ACT doc;
                                   F14 historical, not repaired)
        CORRECTION02_DIFF_CHECK = PASS
        C5_SCANIDENT_UNLOCK = YES
```

---

## HALT conditions

- `HALT_RED_NOT_REPRODUCED`
- `HALT_SCOPE_EXPANSION_REQUIRED`
- `HALT_GIT_IDENTITY_LOST`
- `HALT_F14_BREACH` (any mutation of c4/, c4-correction01/,
  or the CORRECTION01 ACT document)

---

## Residue

```text
P2  A future ACT template could require:
    - no trailing blank line at EOF on ACT documents
    - "cardinality = ACT + N evidence files" to be stated
      with a number, not a figure
    - "expected range" base to be the predecessor CLOSE
      explicitly, not HEAD-relative
    These improvements would mechanically eliminate the
    class of CORRECTION01 defects. Out of scope here.

P2  The CORRECTION01 EOF blank line (line 291) is preserved
    as F14 historical evidence; it is classified, not
    repaired. A future correction cycle could rewrite the
    CORRECTION01 ACT document IF AND ONLY IF that rewrite
    is itself authorized as a new correction ACT (the
    closure-mechanics contract forbids silently amending
    historical ACT documents).
```

---

## Commit topology

```text
1. RED   (empty commit; captures R-RED-1..R-RED-5)
2. IMPL  (adds this ACT doc + c4-correction02/ evidence)
3. CLOSE (empty trailer commit; ACT-Verdict=PASS;
          ACT-Supersedes on the CORRECTION01 ACT)
```

Three commits. Bounded. Evidence-only.

---

## Execution metadata

```text
ACT:           ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION02
ACT-Phase:     RED | IMPL | CLOSE
ACT-Verdict:   PASS | HALT_<...>   (CLOSE only)
ACT-Supersedes: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01
                                                   (CLOSE only)
```

---

## Closure handoff

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION02 HEAD
```

After CORRECTION02 closes PASS, C5 ScanIdent integrated
evidence becomes unlocked per the predecessor ACT §10
topology.

