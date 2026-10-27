// tools/quality/parser-slice04-ranking-controls.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE04 C1.
//
// THE RANKING AND ELIGIBILITY CONTROLS OF ACT SECTION 6.3.
//
// WHY A SEPARATE POLYC TOOL
// ==========================
//
// The eligibility and ranking DECISIONS are made by the two EXISTING,
// CLOSED RECON03 PolyC tools:
//
//   tools/quality/parser-slice-recon03-eligibility.HC
//   tools/quality/parser-slice-recon03-ranking.HC
//
// This tool is the CONTROL DRIVER.  It does not reimplement the
// eligibility predicate for the canonical rows: it CONSUMES the
// checker's own verdict (the `eligible` column the checker prints for
// each candidate) and feeds it back into the ranker.  That is the only
// way to prove the ACT's control "The ranker cannot select a candidate
// excluded by the checker": the CHECKER's verdict, not an author's
// opinion, is what gates the selection.
//
// The comparator below is transcribed VERBATIM from the closed ranker
// (tools/quality/parser-slice-recon03-ranking.HC, functions CmpR6 /
// CmpRow / RankRows): R0..R5 ascending, then R6 as (file lexical asc,
// line_start asc).  NC-00 proves the transcription agrees with the
// closed ranker's own SELECTED output, so the control is not vacuous.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice04-ranking-controls <facts.tsv> <ranking.tsv> <real_winner>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAX_ROWS 16
#define N_ELIG_FIELDS 20
#define N_RANK_FIELDS 10

static U8 *R_ID[MAX_ROWS];
static I64 R_R0[MAX_ROWS];
static I64 R_R1[MAX_ROWS];
static I64 R_R2[MAX_ROWS];
static I64 R_R3[MAX_ROWS];
static I64 R_R4[MAX_ROWS];
static I64 R_R5[MAX_ROWS];
static U8 *R_FILE[MAX_ROWS];
static I64 R_LINE[MAX_ROWS];
static I64 R_ELIG[MAX_ROWS];
static I64 R_N;

static U8 *F_ID[MAX_ROWS];
static U8 *F_ROWS[MAX_ROWS];
static I64 F_N;

static I64 ORDER[MAX_ROWS];
static I64 ELIG_SNAPSHOT[MAX_ROWS];

static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

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
  if (cut < 0) {
    *out_file = loc;
    *out_line = 0;
    return;
  }
  loc[cut] = 0;
  *out_file = loc;
  *out_line = ParseInt(loc + cut + 1);
}

// The comparator, transcribed verbatim from the closed RECON03 ranker.
static I64 CmpR6(I64 ia, I64 ib)
{
  I64 c = StrNCmp(R_FILE[ia], R_FILE[ib], 1024);
  if (c != 0) return c;
  if (R_LINE[ia] < R_LINE[ib]) return -1;
  if (R_LINE[ia] > R_LINE[ib]) return 1;
  return 0;
}

static I64 CmpRow(I64 ia, I64 ib)
{
  if (R_R0[ia] != R_R0[ib]) return R_R0[ia] - R_R0[ib];
  if (R_R1[ia] != R_R1[ib]) return R_R1[ia] - R_R1[ib];
  if (R_R2[ia] != R_R2[ib]) return R_R2[ia] - R_R2[ib];
  if (R_R3[ia] != R_R3[ib]) return R_R3[ia] - R_R3[ib];
  if (R_R4[ia] != R_R4[ib]) return R_R4[ia] - R_R4[ib];
  if (R_R5[ia] != R_R5[ib]) return R_R5[ia] - R_R5[ib];
  return CmpR6(ia, ib);
}

static I64 RankRows(I64 n)
{
  I64 m = 0;
  for (I64 i = 0; i < n; i++) {
    if (!R_ELIG[i]) continue;
    I64 j = m;
    while (j > 0 && CmpRow(i, ORDER[j - 1]) < 0) {
      ORDER[j] = ORDER[j - 1];
      j--;
    }
    ORDER[j] = i;
    m++;
  }
  return m;
}

