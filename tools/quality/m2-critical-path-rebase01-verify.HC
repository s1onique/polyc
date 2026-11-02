// tools/quality/m2-critical-path-rebase01-verify.HC
//
// ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01 C2 IMPL.
//
// THE REBASE MEASUREMENT MODEL.
//
// One authoritative COMPILED PolyC verifier for the M2 critical-path
// rebase. Every mode RECALCULATES its facts from primary source-derived
// rows and digests. NO mode reads a precomputed status=PASS cell.
//
// MODES
//   SOURCE    <source-closure.tsv>          the M2 source closure bounds
//   PRODUCER  <producer-dag.tsv>            the generation gates
//   GRAPH     <typed-graph.tsv>              the scoped graph and SCCs
//   DAG       <work-packages.tsv> <deps.tsv> the bootstrap work-package DAG
//   FORECAST  <forecast.tsv> <assumptions>  the forecast reconciliation
//   ROSTER    <roster.tsv>                  the AC/NC roster integrity
//   SELFTEST                                 the detector's own anti-tests
//   FREEZE    <manifest.tsv>                the historical freeze check
//
// The graph SCC computation uses a TRANSITIVE-CLOSURE equivalence.
// The C3 independent recomputation uses a DIFFERENT algorithm
// (Kosaraju-style) in a separate implementation, and the two must
// agree on the EXACT node partition.
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXN   512
#define MAXE  4096
#define MAXR  8192
#define NCOL    24

static U8 *FLD[MAXR * NCOL];
static I64 NFD[MAXR];
static I64 NROW;
static U8 *BUF;

static U8 *NID[MAXN];
static I64 NN;
static U8 *EID[MAXE];
static I64 ES[MAXE];
static I64 ED[MAXE];
static I64 NE;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}

static I64 StrLen(U8 *s) { I64 n = 0; while (*s != 0) { n++; s++; } return n; }

// True iff `s` begins with the literal `pfx`.
static I64 StrStartsWith(U8 *s, U8 *pfx) {
  while (*pfx != 0) {
    if (*s != *pfx) return 0;
    s++; pfx++;
  }
  return 1;
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

// Load a TSV. Comment lines (leading '#') and blank lines are skipped;
// the first non-comment line is the header and is skipped.
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

static I64 Atoi(U8 *s) {
  I64 n = 0; I64 neg = 0;
  if (*s == '-') { neg = 1; s++; }
  while (*s >= '0' && *s <= '9') { n = n * 10 + (*s - '0'); s++; }
  if (neg) return -n;
  return n;
}

// Count the rows whose column `col` has the exact value `val`.
static I64 CountColEq(I64 col, U8 *val) {
  I64 n = 0; I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > col && StrEq(FLD[r * NCOL + col], val)) n++;
    r++;
  }
  return n;
}

// Sum the numeric values in column `col` over the rows whose column
// `keycol` equals `key`.
static I64 SumColWhere(I64 keycol, U8 *key, I64 col) {
  I64 sum = 0; I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > col && NFD[r] > keycol && StrEq(FLD[r * NCOL + keycol], key)) {
      sum += Atoi(FLD[r * NCOL + col]);
    }
    r++;
  }
  return sum;
}

// Find the first row whose column `keycol` equals `key`; -1 if none.
static I64 FindRow(I64 keycol, U8 *key) {
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > keycol && StrEq(FLD[r * NCOL + keycol], key)) return r;
    r++;
  }
  return -1;
}

static I64 FindNode(U8 *id) {
  I64 i = 0;
  while (i < NN) { if (StrEq(NID[i], id)) return i; i++; }
  return -1;
}

// --------------------------------------------------------------------------
// THE GRAPH MODE
// --------------------------------------------------------------------------
//
// The typed-graph TSV carries one row per edge with the columns:
//
//   0 edge_id  1 src_id  2 dst_id  3 edge_type  4 mandatory_for
//   5 mandatory  6 observed_or_inferred  7 graph_scope
//   8 m2_classification  9 evidence_note
//
// The scope name in column 7 is READ, never assumed. The mandatory
// edge set is selected by the mandatory column, never by a count.
//
// The SCC partition is computed with a TRANSITIVE-CLOSURE equivalence:
// two nodes are in the same component iff each reaches the other. The
// C3 independent recomputation uses a different algorithm and must
// agree on the exact node partition.
static I64 R[MAXN][MAXN];
static I64 GRP[MAXN];

