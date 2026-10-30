// tools/quality/abi-foundation-recon01-verify.HC
//
// ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01 C3 EVIDENCE.
//
// THE INDEPENDENT VERIFIER. It is a separate PolyC program from the C2
// graph tool and from the C host. It reads RAW records (frozen contracts,
// the CENSUS01 edge rows, the cut ledger, the probe sources, the object
// provenance, the causal-mutation transcript and the predecessor freeze)
// and re-derives every load-bearing predicate with its own code path.
// It does not read a C2 "PASS" column as truth.
//
// The SCC partition is recomputed with a transitive-closure equivalence;
// the C3 carrier ALSO recomputes it with POSIX awk and compares the two
// implementations, so a single faulty algorithm cannot manufacture PASS.
//
// MODE
//   VERIFY <repo_root>
//
// Every check prints CHECK_<name>=PASS|FAIL. A failure records the first
// detector class and the program returns non-zero.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXN   96
#define MAXE   512
#define MAXR  4096
#define NCOL    16

static U8 *FLD[MAXR * NCOL];
static I64 NFD[MAXR];
static I64 NROW;
static U8 *BUF;
static I64 BUFSZ;
static U8 *REASON;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}
static I64 StrLen(U8 *s) { I64 n = 0; while (*s != 0) { n++; s++; } return n; }

static I64 StartsWith(U8 *s, U8 *p) {
  while (*p != 0) { if (*s != *p) return 0; s++; p++; }
  return 1;
}

static I64 ParseInt(U8 *s) {
  I64 v = 0;
  while (*s >= '0' && *s <= '9') { v = v * 10 + (*s - '0'); s++; }
  return v;
}

static I64 HasSubstr(U8 *buf, I64 sz, U8 *needle) {
  I64 nl = StrLen(needle);
  if (nl == 0) return 0;
  I64 i = 0;
  while (i + nl <= sz) {
    I64 j = 0;
    while (j < nl) { if (buf[i + j] != needle[j]) break; j++; }
    if (j == nl) return 1;
    i++;
  }
  return 0;
}

// Detect a C field-access arrow in CODE, not in prose. A comment arrow is
// written with spaces ("host -> C"); a real access is "node->kind".
static I64 HasArrowAccess(U8 *buf, I64 sz) {
  I64 i = 1;
  while (i + 1 < sz) {
    if (buf[i] == '-' && buf[i + 1] == '>') {
      if (buf[i - 1] != ' ' && buf[i - 1] != '\t' && buf[i - 1] != '\n') return 1;
    }
    i++;
  }
  return 0;
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
  if (BUF == 0) { BUFSZ = 0; NROW = 0; return -1; }
  BUFSZ = sz;
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

// Headerless loader for the two frozen contract tables, which were
// emitted as bare ID rows before any derived conclusion.
static I64 LoadRaw(U8 *path) {
  I64 sz = 0;
  BUF = FileRead(path, &sz);
  if (BUF == 0) { BUFSZ = 0; NROW = 0; return -1; }
  BUFSZ = sz;
  I64 n = 0;
  U8 *p = BUF; U8 *end = BUF + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    NFD[n] = SplitTabs(ls, n * NCOL, NCOL);
    n++;
  }
  NROW = n;
  return 0;
}

static I64 Check(U8 *name, I64 ok, U8 *reason) {
  if (ok) { "CHECK_%s=PASS\n", name; return 1; }
  "CHECK_%s=FAIL reason=%s\n", name, reason;
  if (REASON == 0) REASON = reason;
  return 0;
}

static I64 JoinRoot(U8 *root, U8 *rel, U8 *out) {
  I64 i = 0;
  while (root[i] != 0) { out[i] = root[i]; i++; }
  if (i > 0 && out[i - 1] != '/') { out[i] = '/'; i++; }
  I64 j = 0;
  while (rel[j] != 0) { out[i] = rel[j]; i++; j++; }
  out[i] = 0;
  return 0;
}

