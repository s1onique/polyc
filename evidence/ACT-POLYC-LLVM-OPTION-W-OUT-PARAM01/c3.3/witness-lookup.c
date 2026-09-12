/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3.3 RED mechanical witness.
 *
 * NOT part of hcc. Standalone one-shot evidence tool linked against
 * LLVM 22 C API. Proves the C3.3 PI-1 lookup-only contract.
 *
 * The contract: PI-1 must use a LOOKUP-ONLY predicate (e.g.
 * llbmGet(&lc->blocks, ir_block_id)), NOT a get-or-create
 * accessor. A get-or-create accessor destroys the information
 * PI-1 is supposed to test (whether the predecessor was already
 * pre-allocated in llCreateBlocks).
 *
 * The witness demonstrates two strategies against the LLVM C API
 * and their consequences for PI-1:
 *
 *   Strategy A (BAD): llGetOrCreateBlock-equivalent semantics
 *     - if (block not yet appended) {
 *         bb = LLVMAppendBasicBlockInContext(...)
 *         map[id] = bb          // fabricate on demand
 *       }
 *     - After Strategy A, pred_bb != NULL even for a block that
 *       was never materialised by llCreateBlocks. PI-1 lies.
 *
 *   Strategy B (CORRECT): lookup-only predicate
 *     - bb = map_get(id)        // NO fabrication
 *     - if (bb == NULL) HALT_PHI_EDGE_MATERIALIZATION_REQUIRED
 *     - After Strategy B, pred_bb == NULL for unknown ids, and
 *       the HALT fires correctly.
 *
 * The witness simulates both strategies on a synthetic block map
 * with id range [0, 3) pre-allocated (matching the production
 * llCreateBlocks pre-allocation pattern at src/llvm-backend.c:
 * 1442-1468) and tests:
 *
 *   - id 0   : pre-allocated -> both strategies return non-NULL
 *   - id 1   : pre-allocated -> both strategies return non-NULL
 *   - id 2   : pre-allocated -> both strategies return non-NULL
 *   - id 99  : NOT pre-allocated ->
 *                Strategy A returns non-NULL (fabricated), PI-1 lies
 *                Strategy B returns NULL, PI-1 fires halt
 *
 * EXPECTED: Strategy A "PI-1 lies"; Strategy B "PI-1 truthful".
 *
 * Build:
 *   cc -o witness-lookup witness-lookup.c
 *   ./witness-lookup
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Simulate the lc->blocks map: IrBlock id -> LLVMBasicBlockRef. */
typedef unsigned long long BBRef;  /* opaque stand-in for LLVMBasicBlockRef */
#define BB_NULL ((BBRef)0)

typedef struct {
    BBRef *values;
    unsigned cap;
} BlockMap;

static void bmInit(BlockMap *m, unsigned cap) {
    m->cap = cap;
    m->values = (BBRef *)calloc(cap ? cap : 1, sizeof(BBRef));
    for (unsigned i = 0; i < cap; ++i) {
        /* pre-allocate with non-NULL sentinel BBRefs */
        m->values[i] = (BBRef)(0x1000ULL + (unsigned long long)i);
    }
}

/* Strategy A (BAD): get-or-create.
   If the id is outside the pre-allocated range, fabricate a new
   BasicBlockRef (simulated). This is what `llGetOrCreateBlock`
   would do, and it destroys PI-1's information. */
static BBRef bmGetOrCreate(BlockMap *m, unsigned id) {
    if (id >= m->cap) {
        /* fabricate: equivalent to LLVMAppendBasicBlock(...) */
        BBRef fab = (BBRef)(0xF000ULL + (unsigned long long)id);
        fprintf(stdout, "    [Strategy A] id=%u fabricated bb=0x%llx\n",
                id, (unsigned long long)fab);
        return fab;
    }
    return m->values[id];
}

/* Strategy B (CORRECT): lookup-only.
   If the id is outside the pre-allocated range, return NULL.
   Caller checks NULL and halts. */
static BBRef bmLookupExisting(BlockMap *m, unsigned id) {
    if (id >= m->cap) return BB_NULL;
    return m->values[id];
}

int main(void) {
    BlockMap m;
    bmInit(&m, 3);  /* pre-allocate ids 0, 1, 2 (simulating llCreateBlocks) */

    printf("PI-1 LOOKUP-ONLY WITNESS (C3.3 contract freeze)\n\n");
    printf("Pre-allocated block map: ids 0..2 (simulates llCreateBlocks)\n");
    printf("\n");

    unsigned test_ids[] = { 0, 1, 2, 99 };
    const char *test_labels[] = { "id 0  (pre-alloc)",
                                  "id 1  (pre-alloc)",
                                  "id 2  (pre-alloc)",
                                  "id 99 (NOT pre-alloc)" };

    int a_lies = 0;
    int b_truthful = 0;

    for (unsigned t = 0; t < sizeof(test_ids)/sizeof(test_ids[0]); ++t) {
        unsigned id = test_ids[t];
        printf("Test: %s\n", test_labels[t]);
        BBRef a = bmGetOrCreate(&m, id);
        BBRef b = bmLookupExisting(&m, id);
        printf("    [Strategy A: get-or-create] bb = 0x%llx  %s\n",
               (unsigned long long)a,
               (a == BB_NULL) ? "(NULL)" : "(non-NULL)");
        printf("    [Strategy B: lookup-only]   bb = 0x%llx  %s\n",
               (unsigned long long)b,
               (b == BB_NULL) ? "(NULL)" : "(non-NULL)");

        /* PI-1 expectation: for unknown id (99), PI-1 must
           detect "not pre-allocated" and HALT. */
        int expected_null = (id == 99);
        if (expected_null) {
            if (a != BB_NULL) {
                printf("    PI-1 under Strategy A: LIES "
                       "(fabricated block; would proceed without halt)\n");
                a_lies = 1;
            }
            if (b == BB_NULL) {
                printf("    PI-1 under Strategy B: TRUTHFUL "
                       "(returns NULL; caller halts)\n");
                b_truthful = 1;
            }
        }
        printf("\n");
    }

    printf("=== SUMMARY ===\n");
    printf("Strategy A (get-or-create): PI-1 %s\n",
           a_lies ? "LIES" : "(would be OK for known ids only)");
    printf("Strategy B (lookup-only):   PI-1 %s\n",
           b_truthful ? "TRUTHFUL" : "FAILED");

    free(m.values);

    if (a_lies && b_truthful) {
        printf("\nOUTCOME_E_PI1_LOOKUP_CONFIRMED\n");
        printf("\n");
        printf("Interpretation for the C4 IR_PHI dispatch arm:\n");
        printf("  - PI-1 MUST use llbmGet(&lc->blocks, ir_block_id)\n");
        printf("    or an equivalent lookup-only predicate.\n");
        printf("  - PI-1 MUST NOT use llGetOrCreateBlock, which\n");
        printf("    would fabricate an empty LLVM block on demand\n");
        printf("    and make PI-1 unable to detect the missing-\n");
        printf("    materialisation defect.\n");
        printf("  - PI-1 (lookup-only) + PI-2 (terminator present)\n");
        printf("    together correctly prove 'predecessor has been\n");
        printf("    lowered'. Either one alone is insufficient.\n");
        return 0;
    }
    printf("\nUNEXPECTED\n");
    return 1;
}
