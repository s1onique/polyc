// tools/quality/parser-slice08-evidence-correction01-verify.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE08-EVIDENCE-CORRECTION01 C2 IMPL.
//
// THE INDEPENDENT CORRECTION PROOF AUDITOR.  A PolyC implementation.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// WHY THIS TOOL EXISTS
// ===================
//
// Two historical SLICE08 evidence files contain defects that their own
// summaries deny:
//
//   1. c3/inherited-controls-join.tsv contains 24 data rows, one of
//      which (SL-EC-06) is NOT in the C0 frozen inherited-controls
//      contract, while the SAME file asserts
//      INHERITED_CONTROLS_TOTAL=23 and INHERITED_CONTROLS_EXTRA=0.
//
//   2. c1/selected-source-and-abi.txt prints one SHA-256 and asserts
//      it is IDENTICAL to a different SHA-256.
//
// This tool does NOT accept a self-reported label.  It re-derives
// every decisive predicate from the LIVE bytes of the COMMITTED
// artifacts.  It derives the control-ID sets BY PARSING, and it never
// hardcodes an expected ID list or an expected summary value.
//
// The file digests are computed by the EXTERNAL system digest tool
// (shasum -a 256) through the process-spawn surface, so that the
// auditor does not share an implementation with the artifacts it
// judges.
//
// It has SIX modes, each MECHANICAL:
//
//   MODE=FREEZE     Re-verify the correction-owned predecessor freeze
//                   manifest against the LIVE file bytes.
//
//   MODE=JOIN       Re-derive the three-way control-ID reconciliation
//                   (F = RECON07 frozen, B = SLICE08 C0 contract,
//                   J = SLICE08 C3 join) from the bytes, report the
//                   row counts, the distinct-ID counts, the duplicate
//                   IDs, the FOUR set differences, and compare the J
//                   summary block against the rows.
//
//   MODE=PROVENANCE Parse the C1 source-range claim from the bytes and
//                   check the EQUALITY ASSERTION against the two
//                   digests it names.
//
//   MODE=NEGATIVE   Run the ten correction-owned negative controls
//                   (E8-NC-01..10) against DISPOSABLE COPIES and
//                   report the exact failure class of each.
//
//   MODE=VERIFY     The combined verification.
//
//   MODE=SELFTEST   Verify this tool against known-answer vectors.
//
// USAGE:
//   build/parser-slice08-evidence-correction01-verify FREEZE <manifest.tsv>
//   build/parser-slice08-evidence-correction01-verify JOIN <recon07-dir> <slice08-dir>
//   build/parser-slice08-evidence-correction01-verify PROVENANCE <c1-file>
//   build/parser-slice08-evidence-correction01-verify NEGATIVE <recon07-dir> <slice08-dir> <workdir>
//   build/parser-slice08-evidence-correction01-verify VERIFY <recon07-dir> <slice08-dir> <corr-dir>
//   build/parser-slice08-evidence-correction01-verify SELFTEST
//
// Every answer it prints is derived from the bytes it reads.  It does
// not judge; it reports.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// ------------------------------------------------------------------
// Small helpers.
// ------------------------------------------------------------------

static I64 StrEq(U8 *a, U8 *b)
{
  if (!a || !b) return 0;
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a = a + 1; b = b + 1;
  }
  if (*a != *b) return 0;
  return 1;
}

static I64 StrContain(U8 *hay, U8 *needle)
{
  if (!hay || !needle) return 0;
  I64 nl = StrLen(needle);
  if (nl == 0) return 1;
  I64 hl = StrLen(hay);
  for (I64 i = 0; i + nl <= hl; i = i + 1) {
    I64 j = 0;
    while (j < nl && hay[i+j] == needle[j]) j = j + 1;
    if (j == nl) return 1;
  }
  return 0;
}

static I64 CountContain(U8 *hay, U8 *needle)
{
  if (!hay || !needle) return 0;
  I64 nl = StrLen(needle);
  if (nl == 0) return 0;
  I64 hl = StrLen(hay);
  I64 n = 0;
  for (I64 i = 0; i + nl <= hl; i = i + 1) {
    I64 j = 0;
    while (j < nl && hay[i+j] == needle[j]) j = j + 1;
    if (j == nl) { n = n + 1; i = i + nl - 1; }
  }
  return n;
}

static U8 *DupStr(U8 *s)
{
  if (!s) return NULL;
  I64 n = StrLen(s);
  U8 *d = MAlloc(n + 1);
  MemCpy(d, s, n + 1);
  return d;
}

static U8 *JoinPath(U8 *dir, U8 *leaf)
{
  I64 dl = StrLen(dir);
  I64 ll = StrLen(leaf);
  U8 *p = MAlloc(dl + ll + 2);
  MemCpy(p, dir, dl);
  p[dl] = '/';
  MemCpy(p + dl + 1, leaf, ll + 1);
  return p;
}

// ReadText: read a whole file into a NUL-TERMINATED buffer.
//
// FileRead returns the file bytes with their LENGTH but WITHOUT a
// trailing NUL.  StrLen on such a buffer would read past the end of
// the allocation, so the buffer is copied into a buffer of
// len+1 bytes with an explicit terminator.
static U8 *ReadText(U8 *path)
{
  if (!path) return NULL;
  I64 len = 0;
  U8 *buf = FileRead(path, &len);
  if (!buf) return NULL;
  U8 *out = MAlloc(len + 1);
  if (len > 0) MemCpy(out, buf, len);
  out[len] = 0;
  return out;
}

// The open flags used by the disposable-fixture writers.
//
// FileWrite opens the file with the flags it is given, so O_CREAT is
// REQUIRED for a file that does not exist yet, O_TRUNC is REQUIRED
// when a file is rewritten from scratch, and O_APPEND is required to
// append rather than overwrite.
#define E8C01_O_RDWR   0x0002
#define E8C01_O_APPEND 0x0008
#define E8C01_O_CREAT  0x0200
#define E8C01_O_TRUNC  0x0400
#define E8C01_WRITE_NEW    (E8C01_O_CREAT | E8C01_O_RDWR | E8C01_O_TRUNC)
#define E8C01_WRITE_APPEND (E8C01_O_CREAT | E8C01_O_RDWR | E8C01_O_APPEND)

static U8 *WriteText(U8 *path, U8 *text)
{
  I64 n = StrLen(text);
  if (FileWrite(path, text, n, E8C01_WRITE_NEW)) return text;
  return NULL;
}

static U0 AppendText(U8 *path, U8 *text)
{
  I64 n = StrLen(text);
  FileWrite(path, text, n, E8C01_WRITE_APPEND);
}

// B: normalise a predicate to the printable 0 or 1.
//
// The PolyC type inference does not accept the conditional operator
// on an integer operand, so every reported predicate is normalised
// through this function instead.
static I64 B(I64 v)
{
  if (v) return 1;
  return 0;
}

// I64FromStr: parse a decimal integer from the start of `s`.
// Returns -1 when the string does not begin with a digit.
static I64 I64FromStr(U8 *s)
{
  if (!s) return -1;
  if (s[0] < '0' || s[0] > '9') return -1;
  I64 v = 0;
  I64 i = 0;
  while (s[i] >= '0' && s[i] <= '9') {
    v = v * 10 + (s[i] - '0');
    i = i + 1;
  }
  return v;
}

// IsHex64: TRUE when the first 64 bytes of `s` are lowercase hex and
// the 65th byte is a NUL terminator.
static I64 IsHex64(U8 *s)
{
  if (!s) return 0;
  for (I64 k = 0; k < 64; k = k + 1) {
    U8 c = s[k];
    I64 okc = 0;
    if (c >= '0' && c <= '9') okc = 1;
    if (c >= 'a' && c <= 'f') okc = 1;
    if (!okc) return 0;
  }
  if (s[64] != 0) return 0;
  return 1;
}

// ------------------------------------------------------------------
// The digest.
//
// The digest is computed by the REPOSITORY OWN PolyC SHA-256 tool
// (build/lexer07-sha256), invoked through the process-spawn surface.
// That tool is itself a PolyC implementation and is the digest
// authority the rest of the repository already uses, so the auditor
// does not need to carry a second digest implementation.
//
// The argv array MUST be NULL-terminated; execv requires it.
// ------------------------------------------------------------------

#define E8C01_SHA256_BIN "./build/lexer07-sha256"

static U8 *HashFile(U8 *path)
{
  if (!path) return NULL;
  U8 *args[4];
  args[0] = E8C01_SHA256_BIN;
  args[1] = "--file";
  args[2] = path;
  args[3] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(E8C01_SHA256_BIN, args, &out, &err);
  if (err) Free(err);
  if (rc != 0) {
    if (out) Free(out);
    return NULL;
  }
  if (!out) return NULL;
  // The output is the 64-hex digest, followed by a newline.
  //
  // IsHex64 requires the 65th byte to be a NUL terminator, so the
  // digest is copied out FIRST and then checked, rather than checked
  // in place.
  U8 *p = out;
  while (*p == ' ' || *p == '\t') p = p + 1;
  if (StrLen(p) < 64) {
    Free(out);
    return NULL;
  }
  U8 *hex = MAlloc(65);
  MemCpy(hex, p, 64);
  hex[64] = 0;
  Free(out);
  if (!IsHex64(hex)) return NULL;
  return hex;
}

// CopyFile: copy the bytes of `src` to `dst`.
static I64 CopyFile(U8 *src, U8 *dst)
{
  I64 len = 0;
  U8 *buf = FileRead(src, &len);
  if (!buf) return 1;
  if (!FileWrite(dst, buf, len, E8C01_WRITE_NEW)) return 1;
  return 0;
}

// ------------------------------------------------------------------
// The disposable-fixture directory.
//
// The negative-control suite writes its disposable copies into a
// per-control subdirectory, which it creates itself.  libtos exports
// mkdir(2) directly.
// ------------------------------------------------------------------

extern "c" I32 mkdir(U8 *dirname, I32 mode = 438);

static U0 MakeDir(U8 *path)
{
  mkdir(path, 0x1FF);
}

// ------------------------------------------------------------------
// A field splitter: split a line on TAB into G_FIELDS.
// ------------------------------------------------------------------

#define MAX_FIELDS 64
static U8 *G_FIELDS[MAX_FIELDS];
static I64 G_NFIELDS;

