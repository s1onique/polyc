HANDOFF for ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02

VERDICT

PASS_TRUE_GREEN

  Reviewer's post-close audit identified three P0 closure-
  truth defects in ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01
  plus a W1 LEXER conservation gap. All four are closed by
  this ACT's bounded repair. The AC ledger is a faithful
  replay of the AUTHORIZED AC01..AC22 from
  docs/acts/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01.md §6;
  the predecessor's AC-table substitution defect is closed.
  F-POLYC-TOOLS is strictly honored (PolyC tool 361 LOC +
  shell dispatch 34 LOC). Bootstrap identity is now a
  measured SHA-256 baked into the archive as a producer-id
  note. LEXER08 and LEXER09 fixed-point verifiers PASS.

IDENTITY

  ACT: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02
  Predecessor: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01
               (reclassified by this ACT from PASS_TRUE_GREEN
                to FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT,
                per F14)

  Predecessor verdict reclassification (F14):
    Original claim:     PASS_TRUE_GREEN (ad77672 trailer)
    Reviewer verdict:   REJECT (post-close audit identified
                        three closure-truth defects)
    This ACT's verdict: FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT
                        (substrate engineering preserved, only
                        the truth status of the closure changes;
                        this HANDOFF does not rewrite the
                        predecessor HANDOFF per F14)

  This ACT commit topology (4 commits, append-only):
    C0 AUTH:           2bc0e9a
    C1 RED:            c1e1714
    C2 IMPL:           256e398
    C3 VERIFY:         f94f297
    C4 CLOSE:          <this commit>

  PATCH_HYGIENE_BASELINE   = 6e30e7f (entry of CORRECTION01)
  ENTRY_HEAD               = 6e30e7f66a5516ee1af5ca9e68f9828303fc54bc
  WORKTREE_STATUS_AT_CLOSE = clean
  APPEND_ONLY              = PASS=11 FAIL=0

ROOT CAUSE / FINDING

  The predecessor ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01
  closed with the trailer "ACT-Verdict: PASS_TRUE_GREEN"
  (commit ad77672). A post-close reviewer audit REJECTED that
  verdict, identifying four closure-truth defects:

    P0-1 (AC table substitution):
      The c3/.../mandatory-ac-status.tsv used a SUBSTITUTED
      AC01..AC22 mapping (e.g. AC02 = "fail-open RED
      reproduced", AC05 = "semantic matrices RED reproduced",
      etc.) that did NOT match the AUTHORIZED AC01..AC22
      definitions in docs/acts/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-
      CORRECTION01.md §6. The 22 PASS / 0 FAIL result was
      therefore not a replay of the authorized AC table.

    P0-2 (bootstrap identity not verified):
      The Makefile lib-tos precondition error did NOT name
      HCC_BOOTSTRAP_PROVENANCE_SHA. The resulting archive
      had no producer-id note; only the path-name trust was
      used as provenance.

    P0-3 (F-POLYC-TOOLS violated):
      scripts/quality/libtos-n02-harness.sh was 262 LOC of
      substantive shell. Authorization explicitly permits only
      ONE new tool (runtime-contract-test.HC) and forbids
      additional non-PolyC tooling. The C3 evidence
      acknowledged the violation and tried to reclassify it
      as a "quality harness exemption" that does not exist
      in F-POLYC-TOOLS.

    W1 (LEXER conservation not rerun):
      The predecessor's c3-lexer-conservation.txt concluded
      conservation from "no LEXER source files mutated"
      rather than by mechanically running the AC14 commands.
      The lib-tos rebuild may have perturbed the runtime
      archive against which both PolyC verifiers link.

  This ACT's repair preserves the predecessor's substrate
  engineering result (fail-closed build seam, 5 required
  symbols exported, archive-only consumer link, 21-case
  semantic matrix, N02 isolation) and makes the surrounding
  evidence and build seam honest.

RED

  Four RED witnesses, one per defect class, all reproduced
  against the predecessor's commit (HEAD = 6e30e7f, the
  CORRECTION01 entry). Captured in
  evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02/c1/:

    RED-1 (P0-1, AC table substitution):
      Side-by-side comparison of the authorized AC01..AC22
      (from CORRECTION01 §6) against the CORRECTION01 c3
      ledger's AC01..AC22. The latter is a different set of
      predicates. 22 PASS / 0 FAIL was not a replay of the
      authorized table.
      See: c1-red1-ac-table-substituted.txt

    RED-2 (P0-2, bootstrap identity):
      With bootstrap absent, the precondition error message
      did NOT contain HCC_BOOTSTRAP_PROVENANCE_SHA (token
      count = 0). The archive had no producer-id member.
      See: c1-red2-bootstrap-identity.txt

    RED-3 (P0-3, F-POLYC-TOOLS):
      wc -l on scripts/quality/libtos-n02-harness.sh
      reported 262 LOC of substantive shell. Authorization
      forbids >50 LOC of non-PolyC tooling.
      See: c1-red3-f-polyc-tools-violation.txt

    RED-4 (W1, LEXER conservation):
      The CORRECTION01 c3-lexer-conservation.txt argued
      conservation from source-file stability rather than
      from running the verifier commands. We ran them in C1
      and confirmed both PASS:
        lexer08-trivia-fixedpoint-verify: PASS (RC=0)
        lexer09-link-fixedpoint-verify:   PASS (RC=0)
      See: c1-red4-lexer-fixedpoint-not-rerun.txt

  Summary: c1-red-summary.tsv (4 REDs, all closed by C2).

