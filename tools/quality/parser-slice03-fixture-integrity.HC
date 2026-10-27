// tools/quality/parser-slice03-fixture-integrity.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE03 C1 IMPL.
//
// INDEPENDENT FIXTURE-INTEGRITY WITNESS.
//
// WHY A SEPARATE TOOL
// ===================
// ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 REPRODUCED a bypass in the
// CLOSED control-flow-token qualification tool: an INDENTED unknown
// fixture row was silently skipped, so the unknown-id ledger never saw
// it and the differential reported STATUS=PASS.  That tool is closed
// evidence under F14 and MUST NOT be reused as the sole proof
// authority for adversarial fixture completeness.
//
// This witness therefore uses a DIFFERENT COUNTING PATH from the
// differential's row classification.
//
// THE INDEPENDENT PATH
// ===================
// The differential classifies rows with a CONTEXTUAL state machine: a
// row is skippable only when it is an explicitly recognized comment, a
// KEY=VALUE metadata row, or an indented continuation of an OPEN
// metadata block.
//
// This witness counts rows with a WHOLE-FILE BYTE SCAN that has NO
// state machine at all:
//
//   * the file is scanned for RECORD SEPARATORS;
//   * every record is tested against the fixture-id PATTERN directly
//     (a canonical id is a fixed-shape token);
//   * a record that MATCHES the pattern is counted as a fixture row;
//   * a record that does NOT match is counted as a NON-FIXTURE record.
//
// The two counts are then compared with the differential's own count.
//
// The witness also REJECTS an unknown fixture id: an id that matches
// the PATTERN but is OUT OF RANGE is an unknown row, and it is
// reported as a failure.  A row whose shape is right but whose number
// is wrong cannot hide.
//
// USAGE:
//   build/parser-slice03-fixture-integrity <fixture.tsv> <expected_count>
//
// The expected count is the count of mandatory rows.  The tool exits
// with RC=0 when the observed count matches, every observed id is in
// range and unique, and no unknown id was seen; RC=1 otherwise.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define MAX_IDS 4096

// The canonical fixture-id PATTERN.
//
// The fixture ids of this component are F001..F098: a literal 'F'
// followed by exactly three decimal digits, ZERO PADDED.  The pattern
// test below is INDEPENDENT of any row classification: it looks at
// the FIRST FOUR BYTES of a record and at nothing else.
//
// A record whose id does NOT match the pattern is NOT a fixture row.
// It is counted as a non-fixture record.  The witness reports both
// counts so that the two can be compared.
//
// The digits may be zero-padded: the range check in the caller is what
// rejects an out-of-range id, and it is that check -- not the shape --
// that produces the UNKNOWN-ID failure.
I64 id_shape_ok(U8 *rec, I64 len)
{
  if (len < 4) return 0;
  if (rec[0] != 70) return 0;                 // 'F'
  if (rec[1] < 48 || rec[1] > 57) return 0;   // '0'..'9'
  if (rec[2] < 48 || rec[2] > 57) return 0;   // '0'..'9'
  if (rec[3] < 48 || rec[3] > 57) return 0;   // '0'..'9'
  return 1;
}

// The numeric id of a record whose shape is ok.
I64 id_number(U8 *rec)
{
  return (rec[1] - 48) * 100 + (rec[2] - 48) * 10 + (rec[3] - 48);
}

// Are the first four bytes of `rec` followed by a TAB (or the end of
// the record)?  A fixture row is "F001<TAB>...".  A record that merely
// STARTS with "F001" but is not a row (for example the word "F0012")
// is not a fixture row.
I64 id_is_field_start(U8 *rec, I64 len)
{
  if (len == 4) return 1;
  if (rec[4] == 9) return 1;                  // TAB
  return 0;
}

// Is this record a RECOGNIZED non-data record?
//
// The only non-data records the fixture format permits are
//
//   * a COMMENT: the record begins with '#';
//   * a METADATA row: the record begins with a KEY=VALUE pair, i.e.
//     an '=' occurs in the FIRST field, before the first TAB.
//
// The '=' test is scoped to the first field because a data row's rationale
// may legitimately contain an '=' (for example "tok == NULL returns 0"),
// so scanning the whole record would misclassify a data row.
//
// NOTE: an INDENTED continuation line is NOT a recognized non-data
// record here.  That is deliberate.  The bypass that
// ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 reproduced was exactly an
// indented unknown row being skipped, so this witness treats an
// indented row as an UNKNOWN ROW unless it is a comment.
I64 is_recognized_non_data(U8 *rec, I64 len)
{
  if (len == 0) return 1;
  if (rec[0] == 35) return 1;                  // '#'
  // A KEY=VALUE metadata row: an '=' in the first field.
  I64 i = 1;
  while (i < len && rec[i] != 9) {
    if (rec[i] == 61) return 1;                // '='
    i = i + 1;
  }
  return 0;
}

