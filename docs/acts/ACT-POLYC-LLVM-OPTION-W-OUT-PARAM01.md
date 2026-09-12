# ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01
ACT-Phase: RED

**Title:** Widen Option-W read envelope to admit `IR_STORE_DEREF` value
reads; add a bounded `case IR_PHI:` arm for short-circuit logical PHIs

**Repository:** `s1onique/polyc`

**Working copy:** `codium-polyc`

**Track:** A — language/compiler critical path

**Entry HEAD:** `55389444f96b99d297b44962cacbbc5fce657adf` — the
C3 CLOSE of `ACT-POLYC-B0-SUBSTRATE-RECON01` (HALT_SUBSTRATE_GAP).

**Predecessor (CLOSED HALT):**
* `ACT-POLYC-B0-SUBSTRATE-RECON01` — recon proved that the post-GEP01 +
  BYTE-MEMORY + LOCAL-MEM2REG substrate cannot implement B0; named
  this ACT as the smallest first continuation.

**Substrate lineage (all CLOSED PASS):**
* `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02`
* `ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02` — Option-W discriminator
* `ACT-POLYC-LLVM-GEP01` — bounded `U8 *base + I64 index` byte access

**Primary question:**

> Does widening `llOptionW_ReadsAreLowerable` to admit
> `IR_STORE_DEREF` value reads, plus adding a bounded `case IR_PHI:`
> arm for short-circuit logical PHIs, allow a real PolyC B0-shaped
> scanner to compile, verify, and run?

**C1.1 RED correction (this revision):**

> An expert review identified five contract defects in the
> initial C1 RED. C1.1 freezes corrections for each:
>
> * P0-1: production-change authorization was contradictory
>   ("FORBIDDEN" + explicit authorization). Now bounded to the
>   C1-frozen seams A and B.
> * P0-2: Fix B was over-authorized as general IR_PHI support.
>   Now `IR_PHI = LLVMBC_SHAPE_DEPENDENT` with a strict
>   shape-validation contract in the dispatch arm itself.
> * P0-3: one-pass PHI lowering safety was not proven. Now
>   mechanically proven by the pre-ordering invariant
>   (frontend always adds predecessors before the merge block;
>   backend iterates blocks in linked-list order); two-phase
>   fallback documented for future producers.
> * P1: negative control was a frontend-crash-as-evidence.
>   Now a mechanical witness `GN4_neg.HC` reaches the backend
>   with well-formed IR and is rejected with a named diagnostic
>   (`OPTION_W_INELIGIBLE`).
> * P2: book-keeping corrections (12 evidence files not 8;
>   G1 caption "no neutral-IR PHI" not "no CFG merge").

**Production semantic changes:**
* BOUNDED TO C1-FROZEN SEAMS A/B (no other deltas).

**New language syntax / neutral IR producer:**
* FORBIDDEN.

**New LLVM backend behavior:**
* AUTHORIZED ONLY FOR:
  * A. IR_STORE_DEREF value-read admission (seam A;
    `src/llvm-backend.c` `llOptionW_ReadsAreLowerable`
    discriminator function only).
  * B. Existing short-circuit IR_PHI lowering (seam B;
    `src/llvm-backend.c` `llLowerInstr` `case IR_PHI:` arm;
    `src/llvm-backend-cap.c` capability-class transition
    `REJECTED` -> `SHAPE_DEPENDENT`; ONLY IF released by C3).

**New LLVM C-API calls outside the existing per-block walk:**
* FORBIDDEN (the widening is local to one discriminator function
  plus one dispatch arm; no new LLVM IR builder calls outside
  what the LLVM C API already exposes).

**New Bash logic:** FORBIDDEN (no new `*.sh` files).

---

## 0. Mission

Mechanically prove that the B0 substrate gap identified by
`ACT-POLYC-B0-SUBSTRATE-RECON01` is exactly two seams — both
fixable in one bounded ACT — or, if not, halt with a sharper
diagnosis.

The recon's "PHI rejection" framing collapsed two distinct
problems into one observation. This ACT separates them.

The ACT has exactly three legitimate successful outcomes:

```text
OUTCOME A - BOTH_SEAMS_FIXED
  Fix A (Option-W widening) and Fix B (IR_PHI dispatch arm)
  both compile and verify. ScanIdent PASSes.
  NEXT: ACT-POLYC-BOOTSTRAP01

OUTCOME B - FIRST_SEAM_FIXED_ONLY
  Fix A passes but Fix B requires a separate bounded ACT.
  Close as HALT_SECOND_SEAM_REQUIRED.
  NEXT: an IR_PHI dispatch-arm ACT, named mechanically.

OUTCOME C - WIDENING_INSUFFICIENT
  Even after both fixes, a B0-shaped scanner fails for a new
  reason not seen in C1.
  Close as HALT_SUBSTRATE_GAP_NAMED.
  NEXT: named mechanically.
```

