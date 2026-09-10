# C10 HALT — Predecessor-store synthesis is architecturally defective

## Verdict

**HALT_DEFECTIVE_IMPL** — C9 IMPL at `6d8b6ea` produces
verifier-clean LLVM IR for the three original RED fixtures, but
the predecessor-store synthesis has a fundamental architectural
defect exposed by the reviewer's P0-1 semantic NC.

## P0-1 finding

The C9 commit message and IMPL summary described C9 as:

```text
"replicate the existing IR_STORE at each predecessor's terminator"
```

On careful examination of the live neutral-IR for the 3 RED
fixtures, the predecessor synthesised stores are NEW store
instructions that do not exist anywhere in the source IR. The
source IR contains exactly ONE `store %slot, %V` per function (in
the merged-store block); C9 synthesises an additional store per
predecessor, using the SSA cache value at that predecessor's end.

The synthesis depends on the SSA cache value being a value that
**dominates the merged-store block**. For the 3 RED fixtures this
property happens to hold. For the reviewer's NC, it does NOT
hold, and the LLVM verifier rejects the result.


## Reproduction (reviewer's NC: ProbePath)

```c
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
```

Neutral IR (from `./hcc --dump-ir`):

```text
bb1 -> predecessors:  {}  successors: {3, 4}
  store    %l6 i64 local, 10 i64 const int  ; line 21
  cmp_gt   %t7 i64 tmp, %p1 i64 param, 0    ; line 22
  br       %t7 i64 tmp, bb3, bb4            ; line 22

bb3 -> predecessors: {1}  successors: {4}
  iadd     %l6 i64 local, %l4 i64 local, 1  ; line 23
  jmp      bb4                              ; line 23

bb4 -> predecessors: {1, 3}  successors: {5, 6}
  cmp_lt   %t9 i64 tmp, %l2 i64 local, 0    ; line 25
  br       %t9 i64 tmp, bb5, bb6            ; line 25

bb5 -> predecessors: {4}  successors: {6}
  isub     %l6 i64 local, 0, %l4 i64 local  ; line 26
  jmp      bb6                              ; line 26

bb6 -> predecessors: {4, 5}  successors: {6}
  store    %t5 i64 tmp, %l6 i64 local       ; line 28
  load     %t11 i64 tmp, %t5 i64 tmp        ; line 28
  ret      %t11 i64 tmp                     ; line 28
```

The merge-store block is bb6 (predecessors bb4 and bb5). The
stored value `%l6` is defined in bb1 (init=10), bb3 (iadd x+1),
and bb5 (isub 0-x). bb4 does NOT redefine `%l6`.

C9 IMPL behaviour:

* bb5's IR_JMP terminator: probes `llvmGet(%l6)` → returns the
  bb5 isub result `%5` (dominates bb6). Emits
  `store %5, alloca`. Correct.
* bb4's IR_BR terminator: probes `llvmGet(%l6)` → returns the
  bb3 iadd result `%3` (defined in bb3). Emits
  `store %3, alloca`. **WRONG for the bb1→bb4 path** (correct
  value there is the bb1 init constant `10`). The emitted store
  uses `%3` which does NOT dominate bb6 (bb3 doesn't reach bb6
  directly).

LLVM in-pipeline verifier rejects:

```text
Instruction does not dominate all uses!
  %3 = add i64 %1, 1
  %polyc.local.slot.0 = phi i64 [ %5, %bb5 ], [ %3, %bb4 ]
LLVM ERROR: Broken function found, compilation aborted!
```

(Full transcript:
`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01/c10/nc_p01_predecessor_paths.live.stderr`.)


## Why the 3 RED fixtures appear to pass

The 3 RED fixtures happen to have IR shapes where every
predecessor of the merge-store block either:

1. **Defines the stored value**, so the SSA cache returns the
   predecessor's own definition (which dominates the merge block),
   OR
2. **Does not define the stored value but the SSA cache value is
   defined in a block that dominates the merge block** (e.g. bb1
   in ReadDigit defines `%l8` and dominates bb4; bb3 doesn't
   redefine but the live-in value at bb3 = the bb1 init = 0,
   which dominates bb4).

For the reviewer's NC, bb4 has TWO predecessors (bb1 and bb3)
where the live-in value of `%l6` DIFFERS by path. The SSA cache
only stores the most recent binding, which is `%3` from bb3. The
bb1→bb4 path's correct value (the constant 10) is lost. mem2reg
cannot construct a valid phi with this store, and the verifier
rejects.

