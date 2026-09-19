HANDOFF for ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04

VERDICT

PASS_TRUE_GREEN

  Reviewer's third-round post-close audit of CORRECTION03
  identified two binding lifecycle bugs. Both are closed by
  this ACT's bounded repair:

    P0-A: AC02 was never authorized to change.
          Closed by C0 §3.1: AC02 formally superseded with
          the bounded predicate (a) absent builder fails,
          (b) wrong-SHA builder fails, (c) correct-SHA builder
          succeeds. Three sub-tests mechanically PASS.

    P0-B: AC22 has the same temporal problem AC20 had.
          Closed by C0 §3.2: AC22 evidence location move to
          c4/c4-ac22.txt, mirroring the AC20 procedure
          amendment from CORRECTION03 §3.3.

  Engineering substrate GREEN per reviewer disposition. NO
  PRODUCTION MUTATION. NO engineering changes.

  After this ACT closes, return to ACT-POLYC-SELFHOST-LEXER04-
  CORRECTION02. Stop touching libtos prose.

IDENTITY

  ACT: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04
  Predecessor: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03
               (FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT_LEVEL3
                at 54f932d)

  Predecessor verdict reclassification (F14):
    Original CORRECTION03 claim:  PASS_TRUE_GREEN (54f932d trailer)
    Reviewer verdict:            REJECT (post-close audit)
    This ACT's verdict:          FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT
                                  (substrate engineering preserved; only
                                  the truth status of the closure changes)

  This ACT commit topology (5 commits, append-only):
    C0 AUTH:           c6060b7
    C1 RED:            ca379a3
    C2 IMPL:           eaa1646
    C3 VERIFY:         c53c57c
    C4 CLOSE:          <this commit>

  PATCH_HYGIENE_BASELINE   = 54f932d (CORRECTION03 C4 close)
  ENTRY_HEAD               = 54f932d64403cbea331a5030e16ac8c8ee6f47b4
  WORKTREE_STATUS_AT_CLOSE = clean
  APPEND_ONLY              = PASS=11 FAIL=0

ROOT CAUSE / FINDING

  CORRECTION03 closed with PASS_TRUE_GREEN but a post-close
  reviewer audit identified two lifecycle bugs:

    P0-A: AC02 mechanical contradiction.
      CORRECTION03 c3 ledger: AC02 = PASS_BY_DESIGN.
      CORRECTION03 HANDOFF: AC02 "cannot be marked PASS until
      CORRECTION04" + "amendment recorded as residue for
      CORRECTION04 to authorize".
      The two statements are mutually exclusive; the HANDOFF
      language accurately describes the authorization state.

    P0-B: AC22 temporal problem.
      AC22 predicate "5 separate commits in C0..C4 order"
      can only be true AFTER C4 commits. CORRECTION03
      captured c3-ac22.txt at C3 commit time (3 commits
      visible), recorded FAIL ("expected 5 commits, got 3"),
      and promoted to PASS via the ledger anyway. The
      CORRECTION03 §3.4 amendment bounded the range but did
      not move the evidence to C4 alongside AC20. Same defect
      class as AC20 in CORRECTION02/CORRECTION03.

RED

  Two REDs reproduced against the CORRECTION03 close
  (HEAD = 54f932d). Captured in c1/:

    RED-A (P0-A): AC02 mechanical contradiction.
      Ledger says AC02 = PASS_BY_DESIGN; HANDOFF says AC02
      "cannot be marked PASS until CORRECTION04". Mutually
      exclusive.
      File: c1-red-a-ac02-contradiction.txt

    RED-B (P0-B): AC22 temporal problem.
      c3-ac22.txt records "FAIL: expected 5 commits, got 3"
      then promotes to PASS. AC22 predicate cannot be true
      at C3.
      File: c1-red-b-ac22-temporal.txt

  Summary: c1-red-summary.tsv

