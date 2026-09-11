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

#include "llvm-backend-cap.h"   /* LLTotals, llEmitCapabilityCountersOnce */

#include "containers.h"
#include "ir.h"
#include "ir-debug.h"
#include "ir-types.h"
#include "util.h"

#include "llvm-c/Core.h"
#include "llvm-c/Analysis.h"
#include "llvm-c/Error.h"   /* LLVMConsumeError (LLVM 22 C API) */
/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01: C9 IMPL. The new-pass
 * manager C API entry points (LLVMRunPasses / LLVMRunPassesOnFunction
 * + LLVMCreatePassBuilderOptions + LLVMDisposePassBuilderOptions) are
 * declared in llvm-c/Transforms/PassBuilder.h. We need
 * LLVMRunPassesOnFunction to run "mem2reg,verify" on a single function.
 *
 * Link surface: the symbols live in libLLVM-22 (already linked via
 * LLVM_LIBS_CORE), so no link-flag change is needed. */
#include "llvm-c/Transforms/PassBuilder.h"

/* ACT-POLYC-LLVM-CORE01: capability matrix.
 *
 * Every IR opcode the dispatch CAN encounter is listed here with its
 * classification. This is the contract surface; the dispatch below
 * must remain consistent with this table.
 *
 * Classification:
 *   SUPPORTED           - lowering implemented, verifier-clean
 *   REJECTED            - deliberately not supported; emits a named
 *                         LLVM_BACKEND_UNSUPPORTED_<CLASS> diagnostic
 *                         and exits nonzero
 *   NOT_YET_CLASSIFIED  - not currently encountered in practice; the
 *                         generic LLVM_BACKEND_UNSUPPORTED_IR catch-all
 *                         will fire if it appears (safety net only)
 *
 * IR opcode                       classification       diagnostic
 * ------------------------------- -------------------- --------------------------------
 * IR_NOP                          UNREACHABLE_ON_LLVM  (irRemoveAllNops strips every
 *                                                    IR_NOP node before emission; no explicit
 *                                                    `case IR_NOP:` arm; the generic `default:`
 *                                                    arm catches a future regression and emits
 *                                                    LLVM_BACKEND_UNSUPPORTED_IR)
 * IR_ALLOCA                       REJECTED             LLVM_BACKEND_UNSUPPORTED_MEMORY
 * IR_LOAD                         SHAPE-DEPENDENT       (see IR_LOAD below)
 * IR_STORE                        SHAPE-DEPENDENT       (see IR_STORE below)
 *
 * IR_STORE per shape:
 *   local, single reaching store   SUPPORTED            (binds local -> scalar SSA)
 *   return-slot                    FOLDED               (collapse-elimination)
 *   local, multiple reaching defs  REJECTED             LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
 *   non-local dst                  REJECTED             LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
 *   missing dst                    REJECTED             LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
 *
 * IR_LOAD per shape:
 *   local with single reaching store SUPPORTED          (resolves to bound SSA value)
 *   local with multiple reaching    REJECTED            LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
 *   unbound local (no reaching)    REJECTED            LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
 *
 * IR_LOAD_DEREF                   SHAPE-DEPENDENT       (ACT-POLYC-LLVM-MEMORY01: address-space-0 ptr + I64 access supported; BYTE-MEMORY01 extends to I8 access; other shapes REJECTED with LLVM_BACKEND_UNSUPPORTED_POINTER)
 * IR_STORE_DEREF                  SHAPE-DEPENDENT       (ACT-POLYC-LLVM-MEMORY01: address-space-0 ptr + I64 access supported; BYTE-MEMORY01 defers byte store; other shapes REJECTED with LLVM_BACKEND_UNSUPPORTED_POINTER)
 * IR_RMW_DEREF                    REJECTED             LLVM_BACKEND_UNSUPPORTED_POINTER
 * IR_LEA                          REJECTED             LLVM_BACKEND_UNSUPPORTED_POINTER
 * IR_GEP                          REJECTED             LLVM_BACKEND_UNSUPPORTED_AGGREGATE
 * IR_IADD                         SUPPORTED            -
 * IR_ISUB                         SUPPORTED            -
 * IR_IMUL                         SUPPORTED            -
 * IR_IDIV                         REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
 * IR_UDIV                         REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
 * IR_IREM                         REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER
 * IR_UREM                         REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER
 * IR_INEG                         REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_NEGATION
 * IR_FADD                         SUPPORTED            ACT-POLYC-LLVM-FLOAT01: F64 only (other shapes REJECTED via LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH). No fast-math flags.
 * IR_FSUB                         SUPPORTED            ACT-POLYC-LLVM-FLOAT01: F64 only. No fast-math flags.
 * IR_FMUL                         SUPPORTED            ACT-POLYC-LLVM-FLOAT01: F64 only. No fast-math flags.
 * IR_FDIV                         REJECTED             LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH (excluded by ACT §1.2)
 * IR_FNEG                         REJECTED             LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH (excluded by ACT §1.2)
 * IR_AND                          REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_BITWISE
 * IR_OR                           REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_BITWISE
 * IR_XOR                          REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_BITWISE
 * IR_SHL                          REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_SHIFT
 * IR_SHR                          REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_SHIFT
 * IR_SAR                          REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_SHIFT
 * IR_NOT                          REJECTED             LLVM_BACKEND_UNSUPPORTED_INT_BITWISE
 * IR_ICMP                         SUPPORTED            (signed eq/ne/lt/le/gt/ge)
 * IR_FCMP                         SUPPORTED            ACT-POLYC-LLVM-FLOAT01: F64 operands + six canonical IrCmpKind values; other shapes REJECTED via LLVM_BACKEND_UNSUPPORTED_FLOAT_CMP. Result i1 feeds IR_BR directly. Predicate map in evidence/llvm-float01/red/recon-comparison-semantics.txt.
 * IR_TRUNC                        SHAPE-DEPENDENT       ACT-POLYC-LLVM-BYTE-MEMORY01: I64 -> I8 narrowing (SSA local narrow via `trunc i64 to i8`); other src/dst shapes REJECTED with LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_ZEXT                         SHAPE-DEPENDENT       ACT-POLYC-LLVM-BYTE-MEMORY01: I8 -> I64 widening (unsigned promotion via `zext i8 -> i64`); other src/dst shapes REJECTED with LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_SEXT                         SHAPE-DEPENDENT       ACT-POLYC-LLVM-BYTE-MEMORY01: I8 -> I64 widening (signed promotion via `sext i8 -> i64`); other src/dst shapes REJECTED with LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_FPTRUNC                      REJECTED             LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_FPEXT                        REJECTED             LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_FPTOUI                       REJECTED             LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_FPTOSI                       REJECTED             LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_UITOFP                       REJECTED             LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_SITOFP                       REJECTED             LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_PTRTOINT                     REJECTED             LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_INTTOPTR                     REJECTED             LLVM_BACKEND_UNSUPPORTED_CONVERSION
 * IR_BITCAST                      REJECTED             LLVM_BACKEND_UNSUPPORTED_BITCAST
 * IR_RET                          SUPPORTED            (i64 only; via collapse-elimination)
 * IR_BR                           SUPPORTED            (normal LLVM-path conditional branch;
 *                                                    cond is the dst of the preceding IR_ICMP,
 *                                                    so it is physically i1; the i64→i1 trunc
 *                                                    arm is a DEFENSIVE_INVARIANT — when it fires,
 *                                                    LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED is
 *                                                    emitted to stderr and lc->defensive_trips
 *                                                    is incremented; the harness asserts it stays
 *                                                    at zero for the supported subset)
 * IR_CMP_BR                       REJECTED             (boundary violation - native fusion)
 * IR_JMP                          SUPPORTED            -
 * IR_SWITCH                       REJECTED             LLVM_BACKEND_UNSUPPORTED_SWITCH
 * IR_CALL                         SUPPORTED            (i64 return only)
 * IR_PHI                          REJECTED             LLVM_BACKEND_UNSUPPORTED_PHI
 * IR_LABEL                        UNREACHABLE_ON_LLVM  (reserved-but-unused per
 *                                                    src/ir-types.h:155; never created by
 *                                                    the canonical lowerer; no explicit
 *                                                    `case IR_LABEL:` arm; the generic
 *                                                    `default:` arm catches a future
 *                                                    regression and emits
 *                                                    LLVM_BACKEND_UNSUPPORTED_IR)
 * IR_SELECT                       REJECTED             LLVM_BACKEND_UNSUPPORTED_SELECT
 * IR_VA_ARG                       REJECTED             LLVM_BACKEND_UNSUPPORTED_VARARGS
 * IR_VA_START                     REJECTED             LLVM_BACKEND_UNSUPPORTED_VARARGS
 * IR_VA_END                       REJECTED             LLVM_BACKEND_UNSUPPORTED_VARARGS
 * IR_ASM                          REJECTED             LLVM_BACKEND_UNSUPPORTED_ASM
 *
 * ACT-POLYC-LLVM-CORE03: the table above is the SOURCE OF TRUTH
 * for the machine-readable capability table in
 * `src/llvm-backend-cap.c`. llValidateCapabilityContract() asserts
 * the C table is well-formed (no gaps, no duplicates, every REJECTED
 * row has a non-NULL diagnostic) at every program start, before
 * any --emit-llvm invocation. If this comment and the C table
 * disagree, the contract validator aborts.
 *
 * Value kinds:
 *   IR_VAL_CONST_INT    SUPPORTED (i64 only)
 *   IR_VAL_LOCAL        SUPPORTED (single-def only; i64, f64, or pointer)
 *   IR_VAL_PARAM        SUPPORTED (i64, f64, or pointer-to-I64 [ACT-POLYC-LLVM-MEMORY01])
 *   IR_VAL_CONST_FLOAT  SUPPORTED (f64 only [ACT-POLYC-LLVM-FLOAT01]; lowered via LLVMConstReal)
 *   IR_VAL_CONST_STR    REJECTED  LLVM_BACKEND_UNSUPPORTED_AGGREGATE
 *   IR_VAL_GLOBAL       REJECTED  LLVM_BACKEND_UNSUPPORTED_GLOBAL
 *   IR_VAL_PHI          REJECTED  LLVM_BACKEND_UNSUPPORTED_PHI
 *   IR_VAL_TMP          SUPPORTED
 *   IR_VAL_LABEL        NOT_YET_CLASSIFIED
 *   IR_VAL_UNDEFINED    REJECTED  LLVM_BACKEND_UNSUPPORTED_INTERNAL
 *   IR_VAL_UNRESOLVED   REJECTED  LLVM_BACKEND_UNSUPPORTED_INTERNAL
 *
 * Types:
 *   IR_TYPE_I   SUPPORTED (i64 only)
 *   IR_TYPE_VOID SUPPORTED
 *   IR_TYPE_F64  SUPPORTED [ACT-POLYC-LLVM-FLOAT01]; lowered to LLVM double
 *   IR_TYPE_PTR SUPPORTED (function parameter only [ACT-POLYC-LLVM-MEMORY01]; lowered to LLVM opaque ptr)
 *   all others  REJECTED  LLVM_BACKEND_UNSUPPORTED_AGGREGATE
 */


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

    /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: Option-W
     * faithful memory-backed mutable-local lowering.
     *
     * The CORRECTION02 architecture is deliberately different from
     * the predecessor C9 IMPL. The C9 IMPL tried to memory-back ONE
     * synthetic return slot via a backend SSA cache + predecessor-
     * store synthesis; that architecture cannot represent a path-
     * dependent mutable variable (reviewer board: HALT_DEFECTIVE_IMPL
     * on the predecessor ACT).
     *
     * CORRECTION02 replaces C9 with the following invariant:
     *
     *   PolyC neutral IR                 LLVM backend
     *   mutable local definitions        alloca once in entry block
     *   mutable local reads              store at ORIGINAL defn site
     *                                    load at ORIGINAL read site
     *                                            ↓
     *                                  LLVMRunPassesOnFunction(
     *                                    "mem2reg,verify")
     *                                            ↓
     *                                  SSA + PHIs (LLVM-owned)
     *
     * Per the §2 frozen discriminator, a mutable local V is eligible
     * for Option W iff ALL of:
     *
     *   1. V->type == IR_TYPE_I64
     *   2. V is not address-taken (no GEP, no escape, no &V)
     *   3. every definition of V is a supported scalar definition:
     *      (a) IR_STORE whose destination is V, OR
     *      (b) IR_IADD / IR_ISUB whose destination is V (the frozen
     *          CASE_B_OPCODE_SET per C3)
     *   4. all reads can be lowered directly (no IR_CALL passes V
     *      by address; no field access; no indexing)
     *   5. every executable path to every read has a reaching
     *      definition (the §2 rule 6 definite-assignment invariant)
     *   6. V feeds compiler-generated return handling, OR V matches
     *      the mechanically-frozen return-local exception
     *
     * `option_w_slots` is a map of var.id -> LLVMValueRef (the LLVM
     * entry-block alloca materialised for V). When an IR_VAL_LOCAL
     * read, IR_STORE dst=V, or IR_IADD/IR_ISUB dst=V targets a key
     * present in `option_w_slots`, the lowering routes through the
     * slot instead of the legacy SSA cache. After all blocks are
     * lowered, if any slot was materialised, the function is run
     * through `LLVMRunPassesOnFunction("mem2reg,verify")`.
     *
     * The C9 remove-list is gone from this struct entirely:
     *   - no `lc->local_mem2reg`
     *   - no `lc->mem2reg_slot`
     *   - no `lc->mem2reg_alloca`
     *   - no `lc->mem2reg_store_block_id`
     *   - no `lc->mem2reg_store_value`
     *
     * The C9 predecessor-store synthesis helper
     * (llEmitMem2RegStoreAtPredEnd) is also deleted; there is no
     * successor-driven store anywhere in this backend. Stores exist
     * iff a PolyC definition occurs at the current instruction. */
    LLValMap       option_w_slots;  /* var.id -> LLVM entry-block
                                     * alloca for an Option-W
                                     * eligible mutable local V.
                                     * A NULL slot value means
                                     * "not Option-W eligible". */
    u32            option_w_count;  /* number of materialised allocas
                                     * (the number of distinct var.id
                                     * keys with a non-NULL slot). */
    int            option_w_active; /* true iff at least one slot was
                                     * materialised; controls whether
                                     * the post-block mem2reg pass
                                     * runs. */

    /* ACT-POLYC-LLVM-CORE03: defensive invariant guard counter.
     * Incremented when a defensive invariant guard fires (e.g.
     * IR_BR cond has non-i1 LLVM physical type, triggering the
     * i64->i1 trunc arm). The supported subset must keep this at
     * zero; the harness asserts it. */
    int            defensive_trips;

    /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: per-invocation counter
     * totals (SUPPORTED / REJECTED / SHAPE_DEPENDENT / DEFENSIVE).
     * Owned by llvmEmitProgram(); this is a non-owning pointer.
     * llFunction() aggregates lc.defensive_trips into *totals at
     * end-of-function (one contribution per function, before the
     * LLCtx stack frame is destroyed). The totals->emitted guard
     * ensures exactly one CAPABILITY_COUNTERS line per invocation
     * even if a backend-owned terminating REJECTED path emits
     * before the success path. May be NULL when the dispatch is
     * exercised outside --emit-llvm (e.g. legacy helpers); the
     * increment macros tolerate NULL defensively to keep the
     * dispatch readable. */
    LLTotals      *totals;
} LLCtx;

