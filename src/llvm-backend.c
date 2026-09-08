/* ACT-POLYC-LLVM-SPIKE01-RESUME01: minimal LLVM 22 C-API emitter.
 *
 * Scope (deliberately narrow, see ACT §13-§36):
 *   - I64 parameters, I64 constants, iadd/isub/imul
 *   - signed integer compare eq/ne/lt/le/gt/ge
 *   - unconditional + conditional branches
 *   - direct intra-module function calls
 *   - I64 return (via collapse-elimination; PHI is forbidden)
 *
 * Out of scope (see ACT §13, §59-§63, §33-§34, §48-§50):
 *   - LLVM optimization pipeline, PassBuilder, opt-level
 *   - PHI nodes
 *   - memory / alloca / load / store (when avoidable)
 *   - target machine, object emission, llc/lli/ExecutionEngine
 *   - ORC / JIT / dlopen
 *   - aggregate, pointer, struct, class, F64, F32, U8/U16/U32, IR_ASM,
 *     IR_CMP_BR, IR_RMW_DEREF, IR_SWITCH, IR_PHI, IR_SELECT, IR_VA_*,
 *     bitwise, shifts, division, negation
 *
 * Boundary invariant (ACT §3, §60-§63):
 *   - This consumer reads IR produced by `irLowerFunction` + the
 *     existing neutral opt pass (the same pipeline `irDump` walks).
 *   - It does NOT call `irAssignAbiParamLocations`, does NOT
 *     consult `IrRegPool`, and does NOT read `IrValue->loc` or
 *     `IrValue->pinned_reg`.
 *   - `IrValue->param_kind` is metadata only; this consumer does
 *     not depend on it.
 *
 * Return-value collapse (ACT §30):
 *   PolyC lowers every `return X` to `store return_slot, X; jmp exit`
 *   followed by an exit block with `load return_slot; ret (load)`.
 *   The spike authorises I64 return only via direct branch returns
 *   (PHI is forbidden, ACT §30). We detect this exact shape and
 *   collapse it: for each predecessor of the exit block whose
 *   terminator is `IR_JMP exit_block`, replace `store slot, V; jmp
 *   exit` with `ret V`. The exit block becomes unreachable and is
 *   emitted as `unreachable` for safety. This is a structural
 *   transformation specific to PolyC's return lowering; it is not
 *   a generic PHI-elimination.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "llvm-backend.h"

#include "containers.h"
#include "ir.h"
#include "ir-debug.h"
#include "ir-types.h"
#include "util.h"

#include "llvm-c/Core.h"
#include "llvm-c/Analysis.h"

/* --- small vector-backed maps --------------------------------------------
 *
 * The supported subset is small and the IR IDs are dense. Use vectors
 * keyed by block.id / value.var.id; a missing key is `NULL`. Per ACT §21
 * "Prefer the simplest representation compatible with current IR IDs."
 *
 * Two parallel maps: one for LLVMValueRef (function args, instruction
 * results, constants) and one for LLVMBasicBlockRef (blocks). The two
 * LLVM opaque types are not interchangeable; C does not let us reuse
 * a single void* map safely, so we keep them distinct.
 */

typedef struct LLValMap {
    LLVMValueRef *values;
    u32 cap;
} LLValMap;

typedef struct LLBlockMap {
    LLVMBasicBlockRef *values;
    u32 cap;
} LLBlockMap;

static void llvmInit(LLValMap *b, u32 cap) {
    b->cap = cap;
    b->values = (LLVMValueRef *)calloc(cap ? cap : 1, sizeof(LLVMValueRef));
}

static void llvmGrow(LLValMap *b, u32 needed) {
    if (needed <= b->cap) return;
    u32 newcap = b->cap ? b->cap : 16;
    while (newcap < needed) newcap *= 2;
    b->values = (LLVMValueRef *)realloc(b->values, newcap * sizeof(LLVMValueRef));
    memset(b->values + b->cap, 0, (newcap - b->cap) * sizeof(LLVMValueRef));
    b->cap = newcap;
}

static void llvmSet(LLValMap *b, u32 id, LLVMValueRef v) {
    llvmGrow(b, id + 1);
    b->values[id] = v;
}

static LLVMValueRef llvmGet(LLValMap *b, u32 id) {
    if (!b || !b->values || id >= b->cap) return NULL;
    return b->values[id];
}

static void llbmInit(LLBlockMap *b, u32 cap) {
    b->cap = cap;
    b->values = (LLVMBasicBlockRef *)calloc(cap ? cap : 1, sizeof(LLVMBasicBlockRef));
}

static void llbmGrow(LLBlockMap *b, u32 needed) {
    if (needed <= b->cap) return;
    u32 newcap = b->cap ? b->cap : 16;
    while (newcap < needed) newcap *= 2;
    b->values = (LLVMBasicBlockRef *)realloc(b->values,
        newcap * sizeof(LLVMBasicBlockRef));
    memset(b->values + b->cap, 0, (newcap - b->cap) * sizeof(LLVMBasicBlockRef));
    b->cap = newcap;
}

static void llbmSet(LLBlockMap *b, u32 id, LLVMBasicBlockRef v) {
    llbmGrow(b, id + 1);
    b->values[id] = v;
}

static LLVMBasicBlockRef llbmGet(LLBlockMap *b, u32 id) {
    if (!b || !b->values || id >= b->cap) return NULL;
    return b->values[id];
}

