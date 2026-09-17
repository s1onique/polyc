// tools/quality/lexer08-trivia-oracle-impl.c
//
// ACT-POLYC-SELFHOST-LEXER03 C2 IMPL -- production trivia
// (comment + whitespace) oracle implementation.
//
// Contains OracleScanTrivia() only. NO main() -- this file is
// linked into other test harnesses (direct differential, real-lexer
// seam runner).
//
// For a standalone selftest harness, see lexer08-trivia-oracle.c.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef long long I64;
typedef unsigned long long U64;
typedef unsigned char U8;

#define TRIVIA_NONE       0
#define TRIVIA_WS         1
#define TRIVIA_NL         2
#define TRIVIA_COMMENT    3

#define TRIVIA_CCF_ASM_BLOCK         (1 << 4)
#define TRIVIA_CCF_ACCEPT_WHITESPACE (1 << 6)
#define TRIVIA_CCF_ACCEPT_NEWLINES   (1 << 2)
#define TRIVIA_CCF_ACCEPT_COMMENTS   (1 << 7)

static U8 oracle_peek(const U8 *src, I64 src_len, I64 pos)
{
    if (pos < 0) return 0;
    if (pos >= src_len) return 0;
    return src[pos];
}

static I64 oracle_skip_code_comment(const U8 *src, I64 src_len, I64 cursor,
                                    I64 *out_end, I64 *out_lineno_delta)
{
    I64 delta = 0;
    I64 p = cursor;
    U8 ch = oracle_peek(src, src_len, p);
    U8 next = oracle_peek(src, src_len, p + 1);
    if (ch != '/' || (next != '/' && next != '*')) {
        *out_end = cursor;
        *out_lineno_delta = 0;
        return -1;
    }
    p += 2;
    if (next == '/') {
        while (p < src_len) {
            U8 b = src[p];
            if (b == '\n') break;
            if (b == 0) break;
            p++;
        }
    } else {
        while (p < src_len) {
            U8 b = src[p];
            if (b == 0) break;
            if (b == '*' && oracle_peek(src, src_len, p + 1) == '/') {
                p += 2;
                *out_end = p;
                *out_lineno_delta = delta;
                return 0;
            }
            if (b == '\n') delta++;
            p++;
        }
    }
    *out_end = p;
    *out_lineno_delta = delta;
    return 0;
}

static I64 oracle_try_whitespace(U8 ch, I64 flags)
{
    if (ch == ' ' || ch == '\t') {
        if (flags & TRIVIA_CCF_ACCEPT_WHITESPACE) return TRIVIA_WS;
        return TRIVIA_NONE;
    }
    if (ch == '\n' || ch == '\r') {
        if (flags & TRIVIA_CCF_ACCEPT_NEWLINES) return TRIVIA_NL;
        return TRIVIA_NONE;
    }
    return -1;
}

I64 OracleScanTrivia(const U8 *src, I64 src_len, I64 cursor, I64 flags,
                     I64 *out_end, I64 *out_kind, I64 *out_lineno_delta,
                     I64 *out_comment_started)
{
    *out_end = cursor;
    *out_kind = TRIVIA_NONE;
    *out_lineno_delta = 0;
    *out_comment_started = 0;
    if (cursor < 0) return 0;
    if (cursor >= src_len) return 0;
    U8 ch = oracle_peek(src, src_len, cursor);
    I64 ws_kind = oracle_try_whitespace(ch, flags);
    if (ws_kind >= 0) {
        I64 nl_delta = 0;
        if (ch == '\n') nl_delta = 1;
        *out_end = cursor + 1;
        *out_kind = ws_kind;
        *out_lineno_delta = nl_delta;
        return ws_kind == TRIVIA_NONE ? 0 : 1;
    }
    I64 comment_end = 0;
    I64 comment_delta = 0;
    I64 rc = oracle_skip_code_comment(src, src_len, cursor,
                                      &comment_end, &comment_delta);
    if (rc >= 0) {
        *out_end = comment_end;
        *out_comment_started = 1;
        *out_lineno_delta = comment_delta;
        if (flags & TRIVIA_CCF_ACCEPT_COMMENTS) {
            *out_kind = TRIVIA_COMMENT;
            return 1;
        }
        *out_kind = TRIVIA_NONE;
        return 0;
    }
    *out_end = cursor;
    *out_kind = TRIVIA_NONE;
    *out_lineno_delta = 0;
    *out_comment_started = 0;
    return 0;
}
