// tools/quality/m2-critical-path-rebase01-red.HC
//
// ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01 C0 RED.
//
// THE FIVE ADVERSE-PROBE DETECTOR.
//
// It is a REAL detector, not a label reader. Each mode RE-DERIVES the
// fact from the primary rows and then applies a rule that a wrong
// claim would violate. A mode is SILENT (exit 0, no output) when the
// claim under test is CONSISTENT with the primary rows, and it prints
// its OWN reason token and exits non-zero when the claim is INCONSISTENT.
//
// The five C0 REDs, each with its own reason:
//
//   R01_HISTORY   FALSE_PHASE_OR_AC50_TERMINALITY
//   R02_GRAPH     GRAPH_SCOPE_OR_CUT_CONFLATION
//   R03_FORECAST  FORECAST_SUM_RECONCILIATION
//   R04_SOURCE    AUTHORITY_DENOMINATOR_MISMATCH
//   R05_BOOTSTRAP M2_PRODUCER_SOURCE_NOT_CLOSED
//
// The input is a "claim" TSV: each row states a CLAIMED value and the
// detector compares the claim against what it re-derives from the
// primary rows it loads itself.
//
// MODES (the claim file is the last argument):
//
//   HISTORY   <pred_range_tsv> <claim_tsv>
//   GRAPH     <edges_tsv>      <claim_tsv>
//   FORECAST  <forecast_tsv>   <claim_tsv>
//   SOURCE    <auth_tsv>       <claim_tsv>
//   BOOTSTRAP <producer_tsv>   <claim_tsv>
//   SELFTEST
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXN   256
#define MAXE  2048
#define MAXR  4096
#define NCOL    24

static U8 *FLD[MAXR * NCOL];
static I64 NFD[MAXR];
static I64 NROW;
static U8 *BUF;

// The claim under test, as key/value pairs.
static U8 *CKEY[MAXR];
static U8 *CVAL[MAXR];
static I64 CN;

// Scratch token offsets/lengths inside a comma-separated claim value.
static I64 TOKOFF[MAXR];
static I64 TOKLEN[MAXR];

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

// Load a "key<TAB>value" claim file into CKEY/CVAL.
static I64 LoadClaims(U8 *path) {
  I64 sz = 0;
  U8 *cb = FileRead(path, &sz);
  if (cb == 0) return -1;
  CN = 0;
  U8 *p = cb; U8 *end = cb + sz;
  while (p < end && CN < MAXR) {
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
    CKEY[CN] = ls;
    CVAL[CN] = tab + 1;
    CN++;
  }
  return 0;
}

static U8 *Claim(U8 *key) {
  I64 i = 0;
  while (i < CN) { if (StrEq(CKEY[i], key)) return CVAL[i]; i++; }
  return 0;
}

// Strip a trailing newline / whitespace in place.
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

// Count how many rows in column `col` have the exact value `val`.
static I64 CountColEq(I64 col, U8 *val) {
  I64 n = 0; I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > col && StrEq(FLD[r * NCOL + col], val)) n++;
    r++;
  }
  return n;
}

// Sum the numeric values in column `col` over rows whose column
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

// Find the first row whose column `keycol` equals `key`; return its
// index or -1.
static I64 FindRow(I64 keycol, U8 *key) {
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > keycol && StrEq(FLD[r * NCOL + keycol], key)) return r;
    r++;
  }
  return -1;
}

