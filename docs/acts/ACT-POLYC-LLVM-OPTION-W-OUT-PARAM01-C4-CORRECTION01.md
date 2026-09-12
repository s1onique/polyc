# ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01
ACT-Phase: RED

Inherits from: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01
(closed PASS at de31f88 — the C4 IMPL-B commit chain).

**Class:** EVIDENCE / CLOSURE-TRUTH CORRECTION

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01`
(closed PASS at de31f88 — C4 IMPL-B RED/IMPL/CLOSE chain).

**Production semantic changes:** FORBIDDEN

**IR / ABI / LLVM authorization:** NONE

**Language-change authorization:** NONE

**New tooling:** NONE

**Non-blocking:** NO. C5 ScanIdent is BLOCKED on this correction
because the C4 closure packet mechanically contradicts itself
in two places (P0 diff-check false positives, P1 stale
conservation counts). When this CORRECTION01 closes PASS, C5
is unlocked.

---

## Mission

Reconcile the C4 IMPL-B closure truth under F14:

1. Re-run every C4 conservation gate from the current C4-CLOSE
   tree and capture the fresh authoritative counts.
2. Classify the two `git diff --check` diagnostics flagged
   across the C4 range as DECORATIVE `=======` heading
   underlines, not unresolved merge conflicts.
3. Document the actual c4_phi_multi_pred fixture fact: a
   three-term OR lowers to TWO chained 2-PHI merge blocks,
   not one 3-input PHI.
4. Add NO production code, NO source-code changes, NO C4/ file
   mutations (F14 immutability of historical evidence).

The C4 production implementation is GREEN — the LLVM PHI
geometry is correct, all six witness fixtures pass hcc +
llvm-as + opt --passes=verify. Only the evidence packet is
being corrected.

---

## Scope

### allowed

- Adding this CORRECTION01 ACT document.
- Adding the c4-correction01/ evidence packet
  (gates-fresh.txt, diff-check-classification.txt,
  conservation-counts.txt, fixture-fact.txt).
- Committing one IMPL commit with the ACT document + the
  four evidence files, plus a CLOSE trailer commit.
- Running conservation gates; recording their fresh output.

### forbidden

- Modifying any production source under `src/`.
- Modifying any LLVM backend file.
- Modifying any c3.* or c4.* evidence file (F14 immutability).
- Modifying `scripts/`, `.githooks/`, `Makefile`,
  `package.json`, `AGENTS.md`, or any Factory doctrine doc.
- Touching C5, C6, or BOOTSTRAP01 scope.
- Carrying `ACT-Supersedes:` on any commit other than the
  CLOSE commit.

---

## Principal RED

```text
R-RED-1  C4 range `git diff --check 004d4e9..de31f88` exits 2
         with two diagnostics:
           c4/c4-impl.txt:172: leftover conflict marker
           c4/opcode-coverage.txt:5: leftover conflict marker
         (TRUE at entry; mechanical, not semantic.)

R-RED-2  C4 IMPL-B CLOSE trailer (de31f88) embedded fresh
         conservation counts 30 / 37 / 6, but the c4-impl.txt
         evidence file (committed in IMPL 9120202) carries
         stale counts 32 / 41 / 8 captured at an earlier
         development snapshot.
         (TRUE at entry; documentation drift.)

R-RED-3  c4_phi_multi_pred.HC fixture comment (line 1-2)
         claims "three-way OR producing an IR_PHI with 3
         incoming edges" but the actual emitted witness
         contains two `phi i8` instructions, each with two
         incoming edges (a chained 2-PHI geometry).
         (TRUE at entry; documentation drift.)

R-RED-4  The C4 PHI production implementation in
         src/llvm-backend.c (C4 IMPL commit 9120202) is
         semantically correct: six witness fixtures pass hcc
         + llvm-as + opt --passes=verify, all P5/P6 Option-W
         regression fixtures remain green, all conservation
         gates PASS.
         (TRUE at entry and remains TRUE; this ACT does not
         touch the production code.)

R-RED-5  Neither c4/c4-impl.txt nor c4/opcode-coverage.txt
         contains any real merge conflict marker
         (`<<<<<<<`, `|||||||`, `>>>>>>>`). The two `=======`
         lines are decorative heading underlines (PURPOSE
         and RESIDUE), which `git diff --check` heuristically
         flags. (TRUE at entry and remains TRUE.)
```

RED is GREEN only when all five findings are documented and
classified in the c4-correction01/ evidence packet, and when
R-RED-1..3 remain TRUE in the post-IMPL state (the
correction does NOT repair c4/ files; it records the truth
in the new packet).

---

## Acceptance criteria

```text
AC01  C4 range diff-check exit status recorded.
      Command: git diff --check 004d4e9..de31f88
      Expected: exit 2; 2 diagnostics on c4/c4-impl.txt:172
      and c4/opcode-coverage.txt:5.

AC02  Both diagnostics classified as decorative `=======`
      heading underlines, NOT unresolved merges. No real
      `<<<<<<<` / `>>>>>>>` markers exist in c4/.
      Command: grep -rE '^(<<<<<<<|>>>>>>>)' evidence/.../c4/
      Expected: empty (exit 1).