IMPLEMENTATION

  Production mutations:

    Makefile:
      - LIBTOS_BOOTSTRAP_SHA captured via shell at parse time:
          LIBTOS_BOOTSTRAP_SHA ?= $(shell shasum -a 256 $(LIBTOS_HCC))
      - lib-tos precondition error now names
        HCC_BOOTSTRAP_PROVENANCE_SHA and the required
        LIBTOS_HCC SHA-256 (both with and without builder).
      - New step 5/8: bake a synthetic producer_id.o
        containing `const char __producer_id[65] = "<SHA>";`
        into the archive as a member.
      - New step 8/8 verifies both:
          (a) nm -j reports producer_id symbol
          (b) `strings | grep -qF <expected-SHA>` confirms
              the SHA is present in the archive.
        Exit 4 or 5 on failure.
      - New target libtos-n02-isolate: builds the PolyC tool
        and runs the shell dispatch + PolyC isolation.
      - Added libtos-n02-isolate to .PHONY list.

    src/CMakeLists.txt: unchanged from CORRECTION01.

  New files:

    tools/quality/libtos-n02-isolate.HC   (361 LOC PolyC)
      Self-contained PolyC tool that performs the substantive
      archive-mutation, compile, link, and undefined-symbol
      capture steps. Links archive-only against libtos.a.
      Replaces the 262-LOC shell harness from CORRECTION01.

    scripts/quality/libtos-n02-harness.sh (34 LOC shell)
      Argument parsing + scratch-dir setup + invoking the
      PolyC tool. Pure dispatch glue. F-POLYC-TOOLS PASSES.

  Mutation of production source: ZERO.
  (No src/parser.c, src/aarch64.c, src/holyc-lib/*.HC, or
  canonical archive symbol-set mutations.)

GATES

  C0/C1 RED/RECON complete:
    c0/c0-entry-identity.txt                PASS
    c1/c1-red1-ac-table-substituted.txt      PASS
    c1/c1-red2-bootstrap-identity.txt        PASS
    c1/c1-red3-f-polyc-tools-violation.txt   PASS
    c1/c1-red4-lexer-fixedpoint-not-rerun.txt PASS
    c1/c1-red-summary.tsv                   4/4 REDs

  C2 IMPL ran cleanly:
    Production mutation: 3 files (Makefile,
                            scripts/quality/libtos-n02-harness.sh,
                            tools/quality/libtos-n02-isolate.HC).
    New files: 1 PolyC tool + 1 shell dispatch + 3 C2 evidence
    files.

  C3 VERIFY (this ACT's evidence tree):
    Fresh canonical archive:                 PASS (157760 bytes)
    5 required symbols present:              PASS
    AC02 fail-closed (RED-1 closed):         PASS
    AC03 provenance-strict (RED-2 closed):   PASS
    AC04 producer-id under __.SYMDEF:        PASS
    AC05..AC11 semantic matrices:            21/21 PASS
    AC12 N02 isolation (10 sub-cases):       PASS
    AC13 archive-only consumer link:         PASS
    AC14 LEXER08 + LEXER09 verifiers:        PASS (both RC=0)
    AC15 make gate-fast:                     PASS (PAIR_OK=14)
    AC16 git diff --check 5cbda9b HEAD:      RC=0
    AC17 F-NO-PYTHON preserved:              PASS (no new Python)
    AC18 F-POLYC-TOOLS:                      PASS (34 LOC shell)
    AC19 F14 surfaces untouched:             PASS
    AC20 worktree clean:                     PASS
    AC21 factory-append-only-test:           PASS=11 FAIL=0
    AC22 phase ordering preserved:           PASS

  Mandatory AC ledger:
    AC01..AC22 = 22 PASS, 0 FAIL, 0 UNKNOWN, 0 MISSING

SCOPE

  Production mutations:
    Makefile:           +~80 lines (lib-tos rewrite + producer-id
                                  step + new libtos-n02-isolate target)
                       -~20 lines (old fail-open recipe)

  New non-production files:
    tools/quality/libtos-n02-isolate.HC    361 LOC (PolyC)
    scripts/quality/libtos-n02-harness.sh   34 LOC (shell dispatch)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02/{c0,c1,c2,c3}/  full
    docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02.md

  Total tracked-file delta (production only):
    ~80 lines added, ~20 lines removed (production)
    ~395 lines added (non-production: PolyC tool + shell + C0-C3 evidence)

  Residue (per F11, NOT in scope of this ACT):

    P1: ./hcc ARM64 inline-asm parser regression at commit
        6ba9f5ec. This ACT's repair routes the libtos build
        through the bootstrap chain (./build/hcc-bootstrap04)
        which DOES parse these mnemonics correctly. The ./hcc
        parser regression itself remains. Recommended bounded
        ACT:
          ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01

    P2: tools/quality/runtime01-selftest.HC duplicates
        archive symbols (#includes tooling.HC directly).
        Out of scope; documented residue in predecessor
        HANDOFF.

    P2: PolyC verifier's SpawnAndCapture invocation uses a
        relative path. Out of scope.

    Pre-existing: tools/factory/factory-no-python-check.HC
        binary fails to link with current libtos.a (90
        duplicate symbols). This is a pre-existing wiring
        issue noted in AGENTS.md ("it is NOT yet wired into
        gate-fast"). F14-equivalent predicate "did this ACT
        add any new Python" PASSES.

  Closed-evidence surfaces (F14):
    evidence/ACT-POLYC-STATIC-FUNCTION-LINKAGE01/**           (untouched)
    evidence/ACT-POLYC-STATIC-FUNCTION-LINKAGE01-CORRECTION01/** (untouched)
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01/**(untouched)
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION0*/**(untouched)
    evidence/ACT-POLYC-SELFHOST-LEXER*/**                     (untouched)
    evidence/ACT-POLYC-SELFHOST-LEXER04-CORRECTION01/**       (untouched)
    docs/factory/HANDOFF-ACT-POLYC-STATIC-FUNCTION-LINKAGE01*.md (untouched)
    docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01*.md (untouched)
    docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER0*.md        (untouched)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01/**                (untouched)
    docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01.md    (untouched,
                                                             verdict
                                                             reclassified
                                                             by this ACT)
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01/**   (untouched;
                                                             verdict
                                                             reclassified
                                                             by this ACT)
    docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01.md
                                                            (untouched,
                                                             verdict
                                                             reclassified
                                                             by this ACT)

    CLOSED_EVIDENCE_DELTA = 0
    CLOSED_HANDOFF_DELTA  = 0

  Append-only history:
    factory-append-only-test: PASS=11 FAIL=0 (NC1..NC11)
    No amend, rebase, force-push, reset, filter-branch, git replace
    since C0 entry. 4 commits added (C0, C1, C2, C3), all linear
    descendants of 6e30e7f. C4 CLOSE will be the 5th and final
    commit of this bounded correction.

NEXT ACT

  ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 (immediate successor)

    Mission: produce the G0/G1/G2/G3 production semantic seam
    proof previously blocked by the libtos substrate gap, plus
    the PolyC-native verifier substrate (factoring out the C
    verifier and the C SHA-256 tool under F-POLYC-TOOLS), plus
    the authorized AC contract replay (AC01..AC32 per
    CORRECTION01 §31). Closes the LEXER04 correction lineage.

    Why this ACT is now ready: the libtos substrate is now
    (a) fail-closed at the artifact boundary,
    (b) provenance-strict with measured SHA-256 baked into
        the archive,
    (c) semantically verified by 21 mechanically executed
        runtime-contract-test cases,
    (d) N02-isolated by a PolyC-native tool,
    (e) LEXER-conservation-confirmed by mechanical re-runs
        of the two fixed-point verifiers,
    (f) AC-ledger-honest (replayed from authorized §6).

  Recommended P1 residue ACT:

  ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01

    Mission: repair the ./hcc ARM64 inline-asm parser
    regression at commit 6ba9f5ec so ./hcc (rather than the
    bootstrap chain) can build src/holyc-lib/{memory,
    strings}.HC. The bootstrap hcc at commit ffee58b
    (./build/hcc-bootstrap04) DOES parse these mnemonics
    correctly, so the parser regression is precisely
    localized to the diff between ffee58b and 6ba9f5ec.

    Mechanically proven reproduction:
      ./build/hcc-bootstrap04 -c src/holyc-lib/memory.HC  # OK
      ./hcc                  -c src/holyc-lib/memory.HC  # FAILS:
        error: src/holyc-lib/memory.HC:146: error:
            asm: unexpected token at start of line
                (LDP X29, X30, [SP], 16)

    Out of scope for THIS ACT (per §2: src/parser.c,
    src/aarch64.c mutation requires HALT_COMPILER_SCOPE_
    EXPANSION). Recommend opening as a dedicated bounded
    ACT after LEXER04 CORRECTION02 closes.

APPEND-ONLY NOTE

  Per ACT-POLYC-FACTORY-HISTORY-RECONCILE01 §19, PolyC
  authoritative Git history is append-only from
  baf5dbd77cf89330699685dffd932c54031c815c forward. This
  ACT's four commits (2bc0e9a, c1e1714, 256e398, f94f297)
  are linear descendants of 6e30e7f, which is itself an
  ancestor of the append-only point. The append-only
  invariant is preserved (factory-append-only-test PASS).

  The predecessor HANDOFF (docs/factory/HANDOFF-ACT-POLYC-
  LIBTOS-SYMBOL-GAPS01-CORRECTION01.md) remains in the tree
  per F14 and is reclassified by this ACT's verdict and
  this HANDOFF to FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT.
  Its substrate engineering result (5 required symbols
  exported, archive-only consumer link, verifier execution,
  all.s fallback removed) is preserved; only the truth
  status of the closure changes.
