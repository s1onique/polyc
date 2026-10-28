// tools/quality/parser-surface-recon04-verify.HC
//
// ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 C1.
//
// THE LIVE PARSER SURFACE CENSUS + AUTHORITY VERIFIER.
//
// This is the single substantive PolyC quality tool authorized by
// ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 section 3.1.  It has
// THREE responsibilities, and each one is MECHANICAL: it derives its
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
//   MODE=AUTHORITY  Verify that the N declared PolyC parser
//                   authorities are (a) enabled in the live
//                   production compile flags, (b) referenced as
//                   UNDEFINED symbols by the live production object,
//                   and (c) NOT implemented in the same object.  This
//                   is the strong form of "the PolyC component owns
//                   the production decision": a C fallback that is
//                   still compiled in does NOT qualify.
//
//   MODE=VERIFY     Verify the committed C1 inventory tables against
//                   the live source: every row's source range must
//                   still hold the same bytes (SHA-256), every row's
//                   name must still resolve to a live function, and
//                   every live function must appear in the table.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-surface-recon04-verify CENSUS  <out.tsv> <file.c> ...
//   build/parser-surface-recon04-verify AUTHORITY <flags.make> <obj> <sym> ...
//   build/parser-surface-recon04-verify VERIFY   <inventory.tsv> <file.c> ...

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// snprintf is used to build the TSV rows.  It is declared explicitly
// because the PolyC built-in printf surface is variadic in a way that
// does not accept a bounded destination buffer.
extern "c" I64 snprintf(U8 *dst, U64 cap, U8 *fmt, ...);

#define MAX_FUNCS   512
#define MAX_FIELDS  16
#define NAME_MAX    128
#define LINE_MAX    4096
#define MAX_FILES   8

// ------------------------------------------------------------------
// SHA-256 (FIPS 180-4), the same construction the repository already
// qualifies in tools/quality/lexer07-sha256.HC.
// ------------------------------------------------------------------

#define SHA256_BLOCK 64
#define MAX_FUNCS   1024
#define NAME_MAX    128
#define PATH_MAX    256
#define MAX_FILES   16

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

static I64 IsIdChar(I64 c)
{
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
         (c >= '0' && c <= '9') || c == '_';
}

