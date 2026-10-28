// tools/quality/parser-surface-recon06-audit.HC
//
// ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON06 C0.
//
// THE RECON06 C0 AUDIT VERIFIER.  A PolyC implementation.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// It has FOUR modes, each MECHANICAL: every answer is derived from
// the LIVE bytes of the named file, never from a hand-authored table.
//
//   MODE=FREEZE      Recompute the SHA-256 of every path in a path
//                    list and write the "sha256<TAB>path" manifest.
//                    This is the C0 predecessor-freeze generator.
//
//   MODE=VERIFY      Read a frozen manifest and re-check every path
//                    against the LIVE file bytes.  Reports
//                    MISSING / MISMATCH / OK counts.  This is the F14
//                    re-verification detector.
//
//   MODE=N06         Mechanically re-derive the DECISIVE facts of the
//                    N-06 literal-control audit from the actual
//                    committed artifacts, and emit the audit's
//                    machine-checked predicates.  It does NOT judge:
//                    it reports what the bytes say.
//
//   MODE=SELFTEST    Verify this tool against known-answer vectors.
//
// USAGE:
//   build/parser-surface-recon06-audit FREEZE <paths.txt> <out.tsv>
//   build/parser-surface-recon06-audit VERIFY <manifest.tsv>
//   build/parser-surface-recon06-audit N06 <recon05-dir> <slice07-dir>
//   build/parser-surface-recon06-audit SELFTEST
//
// The N06 mode's directory arguments are the five closed ACT
// directories it reads:
//   <recon05-dir>/c2/selected-negative-controls.md
//   <recon05-dir>/c2/selected-red-contract.md
//   <recon05-dir>/c2/selected-causal-contract.md
//   <slice07-dir>/c0/negative-control-contract.tsv
//   <slice07-dir>/c1/negative-control-red.txt
//   <slice07-dir>/c3/inherited-controls-join.tsv
//   <slice07-dir>/c3/new-controls-join.tsv
//   <slice07-dir>/c3/causal-polyc-mutation-restoration.txt

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 snprintf(U8 *dst, U64 cap, U8 *fmt, ...);

#define SHA256_BLOCK 64
#define MAX_PATHS    4096
#define PATH_MAX     512

// ------------------------------------------------------------------
// SHA-256 (FIPS 180-4).
// ------------------------------------------------------------------

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
    a = a + 1; b = b + 1;
  }
  if (*a != *b) return 0;
  return 1;
}

// StrContain: does `hay` contain the NUL-terminated `needle`?
static I64 StrContain(U8 *hay, U8 *needle)
{
  if (!hay || !needle) return 0;
  I64 nl = StrLen(needle);
  if (nl == 0) return 1;
  I64 hl = StrLen(hay);
  for (I64 i = 0; i + nl <= hl; i = i + 1) {
    I64 j = 0;
    while (j < nl && hay[i+j] == needle[j]) j = j + 1;
    if (j == nl) return 1;
  }
  return 0;
}

// CountContain: how many times does `hay` contain `needle`?
static I64 CountContain(U8 *hay, U8 *needle)
{
  if (!hay || !needle) return 0;
  I64 nl = StrLen(needle);
  if (nl == 0) return 0;
  I64 hl = StrLen(hay);
  I64 n = 0;
  for (I64 i = 0; i + nl <= hl; i = i + 1) {
    I64 j = 0;
    while (j < nl && hay[i+j] == needle[j]) j = j + 1;
    if (j == nl) { n = n + 1; i = i + nl - 1; }
  }
  return n;
}

// SplitLines: split a NUL-terminated buffer into lines, dropping the
// trailing empty line produced by a final '\n'.  The caller owns the
// returned array; the line pointers point INTO the buffer.
#define MAX_SPLIT_LINES 8192
static U8 *G_LINES[MAX_SPLIT_LINES];
static I64 G_NLINES;