I64 main(I64 argc, U8 **argv)
{
  if (argc != 3) {
    printf("usage: %s <fixture.tsv> <expected_count>\n", argv[0]);
    return 2;
  }

  I64 expected = 0;
  {
    U8 *q = argv[2];
    I64 v = 0;
    I64 digits = 0;
    while (*q >= 48 && *q <= 57) {
      v = v * 10 + (*q - 48);
      digits = digits + 1;
      q = q + 1;
    }
    if (digits == 0) {
      printf("ERROR: the expected count is not a number\n");
      return 2;
    }
    expected = v;
  }

  I64 fsz = 0;
  U8 *ftxt = FileRead(argv[1], &fsz);
  if (ftxt == 0) {
    printf("ERROR: cannot read %s\n", argv[1]);
    return 2;
  }

  // The observed ids.
  I64 seen[MAX_IDS];
  I64 i = 0;
  while (i < MAX_IDS) { seen[i] = 0; i = i + 1; }

  // THE INDEPENDENT WHOLE-FILE SCAN.
  //
  // The file is walked record by record.  A record ends at a newline
  // or at the end of the file.  There is NO state machine and NO
  // metadata block: the only question asked of a record is whether its
  // FIRST FOUR BYTES match the fixture-id pattern AND it is followed by
  // a field separator.
  I64 fixture_rows = 0;
  I64 nonfixture_records = 0;
  I64 unknown_ids = 0;
  I64 unknown_rows = 0;
  I64 rec_no = 0;
  I64 duplicate_ids = 0;
  I64 out_of_range = 0;

  I64 rec_start = 0;
  i = 0;
  while (i <= fsz) {
    // Is the record finished?
    if (i == fsz || ftxt[i] == 10) {
      I64 rec_len = i - rec_start;
      // Strip a trailing carriage return.
      if (rec_len > 0 && ftxt[rec_start + rec_len - 1] == 13) rec_len = rec_len - 1;
      if (rec_len > 0) {
        if (id_shape_ok(ftxt + rec_start, rec_len)
            && id_is_field_start(ftxt + rec_start, rec_len)) {
          fixture_rows = fixture_rows + 1;
          I64 n = id_number(ftxt + rec_start);
          if (n < 1 || n > expected) {
            // The id is OUT OF RANGE: it is an unknown row.
            unknown_ids = unknown_ids + 1;
            out_of_range = out_of_range + 1;
            printf("FIXTURE_ID_UNKNOWN=%d\n", n);
          } else if (n <= MAX_IDS) {
            if (seen[n] > 0) {
              duplicate_ids = duplicate_ids + 1;
              printf("FIXTURE_ID_DUPLICATE=%d\n", n);
            }
            seen[n] = seen[n] + 1;
          }
        } else {
          // The record is NOT a fixture row.  It is acceptable only if
          // it is a RECOGNIZED non-data record: a comment, or a
          // KEY=VALUE metadata row.
          //
          // EVERY OTHER record is an UNKNOWN ROW and is REJECTED.
          //
          // This is the check that closes the bypass class that
          // ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 reproduced: a row
          // whose id does not match the canonical pattern (for example
          // "X001") must NOT be silently skipped.  An earlier revision
          // of this witness counted such a row as a non-fixture record
          // and reported STATUS=PASS for a fixture that carried it.
          if (is_recognized_non_data(ftxt + rec_start, rec_len)) {
            nonfixture_records = nonfixture_records + 1;
          } else {
            unknown_rows = unknown_rows + 1;
            printf("FIXTURE_ROW_UNKNOWN at record %d\n", rec_no);
          }
        }
      }
      rec_no = rec_no + 1;
      rec_start = i + 1;
    }
    i = i + 1;
  }

  // The number of DISTINCT canonical ids observed.
  I64 distinct = 0;
  I64 missing = 0;
  i = 1;
  while (i <= expected) {
    if (i < MAX_IDS && seen[i] > 0) distinct = distinct + 1;
    else missing = missing + 1;
    i = i + 1;
  }

  printf("FIXTURE_INTEGRITY_OBSERVED_ROWS=%d\n", fixture_rows);
  printf("FIXTURE_INTEGRITY_DISTINCT_IDS=%d\n", distinct);
  printf("FIXTURE_INTEGRITY_EXPECTED_ROWS=%d\n", expected);
  printf("FIXTURE_INTEGRITY_NONFIXTURE_RECORDS=%d\n", nonfixture_records);
  printf("FIXTURE_INTEGRITY_UNKNOWN_IDS=%d\n", unknown_ids);
  printf("FIXTURE_INTEGRITY_DUPLICATE_IDS=%d\n", duplicate_ids);
  printf("FIXTURE_INTEGRITY_MISSING_IDS=%d\n", missing);
  printf("FIXTURE_INTEGRITY_UNKNOWN_ROWS=%d\n", unknown_rows);

  Free(ftxt);

  // The verdict.  Every one of these must hold:
  //   * the observed row count equals the expected count;
  //   * every expected id is present exactly once;
  //   * no unknown id was seen.
  if (fixture_rows == expected && distinct == expected && missing == 0
      && unknown_ids == 0 && duplicate_ids == 0 && unknown_rows == 0) {
    printf("STATUS=PASS\n");
    return 0;
  }
  printf("STATUS=FAIL\n");
  return 1;
}
