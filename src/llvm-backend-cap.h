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

#endif /* LLVM_BACKEND_CAP_H */
