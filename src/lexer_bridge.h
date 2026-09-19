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
 *   3. scalar_literal_scanner — ACT-POLYC-SELFHOST-LEXER02
 *      (tools/bootstrap/selfhost-lexer-scalar-literal.HC)
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
 * ABI 3 — scalar_literal_scanner (frozen; see
 * evidence/ACT-POLYC-SELFHOST-LEXER02/c1/region-abi-contract.txt
 * and c2/bridge-delta.txt for the strlen amendment):
 *
 *   I64 BootstrapScanScalarLiteral(
 *       U8  *src,
 *       I64  src_len,
 *       I64  cursor,
 *       I64  flags,
 *       I64 *out_end,
 *       I64 *out_kind,
 *       I64 *out_i64,
 *       U64 *out_f64_bits,
 *       I64 *out_ishex,
 *       I64 *out_error,
 *       I64 *out_strlen
 *   );
 *
 *   Returns one of the SCALAR_* result kinds:
 *     SCALAR_NONE  (0) - cursor does not start a scalar literal;
 *                        *out_end = cursor; no output consumed.
 *     SCALAR_I64   (1) - decimal or hex integer literal
 *     SCALAR_F64   (2) - floating-point literal
 *     SCALAR_CHAR  (3) - character constant
 *     SCALAR_ERROR (4) - malformed (see out_error)
 *
 *   out_error carries one of:
 *     SCALAR_ERR_NONE / MALFORMED_NUMERIC / CHAR_UNTERMINATED
 *     CHAR_OVERFLOW / BAD_ESCAPE / HEX_FLOAT / HEX_EXP / INVALID_BYTE
 *
 *   out_strlen semantics:
 *     - SCALAR_I64 / SCALAR_F64: number of bytes consumed from
 *       cursor (== numlen).
 *     - SCALAR_CHAR: number of character-constant "slots" between
 *       the quotes (each raw char counts 1; each escape sequence
 *       counts 1, regardless of how many bytes the escape sequence
 *       spans). For a char const this is the same value the
 *       legacy lexCharConst writes into `l->cur_strlen` and that
 *       lexCore copies into `le->len`.
 *     - SCALAR_NONE / SCALAR_ERROR: 0.
 *
 *   CHARACTER DOMAIN:
 *     B_LEXER_SCALAR_CHARACTER_DOMAIN     = ASCII
 *     B_LEXER_SCALAR_CTYPE_DEPENDENCY      = NONE (numeric
 *       conversion uses libc strtoll / strtoul / strtod)
 *     B_LEXER_SCALAR_NON_ASCII_EQUIVALENCE = NOT_CLAIMED
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

extern long long BootstrapScanScalarLiteral(unsigned char *src,
                                            long long src_len,
                                            long long cursor,
                                            long long flags,
                                            long long *out_end,
                                            long long *out_kind,
                                            long long *out_i64,
                                            unsigned long long *out_f64_bits,
                                            long long *out_ishex,
                                            long long *out_error,
                                            long long *out_strlen);

/*
 * ABI 4 -- trivia_scanner (frozen; see
 * evidence/ACT-POLYC-SELFHOST-LEXER03/c1/c1-target-behavioral-contract.txt
 * and tools/quality/lexer08-trivia-oracle.c):
 *
 *   I64 BootstrapScanTrivia(
 *       U8  *src,
 *       I64  src_len,
 *       I64  cursor,
 *       I64  flags,
 *       I64 *out_end,
 *       I64 *out_kind,
 *       I64 *out_lineno_delta,
 *       I64 *out_comment_started
 *   );
 *
 * Returns:
 *   0 -- caller should NOT emit a token (NO_OUTPUT)
 *   1 -- caller SHOULD emit a token of kind *out_kind
 *
 * out_kind:
 *   0 (TRIVIA_NONE)    -- no token, but cursor was advanced
 *   1 (TRIVIA_WS)      -- single whitespace byte (' ' or '\t')
 *   2 (TRIVIA_NL)      -- single newline byte ('\n' or '\r')
 *   3 (TRIVIA_COMMENT) -- full comment span consumed
 *
 * out_lineno_delta: number of newline bytes observed inside the
 *                   trivia run (>= 0; equals number of '\n'
 *                   occurrences).
 *
 * out_comment_started: 1 iff the trivia run began with '/' '+ peek
 *                      of '/' or '*' (i.e. a comment-initiated skip).
 *
 * CHARACTER DOMAIN:
 *   B_LEXER_TRIVIA_CHARACTER_DOMAIN      = ASCII
 *   B_LEXER_TRIVIA_CTYPE_DEPENDENCY       = NONE
 *   B_LEXER_TRIVIA_NON_ASCII_EQUIVALENCE  = NOT_CLAIMED
 *
 * Flag bits (matching src/lexer.h CCF_*):
 *   CCF_ACCEPT_NEWLINES    (1 << 2)
 *   CCF_ASM_BLOCK          (1 << 4)
 *   CCF_ACCEPT_WHITESPACE  (1 << 6)
 *   CCF_ACCEPT_COMMENTS    (1 << 7)
 */