/* --- diagnostic -------------------------------------------------------- */

static void llErrUnsupportedOp(IrInstr *ins, IrFunction *fn, const char *what) {
    fprintf(stderr,
        "%s: function %s: opcode %s is not supported by the LLVM backend\n"
        "  IR dst id: %u, line %d\n",
        LLVM_BACKEND_UNSUPPORTED_IR,
        fn->name->data,
        what ? what : "(null)",
        irDstVarId(ins),
        ins->line);
}

static void llErrUnsupportedType(IrValue *v, IrFunction *fn, const char *what) {
    fprintf(stderr,
        "%s: function %s: type %s is not supported by the LLVM backend\n"
        "  IR value id: %u, kind %s\n",
        LLVM_BACKEND_UNSUPPORTED_TYPE,
        fn->name->data,
        what ? what : "?",
        irVarId(v),
        irValueKindToString(v->kind));
}

/* --- ctx --------------------------------------------------------------- */

typedef struct LLCtx {
    LLVMContextRef ctx;
    LLVMModuleRef  mod;
    LLVMBuilderRef bld;

    /* per-function state */
    IrFunction    *fn;
    LLVMValueRef   cur_fn_value;
    LLValMap       values;       /* IrValue var.id -> LLVMValueRef */
    LLBlockMap     blocks;       /* IrBlock  id    -> LLVMBasicBlockRef */

    /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01:
     * the bounded spike is SSA-only. Multiple reaching stores to the
     * same IR_VAL_LOCAL need a phi (or rejection). The spike chooses
     * rejection. Track which local ids have already been bound by an
     * IR_STORE in the current function; reject a second bind.
     *
     * Initial param bindings (set in llBindParams) and constant
     * bindings (set lazily in llLowerValue) are NOT recorded here:
     * those go in via the `values` map at first observation, never
     * via IR_STORE. */
    u8            *local_defs;
    u32            local_defs_cap;

    /* collapse state */
    int            collapsed;
    IrValue       *collapse_slot; /* the IR_VAL_LOCAL slot of the exit block */
} LLCtx;

/* --- per-block helpers ------------------------------------------------- */

static int irInstrListLen(List *l) {
    int n = 0;
    List *node = l->next;
    while (node != l) { n++; node = node->next; }
    return n;
}

static IrInstr *irInstrListAtFromHead(List *l, int idx) {
    int i = 0;
    List *node = l->next;
    while (node != l) {
        if (i == idx) return (IrInstr *)node->value;
        i++;
        node = node->next;
    }
    return NULL;
}

static IrInstr *irInstrListLast(List *l) {
    List *t = listTail(l);
    if (!t) return NULL;
    return (IrInstr *)t->value;
}

/* Detect the PolyC `return X` lowering shape (ACT §30).
 *
 *   exit_block:
 *     load   %v, %slot
 *     ret    %v
 *
 *   each non-exit predecessor of exit_block:
 *     <possibly: ..., alloca of slot at top>
 *     <possibly: ..., store slot, X>
 *     jmp    exit_block
 *
 * Returns 1 if collapse-eligible and fills *out_slot with the IR
 * value of the slot. Returns 0 otherwise.
 *
 * Conservative: only collapse when:
 *   - exit_block contains exactly 2 instructions (load + ret)
 *   - ret.dst is the load's dst (I64)
 *   - every predecessor ends with `jmp exit_block`
 *   - the slot's only mentions across predecessors are the alloca
 *     (at the top of the entry block) and a single store immediately
 *     before the jmp
 */
static int llDetectCollapsibleReturn(IrFunction *fn, IrValue **out_slot) {
    if (!fn->exit_block) return 0;
    IrBlock *eb = fn->exit_block;

    /* The PolyC neutral optimisation pass (`irBasicFunctionOptimisations`,
     * specifically `irRemoveRedundantBlocks`) can fold the exit_block
     * into its predecessor. The folded block is left with
     * `instructions == NULL`. When that happens, the predecessor already
     * terminates with `ret`, so the collapse is already complete; we
     * just need the backend to lower the predecessor normally and skip
     * emitting the (now-stale) exit_block. */
    if (!eb->instructions) {
        *out_slot = NULL;
        return 1;
    }

    int n = listCount(eb->instructions);
    if (n != 2) return 0;

    IrInstr *ld  = irInstrListAtFromHead(eb->instructions, 0);
    IrInstr *ret = irInstrListAtFromHead(eb->instructions, 1);
    if (!ld || !ret) return 0;
    if (ld->op != IR_LOAD) return 0;
    if (ret->op != IR_RET) return 0;
    if (!ret->dst) return 0;
    if (ret->dst != ld->dst) return 0;
    if (ld->dst->type != IR_TYPE_I64) return 0;

    IrValue *slot = ld->r1;
    if (!slot) return 0;

    Map *preds = irBlockGetPredecessors(fn, eb);
    if (!preds) return 0;
    u32 pn = (u32)preds->size;
    if (pn == 0) return 0;

    MapIter *it = mapIterNew(preds);
    int ok = 1;
    while (ok && mapIterNext(it)) {
        IrBlock *pb = (IrBlock *)it->node->value;
        if (pb == eb) continue;
        IrInstr *jmp = irInstrListLast(pb->instructions);
        if (!jmp || jmp->op != IR_JMP) { ok = 0; break; }
        IrBlock *jt = jmp->extra.blocks.target_block;
        if (jt != eb) { ok = 0; break; }
        /* walk instructions: at most one store to slot, immediately
         * before jmp; at most one alloca of slot, at the top of the
         * entry block; no other instruction touches the slot. */
        int seen_store = 0;
        List *node = pb->instructions->next;
        while (node != pb->instructions) {
            IrInstr *ins = (IrInstr *)node->value;
            if (ins == jmp) break;
            if (ins->op == IR_STORE && ins->dst == slot) {
                if (seen_store) { ok = 0; break; }
                seen_store = 1;
                if (!ins->r1 || ins->r1->type != IR_TYPE_I64) {
                    ok = 0; break;
                }
                /* store must be immediately before jmp */
                List *next_node = node->next;
                if (next_node == pb->instructions) { ok = 0; break; }
                if ((IrInstr *)next_node->value != jmp) { ok = 0; break; }
            } else if (ins->op == IR_ALLOCA) {
                if (ins->dst != slot) { ok = 0; break; }
                /* alloca must be at the very top of the block */
                if (pb->instructions->next != node) { ok = 0; break; }
            } else {
                if (ins->dst == slot || ins->r1 == slot || ins->r2 == slot) {
                    ok = 0; break;
                }
            }
            node = node->next;
        }
        if (!ok) break;
        if (!seen_store) { ok = 0; break; }
    }
    mapIterRelease(it);

    if (!ok) return 0;
    *out_slot = slot;
    return 1;
}