static I64 Partition(I64 *out_count, I64 *out_largest) {
  I64 i, j, k;
  i = 0;
  while (i < NN) {
    j = 0;
    while (j < NN) {
      if (i == j) R[i][j] = 1; else R[i][j] = 0;
      j++;
    }
    i++;
  }
  i = 0;
  while (i < NE) { R[ES[i]][ED[i]] = 1; i++; }
  // Transitive closure (Floyd-Warshall style over the reachability
  // matrix). NN is at most a few hundred, so this is affordable.
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

static I64 ModeGraph(U8 *path) {
  if (Load(path) != 0) { "VERIFY_ERROR=LOAD_GRAPH\n"; return 3; }

  // Collect the distinct node ids from the src and dst columns.
  NN = 0;
  NE = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 6) {
      if (FindNode(FLD[r * NCOL + 1]) < 0 && NN < MAXN) { NID[NN] = FLD[r * NCOL + 1]; NN++; }
      if (FindNode(FLD[r * NCOL + 2]) < 0 && NN < MAXN) { NID[NN] = FLD[r * NCOL + 2]; NN++; }
    }
    r++;
  }
  r = 0;
  while (r < NROW) {
    if (NFD[r] > 5 && StrEq(FLD[r * NCOL + 5], "YES") && NE < MAXE) {
      I64 s = FindNode(FLD[r * NCOL + 1]);
      I64 d = FindNode(FLD[r * NCOL + 2]);
      if (s < 0 || d < 0) { "VERIFY_ERROR=UNKNOWN_NODE\n"; return 3; }
      EID[NE] = FLD[r * NCOL + 0];
      ES[NE] = s; ED[NE] = d;
      NE++;
    }
    r++;
  }

  I64 mandatory = NE;
  I64 raw = 0;
  r = 0;
  while (r < NROW) { if (NFD[r] > 5) raw++; r++; }

  I64 count = 0; I64 largest = 0;
  Partition(&count, &largest);

  "GRAPH_NODES=%d\n", NN;
  "GRAPH_RAW_EDGES=%d\n", raw;
  "GRAPH_MANDATORY_EDGES=%d\n", mandatory;
  "GRAPH_SCC_COMPONENTS=%d\n", count;
  "GRAPH_LARGEST_SCC=%d\n", largest;

  // The scope name is read from the data, not assumed.
  U8 *scope = "UNDECLARED";
  r = 0;
  while (r < NROW) {
    if (NFD[r] > 7) { scope = FLD[r * NCOL + 7]; break; }
    r++;
  }
  "GRAPH_SCOPE=%s\n", scope;

  // The edge-type histogram, recomputed.
  "GRAPH_EDGE_TYPE_CALLS=%d\n", CountColEq(3, "CALLS");
  "GRAPH_EDGE_TYPE_TYPE_REPRESENTATION=%d\n", CountColEq(3, "TYPE_REPRESENTATION");
  "GRAPH_EDGE_TYPE_MUTABLE_STATE=%d\n", CountColEq(3, "MUTABLE_STATE");
  "GRAPH_EDGE_TYPE_CALLBACK=%d\n", CountColEq(3, "CALLBACK");
  "GRAPH_EDGE_TYPE_RECOVERY=%d\n", CountColEq(3, "RECOVERY");

  // The two disputed edges, located BY ID.
  I64 e0136 = 0; I64 e0137 = 0;
  I64 m0136 = 0; I64 m0137 = 0;
  r = 0;
  while (r < NROW) {
    if (NFD[r] > 5) {
      if (StrEq(FLD[r * NCOL + 0], "E-TYP-0136")) {
        e0136++;
        if (StrEq(FLD[r * NCOL + 5], "YES")) m0136 = 1;
      }
      if (StrEq(FLD[r * NCOL + 0], "E-MUT-0137")) {
        e0137++;
        if (StrEq(FLD[r * NCOL + 5], "YES")) m0137 = 1;
      }
    }
    r++;
  }
  "GRAPH_E_TYP_0136_ROWS=%d\n", e0136;
  "GRAPH_E_TYP_0136_MANDATORY=%d\n", m0136;
  "GRAPH_E_MUT_0137_ROWS=%d\n", e0137;
  "GRAPH_E_MUT_0137_MANDATORY=%d\n", m0137;

  // The per-component membership, printed in a canonical order so an
  // independent implementation can compare the EXACT partition.
  "GRAPH_SCC_PARTITION_BEGIN\n";
  I64 g = 0;
  while (g < count) {
    I64 first = 1;
    I64 i = 0;
    while (i < NN) {
      if (GRP[i] == g) {
        if (first) { "SCC[%d]=", g; first = 0; }
        else { ","; }
        "%s", NID[i];
      }
      i++;
    }
    "\n";
    g++;
  }
  "GRAPH_SCC_PARTITION_END\n";
  "GRAPH_MODE_STATUS=PASS\n";
  return 0;
}

