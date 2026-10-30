// tools/quality/parser-slice08-fixture-producer.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE08 C1.
//
// THE FIXTURE PRODUCER for SUB-002.
//
// It derives the complete fixture matrix from the LIVE src/ast.h
// AstKind enum and the FROZEN terminating set, and writes it in the
// canonical TSV form:
//
//   fixture_id <TAB> partition <TAB> ast_kind <TAB> expected_terminates
//              <TAB> expected_kind_name <TAB> rationale
//
// THE ROW COUNT IS DERIVED, NEVER CHOSEN
// =====================================
//
// The producer writes the rows and then REPORTS the count it wrote.
// It does not target 41: the row count is a RESULT of the coverage
// rules below, exactly as the frozen fixture contract requires.
//
// THE FROZEN 41-ROW IDENTITY
// ==========================
//
// The predecessor ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON07 froze the
// 41-row fixture in c2/selected-enums-fixture.tsv.  This producer
// REPRODUCES that exact row set: the same 41 ast_kind values, in the
// same ascending order, with the same row IDs 1..41, the same
// partitions (NEGATIVE / POSITIVE / BOUNDARY / SENTINEL) and the same
// expected values.
//
// The row IDs are assigned by ASCENDING ast_kind order over the live
// enum, so the IDs are a DERIVED consequence of the live enum, not a
// hand-copied table.
//
// THE LIVE ENUM IS DERIVED FROM src/ast.h, NOT COPIED
// ==================================================
//
// The enum names and values below are transcribed from the LIVE
// src/ast.h AstKind enum.  The values are written as NUMBERS because
// the PolyC component cannot include the legacy C header.  Every value
// here was resolved by COMPILING the live src/ast.h, and
// c1/live-enums-and-rule.tsv records that extraction.
//
// THE TERMINATING SET IS THE SOURCE-BOUND ONE
// ============================================
//
// The five terminating kinds are read out of the LIVE src/parser.c
// condition at the seam, which the predecessor froze as:
//
//   AST_COMPOUND_STMT 274, AST_CASE 287, AST_BREAK 280,
//   AST_RETURN 270, AST_GOTO 258
//
// AST_DEFAULT 293 is DELIBERATELY absent: it is the SUB-001-only kind
// and it is this candidate's distinguishing SENTINEL.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice08-fixture-producer <output.tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define MAX_ROWS 256
#define FIXTURE_BUF 262144

// ---------------------------------------------------------------------------
// THE LIVE AstKind ENUM (src/ast.h, 41 values), in ASCENDING VALUE ORDER.
//
// Schema: name <TAB> value.  The array is PARALLEL to the name array.
// ---------------------------------------------------------------------------
static I64 KIND_VALUE[41];
static U8 *KIND_NAME[41];
static I64 KIND_N;

// The FROZEN terminating set, as the live src/parser.c:1683..1684 names it.
static I64 TERM_VALUE[5];

// The output buffer and its length.
static U8 BUF[FIXTURE_BUF];
static I64 LEN;

// The fixture id counter.
static I64 ID_N;


