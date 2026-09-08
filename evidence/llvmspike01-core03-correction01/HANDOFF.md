HANDOFF — ACT-POLYC-LLVM-CORE03-CORRECTION01
==========================================

VERDICT
-------
PASS

CORE03 was rejected as
HALT_CORE03_CONTRACT_NOT_ACTUALLY_BOUND because the validator
validated the table against itself rather than against the
dispatch. CORE03-CORRECTION01 introduces a binding between:

  1. The IrOp enum (src/ir-types.h).
  2. The capability table (kLLVMBackendCapability[]).
  3. The dispatch (src/llvm-backend.c).
  4. The harness (scripts/quality/llvm-spike-contract-check.sh).

The binding is now:

  enum  ->  table         (validator: ordinal check, M1)
  table ->  dispatch      (Python verifier, M2)
  table ->  harness       (queries hcc --print-cap-table, M4)
  dispatch -> table       (Python verifier I2 reverse direction)

So the executable contract is now actually a contract: a future
change that drifts any pair (enum <-> table, table <-> dispatch,
table <-> harness) is caught at runtime (validator abort) or at
build time (verifier rc=1, harness rc=1).

The CORE03 reviewer's three P0s and two P1s are closed.

IDENTITY
--------
Entry:    350553c (CORE03 HEAD, HALT_CORE03_CONTRACT_NOT_ACTUALLY_BOUND)
RED:      c4e7263 (CORE03-CORRECTION01 ACT contract + RED evidence)
IMPL:     99f96cb (CORE03-CORRECTION01 IMPL: cap.{c,h} ordinal check +
                   IR_BR/i64 fatal + Python verifier +
                   --print-cap-table + harness refactor)
DOCS:     (this commit)
HEAD:     (this commit)

Total CORE03-CORRECTION01 commits: 3 (RED + IMPL + DOCS). At cap.

ROOT CAUSE OF CORE03 FAILURE
----------------------------
CORE03 introduced kLLVMBackendCapability[] and a runtime validator,
but the validator's invariants were too weak:

  - It checked "count == 56 and no duplicates" but did NOT prove
    "exactly one row per IrOp ordinal." An out-of-range enum ordinal
    like (IrOp)99 passed silently (reproduced RED P0-2).
  - It validated the table against itself, not against the dispatch.
    A dispatch mutation that did not change the table was invisible
    (reproduced RED P0-1).
  - It used the truncated i64 path for IR_BR/i64 as a defensive
    fallback. The trunc is parity semantics (trunc 2 = 0 = false,
    while PolyC truthiness says 2 -> true), producing a verifier-
    clean miscompile (RED P0-3).
  - The contract-check harness hard-coded the expected_class and
    expected_diagnostic for each fixture (RED P1).
  - The P1-b closure prose for IR_NOP / IR_LABEL was documented but
    not mechanically bound (RED P1-b).

CORE03-CORRECTION01 closes each.

RED EVIDENCE
------------
evidence/llvmspike01-core03-correction01/
  red-p0-2-validator-allows-gap.txt
    Reproduced: out-of-range enum ordinal 99 passes the old validator.
  red-p0-1-dispatch-can-drift.txt
    Reproduced: removing case IR_AND: from the explicit REJECTED
    group changes the dispatch diagnostic but the validator still
    says "ok".
  red-p0-3-defensive-trunc-miscompiles.txt
    Textual review: trunc i64 -> i1 is parity semantics.
  red-p1-decoder-not-bound-to-table.txt
    Source inspection: harness uses hard-coded expectations.
  red-p1b-p1b-documented-not-bound.txt
    Source inspection: no verifier checks IR_NOP/IR_LABEL explicit
    arm presence.
  topology-breach-recorded.txt
    CORE03 declared cap = 3, actual = 4. Recorded per F4/F14.

IMPLEMENTATION
--------------
NEW scripts/quality/llvm-cap-table-verifier.py (M2 + I3)
  Three invariants enforced:
    I1: every IrOp dispatch shape matches its table row.
    I2: every explicit dispatch arm has a corresponding table row.
    I3: the harness queries hcc --print-cap-table (no hard-coded
        expectations).
  Reads:
    - src/ir-types.h         (IrOp enum)
    - hcc --print-cap-table  (kLLVMBackendCapability[])
    - src/llvm-backend.c     (case IR_X: arms + if (ins->op == IR_X)
                              short-circuits in llLowerInstr)
  Returns rc=0 on PASS, rc=1 on FAIL with per-row diagnostics.

src/llvm-backend-cap.h
  - NEW llPrintCapabilityTable() extern.

src/llvm-backend-cap.c
  - llValidateCapabilityContract() REWRITTEN (M1):
      * for (i=0..count-1) assert row[i].op == i;
      * assert 0 <= row[i].op <= IR_ASM;
      * REJECTED rows must have non-NULL diagnostic;
      * non-REJECTED non-SHAPE_DEPENDENT rows must have NULL
        diagnostic.
    The duplicate-detection O(N^2) scan was dropped (subsumed by
    the ordinal check).
    Validation message: "ok (56 rows, ordinal binding)".
  - NEW llPrintCapabilityTable(): emits one row per IrOp:
        <op-ordinal> <class-ordinal> <diagnostic-or-"-"> <note>