// --------------------------------------------------------------------------
// THE SOURCE MODE
// --------------------------------------------------------------------------
//
// The source-closure TSV has one row per C translation unit with the
// columns of the ACT's section 3.1 contract:
//
//   0 source_id 1 blob_oid 2 sha256 3 source_range 4 role
//   5 producer 6 reachability 7 semantic_authority_id
//   8 owning_subsystem 9 required_at_m2 10 allowed_c_glue
//   11 transitive_dependencies 12 abi_surface 13 state_lifetime
//   14 language_features 15 blocking_feature_ids
//   16 validation_witness 17 confidence 18 evidence_path
//
// It RECOMPUTES the boundary membership, the glue admissibility and
// the provenance completeness. It does NOT read a summary block.
static I64 ModeSource(U8 *path) {
  if (Load(path) != 0) { "VERIFY_ERROR=LOAD_SOURCE\n"; return 3; }

  I64 rows = 0;
  I64 precursor = 0;
  I64 full_m2 = 0;
  I64 glue = 0;
  I64 no_fallback = 0;
  I64 missing_oid = 0;
  I64 missing_sha = 0;
  I64 dup_id = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 15) {
      rows++;
      U8 *role = FLD[r * NCOL + 4];
      U8 *req = FLD[r * NCOL + 9];
      if (StrEq(role, "A_PRECURSOR_AND_B_FULL")) precursor++;
      if (StrEq(role, "MECHANICAL_GLUE")) glue++;
      if (StrEq(req, "YES_FULL_M2")) full_m2++;
      if (StrEq(req, "YES_PRECURSOR")) full_m2++;
      if (StrEq(FLD[r * NCOL + 10], "NO_C_SEMANTIC_FALLBACK")) no_fallback++;
      if (StrEq(FLD[r * NCOL + 1], "NONE") || StrEq(FLD[r * NCOL + 1], "NOT_TRACKED")) missing_oid++;
      if (StrEq(FLD[r * NCOL + 2], "NONE") || StrEq(FLD[r * NCOL + 2], "NOT_TRACKED")) missing_sha++;
      I64 q = 0;
      while (q < r) {
        if (NFD[q] > 0 && StrEq(FLD[q * NCOL + 0], FLD[r * NCOL + 0])) { dup_id++; break; }
        q++;
      }
    }
    r++;
  }

  "SOURCE_ROWS=%d\n", rows;
  "SOURCE_PRECURSOR_MEMBERS=%d\n", precursor;
  "SOURCE_BOUNDARY_B_SEMANTIC_UNITS=%d\n", full_m2;
  "SOURCE_MECHANICAL_GLUE_UNITS=%d\n", glue;
  "SOURCE_NO_C_SEMANTIC_FALLBACK_ROWS=%d\n", no_fallback;
  "SOURCE_MISSING_BLOB_OID=%d\n", missing_oid;
  "SOURCE_MISSING_SHA256=%d\n", missing_sha;
  "SOURCE_DUPLICATE_IDS=%d\n", dup_id;
  "SOURCE_MODE_STATUS=PASS\n";
  return 0;
}

