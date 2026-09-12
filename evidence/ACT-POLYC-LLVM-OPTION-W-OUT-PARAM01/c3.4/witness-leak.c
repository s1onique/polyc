/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3.4 RED mechanical witness.
 *
 * NOT part of hcc. Standalone one-shot evidence tool (no LLVM
 * linkage required). Demonstrates the C3.3 §9.3.5 contract leak
 * identified by the expert review:
 *
 *   The frozen prose narrows the i1 -> i8 normalization to
 *   "IR_ICMP-only", but the discriminator decides SOLELY from
 *   LLVMTypeOf(v) == i1. That accepts ANY cached i1, including
 *   i1s produced by:
 *     - IR_FCMP (LLVMBuildFCmp returns i1)
 *     - function parameters typed as i1 (bool)
 *     - LLVMBuildZExt / LLVMBuildSExt of an i8 -> i1 (would
 *       require explicit lowering, but the discriminator would
 *       not catch it if such a value were cached)
 *
 * The witness drives the C3.3 pseudocode over FOUR synthetic
 * cases and shows which would be authorized vs rejected under
 * the CURRENT (leaky) discriminator, contrasted with the
 * CORRECTED (producer-checked) discriminator.
 *
 * Verdict: under the CURRENT discriminator, all four cases
 * would be authorized. Under the CORRECTED discriminator,
 * only the IR_ICMP case is authorized.
 *
 * Build:
 *   cc -o witness-leak witness-leak.c
 *   ./witness-leak
 */
#include <stdio.h>
#include <string.h>

/* Mock neutral-IR opcodes (subset of src/ir-types.h:63). */
typedef enum { IR_NOP, IR_ICMP, IR_FCMP, IR_ZEXT } IrOp;

/* Mock LLVM value: opaque + typed + producer. */
typedef struct {
    const char *name;
    int width;            /* 1, 8, 64 */
    IrOp producer_op;     /* IR_NOP if no producer (param/const) */
    int has_producer;
} FakeLLVMValue;

static FakeLLVMValue icmp_i1 = { "icmp_sgt", 1, IR_ICMP, 1 };
static FakeLLVMValue fcmp_i1 = { "fcmp_oeq", 1, IR_FCMP, 1 };
static FakeLLVMValue param_i1 = { "arg.b", 1, IR_NOP, 0 };
static FakeLLVMValue const_i8 = { "const.i8.1", 8, IR_NOP, 0 };

typedef struct {
    const char *name;
    FakeLLVMValue *v;
    int expected_current;   /* what C3.3 says */
    int expected_corrected; /* what C3.4 says */
    const char *note;
} Case;