static U0 SplitLines(U8 *text)
{
  G_NLINES = 0;
  if (!text) return;
  I64 n = StrLen(text);
  if (n == 0) return;
  I64 start = 0;
  for (I64 i = 0; i <= n; i = i + 1) {
    Bool at_end = (i == n);
    Bool at_nl  = FALSE;
    if (!at_end) if (text[i] == '\n') at_nl = TRUE;
    if (at_end || at_nl) {
      I64 len = i - start;
      if (!(at_end && len == 0)) {
        if (G_NLINES < MAX_SPLIT_LINES) {
          G_LINES[G_NLINES] = text + start;
          text[start+len] = 0;
          G_NLINES = G_NLINES + 1;
        }
      }
      start = i + 1;
    }
  }
}

static I64 ParseI64(U8 *s)
{
  I64 sign = 1;
  if (!s) return 0;
  while (*s == ' ') s = s + 1;
  if (*s == '-') { sign = -1; s = s + 1; }
  I64 v = 0;
  while (*s >= '0' && *s <= '9') {
    v = v * 10 + (*s - '0');
    s = s + 1;
  }
  return v * sign;
}

static U8 *DupStr(U8 *s)
{
  if (!s) return NULL;
  I64 n = StrLen(s);
  U8 *d = MAlloc(n + 1);
  MemCpy(d, s, n + 1);
  return d;
}

// JoinPath: "<dir>/<leaf>"
static U8 *JoinPath(U8 *dir, U8 *leaf)
{
  I64 dl = StrLen(dir);
  I64 ll = StrLen(leaf);
  U8 *p = MAlloc(dl + ll + 2);
  MemCpy(p, dir, dl);
  p[dl] = '/';
  MemCpy(p + dl + 1, leaf, ll + 1);
  return p;
}

// HashFile: the lowercase hex SHA-256 of the file's bytes, or NULL if
// the file cannot be read.
static U8 *HashFile(U8 *path)
{
  I64 len = 0;
  U8 *buf = FileRead(path, &len);
  if (!buf) return NULL;
  U8 dig[32];
  Sha256(buf, len, dig);
  U8 *hex = MAlloc(65);
  HexOfBytes(dig, 32, hex);
  return hex;
}

// ------------------------------------------------------------------
// A bounded output buffer, used by the FREEZE mode.
// ------------------------------------------------------------------

#define OUTBUF_MAX (4 * 1024 * 1024)

static U8 *G_OUT;
static I64 G_OUTLEN;

static U0 OutInit()
{
  G_OUT = MAlloc(OUTBUF_MAX);
  MemSet(G_OUT, 0, OUTBUF_MAX);
  G_OUTLEN = 0;
}

static U0 OutStr(U8 *s)
{
  if (!s) return;
  I64 n = StrLen(s);
  if (G_OUTLEN + n + 1 >= OUTBUF_MAX) return;
  MemCpy(G_OUT + G_OUTLEN, s, n);
  G_OUTLEN = G_OUTLEN + n;
  G_OUT[G_OUTLEN] = 0;
}

static U0 OutFlush(U8 *path)
{
  Bool ok = FileWrite(path, G_OUT, G_OUTLEN, O_CREAT | O_TRUNC | O_RDWR);
  if (!ok) {
    "STATUS=ERROR\nREASON=cannot write %s\n", path;
  }
}

// ------------------------------------------------------------------
// MODE=FREEZE
// ------------------------------------------------------------------