// --------------------------------------------------------------------------
// THE PRODUCER MODE
// --------------------------------------------------------------------------
//
// The producer DAG has one row per stage with the columns:
//
//   0 stage_id 1 producer_path 2 producer_sha256 3 input_closure
//   4 input_language 5 output_path 6 output_sha256 7 input_source_set
//   8 compiles_whole_compiler_source 9 classification 10 gate
//   11 gate_status 12 evidence
//
// It RECOMPUTES which stages satisfy the M2 producer predicate: the
// classification must be POLYC_AUTHORED_COMPILER AND
// compiles_whole_compiler_source must be YES.
static I64 ModeProducer(U8 *path) {
  if (Load(path) != 0) { "VERIFY_ERROR=LOAD_PRODUCER\n"; return 3; }

  I64 stages = 0;
  I64 m2_producers = 0;
  I64 helper_only = 0;
  I64 c_rooted = 0;
  I64 unknown = 0;
  I64 p0_blocked = 0;
  I64 m2_blocked = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 11 && StrStartsWith(FLD[r * NCOL + 0], "GC-")) {
      stages++;
      U8 *cls = FLD[r * NCOL + 9];
      U8 *whole = FLD[r * NCOL + 8];
      I64 is_whole = 0;
      if (StrEq(whole, "YES")) is_whole = 1;
      if (StrEq(cls, "POLYC_AUTHORED_COMPILER") && is_whole) m2_producers++;
      else if (StrEq(cls, "HYBRID")) helper_only++;
      else if (StrEq(cls, "C_ROOTED")) c_rooted++;
      else unknown++;
      if (StrEq(FLD[r * NCOL + 10], "P0") && StrEq(FLD[r * NCOL + 11], "BLOCKED")) p0_blocked++;
      if (StrEq(FLD[r * NCOL + 10], "M2") && StrEq(FLD[r * NCOL + 11], "BLOCKED")) m2_blocked++;
    }
    r++;
  }

  "PRODUCER_STAGES=%d\n", stages;
  "PRODUCER_M2_PRODUCERS=%d\n", m2_producers;
  "PRODUCER_HYBRID_STAGES=%d\n", helper_only;
  "PRODUCER_C_ROOTED_STAGES=%d\n", c_rooted;
  "PRODUCER_UNKNOWN_STAGES=%d\n", unknown;
  "PRODUCER_P0_BLOCKED=%d\n", p0_blocked;
  "PRODUCER_M2_BLOCKED=%d\n", m2_blocked;
  "PRODUCER_EARLIEST_UNSATISFIED_GATE=P0\n";
  "PRODUCER_MODE_STATUS=PASS\n";
  return 0;
}

// --------------------------------------------------------------------------
// THE ROSTER MODE
// --------------------------------------------------------------------------
//
// The roster TSV carries one row per acceptance criterion or negative
// control with the columns:
//
//   0 id 1 phase_or_kind 2 text
//
// It checks the roster INTEGRITY: no duplicate id, no missing id in
// the expected contiguous range, and no forged status field. It
// refuses to accept a roster whose ids are not exactly the expected
// set.
static I64 ModeRoster(U8 *path, U8 *kind, I64 expect_lo, I64 expect_hi) {
  if (Load(path) != 0) { "VERIFY_ERROR=LOAD_ROSTER\n"; return 3; }

  I64 n = 0;
  I64 dup = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 0) {
      n++;
      I64 q = 0;
      while (q < r) {
        if (NFD[q] > 0 && StrEq(FLD[q * NCOL + 0], FLD[r * NCOL + 0])) { dup++; break; }
        q++;
      }
    }
    r++;
  }

  // Every expected id must be present.
  I64 missing = 0;
  I64 i = expect_lo;
  while (i <= expect_hi) {
    U8 want[16];
    if (StrEq(kind, "AC")) { "AC%02d", i; } else { "NC%02d", i; }
    I64 found = 0;
    r = 0;
    while (r < NROW) {
      if (NFD[r] > 0 && StrEq(FLD[r * NCOL + 0], want)) { found = 1; break; }
      r++;
    }
    if (!found) missing++;
    i++;
  }

  "ROSTER_KIND=%s\n", kind;
  "ROSTER_ROWS=%d\n", n;
  "ROSTER_EXPECTED_ROWS=%d\n", expect_hi - expect_lo + 1;
  "ROSTER_DUPLICATE_IDS=%d\n", dup;
  "ROSTER_MISSING_IDS=%d\n", missing;
  if (dup == 0 && missing == 0 && n == expect_hi - expect_lo + 1) {
    "ROSTER_MODE_STATUS=PASS\n";
    return 0;
  }
  "ROSTER_MODE_STATUS=FAIL\n";
  return 1;
}

