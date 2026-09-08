/* src/llvm-backend-cap.c
 *
 * ACT-POLYC-LLVM-CORE03: capability table.
 *
 * Indexed in the SAME order as the IrOp enum (IR_NOP=0 .. IR_ASM=55).
 * Source-of-truth: the matrix comment in src/llvm-backend.c.
 *
 * Notes for IR_NOP / IR_LABEL / IR_BR are overridden by
 * CORE03 §1 P1 (machine-enforced correction of CORE02's
 * "explicit REJECTED arm" closure prose bug).
 */

#include "llvm-backend-cap.h"
#include "ir-types.h"
#include "llvm-backend.h"
#include <stdio.h>
#include <stdlib.h>

const LLVMBackendCapabilityDef kLLVMBackendCapability[] = {
    { IR_NOP, LLVMBC_UNREACHABLE_ON_LLVM, NULL, "irRemoveAllNops strips every IR_NOP node before emission; no explicit `case IR_NOP:` arm; the generic `default:` arm catches a future regression and emits LLVM_BACKEND_UNSUPPORTED_IR." },
    { IR_ALLOCA, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_MEMORY, "LLVM_BACKEND_UNSUPPORTED_MEMORY" },
    { IR_LOAD, LLVMBC_SHAPE_DEPENDENT, NULL, "(see IR_LOAD below)" },
    { IR_STORE, LLVMBC_SHAPE_DEPENDENT, NULL, "(see IR_STORE below)" },
    { IR_LOAD_DEREF, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_POINTER, "LLVM_BACKEND_UNSUPPORTED_POINTER" },
    { IR_STORE_DEREF, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_POINTER, "LLVM_BACKEND_UNSUPPORTED_POINTER" },
    { IR_RMW_DEREF, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_POINTER, "LLVM_BACKEND_UNSUPPORTED_POINTER" },
    { IR_LEA, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_POINTER, "LLVM_BACKEND_UNSUPPORTED_POINTER" },
    { IR_GEP, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_AGGREGATE, "LLVM_BACKEND_UNSUPPORTED_AGGREGATE" },
    { IR_IADD, LLVMBC_SUPPORTED, NULL, "(no note)" },
    { IR_ISUB, LLVMBC_SUPPORTED, NULL, "(no note)" },
    { IR_IMUL, LLVMBC_SUPPORTED, NULL, "(no note)" },
    { IR_IDIV, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_DIVISION, "LLVM_BACKEND_UNSUPPORTED_INT_DIVISION" },
    { IR_UDIV, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_DIVISION, "LLVM_BACKEND_UNSUPPORTED_INT_DIVISION" },
    { IR_IREM, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER, "LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER" },
    { IR_UREM, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER, "LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER" },
    { IR_INEG, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_NEGATION, "LLVM_BACKEND_UNSUPPORTED_INT_NEGATION" },
    { IR_FADD, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH, "LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH" },
    { IR_FSUB, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH, "LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH" },
    { IR_FMUL, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH, "LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH" },
    { IR_FDIV, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH, "LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH" },
    { IR_FNEG, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH, "LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH" },
    { IR_AND, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_BITWISE, "LLVM_BACKEND_UNSUPPORTED_INT_BITWISE" },
    { IR_OR, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_BITWISE, "LLVM_BACKEND_UNSUPPORTED_INT_BITWISE" },
    { IR_XOR, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_BITWISE, "LLVM_BACKEND_UNSUPPORTED_INT_BITWISE" },
    { IR_SHL, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_SHIFT, "LLVM_BACKEND_UNSUPPORTED_INT_SHIFT" },
    { IR_SHR, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_SHIFT, "LLVM_BACKEND_UNSUPPORTED_INT_SHIFT" },
    { IR_SAR, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_SHIFT, "LLVM_BACKEND_UNSUPPORTED_INT_SHIFT" },
    { IR_NOT, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_INT_BITWISE, "LLVM_BACKEND_UNSUPPORTED_INT_BITWISE" },
    { IR_ICMP, LLVMBC_SUPPORTED, NULL, "(signed eq/ne/lt/le/gt/ge)" },
    { IR_FCMP, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_FLOAT_CMP, "LLVM_BACKEND_UNSUPPORTED_FLOAT_CMP" },
    { IR_TRUNC, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_ZEXT, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_SEXT, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_FPTRUNC, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_FPEXT, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_FPTOUI, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_FPTOSI, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_UITOFP, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_SITOFP, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_PTRTOINT, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_INTTOPTR, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_CONVERSION, "LLVM_BACKEND_UNSUPPORTED_CONVERSION" },
    { IR_BITCAST, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_BITCAST, "LLVM_BACKEND_UNSUPPORTED_BITCAST" },
    { IR_RET, LLVMBC_SUPPORTED, NULL, "(i64 only; via collapse-elimination)" },
    { IR_BR, LLVMBC_SUPPORTED, NULL, "SUPPORTED, but cond physical type i64 is DEFENSIVE_INVARIANT (runtime-detected via LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED when the i64 arm fires)." },
    { IR_CMP_BR, LLVMBC_REJECTED, "(boundary violation - native fusion)", "(boundary violation - native fusion)" },
    { IR_JMP, LLVMBC_SUPPORTED, NULL, "(no note)" },
    { IR_SWITCH, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_SWITCH, "LLVM_BACKEND_UNSUPPORTED_SWITCH" },
    { IR_CALL, LLVMBC_SUPPORTED, NULL, "(i64 return only)" },
    { IR_PHI, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_PHI, "LLVM_BACKEND_UNSUPPORTED_PHI" },
    { IR_LABEL, LLVMBC_UNREACHABLE_ON_LLVM, NULL, "reserved-but-unused per src/ir-types.h:155; never created by the canonical lowerer; no explicit `case IR_LABEL:` arm; the generic `default:` arm catches a future regression and emits LLVM_BACKEND_UNSUPPORTED_IR." },
    { IR_SELECT, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_SELECT, "LLVM_BACKEND_UNSUPPORTED_SELECT" },
    { IR_VA_ARG, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_VARARGS, "LLVM_BACKEND_UNSUPPORTED_VARARGS" },
    { IR_VA_START, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_VARARGS, "LLVM_BACKEND_UNSUPPORTED_VARARGS" },
    { IR_VA_END, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_VARARGS, "LLVM_BACKEND_UNSUPPORTED_VARARGS" },
    { IR_ASM, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_ASM, "LLVM_BACKEND_UNSUPPORTED_ASM" },
};