## Root cause

```text
ROOT_CAUSE_CLASS = SSA-construction-by-frontend defect
SEAM              = src/llvm-backend.c llEmitMem2RegStoreAtPredEnd
                    (and the IR_JMP / IR_BR pre-terminator
                    emission that calls it)
TRIGGER           = predecessor of merge-store block does not
                    redefine the stored value V, AND V's live-in
                    value at that predecessor differs by path
EFFECT            = emitted LLVM IR has `store V_at_pred_end,
                    alloca` where V_at_pred_end is a value from
                    a non-dominating definition; mem2reg rejects
                    with "Instruction does not dominate all uses"
```

The SSA cache (`lc->values`) is a SINGLE map per var.id — it
remembers the most recent binding. PolyC locals can have multiple
definitions on different CFG paths; the cache cannot represent
this. The predecessor-store synthesis thus picks ONE of the
possible values (the most recent) and emits a store using it,
which is unsound when the live-in at that predecessor actually
depends on which path reached it.

## What the correct architecture must do

The standard SSA rename algorithm: for each definition site of V
on each path from entry to the merge-store block, emit a store
at that definition site (or at the deepest point along each path
where V is unambiguously defined). This requires either:

* **Option X (frontend rename):** Recursively walk predecessors
  of the merge-store block. For each predecessor, if it defines
  V, emit a store there; if not, recurse into its predecessors.
  This is what mem2reg does internally; we would re-implement it.
* **Option Y (input SSA):** Lower the IR into SSA form
  (inserting PHIs at every join where V is live) BEFORE the
  mem2reg pipeline. The merge-store block's read of V becomes a
  load-from-PHI-result; mem2reg then trivially promotes.
* **Option Z (stricter discriminator):** REJECT in `llRecognize
  LocalMem2Reg` any shape where the stored value V has multiple
  definitions on different paths to the merge-store block. This
  is a strict subset of what C9 admits. ReadDigit and AccDigit
  may also be rejected (their stored values have multiple
  definitions on different paths even though only one is "live"
  on any given path).

Option X and Y both require substantial new code (SSA rename or
manual PHI insertion). Option Z shrinks the admitted shape and
may not admit the 3 RED fixtures, in which case a different
solution (probably Option X) is required.

All three options are OUT OF SCOPE for the C9 IMPL frozen
contract.


## What is preserved

The C9 commit `6d8b6ea` is preserved on disk as evidence of what
was attempted:

* The 3 RED fixtures still reach verifier-valid LLVM IR
  (`ir-return-slot-forwarding01-test.sh` PASS=6 FAIL=0).
* `llvm-spike-test.sh` still passes (PASS=18 FAIL=0).
* `gate-fast.sh` still passes.
* The architectural defect exposed by this NC is captured here
  with reproduction commands.

The C9 production code (helpers + IR_ARM modifications +
LLCtx fields) is preserved because removing it would also remove
the 3 RED fixtures' GREEN status, and the next ACT may extend or
supersede this IMPL.

## Files in this halt commit

```text
docs/ROADMAP.md (status update)
docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01.md (C10 halt section)
evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01/c10/HALT-SUMMARY.md (this file)
evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01/c10/nc_p01_predecessor_paths.HC (the NC)
evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01/c10/nc_p01_predecessor_paths.live.stderr (transcript)
src/tests/llvm-byte-memory01/nc_p01_predecessor_paths.HC (the NC, in tree)
```

No `src/` production code change in this commit. The C9 production
code at `6d8b6ea` remains in tree; this halt records the discovery
that the architectural approach is unsound for a class of CFG
shapes and recommends a new ACT for the corrected approach.

## HALT conditions

* **C10 is HALT_DEFECTIVE_IMPL.** Production code change at
  `6d8b6ea` (C9 IMPL) is preserved as a partial / scoped
  witness. The next ACT must either (a) extend C9 with proper
  SSA rename semantics (Option X), or (b) reject a wider class
  of inputs (Option Z) and pair with an IR-side optimisation
  that converts remaining shapes to the narrower admitted form.

## Next ACT

A new ACT (e.g. CORRECTION02) is required. The architectural
decision between Option X / Y / Z is the primary RED question
for that ACT.

ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: HALT_DEFECTIVE_IMPL
