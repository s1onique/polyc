// tools/quality/whole-compiler-census01-independent.HC
//
// ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01 C3 EVIDENCE.
//
// THE INDEPENDENT RECOMPUTATION.
//
// It re-derives the census's load-bearing results with DIFFERENT
// algorithms and without reading the C2 producer's internal state:
//
//   JOINTS    recount authority classes, coverage statuses and the link
//             closure from the raw C1 tables with its own code path;
//   SCC       compute the mandatory SCCs with KOSARAJU (order pass then
//             reverse-graph assignment), not Tarjan, and compare the
//             PARTITION with the committed c2/scc-members.tsv;
//   FORECAST  recompute each bundle cost from c2/bundle-members.tsv and
//             the frozen assumptions, then compare with c2/forecast.tsv
//             and classify the below-100 claim independently.
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// compiler. Explicit control flow only; no pointer-valued ternaries.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAX_ROWS  4200
#define NCOL        24
#define MAX_NODES   96
#define MAX_BUNDLES 64

static U8 *FLD[MAX_ROWS * NCOL];
static I64 NFD[MAX_ROWS];
static I64 NROW;
static U8 *BFLD[MAX_ROWS * NCOL];
static I64 B_NFD[MAX_ROWS];
static I64 B_NROW;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}
static I64 ParseInt(U8 *s) {
  I64 v = 0; U8 *p = s;
  while (*p >= '0' && *p <= '9') { v = v * 10 + (*p - '0'); p++; }
  return v;
}
static I64 ParseId(U8 *s) {
  while (*s != 0 && (*s < 48 || *s > 57)) s++;
  return ParseInt(s);
}
static I64 SplitA(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    FLD[base + n] = p; n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}
static I64 SplitB(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    BFLD[base + n] = p; n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}
static I64 LoadA(U8 *path, I64 hdr) {
  I64 sz = 0; U8 *buf = FileRead(path, &sz);
  if (buf == NULL) return -1;
  I64 n = 0; U8 *p = buf; U8 *e = buf + sz; I64 first = 1;
  while (p < e && n < MAX_ROWS) {
    U8 *ls = p; while (p < e && *p != '\n') p++;
    U8 *le = p; if (p < e) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0) continue;
    if (*ls == '#') continue;
    if (first && hdr) { first = 0; continue; }
    first = 0;
    NFD[n] = SplitA(ls, n * NCOL, NCOL); n++;
  }
  NROW = n; return 0;
}
static I64 LoadB(U8 *path, I64 hdr) {
  I64 sz = 0; U8 *buf = FileRead(path, &sz);
  if (buf == NULL) return -1;
  I64 n = 0; U8 *p = buf; U8 *e = buf + sz; I64 first = 1;
  while (p < e && n < MAX_ROWS) {
    U8 *ls = p; while (p < e && *p != '\n') p++;
    U8 *le = p; if (p < e) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0) continue;
    if (*ls == '#') continue;
    if (first && hdr) { first = 0; continue; }
    first = 0;
    B_NFD[n] = SplitB(ls, n * NCOL, NCOL); n++;
  }
  B_NROW = n; return 0;
}
static U8 *FA(I64 r, I64 c) {
  if (r < 0 || r >= NROW || c < 0 || c >= NFD[r]) return "";
  return FLD[r * NCOL + c];
}
static U8 *FB(I64 r, I64 c) {
  if (r < 0 || r >= B_NROW || c < 0 || c >= B_NFD[r]) return "";
  return BFLD[r * NCOL + c];
}

static U8 PBUF[1024];
static U8 *Join(U8 *a, U8 *b) {
  I64 i = 0;
  while (*a != 0 && i < 900) { PBUF[i] = *a; i++; a++; }
  if (i > 0 && PBUF[i - 1] != 47) { PBUF[i] = 47; i++; }
  while (*b != 0 && i < 1023) { PBUF[i] = *b; i++; b++; }
  PBUF[i] = 0;
  return PBUF;
}

static I64 FAILS;
static U0 Fail(U8 *cls, U8 *detail) { FAILS++; "DETECTOR=%s DETAIL=%s\n", cls, detail; }
static U0 Pass(U8 *name) { "CHECK=%s STATUS=PASS\n", name; }
static I64 CeilD(I64 a, I64 b) {
  if (b <= 0) return 0;
  if (a <= 0) return 0;
  return (a + b - 1) / b;
}