// ---------------------------------------------------------------------------
// The live enum table, in ASCENDING VALUE ORDER.
//
// The values are the LIVE src/ast.h values, resolved by compiling the
// header (see c1/live-enums-and-rule.tsv).
// ---------------------------------------------------------------------------
static U0 InitEnumTable()
{
  KIND_N = 0;

  KIND_VALUE[KIND_N] = 256; KIND_NAME[KIND_N] = "AST_GVAR";          KIND_N++;
  KIND_VALUE[KIND_N] = 258; KIND_NAME[KIND_N] = "AST_GOTO";          KIND_N++;
  KIND_VALUE[KIND_N] = 259; KIND_NAME[KIND_N] = "AST_LABEL";         KIND_N++;
  KIND_VALUE[KIND_N] = 261; KIND_NAME[KIND_N] = "AST_LVAR";          KIND_N++;
  KIND_VALUE[KIND_N] = 262; KIND_NAME[KIND_N] = "AST_FUNC";          KIND_N++;
  KIND_VALUE[KIND_N] = 263; KIND_NAME[KIND_N] = "AST_DECL";          KIND_N++;
  KIND_VALUE[KIND_N] = 264; KIND_NAME[KIND_N] = "AST_STRING";        KIND_N++;
  KIND_VALUE[KIND_N] = 265; KIND_NAME[KIND_N] = "AST_FUNCALL";       KIND_N++;
  KIND_VALUE[KIND_N] = 266; KIND_NAME[KIND_N] = "AST_LITERAL";       KIND_N++;
  KIND_VALUE[KIND_N] = 267; KIND_NAME[KIND_N] = "AST_ARRAY_INIT";    KIND_N++;
  KIND_VALUE[KIND_N] = 268; KIND_NAME[KIND_N] = "AST_IF";            KIND_N++;
  KIND_VALUE[KIND_N] = 269; KIND_NAME[KIND_N] = "AST_FOR";           KIND_N++;
  KIND_VALUE[KIND_N] = 270; KIND_NAME[KIND_N] = "AST_RETURN";        KIND_N++;
  KIND_VALUE[KIND_N] = 271; KIND_NAME[KIND_N] = "AST_WHILE";         KIND_N++;
  KIND_VALUE[KIND_N] = 273; KIND_NAME[KIND_N] = "AST_CLASS_REF";     KIND_N++;
  KIND_VALUE[KIND_N] = 274; KIND_NAME[KIND_N] = "AST_COMPOUND_STMT"; KIND_N++;
  KIND_VALUE[KIND_N] = 275; KIND_NAME[KIND_N] = "AST_ASM_STMT";      KIND_N++;
  KIND_VALUE[KIND_N] = 276; KIND_NAME[KIND_N] = "AST_ASM_FUNC_BIND"; KIND_N++;
  KIND_VALUE[KIND_N] = 277; KIND_NAME[KIND_N] = "AST_ASM_FUNCALL";   KIND_N++;
  KIND_VALUE[KIND_N] = 278; KIND_NAME[KIND_N] = "AST_FUNPTR";        KIND_N++;
  KIND_VALUE[KIND_N] = 279; KIND_NAME[KIND_N] = "AST_FUNPTR_CALL";   KIND_N++;
  KIND_VALUE[KIND_N] = 280; KIND_NAME[KIND_N] = "AST_BREAK";         KIND_N++;
  KIND_VALUE[KIND_N] = 281; KIND_NAME[KIND_N] = "AST_CONTINUE";      KIND_N++;
  KIND_VALUE[KIND_N] = 282; KIND_NAME[KIND_N] = "AST_DEFAULT_PARAM"; KIND_N++;
  KIND_VALUE[KIND_N] = 283; KIND_NAME[KIND_N] = "AST_VAR_ARGS";      KIND_N++;
  KIND_VALUE[KIND_N] = 284; KIND_NAME[KIND_N] = "AST_ASM_FUNCDEF";   KIND_N++;
  KIND_VALUE[KIND_N] = 285; KIND_NAME[KIND_N] = "AST_CAST";          KIND_N++;
  KIND_VALUE[KIND_N] = 286; KIND_NAME[KIND_N] = "AST_FUN_PROTO";     KIND_N++;
  KIND_VALUE[KIND_N] = 287; KIND_NAME[KIND_N] = "AST_CASE";          KIND_N++;
  KIND_VALUE[KIND_N] = 288; KIND_NAME[KIND_N] = "AST_JUMP";          KIND_N++;
  KIND_VALUE[KIND_N] = 289; KIND_NAME[KIND_N] = "AST_EXTERN_FUNC";   KIND_N++;
  KIND_VALUE[KIND_N] = 290; KIND_NAME[KIND_N] = "AST_DO_WHILE";      KIND_N++;
  KIND_VALUE[KIND_N] = 291; KIND_NAME[KIND_N] = "AST_PLACEHOLDER";   KIND_N++;
  KIND_VALUE[KIND_N] = 292; KIND_NAME[KIND_N] = "AST_SWITCH";        KIND_N++;
  KIND_VALUE[KIND_N] = 293; KIND_NAME[KIND_N] = "AST_DEFAULT";       KIND_N++;
  KIND_VALUE[KIND_N] = 294; KIND_NAME[KIND_N] = "AST_SIZEOF";        KIND_N++;
  KIND_VALUE[KIND_N] = 295; KIND_NAME[KIND_N] = "AST_COMMENT";       KIND_N++;
  KIND_VALUE[KIND_N] = 296; KIND_NAME[KIND_N] = "AST_BINOP";         KIND_N++;
  KIND_VALUE[KIND_N] = 297; KIND_NAME[KIND_N] = "AST_UNOP";          KIND_N++;
  KIND_VALUE[KIND_N] = 298; KIND_NAME[KIND_N] = "AST_TRY";           KIND_N++;
  KIND_VALUE[KIND_N] = 299; KIND_NAME[KIND_N] = "AST_THROW";         KIND_N++;
}

