/* ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C3.6 RED mechanical witness.
 *
 * NOT part of hcc. Standalone one-shot evidence tool (no LLVM
 * linkage required). Mechanically proves the LLDefMap domain
 * restriction to IR_VAL_TMP only.
 *
 * C3.6 evidence-channel fix (per expert review of C3.5):
 *
 *   The C3.5 unique-definition contract was too broad: it halted
 *   on ANY duplicate definition for an already-bound IrValue id.
 *   That accidentally turns the new PHI provenance map into a
 *   global SSA assertion over a neutral IR that deliberately
 *   contains mutable locals (IR_VAL_LOCAL).
 *
 *   PolyC's neutral IR has TWO classes of values with dst:
 *
 *     IR_VAL_TMP     SSA-like          (unique def per id)
 *     IR_VAL_LOCAL   mutable local     (intentionally multi-def;
 *                                      Option-W lowers via alloca
 *                                      + mem2reg)
 *
 *   The corrected contract restricts LLDefMap to TMPs only:
 *     - ins->dst->kind == IR_VAL_TMP   -> participate in map
 *     - every other kind               -> ignored
 *
 *   And preserves the unique-definition invariant for TMPs only:
 *     - duplicate TMP definition       -> HALT
 *     - duplicate LOCAL definition     -> silently skipped
 *
 * Required matrix (3 cases):
 *
 *   case                         behaviour
 *   ---------------------------  ---------------------------------
 *   multi_def_local              ALLOWED  (no halt; not in map)
 *   single_tmp_icmp              ALLOWED  (in map; producer retrievable)
 *   duplicate_tmp_id             HALT     (HALT_PHI_TYPE_CONTRACT_REQUIRED)
 *
 * The witness simulates the C3.6-corrected llBuildDefMap pass
 * over an IrFunction containing exactly these three patterns.
 *
 * Build:
 *   cc -o witness-domain witness-domain.c
 *   ./witness-domain
 */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Mock neutral-IR value kinds (subset of src/ir-types.h). */
typedef enum {
    IR_VAL_NOP,
    IR_VAL_TMP,        /* SSA-like; unique def per id (C3.6 in map) */
    IR_VAL_LOCAL,      /* Mutable local; intentionally multi-def (C3.6 SKIPPED) */
    IR_VAL_PARAM,
    IR_VAL_CONST_INT
} IrValueKind;

/* Mock neutral-IR opcodes (subset). */
typedef enum {
    IR_NOP,
    IR_ICMP,           /* The only authorized TMP producer for PHI i1 */
    IR_IADD,
    IR_STORE
} IrOp;

/* Mock IrValue. */
typedef struct {
    int id;
    IrValueKind kind;
    int width;         /* 1 or 8 or 64 */
} IrValue;

/* Mock IrInstr. */
typedef struct {
    IrOp op;
    IrValue *dst;
    IrValue *r1;
    IrValue *r2;
} IrInstr;

/* Mock IrBlock. */
typedef struct {
    const char *name;
    int ninstrs;
    IrInstr *instrs;
} IrBlock;

/* Mock IrFunction (just enough for the build pass). */
typedef struct {
    const char *name;
    int nblocks;
    IrBlock *blocks;
} IrFunction;

/* ----------------------------------------------------------------
 * C3.6-corrected LLDefMap.
 *
 * Domain: IR_VAL_TMP only.
 *   - Non-TMP dsts are silently skipped (C3.6 P0-1).
 *   - Duplicate TMP id is a hard halt (C3.6 P0-2).
 * ---------------------------------------------------------------- */
#define LLDM_HALT 1
#define LLDM_PASS 0

typedef struct {
    IrInstr **values;
    int *kinds;        /* tracked kind so we can confirm domain */
    int cap;
} LLDefMap;

static int g_halt_observed = 0;
static char g_halt_reason[512];

static void lldm_halt(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(g_halt_reason, sizeof(g_halt_reason), fmt, ap);
    va_end(ap);
    g_halt_observed = 1;
}

