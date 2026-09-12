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

## 9.1 C3.1 RED: PHI incoming-edge type binding (Outcome B)

The C1.1 contract above was incomplete: it assumed `llLowerValue`
of any incoming edge would produce an LLVM value whose type
matches the PHI's neutral-IR type (i8). The mechanical witness
at `evidence/c3.1/witness.c` proves this is FALSE for IR_ICMP
producers:

```text
Value                                    LLVMTypeOf  width  name
(1) constant '1' (IR_TYPE_I8)            i8          8      i8
(2) LLVMBuildICmp result (IR_ICMP dst)   i1          1      i1   <- mismatch
(3) constant '1' (IR_TYPE_I64) [control] i64         64     i64
```

Per the C1.1 expert review's trichotomy, this is **Outcome B**
(incoming LLVM value is `i1`). The C4 contract is therefore
AMENDED to insert an explicit `i1 -> i8` normalisation before
`LLVMAddIncoming` for IR_ICMP-produced incoming edges.

```c
for (unsigned i = 0; i < n; ++i) {
    IrPair *p = (IrPair *)vecGet(ins->extra.phi_pairs, i);
    if (!p || !p->ir_value || !p->ir_block) { ... REJECT ... }
    LLVMValueRef v = llLowerValue(lc, p->ir_value);
    /* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3.1 RED (Outcome B):
     * IR_ICMP producers lower to LLVM i1 (via LLVMBuildICmp at
     * src/llvm-backend.c:2598). When the PHI dst type is i8,
     * the incoming i1 must be zero-extended to i8 before
     * LLVMAddIncoming, or the LLVM verifier will reject the
     * module with a type-mismatch diagnostic. The zext is the
     * identity bit-pattern on {0, 1} (the IR_ICMP result
     * contract; runtime-witnessed at src/llvm-backend.c:1815-1872
     * since CORRECTION01). */
    if (LLVMTypeOf(v) == LLVMInt1TypeInContext(lc->ctx) &&
        phi_ty == LLVMInt8TypeInContext(lc->ctx)) {
        v = LLVMBuildZExt(lc->bld, v,
              LLVMInt8TypeInContext(lc->ctx),
              "phi_icmp_zext");
        LL_INC_SHAPE_DEPENDENT(lc); /* named account: phi_icmp_zext */
    }
    incoming_values[i] = v;
    incoming_blocks[i] = llGetOrCreateBlock(lc, p->ir_block);
}
```

This normalisation is **short-circuit-compare PHI incoming
normalisation ONLY**. A non-i8 PHI (e.g. an i64 SSA phi from a
fused IR_SEL-like construct) is out of scope and would require
a separate contract amendment (P1 residue; see c3.1-red.txt).

`C4_IMPL_B_AUTH = TRUE` is **REAFFIRMED** with this amended
contract. The hard-stop rule is satisfied: the conversion is
narrow, mechanically verifiable, and bound to the IR_PHI
dispatch arm's incoming-edge iteration.

No new diagnostic macros. No new counter increments
(LL_INC_SHAPE_DEPENDENT already exists). No change to Gate 3,
Gate 4, or Gate 5 logic. No change to `llType` or `llLowerValue`.

New HALT taxonomy entry:

* `HALT_PHI_TYPE_CONTRACT_REQUIRED` — Outcome D; neutral IR
  inconsistency; not observed (Outcome B observed instead).

## 9.2 C3.2 RED: PHI incoming-edge normalisation placement

The §9.1 amendment was correct about the **type binding** (i1
must be zero-extended to i8) but WRONG about the **placement**
of the zero-extension. It emitted the zext inside the merge
block, after the PHI:

```c
/* C3.1 (WRONG) placement -- emits zext in merge block */
LLVMPositionBuilderAtEnd(bld, merge_block);
LLVMValueRef phi = LLVMBuildPhi(bld, i8, "phi");
LLVMValueRef z   = LLVMBuildZExt(bld, cmp_i1, i8, "zext_in_merge");
LLVMAddIncoming(phi, &z, &pred_block, 1);
```

