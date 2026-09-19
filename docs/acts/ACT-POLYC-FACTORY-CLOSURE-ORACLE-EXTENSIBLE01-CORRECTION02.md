# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02

## Identity

- ACT id: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02
- Phase:  C0 AUTH (authorization; no production mutation)
- Predecessor: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01
- Predecessor verdict recorded: PASS_TRUE_GREEN (rejected by reviewer)
- Reclassification of predecessor: FALSE_GREEN
- Reviewer-disposition evidence:
  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02/
    c0/c0-predecessor-review-disposition.txt
- Entry identity:
    git branch --show-current = main
    git rev-parse HEAD        = b9a43f854ad8f82dd4c95bfabf6f71490f91e616
    git status --short        = clean (modulo unstaged whitespace fixes
                                  to CORRECTION01 evidence files; those
                                  are committed in C2 of this ACT)

## Predecessor in scope

- ACT id: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01
- Open:   0665ada
- Close:  b9a43f8 (the C4 close-correction commit; treated as the
          authoritative close commit of CORRECTION01)
- HANDOFF verdict recorded at close: PASS_TRUE_GREEN
- Post-closure reviewer verdict (this ACT's disposition): FALSE_GREEN
- Reclassification per this ACT: PREDECESSOR_RECLASSIFICATION = FALSE_GREEN

The closed CORRECTION01 ACT and its HANDOFF are historical evidence
per F14. They are NOT modified by this ACT. The HANDOFF continues to
claim PASS_TRUE_GREEN at the textual level. The correctness verdict
is recorded in this ACT's evidence tree.

The previous-predecessor (ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01)
remains reclassified FALSE_GREEN (recorded at f640d46).

## Scope (bounded)

This ACT repairs three mechanically-confirmed defects in the
CORRECTION01 ACT without rewriting its closed evidence. The repairs
are surgical and bounded; no Factory invariant is changed.

### P0-1 -- F-POLYC-TOOLS substantive logic moved into PolyC

CORRECTION01 P0-4 produced a PolyC binary (factory-closure-status-test)
that is a thin driver invoking a 49-LOC shell file
(factory-closure-status-test-cases.sh). The shell file holds the
substantive 12-case matrix, including `expect()`, fixture
construction via printf, checker invocation, RC + grep matching,
and PASS/FAIL aggregation. This is exactly the LOC-cap factorization
F-POLYC-TOOLS forbids: the shell stays under 50 LOC by splitting,
not by being bootstrap glue.

Repair:

  - Move the 12-case matrix definition into a static TSV fixture
    file (factory-closure-status-test-cases.tsv) that contains NO
    executable logic -- only test case rows.
  - Move fixture construction, checker invocation, RC matching,
    grep matching, PASS/FAIL aggregation, and final verdict emission
    into the PolyC binary at tools/quality/factory-closure-status-test.HC.
  - Delete scripts/quality/factory-closure-status-test-cases.sh
    entirely (its job is taken over by the TSV fixture + PolyC reader).
  - The shell wrapper scripts/quality/factory-closure-status-check-test.sh
    becomes a pure dispatch `exec` of the PolyC binary; it stays <=50 LOC
    because it was already a thin wrapper, but its content becomes even
    thinner (no string interpolation, no argument building).

### P0-2 -- Real C3 commit; monotonic proof against committed boundary

CORRECTION01 claimed "between C2 and C3, ACT body / checker /
manifest were unchanged" but its evidence used the boundary
`git diff 1054ae2..HEAD`. C2 is the C2 IMPL/FREEZE commit. The
actual CORRECTION01 trajectory has a C2b commit (7fb7621) between
C2 (1054ae2) and C4 (8efc029); the C3 "VERIFY" was not its own
committed boundary -- it was captured into the C2b commit. The
reviewer correctly identifies this as an "internally impossible"
phase binding.

Repair:

  - This ACT creates a real, named C3 commit between a real, named
    C2b-equivalent and a real, named C4. The C3 commit MUST be a
    pure-evidence commit (no production mutation); only new files
    added under evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-
    EXTENSIBLE01-CORRECTION02/c3/ (and possibly white-space fixes
    to existing CORRECTION01 evidence -- see P0-3 below).
  - The monotonic proof is re-derived against real committed
    boundaries:
      git diff <C2b_commit>..<C3_commit>  =  empty for checker,
                                            ACT body, manifest
      git diff <C3_commit>..<C4_commit>  =  exactly the HANDOFF
                                            file (and only the
                                            HANDOFF file)
  - The C2b commit of CORRECTION01 (7fb7621) is treated as the
    frozen starting boundary for this ACT's monotonic proof. The
    C2 (1054ae2) is documented as "IMPL/FREEZE; before the missed-
    manifest-row correction".
  - The new C3 commit's SHA is recorded and used as the
    reference for the C3/C4 monotonic proof.

### P0-3 -- Patch hygiene: `git diff --check` clean across the
CORRECTION01+CORRECTION02 cumulative range

CORRECTION01 evidence files contain trailing-blank-line whitespace
errors that `git diff --check` reports as failures:

  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01/
    c2/c2-p02-n01-n05-regression.txt:29: new blank line at EOF.
    c3/c3-act-body-unchanged.txt:10: new blank line at EOF.
    c3/c3-checker-unchanged.txt:6: new blank line at EOF.
    c3/c3-manifest-unchanged.txt:6: new blank line at EOF.

These are byte-level hygiene errors in CORRECTION01 evidence.
Per F14, CORRECTION01 evidence is immutable -- its content cannot
be rewritten. But a forward-only correction is allowed: replace
the bad files with byte-equivalent (modulo trailing-blank-line)
versions committed at a new boundary, and mechanically demonstrate
the equivalence.

Repair:

  - In this ACT's C2 phase, replace the four trailing-blank-line
    files with whitespace-clean versions of identical content. The
    replacement is recorded as a CORRECTION02 phase-C2 commit with
    a documented "byte-equivalent content (modulo trailing blank
    line)" witness.
  - In this ACT's C3 phase, write all new evidence files with
    no trailing blank lines. Each new file ends with its final
    content character (no trailing LF after a blank line).
  - The cumulative range `git diff --check <entry_of_this_ACT>..HEAD`
    MUST return empty after this ACT's C4 close.