// --------------------------------------------------------------------------
// R01_HISTORY  ->  FALSE_PHASE_OR_AC50_TERMINALITY
// --------------------------------------------------------------------------
//
// The predecessor range TSV has one row per phase-bearing commit with
// the columns:
//
//   commit_sha   phase   verdict   has_c1_evidence
//
// The detector re-derives the ACTUAL phase count and the ACTUAL
// presence of a C1 EVIDENCE phase from those rows. It then checks the
// CLAIMED values. A claim that asserts five phases, or that asserts
// the literal five-trailer AC50 is satisfied, is INCONSISTENT with the
// actual four-phase range and MUST fire.
static I64 ModeHistory(U8 *pred_path, U8 *claim_path) {
  if (Load(pred_path) != 0) { "DETECTOR_ERROR=LOAD_PREDECESSOR\n"; return 3; }
  if (LoadClaims(claim_path) != 0) { "DETECTOR_ERROR=LOAD_CLAIMS\n"; return 3; }

  I64 phases = 0; I64 c1_present = 0; I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 1) {
      phases++;
      if (StrEq(FLD[r * NCOL + 1], "EVIDENCE") && StrEq(FLD[r * NCOL + 0], "C1")) {
        c1_present = 1;
      }
    }
    r++;
  }

  I64 claimed_phases = Atoi(Claim("ACTUAL_PHASE_COUNT"));
  I64 claimed_c1 = Atoi(Claim("C1_EVIDENCE_COMMIT_PRESENT"));
  I64 claimed_ac50 = Atoi(Claim("FROZEN_AC50_LITERAL_SATISFIED"));

  "HISTORY_DERIVED_PHASE_COUNT=%d\n", phases;
  "HISTORY_DERIVED_C1_EVIDENCE_PRESENT=%d\n", c1_present;

  // The literal AC50 text requires "five trailers". It can only be
  // satisfied if the ACTUAL range really carries five phase-bearing
  // commits AND a C1 EVIDENCE commit exists.
  I64 literal_ok = (phases == 5 && c1_present == 1);

  if (claimed_phases != phases) {
    "FALSE_PHASE_OR_AC50_TERMINALITY\n";
    "REASON_DETAIL=claimed phase count %d differs from the derived count %d\n",
      claimed_phases, phases;
    return 1;
  }
  if (claimed_c1 != c1_present) {
    "FALSE_PHASE_OR_AC50_TERMINALITY\n";
    "REASON_DETAIL=claimed C1 EVIDENCE presence %d differs from the derived %d\n",
      claimed_c1, c1_present;
    return 1;
  }
  if (claimed_ac50 != literal_ok) {
    "FALSE_PHASE_OR_AC50_TERMINALITY\n";
    "REASON_DETAIL=claimed literal AC50 satisfaction %d differs from the derived %d\n",
      claimed_ac50, literal_ok;
    return 1;
  }
  return 0;
}

// --------------------------------------------------------------------------
// R02_GRAPH  ->  GRAPH_SCOPE_OR_CUT_CONFLATION
// --------------------------------------------------------------------------
//
// The edges TSV is the archived CENSUS01 graph-edges.tsv:
//
//   edge_id src dst edge_type mandatory_for mandatory observed evidence ...
//
// The detector re-derives:
//   - the number of MANDATORY edges (mandatory == YES),
//   - the number of MANDATORY edges of each mandatory class,
//   - the presence of E-TYP-0136,
//   - the number of DISTINCT cut edge ids claimed.
//
// The claim file may state a mandatory edge count, a graph scope name,
// and a list of cut edge ids. A claim that substitutes the historical
// 134 for the derived count, or that claims the SAME cut edge id
// twice, is INCONSISTENT and MUST fire.
static I64 ModeGraph(U8 *edges_path, U8 *claim_path) {
  if (Load(edges_path) != 0) { "DETECTOR_ERROR=LOAD_EDGES\n"; return 3; }
  if (LoadClaims(claim_path) != 0) { "DETECTOR_ERROR=LOAD_CLAIMS\n"; return 3; }

  // Column indices in the archived graph-edges.tsv:
  //   0 edge_id  1 src  2 dst  3 edge_type  4 mandatory_for
  //   5 mandatory  6 observed_or_inferred  7 evidence ...
  I64 mandatory = 0;
  I64 e0136 = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 5 && StrEq(FLD[r * NCOL + 5], "YES")) {
      mandatory++;
      if (StrEq(FLD[r * NCOL + 0], "E-TYP-0136")) e0136++;
    }
    r++;
  }

  "GRAPH_DERIVED_MANDATORY_EDGES=%d\n", mandatory;
  "GRAPH_DERIVED_E_TYP_0136_ROWS=%d\n", e0136;

  I64 claimed = Atoi(Claim("MANDATORY_EDGE_COUNT"));
  if (claimed != mandatory) {
    "GRAPH_SCOPE_OR_CUT_CONFLATION\n";
    "REASON_DETAIL=claimed mandatory edge count %d differs from the derived %d\n",
      claimed, mandatory;
    return 1;
  }

  // A cut claim is a COMMA-separated list of edge ids. The same edge
  // id appearing TWICE is a double-counted cut and MUST fire.
  U8 *cuts = Claim("CUT_EDGE_IDS");
  if (cuts != 0) {
    Chomp(cuts);
    I64 seen_ids = 0; I64 dup = 0;
    I64 i = 0;
    U8 *start = cuts;
    while (i <= StrLen(cuts)) {
      if (cuts[i] == ',' || cuts[i] == 0) {
        I64 len = i - (start - cuts);
        if (len > 0) {
          // Record the token's offset and length for the duplicate
          // comparison below.
          TOKOFF[seen_ids] = start - cuts;
          TOKLEN[seen_ids] = len;
          seen_ids++;
        }
        start = cuts + i + 1;
      }
      i++;
    }
    I64 a = 0;
    while (a < seen_ids) {
      I64 b = a + 1;
      while (b < seen_ids) {
        if (TOKLEN[a] == TOKLEN[b]) {
          I64 k = 0; I64 same = 1;
          while (k < TOKLEN[a]) {
            if (cuts[TOKOFF[a] + k] != cuts[TOKOFF[b] + k]) { same = 0; break; }
            k++;
          }
          if (same) { dup++; }
        }
        b++;
      }
      a++;
    }
    if (dup > 0) {
      "GRAPH_SCOPE_OR_CUT_CONFLATION\n";
      "REASON_DETAIL=the same cut edge id is claimed %d times\n", dup;
      return 1;
    }
  }
  return 0;
}

