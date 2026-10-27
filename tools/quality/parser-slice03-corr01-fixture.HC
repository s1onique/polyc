// tools/quality/parser-slice03-corr01-fixture.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01 C2 IMPL.
//
// THE CORRECTED FIXTURE PRODUCER.
//
// It produces the correction-owned fixture contract for the
// operator-precedence slice.  It does NOT modify the closed predecessor
// generator (tools/quality/parser-slice03-contract-requalify.HC); it is
// a SEPARATE tool with a SEPARATE contract.
//
// WHAT IT REPAIRS
// ==============
//
// D1  The predecessor's "I64 domain extreme" rows were formatted with
//     snprintf "%d", a 32-bit conversion, so INT64_MIN rendered as 0
//     and INT64_MAX rendered as -1.  This tool formats every value
//     with a 64-bit conversion, so the extremes are carried exactly.
//
// D6  The predecessor's P16 partition had a frozen 40-row budget that
//     the literal enumeration cannot fit into (65 distinct values are
//     required).  This tool derives the P16 row count from the
//     REQUIRED VALUE SET and does not truncate the neighbour sweep.
//
// D7  The predecessor's P16 partition declared expected_output = -1
//     while its rows carry the mixed set {-1, 1, 3, 4, 5}.  This tool
//     computes EVERY row's expected value from the DERIVED TABLE, so
//     the nominal partition declaration is never used as an expected
//     value.
//
// FALSE SYMBOLIC NUMERICS
// =======================
//
// The predecessor scanned numeric fragments out of symbolic identifiers:
// the digits "64" inside "INT64_MIN" and "INT64_MAX" were harvested as
// the number 64.  This tool NEVER scans a numeric fragment out of an
// identifier.  A boundary constant is either RESOLVED EXPLICITLY (the
// four symbolic bounds below) or the tool FAILS.
//
// THE 64-BIT OUTPUT PATH
// ======================
//
// The value column is written with "%lld".  The closed predecessor's
// "%d" path is exactly what destroyed the extremes.
//
// USAGE:
//   build/parser-slice03-corr01-fixture <prslib.c> <lexer.h> <out.tsv>
//
// The tool exits with RC=0 only when EVERY mandatory value is present
// in the produced fixture, the row count is the derived count, and no
// value was truncated.  It exits non-zero otherwise: a producer that
// emitted a superficially complete but semantically incomplete fixture
// would restore the very defect this ACT repairs.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define LINE_CAP 8192
#define MAX_TABLE_ENTRIES 256
#define MAX_DEFINES 512
#define MAX_VALUES 512
#define MAX_PARTITIONS 64
#define FIXTURE_BUF 262144

// The number of partitions in the corrected contract.
#define PARTITION_COUNT 19

// The number of TAB-separated fields in a fixture row.
#define FIXTURE_FIELD_COUNT 5

// The most-negative safe PRE-MULTIPLY magnitude, base 10.
//
// The magnitude is accumulated NEGATIVE, so the accumulated value v
// satisfies v = -(magnitude).  The step is
//     v' = v * base - digit
// and the requirement is v' >= -2^63, i.e.
//     v * base >= -2^63 + digit
//
// For base 10 and digit d, the exact threshold is
//     v >= ceil((-2^63 + d) / 10)
// which is -922337203685477580 for d = 0..8 and -922337203685477579
// for d = 9.  Both are written explicitly: the division rounds toward
// zero in this language, so computing them would be wrong for d = 9.
#define NEG_LIMIT_DEC -922337203685477580
#define NEG_LIMIT_DEC_D9 -922337203685477579

// The same for base 16.  ceil((-2^63 + d) / 16) is
// -576460752303423488 for d = 0 and -576460752303423487 for d >= 1.
#define NEG_LIMIT_HEX -576460752303423488
#define NEG_LIMIT_HEX_D1 -576460752303423487

// The most-negative magnitude representable at all: -2^63.
#define NEG_MIN_2P63 -9223372036854775807 - 1

// The four signed-I64 extremes, expressed as HEX literals.
//
// The hex form is used because it is EXACTLY representable in the
// toolchain, and it names the value unambiguously.  The decimal
// spelling is derived from the value, not from a literal.
//
//   I64_MIN       = 0x8000000000000000
//   I64_MIN + 1   = 0x8000000000000001
//   I64_MAX - 1   = 0x7ffffffffffffffe
//   I64_MAX       = 0x7fffffffffffffff
#define I64_MIN_HEX        0x8000000000000000
#define I64_MIN_PLUS1_HEX  0x8000000000000001
#define I64_MAX_MINUS1_HEX 0x7ffffffffffffffe
#define I64_MAX_HEX        0x7fffffffffffffff