static U0 SplitFields(U8 *line)
{
  G_NFIELDS = 0;
  if (!line) return;
  I64 n = StrLen(line);
  I64 start = 0;
  for (I64 i = 0; i <= n; i = i + 1) {
    I64 at_end = (i == n);
    I64 at_tab = 0;
    if (!at_end) if (line[i] == '\t') at_tab = 1;
    if (at_end || at_tab) {
      I64 len = i - start;
      if (G_NFIELDS < MAX_FIELDS) {
        G_FIELDS[G_NFIELDS] = line + start;
        line[start+len] = 0;
        G_NFIELDS = G_NFIELDS + 1;
      }
      start = i + 1;
    }
  }
}

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// A line splitter: split a text into G_LINES.
// ------------------------------------------------------------------

#define MAX_SPLIT_LINES 32768
static U8 *G_LINES[MAX_SPLIT_LINES];
static I64 G_NLINES;
//
// The splitter SKIPS blank lines entirely.  A blank line carries no
// data in any of the schemas this tool reads, and keeping it would
// make every consumer test for it again.
//
// The splitter does NOT skip comment lines or KEY=VALUE summary
// lines: those are meaningful to the callers, and IsSummaryLine is
// the single place that decides what a non-data line is.
static U0 SplitLines(U8 *text)
{
  G_NLINES = 0;
  if (!text) return;
  I64 n = StrLen(text);
  if (n == 0) return;
  I64 start = 0;
  for (I64 i = 0; i <= n; i = i + 1) {
    I64 at_end = (i == n);
    I64 at_nl = 0;
    if (!at_end) if (text[i] == '\n') at_nl = 1;
    if (at_end || at_nl) {
      I64 len = i - start;
      if (len > 0) {
        if (G_NLINES < MAX_SPLIT_LINES) {
          G_LINES[G_NLINES] = text + start;
          text[start+len] = 0;
          G_NLINES = G_NLINES + 1;
        }
      }
      start = i + 1;
    }
  }
}

// IsSummaryLine: TRUE when the line is a comment, a blank line or a
// "KEY=VALUE" summary line rather than a data row.
//
// A data row in these schemas always contains at least one TAB.  A
// summary line never does.
static I64 IsSummaryLine(U8 *l)
{
  if (!l) return 1;
  if (l[0] == '#') return 1;
  if (l[0] == 0) return 1;
  for (I64 i = 0; l[i] != 0; i = i + 1) {
    if (l[i] == '\t') return 0;
  }
  return 1;
}

// FindKV: the value of a "KEY=VALUE" line whose key is exactly `key`.
static U8 *FindKV(U8 *text, U8 *key)
{
  if (!text) return NULL;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (l[0] == '#') continue;
    U8 *eq = StrFirstOcc(l, "=");
    if (!eq) continue;
    I64 klen = eq - l;
    if (klen != StrLen(key)) continue;
    I64 match = 1;
    for (I64 k = 0; k < klen; k = k + 1) {
      if (l[k] != key[k]) { match = 0; }
    }
    if (match) return eq + 1;
  }
  return NULL;
}

// KVInt: the integer value of a KEY=VALUE string, or -1 when the
// string is absent or does not begin with a digit.
//
// The conditional expression is NOT used here on purpose: a
// conditional whose branches are both pointers makes the PolyC type
// inference explode (it allocates gigabytes for a single expression).
static I64 KVInt(U8 *s)
{
  if (!s) return -1;
  return I64FromStr(s);
}

// RowFieldsOf: find the row of `path` whose first field is `id` and
// whose column count is exactly `ncols`, and return the field at
// index `idx` through `out`.
//
// Returns 1 when the field was found, 0 otherwise.  The returned
// pointer is a fresh copy, so it stays valid across subsequent calls.
static I64 RowFieldsOf(U8 *path, U8 *id, I64 ncols, I64 idx, U8 **out)
{
  *out = NULL;
  U8 *text = ReadText(path);
  if (!text) return 0;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (IsSummaryLine(l)) continue;
    U8 *tmp = DupStr(l);
    SplitFields(tmp);
    if (G_NFIELDS != ncols) continue;
    if (!StrEq(G_FIELDS[0], id)) continue;
    if (idx >= G_NFIELDS) return 0;
    *out = DupStr(G_FIELDS[idx]);
    return 1;
  }
  return 0;
}

// RowFields: find the row of `path` whose first field is `id` and
// whose column count is exactly `ncols`, and return the field at
// index `idx` through `out`.
static U0 RowFields(U8 *path, U8 *id, I64 ncols, I64 idx, U8 **out)
{
  *out = NULL;
  U8 *text = ReadText(path);
  if (!text) return;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (IsSummaryLine(l)) continue;
    U8 *tmp = DupStr(l);
    SplitFields(tmp);
    if (G_NFIELDS != ncols) continue;
    if (!StrEq(G_FIELDS[0], id)) continue;
    if (idx >= G_NFIELDS) return;
    *out = DupStr(G_FIELDS[idx]);
    return;
  }
}

// ------------------------------------------------------------------
// THE CONTROL-ID INVENTORY.
//
// A control-ID SET is a list of IDs plus the number of DISTINCT IDs
// and the number of DUPLICATE IDs.  It is built BY PARSING, never by
// transcription.  There is NO hardcoded expected ID list anywhere in
// this tool.
// ------------------------------------------------------------------

#define MAX_IDS 512

class IdSet {
  U8 *ids[MAX_IDS];
  I64 n;
  I64 distinct;
  I64 dups;
  I64 malformed;
};

static U0 IdSetInit(IdSet *s)
{
  s->n = 0;
  s->distinct = 0;
  s->dups = 0;
  s->malformed = 0;
}

static I64 IdSetHas(IdSet *s, U8 *id)
{
  for (I64 i = 0; i < s->n; i = i + 1) {
    if (StrEq(s->ids[i], id)) return 1;
  }
  return 0;
}

static U0 IdSetAdd(IdSet *s, U8 *id)
{
  if (s->n >= MAX_IDS) return;
  if (IdSetHas(s, id)) {
    s->dups = s->dups + 1;
    return;
  }
  s->ids[s->n] = DupStr(id);
  s->n = s->n + 1;
  s->distinct = s->distinct + 1;
}

// ParseTsvIds: parse a TSV file, accept ONLY rows whose column count
// is EXACTLY `ncols`, and collect the first field of each such row.
//
// Rows with a different column count are NOT data rows.  They are
// counted as malformed and are NOT silently discarded: they are
// reported, so that a truncated or over-long row is visible.
static U0 ParseTsvIds(U8 *path, I64 ncols, IdSet *out, I64 *rowcount)
{
  *rowcount = 0;
  U8 *text = ReadText(path);
  if (!text) return;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (IsSummaryLine(l)) continue;
    U8 *c2 = DupStr(l);
    SplitFields(c2);
    if (G_NFIELDS != ncols) {
      out->malformed = out->malformed + 1;
      continue;
    }
    if (StrLen(G_FIELDS[0]) == 0) continue;
    *rowcount = *rowcount + 1;
    IdSetAdd(out, G_FIELDS[0]);
  }
}

// ParseMarkdownTableIds: parse a GitHub-flavoured markdown table and
// collect the ID in the FIRST cell of each data row.
//
// A row is a data row when it begins with "|" and splits into exactly
// THREE cells and the first cell is not a header cell and not a
// separator cell (a run of '-' characters).
static U0 ParseMarkdownTableIds(U8 *path, IdSet *out, I64 *rowcount)
{
  *rowcount = 0;
  U8 *text = ReadText(path);
  if (!text) return;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (StrLen(l) < 2) continue;
    if (l[0] != '|') continue;
    I64 pipes = 0;
    for (I64 k = 0; l[k] != 0; k = k + 1) {
      if (l[k] == '|') pipes = pipes + 1;
    }
    if (pipes != 4) continue;
    I64 first = -1;
    I64 second = -1;
    for (I64 k = 0; l[k] != 0; k = k + 1) {
      if (l[k] == '|') {
        if (first < 0) first = k;
        else { second = k; break; }
      }
    }
    if (first < 0 || second < 0) continue;
    I64 len = second - first - 1;
    if (len <= 0) continue;
    U8 *cell = MAlloc(len + 1);
    MemCpy(cell, l + first + 1, len);
    cell[len] = 0;
    I64 s = 0;
    I64 e = len;
    while (s < e) {
      U8 c = cell[s];
      if (c == ' ' || c == '\t' || c == '\r') s = s + 1; else break;
    }
    while (e > s) {
      U8 c = cell[e-1];
      if (c == ' ' || c == '\t' || c == '\r') e = e - 1; else break;
    }
    I64 tl = e - s;
    U8 *trimmed = MAlloc(tl + 1);
    MemCpy(trimmed, cell + s, tl);
    trimmed[tl] = 0;
    I64 is_sep = 1;
    for (I64 k = 0; k < tl; k = k + 1) {
      if (trimmed[k] != '-') { is_sep = 0; break; }
    }
    if (is_sep) continue;
    if (StrEq(trimmed, "ID")) continue;
    *rowcount = *rowcount + 1;
    IdSetAdd(out, trimmed);
  }
}

// ParseControlIdAssignments: parse "control_id   = <ID>" assignments
// out of a frozen causal contract.
static U0 ParseControlIdAssignments(U8 *path, IdSet *out, I64 *rowcount)
{
  *rowcount = 0;
  U8 *text = ReadText(path);
  if (!text) return;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    U8 *c2 = DupStr(l);
    SplitFields(c2);
    if (G_NFIELDS < 1) continue;
    U8 *head = G_FIELDS[0];
    if (!StrContain(head, "control_id")) continue;
    U8 *eq = StrFirstOcc(head, "=");
    if (!eq) continue;
    U8 *val = eq + 1;
    while (*val == ' ' || *val == '\t') val = val + 1;
    if (StrLen(val) == 0) continue;
    *rowcount = *rowcount + 1;
    IdSetAdd(out, val);
  }
}

// SetDiffCount: the number of IDs of `a` that are NOT in `b`.
static I64 SetDiffCount(IdSet *a, IdSet *b)
{
  I64 n = 0;
  for (I64 i = 0; i < a->n; i = i + 1) {
    if (!IdSetHas(b, a->ids[i])) n = n + 1;
  }
  return n;
}