// ------------------------------------------------------------------
// JOINTS
// ------------------------------------------------------------------
static I64 ModeJoins(U8 *c1) {
  I64 bad = 0;
  if (LoadA(Join(c1, "authorities.tsv"), 1) != 0) { Fail("MISSING_FILE", "authorities.tsv"); return 1; }
  I64 ca = 0, ma = 0, pa = 0, other = 0;
  I64 r = 0;
  while (r < NROW) {
    U8 *o = FA(r, 18);
    if (StrEq(o, "C_AUTHORITY")) ca++;
    else if (StrEq(o, "C_MECHANICAL_ADAPTER")) ma++;
    else if (StrEq(o, "POLYC_AUTHORITY")) pa++;
    else other++;
    r++;
  }
  "AUTHORITY_ROWS=%d C_AUTHORITY=%d C_MECHANICAL_ADAPTER=%d POLYC_AUTHORITY=%d OTHER=%d\n",
    NROW, ca, ma, pa, other;
  if (other != 0) { Fail("AUTHORITY_CLASS_ENUM", "other-class-present"); bad++; }
  if (pa != 9) { Fail("NINE_AUTHORITY_CONSERVATION", "polyc-authority-count"); bad++; }
  if (LoadB(Join(c1, "semantic-coverage.tsv"), 1) != 0) { Fail("MISSING_FILE", "semantic-coverage.tsv"); return bad + 1; }
  I64 en = 0, co = 0, st = 0, ad = 0, dun = 0;
  I64 i = 0;
  while (i < B_NROW) {
    U8 *s = FB(i, 7);
    if (StrEq(s, "AUTHORITY_ENUMERATED")) en++;
    else if (StrEq(s, "AUTHORITY_COARSE")) co++;
    else if (StrEq(s, "AUTHORITY_STRAIGHTLINE")) st++;
    else if (StrEq(s, "ADAPTER_DELEGATION_ONLY")) ad++;
    else dun++;
    i++;
  }
  "COVERAGE_ROWS=%d ENUMERATED=%d COARSE=%d STRAIGHTLINE=%d ADAPTERS=%d UNKNOWN_STATUS=%d\n",
    B_NROW, en, co, st, ad, dun;
  if (dun != 0) { Fail("COVERAGE_STATUS_ENUM", "unknown-status"); bad++; }
  if (en + co + st + ad != B_NROW) { Fail("COVERAGE_PARTITION", "sum-mismatch"); bad++; }
  if (LoadB(Join(c1, "link-inputs-and-archive-members.tsv"), 1) != 0) { Fail("MISSING_FILE", "link-inputs"); return bad + 1; }
  I64 li = 0;
  i = 0;
  while (i < B_NROW) {
    if (StrEq(FB(i, 3), "C_OBJECT") && StrEq(FB(i, 4), "YES")) li++;
    i++;
  }
  if (LoadA(Join(c1, "source-target-manifest.tsv"), 1) != 0) { Fail("MISSING_FILE", "manifest"); return bad + 1; }
  I64 ml = 0;
  r = 0;
  while (r < NROW) {
    if (StrEq(FA(r, 11), "LINKED")) ml++;
    r++;
  }
  "MANIFEST_LINKED=%d LINK_INPUT_C_OBJECT_YES=%d\n", ml, li;
  if (ml != li) { Fail("MISSING_LINKED_OBJECT", "manifest-link-input-delta"); bad++; }
  if (bad == 0) Pass("joins");
  return bad;
}

// ------------------------------------------------------------------
// KOSARAJU SCC
// ------------------------------------------------------------------
static U8 *NID[MAX_NODES];
static I64 NN;
static I64 ADJ[MAX_NODES][MAX_NODES];
static I64 ADJN[MAX_NODES];
static I64 RADJ[MAX_NODES][MAX_NODES];
static I64 RADJN[MAX_NODES];
static I64 VIS[MAX_NODES];
static I64 ORDER[MAX_NODES];
static I64 ON;
static I64 COMPK[MAX_NODES];
static I64 NCK;
static I64 PRIOR[MAX_NODES];

static I64 IdxOf(U8 *id) {
  I64 i = 0;
  while (i < NN) { if (StrEq(NID[i], id)) return i; i++; }
  return -1;
}

static U0 DfsOrder(I64 s) {
  I64 stk[MAX_NODES];
  I64 pos[MAX_NODES];
  I64 sp = 0;
  stk[0] = s; pos[0] = 0; sp = 1;
  VIS[s] = 1;
  while (sp > 0) {
    I64 v = stk[sp - 1];
    if (pos[sp - 1] < ADJN[v]) {
      I64 w = ADJ[v][pos[sp - 1]];
      pos[sp - 1]++;
      if (!VIS[w]) { VIS[w] = 1; stk[sp] = w; pos[sp] = 0; sp++; }
    } else {
      ORDER[ON] = v; ON++;
      sp--;
    }
  }
}