There is no outcome "silently widen the discriminator further".

---

## 1. Recon correction (architectural inference refined)

The recon (per `evidence/ACT-POLYC-B0-SUBSTRATE-RECON01/c2/`) named
ONE next ACT, `ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01`, with the
implied mission "widen Option-W to admit `IR_STORE_DEREF` + the
resulting multi-path mem2reg emission".

The reviewer (LLVM backend engineer) correctly identified that:

1. The recon's RC-A (`Option-W read envelope`) is genuinely one
   widening: add `IR_STORE_DEREF` to `llOptionW_ReadsAreLowerable`
   in the value-operand role only.

2. The recon's RC-B (`IR_PHI rejection`) is a SEPARATE seam: the
   backend's `llLowerInstr` lacks a `case IR_PHI:` arm. PHIs are
   produced by the frontend's logical-operator short-circuit
   lowering (src/ir.c:535, 566, 592) as `IR_VAL_TMP` carrying an
   `I8` Boolean result. These PHIs are NOT memory-backed; they
   are SSA merges that exist before any alloca is materialised.
   LLVM's `mem2reg` cannot introduce them because there is no
   alloca to promote.

3. The recon's "while-loop produces IR_PHI" attribution was
   **false**. Empirical reproduction (this ACT C1, G2_minimal.HC)
   shows that a `while` loop with a multi-def local feeding
   `ret` already compiles, verifies, and emits a mem2reg-placed
   LLVM PHI for the synthesised slot alloca. The neutral IR for
   G2 contains NO IR_PHI; the loop is the canonical Option-W
   use case and is fully supported by
   `ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02`.

   The recon's P7 "while" FAIL was actually the *out-param* read
   envelope (RC-A), not the loop control flow.

This ACT adopts the refined framing. The recon's next-ACT naming
is kept (`ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01`) but the mission
is split into two fixes with a hard stop after Fix A.

---

## 2. Architectural invariant (preserved from C6 doctrine)

```text
FRONTEND_SSA_RECONSTRUCTION = NO    (memory-backed allocas;
                                      unchanged from C6 doctrine)

PHI_OWNER_LVAR              = LLVM mem2reg  (unchanged from C6)

PHI_OWNER_SHORT_CIRCUIT     = LLVM backend LLVMBuildPHI
                              (NEW arm added by Fix B)
```

The two PHI owners do not overlap. The Option-W doctrine says
"PolyC never manufactures PHIs for memory-backed locals"; it
says nothing about PHIs for frontend short-circuit results, which
have always existed (src/ir.c:535/566/592) but were never used
by any PolyC source that compiled under the CORE backend.

Adding a `case IR_PHI:` arm to lower these PHIs to LLVMBuildPHI
does NOT contradict the C6 doctrine; it admits a new consumer
for an existing IR construct.

---

## 3. Predecessor state - frozen consumption contract

LOCAL-MEM2REG Option-W (per CORRECTION02 C6 §2, frozen):

```text
mutable I64 local
  entry alloca
  original-site stores           (case-a: IR_STORE)
  original-site loads            (legacy SSA cache)
  case-(b) definitions           (IR_IADD, IR_ISUB only)
  reads must be in the whitelist (IR_IADD, IR_ISUB, IR_IMUL,
                                  IR_ICMP, IR_STORE, IR_RET,
                                  IR_BR, IR_JMP)
  must feed return               (direct or via return-slot
                                  or via tmp chain)
  must be I64, not address-taken
```

Read envelope (current, src/llvm-backend.c:789):
`IR_STORE_DEREF` falls to the `default:` arm and is REJECTED if
V is named as dst, r1, or r2 of any such instruction.

This ACT widens the read envelope ONLY for `IR_STORE_DEREF`
where V is the value operand (`ins->r1 == V`). The address-
taken fence (V as the pointer operand, `ins->dst == V`) is
already rejected by `llOptionW_NotAddressTaken`; the widening
is defensive at the read envelope as belt-and-braces.

CASE_B_OPCODE_SET remains `{IR_STORE, IR_IADD, IR_ISUB}`. No
new case-(b) definition opcode is added.

---

## 4. B0 mission freeze (inherited)

Inherited verbatim from `ACT-POLYC-B0-SUBSTRATE-RECON01` §2:

```text
input model       = PTR_PLUS_LENGTH (U8*src + I64 src_len)
token delivery    = ONE_AT_A_TIME (token-at-a-time lexer)
token kind        = I64 scalar constant
token text model  = SOURCE_SLICE(start, length) into caller buffer
metadata model    = scalar out-params
corpus            = Corpus A (synthetic), B (readat.HC),
                    C (red_byte_to_i64.HC)
```

This ACT does NOT change the B0 mission. It exists to prove the
substrate can implement ScanIdent (the binding fixture).

---

