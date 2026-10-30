/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c0/probe/stale_fixture.c
 *
 * C0 RED WITNESS 5: a wrong-ownership / stale-handle rejection in an
 * ISOLATED C fixture that uses the real production List type, not a
 * mirror struct.
 *
 * This is deliberately NOT the C2 ABI (which adds generations, domains,
 * arena epochs and kind checks). It proves only the C0 proposition that a
 * released handle can be rejected by an explicit check instead of being
 * dereferenced. Exit 0 means the fixture detected the stale use.
 */
#include <stdio.h>
#include <stdint.h>
#include "list.h"

typedef struct {
    uint32_t live;
    uint32_t generation;
    List *list;
} Slot;

#define MAX_SLOTS 8
static Slot g_slots[MAX_SLOTS];

#define STATUS_OK              0
#define STATUS_NULL_HANDLE     1
#define STATUS_NOT_ISSUED      2
#define STATUS_STALE_OR_RELEASED 3

static uint64_t Issue(uint32_t idx, List *list) {
    g_slots[idx].live = 1;
    g_slots[idx].generation++;
    g_slots[idx].list = list;
    return ((uint64_t)g_slots[idx].generation << 32) | (uint64_t)(idx + 1);
}

static int32_t Lookup(uint64_t token, List **out) {
    if (token == 0) return STATUS_NULL_HANDLE;
    uint32_t idx = (uint32_t)(token & 0xffffffffu) - 1u;
    uint32_t gen = (uint32_t)(token >> 32);
    if (idx >= MAX_SLOTS) return STATUS_NOT_ISSUED;
    if (!g_slots[idx].live) return STATUS_STALE_OR_RELEASED;
    if (g_slots[idx].generation != gen) return STATUS_STALE_OR_RELEASED;
    *out = g_slots[idx].list;
    return STATUS_OK;
}

static int32_t Release(uint64_t token) {
    if (token == 0) return STATUS_NULL_HANDLE;
    uint32_t idx = (uint32_t)(token & 0xffffffffu) - 1u;
    if (idx >= MAX_SLOTS) return STATUS_NOT_ISSUED;
    if (!g_slots[idx].live) return STATUS_STALE_OR_RELEASED;
    g_slots[idx].live = 0;
    g_slots[idx].generation++;
    g_slots[idx].list = NULL;
    return STATUS_OK;
}

int main(void) {
    List *l = listNew();
    listAppend(l, (void *)(uint64_t)7);
    uint64_t token = Issue(0, l);

    List *seen = NULL;
    int32_t before = Lookup(token, &seen);
    printf("BEFORE_RELEASE_STATUS=%d COUNT=%d\n", before, before == 0 ? listCount(seen) : -1);

    int32_t rel = Release(token);
    printf("RELEASE_STATUS=%d\n", rel);

    List *after = NULL;
    int32_t stale = Lookup(token, &after);
    printf("STALE_LOOKUP_STATUS=%d EXPECTED=%d REJECTED=%d\n",
           stale, STATUS_STALE_OR_RELEASED,
           stale == STATUS_STALE_OR_RELEASED);

    uint64_t forged = 0x00000000000000ffULL;
    List *forged_out = NULL;
    int32_t forged_status = Lookup(forged, &forged_out);
    printf("FORGED_LOOKUP_STATUS=%d EXPECTED=%d REJECTED=%d\n",
           forged_status, STATUS_NOT_ISSUED,
           forged_status == STATUS_NOT_ISSUED);

    return (before == 0 && rel == 0 &&
            stale == STATUS_STALE_OR_RELEASED &&
            forged_status == STATUS_NOT_ISSUED) ? 0 : 1;
}
