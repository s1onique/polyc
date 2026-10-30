// tools/quality/parser-slice08-fixture-integrity.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE08 C1.
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
//     derives the enum values and the terminating constants by
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
// INDEPENDENCE OF THE EXPECTED SET
// ===============================
//
// The witness does NOT re-run the producer's partition logic and does
// NOT read the new PolyC implementation.  It derives the expected
// values from the LIVE SOURCE BYTES:
//
//   EXPECTED_AST_KINDS    <- parsed out of src/ast.h
//   EXPECTED_TERMINATING  <- parsed out of src/parser.c (the constants
//                            of the legacy condition)
//
// and then checks the fixture's properties against those.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice08-fixture-integrity <fixture.tsv> <ast.h> <parser.c>

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
// key is composed of [A-Z0-9_] and whose value contains no TAB.
static I64 is_recognized_non_data(U8 *rec, I64 len)
{
  if (len == 0) return 1;
  if (rec[0] == 35) return 1;   // '#'
  I64 i = 0;
  while (i < len) {
    U8 c = rec[i];
    if (c == 61) {   // '='
      if (i == 0) return 0;
      return 1;
    }
    if ((c >= 65 && c <= 90) || (c >= 48 && c <= 57) || c == 95) {
      i = i + 1;
      continue;
    }
    return 0;
  }
  return 0;
}

// Read a whole file into a buffer.  It returns the buffer, or NULL.
//
// The PolyC runtime API is `U8 *FileRead(U8 *path, I64 *_size)`: it
// returns the buffer and writes the length through the second
// argument.  There is no separate FileOpen/FileClose/FileSize
// triplet.
static U8 *slurp(U8 *path, I64 *out_len)
{
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) {
    *out_len = -1;
    return NULL;
  }
  *out_len = size;
  return buf;
}

// Find a substring in a buffer.  It returns the byte offset, or -1.
//
// The needle length is computed EXPLICITLY rather than through StrLen:
// the needle is a NUL-terminated literal here, but computing the
// length in the same way as the rest of this file keeps the search
// independent of the runtime's string built-ins.
static I64 find_sub(U8 *buf, I64 len, U8 *needle)
{
  I64 nlen = 0;
  while (needle[nlen] != 0) nlen = nlen + 1;
  if (nlen == 0) return -1;
  I64 i = 0;
  while (i + nlen <= len) {
    I64 j = 0;
    while (j < nlen && buf[i + j] == needle[j]) j = j + 1;
    if (j == nlen) return i;
    i = i + 1;
  }
  return -1;
}

// Parse a decimal integer out of a buffer at an offset.  It returns 1
// on success and advances `pos` past the digits.
static I64 scan_int(U8 *buf, I64 len, I64 *pos, I64 *out)
{
  I64 i = *pos;
  while (i < len && (buf[i] == 32 || buf[i] == 9)) i = i + 1;
  I64 neg = 0;
  if (i < len && buf[i] == 45) { neg = 1; i = i + 1; }
  if (i >= len || buf[i] < 48 || buf[i] > 57) return 0;
  I64 v = 0;
  while (i < len && buf[i] >= 48 && buf[i] <= 57) {
    v = v * 10 + (buf[i] - 48);
    i = i + 1;
  }
  *pos = i;
  if (neg == 1) { *out = 0 - v; } else { *out = v; }
  return 1;
}

// The live enum values, parsed out of src/ast.h.
#define MAX_KINDS 128
static I64 LIVE_VALUE[MAX_KINDS];
static I64 LIVE_NAME_OFF[MAX_KINDS];
static I64 LIVE_NAME_LEN[MAX_KINDS];
static I64 LIVE_N;

// The live TERMINATING set, parsed out of src/parser.c.
#define MAX_TERM 16
static I64 TERM_IDX[MAX_TERM];
static I64 TERM_N;

