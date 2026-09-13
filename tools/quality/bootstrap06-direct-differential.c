// tools/quality/bootstrap06-direct-differential.c
//
// ACT-POLYC-SELFHOST-LEXER01 C2 — direct differential test.
//
// Links the C oracle AND the PolyC component (compiled to a
// .o file) and compares every observable field for all 47
// fixtures. Same fixture matrix as the oracle.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

extern long long BootstrapClassifyOperator(
    unsigned char *src,
    long long src_len,
    long long cursor,
    long long flags,
    long long *out_kind,
    long long *out_length);

/* The C oracle body is inlined here (copy of
 * tools/quality/bootstrap06-operator-classify-oracle.c) so we
 * don't need a separate C object. */

#define CCF_ASM_BLOCK     (1 << 16)
#define CCF_MULTI_COLON   (1 << 17)
typedef long long I64;

static int is_op_trigger(unsigned char c)
{
    switch (c) {
        case '=': case '<': case '>':
        case '+': case '-': case '!':
        case '&': case '|': case '*':
        case '%': case '^':
        case '$': case '@':
        case '.':
        case '\\':
        case ':':
        case '#':
        case '~':
        case '(': case ')':
        case ',': case ';':
        case '[': case ']':
        case '{': case '}':
        case '/':
            return 1;
    }
    return 0;
}

