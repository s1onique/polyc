/* src/llvm-backend-cap.h
 *
 * ACT-POLYC-LLVM-CORE03: machine-enforced capability contract.
 *
 * The capability matrix at the top of src/llvm-backend.c is a C
 * comment. CORE03 turns it into a runtime-checkable table so the
 * dispatch and the documented contract cannot drift apart.
 *
 * Every IrOp value has exactly one row in kLLVMBackendCapability[].
 * llValidateCapabilityContract() asserts the table is well-formed
 * (no gaps, no duplicates, every REJECTED row has a diagnostic,
 * every non-REJECTED row does not).
 *
 * Source-of-truth order:
 *   - The diagnostic string MUST match the corresponding
 *     LLVM_BACKEND_UNSUPPORTED_* macro in src/llvm-backend.h.
 *   - The note field is a free-form comment for the matrix; it
 *     does NOT affect runtime behaviour.
 */

#ifndef LLVM_BACKEND_CAP_H
#define LLVM_BACKEND_CAP_H

#include "ir-types.h"   /* for IrOp */

typedef enum {
    LLVMBC_SUPPORTED          = 0,
    LLVMBC_REJECTED           = 1,
    LLVMBC_SHAPE_DEPENDENT    = 2,
    LLVMBC_UNREACHABLE_ON_LLVM = 3,
    LLVMBC_DEFENSIVE_INVARIANT = 4,
} LLVMBackendCapability;

typedef struct {
    IrOp                       op;
    LLVMBackendCapability      class_;
    /* diagnostic is non-NULL iff class_ == LLVMBC_REJECTED.
     * For SHAPE_DEPENDENT, diagnostic is NULL (the SHAPE matrix
     * lives in the comment; runtime enforcement is per-shape
     * inside the dispatch itself). */
    const char                *diagnostic;
    const char                *note;
} LLVMBackendCapabilityDef;

/* The capability table. Defined in src/llvm-backend-cap.c.
 * Indexed in the SAME order as the IrOp enum (IR_NOP, IR_ALLOCA,
 * ..., IR_ASM). kLLVMBackendCapabilityCount == IR_ASM + 1. */
extern const LLVMBackendCapabilityDef kLLVMBackendCapability[];
extern const int                       kLLVMBackendCapabilityCount;

/* Runtime contract validator. Called once from src/main.c before
 * any --emit-llvm invocation. On failure, prints a diagnostic to
 * stderr and aborts via abort() (NOT exit(1)) so a debugger
 * catches the inconsistency. On success, prints
 *   "LLVM backend capability contract: ok (N rows)\n"
 * to stderr. */
void llValidateCapabilityContract(void);

/* Print the capability table to stdout, one line per row:
 *   <op-ordinal> <class-ordinal> <diagnostic-or-"-"> <name>
 * Used by build-time verifiers (scripts/quality/llvm-cap-table-verifier.py)
 * to bind dispatch <-> table <-> harness without hard-coded expectations. */
void llPrintCapabilityTable(void);

/* ACT-POLYC-LLVM-CORE04-RESUME01 M2: per-class execution counters.
 *
 * Counters describe actual dispatch activity, not capability-table
 * population. Each invocation of hcc --emit-llvm owns ONE LLTotals
 * (allocated on llvmEmitProgram()'s stack; passed by pointer into
 * llFunction() so each function contributes exactly once).
 *
 * Counting rules (see ACT-POLYC-LLVM-CORE04-RESUME01 §5.3):
 *   - SUPPORTED:        one increment per dispatched SUPPORTED op.
 *   - REJECTED:         one increment per REJECTED-class op reaching
 *                       its rejection diagnostic site. (NOT a generic
 *                       default-arm catch-all; capability-class only.)
 *   - SHAPE_DEPENDENT:  one increment at the dispatch seam, regardless
 *                       of whether the concrete shape is accepted or
 *                       rejected. Do NOT double-count a rejected
 *                       SHAPE_DEPENDENT shape as both SHAPE_DEPENDENT
 *                       and REJECTED unless the capability table says
 *                       the opcode is REJECTED.
 *   - DEFENSIVE_INVARIANT: aggregated from the existing per-function
 *                          LLCtx::defensive_trips at the end of
 *                          llFunction() (one contribution per function,
 *                          before the LLCtx is destroyed).
 *
 * UNREACHABLE_ON_LLVM is NOT a mutable execution counter; reaching
 * an UNREACHABLE opcode is itself an invariant violation
 * (HALT_UNREACHABLE_OPCODE_REACHED). The emitted field is always 0.
 *
 * The "emitted" flag is a per-invocation guard so that exactly one
 * CAPABILITY_COUNTERS line is written to stderr per invocation, even
 * if a backend-owned terminating REJECTED path calls the helper
 * before the success-only emission point is reached. */
typedef struct LLTotals {
    unsigned long supported;
    unsigned long rejected;
    unsigned long shape_dependent;
    unsigned long defensive;
    int           emitted;   /* 0 = not yet emitted; 1 = already written */
} LLTotals;

/* Emit the canonical CAPABILITY_COUNTERS line on stderr exactly once
 * per LLTotals instance. No-op if already emitted. The line format is
 *   CAPABILITY_COUNTERS supported=<N> rejected=<N> shape_dependent=<N> defensive=<N> unreachable=0
 * and is ASCII-only, no timestamps, no paths, no pointer values. */
void llEmitCapabilityCountersOnce(LLTotals *totals);

#endif /* LLVM_BACKEND_CAP_H */
