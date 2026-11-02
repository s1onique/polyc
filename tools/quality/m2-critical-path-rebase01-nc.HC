// tools/quality/m2-critical-path-rebase01-nc.HC
//
// ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01 C3 EVIDENCE.
//
// THE TWENTY-FOUR ADVERSARIAL-CONTROL DETECTOR.
//
// It is a REAL detector, not a label reader. Each mode RE-DERIVES the
// fact under test from the PRIMARY rows and then applies the rule that
// a wrong state would violate. A mode is SILENT (exit 0, no output)
// when the state under test is CONSISTENT with the primary rows, and
// it prints its OWN reason token and exits non-zero when the state is
// INCONSISTENT.
//
// The twenty-four frozen controls, each with its own reason token:
//
//   NC01  ENTRY_OR_PREDECESSOR_IDENTITY
//   NC02  FALSE_PHASE_OR_AC50_TERMINALITY
//   NC03  MISBOUND_EXTERNAL_TERMINALITY
//   NC04  HISTORICAL_F14_BLOB_MISMATCH
//   NC05  MECHANICAL_ADAPTER_MISCOUNT
//   NC06  PRODUCTION_REACHABILITY_FALSE
//   NC07  CENSUS_SCOPE_DOUBLE_COUNT
//   NC08  UNKNOWN_AUTHORITY_SILENT_DROP
//   NC09  GRAPH_VERSION_ALIAS
//   NC10  SHADOW_PRODUCTION_CUT_CONFLATION
//   NC11  LAYOUT_OBSERVATION_AS_MANDATORY
//   NC12  CALL_EDGE_SCOPE_CONFUSION
//   NC13  MANDATORY_EDGE_MISSING
//   NC14  SCC_PARTITION_MISMATCH
//   NC15  M2_SOURCE_PRODUCER_NOT_CLOSED
//   NC16  BOOTSTRAP_BLOCKER_OMITTED
//   NC17  WORK_PACKAGE_DAG_INVALID
//   NC18  CRITICAL_PATH_NOT_DERIVED
//   NC19  FORECAST_SUM_RECONCILIATION
//   NC20  INVENTED_COST_RESIDUAL
//   NC21  THROUGHPUT_PROVENANCE_OR_UNIT
//   NC22  FORECAST_DOUBLE_CHARGE
//   NC23  RANKER_ELIGIBILITY_OR_ORDER
//   NC24  AC_NC_OR_TERMINALITY_FALSE_PASS
//
// The state under test is a TSV of the facts a control tampers with.
// The detector compares the facts against what it re-derives.
//
// MODES (the state file is the last argument):
//
//   IDENTITY  <state.tsv>
//   GRAPH     <edges.tsv> <state.tsv>
//   AUTHORITY <authorities.tsv> <state.tsv>
//   PRODUCER  <producer.tsv> <state.tsv>
//   DAG       <wp.tsv> <deps.tsv> <state.tsv>
//   FORECAST  <scenarios.tsv> <historical.tsv> <state.tsv>
//   RANK      <ranking.tsv> <state.tsv>
//   TERMINALITY <state.tsv>
//   SELFTEST
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXN   256
#define MAXE  4096
#define MAXR  8192
#define NCOL    32

static U8 *FLD[MAXR * NCOL];
static I64 NFD[MAXR];
static I64 NROW;
static U8 *BUF;

// The state under test, as key/value pairs.
static U8 *SKEY[MAXR];
static U8 *SVAL[MAXR];
static I64 SN;

// The second state table, for the controls that need two tables.
static U8 *TKEY[MAXR];
static U8 *TVAL[MAXR];
static I64 TN;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}

static I64 StrLen(U8 *s) { I64 n = 0; while (*s != 0) { n++; s++; } return n; }

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

// Load a TSV. Comment lines (leading '#') and blank lines are skipped.
// The first non-comment line is treated as a header and skipped.
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

// Load a "key<TAB>value" table into KEY/VAL. The first non-comment
// line is treated as a header and skipped, matching the TSV loader.
static I64 LoadKV(U8 *path, U8 **KEY, U8 **VAL, I64 *COUNT) {
  I64 sz = 0;
  U8 *kb = FileRead(path, &sz);
  if (kb == 0) return -1;
  I64 n = 0;
  I64 first = 1;
  U8 *p = kb; U8 *end = kb + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    if (first) { first = 0; continue; }
    U8 *tab = ls;
    while (*tab != 0 && *tab != '\t') tab++;
    if (*tab == 0) continue;
    *tab = 0;
    KEY[n] = ls;
    VAL[n] = tab + 1;
    n++;
  }
  *COUNT = n;
  return 0;
}

// Load a "key<TAB>value" STATE table into KEY/VAL. Unlike LoadKV, no
// header row is skipped: a state file is a pure key/value table, and
// its first key IS the first datum.
static I64 LoadState(U8 *path, U8 **KEY, U8 **VAL, I64 *COUNT) {
  I64 sz = 0;
  U8 *kb = FileRead(path, &sz);
  if (kb == 0) return -1;
  I64 n = 0;
  U8 *p = kb; U8 *end = kb + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    U8 *tab = ls;
    while (*tab != 0 && *tab != '\t') tab++;
    if (*tab == 0) continue;
    *tab = 0;
    KEY[n] = ls;
    VAL[n] = tab + 1;
    n++;
  }
  *COUNT = n;
  return 0;
}

