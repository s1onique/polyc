# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01

## Identity

- ACT id: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01
- Phase:  C0 AUTH (authorization; no production mutation)
- Board authorization: granted (post-closure reviewer verdict
  recorded at evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
  CORRECTION01/c0/c0-postclosure-review-disposition.txt, commit
  f640d46)
- Entry identity:
    git branch --show-current = main
    git rev-parse HEAD        = f640d4618c8b68fc9c8aa533e396a6ca1e400df9
    git status --short        = clean

## Predecessor

- ACT id: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01
- Open:   f8ae7ac
- Close:  985ebbd
- HANDOFF verdict recorded at close: PASS_TRUE_GREEN
- Post-closure reviewer verdict: FALSE_GREEN
- Reclassification per this ACT: PREDECESSOR_RECLASSIFICATION = FALSE_GREEN

The closed ACT (f8ae7ac..985ebbd) and its HANDOFF are historical
evidence per F14. They are NOT modified by this ACT. The HANDOFF
continues to claim PASS_TRUE_GREEN at the textual level. The
correctness verdict is recorded in this ACT's evidence tree.

## Scope (bounded)

This ACT repairs four mechanically-confirmed defects in the C3/C4
evidence machinery of ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01
without rewriting its closed evidence.

### P0-1 — AC07 baseline equivalence

The C3 evidence file
`evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01/c3/c3-baseline-equivalence.txt`
contains an error artifact (`RC=2, REASON=manifest not found`),
not a real predicate.

Mechanical reproduction against the committed tree confirms that
both the OLD checker (712a3b7:scripts/quality/factory-closure-
status-check.sh) and the NEW checker (HEAD) report
`PAIR_OK=7 PAIR_FAIL=0 STATUS=PASS VERDICT=PASS` against the
7-row legacy manifest constructed from the pre-C2 commit's
MANAGED_ACTS hardcoded list. The defects is purely C3 test
harness; the migration equivalence is mechanically true.

Required C2/C3 evidence regeneration:

  c2/c2-old-vs-new-baseline.tsv      -- 7-row manifest (real paths)
  c2/c2-old-checker-baseline.txt     -- OLD checker output
  c2/c2-new-checker-baseline.txt     -- NEW checker output
  c2/c2-baseline-diff.txt            -- counter-by-counter diff
                                        OLD vs NEW
  c3/c3-ac07-baseline-equivalence.txt -- required predicates:
    OLD_CHECKER_PAIR_OK=7
    NEW_CHECKER_PAIR_OK=7
    OLD_CHECKER_PAIR_FAIL=0
    NEW_CHECKER_PAIR_FAIL=0
    LEGACY_ENUMERATION_EQUIVALENCE=PASS
    OLD_ORACLE_COMMIT=712a3b7
    NEW_ORACLE_COMMIT=f640d46
    MANIFEST_COMMIT=712a3b7
    OLD_MANAGED_ACTS_COUNT=7
    NEW_MANIFEST_DATA_ROWS=7
    PAIR_IDENTITY_DIFFERENCES=0

### P0-2 — N06 non-short-circuit duplicate classification

The new checker's pipeline ordering has three early `continue`
statements (ACT path, HANDOFF path, pair key) that prevent
`DUPLICATE_PAIRS` from ever firing. For an exact-duplicate row
`(ACT_A, HANDOFF_A)`, the second occurrence hits ACT-path dedup
first and continues before the pair-key check runs.

Required checker fix: collect all three duplicate dimensions
without early `continue`, OR add an explicit `else` branch that
records all dimensions for every row, OR remove the short-circuit
entirely and let the row reach the file/metadata checks too.

Required C2/C3 evidence:

  c2/c2-n06-non-short-circuit.sh     -- N06 fixture script
                                        that constructs a
                                        manifest where all
                                        three duplicate
                                        dimensions SHOULD
                                        fire simultaneously
  c3/c3-n06-non-short-circuit.txt    -- NEW checker output on
                                        N06 fixture; required:
      DUPLICATE_ACT_PATHS=1
      DUPLICATE_HANDOFF_PATHS=1
      DUPLICATE_PAIRS=1
      DUPLICATE_ACT_PATH_DETECTED=YES
      DUPLICATE_HANDOFF_PATH_DETECTED=YES
      DUPLICATE_PAIR_DETECTED=YES
      DUPLICATE_CLASSIFICATION_IS_NON_SHORT_CIRCUITING=YES
      STATUS=FAIL
      RC=1

  c2/c2-n01-n05-regression.txt      -- all prior negative
                                        controls (N01..N05)
                                        still fire correctly
                                        after the dedup fix

### P0-3 — C4 self-judgment via HANDOFF exclusively

C4 of the predecessor ACT appended `## Status: PASS_TRUE_GREEN`
to the ACT body. The closure oracle must not require verdict
metadata inside the ACT being judged.

Required checker fix: remove `count_status_headings` /
`extract_status_token` / `MALFORMED_ACT_STATUS` /
`EXACT_VERDICT_MISMATCHES` (replaced by ACT-vs-HANDOFF HANDOFF-
verdict extraction as the sole authoritative source). The HANDOFF
VERDICT becomes the only verdict token checked.

After the fix, C4 of any future ACT must be able to flip FAIL to
PASS by adding only the HANDOFF file; the ACT body must remain
unchanged from C0.

