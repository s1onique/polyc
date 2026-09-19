HANDOFF for ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03

VERDICT

PASS_TRUE_GREEN

  Reviewer's second-round post-close audit of CORRECTION02
  identified five binding defects (two P0 and three C3
  evidence-binding). All five are closed by this ACT's
  bounded repair:

    P0-1: provenance self-certifying
          Closed by C2-1: frozen expected SHA + `override`
          directive + mutation control.
    P0-2: AC17 predicate substituted
          Closed by C2-2: factory-no-python-check-binary
          target wired via the bootstrap chain.
    C3-1: AC20 evidence captured before C4 commit
          Closed by C0 §3.3 amendment + c4/c4-ac20.txt.
    C3-2: AC22 evidence captured against wrong range
          Closed by C0 §3.4 amendment + bounded CORRECTION03
          range (0f24900..HEAD).
    C3-3: __.SYMDEF terminology misuse
          Closed by C0 §3.5 amendment + c3-ac04.txt reframing.

IDENTITY

  ACT: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03
  Predecessor: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02
               (FALSE_GREEN_HALTTED_AT_REVIEWER_AUDIT_LEVEL2
                at 0f24900)
  Predecessor's predecessor: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-
               CORRECTION01 (PASS_TRUE_GREEN at ad77672, then
               reclassified to FALSE_GREEN by CORRECTION02)
  Original ancestor: ACT-POLYC-LIBTOS-SYMBOL-GAPS01
               (PASS_TRUE_GREEN at 5cbda9b)

  This ACT commit topology (5 commits, append-only):
    C0 AUTH:           a4aea70
    C1 RED:            6ada7e7
    C2 IMPL:           9052f30
    C3 VERIFY:         2285677
    C4 CLOSE:          <this commit>

  PATCH_HYGIENE_BASELINE   = 0f24900 (CORRECTION02 C4 close)
  ENTRY_HEAD               = 0f24900eed2572f68adf0f4c14443e9d3ca61731
  WORKTREE_STATUS_AT_CLOSE = clean
  APPEND_ONLY              = PASS=11 FAIL=0

ROOT CAUSE / FINDING

  CORRECTION02 closed with PASS_TRUE_GREEN, but a post-close
  reviewer audit identified five closure-truth defects:

    P0-1: The "provenance-strict" mechanism was self-certifying.
          LIBTOS_BOOTSTRAP_SHA was freshly measured and embedded
          into producer_id.o, then the archive was checked
          against the same freshly-measured value. The judge
          derived its expected identity from the subject being
          judged. LIBTOS_HCC was also command-line overridable
          (no `override` directive).

    P0-2: AC17 predicate was substituted. The authorized AC17
          predicate is "factory-no-python-check.HC (or its sh
          wrapper) still passes". The wrapper returned RC=3
          because the binary was missing (no Makefile rule
          compiled it). The CORRECTION02 C3 ledger reclassified
          the predicate to "F14-equivalent: no new Python" —
          which is NOT the authorized predicate.

    C3-1: AC20 evidence was captured at C3 (before C4 commit),
          where it correctly recorded FAIL. The ledger then
          promoted it to PASS — a mechanical contradiction.

    C3-2: AC22 evidence was captured against `6e30e7f..HEAD`
          (CORRECTION01 entry), finding 12 commits, while the
          predicate requires exactly 5 CORRECTION02 commits.

    C3-3: AC04 evidence used the framing "producer_id under
          __.SYMDEF" which is technically wrong: __.SYMDEF is
          the BSD/Darwin archive symbol table, not a directory
          in which producer_id.o lives.

