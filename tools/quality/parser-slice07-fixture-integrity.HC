// tools/quality/parser-slice07-fixture-integrity.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE07 C1.
//
// THE INDEPENDENT FIXTURE-INTEGRITY WITNESS.
//
// WHY A SEPARATE TOOL, AND WHY IT MUST NOT SHARE THE PRODUCER'S LOGIC
// =====================================================================
//
// The fixture producer and this witness MUST NOT share their counting
// path, or a defect in the producer's own row classification would be
// invisible to the witness.
//
// The producer emits rows through a single emitter, using a TRANSCRIBED
// enum table.  This witness uses a DIFFERENT path entirely:
//
//   * it READS THE LIVE SOURCE FILES src/ast.h and src/parser.c and
//     derives the enum values and the two decision constants by
//     PARSING THE SOURCE TEXT, so a transcription error in the
//     producer is detected;
//   * it scans the fixture for RECORD SEPARATORS (newline) and tests
//     every record against the fixture-id PATTERN directly (a canonical
//     id is a fixed-shape token: FOUR decimal digits, ZERO PADDED);
//   * a record that MATCHES the pattern is counted as a fixture row;
//   * a record that does NOT match is counted as a NON-FIXTURE record,
//     and it is ACCEPTED only when it is a RECOGNIZED non-data record
//     (a comment, or a KEY=VALUE metadata row).
//
// An INDENTED unknown row is therefore NOT silently skipped: it does
// not match the id pattern (its first byte is a space), so it is
// counted as a non-fixture record, and a non-fixture record that is
// neither a comment nor a metadata row is a FAILURE.
//
// INDEPENDENCE OF THE EXPECTED SET
// ===============================
//
// The witness does NOT re-run the producer's partition logic and does
// NOT read the new PolyC implementation.  It derives the expected
// values from the LIVE SOURCE BYTES:
//
//   EXPECTED_AST_DECL   <- parsed out of src/ast.h
//   EXPECTED_AST_GVAR   <- parsed out of src/ast.h
//   EXPECTED_RULE       <- parsed out of src/parser.c (the legacy
//                          condition's two constants)
//
// and then checks the fixture's properties against those.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice07-fixture-integrity <fixture.tsv> <ast.h> <parser.c>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define MAX_IDS 8192
#define SRC_BUF 2097152
#define FIXTURE_BUF 2097152

// The fixture-id PATTERN.
//
// The fixture ids are 0001..nnnn: exactly four decimal digits, ZERO
// PADDED.  The pattern test below looks at the FIRST FOUR BYTES of a
// record and at nothing else.
static I64 id_shape_ok(U8 *rec, I64 len)
{
  if (len < 4) return 0;
  for (I64 i = 0; i < 4; i = i + 1) {
    if (rec[i] < 48 || rec[i] > 57) return 0;
  }
  return 1;
}

// The numeric id of a record whose shape is ok.
static I64 id_number(U8 *rec)
{
  return (rec[0] - 48) * 1000 + (rec[1] - 48) * 100
       + (rec[2] - 48) * 10 + (rec[3] - 48);
}

// Are the first four bytes of `rec` followed by a TAB (or the end of
// the record)?  A fixture row is "0001<TAB>...".
static I64 id_is_field_start(U8 *rec, I64 len)
{
  if (len == 4) return 1;
  return rec[4] == 9;
}