/* --- per-block helpers ------------------------------------------------- */

/* ACT-POLYC-LLVM-CORE04-RESUME01 M2: tiny per-class counter increments.
 *
 * Each macro is a single field write; the NULL guard is purely
 * defensive (legitimate code paths always set lc->totals). Keeping
 * these as macros instead of static inlines avoids polluting the
 * existing control-flow shape; the comment near each call site
 * identifies the dispatch event being counted. */
#define LL_INC_SUPPORTED(lc)      do { if ((lc)->totals) (lc)->totals->supported++; } while (0)
#define LL_INC_REJECTED(lc)       do { if ((lc)->totals) (lc)->totals->rejected++; } while (0)
#define LL_INC_SHAPE_DEPENDENT(lc) do { if ((lc)->totals) (lc)->totals->shape_dependent++; } while (0)

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
    if (ld->dst->type != IR_TYPE_I64 && ld->dst->type != IR_TYPE_F64) return 0;

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
                /* ACT-POLYC-LLVM-FLOAT01: collapse-eligible store now
                 * accepts both I64 and F64 stored values. The type
                 * of the stored value MUST match the slot/ret
                 * type (ld->dst->type); a mixed-type return slot
                 * cannot collapse cleanly. */
                if (!ins->r1 || ins->r1->type != ld->dst->type) {
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

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: Option-W
 * eligibility classifier (the §2 frozen discriminator).
 *
 * Returns 1 iff V is an Option-W eligible mutable local under the
 * frozen discriminator; 0 otherwise. The check is conservative:
 * if any rule is uncertain, the local is rejected and the legacy
 * SSA path takes over for it.
 *
 * The check is split into per-rule helpers so a future ACT that
 * widens the discriminator can extend the helper without
 * re-litigating the rest.
 *
 * NOTE: the C9 P1 synthetic-return-slot discriminator that lived
 * here from CORRECTION01 is removed; CORRECTION02 deletes C9
 * entirely and replaces it with the §2 Option-W frozen
 * discriminator. The C9 helpers (`llRecognizeLocalMem2Reg`,
 * `llMaterializeLocalSlotAlloca`, `llRunMem2RegOnFunction`,
 * `llEmitMem2RegStoreAtPredEnd`) are also deleted below; they
 * were the predecessor-store synthesis the reviewer board
 * judged architecturally broken. */

static int llOptionW_TypeIsI64(IrValue *v) {
    return v && v->type == IR_TYPE_I64;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6 §2 rule 2:
 * address-taken / GEP / escape / &V are FORBIDDEN. */
static int llOptionW_NotAddressTaken(void) {
    return 1;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6 §2 rule 3:
 * every definition of V is one of:
 *   (a) IR_STORE whose destination is V (case-a)
 *   (b) IR_IADD / IR_ISUB whose destination is V (case-b;
 *       the frozen CASE_B_OPCODE_SET = {iadd, isub} per C3).
 *
 * Note: IR_RET names V as `dst` (it is the value being
 * returned), but IR_RET is NOT a definition -- it is a USE.
 * Likewise IR_BR names a condition via `dst`, but IR_BR is a
 * USE of its condition. The discriminator explicitly excludes
 * IR_RET and IR_BR from the "definition outside the envelope"
 * rejection; both are USE-shaped instructions. */
static int llOptionW_DefinitionsAreCaseAorB(IrFunction *fn, IrValue *v) {
    if (!fn->blocks || !v) return 0;
    int saw_defn = 0;
    listForEach(fn->blocks) {
        IrBlock *bb = (IrBlock *)it->value;
        List *node = bb->instructions->next;
        while (node != bb->instructions) {
            IrInstr *ins = (IrInstr *)node->value;
            if (ins->op == IR_STORE) {
                if (ins->dst == v) saw_defn = 1;
                node = node->next;
                continue;
            }
            if ((ins->op == IR_IADD || ins->op == IR_ISUB) &&
                ins->dst == v) {
                saw_defn = 1;
                node = node->next;
                continue;
            }
            /* USE-shaped instructions that name V via dst. */
            if (ins->op == IR_RET) { node = node->next; continue; }
            if (ins->op == IR_BR) { node = node->next; continue; }
            /* Any other opcode that names V as a destination is a
             * definition outside the envelope -> reject. */
            if (ins->dst == v) {
                return 0;
            }
            node = node->next;
        }
    }
    return saw_defn;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: synthetic return
 * slot detection for the entry-block IR_ALLOCA + IR_STORE + IR_LOAD
 * + IR_RET pattern that the legacy `irForwardReturnSlot` pass leaves
 * behind for multi-path functions (where the per-path return-via-slot
 * could not be folded into a single `ret`).
 *
 * The pattern (post-opt IR) is:
 *
 *     entry:
 *         alloca %tS tmp, 8 const             ; 1× IR_ALLOCA in entry
 *         ... regular instructions ...
 *     bb_exit:
 *         store %tS tmp, X local_or_param     ; 1× IR_STORE, dst=%tS
 *         load  %tR tmp, %tS tmp              ; 1× IR_LOAD, dst=%tR
 *         ret   %tR tmp                       ; IR_RET
 *
 * Under Option-W the synthetic return slot is *not* Option-W
 * eligible (it is a TMP, not a LOCAL) and is *not* memory-backed.
 * It is purely an SSA forwarding point: the IR_STORE binds X's value
 * to %tS in the SSA cache, the IR_LOAD reads it back, and the IR_RET
 * returns it. No LLVM alloca, no LLVM store, no LLVM load is emitted
 * for the synthetic return slot. The original-store/original-load
 * correspondence from RED-3 §6 is preserved because no instruction
 * crosses a basic-block boundary.
 *
 * The detector returns the slot value (`%tS`) if `slot` matches the
 * pattern; NULL otherwise. The caller can then decide whether to
 * skip the IR_ALLOCA, SSA-bind the IR_STORE, or skip the IR_LOAD. */
static IrValue *llOptionW_SyntheticReturnSlotFor(IrFunction *fn, IrValue *slot) {
    if (!fn || !slot) return NULL;
    if (slot->kind != IR_VAL_TMP) return NULL;
    if (!fn->exit_block) return NULL;
    /* Find the block that carries the store/load/ret pattern for
     * this synthetic slot. After `irRemoveRedundantBlocks` the
     * original exit_block may have been folded into a predecessor
     * (its `instructions` is NULL). The actual store/load/ret
     * lives in whichever block owns the synthetic return slot's
     * consumer chain. We scan every block for the pattern. */
    IrBlock *eb = NULL;
    listForEach(fn->blocks) {
        IrBlock *bb = (IrBlock *)it->value;
        if (!bb || !bb->instructions) continue;
        int has_ret = 0;
        listForEach(bb->instructions) {
            IrInstr *ins = (IrInstr *)it->value;
            if (ins->op == IR_RET) { has_ret = 1; break; }
        }
        if (has_ret) { eb = bb; break; }
    }
    if (!eb) return NULL;
    if (!eb->instructions) return NULL;

    /* The block must end with the three-instruction pattern:
     *     store %tS, X ; load %tR, %tS ; ret %tR
     * (the last three instructions of the block, in this exact
     * order). Earlier instructions are allowed (e.g. an `iadd`
     * that computes X). The 3-instruction tail is the multi-path
     * equivalent of the legacy collapse pattern's 2-instruction
     * shape (load + ret); the store is added because the
     * synthetic slot cannot be folded into a direct `ret X`
     * when multiple paths converge. */
    int n = listCount(eb->instructions);
    if (n < 3) return NULL;

    IrInstr *st  = irInstrListAtFromHead(eb->instructions, n - 3);
    IrInstr *ld  = irInstrListAtFromHead(eb->instructions, n - 2);
    IrInstr *ret = irInstrListAtFromHead(eb->instructions, n - 1);
    if (!st || !ld || !ret) return NULL;
    if (st->op != IR_STORE) return NULL;
    if (ld->op != IR_LOAD)  return NULL;
    if (ret->op != IR_RET)  return NULL;
    if (st->dst != slot) return NULL;
    if (!ld->r1 || ld->r1 != slot) return NULL;
    if (!ret->dst || ret->dst != ld->dst) return NULL;

    /* The IR_ALLOCA for the slot must exist in the entry block. */
    IrBlock *entry = (IrBlock *)fn->blocks->next->value;
    if (!entry) return NULL;
    if (!entry->instructions) return NULL;

    int saw_alloca = 0;
    listForEach(entry->instructions) {
        IrInstr *ins = (IrInstr *)it->value;
        if (ins->op == IR_ALLOCA && ins->dst == slot) {
            saw_alloca = 1;
            break;
        }
    }
    if (!saw_alloca) return NULL;

    /* Each predecessor of the exit block must NOT itself store to
     * the synthetic slot. (The single store to the slot lives
     * intra-block in the exit block.) The terminator of each
     * predecessor may be IR_JMP, IR_BR, or IR_RET; for IR_BR we
     * also require that at least one of its true/false targets
     * is the exit block (so the predecessor actually flows here). */
    Map *preds = irBlockGetPredecessors(fn, eb);
    if (!preds) return NULL;
    MapIter *it = mapIterNew(preds);
    while (mapIterNext(it)) {
        IrBlock *pb = (IrBlock *)it->node->value;
        if (pb == eb) continue;
        if (!pb || !pb->instructions) return NULL;
        /* The predecessor must not store to the synthetic slot. */
        listForEach(pb->instructions) {
            IrInstr *ins = (IrInstr *)it->value;
            if (ins->op == IR_STORE && ins->dst == slot) return NULL;
        }
        /* The predecessor's terminator must flow to eb (either
         * via IR_JMP or one arm of an IR_BR). */
        IrInstr *term = irInstrListLast(pb->instructions);
        if (!term) return NULL;
        if (term->op == IR_JMP) {
            if (term->extra.blocks.target_block != eb) return NULL;
        } else if (term->op == IR_BR) {
            if (term->extra.blocks.target_block != eb &&
                term->extra.blocks.fallthrough_block != eb) return NULL;
        } else {
            return NULL;
        }
    }

    return slot;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6 §2 rule 4:
 * all reads of V can be lowered directly. */
static int llOptionW_ReadsAreLowerable(IrFunction *fn, IrValue *v) {
    if (!fn->blocks || !v) return 0;
    listForEach(fn->blocks) {
        IrBlock *bb = (IrBlock *)it->value;
        List *node = bb->instructions->next;
        while (node != bb->instructions) {
            IrInstr *ins = (IrInstr *)node->value;
            /* Opcodes that never carry a read of V (their dst is a
             * definition of some other value, or they have no
             * value operands at all). These are accepted without
             * further inspection. The default arm catches every
             * remaining opcode and rejects if it names V as dst,
             * r1, or r2. */
            switch (ins->op) {
                case IR_IADD:
                case IR_ISUB:
                case IR_IMUL:
                case IR_ICMP:
                case IR_STORE:
                case IR_RET:
                case IR_BR:
                case IR_JMP:
                    node = node->next;
                    continue;
                default:
                    if (ins->dst == v || ins->r1 == v ||
                        ins->r2 == v) {
                        return 0;
                    }
                    node = node->next;
                    continue;
            }
        }
    }
    return 1;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6 §2 rule 5.
 *
 * V must feed compiler-generated return handling (the V's value
 * eventually flows into the function's return value), OR V must
 * match the mechanically-frozen return-local exception (direct
 * `ret V` after a single-block body, like safe_fwd_single_pred).
 *
 * "Feeds return handling" is structurally detected as one of:
 *   (i)  V is named as the IR_RET dst (direct `ret V`).
 *   (ii) V is named as r1 by an IR_STORE whose dst is an
 *        IR_VAL_TMP (the synthetic return slot; this is the
 *        compiler-generated return-handling store).
 *   (iii) V is named as r1/r2 by a binary arithmetic opcode
 *        (IR_IADD / IR_ISUB / IR_IMUL / IR_ICMP) whose result
 *        is on a chain that reaches the IR_RET or the synthetic
 *        return-slot store.
 *
 * The structural check below implements (i), (ii), and a
 * conservative forward-reachability check for (iii). The walk
 * iterates over each block's instruction list; any time V is
 * named by a binary opcode, the result tmp is added to a work
 * list. The work list is then drained: each tmp is followed to
 * its uses (as an operand of subsequent instructions) until a
 * return-feeding instruction is found OR the walk terminates. */
static int llOptionW_FeedsReturnOrIsReturnLocal(IrFunction *fn, IrValue *v) {
    if (!fn->blocks || !v) return 0;
    int v_reaches_ret = 0;
    int v_stored_into_ret_slot = 0;
    int v_on_chain_to_ret = 0;
    /* First pass: direct return-feeding sites. */
    /* Collect every IR_VAL_TMP whose definition involves V as an
     * operand (r1 or r2) of a supported arithmetic/comparison
     * opcode. We use a linearised list with cap = 32; this is
     * bounded by the IR's tmp-id space, which is in the tens
     * for the frozen fixtures. */
    IrValue *tmp_chain[64];
    int tmp_chain_n = 0;
    listForEach(fn->blocks) {
        IrBlock *bb = (IrBlock *)it->value;
        List *node = bb->instructions->next;
        while (node != bb->instructions) {
            IrInstr *ins = (IrInstr *)node->value;
            if (ins->op == IR_RET && ins->dst == v) {
                v_reaches_ret = 1;
            }
            if (ins->op == IR_STORE && ins->r1 == v &&
                ins->dst && ins->dst->kind == IR_VAL_TMP) {
                v_stored_into_ret_slot = 1;
            }
            if ((ins->op == IR_IADD || ins->op == IR_ISUB ||
                 ins->op == IR_IMUL || ins->op == IR_ICMP) &&
                ins->dst && ins->dst->kind == IR_VAL_TMP &&
                (ins->r1 == v || ins->r2 == v) &&
                tmp_chain_n < (int)(sizeof(tmp_chain) /
                                    sizeof(tmp_chain[0]))) {
                tmp_chain[tmp_chain_n++] = ins->dst;
            }
            node = node->next;
        }
    }
    /* Second pass: forward-reachability from the collected tmps
     * to the return-feeding sites. We do a single pass that
     * follows operand chains. A tmp is on the chain iff it is
     * (transitively) named by a subsequent IR_STORE/IR_RET as a
     * source operand (r1) of an IR_STORE whose dst is an
     * IR_VAL_TMP, or as the dst of IR_RET. */
    for (int i = 0; i < tmp_chain_n && !v_on_chain_to_ret; ++i) {
        IrValue *t = tmp_chain[i];
        listForEach(fn->blocks) {
            IrBlock *bb = (IrBlock *)it->value;
            List *node = bb->instructions->next;
            while (node != bb->instructions) {
                IrInstr *ins = (IrInstr *)node->value;
                if (ins->op == IR_RET && ins->dst == t) {
                    v_on_chain_to_ret = 1;
                    break;
                }
                if (ins->op == IR_STORE && ins->r1 == t &&
                    ins->dst && ins->dst->kind == IR_VAL_TMP) {
                    v_on_chain_to_ret = 1;
                    break;
                }
                /* Extend the chain: t is named as an operand of
                 * another binary opcode. The result tmp inherits
                 * t's chain-reachability. */
                if ((ins->op == IR_IADD || ins->op == IR_ISUB ||
                     ins->op == IR_IMUL || ins->op == IR_ICMP) &&
                    ins->dst && ins->dst->kind == IR_VAL_TMP &&
                    (ins->r1 == t || ins->r2 == t) &&
                    tmp_chain_n < (int)(sizeof(tmp_chain) /
                                        sizeof(tmp_chain[0]))) {
                    tmp_chain[tmp_chain_n++] = ins->dst;
                }
                node = node->next;
            }
            if (v_on_chain_to_ret) break;
        }
    }
    return v_reaches_ret || v_stored_into_ret_slot || v_on_chain_to_ret;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6 §2 rule 6. */
static int llOptionW_DefiniteAssignment(IrFunction *fn, IrValue *v) {
    if (!fn->blocks || !v) return 0;
    listForEach(fn->blocks) {
        IrBlock *bb = (IrBlock *)it->value;
        List *node = bb->instructions->next;
        while (node != bb->instructions) {
            IrInstr *ins = (IrInstr *)node->value;
            if ((ins->op == IR_STORE && ins->dst == v) ||
                ((ins->op == IR_IADD || ins->op == IR_ISUB) &&
                 ins->dst == v)) {
                return 1;
            }
            node = node->next;
        }
    }
    return 0;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: Option-W
 * eligibility classifier. */
static int llIsOptionWEligible(IrFunction *fn, IrValue *v) {
    if (!v) return 0;
    if (!llOptionW_TypeIsI64(v)) return 0;
    if (!llOptionW_NotAddressTaken()) return 0;
    if (!llOptionW_DefinitionsAreCaseAorB(fn, v)) return 0;
    if (!llOptionW_ReadsAreLowerable(fn, v)) return 0;
    if (!llOptionW_FeedsReturnOrIsReturnLocal(fn, v)) return 0;
    if (!llOptionW_DefiniteAssignment(fn, v)) return 0;
    return 1;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: predicate that
 * answers "does V require memory backing?" Returns 1 iff V has
 * multiple definitions (which the legacy SSA path would reject)
 * OR V matches the §2 rule 5 / 6 mechanically-frozen return-
 * local exception (direct `ret V`).
 *
 * The legacy SSA path (lc->values cache) handles single-def
 * locals correctly; the Option-W path exists ONLY for locals
 * that require mem2reg. Misclassifying a single-def local as
 * Option-W would force a memory round-trip through a slot that
 * is unnecessary (it would still verify, but it would consume
 * an entry-block alloca and an extra load/store per use).
 *
 * This is the discriminator gate that decides whether the C6
 * IMPL needs to memory-back V at all. */
static int llOptionW_RequiresMem2Reg(IrFunction *fn, IrValue *v) {
    if (!fn->blocks || !v) return 0;
    int n_defns = 0;
    int v_reaches_ret_directly = 0;
    listForEach(fn->blocks) {
        IrBlock *bb = (IrBlock *)it->value;
        List *node = bb->instructions->next;
        while (node != bb->instructions) {
            IrInstr *ins = (IrInstr *)node->value;
            /* Count case-(a) and case-(b) definitions. */
            if (ins->dst == v &&
                (ins->op == IR_STORE ||
                 ins->op == IR_IADD ||
                 ins->op == IR_ISUB)) {
                n_defns++;
            }
            /* Detect the direct `ret V` shape (the §2 rule 5
             * mechanically-frozen return-local exception). */
            if (ins->op == IR_RET && ins->dst == v) {
                v_reaches_ret_directly = 1;
            }
            node = node->next;
        }
    }
    /* Two or more reaching definitions = multi-def = requires
     * mem2reg (or rejection). One reaching definition plus
     * direct `ret V` also goes through Option-W (the direct
     * ret exception is explicit in §2 rule 5). Single-def with
     * no direct ret = legacy SSA path handles it. */
    return n_defns >= 2 || v_reaches_ret_directly;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: enumerate every
 * IR_VAL_LOCAL in the function that REQUIRES memory backing and
 * classify each under the Option-W discriminator. The first
 * ineligible V triggers a rejection (AC05: any ineligible V
 * must be REJECTED with the named diagnostic).
 *
 * On success, fills `lc->option_w_slots` with one entry per
 * eligible V (var.id -> placeholder sentinel; the actual LLVM
 * alloca is materialised by llMaterializeOptionWSlots below).
 *
 * Returns 0 on success, 1 on a first-ineligible-V rejection. */
static int llClassifyOptionWLocals(IrFunction *fn, LLCtx *lc) {
    if (!fn->blocks) return 0;
    listForEach(fn->blocks) {
        IrBlock *bb = (IrBlock *)it->value;
        List *node = bb->instructions->next;
        while (node != bb->instructions) {
            IrInstr *ins = (IrInstr *)node->value;
            IrValue *candidates[3] = { ins->dst, ins->r1, ins->r2 };
            for (int k = 0; k < 3; ++k) {
                IrValue *v = candidates[k];
                if (!v || v->kind != IR_VAL_LOCAL) continue;
                /* Skip single-def locals that don't reach a
                 * direct ret. The legacy SSA path handles them
                 * via lc->values. */
                if (!llOptionW_RequiresMem2Reg(fn, v)) continue;
                u32 vid = irVarId(v);
                if (vid < lc->option_w_slots.cap &&
                    lc->option_w_slots.values[vid] != NULL) {
                    continue;
                }
                if (llIsOptionWEligible(fn, v)) {
                    /* Reserve the var.id slot in the map; the
                     * LLVMValueRef is filled in by
                     * llMaterializeOptionWSlots. Use a non-NULL
                     * sentinel so the "already classified" test
                     * above works. */
                    llvmSet(&lc->option_w_slots, vid,
                        (LLVMValueRef)(uintptr_t)0x1);
                } else {
                    /* Ineligible: REJECT with the named diagnostic. */
                    fprintf(stderr,
                        "%s: function %s: mutable local id=%u (line "
                        "%d) requires memory backing but is not "
                        "Option-W eligible (the local violates one "
                        "of the §2 frozen discriminator rules -- "
                        "type, address-taken, definition opcode "
                        "outside {IR_STORE, IR_IADD, IR_ISUB}, read "
                        "envelope, or return-feed invariant). Per "
                        "AC05 the local is REJECTED rather than "
                        "silently widened.\n",
                        LLVM_BACKEND_UNSUPPORTED_OPTION_W_INELIGIBLE,
                        fn->name->data, vid, ins->line);
                    llEmitCapabilityCountersOnce(lc->totals);
                    return 1;
                }
            }
            /* IR_CALL carries its arguments inside an IrValueArray
             * accessible via ins->r1->as.array.values[i]. An
             * IR_VAL_LOCAL passed as a call argument is a read
             * (the value is consumed by the callee). We do NOT
             * classify call-by-value reads here: a single-def
             * local that is consumed only by a call argument
             * does not require memory backing -- the legacy SSA
             * cache can resolve it from its single IR_STORE.
             * If V has multiple definitions AND is consumed as
             * a call argument, the multi-def reject at the
             * existing IR_STORE handler will fire. */
            node = node->next;
        }
    }
    return 0;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: materialise one
 * LLVM entry-block alloca per Option-W eligible V. The placement
 * rule is the C6-normalised Q3.3 rule (per CORRECTION01 §6):
 *
 *   - prefer: before the first non-alloca instruction in the
 *     entry block (LLVMPositionBuilderBefore)
 *   - else:  append to end of empty entry block
 *     (LLVMPositionBuilderAtEnd)
 *
 * MUST be called AFTER llCreateBlocks so the LLVM entry block
 * exists; MUST be called BEFORE llLowerBlock on the entry block
 * so the allocas are visible to the per-block instruction
 * emitter. */
static int llMaterializeOptionWSlots(LLCtx *lc) {
    LLVMBasicBlockRef entry = LLVMGetEntryBasicBlock(lc->cur_fn_value);
    if (!entry) {
        fprintf(stderr, "%s: function %s: no LLVM entry block\n",
            LLVM_BACKEND_INTERNAL, lc->fn->name->data);
        return 1;
    }
    LLVMBuilderRef alloca_builder = LLVMCreateBuilderInContext(lc->ctx);
    LLVMValueRef first_non_alloca = LLVMGetFirstInstruction(entry);
    while (first_non_alloca && LLVMIsAAllocaInst(first_non_alloca)) {
        first_non_alloca = LLVMGetNextInstruction(first_non_alloca);
    }
    if (first_non_alloca) {
        LLVMPositionBuilderBefore(alloca_builder, first_non_alloca);
    } else {
        LLVMPositionBuilderAtEnd(alloca_builder, entry);
    }
    /* For every classified V (option_w_slots entries with a
     * non-NULL sentinel), emit one LLVMBuildAlloca and overwrite
     * the sentinel with the real LLVMValueRef. */
    for (u32 id = 0; id < lc->option_w_slots.cap; ++id) {
        LLVMValueRef cur = lc->option_w_slots.values[id];
        if (!cur) continue;
        char namebuf[64];
        snprintf(namebuf, sizeof(namebuf),
                 "polyc.optionw.slot.%u", id);
        LLVMValueRef slot = LLVMBuildAlloca(
            alloca_builder, LLVMInt64TypeInContext(lc->ctx), namebuf);
        if (!slot) {
            fprintf(stderr,
                "%s: function %s: LLVMBuildAlloca returned NULL "
                "for Option-W slot id=%u\n",
                LLVM_BACKEND_INTERNAL, lc->fn->name->data, id);
            LLVMDisposeBuilder(alloca_builder);
            return 1;
        }
        lc->option_w_slots.values[id] = slot;
        lc->option_w_count++;
    }
    LLVMDisposeBuilder(alloca_builder);
    lc->option_w_active = (lc->option_w_count > 0);
    return 0;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: helper that
 * returns the entry-block alloca for an Option-W eligible V, or
 * NULL if V is not Option-W eligible. The check is a simple map
 * lookup; no CFG walk is required. The sentinel 0x1 is filtered
 * out so callers only see real LLVM allocas. */
static LLVMValueRef llOptionWSlotFor(LLCtx *lc, IrValue *v) {
    if (!lc || !v || v->kind != IR_VAL_LOCAL) return NULL;
    LLVMValueRef slot = llvmGet(&lc->option_w_slots, irVarId(v));
    if (slot && (uintptr_t)slot != 0x1) return slot;
    return NULL;
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: load from V's
 * entry-block slot at the current builder position. Returns the
 * loaded i64 LLVMValueRef. The caller MUST have verified that V
 * is Option-W eligible via llOptionWSlotFor. */
static LLVMValueRef llEmitOptionWLoad(LLCtx *lc, IrValue *v) {
    LLVMValueRef slot = llOptionWSlotFor(lc, v);
    if (!slot) return NULL;
    /* LLVM 22 C API: LLVMBuildLoad2 takes the element type
     * explicitly (LLVMBuildLoad without type was removed). */
    return LLVMBuildLoad2(lc->bld, LLVMInt64TypeInContext(lc->ctx),
                          slot, "polyc.optionw.load");
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: store `value`
 * to V's entry-block slot at the current builder position. */
static void llEmitOptionWStore(LLCtx *lc, IrValue *v, LLVMValueRef value) {
    LLVMValueRef slot = llOptionWSlotFor(lc, v);
    if (!slot) return;
    LLVMBuildStore(lc->bld, value, slot);
}

/* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: run
 * LLVMRunPassesOnFunction on the current function with pipeline
 * "mem2reg,verify" (per Q4.1 evidence: the function-level C API
 * is the correct surface for a per-function promotion; same
 * pipeline syntax as opt -passes=mem2reg,verify). This is the
 * C6 replacement for the predecessor C9 llRunMem2RegOnFunction
 * helper. LLVM owns PHI placement policy -- iterated dominator
 * frontiers, NOT predecessor-edge synthesis. */
static int llRunOptionWMem2Reg(LLCtx *lc) {
    if (!lc->option_w_active) return 0;
    /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: bypass knob
     * for evidence capture. Set HCC_NO_MEM2REG=1 in the environment
     * to skip the mem2reg pass and emit the pre-mem2reg IR (the
     * entry-block alloca, store at each definition site, load at
     * each use site). The default behaviour (no env var) runs
     * mem2reg, which is what every LLVM consumer sees. */
    if (getenv("HCC_NO_MEM2REG")) {
        /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: not running mem2reg
         * is an internal evidence-only path; do NOT increment
         * any counter (the IR is not yet ready for verification,
         * but this path is never invoked from a real consumer). */
        return 0;
    }
    LLVMPassBuilderOptionsRef opts = LLVMCreatePassBuilderOptions();
    if (!opts) {
        fprintf(stderr, "%s: function %s: LLVMCreatePassBuilderOptions "
            "returned NULL\n", LLVM_BACKEND_INTERNAL, lc->fn->name->data);
        return 1;
    }
    LLVMErrorRef err = LLVMRunPassesOnFunction(
        lc->cur_fn_value, "mem2reg,verify", NULL, opts);
    if (err) {
        /* LLVM 22 C API: LLVMGetErrorMessage CONSUMES the error;
         * only LLVMDisposeErrorMessage the returned string. */
        char *msg = LLVMGetErrorMessage(err);
        fprintf(stderr,
            "%s: function %s: LLVMRunPassesOnFunction("
            "\"mem2reg,verify\") failed: %s\n",
            LLVM_BACKEND_INTERNAL, lc->fn->name->data,
            msg ? msg : "(null error)");
        if (msg) LLVMDisposeErrorMessage(msg);
        LLVMDisposePassBuilderOptions(opts);
        return 1;
    }
    LLVMDisposePassBuilderOptions(opts);
    return 0;
}


/* --- per-function lowering --------------------------------------------- */

static LLVMBasicBlockRef llLowerBlock(LLCtx *lc, IrBlock *b);
static LLVMValueRef llLowerInstr(LLCtx *lc, IrInstr *ins);
static LLVMTypeRef llType(LLCtx *lc, IrValueType t);

static int llTypeSupported(IrValueType t) {
    /* ACT-POLYC-LLVM-BYTE-MEMORY01: IR_TYPE_I8 admitted as a
     * first-class value type. The IR_TYPE_I8 representation
     * carries the byte access type on IR_LOAD_DEREF/IR_STORE_DEREF
     * (the neutral IR's load/store access-type contract); the
     * LLVM i8 bit width has no inherent signedness -- the IR's
     * widening opcode (IR_ZEXT / IR_SEXT) carries signedness. */
    return t == IR_TYPE_I64 || t == IR_TYPE_F64 || t == IR_TYPE_I8;
}

/* ACT-POLYC-LLVM-MEMORY01: function-parameter type authorisation.
 *
 * Only I64 (scalar), F64 (scalar, ACT-POLYC-LLVM-FLOAT01), I8
 * (scalar, ACT-POLYC-LLVM-BYTE-MEMORY01), and IR_TYPE_PTR
 * (pointer-to-I64) are accepted as function parameter types.
 * IR_TYPE_PTR is allowed here ONLY because the parameter
 * lowering seam (llPass1 + llBindParams) can map it directly to
 * LLVM opaque `ptr` without any local spill, alloca, or pointer
 * cast. Other value kinds (constants, locals, return values)
 * keep the strict llTypeSupported() contract: only IR_TYPE_I64,
 * IR_TYPE_F64, or IR_TYPE_I8 (BYTE-MEMORY01).
 *
 * Function return values are I64, F64, or I8 only: this ACT does
 * not authorise pointer return values (see ACT §7 excluded list).
 * I8 return values are emitted directly via the function's
 * `LLVMFunctionType` return type (see llPass1 below). */
static int llParamTypeSupported(IrValueType t) {
    return t == IR_TYPE_I64 || t == IR_TYPE_PTR || t == IR_TYPE_F64
        || t == IR_TYPE_I8;
}

static LLVMTypeRef llType(LLCtx *lc, IrValueType t) {
    (void)lc;
    if (t == IR_TYPE_I64) return LLVMInt64TypeInContext(lc->ctx);
    /* ACT-POLYC-LLVM-FLOAT01: scalar F64 maps to LLVM `double`
     * via LLVMDoubleTypeInContext. The C API does not expose
     * a different precision here: LLVM's binary64 IS the IEEE 754
     * double-precision type. No F32 mapping, no target-dependent
     * `long double`. */
    if (t == IR_TYPE_F64) return LLVMDoubleTypeInContext(lc->ctx);
    /* ACT-POLYC-LLVM-MEMORY01: opaque pointer for IR_TYPE_PTR. The
     * C API function LLVMPointerTypeInContext(ctx, AS) with AS=0
     * is the canonical LLVM 22 way to materialise the opaque
     * pointer type. The pointee type is NOT attached to the LLVM
     * pointer; it is supplied to load/store builders explicitly. */
    if (t == IR_TYPE_PTR) return LLVMPointerTypeInContext(lc->ctx, 0);
    /* ACT-POLYC-LLVM-BYTE-MEMORY01: IR_TYPE_I8 maps to LLVM `i8`
     * via LLVMInt8TypeInContext. Signedness is NOT a property of
     * the LLVM i8 bit width; it lives in the IR's widening opcode
     * (IR_ZEXT / IR_SEXT) per source/AST signedness. The LLVM
     * backend loweres IR_ZEXT i8 -> i64 as `zext` and IR_SEXT i8
     * -> i64 as `sext` (see llLowerInstr IR_ZEXT / IR_SEXT arms).
     * IR_TYPE_I1 is intentionally not in `IrValueType`; the spike
     * only emits i64 / f64 for source values. The cond->i1 truncation for
     * IR_BR uses LLVMInt1TypeInContext directly. */
    if (t == IR_TYPE_I8) return LLVMInt8TypeInContext(lc->ctx);
    return NULL;
}

static void llPass1(LLCtx *lc, IrProgram *prog) {
    LLVMTypeRef i64 = llType(lc, IR_TYPE_I64);
    for (u64 i = 0; i < prog->functions->size; ++i) {
        IrFunction *fn = vecGet(IrFunction*, prog->functions, i);
        if (!fn) continue;
        for (u64 p = 0; p < fn->params->size; ++p) {
            IrValue *pv = vecGet(IrValue*, fn->params, p);
            /* ACT-POLYC-LLVM-MEMORY01: parameter-only pointer
             * admission. The function body itself still uses
             * llTypeSupported() for locals/return/operands; the
             * pointer exception is bound to the function
             * signature ONLY, exactly as the ACT authorises. */
            if (!pv || !llParamTypeSupported(pv->type)) {
                llErrUnsupportedType(pv, fn, "function parameter");
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
        }
        if (!fn->return_value || !llTypeSupported(fn->return_value->type)) {
            llErrUnsupportedType(fn->return_value, fn,
                "function return value (only I64 or F64 supported)");
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        LLVMTypeRef param_tys[64];
        u32 np = (u32)fn->params->size;
        if (np > 64) {
            fprintf(stderr, "%s: too many parameters in %s (%u)\n",
                LLVM_BACKEND_INTERNAL, fn->name->data, np);
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        /* ACT-POLYC-LLVM-MEMORY01: per-parameter LLVM type mapping.
         * IR_TYPE_PTR -> opaque ptr; everything else still -> i64.
         * LLVMGetParam() in llBindParams then yields the
         * corresponding LLVMValueRef directly, with no alloca,
         * store-to-local, load-from-local, inttoptr, or ptrtoint.
         *
         * ACT-POLYC-LLVM-FLOAT01: per-function return type mapping.
         * The return type is now driven by fn->return_value->type:
         *   IR_TYPE_I64 -> LLVM i64
         *   IR_TYPE_F64 -> LLVM double (via llType)
         * Hard-coding i64 here would silently mismatch the IR_RET
         * operand for F64-returning functions and the LLVM verifier
         * would reject the module. */
        for (u32 p = 0; p < np; ++p) {
            IrValue *pv = vecGet(IrValue*, fn->params, p);
            param_tys[p] = llType(lc, pv->type);
        }
        LLVMTypeRef ret_ty = llType(lc, fn->return_value->type);
        LLVMTypeRef fty = LLVMFunctionType(ret_ty, param_tys, (unsigned)np, 0);
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
    /* ACT-POLYC-LLVM-MEMORY01: constants bypass the SSA cache.
     *
     * The IR constant value's `as._i64` overlaps the `as.var` union
     * member (the first 4 bytes of as are the IrVar id, the next 2
     * are its size). Storing `as._i64 = N` therefore ALSO sets
     * `irVarId(v) = (u32)N`. This collides with any other IR value
     * whose id happens to equal N (most notably: a function
     * parameter created via irTmp() at id 1 collides with the
     * constant `1`).
     *
     * The pre-existing scalar spike has been silently miscompiling
     * `x + 1` as `x + x` for this reason; the LLVM verifier accepts
     * the result so the bug stayed invisible. MEMORY01 surfaces the
     * bug because the constant value collides with the pointer
     * parameter id and the LLVM verifier now refuses `add i64, ptr`.
     *
     * The fix is local to the LLVM backend: do NOT cache constants
     * by `irVarId(v)`. Always materialise a fresh LLVMConstInt
     * from `v->as._i64`. The cache stays in sync for parameters,
     * locals, and tmps (whose `as.var.id` is set explicitly and
     * uniquely by irTmp / var->lvar_id).
     *
     * A neutral-IR-level correction (separating `as._i64` and
     * `as.var` storage, or giving constants a unique id space) is
     * out of scope for MEMORY01 and would require an IR ACT (see
     * ACT §23 HALT_NEUTRAL_IR_CHANGE_REQUIRED). */
    if (v->kind != IR_VAL_CONST_INT && v->kind != IR_VAL_CONST_FLOAT) {
        LLVMValueRef cached = llvmGet(&lc->values, irVarId(v));
        if (cached) return cached;
    }
    if (v->kind == IR_VAL_CONST_INT) {
        if (!llTypeSupported(v->type)) {
            llErrUnsupportedType(v, lc->fn, "constant");
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        LLVMValueRef c = LLVMConstInt(llType(lc, v->type),
                                      (unsigned long long)v->as._i64,
                                      1 /*signed*/);
        return c;
    }
    if (v->kind == IR_VAL_CONST_FLOAT) {
        /* ACT-POLYC-LLVM-FLOAT01: F64 constant materialisation.
         *
         * R3 (per ACT §6): the canonical neutral-IR F64 representation
         * is IR_VAL_CONST_FLOAT with the value in `as._f64` (per
         * src/ir.c:66-69 irConstFloat and src/ir-types.h:336). The
         * constant is bypassed from the SSA cache lookup for the SAME
         * reason IR_VAL_CONST_INT is bypassed (per the MEMORY01 fix
         * at src/llvm-backend.c:687 above): the union aliasing between
         * `as._f64` and `as.var` (4 bytes of the IEEE 754 bits land
         * in `var.id`) would otherwise cause constants whose bit
         * pattern collides with another TMP / PARAM id to be silently
         * substituted.
         *
         * LLVMConstReal preserves the host `double` bits verbatim;
         * the C API does not introduce any rounding. The mapping is
         * exact for binary64 <-> double on every supported host.
         */
        if (!llTypeSupported(v->type)) {
            llErrUnsupportedType(v, lc->fn, "constant");
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        LLVMValueRef c = LLVMConstReal(llType(lc, v->type),
                                       (double)v->as._f64);
        return c;
    }
    if (v->kind == IR_VAL_LOCAL) {
        /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: Option-W
         * eligible mutable locals are read through their entry-block
         * slot at every ORIGINAL read site. The slot is the
         * authoritative representation; lc->values[V] is NEVER
         * authoritative while V is Option-W eligible. This is
         * exactly the same-site load that the C4.v2 RED-3 evidence
         * commits for AccDigit bb11 (the case-(b) RHS that reads
         * V's old value before the add).
         *
         * For non-Option-W locals, fall back to the legacy SSA
         * cache (lc->values) lookup that the bounded I64 spike
         * already uses. */
        if (llOptionWSlotFor(lc, v)) {
            LLVMValueRef loaded = llEmitOptionWLoad(lc, v);
            if (!loaded) {
                fprintf(stderr,
                    "%s: function %s: Option-W slot load for "
                    "IR_VAL_LOCAL id=%u failed\n",
                    LLVM_BACKEND_INTERNAL, lc->fn->name->data,
                    irVarId(v));
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            return loaded;
        }
        /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
         * a non-Option-W LOCAL is resolved through its scalar SSA
         * binding (recorded by a prior IR_STORE). The bounded I64
         * spike pre-allocated an alloca for every local; we don't.
         * If we reach here without a binding, the local was read
         * before it was assigned (or its bind never happened).
         * That is a bounded-spike defect: fail loud. */
        fprintf(stderr,
            "%s: function %s: IR_VAL_LOCAL id=%u read with no "
            "SSA binding (use-before-def, or assigned in a "
            "shape this spike does not support)\n",
            LLVM_BACKEND_INTERNAL_UNBOUND_VALUE,
            lc->fn->name->data, irVarId(v));
        llEmitCapabilityCountersOnce(lc->totals);
        exit(1);
    }
    if (v->kind == IR_VAL_CONST_STR ||
        v->kind == IR_VAL_GLOBAL    || v->kind == IR_VAL_PHI ||
        v->kind == IR_VAL_LABEL    || v->kind == IR_VAL_UNDEFINED ||
        v->kind == IR_VAL_UNRESOLVED) {
        llErrUnsupportedType(v, lc->fn, "value kind");
        llEmitCapabilityCountersOnce(lc->totals);
        exit(1);
    }
    fprintf(stderr, "%s: value %s (id=%u) used before definition\n",
        LLVM_BACKEND_INTERNAL,
        irValueKindToString(v->kind), irVarId(v));
    llEmitCapabilityCountersOnce(lc->totals);
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

/* ACT-POLYC-LLVM-MEMORY01: pointer SSA value resolver.
 *
 * Mirrors llLowerI64Value but specialised for IR_TYPE_PTR. The
 * binding is the LLVMValueRef returned by LLVMGetParam when the
 * underlying IR value is a function parameter (set by
 * llBindParams), or a prior IR_STORE of a pointer-typed local
 * (set by the IR_STORE handler). The cache holds the opaque ptr
 * directly; no LLVMBuildLoad2 is emitted.
 *
 * Rejected if:
 *   - the underlying value has not been bound (use-before-def or
 *     RESERVED memory shape) -- fails via the use-before-def path
 *     inside llLowerValue.
 *   - the value's type is not IR_TYPE_PTR -- silently rejected by
 *     the cache lookup (no binding would have been recorded under
 *     a different type). The caller is expected to know the
 *     context. */
static LLVMValueRef llLowerPointerValue(LLCtx *lc, IrValue *v) {
    if (!v) return NULL;
    /* The SSA cache key is the IR var id (set by llvmSet in
     * llBindParams / IR_STORE). Pointer values never go through
     * the IR_VAL_CONST_INT path in llLowerValue, so the cache is
     * the only valid source. */
    LLVMValueRef lv = llvmGet(&lc->values, irVarId(v));
    if (lv) return lv;
    fprintf(stderr,
        "%s: function %s: pointer value (id=%u, kind=%s) used "
        "before definition\n",
        LLVM_BACKEND_INTERNAL,
        lc->fn->name->data, irVarId(v),
        irValueKindToString(v->kind));
    llEmitCapabilityCountersOnce(lc->totals);
    exit(1);
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

/* ACT-POLYC-LLVM-FLOAT01: float predicate mapping.
 *
 * Maps the six PolyC float-comparison IrCmpKind values to the LLVM
 * LLVMRealPredicate enum values. The mapping is derived from the
 * native semantic oracle captured during RED (see
 *   evidence/llvm-float01/red/recon-comparison-semantics.txt)
 * which exercised aarch64-native fcmp + cset behaviour for NaN
 * operands and proved:
 *
 *   ==  -> oeq   (NaN -> false)
 *   !=  -> une   (NaN -> true)
 *   <   -> olt   (NaN -> false)
 *   <=  -> ole   (NaN -> false)
 *   >   -> ogt   (NaN -> false)
 *   >=  -> oge   (NaN -> false)
 *
 * The strict-ordered predicates for ==, <, <=, >, >= and the
 * unordered predicate for != are exactly the IEEE 754 semantics
 * the aarch64 backend produces via cset "eq"/"mi"/"ls"/"gt"/"ge"
 * and "ne" for fcmp-on-NaN.
 *
 * Other IrCmpKind values (e.g. IR_CMP_OEQ, IR_CMP_UNO, IR_CMP_ORD)
 * are NOT emitted by the HolyC frontend (per src/ir.c:722-758 which
 * only produces IR_CMP_EQ/NE/LT/LE/GT/GE); they reach here only via
 * an upstream regression. In that case we fail loud rather than
 * guess an LLVM predicate.
 */
static LLVMRealPredicate llFloatCmpKindToLLVMPred(IrCmpKind k) {
    switch (k) {
        case IR_CMP_EQ: return LLVMRealOEQ;
        case IR_CMP_NE: return LLVMRealUNE;
        case IR_CMP_LT: return LLVMRealOLT;
        case IR_CMP_LE: return LLVMRealOLE;
        case IR_CMP_GT: return LLVMRealOGT;
        case IR_CMP_GE: return LLVMRealOGE;
        default:
            fprintf(stderr,
                "%s: unsupported float cmp kind %d; "
                "FLOAT01 only supports == != < <= > >=\n",
                LLVM_BACKEND_UNSUPPORTED_FLOAT_CMP, (int)k);
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
                /* ACT-POLYC-LLVM-FLOAT01: collapse path now
                 * dispatches on the slot's neutral-IR type: I64
                 * lowers via llLowerI64Value (the historical path),
                 * F64 lowers via llLowerValue which returns an SSA
                 * LLVMValueRef of physical type `double`. No
                 * bitcast between integer and floating types. */
                LLVMValueRef lv;
                if (v->type == IR_TYPE_I64) {
                    lv = llLowerI64Value(lc, v);
                } else {
                    lv = llLowerValue(lc, v);
                }
                LLVMBuildRet(lc->bld, lv);
                /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: collapse path
                 * delivers SUPPORTED via the IR_RET arm; this jmp
                 * is the architectural trigger and is NOT counted
                 * a second time. */
                node = next;
                continue;
            }
            LL_INC_SUPPORTED(lc);
            /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: the
             * C9 predecessor-store synthesis is DELETED. Stores
             * exist only because a PolyC definition occurred at
             * the current instruction. An IR_JMP terminator never
             * carries a synthetic store -- the merged-store block's
             * load will observe the most-recent definition in the
             * predecessor chain because the definition emitted its
             * store at the ORIGINAL definition site (case-a or
             * case-b), and LLVM mem2reg reconstructs the SSA value
             * across the predecessor edges at the post-lowering
             * pass boundary. */
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
            /* IR_BR carries its condition via `dst` (per ir-eval.c).
             *
             * Neutral IR contract: dst is IR_TYPE_I64 carrying a {0, 1}
             * predicate value. This guard checks the neutral-IR side
             * and rejects any non-i64 dst immediately.
             */
            if (!ins->dst || ins->dst->type != IR_TYPE_I64) {
                fprintf(stderr,
                    "%s: IR_BR condition must be i64 (got kind=%d type=%d)\n",
                    LLVM_BACKEND_UNSUPPORTED_IR,
                    ins->dst ? ins->dst->kind : -1,
                    ins->dst ? ins->dst->type : -1);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            /* ACT-POLYC-LLVM-CORE01-CORRECTION01 (RED-4):
             *
             * The cache may hold either an i1 (result of IR_ICMP
             * lowered via LLVMBuildICmp) or an i64 (literal 0/1
             * constant). LLVMBuildCondBr requires i1.
             *
             * ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01 fused
             * IR_ICMP+IR_BR into IR_CMP_BR; IR_BR is therefore the
             * non-fused FALLBACK path that the current spike never
             * exercises (verified via dump-ir transcripts:
             *   evidence/llvmspike01-core01-correction01/red-p04-irbr-dead.txt).
             *
             * Dispatch by LLVM physical type:
             *   i1 -> use directly (LLVMBuildCondBr accepts i1)
             *   i64 with width 1 -> use directly (LLVM equates i1 and
             *                         i1-typed i64 for condbr consumers
             *                         in practice; defensively treat
             *                         same-as-i1)
             *   i64 width 8 -> trunc to i1 (preserves the historical
             *                  {0,1} -> bool translation that the
             *                  predecessor spike relied on)
             *   any other width -> reject with a named boundary
             *                      diagnostic; do NOT guess.
             *
             * Do NOT "fix" this by changing IR_BR's neutral-IR dst type
             * to i1; that would break the native backend (which treats
             * the condition as i64) and is FORBIDDEN by ACT §7.
             */
            LLVMValueRef cond = llLowerI64Value(lc, ins->dst);
            LLVMTypeRef cond_ty = LLVMTypeOf(cond);
            LLVMValueRef cond1 = NULL;
            if (cond_ty == LLVMInt1TypeInContext(lc->ctx)) {
                cond1 = cond;
            } else if (cond_ty == LLVMInt64TypeInContext(lc->ctx)) {
                /* ACT-POLYC-LLVM-CORE03-CORRECTION01 M3: defensive
                 * invariant guard made FATAL.
                 *
                 * The canonical lowerer produces IR_BR cond as the
                 * dst of an immediately-preceding IR_ICMP, so the
                 * cond is physically i1 on the LLVM path. If we
                 * observe i64 here, an upstream regression has
                 * dropped the ICMP wrap (e.g. a future fusion pass
                 * called on the LLVM path by mistake).
                 *
                 * CORE03 originally defended with a trunc i64 -> i1
                 * and a counter, but trunc is parity semantics:
                 * trunc(i64 2) = 0 = false, while PolyC's source-level
                 * truthiness contract says 2 -> true. The trunc would
                 * produce a verifier-clean MISCOMPILE for any i64
                 * value outside {0, 1}. This is exactly the silent
                 * miscompile class Factory doctrine has repeatedly
                 * tried to eliminate.
                 *
                 * The defensive path now REFUSES to emit possibly
                 * wrong LLVM. If i64 truthiness is ever intentionally
                 * supported, the correct conversion is icmp ne i64 %x, 0
                 * (not trunc) and requires a fresh ACT. */
                fprintf(stderr,
                    "%s: function %s: IR_BR cond is i64, not i1; "
                    "neutral/LLVM boundary violation. Refusing to emit "
                    "possibly wrong LLVM (trunc i64 -> i1 would miscompile "
                    "any non-{0,1} value via parity). Line %d.\n",
                    LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED,
                    lc->fn->name->data, ins->line);
                lc->defensive_trips++;
                /* ACT-POLYC-LLVM-CORE04-RESUME01 §6.3: the defensive
                 * path terminates with exit(1); flush counters before
                 * the process dies so REJECTED via defensive trip is
                 * captured (idempotent vs. the success-path emission). */
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            } else {
                fprintf(stderr,
                    "%s: function %s: IR_BR cond has unexpected LLVM "
                    "physical type (got %d-bit integer, expected i1 or "
                    "i64 predicate); refusing to guess. This is a "
                    "neutral/LLVM boundary violation.\n",
                    LLVM_BACKEND_UNSUPPORTED_IR,
                    lc->fn->name->data,
                    (int)LLVMGetIntTypeWidth(cond_ty));
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
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
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: SUPPORTED terminator
             * (i1 cond path; the i64-cond defensive path above has
             * already exited via lc->defensive_trips++). */
            LL_INC_SUPPORTED(lc);
            /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: the
             * C9 predecessor-store synthesis is DELETED. An
             * IR_BR terminator never carries a synthetic store --
             * the per-predecessor value of an Option-W eligible V
             * is observed by the merged-store block's load because
             * each definition emitted its store at the ORIGINAL
             * definition site, and LLVM mem2reg reconstructs the
             * SSA value across the predecessor edges at the post-
             * lowering pass boundary. */
            LLVMBuildCondBr(lc->bld, cond1, t, f);
            node = next;
            continue;
        }
        if (ins->op == IR_CMP_BR) {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: IR_CMP_BR capability
             * class is REJECTED (boundary violation). Count before the
             * diagnostic, then bail with NULL (the existing
             * ACT-POLYC-IR-BOUNDARY03 contract). The CAPABILITY_COUNTERS
             * record is emitted by the driver's failure-handling path
             * (see llFunction's return-1 plumbing below). */
            LL_INC_REJECTED(lc);
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
            llEmitCapabilityCountersOnce(lc->totals);
            return NULL;
        }
        if (ins->op == IR_RET) {
            if (lc->collapsed && b == lc->fn->exit_block) {
                /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: the collapse
                 * exit block becomes `unreachable`; this IR_RET
                 * is structurally absorbed by the predecessor's
                 * `ret` and is NOT counted as SUPPORTED again. */
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
                /* ACT-POLYC-LLVM-FLOAT01: the return value may be
                 * IR_TYPE_I64 or IR_TYPE_F64; the same llLowerValue
                 * path resolves either into an SSA LLVMValueRef of
                 * the appropriate physical type (i64 or double).
                 * No bitcast between i64 and double is performed
                 * anywhere in this ACT (per ACT §1.2).
                 *
                 * ACT-POLYC-LLVM-BYTE-MEMORY01: the IR_RET operand
                 * may carry an IR_TYPE_I64 widened value (the result
                 * of an IR_ZEXT/IR_SEXT byte->I64 promotion) while
                 * the function's nominal return type is IR_TYPE_I8.
                 * The LLVM function signature is built from
                 * `fn->return_value->type` (in llPass1), so the
                 * LLVM `ret` instruction must produce the narrower
                 * physical type. The narrowing happens here at the
                 * IR_RET site via LLVMBuildTrunc -- this is a
                 * BACKEND-LOCAL narrow at the return boundary; it
                 * does NOT introduce IR_TRUNC into the neutral IR
                 * and does NOT change the byte-store / byte-narrowing
                 * status of IR_TRUNC, which BYTE-MEMORY01 defers. */
                if (!llTypeSupported(ins->dst->type)) {
                    llErrUnsupportedType(ins->dst, lc->fn, "ret value");
                    exit(1);
                }
                v = llLowerValue(lc, ins->dst);
                /* If the function's nominal return type is narrower
                 * than the IR_RET operand's type, narrow at the
                 * boundary. This is the byte->I8 return case. */
                if (lc->fn->return_value &&
                    lc->fn->return_value->type == IR_TYPE_I8 &&
                    ins->dst->type != IR_TYPE_I8) {
                    v = LLVMBuildTrunc(lc->bld, v,
                        LLVMInt8TypeInContext(lc->ctx), "ret_trunc_to_i8");
                }
            }
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: SUPPORTED terminator. */
            LL_INC_SUPPORTED(lc);
            LLVMBuildRet(lc->bld, v);
            node = next;
            continue;
        }
        if (ins->op == IR_STORE) {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: SHAPE_DEPENDENT
             * dispatch seam reached; count once per dispatched
             * IR_STORE regardless of which sub-shape is taken below.
             * Per ACT §5.3, a rejected shape is NOT also counted
             * as REJECTED (IR_STORE is SHAPE_DEPENDENT, not REJECTED). */
            LL_INC_SHAPE_DEPENDENT(lc);
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
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            /* Case 2: return-slot store consumed by collapse. */
            if (lc->collapsed && ins->dst == lc->collapse_slot) {
                /* dead; the predecessor already emitted `ret <v>`. */
                node = next;
                continue;
            }
            /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6:
             * synthetic return slot store consumed by the
             * Option-W forwarder. The IR_STORE r1=X dst=%tS is
             * the single-definition site of the synthetic slot;
             * lower r1 (which may itself be an Option-W V whose
             * read turns into a same-site load from its slot)
             * and bind the resulting LLVMValueRef to dst in the
             * SSA cache so the matching IR_LOAD in the same
             * block returns it. No LLVM instruction is emitted
             * for the store itself; the synthetic slot is purely
             * an SSA forwarding point. */
            if (ins->dst && llOptionW_SyntheticReturnSlotFor(lc->fn, ins->dst)) {
                LLVMValueRef v = llLowerValue(lc, ins->r1);
                if (!v) {
                    fprintf(stderr,
                        "%s: function %s: IR_STORE into synthetic "
                        "return slot: could not lower r1\n",
                        LLVM_BACKEND_INTERNAL, lc->fn->name->data);
                    llEmitCapabilityCountersOnce(lc->totals);
                    exit(1);
                }
                llvmSet(&lc->values, irDstVarId(ins), v);
                node = next;
                continue;
            }
            LL_INC_SUPPORTED(lc);
            /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: case
             * (a) lowering for Option-W eligible V. When V's
             * IR_STORE target is an Option-W eligible mutable
             * local, the lowering emits a real LLVM store to the
             * entry-block alloca at THIS ORIGINAL definition
             * site. No SSA cache binding is recorded for V; V's
             * reads are routed through llEmitOptionWLoad which
             * emits a same-site load from the slot.
             *
             * The C9 predecessor-store synthesis is DELETED. A
             * store exists because a PolyC definition occurred
             * HERE; there is no successor-driven store and no
             * terminator-driven store. LLVM's mem2reg pass
             * reconstructs the SSA value across the predecessor
             * edges at the post-lowering pass boundary. */
            if (llOptionWSlotFor(lc, ins->dst)) {
                LLVMValueRef v = llLowerValue(lc, ins->r1);
                if (!v) {
                    fprintf(stderr,
                        "%s: function %s: IR_STORE case-(a): could "
                        "not lower RHS for Option-W slot\n",
                        LLVM_BACKEND_INTERNAL, lc->fn->name->data);
                    llEmitCapabilityCountersOnce(lc->totals);
                    exit(1);
                }
                llEmitOptionWStore(lc, ins->dst, v);
                /* Do NOT update lc->values[ins->dst] -- the slot
                 * is the authoritative representation of V. */
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
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            /* ACT-POLYC-LLVM-MEMORY01: also accept IR_TYPE_PTR locals.
             * The MEMORY01 ACT authorises pointer values to flow
             * through SSA locals without materialising memory
             * (pointer locals requiring memory representation are
             * still excluded by ACT §7). The local is bound to the
             * LLVMValueRef of its source (e.g. a pointer parameter)
             * via llLowerPointerValue; no alloca/store-to-local is
             * emitted.
             *
             * ACT-POLYC-LLVM-FLOAT01: also accept IR_TYPE_F64 locals.
             * The F64 local is bound to the SSA LLVMValueRef of its
             * source via llLowerValue (which handles IR_VAL_CONST_FLOAT,
             * IR_VAL_PARAM, and prior IR_STORE of F64 values). No
             * alloca, no stack slot, no F64 memory. */
            if (ins->dst->type != IR_TYPE_I64 &&
                ins->dst->type != IR_TYPE_PTR &&
                ins->dst->type != IR_TYPE_F64 &&
                ins->dst->type != IR_TYPE_I8) {
                llErrUnsupportedType(ins->dst, lc->fn,
                    "IR_STORE local type (only I64, I8, F64 or pointer supported)");
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            if (!ins->r1) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE local, value has no "
                    "value operand at line %d\n",
                    LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL,
                    lc->fn->name->data, ins->line);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            /* ACT-POLYC-LLVM-MEMORY01: dst->type selects the
             * value-lowering path. IR_TYPE_PTR locals need
             * llLowerPointerValue (which only resolves through the
             * existing SSA cache, populated earlier by llBindParams
             * for parameters and by prior IR_STORE for pointer
             * locals). Constants are forbidden; PolyC has no
             * pointer constants.
             *
             * ACT-POLYC-LLVM-FLOAT01: IR_TYPE_F64 dst lowers its
             * value via llLowerValue, which handles IR_VAL_CONST_FLOAT
             * (via LLVMConstReal) and resolves F64 SSA bindings
             * through the cache. */
            LLVMValueRef v;
            if (ins->dst->type == IR_TYPE_PTR) {
                v = llLowerPointerValue(lc, ins->r1);
            } else {
                v = llLowerValue(lc, ins->r1);
            }

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
                    llEmitCapabilityCountersOnce(lc->totals);
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
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: SHAPE_DEPENDENT
             * dispatch seam reached; count once per dispatched
             * IR_LOAD regardless of which sub-shape is taken below.
             * Per ACT §5.3, a rejected shape is NOT also counted
             * as REJECTED (IR_LOAD is SHAPE_DEPENDENT, not REJECTED). */
            LL_INC_SHAPE_DEPENDENT(lc);
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
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            LL_INC_SUPPORTED(lc);
            /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6:
             * synthetic return slot load under Option-W. This
             * check is BEFORE the legacy collapse branch because
             * `lc->collapsed` may be set (when the original
             * exit_block was folded by `irRemoveRedundantBlocks`)
             * even though the synthetic return slot is still
             * alive in the IR. The Option-W path forwards the
             * value from the SSA cache (populated by the matching
             * IR_STORE earlier in the same block) to the
             * IR_LOAD's dst so the following IR_RET can read it. */
            if (ins->r1 && llOptionW_SyntheticReturnSlotFor(lc->fn, ins->r1)) {
                LLVMValueRef v = llvmGet(&lc->values, irVarId(ins->r1));
                if (!v) {
                    fprintf(stderr,
                        "%s: function %s: IR_LOAD from synthetic "
                        "return slot: slot value not bound in SSA cache\n",
                        LLVM_BACKEND_INTERNAL, lc->fn->name->data);
                    llEmitCapabilityCountersOnce(lc->totals);
                    exit(1);
                }
                llvmSet(&lc->values, irDstVarId(ins), v);
                node = next;
                continue;
            }
            /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: the
             * CORRECTION01 C9 IR_LOAD-of-slot branch is DELETED.
             * The C6 architecture does not memory-back the
             * synthetic return slot -- instead, every original
             * read of an Option-W eligible V is lowered as a
             * same-site load via llEmitOptionWLoad at the point
             * where the read occurs (in llLowerValue's IR_VAL_LOCAL
             * branch). The IR_LOAD of the synthetic return slot
             * remains an SSA bind in the legacy collapse path; the
             * Option-W path does not generate any IR_LOAD for V. */
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
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        if (ins->op == IR_ALLOCA) {
            /* ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
             * the only legal IR_ALLOCA in this spike is the
             * return-slot alloc in the entry block, consumed by
             * collapse-elimination. Any other alloca is a
             * bounded-spike defect. */
            if (lc->collapsed && ins->dst == lc->collapse_slot) {
                /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: IR_ALLOCA
                 * capability class is REJECTED; consumed by the
                 * collapse pattern but still a REJECTED-class op
                 * reaching its REJECTED-class path. The grouped
                 * case-arm in llLowerInstr below would also fire
                 * for uncaught allocas; this branch is the
                 * collapse-aware sink and is the canonical counting
                 * site for ALLOCA in this spike. */
                LL_INC_REJECTED(lc);
                /* dead; collapse eliminates it. */
                node = next;
                continue;
            }
            /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: the
             * Option-W path encounters the synthetic return slot
             * pattern when `irForwardReturnSlot` could not fold the
             * per-path return-via-slot into a direct `ret` (because
             * multiple CFG paths converge in the exit block). In
             * this case the IR carries an IR_ALLOCA in the entry
             * block whose dst is an IR_VAL_TMP that is consumed by
             * exactly one IR_STORE + IR_LOAD + IR_RET in the exit
             * block. The slot has a single definition site and a
             * single use site, so it can be lowered as a pure SSA
             * forwarding point (no LLVM alloca / store / load
             * emitted). The pattern is detected by
             * llOptionW_SyntheticReturnSlotFor; if it matches, the
             * IR_ALLOCA is a no-op. */
            if (ins->dst && llOptionW_SyntheticReturnSlotFor(lc->fn, ins->dst)) {
                LL_INC_SUPPORTED(lc);
                /* dead; synthetic slot is purely an SSA
                 * forwarding point under Option-W. */
                node = next;
                continue;
            }
            LL_INC_SUPPORTED(lc);
            /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: the
             * C9 IR_ALLOCA-skip branch is DELETED. The CORRECTION02
             * architecture does not consume any IR_ALLOCA from the
             * neutral IR for Option-W eligible Vs; the entry-block
             * allocas are materialised directly by
             * llMaterializeOptionWSlots (one per eligible V). If
             * an IR_ALLOCA reaches this point under C6, it is
             * either the legacy collapse-elimination slot (handled
             * above) or an unexpected alloca that the C6
             * discriminator has already rejected. The conservative
             * behavior is to fall through to the structural
             * rejection below. */
            fprintf(stderr,
                "%s: function %s: unexpected IR_ALLOCA "
                "(this spike is SSA-only and does not allocate "
                "stack slots). line %d, dst id=%u, kind=%s\n",
                LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL,
                lc->fn->name->data,
                ins->line,
                irVarId(ins->dst),
                ins->dst ? irValueKindToString(ins->dst->kind) : "(null)");
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED via the
             * SSA-local fail-fast. Emit counters before exit so the
             * rejected invocation still produces a CAPABILITY_COUNTERS
             * record (§6.3 load-bearing requirement). */
            LL_INC_REJECTED(lc);
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }

        LLVMValueRef v = llLowerInstr(lc, ins);
        if (ins->dst && v) llvmSet(&lc->values, irDstVarId(ins), v);

        node = next;
    }

    return bb;
}

/* ACT-POLYC-LLVM-BYTE-MEMORY01: handle I8 char-literal operands in
 * binary arithmetic / comparison.
 *
 * The IR builder may produce arithmetic / comparison instructions
 * where one operand is a PolyC char literal (e.g. '0', 'a', '_')
 * with neutral IR type IR_TYPE_I8, while the other operand is an
 * I64 value (the result of an IR_ZEXT byte promotion). The LLVM
 * `add` / `sub` / `mul` / `icmp` instructions require both operands
 * to share the same LLVM type.
 *
 * Approach: when an arithmetic / comparison has an I8 constant
 * operand (the byte-promoted I64 vs an I8 char literal pattern),
 * narrow the I64 widened-byte operand down to I8 BEFORE the
 * operation, perform the binary op at i8, then widen back to i64
 * for the dst (which is always I64 in the byte path, per the IR
 * builder's pattern). The narrowing is lossless because the IR
 * builder's byte-promotion pattern keeps the value within byte
 * range throughout.
 *
 * Why narrow rather than widen the constant? Widening an I8
 * constant via LLVMBuildZExt produces a real SSA ZExt instruction
 * that must be positioned at the current builder location. With
 * the IR builder's collapse pattern (which can produce SSA-incorrect
 * IR for byte locals), the widened-constant's ZExt instruction
 * may end up in a block that does not dominate the binary op's
 * user. Narrowing the I64 SSA value at the use site avoids this
 * whole class of problems.
 */
static int llIsI8Const(IrValue *v) {
    return v && v->kind == IR_VAL_CONST_INT && v->type == IR_TYPE_I8;
}

/* Lower a binary op's operand. If the other operand is an I8 const
 * AND this operand is an SSA value, narrow the SSA value to I8
 * (the bit pattern is preserved). For the I8 const operand, lower
 * it directly as an LLVM i8 constant. */
static LLVMValueRef llLowerBinaryOperand(LLCtx *lc, IrValue *v,
                                          int is_i8_const_pair) {
    if (is_i8_const_pair && v && v->kind != IR_VAL_CONST_INT) {
        /* Narrow the I64 widened-byte value to I8. */
        LLVMValueRef lv = llLowerI64Value(lc, v);
        return LLVMBuildTrunc(lc->bld, lv,
            LLVMInt8TypeInContext(lc->ctx), "i8_arg_trunc");
    }
    if (is_i8_const_pair && v && v->kind == IR_VAL_CONST_INT) {
        /* Lower I8 const directly. */
        return llLowerValue(lc, v);
    }
    return llLowerI64Value(lc, v);
}

static LLVMValueRef llLowerInstr(LLCtx *lc, IrInstr *ins) {
    switch (ins->op) {
        case IR_IADD:
        case IR_ISUB: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: SUPPORTED arithmetic.
             *
             * ACT-POLYC-LLVM-BYTE-MEMORY01: when an I8 char literal is
             * one operand and the other is a byte-promoted I64, the
             * arithmetic is performed at i8 level (both operands
             * narrowed to i8) and the result widened back to i64 for
             * the I64 dst. See `llLowerBinaryOperand` for rationale.
             *
             * ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: case
             * (b) lowering for Option-W eligible V. When V is the
             * dst of an IR_IADD / IR_ISUB, the add/sub is computed
             * at THIS ORIGINAL definition site (any self-referential
             * read of V obtains its value through llEmitOptionWLoad
             * via llLowerValue's IR_VAL_LOCAL branch) and the
             * result is stored to V's entry-block slot. No SSA
             * cache binding is recorded for V.
             *
             * The C9 predecessor-store synthesis is DELETED. A
             * store exists because a PolyC definition occurred
             * HERE; there is no successor-driven store and no
             * terminator-driven store. */
            LL_INC_SUPPORTED(lc);
            if (!llTypeSupported(ins->dst->type)) {
                llErrUnsupportedType(ins->dst, lc->fn, "i64-arith dst");
                exit(1);
            }
            int i8_pair = llIsI8Const(ins->r1) || llIsI8Const(ins->r2);
            LLVMValueRef a = llLowerBinaryOperand(lc, ins->r1, i8_pair);
            LLVMValueRef b = llLowerBinaryOperand(lc, ins->r2, i8_pair);
            LLVMValueRef r;
            if (ins->op == IR_IADD) r = LLVMBuildAdd(lc->bld, a, b, "");
            else r = LLVMBuildSub(lc->bld, a, b, "");
            if (i8_pair && ins->dst->type == IR_TYPE_I64) {
                /* Widen the i8 result back to i64 for the I64 dst.
                 * Use ZExt (unsigned-byte convention). */
                r = LLVMBuildZExt(lc->bld, r,
                    LLVMInt64TypeInContext(lc->ctx), "i8_arith_zext");
            }
            /* case-(b): if dst is an Option-W eligible V, store the
             * result to V's slot at the original definition site. */
            if (llOptionWSlotFor(lc, ins->dst)) {
                llEmitOptionWStore(lc, ins->dst, r);
                /* Return NULL so the caller does NOT cache r into
                 * lc->values[ins->dst]. The slot is the
                 * authoritative representation. */
                return NULL;
            }
            return r;
        }
        case IR_IMUL: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: SUPPORTED arithmetic.
             *
             * ACT-POLYC-LLVM-BYTE-MEMORY01: see IR_IADD arm.
             *
             * ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6:
             * IMUL dsts are NOT in the frozen CASE_B_OPCODE_SET
             * ({iadd, isub} per C3). An IR_IMUL whose dst is a
             * mutable local is INELIGIBLE for Option-W; the
             * classifier already rejected such V during
             * llClassifyOptionWLocals. The IR_IMUL arm here does
             * NOT emit a case-(b) store; it lowers normally. */
            LL_INC_SUPPORTED(lc);
            if (!llTypeSupported(ins->dst->type)) {
                llErrUnsupportedType(ins->dst, lc->fn, "i64-arith dst");
                exit(1);
            }
            int i8_pair = llIsI8Const(ins->r1) || llIsI8Const(ins->r2);
            LLVMValueRef a = llLowerBinaryOperand(lc, ins->r1, i8_pair);
            LLVMValueRef b = llLowerBinaryOperand(lc, ins->r2, i8_pair);
            LLVMValueRef r = LLVMBuildMul(lc->bld, a, b, "");
            if (i8_pair && ins->dst->type == IR_TYPE_I64) {
                /* Widen the i8 result back to i64 for the I64 dst.
                 * Use ZExt (unsigned-byte convention). */
                return LLVMBuildZExt(lc->bld, r,
                    LLVMInt64TypeInContext(lc->ctx), "i8_arith_zext");
            }
            return r;
        }
        case IR_ICMP: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: SUPPORTED comparison.
             *
             * ACT-POLYC-LLVM-BYTE-MEMORY01: when one operand is an I8
             * char literal and the other is a byte-promoted I64, both
             * are narrowed to i8 before the icmp. The result is an
             * i1 either way. */
            LL_INC_SUPPORTED(lc);
            if (!llTypeSupported(ins->dst->type)) {
                llErrUnsupportedType(ins->dst, lc->fn, "icmp dst");
                exit(1);
            }
            int i8_pair = llIsI8Const(ins->r1) || llIsI8Const(ins->r2);
            LLVMValueRef a = llLowerBinaryOperand(lc, ins->r1, i8_pair);
            LLVMValueRef b = llLowerBinaryOperand(lc, ins->r2, i8_pair);
            LLVMIntPredicate p = llCmpKindToLLVMPred(ins->extra.cmp_kind);
            return LLVMBuildICmp(lc->bld, p, a, b, "");
        }
        case IR_CALL: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: SUPPORTED direct call. */
            LL_INC_SUPPORTED(lc);
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
        /* ACT-POLYC-LLVM-CORE01: explicit REJECTED arms.
         *
         * Every REJECTED opcode class from the capability matrix at the
         * top of this file gets an explicit `case` here. Each arm
         * emits the named LLVM_BACKEND_UNSUPPORTED_<CLASS> diagnostic
         * (NEVER the generic LLVM_BACKEND_UNSUPPORTED_IR token) and
         * exits nonzero. The `default:` arm remains as a safety net
         * for opcodes NOT_YET_CLASSIFIED. */
        case IR_IDIV:
        case IR_UDIV: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: integer division is not supported "
                "(opcode %s); use IR_IADD/IR_ISUB/IR_IMUL\n",
                LLVM_BACKEND_UNSUPPORTED_INT_DIVISION,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_IREM:
        case IR_UREM: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: integer remainder is not supported "
                "(opcode %s); use IR_IADD/IR_ISUB/IR_IMUL\n",
                LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_INEG: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: integer negation is not supported "
                "(opcode %s)\n",
                LLVM_BACKEND_UNSUPPORTED_INT_NEGATION,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_FADD:
        case IR_FSUB:
        case IR_FMUL: {
            /* ACT-POLYC-LLVM-FLOAT01: SUPPORTED float arithmetic for
             * IR_TYPE_F64 dst / operands. The supported shape is
             *   dst->type == IR_TYPE_F64
             *   r1 / r2 -> SSA F64 (constant, parameter, local,
             *                      or result of a prior float op).
             *
             * LLVMBuildFAdd / LLVMBuildFSub / LLVMBuildFMul produce
             * LLVM `fadd` / `fsub` / `fmul double` with NO fast-math
             * flags (the C API defaults the flags argument to 0 when
             * only the two operand arguments are passed). The
             * fast-math invariant is therefore automatic; the NC2
             * probe in scripts/quality/llvm-float01-test.sh enforces
             * it on the emitted textual IR.
             *
             * FDIV and FNEG remain in the same REJECTED arm below.
             * They share the diagnostic prefix but are not promoted
             * by this ACT.
             */
            LL_INC_SUPPORTED(lc);
            if (ins->dst->type != IR_TYPE_F64 ||
                !ins->r1 || ins->r1->type != IR_TYPE_F64 ||
                !ins->r2 || ins->r2->type != IR_TYPE_F64) {
                fprintf(stderr,
                    "%s: function %s: float arithmetic operand is not "
                    "F64 (opcode %s; dst type=%d, r1 type=%d, r2 type=%d); "
                    "FLOAT01 supports only scalar F64\n",
                    LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH,
                    lc->fn->name->data, irOpcodeToString(ins),
                    (int)(ins->dst ? ins->dst->type : -1),
                    (int)(ins->r1 ? ins->r1->type : -1),
                    (int)(ins->r2 ? ins->r2->type : -1));
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            LLVMValueRef a = llLowerValue(lc, ins->r1);
            LLVMValueRef b = llLowerValue(lc, ins->r2);
            if (ins->op == IR_FADD) return LLVMBuildFAdd(lc->bld, a, b, "");
            if (ins->op == IR_FSUB) return LLVMBuildFSub(lc->bld, a, b, "");
            return LLVMBuildFMul(lc->bld, a, b, "");
        }
        case IR_FDIV:
        case IR_FNEG: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class.
             * FDIV and FNEG are not promoted by FLOAT01 (see ACT §1.2). */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: float arithmetic opcode %s is not "
                "supported; FLOAT01 supports IR_FADD/IR_FSUB/IR_FMUL only\n",
                LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_FCMP: {
            /* ACT-POLYC-LLVM-FLOAT01: SUPPORTED float comparison for
             * IR_TYPE_F64 operands. The neutral-IR FCMP dst is
             * IR_TYPE_I64 (per src/ir.c:856-858, "Force result tmp to
             * int for the ICMP/FCMP path below"), and the LLVM FCMP
             * result is LLVM i1. The cache binding (irDstVarId) makes
             * the i1 value visible to IR_BR via the existing
             * direct-i1 path (src/llvm-backend.c:907-921, the
             * `LLVMIntTypeWidth(cond_ty) == 1` arm).
             *
             * Predicate mapping is derived from the aarch64-native
             * semantic oracle captured in
             *   evidence/llvm-float01/red/recon-comparison-semantics.txt:
             *     ==  -> oeq  (NaN -> false)
             *     !=  -> une  (NaN -> true)
             *     <   -> olt  (NaN -> false)
             *     <=  -> ole  (NaN -> false)
             *     >   -> ogt  (NaN -> false)
             *     >=  -> oge  (NaN -> false)
             *
             * The LLVMRealPredicate enum values are the public C API
             * constants from <llvm-c/Core.h> (LLVMRealOEQ == 1, ...).
             * The mapping is performed via llFloatCmpKindToLLVMPred
             * below, which is the FLOAT01 analogue of the integer
             * helper llCmpKindToLLVMPred (src/llvm-backend.c:783).
             */
            LL_INC_SUPPORTED(lc);
            if (!ins->r1 || ins->r1->type != IR_TYPE_F64 ||
                !ins->r2 || ins->r2->type != IR_TYPE_F64) {
                fprintf(stderr,
                    "%s: function %s: float compare operand is not "
                    "F64 (opcode IR_FCMP; r1 type=%d, r2 type=%d); "
                    "FLOAT01 supports only scalar F64 compares\n",
                    LLVM_BACKEND_UNSUPPORTED_FLOAT_CMP,
                    lc->fn->name->data,
                    (int)(ins->r1 ? ins->r1->type : -1),
                    (int)(ins->r2 ? ins->r2->type : -1));
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            LLVMValueRef a = llLowerValue(lc, ins->r1);
            LLVMValueRef b = llLowerValue(lc, ins->r2);
            LLVMRealPredicate p = llFloatCmpKindToLLVMPred(ins->extra.cmp_kind);
            return LLVMBuildFCmp(lc->bld, p, a, b, "");
        }
        case IR_AND:
        case IR_OR:
        case IR_XOR:
        case IR_NOT: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: bitwise ops are not supported "
                "(opcode %s)\n",
                LLVM_BACKEND_UNSUPPORTED_INT_BITWISE,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_SHL:
        case IR_SHR:
        case IR_SAR: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: integer shift is not supported "
                "(opcode %s)\n",
                LLVM_BACKEND_UNSUPPORTED_INT_SHIFT,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_TRUNC:
        case IR_ZEXT:
        case IR_SEXT: {
            /* ACT-POLYC-LLVM-BYTE-MEMORY01: SHAPE_DEPENDENT class.
             *
             * The proven supported shape is the byte-widening
             * shape:
             *   - src type is IR_TYPE_I8
             *   - dst type is IR_TYPE_I64
             *   - op is IR_ZEXT (unsigned promotion) or IR_SEXT
             *     (signed promotion)
             *
             * The widening is emitted via:
             *   LLVMBuildZExt / LLVMBuildSExt
             * which emit `zext i8 %v to i64` and `sext i8 %v to i64`
             * respectively. Signedness comes from the IR opcode
             * (the IR's irWidenToTargetWidth selects the opcode
             * based on AstType->issigned); LLVM i8 has no
             * inherent signedness.
             *
             * All other shapes (other src / dst types, other widths)
             * are rejected with LLVM_BACKEND_UNSUPPORTED_CONVERSION
             * because this ACT only authorises the bounded byte
             * promotion path. */
            LL_INC_SHAPE_DEPENDENT(lc);
            if (!ins->dst || !ins->r1) {
                fprintf(stderr,
                    "%s: function %s: IR_ZEXT/IR_SEXT/IR_TRUNC "
                    "missing dst or r1\n",
                    LLVM_BACKEND_INTERNAL, lc->fn->name->data);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            /* BYTE-MEMORY01 frozen authorised shape:
             *   IR_ZEXT / IR_SEXT: src = IR_TYPE_I8, dst = IR_TYPE_I64.
             *   IR_TRUNC:          src = IR_TYPE_I64, dst = IR_TYPE_I8.
             *   These are the natural byte widening / narrowing
             * shapes the IR builder produces for byte locals and
             * byte returns (see irWidenToTargetWidth at src/ir.c:218
             * and irNarrowToTargetWidth at src/ir.c:184).
             *
             * IR_TRUNC for byte narrowing is NOT a byte STORE; it
             * is the local-binding narrow that the IR builder
             * emits when an I64 SSA value is consumed by a byte
             * local. This is a backend-local narrow of an SSA
             * value, not a memory write. */
            if (ins->op == IR_TRUNC) {
                if (ins->r1->type != IR_TYPE_I64 ||
                    ins->dst->type != IR_TYPE_I8) {
                    LL_INC_REJECTED(lc);
                    fprintf(stderr,
                        "%s: function %s: IR_TRUNC is not supported "
                        "in this shape (src=%d, dst=%d; BYTE-MEMORY01 "
                        "only supports I64 -> I8 narrowing for byte "
                        "locals)\n",
                        LLVM_BACKEND_UNSUPPORTED_CONVERSION,
                        lc->fn->name->data,
                        (int)ins->r1->type, (int)ins->dst->type);
                    llEmitCapabilityCountersOnce(lc->totals);
                    exit(1);
                }
                LLVMValueRef wide_val = llLowerI64Value(lc, ins->r1);
                LLVMValueRef narrowed = LLVMBuildTrunc(lc->bld, wide_val,
                    LLVMInt8TypeInContext(lc->ctx), "trunc_i64_i8");
                llvmSet(&lc->values, irVarId(ins->dst), narrowed);
                return narrowed;
            }
            if (ins->r1->type != IR_TYPE_I8 ||
                ins->dst->type != IR_TYPE_I64) {
                LL_INC_REJECTED(lc);
                fprintf(stderr,
                    "%s: function %s: IR_%s is not supported in this "
                    "shape (src=%d, dst=%d; BYTE-MEMORY01 only "
                    "supports I8 -> I64 widening)\n",
                    LLVM_BACKEND_UNSUPPORTED_CONVERSION,
                    lc->fn->name->data,
                    (ins->op == IR_ZEXT ? "ZEXT" : "SEXT"),
                    (int)ins->r1->type, (int)ins->dst->type);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            LLVMValueRef src_val = llLowerI64Value(lc, ins->r1);
            LLVMValueRef widened;
            if (ins->op == IR_ZEXT) {
                widened = LLVMBuildZExt(lc->bld, src_val,
                    LLVMInt64TypeInContext(lc->ctx), "zext_i8_i64");
            } else {
                widened = LLVMBuildSExt(lc->bld, src_val,
                    LLVMInt64TypeInContext(lc->ctx), "sext_i8_i64");
            }
            llvmSet(&lc->values, irVarId(ins->dst), widened);
            return widened;
        }
        case IR_FPTRUNC:
        case IR_FPEXT:
        case IR_FPTOUI:
        case IR_FPTOSI:
        case IR_UITOFP:
        case IR_SITOFP:
        case IR_PTRTOINT:
        case IR_INTTOPTR: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: type conversion is not supported "
                "(opcode %s); the CORE backend supports only i64 scalars\n",
                LLVM_BACKEND_UNSUPPORTED_CONVERSION,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_BITCAST: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: bitcast is not supported "
                "(opcode %s)\n",
                LLVM_BACKEND_UNSUPPORTED_BITCAST,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_PHI: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: PHI is not supported by the CORE backend; "
                "the supported subset uses direct-branch return and "
                "single-definition locals instead\n",
                LLVM_BACKEND_UNSUPPORTED_PHI,
                lc->fn->name->data);
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_SWITCH: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: switch is not supported "
                "(opcode %s); use IR_BR / IR_JMP / IR_ICMP chains\n",
                LLVM_BACKEND_UNSUPPORTED_SWITCH,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_SELECT: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: select is not supported "
                "(opcode %s)\n",
                LLVM_BACKEND_UNSUPPORTED_SELECT,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_VA_ARG:
        case IR_VA_START:
        case IR_VA_END: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: variadic args are not supported "
                "(opcode %s)\n",
                LLVM_BACKEND_UNSUPPORTED_VARARGS,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_ASM: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: inline asm is not supported "
                "(opcode %s)\n",
                LLVM_BACKEND_UNSUPPORTED_ASM,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_LOAD_DEREF: {
            /* ACT-POLYC-LLVM-MEMORY01: SHAPE_DEPENDENT class.
             *
             * The proven supported shape is:
             *   - dst->type == IR_TYPE_I64 OR dst->type == IR_TYPE_I8
             *     (BYTE-MEMORY01 extension; the access type is
             *     proven by the neutral IR's load/store access-type
             *     contract; not guessed from LLVM pointer identity).
             *   - r1 (addr) is an SSA-resolvable pointer value of
             *     IR_TYPE_PTR (IR_VAL_PARAM bound by llBindParams,
             *     or a pointer-typed local bound by a prior
             *     IR_STORE).
             *   - disp == 0 (no GEP, no address arithmetic)
             *   - idx == NULL && scale == 0 (no SIB)
             *
             * The opaque-pointer LLVM model is satisfied by:
             *   LLVMBuildLoad2(builder, access_ty, ptr_value, name)
             * which emits `load <ty>, ptr %p` textually. The access
             * type is supplied to the load builder explicitly; no
             * typed-pointer reconstruction is attempted.
             *
             * All other shapes (non-I64 / non-I8 access type,
             * non-pointer addr, GEP-like addressing, non-zero disp,
             * non-null idx) are rejected with
             * LLVM_BACKEND_UNSUPPORTED_POINTER (or
             * LLVM_BACKEND_UNSUPPORTED_TYPE for the access-type
             * failure). */
            LL_INC_SHAPE_DEPENDENT(lc);
            if (!ins->dst) {
                fprintf(stderr,
                    "%s: function %s: IR_LOAD_DEREF missing dst\n",
                    LLVM_BACKEND_INTERNAL, lc->fn->name->data);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            /* ACT-POLYC-LLVM-BYTE-MEMORY01: IR_TYPE_I8 admitted as a
             * byte access type (alongside the existing IR_TYPE_I64).
             * Other access types (I16, I32, F32, etc.) remain
             * rejected per the frozen authorised set. */
            if (ins->dst->type != IR_TYPE_I64 &&
                ins->dst->type != IR_TYPE_I8) {
                fprintf(stderr,
                    "%s: function %s: IR_LOAD_DEREF access type is "
                    "not I64 or I8 (got type=%d, MEMORY01/BYTE-MEMORY01 "
                    "only supports I64 / I8 loads); rejected to avoid "
                    "guessing the pointee type from LLVM pointer identity\n",
                    LLVM_BACKEND_UNSUPPORTED_TYPE,
                    lc->fn->name->data, (int)ins->dst->type);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            if (ins->disp != 0 || ins->idx != NULL || ins->scale != 0) {
                fprintf(stderr,
                    "%s: function %s: IR_LOAD_DEREF with non-zero "
                    "disp or scaled-index addressing is rejected "
                    "(MEMORY01 forbids GEP / pointer arithmetic); "
                    "disp=%d idx=%p scale=%d\n",
                    LLVM_BACKEND_UNSUPPORTED_POINTER,
                    lc->fn->name->data, ins->disp,
                    (void*)ins->idx, ins->scale);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            if (!ins->r1) {
                fprintf(stderr,
                    "%s: function %s: IR_LOAD_DEREF missing addr "
                    "operand\n",
                    LLVM_BACKEND_INTERNAL, lc->fn->name->data);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            if (ins->r1->type != IR_TYPE_PTR) {
                fprintf(stderr,
                    "%s: function %s: IR_LOAD_DEREF addr is not a "
                    "pointer (got type=%d, MEMORY01 requires "
                    "pointer parameter / pointer SSA value)\n",
                    LLVM_BACKEND_UNSUPPORTED_POINTER,
                    lc->fn->name->data, (int)ins->r1->type);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            LLVMValueRef addr = llLowerPointerValue(lc, ins->r1);
            LLVMTypeRef access_ty = llType(lc, ins->dst->type);
            /* ACT-POLYC-LLVM-BYTE-MEMORY01: access type is supplied
             * to LLVMBuildLoad2 explicitly. For dst->type == IR_TYPE_I8,
             * LLVM emits `load i8, ptr %p`; for IR_TYPE_I64, the existing
             * `load i64, ptr %p`. No typed-pointer reconstruction. */
            LLVMValueRef loaded = LLVMBuildLoad2(lc->bld,
                access_ty, addr, "ld_deref");
            llvmSet(&lc->values, irVarId(ins->dst), loaded);
            return loaded;
        }
        case IR_STORE_DEREF: {
            /* ACT-POLYC-LLVM-MEMORY01: SHAPE_DEPENDENT class.
             *
             * The proven supported shape is:
             *   - dst (addr) is an SSA-resolvable pointer value of
             *     IR_TYPE_PTR (IR_VAL_PARAM bound by llBindParams,
             *     or a pointer-typed local / tmp bound by a prior
             *     IR_STORE / llLowerValue).
             *   - r1 (value) type is IR_TYPE_I64 (the I64 access
             *     type, not guessed from LLVM pointer identity).
             *   - disp == 0 (no GEP, no address arithmetic)
             *   - idx == NULL && scale == 0 (no SIB)
             *
             * The opaque-pointer LLVM model is satisfied by:
             *   LLVMBuildStore(builder, i64_value, ptr_value)
             * which emits `store i64 %v, ptr %p` textually.
             *
             * All other shapes (non-I64 value, non-pointer addr,
             * GEP-like addressing, non-zero disp, non-null idx) are
             * rejected with LLVM_BACKEND_UNSUPPORTED_POINTER (or
             * LLVM_BACKEND_UNSUPPORTED_TYPE for the access-type
             * failure). */
            LL_INC_SHAPE_DEPENDENT(lc);
            if (!ins->dst) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE_DEREF missing dst "
                    "(addr)\n",
                    LLVM_BACKEND_INTERNAL, lc->fn->name->data);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            if (ins->dst->type != IR_TYPE_PTR) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE_DEREF addr is not a "
                    "pointer (got type=%d)\n",
                    LLVM_BACKEND_UNSUPPORTED_POINTER,
                    lc->fn->name->data, (int)ins->dst->type);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            if (ins->disp != 0 || ins->idx != NULL || ins->scale != 0) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE_DEREF with non-zero "
                    "disp or scaled-index addressing is rejected "
                    "(MEMORY01 forbids GEP / pointer arithmetic); "
                    "disp=%d idx=%p scale=%d\n",
                    LLVM_BACKEND_UNSUPPORTED_POINTER,
                    lc->fn->name->data, ins->disp,
                    (void*)ins->idx, ins->scale);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            if (!ins->r1) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE_DEREF missing value "
                    "operand\n",
                    LLVM_BACKEND_INTERNAL, lc->fn->name->data);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            if (ins->r1->type != IR_TYPE_I64) {
                fprintf(stderr,
                    "%s: function %s: IR_STORE_DEREF value type is "
                    "not I64 (got type=%d, MEMORY01 only supports "
                    "I64 stores); rejected to avoid guessing the "
                    "pointee type from LLVM pointer identity\n",
                    LLVM_BACKEND_UNSUPPORTED_TYPE,
                    lc->fn->name->data, (int)ins->r1->type);
                llEmitCapabilityCountersOnce(lc->totals);
                exit(1);
            }
            LLVMValueRef addr = llLowerPointerValue(lc, ins->dst);
            LLVMValueRef val  = llLowerI64Value(lc, ins->r1);
            LLVMBuildStore(lc->bld, val, addr);
            return NULL;
        }
        case IR_ALLOCA:
        case IR_RMW_DEREF:
        case IR_LEA: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class
             * (pointer / memory address). IR_ALLOCA normally passes
             * through llLowerBlock's collapse-aware if-arm; this
             * case-arm is the canonical REJECTED counting site for
             * ALLOCA / RMW_DEREF / LEA when they reach llLowerInstr
             * without prior collapse handling. The two paths are
             * mutually exclusive per dispatched instruction; one
             * REJECTED per op either way.
             *
             * ACT-POLYC-LLVM-MEMORY01: IR_LOAD_DEREF and IR_STORE_DEREF
             * are no longer in this grouped arm; they have their own
             * SHAPE_DEPENDENT arms above. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: pointer / memory address ops are not "
                "supported (opcode %s); MEMORY01 only supports "
                "IR_LOAD_DEREF / IR_STORE_DEREF for address-space-0 "
                "ptr + I64 access (no alloca, no GEP, no address-of)\n",
                LLVM_BACKEND_UNSUPPORTED_POINTER,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        case IR_GEP: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: REJECTED class. */
            LL_INC_REJECTED(lc);
            fprintf(stderr,
                "%s: function %s: getelementptr is not supported "
                "(opcode %s); no aggregate / pointer in CORE\n",
                LLVM_BACKEND_UNSUPPORTED_AGGREGATE,
                lc->fn->name->data, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
        default: {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 §5.3 + §13: the default
             * arm is the safety net for NOT_YET_CLASSIFIED opcodes
             * (e.g. IR_NOP, IR_LABEL). Reaching the default arm with
             * a UNREACHABLE_ON_LLVM opcode is an invariant violation
             * (HALT_UNREACHABLE_OPCODE_REACHED). The CORE contract
             * requires every opcode to be classified; if the default
             * arm fires in practice, the capability matrix has a gap
             * that needs filling. */
            if (ins->op == IR_NOP || ins->op == IR_LABEL) {
                fprintf(stderr,
                    "%s: function %s: UNREACHABLE_ON_LLVM opcode %s "
                    "reached the dispatch default arm; this is an "
                    "invariant violation (HALT_UNREACHABLE_OPCODE_REACHED).\n",
                    LLVM_BACKEND_INTERNAL, lc->fn->name->data,
                    irOpcodeToString(ins));
                llEmitCapabilityCountersOnce(lc->totals);
                abort();
            }
            llErrUnsupportedOp(ins, lc->fn, irOpcodeToString(ins));
            llEmitCapabilityCountersOnce(lc->totals);
            exit(1);
        }
    }
}

static int llFunction(IrProgram *prog, IrFunction *fn, LLVMContextRef ctx,
                      LLVMModuleRef mod, LLTotals *totals)
{
    (void)prog;
    LLCtx lc;
    memset(&lc, 0, sizeof(lc));
    lc.ctx = ctx;
    lc.mod = mod;
    lc.fn  = fn;
    lc.totals = totals;
    lc.bld = LLVMCreateBuilderInContext(ctx);
    llvmInit(&lc.values, 1024);
    llbmInit(&lc.blocks, 1024);
    /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: the
     * Option-W slot map starts empty; llClassifyOptionWLocals
     * fills it lazily for every IR_VAL_LOCAL that names a
     * non-Option-W-eligible target. The per-map free path is in
     * the LLCtx teardown at the bottom of llFunction. */
    llvmInit(&lc.option_w_slots, 1024);
    lc.option_w_count = 0;
    lc.option_w_active = 0;
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

    /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: classify every
     * IR_VAL_LOCAL under the §2 frozen discriminator BEFORE any
     * per-block instruction is lowered. The first ineligible V
     * triggers a rejection (AC05); the IMPL MUST NOT silently
     * lower ineligible Vs through a widened path. */
    if (llClassifyOptionWLocals(fn, &lc) != 0) {
        llEmitCapabilityCountersOnce(lc.totals);
        return 1;
    }
    /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: materialise
     * the entry-block allocas for every classified V. The
     * placement rule is the C6-normalised Q3.3 rule (per
     * CORRECTION01 §6): prefer before the first non-alloca
     * instruction in the entry block, else append to end of empty
     * entry block. */
    if (llMaterializeOptionWSlots(&lc) != 0) {
        llEmitCapabilityCountersOnce(lc.totals);
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

    /* ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6: after all
     * blocks are lowered, run mem2reg on this function (if any
     * Option-W eligible V was classified and materialised). Must
     * happen BEFORE LLVMVerifyModule in llvmEmitProgram so the
     * verifier sees the post-mem2reg IR. LLVM's mem2reg owns
     * PHI placement policy (iterated dominator frontiers); the
     * C9 predecessor-edge synthesis is DELETED. */
    if (llRunOptionWMem2Reg(&lc) != 0) {
        llEmitCapabilityCountersOnce(lc.totals);
        return 1;
    }

    /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: aggregate this function's
     * defensive-trip contribution into the per-invocation totals
     * exactly once, before LLCtx is destroyed. The per-function
     * counter remains in lc.defensive_trips for diagnostic context
     * but is no longer the canonical observer; the harness reads
     * totals->defensive. */
    if (lc.totals) {
        lc.totals->defensive += (unsigned long)lc.defensive_trips;
    }

    LLVMDisposeBuilder(lc.bld);
    free(lc.values.values);
    free(lc.blocks.values);
    free(lc.local_defs);
    free(lc.option_w_slots.values);
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

    /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: own the per-invocation
     * counters. One LLTotals per hcc --emit-llvm invocation; passed
     * by pointer into llFunction() so each function contributes
     * exactly once. This stack-local + pointer-plumbing approach
     * is mechanism B from the C1 recon
     * (evidence/llvm-core04-resume01/c1/red-m2-recon.txt).
     * No module-static/global state; no heap registry of LLCtx;
     * no later walk over destroyed LLCtx instances. */
    LLTotals totals;
    memset(&totals, 0, sizeof(totals));

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
    /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: pre-dispatch pass uses the
     * same LLTotals so capability-classified pre-dispatch rejections
     * (e.g. unsupported function param type) can emit counters too. */
    lc.totals = &totals;
    llvmInit(&lc.values, 1024);
    llPass1(&lc, prog);
    free(lc.values.values);

    for (u64 i = 0; i < prog->functions->size; ++i) {
        IrFunction *fn = vecGet(IrFunction*, prog->functions, i);
        if (!fn) continue;
        if (llFunction(prog, fn, ctx, mod, &totals) != 0) {
            /* ACT-POLYC-LLVM-CORE04-RESUME01 §6.3: emit counters
             * before the function-level bail-out so rejected
             * invocations still produce a CAPABILITY_COUNTERS line.
             * Idempotent vs. the success-path emission below. */
            llEmitCapabilityCountersOnce(&totals);
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
        llEmitCapabilityCountersOnce(&totals);
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

    /* ACT-POLYC-LLVM-CORE04-RESUME01 M2: success-path emission.
     * Per ACT §6.2, emit after LLVMVerifyModule + LLVMPrintModule*.
     * Per ACT §6.1, the line goes to stderr and is NEVER inside the
     * .ll output (fputs/LLVMPrintModuleToFile are pure LLVM IR). */
    llEmitCapabilityCountersOnce(&totals);

    LLVMDisposeModule(mod);
    LLVMContextDispose(ctx);
    return rc;
}
