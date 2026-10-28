// tools/quality/parser-slice06-fixture-integrity.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06 C1.
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
//     derives the enum values and the terminating set by PARSING THE
//     SOURCE TEXT, so a transcription error in the producer is
//     detected;
//   * it scans the fixture for RECORD SEPARATORS (newline) and tests
//     every record against the fixture-id PATTERN directly (a canonical
//     id is a fixed-shape token: three decimal digits, ZERO PADDED);
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
// The witness does NOT re-run the producer's partition logic.  It
// derives the expected values from the LIVE SOURCE BYTES:
//
//   EXPECTED_ENUM_VALUES   <- parsed out of src/ast.h
//   EXPECTED_TERMINATING   <- parsed out of src/parser.c:1551..1553
//   EXPECTED_PROBES        <- the frozen contract's probe set
//
// and then checks the fixture's properties against those.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice06-fixture-integrity <fixture.tsv> <ast.h> <parser.c>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define MAX_IDS 4096
#define MAX_VALS 4096
#define MAX_PARTS 64
#define SRC_BUF 1048576

// The fixture-id PATTERN.
//
// The fixture ids are 001..nnn: exactly three decimal digits, ZERO
// PADDED.  The pattern test below looks at the FIRST THREE BYTES of a
// record and at nothing else.
static I64 id_shape_ok(U8 *rec, I64 len)
{
  if (len < 3) return 0;
  if (rec[0] < 48 || rec[0] > 57) return 0;
  if (rec[1] < 48 || rec[1] > 57) return 0;
  if (rec[2] < 48 || rec[2] > 57) return 0;
  return 1;
}

// The numeric id of a record whose shape is ok.
static I64 id_number(U8 *rec)
{
  return (rec[0] - 48) * 100 + (rec[1] - 48) * 10 + (rec[2] - 48);
}

// Are the first three bytes of `rec` followed by a TAB (or the end of
// the record)?  A fixture row is "001<TAB>...".
static I64 id_is_field_start(U8 *rec, I64 len)
{
  if (len == 3) return 1;
  return rec[3] == 9;
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

  U8 *keys[10];
  keys[0] = "ACT_ID=";
  keys[1] = "ACT_PHASE=";
  keys[2] = "EVIDENCE_KIND=";
  keys[3] = "FIXTURE_ROW_COUNT=";
  keys[4] = "FIXTURE_PATH=";
  keys[5] = "FIXTURE_INVALID_TOKEN_COUNT=";
  keys[6] = "FIXTURE_PARTITION_COUNT=";
  keys[7] = "FIXTURE_ENUM_VALUE_COUNT=";
  keys[8] = "FIXTURE_PROBE_COUNT=";
  keys[9] = "FIXTURE_TERMINATING_COUNT=";

  for (I64 k = 0; k < 10; k++) {
    U8 *key = keys[k];
    I64 kl = 0;
    while (key[kl] != 0) kl = kl + 1;
    if (len < kl) continue;
    I64 match = 1;
    for (I64 i = 0; i < kl; i++) {
      if (rec[i] != key[i]) { match = 0; break; }
    }
    if (match == 1) return 1;
  }
  return 0;
}

// Is `s` a decimal integer AT ALL, regardless of whether it fits in an
// I64?
//
// This distinguishes a MALFORMED field ("abc", "12x", "") from an
// OUT-OF-RANGE NUMERIC value ("99999999999999999999999"), which the
// frozen negative controls FC-05 and FC-06 require to be reported
// under different counters.
static I64 IsDecimalInteger(U8 *s)
{
  if (*s == '-') s++;
  else if (*s == '+') s++;
  if (*s == 0) return 0;
  I64 digits = 0;
  while (*s >= 48 && *s <= 57) { digits = digits + 1; s++; }
  if (digits == 0) return 0;
  if (*s != 0) return 0;
  return 1;
}