/* Find, for the collapse predecessor block `pb`, the value stored
 * to `slot` (the IR value V in `store slot, V`). */
static IrValue *llCollapseStoreValue(IrBlock *pb, IrValue *slot) {
    IrInstr *jmp = irInstrListLast(pb->instructions);
    if (!jmp || jmp->op != IR_JMP) return NULL;
    List *node = pb->instructions->next;
    while (node != pb->instructions) {
        IrInstr *ins = (IrInstr *)node->value;
        if (ins == jmp) break;
        if (ins->op == IR_STORE && ins->dst == slot) {
            return ins->r1;
        }
        node = node->next;
    }
    return NULL;
}

/* --- per-function lowering --------------------------------------------- */

static LLVMValueRef llLowerValue(LLCtx *lc, IrValue *v);
static LLVMBasicBlockRef llLowerBlock(LLCtx *lc, IrBlock *b);
static LLVMValueRef llLowerInstr(LLCtx *lc, IrInstr *ins);
static LLVMTypeRef llType(LLCtx *lc, IrValueType t);

static int llTypeSupported(IrValueType t) {
    return t == IR_TYPE_I64;
}

static LLVMTypeRef llType(LLCtx *lc, IrValueType t) {
    (void)lc;
    if (t == IR_TYPE_I64) return LLVMInt64TypeInContext(lc->ctx);
    /* IR_TYPE_I1 is intentionally not in `IrValueType`; the spike
     * only emits i64 for source values. The cond->i1 truncation for
     * IR_BR uses LLVMInt1TypeInContext directly. */
    return NULL;
}

static void llPass1(LLCtx *lc, IrProgram *prog) {
    LLVMTypeRef i64 = llType(lc, IR_TYPE_I64);
    for (u64 i = 0; i < prog->functions->size; ++i) {
        IrFunction *fn = vecGet(IrFunction*, prog->functions, i);
        if (!fn) continue;
        for (u64 p = 0; p < fn->params->size; ++p) {
            IrValue *pv = vecGet(IrValue*, fn->params, p);
            if (!pv || !llTypeSupported(pv->type)) {
                llErrUnsupportedType(pv, fn, "function parameter");
                exit(1);
            }
        }
        if (!fn->return_value || !llTypeSupported(fn->return_value->type)) {
            llErrUnsupportedType(fn->return_value, fn,
                "function return value (only I64 supported)");
            exit(1);
        }
        LLVMTypeRef param_tys[64];
        u32 np = (u32)fn->params->size;
        if (np > 64) {
            fprintf(stderr, "%s: too many parameters in %s (%u)\n",
                LLVM_BACKEND_INTERNAL, fn->name->data, np);
            exit(1);
        }
        for (u32 p = 0; p < np; ++p) {
            param_tys[p] = i64;
        }
        LLVMTypeRef fty = LLVMFunctionType(i64, param_tys, (unsigned)np, 0);
        LLVMAddFunction(lc->mod, fn->name->data, fty);
    }
}

/* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
 * scalar SSA lowering.
 *
 * The predecessor spike pre-allocated an LLVM alloca for every
 * IR_VAL_LOCAL at function entry and emitted LLVMBuildStore /
 * LLVMBuildLoad2 to materialise it. That made the spike a tiny
 * memory-machine: every scalar local became a stack slot, and
 * the resulting .ll carried `alloca` / `store` / `load`
 * instructions for every PARAM_COPY pattern.
 *
 * The bounded I64 spike is authorised to be SSA-only. The
 * smallest correct change is:
 *
 *   - No `llPreallocateLocals`. The entry block carries no
 *     allocas at all.
 *   - Each IR_VAL_LOCAL is resolved to an SSA LLVMValueRef
 *     via lc->values.
 *   - IR_STORE local, value  binds `local` to the SSA value
 *     produced by `value`. No LLVMBuildStore is emitted.
 *   - IR_LOAD local          looks up the binding; emits no
 *     LLVMBuildLoad2. The binding is the SSA value.
 *   - IR_ALLOCA local, size  is accepted ONLY when the
 *     recognised return-slot collapse pattern needs it. Any
 *     other alloca is a structural defect for this spike.
 *   - If a local's address is taken, or if multiple reaching
 *     definitions exist, the backend fails with an explicit
 *     LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL diagnostic (or
 *     LLVM_BACKEND_INTERNAL_UNBOUND_VALUE if a read preceeds
 *     its bind). No silent alloca fallback.
 *
 * The bound SSA value must already be a scalar i64. For the
 * supported subset (PARAM_COPY, single-def locals, call result
 * forwarding, arithmetic/comparison temporaries) this holds.
 */

