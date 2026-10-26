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

    // Skip comment lines and the trailing counter block. Only a line
    // that starts with 'F' followed by a digit is a fixture row.
    if (line[0] != 'F') continue;
    if (line[1] < '0' || line[1] > '9') continue;

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
    if (parse_int(&p, &present)) { parse_errors = parse_errors + 1; continue; }
    skip_field(&p);
    // kind
    I64 kind = 0;
    if (parse_int(&p, &kind)) { parse_errors = parse_errors + 1; continue; }
    skip_field(&p);
    // value
    I64 value = 0;
    if (parse_int(&p, &value)) { parse_errors = parse_errors + 1; continue; }
    skip_field(&p);
    // expected
    I64 expected = 0;
    if (parse_int(&p, &expected)) { parse_errors = parse_errors + 1; continue; }

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
    } else if (missing_ids || duplicate_ids || unknown_ids) {
      "REASON=FIXTURE_ID_SET_INCOMPLETE\n";
    } else if (truncated_rows || malformed_rows) {
      "REASON=FIXTURE_SCHEMA_INVALID\n";
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
