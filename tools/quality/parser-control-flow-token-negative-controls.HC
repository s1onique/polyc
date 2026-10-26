// tools/quality/parser-control-flow-token-negative-controls.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01 C1 IMPL.
//
// PolyC-native NEGATIVE-CONTROL DRIVER for the direct differential
// tools/quality/parser-control-flow-token-differential.HC.
//
// WHY THIS TOOL EXISTS
//
// The predecessor ACT (ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01)
// froze a negative-control contract in C1 that included NC-D12:
//
//     NC-D12  a fixture id that is not F### (e.g. X001)
//             FAIL  FIXTURE_ID_UNKNOWN
//
// but the C3 negative-control evidence never executed it. NC-D12 was
// the control that would have exposed the row-reader bypass: the
// predecessor skipped every row that did not start with 'F' followed by
// a digit, BEFORE the unknown-ID ledger ran, so an unknown id such as
// "X001" was invisible and a 42-row fixture plus that row returned
// STATUS=PASS.
//
// This driver EXECUTES every control against the REAL differential
// binary. It does not simulate the differential's decision; it runs
// the real program and reads its real exit status and its real
// REASON token.
//
// A control PASSES when the real differential produced the specified
// exit status AND the specified REASON token. The driver itself is
// NOT the subject: if the driver says PASS, the real differential
// emitted that token.
//
// DESIGN
//
// The fixture is held as ONE byte buffer. A mutation is a byte-range
// splice: the buffer is copied up to a start offset, the replacement
// text is emitted, the copy resumes after an end offset. This avoids
// a per-line object model entirely.
//
// An earlier version of this tool modelled the fixture as a vector of
// separately allocated lines. That was measured to corrupt the F041
// row (its 593-character rationale) under the row-removal and
// row-duplication controls. The byte-splice design has no
// per-line allocation, so that class of defect cannot arise.
//
// USAGE:
//   build/parser-control-flow-token-negative-controls \
//       <differential-binary> <canonical-fixture.tsv> [workdir]
//
// EXIT STATUS: 0 if every control behaves as specified, 1 otherwise.

// NOTE ON FILE-SCOPE INITIALISERS (measured, not assumed).
//
// A file-scope variable WITH an initialiser (for example
// "I64 g_nlines = 0;") puts the compiler into the
// CCTRL_ASM_HAS_INITIALISERS path (src/asm.c, asmBuildInitialiserMain):
// the user's `Main` is renamed to `MainFn` and a SYNTHETIC `_main`
// driver becomes the process entry point. That synthetic driver calls
// `Main` with NO arguments, so `argc` arrives as 0 and `argv` as
// NULL.
//
// This tool NEEDS its command-line arguments (the differential binary
// and the canonical fixture), so it MUST NOT declare any file-scope
// initialiser. Every global below is therefore declared WITHOUT an
// initialiser and is set explicitly in `Main`.
//
// The same rule is why the entry point uses the "I32 Main(I32, U8**)"
// signature that the other PolyC quality tools in this repository use
// (tools/quality/lexer07-broad-corpus-4-stage.HC,
// tools/quality/lexer07-baseline-authority-verify.HC): with no
// file-scope initialiser, `Main` is lowercased to `main` and becomes
// the process entry point directly.
//
// The "I64 main(I64, U8**)" signature was measured to make the current
// PolyC compiler emit _main TWICE in a translation unit of this size:
// the assembler rejects the result with "symbol '_main' is already
// defined". The same source with the I32 Main signature compiles and
// links cleanly.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 printf(U8 *fmt, ...);
extern "c" I64 system(U8 *cmd);
extern "c" I64 strcmp(U8 *a, U8 *b);
extern "c" I32 unlink(U8 *pathname);

// The canonical fixture has 42 data rows.
#define CANONICAL_ROWS 42

// ---------------------------------------------------------------------
// The fixture buffer and the edit state
// ---------------------------------------------------------------------

U8 *g_src;          // the original fixture bytes
I64 g_src_len;      // their length
U8 *g_out;          // the mutated fixture bytes
I64 g_out_len;      // their length

U8 *g_diff_bin;
U8 *g_workdir;
U8 *g_reason;
I64 g_failures;
I64 g_controls;

// ---------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------

U0 CopyStr(U8 *dst, U8 *src)
{
  I64 i = 0;
  while (src[i] != 0) {
    dst[i] = src[i];
    i = i + 1;
  }
  dst[i] = 0;
}

U0 AppendStr(U8 *dst, I64 *len, U8 *src)
{
  I64 i = 0;
  while (src[i] != 0) {
    dst[*len] = src[i];
    *len = *len + 1;
    i = i + 1;
  }
  dst[*len] = 0;
}

