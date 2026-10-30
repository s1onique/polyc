// tools/quality/whole-compiler-census01-verify.HC
//
// ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01 C2 IMPL.
//
// THE WHOLE-COMPILER CENSUS, GRAPH AND FORECAST VERIFIER.
//
// WHY IT EXISTS
// =============
// The C1 census is raw evidence. A raw table cannot prove that it is
// internally consistent, that every mandatory dependency edge is the
// one the source actually creates, that the mandatory SCCs are real,
// or that a forecast follows from the bundle roster. This tool is the
// substantive PolyC verifier that does those things, plus the adverse
// executions (CONTROL mode) that prove each detector is sensitive.
//
// MODES
// =====
//   SCHEMA   <c1_dir>
//   GRAPH    <c1_dir> <out_dir> [prior_scc_members.tsv]
//   FORECAST <c1_dir> <out_dir>
//   CONTROL  <control_id> <c1_dir> <work_dir>
//   SELFTEST
//
// F-POLYC-TOOLS: this is a PolyC implementation, compiled and executed
// by a real PolyC compiler. It is not shell glue. It deliberately uses
// explicit control flow instead of pointer-valued ternaries (the known
// OOM lead) and fixed-size static tables (bounded memory).
//
// USAGE:
//   build/whole-compiler-census01-verify SCHEMA evidence/ACT-.../c1

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags);

#define MAX_ROWS   4200
#define NCOL         40
#define MAX_NODES    96
#define MAX_ID       64
#define HASH_BUCKETS 4096

// ------------------------------------------------------------------
// Loaded TSV tables (bounded, static).
// ------------------------------------------------------------------
static U8 *FLD[MAX_ROWS * NCOL];
static I64 NFD[MAX_ROWS];
static I64 NROW;

static U8 *G_FLD[MAX_ROWS * NCOL];
static I64 G_NFD[MAX_ROWS];
static I64 G_NROW;
static U8 *BFLD[MAX_ROWS * NCOL];
static I64 B_NFD[MAX_ROWS];
static I64 B_NROW;
static U8 *G_PATH;
static I64 G_HEADER;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}

static I64 StrLen(U8 *s) { I64 n = 0; while (*s != 0) { n++; s++; } return n; }

static I64 StrNCmp(U8 *a, U8 *b, I64 n) {
  I64 i = 0;
  while (i < n && *a != 0 && *b != 0) {
    if (*a != *b) return *a - *b;
    a++; b++; i++;
  }
  if (i >= n) return 0;
  return *a - *b;
}

static I64 ParseInt(U8 *s) {
  I64 v = 0; I64 neg = 0; U8 *p = s;
  if (*p == '-') { neg = 1; p++; }
  if (*p == 0) return 0;
  while (*p >= '0' && *p <= '9') { v = v * 10 + (*p - '0'); p++; }
  if (neg) return -v;
  return v;
}

static I64 SplitTabsA(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    FLD[base + n] = p; n++;
    while (*p != 0 && *p != 0x09) p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}
static I64 SplitTabsG(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    G_FLD[base + n] = p; n++;
    while (*p != 0 && *p != 0x09) p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}
static I64 SplitTabsB(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    BFLD[base + n] = p; n++;
    while (*p != 0 && *p != 0x09) p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}
// Load a TSV into global slots (g = 0 -> FLD/NROW, g = 1 -> G_FLD).
static I64 TsvLoad(U8 *path, I64 g, I64 has_header) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) return -1;
  I64 n = 0;
  U8 *p = buf;
  U8 *end = buf + sz;
  I64 first = 1;
  while (p < end && n < MAX_ROWS) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0) continue;
    if (*ls == '#') continue;
    if (first && has_header) { first = 0; continue; }
    first = 0;
    if (g == 0) {
      I64 nf = SplitTabsA(ls, n * NCOL, NCOL);
      NFD[n] = nf;
    } else {
      I64 nf = SplitTabsG(ls, n * NCOL, NCOL);
      G_NFD[n] = nf;
    }
    n++;
  }
  if (g == 0) NROW = n; else G_NROW = n;
  return 0;
}

static U8 *Fld(I64 r, I64 c) {
  if (r < 0 || r >= NROW) return "";
  if (c < 0 || c >= NFD[r]) return "";
  return FLD[r * NCOL + c];
}

static U8 *GFld(I64 r, I64 c) {
  if (r < 0 || r >= G_NROW) return "";
  if (c < 0 || c >= G_NFD[r]) return "";
  return G_FLD[r * NCOL + c];
}

// ------------------------------------------------------------------
// Failure reporting. Every detector prints one DETECTOR=<CLASS> line.
// ------------------------------------------------------------------
static U8 *EXPECT;
static I64 EXPECT_SEEN;
static I64 FAILS;
static I64 CHECKS;

static U0 Fail(U8 *cls, U8 *detail) {
  if (EXPECT != 0 && StrEq(cls, EXPECT)) EXPECT_SEEN = 1;
  FAILS++;
  "DETECTOR=%s DETAIL=%s\n", cls, detail;
}

static U0 Pass(U8 *name) {
  CHECKS++;
  "CHECK=%s STATUS=PASS\n", name;
}

static U0 BeginCheck(U8 *name) {
  CHECKS++;
  "CHECK=%s STATUS=BEGIN\n", name;
}

// ------------------------------------------------------------------
// A small open-addressing string->row table for ID uniqueness and
// referential integrity. Bounded by MAX_ROWS.
// ------------------------------------------------------------------
static I64 HT_HEAD[HASH_BUCKETS];
static I64 HT_NEXT[MAX_ROWS];
static I64 HT_ROW[MAX_ROWS];
static I64 HT_N;

static I64 HashStr(U8 *s) {
  U64 h = 1469598103934665603;
  while (*s != 0) { h = (h ^ *s) * 1099511628211; s++; }
  return (h & 0x7fffffffffffffff);
}

static U0 HtReset() {
  I64 i = 0;
  while (i < HASH_BUCKETS) { HT_HEAD[i] = -1; i++; }
  HT_N = 0;
}

static I64 HtFind(U8 *key) {
  I64 b = HashStr(key) % HASH_BUCKETS;
  I64 i = HT_HEAD[b];
  while (i >= 0) {
    if (StrEq(G_FLD[HT_ROW[i] * NCOL + 0], key)) return HT_ROW[i];
    i = HT_NEXT[i];
  }
  return -1;
}

static U0 HtAdd(I64 row) {
  I64 b = HashStr(G_FLD[row * NCOL + 0]) % HASH_BUCKETS;
  HT_NEXT[HT_N] = HT_HEAD[b];
  HT_ROW[HT_N] = row;
  HT_HEAD[b] = HT_N;
  HT_N++;
}

// Load nodes and index them by node_id (column 0).
static I64 LoadNodes(U8 *path) {
  if (TsvLoad(path, 1, 1) != 0) return -1;
  HtReset();
  I64 r = 0;
  while (r < G_NROW) { HtAdd(r); r++; }
  return 0;
}

// ------------------------------------------------------------------
// Second table slot (B), for joins.
// ------------------------------------------------------------------

static I64 BLoad(U8 *path, I64 has_header) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) return -1;
  I64 n = 0;
  U8 *p = buf;
  U8 *end = buf + sz;
  I64 first = 1;
  while (p < end && n < MAX_ROWS) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0) continue;
    if (*ls == '#') continue;
    if (first && has_header) { first = 0; continue; }
    first = 0;
    B_NFD[n] = SplitTabsB(ls, n * NCOL, NCOL);
    n++;
  }
  B_NROW = n;
  return 0;
}

static U8 *BFld(I64 r, I64 c) {
  if (r < 0 || r >= B_NROW) return "";
  if (c < 0 || c >= B_NFD[r]) return "";
  return BFLD[r * NCOL + c];
}

static U8 KEYBUF[1024];
static U8 PBUF[1024];
static U8 PBUF2[1024];
static U8 *Cat2B(U8 *a, U8 *b) {
  I64 i = 0;
  while (*a != 0 && i < 1000) { PBUF2[i] = *a; i++; a++; }
  while (*b != 0 && i < 1023) { PBUF2[i] = *b; i++; b++; }
  PBUF2[i] = 0;
  return PBUF2;
}

static U8 *Cat2(U8 *a, U8 *b) {
  I64 i = 0;
  while (*a != 0 && i < 1000) { PBUF[i] = *a; i++; a++; }
  while (*b != 0 && i < 1023) { PBUF[i] = *b; i++; b++; }
  PBUF[i] = 0;
  return PBUF;
}

static U8 *PathJoin(U8 *a, U8 *b) {
  I64 i = 0;
  while (*a != 0 && i < 1000) { PBUF[i] = *a; i++; a++; }
  if (i > 0 && PBUF[i - 1] != '/') { PBUF[i] = '/'; i++; }
  while (*b != 0 && i < 1023) { PBUF[i] = *b; i++; b++; }
  PBUF[i] = 0;
  return PBUF;
}



static U8 *Key2(U8 *a, U8 *b) {
  I64 i = 0;
  while (*a != 0 && i < 1000) { KEYBUF[i] = *a; i++; a++; }
  KEYBUF[i] = '|'; i++;
  while (*b != 0 && i < 1023) { KEYBUF[i] = *b; i++; b++; }
  KEYBUF[i] = 0;
  return KEYBUF;
}

// A separate open-addressing table over B rows, keyed by columns k1,k2.
static I64 BHT_HEAD[HASH_BUCKETS];
static I64 BHT_NEXT[MAX_ROWS];
static I64 BHT_ROW[MAX_ROWS];
static I64 BHT_N;
static I64 BHT_K1;
static I64 BHT_K2;

static U0 BHtReset(I64 k1, I64 k2) {
  I64 i = 0;
  while (i < HASH_BUCKETS) { BHT_HEAD[i] = -1; i++; }
  BHT_N = 0; BHT_K1 = k1; BHT_K2 = k2;
}

static U0 BHtBuild() {
  I64 r = 0;
  while (r < B_NROW) {
    U8 *k = Key2(BFld(r, BHT_K1), BFld(r, BHT_K2));
    I64 b = HashStr(k) % HASH_BUCKETS;
    BHT_NEXT[BHT_N] = BHT_HEAD[b];
    BHT_ROW[BHT_N] = r;
    BHT_HEAD[b] = BHT_N;
    BHT_N++;
    r++;
  }
}

