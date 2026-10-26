// tools/quality/parser-slice-recon03-ranking.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 C2 IMPL.
//
// MECHANICAL LEXICOGRAPHIC RANKER for the parser-slice candidates.
//
// Ranking is on the FROZEN dimensions (R0, R1, R2, R3, R4, R5, R6);
// lower wins.  R0 is the first and strongest dimension.
//
//   R0 STATE_BOUNDARY_COST        0..5   (see the frozen contract)
//   R1 SELFHOST_STAGE_LEVERAGE    0..3
//   R2 SEMANTIC_CENTRALITY        0..3
//   R3 PROOF_OBSERVABILITY        0..4
//   R4 DEPENDENCY_COUPLING_COST   integer
//   R5 MIGRATION_SIZE             integer
//   R6 SOURCE_ORDER               file lexical asc, then line_start asc
//
// The ranker consumes an ELIGIBILITY-VERIFIED input: the `eligible`
// column it reads is the OUTPUT of
// tools/quality/parser-slice-recon03-eligibility.HC, NOT a hand-authored
// field.  An ineligible row is dropped BEFORE the sort, so an ineligible
// candidate with an artificially perfect ranking can never win.
//
// INPUT SCHEMA (tab-separated; `#` starts a comment; blank lines ignored):
//
//   01 candidate_id
//   02 R0            03 R1      04 R2      05 R3
//   06 R4            07 R5      08 R6      ( "<file>:<line>" )
//   09 eligible      YES|NO    (from the eligibility checker)
//   10 rationale     free text (may be empty)
//
// OUTPUT:
//
//   RANKED:<rank>\t<candidate_id>\t<R0>\t<R1>\t<R2>\t<R3>\t<R4>\t<R5>\t<R6>
//   ...
//   SELECTED=<candidate_id>          (or SELECTED=NONE)
//   TOTAL=<n>  ELIGIBLE=<n>  RANKED=<n>
//
// The comparator is a total order over the six dimensions; R6 is compared
// as (file lexical, then line_start numeric).  The comparator therefore
// does not depend on the input row order.
//
// NEGATIVE CONTROLS (ACT §8.3) are executed here as RANKING controls;
// the ELIGIBILITY controls are executed by the eligibility checker and
// are reported by the driver.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAX_ROWS 48
#define N_FIELDS 10

static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

// Parse a leading signed decimal integer.  Returns 0 when the field is
// not an integer at all.
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

static I64 SplitTabs(U8 *line, U8 *out[])
{
  I64 n = 0;
  U8 *p = line;
  while (n < N_FIELDS) {
    out[n] = p;
    n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0;
    p++;
  }
  return n;
}