static void llBindParams(LLCtx *lc, IrFunction *fn) {
    for (u64 p = 0; p < fn->params->size; ++p) {
        IrValue *pv = vecGet(IrValue*, fn->params, p);
        LLVMValueRef lv = LLVMGetParam(lc->cur_fn_value, (unsigned)p);
        llvmSet(&lc->values, irVarId(pv), lv);
    }
}

static void llCreateBlocks(LLCtx *lc, IrFunction *fn) {
    listForEach(fn->blocks) {
        IrBlock *b = (IrBlock *)it->value;
        char name[64];
        snprintf(name, sizeof(name), "bb%u", b->id);
        LLVMBasicBlockRef bb = LLVMAppendBasicBlockInContext(
            lc->ctx, lc->cur_fn_value, name);
        llbmSet(&lc->blocks, b->id, bb);
    }
    /* The exit_block may have been folded away by
     * `irRemoveRedundantBlocks` and is no longer in `fn->blocks`,
     * but `fn->exit_block` still references it. When `lc.collapsed`
     * is set with `slot == NULL`, we have already absorbed the
     * folded-away exit block into the predecessor's `ret`, so we
     * don't need an LLVM block for it. */
    if (lc->collapsed && lc->collapse_slot == NULL &&
        fn->exit_block && fn->exit_block->instructions == NULL)
    {
        LLVMBasicBlockRef dead = LLVMAppendBasicBlockInContext(
            lc->ctx, lc->cur_fn_value, "dead_exit");
        llbmSet(&lc->blocks, fn->exit_block->id, dead);
        /* Position the builder so `llLowerBlock`'s `unreachable`
         * terminator is emitted into the dead block. */
        LLVMPositionBuilderAtEnd(lc->bld, dead);
        LLVMBuildUnreachable(lc->bld);
    }
}

static LLVMValueRef llLowerValue(LLCtx *lc, IrValue *v) {
    if (!v) return NULL;
    LLVMValueRef cached = llvmGet(&lc->values, irVarId(v));
    if (cached) return cached;
    if (v->kind == IR_VAL_CONST_INT) {
        if (!llTypeSupported(v->type)) {
            llErrUnsupportedType(v, lc->fn, "constant");
            exit(1);
        }
        LLVMValueRef c = LLVMConstInt(llType(lc, v->type),
                                      (unsigned long long)v->as._i64,
                                      1 /*signed*/);
        llvmSet(&lc->values, irVarId(v), c);
        return c;
    }
    if (v->kind == IR_VAL_LOCAL) {
        /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
         * a LOCAL is resolved through its scalar SSA binding
         * (recorded by a prior IR_STORE). The predecessor spike
         * pre-allocated an alloca for every local; we don't.
         * If we reach here without a binding, the local was
         * read before it was assigned (or its bind never
         * happened). That is a bounded-spike defect: fail loud. */
        fprintf(stderr,
            "%s: function %s: IR_VAL_LOCAL id=%u read with no "
            "SSA binding (use-before-def, or assigned in a "
            "shape this spike does not support)\n",
            LLVM_BACKEND_INTERNAL_UNBOUND_VALUE,
            lc->fn->name->data, irVarId(v));
        exit(1);
    }
    if (v->kind == IR_VAL_CONST_STR || v->kind == IR_VAL_CONST_FLOAT ||
        v->kind == IR_VAL_GLOBAL    || v->kind == IR_VAL_PHI ||
        v->kind == IR_VAL_LABEL    || v->kind == IR_VAL_UNDEFINED ||
        v->kind == IR_VAL_UNRESOLVED) {
        llErrUnsupportedType(v, lc->fn, "value kind");
        exit(1);
    }
    fprintf(stderr, "%s: value %s (id=%u) used before definition\n",
        LLVM_BACKEND_INTERNAL,
        irValueKindToString(v->kind), irVarId(v));
    exit(1);
}

/* Like llLowerValue, but specialised for IR_VAL_LOCAL: the
 * binding is already a scalar i64, so no load is needed. The
 * caller is expected to have already established the binding
 * (otherwise llLowerValue would have errored with
 * LLVM_BACKEND_INTERNAL_UNBOUND_VALUE). */
static LLVMValueRef llLowerI64Value(LLCtx *lc, IrValue *v) {
    LLVMValueRef lv = llLowerValue(lc, v);
    if (!lv) return NULL;
    /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
     * the predecessor spike called LLVMBuildLoad2 here because
     * the cache held a stack-slot pointer. Under SSA lowering,
     * the cache holds the i64 value directly. */
    return lv;
}

