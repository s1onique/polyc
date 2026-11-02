// tools/quality/driver-migration01-red.HC
//
// ACT-POLYC-SELFHOST-DRIVER-MIGRATION01 C0 RED.
//
// THE FIVE ADVERSE-PROBE DETECTOR FOR THE WP-001 DRIVER MIGRATION.
//
// It is a REAL detector, not a label reader. Each mode RE-DERIVES the
// fact it tests from the primary files it loads itself, and then
// applies a rule that a wrong claim would violate. A mode is SILENT
// (exit 0, no output) when the claim under test is CONSISTENT with
// the primary material, and it prints its OWN reason token and exits
// non-zero when the claim is INCONSISTENT.
//
// THE FIVE C0 REDs, each with its own reason token:
//
//   R01_FAKE_DRIVER     POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY
//   R02_ORACLE_LEAK    C_ORACLE_CONTAMINATED
//   R03_DORMANT_C      LEGACY_C_DRIVER_DECISION_ACTIVE
//   R04_ARGUMENT_LIFETIME DRIVER_ABI_LIFETIME_OR_DOMAIN
//   R05_FALSE_P0       BOOTSTRAP_SOURCE_CLOSURE_FALSE
//
// MODES (each mode's inputs are named in the usage line):
//
//   FAKE      <driver_symbols_tsv> <claim.tsv>
//   ORACLE    <hcc_nm_tsv>        <claim.tsv>
//   DORMANT   <driver_symbols_tsv> <claim.tsv>
//   LIFETIME  <abi_contract_tsv>  <claim.tsv>
//   P0        <source_closure_tsv> <claim.tsv>
//   SELFTEST
//
// The claim file is a "key<TAB>value" TSV. The detector compares each
// CLAIMED value against what it re-derives.
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXN   256
#define MAXE  4096
#define MAXR  8192
#define NCOL    24

static U8 *FLD[MAXR * NCOL];
static I64 NROW;

// The claim under test, as key/value pairs.
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

static I64 Atoi(U8 *s) {
  I64 n = 0;
  I64 neg = 0;
  if (*s == 45) { neg = 1; s = s + 1; }
  while (*s >= 48 && *s <= 57) {
    n = n * 10 + (*s - 48);
    s = s + 1;
  }
  if (neg) return 0 - n;
  return n;
}

// Split a TAB-separated line into fields, NUL-terminating each field
// in place. The field pointers are stored at base+col.
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

// Load a TSV. Comment lines (leading '#') and blank lines are skipped.
// The first non-comment line is treated as a header and skipped.
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
  while (i < CN) {
    if (StrEq(CKEY[i], key)) return CVAL[i];
    i = i + 1;
  }
  return 0;
}

// Strip trailing whitespace in place.
// NOTE: PolyC has no `void` type; the empty return type is U0.
static U0 Chomp(U8 *s) {
  I64 n = StrLenOf(s);
  while (n > 0) {
    U8 c = s[n - 1];
    if (c != '\n' && c != '\r' && c != ' ' && c != '\t') break;
    s[n - 1] = 0; n = n - 1;
  }
}