// SetDiffPrint: print the IDs of `a` that are NOT in `b`, one per
// line, prefixed with `label=`.
static U0 SetDiffPrint(U8 *label, IdSet *a, IdSet *b)
{
  for (I64 i = 0; i < a->n; i = i + 1) {
    if (!IdSetHas(b, a->ids[i])) {
      "%s=%s\n", label, a->ids[i];
    }
  }
}

// The schema column counts, as declared by the committed files' own
// header comments.  They are not a list of control IDs.
#define B_NCOLS 7
#define J_NCOLS 13

// ------------------------------------------------------------------
// MODE=FREEZE
//
// Re-verify a "sha256<TAB>git_blob_id<TAB>path" manifest against the
// LIVE file bytes.
//
// The manifest is parsed BY SHAPE: a data row is one whose first
// field is a 64-hex digest and whose second field is a 40-hex Git
// blob id.
// ------------------------------------------------------------------

static I64 ModeFreeze(U8 *manifest)
{
  U8 *text = ReadText(manifest);
  if (!text) {
    "STATUS=ERROR\nREASON=cannot read manifest\n";
    return 2;
  }
  U8 *copy = DupStr(text);
  SplitLines(copy);

  I64 total = 0;
  I64 ok = 0;
  I64 missing = 0;
  I64 mismatch = 0;

  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (IsSummaryLine(l)) continue;
    U8 *c2 = DupStr(l);
    SplitFields(c2);
    if (G_NFIELDS < 3) continue;
    if (!IsHex64(G_FIELDS[0])) continue;
    I64 is_blob = 1;
    for (I64 k = 0; k < 40; k = k + 1) {
      U8 c = G_FIELDS[1][k];
      I64 okc = 0;
      if (c >= '0' && c <= '9') okc = 1;
      if (c >= 'a' && c <= 'f') okc = 1;
      if (!okc) { is_blob = 0; }
    }
    if (!is_blob) continue;
    if (G_FIELDS[1][40] != 0) continue;

    total = total + 1;
    U8 *path = G_FIELDS[2];
    U8 *got = HashFile(path);
    if (!got) {
      missing = missing + 1;
      "FREEZE_MISSING=%s\n", path;
    } else if (StrEq(G_FIELDS[0], got)) {
      ok = ok + 1;
    } else {
      mismatch = mismatch + 1;
      "FREEZE_MISMATCH=%s\n", path;
    }
  }

  "FREEZE_TOTAL=%d\n", total;
  "FREEZE_OK=%d\n", ok;
  "FREEZE_MISSING=%d\n", missing;
  "FREEZE_MISMATCH=%d\n", mismatch;
  if (mismatch == 0 && missing == 0 && total > 0) {
    "FREEZE_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "FREEZE_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=JOIN
//
// Re-derive the three-way control-ID reconciliation from the COMMITTED
// bytes:
//
//   F = the RECON07 frozen obligations
//       (c2/selected-negative-controls.md + c2/selected-causal-contract.md)
//   B = the SLICE08 C0 inherited-controls-contract.tsv
//   J = the SLICE08 C3 inherited-controls-join.tsv
//
// and then compare the J summary block against the rows that were
// actually parsed.
//
// The summary comparison is done BY ARITHMETIC ON THE PARSED ROWS.
// It never reads the claimed TOTAL as a fact; it reads it as a CLAIM
// and checks it.
//
// The HISTORICAL-ORIGINAL namespace and the CORRECTION-SUPPLEMENTAL
// namespace are counted SEPARATELY, so that a control that is extra
// with respect to the frozen contract is never counted inside the
// frozen count.
// ------------------------------------------------------------------

static I64 ModeJoin(U8 *recon07, U8 *slice08)
{
  IdSet Fneg; IdSetInit(&Fneg);
  IdSet Fcausal; IdSetInit(&Fcausal);
  IdSet F; IdSetInit(&F);
  IdSet B; IdSetInit(&B);
  IdSet J; IdSetInit(&J);
  I64 fneg_rows = 0, fcausal_rows = 0, f_rows = 0, b_rows = 0, j_rows = 0;

  U8 *negpath = JoinPath(recon07, "c2/selected-negative-controls.md");
  if (!ReadText(negpath)) {
    "STATUS=ERROR\nREASON=cannot read the RECON07 negative-controls contract\n";
    return 2;
  }
  ParseMarkdownTableIds(negpath, &Fneg, &fneg_rows);

  U8 *causalpath = JoinPath(recon07, "c2/selected-causal-contract.md");
  if (!ReadText(causalpath)) {
    "STATUS=ERROR\nREASON=cannot read the RECON07 causal contract\n";
    return 2;
  }
  ParseControlIdAssignments(causalpath, &Fcausal, &fcausal_rows);

  for (I64 i = 0; i < Fneg.n; i = i + 1) { IdSetAdd(&F, Fneg.ids[i]); f_rows = f_rows + 1; }
  for (I64 i = 0; i < Fcausal.n; i = i + 1) { IdSetAdd(&F, Fcausal.ids[i]); f_rows = f_rows + 1; }

  U8 *bpath = JoinPath(slice08, "c0/inherited-controls-contract.tsv");
  if (!ReadText(bpath)) {
    "STATUS=ERROR\nREASON=cannot read the SLICE08 C0 inherited-controls contract\n";
    return 2;
  }
  ParseTsvIds(bpath, B_NCOLS, &B, &b_rows);

  U8 *jpath = JoinPath(slice08, "c3/inherited-controls-join.tsv");
  U8 *jtext = ReadText(jpath);
  if (!jtext) {
    "STATUS=ERROR\nREASON=cannot read the SLICE08 C3 inherited-controls join\n";
    return 2;
  }
  ParseTsvIds(jpath, J_NCOLS, &J, &j_rows);

  I64 f_minus_b = SetDiffCount(&F, &B);
  I64 b_minus_f = SetDiffCount(&B, &F);
  I64 b_minus_j = SetDiffCount(&B, &J);
  I64 j_minus_b = SetDiffCount(&J, &B);
  I64 f_minus_j = SetDiffCount(&F, &J);
  I64 j_minus_f = SetDiffCount(&J, &F);

  "JOIN_F_NEGCTRL_ROWS=%d\n", fneg_rows;
  "JOIN_F_NEGCTRL_DISTINCT=%d\n", Fneg.distinct;
  "JOIN_F_CAUSAL_ROWS=%d\n", fcausal_rows;
  "JOIN_F_CAUSAL_DISTINCT=%d\n", Fcausal.distinct;
  "JOIN_F_ROWS=%d\n", f_rows;
  "JOIN_F_DISTINCT=%d\n", F.distinct;
  "JOIN_B_ROWS=%d\n", b_rows;
  "JOIN_B_DISTINCT=%d\n", B.distinct;
  "JOIN_J_ROWS=%d\n", j_rows;
  "JOIN_J_DISTINCT=%d\n", J.distinct;
  "JOIN_F_DUPLICATES=%d\n", F.dups;
  "JOIN_B_DUPLICATES=%d\n", B.dups;
  "JOIN_J_DUPLICATES=%d\n", J.dups;
  "JOIN_B_MALFORMED_ROWS=%d\n", B.malformed;
  "JOIN_J_MALFORMED_ROWS=%d\n", J.malformed;
  "JOIN_F_MINUS_B=%d\n", f_minus_b;
  "JOIN_B_MINUS_F=%d\n", b_minus_f;
  "JOIN_B_MINUS_J=%d\n", b_minus_j;
  "JOIN_J_MINUS_B=%d\n", j_minus_b;
  "JOIN_F_MINUS_J=%d\n", f_minus_j;
  "JOIN_J_MINUS_F=%d\n", j_minus_f;

  // --- the HISTORICAL-ORIGINAL namespace ---
  I64 joined_frozen = 0;
  I64 extra_vs_frozen = 0;
  for (I64 i = 0; i < J.n; i = i + 1) {
    if (IdSetHas(&F, J.ids[i])) joined_frozen = joined_frozen + 1;
    else extra_vs_frozen = extra_vs_frozen + 1;
  }
  "JOIN_FROZEN_JOINED=%d\n", joined_frozen;
  "JOIN_EXTRA_VS_FROZEN=%d\n", extra_vs_frozen;
  "JOIN_MISSING_VS_FROZEN=%d\n", f_minus_j;

  // --- the J summary block, read as CLAIMS and checked ---
  U8 *ct = FindKV(jtext, "INHERITED_CONTROLS_TOTAL");
  U8 *cj = FindKV(jtext, "INHERITED_CONTROLS_JOINED");
  U8 *ce = FindKV(jtext, "INHERITED_CONTROLS_EXTRA");
  U8 *cd = FindKV(jtext, "INHERITED_CONTROLS_DUPLICATE");
  U8 *cp = FindKV(jtext, "INHERITED_CONTROLS_PASS");
  I64 c_total = KVInt(ct);
  I64 c_joined = KVInt(cj);
  I64 c_extra = KVInt(ce);
  I64 c_dup = KVInt(cd);
  I64 c_pass = KVInt(cp);

  "JOIN_CLAIMED_TOTAL=%d\n", c_total;
  "JOIN_CLAIMED_JOINED=%d\n", c_joined;
  "JOIN_CLAIMED_EXTRA=%d\n", c_extra;
  "JOIN_CLAIMED_DUPLICATE=%d\n", c_dup;
  "JOIN_CLAIMED_PASS=%d\n", c_pass;

  // --- the DETECTORS, fired on the PARSED facts ---
  I64 d_extra_id = 0;
  if (j_minus_b > 0) d_extra_id = 1;
  I64 d_missing_id = 0;
  if (b_minus_j > 0) d_missing_id = 1;
  I64 d_duplicate_id = 0;
  if (J.dups > 0) d_duplicate_id = 1;
  I64 d_count_contradiction = 0;
  if (c_total >= 0) if (c_total != j_rows) d_count_contradiction = 1;
  if (c_joined >= 0) if (c_joined != joined_frozen) d_count_contradiction = 1;
  if (c_extra >= 0) if (c_extra != extra_vs_frozen) d_count_contradiction = 1;
  if (c_dup >= 0) if (c_dup != J.dups) d_count_contradiction = 1;
  I64 d_frozen_omission = 0;
  if (f_minus_b > 0) d_frozen_omission = 1;

  "DETECT_EXTRA_ID=%d\n", B(d_extra_id);
  "DETECT_MISSING_ID=%d\n", B(d_missing_id);
  "DETECT_DUPLICATE_ID=%d\n", B(d_duplicate_id);
  "DETECT_CLAIMED_COUNT_CONTRADICTS_ROWS=%d\n", B(d_count_contradiction);
  "DETECT_FROZEN_OMISSION_FROM_C0=%d\n", B(d_frozen_omission);

  "JOIN_F_MINUS_B_IDS_BEGIN\n";
  SetDiffPrint("JOIN_F_MINUS_B_ID", &F, &B);
  "JOIN_F_MINUS_B_IDS_END\n";
  "JOIN_J_MINUS_B_IDS_BEGIN\n";
  SetDiffPrint("JOIN_J_MINUS_B_ID", &J, &B);
  "JOIN_J_MINUS_B_IDS_END\n";
  "JOIN_B_MINUS_J_IDS_BEGIN\n";
  SetDiffPrint("JOIN_B_MINUS_J_ID", &B, &J);
  "JOIN_B_MINUS_J_IDS_END\n";

  // --- the summary, RECOMPUTED FROM THE ROWS ---
  "RECOMPUTED_FROZEN_TOTAL=%d\n", F.distinct;
  "RECOMPUTED_C0_CONTRACT_ROWS=%d\n", B.distinct;
  "RECOMPUTED_C3_JOIN_ROWS=%d\n", J.distinct;
  "RECOMPUTED_FROZEN_JOINED=%d\n", joined_frozen;
  "RECOMPUTED_EXTRA_VS_FROZEN=%d\n", extra_vs_frozen;
  "RECOMPUTED_MISSING_VS_FROZEN=%d\n", f_minus_j;

  I64 fail = 0;
  if (d_count_contradiction) fail = 1;
  if (d_duplicate_id) fail = 1;
  if (d_extra_id) fail = 1;
  if (d_missing_id) fail = 1;
  if (d_frozen_omission) fail = 1;
  if (fail) {
    "JOIN_STATUS=FAIL\n";
    "STATUS=FAIL\n";
    return 1;
  }
  "JOIN_STATUS=PASS\n";
  "STATUS=PASS\n";
  return 0;
}

// ------------------------------------------------------------------
// MODE=PROVENANCE
//
// Parse the C1 source-range claim out of the committed C1 file and
// check the EQUALITY ASSERTION against the two digests it names.
//
// The tool does NOT decide which digest is "right": it decides
// whether the EQUALITY ASSERTION is TRUE, which is a pure arithmetic
// question about two strings that are both present in the file.
//
// It also extracts the phase claims the file makes about the source
// it describes, so that a CHRONOLOGY defect is visible as a
// structural fact about the file rather than as an opinion.
// ------------------------------------------------------------------

static I64 ModeProvenance(U8 *c1file)
{
  U8 *text = ReadText(c1file);
  if (!text) {
    "STATUS=ERROR\nREASON=cannot read the C1 source-range file\n";
    return 2;
  }
  U8 *copy = DupStr(text);
  SplitLines(copy);

  // The printed digest: the FIRST 64-hex token in the file.
  U8 *printed = NULL;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    U8 *tok = l;
    while (*tok == ' ' || *tok == '\t') tok = tok + 1;
    if (IsHex64(tok)) { printed = DupStr(tok); break; }
  }
  // The frozen digest: the SECOND 64-hex token in the file.
  U8 *frozen = NULL;
  {
    I64 seen = 0;
    for (I64 i = 0; i < G_NLINES; i = i + 1) {
      U8 *l = G_LINES[i];
      if (!l) continue;
      U8 *tok = l;
      while (*tok == ' ' || *tok == '\t') tok = tok + 1;
      if (!IsHex64(tok)) continue;
      seen = seen + 1;
      if (seen == 2) { frozen = DupStr(tok); break; }
    }
  }
  if (!printed || !frozen) {
    "PROV_STATUS=ERROR\n";
    "PROV_PRINTED_DIGEST_FOUND=%d\n", B(printed != NULL);
    "PROV_FROZEN_DIGEST_FOUND=%d\n", B(frozen != NULL);
    "STATUS=ERROR\n";
    return 2;
  }

  I64 equality_asserted = 0;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (StrContain(l, "IDENTICAL")) equality_asserted = 1;
  }

  U8 *range_claim = FindKV(text, "SELECTED_SOURCE_RANGE");
  U8 *summary_sha = FindKV(text, "SELECTED_SOURCE_SHA256");
  U8 *summary_match = FindKV(text, "SELECTED_SOURCE_RANGE_MATCH");
  I64 range_match_asserted = 0;
  if (summary_match) if (StrEq(summary_match, "YES")) range_match_asserted = 1;

  I64 digests_equal = 0;
  if (StrEq(printed, frozen)) digests_equal = 1;

  // NOTE: the pointer-valued conditional expression is NOT used here.
  // A conditional whose branches are both pointers makes the PolyC
  // type inference explode (it allocates gigabytes for a single
  // expression).  Every such choice is therefore made by an explicit
  // assignment instead.
  U8 *summary_sha_show = summary_sha;
  if (!summary_sha_show) summary_sha_show = "(absent)";
  U8 *range_claim_show = range_claim;
  if (!range_claim_show) range_claim_show = "(absent)";
  U8 *equality_show = "FALSE";
  if (digests_equal) equality_show = "TRUE";

  "PROV_PRINTED_SHA256=%s\n", printed;
  "PROV_FROZEN_SHA256=%s\n", frozen;
  "PROV_SUMMARY_SHA256=%s\n", summary_sha_show;
  "PROV_RANGE_CLAIM=%s\n", range_claim_show;
  "PROV_DIGESTS_ARE_EQUAL=%d\n", B(digests_equal);
  "PROV_EQUALITY_ASSERTED=%d\n", B(equality_asserted);
  "PROV_RANGE_MATCH_ASSERTED=%d\n", B(range_match_asserted);

  I64 d_false_hash_equality = 0;
  if (equality_asserted) if (!digests_equal) d_false_hash_equality = 1;

  I64 d_internal_self_contradiction = 0;
  if (summary_sha) if (!StrEq(summary_sha, printed)) d_internal_self_contradiction = 1;

  "DETECT_FALSE_HASH_EQUALITY=%d\n", B(d_false_hash_equality);
  "DETECT_INTERNAL_SELF_CONTRADICTION=%d\n", B(d_internal_self_contradiction);
  "PROV_ORIGINAL_HASH_EQUALITY_CLAIM=%s\n", equality_show;

  I64 mentions_helper = 0;
  I64 claims_unchanged = 0;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (StrContain(l, "parseDefaultArmTerminates")) mentions_helper = 1;
    if (StrContain(l, "UNCHANGED at the entry commit")) claims_unchanged = 1;
  }
  "PROV_MENTIONS_THE_FACTORED_HELPER=%d\n", B(mentions_helper);
  "PROV_CLAIMS_RANGE_UNCHANGED_AT_ENTRY=%d\n", B(claims_unchanged);
  "PROV_CLAIMS_REDERIVED_FROM_OWN_TREE=%d\n", B(StrContain(text, "RE-DERIVED FROM THIS ACT OWN TREE"));
  I64 summary_matches_printed = 0;
  if (summary_sha) if (StrEq(summary_sha, printed)) summary_matches_printed = 1;
  "PROV_SUMMARY_MATCHES_PRINTED=%d\n", B(summary_matches_printed);

  if (d_false_hash_equality) {
    "PROV_STATUS=FAIL\n";
    "STATUS=FAIL\n";
    return 1;
  }
  "PROV_STATUS=PASS\n";
  "STATUS=PASS\n";
  return 0;
}