static I64 BHtFind2(U8 *a, U8 *b) {
  U8 *k = Key2(a, b);
  I64 h = HashStr(k) % HASH_BUCKETS;
  I64 i = BHT_HEAD[h];
  while (i >= 0) {
    I64 r = BHT_ROW[i];
    if (StrEq(BFld(r, BHT_K1), a) && StrEq(BFld(r, BHT_K2), b)) return r;
    i = BHT_NEXT[i];
  }
  return -1;
}

// A single-column key table over B.
static I64 BHT1_HEAD[HASH_BUCKETS];
static I64 BHT1_NEXT[MAX_ROWS];
static I64 BHT1_ROW[MAX_ROWS];
static I64 BHT1_N;
static I64 BHT1_K;

static U0 BHt1Reset(I64 k) {
  I64 i = 0;
  while (i < HASH_BUCKETS) { BHT1_HEAD[i] = -1; i++; }
  BHT1_N = 0; BHT1_K = k;
}

static U0 BHt1Build() {
  I64 r = 0;
  while (r < B_NROW) {
    I64 b = HashStr(BFld(r, BHT1_K)) % HASH_BUCKETS;
    BHT1_NEXT[BHT1_N] = BHT1_HEAD[b];
    BHT1_ROW[BHT1_N] = r;
    BHT1_HEAD[b] = BHT1_N;
    BHT1_N++;
    r++;
  }
}

static I64 BHt1Find(U8 *key) {
  I64 h = HashStr(key) % HASH_BUCKETS;
  I64 i = BHT1_HEAD[h];
  while (i >= 0) {
    I64 r = BHT1_ROW[i];
    if (StrEq(BFld(r, BHT1_K), key)) return r;
    i = BHT1_NEXT[i];
  }
  return -1;
}

// ------------------------------------------------------------------
// Node-id snapshot (for edge endpoint checks after the slot is reused).
// ------------------------------------------------------------------
static U8 *NODE_ID[MAX_NODES];
static I64 NODE_N;

static I64 NodeIndex(U8 *id) {
  I64 i = 0;
  while (i < NODE_N) {
    if (StrEq(NODE_ID[i], id)) return i;
    i++;
  }
  return -1;
}

static I64 SnapshotNodes(U8 *path) {
  if (LoadNodes(path) != 0) return -1;
  NODE_N = 0;
  I64 r = 0;
  while (r < G_NROW && NODE_N < MAX_NODES) {
    NODE_ID[NODE_N] = GFld(r, 0);
    NODE_N++;
    r++;
  }
  return NODE_N;
}

static I64 IsOwnerClass(U8 *s) {
  if (StrEq(s, "C_AUTHORITY")) return 1;
  if (StrEq(s, "POLYC_AUTHORITY")) return 1;
  if (StrEq(s, "C_MECHANICAL_ADAPTER")) return 1;
  if (StrEq(s, "EXTERNAL_DEPENDENCY")) return 1;
  if (StrEq(s, "UNKNOWN_AUTHORITY")) return 1;
  if (StrEq(s, "NOT_IN_TARGET")) return 1;
  return 0;
}

static I64 IsStatus(U8 *s) {
  if (StrEq(s, "AUTHORITY_ENUMERATED")) return 1;
  if (StrEq(s, "AUTHORITY_COARSE")) return 1;
  if (StrEq(s, "AUTHORITY_STRAIGHTLINE")) return 1;
  if (StrEq(s, "ADAPTER_DELEGATION_ONLY")) return 1;
  return 0;
}

static I64 ExpectedEdgeType(U8 *h) {
  if (StrEq(h, "containers.h") || StrEq(h, "list.h")) return 2;
  if (StrEq(h, "cctrl.h")) return 3;
  return 1;
}

static I64 EdgeTypeMatch(U8 *type, I64 expected) {
  if (expected == 1) return StrEq(type, "TYPE_REPRESENTATION");
  if (expected == 2) return StrEq(type, "CALLBACK");
  return StrEq(type, "RECOVERY");
}

static I64 CheckAuthorities(U8 *dir) {
  BeginCheck("authorities");
  if (TsvLoad(PathJoin(dir, "authorities.tsv"), 1, 1) != 0) {
    Fail("MISSING_FILE", "authorities.tsv");
    return 1;
  }
  I64 bad = 0;
  I64 r = 0;
  HtReset();
  while (r < G_NROW) {
    if (G_NFD[r] < 34) { Fail("MALFORMED_ROW", GFld(r, 0)); bad++; r++; continue; }
    U8 *id = GFld(r, 0);
    if (*id == 0) { Fail("MALFORMED_ROW", "empty-authority-id"); bad++; r++; continue; }
    if (!IsOwnerClass(GFld(r, 18))) { Fail("MALFORMED_ROW", id); bad++; }
    if (!StrEq(GFld(r, 12), "CFG-PROD-HCC-JIT-ON")) {
      Fail("CONFIGURATION_SELECTOR_MISMATCH", id); bad++;
    }
    if (StrEq(GFld(r, 18), "POLYC_AUTHORITY")) {
      if (*GFld(r, 17) == 0) { Fail("MALFORMED_ROW", id); bad++; }
    }
    if (StrEq(GFld(r, 18), "C_AUTHORITY")) {
      if (!StrEq(GFld(r, 20), "OWNS_DECISION") &&
          !StrEq(GFld(r, 20), "OWNS_LOCAL_DECISIONS_AND_ALSO_DELEGATES")) {
        Fail("ADAPTER_AUTHORITY_CONFUSION", id); bad++;
      }
    }
    if (HtFind(id) >= 0) { Fail("DUPLICATE_AUTHORITY_ID", id); bad++; }
    else HtAdd(r);
    r++;
  }
  "AUTHORITY_ROWS=%d\n", G_NROW;
  if (bad == 0) Pass("authorities"); else Fail("AUTHORITIES_INVALID", "see rows above");
  return bad;
}


static I64 CheckCoverage(U8 *dir) {
  BeginCheck("semantic-coverage");
  if (BLoad(PathJoin(dir, "semantic-coverage.tsv"), 1) != 0) {
    Fail("MISSING_FILE", "semantic-coverage.tsv");
    return 1;
  }
  I64 bad = 0;
  I64 r = 0;
  I64 enabled = 0;
  I64 coarse = 0;
  I64 straight = 0;
  I64 adapters = 0;
  while (r < B_NROW) {
    if (B_NFD[r] < 14) { Fail("MALFORMED_ROW", BFld(r, 2)); bad++; r++; continue; }
    if (!IsStatus(BFld(r, 7))) { Fail("MALFORMED_ROW", BFld(r, 2)); bad++; }
    if (StrEq(BFld(r, 7), "AUTHORITY_ENUMERATED")) enabled++;
    if (StrEq(BFld(r, 7), "AUTHORITY_COARSE")) coarse++;
    if (StrEq(BFld(r, 7), "AUTHORITY_STRAIGHTLINE")) straight++;
    if (StrEq(BFld(r, 7), "ADAPTER_DELEGATION_ONLY")) {
      adapters++;
      if (ParseInt(BFld(r, 8)) != 0) { Fail("ADAPTER_AUTHORITY_CONFUSION", BFld(r, 2)); bad++; }
      if (ParseInt(BFld(r, 9)) != 0) { Fail("ACTIVE_C_DECISION_IN_ADAPTER", BFld(r, 2)); bad++; }
      if (ParseInt(BFld(r, 10)) != 1) { Fail("ADAPTER_AUTHORITY_CONFUSION", BFld(r, 2)); bad++; }
    }
    if (ParseInt(BFld(r, 11)) > 0) { Fail("DORMANT_POLYC_AUTHORITY", BFld(r, 2)); bad++; }
    r++;
  }
  "COVERAGE_ROWS=%d ENUMERATED=%d COARSE=%d STRAIGHT=%d ADAPTERS=%d\n",
    B_NROW, enabled, coarse, straight, adapters;
  if (bad == 0) Pass("semantic-coverage"); else Fail("COVERAGE_INVALID", "see rows above");
  return bad;
}


static I64 CheckNodesEdges(U8 *dir) {
  BeginCheck("graph-nodes-edges");
  I64 bad = 0;
  I64 n = SnapshotNodes(PathJoin(dir, "graph-nodes.tsv"));
  if (n < 0) { Fail("MISSING_FILE", "graph-nodes.tsv"); return 1; }
  if (n > MAX_NODES) { Fail("MALFORMED_ROW", "too-many-nodes"); bad++; }
  if (TsvLoad(PathJoin(dir, "graph-edges.tsv"), 1, 1) != 0) {
    Fail("MISSING_FILE", "graph-edges.tsv");
    return bad + 1;
  }
  HtReset();
  I64 e = 0;
  while (e < G_NROW) {
    if (G_NFD[e] < 12) { Fail("MALFORMED_ROW", GFld(e, 0)); bad++; e++; continue; }
    if (HtFind(GFld(e, 0)) >= 0) { Fail("DUPLICATE_EDGE_ID", GFld(e, 0)); bad++; }
    else HtAdd(e);
    if (NodeIndex(GFld(e, 1)) < 0) { Fail("MISSING_REQUIRED_EDGE", GFld(e, 1)); bad++; }
    if (NodeIndex(GFld(e, 2)) < 0) { Fail("MISSING_REQUIRED_EDGE", GFld(e, 2)); bad++; }
    if (!StrEq(GFld(e, 5), "YES") && !StrEq(GFld(e, 5), "NO")) {
      Fail("EDGE_TYPE_OR_MANDATORY_MISMATCH", GFld(e, 0)); bad++;
    }
    e++;
  }
  "NODES=%d EDGES=%d\n", NODE_N, G_NROW;
  if (bad == 0) Pass("graph-nodes-edges"); else Fail("GRAPH_INVALID", "see rows above");
  return bad;
}