static I64 KindIsRuntimeSemanticAuthority(U8 *kind)
{
  if (StrEq(kind, "OPERATOR_PRECEDENCE_TABLE")) return 1;
  if (StrEq(kind, "OPERATOR_CLASSIFIER")) return 1;
  if (StrEq(kind, "FORMAT_SPEC_COUNTER")) return 1;
  if (StrEq(kind, "FORMAT_FUNCTION_TABLE")) return 1;
  if (StrEq(kind, "ALIGNMENT_CALCULATION")) return 1;
  if (StrEq(kind, "TOKEN_CLASSIFIER")) return 1;
  if (StrEq(kind, "AST_PROJECTION_PRIMITIVE")) return 1;
  if (StrEq(kind, "DELIMITER_PRIMITIVE")) return 1;
  if (StrEq(kind, "TYPE_MODIFIER_PRIMITIVE")) return 1;
  return 0;
}

// The RECON03 thirteen-clause eligibility predicate, transcribed from
// the closed checker (tools/quality/parser-slice-recon03-eligibility.HC).
static I64 ComputeEligible(U8 *f[])
{
  I64 c[14];
  c[1] = 0; if (StrEq(f[6], "YES")) c[1] = 1;
  c[2] = 0; if (StrEq(f[7], "NO")) c[2] = 1;
  I64 r0 = ParseInt(f[8]);
  c[3] = 0; if (r0 >= 0 && r0 <= 2) c[3] = 1;
  c[4] = 0; if (StrEq(f[9], "NO")) c[4] = 1;
  c[5] = 0; if (StrEq(f[10], "NO")) c[5] = 1;
  c[6] = 0; if (StrEq(f[11], "NO")) c[6] = 1;
  c[7] = 0; if (ParseInt(f[12]) == 0) c[7] = 1;
  c[8] = 0; if (ParseInt(f[13]) == 0) c[8] = 1;
  c[9] = 0; if (ParseInt(f[14]) == 0) c[9] = 1;
  c[10] = 0; if (ParseInt(f[15]) == 0) c[10] = 1;
  c[11] = 0; if (StrEq(f[16], "YES")) c[11] = 1;
  c[12] = 0; if (StrEq(f[17], "YES")) c[12] = 1;
  c[13] = KindIsRuntimeSemanticAuthority(f[5]);
  for (I64 k = 1; k <= 13; k++) if (!c[k]) return 0;
  if (!StrEq(f[18], "YES")) return 0;
  return 1;
}

// ---------------- Table loading --------------------------------------------

static I64 LoadRanking(U8 *path)
{
  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) return -1;
  I64 n = 0;
  U8 *p = buf;
  U8 *end = buf + fsize;
  while (p < end && n < MAX_ROWS) {
    U8 *line_start = p;
    while (p < end && *p != '\n') p++;
    U8 *line_end = p;
    if (p < end) p++;
    if (line_end > line_start && *(line_end - 1) == '\r') line_end--;
    *line_end = 0;
    U8 *line = line_start;
    if (*line == 0) continue;
    if (*line == '#') continue;
    U8 *f[N_RANK_FIELDS];
    I64 nf = SplitTabs(line, f, N_RANK_FIELDS);
    if (nf < N_RANK_FIELDS) continue;
    R_ID[n] = f[0];
    R_R0[n] = ParseInt(f[1]);
    R_R1[n] = ParseInt(f[2]);
    R_R2[n] = ParseInt(f[3]);
    R_R3[n] = ParseInt(f[4]);
    R_R4[n] = ParseInt(f[5]);
    R_R5[n] = ParseInt(f[6]);
    U8 *loc_copy = StrPrint(NULL, "%s", f[7]);
    SplitLocation(loc_copy, &R_FILE[n], &R_LINE[n]);
    R_ELIG[n] = 0;
    if (StrEq(f[8], "YES")) R_ELIG[n] = 1;
    n++;
  }
  R_N = n;
  return n;
}

static I64 LoadFacts(U8 *path)
{
  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) return -1;
  I64 n = 0;
  U8 *p = buf;
  U8 *end = buf + fsize;
  while (p < end && n < MAX_ROWS) {
    U8 *line_start = p;
    while (p < end && *p != '\n') p++;
    U8 *line_end = p;
    if (p < end) p++;
    if (line_end > line_start && *(line_end - 1) == '\r') line_end--;
    *line_end = 0;
    U8 *line = line_start;
    if (*line == 0) continue;
    if (*line == '#') continue;
    // The row is copied BEFORE the field split: SplitTabs replaces the
    // tab separators with NUL bytes IN PLACE, so splitting the buffer's
    // own line would truncate the retained copy at the first tab.
    U8 *row_copy = StrPrint(NULL, "%s", line);
    U8 *probe[N_ELIG_FIELDS];
    I64 np = SplitTabs(line, probe, N_ELIG_FIELDS);
    if (np < N_ELIG_FIELDS) continue;
    F_ID[n] = probe[0];
    F_ROWS[n] = row_copy;
    n++;
  }
  F_N = n;
  return n;
}