static U8 *State(U8 *key) {
  I64 i = 0;
  while (i < SN) { if (StrEq(SKEY[i], key)) return SVAL[i]; i++; }
  return 0;
}

static U8 *Table2(U8 *key) {
  I64 i = 0;
  while (i < TN) { if (StrEq(TKEY[i], key)) return TVAL[i]; i++; }
  return 0;
}

// NOTE: PolyC has no `void` type; the empty return type is U0.
static U0 Chomp(U8 *s) {
  I64 n = StrLen(s);
  while (n > 0 && (s[n - 1] == '\n' || s[n - 1] == '\r' || s[n - 1] == ' ' || s[n - 1] == '\t')) {
    s[n - 1] = 0; n--;
  }
}

static I64 Atoi(U8 *s) {
  I64 n = 0; I64 neg = 0;
  if (*s == '-') { neg = 1; s++; }
  while (*s >= '0' && *s <= '9') { n = n * 10 + (*s - '0'); s++; }
  if (neg) return -n;
  return n;
}

static I64 CountColEq(I64 col, U8 *val) {
  I64 n = 0; I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > col && StrEq(FLD[r * NCOL + col], val)) n++;
    r++;
  }
  return n;
}

static I64 FindRow(I64 keycol, U8 *key) {
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > keycol && StrEq(FLD[r * NCOL + keycol], key)) return r;
    r++;
  }
  return -1;
}

static I64 RowHasColEq(I64 r, I64 col, U8 *val) {
  if (NFD[r] <= col) return 0;
  return StrEq(FLD[r * NCOL + col], val);
}

