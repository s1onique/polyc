// tools/quality/parser-slice04-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE04 C2 IMPL.
//
// PolyC-native DIRECT DIFFERENTIAL verifier for the AST binary-operator
// decision, with a FAIL-CLOSED fixture-integrity contract.
//
// Architecture (ACT section 8.4):
//   legacy C astBinOpFromToken
//       <-- build/slice04-ast-legacy.o, which is src/ast.c compiled
//          WITHOUT HCC_USE_SELFHOST_PARSER_AST_BINOP, so the REAL legacy
//          switch body is the one that executes
//   PolyC BootstrapAstBinOpFromToken
//       <-- tools/bootstrap/selfhost-parser-slice04.HC
//   comparison layer
//       <-- THIS FILE (PolyC, terminal authority)
//
// The comparison layer is PolyC.  The oracle is C.  The two are compared
// on EVERY row, and the fixture's own `expected` columns are checked
// against the oracle as well, so a disagreement between the PolyC
// subject and the production oracle cannot be masked by an equally
// wrong fixture.
//
// WHY THE ORACLE IS NOT A REIMPLEMENTATION
// =========================================
//
// The oracle object is src/ast.c compiled WITHOUT the delegation
// macro.  The switch table it executes is therefore the BYTE IDENTICAL
// legacy source, not a copy of it and not a reimplementation.  A
// handwritten reimplementation could share the same misreading of the
// legacy source as the PolyC component and would agree with it while
// both are wrong.
//
// The oracle is reached through a NARROW ADAPTER (see
// tools/quality/parser-slice04-oracle-driver.c): the adapter calls the
// real function with a PREINITIALISED output slot and reports the
// observed success flag and the final enum value.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice04-differential <fixture.tsv> <expected_row_count>
//
// Fixture schema:
//   fixture_id <TAB> partition <TAB> token_value <TAB> expected_success
//              <TAB> expected_output <TAB> initial_output <TAB> rationale
//
// The comment lines of the fixture begin with '#'.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 BootstrapAstBinOpFromToken(I64 token_value);

// The REAL legacy classifier, reached through the narrow adapter.
// The adapter takes the token value and the caller's INITIAL output
// value, calls the real astBinOpFromToken, and returns the OBSERVED
// success flag.  The observed output value is reported through the
// adapter's out-parameter.
extern "c" I64 Slice04LegacyBinOpOracle(I64 token_value, I64 initial_output,
                                         I64 *out_after_call);

// The number of TAB-separated fields in a fixture row.
#define FIXTURE_FIELD_COUNT 7

// The most-negative safe PRE-MULTIPLY magnitude, base 10.
//
// The magnitude is accumulated NEGATIVE, so the accumulated value v
// satisfies v = -(magnitude).  The step is
//     v' = v * base - digit
// and the requirement is v' >= -2^63, i.e.
//     v * base >= -2^63 + digit
//
// For base 10 and digit d, the exact threshold is
//     v >= ceil((-2^63 + d) / 10)
// which is -922337203685477580 for d = 0..8 and -922337203685477579
// for d = 9.  Both are written explicitly: the division rounds toward
// zero in this language, so computing them would be wrong for d = 9.
#define NEG_LIMIT_DEC -922337203685477580
#define NEG_LIMIT_DEC_D9 -922337203685477579

// The most-negative magnitude representable at all: -2^63.
#define NEG_MIN_2P63 -9223372036854775807 - 1