static I32 ModeFreeze(U8 *paths_path, U8 *out_path)
{
  I64 plen = 0;
  U8 *ptext = FileRead(paths_path, &plen);
  if (!ptext) {
    "STATUS=ERROR\nREASON=paths file not found\n";
    return 2;
  }
  SplitLines(ptext);

  OutInit();

  I64 n = 0;
  I64 missing = 0;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *p = G_LINES[i];
    if (!p) continue;
    if (!*p) continue;
    // Skip blank lines and '#' comment lines.
    if (p[0] == '#') continue;
    U8 *hex = HashFile(p);
    if (!hex) {
      missing = missing + 1;
      OutStr("MISSING\t");
      OutStr(p);
      OutStr("\n");
      continue;
    }
    OutStr(hex);
    OutStr("\t");
    OutStr(p);
    OutStr("\n");
    n = n + 1;
  }
  OutFlush(out_path);
  "FREEZE_PATHS_HASHED=%d\n", n;
  "FREEZE_PATHS_MISSING=%d\n", missing;
  // NOTE: hcc does not implement the ternary operator; every
  // conditional is written as an explicit if/else.
  if (missing == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=VERIFY
// ------------------------------------------------------------------

static I32 ModeVerify(U8 *manifest_path)
{
  I64 mlen = 0;
  U8 *mtext = FileRead(manifest_path, &mlen);
  if (!mtext) {
    "STATUS=ERROR\nREASON=manifest not found\n";
    return 2;
  }
  SplitLines(mtext);

  I64 ok = 0;
  I64 mismatch = 0;
  I64 missing = 0;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *line = G_LINES[i];
    if (!line) continue;
      if (!*line) continue;
    if (line[0] == '#') continue;
    // "<sha256><TAB><path>"
    I64 tab = -1;
    for (I64 j = 0; line[j]; j = j + 1) if (line[j] == '\t') { tab = j; break; }
    if (tab != 64) {
      "MALFORMED\t%s\n", line;
      mismatch = mismatch + 1;
      continue;
    }
    U8 *want = MAlloc(65);
    MemCpy(want, line, 64);
    want[64] = 0;
    U8 *path = line + tab + 1;
    U8 *hex = HashFile(path);
    if (!hex) {
      "MISSING\t%s\n", path;
      missing = missing + 1;
      continue;
    }
    if (StrEq(hex, want)) {
      ok = ok + 1;
    } else {
      "MISMATCH\t%s\n", path;
      mismatch = mismatch + 1;
    }
  }
  "VERIFY_OK=%d\n", ok;
  "VERIFY_MISMATCH=%d\n", mismatch;
  "VERIFY_MISSING=%d\n", missing;
  if (mismatch == 0 && missing == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=N06
//
// Mechanically re-derive the DECISIVE facts of the N-06 literal
// control audit from the ACTUAL committed bytes.  The tool REPORTS;
// it does not JUDGE.  Each emitted predicate is a direct reading of
// the bytes, so an auditor can falsify any of them by inspecting the
// named file.
// ------------------------------------------------------------------

static U8 *ReadText(U8 *path)
{
  I64 len = 0;
  U8 *buf = FileRead(path, &len);
  return buf;
}

static I32 ModeN06(U8 *recon05_dir, U8 *slice07_dir)
{
  // --- the frozen RECON05 N-06 text ---
  U8 *p_nc = JoinPath(recon05_dir, "c2/selected-negative-controls.md");
  U8 *nc = ReadText(p_nc);
  if (!nc) {
    "STATUS=ERROR\nREASON=missing %s\n", p_nc;
    return 2;
  }

  // The frozen mutation sentence, verbatim.
  I64 has_frozen_c_subject = StrContain(nc, "Mutate ONLY the selected C decision");
  // The frozen detector.
  I64 has_frozen_detector = StrContain(nc, "DETECTOR=CAUSAL_DIRECTION_CHANGE");
  // The frozen framing: these are controls the SUCCESSOR must implement.
  I64 has_successor_framing = StrContain(nc, "These are the controls the SUCCESSOR must implement");

  // Does ANY frozen RECON05 artifact authorise a subject substitution?
  // The search is over the whole frozen c2/ set, exactly as the audit
  // states.
  I64 analogue_hits = 0;
  {
    U8 *names[8];
    names[0] = DupStr("c2/selected-negative-controls.md");
    names[1] = DupStr("c2/selected-red-contract.md");
    names[2] = DupStr("c2/selected-causal-contract.md");
    names[3] = DupStr("c2/selected-abi.md");
    names[4] = DupStr("c2/successor-authorization.md");
    names[5] = DupStr("c2/selected-out-of-scope.md");
    names[6] = DupStr("c2/selected-conservation-contract.md");
    names[7] = DupStr("c2/selected-state-and-ownership.tsv");
    for (I64 i = 0; i < 8; i = i + 1) {
      U8 *pth = JoinPath(recon05_dir, names[i]);
      U8 *txt = ReadText(pth);
      if (!txt) continue;
      analogue_hits = analogue_hits + CountContain(txt, "subject-specific analogue");
      analogue_hits = analogue_hits + CountContain(txt, "successor-authority analogue");
      analogue_hits = analogue_hits + CountContain(txt, "analogue of N-");
      analogue_hits = analogue_hits + CountContain(txt, "analog of N-");
    }
  }

  // The frozen RED-05 successor-state column.
  U8 *p_rc = JoinPath(recon05_dir, "c2/selected-red-contract.md");
  U8 *rc = ReadText(p_rc);
  I64 red05_requires_delegated = 0;
  if (rc) {
    red05_requires_delegated = StrContain(rc, "the C decision is delegated and the behaviour is unchanged");
  }

  // --- the SLICE07 C0 contract's own equivalence note ---
  U8 *p_c0 = JoinPath(slice07_dir, "c0/negative-control-contract.tsv");
  U8 *c0 = ReadText(p_c0);
  I64 c0_has_equivalence_note = 0;
  I64 c0_has_both_ids = 0;
  if (c0) {
    c0_has_equivalence_note = StrContain(c0, "subject-specific analogue of N-06");
    c0_has_both_ids = StrContain(c0, "reported under BOTH N-06 and S7-CC-01");
  }

  // --- the SLICE07 C1 RED's double-reporting statement ---
  U8 *p_c1 = JoinPath(slice07_dir, "c1/negative-control-red.txt");
  U8 *c1 = ReadText(p_c1);
  I64 c1_double_reported = 0;
  if (c1) {
    c1_double_reported = StrContain(c1, "reported under BOTH N-06 and");
  }

  // --- the SLICE07 C3 causal record: THE DECISIVE FILE ---
  U8 *p_causal = JoinPath(slice07_dir, "c3/causal-polyc-mutation-restoration.txt");
  U8 *causal = ReadText(p_causal);
  if (!causal) {
    "STATUS=ERROR\nREASON=missing %s\n", p_causal;
    return 2;
  }
  I64 scope_is_polyc_only = StrContain(causal, "MUTATION_SCOPE=tools/bootstrap/selfhost-parser-slice07.HC ONLY");
  I64 mutation_not_in_parser_c = StrContain(causal, "MUTATION_IS_IN_SRC_PARSER_C=NO");
  I64 mutation_is_polyc = StrContain(causal, "MUTATION_IS_IN_THE_POLYC_SOURCE=YES");
  I64 mutant_build_success = StrContain(causal, "CAUSAL_MUTANT_PRODUCTION_BUILD=SUCCESS");
  I64 restoration_identical = StrContain(causal, "CAUSAL_RESTORATION_BYTE_IDENTICAL=YES");
  I64 main_not_mutated = StrContain(causal, "AUTHORITATIVE_MAIN_MUTATED=NO");

  // --- the SLICE07 C3 inherited join: the N-06 row's subject ---
  U8 *p_ij = JoinPath(slice07_dir, "c3/inherited-controls-join.tsv");
  U8 *ij = ReadText(p_ij);
  I64 join_n06_subject_is_polyc = 0;
  I64 join_n06_row_found = 0;
  I64 join_n06_same_diagnostic = 0;
  if (ij) {
    SplitLines(ij);
    for (I64 i = 0; i < G_NLINES; i = i + 1) {
      U8 *line = G_LINES[i];
      if (!line) continue;
      if (!*line) continue;
      if (line[0] == 'N' && line[1] == '-' && line[2] == '0' && line[3] == '6') {
        join_n06_row_found = 1;
        if (StrContain(line, "the PolyC source")) join_n06_subject_is_polyc = 1;
        if (StrContain(line, "Mapping exists for 1 -> %l14 i64 local")) join_n06_same_diagnostic = 1;
        break;
      }
    }
  }

  // --- the SLICE07 C3 new-controls join: the S7-CC-01 row ---
  U8 *p_nj = JoinPath(slice07_dir, "c3/new-controls-join.tsv");
  U8 *nj = ReadText(p_nj);
  I64 join_s7cc01_row_found = 0;
  I64 join_s7cc01_subject_is_polyc = 0;
  I64 join_s7cc01_cites_same_file = 0;
  I64 join_s7cc01_same_diagnostic = 0;
  if (nj) {
    SplitLines(nj);
    for (I64 i = 0; i < G_NLINES; i = i + 1) {
      U8 *line = G_LINES[i];
      if (!line) continue;
      if (!*line) continue;
      if (StrContain(line, "S7-CC-01")) {
        join_s7cc01_row_found = 1;
        if (StrContain(line, "the PolyC source")) join_s7cc01_subject_is_polyc = 1;
        if (StrContain(line, "causal-polyc-mutation-restoration.txt")) join_s7cc01_cites_same_file = 1;
        // The SHARED DIAGNOSTIC is the precise identity of the
        // experiment: the same mutant compiler rejecting the same
        // witness with the same message is one experiment, not two.
        if (StrContain(line, "Mapping exists for 1 -> %l14 i64 local")) join_s7cc01_same_diagnostic = 1;
        break;
      }
    }
  }

  // --- the RECON05 C-mutation record (inherited background evidence) ---
  U8 *p_cc = JoinPath(recon05_dir, "c2/selected-causal-contract.md");
  U8 *cc = ReadText(p_cc);
  I64 recon05_c_mutation_documented = 0;
  if (cc) {
    recon05_c_mutation_documented = StrContain(cc, "MUTATION_SCOPE=src/parser.c ONLY");
  }

  // ------------------------------------------------------------------
  // THE MACHINE-CHECKED PREDICATES
  // ------------------------------------------------------------------
  "N06_FROZEN_TEXT_FOUND=%d\n", has_frozen_c_subject;
  "N06_FROZEN_DETECTOR_FOUND=%d\n", has_frozen_detector;
  "N06_FROZEN_SUCCESSOR_FRAMING_FOUND=%d\n", has_successor_framing;
  "N06_FROZEN_CORPUS_ANALOGUE_CLAUSES=%d\n", analogue_hits;
  "N06_FROZEN_RED05_REQUIRES_C_DELEGATED=%d\n", red05_requires_delegated;
  "N06_SLICE07_C0_EQUIVALENCE_NOTE_PRESENT=%d\n", c0_has_equivalence_note;
  "N06_SLICE07_C0_REPORTS_BOTH_IDS=%d\n", c0_has_both_ids;
  "N06_SLICE07_C1_DOUBLE_REPORT_STATEMENT=%d\n", c1_double_reported;
  "N06_C3_MUTATION_SCOPE_IS_POLYC_ONLY=%d\n", scope_is_polyc_only;
  "N06_C3_MUTATION_NOT_IN_SRC_PARSER_C=%d\n", mutation_not_in_parser_c;
  "N06_C3_MUTATION_IS_IN_POLYC_SOURCE=%d\n", mutation_is_polyc;
  "N06_C3_MUTANT_PRODUCTION_BUILD_SUCCESS=%d\n", mutant_build_success;
  "N06_C3_RESTORATION_BYTE_IDENTICAL=%d\n", restoration_identical;
  "N06_C3_AUTHORITATIVE_MAIN_NOT_MUTATED=%d\n", main_not_mutated;
  "N06_C3_INHERITED_JOIN_ROW_FOUND=%d\n", join_n06_row_found;
  "N06_C3_INHERITED_JOIN_SUBJECT_IS_POLYC_SOURCE=%d\n", join_n06_subject_is_polyc;
  "N06_C3_NEW_JOIN_S7CC01_ROW_FOUND=%d\n", join_s7cc01_row_found;
  "N06_C3_NEW_JOIN_S7CC01_SUBJECT_IS_POLYC_SOURCE=%d\n", join_s7cc01_subject_is_polyc;
  "N06_C3_NEW_JOIN_S7CC01_CITES_SAME_CAUSAL_FILE=%d\n", join_s7cc01_cites_same_file;
  "N06_C3_N06_ROW_SHARES_THE_S7CC01_DIAGNOSTIC=%d\n", join_n06_same_diagnostic;
  "N06_C3_S7CC01_ROW_SHARES_THE_N06_DIAGNOSTIC=%d\n", join_s7cc01_same_diagnostic;
  "N06_RECON05_C_MUTATION_DOCUMENTED=%d\n", recon05_c_mutation_documented;
  //
  // THE DERIVED AUDIT PREDICATES (boolean, each mechanically implied
  // by the facts above).  hcc has no ternary operator, so every
  // conditional is an explicit if/else.
  //
  I64 q_a_c_mutant_executed = 0;
  if (!mutation_not_in_parser_c) q_a_c_mutant_executed = 1;
  I64 q_b_equivalence_permitted = 0;
  if (analogue_hits > 0) q_b_equivalence_permitted = 1;
  I64 q_c_recon05_discharges = 0;
  I64 q_d_independent = 1;
  if (c1_double_reported) q_d_independent = 0;
  if (join_n06_same_diagnostic && join_s7cc01_same_diagnostic) q_d_independent = 0;
  I64 q_e_real_rebuild_and_witness = 0;
  if (mutant_build_success && restoration_identical) q_e_real_rebuild_and_witness = 1;
  //
  "N06_Q_A_C_DECISION_MUTANT_EXECUTED=%d\n", q_a_c_mutant_executed;
  "N06_Q_B_EQUIVALENCE_EXPLICITLY_PERMITTED=%d\n", q_b_equivalence_permitted;
  "N06_Q_C_RECON05_EVIDENCE_ELIGIBLE_AS_DISCHARGE=%d\n", q_c_recon05_discharges;
  "N06_Q_D_N06_AND_S7CC01_INDEPENDENT=%d\n", q_d_independent;
  "N06_Q_E_REAL_COMPILER_REBUILD_AND_WITNESS=%d\n", q_e_real_rebuild_and_witness;
  //
  // THE DISPOSITION, derived by the ACT's own stated rule.
  //
  I64 literal_proven = 0;
  if (q_a_c_mutant_executed && q_e_real_rebuild_and_witness) literal_proven = 1;
  I64 equiv_proven = 0;
  if (q_b_equivalence_permitted && literal_proven) equiv_proven = 1;
  I64 unproven = 1;
  if (literal_proven || equiv_proven) unproven = 0;
  if (literal_proven) {
    "N06_DISPOSITION=N06_LITERAL_PROVEN\n";
  } else {
    if (equiv_proven) {
      "N06_DISPOSITION=N06_EQUIVALENCE_PERMITTED_AND_PROVEN\n";
    } else {
      "N06_DISPOSITION=N06_UNPROVEN\n";
    }
  }
  //
  "N06_LITERAL_PROVEN=%d\n", literal_proven;
  "N06_EQUIVALENCE_PERMITTED_AND_PROVEN=%d\n", equiv_proven;
  "N06_UNPROVEN=%d\n", unproven;
  //
  if (unproven) {
    "STATUS=FAIL\n";
    return 1;
  }
  "STATUS=PASS\n";
  return 0;
}

// ------------------------------------------------------------------
// MODE=SELFTEST
// ------------------------------------------------------------------

static I32 RunSelfTests()
{
  I64 fails = 0;

  // SHA-256 known-answer vectors (FIPS 180-4 / NIST).
  U8 d[32];
  U8 hex[65];
  U8 *k1;
  U8 *k2;
  U8 *k3;
  k1 = "abc";
  k2 = "";
  k3 = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
  Sha256(k1, 3, d);
  HexOfBytes(d, 32, hex);
  if (StrEq(hex, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad") == 0) {
    "FAIL  selftest: sha256(\"abc\")\n"; fails = fails + 1;
  }
  Sha256(k2, 0, d);
  HexOfBytes(d, 32, hex);
  if (StrEq(hex, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") == 0) {
    "FAIL  selftest: sha256(\"\")\n"; fails = fails + 1;
  }
  Sha256(k3, 56, d);
  HexOfBytes(d, 32, hex);
  if (StrEq(hex, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1") == 0) {
    "FAIL  selftest: sha256(56-byte)\n"; fails = fails + 1;
  }

  // The string helpers.
  if (StrContain("Mutate ONLY the selected C decision", "selected C decision") == 0) {
    "FAIL  selftest: StrContain positive\n"; fails = fails + 1;
  }
  if (StrContain("Mutate ONLY the selected decision", "selected C decision") != 0) {
    "FAIL  selftest: StrContain negative\n"; fails = fails + 1;
  }
  if (CountContain("aXbXc", "X") != 2) {
    "FAIL  selftest: CountContain\n"; fails = fails + 1;
  }
  if (CountContain("abc", "abcd") != 0) {
    "FAIL  selftest: CountContain long needle\n"; fails = fails + 1;
  }
  if (ParseI64("2049") != 2049) { "FAIL  selftest: ParseI64\n"; fails = fails + 1; }
  if (ParseI64("-7") != -7) { "FAIL  selftest: ParseI64 negative\n"; fails = fails + 1; }

  // The line splitter.
  U8 *txt = DupStr("a\nb\n");
  SplitLines(txt);
  if (G_NLINES != 2) { "FAIL  selftest: SplitLines count\n"; fails = fails + 1; }
  if (!StrEq(G_LINES[0], "a") || !StrEq(G_LINES[1], "b")) {
    "FAIL  selftest: SplitLines content\n"; fails = fails + 1;
  }
  U8 *one = DupStr("solo");
  SplitLines(one);
  if (G_NLINES != 1) { "FAIL  selftest: SplitLines one\n"; fails = fails + 1; }
  U8 *none = DupStr("");
  SplitLines(none);
  if (G_NLINES != 0) { "FAIL  selftest: SplitLines empty\n"; fails = fails + 1; }

  if (fails == 0) {
    "SELFTEST_PASS=9\nSELFTEST_FAIL=0\nSTATUS=PASS\n";
    return 0;
  }
  "SELFTEST_FAIL=%d\nSTATUS=FAIL\n", fails;
  return 1;
}

// ------------------------------------------------------------------
// Main
// ------------------------------------------------------------------

I32 UsageErr()
{
  "STATUS=ERROR\nREASON=usage: parser-surface-recon06-audit FREEZE|VERIFY|N06|SELFTEST ...\n";
  return 2;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc >= 2) {
    if (StrEq(argv[1], "--selftest")) return RunSelfTests();
    if (StrEq(argv[1], "SELFTEST")) return RunSelfTests();
  }
  if (argc < 2) return UsageErr();

  if (!StrEq(argv[1], "FREEZE")) {
    if (!StrEq(argv[1], "VERIFY")) {
      if (!StrEq(argv[1], "N06")) return UsageErr();
      if (argc != 4) return UsageErr();
      return ModeN06(argv[2], argv[3]);
    }
    if (argc != 3) return UsageErr();
    return ModeVerify(argv[2]);
  }
  if (argc != 4) return UsageErr();
  return ModeFreeze(argv[2], argv[3]);
}