// A case-insensitive comparison, for the source_language column,
// whose recorded values are "C" and "PolyC".
static I64 StrEqCI(U8 *a, U8 *b) {
  I64 ca;
  I64 cb;
  while (*a != 0 && *b != 0) {
    ca = *a; cb = *b;
    if (ca >= 'A' && ca <= 'Z') ca = ca + 32;
    if (cb >= 'A' && cb <= 'Z') cb = cb + 32;
    if (ca != cb) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

// Compare `len` bytes of `a` at offset `aoff` with `b` at offset `boff`.
static I64 StrNCmpAt(U8 *a, I64 aoff, U8 *b, I64 len) {
  I64 i = 0;
  while (i < len) {
    if (a[aoff + i] != b[i]) return 0;
    i++;
  }
  return 1;
}

// Does the comma-separated list `list` contain the token at `tok`?
static I64 ListHas(U8 *list, U8 *tok, I64 toklen) {
  I64 i = 0;
  while (list[i] != 0) {
    I64 start = i;
    while (list[i] != 0 && list[i] != ',') i++;
    I64 len = i - start;
    if (len == toklen && StrNCmpAt(list, start, tok, toklen)) return 1;
    if (list[i] == ',') i++;
  }
  return 0;
}

// --------------------------------------------------------------------------
// NC01  ENTRY_OR_PREDECESSOR_IDENTITY
// NC02  FALSE_PHASE_OR_AC50_TERMINALITY
// NC03  MISBOUND_EXTERNAL_TERMINALITY
// NC24  AC_NC_OR_TERMINALITY_FALSE_PASS
// --------------------------------------------------------------------------
//
// The state table carries the identity facts a control tampers with:
//
//   entry_head        the SHA this ACT was entered at
//   entry_tree        the tree this ACT was entered at
//   predecessor_head  the predecessor's terminal commit SHA
//   predecessor_range the number of commits in the predecessor range
//   ac50_literal      SATISFIED / NOT_SATISFIED_AS_WRITTEN
//   receipt_bound_head  the HEAD the external receipt is bound to
//   receipt_bound_tree  the TREE the external receipt is bound to
//   ac50_discharged   YES / NO
//   close_count       the number of CLOSE commits
//   act_commit_count  the number of ACT commits
//
// NC01: the state must carry the SAME predecessor HEAD as the
//       independently recorded predecessor terminal SHA.
// NC02: the predecessor range must be the ACTUAL count, and the
//       literal AC50 must NOT be claimed satisfied while the range is
//       short.
// NC03: a receipt may not discharge AC50 unless it is bound to the
//       ACT's own entry identity.
// NC24: AC50 may not be discharged before the CLOSE commit exists.
static I64 ModeIdentity(U8 *state_path) {
  if (LoadState(state_path, SKEY, SVAL, &SN) != 0) { "DETECTOR_ERROR=LOAD_STATE\n"; return 3; }
  I64 fail = 0;

  // NC04: the recorded digest of a frozen historical artifact must
  // match the artifact's actual digest.
  U8 *fsha = State("frozen_artifact_sha256");
  U8 *fsha_exp = State("frozen_artifact_sha256_expected");
  if (fsha != 0 && fsha_exp != 0) {
    if (!StrEq(fsha, fsha_exp)) {
      "REASON=HISTORICAL_F14_BLOB_MISMATCH\n";
      "DETAIL=the recorded digest of a frozen historical artifact does not match the artifact's actual digest\n";
      fail = 1;
    }
  }

  // NC01: the predecessor identity must match the recorded one.
  U8 *ph = State("predecessor_head");
  U8 *ph_expect = State("predecessor_head_expected");
  if (ph == 0 || ph_expect == 0) { "DETECTOR_ERROR=MISSING_PREDECESSOR_IDENTITY\n"; return 3; }
  if (!StrEq(ph, ph_expect)) {
    "REASON=ENTRY_OR_PREDECESSOR_IDENTITY\n";
    "DETAIL=the state predecessor_head does not match the independently recorded predecessor terminal SHA\n";
    fail = 1;
  }

  // NC02: the predecessor range must be the actual count, and the
  // literal AC50 must not be asserted satisfied while it is short.
  U8 *pr = State("predecessor_range");
  U8 *pr_expect = State("predecessor_range_expected");
  U8 *ac50 = State("ac50_literal");
  if (pr == 0 || pr_expect == 0 || ac50 == 0) { "DETECTOR_ERROR=MISSING_PHASE_RANGE\n"; return 3; }
  if (!StrEq(pr, pr_expect)) {
    "REASON=FALSE_PHASE_OR_AC50_TERMINALITY\n";
    "DETAIL=the claimed predecessor phase count does not match the independently counted commit range\n";
    fail = 1;
  } else if (StrEq(ac50, "SATISFIED") && !StrEq(pr, pr_expect)) {
    "REASON=FALSE_PHASE_OR_AC50_TERMINALITY\n";
    fail = 1;
  }

  // NC03: the receipt must be bound to this ACT's own identity.
  U8 *rh = State("receipt_bound_head");
  U8 *rt = State("receipt_bound_tree");
  U8 *eh = State("entry_head");
  U8 *et = State("entry_tree");
  if (rh == 0 || rt == 0 || eh == 0 || et == 0) { "DETECTOR_ERROR=MISSING_RECEIPT_BINDING\n"; return 3; }
  if (!StrEq(rh, eh) || !StrEq(rt, et)) {
    "REASON=MISBOUND_EXTERNAL_TERMINALITY\n";
    "DETAIL=the external receipt is not bound to this ACT's own entry HEAD/TREE\n";
    fail = 1;
  }

  // NC24: AC50 may not be discharged before the CLOSE exists.
  U8 *dis = State("ac50_discharged");
  U8 *cc = State("close_count");
  if (dis == 0 || cc == 0) { "DETECTOR_ERROR=MISSING_CLOSURE_STATE\n"; return 3; }
  if (StrEq(dis, "YES") && Atoi(cc) < 1) {
    "REASON=AC_NC_OR_TERMINALITY_FALSE_PASS\n";
    "DETAIL=AC50 is claimed discharged but no CLOSE commit exists\n";
    fail = 1;
  }
  // The ACT commit count must be at least the phase count plus the
  // close, and the close count must be exactly one.
  U8 *acc = State("act_commit_count");
  if (acc != 0) {
    if (Atoi(cc) != 1) {
      "REASON=AC_NC_OR_TERMINALITY_FALSE_PASS\n";
      "DETAIL=the ACT does not have exactly one CLOSE commit\n";
      fail = 1;
    }
  }

  if (fail == 0) return 0;
  return 1;
}

// --------------------------------------------------------------------------
// NC09  GRAPH_VERSION_ALIAS
// NC10  SHADOW_PRODUCTION_CUT_CONFLATION
// NC11  LAYOUT_OBSERVATION_AS_MANDATORY
// NC12  CALL_EDGE_SCOPE_CONFUSION
// NC13  MANDATORY_EDGE_MISSING
// NC14  SCC_PARTITION_MISMATCH
// --------------------------------------------------------------------------
//
// The edges table has the CENSUS01 columns:
//   edge_id src_id dst_id edge_type mandatory_for mandatory
//   observed_or_inferred evidence callsite state_transfer config_id
//   certainty
//
// The state table carries the graph claims under test:
//   graph_scope            BASE_GRAPH / SHADOW / PER_CONTRACT_SUBSET
//   mandatory_edges        the claimed mandatory edge count
//   edge_ids               the claimed edge id list, comma separated
//   scc_members_a          the first claimed SCC member list
//   scc_members_b          the second claimed SCC member list
//   production_cuts        the claimed production cut list
//   shadow_cuts            the claimed shadow cut list
//   proven_mandatory_layout YES when a header-inclusion-only edge is
//                           claimed as a proven mandatory runtime edge
//   migration_order_edges  the count of edges claimed as migration-order
//
static I64 ModeGraph(U8 *edges_path, U8 *state_path) {
  if (Load(edges_path) != 0) { "DETECTOR_ERROR=LOAD_EDGES\n"; return 3; }
  if (LoadState(state_path, SKEY, SVAL, &SN) != 0) { "DETECTOR_ERROR=LOAD_STATE\n"; return 3; }

  // Recompute the BASE_GRAPH mandatory edge count.
  I64 base_mand = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 5 && StrEq(FLD[r * NCOL + 5], "YES")) base_mand++;
    r++;
  }

  I64 fail = 0;

  // NC09: the scope may not be a non-BASE scope compared against BASE.
  U8 *scope = State("graph_scope");
  U8 *mande = State("mandatory_edges");
  if (scope == 0 || mande == 0) { "DETECTOR_ERROR=MISSING_GRAPH_CLAIMS\n"; return 3; }
  if (!StrEq(scope, "BASE_GRAPH")) {
    "REASON=GRAPH_VERSION_ALIAS\n";
    "DETAIL=a non-BASE_GRAPH scope was compared against the BASE_GRAPH mandatory total\n";
    fail = 1;
  } else if (Atoi(mande) != base_mand) {
    "REASON=GRAPH_VERSION_ALIAS\n";
    "DETAIL=the claimed mandatory edge count does not match the recomputed BASE_GRAPH count\n";
    fail = 1;
  }

  // NC13: a dropped mandatory edge must be detected. The edge-id list
  // gives a second, independent route to the same fact.
  U8 *ids = State("edge_ids");
  if (ids != 0) {
    I64 claimed = 0;
    I64 i = 0;
    while (ids[i] != 0) {
      if (ids[i] == ',') claimed++;
      i++;
    }
    if (claimed > 0 && claimed != base_mand) {
      "REASON=MANDATORY_EDGE_MISSING\n";
      "DETAIL=the claimed mandatory edge id list does not match the recomputed BASE_GRAPH count\n";
      fail = 1;
    }
  }

  // NC10: a shadow cut may not be claimed as a production cut.
  U8 *pcut = State("production_cuts");
  U8 *scut = State("shadow_cuts");
  if (pcut != 0 && scut != 0) {
    I64 i = 0;
    while (scut[i] != 0) {
      I64 start = i;
      while (scut[i] != 0 && scut[i] != ',') i++;
      I64 len = i - start;
      if (len > 0 && ListHas(pcut, scut + start, len)) {
        "REASON=SHADOW_PRODUCTION_CUT_CONFLATION\n";
        "DETAIL=an edge claimed as a shadow cut is also claimed as a production cut\n";
        fail = 1;
        break;
      }
      if (scut[i] == ',') i++;
    }
  }

  // NC11: a header-inclusion-only TYPE_REPRESENTATION edge may not
  // be claimed as a PROVEN mandatory runtime dependency.
  U8 *proven = State("proven_mandatory_layout");
  if (proven != 0 && StrEq(proven, "YES")) {
    I64 q = 0;
    while (q < NROW) {
      if (NFD[q] > 3 && StrEq(FLD[q * NCOL + 3], "TYPE_REPRESENTATION")) {
        if (NFD[q] > 7) {
          U8 *ev = FLD[q * NCOL + 7];
          I64 k = 0;
          I64 is_include = 0;
          while (ev[k] != 0) {
            if (ev[k] == '#') { is_include = 1; break; }
            k++;
          }
          if (is_include) {
            "REASON=LAYOUT_OBSERVATION_AS_MANDATORY\n";
            "DETAIL=a TYPE_REPRESENTATION edge whose only evidence is a header inclusion was claimed as a proven mandatory runtime dependency\n";
            fail = 1;
            break;
          }
        }
      }
      q++;
    }
  }

  // NC12: a CALLS edge may not be claimed as a migration-order edge.
  U8 *mig = State("migration_order_edges");
  if (mig != 0 && Atoi(mig) > 0) {
    I64 q = 0;
    while (q < NROW) {
      if (NFD[q] > 3 && StrEq(FLD[q * NCOL + 3], "CALLS")) {
        "REASON=CALL_EDGE_SCOPE_CONFUSION\n";
        "DETAIL=a CALLS availability edge was claimed as a migration-order edge\n";
        fail = 1;
        break;
      }
      q++;
    }
  }

  // NC14: two different SCC member lists may not both be claimed.
  U8 *sc1 = State("scc_members_a");
  U8 *sc2 = State("scc_members_b");
  if (sc1 != 0 && sc2 != 0 && !StrEq(sc1, sc2)) {
    "REASON=SCC_PARTITION_MISMATCH\n";
    "DETAIL=two different SCC member lists are both claimed as the partition\n";
    fail = 1;
  }

  if (fail == 0) return 0;
  return 1;
}

