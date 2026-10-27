// tools/quality/parser-slice03-corr01-coverage.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01 C2 IMPL.
//
// THE INDEPENDENT SEMANTIC COVERAGE VERIFIER.
//
// It checks a fixture against the SEMANTIC contract, not against a row
// count.  A fixture with the right number of rows but the wrong values
// FAILS.
//
// WHY A SEPARATE TOOL
// ===================
//
// The producer (tools/quality/parser-slice03-corr01-fixture.HC) derives
// the precedence table from the live src/prslib.c by SCANNING ITS
// SOURCE TEXT for `case LABEL:` items.  This verifier does NOT do
// that.  It calls the REAL legacy-C oracle -- the actual
// parseGetPriority body, compiled without the delegation macro -- and
// uses the ORACLE'S OWN ANSWER as the authority for every value.
//
// The two paths are therefore independent:
//
//   the producer   reads the live source TEXT
//   the verifier   EXECUTES the live source CODE
//
// A defect that made the producer mis-read the source would therefore
// have to be reproduced in the C compiler to escape this verifier.
//
// The verifier ALSO derives the required P16 value set INDEPENDENTLY:
// it obtains the operator values by asking the ORACLE for a sweep, not
// by parsing the source.  The oracle's -1 answer marks a
// non-operator, so the set of operator values is discovered by
// EXECUTION rather than by reading.
//
// USAGE:
//   build/parser-slice03-corr01-coverage <fixture.tsv> <prslib.c> <lexer.h>
//
// It exits with RC=0 when every semantic predicate holds and RC=1
// otherwise.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tos.HH"

// The REAL legacy-C oracle: src/prslib.c compiled WITHOUT
// HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE, so the legacy
// parseGetPriority body is the one that executes.
extern "c" I64 ParserLegacyOperatorPrecedenceOracle(I64 punct_value);

#define LINE_CAP 8192
#define MAX_VALUES 4096
#define MAX_OBSERVED 4096

// The canonical corrected fixture count.
#define EXPECTED_FIXTURE_COUNT 123

// The number of TAB-separated fields in a fixture row.
#define FIXTURE_FIELD_COUNT 5

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
// for d = 9.
#define NEG_LIMIT_DEC -922337203685477580
#define NEG_LIMIT_DEC_D9 -922337203685477579

// The same for base 16.
#define NEG_LIMIT_HEX -576460752303423488
#define NEG_LIMIT_HEX_D1 -576460752303423487

// The most-negative magnitude representable at all: -2^63.
#define NEG_MIN_2P63 -9223372036854775807 - 1

// The four signed-I64 extremes, expressed as HEX literals so that they
// are exactly representable.
#define I64_MIN_HEX        0x8000000000000000
#define I64_MIN_PLUS1_HEX  0x8000000000000001
#define I64_MAX_MINUS1_HEX 0x7ffffffffffffffe
#define I64_MAX_HEX        0x7fffffffffffffff

// PolyC does not support a USER-DEFINED variadic function; only an

// ---------------------------------------------------------------------------
// The 64-BIT signed integer parser.
//
// The magnitude is accumulated as a NEGATIVE I64, which makes the
// magnitude 2^63 (needed by INT64_MIN) exactly representable, and the
// limit is checked BEFORE each multiply-add so that no intermediate
// value ever overflows.
//
// A value that does not fit the signed 64-bit range is REJECTED, not
// truncated: an overflowed input is a failure, never a silently
// wrapped value.
//
// Returns 0 on success, 1 on a parse error.
// ---------------------------------------------------------------------------
I64 parse_int(U8 **pp, I64 *out)
{
  U8 *p = *pp;
  I64 neg = 0;
  I64 v = 0;
  I64 base = 10;
  I64 digits = 0;
  I64 is_hex = 0;

  if (*p == '-') { neg = 1; p = p + 1; }
  else if (*p == '+') { p = p + 1; }

  if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
    base = 16;
    is_hex = 1;
    p = p + 2;
  }

  while (1) {
    I64 d = -1;
    if (is_hex) {
      if (*p >= '0' && *p <= '9') d = *p - '0';
      else if (*p >= 'a' && *p <= 'f') d = *p - 'a' + 10;
      else if (*p >= 'A' && *p <= 'F') d = *p - 'A' + 10;
    } else {
      if (*p >= '0' && *p <= '9') d = *p - '0';
    }
    if (d < 0) break;

    I64 thresh = 0;
    if (is_hex) {
      if (d == 0) thresh = NEG_LIMIT_HEX;
      else thresh = NEG_LIMIT_HEX_D1;
    } else {
      if (d == 9) thresh = NEG_LIMIT_DEC_D9;
      else thresh = NEG_LIMIT_DEC;
    }
    if (v < thresh) return 1;    // OUT OF RANGE

    v = v * base - d;
    p = p + 1;
    digits = digits + 1;
  }

  if (digits == 0) return 1;    // NO DIGITS
  if (*p != 0 && *p != '\t') return 1;    // TRAILING GARBAGE
  if (v < NEG_MIN_2P63) return 1;    // magnitude exceeds 2^63

  if (neg) {
    *out = v;
  } else {
    if (v == NEG_MIN_2P63) return 1;
    *out = 0 - v;
  }
  *pp = p;
  return 0;
}