This produces the IR

```llvm
merge:
  %phi = phi i8 [ %z, %pred ]
  %z = zext i1 %cmp to i8
  ret void
```

which the LLVM verifier **rejects** with

```text
Instruction does not dominate all uses!
  %z = zext i1 %cmp to i8
  %phi = phi i8 [ %z, %pred ]
```

because the PHI's incoming-value use conceptually occurs on the
predecessor edge (`pred -> merge`), but the zext is defined
*after* entering the merge block, so it does not dominate that
use. PHIs are also required by the LangRef to be the first
instructions of their basic block, so reordering the zext above
the PHI is not a valid alternative.

The mechanical witness at `evidence/c3.2/witness.c` proves both
geometries against the LLVM 22 C API (linked into the standalone
binary, same `llvm-config --version = 22.1.8` as production
`hcc`):

| variant                  | verify return | message                                       |
|--------------------------|---------------|-----------------------------------------------|
| `c32_bad` (zext in merge)| `1` (invalid) | "Instruction does not dominate all uses! %z = zext i1 %cmp to i8  %phi = phi i8 [ %z, %pred ]" |
| `c32_good` (zext in pred)| `0` (valid)   | (none)                                        |

**Outcome C (placement bug)** is OBSERVED. The C3.1 §9.1
amendment is therefore INCOMPLETE.

### Corrected §9.2 algorithm

The zext MUST be materialised in the **incoming predecessor
block, immediately before its terminator**:

```c
for (unsigned i = 0; i < n; ++i) {
    IrPair *p = (IrPair *)vecGet(ins->extra.phi_pairs, i);
    if (!p || !p->ir_value || !p->ir_block) { ... REJECT ... }
    LLVMValueRef v = llLowerValue(lc, p->ir_value);
    if (LLVMTypeOf(v) == LLVMInt1TypeInContext(lc->ctx) &&
        phi_ty == LLVMInt8TypeInContext(lc->ctx)) {
        /* Predecessor-edge materialisation: */
        LLVMBasicBlockRef pred_bb =
            llGetOrCreateBlock(lc, p->ir_block);
        /* PI-1: pred_bb exists.
           PI-2: pred_bb has a terminator (otherwise the
                 predecessor hasn't been finalised yet --
                 HALT_PHI_EDGE_MATERIALIZATION_REQUIRED).
           PI-3: the incoming value v has already been lowered
                 into pred_bb (verified by the runtime witness
                 since CORRECTION01 at src/llvm-backend.c:
                 1815-1872 -- the IR_ICMP and IR_BR producer
                 always emit cmp on the predecessor before
                 its terminator). */
        LLVMValueRef pred_term =
            LLVMGetBasicBlockTerminator(pred_bb);
        if (!pred_term) {
            /* PI-2 violated. */
            LC_HALT(lc, LLVM_BACKEND_UNSUPPORTED_PHI,
                    "HALT_PHI_EDGE_MATERIALIZATION_REQUIRED: "
                    "predecessor has no terminator");
        }
        LLVMBasicBlockRef save = LLVMGetInsertBlock(lc->bld);
        LLVMPositionBuilderBefore(lc->bld, pred_term);
        v = LLVMBuildZExt(lc->bld, v,
              LLVMInt8TypeInContext(lc->ctx),
              "phi_icmp_zext");
        LLVMPositionBuilderAtEnd(lc->bld, save);
        LL_INC_SHAPE_DEPENDENT(lc);
    }
    incoming_values[i] = v;
    incoming_blocks[i] = pred_bb;
}
```

This produces the IR

```llvm
pred:
  %cmp = icmp sgt i64 %x, %y
  %phi_icmp_zext = zext i1 %cmp to i8
  br label %merge
merge:
  %phi = phi i8 [ %phi_icmp_zext, %pred ]
  ret void
```

which the LLVM verifier accepts (`verify return = 0` per the
witness). The zext now dominates the PHI's incoming-edge use
on the `pred -> merge` edge.

