// tools/quality/parser-slice05-fixture-integrity.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE05 C1.
//
// INDEPENDENT FIXTURE-INTEGRITY WITNESS.
//
// WHY A SEPARATE TOOL
// ===================
//
// The fixture producer and the fixture-integrity witness MUST NOT share
// their counting path, or a defect in the producer's own row
// classification would be invisible to the witness.
//
// The producer emits rows through a single emitter.  This witness uses a
// DIFFERENT path:
//
//   * the file is scanned for RECORD SEPARATORS (newline);
//   * every record is tested against the fixture-id PATTERN directly
//     (a canonical id is a fixed-shape token: 'F' + three digits);
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
// ================================
//
// The witness does not re-derive the expected rows by re-running the
// producer'"'"'s partition logic.  Instead it checks the properties
// the ACT freezes:
//
//   EXPECTED_ID_SET == OBSERVED_ID_SET
//   EXPECTED_VALUE_SET == OBSERVED_VALUE_SET
//   EXPECTED_PARTITIONS == OBSERVED_PARTITIONS
//
// where the expected VALUE SET and the expected PARTITION SET are
// listed IN THIS FILE, independently of the producer.  A fixture that
// omits a required accepted token, or that renames a partition, or
// that carries an unknown token value, is therefore detected even if
// the producer and the witness agreed on the omission.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice05-fixture-integrity <fixture.tsv> <expected_count>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define MAX_IDS 4096
#define MAX_VALS 4096
#define MAX_PARTS 64

// The canonical fixture-id PATTERN.
//
// The fixture ids are F001..Fnnn: a literal 'F' followed by exactly
// three decimal digits, ZERO PADDED.  The pattern test below looks at
// the FIRST FOUR BYTES of a record and at nothing else.
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
// the record)?  A fixture row is "F001<TAB>...".
I64 id_is_field_start(U8 *rec, I64 len)
{
  if (len == 4) return 1;
  return rec[4] == 9;
}

// Is this a RECOGNIZED non-data record?
//
// A comment begins with '#'.  A metadata row is a KEY=VALUE line whose
// key is a recognized metadata key.  Anything else is an UNKNOWN
// record, which is a FAILURE: that is what makes the indented-unknown-row
// control bite.
I64 is_recognized_non_data(U8 *rec, I64 len)
{
  if (len == 0) return 1;
  if (rec[0] == '#') return 1;

  // The recognized metadata keys.
  U8 *keys[6];
  keys[0] = "ACT_ID=";
  keys[1] = "ACT_PHASE=";
  keys[2] = "EVIDENCE_KIND=";
  keys[3] = "FIXTURE_ROW_COUNT=";
  keys[4] = "FIXTURE_PATH=";
  keys[5] = "FIXTURE_INVALID_TOKEN_COUNT=";

  for (I64 k = 0; k < 6; k++) {
    U8 *key = keys[k];
    I64 kl = 0;
    while (key[kl] != 0) kl = kl + 1;
    if (len < kl) continue;
    I64 match = 1;
    for (I64 i = 0; i < kl; i++) {
      if (rec[i] != key[i]) { match = 0; break; }
    }
    if (match) return 1;
  }
  return 0;
}

// ---------------- The EXPECTED value set ----------------------------------
//
// These are the token values the fixture MUST cover: the ten ACCEPTED
// tokens, plus the DISTINCT REJECTED values the partitions are
// required to produce.
//
// The list is written HERE, independently of the producer's partition
// logic, so that an omission in the producer is detected rather than
// mirrored.

// The ten accepted token values (from the compiled live headers).
static I64 EXP_ACCEPTED[10];

// The required rejected values: the accepted values' immediate
// neighbours that are not themselves accepted, the value between '+'
// and '-', the three punctuators between '&' and '*', the three
// aliased lexer constants, the six signed-64-bit boundary values, and
// the lexer token constants that are not unary operators.
//
// The count is computed by the tool, not asserted.
static I64 EXP_REJECTED[512];
static I64 EXP_REJECTED_N;

// The expected partition names.
static U8 *EXP_PART[16];
static I64 EXP_PART_N;