## 5. Three minimal geometries (frozen at C1)

### G1 - out-param consumer with no neutral-IR PHI

```c
I64 G1(I64 x, I64 *out) {
    I64 v = x;
    if (x > 0) {
        v = v + 1;
    }
    *out = v;
    return 0;
}
```

Pre-opt IR (this ACT C1, evidence/c1/g1.ir.txt):
* definitions of v: bb1 store, bb3 iadd (2 case-(b) defs)
* reads of v: bb4 store* (IR_STORE_DEREF as value operand)
* one multi-def local; reads via IR_STORE_DEREF only.

Current behaviour: REJECTED with
`LLVM_BACKEND_UNSUPPORTED_OPTION_W_INELIGIBLE` (path 1).

After Fix A: ACCEPTED. Slot alloca + mem2reg + verifier PASS.
After Fix B (not required for G1).

### G2 - mutable loop/local, no out-param

```c
I64 G2(I64 n) {
    I64 i = 0;
    while (i < n) {
        i = i + 1;
    }
    return i;
}
```

Pre-opt IR (this ACT C1, evidence/c1/g2.ir.txt):
* definitions of i: bb1 store, bb4 iadd (2 case-(b) defs)
* reads of i: bb3 cmp_lt, bb5 store-to-return-tmp
* NO IR_STORE_DEREF, NO IR_PHI.

Current behaviour: ALREADY PASSES. hcc --emit-llvm produces
verified-clean LLVM (evidence/c1/g2.llvm.stderr.txt, exit=0).
The emitted LLIR contains a mem2reg-placed PHI on the
synthesised slot alloca. The neutral IR contains no PHI.

G2 is the conservation oracle for G1/G3: it must remain GREEN
across every phase of this ACT.

### G3 - actual B0 combination (binding fixture, abbreviated)

```c
I64 ScanIdent(U8 *src, I64 len, I64 cursor,
              I64 *out_cursor, I64 *out_len) {
    I64 start = cursor;
    while (cursor < len) {
        U8 ch = src[cursor];
        if (ch == ' ' || ch == '\t' || ch == '\n') break;
        cursor = cursor + 1;
    }
    *out_cursor = cursor;
    *out_len = cursor - start;
    return 0;
}
```

Pre-opt IR (this ACT C1, evidence/c1/g3.ir.txt):
* definitions of cursor: bb1 store, bb11 iadd (2 case-(b) defs)
* reads of cursor: bb3 cmp_lt, bb4 iadd (GEP), bb5 store* x2
* TWO IR_PHI instructions (line 5, lines 17+25), both I8 tmps.

Current behaviour: REJECTED on path 1 (option-W for store*),
which fires before path 2 (PHI) is reached.

After Fix A: still REJECTED on path 2 (PHI).
After Fix B: ACCEPTED. Slot alloca + mem2reg + LLVMBuildPHI for
the short-circuit results + verifier PASS + runtime oracle
matches (evidence/c1/scanident-binding-fixture.txt, tests 01-10).

---

## 6. IR_STORE_DEREF operand freeze (C1 question A)

Empirical source: src/ir.c:1187
```c
IrOp store_op = tgt.indirect ? IR_STORE_DEREF : IR_STORE;
irBlockAddInstr(ctx, irInstrNew(store_op, tgt.target, new_val, NULL));
```

Operand layout:
```text
ins->op   = IR_STORE_DEREF
ins->dst  = tgt.target   (the pointer being stored THROUGH)
ins->r1   = new_val      (the value being stored)
ins->r2   = NULL
```

