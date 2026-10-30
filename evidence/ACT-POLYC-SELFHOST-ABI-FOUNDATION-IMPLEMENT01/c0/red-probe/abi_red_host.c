/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c0/red-probe/abi_red_host.c
 *
 * C0 RED probe: the C host. It owns every real Ast/List object, owns the
 * checked handle table, and is the only side that ever sees a C layout.
 *
 * The state objects are the PRODUCTION types (src/ast.h Ast, src/list.h List);
 * no mirror struct is defined.
 *
 * FAIL-CLOSED GENERATION POLICY (frozen at C0):
 *   a slot's 16-bit generation counter is never allowed to wrap into a value
 *   that could alias an earlier live identity.  When the increment would reach
 *   0 the slot is RETIRED permanently and Register() reports
 *   -ABI_SLOT_RETIRED.  A slot is therefore usable for at most 65535
 *   issue/release transitions, and the failure is explicit, not silent.
 */
#include <stdio.h>
#include <string.h>
#include "ast.h"
#include "list.h"
#include "abi_red.h"

#define ABI_MAX_SLOTS 4

#define ABI_KIND_AST   1
#define ABI_KIND_LIST  2

#define ABI_MAGIC      0x5Au
#define ABI_RESERVED   0xC0DEu

typedef struct {
    u8   live;
    u8   retired;
    u8   kind;
    u8   mutable_cap;
    u8   domain;
    u16  generation;
    void *obj;
    u64  epoch;
} AbiSlot;

static AbiSlot g_slots[ABI_MAX_SLOTS];
static u8      g_domain = 1;
static u64     g_ast_epoch = 1;

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
    if (s->retired) return -ABI_SLOT_RETIRED;
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
    while (i < ABI_MAX_SLOTS && (g_slots[i].live || g_slots[i].retired)) i++;
    if (i >= ABI_MAX_SLOTS) return -ABI_OUT_OF_MEMORY;
    AbiSlot *s = &g_slots[i];
    /* Frozen fail-closed transition: refuse to wrap. */
    if ((u32)s->generation + 1u > 0xffffu) {
        s->retired = 1;
        s->live = 0;
        s->obj = NULL;
        return -ABI_SLOT_RETIRED;
    }
    s->kind = kind;
    s->mutable_cap = 0;
    s->domain = g_domain;
    s->generation = (u16)((u32)s->generation + 1u);
    s->obj = obj;
    s->epoch = g_ast_epoch;
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

static List *ListAtNode(List *l, I64 index) {
    I64 i = 0;
    List *it = l->next;
    while (it != l) {
        if (i == index) return it;
        it = it->next;
        i++;
    }
    return NULL;
}

I64 AbiListLen(I64 list) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(list, ABI_KIND_LIST, &s);
    if (rc != ABI_OK) return rc;
    return (I64)listCount((List *)s->obj);
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

I64 AbiListGrantMutation(I64 list) {
    AbiSlot *s = NULL;
    I64 rc = Lookup(list, ABI_KIND_LIST, &s);
    if (rc != ABI_OK) return rc;
    s->mutable_cap = 1;
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
    if (s->retired) return -ABI_SLOT_RETIRED;
    if (!s->live) return -ABI_DOUBLE_RELEASE;
    u16 tok_gen = (u16)((t >> 16) & 0xffffu);
    if (tok_gen != s->generation) return -ABI_HANDLE_GENERATION_MISMATCH;
    s->live = 0;
    s->mutable_cap = 0;
    s->obj = NULL;
    if ((u32)s->generation + 1u > 0xffffu) {
        s->retired = 1;   /* fail closed: the slot is never re-issued */
    } else {
        s->generation = (u16)((u32)s->generation + 1u);
    }
    return ABI_OK;
}

/* ---- host-side fixture entry points ------------------------------------ */

I64 AbiHostRegisterAst(void *ast) { return Register(ast, ABI_KIND_AST); }
I64 AbiHostRegisterList(void *list) { return Register(list, ABI_KIND_LIST); }

void AbiHostAstArenaTeardown(void) {
    astMemoryRelease();
    g_ast_epoch++;
}

void AbiHostSetDomain(u8 domain) { g_domain = domain; }

/* Accelerated near-wrap setup for AI-15: writes a generation value into the
 * slot that owns `handle`, exercising the REAL transition code in Register()
 * and AbiRelease() rather than a fake detector. */
void AbiHostSetGeneration(I64 handle, u16 generation) {
    u64 t = (u64)handle;
    u32 idx1 = (u32)((t >> 40) & 0xffu);
    if (idx1 == 0 || idx1 > ABI_MAX_SLOTS) return;
    g_slots[idx1 - 1].generation = generation;
}

I64 AbiHostRetireAllSlots(void) {
    u32 i;
    for (i = 0; i < ABI_MAX_SLOTS; i++) {
        g_slots[i].live = 0;
        g_slots[i].retired = 0;
        g_slots[i].obj = NULL;
        g_slots[i].mutable_cap = 0;
        g_slots[i].domain = g_domain;
        g_slots[i].generation = 0;
    }
    return ABI_OK;
}

I64 AbiHostSlotCount(void) { return (I64)ABI_MAX_SLOTS; }

I64 AbiHostOldestLiveGeneration(void) {
    u32 i;
    for (i = 0; i < ABI_MAX_SLOTS; i++)
        if (g_slots[i].live) return (I64)g_slots[i].generation;
    return -1;
}