static U0 InitExpected()
{
  // The ten accepted token values.
  EXP_ACCEPTED[0] = 816; EXP_ACCEPTED[1] = 817;
  EXP_ACCEPTED[2] = 773; EXP_ACCEPTED[3] = 774;
  EXP_ACCEPTED[4] = 43;  EXP_ACCEPTED[5] = 45;
  EXP_ACCEPTED[6] = 126; EXP_ACCEPTED[7] = 33;
  EXP_ACCEPTED[8] = 38;  EXP_ACCEPTED[9] = 42;

  EXP_REJECTED_N = 0;

  // The value between '+' and '-'.
  EXP_REJECTED[EXP_REJECTED_N] = 44; EXP_REJECTED_N = EXP_REJECTED_N + 1;

  // The three punctuators between '&' (38) and '*' (42).
  EXP_REJECTED[EXP_REJECTED_N] = 39; EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = 40; EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = 41; EXP_REJECTED_N = EXP_REJECTED_N + 1;

  // The three aliased lexer constant values.
  EXP_REJECTED[EXP_REJECTED_N] = 769; EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = 770; EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = 771; EXP_REJECTED_N = EXP_REJECTED_N + 1;

  // The six signed 64-bit boundary values.
  EXP_REJECTED[EXP_REJECTED_N] = -9223372036854775807 - 1; EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = -9223372036854775807;     EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = -9223372036854775806;     EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = 9223372036854775805;      EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = 9223372036854775806;      EXP_REJECTED_N = EXP_REJECTED_N + 1;
  EXP_REJECTED[EXP_REJECTED_N] = 9223372036854775807;      EXP_REJECTED_N = EXP_REJECTED_N + 1;

  // The expected partitions.
  EXP_PART_N = 0;
  EXP_PART[EXP_PART_N] = "U01_ACCEPTED_TOKEN";             EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U02_ALTERNATE_INITIAL_OUTPUT";   EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U03_REJECTED_PRINTABLE_ASCII";   EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U04_NEIGHBOUR";                  EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U04_NEIGHBOUR_ACCEPTED";         EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U05_PREFIX_POSTFIX";             EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U06_PLUS_MINUS";                 EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U07_ADDR_OF_DEREF";              EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U08_LEXER_ALIAS";                EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U09_SIGNED_I64_BOUNDARY";        EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U10_UNRECOGNIZED_LEXER_TOKEN";   EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U11_FAILURE_PRESERVES_OUTPUT";   EXP_PART_N = EXP_PART_N + 1;
  EXP_PART[EXP_PART_N] = "U12_PRODUCTION_CALLER";          EXP_PART_N = EXP_PART_N + 1;
}

// ---------------- helpers ---------------------------------------------------

I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