static U0 DfsAssign(I64 s, I64 c) {
  I64 stk[MAX_NODES];
  I64 sp = 0;
  stk[0] = s; sp = 1;
  COMPK[s] = c;
  while (sp > 0) {
    sp--;
    I64 v = stk[sp];
    I64 i = 0;
    while (i < RADJN[v]) {
      I64 w = RADJ[v][i];
      if (COMPK[w] < 0) { COMPK[w] = c; stk[sp] = w; sp++; }
      i++;
    }
  }
}

static I64 ModeScc(U8 *c1, U8 *c2) {
  I64 bad = 0;
  if (LoadA(Join(c1, "graph-nodes.tsv"), 1) != 0) { Fail("MISSING_FILE", "graph-nodes"); return 1; }
  NN = 0;
  I64 r = 0;
  while (r < NROW && NN < MAX_NODES) { NID[NN] = FA(r, 0); NN++; r++; }
  I64 i = 0;
  while (i < NN) { ADJN[i] = 0; RADJN[i] = 0; VIS[i] = 0; COMPK[i] = -1; i++; }
  if (LoadB(Join(c1, "graph-edges.tsv"), 1) != 0) { Fail("MISSING_FILE", "graph-edges"); return 1; }
  i = 0;
  while (i < B_NROW) {
    if (StrEq(FB(i, 5), "YES")) {
      I64 s = IdxOf(FB(i, 1));
      I64 d = IdxOf(FB(i, 2));
      if (s >= 0 && d >= 0 && s != d) {
        ADJ[s][ADJN[s]] = d; ADJN[s]++;
        RADJ[d][RADJN[d]] = s; RADJN[d]++;
      }
    }
    i++;
  }
  ON = 0;
  i = 0;
  while (i < NN) { if (!VIS[i]) DfsOrder(i); i++; }
  NCK = 0;
  I64 k = ON - 1;
  while (k >= 0) {
    I64 v = ORDER[k];
    if (COMPK[v] < 0) { DfsAssign(v, NCK); NCK++; }
    k--;
  }
  "KOSARAJU_NODES=%d KOSARAJU_SCCS=%d\n", NN, NCK;
  if (LoadB(Join(c2, "scc-members.tsv"), 1) != 0) { Fail("MISSING_FILE", "scc-members"); return bad + 1; }
  i = 0;
  while (i < NN) { PRIOR[i] = -1; i++; }
  r = 0;
  while (r < B_NROW) {
    I64 idx = IdxOf(FB(r, 1));
    if (idx >= 0) PRIOR[idx] = ParseId(FB(r, 0));
    r++;
  }
  i = 0;
  while (i < NN) {
    I64 j = i + 1;
    while (j < NN) {
      I64 a = 0, b = 0;
      if (COMPK[i] == COMPK[j]) a = 1;
      if (PRIOR[i] >= 0 && PRIOR[i] == PRIOR[j]) b = 1;
      if (a != b) { Fail("SCC_RECOMPUTE_MISMATCH", NID[i]); bad++; }
      j++;
    }
    i++;
  }
  if (bad == 0) Pass("scc-kosaraju");
  return bad;
}


// ------------------------------------------------------------------
// FORECAST recompute
// ------------------------------------------------------------------
static U8 *NAMES[MAX_BUNDLES];
static I64 BSITES[MAX_BUNDLES];
static I64 BHIGH[MAX_BUNDLES];
static I64 BBASE[MAX_BUNDLES];