### Predecessor-materialisation invariants

The C4 implementation MUST runtime-assert these before calling
`LLVMGetBasicBlockTerminator`:

* **PI-1** the incoming predecessor LLVM block already exists
  (the predecessor has been materialised in the same lowering
  pass).
* **PI-2** the incoming predecessor LLVM block already has a
  terminator (preorder traversal has reached it).
* **PI-3** the incoming value has already been lowered into the
  predecessor block.

PI-1/PI-2/PI-3 hold by the preorder proof already recorded in
the ACT for current short-circuit producers (incoming
predecessor block < merge block in backend traversal order; see
`HALT_PHI_PREORDERING_VIOLATED`). If any of PI-1, PI-2, or PI-3
fails at PHI-lowering time, the C4 implementation MUST halt
with `HALT_PHI_EDGE_MATERIALIZATION_REQUIRED` and surface the
offending predecessor + incoming edge.

### Build-position discipline

The save/restore pattern is bounded by the incoming-edge loop
body and never escapes it. Equivalent to using a dedicated edge
builder (which is also acceptable per the expert's
recommendation), but a careful `LLVMGetInsertBlock` /
`LLVMPositionBuilderAtEnd` restore suffices for correctness.

### Counter semantics (P0 residue)

`LL_INC_SHAPE_DEPENDENT` currently denotes "shape-dependent
helper action"; per-PHI it counts as one helper action
regardless of how many incoming edges are converted. This must
be agreed with the harness contract before C4 (AC47-adjacent).

### C4_IMPL_B_AUTH

REVOKED (third revocation). C4 IMPL-B is locked until:

* R1 the §9.2 corrected algorithm is implemented;
* R2 the PI-1/PI-2/PI-3 runtime assertions are added;
* R3 the `LL_INC_SHAPE_DEPENDENT` counting semantics are agreed
  with the harness contract;
* R4 a fresh `c4/witness.c` re-confirms the geometry.

### Scope (NO EXPANSION)

* No new diagnostic macros.
* No new counter increments (`LL_INC_SHAPE_DEPENDENT`
  pre-exists).
* No change to Gate 3 / Gate 4 / Gate 5 logic.
* No change to `llType` or `llLowerValue`.
* The placement lives entirely inside the IR_PHI dispatch arm's
  incoming-edge iteration loop.

### New HALT taxonomy entry

* `HALT_PHI_EDGE_MATERIALIZATION_REQUIRED` — an incoming
  predecessor fails PI-1, PI-2, or PI-3 at PHI-lowering time;
  triggered only if the C3.2 §9.2 corrected algorithm
  encounters a shape that the preorder proof does not cover.
  The C4 implementation MUST halt with this verdict and surface
  the offending predecessor + incoming edge; it MUST NOT
  improvise a two-phase fallback without an explicit bounded
  amendment.

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
existing `llLowerValue` / `llLowerType` / `llbmGet`
(lookup-only; see §9.3) seams, this ACT halts as
HALT_SCOPE_EXPANSION_REQUIRED.

---

## 9.3 C3.3 RED: PHI dispatch-arm contract mechanics

The C3.2 §9.2 corrected algorithm was correct about the SSA
placement of the zext but had THREE remaining contract defects
in its mechanics. C3.3 freezes the corrections.

### §9.3.1 PI-1 lookup-only predicate (D1 correction)

C3.2 §9.2 wrote:

```c
pred_bb := llGetOrCreateBlock(lc, p->ir_block)
ASSERT PI-1: pred_bb already existed
```

These two operations contradict each other. A get-or-create
accessor destroys the information PI-1 is supposed to test:
if the predecessor LLVM block does not yet exist, the
get-or-create accessor fabricates an empty `LLVMBasicBlockRef`,
after which `pred_bb != NULL` says nothing about whether
preorder materialisation occurred. PI-2 (terminator present)
would happen to catch the defect, but only by coincidence.

C3.3 freezes the correct predicate:

```c
pred_bb := llbmGet(&lc->blocks, p->ir_block)
if pred_bb == NULL:
    HALT_PHI_EDGE_MATERIALIZATION_REQUIRED
          "predecessor block id %u was not pre-allocated
           by llCreateBlocks; preorder materialisation is
           required before the IR_PHI dispatch arm runs."
```

`llbmGet` is the existing lookup-only predicate at
`src/llvm-backend.c:270-273`. It returns `NULL` for any id
outside the pre-allocated range (set up by `llCreateBlocks`
at `src/llvm-backend.c:1442-1468`, which appends every
`IrBlock` of the current function as an LLVM basic block
BEFORE lowering begins). The C4 implementation MUST use
`llbmGet` (or an equivalent lookup-only predicate) and MUST
NOT introduce a get-or-create accessor.

**Mechanical witness**: `evidence/c3.3/witness-lookup.c`
demonstrates both strategies against a simulated block map
and proves the lookup-only predicate detects a fabricated
block that the get-or-create accessor would silently accept.
Verdict: `OUTCOME_E_PI1_LOOKUP_CONFIRMED`.

### §9.3.2 Per-PHI counter semantic (D2 correction)

C3.2 §9.2 was internally inconsistent. The prose froze:

> `LL_INC_SHAPE_DEPENDENT` ... **per-PHI it counts as one
> helper action regardless of how many incoming edges are
> converted**.

But the pseudocode called:

```c
for each incoming edge:
    ...
    if i1 -> i8:
        ...
        LL_INC_SHAPE_DEPENDENT(lc);   /* inside the loop! */
```

A PHI with two `i1` incoming edges would therefore increment
the counter twice.

C3.3 freezes the corrected semantic, consistent with the
existing capability accounting convention observed at
`src/llvm-backend.c:2024, 2229, 2514, 2846, 3029, 3153`
(all of which increment once per opcode at the top of the
arm, not per-instruction-inside-a-loop):

```text
SHAPE_DEPENDENT for IR_PHI = exactly ONE increment per
successfully accepted IR_PHI shape, AT THE TOP of the arm
(after shape validation, BEFORE the per-edge loop).

Per-edge zext normalisation does NOT contribute a separate
counter increment.
```

**Mechanical witness**: `evidence/c3.3/witness-counter.c`
drives FOUR synthetic IR_PHI cases through the corrected
algorithm and prints the counter delta for each:

| case                | n_edges | converted | delta | expected | result |
|---------------------|---------|-----------|-------|----------|--------|
| `phi_no_zext`       | 1       | 0         | 1     | 1        | OK     |
| `phi_one_zext`      | 2       | 1         | 1     | 1        | OK     |
| `phi_two_zexts`     | 3       | 2         | 1     | 1        | OK     |
| `phi_rejected_shape`| 1       | 0         | 0     | 0        | OK     |

Final counter value: `3`. Verdict: `OUTCOME_D_COUNTER_
SEMANTIC_CONFIRMED`.

**Expected counts for the C2-A.2 frozen matrix when C4 lands**:

```text
G3       : 1 SHAPE_DEPENDENT (one IR_PHI accepted)
PhiOnly  : 1 SHAPE_DEPENDENT (one IR_PHI accepted)
Others   : unchanged (no short-circuit PHI in bounded form)
```

### §9.3.3 PI-3 sharpening (minor)

C3.2 PI-3 said:

> incoming value has already been lowered **into the predecessor
> block**.

That is correct for the `IR_ICMP` values that need edge
normalisation, but too broad as a universal PHI rule.
Constants and arguments do not belong to a predecessor block
at all; LLVM considers them to dominate everywhere.

C3.3 sharpens PI-3:

```text
PI-3:
  the incoming value is already available at the predecessor
  edge.

  For instruction-valued incoming:
    its defining instruction dominates that edge; for the
    current bounded short-circuit geometry, the definition
    is in pred_bb before pred_term.

  For constants and arguments:
    no block-local definition requirement applies.
```

For this ACT, the `i1 -> i8` path is currently `IR_ICMP` only,
so the implementation check stays narrow:

```text
if normalization required:
    producer must be a previously lowered instruction in
    pred_bb, defined before pred_term.
```

No need to generalise the compiler.

### §9.3.4 C4 authorization mechanics (D3 correction)

C3.2 wrote C4 re-entry requirements as:

```text
R1 corrected algorithm is implemented in IR_PHI arm
R2 runtime assertions are added
R4 fresh c4/witness.c proves the implemented algorithm
```

But those are exactly the things C4 IMPL-B is supposed to do,
making C4 logically impossible to authorise
("C4 cannot start until C4 implementation exists").

C3.3 separates the obligations into three phases:

```text
PRE-C4 contract requirements (must be true BEFORE C4 starts):
  P1 contract frozen                        (CLOSED in C3.3)
  P2 counter semantics frozen               (CLOSED in C3.3)
  P3 lookup-only PI-1 mechanism identified  (CLOSED in C3.3)
      (llbmGet, no new code)
  P4 implementation scope frozen            (CLOSED in C3.3 §9.2)

C4 implementation obligations (C4's job):
  R1 implement §9.2 corrected algorithm in IR_PHI arm
  R2 implement PI-1, PI-2, PI-3 (narrow) runtime guards
  R3 implement agreed counter policy (per-PHI, once at top)
  R4 produce fresh c4/witness.c re-confirming the geometry

C5 evidence obligations (C5's job):
  E1 independently validate C4's R1-R4 against ScanIdent
```

The previous circular gate is dissolved.

### §9.3.5 Corrected §9.2 algorithm (consolidated)

```c
case IR_PHI:

    /* shape validation (unchanged from C3.2) */
    validate bounded short-circuit shape
    validate exact predecessor set

    /* §9.3.2: counter once per accepted PHI, at the top */
    LL_INC_SHAPE_DEPENDENT(lc);

    phi = LLVMBuildPhi(lc->bld, LLVMInt8TypeInContext(lc->ctx), "phi")

    for each incoming (v, ir_pred):

        /* §9.3.1: lookup-only predicate, NOT get-or-create */
        pred_bb = llbmGet(&lc->blocks, ir_pred->id)
        if pred_bb == NULL:
            HALT_PHI_EDGE_MATERIALIZATION_REQUIRED

        /* ensure pred_bb is actual CFG predecessor */
        assert_in_predecessor_set(pred_bb)

        /* v is the previously-lowered incoming value */

        if LLVMTypeOf(v) == LLVMInt8TypeInContext(lc->ctx):
            use v directly (constant/argument case)

        else if LLVMTypeOf(v) == LLVMInt1TypeInContext(lc->ctx):
            /* PI-2: predecessor has a terminator */
            pred_term = LLVMGetBasicBlockTerminator(pred_bb)
            if pred_term == NULL:
                HALT_PHI_EDGE_MATERIALIZATION_REQUIRED

            /* §9.3.3 PI-3 narrow: assert v was defined in
               pred_bb before pred_term. */
            assert_instruction_in_block_before(v, pred_bb, pred_term)

            /* §9.2 build-position discipline (unchanged from C3.2) */
            save = LLVMGetInsertBlock(lc->bld)
            LLVMPositionBuilderBefore(lc->bld, pred_term)
            v = LLVMBuildZExt(lc->bld, v,
                  LLVMInt8TypeInContext(lc->ctx),
                  "phi_icmp_zext")
            LLVMPositionBuilderAtEnd(lc->bld, save)

        else:
            HALT_PHI_TYPE_CONTRACT_REQUIRED

        add (v, pred_bb) to PHI incoming list

    cache PHI dst
```

### §9.3.6 Historical C4_IMPL_B_AUTH table

Per the expert's append-only history discipline, the C4
authorization state is recorded as a frozen table:

```text
C3       AUTH=true    SUPERSEDED   (pre-dominance-correction)
C3.1     AUTH=true    SUPERSEDED   (pre-placement-correction)
C3.2     AUTH=false   SUPERSEDED   (pre-mechanics-correction)
C3.3     AUTH=true    CURRENT      (if P1-P4 freeze correctly)
```