static LLVMIntPredicate llCmpKindToLLVMPred(IrCmpKind k) {
    switch (k) {
        case IR_CMP_EQ: return LLVMIntEQ;
        case IR_CMP_NE: return LLVMIntNE;
        case IR_CMP_LT: return LLVMIntSLT;
        case IR_CMP_LE: return LLVMIntSLE;
        case IR_CMP_GT: return LLVMIntSGT;
        case IR_CMP_GE: return LLVMIntSGE;
        default:
            fprintf(stderr,
                "%s: only signed comparison supported; got cmp kind %d\n",
                LLVM_BACKEND_UNSUPPORTED_IR, (int)k);
            exit(1);
    }
}

static int llIsCollapseAlloca(IrInstr *ins, IrValue *slot) {
    return ins->op == IR_ALLOCA && ins->dst == slot;
}

static int llIsCollapseStore(IrInstr *ins, IrValue *slot) {
    return ins->op == IR_STORE && ins->dst == slot;
}

static LLVMBasicBlockRef llLowerBlock(LLCtx *lc, IrBlock *b) {
    LLVMBasicBlockRef bb = llbmGet(&lc->blocks, b->id);
    if (!bb) {
        fprintf(stderr, "%s: block bb%u has no LLVM block\n",
            LLVM_BACKEND_INTERNAL, b->id);
        exit(1);
    }
    LLVMPositionBuilderAtEnd(lc->bld, bb);

    if (lc->collapsed && b == lc->fn->exit_block) {
        /* Unreachable after collapse; defensive. */
        LLVMBuildUnreachable(lc->bld);
        return bb;
    }

    List *node = b->instructions->next;
    while (node != b->instructions) {
        IrInstr *ins = (IrInstr *)node->value;
        List *next = node->next;

        if (lc->collapsed) {
            if (llIsCollapseAlloca(ins, lc->collapse_slot) ||
                llIsCollapseStore(ins, lc->collapse_slot)) {
                /* dead on the collapse path */
                node = next;
                continue;
            }
        }

        if (ins->op == IR_JMP) {
            IrBlock *t = ins->extra.blocks.target_block;
            if (lc->collapsed && t == lc->fn->exit_block) {
                /* This predecessor's jmp -> exit is the collapse
                 * boundary. Replace with `ret <stored value>`. */
                IrValue *v = llCollapseStoreValue(b, lc->collapse_slot);
                if (!v) {
                    fprintf(stderr,
                        "%s: collapse predecessor bb%u missing store\n",
                        LLVM_BACKEND_INTERNAL, b->id);
                    exit(1);
                }
                LLVMValueRef lv = llLowerI64Value(lc, v);
                LLVMBuildRet(lc->bld, lv);
                node = next;
                continue;
            }
            LLVMBasicBlockRef dst = llbmGet(&lc->blocks, t->id);
            if (!dst) {
                fprintf(stderr,
                    "%s: jmp target bb%u has no LLVM block\n",
                    LLVM_BACKEND_INTERNAL, t->id);
                exit(1);
            }
            LLVMBuildBr(lc->bld, dst);
            node = next;
            continue;
        }
        if (ins->op == IR_BR) {
            /* IR_BR carries its condition via `dst` (per ir-eval.c). */
            if (!ins->dst || ins->dst->type != IR_TYPE_I64) {
                fprintf(stderr,
                    "%s: IR_BR condition must be i64 (got kind=%d type=%d)\n",
                    LLVM_BACKEND_UNSUPPORTED_IR,
                    ins->dst ? ins->dst->kind : -1,
                    ins->dst ? ins->dst->type : -1);
                exit(1);
            }
            LLVMValueRef cond64 = llLowerI64Value(lc, ins->dst);
            LLVMValueRef cond1 = LLVMBuildTrunc(lc->bld, cond64,
                                               LLVMInt1TypeInContext(lc->ctx), "");
            IrBlock *tt = ins->extra.blocks.target_block;
            IrBlock *ff = ins->extra.blocks.fallthrough_block;
            LLVMBasicBlockRef t = llbmGet(&lc->blocks, tt->id);
            LLVMBasicBlockRef f = llbmGet(&lc->blocks, ff->id);
            if (!t || !f) {
                fprintf(stderr,
                    "%s: IR_BR branch targets missing\n",
                    LLVM_BACKEND_INTERNAL);
                exit(1);
            }
            LLVMBuildCondBr(lc->bld, cond1, t, f);
            node = next;
            continue;
        }
        if (ins->op == IR_CMP_BR) {
            /* ACT-POLYC-IR-BOUNDARY03 (commit 2):
             *   IR_CMP_BR is a NATIVE-ONLY fusion (src/ir-types.h:140-150;
             *   src/ir-optimise.c:1079-1122 creates it via
             *   irOptPinResultReg). The LLVM dispatch never invokes
             *   irFunctionPrepForCodeGen, so IR_CMP_BR should never
             *   reach this consumer. If it does, the neutral/native
             *   boundary has been crossed above this point and the
             *   emission must fail LOUDLY rather than silently re-
             *   translate the fused form.
             *
             * Pre-BOUNDARY03 this arm silently re-emitted icmp +
             * condbr (the predecessor RED-1B proved this worked
             * for the supported subset). That arm is now dead and
             * is replaced by an explicit boundary-violation
             * diagnostic. The neutral IR shape IR_ICMP + IR_BR
             * continues to be handled by the IR_BR arm above. */
            fprintf(stderr,
                "%s: function %s: IR_CMP_BR reached LLVM backend; "
                "this opcode is below the neutral boundary "
                "(src/ir-types.h:140-150) and must not be presented "
                "to a backend-neutral consumer. The neutral IR "
                "should contain IR_ICMP + IR_BR instead. This is a "
                "boundary violation; refusing to emit.\n",
                LLVM_BACKEND_INTERNAL, lc->fn->name->data);
            return NULL;
        }
        if (ins->op == IR_RET) {
            if (lc->collapsed && b == lc->fn->exit_block) {
                LLVMBuildUnreachable(lc->bld);
                node = next;
                continue;
            }
            /* Direct IR_RET (no slot/store): the neutral opt pass
             * (irForwardReturnSlot + irRemoveRedundantBlocks) can
             * collapse the entire return-via-slot pattern into a
             * single `ret <value>` directly in the predecessor. This
             * is the §30 ideal "direct-branch return" shape. */
            LLVMValueRef v = NULL;
            if (ins->dst) {
                if (ins->dst->type != IR_TYPE_I64) {
                    llErrUnsupportedType(ins->dst, lc->fn, "ret value");
                    exit(1);
                }
                v = llLowerI64Value(lc, ins->dst);
            }
            LLVMBuildRet(lc->bld, v);
            node = next;
            continue;
        }
        if (ins->op == IR_STORE) {
            /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
             * scalar SSA binding.
             *
             *   IR_STORE local, value  bind local -> SSA(value)
             *
             * No LLVMBuildAlloca, no LLVMBuildStore is emitted.
             *
             * The bounded I64 spike supports exactly three shapes
             * of IR_STORE:
             *
             *   1. local  := IR_VAL_LOCAL, value := any i64 SSA.
             *      Bind local to value's SSA form. PARAM_COPY.
             *
             *   2. slot   := recognised return-slot (lc->collapse_slot)
             *      from the collapse-elimination predecessor.
             *      Skipped here; the IR_JMP arm above already
             *      emitted `ret <stored value>` instead.
             *
             *   3. any other shape => bounded-spike defect.
             *      Fail loud with LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL.
             */
            if (!ins->dst) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE missing dst\n",
                    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL, lc->fn->name->data);
                exit(1);
            }
            /* Case 2: return-slot store consumed by collapse. */
            if (lc->collapsed && ins->dst == lc->collapse_slot) {
                /* dead; the predecessor already emitted `ret <v>`. */
                node = next;
                continue;
            }
            /* Case 1: PARAM_COPY / local bind. */
            if (ins->dst->kind != IR_VAL_LOCAL) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE into non-local dst "
                    "(kind=%s, type=%d) at line %d\n",
                    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL,
                    lc->fn->name->data,
                    irValueKindToString(ins->dst->kind),
                    (int)ins->dst->type,
                    ins->line);
                exit(1);
            }
            if (ins->dst->type != IR_TYPE_I64) {
                llErrUnsupportedType(ins->dst, lc->fn,
                    "IR_STORE local type (only I64 supported)");
                exit(1);
            }
            if (!ins->r1) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE local, value has no "
                    "value operand at line %d\n",
                    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL,
                    lc->fn->name->data, ins->line);
                exit(1);
            }
            LLVMValueRef v = llLowerI64Value(lc, ins->r1);

            /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01:
             * reject a second reaching store to the same local id.
             * The bounded I64 spike is SSA-only without phi nodes;
             * multiple stores would require a phi to faithfully
             * represent the merge at a join block. Per the ACT, the
             * spike refuses the merge rather than silently picking
             * whichever store happened to be visited last.
             *
             * Initial param bindings (llBindParams) and lazy constant
             * bindings (llLowerValue) do NOT pass through IR_STORE,
             * so they do not poison the bitmap.
             *
             * The check happens BEFORE llvmSet, so the cache is not
             * corrupted on the failure path. */
            {
                u32 lid = irDstVarId(ins);
                if (lid + 1 > lc->local_defs_cap) {
                    u32 old_cap = lc->local_defs_cap;
                    u32 new_cap = old_cap ? old_cap : 16;
                    while (new_cap < lid + 1) new_cap *= 2;
                    lc->local_defs = (u8 *)realloc(lc->local_defs,
                        new_cap * sizeof(u8));
                    memset(lc->local_defs + old_cap, 0,
                        (new_cap - old_cap) * sizeof(u8));
                    lc->local_defs_cap = new_cap;
                }
                if (lc->local_defs[lid]) {
                    fprintf(stderr,
                        "%s: function %s: local id=%u has multiple "
                        "reaching stores (this spike is SSA-only and "
                        "does not insert phi nodes); line %d\n",
                        LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL,
                        lc->fn->name->data, lid, ins->line);
                    exit(1);
                }
                lc->local_defs[lid] = 1;
            }
            /* Record the scalar SSA binding for this local. */
            llvmSet(&lc->values, irDstVarId(ins), v);
            node = next;
            continue;
        }
        if (ins->op == IR_LOAD) {
            /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
             * scalar SSA resolution. There is no load; the result
             * is the cached SSA binding.
             *
             *   IR_LOAD local  -> the SSA value bound to `local`
             *
             * But under SSA lowering, IR_LOAD is unusual: an SSA
             * consumer just reads the bound value directly. The
             * neutral IR emits IR_LOAD only when the value flows
             * through a phi-like slot (return slot, or future
             * address-taken local). For the bounded I64 spike,
             * the only legal IR_LOAD is the return-slot load in
             * the exit block (which is collapsed). Any other
             * IR_LOAD is a bounded-spike defect.
             */
            if (!ins->dst) {
                fprintf(stderr,
                    "%s: function %s: IR_LOAD missing dst\n",
                    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL, lc->fn->name->data);
                exit(1);
            }
            if (lc->collapsed && ins->dst->kind == IR_VAL_TMP) {
                /* return-slot load in collapsed exit block;
                 * the result is unused (the predecessor already
                 * emitted `ret`). Skip. */
                node = next;
                continue;
            }
            fprintf(stderr,
                "%s: function %s: IR_LOAD on local not collapsed; "
                "this spike requires SSA-only locals "
                "(line %d, dst kind=%s)\n",
                LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL,
                lc->fn->name->data,
                ins->line,
                irValueKindToString(ins->dst->kind));
            exit(1);
        }
        if (ins->op == IR_ALLOCA) {
            /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
             * the only legal IR_ALLOCA in this spike is the
             * return-slot alloc in the entry block, consumed by
             * collapse-elimination. Any other alloca is a
             * bounded-spike defect. */
            if (lc->collapsed && ins->dst == lc->collapse_slot) {
                /* dead; collapse eliminates it. */
                node = next;
                continue;
            }
            fprintf(stderr,
                "%s: function %s: unexpected IR_ALLOCA "
                "(this spike is SSA-only and does not allocate "
                "stack slots). line %d, dst id=%u, kind=%s\n",
                LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL,
                lc->fn->name->data,
                ins->line,
                irVarId(ins->dst),
                ins->dst ? irValueKindToString(ins->dst->kind) : "(null)");
            exit(1);
        }

        LLVMValueRef v = llLowerInstr(lc, ins);
        if (ins->dst && v) llvmSet(&lc->values, irDstVarId(ins), v);

        node = next;
    }

    return bb;
}

