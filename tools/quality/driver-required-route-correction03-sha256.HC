// tools/quality/driver-required-route-correction03-sha256.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 3, P2-1 -- THE REAL SHA-256.
//
// The previous rounds labelled a 16-hex-digit FNV-1a 64 digest "SHA256".
// That was a false claim: FNV-1a is a NONCRYPTOGRAPHIC checksum and its
// 64-bit output is not a SHA-256 digest. The P2 finding required that the
// repository's REAL SHA-256 implementation be used where a SHA-256 is
// required, with independently verified known-answer vectors.
//
// This is a straight, self-contained implementation of FIPS 180-4 SHA-256.
// It has NO dependency, NO shell, and NO Python.
//
// The known-answer vectors are MECHANICALLY self-checked by the `selfcheck`
// mode, so a corrupted constant cannot pass unnoticed.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#define SHA256_H0 0x6a09e667
#define SHA256_H1 0xbb67ae85
#define SHA256_H2 0x3c6ef372
#define SHA256_H3 0xa54ff53a
#define SHA256_H4 0x510e527f
#define SHA256_H5 0x9b05688c
#define SHA256_H6 0x1f83d9ab
#define SHA256_H7 0x5be0cd19

// The 32-bit right rotation. `n` is in 1..31.
static U32 Sha256Rotr(U32 x, I64 n) {
  return (x >> n) | (x << (32 - n));
}

// The SHA-256 round constants, indexed by the round number.
static U32 Sha256K(I64 i) {
  if (i ==  0) return 0x428a2f98;
  if (i ==  1) return 0x71374491;
  if (i ==  2) return 0xb5c0fbcf;
  if (i ==  3) return 0xe9b5dba5;
  if (i ==  4) return 0x3956c25b;
  if (i ==  5) return 0x59f111f1;
  if (i ==  6) return 0x923f82a4;
  if (i ==  7) return 0xab1c5ed5;
  if (i ==  8) return 0xd807aa98;
  if (i ==  9) return 0x12835b01;
  if (i == 10) return 0x243185be;
  if (i == 11) return 0x550c7dc3;
  if (i == 12) return 0x72be5d74;
  if (i == 13) return 0x80deb1fe;
  if (i == 14) return 0x9bdc06a7;
  if (i == 15) return 0xc19bf174;
  if (i == 16) return 0xe49b69c1;
  if (i == 17) return 0xefbe4786;
  if (i == 18) return 0x0fc19dc6;
  if (i == 19) return 0x240ca1cc;
  if (i == 20) return 0x2de92c6f;
  if (i == 21) return 0x4a7484aa;
  if (i == 22) return 0x5cb0a9dc;
  if (i == 23) return 0x76f988da;
  if (i == 24) return 0x983e5152;
  if (i == 25) return 0xa831c66d;
  if (i == 26) return 0xb00327c8;
  if (i == 27) return 0xbf597fc7;
  if (i == 28) return 0xc6e00bf3;
  if (i == 29) return 0xd5a79147;
  if (i == 30) return 0x06ca6351;
  if (i == 31) return 0x14292967;
  if (i == 32) return 0x27b70a85;
  if (i == 33) return 0x2e1b2138;
  if (i == 34) return 0x4d2c6dfc;
  if (i == 35) return 0x53380d13;
  if (i == 36) return 0x650a7354;
  if (i == 37) return 0x766a0abb;
  if (i == 38) return 0x81c2c92e;
  if (i == 39) return 0x92722c85;
  if (i == 40) return 0xa2bfe8a1;
  if (i == 41) return 0xa81a664b;
  if (i == 42) return 0xc24b8b70;
  if (i == 43) return 0xc76c51a3;
  if (i == 44) return 0xd192e819;
  if (i == 45) return 0xd6990624;
  if (i == 46) return 0xf40e3585;
  if (i == 47) return 0x106aa070;
  if (i == 48) return 0x19a4c116;
  if (i == 49) return 0x1e376c08;
  if (i == 50) return 0x2748774c;
  if (i == 51) return 0x34b0bcb5;
  if (i == 52) return 0x391c0cb3;
  if (i == 53) return 0x4ed8aa4a;
  if (i == 54) return 0x5b9cca4f;
  if (i == 55) return 0x682e6ff3;
  if (i == 56) return 0x748f82ee;
  if (i == 57) return 0x78a5636f;
  if (i == 58) return 0x84c87814;
  if (i == 59) return 0x8cc70208;
  if (i == 60) return 0x90befffa;
  if (i == 61) return 0xa4506ceb;
  if (i == 62) return 0xbef9a3f7;
  if (i == 63) return 0xc67178f2;
  return 0;
}

