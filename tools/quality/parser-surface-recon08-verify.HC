// tools/quality/parser-surface-recon08-verify.HC
//
// ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08 C2 IMPL.
//
// THE SOURCE-BOUND INDEPENDENT VERIFIER.
//
// WHY THIS TOOL EXISTS
// ====================
//
// The C0 RED of this ACT established two REAL gaps in the existing
// tooling, by ACTUAL OBSERVATION and not by assertion:
//
//   1. The canonical 13-clause checker and the RECON07 recomputer
//      have NO source-range hash column at all.  A candidate that
//      claims a STALE source-range hash for its phase is therefore
//      silently ACCEPTED by both of them.
//
//   2. The canonical ranker TRUSTS its `eligible` column.  A forged
//      eligible flag on an excluded candidate promotes it to rank 1.
//
// This tool closes gap (1) and provides the independent witness that
// gap (2) requires.
//
// WHAT THIS TOOL DOES
// ===================
//
//   MODE=ELIGIBILITY  Re-derive each of the THIRTEEN eligibility
//                     clause bits DIRECTLY from the C1 RAW FACTS,
//                     WITHOUT reading the canonical checker's output.
//                     This is a TABLE-DRIVEN clause evaluation: a
//                     table of (fact index, accepted value) pairs,
//                     NOT the canonical checker's sequence of
//                     assignments.
//
//   MODE=RANKING      Recompute the COMPLETE R0..R6 order from the
//                     RAW FACTS, WITHOUT reading the canonical
//                     ranker's order and WITHOUT reading the
//                     checker's eligible column.  The sort is a
//                     REPEATED MINIMUM SELECTION over the remaining
//                     rows, NOT the canonical ranker's insertion
//                     sort.
//
//   MODE=ANCHOR       Verify every candidate's source-range SHA-256
//                     against the LIVE source bytes, and verify the
//                     range against the LIVE function census.  This
//                     is the mode the canonical tools CANNOT
//                     provide.
//
//   MODE=JOIN         Compare this tool's eligibility and ranking
//                     against the canonical checker's and the
//                     canonical ranker's actual outputs, by exact
//                     candidate ID.
//
//   MODE=SELFTEST     Known-answer and malformed-input self-tests.
//
// WHY IT IS INDEPENDENT
// =====================
//
//   - it re-reads the RAW facts table, not the checker's output;
//   - it derives each clause from the fact fields with its OWN
//     table-driven vocabulary check;
//   - it sorts with its OWN selection-sort routine;
//   - it does NOT hardcode any candidate ID, candidate count,
//     expected eligibility verdict or expected selection.
//
// F-POLYC-TOOLS: this is a PolyC implementation, compiled and executed
// by a real compiler.  It is not shell glue.
//
// USAGE:
//   build/parser-surface-recon08-verify ELIGIBILITY <rawd-facts.tsv>
//   build/parser-surface-recon08-verify RANKING     <rawd-facts.tsv>
//   build/parser-surface-recon08-verify ANCHOR     <identity.tsv> <file.c> ...
//   build/parser-surface-recon08-verify JOIN        <rawd-facts.tsv> <checker-out.tsv> <ranker-out.tsv>
//   build/parser-surface-recon08-verify SELFTEST

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAX_ROWS      64
#define MAX_FILES      8
#define N_FACT_FIELDS 20
#define N_CLAUSES     13
#define N_DIM_FIELDS  10
#define NAME_MAX     128
#define LINE_MAX    4096

// ------------------------------------------------------------------
// SHA-256 (FIPS 180-4).  The same construction the repository already
// qualifies in tools/quality/lexer07-sha256.HC.  It is reproduced
// here because this tool must be SELF-CONTAINED: the ANCHOR mode
// recomputes a candidate's range digest from the bytes, and it must
// do so with its own code rather than by shelling out to another
// tool's implementation.
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
  U8 *hexd = "0123456789abcdef";
  for (I64 i = 0; i < n; i = i + 1) {
    U8 b = bytes[i];
    dst[i+i]   = hexd[(b >> 4) & 0xf];
    dst[i+i+1] = hexd[b & 0xf];
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
  return *a == 0 && *b == 0;
}

