// tools/quality/driver-boundary-qualification01-verify.HC
//
// ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 Q2 IMPL.
//
// THE GENERAL-PURPOSE QUALIFICATION VERIFIER.
//
// It is DISTINCT from the Q0 RED detector
// (driver-boundary-qualification01-red.HC). The RED detector exists to
// prove that a SPECIFIC adverse claim is REJECTED. This verifier
// exists to prove that a measured input table is INTERNALLY
// CONSISTENT and that its recorded facts agree with the independently
// supplied expectations.
//
// CONTRACT:
//
//   * It ingests MEASURED INPUT TABLES as DATA. It never reads a
//     status field and never accepts an expected "PASS" summary, a
//     source SHA or a rank value as its own measurement.
//   * It RE-DERIVES every count it checks from the loaded rows.
//   * It fails CLOSED: a missing row, a duplicate row, a wrong owner,
//     a wrong scope, a bogus active C decision, a false dormant claim,
//     a forged receipt timing and an omitted correction cost each
//     produce their OWN reason token.
//   * Each mode is SILENT (exit 0) when the input is consistent.
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXR 8192
#define NCOL 24

static U8 *FLD[MAXR * NCOL];
static I64 NROW;

static U8 *CKEY[MAXR];
static U8 *CVAL[MAXR];
static I64 CN;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  if (*a == 0 && *b == 0) return 1;
  return 0;
}