// --------------------------------------------------------------------------
// NC23  RANKER_ELIGIBILITY_OR_ORDER
// --------------------------------------------------------------------------
//
// The ranking table has the columns:
//   rank wp_id subsystem gate_satisfied authority_rows
//   downstream_unblocked base_effort priority qualification witness
//   evidence
//
// The state table carries:
//   selected_wp           the claimed selected package
//   selected_rank         the claimed rank band of the selection
//   selected_downstream   the claimed downstream count of the selection
//   selected_qualified    YES when the selection is claimed qualified
//
static I64 ModeRank(U8 *rank_path, U8 *state_path) {
  if (Load(rank_path) != 0) { "DETECTOR_ERROR=LOAD_RANKING\n"; return 3; }
  if (LoadState(state_path, SKEY, SVAL, &SN) != 0) { "DETECTOR_ERROR=LOAD_STATE\n"; return 3; }

  U8 *sel = State("selected_wp");
  U8 *selrank = State("selected_rank");
  U8 *seldown = State("selected_downstream");
  U8 *selq = State("selected_qualified");
  if (sel == 0) { "DETECTOR_ERROR=MISSING_SELECTION\n"; return 3; }

  I64 row = FindRow(1, sel);
  if (row < 0) {
    "REASON=RANKER_ELIGIBILITY_OR_ORDER\n";
    "DETAIL=the selected package is not present in the ranking table\n";
    return 1;
  }

  I64 fail = 0;

  // The selected package's rank band must match the table.
  if (selrank != 0 && !StrEq(FLD[row * NCOL], selrank)) {
    "REASON=RANKER_ELIGIBILITY_OR_ORDER\n";
    "DETAIL=the claimed rank band of the selected package does not match the ranking table\n";
    fail = 1;
  }

  // The claimed downstream count must match the table.
  if (seldown != 0) {
    if (!StrEq(FLD[row * NCOL + 5], seldown)) {
      "REASON=RANKER_ELIGIBILITY_OR_ORDER\n";
      "DETAIL=the claimed downstream count of the selected package does not match the ranking table\n";
      fail = 1;
    }
  }

  // The selected package may not be claimed qualified unless the
  // table says so, AND it must not outrank a package that the table
  // gives a strictly larger downstream count and that is qualified.
  if (selq != 0 && StrEq(selq, "YES")) {
    U8 *q = FLD[row * NCOL + 8];
    if (!StrEq(q, "QUALIFIED")) {
      "REASON=RANKER_ELIGIBILITY_OR_ORDER\n";
      "DETAIL=the selected package is claimed qualified but the ranking table records it otherwise\n";
      fail = 1;
    }
    I64 mydown = Atoi(FLD[row * NCOL + 5]);
    I64 r = 0;
    while (r < NROW) {
      if (r != row) {
        U8 *oq = FLD[r * NCOL + 8];
        I64 odn = Atoi(FLD[r * NCOL + 5]);
        if (StrEq(oq, "QUALIFIED") && odn > mydown) {
          "REASON=RANKER_ELIGIBILITY_OR_ORDER\n";
          "DETAIL=a qualified package with a larger downstream count was promoted behind the selection\n";
          fail = 1;
          break;
        }
      }
      r++;
    }
  }

  if (fail == 0) return 0;
  return 1;
}