// The compressor for ONE 64-byte block. It takes the 64 message bytes of the
// block and the sixteen schedule words, and it runs the 64 rounds.
//
// The block's bytes are read through `block`, which is the caller's buffer.
static U0 Sha256Compress(U8 *block, U32 *w, U32 *h) {
  I64 t = 0;
  // The sixteen direct words.
  while (t < 16) {
    I64 off = t * 4;
    U32 v = 0;
    I64 k = 0;
    while (k < 4) {
      v = (v << 8) | block[off + k];
      k = k + 1;
    }
    w[t] = v;
    t = t + 1;
  }
  // The forty-eight extended words.
  t = 16;
  while (t < 64) {
    U32 w15 = w[t - 15];
    U32 w2 = w[t - 2];
    U32 s0 = Sha256Rotr(w15, 7) ^ Sha256Rotr(w15, 18) ^ (w15 >> 3);
    U32 s1 = Sha256Rotr(w2, 17) ^ Sha256Rotr(w2, 19) ^ (w2 >> 10);
    w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & 0xFFFFFFFF;
    t = t + 1;
  }
  // The eight working variables.
  U32 a = h[0];
  U32 bb = h[1];
  U32 c = h[2];
  U32 d = h[3];
  U32 e = h[4];
  U32 f = h[5];
  U32 g = h[6];
  U32 hh = h[7];
  t = 0;
  while (t < 64) {
    U32 S1 = Sha256Rotr(e, 6) ^ Sha256Rotr(e, 11) ^ Sha256Rotr(e, 25);
    U32 ch = (e & f) ^ ((~e) & g);
    U32 temp1 = (hh + S1 + ch + Sha256K(t) + w[t]) & 0xFFFFFFFF;
    U32 S0 = Sha256Rotr(a, 2) ^ Sha256Rotr(a, 13) ^ Sha256Rotr(a, 22);
    U32 maj = (a & bb) ^ (a & c) ^ (bb & c);
    U32 temp2 = (S0 + maj) & 0xFFFFFFFF;
    hh = g;
    g = f;
    f = e;
    e = (d + temp1) & 0xFFFFFFFF;
    d = c;
    c = bb;
    bb = a;
    a = (temp1 + temp2) & 0xFFFFFFFF;
    t = t + 1;
  }
  h[0] = (h[0] + a) & 0xFFFFFFFF;
  h[1] = (h[1] + bb) & 0xFFFFFFFF;
  h[2] = (h[2] + c) & 0xFFFFFFFF;
  h[3] = (h[3] + d) & 0xFFFFFFFF;
  h[4] = (h[4] + e) & 0xFFFFFFFF;
  h[5] = (h[5] + f) & 0xFFFFFFFF;
  h[6] = (h[6] + g) & 0xFFFFFFFF;
  h[7] = (h[7] + hh) & 0xFFFFFFFF;
}

// The streaming context. It holds the state, the partial block, the number of
// bytes buffered in the partial block, and the total message length.
class Sha256Ctx
{
  U32 h[8];
  U8 block[64];
  I64 fill;
  I64 total;
};