No prior commit is rewritten. The current state is the one
that gates C4.

### §9.3.7 Scope (NO EXPANSION)

* No new diagnostic macros (`HALT_PHI_EDGE_MATERIALIZATION_
  REQUIRED` already added in C3.2).
* No new counter increments (`LL_INC_SHAPE_DEPENDENT`
  pre-exists).
* No change to Gate 3 / Gate 4 / Gate 5 logic.
* No change to `llType`, `llLowerValue`, `llCreateBlocks`.
* No new code (`llbmGet` is the existing lookup-only predicate
  at `src/llvm-backend.c:270-273`; C4 reuses it).
* The §9.2 corrected algorithm lives entirely inside the
  IR_PHI dispatch arm.

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

C3.1 RED (only after C3; NO production change)
                mechanical-witness evidence for every PHI incoming edge
                freeze PHI incoming-edge type binding:
                  - constants: llType(IR_TYPE_I8) = LLVMInt8Type
                  - IR_ICMP:   always LLVMInt1Type (via LLVMBuildICmp)
                decide contract amendment (Outcome A/B/C/D)
                  - Outcome B observed: i1 -> i8 zext required
                  - contract AMENDED to add bounded zext
                reaffirm or revoke C4_IMPL_B_AUTH
                  - C4_IMPL_B_AUTH = TRUE (reaffirmed with amendment)

C3.2 RED (only after C3.1; NO production change)
                mechanical-witness evidence of placement correctness:
                  - variant_bad:  zext in merge after PHI
                                  -> LLVM verifier REJECTS
                                     (Instruction does not dominate
                                      all uses)
                  - variant_good: zext in predecessor before terminator
                                  -> LLVM verifier ACCEPTS
                freeze C3.1 §9.1 amendment as INCOMPLETE
                freeze corrected §9.1 algorithm (build-position
                  save/restore across LLVMPositionBuilderBefore)
                freeze predecessor-materialisation invariants
                  PI-1 incoming pred block exists
                  PI-2 incoming pred block has terminator
                  PI-3 incoming value already lowered into pred
                reaffirm or revoke C4_IMPL_B_AUTH
                  - C4_IMPL_B_AUTH = REVOKED (third revocation)

C3.3 RED (only after C3.2; NO production change)
                mechanical-witness evidence of contract mechanics:
                  - PI-1 lookup-only predicate:
                      lookup-only  -> truthful (NULL on miss)
                      get-or-create -> LIES (fabricates on miss)
                  - per-PHI counter semantic (4 cases):
                      no_zext, one_zext, two_zexts -> delta=1
                      rejected_shape              -> delta=0
                freeze three corrections to C3.2 §9.2:
                  §9.3.1 PI-1 lookup-only (llbmGet, not
                         llGetOrCreateBlock)
                  §9.3.2 counter once per accepted PHI
                         (not per edge)
                  §9.3.3 PI-3 sharpened (instruction-valued
                         only; constants/arguments exempt)
                  §9.3.4 mechanics: pre-C4 contract (P1-P4)
                         separate from C4 implementation (R1-R4)
                         separate from C5 evidence (E1)
                reaffirm or revoke C4_IMPL_B_AUTH
                  - C4_IMPL_B_AUTH = TRUE (reaffirmed;
                    pre-C4 contract requirements P1-P4
                    all closed)

