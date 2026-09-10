# IR-RETURN-SLOT-FORWARDING01 - C3 EVIDENCE

This file records the exact C3 evidence at this commit,
captured immediately after the C2 IMPL (single-
predecessor guard at `src/ir-optimise.c` line 269-270)
was applied.

## Test matrix (per the reviewer's contract)

The dedicated GREEN harness
`scripts/quality/ir-return-slot-forwarding01-test.sh`
returns:

```text
IR_RETURN_SLOT_FORWARDING01_PASS=3
IR_RETURN_SLOT_FORWARDING01_FAIL=3
STATUS=FAIL
```

The 3 PASSes are:

* `safe_fwd_single_pred`: hcc EXIT=0 + llvm-as PASS +
  opt --passes=verify PASS (the NC compile path).
* `safe_fwd_single_pred`: structural rewrite proof
  (post-opt `ret %l6` function-local, NOT
  `ret %t8` load-result tmp).
* toolchain: hcc + llvm-as + opt available.

The 3 FAILs are:

* `pos_b0_compare_digit`: hcc EXIT=1 with
  `LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL: function ReadDigit:
  unexpected IR_ALLOCA (this spike is SSA-only and does
  not allocate stack slots). line 37, dst id=3,
  kind=IR_VAL_TMP`.
* `i64_collapse_probe`: hcc EXIT=1 with
  `LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL: function Probe:
  unexpected IR_ALLOCA ... line 1, dst id=5`.
* `single_cond_probe`: hcc EXIT=1 with
  `LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL: function Probe:
  unexpected IR_ALLOCA ... line 1, dst id=5`.

The IMPL closes the ORIGINAL defect
(`LLVM_BACKEND_VERIFY_FAILED: Instruction does not
dominate all uses!`) — the dominance-violating rewrite
at `src/ir-optimise.c:287` no longer fires on multi-
predecessor exit blocks. The dump-ir transcripts in
`evidence/.../c2/` show the post-IMPL post-opt IR
shape `bb4 -> predecessors {1,3,5}; ret %l8` (no
dominance-violating substitution). However, the post-
suppression IR still carries an `IR_ALLOCA` +
`store; load; ret` triple on the multi-predecessor
exit, which the SSA-only spike rejects with the
`LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL` diagnostic.

The IMPL alone is provably insufficient. This is the
HALT_SECOND_SEAM_REQUIRED outcome.

## Structural NC (before vs after IMPL)

The structural proof for `safe_fwd_single_pred.HC` is
that the rewrite STILL fires on its single-predecessor
exit (the IMPL does not over-broaden). Comparing:

### Pre-IMPL (C1 RED transcript)
`c3/safe_fwd_single_pred-dump-ir-pre.txt` (copy of
c1/safe_fwd_single_pred-dump-ir.txt)

```text
  bb2 -> predecessors: {1}  successors:  {}
    load     %t8 i64 tmp, %t3 i64 tmp  ; line 60
    ret      %t8 i64 tmp  ; line 60

===== After basic optimisations =====
i64 FwdSafe(%p1 ptr param) {
  bb1 -> predecessors:  {}  successors: {1}
    load*    %l4 i64 local, %p1 ptr param  ; line 57
    iadd     %l6 i64 local, %l4 i64 local,
            1 i64 const int  ; line 59
    ret      %l6 i64 local  ; line 60
}
```

### Post-IMPL (C2 IMPL transcript)
`c3/safe_fwd_single_pred-dump-ir-post.txt` (copy of
c2/safe_fwd_single_pred-impl-dump-ir.txt)

```text
  bb2 -> predecessors: {1}  successors:  {}
    load     %t8 i64 tmp, %t3 i64 tmp  ; line 60
    ret      %t8 i64 tmp  ; line 60

===== After basic optimisations =====
i64 FwdSafe(%p1 ptr param) {
  bb1 -> predecessors:  {}  successors: {1}
    load*    %l4 i64 local, %p1 ptr param  ; line 57
    iadd     %l6 i64 local, %l4 i64 local,
            1 i64 const int  ; line 59
    ret      %l6 i64 local  ; line 60
}
```

Byte-identical: the IMPL did NOT affect the
single-predecessor exit case. The rewrite STILL fires
(structural proof holds).

## Conservation matrix

See `c3/conservation-matrix.txt` for the full output.
Summary:

```text
gate-fast                       VERDICT=PASS
factory-v2-test                 PASS=35 FAIL=0
factory-append-only-test        PASS=11 FAIL=0
git diff --check                clean
refs/replace                    empty
IMPL scope (src/ + scripts/)    5 files, +261 lines

IMPL scope detail:
  src/ir-optimise.c                       +12  (Repair E only)
  src/tests/.../i64_collapse_probe.HC      +9   (test fixture)
  src/tests/.../safe_fwd_single_pred.HC   +62  (NC fixture)
  src/tests/.../single_cond_probe.HC      +7   (test fixture)
  scripts/quality/ir-return-slot-forwarding01-test.sh  +171  (new harness)
```

No changes to:
* src/llvm-backend.c
* llCollapseStoreValue
* llDetectCollapsibleReturn
* src/llvm-backend-cap.c
* neutral IR grammar / opcode
* IR_PHI construction
* generic dominance framework

The IMPL contract is surgically satisfied.

## Verdict

HALT_SECOND_SEAM_REQUIRED.

The IMPL closes the specific defect
(`LLVM_BACKEND_VERIFY_FAILED: Instruction does not
dominate all uses!`) and preserves the structural NC,
but the resulting IR requires a second-seam fix
(collapse-elimination widening, IR-level collapse
pass, or SSA spike widening) that is outside this
ACT's authorised scope.

A separate ACT (or a CORRECTION to this ACT that
extends its scope) must authorise one of those three
options before the three RED fixtures can be GREEN.
