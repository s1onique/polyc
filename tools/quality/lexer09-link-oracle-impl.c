// tools/quality/lexer09-link-oracle-impl.c
//
// ACT-POLYC-SELFHOST-LEXER04 C2 IMPL -- reference truth for
// the `#link` directive. Mirrors src/lexer.c::lexLink's
// scanning behavior exactly. The reference state is held in
// a static struct; the direct-differential harness invokes
// `OracleScanLinkDirective` for each fixture and compares
// its outputs against BootstrapLinkDirective's.
//
// All state mutations follow src/lexer.c::lexLink line-for-line;
// the only divergence from the production source is that we
// do not allocate an AoStr for the stored name (the
// differential only requires length / kind agreement).

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef long long I64;
typedef unsigned char U8;

#define ORACLE_LINK_OK              0
#define ORACLE_LINK_ERR_MISSING     1
#define ORACLE_LINK_ERR_INVALID     2
#define ORACLE_LINK_ERR_UNTERM_ANG  3
#define ORACLE_LINK_ERR_UNTERM_QUOT 4
#define ORACLE_LINK_ERR_LEX_FAIL    5

/* Tiny lexeme model for the oracle: kind 0 = punct,
 * kind 1 = ident, start/len of the slice in src. */
typedef struct {
    int kind;
    int len;
    const char *start;
} oracle_lexeme_t;

static int oracle_lex(const char *src, I64 src_len, I64 *cursor,
                      oracle_lexeme_t *out)
{
    if (*cursor >= src_len) return 0;
    char c = src[*cursor];
    if (c == '<' || c == '>' || c == '"' || c == ',' || c == ';') {
        out->kind  = 0;
        out->len   = 1;
        out->start = src + *cursor;
        *cursor = *cursor + 1;
        return 1;
    }
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_') {
        I64 i = *cursor;
        while (i < src_len) {
            char d = src[i];
            if ((d >= 'a' && d <= 'z') || (d >= 'A' && d <= 'Z') ||
                (d >= '0' && d <= '9') || d == '_') {
                i = i + 1;
            } else {
                break;
            }
        }
        out->kind  = 1;
        out->len   = (int)(i - *cursor);
        out->start = src + *cursor;
        *cursor = i;
        return 1;
    }
    /* Anything else (digit, operator, etc.) is a 1-byte
     * unknown token. */
    out->kind  = 0;
    out->len   = 1;
    out->start = src + *cursor;
    *cursor = *cursor + 1;
    return 1;
}

/* ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 C2 IMPL -- ABI 6.
 * The oracle now writes the verbatim body bytes into
 * out_target_bytes, mirroring what the PolyC component does.
 * For the angle form this means the oracle must NOT
 * concatenate lexed tokens -- it must walk the original
 * bytes from src[1] to '>' - 1 verbatim, which is the
 * authority contract. The PolyC component does this with
 * a single forward scan; the oracle now does the same. */
I64 OracleScanLinkDirective(const char *src, I64 src_len, I64 flags,
                            unsigned char *out_target_bytes, I64 out_target_cap,
                            I64 *out_target_len,
                            I64 *out_consumed, I64 *out_is_path,
                            I64 *out_stored_len,
                            I64 *out_error)
{
    (void)flags;

    *out_target_len  = 0;
    *out_consumed    = 0;
    *out_is_path     = 0;
    *out_stored_len  = 0;
    *out_error       = ORACLE_LINK_OK;

    if (src_len <= 0) {
        *out_error = ORACLE_LINK_ERR_MISSING;
        return ORACLE_LINK_ERR_MISSING;
    }

    if (src[0] == '"') {
        /* Quoted form. Walk the bytes between quotes verbatim
         * into out_target_bytes. */
        I64 body_start = 1;
        I64 i = 1;
        while (i < src_len) {
            if (src[i] == '\\' && i + 1 < src_len) {
                i = i + 2;
                continue;
            }
            if (src[i] == '"') {
                I64 body_len = i - body_start;
                I64 copy_end = body_len < out_target_cap ? body_len : out_target_cap;
                for (I64 k = 0; k < copy_end; k = k + 1) {
                    out_target_bytes[k] = (unsigned char)src[body_start + k];
                }
                *out_target_len  = body_len;
                *out_stored_len  = body_len;
                *out_consumed    = i + 1;
                *out_is_path     = 1;
                *out_error       = ORACLE_LINK_OK;
                return ORACLE_LINK_OK;
            }
            i = i + 1;
        }
        *out_error = ORACLE_LINK_ERR_UNTERM_QUOT;
        return ORACLE_LINK_ERR_UNTERM_QUOT;
    }

    if (src[0] == '<') {
        /* Angle form. Walk the bytes between '<' and '>' verbatim
         * into out_target_bytes. NO token-by-token concatenation. */
        I64 body_start = 1;
        I64 i = 1;
        while (i < src_len) {
            if (src[i] == '>') {
                I64 body_len = i - body_start;
                I64 copy_end = body_len < out_target_cap ? body_len : out_target_cap;
                for (I64 k = 0; k < copy_end; k = k + 1) {
                    out_target_bytes[k] = (unsigned char)src[body_start + k];
                }
                *out_target_len  = body_len;
                *out_stored_len  = body_len;
                *out_consumed    = i + 1;
                *out_error       = ORACLE_LINK_OK;
                return ORACLE_LINK_OK;
            }
            i = i + 1;
        }
        *out_error = ORACLE_LINK_ERR_UNTERM_ANG;
        return ORACLE_LINK_ERR_UNTERM_ANG;
    }

    *out_error = ORACLE_LINK_ERR_INVALID;
    return ORACLE_LINK_ERR_INVALID;
}