static LLVMValueRef llLowerInstr(LLCtx *lc, IrInstr *ins) {
    switch (ins->op) {
        case IR_IADD:
        case IR_ISUB:
        case IR_IMUL: {
            if (!llTypeSupported(ins->dst->type)) {
                llErrUnsupportedType(ins->dst, lc->fn, "i64-arith dst");
                exit(1);
            }
            LLVMValueRef a = llLowerI64Value(lc, ins->r1);
            LLVMValueRef b = llLowerI64Value(lc, ins->r2);
            if (ins->op == IR_IADD) return LLVMBuildAdd(lc->bld, a, b, "");
            if (ins->op == IR_ISUB) return LLVMBuildSub(lc->bld, a, b, "");
            return LLVMBuildMul(lc->bld, a, b, "");
        }
        case IR_ICMP: {
            if (!llTypeSupported(ins->dst->type)) {
                llErrUnsupportedType(ins->dst, lc->fn, "icmp dst");
                exit(1);
            }
            LLVMValueRef a = llLowerI64Value(lc, ins->r1);
            LLVMValueRef b = llLowerI64Value(lc, ins->r2);
            LLVMIntPredicate p = llCmpKindToLLVMPred(ins->extra.cmp_kind);
            return LLVMBuildICmp(lc->bld, p, a, b, "");
        }
        case IR_CALL: {
            if (!llTypeSupported(ins->dst->type)) {
                llErrUnsupportedType(ins->dst, lc->fn, "call dst");
                exit(1);
            }
            /* The callee name is in r1->as.array.label (ir.c). */
            if (!ins->r1) {
                fprintf(stderr,
                    "%s: function %s: IR_CALL missing callee\n",
                    LLVM_BACKEND_UNSUPPORTED_IR, lc->fn->name->data);
                exit(1);
            }
            AoStr *lbl = ins->r1->as.array.label;
            if (!lbl) {
                fprintf(stderr,
                    "%s: function %s: IR_CALL callee missing label\n",
                    LLVM_BACKEND_UNSUPPORTED_IR, lc->fn->name->data);
                exit(1);
            }
            const char *cname = lbl->data;
            LLVMValueRef callee = LLVMGetNamedFunction(lc->mod, cname);
            if (!callee) {
                fprintf(stderr,
                    "%s: function %s: call to unknown function '%s'\n",
                    LLVM_BACKEND_UNSUPPORTED_IR, lc->fn->name->data, cname);
                exit(1);
            }
            LLVMTypeRef fty = LLVMGlobalGetValueType(callee);
            unsigned nparams = LLVMCountParamTypes(fty);
            IrValueArray *arr = &ins->r1->as.array;
            unsigned nargs = (unsigned)arr->values->size;
            if (nargs != nparams) {
                fprintf(stderr,
                    "%s: function %s: call '%s' has %u args, expected %u\n",
                    LLVM_BACKEND_UNSUPPORTED_IR, lc->fn->name->data, cname,
                    nargs, nparams);
                exit(1);
            }
            LLVMValueRef *args = (LLVMValueRef *)calloc(
                nparams ? nparams : 1, sizeof(LLVMValueRef));
            for (unsigned i = 0; i < nparams; ++i) {
                IrValue *av = vecGet(IrValue*, arr->values, i);
                args[i] = llLowerI64Value(lc, av);
            }
            LLVMValueRef call = LLVMBuildCall2(lc->bld, fty, callee,
                                               args, nparams, "");
            free(args);
            return call;
        }
        default: {
            llErrUnsupportedOp(ins, lc->fn, irOpcodeToString(ins));
            exit(1);
        }
    }
}

