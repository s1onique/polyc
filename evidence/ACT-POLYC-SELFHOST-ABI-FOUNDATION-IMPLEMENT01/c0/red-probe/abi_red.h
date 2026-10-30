/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c0/red-probe/abi_red.h
 *
 * C0 RED probe: the C-visible surface. Included ONLY by C translation units of
 * this probe. The compiled PolyC subject declares the same functions itself and
 * never sees this header, a pointer, a struct layout or a field offset.
 */
#ifndef ABI_IMPLEMENT01_RED_H
#define ABI_IMPLEMENT01_RED_H

#include "types.h"

typedef s64 I64;

/* Negative statuses. 0/positive is success. */
#define ABI_OK                              0
#define ABI_NULL_HANDLE                     1
#define ABI_WRONG_HANDLE_KIND               2
#define ABI_STALE_OR_RELEASED_HANDLE        3
#define ABI_HANDLE_GENERATION_MISMATCH      4
#define ABI_HANDLE_NOT_ISSUED               5
#define ABI_HANDLE_DOMAIN_MISMATCH          6
#define ABI_DOUBLE_RELEASE                  7
#define ABI_EXPIRED_BORROW_OR_ARENA         8
#define ABI_MUTATION_WITHOUT_CAPABILITY     9
#define ABI_ATOMICITY_OR_RANGE_FAILURE     10
#define ABI_CALLBACK_LIFETIME_OR_REENTRANCY 11
#define ABI_CROSS_FRAME_RECOVERY_UNSAFE    12
#define ABI_HOST_ERROR                     14
#define ABI_OUT_OF_MEMORY                  15
#define ABI_TOKEN_DOMAIN_EXHAUSTED         16
#define ABI_SLOT_RETIRED                   17

#define ABI_ABI_VERSION 1

/* Host accessors called FROM the compiled PolyC subject. */
I64 AbiAstKind(I64 ast);
I64 AbiListLen(I64 list);
I64 AbiListAt(I64 list, I64 index);
I64 AbiListPush(I64 list, I64 value);
I64 AbiListSet(I64 list, I64 index, I64 value);
I64 AbiListGrantMutation(I64 list);
I64 AbiRelease(I64 handle);
I64 AbiAbiVersion(void);

/* Public entry points implemented in the COMPILED PolyC object. */
I64 AbiRedShouldPrint(I64 ast);
I64 AbiRedListAppendBounded(I64 list, I64 value, I64 limit);

/* Host-side fixture entry points (not part of the PolyC-facing ABI). */
I64 AbiHostRegisterAst(void *ast);
I64 AbiHostRegisterList(void *list);
void AbiHostAstArenaTeardown(void);
void AbiHostSetDomain(u8 domain);
void AbiHostSetGeneration(I64 handle, u16 generation);
I64 AbiHostRetireAllSlots(void);
I64 AbiHostSlotCount(void);
I64 AbiHostOldestLiveGeneration(void);

#endif /* ABI_IMPLEMENT01_RED_H */
