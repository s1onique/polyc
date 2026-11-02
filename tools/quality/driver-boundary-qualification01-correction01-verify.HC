// tools/quality/driver-boundary-qualification01-correction01-verify.HC
//
// ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01 C2 IMPL.
//
// THE CORRECTION QUALIFICATION VERIFIER.
//
// It is DISTINCT from the predecessor's Q2 verifier
// (driver-boundary-qualification01-verify.HC), which is NOT MODIFIED.
// This verifier answers the questions the predecessor did not.
//
// CONTRACT:
//
//   * It ingests MEASURED SOURCE-DERIVED TABLES as DATA. It never
//     reads a status field and never accepts an expected "PASS"
//     summary as its own measurement.
//   * It RE-DERIVES every count it checks from the loaded rows.
//   * It fails CLOSED: every adverse condition produces its OWN
//     EXACT reason token, on a NONZERO exit.
//   * Each mode is SILENT (exit 0) when the input is consistent.
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.
//
// THE TEN MODES:
//
//   ACSET       the frozen AC identifier set
//   ACPHASE     the frozen phase against the ledger phase
//   ACPREDICATE the frozen predicate against the ledger claim
//   ACWITNESS   the cited witness against the frozen criterion
//   ACCOUNTING  the criterion-only status arithmetic
//   ROUTES      the branch-level route scope
//   DECISION    the decision-owner qualification
//   BASELINE    the historical / fresh / conservation states
//   CHRONOLOGY  the terminality chronology
//   SELFTEST    the verifier's own helpers

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXR 8192
#define NCOL 24

static U8 *FLD[MAXR * NCOL];
static I64 NROW;

static U8 *HDR[NCOL];
static I64 NHDR;

// The FILE-SCOPE working storage. The predecessor's verifier uses
// file-scope statics exclusively, and this compiler mis-places a
// FUNCTION-LOCAL static character array in a file of this size: the
// resulting local label is referenced across function boundaries and
// the link fails. Every working buffer is therefore hoisted here.
static U8 CanonBuf[8];
static U8 WitnessBuf[4];
static U8 *FLD2[MAXR * NCOL];
static U8 *HDR2[NCOL];
static I64 NHDR2;
static I64 NROW2;
// The THIRD table set. It holds the C0 FROZEN CONTRACT, which is the
// immutable anchor that distinguishes a predicate DRIFT on the ledger
// side from a predicate REWRITE of the frozen contract itself.
static U8 *FLD3[MAXR * NCOL];
static U8 *HDR3[NCOL];
static I64 NHDR3;
static I64 NROW3;
static U8 *EFLD[MAXR * NCOL];
static U8 *EHDR[NCOL];
static I64 ENHDR;
static I64 ENROW;
static U8 *XFLD[256];
static U8 *XHDR[NCOL];
static I64 XNHDR;
static I64 XNROW;
static U8 TokBuf[64][64];
static U8 CtokBuf[64][64];
static I64 Seen[64];

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
//
// A reason token is emitted on its OWN LINE, as
//   <TOKEN>|REASON_DETAIL=<detail>
// The token is EXACT. A test that accepts a token by prefix or by
// substring does NOT pass.
// ---------------------------------------------------------------------------
static U0 FailPlain(U8 *token, U8 *detail) {
  "%s|REASON_DETAIL=%s\n", token, detail;
}

static U0 FailOne(U8 *token, U8 *detail, I64 a) {
  "%s|REASON_DETAIL=%s (%d)\n", token, detail, a;
}

static U0 FailId(U8 *token, U8 *detail, U8 *id) {
  "%s|REASON_DETAIL=%s %s\n", token, detail, id;
}

static U0 FailIdOne(U8 *token, U8 *detail, U8 *id, I64 a) {
  "%s|REASON_DETAIL=%s %s (%d)\n", token, detail, id, a;
}

// ---------------------------------------------------------------------------
// THE TABLE LOADER
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
// captured so the verifier can address columns BY NAME, and the
// remaining rows are loaded as data.
static I64 LoadWithHeader(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 n = 0; I64 haveHdr = 0;
  U8 *p = buf; U8 *end = buf + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    if (haveHdr == 0) {
      haveHdr = 1;
      NHDR = SplitTabs(ls, 0, NCOL);
      I64 i = 0;
      while (i < NHDR) { HDR[i] = FLD[i]; i++; }
      continue;
    }
    SplitTabs(ls, n * NCOL, NCOL);
    n++;
  }
  NROW = n;
  return 0;
}

// Load a TSV into a SUPPLIED field set. The header is captured so the
// caller can address columns BY NAME. It returns the number of data
// rows, or -1 when the file is unreadable.
//
// The SECOND and THIRD table sets need their own loader: the primary
// splitter writes into the primary field array, and a table cannot be
// loaded twice into the same array without destroying the first load.
static I64 LoadTableInto(U8 *path, U8 *fld[], U8 *hdr[], I64 ncol);

static I64 ColOf(U8 *name) {
  I64 i = 0;
  while (i < NHDR) {
    if (StrEq(HDR[i], name) == 1) return i;
    i++;
  }
  return -1;
}

// The value of a NAMED column in a NAMED row. It returns the empty
// string when the column or the row does not exist, so a caller must
// distinguish "absent" from "empty" by testing the column index.
static U8 *Cell(U8 *name, I64 r) {
  I64 c = ColOf(name);
  if (c < 0) return 0;
  if (r < 0 || r >= NROW) return 0;
  return FLD[r * NCOL + c];
}

// The SAME, for the SECONDARY table. The secondary table is addressed
// BY NAME as well: a POSITIONAL read of the existence table would
// silently reinterpret the witness_phase column as the carries_subject
// column, and would then accept a chronologically invalid witness.
static U8 *Cell2(U8 *name, I64 r) {
  I64 c = -1;
  I64 i = 0;
  while (i < ENHDR) { if (StrEq(EHDR[i], name) == 1) { c = i; break; } i++; }
  if (c < 0) return 0;
  if (r < 0 || r >= ENROW) return 0;
  return EFLD[r * NCOL + c];
}

static U8 *CellOr(U8 *name, I64 r, U8 *dflt) {
  U8 *v = Cell(name, r);
  if (v == 0) return dflt;
  return v;
}

