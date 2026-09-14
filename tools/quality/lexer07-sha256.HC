// tools/quality/lexer07-sha256.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05 C2 IMPL.
// PolyC-local SHA-256 (FIPS 180-4). Verified against
// NIST SHA-2 Additional Test Data vectors including the
// 55/56/57-byte zero-byte padding-boundary cases.

#include "../../src/holyc-lib/memory_defs.HH"

#define SHA256_BLOCK 64

class SHA256Ctx {
  U32 state[8];
  U64 bitlen;
  U8  buf[SHA256_BLOCK];
  I64 buflen;
};

static U32 K[64] = {
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static U32 ROTR(U32 x, U32 n) { U32 hi=x>>n; U32 lo=(x<<(32-n))&0xffffffff; return (hi|lo)&0xffffffff; }
static U32 LoadBE(U8 *p) { U32 b0=p[0]; U32 b1=p[1]; U32 b2=p[2]; U32 b3=p[3]; return ((b0<<24)|(b1<<16)|(b2<<8)|b3)&0xffffffff; }
static U0 StoreBE(U8 *p, U32 v) { p[0]=(v>>24)&0xff; p[1]=(v>>16)&0xff; p[2]=(v>>8)&0xff; p[3]=v&0xff; }


U0 SHA256Init(SHA256Ctx *ctx) {
  ctx->state[0]=0x6a09e667; ctx->state[1]=0xbb67ae85;
  ctx->state[2]=0x3c6ef372; ctx->state[3]=0xa54ff53a;
  ctx->state[4]=0x510e527f; ctx->state[5]=0x9b05688c;
  ctx->state[6]=0x1f83d9ab; ctx->state[7]=0x5be0cd19;
  ctx->bitlen=0; ctx->buflen=0;
}

static U0 SHA256Transform(SHA256Ctx *ctx, U8 *block) {
  U32 w[64];
  for (I64 i = 0; i < 16; i = i + 1) {
    w[i] = LoadBE(block + i + i + i + i);
  }
  for (I64 i = 16; i < 64; i = i + 1) {
    U32 s0 = ROTR(w[i-15],7) ^ ROTR(w[i-15],18) ^ (w[i-15]>>3);
    U32 s1 = ROTR(w[i-2],17) ^ ROTR(w[i-2],19) ^ (w[i-2]>>10);
    w[i] = (w[i-16]+s0+w[i-7]+s1) & 0xffffffff;
  }
  U32 a=ctx->state[0]; U32 b=ctx->state[1]; U32 c=ctx->state[2]; U32 d=ctx->state[3];
  U32 e=ctx->state[4]; U32 f=ctx->state[5]; U32 g=ctx->state[6]; U32 h=ctx->state[7];
  for (I64 i = 0; i < 64; i = i + 1) {
    U32 S1 = ROTR(e,6) ^ ROTR(e,11) ^ ROTR(e,25);
    U32 ch = (e & f) ^ ((~e) & g);
    U32 t1 = (h+S1+ch+K[i]+w[i]) & 0xffffffff;
    U32 S0 = ROTR(a,2) ^ ROTR(a,13) ^ ROTR(a,22);
    U32 mj = (a&b) ^ (a&c) ^ (b&c);
    U32 t2 = (S0+mj) & 0xffffffff;
    h=g; g=f; f=e; e=(d+t1)&0xffffffff;
    d=c; c=b; b=a; a=(t1+t2)&0xffffffff;
  }
  ctx->state[0]=(ctx->state[0]+a)&0xffffffff; ctx->state[1]=(ctx->state[1]+b)&0xffffffff;
  ctx->state[2]=(ctx->state[2]+c)&0xffffffff; ctx->state[3]=(ctx->state[3]+d)&0xffffffff;
  ctx->state[4]=(ctx->state[4]+e)&0xffffffff; ctx->state[5]=(ctx->state[5]+f)&0xffffffff;
  ctx->state[6]=(ctx->state[6]+g)&0xffffffff; ctx->state[7]=(ctx->state[7]+h)&0xffffffff;
}

U0 SHA256Update(SHA256Ctx *ctx, U8 *buf, I64 len) {
  U64 lbits = len;
  ctx->bitlen = ctx->bitlen + lbits * 8;
  while (len > 0) {
    I64 take = SHA256_BLOCK - ctx->buflen;
    if (take > len) take = len;
    MemCpy(ctx->buf + ctx->buflen, buf, take);
    ctx->buflen = ctx->buflen + take;
    buf = buf + take;
    len = len - take;
    if (ctx->buflen == SHA256_BLOCK) {
      SHA256Transform(ctx, ctx->buf);
      ctx->buflen = 0;
    }
  }
}

U0 SHA256Final(SHA256Ctx *ctx, U8 *out32) {
  ctx->buf[ctx->buflen] = 0x80;
  ctx->buflen = ctx->buflen + 1;
  if (ctx->buflen > 56) {
    MemSet(ctx->buf + ctx->buflen, 0, SHA256_BLOCK - ctx->buflen);
    SHA256Transform(ctx, ctx->buf);
    ctx->buflen = 0;
  }
  MemSet(ctx->buf + ctx->buflen, 0, 56 - ctx->buflen);
  U64 bl = ctx->bitlen;
  for (I64 i = 0; i < 8; i = i + 1) {
    U8 b = (bl >> (56 - i * 8)) & 0xff;
    ctx->buf[56 + i] = b;
  }
  SHA256Transform(ctx, ctx->buf);
  for (I64 i = 0; i < 8; i = i + 1) StoreBE(out32 + i + i + i + i, ctx->state[i]);
}

U0 SHA256(U8 *buf, I64 len, U8 *out32) {
  SHA256Ctx ctx;
  SHA256Init(&ctx);
  SHA256Update(&ctx, buf, len);
  SHA256Final(&ctx, out32);
}

U0 HexOfBytes(U8 *bytes, I64 n, U8 *dst) {
  U8 *hex = "0123456789abcdef";
  U8 hi_buf[128]; U8 lo_buf[128]; U8 out_buf[256];
  for (I64 i = 0; i < n; i = i + 1) {
    U8 b = bytes[i];
    I64 hi = (b >> 4) & 0xf;
    I64 lo = b & 0xf;
    hi_buf[i] = hex[hi];
    lo_buf[i] = hex[lo];
  }
  for (I64 i = 0; i < n; i = i + 1) {
    I64 o2 = i + i;
    out_buf[o2] = hi_buf[i];
    out_buf[o2 + 1] = lo_buf[i];
  }
  for (I64 i = 0; i < n + n; i = i + 1) dst[i] = out_buf[i];
  dst[n + n] = 0;
}

static I64 HexEq(U8 *got, U8 *want) {
  I64 i = 0;
  while (want[i] != 0) { if (got[i] != want[i]) return 0; i = i + 1; }
  return got[i] == 0;
}

I64 SHA256SelfTest() {
  U8 dig[32]; U8 hex[65]; I64 fail = 0;
  SHA256(NULL, 0, dig); HexOfBytes(dig, 32, hex);
  "SHA256(\"\")        = %s\n", hex;
  if (!HexEq(hex, "e3b0c44298fc1c149afbf4c8996fb924"
                   "27ae41e4649b934ca495991b7852b855")) fail = fail + 1;
  U8 *abc = "abc"; SHA256(abc, 3, dig); HexOfBytes(dig, 32, hex);
  "SHA256(\"abc\")     = %s\n", hex;
  if (!HexEq(hex, "ba7816bf8f01cfea414140de5dae2223"
                   "b00361a396177a9cb410ff61f20015ad")) fail = fail + 1;
  U8 zero[64]; MemSet(zero, 0, 64);
  SHA256(zero, 55, dig); HexOfBytes(dig, 32, hex);
  "SHA256(55 * 0x00)  = %s\n", hex;
  if (!HexEq(hex, "02779466cdec163811d078815c633f21"
                   "901413081449002f24aa3e80f0b88ef7")) fail = fail + 1;
  SHA256(zero, 56, dig); HexOfBytes(dig, 32, hex);
  "SHA256(56 * 0x00)  = %s\n", hex;
  if (!HexEq(hex, "d4817aa5497628e7c77e6b606107042b"
                   "bba3130888c5f47a375e6179be789fbb")) fail = fail + 1;
  SHA256(zero, 57, dig); HexOfBytes(dig, 32, hex);
  "SHA256(57 * 0x00)  = %s\n", hex;
  if (!HexEq(hex, "65a16cb7861335d5ace3c60718b5052e"
                   "44660726da4cd13bb745381b235a1785")) fail = fail + 1;
  if (fail == 0) { "SHA256_SELFTEST=PASS\n"; return 0; }
  "SHA256_SELFTEST=FAIL count=%d\n", fail; return 1;
}

I32 Main(I32 argc, U8 **argv) {
  if (argc > 1) {
    U8 dig[32]; U8 hex[65];
    SHA256(argv[1], StrLen(argv[1]), dig);
    HexOfBytes(dig, 32, hex);
    "%s\n", hex;
    return 0;
  }
  return SHA256SelfTest();
}