// Append `n` bytes from `src`.
U0 AppendBytes(U8 *dst, I64 *len, U8 *src, I64 n)
{
  I64 i = 0;
  while (i < n) {
    dst[*len] = src[i];
    *len = *len + 1;
    i = i + 1;
  }
  dst[*len] = 0;
}


// ---------------------------------------------------------------------
// Locating a line
//
// A line is identified by its byte range [start, end) in the ORIGINAL
// fixture buffer, where end is the offset of the line's terminator.
// ---------------------------------------------------------------------

// The start offset of the n-th (0-based) DATA row, or -1.
//
// A data row is a line that is not blank, does not begin with '#',
// does not begin with whitespace, and whose first field contains no
// '='. These are exactly the rows the differential treats as data rows.
I64 DataRowStart(I64 n)
{
  I64 seen = 0;
  I64 i = 0;
  while (i < g_src_len) {
    I64 start = i;
    while (i < g_src_len && g_src[i] != '\n' && g_src[i] != '\r') i = i + 1;
    I64 end = i;

    // classify
    I64 is_data = 1;
    I64 len = end - start;
    if (len == 0) is_data = 0;
    else {
      U8 c = g_src[start];
      if (c == '#') is_data = 0;
      else if (c == ' ' || c == '\t') is_data = 0;
      else {
        I64 k = start;
        while (k < end && g_src[k] != '\t') {
          if (g_src[k] == '=') { is_data = 0; break; }
          k = k + 1;
        }
      }
    }

    if (is_data) {
      if (seen == n) return start;
      seen = seen + 1;
    }

    // advance past exactly one terminator
    if (i < g_src_len && g_src[i] == '\r') i = i + 1;
    if (i < g_src_len && g_src[i] == '\n') i = i + 1;
  }
  return -1;
}

// The end offset (exclusive, not including the terminator) of the line
// that starts at `start`.
I64 LineEnd(I64 start)
{
  I64 i = start;
  while (i < g_src_len && g_src[i] != '\n' && g_src[i] != '\r') i = i + 1;
  return i;
}

// The offset just past the line terminator that follows the line
// starting at `start`.
I64 LineAfter(I64 start)
{
  I64 i = LineEnd(start);
  if (i < g_src_len && g_src[i] == '\r') i = i + 1;
  if (i < g_src_len && g_src[i] == '\n') i = i + 1;
  return i;
}

// ---------------------------------------------------------------------
// Edits
//
// The mutation is described by two byte ranges of the ORIGINAL buffer
// and one replacement string:
//
//   keep [0, cut_a)        -- the prefix
//   <replacement>          -- the new text
//   keep [cut_b, end)      -- the suffix
//
// A line removal is a replacement of "" over [line_start, line_after).
// A line replacement is a replacement of the new text over
// [line_start, line_end).
// A line insertion is a replacement of the new text over the empty
// range [at, at).
// ---------------------------------------------------------------------

U8 *g_repl;
I64 g_repl_len;
I64 g_cut_a;
I64 g_cut_b;

// Build the mutated buffer from the current edit description.
U0 BuildOutput()
{
  I64 keep1 = g_cut_a;
  I64 keep2 = g_src_len - g_cut_b;
  I64 total = keep1 + g_repl_len + keep2;
  Free(g_out);
  g_out = MAlloc(total + 1);
  g_out_len = 0;
  AppendBytes(g_out, &g_out_len, g_src, keep1);
  AppendBytes(g_out, &g_out_len, g_repl, g_repl_len);
  AppendBytes(g_out, &g_out_len, g_src + g_cut_b, keep2);
  g_out[g_out_len] = 0;
}

// Set the edit to "remove the line that starts at `line_start`".
U0 EditRemoveLine(I64 line_start)
{
  g_cut_a = line_start;
  g_cut_b = LineAfter(line_start);
  g_repl_len = 0;
  Free(g_repl);
  g_repl = MAlloc(1);
  g_repl[0] = 0;
  BuildOutput();
}

// Set the edit to "replace the line that starts at `line_start` with
// `text`".
U0 EditReplaceLine(I64 line_start, U8 *text)
{
  g_cut_a = line_start;
  g_cut_b = LineEnd(line_start);
  g_repl_len = StrLen(text);
  Free(g_repl);
  g_repl = MAlloc(g_repl_len + 1);
  CopyStr(g_repl, text);
  BuildOutput();
}