static int llFunction(IrProgram *prog, IrFunction *fn, LLVMContextRef ctx,
                      LLVMModuleRef mod)
{
    (void)prog;
    LLCtx lc;
    memset(&lc, 0, sizeof(lc));
    lc.ctx = ctx;
    lc.mod = mod;
    lc.fn  = fn;
    lc.bld = LLVMCreateBuilderInContext(ctx);
    llvmInit(&lc.values, 1024);
    llbmInit(&lc.blocks, 1024);
    /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01:
     * local_defs is a flat u8 bitmap keyed by ir.id; u8 is enough for
     * the presence bit. Allocated lazily on first IR_STORE. */
    lc.local_defs = NULL;
    lc.local_defs_cap = 0;

    lc.cur_fn_value = LLVMGetNamedFunction(mod, fn->name->data);
    if (!lc.cur_fn_value) {
        fprintf(stderr, "%s: function %s not in module\n",
            LLVM_BACKEND_INTERNAL, fn->name->data);
        return 1;
    }

    IrValue *slot = NULL;
    lc.collapsed = llDetectCollapsibleReturn(fn, &slot);
    lc.collapse_slot = slot;

    llBindParams(&lc, fn);
    llCreateBlocks(&lc, fn);
    /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
     * no llPreallocateLocals — the entry block carries no allocas.
     * SSA bindings are recorded into lc.values as IR_STORE / IR_RET
     * (etc.) lower. */

    if (!lc.collapsed && fn->exit_block) {
        fprintf(stderr,
            "%s: function %s: return shape not collapsible "
            "(every I64 function must end in collapse-eligible shape)\n",
            LLVM_BACKEND_UNSUPPORTED_IR, fn->name->data);
        return 1;
    }

    List *node = fn->blocks->next;
    int bidx = 0;
    while (node != fn->blocks) {
        IrBlock *b = (IrBlock *)node->value;
        List *next = node->next;
        llLowerBlock(&lc, b);
        bidx++;
        node = next;
    }

    LLVMDisposeBuilder(lc.bld);
    free(lc.values.values);
    free(lc.blocks.values);
    free(lc.local_defs);
    return 0;
}

