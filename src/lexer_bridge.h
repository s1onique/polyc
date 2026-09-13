#ifndef LEXER_BRIDGE_H
#define LEXER_BRIDGE_H

/*
 * src/lexer_bridge.h
 *
 * ACT-POLYC-BOOTSTRAP02 C2 IMPL — declaration-only bridge
 * between the production C lexer (src/lexer.c) and the B1
 * PolyC component (tools/bootstrap/bootstrap02-ident.HC).
 *
 * SCOPE: declaration only. No definition, no inline body,
 * no static data. The single declaration below is the
 * ONLY symbol this header exposes.
 *
 * The B1 component is compiled by stage0 hcc to a separate
 * object (build/bootstrap02-ident.o) and linked into the
 * stage1 binary (build/hcc-bootstrap02). The production
 * ./hcc binary is NOT modified by the link; it remains the
 * stage0 self-host reference.
 *
 * ABI (binding, frozen; see
 * evidence/ACT-POLYC-BOOTSTRAP02/c1/abi-witness.txt):
 *
 *   I64 BootstrapScanIdent(
 *       U8  *src,        // caller-owned, read-only
 *       I64  src_len,    // explicit byte length
 *       I64  start,      // cursor into src
 *       I64 *out_end     // first byte after identifier
 *   );
 *
 *   Returns 1 on success, 0 on invalid input.
 *   On success: *out_end = start + N (N >= 1).
 *   No source mutation, no globals, no allocation.
 *
 * CHARACTER DOMAIN (binding):
 *
 *   B1_IDENTIFIER_CHARACTER_DOMAIN = ASCII
 *   B1_CTYPE_DEPENDENCY            = NONE
 *   B1_NON_ASCII_EQUIVALENCE       = NOT_CLAIMED
 *
 *   The component uses explicit ASCII byte range comparisons
 *   and does NOT depend on <ctype.h>. See
 *   ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01 §1.P1.
 *
 * The matching C declaration uses `long long` (== PolyC I64)
 * and `unsigned char *` (== PolyC U8 *). The out-parameter
 * ABI has been mechanically proven via
 * tools/quality/bootstrap02-abi-probe.HC (15-fixture ABI
 * witness at c1/abi-witness.txt).
 */

#include <stdint.h>

extern long long BootstrapScanIdent(unsigned char *src,
                                    long long src_len,
                                    long long start,
                                    long long *out_end);

#endif /* LEXER_BRIDGE_H */