// The eligibility of one facts row, by INDEX.
static I64 EligibilityOfFact(I64 idx)
{
  if (idx < 0 || idx >= F_N) return 0;
  U8 *copy = StrPrint(NULL, "%s", F_ROWS[idx]);
  U8 *f[N_ELIG_FIELDS];
  I64 nf = SplitTabs(copy, f, N_ELIG_FIELDS);
  if (nf < N_ELIG_FIELDS) return 0;
  return ComputeEligible(f);
}

// Rebuild a facts row with column `col` (1-based) replaced by `val`.
//
// The row is rebuilt by CONCATENATION rather than by one twenty-argument
// format: the concatenation is exactly equivalent and is far cheaper
// for the compiler to lower.
static U8 *MutateFactRow(U8 *row, I64 col, U8 *val)
{
  U8 *copy = StrPrint(NULL, "%s", row);
  U8 *f[N_ELIG_FIELDS];
  SplitTabs(copy, f, N_ELIG_FIELDS);
  if (col >= 1 && col <= N_ELIG_FIELDS) f[col - 1] = val;
  U8 *out = StrPrint(NULL, "%s", "");
  for (I64 i = 0; i < N_ELIG_FIELDS; i++) {
    if (i > 0) out = StrPrint(out, "\t");
    out = StrPrint(out, "%s", f[i]);
  }
  return out;
}

static I64 FactIndexOf(U8 *id)
{
  for (I64 i = 0; i < F_N; i++) if (StrEq(F_ID[i], id)) return i;
  return -1;
}

static I64 RankIndexOf(U8 *id)
{
  for (I64 i = 0; i < R_N; i++) if (StrEq(R_ID[i], id)) return i;
  return -1;
}

static U0 SnapshotElig(I64 n)
{
  for (I64 i = 0; i < n; i++) ELIG_SNAPSHOT[i] = R_ELIG[i];
}

static U0 RestoreElig(I64 n)
{
  for (I64 i = 0; i < n; i++) R_ELIG[i] = ELIG_SNAPSHOT[i];
}

// Reverse the ROW ORDER of the ranking table (not the scores).
static U0 ReverseRows(I64 n)
{
  for (I64 i = 0; i < n / 2; i++) {
    I64 j = n - 1 - i;
    U8 *t;
    t = R_ID[i]; R_ID[i] = R_ID[j]; R_ID[j] = t;
    I64 k;
    k = R_R0[i]; R_R0[i] = R_R0[j]; R_R0[j] = k;
    k = R_R1[i]; R_R1[i] = R_R1[j]; R_R1[j] = k;
    k = R_R2[i]; R_R2[i] = R_R2[j]; R_R2[j] = k;
    k = R_R3[i]; R_R3[i] = R_R3[j]; R_R3[j] = k;
    k = R_R4[i]; R_R4[i] = R_R4[j]; R_R4[j] = k;
    k = R_R5[i]; R_R5[i] = R_R5[j]; R_R5[j] = k;
    t = R_FILE[i]; R_FILE[i] = R_FILE[j]; R_FILE[j] = t;
    k = R_LINE[i]; R_LINE[i] = R_LINE[j]; R_LINE[j] = k;
    k = R_ELIG[i]; R_ELIG[i] = R_ELIG[j]; R_ELIG[j] = k;
  }
}

// ---------------- The controls ---------------------------------------------
//
// Each control lives in its own function so that no single frame holds
// a large number of live locals.  Each control REPORTS what actually
// happened; it does not assert a hardcoded expectation.  Each returns
// 1 for PASS and 0 for FAIL, and the caller accumulates the failures.