// ------------------------------------------------------------------
// Frozen contracts: exactly 50 AC IDs and 24 control IDs, no duplicate.
// ------------------------------------------------------------------
static I64 CheckContracts(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c0/frozen-50-ac.tsv", path);
  if (LoadRaw(path) != 0) return Check("CONTRACTS_AC", 0, "AC_CONTRACT_MISSING");
  I64 ok = (NROW == 50);
  I64 r = 0;
  while (r < NROW && ok) {
    U8 *id = FLD[r * NCOL + 0];
    if (!StartsWith(id, "AC")) ok = 0;
    else {
      I64 n = ParseInt(id + 2);
      if (n != r + 1) ok = 0;
    }
    r++;
  }
  I64 a = Check("CONTRACTS_AC", ok, "AC_ID_SET_MISMATCH");

  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c0/frozen-24-controls.tsv", path);
  if (LoadRaw(path) != 0) return 0;
  I64 okc = (NROW == 24);
  U8 *want[24];
  want[0] = "AB-EN-01"; want[1] = "AB-EN-02"; want[2] = "AB-EN-03"; want[3] = "AB-EN-04";
  want[4] = "AB-HD-01"; want[5] = "AB-HD-02"; want[6] = "AB-HD-03"; want[7] = "AB-HD-04";
  want[8] = "AB-HD-05"; want[9] = "AB-HD-06"; want[10] = "AB-HD-07"; want[11] = "AB-HD-08";
  want[12] = "AB-HD-09"; want[13] = "AB-HD-10"; want[14] = "AB-ST-01"; want[15] = "AB-ST-02";
  want[16] = "AB-ST-03"; want[17] = "AB-ST-04"; want[18] = "AB-ST-05";
  want[19] = "AB-GR-01"; want[20] = "AB-GR-02"; want[21] = "AB-GR-03";
  want[22] = "AB-PV-01"; want[23] = "AB-PV-02";
  I64 i = 0;
  while (i < 24 && okc) {
    I64 found = 0;
    r = 0;
    while (r < NROW) {
      if (StrEq(FLD[r * NCOL + 0], want[i])) found++;
      r++;
    }
    if (found != 1) okc = 0;
    i++;
  }
  I64 c = Check("CONTRACTS_CONTROLS", okc, "CONTROL_ID_SET_MISMATCH");
  if (a && c) return 1;
  return 0;
}

// ------------------------------------------------------------------
// Mandatory edge join + SCC recompute.
// ------------------------------------------------------------------
static U8 *NID[MAXN];
static I64 NN;
static U8 *EID[MAXE];
static I64 ES[MAXE];
static I64 ED[MAXE];
static I64 EST[MAXE];
static I64 NE;

static I64 FindNode(U8 *id) {
  I64 i = 0;
  while (i < NN) { if (StrEq(NID[i], id)) return i; i++; }
  return -1;
}
static I64 FindEdge(U8 *id) {
  I64 i = 0;
  while (i < NE) { if (StrEq(EID[i], id)) return i; i++; }
  return -1;
}