extern long long BootstrapScanTrivia(unsigned char *src,
                                     long long src_len,
                                     long long cursor,
                                     long long flags,
                                     long long *out_end,
                                     long long *out_kind,
                                     long long *out_lineno_delta,
                                     long long *out_comment_started);

/*
 * ABI 6 -- link_directive_scanner (frozen; see
 * evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION03/c0/c0-contract.txt
 * and tools/quality/lexer09-link-oracle.c):
 *
 *   I64 BootstrapLinkDirective(
 *       U8  *src,
 *       I64  src_len,
 *       I64  flags,
 *       U8  *out_target_bytes,    // NEW: caller buffer for body bytes
 *       I64  out_target_cap,      // NEW: capacity of out_target_bytes
 *       I64 *out_target_len,      // NEW: bytes written on success
 *       I64 *out_consumed,
 *       I64 *out_is_path,
 *       I64 *out_stored_len,      // kept as alias of *out_target_len
 *       I64 *out_error
 *   );
 *
 * Scans a `#link` directive body (one of:
 *   - quoted path form   "<path>"
 *   - angle-bracket form <name>
 * ) starting at the byte immediately after the `#link` keyword.
 * Returns 0 on success or an error code in [1..5].
 *
 *   0 = LINK_OK
 *   1 = LINK_ERR_MISSING      (no target at all)
 *   2 = LINK_ERR_INVALID_TOK  (first byte isn't '<' or '"')
 *   3 = LINK_ERR_UNTERM_ANG   (no closing '>' before EOF)
 *   4 = LINK_ERR_UNTERM_QUOT  (no closing '"' before EOF)
 *   5 = LINK_ERR_LEX_FAILURE  (any other lex() returning 0)
 *
 * On success:
 *   out_target_bytes[0..*out_target_len-1] holds the verbatim body bytes
 *                     (no surrounding quotes / angle brackets).
 *   *out_consumed   = total bytes consumed from src.
 *   *out_is_path    = 1 if quoted-path form (lands in
 *                     cc->shared_object_files); 0 if
 *                     angle-name form (lands in cc->link_libs).
 *   *out_stored_len = length of body bytes (== *out_target_len).
 *
 * ABI 6 is the ABI 5 surface plus three new output parameters
 * (out_target_bytes, out_target_cap, *out_target_len) that allow
 * the C adapter to construct the AoStr from a guaranteed-correct
 * byte run. This is required because the legacy C adapter
 * concatenates lexed tokens and corrupts complex targets
 * (e.g. lib-complex_1.0 -> lib-complex_1co).
 *
 * CHARACTER DOMAIN:
 *   B_LINK_DIRECTIVE_CHARACTER_DOMAIN     = ASCII
 *   B_LINK_DIRECTIVE_CTYPE_DEPENDENCY      = NONE
 *   B_LINK_DIRECTIVE_NON_ASCII_EQUIVALENCE = NOT_CLAIMED
 */
extern long long BootstrapLinkDirective(unsigned char *src,
                                        long long src_len,
                                        long long flags,
                                        unsigned char *out_target_bytes,
                                        long long out_target_cap,
                                        long long *out_target_len,
                                        long long *out_consumed,
                                        long long *out_is_path,
                                        long long *out_stored_len,
                                        long long *out_error);

#endif /* LEXER_BRIDGE_H */
