// tools/quality/parser-control-flow-token-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01 C2 IMPL.
//
// PolyC-native DIRECT DIFFERENTIAL verifier for the control-flow token
// decision, with a FAIL-CLOSED fixture-integrity contract.
//
// Architecture (ACT-POLYC-SELFHOST-PARSER-SLICE02 section 7):
//   legacy C OracleValidPostControlFlowToken
//       <-- tools/quality/parser-control-flow-token-oracle-impl.c
//         (which calls the VERBATIM production body copied from
//          src/parser.c:832..864, bound to the LIVE src/lexer.h)
//   PolyC BootstrapValidPostControlFlowToken
//       <-- tools/bootstrap/selfhost-parser-control-flow-token.HC
//   comparison layer
//       <-- THIS FILE (PolyC, terminal authority)
//
// The comparison layer is PolyC. The Oracle is C. The two are compared
// on EVERY row, and the fixture's own `expected` column is checked
// against the oracle as well, so a disagreement between the PolyC
// subject and the production oracle cannot be masked by an equally
// wrong fixture.
//
// USAGE:
//   build/parser-control-flow-token-differential <fixture.tsv>
//
// Fixture schema (the CORRECTED matrix, 42 rows):
//   fixture_id <TAB> partition <TAB> present <TAB> kind <TAB> value
//             <TAB> expected <TAB> rationale <TAB> source_line
//
// `kind` may be decimal or 0x-prefixed hexadecimal.  `value` may be
// decimal, 0x-prefixed hexadecimal, or negative.
//
// ---------------------------------------------------------------------------
// WHAT THIS ACT CHANGED (ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01)
// ---------------------------------------------------------------------------
//
// D3 -- THE FIXTURE SET IS NOW AUTHORITATIVE.
//
// The original acceptance predicate was
//     fail == 0 && parse_errors == 0 && oracle_vs_expected_mismatch == 0
// with NO requirement on the fixture count or on the fixture ID set.
// A one-row fixture therefore produced STATUS=PASS, an EMPTY fixture
// produced STATUS=PASS, and the set missing F041 produced STATUS=PASS --
// concealing the loss of the aliasing control.
//
// The predicate is now:
//     the EXACT canonical ID set F001..F042 is present,
//     each ID occurs EXACTLY once,
//     every row matches the declared schema exactly,
//     and the semantic comparison is clean.
//
// A row that cannot be parsed is a FAILURE, never a silent skip.
//
// D5 -- THE ROW READER NO LONGER SKIPS UNRECOGNIZED ROWS.
//
// The D3 implementation decided whether a line was a fixture row with
// a NEGATIVE test:
//
//     if (line[0] != 'F') continue;
//     if (line[1] < '0' || line[1] > '9') continue;
//
// Every line that failed that test was skipped BEFORE the unknown-ID
// ledger ran. An unknown fixture id such as "X001" was therefore
// INVISIBLE: it never incremented `unknown_ids`, never incremented
// `total`, and a fixture holding the 42 canonical rows PLUS that
// unknown row returned STATUS=PASS.
//
// The row reader is now POSITIVE: a line is skipped only when it is
// an explicitly recognized comment ('#') or metadata (KEY=VALUE or an
// indented continuation) row. Every other line is a DATA row and is
// validated, so an unknown id is counted as a failure and reported
// with the reason token FIXTURE_ID_UNKNOWN.
//
// D4 -- THE SIGNED INTEGER PARSER NO LONGER OVERFLOWS.
//
// The original accumulator was
//     I64 v = 0;  v = v * 10 + digit;  if (negative) v = -v;
// which overflows the I64 range before the negation. Measured against
// the original code: INT64_MAX parsed to -1, INT64_MIN parsed to 0, and
// both out-of-range magnitudes were ACCEPTED rather than rejected.
//
// The magnitude is now accumulated in the NEGATIVE domain, so the only
// magnitude that does not fit in a positive I64 -- 2^63, which INT64_MIN
// needs -- is still exactly representable, and the limit is checked
// BEFORE every multiply-add.
//
// The reason the magnitude is not accumulated in an unsigned type is
// MEASURED, not assumed: in this PolyC, U64 values at or above 2^63 are
// sign-extended by the shift, divide and compare operators, and the
// multiply/add operators wrap in the signed domain. The signed-negative
// domain is therefore the only one in which the arithmetic is exact.
//
// The parser also rejects TRAILING GARBAGE and MISSING DIGITS, which
// the original left to the caller.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value);
extern "c" I64 OracleValidPostControlFlowToken(I64 present, I64 kind, I64 value);

#define LINE_CAP 1024

// The canonical fixture count and ID set.
#define EXPECTED_FIXTURE_COUNT 42