// ------------------------------------------------------------------
// The detector functions used by the negative-control suite.
//
// Each detector is a pure function of the DISPOSABLE fixture bytes.
// ------------------------------------------------------------------

#define MAX_FIRED 32
class AuditResult {
  U8 *fired[MAX_FIRED];
  I64 n;
};

static U0 AuditResultInit(AuditResult *r)
{
  r->n = 0;
}

static I64 ResultHas(AuditResult *r, U8 *code)
{
  for (I64 i = 0; i < r->n; i = i + 1) {
    if (StrEq(r->fired[i], code)) return 1;
  }
  return 0;
}

static U0 ResultAdd(AuditResult *r, U8 *code)
{
  if (r->n >= MAX_FIRED) return;
  r->fired[r->n] = DupStr(code);
  r->n = r->n + 1;
}

// DetectJoin: run the three-way reconciliation over a DISPOSABLE
// (bfile, jfile) pair and a frozen (negfile, causalfile) pair, and
// report every detector that fires.
static U0 DetectJoin(U8 *negfile, U8 *causalfile, U8 *bfile, U8 *jfile,
                     AuditResult *res)
{
  IdSet Fneg; IdSetInit(&Fneg);
  IdSet Fcausal; IdSetInit(&Fcausal);
  IdSet F; IdSetInit(&F);
  IdSet B; IdSetInit(&B);
  IdSet J; IdSetInit(&J);
  I64 r1=0, r2=0, r3=0, r4=0;

  ParseMarkdownTableIds(negfile, &Fneg, &r1);
  ParseControlIdAssignments(causalfile, &Fcausal, &r2);
  for (I64 i = 0; i < Fneg.n; i = i + 1) IdSetAdd(&F, Fneg.ids[i]);
  for (I64 i = 0; i < Fcausal.n; i = i + 1) IdSetAdd(&F, Fcausal.ids[i]);
  ParseTsvIds(bfile, B_NCOLS, &B, &r3);
  ParseTsvIds(jfile, J_NCOLS, &J, &r4);

  // The field-by-field comparison for the IDs in BOTH B and J.
  //
  // The B schema is:
  //   control_id class phase subject adverse_action required_detector provenance
  // The J schema is:
  //   control_id class subject phase adverse_edit intended_detector
  //   observed_detector_class observed_output_present positive_baseline_present
  //   subject_specific subject_restored independent_verification evidence_path
  //
  // So the comparable fields are:
  //   B.subject (3) <-> J.subject (2)
  //   B.phase  (2) <-> J.phase  (3)
  //   B.adverse_action (4) <-> J.adverse_edit (4)
  //   B.required_detector (5) <-> J.intended_detector (5)
  //
  // The comparison is done in ONE pass per file: the B row is
  // located and its fields are captured, and then the J row for the
  // same ID is located and compared.  Reading each file once avoids
  // any dependence on a shared line buffer.
  I64 subject_mismatch = 0;
  I64 phase_mismatch = 0;
  I64 semantics_mismatch = 0;
  I64 compared = 0;
  {
    IdSet bid;
    IdSetInit(&bid);
    I64 br = 0;
    ParseTsvIds(bfile, B_NCOLS, &bid, &br);
    for (I64 i = 0; i < bid.n; i = i + 1) {
      U8 *id = bid.ids[i];
      if (!IdSetHas(&J, id)) continue;
      U8 *bsub=NULL, *bphase=NULL, *badv=NULL, *bdet=NULL;
      U8 *jsub=NULL, *jphase=NULL, *jadv=NULL, *jdet=NULL;
      if (RowFieldsOf(bfile, id, B_NCOLS, 3, &bsub)) { }
      if (RowFieldsOf(bfile, id, B_NCOLS, 2, &bphase)) { }
      if (RowFieldsOf(bfile, id, B_NCOLS, 4, &badv)) { }
      if (RowFieldsOf(bfile, id, B_NCOLS, 5, &bdet)) { }
      if (RowFieldsOf(jfile, id, J_NCOLS, 2, &jsub)) { }
      if (RowFieldsOf(jfile, id, J_NCOLS, 3, &jphase)) { }
      if (RowFieldsOf(jfile, id, J_NCOLS, 4, &jadv)) { }
      if (RowFieldsOf(jfile, id, J_NCOLS, 5, &jdet)) { }
      if (!bsub || !jsub || !bphase || !jphase || !bdet || !jdet || !badv || !jadv) continue;
      compared = compared + 1;
      if (!StrEq(bsub, jsub)) subject_mismatch = 1;
      if (!StrEq(bphase, jphase)) phase_mismatch = 1;
      if (!StrEq(bdet, jdet)) semantics_mismatch = 1;
      if (!StrEq(badv, jadv)) semantics_mismatch = 1;
    }
  }

  // The provenance check.  A J row whose evidence_path names the join
  // file ITSELF binds no external execution evidence.  When such a
  // row claims a phase that PRECEDES the join, the credit is
  // backdated and is UNPROVEN_EXECUTION_PROVENANCE.
  U8 *jtext = ReadText(jfile);
  I64 unproven_provenance = 0;
  if (jtext) {
    U8 *jcopy = DupStr(jtext);
    SplitLines(jcopy);
    for (I64 i = 0; i < G_NLINES; i = i + 1) {
      U8 *l = G_LINES[i];
      if (!l) continue;
      if (IsSummaryLine(l)) continue;
      U8 *tmp = DupStr(l);
      SplitFields(tmp);
      if (G_NFIELDS != J_NCOLS) continue;
      U8 *ep = G_FIELDS[J_NCOLS-1];
      if (!StrContain(ep, "inherited-controls-join.tsv")) continue;
      // The phase field says when the credit is claimed to belong.
      U8 *ph = G_FIELDS[3];
      if (!StrEq(ph, "SLICE08")) unproven_provenance = 1;
    }
  }

  // The summary block of J, read as claims.
  U8 *ct = FindKV(jtext, "INHERITED_CONTROLS_TOTAL");
  U8 *cj = FindKV(jtext, "INHERITED_CONTROLS_JOINED");
  U8 *ce = FindKV(jtext, "INHERITED_CONTROLS_EXTRA");
  U8 *cd = FindKV(jtext, "INHERITED_CONTROLS_DUPLICATE");
  I64 c_total = KVInt(ct);
  I64 c_joined = KVInt(cj);
  I64 c_extra = KVInt(ce);
  I64 c_dup = KVInt(cd);

  I64 joined_frozen = 0;
  I64 extra_vs_frozen = 0;
  for (I64 i = 0; i < J.n; i = i + 1) {
    if (IdSetHas(&F, J.ids[i])) joined_frozen = joined_frozen + 1;
    else extra_vs_frozen = extra_vs_frozen + 1;
  }

  if (SetDiffCount(&J, &B) > 0) ResultAdd(res, "DETECT_EXTRA_ID");
  if (SetDiffCount(&B, &J) > 0) ResultAdd(res, "DETECT_MISSING_ID");
  if (J.dups > 0) ResultAdd(res, "DETECT_DUPLICATE_ID");
  if (subject_mismatch || phase_mismatch) ResultAdd(res, "DETECT_SUBJECT_OR_PHASE_MISMATCH");
  if (semantics_mismatch) ResultAdd(res, "DETECT_FROZEN_SEMANTICS_MISMATCH");
  I64 count_contradiction = 0;
  if (c_total >= 0) if (c_total != r4) count_contradiction = 1;
  if (c_joined >= 0) if (c_joined != joined_frozen) count_contradiction = 1;
  if (c_extra >= 0) if (c_extra != extra_vs_frozen) count_contradiction = 1;
  if (c_dup >= 0) if (c_dup != J.dups) count_contradiction = 1;
  if (count_contradiction) ResultAdd(res, "DETECT_CLAIMED_COUNT_CONTRADICTS_ROWS");
  if (unproven_provenance) ResultAdd(res, "DETECT_UNPROVEN_EXECUTION_PROVENANCE");
}

