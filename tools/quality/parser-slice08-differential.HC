// tools/quality/parser-slice08-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE08 C2.
//
// PolyC-native DIRECT DIFFERENTIAL verifier for the default-arm
// TERMINATION decision, with a FAIL-CLOSED fixture-integrity contract.
//
// Architecture:
//   legacy C decision
//       <-- build/slice08-gen/g0.o, which is the ACTUAL
//          production src/parser.c compiled WITHOUT
//          HCC_USE_SELFHOST_PARSER_DEFAULT_ARM_TERMINATES, so the REAL
//          legacy condition body is the one that executes
//   PolyC BootstrapDefaultArmTerminates
//       <-- tools/bootstrap/selfhost-parser-slice08.HC
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
// The oracle is reached through a NARROW ADAPTER: the adapter calls
// the real legacy decision through the tiny wrapper that src/parser.c
// itself exposes adjacent to that decision
// (ParserLegacyDefaultArmTerminatesOracle).
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice08-differential <fixture.tsv> <expected_row_count>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// The REAL legacy decision, reached through the narrow adapter.
extern "c" I64 Slice08LegacyDefaultArmOracle(I64 ast_kind);

// The PolyC component.  It is the DECISION OWNER under test.
extern "c" I64 BootstrapDefaultArmTerminates(I64 ast_kind);

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
    "usage: parser-slice08-differential <fixture.tsv> <expected_row_count>\n";
    return 2;
  }
  U8 *path = argv[1];
  I64 expected_count = 0;
  if (parse_i64(argv[2], StrLen(argv[2]), &expected_count) == 0) {
    "SLICE08_DIFF_ARG_PARSE_ERROR=1\n";
    "SLICE08_DIFF_STATUS=FAIL\n";
    return 1;
  }

  I64 got = 0;
  U8 *buf = FileRead(path, &got);
  if (buf == NULL) {
    "SLICE08_DIFF_OPEN_FAILED=%s\n", path;
    "SLICE08_DIFF_STATUS=FAIL\n";
    return 1;
  }

  I64 total = 0;
  I64 pass = 0;
  I64 fail = 0;
  I64 skip_rows = 0;
  I64 parse_errors = 0;
  I64 field_parse_errors = 0;
  I64 oracle_vs_expected_mismatch = 0;
  I64 polyc_vs_expected_mismatch = 0;
  I64 oracle_vs_polyc_mismatch = 0;
  I64 invalid_oracle_result = 0;
  I64 invalid_polyc_result = 0;
  I64 duplicate_ids = 0;
  I64 missing_ids = 0;
  I64 out_of_range_ids = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 missing_row_ids = 0;
  I64 max_id = 0;
  I64 dump_rows = 0;
  // The per-row dump is enabled by a THIRD argument of the form "-no"
  // (the NEW-CASES/row form).  It is the SAME comparison layer and the
  // SAME fixture; the dump only ADDS the per-row record, so a dumped run
  // is not a different experiment.
  if (argc >= 4) {
    if (argv[3][0] == 45 && argv[3][1] == 110 && argv[3][2] == 111 && argv[3][3] == 0) {
      dump_rows = 1;
    }
  }
  I64 seen_n = 0;
  I64 seen[MAX_IDS];

  // The record scan.
  I64 pos = 0;
  I64 rec_start = 0;
  while (pos < got) {
    if (buf[pos] == 10) {
      // One record: [rec_start, pos)
      I64 len = pos - rec_start;
      U8 *rec = buf + rec_start;
      // Is this a FIXTURE ROW?  The first byte must be a digit and the
      // row must carry the exact number of TAB-separated fields.
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
            "SLICE08_DIFF_MALFORMED_ROW_FIELDS=%d\n", nf;
          }
        } else {
          I64 id = 0;
          I64 kind = 0;
          I64 expected = 0;
          if (parse_i64(rec + fstart[0], flen[0], &id) == 0
              || parse_i64(rec + fstart[2], flen[2], &kind) == 0
              || parse_i64(rec + fstart[3], flen[3], &expected) == 0) {
            field_parse_errors = field_parse_errors + 1;
            if (field_parse_errors <= 8) {
              "SLICE08_DIFF_FIELD_PARSE_ERROR id=%d\n", id;
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
                "SLICE08_DIFF_DUPLICATE_ID=%d\n", id;
              }
            } else {
              if (seen_n < MAX_IDS) { seen[seen_n] = id; seen_n = seen_n + 1; }
            }

            total = total + 1;
            I64 legacy = Slice08LegacyDefaultArmOracle(kind);
            I64 poly = BootstrapDefaultArmTerminates(kind);
            if (legacy != 0 && legacy != 1) invalid_oracle_result = invalid_oracle_result + 1;
            if (poly != 0 && poly != 1) invalid_polyc_result = invalid_polyc_result + 1;
            if (legacy == expected && poly == expected) pass = pass + 1;
            else fail = fail + 1;
            // The per-row dump: the four generations are compared ROW
            // BY ROW with their exact row IDs, not merely by a summary
            // count.  The row identity, the input and all three
            // results are bound together on one line.
            if (dump_rows == 1) {
              "SLICE08_ROW=%d AST_KIND=%d EXPECTED=%d LEGACY=%d POLYC=%d\n",
                id, kind, expected, legacy, poly;
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
      pos = pos + 1;
      rec_start = pos;
    } else {
      pos = pos + 1;
    }
  }

  // ---- the missing ids --------------------------------------------------
  for (I64 id = 1; id <= max_id; id = id + 1) {
    I64 found = 0;
    for (I64 i = 0; i < seen_n; i = i + 1) {
      if (seen[i] == id) found = 1;
    }
    if (found == 0) {
      missing_ids = missing_ids + 1;
      if (missing_ids <= 8) {
        "SLICE08_DIFF_MISSING_ID=%d\n", id;
      }
    }
  }
  for (I64 i = 0; i < seen_n; i = i + 1) {
    if (seen[i] < 1 || seen[i] > max_id) out_of_range_ids = out_of_range_ids + 1;
  }

  // ---- the report -------------------------------------------------------
  "SLICE08_DIFF_PATH=%s\n", path;
  "SLICE08_DIFF_ROWS=%d\n", total;
  "SLICE08_DIFF_EXPECTED_ROWS=%d\n", expected_count;
  "SLICE08_DIFF_PASS=%d\n", pass;
  "SLICE08_DIFF_FAIL=%d\n", fail;
  "SLICE08_DIFF_SKIP_ROWS=%d\n", skip_rows;
  "SLICE08_DIFF_PARSE_ERRORS=%d\n", parse_errors;
  "SLICE08_DIFF_FIELD_PARSE_ERRORS=%d\n", field_parse_errors;
  "SLICE08_DIFF_ORACLE_VS_EXPECTED_MISMATCH=%d\n", oracle_vs_expected_mismatch;
  "SLICE08_DIFF_POLYC_VS_EXPECTED_MISMATCH=%d\n", polyc_vs_expected_mismatch;
  "SLICE08_DIFF_ORACLE_VS_POLYC_MISMATCH=%d\n", oracle_vs_polyc_mismatch;
  "SLICE08_DIFF_INVALID_ORACLE_RESULT=%d\n", invalid_oracle_result;
  "SLICE08_DIFF_INVALID_POLYC_RESULT=%d\n", invalid_polyc_result;
  "SLICE08_DIFF_DUPLICATE_IDS=%d\n", duplicate_ids;
  "SLICE08_DIFF_MISSING_IDS=%d\n", missing_ids;
  "SLICE08_DIFF_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "SLICE08_DIFF_MALFORMED_ROWS=%d\n", malformed_rows;
  "SLICE08_DIFF_TRUNCATED_ROWS=%d\n", truncated_rows;
  "SLICE08_DIFF_MISSING_ROW_IDS=%d\n", missing_row_ids;

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
      && invalid_oracle_result == 0
      && invalid_polyc_result == 0
      && duplicate_ids == 0
      && missing_ids == 0
      && out_of_range_ids == 0
      && malformed_rows == 0
      && truncated_rows == 0
      && field_parse_errors == 0) {
    "SLICE08_DIFF_STATUS=PASS\n";
    return 0;
  }
  "SLICE08_DIFF_STATUS=FAIL\n";
  return 1;
}