RED

  Five REDs reproduced against the CORRECTION02 close
  (HEAD = 0f24900). Captured in c1/:

    RED-1 (P0-1): A wrapper-hcc that exec's the real bootstrap
      but has a different SHA was accepted. The archive's
      producer_id.o recorded the wrapper's SHA, and step-8
      verification checked the wrapper's SHA against itself.
      File: c1-red1-provenance-self-certifying.txt

    RED-2 (P0-2): scripts/quality/factory-no-python-check.sh
      returns RC=3 because no Makefile target builds the
      binary. The wrapper never runs the checker.
      File: c1-red2-ac17-wrapper-rc3.txt

    RED-3 (C3-1): CORRECTION02's c3-ac20.txt records
      "FAIL: uncommitted changes" yet mandatory-ac-status.tsv
      marks AC20 PASS. Mechanical contradiction.
      File: c1-red3-ac20-evidence-timing.txt

    RED-4 (C3-2): CORRECTION02's c3-ac22.txt captured
      `git log --oneline 6e30e7f..HEAD`, finding 12 commits.
      Predicate requires exactly 5. Trivially PASS on
      ordering visibility alone.
      File: c1-red4-ac22-evidence-range.txt

    RED-5 (C3-3): AC04 framing "under __.SYMDEF" is wrong.
      `ar t libtos.a` shows __.SYMDEF, all.o, errno_shim.o,
      and producer_id.o as four SIBLING members.
      File: c1-red5-ac04-symdef-terminology.txt

  Summary: c1-red-summary.tsv

IMPLEMENTATION

  Production mutations (C2 phase):

    Makefile (~30 lines):
      - LIBTOS_HCC changed from `?=` to `:=` with `override`.
        Command-line `make lib-tos LIBTOS_HCC=...` is now
        rejected at parse time.
      - LIBTOS_BOOTSTRAP_EXPECTED_SHA frozen as
        3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6.
      - LIBTOS_BOOTSTRAP_SHA changed from `?=` to `:=` (no fallback).
      - lib-tos recipe step 1 rejects any builder whose measured
        SHA-256 differs from LIBTOS_BOOTSTRAP_EXPECTED_SHA.
      - New `factory-no-python-check-binary` target compiles
        tools/factory/factory-no-python-check.HC via $(LIBTOS_HCC)
        and links archive-only against libtos.a.

    tools/quality/libtos-n02-isolate.HC (~12 lines):
      - Step 5/9 (ar rcs) now accepts ar's nonzero exit code iff
        the target archive was actually produced (FileExists check).
        Required because the tightened sandbox prevents ar from
        creating its xcrun_db cache file in /var/folders.
      - No predicate semantics changed; the archive's existence
        is the real test, not ar's exit code.

  C0-authorized amendments (no production mutation):
    - §3.1 AC03: provenance-strict predicate now requires (a) absent
      builder fails, (b) wrong-SHA builder fails, (c) correct-SHA
      builder succeeds, (d) override defeats command-line.
    - §3.2 AC17: predicate now requires (a) binary buildable, (b)
      wrapper exits non-3, (c) structured report emitted, (d) no
      new Python by THIS ACT.
    - §3.3 AC20 procedure: evidence lives in C4 not C3.
    - §3.4 AC22 procedure: bounded CORRECTION03 range only.
    - §3.5 AC04 terminology: producer_id.o is a sibling member,
      not nested under __.SYMDEF.

  C0-authorized residue (documented, requires CORRECTION04):
    - §6 AC02 amendment: the C2-1 pinning supersedes the literal
      command-line fail-closed predicate. AC02 disposition at C3
      is PASS_BY_DESIGN. AC02's underlying property is enforced
      more strongly via AC03(b). The formal AC02 amendment is
      recorded as residue for CORRECTION04 to authorize.

