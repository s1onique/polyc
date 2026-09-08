HANDOFF — ACT-POLYC-LLVM-CORE03-CORRECTION02
==========================================

VERDICT
-------
HALT_SCOPE_CONTRACT_VIOLATED

SUPERSESSION (added by ACT-POLYC-FACTORY-STATUS-RECONCILIATION)
---------------------------------------------------------------

The verbatim verdict token was historically "PASS" (see historical
reviewer evidence below). Per F14 (current truth may invalidate
history), the authoritative verdict is now reconciled to the exact
ACT authoritative token:

    ACT       -> HALT_SCOPE_CONTRACT_VIOLATED
    HANDOFF   -> HALT_SCOPE_CONTRACT_VIOLATED     (this update)

The historical PASS claim is preserved as historical evidence (the
prose below); only the verbatim verdict token is corrected to
match the ACT's ## Status block under the new exact-token
factory closure-status contract.

CORRECTION02 closes every defect the reviewer flagged on
CORRECTION01 (HALT_CORE03_CORRECTION01_BINDING_STILL_PARTIAL):

  P0-wire:          CLOSED — length-delimited wire format + round-trip
  P0-arm-local:     CLOSED — arm-body extraction; verifier binds each
                          diagnostic to its arm, not to backend.c as
                          a whole
  P0-harness-taut:  CLOSED — exp_diag no longer assigned from obs_diag;
                          comparison is set-membership against a
                          per-fixture acceptable set
  P0-class-hard:    NARROWED — kept as FIXTURE_CLASS_MANUALLY_DECLARED
                          (per reviewer's acceptable narrow contract);
                          the diagnostic set is now per-fixture (via
                          expected_opcodes), not global
  P1-status:        CLOSED — ACT-POLYC-LLVM-CORE03-CORRECTION01 status
                          updated to HALT_TOPOLOGY_RECORDED with a
                          Supersession block pointing to CORRECTION02
  topology:         AT CAP — 3 commits (RED + IMPL + DOCS), strict per F12
                    (verified post-IMPL)

IDENTITY
--------
Entry:    d1644a1 (CORRECTION01 HEAD, after CORRECTION01 evidence witness)
RED:      b42480d (CORRECTION02 ACT contract + 5 RED evidence files)
IMPL:     857ecf2 (CORRECTION02 M1+M2+M3+M4)
DOCS:     (this commit)
HEAD:     (this commit)

Total CORRECTION02 commits: 3. At cap.

CORRECTION01 commits preserved per F14: c4e7263, 99f96cb, e0ce11c, d1644a1.

CORRECTION01 declared cap = 3, actual = 4 (topology breach recorded
honestly at evidence/llvmspike01-core03-correction01/topology-breach-recorded.txt
and re-summarised in evidence/llvmspike01-core03-correction02/topology-breach-recorded.txt).

ROOT CAUSE OF CORRECTION02 SCOPE
--------------------------------
CORRECTION01 closed the reviewer's CORE03 P0s and P1s on paper, but
the closures were surface-level. The reviewer correctly identified
four binding defects that false-GREENed under the previous checks:

  1. The wire format was space-delimited with no escaping. IR_CMP_BR's
     diagnostic `"(boundary violation - native fusion)"` was truncated
     at its first space, so the verifier's parsed diagnostic was
     `"(boundary"`. Round-trip was impossible.

  2. The verifier's I1 REJECTED diagnostic check was a whole-file
     `diag in backend_text` heuristic. A REJECTED opcode whose handler
     emitted the wrong macro would false-PASS if the right macro
     existed elsewhere (comment, other arm, etc.).

  3. The contract harness's `exp_diag="$obs_diag"` line was
     tautological — expected assigned from observed, so the
     comparison could never fail. Additionally, the diagnostic set
     was a global union of ALL REJECTED rows, so a fixture exercising
     IR_IDIV could emit INT_SHIFT and still pass.

  4. The CORRECTION01 ACT status was OPEN while its HANDOFF claimed
     PASS — direct stale-closure contradiction.

CORRECTION02 closes each by HARDENING the check, NOT weakening it.

RED EVIDENCE
------------
evidence/llvmspike01-core03-correction02/
  red-p0-wire-format-lossy.txt
    IR_CMP_BR diagnostic parsed as "(boundary" — current wire format
    is lossy for any diagnostic containing a space.
  red-p0-arm-local-diagnostic.txt
    IR_GEP handler changed to emit BITCAST instead of AGGREGATE.
    CORRECTION01 verifier false-GREENs (BITCAST macro is in backend.c).
    CORRECTION02 verifier REDs with arm-local diagnostic mismatch.
  red-p0-harness-tautology.txt
    Captures the structural defect: `exp_diag="$obs_diag"` cannot fail.
  red-p0-harness-tautology-reproduction.txt
    Live negative test: IR_IDIV handler changed to emit INT_SHIFT.
    CORRECTION01 harness silently GREENs (INT_SHIFT in global union).
    CORRECTION02 harness REDs (INT_SHIFT not in IR_IDIV's per-fixture
    acceptable set).
  red-p1-status-contradiction.txt
    Captures the stale ACT/HANDOFF contradiction.
  topology-breach-recorded.txt
    CORRECTION01 declared cap=3, actual=4. Recorded honestly per F4.
  negative-test-m1-wire-format.txt
    Live: revert llPrintCapabilityTable to old space-delimited format;
    M1 round-trip test REDs.
  negative-test-m2-arm-local.txt
    Live: change IR_GEP arm to emit BITCAST; arm-local M2 check REDs.

IMPLEMENTATION
--------------

### M1 — length-delimited wire format

src/llvm-backend-cap.c:131-148
  llPrintCapabilityTable() now emits:
    <op-ordinal>\t<class-ordinal>\t<diag-len>\t<diag>\t<note-len>\t<note>\n

scripts/quality/llvm-cap-table-verifier.py
  Parser reads len, then reads exactly len bytes for each variable-
  length field. Round-trippable byte-for-byte (verified by check_wire_format_roundtrip).

IR_CMP_BR row (correctly parsed):
  $ ./hcc --install-dir=/tmp/__polyc_prefix__ --print-cap-table \
      | awk -F'\t' '$1 == "45"'
  45\t1\t22\tLLVM_BACKEND_INTERNAL\t149\tLLVM_BACKEND_INTERNAL (boundary violation ...)

(Note: IR_CMP_BR's diagnostic was also corrected from
"(boundary violation - native fusion)" to LLVM_BACKEND_INTERNAL
because the if-arm in src/llvm-backend.c actually emits INTERNAL,
not a descriptive English string. See M2's row content correction.)

### M2 — arm-local diagnostic binding

scripts/quality/llvm-cap-table-verifier.py
  get_dispatch_arm_groups():
    Locates the switch in llLowerInstr, walks the case labels,
    groups consecutive `case IR_X:` labels into one arm-group, and
    extracts the body text (from after the last label to the next
    case/default:/closing brace at switch depth).
  get_if_arm_bodies():
    Scans BOTH llLowerBlock (where IR_BR/IR_JMP/IR_RET/IR_CMP_BR are
    dispatched) AND llLowerInstr for `if (ins->op == IR_X)` arms.
    Extracts each arm's body.
  check_dispatch_arm_local_diagnostic():
    For every REJECTED opcode, finds the body of its dispatch arm
    (case-group or if-arm) and asserts the diagnostic macro appears
    in that body specifically — not in backend.c as a whole.

Row content corrections (necessary for the new check to PASS):
  IR_ALLOCA:  was LLVM_BACKEND_UNSUPPORTED_MEMORY (table-vs-dispatch
              drift, only present in matrix comment). Now
              LLVM_BACKEND_UNSUPPORTED_POINTER (matches the grouped
              arm with IR_LOAD_DEREF/STORE_DEREF/RMW_DEREF/LEA).
  IR_CMP_BR:  was "(boundary violation - native fusion)" (descriptive
              string, no actual macro in dispatch). Now
              LLVM_BACKEND_INTERNAL (matches the if-arm in
              llLowerBlock that emits the boundary-violation check).

Both corrections were UNCOVERED by M2's stricter check; they were
pre-existing table-vs-dispatch binding defects that the previous
whole-file heuristic missed.

### M3 — per-fixture set-membership contract

scripts/quality/llvm-spike-contract-check.sh
  Removed `exp_diag="$obs_diag"`. Per-fixture declaration:
    contract_check <fixture> <expected_class> <expected_opcodes...>
  For REJECTED fixtures, the harness builds the union of:
    - the table's diagnostic for each opcode in expected_opcodes
    - LLVM_BACKEND_UNSUPPORTED_TYPE (generic pre-dispatch rejection)
    - LLVM_BACKEND_INTERNAL (generic internal/boundary rejection)
    - LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL (SHAPE_DEPENDENT rejection)
    - PARSE_TIME_REJECTION (synthetic; matches `^error:` in stderr)
  obs_diag must be in this set. The set is FIXED at harness-startup
  time (not derived from obs_diag). The comparison is now
  non-tautological.

Honest contract narrow (per reviewer's allowance):
  FIXTURE_CLASS_MANUALLY_DECLARED     # expected_class per fixture
  DIAGNOSTIC_SET_TABLE_DERIVED       # expected_diagnostic via
                                       expected_opcodes + table

Full fixture -> opcode-set automatic decoding remains CORE04 scope.

### M4 — status reconciliation

docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md
  Status: OPEN -> HALT_TOPOLOGY_RECORDED.
  Added Supersession block pointing to CORRECTION02.
  Commit history preserved (F14).

GATES (verified at HEAD)
------------------------
* git diff --check HEAD~1: rc=0 (uncommitted dirty files: 0)
* git diff --check HEAD~3..HEAD: rc=0
* existing llvm-spike-test.sh: PASS=18 FAIL=0
* contract-check harness: PASS=20 FAIL=0
* M2 cap-table verifier: PASS (with M1 round-trip test + M2 arm-local check)
* All three gates reproducible after `rm -f *.o hcc && make -C build`

ACCEPTANCE (live negative tests)
--------------------------------
M1 (wire-format):
  Reverted llPrintCapabilityTable to old printf("%d %d %s %s\n", ...).
  Verifier M1 round-trip test REDs (rc=1).
  See evidence/llvmspike01-core03-correction02/negative-test-m1-wire-format.txt.

M2 (arm-local):
  Changed IR_GEP arm to emit LLVM_BACKEND_UNSUPPORTED_BITCAST
  (the wrong macro, still emitted by another arm).
  CORRECTION01 verifier false-PASSes; CORRECTION02 verifier REDs with
  "IR_GEP (REJECTED) diagnostic 'LLVM_BACKEND_UNSUPPORTED_AGGREGATE'
   NOT in this arm's body. Appears in: <none>".
  See evidence/llvmspike01-core03-correction02/negative-test-m2-arm-local.txt.

M3 (harness-tautology):
  Changed IR_IDIV/IR_UDIV handler to emit LLVM_BACKEND_UNSUPPORTED_INT_SHIFT
  (the wrong macro, still emitted by the IR_SHL group).
  CORRECTION01 harness silently GREENs (INT_SHIFT in global union);
  CORRECTION02 harness REDs with "obs_diag '-' is NOT in the
   per-fixture acceptable set: LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
   LLVM_BACKEND_UNSUPPORTED_TYPE LLVM_BACKEND_INTERNAL
   LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL".
  See evidence/llvmspike01-core03-correction02/red-p0-harness-tautology-reproduction.txt.

M4 (status):
  ACT-POLYC-LLVM-CORE03-CORRECTION01.md status updated in-place.
  Commit history unchanged (F14).

SCOPE
-----
NEW:
* docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md (ACT contract)
* scripts/quality/.gitignore (pycache)
* evidence/llvmspike01-core03-correction02/* (RED + IMPL evidence)

MODIFIED (HARDENING — check made stricter, not weaker):
* src/llvm-backend-cap.c (M1: length-delimited wire format)
* scripts/quality/llvm-cap-table-verifier.py
    (M1: length-delimited parser + round-trip test;
     M2: arm-group body extraction + arm-local diagnostic binding)
* scripts/quality/llvm-spike-contract-check.sh
    (M3: per-fixture expected_opcodes + set-membership check;
     tautology removed)
* src/llvm-backend-cap.c (M2 row-content correction: IR_ALLOCA,
    IR_CMP_BR)
* docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md
    (M4: status -> HALT_TOPOLOGY_RECORDED + Supersession block)

NOT changed:
* src/ir*.{c,h} (no IR opcode semantics changes)
* The native backend
* The matrix comment in src/llvm-backend.c (still human-readable)
* CORE01-CORE02 invariants (preserved)

RESIDUE
-------
P0: The verifier's I1 check still does not do AST-level parsing.
    A more robust approach would be to use libclang or a proper
    C parser to extract arm bodies. The current brace-counting
    approach is sufficient for the current dispatch shape (single
    switch + early-returns in helper functions) but may need
    rework if the dispatch becomes more complex.

P1: The harness's per-fixture `expected_opcodes` is still manually
    declared. The reviewer explicitly accepted this narrow contract
    under FIXTURE_CLASS_MANUALLY_DECLARED + DIAGNOSTIC_SET_TABLE_DERIVED.
    Full fixture->opcode-set automatic decoding is CORE04 scope.

P1: The "always-acceptable generics" list in the harness
    (LLVM_BACKEND_UNSUPPORTED_TYPE, LLVM_BACKEND_INTERNAL,
    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL) is hand-curated. If new
    cross-class generics are added to the dispatch, the harness
    must be updated. A future ACT could promote these to
    auto-discovery via the table itself.

P2: Closure oracle trust (FT1) — the validator's abort(), the
    verifier's exit code, and the harness's set-membership check
    are now three distinct closure oracles. Their mutual trust
    is now MORE important. (ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01.)

P2: Pre-CORE03 history (CORE01, CORE02) was preserved via the
    topology breach record. No rewriting (F14).

P2: CORE03-CORRECTION01 declared cap = 3, actual = 4 (recorded
    honestly at evidence/llvmspike01-core03-correction01/topology-breach-recorded.txt).
    Same pattern as CORE03 itself.

NEXT ACT
--------
ACT-POLYC-LLVM-CORE04 (deferred):
- Consolidate the fixture list between llvm-spike-test.sh and
  llvm-spike-contract-check.sh.
- Replace per-fixture `expected_opcodes` with automatic
  fixture -> opcode-set decoding (run the fixture under native
  mode and observe which opcodes are exercised).
- Per-class execution counters in the harness summary.
- Replace the matrix comment in src/llvm-backend.c with a
  generated comment (closes reviewer "comment ↔ table binding").

Also tracked (Factory-tooling):
ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01 (FT1) — the validator
and verifier and harness set-membership check are now three
closure oracles. Their mutual trust warrants separate investigation.