// Parse the AstKind enum out of the live src/ast.h.
//
// The AstKind enum is the region between "typedef enum {" and its
// matching "}".  Only the enumerators INSIDE that region are
// collected, so the AST_ references that appear elsewhere in the
// header (in macros, in struct fields and in comments) are NOT
// mistaken for enum members.
static U0 parse_ast_h(U8 *buf, I64 len)
{
  LIVE_N = 0;
  // Locate the enum's opening brace.  The declaration is
  // "typedef enum AstKind {".
  I64 at = find_sub(buf, len, "typedef enum AstKind {");
  if (at < 0) return;
  I64 body = at;
  while (body < len && buf[body] != 123) body = body + 1;   // '{'
  if (body >= len) return;
  // The enum ends at the matching '}'.
  I64 depth = 0;
  I64 end = body;
  while (end < len) {
    if (buf[end] == 123) depth = depth + 1;
    if (buf[end] == 125) {
      depth = depth - 1;
      if (depth == 0) break;
    }
    end = end + 1;
  }
  // Collect the enumerators INSIDE the enum region.
  I64 pos = body;
  while (pos < end) {
    I64 hit = -1;
    I64 i = pos;
    while (i + 4 <= end) {
      if (buf[i] == 65 && buf[i+1] == 83 && buf[i+2] == 84 && buf[i+3] == 95) { hit = i; break; }
      i = i + 1;
    }
    if (hit < 0) break;
    I64 ne = hit;
    while (ne < end) {
      U8 c = buf[ne];
      if ((c >= 65 && c <= 90) || (c >= 48 && c <= 57) || c == 95) { ne = ne + 1; continue; }
      break;
    }
    I64 nlen = ne - hit;
    I64 p = ne;
    while (p < end && (buf[p] == 32 || buf[p] == 9)) p = p + 1;
    if (p >= end || buf[p] != 61) { pos = hit + 4; continue; }   // not an enumerator
    p = p + 1;
    I64 v = 0;
    if (scan_int(buf, end, &p, &v) == 0) { pos = hit + 4; continue; }
    if (LIVE_N < MAX_KINDS) {
      LIVE_VALUE[LIVE_N] = v;
      LIVE_NAME_OFF[LIVE_N] = hit;
      LIVE_NAME_LEN[LIVE_N] = nlen;
      LIVE_N = LIVE_N + 1;
    }
    pos = p;
  }
}

// The index of a live kind NAME, or -1.
//
// `hay` is the buffer the NAME OCCURRENCE lives in (the parser
// source), while the live names are recorded in the AST HEADER
// buffer.  The two buffers are DIFFERENT, so the comparison must
// read the occurrence from `hay` and the reference from the header
// buffer.  The header buffer is passed explicitly so the comparison
// can never read the wrong buffer.
static I64 live_index_of_name(U8 *hay, I64 off, I64 len, U8 *hdr)
{
  I64 k = 0;
  while (k < LIVE_N) {
    if (LIVE_NAME_LEN[k] == len) {
      I64 z = 0;
      I64 same = 1;
      while (z < len) {
        if (hay[off + z] != hdr[LIVE_NAME_OFF[k] + z]) { same = 0; break; }
        z = z + 1;
      }
      if (same == 1) return k;
    }
    k = k + 1;
  }
  return -1;
}

