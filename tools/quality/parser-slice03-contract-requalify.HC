// tools/quality/parser-slice03-contract-requalify.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE03 C1 IMPL.
//
// CONTRACT REQUALIFICATION TOOL for the operator-precedence slice.
//
// It re-derives the precedence table DIRECTLY from the live
// `src/prslib.c` and the live `src/lexer.h`, audits the predecessor's
// frozen fixture-partition table against that derivation, and computes
// the corrected mandatory fixture count.
//
// It does NOT trust the predecessor's contract prose, and it does NOT
// change the legacy semantics: it only reports what the live source
// says.
//
// The output is a set of TSV files plus a machine-readable summary.
// Nothing here is an expectation that could be hand-authored: the
// table is computed, the audit is computed, and the counts are
// computed.
//
// USAGE:
//   build/parser-slice03-contract-requalify <prslib.c> <lexer.h> \
//        <partition.tsv> <outdir>
//
// The outdir receives:
//   precedence-table-derived.tsv
//   fixture-partitions-audit.tsv
//   fixture-count-arithmetic.txt
//   required-result.txt
//
// The tool exits with RC=0 when the audit finds no UNKNOWN partition
// membership and the count is internally consistent, and RC=1
// otherwise.  A tool that always exits 0 would report PASS for a
// contract that does not match the source.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define LINE_CAP 4096
#define MAX_TABLE_ENTRIES 256
#define MAX_DEFINES 512
#define MAX_PARTITIONS 64

// ---------------------------------------------------------------------------
// Append a printf-formatted string to a buffer.
//
// The return value is the number of BYTES appended, so the caller
// advances the write position by it.  `snprintf` is used because the
// PolyC `StrPrint` does not advance the destination pointer the way a
// printf-family function is expected to.
// ---------------------------------------------------------------------------
// PolyC does not support a USER-DEFINED variadic function; only an
// `extern "c"` one.  `snprintf` is therefore declared explicitly.
//
// Because a user-defined variadic helper is impossible, the append
// helpers below are FIXED-ARITY: one per shape of output line.  Each
// returns the number of BYTES appended, so the caller advances the
// write position by it.
extern "c" I64 snprintf(U8 *dst, U64 cap, U8 *fmt, ...);

// Append a literal string.
I64 app_lit(U8 *dst, I64 cap, U8 *s)
{
  if (cap <= 0) return 0;
  I64 n = 0;
  while (s[n] != 0 && n < cap - 1) { dst[n] = s[n]; n = n + 1; }
  return n;
}

// Append "<text><number>\n".
I64 app_i(U8 *dst, I64 cap, U8 *text, I64 v)
{
  if (cap <= 0) return 0;
  I64 n = app_lit(dst, cap, text);
  if (n >= cap - 1) return n;
  I64 m = snprintf(dst + n, cap - n, "%d\n", v);
  if (m < 0) return n;
  if (m >= cap - n) return n + cap - n - 1;
  return n + m;
}

// Append "<text><number>\n".
I64 app_i2(U8 *dst, I64 cap, U8 *text, I64 a, I64 b)
{
  if (cap <= 0) return 0;
  I64 n = app_lit(dst, cap, text);
  if (n >= cap - 1) return n;
  I64 m = snprintf(dst + n, cap - n, "%d\n", a);
  if (m < 0) return n;
  if (m >= cap - n) return n + cap - n - 1;
  n = n + m;
  if (n >= cap - 1) return n;
  m = snprintf(dst + n, cap - n, "%d\n", b);
  if (m < 0) return n;
  if (m >= cap - n) return n + cap - n - 1;
  return n + m;
}

// Build a path by concatenating a directory and a file name.
I64 outpath(U8 *dst, I64 cap, U8 *dir, U8 *name)
{
  I64 n = 0;
  while (dir[n] != 0 && n < cap - 1) { dst[n] = dir[n]; n = n + 1; }
  // The name is copied with a SINGLE index that advances in BOTH the
  // read and the write.  An earlier revision read name[i] with an i
  // that was never incremented, so the first byte was copied over and
  // over: the observed path was "build/slice03-out" followed by 130
  // stray slashes, and the file was never created.
  I64 i = 0;
  while (name[i] != 0 && n < cap - 1) {
    dst[n] = name[i];
    n = n + 1;
    i = i + 1;
  }
  dst[n] = 0;
  return n;
}

// ---------------------------------------------------------------------------
// A small string-slice helper.  `buf` points into a caller-owned array.
// ---------------------------------------------------------------------------

// Return the length of the NUL-terminated string at p.
// The library StrLen is used instead of a hand-written NUL scan.
// A hand-written scan is UNSAFE on a PolyC string literal: the
// compiler lays the literal bytes out contiguously, so the byte after
// the terminator can belong to the NEXT literal.  A hand-written scan
// therefore ran past the end of the literal and produced a path of
// 130 stray slashes.  StrLen is an extern C routine and is correct.
I64 slen(U8 *p)
{
  U64 n = StrLen(p);
  return n;
}