// Set the edit to "insert `text` as a new line before the line that
// starts at `line_start`".
U0 EditInsertLine(I64 line_start, U8 *text)
{
  g_cut_a = line_start;
  g_cut_b = line_start;
  I64 tl = StrLen(text);
  g_repl_len = tl + 1;
  Free(g_repl);
  g_repl = MAlloc(g_repl_len + 1);
  CopyStr(g_repl, text);
  g_repl[tl] = '\n';
  g_repl[tl + 1] = 0;
  BuildOutput();
}

// Set the edit to "append `text` as a new line at the end of the file".
//
// ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02: the
// appended row MUST be SEPARATE from the last existing row. The
// previous form appended at g_src_len without a separating newline,
// so on a source whose last line is not newline-terminated the
// appended text JOINED that line, producing a single merged row.
//
// The separator is emitted only when the source does not already end
// with a newline, so a well-formed source is byte-identical to what
// the previous form produced.
U0 EditAppendLine(U8 *text)
{
  g_cut_a = g_src_len;
  g_cut_b = g_src_len;
  I64 tl = StrLen(text);

  // Does the source already end with a newline?
  I64 need_sep = 1;
  if (g_src_len > 0 && g_src[g_src_len - 1] == '\n') need_sep = 0;

  I64 sep = 0;
  if (need_sep) sep = 1;

  g_repl_len = tl + sep + 1;
  Free(g_repl);
  g_repl = MAlloc(g_repl_len + 1);
  // The SEPARATOR terminates the PREVIOUS, unterminated line, so it
  // comes FIRST, before the appended row's text. The appended row's
  // own terminator comes last.
  if (need_sep) g_repl[0] = '\n';
  CopyStr(g_repl + sep, text);
  g_repl[sep + tl] = '\n';
  g_repl[sep + tl + 1] = 0;
  BuildOutput();
}

// Set the edit to "keep the whole file unchanged".
U0 EditNone()
{
  g_cut_a = 0;
  g_cut_b = 0;
  g_repl_len = 0;
  Free(g_repl);
  g_repl = MAlloc(1);
  g_repl[0] = 0;
  BuildOutput();
}

// ---------------------------------------------------------------------
// The runner
// ---------------------------------------------------------------------

// Run the real differential on the current mutated fixture, capturing
// its stdout.
//
// The exit status is the RAW wait status returned by system(3), which
// encodes the child's exit code in the high byte (code == status >> 8).
// The child's exit code is what the differential's contract is
// expressed in, so the raw status is decoded here.
I64 RunDifferential(U8 *outpath)
{
  U8 fixture[1024];
  U8 cmd[1024 + 1024 + 256];
  I64 at = 0;
  CopyStr(fixture, g_workdir);
  at = StrLen(fixture);
  AppendStr(fixture, &at, "/fixture.tsv");

  // The captured output is removed first, for the same reason: the
  // differential's FileWrite does not truncate.
  unlink(outpath);

  at = 0;
  CopyStr(cmd, "\"");
  at = StrLen(cmd);
  AppendStr(cmd, &at, g_diff_bin);
  AppendStr(cmd, &at, "\" \"");
  AppendStr(cmd, &at, fixture);
  AppendStr(cmd, &at, "\" > \"");
  AppendStr(cmd, &at, outpath);
  AppendStr(cmd, &at, "\" 2>&1");
  I64 raw = system(cmd);
  return (raw >> 8) & 0xFF;
}

// Extract the value of REASON=<token> from the captured output.
U0 ExtractReason(U8 *outpath)
{
  I64 sz = 0;
  U8 *buf = FileRead(outpath, &sz);
  if (buf == NULL) {
    Free(g_reason);
    g_reason = MAlloc(16);
    CopyStr(g_reason, "<no-output>");
    return;
  }
  Free(g_reason);
  g_reason = MAlloc(128);
  CopyStr(g_reason, "<none>");
  // The prefix is matched POSITIONALLY against the literal characters
  // rather than against a copied key buffer: the copied-buffer form was
  // measured to compare only five of the six prefix characters in this
  // translation unit, which produced a token with a leading '='.
  I64 i = 0;
  while (i < sz) {
    I64 start = i;
    while (i < sz && buf[i] != '\n') i = i + 1;
    I64 len = i - start;
    // "REASON=" is seven characters.
    if (len > 7
        && buf[start + 0] == 'R'
        && buf[start + 1] == 'E'
        && buf[start + 2] == 'A'
        && buf[start + 3] == 'S'
        && buf[start + 4] == 'O'
        && buf[start + 5] == 'N'
        && buf[start + 6] == '=') {
      I64 vlen = len - 7;
      U8 *v = MAlloc(vlen + 1);
      I64 m = 0;
      while (m < vlen) {
        v[m] = buf[start + 7 + m];
        m = m + 1;
      }
      v[vlen] = 0;
      Free(g_reason);
      g_reason = v;
    }
    while (i < sz && (buf[i] == '\n' || buf[i] == '\r')) i = i + 1;
  }
  Free(buf);
}

