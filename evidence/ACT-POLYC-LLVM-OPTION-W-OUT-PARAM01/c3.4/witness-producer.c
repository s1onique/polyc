/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3.4 RED mechanical witness.
 *
 * NOT part of hcc. Standalone one-shot evidence tool (no LLVM
 * linkage required). Drives the C3.4 corrected algorithm
 * (producer-checked + per-PHI counter) over FOUR synthetic
 * IR_PHI cases and prints the counter delta + verdict for each.
 *
 * The four cases test the full C3.4 contract:
 *
 *   phi_icmp_producer:
 *     1 incoming (i1 from IR_ICMP)
 *     -> producer-checked AUTHORIZED
 *     -> delta=1, conversion applied
 *
 *   phi_fcmp_producer:
 *     1 incoming (i1 from IR_FCMP)
 *     -> producer-checked REJECTED (HALT_PHI_TYPE_CONTRACT_REQUIRED)
 *     -> delta=0
 *
 *   phi_param_i1:
 *     1 incoming (i1 function parameter, no producer)
 *     -> producer-checked REJECTED
 *     -> delta=0
 *
 *   phi_rejected_i64:
 *     1 incoming (i64 const)
 *     -> type-checked REJECTED (Outcome C of C3.1)
 *     -> delta=0
 *
 * Total expected counter value: 1 + 0 + 0 + 0 = 1.
 *
 * Build:
 *   cc -o witness-producer witness-producer.c
 *   ./witness-producer
 */
#include <stdio.h>
#include <string.h>

/* Mock neutral-IR opcodes. */
typedef enum { IR_NOP, IR_ICMP, IR_FCMP } IrOp;

/* Mock def_map entry. */
typedef struct {
    int has_producer;
    IrOp op;
} DefEntry;

static DefEntry def_map[256];

static void def_map_init(void) {
    for (int i = 0; i < 256; ++i) {
        def_map[i].has_producer = 0;
        def_map[i].op = IR_NOP;
    }
    def_map[1].has_producer = 1; def_map[1].op = IR_ICMP;
    def_map[2].has_producer = 1; def_map[2].op = IR_FCMP;
    /* id 3 and id 4 left as has_producer=0 (param + const) */
}

typedef struct {
    const char *name;
    int ir_value_id;
    int llvm_width;
    int expected_delta;
    int expected_converted;
} Case;

/* Run the C3.4 corrected algorithm. Returns 1 if the case
   produced the expected delta and converted count, 0 otherwise. */
static int run_case(Case *c, unsigned *g_counter, int *g_out_delta,
                    int *g_out_converted) {
    unsigned before = *g_counter;
    int converted = 0;
    int delta = 0;

    /* shape admission. */
    int shape_admitted = 0;
    int v_id = c->ir_value_id;
    int w = c->llvm_width;

    if (w == 8) {
        shape_admitted = 1;
    } else if (w == 1) {
        DefEntry *d = &def_map[v_id];
        if (d->has_producer && d->op == IR_ICMP) {
            shape_admitted = 1;
            converted = 1;
        } else {
            shape_admitted = 0;
        }
    } else {
        shape_admitted = 0;
    }

    /* Counter increments once at the top because the SHAPE has
       been admitted (Option A: "static shape admitted by dispatch
       contract"). */
    if (shape_admitted) {
        *g_counter += 1;
        delta = 1;
    } else {
        delta = 0;
    }

    *g_out_delta = delta;
    *g_out_converted = converted;

    int ok = (delta == c->expected_delta &&
              converted == c->expected_converted);
    printf("  case=%-22s  delta=%d  converted=%d  "
           "expected_delta=%d  expected_converted=%d  %s\n",
           c->name, delta, converted,
           c->expected_delta, c->expected_converted,
           ok ? "OK" : "FAIL");
    return ok;
}

int main(void) {
    def_map_init();
    unsigned counter = 0;

    printf("C3.4 PRODUCER-CHECKED + PER-PHI COUNTER WITNESS\n");
    printf("\n");
    printf("Mock def_map (IrValue id -> defining IrInstr):\n");
    printf("  id 1 -> IR_ICMP\n");
    printf("  id 2 -> IR_FCMP\n");
    printf("  id 3 -> (none; function parameter)\n");
    printf("  id 4 -> (none; constant)\n");
    printf("\n");

    Case cases[] = {
        { "phi_icmp_producer", 1, 1, 1, 1 },
        { "phi_fcmp_producer", 2, 1, 0, 0 },
        { "phi_param_i1",      3, 1, 0, 0 },
        { "phi_rejected_i64",  4, 64, 0, 0 },
    };
    int n = (int)(sizeof(cases) / sizeof(cases[0]));

    printf("=== CASE RUN ===\n\n");
    int all_ok = 1;
    for (int i = 0; i < n; ++i) {
        int d, cv;
        if (!run_case(&cases[i], &counter, &d, &cv)) all_ok = 0;
    }

    printf("\nFINAL counter value: %u\n", counter);
    printf("EXPECTED:            1 (only phi_icmp_producer is admitted)\n");

    if (all_ok && counter == 1) {
        printf("\nOUTCOME_G_PRODUCER_AND_COUNTER_CONFIRMED\n");
        printf("\n");
        printf("Interpretation for the C4 IR_PHI dispatch arm:\n");
        printf("  - The discriminator MUST check producer opcode\n");
        printf("    (IR_ICMP only), not just LLVM type.\n");
        printf("  - The producer check happens BEFORE the i1 -> i8\n");
        printf("    normalization is attempted, so a non-IR_ICMP\n");
        printf("    i1 halts with HALT_PHI_TYPE_CONTRACT_REQUIRED\n");
        printf("    without emitting any zext.\n");
        printf("  - The counter semantic is 'static shape admitted\n");
        printf("    by dispatch contract' (Option A): it increments\n");
        printf("    once at the top, BEFORE PI-1/PI-2/PI-3 guards.\n");
        printf("  - Expected counters for the C2-A.2 frozen matrix\n");
        printf("    when C4 lands:\n");
        printf("      G3       : 1 SHAPE_DEPENDENT (one IR_ICMP PHI)\n");
        printf("      PhiOnly  : 1 SHAPE_DEPENDENT (one IR_ICMP PHI)\n");
        return 0;
    }
    printf("\nUNEXPECTED\n");
    return 1;
}