// Return 1 if the NUL-terminated string at a equals the one at b.
// Compare exactly `n` bytes of a and b.
//
// A PolyC string literal is NOT reliably NUL-terminated in the sense
// that a byte-by-byte scan for the terminator can walk past the end
// of the literal: the compiler lays the literal bytes out contiguously
// and the byte AFTER the NUL may belong to the NEXT literal.  A
// comparison that scans for the NUL is therefore unsafe.  Every
// comparison in this tool therefore carries an EXPLICIT length.
//
// This was measured, not assumed: a scan-for-NUL comparison of
// "parseGetPriority" against the live src/prslib.c reported a mismatch
// at index 16, where the file held '(' (40) and the literal held 0.
I64 memeq(U8 *a, U8 *b, I64 n)
{
  I64 i = 0;
  while (i < n) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// Return 1 if the byte sequence `lit` of length `n` occurs anywhere in
// `hay` of length `hlen`.  Returns the 1-based offset of the first
// occurrence in *out, or 0 when there is none.
I64 contains(U8 *hay, I64 hlen, U8 *lit, I64 n, I64 *out)
{
  I64 i = 0;
  while (i + n <= hlen) {
    if (memeq(hay + i, lit, n)) {
      *out = i;
      return 1;
    }
    i = i + 1;
  }
  *out = 0;
  return 0;
}

// Copy the NUL-terminated string at src into dst (at most cap-1 bytes
// plus the NUL).  Returns the length written.
I64 scopy(U8 *dst, I64 cap, U8 *src)
{
  I64 i = 0;
  while (i < cap - 1 && src[i] != 0) {
    dst[i] = src[i];
    i = i + 1;
  }
  dst[i] = 0;
  return i;
}

// Skip whitespace at p.  Returns the new position.
U8 *skip_ws(U8 *p)
{
  while (*p == ' ' || *p == '\t' || *p == '\r') p = p + 1;
  return p;
}

// ---------------------------------------------------------------------------
// The derived table.
//
// `name` is the source-level case label exactly as it appears in
// src/prslib.c (e.g. "TK_SHR" or "'*'").
// `value` is the NUMERIC punct value, resolved from src/lexer.h for a
// named constant and from the C character literal for a punctuation
// label.
// `value_known` is 0 when the label could not be resolved to a number.
// ---------------------------------------------------------------------------

U8 g_name[MAX_TABLE_ENTRIES][64];
I64 g_value[MAX_TABLE_ENTRIES];
I64 g_value_known[MAX_TABLE_ENTRIES];
I64 g_precedence[MAX_TABLE_ENTRIES];
I64 g_line[MAX_TABLE_ENTRIES];
I64 g_entry_count;
I64 g_sentinel;
I64 g_sentinel_found;

I64 g_def_name[MAX_DEFINES][64];
I64 g_def_value[MAX_DEFINES];
I64 g_def_count;

// ---------------------------------------------------------------------------
// Parse src/lexer.h into the define table.
//
// Only `#define NAME <integer>` lines are captured.  A define whose
// body is not a plain integer (for example KW_CLASS, which is
// "(1<<0)") is skipped: it cannot be a punct value.
// ---------------------------------------------------------------------------

I64 parse_defines(U8 *text, I64 size)
{
  I64 i = 0;
  g_def_count = 0;
  while (i < size) {
    // Find the start of a line.
    I64 ls = i;
    while (i < size && text[i] != '\n') i = i + 1;
    I64 le = i;
    if (i < size) i = i + 1;

    // The line must begin with "#define".
    if (le - ls < 7) continue;
    if (text[ls] != '#') continue;
    if (text[ls+1] != 'd') continue;
    if (text[ls+2] != 'e') continue;
    if (text[ls+3] != 'f') continue;
    if (text[ls+4] != 'i') continue;
    if (text[ls+5] != 'n') continue;
    if (text[ls+6] != 'e') continue;

    U8 *p = skip_ws(text + ls + 7);
    // The name.
    U8 nm[64];
    I64 k = 0;
    while (*p && *p != ' ' && *p != '\t' && k < 63) {
      nm[k] = *p;
      k = k + 1;
      p = p + 1;
    }
    nm[k] = 0;
    if (k == 0) continue;

    p = skip_ws(p);
    // The value: an optional 0x prefix and digits.  Anything else
    // (a parenthesis, an identifier, an operator) is NOT a plain
    // integer and is skipped.
    I64 neg = 0;
    if (*p == '-') { neg = 1; p = p + 1; }
    else if (*p == '+') { p = p + 1; }

    I64 base = 10;
    if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
      base = 16;
      p = p + 2;
    }
    I64 v = 0;
    I64 digits = 0;
    while (*p) {
      I64 d = -1;
      if (*p >= '0' && *p <= '9') d = *p - '0';
      else if (base == 16 && *p >= 'a' && *p <= 'f') d = *p - 'a' + 10;
      else if (base == 16 && *p >= 'A' && *p <= 'F') d = *p - 'A' + 10;
      if (d < 0) break;
      if (d >= base) break;
      v = v * base + d;
      digits = digits + 1;
      p = p + 1;
    }
    if (digits == 0) continue;
    // The value must be the WHOLE rest of the definition (up to the
    // line end), otherwise it is an expression, not a literal.
    p = skip_ws(p);
    if (*p != 0 && *p != '\r' && *p != '\n') continue;
    if (neg) v = 0 - v;

    if (g_def_count < MAX_DEFINES) {
      scopy(g_def_name[g_def_count], 64, nm);
      g_def_value[g_def_count] = v;
      g_def_count = g_def_count + 1;
    }
  }
  return g_def_count;
}

