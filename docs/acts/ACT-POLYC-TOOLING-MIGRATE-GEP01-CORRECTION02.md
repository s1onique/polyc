# ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02
ACT-Phase: RED
ACT-Phase-Notes: C1 RED is purely an evidence-phase
  correction ACT. There is no IMPL phase because
  PRODUCTION SEMANTIC CHANGES are FORBIDDEN (the harness
  is correct; only the closure-contract semantics need
  reconciliation). C2 CLOSE performs the closure-trail
  reconciliation: ACT-Supersedes +
  ACT-Corrected-Verdict reclassify the predecessor's
  closure to a truthful halt verdict, and the close
  evidence directory is populated.

**Title:** Reclassify CORRECTION01's AC07 outcome truthfully
and correct the predecessor's verdict without changing
production source.

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:**
- `ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01`
  (CLOSED PASS per its own trailer; PASS was incorrect
  on AC07 per the reviewer's analysis. Per F14 the
  predecessor's evidence tree at
  `evidence/.../correction01/` is NOT mutated by this ACT;
  this ACT only writes new evidence under
  `evidence/.../correction02/` and only carries
  ACT-Supersedes + ACT-Corrected-Verdict on its own
  CLOSE commit.)

**Class:** TOOLING / CLOSURE-CONTRACT-CORRECTION
(evidence / verdict-reconciliation; no production code change.)

**Primary production seam:** none.
**Test-harness changes to `tools/quality/llvm-gep01-test.HC`:** FORBIDDEN.
**Compiler semantic changes:** FORBIDDEN.
**Parser / typechecker changes:** FORBIDDEN.
**Neutral-IR changes:** FORBIDDEN.
**LLVM backend changes:** FORBIDDEN.
**ABI changes:** FORBIDDEN.
**Factory-doctrine changes:** FORBIDDEN.
**New Bash logic > 0 LOC:** FORBIDDEN.
**Historical evidence mutation (any c{1,2,3,4} file under
  `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/`, any
  file under `evidence/.../correction01/`):** FORBIDDEN.
**Reopening MIGRATE-GEP01 or MIGRATE-GEP01-CORRECTION01
  for general amendment:** FORBIDDEN.
**Opening SHELL-BUDGET01 or any new Track-B ACT:** FORBIDDEN.

---

# 0. Mission

`ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01` closed with
`ACT-Verdict: PASS` on its C3 commit, but the production
work is correct and complete. The closure-contract was
not satisfied as written.

Concretely, three things are wrong with the CORRECTION01
closure as it currently stands:

  (a) **AC07 not satisfied as written.** AC07 reads:

        > Conservation: make unit-test, make
        > jit-unit-test, make lsp-test (where applicable)
        > all PASS with counts unchanged from the c4
        > close-tree baseline.

      At the CORRECTION01 CLOSE tree, all three returned
      `rc=2`. The closure narrative reclassified them as
      `ENVIRONMENTALLY_UNAVAILABLE` by analogy with two
      DIFFERENT c4-baseline gates
      (`llvm-spike`, `harness-evidence-isolation-test`).
      That analogy is semantically wrong:

        - The c4 baseline NEVER measured
          `make unit-test` / `make jit-unit-test` /
          `make lsp-test` as conservation gates (the c4
          baseline ran `llvm-gep01-test`,
          `llvm-byte-memory01`, `llvm-intops01`,
          `ir-return-slot-fwd01`,
          `llvm-cap-table-verifier`,
          `shell-loc-gate`, `factory-append-only`,
          `llvm-spike`, `harness-evidence-isolation`).
        - The CORRECTION01 ACT did NOT define
          `ENVIRONMENTALLY_UNAVAILABLE` as an accepted
          result for AC07. Its HALT list says "if any
          conservation gate regresses" (which it did).
        - "Counts unchanged from c4 baseline" is
          undefined when the gates were not measured in
          the baseline.

      The environment explanation may be entirely correct
      (and is; `tos.HH` is absent and the macOS sandbox
      blocks `ar` cache-file creation), but that proves
      non-attribution, not satisfaction of AC07. The
      CORRECTION01 CLOSE did not honestly satisfy AC07.

  (b) **AC08 was satisfied only after a NON-ACT
      follow-up.** AC08 reads:

        > Patch hygiene: git diff --check on the closing
        > commit is clean.

      The CORRECTION01 CLOSE commit `1732c3f` introduced
      a trailing blank line in
      `evidence/.../correction01/close/README.md`, which
      `git diff --check` flagged at the CLOSE tree. A
      subsequent NON-ACT commit `a2f4a6e` (titled
      `tools(factory): trailing-blank-line correction`)
      removed that line. AC08 is satisfied only at the
      POST-CLOSE tree, not at the CLOSE tree. Git
      commits are immutable snapshots; a later commit
      cannot retroactively make `1732c3f` satisfy AC08.
      The CLOSE tree failed AC08.

  (c) **Direct-argv evidence lacks raw/executable
      disambiguation.** Both the IMPL and fresh CLOSE
      proof-packets report
      `DIRECT_ARGV_FORBIDDEN_COUNT=1`, while the
      closure-summary narrative describes the harness as
      satisfying the direct-argv constraint. The single
      raw hit is in a header-comment block
      (`tools/quality/llvm-gep01-test.HC` lines 11-12)
      that EXPLICITLY forbids these tokens; it is not an
      executable violation. But the evidence channel does
      not disambiguate raw hits from executable hits, so
      a reader cannot tell whether the contract is
      satisfied or whether the IMPL just hid a violation
      behind a literal-string match.