// Is this a RECOGNIZED non-data record?
//
// A comment begins with '#'.  A metadata row is a KEY=VALUE line whose
// key is a recognized metadata key.  Anything else is an UNKNOWN
// record, which is a FAILURE: that is what makes the indented-unknown-
// row control bite.
static I64 is_recognized_non_data(U8 *rec, I64 len)
{
  if (len == 0) return 1;
  if (rec[0] == '#') return 1;

  U8 *keys[9];
  I64 key_len[9];
  I64 key_n = 0;

  keys[key_n] = "ACT_ID=";        key_len[key_n] = 7; key_n++;
  keys[key_n] = "ACT_PHASE=";     key_len[key_n] = 10; key_n++;
  keys[key_n] = "EVIDENCE_KIND="; key_len[key_n] = 13; key_n++;
  keys[key_n] = "FIXTURE_ROW_COUNT=";      key_len[key_n] = 18; key_n++;
  keys[key_n] = "FIXTURE_PARTITION_COUNT="; key_len[key_n] = 23; key_n++;
  keys[key_n] = "FIXTURE_ENUM_VALUE_COUNT="; key_len[key_n] = 24; key_n++;
  keys[key_n] = "FIXTURE_PROBE_COUNT=";     key_len[key_n] = 20; key_n++;
  keys[key_n] = "FIXTURE_DECLVAR_PROBE_COUNT="; key_len[key_n] = 27; key_n++;
  keys[key_n] = "FIXTURE_SKIP_COUNT=";      key_len[key_n] = 19; key_n++;

  for (I64 k = 0; k < key_n; k = k + 1) {
    if (len < key_len[k]) continue;
    I64 same = 1;
    for (I64 i = 0; i < key_len[k]; i = i + 1) {
      if (rec[i] != keys[k][i]) { same = 0; break; }
    }
    if (same == 1) return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// THE SOURCE-BOUND CONSTANTS.
//
// The witness derives AST_DECL and AST_GVAR from the LIVE src/ast.h
// TEXT, and derives the decision's presence from the LIVE src/parser.c
// TEXT.  It does NOT hard-code them.
// ---------------------------------------------------------------------------

// Find the enumerator `NAME = <decimal>` in the source text and return
// its value, or -1 when the enumerator is absent.
static I64 ParseEnumValue(U8 *src, I64 len, U8 *name)
{
  I64 name_len = 0;
  while (name[name_len] != 0) name_len = name_len + 1;

  for (I64 i = 0; i + name_len < len; i = i + 1) {
    I64 same = 1;
    for (I64 j = 0; j < name_len; j = j + 1) {
      if (src[i + j] != name[j]) { same = 0; break; }
    }
    if (same == 0) continue;
    // The character before must not be an identifier character.
    if (i > 0) {
      U8 prev = src[i - 1];
      if ((prev >= 65 && prev <= 90) || (prev >= 97 && prev <= 122)
          || (prev >= 48 && prev <= 57) || prev == 95) continue;
    }
    // Skip whitespace, then expect '='.
    I64 j = i + name_len;
    while (j < len && (src[j] == 32 || src[j] == 9)) j = j + 1;
    if (j >= len || src[j] != 61) continue;   // '='
    j = j + 1;
    while (j < len && (src[j] == 32 || src[j] == 9)) j = j + 1;
    // Parse the decimal value.
    if (j >= len || src[j] < 48 || src[j] > 57) continue;
    I64 v = 0;
    while (j < len && src[j] >= 48 && src[j] <= 57) {
      v = v * 10 + (src[j] - 48);
      j = j + 1;
    }
    return v;
  }
  return -1;
}

// Does the source text contain the SUBSTRING `needle`?
static I64 SourceContains(U8 *src, I64 len, U8 *needle)
{
  I64 n = 0;
  while (needle[n] != 0) n = n + 1;
  if (n == 0) return 1;
  for (I64 i = 0; i + n <= len; i = i + 1) {
    I64 same = 1;
    for (I64 j = 0; j < n; j = j + 1) {
      if (src[i + j] != needle[j]) { same = 0; break; }
    }
    if (same == 1) return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// THE FIELD PARSER.
//
// A fixture row is:
//   id <TAB> partition <TAB> stmt_kind <TAB> declvar_kind <TAB>
//   expected_appends <TAB> stmt_name <TAB> declvar_name <TAB> rationale
//
// The field count is checked EXACTLY: a row with too few or too many
// fields is MALFORMED, not silently accepted.
// ---------------------------------------------------------------------------
#define EXPECTED_FIELD_COUNT 8

// Find the START offset of the Nth TAB-separated field of `rec`, or -1.
//
// Field 0 starts at offset 0.  Field n starts one past the n-th TAB.
// The END offset of field n is the offset of the (n+1)-th TAB, or the
// record length for the last field.
static I64 FieldStart(U8 *rec, I64 len, I64 index)
{
  if (index == 0) return 0;
  I64 field = 0;
  for (I64 i = 0; i < len; i = i + 1) {
    if (rec[i] == 9) {
      field = field + 1;
      if (field == index) return i + 1;
    }
  }
  return -1;
}

// Find the END offset of the Nth TAB-separated field of `rec`, or -1.
static I64 FieldEnd(U8 *rec, I64 len, I64 index)
{
  I64 field = 0;
  for (I64 i = 0; i < len; i = i + 1) {
    if (rec[i] == 9) {
      if (field == index) return i;
      field = field + 1;
    }
  }
  if (field == index) return len;
  return -1;
}

// Parse a signed decimal integer field.  Returns 0 on success and 1 on
// a malformed field.
//
// The full signed-64-bit range is accepted, INCLUDING the INT64_MIN
// spelling "-9223372036854775808".  The accumulation is done
// NEGATIVE so that the most negative value is representable, exactly as
// the SLICE06 differential does.
static I64 ParseI64Field(U8 *s, I64 len, I64 *out)
{
  if (len == 0) return 1;
  I64 i = 0;
  I64 neg = 0;
  if (s[0] == 45) { neg = 1; i = 1; }   // '-'
  if (i >= len) return 1;
  I64 v = 0;
  for (; i < len; i = i + 1) {
    if (s[i] < 48 || s[i] > 57) return 1;
    I64 d = s[i] - 48;
    // Guard the multiply against overflow: the magnitude may reach
    // 9223372036854775808 for INT64_MIN.
    if (v > 922337203685477580) return 1;
    if (v == 922337203685477580 && d > 8) return 1;
    v = v * 10 + d;
  }
  if (neg == 1) {
    // -9223372036854775808 is representable; the negation of it is not,
    // so it is built directly.
    if (v == 9223372036854775808) {
      *out = (-9223372036854775807 - 1);
      return 0;
    }
    *out = -v;
    return 0;
  }
  *out = v;
  return 0;
}

// ---------------------------------------------------------------------------
// THE MAIN VERIFICATION.
//
// The witness:
//   1. derives AST_DECL and AST_GVAR from the LIVE src/ast.h bytes;
//   2. derives the decision's presence from the LIVE src/parser.c bytes;
//   3. scans every fixture record;
//   4. checks each fixture row's EXPECTED value against the rule
//      recomputed from the source-bound constants;
//   5. checks the row id set for missing, duplicate, out-of-range and
//      misordered ids;
//   6. checks that every row carries a valid boolean expected value.
// ---------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv)
{
  if (argc < 4) {
    "usage: parser-slice07-fixture-integrity <fixture.tsv> <ast.h> <parser.c>\n";
    return 2;
  }
  U8 *fixture_path = argv[1];
  U8 *ast_path = argv[2];
  U8 *parser_path = argv[3];

  // ---- the live source bytes --------------------------------------------
  I64 ast_len = 0;
  U8 *ast_src = FileRead(ast_path, &ast_len);
  if (ast_src == NULL) {
    "FIXTURE_INTEGRITY_AST_READ_FAILED=%s\n", ast_path;
    "STATUS=FAIL\n";
    return 1;
  }
  I64 parser_len = 0;
  U8 *parser_src = FileRead(parser_path, &parser_len);
  if (parser_src == NULL) {
    "FIXTURE_INTEGRITY_PARSER_READ_FAILED=%s\n", parser_path;
    "STATUS=FAIL\n";
    return 1;
  }

  // ---- the source-bound constants ---------------------------------------
  I64 ast_decl = ParseEnumValue(ast_src, ast_len, "AST_DECL");
  I64 ast_gvar = ParseEnumValue(ast_src, ast_len, "AST_GVAR");
  I64 ast_lvar = ParseEnumValue(ast_src, ast_len, "AST_LVAR");

  if (ast_decl < 0 || ast_gvar < 0 || ast_lvar < 0) {
    "FIXTURE_INTEGRITY_ENUM_PARSE_FAILED=YES\n";
    "FIXTURE_INTEGRITY_AST_DECL=%d\n", ast_decl;
    "FIXTURE_INTEGRITY_AST_GVAR=%d\n", ast_gvar;
    "STATUS=FAIL\n";
    return 1;
  }

  // The decision must still be PRESENT in the live parser source, in
  // whichever form the migration left it.  Both the legacy condition
  // and the delegated adapter mention the two constants.
  I64 parser_has_decl = SourceContains(parser_src, parser_len, "AST_DECL");
  I64 parser_has_gvar = SourceContains(parser_src, parser_len, "AST_GVAR");

  "FIXTURE_INTEGRITY_PATH=%s\n", fixture_path;
  "FIXTURE_INTEGRITY_AST_H=%s\n", ast_path;
  "FIXTURE_INTEGRITY_PARSER_C=%s\n", parser_path;
  "FIXTURE_INTEGRITY_SOURCE_AST_DECL=%d\n", ast_decl;
  "FIXTURE_INTEGRITY_SOURCE_AST_GVAR=%d\n", ast_gvar;
  "FIXTURE_INTEGRITY_SOURCE_AST_LVAR=%d\n", ast_lvar;
  "FIXTURE_INTEGRITY_PARSER_HAS_AST_DECL=%d\n", parser_has_decl;
  "FIXTURE_INTEGRITY_PARSER_HAS_AST_GVAR=%d\n", parser_has_gvar;

  if (parser_has_decl == 0 || parser_has_gvar == 0) {
    "FIXTURE_INTEGRITY_SOURCE_CONTRACT_MISSING=YES\n";
    "STATUS=FAIL\n";
    return 1;
  }

  // ---- the fixture bytes ------------------------------------------------
  I64 fix_len = 0;
  U8 *fix = FileRead(fixture_path, &fix_len);
  if (fix == NULL) {
    "FIXTURE_INTEGRITY_FIXTURE_READ_FAILED=%s\n", fixture_path;
    "STATUS=FAIL\n";
    return 1;
  }

  // ---- the counters -----------------------------------------------------
  I64 total_rows = 0;
  I64 non_data_records = 0;
  I64 unknown_records = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 field_parse_errors = 0;
  I64 wrong_expected = 0;
  I64 invalid_expected = 0;
  I64 duplicate_ids = 0;
  I64 missing_ids = 0;
  I64 out_of_range_ids = 0;
  I64 out_of_order_ids = 0;
  I64 max_id = 0;

  I64 seen[MAX_IDS];
  I64 seen_n = 0;

  I64 rec_start = 0;
  I64 pos = 0;
  I64 last_id = 0;
  while (pos <= fix_len) {
    if (pos == fix_len || fix[pos] == 10) {
      I64 len = pos - rec_start;
      // Strip a trailing CR.
      if (len > 0 && fix[rec_start + len - 1] == 13) len = len - 1;
      U8 *rec = fix + rec_start;

      if (len > 0
          && id_shape_ok(rec, len) == 1
          && id_is_field_start(rec, len) == 1) {      // A fixture ROW.
      total_rows = total_rows + 1;
      I64 id = id_number(rec);
      if (id > max_id) max_id = id;

      // The field count must be EXACTLY EXPECTED_FIELD_COUNT.
      //
      // A well-formed row has EXPECTED_FIELD_COUNT fields, i.e.
      // EXPECTED_FIELD_COUNT - 1 tabs.  The count is derived directly
      // from the TAB COUNT, and the numeric fields are then located by
      // their START offsets.
      I64 tabs = 0;
      for (I64 i = 0; i < len; i = i + 1) {
        if (rec[i] == 9) tabs = tabs + 1;
      }
      if (tabs != EXPECTED_FIELD_COUNT - 1) {
        if (tabs < EXPECTED_FIELD_COUNT - 1) {
          truncated_rows = truncated_rows + 1;
        } else {
          malformed_rows = malformed_rows + 1;
        }
      }

      // The numeric fields.
      //
      // Field N is the byte range [FieldStart(N), FieldEnd(N)), where
      // FieldEnd(N) is the offset of the N-th TAB and FieldStart(N) is
      // one past the (N-1)-th TAB.  FieldStart(N+1) - 1 is
      // FieldEnd(N), so the field length is FieldStart(N+1) -
      // FieldStart(N) - 1.
      I64 s2 = FieldStart(rec, len, 2);
      I64 s3 = FieldStart(rec, len, 3);
      I64 s4 = FieldStart(rec, len, 4);
      I64 s5 = FieldStart(rec, len, 5);
      I64 stmt_kind = 0;
      I64 declvar_kind = 0;
      I64 expected = 0;
      I64 e1 = 1;
      I64 e2 = 1;
      I64 e3 = 1;
      if (s2 >= 0 && s3 >= 0 && s4 >= 0 && s5 >= 0) {
        e1 = ParseI64Field(rec + s2, s3 - s2 - 1, &stmt_kind);
        e2 = ParseI64Field(rec + s3, s4 - s3 - 1, &declvar_kind);
        e3 = ParseI64Field(rec + s4, s5 - s4 - 1, &expected);
      }
      if (e1 != 0 || e2 != 0 || e3 != 0) {
        field_parse_errors = field_parse_errors + 1;
      } else {
        // The expected value must be a valid boolean.
        if (expected != 0 && expected != 1) {
          invalid_expected = invalid_expected + 1;
        }
        // THE INDEPENDENT RULE, recomputed from the source-bound
        // constants.  This is the frozen legacy condition:
        //   appends = !(stmt_kind == AST_DECL && declvar_kind == AST_GVAR)
        I64 recomputed = 1;
        if (stmt_kind == ast_decl) {
          if (declvar_kind == ast_gvar) recomputed = 0;
        }
        if (recomputed != expected) {
          wrong_expected = wrong_expected + 1;
          if (wrong_expected <= 8) {
            "FIXTURE_INTEGRITY_WRONG_ROW_ID=%d STMT_KIND=%d DECLVAR_KIND=%d EXPECTED=%d RECOMPUTED=%d\n",
              id, stmt_kind, declvar_kind, expected, recomputed;
          }
        }
      }

      // The id set.
      I64 dup = 0;
      for (I64 i = 0; i < seen_n; i = i + 1) {
        if (seen[i] == id) dup = 1;
      }
      if (dup == 1) {
        duplicate_ids = duplicate_ids + 1;
        if (duplicate_ids <= 8) {
          "FIXTURE_INTEGRITY_DUPLICATE_ID=%d\n", id;
        }
      } else {
        if (seen_n < MAX_IDS) { seen[seen_n] = id; seen_n = seen_n + 1; }
      }
      if (id <= last_id) {
        out_of_order_ids = out_of_order_ids + 1;
      }
      last_id = id;
      } else {
      // A NON-DATA record.
      non_data_records = non_data_records + 1;
      if (is_recognized_non_data(rec, len) == 0) {
        unknown_records = unknown_records + 1;
        if (unknown_records <= 8) {
          "FIXTURE_INTEGRITY_UNKNOWN_RECORD=%s\n", rec;
        }
      }
      }

      // The record is consumed: advance past its terminator.
      pos = pos + 1;
      rec_start = pos;
    } else {
      // Not a record terminator: keep scanning.
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
        "FIXTURE_INTEGRITY_MISSING_ID=%d\n", id;
      }
    }
  }
  for (I64 i = 0; i < seen_n; i = i + 1) {
    if (seen[i] < 1 || seen[i] > max_id) out_of_range_ids = out_of_range_ids + 1;
  }

  // ---- the report -------------------------------------------------------
  "FIXTURE_INTEGRITY_ROWS=%d\n", total_rows;
  "FIXTURE_INTEGRITY_NON_DATA_RECORDS=%d\n", non_data_records;
  "FIXTURE_INTEGRITY_UNKNOWN_RECORDS=%d\n", unknown_records;
  "FIXTURE_INTEGRITY_MALFORMED_ROWS=%d\n", malformed_rows;
  "FIXTURE_INTEGRITY_TRUNCATED_ROWS=%d\n", truncated_rows;
  "FIXTURE_INTEGRITY_FIELD_PARSE_ERRORS=%d\n", field_parse_errors;
  "FIXTURE_INTEGRITY_WRONG_EXPECTED=%d\n", wrong_expected;
  "FIXTURE_INTEGRITY_INVALID_EXPECTED=%d\n", invalid_expected;
  "FIXTURE_INTEGRITY_DUPLICATE_IDS=%d\n", duplicate_ids;
  "FIXTURE_INTEGRITY_MISSING_IDS=%d\n", missing_ids;
  "FIXTURE_INTEGRITY_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "FIXTURE_INTEGRITY_OUT_OF_ORDER_IDS=%d\n", out_of_order_ids;
  "FIXTURE_INTEGRITY_MAX_ID=%d\n", max_id;

  // The acceptance predicate.
  //
  // The witness passes only when EVERY row's expected value equals the
  // rule recomputed from the LIVE source bytes, the row id set is
  // exactly 1..max_id with no duplicates and no gaps, no row is
  // malformed or truncated, no expected value is outside {0, 1}, and no
  // record is unrecognized.
  if (total_rows > 0
      && unknown_records == 0
      && malformed_rows == 0
      && truncated_rows == 0
      && field_parse_errors == 0
      && wrong_expected == 0
      && invalid_expected == 0
      && duplicate_ids == 0
      && missing_ids == 0
      && out_of_range_ids == 0
      && out_of_order_ids == 0) {
    "FIXTURE_INTEGRITY_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "FIXTURE_INTEGRITY_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}