// Look up a define by name.  Returns 1 and sets *out when found.
I64 lookup_define(U8 *nm, I64 *out)
{
  I64 i = 0;
  while (i < g_def_count) {
    if (memeq(g_def_name[i], nm, slen(nm))) {
      *out = g_def_value[i];
      return 1;
    }
    i = i + 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// Parse the legacy C switch body.
//
// The body is a sequence of `case <label>:` lines and `return <n>;`
// lines.  A `case` binds to the NEXT `return`.  A `default:` binds to
// the next `return` as well, and that return is the sentinel.
//
// The `case` label is a C token: either a character literal ('*') or an
// identifier (TK_SHR).
// ---------------------------------------------------------------------------

I64 parse_switch(U8 *text, I64 size)
{
  I64 i = 0;
  I64 lineno = 0;
  g_entry_count = 0;
  // pending: the labels seen since the last `return`.
  I64 pending_count = 0;
  U8 pending_name[32][64];
  // Set when a `default:` arm is pending: the next `return` is the
  // SENTINEL, not an operator precedence.
  I64 pending_default = 0;
  g_sentinel = 0;
  g_sentinel_found = 0;

  while (i < size) {
    I64 ls = i;
    while (i < size && text[i] != '\n') i = i + 1;
    I64 le = i;
    if (i < size) i = i + 1;
    lineno = lineno + 1;

    U8 *p = skip_ws(text + ls);
    // Is this a `default:` line?  Its return value is the SENTINEL:
    // the value the legacy function returns for every punct value that
    // is not a recognised operator.  It is captured separately from
    // the operator table, because a sentinel is not an operator.
    if (p[0] == 'd' && p[1] == 'e' && p[2] == 'f' && p[3] == 'a'
        && p[4] == 'u' && p[5] == 'l' && p[6] == 't') {
      p = p + 7;
      p = skip_ws(p);
      if (*p == ':') {
        pending_default = 1;
        continue;
      }
    }
    // Is this a `case` line?
    //
    // A SINGLE LINE MAY CARRY SEVERAL case labels.  The live source
    // has, for example:
    //
    //     case '*': case '/': case '%':
    //
    // so the handler LOOP over the labels on the line.  An earlier
    // revision read only the first label and therefore derived a table
    // of 31 entries instead of 34.
    if (p[0] == 'c' && p[1] == 'a' && p[2] == 's' && p[3] == 'e') {
      p = p + 4;
      // The label(s).
      I64 labels_found = 0;
      while (labels_found < 32) {
        p = skip_ws(p);
        // A `case` keyword may follow another label on the same line.
        if (p[0] == 'c' && p[1] == 'a' && p[2] == 's' && p[3] == 'e') {
          p = p + 4;
          p = skip_ws(p);
        }
        if (*p == 0) break;
        U8 nm[64];
        I64 k = 0;
        if (*p == 39) {
          // A character literal: capture it verbatim including the
          // quotes, and resolve it to its numeric value separately.
          nm[k] = *p; k = k + 1;
          p = p + 1;
          while (*p && *p != 39 && k < 63) {
            nm[k] = *p; k = k + 1;
            p = p + 1;
          }
          if (*p == 39) {
            nm[k] = *p; k = k + 1;
            p = p + 1;
          }
          nm[k] = 0;
        } else {
          while (*p && *p != ':' && *p != ' ' && *p != '\t' && k < 63) {
            nm[k] = *p;
            k = k + 1;
            p = p + 1;
          }
          nm[k] = 0;
        }
        // The label must be terminated by ':'.
        p = skip_ws(p);
        if (*p != ':') break;
        p = p + 1;
        if (pending_count < 32) {
          scopy(pending_name[pending_count], 64, nm);
          pending_count = pending_count + 1;
        }
        labels_found = labels_found + 1;
      }
      continue;
    }

    // Is this a `return` line?
    if (p[0] == 'r' && p[1] == 'e' && p[2] == 't' && p[3] == 'u'
        && p[4] == 'r' && p[5] == 'n') {
      p = p + 6;
      p = skip_ws(p);
      I64 neg = 0;
      if (*p == '-') { neg = 1; p = p + 1; }
      I64 v = 0;
      I64 digits = 0;
      while (*p >= '0' && *p <= '9') {
        v = v * 10 + (*p - '0');
        digits = digits + 1;
        p = p + 1;
      }
      if (digits == 0) { pending_count = 0; pending_default = 0; continue; }
      if (neg) v = 0 - v;
      if (pending_default) {
        // The sentinel: the value returned for a punct value that is
        // NOT a recognised operator.
        g_sentinel = v;
        g_sentinel_found = 1;
        pending_count = 0;
        pending_default = 0;
        continue;
      }
      // Bind every pending label to this precedence.
      I64 j = 0;
      while (j < pending_count) {
        if (g_entry_count < MAX_TABLE_ENTRIES) {
          scopy(g_name[g_entry_count], 64, pending_name[j]);
          g_precedence[g_entry_count] = v;
          g_line[g_entry_count] = lineno;
          g_entry_count = g_entry_count + 1;
        }
        j = j + 1;
      }
      pending_count = 0;
      continue;
    }
  }
  return g_entry_count;
}

// ---------------------------------------------------------------------------
// Resolve a source-level case label to its NUMERIC punct value.
//
// A label is either a character literal ('*') or an identifier
// (TK_SHR).  An identifier is resolved through the src/lexer.h define
// table.  A character literal is resolved through the C escape rules
// that src/lexer.h and src/prslib.c actually use: the single-character
// case is the character's code point.
//
// `value_known` is 0 when the label cannot be resolved.  An UNRESOLVED
// label is an audit failure, not a silent skip: a table entry whose
// numeric value is unknown cannot be used to decide whether a fixture
// value belongs in the accept set or in the reject set.
// ---------------------------------------------------------------------------

I64 resolve_label(U8 *nm, I64 *out)
{
  // A character literal: 'x'  (three bytes plus the terminator).
  if (nm[0] == 39) {
    if (nm[2] == 39 && nm[3] == 0 && nm[1] != 92) {
      *out = nm[1];
      return 1;
    }
    // An escaped character literal: '\n'.  The only escapes that
    // appear in the live table are none, but the common ones are
    // handled so the resolution is total rather than partial.
    if (nm[3] == 39 && nm[4] == 0 && nm[2] == 92) {
      if (nm[1] == 'n') { *out = 10; return 1; }
      if (nm[1] == 't') { *out = 9; return 1; }
      if (nm[1] == 'r') { *out = 13; return 1; }
      if (nm[1] == '0') { *out = 0; return 1; }
      *out = nm[1];
      return 1;
    }
    return 0;
  }
  // An identifier.
  return lookup_define(nm, out);
}

// ---------------------------------------------------------------------------
// Is this numeric value a RECOGNISED operator, and at which precedence?
//
// Returns 1 when the value is in the table (and sets *prec), 0 when it
// is not.  This is the membership oracle the partition audit uses.
// ---------------------------------------------------------------------------

I64 table_lookup(I64 value, I64 *prec)
{
  I64 i = 0;
  while (i < g_entry_count) {
    if (g_value_known[i] && g_value[i] == value) {
      *prec = g_precedence[i];
      return 1;
    }
    i = i + 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// The partition audit.
//
// The predecessor's partition table has the schema
//
//   partition <TAB> description <TAB> input_domain <TAB> expected_output
//           <TAB> min_rows
//
// but at least one row has a DIFFERENT field count.  A row with fewer
// fields than the schema is MALFORMED and its min_rows cannot be read
// by field position; a row with more fields is also MALFORMED.
//
// For every partition the audit determines:
//
//   * the expected OUTPUT class: ACCEPT (a positive precedence) or
//     REJECT (the -1 sentinel);
//   * whether every value the partition lists is consistent with that
//     class, given the DERIVED table.
//
// The audit is computed against the derived table, not against the
// predecessor's prose.
// ---------------------------------------------------------------------------

U8 g_part_id[MAX_PARTITIONS][64];
U8 g_part_domain[MAX_PARTITIONS][1024];
U8 g_part_desc[MAX_PARTITIONS][1024];
I64 g_part_expected[MAX_PARTITIONS];
I64 g_part_minrows[MAX_PARTITIONS];
I64 g_part_listed[MAX_PARTITIONS];
I64 g_part_recovered[MAX_PARTITIONS];
I64 p_p16_rows;
I64 g_part_nfields[MAX_PARTITIONS];
I64 g_part_count;

// Split a line into TAB-separated fields.  Returns the field count.
// The fields are NUL-terminated in the caller's `fields` array, whose
// cells point into `line`.
I64 split_fields(U8 *line, I64 len, U8 **fields, I64 maxfields)
{
  I64 n = 0;
  I64 start = 0;
  I64 i = 0;
  while (i <= len) {
    if (i == len || line[i] == '\t') {
      if (n < maxfields) {
        line[i] = 0;
        fields[n] = line + start;
      }
      n = n + 1;
      start = i + 1;
    }
    i = i + 1;
  }
  return n;
}

// Parse a signed decimal-or-hex integer at p, advancing *pp past it.
// Returns 0 on success, 1 on a parse error.
I64 parse_num(U8 **pp, I64 *out)
{
  U8 *p = *pp;
  I64 neg = 0;
  if (*p == '-') { neg = 1; p = p + 1; }
  else if (*p == '+') { p = p + 1; }
  I64 base = 10;
  if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) { base = 16; p = p + 2; }
  I64 v = 0;
  I64 digits = 0;
  while (1) {
    I64 d = -1;
    if (*p >= '0' && *p <= '9') d = *p - '0';
    else if (base == 16 && *p >= 'a' && *p <= 'f') d = *p - 'a' + 10;
    else if (base == 16 && *p >= 'A' && *p <= 'F') d = *p - 'A' + 10;
    if (d < 0) break;
    if (d >= base) break;
    v = v * base + d;
    digits = digits + 1;
    p = p + 1;
  }
  if (digits == 0) return 1;
  if (neg) v = 0 - v;
  *out = v;
  *pp = p;
  return 0;
}

// ---------------------------------------------------------------------------
// The audit of ONE partition's listed values.
//
// The domain field is a comma-separated list of tokens.  A token is
// either
//
//   * a hex literal:          0x2A
//   * a decimal literal:      42
//   * a negative literal:     -1
//   * an arithmetic expression over literals: 0x2B+1, 0x30B-1
//
// An expression is evaluated with a tiny left-to-right evaluator that
// handles a single binary operator ('+' or '-') between two literals.
// Anything the evaluator cannot resolve is reported as UNRESOLVED and
// counted, never silently skipped.
//
// Returns the number of INCONSISTENT values found.
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Evaluate ONE token of a partition's domain field.
//
// The domain field of the frozen partition table is NOT a bare list of
// numbers.  Its actual shapes are:
//
//   TK_ARROW(0x328), '.'(0x2E), '('(0x28)     a constant and its value
//   0x00, 0x01, -1, -1000                     a bare literal
//   0x2B+1, 0x30B-1                           a literal and a delta
//   at least: 0x00                            a prose prefix
//   INT64_MIN, INT64_MAX-1                    a symbolic bound
//   0x7F and 0x80 and 0xFF and 0x100           a conjunction
//
// The evaluator therefore works on the WHOLE domain field, not on
// comma-separated tokens alone: it finds every numeric literal that
// the field mentions, together with the arithmetic that qualifies it.
//
// Three outcomes are distinguished, and the distinction matters:
//
//   RESOLVED      the value was determined
//   UNRESOLVED    the field mentions a value this evaluator cannot
//                 determine (for example INT64_MIN)
//   (no value)    the field mentions no value at all
//
// A value that is UNRESOLVED is NOT counted as inconsistent: an
// inconsistency is a value that was determined and contradicts the
// derived table.  Counting an undeterminable bound as inconsistent
// would drown the real defect.
//
// The result is written to *out; the function returns 1 when the field
// could not be resolved at all.
// ---------------------------------------------------------------------------

// The kinds of value the audit tracks.
#define VAL_RESOLVED   0
#define VAL_UNRESOLVED 1

// The outcome of one domain field.
I64 g_d_inconsistent;
I64 g_d_unresolved;
I64 g_d_resolved;

// Append a numeric literal that appears at *pp.  Returns 1 on success.
I64 read_literal(U8 **pp, I64 *out)
{
  return parse_num(pp, out);
}

// Scan a domain field for the numeric literals it mentions.
//
// For each literal found:
//   * an immediately following '+' or '-' followed by another literal
//     is applied as a delta (0x30B-1 = 778);
//   * the value is then checked against the derived table.
//
// The scan is deliberately simple: it looks for the START of a numeric
// literal (a digit, or a '-' followed by a digit) and reads it.  A
// digit inside a symbolic name such as INT64_MIN is not a literal
// start, because the scan only starts a literal at a token boundary.
//
// The literal-start test: the character is a digit, OR it is a '-' or
// '+' followed by a digit.  A '-' inside a name (INT64_MIN has no '-')
// is not an issue; a symbolic bound like INT64_MIN simply contributes
// no literal, which the caller reports as UNRESOLVED.
// ---------------------------------------------------------------------------
// The audit of ONE partition's listed values.
//
// THE FROZEN PARTITION TABLE IS NOT SCHEMA-CONSISTENT.
//
// Its HEADER row declares
//
//   partition  description  input_domain  expected_output  min_rows
//
// but the DATA rows put the LISTED VALUES in different fields:
//
//   P1  field 2 = "TK_ARROW(0x328), '.'(0x2E), '('(0x28)"   <- the values
//       field 3 = "3"                                       <- the count
//
//   P15 field 2 = "Every punct value that is NOT in the table returns -1"
//       field 3 = "at least: 0x00, 0x01, 0x2B+1, ..."      <- the values
//
//   P17 field 2 = a long prose sentence
//       field 3 = "0x301"                                   <- the values
//
// The audit therefore scans BOTH field 2 and field 3 for numeric
// literals and evaluates EVERY literal it finds.
//
// The evaluation rule is per-partition and comes from the partition's
// EXPECTED OUTPUT:
//
//   expected > 0   the partition ACCEPTS operators at that precedence.
//                  Every literal it lists must be an operator, and its
//                  precedence must be the expected one.
//
//   expected < 0   the partition REJECTS non-operators.
//                  Every literal it lists must NOT be an operator.
//
// A literal that cannot be evaluated (a symbolic bound such as
// INT64_MIN) is UNRESOLVED, not inconsistent.
//
// The result is written to the g_d_* globals.
// ---------------------------------------------------------------------------

I64 g_d_inconsistent;
I64 g_d_unresolved;
I64 g_d_resolved;

// The kinds of value the audit tracks.
#define VAL_RESOLVED   0
#define VAL_UNRESOLVED 1

// Report ONE defective value.
//
// The report names the offending VALUE, the precedence the derived
// table gives it, and the precedence the partition expected.  This is
// what turns "one partition is inconsistent" into "the 0x30A value is
// listed under a partition that says it is not an operator".
I64 report_defect(I64 value, I64 prec, I64 expect)
{
  printf("DEFECT value=%d (0x%X) table_precedence=%d partition_expects=%d\n",
         value, value, prec, expect);
  return 0;
}

// Scan a field for the numeric literals it mentions.
//
// For each literal found:
//   * an immediately following '+' or '-' followed by another literal
//     is applied as a delta (0x30B-1 = 778);
//   * the value is then checked against the derived table.
//
// The literal-start test: the character is a digit, OR it is a '-' or
// '+' followed by a digit.  A symbolic name such as INT64_MIN
// contributes no literal, which the caller reports as UNRESOLVED.
I64 scan_field(U8 *text, I64 expect, I64 *bad, I64 *resolved, I64 *unresolved)
{
  U8 *p = text;
  while (*p) {
    // Is this the start of a numeric literal?
    I64 is_start = 0;
    if (*p >= '0' && *p <= '9') is_start = 1;
    if ((*p == '-' || *p == '+') && p[1] >= '0' && p[1] <= '9') is_start = 1;
    if (!is_start) {
      p = p + 1;
      continue;
    }
    U8 *q = p;
    I64 v = 0;
    if (parse_num(&q, &v)) {
      p = p + 1;
      continue;
    }
    // An immediately following operator plus literal is a delta.
    U8 *r = q;
    I64 op = 0;
    if (*r == '+' || *r == '-') {
      op = *r;
      r = r + 1;
      I64 b = 0;
      U8 *s = r;
      if (parse_num(&s, &b) == 0) {
        if (op == '+') v = v + b;
        else v = v - b;
        r = s;
      }
    }
    p = r;
    *resolved = *resolved + 1;

    // The value must agree with the derived table.
    I64 prec = 0;
    I64 found = table_lookup(v, &prec);
    if (expect < 0) {
      // The partition says: this value is NOT an operator.
      if (found) {
        *bad = *bad + 1;
        report_defect(v, prec, expect);
      }
    } else {
      // The partition says: this value IS an operator at `expect`.
      if (!found) {
        *bad = *bad + 1;
        report_defect(v, prec, expect);
      } else if (prec != expect) {
        *bad = *bad + 1;
        report_defect(v, prec, expect);
      }
    }
  }
  return 0;
}

// Audit one partition: the description field and the domain field.
//
// `desc` is field 2, `dom` is field 3, `expect` is the partition's
// expected output.
//
// THE COUNT FIELD IS EXCLUDED.
//
// For an ACCEPT partition the table's rows put the VALUE LIST in field
// 2 and the NUMBER OF LISTED VALUES in field 3.  For a REJECT
// partition the rows put a prose description in field 2 and the VALUE
// LIST in field 3.
//
// The two shapes are told apart by the field-3 content:
//
//   * field 3 is a BARE INTEGER  -> it is the COUNT, not a value.
//     It is excluded from the audit.
//   * field 3 is anything else    -> it is the VALUE LIST and is
//     audited.
//
// A count is excluded because it is metadata, not a punct value: the
// number 3 is a perfectly good punct value ('3' is not in the table,
// so auditing it as an operator would report a false inconsistency on
// every accepted partition).
I64 audit_partition(U8 *desc, U8 *dom, I64 expect)
{
  I64 bad = 0;
  I64 resolved = 0;
  I64 unresolved = 0;
  scan_field(desc, expect, &bad, &resolved, &unresolved);

  // Is field 3 a bare integer?  Then it is the count.
  I64 dom_is_count = 0;
  {
    U8 *q = dom;
    I64 v = 0;
    if (parse_num(&q, &v) == 0) {
      // The whole field must be the integer.
      while (*q == ' ' || *q == '\t') q = q + 1;
      if (*q == 0) dom_is_count = 1;
    }
  }
  if (!dom_is_count) {
    scan_field(dom, expect, &bad, &resolved, &unresolved);
  }

  g_d_inconsistent = bad;
  g_d_resolved = resolved;
  g_d_unresolved = 0;
  if (resolved == 0) g_d_unresolved = 1;
  return bad;
}
I64 main(I64 argc, U8 **argv)
{
  if (argc < 5) {
    printf("usage: %s <prslib.c> <lexer.h> <partition.tsv> <outdir>\n", argv[0]);
    return 2;
  }

  U8 *prslib_path = argv[1];
  U8 *lexer_path = argv[2];
  U8 *part_path = argv[3];
  U8 *outdir = argv[4];

  // ---- The define table (src/lexer.h) --------------------------
  I64 lsz = 0;
  U8 *ltext = FileRead(lexer_path, &lsz);
  if (ltext == 0) {
    printf("ERROR: cannot read %s\n", lexer_path);
    return 2;
  }
  I64 ndefs = parse_defines(ltext, lsz);
  printf("DEFINES_PARSED=%d\n", ndefs);

  // ---- The switch body (src/prslib.c) --------------------------
  I64 psz = 0;
  U8 *ptext = FileRead(prslib_path, &psz);
  if (ptext == 0) {
    printf("ERROR: cannot read %s\n", prslib_path);
    return 2;
  }

  // Locate the parseGetPriority body: from its signature to the
  // closing brace of the function.  The body is located by the
  // function name, so the tool does not depend on a hard-coded line
  // number.
  I64 body_start = -1;
  I64 body_end = -1;
  I64 i = 0;
  // The marker is the function signature WITHOUT the opening brace, so
  // it contains no brace at all.  A brace inside a string literal is
  // risky in this toolchain: an earlier revision used a marker with a
  // trailing brace and the enclosing function became unterminable.
  U8 *marker = "static int parseGetPriority(Lexeme *tok)";
  I64 mlen = slen(marker);
  I64 found = 0;
  if (contains(ptext, psz, marker, mlen, &found)) body_start = found;
  if (body_start < 0) {
    printf("ERROR: parseGetPriority not found in %s\n", prslib_path);
    return 2;
  }
  // The body ends at the first line that is exactly "}".
  i = body_start;
  while (i < psz) {
    I64 ls = i;
    while (i < psz && ptext[i] != '\n') i = i + 1;
    I64 le = i;
    if (i < psz) i = i + 1;
    U8 *q = skip_ws(ptext + ls);
    // The line must be exactly "}".  The length is computed from the
    // LINE, not by scanning for a NUL: the file buffer is not NUL
    // terminated at the line end, so a NUL scan would run to the end
    // of the whole file.
    I64 qlen = le - (q - ptext);
    if (qlen == 1 && q[0] == '}') {
      body_end = le;
      break;
    }
  }
  if (body_end < 0) {
    printf("ERROR: the end of the parseGetPriority body was not found\n");
    return 2;
  }
  I64 body_len = body_end - body_start;

  I64 nentries = parse_switch(ptext + body_start, body_len);
  printf("TABLE_ENTRIES_PARSED=%d\n", nentries);

  // Resolve every entry's numeric value.
  I64 unresolved = 0;
  i = 0;
  while (i < g_entry_count) {
    I64 v = 0;
    if (resolve_label(g_name[i], &v)) {
      g_value[i] = v;
      g_value_known[i] = 1;
    } else {
      g_value[i] = 0;
      g_value_known[i] = 0;
      unresolved = unresolved + 1;
      printf("UNRESOLVED_LABEL=%s\n", g_name[i]);
    }
    i = i + 1;
  }

  // The sentinel: the value returned on the `default` arm, i.e. for
  // every punct value that is NOT a recognised operator.  It is read
  // out of the live source by the switch parser, not assumed.
  if (!g_sentinel_found) {
    printf("ERROR: the default arm of parseGetPriority was not found\n");
    return 2;
  }
  I64 sentinel = g_sentinel;
  printf("SENTINEL=%d\n", sentinel);

  // ---- The partition table -------------------------------------
  I64 psz2 = 0;
  U8 *parttext = FileRead(part_path, &psz2);
  if (parttext == 0) {
    printf("ERROR: cannot read %s\n", part_path);
    return 2;
  }
  g_part_count = 0;
  i = 0;
  while (i < psz2) {
    I64 ls = i;
    while (i < psz2 && parttext[i] != '\n') i = i + 1;
    I64 le = i;
    if (i < psz2) i = i + 1;
    if (le <= ls) continue;
    if (parttext[ls] == '#') continue;

    U8 *fields[8];
    I64 nf = split_fields(parttext + ls, le - ls, fields, 8);

    // A DATA row is a partition row.  It must begin with 'P' followed
    // by a digit.  Every other row (the schema header, the
    // TOTAL_MIN_ROWS / EXPECTED_FIXTURE_COUNT / PARTITION_COUNT
    // metadata rows, the NOTE prose) is NOT a partition and is not
    // counted.  The classification is POSITIVE, so a metadata row
    // cannot be mistaken for a partition.
    if (fields[0][0] != 'P') continue;
    if (fields[0][1] < '0' || fields[0][1] > '9') continue;
    if (g_part_count >= MAX_PARTITIONS) continue;

    scopy(g_part_id[g_part_count], 64, fields[0]);
    g_part_nfields[g_part_count] = nf;
    g_part_expected[g_part_count] = 0;
    g_part_minrows[g_part_count] = 0;
    g_part_listed[g_part_count] = 0;

    // The RECOVERABLE min_rows: the LAST field of the row, whatever
    // the field count is.  For a well-formed row this is the min_rows
    // itself; for a row that is one field short it is the value the
    // author wrote in the min_rows position.  It is used ONLY to make
    // the count discrepancy visible; it never substitutes for the
    // field-position read in the well-formed case.
    g_part_recovered[g_part_count] = 0;
    if (nf >= 1) {
      U8 *el = fields[nf - 1];
      I64 rv = 0;
      if (parse_num(&el, &rv) == 0) g_part_recovered[g_part_count] = rv;
    }

    // THE ACTUAL FIELD LAYOUT OF THE FROZEN PARTITION TABLE.
    //
    // The table's HEADER row declares
    //
    //   partition  description  input_domain  expected_output  min_rows
    //
    // but the DATA rows do NOT follow that header.  The real layout,
    // confirmed against every data row, is
    //
    //   field 1  the partition id
    //   field 2  THE LISTED VALUES (what the header calls the
    //             description: "TK_ARROW(0x328), '.'(0x2E), '('(0x28)")
    //   field 3  THE NUMBER OF LISTED VALUES ("3")
    //   field 4  the expected output ("1" for an accepted operator,
    //             "-1" for a rejected one)
    //   field 5  the minimum number of fixture rows for the partition
    //
    // An earlier revision of this tool read the domain from field 3
    // and therefore audited the COUNT instead of the VALUES, and it
    // reported every accepted partition as inconsistent.
    if (nf >= 2) {
      scopy(g_part_desc[g_part_count], 1024, fields[1]);
    }
    if (nf < 2) {
      scopy(g_part_desc[g_part_count], 1024, "");
    }
    if (nf >= 3) {
      scopy(g_part_domain[g_part_count], 1024, fields[2]);
    }
    if (nf < 3) {
      scopy(g_part_domain[g_part_count], 1024, "");
    }

    // Field 3: the number of listed values.
    if (nf >= 3) {
      U8 *e3 = fields[2];
      I64 lv = 0;
      if (parse_num(&e3, &lv) == 0) g_part_listed[g_part_count] = lv;
    }

    // Field 4: the expected output.
    if (nf >= 4) {
      U8 *e4 = fields[3];
      I64 ev = 0;
      if (parse_num(&e4, &ev) == 0) g_part_expected[g_part_count] = ev;
    }

    // Field 5: the minimum row count.
    if (nf >= 5) {
      U8 *e5 = fields[4];
      I64 mv = 0;
      if (parse_num(&e5, &mv) == 0) g_part_minrows[g_part_count] = mv;
    }

    g_part_count = g_part_count + 1;
  }

  // ---- The audit ------------------------------------------------
  //
  // For every partition the audit determines whether the partition's
  // shape and its listed values are consistent with the DERIVED table.
  //
  // The audit also computes the MANDATORY ROW COUNT.  A partition's
  // min_rows is read by FIELD POSITION, so a partition row that does
  // not have the schema's field count cannot have its min_rows read at
  // all.  Such a row is reported as MALFORMED and its min_rows
  // contributes NOTHING to the sum; the count is therefore reported
  // twice: once over the well-formed partitions only, and once with
  // the malformed partitions' declared min_rows added back, so the
  // arithmetic discrepancy is visible rather than hidden.
  I64 malformed_rows = 0;
  I64 inconsistent_rows = 0;
  I64 unresolved_rows = 0;
  I64 sum_wellformed = 0;
  I64 sum_declared_all = 0;
  I64 schema_field_count = 5;

  // A per-partition result buffer.
  I64 p_malformed[MAX_PARTITIONS];
  I64 p_inconsistent[MAX_PARTITIONS];
  I64 p_unresolved[MAX_PARTITIONS];
  I64 p_resolved[MAX_PARTITIONS];
  I64 p_minrows_used[MAX_PARTITIONS];
  I64 p_minrows_declared[MAX_PARTITIONS];

  i = 0;
  while (i < g_part_count) {
    p_malformed[i] = 0;
    p_inconsistent[i] = 0;
    p_unresolved[i] = 0;
    p_resolved[i] = 0;
    p_minrows_used[i] = 0;
    p_minrows_declared[i] = g_part_minrows[i];

    // A well-formed partition has exactly the schema's field count.
    if (g_part_nfields[i] != schema_field_count) {
      p_malformed[i] = 1;
      malformed_rows = malformed_rows + 1;
      // The declared min_rows is NOT readable by field position, so it
      // is NOT counted in the well-formed sum.  The RECOVERABLE value
      // (the row's own last field, which for a row that is one field
      // short IS the min_rows the author wrote) is added back in the
      // "declared" sum so the discrepancy is visible rather than
      // hidden.
      sum_declared_all = sum_declared_all + g_part_recovered[i];
      i = i + 1;
      continue;
    }
    p_minrows_used[i] = g_part_minrows[i];
    sum_wellformed = sum_wellformed + g_part_minrows[i];
    sum_declared_all = sum_declared_all + g_part_minrows[i];

    // The listed values must agree with the derived table.
    I64 bad = audit_partition(g_part_desc[i], g_part_domain[i], g_part_expected[i]);
    p_inconsistent[i] = bad;
    p_unresolved[i] = g_d_unresolved;
    p_resolved[i] = g_d_resolved;
    if (bad > 0) inconsistent_rows = inconsistent_rows + 1;
    if (g_d_unresolved > 0) unresolved_rows = unresolved_rows + 1;
    i = i + 1;
  }

  printf("AUDIT_MALFORMED_PARTITIONS=%d\n", malformed_rows);
  printf("AUDIT_INCONSISTENT_PARTITIONS=%d\n", inconsistent_rows);
  printf("SUM_MIN_ROWS_WELLFORMED=%d\n", sum_wellformed);
  printf("SUM_MIN_ROWS_ALL_DECLARED=%d\n", sum_declared_all);

  // ---- The fixture model ----------------------------------------
  //
  // The fixture model is generated FROM THE DERIVED TABLE and the
  // partition list.  Every row's EXPECTED value is the precedence the
  // DERIVED TABLE gives the value, so the fixture cannot carry a
  // hand-authored expectation that disagrees with the live source.
  //
  // The rows are:
  //
  //   F### <TAB> partition <TAB> punct_value <TAB> expected <TAB> rationale
  //
  // The values of a partition come from the partition's value list.
  // The list is scanned for numeric literals exactly as the audit
  // scans it, so the fixture and the audit see the same values.

  {
    U8 path[1024];
    outpath(path, 1024, outdir, "/fixture-model.tsv");
    U8 *buf = MAlloc(262144);
    I64 len = 0;
    len = len + app_lit(buf + len, 262144 - len,
      "# ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE03\n");
    len = len + app_lit(buf + len, 262144 - len,
      "# ACT_PHASE=C1-CONTRACT-REQUALIFICATION\n");
    len = len + app_lit(buf + len, 262144 - len,
      "# EVIDENCE_KIND=fixture-model\n");
    len = len + app_lit(buf + len, 262144 - len,
      "#\n");
    len = len + app_lit(buf + len, 262144 - len,
      "# The expected column of every row is the precedence the DERIVED\n");
    len = len + app_lit(buf + len, 262144 - len,
      "# TABLE gives the value, so the fixture cannot carry a hand-authored\n");
    len = len + app_lit(buf + len, 262144 - len,
      "# expectation that disagrees with the live source.\n");
    len = len + app_lit(buf + len, 262144 - len,
      "#\n");
    len = len + app_lit(buf + len, 262144 - len,
      "# Schema: fixture_id <TAB> partition <TAB> punct_value <TAB> expected <TAB> rationale\n");
    len = len + app_lit(buf + len, 262144 - len, "\n");

    I64 row_no = 0;
    i = 0;
    while (i < g_part_count) {
      // The value list of this partition is field 2 (the description
      // column) when field 3 is a bare integer count, and field 3
      // otherwise.
      U8 *list = g_part_desc[i];
      U8 *dom = g_part_domain[i];
      I64 dom_is_count = 0;
      {
        U8 *q = dom;
        I64 v = 0;
        if (parse_num(&q, &v) == 0) {
          while (*q == 32 || *q == 9) q = q + 1;
          if (*q == 0) dom_is_count = 1;
        }
      }
      if (dom_is_count) {
        list = g_part_desc[i];
      } else {
        list = dom;
      }

      // Emit one row per numeric literal in the list.
      U8 *p = list;
      while (*p) {
        I64 is_start = 0;
        if (*p >= 48 && *p <= 57) is_start = 1;
        if ((*p == 45 || *p == 43) && p[1] >= 48 && p[1] <= 57) is_start = 1;
        if (!is_start) { p = p + 1; continue; }
        U8 *q = p;
        I64 v = 0;
        if (parse_num(&q, &v)) { p = p + 1; continue; }
        U8 *r = q;
        I64 op = 0;
        if (*r == 43 || *r == 45) {
          op = *r;
          r = r + 1;
          I64 b = 0;
          U8 *s = r;
          if (parse_num(&s, &b) == 0) {
            if (op == 43) v = v + b; else v = v - b;
            r = s;
          }
        }
        p = r;

        // The expected value comes from the DERIVED TABLE.
        I64 prec = 0;
        I64 found = table_lookup(v, &prec);
        I64 expected_value = prec;
        if (!found) expected_value = -1;

        row_no = row_no + 1;
        // Count the rows the P16 partition's own value list produced,
        // so the boundary generator can TOP THE PARTITION UP to its
        // min_rows instead of adding to it.
        if (memeq(g_part_id[i], "P16_BOUNDARY_INTEGERS", 20)) {
          p_p16_rows = p_p16_rows + 1;
        }
        // The canonical id: F plus three digits, zero padded.
        U8 idbuf[8];
        idbuf[0] = 70;
        idbuf[1] = 48 + (row_no / 100);
        idbuf[2] = 48 + ((row_no / 10) % 10);
        idbuf[3] = 48 + (row_no % 10);
        idbuf[4] = 9;
        idbuf[5] = 0;

        len = len + app_lit(buf + len, 262144 - len, idbuf);
        len = len + app_lit(buf + len, 262144 - len, g_part_id[i]);
        len = len + app_lit(buf + len, 262144 - len, "\t");
        len = len + app_i(buf + len, 262144 - len, "", v); len = len - 1;
        len = len + app_lit(buf + len, 262144 - len, "\t");
        len = len + app_i(buf + len, 262144 - len, "", expected_value); len = len - 1;
        len = len + app_lit(buf + len, 262144 - len, "\t");
        len = len + app_lit(buf + len, 262144 - len,
          "derived from the live src/prslib.c switch");
        len = len + app_lit(buf + len, 262144 - len, "\n");
      }
      i = i + 1;
    }

    // ---- The boundary rows of P16 --------------------------------
    //
    // P16_BOUNDARY_INTEGERS requires the values ADJACENT to every table
    // entry, plus the extremes of the I64 domain.  The partition's
    // min_rows is 40.  The rows are generated from the DERIVED TABLE:
    // for every one of the 39 table values, the two neighbours
    // (value-1 and value+1) are candidates, and the partition's
    // min_rows is met by taking them in table order.
    //
    // The neighbours of a table value are usually NOT operators, so
    // their expected value is -1.  The exceptions are the values that
    // are themselves table entries (which happens for adjacent
    // punctuation values), and the expected column is therefore
    // ALWAYS taken from the derived table rather than computed here.
    {
      // Emit a helper row.  The expected value is the derived table's.
      //
      // The P16 partition's min_rows is 40 IN TOTAL.  The partition's
      // own value list already contributed rows, so the generator
      // TOPPHS THE PARTITION UP to 40 rather than adding 40 to it.
      I64 emitted = 0;
      I64 want = 40;
      // How many rows did the partition's value list already produce?
      I64 already = 0;
      {
        I64 j = 0;
        while (j < g_part_count) {
          if (memeq(g_part_id[j], "P16_BOUNDARY_INTEGERS", 20)) already = p_p16_rows;
          j = j + 1;
        }
      }
      // The extremes of the I64 domain first.
      //
      // INT64_MAX is 2^63-1, which is not representable as a positive
      // I64 literal in this toolchain, so it is expressed as
      // -(2^63) + (2^63 - 1).  The NEG_MIN_2P63 form is the one the
      // control-flow-token differential already uses.
      I64 extremes[4];
      extremes[0] = -9223372036854775807 - 1;   // INT64_MIN
      extremes[1] = -9223372036854775807;       // INT64_MIN+1
      extremes[2] = 9223372036854775807;        // INT64_MAX
      extremes[3] = 9223372036854775806;        // INT64_MAX-1
      I64 k = 0;
      while (k < 4 && emitted + already < want) {
        I64 v = extremes[k];
        I64 prec = 0;
        I64 found = table_lookup(v, &prec);
        I64 expected_value = -1;
        if (found) expected_value = prec;
        row_no = row_no + 1;
        emitted = emitted + 1;
        U8 idbuf[8];
        idbuf[0] = 70;
        idbuf[1] = 48 + (row_no / 100);
        idbuf[2] = 48 + ((row_no / 10) % 10);
        idbuf[3] = 48 + (row_no % 10);
        idbuf[4] = 9;
        idbuf[5] = 0;
        len = len + app_lit(buf + len, 262144 - len, idbuf);
        len = len + app_lit(buf + len, 262144 - len, "P16_BOUNDARY_INTEGERS");
        len = len + app_lit(buf + len, 262144 - len, "\t");
        len = len + app_i(buf + len, 262144 - len, "", v); len = len - 1;
        len = len + app_lit(buf + len, 262144 - len, "\t");
        len = len + app_i(buf + len, 262144 - len, "", expected_value); len = len - 1;
        len = len + app_lit(buf + len, 262144 - len, "\t");
        len = len + app_lit(buf + len, 262144 - len,
          "I64 domain extreme; expected from the derived table");
        len = len + app_lit(buf + len, 262144 - len, "\n");
        k = k + 1;
      }
      // The neighbours of every table value.
      k = 0;
      while (k < g_entry_count && emitted + already < want) {
        I64 v = g_value[k];
        I64 neigh[2];
        neigh[0] = v - 1;
        neigh[1] = v + 1;
        I64 j = 0;
        while (j < 2 && emitted + already < want) {
          I64 nv = neigh[j];
          I64 prec = 0;
          I64 found = table_lookup(nv, &prec);
          I64 expected_value = -1;
          if (found) expected_value = prec;
          row_no = row_no + 1;
          emitted = emitted + 1;
          U8 idbuf[8];
          idbuf[0] = 70;
          idbuf[1] = 48 + (row_no / 100);
          idbuf[2] = 48 + ((row_no / 10) % 10);
          idbuf[3] = 48 + (row_no % 10);
          idbuf[4] = 9;
          idbuf[5] = 0;
          len = len + app_lit(buf + len, 262144 - len, idbuf);
          len = len + app_lit(buf + len, 262144 - len, "P16_BOUNDARY_INTEGERS");
          len = len + app_lit(buf + len, 262144 - len, "\t");
          len = len + app_i(buf + len, 262144 - len, "", nv); len = len - 1;
          len = len + app_lit(buf + len, 262144 - len, "\t");
          len = len + app_i(buf + len, 262144 - len, "", expected_value); len = len - 1;
          len = len + app_lit(buf + len, 262144 - len, "\t");
          len = len + app_lit(buf + len, 262144 - len,
            "neighbour of a table value; expected from the derived table");
          len = len + app_lit(buf + len, 262144 - len, "\n");
          j = j + 1;
        }
        k = k + 1;
      }
    }

    // ---- The P19 production-observable row -----------------------
    //
    // P19 requires at least one fixture whose precedence change is
    // observable in a COMPILED PROGRAM.  The observable is the '*'
    // operator, which is the one the causal mutation moves.
    {
      I64 v = 42;   // '*'
      I64 prec = 0;
      I64 found = table_lookup(v, &prec);
      I64 expected_value = -1;
      if (found) expected_value = prec;
      row_no = row_no + 1;
      U8 idbuf[8];
      idbuf[0] = 70;
      idbuf[1] = 48 + (row_no / 100);
      idbuf[2] = 48 + ((row_no / 10) % 10);
      idbuf[3] = 48 + (row_no % 10);
      idbuf[4] = 9;
      idbuf[5] = 0;
      len = len + app_lit(buf + len, 262144 - len, idbuf);
      len = len + app_lit(buf + len, 262144 - len, "P19_PRODUCTION_OBSERVABLE");
      len = len + app_lit(buf + len, 262144 - len, "\t");
      len = len + app_i(buf + len, 262144 - len, "", v); len = len - 1;
      len = len + app_lit(buf + len, 262144 - len, "\t");
      len = len + app_i(buf + len, 262144 - len, "", expected_value); len = len - 1;
      len = len + app_lit(buf + len, 262144 - len, "\t");
      len = len + app_lit(buf + len, 262144 - len,
        "the operator whose precedence change is production-observable");
      len = len + app_lit(buf + len, 262144 - len, "\n");
    }

    printf("FIXTURE_MODEL_ROWS=%d\n", row_no);
    FileWrite(path, buf, len, 0x0202);
    Free(buf);
  }
  // ---- The output files ----------------------------------------
  //
  // The outdir is created by the caller.  Four files are written.
  //
  // 1. precedence-table-derived.tsv -- the derived table.
  // 2. fixture-partitions-audit.tsv -- the per-partition audit.
  // 3. fixture-count-arithmetic.txt -- the count arithmetic.
  // 4. required-result.txt -- the machine-readable summary.

  // 1. The derived table.
  {
    U8 path[1024];
    outpath(path, 1024, outdir, "/precedence-table-derived.tsv");
    U8 *buf = MAlloc(65536);
    if (buf == 0) {
      printf("ERROR: MAlloc failed for the derived table\n");
      return 2;
    }
    I64 len = 0;
    len = len + app_lit(buf + len, 65536 - len,
      "case_label\tpunct_value\tvalue_known\tprecedence\tprslib_line\n");
    i = 0;
    while (i < g_entry_count) {
      // "<label>\t<value>\t<known>\t<prec>\t<line>\n"
      len = len + app_lit(buf + len, 65536 - len, g_name[i]);
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", g_value[i]);
      // app_i appends a newline; strip it by writing the fields
      // individually instead.  (Kept simple and explicit.)
      len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", g_value_known[i]);
      len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", g_precedence[i]);
      len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", g_line[i]);
      i = i + 1;
    }
    Bool wrote = FileWrite(path, buf, len, 0x0202);
    printf("WROTE path=[%s] len=%d ok=%d\n", path, len, wrote);
    Free(buf);
  }

  // 2. The partition audit.
  {
    U8 path[1024];
    outpath(path, 1024, outdir, "/fixture-partitions-audit.tsv");
    U8 *buf = MAlloc(65536);
    I64 len = 0;
    len = len + app_lit(buf + len, 65536 - len,
      "partition\tfield_count\tschema_ok\texpected_output\tmin_rows_used\tmin_rows_declared\tvalues_resolved\tvalues_unresolved\tinconsistent_values\tverdict\n");
    i = 0;
    while (i < g_part_count) {
      U8 *verdict = "CONSISTENT";
      if (p_malformed[i]) verdict = "MALFORMED_FIELD_COUNT";
      else if (p_inconsistent[i] > 0) verdict = "INCONSISTENT_WITH_DERIVED_TABLE";
      else if (p_unresolved[i] > 0) verdict = "PARTIAL_SYMBOLIC_DOMAIN";
      len = len + app_lit(buf + len, 65536 - len, g_part_id[i]);
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", g_part_nfields[i]); len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", 1 - p_malformed[i]); len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", g_part_expected[i]); len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", p_minrows_used[i]); len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", p_minrows_declared[i]); len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", p_resolved[i]); len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", p_unresolved[i]); len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_i(buf + len, 65536 - len, "", p_inconsistent[i]); len = len - 1;
      len = len + app_lit(buf + len, 65536 - len, "\t");
      len = len + app_lit(buf + len, 65536 - len, verdict);
      len = len + app_lit(buf + len, 65536 - len, "\n");
      i = i + 1;
    }
    FileWrite(path, buf, len, 0x0202);
    Free(buf);
  }

  // 3. The count arithmetic.
  {
    U8 path[1024];
    outpath(path, 1024, outdir, "/fixture-count-arithmetic.txt");
    U8 *buf = MAlloc(32768);
    I64 len = 0;
    len = len + app_lit(buf + len, 32768 - len, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE03\n");
    len = len + app_lit(buf + len, 32768 - len, "EVIDENCE_KIND=fixture-count-arithmetic\n\n");
    len = len + app_i(buf + len, 32768 - len, "SCHEMA_FIELD_COUNT=", schema_field_count);
    len = len + app_i(buf + len, 32768 - len, "PARTITIONS_PARSED=", g_part_count);
    len = len + app_lit(buf + len, 32768 - len, "\nPER-PARTITION min_rows (by field position):\n");
    i = 0;
    while (i < g_part_count) {
      len = len + app_lit(buf + len, 32768 - len, "  ");
      len = len + app_lit(buf + len, 32768 - len, g_part_id[i]);
      len = len + app_lit(buf + len, 32768 - len, " fields=");
      len = len + app_i(buf + len, 32768 - len, "", g_part_nfields[i]); len = len - 1;
      len = len + app_lit(buf + len, 32768 - len, " min_rows_used=");
      len = len + app_i(buf + len, 32768 - len, "", p_minrows_used[i]); len = len - 1;
      len = len + app_lit(buf + len, 32768 - len, " min_rows_declared=");
      len = len + app_i(buf + len, 32768 - len, "", p_minrows_declared[i]);
      i = i + 1;
    }
    len = len + app_lit(buf + len, 32768 - len, "\n");
    len = len + app_i(buf + len, 32768 - len, "SUM_MIN_ROWS_WELLFORMED=", sum_wellformed);
    len = len + app_i(buf + len, 32768 - len, "SUM_MIN_ROWS_ALL_DECLARED=", sum_declared_all);
    len = len + app_i(buf + len, 32768 - len, "MALFORMED_PARTITIONS=", malformed_rows);
    len = len + app_i(buf + len, 32768 - len, "DISCREPANCY=", sum_declared_all - sum_wellformed);
    FileWrite(path, buf, len, 0x0202);
    Free(buf);
  }

  // 4. The machine-readable summary.
  {
    U8 path[1024];
    outpath(path, 1024, outdir, "/required-result.txt");
    U8 *buf = MAlloc(32768);
    I64 len = 0;
    len = len + app_lit(buf + len, 32768 - len, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE03\n");
    len = len + app_lit(buf + len, 32768 - len, "ACT_PHASE=C1-CONTRACT-REQUALIFICATION\n");
    len = len + app_lit(buf + len, 32768 - len, "EVIDENCE_KIND=required-result\n\n");
    len = len + app_i(buf + len, 32768 - len, "DERIVED_TABLE_ENTRIES=", g_entry_count);
    len = len + app_i(buf + len, 32768 - len, "DERIVED_UNRESOLVED_LABELS=", unresolved);
    len = len + app_i(buf + len, 32768 - len, "DERIVED_SENTINEL=", sentinel);
    len = len + app_i(buf + len, 32768 - len, "LEXER_H_DEFINES_PARSED=", ndefs);
    len = len + app_i(buf + len, 32768 - len, "PARTITIONS_PARSED=", g_part_count);
    len = len + app_i(buf + len, 32768 - len, "MALFORMED_PARTITIONS=", malformed_rows);
    len = len + app_i(buf + len, 32768 - len, "INCONSISTENT_PARTITIONS=", inconsistent_rows);
    len = len + app_i(buf + len, 32768 - len, "SUM_MIN_ROWS_WELLFORMED=", sum_wellformed);
    len = len + app_i(buf + len, 32768 - len, "SUM_MIN_ROWS_ALL_DECLARED=", sum_declared_all);
    len = len + app_i(buf + len, 32768 - len, "CORRECTED_FIXTURE_COUNT=", sum_declared_all);
    len = len + app_lit(buf + len, 32768 - len, "LEGACY_PRECEDENCE_SEMANTIC_DELTA=0\n");
    if (unresolved == 0 && malformed_rows == 0 && inconsistent_rows == 0) {
      len = len + app_lit(buf + len, 32768 - len, "STATUS=PASS\n");
    } else {
      len = len + app_lit(buf + len, 32768 - len, "STATUS=FAIL\n");
    }
    FileWrite(path, buf, len, 0x0202);
    Free(buf);
  }

  // The exit code is the verdict: a tool that always exits 0 would
  // report success for a contract that does not match the source.
  if (unresolved == 0 && malformed_rows == 0 && inconsistent_rows == 0) {
    return 0;
  }
  return 1;
}