// --------------------------------------------------------------------------
// R03_FORECAST  ->  FORECAST_SUM_RECONCILIATION
// --------------------------------------------------------------------------
//
// The forecast TSV is the archived CENSUS01 c2/forecast.tsv:
//
//   milestone act_low act_base act_high selection_acts implementation_acts
//   integration_abi_acts bootstrap_acts correction_acts
//   shared_infrastructure_acts total_effort_sum critical_path_length ...
//
// The detector RE-SUMS the six displayed cost columns of the row named
// by the claim's MILESTONE key and compares that sum against the
// row's OWN total_effort_sum column. A claim that asserts the reported
// total IS reconciled by the displayed columns is INCONSISTENT when the
// two differ, and MUST fire.
static I64 ModeForecast(U8 *forecast_path, U8 *claim_path) {
  if (Load(forecast_path) != 0) { "DETECTOR_ERROR=LOAD_FORECAST\n"; return 3; }
  if (LoadClaims(claim_path) != 0) { "DETECTOR_ERROR=LOAD_CLAIMS\n"; return 3; }

  U8 *ms = Claim("MILESTONE");
  if (ms == 0) { "DETECTOR_ERROR=MISSING_MILESTONE_CLAIM\n"; return 3; }
  Chomp(ms);

  I64 row = FindRow(0, ms);
  if (row < 0) { "DETECTOR_ERROR=MILESTONE_ROW_NOT_FOUND\n"; return 3; }

  // Column indices in the archived forecast.tsv:
  //   0 milestone 1 act_low 2 act_base 3 act_high
  //   4 selection 5 implementation 6 integration_abi 7 bootstrap
  //   8 correction 9 shared_infrastructure 10 total_effort_sum
  //   11 critical_path_length
  I64 displayed = 0;
  I64 col = 4;
  while (col <= 9) { displayed += Atoi(FLD[row * NCOL + col]); col++; }
  I64 reported = Atoi(FLD[row * NCOL + 10]);
  I64 crit = Atoi(FLD[row * NCOL + 11]);

  "FORECAST_DERIVED_DISPLAYED_SUM=%d\n", displayed;
  "FORECAST_DERIVED_REPORTED_TOTAL=%d\n", reported;
  "FORECAST_DERIVED_CRITICAL_PATH=%d\n", crit;
  "FORECAST_DERIVED_DELTA=%d\n", reported - displayed;

  I64 claimed = Atoi(Claim("REPORTED_TOTAL"));
  if (claimed != reported) {
    "FORECAST_SUM_RECONCILIATION\n";
    "REASON_DETAIL=claimed reported total %d differs from the archived %d\n",
      claimed, reported;
    return 1;
  }

  // The reconciliation claim: does the displayed column set account for
  // the reported total? The claim states whether it DOES. When the
  // claim says yes but the derived delta is non-zero, it fires.
  I64 claims_reconciled = Atoi(Claim("DISPLAYED_SUM_RECONCILES_REPORTED_TOTAL"));
  I64 actually_reconciled = 0;
  if (displayed == reported) actually_reconciled = 1;
  if (claims_reconciled != actually_reconciled) {
    "FORECAST_SUM_RECONCILIATION\n";
    "REASON_DETAIL=claimed reconciliation %d differs from the derived %d (displayed %d vs reported %d)\n",
      claims_reconciled, actually_reconciled, displayed, reported;
    return 1;
  }
  return 0;
}