Required C2/C3 evidence:

  c2/c2-self-row-c3-red.txt         -- HANDOFF absent,
                                        self pair FAIL,
                                        overall FAIL
  c3/c3-self-row-c4-green.txt       -- HANDOFF added,
                                        self pair PASS,
                                        overall PASS
  c3/c3-act-body-unchanged.txt      -- SHA-256 of
                                        docs/acts/ACT-POLYC-
                                        FACTORY-CLOSURE-
                                        ORACLE-EXTENSIBLE01-
                                        CORRECTION01.md
                                        identical between
                                        C0 commit and C4 commit
  c3/c3-checker-unchanged.txt       -- SHA-256 of
                                        scripts/quality/
                                        factory-closure-
                                        status-check.sh
                                        identical between
                                        C2 freeze commit and
                                        C4 commit
  c3/c3-manifest-unchanged.txt      -- SHA-256 of
                                        docs/factory/
                                        act-handoff-map.tsv
                                        identical between
                                        C2 freeze commit and
                                        C4 commit

### P0-4 — F-POLYC-TOOLS PolyC test binary

The 123-LOC shell test harness
`scripts/quality/factory-closure-status-check-test.sh` violates
F-POLYC-TOOLS (DOCTRINE §27). It is replaced by:

  tools/quality/factory-closure-status-test.HC
      -- PolyC test executable implementing the substantive
         fixture generation and assertion engine

  scripts/quality/factory-closure-status-check-test.sh
      -- Reduced to ≤50-LOC dispatch wrapper:
         - verify executable present (build if needed)
         - exec build/factory-closure-status-test "$@"

F-POLYC-TOOLS is not yet activated at binding enforcement (per
AGENTS.md F-POLYC-TOOLS pointer: NOT YET LANDED — C2.9 residue).
This ACT brings this specific test into compliance so that when
the binding check is wired in, no exception is needed.

Required C2/C3 evidence:

  c2/c2-polyc-test-loc.txt          -- wc -l on the new
                                        PolyC test file (must
                                        be a real .HC file
                                        whose build artifact
                                        contains the test
                                        logic)
  c2/c2-shell-dispatch-loc.txt      -- wc -l on the reduced
                                        shell wrapper (must
                                        be <= 50)
  c3/c3-shell-budget-gate.txt       -- shell-budget-gate.sh
                                        output (PASS with
                                        the reduced shell)
  c3/c3-polyc-test-build.txt        -- build log for
                                        tools/quality/
                                        factory-closure-
                                        status-test.HC

## Out of scope

This ACT SHALL NOT:

  - modify the closed ACT body or HANDOFF of ACT-POLYC-
    FACTORY-CLOSURE-ORACLE-EXTENSIBLE01 (F14);
  - modify any closed evidence file under
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01/
    (F14);
  - change compiler behavior;
  - change static-function linkage semantics;
  - repair libtos symbols;
  - introduce a new substantive shell application
    (P0-4 requires the OPPOSITE: replace substantive shell
    with PolyC);
  - expand the bounded managed universe beyond what is
    required for the four repairs;
  - silently inflate the previous verdict in the historical
    HANDOFF.

## Target verdict

```
PREDECESSOR_RECLASSIFICATION = FALSE_GREEN

CORRECTION01_TARGET_VERDICT =
    PASS_TRUE_GREEN
        iff every repair AC and self-closure predicate
        is mechanically proven at C3, AND C4 introduces
        only the HANDOFF (no ACT body, checker, or
        manifest mutation),
    otherwise
        PASS_ENGINEERING_HALT_EVIDENCE_DEFECTS
        or appropriate HALT token.
```

This ACT MAY earn PASS_TRUE_GREEN itself if its own
closure is honestly demonstrated. The previously-closed
ACT is reclassified to FALSE_GREEN; this ACT is judged
on its own merits.

## Successor blocking

```
BLOCKS:
  ACT-POLYC-LIBTOS-SYMBOL-GAPS01
  ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
  ACT-POLYC-SELFHOST-SURFACE-RECON03
```

The closure oracle's own authority depends on its closure
being honestly demonstrated. Downstream ACTs are gated
until this ACT closes.

## Required sequence

```
C0 AUTH     this document committed; no production mutation
C1 RED      reproduce the four defects against the
            committed tree; capture RED evidence files
C2 IMPL     apply checker fix (P0-2 + P0-3); write PolyC
            test binary (P0-4); regenerate baseline
            equivalence evidence (P0-1); freeze checker
            and manifest at C2
C3 VERIFY   re-run all controls; demonstrate C4 transition
            via HANDOFF only; record SHA-256 of unchanged
            ACT body, checker, manifest between C0/C2/C4
C4 CLOSE    add HANDOFF only; no other mutations;
            record terminal verdict
```

## Halt discipline

This ACT halts with one of the following tokens if:

  HALT_RED_NOT_REPRODUCED         any P0 defect not
                                   reproducible against
                                   the committed tree
  HALT_SCOPE_EXPANSION_REQUIRED   bounded scope insufficient
                                   to repair all four defects
  HALT_POLYC_BUILD_FAILED         the new PolyC test
                                   binary does not build or
                                   produce a working
                                   executable
  HALT_CLASSIFICATION_GOVERNANCE  (this disposition itself)

Otherwise the agent continues into C1 RED per F-CONVERGENCE.