### What is OUT of scope

  - The closure oracle itself
    (scripts/quality/factory-closure-status-check.sh) is correct
    and is NOT modified by this ACT. The checker is frozen at
    SHA-256 1d69e962e16d253b6c9249d6900c5d5a43236faa78458756c54e2e26923f0bfa.
  - The current 10-row manifest is correct; not modified.
  - The CORRECTION01 ACT body is immutable per F14; not modified.
  - The CORRECTION01 HANDOFF continues to claim PASS_TRUE_GREEN
    at the textual level; not modified.
  - The CORRECTION01 evidence files are immutable at the content
    level; trailing-blank-line fixes are made by replacement, not
    by mutation of the originals.

## Entry gate

Required preconditions for entering C2 IMPL/FREEZE:

  - C0 review-disposition evidence file recorded.
  - Real F-POLYC-TOOLS test binary compiled and passes 12/12.
  - Real C3 commit exists with monotonic proof files
    (c3/c3-act-body-unchanged.txt etc.) committed against
    the 7fb7621 boundary.

## Phase plan

  - C0 AUTH (this commit): ACT body + scope + entry identity.
  - C1 RED (committed next):
      c1-red-p01-polyc-engine.txt
        Real PolyC binary parsing the TSV fixture, running the
        12 cases, and aggregating PASS/FAIL.
      c1-red-p02-monotonic-rebuild.txt
        Real demonstration that the previous phase binding was
        broken (the diff-with-empty + committed-blob-SHA
        contradiction).
      c1-red-p03-whitespace-fix.txt
        Real demonstration of the four trailing-blank-line files.
  - C2 IMPL/FREEZE (committed next):
      - New PolyC binary at tools/quality/factory-closure-status-test.HC
        that parses factory-closure-status-test-cases.tsv and
        owns all test logic.
      - New TSV fixture at scripts/quality/factory-closure-status-test-cases.tsv
        containing 12 test-case rows.
      - Delete scripts/quality/factory-closure-status-test-cases.sh
        (its job is gone; the engine is in PolyC).
      - Replace four whitespace-bad CORRECTION01 evidence files
        with byte-equivalent whitespace-clean versions.
      - Update Makefile if needed.
      - Update SHELL-BUDGET.tsv (TINY entry for the new TSV;
        remove the 49-LOC shell entry since the file is deleted).
      - Update tools/quality/factory-closure-status-test.HC header
        documentation.
  - C3 VERIFY (committed as a real commit, not just an
    evidence-capture in C2b):
      - Monotonic proof re-derived against real boundaries:
          git diff <C2_boundary>..<C3_commit> -- checker
            = empty
          git diff <C2_boundary>..<C3_commit> -- manifest
            = empty
          git diff <C2_boundary>..<C3_commit> -- ACT-body-CORRECTION01
            = empty
          git diff <C2_boundary>..<C3_commit> -- ACT-body-CORRECTION02
            = empty
      - 12-case regression through new PolyC binary: PASS.
      - Final-10-pair oracle: PAIR_OK=10 PAIR_FAIL=0 STATUS=PASS.
      - `git diff --check <entry>..HEAD` = clean.
      - C3 commit is its own boundary; only new files under
        evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
        CORRECTION02/c3/ are added between C2 and C3.
  - C4 CLOSE (final commit):
      - Add HANDOFF file only. No other mutations.
      - The monotonic proof is extended to show
          git diff <C3_commit>..<C4_commit>
        = exactly the HANDOFF file path.

## Halt tokens

  - HALT_RED_NOT_REPRODUCED
  - HALT_SCOPE_EXPANSION_REQUIRED
  - HALT_PHASE_BINDING_INCONSISTENT (raised if any monotonic
    proof is internally inconsistent)

## Production semantic changes

  - FORBIDDEN: any change to scripts/quality/factory-closure-status-check.sh.
  - FORBIDDEN: any change to docs/factory/act-handoff-map.tsv.
  - FORBIDDEN: any change to the closure oracle's runtime behavior.

## IR / ABI / LLVM authorization

  - NONE.
