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

**Production semantic changes:** FORBIDDEN.

**New compiler feature:** FORBIDDEN.

**New LLVM capability:** FORBIDDEN (the widening is local to one
discriminator function plus one dispatch arm; no new LLVM IR
builder calls outside what the LLVM C API already exposes).

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

### G1 - out-param consumer, no CFG merge

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
    // ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01: lower short-circuit
    // logical-result PHIs to LLVMBuildPHI. Provenance (C1) shows
    // that ALL IR_PHI in the neutral IR are produced by
    // src/ir.c:535/566/592 (logical short-circuit); operands are
    // therefore IR_VAL_TMP carrying I8 values.
    //
    // The destination is placed at the start of the current block
    // (LLVMBuildPHI returns a PHI node positioned at builder).
    if (!ins->dst || !ins->extra.phi_pairs) {
        // malformed PHI; defensive reject
        fprintf(stderr,
            "%s: function %s: malformed IR_PHI "
            "(missing dst or phi_pairs)\n",
            LLVM_BACKEND_INTERNAL, fn->name->data);
        return 1;
    }
    LLVMTypeRef phi_ty = llLowerType(lc, ins->dst->type);
    LLVMValueRef phi_node = LLVMBuildPhi(builder, phi_ty, "");
    unsigned n = (unsigned)vecSize(ins->extra.phi_pairs);
    LLVMValueRef *incoming_values =
        (LLVMValueRef *)malloc(sizeof(LLVMValueRef) * n);
    LLVMBasicBlockRef *incoming_blocks =
        (LLVMBasicBlockRef *)malloc(sizeof(LLVMBasicBlockRef) * n);
    for (unsigned i = 0; i < n; ++i) {
        IrPair *p = (IrPair *)vecGet(ins->extra.phi_pairs, i);
        incoming_values[i] = llLowerValue(lc, p->ir_value);
        incoming_blocks[i] = llGetOrCreateBlock(lc, p->ir_block);
    }
    LLVMAddIncoming(phi_node, incoming_values, incoming_blocks, n);
    free(incoming_values);
    free(incoming_blocks);
    llCacheValue(lc, ins->dst, phi_node);
    return 0;
}
```

Invariants:
* `LLVMBuildPHI` is positioned at the builder cursor; PHI nodes
  must be at the start of a basic block. The dispatcher
  enforces this by placing PHI lowering first in the block walk.
* `IR_VAL_TMP` operands only (per C1 provenance).
* No case-(a)/(b) implications: the result of a PHI is a fresh
  SSA value, not a memory-backed local.
* The existing C6 IR opcode table
  (`src/llvm-backend-cap.c`) updates:
  `IR_PHI` from `LLVMBC_REJECTED` to `LLVMBC_SUPPORTED`.

Hard stop: if Fix B's implementation requires additional LLVM
C-API calls beyond `LLVMBuildPHI` + `LLVMAddIncoming` + the
existing `llLowerValue` / `llLowerType` / `llGetOrCreateBlock`
seams, this ACT halts as HALT_SCOPE_EXPANSION_REQUIRED.

---

## 10. Commit topology

```text
C1 RED        (this commit)
                ACT + 6 C1 evidence files

C2 IMPL-A     (Fix A only)
                widen llOptionW_ReadsAreLowerable
                rebuild hcc
                verify: G1 PASS, G2 PASS, G3 still FAIL on path 2

C3 EVIDENCE-A
                P1 PASS, P2 PASS, P5-P11 PASS (LOCAL-MEM2REG regression)
                P3 still FAIL on path 2 (PHI)
                C3 freeze the two-seam result

C4 IMPL-B     (ONLY IF C3 finds path 2 still blocks)
                add case IR_PHI: arm to llLowerInstr
                update src/llvm-backend-cap.c IR_PHI to SUPPORTED
                rebuild hcc

C5 EVIDENCE-B
                ScanIdent compiles + verifies + runs against oracle
                ALL conservation gates GREEN
                patch hygiene clean

C6 CLOSE      (verdict per outcome)
```

Hard stop rule: if C3 finds that path 2 (PHI) is the only remaining
blocker AND Fix B's contract in §9 above can be implemented
without scope expansion, proceed to C4. Otherwise, halt after C3
with verdict `HALT_SECOND_SEAM_REQUIRED` and a smaller IR_PHI-
only ACT, named mechanically.

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
12. AC12 No production semantic change.
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
the LLVM_BACKEND_UNSUPPORTED_PHI diagnostic removal
                                (kept as the rejection path for
                                 malformed or out-of-contract PHIs)
Track B (codium-polyc2)       (independent)
a Bash migration
```

---

## 14. Required final report

VERDICT, IDENTITY (ENTRY_HEAD / C1_RED / C2_IMPL-A / C3_EVIDENCE-A /
C4_IMPL-B [if run] / C5_EVIDENCE-B [if run] / C6_CLOSE / FINAL_HEAD /
WORKTREE), ARCHITECTURAL INFERENCE (the two-seam split; the
corrected statement of PHI ownership), GEOMETRY PROBES (G1, G2, G3),
OPTION-W WIDENING (frozen contract; implemented diff line range;
test P1 PASS), IR_PHI DISPATCH ARM (only if C4 ran; frozen contract;
implemented diff line range; test P3 PASS), SCANIDENT ORACLE (10
tests, runtime output), PRODUCTION DELTA (src/ tests/ shell/ doc/),
GATES (functional compiler, factory, environmental), RESIDUE,
ROADMAP STATE, NEXT ACT.