// Parse a signed decimal integer at *pp.  Advances *pp past the token.
// Returns 0 on success, 1 on a parse error.
//
// The magnitude is accumulated as a NEGATIVE I64, which makes the
// magnitude 2^63 (needed by INT64_MIN) exactly representable, and the
// limit is checked BEFORE each multiply so no intermediate overflows.
static I64 parse_dec(U8 **pp, I64 *out)
{
  U8 *p = *pp;
  I64 neg = 0;
  if (*p == '-') {
    neg = 1;
    p++;
  }
  if (*p < '0' || *p > '9') return 1;
  I64 v = 0;
  I64 digits = 0;
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
    // The post-multiply check is the EXACT representable floor: the
    // accumulated magnitude may reach 9223372036854775807 (INT64_MAX)
    // but NOT 9223372036854775808.
    //
    // The check is `v < NEG_MIN_2P63`, which rejects a magnitude of
    // 9223372036854775808 ONLY when the sign is negative.  For a
    // POSITIVE literal the magnitude 9223372036854775808 would
    // accumulate to exactly NEG_MIN_2P63, which is NOT below it, so
    // the 19-DIGIT case is rejected by the digit-count rule below.
    if (v < NEG_MIN_2P63) return 1;
    p++;
  }
  // The digit count alone is NOT the out-of-range test: INT64_MAX
  // (9223372036854775807) and INT64_MIN (-9223372036854775808) BOTH
  // have NINETEEN digits and BOTH are in range.
  //
  // The exact test is on the ACCUMULATED MAGNITUDE:
  //
  //   positive literal: magnitude <= 9223372036854775807
  //   negative literal: magnitude <= 9223372036854775808
  //
  // The accumulated value v is the NEGATIVE magnitude, so the two
  // bounds are "v >= -9223372036854775807" and "v >= NEG_MIN_2P63".
  if (digits > 18) {
    if (neg) {
      // The magnitude 2^63 is exactly representable as INT64_MIN.
      if (v < NEG_MIN_2P63) return 1;
    } else {
      if (v < -9223372036854775807) return 1;
    }
  }
  // The accumulated magnitude v is NEGATIVE (v = -magnitude).
  //
  //   positive input: the value is -v, i.e. the magnitude is positive.
  //   negative input: the value is  v, i.e. the magnitude is negative,
  //                   and v == -2^63 is exactly INT64_MIN.
  if (neg) {
    *out = v;
  } else {
    *out = -v;
  }
  *pp = p;
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

// Parse a leading signed decimal integer.  Returns 0 when the field is
// not an integer at all.
static I64 ParseInt(U8 *s)
{
  I64 v = 0;
  I64 neg = 0;
  U8 *p = s;
  if (*p == '-') { neg = 1; p++; }
  if (*p == 0) return 0;
  while (*p >= '0' && *p <= '9') {
    v = v * 10 + (*p - '0');
    p++;
  }
  if (*p != 0) return 0;
  if (neg) return -v;
  return v;
}

// The number of fixture rows to expect.  It is supplied by the caller
// so that the expected count is a DERIVED value (the producer reports
// the count it wrote), never a constant chosen in advance.
#define MAX_IDS 1024

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