This ACT does NOT alter the harness, the compiler, the
parser, the IR, the ABI, the Factory doctrine, or any
historical evidence tree. It only:

  1. writes new evidence under
     `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction02/`
     establishing the actual state of (a), (b), (c);
  2. on its CLOSE commit, carries
     `ACT-Supersedes: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01`
     + `ACT-Corrected-Verdict: HALT_AC07_NOT_SATISFIED`
     so the Factory closure-status oracle classifies the
     predecessor's verdict correctly;
  3. documents the truth: CORRECTION01's production
     work is fully correct (predicate contract, option-B
     scratch, containment, seeded-fail, scope), but the
     closure did not truthfully satisfy AC07 or AC08,
     so the verdict is corrected to a halt.

The corrected verdict grammar is documented at
`docs/factory/GIT-METADATA.md` §2.2 / §2.3 and §3.

---

# 1. Why now

The CORRECTION01 CLOSE tree (`1732c3f`) carried
`ACT-Verdict: PASS`, but the closure evidence showed
AC07's three named gates all returning `rc=2`. The CLOSE
tree also failed AC08 (trailing blank line). A subsequent
NON-ACT commit (`a2f4a6e`) fixed the AC08 issue but did
not address AC07. Without a correction, the Factory
closure-status oracle continues to report the predecessor
as PASS, and Track B's
`ACT-POLYC-TOOLING-SHELL-BUDGET01` cannot be issued in
good faith because its foundation carries an
unsatisfied-mandatory-criterion closure.

F4 (failures are evidence) and F13 (evidence over
prose) require the verdict to match the evidence.

---

# 2. Source-of-truth hierarchy for the corrections

In descending order of authority:

1. The CORRECTION01 ACT contract (verbatim at
   `docs/acts/ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01.md`)
   for AC07 / AC08 literal text;
2. The CORRECTION01 C3 CLOSE commit's commit message
   for what was actually verified at CLOSE;
3. The fresh-tree measurements recorded at
   `evidence/.../correction01/close/unit-test.txt`,
   `jit-unit-test.txt`, `lsp-test.txt`, and
   `factory-gates.txt` for ground truth on what PASSED
   and what FAILED at CLOSE;
4. The c4 closure-summary at
   `evidence/.../c4/closure-summary.txt` for which
   gates the c4 baseline actually measured;
5. The Factory v2 grammar at
   `docs/factory/GIT-METADATA.md` for the verdict and
   supersession trailer contract;
6. AGENTS.md F14 (current truth may invalidate history)
   and F-GIT-IDENTITY (no SHA-of-self claims).

If any conflict emerges, items 1-3 are binding for
AC07 / AC08. Item 4 is binding for the question of
"counts unchanged from c4 baseline". Item 5 is binding
for the verdict / supersession trailer contract.

---

# 3. Allowed production change

NONE.

This ACT is evidence-only. The C2 IMPL commit of
CORRECTION01 (`7f88df2`) was correct; its diff is
preserved immutably per F14.

