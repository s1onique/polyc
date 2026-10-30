// tools/quality/parser-slice09-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE09 C3.
//
// PolyC-native DIRECT DIFFERENTIAL verifier for the STATEMENT-
// CONSTRUCTOR DISPATCH decision, with a FAIL-CLOSED fixture-integrity
// contract.
//
// Architecture:
//   legacy C decision
//       <-- build/slice09-gen/g0.o, which is the ACTUAL
//          production src/parser.c compiled WITHOUT
//          HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH, so the REAL
//          legacy keyword chain is the one that executes
//   PolyC BootstrapStatementDispatch
//       <-- tools/bootstrap/selfhost-parser-statement-dispatch.HC
//   comparison layer
//       <-- THIS FILE (PolyC, terminal authority)
//
// TWO SOURCES ARE COMPARED ON EVERY ROW
// =========================================
//
//   1. the decision's observed value (the generation under test);
//   2. the fixture's own independently derived expected value.
//
// The fixture's expected values were derived from the SOURCE and the
// ENUM by two independent programs (the producer and the integrity
// witness), so comparing the generation against the fixture is not a
// comparison of a program against itself.
//
// WHY THE ORACLE IS NOT A REIMPLEMENTATION
// =========================================
//
// The oracle object is the ACTUAL production src/parser.c translation
// unit, compiled with the delegation OFF.  The decision body it
// executes is therefore the BYTE-IDENTICAL legacy source, not a copy
// of it and not a reimplementation.
//
// The oracle is reached through a NARROW ADAPTER: the adapter calls
// the real legacy decision through the tiny wrapper that src/parser.c
// itself exposes adjacent to that decision
// (ParserLegacyStatementDispatchOracle).
//
// WHICH SOURCE IS UNDER TEST IS CHOSEN AT LINK TIME
// ==================================================
//
// The differential is built FOUR times, once per generation:
//
//   G0  links build/slice09-gen/g0.o  -- the legacy C oracle
//   G1  links build/slice09-gen/g1.o  -- the stage0-built PolyC
//   G2  links build/slice09-gen/g2.o  -- the production-built PolyC
//   G3  links build/slice09-gen/g3.o  -- the bootstrap02-built PolyC
//
// The symbol name is the SAME in all four builds, so the comparison
// layer is BYTE-IDENTICAL across the four and only the linked
// decision object differs.  That is what makes the four runs
// comparable row for row.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice09-differential <fixture.tsv> <expected_row_count>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// The decision under test.  The linked object supplies it: either the
// legacy C oracle (G0) or one of the three compiled PolyC generations
// (G1, G2, G3).
extern "c" I64 Slice09StatementDispatchUnderTest(I64 token_type,
                                                 I64 keyword_id);

// The number of TAB-separated fields in a fixture row.
//
//   fixture_id, partition, token_type, keyword_id,
//   expected_selector, expected_constructor, rationale
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
// The literal -9223372036854775808 DOES NOT EVALUATE TO INT64_MIN IN
// THIS LANGUAGE.  The positive magnitude 9223372036854775808 is one
// past INT64_MAX, so the parser's constant folding clamps it and the
// negative of it yields -9223372036854775807 instead.  The floor is
// therefore written as (-9223372036854775807 - 1).
#define NEG_MIN_2P63 (-9223372036854775807 - 1)
#define INT64_MAX_VALUE 9223372036854775807

// The parse of a decimal integer field.  It returns 1 on success.
static I64 parse_i64(U8 *s, I64 len, I64 *out)
{
  I64 neg = 0;
  I64 i = 0;
  if (len == 0) return 0;
  if (s[0] == 45) { neg = 1; i = 1; if (len == 1) return 0; }
  I64 acc = 0;
  while (i < len) {
    if (s[i] < 48 || s[i] > 57) return 0;
    I64 digit = s[i] - 48;
    // The magnitude is accumulated NEGATIVE so that the INT64_MIN
    // floor is exactly representable.
    if (acc == NEG_LIMIT_DEC && digit == 9) acc = NEG_LIMIT_DEC_D9;
    else if (acc < NEG_LIMIT_DEC) return 0;
    else acc = acc * 10 - digit;
    i = i + 1;
  }
  I64 mag = 0 - acc;
  if (mag == INT64_MAX_VALUE && neg == 1) { *out = NEG_MIN_2P63; return 1; }
  if (neg == 1) { *out = 0 - mag; return 1; }
  *out = mag;
  return 1;
}

