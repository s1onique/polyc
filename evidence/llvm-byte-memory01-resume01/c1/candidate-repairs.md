# candidate-repairs.md -- RESUME01 C1 RED candidate repair survey

C1 question 3 (per reviewer): WHAT is the smallest
invariant-preserving repair? Survey of candidate mechanisms A
through E (and one additional candidate F).

---

## Repair candidate survey

### A. Choose a dominating existing value

The exit_block could re-load from the return slot instead of
using `%l8` directly:

```c
// irForwardReturnSlot do-rewrite:
st->op = IR_NOP;
ld->op = IR_NOP;
// keep rt->dst = ld->dst;  // i.e. ret tmp_loaded_from_slot
```

This restores the canonical PolyC return-slot shape and lets
`llCollapseStoreValue` / `llDetectCollapsibleReturn` handle
the multi-predecessor case the way they were designed to.

**Dominance:** correct (the load is in the exit_block; the
slot's last store dominates the load because every predecessor
of exit_block `jmp`s to exit_block).

**Size:** 3 lines changed in `src/ir-optimise.c`
(irForwardReturnSlot, lines 287-291) plus the corresponding
adjustment to `llLowerInstr` for the rewritten `ret` (which
must accept either `ld->dst` or `st->r1`).

**Risk:** the LLVM-side collapse seam was designed for exactly
this shape. If `llDetectCollapsibleReturn` rejects the
multi-predecessor case, we fall through to the regular
`load; ret` path and the verifier passes. There is no scenario
where this repair produces verifier-invalid IR.

**Test coverage:** `pos_byte_compare_simple.HC` already passes
via the load/ret path (no collapse applied). Adding
`pos_b0_compare_digit.HC` and the I64 probe as GREEN fixtures
exercises the non-collapse path explicitly.

---

### B. Move / hoist the definition

The current definition of `%l8` is in bb5 (`isub`). The
defining instruction could be hoisted to a dominator block
(bb1) so that every path to bb4 sees the definition.

**Problem:** `%l8` has DIFFERENT values on different paths
(initial `0` on bb1's path; `isub` result on bb5's path).
There is no single hoisted definition that produces the
correct value on both paths. The only correct hoist is a PHI
node, which is repair C.

**Verdict:** NOT APPLICABLE for this defect; applies to
different defects where a single hoisted definition is
sufficient.

---

### C. PHI construction

Insert a PHI in the exit_block that joins the value from
each predecessor:

```llvm
bb4:
  %l8.phi = phi i64 [ 0, %bb1 ], [ %l8.undef, %bb3 ], [ %l8.isub, %bb5 ]
  ret i64 %l8.phi
```

(For bb3, which doesn't define `%l8`, use the entry-block
value of `%l8` if available — which is `%l8 = 0` from bb1's
initial store.)

**Dominance:** PHI nodes are the canonical SSA solution for
this case. The phi operands are sourced from each predecessor
where the value is available.

**Size:** 5-15 lines of new code in `irForwardReturnSlot`
(detect multi-predecessor exit_block; insert phi; rewrite
`rt->dst` to the phi result; remove the load and store).

**Risk:** phi construction is the LLVM-idiomatic answer, but
it requires:
  (a) the return local's value to be the same variable at
      every predecessor of the exit_block (it is — `%l8` is
      the SSA name);
  (b) the optimiser to track the predecessor-wise value
      mapping (which requires following the use-def chain
      inside each predecessor);
  (c) the LLVM backend's `llLowerValue` to handle
      IR_PHI nodes, which it does not currently emit (the
      PolyC neutral IR does not have an explicit phi opcode
      — phi-ness is collapsed into alloca+store by the
      return-slot idiom).

This is the conceptually cleanest answer but requires
non-trivial work. Likely out of scope for RESUME01's
authorized seam.

**Verdict:** WORKABLE BUT EXCEEDS SCOPE. If the simplest
repair (A) is sufficient, C is reserved for a follow-on ACT.

---

### D. Suppress the collapse for unsafe CFG shapes

