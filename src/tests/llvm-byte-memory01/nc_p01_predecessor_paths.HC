/* P0-1 NC: multi-predecessor return slot with DIFFERENT definitions
 * on different paths.
 *
 * ProbePath(cond, x):
 *   r = 10
 *   if cond > 0:  r = x + 1
 *   if cond < 0:  r = 0 - x
 *   return r
 *
 * Paths:
 *   cond = 0   -> r = 10
 *   cond = 5   -> r = 43 (x+1)
 *   cond = -3  -> r = -42 (-x)
 *
 * The IR shape:
 *   bb1: store %l6, 10; br (cond>0 ? bb3 : bb4)
 *   bb3: iadd %l6, %l4, 1; jmp bb4
 *   bb4: cmp_lt; br (cond<0 ? bb5 : bb6)
 *   bb5: isub %l6, 0, %l4; jmp bb6
 *   bb6: store %t5, %l6; load; ret
 *
 * bb6's predecessors are bb4 and bb5. bb5 defines %l6.
 * bb4 doesn't define %l6, but bb4's live-in %l6 differs
 * by incoming path (10 from bb1, x+1 from bb3).
 *
 * C9 IMPL synthesizes `store %l6, alloca` at bb4's terminator
 * using the SSA cache value (which is %3 from bb3's iadd).
 * This store uses a value (%3) that doesn't dominate bb6,
 * and LLVM verifier rejects with:
 *
 *   Instruction does not dominate all uses!
 *     %3 = add i64 %1, 1
 *     %polyc.local.slot.0 = phi i64 [ %5, %bb5 ], [ %3, %bb4 ]
 */
I64 ProbePath(I64 cond, I64 x) {
    I64 r;
    r = 10;
    if (cond > 0) {
        r = x + 1;
    }
    if (cond < 0) {
        r = 0 - x;
    }
    return r;
}
