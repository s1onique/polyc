HANDOFF for ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02

VERDICT

PASS_TRUE_GREEN

IDENTITY

  ACT: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02
  Predecessor: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01
    Predecessor open:    0665ada
    Predecessor close:   b9a43f8
    Predecessor HANDOFF verdict recorded: PASS_TRUE_GREEN
    Predecessor post-closure reviewer verdict: FALSE_GREEN
    Reclassification: PREDECESSOR_RECLASSIFICATION = FALSE_GREEN
  This ACT open:         ca67d1a (C0 AUTH)
  This ACT C2 boundary:  f011d56 (C2 patch-hygiene fix)
  This ACT C3 verify:    c37d5fa
  This ACT C4 close:     <this commit>

ROOT CAUSE / FINDING

  The closed ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01
  reached a PASS_TRUE_GREEN verdict with three mechanically-confirmed
  defects in its proof machinery. The closure oracle itself is sound;
  the proof machinery around it had:

    P0-1 F-POLYC-TOOLS: the PolyC test binary was a thin driver
          invoking a 49-LOC shell file holding the substantive
          12-case matrix logic. LOC-cap factorization.
    P0-2 C3 phase binding: the monotonic proof used an inconsistent
          committed boundary (claimed 1054ae2..HEAD with empty diff
          but recorded a non-1054ae2 SHA). C3 was not its own
          committed boundary.
    P0-3 patch hygiene: 4 CORRECTION01 evidence files had trailing
          blank lines that git diff --check flagged.

RED

  C1 RED reproduced all three defects against the committed tree
  at HEAD = ca67d1a:
    c1-red-p01-polyc-engine.txt
      49-LOC shell file holds expect(), fixture construction,
      checker invocation, RC + grep matching, PASS/FAIL aggregation.
      PolyC binary is a thin driver.
    c1-red-p02-monotonic-rebuild.txt
      C3 was not its own committed boundary; CORRECTION01 evidence
      files were committed inside the C2b commit.
    c1-red-p03-whitespace.txt
      4 CORRECTION01 evidence files have trailing blank lines.

IMPLEMENTATION

  C2 IMPL/FREEZE (a865dc8) and C2 patch-hygiene fix (f011d56):

    P0-1: PolyC test binary rewritten to OWN the 12-case matrix.
          The PolyC binary now reads a static TSV fixture
          (scripts/quality/factory-closure-status-test-cases.tsv,
          data only, no executable logic), parses each row,
          decodes escape sequences, writes the per-case temp
          manifest via FileWrite, invokes the checker via
          System, captures output, matches RC + substring,
          and aggregates PASS/FAIL counters. The 49-LOC shell
          engine (scripts/quality/factory-closure-status-test-
          cases.sh) is DELETED. The shell wrapper
          (scripts/quality/factory-closure-status-check-test.sh)
          is reduced to 16 LOC pure dispatch (env vars + exec).
          docs/factory/SHELL-BUDGET.tsv updated.

    P0-2: deferred to C3. This C2 commit establishes the frozen
          starting boundary for the new monotonic proof. C3 is a
          real, named commit (c37d5fa) containing only new files
          under evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-
          EXTENSIBLE01-CORRECTION02/c3/.

    P0-3: 4 CORRECTION01 evidence files replaced with
          byte-equivalent (modulo trailing blank line) versions.
          Stripping the trailing blank line preserves content;
          removes the git diff --check finding.

GATES

  12-case regression: 12/12 PASS through the new PolyC binary
  (no shell engine).

  Monotonic proof against real committed boundaries:
    git diff <C2_boundary>..<C3_verify> -- checker
      = empty
    git diff <C2_boundary>..<C3_verify> -- manifest
      = empty
    git diff <C2_boundary>..<C3_verify> -- ACT-body-CORRECTION01
      = empty
    git diff <C2_boundary>..<C3_verify> -- ACT-body-CORRECTION02
      = empty
    git diff <C3_verify>..HEAD -- <this HANDOFF only>
      = exactly the HANDOFF file

  Final 10-pair oracle:
    factory-closure-status-check on 10-row manifest reports
    PAIR_OK=10 PAIR_FAIL=0 STATUS=PASS VERDICT=PASS.

  Patch hygiene:
    git diff --check <C2_boundary>..HEAD = empty.
    git diff --check <CORRECTION02_entry>..HEAD = empty
    (after C4 close).

SCOPE

  All three repairs are bounded to:
    - tools/quality/factory-closure-status-test.HC (rewritten)
    - scripts/quality/factory-closure-status-test-cases.tsv
      (new static TSV fixture)
    - scripts/quality/factory-closure-status-test-cases.sh
      (DELETED)
    - scripts/quality/factory-closure-status-check-test.sh
      (reduced to 16 LOC pure dispatch)
    - docs/factory/SHELL-BUDGET.tsv (updated)
    - docs/factory/act-handoff-map.tsv (self-row added at C0)
    - docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
      CORRECTION02.md (the ACT itself; C0 AUTH only)
    - docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-
      EXTENSIBLE01-CORRECTION02.md (this file; C4 CLOSE only)
    - 4 CORRECTION01 evidence files (whitespace-cleaned by
      forward-only replacement)

  Out of scope (per F14):
    - docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
      CORRECTION01.md (closed ACT body; immutable)
    - docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-
      EXTENSIBLE01-CORRECTION01.md (closed HANDOFF; immutable)
    - evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
      CORRECTION01/* (closed ACT evidence; immutable per F14;
      only forward-only whitespace-clean replacement applied)

RESIDUE

  - PolyC's Main in this runtime does not receive argv (argc=0).
    The PolyC test binary reads configuration via the env vars
    FACTORY_CLOSURE_STATUS_CHECKER and FACTORY_CLOSURE_STATUS_CASES.
    The shell wrapper sets these. If the binary is invoked
    directly without env vars set, it falls back to repository-
    relative defaults.

  - The full PolyC test binary is ~400 LOC, larger than the
    previous 140-LOC thin-driver. This is a deliberate trade:
    F-POLYC-TOOLS substantive logic MUST be in PolyC, and the
    matrix logic is substantive.

  - The TSV fixture uses a sentinel "<empty>" string for
    zero-byte manifests. The PolyC parser recognizes this and
    writes 0 bytes. This avoids a trailing-tab whitespace issue
    that git diff --check would otherwise flag.

  - The 49-LOC shell engine file was deleted at C2. It cannot
    be grandfathered in LEGACY-NON-POLYC-TOOLS.tsv because it
    no longer exists in the tree.

NEXT ACT

  After this ACT closes, the Factory closure oracle's authority
  is restored. Subsequent Factory ACTs may proceed:

    ACT-POLYC-LIBTOS-SYMBOL-GAPS01
    ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
    ACT-POLYC-SELFHOST-SURFACE-RECON03

  No further blocked-by-this-ACT residue.

ENTRY IDENTITY (C4 CLOSE)

  git branch --show-current = main
  HEAD before this HANDOFF addition: c37d5fa2625d478288e2bfd19c846ef937e92181
  Worktree: clean (after this commit)
