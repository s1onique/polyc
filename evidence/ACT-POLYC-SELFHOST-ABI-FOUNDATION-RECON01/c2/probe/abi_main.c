/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe/abi_main.c
 *
 * The real executable. It links:
 *   - the PRODUCTION C definitions (src/ast.c, src/list.c, ...);
 *   - this host adapter (abi_host.c) with the checked handle table;
 *   - the COMPILED PolyC probe object (abi_probe.o, produced by ./hcc);
 *   - the independent C-only oracle (abi_oracle.c).
 */
#include <stdio.h>
#include <string.h>
#include "ast.h"
#include "list.h"
#include "abi_host.h"

extern I64 AbiHostRegisterAst(Ast *ast);
extern I64 AbiHostRegisterList(List *list);
extern void AbiHostAstArenaTeardown(void);
extern u64 AbiHostAstEpoch(void);
extern void AbiHostSetDomain(u8 domain);
extern I64 OracleAstClassify(Ast *a);
extern I64 OracleListCount(List *l);
extern I64 OracleListAt(List *l, I64 index);

static int g_fail = 0;

static Ast *MakeAddAst(I64 lv, I64 rv) {
    int err = 0;
    Ast *l = astI64Type(lv);
    Ast *r = astI64Type(rv);
    return astBinaryOp(AST_BIN_OP_ADD, l, r, &err);
}

static List *MakeList(I64 n) {
    List *l = listNew();
    I64 i = 0;
    while (i < n) {
        I64 v = (i + 1) * 10;
        listAppend(l, (void *)(u64)v);
        i++;
    }
    return l;
}

static int Check(const char *what, I64 got, I64 want) {
    int ok = (got == want);
    printf("CHECK %-32s got=%lld want=%lld %s\n", what,
           (long long)got, (long long)want, ok ? "OK" : "FAIL");
    if (!ok) g_fail = 1;
    return ok;
}

static int Pristine(void) {
    astMemoryInit();

    Ast *add = MakeAddAst(17, 25);
    I64 ast_tok = AbiHostRegisterAst(add);
    printf("PRISTINE_AST_TOKEN=%lld\n", (long long)ast_tok);
    I64 ast_got = AbiProbeAstClassify(ast_tok);
    I64 ast_want = OracleAstClassify(add);
    printf("PRISTINE_AST_RESULT=%lld ORACLE=%lld\n",
           (long long)ast_got, (long long)ast_want);
    Check("ast_classify_matches_oracle", ast_got, ast_want);

    Ast *plain = astI64Type(7);
    I64 plain_tok = AbiHostRegisterAst(plain);
    Check("literal_class", AbiProbeAstClassify(plain_tok), 100);

    List *list = MakeList(3);
    I64 list_tok = AbiHostRegisterList(list);
    printf("PRISTINE_LIST_TOKEN=%lld\n", (long long)list_tok);
    Check("list_grant", AbiListGrantMutation(list_tok), ABI_OK);

    I64 appended = AbiProbeListAppend(list_tok, 40, 10);
    printf("PRISTINE_LIST_APPEND=%lld\n", (long long)appended);
    Check("list_append_result", appended, 4);
    Check("list_append_count", OracleListCount(list), 4);
    Check("list_append_value", OracleListAt(list, 3), 40);

    I64 replaced = AbiProbeListReplace(list_tok, 1, 99);
    printf("PRISTINE_LIST_REPLACE=%lld\n", (long long)replaced);
    Check("list_replace_result", replaced, 99);
    Check("list_replace_value", OracleListAt(list, 1), 99);
    Check("list_replace_count", OracleListCount(list), 4);

    /* Bounded append refusal is atomic. */
    I64 refused = AbiProbeListAppend(list_tok, 50, 4);
    printf("PRISTINE_LIST_BOUNDED_REFUSAL=%lld\n", (long long)refused);
    Check("bounded_append_refused", refused, -ABI_ATOMICITY_OR_RANGE_FAILURE);
    Check("bounded_append_atomic", OracleListCount(list), 4);

    printf("PRISTINE_STATUS=%s\n", g_fail ? "FAIL" : "PASS");
    return g_fail ? 1 : 0;
}