The allowed filesystem mutations are:

  - add: `docs/acts/ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02.md`
    (this document);
  - add: `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction02/`
    containing C1 RED evidence and C2 CLOSE evidence
    (no other subdirectories).

The forbidden filesystem mutations are:

  - any modification of files under
    `tools/quality/llvm-gep01-test.HC`;
  - any modification of files under `src/`;
  - any modification of `src/holyc-lib/tooling.HC` or
    `src/holyc-lib/strings.HC`;
  - any modification of historical c{1,2,3,4} evidence
    under `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/`;
  - any modification of files under
    `evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction01/`
    (RED, IMPL, and CLOSE evidence trees are all
    preserved immutably per F14);
  - any modification of the CORRECTION01 ACT document;
  - any modification of Makefiles, CI scripts, or
    Factory v2 machinery;
  - any new Bash logic;
  - any --amend, rebase, or other history-rewriting
    operation (append-only invariant per F14).

---

# 4. Principal RED

The principal RED establishes the three closure-truth
defects mechanically. The witnesses are pure, re-runnable
shell transcripts recorded under
`evidence/.../correction02/red/`.

R1 — AC07 not satisfied as written.
  Observed at CORRECTION01 CLOSE tree (commit `1732c3f`,
  reproducible via
  `git checkout 1732c3f && make unit-test` etc.):
    - `make unit-test`     rc=2 (env: tos.HH absent)
    - `make jit-unit-test` rc=2 (env: tos.HH absent)
    - `make lsp-test`      rc=2 (env: ar cache perm +
                              linker error)
  AC07 contract: "all PASS with counts unchanged from
  the c4 close-tree baseline". None of the three PASSed;
  no c4 baseline counts exist for any of them. Therefore
  AC07 != PASS as written.

R2 — c4 did not establish baseline counts for these
     three gates.
  Mechanical check:
    grep -n 'unit-test\|jit-unit-test\|lsp-test' \
        evidence/.../c4/conservation-gates.txt
  yields 0 matches. The c4 baseline measured
  `llvm-gep01-test`, `llvm-byte-memory01`,
  `llvm-intops01`, `ir-return-slot-fwd01`,
  `llvm-cap-table-verifier`, `shell-loc-gate`,
  `factory-append-only`, `llvm-spike`,
  `harness-evidence-isolation-test` — none of which is
  `make unit-test`, `make jit-unit-test`, or
  `make lsp-test`. Therefore "counts unchanged from c4
  baseline" is undefined for AC07's three named gates.