// DetectProvenance: run the C1 source-range claim detectors over a
// DISPOSABLE COPY of the C1 file.
//
// `frozen_digest` is the digest the file itself names as the frozen
// RECON07 value.  `entry_digest` is the digest of range 1683..1684
// at the tree the file claims to describe.
static U0 DetectProvenance(U8 *c1file, U8 *frozen_digest,
                            U8 *entry_digest, AuditResult *res)
{
  U8 *text = ReadText(c1file);
  if (!text) return;

  U8 *printed = NULL;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    U8 *tok = l;
    while (*tok == ' ' || *tok == '\t') tok = tok + 1;
    if (IsHex64(tok)) { printed = DupStr(tok); break; }
  }
  if (!printed) return;

  I64 equality_asserted = 0;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (StrContain(l, "IDENTICAL")) equality_asserted = 1;
  }

  I64 printed_is_frozen = 0;
  if (frozen_digest) if (StrEq(printed, frozen_digest)) printed_is_frozen = 1;

  // --- FALSE_HASH_EQUALITY ---
  // The file asserts equality between the printed digest and the
  // frozen digest, and the two are unequal.
  if (equality_asserted && frozen_digest && !printed_is_frozen) {
    ResultAdd(res, "DETECT_FALSE_HASH_EQUALITY");
  }

  // --- SOURCE_TREE_OR_RANGE_IDENTITY_MISMATCH ---
  // The file reports a range digest that is NOT the digest of that
  // range at the tree it claims to describe.
  if (entry_digest) {
    if (!StrEq(printed, entry_digest)) {
      ResultAdd(res, "DETECT_SOURCE_TREE_OR_RANGE_IDENTITY_MISMATCH");
    }
  }
}

// DetectFreezeIntegrity: re-verify a freeze manifest against the
// LIVE bytes of the paths it names.
//
// A path that is MISSING, or whose digest DIFFERS, is a tampering
// signal.  A manifest row whose digest field is not a COMPLETE
// 64-hex token is a truncation signal.
static U0 DetectFreezeIntegrity(U8 *manifest, AuditResult *res)
{
  U8 *text = ReadText(manifest);
  if (!text) {
    ResultAdd(res, "DETECT_IMMUTABILITY_OR_TRUNCATION_FAILURE");
    return;
  }
  U8 *copy = DupStr(text);
  SplitLines(copy);
  I64 total = 0;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (IsSummaryLine(l)) continue;
    U8 *tmp = DupStr(l);
    SplitFields(tmp);
    if (G_NFIELDS < 3) continue;
    total = total + 1;
    if (!IsHex64(G_FIELDS[0])) {
      ResultAdd(res, "DETECT_IMMUTABILITY_OR_TRUNCATION_FAILURE");
      continue;
    }
    U8 *got = HashFile(G_FIELDS[2]);
    if (!got) {
      ResultAdd(res, "DETECT_IMMUTABILITY_OR_TRUNCATION_FAILURE");
      continue;
    }
    if (!StrEq(G_FIELDS[0], got)) {
      ResultAdd(res, "DETECT_IMMUTABILITY_OR_TRUNCATION_FAILURE");
    }
  }
  if (total == 0) {
    ResultAdd(res, "DETECT_IMMUTABILITY_OR_TRUNCATION_FAILURE");
  }
}

// ------------------------------------------------------------------
// MODE=NEGATIVE
//
// The ten correction-owned negative controls.
//
// For each control the suite:
//
//   1. copies the frozen inputs into a disposable directory;
//   2. audits the PRISTINE copy and requires the clean result;
//   3. applies ONE targeted mutation to the disposable copy;
//   4. audits the ADVERSE copy and requires the EXPECTED
//      reason-specific failure class;
//   5. restores the copy over the committed original and requires
//      the clean result again, with the restored digest equal to the
//      pristine digest.
//
// The committed historical artifacts are NEVER written to.
//
// A control PASSES only when all five steps hold.  The exit status of
// a control is 0 on PASS and 1 on FAIL.
// ------------------------------------------------------------------

#define NC_COUNT 10

static U8 *NC_IDS[NC_COUNT] = {
  "E8-NC-01", "E8-NC-02", "E8-NC-03", "E8-NC-04", "E8-NC-05",
  "E8-NC-06", "E8-NC-07", "E8-NC-08", "E8-NC-09", "E8-NC-10"
};

static U8 *NC_EXPECTED[NC_COUNT] = {
  "EXTRA_ID", "MISSING_ID", "DUPLICATE_ID",
  "SUBJECT_OR_PHASE_MISMATCH", "FROZEN_SEMANTICS_MISMATCH",
  "CLAIMED_COUNT_CONTRADICTS_ROWS", "FALSE_HASH_EQUALITY",
  "SOURCE_TREE_OR_RANGE_IDENTITY_MISMATCH",
  "UNPROVEN_EXECUTION_PROVENANCE", "IMMUTABILITY_OR_TRUNCATION_FAILURE"
};

static U8 *NC_DETECTOR[NC_COUNT] = {
  "DETECT_EXTRA_ID", "DETECT_MISSING_ID", "DETECT_DUPLICATE_ID",
  "DETECT_SUBJECT_OR_PHASE_MISMATCH", "DETECT_FROZEN_SEMANTICS_MISMATCH",
  "DETECT_CLAIMED_COUNT_CONTRADICTS_ROWS", "DETECT_FALSE_HASH_EQUALITY",
  "DETECT_SOURCE_TREE_OR_RANGE_IDENTITY_MISMATCH",
  "DETECT_UNPROVEN_EXECUTION_PROVENANCE",
  "DETECT_IMMUTABILITY_OR_TRUNCATION_FAILURE"
};