int llvmEmitProgram(IrProgram *prog,
                    Cctrl *cc,
                    FILE *out_fp,
                    const char *out_path)
{
    (void)cc;
    if ((out_fp == NULL) == (out_path == NULL)) {
        fprintf(stderr, "%s: exactly one of out_fp/out_path must be set\n",
            LLVM_BACKEND_INTERNAL);
        return 1;
    }

    LLVMContextRef ctx = LLVMContextCreate();
    if (!ctx) {
        fprintf(stderr, "%s: LLVMContextCreate returned NULL\n",
            LLVM_BACKEND_INTERNAL);
        return 1;
    }
    LLVMModuleRef mod = LLVMModuleCreateWithNameInContext(
        "polyc_module", ctx);
    if (!mod) {
        LLVMContextDispose(ctx);
        fprintf(stderr, "%s: LLVMModuleCreateWithNameInContext returned NULL\n",
            LLVM_BACKEND_INTERNAL);
        return 1;
    }

    LLCtx lc;
    memset(&lc, 0, sizeof(lc));
    lc.ctx = ctx;
    lc.mod = mod;
    llvmInit(&lc.values, 1024);
    llPass1(&lc, prog);
    free(lc.values.values);

    for (u64 i = 0; i < prog->functions->size; ++i) {
        IrFunction *fn = vecGet(IrFunction*, prog->functions, i);
        if (!fn) continue;
        if (llFunction(prog, fn, ctx, mod) != 0) {
            LLVMDisposeModule(mod);
            LLVMContextDispose(ctx);
            return 1;
        }
    }

    char *err = NULL;
    if (LLVMVerifyModule(mod, LLVMReturnStatusAction, &err) != 0) {
        fprintf(stderr, "%s: %s\n",
            LLVM_BACKEND_VERIFY_FAILED, err ? err : "(null error)");
        if (err) LLVMDisposeMessage(err);
        LLVMDisposeModule(mod);
        LLVMContextDispose(ctx);
        return 1;
    }
    if (err) LLVMDisposeMessage(err);

    int rc = 0;
    if (out_path) {
            char *perr = NULL;
        if (LLVMPrintModuleToFile(mod, out_path, &perr) != 0) {
            fprintf(stderr, "%s: LLVMPrintModuleToFile: %s\n",
                LLVM_BACKEND_INTERNAL, perr ? perr : "(null)");
            if (perr) LLVMDisposeMessage(perr);
            rc = 1;
        } else if (perr) {
            fprintf(stderr, "%s: warning: %s\n",
                LLVM_BACKEND_INTERNAL, perr);
            LLVMDisposeMessage(perr);
        }
    } else {
        char *s = LLVMPrintModuleToString(mod);
        if (!s) {
            fprintf(stderr, "%s: LLVMPrintModuleToString returned NULL\n",
                LLVM_BACKEND_INTERNAL);
            rc = 1;
        } else {
            fputs(s, out_fp);
            LLVMDisposeMessage(s);
        }
    }

    LLVMDisposeModule(mod);
    LLVMContextDispose(ctx);
    return rc;
}