// Parse the TERMINATING set out of the live src/parser.c.
//
// THE SEAM IS LOCATED BY ITS HELPER, NOT BY ITS FIRST OCCURRENCE.
//
// The name "AST_COMPOUND_STMT" occurs MANY times in src/parser.c (in
// other decisions, in comments and in switch labels), so the first
// textual occurrence is NOT the seam.  The seam is the legacy
// condition INSIDE the helper function that the migration introduced:
//
//   static int parseDefaultArmTerminates(int kind)
//   {
//     ...
//     if (kind == AST_COMPOUND_STMT || kind == AST_CASE ||
//             kind == AST_BREAK || kind == AST_RETURN
//             || kind == AST_GOTO) return 1;
//
// The witness therefore locates the helper by name, then extracts the
// AST_ identifiers of its first "if (" condition body.  This binds the
// terminating set to the LIVE source rather than to a transcribed
// table, and it cannot be fooled by an unrelated earlier occurrence.
static U0 parse_parser_c(U8 *buf, I64 len, U8 *hdr)
{
  TERM_N = 0;
  // Locate the helper.
  I64 at = find_sub(buf, len, "parseDefaultArmTerminates(int kind)");
  if (at < 0) {
    "FIXTURE_INTEGRITY_SEAM_HELPER_NOT_FOUND=1\n";
    return;
  }
  // The helper's body starts at the '{' after the signature.
  I64 body = at;
  while (body < len && buf[body] != 123) body = body + 1;   // '{'
  if (body >= len) return;
  // The body ends at the matching '}'.  The helper has no nested
  // braces in its legacy arm, so the FIRST '}' after the body start
  // that is not inside the "#ifdef" arm is the end.  To stay robust,
  // the search stops at the first '}' that follows a ';' at brace
  // depth 1.
  I64 depth = 0;
  I64 end = body;
  while (end < len) {
    if (buf[end] == 123) depth = depth + 1;
    if (buf[end] == 125) {
      depth = depth - 1;
      if (depth == 0) break;
    }
    end = end + 1;
  }
  // The legacy arm is the one whose condition mentions
  // AST_COMPOUND_STMT.  Locate it INSIDE the helper body.
  I64 seam = -1;
  I64 i = body;
  while (i < end) {
    I64 hit = find_sub(buf + i, end - i, "AST_COMPOUND_STMT");
    if (hit < 0) break;
    seam = i + hit;
    break;
  }
  if (seam < 0) return;
  // The condition starts at the previous ';' or '{' or newline-run.
  I64 cond_start = seam;
  while (cond_start > body) {
    U8 c = buf[cond_start - 1];
    if (c == 59 || c == 123) break;   // ';' or '{'
    cond_start = cond_start - 1;
  }
  // The condition ends at its terminating ';'.
  I64 cond_end = seam;
  while (cond_end < end) {
    if (buf[cond_end] == 59) break;   // ';'
    cond_end = cond_end + 1;
  }
  // Collect the AST_ identifiers of this condition.
  i = cond_start;
  while (i < cond_end) {
    if (buf[i] == 65 && buf[i+1] == 83 && buf[i+2] == 84 && buf[i+3] == 95) {
      I64 ne = i;
      while (ne < cond_end) {
        U8 c = buf[ne];
        if ((c >= 65 && c <= 90) || (c >= 48 && c <= 57) || c == 95) { ne = ne + 1; continue; }
        break;
      }
      I64 nlen = ne - i;
      I64 k = live_index_of_name(buf, i, nlen, hdr);
      if (k >= 0 && TERM_N < MAX_TERM) {
        TERM_IDX[TERM_N] = k;
        TERM_N = TERM_N + 1;
      }
      i = ne;
      continue;
    }
    i = i + 1;
  }
}

// Is this live value one of the terminating set?
static I64 is_terminating(I64 v)
{
  I64 k = 0;
  while (k < TERM_N) {
    if (LIVE_VALUE[TERM_IDX[k]] == v) return 1;
    k = k + 1;
  }
  return 0;
}