static int Control(const char *id) {
    astMemoryInit();
    int ok = 0;

    if (strcmp(id, "AB-HD-01") == 0) {
        I64 r = AbiAstKind(0);
        printf("CONTROL=%s DETECTOR=NULL_HANDLE EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_NULL_HANDLE, (long long)r);
        ok = (r == -ABI_NULL_HANDLE);
    } else if (strcmp(id, "AB-HD-02") == 0) {
        I64 ast = AbiHostRegisterAst(MakeAddAst(1, 2));
        I64 r = AbiListLen(ast);
        printf("CONTROL=%s DETECTOR=WRONG_HANDLE_KIND EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_WRONG_HANDLE_KIND, (long long)r);
        ok = (r == -ABI_WRONG_HANDLE_KIND);
    } else if (strcmp(id, "AB-HD-03") == 0) {
        I64 list = AbiHostRegisterList(MakeList(2));
        AbiRelease(list);
        I64 r = AbiListLen(list);
        printf("CONTROL=%s DETECTOR=STALE_OR_RELEASED_HANDLE EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_STALE_OR_RELEASED_HANDLE, (long long)r);
        ok = (r == -ABI_STALE_OR_RELEASED_HANDLE);
    } else if (strcmp(id, "AB-HD-04") == 0) {
        I64 list = AbiHostRegisterList(MakeList(2));
        I64 older = list - (I64)(1u << 16);
        I64 r = AbiListLen(older);
        printf("CONTROL=%s DETECTOR=HANDLE_GENERATION_MISMATCH EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_HANDLE_GENERATION_MISMATCH, (long long)r);
        ok = (r == -ABI_HANDLE_GENERATION_MISMATCH);
    } else if (strcmp(id, "AB-HD-05") == 0) {
        I64 forged = (I64)0xDEADBEEFCAFEF00DULL;
        I64 r = AbiListLen(forged);
        printf("CONTROL=%s DETECTOR=HANDLE_NOT_ISSUED EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_HANDLE_NOT_ISSUED, (long long)r);
        ok = (r == -ABI_HANDLE_NOT_ISSUED);
    } else if (strcmp(id, "AB-HD-06") == 0) {
        Ast *a = astI64Type(3);
        I64 tok = AbiHostRegisterAst(a);
        AbiHostAstArenaTeardown();
        I64 r = AbiAstKind(tok);
        printf("CONTROL=%s DETECTOR=EXPIRED_BORROW_OR_ARENA EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_EXPIRED_BORROW_OR_ARENA, (long long)r);
        ok = (r == -ABI_EXPIRED_BORROW_OR_ARENA);
    } else if (strcmp(id, "AB-HD-07") == 0) {
        I64 list = AbiHostRegisterList(MakeList(1));
        AbiHostSetDomain(2);
        I64 r = AbiListLen(list);
        printf("CONTROL=%s DETECTOR=HANDLE_DOMAIN_MISMATCH EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_HANDLE_DOMAIN_MISMATCH, (long long)r);
        ok = (r == -ABI_HANDLE_DOMAIN_MISMATCH);
    } else if (strcmp(id, "AB-HD-08") == 0) {
        I64 list = AbiHostRegisterList(MakeList(1));
        AbiRelease(list);
        I64 r = AbiRelease(list);
        printf("CONTROL=%s DETECTOR=DOUBLE_RELEASE EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_DOUBLE_RELEASE, (long long)r);
        ok = (r == -ABI_DOUBLE_RELEASE);
    } else if (strcmp(id, "AB-ST-01") == 0) {
        List *l = MakeList(2);
        I64 tok = AbiHostRegisterList(l);
        I64 before = OracleListCount(l);
        I64 r = AbiProbeListAppend(tok, 77, 10);
        int unchanged = (OracleListCount(l) == before);
        printf("CONTROL=%s DETECTOR=MUTATION_WITHOUT_CAPABILITY EXPECTED=%d ACTUAL=%lld STATE_UNCHANGED=%d\n",
               id, -ABI_MUTATION_WITHOUT_CAPABILITY, (long long)r, unchanged);
        ok = (r == -ABI_MUTATION_WITHOUT_CAPABILITY && unchanged);
    } else if (strcmp(id, "AB-ST-02") == 0) {
        List *l = MakeList(3);
        I64 tok = AbiHostRegisterList(l);
        AbiListGrantMutation(tok);
        I64 before = OracleListCount(l);
        I64 r = AbiProbeListReplace(tok, 5, 88);
        int unchanged = (OracleListCount(l) == before);
        printf("CONTROL=%s DETECTOR=ATOMICITY_OR_RANGE_FAILURE EXPECTED=%d ACTUAL=%lld STATE_UNCHANGED=%d\n",
               id, -ABI_ATOMICITY_OR_RANGE_FAILURE, (long long)r, unchanged);
        ok = (r == -ABI_ATOMICITY_OR_RANGE_FAILURE && unchanged);
    } else if (strcmp(id, "AB-ST-03") == 0) {
        I64 tok = AbiHostRegisterList(MakeList(1));
        I64 r = AbiRetainCallback(tok, 1234);
        printf("CONTROL=%s DETECTOR=CALLBACK_LIFETIME_OR_REENTRANCY EXPECTED=%d ACTUAL=%lld\n",
               id, -ABI_CALLBACK_LIFETIME_OR_REENTRANCY, (long long)r);
        ok = (r == -ABI_CALLBACK_LIFETIME_OR_REENTRANCY);
    } else if (strcmp(id, "AB-ST-05") == 0) {
        List *l = MakeList(2);
        I64 tok = AbiHostRegisterList(l);
        AbiListGrantMutation(tok);
        I64 before = OracleListCount(l);
        AbiListFailNextPush(tok);
        I64 r = AbiProbeListAppend(tok, 55, 10);
        int unchanged = (OracleListCount(l) == before);
        printf("CONTROL=%s DETECTOR=HOST_ERROR_NOT_PROPAGATED EXPECTED=%d ACTUAL=%lld STATE_UNCHANGED=%d\n",
               id, -ABI_HOST_ERROR, (long long)r, unchanged);
        ok = (r == -ABI_HOST_ERROR && unchanged);
    } else {
        printf("CONTROL=%s DETECTOR=UNKNOWN_CONTROL\n", id);
        return 2;
    }

    printf("CONTROL_RESULT=%s PASS=%d\n", ok ? "REJECTED_AS_REQUIRED" : "NOT_REJECTED", ok);
    return ok ? 0 : 1;
}

int main(int argc, char **argv) {
    if (argc >= 3 && strcmp(argv[1], "CONTROL") == 0) {
        return Control(argv[2]);
    }
    if (argc >= 2 && strcmp(argv[1], "ARENA") == 0) {
        astMemoryInit();
        Ast *a = astI64Type(11);
        I64 tok = AbiHostRegisterAst(a);
        I64 before = AbiAstKind(tok);
        AbiHostAstArenaTeardown();
        I64 after = AbiAstKind(tok);
        printf("ARENA_BEFORE=%lld AFTER_TEARDOWN=%lld STATUS=%s\n",
               (long long)before, (long long)after,
               (before == AST_LITERAL && after == -ABI_EXPIRED_BORROW_OR_ARENA) ? "PASS" : "FAIL");
        return (before == AST_LITERAL && after == -ABI_EXPIRED_BORROW_OR_ARENA) ? 0 : 1;
    }
    return Pristine();
}