C4 IMPL-B     (ONLY IF C3.3 authorises it; currently READY)
                add case IR_PHI: arm to llLowerInstr (SHAPE_DEPENDENT)
                + STRENGTHENED shape validation:
                  - pair_count == CFG predecessor count
                  - each incoming block is actual predecessor
                  - each predecessor represented exactly once
                  - incoming type compatible with I8 PHI
                  - no non-PHI precedes PHI in merge block
                + AMENDED (C3.3) incoming-edge normalisation:
                  - LL_INC_SHAPE_DEPENDENT(lc);  /* ONCE, at top */
                  - for each incoming (v, ir_pred):
                      pred_bb := llbmGet(&lc->blocks,
                                          ir_pred->id)
                      if pred_bb == NULL:
                          HALT_PHI_EDGE_MATERIALIZATION_REQUIRED
                      term := LLVMGetBasicBlockTerminator(pred_bb)
                      if term == NULL:
                          HALT_PHI_EDGE_MATERIALIZATION_REQUIRED
                      /* PI-3 narrow: assert v is in pred_bb
                         before term (if normalisation needed) */
                      if LLVMTypeOf(v) == i1 && phi_ty == i8:
                          save := LLVMGetInsertBlock(lc->bld)
                          LLVMPositionBuilderBefore(lc->bld, term)
                          v    := LLVMBuildZExt(lc->bld, v, i8,
                                                "phi_icmp_zext")
                          LLVMPositionBuilderAtEnd(lc->bld, save)
                      add (v, pred_bb) to PHI incoming list
                + harness-contract alignment on
                  LL_INC_SHAPE_DEPENDENT counting semantics
                  (per-PHI, not per-edge; AC49)
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

### C3.1 contract-amendment acceptance criteria

38. AC38 C3.1 freezes the PHI incoming-edge type-binding
         contract amendment: an IR_ICMP-produced incoming edge
         whose cached LLVM value is `i1` MUST be zero-extended
         to `i8` before `LLVMAddIncoming` when the PHI's
         neutral type is `IR_TYPE_I8`.
39. AC39 C3.1 freezes the mechanical-witness requirement:
         the type binding MUST be captured by exercising the
         LLVM 22 C API on the actual lowering primitives
         (`LLVMConstInt` for constants, `LLVMBuildICmp` for
         IR_ICMP); the captured `LLVMTypeOf` output is the
         authoritative type binding, not the neutral-IR type.
40. AC40 C3.1 freezes the trichotomy outcomes:
         - Outcome A: incoming LLVM value already i8 (no
           conversion); not observed.
         - Outcome B: incoming LLVM value i1 (zext to i8);
           OBSERVED.
         - Outcome C: incoming LLVM value i64 (trunc or zext
           to i8); not observed.
         - Outcome D: neutral IR inconsistent (HALT); not
           observed.
41. AC41 C3.1 reaffirms C4_IMPL_B_AUTH = TRUE with the
         amended contract. The hard-stop rule is satisfied
         because the conversion is narrow (short-circuit PHI
         incoming normalisation only), mechanically
         verifiable (LLVM 22 C API), and bound to the IR_PHI
         dispatch arm's incoming-edge iteration (no general
         integer-conversion widening).

### C3.2 placement-contract acceptance criteria

42. AC42 C3.2 freezes the placement-correctness contract:
         the `LLVMBuildZExt` that normalises an `i1` incoming
         edge to `i8` MUST be emitted on the predecessor edge,
         NOT in the merge block after the PHI. This is the
         SSA dominance rule for PHI operands.
43. AC43 C3.2 freezes the predecessor-materialisation
         invariants that the C4 implementation MUST runtime-
         assert before calling `LLVMGetBasicBlockTerminator`:
         PI-1 the incoming predecessor LLVM block already
              exists (predecessor has been materialised in the
              same lowering pass)
         PI-2 the incoming predecessor block already has a
              terminator (preorder traversal has reached it)
         PI-3 the incoming value has already been lowered
              into the predecessor block
44. AC44 C3.2 freezes the build-position discipline:
         before `LLVMPositionBuilderBefore(bld, pred_term)`,
         save the current insert block; after `LLVMBuildZExt`,
         restore via `LLVMPositionBuilderAtEnd(bld, save)`.
         (Equivalent to using a dedicated edge builder; the
         save/restore pattern is bounded by the incoming-edge
         loop body and never escapes it.)
45. AC45 C3.2 freezes the HALT_PHI_EDGE_MATERIALIZATION_REQUIRED
         halt taxonomy entry (triggered when PI-1, PI-2, or
         PI-3 fails at PHI-lowering time).