static I64 CheckLinkClosure(U8 *dir) {
  BeginCheck("link-closure");
  I64 bad = 0;
  if (BLoad(PathJoin(dir, "link-inputs-and-archive-members.tsv"), 1) != 0) {
    Fail("MISSING_FILE", "link-inputs-and-archive-members.tsv");
    return 1;
  }
  BHt1Reset(2);
  BHt1Build();
  I64 b_rows = B_NROW;
  if (TsvLoad(PathJoin(dir, "source-target-manifest.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "source-target-manifest.tsv");
    return bad + 1;
  }
  I64 linked = 0;
  I64 r = 0;
  while (r < NROW) {
    if (StrEq(Fld(r, 11), "LINKED")) {
      linked++;
      I64 hit = BHt1Find(Fld(r, 7));
      if (hit < 0) { Fail("MISSING_LINKED_OBJECT", Fld(r, 7)); bad++; }
      else if (!StrEq(BFld(hit, 3), "C_OBJECT")) { Fail("MISSING_LINKED_OBJECT", Fld(r, 7)); bad++; }
      else if (!StrEq(BFld(hit, 4), "YES")) { Fail("MISSING_LINKED_OBJECT", Fld(r, 7)); bad++; }
    }
    r++;
  }
  I64 i = 0;
  while (i < b_rows) {
    if (StrEq(BFld(i, 3), "C_OBJECT")) {
      U8 *obj = BFld(i, 2);
      I64 found = 0;
      I64 k = 0;
      while (k < NROW) {
        if (StrEq(Fld(k, 7), obj)) { found = 1; break; }
        k++;
      }
      if (found == 0) { Fail("NONPRODUCTION_TARGET", obj); bad++; }
    }
    i++;
  }
  "LINKED_C_TUS=%d LINK_INPUT_ROWS=%d\n", linked, b_rows;
  if (bad == 0) Pass("link-closure"); else Fail("LINK_CLOSURE_INVALID", "see rows above");
  return bad;
}


static I64 CheckDormant(U8 *dir) {
  BeginCheck("dormant-polyc");
  if (TsvLoad(PathJoin(dir, "dormant-polyc-sites.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "dormant-polyc-sites.tsv");
    return 1;
  }
  I64 bad = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] < 11) { Fail("MALFORMED_ROW", Fld(r, 4)); bad++; r++; continue; }
    if (!StrEq(Fld(r, 6), "NO")) { Fail("DORMANT_POLYC_AUTHORITY", Fld(r, 4)); bad++; }
    if (!StrEq(Fld(r, 7), "0")) { Fail("DORMANT_POLYC_AUTHORITY", Fld(r, 4)); bad++; }
    if (!StrEq(Fld(r, 8), "0")) { Fail("UNLINKED_POLYC_SYMBOL", Fld(r, 4)); bad++; }
    r++;
  }
  "DORMANT_SITES=%d\n", NROW;
  if (bad == 0) Pass("dormant-polyc"); else Fail("DORMANT_INVALID", "see rows above");
  return bad;
}

// Recompute the mandatory migration edges from the include facts and
// compare them with the declared graph. This is the check that makes a
// removed, reversed, retyped or forged mandatory edge observable.
static I64 CheckMandatoryEdges(U8 *dir) {
  BeginCheck("mandatory-edges");
  if (BLoad(PathJoin(dir, "graph-edges.tsv"), 1) != 0) {
    Fail("MISSING_FILE", "graph-edges.tsv");
    return 1;
  }
  I64 b_rows = B_NROW;
  if (TsvLoad(PathJoin(dir, "include-facts.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "include-facts.tsv");
    return 1;
  }
  I64 bad = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] < 6) { Fail("MALFORMED_ROW", Fld(r, 0)); bad++; r++; continue; }
    U8 *src = Cat2("SYS-", Fld(r, 2));
    U8 *dst = Cat2B("SYS-", Fld(r, 4));
    I64 want = ExpectedEdgeType(Fld(r, 3));
    I64 fwd = -1;
    I64 rev = -1;
    I64 e = 0;
    while (e < b_rows) {
      if (!StrEq(BFld(e, 3), "CALLS")) {
        if (StrEq(BFld(e, 1), src) && StrEq(BFld(e, 2), dst)) {
          if (fwd < 0) fwd = e;
          if (EdgeTypeMatch(BFld(e, 3), want)) fwd = e;
        }
        if (StrEq(BFld(e, 1), dst) && StrEq(BFld(e, 2), src)) rev = e;
      }
      e++;
    }
    if (fwd < 0) {
      if (rev >= 0) { Fail("DEPENDENCY_DIRECTION_ERROR", Fld(r, 3)); bad++; }
      else { Fail("MISSING_REQUIRED_EDGE", Fld(r, 3)); bad++; }
    } else {
      if (!EdgeTypeMatch(BFld(fwd, 3), want)) { Fail("EDGE_TYPE_OR_MANDATORY_MISMATCH", BFld(fwd, 0)); bad++; }
      if (!StrEq(BFld(fwd, 5), "YES")) { Fail("EDGE_TYPE_OR_MANDATORY_MISMATCH", BFld(fwd, 0)); bad++; }
    }
    r++;
  }
  // Forged mandatory edges: every mandatory TYPE/CALLBACK/RECOVERY edge
  // must be produced by at least one include fact.
  I64 e2 = 0;
  while (e2 < b_rows) {
    U8 *t = BFld(e2, 3);
    if (StrEq(BFld(e2, 5), "YES") &&
        (StrEq(t, "TYPE_REPRESENTATION") || StrEq(t, "CALLBACK") || StrEq(t, "RECOVERY"))) {
      I64 found = 0;
      I64 k = 0;
      while (k < NROW) {
        U8 *s2 = Cat2("SYS-", Fld(k, 2));
        U8 *d2 = Cat2B("SYS-", Fld(k, 4));
        if (StrEq(s2, BFld(e2, 1)) && StrEq(d2, BFld(e2, 2))) { found = 1; break; }
        k++;
      }
      if (found == 0) { Fail("EDGE_TYPE_OR_MANDATORY_MISMATCH", BFld(e2, 0)); bad++; }
    }
    e2++;
  }
  "INCLUDE_FACTS=%d MANDATORY_EDGE_CHECKS=%d\n", NROW, b_rows;
  if (bad == 0) Pass("mandatory-edges"); else Fail("MANDATORY_EDGES_INVALID", "see rows above");
  return bad;
}


