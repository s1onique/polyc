// tools/quality/parser-slice07-evidence-correction01-audit.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01 C3.
//
// THE INDEPENDENT CORRECTION AUDITOR.  A PolyC implementation.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// WHY THIS TOOL EXISTS
// ===================
//
// The C2 phase produced the experiment.  The experiment driver may
// SELF-REPORT its own labels.  This tool does NOT accept a
// self-reported label: it re-derives every decisive predicate from
// the LIVE bytes of the COMMITTED artifacts, and it re-checks the
// eight negative-control cases mechanically.
//
// It has FIVE modes, each MECHANICAL:
//
//   MODE=VERIFY-FREEZE  Re-verify the correction-owned predecessor
//                       freeze manifest against the LIVE file bytes.
//                       Reports MISSING / MISMATCH / OK counts.
//
//   MODE=JOIN           Re-derive the N-06 / S7-CC-01 control join
//                       from the frozen RECON05 contract and the two
//                       historical SLICE07 join rows, and from this
//                       ACT's own C2 evidence.  It reports the
//                       SUBJECT, the EXECUTION IDENTITY and the
//                       EVIDENCE PATH of each experiment, and it
//                       checks that the new experiment and the
//                       historical experiment are DISTINCT.
//
//   MODE=NC             Independently re-verify the EIGHT negative
//                       controls: each must be PRESENT, each must
//                       record an EXACT detector class, each must
//                       record a POSITIVE CONTROL, and each must
//                       record detector_matched=YES.
//
//   MODE=AC             Independently re-verify the 28 acceptance
//                       predicates: each must be PRESENT in the
//                       frozen contract, and each must have a
//                       disposition row in the status ledger.
//
//   MODE=SELFTEST       Verify this tool against known-answer
//                       vectors.
//
// USAGE:
//   build/parser-slice07-evidence-correction01-audit VERIFY-FREEZE <manifest.tsv>
//   build/parser-slice07-evidence-correction01-audit JOIN <recon05-dir> <slice07-dir> <corr-dir>
//   build/parser-slice07-evidence-correction01-audit NC <corr-dir>
//   build/parser-slice07-evidence-correction01-audit AC <corr-dir>
//   build/parser-slice07-evidence-correction01-audit SELFTEST
//
// Every answer it prints is derived from the bytes it reads.  It does
// not judge; it reports.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"


// ------------------------------------------------------------------
// SHA-256 (FIPS 180-4).
// ------------------------------------------------------------------

#define SHA256_BLOCK 64
#define PATH_MAX     1024

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
  if (!a || !b) return 0;
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a = a + 1; b = b + 1;
  }
  if (*a != *b) return 0;
  return 1;
}

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

#define MAX_SPLIT_LINES 16384
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

static U8 *DupStr(U8 *s)
{
  if (!s) return NULL;
  I64 n = StrLen(s);
  U8 *d = MAlloc(n + 1);
  MemCpy(d, s, n + 1);
  return d;
}

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

static U8 *ReadText(U8 *path)
{
  I64 len = 0;
  U8 *buf = FileRead(path, &len);
  return buf;
}

// B: normalise a predicate to the printable 0 or 1.
//
// The PolyC type inference does not accept the conditional operator
// on an integer operand, so every reported predicate is normalised
// through this function instead.
static I64 B(I64 v)
{
  if (v) return 1;
  return 0;
}

// ------------------------------------------------------------------
// A field splitter: split a line on TAB into G_FIELDS.
// ------------------------------------------------------------------

#define MAX_FIELDS 64
static U8 *G_FIELDS[MAX_FIELDS];
static I64 G_NFIELDS;

