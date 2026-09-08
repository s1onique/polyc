HANDOFF -- ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION01
===============================================================

VERDICT
-------
PASS

ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION01 closes the
three P0/P1 defects the reviewer raised against the predecessor
ACT-POLYC-FACTORY-STATUS-RECONCILIATION's closure posture:

  P0 #1 (independent bidirectional completeness)
    -- the predecessor checker iterated only over manifest rows
       and silently skipped managed ACT/HANDOFF pairs that were
       not in the manifest, while still printing STATUS=PASS.
  P0 #2 (closure-summary overclaims)
    -- the predecessor's UNMAPPED_* / EXTRA_* claims were
       documentary assertions, not mechanically proven invariants;
       the predecessor checker did not emit those counters.
  P1 (POSIX shell contract)
    -- the predecessor checker used `declare -A`, a Bash-only
       extension, in a file declaring `#!/bin/sh` and invoked
       through `sh`. Under `dash` it failed with rc=127.

IDENTITY
--------

Entry:    c014d1f8f561dba18ecdad2d53035174408d9a47
RED:      c014d1f8f561dba18ecdad2d53035174408d9a47 (C1: ACT contract + RED-A/RED-B/RED-C)
IMPL:     15070c3 (C2 IMPL: rewritten checker + 18-test suite + closure evidence)
DOCS:     (this commit)
HEAD:     (this commit)

Total commits for this ACT: 3 (C1 + C2 + DOCS in this commit). At cap.

ROOT CAUSE
----------

The predecessor oracle was self-referential: it asked the manifest
what it should validate. With one manifest row removed while all 5
ACT/HANDOFF files remained on disk, the oracle reported
PAIR_OK=4 PAIR_FAIL=0 STATUS=PASS rc=0 and the closure summary
asserted the missing pair was "unmapped" only in prose. The four
UNMAPPED_*/EXTRA_* counters were not produced by the checker at
all.

The repair replaces "manifest-driven soft validation" with two
authorities and one mechanical reconciliation:

  1. bounded managed universe (hard-coded 5 ACTs + 5 HANDOFFs)
  2. manifest pairing map
  3. checker that computes set differences independently and
     emits them as part of its standard output

RED MATRIX
----------

RED-A   5 ACT/HANDOFF files on disk, 4-row manifest (correction02
        row removed). Predecessor checker returned rc=0 with
        PAIR_OK=4 and STATUS=PASS. New checker returns rc=1 with
        UNMAPPED_MANAGED_ACTS=1 and UNMAPPED_MANAGED_HANDOFFS=1.
        Captured at
        evidence/factory-status-reconciliation-correction01/{red-a,impl/red-a-replay}/.

RED-B   The four UNMAPPED_* / EXTRA_* counters are not emitted by
        the predecessor. Observed emitted counters:
          MANIFEST_ROWS, MANIFEST_PARSE_ERRORS,
          DUPLICATE_*, MISSING_*, MALFORMED_*, EXACT_VERDICT_MISMATCHES,
          PAIR_OK, PAIR_FAIL.
        Captured at evidence/factory-status-reconciliation-correction01/red-b/.

RED-C   Predecessor uses `declare -A`. Under dash:
          dash scripts/quality/factory-closure-status-check.sh
          scripts/quality/factory-closure-status-check.sh: 58: declare: not found
          rc=127.
        Captured at evidence/factory-status-reconciliation-correction01/red-c/.

All three REDs were captured BEFORE any production change (F3).

IMPLEMENTATION
--------------

scripts/quality/factory-closure-status-check.sh
  - rewritten as genuine POSIX /bin/sh; no `declare -A`
  - hard-codes the 5-pair bounded managed universe
  - emits MANAGED_ACTS, MANAGED_HANDOFFS,
    UNMAPPED_MANAGED_ACTS, UNMAPPED_MANAGED_HANDOFFS,
    EXTRA_MANIFEST_ACTS, EXTRA_MANIFEST_HANDOFFS as standard
    output (R2)
  - fails (rc=1, STATUS=FAIL) on any non-zero UNMAPPED_* / EXTRA_*
    (R1, R2)
  - same exit semantics under both `sh` and `dash` (R3, R6)

evidence/factory-status-reconciliation-correction01/n1-n18/run.sh
  - 18 negative tests + baseline = 52 assertions
  - N16: bounded completeness (4-row manifest) -> UNMAPPED_*=1
  - N17: mirror negative (out-of-managed extra row) -> EXTRA_*=1
  - N18: POSIX shell portability (dash) -> PASS
  - all 52 assertions PASS, 0 FAIL (rc=0)

GATES
-----

sh  scripts/quality/factory-closure-status-check.sh  rc=0
dash scripts/quality/factory-closure-status-check.sh rc=0
sh  scripts/quality/gate-fast.sh                     rc=0
bash .githooks/pre-commit                            rc=0
git diff --check                                     rc=0

Pre-commit regression (caught by the hook on the clean tree):
  - mutate a HANDOFF verdict token       -> rc=1 (EXACT_VERDICT_MISMATCHES=1)
  - reduce manifest from 5 rows to 4     -> rc=1 (UNMAPPED_*=1)
  - restore                              -> rc=0

SCOPE
-----

In scope (closed by this ACT):
  - factory closure-status checker rewritten as genuine POSIX sh
  - independent enumeration of the bounded 5-pair managed universe
  - mechanical emission of the four set-difference counters
  - N16 / N17 / N18 negative tests
  - closure HANDOFF and ACT status update for this CORRECTION01

Out of scope (residue):
  - extending the bounded universe to other ACT prefixes
    (ir-boundary*, llvmspike01-core*, factory-*); P2
  - removing the legacy llvm-closure-status-check.sh compatibility
    wrapper; P2

CONSERVATION
------------

The predecessor ACT and its HANDOFF are preserved unchanged.
The legacy llvm-closure-status-check.sh compatibility wrapper
still delegates to the new checker (one line). The bounded
5-pair managed universe is the same in both ACTs. No compiler
or LLVM code was modified.

NEXT ACT
--------

ACT-POLYC-LLVM-CORE04 is unblocked.
