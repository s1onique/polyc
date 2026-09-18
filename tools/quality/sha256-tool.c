// tools/quality/sha256-tool.c
//
// ACT-POLYC-SELFHOST-LEXER04 C2 IMPL — minimal standalone
// SHA-256 utility used by the fixedpoint verifier. Same
// interface as tools/quality/lexer07-sha256.HC so the
// verifier can call it as a subprocess unchanged.
//
// Build with:
//   cc -O2 -o build/lexer07-sha256 tools/quality/sha256-tool.c
//
// Modes:
//   (no args)              silent (rc 0)
//   --file <path>          print hex SHA-256 of file content
//
// The output is exactly 64 lowercase hex chars followed by
// newline; this matches what the PolyC lexer07-sha256.HC
// produced in previous ACTs.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

static const uint32_t K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static inline uint32_t ROTR(uint32_t x, uint32_t n) {
    return (x >> n) | (x << (32 - n));
}

static void sha256_transform(uint32_t state[8], const uint8_t block[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)block[i*4 + 0] << 24) |
               ((uint32_t)block[i*4 + 1] << 16) |
               ((uint32_t)block[i*4 + 2] << 8)  |
               ((uint32_t)block[i*4 + 3]);
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = ROTR(w[i-15], 7) ^ ROTR(w[i-15], 18) ^ (w[i-15] >> 3);
        uint32_t s1 = ROTR(w[i-2], 17) ^ ROTR(w[i-2], 19) ^ (w[i-2] >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a = state[0], b = state[1], c = state[2], d = state[3];
    uint32_t e = state[4], f = state[5], g = state[6], h = state[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = ROTR(e, 6) ^ ROTR(e, 11) ^ ROTR(e, 25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = h + S1 + ch + K[i] + w[i];
        uint32_t S0 = ROTR(a, 2) ^ ROTR(a, 13) ^ ROTR(a, 22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e;
        e = d + t1;
        d = c; c = b; b = a;
        a = t1 + t2;
    }
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

static void sha256_file(const char *path, char hex_out[65])
{
    FILE *f = fopen(path, "rb");
    if (!f) { hex_out[0] = 0; return; }
    uint32_t state[8] = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    };
    uint8_t block[64];
    uint64_t bitlen = 0;
    size_t n;
    while ((n = fread(block, 1, 64, f)) > 0) {
        bitlen += (uint64_t)n * 8;
        if (n == 64) {
            sha256_transform(state, block);
        } else {
            /* final block with padding */
            uint8_t padded[128];
            memcpy(padded, block, n);
            padded[n] = 0x80;
            size_t pad_len = (n + 1 <= 56) ? (64 - n - 1) : (128 - n - 1);
            memset(padded + n + 1, 0, pad_len);
            size_t total = n + 1 + pad_len;
            /* length in bits, big-endian */
            padded[total - 8] = (uint8_t)(bitlen >> 56);
            padded[total - 7] = (uint8_t)(bitlen >> 48);
            padded[total - 6] = (uint8_t)(bitlen >> 40);
            padded[total - 5] = (uint8_t)(bitlen >> 32);
            padded[total - 4] = (uint8_t)(bitlen >> 24);
            padded[total - 3] = (uint8_t)(bitlen >> 16);
            padded[total - 2] = (uint8_t)(bitlen >> 8);
            padded[total - 1] = (uint8_t)(bitlen);
            sha256_transform(state, padded);
            if (total == 128) {
                sha256_transform(state, padded + 64);
            }
        }
    }
    fclose(f);
    for (int i = 0; i < 8; i++) {
        snprintf(hex_out + i*8, 9, "%08x", state[i]);
    }
    hex_out[64] = 0;
}

int main(int argc, char **argv)
{
    if (argc >= 3 && strcmp(argv[1], "--file") == 0) {
        char hex[65];
        sha256_file(argv[2], hex);
        printf("%s\n", hex);
        return 0;
    }
    return 0;
}
