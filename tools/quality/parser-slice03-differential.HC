// tools/quality/parser-slice03-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE03 C2 IMPL.
//
// PolyC-native DIRECT DIFFERENTIAL verifier for the operator-precedence
// decision, with a FAIL-CLOSED fixture-integrity contract.
//
// Architecture (ACT section 5.3):
//   legacy C ParserLegacyOperatorPrecedenceOracle
//       <-- build/slice03-prslib-legacy.o, which is src/prslib.c
//          compiled WITHOUT HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE,
//          so the REAL legacy parseGetPriority body is the one executed
//   PolyC BootstrapOperatorPrecedence
//       <-- tools/bootstrap/selfhost-parser-operator-precedence.HC
//   comparison layer
//       <-- THIS FILE (PolyC, terminal authority)
//
// The comparison layer is PolyC.  The oracle is C.  The two are compared
// on EVERY row, and the fixture's own `expected` column is checked
// against the oracle as well, so a disagreement between the PolyC subject
// and the production oracle cannot be masked by an equally wrong fixture.
//
// WHY THE ORACLE IS NOT A REIMPLEMENTATION
// =========================================
// The oracle object is src/prslib.c compiled WITHOUT the delegation
// macro.  The precedence table it executes is therefore the BYTE
// IDENTICAL legacy source, not a copy of it and not a reimplementation.
// A handwritten reimplementation could share the same misreading of the
// legacy source as the PolyC component and would agree with it while
// both are wrong.
//
// USAGE:
//   build/parser-slice03-differential <fixture.tsv>
//
// Fixture schema:
//   fixture_id <TAB> partition <TAB> punct_value <TAB> expected
//             <TAB> rationale
//
// `punct_value` may be decimal, 0x-prefixed hexadecimal, or negative.
// The comment lines of the fixture begin with '#'.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 BootstrapOperatorPrecedence(I64 punct_value);
extern "c" I64 ParserLegacyOperatorPrecedenceOracle(I64 punct_value);

#define LINE_CAP 1024

// The canonical fixture count and ID set.
#define EXPECTED_FIXTURE_COUNT 98

// The exact number of TAB-separated fields in a fixture row.
#define FIXTURE_FIELD_COUNT 5

// The most-negative safe PRE-MULTIPLY magnitude, base 10.
//
// The magnitude is accumulated NEGATIVE, so the accumulated value v
// satisfies v = -(magnitude).  The step is
//     v' = v * base - digit
// and the requirement is v' >= -2^63, i.e.
//
//     v * base >= -2^63 + digit
//
// For base 10 and digit d, the exact threshold is
//     v >= ceil((-2^63 + d) / 10)
// which is -922337203685477580 for d = 0..8 and -922337203685477579
// for d = 9.  Both are written explicitly: the division rounds toward
// zero in this language, so computing them would be wrong for d = 9.
#define NEG_LIMIT_DEC -922337203685477580
#define NEG_LIMIT_DEC_D9 -922337203685477579

// The same for base 16.  ceil((-2^63 + d) / 16) is
// -576460752303423488 for d = 0 and -576460752303423487 for d >= 1.
#define NEG_LIMIT_HEX -576460752303423488
#define NEG_LIMIT_HEX_D1 -576460752303423487

// The most-negative magnitude representable at all: -2^63.
#define NEG_MIN_2P63 -9223372036854775807 - 1

// Parse a signed decimal-or-hex integer at *pp.  Advances *pp past the
// token.  Returns 0 on success, 1 on a parse error.
//
// The magnitude is accumulated as a NEGATIVE I64, which makes the
// magnitude 2^63 (needed by INT64_MIN) exactly representable, and the
// limit is checked BEFORE each multiply-add so that no intermediate
// value ever overflows.
//
// The whole token must be consumed: trailing garbage is a parse error.
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

    // Check the limit BEFORE the multiply-add.
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

  // The token must be EXACTLY the integer: it must end at a TAB or at
  // the end of the field.  Trailing garbage ("12abc") is a parse error,
  // not a silently truncated value.
  if (*p != 0 && *p != '\t') return 1;    // TRAILING GARBAGE

  // The magnitude must not exceed 2^63.
  if (v < NEG_MIN_2P63) return 1;

  // v holds the NEGATIVE magnitude.
  if (neg) {
    *out = v;                 // already negative
  } else {
    // The positive magnitude must fit in a positive I64, i.e. the
    // magnitude must be at most 2^63 - 1.
    if (v == NEG_MIN_2P63) return 1;
    *out = 0 - v;
  }
  *pp = p;
  return 0;
}