static I64 CheckRangeHashes(U8 *dir) {
  BeginCheck("source-range-hashes");
  if (BLoad(PathJoin(dir, "functions-raw.tsv"), 1) != 0) {
    Fail("MISSING_FILE", "functions-raw.tsv");
    return 1;
  }
  BHtReset(1, 2); // (path, function)
  BHtBuild();
  I64 b_rows = B_NROW;
  I64 bad = 0;
  I64 checked = 0;
  if (TsvLoad(PathJoin(dir, "authorities.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "authorities.tsv");
    return bad + 1;
  }
  I64 r = 0;
  while (r < NROW) {
    if (StrEq(Fld(r, 18), "C_AUTHORITY")) {
      I64 hit = BHtFind2(Fld(r, 4), Fld(r, 11));
      if (hit < 0) { Fail("MISSING_FUNCTION_BINDING", Fld(r, 0)); bad++; }
      else {
        checked++;
        if (!StrEq(BFld(hit, 8), Fld(r, 10))) {
          // The same function name may be defined more than once in one
          // translation unit; accept any definition whose range matches.
          I64 alt = 0;
          I64 ok = 0;
          while (alt < b_rows) {
            if (StrEq(BFld(alt, 1), Fld(r, 4)) && StrEq(BFld(alt, 2), Fld(r, 11)) &&
                StrEq(BFld(alt, 8), Fld(r, 10))) { ok = 1; break; }
            alt++;
          }
          if (!ok) { Fail("SOURCE_PHASE_HASH_MISMATCH", Fld(r, 0)); bad++; }
        }
      }
    }
    r++;
  }
  "RANGE_HASH_JOINS=%d FUNCTIONS_RAW=%d\n", checked, b_rows;
  if (bad == 0) Pass("source-range-hashes"); else Fail("RANGE_HASH_INVALID", "see rows above");
  return bad;
}

static I64 CheckPolycAuthority(U8 *dir) {
  BeginCheck("polyc-authority");
  I64 pr = BLoad(PathJoin(dir, "nine-authorities-object-proof.tsv"), 1);
  if (pr != 0) { pr = BLoad(PathJoin(dir, "../c0/nine-authorities-object-proof.tsv"), 1); }
  if (pr != 0) {
    Fail("MISSING_FILE", "nine-authorities-object-proof.tsv");
    return 1;
  }
  I64 b_rows = B_NROW;
  I64 bad = 0;
  I64 count = 0;
  if (TsvLoad(PathJoin(dir, "authorities.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "authorities.tsv");
    return bad + 1;
  }
  I64 r = 0;
  while (r < NROW) {
    if (StrEq(Fld(r, 18), "POLYC_AUTHORITY")) {
      count++;
      U8 *sym = Fld(r, 11);
      I64 found = 0;
      I64 k = 0;
      while (k < b_rows) {
        if (StrEq(BFld(k, 1), sym)) {
          if (StrEq(BFld(k, 10), "1") && StrEq(BFld(k, 8), "1")) found = 1;
        }
        k++;
      }
      if (found == 0) { Fail("UNLINKED_POLYC_SYMBOL", sym); bad++; }
    }
    r++;
  }
  "POLYC_AUTHORITY_ROWS=%d OBJECT_PROOF_ROWS=%d\n", count, b_rows;
  if (bad == 0) Pass("polyc-authority"); else Fail("POLYC_AUTHORITY_INVALID", "see rows above");
  return bad;
}

static I64 CheckUnknownEdges(U8 *dir) {
  BeginCheck("unknown-edges");
  I64 n = SnapshotNodes(PathJoin(dir, "graph-nodes.tsv"));
  if (n < 0) { Fail("MISSING_FILE", "graph-nodes.tsv"); return 1; }
  if (TsvLoad(PathJoin(dir, "unknown-edges.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "unknown-edges.tsv");
    return 1;
  }
  I64 bad = 0;
  if (NROW < 4) { Fail("UNRESOLVED_REACHABILITY_EDGE", "unknown-roster-shrunk"); bad++; }
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] < 9) { Fail("MALFORMED_ROW", Fld(r, 0)); bad++; r++; continue; }
    if (NodeIndex(Fld(r, 2)) < 0) { Fail("UNRESOLVED_REACHABILITY_EDGE", Fld(r, 2)); bad++; }
    r++;
  }
  "UNKNOWN_EDGES=%d\n", NROW;
  if (bad == 0) Pass("unknown-edges"); else Fail("UNKNOWN_EDGES_INVALID", "see rows above");
  return bad;
}

static I64 CheckArchiveMembers(U8 *dir) {
  BeginCheck("archive-members");
  if (TsvLoad(PathJoin(dir, "archive-member-linkage.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "archive-member-linkage.tsv");
    return 1;
  }
  I64 total = NROW;
  I64 not_extracted = 0;
  I64 r = 0;
  while (r < NROW) {
    if (StrEq(Fld(r, 4), "NOT_EXTRACTED")) not_extracted++;
    r++;
  }
  I64 bad = 0;
  if (total != 10) { Fail("INCOMPLETE_LINK_INPUT_CLOSURE", "archive-member-count"); bad++; }
  if (not_extracted != 1) { Fail("INCOMPLETE_LINK_INPUT_CLOSURE", "not-extracted-count"); bad++; }
  "ARCHIVE_MEMBERS=%d NOT_EXTRACTED=%d\n", total, not_extracted;
  if (bad == 0) Pass("archive-members"); else Fail("ARCHIVE_MEMBERS_INVALID", "see rows above");
  return bad;
}


// ------------------------------------------------------------------
// GRAPH mode: Tarjan SCC over MANDATORY migration edges, condensation,
// deterministic topological order. CALLS edges are excluded by design:
// an availability call does not force a migration order.
// ------------------------------------------------------------------
static I64 ADJJ[MAX_NODES][MAX_NODES];
static I64 ADJN[MAX_NODES];
static I64 T_IDX[MAX_NODES];
static I64 T_LOW[MAX_NODES];
static I64 T_ON[MAX_NODES];
static I64 T_STK[MAX_NODES];
static I64 T_STKN;
static I64 T_NEXT;
static I64 COMP[MAX_NODES];
static I64 CMM[MAX_NODES][MAX_NODES];
static I64 INDEG[MAX_NODES];
static I64 DONE[MAX_NODES];
static I64 COMPN;

static I64 CmpS(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) {
    if (*a != *b) return *a - *b;
    a++; b++;
  }
  return *a - *b;
}

static U8 *MinIdOfComp(I64 c, I64 n) {
  U8 *m = "~";
  I64 i = 0;
  while (i < n) {
    if (COMP[i] == c) { if (CmpS(NODE_ID[i], m) < 0) m = NODE_ID[i]; }
    i++;
  }
  return m;
}

static I64 StrCmp(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) {
    if (*a != *b) return *a - *b;
    a++; b++;
  }
  return *a - *b;
}

static U0 TarjanVisit(I64 v) {
  T_IDX[v] = T_NEXT; T_LOW[v] = T_NEXT; T_NEXT++;
  T_STK[T_STKN] = v; T_STKN++;
  T_ON[v] = 1;
  I64 i = 0;
  while (i < ADJN[v]) {
    I64 w = ADJJ[v][i];
    if (T_IDX[w] < 0) {
      TarjanVisit(w);
      if (T_LOW[w] < T_LOW[v]) T_LOW[v] = T_LOW[w];
    } else if (T_ON[w]) {
      if (T_IDX[w] < T_LOW[v]) T_LOW[v] = T_IDX[w];
    }
    i++;
  }
  if (T_LOW[v] == T_IDX[v]) {
    while (T_STKN > 0) {
      T_STKN--;
      I64 w = T_STK[T_STKN];
      T_ON[w] = 0;
      COMP[w] = COMPN;
      if (w == v) break;
    }
    COMPN++;
  }
}

static I64 BuildMandatoryGraph(U8 *dir) {
  I64 n = SnapshotNodes(PathJoin(dir, "graph-nodes.tsv"));
  if (n < 0) return -1;
  I64 i = 0;
  while (i < n) { ADJN[i] = 0; i++; }
  if (TsvLoad(PathJoin(dir, "graph-edges.tsv"), 1, 1) != 0) return -1;
  I64 e = 0;
  while (e < G_NROW) {
    if (StrEq(GFld(e, 5), "YES")) {
      I64 s = NodeIndex(GFld(e, 1));
      I64 d = NodeIndex(GFld(e, 2));
      if (s >= 0 && d >= 0 && s != d) {
        ADJN[s]++;
        ADJJ[s][ADJN[s] - 1] = d;
      }
    }
    e++;
  }
  return n;
}

static I64 ComputeScc() {
  I64 i = 0;
  while (i < MAX_NODES) {
    T_IDX[i] = -1; T_LOW[i] = -1; T_ON[i] = 0; COMP[i] = -1;
    i++;
  }
  T_STKN = 0; T_NEXT = 0; COMPN = 0;
  i = 0;
  while (i < NODE_N) {
    if (T_IDX[i] < 0) TarjanVisit(i);
    i++;
  }
  return COMPN;
}

static U8 OUTBUF[262144];
static I64 OUTLEN;

static U0 OutReset() { OUTLEN = 0; }

static U0 OutS(U8 *s) {
  while (*s != 0 && OUTLEN < 262000) { OUTBUF[OUTLEN] = *s; OUTLEN++; s++; }
}

static U0 OutI(I64 v) {
  U8 tmp[32];
  I64 n = 0;
  if (v < 0) { OutS("-"); v = -v; }
  if (v == 0) { OutS("0"); return; }
  while (v > 0) { tmp[n] = '0' + (v % 10); n++; v = v / 10; }
  while (n > 0) { n--; OUTBUF[OUTLEN] = tmp[n]; OUTLEN++; }
}

static U0 OutFlush(U8 *path) {
  FileWrite(path, OUTBUF, OUTLEN, O_CREAT | O_RDWR | O_TRUNC);
}

static I64 GraphMode(U8 *dir, U8 *outdir) {
  BeginCheck("graph");
  I64 n = BuildMandatoryGraph(dir);
  if (n < 0) { Fail("MISSING_FILE", "graph inputs"); return 1; }
  I64 comps = ComputeScc();
  "MANDATORY_EDGES=%d NODES=%d SCCS=%d\n", G_NROW, n, comps;
  // scc-members.tsv
  OutReset();
  OutS("scc_id\tnode_id\tmember_index\n");
  I64 c = 0;
  while (c < comps) {
    I64 i = 0;
    I64 k = 0;
    while (i < n) {
      if (COMP[i] == c) {
        OutS("SCC-"); OutI(c + 1); OutS("\t");
        OutS(NODE_ID[i]); OutS("\t"); OutI(k); OutS("\n");
        k++;
      }
      i++;
    }
    c++;
  }
  U8 *p1 = PathJoin(outdir, "scc-members.tsv");
  OutFlush(p1);
  // condensed DAG
  I64 dummy = 0;
  I64 a = 0;
  while (a < MAX_NODES) { I64 b = 0; while (b < MAX_NODES) { CMM[a][b] = 0; b++; } a++; }
  I64 e = 0;
  while (e < G_NROW) {
    if (StrEq(GFld(e, 5), "YES")) {
      I64 s = NodeIndex(GFld(e, 1));
      I64 d = NodeIndex(GFld(e, 2));
      if (s >= 0 && d >= 0 && COMP[s] != COMP[d]) CMM[COMP[s]][COMP[d]] = 1;
    }
    e++;
  }
  OutReset();
  OutS("edge_id\tsrc_scc\tdst_scc\n");
  I64 ne = 0;
  a = 0;
  while (a < comps) {
    I64 b = 0;
    while (b < comps) {
      if (CMM[a][b]) {
        OutS("CSCC-"); OutI(a + 1); OutS("-"); OutI(b + 1);
        OutS("\tSCC-"); OutI(a + 1); OutS("\tSCC-"); OutI(b + 1);
        OutS("\n");
        ne++;
      }
      b++;
    }
    a++;
  }
  OutFlush(PathJoin(outdir, "condensed-migration-dag.tsv"));
  "CONDENSED_EDGES=%d\n", ne;
  // deterministic topological order: Kahn, smallest representative id first
  I64 i = 0;
  while (i < comps) { INDEG[i] = 0; DONE[i] = 0; i++; }
  a = 0;
  while (a < comps) {
    I64 b = 0;
    while (b < comps) { if (CMM[a][b]) INDEG[b]++; b++; }
    a++;
  }
  OutReset();
  OutS("order\tscc_id\trepresentative_node\tmember_count\n");
  I64 ord = 0;
  while (ord < comps) {
    I64 best = -1;
    I64 c2 = 0;
    while (c2 < comps) {
      if (DONE[c2] == 0 && INDEG[c2] == 0) {
        if (best < 0) best = c2;
        else if (StrCmp(MinIdOfComp(c2, n), MinIdOfComp(best, n)) < 0) best = c2;
      }
      c2++;
    }
    if (best < 0) { Fail("GRAPH_EDGE_OR_SCC", "cycle-in-condensation"); return 1; }
    DONE[best] = 1;
    I64 cnt = 0;
    I64 rep = -1;
    i = 0;
    while (i < n) {
      if (COMP[i] == best) {
        cnt++;
        if (rep < 0) rep = i;
        else if (StrCmp(NODE_ID[i], NODE_ID[rep]) < 0) rep = i;
      }
      i++;
    }
    OutI(ord + 1); OutS("\tSCC-"); OutI(best + 1);
    OutS("\t"); OutS(NODE_ID[rep]); OutS("\t"); OutI(cnt); OutS("\n");
    I64 b = 0;
    while (b < comps) { if (CMM[best][b]) INDEG[b]--; b++; }
    ord++;
  }
  OutFlush(PathJoin(outdir, "topological-order.tsv"));
  "TOPOLOGICAL_ORDER=%d\n", ord;
  Pass("graph");
  return 0;
}


// ------------------------------------------------------------------
// FORECAST mode. The cost model is an explicit assumption table, not a
// measured quantity; forecast-assumptions.tsv records every constant.
// ------------------------------------------------------------------
static I64 CeilDiv(I64 a, I64 b) {
  if (b <= 0) return 0;
  if (a <= 0) return 0;
  return (a + b - 1) / b;
}

static I64 NODE_AUTH[MAX_NODES];
static I64 NODE_FN[MAX_NODES];
static I64 NODE_HIGH[MAX_NODES];
static I64 NODE_OWNER_C[MAX_NODES];

static U0 FillNodeMeta(U8 *dir) {
  I64 i = 0;
  while (i < NODE_N) { NODE_AUTH[i] = 0; NODE_FN[i] = 0; NODE_HIGH[i] = 0; NODE_OWNER_C[i] = 0; i++; }
  LoadNodes(PathJoin(dir, "graph-nodes.tsv"));
  i = 0;
  while (i < G_NROW && i < NODE_N) {
    NODE_AUTH[i] = ParseInt(GFld(i, 8));
    NODE_FN[i] = ParseInt(GFld(i, 9));
    if (StrEq(GFld(i, 5), "HIGH")) NODE_HIGH[i] = 1;
    if (StrEq(GFld(i, 2), "C_AUTHORITY")) NODE_OWNER_C[i] = 1;
    i++;
  }
}

static I64 B_SITES[MAX_NODES];
static I64 B_FN[MAX_NODES];
static I64 B_HIGH[MAX_NODES];
static I64 B_MEMBERS[MAX_NODES];
static I64 B_LOW[MAX_NODES];
static I64 B_BASE[MAX_NODES];
static I64 B_HIGHV[MAX_NODES];
static I64 B_IMPL[MAX_NODES];
static I64 B_INTEG[MAX_NODES];
static I64 B_PROOF[MAX_NODES];
static I64 B_CORR[MAX_NODES];

static I64 ComputeBundles() {
  I64 comps = COMPN;
  I64 c = 0;
  while (c < comps) {
    B_SITES[c] = 0; B_FN[c] = 0; B_HIGH[c] = 0; B_MEMBERS[c] = 0;
    I64 i = 0;
    while (i < NODE_N) {
      if (COMP[i] == c && NODE_OWNER_C[i]) {
        B_MEMBERS[c]++;
        B_SITES[c] += NODE_AUTH[i];
        B_FN[c] += NODE_FN[i];
        if (NODE_HIGH[i]) B_HIGH[c] = 1;
      }
      i++;
    }
    I64 impl = CeilDiv(B_SITES[c], 12);
    if (impl < 1) impl = 1;
    I64 integ = 1;
    I64 proof = 1;
    I64 corr = CeilDiv((impl + integ) * 44, 100);
    I64 base = 1 + impl + integ + proof + corr;
    if (B_HIGH[c]) base = CeilDiv(base * 125, 100);
    I64 lo_impl = CeilDiv(B_SITES[c], 20);
    if (lo_impl < 1) lo_impl = 1;
    I64 lo = 1 + lo_impl + 1 + 1 + CeilDiv((lo_impl + 1) * 25, 100);
    I64 hi_impl = CeilDiv(B_SITES[c], 6);
    if (hi_impl < 1) hi_impl = 1;
    I64 hi = 1 + hi_impl + 1 + 1 + CeilDiv((hi_impl + 1) * 65, 100);
    hi = CeilDiv(hi * 150, 100);
    B_IMPL[c] = impl; B_INTEG[c] = integ; B_PROOF[c] = proof; B_CORR[c] = corr;
    B_BASE[c] = base; B_LOW[c] = lo; B_HIGHV[c] = hi;
    c++;
  }
  return comps;
}


static I64 ForecastMode(U8 *dir, U8 *outdir) {
  BeginCheck("forecast");
  I64 n = BuildMandatoryGraph(dir);
  if (n < 0) { Fail("MISSING_FILE", "graph inputs"); return 1; }
  ComputeScc();
  FillNodeMeta(dir);
  I64 comps = ComputeBundles();
  I64 c = 0;
  I64 bundles = 0;
  I64 sum_low = 0, sum_base = 0, sum_high = 0;
  I64 sum_impl = 0, sum_integ = 0, sum_proof = 0, sum_corr = 0;
  while (c < comps) {
    if (B_MEMBERS[c] > 0) {
      bundles++;
      sum_low += B_LOW[c]; sum_base += B_BASE[c]; sum_high += B_HIGHV[c];
      sum_impl += B_IMPL[c]; sum_integ += B_INTEG[c];
      sum_proof += B_PROOF[c]; sum_corr += B_CORR[c];
    }
    c++;
  }
  OutReset();
  OutS("bundle_id\tscc_id\tmembers\tc_decision_sites\tfunctions\thigh_relevance\tact_low\tact_base\tact_high\tabi_plan\thost_state_boundary\tevidence\n");
  c = 0;
  I64 bi = 0;
  while (c < comps) {
    if (B_MEMBERS[c] > 0) {
      bi++;
      OutS("B-"); OutI(bi); OutS("\tSCC-"); OutI(c + 1);
      OutS("\t"); OutI(B_MEMBERS[c]);
      OutS("\t"); OutI(B_SITES[c]);
      OutS("\t"); OutI(B_FN[c]);
      OutS("\t"); OutI(B_HIGH[c]);
      OutS("\t"); OutI(B_LOW[c]);
      OutS("\t"); OutI(B_BASE[c]);
      OutS("\t"); OutI(B_HIGHV[c]);
      OutS("\tSCALAR_ABI_PLUS_OWNED_STATE_HANDLE\tSTATE_HANDLE_REQUIRED\tc2/forecast-assumptions.tsv\n");
    }
    c++;
  }
  OutFlush(PathJoin(outdir, "migration-bundles.tsv"));
  OutReset();
  OutS("bundle_id\tscc_id\tnode_id\tauthority_count\n");
  c = 0;
  bi = 0;
  while (c < comps) {
    if (B_MEMBERS[c] > 0) {
      bi++;
      I64 i = 0;
      while (i < n) {
        if (COMP[i] == c && NODE_OWNER_C[i]) {
          OutS("B-"); OutI(bi); OutS("\tSCC-"); OutI(c + 1);
          OutS("\t"); OutS(NODE_ID[i]); OutS("\t"); OutI(NODE_AUTH[i]);
          OutS("\n");
        }
        i++;
      }
    }
    c++;
  }
  OutFlush(PathJoin(outdir, "bundle-members.tsv"));
  I64 P_ABI_LOW = 2, P_ABI_BASE = 3, P_ABI_HIGH = 5;
  I64 P_BLK_LOW = 3, P_BLK_BASE = 4, P_BLK_HIGH = 8;
  I64 P_GEN_LOW = 2, P_GEN_BASE = 3, P_GEN_HIGH = 5;
  I64 P_CONV_LOW = 2, P_CONV_BASE = 3, P_CONV_HIGH = 6;
  I64 m1_low = sum_low + P_ABI_LOW;
  I64 m1_base = sum_base + P_ABI_BASE;
  I64 m1_high = sum_high + P_ABI_HIGH;
  I64 m2_low = m1_low + P_BLK_LOW + P_GEN_LOW;
  I64 m2_base = m1_base + P_BLK_BASE + P_GEN_BASE;
  I64 m2_high = m1_high + P_BLK_HIGH + P_GEN_HIGH;
  I64 m3_low = m2_low + P_CONV_LOW;
  I64 m3_base = m2_base + P_CONV_BASE;
  I64 m3_high = m2_high + P_CONV_HIGH;
  I64 m4_low = m3_low + CeilDiv(m2_low * 25, 100);
  I64 m4_base = m3_base + CeilDiv(m2_base * 25, 100);
  I64 m4_high = m3_high + CeilDiv(m2_high * 25, 100);


  OutReset();
  U8 *verdict = "UNPROVEN";
  if (m2_base < 100) verdict = "SUPPORTED";
  else if (m2_low >= 100) verdict = "NOT_SUPPORTED";
  OutS("milestone\tact_low\tact_base\tact_high\tselection_acts\timplementation_acts\tintegration_abi_acts\tbootstrap_acts\tcorrection_acts\tshared_infrastructure_acts\ttotal_effort_sum\tcritical_path_length\tassumptions_ref\n");
  OutS("M1\t"); OutI(m1_low); OutS("\t"); OutI(m1_base); OutS("\t"); OutI(m1_high);
  OutS("\t"); OutI(bundles); OutS("\t"); OutI(sum_impl); OutS("\t"); OutI(sum_integ);
  OutS("\t"); OutI(sum_proof); OutS("\t"); OutI(sum_corr);
  OutS("\t"); OutI(P_ABI_BASE); OutS("\t"); OutI(m1_base);
  OutS("\t"); OutI(m1_base); OutS("\tc2/forecast-assumptions.tsv\n");
  OutS("M2\t"); OutI(m2_low); OutS("\t"); OutI(m2_base); OutS("\t"); OutI(m2_high);
  OutS("\t"); OutI(bundles); OutS("\t"); OutI(sum_impl); OutS("\t"); OutI(sum_integ);
  OutS("\t"); OutI(sum_proof + P_BLK_BASE + P_GEN_BASE); OutS("\t"); OutI(sum_corr);
  OutS("\t"); OutI(P_ABI_BASE); OutS("\t"); OutI(m2_base);
  OutS("\t"); OutI(m2_base); OutS("\tc2/forecast-assumptions.tsv\n");
  OutS("M3\t"); OutI(m3_low); OutS("\t"); OutI(m3_base); OutS("\t"); OutI(m3_high);
  OutS("\t"); OutI(bundles); OutS("\t"); OutI(sum_impl); OutS("\t"); OutI(sum_integ);
  OutS("\t"); OutI(sum_proof + P_BLK_BASE + P_GEN_BASE + P_CONV_BASE); OutS("\t"); OutI(sum_corr);
  OutS("\t"); OutI(P_ABI_BASE); OutS("\t"); OutI(m3_base);
  OutS("\t"); OutI(m3_base); OutS("\tc2/forecast-assumptions.tsv\n");
  OutS("M4\t"); OutI(m4_low); OutS("\t"); OutI(m4_base); OutS("\t"); OutI(m4_high);
  OutS("\t"); OutI(bundles); OutS("\t"); OutI(sum_impl); OutS("\t"); OutI(sum_integ);
  OutS("\t"); OutI(sum_proof + P_BLK_BASE + P_GEN_BASE + P_CONV_BASE); OutS("\t"); OutI(sum_corr);
  OutS("\t"); OutI(P_ABI_BASE); OutS("\t"); OutI(m4_base);
  OutS("\t"); OutI(m4_base); OutS("\tc2/forecast-assumptions.tsv\n");
  OutS("M2_BELOW_100_ACTS\t"); OutS(verdict); OutS("\t\t\t\t\t\t\t\t\t\t\tc2/forecast-assumptions.tsv\n");
  I64 unkcount = 0;
  I64 ui = 0;
  while (ui < NODE_N) {
    if (StrNCmp(NODE_ID[ui], "UNK-", 4) == 0) unkcount++;
    ui++;
  }
  OutS("UNKNOWN_NODES\t"); OutI(unkcount); OutS("\t\t\t\t\t\t\t\t\t\t\tc2/forecast-assumptions.tsv\n");
  OutFlush(PathJoin(outdir, "forecast.tsv"));
  OutReset();
  OutS("scenario\tbundle_count\tact_low\tact_base\tact_high\tnote\n");
  OutS("ONE_DECISION_PER_ACT\t"); OutI(sum_impl + sum_integ); OutS("\t");
  OutI(sum_impl + sum_integ); OutS("\t"); OutI(sum_impl + sum_integ);
  OutS("\tper-decision transfer at the historical parser rate; an upper bound, not a plan\n");
  OutS("COHERENT_BUNDLES\t"); OutI(bundles); OutS("\t"); OutI(m1_low); OutS("\t");
  OutI(m1_base); OutS("\t"); OutI(m1_high); OutS("\tthe recommended programme shape\n");
  OutS("HIGH_RISK_FALLBACK\t"); OutI(bundles); OutS("\t"); OutI(m2_low); OutS("\t");
  OutI(m2_base); OutS("\t"); OutI(m2_high); OutS("\tall bundles plus bootstrap blockers\n");
  OutFlush(PathJoin(outdir, "migration-scenarios.tsv"));
  "BUNDLES=%d M1=%d/%d/%d M2=%d/%d/%d M3=%d/%d/%d M4=%d/%d/%d\n",
    bundles, m1_low, m1_base, m1_high, m2_low, m2_base, m2_high,
    m3_low, m3_base, m3_high, m4_low, m4_base, m4_high;
  "M2_BELOW_100_ACTS=%s\n", verdict;
  Pass("forecast");
  return 0;
}

static I64 RunSchema(U8 *dir) {
  I64 bad = 0;
  bad += CheckAuthorities(dir);
  bad += CheckCoverage(dir);
  bad += CheckNodesEdges(dir);
  bad += CheckLinkClosure(dir);
  bad += CheckDormant(dir);
  bad += CheckMandatoryEdges(dir);
  bad += CheckRangeHashes(dir);
  bad += CheckPolycAuthority(dir);
  bad += CheckUnknownEdges(dir);
  bad += CheckArchiveMembers(dir);
  "SCHEMA_CHECKS=%d DETECTORS_FIRED=%d\n", CHECKS, FAILS;
  if (bad == 0) { "SCHEMA_STATUS=PASS\n"; return 0; }
  "SCHEMA_STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// SELFTEST: known answers for the arithmetic, comparator and vocabulary.
// ------------------------------------------------------------------
static I64 SelfTest() {
  I64 fail = 0;
  if (CeilDiv(0, 12) != 0) fail++;
  if (CeilDiv(1, 12) != 1) fail++;
  if (CeilDiv(12, 12) != 1) fail++;
  if (CeilDiv(13, 12) != 2) fail++;
  if (CeilDiv(25, 2) != 13) fail++;
  if (ParseInt("42") != 42) fail++;
  if (ParseInt("-7") != -7) fail++;
  if (ParseInt("x") != 0) fail++;
  if (StrCmp("a", "b") >= 0) fail++;
  if (StrCmp("b", "a") <= 0) fail++;
  if (StrCmp("a", "a") != 0) fail++;
  if (!IsStatus("AUTHORITY_COARSE")) fail++;
  if (IsStatus("NOT_A_STATUS")) fail++;
  if (!IsOwnerClass("POLYC_AUTHORITY")) fail++;
  if (IsOwnerClass("SOMETHING_ELSE")) fail++;
  if (HashStr("a") == HashStr("b")) fail++;
  if (ExpectedEdgeType("cctrl.h") != 3) fail++;
  if (ExpectedEdgeType("containers.h") != 2) fail++;
  if (ExpectedEdgeType("ast.h") != 1) fail++;
  U8 *p = PathJoin("a/b", "c.tsv");
  if (!StrEq(p, "a/b/c.tsv")) fail++;
  U8 *k = Key2("x", "y");
  if (!StrEq(k, "x|y")) fail++;
  "SELFTEST_CASES=19 SELFTEST_FAIL=%d\n", fail;
  if (fail == 0) { "SELFTEST_STATUS=PASS\n"; return 0; }
  "SELFTEST_STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// CONTROL helpers: mutate injected copies, then run the real detectors.
// ------------------------------------------------------------------
static U8 *FILES[24];
static I64 NFILES;

static U0 InitFileList() {
  FILES[0] = "authorities.tsv";
  FILES[1] = "semantic-coverage.tsv";
  FILES[2] = "graph-nodes.tsv";
  FILES[3] = "graph-edges.tsv";
  FILES[4] = "unknown-edges.tsv";
  FILES[5] = "functions-raw.tsv";
  FILES[6] = "source-target-manifest.tsv";
  FILES[7] = "link-inputs-and-archive-members.tsv";
  FILES[8] = "archive-member-linkage.tsv";
  FILES[9] = "dormant-polyc-sites.tsv";
  FILES[10] = "polyc-subject-manifest.tsv";
  FILES[11] = "include-facts.tsv";
  FILES[12] = "compiler-generation-chain.tsv";
  FILES[13] = "bootstrap-blockers.tsv";
  FILES[14] = "migration-bundles.tsv";
  FILES[15] = "forecast.tsv";
  FILES[16] = "bootstrap-milestones.tsv";
  NFILES = 17;
}

static I64 CopyOne(U8 *src, U8 *dst) {
  I64 sz = 0;
  U8 *buf = FileRead(src, &sz);
  if (buf == NULL) return -1;
  FileWrite(dst, buf, sz, O_CREAT | O_RDWR | O_TRUNC);
  return 0;
}


// Write a mutated copy of one file: rows are rewritten, with the first row
// satisfying (col == value) deleted, or row 'rowidx' modified.
static U0 MutWrite(U8 *path, I64 op, I64 rowidx, I64 col, U8 *value) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) return;
  U8 *out = MAlloc(sz + 8192);
  I64 o = 0;
  U8 *p = buf;
  U8 *end = buf + sz;
  I64 dataidx = -1;
  I64 first = 1;
  I64 done = 0;
  while (p < end) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    I64 len = le - ls;
    I64 is_data = 1;
    if (len == 0) is_data = 0;
    if (len > 0 && *ls == '#') is_data = 0;
    if (is_data && first) { first = 0; is_data = 0; } // header
    if (is_data) dataidx++;
    I64 handled = 0;
    if (is_data && op == 1) {
      // delete first row whose field[col] equals value (or first data row)
      if (!done) {
        I64 match = 0;
        if (*value == 0) match = 1;
        else {
          I64 f = 0;
          U8 *q = ls;
          while (f < col && q < le) { while (q < le && *q != '\t') q++; if (q < le) q++; f++; }
          U8 *s2 = q;
          while (q < le && *q != '\t') q++;
          I64 fl = q - s2;
          if (fl == StrLen(value) && StrNCmp(s2, value, fl) == 0) match = 1;
        }
        if (match) { done = 1; handled = 1; }
      }
    }
    if (handled) continue;
    if (is_data && op == 3 && dataidx == rowidx) {
      // Set field col to value, preserving every other field.
      I64 c2 = 0;
      U8 *q2 = ls;
      while (1) {
        U8 *s2 = q2;
        while (q2 < le && *q2 != '\t') q2++;
        if (c2 == col) {
          U8 *v = value;
          while (*v != 0 && o < sz + 8000) { out[o] = *v; o++; v++; }
        } else {
          U8 *t = s2;
          while (t < q2) { out[o] = *t; o++; t++; }
        }
        if (q2 < le && *q2 == '\t') {
          if (o < sz + 8000) { out[o] = '\t'; o++; }
          q2++; c2++; continue;
        }
        break;
      }
      if (o < sz + 8000) { out[o] = '\n'; o++; }
      handled = 1;
    }
    if (handled) continue;
    U8 *t = ls;
    while (t < le) { out[o] = *t; o++; t++; }
    if (o < sz + 8000) { out[o] = '\n'; o++; }
    if (is_data && op == 2 && dataidx == rowidx) {
      // duplicate this row
      t = ls;
      while (t < le) { out[o] = *t; o++; t++; }
      if (o < sz + 8000) { out[o] = '\n'; o++; }
    }
  }
  if (op == 4) {
    U8 *v = value;
    while (*v != 0) { out[o] = *v; o++; v++; }
    out[o] = '\n'; o++;
  }
  FileWrite(path, out, o, O_CREAT | O_RDWR | O_TRUNC);
  Free(out);
}

// ------------------------------------------------------------------
// Consistency checks over the derived c2 artefacts (bundles, forecast,
// generation chain, blockers). Used by SCHEMA when the files exist and
// by CONTROL after a mutation.
// ------------------------------------------------------------------

static I64 CheckBlockers(U8 *dir) {
  BeginCheck("bootstrap-blockers");
  I64 psz = 0;
  U8 *probe = FileRead(PathJoin(dir, "bootstrap-blockers.tsv"), &psz);
  if (probe == NULL) { "CHECK=bootstrap-blockers STATUS=SKIPPED\n"; return 0; }
  if (TsvLoad(PathJoin(dir, "bootstrap-blockers.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "bootstrap-blockers.tsv");
    return 1;
  }
  U8 *need[4];
  need[0] = "BB-01";
  need[1] = "BB-02";
  need[2] = "BB-03";
  need[3] = "BB-04";
  I64 bad = 0;
  I64 k = 0;
  while (k < 4) {
    I64 found = 0;
    I64 r = 0;
    while (r < NROW) {
      if (StrEq(Fld(r, 0), need[k])) found = 1;
      r++;
    }
    if (found == 0) { Fail("MISSING_BOOTSTRAP_BLOCKER", need[k]); bad++; }
    k++;
  }
  "BLOCKER_ROWS=%d\n", NROW;
  if (bad == 0) Pass("bootstrap-blockers"); else Fail("BLOCKERS_INVALID", "see rows above");
  return bad;
}

static I64 CheckGlue(U8 *dir) {
  BeginCheck("allowed-glue");
  I64 psz = 0;
  U8 *probe = FileRead(PathJoin(dir, "bootstrap-milestones.tsv"), &psz);
  if (probe == NULL) { "CHECK=allowed-glue STATUS=SKIPPED\n"; return 0; }
  I64 n = SnapshotNodes(PathJoin(dir, "graph-nodes.tsv"));
  if (n < 0) { Fail("MISSING_FILE", "graph-nodes.tsv"); return 1; }
  if (TsvLoad(PathJoin(dir, "bootstrap-milestones.tsv"), 0, 1) != 0) {
    Fail("MISSING_FILE", "bootstrap-milestones.tsv");
    return 1;
  }
  I64 bad = 0;
  I64 r = 0;
  while (r < NROW) {
    if (StrEq(Fld(r, 2), "ALLOWED_GLUE")) {
      I64 idx = NodeIndex(Fld(r, 0));
      if (idx >= 0) {
        I64 nrow2 = 0;
        while (nrow2 < G_NROW) {
          if (StrEq(GFld(nrow2, 0), Fld(r, 0))) {
            if (ParseInt(GFld(nrow2, 8)) != 0) { Fail("SEMANTIC_C_MASQUERADING_AS_GLUE", Fld(r, 0)); bad++; }
          }
          nrow2++;
        }
      }
      if (idx < 0) { Fail("SEMANTIC_C_MASQUERADING_AS_GLUE", Fld(r, 0)); bad++; }
    }
    r++;
  }
  "MILESTONE_ROWS=%d\n", NROW;
  if (bad == 0) Pass("allowed-glue"); else Fail("GLUE_INVALID", "see rows above");
  return bad;
}

static I64 CheckDerived(U8 *dir) {
  BeginCheck("derived-artefacts");
  I64 psz = 0;
  U8 *probe = FileRead(PathJoin(dir, "migration-bundles.tsv"), &psz);
  if (probe == NULL) { "CHECK=derived-artefacts STATUS=SKIPPED\n"; return 0; }
  I64 bad = 0;
  I64 r = BLoad(PathJoin(dir, "migration-bundles.tsv"), 1);
  if (r == 0) {
    I64 i = 0;
    while (i < B_NROW) {
      I64 j = i + 1;
      while (j < B_NROW) {
        if (StrEq(BFld(i, 0), BFld(j, 0))) { Fail("FORECAST_DOUBLE_COUNT", BFld(i, 0)); bad++; }
        j++;
      }
      if (StrEq(BFld(i, 9), "PURE_SCALAR")) { Fail("UNBOUNDED_STATE_BOUNDARY", BFld(i, 0)); bad++; }
      i++;
    }
    "BUNDLE_ROWS=%d\n", B_NROW;
  }
  // forecast arithmetic, unknown propagation and claim consistency
  r = TsvLoad(PathJoin(dir, "forecast.tsv"), 0, 1);
  if (r == 0) {
    I64 m1_base = -1;
    I64 m2_base = -1;
    I64 m2_low = -1;
    I64 recorded_unk = -1;
    I64 claim_supported = -1;
    I64 i = 0;
    while (i < NROW) {
      if (StrEq(Fld(i, 0), "M1")) m1_base = ParseInt(Fld(i, 2));
      if (StrEq(Fld(i, 0), "M2")) { m2_base = ParseInt(Fld(i, 2)); m2_low = ParseInt(Fld(i, 1)); }
      if (StrEq(Fld(i, 0), "UNKNOWN_NODES")) recorded_unk = ParseInt(Fld(i, 1));
      if (StrEq(Fld(i, 0), "M2_BELOW_100_ACTS")) {
        if (StrEq(Fld(i, 1), "SUPPORTED")) claim_supported = 1;
        else claim_supported = 0;
      }
      i++;
    }
    if (m1_base >= 0 && m2_base >= 0 && m2_base < m1_base) {
      Fail("FORECAST_CRITICAL_PATH_VIOLATION", "M2-below-M1"); bad++;
    }
    // UNKNOWN propagation: the recorded count must equal the UNK-* nodes.
    I64 unk = 0;
    I64 n2 = SnapshotNodes(PathJoin(dir, "graph-nodes.tsv"));
    I64 k = 0;
    while (k < n2) {
      if (StrNCmp(NODE_ID[k], "UNK-", 4) == 0) unk++;
      k++;
    }
    if (recorded_unk >= 0 && unk != recorded_unk) {
      Fail("UNKNOWN_NOT_PROPAGATED", "unknown-count"); bad++;
    }
    if (claim_supported >= 0 && m2_base >= 0) {
      I64 truth = 0;
      if (m2_base < 100) truth = 1;
      if (claim_supported != truth) { Fail("UNSUPPORTED_BELOW_100_CLAIM", "M2_BELOW_100_ACTS"); bad++; }
    }
    "FORECAST_ROWS=%d M1_BASE=%d M2_BASE=%d M2_LOW=%d UNKNOWN_RECORDED=%d\n",
      NROW, m1_base, m2_base, m2_low, recorded_unk;
  }
  // generation-chain claims and producer/output identity
  r = TsvLoad(PathJoin(dir, "compiler-generation-chain.tsv"), 0, 1);
  if (r == 0) {
    I64 i = 0;
    while (i < NROW) {
      I64 j = i + 1;
      while (j < NROW) {
        if (*Fld(i, 6) != 0 && StrEq(Fld(i, 6), Fld(j, 6)) &&
            StrNCmp(Fld(i, 7), "B1_", 3) == 0) {
          Fail("PRODUCER_IDENTITY_COLLISION", Fld(i, 0)); bad++;
        }
        j++;
      }
      if (StrNCmp(Fld(i, 7), "B5_", 3) == 0 && StrEq(Fld(i, 5), "NONE")) {
        Fail("HYBRID_NOT_SELFHOSTED", Fld(i, 0)); bad++;
      }
      i++;
    }
    "GENERATION_ROWS=%d\n", NROW;
  }
  if (bad == 0) Pass("derived-artefacts"); else Fail("DERIVED_INVALID", "see rows above");
  return bad;
}

// ------------------------------------------------------------------
// SCC comparison against a supplied prior partition (WC-DG-04).
// ------------------------------------------------------------------
static I64 COMP_PRIOR[MAX_NODES];

static I64 GraphCompare(U8 *dir, U8 *priorPath) {
  BeginCheck("scc-prior");
  I64 n = BuildMandatoryGraph(dir);
  if (n < 0) { Fail("MISSING_FILE", "graph inputs"); return 1; }
  ComputeScc();
  if (BLoad(priorPath, 1) != 0) { Fail("MISSING_FILE", priorPath); return 1; }
  I64 i = 0;
  while (i < NODE_N) { COMP_PRIOR[i] = -1; i++; }
  I64 r = 0;
  while (r < B_NROW) {
    I64 idx = NodeIndex(BFld(r, 1));
    if (idx >= 0) COMP_PRIOR[idx] = ParseInt(BFld(r, 0));
    r++;
  }
  I64 bad = 0;
  i = 0;
  while (i < NODE_N) {
    I64 j = i + 1;
    while (j < NODE_N) {
      I64 same_now = 0;
      I64 same_prior = 0;
      if (COMP[i] == COMP[j]) same_now = 1;
      if (COMP_PRIOR[i] >= 0 && COMP_PRIOR[i] == COMP_PRIOR[j]) same_prior = 1;
      if (same_now != same_prior) { Fail("SCC_RECOMPUTE_MISMATCH", NODE_ID[i]); bad++; }
      j++;
    }
    i++;
  }
  "SCC_PARTITION_NODES=%d PRIOR_ROWS=%d\n", NODE_N, B_NROW;
  if (bad == 0) Pass("scc-prior"); else Fail("SCC_PRIOR_INVALID", "see rows above");
  return bad;
}

static U0 SwapSrcDst(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) return;
  U8 *out = MAlloc(sz + 4096);
  I64 o = 0;
  U8 *p = buf;
  U8 *end = buf + sz;
  I64 done = 0;
  I64 first = 1;
  while (p < end) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    I64 isdata = 1;
    if (le == ls || *ls == '#') isdata = 0;
    if (isdata && first) { first = 0; isdata = 0; }
    if (isdata && !done) {
      U8 *q = ls;
      I64 f = 0;
      U8 *f1 = ls;
      U8 *f1e = ls;
      U8 *f2 = ls;
      U8 *f2e = ls;
      I64 mandatory = 0;
      while (q <= le) {
        U8 *s2 = q;
        while (q < le && *q != '\t') q++;
        if (f == 1) { f1 = s2; f1e = q; }
        if (f == 2) { f2 = s2; f2e = q; }
        if (f == 5 && (q - s2) == 3 && StrNCmp(s2, "YES", 3) == 0) mandatory = 1;
        if (q < le && *q == '\t') q++; else break;
        f++;
      }
      if (mandatory) {
        U8 *t = ls;
        while (t < f1) { out[o] = *t; o++; t++; }
        t = f2;
        while (t < f2e) { out[o] = *t; o++; t++; }
        out[o] = '\t'; o++;
        t = f1;
        while (t < f1e) { out[o] = *t; o++; t++; }
        t = f2e;
        while (t < le) { out[o] = *t; o++; t++; }
        out[o] = '\n'; o++;
        done = 1;
        continue;
      }
    }
    U8 *t = ls;
    while (t < le) { out[o] = *t; o++; t++; }
    out[o] = '\n'; o++;
  }
  FileWrite(path, out, o, O_CREAT | O_RDWR | O_TRUNC);
  Free(out);
}


static U8 ALT[1024];
static U0 SetAlt(U8 *s) {
  I64 i = 0;
  while (*s != 0 && i < 1023) { ALT[i] = *s; i++; s++; }
  ALT[i] = 0;
}
static U8 SBUF[1024];
static U0 SnapPath(U8 *s) {
  I64 i = 0;
  while (*s != 0 && i < 1023) { SBUF[i] = *s; i++; s++; }
  SBUF[i] = 0;
}
static U0 CopyCensus(U8 *src, U8 *dst, I64 extra) {
  I64 i = 0;
  while (i < NFILES) {
    SnapPath(PathJoin(src, FILES[i]));
    I64 ok = CopyOne(SBUF, PathJoin(dst, FILES[i]));
    if (ok != 0 && extra > 0) {
      SnapPath(PathJoin(ALT, FILES[i]));
      CopyOne(SBUF, PathJoin(dst, FILES[i]));
    }
    i++;
  }
}
static I64 ControlMode(U8 *id, U8 *srcdir, U8 *workdir) {
  InitFileList();
  SetAlt(PathJoin(srcdir, "../c2"));
  { U8 *pp = PathJoin(srcdir, "../c0/nine-authorities-object-proof.tsv"); SnapPath(pp); CopyOne(SBUF, PathJoin(workdir, "nine-authorities-object-proof.tsv")); }
  CopyCensus(srcdir, workdir, 1);
  U8 *cls = "";
  I64 op = 0;
  I64 row = 0;
  I64 col = 0;
  U8 *val = "";
  U8 *file = "";
  I64 special = 0;
  if (StrEq(id, "WC-IC-01")) { file = "link-inputs-and-archive-members.tsv"; op = 1; col = 3; val = "C_OBJECT"; cls = "MISSING_LINKED_OBJECT"; }
  else if (StrEq(id, "WC-IC-02")) { file = "link-inputs-and-archive-members.tsv"; op = 4; val = "LI-FORGED\tsrc/tests/test-runner\tbuild/test-runner\tC_OBJECT\tYES\thcc\tCFG-PROD-HCC-JIT-ON\tforged"; cls = "NONPRODUCTION_TARGET"; }
  else if (StrEq(id, "WC-IC-03")) { file = "authorities.tsv"; op = 2; row = 0; cls = "DUPLICATE_AUTHORITY_ID"; }
  else if (StrEq(id, "WC-IC-04")) { file = "authorities.tsv"; op = 3; row = 0; col = 10; val = "0000000000000000000000000000000000000000000000000000000000000000"; cls = "SOURCE_PHASE_HASH_MISMATCH"; }
  else if (StrEq(id, "WC-IC-05")) { file = "archive-member-linkage.tsv"; op = 1; col = 0; val = ""; cls = "INCOMPLETE_LINK_INPUT_CLOSURE"; }
  else if (StrEq(id, "WC-IC-06")) { file = "authorities.tsv"; op = 3; row = 0; col = 12; val = "CFG-STAGE0-RECIPE-FRESH"; cls = "CONFIGURATION_SELECTOR_MISMATCH"; }
  else if (StrEq(id, "WC-AU-01")) { file = "authorities.tsv"; op = 3; row = 0; col = 20; val = "PROJECTS_SCALARS_AND_CALLS_POLYC"; cls = "ADAPTER_AUTHORITY_CONFUSION"; }
  else if (StrEq(id, "WC-AU-02")) { file = "authorities.tsv"; op = 4; val = "A-P-BootstrapScanIdent\tBootstrapScanIdent\tPOLYC_SUBJECT\tPolyC\ttools/bootstrap/bootstrap02-ident.HC\ta7f5648077b27b9af2f29f034eb27b4aba6941f8\tTREE_AT_C1\tabc\t0\t0\tSUBJ\tBootstrapScanIdent\tCFG-PROD-HCC-JIT-ON\tbuild/bootstrap02-ident.o\t./hcc\tx\tLINKED_OBJECT:y\tHCC_USE_SELFHOST_COMPONENTS\tPOLYC_AUTHORITY\tc1/a.tsv\tNONE\tNA\tNONE\tNOT_ESTABLISHED_IN_C1\tNO\tNO\tNO\tNO\tI64\tSCALAR\tNONE\tHIGH\tx\tMEDIUM"; cls = "UNLINKED_POLYC_SYMBOL"; }
  else if (StrEq(id, "WC-AU-03")) { file = "dormant-polyc-sites.tsv"; op = 3; row = 0; col = 6; val = "YES"; cls = "DORMANT_POLYC_AUTHORITY"; }
  else if (StrEq(id, "WC-AU-04")) { file = "semantic-coverage.tsv"; op = 3; row = 1; col = 7; val = "ADAPTER_DELEGATION_ONLY"; cls = "ACTIVE_C_DECISION_IN_ADAPTER"; }
  else if (StrEq(id, "WC-AU-05")) { file = "unknown-edges.tsv"; op = 1; col = 0; val = ""; cls = "UNRESOLVED_REACHABILITY_EDGE"; }
  else if (StrEq(id, "WC-DG-01")) { file = "graph-edges.tsv"; op = 1; col = 0; val = "E-TYP-0214"; cls = "MISSING_REQUIRED_EDGE"; }
  else if (StrEq(id, "WC-DG-02")) { file = "graph-edges.tsv"; op = 4; val = "E-FORGED-9999\tSYS-AST\tSYS-JSON\tTYPE_REPRESENTATION\tTYPE_LAYOUT_BEFORE_SEMANTICS\tYES\tOBSERVED\tforged\tx\tTYPE_LAYOUT\tCFG-PROD-HCC-JIT-ON\tHIGH"; cls = "EDGE_TYPE_OR_MANDATORY_MISMATCH"; }
  else if (StrEq(id, "WC-DG-03")) { file = "graph-edges.tsv"; special = 1; cls = "DEPENDENCY_DIRECTION_ERROR"; }
  else if (StrEq(id, "WC-DG-04")) { special = 2; cls = "SCC_RECOMPUTE_MISMATCH"; }
  else if (StrEq(id, "WC-DG-05")) { file = "migration-bundles.tsv"; op = 3; row = 0; col = 9; val = "PURE_SCALAR"; cls = "UNBOUNDED_STATE_BOUNDARY"; }
  else if (StrEq(id, "WC-BS-01")) { file = "compiler-generation-chain.tsv"; op = 2; row = 1; cls = "PRODUCER_IDENTITY_COLLISION"; }
  else if (StrEq(id, "WC-BS-02")) { file = "compiler-generation-chain.tsv"; op = 3; row = 13; col = 7; val = "B5_WHOLE_COMPILER_CLAIM"; cls = "HYBRID_NOT_SELFHOSTED"; }
  else if (StrEq(id, "WC-BS-03")) { file = "bootstrap-blockers.tsv"; op = 1; col = 0; val = ""; cls = "MISSING_BOOTSTRAP_BLOCKER"; }
  else if (StrEq(id, "WC-BS-04")) { file = "bootstrap-milestones.tsv"; op = 4; val = "SYS-AST\tCOMPILER_SEMANTICS\tALLOWED_GLUE\tforged"; cls = "SEMANTIC_C_MASQUERADING_AS_GLUE"; }
  else if (StrEq(id, "WC-FC-01")) { file = "migration-bundles.tsv"; op = 2; row = 0; cls = "FORECAST_DOUBLE_COUNT"; }
  else if (StrEq(id, "WC-FC-02")) { file = "graph-nodes.tsv"; op = 1; col = 0; val = "UNK-callback-dispatch"; cls = "UNKNOWN_NOT_PROPAGATED"; }
  else if (StrEq(id, "WC-FC-03")) { file = "forecast.tsv"; op = 3; row = 1; col = 2; val = "1"; cls = "FORECAST_CRITICAL_PATH_VIOLATION"; }
  else if (StrEq(id, "WC-FC-04")) { file = "forecast.tsv"; op = 3; row = 4; col = 1; val = "SUPPORTED"; cls = "UNSUPPORTED_BELOW_100_CLAIM"; }
  else { "CONTROL=%s STATUS=FAIL REASON=UNKNOWN_CONTROL\n", id; return 1; }
  if (special == 1) {
    SwapSrcDst(PathJoin(workdir, file));
  } else if (special == 2) {
    U8 *p = PathJoin(workdir, "prior-scc-wrong.tsv");
    OutReset();
    OutS("scc_id\tnode_id\tmember_index\n");
    I64 i = 0;
    while (i < NODE_N) {
      OutS("SCC-"); OutI(i + 1); OutS("\t"); OutS(NODE_ID[i]); OutS("\t0\n");
      i++;
    }
    OutFlush(p);
  } else if (op != 0) {
    MutWrite(PathJoin(workdir, file), op, row, col, val);
  }
  FAILS = 0; CHECKS = 0; EXPECT = cls; EXPECT_SEEN = 0;
  RunSchema(workdir);
  CheckDerived(workdir);
  CheckBlockers(workdir);
  CheckGlue(workdir);
  if (special == 2) GraphCompare(workdir, PathJoin(workdir, "prior-scc-wrong.tsv"));
  U8 *v = "FAIL";
  if (EXPECT_SEEN == 1) v = "PASS";
  "CONTROL=%s EXPECTED=%s SEEN=%d STATUS=%s\n", id, cls, EXPECT_SEEN, v;
  if (EXPECT_SEEN == 1) return 0;
  return 1;
}

I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) {
    "USAGE: whole-compiler-census01-verify SCHEMA|GRAPH|FORECAST|CONTROL|SELFTEST ...\n";
    return 2;
  }
  if (StrEq(argv[1], "SELFTEST")) return SelfTest();
  if (StrEq(argv[1], "SCHEMA")) {
    if (argc < 3) return 2;
    I64 r = RunSchema(argv[2]);
    r += CheckDerived(argv[2]);
    r += CheckBlockers(argv[2]);
    r += CheckGlue(argv[2]);
    if (r == 0) "OVERALL_STATUS=PASS\n"; else "OVERALL_STATUS=FAIL\n";
    if (r == 0) return 0;
    return 1;
  }
  if (StrEq(argv[1], "CONTROL")) {
    if (argc < 5) return 2;
    return ControlMode(argv[2], argv[3], argv[4]);
  }
  if (StrEq(argv[1], "GRAPH")) {
    if (argc < 4) return 2;
    return GraphMode(argv[2], argv[3]);
  }
  if (StrEq(argv[1], "FORECAST")) {
    if (argc < 4) return 2;
    return ForecastMode(argv[2], argv[3]);
  }
  "UNKNOWN_MODE=%s\n", argv[1];
  return 2;
}