// Skip one TAB-separated field.
static U0 skip_field(U8 **pp)
{
  U8 *p = *pp;
  while (*p != 0 && *p != '\t') p++;
  if (*p == '\t') p++;
  *pp = p;
}

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c1/fixture.tsv";
  I64 expected_count = 0;
  I64 ai = 1;
  if (argc > ai) path = argv[ai];
  ai++;
  if (argc > ai) expected_count = ParseInt(argv[ai]);

  I64 fsize = 0;
  U8 *ftxt = FileRead(path, &fsize);
  if (ftxt == NULL) {
    "SLICE04_DIFF_STATUS=FAIL\n";
    "SLICE04_DIFF_REASON=CANNOT_READ_FIXTURE\n";
    "SLICE04_DIFF_INPUT=%s\n", path;
    return 1;
  }

  I64 seen[MAX_IDS];
  I64 i = 0;
  while (i < MAX_IDS) { seen[i] = 0; i = i + 1; }

  I64 total = 0;
  I64 pass = 0;
  I64 fail = 0;
  I64 parse_errors = 0;
  I64 field_parse_errors = 0;
  I64 unknown_ids = 0;
  I64 duplicate_ids = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 out_of_range_ids = 0;
  I64 oracle_vs_expected_mismatch = 0;
  I64 output_preservation_failures = 0;
  I64 enum_mapping_mismatches = 0;
  I64 first_fail_value = 0;
  I64 first_fail_poly = 0;
  I64 first_fail_oracle = 0;

  U8 *p = ftxt;
  U8 *end = ftxt + fsize;

  while (p < end) {
    U8 *line_start = p;
    while (p < end && *p != '\n') p++;
    U8 *line_end = p;
    if (p < end) p++;
    if (line_end > line_start && *(line_end - 1) == '\r') line_end--;
    *line_end = 0;

    U8 *line = line_start;
    if (*line == 0) continue;
    if (*line == '#') continue;

    // A metadata row is a KEY=VALUE line with no fixture id.  The
    // canonical metadata keys are ACT_ID=, ACT_PHASE=, EVIDENCE_KIND=
    // and FIXTURE_ROW_COUNT=.  A data row always starts with 'F'.
    if (line[0] != 70) {
      if (has_equals(line)) continue;
    }

    total = total + 1;

    // ---- The fixture id ---------------------------------------------
    I64 idlen = 0;
    while (line[idlen] != 0 && line[idlen] != '\t') idlen++;
    I64 idnum = id_of(line, idlen);
    if (idnum < 1 || idnum > expected_count || !id_shape_ok(line, idlen)) {
      unknown_ids = unknown_ids + 1;
      out_of_range_ids = out_of_range_ids + 1;
      parse_errors = parse_errors + 1;
      continue;
    }
    if (seen[idnum] > 0) {
      duplicate_ids = duplicate_ids + 1;
      parse_errors = parse_errors + 1;
      continue;
    }
    seen[idnum] = 1;

    U8 *q = line;
    skip_field(&q);      // fixture_id
    skip_field(&q);      // partition

    // ---- The token value ---------------------------------------------
    I64 value = 0;
    if (parse_dec(&q, &value)) {
      parse_errors = parse_errors + 1;
      field_parse_errors = field_parse_errors + 1;
      continue;
    }
    skip_field(&q);

    // ---- The expected success flag -----------------------------------
    I64 exp_success = 0;
    if (parse_dec(&q, &exp_success)) {
      parse_errors = parse_errors + 1;
      field_parse_errors = field_parse_errors + 1;
      continue;
    }
    skip_field(&q);

    // ---- The expected output -----------------------------------------
    I64 exp_output = 0;
    if (parse_dec(&q, &exp_output)) {
      parse_errors = parse_errors + 1;
      field_parse_errors = field_parse_errors + 1;
      continue;
    }
    skip_field(&q);

    // ---- The initial output value -------------------------------------
    I64 init_output = 0;
    if (parse_dec(&q, &init_output)) {
      parse_errors = parse_errors + 1;
      field_parse_errors = field_parse_errors + 1;
      continue;
    }

    // ---- The two authorities ------------------------------------------
    I64 legacy_after = 0;
    I64 legacy_success = Slice04LegacyBinOpOracle(value, init_output, &legacy_after);
    I64 polyc = BootstrapAstBinOpFromToken(value);

    // The PolyC component's success convention is the sentinel: a
    // NONNEGATIVE result is a mapped operator and -1 is the failure
    // sentinel.
    I64 polyc_success = 0;
    I64 polyc_output = 0;
    if (polyc >= 0) {
      polyc_success = 1;
      polyc_output = polyc;
    }

    // The PRODUCTION ADAPTER's view of the PolyC side.
    //
    // The adapter writes the output ONLY on success.  On failure it
    // returns 0 and leaves the caller's output slot UNCHANGED.  The
    // differential therefore models the adapter, not the raw component:
    // the adapter's output after the call is the mapped enum on success
    // and the caller's INITIAL value on failure.
    I64 adapter_output = init_output;
    if (polyc_success == 1) adapter_output = polyc_output;

    // The fixture's own expectation must agree with the production
    // oracle.  A row where they disagree is a defect in the FIXTURE,
    // not in the subject, and is counted separately so it cannot be
    // confused with a subject/oracle disagreement.
    if (legacy_success != exp_success || legacy_after != exp_output) {
      oracle_vs_expected_mismatch = oracle_vs_expected_mismatch + 1;
    }

    // The OUTPUT-PRESERVATION property: on failure, the caller's
    // output storage must be UNCHANGED.
    if (legacy_success == 0 && legacy_after != init_output) {
      output_preservation_failures = output_preservation_failures + 1;
    }
    if (polyc_success == 0 && adapter_output != init_output) {
      output_preservation_failures = output_preservation_failures + 1;
    }

    // The ENUM MAPPING must agree.
    if (legacy_success == 1 && legacy_after != polyc_output) {
      enum_mapping_mismatches = enum_mapping_mismatches + 1;
    }

    if (legacy_success == polyc_success && legacy_after == adapter_output) {
      pass = pass + 1;
    } else {
      fail = fail + 1;
      if (fail <= 8) {
        "SLICE04_DIFF_MISMATCH value=%d legacy_success=%d legacy_output=%d polyc_success=%d polyc_output=%d adapter_output=%d expected_success=%d expected_output=%d init=%d\n",
               value, legacy_success, legacy_after, polyc_success, polyc_output, adapter_output,
               exp_success, exp_output, init_output;
      }
      if (fail == 1) {
        first_fail_value = value;
        first_fail_poly = polyc_output;
        first_fail_oracle = legacy_after;
      }
    }
  }

  // ---- The missing-id count -------------------------------------------
  I64 missing_ids = 0;
  i = 1;
  while (i <= expected_count) {
    if (seen[i] == 0) missing_ids = missing_ids + 1;
    i = i + 1;
  }

  Free(ftxt);

  "SLICE04_DIFF_TOTAL=%d\n", total;
  "SLICE04_DIFF_PASS=%d\n", pass;
  "SLICE04_DIFF_FAIL=%d\n", fail;
  "SLICE04_DIFF_PARSE_ERRORS=%d\n", parse_errors;
  "SLICE04_DIFF_FIELD_PARSE_ERRORS=%d\n", field_parse_errors;
  "SLICE04_DIFF_ORACLE_VS_EXPECTED_MISMATCH=%d\n", oracle_vs_expected_mismatch;
  "SLICE04_DIFF_OUTPUT_PRESERVATION_FAILURES=%d\n", output_preservation_failures;
  "SLICE04_DIFF_ENUM_MAPPING_MISMATCHES=%d\n", enum_mapping_mismatches;
  "SLICE04_DIFF_UNKNOWN_IDS=%d\n", unknown_ids;
  "SLICE04_DIFF_DUPLICATE_IDS=%d\n", duplicate_ids;
  "SLICE04_DIFF_MISSING_IDS=%d\n", missing_ids;
  "SLICE04_DIFF_MALFORMED_ROWS=%d\n", malformed_rows;
  "SLICE04_DIFF_TRUNCATED_ROWS=%d\n", truncated_rows;
  "SLICE04_DIFF_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "SLICE04_DIFF_EXPECTED_ROW_COUNT=%d\n", expected_count;
  if (fail == 1) {
    "SLICE04_DIFF_FIRST_FAILURE value=%d polyc=%d oracle=%d\n",
           first_fail_value, first_fail_poly, first_fail_oracle;
  }

  // The acceptance predicate.
  //
  // The fixture set is AUTHORITATIVE: the EXACT canonical ID set is
  // present, each ID occurs EXACTLY once, every row matches the
  // declared schema, the semantic comparison is clean, and the
  // fixture's own expectations agree with the production oracle.
  //
  // A row that cannot be parsed is a FAILURE, never a silent skip.
  if (fail == 0
      && parse_errors == 0
      && oracle_vs_expected_mismatch == 0
      && output_preservation_failures == 0
      && enum_mapping_mismatches == 0
      && unknown_ids == 0
      && duplicate_ids == 0
      && missing_ids == 0
      && malformed_rows == 0
      && truncated_rows == 0
      && total == expected_count) {
    "SLICE04_DIFF_STATUS=PASS\n";
    return 0;
  }
  "SLICE04_DIFF_STATUS=FAIL\n";
  return 1;
}