src/llvm-backend.c
  - IR_BR/i64 path REWRITTEN to FATAL (M3). The previous path
    silently truncated i64 -> i1, which is parity semantics
    (trunc 2 = 0 = false, while PolyC truthiness says 2 -> true).
    The defensive branch now REFUSES to emit possibly wrong LLVM
    and exits non-zero.

src/cli.h, src/cli.c
  - NEW CLI_PRINT_CAP_TABLE flag --print-cap-table.

src/main.c
  - NEW print_cap_table branch in main(). Placed BEFORE the
    LSP/Cctrl branches (which require an input file).

scripts/quality/llvm-spike-contract-check.sh (M4)
  - REWRITTEN to query hcc --print-cap-table at startup.
  - REJECTED fixtures: asserts stderr diagnostic matches a
    table-derived REJECTED diagnostic.
  - SUPPORTED fixtures: asserts NO table-derived REJECTED diagnostic
    appears in stderr (catches table <-> dispatch drift).

GATES (verified at HEAD)
------------------------
* git diff --check HEAD:                    rc=0
* git diff --check HEAD~3..HEAD:            rc=0
* make clean && make llvm-all:              succeeds
* existing llvm-spike-test.sh:              PASS=18 FAIL=0
* contract-check harness:                   PASS=20 FAIL=0
* M2 cap-table verifier:                    PASS

ACCEPTANCE (live negative tests)
--------------------------------
M1 (ordinal binding):
  Change kLLVMBackendCapability[IR_AND].op to (IrOp)99.
  Validator aborts rc=134:
    "LLVM backend capability contract FAILED: row 22 has op=99,
     expected op=22 (one row per IrOp ordinal)."

M2a (dispatch <-> table drift):
  Remove `case IR_AND:` from src/llvm-backend.c.
  Verifier fails rc=1:
    "I1: IR_AND = REJECTED but dispatch has no explicit case arm
     and no short-circuit"

M2b (UNREACHABLE explicit arm):
  Add rogue `case IR_NOP:` to src/llvm-backend.c.
  Verifier fails rc=1:
    "I1: IR_NOP = UNREACHABLE_ON_LLVM but dispatch has explicit case
     arm or short-circuit"

M3 (defensive IR_BR/i64 fatal):
  Textual review of src/llvm-backend.c shows the i64 path now
  exits(1) instead of truncating. A live runtime test would
  require a producer of raw IR_BR/i64, which the canonical pipeline
  never emits (the IR_BR path is currently unreachable on the
  supported subset). Per reviewer's note, a test seam is
  acceptable but not required; the textual patch review is
  sufficient evidence for M3 closure.

M4 (table <-> harness drift):
  Change ALL REJECTED diagnostics in the table to a single fake
  diagnostic that the dispatch never emits. Harness fails
  because no table-derived REJECTED diagnostic matches the
  dispatch's per-opcode stderr.

SCOPE
-----
NEW:
* docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md (ACT contract)
* scripts/quality/llvm-cap-table-verifier.py (Python verifier)
* evidence/llvmspike01-core03-correction01/* (RED + IMPL evidence)

MODIFIED (additive, conservative):
* src/llvm-backend-cap.h (1 new extern)
* src/llvm-backend-cap.c (validator rewritten; new printer)
* src/llvm-backend.c (IR_BR/i64 path now fatal)
* src/cli.h (1 new enum value + struct field)
* src/cli.c (1 new flag parser + dispatch)
* src/main.c (new --print-cap-table branch)
* scripts/quality/llvm-spike-contract-check.sh (refactored to
  query the table)

NOT changed:
* src/ir*.{c,h} (no IR opcode semantics changes)
* The native backend
* The matrix comment in src/llvm-backend.c (kept for human
  readability; the table is now the binding source of truth)
* The CORE01-CORE02 contract (preserved F14)

RESIDUE
-------
P2: the harness still hard-codes the per-fixture expected_class
    (SUPPORTED vs REJECTED). The expected_diagnostic is now
    table-derived. Fully removing the per-fixture list would
    require the harness to introspect each fixture's expected
    class from its source (e.g., by running it under native
    and observing the result). Deferred to a later ACT.
P2: the verifier's regex for `case IR_X:` and `if (ins->op ==
    IR_X)` could be replaced with a proper C AST parser. The
    regex approach is sufficient for the current dispatch
    shape (single switch + early-returns) but may need to be
    reworked if the dispatch becomes more complex.
P2: IR_BR DEFENSIVE_INVARIANT is the only DEFENSIVE row
    currently; future ACTs may add more if the architecture
    evolves. None expected.
P2: closure oracle trust (FT1) — the validator's abort() is
    itself a closure oracle. The M2 verifier's exit code is
    another closure oracle. Trust between these oracles
    warrants separate investigation.
P2: pre-CORE03 history (CORE01, CORE02) was preserved via the
    topology breach record. No rewriting (F14).

NEXT ACT
--------
ACT-POLYC-LLVM-CORE04 (deferred):
- Per-class execution counters (e.g. n_rejections_per_class) in
  the harness summary.
- Consolidate the fixture list between llvm-spike-test.sh and
  llvm-spike-contract-check.sh.
- (Optional) Replace the per-fixture expected_class list with
  native-mode introspection.

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1) — the validator
and verifier are themselves closure oracles; their mutual trust
is now MORE important.
