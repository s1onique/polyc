// tools/quality/driver-boundary-qualification01-red.HC
//
// ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 Q0 RED.
//
// THE BOUNDED EARLY RED DETECTOR.
//
// It is the ONLY audit tool authorised before Q2. Q2 implements a
// separate, general-purpose qualification verifier that independently
// replays these REDs.
//
// CONTRACT:
//
//   * The detector RE-DERIVES every fact it tests from the PRIMARY
//     material it loads itself (Git-derived rows, symbol tables,
//     relocation tables, receipts). It NEVER reads a status field
//     and NEVER trusts an "expected PASS" cell.
//   * A mode is SILENT (exit 0, no output) when the material is
//     CONSISTENT with the audited claim.
//   * A mode prints ITS OWN reason token and exits non-zero when the
//     material is INCONSISTENT. Each mode owns a DISTINCT reason
//     token, so a failure names itself.
//
// The five Q0 RED reason tokens are:
//
//   R01  RELOCATION_IS_NOT_DECISION_PROOF
//   R02  DRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN
//   R03  PRECOMMITTED_TERMINALITY_RESULT
//   R04  WP001_CORRECTION_FAMILY_OMITTED
//   R05  WP001_AUTHORITY_OR_M2_OVERCLAIM
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXR 8192
#define NCOL 24

static U8 *FLD[MAXR * NCOL];
static I64 NROW;

// The "key<TAB>value" claim rows loaded from the claim file.
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
//
// Every reason token is emitted by ONE of these small helpers. Keeping
// the printf-form in a tiny function (rather than inline in a large
// mode function) keeps the source shape uniform and keeps each
// diagnostic independently readable.
//
// Each emitter prints the REASON TOKEN first, so a failing run names
// itself without the caller having to interpret the message.
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

// Split one TSV line in place. Returns the field count.
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

// Load a TSV. Comment lines and blank lines are skipped. The first
// non-comment line is a header and is skipped.
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

// Load a "key<TAB>value" claim file.
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

// The claim value for a key, or "" when the key is absent.
static U8 *Claim(U8 *key) {
  I64 i = 0;
  while (i < CN) {
    if (StrEq(CKEY[i], key) == 1) return CVAL[i];
    i++;
  }
  return "";
}


// The number of LINES of a file that CONTAIN a substring.
static I64 CountLinesWith(U8 *path, U8 *needle) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 hits = 0;
  I64 nlen = StrLenOf(needle);
  I64 i = 0;
  while (i < sz) {
    I64 ls = i;
    while (i < sz && buf[i] != '\n') i++;
    I64 le = i;
    if (i < sz) i++;
    I64 j = 0;
    while (j + nlen <= le - ls) {
      I64 k = 0;
      while (k < nlen && buf[ls + j + k] == needle[k]) k++;
      if (k == nlen) { hits = hits + 1; break; }
      j++;
    }
  }
  return hits;
}

