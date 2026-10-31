/* src/abi-cpa-host.c -- ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01
 *
 * The C host of the production opaque-handle ABI.
 *
 * RESPONSIBILITIES (mechanical only):
 *   - own the checked handle table;
 *   - issue / validate / retire opaque I64 tokens;
 *   - dereference the real Ast on behalf of PolyC and return one scalar field;
 *   - translate its own failures into negative status codes.
 *
 * This file does NOT decide which AST kinds are printed. That decision lives in
 * the compiled PolyC subject (tools/bootstrap/selfhost-abi-compile-print-ast.HC).
 * There is deliberately NO mutation entry point here: the borrowed state is
 * read-only, and C owns every allocation, the AST arena and the node list.
 *
 * FAIL-CLOSED GENERATION POLICY: the 16-bit generation counter never wraps to a
 * value that could alias an earlier identity; the slot is retired instead
 * (-ABI_SLOT_RETIRED). A slot is usable for at most 65535 issue/release
 * transitions.
 *
 * The handle table is BOUNDED. When every slot is live or retired, issue
 * fails closed with -ABI_OUT_OF_MEMORY: the caller MUST surface that as an
 * error, never silently skip or silently print a node.
 *
 * Derived from the frozen IMPLEMENT01 shadow host
 * (evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c2/shadow-patch.diff,
 * src/abi-cpa-host.c), with the fixture-only test hooks removed: the
 * production host exposes no hook that could alter a slot's domain,
 * generation or liveness from outside.
 */
#include "abi-cpa-host.h"
#include "ast.h"

#define ABI_CPA_MAX_SLOTS 64

#define ABI_CPA_KIND_AST  1

#define ABI_CPA_MAGIC     0x5Au
#define ABI_CPA_RESERVED  0xC0DEu

typedef struct {
    u8   live;
    u8   retired;
    u8   kind;
    u8   domain;
    u16  generation;
    void *obj;
    u64  epoch;
} AbiCpaSlot;

static AbiCpaSlot g_cpa_slots[ABI_CPA_MAX_SLOTS];
static u8  g_cpa_domain = 1;
static u64 g_cpa_ast_epoch = 1;

static u64 AbiCpaEncode(u32 idx, u8 kind, u16 gen, u8 domain) {
    return ((u64)ABI_CPA_RESERVED << 48) |
           ((u64)(idx + 1) << 40) |
           ((u64)kind << 32) |
           ((u64)gen << 16) |
           ((u64)domain << 8) |
           (u64)ABI_CPA_MAGIC;
}

/* Structural validation + liveness/kind/generation/domain/epoch checks.
 * NOTHING is dereferenced before this returns ABI_OK. */
static s64 AbiCpaLookup(s64 token, u8 expect_kind, AbiCpaSlot **out) {
    u64 t;
    u32 idx1, idx;
    u8 tok_domain, tok_kind;
    u16 tok_gen;
    AbiCpaSlot *s;

    if (token == 0) return -ABI_NULL_HANDLE;

    t = (u64)token;
    if ((u8)(t & 0xffu) != ABI_CPA_MAGIC) return -ABI_HANDLE_NOT_ISSUED;
    if ((u16)((t >> 48) & 0xffffu) != ABI_CPA_RESERVED) return -ABI_HANDLE_NOT_ISSUED;

    idx1 = (u32)((t >> 40) & 0xffu);
    if (idx1 == 0 || idx1 > ABI_CPA_MAX_SLOTS) return -ABI_HANDLE_NOT_ISSUED;
    idx = idx1 - 1;

    tok_domain = (u8)((t >> 8) & 0xffu);
    tok_gen    = (u16)((t >> 16) & 0xffffu);
    tok_kind   = (u8)((t >> 32) & 0xffu);

    s = &g_cpa_slots[idx];
    if (tok_domain != g_cpa_domain || s->domain != g_cpa_domain)
        return -ABI_HANDLE_DOMAIN_MISMATCH;
    if (s->retired) return -ABI_SLOT_RETIRED;
    if (tok_kind != s->kind) return -ABI_WRONG_HANDLE_KIND;
    if (expect_kind != 0 && s->kind != expect_kind) return -ABI_WRONG_HANDLE_KIND;
    if (!s->live) return -ABI_STALE_OR_RELEASED_HANDLE;
    if (tok_gen != s->generation) return -ABI_HANDLE_GENERATION_MISMATCH;
    if (s->kind == ABI_CPA_KIND_AST && s->epoch != g_cpa_ast_epoch)
        return -ABI_EXPIRED_BORROW_OR_ARENA;

    *out = s;
    return ABI_OK;
}

