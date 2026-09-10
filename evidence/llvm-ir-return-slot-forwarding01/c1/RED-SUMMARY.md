# RED-SUMMARY -- ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 (C1 RED phase)

## Result

RED reproduced and mechanically pinned against the
ACT's authorized seam (`src/ir-optimise.c::irForwardReturnSlot`).
Three committed regression fixtures (`pos_b0_compare_digit.HC`,
`i64_collapse_probe.HC`, `single_cond_probe.HC`) all FAIL
`hcc --emit-llvm` with `LLVM_BACKEND_VERIFY_FAILED:
Instruction does not dominate all uses!`. The defect is
GENERIC (reproduces on I64-only fixtures) and the root
cause is `irForwardReturnSlot` rewriting `store slot, V;
load slot; ret T` into `ret V` for an exit block whose
predecessors do not all define V.

A structural negative control (`safe_fwd_single_pred.HC`)
demonstrates that the rewrite still fires correctly on a
single-predecessor exit block. The NC is verified
structurally (before/after neutral-IR comparison) AND
functionally (`hcc --emit-llvm` exits 0, LLVM verifier
accepts the resulting module).

No production code is changed in this commit. This is
the C1 RED phase. IMPL (C2) is the next phase after the
RED matrix is reviewed.

Closure verdict for C1 is RESERVED: per Factory-v2
lifecycle, RED commits do not carry an `ACT-Verdict`
trailer.

## Real RED seam (per reviewer's P0 correction)

```text
$ ./hcc --install-dir=/tmp/polyc-install --emit-llvm \
    src/tests/llvm-byte-memory01/<fixture>.HC
LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
  <bad instruction + use>
LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
  <bad instruction + use>
CAPABILITY_COUNTERS ...
EXIT=1
```

The compiler's INTERNAL `LLVMVerifyModule` gate rejects
the invalid module before emission. **No `.ll` file is
produced at RED.** `opt --passes=verify` is therefore
not the observable RED seam unless a pre-verifier dump
facility is added -- and the reviewer's P0 explicitly
forbids adding such machinery merely to satisfy ACT
wording.

This RED contract replaces the earlier `opt --passes=verify`
wording (which the reviewer's P0 identified as
self-contradictory with the existing compiler behaviour).

## RED fixtures (committed in this phase)

### pos_b0_compare_digit.HC (carried over from RESUME01)

Source: `src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC`

Compile:

```text
$ ./hcc --install-dir=/tmp/polyc-install --emit-llvm \
    src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC
LLVM backend capability contract: ok (56 rows, ordinal binding)
LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
  %i8_arith_zext = zext i8 %3 to i64
  ret i64 %i8_arith_zext
Instruction does not dominate all uses!
  %6 = add i64 %5, %i8_arith_zext
  ret i64 %6

CAPABILITY_COUNTERS supported=16 rejected=0 shape_dependent=14 defensive=0 unreachable=0
EXIT=1
```

This fixture was originally added under BYTE-MEMORY01 as
the mandated B0 GREEN fixture. Its RED behaviour is what
halted BYTE-MEMORY01's IMPL and motivated the RESUME01
HALT that opened this ACT.

### i64_collapse_probe.HC (new in this ACT)

Source: `src/tests/llvm-byte-memory01/i64_collapse_probe.HC`

```c
I64 Probe(I64 acc, I64 *p) {
    I64 x = *p;
    if (x >= 10) {
        if (x <= 99) {
            acc = acc + x;
        }
    }
    return acc;
}
```

Compile:

```text
$ ./hcc --install-dir=/tmp/polyc-install --emit-llvm \
    src/tests/llvm-byte-memory01/i64_collapse_probe.HC
LLVM backend capability contract: ok (56 rows, ordinal binding)
LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
  %4 = add i64 %0, %ld_deref
  ret i64 %4

CAPABILITY_COUNTERS supported=7 rejected=0 shape_dependent=2 defensive=0 unreachable=0
EXIT=1
```