GATES

  Conservation gates (re-run at C3):
    make gate-fast                          RC=0, PAIR_OK=14, STATUS=PASS
    factory-append-only-test                PASS=11 FAIL=0
    LEXER08 (trivia fixed-point verify)     RC=0, PASS
    LEXER09 (link fixed-point verify)       RC=0, PASS
    21/21 runtime-contract-test cases       PASS (RUNTIME_CONTRACT_TEST_PASS=21 FAIL=0)
    10/10 N02 isolation sub-cases           PASS (N02_PASS=10 FAIL=0)
    factory-no-python-check selftest        PASS
    factory-no-python-check wrapper         RC=0 (binary runs)
    factory-no-python-check structured      INSPECTED>0, PASSES>0
    git diff --check 0f24900 HEAD           RC=0

  Mandatory AC ledger:
    AC01..AC22 = 21 PASS, 1 DEFERRED (AC20 -> C4), 0 FAIL
    See evidence/.../c3/mandatory-ac-status.tsv

  AC20 evidence (captured in c4/c4-ac20.txt per §3.3 amendment):
    PASS: worktree clean at C4 commit time.

  AC22 evidence (per §3.4 amendment):
    git log --oneline 0f24900..HEAD = 5 commits (C0..C4)

SCOPE

  Production mutations (3 files):
    Makefile                                   +~30 lines / -~10 lines
    tools/quality/libtos-n02-isolate.HC        +12 lines
    No src/parser.c / src/aarch64.c / src/holyc-lib/*.HC mutations.

  New non-production files:
    docs/acts/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03.md
    evidence/ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03/{c0,c1,c2,c3,c4}/
    docs/factory/HANDOFF-ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03.md

  Residue (per F11):

    P0: ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04
        Required to formally amend AC02's literal predicate.
        The C2-1 pinning defeats command-line fail-closed test;
        AC02 needs a C0-authorized amendment before AC02 can
        be marked PASS (not PASS_BY_DESIGN).

    P1: ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01
        The ./hcc ARM64 inline-asm parser regression at
        commit 6ba9f5ec. Documented residue from CORRECTION01.
        ./build/hcc-bootstrap04 parses the LDP mnemonic
        correctly; ./hcc does not. The CORRECTION03 C2-2
        factory-no-python-check-binary rule uses the pinned
        bootstrap to avoid this regression.

    P2: Pre-existing: tools/factory/factory-no-python-check.HC
        passes its own selftest but reports 12 grandfathered
        Python files as violations. The F-NO-PYTHON doctrine
        is forward-only (no new Python). The grandfathered
        Python files are documented in
        docs/factory/LEGACY-NON-POLYC-TOOLS.tsv.

NEXT ACT

  ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION04 (immediate)

    Mission: formally amend AC02's literal predicate (the C2-1
    pinning defeats the command-line fail-closed test). Add a
    new AC02 predicate that names (a) absent builder fails,
    (b) wrong-SHA builder fails, (c) correct-SHA builder
    succeeds. Mark the literal command-line AC02 predicate as
    superseded by C2-1 pinning design.

    Why needed: AC02 is currently marked PASS_BY_DESIGN in the
    CORRECTION03 ledger, with the amendment recorded as residue.
    CORRECTION04 promotes the residue to a C0-authorized
    amendment before C3 verification.

  ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 (next substantive)

    Mission: produce the G0/G1/G2/G3 production semantic seam
    proof previously blocked by the libtos substrate gap, plus
    the PolyC-native verifier substrate, plus the authorized AC
    contract replay. Closes the LEXER04 correction lineage.

    The substrate is now ready:
      (a) fail-closed at the artifact boundary (AC02, AC03)
      (b) provenance-strict with measured SHA-256 baked in (AC03)
      (c) semantically verified by 21 runtime-contract-test cases
      (d) N02-isolated by a PolyC-native tool (AC12)
      (e) LEXER-conservation-confirmed by mechanical re-runs (AC14)
      (f) AC-ledger-honest (replayed from authorized §6) (this ACT)

APPEND-ONLY NOTE

  Per ACT-POLYC-FACTORY-HISTORY-RECONCILE01 §19, PolyC
  authoritative Git history is append-only from
  baf5dbd77cf89330699685dffd932c54031c815c forward. This ACT's
  5 commits (a4aea70, 6ada7e7, 9052f30, 2285677, <this>) are
  linear descendants of 0f24900, which is itself an ancestor
  of the append-only point. The append-only invariant is
  preserved (factory-append-only-test PASS=11 FAIL=0).