// Advance *pp past the next TAB-separated field.
I64 skip_field(U8 **pp)
{
  U8 *p = *pp;
  while (*p && *p != '\t') p = p + 1;
  if (*p == '\t') p = p + 1;
  *pp = p;
  return 0;
}

// Return the length of the field at *pp, and advance *pp past the TAB.
I64 field_len(U8 *p)
{
  I64 n = 0;
  while (p[n] && p[n] != '\t') n = n + 1;
  return n;
}

// Is this the canonical fixture id for the given index?
//
// The canonical id is F followed by three decimal digits that spell
// the index, ZERO PADDED: F001, F002, ... F098.
//
// The digits are compared as the DECIMAL SPELLING of the index, so
// F001 spells 1 and F098 spells 98.  An id that is merely in range is
// NOT canonical: F002 does not spell index 2 unless the digits say so.
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

// Is this line a RECOGNIZED non-data row that may be skipped?
//
// The classification is POSITIVE: a line is skippable only when it is
// EXPLICITLY a comment or a metadata line.  Every other line is a DATA
// row and MUST be validated.
//
//   1. COMMENT: the line begins with '#'.
//   2. METADATA: the line begins with a KEY=VALUE pair, i.e. an '='
//      occurs in the FIRST field, before the first TAB.
//
// The '=' test is scoped to the FIRST FIELD because a data row's
// rationale may legitimately contain an '=' (for example "tok == NULL
// returns 0"), so scanning the whole line would misclassify a data
// row as metadata.
//
// An INDENTED row is NOT recognized as a non-data row.  That is
// deliberate: the indented-continuation rule is what let the bypass
// through in the closed control-flow-token tool, and an indented
// unknown row must reach the unknown-id ledger instead of vanishing.
I64 is_skippable_row(U8 *line, I64 linelen)
{
  if (linelen == 0) return 1;              // blank line
  if (line[0] == '#') return 1;             // comment

  // KEY=VALUE metadata: an '=' in the first field.
  I64 i = 1;
  while (i < linelen && line[i] != '\t') {
    if (line[i] == '=') return 1;
    i = i + 1;
  }
  return 0;
}