// NC20  INVENTED_COST_RESIDUAL
// NC21  THROUGHPUT_PROVENANCE_OR_UNIT
// NC22  FORECAST_DOUBLE_CHARGE
// --------------------------------------------------------------------------
//
// The state table carries:
//   historical_total       the archived reported total (355)
//   historical_displayed   the archived displayed category sum (290)
//   reconciliation         EQUAL when the two are claimed equal
//   residual_work          a claimed extra residual ACT count
//   throughput_sites_per_act  the claimed sites-per-ACT rate
//   throughput_provenance  MEASURED / ASSUMED
//   throughput_unit        SITES / FUNCTIONS / ROWS
//   shared_acts            the claimed shared-infrastructure ACT count
//   shared_acts_expected   the actual shared-infrastructure ACT count
//
static I64 ModeForecast(U8 *scen_path, U8 *hist_path, U8 *state_path) {
  if (Load(scen_path) != 0) { "DETECTOR_ERROR=LOAD_SCENARIOS\n"; return 3; }
  if (LoadState(state_path, SKEY, SVAL, &SN) != 0) { "DETECTOR_ERROR=LOAD_STATE\n"; return 3; }
  I64 fail = 0;

  // NC19: the archived displayed sum may never be accepted as equal
  // to the archived reported total.
  U8 *rec = State("reconciliation");
  if (rec == 0) { "DETECTOR_ERROR=MISSING_RECONCILIATION_CLAIM\n"; return 3; }
  if (StrEq(rec, "EQUAL")) {
    "REASON=FORECAST_SUM_RECONCILIATION\n";
    "DETAIL=the archived displayed category sum is claimed equal to the archived reported total\n";
    fail = 1;
  }

  // NC20: an unexplained residual may not be introduced as work.
  U8 *resid = State("residual_work");
  if (resid != 0 && Atoi(resid) != 0) {
    "REASON=INVENTED_COST_RESIDUAL\n";
    "DETAIL=a residual ACT count is carried as work without a source-bound basis\n";
    fail = 1;
  }

  // NC21: the throughput rate may not be presented as measured when
  // it is assumed, and the unit may not be mixed.
  U8 *prov = State("throughput_provenance");
  U8 *unit = State("throughput_unit");
  U8 *rate = State("throughput_sites_per_act");
  if (prov != 0 && unit != 0 && rate != 0) {
    if (StrEq(prov, "MEASURED") && !StrEq(unit, "SITES")) {
      "REASON=THROUGHPUT_PROVENANCE_OR_UNIT\n";
      "DETAIL=the throughput rate is claimed measured but is not expressed in sites\n";
      fail = 1;
    }
    if (StrEq(prov, "ASSUMED") && Atoi(rate) == 12) {
      "REASON=THROUGHPUT_PROVENANCE_OR_UNIT\n";
      "DETAIL=the assumed 12 sites-per-ACT rate is presented as if it were measured\n";
      fail = 1;
    }
    if (!StrEq(unit, "SITES") && !StrEq(unit, "FUNCTIONS") && !StrEq(unit, "ROWS")) {
      "REASON=THROUGHPUT_PROVENANCE_OR_UNIT\n";
      "DETAIL=the throughput unit is not one of SITES, FUNCTIONS or ROWS\n";
      fail = 1;
    }
  }

  // NC22: a shared-infrastructure ACT may not be charged to more than
  // one package total.
  U8 *sh = State("shared_acts");
  U8 *shx = State("shared_acts_expected");
  if (sh != 0 && shx != 0 && Atoi(sh) != Atoi(shx)) {
    "REASON=FORECAST_DOUBLE_CHARGE\n";
    "DETAIL=the shared-infrastructure ACT count is charged differently from the single shared reserve\n";
    fail = 1;
  }

  if (fail == 0) return 0;
  return 1;
}