Width-agnostic: same defect with no byte types involved.

### single_cond_probe.HC (new in this ACT)

Source: `src/tests/llvm-byte-memory01/single_cond_probe.HC`

```c
I64 Probe(I64 acc, I64 *p) {
    I64 x = *p;
    if (x >= 10) {
        acc = acc + x;
    }
    return acc;
}
```

Compile:

```text
$ ./hcc --install-dir=/tmp/polyc-install --emit-llvm \
    src/tests/llvm-byte-memory01/single_cond_probe.HC
LLVM backend capability contract: ok (56 rows, ordinal binding)
LLVM_BACKEND_VERIFY_FAILED: Instruction does not dominate all uses!
  %3 = add i64 %0, %ld_deref
  ret i64 %3

CAPABILITY_COUNTERS supported=5 rejected=0 shape_dependent=2 defensive=0 unreachable=0
EXIT=1
```

Minimal trigger: single conditional, no nesting, no
byte types, exit block has multiple predecessors (the
entry path and the conditional-true path).

## Negative control (structural)

### safe_fwd_single_pred.HC (new in this ACT)

Source: `src/tests/llvm-byte-memory01/safe_fwd_single_pred.HC`

```c
I64 FwdSafe(I64 *p) {
    I64 x = *p;
    I64 acc;
    acc = x + 1;
    return acc;
}
```

Compile:

```text
$ ./hcc --install-dir=/tmp/polyc-install --emit-llvm \
    src/tests/llvm-byte-memory01/safe_fwd_single_pred.HC
LLVM backend capability contract: ok (56 rows, ordinal binding)
CAPABILITY_COUNTERS supported=2 rejected=0 shape_dependent=1 defensive=0 unreachable=0
define i64 @FwdSafe(ptr %0) {
bb1:
  %ld_deref = load i64, ptr %0, align 4
  %1 = add i64 %ld_deref, 1
  ret i64 %1

dead_exit:                                        ; No predecessors!
  unreachable
}
EXIT=0
```

Structural before/after neutral IR (from
`./hcc --dump-ir`):

```text
BEFORE (unoptimized IR, output of IrFunctionCompile):

  bb1 -> predecessors:  {}  successors: {2}
    store    %l2 ptr local, %p1 ptr param  ; line 56
    alloca   %t3 i64 tmp, 8 i64 const int  ; line 56
    load*    %l4 i64 local, %l2 ptr local  ; line 57
    iadd     %l6 i64 local, %l4 i64 local, 1 i64 const int  ; line 59
    store    %t3 i64 tmp, %l6 i64 local  ; line 60
    jmp      bb2  ; line 60

  bb2 -> predecessors: {1}  successors:  {}
    load     %t8 i64 tmp, %t3 i64 tmp  ; line 60
    ret      %t8 i64 tmp  ; line 60

AFTER (post-basic-optimisations):

  bb1 -> predecessors:  {}  successors: {1}
    load*    %l4 i64 local, %p1 ptr param  ; line 57
    iadd     %l6 i64 local, %l4 i64 local, 1 i64 const int  ; line 59
    ret      %l6 i64 local  ; line 60
```

Note: BEFORE bb2 has `ret %t8` (a tmp loaded from the
slot). AFTER bb1 has `ret %l6` (a function-local directly).
The rewrite `store %t3, %l6; load %t8, %t3; ret %t8` -->
`ret %l6` fired on the SINGLE-PREDECESSOR bb2.

The result is LLVM-valid because `%l6` dominates bb2
along the only path.

## What the NC proves

```text
The NC fixture proves:

  (1) The rewrite irForwardReturnSlot CURRENTLY fires
      on single-predecessor exit blocks (it does in the
      current build).

  (2) The rewrite is SAFE on single-predecessor exit
      blocks (LLVM verifier accepts the result).

  (3) Post-IMPL (after the single-predecessor guard is
      added at irForwardReturnSlot line 287), the
      rewrite STILL fires on this fixture (single
      predecessor passes the guard). The before/after
      neutral IR is structurally identical to the
      pre-IMPL shape.

  (4) If a future change DISABLES irForwardReturnSlot
      entirely, the AFTER neutral IR for this fixture
      would revert to `ret %t8` (or `store %t3, %l6;
      load %t8, %t3; ret %t8`). That would falsify the
      ACT's "guard is not over-broad" claim.
```