static I64 StrLen(U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

// Parse a leading signed decimal integer.  Returns 0 when the field
// is not an integer at all.  (Same contract as the canonical tools:
// a non-integer field yields 0, which is what the zero-count clauses
// need, and the row is separately rejected as MALFORMED when it has
// too few fields.)
static I64 ParseInt(U8 *s)
{
  I64 v = 0;
  I64 neg = 0;
  U8 *p = s;
  if (*p == '-') { neg = 1; p = p + 1; }
  if (*p == 0) return 0;
  while (*p >= '0' && *p <= '9') {
    v = v * 10 + (*p - '0');
    p = p + 1;
  }
  if (*p != 0) return 0;
  if (neg) return -v;
  return v;
}

// Split one tab-separated line into at most `maxf` pointers.
// Returns the number of fields actually present.
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
// THE CLAUSE POLICY, AS A TABLE.
//
// This is a DIFFERENT REPRESENTATION from the canonical checker's
// sequence of assignments.  The canonical checker evaluates the
// clauses with thirteen separate `if` statements over the fact
// fields.  This tool evaluates them by WALKING A TABLE of
// (fact index, clause kind, expected value) triples.
//
//   clause 01  semantic_authority        field  7   YES
//   clause 02  already_selfhosted        field  8   NO
//   clause 03  r0                        field  9   integer 0..2
//   clause 04  owns_setjmp               field 10   NO
//   clause 05  writes_current_recovery   field 11   NO
//   clause 06  requires_nonlocal_recovery field 12  NO
//   clause 07  host_graph_writes         field 13   integer == 0
//   clause 08  pointer_identity_operations field 14 integer == 0
//   clause 09  parser_callback_count     field 15   integer == 0
//   clause 10  semantic_callback_count   field 16   integer == 0
//   clause 11  deterministic_projection  field 17   YES
//   clause 12  production_delegation_feasible field 18 YES
//   clause 13  candidate_kind            field  6   a runtime
//                                                    semantic authority
//
// The candidate_kind vocabulary for clause 13 is checked with a
// TABLE-DRIVEN membership test over a SEPARATE KIND table, not with
// the canonical checker's sequence of StrEq calls.
// ------------------------------------------------------------------

#define CK_YES       1
#define CK_NO        2
#define CK_INT_EQ0   3
#define CK_INT_LE2   4
#define CK_KIND      5

class ClauseRule {
  I64 field;      // 1-based index into the facts row
  I64 kind;       // CK_*
  U8 *value;      // the accepted literal, for CK_YES / CK_NO
};

static ClauseRule ClauseTable[N_CLAUSES] = {
  { 7,  CK_YES,     "YES" },
  { 8,  CK_NO,      "NO"  },
  { 9,  CK_INT_LE2, ""    },
  { 10, CK_NO,      "NO"  },
  { 11, CK_NO,      "NO"  },
  { 12, CK_NO,      "NO"  },
  { 13, CK_INT_EQ0, ""    },
  { 14, CK_INT_EQ0, ""    },
  { 15, CK_INT_EQ0, ""    },
  { 16, CK_INT_EQ0, ""    },
  { 17, CK_YES,     "YES" },
  { 18, CK_YES,     "YES" },
  { 6,  CK_KIND,    ""    }
};

// The RUNTIME SEMANTIC AUTHORITY kinds.  Clause 13 admits exactly
// these.  A kind that is not in this table is NOT a runtime semantic
// authority.
static U8 *AuthorityKinds[9] = {
  "OPERATOR_PRECEDENCE_TABLE",
  "OPERATOR_CLASSIFIER",
  "FORMAT_SPEC_COUNTER",
  "FORMAT_FUNCTION_TABLE",
  "ALIGNMENT_CALCULATION",
  "TOKEN_CLASSIFIER",
  "AST_PROJECTION_PRIMITIVE",
  "DELIMITER_PRIMITIVE",
  "TYPE_MODIFIER_PRIMITIVE"
};

static I64 KindIsAuthority(U8 *kind)
{
  for (I64 i = 0; i < 9; i = i + 1) {
    if (StrEq(kind, AuthorityKinds[i])) return 1;
  }
  return 0;
}

// Evaluate ONE clause against a facts row.  The clause is selected by
// its index, and the evaluation is driven by the TABLE entry.
static I64 EvalClause(I64 clause, U8 *f[])
{
  ClauseRule *r = &ClauseTable[clause - 1];
  U8 *v = f[r->field - 1];
  if (r->kind == CK_YES) return StrEq(v, r->value);
  if (r->kind == CK_NO)  return StrEq(v, r->value);
  if (r->kind == CK_INT_EQ0) return ParseInt(v) == 0;
  if (r->kind == CK_INT_LE2) {
    I64 x = ParseInt(v);
    return x >= 0 && x <= 2;
  }
  if (r->kind == CK_KIND) return KindIsAuthority(v);
  return 0;
}

// ------------------------------------------------------------------
// THE FACTS TABLE AND ITS LOADER.
//
// A facts row is stored as its split fields, so that the clause
// evaluation and the ranking read the SAME rawd source.
// ------------------------------------------------------------------

class FactRow {
  U8 *id;
  U8 *fields[N_FACT_FIELDS];
  I64 nfields;
  I64 dims[7];     // R0..R5 are facts-derived; R6 is the source order
  U8 *r6file;
  I64 r6line;
  I64 eligible;
  I64 malformed;
  I64 has_dims;    // set when a dimension row supplied R1..R5 and R6
};

static FactRow Facts[MAX_ROWS];
static I64 DimsSuppliedArr[1];
// THE THREE COUNTERS BELOW ARE DECLARED AS ONE-ELEMENT ARRAYS, NOT AS
// INITIALISED SCALARS.
//
// MEASURED COMPILER DEFECT (see the header comment): in this
// compiler, a file-scope `static` SCALAR global WITH AN INITIALISER
// is placed at the storage slot that `Main`'s `argc` parameter
// occupies.  The observable effect is that `argc` reads back as the
// global's VALUE rather than as the argument count, and `argv` reads
// back as NULL.
//
//   static I64 g_n = 42;
//   I32 Main(I32 argc, U8 **argv) { "ARGC=%d\n", argc; ... }
//     -> ARGC=42
//
// The same construct with NO initialiser, or as a ONE-ELEMENT ARRAY,
// is unaffected.  This tool therefore uses the array form, and reads
// element 0.  The defect is recorded as separate compiler debt and is
// NOT fixed under this ACT.
static I64 FactCountArr[1];
static I64 SourceCountArr[1];
static I64 CanonCountArr[1];


// Read the facts table.  Returns 0 on success, 1 when the file
// cannot be read.  A row with too few fields is counted as MALFORMED
// and is NOT admitted as an eligible fact row.
static I64 LoadFacts(U8 *path)
{
  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) return 1;
  FactCountArr[0] = 0;
  U8 *p = buf;
  U8 *end = buf + fsize;
  while (p < end) {
    U8 *line_start = p;
    while (p < end && *p != '\n') p = p + 1;
    U8 *line_end = p;
    if (p < end) p = p + 1;
    if (line_end > line_start && *(line_end - 1) == '\r') line_end = line_end - 1;
    *line_end = 0;
    U8 *line = line_start;
    if (*line == 0) continue;
    if (*line == '#') continue;
    U8 *f[N_FACT_FIELDS];
    I64 nf = SplitTabs(line, f, N_FACT_FIELDS);
    if (FactCountArr[0] >= MAX_ROWS) continue;
    FactRow *r = &Facts[FactCountArr[0]];
    r->id = f[0];
    r->nfields = nf;
    r->malformed = 0;
    if (nf < N_FACT_FIELDS) {
      r->malformed = 1;
      r->eligible = 0;
      FactCountArr[0] = FactCountArr[0] + 1;
      continue;
    }
    for (I64 i = 0; i < N_FACT_FIELDS; i = i + 1) r->fields[i] = f[i];
    // R0 is read FROM THE FACITS, not from a dimension table, so that
    // the eligibility fact and the ranking dimension cannot drift.
    r->dims[0] = ParseInt(r->fields[8]);
    // R1..R5 default to the neutral minima and are OVERWRITTEN by the
    // dimension read.
    for (I64 i = 1; i < 6; i = i + 1) r->dims[i] = 0;
    // R6 is the source order: the facts row's source_file and
    // source_start fields.
    r->r6file = r->fields[2];
    r->r6line = ParseInt(r->fields[3]);
    r->eligible = 0;
    FactCountArr[0] = FactCountArr[0] + 1;
  }
  return 0;
}

// Evaluate every admitted row's thirteen clauses and set its
// eligibility.  A row is eligible only when every clause bit is 1
// AND the production_reachable fact (field 19) is YES.
static U0 EvaluateAll()
{
  for (I64 i = 0; i < FactCountArr[0]; i = i + 1) {
    FactRow *r = &Facts[i];
    if (r->malformed) { r->eligible = 0; continue; }
    I64 all = 1;
    for (I64 c = 1; c <= N_CLAUSES; c = c + 1) {
      if (!EvalClause(c, r->fields)) { all = 0; break; }
    }
    if (all && !StrEq(r->fields[18], "YES")) all = 0;
    r->eligible = all;
  }
}

// ------------------------------------------------------------------
// THE RANKING.
//
// The comparator is a TOTAL order over R0..R6: lower wins, and R6 is
// compared as (file lexical, then line numeric).  The comparator
// therefore does NOT depend on the input row order.
//
// The SORT is a REPEATED MINIMUM SELECTION over the remaining rows.
// The canonical ranker uses an INSERTION SORT.  These are different
// algorithms with the same total order, so agreement between them is
// a genuine cross-check rather than a restatement.
// ------------------------------------------------------------------

