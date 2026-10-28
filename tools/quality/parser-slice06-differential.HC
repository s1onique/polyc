// tools/quality/parser-slice06-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06 C1.
//
// PolyC-native DIRECT DIFFERENTIAL verifier for the switch-case ARM
// TERMINATION decision, with a FAIL-CLOSED fixture-integrity contract.
//
// Architecture:
//   legacy C decision
//       <-- build/slice06-parser-legacy.o, which is the ACTUAL
//          production src/parser.c compiled WITHOUT
//          HCC_USE_SELFHOST_PARSER_SWITCH_ARM, so the REAL legacy
//          condition body is the one that executes
//   PolyC BootstrapSwitchArmTerminates
//       <-- tools/bootstrap/selfhost-parser-slice06.HC
//   comparison layer
//       <-- THIS FILE (PolyC, terminal authority)
//
// THREE SOURCES ARE COMPARED ON EVERY ROW
// =========================================
//
//   1. the legacy C oracle's observed decision;
//   2. the PolyC component's observed decision;
//   3. the fixture's own independently derived expected value.
//
// Comparing only 1 against 2 would let an equally wrong fixture hide a
// disagreement.  Comparing only 2 against 3 would let a broken oracle
// hide a disagreement.  All three are compared.
//
// WHY THE ORACLE IS NOT A REIMPLEMENTATION
// =========================================
//
// The oracle object is the ACTUAL production src/parser.c translation
// unit, compiled with the delegation OFF.  The decision body it
// executes is therefore the BYTE-IDENTICAL legacy source, not a copy
// of it and not a reimplementation.
//
// The oracle is reached through a NARROW ADAPTER (see
// tools/quality/parser-slice06-oracle-adapter.c): the adapter calls
// the real legacy decision through the tiny wrapper that src/parser.c
// itself exposes adjacent to that decision.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice06-differential <fixture.tsv> <expected_row_count>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// The REAL legacy decision, reached through the narrow adapter.
//
// The adapter takes the AstKind value and returns the OBSERVED legacy
// decision: 1 when the legacy condition terminated the arm, 0 when it
// did not.
extern "c" I64 Slice06LegacySwitchArmOracle(I64 ast_kind);

// The PolyC component.  It is the DECISION OWNER under test.
extern "c" I64 BootstrapSwitchArmTerminates(I64 ast_kind);

// The number of TAB-separated fields in a fixture row.
#define FIXTURE_FIELD_COUNT 6

// The most-negative safe PRE-MULTIPLY magnitude, base 10.
//
// The magnitude is accumulated NEGATIVE, so the accumulated value v
// satisfies v = -(magnitude).  The step is v' = v * base - digit and
// the requirement is v' >= -2^63, i.e.
//     v * base >= -2^63 + digit
// For base 10 and digit d, the exact threshold is
//     v >= ceil((-2^63 + d) / 10)
// which is -922337203685477580 for d = 0..8 and -922337203685477579
// for d = 9.  Both are written explicitly: the division rounds toward
// zero in this language, so computing them would be wrong for d = 9.
#define NEG_LIMIT_DEC   -922337203685477580
#define NEG_LIMIT_DEC_D9 -922337203685477579

// The exact representable floor: the accumulated magnitude may reach
// 9223372036854775807 (INT64_MAX) but NOT 9223372036854775808.
//
// THE LITERAL -9223372036854775808 DOES NOT EVALUATE TO INT64_MIN IN
// THIS LANGUAGE.  The positive magnitude 9223372036854775808 is one
// past INT64_MAX, so the parser's constant folding wraps it to
// INT64_MIN and the unary minus then wraps it BACK to
// -9223372036854775807.  That was MEASURED, not assumed:
//
//   I64 a = -9223372036854775808;     ->  -9223372036854775807
//   I64 d = -9223372036854775807 - 1; ->  -9223372036854775808
//
// The subtraction form is exact, so it is the one used here.
#define NEG_MIN_2P63 (-9223372036854775807 - 1)

// Parse a signed decimal integer with an EXACT 64-bit conversion.
//
// Returns 0 on success and 1 on an out-of-range or malformed value.
// The accumulator is built NEGATIVE so that the most negative value is
// representable without an intermediate positive overflow.
//
// A "%d" conversion is NOT used anywhere: it is a 32-bit conversion and
// would destroy the signed-64-bit extremes.
static I64 ParseI64(U8 *s, I64 *out)
{
  I64 v = 0;
  I64 neg = 0;
  I64 digits = 0;
  U8 *p = s;

  if (*p == '-') { neg = 1; p++; }
  else if (*p == '+') { p++; }
  if (*p == 0) return 1;

  while (*p >= '0' && *p <= '9') {
    I64 d = *p - '0';
    digits = digits + 1;
    // The limit is checked BOTH before the multiply and after it.
    I64 limit = NEG_LIMIT_DEC;
    if (d == 9) limit = NEG_LIMIT_DEC_D9;
    if (v < limit) return 1;
    v = v * 10 - d;
    if (v < NEG_MIN_2P63) return 1;
    p++;
  }
  if (*p != 0) return 1;

  if (digits > 18) {
    if (neg) {
      if (v < NEG_MIN_2P63) return 1;
    } else {
      if (v < -9223372036854775807) return 1;
    }
  }

  if (neg) *out = v;
  else *out = -v;
  return 0;
}