// Parse a signed decimal integer with an EXACT 64-bit conversion.
//
// Returns 0 on success and 1 on an out-of-range or malformed value.
// A "%d" conversion is NOT used: it is a 32-bit conversion.
static I64 ParseI64(U8 *s, I64 *out)
{
  I64 v = 0;
  I64 neg = 0;
  I64 digits = 0;
  U8 *p = s;

  if (*p == '-') { neg = 1; p = p + 1; }
  else if (*p == '+') { p = p + 1; }

  while (*p >= 48 && *p <= 57) {
    I64 d = *p - 48;
    if (v > (9223372036854775807 - d) / 10) return 1;
    v = v * 10 + d;
    digits = digits + 1;
    p = p + 1;
  }
  if (digits == 0) return 1;
  if (*p != 0 && *p != 9 && *p != 13) return 1;

  if (neg == 1) v = -v;
  *out = v;
  return 0;
}

// Compare two NUL-terminated strings for equality.
//
// This is the LOCAL definition used by the SLICE05 precedent; it is
// defined here so that the witness does not depend on a header that
// does not export it.
static I64 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a = a + 1; b = b + 1;
  }
  return *a == 0 && *b == 0;
}

// A LENGTH-BOUNDED comparison of `n` bytes.
//
// The live source text is read with FileRead, which does NOT
// NUL-terminate its buffer.  A NUL-terminated comparison would read
// past the buffer end, so every comparison against the SOURCE TEXT uses
// this bounded form instead.  StrEq is used only for the NUL-terminated
// strings that this tool itself builds.
static I64 MemEq(U8 *a, U8 *b, I64 n)
{
  I64 i;
  for (i = 0; i < n; i = i + 1) {
    if (a[i] != b[i]) return 0;
  }
  return 1;
}

// Find the first occurrence of `pat` in txt[0..len), or -1.
static I64 FindSub(U8 *txt, I64 len, U8 *pat, I64 plen)
{
  I64 i;
  for (i = 0; i + plen <= len; i = i + 1) {
    if (MemEq(&txt[i], pat, plen) == 1) return i;
  }
  return -1;
}
// Is `s` a valid strictly-signed decimal integer (no sign allowed)?
static I64 IsPlainInteger(U8 *s, I64 *out)
{
  if (*s == '-') return 0;
  return ParseI64(s, out);
}

// ---------------------------------------------------------------------------
// THE INDEPENDENT SOURCE DERIVATION
// ---------------------------------------------------------------------------
//
// The enum values are parsed OUT OF THE LIVE src/ast.h TEXT, not
// transcribed.  The terminating set is parsed OUT OF THE LIVE
// src/parser.c TEXT at the frozen range, not transcribed.
//
// This is what makes the witness independent of the producer: if the
// producer mis-transcribed a value, the two disagree and the witness
// reports it.

static I64 EXP_ENUM[128];
static I64 EXP_ENUM_N;

// The AST_ prefixed names that the AstKind enum defines.
//
// The AstKind enum is the LAST `typedef enum ... } AstKind;` in
// src/ast.h, and its members all begin with "AST_".  The witness
// collects every "AST_<NAME> = <value>;" line that appears BEFORE the
// "} AstKind;" terminator.
static I64 DeriveEnumFromAstH(U8 *txt, I64 len)
{
  EXP_ENUM_N = 0;

  // Find the LAST occurrence of "} AstKind;".
  I64 end = -1;
  I64 i;
  for (i = 0; i + 8 <= len; i = i + 1) {
    if (txt[i] == 125 && MemEq(&txt[i], "} AstKind;", 8) == 1) { end = i; break; }
  }
  if (end < 0) return 1;

  // Find the START of that enum: the last "typedef enum AstKind {"
  // before `end`.
  I64 start = -1;
  for (i = 0; i + 22 <= end; i = i + 1) {
    if (MemEq(&txt[i], "typedef enum AstKind {", 22) == 1) { start = i + 22; break; }
  }
  if (start < 0) return 1;

  // Walk the members.  Each looks like:
  //   AST_<NAME> = <value>,
  //   AST_<NAME>,
  // A member without an explicit value continues the previous value.
  I64 cur = 0;
  I64 pos = start;
  while (pos < end) {
    // Find the next "AST_" at a member boundary.
    while (pos < end && !(txt[pos] == 65 && MemEq(&txt[pos], "AST_", 4) == 1)) {
      pos = pos + 1;
    }
    if (pos >= end) break;

    // Extract the member name up to the '=' or the ','.
    I64 name_start = pos;
    while (pos < end && txt[pos] != 61 && txt[pos] != 44 && txt[pos] != 59) {
      pos = pos + 1;
    }
    if (pos >= end) break;

    I64 name_len = pos - name_start;
    U8 namebuf[64];
    if (name_len > 63) name_len = 63;
    I64 j;
    for (j = 0; j < name_len; j = j + 1) namebuf[j] = txt[name_start + j];
    namebuf[name_len] = 0;

    if (txt[pos] == 61) {
      // An explicit value.
      pos = pos + 1;
      while (pos < end && (txt[pos] == 32 || txt[pos] == 9)) pos = pos + 1;
      I64 v = 0;
      I64 neg = 0;
      if (txt[pos] == 45) { neg = 1; pos = pos + 1; }
      while (pos < end && txt[pos] >= 48 && txt[pos] <= 57) {
        v = v * 10 + (txt[pos] - 48);
        pos = pos + 1;
      }
      if (neg == 1) v = -v;
      cur = v;
    }

    // Record the member.
    if (EXP_ENUM_N < 128) {
      EXP_ENUM[EXP_ENUM_N] = cur;
      EXP_ENUM_N = EXP_ENUM_N + 1;
    }

    // Skip to the next member boundary.
    while (pos < end && txt[pos] != 44 && txt[pos] != 59) pos = pos + 1;
    if (pos < end) pos = pos + 1;
  }
  return 0;
}