// Run one control and assert its expected exit status and reason.
//
// `expect_status` is the differential's expected exit code
// (0 = PASS, 1 = FAIL).
// `expect_reason` is the expected REASON token, or NULL when the
// control is expected to PASS (no reason token is emitted).
U0 CheckControl(U8 *id, I64 expect_status, U8 *expect_reason)
{
  g_controls = g_controls + 1;

  U8 fixture[1024];
  U8 outpath[1024];
  I64 at = 0;
  CopyStr(fixture, g_workdir);
  at = StrLen(fixture);
  AppendStr(fixture, &at, "/fixture.tsv");
  at = 0;
  CopyStr(outpath, g_workdir);
  at = StrLen(outpath);
  AppendStr(outpath, &at, "/out.txt");

  // The fixture file is REMOVED before it is written.
  //
  // FileWrite opens with O_CREAT|O_RDWR and does NOT truncate
  // (src/holyc-lib/io.HC; io_defs.HH defines no O_TRUNC), so writing a
  // shorter buffer over an existing, longer file leaves the previous
  // file's trailing bytes in place. That was measured to leave stale
  // F001..F029 rows at the end of the fixture and to make the
  // differential report FIXTURE_SCHEMA_INVALID for the UNMODIFIED
  // canonical fixture.
  unlink(fixture);
  FileWrite(fixture, g_out, g_out_len, 0x0202);

  // The fixture of every control is ALSO kept under a control-specific
  // name, so that a failing control can be inspected byte for byte.
  {
    U8 keep[1024];
    I64 k = 0;
    CopyStr(keep, g_workdir);
    k = StrLen(keep);
    AppendStr(keep, &k, "/fixture-");
    AppendStr(keep, &k, id);
    AppendStr(keep, &k, ".tsv");
    unlink(keep);
    FileWrite(keep, g_out, g_out_len, 0x0202);
  }

  I64 rc = RunDifferential(outpath);
  ExtractReason(outpath);

  I64 ok = 1;
  if (rc != expect_status) ok = 0;
  if (expect_reason != NULL) {
    if (strcmp(g_reason, expect_reason) != 0) ok = 0;
  } else {
    if (rc != 0) ok = 0;
  }

  if (ok) {
    printf("NC %s: OK (rc=%d reason=%s)\n", id, rc, g_reason);
  } else {
    printf("NC %s: BROKEN (expected rc=%d reason=%s; observed rc=%d reason=%s)\n",
           id, expect_status, expect_reason, rc, g_reason);
    g_failures = g_failures + 1;
  }
}


// ---------------------------------------------------------------------
// The controls
// ---------------------------------------------------------------------

// A data row that is well formed but carries an unknown fixture id.
#define ROW_X001 "X001\tUNKNOWN\t1\t1\t1\t1\tnc-d12\tnc-d12"
#define ROW_Z999 "Z999\tUNKNOWN\t1\t1\t1\t1\tnc-d13\tnc-d13"
#define ROW_F043 "F043\tUNKNOWN\t1\t1\t1\t1\tnc-d4\tnc-d4"
#define ROW_F01  "F01\tUNKNOWN\t1\t1\t1\t1\tnc-d15\tnc-d15"

// ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02.
//
// An unknown fixture id that is INDENTED. The predecessor's row
// recognizer accepted ANY indented line as a metadata continuation,
// without requiring that a metadata block was in scope, so these rows
// were invisible to the unknown-ID ledger and the differential returned
// STATUS=PASS.
//
// The SPACE-indented form has the canonical 8 fields, so it is an
// unknown-ID failure. The TAB-indented form carries a leading TAB,
// which makes its first field empty and yields 9 fields, so it is a
// SCHEMA failure. Both are rejections; the token follows the row's
// own schema.
#define ROW_IND_SPACE "  X001\tUNKNOWN\t1\t1\t1\t1\tnc-d18\tnc-d18"
#define ROW_IND_TAB   "\tX001\tUNKNOWN\t1\t1\t1\t1\tnc-d19\tnc-d19"

// The same unknown id, indented, but with the canonical field count
// (the leading TAB is the indent, so the row carries 7 real fields).
#define ROW_IND_TAB7  "\tX001\tUNKNOWN\t1\t1\t1\t1\tnc-d20"