static int c_classify(const unsigned char *src,
                      long long src_len,
                      long long cursor,
                      long long flags,
                      I64 *out_kind,
                      I64 *out_length)
{
    if (src == NULL)               return 0;
    if (out_kind == NULL)          return 0;
    if (out_length == NULL)        return 0;
    if (cursor < 0)                return 0;
    if (cursor >= src_len)         return 0;
    unsigned char ch = src[cursor];
    if (!is_op_trigger(ch))        return 0;
    #define P1 ((cursor + 1 < src_len) ? (unsigned char)src[cursor + 1] : 0)
    #define P2 ((cursor + 2 < src_len) ? (unsigned char)src[cursor + 2] : 0)
    switch (ch) {
        case '=': {
            if (P1 == '=') { *out_kind = 0x30B; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '<': {
            if (P1 == '=') { *out_kind = 0x30D; *out_length = 2; }
            else if (P1 == '<') {
                if (P2 == '=') { *out_kind = 0x312; *out_length = 3; }
                else { *out_kind = 0x309; *out_length = 2; }
            } else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '>': {
            if (P1 == '=') { *out_kind = 0x30E; *out_length = 2; }
            else if (P1 == '>') {
                if (P2 == '=') { *out_kind = 0x313; *out_length = 3; }
                else { *out_kind = 0x30A; *out_length = 2; }
            } else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '+': {
            if (P1 == '+') { *out_kind = 0x305; *out_length = 2; }
            else if (P1 == '=') { *out_kind = 0x319; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '-': {
            if (P1 == '-') { *out_kind = 0x306; *out_length = 2; }
            else if (P1 == '>') { *out_kind = 0x328; *out_length = 2; }
            else if (P1 == '=') { *out_kind = 0x31A; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '!': {
            if (P1 == '=') { *out_kind = 0x30C; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '&': {
            if (P1 == '&') { *out_kind = 0x30F; *out_length = 2; }
            else if (P1 == '=') { *out_kind = 0x316; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '|': {
            if (P1 == '|') { *out_kind = 0x310; *out_length = 2; }
            else if (P1 == '=') { *out_kind = 0x317; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '*': {
            if (P1 == '=') { *out_kind = 0x314; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '%': {
            if (P1 == '=') { *out_kind = 0x322; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '^': {
            if (P1 == '=') { *out_kind = 0x318; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '$':
        case '@':
        case '#': {
            if (!(flags & CCF_ASM_BLOCK)) return 0;
            *out_kind = (I64)ch; *out_length = 1;
            return 1;
        }
        case '.': {
            if (cursor + 1 < src_len) {
                unsigned char p1 = (unsigned char)src[cursor + 1];
                if (p1 >= '0' && p1 <= '9') return 0;
                if (p1 == '.') {
                    if (cursor + 2 < src_len &&
                        (unsigned char)src[cursor + 2] == '.') {
                        *out_kind = 0x324; *out_length = 3;
                        return 1;
                    }
                    return 0;
                }
            }
            *out_kind = (I64)ch; *out_length = 1;
            return 1;
        }
        case '\\': {
            *out_kind = (I64)ch; *out_length = 1;
            return 1;
        }
        case ':': {
            if ((flags & CCF_MULTI_COLON) && P1 == ':') {
                *out_kind = 0x308; *out_length = 2;
            } else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
        case '~':
        case '(':
        case ')':
        case ',':
        case ';':
        case '[':
        case ']':
        case '{':
        case '}': {
            *out_kind = (I64)ch; *out_length = 1;
            return 1;
        }
        case '/': {
            if (P1 == '=') { *out_kind = 0x315; *out_length = 2; }
            else { *out_kind = (I64)ch; *out_length = 1; }
            return 1;
        }
    }
    return 0;
    #undef P1
    #undef P2
}

typedef struct {
    const char *id;
    const char *input;
    long long   cursor;
    long long   flags;
} Fix;

static Fix FIXTURES[] = {
    { "O01", "(",  0, 0 },
    { "O02", ")",  0, 0 },
    { "O03", "[",  0, 0 },
    { "O04", "]",  0, 0 },
    { "O05", "{",  0, 0 },
    { "O06", "}",  0, 0 },
    { "O07", ",",  0, 0 },
    { "O08", ";",  0, 0 },
    { "O09", "~",  0, 0 },
    { "O10", "=",  0, 0 },
    { "O11", "<",  0, 0 },
    { "O12", ">",  0, 0 },
    { "O13", "+",  0, 0 },
    { "O14", "-",  0, 0 },
    { "O15", "!",  0, 0 },
    { "O16", "&",  0, 0 },
    { "O17", "|",  0, 0 },
    { "O18", "*",  0, 0 },
    { "O19", "%",  0, 0 },
    { "O20", "^",  0, 0 },
    { "O21", "==", 0, 0 },
    { "O22", "<=", 0, 0 },
    { "O23", "<<", 0, 0 },
    { "O24", "<<=",0, 0 },
    { "O25", ">=", 0, 0 },
    { "O26", ">>", 0, 0 },
    { "O27", ">>=",0, 0 },
    { "O28", "++", 0, 0 },
    { "O29", "+=", 0, 0 },
    { "O30", "--", 0, 0 },
    { "O31", "->", 0, 0 },
    { "O32", "-=", 0, 0 },
    { "O33", "abc==def", 3, 0 },
    { "O34", "abc+",     3, 0 },
    { "N01", "abc",      0, 0 },
    { "N02", "",         0, 0 },
    { "N03", "abc",      3, 0 },
    { "N04", "9abc",     0, 0 },
    { "N05", ".5",       0, 0 },
    { "N06", "..",       0, 0 },
    { "N07", "$x",       0, 0 },
    { "O35", "$x",       0, CCF_ASM_BLOCK },
    { "O36", "::",       0, CCF_MULTI_COLON },
    { "O37", ":",        0, 0 },
    { "O38", "...",      0, 0 },
    { "O39", ".",        0, 0 },
    { "O40", "\\",       0, 0 },
};

int main(int argc, char **argv)
{
    (void)argc; (void)argv;
    int pass = 0, fail = 0;
    int n = (int)(sizeof(FIXTURES) / sizeof(FIXTURES[0]));

    for (int i = 0; i < n; i++) {
        Fix *f = &FIXTURES[i];
        long long src_len = (long long)strlen(f->input);

        I64 c_kind = 0, c_length = 0, p_kind = 0, p_length = 0;
        int c_rc = c_classify((const unsigned char *)f->input,
                              src_len, f->cursor, f->flags,
                              &c_kind, &c_length);
        int p_rc = (int)BootstrapClassifyOperator(
                              (unsigned char *)f->input,
                              src_len, f->cursor, f->flags,
                              &p_kind, &p_length);

        int this_pass = 1;
        if (c_rc != p_rc) this_pass = 0;
        if (c_rc == 1) {
            if (c_kind   != p_kind)   this_pass = 0;
            if (c_length != p_length) this_pass = 0;
        }

        if (this_pass) {
            pass++;
            printf("%s PASS rc=%d kind=0x%llx len=%lld\n",
                   f->id, p_rc,
                   (unsigned long long)p_kind, p_length);
        } else {
            fail++;
            printf("%s FAIL c(rc=%d,kind=0x%llx,len=%lld) "
                   "p(rc=%d,kind=0x%llx,len=%lld)\n",
                   f->id, c_rc,
                   (unsigned long long)c_kind, c_length,
                   p_rc,
                   (unsigned long long)p_kind, p_length);
        }
    }

    printf("ACT_SELFHOST_LEXER01_DIRECT_DIFFERENTIAL_CASES=%d\n", n);
    printf("ACT_SELFHOST_LEXER01_DIRECT_DIFFERENTIAL_PASS=%d\n", pass);
    printf("ACT_SELFHOST_LEXER01_DIRECT_DIFFERENTIAL_FAIL=%d\n", fail);
    if (fail == 0) {
        printf("STATUS=PASS\n");
        return 0;
    } else {
        printf("STATUS=FAIL\n");
        return 1;
    }
}