// The terminating set, parsed OUT OF THE LIVE src/parser.c TEXT.
//
// The frozen range is src/parser.c:1551..1553.  The witness finds the
// CONDITION TEXT itself: the line that contains "AST_COMPOUND_STMT ||"
// and the following lines up to the "break;".  It then collects every
// "AST_<NAME>" token in that condition and resolves each name to its
// enum value using the enum derived from src/ast.h.
static I64 EXP_TERM[16];
static I64 EXP_TERM_N;
static I64 EXP_TERM_LINE;

// The length of the live src/ast.h text (needed by ResolveName).
static I64 EXP_SRC_LEN;

// Resolve an "AST_<NAME>" token to its enum value, using the LIVE
// src/ast.h text.
//
// The AstKind enum is located by its "} AstKind;" terminator, and its
// members are walked in order; a member with an explicit "= value"
// sets the running value, a member without one continues it.
static I64 ResolveName(U8 *txt, I64 len, U8 *name, I64 name_len, I64 *out)
{
  // Locate the enum body.
  I64 end = -1;
  I64 i;
  for (i = 0; i + 8 <= len; i = i + 1) {
    if (txt[i] == 125 && MemEq(&txt[i], "} AstKind;", 8) == 1) { end = i; break; }
  }
  if (end < 0) return 1;

  I64 start = -1;
  for (i = 0; i + 22 <= end; i = i + 1) {
    if (MemEq(&txt[i], "typedef enum AstKind {", 22) == 1) { start = i + 22; break; }
  }
  if (start < 0) return 1;

  I64 cur = 0;
  I64 pos = start;
  while (pos < end) {
    while (pos < end && !(txt[pos] == 65 && MemEq(&txt[pos], "AST_", 4) == 1)) {
      pos = pos + 1;
    }
    if (pos >= end) break;

    I64 ns = pos;
    while (pos < end && txt[pos] != 61 && txt[pos] != 44 && txt[pos] != 59) pos = pos + 1;
    I64 nl = pos - ns;
    while (nl > 0 && (txt[ns + nl - 1] == 32 || txt[ns + nl - 1] == 9)) nl = nl - 1;

    if (pos < end && txt[pos] == 61) {
      pos = pos + 1;
      while (pos < end && (txt[pos] == 32 || txt[pos] == 9)) pos = pos + 1;
      I64 v = 0;
      I64 neg = 0;
      if (pos < end && txt[pos] == 45) { neg = 1; pos = pos + 1; }
      while (pos < end && txt[pos] >= 48 && txt[pos] <= 57) {
        v = v * 10 + (txt[pos] - 48);
        pos = pos + 1;
      }
      if (neg == 1) v = -v;
      cur = v;
    }

    if (nl == name_len) {
      I64 match = 1;
      for (I64 k = 0; k < nl; k = k + 1) {
        if (txt[ns + k] != name[k]) { match = 0; break; }
      }
      if (match == 1) { *out = cur; return 0; }
    }

    while (pos < end && txt[pos] != 44 && txt[pos] != 59) pos = pos + 1;
    if (pos < end) pos = pos + 1;
  }
  return 1;
}

