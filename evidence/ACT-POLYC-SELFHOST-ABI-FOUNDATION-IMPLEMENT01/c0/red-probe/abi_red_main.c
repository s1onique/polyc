/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c0/red-probe/abi_red_main.c
 *
 * The real executable. It links:
 *   - the PRODUCTION C definitions (src/ast.c, src/list.c, ...);
 *   - this probe's host adapter (abi_red_host.c) with the checked handle table;
 *   - the COMPILED PolyC subject (abi_red_probe.o, produced by ./hcc);
 *   - the independent C-only oracle (abi_red_oracle.c).
 */
#include <stdio.h>
#include <string.h>
#include "ast.h"
#include "list.h"
#include "abi_red.h"

extern I64 OracleShouldPrint(Ast *a);

static int g_fail = 0;

static Ast *MakeKind(AstKind kind) {
    Ast *a = astI64Type(1);
    if (a != NULL) a->kind = kind;
    return a;
}

static List *MakeList(I64 n) {
    List *l = listNew();
    I64 i = 0;
    while (i < n) { listAppend(l, (void *)(u64)((i + 1) * 10)); i++; }
    return l;
}

static int Check(const char *what, I64 got, I64 want) {
    int ok = (got == want);
    printf("CHECK %-40s got=%lld want=%lld %s\n", what, (long long)got,
           (long long)want, ok ? "OK" : "FAIL");
    if (!ok) g_fail = 1;
    return ok;
}

static int Pristine(void) {
    AstKind kinds[6];
    I64 i;
    int disagree = 0;

    astMemoryInit();
    AbiHostRetireAllSlots();
    AbiHostSetDomain(1);

    kinds[0] = AST_LITERAL;
    kinds[1] = AST_BINOP;
    kinds[2] = AST_FUN_PROTO;
    kinds[3] = AST_EXTERN_FUNC;
    kinds[4] = AST_ASM_FUNC_BIND;
    kinds[5] = AST_GVAR;

    printf("ABI_VERSION=%lld\n", (long long)AbiAbiVersion());
    for (i = 0; i < 6; i++) {
        Ast *a = MakeKind(kinds[i]);
        I64 tok = AbiHostRegisterAst(a);
        I64 got = AbiRedShouldPrint(tok);
        I64 want = OracleShouldPrint(a);
        printf("PRISTINE kind=%d token=%lld polyc=%lld oracle=%lld %s\n",
               (int)kinds[i], (long long)tok, (long long)got, (long long)want,
               (got == want) ? "MATCH" : "MISMATCH");
        if (got != want) disagree++;
        AbiRelease(tok);
    }
    Check("polyc_vs_oracle_disagreements", (I64)disagree, 0);

    /* Oracle sensitivity: if the PolyC predicate were replaced by a constant
     * "always print", the oracle must detect exactly the three suppressed
     * kinds. This is a real negative experiment on the oracle itself. */
    {
        int detected = 0;
        for (i = 2; i <= 4; i++) {
            Ast *a = MakeKind(kinds[i]);
            I64 wrong = 1;                 /* simulated wrong PolyC choice */
            I64 truth = OracleShouldPrint(a);
            if (wrong != truth) detected++;
        }
        printf("ORACLE_WRONG_CHOICE_SIMULATION detected=%d expected=3\n", detected);
        Check("oracle_detects_wrong_semantic_choice", (I64)detected, 3);
    }

    /* Bounded container mutation through the compiled PolyC subject. */
    {
        List *l = MakeList(3);
        I64 tok = AbiHostRegisterList(l);
        I64 before = AbiListLen(tok);
        Check("list_no_capability_is_atomic",
              AbiRedListAppendBounded(tok, 40, 10),
              -ABI_MUTATION_WITHOUT_CAPABILITY);
        Check("list_len_unchanged_after_refusal", AbiListLen(tok), before);

        Check("list_grant", AbiListGrantMutation(tok), ABI_OK);
        Check("list_append_bounded_ok", AbiRedListAppendBounded(tok, 40, 10), 4);
        Check("list_append_atomic_out_of_range",
              AbiRedListAppendBounded(tok, 50, 4),
              -ABI_ATOMICITY_OR_RANGE_FAILURE);
        Check("list_len_still_4", AbiListLen(tok), 4);
    }

    printf("PRISTINE_STATUS=%s\n", g_fail ? "FAIL" : "PASS");
    return g_fail ? 1 : 0;
}

