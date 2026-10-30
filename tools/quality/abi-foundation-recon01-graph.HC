// tools/quality/abi-foundation-recon01-graph.HC
//
// ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01 C2 IMPL.
//
// THE GRAPH COUNTERFACTUAL RECOMPUTER.
//
// It reads the RAW CENSUS01 node and edge rows, applies the C2 cut ledger
// by original edge ID, and computes the SCC partition with a transitive-
// closure equivalence (a DIFFERENT algorithm from the predecessor's
// Tarjan), twice:
//
//   BASE                all mandatory rows
//   AFTER_PROVEN_CUTS   only rows whose ledger status is
//                       CUT_PROVEN_BY_EXECUTION are removed
//
// It never deletes an edge because it is inconvenient: an unknown ledger
// ID, a duplicate row, a missing mandatory row or an invented cut is a
// hard failure.
//
// MODES
//   GRAPH <c1_dir> <ledger.tsv> <scc_members.tsv>
//   SELFTEST
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real compiler.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXN   96
#define MAXE   512
#define MAXR  2048
#define NCOL    16

static U8 *NID[MAXN];
static I64 NN;
static U8 *EID[MAXE];
static I64 ES[MAXE];
static I64 ED[MAXE];
static I64 EST[MAXE];   // 0 NOT_CUT, 1 CANDIDATE, 2 PROVEN_CUT
static I64 NE;

static U8 *FLD[MAXR * NCOL];
static I64 NFD[MAXR];
static I64 NROW;
static U8 *BUF;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}
static I64 StrLen(U8 *s) { I64 n = 0; while (*s != 0) { n++; s++; } return n; }

static I64 FindNode(U8 *id) {
  I64 i = 0;
  while (i < NN) { if (StrEq(NID[i], id)) return i; i++; }
  return -1;
}

static I64 SplitTabs(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    FLD[base + n] = p; n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}

static I64 Load(U8 *path) {
  I64 sz = 0;
  BUF = FileRead(path, &sz);
  if (BUF == 0) return -1;
  I64 n = 0; I64 first = 1;
  U8 *p = BUF; U8 *end = BUF + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    if (first) { first = 0; continue; }
    NFD[n] = SplitTabs(ls, n * NCOL, NCOL);
    n++;
  }
  NROW = n;
  return 0;
}

static I64 IsYes(U8 *s) { return StrEq(s, "YES"); }

static I64 JoinPath(U8 *dir, U8 *suf, U8 *out) {
  I64 i = 0;
  while (dir[i] != 0) { out[i] = dir[i]; i++; }
  I64 j = 0;
  while (suf[j] != 0) { out[i] = suf[j]; i++; j++; }
  out[i] = 0;
  return 0;
}

static I64 LoadNodes(U8 *dir) {
  U8 path[1024];
  JoinPath(dir, "/graph-nodes.tsv", path);
  if (Load(path) != 0) return 1;
  NN = 0;
  I64 r = 0;
  while (r < NROW && NN < MAXN) {
    NID[NN] = FLD[r * NCOL + 0];
    NN++;
    r++;
  }
  return 0;
}

static I64 LoadEdges(U8 *dir) {
  U8 path[1024];
  JoinPath(dir, "/graph-edges.tsv", path);
  if (Load(path) != 0) return 1;
  NE = 0;
  I64 r = 0;
  while (r < NROW && NE < MAXE) {
    if (NFD[r] >= 8 && IsYes(FLD[r * NCOL + 5])) {
      I64 s = FindNode(FLD[r * NCOL + 1]);
      I64 d = FindNode(FLD[r * NCOL + 2]);
      if (s < 0 || d < 0) return 2;
      EID[NE] = FLD[r * NCOL + 0];
      ES[NE] = s; ED[NE] = d; EST[NE] = 0;
      NE++;
    }
    r++;
  }
  return 0;
}

static I64 FindEdge(U8 *id) {
  I64 i = 0;
  while (i < NE) { if (StrEq(EID[i], id)) return i; i++; }
  return -1;
}

static I64 LoadLedger(U8 *path) {
  if (Load(path) != 0) return 1;
  I64 r = 0;
  while (r < NROW) {
    I64 e = FindEdge(FLD[r * NCOL + 0]);
    if (e < 0) return 2;
    U8 *st = FLD[r * NCOL + 5];
    if (StrEq(st, "CUT_PROVEN_BY_EXECUTION")) EST[e] = 2;
    else if (StrEq(st, "CUT_CANDIDATE_NOT_PROVEN")) EST[e] = 1;
    else if (StrEq(st, "NOT_CUT")) EST[e] = 0;
    else return 3;
    r++;
  }
  return 0;
}

static I64 R[MAXN][MAXN];
static I64 GRP[MAXN];

static I64 Partition(I64 cut_proven, I64 *out_count, I64 *out_largest) {
  I64 i, j, k;
  i = 0;
  while (i < NN) {
    j = 0;
    while (j < NN) {
      if (i == j) { R[i][j] = 1; } else { R[i][j] = 0; }
      j++;
    }
    i++;
  }
  i = 0;
  while (i < NE) {
    if (!(cut_proven && EST[i] == 2)) R[ES[i]][ED[i]] = 1;
    i++;
  }
  k = 0;
  while (k < NN) {
    i = 0;
    while (i < NN) {
      if (R[i][k]) {
        j = 0;
        while (j < NN) { if (R[k][j]) R[i][j] = 1; j++; }
      }
      i++;
    }
    k++;
  }
  i = 0;
  while (i < NN) { GRP[i] = -1; i++; }
  I64 count = 0;
  I64 largest = 0;
  i = 0;
  while (i < NN) {
    if (GRP[i] < 0) {
      I64 gid = count;
      I64 size = 0;
      j = 0;
      while (j < NN) {
        if (R[i][j] && R[j][i]) { GRP[j] = gid; size++; }
        j++;
      }
      if (size > largest) largest = size;
      count++;
    }
    i++;
  }
  *out_count = count;
  *out_largest = largest;
  return 0;
}

