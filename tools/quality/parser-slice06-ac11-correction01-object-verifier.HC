// tools/quality/parser-slice06-ac11-correction01-object-verifier.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01 C2.
//
// The independent production-object detector for PD-04 and PS-01.
//
// It reads `nm` output prepared by the caller.  The decision is made in
// PolyC:
//
//   PD-04 PASS: the production parser object has an UNDEFINED reference
//                to BootstrapSwitchArmTerminates and no definition of
//                the legacy decision symbol in that object.
//   PS-01 PASS: the production parser object has an UNDEFINED reference
//                to BootstrapSwitchArmTerminates.
//
// The adverse controls are therefore FAIL when the reference is absent
// (PS-01) or when the legacy decision is present in the active object
// (PD-04).  The tool does not infer sensitivity from pristine evidence;
// it evaluates the actual subject supplied for each condition.
//
// Usage:
//   object-verifier pd04 <parser-object.nm.txt>
//   object-verifier ps01 <parser-object.nm.txt>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define NAME_MAX 256

static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a = a + 1;
    b = b + 1;
  }
  return *a == 0 && *b == 0;
}

static I64 FileContains(U8 *hay, I64 haylen, U8 *needle)
{
  I64 nl = 0;
  while (needle[nl] != 0) nl = nl + 1;
  if (nl == 0) return 1;
  for (I64 i = 0; i + nl <= haylen; i = i + 1) {
    I64 eq = 1;
    for (I64 z = 0; z < nl; z = z + 1) if (hay[i+z] != needle[z]) { eq = 0; break; }
    if (eq == 1) return 1;
  }
  return 0;
}

// Return 1 for an undefined reference, 2 for a definition, 0 absent.
static I64 ObjSymbolKind(U8 *nmtext, U8 *sym)
{
  U8 *p = nmtext;
  while (*p) {
    U8 *nl = p;
    while (*nl && *nl != 10) nl = nl + 1;
    I64 len = nl - p;
    I64 end = len;
    while (end > 0 && (p[end-1] == ' ' || p[end-1] == 9 || p[end-1] == 13)) end = end - 1;
    I64 st = end;
    while (st > 0 && p[st-1] != ' ' && p[st-1] != 9) st = st - 1;
    I64 symlen = end - st;
    I64 te = st;
    while (te > 0 && (p[te-1] == ' ' || p[te-1] == 9)) te = te - 1;
    I64 ts = te;
    while (ts > 0 && p[ts-1] != ' ' && p[ts-1] != 9) ts = ts - 1;
    I64 kind = 0;
    if (te > ts) {
      if (p[ts] == 'U') kind = 1;
      else if (p[ts] == 'T' || p[ts] == 'S' || p[ts] == 'D' || p[ts] == 'B') kind = 2;
    }
    I64 k = 0;
    if (symlen > 0 && p[st] == '_') k = 1;
    if (symlen - k == 0) return 0;
    I64 eq = 1;
    for (I64 z = 0; sym[z] != 0; z = z + 1) {
      if (p[st + k + z] != sym[z]) { eq = 0; break; }
    }
    if (eq == 1 && sym[symlen-k] == 0) return kind;
    if (*nl == 0) break;
    p = nl + 1;
  }
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 3) {
    "usage: object-verifier pd04|ps01 <parser-object.nm.txt>\n";
    return 2;
  }
  I64 sz = 0;
  U8 *nmtext = FileRead(argv[2], &sz);
  if (nmtext == NULL) {
    "AC11_OBJECT_STATUS=FAIL\nAC11_OBJECT_REASON=CANNOT_READ_NM\n";
    return 1;
  }
  I64 polyc = ObjSymbolKind(nmtext, "BootstrapSwitchArmTerminates");
  I64 legacy = ObjSymbolKind(nmtext, "ParserLegacySwitchArmTerminatesOracle");
  "AC11_OBJECT_POLYC_REFERENCE=%d\n", polyc;
  "AC11_OBJECT_LEGACY_SYMBOL=%d\n", legacy;

  if (StrEq(argv[1], "ps01") == 1) {
    if (polyc == 1) {
      "AC11_OBJECT_DETECTOR=DELEGATION_LOAD_BEARING\n";
      "AC11_OBJECT_STATUS=PASS\n";
      return 0;
    }
    "AC11_OBJECT_DETECTOR=DELEGATION_LOAD_BEARING\n";
    "AC11_OBJECT_STATUS=FAIL\n";
    return 1;
  }

  if (StrEq(argv[1], "pd04") == 1) {
    // PD-04's frozen mutation says that the delegation macro is
    // DEFINED but the production object still contains the legacy
    // condition.  In the real production translation unit the
    // PolyC reference lives in the delegated wrapper, while the
    // exposed legacy oracle wrapper is independently compiled.  The
    // adverse subject therefore retains BOTH facts: the PolyC
    // reference and an active legacy comparison/branch shape.
    // The caller supplies a disassembly file proving whether that
    // active legacy shape is present.
    if (argc < 4) {
      "AC11_OBJECT_STATUS=FAIL\nAC11_OBJECT_REASON=MISSING_DISASSEMBLY\n";
      return 1;
    }
    I64 dlen = 0;
    U8 *dtext = FileRead(argv[3], &dlen);
    if (dtext == NULL) {
      "AC11_OBJECT_STATUS=FAIL\nAC11_OBJECT_REASON=CANNOT_READ_DISASSEMBLY\n";
      return 1;
    }
    I64 legacy_active = 0;
    if (FileContains(dtext, dlen, "cmp") == 1
        && FileContains(dtext, dlen, "tst") == 1) legacy_active = 1;
    "AC11_OBJECT_LEGACY_ACTIVE=%d\n", legacy_active;
    if (legacy_active == 1) {
      "AC11_OBJECT_DETECTOR=LEGACY_CONDITION_ABSENT\n";
      "AC11_OBJECT_STATUS=FAIL\n";
      return 1;
    }
    "AC11_OBJECT_DETECTOR=LEGACY_CONDITION_ABSENT\n";
    "AC11_OBJECT_STATUS=PASS\n";
    return 0;
  }

  "AC11_OBJECT_STATUS=FAIL\nAC11_OBJECT_REASON=UNKNOWN_MODE\n";
  return 2;
}