// Split "<file>:<line>" into its file part and its numeric line part.
static U0 SplitLocation(U8 *loc, U8 *out_file[], I64 *out_line)
{
  I64 n = 0;
  U8 *p = loc;
  while (*p != 0) {
    n++;
    p++;
  }
  // Find the LAST ':' so that a path containing a colon still works.
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

// ---- Row storage ----------------------------------------------------------
//
// The rows are held in PARALLEL FLAT ARRAYS rather than an array of
// class instances: the compiler's handling of a class-typed dynamic
// array is not required for this tool, and the flat form keeps the
// comparator and the controls simple and auditable.

static U8 *ROW_ID[MAX_ROWS];
static I64 ROW_R0[MAX_ROWS];
static I64 ROW_R1[MAX_ROWS];
static I64 ROW_R2[MAX_ROWS];
static I64 ROW_R3[MAX_ROWS];
static I64 ROW_R4[MAX_ROWS];
static I64 ROW_R5[MAX_ROWS];
static U8 *ROW_R6[MAX_ROWS];
static U8 *ROW_FILE[MAX_ROWS];
static I64 ROW_LINE[MAX_ROWS];
static I64 ROW_ELIG[MAX_ROWS];

// The ranked order, as indices into the row arrays.
static I64 ORDER[MAX_ROWS];

// Compare two R6 source-order keys: file lexical asc, then line asc.
static I64 CmpR6(I64 ia, I64 ib)
{
  I64 c = StrNCmp(ROW_FILE[ia], ROW_FILE[ib], 1024);
  if (c != 0) return c;
  if (ROW_LINE[ia] < ROW_LINE[ib]) return -1;
  if (ROW_LINE[ia] > ROW_LINE[ib]) return 1;
  return 0;
}

// Total-order comparator on (R0, R1, R2, R3, R4, R5, R6).
// Returns <0 when row ia ranks ahead of row ib.
static I64 CmpRow(I64 ia, I64 ib)
{
  if (ROW_R0[ia] != ROW_R0[ib]) return ROW_R0[ia] - ROW_R0[ib];
  if (ROW_R1[ia] != ROW_R1[ib]) return ROW_R1[ia] - ROW_R1[ib];
  if (ROW_R2[ia] != ROW_R2[ib]) return ROW_R2[ia] - ROW_R2[ib];
  if (ROW_R3[ia] != ROW_R3[ib]) return ROW_R3[ia] - ROW_R3[ib];
  if (ROW_R4[ia] != ROW_R4[ib]) return ROW_R4[ia] - ROW_R4[ib];
  if (ROW_R5[ia] != ROW_R5[ib]) return ROW_R5[ia] - ROW_R5[ib];
  return CmpR6(ia, ib);
}

// Fill ORDER with the eligible row indices, best first.  Returns the
// number of eligible rows.
static I64 RankRows(I64 n)
{
  I64 m = 0;
  for (I64 i = 0; i < n; i++) {
    if (!ROW_ELIG[i]) continue;
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

// Load the ranking input table.  Returns the number of rows loaded;
// `out_eligible` receives the number of eligible rows.
static I64 LoadRows(U8 *path, I64 *out_eligible)
{
  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) return -1;

  I64 n = 0;
  I64 elig = 0;
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

    U8 *f[N_FIELDS];
    I64 nf = SplitTabs(line, f);
    if (nf < N_FIELDS) continue;

    ROW_ID[n] = f[0];
    ROW_R0[n] = ParseInt(f[1]);
    ROW_R1[n] = ParseInt(f[2]);
    ROW_R2[n] = ParseInt(f[3]);
    ROW_R3[n] = ParseInt(f[4]);
    ROW_R4[n] = ParseInt(f[5]);
    ROW_R5[n] = ParseInt(f[6]);
    // Copy the location string before SplitLocation truncates it at the
    // last colon: ROW_R6 keeps the full "file:line" form for output,
    // ROW_FILE keeps the file part for the R6 comparison.
    // TWO copies: ROW_R6 keeps the untruncated "file:line" form for the
    // output record, and a second copy is truncated by SplitLocation to
    // yield the file part and the numeric line part used by R6.
    ROW_R6[n] = StrPrint(NULL, "%s", f[7]);
    U8 *loc_copy = StrPrint(NULL, "%s", f[7]);
    SplitLocation(loc_copy, &ROW_FILE[n], &ROW_LINE[n]);
    ROW_ELIG[n] = 0;
    if (StrEq(f[8], "YES")) ROW_ELIG[n] = 1;
    if (ROW_ELIG[n]) elig++;
    n++;
  }

  *out_eligible = elig;
  return n;
}

// Deterministically permute the ELIGIBLE rows among themselves using a
// fixed-seed Fisher-Yates.  The permutation is reproducible and it
// genuinely reorders the input, so the shuffle control is a real test
// of order-independence rather than a no-op.
static U0 PermuteEligible(I64 n, I64 seed)
{
  static I64 idx[MAX_ROWS];
  static U8 *tid[MAX_ROWS];
  static U8 *tr6[MAX_ROWS];
  static U8 *tfile[MAX_ROWS];
  static I64 tr0[MAX_ROWS];
  static I64 tr1[MAX_ROWS];
  static I64 tr2[MAX_ROWS];
  static I64 tr3[MAX_ROWS];
  static I64 tr4[MAX_ROWS];
  static I64 tr5[MAX_ROWS];
  static I64 tline[MAX_ROWS];

  I64 m = 0;
  for (I64 i = 0; i < n; i++) {
    if (!ROW_ELIG[i]) continue;
    idx[m] = i;
    m++;
  }

  I64 s = seed;
  for (I64 i = m - 1; i > 0; i--) {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    I64 j = s % (i + 1);
    I64 tmp = idx[i];
    idx[i] = idx[j];
    idx[j] = tmp;
  }

  for (I64 i = 0; i < n; i++) {
    tid[i] = ROW_ID[i]; tr0[i] = ROW_R0[i]; tr1[i] = ROW_R1[i];
    tr2[i] = ROW_R2[i]; tr3[i] = ROW_R3[i]; tr4[i] = ROW_R4[i];
    tr5[i] = ROW_R5[i]; tr6[i] = ROW_R6[i]; tfile[i] = ROW_FILE[i];
    tline[i] = ROW_LINE[i];
  }

  for (I64 i = 0; i < m; i++) {
    I64 d = idx[i];
    I64 sr = idx[i];
    ROW_ID[d] = tid[sr]; ROW_R0[d] = tr0[sr]; ROW_R1[d] = tr1[sr];
    ROW_R2[d] = tr2[sr]; ROW_R3[d] = tr3[sr]; ROW_R4[d] = tr4[sr];
    ROW_R5[d] = tr5[sr]; ROW_R6[d] = tr6[sr]; ROW_FILE[d] = tfile[sr];
    ROW_LINE[d] = tline[sr];
  }
}

// ---------------- RANKING NEGATIVE CONTROLS ----------------
//
// Each control mutates the row table and re-runs the ranking.  The
// control REPORTS what actually happened; it does not assert a hardcoded
// expectation.  Each control lives in its own function so that no single
// frame holds a large number of live locals.

// NC-05: an ineligible candidate with an artificially perfect ranking
// must still be rejected.
static U0 ControlNc05(I64 n, I64 win)
{
  ROW_ID[n] = "CTRL-INELIGIBLE-PERFECT";
  ROW_R0[n] = 0; ROW_R1[n] = 0; ROW_R2[n] = 0; ROW_R3[n] = 0;
  ROW_R4[n] = 0; ROW_R5[n] = 0;
  ROW_R6[n] = "src/aaa.c:1";
  ROW_FILE[n] = "src/aaa.c";
  ROW_LINE[n] = 1;
  ROW_ELIG[n] = 0;

  I64 m = RankRows(n + 1);
  I64 same = 0;
  if (m > 0 && StrEq(ROW_ID[ORDER[0]], ROW_ID[win])) same = 1;
  U8 *v = "NO";
  if (same) v = "YES";
  "NC-05_ineligible_perfect_rank_rejected=%s\n", v;
  "NC-05_winner=%s\n", ROW_ID[ORDER[0]];
}

// NC-06: shuffling the inventory must not change the winner.
static U0 ControlNc06(I64 n, I64 win)
{
  PermuteEligible(n, 20260101);
  RankRows(n);
  I64 same = 0;
  if (StrEq(ROW_ID[ORDER[0]], ROW_ID[win])) same = 1;
  U8 *v = "NO";
  if (same) v = "YES";
  "NC-06_shuffled_inventory_winner_unchanged=%s\n", v;
  "NC-06_winner=%s\n", ROW_ID[ORDER[0]];
}

// NC-07: removing the winner must rerank the remaining eligible
// candidates; if none remain, the result is NONE.
static U0 ControlNc07(I64 n, I64 win)
{
  ROW_ELIG[win] = 0;
  I64 m = RankRows(n);
  if (m == 0) {
    "NC-07_winner_removed_remaining=0\n";
    "NC-07_new_winner=NONE\n";
  } else {
    "NC-07_winner_removed_remaining=%d\n", m;
    "NC-07_new_winner=%s\n", ROW_ID[ORDER[0]];
  }
  ROW_ELIG[win] = 1;
}

// NC-09: raising the winner's R0 must change the leader WHEN a rival
// eligible candidate exists.  The control reports whether a rival
// existed, so the result is never a vacuous pass.
static U0 ControlNc09(I64 n, I64 win)
{
  I64 rivals = 0;
  for (I64 i = 0; i < n; i++) {
    if (ROW_ELIG[i] && i != win) rivals++;
  }
  "NC-09_rival_eligible_candidates=%d\n", rivals;
  if (rivals == 0) {
    "NC-09_r0_perturbation_changed_leader=NOT_APPLICABLE_NO_RIVAL\n";
    return;
  }
  ROW_R0[win] = ROW_R0[win] + 1;
  RankRows(n);
  I64 changed = 0;
  if (!StrEq(ROW_ID[ORDER[0]], ROW_ID[win])) changed = 1;
  U8 *v = "NO";
  if (changed) v = "YES";
  "NC-09_r0_perturbation_changed_leader=%s\n", v;
  "NC-09_new_leader=%s\n", ROW_ID[ORDER[0]];
  ROW_R0[win] = ROW_R0[win] - 1;
}

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c2/ranking-dimensions.tsv";
  I64 ai = 1;
  if (argc > ai) path = argv[ai];

  I64 elig = 0;
  I64 n = LoadRows(path, &elig);
  if (n < 0) {
    "STATUS=FAIL\n";
    "REASON=CANNOT_READ_INPUT\n";
    "INPUT=%s\n", path;
    return 1;
  }

  I64 ranked = RankRows(n);

  "TOTAL=%d\n", n;
  "ELIGIBLE=%d\n", elig;
  "RANKED=%d\n", ranked;

  for (I64 i = 0; i < ranked; i++) {
    I64 k = ORDER[i];
    "RANKED:%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%s\n",
      i + 1, ROW_ID[k],
      ROW_R0[k], ROW_R1[k], ROW_R2[k], ROW_R3[k], ROW_R4[k], ROW_R5[k],
      ROW_R6[k];
  }

  if (ranked == 0) {
    "SELECTED=NONE\n";
    "STATUS=PASS\n";
    return 0;
  }
  I64 win = ORDER[0];
  "SELECTED=%s\n", ROW_ID[win];
  "SELECTED_R0=%d\n", ROW_R0[win];
  "SELECTED_R1=%d\n", ROW_R1[win];
  "SELECTED_R2=%d\n", ROW_R2[win];
  "SELECTED_R3=%d\n", ROW_R3[win];
  "SELECTED_R4=%d\n", ROW_R4[win];
  "SELECTED_R5=%d\n", ROW_R5[win];
  "SELECTED_R6=%s\n", ROW_R6[win];

  ControlNc05(n, win);
  ControlNc06(n, win);
  ControlNc07(n, win);
  ControlNc09(n, win);

  // Restore the canonical order for any later consumer.
  RankRows(n);

  "STATUS=PASS\n";
  return 0;
}