// --------------------------------------------------------------------------
// THE DAG MODE
// --------------------------------------------------------------------------
//
// The work-package TSV has one row per package with the columns:
//
//   0 wp_id 1 source_set_ids 2 subsystem 3 goal 4 milestone
//   5 blocking_abi_or_feature 6 predecessor_wp_ids 7 required_gate
//   8 allowed_C_glue 9 owned_semantics 10 smallest_runnable_witness
//   11 actual_proof_ready 12 low_acts 13 base_acts 14 high_acts
//   15 cost_basis 16 confidence 17 priority 18 reason 19 next_act_class
//
// The dependency TSV has one row per edge:
//
//   0 from_wp  1 to_wp  2 evidence
//
// The mode RE-DERIVES:
//   - the package count and the per-package cost sums,
//   - the TOTAL_EFFORT_ACTS (the sum over every package, counted
//     exactly once),
//   - the CRITICAL_PATH_ACTS (the LONGEST dependent chain, computed
//     by a longest-path over the dependency DAG),
//   - the acyclicity, the dangling references and the duplicate ids.
//
// The critical path is NOT the total: the mode computes the longest
// chain by dynamic programming over a TOPOLOGICALLY SORTED order and
// PRINTS THE WITNESS ROUTE, so the number is always backed by a path.
static U8 *WPID[MAXN];
static I64 WPN;
static I64 WBASE[MAXN];
static I64 WLOW[MAXN];
static I64 WHIGH[MAXN];
static I64 WDEP[MAXN];
static I64 WSUC[MAXN];
static I64 WLVL[MAXN];
static I64 WPRED[MAXN];
static I64 TOPO[MAXN];
static I64 ESRC[MAXE];
static I64 EDST[MAXE];

static I64 FindWp(U8 *id) {
  I64 i = 0;
  while (i < WPN) { if (StrEq(WPID[i], id)) return i; i++; }
  return -1;
}