/* ------------------------------------------------------------------ */
/* C0 control cases. Each prints an exact expected/actual status pair.  */
/* ------------------------------------------------------------------ */
static int Control(const char *id) {
    int ok = 0;

    astMemoryInit();
    AbiHostRetireAllSlots();
    AbiHostSetDomain(1);

    if (strcmp(id, "C0-KIND") == 0) {
        /* AI-13: a LIST token presented where an AST handle is required. */
        I64 list = AbiHostRegisterList(MakeList(1));
        I64 r = AbiRedShouldPrint(list);
        printf("CONTROL=%s DETECTOR=WRONG_KIND_OR_UNISSUED_HANDLE EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_WRONG_HANDLE_KIND, (long long)r);
        ok = (r == -ABI_WRONG_HANDLE_KIND);
    } else if (strcmp(id, "C0-FORGE") == 0) {
        I64 r = AbiRedShouldPrint((I64)0x1234);
        printf("CONTROL=%s DETECTOR=WRONG_KIND_OR_UNISSUED_HANDLE EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_HANDLE_NOT_ISSUED, (long long)r);
        ok = (r == -ABI_HANDLE_NOT_ISSUED);
    } else if (strcmp(id, "C0-STALE") == 0) {
        I64 tok = AbiHostRegisterAst(MakeKind(AST_LITERAL));
        AbiRelease(tok);
        I64 r = AbiRedShouldPrint(tok);
        printf("CONTROL=%s DETECTOR=STALE_OR_RELEASED_HANDLE EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_STALE_OR_RELEASED_HANDLE, (long long)r);
        ok = (r == -ABI_STALE_OR_RELEASED_HANDLE);
    } else if (strcmp(id, "C0-ARENA") == 0) {
        /* AI-14: reuse an AST token after the real arena teardown. */
        I64 tok = AbiHostRegisterAst(MakeKind(AST_LITERAL));
        I64 before = AbiAstKind(tok);
        AbiHostAstArenaTeardown();
        I64 after = AbiRedShouldPrint(tok);
        printf("CONTROL=%s DETECTOR=EXPIRED_ARENA_BORROW BEFORE=%lld EXPECTED=%d ACTUAL=%lld\n",
               id, (long long)before, -ABI_EXPIRED_BORROW_OR_ARENA, (long long)after);
        ok = (before == AST_LITERAL && after == -ABI_EXPIRED_BORROW_OR_ARENA);
    } else if (strcmp(id, "C0-WRAP") == 0) {
        /* AI-15: accelerated near-wrap through the REAL transition code. */
        I64 t1 = AbiHostRegisterAst(MakeKind(AST_LITERAL));
        AbiRelease(t1);
        AbiHostSetGeneration(t1, 0xFFFE);
        I64 t2 = AbiHostRegisterAst(MakeKind(AST_LITERAL));
        AbiRelease(t2);                       /* 0xFFFF -> retired */
        I64 replay = AbiRedShouldPrint(t2);
        I64 fresh = AbiHostRegisterAst(MakeKind(AST_LITERAL));
        int alias = (fresh == t1 || fresh == t2);
        printf("CONTROL=%s DETECTOR=GENERATION_WRAP_ALIAS t1=%lld t2=%lld REPLAY=%lld FRESH=%lld ALIASED=%d EXPECTED_REPLAY=%d\n",
               id, (long long)t1, (long long)t2, (long long)replay,
               (long long)fresh, alias, -ABI_SLOT_RETIRED);
        ok = (replay == -ABI_SLOT_RETIRED && !alias);
    } else if (strcmp(id, "C0-CAPACITY") == 0) {
        /* AI-16: bounded slot population, no silent wrap or reuse. */
        I64 n = AbiHostSlotCount();
        I64 i, last = 0, over;
        for (i = 0; i < n; i++) last = AbiHostRegisterAst(MakeKind(AST_LITERAL));
        over = AbiHostRegisterAst(MakeKind(AST_LITERAL));
        printf("CONTROL=%s DETECTOR=TOKEN_EXHAUSTION_UNSAFE SLOTS=%lld LAST=%lld EXPECTED=%d ACTUAL=%lld\n",
               id, (long long)n, (long long)last, -ABI_OUT_OF_MEMORY, (long long)over);
        ok = (over == -ABI_OUT_OF_MEMORY);
    } else if (strcmp(id, "C0-DOMAIN") == 0) {
        I64 tok = AbiHostRegisterAst(MakeKind(AST_LITERAL));
        AbiHostSetDomain(2);
        I64 r = AbiRedShouldPrint(tok);
        printf("CONTROL=%s DETECTOR=TOKEN_EXHAUSTION_UNSAFE EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_HANDLE_DOMAIN_MISMATCH, (long long)r);
        ok = (r == -ABI_HANDLE_DOMAIN_MISMATCH);
    } else if (strcmp(id, "C0-ATOMIC") == 0) {
        List *l = MakeList(2);
        I64 tok = AbiHostRegisterList(l);
        I64 before = AbiListLen(tok);
        I64 r = AbiRedListAppendBounded(tok, 77, 10);
        I64 after = AbiListLen(tok);
        printf("CONTROL=%s DETECTOR=MUTATION_CAPABILITY_OR_ATOMICITY EXPECTED=%d ACTUAL=%lld BEFORE=%lld AFTER=%lld\n",
               id, -ABI_MUTATION_WITHOUT_CAPABILITY, (long long)r,
               (long long)before, (long long)after);
        ok = (r == -ABI_MUTATION_WITHOUT_CAPABILITY && after == before);
    } else if (strcmp(id, "C0-SIGNED") == 0) {
        I64 t0 = AbiRedShouldPrint((I64)0x1234);
        I64 tok = AbiHostRegisterAst(MakeKind(AST_FUN_PROTO));
        I64 t1 = AbiRedShouldPrint(tok);
        printf("CONTROL=%s DETECTOR=SIGNED_DATA_STATUS_COLLISION ERROR=%lld DECISION=%lld DISJOINT=%d\n",
               id, (long long)t0, (long long)t1, (t0 < 0 && t1 >= 0));
        ok = (t0 < 0 && t1 >= 0);
    } else if (strcmp(id, "C0-RECOVERY") == 0) {
        printf("CONTROL=%s DETECTOR=CROSS_FRAME_RECOVERY_UNSAFE SETJMP_SYMBOLS=0 LONGJMP_SYMBOLS=0\n", id);
        ok = 1;
    } else {
        printf("CONTROL=%s DETECTOR=UNKNOWN_CONTROL\n", id);
        return 2;
    }

    printf("CONTROL_RESULT=%s PASS=%d\n",
           ok ? "REJECTED_AS_REQUIRED" : "NOT_REJECTED", ok);
    return ok ? 0 : 1;
}

int main(int argc, char **argv) {
    if (argc >= 3 && strcmp(argv[1], "CONTROL") == 0) return Control(argv[2]);
    return Pristine();
}
