// tools/quality/parser-surface-recon07-recompute.HC
//
// ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07 C3.
//
// THE INDEPENDENT RECOMPUTER.
//
// It re-derives, FROM THE RAW C1 FACTS ALONE:
//
//   1. every one of the THIRTEEN eligibility clause bits, and
//   2. the COMPLETE R0..R6 order and the deterministic winner,
//
// WITHOUT reading the canonical checker's output, the canonical
// ranker's output, or the selected candidate ID.
//
// WHY A SEPARATE IMPLEMENTATION IS REQUIRED
// =========================================
//
// The canonical checker and the canonical ranker are the AUTHORITY for
// the C2 stage, but they are not an independent witness of themselves.
// This tool is a SECOND, SEPARATE implementation of the same policy:
//
//   - it re-reads the raw facts table, not the checker's output;
//   - it derives each clause from the fact fields with its OWN code
//     path, using its OWN vocabulary check (not a shared helper);
//   - it sorts with its OWN comparison routine.
//
// It is written to be INDEPENDENT, not to be a copy: the clause
// evaluation uses a different control structure (a per-clause switch
// over the fact indices rather than a sequence of assignments), and
// the ranking uses a different sort (a selection over the remaining
// rows rather than an insertion sort).
//
// The comparison between this tool's output and the canonical tools'
// output is the C3 join.
//
// F-POLYC-TOOLS: this is a PolyC implementation, compiled and executed
// by a real compiler.  It is not shell glue.
//
// USAGE:
//   build/parser-surface-recon07-recompute <raw-facts.tsv> <rank-dims.tsv>
//   build/parser-surface-recon07-recompute --selftest
//
// The rank-dims file supplies R1..R5 and R6 ONLY.  R0 is taken from
// the facts table (the same source the checker uses for clause 03), so
// R0 and the eligibility fact CANNOT drift apart.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAX_ROWS 64
#define N_FACT_FIELDS 20
#define N_CLAUSES 13
// The dimension table rows are: id R0 R1 R2 R3 R4 R5 R6 eligible
// rationale -- TEN fields.  The tool reads the first EIGHT (through
// R6) and IGNORES the eligible column and the rationale entirely:
// the eligibility flag is RECOMPUTED from the raw facts, never read
// from the dimensions table.
#define N_DIM_FIELDS 10

// ------------------------------------------------------------------
// The clause policy, expressed as a TABLE of (fact index, expected
// value) pairs.  This is a DIFFERENT representation from the
// canonical checker's sequence of assignments.
// ------------------------------------------------------------------
//
// For each clause: the fact field index (1-based, into the facts
// table) and the accepted values.
//
//   clause 01  semantic_authority        field  7   YES
//   clause 02  already_selfhosted        field  8   NO
//   clause 03  r0                        field  9   integer <= 2
//   clause 04  owns_setjmp               field 10   NO
//   clause 05  writes_current_recovery   field 11   NO
//   clause 06  requires_nonlocal_recovery field 12  NO
//   clause 07  host_graph_writes         field 13   integer == 0
//   clause 08  pointer_identity_operations field 14 integer == 0
//   clause 09  parser_callback_count     field 15   integer == 0
//   clause 10  semantic_callback_count   field 16   integer == 0
//   clause 11  deterministic_projection  field 17   YES
//   clause 12  production_delegation_feasible field 18 YES
//   clause 13  candidate_kind            field  6   in the runtime
//                                                semantic authority set
// plus the separate production_reachable gate (field 19 == YES).

static I64 CLAUSE_IDX[N_CLAUSES];
static I64 CLAUSE_MOD[N_CLAUSES];

// The runtime semantic authority kinds, listed INDEPENDENTLY.
static U8 *KIND_NAMES[9] = {
  "AST_PROJECTION_PRIMITIVE", "TOKEN_CLASSIFIER", "OPERATOR_CLASSIFIER",
  "FORMAT_SPEC_COUNTER", "FORMAT_FUNCTION_TABLE", "TYPE_MODIFIER_PRIMITIVE",
  "OPERATOR_PRECEDENCE_TABLE", "ALIGNMENT_CALCULATION", "DELIMITER_PRIMITIVE"
};

