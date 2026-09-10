# RED-SUMMARY -- ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01 (C1 RED phase)

## Result

RED reproduced and mechanically pinned. The mandated B0-shaped
GREEN fixture `pos_b0_compare_digit.HC` FAILS
`LLVMVerifyModule` with two SSA-dominance violations. The defect
is generic (reproduces with I64-only fixtures) and the root
cause is the neutral IR optimisation pass `irForwardReturnSlot`
(src/ir-optimise.c:256-309) rewriting `store; load; ret` into
`ret stored_value` in multi-predecessor exit_blocks.

No production code is changed in this commit. This is the RED
phase; IMPL (C2) follows after this RED recon is reviewed.

Closure verdict for C1 is reserved for the IMPL phase (C2) per
Factory-v2 lifecycle: RED does not carry an ACT-Verdict trailer.

## Toolchain

- hcc v0.0.15-beta (./hcc, current build)
- LLVM $(llvm-as --version 2>/dev/null | head -1)
- opt $(opt --version 2>/dev/null | head -1)

## RED fixtures

Mandatory GREEN (P0 H2 binding):

  src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC
    $ ./hcc --install-dir=/tmp/polyc-install --emit-llvm
        src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC
    EXIT=1
    LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
      %i8_arith_zext = zext i8 %3 to i64
      ret i64 %i8_arith_zext
    LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
      %6 = add i64 %5, %i8_arith_zext
      ret i64 %6

Probe fixtures (used to identify the defect as generic):

  /tmp/i64_collapse_probe.HC
    $ ./hcc --install-dir=/tmp/polyc-install --emit-llvm
        /tmp/i64_collapse_probe.HC
    EXIT=1
    LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
      %4 = add i64 %0, %ld_deref
      ret i64 %4

  /tmp/single_cond_probe.HC
    $ ./hcc --install-dir=/tmp/polyc-install --emit-llvm
        /tmp/single_cond_probe.HC
    EXIT=1
    LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
      %3 = add i64 %0, %ld_deref
      ret i64 %3

Negative fixtures (NOT triggering, for CFG-shape classification):

  pos_byte_compare_simple.HC
    $ ./hcc --install-dir=/tmp/polyc-install --emit-llvm
        src/tests/llvm-byte-memory01/pos_byte_compare_simple.HC
    EXIT=0 (PASS -- returns literal in both arms)

  /tmp/trivial_probe.HC     EXIT=0 (literal returns)
  /tmp/uncond_probe.HC      EXIT=0 (unconditional modification)
  /tmp/readonly_probe.HC    EXIT=0 (local read, not modified)

## Trigger condition

A function-local L is the function's return value, and:
  - L is conditionally modified inside one arm of a
    conditional branch (single conditional or nested diamond),
  - the exit_block has multiple predecessors,
  - not every predecessor defines L.

Width-agnostic: reproduces with I64-only and I8/U8-byte
fixtures. F64 not yet probed but the same idiom would apply;
flagged for follow-on ACTs if confirmed.

## Root cause class

```
ROOT_CAUSE_CLASS = generic LLVM builder CFG bug
TRIGGERED_BY      = BYTE-MEMORY01 B0 fixture pos_b0_compare_digit.HC
SEAM              = src/ir-optimise.c irForwardReturnSlot line 287
                  rt->dst = st->r1;
EFFECT            = exit_block's ret uses a value that does not
                  dominate the exit_block along every predecessor
                  path
```

The IMPL closure record from BYTE-MEMORY01 §0.5 H2 named
"llCollapseStoreValue cross-block reload missing" as the
defect; that hypothesis is now DEMOTED to "one of two
containment sites." The actual root cause is the IR
optimisation pass `irForwardReturnSlot`.

## Candidate repairs

Survey in candidate-repairs.md. Recommended primary repair:
make the `irForwardReturnSlot` rewrite conditional on the
exit_block's predecessor shape (Repair A or D). ~2 lines in
src/ir-optimise.c. IMPL phase (C2) will pin the exact
mechanism after this RED recon is reviewed.

## C1 reviewer's three questions -- answered

```
1. WHY does llCollapseStoreValue select/create a value
   that does not dominate the later store/use?
   A. Because the upstream IR optimisation pass
      `irForwardReturnSlot` rewrote the exit_block's
      `load; ret load_result` into `ret stored_value`,
      which references a value (%l8, %l17) that may not
      dominate the exit_block along every predecessor
      path. The LLVM-side collapse (`llCollapseStoreValue`
      / `llDetectCollapsibleReturn`) is not engaged for
      the rewritten shape (the exit_block has 1
      instruction, not 2), so the unsafe choice is
      upstream.

2. WHAT minimal CFG shapes reproduce it?
   A. A function-local whose value is the function's
      return value, where the local is conditionally
      modified inside a conditional branch. Both
      single-conditional and nested-diamond shapes
      reproduce. I64-only probe reproduces the same
      defect; byte fixture is one of multiple triggers.

3. WHAT is the smallest invariant-preserving repair?
   A. Make the irForwardReturnSlot rewrite conditional
      on the exit_block having at most one predecessor
      (or every predecessor defining stored_value).
      ~2 lines. Falls through to the canonical
      load/ret shape that the existing LLVM-side
      collapse seam was designed to handle.
   B. Not recommended (requires phi support).
   C. Not applicable (no single hoisted definition is
      correct on all paths).
   D. Equivalent to A.
   E. Strictly smaller than A: skip the rewrite for
      multi-predecessor exit_blocks.
```

## HALT conditions encountered

None. C1 recon succeeded; the defect is mechanical and the
candidate repairs are bounded to the authorised seam
(src/ir-optimise.c irForwardReturnSlot and/or
src/llvm-backend.c llCollapseStoreValue /
llDetectCollapsibleReturn). No neutral-IR redesign required;
no scope expansion required.

## Recommended next ACT phase

C2 (IMPL): pin one of the candidate repairs (A or D
recommended); produce a minimal diff to the authorised
seam; verify with pos_b0_compare_digit.HC + i64_collapse_probe
+ single_cond_probe as GREEN fixtures. Re-run all existing
gate-fast gates to confirm no regression.