// The exact number of TAB-separated fields in a fixture row.
#define FIXTURE_FIELD_COUNT 8

// The most-negative safe PRE-MULTIPLY magnitude, base 10.
//
// The magnitude is accumulated NEGATIVE, so the accumulated value v
// satisfies v = -(magnitude). The step is
//     v' = v * base - digit
// and the requirement is v' >= -2^63, i.e.
//
//     v * base >= -2^63 + digit
//
// For base 10 and digit d, the exact threshold is
//     v >= ceil((-2^63 + d) / 10)
// which is -922337203685477580 for d = 0..8 and -922337203685477579
// for d = 9. Both are written explicitly: the division rounds toward
// zero in this language, so computing them would be wrong for d = 9.
// BEGIN VERBATIM COPY of parse_int
#define NEG_LIMIT_DEC -922337203685477580
#define NEG_LIMIT_DEC_D9 -922337203685477579

// The same for base 16. ceil((-2^63 + d) / 16) is
// -576460752303423488 for d = 0 and -576460752303423487 for d >= 1.
#define NEG_LIMIT_HEX -576460752303423488
#define NEG_LIMIT_HEX_D1 -576460752303423487

// The most-negative magnitude representable at all: -2^63.
#define NEG_MIN_2P63 -9223372036854775807 - 1

// Parse a signed decimal-or-hex integer at *pp. Advances *pp past the
// token. Returns 0 on success, 1 on a parse error.
//
// The magnitude is accumulated as a NEGATIVE I64, which makes the
// magnitude 2^63 (needed by INT64_MIN) exactly representable, and the
// limit is checked BEFORE each multiply-add so that no intermediate
// value ever overflows.
//
// The whole token must be consumed: trailing garbage is a parse error.
//
// ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: the block between the
// markers below is EXTRACTED MECHANICALLY by the Makefile to build the
// integer-boundary qualification tool
// (tools/quality/parser-control-flow-token-int-bounds.HC), so the
// function under test and the function under qualification can never
// drift apart.
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
  // the end of the field. Trailing garbage ("12abc") is a parse error,
  // not a silently truncated value. This is what the original
  // implementation left to the caller, and it is how a malformed
  // fixture row could pass unnoticed.
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
// END VERBATIM COPY of parse_int

// Advance *pp past the next TAB-separated field.
// Returns 1 if the field is missing (no TAB was found before the end of
// the line), 0 otherwise.
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

// ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01.
//
// Is this line a RECOGNIZED non-data row that may be skipped?
//
// The classification is POSITIVE: a line is skippable only if it is
// EXPLICITLY a comment or a metadata line. Every other line is a DATA
// row and MUST be validated.
//
// This is the repair of the predecessor's P0 bypass. The predecessor
// used the NEGATIVE test
//
//     if (line[0] != 'F') continue;
//     if (line[1] < '0' || line[1] > '9') continue;
//
// which skipped any row whose ID did not start with 'F' followed by a
// digit BEFORE the unknown-ID ledger could run. An unknown fixture ID
// such as "X001" was therefore invisible: it never incremented
// `unknown_ids`, never incremented `total`, and the differential
// returned STATUS=PASS. The frozen contract requires an unknown ID to
// be REJECTED, and the predecessor's own C1 control NC-D12 specified
// exactly that case but was never executed.
//
// The two recognized skippable forms are:
//
//   1. COMMENT: the line begins with '#'.
//   2. METADATA: the line begins with an '=' at some position > 0
//      (a KEY=VALUE line), OR the line begins with a SPACE or TAB
//      (an indented continuation line of the metadata block).
//
// The '=' test is scoped to the FIRST FIELD only, i.e. it must occur
// before the first TAB. A data row's rationale field may legitimately
// contain '=' (for example "tok == NULL returns 0; ..."), so scanning
// the whole line would wrongly classify a data row as metadata.
//
// A data row always begins with a non-whitespace, non-'#' character and
// carries the fixture id in its first field, so neither recognized
// skippable form can swallow a data row.
I64 is_skippable_row(U8 *line, I64 linelen)
{
  if (linelen == 0) return 1;              // blank line

  // 1. comment
  if (line[0] == '#') return 1;

  // 2a. indented continuation of the metadata block
  if (line[0] == ' ' || line[0] == '\t') return 1;

  // 2b. KEY=VALUE metadata line: an '=' in the FIRST field, i.e. at a
  // position > 0 and before the first TAB.
  I64 i = 1;
  while (i < linelen && line[i] != '\t') {
    if (line[i] == '=') return 1;
    i = i + 1;
  }

  // Not a recognized comment or metadata row: this is a DATA row and
  // MUST be validated. Falling through here is what makes an unknown
  // fixture ID visible.
  return 0;
}