const int kLLVMBackendCapabilityCount =
    (int)(sizeof(kLLVMBackendCapability) / sizeof(kLLVMBackendCapability[0]));

void llValidateCapabilityContract(void) {
    if (kLLVMBackendCapabilityCount != IR_ASM + 1) {
        fprintf(stderr,
            "LLVM backend capability contract FAILED: table has %d rows,"
            " expected %d (IR_ASM+1).\n",
            kLLVMBackendCapabilityCount, IR_ASM + 1);
        abort();
    }
    /* ACT-POLYC-LLVM-CORE03-CORRECTION01 M1: prove that table[i] is
     * exactly the row for IrOp i (no gaps, no duplicates, no out-of-
     * range opcodes, correct ordering). This is a stronger invariant
     * than "count == IR_ASM+1 and no duplicates": an out-of-range op
     * like (IrOp)99 would have passed the old check but is caught here. */
    for (int i = 0; i < kLLVMBackendCapabilityCount; i++) {
        const LLVMBackendCapabilityDef *row = &kLLVMBackendCapability[i];
        if ((int)row->op != i) {
            fprintf(stderr,
                "LLVM backend capability contract FAILED: row %d has"
                " op=%d, expected op=%d (one row per IrOp ordinal).\n",
                i, (int)row->op, i);
            abort();
        }
        if ((int)row->op < 0 || (int)row->op > IR_ASM) {
            fprintf(stderr,
                "LLVM backend capability contract FAILED: row %d has"
                " out-of-range op=%d (must be 0..%d).\n",
                i, (int)row->op, IR_ASM);
            abort();
        }
        if (row->class_ == LLVMBC_REJECTED && row->diagnostic == NULL) {
            fprintf(stderr,
                "LLVM backend capability contract FAILED: REJECTED row %d"
                " (op=%d) has NULL diagnostic.\n", i, (int)row->op);
            abort();
        }
        if (row->class_ != LLVMBC_REJECTED
            && row->class_ != LLVMBC_SHAPE_DEPENDENT
            && row->diagnostic != NULL) {
            fprintf(stderr,
                "LLVM backend capability contract FAILED: non-REJECTED row %d"
                " (op=%d, class=%d) has non-NULL diagnostic %s.\n",
                i, (int)row->op, (int)row->class_, row->diagnostic);
            abort();
        }
    }
    fprintf(stderr,
        "LLVM backend capability contract: ok (%d rows, ordinal binding)\n",
        kLLVMBackendCapabilityCount);
}

void llPrintCapabilityTable(void) {
    for (int i = 0; i < kLLVMBackendCapabilityCount; i++) {
        const LLVMBackendCapabilityDef *row = &kLLVMBackendCapability[i];
        /* <op-ordinal> <class-ordinal> <diagnostic-or-"-"> <note> */
        printf("%d %d %s %s\n",
               (int)row->op,
               (int)row->class_,
               row->diagnostic ? row->diagnostic : "-",
               row->note ? row->note : "-");
    }
}