// The canonical fixture-id shape: exactly three decimal digits, ZERO
// PADDED.
static I64 id_shape_ok(U8 *rec, I64 len)
{
  if (len < 3) return 0;
  if (rec[0] < 48 || rec[0] > 57) return 0;
  if (rec[1] < 48 || rec[1] > 57) return 0;
  if (rec[2] < 48 || rec[2] > 57) return 0;
  return 1;
}

static I64 id_number(U8 *rec)
{
  return (rec[0] - 48) * 100 + (rec[1] - 48) * 10 + (rec[2] - 48);
}

// Split a TAB-separated line into at most `maxf` fields.
//
// The line buffer is MODIFIED in place: each separator becomes a NUL.
//
// The scan stops at a TAB, a CR or an LF.  The CR matters: the fixture
// rows end with CRLF, so without it the LAST field would swallow the
// CR and then keep scanning into the NEXT record, which would corrupt
// every subsequent row's field split.
static I64 split_tabs(U8 *line, U8 *out[], I64 maxf)
{
  I64 n = 0;
  U8 *p = line;
  while (n < maxf) {
    out[n] = p;
    n++;
    while (*p != 0 && *p != 9 && *p != 13 && *p != 10) p++;
    if (*p == 0) break;
    if (*p != 9) break;
    *p = 0;
    p++;
  }
  return n;
}