// =========================================================================
// R01_FAKE_DRIVER  ->  POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY
//
// THE ADVERSE CLAIM: "a PolyC-authored driver exists and owns the
// compile decision", demonstrated by a C-owned CLI decoder that calls
// ONE inert PolyC function.
//
// THE DERIVATION: the detector is given the REAL symbol roster of the
// production executable and the list of the driver decision symbols
// that the PolyC subject is REQUIRED to own. A driver that is merely
// LINKED is not an authority. The detector requires that each named
// decision symbol is defined by the PolyC SUBJECT OBJECT and that the
// production C driver source does NOT still contain the corresponding
// decision. A single inert function fails the ownership test.
//
// symbols table columns:
//   0 symbol  1 defn_object_kind  2 defined_by_polyc_subject  3 c_still_owns
// =========================================================================
static I32 ModeFake(U8 *symbols_tsv, U8 *claim_tsv) {
  if (Load(symbols_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", symbols_tsv; return 2; }
  if (LoadClaims(claim_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", claim_tsv; return 2; }

  I64 owned = 0;
  I64 inert_only = 0;
  I64 r = 0;
  while (r < NROW) {
    U8 *sym = FLD[r * NCOL + 0];
    U8 *byPolyc = FLD[r * NCOL + 2];
    U8 *cOwns = FLD[r * NCOL + 3];
    if (sym == 0) { r = r + 1; continue; }
    if (StrEq(byPolyc, "YES") && StrEq(cOwns, "NO")) owned = owned + 1;
    if (StrEq(byPolyc, "YES") && StrEq(cOwns, "YES")) inert_only = inert_only + 1;
    r = r + 1;
  }

  U8 *claimed = Claim("POLYC_DRIVER_DECISIONS_OWNED");
  if (claimed == 0) { "REASON_DETAIL=missing claim POLYC_DRIVER_DECISIONS_OWNED\n"; return 2; }
  I64 claimed_owned = Atoi(claimed);

  U8 *claimed_inert_ptr = Claim("INERT_POLYC_FUNCTIONS_CALLED_BY_C");
  I64 claimed_inert = 0;
  if (claimed_inert_ptr != 0) claimed_inert = Atoi(claimed_inert_ptr);

  if (claimed_owned != owned) {
    "POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY\n";
    "REASON_DETAIL=claimed owned decisions %d differs from the derived %d\n",
      claimed_owned, owned;
    return 1;
  }
  if (claimed_inert != inert_only) {
    "POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY\n";
    "REASON_DETAIL=claimed inert PolyC functions %d differs from the derived %d\n",
      claimed_inert, inert_only;
    return 1;
  }
  if (owned > 0 && owned < 2) {
    "POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY\n";
    "REASON_DETAIL=only %d decision(s) are owned by the PolyC driver; a single inert function is not a driver\n",
      owned;
    return 1;
  }
  return 0;
}

// =========================================================================
// R02_ORACLE_LEAK  ->  C_ORACLE_CONTAMINATED
//
// THE ADVERSE CLAIM: "the selector-OFF C-only driver oracle is
// independent of the new PolyC driver".
//
// THE DERIVATION: the detector is given the REAL `nm -g` roster of the
// selector-OFF oracle executable and the roster of the driver symbols
// the PolyC subject exports. If ANY driver symbol appears in the
// oracle, the oracle is contaminated.
//
// nm table columns:
//   0 symbol  1 in_oracle  2 is_driver_symbol
// =========================================================================
static I32 ModeOracle(U8 *nm_tsv, U8 *claim_tsv) {
  if (Load(nm_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", nm_tsv; return 2; }
  if (LoadClaims(claim_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", claim_tsv; return 2; }

  I64 leaked = 0;
  I64 r = 0;
  while (r < NROW) {
    U8 *sym = FLD[r * NCOL + 0];
    U8 *inOracle = FLD[r * NCOL + 1];
    U8 *isDriver = FLD[r * NCOL + 2];
    if (sym == 0) { r = r + 1; continue; }
    if (StrEq(inOracle, "YES") && StrEq(isDriver, "YES")) leaked = leaked + 1;
    r = r + 1;
  }

  U8 *claimed = Claim("DRIVER_SYMBOLS_IN_C_ONLY_ORACLE");
  if (claimed == 0) { "REASON_DETAIL=missing claim DRIVER_SYMBOLS_IN_C_ONLY_ORACLE\n"; return 2; }
  I64 claimed_leaked = Atoi(claimed);
  if (claimed_leaked != leaked) {
    "C_ORACLE_CONTAMINATED\n";
    "REASON_DETAIL=claimed %d driver symbols in the C-only oracle differs from the derived %d\n",
      claimed_leaked, leaked;
    return 1;
  }
  if (leaked > 0) {
    "C_ORACLE_CONTAMINATED\n";
    "REASON_DETAIL=the C-only oracle imports %d driver PolyC symbol(s)\n", leaked;
    return 1;
  }
  return 0;
}

// =========================================================================
// R03_DORMANT_C  ->  LEGACY_C_DRIVER_DECISION_ACTIVE
//
// THE ADVERSE CLAIM: "the production selector-ON entry lets PolyC own
// the driver decision", i.e. the legacy C decisions are dormant.
//
// THE DERIVATION: the detector is given the REAL relocation evidence
// for the legacy C driver decision points on the PRODUCTION ON route.
// A decision is still ACTIVE in C iff the production C object still
// carries a relocation to it AND the PolyC driver does not own it.
//
// The MIGRATED state and the NOT-YET-MIGRATED state are DISTINCT. At
// C0 no decision is PolyC-owned, so every legacy decision is ACTIVE
// and that is the TRUE state; the claim file says so explicitly
// through the POLYC_OWNER_PRESENT key. A claim of
// POLYC_OWNER_PRESENT=YES over a route that still carries live legacy
// relocations fires the reason token, because that is exactly the
// "dormant C" claim being made falsely.
//
// reloc table columns:
//   0 decision_symbol  1 on_route_relocs  2 owned_by_polyc
// =========================================================================
static I32 ModeDormant(U8 *reloc_tsv, U8 *claim_tsv) {
  if (Load(reloc_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", reloc_tsv; return 2; }
  if (LoadClaims(claim_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", claim_tsv; return 2; }

  I64 active = 0;
  I64 r = 0;
  while (r < NROW) {
    U8 *sym = FLD[r * NCOL + 0];
    U8 *rel = FLD[r * NCOL + 1];
    U8 *owned = FLD[r * NCOL + 2];
    if (sym == 0) { r = r + 1; continue; }
    if (StrEq(rel, "YES") && StrEq(owned, "NO")) active = active + 1;
    r = r + 1;
  }

  U8 *claimed = Claim("LEGACY_C_DECISIONS_ACTIVE_ON_PRODUCTION_ROUTE");
  if (claimed == 0) { "REASON_DETAIL=missing claim LEGACY_C_DECISIONS_ACTIVE_ON_PRODUCTION_ROUTE\n"; return 2; }
  I64 claimed_active = Atoi(claimed);

  U8 *ownerPtr = Claim("POLYC_OWNER_PRESENT");
  I64 owner = 0;
  if (ownerPtr != 0 && StrEq(ownerPtr, "YES")) owner = 1;

  if (claimed_active != active) {
    "LEGACY_C_DRIVER_DECISION_ACTIVE\n";
    "REASON_DETAIL=claimed %d active legacy C decisions differs from the derived %d\n",
      claimed_active, active;
    return 1;
  }
  // The claim is that a PolyC owner exists. Then the legacy decisions
  // on the route MUST be dormant, i.e. zero of them may still be live.
  if (owner == 1 && active > 0) {
    "LEGACY_C_DRIVER_DECISION_ACTIVE\n";
    "REASON_DETAIL=%d legacy C driver decision(s) are still live on the production route although a PolyC owner is claimed\n", active;
    return 1;
  }
  // No PolyC owner is claimed, so the legacy decisions may legitimately
  // still be live. Nothing more to check.
  return 0;
}

// =========================================================================
// R04_ARGUMENT_LIFETIME  ->  DRIVER_ABI_LIFETIME_OR_DOMAIN
//
// THE ADVERSE CLAIM: "the driver ABI is safe".
//
// THE DERIVATION: the detector is given the REAL ABI contract table.
// Every ABI operation must declare a lifetime class and a domain
// check. An operation that borrows a pointer without a lifetime
// class, or that accepts an unchecked domain, is unsafe.
//
// The ABSENCE of the ABI is a DISTINCT state from the presence of an
// unsafe ABI. At C0 the ABI does not exist yet, and that is the TRUE
// state, so the pristine claim must be ACCEPTED. The claim file says
// so explicitly through the ABI_PRESENT key: at C0 it is NO, and the
// detector then requires the ABI table to be EMPTY. A claim of
// ABI_PRESENT=YES over an empty table, or a present-but-unsafe ABI,
// both fire the reason token.
//
// abi table columns:
//   0 operation  1 lifetime_class  2 domain_checked  3 stale_safe
// =========================================================================
static I32 ModeLifetime(U8 *abi_tsv, U8 *claim_tsv) {
  if (Load(abi_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", abi_tsv; return 2; }
  if (LoadClaims(claim_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", claim_tsv; return 2; }

  I64 unsafe = 0;
  I64 ops = 0;
  I64 r = 0;
  while (r < NROW) {
    U8 *op = FLD[r * NCOL + 0];
    U8 *life = FLD[r * NCOL + 1];
    U8 *dom = FLD[r * NCOL + 2];
    U8 *stale = FLD[r * NCOL + 3];
    if (op == 0) { r = r + 1; continue; }
    ops = ops + 1;
    I64 ok = 1;
    if (life == 0 || StrEq(life, "NONE")) ok = 0;
    if (dom == 0 || StrEq(dom, "NO")) ok = 0;
    if (stale == 0 || StrEq(stale, "NO")) ok = 0;
    if (ok == 0) unsafe = unsafe + 1;
    r = r + 1;
  }

  U8 *claimed = Claim("UNSAFE_ABI_OPERATIONS");
  if (claimed == 0) { "REASON_DETAIL=missing claim UNSAFE_ABI_OPERATIONS\n"; return 2; }
  I64 claimed_unsafe = Atoi(claimed);

  U8 *presentPtr = Claim("ABI_PRESENT");
  I64 present = 0;
  if (presentPtr != 0 && StrEq(presentPtr, "YES")) present = 1;

  if (claimed_unsafe != unsafe) {
    "DRIVER_ABI_LIFETIME_OR_DOMAIN\n";
    "REASON_DETAIL=claimed %d unsafe ABI operations differs from the derived %d\n",
      claimed_unsafe, unsafe;
    return 1;
  }
  if (unsafe > 0) {
    "DRIVER_ABI_LIFETIME_OR_DOMAIN\n";
    "REASON_DETAIL=%d ABI operation(s) lack a lifetime class, a domain check or stale safety\n", unsafe;
    return 1;
  }
  // The ABI is claimed to be PRESENT. Then the contract must actually
  // declare operations; an empty contract over a "present" claim is a
  // lie about the ABI.
  if (present == 1 && ops == 0) {
    "DRIVER_ABI_LIFETIME_OR_DOMAIN\n";
    "REASON_DETAIL=the ABI is claimed present but the contract declares no operations\n";
    return 1;
  }
  // The ABI is claimed to be ABSENT. Then the contract must be empty.
  if (present == 0 && ops > 0) {
    "DRIVER_ABI_LIFETIME_OR_DOMAIN\n";
    "REASON_DETAIL=the ABI is claimed absent but the contract declares %d operation(s)\n", ops;
    return 1;
  }
  return 0;
}

// =========================================================================
// R05_FALSE_P0  ->  BOOTSTRAP_SOURCE_CLOSURE_FALSE
//
// THE ADVERSE CLAIM: "the PolyC-authored compiler source set is
// closed", i.e. P0 is complete or M2 is achieved.
//
// THE DERIVATION: the detector is given the REAL source closure table.
// A source set is closed iff every semantic compiler source in the
// closure has a PolyC-authored counterpart. The driver alone does not
// close it.
//
// closure table columns:
//   0 source_id  1 source_file  2 semantic_role  3 polyc_authored
// =========================================================================
static I32 ModeP0(U8 *closure_tsv, U8 *claim_tsv) {
  if (Load(closure_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", closure_tsv; return 2; }
  if (LoadClaims(claim_tsv) < 0) { "REASON_DETAIL=cannot read %s\n", claim_tsv; return 2; }

  I64 semantic = 0;
  I64 authored = 0;
  I64 r = 0;
  while (r < NROW) {
    U8 *role = FLD[r * NCOL + 2];
    U8 *poly = FLD[r * NCOL + 3];
    if (role == 0) { r = r + 1; continue; }
    if (!StrEq(role, "MECHANICAL_GLUE")) {
      semantic = semantic + 1;
      if (StrEq(poly, "YES")) authored = authored + 1;
    }
    r = r + 1;
  }

  U8 *claimed_closed = Claim("P0_SOURCE_SET_CLOSED");
  if (claimed_closed == 0) { "REASON_DETAIL=missing claim P0_SOURCE_SET_CLOSED\n"; return 2; }
  U8 *claimed_m2 = Claim("M2_ACHIEVED");
  U8 *claimed_p0 = Claim("P0_COMPLETE");

  I64 is_closed = 0;
  if (semantic > 0 && authored == semantic) is_closed = 1;

  I64 claims_closed = 0;
  if (StrEq(claimed_closed, "YES")) claims_closed = 1;
  if (claims_closed != is_closed) {
    "BOOTSTRAP_SOURCE_CLOSURE_FALSE\n";
    "REASON_DETAIL=claimed P0 closed=%d differs from the derived %d (%d of %d semantic sources authored)\n",
      claims_closed, is_closed, authored, semantic;
    return 1;
  }
  if (claimed_m2 != 0 && StrEq(claimed_m2, "YES")) {
    "BOOTSTRAP_SOURCE_CLOSURE_FALSE\n";
    "REASON_DETAIL=the source set is not closed, so M2 cannot be achieved\n";
    return 1;
  }
  if (claimed_p0 != 0 && StrEq(claimed_p0, "YES")) {
    "BOOTSTRAP_SOURCE_CLOSURE_FALSE\n";
    "REASON_DETAIL=the source set is not closed, so P0 cannot be complete\n";
    return 1;
  }
  return 0;
}

// =========================================================================
// THE ENTRY POINT
// =========================================================================
I32 Main(I32 argc, U8 **argv) {
  if (argc >= 4 && StrEq(argv[1], "FAKE")) {
    return ModeFake(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "ORACLE")) {
    return ModeOracle(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "DORMANT")) {
    return ModeDormant(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "LIFETIME")) {
    return ModeLifetime(argv[2], argv[3]);
  }
  if (argc >= 4 && StrEq(argv[1], "P0")) {
    return ModeP0(argv[2], argv[3]);
  }
  if (argc >= 3 && StrEq(argv[1], "SELFTEST")) {
    // The selftest exercises the string and integer helpers on KNOWN
    // inputs, so a broken helper cannot make a RED vacuous.
    I64 bad = 0;
    if (!StrEq("abc", "abc")) bad = bad + 1;
    if (StrEq("abc", "abd")) bad = bad + 1;
    if (Atoi("0") != 0) bad = bad + 1;
    if (Atoi("42") != 42) bad = bad + 1;
    if (Atoi("-7") != -7) bad = bad + 1;
    if (StrLenOf("abcd") != 4) bad = bad + 1;
    if (bad != 0) {
      "SELFTEST_FAILED\n";
      "REASON_DETAIL=%d helper checks failed\n", bad;
      return 1;
    }
    return 0;
  }
  "USAGE: driver-migration01-red FAKE|ORACLE|DORMANT|LIFETIME|P0 <primary.tsv> <claim.tsv>\n";
  return 2;
}
