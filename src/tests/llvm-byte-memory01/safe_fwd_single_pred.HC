/* SAFE_FWD_SINGLE_PRED: structural negative control for
 * ACT-POLYC-IR-RETURN-SLOT-FORWARDING01.
 *
 * This fixture exercises the SAME return-slot forwarding
 * mechanism that the C1 RED defect (`store; load; ret`
 * substituted into a multi-predecessor exit block) breaks,
 * but on a SAFE CFG topology: the function body is
 * deliberately UNCONDITIONAL, and the exit block has
 * exactly ONE predecessor. The irForwardReturnSlot rewrite
 * (`store; load; ret` → `ret stored_value`) is therefore
 * dominance-safe on this fixture.
 *
 * Structural intent:
 *   - The function returns a function-local `acc`.
 *   - `acc` is unconditionally assigned in bb1.
 *   - The exit block (bb2) has exactly ONE predecessor
 *     (bb1) and the irForwardReturnSlot rewrite fires
 *     on bb2: `store; load; ret` → `ret stored_value`.
 *
 * Pre-IMPL behaviour (current):
 *   - bb2: store %t3, %l4; load %t7, %t3; ret %t7.
 *   - irForwardReturnSlot fires:
 *     bb2 becomes: ret %l4.
 *   - LLVM verifier ACCEPTS (single predecessor; %l4
 *     defined in bb1 which dominates bb2).
 *
 * Post-IMPL behaviour (after the single-predecessor
 * guard is added):
 *   - bb2 has 1 predecessor; guard passes.
 *   - Rewrite STILL fires; bb2 becomes ret %l4.
 *   - LLVM verifier still accepts.
 *   - The before/after neutral IR for this fixture is
 *     structurally identical to the pre-IMPL shape.
 *
 * If a future change disables irForwardReturnSlot
 * entirely, this fixture will still PASS the binary
 * compile, but the AFTER neutral-IR dump will show the
 * `store; load; ret` shape unchanged — falsifying the
 * ACT's "guard is not over-broad" claim. The NC
 * transcript is therefore the structural proof of the
 * guard's narrowness, not a binary PASS/FAIL.
 *
 * Observe in the captured --dump-ir transcript:
 *   before:
 *     bb2 -> predecessors: {1}
 *       store    %t3 i64 tmp, %l4 i64 local
 *       jmp      bb2  (folded below by irFoldPassThroughBlocks)
 *     bb2 -> predecessors: {1}
 *       load     %t7 i64 tmp, %t3 i64 tmp
 *       ret      %t7 i64 tmp
 *   after:
 *     bb2 -> predecessors: {1}  (single predecessor)
 *       ret      %l4 i64 local
 *   This is the SAFE rewrite firing on a single-
 *   predecessor exit block.
 */
I64 FwdSafe(I64 *p) {
    I64 x = *p;
    I64 acc;
    acc = x + 1;
    return acc;
}