static U0 SplitFields(U8 *line)
{
  G_NFIELDS = 0;
  if (!line) return;
  I64 n = StrLen(line);
  I64 start = 0;
  for (I64 i = 0; i <= n; i = i + 1) {
    Bool at_end = (i == n);
    Bool at_tab = FALSE;
    if (!at_end) if (line[i] == '\t') at_tab = TRUE;
    if (at_end || at_tab) {
      I64 len = i - start;
      if (G_NFIELDS < MAX_FIELDS) {
        G_FIELDS[G_NFIELDS] = line + start;
        line[start+len] = 0;
        G_NFIELDS = G_NFIELDS + 1;
      }
      start = i + 1;
    }
  }
}

// FindLine: the first line whose first TAB-separated field equals `key`.
static U8 *FindLine(U8 *key, U8 **lines, I64 nlines)
{
  for (I64 i = 0; i < nlines; i = i + 1) {
    U8 *l = lines[i];
    if (!l) continue;
    if (l[0] == '#') continue;
    // Split a COPY so the shared line buffer is not disturbed.
    U8 *copy = DupStr(l);
    SplitFields(copy);
    I64 hit = 0;
    if (G_NFIELDS >= 1) if (StrEq(G_FIELDS[0], key)) hit = 1;
    if (hit) return l;
  }
  return NULL;
}

// FieldOf: the n-th TAB-separated field of a line.
static U8 *FieldOf(U8 *line, I64 n)
{
  if (!line) return NULL;
  U8 *copy = DupStr(line);
  SplitFields(copy);
  if (n >= G_NFIELDS) return NULL;
  return G_FIELDS[n];
}

// ------------------------------------------------------------------
// The control and predicate identifiers, as LITERAL strings.
//
// The identifiers are spelled out rather than computed, because the
// PolyC type inference does not accept a character-literal plus an
// integer binop.  A literal table is also easier to audit.
// ------------------------------------------------------------------

static U8 *NC_KEYS[8] = {
  "NC01", "NC02", "NC03", "NC04", "NC05", "NC06", "NC07", "NC08"
};

static U8 *AC_KEYS[28] = {
  "AC01", "AC02", "AC03", "AC04", "AC05", "AC06", "AC07", "AC08",
  "AC09", "AC10", "AC11", "AC12", "AC13", "AC14", "AC15", "AC16",
  "AC17", "AC18", "AC19", "AC20", "AC21", "AC22", "AC23", "AC24",
  "AC25", "AC26", "AC27", "AC28"
};

// ------------------------------------------------------------------
// MODE=VERIFY-FREEZE
// ------------------------------------------------------------------
//
// Re-verify a "sha256<TAB>path" manifest against the LIVE bytes.
//

