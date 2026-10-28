// tools/quality/parser-slice06-ac11-correction01-control-verifier.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06-AC11-CORRECTION01 C2.
//
// The independent AC11 control verifier.  It consumes a TSV whose rows
// are: control_id, subject_kind, legacy_result, poly_result.
// It reports ROW mismatches and, separately, DISTINCT SEMANTIC-KIND
// mismatches.  The frozen PD-01..PD-03 predicate is exactly one
// semantic-kind mismatch; the original full-fixture row count remains
// visible and is never redefined.
//
// It also consumes a fixture-like TSV and an explicit canonical ID count.
// Its UNKNOWN_ID detector counts IDs outside 1..expected_count.  This
// is the intended FC-03 detector, distinct from the invalid semantic
// value detector in the historical verifier.
//
// F-POLYC-TOOLS: PolyC implementation; no shell glue.
//
// Usage:
//   control-verifier semantic <control.tsv>
//   control-verifier unknown-id <fixture.tsv> <expected-count>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

#define MAX_ROWS 4096

static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a = a + 1;
    b = b + 1;
  }
  return *a == 0 && *b == 0;
}

static I64 ParseI64(U8 *s, I64 *out)
{
  I64 neg = 0;
  I64 v = 0;
  if (*s == '-') { neg = 1; s = s + 1; }
  if (*s == 0) return 0;
  while (*s >= '0' && *s <= '9') {
    v = v * 10 + (*s - '0');
    s = s + 1;
  }
  if (*s != 0) return 0;
  if (neg) v = -v;
  *out = v;
  return 1;
}

// Split a NUL-terminated line into at most maxf tab-separated fields.
// The line is modified in place.
static I64 SplitTabs(U8 *line, U8 *out[], I64 maxf)
{
  I64 n = 0;
  U8 *p = line;
  while (n < maxf) {
    out[n] = p;
    n = n + 1;
    while (*p != 0 && *p != 9) p = p + 1;
    if (*p == 0) break;
    *p = 0;
    p = p + 1;
  }
  return n;
}

static I64 ModeSemantic(U8 *path)
{
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) {
    "AC11_CONTROL_STATUS=FAIL\nAC11_CONTROL_REASON=CANNOT_READ\n";
    return 1;
  }

  I64 row_mismatches = 0;
  I64 kinds[256];
  I64 kind_n = 0;
  I64 rows = 0;
  U8 *p = buf;
  U8 *end = buf + sz;
  while (p < end) {
    U8 *eol = p;
    while (eol < end && *eol != 10) eol = eol + 1;
    I64 llen = eol - p;
    if (llen > 0 && *p != '#') {
      U8 *line = MAlloc(llen + 1);
      MemCpy(line, p, llen);
      line[llen] = 0;
      U8 *f[8];
      I64 n = SplitTabs(line, f, 8);
      if (n >= 4) {
        I64 legacy = 0;
        I64 poly = 0;
        I64 kind = 0;
        I64 kind_ok = ParseI64(f[1], &kind);
        I64 legacy_ok = ParseI64(f[2], &legacy);
        I64 poly_ok = ParseI64(f[3], &poly);
        if (kind_ok == 1 && legacy_ok == 1 && poly_ok == 1) {
          rows = rows + 1;
          if (legacy != poly) {
            row_mismatches = row_mismatches + 1;
            I64 found = 0;
            for (I64 i = 0; i < kind_n; i = i + 1) if (kinds[i] == kind) found = 1;
            if (found == 0 && kind_n < 256) { kinds[kind_n] = kind; kind_n = kind_n + 1; }
          }
        } else if (f[0][0] >= '0' && f[0][0] <= '9') {
          "AC11_CONTROL_PARSE_ERRORS=%d\n", 1;
          return 1;
        }
      }
      Free(line);
    }
    p = eol + 1;
  }

  "AC11_CONTROL_ROWS=%d\n", rows;
  "AC11_CONTROL_ROW_MISMATCHES=%d\n", row_mismatches;
  "AC11_CONTROL_SEMANTIC_KIND_MISMATCHES=%d\n", kind_n;
  if (kind_n == 1) {
    "AC11_CONTROL_SEMANTIC_KIND=%d\n", kinds[0];
    "AC11_CONTROL_STATUS=PASS\n";
    return 0;
  }
  "AC11_CONTROL_STATUS=FAIL\n";
  return 1;
}

static I64 ModeUnknownId(U8 *path, I64 expected_count)
{
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) {
    "AC11_UNKNOWN_ID_STATUS=FAIL\nAC11_UNKNOWN_ID_REASON=CANNOT_READ\n";
    return 1;
  }

  I64 rows = 0;
  I64 unknown_ids = 0;
  I64 duplicate_ids = 0;
  I64 missing_ids = 0;
  I64 ids[4096];
  I64 seen_n = 0;
  U8 *p = buf;
  U8 *end = buf + sz;
  while (p < end) {
    U8 *eol = p;
    while (eol < end && *eol != 10) eol = eol + 1;
    I64 llen = eol - p;
    if (llen > 0 && *p != '#') {
      U8 *line = MAlloc(llen + 1);
      MemCpy(line, p, llen);
      line[llen] = 0;
      U8 *f[8];
      I64 n = SplitTabs(line, f, 8);
      if (n >= 1 && f[0][0] >= '0' && f[0][0] <= '9') {
        I64 id = 0;
        if (ParseI64(f[0], &id) == 1) {
          rows = rows + 1;
          if (id < 1 || id > expected_count) unknown_ids = unknown_ids + 1;
          for (I64 i = 0; i < seen_n; i = i + 1) if (ids[i] == id) duplicate_ids = duplicate_ids + 1;
          if (seen_n < 4096) { ids[seen_n] = id; seen_n = seen_n + 1; }
        } else {
          "AC11_UNKNOWN_ID_PARSE_ERRORS=1\n";
          return 1;
        }
      }
      Free(line);
    }
    p = eol + 1;
  }

  for (I64 id = 1; id <= expected_count; id = id + 1) {
    I64 found = 0;
    for (I64 i = 0; i < seen_n; i = i + 1) if (ids[i] == id) found = 1;
    if (found == 0) missing_ids = missing_ids + 1;
  }

  "AC11_UNKNOWN_ID_ROWS=%d\n", rows;
  "AC11_UNKNOWN_ID_UNKNOWN_IDS=%d\n", unknown_ids;
  "AC11_UNKNOWN_ID_DUPLICATE_IDS=%d\n", duplicate_ids;
  "AC11_UNKNOWN_ID_MISSING_IDS=%d\n", missing_ids;
  if (unknown_ids == 1 && duplicate_ids == 0 && missing_ids == 0) {
    "AC11_UNKNOWN_ID_STATUS=PASS\n";
    return 0;
  }
  "AC11_UNKNOWN_ID_STATUS=FAIL\n";
  return 1;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc >= 3 && StrEq(argv[1], "semantic") == 1) return ModeSemantic(argv[2]);
  if (argc >= 4 && StrEq(argv[1], "unknown-id") == 1) {
    I64 expected = 0;
    if (ParseI64(argv[3], &expected) == 0) {
      "AC11_UNKNOWN_ID_STATUS=FAIL\nAC11_UNKNOWN_ID_REASON=BAD_EXPECTED_COUNT\n";
      return 1;
    }
    return ModeUnknownId(argv[2], expected);
  }
  "usage: control-verifier semantic <control.tsv>\n";
  "usage: control-verifier unknown-id <fixture.tsv> <expected-count>\n";
  return 2;
}