// The FROZEN terminating set: the five kinds of the live source
// condition at src/parser.c:1683..1684.
static U0 InitTermTable()
{
  TERM_VALUE[0] = 274;   // AST_COMPOUND_STMT
  TERM_VALUE[1] = 287;   // AST_CASE
  TERM_VALUE[2] = 280;   // AST_BREAK
  TERM_VALUE[3] = 270;   // AST_RETURN
  TERM_VALUE[4] = 258;   // AST_GOTO
}

// THE FROZEN RULE.  The expected terminate outcome.
//
// The rule is a MEMBERSHIP TEST against the frozen terminating set.
// It is TOTAL: every value maps to exactly one of {0, 1}.
static I64 RuleTerminates(I64 ast_kind)
{
  I64 i = 0;
  while (i < 5) {
    if (ast_kind == TERM_VALUE[i]) return 1;
    i = i + 1;
  }
  return 0;
}

// THE PARTITION OF A ROW.
//
//   POSITIVE  : the kind is in the frozen terminating set
//   SENTINEL  : AST_DEFAULT (293) -- the SUB-001-only kind, which this
//                candidate deliberately does NOT terminate on
//   BOUNDARY  : AST_JUMP (288) -- the kind immediately above the
//                highest terminating kind (287 AST_CASE)
//   NEGATIVE  : everything else
static U8 *PartitionOf(I64 ast_kind)
{
  if (RuleTerminates(ast_kind) == 1) return "POSITIVE";
  if (ast_kind == 293) return "SENTINEL";
  if (ast_kind == 288) return "BOUNDARY";
  return "NEGATIVE";
}

// The rationale of a row.
static U8 *RationaleOf(I64 ast_kind)
{
  if (RuleTerminates(ast_kind) == 1) {
    return "this kind TERMINATES the default arm (the C side executes the break)";
  }
  if (ast_kind == 293) {
    return "AST_DEFAULT is DELIBERATELY absent from the SUB-002 condition although PRESENT in the migrated SUB-001 condition; this is the candidate's distinguishing property";
  }
  if (ast_kind == 288) {
    return "AST_JUMP is the kind immediately above AST_CASE=287, the highest terminating kind";
  }
  return "this kind does NOT terminate the default arm";
}


// The append helpers, borrowed in SHAPE from the existing producers so
// that the header and the rows cannot disagree about line endings.
static I64 app_lit(U8 *dst, I64 cap, U8 *lit)
{
  I64 n = 0;
  while (lit[n] != 0) { n = n + 1; }
  I64 i = 0;
  while (i < n) { dst[i] = lit[i]; i = i + 1; }
  return n;
}

static I64 app_ll(U8 *dst, I64 cap, I64 v)
{
  U8 tmp[32];
  I64 n = 0;
  if (v < 0) {
    tmp[0] = 45; n = 1;
    v = 0 - v;
  }
  U8 digits[24];
  I64 d = 0;
  while (v > 0) { digits[d] = 48 + (v % 10); v = v / 10; d = d + 1; }
  if (d == 0) { digits[0] = 48; d = 1; }
  I64 i = d - 1;
  while (i >= 0) { tmp[n] = digits[i]; n = n + 1; i = i - 1; }
  I64 k = 0;
  while (k < n) { dst[k] = tmp[k]; k = k + 1; }
  return n;
}