46. AC46 C3.2 REVOKES C4_IMPL_B_AUTH for the third time
         because the §9.1 (C3.1) amendment is INCOMPLETE:
         the type binding is correct but the placement is
         wrong. C4 may be reopened only after C3.2 §9.1
         corrected algorithm is implemented and re-confirmed
         by a fresh mechanical witness.
47. AC47 C3.2 requires mechanical-witness evidence of both
         the bad geometry (LLVM verifier REJECTS with
         "Instruction does not dominate all uses") and the
         good geometry (LLVM verifier ACCEPTS). The captured
         artifact is `evidence/c3.2/witness` and its captured
         output `evidence/c3.2/witness.txt`.

### C3.3 contract-mechanics acceptance criteria

48. AC48 C3.3 freezes the PI-1 lookup-only contract:
         the predecessor LLVM block lookup MUST use a
         lookup-only predicate (e.g. `llbmGet`) and MUST
         NOT use a get-or-create accessor. On NULL, the
         C4 implementation MUST halt with
         `HALT_PHI_EDGE_MATERIALIZATION_REQUIRED`.
49. AC49 C3.3 freezes the per-PHI counter semantic:
         `LL_INC_SHAPE_DEPENDENT` MUST fire exactly once
         per successfully accepted IR_PHI shape, AT THE
         TOP of the arm (after shape validation, BEFORE
         the per-edge loop). Per-edge zext normalisation
         MUST NOT contribute a separate counter increment.
         Expected counts for the C2-A.2 frozen matrix
         when C4 lands:
         - `G3`      : 1 SHAPE_DEPENDENT (one IR_PHI)
         - `PhiOnly` : 1 SHAPE_DEPENDENT (one IR_PHI)
50. AC50 C3.3 freezes the C4 authorization mechanics:
         pre-C4 contract readiness (P1-P4) is distinct
         from C4 implementation (R1-R4) and from C5
         evidence (E1). The previous circular gate is
         dissolved. C4 is currently READY (P1-P4 all
         CLOSED in C3.3).
51. AC51 C3.3 freezes the PI-3 sharpening: for
         instruction-valued incoming `v`, the definition
         MUST be in `pred_bb` before `pred_term`. For
         constants and arguments, no block-local
         definition requirement applies. The C4
         implementation narrows PI-3 to the IR_ICMP
         producer case (current bounded short-circuit
         geometry).
52. AC52 C3.3 requires mechanical-witness evidence of:
         (a) per-PHI counter semantic
             (`evidence/c3.3/witness-counter.c`),
             verifying `no_zext`/`one_zext`/`two_zexts`
             all yield `delta=1` and `rejected_shape`
             yields `delta=0`; AND
         (b) PI-1 lookup-only vs get-or-create contrast
             (`evidence/c3.3/witness-lookup.c`),
             verifying that lookup-only detects a
             not-pre-allocated block id while
             get-or-create silently fabricates one.

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
HALT_PHI_TYPE_CONTRACT_REQUIRED (the PHI incoming-edge type
                                  binding cannot be satisfied
                                  without scope expansion or
                                  neutral-IR change; Outcome D
                                  of the C3.1 trichotomy. Not
                                  observed: Outcome B was
                                  observed instead, and the
                                  contract was amended to add
                                  a bounded i1 -> i8 zext.)
HALT_PHI_EDGE_MATERIALIZATION_REQUIRED
                                 (an incoming predecessor
                                  fails PI-1, PI-2, or PI-3
                                  at PHI-lowering time: the
                                  predecessor block does not
                                  exist, has no terminator, or
                                  the incoming value has not
                                  yet been lowered into it.
                                  Triggered only if the C3.2
                                  §9.1 corrected algorithm
                                  encounters a shape that the
                                  preorder proof does not
                                  cover. The C4 implementation
                                  MUST halt with this verdict
                                  and surface the offending
                                  predecessor + incoming
                                  edge; it MUST NOT improvise
                                  a two-phase fallback without
                                  an explicit bounded
                                  amendment.)
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