static void lldm_grow(LLDefMap *m, int needed) {
    if (needed <= m->cap) return;
    int newcap = m->cap ? m->cap * 2 : 16;
    while (newcap < needed) newcap *= 2;
    m->values = realloc(m->values, sizeof(IrInstr *) * newcap);
    m->kinds  = realloc(m->kinds,  sizeof(int) * newcap);
    for (int i = m->cap; i < newcap; i++) {
        m->values[i] = NULL;
        m->kinds[i]  = IR_VAL_NOP;
    }
    m->cap = newcap;
}

/* C3.6 CORRECTED lldmSet:
 *   - ins->dst->kind == IR_VAL_TMP   -> participate
 *   - any other kind                 -> return PASS (skip silently)
 *   - duplicate TMP id               -> HALT_PHI_TYPE_CONTRACT_REQUIRED
 */
static int lldm_set(LLDefMap *m, IrInstr *ins) {
    if (!ins || !ins->dst) return LLDM_PASS;
    if (ins->dst->kind != IR_VAL_TMP) {
        /* NOT in the LLDefMap domain. PolyC's mutable locals are
         * lowered through Option-W's alloca + mem2reg pipeline and
         * intentionally may have multiple defining instructions. */
        return LLDM_PASS;
    }
    int id = ins->dst->id;
    lldm_grow(m, id + 1);
    IrInstr *old = m->values[id];
    if (old && old != ins) {
        lldm_halt(
            "HALT_PHI_TYPE_CONTRACT_REQUIRED: duplicate TMP "
            "definition for IrValue id %d. IR_VAL_TMP must have "
            "a unique defining instruction (old=0x<ins1>, "
            "new=0x<ins2>).",
            id);
        return LLDM_HALT;
    }
    m->values[id] = ins;
    m->kinds[id]  = IR_VAL_TMP;
    return LLDM_PASS;
}

static IrInstr *lldm_get(LLDefMap *m, int id) {
    if (!m || !m->values || id < 0 || id >= m->cap) return NULL;
    return m->values[id];
}

/* C3.6 CORRECTED llBuildDefMap:
 *   one pass over all blocks; lldm_set internally filters by kind. */
static void llBuildDefMap(LLDefMap *m, IrFunction *fn) {
    for (int bi = 0; bi < fn->nblocks; bi++) {
        IrBlock *b = &fn->blocks[bi];
        for (int ii = 0; ii < b->ninstrs; ii++) {
            IrInstr *ins = &b->instrs[ii];
            if (lldm_set(m, ins) == LLDM_HALT) return;
        }
    }
}

/* ----------------------------------------------------------------
 * Test fixtures.
 * ---------------------------------------------------------------- */

/* Fixture A: a function whose only dst writes target IR_VAL_LOCAL.
 *
 *   block A:
 *     store V, 10        (dst V : LOCAL)
 *     iadd  V, x         (dst V : LOCAL)
 *     isub  V, y         (dst V : LOCAL)
 *
 * Three definitions of the same LOCAL id. Under C3.5's overly-
 * broad uniqueness contract this would HALT before PHI was even
 * relevant. Under C3.6 the LOCALs are outside the map domain and
 * the pass completes silently. */
static void build_fixture_multi_def_local(IrFunction *fn,
                                          IrValue *locals,
                                          IrValue *r1s,
                                          IrValue *r2s) {
    (void)r2s;
    IrBlock *b = &fn->blocks[0];
    b->name = "entry";
    b->ninstrs = 3;
    b->instrs = calloc(3, sizeof(IrInstr));

    /* store V, 10 */
    b->instrs[0].op  = IR_STORE;
    b->instrs[0].dst = &locals[0];   /* LOCAL V */
    b->instrs[0].r1  = &r1s[0];      /* 10 */
    b->instrs[0].r2  = NULL;

    /* iadd V, x */
    b->instrs[1].op  = IR_IADD;
    b->instrs[1].dst = &locals[0];   /* SAME LOCAL V (def #2) */
    b->instrs[1].r1  = &r1s[1];      /* x */
    b->instrs[1].r2  = NULL;

    /* isub V, y */
    b->instrs[2].op  = IR_IADD;
    b->instrs[2].dst = &locals[0];   /* SAME LOCAL V (def #3) */
    b->instrs[2].r1  = &r1s[2];      /* y */
    b->instrs[2].r2  = NULL;
}