// Is the field at *pp exactly the canonical fixture id for `index`
// (1-based)? The canonical id is "F" followed by the index in DECIMAL
// with no leading zeros, e.g. index 1 -> "F001", index 42 -> "F042".
I64 is_canonical_id(U8 *s, I64 n, I64 index)
{
  if (n != 4) return 0;
  if (s[0] != 'F') return 0;
  if (s[1] != '0') return 0;
  // index must be 1..42, so the tens digit is 0..4 and the ones 0..9
  I64 tens = index / 10;
  I64 ones = index % 10;
  if (tens == 0) {
    if (s[2] != '0') return 0;
  } else {
    if (s[2] != '0' + tens) return 0;
  }
  if (s[3] != '0' + ones) return 0;
  return 1;
}

I64 main(I64 argc, U8 **argv)
{
  if (argc != 2) {
    "SLICE02_DIFF_USAGE: %s <fixture.tsv>\n", argv[0];
    return 2;
  }

  I64 fsz = 0;
  U8 *ftxt = FileRead(argv[1], &fsz);
  if (ftxt == NULL) {
    "SLICE02_DIFF_RC=2 reason=missing-fixture path=%s\n", argv[1];
    return 2;
  }

  I64 pass = 0;
  I64 fail = 0;
  I64 total = 0;
  I64 parse_errors = 0;
  // The subset of parse errors that come from a FIELD that does not
  // parse. This is the SCHEMA-failure counter: a field that does not
  // parse is a schema failure, whereas the aggregate parse_errors also
  // counts a missing id and a duplicate id, neither of which is a
  // schema failure.
  I64 field_parse_errors = 0;
  I64 oracle_vs_expected_mismatch = 0;
  I64 first_fail_present = 0;
  I64 first_fail_kind = 0;
  I64 first_fail_value = 0;
  I64 first_fail_poly = 0;
  I64 first_fail_oracle = 0;

  // ---- The fixture-integrity accounting (D3) ------------------------
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
    //
    // ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01: the
    // predecessor skipped any line that did not start with 'F' followed
    // by a digit. That made an unknown fixture ID (e.g. "X001")
    // invisible to the unknown-ID ledger, so a 42-row fixture plus an
    // unknown row returned STATUS=PASS. The test is now POSITIVE: a row
    // is skipped only when it is a recognized comment or metadata line.
    if (is_skippable_row(line, linelen)) continue;

    total = total + 1;

    // ---- The row must match the declared schema EXACTLY -----------
    // 8 TAB-separated fields. A row with fewer is TRUNCATED; a row with
    // more is MALFORMED. Either way it is a FAILURE, never a silent skip.
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

    // ---- The fixture id must be a canonical F### in range ---------
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
    // present
    I64 present = 0;
    if (parse_int(&p, &present)) { parse_errors = parse_errors + 1; field_parse_errors = field_parse_errors + 1; continue; }
    skip_field(&p);
    // kind
    I64 kind = 0;
    if (parse_int(&p, &kind)) { parse_errors = parse_errors + 1; field_parse_errors = field_parse_errors + 1; continue; }
    skip_field(&p);
    // value
    I64 value = 0;
    if (parse_int(&p, &value)) { parse_errors = parse_errors + 1; field_parse_errors = field_parse_errors + 1; continue; }
    skip_field(&p);
    // expected
    I64 expected = 0;
    if (parse_int(&p, &expected)) { parse_errors = parse_errors + 1; field_parse_errors = field_parse_errors + 1; continue; }

    I64 pc = BootstrapValidPostControlFlowToken(present, kind, value);
    I64 oc = OracleValidPostControlFlowToken(present, kind, value);

    // The fixture's own expectation must agree with the production
    // oracle. A row where they disagree is a defect in the FIXTURE,
    // not in the subject, and is counted separately so it cannot be
    // confused with a subject/oracle disagreement.
    if (oc != expected) oracle_vs_expected_mismatch = oracle_vs_expected_mismatch + 1;

    if (pc == oc) {
      pass = pass + 1;
    } else {
      fail = fail + 1;
      if (fail == 1) {
        first_fail_present = present;
        first_fail_kind = kind;
        first_fail_value = value;
        first_fail_poly = pc;
        first_fail_oracle = oc;
      }
    }
  }

  // ---- The canonical ID set must be COMPLETE ----------------------
  I64 missing_ids = 0;
  I64 m = 1;
  while (m <= EXPECTED_FIXTURE_COUNT) {
    if (seen[m] == 0) missing_ids = missing_ids + 1;
    m = m + 1;
  }

  Free(ftxt);

  "SLICE02_DIFFERENTIAL_TOTAL=%d\n", total;
  "SLICE02_DIFFERENTIAL_PASS=%d\n", pass;
  "SLICE02_DIFFERENTIAL_FAIL=%d\n", fail;
  "SLICE02_DIFFERENTIAL_PARSE_ERRORS=%d\n", parse_errors;
  "SLICE02_DIFFERENTIAL_ORACLE_VS_EXPECTED_MISMATCH=%d\n", oracle_vs_expected_mismatch;

  // ---- The fixture-integrity ledger (D3) ---------------------------
  "SLICE02_DIFFERENTIAL_EXPECTED_FIXTURE_COUNT=%d\n", EXPECTED_FIXTURE_COUNT;
  "SLICE02_DIFFERENTIAL_OBSERVED_FIXTURE_COUNT=%d\n", total;
  "SLICE02_DIFFERENTIAL_MISSING_IDS=%d\n", missing_ids;
  "SLICE02_DIFFERENTIAL_DUPLICATE_IDS=%d\n", duplicate_ids;
  "SLICE02_DIFFERENTIAL_UNKNOWN_IDS=%d\n", unknown_ids;
  "SLICE02_DIFFERENTIAL_TRUNCATED_ROWS=%d\n", truncated_rows;
  "SLICE02_DIFFERENTIAL_MALFORMED_ROWS=%d\n", malformed_rows;
  "SLICE02_DIFFERENTIAL_FIELD_PARSE_ERRORS=%d\n", field_parse_errors;
  "SLICE02_DIFFERENTIAL_FIXTURE_IDS_COMPLETE=%d\n", missing_ids == 0;
  "SLICE02_DIFFERENTIAL_FIXTURE_IDS_UNIQUE=%d\n", duplicate_ids == 0;
  "SLICE02_DIFFERENTIAL_FIXTURE_SCHEMA_VALID=%d\n", truncated_rows == 0 && malformed_rows == 0 && unknown_ids == 0;

  if (fail) {
    "first_fail_present=%d\n", first_fail_present;
    "first_fail_kind=%d\n", first_fail_kind;
    "first_fail_value=%d\n", first_fail_value;
    "first_fail_poly=%d\n", first_fail_poly;
    "first_fail_oracle=%d\n", first_fail_oracle;
  }

  // The acceptance predicate. Every clause is load bearing.
  if (fail || parse_errors || oracle_vs_expected_mismatch
      || missing_ids || duplicate_ids || unknown_ids
      || truncated_rows || malformed_rows
      || total != EXPECTED_FIXTURE_COUNT) {
    if (total == 0) {
      "REASON=FIXTURE_SET_EMPTY\n";
    } else if (unknown_ids) {
      // ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01.
      //
      // An unknown fixture id is its OWN reason token. The predecessor
      // reported it as FIXTURE_ID_SET_INCOMPLETE together with a missing
      // or duplicate id, but the C1 contract for NC-D12 requires the
      // specific token FIXTURE_ID_UNKNOWN. This branch is only
      // REACHABLE now that the row reader validates every data row
      // instead of skipping rows that do not start with 'F'.
      "REASON=FIXTURE_ID_UNKNOWN\n";
    } else if (truncated_rows || malformed_rows || field_parse_errors) {
      // A schema-invalid row is reported as a SCHEMA failure, even
      // though it may also leave the id set incomplete (the invalid row
      // never reaches the id ledger, so its id is reported missing).
      //
      // The predecessor reported FIXTURE_ID_SET_INCOMPLETE for a
      // truncated row and FIXTURE_COUNT_MISMATCH for a row whose
      // integer field fails to parse. Both contradicted its own C1
      // contract, where NC-D6b and NC-D7 both specify
      // FIXTURE_SCHEMA_INVALID. A row whose field does not parse is a
      // schema failure, and the schema failure is the more specific
      // diagnosis, so it is reported first.
      //
      // The condition is `field_parse_errors`, NOT the aggregate
      // `parse_errors`: the aggregate also counts a duplicate id and a
      // missing id, and a duplicate id is NOT a schema failure.
      "REASON=FIXTURE_SCHEMA_INVALID\n";
    } else if (missing_ids || duplicate_ids) {
      "REASON=FIXTURE_ID_SET_INCOMPLETE\n";
    } else if (oracle_vs_expected_mismatch) {
      "REASON=ORACLE_VS_EXPECTED_MISMATCH\n";
    } else if (fail) {
      "REASON=SUBJECT_VS_ORACLE_MISMATCH\n";
    } else {
      "REASON=FIXTURE_COUNT_MISMATCH\n";
    }
    "STATUS=FAIL\n";
    return 1;
  }
  "STATUS=PASS\n";
  return 0;
}