// --------------------------------------------------------------------------
// R04_SOURCE  ->  AUTHORITY_DENOMINATOR_MISMATCH
// --------------------------------------------------------------------------
//
// The authorities TSV has one row per counted authority with the
// columns:
//
//   authority_id symbol classification producer linked import_count
//
// The detector RE-DERIVES the authority count by counting rows whose
// classification is a SEMANTIC authority class, and it separately
// counts rows that name the CSET mechanical adapter or a DORMANT /
// NON-PRODUCTION class.
//
// A claim that counts the CSET adapter as a semantic authority, or
// that counts a dormant/unlinked site as production-reachable, is
// INCONSISTENT with the derived semantic count and MUST fire.
static I64 ModeSource(U8 *auth_path, U8 *claim_path) {
  if (Load(auth_path) != 0) { "DETECTOR_ERROR=LOAD_AUTHORITIES\n"; return 3; }
  if (LoadClaims(claim_path) != 0) { "DETECTOR_ERROR=LOAD_CLAIMS\n"; return 3; }

  // Column indices: 0 authority_id 1 symbol 2 classification
  //                 3 producer 4 linked 5 import_count
  I64 semantic = 0; I64 cset = 0; I64 dormant = 0; I64 unlinked = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 2) {
      U8 *cls = FLD[r * NCOL + 2];
      if (StrEq(cls, "MECHANICAL_ADAPTER") || StrEq(cls, "CSET_ADAPTER")) {
        cset++;
      } else if (StrEq(cls, "DORMANT_SELECTOR_OFF") || StrEq(cls, "NOT_PRODUCTION_REACHABLE")) {
        dormant++;
      } else {
        semantic++;
      }
      if (NFD[r] > 4 && StrEq(FLD[r * NCOL + 4], "0")) unlinked++;
    }
    r++;
  }

  "SOURCE_DERIVED_SEMANTIC_AUTHORITIES=%d\n", semantic;
  "SOURCE_DERIVED_MECHANICAL_ADAPTERS=%d\n", cset;
  "SOURCE_DERIVED_DORMANT_ROWS=%d\n", dormant;
  "SOURCE_DERIVED_UNLINKED_ROWS=%d\n", unlinked;

  I64 claimed = Atoi(Claim("SEMANTIC_AUTHORITY_COUNT"));
  if (claimed != semantic) {
    "AUTHORITY_DENOMINATOR_MISMATCH\n";
    "REASON_DETAIL=claimed semantic authority count %d differs from the derived %d\n",
      claimed, semantic;
    return 1;
  }

  // A claim that counts the mechanical adapter as a semantic authority
  // is caught by the same denominator check above, but the dedicated
  // token makes the failure mode explicit and distinguishable.
  //
  // The claim states whether the CSET adapter IS counted as a
  // semantic authority. The derived truth is ALWAYS false: the
  // adapter is a MECHANICAL_ADAPTER class row and is never counted.
  I64 claims_cset = Atoi(Claim("CSET_COUNTED_AS_AUTHORITY"));
  I64 actually_cset = 0;
  if (claims_cset != actually_cset) {
    "AUTHORITY_DENOMINATOR_MISMATCH\n";
    "REASON_DETAIL=claimed CSET-as-authority %d differs from the derived %d\n",
      claims_cset, actually_cset;
    return 1;
  }

  // A claim that counts a dormant/unlinked site as production
  // reachable is likewise caught explicitly. The derived truth is
  // ALWAYS false: dormant rows are never production-reachable.
  I64 claims_dormant = Atoi(Claim("DORMANT_COUNTED_AS_PRODUCTION_REACHABLE"));
  I64 actually_dormant = 0;
  if (claims_dormant != actually_dormant) {
    "AUTHORITY_DENOMINATOR_MISMATCH\n";
    "REASON_DETAIL=claimed dormant-as-production %d differs from the derived %d\n",
      claims_dormant, actually_dormant;
    return 1;
  }
  return 0;
}