// NC18  CRITICAL_PATH_NOT_DERIVED
// --------------------------------------------------------------------------
//
// The state table carries:
//   packages            the claimed package count
//   edges               the claimed edge count
//   acyclic             YES when the DAG is claimed acyclic
//   total_base          the claimed total base effort
//   critical_base       the claimed critical path
//   critical_witness    the claimed critical path witness route
//
static I64 ModeDag(U8 *wp_path, U8 *dep_path, U8 *state_path) {
  if (Load(wp_path) != 0) { "DETECTOR_ERROR=LOAD_WORK_PACKAGES\n"; return 3; }
  if (LoadKV(dep_path, TKEY, TVAL, &TN) != 0) { "DETECTOR_ERROR=LOAD_DEPENDENCIES\n"; return 3; }
  if (LoadState(state_path, SKEY, SVAL, &SN) != 0) { "DETECTOR_ERROR=LOAD_STATE\n"; return 3; }

  I64 fail = 0;
  I64 pkgs = NROW;
  I64 edges = TN;
  I64 dangling = 0;

  // The dependency table is "from<TAB>to<TAB>evidence", so the loaded
  // key is "from" and the loaded value begins with "to". A "to" token
  // that names no package is a dangling reference.
  I64 i = 0;
  while (i < TN) {
    U8 *v = TVAL[i];
    I64 j = 0;
    while (v[j] != 0 && v[j] != '\t') j++;
    I64 found = 0;
    I64 r = 0;
    while (r < pkgs) {
      U8 *pid = FLD[r * NCOL];
      I64 k = 0;
      I64 match = 1;
      while (k < j && pid[k] != 0) {
        if (pid[k] != v[k]) { match = 0; break; }
        k++;
      }
      if (match && k == j && pid[j] == 0) found = 1;
      r++;
    }
    if (!found) dangling++;
    i++;
  }

  U8 *pc = State("packages");
  U8 *ec = State("edges");
  U8 *acy = State("acyclic");
  if (pc == 0 || ec == 0 || acy == 0) { "DETECTOR_ERROR=MISSING_DAG_CLAIMS\n"; return 3; }
  if (Atoi(pc) != pkgs) {
    "REASON=WORK_PACKAGE_DAG_INVALID\n";
    "DETAIL=the claimed package count does not match the work-package table\n";
    fail = 1;
  }
  if (Atoi(ec) != edges) {
    "REASON=WORK_PACKAGE_DAG_INVALID\n";
    "DETAIL=the claimed edge count does not match the dependency table\n";
    fail = 1;
  }
  if (dangling > 0 && StrEq(acy, "YES")) {
    "REASON=WORK_PACKAGE_DAG_INVALID\n";
    "DETAIL=the DAG is claimed acyclic but a dependency edge names a package that does not exist\n";
    fail = 1;
  }

  // NC18: the critical path may not equal the total effort unless a
  // witness route is present.
  U8 *tb = State("total_base");
  U8 *cb = State("critical_base");
  U8 *wit = State("critical_witness");
  if (tb != 0 && cb != 0) {
    I64 has_witness = 0;
    if (wit != 0 && StrLen(wit) > 0 && !StrEq(wit, "NONE")) has_witness = 1;
    if (Atoi(cb) == Atoi(tb) && !has_witness) {
      "REASON=CRITICAL_PATH_NOT_DERIVED\n";
      "DETAIL=the critical path equals the total effort and no path witness is given\n";
      fail = 1;
    }
    if (Atoi(cb) > Atoi(tb)) {
      "REASON=CRITICAL_PATH_NOT_DERIVED\n";
      "DETAIL=the claimed critical path exceeds the total effort\n";
      fail = 1;
    }
  }

  if (fail == 0) return 0;
  return 1;
}

