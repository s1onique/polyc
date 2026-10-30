/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe/abi_host.c
 *
 * ABI v1: the C host. It owns every real Ast/List/AoStr/Arena object,
 * owns the checked handle table, and is the only side that ever sees a
 * C layout. The PolyC side receives opaque 64-bit tokens and negative
 * status codes.
 *
 * The state objects are the PRODUCTION types: src/ast.h Ast/AstType,
 * src/list.h List, src/arena.h Arena. No mirror struct is defined.
 */
#include <stdio.h>
#include <string.h>
#include "ast.h"
#include "list.h"
#include "aostr.h"
#include "arena.h"
#include "abi_host.h"

#define ABI_MAX_SLOTS 64

#define ABI_KIND_AST   1
#define ABI_KIND_LIST  2

#define ABI_MAGIC      0x5Au
#define ABI_RESERVED   0xC0DEu

typedef struct {
    u8   live;
    u8   kind;
    u8   mutable_cap;
    u8   domain;
    u16  generation;
    u16  flags;
    void *obj;
    u64  epoch;
} AbiSlot;

static AbiSlot g_slots[ABI_MAX_SLOTS];
static u8 g_domain = 1;
static u64 g_ast_epoch = 1;
static int g_fail_next_push = 0;

static u64 Encode(u32 idx, u8 kind, u16 gen, u8 domain) {
    return ((u64)ABI_RESERVED << 48) |
           ((u64)(idx + 1) << 40) |
           ((u64)kind << 32) |
           ((u64)gen << 16) |
           ((u64)domain << 8) |
           (u64)ABI_MAGIC;
}

/* Structural validation + liveness/kind/generation/domain/epoch checks.
 * NOTHING is dereferenced before this returns ABI_OK. */
static I64 Lookup(I64 token, u8 expect_kind, AbiSlot **out) {
    if (token == 0) return -ABI_NULL_HANDLE;

    u64 t = (u64)token;
    if ((u8)(t & 0xffu) != ABI_MAGIC) return -ABI_HANDLE_NOT_ISSUED;
    if ((u16)((t >> 48) & 0xffffu) != ABI_RESERVED) return -ABI_HANDLE_NOT_ISSUED;

    u32 idx1 = (u32)((t >> 40) & 0xffu);
    if (idx1 == 0 || idx1 > ABI_MAX_SLOTS) return -ABI_HANDLE_NOT_ISSUED;
    u32 idx = idx1 - 1;

    u8  tok_domain = (u8)((t >> 8) & 0xffu);
    u16 tok_gen    = (u16)((t >> 16) & 0xffffu);
    u8  tok_kind   = (u8)((t >> 32) & 0xffu);

    AbiSlot *s = &g_slots[idx];
    if (tok_domain != g_domain || s->domain != g_domain)
        return -ABI_HANDLE_DOMAIN_MISMATCH;
    if (tok_kind != s->kind) return -ABI_WRONG_HANDLE_KIND;
    if (expect_kind != 0 && s->kind != expect_kind)
        return -ABI_WRONG_HANDLE_KIND;
    if (!s->live) return -ABI_STALE_OR_RELEASED_HANDLE;
    if (tok_gen != s->generation) return -ABI_HANDLE_GENERATION_MISMATCH;
    if (s->kind == ABI_KIND_AST && s->epoch != g_ast_epoch)
        return -ABI_EXPIRED_BORROW_OR_ARENA;

    *out = s;
    return ABI_OK;
}

static I64 Register(void *obj, u8 kind) {
    u32 i = 0;
    while (i < ABI_MAX_SLOTS && g_slots[i].live) i++;
    if (i >= ABI_MAX_SLOTS) return -ABI_OUT_OF_MEMORY;
    AbiSlot *s = &g_slots[i];
    s->kind = kind;
    s->mutable_cap = 0;
    s->domain = g_domain;
    s->generation = (u16)(s->generation + 1u);
    if (s->generation == 0) s->generation = 1;
    s->obj = obj;
    s->epoch = g_ast_epoch;
    s->flags = 0;
    s->live = 1;
    return (I64)Encode(i, kind, s->generation, s->domain);
}

I64 AbiAbiVersion(void) { return ABI_ABI_VERSION; }

I64 AbiAstKind(I64 ast) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(ast, ABI_KIND_AST, &s);
    if (rc != ABI_OK) return rc;
    return (I64)((Ast *)s->obj)->kind;
}

I64 AbiAstBinOp(I64 ast) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(ast, ABI_KIND_AST, &s);
    if (rc != ABI_OK) return rc;
    Ast *a = (Ast *)s->obj;
    if (a->kind != AST_BINOP) return -ABI_WRONG_HANDLE_KIND;
    return (I64)a->binop;
}

static Ast *AstChild(Ast *a, I64 which) {
    if (which == 0) return a->left;
    if (which == 1) return a->right;
    return NULL;
}

I64 AbiAstChildKind(I64 ast, I64 which) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(ast, ABI_KIND_AST, &s);
    if (rc != ABI_OK) return rc;
    Ast *a = (Ast *)s->obj;
    if (a->kind != AST_BINOP) return -ABI_WRONG_HANDLE_KIND;
    if (which != 0 && which != 1) return -ABI_ATOMICITY_OR_RANGE_FAILURE;
    Ast *c = AstChild(a, which);
    if (c == NULL) return -ABI_NULL_HANDLE;
    return (I64)c->kind;
}

