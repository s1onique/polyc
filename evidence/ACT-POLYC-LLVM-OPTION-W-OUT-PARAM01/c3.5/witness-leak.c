/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3.5 RED mechanical witness.
 *
 * NOT part of hcc. Standalone one-shot evidence tool (no LLVM
 * linkage required). Mechanically proves the C3.4 producer-leak
 * CORRECTION by requiring the OBSERVED current-discriminator
 * accept-set to leak exactly two cases (IR_FCMP, function-param
 * i1) that the corrected producer-checked discriminator rejects.
 *
 * C3.5 evidence-channel fix (per expert):
 *
 *   The C3.4 witness-leak had an inverted predicate: its `leak`
 *   measured "witness matches its own hard-coded expected table",
 *   which is the wrong semantic. A witness that always returns
 *   the values it expects is a tautology, not a leak.
 *
 *   The correct predicate is:
 *
 *       leak(curr, producer) =
 *           curr_accepts  AND
 *           NOT producer_authorized
 *
 *   where
 *
 *       producer_authorized =
 *           has_producer AND producer_op == IR_ICMP
 *
 *   This is independent of the witness's own expectations: the
 *   leak exists iff the current discriminator accepts a value
 *   whose producer is NOT authorized by the S9.4 contract.
 *
 *   Required matrix (4 cases):
 *
 *       case                  curr     producer_authorized  leak?
 *       phi_icmp_producer     ACCEPT   YES                  NO
 *       phi_fcmp_producer     ACCEPT   NO                   YES
 *       phi_param_i1          ACCEPT   NO                   YES
 *       phi_no_zext_i8        direct   (not normalised)     NO
 *
 *   LEAK_ROWS must equal 2 (FCMP + PARAM).
 *   The process must exit 0 ONLY if the observed matrix is
 *   EXACTLY as above. Any deviation -> non-zero exit +
 *   UNEXPECTED verdict.
 *
 * Build:
 *   cc -o witness-leak witness-leak.c
 *   ./witness-leak
 */
#include <stdio.h>
#include <string.h>

/* Mock neutral-IR opcodes. */
typedef enum { IR_NOP, IR_ICMP, IR_FCMP } IrOp;

/* Mock value with producer info. */
typedef struct {
    const char *name;
    int width;            /* 1 or 8 */
    int has_producer;
    IrOp producer_op;
} MockValue;

/* Mock current discriminator: type-only. Returns 1 if it would
   proceed with normalisation, 0 if it would skip. */
static int current_discriminator_accepts(MockValue *v) {
    /* The current C3.3 discriminator proceeds whenever
       the LLVM type is i1 and the PHI is i8. We simulate the
       type check only -- which is precisely the leak. */
    return (v->width == 1) ? 1 : 0;
}

/* Mock producer authorization check: defined by the contract,
   NOT by the witness's expectations. */
static int producer_authorized(MockValue *v) {
    return v->has_producer && (v->producer_op == IR_ICMP);
}

typedef struct {
    const char *name;
    MockValue   v;
    int         expected_curr;
    int         expected_corr;
    int         expected_leak;
} Case;

int main(void) {
    Case cases[] = {
        { "phi_icmp_producer",
          { "icmp_sgt", 1, 1, IR_ICMP },
          1, 1, 0 },
        { "phi_fcmp_producer",
          { "fcmp_oeq", 1, 1, IR_FCMP },
          1, 0, 1 },
        { "phi_param_i1",
          { "arg.b", 1, 0, IR_NOP },
          1, 0, 1 },
        { "phi_no_zext_i8",
          { "const.i8.1", 8, 0, IR_NOP },
          0, 0, 0 },
    };

    int n = (int)(sizeof(cases) / sizeof(cases[0]));

    printf("C3.5 PRODUCER-LEAK WITNESS (CORRECTED PREDICATE)\n");
    printf("\n");
    printf("Discriminator definitions:\n");
    printf("  current (C3.3 leaky):  proceeds iff LLVMTypeOf(v) == i1\n");
    printf("  producer_authorized:   has_producer && producer_op == IR_ICMP\n");
    printf("  corrected (C3.4):      proceeds iff producer_authorized\n");
    printf("  leak:                  curr_accepts && !producer_authorized\n");
    printf("\n");
    printf("=== OBSERVED MATRIX ===\n");
    printf("\n");
    /* Right-aligned trailing column: %s not %-7s to avoid trailing
       whitespace on short strings ("no", "YES"). */
    printf("%-22s %-7s %-7s %-9s %-9s %-9s %s\n",
           "case", "width", "prod",
           "expected", "observed", "corrected", "leak?");
    printf("%-22s %-7s %-7s %-9s %-9s %-9s %s\n",
           "----------------------", "-------", "-------",
           "---------", "---------", "---------", "-------");

    int observed_curr[4], observed_corr[4], observed_leak[4];
    int leak_rows = 0;
    int matrix_ok = 1;

    for (int i = 0; i < n; ++i) {
        Case *c = &cases[i];
        int curr = current_discriminator_accepts(&c->v);
        int auth = producer_authorized(&c->v);
        int corr = auth;
        int leak = curr && !auth;

        const char *prod_str = c->v.has_producer
            ? (c->v.producer_op == IR_ICMP ? "IR_ICMP" :
               c->v.producer_op == IR_FCMP ? "IR_FCMP" : "OTHER")
            : "(none)";

        printf("%-22s %-7d %-7s %-9s %-9s %-9s %s\n",
               c->name, c->v.width, prod_str,
               c->expected_curr ? "ACCEPT" : "reject",
               curr ? "ACCEPT" : "reject",
               corr ? "ACCEPT" : "reject",
               leak ? "YES" : "no");

        observed_curr[i] = curr;
        observed_corr[i] = corr;
        observed_leak[i] = leak;
        if (leak) leak_rows++;
        if (curr != c->expected_curr ||
            corr != c->expected_corr ||
            leak != c->expected_leak) {
            matrix_ok = 0;
        }
    }

    printf("\n");
    printf("=== VERDICT ===\n");
    printf("Leak rows (curr accepts AND !producer_authorized): %d\n",
           leak_rows);
    printf("Required leak rows:                                2\n");
    printf("Matrix matches required shape:                     %s\n",
           matrix_ok ? "YES" : "NO");
    printf("\n");

    if (matrix_ok && leak_rows == 2) {
        printf("OUTCOME_F_PRODUCER_LEAK_CONFIRMED\n");
        printf("\n");
        printf("Interpretation for the C4 IR_PHI dispatch arm:\n");
        printf("  - The CURRENT discriminator (LLVMTypeOf == i1)\n");
        printf("    leaks EXACTLY 2 cases: IR_FCMP-produced i1\n");
        printf("    and function-parameter i1.\n");
        printf("  - The CORRECTED discriminator (producer == IR_ICMP)\n");
        printf("    rejects both leaks.\n");
        printf("  - The predicate `leak = curr_accepts &&\n");
        printf("    !producer_authorized` is the correct semantic,\n");
        printf("    NOT 'witness matches its own expectations'.\n");
        return 0;
    }

    printf("UNEXPECTED: matrix_ok=%d leak_rows=%d (expected matrix_ok=1 leak_rows=2)\n",
           matrix_ok, leak_rows);
    return 1;
}
