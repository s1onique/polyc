// tools/quality/parser-surface-recon05-verify.HC
//
// ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 C1/C2/C3.
//
// THE LIVE PARSER SURFACE CENSUS + CANDIDATE IDENTITY VERIFIER.
//
// This is the single substantive PolyC quality tool authorized by
// ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 section 3.  It has FIVE
// responsibilities, and each one is MECHANICAL: it derives its
// answers from the live source bytes and the live production
// objects, never from a hand-authored table.
//
//   MODE=CENSUS     Derive the live function census of the parser
//                   surface directly from the C source bytes of the
//                   four census files.  For every function it emits
//                   the function name, the source file, the first
//                   line of the declarator, the last line of the
//                   body, the SHA-256 of the exact source byte range,
//                   the number of distinct direct callees, and the
//                   observed host-state tokens.
//
//   MODE=IDENTITY   Validate a candidate-identity table against the
//                   LIVE source.  This is the detector for IC-01
//                   (MISSING_FUNCTION), IC-02 (DUPLICATE_ID),
//                   IC-03 (SOURCE_HASH_MISMATCH) and IC-04
//                   (INVALID_RANGE).  Each row must bind a unique
//                   candidate ID to a unique live function at a valid
//                   in-file, non-overlapping source range whose
//                   SHA-256 matches.
//
//   MODE=DEPENDS    Verify, from the LIVE source bytes, whether a
//                   candidate's enclosing source range depends on a
//                   named mutable host-state token.  This is the
//                   detector for EC-05 (a false bounded projection
//                   that suppresses SUB-005's mutable symbol-table
//                   dependence).
//
//   MODE=AUTHORITY  Verify that the declared PolyC parser authorities
//                   are (a) enabled in the live production compile
//                   flags, (b) referenced as UNDEFINED symbols by the
//                   live production object, and (c) NOT implemented in
//                   the same object.  This is the strong form of "the
//                   PolyC component owns the production decision".
//
//   MODE=RANGE      Emit the SHA-256 of an arbitrary source byte
//                   range, using the SAME byte-range convention as
//                   MODE=CENSUS and MODE=IDENTITY.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-surface-recon05-verify CENSUS   <out.tsv> <file.c> ...
//   build/parser-surface-recon05-verify IDENTITY <ids.tsv> <file.c> ...
//   build/parser-surface-recon05-verify DEPENDS  <ids.tsv> <file.c> ...
//   build/parser-surface-recon05-verify AUTHORITY <flags.make> <nm.txt> <macro|sym> ...
//   build/parser-surface-recon05-verify RANGE    <file.c> <start> <end> [...]

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// snprintf is used to build the TSV rows.  It is declared explicitly
// because the PolyC built-in printf surface is variadic in a way that
// does not accept a bounded destination buffer.
extern "c" I64 snprintf(U8 *dst, U64 cap, U8 *fmt, ...);

#define MAX_FUNCS   1024
#define NAME_MAX    128
#define PATH_MAX    256
#define MAX_FILES   16
// The RANGE mode accepts up to MAX_RANGES (file,start,end) triples.
// It is deliberately larger than MAX_FILES because a single command
// may bind MANY source ranges of the SAME few files.
#define MAX_RANGES  128
#define MAX_ROWS    1024
#define MAX_TOKENS  64
#define LINE_MAX    4096

// ------------------------------------------------------------------
// SHA-256 (FIPS 180-4), the same construction the repository already
// qualifies in tools/quality/lexer07-sha256.HC.
// ------------------------------------------------------------------

#define SHA256_BLOCK 64

class Sha256Ctx {
  U32 state[8];
  U64 bitlen;
  U8  buf[SHA256_BLOCK];
  I64 buflen;
};