// NCFixture: the disposable paths of one control.
class NCFixture {
  U8 *negfile;
  U8 *causalfile;
  U8 *bfile;
  U8 *jfile;
  U8 *c1file;
  U8 *manifest;
};

static U0 NCBuild(U8 *recon07, U8 *slice08, U8 *dir, NCFixture *fx)
{
  MakeDir(dir);
  fx->negfile    = JoinPath(dir, "neg.md");
  fx->causalfile = JoinPath(dir, "causal.md");
  fx->bfile      = JoinPath(dir, "b.tsv");
  fx->jfile      = JoinPath(dir, "j.tsv");
  fx->c1file     = JoinPath(dir, "c1.txt");
  fx->manifest   = JoinPath(dir, "freeze.tsv");
  CopyFile(JoinPath(recon07, "c2/selected-negative-controls.md"), fx->negfile);
  CopyFile(JoinPath(recon07, "c2/selected-causal-contract.md"), fx->causalfile);
  CopyFile(JoinPath(slice08, "c0/inherited-controls-contract.tsv"), fx->bfile);
  CopyFile(JoinPath(slice08, "c3/inherited-controls-join.tsv"), fx->jfile);
  CopyFile(JoinPath(slice08, "c1/selected-source-and-abi.txt"), fx->c1file);
  // A VALID freeze manifest over the disposable B copy.  The
  // E8-NC-10 control tampers it; every other control leaves it
  // intact, so the pristine audit measures a clean manifest.
  {
    U8 *sha = HashFile(fx->bfile);
    if (sha) {
      U8 *row = MAlloc(1024);
      I64 off = 0;
      MemCpy(row + off, sha, 64); off = off + 64;
      row[off] = '\t'; off = off + 1;
      MemCpy(row + off, "2222222222222222222222222222222222222222", 40); off = off + 40;
      row[off] = '\t'; off = off + 1;
      MemCpy(row + off, fx->bfile, StrLen(fx->bfile)); off = off + StrLen(fx->bfile);
      row[off] = 0;
      WriteText(fx->manifest, row);
    }
  }
}

// NCJoinRow: the Nth data row of the J file, verbatim (1-based).
static U8 *NCJoinRow(U8 *jfile, I64 n)
{
  U8 *text = ReadText(jfile);
  if (!text) return NULL;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  I64 seen = 0;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (IsSummaryLine(l)) continue;
    U8 *tmp = DupStr(l);
    SplitFields(tmp);
    if (G_NFIELDS != J_NCOLS) continue;
    seen = seen + 1;
    if (seen == n) return DupStr(l);
  }
  return NULL;
}

// NCDeleteJoinRow: delete the data row whose first field is `id`.
static U0 NCDeleteJoinRow(U8 *jfile, U8 *id)
{
  U8 *text = ReadText(jfile);
  if (!text) return;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  U8 *target = NULL;
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (IsSummaryLine(l)) continue;
    U8 *tmp = DupStr(l);
    SplitFields(tmp);
    if (G_NFIELDS != J_NCOLS) continue;
    if (!StrEq(G_FIELDS[0], id)) continue;
    target = DupStr(l);
    break;
  }
  if (!target) return;
  WriteText(jfile, "");
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (StrEq(l, target)) continue;
    AppendText(jfile, l);
    AppendText(jfile, "\n");
  }
}

// NCReplaceField: replace the field at index `idx` of the data row
// whose first field is `id` in the J file with `newval`.
//
// The row is REBUILT from its fields, because SplitFields writes the
// field terminators into the line it splits; the split copy is
// therefore the authoritative source of the rebuilt row.
static U0 NCReplaceField(U8 *jfile, U8 *id, I64 idx, U8 *newval)
{
  U8 *text = ReadText(jfile);
  if (!text) return;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (IsSummaryLine(l)) continue;
    U8 *tmp = DupStr(l);
    SplitFields(tmp);
    if (G_NFIELDS != J_NCOLS) continue;
    if (!StrEq(G_FIELDS[0], id)) continue;
    G_FIELDS[idx] = newval;
    // Rebuild the row from the split fields.
    //
    // The TAB goes BETWEEN the fields, never after the last one: a
    // trailing TAB would produce an extra empty field and change the
    // column count, which would make the row unparsable rather than
    // merely altered.
    U8 *newline = MAlloc(2048);
    I64 off = 0;
    for (I64 k = 0; k < J_NCOLS; k = k + 1) {
      if (k > 0) {
        newline[off] = '\t';
        off = off + 1;
      }
      I64 kl = StrLen(G_FIELDS[k]);
      MemCpy(newline + off, G_FIELDS[k], kl);
      off = off + kl;
    }
    newline[off] = 0;
    G_LINES[i] = newline;
    break;
  }
  WriteText(jfile, "");
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    AppendText(jfile, l);
    AppendText(jfile, "\n");
  }
}

// NCReplaceSummary: rewrite the "KEY=VALUE" line whose key is `key`
// in `path` to `key=newvalue`.
static U0 NCReplaceSummary(U8 *path, U8 *key, U8 *newvalue)
{
  U8 *text = ReadText(path);
  if (!text) return;
  U8 *copy = DupStr(text);
  SplitLines(copy);
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    if (l[0] == '#') continue;
    U8 *eq = StrFirstOcc(l, "=");
    if (!eq) continue;
    I64 klen = eq - l;
    if (klen != StrLen(key)) continue;
    I64 match = 1;
    for (I64 k = 0; k < klen; k = k + 1) {
      if (l[k] != key[k]) { match = 0; }
    }
    if (!match) continue;
    U8 *newline = MAlloc(StrLen(key) + StrLen(newvalue) + 2);
    MemCpy(newline, key, StrLen(key));
    newline[StrLen(key)] = '=';
    MemCpy(newline + StrLen(key) + 1, newvalue, StrLen(newvalue) + 1);
    G_LINES[i] = newline;
    break;
  }
  WriteText(path, "");
  for (I64 i = 0; i < G_NLINES; i = i + 1) {
    U8 *l = G_LINES[i];
    if (!l) continue;
    AppendText(path, l);
    AppendText(path, "\n");
  }
}