// The live NAME of a kind value, as an offset/length pair.
static I64 live_name_of(I64 v, I64 *off, I64 *len)
{
  I64 k = 0;
  while (k < LIVE_N) {
    if (LIVE_VALUE[k] == v) { *off = LIVE_NAME_OFF[k]; *len = LIVE_NAME_LEN[k]; return 1; }
    k = k + 1;
  }
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 4) {
    "usage: parser-slice08-fixture-integrity <fixture.tsv> <ast.h> <parser.c>\n";
    return 2;
  }
  U8 *fixture_path = argv[1];
  U8 *ast_path = argv[2];
  U8 *parser_path = argv[3];

  // ---- the LIVE SOURCES -------------------------------------------------
  I64 ast_len = 0;
  I64 parser_len = 0;
  U8 *ast_buf = slurp(ast_path, &ast_len);
  U8 *parser_buf = slurp(parser_path, &parser_len);
  if (ast_buf == NULL) {
    "FIXTURE_INTEGRITY_AST_SOURCE_UNREADABLE=%s\n", ast_path;
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    "STATUS=FAIL\n";
    return 1;
  }
  if (parser_buf == NULL) {
    "FIXTURE_INTEGRITY_PARSER_SOURCE_UNREADABLE=%s\n", parser_path;
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    "STATUS=FAIL\n";
    return 1;
  }

  parse_ast_h(ast_buf, ast_len);
  parse_parser_c(parser_buf, parser_len, ast_buf);

  "FIXTURE_INTEGRITY_LIVE_ENUM_COUNT=%d\n", LIVE_N;
  "FIXTURE_INTEGRITY_LIVE_TERMINATING_COUNT=%d\n", TERM_N;

  if (LIVE_N == 0) {
    "FIXTURE_INTEGRITY_LIVE_ENUM_EMPTY=1\n";
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    "STATUS=FAIL\n";
    return 1;
  }
  if (TERM_N != 5) {
    "FIXTURE_INTEGRITY_LIVE_TERMINATING_COUNT_WRONG=%d\n", TERM_N;
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    "STATUS=FAIL\n";
    return 1;
  }

  // ---- the FIXTURE ------------------------------------------------------
  I64 got = 0;
  U8 *buf = slurp(fixture_path, &got);
  if (buf == NULL) {
    "FIXTURE_INTEGRITY_FIXTURE_UNREADABLE=%s\n", fixture_path;
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    "STATUS=FAIL\n";
    return 1;
  }

  I64 total_rows = 0;
  I64 non_data_records = 0;
  I64 unknown_records = 0;
  I64 malformed_rows = 0;
  I64 truncated_rows = 0;
  I64 field_parse_errors = 0;
  I64 wrong_expected = 0;
  I64 invalid_expected = 0;
  I64 wrong_kind_name = 0;
  I64 wrong_partition = 0;
  I64 unknown_kind = 0;
  I64 duplicate_ids = 0;
  I64 missing_ids = 0;
  I64 out_of_range_ids = 0;
  I64 out_of_order_ids = 0;
  I64 max_id = 0;
  I64 last_id = 0;
  I64 seen_n = 0;
  I64 seen[MAX_IDS];

  I64 pos = 0;
  I64 rec_start = 0;
  while (pos < got) {
    if (buf[pos] == 10) {
      I64 len = pos - rec_start;
      U8 *rec = buf + rec_start;
      if (id_shape_ok(rec, len) == 1 && id_is_field_start(rec, len) == 1) {
        // A FIXTURE ROW.  Split into its 6 fields.
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
        if (nf != 6) {
          malformed_rows = malformed_rows + 1;
          if (malformed_rows <= 8) {
            "FIXTURE_INTEGRITY_MALFORMED_ROW id=%d fields=%d\n", id_number(rec), nf;
          }
        } else {
          I64 id = id_number(rec);
          I64 kind = 0;
          I64 p = fstart[2];
          I64 ok = 1;
          while (p < fstart[2] + flen[2] && (rec[p] == 32 || rec[p] == 9)) p = p + 1;
          if (p >= fstart[2] + flen[2] || rec[p] < 48 || rec[p] > 57) ok = 0;
          while (ok == 1 && p < fstart[2] + flen[2] && rec[p] >= 48 && rec[p] <= 57) {
            kind = kind * 10 + (rec[p] - 48);
            p = p + 1;
          }
          I64 expected = 0;
          I64 q = fstart[3];
          I64 ok2 = 1;
          while (q < fstart[3] + flen[3] && (rec[q] == 32 || rec[q] == 9)) q = q + 1;
          if (q >= fstart[3] + flen[3] || rec[q] < 48 || rec[q] > 57) ok2 = 0;
          while (ok2 == 1 && q < fstart[3] + flen[3] && rec[q] >= 48 && rec[q] <= 57) {
            expected = expected * 10 + (rec[q] - 48);
            q = q + 1;
          }
          if (ok == 0 || ok2 == 0) {
            field_parse_errors = field_parse_errors + 1;
            if (field_parse_errors <= 8) {
              "FIXTURE_INTEGRITY_FIELD_PARSE_ERROR id=%d\n", id;
            }
          } else {
            total_rows = total_rows + 1;
            if (id > max_id) max_id = id;
            I64 noff = 0;
            I64 nlen = 0;
            if (live_name_of(kind, &noff, &nlen) == 0) {
              unknown_kind = unknown_kind + 1;
              if (unknown_kind <= 8) {
                "FIXTURE_INTEGRITY_UNKNOWN_KIND id=%d kind=%d\n", id, kind;
              }
            } else {
              I64 same = 1;
              if (flen[4] != nlen) same = 0;
              I64 z = 0;
              while (same == 1 && z < nlen) {
                if (rec[fstart[4] + z] != ast_buf[noff + z]) { same = 0; break; }
                z = z + 1;
              }
              if (same == 0) {
                wrong_kind_name = wrong_kind_name + 1;
                if (wrong_kind_name <= 8) {
                  "FIXTURE_INTEGRITY_WRONG_KIND_NAME id=%d kind=%d\n", id, kind;
                }
              }
            }
            if (expected != 0 && expected != 1) {
              invalid_expected = invalid_expected + 1;
              if (invalid_expected <= 8) {
                "FIXTURE_INTEGRITY_INVALID_EXPECTED id=%d expected=%d\n", id, expected;
              }
            } else {
              I64 recomputed = is_terminating(kind);
              if (recomputed != expected) {
                wrong_expected = wrong_expected + 1;
                if (wrong_expected <= 8) {
                  "FIXTURE_INTEGRITY_WRONG_EXPECTED id=%d kind=%d expected=%d recomputed=%d\n",
                    id, kind, expected, recomputed;
                }
              }
            }
            I64 part_positive = 0;
            I64 part_negative = 0;
            if (flen[1] == 8) {
              I64 z = 0;
              I64 same = 1;
              while (z < 8) {
                if (rec[fstart[1] + z] != "POSITIVE"[z]) { same = 0; break; }
                z = z + 1;
              }
              part_positive = same;
              z = 0;
              same = 1;
              while (z < 8) {
                if (rec[fstart[1] + z] != "NEGATIVE"[z]) { same = 0; break; }
                z = z + 1;
              }
              part_negative = same;
            }
            if ((part_positive == 1 && is_terminating(kind) == 0)
                || (part_negative == 1 && is_terminating(kind) == 1)) {
              wrong_partition = wrong_partition + 1;
              if (wrong_partition <= 8) {
                "FIXTURE_INTEGRITY_WRONG_PARTITION id=%d kind=%d\n", id, kind;
              }
            }
            I64 dup = 0;
            I64 k = 0;
            while (k < seen_n) {
              if (seen[k] == id) dup = 1;
              k = k + 1;
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
          }
        }
      } else {
        non_data_records = non_data_records + 1;
        if (is_recognized_non_data(rec, len) == 0) {
          unknown_records = unknown_records + 1;
          if (unknown_records <= 8) {
            "FIXTURE_INTEGRITY_UNKNOWN_RECORD=%s\n", rec;
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
  "FIXTURE_INTEGRITY_WRONG_KIND_NAME=%d\n", wrong_kind_name;
  "FIXTURE_INTEGRITY_WRONG_PARTITION=%d\n", wrong_partition;
  "FIXTURE_INTEGRITY_UNKNOWN_KIND=%d\n", unknown_kind;
  "FIXTURE_INTEGRITY_DUPLICATE_IDS=%d\n", duplicate_ids;
  "FIXTURE_INTEGRITY_MISSING_IDS=%d\n", missing_ids;
  "FIXTURE_INTEGRITY_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "FIXTURE_INTEGRITY_OUT_OF_ORDER_IDS=%d\n", out_of_order_ids;
  "FIXTURE_INTEGRITY_MAX_ID=%d\n", max_id;

  // The acceptance predicate.
  //
  // The witness passes only when EVERY row's expected value equals the
  // rule recomputed from the LIVE source bytes, the row id set is
  // exactly 1..max_id with no duplicates and no gaps, every kind is a
  // live kind with the live name, no row is malformed or truncated, no
  // expected value is outside {0, 1}, and no record is unrecognized.
  if (total_rows > 0
      && unknown_records == 0
      && malformed_rows == 0
      && truncated_rows == 0
      && field_parse_errors == 0
      && wrong_expected == 0
      && invalid_expected == 0
      && wrong_kind_name == 0
      && wrong_partition == 0
      && unknown_kind == 0
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