// ---------------------------------------------------------------------------
// The OBSERVED fixture values.
//
// The verifier collects the values the fixture actually carries, so it
// can compare that SET against the REQUIRED set.
// ---------------------------------------------------------------------------
I64 g_observed[MAX_OBSERVED];
I64 g_observed_count;

I64 observed_has(I64 v)
{
  I64 i = 0;
  while (i < g_observed_count) {
    if (g_observed[i] == v) return 1;
    i = i + 1;
  }
  return 0;
}

I64 observed_add(I64 v)
{
  if (observed_has(v)) return 0;
  if (g_observed_count >= MAX_OBSERVED) return 1;
  g_observed[g_observed_count] = v;
  g_observed_count = g_observed_count + 1;
  return 1;
}

// ---------------------------------------------------------------------------
// The REQUIRED value set.
//
// It is built by EXECUTION, not by reading the source: the operator
// values are DISCOVERED by sweeping the oracle, and the oracle's -1
// answer marks a non-operator.
//
// The sweep covers every byte value that the legacy table can name:
// the ASCII punctuation region (0x00..0xFF) and the token-constant
// region (0x300..0x340), which is where TK_ARROW, TK_SHL, TK_EQU_EQU
// and the rest live.
//
// The discovered operator values are then augmented with their
// neighbours, the four signed-I64 extremes and the three base values.
// ---------------------------------------------------------------------------
I64 g_required[MAX_VALUES];
I64 g_required_count;

// The discovered operator values (the oracle's non-(-1) answers).
I64 g_ops[MAX_VALUES];
I64 g_op_count;

I64 required_has(I64 v)
{
  I64 i = 0;
  while (i < g_required_count) {
    if (g_required[i] == v) return 1;
    i = i + 1;
  }
  return 0;
}

I64 required_add(I64 v)
{
  if (required_has(v)) return 0;
  if (g_required_count >= MAX_VALUES) return 1;
  g_required[g_required_count] = v;
  g_required_count = g_required_count + 1;
  return 1;
}