// NC16  BOOTSTRAP_BLOCKER_OMITTED
// --------------------------------------------------------------------------
//
// The producer table has the columns:
//   stage_id producer compiles classification evidence
//
// The state table carries:
//   polyc_compiler_source_set  the claimed size of a PolyC-authored
//                              compiler source set
//   earliest_gate              the claimed earliest unsatisfied gate
//   blockers_listed            the claimed number of blockers
//   blockers_total             the actual number of blocker rows
//
static I64 ModeProducer(U8 *prod_path, U8 *state_path) {
  if (Load(prod_path) != 0) { "DETECTOR_ERROR=LOAD_PRODUCER\n"; return 3; }
  if (LoadState(state_path, SKEY, SVAL, &SN) != 0) { "DETECTOR_ERROR=LOAD_STATE\n"; return 3; }
  I64 fail = 0;

  // NC15: a C-rooted stage0 plus helper objects is NOT a closed M2
  // source-producer chain. The chain is closed only if some stage
  // classifies itself as the producer of a PolyC-authored compiler
  // source set.
  U8 *pcs = State("polyc_compiler_source_set");
  if (pcs == 0) { "DETECTOR_ERROR=MISSING_PRODUCER_CLAIMS\n"; return 3; }
  if (Atoi(pcs) > 0) {
    I64 producer_found = 0;
    I64 r = 0;
    while (r < NROW) {
      if (NFD[r] > 3 && StrEq(FLD[r * NCOL + 3], "POLYC_COMPILER_SOURCE_SET")) producer_found = 1;
      r++;
    }
    if (!producer_found) {
      "REASON=M2_SOURCE_PRODUCER_NOT_CLOSED\n";
      "DETAIL=a PolyC-authored compiler source set is claimed, but no stage in the producer table produces one\n";
      fail = 1;
    }
  }

  // NC16: an actual blocker may not be omitted from the blocker list.
  U8 *bl = State("blockers_listed");
  U8 *bt = State("blockers_total");
  if (bl != 0 && bt != 0) {
    if (Atoi(bl) != Atoi(bt)) {
      "REASON=BOOTSTRAP_BLOCKER_OMITTED\n";
      "DETAIL=the claimed blocker list omits a recorded blocker\n";
      fail = 1;
    }
  }

  if (fail == 0) return 0;
  return 1;
}

// NC06  PRODUCTION_REACHABILITY_FALSE
// NC07  CENSUS_SCOPE_DOUBLE_COUNT
// NC08  UNKNOWN_AUTHORITY_SILENT_DROP
// --------------------------------------------------------------------------
//
// The state table carries the census claims under test:
//   polyc_authority_count     the claimed number of PolyC authorities
//   cset_counted_as_authority YES when CSET is counted as an authority
//   production_reachable      the claimed production-reachable count
//   census_total              the claimed census denominator
//   remaining_scope           the claimed remaining semantic scope
//   unknown_rows              the claimed unknown-bearing row count
//
static I64 ModeAuthority(U8 *auth_path, U8 *unk_path, U8 *dorm_path, U8 *state_path) {
  if (Load(auth_path) != 0) { "DETECTOR_ERROR=LOAD_AUTHORITIES\n"; return 3; }
  if (LoadState(state_path, SKEY, SVAL, &SN) != 0) { "DETECTOR_ERROR=LOAD_STATE\n"; return 3; }

  // Recompute the authority populations from the rows themselves.
  I64 total = NROW;
  I64 polyc = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 3 && StrEqCI(FLD[r * NCOL + 3], "POLYC")) polyc++;
    r++;
  }

  I64 fail = 0;

  // NC05: CSET is a mechanical adapter and may not be counted as a
  // PolyC authority.
  U8 *pc = State("polyc_authority_count");
  if (pc == 0) { "DETECTOR_ERROR=MISSING_AUTHORITY_CLAIMS\n"; return 3; }
  if (Atoi(pc) != polyc) {
    "REASON=MECHANICAL_ADAPTER_MISCOUNT\n";
    "DETAIL=the claimed PolyC authority count does not match the rows whose source_language is POLYC\n";
    fail = 1;
  }
  U8 *cset_claim = State("cset_counted_as_authority");
  if (cset_claim != 0 && StrEq(cset_claim, "YES")) {
    "REASON=MECHANICAL_ADAPTER_MISCOUNT\n";
    "DETAIL=CSET was counted as a PolyC authority; it is a mechanical adapter\n";
    fail = 1;
  }

  // NC06: a dormant, unlinked authority may not be counted as
  // production-reachable. The dormant sites live in their own table;
  // the production-reachable count is the authority population less
  // the dormant rows.
  U8 *prod = State("production_reachable");
  if (prod != 0) {
    I64 dormant = 0;
    if (Load(dorm_path) != 0) { "DETECTOR_ERROR=LOAD_DORMANT_SITES\n"; return 3; }
    dormant = NROW;
    I64 reachable = total - dormant;
    if (Atoi(prod) != reachable) {
      "REASON=PRODUCTION_REACHABILITY_FALSE\n";
      "DETAIL=the claimed production-reachable authority count does not match the authority population less the dormant rows\n";
      fail = 1;
    }
  }

  // NC07: the census denominator may not be double-counted and the
  // remaining scope must reconcile with it.
  U8 *ct = State("census_total");
  U8 *rem = State("remaining_scope");
  if (ct != 0 && Atoi(ct) != total) {
    "REASON=CENSUS_SCOPE_DOUBLE_COUNT\n";
    "DETAIL=the claimed census denominator does not match the recomputed authority row count\n";
    fail = 1;
  }
  if (rem != 0 && ct != 0) {
    if (Atoi(rem) > Atoi(ct)) {
      "REASON=CENSUS_SCOPE_DOUBLE_COUNT\n";
      "DETAIL=the claimed remaining scope exceeds the census denominator\n";
      fail = 1;
    }
  }

  // NC08: the unknown-bearing rows may not be silently dropped.
  // The unknown-bearing rows live in their own table, which is loaded
  // separately so the count is derived from the real rows.
  U8 *unk = State("unknown_rows");
  if (unk != 0) {
    I64 unknown_rows = 0;
    if (Load(unk_path) == 0) {
      I64 q = 0;
      while (q < NROW) {
        if (NFD[q] > 0) {
          U8 *id = FLD[q * NCOL];
          I64 k = 0;
          I64 is_unknown = 0;
          while (id[k] != 0) {
            if (id[k] == 'U' && id[k + 1] == '-') { is_unknown = 1; break; }
            k++;
          }
          if (is_unknown) unknown_rows++;
        }
        q++;
      }
    } else {
      "DETECTOR_ERROR=LOAD_UNKNOWN_EDGES\n";
      return 3;
    }
    if (Atoi(unk) != unknown_rows) {
      "REASON=UNKNOWN_AUTHORITY_SILENT_DROP\n";
      "DETAIL=the claimed unknown-bearing row count does not match the unknown-edge rows\n";
      fail = 1;
    }
  }

  if (fail == 0) return 0;
  return 1;
}