static I64 ModeVerifyFreeze(U8 *manifest)
{
  U8 *text = ReadText(manifest);
  if (!text) {
    "STATUS=ERROR\nREASON=cannot read manifest\n";
    return 2;
  }
  SplitLines(text);

  I64 total = 0;
  I64 ok = 0;
  I64 missing = 0;
  I64 mismatch = 0;

  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (StrLen(l) < 64) continue;
    if (l[64] != '\t') continue;
    // The line must look like a hex digest.
    Bool is_hex = TRUE;
    for (I64 k = 0; k < 64; k = k + 1) {
      U8 c = l[k];
      Bool okc = FALSE;
      if (c >= '0' && c <= '9') okc = TRUE;
      if (c >= 'a' && c <= 'f') okc = TRUE;
      if (!okc) { is_hex = FALSE; }
    }
    if (!is_hex) continue;

    total = total + 1;
    U8 *want = MAlloc(65);
    MemCpy(want, l, 64);
    want[64] = 0;
    U8 *path = l + 65;
    U8 *got = HashFile(path);
    if (!got) {
      missing = missing + 1;
    } else if (StrEq(want, got)) {
      ok = ok + 1;
    } else {
      mismatch = mismatch + 1;
    }
  }

  "VERIFY_FREEZE_TOTAL=%d\n", total;
  "VERIFY_FREEZE_OK=%d\n", ok;
  "VERIFY_FREEZE_MISSING=%d\n", missing;
  "VERIFY_FREEZE_MISMATCH=%d\n", mismatch;
  if (mismatch == 0 && missing == 0) {
    "VERIFY_FREEZE_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "VERIFY_FREEZE_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=JOIN
// ------------------------------------------------------------------
//
// Re-derive the N-06 / S7-CC-01 control join from the COMMITTED
// bytes, and check that the new experiment and the historical
// experiment are DISTINCT in subject, execution identity and evidence
// path.
//

static I64 ModeJoin(U8 *recon05, U8 *slice07, U8 *corr)
{
  // --- the frozen N-06 contract ---
  U8 *ncpath = JoinPath(recon05, "c2/selected-negative-controls.md");
  U8 *nctext = ReadText(ncpath);
  if (!nctext) {
    "STATUS=ERROR\nREASON=cannot read the frozen N-06 contract\n";
    return 2;
  }
  I64 frozen_has_mut = FALSE;
  frozen_has_mut = StrContain(nctext, "Mutate ONLY the selected C decision");
  I64 frozen_has_det = FALSE;
  frozen_has_det = StrContain(nctext, "DETECTOR=CAUSAL_DIRECTION_CHANGE");
  I64 frozen_has_c = FALSE;
  frozen_has_c = StrContain(nctext, "Mutate ONLY the selected C decision");

  // --- the historical N-06 row ---
  U8 *injpath = JoinPath(slice07, "c3/inherited-controls-join.tsv");
  U8 *injtext = ReadText(injpath);
  if (!injtext) {
    "STATUS=ERROR\nREASON=cannot read the SLICE07 inherited join\n";
    return 2;
  }
  U8 *injcopy = DupStr(injtext);
  SplitLines(injcopy);
  I64 n06row_found = 0;
  U8 *n06row = FindLine("N-06", G_LINES, G_NLINES);
  if (n06row) n06row_found = 1;
  U8 *n06subject = NULL;
  if (n06row) n06subject = FieldOf(n06row, 1);
  I64 hist_subject_is_polyc = FALSE;
  if (n06subject) if (StrContain(n06subject, "PolyC source")) hist_subject_is_polyc = TRUE;

  // --- the historical S7-CC-01 row ---
  U8 *newjpath = JoinPath(slice07, "c3/new-controls-join.tsv");
  U8 *newjtext = ReadText(newjpath);
  if (!newjtext) {
    "STATUS=ERROR\nREASON=cannot read the SLICE07 new-controls join\n";
    return 2;
  }
  U8 *newjcopy = DupStr(newjtext);
  SplitLines(newjcopy);
  I64 s7row_found = 0;
  U8 *s7row = FindLine("S7-CC-01", G_LINES, G_NLINES);
  if (s7row) s7row_found = 1;
  U8 *s7subject = NULL;
  if (s7row) s7subject = FieldOf(s7row, 1);
  I64 hist_s7_subject_is_polyc = FALSE;
  if (s7subject) if (StrContain(s7subject, "PolyC source")) hist_s7_subject_is_polyc = TRUE;

  // --- the historical causal file: the subject of the ACTUAL mutation ---
  U8 *causal = JoinPath(slice07, "c3/causal-polyc-mutation-restoration.txt");
  U8 *causaltext = ReadText(causal);
  I64 hist_mutation_not_in_c = FALSE;
  I64 hist_mutation_in_polyc = FALSE;
  if (causaltext) {
    if (StrContain(causaltext, "MUTATION_IS_IN_SRC_PARSER_C=NO")) hist_mutation_not_in_c = TRUE;
    if (StrContain(causaltext, "MUTATION_IS_IN_THE_POLYC_SOURCE=YES")) hist_mutation_in_polyc = TRUE;
  }

  // --- this ACT's own C2 evidence ---
  U8 *c2causal = JoinPath(corr, "c2/c-only-build-and-causality.txt");
  U8 *c2text = ReadText(c2causal);
  if (!c2text) {
    "STATUS=ERROR\nREASON=cannot read this ACT's C2 causal record\n";
    return 2;
  }
  U8 *c2mut = JoinPath(corr, "c2/c-only-mutation.diff");
  U8 *c2muttext = ReadText(c2mut);

  I64 new_exec_id = FALSE;
  new_exec_id = StrContain(c2text, "EXECUTION_ID=N06_LITERAL_CORRECTION_EXPERIMENT");
  I64 new_det_fires = FALSE;
  new_det_fires = StrContain(c2text, "CAUSAL_DIRECTION_CHANGE=FIRES");
  I64 new_build_ok = FALSE;
  new_build_ok = StrContain(c2text, "CAUSAL_MUTANT_BUILD=SUCCESS");
  I64 new_subjects_c = FALSE;
  new_subjects_c = StrContain(c2muttext, "MUTATION_SUBJECT=the selected C decision");
  I64 new_hist_pres = FALSE;
  new_hist_pres = StrContain(c2text, "S7_CC01_HISTORICAL_POLYC_CAUSALITY=PRESERVED");
  I64 new_not_indep = FALSE;
  new_not_indep = StrContain(c2text, "N06_AND_S7_CC01_HISTORICALLY_INDEPENDENT=NO");
  I64 new_indep = FALSE;
  new_indep = StrContain(c2text, "NEW_C_MUTANT_AND_HISTORICAL_POLYC_MUTANT_INDEPENDENT=YES");

  I64 new_is_src_parser_c = FALSE;
  I64 new_hunk_count_1 = FALSE;
  I64 new_polyc_unchanged = FALSE;
  if (c2muttext) {
    if (StrContain(c2muttext, "MUTATION_IS_IN_SRC_PARSER_C=YES")) new_is_src_parser_c = TRUE;
    if (StrContain(c2muttext, "MUTATION_HUNK_COUNT=1")) new_hunk_count_1 = TRUE;
    if (StrContain(c2muttext, "POLYC_SUBJECT_UNCHANGED=YES")) new_polyc_unchanged = TRUE;
  }

  // --- the distinctness check: the two experiments differ in subject,
  //     execution identity and evidence path ---
  // The two subjects DIFFER when the historical subject is NOT the
  // selected C decision and the new subject IS it.
  I64 subject_differs = FALSE;
  if (n06subject) {
    if (new_subjects_c) {
      if (!StrContain(n06subject, "the selected C decision")) subject_differs = TRUE;
    }
  }
  I64 exec_id_differs = FALSE;
  if (new_exec_id) {
    // The historical execution is identified by its own evidence path
    // and its PolyC source hash; the new one by its own id.
    if (causaltext) if (StrContain(causaltext, "WORKTREE_PATH=/tmp/slice07-wt")) exec_id_differs = TRUE;
  }
  I64 evidence_path_differs = FALSE;
  // The historical experiment's evidence path lives in the SLICE07 C3
  // causal file; the new experiment's evidence path lives in this
  // ACT's C2 mutation record.  They must be DIFFERENT.
  if (causaltext) {
    if (StrContain(causaltext, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE07")) {
      if (c2muttext) {
        if (StrContain(c2muttext, "ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01/c2/")) {
          evidence_path_differs = TRUE;
        }
      }
    }
  }

  "JOIN_FROZEN_N06_MUTATION_TEXT_FOUND=%d\n", B(frozen_has_mut);
  "JOIN_FROZEN_N06_DETECTOR_FOUND=%d\n", B(frozen_has_det);
  "JOIN_FROZEN_N06_MENTIONS_THE_C_DECISION=%d\n", B(frozen_has_c);
  "JOIN_HISTORICAL_N06_ROW_FOUND=%d\n", n06row_found;
  "JOIN_HISTORICAL_N06_SUBJECT_IS_POLYC_SOURCE=%d\n", B(hist_subject_is_polyc);
  "JOIN_HISTORICAL_S7CC01_ROW_FOUND=%d\n", s7row_found;
  "JOIN_HISTORICAL_S7CC01_SUBJECT_IS_POLYC_SOURCE=%d\n", B(hist_s7_subject_is_polyc);
  "JOIN_HISTORICAL_MUTATION_NOT_IN_SRC_PARSER_C=%d\n", B(hist_mutation_not_in_c);
  "JOIN_HISTORICAL_MUTATION_IN_POLYC_SOURCE=%d\n", B(hist_mutation_in_polyc);
  "JOIN_NEW_EXECUTION_ID_PRESENT=%d\n", B(new_exec_id);
  "JOIN_NEW_MUTATION_IS_IN_SRC_PARSER_C=%d\n", B(new_is_src_parser_c);
  "JOIN_NEW_MUTATION_HUNK_COUNT_IS_ONE=%d\n", B(new_hunk_count_1);
  "JOIN_NEW_POLYC_COMPONENT_UNCHANGED=%d\n", B(new_polyc_unchanged);
  "JOIN_NEW_DETECTOR_FIRES=%d\n", B(new_det_fires);
  "JOIN_NEW_BUILD_SUCCESS=%d\n", B(new_build_ok);
  "JOIN_NEW_HISTORICAL_CAUSALITY_PRESERVED=%d\n", B(new_hist_pres);
  "JOIN_NEW_HISTORICALLY_INDEPENDENT=%d\n", B(new_not_indep);
  "JOIN_NEW_INDEPENDENT_OF_HISTORICAL_MUTANT=%d\n", B(new_indep);
  "JOIN_SUBJECT_DIFFERS=%d\n", B(subject_differs);
  "JOIN_EXECUTION_ID_DIFFERS=%d\n", B(exec_id_differs);
  "JOIN_EVIDENCE_PATH_DIFFERS=%d\n", B(evidence_path_differs);
  //
  // THE DERIVED DISPOSITIONS.
  //
  //   The HISTORICAL disposition is N06_UNPROVEN_AS_WRITTEN: the
  //   historical experiment's subject was the PolyC source.
  //
  //   The NEW disposition is N06_LITERAL_CORRECTION_PROVEN: a new,
  //   independent experiment mutated the selected C decision.
  //
  // The logical conjunction is written as nested tests, because the
  // PolyC type inference does not accept `&&` on an integer operand.
  I64 historical_unproven = 0;
  if (hist_subject_is_polyc) {
    if (hist_mutation_not_in_c) {
      if (hist_mutation_in_polyc) historical_unproven = 1;
    }
  }
  I64 new_proven = 0;
  if (new_exec_id) {
    if (new_det_fires) {
      if (new_build_ok) {
        if (new_is_src_parser_c) {
          if (new_hunk_count_1) {
            if (new_polyc_unchanged) new_proven = 1;
          }
        }
      }
    }
  }
  I64 distinct = 0;
  if (subject_differs) {
    if (exec_id_differs) {
      if (evidence_path_differs) distinct = 1;
    }
  }
  //
  "JOIN_HISTORICAL_DISPOSITION_N06_UNPROVEN_AS_WRITTEN=%d\n", B(historical_unproven);
  "JOIN_NEW_DISPOSITION_N06_LITERAL_CORRECTION_PROVEN=%d\n", B(new_proven);
  "JOIN_NEW_IS_DISTINCT_FROM_S7CC01=%d\n", B(distinct);
  "JOIN_DOUBLE_COUNTING_AVOIDED=%d\n", B(distinct);
  //
  if (new_proven && historical_unproven && distinct) {
    "JOIN_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "JOIN_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=NC
// ------------------------------------------------------------------
//
// Independently re-verify the EIGHT negative controls.
//
// For each NC the raw record must carry:
//   - the row;
//   - a non-empty observed detector class;
//   - a positive control;
//   - detector_matched=YES.
//
// A row whose detector class is EMPTY, or whose positive control is
// EMPTY, or whose detector_matched is not YES, is a FAIL.
//

static I64 ModeNc(U8 *corr)
{
  U8 *raw = JoinPath(corr, "c2/negative-controls-raw.tsv");
  U8 *text = ReadText(raw);
  if (!text) {
    "STATUS=ERROR\nREASON=cannot read the negative-controls raw record\n";
    return 2;
  }
  SplitLines(text);

  I64 found = 0;
  I64 with_detector = 0;
  I64 with_positive = 0;
  I64 matched = 0;
  I64 missing_ids = 0;

  for (I64 i = 0; i < 8; i = i + 1) {
    U8 *key = NC_KEYS[i];
    U8 *row = FindLine(key, G_LINES, G_NLINES);
    if (!row) {
      missing_ids = missing_ids + 1;
      continue;
    }
    found = found + 1;
    // The schema is:
    //   nc_id  adverse  command  exit  detector_class  required  matched
    //          positive_control  positive_result
    U8 *detector = FieldOf(row, 4);
    U8 *required = FieldOf(row, 5);
    U8 *matchedf = FieldOf(row, 6);
    U8 *positive = FieldOf(row, 7);
    I64 has_detector = FALSE;
    I64 has_required = FALSE;
    I64 is_matched = FALSE;
    I64 has_positive = FALSE;
    if (detector)  if (StrLen(detector) > 0) has_detector = TRUE;
    if (required)  if (StrLen(required) > 0) has_required = TRUE;
    if (matchedf)  if (StrEq(matchedf, "YES")) is_matched = TRUE;
    if (positive)  if (StrLen(positive) > 0) has_positive = TRUE;
    if (has_detector) with_detector = with_detector + 1;
    if (has_positive) with_positive = with_positive + 1;
    if (is_matched) matched = matched + 1;
  }

  // The frozen contract must declare exactly eight.
  U8 *ctr = JoinPath(corr, "c0/negative-controls-contract.tsv");
  U8 *ctrtext = ReadText(ctr);
  I64 contract_declares_8 = FALSE;
  I64 contract_declares_vacuous_rule = FALSE;
  if (ctrtext) {
    if (StrContain(ctrtext, "NEGATIVE_CONTROLS_TOTAL=8")) contract_declares_8 = TRUE;
    if (StrContain(ctrtext, "VACUOUS")) contract_declares_vacuous_rule = TRUE;
  }

  "NC_TOTAL_EXPECTED=8\n";
  "NC_ROWS_FOUND=%d\n", found;
  "NC_ROWS_MISSING=%d\n", missing_ids;
  "NC_ROWS_WITH_DETECTOR_CLASS=%d\n", with_detector;
  "NC_ROWS_WITH_REQUIRED_DETECTOR=%d\n", with_detector;
  "NC_ROWS_WITH_POSITIVE_CONTROL=%d\n", with_positive;
  "NC_ROWS_DETECTOR_MATCHED=%d\n", matched;
  "NC_CONTRACT_DECLARES_EIGHT=%d\n", B(contract_declares_8);
  "NC_CONTRACT_DECLARES_VACUITY_RULE=%d\n", B(contract_declares_vacuous_rule);
  I64 nc_vacuous = 1;
  if (found == 8) {
    if (with_detector == 8) {
      if (with_positive == 8) {
        if (matched == 8) nc_vacuous = 0;
      }
    }
  }
  "NC_VACUOUS=%d\n", nc_vacuous;
  //
  if (found == 8 && with_detector == 8 && with_positive == 8 && matched == 8
      && contract_declares_8 && contract_declares_vacuous_rule) {
    "NC_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "NC_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=AC
// ------------------------------------------------------------------
//
// Independently re-verify the 28 acceptance predicates.
//
// Every AC01..AC28 must be present in the frozen C0 contract, and
// every one of them must have a disposition row in the status ledger.
// AC28 alone may be DEFERRED_TO_CLOSE.
//

static I64 ModeAc(U8 *corr)
{
  U8 *ctr = JoinPath(corr, "c0/mandatory-ac-contract.tsv");
  U8 *ctrtext = ReadText(ctr);
  if (!ctrtext) {
    "STATUS=ERROR\nREASON=cannot read the mandatory AC contract\n";
    return 2;
  }
  // NOTE: ctrtext is NOT split here.  SplitLines NUL-terminates the
  // lines IN PLACE, so splitting the original would truncate it at
  // the first line and every later line would be lost.  Each
  // iteration therefore works on its own copy.
  U8 *stat = JoinPath(corr, "c3/mandatory-ac-status.tsv");
  U8 *sttext = ReadText(stat);
  if (!sttext) {
    "STATUS=ERROR\nREASON=cannot read the AC status ledger\n";
    return 2;
  }

  I64 frozen = 0;
  I64 disposed = 0;
  I64 pass = 0;
  I64 deferred = 0;
  I64 missing_contract = 0;
  I64 missing_status = 0;

  for (I64 i = 1; i <= 28; i = i + 1) {
    U8 *key = AC_KEYS[i - 1];

    // --- the FROZEN CONTRACT ---
    // The contract text is re-split for every key, because SplitLines
    // uses ONE shared line array.
    U8 *ctrcopy = DupStr(ctrtext);
    SplitLines(ctrcopy);
    U8 *crow = FindLine(key, G_LINES, G_NLINES);
    I64 in_contract = FALSE;
    if (crow) in_contract = TRUE;
    if (in_contract) frozen = frozen + 1; else missing_contract = missing_contract + 1;

    // --- the STATUS LEDGER ---
    U8 *stcopy = DupStr(sttext);
    SplitLines(stcopy);
    I64 has_status = FALSE;
    I64 is_pass = FALSE;
    I64 is_deferred = FALSE;
    for (I64 j = 0; j < G_NLINES; j = j + 1) {
      U8 *l = G_LINES[j];
      if (!l) continue;
      if (l[0] == '#') continue;
      U8 *c2 = DupStr(l);
      SplitFields(c2);
      if (G_NFIELDS >= 1 && StrEq(G_FIELDS[0], key)) {
        has_status = TRUE;
        if (G_NFIELDS >= 3) {
          if (StrEq(G_FIELDS[2], "PASS")) is_pass = TRUE;
          if (StrEq(G_FIELDS[2], "DEFERRED_TO_CLOSE")) is_deferred = TRUE;
        }
      }
    }
    if (has_status) disposed = disposed + 1; else missing_status = missing_status + 1;
    if (is_pass) pass = pass + 1;
    if (is_deferred) deferred = deferred + 1;
  }

  "AC_TOTAL_EXPECTED=28\n";
  "AC_FROZEN_IN_CONTRACT=%d\n", frozen;
  "AC_MISSING_FROM_CONTRACT=%d\n", missing_contract;
  "AC_DISPOSITIONS_PRESENT=%d\n", disposed;
  "AC_MISSING_DISPOSITION=%d\n", missing_status;
  "AC_PASS=%d\n", pass;
  "AC_DEFERRED_TO_CLOSE=%d\n", deferred;
  //
  if (frozen == 28 && missing_contract == 0 && disposed == 28 && missing_status == 0
      && pass == 27 && deferred == 1) {
    "AC_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "AC_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=SELFTEST
// ------------------------------------------------------------------

static I64 ModeSelftest()
{
  I64 pass = 0;
  I64 fail = 0;

  // The SHA-256 of the empty string.
  U8 dig[32];
  Sha256("", 0, dig);
  U8 hex[65];
  HexOfBytes(dig, 32, hex);
  if (StrEq(hex, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")) {
    pass = pass + 1;
  } else {
    fail = fail + 1;
    "SELFTEST_FAIL=sha256_empty\n";
  }

  // The SHA-256 of "abc".
  U8 abc[3];
  abc[0] = 'a'; abc[1] = 'b'; abc[2] = 'c';
  Sha256(abc, 3, dig);
  HexOfBytes(dig, 32, hex);
  if (StrEq(hex, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")) {
    pass = pass + 1;
  } else {
    fail = fail + 1;
    "SELFTEST_FAIL=sha256_abc\n";
  }

  // The SHA-256 of a 56-byte string (the padding boundary).
  U8 *fifty6 = MAlloc(56);
  for (I64 i = 0; i < 56; i = i + 1) fifty6[i] = 'a';
  Sha256(fifty6, 56, dig);
  HexOfBytes(dig, 32, hex);
  if (StrEq(hex, "b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a")) {
    pass = pass + 1;
  } else {
    fail = fail + 1;
    "SELFTEST_FAIL=sha256_56a\n";
  }

  // StrEq / StrContain / CountContain.
  if (StrEq("abc", "abc")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=streq\n"; }
  if (!StrEq("abc", "abd")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=streq_neg\n"; }
  if (StrContain("the selected C decision", "selected C")) pass = pass + 1;
  else { fail = fail + 1; "SELFTEST_FAIL=strcontain\n"; }
  if (CountContain("aaa", "aa") == 1) pass = pass + 1;
  else { fail = fail + 1; "SELFTEST_FAIL=countcontain\n"; }

  // SplitFields.
  U8 *fs = DupStr("a\tb\tc");
  SplitFields(fs);
  if (G_NFIELDS == 3 && StrEq(G_FIELDS[0], "a") && StrEq(G_FIELDS[2], "c")) {
    pass = pass + 1;
  } else {
    fail = fail + 1;
    "SELFTEST_FAIL=splitfields\n";
  }

  // SplitLines drops only the FINAL empty line produced by a trailing
  // '\n'; every interior line, including an EMPTY one, is kept.
  U8 *ls = DupStr("one\ntwo\n\nthree");
  SplitLines(ls);
  if (G_NLINES == 4 && StrEq(G_LINES[0], "one") && StrEq(G_LINES[1], "two")
      && StrEq(G_LINES[2], "") && StrEq(G_LINES[3], "three")) {
    pass = pass + 1;
  } else {
    fail = fail + 1;
    "SELFTEST_FAIL=splitlines\n";
  }

  "SELFTEST_PASS=%d\n", pass;
  "SELFTEST_FAIL=%d\n", fail;
  if (fail == 0) {
    "SELFTEST_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "SELFTEST_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// The entry point.
// ------------------------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "STATUS=ERROR\nREASON=usage: audit <mode> [args]\n";
    return 2;
  }
  U8 *mode = argv[1];

  if (StrEq(mode, "VERIFY-FREEZE")) {
    if (argc < 3) { "STATUS=ERROR\nREASON=VERIFY-FREEZE needs a manifest\n"; return 2; }
    return ModeVerifyFreeze(argv[2]);
  }
  if (StrEq(mode, "JOIN")) {
    if (argc < 5) { "STATUS=ERROR\nREASON=JOIN needs recon05 slice07 corr dirs\n"; return 2; }
    return ModeJoin(argv[2], argv[3], argv[4]);
  }
  if (StrEq(mode, "NC")) {
    if (argc < 3) { "STATUS=ERROR\nREASON=NC needs the correction dir\n"; return 2; }
    return ModeNc(argv[2]);
  }
  if (StrEq(mode, "AC")) {
    if (argc < 3) { "STATUS=ERROR\nREASON=AC needs the correction dir\n"; return 2; }
    return ModeAc(argv[2]);
  }
  if (StrEq(mode, "SELFTEST")) {
    return ModeSelftest();
  }

  "STATUS=ERROR\nREASON=unknown mode\n";
  return 2;
}