s64 AbiAbiVersion(void) { return ABI_CPA_VERSION; }

s64 AbiCpaIssueAst(void *ast) {
    u32 i = 0;
    AbiCpaSlot *s;

    if (ast == NULL) return -ABI_NULL_HANDLE;
    while (i < ABI_CPA_MAX_SLOTS && (g_cpa_slots[i].live || g_cpa_slots[i].retired)) i++;
    /* FAIL CLOSED: the bounded table is exhausted. The caller must surface
     * this as an error; it must never silently skip or silently print. */
    if (i >= ABI_CPA_MAX_SLOTS) return -ABI_OUT_OF_MEMORY;

    s = &g_cpa_slots[i];
    /* FAIL CLOSED: the generation counter is never wrapped into a value
     * that could alias an earlier identity. The slot is retired instead. */
    if ((u32)s->generation + 1u > 0xffffu) {
        s->retired = 1;
        s->live = 0;
        s->obj = NULL;
        return -ABI_SLOT_RETIRED;
    }
    s->kind = ABI_CPA_KIND_AST;
    s->domain = g_cpa_domain;
    s->generation = (u16)((u32)s->generation + 1u);
    s->obj = ast;
    s->epoch = g_cpa_ast_epoch;
    s->live = 1;
    return (s64)AbiCpaEncode(i, ABI_CPA_KIND_AST, s->generation, s->domain);
}

static s64 AbiCpaReleaseInternal(s64 handle);
void AbiCpaRetireAst(s64 handle) { (void)AbiCpaReleaseInternal(handle); }

s64 AbiCpaAstKind(s64 ast) {
    AbiCpaSlot *s = NULL;
    s64 rc = AbiCpaLookup(ast, ABI_CPA_KIND_AST, &s);
    if (rc != ABI_OK) return rc;
    /* MECHANICAL READ ONLY: the host reports the kind value. It does not
     * classify it, does not compare it against any threshold and does not
     * decide whether the node is printed. */
    return (s64)((Ast *)s->obj)->kind;
}

static s64 AbiCpaReleaseInternal(s64 handle) {
    u64 t;
    u32 idx1, idx;
    AbiCpaSlot *s;
    u8 tok_domain;
    u16 tok_gen;

    if (handle == 0) return -ABI_NULL_HANDLE;
    t = (u64)handle;
    if ((u8)(t & 0xffu) != ABI_CPA_MAGIC) return -ABI_HANDLE_NOT_ISSUED;

    idx1 = (u32)((t >> 40) & 0xffu);
    if (idx1 == 0 || idx1 > ABI_CPA_MAX_SLOTS) return -ABI_HANDLE_NOT_ISSUED;
    idx = idx1 - 1;

    tok_domain = (u8)((t >> 8) & 0xffu);
    tok_gen    = (u16)((t >> 16) & 0xffffu);

    s = &g_cpa_slots[idx];
    if (tok_domain != g_cpa_domain || s->domain != g_cpa_domain)
        return -ABI_HANDLE_DOMAIN_MISMATCH;
    if (s->retired) return -ABI_SLOT_RETIRED;
    if (!s->live) return -ABI_DOUBLE_RELEASE;
    if (tok_gen != s->generation) return -ABI_HANDLE_GENERATION_MISMATCH;

    s->live = 0;
    s->obj = NULL;
    /* The generation counter is advanced so that a stale token can never
     * alias this slot again. It is never wrapped to a previously valid
     * value: the slot is retired once the counter would overflow. */
    if ((u32)s->generation + 1u > 0xffffu) {
        s->retired = 1;
        s->generation = 0xffffu;
    } else {
        s->generation = (u16)((u32)s->generation + 1u);
    }
    return ABI_OK;
}