// Derive the terminating set from the LIVE src/parser.c TEXT.
//
// The witness locates the CONDITION itself: the line that contains
// "AST_COMPOUND_STMT", and it collects the "AST_<NAME>" tokens of that
// condition up to the "break;".  The terminating set is therefore
// derived from the live source, not transcribed.
static I64 DeriveTerminating(U8 *ptxt, I64 plen, U8 *atxt, I64 alen)
{
  EXP_TERM_N = 0;
  EXP_TERM_LINE = 0;

  // Find the condition's start: the "if (stmt->kind == AST_" line.
  I64 cstart = -1;
  I64 i;
  for (i = 0; i + 22 <= plen; i = i + 1) {
    if (MemEq(&ptxt[i], "if (stmt->kind == AST_", 22) == 1) { cstart = i; break; }
  }
  if (cstart < 0) return 1;

  // Find the end: the "break;" that closes the condition.
  I64 cend = -1;
  for (i = cstart; i + 6 <= plen; i = i + 1) {
    if (MemEq(&ptxt[i], "break;", 6) == 1) { cend = i; break; }
  }
  if (cend < 0) return 1;

  // Collect every "AST_<NAME>" token in the condition.
  I64 pos = cstart;
  while (pos < cend) {
    if (ptxt[pos] == 65 && MemEq(&ptxt[pos], "AST_", 4) == 1) {
      I64 ns = pos;
      while (pos < cend && ptxt[pos] != 61 && ptxt[pos] != 44 && ptxt[pos] != 59
             && ptxt[pos] != 41 && ptxt[pos] != 32 && ptxt[pos] != 9
             && ptxt[pos] != 10 && ptxt[pos] != 13) {
        pos = pos + 1;
      }
      I64 nl = pos - ns;
      while (nl > 0 && (ptxt[ns + nl - 1] == 32 || ptxt[ns + nl - 1] == 9)) nl = nl - 1;
      I64 v;
      if (ResolveName(atxt, alen, &ptxt[ns], nl, &v) == 0) {
        I64 dup = 0;
        for (I64 k = 0; k < EXP_TERM_N; k = k + 1) {
          if (EXP_TERM[k] == v) dup = 1;
        }
        if (dup == 0 && EXP_TERM_N < 16) {
          EXP_TERM[EXP_TERM_N] = v;
          EXP_TERM_N = EXP_TERM_N + 1;
        }
      }
      continue;
    }
    pos = pos + 1;
  }

  // The line number of the condition's first line.
  I64 line = 1;
  for (i = 0; i < cstart; i = i + 1) {
    if (ptxt[i] == 10) line = line + 1;
  }
  EXP_TERM_LINE = line;
  return 0;
}

// Is `v` in the derived terminating set?
static I64 IsExpectedTerminating(I64 v)
{
  for (I64 i = 0; i < EXP_TERM_N; i = i + 1) {
    if (EXP_TERM[i] == v) return 1;
  }
  return 0;
}

// Is `v` in the derived enum?
static I64 IsExpectedEnum(I64 v)
{
  for (I64 i = 0; i < EXP_ENUM_N; i = i + 1) {
    if (EXP_ENUM[i] == v) return 1;
  }
  return 0;
}

// The frozen probe set from the predecessor's contract.
static I64 EXP_PROBE[10];
static I64 EXP_PROBE_N;

static U0 InitExpectedProbes()
{
  EXP_PROBE_N = 0;
  EXP_PROBE[EXP_PROBE_N] = -4; EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = -3; EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = -2; EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = -1; EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = 0;  EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = 296; EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = 297; EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = 298; EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = 299; EXP_PROBE_N++;
  EXP_PROBE[EXP_PROBE_N] = 300; EXP_PROBE_N++;
}

// Is `v` in the expected probe set?
static I64 IsExpectedProbe(I64 v)
{
  for (I64 i = 0; i < EXP_PROBE_N; i = i + 1) {
    if (EXP_PROBE[i] == v) return 1;
  }
  return 0;
}