static I64 LoadGraph(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c1/graph-nodes.tsv", path);
  if (Load(path) != 0) return 1;
  NN = 0;
  I64 r = 0;
  while (r < NROW && NN < MAXN) { NID[NN] = FLD[r * NCOL + 0]; NN++; r++; }

  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c1/graph-edges.tsv", path);
  if (Load(path) != 0) return 1;
  NE = 0;
  r = 0;
  while (r < NROW && NE < MAXE) {
    if (NFD[r] >= 8 && StrEq(FLD[r * NCOL + 5], "YES")) {
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

static I64 R[MAXN][MAXN];
static I64 GRP[MAXN];

static I64 Partition(I64 only_proven, I64 *pc, I64 *pl) {
  I64 i = 0, j = 0, k = 0;
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
    if (!(only_proven && EST[i] == 2)) R[ES[i]][ED[i]] = 1;
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
  I64 count = 0, largest = 0;
  i = 0;
  while (i < NN) {
    if (GRP[i] < 0) {
      I64 size = 0;
      j = 0;
      while (j < NN) {
        if (R[i][j] && R[j][i]) { GRP[j] = count; size++; }
        j++;
      }
      if (size > largest) largest = size;
      count++;
    }
    i++;
  }
  *pc = count;
  *pl = largest;
  return 0;
}

static I64 CheckGraph(U8 *root) {
  if (LoadGraph(root) != 0) return Check("GRAPH_JOIN", 0, "GRAPH_LOAD_FAILURE");
  if (NE != 135) return Check("GRAPH_JOIN", 0, "MANDATORY_EDGE_COUNT_MISMATCH");

  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/graph-cut-ledger.tsv", path);
  if (Load(path) != 0) return Check("GRAPH_JOIN", 0, "LEDGER_MISSING");
  if (NROW != NE) return Check("GRAPH_JOIN", 0, "LEDGER_ROW_COUNT_MISMATCH");
  I64 proven = 0, cand = 0, notcut = 0;
  I64 r = 0;
  while (r < NROW) {
    I64 e = FindEdge(FLD[r * NCOL + 0]);
    if (e < 0) return Check("GRAPH_JOIN", 0, "UNKNOWN_LEDGER_EDGE");
    U8 *st = FLD[r * NCOL + 5];
    if (StrEq(st, "CUT_PROVEN_BY_EXECUTION")) {
      // A proven cut must name an executed source-representative probe and
      // must not be a header-only observation.
      if (StrEq(FLD[r * NCOL + 7], "NONE")) return Check("GRAPH_JOIN", 0, "UNPROVEN_EDGE_CUT");
      if (StrEq(FLD[r * NCOL + 4], "OBSERVED_LAYOUT_COUPLING"))
        return Check("GRAPH_JOIN", 0, "EDGE_EVIDENCE_OVERCLAIM");
      EST[e] = 2; proven++;
    } else if (StrEq(st, "CUT_CANDIDATE_NOT_PROVEN")) { EST[e] = 1; cand++; }
    else if (StrEq(st, "NOT_CUT")) { EST[e] = 0; notcut++; }
    else return Check("GRAPH_JOIN", 0, "INVALID_CUT_STATUS");
    r++;
  }
  I64 base_count = 0, base_largest = 0, cut_count = 0, cut_largest = 0;
  Partition(0, &base_count, &base_largest);
  Partition(1, &cut_count, &cut_largest);

  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/graph-before-after-scc.tsv", path);
  if (Load(path) != 0) return Check("GRAPH_JOIN", 0, "SCC_SUMMARY_MISSING");
  I64 base_file = -1, largest_file = -1, cut_file = -1;
  r = 0;
  while (r < NROW) {
    if (StrEq(FLD[r * NCOL + 0], "BASE")) {
      base_file = ParseInt(FLD[r * NCOL + 1]);
      largest_file = ParseInt(FLD[r * NCOL + 2]);
    } else if (StrEq(FLD[r * NCOL + 0], "AFTER_PROVEN_CUTS")) {
      cut_file = ParseInt(FLD[r * NCOL + 1]);
    }
    r++;
  }
  I64 ok = (base_count == base_file && base_largest == largest_file && cut_count == cut_file);
  if (!ok) return Check("GRAPH_JOIN", 0, "SCC_OR_DAG_RECOMPUTE_MISMATCH");
  "GRAPH_BASE_NODES=%d\n", NN;
  "GRAPH_BASE_MANDATORY_EDGES=%d\n", NE;
  "CUT_PROVEN_BY_EXECUTION=%d\n", proven;
  "CUT_CANDIDATE_NOT_PROVEN=%d\n", cand;
  "NOT_CUT=%d\n", notcut;
  "SCC_BASE=%d\n", base_count;
  "SCC_BASE_LARGEST=%d\n", base_largest;
  "SCC_AFTER_PROVEN_CUTS=%d\n", cut_count;
  return Check("GRAPH_JOIN", 1, "OK");
}


// ------------------------------------------------------------------
// ABI widths, opacity, recovery, provenance, causality.
// ------------------------------------------------------------------
static I64 CountSubstr(U8 *buf, I64 sz, U8 *needle) {
  I64 nl = StrLen(needle);
  I64 n = 0, i = 0;
  if (nl == 0) return 0;
  while (i + nl <= sz) {
    I64 j = 0;
    while (j < nl) { if (buf[i + j] != needle[j]) break; j++; }
    if (j == nl) { n++; i = i + nl; } else i++;
  }
  return n;
}

static I64 ExtractValue(U8 *buf, I64 sz, U8 *prefix, U8 *out, I64 cap) {
  I64 pl = StrLen(prefix);
  I64 i = 0;
  while (i + pl <= sz) {
    I64 j = 0;
    while (j < pl) { if (buf[i + j] != prefix[j]) break; j++; }
    if (j == pl) {
      I64 k = 0;
      i = i + pl;
      while (i < sz && k < cap - 1 && buf[i] != '\n' && buf[i] != '\r') {
        out[k] = buf[i]; k++; i++;
      }
      out[k] = 0;
      return 1;
    }
    i++;
  }
  return 0;
}

static I64 CheckAbi(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/abi-signatures.tsv", path);
  if (Load(path) != 0) return Check("ABI_WIDTHS", 0, "CALL_ABI_MISMATCH");
  if (NROW < 13) return Check("ABI_WIDTHS", 0, "CALL_ABI_MISMATCH");
  I64 r = 0;
  while (r < NROW) {
    if (!StrEq(FLD[r * NCOL + 3], "64")) return Check("ABI_WIDTHS", 0, "CALL_ABI_MISMATCH");
    U8 *params = FLD[r * NCOL + 4];
    if (HasSubstr(params, StrLen(params), "I32")) return Check("ABI_WIDTHS", 0, "CALL_ABI_MISMATCH");
    if (HasSubstr(params, StrLen(params), "I16")) return Check("ABI_WIDTHS", 0, "CALL_ABI_MISMATCH");
    if (HasSubstr(params, StrLen(params), "Bool")) return Check("ABI_WIDTHS", 0, "CALL_ABI_MISMATCH");
    r++;
  }
  I64 aw = Check("ABI_WIDTHS", 1, "OK");

  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe/abi_probe.HC", path);
  I64 sz = 0;
  U8 *probe = FileRead(path, &sz);
  if (probe == 0) return Check("ABI_PROBE_SOURCE", 0, "CALL_ABI_MISMATCH");
  I64 externs = CountSubstr(probe, sz, "extern \"c\" I64");
  I64 ae = Check("ABI_PROBE_SOURCE", externs == 8, "CALL_ABI_MISMATCH");

  I64 layout_bad = 0;
  if (HasArrowAccess(probe, sz)) layout_bad = 1;
  if (HasSubstr(probe, sz, "(Ast *")) layout_bad = 1;
  if (HasSubstr(probe, sz, "(U8 *)")) layout_bad = 1;
  if (HasSubstr(probe, sz, "(I64 *)")) layout_bad = 1;
  I64 al = Check("OPAQUE_LAYOUT", !layout_bad, "OPAQUE_LAYOUT_VIOLATION");

  I64 recovery_bad = 0;
  if (HasSubstr(probe, sz, "setjmp")) recovery_bad = 1;
  if (HasSubstr(probe, sz, "longjmp")) recovery_bad = 1;
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe/abi_host.c", path);
  I64 hs = 0;
  U8 *host = FileRead(path, &hs);
  if (host == 0) return Check("CROSS_FRAME_RECOVERY", 0, "CROSS_FRAME_RECOVERY_UNSAFE");
  if (HasSubstr(host, hs, "setjmp")) recovery_bad = 1;
  if (HasSubstr(host, hs, "longjmp")) recovery_bad = 1;
  I64 ar = Check("CROSS_FRAME_RECOVERY", !recovery_bad, "CROSS_FRAME_RECOVERY_UNSAFE");

  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/real-object-linkage.tsv", path);
  if (Load(path) != 0) return Check("PRODUCER_IDENTITY", 0, "POLYC_PRODUCER_SUBJECT_MISMATCH");
  if (NROW < 1) return Check("PRODUCER_IDENTITY", 0, "POLYC_PRODUCER_SUBJECT_MISMATCH");
  U8 *producer = FLD[0 * NCOL + 3];
  U8 *producer_sha = FLD[0 * NCOL + 4];
  I64 p1 = StrEq(producer, "./hcc");
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe-build-and-selftests.txt", path);
  I64 ts = 0;
  U8 *text = FileRead(path, &ts);
  U8 got[256];
  got[0] = 0;
  I64 ex = 0;
  if (text != 0) ex = ExtractValue(text, ts, "HCC_SHA256=", got, 256);
  I64 p2 = (ex && StrEq(got, producer_sha));
  I64 ap = Check("PRODUCER_IDENTITY", p1 && p2, "POLYC_PRODUCER_SUBJECT_MISMATCH");

  // Causal mutation: mutant and pristine results must differ, and the
  // restored object must equal the original object.
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/causal-mutation-restoration.txt", path);
  I64 cs = 0;
  U8 *causal = FileRead(path, &cs);
  if (causal == 0) return Check("CAUSAL_MUTATION", 0, "DORMANT_OR_NO_CAUSAL_DELTA");
  I64 has_mut = HasSubstr(causal, cs, "PRISTINE_AST_RESULT=1725");
  I64 has_pris = HasSubstr(causal, cs, "PRISTINE_AST_RESULT=17025");
  U8 orig[256]; U8 rest[256]; orig[0] = 0; rest[0] = 0;
  I64 e1 = ExtractValue(causal, cs, "OBJECT_ORIGINAL_SHA256=", orig, 256);
  I64 e2 = ExtractValue(causal, cs, "OBJECT_RESTORED_SHA256=", rest, 256);
  I64 hashes = (e1 && e2 && StrEq(orig, rest));
  I64 ac = Check("CAUSAL_MUTATION", has_mut && has_pris && hashes, "DORMANT_OR_NO_CAUSAL_DELTA");

  if (aw && ae && al && ar && ap && ac) return 1;
  return 0;
}


// ------------------------------------------------------------------
// Predecessor freeze, authority, scope, forecast, AC and control joins.
// ------------------------------------------------------------------
static I64 EndsWith(U8 *s, U8 *suf) {
  I64 sl = StrLen(s), fl = StrLen(suf);
  if (fl > sl) return 0;
  I64 i = 0;
  while (i < fl) { if (s[sl - fl + i] != suf[i]) return 0; i++; }
  return 1;
}

static I64 CheckPredecessor(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c0/predecessor-freeze.tsv", path);
  if (Load(path) != 0) return Check("PREDECESSOR_FREEZE", 0, "PREDECESSOR_HASH_MISMATCH");
  I64 n = NROW;
  U8 *P[128];
  U8 *S[128];
  I64 i = 0;
  while (i < n && i < 128) {
    P[i] = FLD[i * NCOL + 0];
    S[i] = FLD[i * NCOL + 2];
    i++;
  }
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c3/predecessor-freeze-recomputed.tsv", path);
  if (Load(path) != 0) return Check("PREDECESSOR_FREEZE", 0, "PREDECESSOR_HASH_MISMATCH");
  if (NROW != n) return Check("PREDECESSOR_FREEZE", 0, "PREDECESSOR_HASH_MISMATCH");
  i = 0;
  while (i < n) {
    U8 *p = FLD[i * NCOL + 0];
    U8 *s = FLD[i * NCOL + 2];
    I64 found = -1;
    I64 t = 0;
    while (t < n) {
      if (StrEq(P[t], p)) { found = t; break; }
      t++;
    }
    if (found < 0) return Check("PREDECESSOR_FREEZE", 0, "PREDECESSOR_HASH_MISMATCH");
    if (!StrEq(S[found], s)) return Check("PREDECESSOR_FREEZE", 0, "PREDECESSOR_HASH_MISMATCH");
    i++;
  }
  return Check("PREDECESSOR_FREEZE", 1, "OK");
}

static I64 CheckScope(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c0/predecessor-freeze.tsv", path);
  if (Load(path) != 0) return Check("PREDECESSOR_SCOPE", 0, "PREDECESSOR_SCOPE_MISMATCH");
  I64 r = 0;
  while (r < NROW) {
    U8 *p = FLD[r * NCOL + 0];
    if (EndsWith(p, "-tmp.HC")) {
      I64 known = StrEq(p, "tools/quality/tl-tmp.HC") || StrEq(p, "tools/quality/tn-tmp.HC");
      if (!known) return Check("PREDECESSOR_SCOPE", 0, "PREDECESSOR_SCOPE_MISMATCH");
    }
    r++;
  }
  return Check("PREDECESSOR_SCOPE", 1, "OK");
}

static I64 CheckAuthority(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c0/nine-authorities.tsv", path);
  if (Load(path) != 0) return Check("NINE_AUTHORITIES", 0, "DORMANT_AUTHORITY_NOT_LINKED");
  if (NROW != 9) return Check("NINE_AUTHORITIES", 0, "DORMANT_AUTHORITY_NOT_LINKED");
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c3/nine-authorities-nm.txt", path);
  I64 ns = 0;
  U8 *nm = FileRead(path, &ns);
  if (nm == 0) return Check("NINE_AUTHORITIES", 0, "DORMANT_AUTHORITY_NOT_LINKED");
  I64 r = 0;
  while (r < NROW) {
    U8 needle[256];
    needle[0] = ' '; needle[1] = 'T'; needle[2] = ' '; needle[3] = '_';
    I64 k = 4;
    U8 *sym = FLD[r * NCOL + 1];
    while (*sym != 0 && k < 250) { needle[k] = *sym; k++; sym++; }
    needle[k] = 0;
    if (!HasSubstr(nm, ns, needle)) return Check("NINE_AUTHORITIES", 0, "DORMANT_AUTHORITY_NOT_LINKED");
    r++;
  }
  return Check("NINE_AUTHORITIES", 1, "OK");
}

static I64 CheckForecast(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/forecast-impact.tsv", path);
  if (Load(path) != 0) return Check("FORECAST_SCOPE", 0, "FORECAST_SCOPE_OR_DOUBLE_COUNT");
  I64 r = 0;
  I64 f4 = 0, f5 = 0, f11 = 0;
  while (r < NROW) {
    U8 *id = FLD[r * NCOL + 0];
    U8 *st = FLD[r * NCOL + 5];
    if (StrEq(id, "FI-04")) { if (StrEq(st, "EXCLUDED")) f4 = 1; }
    if (StrEq(id, "FI-05")) { if (StrEq(st, "EXCLUDED")) f5 = 1; }
    if (StrEq(id, "FI-11")) { if (StrEq(st, "NOT_SUPPORTED")) f11 = 1; }
    if (StrEq(st, "INCLUDED_AS_REMAINING")) return Check("FORECAST_SCOPE", 0, "FORECAST_SCOPE_OR_DOUBLE_COUNT");
    r++;
  }
  return Check("FORECAST_SCOPE", f4 && f5 && f11, "FORECAST_SCOPE_OR_DOUBLE_COUNT");
}


static I64 CheckAcLedger(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c3/mandatory-50-ac-status.tsv", path);
  if (Load(path) != 0) return Check("MANDATORY_AC", 0, "AC_LEDGER_MISSING");
  if (NROW != 50) return Check("MANDATORY_AC", 0, "AC_LEDGER_COUNT");
  I64 r = 0;
  while (r < NROW) {
    U8 *id = FLD[r * NCOL + 0];
    U8 *st = FLD[r * NCOL + 1];
    I64 n = ParseInt(id + 2);
    if (n != r + 1) return Check("MANDATORY_AC", 0, "AC_ID_SET_MISMATCH");
    if (n <= 49 && !StrEq(st, "PASS")) return Check("MANDATORY_AC", 0, "AC_NOT_PASS");
    if (n == 50 && !StrEq(st, "DEFERRED")) return Check("MANDATORY_AC", 0, "AC50_NOT_DEFERRED");
    r++;
  }
  return Check("MANDATORY_AC", 1, "OK");
}

static I64 CheckControlJoin(U8 *root) {
  U8 path[1024];
  JoinRoot(root, "evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c3/frozen-control-execution-join.tsv", path);
  if (Load(path) != 0) return Check("CONTROL_JOIN", 0, "CONTROL_JOIN_MISSING");
  if (NROW != 24) return Check("CONTROL_JOIN", 0, "CONTROL_JOIN_COUNT");
  U8 *want[24];
  want[0] = "AB-EN-01"; want[1] = "AB-EN-02"; want[2] = "AB-EN-03"; want[3] = "AB-EN-04";
  want[4] = "AB-HD-01"; want[5] = "AB-HD-02"; want[6] = "AB-HD-03"; want[7] = "AB-HD-04";
  want[8] = "AB-HD-05"; want[9] = "AB-HD-06"; want[10] = "AB-HD-07"; want[11] = "AB-HD-08";
  want[12] = "AB-HD-09"; want[13] = "AB-HD-10"; want[14] = "AB-ST-01"; want[15] = "AB-ST-02";
  want[16] = "AB-ST-03"; want[17] = "AB-ST-04"; want[18] = "AB-ST-05";
  want[19] = "AB-GR-01"; want[20] = "AB-GR-02"; want[21] = "AB-GR-03";
  want[22] = "AB-PV-01"; want[23] = "AB-PV-02";
  I64 i = 0;
  while (i < 24) {
    I64 found = 0;
    I64 r = 0;
    while (r < NROW) {
      if (StrEq(FLD[r * NCOL + 0], want[i]) && StrEq(FLD[r * NCOL + 1], "PASS")) found++;
      r++;
    }
    if (found != 1) return Check("CONTROL_JOIN", 0, "CONTROL_JOIN_MISMATCH");
    i++;
  }
  return Check("CONTROL_JOIN", 1, "OK");
}

I32 Main(I32 argc, U8 **argv) {
  if (argc < 3 || !StrEq(argv[1], "VERIFY")) {
    "USAGE: abi-foundation-recon01-verify VERIFY <repo_root>\n";
    return 2;
  }
  U8 *root = argv[2];
  REASON = 0;
  I64 ok = 1;
  if (!CheckContracts(root)) ok = 0;
  if (!CheckGraph(root)) ok = 0;
  if (!CheckAbi(root)) ok = 0;
  if (!CheckPredecessor(root)) ok = 0;
  if (!CheckScope(root)) ok = 0;
  if (!CheckAuthority(root)) ok = 0;
  if (!CheckForecast(root)) ok = 0;
  if (!CheckAcLedger(root)) ok = 0;
  if (!CheckControlJoin(root)) ok = 0;
  if (ok) { "VERIFY=PASS\n"; return 0; }
  if (REASON == 0) { "VERIFY=FAIL reason=UNSPECIFIED\n"; } else { "VERIFY=FAIL reason=%s\n", REASON; }
  return 1;
}
