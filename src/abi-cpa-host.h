/* src/abi-cpa-host.h -- ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01
 *
 * C host side of the production opaque-handle ABI used by the top-level AST
 * visibility decision (src/compile.c, compilePrintAst).
 *
 * Included ONLY by C translation units. The compiled PolyC component
 * (tools/bootstrap/selfhost-abi-compile-print-ast.HC) declares the same
 * functions itself and never sees this header, a pointer, a struct layout
 * or a field offset.
 *
 * The layout and the status values are the frozen ABI v1 with the additive
 * v1.1 delta (fail-closed generation retirement). See
 * evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c1/
 * abi-v11-production-ownership.md.
 */
#ifndef ABI_CPA_HOST_H
#define ABI_CPA_HOST_H

#include "types.h"

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

#define ABI_CPA_VERSION 1

/* Mechanical host entry points. None of them makes a semantic decision about
 * the program being compiled. */
s64 AbiCpaIssueAst(void *ast);
void AbiCpaRetireAst(s64 handle);
s64 AbiAbiVersion(void);

/* The ONE accessor the compiled PolyC component may call. */
s64 AbiCpaAstKind(s64 ast);

/* Public entry point implemented in the COMPILED PolyC object. */
s64 AbiCpaShouldPrintAst(s64 ast);

#endif /* ABI_CPA_HOST_H */