// ---------------------------------------------------------------------------
// THE FROZEN CORRECTION ROSTERS
//
// The 32 correction acceptance identifiers, and the 18 correction
// negative-control identifiers. These are FROZEN at C0 and are NOT
// editable to obtain a PASS.
// ---------------------------------------------------------------------------
static U8 *ACROSTER[32];
static I64 NACR;

static I64 LoadAcRoster(U8 *path) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 n = 0; I64 haveHdr = 0;
  U8 *p = buf; U8 *end = buf + sz;
  while (p < end && n < 32) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    I64 nf = SplitTabs(ls, 0, NCOL);
    if (haveHdr == 0) { haveHdr = 1; continue; }
    if (nf < 1) continue;
    // The metadata row is NOT an acceptance criterion.
    if (StrEq(FLD[0], "AC_ROSTER_SIZE") == 1) continue;
    ACROSTER[n] = FLD[0];
    n++;
  }
  NACR = n;
  return 0;
}

// The canonical correction acceptance identifiers, AC01 .. AC32.
// They are spelled out rather than computed, so the frozen set is
// readable in the source itself and cannot drift.
static U8 *CanonAcList[32];
static U8 CanonBuf[8];

static U0 InitCanonAcList() {
  CanonAcList[0] = "AC01"; CanonAcList[1] = "AC02"; CanonAcList[2] = "AC03";
  CanonAcList[3] = "AC04"; CanonAcList[4] = "AC05"; CanonAcList[5] = "AC06";
  CanonAcList[6] = "AC07"; CanonAcList[7] = "AC08"; CanonAcList[8] = "AC09";
  CanonAcList[9] = "AC10"; CanonAcList[10] = "AC11"; CanonAcList[11] = "AC12";
  CanonAcList[12] = "AC13"; CanonAcList[13] = "AC14"; CanonAcList[14] = "AC15";
  CanonAcList[15] = "AC16"; CanonAcList[16] = "AC17"; CanonAcList[17] = "AC18";
  CanonAcList[18] = "AC19"; CanonAcList[19] = "AC20"; CanonAcList[20] = "AC21";
  CanonAcList[21] = "AC22"; CanonAcList[22] = "AC23"; CanonAcList[23] = "AC24";
  CanonAcList[24] = "AC25"; CanonAcList[25] = "AC26"; CanonAcList[26] = "AC27";
  CanonAcList[27] = "AC28"; CanonAcList[28] = "AC29"; CanonAcList[29] = "AC30";
  CanonAcList[30] = "AC31"; CanonAcList[31] = "AC32";
}

// The canonical identifier for the ordinal 1..32: AC01 .. AC32.
static U8 *CanonAcId(I64 ordinal) {
  if (ordinal < 1 || ordinal > 32) return 0;
  return CanonAcList[ordinal - 1];
}