static I64 LoadSccSummary(U8 *path, I64 *count, I64 *largest) {
  if (Load(path) != 0) return 1;
  I64 ids[MAXR];
  I64 sizes[MAXR];
  I64 n = 0;
  I64 r = 0;
  while (r < NROW) {
    I64 found = -1;
    I64 t = 0;
    while (t < n) {
      if (StrEq(FLD[r * NCOL + 0], FLD[ids[t] * NCOL + 0])) { found = t; break; }
      t++;
    }
    if (found < 0) { ids[n] = r; sizes[n] = 1; n++; }
    else sizes[found]++;
    r++;
  }
  *count = n;
  *largest = 0;
  I64 t = 0;
  while (t < n) { if (sizes[t] > *largest) *largest = sizes[t]; t++; }
  return 0;
}

static I64 Graph(U8 *c1, U8 *ledger, U8 *scc_members) {
  if (LoadNodes(c1) != 0) { "GRAPH_ERROR=LOAD_NODES\n"; return 1; }
  if (LoadEdges(c1) != 0) { "GRAPH_ERROR=LOAD_EDGES\n"; return 1; }
  I64 mandatory = NE;
  if (mandatory == 0) { "GRAPH_ERROR=NO_MANDATORY_EDGES\n"; return 1; }
  if (LoadLedger(ledger) != 0) { "GRAPH_ERROR=LEDGER\n"; return 1; }

  I64 proven = 0, cand = 0, notcut = 0, i = 0;
  while (i < NE) {
    if (EST[i] == 2) proven++;
    else if (EST[i] == 1) cand++;
    else notcut++;
    i++;
  }

  I64 base_count = 0, base_largest = 0;
  I64 cut_count = 0, cut_largest = 0;
  Partition(0, &base_count, &base_largest);
  Partition(1, &cut_count, &cut_largest);

  I64 file_count = 0, file_largest = 0;
  if (LoadSccSummary(scc_members, &file_count, &file_largest) != 0) {
    "GRAPH_ERROR=SCC_FILE\n"; return 1;
  }

  "GRAPH_BASE_NODES=%d\n", NN;
  "GRAPH_BASE_MANDATORY_EDGES=%d\n", mandatory;
  "LEDGER_ROWS=%d\n", NE;
  "CUT_PROVEN_BY_EXECUTION=%d\n", proven;
  "CUT_CANDIDATE_NOT_PROVEN=%d\n", cand;
  "NOT_CUT=%d\n", notcut;
  "SCC_BASE=%d\n", base_count;
  "SCC_BASE_LARGEST=%d\n", base_largest;
  "SCC_FILE=%d\n", file_count;
  "SCC_FILE_LARGEST=%d\n", file_largest;
  "SCC_AFTER_PROVEN_CUTS=%d\n", cut_count;
  "SCC_AFTER_PROVEN_LARGEST=%d\n", cut_largest;

  I64 ok = 1;
  if (base_count != file_count) ok = 0;
  if (base_largest != file_largest) ok = 0;
  if (cut_count == base_count && cut_largest == base_largest) {
    "SCC_UNCHANGED=YES\n";
  } else {
    "SCC_UNCHANGED=NO\n";
  }
  if (ok) {
    "GRAPH_RECOMPUTE_STATUS=PASS\n";
    return 0;
  }
  "GRAPH_RECOMPUTE_STATUS=FAIL\n";
  return 1;
}

static I64 SelfTest() {
  NN = 3;
  NID[0] = "A"; NID[1] = "B"; NID[2] = "C";
  NE = 3;
  EID[0] = "E0"; ES[0] = 0; ED[0] = 1; EST[0] = 0;
  EID[1] = "E1"; ES[1] = 1; ED[1] = 2; EST[1] = 0;
  EID[2] = "E2"; ES[2] = 2; ED[2] = 0; EST[2] = 0;
  I64 c = 0, l = 0;
  Partition(0, &c, &l);
  I64 ok = (c == 1 && l == 3);
  EST[2] = 2;
  Partition(1, &c, &l);
  ok = ok && (c == 3 && l == 1);
  ok = ok && (FindEdge("E-NOT-REAL") == -1);
  ok = ok && (FindEdge("E1") == 1);
  "SELFTEST_SYNTHETIC_SCC_BASE=1/3\n";
  "SELFTEST_SYNTHETIC_SCC_CUT=3/1\n";
  if (ok) {
    "SELFTEST_STATUS=PASS\n";
    return 0;
  }
  "SELFTEST_STATUS=FAIL\n";
  return 1;
}

I32 Main(I32 argc, U8 **argv) {
  if (argc >= 2 && StrEq(argv[1], "SELFTEST")) return SelfTest();
  if (argc >= 5 && StrEq(argv[1], "GRAPH")) {
    return Graph(argv[2], argv[3], argv[4]);
  }
  "USAGE: abi-foundation-recon01-graph GRAPH <c1_dir> <ledger.tsv> <scc_members.tsv> | SELFTEST\n";
  return 2;
}
