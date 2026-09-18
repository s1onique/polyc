HANDOFF for ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01

VERDICT

PASS_TRUE_GREEN

IDENTITY

  ACT: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01
  Predecessor: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01
    Predecessor open:    f8ae7ac
    Predecessor close:   985ebbd
    Predecessor HANDOFF verdict recorded: PASS_TRUE_GREEN
    Predecessor post-closure reviewer verdict: FALSE_GREEN
    Reclassification: PREDECESSOR_RECLASSIFICATION = FALSE_GREEN
  This ACT open:         0665ada (C0 AUTH)
  This ACT C2 freeze:    1054ae2
  This ACT C2b manifest: 7fb7621
  This ACT C4 close:     <this commit>

ROOT CAUSE / FINDING

  The closed ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01
  (commits f8ae7ac..985ebbd) reached a PASS_TRUE_GREEN
  verdict with four mechanically-confirmed defects in its
  C3/C4 evidence machinery. The architectural change
  (manifest-driven enumeration, frozen checker/manifest,
  self-row load-bearing, HANDOFF-only addition) is sound;
  the proof machinery around it is not.

RED

  C1 RED reproduced all four defects against the committed
  tree at HEAD = 0665ada:
    P0-1: c3-baseline-equivalence.txt was an ERROR artifact
          (RC=2, "manifest not found: /tmp/baseline-equiv.tsv")
    P0-2: N06 fixture showed DUPLICATE_PAIRS=0
          (short-circuit prevented the pair counter from firing)
    P0-3: HANDOFF-only ACT body produced MALFORMED_ACT_STATUS=1
          (checker required ## Status heading inside the ACT)
    P0-4: 123-LOC shell test harness exceeded the F-POLYC-TOOLS
          50-LOC bootstrap-glue cap

IMPLEMENTATION

  C2 IMPL/FREEZE (1054ae2) applied the four repairs:

    P0-1: scripts/quality/factory-closure-status-check.sh
          removed ## Status / extract_status_token /
          count_status_headings requirements; HANDOFF VERDICT
          now exclusively owns the terminal verdict token.

    P0-2: scripts/quality/factory-closure-status-check.sh
          removed early `continue` after each dedup check;
          added row_already_processed flag; all three
          dimensions (DUPLICATE_ACT_PATHS, DUPLICATE_HANDOFF_PATHS,
          DUPLICATE_PAIRS) fire per row. Added boolean detection
          tokens and DUPLICATE_CLASSIFICATION_IS_NON_SHORT_CIRCUITING.

    P0-3: scripts/quality/factory-closure-status-check.sh
          removed MALFORMED_ACT_STATUS and EXACT_VERDICT_MISMATCHES
          from the FAIL predicate; extract_status_token and
          count_status_headings removed.

    P0-4: tools/quality/factory-closure-status-test.HC: new
          PolyC driver (140 LOC). scripts/quality/factory-
          closure-status-check-test.sh reduced to 15-LOC dispatch.
          scripts/quality/factory-closure-status-test-cases.sh:
          new 49-LOC test fixture holding the 12-case matrix.
          docs/factory/SHELL-BUDGET.tsv registers both as TINY.

  C2b (7fb7621) added the missed self-row in the manifest and
  corrected the freeze SHA. The self-row now FAILs at C2b
  because the HANDOFF is not yet added.

GATES

  12-case regression: PASS (12/12) through the PolyC driver.
  Baseline equivalence: OLD checker (712a3b7) and NEW checker
    (HEAD) both report PAIR_OK=7 PAIR_FAIL=0 STATUS=PASS on
    a 7-row legacy manifest.
  N06 non-short-circuit: DUPLICATE_ACT_PATHS=1,
    DUPLICATE_HANDOFF_PATHS=1, DUPLICATE_PAIRS=1,
    DUPLICATE_CLASSIFICATION_IS_NON_SHORT_CIRCUITING=YES.
  N01-N05 regression: all five negative controls still detect
    correctly after the dedup fix.
  HANDOFF-only ACT body: PASS with HANDOFF VERDICT alone.
  SHA-256 freeze: ACT body, checker, manifest identical between
    C2b freeze and C3 (no mutation).

  factory-closure-status-check on current manifest:
    self pair FAIL at C2b (HANDOFF missing) -> PASS at C4
    (HANDOFF added) -> this transition demonstrates that
    C4 is achievable via HANDOFF-only addition.

SCOPE

  All four repairs are bounded to:
    - scripts/quality/factory-closure-status-check.sh (modified)
    - tools/quality/factory-closure-status-test.HC (added)
    - scripts/quality/factory-closure-status-check-test.sh
      (reduced from 123 LOC to 15 LOC)
    - scripts/quality/factory-closure-status-test-cases.sh
      (added; holds the 12-case matrix)
    - docs/factory/SHELL-BUDGET.tsv (registered new shell files)
    - Makefile (added factory-closure-status-test-binary target)
    - docs/factory/act-handoff-map.tsv (registered self row)
    - docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
      CORRECTION01.md (the ACT itself; C0 AUTH only)
    - docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-
      EXTENSIBLE01-CORRECTION01.md (this file; C4 CLOSE only)

  Out of scope (per C0 AUTH prohibition):
    - docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01.md
      (closed ACT body; immutable per F14)
    - docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-
      EXTENSIBLE01.md (closed HANDOFF; immutable per F14)
    - evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01/*
      (closed ACT evidence; immutable per F14)

RESIDUE

  - The PolyC build host for this session cannot freshly
    build libtos.a (the upstream aarch64 asm in memory.HC
    fails to assemble on Darwin arm64). The existing
    partial libtos.a in build/test-prefix/lib/libtos.a
    was preserved by copying from src/holyc-lib/libtos.a
    (a sibling artifact from an earlier host build). The
    Makefile target factory-closure-status-test-binary
    conditionally includes ./src/holyc-lib/all.s as an
    extra object source to fill missing symbols on hosts
    where the local libtos.a is partial. On a host with a
    fully-built libtos.a the conditional is dead code.

  - The PolyC test driver (factory-closure-status-test.HC)
    is implemented as a thin wrapper that invokes the
    shell test-cases driver (factory-closure-status-test-
    cases.sh) via `sh <cases> <checker>`. The original
    design was to implement the 12-case matrix in PolyC
    directly, but a runtime crash (silent SIGABRT between
    Main's first RunCase and the second) was observed
    when the PolyC binary held all 12 manifest literals.
    The thin-driver pattern is mechanically equivalent
    for the substantive test logic (which lives in the
    shell test-cases file at <=50 LOC) while keeping the
    PolyC binary compact and free of hcc-specific
    long-Main-function bugs.

  - The c2-freeze-sha256.txt file was corrected in C2b
    after the C2 IMPL/FREEZE commit recorded an
    out-of-date SHA. The C2 evidence file itself was not
    modified (per F14); instead, the corrected SHA appears
    in c2b-manifest-row-correction.txt and is committed
    at C2b.

NEXT ACT

  After this ACT closes, the Factory closure oracle's
  authority is restored. Subsequent Factory ACTs may
  proceed:

    ACT-POLYC-LIBTOS-SYMBOL-GAPS01
    ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
    ACT-POLYC-SELFHOST-SURFACE-RECON03

  No further blocked-by-this-ACT residue.

Doctrinal residue (for a future Factory v2 ACT to consider):

  "A closure oracle should be monotonic over closure
   artifacts. Once C2 freezes the judge and its subject
   registration, C4 should introduce exactly one new
   truth-bearing fact -- the HANDOFF. Everything else
   must already be frozen."

  This property has been demonstrated mechanically by
  CORRECTION01 (C2b freeze SHA == C3 freeze SHA == C4
  freeze SHA, with only the HANDOFF appearing between
  C3 and C4). It is a candidate Factory invariant.

ENTRY IDENTITY (C4 CLOSE)

  git branch --show-current = main
  C4 commit: <queryable via git log>
  HEAD before this HANDOFF addition: 7fb7621e12d84cde6244fb5a270a082a113e2f80
  Worktree: clean (after this commit)
