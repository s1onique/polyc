#ifndef LEXER_BRIDGE_H
#define LEXER_BRIDGE_H

/*
 * src/lexer_bridge.h
 *
 * Declaration-only bridge between the production C lexer
 * (src/lexer.c) and the PolyC self-host components.
 *
 * SCOPE: declaration only. No definition, no inline body,
 * no static data. The declarations below are the ONLY
 * symbols this header exposes.
 *
 * Two PolyC components are linked into the stage1+ binaries
 * (build/hcc-bootstrap02/03/04):
 *
 *   1. identifier_scanner — ACT-POLYC-BOOTSTRAP02
 *      (tools/bootstrap/bootstrap02-ident.HC)
 *
 *   2. operator_punctuation_recognizer — ACT-POLYC-SELFHOST-LEXER01
 *      (tools/bootstrap/selfhost-lexer-operator-classify.HC)
 *
 * The stage0 ./hcc binary does NOT link either component; it
 * uses the legacy C implementation in src/lexer.c.
 *
 * ABI 1 — identifier_scanner (frozen; see
 * evidence/ACT-POLYC-BOOTSTRAP02/c1/abi-witness.txt):
 *
 *   I64 BootstrapScanIdent(
 *       U8  *src,
 *       I64  src_len,
 *       I64  start,
 *       I64 *out_end
 *   );
 *
 *   Returns 1 on success, 0 on invalid input.
 *   On success: *out_end = start + N (N >= 1).
 *   No source mutation, no globals, no allocation.
 *
 *   CHARACTER DOMAIN:
 *     B1_IDENTIFIER_CHARACTER_DOMAIN   = ASCII
 *     B1_CTYPE_DEPENDENCY              = NONE
 *     B1_NON_ASCII_EQUIVALENCE         = NOT_CLAIMED
 *
 * ABI 2 — operator_punctuation_recognizer (frozen; see
 * evidence/ACT-POLYC-SELFHOST-LEXER01/c1/winner-abi-contract.txt):
 *
 *   I64 BootstrapClassifyOperator(
 *       U8  *src,
 *       I64  src_len,
 *       I64  cursor,
 *       I64  flags,
 *       I64 *out_kind,
 *       I64 *out_length
 *   );
 *
 *   Returns 1 if src[cursor] is an operator/punctuation byte;
 *   on success *out_kind and *out_length are populated.
 *   Returns 0 if src[cursor] is NOT an operator/punctuation
 *   byte; the C wrapper falls through to the next dispatcher
 *   arm.
 *
 *   CHARACTER DOMAIN:
 *     B_LEXER_OPERATOR_CHARACTER_DOMAIN     = ASCII
 *     B_LEXER_OPERATOR_CTYPE_DEPENDENCY      = NONE
 *     B_LEXER_OPERATOR_NON_ASCII_EQUIVALENCE = NOT_CLAIMED
 *
 * Generic stage1+ selector (binding):
 *
 *   The production lexer (src/lexer.c) routes through the
 *   PolyC components when compiled with
 *   -DHCC_USE_SELFHOST_COMPONENTS. The legacy macro
 *   -DHCC_BOOTSTRAP02_STAGE1 is preserved as a compatibility
 *   alias and is normalized to HCC_USE_SELFHOST_COMPONENTS
 *   at the source level (see src/lexer.c lexIdentifier).
 *
 *   No runtime legacy fallback. No shadow execution.
 */

#include <stdint.h>

extern long long BootstrapScanIdent(unsigned char *src,
                                    long long src_len,
                                    long long start,
                                    long long *out_end);

extern long long BootstrapClassifyOperator(unsigned char *src,
                                           long long src_len,
                                           long long cursor,
                                           long long flags,
                                           long long *out_kind,
                                           long long *out_length);

#endif /* LEXER_BRIDGE_H */