// ---------------------------------------------------------------------------
// MODE ACSET
//
// The acceptance identifier set must be EXACTLY AC01..AC32, each
// occurring EXACTLY ONCE, with no unexpected and no missing ID.
//
//   AC_ID_DUPLICATE   an ID occurs more than once
//   AC_ID_MISSING     an expected ID does not occur
//   AC_ID_UNEXPECTED  an ID outside the frozen set occurs
// ---------------------------------------------------------------------------
static I32 ModeAcSet(I32 argc, U8 **argv) {
  if (argc < 2) { "REASON_DETAIL=usage: ACSET <ledger.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("AC_ID_MISSING", "the acceptance ledger is unreadable");
    return 1;
  }
  I64 i = 0;
  I64 seen[64];
  while (i < 64) { seen[i] = 0; i++; }

  I64 r = 0;
  while (r < NROW) {
    U8 *id = Cell("ac_id", r);
    if (id == 0) { r++; continue; }
    if (StrEq(id, "AC_ROSTER_SIZE") == 1) { r++; continue; }
    // Only the EXACT identifier shape is a criterion.
    if (StrLenOf(id) != 4) {
      FailId("AC_ID_UNEXPECTED", "the identifier is not of the ACnn shape:", id);
      return 1;
    }
    if (id[0] != 'A' || id[1] != 'C' || id[2] < '0' || id[2] > '9' || id[3] < '0' || id[3] > '9') {
      FailId("AC_ID_UNEXPECTED", "the identifier is not of the ACnn shape:", id);
      return 1;
    }
    I64 ord = (id[2] - 48) * 10 + (id[3] - 48);
    if (ord < 1 || ord > 32) {
      FailId("AC_ID_UNEXPECTED", "the identifier is outside the frozen AC01..AC32 set:", id);
      return 1;
    }
    if (Seen[ord] == 1) {
      FailId("AC_ID_DUPLICATE", "the identifier occurs more than once:", id);
      return 1;
    }
    Seen[ord] = 1;
    r++;
  }

  I64 k = 1;
  while (k <= 32) {
    if (Seen[k] == 0) {
      FailId("AC_ID_MISSING", "the frozen identifier does not occur:", CanonAcId(k));
      return 1;
    }
    k++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE ACPHASE
//
// The ledger phase of each criterion must EQUAL the frozen phase.
//
//   FROZEN_AC_PHASE_DRIFT    the ledger phase differs from the frozen one
//   FROZEN_AC_PREDICATE_DRIFT the ledger predicate differs from the frozen one
//   FROZEN_CONTRACT_REWRITTEN the frozen predicate was substituted
// ---------------------------------------------------------------------------
// Split a line into TAB-separated fields, writing into a SUPPLIED
// field array. The second table set needs its own splitter, because
// the primary splitter writes into the primary field array.
static I64 SplitTabsInto(U8 *line, U8 *base[], I64 max) {
  I64 n = 0;
  U8 *p = line;
  while (n < max) {
    base[n] = p;
    n = n + 1;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}

// Load a TSV into a SUPPLIED field set. The header is captured so the
// caller can address columns BY NAME. It returns the number of data
// rows, or -1 when the file is unreadable.
//
// The SECOND and THIRD table sets need their own loader: the primary
// splitter writes into the primary field array, and a table cannot be
// loaded twice into the same array without destroying the first load.
static I64 LoadTableInto(U8 *path, U8 *fld[], U8 *hdr[], I64 ncol) {
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 n = 0; I64 haveHdr = 0; I64 nhdr = 0;
  U8 *p = buf; U8 *end = buf + sz;
  while (p < end && n < MAXR) {
    U8 *ls = p;
    while (p < end && *p != '\n') p++;
    U8 *le = p;
    if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0 || *ls == '#') continue;
    if (haveHdr == 0) {
      haveHdr = 1;
      nhdr = SplitTabsInto(ls, fld, ncol);
      I64 i = 0;
      while (i < nhdr) { hdr[i] = fld[i]; i++; }
      continue;
    }
    SplitTabsInto(ls, fld + n * ncol, ncol);
    n++;
  }
  return n;
}

static I32 ModeAcPhase(I32 argc, U8 **argv) {
  if (argc < 2) { "REASON_DETAIL=usage: ACPHASE <ledger.tsv> <frozen.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("AC_ID_MISSING", "the acceptance ledger is unreadable");
    return 1;
  }
  // The FROZEN table is loaded into the SECOND field set, so the two
  // contracts are compared rather than one being read twice.
  NROW2 = LoadTableInto(argv[2], FLD2, HDR2, NCOL);
  if (NROW2 < 0) {
    FailPlain("FROZEN_AC_PREDICATE_DRIFT", "the frozen acceptance roster is unreadable");
    return 1;
  }

  I64 r = 0;
  while (r < NROW) {
    U8 *id = Cell("ac_id", r);
    if (id == 0 || StrEq(id, "AC_ROSTER_SIZE") == 1) { r++; continue; }
    U8 *lph = Cell("phase", r);
    // Find the frozen row with the SAME identifier.
    I64 f = 0; I64 found = 0;
    while (f < NROW2) {
      U8 *fid = FLD2[f * NCOL + 0];
      if (StrEq(fid, id) == 1) { found = 1; break; }
      f++;
    }
    if (found == 0) {
      FailId("AC_ID_MISSING", "the frozen roster has no row for:", id);
      return 1;
    }
    // The frozen phase is column 1, the frozen predicate is column 2.
    U8 *fph = FLD2[f * NCOL + 1];
    U8 *fpred = FLD2[f * NCOL + 2];
    if (lph != 0 && fph != 0 && StrEq(lph, fph) == 0) {
      FailId("FROZEN_AC_PHASE_DRIFT", "the ledger phase differs from the frozen phase:", id);
      return 1;
    }
    // The frozen PREDICATE is carried in the ledger's own predicate
    // column. If the ledger states a predicate and it differs from
    // the frozen one, the contract was rewritten.
    U8 *lpred = Cell("frozen_predicate", r);
    if (lpred != 0 && fpred != 0 && StrLenOf(lpred) > 0) {
      if (StrEq(lpred, fpred) == 0) {
        FailId("FROZEN_AC_PREDICATE_DRIFT", "the stated predicate differs from the frozen predicate:", id);
        return 1;
      }
    }
    r++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE ACPREDICATE
//
// The ledger claim must be about the SAME SUBJECT as the frozen
// predicate. A claim that shares NO distinctive word with the frozen
// predicate is a PREDICATE SUBSTITUTION.
//
//   FROZEN_AC_PREDICATE_DRIFT  the claim does not concern the frozen subject
//   FROZEN_CONTRACT_REWRITTEN  the frozen predicate was replaced
// ---------------------------------------------------------------------------

// The DISTINCTIVE words of a predicate: length >= 5, lowercased,
// deduplicated. A generic word of length 4 or less carries no subject.
//
// The tokens are written into a TWO-DIMENSIONAL CHARACTER BUFFER, not
// into an array of pointers: an array of pointers would hold
// UNINITIALISED addresses, and writing through them faults.
static I64 DistinctiveTokens(U8 *text, I64 max) {
  I64 n = 0;
  I64 len = StrLenOf(text);
  I64 i = 0;
  while (i < len && n < max) {
    U8 *w = TokBuf[n];
    I64 k = 0;
    while (i < len) {
      U8 c = text[i];
      if (c >= 'A' && c <= 'Z') c = c + 32;
      if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_') { w[k] = c; k++; i++; }
      else { i++; break; }
    }
    w[k] = 0;
    if (k >= 5) n++;
  }
  return n;
}

// Collect the distinctive tokens of a text into the SECOND
// two-dimensional character buffer. It returns the number collected.
//
// The buffer is FILE-SCOPE, not a parameter: this compiler does not
// pass a two-dimensional array to a pointer parameter correctly, and
// a function-local static character array faults the link.
static I64 CollectTokens(U8 *text) {
  I64 n = 0;
  I64 len = StrLenOf(text);
  I64 i = 0;
  while (i < len && n < 64) {
    U8 *w = CtokBuf[n];
    I64 k = 0;
    while (i < len) {
      U8 c = text[i];
      if (c >= 'A' && c <= 'Z') c = c + 32;
      if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_') { w[k] = c; k++; i++; }
      else { i++; break; }
    }
    w[k] = 0;
    if (k >= 5) n++;
  }
  return n;
}

static I32 ModeAcPredicate(I32 argc, U8 **argv) {
  if (argc < 4) { "REASON_DETAIL=usage: ACPREDICATE <ledger.tsv> <frozen.tsv> <c0-contract.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("AC_ID_MISSING", "the acceptance ledger is unreadable");
    return 1;
  }
  // The FROZEN table is loaded into the SECOND field set, and the C0
  // FROZEN CONTRACT into the THIRD. The contract is the IMMUTABLE
  // ANCHOR: it is what makes a predicate DRIFT distinguishable from a
  // predicate REWRITE. With only two tables, a rewrite of the frozen
  // table and a substitution on the ledger side look identical.
  NROW2 = LoadTableInto(argv[2], FLD2, HDR2, NCOL);
  if (NROW2 < 0) {
    FailPlain("FROZEN_AC_PREDICATE_DRIFT", "the frozen acceptance roster is unreadable");
    return 1;
  }
  NROW3 = LoadTableInto(argv[3], FLD3, HDR3, NCOL);
  if (NROW3 < 0) {
    FailPlain("FROZEN_CONTRACT_REWRITTEN", "the C0 frozen contract is unreadable");
    return 1;
  }

  I64 r = 0;
  while (r < NROW) {
    U8 *id = Cell("ac_id", r);
    if (id == 0 || StrEq(id, "AC_ROSTER_SIZE") == 1) { r++; continue; }
    U8 *fpred = Cell("frozen_predicate", r);
    // Find the frozen row with the SAME identifier.
    I64 f = -1;
    I64 k = 0;
    while (k < NROW2) {
      if (StrEq(FLD2[k * NCOL + 0], id) == 1) { f = k; break; }
      k++;
    }
    if (f < 0) {
      FailId("AC_ID_MISSING", "the frozen roster has no row for:", id);
      return 1;
    }
    // Find the C0 CONTRACT row with the SAME identifier.
    I64 c = -1;
    k = 0;
    while (k < NROW3) {
      if (StrEq(FLD3[k * NCOL + 0], id) == 1) { c = k; break; }
      k++;
    }
    if (c < 0) {
      FailId("FROZEN_CONTRACT_REWRITTEN", "the C0 frozen contract has no row for:", id);
      return 1;
    }
    // The frozen predicate is column 2 of the frozen table. The C0
    // contract predicate is column 2 of the contract table.
    U8 *frozePred = FLD2[f * NCOL + 2];
    U8 *contractPred = FLD3[c * NCOL + 2];
    if (fpred == 0 || frozePred == 0 || contractPred == 0) {
      FailId("FROZEN_AC_PREDICATE_DRIFT", "the predicate is not stated on all three sides:", id);
      return 1;
    }
    // THE CONTRACT ANCHOR. The frozen table must agree with the
    // immutable C0 contract. A disagreement means the frozen contract
    // itself was REWRITTEN, which is the condition under which a PASS
    // could be obtained by weakening the acceptance criterion.
    if (StrEq(frozePred, contractPred) == 0) {
      FailId("FROZEN_CONTRACT_REWRITTEN", "the frozen table differs from the C0 frozen contract:", id);
      return 1;
    }
    // The ledger's predicate MUST EQUAL the frozen predicate, byte for
    // byte. A substituted predicate is a DRIFT.
    if (StrEq(fpred, frozePred) == 0) {
      FailId("FROZEN_AC_PREDICATE_DRIFT", "the ledger predicate differs from the frozen predicate:", id);
      return 1;
    }
    r++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE ACWITNESS
//
// Every PREDECESSOR criterion's cited witness must EXIST, be committed
// at or before the criterion's frozen phase, and CARRY the frozen
// subject. A criterion may be adjudicated PROVEN only when the
// artifact that discharges it is PRESENT, PHASE-VALID and CARRIES the
// subject.
//
// The input is the 50-row witness binding table. It is addressed BY
// NAME. A POSITIONAL read would silently reinterpret the chronology
// column as the relevance column, and would then accept a
// chronologically invalid witness.
//
//   AC_WITNESS_MISSING            the cited path does not exist
//   AC_WITNESS_CHRONOLOGY_INVALID  the witness is from the wrong phase
//   AC_WITNESS_PREDICATE_MISMATCH  the witness does not carry the subject
//   AC_WITNESS_INSUFFICIENT        a PROVEN verdict has no binding
//                                  artifact that carries the subject
// ---------------------------------------------------------------------------

// The phase directory of a witness path: q0 -> Q0, and so on.
static U8 *WitnessPhase(U8 *path) {
  if (StrLenOf(path) < 3) return 0;
  if (path[0] != 'q') return 0;
  if (path[2] != '/') return 0;
  U8 *buf = WitnessBuf;
  buf[0] = 'Q'; buf[1] = path[1]; buf[2] = 0;
  return buf;
}

// Whether a phase label is at or BEFORE the criterion's phase.
static I64 PhaseAtOrBefore(U8 *witnessPhase, U8 *criterionPhase) {
  if (witnessPhase == 0 || criterionPhase == 0) return 1;
  I64 w = witnessPhase[1] - 48;
  I64 c = criterionPhase[1] - 48;
  if (c < 0 || c > 9 || w < 0 || w > 9) return 1;
  if (w <= c) return 1;
  return 0;
}

static I32 ModeAcWitness(I32 argc, U8 **argv) {
  if (argc < 2) { "REASON_DETAIL=usage: ACWITNESS <witness-binding.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("AC_WITNESS_MISSING", "the witness binding table is unreadable");
    return 1;
  }

  I64 r = 0;
  while (r < NROW) {
    U8 *id = Cell("ac_id", r);
    if (id == 0 || StrEq(id, "AC_ROSTER_SIZE") == 1) { r++; continue; }

    // FAIL CLOSED. Every column the check needs must be PRESENT. A
    // missing column means the binding cannot be checked, and a silent
    // skip would make this mode a NO-OP that always passes.
    U8 *fph = Cell("frozen_phase", r);
    U8 *cit = Cell("cited_witness", r);
    U8 *cpres = Cell("cited_present", r);
    U8 *cph = Cell("cited_phase_valid", r);
    U8 *ccar = Cell("cited_carries", r);
    U8 *ba = Cell("binding_artifact", r);
    U8 *bpres = Cell("binding_present", r);
    U8 *bph = Cell("binding_phase_valid", r);
    U8 *bcar = Cell("binding_carries", r);
    U8 *st = Cell("verified_status", r);
    if (fph == 0 || cit == 0 || cpres == 0 || cph == 0 || ccar == 0 ||
        ba == 0 || bpres == 0 || bph == 0 || bcar == 0 || st == 0) {
      FailId("AC_WITNESS_MISSING", "the witness binding table lacks a required column:", id);
      return 1;
    }

    // A PROVEN verdict requires a binding artifact that is present,
    // phase-valid and carries the subject. The binding is the CITED
    // witness when the criterion was proven as frozen, and a DIFFERENT
    // existing witness otherwise.
    //
    // The CITED witness is NOT required to be sound. The predecessor
    // cited witnesses that do not exist, that were committed too late,
    // or that do not carry the frozen subject. Those are the DEFECTS
    // this correction reconciles. What the correction must prove is
    // that every criterion it reports as PROVEN is discharged by a
    // binding artifact that is present, phase-valid and carries the
    // subject.
    I64 isFrozen = (StrEq(st, "PROVEN_AS_FROZEN") == 1);
    I64 isAlternate = (StrEq(st, "PROVEN_BY_ALTERNATE_EXISTING_WITNESS") == 1);
    if (isFrozen == 1 || isAlternate == 1) {
      if (StrEq(bpres, "YES") != 1) {
        FailId("AC_WITNESS_INSUFFICIENT", "the PROVEN verdict has no binding artifact in the close tree:", id);
        return 1;
      }
      if (StrEq(bph, "YES") != 1) {
        FailId("AC_WITNESS_CHRONOLOGY_INVALID", "the binding artifact is not at a valid phase:", id);
        return 1;
      }
      if (StrEq(bcar, "YES") != 1) {
        FailId("AC_WITNESS_INSUFFICIENT", "the binding artifact does not carry the frozen subject:", id);
        return 1;
      }
      // When the criterion is proven AS FROZEN, the CITED witness IS
      // the binding. The cited witness must therefore carry the frozen
      // subject itself, and it must be committed at or before the
      // frozen criterion phase.
      if (isFrozen == 1) {
        if (StrEq(ccar, "YES") != 1) {
          FailId("AC_WITNESS_PREDICATE_MISMATCH", "the cited witness does not carry the frozen predicate subject:", id);
          return 1;
        }
        if (StrEq(cph, "NO") == 1) {
          FailId("AC_WITNESS_CHRONOLOGY_INVALID", "the cited witness was committed after the frozen criterion phase:", id);
          return 1;
        }
        if (StrEq(cpres, "YES") != 1) {
          FailId("AC_WITNESS_MISSING", "the cited witness path is not present in the close tree:", id);
          return 1;
        }
      }
    }
    // A criterion that is NOT proven must NOT claim a binding artifact
    // that carries the subject. A criterion with no discharging witness
    // cannot simultaneously present one.
    if (isFrozen == 0 && isAlternate == 0) {
      if (StrEq(bcar, "YES") == 1) {
        FailId("AC_WITNESS_INSUFFICIENT", "an unproven criterion claims a binding artifact that carries the subject:", id);
        return 1;
      }
    }
    r++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE ACCOUNTING
//
// The criterion-only status arithmetic.
//
//   AC_METADATA_COUNTED    a metadata row was counted as a criterion
//   AC_STATUS_TOTAL_FORGED the status totals do not sum to the roster
// ---------------------------------------------------------------------------
// Parse a SMALL NON-NEGATIVE INTEGER from a decimal string. It
// returns -1 when the string is not a plain decimal number.
static I64 ParseCount(U8 *s) {
  if (s == 0) return -1;
  I64 n = 0;
  I64 i = 0;
  if (s[0] == 0) return -1;
  while (s[i] != 0) {
    if (s[i] < '0' || s[i] > '9') return -1;
    n = n * 10 + (s[i] - 48);
    i++;
  }
  return n;
}

static I32 ModeAccounting(I32 argc, U8 **argv) {
  if (argc < 2) { "REASON_DETAIL=usage: ACCOUNTING <ledger.tsv> <expected.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("AC_ID_MISSING", "the acceptance ledger is unreadable");
    return 1;
  }
  I64 nPass = 0; I64 nFail = 0; I64 nDef = 0; I64 nOther = 0; I64 nMeta = 0; I64 nCrit = 0;
  I64 r = 0;
  while (r < NROW) {
    U8 *id = Cell("ac_id", r);
    if (id == 0) { r++; continue; }
    U8 *st = Cell("status", r);
    if (StrEq(id, "AC_ROSTER_SIZE") == 1) {
      // The metadata row is NOT a criterion. It is counted SEPARATELY.
      nMeta++;
      if (st != 0 && StrEq(st, "PASS") == 1) {
        FailPlain("AC_METADATA_COUNTED", "the AC_ROSTER_SIZE metadata row carries a PASS status");
        return 1;
      }
      r++;
      continue;
    }
    if (StrLenOf(id) == 4 && id[0] == 'A' && id[1] == 'C') {
      nCrit++;
      if (st == 0) { FailId("AC_STATUS_TOTAL_FORGED", "the criterion has no status:", id); return 1; }
      if (StrEq(st, "PASS") == 1) nPass++;
      else if (StrEq(st, "FAIL") == 1) nFail++;
      else if (StrEq(st, "DEFERRED") == 1) nDef++;
      else { FailId("AC_STATUS_TOTAL_FORGED", "the criterion carries an unknown status:", id); return 1; }
    }
    r++;
  }
  if (nCrit != 32) {
    FailOne("AC_STATUS_TOTAL_FORGED", "the criterion count is not the frozen roster size:", nCrit);
    return 1;
  }
  I64 total = nPass + nFail + nDef;
  if (total != nCrit) {
    FailOne("AC_STATUS_TOTAL_FORGED", "the status totals do not sum to the criterion count:", total);
    return 1;
  }
  // The EXPECTED table states the historical criterion-only counts.
  if (argc >= 3) {
    I64 sz = 0;
    U8 *buf = FileRead(argv[2], &sz);
    if (buf == 0) {
      FailPlain("AC_STATUS_TOTAL_FORGED", "the expected counts table is unreadable");
      return 1;
    }
    I64 n = 0; I64 haveHdr = 0;
    U8 *p = buf; U8 *end = buf + sz;
    while (p < end && n < 256) {
      U8 *ls = p;
      while (p < end && *p != '\n') p++;
      U8 *le = p;
      if (p < end) p++;
      if (le > ls && *(le - 1) == '\r') le--;
      *le = 0;
      if (*ls == 0 || *ls == '#') continue;
      if (haveHdr == 0) {
        haveHdr = 1;
        XNHDR = SplitTabsInto(ls, XFLD, NCOL);
        I64 i = 0;
        while (i < XNHDR) { XHDR[i] = XFLD[i]; i++; }
        continue;
      }
      SplitTabsInto(ls, XFLD + n * NCOL, NCOL);
      n++;
    }
    XNROW = n;
    I64 e = 0;
    while (e < XNROW) {
      U8 *k = XFLD[e * NCOL + 0];
      U8 *v = XFLD[e * NCOL + 1];
      if (StrEq(k, "EXPECTED_PASS") == 1) {
        I64 want = ParseCount(v);
        if (want < 0) { FailPlain("AC_STATUS_TOTAL_FORGED", "EXPECTED_PASS is not a number"); return 1; }
        if (want != nPass) {
          FailOne("AC_STATUS_TOTAL_FORGED", "the recomputed PASS count differs from the expected count:", nPass);
          return 1;
        }
      }
      if (StrEq(k, "EXPECTED_FAIL") == 1) {
        I64 want = ParseCount(v);
        if (want < 0) { FailPlain("AC_STATUS_TOTAL_FORGED", "EXPECTED_FAIL is not a number"); return 1; }
        if (want != nFail) {
          FailOne("AC_STATUS_TOTAL_FORGED", "the recomputed FAIL count differs from the expected count:", nFail);
          return 1;
        }
      }
      if (StrEq(k, "EXPECTED_DEFERRED") == 1) {
        I64 want = ParseCount(v);
        if (want < 0) { FailPlain("AC_STATUS_TOTAL_FORGED", "EXPECTED_DEFERRED is not a number"); return 1; }
        if (want != nDef) {
          FailOne("AC_STATUS_TOTAL_FORGED", "the recomputed DEFERRED count differs from the expected count:", nDef);
          return 1;
        }
      }
      e++;
    }
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE ROUTES
//
// The branch-level route scope.
//
// A branch's route scope is a PER-BRANCH fact. A branch that is
// reachable on a route OTHER than the required route does NOT prove
// required-route reachability, and a FUNCTION-level reachability
// statement does NOT stand in for a BRANCH-level one.
//
//   BRANCH_ROUTE_SCOPE_LAUNDERED
//       a non-required-route witness is counted as required-route proof
//   FUNCTION_BRANCH_REACHABILITY_CONFLATED
//       a function-level statement is used as a branch-level one
// ---------------------------------------------------------------------------
static I32 ModeRoutes(I32 argc, U8 **argv) {
  if (argc < 2) { "REASON_DETAIL=usage: ROUTES <branches.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("BRANCH_ROUTE_SCOPE_LAUNDERED", "the branch inventory is unreadable");
    return 1;
  }
  I64 nReq = 0; I64 nGlobal = 0; I64 nUnproven = 0;
  I64 r = 0;
  while (r < NROW) {
    U8 *bid = Cell("branch_id", r);
    if (bid == 0 || StrLenOf(bid) == 0) { r++; continue; }
    U8 *req = Cell("required_route_reachable", r);
    U8 *whl = Cell("whole_cli_reachable", r);
    U8 *wit = Cell("linked_execution_witness", r);
    U8 *cf = Cell("counterfactual_result", r);
    U8 *taken = Cell("required_route_taken", r);
    if (req == 0 || whl == 0 || taken == 0) {
      FailId("BRANCH_ROUTE_SCOPE_LAUNDERED", "the branch does not state a route scope:", bid);
      return 1;
    }
    I64 isReq = (StrEq(req, "PROVEN_REACHABLE") == 1);
    I64 isUn = (StrEq(req, "UNPROVEN") == 1);
    I64 isUnr = (StrEq(req, "PROVEN_UNREACHABLE") == 1);
    if (isReq == 0 && isUn == 0 && isUnr == 0) {
      FailId("BRANCH_ROUTE_SCOPE_LAUNDERED", "the branch route scope is not in the frozen vocabulary:", bid);
      return 1;
    }
    // A branch claimed REACHABLE on the required route must carry a
    // concrete route argument: a linked execution witness, a
    // counterfactual, or a source-trace proof. A FUNCTION-level
    // statement alone is NOT sufficient.
    if (isReq == 1) {
      I64 hasTrace = (Has(wit, "REQUIRED_ROUTE_TRACE") == 1);
      I64 hasCf = (Has(cf, "ARTIFACT") == 1) || (Has(cf, "CHANGED") == 1);
      if (hasTrace == 0 && hasCf == 0) {
        FailId("FUNCTION_BRANCH_REACHABILITY_CONFLATED", "the required-route reachability has no branch-level proof:", bid);
        return 1;
      }
      // The route argument must be ON THE REQUIRED ROUTE. A witness
      // whose only route qualifier names ANOTHER route, such as
      // TOKEN_ROUTE or OFF_ROUTE, does not prove required-route
      // reachability. This is the route-scope laundering condition.
      I64 onRequired = (Has(cf, "TOKEN_ROUTE") == 0) && (Has(cf, "OFF_ROUTE") == 0) &&
                       (Has(wit, "TOKEN_ROUTE") == 0) && (Has(wit, "OFF_ROUTE") == 0);
      if (onRequired == 0) {
        FailId("BRANCH_ROUTE_SCOPE_LAUNDERED", "the reachability witness is on another route, not the required route:", bid);
        return 1;
      }
      // The branch must actually be TAKEN on the required route.
      if (StrEq(taken, "YES") != 1) {
        FailId("BRANCH_ROUTE_SCOPE_LAUNDERED", "the branch is not taken on the required route:", bid);
        return 1;
      }
      nReq++;
    }
    // A branch NOT taken on the required route cannot be REACHABLE on
    // it. A whole-CLI-scope branch is a DIFFERENT scope.
    if (StrEq(taken, "NO") == 1 && isReq == 1) {
      FailId("BRANCH_ROUTE_SCOPE_LAUNDERED", "the branch is not taken on the required route:", bid);
      return 1;
    }
    if (isUn == 1) nUnproven++;
    if (StrEq(whl, "PROVEN_REACHABLE") == 1) nGlobal++;
    r++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE DECISION
//
// The decision-owner qualification.
//
//   DECISION_OWNER_NOT_CAUSALLY_SEPARATED
//       a C branch is called a policy owner on the strength of a
//       causal execution alone
//   MUTANT_LINK_PROVENANCE_MISSING
//       a counterfactual has no linked-binary provenance
//   SEMANTIC_COMPARATOR_INSENSITIVE
//       a comparator does not observe artifact type, exit, stdout or
//       stderr
// ---------------------------------------------------------------------------
static I32 ModeDecision(I32 argc, U8 **argv) {
  if (argc < 2) { "REASON_DETAIL=usage: DECISION <ownership.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("DECISION_OWNER_NOT_CAUSALLY_SEPARATED", "the ownership table is unreadable");
    return 1;
  }
  I64 r = 0;
  while (r < NROW) {
    U8 *bid = Cell("branch_id", r);
    if (bid == 0 || StrLenOf(bid) == 0) { r++; continue; }
    U8 *final = Cell("FINAL_QUALIFICATION", r);
    U8 *pol = Cell("POLYC_INTENT_PROVEN", r);
    U8 *map = Cell("C_ACTION_MAPPING_PROVEN", r);
    U8 *indep = Cell("C_INDEPENDENT_POLICY_PROVEN", r);
    U8 *mech = Cell("MECHANICAL_EXECUTION_PROVEN", r);
    U8 *cmp = Cell("comparator_observed_dimensions", r);
    U8 *link = Cell("mutant_binary_linked", r);
    if (final == 0 || StrLenOf(final) == 0) {
      FailId("DECISION_OWNER_NOT_CAUSALLY_SEPARATED", "the branch has no final qualification:", bid);
      return 1;
    }
    // A C SEMANTIC OWNER verdict REQUIRES the independent-policy
    // evidence. A causal execution alone does not establish it.
    if (StrEq(final, "C_SEMANTIC_OWNER_PROVEN") == 1) {
      if (indep == 0 || StrEq(indep, "YES") == 0) {
        FailId("DECISION_OWNER_NOT_CAUSALLY_SEPARATED", "a C policy owner is claimed without the independent-policy evidence:", bid);
        return 1;
      }
    }
    // A POLYC_SEMANTIC_OWNER_C_EXECUTOR verdict requires the intent to
    // be proven AND the mapping to be proven.
    if (StrEq(final, "POLYC_SEMANTIC_OWNER_C_EXECUTOR") == 1) {
      if (pol == 0 || StrEq(pol, "YES") == 0) {
        FailId("DECISION_OWNER_NOT_CAUSALLY_SEPARATED", "a PolyC-owned verdict is claimed without the intent evidence:", bid);
        return 1;
      }
      if (map == 0 || StrEq(map, "YES") == 0) {
        FailId("DECISION_OWNER_NOT_CAUSALLY_SEPARATED", "a PolyC-owned verdict is claimed without the action-mapping evidence:", bid);
        return 1;
      }
    }
    // A counterfactual MUST be linked into the executed binary. The
    // column states whether the mutant binary was DIFFERENT from the
    // baseline and therefore actually linked.
    if (link != 0 && StrEq(link, "NO") == 1) {
      FailId("MUTANT_LINK_PROVENANCE_MISSING", "the counterfactual was never linked into the executed binary:", bid);
      return 1;
    }
    // The comparator MUST observe the artifact type, the exit code,
    // stdout and stderr. A comparator that ignores any of them is
    // INSENSITIVE.
    if (cmp != 0 && StrLenOf(cmp) > 0) {
      if (Has(cmp, "artifact_type") == 0) {
        FailId("SEMANTIC_COMPARATOR_INSENSITIVE", "the comparator does not observe the artifact type:", bid);
        return 1;
      }
      if (Has(cmp, "exit_code") == 0) {
        FailId("SEMANTIC_COMPARATOR_INSENSITIVE", "the comparator does not observe the exit code:", bid);
        return 1;
      }
      if (Has(cmp, "stdout") == 0) {
        FailId("SEMANTIC_COMPARATOR_INSENSITIVE", "the comparator does not observe stdout:", bid);
        return 1;
      }
      if (Has(cmp, "stderr") == 0) {
        FailId("SEMANTIC_COMPARATOR_INSENSITIVE", "the comparator does not observe stderr:", bid);
        return 1;
      }
    }
    r++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE BASELINE
//
// The three baseline states are kept DISTINCT.
//
//   BASELINE_NOT_REMEASURED_LAUNDERED
//       a NOT_REMEASURED historical value is presented as a fresh PASS
// ---------------------------------------------------------------------------
static I32 ModeBaseline(I32 argc, U8 **argv) {
  if (argc < 2) { "REASON_DETAIL=usage: BASELINE <baseline.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("BASELINE_NOT_REMEASURED_LAUNDERED", "the baseline table is unreadable");
    return 1;
  }
  I64 r = 0;
  while (r < NROW) {
    U8 *key = Cell("key", r);
    if (key == 0 || StrLenOf(key) == 0) { r++; continue; }
    U8 *hist = Cell("HISTORICAL_VALUE", r);
    U8 *fresh = Cell("FRESH_MEASUREMENT", r);
    U8 *verd = Cell("CONSERVATION_VERDICT", r);
    if (fresh == 0 || verd == 0) {
      FailId("BASELINE_NOT_REMEASURED_LAUNDERED", "the baseline does not state all three states:", key);
      return 1;
    }
    // A historical NOT_REMEASURED value may NOT acquire a fresh PASS.
    I64 histNotRe = (Has(hist, "NOT_REMEASURED") == 1);
    I64 freshPass = (StrEq(fresh, "PASS") == 1);
    if (histNotRe == 1 && freshPass == 1) {
      FailId("BASELINE_NOT_REMEASURED_LAUNDERED", "a NOT_REMEASURED historical value is presented as a fresh PASS:", key);
      return 1;
    }
    // A NOT_REMEASURED historical value keeps its CONSERVED verdict.
    if (histNotRe == 1) {
      if (Has(verd, "CONSERVED_AS_NOT_REMEASURED") == 0 && Has(verd, "NOT_REMEASURED") == 0) {
        FailId("BASELINE_NOT_REMEASURED_LAUTHORED", "the verdict does not preserve the NOT_REMEASURED state:", key);
        return 1;
      }
    }
    r++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE CHRONOLOGY
//
// The terminality chronology.
//
//   PRECOMMITTED_EXTERNAL_SUCCESS
//       an external success is claimed before the close
//   HISTORICAL_TERMINALITY_LAUNDERED
//       a historical receipt chronology is invented
// ---------------------------------------------------------------------------
static I32 ModeChronology(I32 argc, U8 **argv) {
  if (argc < 2) { "REASON_DETAIL=usage: CHRONOLOGY <chronology.tsv>\n"; return 2; }
  if (LoadWithHeader(argv[1]) < 0) {
    FailPlain("HISTORICAL_TERMINALITY_LAUNDERED", "the chronology table is unreadable");
    return 1;
  }
  I64 r = 0;
  while (r < NROW) {
    U8 *key = Cell("key", r);
    if (key == 0 || StrLenOf(key) == 0) { r++; continue; }
    U8 *val = Cell("value", r);
    U8 *at = Cell("observed_at", r);
    if (val == 0) { r++; continue; }
    // The HISTORICAL terminality claim is checked FIRST and on its own
    // terms. The historical ACT's terminality was never proven by a
    // topology-backed receipt, so a historical row that claims a
    // confirmed external success is a LAUNDERED chronology. It is not
    // a precommitted EXTERNAL success: the two conditions are
    // different, and each must produce its OWN reason token.
    if (Has(key, "HISTORICAL_ACT_TERMINALITY") == 1) {
      if (StrEq(val, "CONFIRMED") == 1 || StrEq(val, "EXTERNAL_SUCCESS") == 1) {
        FailId("HISTORICAL_TERMINALITY_LAUNDERED", "the historical terminality is presented as confirmed:", key);
        return 1;
      }
    }
    // The PRE-COMMITTED tracked outcome may not be presented as
    // topology-backed.
    if (Has(key, "HISTORICAL_TRACKED_OUTCOME_PROVENANCE") == 1) {
      if (Has(val, "TOPOLOGY_BACKED") == 1 || Has(val, "CONFIRMED") == 1) {
        FailId("HISTORICAL_TERMINALITY_LAUNDERED", "the precommitted tracked outcome is presented as topology-backed:", key);
        return 1;
      }
    }
    // An external success may be claimed only AT OR AFTER the close.
    if (Has(val, "EXTERNAL_SUCCESS") == 1 || Has(val, "PROBE_PASS") == 1) {
      if (at == 0 || StrLenOf(at) == 0) {
        FailId("PRECOMMITTED_EXTERNAL_SUCCESS", "an external success is claimed with no observation point:", key);
        return 1;
      }
      if (StrEq(at, "AT_OR_AFTER_CLOSE") == 0) {
        FailId("PRECOMMITTED_EXTERNAL_SUCCESS", "an external success is claimed BEFORE the close:", key);
        return 1;
      }
    }
    r++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// MODE SELFTEST
// ---------------------------------------------------------------------------
static I32 Selftest() {
  InitCanonAcList();
  if (StrEq("abc", "abc") != 1) { "REASON_DETAIL=StrEq failed on equal strings\n"; return 1; }
  if (StrEq("abc", "abd") != 0) { "REASON_DETAIL=StrEq failed on different strings\n"; return 1; }
  if (StrEq("", "") != 1) { "REASON_DETAIL=StrEq failed on empty strings\n"; return 1; }
  if (Has("hello world", "world") != 1) { "REASON_DETAIL=Has failed on a present needle\n"; return 1; }
  if (Has("hello world", "planet") != 0) { "REASON_DETAIL=Has failed on an absent needle\n"; return 1; }
  if (Has("hello", "") != 1) { "REASON_DETAIL=Has failed on an empty needle\n"; return 1; }
  if (StrLenOf("abcd") != 4) { "REASON_DETAIL=StrLenOf failed\n"; return 1; }
  if (PhaseAtOrBefore("Q0", "Q1") != 1) { "REASON_DETAIL=PhaseAtOrBefore failed for Q0 before Q1\n"; return 1; }
  if (PhaseAtOrBefore("Q2", "Q1") != 0) { "REASON_DETAIL=PhaseAtOrBefore failed for Q2 after Q1\n"; return 1; }
  if (StrEq(CanonAcId(1), "AC01") != 1) { "REASON_DETAIL=CanonAcId failed for 1\n"; return 1; }
  if (StrEq(CanonAcId(32), "AC32") != 1) { "REASON_DETAIL=CanonAcId failed for 32\n"; return 1; }
  if (StrEq(CanonAcId(12), "AC12") != 1) { "REASON_DETAIL=CanonAcId failed for 12\n"; return 1; }
  if (StrEq(WitnessPhase("q2/foo.tsv"), "Q2") != 1) { "REASON_DETAIL=WitnessPhase failed for q2\n"; return 1; }
  if (WitnessPhase("docs/x.md") != 0) { "REASON_DETAIL=WitnessPhase failed for a non-phase path\n"; return 1; }
  {
    I64 n = DistinctiveTokens("Real compile-output fixture succeeds", 8);
    if (n != 4) { "REASON_DETAIL=DistinctiveTokens failed\n"; return 1; }
  }
  {
    I64 n = CollectTokens("an INDEPENDENT POSIX witness agrees");
    if (n != 4) { "REASON_DETAIL=CollectTokens failed\n"; return 1; }
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
  InitCanonAcList();
  U8 *mode = argv[1];
  if (StrEq(mode, "ACSET") == 1)      return ModeAcSet(argc - 1, argv + 1);
  if (StrEq(mode, "ACPHASE") == 1)    return ModeAcPhase(argc - 1, argv + 1);
  if (StrEq(mode, "ACPREDICATE") == 1) return ModeAcPredicate(argc - 1, argv + 1);
  if (StrEq(mode, "ACWITNESS") == 1)  return ModeAcWitness(argc - 1, argv + 1);
  if (StrEq(mode, "ACCOUNTING") == 1) return ModeAccounting(argc - 1, argv + 1);
  if (StrEq(mode, "ROUTES") == 1)     return ModeRoutes(argc - 1, argv + 1);
  if (StrEq(mode, "DECISION") == 1)   return ModeDecision(argc - 1, argv + 1);
  if (StrEq(mode, "BASELINE") == 1)   return ModeBaseline(argc - 1, argv + 1);
  if (StrEq(mode, "CHRONOLOGY") == 1) return ModeChronology(argc - 1, argv + 1);
  if (StrEq(mode, "SELFTEST") == 1)   return Selftest();
  "REASON_DETAIL=unknown mode %s\n", mode;
  return 2;
}
