# ACT-POLYC-LLVM-CORE03-CORRECTION02

## Status

OPEN — closing CORE03-CORRECTION01 reviewer P0s and P1s.

Predecessor: ACT-POLYC-LLVM-CORE03-CORRECTION01
(verdict: HALT_CORE03_CORRECTION01_BINDING_STILL_PARTIAL).

## Verdict at OPEN

CORE03-CORRECTION01 closed with PASS in commit d1644a1; the reviewer
correctly rejected that PASS because:

  P0-wire:  hcc --print-cap-table wire format truncates IR_CMP_BR's
            diagnostic string at its first space. The verifier's
            line.split(None, 3) parses the diagnostic as "(boundary"
            rather than the full string. Verifier reports PASS for
            IR_CMP_BR but the binding is broken.

  P0-arm-local: the verifier checks "diag in backend_text" (whole
            file). A REJECTED opcode whose handler emits the wrong
            diagnostic (but the right macro is still in the file
            elsewhere) false-GREENs. Concrete reproducer: IR_GEP
            handler emits BITCAST instead of AGGREGATE; verifier
            still PASSES for IR_GEP.

  P0-harness-tautology: scripts/quality/llvm-spike-contract-check.sh
            line 140: exp_diag="$obs_diag". The expected diagnostic
            is assigned from the observed diagnostic, so the
            comparison can never fail. The diagnostic set is GLOBAL
            across all REJECTED rows, so a fixture exercising IR_IDIV
            could emit INT_SHIFT and still pass.

  P0-class-hardcoded: the harness still hard-codes expected_class
            per fixture. CORRECTION01 admitted this in residue but
            claimed diagnostic was table-derived; not fully bound.

  P1-status: docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md says
            OPEN; HANDOFF.md says PASS. Stale-closure contradiction.

  topology:  CORE03-CORRECTION01 declared cap = 3, actual = 4.
            Same pattern as CORE03 (declared 3, actual = 4).

CORRECTION02 narrows these into a single bounded correction.

## Scope (cap = RED + IMPL + DOCS = 3 commits; strict per F12)

### M1 — make the wire format unambiguous (closes P0-wire)

Current format: printf("%d %d %s %s\n", ...). Space-delimited,
no escaping. Python parser does line.split(None, 3). IR_CMP_BR's
diagnostic contains a space; the parser truncates it.

Fix: length-delimited format. Each variable-length field is
prefixed with its byte length in ASCII decimal, then a tab:

  <op-ordinal>\t<class-ordinal>\t<diag-len>\t<diag>\t<note-len>\t<note>\n

The verifier reads len, then reads exactly len bytes. Round-trip-
able byte-for-byte.

Round-trip assertion in verifier: after parsing, serialize back
and assert byte-equality with the input wire format. The IR_CMP_BR
row already gives us the RED: current wire format is NOT round-
trippable because "(boundary violation ..." is parsed as "(boundary".

### M2 — bind the diagnostic to the dispatch arm (closes P0-arm-local)

The current verifier checks diag in backend_text — the whole
file. This passes whenever the diagnostic macro appears anywhere.

Fix: extract the body of each case arm (or grouped-case arm) in
the dispatch switch and verify the diagnostic macro appears in
that body specifically.

Approach:
  1. Locate the dispatch switch in src/llvm-backend.c (the one in
     llLowerInstr).
  2. Walk the case arms. Group consecutive case IR_X:/case IR_Y:
     labels into one arm-group.
  3. For each arm-group, extract the body (text from after the
     last case label up to the next case/default:/} at the same
     depth).
  4. For each REJECTED opcode in the group, verify the table's
     diagnostic macro string appears in that group's body.

For UNREACHABLE_ON_LLVM: assert the opcode does NOT appear as
case IR_X: or if (ins->op == IR_X) anywhere in the dispatch.

For SUPPORTED / SHAPE_DEPENDENT / DEFENSIVE_INVARIANT: continue to
assert arm presence (no diagnostic-macro check).