/* Fixture B: a function with a single TMP from IR_ICMP. */
static void build_fixture_single_tmp_icmp(IrFunction *fn,
                                           IrValue *tmp,
                                           IrValue *r1s) {
    IrBlock *b = &fn->blocks[0];
    b->name = "entry";
    b->ninstrs = 1;
    b->instrs = calloc(1, sizeof(IrInstr));

    /* icmp t, a, b   (dst t : TMP, op ICMP) */
    b->instrs[0].op  = IR_ICMP;
    b->instrs[0].dst = &tmp[0];
    b->instrs[0].r1  = &r1s[0];
    b->instrs[0].r2  = &r1s[1];
}

/* Fixture C: a function with a synthetic duplicate TMP id.
 *
 *   block C:
 *     icmp t0, a, b    (defines t0)
 *     iadd t0, c       (RE-defines t0 -- illegal for TMP)
 *
 * Two definitions of the same TMP id. Under C3.6 this MUST HALT
 * with HALT_PHI_TYPE_CONTRACT_REQUIRED. */
static void build_fixture_duplicate_tmp(IrFunction *fn,
                                        IrValue *tmp,
                                        IrValue *r1s) {
    IrBlock *b = &fn->blocks[0];
    b->name = "entry";
    b->ninstrs = 2;
    b->instrs = calloc(2, sizeof(IrInstr));

    b->instrs[0].op  = IR_ICMP;
    b->instrs[0].dst = &tmp[0];      /* TMP t0, def #1 */
    b->instrs[0].r1  = &r1s[0];
    b->instrs[0].r2  = &r1s[1];

    b->instrs[1].op  = IR_IADD;
    b->instrs[1].dst = &tmp[0];      /* TMP t0, def #2 (duplicate) */
    b->instrs[1].r1  = &r1s[2];
    b->instrs[1].r2  = NULL;
}

/* ----------------------------------------------------------------
 * Harness.
 *
 * For each of the three fixtures we run llBuildDefMap, then check:
 *
 *   A (multi_def_local):
 *       expected: LLDM_PASS, no halt, def_map contains nothing
 *                 for V (LOCAL is out of domain)
 *   B (single_tmp_icmp):
 *       expected: LLDM_PASS, no halt, def_map[t0] == icmp instr
 *   C (duplicate_tmp):
 *       expected: LLDM_HALT, g_halt_observed set
 *
 * Process exits 0 iff all three expectations match.
 * ---------------------------------------------------------------- */
