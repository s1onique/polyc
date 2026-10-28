// tools/quality/parser-slice05-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE05 C1.
//
// PolyC-native DIRECT DIFFERENTIAL verifier for the AST unary-operator
// decision, with a FAIL-CLOSED fixture-integrity contract.
//
// Architecture (ACT section 7.6):
//   legacy C astUnaryOpFromToken
//       <-- build/slice05-ast-legacy.o, which is src/ast.c compiled
//          WITHOUT HCC_USE_SELFHOST_PARSER_AST_UNARY, so the REAL legacy
//          switch body is the one that executes
//   PolyC BootstrapAstUnaryOpFromToken
//       <-- tools/bootstrap/selfhost-parser-slice05.HC
//   comparison layer
//       <-- THIS FILE (PolyC, terminal authority)
//
// THREE SOURCES ARE COMPARED ON EVERY ROW
// =========================================
//
//   1. the legacy C oracle's observed success flag and output;
//   2. the PolyC adapter's observed success flag and output;
//   3. the fixture's own independently frozen expected values.
//
// Comparing only 1 against 2 would let an equally wrong fixture hide a
// disagreement.  Comparing only 2 against 3 would let a broken oracle
// hide a disagreement.  All three are compared.
//
// WHY THE ORACLE IS NOT A REIMPLEMENTATION
// =========================================
//
// The oracle object is src/ast.c compiled WITHOUT the delegation macro.
// The switch table it executes is therefore the BYTE IDENTICAL legacy
// source, not a copy of it and not a reimplementation.  A handwritten
// reimplementation could share the same misreading of the legacy source
// as the PolyC component and would agree with it while both are wrong.
//
// The oracle is reached through a NARROW ADAPTER (see
// tools/quality/parser-slice05-oracle-driver.c): the adapter calls the
// real function with a PREINITIALISED output slot and reports the
// observed success flag and the final enum value.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice05-differential <fixture.tsv> <expected_row_count>
//
// Fixture schema:
//   fixture_id <TAB> partition <TAB> token_value <TAB> expected_success
//              <TAB> expected_output <TAB> initial_output <TAB> rationale
//
// The comment lines of the fixture begin with '#'.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// The REAL legacy classifier, reached through the narrow adapter.
//
// The adapter takes the token value and the caller's INITIAL output
// value, calls the real astUnaryOpFromToken, and returns the OBSERVED
// success flag.  The observed output value is reported through the
// adapter's out-parameter.
extern "c" I64 Slice05LegacyUnaryOpOracle(I64 token_value, I64 initial_output,
                                          I64 *out_after_call);

// The PolyC component.  It is the DECISION OWNER under test.
extern "c" I64 BootstrapAstUnaryOpFromToken(I64 token_value);

// The number of TAB-separated fields in a fixture row.
#define FIXTURE_FIELD_COUNT 7

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
// The subtraction form is exact, so it is the one used here.  Writing
// the literal directly would have made this verifier REJECT the
// legitimate INT64_MIN fixture row.
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
    //
    // The pre-multiply check alone is NOT sufficient: the magnitude
    // 9223372036854775808 has 19 digits, and after 18 digits the
    // accumulated magnitude is exactly 922337203685477580, which is
    // NOT below the pre-multiply limit, so the multiply would
    // overflow silently.
    I64 limit = NEG_LIMIT_DEC;
    if (d == 9) limit = NEG_LIMIT_DEC_D9;
    if (v < limit) return 1;
    v = v * 10 - d;
    // The post-multiply check is the EXACT representable floor.
    if (v < NEG_MIN_2P63) return 1;
    p++;
  }
  if (*p != 0) return 1;

  // The digit count alone is NOT the out-of-range test: INT64_MAX and
  // INT64_MIN BOTH have NINETEEN digits and BOTH are in range.
  if (digits > 18) {
    if (neg) {
      // The magnitude 2^63 is exactly representable as INT64_MIN.
      if (v < NEG_MIN_2P63) return 1;
    } else {
      if (v < -9223372036854775807) return 1;
    }
  }

  // The accumulated magnitude v is NEGATIVE (v = -magnitude).
  if (neg) *out = v;
  else *out = -v;
  return 0;
}