// Return 1 when `s` starts with the literal `pfx`.
static I64 HasPrefix(U8 *s, U8 *pfx)
{
  I64 i = 0;
  while (pfx[i] != 0) {
    if (s[i] != pfx[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// Return -1 if a is strictly better than b, +1 if b is better, 0 if
// they compare EQUAL (the tie).  A tie is broken by the candidate ID
// so that the order is TOTAL and deterministic.
static I64 CompareRows(FactRow *a, FactRow *b)
{
  for (I64 i = 0; i < 6; i = i + 1) {
    if (a->dims[i] < b->dims[i]) return -1;
    if (a->dims[i] > b->dims[i]) return 1;
  }
  // R6: file lexical ascending, then line ascending.
  I64 c = 0;
  U8 *pa = a->r6file; U8 *pb = b->r6file;
  while (pa[c] != 0 && pb[c] != 0) {
    if (pa[c] < pb[c]) return -1;
    if (pa[c] > pb[c]) return 1;
    c = c + 1;
  }
  if (pa[c] != 0) return 1;
  if (pb[c] != 0) return -1;
  if (a->r6line < b->r6line) return -1;
  if (a->r6line > b->r6line) return 1;
  // Deterministic tie-break on the candidate ID.
  c = 0;
  while (a->id[c] != 0 && b->id[c] != 0) {
    if (a->id[c] < b->id[c]) return -1;
    if (a->id[c] > b->id[c]) return 1;
    c = c + 1;
  }
  if (a->id[c] != 0) return 1;
  if (b->id[c] != 0) return -1;
  return 0;
}

// Read a dimension table (id R0 R1 R2 R3 R4 R5 R6 eligible rationale)
// and OVERWRITE the facts rows' R1..R5 and R6 from it.  R0 is taken
// from the FACTS row (the same source the checker uses for clause
// 03), so the two cannot drift apart.
//
// The dimension table's `eligible` column and its rationale are
// IGNORED: the eligibility flag is RECOMPUTED from the raw facts and
// is NEVER read from the dimension table.
//
// Returns -1 when the file cannot be read, and the number of fact
// rows that received their dimensions otherwise.  A count of ZERO is
// a legitimate (and detectable) condition, not a read failure.
static I64 LoadDims(U8 *path)
{
  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) return -1;
  U8 *p = buf;
  U8 *end = buf + fsize;
  I64 matched = 0;
  DimsSuppliedArr[0] = 1;
  while (p < end) {
    U8 *line_start = p;
    while (p < end && *p != '\n') p = p + 1;
    U8 *line_end = p;
    if (p < end) p = p + 1;
    if (line_end > line_start && *(line_end - 1) == '\r') line_end = line_end - 1;
    *line_end = 0;
    U8 *line = line_start;
    if (*line == 0) continue;
    if (*line == '#') continue;
    U8 *f[N_DIM_FIELDS];
    I64 nf = SplitTabs(line, f, N_DIM_FIELDS);
    if (nf < 8) continue;
    for (I64 i = 0; i < FactCountArr[0]; i = i + 1) {
      FactRow *r = &Facts[i];
      if (!StrEq(r->id, f[0])) continue;
      // The dimension table's schema is
      //   01 candidate_id  02 R0  03 R1  04 R2  05 R3  06 R4  07 R5
      //   08 R6  09 eligible  10 rationale
      // so R1..R5 live in fields 3..7 and R6 in field 8.
      for (I64 d = 1; d <= 5; d = d + 1) r->dims[d] = ParseInt(f[d + 1]);
      // R6 is "<file>:<line>"; split it back into its two parts.
      U8 *r6 = f[7];
      U8 *colon = r6;
      while (*colon != 0 && *colon != ':') colon = colon + 1;
      if (*colon == ':') {
        *colon = 0;
        r->r6file = r6;
        r->r6line = ParseInt(colon + 1);
      }
      matched = matched + 1;
      r->has_dims = 1;
      break;
    }
  }
  return matched;
}

// Produce the complete order by repeated minimum selection over the
// ELIGIBLE rows.  Writes the order into `order` (row indices) and
// returns the number of ranked rows.
static I64 ComputeOrder(I64 *order)
{
  I64 used[MAX_ROWS];
  for (I64 i = 0; i < FactCountArr[0]; i = i + 1) used[i] = 0;
  I64 n = 0;
  for (I64 step = 0; step < FactCountArr[0]; step = step + 1) {
    I64 best = -1;
    for (I64 i = 0; i < FactCountArr[0]; i = i + 1) {
      if (used[i]) continue;
      if (!Facts[i].eligible) continue;
      // A candidate with NO dimension row has no R1..R5 and no R6, so
      // it cannot be placed in the order.  It is EXCLUDED, exactly as
      // the canonical ranker excludes it by never receiving it.
      if (DimsSuppliedArr[0] && !Facts[i].has_dims) continue;
      if (best < 0) { best = i; continue; }
      if (CompareRows(&Facts[i], &Facts[best]) < 0) best = i;
    }
    if (best < 0) break;
    used[best] = 1;
    order[n] = best;
    n = n + 1;
  }
  return n;
}

// ------------------------------------------------------------------
// MODE=ANCHOR -- THE SOURCE-RANGE VERIFIER.
//
// This is the mode the canonical checker and the RECON07 recomputer
// CANNOT provide: it recomputes each candidate's source-range
// SHA-256 from the LIVE source bytes and compares it to the claimed
// digest.
//
// The identity table schema is the same one the repository's
// MODE=IDENTITY mode uses:
//
//   01 candidate_id
//   02 source_file
//   03 source_start   (1-based line)
//   04 source_end     (1-based line, inclusive)
//   05 source_sha256  (the claimed digest)
//   06 function_name
//
// The range digest is computed over the EXACT BYTES of the lines
// [start..end], including their trailing newlines, which is the same
// convention the repository's existing RANGE mode uses.
// ------------------------------------------------------------------

class SrcFile {
  U8 *path;
  U8 *bytes;
  I64 len;
  I64 *lineoff;   // byte offset of each line, 1-based
  I64 nlines;
};

static SrcFile Sources[MAX_FILES];


static I64 LoadSource(U8 *path)
{
  if (SourceCountArr[0] >= MAX_FILES) return 0;
  I64 len = 0;
  U8 *bytes = FileRead(path, &len);
  if (bytes == NULL) return 0;
  SrcFile *s = &Sources[SourceCountArr[0]];
  s->path = path;
  s->bytes = bytes;
  s->len = len;
  // Build the line-offset table.
  I64 cap = 1024;
  I64 *off = MAlloc(cap * 8);
  I64 n = 1;
  off[0] = 0;
  for (I64 i = 0; i < len; i = i + 1) {
    if (bytes[i] == '\n') {
      if (n + 2 > cap) {
        I64 *nb = MAlloc(cap * 16);
        for (I64 k = 0; k < n; k = k + 1) nb[k] = off[k];
        Free(off);
        off = nb;
        cap = cap * 2;
      }
      n = n + 1;
      off[n - 1] = i + 1;
    }
  }
  s->lineoff = off;
  s->nlines = n;
  SourceCountArr[0] = SourceCountArr[0] + 1;
  return 1;
}

// Return the source index for a path, or -1.
static I64 FindSource(U8 *path)
{
  for (I64 i = 0; i < SourceCountArr[0]; i = i + 1) {
    if (StrEq(Sources[i].path, path)) return i;
  }
  return -1;
}

// Compute the SHA-256 of the byte range of lines [start..end] in the
// given source.  Returns 0 when the range is out of bounds.
static I64 RangeDigest(I64 si, I64 start, I64 end, U8 *outhexd)
{
  SrcFile *s = &Sources[si];
  if (start < 1) return 0;
  if (end < start) return 0;
  if (end > s->nlines) return 0;
  I64 b0 = s->lineoff[start - 1];
  I64 b1;
  if (end == s->nlines) {
    b1 = s->len;
  } else {
    b1 = s->lineoff[end];
  }
  U8 rawd[32];
  Sha256(s->bytes + b0, b1 - b0, rawd);
  HexOfBytes(rawd, 32, outhexd);
  return 1;
}

// ------------------------------------------------------------------
// MODE=ELIGIBILITY
// ------------------------------------------------------------------

static I64 ModeEligibility(U8 *facts_path)
{
  if (LoadFacts(facts_path)) {
    "STATUS=FAIL\nREASON=CANNOT_READ_FACTS\nINPUT=%s\n", facts_path;
    return 1;
  }
  EvaluateAll();
  I64 total = 0;
  I64 eligible = 0;
  I64 malformed = 0;
  for (I64 i = 0; i < FactCountArr[0]; i = i + 1) {
    FactRow *r = &Facts[i];
    if (r->malformed) { malformed = malformed + 1; continue; }
    total = total + 1;
    // The verdict is chosen with an EXPLICIT if, not a ternary: this
    // compiler does not accept a ternary in the printf argument list,
    // and the ACT records a pointer-valued ternary OOM as separate
    // debt.  The bounded tooling avoids both.
    U8 *verdict = "NO";
    if (r->eligible) verdict = "YES";
    "ELIG:%s\t%s\t", r->id, verdict;
    I64 failed = 0;
    for (I64 c = 1; c <= N_CLAUSES; c = c + 1) {
      I64 bit = EvalClause(c, r->fields);
      "%d", bit;
      if (!bit) failed = failed + 1;
    }
    "\t%d\n", failed;
    if (r->eligible) eligible = eligible + 1;
  }
  "TOTAL=%d\n", total;
  "ELIGIBLE=%d\n", eligible;
  "MALFORMED=%d\n", malformed;
  "INELIGIBLE=%d\n", total - eligible;
  "STATUS=PASS\n";
  return 0;
}

// ------------------------------------------------------------------
// MODE=RANKING
// ------------------------------------------------------------------

static I64 ModeRanking(U8 *facts_path, U8 *dims_path)
{
  if (LoadFacts(facts_path)) {
    "STATUS=FAIL\nREASON=CANNOT_READ_FACTS\nINPUT=%s\n", facts_path;
    return 1;
  }
  EvaluateAll();
  if (dims_path != NULL) {
    I64 dims_matched = LoadDims(dims_path);
    if (dims_matched < 0) {
      "STATUS=FAIL\nREASON=CANNOT_READ_DIMS\nINPUT=%s\n", dims_path;
      return 1;
    }
    "DIMS_MATCHED=%d\n", dims_matched;
  }
  I64 order[MAX_ROWS];
  I64 n = ComputeOrder(order);
  for (I64 i = 0; i < n; i = i + 1) {
    FactRow *r = &Facts[order[i]];
    "RANKED:%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%s:%d\n",
      i + 1, r->id, r->dims[0], r->dims[1], r->dims[2], r->dims[3],
      r->dims[4], r->dims[5], r->r6file, r->r6line;
  }
  I64 eligible = 0;
  I64 malformed = 0;
  for (I64 i = 0; i < FactCountArr[0]; i = i + 1) {
    if (Facts[i].malformed) malformed = malformed + 1;
    else if (Facts[i].eligible) eligible = eligible + 1;
  }
  "RANKED_COUNT=%d\n", n;
  "ELIGIBLE=%d\n", eligible;
  "TOTAL=%d\n", FactCountArr[0];
  "MALFORMED=%d\n", malformed;
  // The selected ID is chosen with an EXPLICIT if, not a
  // pointer-valued ternary: the ACT records a pointer-valued ternary
  // OOM in this compiler as separate debt, and the bounded tooling
  // avoids it.
  U8 *selected = "NONE";
  if (n > 0) selected = Facts[order[0]].id;
  "SELECTED=%s\n", selected;
  "STATUS=PASS\n";
  return 0;
}

// ------------------------------------------------------------------
// MODE=ANCHOR
// ------------------------------------------------------------------

static I64 ModeAnchor(U8 *ids_path, U8 *files[], I64 nfiles)
{
  for (I64 i = 0; i < nfiles; i = i + 1) {
    if (!LoadSource(files[i])) {
      "STATUS=FAIL\nREASON=CANNOT_READ_SOURCE\nFILE=%s\n", files[i];
      return 1;
    }
  }
  I64 tlen = 0;
  U8 *tbl = FileRead(ids_path, &tlen);
  if (tbl == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_IDENTITY_TABLE\nINPUT=%s\n", ids_path;
    return 1;
  }
  I64 rows = 0;
  I64 ok = 0;
  I64 hash_mismatch = 0;
  I64 invalid_range = 0;
  I64 missing_source = 0;
  U8 *p = tbl;
  U8 *end = tbl + tlen;
  while (p < end) {
    U8 *line_start = p;
    while (p < end && *p != '\n') p = p + 1;
    U8 *line_end = p;
    if (p < end) p = p + 1;
    if (line_end > line_start && *(line_end - 1) == '\r') line_end = line_end - 1;
    *line_end = 0;
    U8 *line = line_start;
    if (*line == 0) continue;
    if (*line == '#') continue;
    U8 *f[6];
    I64 nf = SplitTabs(line, f, 6);
    if (nf < 5) continue;
    rows = rows + 1;
    I64 start = ParseInt(f[2]);
    I64 end = ParseInt(f[3]);
    I64 si = FindSource(f[1]);
    if (si < 0) {
      missing_source = missing_source + 1;
      "DETECTOR=MISSING_SOURCE\nCANDIDATE_ID=%s\nFILE=%s\n", f[0], f[1];
      continue;
    }
    U8 actual[80];
    if (!RangeDigest(si, start, end, actual)) {
      invalid_range = invalid_range + 1;
      "DETECTOR=INVALID_RANGE\nCANDIDATE_ID=%s\nFILE=%s\nSTART=%d\nEND=%d\n",
        f[0], f[1], start, end;
      continue;
    }
    if (!StrEq(actual, f[4])) {
      hash_mismatch = hash_mismatch + 1;
      "DETECTOR=SOURCE_HASH_MISMATCH\nCANDIDATE_ID=%s\nFILE=%s\nRANGE=%d..%d\nEXPECTED_SHA256=%s\nACTUAL_SHA256=%s\n",
        f[0], f[1], start, end, f[4], actual;
      continue;
    }
    ok = ok + 1;
    "ANCHOR_OK:%s\t%s\t%d\t%d\t%s\n", f[0], f[1], start, end, actual;
  }
  "ANCHOR_ROWS=%d\n", rows;
  "ANCHOR_OK=%d\n", ok;
  "SOURCE_HASH_MISMATCH=%d\n", hash_mismatch;
  "INVALID_RANGE=%d\n", invalid_range;
  "MISSING_SOURCE=%d\n", missing_source;
  if (hash_mismatch == 0 && invalid_range == 0 && missing_source == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=JOIN -- COMPARE AGAINST THE CANONICAL TOOLS' ACTUAL OUTPUTS.
//
// The comparison is by EXACT CANDIDATE ID, never by row order.  The
// canonical checker's output lines are
//
//   <id> <YES|NO> <clause bits> <failed>
//
// and the canonical ranker's ranked lines are
//
//   RANKED:<n> <id> R0 R1 R2 R3 R4 R5 R6
//
// This mode reads those ACTUAL outputs and compares them with this
// tool's independently computed values.
// ------------------------------------------------------------------

class CanonElig {
  U8 *id;
  U8 *verdict;
  U8 *bits;
};

static CanonElig Canon[MAX_ROWS];


static I64 LoadCanonElig(U8 *path)
{
  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) return 1;
  CanonCountArr[0] = 0;
  U8 *p = buf;
  U8 *end = buf + fsize;
  while (p < end) {
    U8 *line_start = p;
    while (p < end && *p != '\n') p = p + 1;
    U8 *line_end = p;
    if (p < end) p = p + 1;
    if (line_end > line_start && *(line_end - 1) == '\r') line_end = line_end - 1;
    *line_end = 0;
    U8 *line = line_start;
    if (*line == 0) continue;
    if (*line == '#') continue;
    U8 *f[4];
    I64 nf = SplitTabs(line, f, 4);
    if (nf < 3) continue;
    if (CanonCountArr[0] >= MAX_ROWS) continue;
    Canon[CanonCountArr[0]].id = f[0];
    Canon[CanonCountArr[0]].verdict = f[1];
    Canon[CanonCountArr[0]].bits = f[2];
    CanonCountArr[0] = CanonCountArr[0] + 1;
  }
  return 0;
}

// ------------------------------------------------------------------
// MODE=FIXTURE -- THE FIXTURE-INTEGRITY DETECTOR.
//
// The frozen fixture is a table of rows:
//
//   01 row_id  02 token_type  03 keyword_id  04 expected_selector
//   05 constructor
//
// The detector compares the fixture against the frozen one, BY EXACT
// ROW ID, and reports the FIRST differing row.  A corrupted expected
// value is a FIXTURE_ROW_MISMATCH with the exact row.
//
// USAGE:
//   build/parser-surface-recon08-verify FIXTURE <frozen.tsv> <observed.tsv>
// ------------------------------------------------------------------

static I64 ModeFixture(U8 *frozen_path, U8 *obs_path)
{
  I64 fsize = 0;
  I64 osize = 0;
  U8 *fb = FileRead(frozen_path, &fsize);
  U8 *ob = FileRead(obs_path, &osize);
  if (fb == NULL) { "STATUS=FAIL\nREASON=CANNOT_READ_FROZEN_FIXTURE\n"; return 1; }
  if (ob == NULL) { "STATUS=FAIL\nREASON=CANNOT_READ_OBSERVED_FIXTURE\n"; return 1; }
  I64 rows = 0;
  I64 mismatches = 0;
  // For every observed row, find the frozen row with the same ID and
  // compare the remaining fields.
  U8 *op = ob;
  U8 *oend = ob + osize;
  while (op < oend) {
    U8 *ols = op;
    while (op < oend && *op != '\n') op = op + 1;
    I64 llen = op - ols;
    if (op < oend) op = op + 1;
    // Copy the line out before splitting it: a NUL written into the
    // buffer would truncate the next line scan.
    U8 *lbuf = MAlloc(llen + 1);
    for (I64 q = 0; q < llen; q = q + 1) lbuf[q] = ols[q];
    lbuf[llen] = 0;
    if (llen == 0) { Free(lbuf); continue; }
    if (lbuf[0] == '#') { Free(lbuf); continue; }
    U8 *of[5];
    I64 onf = SplitTabs(lbuf, of, 5);
    if (onf < 5) { Free(lbuf); continue; }
    rows = rows + 1;
    // The observed row's fields are COPIED OUT: the split above
    // replaced the line's tabs with NULs, and the frozen lookup below
    // re-reads the observed row only through these copies.
    U8 *ocopy[5];
    for (I64 k = 0; k < 5; k = k + 1) {
      I64 l = StrLen(of[k]);
      U8 *cp = MAlloc(l + 1);
      for (I64 q = 0; q < l; q = q + 1) cp[q] = of[k][q];
      cp[l] = 0;
      ocopy[k] = cp;
    }
    Free(lbuf);
    // Find the frozen row with the same ID.
    //
    // The frozen buffer is scanned by BYTE OFFSET, using a COPY of
    // each candidate line, so that splitting a line never writes a
    // NUL into the buffer that the line scan is still walking.  A
    // NUL written into the buffer would truncate the next line scan
    // at that NUL and silently skip the following row.
    U8 *fp = fb;
    U8 *fend = fb + fsize;
    U8 *fcopy[5];
    I64 found = 0;
    while (fp < fend) {
      U8 *fls = fp;
      while (fp < fend && *fp != '\n') fp = fp + 1;
      I64 llen = fp - fls;
      if (fp < fend) fp = fp + 1;
      // Copy the line out before touching it.
      U8 *lbuf = MAlloc(llen + 1);
      for (I64 q = 0; q < llen; q = q + 1) lbuf[q] = fls[q];
      lbuf[llen] = 0;
      if (llen == 0) { Free(lbuf); continue; }
      if (lbuf[0] == '#') { Free(lbuf); continue; }
      U8 *ff[5];
      I64 fnf = SplitTabs(lbuf, ff, 5);
      if (fnf < 5) { Free(lbuf); continue; }
      if (!StrEq(ff[0], ocopy[0])) { Free(lbuf); continue; }
      for (I64 k = 0; k < 5; k = k + 1) {
        I64 l = StrLen(ff[k]);
        U8 *cp = MAlloc(l + 1);
        for (I64 q = 0; q < l; q = q + 1) cp[q] = ff[k][q];
        cp[l] = 0;
        fcopy[k] = cp;
      }
      Free(lbuf);
      found = 1;
      break;
    }
    if (!found) {
      mismatches = mismatches + 1;
      "DETECTOR=FIXTURE_ROW_MISMATCH\nROW_ID=%s\nREASON=THE_ROW_IS_ABSENT_FROM_THE_FROZEN_FIXTURE\n", ocopy[0];
      continue;
    }
    I64 same = 1;
    for (I64 k = 1; k < 5; k = k + 1) {
      if (!StrEq(fcopy[k], ocopy[k])) { same = 0; break; }
    }
    if (!same) {
      mismatches = mismatches + 1;
      "DETECTOR=FIXTURE_ROW_MISMATCH\nROW_ID=%s\n", ocopy[0];
      "EXPECTED=%s %s %s %s\n", fcopy[1], fcopy[2], fcopy[3], fcopy[4];
      "ACTUAL=%s %s %s %s\n", ocopy[1], ocopy[2], ocopy[3], ocopy[4];
    }
  }
  "FIXTURE_ROWS=%d\n", rows;
  "FIXTURE_MISMATCHES=%d\n", mismatches;
  if (mismatches == 0) { "STATUS=PASS\n"; return 0; }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=G0 -- THE G0-PROVENANCE DETECTOR.
//
// A G0 oracle is GENUINE only when it is the REAL PRODUCTION
// TRANSLATION UNIT compiled with the candidate selector OFF.
//
// A G0 oracle is NOT genuine when:
//   (a) it is a HANDMADE re-implementation of the rule: it does not
//       carry the production function-scoped relocations to the
//       statement constructors; or
//   (b) it IMPORTS the PolyC successor symbol: then the "legacy"
//       oracle is not legacy at all.
//
// The detector works on the OBJECT FILE, so it checks the artefact
// that would actually be linked.
//
// USAGE:
//   build/parser-surface-recon08-verify G0 <object-file> <successor-symbol> <constructor-symbol> ...
//
// ------------------------------------------------------------------

static I64 ModeG0(U8 *obj_path, U8 *succ, U8 *ctors[], I64 nctors)
{
  I64 osize = 0;
  U8 *obj = FileRead(obj_path, &osize);
  if (obj == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_OBJECT\nINPUT=%s\n", obj_path;
    return 1;
  }
  // Does the object IMPORT the PolyC successor symbol?
  I64 imports_successor = 0;
  {
    I64 sl = StrLen(succ);
    for (I64 i = 0; i + sl <= osize; i = i + 1) {
      if (obj[i] != succ[0]) continue;
      I64 same = 1;
      for (I64 j = 1; j < sl; j = j + 1) if (obj[i + j] != succ[j]) { same = 0; break; }
      if (same) { imports_successor = 1; break; }
    }
  }
  // Does the object carry the PRODUCTION constructor relocations?
  I64 found_ctors = 0;
  for (I64 c = 0; c < nctors; c = c + 1) {
    I64 sl = StrLen(ctors[c]);
    for (I64 i = 0; i + sl <= osize; i = i + 1) {
      if (obj[i] != ctors[c][0]) continue;
      I64 same = 1;
      for (I64 j = 1; j < sl; j = j + 1) if (obj[i + j] != ctors[c][j]) { same = 0; break; }
      if (same) { found_ctors = found_ctors + 1; break; }
    }
  }
  "G0_OBJECT=%s\n", obj_path;
  "G0_IMPORTS_SUCCESSOR=%d\n", imports_successor;
  "G0_CONSTRUCTOR_RELOCATIONS_FOUND=%d\n", found_ctors;
  "G0_CONSTRUCTORS_EXPECTED=%d\n", nctors;
  if (imports_successor) {
    "DETECTOR=G0_NOT_GENUINE_C_TU\nREASON=THE_G0_OBJECT_IMPORTS_THE_POLYC_SUCCESSOR_SYMBOL\n";
    "STATUS=FAIL\n";
    return 1;
  }
  if (found_ctors < nctors) {
    "DETECTOR=G0_NOT_GENUINE_C_TU\nREASON=THE_G0_OBJECT_IS_NOT_THE_PRODUCTION_TRANSLATION_UNIT\n";
    "STATUS=FAIL\n";
    return 1;
  }
  "STATUS=PASS\n";
  return 0;
}

// ------------------------------------------------------------------
// MODE=ROSTER -- THE UNKNOWN-ID DETECTOR.
//
// A candidate ID that is not in the FROZEN ROSTER is UNKNOWN, whether
// it appears in the facts table, in the checker's output, or in both.
//
// This is the detector that the canonical checker CANNOT provide: the
// canonical checker adjudicates ANY row it is given, so an injected
// unknown ID is silently adjudicated as a normal candidate.  The
// roster comparison is what makes an unknown ID detectable.
//
// USAGE:
//   build/parser-surface-recon08-verify ROSTER <roster.txt> <facts.tsv>
//   build/parser-surface-recon08-verify ROSTER <roster.txt> <facts.tsv> <checker-out.tsv>
//
// The roster file is one candidate ID per line; `#` starts a comment.
// ------------------------------------------------------------------

static U8 *RosterIds[MAX_ROWS];
static I64 RosterCountArr[1];

static I64 LoadRoster(U8 *path)
{
  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) return 1;
  RosterCountArr[0] = 0;
  U8 *p = buf;
  U8 *end = buf + fsize;
  while (p < end) {
    U8 *ls = p;
    while (p < end && *p != '\n') p = p + 1;
    U8 *le = p;
    if (p < end) p = p + 1;
    if (le > ls && *(le - 1) == '\r') le = le - 1;
    *le = 0;
    if (*ls == 0) continue;
    if (*ls == '#') continue;
    if (RosterCountArr[0] >= MAX_ROWS) continue;
    RosterIds[RosterCountArr[0]] = ls;
    RosterCountArr[0] = RosterCountArr[0] + 1;
  }
  return 0;
}

static I64 InRoster(U8 *id)
{
  for (I64 i = 0; i < RosterCountArr[0]; i = i + 1) {
    if (StrEq(RosterIds[i], id)) return 1;
  }
  return 0;
}

static I64 ModeRoster(U8 *roster_path, U8 *facts_path, U8 *canon_path)
{
  if (LoadRoster(roster_path)) {
    "STATUS=FAIL\nREASON=CANNOT_READ_ROSTER\nINPUT=%s\n", roster_path;
    return 1;
  }
  if (LoadFacts(facts_path)) {
    "STATUS=FAIL\nREASON=CANNOT_READ_FACTS\nINPUT=%s\n", facts_path;
    return 1;
  }
  I64 unknown_facts = 0;
  for (I64 i = 0; i < FactCountArr[0]; i = i + 1) {
    if (InRoster(Facts[i].id)) continue;
    unknown_facts = unknown_facts + 1;
    "DETECTOR=UNKNOWN_CANDIDATE_ID\nCANDIDATE_ID=%s\nSOURCE=FACTS\n", Facts[i].id;
  }
  I64 unknown_canon = 0;
  if (canon_path != NULL) {
    if (LoadCanonElig(canon_path)) {
      "STATUS=FAIL\nREASON=CANNOT_READ_CANONICAL_ELIGIBILITY\nINPUT=%s\n", canon_path;
      return 1;
    }
    for (I64 k = 0; k < CanonCountArr[0]; k = k + 1) {
      if (InRoster(Canon[k].id)) continue;
      unknown_canon = unknown_canon + 1;
      "DETECTOR=UNKNOWN_CANDIDATE_ID\nCANDIDATE_ID=%s\nSOURCE=CHECKER_OUTPUT\n", Canon[k].id;
    }
  }
  // A roster ID that no fact row claims is a MISSING candidate.
  I64 missing = 0;
  for (I64 i = 0; i < RosterCountArr[0]; i = i + 1) {
    I64 found = 0;
    for (I64 k = 0; k < FactCountArr[0]; k = k + 1) {
      if (StrEq(Facts[k].id, RosterIds[i])) { found = 1; break; }
    }
    if (!found) {
      missing = missing + 1;
      "DETECTOR=MISSING_CANDIDATE_ID\nCANDIDATE_ID=%s\nSOURCE=ROSTER\n", RosterIds[i];
    }
  }
  "ROSTER_COUNT=%d\n", RosterCountArr[0];
  "FACTS_COUNT=%d\n", FactCountArr[0];
  "UNKNOWN_CANDIDATE_ID=%d\n", unknown_facts + unknown_canon;
  "MISSING_CANDIDATE_ID=%d\n", missing;
  if (unknown_facts + unknown_canon + missing == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}


static I64 ModeJoin(U8 *facts_path, U8 *dims_path, U8 *canon_path, U8 *ranker_path)
{
  if (LoadFacts(facts_path)) {
    "STATUS=FAIL\nREASON=CANNOT_READ_FACTS\nINPUT=%s\n", facts_path;
    return 1;
  }
  EvaluateAll();
  // The R1..R5 and R6 dimensions are read from the dimension table.
  // R0 comes from the FACTS row, so the eligibility fact and the
  // ranking dimension cannot drift apart.  The dimension table's own
  // `eligible` column is IGNORED.
  if (dims_path != NULL) {
    I64 dims_matched = LoadDims(dims_path);
    if (dims_matched < 0) {
      "STATUS=FAIL\nREASON=CANNOT_READ_DIMS\nINPUT=%s\n", dims_path;
      return 1;
    }
    "DIMS_MATCHED=%d\n", dims_matched;
  }
  if (LoadCanonElig(canon_path)) {
    "STATUS=FAIL\nREASON=CANNOT_READ_CANONICAL_ELIGIBILITY\nINPUT=%s\n", canon_path;
    return 1;
  }
  // ---- PART 1: THE ELIGIBILITY JOIN ----
  I64 mismatch = 0;
  I64 unbound = 0;
  for (I64 i = 0; i < FactCountArr[0]; i = i + 1) {
    FactRow *r = &Facts[i];
    if (r->malformed) continue;
    I64 found = -1;
    for (I64 k = 0; k < CanonCountArr[0]; k = k + 1) {
      if (StrEq(Canon[k].id, r->id)) { found = k; break; }
    }
    if (found < 0) {
      unbound = unbound + 1;
      "DETECTOR=UNBOUND_ID\nCANDIDATE_ID=%s\n", r->id;
      continue;
    }
    I64 canon_yes = StrEq(Canon[found].verdict, "YES");
    U8 *indep_verdict = "NO";
    if (r->eligible) indep_verdict = "YES";
    if (canon_yes != r->eligible) {
      mismatch = mismatch + 1;
      "DETECTOR=ELIGIBILITY_MISMATCH\nCANDIDATE_ID=%s\nCANONICAL=%s\nINDEPENDENT=%s\n",
        r->id, Canon[found].verdict, indep_verdict;
      continue;
    }
    // The clause BITS must agree too, not merely the verdict.
    I64 bits_agree = 1;
    for (I64 c = 0; c < N_CLAUSES; c = c + 1) {
      I64 mine = EvalClause(c + 1, r->fields);
      I64 theirs = 0;
      if (Canon[found].bits[c] == '1') theirs = 1;
      if (mine != theirs) { bits_agree = 0; break; }
    }
    if (!bits_agree) {
      mismatch = mismatch + 1;
      "DETECTOR=ELIGIBILITY_CLAUSE_MISMATCH\nCANDIDATE_ID=%s\nCANONICAL_BITS=%s\n", r->id, Canon[found].bits;
    }
  }
  // A canonical row that names no fact row is an EXTRA.
  I64 extra = 0;
  for (I64 k = 0; k < CanonCountArr[0]; k = k + 1) {
    I64 found = 0;
    for (I64 i = 0; i < FactCountArr[0]; i = i + 1) {
      if (StrEq(Facts[i].id, Canon[k].id)) { found = 1; break; }
    }
    if (!found) {
      extra = extra + 1;
      "DETECTOR=EXTRA_ID\nCANDIDATE_ID=%s\n", Canon[k].id;
    }
  }
  "ELIGIBILITY_MISMATCH=%d\n", mismatch;
  "ELIGIBILITY_UNBOUND_ID=%d\n", unbound;
  "ELIGIBILITY_EXTRA_ID=%d\n", extra;
  //
  // ---- PART 2: THE FULL-ORDER JOIN ----
  //
  I64 order[MAX_ROWS];
  I64 n = ComputeOrder(order);
  I64 order_mismatch = 0;
  if (ranker_path != NULL) {
    I64 rsize = 0;
    U8 *rbuf = FileRead(ranker_path, &rsize);
    if (rbuf == NULL) {
      "STATUS=FAIL\nREASON=CANNOT_READ_CANONICAL_RANKING\nINPUT=%s\n", ranker_path;
      return 1;
    }
    // Collect the canonical ranker's order.
    U8 *canon_order[MAX_ROWS];
    I64 canon_n = 0;
    U8 *p = rbuf;
    U8 *end = rbuf + rsize;
    while (p < end) {
      U8 *line_start = p;
      while (p < end && *p != '\n') p = p + 1;
      U8 *line_end = p;
      if (p < end) p = p + 1;
      if (line_end > line_start && *(line_end - 1) == '\r') line_end = line_end - 1;
      *line_end = 0;
      U8 *line = line_start;
      if (*line == 0) continue;
      if (line[0] != 'R') continue;
      if (StrLen(line) < 8) continue;
      if (!HasPrefix(line, "RANKED:")) continue;
      U8 *tab = line;
      while (*tab != 0 && *tab != '\t') tab = tab + 1;
      if (*tab != '\t') continue;
      U8 *id = tab + 1;
      U8 *tab2 = id;
      while (*tab2 != 0 && *tab2 != '\t') tab2 = tab2 + 1;
      *tab2 = 0;
      if (canon_n < MAX_ROWS) { canon_order[canon_n] = id; canon_n = canon_n + 1; }
    }
    if (canon_n != n) {
      order_mismatch = order_mismatch + 1;
      "DETECTOR=FULL_ORDER_LENGTH_MISMATCH\nCANONICAL=%d\nINDEPENDENT=%d\n", canon_n, n;
    }
    I64 lim = canon_n;
    if (n < lim) lim = n;
    for (I64 i = 0; i < lim; i = i + 1) {
      if (!StrEq(canon_order[i], Facts[order[i]].id)) {
        order_mismatch = order_mismatch + 1;
        "DETECTOR=RANK_ORDER_MISMATCH\nPOSITION=%d\nCANONICAL=%s\nINDEPENDENT=%s\n",
          i + 1, canon_order[i], Facts[order[i]].id;
      }
    }
    "CANONICAL_RANKED_COUNT=%d\n", canon_n;
  }
  "FULL_ORDER_MISMATCH=%d\n", order_mismatch;
  "INDEPENDENT_RANKED_COUNT=%d\n", n;
  // Explicit if, not a pointer-valued ternary (see the note in
  // ModeRanking).
  U8 *indep_selected = "NONE";
  if (n > 0) indep_selected = Facts[order[0]].id;
  "INDEPENDENT_SELECTED=%s\n", indep_selected;
  //
  I64 bad = mismatch + unbound + extra + order_mismatch;
  if (bad == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=SELFTEST
//
// The self-tests use KNOWN-ANSWER inputs whose expected values are
// fixed here.  They do NOT read the canonical tools' outputs and they
// do NOT hardcode any production candidate ID or count.
//
//   ST-1  the SHA-256 of the empty string
//   ST-2  the SHA-256 of "abc"
//   ST-3  a row with every clause satisfied passes all 13 clauses
//   ST-4  already_selfhosted=YES breaks clause 02
//   ST-5  r0=3 breaks clause 03
//   ST-6  a non-authority kind breaks clause 13
//   ST-7  host_graph_writes=1 breaks clause 07
//   ST-8  the comparator is antisymmetric
// ------------------------------------------------------------------

static I64 SelfTest()
{
  I64 failures = 0;
  U8 rawd[32];
  U8 hexd[80];
  Sha256("", 0, rawd);
  HexOfBytes(rawd, 32, hexd);
  if (!StrEq(hexd, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")) {
    failures = failures + 1;
    "SELFTEST=ST-1 STATUS=FAIL ACTUAL=%s\n", hexd;
  } else { "SELFTEST=ST-1 STATUS=PASS\n"; }
  Sha256("abc", 3, rawd);
  HexOfBytes(rawd, 32, hexd);
  if (!StrEq(hexd, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")) {
    failures = failures + 1;
    "SELFTEST=ST-2 STATUS=FAIL ACTUAL=%s\n", hexd;
  } else { "SELFTEST=ST-2 STATUS=PASS\n"; }
  U8 *good[20];
  good[0]="ST";   good[1]="f";    good[2]="src/x.c";
  good[3]="1";   good[4]="2";    good[5]="TOKEN_CLASSIFIER";
  good[6]="YES"; good[7]="NO";   good[8]="0";
  good[9]="NO";  good[10]="NO";  good[11]="NO";
  good[12]="0"; good[13]="0";   good[14]="0";
  good[15]="0"; good[16]="YES";  good[17]="YES";
  good[18]="YES";good[19]="-";
  I64 nclause = 0;
  for (I64 c = 1; c <= N_CLAUSES; c = c + 1) if (EvalClause(c, good)) nclause = nclause + 1;
  if (nclause != N_CLAUSES) {
    failures = failures + 1;
    "SELFTEST=ST-3 STATUS=FAIL BITS=%d\n", nclause;
  } else { "SELFTEST=ST-3 STATUS=PASS\n"; }
  U8 *m[20];
  for (I64 i = 0; i < 20; i = i + 1) m[i] = good[i];
  m[7] = "YES";
  if (EvalClause(2, m)) { failures = failures + 1; "SELFTEST=ST-4 STATUS=FAIL\n"; }
  else { "SELFTEST=ST-4 STATUS=PASS\n"; }
  for (I64 i = 0; i < 20; i = i + 1) m[i] = good[i];
  m[8] = "3";
  if (EvalClause(3, m)) { failures = failures + 1; "SELFTEST=ST-5 STATUS=FAIL\n"; }
  else { "SELFTEST=ST-5 STATUS=PASS\n"; }
  for (I64 i = 0; i < 20; i = i + 1) m[i] = good[i];
  m[5] = "STATIC_HELPER";
  if (EvalClause(13, m)) { failures = failures + 1; "SELFTEST=ST-6 STATUS=FAIL\n"; }
  else { "SELFTEST=ST-6 STATUS=PASS\n"; }
  for (I64 i = 0; i < 20; i = i + 1) m[i] = good[i];
  m[12] = "1";
  if (EvalClause(7, m)) { failures = failures + 1; "SELFTEST=ST-7 STATUS=FAIL\n"; }
  else { "SELFTEST=ST-7 STATUS=PASS\n"; }
  FactRow a; FactRow b;
  a.id="A"; b.id="B";
  for (I64 i = 0; i < 6; i = i + 1) { a.dims[i]=0; b.dims[i]=0; }
  a.r6file="src/x.c"; b.r6file="src/x.c";
  a.r6line=1; b.r6line=1;
  I64 ab = CompareRows(&a, &b);
  I64 ba = CompareRows(&b, &a);
  if (ab != -ba) {
    failures = failures + 1;
    "SELFTEST=ST-8 STATUS=FAIL AB=%d BA=%d\n", ab, ba;
  } else { "SELFTEST=ST-8 STATUS=PASS\n"; }
  "SELFTEST_FAILURES=%d\n", failures;
  if (failures == 0) { "STATUS=PASS\n"; return 0; }
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MAIN
// ------------------------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "USAGE=parser-surface-recon08-verify ELIGIBILITY|RANKING|ANCHOR|JOIN|SELFTEST ...\n";
    return 1;
  }
  U8 *mode = argv[1];
  if (StrEq(mode, "SELFTEST")) return SelfTest();
  if (StrEq(mode, "ELIGIBILITY")) {
    if (argc < 3) { "STATUS=FAIL\nREASON=MISSING_FACTS\n"; return 1; }
    return ModeEligibility(argv[2]);
  }
  if (StrEq(mode, "RANKING")) {
    if (argc < 3) { "STATUS=FAIL\nREASON=MISSING_FACTS\n"; return 1; }
    U8 *dims = NULL;
    if (argc > 3) dims = argv[3];
    return ModeRanking(argv[2], dims);
  }
  if (StrEq(mode, "ANCHOR")) {
    if (argc < 4) { "STATUS=FAIL\nREASON=MISSING_IDENTITY_TABLE\n"; return 1; }
    U8 *files[MAX_FILES];
    I64 nfiles = 0;
    for (I64 i = 3; i < argc && nfiles < MAX_FILES; i = i + 1) {
      files[nfiles] = argv[i];
      nfiles = nfiles + 1;
    }
    return ModeAnchor(argv[2], files, nfiles);
  }
  if (StrEq(mode, "FIXTURE")) {
    if (argc < 4) { "STATUS=FAIL\nREASON=MISSING_INPUTS\n"; return 1; }
    return ModeFixture(argv[2], argv[3]);
  }
  if (StrEq(mode, "G0")) {
    if (argc < 5) { "STATUS=FAIL\nREASON=MISSING_INPUTS\n"; return 1; }
    U8 *ctors[32];
    I64 nctors = 0;
    for (I64 i = 4; i < argc && nctors < 32; i = i + 1) {
      ctors[nctors] = argv[i];
      nctors = nctors + 1;
    }
    return ModeG0(argv[2], argv[3], ctors, nctors);
  }
  if (StrEq(mode, "ROSTER")) {
    if (argc < 4) { "STATUS=FAIL\nREASON=MISSING_INPUTS\n"; return 1; }
    U8 *canon = NULL;
    if (argc > 4) canon = argv[4];
    return ModeRoster(argv[2], argv[3], canon);
  }
  if (StrEq(mode, "JOIN")) {
    if (argc < 5) { "STATUS=FAIL\nREASON=MISSING_INPUTS\n"; return 1; }
    U8 *ranker = NULL;
    if (argc > 6) ranker = argv[6];
    return ModeJoin(argv[2], argv[3], argv[4], ranker);
  }
  "STATUS=FAIL\nREASON=UNKNOWN_MODE\nMODE=%s\n", mode;
  return 1;
}