I64 ops_has(I64 v)
{
  I64 i = 0;
  while (i < g_op_count) {
    if (g_ops[i] == v) return 1;
    i = i + 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// The values that the P16 rows actually carry.
//
// This is the COVERAGE side of the membership check: the required set
// must be covered EXACTLY by the P16 rows.
//
// p16_note records `v` if it has not been recorded yet, and returns 1
// when it was NEW.  p16_has reports whether it was already recorded.
// ---------------------------------------------------------------------------
I64 g_p16_seen[MAX_VALUES];
I64 g_p16_seen_count;

I64 p16_has(I64 v)
{
  I64 i = 0;
  while (i < g_p16_seen_count) {
    if (g_p16_seen[i] == v) return 1;
    i = i + 1;
  }
  return 0;
}

I64 p16_note(I64 v)
{
  if (p16_has(v)) return 0;
  if (g_p16_seen_count < MAX_VALUES) {
    g_p16_seen[g_p16_seen_count] = v;
    g_p16_seen_count = g_p16_seen_count + 1;
  }
  return 1;
}

// Discover the operator values by EXECUTING the oracle.
I64 discover_operators()
{
  g_op_count = 0;
  I64 v = 0;
  // The ASCII region.
  while (v <= 255) {
    if (ParserLegacyOperatorPrecedenceOracle(v) != -1) {
      if (!ops_has(v)) {
        if (g_op_count < MAX_VALUES) {
          g_ops[g_op_count] = v;
          g_op_count = g_op_count + 1;
        }
      }
    }
    v = v + 1;
  }
  // The token-constant region.
  v = 0x300;
  while (v <= 0x340) {
    if (ParserLegacyOperatorPrecedenceOracle(v) != -1) {
      if (!ops_has(v)) {
        if (g_op_count < MAX_VALUES) {
          g_ops[g_op_count] = v;
          g_op_count = g_op_count + 1;
        }
      }
    }
    v = v + 1;
  }
  return g_op_count;
}

// ---------------------------------------------------------------------------
// Field helpers.
// ---------------------------------------------------------------------------

I64 field_len(U8 *p)
{
  I64 n = 0;
  while (p[n] && p[n] != '\t') n = n + 1;
  return n;
}

I64 skip_field(U8 **pp)
{
  U8 *p = *pp;
  while (*p && *p != '\t') p = p + 1;
  if (*p == '\t') p = p + 1;
  *pp = p;
  return 0;
}

I64 memeq(U8 *a, U8 *b, I64 n)
{
  I64 i = 0;
  while (i < n) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// Is this line a RECOGNIZED non-data row that may be skipped?
//
// A line is skippable only when it is EXPLICITLY a comment (it begins
// with '#') or a KEY=VALUE metadata row (an '=' occurs in the FIRST
// field).  Every other line is a DATA row and MUST be validated.
//
// An INDENTED row is NOT recognized as a non-data row: that is the
// bypass class that ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
// reproduced, and an indented unknown row must reach the ledger rather
// than vanish.
I64 is_skippable_row(U8 *line, I64 linelen)
{
  if (linelen == 0) return 1;
  if (line[0] == '#') return 1;
  I64 i = 1;
  while (i < linelen && line[i] != '\t') {
    if (line[i] == '=') return 1;
    i = i + 1;
  }
  return 0;
}

// Is this the canonical id for the given index?
//
// The canonical id is F followed by three decimal digits that spell
// the index, ZERO PADDED.
I64 is_canonical_id(U8 *s, I64 n, I64 index)
{
  if (n != 4) return 0;
  if (s[0] != 'F') return 0;
  I64 hundreds = index / 100;
  I64 tens = (index / 10) % 10;
  I64 ones = index % 10;
  if (s[1] != '0' + hundreds) return 0;
  if (s[2] != '0' + tens) return 0;
  if (s[3] != '0' + ones) return 0;
  return 1;
}

// The partition id of a row, compared by its prefix.
I64 is_p16_partition(U8 *s, I64 n)
{
  // "P16_BOUNDARY_INTEGERS" is 21 bytes.
  if (n != 21) return 0;
  return memeq(s, "P16_BOUNDARY_INTEGERS", 21);
}

// Build the required set from the DISCOVERED operator values.
//
// The operator values were DISCOVERED by executing the oracle, so this
// set is derived from the live CODE, not from the live source text.
I64 build_required()
{
  g_required_count = 0;
  I64 i = 0;
  while (i < g_op_count) {
    required_add(g_ops[i] - 1);
    required_add(g_ops[i] + 1);
    i = i + 1;
  }
  // The four signed-I64 extremes.
  required_add(I64_MIN_HEX);
  required_add(I64_MIN_PLUS1_HEX);
  required_add(I64_MAX_MINUS1_HEX);
  required_add(I64_MAX_HEX);
  // The three base values.
  required_add(0);
  required_add(-1);
  required_add(1);
  return g_required_count;
}

I64 main(I64 argc, U8 **argv)
{
  if (argc != 4) {
    printf("CORR01_COVERAGE_USAGE: %s <fixture.tsv> <prslib.c> <lexer.h>\n", argv[0]);
    return 2;
  }

  // ---- The fixture ------------------------------------------------
  I64 fsz = 0;
  U8 *ftxt = FileRead(argv[1], &fsz);
  if (ftxt == 0) {
    printf("CORR01_COVERAGE_ERROR: cannot read %s\n", argv[1]);
    return 2;
  }

  // ---- The required set, derived by EXECUTION ----------------------
  //
  // The oracle's answers are the authority.  The producer's answers
  // are NOT consulted: the two paths are independent.
  I64 op_count = discover_operators();
  I64 req_count = build_required();
  printf("DISCOVERED_OPERATOR_VALUES=%d\n", op_count);
  printf("REQUIRED_VALUE_SET_SIZE=%d\n", req_count);

  if (op_count == 0) {
    printf("CORR01_COVERAGE_ERROR: the oracle reported no operator values\n");
    return 1;
  }

  // ---- The row scan -----------------------------------------------
  I64 total = 0;
  I64 parse_errors = 0;
  I64 field_parse_errors = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 unknown_ids = 0;
  I64 duplicate_ids = 0;
  I64 missing_ids = 0;
  I64 out_of_range_ids = 0;
  I64 oracle_vs_expected_mismatch = 0;
  I64 p16_rows = 0;
  I64 p16_value_errors = 0;
  I64 p16_expected_errors = 0;
  I64 p16_covered = 0;
  I64 first_fail_value = 0;
  I64 first_fail_expected = 0;
  I64 first_fail_oracle = 0;
  I64 have_first_fail = 0;

  I64 seen[EXPECTED_FIXTURE_COUNT + 1];
  I64 i = 0;
  while (i < EXPECTED_FIXTURE_COUNT + 1) {
    seen[i] = 0;
    i = i + 1;
  }

  g_observed_count = 0;

  I64 lineno = 0;
  while (lineno < fsz) {
    while (lineno < fsz && (ftxt[lineno] == 10 || ftxt[lineno] == 13)) lineno = lineno + 1;
    if (lineno >= fsz) break;

    U8 line[LINE_CAP];
    I64 j = 0;
    while (lineno < fsz && ftxt[lineno] != 10 && ftxt[lineno] != 13 && j < LINE_CAP - 1) {
      line[j] = ftxt[lineno];
      j = j + 1;
      lineno = lineno + 1;
    }
    line[j] = 0;
    I64 linelen = j;

    if (is_skippable_row(line, linelen)) continue;

    total = total + 1;

    // ---- The row must match the declared schema EXACTLY ----------
    I64 nfields = 0;
    I64 k = 0;
    while (k < linelen) {
      if (line[k] == 9) nfields = nfields + 1;
      k = k + 1;
    }
    nfields = nfields + 1;
    if (nfields != FIXTURE_FIELD_COUNT) {
      if (nfields < FIXTURE_FIELD_COUNT) truncated_rows = truncated_rows + 1;
      else malformed_rows = malformed_rows + 1;
      parse_errors = parse_errors + 1;
      continue;
    }

    // ---- The fixture id -------------------------------------------
    I64 idlen = field_len(line);
    I64 idnum = 0;
    if (idlen == 4) {
      idnum = (line[1] - 48) * 100 + (line[2] - 48) * 10 + (line[3] - 48);
    }
    if (idlen != 4 || idnum < 1 || idnum > EXPECTED_FIXTURE_COUNT
        || !is_canonical_id(line, idlen, idnum)) {
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

    // ---- The value and the expectation ----------------------------
    U8 *p = line;
    skip_field(&p);                       // fixture_id
    U8 *part = p;
    I64 partlen = field_len(p);
    skip_field(&p);                       // partition
    I64 value = 0;
    if (parse_int(&p, &value)) {
      parse_errors = parse_errors + 1;
      field_parse_errors = field_parse_errors + 1;
      continue;
    }
    skip_field(&p);
    I64 expected = 0;
    if (parse_int(&p, &expected)) {
      parse_errors = parse_errors + 1;
      field_parse_errors = field_parse_errors + 1;
      continue;
    }

    // ---- The ORACLE's answer is the authority --------------------
    I64 oc = ParserLegacyOperatorPrecedenceOracle(value);
    if (oc != expected) {
      oracle_vs_expected_mismatch = oracle_vs_expected_mismatch + 1;
      if (!have_first_fail) {
        have_first_fail = 1;
        first_fail_value = value;
        first_fail_expected = expected;
        first_fail_oracle = oc;
      }
    }

    // ---- The semantic membership checks ---------------------------
    //
    // A P16 row's value MUST be in the REQUIRED set.  The REQUIRED set
    // is covered EXACTLY by the P16 rows: every required value must
    // appear as a P16 row, and no P16 row may carry a value outside
    // the required set.
    //
    // A row in ANOTHER partition is NOT required to avoid the
    // required set: an operator value frequently IS the neighbour of
    // another operator, so the accept partitions legitimately carry
    // values that the required set also contains.  The coverage
    // direction that matters is checked below.
    observed_add(value);
    if (is_p16_partition(part, partlen)) {
      p16_rows = p16_rows + 1;
      if (!required_has(value)) p16_value_errors = p16_value_errors + 1;
      if (expected != oc) p16_expected_errors = p16_expected_errors + 1;
      if (p16_note(value)) p16_covered = p16_covered + 1;
    }
  }

  // ---- The missing-id count ---------------------------------------
  i = 1;
  while (i <= EXPECTED_FIXTURE_COUNT) {
    if (seen[i] == 0) missing_ids = missing_ids + 1;
    i = i + 1;
  }

  // ---- The observed set against the required set ------------------
  //
  // Every REQUIRED value must appear as a P16 row.  A fixture with the
  // correct row count but the wrong coverage FAILS here.
  I64 missing_required = 0;
  i = 0;
  while (i < req_count) {
    if (!p16_has(g_required[i])) missing_required = missing_required + 1;
    i = i + 1;
  }

  // ---- The signed-I64 extremes ------------------------------------
  I64 extremes_present = 0;
  if (observed_has(I64_MIN_HEX)) extremes_present = extremes_present + 1;
  if (observed_has(I64_MIN_PLUS1_HEX)) extremes_present = extremes_present + 1;
  if (observed_has(I64_MAX_MINUS1_HEX)) extremes_present = extremes_present + 1;
  if (observed_has(I64_MAX_HEX)) extremes_present = extremes_present + 1;

  Free(ftxt);

  printf("FIXTURE_TOTAL_ROWS=%d\n", total);
  printf("FIXTURE_EXPECTED_ROWS=%d\n", EXPECTED_FIXTURE_COUNT);
  printf("P16_ROWS=%d\n", p16_rows);
  printf("P16_REQUIRED_VALUES_PRESENT=%d/%d\n", req_count - missing_required, req_count);
  printf("P16_REQUIRED_VALUES_MISSING=%d\n", missing_required);
  printf("P16_SIGNED_EXTREMES_PRESENT=%d/4\n", extremes_present);
  printf("P16_VALUE_MEMBERSHIP_ERRORS=%d\n", p16_value_errors);
  printf("P16_EXPECTED_ERRORS=%d\n", p16_expected_errors);
  printf("P16_DISTINCT_VALUES_COVERED=%d/%d\n", p16_covered, req_count);
  printf("ORACLE_VS_EXPECTED_MISMATCH=%d\n", oracle_vs_expected_mismatch);
  printf("PARSE_ERRORS=%d\n", parse_errors);
  printf("FIELD_PARSE_ERRORS=%d\n", field_parse_errors);
  printf("MALFORMED_ROWS=%d\n", malformed_rows);
  printf("TRUNCATED_ROWS=%d\n", truncated_rows);
  printf("UNKNOWN_IDS=%d\n", unknown_ids);
  printf("DUPLICATE_IDS=%d\n", duplicate_ids);
  printf("MISSING_IDS=%d\n", missing_ids);
  printf("OUT_OF_RANGE_IDS=%d\n", out_of_range_ids);
  if (have_first_fail) {
    printf("FIRST_EXPECTATION_FAILURE value=%lld expected=%lld oracle=%lld\n",
           first_fail_value, first_fail_expected, first_fail_oracle);
  }

  // ---- The verdict ------------------------------------------------
  //
  // EVERY one of these must hold:
  //   * the row count is the canonical count;
  //   * every canonical id is present exactly once;
  //   * every row parses and has the declared schema;
  //   * every row's expectation agrees with the REAL oracle;
  //   * every required value is present AS A P16 ROW;
  //   * the four signed-I64 extremes are present;
  //   * every P16 row's value is in the required set;
  //   * every P16 row's expectation agrees with the oracle.
  if (total == EXPECTED_FIXTURE_COUNT
      && missing_ids == 0
      && unknown_ids == 0
      && duplicate_ids == 0
      && out_of_range_ids == 0
      && malformed_rows == 0
      && truncated_rows == 0
      && parse_errors == 0
      && field_parse_errors == 0
      && oracle_vs_expected_mismatch == 0
      && p16_value_errors == 0
      && p16_expected_errors == 0
      && missing_required == 0
      && extremes_present == 4
      && p16_rows == req_count
      && p16_covered == req_count) {
    printf("STATUS=PASS\n");
    return 0;
  }
  printf("STATUS=FAIL\n");
  return 1;
}
