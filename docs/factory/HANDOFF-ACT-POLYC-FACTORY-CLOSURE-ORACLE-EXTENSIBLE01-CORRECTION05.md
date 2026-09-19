HANDOFF for ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05

VERDICT

PASS_TRUE_GREEN

  This ACT prospectively requalifies the Factory closure oracle
  lineage. It does NOT rewrite any historical FALSE_GREEN verdict;
  CORRECTION01/02/03 remain historically FALSE_GREEN per the
  reviewer's reclassification by CORRECTION04.

  This ACT proves the lifecycle ordering invariant that CORRECTION04
  could not prove: a managed ACT whose self-row is registered
  BEFORE verification, with the HANDOFF absent, produces a
  FAILING witness at C3; the same frozen checker over the same
  frozen manifest produces a PASSING verdict at C4 once the
  HANDOFF appears. The ACT body itself gained no post-hoc verdict
  field — the PASS_TRUE_GREEN verdict lives only in this HANDOFF.

IDENTITY

  ACT: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05
  Predecessor: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04
    HEAD at predecessor close: 0e6c36e2a34867f5a2454fdafa0f6d4c6699c2ed
    Verdict:                    PASS_FALSE_GREEN_HALTTED_AT_HANDBOFF_LEVEL

  This ACT commit topology (5 commits, append-only):
    C0 AUTH:                   4c40a53
    C1 RED/CONTRACT:           b96b0ec
    C2 SELF-REGISTER/FREEZE:   9eb459d
    C3 VERIFY:                 49304d3
    C4 CLOSE:                  <this commit>

  PATCH_HYGIENE_BASELINE       = 0e6c36e (binding predecessor HEAD, frozen at C0)
  ENTRY_HEAD                   = 0e6c36e
  WORKTREE_STATUS_AT_CLOSE     = clean

ROOT CAUSE / FINDING

  CORRECTION04 closed with PASS_FALSE_GREEN_HALTTED_AT_HANDBOFF_LEVEL
  after falsifying two CORRECTION03 predicates:

    (a) the authorized patch-hygiene predicate
        `git diff --check 0665ada..HEAD`
        was FALSE due to historical EOF blanks preserved under F14
        (a tautological impossibility of the chosen baseline, not
        a corruption of the F14 restoration itself);

    (b) the manifest self-row was added in C0 of CORRECTION03
        even though the same ACT body declared that mutation
        out-of-scope (F15 self-authorization defect).

  CORRECTION04's narrower verdict was correct: it preserved
  mechanical GREEN for the oracle machinery, reclassified the
  lineage's truth status, and explicitly identified that the
  missing governance proof was lifecycle ordering — registration
  of the closing ACT as a managed pair BEFORE verification.

  CORRECTION05 provides exactly that missing proof, without
  repairing the historical predicate or rewriting any closed
  artifact.

PROSPECTIVE PATCH-HYGIENE BASELINE

  ACT §6 froze:
    PATCH_HYGIENE_BASELINE = 0e6c36e (binding predecessor HEAD)

  Terminal predicate:
    git diff --check 0e6c36e..HEAD

  Observed at C3 commit (49304d3): clean.
  Observed at C4 commit (this commit): clean.

  HISTORICAL_0665ada_PREDICATE = FALSE (acknowledged, untouched)
  CORRECTION05_PROSPECTIVE_RANGE = CLEAN

  No .gitattributes whitespace exception is introduced. No
  historical evidence is mutated. No alternate baseline is
  substituted.