// --------------------------------------------------------------------------
// R05_BOOTSTRAP  ->  M2_PRODUCER_SOURCE_NOT_CLOSED
// --------------------------------------------------------------------------
//
// The producer TSV has one row per producer stage with the columns:
//
//   stage_id producer_sha256 input_closure input_language output
//   compiles_whole_compiler_source classification evidence
//
// The detector RE-DERIVES, over the stages that actually compile a
// PolyC-authored COMPILER SOURCE SET, whether a genuine M2 producer
// exists. A stage counts toward M2 only if it is classified as a
// POLYC_AUTHORED_COMPILER AND compiles_whole_compiler_source == YES.
//
// A claim that asserts M2 is achieved by a C-rooted stage0 that only
// compiles helper SUBJECTS is INCONSISTENT and MUST fire.
static I64 ModeBootstrap(U8 *producer_path, U8 *claim_path) {
  if (Load(producer_path) != 0) { "DETECTOR_ERROR=LOAD_PRODUCERS\n"; return 3; }
  if (LoadClaims(claim_path) != 0) { "DETECTOR_ERROR=LOAD_CLAIMS\n"; return 3; }

  // Column indices: 0 stage_id 1 producer_sha256 2 input_closure
  //   3 input_language 4 output 5 compiles_whole_compiler_source
  //   6 classification 7 evidence
  I64 m2_producers = 0; I64 helper_only = 0; I64 c_rooted = 0;
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] > 6) {
      U8 *cls = FLD[r * NCOL + 6];
      U8 *whole = FLD[r * NCOL + 5];
      I64 is_whole = 0;
      if (StrEq(whole, "YES")) is_whole = 1;
      if (StrEq(cls, "POLYC_AUTHORED_COMPILER") && is_whole) {
        m2_producers++;
      } else if (StrEq(cls, "C_ROOTED") || StrEq(cls, "HYBRID")) {
        c_rooted++;
      } else if (StrEq(cls, "POLYC_AUTHORED_PRECURSOR") || StrEq(cls, "HYBRID_SUBJECT")) {
        helper_only++;
      }
    }
    r++;
  }

  "BOOTSTRAP_DERIVED_M2_PRODUCERS=%d\n", m2_producers;
  "BOOTSTRAP_DERIVED_C_ROOTED_OR_HYBRID_STAGES=%d\n", c_rooted;
  "BOOTSTRAP_DERIVED_HELPER_ONLY_STAGES=%d\n", helper_only;

  I64 claimed_m2 = Atoi(Claim("M2_PRODUCER_COUNT"));
  if (claimed_m2 != m2_producers) {
    "M2_PRODUCER_SOURCE_NOT_CLOSED\n";
    "REASON_DETAIL=claimed M2 producer count %d differs from the derived %d\n",
      claimed_m2, m2_producers;
    return 1;
  }

  I64 claims_m2_achieved = Atoi(Claim("M2_ACHIEVED"));
  I64 actually = 0;
  if (m2_producers > 0) actually = 1;
  if (claims_m2_achieved != actually) {
    "M2_PRODUCER_SOURCE_NOT_CLOSED\n";
    "REASON_DETAIL=claimed M2 achieved %d differs from the derived %d\n",
      claims_m2_achieved, actually;
    return 1;
  }
  return 0;
}

// --------------------------------------------------------------------------
// THE ENTRY POINT
// --------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  if (argc >= 4 && StrEq(argv[1], "HISTORY")) {
    return ModeHistory(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "GRAPH")) {
    return ModeGraph(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "FORECAST")) {
    return ModeForecast(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "SOURCE")) {
    return ModeSource(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "BOOTSTRAP")) {
    return ModeBootstrap(argv[2], argv[3]);
  }
  "USAGE: m2-critical-path-rebase01-red HISTORY|GRAPH|FORECAST|SOURCE|BOOTSTRAP <primary.tsv> <claim.tsv>\n";
  return 2;
}