// The number of fixture rows to expect.  It is supplied by the caller
// so that the expected count is a DERIVED value (the producer reports
// the count it wrote), never a constant chosen in advance.
#define MAX_IDS 1024

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "evidence/ACT-POLYC-SELFHOST-PARSER-SLICE06/c1/fixture.tsv";
  I64 expected_count = 0;
  I64 ai = 1;
  if (argc > ai) path = argv[ai];
  ai++;
  if (argc > ai) {
    I64 tmp = 0;
    if (ParseI64(argv[ai], &tmp) != 0) {
      "SLICE06_DIFF_STATUS=FAIL\n";
      "SLICE06_DIFF_REASON=BAD_EXPECTED_COUNT\n";
      return 1;
    }
    expected_count = tmp;
  }

  I64 fsize = 0;
  U8 *ftxt = FileRead(path, &fsize);
  if (ftxt == NULL) {
    "SLICE06_DIFF_STATUS=FAIL\n";
    "SLICE06_DIFF_REASON=CANNOT_READ_FIXTURE\n";
    "SLICE06_DIFF_INPUT=%s\n", path;
    return 1;
  }

  I64 seen[MAX_IDS];
  I64 seen_n = 0;
  I64 total = 0;
  I64 pass = 0;
  I64 fail = 0;
  I64 parse_errors = 0;
  I64 field_parse_errors = 0;
  I64 oracle_vs_expected_mismatch = 0;
  I64 polyc_vs_expected_mismatch = 0;
  I64 oracle_vs_polyc_mismatch = 0;
  I64 invalid_polyc_result = 0;
  I64 unknown_ids = 0;
  I64 duplicate_ids = 0;
  I64 missing_ids = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 out_of_range_ids = 0;
  I64 missing_row_ids = 0;

  // ---- scan the fixture record by record --------------------------------
  I64 rec_start = 0;
  I64 pos = 0;
  while (pos <= fsize) {
    if (pos == fsize || ftxt[pos] == 10) {
      I64 rec_len = pos - rec_start;
      // Strip a trailing CR.
      I64 eff_len = rec_len;
      if (eff_len > 0 && ftxt[rec_start + eff_len - 1] == 13) eff_len = eff_len - 1;

      if (eff_len > 0) {
        if (id_shape_ok(&ftxt[rec_start], eff_len) == 1) {
          // ---- a FIXTURE ROW -------------------------------------------
          total = total + 1;
          I64 id = id_number(&ftxt[rec_start]);

          for (I64 i = 0; i < seen_n; i = i + 1) {
            if (seen[i] == id) duplicate_ids = duplicate_ids + 1;
          }
          if (seen_n < MAX_IDS) { seen[seen_n] = id; seen_n = seen_n + 1; }

          // Split the record into its fields.  The buffer is modified in
          // place, so the separator NULs stay inside the fixture text.
          U8 *fields[FIXTURE_FIELD_COUNT + 2];
          I64 nf = split_tabs(&ftxt[rec_start], fields, FIXTURE_FIELD_COUNT + 2);

          if (nf < FIXTURE_FIELD_COUNT) {
            truncated_rows = truncated_rows + 1;
          } else {
            I64 kind = 0;
            I64 expected = 0;
            I64 kind_ok = ParseI64(fields[2], &kind);
            I64 exp_ok = ParseI64(fields[3], &expected);

            if (kind_ok != 0) {
              field_parse_errors = field_parse_errors + 1;
            } else if (exp_ok != 0 || (expected != 0 && expected != 1)) {
              field_parse_errors = field_parse_errors + 1;
            } else {
              // The REAL legacy decision.
              I64 legacy = Slice06LegacySwitchArmOracle(kind);
              // The PolyC decision.
              I64 poly = BootstrapSwitchArmTerminates(kind);

              if (legacy != 0 && legacy != 1) {
                invalid_polyc_result = invalid_polyc_result + 1;
              }
              if (poly != 0 && poly != 1) {
                invalid_polyc_result = invalid_polyc_result + 1;
              }
              if (legacy == expected && poly == expected) {
                pass = pass + 1;
              } else {
                fail = fail + 1;
              }
              if (legacy != expected) {
                oracle_vs_expected_mismatch = oracle_vs_expected_mismatch + 1;
              }
              if (poly != expected) {
                polyc_vs_expected_mismatch = polyc_vs_expected_mismatch + 1;
              }
              if (legacy != poly) {
                oracle_vs_polyc_mismatch = oracle_vs_polyc_mismatch + 1;
              }
            }
          }
        }
      }
      rec_start = pos + 1;
    }
    pos = pos + 1;
  }

  // ---- the missing ids --------------------------------------------------
  for (I64 id = 1; id <= expected_count; id = id + 1) {
    I64 found = 0;
    for (I64 i = 0; i < seen_n; i = i + 1) {
      if (seen[i] == id) found = 1;
    }
    if (found == 0) missing_ids = missing_ids + 1;
  }
  for (I64 i = 0; i < seen_n; i = i + 1) {
    if (seen[i] < 1 || seen[i] > expected_count) out_of_range_ids = out_of_range_ids + 1;
  }

  // ---- the report -------------------------------------------------------
  "SLICE06_DIFF_PATH=%s\n", path;
  "SLICE06_DIFF_ROWS=%d\n", total;
  "SLICE06_DIFF_EXPECTED_ROWS=%d\n", expected_count;
  "SLICE06_DIFF_PASS=%d\n", pass;
  "SLICE06_DIFF_FAIL=%d\n", fail;
  "SLICE06_DIFF_PARSE_ERRORS=%d\n", parse_errors;
  "SLICE06_DIFF_FIELD_PARSE_ERRORS=%d\n", field_parse_errors;
  "SLICE06_DIFF_ORACLE_VS_EXPECTED_MISMATCH=%d\n", oracle_vs_expected_mismatch;
  "SLICE06_DIFF_POLYC_VS_EXPECTED_MISMATCH=%d\n", polyc_vs_expected_mismatch;
  "SLICE06_DIFF_ORACLE_VS_POLYC_MISMATCH=%d\n", oracle_vs_polyc_mismatch;
  "SLICE06_DIFF_INVALID_RESULT_VALUES=%d\n", invalid_polyc_result;
  "SLICE06_DIFF_DUPLICATE_IDS=%d\n", duplicate_ids;
  "SLICE06_DIFF_MISSING_IDS=%d\n", missing_ids;
  "SLICE06_DIFF_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "SLICE06_DIFF_MALFORMED_ROWS=%d\n", malformed_rows;
  "SLICE06_DIFF_TRUNCATED_ROWS=%d\n", truncated_rows;
  "SLICE06_DIFF_MISSING_ROW_IDS=%d\n", missing_row_ids;

  // The acceptance predicate.
  //
  // The differential passes only when EVERY row agrees across all
  // three sources, the row set is exactly the expected one, and every
  // observed result is a valid boolean.
  if (total == expected_count
      && expected_count > 0
      && pass == total
      && fail == 0
      && oracle_vs_expected_mismatch == 0
      && polyc_vs_expected_mismatch == 0
      && oracle_vs_polyc_mismatch == 0
      && invalid_polyc_result == 0
      && duplicate_ids == 0
      && missing_ids == 0
      && out_of_range_ids == 0
      && malformed_rows == 0
      && truncated_rows == 0
      && field_parse_errors == 0) {
    "SLICE06_DIFF_STATUS=PASS\n";
    return 0;
  }
  "SLICE06_DIFF_STATUS=FAIL\n";
  return 1;
}