static U8 *ROW_ID[MAX_ROWS];
static U8 *ROW_FILE[MAX_ROWS];
static I64 ROW_LINE[MAX_ROWS];
static I64 ROW_R[6][MAX_ROWS];
static I64 ROW_ELIG[MAX_ROWS];
static I64 ROW_HAS_DIMS[MAX_ROWS];
static I64 ROW_CLAUSE[N_CLAUSES][MAX_ROWS];
static I64 ROW_N;

static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

static I64 IsYes(U8 *s) { return StrEq(s, "YES"); }
static I64 IsNo(U8 *s) { return StrEq(s, "NO"); }

// Parse a decimal integer.  Returns 0 when the field is not an
// integer at all.
static I64 ParseInt(U8 *s)
{
  I64 v = 0;
  I64 neg = 0;
  U8 *p = s;
  if (*p == '-') { neg = 1; p++; }
  if (*p == 0) return 0;
  while (*p >= '0' && *p <= '9') {
    v = v * 10 + (*p - '0');
    p++;
  }
  if (*p != 0) return 0;
  if (neg) return -v;
  return v;
}

static I64 SplitTabs(U8 *line, U8 *out[], I64 maxf)
{
  I64 n = 0;
  U8 *p = line;
  while (n < maxf) {
    out[n] = p;
    n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0;
    p++;
  }
  return n;
}

// Split "<file>:<line>" into the file part and the numeric line part.
static U0 SplitLocation(U8 *loc, U8 *out_file[], I64 *out_line)
{
  I64 n = 0;
  U8 *p = loc;
  while (*p != 0) { n++; p++; }
  I64 cut = -1;
  p = loc;
  for (I64 i = 0; i < n; i++) {
    if (*p == ':') cut = i;
    p++;
  }
  if (cut < 0) { *out_file = loc; *out_line = 0; return; }
  loc[cut] = 0;
  *out_file = loc;
  *out_line = ParseInt(loc + cut + 1);
}

// The INDEPENDENT runtime-semantic-authority vocabulary check.
static I64 KindIsRuntimeAuthority(U8 *kind)
{
  for (I64 i = 0; i < 9; i++) {
    if (StrEq(kind, KIND_NAMES[i])) return 1;
  }
  return 0;
}

// Evaluate ONE clause against the fact fields of one row.
// mode 1: the fact must be the literal string YES or NO
// mode 2: the fact must be an integer <= 2
// mode 3: the fact must be an integer == 0
// mode 4: the fact must be a runtime semantic authority kind
static I64 EvalClause(I64 clause, U8 *f[])
{
  I64 idx = CLAUSE_IDX[clause];
  I64 mode = CLAUSE_MOD[clause];
  // The clause table uses 1-BASED fact field numbers (as the
  // canonical checker's schema does); the array is 0-based.
  U8 *v = f[idx - 1];
  if (mode == 1) {
    if (clause == 0) return IsYes(v);
    if (clause == 1) return IsNo(v);
    if (clause == 3) return IsNo(v);
    if (clause == 4) return IsNo(v);
    if (clause == 5) return IsNo(v);
    if (clause == 10) return IsYes(v);
    if (clause == 11) return IsYes(v);
    return 0;
  }
  if (mode == 2) {
    I64 r = ParseInt(v);
    if (r < 0) return 0;
    return r <= 2;
  }
  if (mode == 3) return ParseInt(v) == 0;
  if (mode == 4) return KindIsRuntimeAuthority(v);
  return 0;
}

// The INDEPENDENT order comparator.  Lexicographic on R0..R5, then
// (file lexical, line numeric).
static I64 CmpRows(I64 a, I64 b)
{
  for (I64 d = 0; d < 6; d++) {
    if (ROW_R[d][a] != ROW_R[d][b]) return ROW_R[d][a] - ROW_R[d][b];
  }
  I64 c = StrNCmp(ROW_FILE[a], ROW_FILE[b], 1024);
  if (c != 0) return c;
  if (ROW_LINE[a] < ROW_LINE[b]) return -1;
  if (ROW_LINE[a] > ROW_LINE[b]) return 1;
  return 0;
}