RED

  c1/c1-self-registration-red.txt:
    Pre-self-register universe: MANIFEST_ROWS=13 PAIR_OK=13
    PAIR_FAIL=0 STATUS=PASS. CONFIRMED self-registration
    RED condition (no FAIL yet, so the 'registered-before-C3
    fails on missing HANDOFF' pattern is meaningful to introduce).

  c1/c1-current-oracle-regression.txt:
    13/13 oracle PASS; 12/12 PolyC regression PASS; PolyC test
    authority confirmed (factory-closure-status-test.HC exists,
    shell dispatch wrapper is 16 LOC).

  c2/c2-self-row-red.txt:
    After appending exactly one CORRECTION05 row to the manifest
    (no HANDOFF):
      MANIFEST_ROWS=14
      PAIR_OK=13
      PAIR_FAIL=1
      STATUS=FAIL
    Single failing pair: CORRECTION05, cause MISSING_HANDOFF_FILE.

  c3/c3-self-row-load-bearing.txt:
    Same numbers re-observed from a fresh committed C2 boundary:
    MANIFEST_ROWS=14 PAIR_OK=13 PAIR_FAIL=1. UNRELATED_PAIR_FAIL=0.

  c3/c3-freeze-verification.txt:
    CHECKER/MANIFEST/ACT_BODY/POLYC_TEST/SHELL_WRAPPER/CASES_TSV
    SHA-256 hashes are identical between C2 and C3.

IMPLEMENTATION

  No code was changed. This ACT mutated only:

    - docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md
      (new ACT body, committed at C0 AUTH)
    - docs/factory/act-handoff-map.tsv
      (exactly one row appended for the CORRECTION05 self-pair,
       committed at C2 SELF-REGISTER/FREEZE)
    - evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05/**
      (this ACT's own evidence namespace)
    - docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md
      (this file, committed at C4 CLOSE)

  No checker mutation, no test implementation mutation, no
  Makefile mutation, no SHELL-BUDGET mutation, no old evidence
  mutation, no production-tree mutation.

C3 TRANSITION PROOF

  Pre-C3 (committed C2):
    CHECKER  1d69e962e16d253b6c9249d6900c5d5a43236faa78458756c54e2e26923f0bfa
    MANIFEST a4848bf51709bf40d49cd01a458197eb173c718de19a4d543a104c1792c5f51c
    ACT_BODY 5d9575628e2d2f8f8e710f00c7ced9717f8fd83afe4727f4174c651bc32e74fb
    POLYC_TEST 88943f4ff6897c60244b58343a1767cdb952ea70065828dc501228b4bcf755ad
    SHELL_WRAPPER 48fd9dab14c4892f20b7e80d5da93531c4cb43ecb67d7cf1c97890a55e3d3b92
    CASES_TSV 954c4eb814e5eebb91ee95de238b90e66815ddbb4c75cbd14377dfe760332634

  At C3 (worktree == committed C2, no edits):
    All six hashes identical. C2_TO_C3_FROZEN=YES.

C4 TRANSITION PROOF

  With the HANDOFF present, before C4 commit:

    $ bash scripts/quality/factory-closure-status-check.sh ; echo $?
    ...
    OK    ... (13 rows)
    OK    docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md   PASS_TRUE_GREEN
    ...
    MANIFEST_ROWS=14
    PAIR_OK=14
    PAIR_FAIL=0
    STATUS=PASS
    VERDICT=PASS
    exit=0

  Self-pair flips: HANDOFF_ABSENT -> HANDOFF_PRESENT.
  The unchanged checker over the unchanged manifest accepts the
  self-pair that previously failed.

  C3_TO_C4_HANDOFF_ONLY=YES
  C3_TO_C4_CHANGED_FILE_COUNT=1

  The C3..C4 diff will be checked post-commit and must contain
  exactly:
    A docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md

GATES (state at this C4 commit)

  factory-closure-status-check:
    PAIR_OK=14 PAIR_FAIL=0 STATUS=PASS VERDICT=PASS

  factory-closure-status-check-test:
    12/12 PASS

  factory-append-only-test:
    11/11 PASS

  Prospective patch hygiene (0e6c36e..HEAD):
    clean

  F14 conservation:
    closed CORRECTION0[1..4] evidence unchanged
    closed HANDOFFs unchanged
    closed ACT bodies (other than CORRECTION05 itself) unchanged

  F-NO-PYTHON:
    NEW_PYTHON_SOURCES=0 NEW_PYTHON_INVOCATIONS=0 NEW_PYTHON_VIOLATIONS=0

  F-POLYC-TOOLS:
    NEW_SUBSTANTIVE_NON_POLYC_TOOLS=0 NEW_SHELL_TOOLS=0
    POLYC_TEST_AUTHORITY_UNCHANGED=YES

SCOPE (bounded)

  This ACT mutated:
    - docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05.md (C0)
    - evidence/.../CORRECTION05/c0/c0-entry-identity.txt (C0)
    - evidence/.../CORRECTION05/c1/**.txt (C1)
    - docs/factory/act-handoff-map.tsv (C2 self-row, EXPLICITLY
        authorized at C1)
    - evidence/.../CORRECTION05/c2/**.txt (C2)
    - evidence/.../CORRECTION05/c3/**.txt (C3)
    - docs/factory/HANDOFF-...-CORRECTION05.md (C4, this file)

  Out of scope (per F7/F15):
    - scripts/quality/factory-closure-status-check.sh
    - scripts/quality/factory-closure-status-check-test.sh
    - scripts/quality/factory-closure-status-test-cases.tsv
    - tools/quality/factory-closure-status-test.HC
    - All closed ACT bodies and HANDOFFs (F14 immutability)
    - docs/ROADMAP.md (no closure signal required)
    - All production trees (src/, tools/bootstrap/)
    - Any pending Factory roadmap ACT

RESIDUE

  None at the closure-oracle lineage level. The lineage is now
  prospectively requalified; future ACTs may follow the
  authorize → register → freeze → verify-missing-HANDOFF →
  close-by-adding-HANDOFF-only lifecycle.

  Historical reclassifications remain:
    CLOSURE-ORACLE-EXTENSIBLE01     historical close = FALSE_GREEN
    CORRECTION01                    historical close = FALSE_GREEN
    CORRECTION02                    historical close = FALSE_GREEN
    CORRECTION03                    historical close = FALSE_GREEN
    CORRECTION04                    terminal = PASS_FALSE_GREEN_HALTTED_AT_HANDBOFF_LEVEL

  These are F14 immutable facts. They do NOT block forward use
  of the closure oracle machinery; they DO prevent claiming
  those historical ACTs were retroactively green.

LIFECYCLE

  C0 (4c40a53):  ACT body + c0/ entry evidence. No manifest.
  C1 (b96b0ec):  c1/ RED/CONTRACT evidence. No manifest.
  C2 (9eb459d):  c2/ self-registration + freeze. One manifest row.
  C3 (49304d3):  c3/ verification. No manifest, no ACT, no checker,
                 no test, no HANDOFF.
  C4 (<this>):   HANDOFF only. No manifest, no ACT, no checker,
                 no test, no c4/ evidence (per §24, the HANDOFF
                 itself records C4).

  Commit topology = 5 commits, exactly as ACT §44 specifies.
  No post-C4 hygiene commit.

ENTRY IDENTITY (C4 CLOSE)

  git branch --show-current = main
  HEAD before this commit:  49304d31dde6bbb116a05dab02c4c689a9a5bdb2 (C3 VERIFY)
  Worktree:                 clean
  This commit:              <queryable via git log>

  Mandatory AC table:
    evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION05/c3/mandatory-ac-status.tsv
    MANDATORY_TOTAL=32
    MANDATORY_PASS=32
    MANDATORY_FAIL=0
    MANDATORY_UNKNOWN=0
    MANDATORY_MISSING_EVIDENCE=0
