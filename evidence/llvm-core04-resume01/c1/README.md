# ACT-POLYC-LLVM-CORE04-RESUME01 C1 evidence

This directory holds the C1 RED-phase evidence for RESUME01.

## Files

- `red-verifier.out` --
  Full stdout of
  `python3 scripts/quality/llvm-cap-table-verifier.py`
  run against the tree at commit `ee91be8` after C1 adds
  `check_dispatch_scope_is_tight()` with the permanent
  adversarial fixture. The output ends with
  `FAIL: 1 binding violations` and `rc=1`.

  The failure message identifies the discovery-scope
  asymmetry:
    7 loose-only opcodes (potential rogue `if (ins->op ==
    IR_X)` arms outside llLowerInstr):
    [IR_ALLOCA, IR_BR, IR_CMP_BR, IR_JMP, IR_LOAD,
     IR_RET, IR_STORE]

  These opcodes ARE present in `src/llvm-backend.c`
  outside the `llLowerInstr` function. They are correctly
  scoped to helpers (`llDetectCollapsibleReturn`,
  `llLowerBlock`, etc.) but the verifier's loose
  extractor currently treats them as registered handlers
  without binding them to capability-table rows. C2 IMPL
  unifies the extractor.

- `red-m2-recon.txt` --
  M2 lifetime/aggregation recon. Documents the LLCtx
  ownership analysis that rules out the reviewer's
  hypothesis A ("driver walks all LLCtx instances") and
  identifies mechanism B (`LLTotals*` output parameter
  passed from `llvmEmitProgram()` to `llFunction()`) as
  the cheapest, scope-neutral accumulation seam.
  Establishes the C2 IMPL contract for one
  CAPABILITY_COUNTERS line per hcc invocation, with the
  UNREACHABLE_ON_LLVM field fixed at 0 by definition.

## RED-M1 wiring

The verifier is wired as follows:

  1. A labelled permanent adversarial fixture
     `RESUME01_ADVERSARIAL_DISPATCH_SNIPPET` is held in
     the verifier. It contains a function
     `not_a_dispatch_helper` with three `if (ins->op ==
     IR_X)` arms that must NOT be picked up by the
     scope-tighter.

  2. `_loose_if_arm_extract(text)` mirrors the current
     loose regex semantics. On the adversarial fixture
     it returns {IR_ADD, IR_SUB, IR_MUL}.

  3. `_scoped_if_arm_extract(text, scope_fn_names)` is
     the proposed scope-tight extractor. On the
     adversarial fixture with scope=['llLowerInstr'] it
     returns {}.

  4. `check_dispatch_scope_is_tight(dispatch)` compares
     the loose and scoped sets on the real
     `src/llvm-backend.c`. Currently they differ by the
     7 rogue opcodes listed above; the test FAILs.

  5. After C2 IMPL unifies `get_dispatch_arms()` to use
     the scope-tight extractor, the same test PASSes
     and stays in the verifier forever as a regression
     guard.

## RED-M2 wiring

The harness adds a section
`=== capability counters (RESUME01 RED-M2) ===` that runs
`hcc --emit-llvm` on `src/tests/llvm-spike/01_const.HC`
and greps for `^CAPABILITY_COUNTERS ` in the output. The
section FAILs (and emits `counters=missing`) until the
backend emits the line.

This machine does not have `llvm-config` / `llvm-as`
(LVM 22 required by the Makefile), so the spike-test
harness cannot run end-to-end here. The dry-run with
HCC=/nonexistent/hcc confirms the RED section fails
closed. The C2 GREEN gate (`grep -q '^CAPABILITY_COUNTERS '`
in `llvm-spike-test.sh`) is documented as a C2 IMPL
obligation in `red-m2-recon.txt`.

## Trailers

C1 commit will carry:

  ACT: ACT-POLYC-LLVM-CORE04-RESUME01
  ACT-Phase: RED
  ACT-Supersedes: ACT-POLYC-LLVM-CORE04

(continuing the documentary-RED range from 0604467 and
ee91be8).