// The fixture buffer.
#define FIXTURE_BUF 2097152
#define MAX_IDS 8192

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 3) {
    "usage: parser-slice09-differential <fixture.tsv> <expected_row_count>\n";
    return 2;
  }
  U8 *path = argv[1];
  I64 expected_count = 0;
  if (parse_i64(argv[2], StrLen(argv[2]), &expected_count) == 0) {
    "SLICE09_DIFF_ARG_PARSE_ERROR=1\n";
    "SLICE09_DIFF_STATUS=FAIL\n";
    return 1;
  }

  I64 got = 0;
  U8 *buf = FileRead(path, &got);
  if (buf == NULL) {
    "SLICE09_DIFF_OPEN_FAILED=%s\n", path;
    "SLICE09_DIFF_STATUS=FAIL\n";
    return 1;
  }

  I64 total = 0;
  I64 pass = 0;
  I64 fail = 0;
  I64 parse_errors = 0;
  I64 field_parse_errors = 0;
  I64 selector_mismatch = 0;
  I64 invalid_result = 0;
  I64 duplicate_ids = 0;
  I64 out_of_range_ids = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 missing_row_ids = 0;
  I64 max_id = 0;
  I64 seen_n = 0;
  I64 seen[MAX_IDS];
  // The per-row dump is enabled by a THIRD argument of the form "-no".
  // It is the SAME comparison layer and the SAME fixture; the dump
  // only ADDS the per-row record, so a dumped run is not a different
  // experiment.
  I64 dump_rows = 0;
  if (argc >= 4) {
    if (argv[3][0] == 45 && argv[3][1] == 110 && argv[3][2] == 111 && argv[3][3] == 0) {
      dump_rows = 1;
    }
  }

  // The record scan.
  I64 pos = 0;
  I64 rec_start = 0;
  while (pos < got) {
    if (buf[pos] == 10) {
      // One record: [rec_start, pos)
      I64 len = pos - rec_start;
      U8 *rec = buf + rec_start;
      // Is this a FIXTURE ROW?  The first byte must be a digit.
      I64 is_row = 0;
      if (len > 0 && rec[0] >= 48 && rec[0] <= 57) is_row = 1;
      if (is_row == 1) {
        // Split into fields.
        I64 fstart[8];
        I64 flen[8];
        I64 nf = 0;
        I64 fs = 0;
        I64 i = 0;
        while (i <= len) {
          if (i == len || rec[i] == 9) {
            if (nf < 8) { fstart[nf] = fs; flen[nf] = i - fs; nf = nf + 1; }
            fs = i + 1;
          }
          i = i + 1;
        }
        if (nf != FIXTURE_FIELD_COUNT) {
          malformed_rows = malformed_rows + 1;
          if (malformed_rows <= 8) {
            "SLICE09_DIFF_MALFORMED_ROW_FIELDS=%d\n", nf;
          }
        } else {
          I64 id = 0;
          I64 ttype = 0;
          I64 kid = 0;
          I64 expected = 0;
          if (parse_i64(rec + fstart[0], flen[0], &id) == 0
              || parse_i64(rec + fstart[2], flen[2], &ttype) == 0
              || parse_i64(rec + fstart[3], flen[3], &kid) == 0
              || parse_i64(rec + fstart[4], flen[4], &expected) == 0) {
            field_parse_errors = field_parse_errors + 1;
            if (field_parse_errors <= 8) {
              "SLICE09_DIFF_FIELD_PARSE_ERROR id=%d\n", id;
            }
          } else {
            if (id < 1) {
              out_of_range_ids = out_of_range_ids + 1;
            }
            if (id > max_id) max_id = id;
            // The duplicate check.
            I64 dup = 0;
            I64 k = 0;
            while (k < seen_n) {
              if (seen[k] == id) dup = 1;
              k = k + 1;
            }
            if (dup == 1) {
              duplicate_ids = duplicate_ids + 1;
              if (duplicate_ids <= 8) {
                "SLICE09_DIFF_DUPLICATE_ID=%d\n", id;
              }
            } else {
              if (seen_n < MAX_IDS) { seen[seen_n] = id; seen_n = seen_n + 1; }
            }

            // THE COMPARISON: the decision's observed value against
            // the fixture's independently derived expected value.
            I64 actual = Slice09StatementDispatchUnderTest(ttype, kid);
            if (actual < 0 || actual > 15) {
              invalid_result = invalid_result + 1;
              if (invalid_result <= 8) {
                "SLICE09_DIFF_INVALID_SELECTOR id=%d actual=%d\n", id, actual;
              }
            }
            total = total + 1;
            if (actual == expected) {
              pass = pass + 1;
            } else {
              fail = fail + 1;
              selector_mismatch = selector_mismatch + 1;
              if (selector_mismatch <= 8) {
                "SLICE09_DIFF_SELECTOR_MISMATCH id=%d token_type=%d keyword_id=%d expected=%d actual=%d\n",
                  id, ttype, kid, expected, actual;
              }
            }
            if (dump_rows == 1) {
              "SLICE09_ROW\t%d\t%d\t%d\t%d\t%d\n", id, ttype, kid, expected, actual;
            }
          }
        }
      }
      rec_start = pos + 1;
    }
    pos = pos + 1;
  }

  // The MISSING-ID check: every id in 1..max_id must have been seen.
  I64 mi = 1;
  while (mi <= max_id) {
    I64 found = 0;
    I64 k = 0;
    while (k < seen_n) {
      if (seen[k] == mi) found = 1;
      k = k + 1;
    }
    if (found == 0) {
      missing_row_ids = missing_row_ids + 1;
      if (missing_row_ids <= 8) {
        "SLICE09_DIFF_MISSING_ROW_ID=%d\n", mi;
      }
    }
    mi = mi + 1;
  }

  // The ROW-COUNT check: the fixture must carry exactly the declared
  // number of rows.  A shortfall means a row was dropped.
  if (total != expected_count) {
    truncated_rows = truncated_rows + 1;
    "SLICE09_DIFF_ROW_COUNT_MISMATCH expected=%d observed=%d\n",
      expected_count, total;
  }

  "SLICE09_DIFF_ROWS=%d\n", total;
  "SLICE09_DIFF_PASS=%d\n", pass;
  "SLICE09_DIFF_FAIL=%d\n", fail;
  "SLICE09_DIFF_SELECTOR_MISMATCH=%d\n", selector_mismatch;
  "SLICE09_DIFF_INVALID_SELECTOR=%d\n", invalid_result;
  "SLICE09_DIFF_MALFORMED_ROWS=%d\n", malformed_rows;
  "SLICE09_DIFF_FIELD_PARSE_ERRORS=%d\n", field_parse_errors;
  "SLICE09_DIFF_DUPLICATE_IDS=%d\n", duplicate_ids;
  "SLICE09_DIFF_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "SLICE09_DIFF_MISSING_ROW_IDS=%d\n", missing_row_ids;
  "SLICE09_DIFF_TRUNCATED_ROWS=%d\n", truncated_rows;
  "SLICE09_DIFF_MAX_ID=%d\n", max_id;

  if (fail == 0 && selector_mismatch == 0 && invalid_result == 0
      && malformed_rows == 0 && field_parse_errors == 0
      && duplicate_ids == 0 && out_of_range_ids == 0
      && missing_row_ids == 0 && truncated_rows == 0
      && total == expected_count && expected_count > 0) {
    "SLICE09_DIFF_STATUS=PASS\n";
    return 0;
  }
  "SLICE09_DIFF_STATUS=FAIL\n";
  return 1;
}