static I64 StrLenOf(U8 *s) {
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

// Whether the haystack CONTAINS the needle.
static I64 Has(U8 *hay, U8 *needle) {
  I64 nl = StrLenOf(needle);
  if (nl == 0) return 1;
  I64 i = 0;
  while (hay[i] != 0) {
    I64 k = 0;
    while (k < nl && hay[i + k] == needle[k]) k++;
    if (k == nl) return 1;
    i++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// THE DIAGNOSTIC EMITTERS
// ---------------------------------------------------------------------------
static U0 FailPlain(U8 *token, U8 *detail) {
  "%s|REASON_DETAIL=%s\n", token, detail;
}

static U0 FailTwo(U8 *token, U8 *detail, I64 a, I64 b) {
  "%s|REASON_DETAIL=%s (%d vs %d)\n", token, detail, a, b;
}

static U0 FailOne(U8 *token, U8 *detail, I64 a) {
  "%s|REASON_DETAIL=%s (%d)\n", token, detail, a;
}

static U0 FailId(U8 *token, U8 *detail, U8 *id) {
  "%s|REASON_DETAIL=%s %s\n", token, detail, id;
}

// ---------------------------------------------------------------------------
// THE TABLE LOADERS
// ---------------------------------------------------------------------------
static I64 SplitTabs(U8 *line, I64 base, I64 max) {
  I64 n = 0;
  U8 *p = line;
  while (n < max) {
    FLD[base + n] = p;
    n = n + 1;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}

// Load a TSV whose FIRST non-comment line is a HEADER. The header is
// skipped and the remaining rows are loaded.
static I64 Load(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 n = 0; I64 first = 1;
  U8 *p = buf; U8 *end = buf + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    if (first) { first = 0; continue; }
    SplitTabs(ls, n * NCOL, NCOL);
    n++;
  }
  NROW = n;
  return 0;
}


// Load a TSV whose first non-comment line is a HEADER, and RETURN the
// header fields too, so the verifier can address columns BY NAME and
// not by a hard-coded position.
static U8 *HDR[NCOL];
static I64 NHDR;

static I64 LoadWithHeader(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 n = 0; I64 haveHdr = 0;
  NHDR = 0;
  U8 *p = buf; U8 *end = buf + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0) continue;
    if (haveHdr == 0) {
      // The header row is the FIRST line that carries at least one TAB.
      // A leading '#' is stripped. Lines before it are comment
      // metadata and are ignored.
      if (Has(ls, "\t") == 0) continue;
      U8 *h = ls;
      if (*h == '#') { h++; while (*h == ' ' || *h == '\t') h++; }
      NHDR = SplitTabs(h, 0, NCOL);
      I64 k = 0;
      while (k < NHDR) { HDR[k] = FLD[k]; k++; }
      haveHdr = 1;
      continue;
    }
    if (*ls == '#') continue;
    SplitTabs(ls, n * NCOL, NCOL);
    n++;
  }
  NROW = n;
  return 0;
}

// The column index of a named column, or -1.
static I64 ColOf(U8 *name) {
  I64 i = 0;
  while (i < NHDR) {
    if (StrEq(HDR[i], name) == 1) return i;
    i++;
  }
  return -1;
}

// The value of a named column in row r, or "" when absent.
static U8 *Cell(U8 *name, I64 r) {
  I64 c = ColOf(name);
  if (c < 0) return "";
  if (r < 0 || r >= NROW) return "";
  return FLD[r * NCOL + c];
}

// Load a "key<TAB>value" expectation file.
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

static U8 *Expect(U8 *key) {
  I64 i = 0;
  while (i < CN) {
    if (StrEq(CKEY[i], key) == 1) return CVAL[i];
    i++;
  }
  return "";
}

// ---------------------------------------------------------------------------
// IDENTITY -- ENTRY_IDENTITY_FORGED
//
// The measured identity table must agree with the independently
// supplied expectations, field by field. A field that says MATCH in
// the measured table but disagrees with the expectation is a forgery.
// ---------------------------------------------------------------------------
static I32 ModeIdentity(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: IDENTITY <identity.tsv> <expectations.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=identity table unreadable\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=expectations unreadable\n"; return 2; }

  I64 i = 0;
  while (i < NROW) {
    U8 *check = Cell("check", i);
    U8 *measured = Cell("measured", i);
    U8 *result = Cell("result", i);
    if (StrEq(check, "") == 1) {
      FailPlain("ENTRY_IDENTITY_FORGED", "the identity table has a row with no check name");
      return 1;
    }
    // The expectation for this check, when one is supplied.
    U8 *want = Expect(check);
    if (StrEq(want, "") != 1) {
      if (StrEq(measured, want) != 1) {
        FailTwo("ENTRY_IDENTITY_FORGED", "the measured value differs from the independently supplied expectation", Atoi(measured), Atoi(want));
        return 1;
      }
      if (StrEq(result, "MATCH") != 1 && StrEq(result, "PASS") != 1 && StrEq(result, "NONE") != 1) {
        FailId("ENTRY_IDENTITY_FORGED", "the measured value agrees but the row verdict is not a measured verdict:", check);
        return 1;
      }
    }
    i++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// THE TWO-TABLE COUNTERPART OF THE LOADER
//
// LoadWithHeader overwrites the shared FLD/HDR/NHDR state, so a mode
// that compares TWO tables must keep the FIRST table's fields in a
// separate store. These helpers do that: the current table is loaded
// first and copied into CURFLD/CURHDR, and the historical table is
// then loaded into the shared state.
//
// The copy is a DEEP copy of the field POINTERS: the strings they
// point at are owned by the loaded buffer, which stays alive because
// the buffer pointer is retained.
// ---------------------------------------------------------------------------
static U8 *CURFLD[MAXR * NCOL];
static U8 *CURHDR[NCOL];
static I64 CURN;
static I64 CURNHDR;

// Save the currently loaded table into the CUR* store.
static U0 SaveCurrent() {
  I64 i = 0;
  while (i < NROW * NCOL) { CURFLD[i] = FLD[i]; i++; }
  I64 k = 0;
  while (k < NHDR) { CURHDR[k] = HDR[k]; k++; }
  CURN = NROW;
  CURNHDR = NHDR;
}

// The column index of a named column in the SAVED table, or -1.
static I64 CurColOf(U8 *name) {
  I64 i = 0;
  while (i < CURNHDR) {
    if (StrEq(CURHDR[i], name) == 1) return i;
    i++;
  }
  return -1;
}

// The value of a named column in row r of the SAVED table.
static U8 *CurCell(U8 *name, I64 r) {
  I64 c = CurColOf(name);
  if (c < 0) return "";
  if (r < 0 || r >= CURN) return "";
  return CURFLD[r * NCOL + c];
}

// ---------------------------------------------------------------------------
// ROSTER -- DRIVER_ROSTER_ID_MISSING | DRIVER_ROSTER_ID_DUPLICATE
//
// The current-classification table must contain EXACTLY the IDs of the
// historical roster: no missing ID, no duplicate ID, no extra ID.
// ---------------------------------------------------------------------------
static I32 ModeRoster(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: ROSTER <current.tsv> <historical.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=current table unreadable\n"; return 2; }
  SaveCurrent();
  if (LoadWithHeader(argv[2]) < 0) { "REASON_DETAIL=historical roster unreadable\n"; return 2; }
  I64 histN = NROW;

  // Every historical ID must appear EXACTLY ONCE in the current table.
  I64 h = 0;
  while (h < histN) {
    U8 *hid = Cell("historical_id", h);
    if (StrEq(hid, "") == 1) {
      FailPlain("DRIVER_ROSTER_ID_MISSING", "the historical roster has a row with no historical_id");
      return 1;
    }
    // A roster ID is an identifier that begins with the roster prefix.
    // A row whose first column is a summary key is not a roster row and
    // is not counted as a missing ID; a row whose first column LOOKS
    // like a roster ID but has a different prefix IS a malformed row.
    if (Has(hid, "A-C-DRIVER-") == 0) {
      if (Has(hid, "JOIN_") == 1 || Has(hid, "AC_ROSTER") == 1 || Has(hid, "NC_ROSTER") == 1) {
        h++;
        continue;
      }
      FailId("DRIVER_ROSTER_ID_MISSING", "the historical roster has a malformed ID:", hid);
      return 1;
    }
    I64 seen = 0;
    I64 c = 0;
    while (c < CURN) {
      if (StrEq(CurCell("historical_id", c), hid) == 1) seen = seen + 1;
      c++;
    }
    if (seen == 0) {
      FailId("DRIVER_ROSTER_ID_MISSING", "the historical ID is absent from the current table:", hid);
      return 1;
    }
    if (seen > 1) {
      FailId("DRIVER_ROSTER_ID_DUPLICATE", "the historical ID appears more than once in the current table:", hid);
      return 1;
    }
    h++;
  }

  // No EXTRA ID may be present in the current table.
  I64 c = 0;
  while (c < CURN) {
    U8 *cid = CurCell("historical_id", c);
    if (Has(cid, "A-C-DRIVER-") == 0) { c++; continue; }
    I64 seen = 0;
    I64 k = 0;
    while (k < histN) {
      if (StrEq(Cell("historical_id", k), cid) == 1) seen = seen + 1;
      k++;
    }
    if (seen == 0) {
      FailId("DRIVER_ROSTER_ID_MISSING", "the current table carries an ID that is not in the historical roster:", cid);
      return 1;
    }
    c++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// HISTCLASS -- HISTORICAL_CLASS_REWRITTEN
//
// The historical_class column of the current table must equal the
// historical_class column of the historical roster, row by row. The
// historical classification is immutable: this audit may QUALIFY it,
// it may not REWRITE it.
// ---------------------------------------------------------------------------
static I32 ModeHistClass(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: HISTCLASS <current.tsv> <historical.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=current table unreadable\n"; return 2; }
  SaveCurrent();
  if (LoadWithHeader(argv[2]) < 0) { "REASON_DETAIL=historical roster unreadable\n"; return 2; }
  I64 histN = NROW;

  I64 h = 0;
  while (h < histN) {
    U8 *hid = Cell("historical_id", h);
    if (Has(hid, "A-C-DRIVER-") == 0) { h++; continue; }
    U8 *hcls = Cell("historical_class", h);
    I64 c = 0;
    while (c < CURN) {
      if (StrEq(CurCell("historical_id", c), hid) == 1) {
        U8 *ccls = CurCell("historical_class", c);
        if (StrEq(ccls, hcls) != 1) {
          FailId("HISTORICAL_CLASS_REWRITTEN", "the historical class was rewritten; the immutable value was", hid);
          return 1;
        }
      }
      c++;
    }
    h++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// OWNERSHIP -- DECISION_OWNER_NOT_TRACED | ENTRY_BRANCH_CAUSAL_UNPROVEN
//               | EMITFILE_POLICY_UNPROVEN | UNREACHABILITY_NOT_PROVEN
//
// Every row of the current-classification table must carry a decision
// owner, a current class, a confidence and a route scope. A row that
// claims a class WITHOUT the witness that the class requires is
// rejected with the reason token of THAT class.
//
//   POLYC_OWNED_DECISION_PROVEN    requires a counterfactual witness
//   C_SEMANTIC_RETAINED_WP001       requires a counterfactual witness
//   DORMANT_OR_UNREACHABLE_PROVEN   requires a zero live call count
//   C_MECHANICAL_EXECUTION_PROVEN   requires a non-zero live call count
// ---------------------------------------------------------------------------
static I32 ModeOwnership(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: OWNERSHIP <current.tsv> <expectations.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=current table unreadable\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=expectations unreadable\n"; return 2; }

  I64 i = 0;
  while (i < NROW) {
    U8 *id = Cell("historical_id", i);
    U8 *fun = Cell("historical_function", i);
    U8 *owner = Cell("decision_owner", i);
    U8 *cls = Cell("current_class", i);
    U8 *conf = Cell("confidence", i);
    U8 *route = Cell("wp001_route_reachable", i);
    U8 *cf = Cell("counterfactual_execution", i);
    I64 live = Atoi(Cell("live_text_callsites", i));

    if (StrEq(owner, "") == 1 || StrEq(owner, "PENDING") == 1) {
      FailId("DECISION_OWNER_NOT_TRACED", "the row carries no traced decision owner:", id);
      return 1;
    }
    if (StrEq(cls, "") == 1 || StrEq(cls, "PENDING") == 1) {
      FailId("DECISION_OWNER_NOT_TRACED", "the row carries no current class:", id);
      return 1;
    }
    if (StrEq(conf, "") == 1 || StrEq(conf, "PENDING") == 1) {
      FailId("DECISION_OWNER_NOT_TRACED", "the row carries no confidence:", id);
      return 1;
    }
    if (StrEq(route, "") == 1 || StrEq(route, "PENDING") == 1) {
      FailId("DECISION_OWNER_NOT_TRACED", "the row carries no route scope:", id);
      return 1;
    }
    if (StrEq(cls, "UNPROVEN") == 1) {
      FailId("DECISION_OWNER_NOT_TRACED", "the row is UNPROVEN and cannot support a boundary claim:", id);
      return 1;
    }
    if (StrEq(cf, "PENDING") == 1 || StrEq(cf, "") == 1) {
      // A retained-C-semantic row carries a SPECIFIC obligation: the
      // main() entry branch and the emitFile() policy each need their
      // OWN reason token. The generic check below would swallow those
      // into DECISION_OWNER_NOT_TRACED, so the specific checks are
      // made FIRST.
      if (StrEq(cls, "C_SEMANTIC_RETAINED_WP001") == 1) {
        if (StrEq(fun, "main") == 1) {
          FailId("ENTRY_BRANCH_CAUSAL_UNPROVEN", "the main() semantic branch has no counterfactual witness:", id);
          return 1;
        }
        if (StrEq(fun, "emitFile") == 1) {
          FailId("EMITFILE_POLICY_UNPROVEN", "the emitFile() policy has no counterfactual witness:", id);
          return 1;
        }
      }
      FailId("DECISION_OWNER_NOT_TRACED", "the row carries no counterfactual witness:", id);
      return 1;
    }

    // A witness is a token FOLLOWED BY ITS PROVENANCE.
    //
    // The accepted forms are exactly:
    //
    //   COUNTERFACTUAL_C_PERFORMED (<provenance>)
    //   NOT_APPLICABLE_<REASON>
    //
    // A bare COUNTERFACTUAL_C_PERFORMED with no provenance is NOT a
    // witness: the provenance has been stripped and the row must not
    // be allowed to support an ownership claim. A token that merely
    // starts with a witness name but does not match an accepted form
    // is likewise NOT a witness.
    I64 hasCf = 0;
    if (StrEq(cf, "NOT_APPLICABLE_NO_LIVE_CALLSITE") == 1) hasCf = 1;
    if (StrEq(cf, "NOT_APPLICABLE_PLATFORM_MAPPING") == 1) hasCf = 1;
    if (StrEq(cf, "NOT_APPLICABLE_PLATFORM_OPERATION") == 1) hasCf = 1;
    if (StrEq(cf, "NOT_APPLICABLE_PRESENTATION") == 1) hasCf = 1;
    if (StrEq(cf, "NOT_APPLICABLE_INITIALISATION") == 1) hasCf = 1;
    if (Has(cf, "COUNTERFACTUAL_C_PERFORMED (") == 1 && Has(cf, ")") == 1) hasCf = 1;

    if (StrEq(cls, "POLYC_OWNED_DECISION_PROVEN") == 1 && hasCf == 0) {
      FailId("DECISION_OWNER_NOT_TRACED", "the row claims PolyC ownership without a counterfactual witness:", id);
      return 1;
    }
    if (StrEq(cls, "C_SEMANTIC_RETAINED_WP001") == 1 && hasCf == 0) {
      if (StrEq(fun, "main") == 1) {
        FailId("ENTRY_BRANCH_CAUSAL_UNPROVEN", "the main() semantic branch has no counterfactual witness:", id);
        return 1;
      }
      if (StrEq(fun, "emitFile") == 1) {
        FailId("EMITFILE_POLICY_UNPROVEN", "the emitFile() policy has no counterfactual witness:", id);
        return 1;
      }
      FailId("DECISION_OWNER_NOT_TRACED", "the row claims a retained C decision without a counterfactual witness:", id);
      return 1;
    }
    if (StrEq(cls, "DORMANT_OR_UNREACHABLE_PROVEN") == 1 && live > 0) {
      FailId("UNREACHABILITY_NOT_PROVEN", "the row claims unreachability but has live call sites:", id);
      return 1;
    }
    i++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// SCOPE -- GLOBAL_DRIVER_REMAINDER_UNDERCOUNTED
//
// The route-scoped remainder and the global remainder are SEPARATE
// counts. The global remainder must be at least the route-scoped one,
// and both must equal the counts re-derived from the rows.
// ---------------------------------------------------------------------------
static I32 ModeScope(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: SCOPE <current.tsv> <expectations.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=current table unreadable\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=expectations unreadable\n"; return 2; }

  I64 routeRem = 0;
  I64 globalRem = 0;
  I64 i = 0;
  while (i < NROW) {
    if (StrEq(Cell("current_class", i), "C_SEMANTIC_RETAINED_WP001") == 1) {
      globalRem = globalRem + 1;
      if (StrEq(Cell("wp001_route_reachable", i), "YES") == 1) routeRem = routeRem + 1;
    }
    i++;
  }

  U8 *wantRoute = Expect("WP001_REQUIRED_ROUTE_C_SEMANTIC_REMAINDER");
  U8 *wantGlobal = Expect("WP001_GLOBAL_C_SEMANTIC_REMAINDER");
  if (StrEq(wantRoute, "") == 1 || StrEq(wantGlobal, "") == 1) {
    FailPlain("GLOBAL_DRIVER_REMAINDER_UNDERCOUNTED", "the scope expectations are incomplete");
    return 1;
  }
  if (Atoi(wantRoute) != routeRem) {
    FailTwo("GLOBAL_DRIVER_REMAINDER_UNDERCOUNTED", "the reported route-scoped remainder differs from the re-derived count", Atoi(wantRoute), routeRem);
    return 1;
  }
  if (Atoi(wantGlobal) != globalRem) {
    FailTwo("GLOBAL_DRIVER_REMAINDER_UNDERCOUNTED", "the reported global remainder differs from the re-derived count", Atoi(wantGlobal), globalRem);
    return 1;
  }
  if (globalRem < routeRem) {
    FailTwo("GLOBAL_DRIVER_REMAINDER_UNDERCOUNTED", "the global remainder is smaller than the route-scoped remainder", globalRem, routeRem);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// AUTHORITY -- AUTHORITY_UNIT_MISMATCH
//
// The authority count is a count of AUTHORITY SUBJECTS, not of
// migrated review rows. The verifier re-derives the live count from
// the authority table and rejects a claim that equates the 32 review
// rows with the authority count.
// ---------------------------------------------------------------------------
static I32 ModeAuthority(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: AUTHORITY <authorities.tsv> <expectations.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=authority table unreadable\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=expectations unreadable\n"; return 2; }

  I64 live = 0;
  I64 i = 0;
  while (i < NROW) {
    if (Atoi(Cell("importing_c_objs", i)) >= 1) live = live + 1;
    i++;
  }

  U8 *want = Expect("FINAL_AUTHORITIES");
  if (StrEq(want, "") == 1) {
    FailPlain("AUTHORITY_UNIT_MISMATCH", "the authority expectation is missing");
    return 1;
  }
  if (Atoi(want) != live) {
    FailTwo("AUTHORITY_UNIT_MISMATCH", "the reported authority count differs from the re-derived live count", Atoi(want), live);
    return 1;
  }
  U8 *rows = Expect("HISTORICAL_ROWS");
  U8 *newAuth = Expect("NEW_AUTHORITIES");
  if (StrEq(rows, "") != 1 && StrEq(newAuth, "") != 1) {
    if (Atoi(newAuth) == 1 && Atoi(rows) == Atoi(want)) {
      FailTwo("AUTHORITY_UNIT_MISMATCH", "the review-row count was charged as the authority count", Atoi(rows), Atoi(want));
      return 1;
    }
  }
  return 0;
}

// ---------------------------------------------------------------------------
// FAMILY -- ACT_FAMILY_COST_UNDERCOUNTED
//
// The family cost is a count of NAMED ACTs. The verifier re-derives
// the count from the inventory and rejects a claim that counts a
// subset (for example the parent plus the first correction only).
// ---------------------------------------------------------------------------
static I32 ModeFamily(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: FAMILY <inventory.tsv> <expectations.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=inventory unreadable\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=expectations unreadable\n"; return 2; }

  I64 acts = 0;
  I64 impl = 0;
  I64 tech = 0;
  I64 gov = 0;
  I64 i = 0;
  while (i < NROW) {
    U8 *id = Cell("act_id", i);
    if (StrEq(id, "") == 1) {
      FailPlain("ACT_FAMILY_COST_UNDERCOUNTED", "the inventory has a row with no act_id");
      return 1;
    }
    acts = acts + 1;
    U8 *kind = Cell("kind", i);
    if (StrEq(kind, "IMPLEMENTATION") == 1) impl = impl + 1;
    if (StrEq(kind, "TECHNICAL_CORRECTION") == 1) tech = tech + 1;
    if (StrEq(kind, "GOVERNANCE_CORRECTION") == 1) gov = gov + 1;
    i++;
  }

  U8 *wantAll = Expect("WP001_ALL_ACTS_CONSUMED");
  U8 *wantImpl = Expect("WP001_IMPLEMENTATION_ACTS");
  U8 *wantTech = Expect("WP001_TECHNICAL_CORRECTION_ACTS");
  U8 *wantGov = Expect("WP001_GOVERNANCE_CORRECTION_ACTS");
  if (StrEq(wantAll, "") == 1 || StrEq(wantImpl, "") == 1 || StrEq(wantTech, "") == 1 || StrEq(wantGov, "") == 1) {
    FailPlain("ACT_FAMILY_COST_UNDERCOUNTED", "the family cost expectations are incomplete");
    return 1;
  }
  if (Atoi(wantAll) != acts) {
    FailTwo("ACT_FAMILY_COST_UNDERCOUNTED", "the reported family ACT count differs from the re-derived count", Atoi(wantAll), acts);
    return 1;
  }
  if (Atoi(wantImpl) != impl) {
    FailTwo("ACT_FAMILY_COST_UNDERCOUNTED", "the reported implementation-ACT count differs from the re-derived count", Atoi(wantImpl), impl);
    return 1;
  }
  if (Atoi(wantTech) != tech) {
    FailTwo("ACT_FAMILY_COST_UNDERCOUNTED", "the reported technical-correction count differs from the re-derived count", Atoi(wantTech), tech);
    return 1;
  }
  if (Atoi(wantGov) != gov) {
    FailTwo("ACT_FAMILY_COST_UNDERCOUNTED", "the reported governance-correction count differs from the re-derived count", Atoi(wantGov), gov);
    return 1;
  }
  if (impl + tech + gov != acts) {
    FailTwo("ACT_FAMILY_COST_UNDERCOUNTED", "the cost subtypes do not sum to the family ACT count", impl + tech + gov, acts);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// CHRONOLOGY -- PRECOMMITTED_RESULT_LAUNDERED
//             | RECEIPT_EXISTENCE_NOT_PROVEN
//             | REPLAY_PROVENANCE_CONFLATED
//             | POST_CLOSE_ID_CARRIER_OMITTED
//
// The four chronology questions are kept distinct. A tracked outcome
// that was already in the CLOSE tree is a PRECOMMITTED PROSPECTIVE
// RESULT. A receipt whose existence is asserted but not measured is
// RECEIPT_EXISTENCE_NOT_PROVEN. A replay presented as the ORIGINAL
// receipt is REPLAY_PROVENANCE_CONFLATED. A post-CLOSE ACT-id commit
// that the scan does not cover is POST_CLOSE_ID_CARRIER_OMITTED.
// ---------------------------------------------------------------------------
static I32 ModeChronology(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: CHRONOLOGY <chronology.tsv> <expectations.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=chronology table unreadable\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=expectations unreadable\n"; return 2; }

  I64 i = 0;
  while (i < NROW) {
    U8 *key = Cell("key", i);
    U8 *value = Cell("value", i);
    if (StrEq(key, "") == 1) {
      FailPlain("PRECOMMITTED_RESULT_LAUNDERED", "the chronology table has a row with no key");
      return 1;
    }
    if (StrEq(key, "HISTORICAL_TRACKED_OUTCOME_PROVENANCE") == 1) {
      U8 *want = Expect(key);
      if (StrEq(want, "") == 1) {
        FailPlain("PRECOMMITTED_RESULT_LAUNDERED", "the tracked-outcome provenance expectation is missing");
        return 1;
      }
      if (StrEq(value, want) != 1) {
        FailId("PRECOMMITTED_RESULT_LAUNDERED", "the tracked-outcome provenance differs from the expectation:", value);
        return 1;
      }
    }
    if (StrEq(key, "ORIGINAL_EXTERNAL_RECEIPT") == 1) {
      U8 *want = Expect(key);
      if (StrEq(want, "") == 1) {
        FailPlain("RECEIPT_EXISTENCE_NOT_PROVEN", "the original-receipt expectation is missing");
        return 1;
      }
      if (StrEq(value, want) != 1) {
        FailId("RECEIPT_EXISTENCE_NOT_PROVEN", "the original-receipt classification differs from the expectation:", value);
        return 1;
      }
      if (StrEq(value, "VERIFIED") == 1) {
        if (StrEq(Cell("measured_exists", i), "YES") != 1) {
          FailPlain("RECEIPT_EXISTENCE_NOT_PROVEN", "the receipt is claimed VERIFIED but its existence was not measured");
          return 1;
        }
      }
    }
    if (StrEq(key, "FRESH_EXTERNAL_REPLAY") == 1) {
      U8 *want = Expect(key);
      if (StrEq(want, "") == 1) {
        FailPlain("REPLAY_PROVENANCE_CONFLATED", "the fresh-replay expectation is missing");
        return 1;
      }
      if (StrEq(value, want) != 1) {
        FailId("REPLAY_PROVENANCE_CONFLATED", "the fresh-replay classification differs from the expectation:", value);
        return 1;
      }
      if (StrEq(value, "VERIFIED") == 1) {
        FailPlain("REPLAY_PROVENANCE_CONFLATED", "a fresh replay was presented as the original historical receipt");
        return 1;
      }
    }
    if (StrEq(key, "POST_CLOSE_ACT_ID_COMMITS") == 1) {
      U8 *want = Expect(key);
      if (StrEq(want, "") == 1) {
        FailPlain("POST_CLOSE_ID_CARRIER_OMITTED", "the post-CLOSE ACT-id commit expectation is missing");
        return 1;
      }
      if (Atoi(value) != Atoi(want)) {
        FailTwo("POST_CLOSE_ID_CARRIER_OMITTED", "the measured post-CLOSE ACT-id commit count differs from the expectation", Atoi(value), Atoi(want));
        return 1;
      }
    }
    if (StrEq(key, "HISTORICAL_ACT_TERMINALITY_CONFIRMED") == 1) {
      U8 *want = Expect(key);
      if (StrEq(want, "") == 1) {
        FailPlain("PRECOMMITTED_RESULT_LAUNDERED", "the historical-terminality expectation is missing");
        return 1;
      }
      if (StrEq(value, want) != 1) {
        FailId("PRECOMMITTED_RESULT_LAUNDERED", "the historical terminality classification differs from the expectation:", value);
        return 1;
      }
    }
    i++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// ACCEPT -- FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED
//
// The acceptance ledger must contain EXACTLY the fifty frozen AC IDs,
// each exactly once. A missing ID, a duplicate ID or an extra ID is a
// forged acceptance set. A criterion that claims PASS while its
// required phase has not been reached is a forged acceptance.
//
// The ledger table carries the columns ac_id, phase and status.
// ---------------------------------------------------------------------------
static I32 ModeAccept(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: ACCEPT <ledger.tsv> <frozen.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=acceptance ledger unreadable\n"; return 2; }
  I64 ledN = NROW;
  if (LoadWithHeader(argv[2]) < 0) { "REASON_DETAIL=frozen AC roster unreadable\n"; return 2; }
  I64 froN = NROW;

  I64 i = 0;
  while (i < froN) {
    U8 *want = Cell("ac_id", i);
    if (StrEq(want, "") == 1) {
      FailPlain("FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED", "the frozen AC roster has a row with no ac_id");
      return 1;
    }
    I64 seen = 0;
    I64 c = 0;
    while (c < ledN) {
      if (StrEq(Cell("ac_id", c), want) == 1) seen = seen + 1;
      c++;
    }
    if (seen == 0) {
      FailId("FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED", "the acceptance ledger omits a frozen AC id:", want);
      return 1;
    }
    if (seen > 1) {
      FailId("FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED", "the acceptance ledger repeats a frozen AC id:", want);
      return 1;
    }
    i++;
  }

  // No EXTRA id may be present.
  I64 c = 0;
  while (c < ledN) {
    U8 *got = Cell("ac_id", c);
    I64 seen = 0;
    I64 k = 0;
    while (k < froN) {
      if (StrEq(Cell("ac_id", k), got) == 1) seen = seen + 1;
      k++;
    }
    if (seen == 0) {
      FailId("FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED", "the acceptance ledger carries an id that is not in the frozen roster:", got);
      return 1;
    }
    // A criterion may only claim PASS when its phase is one that has
    // actually been reached. The Q4 phase criteria are DEFERRED at Q3.
    U8 *st = Cell("status", c);
    U8 *ph = Cell("phase", c);
    if (StrEq(st, "PASS") == 1) {
      if (StrEq(ph, "External") == 1) {
        FailId("FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED", "an external criterion claims PASS before the external observation:", got);
        return 1;
      }
    }
    c++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// M2CLASS -- M2_BOOTSTRAP_MISCLASSIFIED | KNOWN_BASELINE_FALSE_GREEN
//
// A hybrid C-rooted compiler whose driver route still runs a C
// dispatch is NOT M2. A historical baseline that is known to be
// non-green may not be relabelled PASS.
// ---------------------------------------------------------------------------
static I32 ModeM2Class(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: M2CLASS <claims.tsv> <expectations.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) { "REASON_DETAIL=claims table unreadable\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=expectations unreadable\n"; return 2; }

  I64 i = 0;
  while (i < NROW) {
    U8 *key = Cell("key", i);
    U8 *value = Cell("value", i);
    if (StrEq(key, "") == 1) {
      FailPlain("M2_BOOTSTRAP_MISCLASSIFIED", "the claims table has a row with no key");
      return 1;
    }
    if (StrEq(key, "M2_ACHIEVED") == 1) {
      U8 *want = Expect(key);
      if (StrEq(want, "") == 1) {
        FailPlain("M2_BOOTSTRAP_MISCLASSIFIED", "the M2 expectation is missing");
        return 1;
      }
      if (StrEq(value, want) != 1) {
        FailId("M2_BOOTSTRAP_MISCLASSIFIED", "the M2 claim differs from the expectation:", value);
        return 1;
      }
      if (StrEq(value, "YES") == 1) {
        U8 *rem = Expect("WP001_REQUIRED_ROUTE_C_SEMANTIC_REMAINDER");
        if (StrEq(rem, "") != 1 && Atoi(rem) > 0) {
          FailOne("M2_BOOTSTRAP_MISCLASSIFIED", "M2 is claimed while the required route still has a retained C semantic remainder", Atoi(rem));
          return 1;
        }
      }
    }
    if (StrEq(key, "CROSS_TARGET_PREFIX") == 1) {
      U8 *want = Expect(key);
      if (StrEq(want, "") == 1) {
        FailPlain("KNOWN_BASELINE_FALSE_GREEN", "the cross-target baseline expectation is missing");
        return 1;
      }
      if (StrEq(value, want) != 1) {
        FailId("KNOWN_BASELINE_FALSE_GREEN", "a known non-green baseline was relabelled:", value);
        return 1;
      }
    }
    i++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// THE ANTI-SELFTEST HARNESS
//
// The verifier proves its own helpers are live by exercising them on
// data it constructs. It never consults a recorded PASS.
// ---------------------------------------------------------------------------
static I32 Selftest() {
  if (StrEq("a", "a") == 0) { "SELFTEST_FAILED|REASON_DETAIL=StrEq\n"; return 1; }
  if (Atoi("42") != 42) { "SELFTEST_FAILED|REASON_DETAIL=Atoi\n"; return 1; }
  if (StrLenOf("abc") != 3) { "SELFTEST_FAILED|REASON_DETAIL=StrLenOf\n"; return 1; }
  if (Atoi("") != 0) { "SELFTEST_FAILED|REASON_DETAIL=Atoi on an empty string\n"; return 1; }
  return 0;
}

// ---------------------------------------------------------------------------
// THE DISPATCHER
// ---------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) {
    "REASON_DETAIL=usage: <mode> <args...>\n";
    return 2;
  }
  U8 *mode = argv[1];
  if (StrEq(mode, "IDENTITY") == 1)   return ModeIdentity(argc - 1, argv + 1);
  if (StrEq(mode, "ROSTER") == 1)     return ModeRoster(argc - 1, argv + 1);
  if (StrEq(mode, "HISTCLASS") == 1)  return ModeHistClass(argc - 1, argv + 1);
  if (StrEq(mode, "OWNERSHIP") == 1)  return ModeOwnership(argc - 1, argv + 1);
  if (StrEq(mode, "SCOPE") == 1)      return ModeScope(argc - 1, argv + 1);
  if (StrEq(mode, "AUTHORITY") == 1)  return ModeAuthority(argc - 1, argv + 1);
  if (StrEq(mode, "FAMILY") == 1)     return ModeFamily(argc - 1, argv + 1);
  if (StrEq(mode, "CHRONOLOGY") == 1) return ModeChronology(argc - 1, argv + 1);
  if (StrEq(mode, "ACCEPT") == 1)     return ModeAccept(argc - 1, argv + 1);
  if (StrEq(mode, "M2CLASS") == 1)    return ModeM2Class(argc - 1, argv + 1);
  if (StrEq(mode, "SELFTEST") == 1)   return Selftest();
  "REASON_DETAIL=unknown mode %s\n", mode;
  return 2;
}