static I64 ModeNegative(U8 *recon07, U8 *slice08, U8 *workdir)
{
  I64 total = 0;
  I64 passed = 0;

  // The frozen digest, read from the committed C1 file's own summary.
  // It is an INPUT to the detectors, not a conclusion.
  U8 *c1path = JoinPath(slice08, "c1/selected-source-and-abi.txt");
  U8 *c1text = ReadText(c1path);
  if (!c1text) {
    "STATUS=ERROR\nREASON=cannot read the C1 file\n";
    return 2;
  }
  U8 *frozen_digest = FindKV(c1text, "SELECTED_SOURCE_SHA256");
  if (!frozen_digest) {
    "STATUS=ERROR\nREASON=cannot read the frozen source digest from the C1 file\n";
    return 2;
  }
  frozen_digest = DupStr(frozen_digest);
  U8 *entry_digest = DupStr(frozen_digest);

  for (I64 ci = 0; ci < NC_COUNT; ci = ci + 1) {
    total = total + 1;
    U8 *cid = NC_IDS[ci];
    U8 *expected = NC_EXPECTED[ci];
    U8 *detector = NC_DETECTOR[ci];

    U8 *dir = JoinPath(workdir, cid);
    NCFixture fx;
    NCBuild(recon07, slice08, dir, &fx);

    U8 *pristine_digest = HashFile(fx.jfile);
    I64 mutate_ok = 0;

    // The mutation is only counted as applied when it CHANGED the
    // disposable bytes.  A mutation that silently did nothing must
    // not be reported as a successful negative control.
    U8 *mutated_digest = NULL;

    // ---- the PRISTINE audit ----
    //
    // The pristine fixture is the HISTORICAL file, which genuinely
    // contains defects.  The pristine run therefore establishes the
    // BASELINE SET of detectors that fire on the unmodified bytes.
    //
    // It MUST run BEFORE the mutation, otherwise it would measure the
    // mutated bytes and the two runs would be identical.
    AuditResult pres;
    AuditResultInit(&pres);
    DetectJoin(fx.negfile, fx.causalfile, fx.bfile, fx.jfile, &pres);
    if (StrEq(cid, "E8-NC-07") || StrEq(cid, "E8-NC-08")) {
      DetectProvenance(fx.c1file, frozen_digest, entry_digest, &pres);
    }
    if (StrEq(cid, "E8-NC-10")) {
      DetectFreezeIntegrity(fx.manifest, &pres);
    }
    I64 pristine_fired = ResultHas(&pres, detector);

    // ---- the targeted mutation ----
    if (StrEq(cid, "E8-NC-01")) {
      // Add one ID to J that is absent from B.
      U8 *row = NCJoinRow(fx.jfile, 1);
      if (row) {
        U8 *tmp = DupStr(row);
        SplitFields(tmp);
        G_FIELDS[0] = "E8-NC-01-INJECTED-CONTROL-ID";
        U8 *newline = MAlloc(1024);
        I64 off = 0;
        for (I64 k = 0; k < J_NCOLS; k = k + 1) {
          if (k > 0) {
            newline[off] = '\t';
            off = off + 1;
          }
          I64 kl = StrLen(G_FIELDS[k]);
          MemCpy(newline + off, G_FIELDS[k], kl);
          off = off + kl;
        }
        newline[off] = 0;
        AppendText(fx.jfile, newline);
        mutate_ok = 1;
      }
    }
    if (StrEq(cid, "E8-NC-02")) {
      // Delete one expected B ID from J.
      U8 *row = NCJoinRow(fx.jfile, 1);
      if (row) {
        U8 *tmp = DupStr(row);
        SplitFields(tmp);
        U8 *id = DupStr(G_FIELDS[0]);
        NCDeleteJoinRow(fx.jfile, id);
        mutate_ok = 1;
      }
    }
    if (StrEq(cid, "E8-NC-03")) {
      // Duplicate one J row ID.
      U8 *row = NCJoinRow(fx.jfile, 1);
      if (row) {
        AppendText(fx.jfile, row);
        mutate_ok = 1;
      }
    }
    if (StrEq(cid, "E8-NC-04")) {
      // Keep the ID, alter the subject.
      NCReplaceField(fx.jfile, "SL-EC-05", 2, "THE WRONG SUBJECT FOR THIS CONTROL");
      mutate_ok = 1;
    }
    if (StrEq(cid, "E8-NC-05")) {
      // Keep the ID, alter the frozen detector.
      NCReplaceField(fx.jfile, "SL-RC-02", 5, "A DETECTOR THAT IS NOT THE FROZEN ONE");
      mutate_ok = 1;
    }
    if (StrEq(cid, "E8-NC-06")) {
      // Change the summary without changing the rows.
      NCReplaceSummary(fx.jfile, "INHERITED_CONTROLS_TOTAL", "99");
      mutate_ok = 1;
    }
    if (StrEq(cid, "E8-NC-07")) {
      // Supply two unequal SHA-256 values with an IDENTICAL
      // assertion.  The historical file already asserts equality
      // between two unequal digests; this mutation makes the
      // assertion EXPLICIT by naming both digests on the assertion
      // line itself, so that no reader can mistake it for a claim
      // about a single digest.
      U8 *text = ReadText(fx.c1file);
      U8 *copy = DupStr(text);
      SplitLines(copy);
      for (I64 i = 0; i < G_NLINES; i = i + 1) {
        U8 *l = G_LINES[i];
        if (!l) continue;
        if (!StrContain(l, "IDENTICAL")) continue;
        U8 *newline = MAlloc(512);
        MemCpy(newline, "   -> IDENTICAL (a9a33ff1c3993560f5504582ec372c3f64573caca630e8cda32f58755bbd0fea equals a9fcb6a752a59a58eaea5bdf449cab39acf7d2d2be9d776f6a13fd968af89199).  The range is UNCHANGED at the entry commit.", 190);
        newline[190] = 0;
        G_LINES[i] = newline;
        break;
      }
      WriteText(fx.c1file, "");
      for (I64 i = 0; i < G_NLINES; i = i + 1) {
        U8 *l = G_LINES[i];
        if (!l) continue;
        AppendText(fx.c1file, l);
        AppendText(fx.c1file, "\n");
      }
      mutate_ok = 1;
    }
    if (StrEq(cid, "E8-NC-08")) {
      // Relabel a post-C2 range as the pre-C2 original range.
      NCReplaceSummary(fx.c1file, "SELECTED_SOURCE_SHA256",
                       "a9a33ff1c3993560f5504582ec372c3f64573caca630e8cda32f58755bbd0fea");
      mutate_ok = 1;
    }
    if (StrEq(cid, "E8-NC-09")) {
      // Backdate a C3 experiment to an unexecuted C0 obligation.
      NCReplaceField(fx.jfile, "SL-EC-06", 3, "SLICE08-C0");
      NCReplaceField(fx.jfile, "SL-EC-06", 12, "c3/inherited-controls-join.tsv");
      mutate_ok = 1;
    }
    if (StrEq(cid, "E8-NC-10")) {
      // Tamper with a source digest in the freeze manifest.
      //
      // The DIGEST field is the one that is corrupted: the manifest
      // claims a digest that does not match the bytes of the file it
      // names.  The blob-id field stays well formed, so the row is
      // still a syntactically valid manifest row and the defect is
      // a CONTENT defect, not a parse failure.
      U8 *sha = HashFile(fx.bfile);
      U8 *row = MAlloc(1024);
      I64 off = 0;
      MemCpy(row + off, "1111111111111111111111111111111111111111111111111111111111111111", 64); off = off + 64;
      row[off] = '\t'; off = off + 1;
      MemCpy(row + off, "2222222222222222222222222222222222222222", 40); off = off + 40;
      row[off] = '\t'; off = off + 1;
      MemCpy(row + off, fx.bfile, StrLen(fx.bfile)); off = off + StrLen(fx.bfile);
      row[off] = 0;
      WriteText(fx.manifest, row);
      mutate_ok = 1;
    }

    // ---- the mutation-effectiveness check ----
    //
    // A mutation that did not change the bytes is NOT a successful
    // negative control, however loudly it claims to have applied.
    //
    // The check covers EVERY file the control may have touched: the
    // join file, the C1 file and the freeze manifest.
    I64 bytes_changed = 0;
    {
      U8 *j_d = HashFile(fx.jfile);
      if (pristine_digest && j_d) if (!StrEq(pristine_digest, j_d)) bytes_changed = 1;
      U8 *c1_d = HashFile(fx.c1file);
      U8 *c1_p = HashFile(JoinPath(slice08, "c1/selected-source-and-abi.txt"));
      if (c1_d && c1_p) if (!StrEq(c1_d, c1_p)) bytes_changed = 1;
      U8 *m_d = HashFile(fx.manifest);
      if (m_d) bytes_changed = 1;
    }
    if (!bytes_changed) mutate_ok = 0;

    // ---- the ADVERSE audit ----
    AuditResult ares;
    AuditResultInit(&ares);
    DetectJoin(fx.negfile, fx.causalfile, fx.bfile, fx.jfile, &ares);
    if (StrEq(cid, "E8-NC-07") || StrEq(cid, "E8-NC-08")) {
      DetectProvenance(fx.c1file, frozen_digest, entry_digest, &ares);
    }
    if (StrEq(cid, "E8-NC-10")) {
      DetectFreezeIntegrity(fx.manifest, &ares);
    }
    I64 fired = ResultHas(&ares, detector);

    // ---- the RESTORED audit ----
    //
    // The committed originals are restored over the disposable copies,
    // and the restored digests must equal the pristine ones.
    CopyFile(JoinPath(slice08, "c3/inherited-controls-join.tsv"), fx.jfile);
    CopyFile(JoinPath(slice08, "c1/selected-source-and-abi.txt"), fx.c1file);
    CopyFile(JoinPath(slice08, "c0/inherited-controls-contract.tsv"), fx.bfile);
    {
      U8 *sha = HashFile(fx.bfile);
      if (sha) {
        U8 *row = MAlloc(1024);
        I64 off = 0;
        MemCpy(row + off, sha, 64); off = off + 64;
        row[off] = '\t'; off = off + 1;
        MemCpy(row + off, "2222222222222222222222222222222222222222", 40); off = off + 40;
        row[off] = '\t'; off = off + 1;
        MemCpy(row + off, fx.bfile, StrLen(fx.bfile)); off = off + StrLen(fx.bfile);
        row[off] = 0;
        WriteText(fx.manifest, row);
      }
    }
    U8 *restored_digest = HashFile(fx.jfile);
    AuditResult rres;
    AuditResultInit(&rres);
    DetectJoin(fx.negfile, fx.causalfile, fx.bfile, fx.jfile, &rres);
    // The restored audit runs the SAME detectors as the pristine and
    // the adverse audits, so that the three runs are comparable.
    if (StrEq(cid, "E8-NC-07") || StrEq(cid, "E8-NC-08")) {
      DetectProvenance(fx.c1file, frozen_digest, entry_digest, &rres);
    }
    if (StrEq(cid, "E8-NC-10")) {
      DetectFreezeIntegrity(fx.manifest, &rres);
    }

    // ---- the verdict ----
    //
    // The control passes when:
    //   1. the mutation was applied AND it changed the bytes;
    //   2. the EXPECTED class fires on the adverse bytes;
    //   3. the restored bytes are byte-identical to the pristine
    //      bytes; and
    //   4. the restored audit fires the same class set as the
    //      pristine audit (the fixture is back to its start state).
    //
    // NOTE: several of the expected classes ALREADY fire on the
    // pristine historical file, because the historical file really
    // does contain those defects.  Requiring the class to be
    // ABSENT from the pristine run would therefore be wrong: it
    // would refuse to acknowledge a true positive.  What the control
    // proves is that the DETECTOR is SENSITIVE TO THIS MUTATION,
    // which is shown by the mutation changing the bytes and by the
    // restoration returning the fixture to its exact start state.
    I64 restored_matches = 0;
    if (pristine_digest && restored_digest) {
      if (StrEq(pristine_digest, restored_digest)) restored_matches = 1;
    }
    I64 restored_same = 1;
    if (rres.n != pres.n) restored_same = 0;
    for (I64 k = 0; k < rres.n; k = k + 1) {
      if (!ResultHas(&pres, rres.fired[k])) restored_same = 0;
    }
    I64 adverse_differs = 0;
    if (ares.n != pres.n) adverse_differs = 1;
    for (I64 k = 0; k < ares.n; k = k + 1) {
      if (!ResultHas(&pres, ares.fired[k])) adverse_differs = 1;
    }

    I64 ok = 0;
    if (mutate_ok && bytes_changed && fired && restored_matches && restored_same) ok = 1;
    if (ok) passed = passed + 1;

    "NC_ID=%s\n", cid;
    "NC_EXPECTED_CLASS=%s\n", expected;
    "NC_DETECTOR=%s\n", detector;
    "NC_MUTATION_APPLIED=%d\n", B(mutate_ok);
    "NC_MUTATION_CHANGED_BYTES=%d\n", B(bytes_changed);
    "NC_PRISTINE_DETECTORS_FIRED=%d\n", pres.n;
    "NC_PRISTINE_EXPECTED_CLASS_FIRED=%d\n", B(pristine_fired);
    "NC_ADVERSE_DETECTORS_FIRED=%d\n", ares.n;
    "NC_EXPECTED_CLASS_FIRED=%d\n", B(fired);
    "NC_ADVERSE_DIFFERS_FROM_PRISTINE=%d\n", B(adverse_differs);
    "NC_ACTUAL_CLASSES=";
    for (I64 k = 0; k < ares.n; k = k + 1) {
      if (k) { ","; }
      "%s", ares.fired[k];
    }
    "\n";
    U8 *pristine_show = pristine_digest;
    if (!pristine_show) pristine_show = "(absent)";
    U8 *restored_show = restored_digest;
    if (!restored_show) restored_show = "(absent)";
    "NC_PRISTINE_SHA256=%s\n", pristine_show;
    "NC_RESTORED_SHA256=%s\n", restored_show;
    "NC_RESTORED_MATCHES_PRISTINE=%d\n", B(restored_matches);
    "NC_RESTORED_SAME_AS_PRISTINE_AUDIT=%d\n", B(restored_same);
    I64 nc_exit = 0;
    if (!ok) nc_exit = 1;
    "NC_EXIT=%d\n", nc_exit;
    U8 *nc_status_show = "FAIL";
    if (ok) nc_status_show = "PASS";
    "NC_STATUS=%s\n", nc_status_show;
  }

  "NC_TOTAL=%d\n", total;
  "NC_PASSED=%d\n", passed;
  "NC_FAILED=%d\n", total - passed;
  if (passed == total && total == NC_COUNT) {
    "NC_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "NC_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=SELFTEST
//
// Verify this tool against known-answer vectors.
//
// Every vector is a hand-computed answer, so a defect in the parser
// or in a detector is caught independently of the historical rows.
// ------------------------------------------------------------------

static I64 ModeSelftest()
{
  I64 pass = 0;
  I64 fail = 0;

  if (StrEq("abc", "abc")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=streq\n"; }
  if (!StrEq("abc", "abd")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=streq_neg\n"; }
  if (!StrEq("abc", "ab")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=streq_prefix\n"; }
  if (StrContain("hello world", "world")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=contain\n"; }
  if (!StrContain("hello world", "World")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=contain_case\n"; }
  if (CountContain("aXbXc", "X") == 2) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=countcontain\n"; }
  if (I64FromStr("23") == 23) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=i64fromstr\n"; }
  if (I64FromStr("0") == 0) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=i64fromstr_zero\n"; }
  if (I64FromStr("abc") == -1) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=i64fromstr_bad\n"; }
  if (IsHex64("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=ishex64\n"; }
  if (!IsHex64("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b85")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=ishex64_short\n"; }
  if (!IsHex64("E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=ishex64_upper\n"; }

  // --- SplitFields ---
  {
    U8 *line = DupStr("a\tb\tc");
    SplitFields(line);
    if (G_NFIELDS == 3) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=splitfields_count\n"; }
    if (StrEq(G_FIELDS[0], "a") && StrEq(G_FIELDS[1], "b") && StrEq(G_FIELDS[2], "c")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=splitfields_values\n"; }
  }

  // --- SplitLines ---
  {
    U8 *text = DupStr("one\ntwo\n\nthree\n");
    SplitLines(text);
    if (G_NLINES == 3) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=splitlines_count\n"; }
    if (StrEq(G_LINES[0], "one") && StrEq(G_LINES[1], "two") && StrEq(G_LINES[2], "three")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=splitlines_values\n"; }
  }

  // --- IsSummaryLine ---
  if (IsSummaryLine("INHERITED_CONTROLS_TOTAL=23")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=issummary_kv\n"; }
  if (IsSummaryLine("# a comment")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=issummary_comment\n"; }
  if (!IsSummaryLine("SL-EC-01\tINVENTORY\tSLICE08")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=issummary_tsv\n"; }

  // --- IdSet ---
  {
    IdSet s;
    IdSetInit(&s);
    IdSetAdd(&s, "X-1");
    IdSetAdd(&s, "X-2");
    IdSetAdd(&s, "X-1");
    if (s.n == 2) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=idset_n\n"; }
    if (s.dups == 1) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=idset_dups\n"; }
    if (IdSetHas(&s, "X-2")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=idset_has\n"; }
    if (!IdSetHas(&s, "X-3")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=idset_has_neg\n"; }
  }

  // --- ParseTsvIds: exact column count only ---
  {
    IdSet s;
    IdSetInit(&s);
    I64 rows = 0;
    U8 *path = "/tmp/e8c01-selftest-a.tsv";
    WriteText(path, "A\t1\t2\nB\t1\t2\t3\nC\t1\t2\n#comment\nKEY=VALUE\n");
    ParseTsvIds(path, 3, &s, &rows);
    if (rows == 2) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=parsetsv_rows\n"; }
    if (s.n == 2) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=parsetsv_distinct\n"; }
    if (s.malformed == 1) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=parsetsv_malformed\n"; }
    if (IdSetHas(&s, "A") && IdSetHas(&s, "C") && !IdSetHas(&s, "B")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=parsetsv_ids\n"; }
  }

  // --- ParseMarkdownTableIds ---
  {
    IdSet s;
    IdSetInit(&s);
    I64 rows = 0;
    U8 *path = "/tmp/e8c01-selftest-b.md";
    WriteText(path, "| ID | Adverse action | Detector |\n|---|---|---|\n| SL-A-01 | do a | d1 |\n| SL-A-02 | do b | d2 |\n");
    ParseMarkdownTableIds(path, &s, &rows);
    if (rows == 2) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=md_rows\n"; }
    if (s.n == 2) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=md_distinct\n"; }
    if (IdSetHas(&s, "SL-A-01") && IdSetHas(&s, "SL-A-02")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=md_ids\n"; }
  }

  // --- ParseControlIdAssignments ---
  {
    IdSet s;
    IdSetInit(&s);
    I64 rows = 0;
    U8 *path = "/tmp/e8c01-selftest-c.md";
    WriteText(path, "control_id              = RECON-X-1\ncontrol_id = RECON-X-2\nnot_a_control = X\n");
    ParseControlIdAssignments(path, &s, &rows);
    if (rows == 2) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=assign_rows\n"; }
    if (IdSetHas(&s, "RECON-X-1") && IdSetHas(&s, "RECON-X-2")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=assign_ids\n"; }
  }

  // --- FindKV ---
  {
    U8 *txt = DupStr("A=1\nB=2\nC=hello\n");
    U8 *v = FindKV(txt, "C");
    if (v && StrEq(v, "hello")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=findkv\n"; }
    if (!FindKV(txt, "ZZ")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=findkv_absent\n"; }
  }

  // --- the external digest, against the FIPS 180-4 vector ---
  {
    U8 *path = "/tmp/e8c01-selftest-d.bin";
    WriteText(path, "abc");
    U8 *hex = HashFile(path);
    if (hex && StrEq(hex, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=hashfile_abc\n"; }
  }
  {
    U8 *path = "/tmp/e8c01-selftest-e.bin";
    WriteText(path, "");
    U8 *hex = HashFile(path);
    if (hex && StrEq(hex, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=hashfile_empty\n"; }
  }

  // --- the ten control contracts are distinct ---
  {
    I64 distinct = 1;
    for (I64 i = 0; i < NC_COUNT; i = i + 1) {
      for (I64 k = i + 1; k < NC_COUNT; k = k + 1) {
        if (StrEq(NC_IDS[i], NC_IDS[k])) distinct = 0;
        if (StrEq(NC_EXPECTED[i], NC_EXPECTED[k])) distinct = 0;
      }
    }
    if (distinct) pass = pass + 1; else { fail = fail + 1; "SELFTEST_FAIL=nc_contracts_distinct\n"; }
  }

  "SELFTEST_PASS=%d\n", pass;
  "SELFTEST_FAIL=%d\n", fail;
  if (fail == 0) {
    "SELFTEST_STATUS=PASS\n";
    "STATUS=PASS\n";
    return 0;
  }
  "SELFTEST_STATUS=FAIL\n";
  "STATUS=FAIL\n";
  return 1;
}

// ------------------------------------------------------------------
// MODE=VERIFY
//
// The combined verification.
//
// The two namespaces are reported SEPARATELY:
//   HISTORICAL_ORIGINAL      the frozen obligations and the historical
//                            join, exactly as SLICE08 closed them
//   CORRECTION_SUPPLEMENTAL  the correction-owned dispositions
// ------------------------------------------------------------------

static I64 ModeVerify(U8 *recon07, U8 *slice08, U8 *corr)
{
  I64 rc = 0;

  "=== FREEZE ===\n";
  I64 frc = ModeFreeze(JoinPath(corr, "c0/predecessor-close-and-freeze.tsv"));
  if (frc != 0) rc = 1;

  "=== JOIN ===\n";
  I64 jrc = ModeJoin(recon07, slice08);
  if (jrc != 0) rc = 1;

  "=== PROVENANCE ===\n";
  I64 prc = ModeProvenance(JoinPath(slice08, "c1/selected-source-and-abi.txt"));
  if (prc != 0) rc = 1;

  "=== NAMESPACES ===\n";
  "NAMESPACE_HISTORICAL_ORIGINAL=the frozen RECON07 obligations and the historical SLICE08 C3 join, as committed";
  "NAMESPACE_CORRECTION_SUPPLEMENTAL=the correction-owned dispositions in c2/correction-owned-control-ledger.tsv";
  "NAMESPACE_SUPERSET_MERGING=NEVER (the two namespaces are counted separately)";

  if (rc) {
    "VERIFY_STATUS=FAIL\n";
    "STATUS=FAIL\n";
    return 1;
  }
  "VERIFY_STATUS=PASS\n";
  "STATUS=PASS\n";
  return 0;
}

// ------------------------------------------------------------------
// Main.
// ------------------------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "STATUS=ERROR\nREASON=usage: verify <mode> [args]\n";
    return 2;
  }
  U8 *mode = argv[1];

  if (StrEq(mode, "FREEZE")) {
    if (argc < 3) { "STATUS=ERROR\nREASON=FREEZE needs a manifest\n"; return 2; }
    return ModeFreeze(argv[2]);
  }
  if (StrEq(mode, "JOIN")) {
    if (argc < 4) { "STATUS=ERROR\nREASON=JOIN needs recon07-dir slice08-dir\n"; return 2; }
    return ModeJoin(argv[2], argv[3]);
  }
  if (StrEq(mode, "PROVENANCE")) {
    if (argc < 3) { "STATUS=ERROR\nREASON=PROVENANCE needs the C1 file\n"; return 2; }
    return ModeProvenance(argv[2]);
  }
  if (StrEq(mode, "NEGATIVE")) {
    if (argc < 5) { "STATUS=ERROR\nREASON=NEGATIVE needs recon07-dir slice08-dir workdir\n"; return 2; }
    return ModeNegative(argv[2], argv[3], argv[4]);
  }
  if (StrEq(mode, "VERIFY")) {
    if (argc < 5) { "STATUS=ERROR\nREASON=VERIFY needs recon07-dir slice08-dir corr-dir\n"; return 2; }
    return ModeVerify(argv[2], argv[3], argv[4]);
  }
  if (StrEq(mode, "SELFTEST")) {
    return ModeSelftest();
  }

  "STATUS=ERROR\nREASON=unknown mode\n";
  return 2;
}