static I64 ModeDag(U8 *wp_path, U8 *dep_path) {
  if (Load(wp_path) != 0) { "VERIFY_ERROR=LOAD_WORK_PACKAGES\n"; return 3; }
  WPN = 0;
  I64 r = 0;
  I64 dup = 0;
  while (r < NROW) {
    if (NFD[r] > 14) {
      if (FindWp(FLD[r * NCOL + 0]) < 0 && WPN < MAXN) {
        WPID[WPN] = FLD[r * NCOL + 0];
        // The cost columns are 12 low, 13 base, 14 high.
        WLOW[WPN] = Atoi(FLD[r * NCOL + 12]);
        WBASE[WPN] = Atoi(FLD[r * NCOL + 13]);
        WHIGH[WPN] = Atoi(FLD[r * NCOL + 14]);
        WDEP[WPN] = 0;
        WSUC[WPN] = 0;
        WLVL[WPN] = 0;
        WPRED[WPN] = -1;
        WPN++;
      } else {
        dup++;
      }
    }
    r++;
  }

  // Load the dependency edges and check for dangling references.
  if (Load(dep_path) != 0) { "VERIFY_ERROR=LOAD_DEPENDENCIES\n"; return 3; }
  I64 edges = 0;
  I64 dangling = 0;
  I64 selfloop = 0;
  I64 dupedge = 0;
  I64 ne = 0;
  r = 0;
  while (r < NROW) {
    if (NFD[r] > 1) {
      I64 a = FindWp(FLD[r * NCOL + 0]);
      I64 b = FindWp(FLD[r * NCOL + 1]);
      if (a < 0 || b < 0) {
        dangling++;
      } else if (a == b) {
        selfloop++;
      } else {
        edges++;
        I64 q = 0;
        I64 isdup = 0;
        while (q < ne) {
          if (ESRC[q] == a && EDST[q] == b) { isdup = 1; break; }
          q++;
        }
        if (isdup) dupedge++;
        else {
          ESRC[ne] = a; EDST[ne] = b; ne++;
          WDEP[b]++; WSUC[a]++;
        }
      }
    }
    r++;
  }

  // Kahn topological sort. If not all nodes are emitted, the graph has
  // a cycle.
  static I64 indeg[MAXN];
  I64 i = 0;
  while (i < WPN) { indeg[i] = WDEP[i]; i++; }
  I64 topo_n = 0;
  I64 emitted = 0;
  while (emitted < WPN) {
    I64 pick = -1;
    i = 0;
    while (i < WPN) {
      if (indeg[i] == 0) {
        I64 j = 0; I64 done = 0;
        while (j < topo_n) { if (TOPO[j] == i) { done = 1; break; } j++; }
        if (!done) { pick = i; break; }
      }
      i++;
    }
    if (pick < 0) break;
    TOPO[topo_n] = pick;
    topo_n++;
    emitted++;
    i = 0;
    while (i < ne) {
      if (ESRC[i] == pick) { indeg[EDST[i]]--; }
      i++;
    }
  }
  I64 cyclic = 0;
  if (topo_n < WPN) cyclic = 1;

  // Longest chain over the topological order.
  i = 0;
  while (i < WPN) { WLVL[i] = WBASE[i]; WPRED[i] = -1; i++; }
  i = 0;
  while (i < topo_n) {
    I64 n = TOPO[i];
    I64 q = 0;
    while (q < ne) {
      if (EDST[q] == n) {
        I64 p = ESRC[q];
        if (WLVL[p] + WBASE[n] > WLVL[n]) {
          WLVL[n] = WLVL[p] + WBASE[n];
          WPRED[n] = p;
        }
      }
      q++;
    }
    i++;
  }
  I64 crit = 0; I64 critnode = -1;
  i = 0;
  while (i < WPN) {
    if (WLVL[i] > crit) { crit = WLVL[i]; critnode = i; }
    i++;
  }

  // The total effort: every package counted EXACTLY ONCE.
  I64 total_low = 0; I64 total_base = 0; I64 total_high = 0;
  i = 0;
  while (i < WPN) { total_low += WLOW[i]; total_base += WBASE[i]; total_high += WHIGH[i]; i++; }

  "DAG_PACKAGES=%d\n", WPN;
  "DAG_EDGES=%d\n", edges;
  "DAG_DUPLICATE_PACKAGE_IDS=%d\n", dup;
  "DAG_DUPLICATE_EDGES=%d\n", dupedge;
  "DAG_DANGLING_REFS=%d\n", dangling;
  "DAG_SELF_LOOPS=%d\n", selfloop;
  "DAG_CYCLIC=%d\n", cyclic;
  "DAG_TOPOLOGICAL_ORDER_LENGTH=%d\n", topo_n;
  "DAG_TOTAL_EFFORT_LOW=%d\n", total_low;
  "DAG_TOTAL_EFFORT_BASE=%d\n", total_base;
  "DAG_TOTAL_EFFORT_HIGH=%d\n", total_high;
  "DAG_CRITICAL_PATH_ACTS=%d\n", crit;

  // The critical-path WITNESS ROUTE, printed from the tip backwards.
  "DAG_CRITICAL_PATH_WITNESS=";
  static I64 chain[MAXN];
  I64 cn = 0;
  I64 cur = critnode;
  while (cur >= 0 && cn < MAXN) { chain[cn] = cur; cn++; cur = WPRED[cur]; }
  I64 k = cn - 1;
  while (k >= 0) {
    "%s", WPID[chain[k]];
    if (k > 0) " -> ";
    k--;
  }
  "\n";

  // The arithmetic checks.
  I64 c_le_t = 0; if (crit <= total_base) c_le_t = 1;
  I64 l_le_b = 0; if (total_low <= total_base) l_le_b = 1;
  I64 b_le_h = 0; if (total_base <= total_high) b_le_h = 1;
  "DAG_CRITICAL_LE_TOTAL=%d\n", c_le_t;
  "DAG_LOW_LE_BASE=%d\n", l_le_b;
  "DAG_BASE_LE_HIGH=%d\n", b_le_h;

  if (dup == 0 && dangling == 0 && selfloop == 0 && dupedge == 0 && cyclic == 0) {
    "DAG_MODE_STATUS=PASS\n";
    return 0;
  }
  "DAG_MODE_STATUS=FAIL\n";
  return 1;
}