static I64 ModeForecast(U8 *c2) {
  I64 bad = 0;
  if (LoadA(Join(c2, "bundle-members.tsv"), 1) != 0) { Fail("MISSING_FILE", "bundle-members"); return 1; }
  I64 nb = 0;
  I64 i = 0;
  while (i < NROW) {
    U8 *b = FA(i, 0);
    I64 idx = -1;
    I64 k = 0;
    while (k < nb) {
      if (StrEq(NAMES[k], b)) { idx = k; break; }
      k++;
    }
    if (idx < 0) {
      if (nb >= MAX_BUNDLES) { Fail("FORECAST_DOUBLE_COUNT", "too-many-bundles"); return bad + 1; }
      idx = nb;
      NAMES[nb] = b;
      BSITES[nb] = 0;
      BHIGH[nb] = 0;
      nb++;
    }
    BSITES[idx] += ParseInt(FA(i, 3));
    i++;
  }
  if (LoadB(Join(c2, "migration-bundles.tsv"), 1) != 0) { Fail("MISSING_FILE", "migration-bundles"); return bad + 1; }
  I64 k2 = 0;
  while (k2 < nb) {
    i = 0;
    while (i < B_NROW) {
      if (StrEq(FB(i, 0), NAMES[k2])) {
        if (StrEq(FB(i, 5), "1")) BHIGH[k2] = 1;
        if (ParseInt(FB(i, 3)) != BSITES[k2]) { Fail("FORECAST_DOUBLE_COUNT", NAMES[k2]); bad++; }
      }
      i++;
    }
    k2++;
  }
  I64 sum_base = 0;
  k2 = 0;
  while (k2 < nb) {
    I64 impl = CeilD(BSITES[k2], 12);
    if (impl < 1) impl = 1;
    I64 corr = CeilD((impl + 1) * 44, 100);
    I64 base = 1 + impl + 1 + 1 + corr;
    if (BHIGH[k2]) base = CeilD(base * 125, 100);
    BBASE[k2] = base;
    sum_base += base;
    "BUNDLE=%s SITES=%d IMPL=%d BASE=%d HIGH=%d\n", NAMES[k2], BSITES[k2], impl, base, BHIGH[k2];
    i = 0;
    while (i < B_NROW) {
      if (StrEq(FB(i, 0), NAMES[k2]) && ParseInt(FB(i, 7)) != base) {
        Fail("UNREPRODUCIBLE_FORECAST", NAMES[k2]); bad++;
      }
      i++;
    }
    k2++;
  }
  I64 m1 = sum_base + 3;
  I64 m2 = m1 + 4 + 3;
  I64 m3 = m2 + 3;
  I64 m4 = m3 + CeilD(m2 * 25, 100);
  "RECOMPUTED M1=%d M2=%d M3=%d M4=%d BUNDLES=%d\n", m1, m2, m3, m4, nb;
  if (LoadB(Join(c2, "forecast.tsv"), 1) != 0) { Fail("MISSING_FILE", "forecast.tsv"); return bad + 1; }
  i = 0;
  while (i < B_NROW) {
    U8 *m = FB(i, 0);
    I64 want = -1;
    if (StrEq(m, "M1")) want = m1;
    if (StrEq(m, "M2")) want = m2;
    if (StrEq(m, "M3")) want = m3;
    if (StrEq(m, "M4")) want = m4;
    if (want >= 0 && ParseInt(FB(i, 2)) != want) { Fail("UNREPRODUCIBLE_FORECAST", m); bad++; }
    i++;
  }
  U8 *v = "UNPROVEN";
  if (m2 < 100) v = "SUPPORTED";
  else if (m1 >= 100) v = "NOT_SUPPORTED";
  "INDEPENDENT_M2_BELOW_100=%s\n", v;
  if (bad == 0) Pass("forecast-independent");
  return bad;
}

I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) { "USAGE: whole-compiler-census01-independent JOINTS|SCC|FORECAST|SELFTEST\n"; return 2; }
  if (StrEq(argv[1], "SELFTEST")) {
    I64 f = 0;
    if (CeilD(13, 12) != 2) f++;
    if (CeilD(12, 12) != 1) f++;
    if (CeilD(0, 12) != 0) f++;
    if (ParseInt("42") != 42) f++;
    if (!StrEq("a", "a")) f++;
    if (StrEq("a", "b")) f++;
    "SELFTEST_FAIL=%d\n", f;
    if (f == 0) { "SELFTEST_STATUS=PASS\n"; return 0; }
    "SELFTEST_STATUS=FAIL\n";
    return 1;
  }
  if (StrEq(argv[1], "JOINTS")) {
    if (argc < 3) return 2;
    if (ModeJoins(argv[2]) == 0) return 0;
    return 1;
  }
  if (StrEq(argv[1], "SCC")) {
    if (argc < 4) return 2;
    if (ModeScc(argv[2], argv[3]) == 0) return 0;
    return 1;
  }
  if (StrEq(argv[1], "FORECAST")) {
    if (argc < 3) return 2;
    if (ModeForecast(argv[2]) == 0) return 0;
    return 1;
  }
  "UNKNOWN_MODE=%s\n", argv[1];
  return 2;
}