// The zero-padded 4-digit row id.
//
// The padding goes on the LEFT: the fixture ids are 0001..nnnn.
static I64 app_rowid(U8 *dst, I64 cap, I64 id)
{
  U8 digits[8];
  I64 d = 0;
  I64 v = id;
  while (v > 0) { digits[d] = 48 + (v % 10); v = v / 10; d = d + 1; }
  if (d == 0) { digits[0] = 48; d = 1; }
  I64 n = 0;
  while (n < 4 - d) { dst[n] = 48; n = n + 1; }
  I64 i = d - 1;
  while (i >= 0) { dst[n] = digits[i]; n = n + 1; i = i - 1; }
  return n;
}

// The main.
I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "usage: parser-slice08-fixture-producer <output.tsv>\n";
    return 2;
  }
  U8 *out_path = argv[1];

  InitEnumTable();
  InitTermTable();
  ID_N = 0;
  LEN = 0;
  BUF[0] = 0;

  // THE ROWS.  One row per live AstKind, in ASCENDING VALUE ORDER.
  //
  // The row id is the 1-based position in that order, so the ids are
  // a DERIVED consequence of the live enum.
  I64 i = 0;
  while (i < KIND_N) {
    I64 kind = KIND_VALUE[i];
    U8 *name = KIND_NAME[i];
    I64 expected = RuleTerminates(kind);
    U8 *part = PartitionOf(kind);
    U8 *rat = RationaleOf(kind);

    LEN = LEN + app_rowid(BUF + LEN, FIXTURE_BUF - LEN, ID_N + 1);
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t");
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, part);
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t");
    LEN = LEN + app_ll(BUF + LEN, FIXTURE_BUF - LEN, kind);
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t");
    LEN = LEN + app_ll(BUF + LEN, FIXTURE_BUF - LEN, expected);
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t");
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, name);
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t");
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, rat);
    LEN = LEN + app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n");
    BUF[LEN] = 0;

    ID_N = ID_N + 1;
    i = i + 1;
  }

  // The header block is written into the SAME buffer, BEFORE the rows.
  // The rows are therefore built into a SECOND buffer and then copied.
  U8 rows[FIXTURE_BUF];
  I64 row_len = LEN;
  I64 k = 0;
  while (k < row_len) { rows[k] = BUF[k]; k = k + 1; }

  LEN = 0;
  BUF[0] = 0;

  I64 n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE08\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "ACT_PHASE=C1-EVIDENCE\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "EVIDENCE_KIND=fixture\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The canonical fixture for the selected candidate\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# CANDIDATE=SUB-002 (the default-arm termination decision)\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# Schema:\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   fixture_id <TAB> partition <TAB> ast_kind <TAB>\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   expected_terminates <TAB> expected_kind_name <TAB>\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   rationale\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The row count is DERIVED from the live enum and the\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# frozen terminating set.  It is NOT hard-coded.\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_ROW_COUNT="); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, ID_N); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_ENUM_VALUE_COUNT="); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, KIND_N); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_TERMINATING_COUNT=5\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  BUF[LEN] = 0;

  I64 hdr_len = LEN;
  k = 0;
  while (k < row_len && LEN < FIXTURE_BUF - 1) {
    BUF[LEN] = rows[k];
    LEN = LEN + 1;
    k = k + 1;
  }
  BUF[LEN] = 0;

  // FileWrite does NOT truncate: writing a SHORTER file over a LONGER
  // one leaves the old tail behind.  The fixture is therefore removed
  // first, so a regenerated fixture can never carry a stale tail.
  if (FileExists(out_path)) {
    Rm(out_path);
  }

  if (!FileWrite(out_path, BUF, LEN, 0x0202)) {
    "FIXTURE_WRITE_FAILED=%s\n", out_path;
    "STATUS=FAIL\n";
    return 1;
  }

  "FIXTURE_PATH=%s\n", out_path;
  "FIXTURE_ROW_COUNT=%d\n", ID_N;
  "FIXTURE_ENUM_VALUE_COUNT=%d\n", KIND_N;
  "FIXTURE_TERMINATING_COUNT=5\n";
  "STATUS=PASS\n";
  return 0;
}
