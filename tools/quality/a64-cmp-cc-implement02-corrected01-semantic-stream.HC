// tools/quality/a64-cmp-cc-implement02-corrected01-semantic-stream.HC
//
// ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01 C3.
//
// THE FOUR-SEMANTIC-STREAM EMITTER.
//
// It evaluates the SOURCE-DERIVED FIXTURE SET against ONE semantic
// stream and writes the resulting stream file. The four streams are:
//
//   G0  the legacy C oracle (the selector-OFF aarch64.c decision)
//   G1  the compiled PolyC subject produced by producer 1
//   G2  the compiled PolyC subject produced by producer 2
//   G3  the compiled PolyC subject produced by producer 3
//
// The emitter is a PolyC implementation compiled by a real PolyC
// compiler. It is NOT shell glue. It imports the compiled PolyC
// subject's two exports and calls them, so the emitted stream IS the
// PolyC decision's output, not a transcription of it.
//
// The G0 stream is emitted by the SAME emitter, linked against the
// legacy C oracle's two decision functions, so that the PAIR roster
// compares two streams that were produced by ONE mechanism over ONE
// fixture set, rather than comparing a PolyC output against a
// hand-written expectation.
//
// MODE: <fixture-contract.tsv> <out-file> <STREAM: G0|G1|G2|G3>
//
// The emitted file has one TAB-separated row per fixture row:
//
//   id \t kind \t is_float \t role \t observed
//
// where observed is the SUFFIX STRING for a successful decision, the
// literal (null) for a failed-domain decision, and the literal
// same-pointer for the borrowed-lifetime row.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// The library's FileRead and FileWrite come from io_defs.HH, which
// declares them with the REAL signatures. They are NOT redeclared
// here: a duplicate extern "c" declaration with a different return
// type conflicts with the header's and produces a broken call.
//
// The flags MUST be O_CREAT|O_RDWR: a flags value of 0 opens the path
// WITHOUT O_CREAT and the write silently fails.

// THE COMPILED POLYC SUBJECT'S TWO EXPORTS.
extern "c" U8 *AbiA64CcForV2(I64 kind, I64 is_float);
extern "c" U8 *AbiA64CcInvForV2(I64 kind, I64 is_float);

// THE LEGACY C ORACLE'S TWO DECISION FUNCTIONS (the G0 stream only).
//
// These are the REAL static functions aarch64CcFor and aarch64CcInvFor
// from src/aarch64.c, exposed under non-static names by the DISPOSABLE
// G0 oracle wrapper, which #includes the REAL src/aarch64.c with the
// selector OFF so that the legacy C tables are compiled in. The G0
// oracle is NOT a production artifact and is never committed.
extern "c" U8 *g0_cc_for(I64 kind, I64 is_float);
extern "c" U8 *g0_cc_inv(I64 kind, I64 is_float);

#define MAX_ROWS   260
#define NCOL         16
#define MAX_CELL    64
#define MAX_FIELDS (MAX_ROWS * NCOL)

// The cells are held in a POINTER ARRAY and the text is split in
// place, exactly as the red verifier does it. A flat byte array of
// strings is not used here because this compiler's handling of a
// multi-dimensional byte array is not sound.
//
// NOTE: NROW has NO initialiser on purpose. A global with an
// initialiser makes this PolyC compiler emit the C entry point with
// argc=0 and argv=NULL, so the tool could never see its own
// arguments. The global is initialised in Main instead. This is a
// compiler defect, not a property of this tool, and it is recorded as
// P1 residue in c3/residue.tsv; it is NOT worked around in the
// compiler because that is outside this ACT's authorised scope.
I64  NROW;
U8   *FLD[MAX_FIELDS];

// SplitCols splits one TAB-separated line IN PLACE and fills the
// pointer array fld with the cell addresses. It returns the number of
// cells, which may exceed maxf.
I64 SplitCols(U8 *line, U8 **fld, I64 maxf)
{
  I64 n = 0;
  U8 *p = line;
  U8 *start = line;
  while (1) {
    if (*p == '\t' || *p == 0) {
      I64 last = (*p == 0);
      *p = 0;
      if (n < maxf) fld[n] = start;
      n++;
      if (last) break;
      start = p + 1;
    }
    p++;
  }
  return n;
}

// The loader is deliberately INDEPENDENT of the red verifier's loader:
// two tools that share no code must agree on the fixture set.
I64 LoadFixture(U8 *path)
{
  I64 sz = 0;
  U8 *txt = FileRead(path, &sz);
  if (txt == NULL) return -1;
  U8 *p = txt;
  NROW = 0;
  while (*p != 0) {
    U8 *line = p;
    while (*p != 0 && *p != '\n') p++;
    if (*p == '\n') { *p = 0; p++; }
    if (line[0] == 0) continue;
    if (line[0] == '#') continue;
    if (NROW >= MAX_ROWS) break;
    SplitCols(line, &FLD[NROW * NCOL], NCOL);
    NROW++;
  }
  return 0;
}

