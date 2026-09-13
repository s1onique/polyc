// tools/quality/bootstrap06-operator-classify-oracle.c
//
// ACT-POLYC-SELFHOST-LEXER01 C1 RED — production operator /
// punctuation classification oracle.
//
// Independent C99 reference of EXACTLY the production
// operator/punctuation classification logic from
// src/lexer.c (the lexCore switch cases for =,<,>,+,-,!,&,
// |,*,%,^,$,@,.,\,:,~,comma,brackets,braces,parens,semi,/
// when not comment, # in asm block).
//
// This is NOT a wrapper around the production compiler; it
// is an independent C implementation of the same algorithm,
// parameterised by (src, src_len, cursor, flags, out_kind,
// out_length) so it can be exercised from a standalone
// harness.
//
// The oracle reproduces the production rules:
//   1. If ch is NOT one of the operator trigger bytes,
//      return 0 (not an operator).
//   2. Otherwise, compute (kind, length) exactly as the
//      legacy lexCore would, modulo the following two
//      exceptions that are deliberately NOT part of the
//      winner (they require raises or fall-through that the
//      PolyC component will not own):
//        - `..` not followed by `.`     -> legacy raises
//        - `$` / `@` / `#` outside CCF_ASM_BLOCK
//                                      -> legacy falls through
//      For these, the oracle returns 0 (so the wrapper falls
//      through to the next dispatcher arm).
//
// Output (one line per case):
//
//   O01 OP kind=0x3d len=1
//   O02 OP kind=0x30b len=2
//   ...
//   ONN NOT_OP
//   ...
//
// And final summary line:
//
//   ACT_SELFHOST_LEXER01_OPERATOR_CASES=N
//   ACT_SELFHOST_LEXER01_OPERATOR_PASS=<N>
//   ACT_SELFHOST_LEXER01_OPERATOR_FAIL=<N>
//   STATUS=<PASS|FAIL>
//
// Exit codes:
//   0  all cases match expected output
//   1  at least one case failed
//   2  argument error

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* ==== Frozen production flag bits (subset relevant to winner) ==== */
#define CCF_ASM_BLOCK     (1 << 16)  /* placeholder; exact bit is
                                        frozen by C2 wrapper */
#define CCF_MULTI_COLON   (1 << 17)  /* placeholder; exact bit is
                                        frozen by C2 wrapper */

typedef long long I64;

/* ==== Frozen production operator trigger set ==== */
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

