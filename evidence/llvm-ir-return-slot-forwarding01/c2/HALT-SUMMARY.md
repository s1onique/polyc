# IR-RETURN-SLOT-FORWARDING01 - C2 IMPL outcome: HALT_SECOND_SEAM_REQUIRED

## Verdict

The single-predecessor guard authorised by the reviewer
(`if (bb_preds && bb_preds->size > 1) continue;` per
block, not the original `!= 1` formulation which broke
the NC) was applied at
`src/ir-optimise.c::irForwardReturnSlot`. The result:

```text
              RED?         LLVM .ll    llvm-as   opt --passes=verify
pos_b0        EXIT=1       REJECTED    n/a       n/a
i64_collapse  EXIT=1       REJECTED    n/a       n/a
single_cond   EXIT=1       REJECTED    n/a       n/a
safe_fwd_NC   EXIT=0       produced    PASS      PASS
```

The three RED fixtures no longer trigger the dominance-
violating rewrite (post-opt IR shows
`bb4 -> predecessors {1,3,5}; ret %l8` instead of
`ret %i8_arith_zext`), so the original
`LLVM_BACKEND_VERIFY_FAILED: Instruction does not
dominate all uses!` defect is closed for the IR-side
rewrite path.

**However** the resulting IR still contains an
`IR_ALLOCA` + `store; load; ret` triple on a multi-
predecessor exit block. The SSA-only spike explicitly
rejects `IR_ALLOCA` outside the canonical
collapse-eligible shape, so the backend now emits:

```text
LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL: function ReadDigit:
unexpected IR_ALLOCA (this spike is SSA-only and does not
allocate stack slots). line 37, dst id=3, kind=IR_VAL_TMP
```

This is a different exit code than C1 RED's
`LLVM_BACKEND_VERIFY_FAILED`, but it is still EXIT=1
and still rejects the function from reaching verifier-
valid LLVM IR. The IMPL alone does not make the REDs
GREEN.

## Second seam (HALT reason)

The IR pipeline produces a 3-instruction
`store; load; ret` pattern on the post-fold exit block.
The existing LLVM-side collapse-elimination seam
(`llDetectCollapsibleReturn` at
`src/llvm-backend.c:400`) requires
`exit_block->instructions` to have exactly 2
instructions (`load; ret`), not 3. So the collapse-
eligible detector does not fire on the post-fold IR.
The IR remains `IR_ALLOCA`-bearing, and the SSA-only
spike rejects it.

Three hypothetical fixes exist, ALL outside the
authorised ACT scope:

```text
A. Widen llDetectCollapsibleReturn to also recognise
   the 3-instruction `store; load; ret` shape on a
   multi-predecessor exit (each predecessor stores a
   distinct value; collapse becomes a phi-of-stored-
   values pattern). Forbids IR_PHI construction (the
   spike is SSA-only).

B. Insert an IR-level collapse-elimination pass that
   rewrites the alloca-bearing store;load;ret triple
   into the per-predecessor direct-return shape
   BEFORE the LLVM backend sees the IR. Requires
   IR_PHI or explicit per-edge parameterisation.

C. Widen the SSA-only spike to accept IR_ALLOCA in
   collapse-eligible functions. Changes the spike's
   canonical contract.
```

Per the reviewer's P0/P1/P2 contract for this ACT:

```text
ALLOWED production:
    src/ir-optimise.c
        irForwardReturnSlot only

FORBIDDEN:
    src/llvm-backend.c
    llCollapseStoreValue
    llDetectCollapsibleReturn
    src/llvm-backend-cap.c
    neutral IR grammar/opcode changes
    PHI construction
    generic dominance framework
```

None of A/B/C is reachable from this ACT. The IMPL
alone is provably insufficient. Per F4 (a HALT is a
successful execution outcome when an ACT precondition
fails), this ACT halts with
`HALT_SECOND_SEAM_REQUIRED`.

## What was achieved (not nothing)

1. The dominance-violating rewrite at line 287 of
   `src/ir-optimise.c` is suppressed for multi-
   predecessor blocks. The verifier-failure code path
   is closed.
2. The structural NC `safe_fwd_single_pred.HC` still
   has the rewrite fire on its single-predecessor exit
   (the dump-ir transcript in
   `evidence/.../c2/safe_fwd_single_pred-impl-dump-ir.txt`
   shows `ret %l6 i64 local` post-opt, not
   `ret %t8 i64 tmp`).
3. Conservation holds: `gate-fast VERDICT=PASS`,
   `factory-v2-test PASS=35 FAIL=0`,
   `factory-append-only-test PASS=11 FAIL=0`,
   `git diff --check` clean, scope limited to
   `src/ir-optimise.c` (+12 lines).
4. The simple positive fixture
   `pos_byte_compare_simple.HC` continues to compile to
   verifier-valid LLVM IR (`llvm-as` +
   `opt --passes=verify` PASS). No previously-passing
   path was broken.

## Recommended next ACT

A separate ACT must authorise ONE of A/B/C above (or a
fourth option). The author of that ACT should:

* Decide whether the multi-predecessor collapse should
  use IR_PHI (which is currently forbidden by the
  SSA-only spike contract), or use a new explicit
  per-edge representation.
* Classify this as either a CORRECTION to
  ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 (extending the
  IMPL contract) or a fresh ACT (e.g.
  ACT-POLYC-IR-RETURN-SLOT-COLLAPSE01 or
  ACT-POLYC-LLVM-MULTIPRED-COLLAPSE01).
* Bind a fresh RED for the new seam before any further
  production change.

## Files in this C2 IMPL commit

```text
src/ir-optimise.c                                       +12 lines
evidence/llvm-ir-return-slot-forwarding01/c2/
    pos_b0_compare_digit-impl-stderr.txt                REJECTED SSA_LOCAL
    pos_b0_compare_digit-impl-dump-ir.txt               rewrite suppressed
    i64_collapse_probe-impl-stderr.txt                  REJECTED SSA_LOCAL
    i64_collapse_probe-impl-dump-ir.txt                 rewrite suppressed
    single_cond_probe-impl-stderr.txt                   REJECTED SSA_LOCAL
    single_cond_probe-impl-dump-ir.txt                  rewrite suppressed
    safe_fwd_single_pred-impl-stderr.txt                ACCEPTED
    safe_fwd_single_pred-impl-dump-ir.txt               rewrite STILL fires
    HALT-SUMMARY.md                                     this document
```

## Test matrix re-runnability

Every assertion above can be reproduced at this commit
by:

```text
$ make llvm-all && make install
$ for f in pos_b0_compare_digit i64_collapse_probe \
           single_cond_probe safe_fwd_single_pred ; do
      ./hcc --install-dir=/tmp/polyc-install --emit-llvm \
            src/tests/llvm-byte-memory01/$f.HC \
            > /dev/null \
            2> evidence/llvm-ir-return-slot-forwarding01/c2/${f}-impl-stderr.txt
      printf 'EXIT=%d\n' $? >> evidence/.../c2/${f}-impl-stderr.txt
  done
```

The captured transcripts above are the exact output of
that script at this commit.
