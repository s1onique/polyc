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
#include <string.h>

/* ACT-POLYC-LLVM-CORE04-RESUME01 M2: capability-counter side channel.
 *
 * The helper is the single writer of the CAPABILITY_COUNTERS line. It
 * is idempotent per LLTotals instance via the `emitted` flag, so the
 * driver may call it once on the success path AND backend-owned
 * terminating REJECTED paths may also call it before their existing
 * exit(1) without producing a second line. Per ACT §6.1, the line
 * is written to STDERR (not into the .ll output file); per ACT §6.2,
 * one physical line per hcc --emit-llvm invocation that reached the
 * backend; per ACT §5.3, unreachable is hard-coded to 0.
 *
 * No malloc, no file handles, no path components. The format is
 *   CAPABILITY_COUNTERS supported=<N> rejected=<N> shape_dependent=<N> defensive=<N> unreachable=0
 * Each field is ASCII decimal; no whitespace other than single spaces
 * between fields; trailing newline at end. */
void llEmitCapabilityCountersOnce(LLTotals *totals) {
    if (!totals || totals->emitted) return;
    totals->emitted = 1;
    fprintf(stderr,
        "CAPABILITY_COUNTERS supported=%lu rejected=%lu "
        "shape_dependent=%lu defensive=%lu unreachable=0\n",
        totals->supported,
        totals->rejected,
        totals->shape_dependent,
        totals->defensive);
}

const LLVMBackendCapabilityDef kLLVMBackendCapability[] = {
    { IR_NOP, LLVMBC_UNREACHABLE_ON_LLVM, NULL, "irRemoveAllNops strips every IR_NOP node before emission; no explicit `case IR_NOP:` arm; the generic `default:` arm catches a future regression and emits LLVM_BACKEND_UNSUPPORTED_IR." },
    { IR_ALLOCA, LLVMBC_REJECTED, LLVM_BACKEND_UNSUPPORTED_POINTER, "LLVM_BACKEND_UNSUPPORTED_POINTER (IR_ALLOCA is grouped with IR_LOAD_DEREF/IR_STORE_DEREF/IR_RMW_DEREF/IR_LEA in the dispatch; the grouped arm emits POINTER, not MEMORY. The MEMORY macro name was a historical misnomer; corrected by ACT-POLYC-LLVM-CORE03-CORRECTION02 M2.)" },
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
    { IR_CMP_BR, LLVMBC_REJECTED, LLVM_BACKEND_INTERNAL, "LLVM_BACKEND_INTERNAL (boundary violation - native fusion; the IR_CMP_BR handler in src/llvm-backend.c emits LLVM_BACKEND_INTERNAL because reaching this arm means the neutral/native boundary has been crossed. The previous table entry had a descriptive string that did not match any macro in the dispatch; corrected by ACT-POLYC-LLVM-CORE03-CORRECTION02 M2.)" },
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
        /* ACT-POLYC-LLVM-CORE03-CORRECTION02 M1: length-delimited
         * wire format. Each variable-length field is prefixed with
         * its byte length in ASCII decimal, then a tab. The parser
         * reads len bytes for that field, regardless of content.
         *
         * Format per row:
         *   <op-ordinal>\t<class-ordinal>\t<diag-len>\t<diag>\t<note-len>\t<note>\n
         *
         * This is round-trippable byte-for-byte (verified by the
         * Python verifier's round-trip test). The previous format
         * was space-delimited and truncated IR_CMP_BR's diagnostic
         * `"(boundary violation - native fusion)"` to `"(boundary"`. */
        /* ACT-POLYC-LLVM-CORE03-CORRECTION05 M3: NULL-sentinel contract.
         *
         * The wire format reserves the single byte sequence "-"
         * (length 1) as the NULL sentinel for both diag and note.
         * A legitimate diagnostic or note whose contents are
         * exactly the ASCII character "-" cannot be represented
         * distinctly from NULL on the wire. This is an inherent
         * value-collision in the current protocol and is
         * documented as a contract limitation. The two
         * reasonable fixes (length=-1 sentinel, or a separate
         * presence flag column) require a wire-format change and
         * are deferred; see CORRECTION05 Residue. */
        const char *diag = row->diagnostic ? row->diagnostic : "-";
        const char *note = row->note ? row->note : "-";
        printf("%d\t%d\t%zu\t%s\t%zu\t%s\n",
               (int)row->op,
               (int)row->class_,
               strlen(diag), diag,
               strlen(note), note);
    }
}