`IR_STORE_DEREF(ins->dst=ptr, ins->r1=V)` is a READ of V.
`IR_STORE_DEREF(ins->dst=V, ins->r1=...)` would write V (it would
not lower this way in current PolyC source - it lowers to
`IR_STORE` on V's loff instead). The address-taken fence
(`llOptionW_NotAddressTaken`) rejects V in the second form.

Full freeze: `evidence/c1/store-deref-operand-freeze.txt`.

---

## 7. IR_PHI provenance freeze (C1 question B)

Producers of `IR_PHI` in src/ir.c (the only frontend emitter):

```text
src/ir.c:535-538   AST_BIN_OP_LOG_AND  short-circuit
src/ir.c:566-569   AST_BIN_OP_LOG_AND  short-circuit
src/ir.c:592-595   AST_BIN_OP_LOG_OR   short-circuit
```

Every `IR_PHI` carries an `IR_VAL_TMP` of type I8 representing
the Boolean short-circuit result. It NEVER carries an
`IR_VAL_LOCAL`. The mid-end (src/ir-optimise.c) only CONSUMES
existing PHIs; it does not CREATE new ones.

PHI provenance therefore confirms the expert's Case B1:
PHIs belong to a TMP class that the backend can lower via
`LLVMBuildPHI` + `LLVMAddIncoming`. They are NOT memory-backed,
so the `PHI_OWNER = LLVM mem2reg` doctrine is not violated.

Full freeze: `evidence/c1/phi-provenance-freeze.txt`.

---

## 8. Frozen Option-W widening contract (C2-A pre-authorised)

Source under change:
* `src/llvm-backend.c`, function `llOptionW_ReadsAreLowerable`
  at line 789.

Diff shape:

```c
case IR_STORE_DEREF:
    // B0-shaped widening (ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01):
    // accept IR_STORE_DEREF ONLY when V is the VALUE operand.
    // V as POINTER is rejected earlier by llOptionW_NotAddressTaken;
    // this arm is belt-and-braces defensive.
    if (ins->r1 == v) {
        node = node->next;
        continue;
    }
    if (ins->dst == v || ins->r2 == v) {
        return 0;
    }
    node = node->next;
    continue;
```

Invariants preserved (F5):
* `CASE_B_OPCODE_SET = {IR_STORE, IR_IADD, IR_ISUB}` UNCHANGED
* `llOptionW_DefinitionsAreCaseAorB` UNCHANGED
* `llOptionW_TypeIsI64` UNCHANGED
* `llOptionW_NotAddressTaken` UNCHANGED
* `llOptionW_FeedsReturnOrIsReturnLocal` UNCHANGED
* `llOptionW_DefiniteAssignment` UNCHANGED

Negative control: IR_STORE_DEREF where V is the POINTER operand
(`ins->dst == V`) MUST continue to be rejected. The address-
taken fence (`llOptionW_NotAddressTaken`) already enforces this;
the widening's defensive `if (ins->dst == v) return 0;` documents
the invariant at the read-envelope layer.

Positive control: the C2-A test set is:
* G1_minimal.HC       (P1: one def, one branch, `*out = v`)
* G3_minimal.HC       (P3: multi-def loop + `*out_cursor = cursor`)
* safe_fwd_single_pred probe  (P5)
* MultiDef probe              (P6)
* ProbePath / Diamond / AccDigit / i64_collapse_probe /
  single_cond_probe           (P7-P11, LOCAL-MEM2REG regression set)

Full freeze: `evidence/c1/option-w-widening-contract.txt`.

---

## 9. Frozen IR_PHI dispatch-arm contract (C2-B pre-authorised IF needed)

If Fix B is required (i.e. if C3 finds that G3 still fails after
Fix A), the implementation in `src/llvm-backend.c` `llLowerInstr`
adds:

```c
case IR_PHI: {
    // ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 (C1.1): lower
    // short-circuit logical-result PHIs to LLVMBuildPHI.
    // Provenance (C1) shows that ALL IR_PHI in the current
    // neutral IR are produced by src/ir.c:535/566/592
    // (logical short-circuit); operands are therefore
    // IR_VAL_TMP carrying I8 values.
    //
    // SHAPE_DEPENDENT validation: the dispatch arm enforces
    // the C1-frozen shape contract before lowering. A future
    // PHI producer that violates any invariant below is
    // rejected with a NEW diagnostic (NOT the legacy
    // LLVMBC_REJECTED path).
    if (!ins->dst) {
        // malformed PHI: missing dst
        LL_INC_REJECTED(lc);
        fprintf(stderr,
            "%s: function %s: IR_PHI missing dst\n",
            LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE,
            lc->fn->name->data);
        llEmitCapabilityCountersOnce(lc->totals);
        exit(1);
    }
    if (ins->dst->kind != IR_VAL_TMP ||
        ins->dst->type != IR_TYPE_I8) {
        // SHAPE_DEPENDENT mismatch
        LL_INC_REJECTED(lc);
        fprintf(stderr,
            "%s: function %s: IR_PHI shape mismatch "
            "(dst.kind=%s dst.type=%d; only IR_VAL_TMP+I8 "
            "from short-circuit logical operators is "
            "supported)\n",
            LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE,
            lc->fn->name->data,
            irValueKindToString(ins->dst->kind),
            (int)ins->dst->type);
        llEmitCapabilityCountersOnce(lc->totals);
        exit(1);
    }
    if (!ins->extra.phi_pairs ||
        vecSize(ins->extra.phi_pairs) < 1) {
        LL_INC_REJECTED(lc);
        fprintf(stderr,
            "%s: function %s: IR_PHI missing phi_pairs\n",
            LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE,
            lc->fn->name->data);
        llEmitCapabilityCountersOnce(lc->totals);
        exit(1);
    }
    // Pre-ordering invariant (see c1.1/phi-onepass-safety.txt):
    // every incoming ir_block must precede the merge block in
    // fn->blocks, so by the time we reach this arm, every
    // incoming value is already bound to lc->values.
    LLVMTypeRef phi_ty = llLowerType(lc, ins->dst->type);
    LLVMValueRef phi_node = LLVMBuildPhi(builder, phi_ty, "");
    unsigned n = (unsigned)vecSize(ins->extra.phi_pairs);
    LLVMValueRef *incoming_values =
        (LLVMValueRef *)malloc(sizeof(LLVMValueRef) * n);
    LLVMBasicBlockRef *incoming_blocks =
        (LLVMBasicBlockRef *)malloc(sizeof(LLVMBasicBlockRef) * n);
    for (unsigned i = 0; i < n; ++i) {
        IrPair *p = (IrPair *)vecGet(ins->extra.phi_pairs, i);
        if (!p || !p->ir_value || !p->ir_block) {
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: IR_PHI incoming pair %u "
                "missing ir_value or ir_block\n",
                LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE,
                lc->fn->name->data, i);
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        incoming_values[i] = llLowerValue(lc, p->ir_value);
        incoming_blocks[i] = llGetOrCreateBlock(lc, p->ir_block);
    }
    LLVMAddIncoming(phi_node, incoming_values, incoming_blocks, n);
    free(incoming_values);
    free(incoming_blocks);
    llCacheValue(lc, ins->dst, phi_node);
    LL_INC_SUPPORTED(lc);
    return LLVMValueRef-as-return-value;
}
```

Invariants:
* `LLVMBuildPHI` is positioned at the builder cursor; PHI nodes
  must be at the start of a basic block. The dispatcher
  enforces this by placing PHI lowering first in the block walk.
* `IR_VAL_TMP` operands only (per C1 provenance); the SHAPE_DEPENDENT
  guard rejects every other shape with the new diagnostic.
* No case-(a)/(b) implications: the result of a PHI is a fresh
  SSA value, not a memory-backed local.
* Pre-ordering invariant (proven in c1.1/phi-onepass-safety.txt):
  every incoming `ir_block` precedes the merge block in
  `fn->blocks`, so `llLowerValue(lc, p->ir_value)` resolves
  to a cached SSA value before the merge block is visited.
* The existing C6 IR opcode table (`src/llvm-backend-cap.c`)
  updates: `IR_PHI` from `LLVMBC_REJECTED` to
  `LLVMBC_SHAPE_DEPENDENT` (NOT `LLVMBC_SUPPORTED`). The
  diagnostic field for `IR_PHI` is `NULL` (per
  `llvm-backend-cap.h` SHAPE_DEPENDENT contract: the SHAPE
  matrix lives in the dispatch comment; runtime enforcement
  is per-shape inside the dispatch itself).
* A new diagnostic macro `LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE`
  is added to `src/llvm-backend.h`. It is reserved for the
  C1.1 dispatch-arm's SHAPE_DEPENDENT rejection paths.
  The legacy `LLVM_BACKEND_UNSUPPORTED_PHI` is REMOVED from
  the dispatch (its only remaining use was the REJECTED-class
  default arm, which is now superseded by the SHAPE_DEPENDENT
  arm).

Two-phase fallback: if a future PHI producer violates the
pre-ordering invariant (e.g., a loop-carried short-circuit),
the bounded fallback is to split the dispatch arm into a
two-phase lowering:

  * Phase 1 (during block walk): create the PHI node, cache
    (merge_block, dst, phi_node) and (ir_block, ir_value,
    phi_node) into a deferred list.
  * Phase 2 (after all blocks lowered): resolve incoming
    values via `llLowerValue` and call `LLVMAddIncoming`.

The C2 IMPL-B (if released by C3) MUST use one-pass because
the only current producer shape has the pre-ordering invariant;
two-phase is preserved as a bounded fallback only.

### Strengthened PHI-B shape contract (C2-A.1, before C4 release)

Per LLVM LangRef, a PHI must have exactly one incoming
`(value, block)` pair for each predecessor of the merge
block, with PHIs preceding non-PHI instructions in the
block. The C1.1 SHAPE_DEPENDENT guard was insufficient
(only checked "block belongs to function"). The
STRENGTHENED contract for C4 IMPL-B is:

```text
  IR_PHI accepted iff:

    dst != NULL
    dst.kind == IR_VAL_TMP
    dst.type == IR_TYPE_I8

    phi_pairs != NULL
    pair_count == CFG_predecessor_count(current_block)

    for each pair P:
      P != NULL
      P.ir_value != NULL
      P.ir_block != NULL

      P.ir_block IS an actual predecessor of current_block
      P.ir_block occurs exactly once in phi_pairs
      (set semantics, not multiset)

      P.ir_value.type == IR_TYPE_I8
        OR P.ir_value is an I8-compatible constant
        (per the existing neutral-IR type contract)

    every predecessor of current_block occurs exactly once
    in phi_pairs

  AND:

    IR_PHI is the FIRST instruction in the merge block
    (no non-PHI instruction precedes it in the neutral IR
    order; the C4 IMPL-B verifies this with the same
    pre-ordering argument as the C1.1 lowering safety proof,
    applied to within-block instruction ordering).

  rejected shapes use:
    LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE
```

This contract is stronger than the C1.1 freeze in three ways:

1. Each incoming block must be an ACTUAL predecessor of
   the merge block (not merely a block in fn->blocks).
2. The predecessor set has set semantics: each predecessor
   appears exactly once. The PHI's `pair_count` must equal
   the CFG's `predecessor_count(current_block)`.
3. The IR_PHI must be the first instruction in the merge
   block; non-PHI instructions may not precede it.

The "exactly once" property is what guarantees LLVM
semantics: each predecessor edge contributes one and only
one incoming value.

The "PHI first in block" property is verified mechanically:
for every current IR_PHI producer, the merge block's first
instruction is the IR_PHI. The C1.1 pre-ordering argument
extends to within-block instruction ordering in the C4
IMPL-B's verification step.

Hard stop: if Fix B's implementation requires additional LLVM
C-API calls beyond `LLVMBuildPHI` + `LLVMAddIncoming` + the
existing `llLowerValue` / `llLowerType` / `llGetOrCreateBlock`
seams, this ACT halts as HALT_SCOPE_EXPANSION_REQUIRED.

---

## 10. Commit topology

```text
C1 RED        (committed; RED at 982dfa3)
                ACT + 12 C1 evidence files

C1.1 RED      (committed; RED at adcbca1)
                ACT corrections (5 contract defects)
                + 3 C1.1 evidence files:
                  - c1.1-patch-summary.md
                  - negative-control.txt
                  - phi-onepass-safety.txt

C2 IMPL-A     (committed; IMPL at c03b2346; HALT_C2A_INCOMPLETE)
                widened Gate 4 (read envelope); revealed Gate 5 gap
                + 2 C2 evidence files:
                  - baseline-pre-c2a.txt
                  - post-c2a-result.txt

C2-A.1 RED    (this commit)
                ACT correction: Rule 5 = observable sink
                + 1 C2.1 evidence file:
                  - rule5-observable-sink.txt
                NO production change.

C2-A.2 IMPL   (next; same ACT)
                widen Gate 5: admit Sink C = IR_STORE_DEREF(r1==V)
                add GN5_out_and_unsupported_use.HC negative control
                + GN5b positive control

C3 EVIDENCE-A (only after C2-A.2)
                G1 PASS / G2 PASS / G3 UNSUPPORTED_PHI / GN4 still
                rejected / GN5 still rejected / GN5b PASS / P5-P11 7/7
                strengthen PHI-B shape contract per LLVM LangRef
                decide C4_IMPL_B_AUTH

C4 IMPL-B     (ONLY IF C3 releases it)
                add case IR_PHI: arm to llLowerInstr (SHAPE_DEPENDENT)
                + STRENGTHENED shape validation:
                  - pair_count == CFG predecessor count
                  - each incoming block is actual predecessor
                  - each predecessor represented exactly once
                  - incoming type compatible with I8 PHI
                  - no non-PHI precedes PHI in merge block
                add LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE
                update src/llvm-backend-cap.c IR_PHI to SHAPE_DEPENDENT

C5 EVIDENCE-B
                ScanIdent compiles + verifies + runs against oracle
                ALL conservation gates GREEN
                patch hygiene clean

C6 CLOSE      (verdict per outcome)
```

Hard stop rule: if C3 finds that path 2 (PHI) is the only remaining
blocker AND Fix B's STRENGTHENED contract (above) can be
implemented without scope expansion, proceed to C4. Otherwise,
halt after C3 with verdict `HALT_SECOND_SEAM_REQUIRED` and a
smaller IR_PHI-only ACT, named mechanically.

## 10.1 Architectural inference refinement (C2-A.1)

The recon's two-seam framing was empirically incomplete.
C2-A revealed that Gate 4 (read envelope) and Gate 5 (return
sink) are TWO FACETS of the same Option-W eligibility seam:

```text
A1 = legal read/use shape        (Gate 4; widened in C2-A)
A2 = observable sink shape       (Gate 5; widened in C2-A.2)
B  = IR_PHI backend support      (Gate dispatch; seam B)
```

This is more truthful than the recon's "A / B" framing.

The C function `llOptionW_FeedsReturnOrIsReturnLocal` keeps
its historical name (recorded as legacy naming debt). Its
SEMANTIC contract is now observable-sink (not return-sink):

  Sink A: direct function return (unchanged)
  Sink B: compiler-generated return slot (unchanged)
  Sink C: IR_STORE_DEREF(r1==V, dst!=V, r2!=V) [NEW in C2-A.2]

The frozen implementation contract for Sink C is in
`evidence/c2.1/rule5-observable-sink.txt`.

F14 hygiene residue: the C1 IR captures (g1/g2/g3 .ir.txt)
were later stripped of whitespace at commit 6512e0f. Future
ACTs must follow the F14 hygiene-preserving pattern
(preserve historical artifact; record hygiene defect in new
evidence rather than modifying old captures).

---

## 11. Acceptance criteria

1. AC01  Entry HEAD is the C3 CLOSE of `B0-SUBSTRATE-RECON01`.
2. AC02  C1 freezes three minimal geometries (G1, G2, G3).
3. AC03  C1 freezes `IR_STORE_DEREF` operand layout.
4. AC04  C1 freezes `IR_PHI` provenance.
5. AC05  C1 freezes the Option-W widening contract with negative
         and positive controls.
6. AC06  C2-A widens `llOptionW_ReadsAreLowerable` EXACTLY as
         frozen in §8 (no other changes).
7. AC07  C3 GREENs P1, P2, P5-P11 (LOCAL-MEM2REG regression).
8. AC08  C3 reports P3 (G3) failure mode:
         (a) passes after Fix A only - halt with HALT_SECOND_SEAM_REQUIRED;
         (b) still fails on path 2 - proceed to C4.
9. AC09  If C4 runs: C5 GREENs P3 (G3 / ScanIdent).
10. AC10 ScanIdent runtime oracle matches `evidence/c1/scanident-
         binding-fixture.txt` tests 01-10.
11. AC11 LOCAL-MEM2REG predecessor (`LL_INC_SHAPE_DEPENDENT` /
         `LLVM_BACKEND_UNSUPPORTED_OPTION_W_INELIGIBLE` /
         capability counter semantics) UNCHANGED.
12. AC12 No production semantic change OUTSIDE the frozen
         C2-A/C4-B seams (seam A: IR_STORE_DEREF value-read
         admission; seam B: existing short-circuit IR_PHI
         lowering).
13. AC13 No new `.sh` files added.
14. AC14 Functional compiler gates GREEN (GEP01/BYTE-MEMORY/
         INT-OPS/IR-RETURN-SLOT-FWD/SPIKE/CAP-TABLE/SHELL-LOC).
15. AC15 Factory gates GREEN (v2-commit-msg-check /
         append-only-test / closure-status).
16. AC16 `harness-evidence-isolation-test` recorded as
         ENVIRONMENTALLY UNAVAILABLE (not PASS) per expert
         review.
17. AC17 Commit-range patch hygiene truthful (`git diff --check`
         clean across the contiguous ACT range).
18. AC18 Working tree clean at CLOSE.
19. AC19 Verdict is one of: `PASS`, `HALT_SECOND_SEAM_REQUIRED`,
         `HALT_SUBSTRATE_GAP_NAMED`, `HALT_SCOPE_EXPANSION_REQUIRED`.

### C1.1 contract-correction acceptance criteria

20. AC20 C1.1 freezes `IR_PHI` capability class as
         `LLVMBC_SHAPE_DEPENDENT` (NOT `LLVMBC_SUPPORTED`).
21. AC21 C1.1 freezes the SHAPE_DEPENDENT validation contract
         (dst.kind == IR_VAL_TMP, dst.type == IR_TYPE_I8,
         phi_pairs != NULL, every incoming pair has ir_value
         and ir_block).
22. AC22 C1.1 freezes the pre-ordering invariant for one-pass
         PHI lowering (every incoming ir_block precedes the
         merge block in fn->blocks) and the two-phase fallback
         for future producers that violate the invariant.
23. AC23 C1.1 freezes a mechanical negative-control witness
         (GN4_neg.HC) for the read-envelope widening, with a
         named diagnostic (`OPTION_W_INELIGIBLE`) - NOT a
         frontend crash.
24. AC24 C2-A must verify that GN4_neg.HC is STILL rejected
         after the widening, with the SAME diagnostic and
         CAPABILITY_COUNTERS state as pre-C2.
25. AC25 C2-A must verify that no IR_PHI-related diagnostic
         fires for any G1, G2, G3, or LOCAL-MEM2REG regression
         test (the seam-A widening is bounded to the read
         envelope; it does not touch any IR_PHI code path).
26. AC26 C4 IMPL-B (if released) must use the SHAPE_DEPENDENT
         guard from §9 and reject every other shape with
         `LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE`.
27. AC27 C4 IMPL-B (if released) must transition `IR_PHI` in
         `src/llvm-backend-cap.c` from `LLVMBC_REJECTED` to
         `LLVMBC_SHAPE_DEPENDENT` (diagnostic = NULL).
28. AC28 C1.1 freezes the book-keeping corrections:
         (a) "8 evidence files" -> "12 C1 evidence files";
         (b) G1 caption "no CFG merge" -> "no neutral-IR PHI".

### C2-A.1 authorization correction acceptance criteria

29. AC29 C2-A.1 freezes the Rule 5 semantic redefinition from
         return-sink to observable-sink.
30. AC30 C2-A.1 freezes Sink C as the ONLY new approved sink:
         `IR_STORE_DEREF(r1==V, dst!=V, r2!=V)`.
31. AC31 C2-A.1 freezes the strengthened negative control
         (GN5_out_and_unsupported_use.HC) with a positive
         control (GN5b.HC).
32. AC32 C2-A.1 freezes the historical-naming-debt clause:
         the C function keeps `llOptionW_FeedsReturnOrIsReturnLocal`
         but the SEMANTIC contract is observable-sink.

### C2-A.2 implementation acceptance criteria

33. AC33 C2-A.2 widens ONLY `llOptionW_FeedsReturnOrIsReturnLocal`
         (Sink C arm); no other production source files modified.
34. AC34 C2-A.2 transition matrix:
         G1 PASS, G2 PASS, G3 UNSUPPORTED_PHI, GN4 still
         rejected, GN5 still rejected (imul violates Gate 3),
         GN5b PASS (positive control), P5-P11 7/7 PASS.
35. AC35 If the C2-A.2 matrix is NOT achieved, HALT and require
         a full discriminator gate audit (HALT_GATE_AUDIT_REQUIRED).
36. AC36 C2-A.2 does not change Gate 3 (definition forms)
         or Gate 4 (read envelope).
37. AC37 C2-A.2 adds GN5/GN5b to the regression set as P12/P13.

---

## 12. HALT taxonomy

```text
PASS                       (Outcome A: both seams fixed)
HALT_SECOND_SEAM_REQUIRED  (Outcome B: Fix A only; open IR_PHI ACT)
HALT_SUBSTRATE_GAP_NAMED   (Outcome C: widening insufficient)
HALT_SCOPE_EXPANSION_REQUIRED  (Fix B needs more than the
                                frozen contract allows)
HALT_CONSERVATION_REGRESSION   (any required gate regressed)
HALT_LLVM_VERIFY               (llvm-as or opt --passes=verify fails)
HALT_RUNTIME_MISMATCH          (ScanIdent oracle mismatch)
HALT_NEGATIVE_CONTROL_REGRESSION  (C2-A: GN4_neg.HC becomes
                                   accepted after widening)
HALT_PHI_PREORDERING_VIOLATED    (a future IR_PHI producer violates
                                   the pre-ordering invariant and
                                   requires two-phase lowering)
HALT_C2A_INCOMPLETE             (committed at c03b2346; the
                                  read-envelope widening alone
                                  was insufficient because Gate 5
                                  (FeedsReturn) also rejects
                                  B0-shaped out-param code)
HALT_GATE_AUDIT_REQUIRED        (a new gate, not addressed by
                                  the frozen contract, rejects
                                  a probe; the discriminator
                                  itself needs a full audit)
```

---

## 13. Explicit non-goals

```text
BOOTSTRAP01 itself
ARRAY01
STRUCT01
BYTE-STORE01
a string-library ACT
a malloc ACT
a parser
a preprocessor
a macro engine
PHI for memory-backed LVars   (still owned by LLVM mem2reg)
general IR_PHI lowering       (only short-circuit logical PHIs)
                                with SHAPE_DEPENDENT guard per C1.1
the legacy LLVM_BACKEND_UNSUPPORTED_PHI diagnostic removal
                                (replaced by
                                 LLVM_BACKEND_UNSUPPORTED_PHI_ORTHOGONAL_TO_CORE;
                                 the old macro's only call site
                                 was the REJECTED default arm,
                                 which is now superseded by the
                                 SHAPE_DEPENDENT arm)
general SELECT / SWITCH lowering
                                (still REJECTED)
a Bash migration
Track B (codium-polyc2)       (independent)
```

---

## 14. Required final report

VERDICT, IDENTITY (ENTRY_HEAD / C1_RED / C1.1_RED / C2_IMPL-A /
C3_EVIDENCE-A / C4_IMPL-B [if run] / C5_EVIDENCE-B [if run] /
C6_CLOSE / FINAL_HEAD / WORKTREE), ARCHITECTURAL INFERENCE
(two-seam split; corrected PHI ownership; C1.1 contract
corrections), GEOMETRY PROBES (G1, G2, G3), NEGATIVE CONTROL
(GN4_neg.HC rejection status; C2-A AC24), OPTION-W WIDENING
(frozen contract; implemented diff line range; test P1 PASS;
AC25: no IR_PHI diagnostic fires), IR_PHI DISPATCH ARM (only
if C4 ran; SHAPE_DEPENDENT class; frozen contract;
implemented diff line range; test P3 PASS), SCANIDENT ORACLE
(10 tests, runtime output), PRODUCTION DELTA (src/ tests/
shell/ doc/), GATES (functional compiler, factory, environmental),
RESIDUE, ROADMAP STATE, NEXT ACT.