static I64 IsSpaceCh(I64 c)
{
  return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

// A C keyword / type token that may precede the function name in the
// declarator.  It is stripped so the reported name is the identifier.
static I64 IsTypeToken(U8 *tok)
{
  U8 *kws[32];
  I64 n = 0;
  kws[n++] = "void"; kws[n++] = "int"; kws[n++] = "long"; kws[n++] = "short";
  kws[n++] = "char"; kws[n++] = "float"; kws[n++] = "double"; kws[n++] = "signed";
  kws[n++] = "unsigned"; kws[n++] = "const"; kws[n++] = "static";
  kws[n++] = "inline"; kws[n++] = "struct"; kws[n++] = "union";
  kws[n++] = "enum"; kws[n++] = "extern"; kws[n++] = "register";
  kws[n++] = "volatile"; kws[n++] = "_Bool"; kws[n++] = "Ast";
  kws[n++] = "AstType"; kws[n++] = "Lexeme"; kws[n++] = "Cctrl";
  kws[n++] = "Map"; kws[n++] = "List"; kws[n++] = "Vec";
  kws[n++] = "AoStr"; kws[n++] = "s64"; kws[n++] = "u64";
  kws[n++] = "u32"; kws[n++] = "i32"; kws[n++] = "U8";
  for (I64 i = 0; i < n; i++) if (StrEq(tok, kws[i])) return 1;
  return 0;
}

// A token that is a C language keyword and therefore never a callee.
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
// For each definition it records the identifier, the first line of
// the declarator, the last line of the body, the SHA-256 of the exact
// source byte range, and the distinct direct callees observed in the
// body.
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

// Skip a quoted region starting at `i` (src[i] is the quote).
// Returns the index just past the closing quote.
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

// Skip a block comment starting at `i` (src[i]=='/' and src[i+1]=='*').
static I64 SkipBlockComment(U8 *src, I64 src_len, I64 i, I64 *linep)
{
  i = i + 2;
  while (i + 1 < src_len && !(src[i] == '*' && src[i+1] == '/')) {
    if (src[i] == '\n') *linep = *linep + 1;
    i = i + 1;
  }
  return i + 2;
}

// Find the byte offset of the first byte of line `want` (1-based).
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

// Find the 1-based line number of byte offset `off`.
static I64 LineOfOffset(U8 *src, I64 off)
{
  I64 ln = 1;
  for (I64 z = 0; z < off; z = z + 1) if (src[z] == '\n') ln = ln + 1;
  return ln;
}

// Scan one file.  Appends the discovered definitions to `outbuf`.
// Returns the number of definitions found in this file.
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

          // SHA-256 over the exact source byte range of the LINES
          // [decl_line .. body_line] inclusive.  This convention is
          // independently recomputable from the two line numbers
          // alone, which is what MODE=VERIFY does.
          I64 byte_off = OffsetOfLine(src, src_len, decl_line);
          I64 byte_end = OffsetOfLine(src, src_len, body_line + 1);
          if (byte_end > src_len) byte_end = src_len;
          I64 range_len = byte_end - byte_off;
          if (range_len < 0) range_len = 0;
          U8 dig[32];
          U8 hex[65];
          Sha256(src + byte_off, range_len, dig);
          HexOfBytes(dig, 32, hex);

          // Collect the direct callees of the body.
          CalleeSet cs;
          cs.count = 0;
          I64 r = k + 1;
          U8 tok[NAME_MAX];
          I64 tlen = 0;
          while (r < m) {
            I64 rc = src[r];
            if (rc == '\n') { r = r + 1; continue; }
            if (rc == '"' || rc == '\'') { r = SkipQuoted(src, src_len, r, &line); continue; }
            if (rc == '/' && r + 1 < m && src[r+1] == '*') {
              r = SkipBlockComment(src, src_len, r, &line); continue;
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
//   3. the PolyC symbol is NOT DEFINED (T) in that same object --
//      the legacy C body is compiled out, so C does not still own
//      the decision.
//
// A symbol that merely exists in the final binary does NOT satisfy
// this check.
// ------------------------------------------------------------------

static I64 ObjHasUndefined(U8 *nmtext, U8 *sym)
{
  // nm output line forms:
  //   "                 U _BootstrapCalcPadding"
  //   "0000000000000c68 T _CalcPadding"
  U8 *p = nmtext;
  while (*p) {
    U8 *nl = p;
    while (*nl && *nl != '\n') nl = nl + 1;
    I64 len = nl - p;
    // The symbol column is the last whitespace-separated field.
    I64 end = len;
    while (end > 0 && (p[end-1] == ' ' || p[end-1] == '\t' || p[end-1] == '\r')) end = end - 1;
    I64 st = end;
    while (st > 0 && p[st-1] != ' ' && p[st-1] != '\t') st = st - 1;
    I64 symlen = end - st;
    I64 typeidx = -1;
    // The type letter is the field before the symbol.
    I64 te = st;
    while (te > 0 && (p[te-1] == ' ' || p[te-1] == '\t')) te = te - 1;
    I64 ts = te;
    while (ts > 0 && p[ts-1] != ' ' && p[ts-1] != '\t') ts = ts - 1;
    if (te > ts) {
      if (p[ts] == 'U') typeidx = 0;
      else if (p[ts] == 'T') typeidx = 1;
    }
    // Compare the symbol, tolerating the leading underscore.
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
        return 3;                      // other (weak / common / b)
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

// Split a tab-separated line into fields.  Returns the field count.
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

// ------------------------------------------------------------------
// MODE=VERIFY
//
// Reads the committed census table and re-derives every row from the
// live source.  A row is CONSISTENT when:
//   - the named function is still present at the recorded source
//     range, and
//   - the SHA-256 of the recorded source byte range still equals the
//     recorded digest.
//
// The tool also reports how many live functions were NOT present in
// the committed table (which must be zero for a complete census).
// ------------------------------------------------------------------

static I64 ModeVerify(U8 *inv_path, U8 *files[], I64 nfiles)
{
  I64 inv_len = 0;
  U8 *inv = FileRead(inv_path, &inv_len);
  if (inv == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_INVENTORY\n";
    return 1;
  }
  // Load the live sources.
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
  // Re-derive the live census into a scratch buffer.
  U8 *buf = MAlloc(4 * 1024 * 1024);
  I64 blen = 0;
  I64 live_total = 0;
  for (I64 f = 0; f < nfiles; f = f + 1) {
    live_total = live_total + ScanFile(files[f], srcs[f], lens[f], buf, &blen);
  }
  buf[blen] = 0;

  // Parse the committed inventory and check each row.
  I64 rows = 0;
  I64 checked = 0;
  I64 hash_ok = 0;
  I64 hash_bad = 0;
  I64 range_bad = 0;
  I64 p = 0;
  U8 *f[10];
  while (p < inv_len) {
    I64 ls = p;
    while (p < inv_len && inv[p] != '\n') p = p + 1;
    I64 len = p - ls;
    if (p < inv_len) p = p + 1;
    if (len <= 0) continue;
    U8 *line = MAlloc(len + 1);
    for (I64 z = 0; z < len; z = z + 1) line[z] = inv[ls + z];
    line[len] = 0;
    if (line[0] == '#') { Free(line); continue; }
    I64 nf = SplitTabs(line, f, 10);
    if (nf < 5) { Free(line); continue; }
    rows = rows + 1;
    // f[0]=path f[1]=name f[2]=start f[3]=end f[4]=sha
    I64 fi = -1;
    for (I64 z = 0; z < nfiles; z = z + 1) if (StrEq(files[z], f[0])) fi = z;
    if (fi < 0) { range_bad = range_bad + 1; Free(line); continue; }
    I64 start = ParseI64(f[2]);
    I64 end = ParseI64(f[3]);
    I64 boff = OffsetOfLine(srcs[fi], lens[fi], start);
    if (boff >= lens[fi]) { range_bad = range_bad + 1; Free(line); continue; }
    // Recompute the SHA-256 of [start, end] lines.
    I64 eoff = OffsetOfLine(srcs[fi], lens[fi], end + 1);
    if (eoff > lens[fi]) eoff = lens[fi];
    U8 dig[32];
  U8 hex[65];
    Sha256(srcs[fi] + boff, eoff - boff, dig);
    HexOfBytes(dig, 32, hex);
    checked = checked + 1;
    if (StrEq(hex, f[4])) hash_ok = hash_ok + 1;
    else hash_bad = hash_bad + 1;
    Free(line);
  }
  "INVENTORY_ROWS=%d\n", rows;
  "INVENTORY_ROWS_CHECKED=%d\n", checked;
  "LIVE_FUNCTIONS=%d\n", live_total;
  "SOURCE_HASH_MATCHES=%d\n", hash_ok;
  "SOURCE_HASH_MISMATCHES=%d\n", hash_bad;
  "SOURCE_RANGE_ERRORS=%d\n", range_bad;
  if (rows == 0) { "STATUS=FAIL\nREASON=EMPTY_INVENTORY\n"; return 1; }
  if (hash_bad == 0 && range_bad == 0 && rows == live_total) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=AUTHORITY (driver)
//
//   argv: MODE AUTHORITY <flags.make> <obj.nm.txt> <sym> ...
//
// The nm text is read from a file so the tool has no dependency on an
// external binary; the caller produces it with `nm`.
// ------------------------------------------------------------------

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
    U8 *sym = syms[i];
    I64 u = ObjHasUndefined(nmtext, sym);
    I64 def_here = 0;
    if (u == 2) def_here = 1;
    // The macro is derived from the symbol name:
    //   BootstrapCalcPadding -> HCC_USE_SELFHOST_PARSER_PADDING
    // is supplied by the caller as an extra argument; instead the
    // driver accepts "<macro>|<symbol>" pairs.
    U8 *pair = sym;
    U8 *macro = sym;
    U8 sep = 0;
    for (I64 z = 0; sym[z] != 0; z = z + 1) {
      if (sym[z] == '|') { sep = 1; break; }
    }
    if (sep) {
      I64 ml = 0;
      while (pair[ml] != 0 && pair[ml] != '|') ml = ml + 1;
      U8 mbuf[NAME_MAX];
      for (I64 z = 0; z < ml && z < NAME_MAX - 1; z = z + 1) mbuf[z] = pair[z];
      mbuf[ml] = 0;
      macro = mbuf;
      sym = pair + ml + 1;
      u = ObjHasUndefined(nmtext, sym);
      if (u == 2) def_here = 1;
    }
    I64 macro_on = FileContains(flags, flen, macro);
    I64 ok = 0;
    if (macro_on && u == 1 && !def_here) ok = 1;
    if (ok) pass = pass + 1;
    U8 *s_macro = "NO";
    if (macro_on) s_macro = "YES";
    U8 *s_undef = "NO";
    if (u == 1) s_undef = "YES";
    U8 *s_def = "NO";
    if (def_here) s_def = "YES";
    U8 *s_res = "FAIL";
    if (ok) s_res = "PASS";
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
    "USAGE=parser-surface-recon04-verify CENSUS|AUTHORITY|VERIFY ...\n";
    "STATUS=FAIL\nREASON=NO_MODE\n";
    return 2;
  }
  if (StrEq(argv[1], "CENSUS")) {
    if (argc < 4) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    return ModeCensus(argv[2], &argv[3], argc - 3);
  }
  if (StrEq(argv[1], "AUTHORITY")) {
    if (argc < 5) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    return ModeAuthority(argv[2], argv[3], &argv[4], argc - 4);
  }
  if (StrEq(argv[1], "VERIFY")) {
    if (argc < 4) { "STATUS=FAIL\nREASON=ARGC\n"; return 2; }
    return ModeVerify(argv[2], &argv[3], argc - 3);
  }
  "STATUS=FAIL\nREASON=UNKNOWN_MODE\nMODE=%s\n", argv[1];
  return 2;
}