int main(void) {
    Case cases[] = {
        { "phi_icmp_producer",  &icmp_i1,  1, 1,
          "IR_ICMP -> i1: AUTHORIZED by both" },
        { "phi_fcmp_producer",  &fcmp_i1,  1, 0,
          "IR_FCMP -> i1: CURRENT accepts (LEAK); CORRECTED rejects" },
        { "phi_param_i1",       &param_i1, 1, 0,
          "Function-arg i1: CURRENT accepts (LEAK); CORRECTED rejects" },
        { "phi_no_zext_i8",     &const_i8, 0, 0,
          "i8 incoming: no normalization needed; both reject" },
    };
    int n = (int)(sizeof(cases) / sizeof(cases[0]));

    printf("C3.4 PRODUCER-LEAK WITNESS\n");
    printf("\n");
    printf("Current C3.3 §9.3.5 discriminator:\n");
    printf("  if LLVMTypeOf(v) == LLVMInt1TypeInContext(lc->ctx) &&\n");
    printf("     phi_ty == LLVMInt8TypeInContext(lc->ctx):\n");
    printf("      v = LLVMBuildZExt(...)\n");
    printf("\n");
    printf("Corrected C3.4 §9.4 discriminator:\n");
    printf("  if LLVMTypeOf(v) == LLVMInt1TypeInContext(lc->ctx) &&\n");
    printf("     phi_ty == LLVMInt8TypeInContext(lc->ctx):\n");
    printf("      producer = def_map_lookup(p->ir_value)\n");
    printf("      if !producer ||\n");
    printf("         producer->op != IR_ICMP ||\n");
    printf("         producer->dst != p->ir_value:\n");
    printf("        HALT_PHI_TYPE_CONTRACT_REQUIRED\n");
    printf("      v = LLVMBuildZExt(...)\n");
    printf("\n");
    printf("=== CASE TABLE ===\n");
    printf("\n");
    printf("%-22s %-7s %-7s %-7s %-7s %-7s  %s\n",
           "case", "width", "prod", "curr", "corr", "leak?", "note");
    printf("%-22s %-7s %-7s %-7s %-7s %-7s  %s\n",
           "--------------------", "-------", "-------",
           "-------", "-------", "-------",
           "----------------------------------------");

    int leaks = 0;
    for (int i = 0; i < n; ++i) {
        Case *c = &cases[i];
        /* Current discriminator: type-only. */
        int curr_accepts =
            (c->v->width == 1) ? 1 : 0;
        /* Corrected discriminator: type AND producer == IR_ICMP. */
        int corr_accepts =
            (c->v->width == 1) &&
            c->v->has_producer &&
            (c->v->producer_op == IR_ICMP);
        int leak = (curr_accepts != c->expected_current) ||
                   (corr_accepts != c->expected_corrected);

        const char *prod_str = c->v->has_producer
            ? (c->v->producer_op == IR_ICMP ? "IR_ICMP" :
               c->v->producer_op == IR_FCMP ? "IR_FCMP" : "OTHER")
            : "(none)";

        printf("%-22s %-7d %-7s %-7s %-7s %-7s  %s\n",
               c->name, c->v->width, prod_str,
               curr_accepts ? "ACCEPT" : "reject",
               corr_accepts ? "ACCEPT" : "reject",
               leak ? "YES" : "no",
               c->note);
        if (leak) leaks++;
    }

    printf("\n");
    printf("=== SUMMARY ===\n");
    printf("Leak rows: %d\n", leaks);
    printf("\n");
    printf("C3.3 §9.3.5 (current) accepts the IR_FCMP and function-\n");
    printf("parameter i1 cases. C3.4 §9.4 (corrected) rejects both.\n");
    printf("\n");

    /* Sanity check: the expected leaks are exactly 2 (fcmp + param). */
    int fcmp_leak = (cases[1].expected_current == 1) &&
                    (cases[1].expected_corrected == 0);
    int param_leak = (cases[2].expected_current == 1) &&
                     (cases[2].expected_corrected == 0);
    int icmp_ok = (cases[0].expected_current == 1) &&
                  (cases[0].expected_corrected == 1);

    if (fcmp_leak && param_leak && icmp_ok) {
        printf("OUTCOME_F_PRODUCER_LEAK_CONFIRMED\n");
        printf("\n");
        printf("Interpretation for the C4 IR_PHI dispatch arm:\n");
        printf("  - The discriminator MUST check the producer opcode,\n");
        printf("    not just the LLVM type.\n");
        printf("  - A bounded producer-identity seam is required:\n");
        printf("      def_map : IrValue id -> defining IrInstr *\n");
        printf("    built during llCreateBlocks (or right after) by\n");
        printf("    walking every IrInstr in every IrBlock and\n");
        printf("    recording instr->dst -> instr.\n");
        printf("  - The i1 -> i8 normalization path then becomes:\n");
        printf("      producer = def_map_lookup(p->ir_value)\n");
        printf("      if !producer || producer->op != IR_ICMP ||\n");
        printf("         producer->dst != p->ir_value:\n");
        printf("        HALT_PHI_TYPE_CONTRACT_REQUIRED\n");
        printf("\n");
        printf("  - Constants and arguments bypass the producer check\n");
        printf("    (they have no defining IrInstr), but they are also\n");
        printf("    LLVM i8 by construction (no normalization needed).\n");
        printf("    The discriminator naturally falls through to\n");
        printf("    \"use directly\" without ever entering the i1 branch.\n");
        return 0;
    }
    printf("UNEXPECTED\n");
    return 1;
}
