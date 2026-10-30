/* evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe/abi_host.h
 *
 * ABI v1: C host side. This header is included ONLY by C host/fixture
 * translation units. PolyC never includes it and never sees these
 * structures; the PolyC probe declares the public functions itself and
 * treats every handle as an opaque I64.
 */
#ifndef ABI_FOUNDATION_RECON01_HOST_H
#define ABI_FOUNDATION_RECON01_HOST_H

#include "types.h"

/* The PolyC dialect spells the 64-bit integer I64; the C compiler sources
 * spell it s64. This fixture header bridges the two names for the C side
 * only. PolyC never includes this header. */
typedef s64 I64;

/* ---- public status codes (negative returns; 0/positive = success) ---- */
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
#define ABI_HOST_ERROR_NOT_PROPAGATED      13
#define ABI_HOST_ERROR                     14
#define ABI_OUT_OF_MEMORY                  15

#define ABI_ABI_VERSION 1

/* ---- the full public C surface called from PolyC ---- */
I64 AbiAbiVersion(void);
I64 AbiAstKind(I64 ast);
I64 AbiAstBinOp(I64 ast);
I64 AbiAstChildKind(I64 ast, I64 which);
I64 AbiAstChildI64(I64 ast, I64 which);
I64 AbiListLen(I64 list);
I64 AbiListAt(I64 list, I64 index);
I64 AbiListPush(I64 list, I64 value);
I64 AbiListSet(I64 list, I64 index, I64 value);
I64 AbiRelease(I64 handle);
I64 AbiRetainCallback(I64 handle, I64 fn);
I64 AbiListGrantMutation(I64 list);
I64 AbiListFailNextPush(I64 list);

/* Public C entry points implemented in the COMPILED PolyC object. */
I64 AbiProbeAstClassify(I64 ast);
I64 AbiProbeListAppend(I64 list, I64 value, I64 limit);
I64 AbiProbeListReplace(I64 list, I64 index, I64 value);

#endif /* ABI_FOUNDATION_RECON01_HOST_H */