// Does the line contain an '=' character?  A metadata row is a
// KEY=VALUE line; a data row always starts with the fixture id 'F'.
static I64 has_equals(U8 *s)
{
  while (*s != 0) {
    if (*s == '=') return 1;
    s++;
  }
  return 0;
}

// The canonical fixture-id shape: a literal 'F' followed by exactly
// three decimal digits.
static I64 id_shape_ok(U8 *rec, I64 len)
{
  if (len < 4) return 0;
  if (rec[0] != 70) return 0;                 // 'F'
  if (rec[1] < 48 || rec[1] > 57) return 0;   // '0'..'9'
  if (rec[2] < 48 || rec[2] > 57) return 0;   // '0'..'9'
  if (rec[3] < 48 || rec[3] > 57) return 0;   // '0'..'9'
  return 1;
}

static I64 id_number(U8 *rec)
{
  return (rec[1] - 48) * 100 + (rec[2] - 48) * 10 + (rec[3] - 48);
}

// The numeric id of a record, or -1 when the shape is wrong.
static I64 id_of(U8 *rec, I64 len)
{
  if (!id_shape_ok(rec, len)) return -1;
  return id_number(rec);
}

// Split a TAB-separated line into at most `maxf` fields.
//
// The line buffer is MODIFIED in place: each separator becomes a NUL.
static I64 split_tabs(U8 *line, U8 *out[], I64 maxf)
{
  I64 n = 0;
  U8 *p = line;
  while (n < maxf) {
    out[n] = p;
    n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
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
  U8 *path = "evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c1/fixture.tsv";
  I64 expected_count = 0;
  I64 ai = 1;
  if (argc > ai) path = argv[ai];
  ai++;
  if (argc > ai) {
    I64 tmp = 0;
    if (ParseI64(argv[ai], &tmp) != 0) {
      "SLICE05_DIFF_STATUS=FAIL\n";
      "SLICE05_DIFF_REASON=BAD_EXPECTED_COUNT\n";
      return 1;
    }
    expected_count = tmp;
  }

  I64 fsize = 0;
  U8 *ftxt = FileRead(path, &fsize);
  if (ftxt == NULL) {
    "SLICE05_DIFF_STATUS=FAIL\n";
    "SLICE05_DIFF_REASON=CANNOT_READ_FIXTURE\n";
    "SLICE05_DIFF_INPUT=%s\n", path;
    return 1;
  }

  static I64 seen[MAX_IDS];
  I64 total = 0;
  I64 pass = 0;
  I64 fail = 0;
  I64 parse_errors = 0;
  I64 field_parse_errors = 0;
  I64 oracle_vs_expected_mismatch = 0;
  I64 polyc_vs_expected_mismatch = 0;
  I64 output_preservation_failures = 0;
  I64 enum_mapping_mismatches = 0;
  I64 unknown_ids = 0;
  I64 duplicate_ids = 0;
  I64 missing_ids = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 out_of_range_ids = 0;

  I64 first_fail_value = 0;
  I64 first_fail_poly = 0;
  I64 first_fail_oracle = 0;

  // ---- the per-record scan ---------------------------------------------
  //
  // The file is walked line by line.  A line that does not start with
  // the fixture-id shape is a NON-DATA line: it is accepted only when
  // it is a comment or a recognized metadata row.  An INDENTED unknown
  // row therefore does not disappear silently.
  I64 line_start = 0;
  I64 pos = 0;
  while (pos <= fsize) {
    I64 at_end = 0;
    if (pos == fsize) at_end = 1;
    else if (ftxt[pos] == '\n') at_end = 1;

    if (at_end == 1) {
      I64 len = pos - line_start;
      if (len > 0) {
        U8 *rec = ftxt + line_start;

        I64 is_data = 0;
        if (id_shape_ok(rec, len) == 1) {
          if (len == 4 || rec[4] == '\t') is_data = 1;
        }

        if (is_data == 0) {
          // A non-data line.
          if (rec[0] != '#' && has_equals(rec) == 0) {
            parse_errors = parse_errors + 1;
            "SLICE05_DIFF_PARSE_ERROR at byte %d\n", line_start;
          }
        } else {
          // ---- a FIXTURE ROW -------------------------------------------
          total = total + 1;
          I64 id = id_of(rec, len);

          // The record is NUL-TERMINATED in place before it is split,
          // so that the field splitter sees a C string rather than a
          // range that still contains the newline.
          rec[len] = 0;

          // The id must be in range and unique.
          if (id < 1 || id > expected_count) {
            out_of_range_ids = out_of_range_ids + 1;
            "SLICE05_DIFF_OUT_OF_RANGE_ID=%d\n", id;
          } else {
            I64 dup = 0;
            for (I64 i = 0; i < MAX_IDS; i++) {
              if (seen[i] == id) dup = 1;
            }
            if (dup == 1) {
              duplicate_ids = duplicate_ids + 1;
              "SLICE05_DIFF_DUPLICATE_ID=%d\n", id;
            } else if (id <= MAX_IDS) {
              seen[id] = 1;
            }
          }

          // ---- split the row into its fields ----------------------------
          U8 *f[FIXTURE_FIELD_COUNT + 1];
          I64 nf = split_tabs(rec, f, FIXTURE_FIELD_COUNT + 1);
          if (nf != FIXTURE_FIELD_COUNT) {
            if (nf < FIXTURE_FIELD_COUNT) truncated_rows = truncated_rows + 1;
            else malformed_rows = malformed_rows + 1;
            "SLICE05_DIFF_FIELD_COUNT id=%d fields=%d\n", id, nf;
          } else {
            I64 tok = 0;
            I64 succ = 0;
            I64 exp_out = 0;
            I64 init = 0;
            I64 bad = 0;
            if (ParseI64(f[2], &tok) != 0) bad = 1;
            if (ParseI64(f[3], &succ) != 0) bad = 1;
            if (ParseI64(f[4], &exp_out) != 0) bad = 1;
            if (ParseI64(f[5], &init) != 0) bad = 1;

            if (bad == 1) {
              field_parse_errors = field_parse_errors + 1;
              "SLICE05_DIFF_FIELD_PARSE_ERROR id=%d\n", id;
            } else {
              // ---- the THREE SOURCES ----------------------------------
              //
              // 1. the legacy C oracle.
              I64 oracle_out = 0;
              I64 oracle_ok = Slice05LegacyUnaryOpOracle(tok, init, &oracle_out);
              // 2. the PolyC component through the production adapter's
              //    contract: a negative mapped value is a failure and
              //    the output storage is NOT written.
              I64 mapped = BootstrapAstUnaryOpFromToken(tok);
              I64 poly_ok = 0;
              I64 poly_out = init;
              if (mapped >= 0) {
                poly_ok = 1;
                poly_out = mapped;
              }
              // 3. the fixture's own frozen expectations.
              I64 exp_ok = succ;
              I64 exp_after = exp_out;

              I64 row_bad = 0;

              // The oracle must agree with the frozen expectation.
              if (oracle_ok != exp_ok || oracle_out != exp_after) {
                oracle_vs_expected_mismatch = oracle_vs_expected_mismatch + 1;
                "SLICE05_DIFF_ORACLE_VS_EXPECTED id=%d token=%d oracle=(%d,%d) expected=(%d,%d)\n",
                      id, tok, oracle_ok, oracle_out, exp_ok, exp_after;
                row_bad = 1;
              }

              // The PolyC component must agree with the frozen
              // expectation.
              if (poly_ok != exp_ok || poly_out != exp_after) {
                polyc_vs_expected_mismatch = polyc_vs_expected_mismatch + 1;
                "SLICE05_DIFF_POLYC_VS_EXPECTED id=%d token=%d polyc=(%d,%d) expected=(%d,%d)\n",
                      id, tok, poly_ok, poly_out, exp_ok, exp_after;
                row_bad = 1;
              }

              // The PolyC component must agree with the legacy oracle.
              if (poly_ok != oracle_ok || poly_out != oracle_out) {
                enum_mapping_mismatches = enum_mapping_mismatches + 1;
                "SLICE05_DIFF_POLYC_VS_ORACLE id=%d token=%d polyc=(%d,%d) oracle=(%d,%d)\n",
                      id, tok, poly_ok, poly_out, oracle_ok, oracle_out;
                row_bad = 1;
              }

              // A FAILED lookup must leave the output storage
              // UNCHANGED.
              if (poly_ok == 0 && poly_out != init) {
                output_preservation_failures = output_preservation_failures + 1;
                "SLICE05_DIFF_OUTPUT_PRESERVATION id=%d token=%d init=%d after=%d\n",
                      id, tok, init, poly_out;
                row_bad = 1;
              }
              if (oracle_ok == 0 && oracle_out != init) {
                output_preservation_failures = output_preservation_failures + 1;
                "SLICE05_DIFF_ORACLE_OUTPUT_PRESERVATION id=%d token=%d init=%d after=%d\n",
                      id, tok, init, oracle_out;
                row_bad = 1;
              }

              if (row_bad == 0) {
                pass = pass + 1;
              } else {
                fail = fail + 1;
                if (first_fail_value == 0 && first_fail_poly == 0) {
                  first_fail_value = tok;
                  first_fail_poly = poly_out;
                  first_fail_oracle = oracle_out;
                }
              }
            }
          }
        }
      }
      line_start = pos + 1;
    }
    pos = pos + 1;
  }

  // ---- the missing ids ---------------------------------------------------
  for (I64 id = 1; id <= expected_count; id++) {
    if (seen[id] == 0) missing_ids = missing_ids + 1;
  }

  Free(ftxt);

  "SLICE05_DIFF_TOTAL=%d\n", total;
  "SLICE05_DIFF_PASS=%d\n", pass;
  "SLICE05_DIFF_FAIL=%d\n", fail;
  "SLICE05_DIFF_PARSE_ERRORS=%d\n", parse_errors;
  "SLICE05_DIFF_FIELD_PARSE_ERRORS=%d\n", field_parse_errors;
  "SLICE05_DIFF_ORACLE_VS_EXPECTED_MISMATCH=%d\n", oracle_vs_expected_mismatch;
  "SLICE05_DIFF_POLYC_VS_EXPECTED_MISMATCH=%d\n", polyc_vs_expected_mismatch;
  "SLICE05_DIFF_OUTPUT_PRESERVATION_FAILURES=%d\n", output_preservation_failures;
  "SLICE05_DIFF_ENUM_MAPPING_MISMATCHES=%d\n", enum_mapping_mismatches;
  "SLICE05_DIFF_UNKNOWN_IDS=%d\n", unknown_ids;
  "SLICE05_DIFF_DUPLICATE_IDS=%d\n", duplicate_ids;
  "SLICE05_DIFF_MISSING_IDS=%d\n", missing_ids;
  "SLICE05_DIFF_MALFORMED_ROWS=%d\n", malformed_rows;
  "SLICE05_DIFF_TRUNCATED_ROWS=%d\n", truncated_rows;
  "SLICE05_DIFF_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "SLICE05_DIFF_EXPECTED_ROW_COUNT=%d\n", expected_count;
  if (fail == 1) {
    "SLICE05_DIFF_FIRST_FAILURE value=%d polyc=%d oracle=%d\n",
           first_fail_value, first_fail_poly, first_fail_oracle;
  }

  // The acceptance predicate.
  //
  // The fixture set is AUTHORITATIVE: the EXACT canonical ID set is
  // present, each ID occurs EXACTLY once, every row matches the
  // declared schema, the three sources agree on every row, and the
  // output-preservation property holds on every failure.
  //
  // A row that cannot be parsed is a FAILURE, never a silent skip.
  if (fail == 0
      && parse_errors == 0
      && field_parse_errors == 0
      && oracle_vs_expected_mismatch == 0
      && polyc_vs_expected_mismatch == 0
      && output_preservation_failures == 0
      && enum_mapping_mismatches == 0
      && unknown_ids == 0
      && duplicate_ids == 0
      && missing_ids == 0
      && malformed_rows == 0
      && truncated_rows == 0
      && out_of_range_ids == 0
      && total == expected_count) {
    "SLICE05_DIFF_STATUS=PASS\n";
    return 0;
  }
  "SLICE05_DIFF_STATUS=FAIL\n";
  return 1;
}