/* ==== Frozen production operator classification ==== */
static int prod_classify_operator(const unsigned char *src,
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

    #define PEEK1() ((cursor + 1 < src_len) ? (unsigned char)src[cursor + 1] : 0)
    #define PEEK2() ((cursor + 2 < src_len) ? (unsigned char)src[cursor + 2] : 0)

    switch (ch) {
        case '=': {
            if (PEEK1() == '=') {
                *out_kind = 0x30B;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '<': {
            if (PEEK1() == '=') {
                *out_kind = 0x30D;
                *out_length = 2;
            } else if (PEEK1() == '<') {
                if (PEEK2() == '=') {
                    *out_kind = 0x312;
                    *out_length = 3;
                } else {
                    *out_kind = 0x309;
                    *out_length = 2;
                }
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '>': {
            if (PEEK1() == '=') {
                *out_kind = 0x30E;
                *out_length = 2;
            } else if (PEEK1() == '>') {
                if (PEEK2() == '=') {
                    *out_kind = 0x313;
                    *out_length = 3;
                } else {
                    *out_kind = 0x30A;
                    *out_length = 2;
                }
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '+': {
            if (PEEK1() == '+') {
                *out_kind = 0x305;
                *out_length = 2;
            } else if (PEEK1() == '=') {
                *out_kind = 0x319;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '-': {
            if (PEEK1() == '-') {
                *out_kind = 0x306;
                *out_length = 2;
            } else if (PEEK1() == '>') {
                *out_kind = 0x328;
                *out_length = 2;
            } else if (PEEK1() == '=') {
                *out_kind = 0x31A;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '!': {
            if (PEEK1() == '=') {
                *out_kind = 0x30C;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '&': {
            if (PEEK1() == '&') {
                *out_kind = 0x30F;
                *out_length = 2;
            } else if (PEEK1() == '=') {
                *out_kind = 0x316;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '|': {
            if (PEEK1() == '|') {
                *out_kind = 0x310;
                *out_length = 2;
            } else if (PEEK1() == '=') {
                *out_kind = 0x317;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '*': {
            if (PEEK1() == '=') {
                *out_kind = 0x314;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '%': {
            if (PEEK1() == '=') {
                *out_kind = 0x322;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '^': {
            if (PEEK1() == '=') {
                *out_kind = 0x318;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
        case '$':
        case '@':
        case '#': {
            if (!(flags & CCF_ASM_BLOCK)) return 0;
            *out_kind = (I64)ch;
            *out_length = 1;
            return 1;
        }
        case '.': {
            if (cursor + 1 < src_len) {
                unsigned char p1 = (unsigned char)src[cursor + 1];
                if (p1 >= '0' && p1 <= '9') {
                    return 0;
                }
                if (p1 == '.') {
                    if (cursor + 2 < src_len &&
                        (unsigned char)src[cursor + 2] == '.') {
                        *out_kind = 0x324;
                        *out_length = 3;
                        return 1;
                    }
                    return 0;
                }
            }
            *out_kind = (I64)ch;
            *out_length = 1;
            return 1;
        }
        case '\\': {
            *out_kind = (I64)ch;
            *out_length = 1;
            return 1;
        }
        case ':': {
            if ((flags & CCF_MULTI_COLON) && PEEK1() == ':') {
                *out_kind = 0x308;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
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
            *out_kind = (I64)ch;
            *out_length = 1;
            return 1;
        }
        case '/': {
            if (PEEK1() == '=') {
                *out_kind = 0x315;
                *out_length = 2;
            } else {
                *out_kind = (I64)ch;
                *out_length = 1;
            }
            return 1;
        }
    }
    return 0;
    #undef PEEK1
    #undef PEEK2
}

typedef struct {
    const char *id;
    const char *input;
    long long   cursor;
    long long   flags;
    long long   expected_kind;
    long long   expected_length;
    int         expected_ok;
} OpFixture;

static OpFixture FIXTURES[] = {
    { "O01", "(",  0, 0, '(',  1, 1 },
    { "O02", ")",  0, 0, ')',  1, 1 },
    { "O03", "[",  0, 0, '[',  1, 1 },
    { "O04", "]",  0, 0, ']',  1, 1 },
    { "O05", "{",  0, 0, '{',  1, 1 },
    { "O06", "}",  0, 0, '}',  1, 1 },
    { "O07", ",",  0, 0, ',',  1, 1 },
    { "O08", ";",  0, 0, ';',  1, 1 },
    { "O09", "~",  0, 0, '~',  1, 1 },
    { "O10", "=",  0, 0, '=',  1, 1 },
    { "O11", "<",  0, 0, '<',  1, 1 },
    { "O12", ">",  0, 0, '>',  1, 1 },
    { "O13", "+",  0, 0, '+',  1, 1 },
    { "O14", "-",  0, 0, '-',  1, 1 },
    { "O15", "!",  0, 0, '!',  1, 1 },
    { "O16", "&",  0, 0, '&',  1, 1 },
    { "O17", "|",  0, 0, '|',  1, 1 },
    { "O18", "*",  0, 0, '*',  1, 1 },
    { "O19", "%",  0, 0, '%',  1, 1 },
    { "O20", "^",  0, 0, '^',  1, 1 },
    { "O21", "==", 0, 0, 0x30B,  2, 1 },
    { "O22", "<=", 0, 0, 0x30D,  2, 1 },
    { "O23", "<<", 0, 0, 0x309,  2, 1 },
    { "O24", "<<=",0, 0, 0x312,  3, 1 },
    { "O25", ">=", 0, 0, 0x30E,  2, 1 },
    { "O26", ">>", 0, 0, 0x30A,  2, 1 },
    { "O27", ">>=",0, 0, 0x313,  3, 1 },
    { "O28", "++", 0, 0, 0x305,  2, 1 },
    { "O29", "+=", 0, 0, 0x319,  2, 1 },
    { "O30", "--", 0, 0, 0x306,  2, 1 },
    { "O31", "->", 0, 0, 0x328,  2, 1 },
    { "O32", "-=", 0, 0, 0x31A,  2, 1 },
    { "O33", "abc==def", 3, 0, 0x30B, 2, 1 },
    { "O34", "abc+",     3, 0, '+',  1, 1 },
    { "N01", "abc",      0, 0, 0,    0, 0 },
    { "N02", "",         0, 0, 0,    0, 0 },
    { "N03", "abc",      3, 0, 0,    0, 0 },
    { "N04", "9abc",     0, 0, 0,    0, 0 },
    { "N05", ".5",       0, 0, 0,    0, 0 },
    { "N06", "..",       0, 0, 0,    0, 0 },
    { "N07", "$x",       0, 0, 0,    0, 0 },
    { "O35", "$x",       0, CCF_ASM_BLOCK, '$', 1, 1 },
    { "O36", "::",       0, CCF_MULTI_COLON, 0x308, 2, 1 },
    { "O37", ":",        0, 0, ':', 1, 1 },
    { "O38", "...",      0, 0, 0x324, 3, 1 },
    { "O39", ".",        0, 0, '.', 1, 1 },
    { "O40", "\\",       0, 0, '\\', 1, 1 },
};

int main(int argc, char **argv)
{
    (void)argc; (void)argv;
    int pass = 0, fail = 0;
    int n = (int)(sizeof(FIXTURES) / sizeof(FIXTURES[0]));

    for (int i = 0; i < n; i++) {
        OpFixture *f = &FIXTURES[i];
        long long src_len = (long long)strlen(f->input);

        I64 out_kind = 0;
        I64 out_length = 0;
        int ok = prod_classify_operator((const unsigned char *)f->input,
                                        src_len,
                                        f->cursor,
                                        f->flags,
                                        &out_kind,
                                        &out_length);

        int this_pass = 1;
        if (ok != f->expected_ok)      this_pass = 0;
        if (ok == 1) {
            if (out_kind   != f->expected_kind)   this_pass = 0;
            if (out_length != f->expected_length) this_pass = 0;
        }

        if (this_pass) {
            pass++;
            if (ok == 1) {
                printf("%s OP kind=0x%llx len=%lld\n",
                       f->id,
                       (unsigned long long)out_kind,
                       out_length);
            } else {
                printf("%s NOT_OP\n", f->id);
            }
        } else {
            fail++;
            printf("%s FAIL ok=%d exp_ok=%d kind=0x%llx exp_kind=0x%llx "
                   "len=%lld exp_len=%lld\n",
                   f->id, ok, f->expected_ok,
                   (unsigned long long)out_kind,
                   (unsigned long long)f->expected_kind,
                   out_length, f->expected_length);
        }
    }

    printf("ACT_SELFHOST_LEXER01_OPERATOR_CASES=%d\n", n);
    printf("ACT_SELFHOST_LEXER01_OPERATOR_PASS=%d\n", pass);
    printf("ACT_SELFHOST_LEXER01_OPERATOR_FAIL=%d\n", fail);
    if (fail == 0) {
        printf("STATUS=PASS\n");
        return 0;
    } else {
        printf("STATUS=FAIL\n");
        return 1;
    }
}