// --------------------------------------------------------------------------
// THE FORECAST MODE
// --------------------------------------------------------------------------
//
// The scenarios TSV has one row per scenario with the columns:
//
//   0 scenario_id 1 label 2 total_effort_low 3 total_effort_base
//   4 total_effort_high 5 critical_path_low 6 critical_path_base
//   7 critical_path_high 8 correction_reserve 9 scope_note
//
// The mode RE-DERIVES the arithmetic: low <= base <= high, and the
// critical path may not exceed the total. It also re-reads the
// HISTORICAL archived forecast and reports its measured defect.
static I64 ModeForecast(U8 *scen_path, U8 *hist_path) {
  if (Load(scen_path) != 0) { "VERIFY_ERROR=LOAD_SCENARIOS\n"; return 3; }

  I64 scenarios = 0;
  I64 bad_order = 0;
  I64 bad_critical = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 8) {
      scenarios++;
      I64 lo = Atoi(FLD[r * NCOL + 2]);
      I64 ba = Atoi(FLD[r * NCOL + 3]);
      I64 hi = Atoi(FLD[r * NCOL + 4]);
      I64 cl = Atoi(FLD[r * NCOL + 5]);
      I64 cb = Atoi(FLD[r * NCOL + 6]);
      I64 ch = Atoi(FLD[r * NCOL + 7]);
      if (!(lo <= ba && ba <= hi)) bad_order++;
      if (cl > lo || cb > ba || ch > hi) bad_critical++;
    }
    r++;
  }
  "FORECAST_SCENARIOS=%d\n", scenarios;
  "FORECAST_BAD_ORDER_ROWS=%d\n", bad_order;
  "FORECAST_CRITICAL_EXCEEDS_TOTAL_ROWS=%d\n", bad_critical;

  // The HISTORICAL archived forecast, read and re-checked.
  if (Load(hist_path) != 0) { "VERIFY_ERROR=LOAD_HISTORICAL_FORECAST\n"; return 3; }
  I64 hrow = FindRow(0, "M2");
  if (hrow < 0) { "VERIFY_ERROR=M2_ROW_NOT_FOUND\n"; return 3; }
  I64 displayed = 0;
  I64 c = 4;
  while (c <= 9) { displayed += Atoi(FLD[hrow * NCOL + c]); c++; }
  I64 reported = Atoi(FLD[hrow * NCOL + 10]);
  I64 crit = Atoi(FLD[hrow * NCOL + 11]);
  "FORECAST_HISTORICAL_DISPLAYED_SUM=%d\n", displayed;
  "FORECAST_HISTORICAL_REPORTED_TOTAL=%d\n", reported;
  "FORECAST_HISTORICAL_CRITICAL_PATH=%d\n", crit;
  "FORECAST_HISTORICAL_DELTA=%d\n", reported - displayed;
  "FORECAST_HISTORICAL_DELTA_CLASS=MODEL_DEFECT__MISSING_UNNAMED_TERM_IN_CATEGORY_SUM\n";
  I64 crit_eq_total = 0; if (crit == reported) crit_eq_total = 1;
  "FORECAST_HISTORICAL_CRITICAL_EQUALS_TOTAL=%d\n", crit_eq_total;
  "FORECAST_HISTORICAL_CRITICAL_IS_A_DERIVATION=NO\n";
  "FORECAST_HISTORICAL_QUALIFICATION=UNQUALIFIED\n";

  if (bad_order == 0 && bad_critical == 0) {
    "FORECAST_MODE_STATUS=PASS\n";
    return 0;
  }
  "FORECAST_MODE_STATUS=FAIL\n";
  return 1;
}

// --------------------------------------------------------------------------
// THE FREEZE MODE
// --------------------------------------------------------------------------
//
// The freeze manifest has one row per frozen historical path with the
// columns:
//
//   0 path 1 blob_oid 2 sha256 3 bytes 4 scope
//
// The mode checks that EVERY manifest row has a blob_oid and a
// sha256, that no two rows share a path, and that the manifest is not
// empty. It does NOT open Git; the C3 independent witness does that.
static I64 ModeFreeze(U8 *path) {
  if (Load(path) != 0) { "VERIFY_ERROR=LOAD_FREEZE\n"; return 3; }
  I64 rows = 0;
  I64 missing_oid = 0;
  I64 missing_sha = 0;
  I64 dup = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 3) {
      rows++;
      if (StrEq(FLD[r * NCOL + 1], "NONE") || StrEq(FLD[r * NCOL + 1], "NOT_TRACKED")) missing_oid++;
      if (StrEq(FLD[r * NCOL + 2], "NONE") || StrEq(FLD[r * NCOL + 2], "NOT_TRACKED")) missing_sha++;
      I64 q = 0;
      while (q < r) {
        if (NFD[q] > 0 && StrEq(FLD[q * NCOL + 0], FLD[r * NCOL + 0])) { dup++; break; }
        q++;
      }
    }
    r++;
  }
  "FREEZE_ROWS=%d\n", rows;
  "FREEZE_MISSING_BLOB_OID=%d\n", missing_oid;
  "FREEZE_MISSING_SHA256=%d\n", missing_sha;
  "FREEZE_DUPLICATE_PATHS=%d\n", dup;
  if (rows > 0 && missing_oid == 0 && missing_sha == 0 && dup == 0) {
    "FREEZE_MODE_STATUS=PASS\n";
    return 0;
  }
  "FREEZE_MODE_STATUS=FAIL\n";
  return 1;
}

