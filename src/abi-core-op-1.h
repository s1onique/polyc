/* src/abi-core-op-1.h -- ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01
 *
 * The C host side of the production scalar ABI ABI-CORE-OP-1, used by the
 * three selected core-operator decisions of BUNDLE-OPERATOR-CORE-01:
 *
 *   SITE-COMPOUND-ASSIGN   src/prslib.c  parseCompoundAssign
 *   SITE-VALID-POINTER-OP  src/ast.c     astIsValidPointerOp
 *   SITE-RANGE-OPERATOR    src/ast.c     astIsRangeOperator
 *
 * Included ONLY by C translation units. The compiled PolyC component
 * (tools/bootstrap/selfhost-core-operator.HC) declares the same functions
 * itself and never sees this header, a pointer, a struct layout or a field
 * offset.
 *
 * WHY A HEADER IS NEEDED
 * ----------------------
 * The three call sites live in TWO translation units (src/prslib.c and
 * src/ast.c) and the selector must be able to COMPILE THE LEGACY C
 * PREDICATE OUT of both of them. A declaration is therefore needed in each
 * consuming TU so that the selector-ON arm can call the subject.
 *
 * THE ABI IS SCALAR-ONLY
 * ----------------------
 * No raw Ast*, Lexeme*, List*, Map*, Cctrl*, Arena* or pointer-bitcast
 * handle crosses this boundary. The out-parameter of
 * AbiCoreClassifyCompoundAssign is ONE host-owned s64 cell; the subject
 * writes a single scalar into it and never reads host layout through it.
 *
 * The exact contract is frozen in
 * evidence/ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01/c1/abi-core-op-1.tsv.
 */
#ifndef ABI_CORE_OP_1_H
#define ABI_CORE_OP_1_H

#include "types.h"

/* The three exported decisions of the compiled PolyC subject.
 *
 * Every function returns a value in {0,1}. A NEGATIVE return value is a
 * reserved host status code and is disjoint from {0,1}; the subject is
 * TOTAL over the whole s64 domain, so the status range is never produced.
 *
 * AbiCoreClassifyCompoundAssign writes *out_operator ONLY when it returns
 * 1. The operator value is deliberately NOT the return value, because
 * AST_BIN_OP_MUL is 0 and would collide with the "not a compound
 * assignment" result 0.
 */
s64 AbiCoreClassifyCompoundAssign(s64 token_type, s64 token_value, s64 *out_operator);
s64 AbiCoreIsValidPointerOperator(s64 binary_operator);
s64 AbiCoreIsRangeOperator(s64 binary_operator);

#endif /* ABI_CORE_OP_1_H */