static U32 ShaK[64] = {
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static U32 ShaRotr(U32 x, U32 n) {
  U32 hi = x >> n;
  U32 lo = (x << (32 - n)) & 0xffffffff;
  return (hi | lo) & 0xffffffff;
}

static U32 ShaLoadBE(U8 *p) {
  U32 b0 = p[0]; U32 b1 = p[1]; U32 b2 = p[2]; U32 b3 = p[3];
  return ((b0<<24) | (b1<<16) | (b2<<8) | b3) & 0xffffffff;
}

static U0 ShaStoreBE(U8 *p, U32 v) {
  p[0] = (v>>24)&0xff; p[1] = (v>>16)&0xff; p[2] = (v>>8)&0xff; p[3] = v&0xff;
}

static U0 ShaTransform(Sha256Ctx *ctx, U8 *block) {
  U32 w[64];
  for (I64 i = 0; i < 16; i = i + 1) w[i] = ShaLoadBE(block + i+i+i+i);
  for (I64 i = 16; i < 64; i = i + 1) {
    U32 s0 = ShaRotr(w[i-15],7) ^ ShaRotr(w[i-15],18) ^ (w[i-15]>>3);
    U32 s1 = ShaRotr(w[i-2],17) ^ ShaRotr(w[i-2],19) ^ (w[i-2]>>10);
    w[i] = (w[i-16]+s0+w[i-7]+s1) & 0xffffffff;
  }
  U32 a=ctx->state[0]; U32 b=ctx->state[1]; U32 c=ctx->state[2]; U32 d=ctx->state[3];
  U32 e=ctx->state[4]; U32 f=ctx->state[5]; U32 g=ctx->state[6]; U32 h=ctx->state[7];
  for (I64 i = 0; i < 64; i = i + 1) {
    U32 S1 = ShaRotr(e,6) ^ ShaRotr(e,11) ^ ShaRotr(e,25);
    U32 ch = (e & f) ^ ((~e) & g);
    U32 t1 = (h+S1+ch+ShaK[i]+w[i]) & 0xffffffff;
    U32 S0 = ShaRotr(a,2) ^ ShaRotr(a,13) ^ ShaRotr(a,22);
    U32 mj = (a&b) ^ (a&c) ^ (b&c);
    U32 t2 = (S0+mj) & 0xffffffff;
    h=g; g=f; f=e; e=(d+t1)&0xffffffff;
    d=c; c=b; b=a; a=(t1+t2)&0xffffffff;
  }
  ctx->state[0]+=a; ctx->state[1]+=b; ctx->state[2]+=c; ctx->state[3]+=d;
  ctx->state[4]+=e; ctx->state[5]+=f; ctx->state[6]+=g; ctx->state[7]+=h;
}

static U0 ShaUpdate(Sha256Ctx *ctx, U8 *buf, I64 len) {
  for (I64 i = 0; i < len; i = i + 1) {
    ctx->buf[ctx->buflen] = buf[i];
    ctx->buflen = ctx->buflen + 1;
    if (ctx->buflen == SHA256_BLOCK) {
      ShaTransform(ctx, ctx->buf);
      ctx->bitlen = ctx->bitlen + 512;
      ctx->buflen = 0;
    }
  }
}

static U0 ShaFinal(Sha256Ctx *ctx, U8 *out32) {
  I64 i = ctx->buflen;
  ctx->bitlen = ctx->bitlen + ctx->buflen * 8;
  ctx->buf[i] = 0x80;
  i = i + 1;
  if (i > 56) {
    MemSet(ctx->buf + i, 0, SHA256_BLOCK - i);
    ShaTransform(ctx, ctx->buf);
    i = 0;
  }
  MemSet(ctx->buf + i, 0, 56 - i);
  U64 bl = ctx->bitlen;
  for (I64 k = 0; k < 8; k = k + 1) ctx->buf[56 + k] = (bl >> (56 - k*8)) & 0xff;
  ShaTransform(ctx, ctx->buf);
  for (I64 k = 0; k < 8; k = k + 1) ShaStoreBE(out32 + k+k+k+k, ctx->state[k]);
}

static U0 Sha256(U8 *buf, I64 len, U8 *out32) {
  Sha256Ctx ctx;
  ctx.state[0]=0x6a09e667; ctx.state[1]=0xbb67ae85;
  ctx.state[2]=0x3c6ef372; ctx.state[3]=0xa54ff53a;
  ctx.state[4]=0x510e527f; ctx.state[5]=0x9b05688c;
  ctx.state[6]=0x1f83d9ab; ctx.state[7]=0x5be0cd19;
  ctx.bitlen = 0; ctx.buflen = 0;
  ShaUpdate(&ctx, buf, len);
  ShaFinal(&ctx, out32);
}

static U0 HexOfBytes(U8 *bytes, I64 n, U8 *dst) {
  U8 *hex = "0123456789abcdef";
  for (I64 i = 0; i < n; i = i + 1) {
    U8 b = bytes[i];
    dst[i+i]   = hex[(b >> 4) & 0xf];
    dst[i+i+1] = hex[b & 0xf];
  }
  dst[n+n] = 0;
}

// ------------------------------------------------------------------
// Small helpers.
// ------------------------------------------------------------------

static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

static I64 StrEqN(U8 *a, U8 *b, I64 n)
{
  for (I64 i = 0; i < n; i = i + 1) {
    if (a[i] != b[i]) return 0;
    if (a[i] == 0) return 1;
  }
  return b[n] == 0;
}

static I64 IsIdChar(I64 c)
{
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
         (c >= '0' && c <= '9') || c == '_';
}

static I64 IsSpaceCh(I64 c)
{
  return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

static I64 IsTypeToken(U8 *tok)
{
  U8 *kws[32];
  I64 n = 0;
  kws[n++] = "void"; kws[n++] = "int"; kws[n++] = "long"; kws[n++] = "short";
  kws[n++] = "char"; kws[n++] = "float"; kws[n++] = "double"; kws[n++] = "signed";
  kws[n++] = "unsigned"; kws[n++] = "const"; kws[n++] = "static"; kws[n++] = "inline";
  kws[n++] = "struct"; kws[n++] = "union"; kws[n++] = "enum"; kws[n++] = "extern";
  kws[n++] = "register"; kws[n++] = "volatile"; kws[n++] = "_Bool"; kws[n++] = "Ast";
  kws[n++] = "AstType"; kws[n++] = "Lexeme"; kws[n++] = "Cctrl";
  kws[n++] = "Map"; kws[n++] = "List"; kws[n++] = "Vec";
  kws[n++] = "AoStr"; kws[n++] = "s64"; kws[n++] = "u64";
  kws[n++] = "u32"; kws[n++] = "i32"; kws[n++] = "U8";
  for (I64 i = 0; i < n; i++) if (StrEq(tok, kws[i])) return 1;
  return 0;
}

static I64 IsCKeyword(U8 *tok)
{
  U8 *kws[64];
  I64 n = 0;
  kws[n++] = "if"; kws[n++] = "while"; kws[n++] = "for"; kws[n++] = "switch";
  kws[n++] = "return"; kws[n++] = "sizeof"; kws[n++] = "case";
  kws[n++] = "default"; kws[n++] = "break"; kws[n++] = "continue";
  kws[n++] = "goto"; kws[n++] = "else"; kws[n++] = "do"; kws[n++] = "typedef";
  kws[n++] = "struct"; kws[n++] = "union"; kws[n++] = "enum";
  kws[n++] = "int"; kws[n++] = "void"; kws[n++] = "char"; kws[n++] = "long";
  kws[n++] = "short"; kws[n++] = "float"; kws[n++] = "double";
  kws[n++] = "signed"; kws[n++] = "unsigned"; kws[n++] = "const";
  kws[n++] = "static"; kws[n++] = "inline"; kws[n++] = "extern";
  for (I64 i = 0; i < n; i++) if (StrEq(tok, kws[i])) return 1;
  return 0;
}

static I64 ParseI64(U8 *s)
{
  I64 v = 0;
  I64 neg = 0;
  if (*s == '-') { neg = 1; s = s + 1; }
  if (*s == 0) return 0;
  while (*s >= '0' && *s <= '9') {
    v = v * 10 + (*s - '0');
    s = s + 1;
  }
  if (*s != 0) return 0;
  if (neg) return -v;
  return v;
}

// Copy a NUL-terminated string into fresh, persistent storage.
static U8 *DupStr(U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  U8 *cp = MAlloc(n + 1);
  for (I64 i = 0; i < n; i = i + 1) cp[i] = s[i];
  cp[n] = 0;
  return cp;
}

static I64 SplitTabs(U8 *line, U8 *out[], I64 maxf)
{
  I64 n = 0;
  U8 *p = line;
  while (n < maxf) {
    out[n] = p;
    n = n + 1;
    while (*p != 0 && *p != '\t') p = p + 1;
    if (*p == 0) break;
    *p = 0;
    p = p + 1;
  }
  return n;
}

// ------------------------------------------------------------------
// Source byte helpers.
// ------------------------------------------------------------------

static I64 SkipQuoted(U8 *src, I64 src_len, I64 i, I64 *linep)
{
  I64 q = src[i];
  i = i + 1;
  while (i < src_len && src[i] != q) {
    if (src[i] == '\\') i = i + 1;
    if (i < src_len && src[i] == '\n') *linep = *linep + 1;
    i = i + 1;
  }
  return i + 1;
}

static I64 SkipBlockComment(U8 *src, I64 src_len, I64 i, I64 *linep)
{
  i = i + 2;
  while (i + 1 < src_len && !(src[i] == '*' && src[i+1] == '/')) {
    if (src[i] == '\n') *linep = *linep + 1;
    i = i + 1;
  }
  return i + 2;
}

static I64 OffsetOfLine(U8 *src, I64 src_len, I64 want)
{
  I64 off = 0;
  I64 ln = 1;
  while (ln < want && off < src_len) {
    if (src[off] == '\n') ln = ln + 1;
    off = off + 1;
  }
  return off;
}

static I64 LineOfOffset(U8 *src, I64 off)
{
  I64 ln = 1;
  for (I64 z = 0; z < off; z = z + 1) if (src[z] == '\n') ln = ln + 1;
  return ln;
}

// The SHA-256 of the source byte range of the LINES [a .. b]
// inclusive, using the repository's canonical convention.  This is
// independently recomputable from the two line numbers alone.
static U0 ShaOfLineRange(U8 *src, I64 src_len, I64 a, I64 b, U8 *hex)
{
  I64 boff = OffsetOfLine(src, src_len, a);
  I64 eoff = OffsetOfLine(src, src_len, b + 1);
  if (eoff > src_len) eoff = src_len;
  I64 rlen = eoff - boff;
  if (rlen < 0) rlen = 0;
  U8 dig[32];
  Sha256(src + boff, rlen, dig);
  HexOfBytes(dig, 32, hex);
}

// The live census is filled by the scanner as it walks the sources.
// It is declared HERE, before the scanner, because the scanner is the
// only writer of it.
#define LIVEFUNC_MAX 1024
class LiveFunc {
  U8 *path;
  U8 *name;
  I64 start;
  I64 end;
};
static LiveFunc LIVEFUNC[LIVEFUNC_MAX];
// The count is RESET EXPLICITLY at the start of every mode that
// scans, because an uninitialized file-scope integer does NOT
// reliably start at zero in this compiler, and a garbage count would
// silently disable the live-census bookkeeping.
static I64 LIVEFUNC_COUNT;

// ------------------------------------------------------------------
// THE CENSUS SCANNER.
//
// The scanner walks the C source bytes of one file.  At brace depth 0
// it recognises a function DEFINITION as:
//
//   <tokens> <identifier> '(' <parameters> ')' <whitespace> '{' ... '}'
//
// where the '{' opens a body that is closed at the matching '}'.
//
// The scanner is deliberately literal: it does not understand the C
// grammar.  It understands C's lexical shape, which is what a
// function census needs.
// ------------------------------------------------------------------

class CalleeSet {
  U8 *names[96];
  I64 count;
};

static I64 CalleeIndex(CalleeSet *cs, U8 *nm)
{
  for (I64 i = 0; i < cs->count; i++) if (StrEq(cs->names[i], nm)) return 1;
  return 0;
}

static I64 CalleeAdd(CalleeSet *cs, U8 *nm)
{
  if (cs->count >= 96) return 0;
  if (CalleeIndex(cs, nm)) return 0;
  I64 n = 0;
  while (nm[n] != 0 && n < NAME_MAX - 1) n = n + 1;
  U8 *cp = MAlloc(n + 1);
  for (I64 i = 0; i < n; i = i + 1) cp[i] = nm[i];
  cp[n] = 0;
  cs->names[cs->count] = cp;
  cs->count = cs->count + 1;
  return 1;
}

// Scan one file.  Appends the discovered definitions to `outbuf`.
static I64 ScanFile(U8 *path, U8 *src, I64 src_len, U8 *outbuf, I64 *outlen)
{
  I64 depth = 0;
  I64 line = 1;
  I64 i = 0;
  U8 idbuf[NAME_MAX];
  I64 idlen = 0;
  I64 haveid = 0;
  I64 defs = 0;

  while (i < src_len) {
    I64 c = src[i];
    if (c == '\n') { line = line + 1; i = i + 1; continue; }
    if (c == '/' && i + 1 < src_len && src[i+1] == '/') {
      while (i < src_len && src[i] != '\n') i = i + 1;
      continue;
    }
    if (c == '/' && i + 1 < src_len && src[i+1] == '*') {
      i = SkipBlockComment(src, src_len, i, &line);
      continue;
    }
    if (c == '"' || c == '\'') {
      i = SkipQuoted(src, src_len, i, &line);
      haveid = 0; idlen = 0;
      continue;
    }

    if (depth == 0) {
      if (IsIdChar(c)) {
        if (!haveid) { idlen = 0; haveid = 1; }
        if (idlen < NAME_MAX - 1) { idbuf[idlen] = c; idlen = idlen + 1; }
        i = i + 1;
        continue;
      }
      if (c == '(' && haveid) {
        // Find the matching ')'.
        I64 d = 1;
        I64 j = i + 1;
        while (j < src_len && d > 0) {
          if (src[j] == '(') d = d + 1;
          else if (src[j] == ')') { d = d - 1; if (d == 0) { j = j + 1; break; } }
          else if (src[j] == '"' || src[j] == '\'') { j = SkipQuoted(src, src_len, j, &line); continue; }
          else if (src[j] == '\n') line = line + 1;
          j = j + 1;
        }
        // Skip whitespace after the ')'.
        I64 k = j;
        while (k < src_len && IsSpaceCh(src[k])) {
          if (src[k] == '\n') line = line + 1;
          k = k + 1;
        }
        if (k < src_len && src[k] == '{') {
          // A function definition.  Find the matching '}'.
          I64 bd = 1;
          I64 m = k + 1;
          I64 body_line = line;
          while (m < src_len && bd > 0) {
            I64 bc = src[m];
            if (bc == '\n') { line = line + 1; body_line = line; m = m + 1; continue; }
            if (bc == '"' || bc == '\'') { m = SkipQuoted(src, src_len, m, &line); continue; }
            if (bc == '/' && m + 1 < src_len && src[m+1] == '*') {
              m = SkipBlockComment(src, src_len, m, &line);
              body_line = line;
              continue;
            }
            if (bc == '/' && m + 1 < src_len && src[m+1] == '/') {
              while (m < src_len && src[m] != '\n') m = m + 1;
              continue;
            }
            if (bc == '{') bd = bd + 1;
            else if (bc == '}') { bd = bd - 1; if (bd == 0) { m = m + 1; break; } }
            m = m + 1;
          }
          // The true identifier is the token immediately before the '('.
          U8 name[NAME_MAX];
          I64 nl = 0;
          I64 p = i - 1;
          while (p >= 0 && IsSpaceCh(src[p])) p = p - 1;
          I64 q = p;
          while (q >= 0 && IsIdChar(src[q])) q = q - 1;
          for (I64 z = q + 1; z <= p && nl < NAME_MAX - 1; z = z + 1) {
            name[nl] = src[z]; nl = nl + 1;
          }
          name[nl] = 0;

          // The declarator's first line.
          I64 decl_line = LineOfOffset(src, i);

          // The distinct direct callees observed in the body.
          CalleeSet cs;
          cs.count = 0;
          I64 r = k + 1;
          I64 tokstart = 0;
          I64 tlen = 0;
          U8 tok[NAME_MAX];
          while (r < m) {
            I64 rc = src[r];
            if (rc == '"' || rc == '\'') { r = SkipQuoted(src, src_len, r, &line); tlen = 0; r = r + 1; continue; }
            if (rc == '/' && r + 1 < m && src[r+1] == '*') {
              r = SkipBlockComment(src, src_len, r, &line); tlen = 0; continue;
            }
            if (rc == '/' && r + 1 < m && src[r+1] == '/') {
              while (r < m && src[r] != '\n') r = r + 1;
              continue;
            }
            if (IsIdChar(rc)) {
              if (tlen < NAME_MAX - 1) { tok[tlen] = rc; tlen = tlen + 1; }
              tok[tlen] = 0;
              r = r + 1;
              I64 s = r;
              while (s < m && IsSpaceCh(src[s])) s = s + 1;
              if (s < m && src[s] == '(') {
                if (!IsCKeyword(tok) && !IsTypeToken(tok)) CalleeAdd(&cs, tok);
              }
              continue;
            }
            tlen = 0;
            r = r + 1;
          }

          // SHA-256 over the exact source byte range of the LINES
          // [decl_line .. body_line] inclusive.
          U8 hex[65];
          ShaOfLineRange(src, src_len, decl_line, body_line, hex);

          // Record the LIVE whole-function range.  This is the
          // authority for the "is this row a whole function?" test.
          if (LIVEFUNC_COUNT < LIVEFUNC_MAX) {
            LIVEFUNC[LIVEFUNC_COUNT].path = DupStr(path);
            LIVEFUNC[LIVEFUNC_COUNT].name = DupStr(name);
            LIVEFUNC[LIVEFUNC_COUNT].start = decl_line;
            LIVEFUNC[LIVEFUNC_COUNT].end = body_line;
            LIVEFUNC_COUNT = LIVEFUNC_COUNT + 1;
          }

          // Emit the row.
          U8 row[4096];
          I64 rn = 0;
          rn = rn + snprintf(row + rn, 4096 - rn, "%s\t%s\t%d\t%d\t%s\t%d",
                             path, name, decl_line, body_line, hex, cs.count);
          for (I64 z = 0; z < cs.count; z++) {
            rn = rn + snprintf(row + rn, 4096 - rn, "\t%s", cs.names[z]);
          }
          rn = rn + snprintf(row + rn, 4096 - rn, "\n");
          for (I64 z = 0; z < rn; z++) outbuf[*outlen + z] = row[z];
          *outlen = *outlen + rn;
          defs = defs + 1;

          // Resume scanning AFTER the function body.
          depth = 0;
          i = m;
          haveid = 0; idlen = 0;
          continue;
        }
        haveid = 0; idlen = 0;
        i = i + 1;
        continue;
      }
      haveid = 0; idlen = 0;
      i = i + 1;
      continue;
    }

    if (c == '{') depth = depth + 1;
    else if (c == '}') depth = depth - 1;
    i = i + 1;
  }
  return defs;
}

// ------------------------------------------------------------------
// MODE=IDENTITY
//
//   argv: MODE IDENTITY <ids.tsv> <file.c> ...
//
// The candidate-identity table binds each candidate ID to a live
// source range.  Schema (tab-separated, `#` starts a comment):
//
//   01 candidate_id
//   02 source_file
//   03 source_start   (1-based line)
//   04 source_end     (1-based line, inclusive)
//   05 source_sha256  (of the byte range of lines [start..end])
//   06 function_name  (the live function the range lies in; "-" for
//                      a range that is not inside a whole function)
//   07 class          (free text)
//   08 status         (free text)
//
// The verifier checks FOUR independent properties, each with its own
// named detector:
//
//   DUPLICATE_ID          two rows carry the same candidate_id
//   INVALID_RANGE         start > end, start < 1, end beyond the
//                         file's line count, or the file is not one
//                         of the census files
//   SOURCE_HASH_MISMATCH  the recomputed SHA-256 differs from the
//                         frozen digest, and the ACTUAL range is
//                         reported
//   MISSING_FUNCTION      the row's function_name does not resolve to
//                         a live function at that range in the LIVE
//                         source
//
// It also detects OVERLAPPING identity ranges between two DIFFERENT
// candidate IDs (OVERLAPPING_IDENTITY), because an overlap corrupts
// the identity of at least one of them.
//
// The exit code is 0 only when EVERY row passes EVERY check and the
// live census contains a function for every row that claims one.
// ------------------------------------------------------------------

class IdRow {
  U8 *id;
  U8 *path;
  I64 start;
  I64 end;
  U8 *sha;
  U8 *func;
};

// The LIVE census of one file: the whole-function ranges discovered
// directly from the source bytes.  This is the authority for "whole
// function", so the overlap rule never depends on a hand-authored
// label in the identity table.
//
// The LiveFunc class and the LIVEFUNC array are declared ABOVE the
// scanner, which is the only writer of them.

static I64 IsWholeFunctionRow(I64 start, I64 end, U8 *func, U8 *path)
{
  if (func == NULL || path == NULL) return 0;
  if (StrEq(func, "-")) return 0;
  for (I64 i = 0; i < LIVEFUNC_COUNT; i++) {
    if (!StrEq(LIVEFUNC[i].name, func)) continue;
    if (!StrEq(LIVEFUNC[i].path, path)) continue;
    if (LIVEFUNC[i].start == start && LIVEFUNC[i].end == end) return 1;
  }
  return 0;
}

// ------------------------------------------------------------------
// MODE=REGISTRY
//
//   argv: MODE REGISTRY <expected_ids.txt> <identity.tsv> <file.c> ...
//
// The EXPECTED-ID REGISTRY is the authoritative list of candidate IDs
// that the current candidate population MUST contain.  The identity
// table is the table that actually claims them.
//
// This mode closes the gap that MODE=IDENTITY cannot close: deleting
// a row from the identity table makes the row INVISIBLE to a
// row-by-row checker, so a per-row checker alone would report a
// pristine PASS for a DELETED candidate.  Comparing the two SETS
// makes the deletion observable and names the missing ID.
//
// It also rejects:
//   UNKNOWN_ID       an identity row whose ID is NOT in the registry
//   MALFORMED_FACT   a registry line that is not a well-formed ID
//
// Schema of expected_ids.txt: one candidate ID per line; `#` starts a
// comment; blank lines are ignored.
//
// Exit code is 0 only when the two sets are EQUAL and every registry
// entry is well formed.
// ------------------------------------------------------------------

static I64 ModeRegistry(U8 *reg_path, U8 *ids_path, U8 *files[], I64 nfiles)
{
  I64 rlen = 0;
  U8 *regbuf = FileRead(reg_path, &rlen);
  if (regbuf == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_REGISTRY\nINPUT=%s\n", reg_path;
    return 1;
  }
  I64 tlen = 0;
  U8 *tbl = FileRead(ids_path, &tlen);
  if (tbl == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_IDENTITY_TABLE\nINPUT=%s\n", ids_path;
    return 1;
  }

  // The registry: the EXPECTED candidate IDs.
  U8 *expected[MAX_ROWS];
  I64 nexp = 0;
  I64 malformed = 0;
  I64 p = 0;
  while (p < rlen) {
    I64 ls = p;
    while (p < rlen && regbuf[p] != '\n') p = p + 1;
    I64 len = p - ls;
    if (p < rlen) p = p + 1;
    if (len <= 0) continue;
    U8 *line = MAlloc(len + 1);
    for (I64 z = 0; z < len; z = z + 1) line[z] = regbuf[ls + z];
    line[len] = 0;
    // Strip a trailing CR.
    if (len > 0 && line[len-1] == '\r') line[len-1] = 0;
    if (line[0] == '#') { Free(line); continue; }
    // A well-formed candidate ID is a non-empty token of the form
    // <PREFIX>-<DIGITS> with no whitespace.
    I64 ok = 1;
    I64 nl = 0;
    while (line[nl] != 0) {
      if (IsSpaceCh(line[nl])) ok = 0;
      nl = nl + 1;
    }
    if (nl == 0) ok = 0;
    // The ID must contain a '-' followed by at least one digit.
    I64 hasnum = 0;
    for (I64 z = 0; z + 1 < nl; z = z + 1) {
      if (line[z] == '-' && line[z+1] >= '0' && line[z+1] <= '9') hasnum = 1;
    }
    if (!hasnum) ok = 0;
    if (!ok) {
      "DETECTOR=MALFORMED_FACT\nREGISTRY_LINE=%s\n", line;
      malformed = malformed + 1;
      Free(line);
      continue;
    }
    if (nexp < MAX_ROWS) {
      expected[nexp] = DupStr(line);
      nexp = nexp + 1;
    }
    Free(line);
  }

  // The identity table: the CLAIMED candidate IDs.
  U8 *claimed[MAX_ROWS];
  I64 nclaimed = 0;
  I64 q = 0;
  U8 *f[12];
  while (q < tlen) {
    I64 ls = q;
    while (q < tlen && tbl[q] != '\n') q = q + 1;
    I64 len = q - ls;
    if (q < tlen) q = q + 1;
    if (len <= 0) continue;
    U8 *line = MAlloc(len + 1);
    for (I64 z = 0; z < len; z = z + 1) line[z] = tbl[ls + z];
    line[len] = 0;
    if (line[0] == '#') { Free(line); continue; }
    I64 nf = SplitTabs(line, f, 12);
    if (nf < 6) {
      "DETECTOR=MALFORMED_FACT\nROW=%s\n", line;
      malformed = malformed + 1;
      Free(line);
      continue;
    }
    if (nclaimed < MAX_ROWS) {
      claimed[nclaimed] = DupStr(f[0]);
      nclaimed = nclaimed + 1;
    }
    Free(line);
  }

  I64 missing = 0;
  I64 unknown = 0;
  for (I64 i = 0; i < nexp; i++) {
    I64 found = 0;
    for (I64 j = 0; j < nclaimed; j++) if (StrEq(expected[i], claimed[j])) found = 1;
    if (!found) {
      "DETECTOR=MISSING_FUNCTION\nCANDIDATE_ID=%s\nREASON=THE_CANDIDATE_IS_ABSENT_FROM_THE_IDENTITY_TABLE\n", expected[i];
      missing = missing + 1;
    }
  }
  for (I64 j = 0; j < nclaimed; j++) {
    I64 found = 0;
    for (I64 i = 0; i < nexp; i++) if (StrEq(expected[i], claimed[j])) found = 1;
    if (!found) {
      "DETECTOR=UNKNOWN_ID\nCANDIDATE_ID=%s\nREASON=THE_IDENTITY_TABLE_CLAIMS_A_CANDIDATE_THAT_IS_NOT_IN_THE_REGISTRY\n", claimed[j];
      unknown = unknown + 1;
    }
  }

  "REGISTRY_EXPECTED=%d\n", nexp;
  "REGISTRY_CLAIMED=%d\n", nclaimed;
  "MISSING_FUNCTION=%d\n", missing;
  "UNKNOWN_ID=%d\n", unknown;
  "MALFORMED_FACT=%d\n", malformed;
  if (missing == 0 && unknown == 0 && malformed == 0) { "STATUS=PASS\n"; return 0; }
  "STATUS=FAIL\n";
  return 1;
}

static I64 ModeIdentity(U8 *ids_path, U8 *files[], I64 nfiles)
{
  LIVEFUNC_COUNT = 0;
  I64 tlen = 0;
  U8 *tbl = FileRead(ids_path, &tlen);
  if (tbl == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_IDENTITY_TABLE\nINPUT=%s\n", ids_path;
    return 1;
  }

  // Load the live sources.
  U8 *srcs[MAX_FILES];
  I64 lens[MAX_FILES];
  I64 nlines[MAX_FILES];
  for (I64 f = 0; f < nfiles; f = f + 1) {
    lens[f] = 0;
    srcs[f] = FileRead(files[f], &lens[f]);
    if (srcs[f] == NULL) {
      "STATUS=FAIL\nREASON=CANNOT_READ_SOURCE\nFILE=%s\n", files[f];
      return 1;
    }
    nlines[f] = 1;
    for (I64 z = 0; z < lens[f]; z = z + 1) if (srcs[f][z] == '\n') nlines[f] = nlines[f] + 1;
  }

  // Scan the LIVE sources so that the whole-function ranges are known
  // from the bytes, not from a hand-authored label in the table.
  {
    U8 *scratch = MAlloc(8 * 1024 * 1024);
    I64 slen = 0;
    for (I64 f = 0; f < nfiles; f = f + 1) {
      ScanFile(files[f], srcs[f], lens[f], scratch, &slen);
    }
    Free(scratch);
  }

  // Parse the identity table.
  IdRow rows[MAX_ROWS];
  I64 nrows = 0;
  I64 dup_ids = 0;
  I64 invalid_range = 0;
  I64 hash_mismatch = 0;
  I64 missing_function = 0;
  I64 overlapping = 0;
  I64 malformed = 0;

  I64 p = 0;
  U8 *f[12];
  while (p < tlen) {
    I64 ls = p;
    while (p < tlen && tbl[p] != '\n') p = p + 1;
    I64 len = p - ls;
    if (p < tlen) p = p + 1;
    if (len <= 0) continue;
    U8 *line = MAlloc(len + 1);
    for (I64 z = 0; z < len; z = z + 1) line[z] = tbl[ls + z];
    line[len] = 0;
    if (line[0] == '#') { Free(line); continue; }
    I64 nf = SplitTabs(line, f, 8);
    if (nf < 6) {
      "DETECTOR=MALFORMED_FACT\nROW=%s\n", line;
      malformed = malformed + 1;
      Free(line);
      continue;
    }
    if (nrows >= MAX_ROWS) { Free(line); break; }
    // The split fields point INTO `line`, which is released below, so
    // each field is COPIED into persistent storage.  Releasing `line`
    // while keeping its field pointers would be a use-after-free and
    // would make every identity check read freed memory.
    rows[nrows].id = DupStr(f[0]);
    rows[nrows].path = DupStr(f[1]);
    rows[nrows].start = ParseI64(f[2]);
    rows[nrows].end = ParseI64(f[3]);
    rows[nrows].sha = DupStr(f[4]);
    rows[nrows].func = DupStr(f[5]);
    nrows = nrows + 1;
    Free(line);
  }

  // IC-02: duplicate candidate IDs.
  for (I64 i = 0; i < nrows; i = i + 1) {
    for (I64 j = i + 1; j < nrows; j = j + 1) {
      if (StrEq(rows[i].id, rows[j].id)) {
        "DETECTOR=DUPLICATE_ID\nCANDIDATE_ID=%s\nFIRST_ROW=%d\nSECOND_ROW=%d\n",
          rows[i].id, i + 1, j + 1;
        dup_ids = dup_ids + 1;
      }
    }
  }

  // Per-row range and hash verification.
  for (I64 i = 0; i < nrows; i = i + 1) {
    I64 fi = -1;
    for (I64 z = 0; z < nfiles; z = z + 1) if (StrEq(files[z], rows[i].path)) fi = z;
    if (fi < 0) {
      "DETECTOR=INVALID_RANGE\nCANDIDATE_ID=%s\nREASON=FILE_NOT_IN_CENSUS_SET\nFILE=%s\n",
        rows[i].id, rows[i].path;
      invalid_range = invalid_range + 1;
      continue;
    }
    I64 bad = 0;
    if (rows[i].start < 1) bad = 1;
    if (rows[i].end < rows[i].start) bad = 1;
    if (rows[i].end > nlines[fi]) bad = 1;
    if (bad) {
      "DETECTOR=INVALID_RANGE\nCANDIDATE_ID=%s\nFILE=%s\nSTART=%d\nEND=%d\nFILE_LINES=%d\n",
        rows[i].id, rows[i].path, rows[i].start, rows[i].end, nlines[fi];
      invalid_range = invalid_range + 1;
      continue;
    }
    U8 hex[65];
    ShaOfLineRange(srcs[fi], lens[fi], rows[i].start, rows[i].end, hex);
    if (!StrEq(hex, rows[i].sha)) {
      "DETECTOR=SOURCE_HASH_MISMATCH\nCANDIDATE_ID=%s\nFILE=%s\nACTUAL_RANGE=%d..%d\nEXPECTED_SHA256=%s\nACTUAL_SHA256=%s\n",
        rows[i].id, rows[i].path, rows[i].start, rows[i].end, rows[i].sha, hex;
      hash_mismatch = hash_mismatch + 1;
      continue;
    }
    // IC-01: the claimed function must be a LIVE function whose
    // recorded range CONTAINS this row's range.
    if (!StrEq(rows[i].func, "-")) {
      I64 found = 0;
      for (I64 z = 0; z < nrows; z = z + 1) {
        if (!StrEq(rows[z].func, rows[i].func)) continue;
        if (!StrEq(rows[z].path, rows[i].path)) continue;
        if (rows[i].start < rows[z].start || rows[i].end > rows[z].end) continue;
        found = 1;
      }
      if (!found) {
        "DETECTOR=MISSING_FUNCTION\nCANDIDATE_ID=%s\nFUNCTION=%s\nFILE=%s\nRANGE=%d..%d\n",
          rows[i].id, rows[i].func, rows[i].path, rows[i].start, rows[i].end;
        missing_function = missing_function + 1;
      }
    }
  }

  // Overlapping identity ranges between DIFFERENT candidate IDs.
  //
  // NESTING IS NOT A CONFLICT.  A structural sub-slice legitimately
  // lives INSIDE its enclosing function's whole-function range (for
  // example SUB-003 inside SUB-007).  That is the normal shape of a
  // bounded sub-decision and must NOT be reported.
  //
  // The LIVE CENSUS is the authority for "whole function": a row whose
  // range is EXACTLY the live function's range is a whole-function
  // row, and a whole-function row legitimately overlaps the bounded
  // sub-slice rows of the same function.
  //
  // What IS a conflict is two DIFFERENT candidate decisions whose
  // ranges overlap while NEITHER contains the other, or two rows that
  // claim the EXACT SAME decision region.  Those two shapes corrupt
  // the identity of at least one of the rows.
  for (I64 i = 0; i < nrows; i = i + 1) {
    for (I64 j = i + 1; j < nrows; j = j + 1) {
      if (StrEq(rows[i].id, rows[j].id)) continue;
      if (!StrEq(rows[i].path, rows[j].path)) continue;
      I64 a1 = rows[i].start; I64 a2 = rows[i].end;
      I64 b1 = rows[j].start; I64 b2 = rows[j].end;
      if (!(a1 <= b2 && b1 <= a2)) continue;
      // A row that spans a WHOLE LIVE FUNCTION may legitimately overlap
      // the bounded sub-rows of that same function.
      I64 a_whole = IsWholeFunctionRow(a1, a2, rows[i].func, rows[i].path);
      I64 b_whole = IsWholeFunctionRow(b1, b2, rows[j].func, rows[j].path);
      I64 a_in_b = (a1 >= b1 && a2 <= b2);
      I64 b_in_a = (b1 >= a1 && b2 <= a2);
      I64 same_decision = 0;
      if (a1 == b1 && a2 == b2) same_decision = 1;
      if (!a_in_b && !b_in_a && !a_whole && !b_whole) same_decision = 1;
      if (same_decision) {
        "DETECTOR=OVERLAPPING_IDENTITY\nCANDIDATE_ID_A=%s\nRANGE_A=%d..%d\nCANDIDATE_ID_B=%s\nRANGE_B=%d..%d\n",
          rows[i].id, a1, a2, rows[j].id, b1, b2;
        overlapping = overlapping + 1;
      }
    }
  }

  "IDENTITY_ROWS=%d\n", nrows;
  "DUPLICATE_ID=%d\n", dup_ids;
  "INVALID_RANGE=%d\n", invalid_range;
  "SOURCE_HASH_MISMATCH=%d\n", hash_mismatch;
  "MISSING_FUNCTION=%d\n", missing_function;
  "OVERLAPPING_IDENTITY=%d\n", overlapping;
  "MALFORMED_FACT=%d\n", malformed;
  if (dup_ids == 0 && invalid_range == 0 && hash_mismatch == 0 &&
      missing_function == 0 && overlapping == 0 && malformed == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=DEPENDS
//
//   argv: MODE DEPENDS <ids.tsv> <file.c> ...
//
// The candidate-identity table uses the SAME schema as MODE=IDENTITY,
// but field 9 (when present) names ONE mutable host-state TOKEN that
// the candidate's decision is claimed NOT to depend on.
//
// The verifier extracts the LIVE source bytes of the candidate's
// enclosing function and searches them for that token.  When the
// token IS present, the claim "the projection does not depend on it"
// is FALSE and the verifier reports:
//
//   DETECTOR=MUTABLE_HOST_STATE_DEPENDENCE
//
// This is the detector for EC-05: a candidate that suppresses
// SUB-005's mutable symbol-table dependence cannot be certified by
// assertion, only by the live bytes.
//
// When the token is absent, the verifier reports the positive result
// NO_MUTABLE_HOST_STATE_DEPENDENCE for that candidate.
//
// A candidate with NO token field is reported as UNBOUND and does not
// count as a positive verification.
// ------------------------------------------------------------------

static I64 ModeDepends(U8 *ids_path, U8 *files[], I64 nfiles)
{
  LIVEFUNC_COUNT = 0;
  I64 tlen = 0;
  U8 *tbl = FileRead(ids_path, &tlen);
  if (tbl == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_IDENTITY_TABLE\nINPUT=%s\n", ids_path;
    return 1;
  }
  U8 *srcs[MAX_FILES];
  I64 lens[MAX_FILES];
  for (I64 f = 0; f < nfiles; f = f + 1) {
    lens[f] = 0;
    srcs[f] = FileRead(files[f], &lens[f]);
    if (srcs[f] == NULL) {
      "STATUS=FAIL\nREASON=CANNOT_READ_SOURCE\nFILE=%s\n", files[f];
      return 1;
    }
  }

  I64 checked = 0;
  I64 dependent = 0;
  I64 independent = 0;
  I64 unbound = 0;

  // Scan the LIVE sources so that the enclosing-function ranges are
  // known from the bytes.
  {
    U8 *scratch = MAlloc(8 * 1024 * 1024);
    I64 slen = 0;
    for (I64 f = 0; f < nfiles; f = f + 1) {
      ScanFile(files[f], srcs[f], lens[f], scratch, &slen);
    }
    Free(scratch);
  }

  // The TRANSITIVE search also consults the HOST CONTROL TU, because a
  // decision can reach the mutable host state through a callee that
  // lives OUTSIDE the parser census set.  SUB-005 is the live example:
  // parseDeclOrStatement calls cctrlIsKeyword, and cctrlIsKeyword
  // reaches cc->symbol_table through cctrlGetKeyWord -- both in
  // src/cctrl.c, which is not one of the four census files.
  //
  // The extra TU is APPENDED to the search set only.  It does not
  // change the census, the identity table, or the eligibility facts.
  U8 *searchfiles[MAX_FILES + 2];
  I64 nsearch = nfiles;
  for (I64 f = 0; f < nfiles; f = f + 1) searchfiles[f] = files[f];
  U8 *hostctrl = "src/cctrl.c";
  I64 hclen = 0;
  U8 *hcsrc = FileRead(hostctrl, &hclen);
  if (hcsrc != NULL) {
    searchfiles[nsearch] = hostctrl;
    nsearch = nsearch + 1;
    U8 *scratch = MAlloc(8 * 1024 * 1024);
    I64 slen = 0;
    ScanFile(hostctrl, hcsrc, hclen, scratch, &slen);
    Free(scratch);
  }

  // The identity table is parsed FIRST so that the ENCLOSING FUNCTION
  // of each candidate row is known.  The enclosing function is the
  // row that names the same function and whose range CONTAINS this
  // row's range.
  IdRow rows[MAX_ROWS];
  I64 nrows = 0;
  {
    I64 q = 0;
    U8 *g[12];
    while (q < tlen) {
      I64 ls = q;
      while (q < tlen && tbl[q] != '\n') q = q + 1;
      I64 len = q - ls;
      if (q < tlen) q = q + 1;
      if (len <= 0) continue;
      U8 *line = MAlloc(len + 1);
      for (I64 z = 0; z < len; z = z + 1) line[z] = tbl[ls + z];
      line[len] = 0;
      if (line[0] == '#') { Free(line); continue; }
      I64 nf = SplitTabs(line, g, 12);
      if (nf >= 6 && nrows < MAX_ROWS) {
        rows[nrows].id = DupStr(g[0]);
        rows[nrows].path = DupStr(g[1]);
        rows[nrows].start = ParseI64(g[2]);
        rows[nrows].end = ParseI64(g[3]);
        rows[nrows].sha = DupStr(g[4]);
        rows[nrows].func = DupStr(g[5]);
        nrows = nrows + 1;
      }
      Free(line);
    }
  }

  I64 p = 0;
  U8 *f[12];
  while (p < tlen) {
    I64 ls = p;
    while (p < tlen && tbl[p] != '\n') p = p + 1;
    I64 len = p - ls;
    if (p < tlen) p = p + 1;
    if (len <= 0) continue;
    U8 *line = MAlloc(len + 1);
    for (I64 z = 0; z < len; z = z + 1) line[z] = tbl[ls + z];
    line[len] = 0;
    if (line[0] == '#') { Free(line); continue; }
    I64 nf = SplitTabs(line, f, 12);
    if (nf < 9) {
      "CANDIDATE_ID=%s\nDETECTOR=UNBOUND_DEPENDENCY\nREASON=NO_MUTABLE_STATE_TOKEN_BOUND\n", f[0];
      unbound = unbound + 1;
      Free(line);
      continue;
    }
    // The split fields point INTO `line`, which is released at the end
    // of this iteration, so every field is COPIED out first.
    U8 *id = DupStr(f[0]);
    U8 *path = DupStr(f[1]);
    I64 start = ParseI64(f[2]);
    I64 end = ParseI64(f[3]);
    U8 *token = DupStr(f[8]);
    U8 *func = DupStr(f[5]);

    I64 fi = -1;
    for (I64 z = 0; z < nfiles; z = z + 1) if (StrEq(files[z], path)) fi = z;
    if (fi < 0) { Free(line); continue; }

    // The dependency check is performed over the ENCLOSING FUNCTION's
    // byte range, because the question EC-05 asks is whether the
    // enclosing decision consults the mutable host state at all.  For
    // a whole-function candidate the candidate's own range IS the
    // function's range; for a bounded sub-slice the enclosing range is
    // the row that names the SAME function IN THE SAME FILE and whose
    // range CONTAINS this row's range.
    //
    // The match is on (file, function) together.  Matching on the
    // function name alone would widen a sub-slice to an unrelated
    // function of the same name in another file.
    // The DIRECT search is over the candidate's OWN range: the
    // bounded sub-decision itself.  The TRANSITIVE search then follows
    // the functions THAT OWN RANGE CALLS DIRECTLY.
    //
    // Using the ENCLOSING FUNCTION's range for the transitive search
    // would over-report: a bounded sub-decision that calls nothing
    // (SUB-003 reads two AstKind values and calls no helper) would be
    // reported as depending on whatever its enclosing function calls.
    // That is a property of the enclosing function, which the ACT
    // explicitly leaves on the C side of the seam.
    I64 lo = start;
    I64 hi = end;

    // Extract the byte range and search for the token.
    I64 boff = OffsetOfLine(srcs[fi], lens[fi], lo);
    I64 eoff = OffsetOfLine(srcs[fi], lens[fi], hi + 1);
    if (eoff > lens[fi]) eoff = lens[fi];
    I64 rlen = eoff - boff;
    if (rlen < 0) rlen = 0;

    I64 toklen = 0;
    while (token[toklen] != 0) toklen = toklen + 1;
    // The token "-" is the explicit "NO mutable state token is bound
    // to this candidate" marker.  It is NOT a searchable token: a
    // candidate with no bound token must be reported as UNBOUND, not
    // as a false dependence on the literal hyphen.
    if (StrEq(token, "-")) toklen = 0;

    I64 hit = 0;
    I64 hit_site = 0;
    if (toklen > 0) {
      for (I64 z = 0; z + toklen <= rlen; z = z + 1) {
        I64 eq = 1;
        for (I64 w = 0; w < toklen; w = w + 1) {
          if (srcs[fi][boff + z + w] != token[w]) { eq = 0; break; }
        }
        if (eq) { hit = 1; hit_site = 1; break; }
      }
    }

    // TRANSITIVE DEPENDENCE.
    //
    // A decision may reach the mutable host state through a CALLEE
    // rather than through its own text.  SUB-005 is the live example:
    // its own three lines call cctrlIsKeyword, and cctrlIsKeyword
    // reaches cc->symbol_table through cctrlGetKeyWord -- a SECOND
    // level.  Searching only the candidate's own bytes would
    // therefore certify a FALSE "no dependence" claim.
    //
    // So the search is EXPANDED to the bodies of the functions the
    // candidate's range CALLS, and then ONE MORE LEVEL: the functions
    // THOSE call.  Two levels is exactly the depth at which the live
    // dependence lives, and two levels is still a bounded expansion.
    if (!hit && toklen > 0) {
      // Collect the identifiers that the candidate's range calls.
      U8 *called[MAX_TOKENS];
      I64 ncalled = 0;
      I64 r = boff;
      while (r < eoff && ncalled < MAX_TOKENS) {
        I64 rc = srcs[fi][r];
        if (rc == '"' || rc == '\'') { r = SkipQuoted(srcs[fi], lens[fi], r, &r); continue; }
        if (IsIdChar(rc)) {
          U8 nm[NAME_MAX];
          I64 nl = 0;
          while (r < eoff && IsIdChar(srcs[fi][r])) {
            if (nl < NAME_MAX - 1) { nm[nl] = srcs[fi][r]; nl = nl + 1; }
            r = r + 1;
          }
          nm[nl] = 0;
          I64 s = r;
          while (s < eoff && IsSpaceCh(srcs[fi][s])) s = s + 1;
          if (s < eoff && srcs[fi][s] == '(' && nl > 0 && !IsCKeyword(nm) && !IsTypeToken(nm)) {
            I64 dup = 0;
            for (I64 z = 0; z < ncalled; z++) if (StrEq(called[z], nm)) dup = 1;
            if (!dup) { called[ncalled] = DupStr(nm); ncalled = ncalled + 1; }
          }
          continue;
        }
        r = r + 1;
      }
      // Search the body of each called function, and of the functions
      // THAT calls, in the LIVE census.
      for (I64 level = 0; level < 2 && !hit; level = level + 1) {
        I64 nnext = 0;
        for (I64 z = 0; z < ncalled && !hit; z = z + 1) {
          for (I64 g = 0; g < LIVEFUNC_COUNT; g++) {
            if (!StrEq(LIVEFUNC[g].name, called[z])) continue;
            I64 gfi = -1;
            for (I64 q = 0; q < nsearch; q = q + 1) if (StrEq(searchfiles[q], LIVEFUNC[g].path)) gfi = q;
            if (gfi < 0) continue;
            U8 *gsrc = srcs[gfi];
            I64 glen_total = lens[gfi];
            if (gfi >= nfiles) { gsrc = hcsrc; glen_total = hclen; }
            I64 gb = OffsetOfLine(gsrc, glen_total, LIVEFUNC[g].start);
            I64 ge = OffsetOfLine(gsrc, glen_total, LIVEFUNC[g].end + 1);
            if (ge > glen_total) ge = glen_total;
            I64 glen = ge - gb;
            if (glen < 0) glen = 0;
            // Search the body for the token.
            for (I64 y = 0; y + toklen <= glen; y = y + 1) {
              I64 eq = 1;
              for (I64 w = 0; w < toklen; w = w + 1) {
                if (gsrc[gb + y + w] != token[w]) { eq = 0; break; }
              }
              if (eq) { hit = 1; hit_site = 2; break; }
            }
            if (hit) break;
            // Collect the functions THIS one calls, for the next level.
            if (level == 0) {
              I64 q = gb;
              while (q < ge && nnext < MAX_TOKENS) {
                I64 qc = gsrc[q];
                if (qc == '"' || qc == '\'') { q = SkipQuoted(gsrc, glen_total, q, &q); continue; }
                if (IsIdChar(qc)) {
                  U8 nm[NAME_MAX];
                  I64 nl = 0;
                  while (q < ge && IsIdChar(gsrc[q])) {
                    if (nl < NAME_MAX - 1) { nm[nl] = gsrc[q]; nl = nl + 1; }
                    q = q + 1;
                  }
                  nm[nl] = 0;
                  I64 s = q;
                  while (s < ge && IsSpaceCh(gsrc[s])) s = s + 1;
                  if (s < ge && gsrc[s] == '(' && nl > 0 && !IsCKeyword(nm) && !IsTypeToken(nm)) {
                    I64 dup = 0;
                    for (I64 w = 0; w < nnext; w++) if (StrEq(called[w], nm)) dup = 1;
                    if (!dup) { called[nnext] = DupStr(nm); nnext = nnext + 1; }
                  }
                  continue;
                }
                q = q + 1;
              }
            }
          }
        }
        ncalled = nnext;
        if (ncalled == 0) break;
      }
    }

    checked = checked + 1;
    if (toklen == 0) {
      "CANDIDATE_ID=%s\nDETECTOR=UNBOUND_DEPENDENCY\nREASON=EMPTY_MUTABLE_STATE_TOKEN\n", id;
      unbound = unbound + 1;
    } else if (hit) {
      U8 *site = "DIRECT_IN_THE_CANDIDATE_RANGE";
      if (hit_site == 2) site = "TRANSITIVE_THROUGH_A_CALLEE";
      "CANDIDATE_ID=%s\nDETECTOR=MUTABLE_HOST_STATE_DEPENDENCE\nMUTABLE_STATE_TOKEN=%s\nFILE=%s\nENCLOSING_RANGE=%d..%d\nDEPENDENCE_SITE=%s\n",
        id, token, path, lo, hi, site;
      dependent = dependent + 1;
    } else {
      "CANDIDATE_ID=%s\nDETECTOR=NONE\nRESULT=NO_MUTABLE_HOST_STATE_DEPENDENCE\nMUTABLE_STATE_TOKEN=%s\nFILE=%s\nENCLOSING_RANGE=%d..%d\n",
        id, token, path, lo, hi;
      independent = independent + 1;
    }
    Free(line);
  }

  "DEPENDS_CHECKED=%d\n", checked;
  "MUTABLE_HOST_STATE_DEPENDENCE=%d\n", dependent;
  "NO_MUTABLE_HOST_STATE_DEPENDENCE=%d\n", independent;
  "UNBOUND_DEPENDENCY=%d\n", unbound;
  if (dependent == 0 && unbound == 0) { "STATUS=PASS\n"; return 0; }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=AUTHORITY
//
// For each declared PolyC parser authority the tool checks THREE
// mechanical facts about the LIVE production artifacts:
//
//   1. the dedicated delegation macro is present in the live
//      production compile flags;
//   2. the PolyC symbol appears as an UNDEFINED reference (U) in the
//      live production object -- the object imports the PolyC
//      decision;
//   3. the PolyC symbol is NOT DEFINED (T) in that same object -- the
//      legacy C body is compiled out, so C does not still own the
//      decision.
//
// A symbol that merely exists in the final binary does NOT satisfy
// this check.
// ------------------------------------------------------------------

static I64 ObjHasUndefined(U8 *nmtext, U8 *sym)
{
  U8 *p = nmtext;
  while (*p) {
    U8 *nl = p;
    while (*nl && *nl != '\n') nl = nl + 1;
    I64 len = nl - p;
    I64 end = len;
    while (end > 0 && (p[end-1] == ' ' || p[end-1] == '\t' || p[end-1] == '\r')) end = end - 1;
    I64 st = end;
    while (st > 0 && p[st-1] != ' ' && p[st-1] != '\t') st = st - 1;
    I64 symlen = end - st;
    I64 typeidx = -1;
    I64 te = st;
    while (te > 0 && (p[te-1] == ' ' || p[te-1] == '\t')) te = te - 1;
    I64 ts = te;
    while (ts > 0 && p[ts-1] != ' ' && p[ts-1] != '\t') ts = ts - 1;
    if (te > ts) {
      if (p[ts] == 'U') typeidx = 0;
      else if (p[ts] == 'T') typeidx = 1;
    }
    I64 k = 0;
    if (symlen > 0 && p[st] == '_') { k = 1; }
    U8 want[NAME_MAX];
    I64 wl = 0;
    while (sym[wl] != 0 && wl < NAME_MAX - 1) { want[wl] = sym[wl]; wl = wl + 1; }
    want[wl] = 0;
    if (symlen - k == wl) {
      I64 eq = 1;
      for (I64 z = 0; z < wl; z = z + 1) if (p[st+k+z] != want[z]) { eq = 0; break; }
      if (eq) {
        if (typeidx == 0) return 1;   // U
        if (typeidx == 1) return 2;   // T
        return 3;                      // other
      }
    }
    if (!*nl) break;
    p = nl + 1;
  }
  return 0;
}

static I64 FileContains(U8 *hay, I64 haylen, U8 *needle)
{
  I64 nl = 0;
  while (needle[nl] != 0) nl = nl + 1;
  if (nl == 0) return 1;
  for (I64 i = 0; i + nl <= haylen; i = i + 1) {
    I64 eq = 1;
    for (I64 z = 0; z < nl; z = z + 1) if (hay[i+z] != needle[z]) { eq = 0; break; }
    if (eq) return 1;
  }
  return 0;
}

static I64 ModeAuthority(U8 *flags_path, U8 *nm_path, U8 *syms[], I64 nsyms)
{
  I64 flen = 0;
  U8 *flags = FileRead(flags_path, &flen);
  if (flags == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_FLAGS\nFILE=%s\n", flags_path;
    return 1;
  }
  I64 nlen = 0;
  U8 *nmtext = FileRead(nm_path, &nlen);
  if (nmtext == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_NM\nFILE=%s\n", nm_path;
    return 1;
  }
  I64 pass = 0;
  for (I64 i = 0; i < nsyms; i = i + 1) {
    U8 *macro = syms[i];
    U8 *sym = syms[i];
    I64 ml = 0;
    I64 sep = 0;
    for (I64 z = 0; syms[i][z] != 0; z = z + 1) {
      if (syms[i][z] == '|') { sep = 1; break; }
    }
    if (sep) {
      ml = 0;
      while (sym[ml] != 0 && sym[ml] != '|') ml = ml + 1;
      U8 mbuf[NAME_MAX];
      for (I64 z = 0; z < ml && z < NAME_MAX - 1; z = z + 1) mbuf[z] = sym[z];
      mbuf[ml] = 0;
      macro = mbuf;
      sym = sym + ml + 1;
    }
    I64 u = ObjHasUndefined(nmtext, sym);
    I64 def_here = 0;
    if (u == 2) def_here = 1;
    I64 macro_on = FileContains(flags, flen, macro);
    I64 ok = 0;
    if (macro_on && u == 1 && !def_here) ok = 1;
    if (ok) pass = pass + 1;
    U8 *s_macro = "NO"; if (macro_on) s_macro = "YES";
    U8 *s_undef = "NO"; if (u == 1) s_undef = "YES";
    U8 *s_def = "NO"; if (def_here) s_def = "YES";
    U8 *s_res = "FAIL"; if (ok) s_res = "PASS";
    "AUTHORITY\t%s\t%s\tMACRO_ENABLED=%s\tOBJ_UNDEFINED_REF=%s\tOBJ_DEFINED_HERE=%s\tRESULT=%s\n",
      macro, sym, s_macro, s_undef, s_def, s_res;
  }
  "AUTHORITIES_EXPECTED=%d\n", nsyms;
  "AUTHORITIES_VERIFIED=%d\n", pass;
  if (pass == nsyms && nsyms > 0) { "STATUS=PASS\n"; return 0; }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=RANGE
//
//   argv: MODE RANGE <file.c> <start> <end> [<file.c> <start> <end> ...]
//
// Emits the SHA-256 of the source byte range [start_line .. end_line]
// inclusive, using the SAME byte-range convention as MODE=CENSUS and
// MODE=IDENTITY.
// ------------------------------------------------------------------

static I64 ModeRange(U8 *files[], I64 nspecs, I64 *starts, I64 *ends)
{
  I64 total = 0;
  I64 fail = 0;
  for (I64 s = 0; s < nspecs; s = s + 1) {
    U8 *path = files[s];
    I64 len = 0;
    U8 *src = FileRead(path, &len);
    if (src == NULL) {
      "STATUS=FAIL\nREASON=CANNOT_READ_SOURCE\nFILE=%s\n", path;
      return 1;
    }
    U8 hex[65];
    ShaOfLineRange(src, len, starts[s], ends[s], hex);
    "RANGE\t%s\t%d\t%d\t%s\n", path, starts[s], ends[s], hex;
    total = total + 1;
    Free(src);
  }
  "RANGE_TOTAL=%d\n", total;
  "RANGE_FAILURES=%d\n", fail;
  if (fail == 0) { "STATUS=PASS\n"; return 0; }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=CENSUS (driver)
//
//   argv: MODE CENSUS <out.tsv> <file.c> ...
// ------------------------------------------------------------------

static I64 ModeCensus(U8 *out_path, U8 *files[], I64 nfiles)
{
  U8 *buf = MAlloc(8 * 1024 * 1024);
  I64 blen = 0;
  I64 total = 0;
  for (I64 f = 0; f < nfiles; f = f + 1) {
    I64 len = 0;
    U8 *src = FileRead(files[f], &len);
    if (src == NULL) {
      "STATUS=FAIL\nREASON=CANNOT_READ_SOURCE\nFILE=%s\n", files[f];
      return 1;
    }
    total = total + ScanFile(files[f], src, len, buf, &blen);
    Free(src);
  }
  buf[blen] = 0;
  Bool wrote = FileWrite(out_path, buf, blen);
  if (!wrote) {
    "STATUS=FAIL\nREASON=WRITE_FAILED\nOUTPUT=%s\n", out_path;
    return 1;
  }
  "CENSUS_FILES=%d\n", nfiles;
  "CENSUS_FUNCTIONS=%d\n", total;
  "CENSUS_OUTPUT=%s\n", out_path;
  "STATUS=PASS\n";
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "USAGE=parser-surface-recon05-verify CENSUS|IDENTITY|DEPENDS|AUTHORITY|RANGE ...\n";
    "STATUS=FAIL\nREASON=NO_MODE\n";
    return 2;
  }
  if (StrEq(argv[1], "CENSUS")) {
    if (argc < 4) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    return ModeCensus(argv[2], &argv[3], argc - 3);
  }
  if (StrEq(argv[1], "REGISTRY")) {
    if (argc < 5) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    return ModeRegistry(argv[2], argv[3], &argv[4], argc - 4);
  }
  if (StrEq(argv[1], "IDENTITY")) {
    if (argc < 4) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    return ModeIdentity(argv[2], &argv[3], argc - 3);
  }
  if (StrEq(argv[1], "DEPENDS")) {
    if (argc < 4) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    return ModeDepends(argv[2], &argv[3], argc - 3);
  }
  if (StrEq(argv[1], "AUTHORITY")) {
    if (argc < 5) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    return ModeAuthority(argv[2], argv[3], &argv[4], argc - 4);
  }
  if (StrEq(argv[1], "RANGE")) {
    if (argc < 5) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    if (((argc - 2) % 3) != 0) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    I64 nspecs = (argc - 2) / 3;
    if (nspecs > MAX_RANGES) { "STATUS=FAIL\nREASON=TOO_MANY_RANGES\n"; return 2; }
    U8 *files[MAX_RANGES];
    I64 starts[MAX_RANGES];
    I64 ends[MAX_RANGES];
    for (I64 i = 0; i < nspecs; i = i + 1) {
      files[i] = argv[2 + i*3];
      starts[i] = ParseI64(argv[3 + i*3]);
      ends[i] = ParseI64(argv[4 + i*3]);
    }
    return ModeRange(files, nspecs, starts, ends);
  }
  "STATUS=FAIL\nREASON=UNKNOWN_MODE\nMODE=%s\n", argv[1];
  return 2;
}