R3 — CORRECTION01 CLOSE tree failed AC08.
  Mechanical check:
    git diff --check 1732c3f~1..1732c3f
  yields:
    "evidence/.../correction01/close/README.md:55:
     new blank line at EOF."
  Therefore the CLOSE tree `1732c3f` did NOT satisfy
  AC08 ("git diff --check on the closing commit is
  clean"). The trailing-newline NON-ACT commit
  `a2f4a6e` makes the POST-CLOSE tree clean but cannot
  retroactively make `1732c3f` clean.

R4 — direct-argv evidence lacks raw/executable
     disambiguation.
  Mechanical check on the harness at the CORRECTION01
  CLOSE tree:
    grep -nE '/bin/sh|sh -c|bash -c|system\(|popen\(|
        System\(|Sh\(|Shlurp\(\)' \
        tools/quality/llvm-gep01-test.HC
  yields 2 hits, both inside the header-comment block
  on lines 11-12 that EXPLICITLY forbids these tokens.
  The IMPL and fresh CLOSE proof-packets report
  `DIRECT_ARGV_FORBIDDEN_COUNT=1`, which is neither 0
  nor 2, and does not disambiguate "raw hit" from
  "executable call". Therefore the evidence channel
  does not truthfully document whether the contract is
  satisfied.

---

# 5. IMPL phase

NONE.

This ACT has no IMPL phase. Production semantic changes
are FORBIDDEN. The harness is correct; only the
closure-contract semantics need reconciliation.

The closure reconciliation is performed in the C2 CLOSE
commit via the
`ACT-Supersedes` + `ACT-Corrected-Verdict` trailers per
`docs/factory/GIT-METADATA.md` §2.3.

---

# 6. Acceptance criteria

AC01. AC07 truthfully classified.
      Allowed outcomes (any one of):
        - AC07_PASS — if AC07 is satisfied at the
          CORRECTION02 CLOSE tree (only possible if
          AC07 is satisfied by current harness on
          current checkout, which it is not);
        - HALT_AC07_NOT_SATISFIED — if AC07 is not
          satisfied at the CORRECTION02 CLOSE tree;
        - HALT_REAL_REGRESSION — if AC07's failure is
          a true regression introduced by this ACT
          (it cannot be — this ACT has no IMPL).
      The default outcome for this checkout is
      `HALT_AC07_NOT_SATISFIED`. AC01 is satisfied when
      the close evidence records the actual outcome
      truthfully and the close commit carries the
      matching trailers.

AC02. AC07's "counts unchanged from c4 baseline" is
      mechanically established to be UNDEFINED for the
      three named gates. Evidence in
      `evidence/.../correction02/close/ac07-c4-baseline.txt`.

AC03. AC08 mechanically established at the CORRECTION01
      CLOSE tree (commit `1732c3f`). Evidence in
      `evidence/.../correction02/close/ac08-close-tree.txt`.
      The CLOSE commit `1732c3f` failed AC08; the
      NON-ACT commit `a2f4a6e` made the POST-CLOSE
      tree clean.

AC04. Direct-argv audit records:
        RAW_HITS (entire harness file via grep -E)
        COMMENT_ONLY_HITS (lines starting with `//`)
        EXECUTABLE_HITS (RAW_HITS - COMMENT_ONLY_HITS)
      Required: `EXECUTABLE_HITS=0` on
        `tools/quality/llvm-gep01-test.HC`,
        `src/holyc-lib/tooling.HC`,
        `src/holyc-lib/strings.HC`.
      Evidence in
      `evidence/.../correction02/close/direct-argv-audit.txt`.

AC05. Current harness proof remains GREEN (conservation
      per F10):
        - predicate-selftest: 7/7 PASS, rc=0
        - GEP01 real harness: 30/0 PASS, rc=0
        - seeded-fail: 29/1 FAIL, rc=1
      Re-run only if needed to establish conservation;
      no implementation changes.
      Evidence in
      `evidence/.../correction02/close/harness-replay.txt`.

AC06. CORRECTION02 range:
        - git diff --check HEAD~1..HEAD = clean
        - production delta = empty (no changes to
          tools/quality/llvm-gep01-test.HC, src/, or
          tooling.HC)
        - factory-append-only-test = PASS
        - factory-v2-range-check = PASS for this ACT's
          CLOSE commit
      Evidence in
      `evidence/.../correction02/close/range-checks.txt`.

AC07. No SHA-of-self claims in any CORRECTION02
      artifact. Evidence in
      `evidence/.../correction02/close/no-sha-of-self.txt`
      (mechanical grep `[-0-9a-f]\{40\}` returning empty).

AC08. CORRECTION01 evidence tree at
      `evidence/.../correction01/{red,impl,close}/` is
      unchanged (verified via `git diff` showing zero
      modifications to that subtree across the
      CORRECTION02 range).

---

# 7. HALT conditions

- `HALT_RED_NOT_REPRODUCED` — if R1, R2, R3, or R4 cannot
  be mechanically reproduced against the CORRECTION01
  CLOSE commit `1732c3f`. These are pure shell transcripts
  against immutable artifacts; reproduction should be
  trivial. If any fails, halt.
- `HALT_SCOPE_EXPANSION_REQUIRED` — if truthful
  reconciliation of the CORRECTION01 closure requires
  changes outside the
  `evidence/.../correction02/` directory or
  the `docs/acts/ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02.md`
  document.
- `HALT_PRODUCTION_MODIFIED` — if the diff of
  `tools/quality/llvm-gep01-test.HC`, `src/`, or
  `src/holyc-lib/tooling.HC` is non-empty across the
  CORRECTION02 range.
- `HALT_HISTORICAL_EVIDENCE_MUTATED` — if any file under
  `evidence/.../correction01/` or
  `evidence/.../c{1,2,3,4}/` is modified by this ACT.
- `HALT_PRE_DECLARED_FALSE_GREEN` — if AC01 is recorded
  as `AC07_PASS` when the three named gates return rc=2.
  F5 forbids misrepresenting failed criteria as PASS.

---

# 8. Commit topology (per F12)

C1 RED       (committed)   — this ACT document +
                              correction02/red/ principal
                              RED witnesses
                              (mechanical re-checks of R1,
                              R2, R3, R4 against `1732c3f`).
C2 CLOSE     (deferred)    — verdict reconciliation via
                              ACT-Supersedes +
                              ACT-Corrected-Verdict
                              trailers; populate
                              correction02/close/.

Cardinality-1 CLOSE: exactly ONE commit for this ACT
may carry `ACT-Phase: CLOSE` (and `ACT-Verdict: PASS`).

---

# 9. Commit trailer contract

C1 (initial RED):

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02
    ACT-Phase: RED

C2 (CLOSE — verdict reconciliation):

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION02
    ACT-Phase: CLOSE
    ACT-Verdict: PASS
    ACT-Supersedes: ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
    ACT-Corrected-Verdict: HALT_AC07_NOT_SATISFIED

Per `docs/factory/GIT-METADATA.md` §2.3, the correction's
own CLOSE carries its own `ACT-Verdict: PASS` (the
correction ACT itself passes); the corrected verdict
about the predecessor is recorded in
`ACT-Corrected-Verdict`. The Factory closure-status
oracle MUST then report the predecessor as
`HALT_AC07_NOT_SATISFIED` (matching the existing
verdict grammar at §2.2:
`^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$`).

No SHA-of-self fields. The closing commit's SHA is
queried from Git, not embedded in this document.

---

# 10. Residue (pre-declared per F11)

P0 — none anticipated beyond R1-R4 (which are this ACT's
mandatory scope and are closed mechanically).

P1 — AC07 three gates (`make unit-test`,
     `make jit-unit-test`, `make lsp-test`) classified
     `HALT_AC07_NOT_SATISFIED` on this checkout. The
     root cause is environmental (`/usr/local/include/
     tos.HH` absent; macOS sandbox `ar` cache-file
     permission); NOT a regression introduced by this
     ACT (this ACT has no IMPL phase). Fixing the
     environment is infrastructure work outside this
     ACT and outside Track B; requires either
     `make install` (install hcc globally) OR a
     Makefile recipe rewrite that always passes
     `--install-dir` to `hcc` invocations.
     Recorded for downstream ACT (next ACT: see §12).

P2 — same as CORRECTION01's P2 (c4 close residue
     preserved per F14).

---

# 11. Closure handoff (deferred to C2 CLOSE)

Will contain the standard structured fields:

    VERDICT
    IDENTITY (branch, predecessor, ACT id, phase, verdict,
              supersedes, corrected-verdict)
    RED (R1-R4 mechanical reproduction)
    IMPLEMENTATION (NONE — pure evidence ACT)
    GATES (BUILD=N/A, TARGETED=N/A, UNIT=N/A, JIT=N/A,
           LSP=N/A, DIFF_CHECK=PASS, FACTORY_V2=PASS,
           RANGE_CHECK=PASS, NO_SHA_OF_SELF=PASS,
           DIRECT_ARGV_AUDIT=PASS)
    SCOPE (FILES_CHANGED=correction02/ only,
           harness_CHANGED=NO, src_CHANGED=NO,
           tooling.HC_CHANGED=NO,
           correction01/_CHANGED=NO,
           historical_c{1,2,3,4}_CHANGED=NO)
    RESIDUE (P0 none, P1 AC07 halt truthfulness,
             P2 carry-forward)
    NEXT_ACT

Per the Factory v2 HANDOFF template at
`docs/factory/HANDOFF-TEMPLATE.md`. The authoritative
verdict lives on the C2 CLOSE commit's `ACT-Verdict`
trailer, not on the HANDOFF file.

---

# 12. Next ACT on PASS

This ACT does NOT begin the next Track-B step. On PASS,
NEXT = `ACT-POLYC-TOOLING-SHELL-BUDGET01`, exactly as
recorded in the c4 closure-summary for MIGRATE-GEP01
and in CORRECTION01's §12.

The reason this is gated on CORRECTION02 (and not
issued directly after CORRECTION01's PASS) is that
CORRECTION01's PASS was incorrect on AC07; Track B
should not be advanced on a verdict whose
acceptance criteria were not satisfied.

If this ACT itself must HALT, the next ACT is to
recommend the bounded expansion in a separate
CORRECTION03 (NOT in this turn).

HARD STOP after C2 CLOSE.
