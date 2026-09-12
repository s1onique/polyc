/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3.2 RED mechanical witness.
 *
 * NOT part of hcc. Standalone one-shot evidence tool linked against
 * LLVM 22 C API. Mechanically proves the C3.1 placement contract
 * is INSIDE the merge block, which would be rejected by the LLVM
 * verifier for dominance violation. Then mechanically proves the
 * CORRECT placement (in the incoming predecessor block, before
 * its terminator) is accepted.
 *
 * Two variants per LLVM module, both fed with the same icmp shape
 * (function-parameter fed so DCE/constant-folding cannot collapse
 * the incoming value):
 *
 *   variant_bad:
 *     pred:
 *       %cmp = icmp sgt i64 %x, %y
 *       br label %merge
 *     merge:
 *       %phi = phi i8 [ %z, %pred ]   ; PHI must be first per LangRef
 *       %z = zext i1 %cmp to i8        ; C3.1 mistake: zext after PHI
 *       store i8 %z, ptr @g
 *       ret void
 *
 *   variant_good:
 *     pred:
 *       %cmp = icmp sgt i64 %x, %y
 *       %phi_icmp_zext = zext i1 %cmp to i8   ; GOOD: zext in pred
 *       br label %merge                       ; before terminator
 *     merge:
 *       %phi = phi i8 [ %phi_icmp_zext, %pred ]
 *       store i8 %phi, ptr @g
 *       ret void
 *
 * Both modules are run through LLVMVerifyModule (action =
 * LLVMReturnStatusAction; the C3.1 contract is verified via the
 * LLVMBool return and the diagnostic message).
 *
 * EXPECTED:
 *   variant_bad  -> verify return = 1 (rejected)
 *                   message: "Instruction does not dominate all uses!
 *                             %z = zext i1 %cmp to i8
 *                             %phi = phi i8 [ %z, %pred ]"
 *   variant_good -> verify return = 0 (accepted)
 *
 * Build:
 *   cc -o witness witness.c $(llvm-config --cflags --libs core analysis --ldflags)
 *   ./witness
 */
#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <stdio.h>

/* Run LLVMVerifyModule on `mod` and print verifier verdict + IR.
   Returns the LLVMBool from LLVMVerifyModule. */
static LLVMBool verify_and_dump(const char *tag, LLVMModuleRef mod) {
    char *msg = NULL;
    LLVMBool bad = LLVMVerifyModule(mod, LLVMReturnStatusAction, &msg);
    printf("\n=== %s ===\n", tag);
    printf("verify return=%d (0=valid, 1=invalid)\n", (int)bad);
    if (msg) {
        printf("verifier message:\n%s", msg);
        LLVMDisposeMessage(msg);
    } else {
        printf("verifier message: (none)\n");
    }
    char *ir = LLVMPrintModuleToString(mod);
    printf("IR:\n%s\n", ir);
    LLVMDisposeMessage(ir);
    return bad;
}

/* Build variant_bad: zext inside merge block after PHI. */
static LLVMBool build_bad(LLVMContextRef ctx) {
    LLVMModuleRef mod = LLVMModuleCreateWithNameInContext("c32_bad", ctx);
    LLVMBuilderRef bld = LLVMCreateBuilderInContext(ctx);

    LLVMTypeRef i64 = LLVMInt64TypeInContext(ctx);
    LLVMTypeRef i8  = LLVMInt8TypeInContext(ctx);
    LLVMValueRef g = LLVMAddGlobal(mod, i8, "g");
    LLVMSetInitializer(g, LLVMConstInt(i8, 0, 0));
    LLVMSetLinkage(g, LLVMExternalLinkage);

    /* void f(i64 %x, i64 %y) */
    LLVMTypeRef fty = LLVMFunctionType(LLVMVoidTypeInContext(ctx),
        (LLVMTypeRef[]){ i64, i64 }, 2, 0);
    LLVMValueRef fn = LLVMAddFunction(mod, "f", fty);
    LLVMValueRef arg_x = LLVMGetParam(fn, 0);
    LLVMValueRef arg_y = LLVMGetParam(fn, 1);
    LLVMSetValueName(arg_x, "x");
    LLVMSetValueName(arg_y, "y");

    LLVMBasicBlockRef pred  = LLVMAppendBasicBlock(fn, "pred");
    LLVMBasicBlockRef merge = LLVMAppendBasicBlock(fn, "merge");

    /* pred: %cmp = icmp sgt %x, %y, br merge */
    LLVMPositionBuilderAtEnd(bld, pred);
    LLVMValueRef cmp = LLVMBuildICmp(bld, LLVMIntSGT, arg_x, arg_y, "cmp");
    LLVMBuildBr(bld, merge);

    /* merge: PHI FIRST (LangRef requires PHIs at top of block),
       THEN zext (BAD: defined after the PHI in the same merge block,
       so does not dominate the PHI's incoming-edge use from pred). */
    LLVMPositionBuilderAtEnd(bld, merge);
    LLVMValueRef phi = LLVMBuildPhi(bld, i8, "phi");
    LLVMValueRef z   = LLVMBuildZExt(bld, cmp, i8, "z");
    LLVMValueRef inc_v[1] = { z };
    LLVMBasicBlockRef inc_bb[1] = { pred };
    LLVMAddIncoming(phi, inc_v, inc_bb, 1);
    /* observable use of z to defeat DCE */
    LLVMBuildStore(bld, z, g);
    LLVMBuildRetVoid(bld);

    LLVMBool bad = verify_and_dump("VARIANT_BAD: zext in merge after PHI", mod);

    LLVMDisposeBuilder(bld);
    LLVMDisposeModule(mod);
    return bad;
}