`irForwardReturnSlot` already operates intra-block. The
"unsafe" version of the rewrite is the intra-block rewrite
applied to the exit_block. Suppress the rewrite when the
exit_block has multiple predecessors that don't all define
the return local:

```c
// in irForwardReturnSlot, before line 287:
if (irBlockGetPredecessors(fn, bb)->size > 1
    && !irPredecessorsAllDefine(fn, bb, st->r1)) {
    continue;  // skip this rewrite
}
```

**Size:** ~10 lines + a small predecessor-scan helper.

**Risk:** this falls through to the canonical
`store; load; ret` shape that the LLVM-side collapse seam
was designed for. The verifier will pass because the load
is in the exit_block and the slot's last store dominates the
load.

**Verdict:** EQUIVALENT TO A for our specific defect. Both
mechanisms leave the canonical `load; ret` shape in place.

---

### E. Something even smaller

The defect is observable only when:
  (1) `irForwardReturnSlot` rewrites `store; load; ret` →
      `ret stored_value` in the exit_block, AND
  (2) the exit_block has multiple predecessors, AND
  (3) not every predecessor defines `stored_value`.

The simplest possible repair: don't do the rewrite when
condition (2) holds. The rewrite's benefit is to avoid an
LLVM-level alloca+store+load+ret → ret sequence, which
`llCollapseStoreValue` already does at the LLVM level when
the shape is canonical. So skipping the IR-level rewrite is
a net zero loss for the canonical shape (LLVM-side collapse
still applies), and a strict improvement for the non-
canonical shape (verifier now passes).

This is exactly repair A scoped tighter: keep the rewrite for
single-predecessor exit_blocks, skip it otherwise. Two-line
guard at line 287.

---

## F. (Additional candidate) Move the rewrite from intra-block to per-predecessor

The intra-block rewrite is too aggressive for multi-predecessor
exit_blocks. A per-predecessor rewrite would: for each
predecessor that has `store slot, V` immediately before `jmp
exit_block`, replace `jmp exit_block` with `ret V`. This is
exactly what `llCollapseStoreValue` does on the LLVM side.

**Verdict:** This duplicates the LLVM-side collapse logic
in the neutral IR. Likely over-engineered; the LLVM-side
collapse is the right place for this logic.

---

## Recommended primary repair

**Repair A (or D — they are equivalent for this defect):**
make the `irForwardReturnSlot` rewrite conditional on the
exit_block having at most one predecessor, OR on every
predecessor defining `stored_value`. Skip the rewrite when
the condition fails. The non-collapse path then produces the
canonical `store; load; ret` shape, which `llDetectCollap-
sibleReturn` and `llCollapseStoreValue` handle correctly.

RESUME01 §3.1 will pin the exact mechanism in IMPL phase
C2 after this RED recon is reviewed. The recon now answers
the three C1 questions:

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
      the rewritten shape (the exit_block has 1 instruction,
      not 2), so the unsafe choice is upstream.

2. WHAT minimal CFG shapes reproduce it?
   A. A function-local whose value is the function's
      return value, where the local is conditionally
      modified inside a conditional branch (single
      conditional OR nested diamond). I64-only probe
      reproduces the same defect; byte fixture is one
      of multiple triggers.

3. WHAT is the smallest invariant-preserving repair?
   A. Repair A or D: make the rewrite conditional on
      the exit_block's predecessor shape. ~2 lines in
      src/ir-optimise.c irForwardReturnSlot. This is
      the same canonical shape that the existing
      LLVM-side collapse seam was designed to handle.
   B. Not recommended for this ACT (would require phi
      support in the neutral IR or LLVM backend, which
      is out of RESUME01's authorised seam).
   C. Not applicable (no single hoisted definition is
      correct on all paths).
   D. Equivalent to A; both fall through to the
      canonical load/ret path.
   E. Strictly smaller than A: only do the rewrite for
      single-predecessor exit_blocks.
```

The IMPL phase (C2) will pin one of these and add the
mandatory GREEN fixtures.