Acceptance:
  Repeat the RED: IR_GEP handler emits BITCAST (instead of
  AGGREGATE). Corrected verifier must RED with "IR_GEP arm emits
  BITCAST but table says AGGREGATE".

### M3 — remove the harness tautology (closes P0-harness-tautology)

Replace `exp_diag="$obs_diag"` with per-fixture explicit
expected_diagnostic. CORRECTION01 admitted expected_class is
hard-coded; CORRECTION02 keeps this honest under a narrower
contract:

  FIXTURE_CLASS_MANUALLY_DECLARED     # per-fixture, in the script
  DIAGNOSTIC_SET_TABLE_DERIVED       # per-fixture, by opcode-set

Per-fixture declaration becomes:

  contract_check <fixture> <expected_class> <expected_opcodes...>

For SUPPORTED fixtures: expected_opcodes is empty.

For REJECTED fixtures: harness builds the union of REJECTED rows'
diagnostics whose opcode is in expected_opcodes, asserts obs_diag
is in that union. Also asserts obs_diag is NOT in the union of
REJECTED diagnostics for opcodes NOT in expected_opcodes (catches
the "any table diagnostic passes" defect).

Acceptance:
  IR_IDIV handler emits INT_SHIFT instead of INT_DIVISION. Harness
  must RED on neg_f64 / red_idiv_unclassified fixtures because
  INT_SHIFT is not in IR_IDIV's diagnostic set.

### M4 — reconcile the ACT status (closes P1-status)

Update docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md:
  - Status: OPEN -> HALT_TOPOLOGY_RECORDED.
  - Add Supersession block pointing to CORRECTION02.
  - Leave commit hashes and verdict text intact (F14).

## Out of scope (F7)

  - Full fixture -> opcode-set automatic decoding. (CORE04.)
  - Replacing the matrix comment in src/llvm-backend.c with a
    generated comment. (CORE04.)
  - Per-class execution counters in the harness. (CORE04.)
  - Consolidating the fixture list between the two harnesses.
    (CORE04.)
  - Changing the actual diagnostic macro values in src/llvm-
    backend-cap.c or src/llvm-backend.c (these are pre-existing
    binding defects surfaced by M2's arm-local check; the fix
    would change semantics and requires its own ACT). CORRECTION02
    only HARDENS the check; the row content remains residue.

## Files authorised for change

NEW:
  docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md (this file)
  evidence/llvmspike01-core03-correction02/*

MODIFIED:
  src/llvm-backend-cap.c    (M1: length-delimited wire format)
  scripts/quality/llvm-cap-table-verifier.py
                            (M1: parse length-delimited; round-trip test;
                             M2: arm-group body extraction)
  scripts/quality/llvm-spike-contract-check.sh
                            (M3: per-fixture expected_opcodes list;
                             remove exp_diag="$obs_diag")
  docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md
                            (M4: status -> HALT_TOPOLOGY_RECORDED;
                             Supersession block)

NOT authorised (F7):
  - src/ir*.{c,h}
  - The native backend
  - LLVM SPIKE work unrelated to CORE03
  - Changing diagnostic macro values (semantic, not contract)

## Gate profile

  git diff --check HEAD~N..HEAD: rc=0   (N = CORRECTION02 commits)
  make clean && make llvm-all: succeeds
  existing llvm-spike-test.sh: PASS=18 FAIL=0
  contract-check harness:      PASS=20 FAIL=0
  NEW cap-table verifier:      PASS (rc=0)
  RED M1/M2/M3/M4 witnesses:   reproduced
  Topology:                    ACTUAL <= cap (strict, declared = 3)

## Topology cap

  RED  = 1 commit (this ACT + RED evidence)
  IMPL = 1 commit (M1+M2+M3+M4 together — M2 needs M1's parsed
         diagnostic; M3 needs M1's diagnostic set; M4 needs M2's
         verdict to update status)
  DOCS = 1 commit (HANDOFF + post-impl snapshots)

  TOTAL = 3 commits, AT CAP.