I32 Main(I32 argc, U8 **argv)
{
  // The file-scope globals carry no initialiser (see the note at the
  // top of this file), so they are set explicitly here.
  g_failures = 0;
  g_controls = 0;
  g_reason = NULL;
  g_repl = NULL;
  g_out = NULL;
  g_out_len = 0;
  g_repl_len = 0;
  g_cut_a = 0;
  g_cut_b = 0;

  if (argc < 3) {
    printf("USAGE: %s <differential-binary> <canonical-fixture.tsv> [workdir]\n", argv[0]);
    return 2;
  }
  g_diff_bin = argv[1];
  if (argc >= 4) g_workdir = argv[3];
  else g_workdir = "/tmp";

  g_src = FileRead(argv[2], &g_src_len);
  if (g_src == NULL) {
    printf("ERROR: cannot read fixture %s\n", argv[2]);
    return 2;
  }
  printf("FIXTURE_BYTES=%d\n", g_src_len);

  // The number of data rows must be exactly 42.
  I64 base_rows = 0;
  I64 probe = 0;
  while (1) {
    I64 s = DataRowStart(base_rows);
    if (s < 0) break;
    base_rows = base_rows + 1;
    probe = s;
  }
  printf("CANONICAL_DATA_ROWS=%d\n", base_rows);
  if (base_rows != CANONICAL_ROWS) {
    printf("ERROR: the canonical fixture must hold exactly %d data rows, found %d\n",
           CANONICAL_ROWS, base_rows);
    return 2;
  }

  // ---- CONTROL: the canonical fixture must PASS -------------------
  EditNone();
  CheckControl("NC-D0-canonical", 0, NULL);

  // ---- NC-D8: a valid fixture in SHUFFLED order must PASS ---------
  //
  // The data rows are emitted in REVERSE order. The comment and
  // metadata rows keep their original relative order, which does not
  // matter: the fixture contract is order independent.
  //
  // The shuffled fixture is built into a separate buffer; the
  // ORIGINAL fixture buffer is NOT modified, so every later control
  // still starts from the pristine canonical fixture.
  {
    I64 n = base_rows;
    I64 *starts = MAlloc(n * 8);
    I64 *ends = MAlloc(n * 8);
    I64 i = 0;
    while (i < n) {
      starts[i] = DataRowStart(i);
      ends[i] = LineEnd(starts[i]);
      i = i + 1;
    }

    // The output buffer holds every line of the original file, but the
    // DATA lines are taken from the reversed data-row list.
    I64 total = g_src_len;
    U8 *buf = MAlloc(total + 1);
    I64 at = 0;

    // Walk the original file line by line. Each NON-data line is
    // copied verbatim. Each DATA line is replaced by the next data row
    // taken from the reversed list.
    I64 pos = 0;
    I64 next = n - 1;
    while (pos < g_src_len) {
      I64 start = pos;
      while (pos < g_src_len && g_src[pos] != '\n' && g_src[pos] != '\r') pos = pos + 1;
      I64 end = pos;
      // advance past the terminator
      I64 after = pos;
      if (after < g_src_len && g_src[after] == '\r') after = after + 1;
      if (after < g_src_len && g_src[after] == '\n') after = after + 1;

      I64 is_data = 0;
      I64 len = end - start;
      if (len > 0) {
        U8 c = g_src[start];
        if (c != '#' && c != ' ' && c != '\t') {
          I64 k = start;
          while (k < end && g_src[k] != '\t') {
            if (g_src[k] == '=') { is_data = 0; break; }
            k = k + 1;
          }
          if (k >= end || g_src[k] == '\t') is_data = 1;
        }
      }

      if (is_data) {
        // Emit the reversed data row, INCLUDING its terminator. The
        // terminator is taken from the ORIGINAL data line's position,
        // so the emitted line count and the line structure are
        // preserved exactly.
        AppendBytes(buf, &at, g_src + starts[next], ends[next] - starts[next]);
        AppendBytes(buf, &at, g_src + end, after - end);
        next = next - 1;
      } else {
        AppendBytes(buf, &at, g_src + start, after - start);
      }
      pos = after;
    }
    buf[at] = 0;

    Free(g_out);
    g_out = buf;
    g_out_len = at;
    Free(starts);
    Free(ends);
    CheckControl("NC-D8-shuffled", 0, NULL);

    // restore the pristine output for the following controls
    EditNone();
  }

  // ---- NC-D1: remove the F041 row --------------------------------
  {
    I64 s = DataRowStart(40);           // F041
    if (s < 0) { printf("ERROR: F041 not found\n"); return 2; }
    EditRemoveLine(s);
    CheckControl("NC-D1-remove-F041", 1, "FIXTURE_ID_SET_INCOMPLETE");
  }

  // ---- NC-D2: remove the F007 row --------------------------------
  {
    I64 s = DataRowStart(6);            // F007
    if (s < 0) { printf("ERROR: F007 not found\n"); return 2; }
    EditRemoveLine(s);
    CheckControl("NC-D2-remove-F007", 1, "FIXTURE_ID_SET_INCOMPLETE");
  }

  // ---- NC-D3: duplicate F041 while omitting F042 ------------------
  //
  // The F042 row is replaced by a copy of the F041 row.
  {
    I64 s42 = DataRowStart(41);         // F042
    I64 s41 = DataRowStart(40);         // F041
    if (s42 < 0 || s41 < 0) { printf("ERROR: F041/F042 not found\n"); return 2; }
    I64 blen = LineEnd(s41) - s41;
    U8 *copy = MAlloc(blen + 1);
    I64 k = 0;
    while (k < blen) { copy[k] = g_src[s41 + k]; k = k + 1; }
    copy[blen] = 0;
    EditReplaceLine(s42, copy);
    CheckControl("NC-D3-duplicate-F041-omit-F042", 1, "FIXTURE_ID_SET_INCOMPLETE");
    Free(copy);
  }

  // ---- NC-D4: replace F041 with the unknown id F043 ---------------
  {
    I64 s = DataRowStart(40);           // F041
    if (s < 0) { printf("ERROR: F041 not found\n"); return 2; }
    EditReplaceLine(s, ROW_F043);
    CheckControl("NC-D4-F041-to-F043", 1, "FIXTURE_ID_UNKNOWN");
  }


  // ---- NC-D5: an empty fixture file -------------------------------
  {
    g_cut_a = 0;
    g_cut_b = g_src_len;
    g_repl_len = 0;
    Free(g_repl);
    g_repl = MAlloc(1);
    g_repl[0] = 0;
    BuildOutput();
    CheckControl("NC-D5-empty", 1, "FIXTURE_SET_EMPTY");
  }

  // ---- NC-D6b: an integer field with trailing garbage -------------
  //
  // The 'present' field of the F001 row is replaced with "1abc".
  {
    I64 s = DataRowStart(0);            // F001
    if (s < 0) { printf("ERROR: F001 not found\n"); return 2; }
    I64 e = LineEnd(s);
    // find the offset of the third field's start (two TABs)
    I64 tabs = 0;
    I64 k = s;
    while (k < e && tabs < 2) {
      if (g_src[k] == '\t') tabs = tabs + 1;
      k = k + 1;
    }
    // k is now just past the second TAB: the start of the third field
    I64 fstart = k;
    I64 fend = fstart;
    while (fend < e && g_src[fend] != '\t') fend = fend + 1;
    // rebuild: prefix, "1abc", suffix
    I64 total = g_src_len - (fend - fstart) + 4;
    U8 *buf = MAlloc(total + 1);
    I64 at = 0;
    AppendBytes(buf, &at, g_src, fstart);
    AppendStr(buf, &at, "1abc");
    AppendBytes(buf, &at, g_src + fend, g_src_len - fend);
    buf[at] = 0;
    Free(g_out);
    g_out = buf;
    g_out_len = at;
    CheckControl("NC-D6b-trailing-garbage", 1, "FIXTURE_SCHEMA_INVALID");
  }

  // ---- NC-D7: a truncated row (the last two fields dropped) -------
  //
  // The F001 row is cut after its sixth field, so it holds six fields
  // instead of eight.
  {
    I64 s = DataRowStart(0);            // F001
    if (s < 0) { printf("ERROR: F001 not found\n"); return 2; }
    I64 e = LineEnd(s);
    I64 tabs = 0;
    I64 k = s;
    while (k < e && tabs < 6) {
      if (g_src[k] == '\t') tabs = tabs + 1;
      k = k + 1;
    }
    // k is just past the sixth TAB: the start of the seventh field
    I64 cut = k;
    I64 total = cut;
    U8 *buf = MAlloc(total + 1);
    I64 at = 0;
    AppendBytes(buf, &at, g_src, cut);
    buf[at] = 0;
    Free(g_out);
    g_out = buf;
    g_out_len = at;
    CheckControl("NC-D7-truncated-row", 1, "FIXTURE_SCHEMA_INVALID");
  }

  // ---- NC-D11: a file with no candidate rows at all ---------------
  //
  // Every DATA row is removed; the comment and metadata rows remain.
  //
  // The removal is done into a separate buffer; the ORIGINAL fixture
  // buffer is NOT modified, so every later control still starts from
  // the pristine canonical fixture.
  {
    I64 n = base_rows;
    I64 *starts = MAlloc(n * 8);
    I64 *afters = MAlloc(n * 8);
    I64 i = 0;
    while (i < n) {
      starts[i] = DataRowStart(i);
      afters[i] = LineAfter(starts[i]);
      i = i + 1;
    }

    // Walk the original file, copying every NON-data line and skipping
    // every DATA line.
    I64 total = g_src_len;
    U8 *buf = MAlloc(total + 1);
    I64 at = 0;
    I64 pos = 0;
    while (pos < g_src_len) {
      I64 start = pos;
      while (pos < g_src_len && g_src[pos] != '\n' && g_src[pos] != '\r') pos = pos + 1;
      I64 end = pos;
      I64 after = pos;
      if (after < g_src_len && g_src[after] == '\r') after = after + 1;
      if (after < g_src_len && g_src[after] == '\n') after = after + 1;

      I64 is_data = 0;
      I64 len = end - start;
      if (len > 0) {
        U8 c = g_src[start];
        if (c != '#' && c != ' ' && c != '\t') {
          I64 k = start;
          while (k < end && g_src[k] != '\t') {
            if (g_src[k] == '=') { is_data = 0; break; }
            k = k + 1;
          }
          if (k >= end || g_src[k] == '\t') is_data = 1;
        }
      }

      if (!is_data) {
        AppendBytes(buf, &at, g_src + start, after - start);
      }
      pos = after;
    }
    buf[at] = 0;

    Free(g_out);
    g_out = buf;
    g_out_len = at;
    Free(starts);
    Free(afters);
    CheckControl("NC-D11-no-candidate-rows", 1, "FIXTURE_SET_EMPTY");

    // restore the pristine output for the following controls
    EditNone();
  }

  // ---- NC-D12: the 42 canonical rows PLUS an unknown id X001 ------
  //
  // This is the control the predecessor ACT froze in C1 and never
  // executed. Before the fix, this row was skipped by the row reader
  // BEFORE the unknown-ID ledger ran, so the differential returned
  // STATUS=PASS.
  {
    EditAppendLine(ROW_X001);
    CheckControl("NC-D12-unknown-X001", 1, "FIXTURE_ID_UNKNOWN");
  }

  // ---- NC-D13: the 42 canonical rows PLUS an unknown id Z999 ------
  //
  // The same bypass with a different non-'F' prefix. This control
  // proves the repair is not specific to the literal "X001".
  {
    EditAppendLine(ROW_Z999);
    CheckControl("NC-D13-unknown-Z999", 1, "FIXTURE_ID_UNKNOWN");
  }

  // ---- NC-D14: an unknown id in the MIDDLE of the fixture ---------
  //
  // The unknown row is not appended at the end, so the rejection
  // cannot be an artifact of a trailing-block rule.
  {
    I64 s = DataRowStart(20);           // F021
    if (s < 0) { printf("ERROR: F021 not found\n"); return 2; }
    EditInsertLine(s, ROW_X001);
    CheckControl("NC-D14-unknown-in-middle", 1, "FIXTURE_ID_UNKNOWN");
  }

  // ---- NC-D15: a row whose id has the wrong shape -----------------
  {
    EditAppendLine(ROW_F01);
    CheckControl("NC-D15-short-id", 1, "FIXTURE_ID_UNKNOWN");
  }

  // ---- NC-D16: a recognized comment row is still skipped ---------
  //
  // A recognized comment row must NOT be counted as a data row.
  {
    EditAppendLine("# a trailing comment row");
    CheckControl("NC-D16-comment-row-skipped", 0, NULL);
  }

  // ---- NC-D17: a KEY=VALUE metadata row is still skipped ---------
  {
    EditAppendLine("SOME_METADATA_KEY=some value");
    CheckControl("NC-D17-metadata-row-skipped", 0, NULL);
  }

  // ===================================================================
  // ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION02
  // ===================================================================
  //
  // The predecessor's row recognizer accepted ANY indented line as a
  // metadata continuation, without requiring that a metadata block was
  // in scope. An indented unknown fixture id was therefore invisible to
  // the unknown-ID ledger and the differential returned STATUS=PASS.

  // ---- NC-D18: an INDENTED unknown id in the middle --------------
  //
  // The row is inserted between F020 and F021, i.e. in the DATA
  // region, where no metadata block is in scope. It must be rejected.
  {
    I64 s = DataRowStart(20);           // F021
    if (s < 0) { printf("ERROR: F021 not found\n"); return 2; }
    EditInsertLine(s, ROW_IND_SPACE);
    CheckControl("NC-D18-indented-unknown-in-middle", 1, "FIXTURE_ID_UNKNOWN");
  }

  // ---- NC-D19: a TAB-indented unknown id -------------------------
  //
  // The leading TAB makes the first field empty, so the row carries 9
  // fields and is a SCHEMA failure. It must still be REJECTED.
  {
    I64 s = DataRowStart(20);           // F021
    if (s < 0) { printf("ERROR: F021 not found\n"); return 2; }
    EditInsertLine(s, ROW_IND_TAB);
    CheckControl("NC-D19-tab-indented-unknown", 1, "FIXTURE_SCHEMA_INVALID");
  }

  // ---- NC-D20: a TAB-indented unknown id with 8 fields -----------
  //
  // The canonical field count, so the failure is an unknown-ID
  // failure rather than a schema failure.
  {
    I64 s = DataRowStart(20);           // F021
    if (s < 0) { printf("ERROR: F021 not found\n"); return 2; }
    EditInsertLine(s, ROW_IND_TAB7);
    CheckControl("NC-D20-tab-indented-unknown-8-fields", 1, "FIXTURE_ID_UNKNOWN");
  }

  // ---- NC-D21: an appended row is SEPARATE from the last row -----
  //
  // The source's LAST LINE is not newline-terminated, so the appended
  // text would JOIN it if the driver did not emit a separating
  // newline. With the separator, the appended row is its own row, and
  // the fixture holds 43 data rows of which one is unknown.
  //
  // The driver models every edit as a range replacement over the
  // ORIGINAL buffer (g_src), so this control is expressed as ONE
  // edit: the range that holds the final newline is replaced by the
  // appended row, and the separator logic decides whether a newline
  // is emitted between the last existing line and that row.
  {
    // The canonical file's last line is a trailing comment line, NOT
    // a data row. The final '\n' is the byte to be replaced.
    if (g_src_len < 2 || g_src[g_src_len - 1] != '\n') {
      printf("ERROR: canonical fixture does not end with a newline\n");
      return 2;
    }
    // Replace the final '\n' with the appended row. EditAppendLine
    // appends at g_src_len, so the range is set explicitly here and
    // the replacement is built the same way EditAppendLine builds
    // it: a separating newline is emitted ONLY when the source does
    // not already end with one.
    //
    // The source DOES end with a newline here, so no separator is
    // emitted and the appended row lands on its own line. To make the
    // control load-bearing for the separator, the final newline is
    // REMOVED from the source first, and the row is then appended to
    // the unterminated source.
    I64 tail_start = g_src_len - 2;
    while (tail_start > 0
           && g_src[tail_start] != '\n'
           && g_src[tail_start] != '\r') tail_start = tail_start - 1;
    I64 last_line_start = tail_start + 1;
    if (last_line_start >= g_src_len - 1) { printf("ERROR: no last line\n"); return 2; }

    // Step 1: replace the final newline with nothing, so that the
    // source's last line is unterminated. This edit is expressed as
    // a range replacement over g_src, exactly like every other edit.
    g_cut_a = g_src_len - 1;
    g_cut_b = g_src_len;
    g_repl_len = 0;
    Free(g_repl);
    g_repl = MAlloc(1);
    g_repl[0] = 0;
    BuildOutput();

    // Step 2: append the unknown row to the unterminated source.
    //
    // The buffer that step 1 produced is g_out. It becomes the new
    // g_src for this step, but it must be a FRESH COPY: BuildOutput
    // frees g_out before it rebuilds it, so aliasing g_src to g_out
    // would leave g_src dangling.
    U8 *unterminated = MAlloc(g_out_len + 1);
    CopyStr(unterminated, g_out);
    Free(g_out);
    g_out = NULL;
    Free(g_src);
    g_src = unterminated;
    g_src_len = g_out_len;

    EditAppendLine(ROW_X001);
    CheckControl("NC-D21-appended-row-not-joined", 1, "FIXTURE_ID_UNKNOWN");

    // restore the pristine source for any following control
    Free(g_src);
    g_src = FileRead(argv[2], &g_src_len);
    if (g_src == NULL) { printf("ERROR: cannot re-read fixture\n"); return 2; }
    EditNone();
  }

  printf("NEGATIVE_CONTROLS_TOTAL=%d\n", g_controls);
  printf("NEGATIVE_CONTROLS_BROKEN=%d\n", g_failures);
  if (g_failures) {
    "STATUS=FAIL\n";
    return 1;
  }
  "STATUS=PASS\n";
  return 0;
}