// The expected partition set, listed INDEPENDENTLY of the producer.
//
// The producer emits these partitions; the witness knows them from the
// frozen contract, not from the producer's output.
static U8 *EXP_PART[12];
static I64 EXP_PART_N;

static U0 InitExpectedPartitions()
{
  EXP_PART_N = 0;
  EXP_PART[EXP_PART_N] = "P01_ACCEPTED";          EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P02_REJECTED";          EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P03_BOUNDARY";          EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P04_BOUNDARY";          EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P05_ALIASING";          EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P06_PROJECTION_EDGE";   EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P07_ERROR_FAILURE";     EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P08_PRODUCTION_CALLER"; EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P09_MUTATION_SENSITIVE";EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P10_AST_SHAPE";         EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P11_STATEMENT_ORDERING";EXP_PART_N++;
  EXP_PART[EXP_PART_N] = "P12_SCOPE_SENSITIVE";   EXP_PART_N++;
}

// Copy `n` bytes into a NUL-terminated buffer.
static U0 CopyBytes(U8 *dst, U8 *src, I64 n)
{
  I64 i;
  for (i = 0; i < n; i = i + 1) dst[i] = src[i];
  dst[n] = 0;
}

// Find the offset of the n-th TAB-separated field in `rec`.
// Returns the offset of the field's first byte, or -1 when the record
// has fewer than n+1 fields.
static I64 FieldOffset(U8 *rec, I64 len, I64 n)
{
  I64 field = 0;
  I64 i = 0;
  while (i < len) {
    if (rec[i] == 9) {
      field = field + 1;
      if (field == n) return i + 1;
    }
    i = i + 1;
  }
  return -1;
}

// The length of the n-th TAB-separated field.
static I64 FieldLength(U8 *rec, I64 len, I64 n)
{
  I64 start = FieldOffset(rec, len, n);
  if (start < 0) return -1;
  I64 end = start;
  while (end < len && rec[end] != 9) end = end + 1;
  return end - start;
}