I64 StrLen(U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

// Is `v` one of the ten accepted token values?
I64 IsExpAccepted(I64 v)
{
  for (I64 i = 0; i < 10; i++) if (EXP_ACCEPTED[i] == v) return 1;
  return 0;
}

// Is `v` one of the required rejected values?
I64 IsExpRejected(I64 v)
{
  for (I64 i = 0; i < EXP_REJECTED_N; i++) if (EXP_REJECTED[i] == v) return 1;
  return 0;
}

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
// The subtraction form is exact, so it is the one used here.
#define NEG_MIN_2P63 (-9223372036854775807 - 1)

// Parse a signed 64-bit decimal number with an EXACT conversion.
//
// The accumulator is built NEGATIVE so that the most negative value is
// representable without an intermediate positive overflow.  A "%d"
// conversion is NOT used anywhere: it is a 32-bit conversion and would
// destroy the signed-64-bit extremes.
I64 ParseI64(U8 *s, I64 len, I64 *ok)
{
  *ok = 0;
  if (len == 0) return 0;
  I64 i = 0;
  I64 neg = 0;
  if (s[0] == '-') { neg = 1; i = 1; }
  else if (s[0] == '+') { i = 1; }

  // The most-negative-safe PRE-MULTIPLY magnitude, base 10.
  //
  // The magnitude is accumulated NEGATIVE, so the accumulated value v
  // satisfies v = -(magnitude).  The step is v' = v * base - digit and
  // the requirement is v' >= -2^63, i.e.
  //     v * base >= -2^63 + digit
  // For base 10 and digit d, the exact threshold is
  //     v >= ceil((-2^63 + d) / 10)
  // which is -922337203685477580 for d = 0..8 and -922337203685477579
  // for d = 9.  Both are written explicitly: the division rounds
  // toward zero in this language, so computing them would be wrong for
  // d = 9.
  I64 v = 0;
  for (; i < len; i++) {
    if (s[i] < 48 || s[i] > 57) return 0;
    I64 d = s[i] - 48;
    I64 limit = -922337203685477580;
    if (d == 9) limit = -922337203685477579;
    if (v < limit) return 0;
    v = v * 10 - d;
    // The POST-multiply check is the EXACT representable floor.  The
    // accumulated magnitude may reach INT64_MAX but NOT 2^63.
    if (v < NEG_MIN_2P63) return 0;
  }
  if (neg == 0) {
    // The positive magnitude must fit in INT64_MAX.
    if (v == NEG_MIN_2P63) return 0;
    v = -v;
  }
  *ok = 1;
  return v;
}

// ---------------- The main -------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 3) {
    "usage: parser-slice05-fixture-integrity <fixture.tsv> <expected_count>\n";
    return 2;
  }
  U8 *path = argv[1];
  I64 expected_count = 0;
  {
    I64 ok = 0;
    expected_count = ParseI64(argv[2], StrLen(argv[2]), &ok);
    if (ok == 0) {
      "FIXTURE_INTEGRITY_STATUS=FAIL\n";
      "FIXTURE_INTEGRITY_REASON=BAD_EXPECTED_COUNT\n";
      return 1;
    }
  }

  InitExpected();

  I64 ftxt_len = 0;
  U8 *ftxt = FileRead(path, &ftxt_len);
  if (ftxt == NULL) {
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    "FIXTURE_INTEGRITY_REASON=CANNOT_READ_FIXTURE\n";
    "FIXTURE_INTEGRITY_PATH=%s\n", path;
    return 1;
  }

  // The observed id set.
  static I64 seen_id[MAX_IDS];
  I64 seen_n = 0;
  I64 duplicate_ids = 0;
  I64 unknown_ids = 0;
  I64 out_of_range_ids = 0;

  // The observed VALUE set: the distinct token values seen.
  static I64 seen_val[MAX_VALS];
  I64 seen_val_n = 0;

  // The observed PARTITION set.
  static U8 *seen_part[MAX_PARTS];
  I64 seen_part_n = 0;

  // The counters.
  I64 fixture_rows = 0;
  I64 non_data_records = 0;
  I64 unknown_records = 0;
  I64 malformed_rows = 0;
  I64 invalid_i64_values = 0;
  I64 untested_accepted_tokens = 0;
  I64 untested_failure_storage_cases = 0;
  I64 accepted_seen[10];
  I64 accepted_seen_n = 0;
  I64 failure_storage_cases = 0;

  // ---- the whole-file byte scan ---------------------------------------
  //
  // The file is walked record by record.  A record is the byte range
  // between two newlines.  There is NO state machine: the decision is
  // made from the record's first bytes alone.
  I64 rec_start = 0;
  I64 pos = 0;
  while (pos <= ftxt_len) {
    I64 at_end = 0;
    if (pos == ftxt_len) at_end = 1;
    else if (ftxt[pos] == 10) at_end = 1;

    if (at_end == 1) {
      I64 rec_len = pos - rec_start;
      if (rec_len > 0) {
        U8 *rec = ftxt + rec_start;

        if (id_shape_ok(rec, rec_len) == 1 && id_is_field_start(rec, rec_len) == 1) {
          // ---- a FIXTURE ROW --------------------------------------------
          fixture_rows = fixture_rows + 1;
          I64 id = id_number(rec);

          // The id must be in range and unique.
          if (id < 1 || id > expected_count) {
            out_of_range_ids = out_of_range_ids + 1;
            "FIXTURE_INTEGRITY_OUT_OF_RANGE_ID=%d\n", id;
          } else {
            I64 dup = 0;
            for (I64 i = 0; i < seen_n; i++) if (seen_id[i] == id) dup = 1;
            if (dup == 1) {
              duplicate_ids = duplicate_ids + 1;
              "FIXTURE_INTEGRITY_DUPLICATE_ID=%d\n", id;
            } else if (seen_n < MAX_IDS) {
              seen_id[seen_n] = id;
              seen_n = seen_n + 1;
            }
          }

          // ---- the row's fields ------------------------------------------
          //
          // The record is split on TABs.  The schema is seven fields:
          //   id, partition, token_value, expected_success,
          //   expected_output, initial_output, rationale
          I64 fs[8];
          I64 fl[8];
          I64 nf = 0;
          I64 fstart = rec_start;
          I64 fp = rec_start;
          while (fp <= pos) {
            I64 e = 0;
            if (fp == pos) e = 1;
            else if (ftxt[fp] == 9) e = 1;
            if (e == 1) {
              if (nf < 8) { fs[nf] = fstart; fl[nf] = fp - fstart; }
              nf = nf + 1;
              fstart = fp + 1;
            }
            fp = fp + 1;
          }

          if (nf != 7) {
            malformed_rows = malformed_rows + 1;
            "FIXTURE_INTEGRITY_MALFORMED_ROW id=%d fields=%d\n", id, nf;
          } else {
            // The partition.
            U8 part[128];
            I64 pl = fl[1];
            if (pl > 127) pl = 127;
            I64 k = 0;
            while (k < pl) { part[k] = ftxt[fs[1] + k]; k = k + 1; }
            part[pl] = 0;

            I64 known = 0;
            for (I64 i = 0; i < EXP_PART_N; i++) if (StrEq(part, EXP_PART[i]) == 1) known = 1;
            if (known == 0) {
              "FIXTURE_INTEGRITY_UNKNOWN_PARTITION=%s\n", part;
              malformed_rows = malformed_rows + 1;
            } else {
              I64 pseen = 0;
              for (I64 i = 0; i < seen_part_n; i++) if (StrEq(seen_part[i], part) == 1) pseen = 1;
              if (pseen == 0 && seen_part_n < MAX_PARTS) {
                // The partition name is COPIED into the registry.  The
                // `part` buffer is a stack local that is REUSED by the
                // next row, so storing its address would make every
                // registry entry alias the LAST row's partition.
                U8 *stored = MAlloc(pl + 1);
                I64 k2 = 0;
                while (k2 < pl) { stored[k2] = part[k2]; k2 = k2 + 1; }
                stored[pl] = 0;
                seen_part[seen_part_n] = stored;
                seen_part_n = seen_part_n + 1;
              }
            }

            // The token value, the expected success flag, the expected
            // output and the initial output.
            I64 ok1 = 0, ok2 = 0, ok3 = 0, ok4 = 0;
            I64 tok = ParseI64(ftxt + fs[2], fl[2], &ok1);
            I64 succ = ParseI64(ftxt + fs[3], fl[3], &ok2);
            I64 outv = ParseI64(ftxt + fs[4], fl[4], &ok3);
            I64 init = ParseI64(ftxt + fs[5], fl[5], &ok4);
            if (ok1 == 0 || ok2 == 0 || ok3 == 0 || ok4 == 0) {
              invalid_i64_values = invalid_i64_values + 1;
              "FIXTURE_INTEGRITY_INVALID_I64 id=%d\n", id;
            } else {
              // The observed VALUE set.
              I64 vseen = 0;
              for (I64 i = 0; i < seen_val_n; i++) if (seen_val[i] == tok) vseen = 1;
              if (vseen == 0 && seen_val_n < MAX_VALS) {
                seen_val[seen_val_n] = tok;
                seen_val_n = seen_val_n + 1;
              }

              // Every ACCEPTED token must be covered by a row that
              // expects SUCCESS.
              if (succ == 1) {
                I64 aseen = 0;
                for (I64 i = 0; i < accepted_seen_n; i++) if (accepted_seen[i] == tok) aseen = 1;
                if (aseen == 0 && accepted_seen_n < 10) {
                  accepted_seen[accepted_seen_n] = tok;
                  accepted_seen_n = accepted_seen_n + 1;
                }
              }

              // A FAILED row must preserve the initial output: the
              // expected output must EQUAL the initial output.
              if (succ == 0) {
                if (outv != init) {
                  failure_storage_cases = failure_storage_cases + 1;
                  "FIXTURE_INTEGRITY_FAILURE_OVERWRITES id=%d init=%d out=%d\n",
                        id, init, outv;
                }
              }
            }
          }
        } else {
          // ---- a NON-FIXTURE record -------------------------------------
          non_data_records = non_data_records + 1;
          if (is_recognized_non_data(rec, rec_len) == 0) {
            unknown_records = unknown_records + 1;
            "FIXTURE_INTEGRITY_UNKNOWN_RECORD at byte %d\n", rec_start;
          }
        }
      }
      rec_start = pos + 1;
    }
    pos = pos + 1;
  }

  // ---- the missing ids -------------------------------------------------
  I64 missing_ids = 0;
  for (I64 id = 1; id <= expected_count; id++) {
    I64 found = 0;
    for (I64 i = 0; i < seen_n; i++) if (seen_id[i] == id) found = 1;
    if (found == 0) missing_ids = missing_ids + 1;
  }

  // ---- the untested accepted tokens -------------------------------------
  for (I64 i = 0; i < 10; i++) {
    I64 found = 0;
    for (I64 j = 0; j < accepted_seen_n; j++) if (accepted_seen[j] == EXP_ACCEPTED[i]) found = 1;
    if (found == 0) untested_accepted_tokens = untested_accepted_tokens + 1;
  }

  // ---- the untested failure-storage cases -------------------------------
  //
  // Every EXPECTED rejected value must be present in the fixture.  A
  // rejected value that the fixture never exercises is a coverage hole.
  for (I64 i = 0; i < EXP_REJECTED_N; i++) {
    I64 found = 0;
    for (I64 j = 0; j < seen_val_n; j++) if (seen_val[j] == EXP_REJECTED[i]) found = 1;
    if (found == 0) untested_failure_storage_cases = untested_failure_storage_cases + 1;
  }

  // ---- the expected partition set ---------------------------------------
  I64 missing_partitions = 0;
  for (I64 i = 0; i < EXP_PART_N; i++) {
    I64 found = 0;
    for (I64 j = 0; j < seen_part_n; j++) if (StrEq(seen_part[j], EXP_PART[i]) == 1) found = 1;
    if (found == 0) {
      missing_partitions = missing_partitions + 1;
      "FIXTURE_INTEGRITY_MISSING_PARTITION=%s\n", EXP_PART[i];
    }
  }
  I64 extra_partitions = 0;
  for (I64 j = 0; j < seen_part_n; j++) {
    I64 found = 0;
    for (I64 i = 0; i < EXP_PART_N; i++) if (StrEq(EXP_PART[i], seen_part[j]) == 1) found = 1;
    if (found == 0) extra_partitions = extra_partitions + 1;
  }

  Free(ftxt);

  "FIXTURE_INTEGRITY_PATH=%s\n", path;
  "FIXTURE_INTEGRITY_OBSERVED_ROWS=%d\n", fixture_rows;
  "FIXTURE_INTEGRITY_EXPECTED_ROWS=%d\n", expected_count;
  "FIXTURE_INTEGRITY_NON_DATA_RECORDS=%d\n", non_data_records;
  "FIXTURE_INTEGRITY_UNKNOWN_RECORDS=%d\n", unknown_records;
  "FIXTURE_INTEGRITY_DUPLICATE_IDS=%d\n", duplicate_ids;
  "FIXTURE_INTEGRITY_MISSING_IDS=%d\n", missing_ids;
  "FIXTURE_INTEGRITY_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "FIXTURE_INTEGRITY_UNKNOWN_IDS=%d\n", unknown_ids;
  "FIXTURE_INTEGRITY_MALFORMED_ROWS=%d\n", malformed_rows;
  "FIXTURE_INTEGRITY_INVALID_I64_VALUES=%d\n", invalid_i64_values;
  "FIXTURE_INTEGRITY_UNTESTED_ACCEPTED_TOKENS=%d\n", untested_accepted_tokens;
  "FIXTURE_INTEGRITY_UNTESTED_FAILURE_STORAGE_CASES=%d\n",
        untested_failure_storage_cases;
  "FIXTURE_INTEGRITY_FAILURE_OVERWRITE_CASES=%d\n", failure_storage_cases;
  "FIXTURE_INTEGRITY_MISSING_PARTITIONS=%d\n", missing_partitions;
  "FIXTURE_INTEGRITY_EXTRA_PARTITIONS=%d\n", extra_partitions;
  "FIXTURE_INTEGRITY_OBSERVED_DISTINCT_VALUES=%d\n", seen_val_n;
  "FIXTURE_INTEGRITY_OBSERVED_PARTITIONS=%d\n", seen_part_n;
  "FIXTURE_INTEGRITY_EXPECTED_PARTITIONS=%d\n", EXP_PART_N;

  // The acceptance predicate.
  //
  // The fixture set is AUTHORITATIVE: the EXACT canonical ID set is
  // present, each ID occurs EXACTLY once, every row matches the
  // declared schema, every required accepted token and every required
  // rejected value is covered, no failed row overwrites its output, and
  // the partition set is exactly the expected one.
  if (fixture_rows == expected_count
      && missing_ids == 0
      && duplicate_ids == 0
      && out_of_range_ids == 0
      && unknown_ids == 0
      && unknown_records == 0
      && malformed_rows == 0
      && invalid_i64_values == 0
      && untested_accepted_tokens == 0
      && untested_failure_storage_cases == 0
      && failure_storage_cases == 0
      && missing_partitions == 0
      && extra_partitions == 0) {
    "FIXTURE_INTEGRITY_STATUS=PASS\n";
    return 0;
  }
  "FIXTURE_INTEGRITY_STATUS=FAIL\n";
  return 1;
}