// The context initialiser.
static U0 Sha256Init(Sha256Ctx *c) {
  c->h[0] = SHA256_H0;
  c->h[1] = SHA256_H1;
  c->h[2] = SHA256_H2;
  c->h[3] = SHA256_H3;
  c->h[4] = SHA256_H4;
  c->h[5] = SHA256_H5;
  c->h[6] = SHA256_H6;
  c->h[7] = SHA256_H7;
  c->fill = 0;
  c->total = 0;
}

// The streaming update. The message may be supplied in any number of pieces;
// the digest is the digest of the CONCATENATION.
//
// The padding is applied ONLY by Sha256Final, so a piece boundary never
// introduces a spurious padding block.
static U0 Sha256Update(Sha256Ctx *c, U8 *buf, I64 size) {
  U32 *w = MAlloc(sizeof(U32) * 64);
  I64 i = 0;
  while (i < size) {
    c->block[c->fill] = buf[i];
    c->fill = c->fill + 1;
    c->total = c->total + 1;
    if (c->fill == 64) {
      Sha256Compress(c->block, w, c->h);
      c->fill = 0;
    }
    i = i + 1;
  }
  Free(w);
}

// The finaliser. It applies the padding, the zero fill and the 64-bit
// big-endian bit length, and it writes the 32-byte digest into `out`.
//
// The padding is: the 0x80 byte, then the shortest zero run that brings the
// length to 56 modulo 64, then the 8-byte big-endian bit length.
//
// The padded length MUST be rounded UP to a whole number of 64-byte blocks.
// The rounding is computed with an explicit remainder test, so a message
// whose length is already a multiple of 64 still gets the extra block that
// the trailing 8-byte length field requires.
static U0 Sha256Final(Sha256Ctx *c, U8 *out) {
  I64 bitlen = c->total * 8;
  U32 *w = MAlloc(sizeof(U32) * 64);

  // The 0x80 byte.
  c->block[c->fill] = 128;
  c->fill = c->fill + 1;

  // If the 0x80 byte pushed the fill past the 56-byte mark, the length
  // field does not fit in THIS block. The block is completed with zeros,
  // compressed, and a FRESH block is started for the length field.
  //
  // This is the case that a message whose length is 56 modulo 64 (and no
  // smaller) reaches, and it is the case a naive implementation gets
  // wrong by overwriting the 0x80 byte with the length field.
  if (c->fill > 56) {
    while (c->fill < 64) {
      c->block[c->fill] = 0;
      c->fill = c->fill + 1;
    }
    Sha256Compress(c->block, w, c->h);
    c->fill = 0;
  }

  // The zero fill up to the 56-byte mark.
  while (c->fill < 56) {
    c->block[c->fill] = 0;
    c->fill = c->fill + 1;
  }
  // The eight-byte big-endian bit length, most significant byte first.
  I64 k = 0;
  while (k < 8) {
    I64 shift = 56 - k * 8;
    I64 o = 56 + k;
    c->block[o] = (bitlen >> shift) & 255;
    k = k + 1;
  }
  c->fill = 64;

  Sha256Compress(c->block, w, c->h);
  Free(w);

  I64 i = 0;
  while (i < 8) {
    U32 v = c->h[i];
    I64 j = 0;
    while (j < 4) {
      I64 o = i * 4 + j;
      out[o] = (v >> (24 - j * 8)) & 255;
      j = j + 1;
    }
    i = i + 1;
  }
}

// The digest of a byte run. `out` receives 32 bytes.
static U0 Sha256Bytes(U8 *buf, I64 size, U8 *out) {
  Sha256Ctx c;
  Sha256Init(&c);
  if (buf != NULL && size > 0) {
    Sha256Update(&c, buf, size);
  }
  Sha256Final(&c, out);
}