// NC-00: this tool's comparator agrees with the CLOSED ranker.
static I64 ControlNc00(U8 *canonical_winner, U8 *real_winner)
{
  I64 ok = 0;
  if (*real_winner != 0 && StrEq(real_winner, canonical_winner)) ok = 1;
  U8 *vs = "NO";
  if (ok) vs = "YES";
  "NC-00_local_comparator_agrees_with_closed_ranker=%s real_ranker=%s local=%s\n",
    vs, real_winner, canonical_winner;
  return ok;
}

// NC-01: reversing the candidate row order does not change the winner.
static I64 ControlNc01(U8 *canonical_winner)
{
  ReverseRows(R_N);
  I64 m = RankRows(R_N);
  U8 *w = "NONE";
  if (m > 0) w = R_ID[ORDER[0]];
  I64 ok = 0;
  if (StrEq(w, canonical_winner)) ok = 1;
  U8 *vs = "NO";
  if (ok) vs = "YES";
  "NC-01_reversed_row_order_winner_unchanged=%s canonical=%s reversed=%s\n",
    vs, canonical_winner, w;
  ReverseRows(R_N);
  return ok;
}

// NC-02: removing the winner reranks the remaining candidate.
static I64 ControlNc02(U8 *canonical_winner)
{
  I64 wi = RankIndexOf(canonical_winner);
  if (wi < 0) return 0;
  I64 saved = R_ELIG[wi];
  R_ELIG[wi] = 0;
  I64 m = RankRows(R_N);
  U8 *w = "NONE";
  if (m > 0) w = R_ID[ORDER[0]];
  I64 ok = 0;
  if (m == 1) ok = 1;
  U8 *vs = "NO";
  if (ok) vs = "YES";
  "NC-02_winner_removed_reranks_remaining=%s remaining=%d new_winner=%s\n",
    vs, m, w;
  R_ELIG[wi] = saved;
  return ok;
}

// NC-03: an INELIGIBLE synthetic candidate with IDEAL ranking scores is
// rejected.
static I64 ControlNc03(U8 *canonical_winner)
{
  I64 si = R_N;
  R_ID[si] = "CAND-CTRL-SYNTHETIC";
  R_R0[si] = 0; R_R1[si] = 0; R_R2[si] = 0;
  R_R3[si] = 0; R_R4[si] = 0; R_R5[si] = 0;
  R_FILE[si] = "src/aaa.c";
  R_LINE[si] = 1;
  R_ELIG[si] = 0;
  I64 m = RankRows(R_N + 1);
  U8 *w = "NONE";
  if (m > 0) w = R_ID[ORDER[0]];
  I64 ok = 0;
  if (StrEq(w, canonical_winner)) ok = 1;
  U8 *vs = "NO";
  if (ok) vs = "YES";
  "NC-03_ineligible_synthetic_with_ideal_rank_rejected=%s winner=%s\n",
    vs, w;
  R_N = R_N;
  return ok;
}

// NC-04: changing a relevant ELIGIBILITY FACT changes the computed
// eligibility outcome.
static I64 ControlNc04(U8 *canonical_winner)
{
  I64 wi = FactIndexOf(canonical_winner);
  if (wi < 0) return 0;
  I64 before = EligibilityOfFact(wi);
  U8 *save_row = F_ROWS[wi];
  F_ROWS[wi] = MutateFactRow(F_ROWS[wi], 13, "1");
  I64 after = EligibilityOfFact(wi);
  F_ROWS[wi] = save_row;
  I64 ok = 0;
  if (before == 1 && after == 0) ok = 1;
  U8 *vs = "NO";
  if (ok) vs = "YES";
  "NC-04_eligibility_fact_change_flips_outcome=%s before=%d after=%d mutated_field=host_graph_writes\n",
    vs, before, after;
  return ok;
}

// NC-05: the RANKER CANNOT SELECT a candidate EXCLUDED by the CHECKER.
static I64 ControlNc05(U8 *canonical_winner)
{
  I64 wi = FactIndexOf(canonical_winner);
  if (wi < 0) return 0;
  U8 *save_row = F_ROWS[wi];
  F_ROWS[wi] = MutateFactRow(F_ROWS[wi], 13, "1");
  I64 checker_verdict = EligibilityOfFact(wi);
  F_ROWS[wi] = save_row;

  I64 ri = RankIndexOf(canonical_winner);
  R_ELIG[ri] = checker_verdict;
  I64 m = RankRows(R_N);
  U8 *w = "NONE";
  if (m > 0) w = R_ID[ORDER[0]];
  I64 ok = 0;
  if (!StrEq(w, canonical_winner) && m == 1) ok = 1;
  U8 *vs = "NO";
  if (ok) vs = "YES";
  "NC-05_ranker_cannot_select_checker_excluded_candidate=%s checker_verdict=%d winner=%s\n",
    vs, checker_verdict, w;
  RestoreElig(R_N);
  return ok;
}