I64 main(I64 argc, U8 **argv)
{
  if (argc != 2) {
    printf("SLICE03_DIFF_USAGE: %s <fixture.tsv>\n", argv[0]);
    return 2;
  }

  I64 fsz = 0;
  U8 *ftxt = FileRead(argv[1], &fsz);
  if (ftxt == 0) {
    printf("SLICE03_DIFF_ERROR: cannot read %s\n", argv[1]);
    return 2;
  }

  I64 total = 0;
  I64 pass = 0;
  I64 fail = 0;
  I64 parse_errors = 0;
  I64 field_parse_errors = 0;
  I64 oracle_vs_expected_mismatch = 0;
  I64 first_fail_value = 0;
  I64 first_fail_poly = 0;
  I64 first_fail_oracle = 0;

  // ---- The fixture-integrity accounting -------------------------
  I64 seen[EXPECTED_FIXTURE_COUNT + 1];   // 1-based
  I64 i = 0;
  while (i < EXPECTED_FIXTURE_COUNT + 1) {
    seen[i] = 0;
    i = i + 1;
  }
  I64 duplicate_ids = 0;
  I64 unknown_ids = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 out_of_range_ids = 0;

  I64 lineno = 0;
  while (lineno < fsz) {
    // skip empty lines
    while (lineno < fsz && (ftxt[lineno] == '\n' || ftxt[lineno] == '\r')) lineno = lineno + 1;
    if (lineno >= fsz) break;

    // capture one row
    U8 line[LINE_CAP];
    I64 j = 0;
    while (lineno < fsz && ftxt[lineno] != '\n' && ftxt[lineno] != '\r' && j < LINE_CAP - 1) {
      line[j] = ftxt[lineno];
      j = j + 1;
      lineno = lineno + 1;
    }
    line[j] = 0;
    I64 linelen = j;

    // Skip ONLY the explicitly recognized comment and metadata rows.
    // Every other line is a DATA row and is validated below.
    if (is_skippable_row(line, linelen)) continue;

    total = total + 1;

    // ---- The row must match the declared schema EXACTLY -----------
    // 5 TAB-separated fields.  A row with fewer is TRUNCATED; a row
    // with more is MALFORMED.  Either way it is a FAILURE, never a
    // silent skip.
    I64 nfields = 0;
    I64 k = 0;
    while (k < linelen) {
      if (line[k] == '\t') nfields = nfields + 1;
      k = k + 1;
    }
    nfields = nfields + 1;
    if (nfields != FIXTURE_FIELD_COUNT) {
      if (nfields < FIXTURE_FIELD_COUNT) truncated_rows = truncated_rows + 1;
      else malformed_rows = malformed_rows + 1;
      parse_errors = parse_errors + 1;
      continue;
    }

    // ---- The fixture id must be a canonical F### in range --------
    I64 idlen = field_len(line);
    I64 idnum = 0;
    if (idlen == 4) {
      idnum = (line[1] - '0') * 100 + (line[2] - '0') * 10 + (line[3] - '0');
    }
    if (idlen != 4 || idnum < 1 || idnum > EXPECTED_FIXTURE_COUNT
        || !is_canonical_id(line, idlen, idnum)) {
      unknown_ids = unknown_ids + 1;
      parse_errors = parse_errors + 1;
      continue;
    }
    if (seen[idnum] > 0) {
      duplicate_ids = duplicate_ids + 1;
      parse_errors = parse_errors + 1;
      continue;
    }
    seen[idnum] = 1;

    U8 *p = line;
    // fixture_id
    skip_field(&p);
    // partition
    skip_field(&p);
    // punct_value
    I64 value = 0;
    if (parse_int(&p, &value)) { parse_errors = parse_errors + 1; field_parse_errors = field_parse_errors + 1; continue; }
    skip_field(&p);
    // expected
    I64 expected = 0;
    if (parse_int(&p, &expected)) { parse_errors = parse_errors + 1; field_parse_errors = field_parse_errors + 1; continue; }

    I64 pc = BootstrapOperatorPrecedence(value);
    I64 oc = ParserLegacyOperatorPrecedenceOracle(value);

    // The fixture's own expectation must agree with the production
    // oracle.  A row where they disagree is a defect in the FIXTURE,
    // not in the subject, and is counted separately so it cannot be
    // confused with a subject/oracle disagreement.
    if (oc != expected) oracle_vs_expected_mismatch = oracle_vs_expected_mismatch + 1;

    if (pc == oc) {
      pass = pass + 1;
    } else {
      fail = fail + 1;
      if (fail == 1) {
        first_fail_value = value;
        first_fail_poly = pc;
        first_fail_oracle = oc;
      }
    }
  }

  // ---- The missing-id count -------------------------------------
  I64 missing_ids = 0;
  i = 1;
  while (i <= EXPECTED_FIXTURE_COUNT) {
    if (seen[i] == 0) missing_ids = missing_ids + 1;
    i = i + 1;
  }

  Free(ftxt);

  printf("SLICE03_DIFF_TOTAL=%d\n", total);
  printf("SLICE03_DIFF_PASS=%d\n", pass);
  printf("SLICE03_DIFF_FAIL=%d\n", fail);
  printf("SLICE03_DIFF_PARSE_ERRORS=%d\n", parse_errors);
  printf("SLICE03_DIFF_FIELD_PARSE_ERRORS=%d\n", field_parse_errors);
  printf("SLICE03_DIFF_ORACLE_VS_EXPECTED_MISMATCH=%d\n", oracle_vs_expected_mismatch);
  printf("SLICE03_DIFF_UNKNOWN_IDS=%d\n", unknown_ids);
  printf("SLICE03_DIFF_DUPLICATE_IDS=%d\n", duplicate_ids);
  printf("SLICE03_DIFF_MISSING_IDS=%d\n", missing_ids);
  printf("SLICE03_DIFF_MALFORMED_ROWS=%d\n", malformed_rows);
  printf("SLICE03_DIFF_TRUNCATED_ROWS=%d\n", truncated_rows);
  printf("SLICE03_DIFF_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids);
  printf("SLICE03_DIFF_EXPECTED_FIXTURE_COUNT=%d\n", EXPECTED_FIXTURE_COUNT);
  if (fail == 1) {
    printf("SLICE03_DIFF_FIRST_FAILURE value=%d polyc=%d oracle=%d\n",
           first_fail_value, first_fail_poly, first_fail_oracle);
  }

  // The acceptance predicate.
  //
  // The fixture set is AUTHORITATIVE: the EXACT canonical ID set
  // F001..F098 is present, each ID occurs EXACTLY once, every row
  // matches the declared schema, the semantic comparison is clean, and
  // the fixture's own expectations agree with the production oracle.
  //
  // A row that cannot be parsed is a FAILURE, never a silent skip.
  if (fail == 0
      && parse_errors == 0
      && oracle_vs_expected_mismatch == 0
      && unknown_ids == 0
      && duplicate_ids == 0
      && missing_ids == 0
      && malformed_rows == 0
      && truncated_rows == 0
      && total == EXPECTED_FIXTURE_COUNT) {
    printf("STATUS=PASS\n");
    return 0;
  }
  printf("STATUS=FAIL\n");
  return 1;
}