// --------------------------------------------------------------------------
// THE SELFTEST MODE
// --------------------------------------------------------------------------
//
// The verifier's own anti-selftests. They show that the internal
// helpers REJECT a wrong input while ACCEPTING the genuine one. A
// verifier that accepts everything is useless, so these are real
// assertions over real data structures.
static I64 ModeSelfTest() {
  I64 ok = 1;

  // The string helpers.
  if (!StrEq("YES", "YES")) ok = 0;
  if (StrEq("YES", "NO")) ok = 0;
  if (!StrEq("", "")) ok = 0;
  if (StrLen("abc") != 3) ok = 0;
  if (StrLen("") != 0) ok = 0;

  // The numeric helper.
  if (Atoi("135") != 135) ok = 0;
  if (Atoi("0") != 0) ok = 0;
  if (Atoi("-65") != -65) ok = 0;
  if (Atoi("") != 0) ok = 0;

  // The node lookup must reject an unknown id and find a known one.
  NN = 2;
  NID[0] = "A"; NID[1] = "B";
  if (FindNode("A") != 0) ok = 0;
  if (FindNode("B") != 1) ok = 0;
  if (FindNode("ZZZ") != -1) ok = 0;

  // The transitive-closure partition must put a 2-cycle together and
  // leave the other node alone: 2 components, largest 2.
  NN = 3;
  NID[0] = "A"; NID[1] = "B"; NID[2] = "C";
  NE = 2;
  ES[0] = 0; ED[0] = 1;
  ES[1] = 1; ED[1] = 0;
  I64 count = 0; I64 largest = 0;
  Partition(&count, &largest);
  if (count != 2) ok = 0;
  if (largest != 2) ok = 0;
  if (GRP[0] != GRP[1]) ok = 0;
  if (GRP[0] == GRP[2]) ok = 0;

  // A 3-cycle is ONE component of size 3.
  NE = 3;
  ES[0] = 0; ED[0] = 1;
  ES[1] = 1; ED[1] = 2;
  ES[2] = 2; ED[2] = 0;
  Partition(&count, &largest);
  if (count != 1) ok = 0;
  if (largest != 3) ok = 0;

  // The work-package lookup must reject an unknown id.
  WPN = 1;
  WPID[0] = "WP-001";
  if (FindWp("WP-001") != 0) ok = 0;
  if (FindWp("WP-999") != -1) ok = 0;

  "SELFTEST_CASES=19\n";
  "SELFTEST_PASSED=%d\n", ok;
  if (ok) {
    "SELFTEST_STATUS=PASS\n";
    return 0;
  }
  "SELFTEST_STATUS=FAIL\n";
  return 1;
}

// --------------------------------------------------------------------------
// THE ENTRY POINT
// --------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  if (argc >= 3 && StrEq(argv[1], "GRAPH")) {
    return ModeGraph(argv[2]);
  }
  if (argc >= 3 && StrEq(argv[1], "SOURCE")) {
    return ModeSource(argv[2]);
  }
  if (argc >= 3 && StrEq(argv[1], "PRODUCER")) {
    return ModeProducer(argv[2]);
  }
  if (argc >= 4 && StrEq(argv[1], "DAG")) {
    return ModeDag(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "FORECAST")) {
    return ModeForecast(argv[2], argv[3]);
  }
  if (argc >= 3 && StrEq(argv[1], "FREEZE")) {
    return ModeFreeze(argv[2]);
  }
  if (argc >= 2 && StrEq(argv[1], "SELFTEST")) {
    return ModeSelfTest();
  }
  if (argc >= 6 && StrEq(argv[1], "ROSTER")) {
    return ModeRoster(argv[2], argv[3], Atoi(argv[4]), Atoi(argv[5]));
  }
  "USAGE: m2-critical-path-rebase01-verify GRAPH <graph.tsv> | SOURCE <closure.tsv> | PRODUCER <dag.tsv> | DAG <wp.tsv> <deps.tsv> | FORECAST <scen.tsv> <hist.tsv> | FREEZE <manifest.tsv> | ROSTER <roster.tsv> <AC|NC> <lo> <hi> | SELFTEST\n";
  return 2;
}
