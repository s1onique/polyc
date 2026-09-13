// tools/quality/bootstrap01-lexer-oracle.c
//
// ACT-POLYC-BOOTSTRAP01 C1 — independent reference lexer.
//
// Pure-C reference implementation of the B0 lexical subset.
// Implements exactly the algorithm that an independent
// PolyC-free reference would use against the frozen ABI in
// evidence/ACT-POLYC-BOOTSTRAP01/c1/lexical-contract.txt.
//
// It is NOT a wrapper around the PolyC subject; it is its
// own implementation, compiled independently, with the only
// contract link being the JSON fixture file
// bootstrap01-fixtures.json.
//
// Exit codes:
//   0  every fixture's tokens matched
//   1  at least one fixture failed comparison
//   2  argument or fixture-load error
//
// Usage:
//   bootstrap01-lexer-oracle <path-to-fixtures.json>
//
// Toolchain: C99, no external dependencies.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>

// ----------------------------------------------------------------
// Frozen B0 ABI
// ----------------------------------------------------------------

enum {
    TK_EOF      = 0,
    TK_IDENT    = 1,
    TK_INT      = 2,
    TK_LPAREN   = 3,
    TK_RPAREN   = 4,
    TK_LBRACE   = 5,
    TK_RBRACE   = 6,
    TK_LBRACKET = 7,
    TK_RBRACKET = 8,
    TK_COMMA    = 9,
    TK_SEMI     = 10,
    TK_PLUS     = 11,
    TK_MINUS    = 12,
    TK_STAR     = 13,
    TK_SLASH    = 14,
    TK_ASSIGN   = 15
};

enum {
    LEX_OK               = 0,
    LEX_OUTPUT_FULL      = 1,
    LEX_UNSUPPORTED_BYTE = 2,
    LEX_INVALID_INPUT    = 3
};

static const char *kind_name(int k) {
    switch (k) {
        case TK_EOF:      return "EOF";
        case TK_IDENT:    return "IDENT";
        case TK_INT:      return "INT";
        case TK_LPAREN:   return "LPAREN";
        case TK_RPAREN:   return "RPAREN";
        case TK_LBRACE:   return "LBRACE";
        case TK_RBRACE:   return "RBRACE";
        case TK_LBRACKET: return "LBRACKET";
        case TK_RBRACKET: return "RBRACKET";
        case TK_COMMA:    return "COMMA";
        case TK_SEMI:     return "SEMI";
        case TK_PLUS:     return "PLUS";
        case TK_MINUS:    return "MINUS";
        case TK_STAR:     return "STAR";
        case TK_SLASH:    return "SLASH";
        case TK_ASSIGN:   return "ASSIGN";
        default:          return "?";
    }
}

// ----------------------------------------------------------------
// Reference lexer
// ----------------------------------------------------------------

typedef struct {
    int kind;
    long long start;
    long long len;
} RefToken;

static int punct_kind(unsigned char c) {
    switch (c) {
        case '(': return TK_LPAREN;
        case ')': return TK_RPAREN;
        case '{': return TK_LBRACE;
        case '}': return TK_RBRACE;
        case '[': return TK_LBRACKET;
        case ']': return TK_RBRACKET;
        case ',': return TK_COMMA;
        case ';': return TK_SEMI;
        case '+': return TK_PLUS;
        case '-': return TK_MINUS;
        case '*': return TK_STAR;
        case '/': return TK_SLASH;
        case '=': return TK_ASSIGN;
        default:  return 0;
    }
}

static int is_ident_start(unsigned char c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_';
}

static int is_ident_rest(unsigned char c) {
    return is_ident_start(c) || (c >= '0' && c <= '9');
}