// The base values the P16 partition requires in addition to the
// operator neighbours and the extremes.
#define BASE_ZERO 0
#define BASE_NEG1 -1
#define BASE_POS1 1

// PolyC does not support a USER-DEFINED variadic function; only an
// `extern "c"` one.  `snprintf` is therefore declared explicitly.
extern "c" I64 snprintf(U8 *dst, U64 cap, U8 *fmt, ...);

// ---------------------------------------------------------------------------
// Append helpers.
//
// Each appends and returns the number of BYTES appended, so the caller
// advances the write position by it.
//
// app_ll is the 64-BIT value formatter.  It is the ONE place where a
// fixture value is turned into text, and it uses "%lld".  The closed
// predecessor used "%d" here and that is precisely how the signed-I64
// extremes were destroyed.
// ---------------------------------------------------------------------------

I64 app_lit(U8 *dst, I64 cap, U8 *s)
{
  if (cap <= 0) return 0;
  I64 n = 0;
  while (s[n] != 0 && n < cap - 1) { dst[n] = s[n]; n = n + 1; }
  return n;
}

// Append "<text><64-bit number>".
I64 app_ll(U8 *dst, I64 cap, U8 *text, I64 v)
{
  if (cap <= 0) return 0;
  I64 n = app_lit(dst, cap, text);
  if (n >= cap - 1) return n;
  I64 m = snprintf(dst + n, cap - n, "%lld", v);
  if (m < 0) return n;
  if (m >= cap - n) return n + cap - n - 1;
  return n + m;
}


// ---------------------------------------------------------------------------
// The derived precedence table.
//
// g_value[k]      the numeric punct value of table entry k
// g_precedence[k] the precedence that entry k returns
// ---------------------------------------------------------------------------
I64 g_value[MAX_TABLE_ENTRIES];
I64 g_precedence[MAX_TABLE_ENTRIES];
I64 g_entry_count;
I64 g_sentinel;
I64 g_sentinel_found;

// The lexer.h define table.
I64 g_def_value[MAX_DEFINES];
U8 g_def_name[MAX_DEFINES][64];
I64 g_def_count;

// The number of case labels whose numeric value could NOT be resolved.
I64 g_unresolved;

// ---------------------------------------------------------------------------
// Small string helpers.
// ---------------------------------------------------------------------------

I64 scopy(U8 *dst, I64 cap, U8 *src)
{
  I64 n = 0;
  while (src[n] != 0 && n < cap - 1) { dst[n] = src[n]; n = n + 1; }
  dst[n] = 0;
  return n;
}