I64 AbiAstChildI64(I64 ast, I64 which) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(ast, ABI_KIND_AST, &s);
    if (rc != ABI_OK) return rc;
    Ast *a = (Ast *)s->obj;
    if (a->kind != AST_BINOP) return -ABI_WRONG_HANDLE_KIND;
    if (which != 0 && which != 1) return -ABI_ATOMICITY_OR_RANGE_FAILURE;
    Ast *c = AstChild(a, which);
    if (c == NULL) return -ABI_NULL_HANDLE;
    if (c->kind != AST_LITERAL) return -ABI_WRONG_HANDLE_KIND;
    return (I64)c->i64;
}

I64 AbiListLen(I64 list) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(list, ABI_KIND_LIST, &s);
    if (rc != ABI_OK) return rc;
    return (I64)listCount((List *)s->obj);
}

static List *ListAtNode(List *head, I64 index) {
    I64 i = 0;
    List *it = head->next;
    while (it != head) {
        if (i == index) return it;
        i++;
        it = it->next;
    }
    return NULL;
}

I64 AbiListAt(I64 list, I64 index) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(list, ABI_KIND_LIST, &s);
    if (rc != ABI_OK) return rc;
    if (index < 0) return -ABI_ATOMICITY_OR_RANGE_FAILURE;
    List *n = ListAtNode((List *)s->obj, index);
    if (n == NULL) return -ABI_ATOMICITY_OR_RANGE_FAILURE;
    return (I64)(u64)n->value;
}

I64 AbiListPush(I64 list, I64 value) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(list, ABI_KIND_LIST, &s);
    if (rc != ABI_OK) return rc;
    if (!s->mutable_cap) return -ABI_MUTATION_WITHOUT_CAPABILITY;
    if (g_fail_next_push) {
        g_fail_next_push = 0;
        return -ABI_HOST_ERROR;
    }
    listAppend((List *)s->obj, (void *)(u64)value);
    return ABI_OK;
}

I64 AbiListSet(I64 list, I64 index, I64 value) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(list, ABI_KIND_LIST, &s);
    if (rc != ABI_OK) return rc;
    if (!s->mutable_cap) return -ABI_MUTATION_WITHOUT_CAPABILITY;
    if (index < 0) return -ABI_ATOMICITY_OR_RANGE_FAILURE;
    List *n = ListAtNode((List *)s->obj, index);
    if (n == NULL) return -ABI_ATOMICITY_OR_RANGE_FAILURE;
    n->value = (void *)(u64)value;
    return ABI_OK;
}

I64 AbiRelease(I64 handle) {
    if (handle == 0) return -ABI_NULL_HANDLE;
    u64 t = (u64)handle;
    if ((u8)(t & 0xffu) != ABI_MAGIC) return -ABI_HANDLE_NOT_ISSUED;
    if ((u16)((t >> 48) & 0xffffu) != ABI_RESERVED) return -ABI_HANDLE_NOT_ISSUED;
    u32 idx1 = (u32)((t >> 40) & 0xffu);
    if (idx1 == 0 || idx1 > ABI_MAX_SLOTS) return -ABI_HANDLE_NOT_ISSUED;
    AbiSlot *s = &g_slots[idx1 - 1];
    u8 tok_domain = (u8)((t >> 8) & 0xffu);
    if (tok_domain != g_domain || s->domain != g_domain)
        return -ABI_HANDLE_DOMAIN_MISMATCH;
    if (!s->live) return -ABI_DOUBLE_RELEASE;
    u16 tok_gen = (u16)((t >> 16) & 0xffffu);
    if (tok_gen != s->generation) return -ABI_HANDLE_GENERATION_MISMATCH;
    s->live = 0;
    s->mutable_cap = 0;
    s->generation = (u16)(s->generation + 1u);
    if (s->generation == 0) s->generation = 1;
    s->obj = NULL;
    return ABI_OK;
}

I64 AbiRetainCallback(I64 handle, I64 fn) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(handle, 0, &s);
    (void)fn;
    if (rc != ABI_OK) return rc;
    /* v1 deliberately has no callback-retention surface: a PolyC function
     * address cannot be proven to outlive the host scope that would store
     * it. The forbidden operation is rejected, not simulated. */
    return -ABI_CALLBACK_LIFETIME_OR_REENTRANCY;
}

I64 AbiListGrantMutation(I64 list) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(list, ABI_KIND_LIST, &s);
    if (rc != ABI_OK) return rc;
    s->mutable_cap = 1;
    return ABI_OK;
}

I64 AbiListFailNextPush(I64 list) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(list, ABI_KIND_LIST, &s);
    if (rc != ABI_OK) return rc;
    g_fail_next_push = 1;
    return ABI_OK;
}

/* Host-side fixture entry points, not part of the PolyC-facing ABI. */
I64 AbiHostRegisterAst(Ast *ast) {
    return Register(ast, ABI_KIND_AST);
}

I64 AbiHostRegisterList(List *list) {
    return Register(list, ABI_KIND_LIST);
}

void AbiHostAstArenaTeardown(void) {
    astMemoryRelease();
    g_ast_epoch++;
}

u64 AbiHostAstEpoch(void) {
    return g_ast_epoch;
}

void AbiHostSetDomain(u8 domain) {
    g_domain = domain;
}