static int ref_lex(const unsigned char *src, size_t src_len,
                   RefToken *out, size_t out_cap, size_t *out_count) {
    size_t i = 0;
    size_t n = src_len;
    size_t count = 0;
    while (i < n) {
        unsigned char c = src[i];
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
            i++;
            continue;
        }
        if (count + 1 > out_cap) return LEX_OUTPUT_FULL;
        if (is_ident_start(c)) {
            size_t s = i;
            i++;
            while (i < n && is_ident_rest(src[i])) i++;
            out[count].kind = TK_IDENT;
            out[count].start = (long long)s;
            out[count].len = (long long)(i - s);
            count++;
            continue;
        }
        if (c >= '0' && c <= '9') {
            size_t s = i;
            while (i < n && src[i] >= '0' && src[i] <= '9') i++;
            out[count].kind = TK_INT;
            out[count].start = (long long)s;
            out[count].len = (long long)(i - s);
            count++;
            continue;
        }
        int pk = punct_kind(c);
        if (pk != 0) {
            out[count].kind = pk;
            out[count].start = (long long)i;
            out[count].len = 1;
            count++;
            i++;
            continue;
        }
        *out_count = count;
        return LEX_UNSUPPORTED_BYTE;
    }
    if (count + 1 > out_cap) { *out_count = count; return LEX_OUTPUT_FULL; }
    out[count].kind = TK_EOF;
    out[count].start = (long long)n;
    out[count].len = 0;
    count++;
    *out_count = count;
    return LEX_OK;
}


// ----------------------------------------------------------------
// Fixture format: oracle takes one fixture record via argv.
// argv[1] = ID
// argv[2] = SRC (hex)
// argv[3] = SLICE_OFF (decimal int or "X")
// argv[4] = CAP (decimal int or "X")
// argv[5] = STATUS (OK|FULL|UNSUP|BAD)
// argv[6..] = triplets: KIND:START:LEN
//
// The orchestrator (PolyC test driver) iterates through
// fixtures, calls the oracle once per fixture, and compares
// outputs. This keeps the oracle minimal and free of any
// JSON parser.
// ----------------------------------------------------------------

static int hex_byte(int hi, int lo) {
    int h = (hi >= '0' && hi <= '9') ? hi - '0'
          : (hi >= 'a' && hi <= 'f') ? hi - 'a' + 10
          : (hi >= 'A' && hi <= 'F') ? hi - 'A' + 10
          : -1;
    int l = (lo >= '0' && lo <= '9') ? lo - '0'
          : (lo >= 'a' && lo <= 'f') ? lo - 'a' + 10
          : (lo >= 'A' && lo <= 'F') ? lo - 'A' + 10
          : -1;
    if (h < 0 || l < 0) return -1;
    return (h << 4) | l;
}

static int parse_hex(const char *s, unsigned char *out, size_t *outlen) {
    size_t n = strlen(s);
    if (n % 2 != 0) return 0;
    size_t j = 0;
    for (size_t i = 0; i < n; i += 2) {
        int b = hex_byte(s[i], s[i+1]);
        if (b < 0) return 0;
        out[j++] = (unsigned char)b;
    }
    *outlen = j;
    return 1;
}

static int parse_status(const char *s) {
    if (strcmp(s, "OK")   == 0) return LEX_OK;
    if (strcmp(s, "FULL") == 0) return LEX_OUTPUT_FULL;
    if (strcmp(s, "UNSUP")== 0) return LEX_UNSUPPORTED_BYTE;
    if (strcmp(s, "BAD")  == 0) return LEX_INVALID_INPUT;
    return -1;
}

static int compare_streams(const RefToken *sub, size_t sub_n, int sub_status,
                           const RefToken *ref, size_t ref_n, int ref_status) {
    if (sub_status != ref_status) return 0;
    if (sub_n != ref_n) return 0;
    for (size_t i = 0; i < sub_n; i++) {
        if (sub[i].kind  != ref[i].kind)  return 0;
        if (sub[i].start != ref[i].start) return 0;
        if (sub[i].len   != ref[i].len)   return 0;
    }
    return 1;
}