/* Build variant_good: zext in predecessor block before its terminator. */
static LLVMBool build_good(LLVMContextRef ctx) {
    LLVMModuleRef mod = LLVMModuleCreateWithNameInContext("c32_good", ctx);
    LLVMBuilderRef bld = LLVMCreateBuilderInContext(ctx);

    LLVMTypeRef i64 = LLVMInt64TypeInContext(ctx);
    LLVMTypeRef i8  = LLVMInt8TypeInContext(ctx);
    LLVMValueRef g = LLVMAddGlobal(mod, i8, "g");
    LLVMSetInitializer(g, LLVMConstInt(i8, 0, 0));
    LLVMSetLinkage(g, LLVMExternalLinkage);

    LLVMTypeRef fty = LLVMFunctionType(LLVMVoidTypeInContext(ctx),
        (LLVMTypeRef[]){ i64, i64 }, 2, 0);
    LLVMValueRef fn = LLVMAddFunction(mod, "f", fty);
    LLVMValueRef arg_x = LLVMGetParam(fn, 0);
    LLVMValueRef arg_y = LLVMGetParam(fn, 1);
    LLVMSetValueName(arg_x, "x");
    LLVMSetValueName(arg_y, "y");

    LLVMBasicBlockRef pred  = LLVMAppendBasicBlock(fn, "pred");
    LLVMBasicBlockRef merge = LLVMAppendBasicBlock(fn, "merge");

    /* pred: %cmp, %z = zext (GOOD), br merge */
    LLVMPositionBuilderAtEnd(bld, pred);
    LLVMValueRef cmp = LLVMBuildICmp(bld, LLVMIntSGT, arg_x, arg_y, "cmp");
    /* GOOD: emit zext in predecessor, before terminator */
    LLVMValueRef z = LLVMBuildZExt(bld, cmp, i8, "phi_icmp_zext");
    LLVMBuildBr(bld, merge);

    /* merge: PHI uses [z from pred]; observe z via store */
    LLVMPositionBuilderAtEnd(bld, merge);
    LLVMValueRef phi = LLVMBuildPhi(bld, i8, "phi");
    LLVMValueRef inc_v[1] = { z };
    LLVMBasicBlockRef inc_bb[1] = { pred };
    LLVMAddIncoming(phi, inc_v, inc_bb, 1);
    LLVMBuildStore(bld, phi, g);
    LLVMBuildRetVoid(bld);

    LLVMBool bad = verify_and_dump("VARIANT_GOOD: zext in pred before terminator", mod);

    LLVMDisposeBuilder(bld);
    LLVMDisposeModule(mod);
    return bad;
}

int main(void) {
    LLVMContextRef ctx = LLVMContextCreate();
    LLVMBool bad  = build_bad(ctx);
    LLVMBool good = build_good(ctx);
    LLVMContextDispose(ctx);

    printf("\n=== SUMMARY ===\n");
    printf("bad_return =%d  (LLVMVerifyModule result for variant_bad)\n",  (int)bad);
    printf("good_return=%d  (LLVMVerifyModule result for variant_good)\n", (int)good);
    printf("EXPECTED: bad=1 (rejected by dominance), good=0 (accepted)\n");
    printf("\n");
    if (bad == 1 && good == 0) {
        printf("OUTCOME_C_PLACEMENT_CONFIRMED\n");
        printf("\n");
        printf("Interpretation for the C4 IR_PHI dispatch arm:\n");
        printf("  - emit_zext_in_merge_block_after_phi       -> REJECTED\n");
        printf("    (Instruction does not dominate all uses)\n");
        printf("  - emit_zext_in_predecessor_before_term     -> ACCEPTED\n");
        printf("    (dominance holds; zext defined on the edge)\n");
        printf("\n");
        printf("  Therefore the § 9.1 amendment (C3.1) is incomplete.\n");
        printf("  The correct placement is in the predecessor block,\n");
        printf("  immediately before its terminator, using\n");
        printf("  LLVMPositionBuilderBefore(builder, pred_term).\n");
        printf("  The builder cursor must be restored to the merge\n");
        printf("  block before LLVMBuildPhi / LLVMAddIncoming.\n");
        return 0;
    }
    printf("UNEXPECTED: bad=%d good=%d\n", (int)bad, (int)good);
    return 1;
}