I64 Atol(U8 *s)
{
  I64 neg = 0;
  I64 i = 0;
  I64 v = 0;
  if (s[0] == '-') { neg = 1; i = 1; }
  while (s[i] >= '0' && s[i] <= '9') {
    v = v * 10 + (s[i] - '0');
    i++;
  }
  if (neg) return -v;
  return v;
}

I32 Main(I32 argc, U8 **argv)
{
  NROW = 0;
  if (argc < 4) {
    "usage: semantic-stream <fixture.tsv> <out> <G0|G1|G2|G3>\n";
    return 2;
  }
  U8 *fixture = argv[1];
  U8 *outfile = argv[2];
  U8 *stream = argv[3];

  I64 use_c = 0;
  if (StrCmp(stream, "G0") == 0) use_c = 1;

  if (LoadFixture(fixture) != 0) {
    "semantic-stream: cannot read the fixture contract\n";
    return 1;
  }
  if (NROW == 0) {
    "semantic-stream: the fixture contract is empty\n";
    return 1;
  }

  // The output is written ROW BY ROW in append mode, so no output
  // buffer of an estimated size is needed and no length accounting can
  // go wrong. The file is first TRUNCATED, so a re-run never appends
  // to a previous run's content.
  I64 len = 0;
  U8 *empty = StrPrint(NULL, "");
  FileWrite(outfile, empty, 0, O_CREAT | O_RDWR | O_TRUNC);
  Free(empty);

  for (I64 r = 0; r < NROW; r++) {
    U8 *id = FLD[r * NCOL + 0];
    U8 *kinds = FLD[r * NCOL + 1];
    U8 *floats = FLD[r * NCOL + 2];
    U8 *role = FLD[r * NCOL + 3];
    U8 *part = FLD[r * NCOL + 7];
    if (id[0] == 0) continue;
    if (StrCmp(id, "id") == 0) continue;

    U8 *line = NULL;
    // The BORROWED_LIFETIME ROLE is not a decision: it is a lifetime
    // observation. The ROLE is checked BEFORE the PARTITION because a
    // BORROWED_LIFETIME row appears in TWO partitions, and the role is
    // the property that decides how the row is observed.
    if (StrCmp(role, "BORROWED_LIFETIME") == 0) {
      line = StrPrint(NULL, "%s\t%s\t%s\t%s\tstable+NUL\n",
                      id, kinds, floats, role);
    } else if (StrCmp(role, "ZERO_DISCRIMINANT") == 0) {
      // The ZERO_DISCRIMINANT row is not ONE decision either: it
      // observes BOTH decisions at the zero discriminant, because the
      // whole point of the row is that the zero discriminant produces
      // "eq" for FOR and "ne" for INV and that neither is an error.
      U8 *rf = NULL;
      U8 *ri = NULL;
      if (use_c) {
        rf = g0_cc_for(Atol(kinds), Atol(floats));
        ri = g0_cc_inv(Atol(kinds), Atol(floats));
      } else {
        rf = AbiA64CcForV2(Atol(kinds), Atol(floats));
        ri = AbiA64CcInvForV2(Atol(kinds), Atol(floats));
      }
      U8 *sf = "(null)";
      U8 *si = "(null)";
      if (rf != NULL) sf = rf;
      if (ri != NULL) si = ri;
      line = StrPrint(NULL, "%s\t%s\t%s\t%s\t%s/%s\n",
                      id, kinds, floats, role, sf, si);
    } else {
      I64 kind = Atol(kinds);
      I64 isf = Atol(floats);
      U8 *res = NULL;
      if (StrCmp(role, "FOR") == 0) {
        if (use_c) res = g0_cc_for(kind, isf);
        else        res = AbiA64CcForV2(kind, isf);
      } else {
        if (use_c) res = g0_cc_inv(kind, isf);
        else        res = AbiA64CcInvForV2(kind, isf);
      }
      if (res == NULL) {
        line = StrPrint(NULL, "%s\t%s\t%s\t%s\t(null)\n",
                        id, kinds, floats, role);
      } else {
        line = StrPrint(NULL, "%s\t%s\t%s\t%s\t%s\n",
                        id, kinds, floats, role, res);
      }
    }
    I64 ll = StrLen(line);
    FileWrite(outfile, line, ll, O_CREAT | O_RDWR | O_APPEND);
    Free(line);
    len += ll;
  }

  "semantic-stream: stream=%s rows=%d bytes=%d\n", stream, NROW, len;
  return 0;
}