## Trigger condition (refined from C1)

```text
A function-local L is the function's return value via
the alloca-based return-slot pattern, and:

  - L is conditionally modified inside one or more
    arms of conditional branches,
  - the exit block has MULTIPLE predecessors after
    irRemoveRedundantBlocks + irFoldPassThroughBlocks,
  - at least one predecessor of the exit block does
    not define L (typically the entry block where L
    is only initialised via alloca store).

Width-agnostic: reproduces with I64-only and I8/U8-byte
fixtures.

LLVM-side collapse machinery (llCollapseStoreValue,
llDetectCollapsibleReturn) is NOT engaged for the
rewritten shape (the exit block has 1 instruction after
the rewrite, not 2), so the unsafe choice is upstream in
the IR-side optimisation pass.
```

## Root cause (final)

```text
ROOT_CAUSE_CLASS = generic IR-side optimisation CFG bug
SEAM              = src/ir-optimise.c irForwardReturnSlot
                    line 287 `rt->dst = st->r1;`
TRIGGER           = rewrite fires on multi-predecessor
                    exit blocks without verifying that
                    st->r1 dominates the exit block along
                    every predecessor path
EFFECT            = emitted LLVM IR has `ret V` where V
                    is not defined along every path;
                    LLVMVerifyModule rejects with
                    "Instruction does not dominate all
                    uses!"
```

## C2 IMPL plan (preview; not in this commit)

Add at `src/ir-optimise.c::irForwardReturnSlot`, just
before line 287 (`rt->dst = st->r1;`):

```c
/* Conservative dominance guard: only forward when the
 * exit block has exactly one predecessor. The
 * substituted value must dominate the exit block along
 * every path; this guard is a sufficient condition
 * (single-path = trivially dominated) but NOT a
 * necessary condition (multi-predecessor blocks where
 * the value is defined in a common dominator are
 * deliberately declined; the canonical
 * `store; load; ret` shape survives and is handled
 * correctly by the LLVM-side collapse seam). */
if (irBlockGetPredecessors(fn, bb)->size != 1)
    continue;
```

DO NOT change:

- `src/llvm-backend.c`
- `llCollapseStoreValue`
- `llDetectCollapsibleReturn`
- `src/llvm-backend-cap.c`
- the neutral-IR opcode grammar
- dispatch-table coverage machinery

Reviewer-selected option **E** (conservatively safer than
A/D, smaller than B, no value-flow analysis needed like
C).

## HALT conditions encountered

None. C1 recon succeeded; the defect is mechanical and
the candidate repair is bounded to the authorised seam
(`src/ir-optimise.c::irForwardReturnSlot`). No
neutral-IR redesign required; no scope expansion
required.

## Files in this C1 commit

```text
src/tests/llvm-byte-memory01/i64_collapse_probe.HC       (new)
src/tests/llvm-byte-memory01/single_cond_probe.HC        (new)
src/tests/llvm-byte-memory01/safe_fwd_single_pred.HC     (new)
docs/acts/ACT-POLYC-IR-RETURN-SLOT-FORWARDING01.md       (RED section 2
                                                          wording fixed
                                                          per reviewer P0)
docs/ROADMAP.md                                          (status update)
evidence/llvm-ir-return-slot-forwarding01/c1/*.txt       (RED +
                                                          NC
                                                          transcripts)
evidence/llvm-ir-return-slot-forwarding01/c1/RED-SUMMARY.md (this
                                                          file)
```

No `src/`, no `scripts/`, no `AGENTS.md` changes in this
C1 RED commit.
