// tools/quality/driver-required-route-correction02-test.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02.
//
// THE CANONICAL PRECEDENCE REGRESSION TEST.
//
// It checks that the PolyC-selected STATUS has PRECEDENCE over the
// C-owned `-o-`/`-S` policy.
//
// The test reads a TRANSCRIPT: for each precedence case, the recorded
// exit status and the recorded stderr of a REAL production compiler
// invocation. The transcript is produced by the canonical Make target,
// which runs the REAL production compiler.
//
// The expectations are the FROZEN ones from the C1 precedence
// contract:
//
//   case                         selected status   reported diagnostic
//   stdout without assembly      TO_STDOUT         the `-o-` diagnostic
//   stdout without assembly and
//     an unknown argument        USAGE             the unknown-arguments
//                                                 diagnostic
//   stdout without assembly and
//     an arity violation         ARITY             the arity diagnostic
//   stdout WITH assembly         COMPILE           no diagnostic
//
// The point of the test is the SECOND and THIRD rows: before the
// correction the C-owned policy preempted the PolyC-selected status
// and reported its own diagnostic instead.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXR 8192
#define NCOL 12

// NOTE: NO FILE-SCOPE INITIALISER HERE.
//
// A file-scope initialiser makes the production compiler build a
// synthetic `_main` driver that calls the user `Main` with argc=0 and
// argv=NULL. This tool NEEDS the real argc/argv, so it declares its
// accumulator WITHOUT an initialiser and seeds it on entry. The same
// constraint and the same workaround are already recorded as RES-01
// by ACT-POLYC-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01.
static I64 failures;

static U8 *FLD[MAXR * NCOL];

// The EMPTY string, used for a field a row did not fill. A cleared
// slot must point at the empty string, not at the row text, so that a
// short row cannot inherit the PREVIOUS row's trailing content.
//
// It is a one-byte BUFFER with a NUL in it, not a file-scope
// initialiser: a file-scope initialiser makes the production compiler
// build a synthetic `_main` driver that calls the user `Main` with
// argc=0 and argv=NULL. The same constraint and the same workaround
// are already recorded as RES-01 by
// ACT-POLYC-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01.
static U8 EMPTY_FIELD_BUF[1];
static I64 NROW;

// The REAL field count of each loaded row. A field at or beyond that
// count is the EMPTY string. The count is recorded because a row may
// carry FEWER fields than the format declares, and a missing trailing
// field must read as empty rather than as whatever the buffer held.
static I64 NCNT[MAXR];

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

static U0 FailOne(U8 *token, U8 *detail, I64 a) {
  "%s|REASON_DETAIL=%s (%d)\n", token, detail, a;
  failures = failures + 1;
}

static U0 FailPlain(U8 *token, U8 *detail) {
  "%s|REASON_DETAIL=%s\n", token, detail;
  failures = failures + 1;
}

// Split one TSV line in place. Returns the field count.
//
// Every slot up to `max` is CLEARED first, so a row with FEWER fields
// than the previous row cannot inherit a STALE field. A trailing empty
// field is a real value: it is the empty string.
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
  // Clear the slots this row did not fill.
  I64 c = n;
  while (c < max) { FLD[base + c] = EMPTY_FIELD_BUF; c = c + 1; }
  return n;
}

// Is this line the HEADER row? The header's FIRST field is "case_id".
// The check is on the first field alone, because the header row has
// further tab-separated columns after it.
static I64 IsHeaderRow(U8 *line) {
  I64 j = 0;
  while (line[j] == ' ' || line[j] == '\t') j++;
  I64 k = j;
  while (line[k] != 0 && line[k] != '\t') k++;
  if (k - j != 7) return 0;
  I64 m = 0;
  while (m < 7) {
    if (line[j + m] != "case_id"[m]) return 0;
    m++;
  }
  return 1;
}

// Load a TSV file into FLD/NROW. Comment lines (starting with #) and
// blank lines are skipped. The HEADER row is skipped too: it names the
// columns, it is not a case.
static I64 Load(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  NROW = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    if (buf[i] == 10) {
      // The newline is TERMINATED and NOT restored. The last field of
      // the row must end at a NUL: if the newline byte were put back,
      // that field would run into the separator and the next row's
      // first byte, and the tool would read one row's text as the
      // next row's field.
      buf[i] = 0;
      if (*line != 0 && *line != '#') {
        if (IsHeaderRow(line) == 1) {
          // the header row
        } else {
          NCNT[NROW] = SplitTabs(line, NROW * NCOL, NCOL);
          NROW++;
        }
      }
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size && *line != 0 && *line != '#') {
    if (IsHeaderRow(line) == 0) {
      NCNT[NROW] = SplitTabs(line, NROW * NCOL, NCOL);
      NROW++;
    }
  }
  return NROW;
}

