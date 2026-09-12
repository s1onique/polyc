/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3.1 RED mechanical witness.
 *
 * NOT part of hcc. Standalone one-shot evidence tool linked against
 * LLVM 22 C API. Prints the LLVMTypeOf three values that would be
 * passed to LLVMAddIncoming in the proposed C4 PHI dispatch arm:
 *
 *   (1) a constant "1" of neutral type IR_TYPE_I8
 *       (= llType(IR_TYPE_I8) = LLVMInt8TypeInContext)
 *   (2) an LLVMBuildICmp result (= the value cached by the IR_ICMP
 *       dispatch arm at src/llvm-backend.c:2582-2598)
 *   (3) a wider "1" of neutral type IR_TYPE_I64 (control witness
 *       for the llType(IR_TYPE_I64) == LLVMInt64Type mapping)
 *
 * For each value, print:
 *   LLVMTypeOf  -> integer width in bits
 *   name        -> "iN" (LLVM's printable type name)
 *
 * The verdict line at the end is the literal text the ACT needs.
 *
 * Build:
 *   cc -o /tmp/c31-witness witness.c $(llvm-config --cflags --libs core --ldflags)
 *   /tmp/c31-witness
 */
#include <llvm-c/Core.h>
#include <stdio.h>
#include <stdlib.h>

static const char *type_name(LLVMTypeRef t) {
    if (!t) return "(null)";
    if (LLVMGetTypeKind(t) != LLVMIntegerTypeKind) return "(non-int)";
    char *s = LLVMPrintTypeToString(t);
    const char *r = s;
    /* strip trailing whitespace */
    static char buf[16];
    int i = 0;
    while (r[i] && r[i] != '\n' && i < 15) { buf[i] = r[i]; i++; }
    buf[i] = 0;
    LLVMDisposeMessage(s);
    return buf;
}

int main(void) {
    LLVMContextRef ctx = LLVMContextCreate();
    LLVMModuleRef mod  = LLVMModuleCreateWithNameInContext("c31_witness", ctx);
    LLVMBuilderRef bld = LLVMCreateBuilderInContext(ctx);
    LLVMBasicBlockRef bb = LLVMAppendBasicBlock(
        LLVMAddFunction(mod, "f",
            LLVMFunctionType(LLVMVoidTypeInContext(ctx), NULL, 0, 0)),
        "entry");
    LLVMPositionBuilderAtEnd(bld, bb);

    /* (1) IR_VAL_CONST_INT 1 of neutral type IR_TYPE_I8
     *     = llLowerValue -> LLVMConstInt(llType(IR_TYPE_I8), 1, 1)
     *     = LLVMConstInt(LLVMInt8TypeInContext(ctx), 1, 1)            */
    LLVMValueRef c_i8 = LLVMConstInt(LLVMInt8TypeInContext(ctx), 1, 1);

    /* (3) IR_VAL_CONST_INT 1 of neutral type IR_TYPE_I64 (control)    */
    LLVMValueRef c_i64 = LLVMConstInt(LLVMInt64TypeInContext(ctx), 1, 1);

    /* (2) Result of LLVMBuildICmp = the value cached at IR_ICMP dst
     *     (per src/llvm-backend.c:2582-2598; always returns i1).
     *     Use 64-bit operands (the dominant PolyC IR_TYPE_I64 shape;
     *     i8-pair narrowing feeds the same icmp op and yields the
     *     same i1 type).                                                  */
    LLVMValueRef a = LLVMConstInt(LLVMInt64TypeInContext(ctx), 7, 1);
    LLVMValueRef b = LLVMConstInt(LLVMInt64TypeInContext(ctx), 3, 1);
    LLVMValueRef cmp_i1 = LLVMBuildICmp(bld, LLVMIntSGT, a, b, "cmp");

    /* Report. */
    LLVMTypeRef t_c_i8  = LLVMTypeOf(c_i8);
    LLVMTypeRef t_c_i64 = LLVMTypeOf(c_i64);
    LLVMTypeRef t_cmp   = LLVMTypeOf(cmp_i1);

    unsigned w_c_i8  = LLVMGetIntTypeWidth(t_c_i8);
    unsigned w_c_i64 = LLVMGetIntTypeWidth(t_c_i64);
    unsigned w_cmp   = LLVMGetIntTypeWidth(t_cmp);

    printf("PHI_INCOMING_TYPE_WITNESS (LLVM 22 C API; c31.1 RED)\n");
    printf("\n");
    printf("Value                                    LLVMTypeOf  width  name\n");
    printf("---------------------------------------  ----------  -----  ----\n");
    printf("(1) constant '1' (IR_TYPE_I8)            i%-9u  %-5u  %s\n",
           w_c_i8, w_c_i8, type_name(t_c_i8));
    printf("(2) LLVMBuildICmp result (IR_ICMP dst)   i%-9u  %-5u  %s\n",
           w_cmp, w_cmp, type_name(t_cmp));
    printf("(3) constant '1' (IR_TYPE_I64) [control] i%-9u  %-5u  %s\n",
           w_c_i64, w_c_i64, type_name(t_c_i64));

    printf("\n");
    printf("EXPECTED_PHI_TYPE_FROM_NEUTRAL = i8 (per ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3 frozen matrix)\n");
    printf("\n");
    printf("VERDICT:\n");
    if (w_c_i8 == 8 && w_cmp == 1 && w_c_i64 == 64) {
        printf("  OUTCOME_B_CONFIRMED\n");
        printf("  - incoming constant '1' (IR_TYPE_I8) lowers to LLVM i8 (width 8)\n");
        printf("  - incoming IR_ICMP dst lowers to LLVM i1 (width 1)  <-- MISMATCH\n");
        printf("  - incoming constant '1' (IR_TYPE_I64) lowers to LLVM i64 (width 64)\n");
        printf("\n");
        printf("  Consequence for C4 IR_PHI dispatch arm:\n");
        printf("    - LLVMBuildPHI(LLVMInt8TypeInContext(ctx), \"\")  -> i8 PHI\n");
        printf("    - LLVMAddIncoming for the constant edge          -> OK (i8 == i8)\n");
        printf("    - LLVMAddIncoming for the IR_ICMP edge           -> REJECTED\n");
        printf("      by the LLVM verifier (incoming value i1 does\n");
        printf("      not match PHI type i8).\n");
        printf("\n");
        printf("  Required bounded conversion contract (Outcome B):\n");
        printf("    For incoming edges whose producer opcode is\n");
        printf("    IR_ICMP, insert:\n");
        printf("        LLVMValueRef z = LLVMBuildZExt(\n");
        printf("            lc->bld, incoming, LLVMInt8TypeInContext(lc->ctx),\n");
        printf("            \"phi_icmp_zext\");\n");
        printf("    then pass z to LLVMAddIncoming. This conversion\n");
        printf("    is correct because the IR_ICMP result is already\n");
        printf("    canonically 0 or 1 (per IR_BR dispatch contract,\n");
        printf("    src/llvm-backend.c:1815-1853, which has been the\n");
        printf("    runtime witness for i1 correctness since CORRECTION01).\n");
        printf("\n");
        printf("  Scope impact: ZERO new diagnostic macros, ZERO new\n");
        printf("  counters, ONE additional builder call inside the new\n");
        printf("  IR_PHI dispatch arm. The conversion is bound to the\n");
        printf("  IR_PHI dispatch arm's incoming-edge iteration, not a\n");
        printf("  general integer conversion widening.\n");
    } else {
        printf("  UNEXPECTED_TYPE_BINDING: c_i8=%u, cmp=%u, c_i64=%u\n",
               w_c_i8, w_cmp, w_c_i64);
        printf("  -> HALT_PHI_TYPE_CONTRACT_REQUIRED (Outcome D)\n");
    }

    /* Cleanup */
    LLVMDisposeBuilder(bld);
    LLVMDisposeModule(mod);
    LLVMContextDispose(ctx);
    return 0;
}