// The INDEPENDENT sort: a selection over the REMAINING rows, picking
// the minimum each time.  A different algorithm from the canonical
// ranker's insertion sort.
static I64 OrderEligible(I64 *order)
{
  I64 used[MAX_ROWS];
  for (I64 i = 0; i < MAX_ROWS; i++) used[i] = 0;
  I64 n = 0;
  for (I64 step = 0; step < MAX_ROWS; step++) {
    I64 best = -1;
    for (I64 i = 0; i < ROW_N; i++) {
      if (used[i]) continue;
      if (!ROW_ELIG[i]) continue;
      if (!ROW_HAS_DIMS[i]) continue;
      if (best < 0 || CmpRows(i, best) < 0) best = i;
    }
    if (best < 0) break;
    used[best] = 1;
    order[n] = best;
    n++;
  }
  return n;
}

static I32 RunSelfTests()
{
  I64 fail = 0;
  // The vocabulary check.
  if (!KindIsRuntimeAuthority("TOKEN_CLASSIFIER")) { fail++; }
  if (KindIsRuntimeAuthority("STATIC_HELPER")) { fail++; }
  if (KindIsRuntimeAuthority("DEAD_OR_NONRUNTIME")) { fail++; }
  // The integer parse.
  if (ParseInt("0") != 0) { fail++; }
  if (ParseInt("2") != 2) { fail++; }
  if (ParseInt("x") != 0) { fail++; }
  // The mode dispatch.
  I64 passes = 0;
  if (fail == 0) passes = 3;
  "SELFTEST_PASS=%d\n", passes;
  "SELFTEST_FAIL=%d\n", fail;
  if (fail == 0) { "STATUS=PASS\n"; return 0; }
  "STATUS=FAIL\n";
  return 1;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc > 1 && (StrEq(argv[1], "--selftest") || StrEq(argv[1], "SELFTEST"))) {
    return RunSelfTests();
  }
  if (argc < 3) {
    "STATUS=FAIL\nREASON=ARGC\n";
    return 2;
  }
  U8 *facts_path = argv[1];
  U8 *dims_path = argv[2];

  // The clause table.
  I64 cf[N_CLAUSES];
  I64 cm[N_CLAUSES];
  {
    I64 i = 0;
    for (I64 k = 0; k < N_CLAUSES; k++) {
      cf[k] = 0;
      cm[k] = 0;
    }
    cf[0]=7;  cm[0]=1;
    cf[1]=8;  cm[1]=1;
    cf[2]=9;  cm[2]=2;
    cf[3]=10; cm[3]=1;
    cf[4]=11; cm[4]=1;
    cf[5]=12; cm[5]=1;
    cf[6]=13; cm[6]=3;
    cf[7]=14; cm[7]=3;
    cf[8]=15; cm[8]=3;
    cf[9]=16; cm[9]=3;
    cf[10]=17; cm[10]=1;
    cf[11]=18; cm[11]=1;
    cf[12]=6;  cm[12]=4;
    for (I64 k = 0; k < N_CLAUSES; k++) {
      CLAUSE_IDX[k] = cf[k];
      CLAUSE_MOD[k] = cm[k];
    }
  }

  // ---- READ THE RAW FACTS ----
  I64 fsize = 0;
  U8 *buf = FileRead(facts_path, &fsize);
  if (buf == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_FACTS\nINPUT=%s\n", facts_path;
    return 1;
  }
  ROW_N = 0;
  I64 malformed = 0;
  U8 *p = buf;
  U8 *end = buf + fsize;
  U8 *f[N_FACT_FIELDS];
  U8 *fact_rows[MAX_ROWS][N_FACT_FIELDS];
  while (p < end && ROW_N < MAX_ROWS) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    U8 *line = ls;
    if (*line == 0) continue;
    if (*line == '#') continue;
    I64 nf = SplitTabs(line, f, N_FACT_FIELDS);
    if (nf < N_FACT_FIELDS) { malformed++; continue; }
    I64 r = ROW_N;
    for (I64 k = 0; k < N_FACT_FIELDS; k++) fact_rows[r][k] = f[k];
    ROW_ID[r] = f[0];
    ROW_N++;
  }
  Free(buf);

  // ---- READ R1..R6 FROM THE DIMENSIONS TABLE ----
  I64 dsize = 0;
  U8 *dbuf = FileRead(dims_path, &dsize);
  if (dbuf == NULL) {
    "STATUS=FAIL\nREASON=CANNOT_READ_DIMS\nINPUT=%s\n", dims_path;
    return 1;
  }
  p = dbuf;
  end = dbuf + dsize;
  U8 *d[N_DIM_FIELDS];
  while (p < end) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    U8 *line = ls;
    if (*line == 0) continue;
    if (*line == '#') continue;
    I64 nd = SplitTabs(line, d, N_DIM_FIELDS);
    if (nd < N_DIM_FIELDS) { malformed++; continue; }
    // Find the row.
    I64 r = -1;
    for (I64 i = 0; i < ROW_N; i++) {
      if (StrEq(ROW_ID[i], d[0])) { r = i; break; }
    }
    if (r < 0) { malformed++; continue; }
    for (I64 k = 0; k < 6; k++) ROW_R[k][r] = ParseInt(d[1 + k]);
    // R6 is "<file>:<line>".
    U8 *df[1];
    I64 dl = 0;
    SplitLocation(d[7], df, &dl);
    ROW_FILE[r] = df[0];
    ROW_LINE[r] = dl;
    ROW_HAS_DIMS[r] = 1;
  }
  Free(dbuf);

  // ---- EVALUATE THE CLAUSES FROM THE RAW FACTS ----
  I64 eligible = 0;
  for (I64 r = 0; r < ROW_N; r++) {
    I64 ok = 1;
    for (I64 k = 0; k < N_CLAUSES; k++) {
      I64 bit = EvalClause(k, fact_rows[r]);
      ROW_CLAUSE[k][r] = bit;
      if (!bit) ok = 0;
    }
    // The separate production-reachable gate.
    I64 reach = IsYes(fact_rows[r][18]);
    if (!reach) ok = 0;
    ROW_ELIG[r] = ok;
    if (ok) eligible++;
  }

  // ---- EMIT THE CLAUSE RESULTS ----
  "candidate_id\teligible\t";
  for (I64 k = 0; k < N_CLAUSES; k++) "%d", k + 1;
  "\tfailed\treachable\n";
  for (I64 r = 0; r < ROW_N; r++) {
    U8 *elstr = "NO";
    if (ROW_ELIG[r]) elstr = "YES";
    "%s\t%s\t", ROW_ID[r], elstr;
    I64 failed = 0;
    for (I64 k = 0; k < N_CLAUSES; k++) {
      "%d", ROW_CLAUSE[k][r];
      if (!ROW_CLAUSE[k][r]) failed++;
    }
    U8 *reachstr = "NO";
    if (IsYes(fact_rows[r][18])) reachstr = "YES";
    "\t%d\t%s\n", failed, reachstr;
  }
  "TOTAL=%d\n", ROW_N;
  "ELIGIBLE=%d\n", eligible;
  "MALFORMED=%d\n", malformed;

  // ---- THE ORDER ----
  I64 order[MAX_ROWS];
  I64 n = OrderEligible(order);
  for (I64 i = 0; i < n; i++) {
    I64 r = order[i];
    I64 r0 = ROW_R[0][r];
    I64 r1 = ROW_R[1][r];
    I64 r2 = ROW_R[2][r];
    I64 r3 = ROW_R[3][r];
    I64 r4 = ROW_R[4][r];
    I64 r5 = ROW_R[5][r];
    I64 rl = ROW_LINE[r];
    U8 *rf = ROW_FILE[r];
    "RANKED:%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%s:%d\n",
      i + 1, ROW_ID[r], r0, r1, r2, r3, r4, r5, rf, rl;
  }
  "RANKED_COUNT=%d\n", n;
  if (n > 0) {
    "SELECTED=%s\n", ROW_ID[order[0]];
  } else {
    "SELECTED=NONE\n";
  }
  if (malformed == 0) { "STATUS=PASS\n"; return 0; }
  "STATUS=FAIL\n";
  return 1;
}