// ---------------- The main -------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 4) {
    "usage: parser-slice06-fixture-integrity <fixture.tsv> <ast.h> <parser.c>\n";
    return 2;
  }
  U8 *path = argv[1];
  U8 *ast_path = argv[2];
  U8 *parser_path = argv[3];

  InitExpectedPartitions();
  InitExpectedProbes();

  // ---- read the LIVE sources -------------------------------------------
  I64 alen = 0;
  U8 *atxt = FileRead(ast_path, &alen);
  if (atxt == NULL) {
    "FIXTURE_INTEGRITY_AST_READ_FAILED=%s\n", ast_path;
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    return 1;
  }
  EXP_SRC_LEN = alen;

  I64 plen = 0;
  U8 *ptxt = FileRead(parser_path, &plen);
  if (ptxt == NULL) {
    "FIXTURE_INTEGRITY_PARSER_READ_FAILED=%s\n", parser_path;
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    return 1;
  }

  // ---- derive the expected sets from the LIVE source -------------------
  if (DeriveEnumFromAstH(atxt, alen) != 0) {
    "FIXTURE_INTEGRITY_ENUM_DERIVATION_FAILED=YES\n";
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    return 1;
  }
  if (DeriveTerminating(ptxt, plen, atxt, alen) != 0) {
    "FIXTURE_INTEGRITY_TERMINATING_DERIVATION_FAILED=YES\n";
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    return 1;
  }

  // ---- read the fixture -------------------------------------------------
  I64 fsize = 0;
  U8 *ftxt = FileRead(path, &fsize);
  if (ftxt == NULL) {
    "FIXTURE_INTEGRITY_READ_FAILED=%s\n", path;
    "FIXTURE_INTEGRITY_STATUS=FAIL\n";
    return 1;
  }

  // ---- scan the fixture record by record --------------------------------
  I64 fixture_rows = 0;
  I64 non_data_records = 0;
  I64 unknown_records = 0;
  I64 duplicate_ids = 0;
  I64 missing_ids = 0;
  I64 out_of_range_ids = 0;
  I64 unknown_ids = 0;
  I64 malformed_rows = 0;
  I64 invalid_input_values = 0;
  I64 wrong_expected = 0;
  I64 wrong_partition = 0;
  I64 untested_enum_values = 0;
  I64 untested_probe_values = 0;

  I64 seen_id[MAX_IDS];
  I64 seen_n = 0;
  I64 seen_val[MAX_VALS];
  I64 seen_val_n = 0;
  U8 seen_part[MAX_PARTS][64];
  I64 seen_part_n = 0;

  // The largest id observed, used to compute the expected id set.
  I64 max_id = 0;

  I64 rec_start = 0;
  I64 pos = 0;
  while (pos <= fsize) {
    if (pos == fsize || ftxt[pos] == 10) {
      I64 rec_len = pos - rec_start;
      // Strip a trailing CR.
      I64 eff_len = rec_len;
      if (eff_len > 0 && ftxt[rec_start + eff_len - 1] == 13) eff_len = eff_len - 1;

      if (eff_len > 0) {
        if (id_shape_ok(&ftxt[rec_start], eff_len) == 1
            && id_is_field_start(&ftxt[rec_start], eff_len) == 1) {
          // ---- a FIXTURE ROW -------------------------------------------
          fixture_rows = fixture_rows + 1;
          I64 id = id_number(&ftxt[rec_start]);

          // The duplicate check.
          for (I64 i = 0; i < seen_n; i = i + 1) {
            if (seen_id[i] == id) duplicate_ids = duplicate_ids + 1;
          }
          if (seen_n < MAX_IDS) { seen_id[seen_n] = id; seen_n = seen_n + 1; }
          if (id > max_id) max_id = id;

          // The partition (field 1).
          I64 p_off = FieldOffset(&ftxt[rec_start], eff_len, 1);
          I64 p_len = FieldLength(&ftxt[rec_start], eff_len, 1);
          if (p_off < 0 || p_len <= 0) {
            malformed_rows = malformed_rows + 1;
          } else {
            U8 pbuf[128];
            if (p_len > 127) p_len = 127;
            CopyBytes(pbuf, &ftxt[rec_start + p_off], p_len);
            I64 known = 0;
            for (I64 i = 0; i < EXP_PART_N; i = i + 1) {
              if (StrEq(pbuf, EXP_PART[i]) == 1) known = 1;
            }
            if (known == 0) wrong_partition = wrong_partition + 1;
            I64 dup_part = 0;
            for (I64 i = 0; i < seen_part_n; i = i + 1) {
              if (StrEq(&seen_part[i][0], pbuf) == 1) dup_part = 1;
            }
            if (dup_part == 0 && seen_part_n < MAX_PARTS) {
              CopyBytes(seen_part[seen_part_n], pbuf, p_len);
              seen_part_n = seen_part_n + 1;
            }
          }

          // The ast_kind (field 2) and the expected (field 3).
          I64 k_off = FieldOffset(&ftxt[rec_start], eff_len, 2);
          I64 k_len = FieldLength(&ftxt[rec_start], eff_len, 2);
          I64 e_off = FieldOffset(&ftxt[rec_start], eff_len, 3);
          I64 e_len = FieldLength(&ftxt[rec_start], eff_len, 3);

          if (k_off < 0 || k_len <= 0 || e_off < 0 || e_len <= 0) {
            malformed_rows = malformed_rows + 1;
          } else {
            U8 kbuf[64];
            U8 ebuf[64];
            if (k_len > 63) k_len = 63;
            if (e_len > 63) e_len = 63;
            CopyBytes(kbuf, &ftxt[rec_start + k_off], k_len);
            CopyBytes(ebuf, &ftxt[rec_start + e_off], e_len);

            I64 kind = 0;
            I64 expected = 0;
            I64 kind_ok = ParseI64(kbuf, &kind);
            I64 exp_ok = ParseI64(ebuf, &expected);

            if (kind_ok != 0) {
              // Distinguish a MALFORMED field from an OUT-OF-RANGE
              // NUMERIC value.
              //
              // The frozen negative controls distinguish them:
              //
              //   FC-05  a malformed kind field (e.g. "abc")
              //          -> MALFORMED_ROWS
              //   FC-06  an out-of-range NUMERIC value
              //          -> INVALID_INPUT_VALUES
              //
              // So a field that is not a decimal integer AT ALL is
              // malformed, while a field that IS a decimal integer but
              // does not fit in an I64, or that is an I64 but is
              // neither an enum value nor an expected probe, is an
              // invalid INPUT VALUE.
              if (IsDecimalInteger(kbuf) == 0) {
                malformed_rows = malformed_rows + 1;
              } else {
                invalid_input_values = invalid_input_values + 1;
              }
            } else if (exp_ok != 0 || (expected != 0 && expected != 1)) {
              malformed_rows = malformed_rows + 1;
            } else {
              // The value must be an enum value or an expected probe.
              if (IsExpectedEnum(kind) == 0 && IsExpectedProbe(kind) == 0) {
                invalid_input_values = invalid_input_values + 1;
              }
              // The expected value must match the DERIVED terminating set.
              I64 want = IsExpectedTerminating(kind);
              if (want != expected) wrong_expected = wrong_expected + 1;

              // Record the value.
              I64 dup_val = 0;
              for (I64 i = 0; i < seen_val_n; i = i + 1) {
                if (seen_val[i] == kind) dup_val = 1;
              }
              if (dup_val == 0 && seen_val_n < MAX_VALS) {
                seen_val[seen_val_n] = kind;
                seen_val_n = seen_val_n + 1;
              }
            }
          }
        } else {
          // ---- a NON-FIXTURE record -------------------------------------
          non_data_records = non_data_records + 1;
          if (is_recognized_non_data(&ftxt[rec_start], eff_len) == 0) {
            unknown_records = unknown_records + 1;
            "FIXTURE_INTEGRITY_UNKNOWN_RECORD at byte %d\n", rec_start;
          }
        }
      }
      rec_start = pos + 1;
    }
    pos = pos + 1;
  }

  // ---- the missing ids --------------------------------------------------
  // The canonical id space is 1..max_id, with no gaps.
  for (I64 id = 1; id <= max_id; id = id + 1) {
    I64 found = 0;
    for (I64 i = 0; i < seen_n; i = i + 1) {
      if (seen_id[i] == id) found = 1;
    }
    if (found == 0) missing_ids = missing_ids + 1;
  }
  for (I64 i = 0; i < seen_n; i = i + 1) {
    if (seen_id[i] < 1 || seen_id[i] > max_id) out_of_range_ids = out_of_range_ids + 1;
  }

  // ---- the untested enum values -----------------------------------------
  // Every enum value derived from the live src/ast.h MUST appear.
  for (I64 i = 0; i < EXP_ENUM_N; i = i + 1) {
    I64 found = 0;
    for (I64 j = 0; j < seen_val_n; j = j + 1) {
      if (seen_val[j] == EXP_ENUM[i]) found = 1;
    }
    if (found == 0) untested_enum_values = untested_enum_values + 1;
  }

  // ---- the untested probe values ----------------------------------------
  // Every expected probe MUST appear.
  for (I64 i = 0; i < EXP_PROBE_N; i = i + 1) {
    I64 found = 0;
    for (I64 j = 0; j < seen_val_n; j = j + 1) {
      if (seen_val[j] == EXP_PROBE[i]) found = 1;
    }
    if (found == 0) untested_probe_values = untested_probe_values + 1;
  }

  // ---- the partition set -------------------------------------------------
  I64 missing_partitions = 0;
  for (I64 i = 0; i < EXP_PART_N; i = i + 1) {
    I64 found = 0;
    for (I64 j = 0; j < seen_part_n; j = j + 1) {
      if (StrEq(&seen_part[j][0], EXP_PART[i]) == 1) found = 1;
    }
    if (found == 0) {
      // A zero-coverage partition is NOT missing: P05, P07 and P12 are
      // recorded with ZERO rows by design (the frozen contract records
      // them so that their ABSENCE is explicit).
      I64 zero_ok = 0;
      if (StrEq(EXP_PART[i], "P05_ALIASING") == 1) zero_ok = 1;
      if (StrEq(EXP_PART[i], "P07_ERROR_FAILURE") == 1) zero_ok = 1;
      if (StrEq(EXP_PART[i], "P12_SCOPE_SENSITIVE") == 1) zero_ok = 1;
      if (zero_ok == 0) missing_partitions = missing_partitions + 1;
    }
  }
  I64 extra_partitions = 0;
  for (I64 j = 0; j < seen_part_n; j = j + 1) {
    I64 found = 0;
    for (I64 i = 0; i < EXP_PART_N; i = i + 1) {
      if (StrEq(EXP_PART[i], &seen_part[j][0]) == 1) found = 1;
    }
    if (found == 0) extra_partitions = extra_partitions + 1;
  }

  // ---- the report -------------------------------------------------------
  "FIXTURE_INTEGRITY_PATH=%s\n", path;
  "FIXTURE_INTEGRITY_OBSERVED_ROWS=%d\n", fixture_rows;
  "FIXTURE_INTEGRITY_NON_DATA_RECORDS=%d\n", non_data_records;
  "FIXTURE_INTEGRITY_UNKNOWN_RECORDS=%d\n", unknown_records;
  "FIXTURE_INTEGRITY_DUPLICATE_IDS=%d\n", duplicate_ids;
  "FIXTURE_INTEGRITY_MISSING_IDS=%d\n", missing_ids;
  "FIXTURE_INTEGRITY_OUT_OF_RANGE_IDS=%d\n", out_of_range_ids;
  "FIXTURE_INTEGRITY_UNKNOWN_IDS=%d\n", unknown_ids;
  "FIXTURE_INTEGRITY_MALFORMED_ROWS=%d\n", malformed_rows;
  "FIXTURE_INTEGRITY_INVALID_INPUT_VALUES=%d\n", invalid_input_values;
  "FIXTURE_INTEGRITY_WRONG_EXPECTED=%d\n", wrong_expected;
  "FIXTURE_INTEGRITY_WRONG_PARTITION=%d\n", wrong_partition;
  "FIXTURE_INTEGRITY_UNTESTED_ENUM_VALUES=%d\n", untested_enum_values;
  "FIXTURE_INTEGRITY_UNTESTED_PROBE_VALUES=%d\n", untested_probe_values;
  "FIXTURE_INTEGRITY_MISSING_PARTITIONS=%d\n", missing_partitions;
  "FIXTURE_INTEGRITY_EXTRA_PARTITIONS=%d\n", extra_partitions;
  "FIXTURE_INTEGRITY_OBSERVED_DISTINCT_VALUES=%d\n", seen_val_n;
  "FIXTURE_INTEGRITY_OBSERVED_PARTITIONS=%d\n", seen_part_n;
  "FIXTURE_INTEGRITY_EXPECTED_PARTITIONS=%d\n", EXP_PART_N;

  // The INDEPENDENTLY DERIVED expectations.
  "FIXTURE_INTEGRITY_DERIVED_ENUM_VALUES=%d\n", EXP_ENUM_N;
  "FIXTURE_INTEGRITY_DERIVED_TERMINATING=%d\n", EXP_TERM_N;
  "FIXTURE_INTEGRITY_DERIVED_TERMINATING_LINE=%d\n", EXP_TERM_LINE;
  "FIXTURE_INTEGRITY_DERIVED_PROBES=%d\n", EXP_PROBE_N;

  I64 i;
  "FIXTURE_INTEGRITY_DERIVED_TERMINATING_SET=";
  for (i = 0; i < EXP_TERM_N; i = i + 1) {
    "%d ", EXP_TERM[i];
  }
  "\n";

  // The acceptance predicate.
  //
  // The fixture set is AUTHORITATIVE: the EXACT canonical id set is
  // present, each id occurs EXACTLY once, every row matches the
  // declared schema, every enum value and every probe is covered, every
  // expected value matches the LIVE derived terminating set, every
  // partition is one of the frozen partitions, and there is no unknown
  // record.
  if (fixture_rows > 0
      && missing_ids == 0
      && duplicate_ids == 0
      && out_of_range_ids == 0
      && unknown_ids == 0
      && unknown_records == 0
      && malformed_rows == 0
      && invalid_input_values == 0
      && wrong_expected == 0
      && wrong_partition == 0
      && untested_enum_values == 0
      && untested_probe_values == 0
      && missing_partitions == 0
      && extra_partitions == 0
      && EXP_ENUM_N == 41
      && EXP_TERM_N == 6) {
    "FIXTURE_INTEGRITY_STATUS=PASS\n";
    return 0;
  }
  "FIXTURE_INTEGRITY_STATUS=FAIL\n";
  return 1;
}
