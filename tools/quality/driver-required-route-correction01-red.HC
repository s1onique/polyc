// tools/quality/driver-required-route-correction01-red.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01 C0 RED.
//
// THE FIVE REQUIRED-ROUTE RED DETECTORS.
//
// CONTRACT:
//
//   * Each detector RE-DERIVES every fact it tests from the PRIMARY
//     material it loads itself. It NEVER reads a status field and
//     NEVER trusts an "expected PASS" cell.
//   * A mode is SILENT (exit 0, no output) when the material is
//     CONSISTENT with the audited claim.
//   * A mode prints ITS OWN reason token and exits non-zero when the
//     material is INCONSISTENT. Each mode owns a DISTINCT reason
//     token, so a failure names itself.
//
// THE FIVE REQUIRED-ROUTE RED REASON TOKENS:
//
//   R01_UNUSED_ACTION   POLYC_ACTION_NOT_CONSUMED
//   R02_C_EMISSION_POLICY  C_REQUIRED_ROUTE_DECISION_ACTIVE
//   R03_FAKE_OBJECT    EMITTED_ARTIFACT_CLASS_MISMATCH
//   R04_ORACLE_LEAK    C_DRIVER_ORACLE_CONTAMINATED
//   R05_BACKDATED_RECEIPT  TERMINALITY_CHRONOLOGY_UNPROVEN
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXR 16384
#define NCOL 24

static U8 *FLD[MAXR * NCOL];
static I64 NROW;

// ---------------------------------------------------------------------------
// THE STRING HELPERS
// ---------------------------------------------------------------------------

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

// The number of LINES in a file that contain the substring.
static I64 CountLinesWith(U8 *path, U8 *needle) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  I64 n = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    U8 c = buf[i];
    if (c == 10) {
      // terminate the line in place
      U8 save = buf[i];
      buf[i] = 0;
      if (Has(line, needle) == 1) n++;
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size) {
    if (Has(line, needle) == 1) n++;
  }
  return n;
}

// The number of lines in a file that contain the substring AND do NOT
// contain the exclusion substring.
static I64 CountLinesWithNot(U8 *path, U8 *needle, U8 *excl) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  I64 n = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    U8 c = buf[i];
    if (c == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      if (Has(line, needle) == 1 && Has(line, excl) == 0) n++;
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size) {
    if (Has(line, needle) == 1 && Has(line, excl) == 0) n++;
  }
  return n;
}

// ---------------------------------------------------------------------------
// THE DIAGNOSTIC EMITTERS
// ---------------------------------------------------------------------------

static U0 FailPlain(U8 *token, U8 *detail) {
  "%s|REASON_DETAIL=%s\n", token, detail;
}

static U0 FailOne(U8 *token, U8 *detail, I64 a) {
  "%s|REASON_DETAIL=%s (%d)\n", token, detail, a;
}