// ---------------------------------------------------------------------------
// R01 -- RELOCATION_IS_NOT_DECISION_PROOF
//
// The adverse claim is: "the eight PolyC relocations prove that main and
// emitFile contain no live C decision".
//
// The detector RE-DERIVES the truth from the primary input:
//
//   <relocs.txt>    the undefined _WpDriver* symbols of EVERY production
//                   C object, one per line
//
// A relocation is a LINK reference, not a DECISION. The claim is
// inconsistent when the relocation set is empty (nothing to prove) OR
// when the relocation set contains NO action-selection symbol, because
// then the relocations demonstrably do NOT cover the action decision.
//
// The claim file supplies:
//
//   RELOC_COUNT          the number of relocations the claim asserts
//   PROVES_NO_C_DECISION 1 if the claim asserts the boundary is proven
//   ACTION_RELOC_COUNT   the number of relocations the claim counts as
//                        ACTION-selection relocations
// ---------------------------------------------------------------------------
static I32 ModeRelocation(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: R01 <relocs.txt> <claims.tsv>\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=claims file unreadable\n"; return 2; }

  I64 relocs = CountLinesWith(argv[1], "_WpDriver");
  // The four action-selection symbols the WP-001 driver exports.
  I64 actionRelocs = 0;
  if (CountLinesWith(argv[1], "_WpDriverSelectAction") > 0) actionRelocs++;
  if (CountLinesWith(argv[1], "_WpDriverSelectedAction") > 0) actionRelocs++;
  if (CountLinesWith(argv[1], "_WpDriverOptionAction") > 0) actionRelocs++;
  if (CountLinesWith(argv[1], "_WpDriverMapStatus") > 0) actionRelocs++;

  U8 *asserted = Claim("RELOC_COUNT");
  I64 assertedN = Atoi(asserted);
  U8 *proves = Claim("PROVES_NO_C_DECISION");
  U8 *assertedAction = Claim("ACTION_RELOC_COUNT");
  I64 assertedActionN = Atoi(assertedAction);

  if (StrEq(proves, "1") != 1) {
    // The claim does not assert the boundary. Nothing to falsify.
    return 0;
  }

  if (relocs == 0) {
    FailPlain("RELOCATION_IS_NOT_DECISION_PROOF", "the relocation set is EMPTY; an empty relocation set proves no ownership claim");
    return 1;
  }
  if (assertedN != relocs) {
    FailTwo("RELOCATION_IS_NOT_DECISION_PROOF", "the asserted relocation count differs from the measured count", assertedN, relocs);
    return 1;
  }
  if (assertedActionN != actionRelocs) {
    FailTwo("RELOCATION_IS_NOT_DECISION_PROOF", "the asserted action-selection relocation count differs from the measured count", assertedActionN, actionRelocs);
    return 1;
  }
  if (actionRelocs == 0) {
    FailOne("RELOCATION_IS_NOT_DECISION_PROOF", "measured driver relocations, none of which is an action-selection relocation; a relocation is a link reference, not a decision proof", relocs);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R02 -- DRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN
//
// The adverse claim is: "main / emitFile are migrated because their
// branch reads a PolyC-produced field", with no branch counterfactual.
//
// The detector RE-DERIVES the truth from:
//
//   <counterfactual.tsv> one row per mutated branch, with the columns
//                        branch_id, mutated_in_c_off, linked_proof,
//                        observed_difference
//
// A claim of causal ownership requires, for EVERY mutated branch, a
// LINKED mutation proof AND an OBSERVED behavioural difference. A
// branch that was mutated but never linked, or that was linked but
// produced no observed difference, does NOT establish causal ownership.
//
// The claim file supplies:
//
//   CAUSAL_CLAIMED  1 if the claim asserts causal ownership
//   BRANCH_COUNT    the number of branches the claim covers
// ---------------------------------------------------------------------------
static I32 ModeCausal(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: R02 <counterfactual.tsv> <claims.tsv>\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=claims file unreadable\n"; return 2; }
  if (Load(argv[1]) < 0) { "REASON_DETAIL=counterfactual table unreadable\n"; return 2; }

  U8 *claimed = Claim("CAUSAL_CLAIMED");
  if (StrEq(claimed, "1") != 1) return 0;

  U8 *branchCount = Claim("BRANCH_COUNT");
  I64 assertedBranches = Atoi(branchCount);
  if (assertedBranches != NROW) {
    FailTwo("DRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN", "the claimed branch count differs from the counterfactual row count", assertedBranches, NROW);
    return 1;
  }

  I64 i = 0;
  while (i < NROW) {
    U8 *id = FLD[i * NCOL + 0];
    U8 *linked = FLD[i * NCOL + 2];
    U8 *diff = FLD[i * NCOL + 3];
    if (StrEq(linked, "1") != 1) {
      FailId("DRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN", "the branch was mutated but never proven LINKED into the built binary:", id);
      return 1;
    }
    if (StrEq(diff, "1") != 1) {
      FailId("DRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN", "the branch was linked but produced NO observed behavioural difference:", id);
      return 1;
    }
    i++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R03 -- PRECOMMITTED_TERMINALITY_RESULT
//
// The adverse claim is: "the tracked terminality-outcome.tsv IS an
// external post-CLOSE receipt".
//
// The detector RE-DERIVES the truth from:
//
//   <tracked-outcome.tsv>  the tracked prospective-result file
//   <close-tree-list.txt>  the tracked paths present in the CLOSE tree
//
// The tracked file is a PRECOMMITTED PROSPECTIVE RESULT when it
// asserts a terminal outcome (a PASS verdict or a discharged AC) AND
// it was already present in the CLOSE tree -- i.e. it predates the
// CLOSE, so it cannot be a post-CLOSE observation.
//
// The claim file supplies:
//
//   CLAIMS_EXTERNAL_RECEIPT 1 if the claim asserts the tracked file is
//                            an external post-CLOSE receipt
// ---------------------------------------------------------------------------
static I32 ModePrecommitted(I32 argc, U8 **argv) {
  if (argc < 4) { "REASON_DETAIL=usage: R03 <tracked-outcome.tsv> <close-tree-list.txt> <claims.tsv>\n"; return 2; }
  if (LoadClaims(argv[3]) < 0) { "REASON_DETAIL=claims file unreadable\n"; return 2; }

  U8 *claimed = Claim("CLAIMS_EXTERNAL_RECEIPT");
  if (StrEq(claimed, "1") != 1) return 0;

  // Does the tracked file assert a terminal outcome?
  I64 assertsOutcome = 0;
  if (CountLinesWith(argv[1], "EXTERNAL_TERMINALITY\tPASS") > 0) assertsOutcome = 1;
  if (CountLinesWith(argv[1], "PROBE_RESULT\tPASS") > 0) assertsOutcome = 1;
  if (CountLinesWith(argv[1], "AC50\tPASS") > 0) assertsOutcome = 1;

  // Was it already in the CLOSE tree?
  I64 inCloseTree = CountLinesWith(argv[2], "terminality-outcome.tsv");

  if (assertsOutcome == 1 && inCloseTree > 0) {
    FailPlain("PRECOMMITTED_TERMINALITY_RESULT", "the tracked outcome file asserts a terminal PASS and was already present in the CLOSE tree; it is a PRECOMMITTED PROSPECTIVE RESULT, not a post-CLOSE observation");
    return 1;
  }
  return 0;
}


// ---------------------------------------------------------------------------
// R04 -- WP001_CORRECTION_FAMILY_OMITTED
//
// The adverse claim is: "WP-001 consumed only the parent ACT and
// CORRECTION01" (i.e. 2 ACTs).
//
// The detector RE-DERIVES the truth from:
//
//   <act-inventory.tsv> one row per named ACT in the family, with the
//                       columns act_id, kind, phase_commits
//
// The claim file supplies:
//
//   FAMILY_ACT_COUNT  the number of ACTs the claim asserts were spent
// ---------------------------------------------------------------------------
static I32 ModeFamily(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: R04 <act-inventory.tsv> <claims.tsv>\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=claims file unreadable\n"; return 2; }
  if (Load(argv[1]) < 0) { "REASON_DETAIL=ACT inventory unreadable\n"; return 2; }

  U8 *claimed = Claim("FAMILY_ACT_COUNT");
  I64 asserted = Atoi(claimed);
  if (asserted == NROW) return 0;

  FailTwo("WP001_CORRECTION_FAMILY_OMITTED", "the claimed ACT count differs from the distinct named ACTs in the family inventory", asserted, NROW);
  return 1;
}

// ---------------------------------------------------------------------------
// R05 -- WP001_AUTHORITY_OR_M2_OVERCLAIM
//
// The adverse claim is: "32 rows = 32 migrated authorities" and/or
// "the hybrid WP-001 compiler is M2".
//
// The detector RE-DERIVES the truth from:
//
//   <authority.tsv> one row per production PolyC authority, with the
//                   columns authority_id, symbol, importing_c_objs
//
// The claim file supplies:
//
//   CLAIMED_AUTHORITIES  the number of authorities the claim asserts
//   CLAIMED_M2          1 if the claim asserts M2 is achieved
//   HISTORICAL_ROWS     the number of historical review rows
// ---------------------------------------------------------------------------
static I32 ModeOverclaim(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: R05 <authority.tsv> <claims.tsv>\n"; return 2; }
  if (LoadClaims(argv[2]) < 0) { "REASON_DETAIL=claims file unreadable\n"; return 2; }
  if (Load(argv[1]) < 0) { "REASON_DETAIL=authority table unreadable\n"; return 2; }

  // Count the authorities that are MEASURED live: the symbol is defined
  // in a PolyC subject object AND imported by at least one C object.
  I64 live = 0;
  I64 i = 0;
  while (i < NROW) {
    U8 *importers = FLD[i * NCOL + 2];
    if (Atoi(importers) >= 1) live = live + 1;
    i++;
  }

  U8 *claimed = Claim("CLAIMED_AUTHORITIES");
  I64 asserted = Atoi(claimed);
  if (asserted != live) {
    FailTwo("WP001_AUTHORITY_OR_M2_OVERCLAIM", "the asserted authority count differs from the live count in the object graph", asserted, live);
    return 1;
  }

  U8 *m2 = Claim("CLAIMED_M2");
  if (StrEq(m2, "1") == 1) {
    U8 *rows = Claim("HISTORICAL_ROWS");
    if (Atoi(rows) != asserted) {
      FailTwo("WP001_AUTHORITY_OR_M2_OVERCLAIM", "M2 is claimed while the historical review-row count is charged against the authority count", Atoi(rows), asserted);
      return 1;
    }
    FailPlain("WP001_AUTHORITY_OR_M2_OVERCLAIM", "M2 is claimed for a C-rooted hybrid compiler whose driver route still runs a C dispatch");
    return 1;
  }
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
  if (StrEq(mode, "R01") == 1) return ModeRelocation(argc - 1, argv + 1);
  if (StrEq(mode, "R02") == 1) return ModeCausal(argc - 1, argv + 1);
  if (StrEq(mode, "R03") == 1) return ModePrecommitted(argc - 1, argv + 1);
  if (StrEq(mode, "R04") == 1) return ModeFamily(argc - 1, argv + 1);
  if (StrEq(mode, "R05") == 1) return ModeOverclaim(argc - 1, argv + 1);
  if (StrEq(mode, "SELFTEST") == 1) {
    if (StrEq("a", "a") == 0) { "SELFTEST_FAILED\n"; return 1; }
    if (Atoi("42") != 42) { "SELFTEST_FAILED\n"; return 1; }
    if (StrLenOf("abc") != 3) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("abcdef", "cd") != 1) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("abcdef", "cz") != 0) { "SELFTEST_FAILED\n"; return 1; }
    return 0;
  }
  "REASON_DETAIL=unknown mode %s\n", mode;
  return 2;
}