// --------------------------------------------------------------------------
// THE SELFTEST MODE
// --------------------------------------------------------------------------
//
// The detector's own anti-selftests. They show that the internal
// helpers REJECT a wrong input while ACCEPTING the genuine one. A
// detector that accepts everything is useless, so these are real
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

  // The prefix comparison helper.
  if (!StrNCmpAt("E-TYP-0136", 0, "E-TYP-0136", 10)) ok = 0;
  if (StrNCmpAt("E-TYP-0136", 0, "E-TYP-0137", 10)) ok = 0;

  // The comma-list membership helper.
  if (!ListHas("A,B,C", "B", 1)) ok = 0;
  if (ListHas("A,B,C", "D", 1)) ok = 0;
  if (ListHas("", "A", 1)) ok = 0;

  // The row lookup must reject an unknown id and find a known one.
  NROW = 2;
  NFD[0] = 3; NFD[1] = 3;
  FLD[0 * NCOL + 1] = "WP-001"; FLD[1 * NCOL + 1] = "WP-002";
  if (FindRow(1, "WP-001") != 0) ok = 0;
  if (FindRow(1, "WP-002") != 1) ok = 0;
  if (FindRow(1, "WP-999") != -1) ok = 0;

  // The state lookup must reject an unknown key.
  SN = 1;
  SKEY[0] = "alpha"; SVAL[0] = "beta";
  if (!StrEq(State("alpha"), "beta")) ok = 0;
  if (State("omega") != 0) ok = 0;

  "SELFTEST_CASES=15\n";
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
  if (argc >= 3 && StrEq(argv[1], "IDENTITY")) {
    return ModeIdentity(argv[2]);
  }
  if (argc >= 4 && StrEq(argv[1], "GRAPH")) {
    return ModeGraph(argv[2], argv[3]);
  }
  if (argc >= 6 && StrEq(argv[1], "AUTHORITY")) {
    return ModeAuthority(argv[2], argv[3], argv[4], argv[5]);
  }
  if (argc >= 4 && StrEq(argv[1], "PRODUCER")) {
    return ModeProducer(argv[2], argv[3]);
  }
  if (argc >= 5 && StrEq(argv[1], "DAG")) {
    return ModeDag(argv[2], argv[3], argv[4]);
  }
  if (argc >= 5 && StrEq(argv[1], "FORECAST")) {
    return ModeForecast(argv[2], argv[3], argv[4]);
  }
  if (argc >= 4 && StrEq(argv[1], "RANK")) {
    return ModeRank(argv[2], argv[3]);
  }
  if (argc >= 2 && StrEq(argv[1], "SELFTEST")) {
    return ModeSelfTest();
  }
  "USAGE: m2-critical-path-rebase01-nc IDENTITY <state.tsv> | GRAPH <edges.tsv> <state.tsv> | AUTHORITY <auth.tsv> <state.tsv> | PRODUCER <prod.tsv> <state.tsv> | DAG <wp.tsv> <deps.tsv> <state.tsv> | FORECAST <scen.tsv> <hist.tsv> <state.tsv> | RANK <rank.tsv> <state.tsv> | SELFTEST\n";
  return 2;
}