// The lowercase hexadecimal rendering of a 32-byte digest. `out` receives
// 64 hexadecimal digits and a terminating NUL, so it needs 65 bytes.
//
// NOTE: every computed subscript is hoisted into a LOCAL before the store.
// The production compiler's byte-store codegen emits a scaled indexed store
// when the scale factor appears inside the subscript expression, and a
// scaled index is not encodable for a byte store on AArch64. Hoisting keeps
// the emitted store legal without changing any semantics.
static U0 Sha256Hex(U8 *out, U8 *digest) {
  U8 *hex = "0123456789abcdef";
  I64 i = 0;
  while (i < 32) {
    I64 o1 = i * 2;
    I64 o2 = i * 2 + 1;
    I64 b = digest[i];
    out[o1] = hex[(b >> 4) & 15];
    out[o2] = hex[b & 15];
    i = i + 1;
  }
  out[64] = 0;
}

// The digest of a FILE. A MISSING file is a HARD FAILURE: the caller
// receives 0 and the caller reports the absence. A present file, INCLUDING an
// empty one, has the SHA-256 of its exact bytes.
//
// The distinction matters: a MISSING input is NOT an empty input, and an
// evidence architecture that conflates them accepts a missing fixture.
static I64 Sha256File(U8 *path, U8 *out_hex) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return 0;
  U8 digest[32];
  Sha256Bytes(buf, size, digest);
  Sha256Hex(out_hex, digest);
  return 1;
}

// The KNOWN-ANSWER VECTORS. They are the FIPS 180-4 / NIST published
// SHA-256 digests for the canonical short inputs. The `selfcheck` mode
// verifies the implementation against them.
//
// The vectors are:
//   "" ->
//     e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
//   "abc" ->
//     ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
//   "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" ->
//     248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1
//   the 1,000,000 repetitions of "a" ->
//     cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0
//
// The million-'a' vector is exercised through a PIECEWISE absorb, so the
// block-boundary handling is exercised as well.
static I64 Sha256SelfCheck() {
  I64 failures = 0;
  U8 hex[65];
  U8 digest[32];

  Sha256Bytes("", 0, digest);
  Sha256Hex(hex, digest);
  if (StrCmp(hex, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") != 0) {
    "SHA256_SELFTEST\tEMPTY_VECTOR\tFAIL\t%s\n", hex;
    failures = failures + 1;
  } else {
    "SHA256_SELFTEST\tEMPTY_VECTOR\tPASS\n";
  }

  Sha256Bytes("abc", 3, digest);
  Sha256Hex(hex, digest);
  if (StrCmp(hex, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad") != 0) {
    "SHA256_SELFTEST\tABC_VECTOR\tFAIL\t%s\n", hex;
    failures = failures + 1;
  } else {
    "SHA256_SELFTEST\tABC_VECTOR\tPASS\n";
  }

  U8 *two = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
  Sha256Bytes(two, 56, digest);
  Sha256Hex(hex, digest);
  if (StrCmp(hex, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1") != 0) {
    "SHA256_SELFTEST\tTWO_BLOCK_VECTOR\tFAIL\t%s\n", hex;
    failures = failures + 1;
  } else {
    "SHA256_SELFTEST\tTWO_BLOCK_VECTOR\tPASS\n";
  }

  // The million-'a' vector, computed with a PIECEWISE absorb. Each piece is
  // 1000 bytes, so the message is absorbed in 1000 pieces of 1000 bytes.
  Sha256Ctx c;
  Sha256Init(&c);
  U8 *chunk = MAlloc(1000);
  I64 ci = 0;
  while (ci < 1000) { chunk[ci] = 97; ci = ci + 1; }
  I64 iter = 0;
  while (iter < 1000) {
    Sha256Update(&c, chunk, 1000);
    iter = iter + 1;
  }
  Sha256Final(&c, digest);
  Free(chunk);
  Sha256Hex(hex, digest);
  if (StrCmp(hex, "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0") != 0) {
    "SHA256_SELFTEST\tMILLION_A_VECTOR\tFAIL\t%s\n", hex;
    failures = failures + 1;
  } else {
    "SHA256_SELFTEST\tMILLION_A_VECTOR\tPASS\n";
  }

  "SHA256_SELFTEST_FAILURES\t%d\n", failures;
  return failures;
}