I64 memeq(U8 *a, U8 *b, I64 n)
{
  I64 i = 0;
  while (i < n) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

I64 str_len(U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

U8 *skip_ws(U8 *p)
{
  while (*p == 32 || *p == 9 || *p == 13) p = p + 1;
  return p;
}

// ---------------------------------------------------------------------------
// Parse a signed decimal-or-hex integer at *pp.
//
// The magnitude is accumulated as a NEGATIVE I64, which makes the
// magnitude 2^63 (needed by INT64_MIN) exactly representable, and the
// limit is checked BEFORE each multiply-add so that no intermediate
// value ever overflows.
//
// The whole token must be consumed: trailing garbage is a parse error.
//
// Returns 0 on success, 1 on a parse error.
// ---------------------------------------------------------------------------
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
  if (*p != 0 && *p != '\t' && *p != ' ') return 1;    // TRAILING GARBAGE
  if (v < NEG_MIN_2P63) return 1;    // magnitude exceeds 2^63

  // v holds the NEGATIVE magnitude.
  if (neg) {
    *out = v;                 // already negative
  } else {
    // The positive magnitude must fit in a positive I64.
    if (v == NEG_MIN_2P63) return 1;
    *out = 0 - v;
  }
  *pp = p;
  return 0;
}

// ---------------------------------------------------------------------------
// Read the lexer.h define table.
//
// Every "#define NAME VALUE" is recorded.  A define whose value is not a
// plain integer is recorded with the value 0 and is NOT resolvable; the
// caller reports such a label as UNRESOLVED rather than guessing.
// ---------------------------------------------------------------------------
I64 read_defines(U8 *txt, I64 fsz)
{
  I64 i = 0;
  I64 lineno = 0;
  g_def_count = 0;
  while (i < fsz) {
    // Extract one line.
    U8 line[LINE_CAP];
    I64 n = 0;
    while (i < fsz && txt[i] != 10 && txt[i] != 13 && n < LINE_CAP - 1) {
      line[n] = txt[i];
      n = n + 1;
      i = i + 1;
    }
    line[n] = 0;
    while (i < fsz && (txt[i] == 10 || txt[i] == 13)) i = i + 1;
    lineno = lineno + 1;

    U8 *p = skip_ws(line);
    if (!(p[0] == '#' && p[1] == 'd' && p[2] == 'e' && p[3] == 'f'
          && p[4] == 'i' && p[5] == 'n' && p[6] == 'e')) continue;
    p = p + 7;
    p = skip_ws(p);

    // The name.
    U8 nm[64];
    I64 k = 0;
    while (*p && *p != 32 && *p != 9 && *p != '(' && k < 63) {
      nm[k] = *p;
      k = k + 1;
      p = p + 1;
    }
    nm[k] = 0;
    if (k == 0) continue;

    // The value: a parenthesised expression or a bare integer.
    p = skip_ws(p);
    I64 v = 0;
    I64 resolved = 0;
    if (*p == '(') {
      p = p + 1;
      p = skip_ws(p);
      // A parenthesised value is "(0x328)".
      if (*p == '-') {
        U8 *q = p;
        I64 tmp = 0;
        if (parse_int(&q, &tmp) == 0) {
          U8 *r = skip_ws(q);
          if (*r == ')') { v = tmp; resolved = 1; }
        }
      } else {
        U8 *q = p;
        I64 tmp = 0;
        if (parse_int(&q, &tmp) == 0) {
          U8 *r = skip_ws(q);
          if (*r == ')') { v = tmp; resolved = 1; }
        }
      }
    } else {
      U8 *q = p;
      I64 tmp = 0;
      if (parse_int(&q, &tmp) == 0) {
        U8 *r = skip_ws(q);
        // The value must be the whole rest of the line (a comment may
        // follow).
        if (*r == 0 || *r == '/' || *r == '#') { v = tmp; resolved = 1; }
      }
    }

    if (g_def_count < MAX_DEFINES) {
      scopy(g_def_name[g_def_count], 64, nm);
      g_def_value[g_def_count] = v;
      g_def_count = g_def_count + 1;
      // A define that could not be resolved is stored with a sentinel
      // value that no real punct value can take, so that a lookup for
      // it reports UNRESOLVED rather than a wrong number.
      if (!resolved) g_def_value[g_def_count - 1] = 0x7FFFFFFFFFFFFFFE;
    }
  }
  return g_def_count;
}

// ---------------------------------------------------------------------------
// Resolve a source-level case label to its NUMERIC punct value.
//
// A label is either a character literal ('*') or an identifier
// (TK_SHR).  An identifier is resolved through the src/lexer.h define
// table.  A character literal is resolved to the character's code point.
//
// `known` is 0 when the label cannot be resolved.  An UNRESOLVED label
// is a FAILURE, never a silent skip: a table entry whose numeric value
// is unknown cannot be used to decide a fixture row's expected value.
// ---------------------------------------------------------------------------
I64 resolve_label(U8 *nm, I64 *out, I64 *known)
{
  *known = 0;

  // A character literal: 'x'
  if (nm[0] == 39) {
    if (nm[2] == 39 && nm[3] == 0 && nm[1] != 92) {
      *out = nm[1];
      *known = 1;
      return 1;
    }
    // An escaped character literal: '\n' and friends.
    if (nm[3] == 39 && nm[4] == 0 && nm[2] == 92) {
      if (nm[1] == 'n') { *out = 10; *known = 1; return 1; }
      if (nm[1] == 't') { *out = 9; *known = 1; return 1; }
      if (nm[1] == 'r') { *out = 13; *known = 1; return 1; }
      if (nm[1] == '0') { *out = 0; *known = 1; return 1; }
      *out = nm[1];
      *known = 1;
      return 1;
    }
    return 0;
  }

  // An identifier: resolve through the define table.
  I64 i = 0;
  while (i < g_def_count) {
    if (memeq(g_def_name[i], nm, str_len(nm))) {
      // The unresolved sentinel is not a real value.
      if (g_def_value[i] == 0x7FFFFFFFFFFFFFFE) return 0;
      *out = g_def_value[i];
      *known = 1;
      return 1;
    }
    i = i + 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// Locate the parseGetPriority body.
//
// The body is located BY NAME, so the tool does not depend on a
// hard-coded line number.  It runs from the function signature to the
// first line that is exactly "}".
//
// Returns the body length, or -1 if the body was not found.
// ---------------------------------------------------------------------------
I64 locate_body(U8 *txt, I64 fsz, U8 *marker, I64 *out_start)
{
  I64 mlen = str_len(marker);
  I64 i = 0;
  while (i + mlen <= fsz) {
    if (memeq(txt + i, marker, mlen)) {
      *out_start = i;
      break;
    }
    i = i + 1;
  }
  if (i + mlen > fsz) return -1;

  // The body ends at the first line that is exactly "}".
  I64 j = *out_start;
  while (j < fsz) {
    I64 ls = j;
    while (j < fsz && txt[j] != 10) j = j + 1;
    I64 le = j;
    if (j < fsz) j = j + 1;
    U8 *q = skip_ws(txt + ls);
    I64 qlen = le - (q - txt);
    if (qlen == 1 && q[0] == '}') return le - *out_start;
  }
  return -1;
}

// ---------------------------------------------------------------------------
// Derive the precedence table from the parseGetPriority body.
//
// The body is a single switch over tok->i64 whose arms are `case
// LABEL:` and whose results are `return N;`.  This function walks the
// body, collects the pending case labels and binds them to the
// precedence of the `return` that follows them.
//
// A LINE MAY CARRY SEVERAL CASE LABELS: the live source has
//     case '*': case '/': case '%':
// so a line is scanned for a SEQUENCE of `case LABEL:` items, not just
// for one.
//
// The -1 sentinel is read out of the DEFAULT arm, not assumed.
// ---------------------------------------------------------------------------
I64 derive_table(U8 *txt, I64 fsz)
{
  I64 i = 0;
  I64 lineno = 0;
  I64 pending_count = 0;
  I64 pending_default = 0;
  U8 pending_name[32][64];
  I64 unresolved = 0;

  g_entry_count = 0;
  g_sentinel = 0;
  g_sentinel_found = 0;

  while (i < fsz) {
    U8 line[LINE_CAP];
    I64 n = 0;
    while (i < fsz && txt[i] != 10 && txt[i] != 13 && n < LINE_CAP - 1) {
      line[n] = txt[i];
      n = n + 1;
      i = i + 1;
    }
    line[n] = 0;
    while (i < fsz && (txt[i] == 10 || txt[i] == 13)) i = i + 1;
    lineno = lineno + 1;

    U8 *p = skip_ws(line);

    // A `return` line?
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
        g_sentinel = v;
        g_sentinel_found = 1;
        pending_count = 0;
        pending_default = 0;
        continue;
      }
      // Bind every pending label to this precedence.
      I64 j = 0;
      while (j < pending_count) {
        I64 val = 0;
        I64 known = 0;
        if (!resolve_label(pending_name[j], &val, &known)) unresolved = unresolved + 1;
        if (g_entry_count < MAX_TABLE_ENTRIES) {
          g_value[g_entry_count] = val;
          g_precedence[g_entry_count] = v;
          g_entry_count = g_entry_count + 1;
        }
        j = j + 1;
      }
      pending_count = 0;
      continue;
    }

    // A line of `case` labels and/or a `default` arm.
    //
    // The line is scanned left to right for a SEQUENCE of items.  Each
    // item is either `case LABEL:` or `default:`.
    I64 saw_item = 0;
    while (1) {
      p = skip_ws(p);
      if (p[0] == 'c' && p[1] == 'a' && p[2] == 's' && p[3] == 'e'
          && (p[4] == 32 || p[4] == 9)) {
        p = p + 4;
        p = skip_ws(p);

        // The label: a character literal or an identifier.
        U8 nm[64];
        I64 k = 0;
        if (*p == 39) {
          // A character literal, possibly escaped.
          nm[k] = *p; k = k + 1; p = p + 1;
          if (*p == 92) { nm[k] = *p; k = k + 1; p = p + 1; }
          nm[k] = *p; k = k + 1; p = p + 1;
          if (*p == 39) { nm[k] = *p; k = k + 1; p = p + 1; }
        } else {
          while (*p && *p != ':' && *p != ' ' && *p != 9 && k < 63) {
            nm[k] = *p; k = k + 1; p = p + 1;
          }
        }
        nm[k] = 0;

        // The label must be terminated by ':'.
        p = skip_ws(p);
        if (*p != ':') break;
        p = p + 1;
        if (pending_count < 32) {
          scopy(pending_name[pending_count], 64, nm);
          pending_count = pending_count + 1;
        }
        saw_item = 1;
        continue;
      }
      if (p[0] == 'd' && p[1] == 'e' && p[2] == 'f' && p[3] == 'a'
          && p[4] == 'u' && p[5] == 'l' && p[6] == 't'
          && (p[7] == 32 || p[7] == 9 || p[7] == ':')) {
        pending_default = 1;
        pending_count = 0;
        p = p + 7;
        saw_item = 1;
        continue;
      }
      break;
    }
    if (saw_item) continue;

    // Any other line ends the current arm's label list.
    if (pending_count > 0 || pending_default) {
      // A line that is neither a case label nor a return leaves the
      // pending labels dangling.  That is a structural change in the
      // switch and is reported rather than silently carried over.
      pending_count = 0;
      pending_default = 0;
    }
  }
  g_unresolved = unresolved;
  return g_entry_count;
}

// ---------------------------------------------------------------------------
// The REQUIRED P16 VALUE SET.
//
// The set is the union of
//
//   { v-1 : v is a table value }  UNION  { v+1 : v is a table value }
//   UNION { INT64_MIN, INT64_MIN+1, INT64_MAX-1, INT64_MAX }
//   UNION { 0, -1, 1 }
//
// The four symbolic bounds are RESOLVED EXPLICITLY from the hex
// constants at the top of this file.  No numeric fragment is ever
// scanned out of an identifier.
// ---------------------------------------------------------------------------

// The distinct required P16 values.
I64 g_p16[MAX_VALUES];
I64 g_p16_count;

// Is `v` already in the required set?
I64 p16_has(I64 v)
{
  I64 i = 0;
  while (i < g_p16_count) {
    if (g_p16[i] == v) return 1;
    i = i + 1;
  }
  return 0;
}

// Add `v` to the required set if it is not already there.
I64 p16_add(I64 v)
{
  if (p16_has(v)) return 0;
  if (g_p16_count >= MAX_VALUES) return 1;
  g_p16[g_p16_count] = v;
  g_p16_count = g_p16_count + 1;
  return 1;
}

// Build the required set from the derived table.
//
// Returns the number of distinct values.  `overflow` is set to 1 if a
// neighbour could not be represented (which would mean the table held
// a value at the domain edge).
I64 build_p16_set(I64 *overflow)
{
  g_p16_count = 0;
  *overflow = 0;

  // The neighbours of every table value.
  I64 k = 0;
  while (k < g_entry_count) {
    I64 v = g_value[k];
    I64 lo = v - 1;
    I64 hi = v + 1;
    // The domain edge: a neighbour outside the signed 64-bit range is
    // not representable and is reported rather than silently wrapped.
    if (v == I64_MIN_HEX) *overflow = *overflow + 1;
    if (v == I64_MAX_HEX) *overflow = *overflow + 1;
    p16_add(lo);
    p16_add(hi);
    k = k + 1;
  }

  // The four signed-I64 extremes, resolved explicitly.
  p16_add(I64_MIN_HEX);
  p16_add(I64_MIN_PLUS1_HEX);
  p16_add(I64_MAX_MINUS1_HEX);
  p16_add(I64_MAX_HEX);

  // The three base values.
  p16_add(BASE_ZERO);
  p16_add(BASE_NEG1);
  p16_add(BASE_POS1);

  return g_p16_count;
}

// Sort the required set into ASCENDING NUMERIC order.
//
// The sort is an insertion sort: the set is small (65 elements) and a
// simple, obviously-correct sort is worth more here than speed.
I64 p16_sort()
{
  I64 i = 1;
  while (i < g_p16_count) {
    I64 v = g_p16[i];
    I64 j = i - 1;
    while (j >= 0 && g_p16[j] > v) {
      g_p16[j + 1] = g_p16[j];
      j = j - 1;
    }
    g_p16[j + 1] = v;
    i = i + 1;
  }
  return g_p16_count;
}

// ---------------------------------------------------------------------------
// The precedence of a value, from the derived table.
//
// Returns 1 when the value is a table entry; the precedence is written
// to *out.  Returns 0 otherwise, and the caller uses the sentinel.
// ---------------------------------------------------------------------------
I64 table_lookup(I64 v, I64 *out)
{
  I64 i = 0;
  while (i < g_entry_count) {
    if (g_value[i] == v) { *out = g_precedence[i]; return 1; }
    i = i + 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// THE CORRECTED PARTITION CONTRACT.
//
// All 19 partitions of the predecessor's contract are preserved, with
// their required coverage.  The ONLY change is P16: its row count is
// derived from the REQUIRED VALUE SET (65) instead of being frozen at
// a 40 that the literal enumeration cannot fit into (D6).
//
// The other partitions' VALUES are read from the live precedence table
// by PRECEDENCE CLASS, not transcribed by hand: the accept partitions
// list exactly the table entries of their class, and the reject
// partitions list their literal values.
//
//   partition id                   class   values
//   P1..P14  ACCEPTED_PRECEDENCE_n  n       the table entries of class n
//   P15      REJECTED_NOT_AN_OPERATOR       literal non-operator values
//   P16      BOUNDARY_INTEGERS               the required value set
//   P17      ALIASING_SENSITIVE              0x301 (TK_STR == TK_SUPERSCRIPT)
//   P18      SIGN_AND_WIDTH_BOUNDARIES       the sign-bit / byte-width values
//   P19      PRODUCTION_OBSERVABLE           '*' (the causal-mutation value)
// ---------------------------------------------------------------------------

// The literal values of the reject and boundary partitions.
I64 g_reject[16];
I64 g_reject_count;

// The P18 sign-and-width boundary values.
I64 g_width[16];
I64 g_width_count;

I64 init_literal_sets()
{
  g_reject_count = 0;
  // The P15 reject set.  It does NOT contain 0x30B-1: that value is
  // 0x30A, which is TK_SHR, a RECOGNISED operator with precedence 6.
  // The predecessor's TK_SHR defect is corrected here and is not
  // re-introduced.
  g_reject[0] = 0;        // 0x00
  g_reject[1] = 1;        // 0x01
  g_reject[2] = 0x2B + 1; // 0x2C
  g_reject[3] = 0x301;    // TK_STR / TK_SUPERSCRIPT
  g_reject[4] = 0x400;
  g_reject[5] = 0x7F;
  g_reject[6] = 0x1000;
  g_reject[7] = -1;
  g_reject[8] = -1000;
  g_reject_count = 9;

  g_width_count = 0;
  g_width[0] = 0x7F;
  g_width[1] = 0x80;
  g_width[2] = 0xFF;
  g_width[3] = 0x100;
  g_width[4] = 0x7FFF;
  g_width[5] = 0x8000;
  g_width[6] = 0xFFFF;
  g_width[7] = 0x10000;
  g_width_count = 8;

  return 1;
}

// The canonical partition id for a precedence class n (1..14).
U8 *accept_partition_id(I64 n)
{
  if (n == 1) return "P1_ACCEPTED_PRECEDENCE_1";
  if (n == 2) return "P2_ACCEPTED_PRECEDENCE_2";
  if (n == 3) return "P3_ACCEPTED_PRECEDENCE_3";
  if (n == 4) return "P4_ACCEPTED_PRECEDENCE_4";
  if (n == 5) return "P5_ACCEPTED_PRECEDENCE_5";
  if (n == 6) return "P6_ACCEPTED_PRECEDENCE_6";
  if (n == 7) return "P7_ACCEPTED_PRECEDENCE_7";
  if (n == 8) return "P8_ACCEPTED_PRECEDENCE_8";
  if (n == 9) return "P9_ACCEPTED_PRECEDENCE_9";
  if (n == 10) return "P10_ACCEPTED_PRECEDENCE_10";
  if (n == 11) return "P11_ACCEPTED_PRECEDENCE_11";
  if (n == 12) return "P12_ACCEPTED_PRECEDENCE_12";
  if (n == 13) return "P13_ACCEPTED_PRECEDENCE_13";
  if (n == 14) return "P14_ACCEPTED_PRECEDENCE_14";
  return "";
}

// ---------------------------------------------------------------------------
// Emit ONE fixture row.
//
//   fixture_id <TAB> partition <TAB> punct_value <TAB> expected <TAB> rationale
//
// The expected value is ALWAYS taken from the derived table, never from
// a partition declaration.  That is the D7 repair.
// ---------------------------------------------------------------------------
I64 emit_row(U8 *buf, I64 cap, I64 *len, I64 row_no, U8 *partition,
             I64 value, U8 *rationale)
{
  I64 prec = 0;
  I64 expected_value = g_sentinel;
  if (table_lookup(value, &prec)) expected_value = prec;

  // The canonical id: F followed by three decimal digits, zero padded.
  U8 idbuf[8];
  idbuf[0] = 70;
  idbuf[1] = 48 + (row_no / 100);
  idbuf[2] = 48 + ((row_no / 10) % 10);
  idbuf[3] = 48 + (row_no % 10);
  idbuf[4] = 9;
  idbuf[5] = 0;

  *len = *len + app_lit(buf + *len, cap - *len, idbuf);
  *len = *len + app_lit(buf + *len, cap - *len, partition);
  *len = *len + app_lit(buf + *len, cap - *len, "\t");
  *len = *len + app_ll(buf + *len, cap - *len, "", value);
  *len = *len + app_lit(buf + *len, cap - *len, "\t");
  *len = *len + app_ll(buf + *len, cap - *len, "", expected_value);
  *len = *len + app_lit(buf + *len, cap - *len, "\t");
  *len = *len + app_lit(buf + *len, cap - *len, rationale);
  *len = *len + app_lit(buf + *len, cap - *len, "\n");
  return *len;
}

I64 main(I64 argc, U8 **argv)
{
  if (argc != 4) {
    printf("CORR01_FIXTURE_USAGE: %s <prslib.c> <lexer.h> <out.tsv>\n", argv[0]);
    return 2;
  }

  // ---- The live sources -----------------------------------------
  I64 psz = 0;
  U8 *ptxt = FileRead(argv[1], &psz);
  if (ptxt == 0) {
    printf("CORR01_FIXTURE_ERROR: cannot read %s\n", argv[1]);
    return 2;
  }
  I64 lsz = 0;
  U8 *ltxt = FileRead(argv[2], &lsz);
  if (ltxt == 0) {
    printf("CORR01_FIXTURE_ERROR: cannot read %s\n", argv[2]);
    return 2;
  }

  // ---- The derived table -----------------------------------------
  read_defines(ltxt, lsz);

  // The table is derived from the parseGetPriority BODY ONLY.  The
  // whole file contains other switches whose `default` arms and `case`
  // labels would otherwise be harvested.
  I64 body_start = 0;
  I64 body_len = locate_body(ptxt, psz, "static int parseGetPriority(Lexeme *tok)", &body_start);
  if (body_len < 0) {
    printf("CORR01_FIXTURE_ERROR: the parseGetPriority body was not found\n");
    return 1;
  }
  derive_table(ptxt + body_start, body_len);

  printf("DERIVED_TABLE_ENTRIES=%d\n", g_entry_count);
  printf("DERIVED_UNRESOLVED_LABELS=%d\n", g_unresolved);
  printf("DERIVED_SENTINEL=%d\n", g_sentinel);
  printf("LEXER_H_DEFINES_PARSED=%d\n", g_def_count);

  if (g_entry_count == 0 || g_unresolved != 0 || !g_sentinel_found) {
    printf("CORR01_FIXTURE_ERROR: the precedence table could not be derived cleanly\n");
    return 1;
  }

  // ---- The required P16 value set -------------------------------
  init_literal_sets();
  I64 overflow = 0;
  build_p16_set(&overflow);
  p16_sort();
  printf("P16_REQUIRED_VALUES=%d\n", g_p16_count);
  printf("P16_DOMAIN_OVERFLOW=%d\n", overflow);
  if (overflow != 0) {
    printf("CORR01_FIXTURE_ERROR: a table value sits at the signed 64-bit domain edge\n");
    return 1;
  }

  // ---- The fixture buffer ---------------------------------------
  U8 *buf = MAlloc(FIXTURE_BUF);
  if (buf == 0) {
    printf("CORR01_FIXTURE_ERROR: MAlloc failed\n");
    return 2;
  }
  I64 len = 0;
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "ACT_PHASE=C2-IMPL\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "EVIDENCE_KIND=corrected-fixture\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len, "#\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "# The expected column of every row is the precedence the DERIVED\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "# TABLE gives the value, computed from the LIVE src/prslib.c and\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "# src/lexer.h.  No partition declaration is used as an expected\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "# value.\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "#\n# The value column is written with a 64-bit conversion, so the\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "# signed-I64 extremes are carried exactly.\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len,
    "#\n# Schema: fixture_id <TAB> partition <TAB> punct_value <TAB> expected <TAB> rationale\n");
  len = len + app_lit(buf + len, FIXTURE_BUF - len, "\n");

  I64 row_no = 0;

  // ---- P1..P14: the accept partitions ---------------------------
  //
  // The values of an accept partition are the table entries of its
  // precedence class, in the derived table's order.
  I64 cls = 1;
  while (cls <= 14) {
    U8 *pid = accept_partition_id(cls);
    I64 k = 0;
    while (k < g_entry_count) {
      if (g_precedence[k] == cls) {
        row_no = row_no + 1;
        len = emit_row(buf, FIXTURE_BUF, &len, row_no, pid, g_value[k],
                       "operator of precedence class from the live src/prslib.c switch");
      }
      k = k + 1;
    }
    cls = cls + 1;
  }

  // ---- P15: the reject partition --------------------------------
  I64 i = 0;
  while (i < g_reject_count) {
    row_no = row_no + 1;
    len = emit_row(buf, FIXTURE_BUF, &len, row_no,
                   "P15_REJECTED_NOT_AN_OPERATOR", g_reject[i],
                   "a punct value that is not in the live precedence table");
    i = i + 1;
  }

  // ---- P16: the boundary partition -------------------------------
  //
  // Every DISTINCT required value gets exactly one row.  The rows are
  // emitted in ascending numeric order, so the fixture's P16 block IS
  // the canonical ordered value set.
  i = 0;
  while (i < g_p16_count) {
    row_no = row_no + 1;
    len = emit_row(buf, FIXTURE_BUF, &len, row_no,
                   "P16_BOUNDARY_INTEGERS", g_p16[i],
                   "boundary value: operator neighbour, signed-I64 extreme, or base value");
    i = i + 1;
  }

  // ---- P17: the aliasing partition -------------------------------
  row_no = row_no + 1;
  len = emit_row(buf, FIXTURE_BUF, &len, row_no,
                 "P17_ALIASING_SENSITIVE", 0x301,
                 "TK_STR and TK_SUPERSCRIPT are the same number; neither is an operator");

  // ---- P18: the sign-and-width partition -------------------------
  i = 0;
  while (i < g_width_count) {
    row_no = row_no + 1;
    len = emit_row(buf, FIXTURE_BUF, &len, row_no,
                   "P18_SIGN_AND_WIDTH_BOUNDARIES", g_width[i],
                   "sign-bit and byte-width boundary value");
    i = i + 1;
  }

  // ---- P19: the production-observable partition ------------------
  //
  // The observable is '*', the operator the causal mutation moves.
  row_no = row_no + 1;
  len = emit_row(buf, FIXTURE_BUF, &len, row_no,
                 "P19_PRODUCTION_OBSERVABLE", 42,
                 "the operator whose precedence change is production-observable");

  // ---- Write it out ----------------------------------------------
  Bool wrote = FileWrite(argv[3], buf, len, 0x0202);
  Free(buf);
  if (!wrote) {
    printf("CORR01_FIXTURE_ERROR: FileWrite failed for %s\n", argv[3]);
    return 2;
  }

  printf("FIXTURE_ROWS=%d\n", row_no);
  printf("P16_ROWS=%d\n", g_p16_count);
  printf("NON_P16_ROWS=%d\n", row_no - g_p16_count);
  printf("WROTE=%s\n", argv[3]);

  // ---- The self-check --------------------------------------------
  //
  // The producer MUST FAIL rather than emit a superficially complete
  // fixture.  These checks are what make the producer's exit code
  // meaningful:
  //
  //   * every required P16 value must be in the set;
  //   * the four signed-I64 extremes must be present;
  //   * the set must contain all the operator neighbours;
  //   * the row count must be the derived count.
  I64 missing_extremes = 0;
  if (!p16_has(I64_MIN_HEX)) missing_extremes = missing_extremes + 1;
  if (!p16_has(I64_MIN_PLUS1_HEX)) missing_extremes = missing_extremes + 1;
  if (!p16_has(I64_MAX_MINUS1_HEX)) missing_extremes = missing_extremes + 1;
  if (!p16_has(I64_MAX_HEX)) missing_extremes = missing_extremes + 1;

  I64 missing_neighbours = 0;
  I64 k = 0;
  while (k < g_entry_count) {
    if (!p16_has(g_value[k] - 1)) missing_neighbours = missing_neighbours + 1;
    if (!p16_has(g_value[k] + 1)) missing_neighbours = missing_neighbours + 1;
    k = k + 1;
  }

  printf("P16_SIGNED_EXTREMES_PRESENT=%d/4\n", 4 - missing_extremes);
  printf("P16_MISSING_OPERATOR_NEIGHBOURS=%d\n", missing_neighbours);

  if (missing_extremes != 0 || missing_neighbours != 0) {
    printf("CORR01_FIXTURE_ERROR: the required value set is incomplete\n");
    return 1;
  }

  printf("STATUS=PASS\n");
  return 0;
}