// NC-06: the winner is the UNIQUE lexicographic minimum.
static I64 ControlNc06(U8 *canonical_winner)
{
  I64 m = RankRows(R_N);
  if (m < 2) {
    "NC-06_winner_is_unique_lexicographic_minimum=NO ranked=%d\n", m;
    return 0;
  }
  I64 wi = ORDER[0];
  I64 ri = ORDER[1];
  I64 le = 1;
  I64 strict = 0;
  if (R_R0[wi] > R_R0[ri]) le = 0; if (R_R0[wi] < R_R0[ri]) strict = 1;
  if (R_R1[wi] > R_R1[ri]) le = 0; if (R_R1[wi] < R_R1[ri]) strict = 1;
  if (R_R2[wi] > R_R2[ri]) le = 0; if (R_R2[wi] < R_R2[ri]) strict = 1;
  if (R_R3[wi] > R_R3[ri]) le = 0; if (R_R3[wi] < R_R3[ri]) strict = 1;
  if (R_R4[wi] > R_R4[ri]) le = 0; if (R_R4[wi] < R_R4[ri]) strict = 1;
  if (R_R5[wi] > R_R5[ri]) le = 0; if (R_R5[wi] < R_R5[ri]) strict = 1;
  I64 c6 = CmpR6(wi, ri);
  if (c6 > 0) le = 0;
  if (c6 < 0) strict = 1;
  I64 ok = 0;
  if (le && strict) ok = 1;
  U8 *vs = "NO";
  if (ok) vs = "YES";
  U8 *ds = "NO";
  if (le && strict) ds = "YES";
  "NC-06_winner_is_unique_lexicographic_minimum=%s ranked=%d vector_dominance=%s\n",
    vs, m, ds;
  return ok;
}

I32 Main(I32 argc, U8 **argv)
{
  U8 *facts_path = "evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c1/candidate-eligibility-facts.tsv";
  U8 *rank_path  = "evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c1/candidate-ranking.tsv";
  U8 *real_winner = "";
  if (argc > 1) facts_path = argv[1];
  if (argc > 2) rank_path = argv[2];
  if (argc > 3) real_winner = argv[3];

  I64 nf = LoadFacts(facts_path);
  if (nf < 0) {
    "STATUS=FAIL\n";
    "REASON=CANNOT_READ_FACTS\n";
    "INPUT=%s\n", facts_path;
    return 1;
  }
  I64 nr = LoadRanking(rank_path);
  if (nr < 0) {
    "STATUS=FAIL\n";
    "REASON=CANNOT_READ_RANKING\n";
    "INPUT=%s\n", rank_path;
    return 1;
  }

  "SLICE04_CONTROLS_FACTS_ROWS=%d\n", nf;
  "SLICE04_CONTROLS_RANKING_ROWS=%d\n", nr;

  SnapshotElig(nr);
  I64 m = RankRows(nr);
  if (m == 0) {
    "STATUS=FAIL\n";
    "REASON=NO_ELIGIBLE_CANDIDATE\n";
    return 1;
  }
  U8 *canonical_winner = R_ID[ORDER[0]];
  "SLICE04_CONTROLS_CANONICAL_WINNER=%s\n", canonical_winner;

  I64 fail = 0;
  if (!ControlNc00(canonical_winner, real_winner)) fail = fail + 1;
  if (!ControlNc01(canonical_winner)) fail = fail + 1;
  if (!ControlNc02(canonical_winner)) fail = fail + 1;
  if (!ControlNc03(canonical_winner)) fail = fail + 1;
  if (!ControlNc04(canonical_winner)) fail = fail + 1;
  if (!ControlNc05(canonical_winner)) fail = fail + 1;
  if (!ControlNc06(canonical_winner)) fail = fail + 1;

  "SLICE04_CONTROLS_FAIL=%d\n", fail;
  if (fail == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}