int main(void) {
    int a_pass = 0, b_pass = 0, c_pass = 0;

    /* --- Fixture A --- */
    {
        g_halt_observed = 0;
        g_halt_reason[0] = '\0';
        IrValue locals[1] = { { .id = 0, .kind = IR_VAL_LOCAL, .width = 64 } };
        IrValue r1s[3]   = {
            { .id = 100, .kind = IR_VAL_CONST_INT, .width = 64 }, /* 10 */
            { .id = 101, .kind = IR_VAL_PARAM,     .width = 64 }, /* x   */
            { .id = 102, .kind = IR_VAL_PARAM,     .width = 64 }  /* y   */
        };
        IrBlock blk = { 0 };
        IrFunction fn = { .name = "fixture_A_multi_def_local",
                          .nblocks = 1, .blocks = &blk };
        build_fixture_multi_def_local(&fn, locals, r1s, r1s);

        LLDefMap m = { 0 };
        llBuildDefMap(&m, &fn);

        int map_has_V  = (lldm_get(&m, 0) != NULL);
        int no_halt    = (g_halt_observed == 0);
        a_pass = no_halt && !map_has_V;
        printf("=== Fixture A: multi_def_local (IR_VAL_LOCAL id=0) ===\n");
        printf("  halt observed                : %d (want 0)\n", g_halt_observed);
        printf("  def_map[LOCAL V] populated   : %d (want 0)\n", map_has_V);
        printf("  result                       : %s\n\n",
               a_pass ? "PASS (LOCAL out of domain; not halted)"
                      : "FAIL");
        free(blk.instrs);
        free(m.values); free(m.kinds);
    }

    /* --- Fixture B --- */
    {
        g_halt_observed = 0;
        g_halt_reason[0] = '\0';
        IrValue tmp[1]  = { { .id = 0, .kind = IR_VAL_TMP, .width = 1 } };
        IrValue r1s[3]  = {
            { .id = 100, .kind = IR_VAL_PARAM, .width = 64 }, /* a */
            { .id = 101, .kind = IR_VAL_PARAM, .width = 64 }, /* b */
            { .id = 102, .kind = IR_VAL_PARAM, .width = 64 }  /* c */
        };
        IrBlock blk = { 0 };
        IrFunction fn = { .name = "fixture_B_single_tmp_icmp",
                          .nblocks = 1, .blocks = &blk };
        build_fixture_single_tmp_icmp(&fn, tmp, r1s);

        LLDefMap m = { 0 };
        llBuildDefMap(&m, &fn);

        IrInstr *producer = lldm_get(&m, 0);
        int no_halt       = (g_halt_observed == 0);
        int in_map        = (producer != NULL);
        int is_icmp       = in_map && (producer->op == IR_ICMP);
        int dst_ok        = in_map && (producer->dst == &tmp[0]);
        b_pass = no_halt && in_map && is_icmp && dst_ok;
        printf("=== Fixture B: single_tmp_icmp (IR_VAL_TMP id=0 from IR_ICMP) ===\n");
        printf("  halt observed              : %d (want 0)\n", g_halt_observed);
        printf("  def_map[t0] populated      : %d (want 1)\n", in_map);
        printf("  producer->op               : %s (want IR_ICMP)\n",
               in_map ? (producer->op == IR_ICMP ? "IR_ICMP" : "OTHER") : "N/A");
        printf("  producer->dst == t0        : %d (want 1)\n", dst_ok);
        printf("  result                     : %s\n\n",
               b_pass ? "PASS (TMP in map; producer retrievable)"
                      : "FAIL");
        free(blk.instrs);
        free(m.values); free(m.kinds);
    }

    /* --- Fixture C --- */
    {
        g_halt_observed = 0;
        g_halt_reason[0] = '\0';
        IrValue tmp[1]  = { { .id = 0, .kind = IR_VAL_TMP, .width = 1 } };
        IrValue r1s[3]  = {
            { .id = 100, .kind = IR_VAL_PARAM, .width = 64 }, /* a */
            { .id = 101, .kind = IR_VAL_PARAM, .width = 64 }, /* b */
            { .id = 102, .kind = IR_VAL_PARAM, .width = 64 }  /* c */
        };
        IrBlock blk = { 0 };
        IrFunction fn = { .name = "fixture_C_duplicate_tmp",
                          .nblocks = 1, .blocks = &blk };
        build_fixture_duplicate_tmp(&fn, tmp, r1s);

        LLDefMap m = { 0 };
        llBuildDefMap(&m, &fn);

        c_pass = (g_halt_observed == 1) &&
                 (strstr(g_halt_reason, "HALT_PHI_TYPE_CONTRACT_REQUIRED") != NULL) &&
                 (strstr(g_halt_reason, "duplicate TMP") != NULL) &&
                 (strstr(g_halt_reason, "0x<ins1>") != NULL) &&
                 (strstr(g_halt_reason, "0x<ins2>") != NULL);
        printf("=== Fixture C: duplicate_tmp (IR_VAL_TMP id=0 defined twice) ===\n");
        printf("  halt observed              : %d (want 1)\n", g_halt_observed);
        printf("  halt reason                : %s\n",
               g_halt_reason[0] ? g_halt_reason : "(none)");
        printf("  result                     : %s\n\n",
               c_pass ? "PASS (duplicate TMP halted with HALT_PHI_TYPE_CONTRACT_REQUIRED)"
                      : "FAIL");
        free(blk.instrs);
        free(m.values); free(m.kinds);
    }

    printf("========================================\n");
    printf("A (multi_def_local allowed) : %s\n", a_pass ? "PASS" : "FAIL");
    printf("B (single_tmp_icmp allowed) : %s\n", b_pass ? "PASS" : "FAIL");
    printf("C (duplicate_tmp halted)    : %s\n", c_pass ? "PASS" : "FAIL");
    printf("========================================\n");

    int all_pass = a_pass && b_pass && c_pass;
    printf("ALL THREE CASES MATCH REQUIRED SHAPE: %s\n",
           all_pass ? "YES" : "NO");
    return all_pass ? 0 : 1;
}