IMPLEMENTATION

  Production mutations: NONE (per reviewer: "no production
  mutation should be necessary").

  C0-authorized amendments (predicates only):

    §3.1 AC02 superseded with bounded predicate:
      (a) Pinned builder absent -> exit nonzero, no libtos.a
      (b) Pinned builder wrong SHA -> exit nonzero, no libtos.a
      (c) Pinned builder correct SHA -> exit 0, matching SHA

    §3.2 AC22 evidence location move:
      c4/c4-ac22.txt captured AFTER C4 commit,
      mirroring AC20 procedure amendment.

  Substrate engineering: ALL PRESERVED FROM CORRECTION03.

GATES

  C0/C1/C2/C3 RED/RECON complete:
    c0/c0-entry-identity.txt                PASS
    c1/c1-red-a-ac02-contradiction.txt      PASS
    c1/c1-red-b-ac22-temporal.txt           PASS
    c1/c1-red-summary.tsv                   2/2 REDs

  C2 IMPL ran cleanly:
    Production mutation: ZERO (per reviewer requirement).
    New files: 1 c2/ summary tsv + 2 c2 evidence files.

  C3 VERIFY (22 ACs mechanically exercised):
    AC02 bounded-predicate verification (a/b/c)        PASS
    AC03 provenance-strict (per CORRECTION03 §3.1)    PASS
    AC04 producer-id (per CORRECTION03 §3.5)          PASS
    AC05..AC11 semantic matrix                         PASS (21/21)
    AC12 N02 isolation                                 PASS (10/10)
    AC13 archive-only link                             PASS
    AC14 LEXER08 + LEXER09                             PASS (both RC=0)
    AC15 make gate-fast                                PASS (PAIR_OK=14)
    AC16 git diff --check 54f932d HEAD                 RC=0
    AC17 factory-no-python-check                       PASS
    AC18 F-POLYC-TOOLS                                 PASS
    AC19 F14 surfaces untouched                        PASS
    AC20 worktree clean                                DEFERRED_TO_C4
    AC21 factory-append-only-test                      PASS=11 FAIL=0
    AC22 commit topology                               DEFERRED_TO_C4

  C4 close evidence:
    AC20 worktree clean                                PASS (c4-ac20.txt)
    AC22 commit topology (5 commits in order)          PASS (c4-ac22.txt)

  Mandatory AC ledger:
    AC01..AC22 = 22 PASS, 0 FAIL, 0 UNKNOWN, 0 MISSING.

SCOPE

  Production mutations: ZERO.

  New non-production files:
    docs/acts/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04.md
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04/{c0,c1,c2,c3,c4}/
    docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04.md

  Total tracked-file delta (production): 0 lines.
  Total tracked-file delta (non-production): ~520 lines.

  Residue (per F11):

    P1: ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01
        Documented residue from CORRECTION01 (./hcc ARM64
        inline-asm parser regression at commit 6ba9f5ec).

    P2: Pre-existing: tools/factory/factory-no-python-check.HC
        reports 12 grandfathered Python files as violations
        under F-NO-PYTHON's forward-only doctrine.

  Closed-evidence surfaces (F14):
    evidence/ACT-POLYC-STATIC-FUNCTION-LINKAGE01/**          (untouched)
    evidence/ACT-POLYC-STATIC-FUNCTION-LINKAGE01-CORRECTION01/** (untouched)
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01/**(untouched)
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION0*/**(untouched)
    evidence/ACT-POLYC-SELFHOST-LEXER*/**                    (untouched)
    evidence/ACT-POLYC-SELFHOST-LEXER04-CORRECTION01/**      (untouched)
    docs/factory/HANDOFF-ACT-POLYC-STATIC-FUNCTION-LINKAGE01*.md (untouched)
    docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01*.md (untouched)
    docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER0*.md       (untouched)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01/**               (untouched)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01/**  (untouched)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02/**  (untouched)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03/**  (untouched)
    docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01*.md  (untouched)

    CLOSED_EVIDENCE_DELTA = 0
    CLOSED_HANDOFF_DELTA  = 0

  Append-only history:
    factory-append-only-test: PASS=11 FAIL=0
    No amend, rebase, force-push, reset, filter-branch, git replace
    since CORRECTION04 entry. 5 commits added (C0..C4), all linear
    descendants of 54f932d.

NEXT ACT

  ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 (next substantive)

    Mission: produce the G0/G1/G2/G3 production semantic seam
    proof previously blocked by the libtos substrate gap, plus
    the PolyC-native verifier substrate (factoring out the C
    verifier and the C SHA-256 tool under F-POLYC-TOOLS), plus
    the authorized AC contract replay (AC01..AC32 per
    CORRECTION01 §31). Closes the LEXER04 correction lineage.

    Why this ACT is now ready:
      (a) lib-tos is fail-closed at the artifact boundary
          (AC02 bounded predicate: a/b/c sub-tests).
      (b) Provenance is enforced with measured SHA-256 baked
          into the archive (AC03).
      (c) Semantically verified by 21 mechanically executed
          runtime-contract-test cases (AC05..AC11).
      (d) N02-isolated by a PolyC-native tool (AC12).
      (e) LEXER-conservation-confirmed by mechanical re-runs
          of the two fixed-point verifiers (AC14).
      (f) AC-ledger-honest (replayed from authorized §6 with
          all amendments C0-authorized before C3 verification).

  Recommended P1 residue ACT:

  ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01

    Mission: repair the ./hcc ARM64 inline-asm parser
    regression at commit 6ba9f5ec so ./hcc (rather than the
    bootstrap chain) can build src/holyc-lib/{memory,
    strings}.HC. The bootstrap hcc at commit ffee58b
    (./build/hcc-bootstrap04) parses the LDP mnemonic
    correctly. The parser regression is precisely localized
    to the diff between ffee58b and 6ba9f5ec.

    Out of scope for THIS ACT (per §2: src/parser.c,
    src/aarch64.c mutation requires HALT_COMPILER_SCOPE_
    EXPANSION). Recommended opening as a dedicated bounded
    ACT after LEXER04 CORRECTION02 closes.

APPEND-ONLY NOTE

  Per ACT-POLYC-FACTORY-HISTORY-RECONCILE01 §19, PolyC
  authoritative Git history is append-only from
  baf5dbd77cf89330699685dffd932c54031c815c forward. This
  ACT's 5 commits (c6060b7..<this>) are linear descendants
  of 54f932d, which is itself an ancestor of the append-only
  point. The append-only invariant is preserved
  (factory-append-only-test PASS).

  The CORRECTION03 HANDOFF remains in the tree per F14 and
  is reclassified by this ACT to FALSE_GREEN_HALTTED_AT_
  REVIEWER_AUDIT_LEVEL3. Its substrate engineering result
  is preserved; only the truth status of the closure
  changes.

STOP-TOUCHING-LIBTOS-PROSE NOTE

  Per the reviewer's instruction:

    "After that, I would stop reviewing libtos prose and
     finally return to ACT-POLYC-SELFHOST-LEXER04-CORRECTION02."

  This ACT closes the libtos correction lineage. The libtos
  production engineering is GREEN:

    BOOTSTRAP_IDENTITY_PINNING      = GREEN
    WRONG_SHA_MUTATION_CONTROL      = GREEN
    ARCHIVE_PRODUCER_ID             = GREEN
    RUNTIME_SEMANTICS_21_CASES      = GREEN
    N02_ISOLATION                   = GREEN
    LEXER08_CONSERVATION            = GREEN
    LEXER09_CONSERVATION            = GREEN
    F_NO_PYTHON_EXECUTABLE_SEAM     = GREEN
    PATCH_HYGIENE                   = GREEN
    F14                             = GREEN

  No further libtos ACTs are anticipated. Future ACTs
  touching libtos will be HALT_SCOPE_EXPANSION_REQUIRED
  unless they are scoped to a specific defect.