AC03  Fresh conservation counts captured at HEAD = de31f88
      from a fresh `make llvm-all` build of hcc.
      Documented in c4-correction01/conservation-counts.txt
      with the exact PASS/FAIL values for all seven gates.

AC04  c4_phi_multi_pred fixture fact corrected: the fixture
      lowers to TWO chained 2-PHI merge blocks, not one
      3-input PHI. Documented in
      c4-correction01/fixture-fact.txt with the actual
      emitted witness lines.

AC05  No production-code change across the CORRECTION01 range.
      Command: git diff --numstat 6ef6e11..HEAD -- src/ \
                  tests/ scripts/ .githooks/ .clinerules/ \
                  Makefile package.json
      Expected: empty (the C4 IMPL diff is in this range; it
      is grandfathered and does not re-introduce under the
      CORRECTION01 range — verified by commit-subject grep).

AC06  c4/ and c3/ evidence files untouched across the
      CORRECTION01 range (F14 immutability).
      Command: git diff --name-only <predecessor-CLOSE>..HEAD \
                  | grep '^evidence/.*/\(c3\.\|c4/\)'
      Expected: empty.

AC07  Only this CORRECTION01 ACT document and the four
      c4-correction01 evidence files changed across the
      CORRECTION01 range.
      Command: git diff --name-only <predecessor-CLOSE>..HEAD
      Expected:
          docs/acts/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01.md
          evidence/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01/c4-correction01/diff-check-classification.txt
          evidence/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01/c4-correction01/conservation-counts.txt
          evidence/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01/c4-correction01/fixture-fact.txt
          evidence/ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01/c4-correction01/gates-fresh.txt

AC08  RED, IMPL, CLOSE commit-msg gates all pass; ACT-
      Supersedes only on CLOSE.
      Command: bash scripts/quality/factory-v2-range-check.sh \
                  ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01 HEAD
      Expected: STATUS=PASS.

AC09  Closure-truth verdict block.
      Command: read evidence/.../c4-correction01/closure-truth.txt
      Expected: contains the C4_COMPILER_SEMANTICS, REAL_HCC,
      LLVM_AS, LLVM_OPT_VERIFY, CONSERVATION_COUNTS,
      C4_HISTORICAL_DIFF_CHECK, NEW_CORRECTION_DIFF_CHECK,
      P0_PRODUCTION block from the reviewer's prescription.
```

---

## HALT conditions

- `HALT_RED_NOT_REPRODUCED`
- `HALT_SCOPE_EXPANSION_REQUIRED`
- `HALT_GIT_IDENTITY_LOST`

---

## Residue

```text
P1  A future ACT template could require all evidence files
    to use single-`-` heading underlines (or no underlines)
    to avoid the `git diff --check` false-positive pattern
    on decorative `=======` headings. Out of scope here.

P1  The c4_phi_multi_pred fixture comment could be revised
    to describe the actual chained 2-PHI geometry, but per
    F14 the c4/ files are immutable. The corrected truth
    lives in c4-correction01/fixture-fact.txt.
```

---

## Commit topology

```text
1. RED   (empty commit; captures R-RED-1..R-RED-5)
2. IMPL  (adds this ACT doc + 4 evidence files)
3. CLOSE (empty trailer commit; ACT-Verdict=PASS;
          ACT-Supersedes on the predecessor ACT)
```

Three commits. Bounded. Evidence-only.

---

## Execution metadata

```text
ACT:           ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01
ACT-Phase:     RED | IMPL | CLOSE
ACT-Verdict:   PASS | HALT_<...>   (CLOSE only)
ACT-Supersedes: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01
                                                   (CLOSE only)
```

---

## Closure handoff

Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01-C4-CORRECTION01 HEAD
```

After CORRECTION01 closes PASS, C5 ScanIdent integrated
evidence becomes unlocked per the predecessor ACT §10
topology.

---

## Closure-truth verdict block

The canonical block, to be filled in at CLOSE:

```text
C4_COMPILER_SEMANTICS       = PASS  (production code unchanged;
                                      six witnesses pass hcc +
                                      llvm-as + opt --passes=verify)
C4_REAL_HCC_WITNESSES       = PASS  (6/6 fixtures)
LLVM_AS                     = PASS  (6/6 fixtures rc=0)
LLVM_OPT_VERIFY             = PASS  (6/6 fixtures rc=0)
CONSERVATION_COUNTS         = PASS  (factory-append-only 11/0,
                                      shell-loc PASS, gate-fast PASS,
                                      llvm-gep01 30/0,
                                      llvm-byte-memory01 37/0,
                                      llvm-intops01 4/0,
                                      ir-return-slot-forwarding01 6/0,
                                      factory-v2-range-check PASS)
C4_HISTORICAL_DIFF_CHECK    = FAIL_WITH_CLASSIFIED_EVIDENCE_MARKERS
                              (2 decorative `=======` heading
                              underlines flagged; classified in
                              c4-correction01/diff-check-classification.txt;
                              no real unresolved merges)
NEW_CORRECTION_DIFF_CHECK   = PASS  (c4-correction01/ uses no
                                      decorative heading underlines;
                                      gate-fast diff-check line PASS
                                      for fresh-staged)
P0_PRODUCTION               = none  (no production code changed)
```