static U0 FailTwo(U8 *token, U8 *detail, I64 a, I64 b) {
  "%s|REASON_DETAIL=%s (%d vs %d)\n", token, detail, a, b;
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

// Load a TSV file into FLD/NROW. Comment lines (starting with #) and
// blank lines are skipped.
static I64 Load(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  NROW = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      if (*line != 0 && *line != '#') {
        SplitTabs(line, NROW * NCOL, NCOL);
        NROW++;
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size && *line != 0 && *line != '#') {
    SplitTabs(line, NROW * NCOL, NCOL);
    NROW++;
  }
  return NROW;
}

// ---------------------------------------------------------------------------
// R01_UNUSED_ACTION -- POLYC_ACTION_NOT_CONSUMED
//
// ADVERSE PREMISE: the PolyC action exists in the production compiler,
// but the production emission path never CONSUMES it.
//
// The detector reads the LINKED PRODUCTION BINARY's disassembly and
// counts the CALL SITES of the action accessor. A symbol DEFINITION
// is not consumption.
//
//   argv[1] = the linked production binary (or its disassembly)
//   argv[2] = the action accessor symbol, e.g. _WpDriverSelectedAction
//   argv[3] = the path to the emission function, e.g. _emitFile
// ---------------------------------------------------------------------------
static I32 ModeUnusedAction(I32 argc, U8 **argv) {
  if (argc < 4) { "REASON_DETAIL=usage: R01 <disasm> <symbol> <emitter-fn>\n"; return 2; }
  I64 callsites = CountLinesWith(argv[1], argv[2]);
  if (callsites < 0) { FailPlain("POLYC_ACTION_NOT_CONSUMED", "disassembly unreadable"); return 1; }
  // The emitter function's own body must contain a CALL to the action
  // accessor. A call elsewhere in the binary is NOT consumption.
  I64 inEmitter = 0;
  I64 size = 0;
  U8 *buf = FileRead(argv[1], &size);
  if (buf == NULL) { FailPlain("POLYC_ACTION_NOT_CONSUMED", "disassembly unreadable"); return 1; }
  // find the emitter label line
  I64 i = 0;
  U8 *line = buf;
  I64 inFn = 0;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      if (inFn == 0) {
        if (Has(line, argv[3]) == 1 && Has(line, ":") == 1) inFn = 1;
      } else {
        if (Has(line, ":") == 1 && Has(line, " ") == 0) {
          // next function label -- stop
          buf[i] = save;
          break;
        }
        if (Has(line, "call") == 1 || Has(line, "bl") == 1) {
          if (Has(line, argv[2]) == 1) inEmitter++;
        }
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (inEmitter == 0) {
    FailOne("POLYC_ACTION_NOT_CONSUMED", "the emission function calls the action accessor zero times", inEmitter);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R02_C_EMISSION_POLICY -- C_REQUIRED_ROUTE_DECISION_ACTIVE
//
// ADVERSE PREMISE: the C emission branch still reads the C-side
// request field to decide the artifact class.
//
//   argv[1] = the production C source of the emission function
//   argv[2] = the C field name, e.g. args->emit_object
// ---------------------------------------------------------------------------
static I32 ModeCEmissionPolicy(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: R02 <c-source> <c-field>\n"; return 2; }
  I64 n = CountLinesWith(argv[1], argv[2]);
  if (n < 0) { FailPlain("C_REQUIRED_ROUTE_DECISION_ACTIVE", "C source unreadable"); return 1; }
  if (n > 0) {
    FailOne("C_REQUIRED_ROUTE_DECISION_ACTIVE", "the C emission path still reads the C request field", n);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R03_FAKE_OBJECT -- EMITTED_ARTIFACT_CLASS_MISMATCH
//
// ADVERSE PREMISE: a green compiler invocation wrote an EXECUTABLE
// where an OBJECT was required.
//
//   argv[1] = the produced artifact path
//   argv[2] = the required class token, e.g. "object"
// ---------------------------------------------------------------------------
static I32 ModeFakeObject(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: R03 <artifact> <required-class>\n"; return 2; }
  I64 size = 0;
  U8 *buf = FileRead(argv[1], &size);
  if (buf == NULL) {
    // A MISSING artifact is also a class mismatch: the required
    // artifact was not produced at all.
    FailPlain("EMITTED_ARTIFACT_CLASS_MISMATCH", "the required artifact was not produced");
    return 1;
  }
  U8 kind[64];
  I64 k = 0;
  // The first line of `file` output for a Mach-O object begins with
  // "Mach-O ... object ...". The tool receives the `file` OUTPUT as a
  // text file whose FIRST LINE is the artifact description.
  U8 *line = buf;
  I64 i = 0;
  while (i < size && buf[i] != 10) i++;
  I64 len = i;
  if (len > 63) len = 63;
  I64 j = 0;
  while (j < len) { kind[j] = buf[j]; j++; }
  kind[len] = 0;
  I64 isObj = Has(kind, "object");
  I64 isExe = Has(kind, "executable");
  I64 wantObj = StrEq(argv[2], "object");
  if (wantObj == 1 && isObj == 0) {
    FailPlain("EMITTED_ARTIFACT_CLASS_MISMATCH", "the emitted artifact is not an object");
    return 1;
  }
  if (wantObj == 0 && isExe == 0) {
    FailPlain("EMITTED_ARTIFACT_CLASS_MISMATCH", "the emitted artifact is not an executable");
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R04_ORACLE_LEAK -- C_DRIVER_ORACLE_CONTAMINATED
//
// ADVERSE PREMISE: the selector-OFF C-only oracle imports or calls
// the PolyC driver path.
//
//   argv[1] = the linked G0 oracle's symbol table dump
//   argv[2] = the driver symbol prefix, e.g. _WpDriver
// ---------------------------------------------------------------------------
static I32 ModeOracleLeak(I32 argc, U8 **argv) {
  if (argc < 3) { "REASON_DETAIL=usage: R04 <g0-symbols> <prefix>\n"; return 2; }
  I64 n = CountLinesWith(argv[1], argv[2]);
  if (n < 0) { FailPlain("C_DRIVER_ORACLE_CONTAMINATED", "the G0 symbol table is unreadable"); return 1; }
  if (n > 0) {
    FailOne("C_DRIVER_ORACLE_CONTAMINATED", "the selector-OFF oracle carries driver symbols", n);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R05_BACKDATED_RECEIPT -- TERMINALITY_CHRONOLOGY_UNPROVEN
//
// ADVERSE PREMISE: a tracked CLOSE-tree file claims the result of a
// future external probe.
//
//   argv[1] = the tracked tree listing of the CLOSE tree
//   argv[2] = the receipt file path that must NOT be present in the
//             CLOSE tree. It MUST name THIS ACT's receipt, not a
//             predecessor's: a predecessor's receipt is legitimate
//             historical evidence and must NOT trigger this detector.
//   argv[3] = the predecessor receipt path that MUST be tolerated.
//             The detector asserts that the two are distinguishable,
//             so a broad substring cannot make a pristine tree fire.
//
// A receipt-shaped file is one whose path names THIS ACT's terminality
// receipt. The detector therefore requires the tree listing to contain
// the forbidden path EXACTLY, and additionally requires that the
// tolerated predecessor path does NOT satisfy the forbidden path.
// ---------------------------------------------------------------------------
static I32 ModeBackdatedReceipt(I32 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: R05 <close-tree-listing> <forbidden-path> <tolerated-predecessor-path>\n";
    return 2;
  }
  I64 size = 0;
  U8 *buf = FileRead(argv[1], &size);
  if (buf == NULL) { FailPlain("TERMINALITY_CHRONOLOGY_UNPROVEN", "the CLOSE tree listing is unreadable"); return 1; }
  I64 n = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      if (StrEq(line, argv[2]) == 1) n++;
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size && StrEq(line, argv[2]) == 1) n++;
  if (n < 0) { FailPlain("TERMINALITY_CHRONOLOGY_UNPROVEN", "the CLOSE tree listing is unreadable"); return 1; }
  // The tolerated predecessor path must NOT be the forbidden path.
  if (StrEq(argv[2], argv[3]) == 1) {
    FailPlain("TERMINALITY_CHRONOLOGY_UNPROVEN", "the forbidden path and the tolerated predecessor path are the same");
    return 1;
  }
  if (n > 0) {
    FailOne("TERMINALITY_CHRONOLOGY_UNPROVEN", "the CLOSE tree contains this ACT's terminality receipt", n);
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
  if (StrEq(mode, "R01") == 1) return ModeUnusedAction(argc - 1, argv + 1);
  if (StrEq(mode, "R02") == 1) return ModeCEmissionPolicy(argc - 1, argv + 1);
  if (StrEq(mode, "R03") == 1) return ModeFakeObject(argc - 1, argv + 1);
  if (StrEq(mode, "R04") == 1) return ModeOracleLeak(argc - 1, argv + 1);
  if (StrEq(mode, "R05") == 1) return ModeBackdatedReceipt(argc - 1, argv + 1);
  if (StrEq(mode, "SELFTEST") == 1) {
    if (StrEq("a", "a") == 0) { "SELFTEST_FAILED\n"; return 1; }
    if (StrLenOf("abc") != 3) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("abcdef", "cd") != 1) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("abcdef", "cz") != 0) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("Mach-O 64-bit object arm64", "object") != 1) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("Mach-O 64-bit object arm64", "executable") != 0) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("Mach-O 64-bit executable arm64", "executable") != 1) { "SELFTEST_FAILED\n"; return 1; }
    return 0;
  }
  "REASON_DETAIL=unknown mode %s\n", mode;
  return 2;
}