static void print_stream(const char *which, const char *id,
                         const RefToken *t, size_t n, int status) {
    printf("%s %s\n", which, id);
    for (size_t i = 0; i < n; i++) {
        printf("  %s  %zu %s %lld %lld\n",
               id, i, kind_name(t[i].kind), t[i].start, t[i].len);
    }
    const char *sn = "OK";
    if      (status == LEX_OUTPUT_FULL)      sn = "FULL";
    else if (status == LEX_UNSUPPORTED_BYTE) sn = "UNSUP";
    else if (status == LEX_INVALID_INPUT)    sn = "BAD";
    printf("  %s  STATUS=%s\n", id, sn);
}

static int run_one(const char *id,
                   const unsigned char *src, size_t src_len,
                   long long slice_off, int has_slice,
                   long long cap, int has_cap,
                   const RefToken *ref, size_t ref_n, int ref_status) {
    const unsigned char *sub_src = src;
    size_t sub_len = src_len;
    if (has_slice) {
        if (slice_off < 0 || (size_t)slice_off > src_len) {
            printf("CASE %s  RESULT=FAIL (invalid slice offset)\n", id);
            return 0;
        }
        sub_src += slice_off;
        sub_len -= (size_t)slice_off;
    }
    RefToken sub[256];
    size_t sub_cap = has_cap ? (size_t)cap : 256;
    size_t sub_n = 0;
    int sub_status = ref_lex(sub_src, sub_len, sub, sub_cap, &sub_n);

    print_stream("REF", id, ref, ref_n, ref_status);
    print_stream("SUB", id, sub, sub_n, sub_status);

    int ok = compare_streams(sub, sub_n, sub_status, ref, ref_n, ref_status);
    printf("CASE %s  RESULT=%s\n", id, ok ? "PASS" : "FAIL");
    return ok;
}

int main(int argc, char **argv) {
    if (argc < 6) {
        fprintf(stderr, "usage: %s ID SRC SLICE_OFF CAP STATUS [KIND:START:LEN ...]\n", argv[0]);
        return 2;
    }
    const char *id     = argv[1];
    const char *src_s  = argv[2];
    const char *sl_s   = argv[3];
    const char *cap_s  = argv[4];
    const char *stat_s = argv[5];

    unsigned char src[4096];
    size_t src_len = 0;
    if (!parse_hex(src_s, src, &src_len)) {
        fprintf(stderr, "bad SRC hex\n");
        return 2;
    }
    long long slice_off = 0;
    int has_slice = 0;
    if (strcmp(sl_s, "X") != 0) {
        slice_off = atoll(sl_s);
        has_slice = 1;
    }
    long long cap = 0;
    int has_cap = 0;
    if (strcmp(cap_s, "X") != 0) {
        cap = atoll(cap_s);
        has_cap = 1;
    }
    int ref_status = parse_status(stat_s);
    if (ref_status < 0) {
        fprintf(stderr, "bad STATUS: %s\n", stat_s);
        return 2;
    }
    RefToken ref[256];
    size_t ref_n = 0;
    for (int i = 6; i < argc; i++) {
        if (ref_n >= 256) break;
        const char *s = argv[i];
        char buf[64];
        strncpy(buf, s, sizeof(buf) - 1);
        buf[sizeof(buf) - 1] = '\0';
        char *colon1 = strchr(buf, ':');
        if (!colon1) { fprintf(stderr,"bad TK %s\n",s); return 2; }
        *colon1 = '\0';
        char *colon2 = strchr(colon1 + 1, ':');
        if (!colon2) { fprintf(stderr,"bad TK %s\n",s); return 2; }
        *colon2 = '\0';
        ref[ref_n].kind  = atoi(buf);
        ref[ref_n].start = atoll(colon1 + 1);
        ref[ref_n].len   = atoll(colon2 + 1);
        ref_n++;
    }
    int ok = run_one(id, src, src_len, slice_off, has_slice, cap, has_cap,
                     ref, ref_n, ref_status);
    return ok ? 0 : 1;
}