// The TRANSCRIPT FORMAT.
//
//   case_id <TAB> selected_status <TAB> expected_exit <TAB> observed_exit
//              <TAB> expected_diagnostic_token <TAB> observed_stderr
//
// The observed stderr is the FULL stderr of the real invocation. The
// expected diagnostic is checked by TOKEN, because the diagnostics
// carry the offending argument names, which vary per case. The token
// is the part that identifies WHICH diagnostic was reported.
//
// The frozen tokens:
//   TO_STDOUT   "`-o-` can only be used in conjunction with `-S`"
//   USAGE       "Unknown commandline options"
//   ARITY       "Unexpected end of input"
//   NONE        the empty string: no diagnostic at all
//
#define TOKEN_TO_STDOUT "`-o-` can only be used in conjunction with `-S`"
#define TOKEN_USAGE     "Unknown commandline options"
#define TOKEN_ARITY     "Unexpected end of input"

// The field at index `f` of row `r`. A field the row did not carry is
// the EMPTY string.
static U8 *FieldAt(I64 r, I64 f) {
  if (f >= NCNT[r]) return EMPTY_FIELD_BUF;
  return FLD[r * NCOL + f];
}

// Is this observed stderr the EMPTY marker? The harness writes the
// marker EMPTY_STDERR when the invocation produced no stderr at all,
// so that an empty trailing field never has to be carried by the TSV
// format. The marker is a transcript artefact, not a diagnostic.
static I64 IsEmptyMarker(U8 *s) {
  if (StrEq(s, "EMPTY_STDERR") == 1) return 1;
  return 0;
}

// Check one transcript row against the FROZEN expectation.
static U0 CheckRow(I64 r) {
  U8 *case_id = FieldAt(r, 0);
  U8 *status = FieldAt(r, 1);
  U8 *want_exit = FieldAt(r, 2);
  U8 *got_exit = FieldAt(r, 3);
  U8 *want_tok = FieldAt(r, 4);
  U8 *got_err = FieldAt(r, 5);

  // The exit status must match exactly.
  if (StrEq(want_exit, got_exit) != 1) {
    FailOne("PRECEDENCE_EXIT_STATUS_MISMATCH", case_id, r);
    return;
  }

  // The reported diagnostic must be the one the PolyC-selected status
  // names. The empty expectation means NO diagnostic at all.
  if (StrLenOf(want_tok) == 0) {
    // No diagnostic is expected. The observed stderr must be empty,
    // which the harness records as the EMPTY marker.
    if (IsEmptyMarker(got_err) == 0) {
      FailPlain("PRECEDENCE_UNEXPECTED_DIAGNOSTIC", case_id);
    }
    return;
  }
  if (Has(got_err, want_tok) != 1) {
    FailPlain("PRECEDENCE_DIAGNOSTIC_MISMATCH", case_id);
    return;
  }
  // The observed diagnostic must ALSO be the one the PolyC-selected
  // status names. This is the anti-preemption check: the transcript
  // carries the status the driver selected, and the diagnostic must
  // agree with it.
  if (StrEq(status, "TO_STDOUT") == 1) {
    if (Has(got_err, TOKEN_TO_STDOUT) != 1) {
      FailPlain("PRECEDENCE_STATUS_DISAGREES_WITH_DIAGNOSTIC", case_id);
      return;
    }
  }
  if (StrEq(status, "USAGE") == 1) {
    if (Has(got_err, TOKEN_USAGE) != 1) {
      FailPlain("PRECEDENCE_STATUS_DISAGREES_WITH_DIAGNOSTIC", case_id);
      return;
    }
  }
  if (StrEq(status, "ARITY") == 1) {
    if (Has(got_err, TOKEN_ARITY) != 1) {
      FailPlain("PRECEDENCE_STATUS_DISAGREES_WITH_DIAGNOSTIC", case_id);
      return;
    }
  }
}

I32 Main(I32 argc, U8 **argv) {
  // The EMPTY buffer is set explicitly, not relied upon to be
  // zero-initialised by the compiler's file-scope handling.
  EMPTY_FIELD_BUF[0] = 0;
  if (argc < 2) {
    "REASON_DETAIL=usage: <transcript.tsv>\n";
    return 2;
  }
  if (Load(argv[1]) < 0) {
    FailPlain("PRECEDENCE_TRANSCRIPT_UNREADABLE", argv[1]);
    return 1;
  }
  if (NROW == 0) {
    FailPlain("PRECEDENCE_TRANSCRIPT_EMPTY", argv[1]);
    return 1;
  }
  I64 i = 0;
  while (i < NROW) { CheckRow(i); i = i + 1; }

  if (failures > 0) {
    "DRIVER_WP001_PRECEDENCE_TEST_CASES=%d\n", NROW;
    "DRIVER_WP001_PRECEDENCE_TEST_FAILURES=%d\n", failures;
    "DRIVER_WP001_PRECEDENCE_TEST_STATUS=FAIL\n";
    return 1;
  }
  "DRIVER_WP001_PRECEDENCE_TEST_CASES=%d\n", NROW;
  "DRIVER_WP001_PRECEDENCE_TEST_FAILURES=0\n";
  "DRIVER_WP001_PRECEDENCE_TEST_STATUS=PASS\n";
  return 0;
}
