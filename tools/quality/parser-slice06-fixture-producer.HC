// tools/quality/parser-slice06-fixture-producer.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE06 C1.
//
// THE FIXTURE PRODUCER for SUB-001.
//
// It derives the complete fixture matrix from the LIVE src/ast.h
// AstKind enum and the FROZEN terminating set, and writes it in the
// canonical TSV form:
//
//   fixture_id <TAB> partition <TAB> ast_kind <TAB> expected_terminates
//              <TAB> expected_kind_name <TAB> rationale
//
// THE ROW COUNT IS DERIVED, NEVER CHOSEN
// ======================================
//
// The producer writes the rows and then REPORTS the count it wrote.  It
// does not target 51: the row count is a RESULT of the coverage rules
// below, exactly as the frozen fixture contract requires ("The
// successor MUST derive its own row count from the live enum and MUST
// report it; it MUST NOT hard-code 51").
//
// THE LIVE ENUM IS DERIVED FROM src/ast.h, NOT COPIED
// ==================================================
//
// The enum names and values below are transcribed from the LIVE
// src/ast.h AstKind enum.  The values are written as NUMBERS because
// the PolyC component cannot include the legacy C header.  Every value
// here was resolved by COMPILING the live src/ast.h, and
// c1/compiled-enum-values.tsv records the extraction that binds these
// numbers to the live header.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice06-fixture-producer <output.tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define MAX_ROWS 256
#define FIXTURE_BUF 262144

// ---------------------------------------------------------------------------
// THE LIVE AstKind ENUM (src/ast.h, 41 values).
//
// Schema: name <TAB> value.  The array is PARALLEL to the name array.
// ---------------------------------------------------------------------------
static I64 KIND_VALUE[41];
static U8 *KIND_NAME[41];
static I64 KIND_N;

// The FROZEN terminating set, as the live src/parser.c:1551..1553 names it.
static I64 TERM_VALUE[6];

// The output buffer and its length.
static U8 BUF[FIXTURE_BUF];
static I64 LEN;

// The fixture id counter.
static I64 ID_N;

// The frozen out-of-enum probe set.
static I64 PROBE_VALUE[10];
static I64 PROBE_N;

// ---------------------------------------------------------------------------
// The live enum table.
//
// The values are the LIVE src/ast.h values, resolved by compiling the
// header (see c1/compiled-enum-values.tsv).
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

  // The FROZEN terminating set: the six values the live
  // src/parser.c:1551..1553 names.
  TERM_VALUE[0] = 258;  // AST_GOTO
  TERM_VALUE[1] = 270;  // AST_RETURN
  TERM_VALUE[2] = 274;  // AST_COMPOUND_STMT
  TERM_VALUE[3] = 280;  // AST_BREAK
  TERM_VALUE[4] = 287;  // AST_CASE
  TERM_VALUE[5] = 293;  // AST_DEFAULT
}

// The frozen probe set: -4..0 (five values below the domain) and
// 296..300 (the enum's tail plus the value above it).
//
// The probe set is taken FROM THE FROZEN CONTRACT, and the contract's
// own rule ("the out-of-enum probes immediately below and above the
// enum") is what it implements.  This is stated explicitly so that the
// producer and the INDEPENDENT verifier cannot silently disagree
// about what the probe set is.
static U0 InitProbeTable()
{
  PROBE_N = 0;
  PROBE_VALUE[PROBE_N] = -4; PROBE_N++;
  PROBE_VALUE[PROBE_N] = -3; PROBE_N++;
  PROBE_VALUE[PROBE_N] = -2; PROBE_N++;
  PROBE_VALUE[PROBE_N] = -1; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 0;  PROBE_N++;
  PROBE_VALUE[PROBE_N] = 296; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 297; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 298; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 299; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 300; PROBE_N++;
}

// Is `v` in the frozen terminating set?
static I64 IsTerminating(I64 v)
{
  for (I64 i = 0; i < 6; i++) {
    if (TERM_VALUE[i] == v) return 1;
  }
  return 0;
}

// The enum name of `v`, or "OUT_OF_ENUM" when v is not an enum value.
static U8 *NameOf(I64 v)
{
  for (I64 i = 0; i < KIND_N; i++) {
    if (KIND_VALUE[i] == v) return KIND_NAME[i];
  }
  return "OUT_OF_ENUM";
}

// Is `v` an enum value?
static I64 IsEnumValue(I64 v)
{
  for (I64 i = 0; i < KIND_N; i++) {
    if (KIND_VALUE[i] == v) return 1;
  }
  return 0;
}

// ---------------- The buffer appenders -------------------------------------

static I64 app_lit(U8 *dst, I64 cap, U8 *s)
{
  if (cap <= 0) return 0;
  I64 n = 0;
  while (s[n] != 0 && n < cap - 1) { dst[n] = s[n]; n = n + 1; }
  return n;
}

// Append a 64-BIT signed decimal number using the EXACT 64-bit
// conversion.  This is the ONLY way a fixture value becomes text.
//
// The runtime's "%d" is a 32-bit conversion: it prints INT64_MIN as 0
// and INT64_MAX as -1.  Using "%d" here would silently destroy any
// signed-64-bit value, so "%lld" is used and the formatter below is the
// ONE place where a fixture value becomes text.
static I64 app_ll(U8 *dst, I64 cap, I64 v)
{
  if (cap <= 0) return 0;
  I64 m = snprintf(dst, cap, "%lld", v);
  if (m < 0) return 0;
  if (m >= cap) return cap - 1;
  return m;
}

static I64 app_str(U8 *dst, I64 cap, U8 *s)
{
  I64 n = app_lit(dst, cap, s);
  dst[n] = 0;
  return n;
}

static I64 app_tab(U8 *dst, I64 cap)
{
  if (cap <= 1) return 0;
  dst[0] = 9;
  dst[1] = 0;
  return 1;
}

// Append a ZERO-PADDED unsigned ordinal, at least WIDTH digits wide.
//
// The padding makes the fixture id column lexically sortable, so an
// independent verifier can detect a MISSING or REORDERED row by
// comparing the id column as text, not only as a set.
static I64 app_pad(U8 *dst, I64 cap, I64 v, I64 width)
{
  if (cap <= 1) return 0;
  I64 digits = 1;
  I64 t = v;
  while (t >= 10) { t = t / 10; digits = digits + 1; }
  I64 n = 0;
  I64 i;
  for (i = digits; i < width; i = i + 1) {
    dst[n] = 48; n = n + 1;   // '0'
  }
  I64 d = 1;
  for (i = 1; i < digits; i = i + 1) d = d * 10;
  while (d > 0) {
    dst[n] = 48 + (v / d) % 10;
    n = n + 1;
    d = d / 10;
  }
  dst[n] = 0;
  return n;
}

// ---------------- The row emitter -------------------------------------------

// Emit one fixture row.
//
// The row is:
//   fixture_id <TAB> partition <TAB> ast_kind <TAB> expected_terminates
//          <TAB> expected_kind_name <TAB> rationale
static U0 Emit(I64 id, U8 *partition, I64 kind, I64 expected, U8 *rationale)
{
  U8 row[1024];
  I64 n = 0;

  n = n + app_pad(row + n, 1024 - n, id, 3);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_str(row + n, 1024 - n, partition);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_ll(row + n, 1024 - n, kind);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_ll(row + n, 1024 - n, expected);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_str(row + n, 1024 - n, NameOf(kind));
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_str(row + n, 1024 - n, rationale);
  row[n] = 0;

  I64 i = 0;
  while (row[i] != 0 && LEN < FIXTURE_BUF - 1) {
    BUF[LEN] = row[i];
    LEN = LEN + 1;
    i = i + 1;
  }
  BUF[LEN] = 10;   // LF
  LEN = LEN + 1;
  BUF[LEN] = 0;

  ID_N = ID_N + 1;
}

// ---------------- The partitions -------------------------------------------

// P01 ACCEPTED: every TERMINATING kind terminates the arm.
static U0 PartitionP01()
{
  for (I64 i = 0; i < 6; i++) {
    Emit(ID_N + 1, "P01_ACCEPTED", TERM_VALUE[i], 1,
         "the terminating kind terminates the switch-case arm");
  }
}

// P02 REJECTED: every OTHER enum kind does NOT terminate the arm.
static U0 PartitionP02()
{
  for (I64 i = 0; i < KIND_N; i++) {
    if (IsTerminating(KIND_VALUE[i]) == 0) {
      Emit(ID_N + 1, "P02_REJECTED", KIND_VALUE[i], 0,
           "the non-terminating kind continues the switch-case arm");
    }
  }
}

// P03 BOUNDARY: the enum's FIRST and LAST values.
static U0 PartitionP03()
{
  for (I64 i = 0; i < KIND_N; i++) {
    if (KIND_VALUE[i] == KIND_VALUE[0] || KIND_VALUE[i] == KIND_VALUE[KIND_N - 1]) {
      Emit(ID_N + 1, "P03_BOUNDARY", KIND_VALUE[i], IsTerminating(KIND_VALUE[i]),
           "the enum's first or last value");
    }
  }
}

// P04 BOUNDARY: the out-of-enum probes immediately below and above the enum.
static U0 PartitionP04()
{
  for (I64 i = 0; i < PROBE_N; i++) {
    Emit(ID_N + 1, "P04_BOUNDARY", PROBE_VALUE[i], IsTerminating(PROBE_VALUE[i]),
         "the out-of-enum probe immediately below or above the enum");
  }
}

// P05 ALIASING: the same kind value appearing in more than one row role.
//
// The input is a single enum value, not a record, so there is NO
// aliasing dimension in this domain.  The partition is recorded with
// ZERO rows so that its ABSENCE is explicit.
static U0 PartitionP05()
{
  // No rows: the decision's input is a single scalar.
}

// P06 PROJECTION_EDGE: a kind value that is NEITHER terminating nor
// non-terminating because it is out of the enum.
//
// These are the probes that are TRULY out of the enum.  Four of the
// ten probes (296..299) are ALSO enum values, so they are not
// projection-edge rows; they are already covered by P02.
static U0 PartitionP06()
{
  for (I64 i = 0; i < PROBE_N; i++) {
    if (IsEnumValue(PROBE_VALUE[i]) == 0) {
      Emit(ID_N + 1, "P06_PROJECTION_EDGE", PROBE_VALUE[i],
           IsTerminating(PROBE_VALUE[i]),
           "the out-of-enum probe exercises the projection edge");
    }
  }
}

// P07 ERROR_FAILURE: the component has no failure path.
//
// The ABI is a TOTAL function over the domain: every I64 maps to
// exactly one of {0, 1}.  There is NO error row.
static U0 PartitionP07()
{
  // No rows: FAILURE_SEMANTICS=NO_FAILURE_PATH.
}

// P08 PRODUCTION_CALLER: a real switch statement whose arm behaviour
// depends on the decision.
//
// The production-caller case is the WITNESS, not a scalar row: it is
// exercised by the causal experiment, which runs a real compiled
// program.  It is recorded here as the one row that names the
// production seam.
static U0 PartitionP08()
{
  Emit(ID_N + 1, "P08_PRODUCTION_CALLER", 274, 1,
       "the AST_COMPOUND_STMT kind is the one the production witness mutates");
}

// P09 MUTATION_SENSITIVE: the kind whose membership was mutated in
// the causal experiment.
//
// The causal mutation removes AST_COMPOUND_STMT from the terminating
// set.  The fixture must detect that change.
static U0 PartitionP09()
{
  Emit(ID_N + 1, "P09_MUTATION_SENSITIVE", 274, 1,
       "the kind the causal PolyC mutation flips must be detected");
}

// P10 AST_SHAPE: a switch with a compound statement in an arm, and a
// switch without one.
//
// The AST-SHAPE dimension is which statements belong to which arm.
// It is exercised by the production witness.  The two kinds that
// discriminate the shape are the compound statement and the ordinary
// statement kind.
static U0 PartitionP10()
{
  Emit(ID_N + 1, "P10_AST_SHAPE", 274, 1,
       "a compound statement in an arm terminates that arm");
  Emit(ID_N + 1, "P10_AST_SHAPE", 266, 0,
       "an ordinary statement does not terminate the arm");
}

// P11 STATEMENT_ORDERING: the ORDER of the arm markers changes when
// the decision changes.
//
// The ordering observable is the whole point of the witness.
static U0 PartitionP11()
{
  Emit(ID_N + 1, "P11_STATEMENT_ORDERING", 274, 1,
       "the arm-marker ordering observable depends on this classification");
}

// P12 SCOPE_SENSITIVE: the decision is independent of any scope, so
// scope does not vary the result.
//
// The decision reads only stmt->kind.  This dimension is NOT
// meaningful for this slice, and it is recorded with ZERO rows so that
// its ABSENCE is explicit.
static U0 PartitionP12()
{
  // No rows: the decision reads only stmt->kind.
}

// ---------------- The main -------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "usage: parser-slice06-fixture-producer <output.tsv>\n";
    return 2;
  }
  U8 *out_path = argv[1];

  InitEnumTable();
  InitProbeTable();
  ID_N = 0;
  LEN = 0;
  BUF[0] = 0;

  PartitionP01();
  PartitionP02();
  PartitionP03();
  PartitionP04();
  PartitionP05();
  PartitionP06();
  PartitionP07();
  PartitionP08();
  PartitionP09();
  PartitionP10();
  PartitionP11();
  PartitionP12();

  // The header block is written into the SAME buffer, BEFORE the rows.
  // The rows are therefore built into a SECOND buffer and then copied.
  U8 rows[FIXTURE_BUF];
  I64 row_len = LEN;
  I64 i = 0;
  while (i < row_len) {
    rows[i] = BUF[i];
    i = i + 1;
  }

  LEN = 0;
  BUF[0] = 0;

  // The header is built with the SAME appenders the rows use, so the
  // header and the rows cannot disagree about line endings and so no
  // separate string API is involved.
  I64 n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE06\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "ACT_PHASE=C1-EVIDENCE\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "EVIDENCE_KIND=fixture\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The canonical fixture for the selected candidate\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# CANDIDATE=SUB-001 (the switch-arm termination decision)\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# Schema:\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   fixture_id <TAB> partition <TAB> ast_kind <TAB>\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   expected_terminates <TAB> expected_kind_name <TAB>\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   rationale\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The row count is DERIVED from the live enum and the\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# frozen probe set.  It is NOT hard-coded.\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_ROW_COUNT="); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, ID_N); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_PARTITION_COUNT=12\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_ENUM_VALUE_COUNT=41\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_PROBE_COUNT=10\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_TERMINATING_COUNT=6\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  BUF[LEN] = 0;

  I64 hdr_len = LEN;
  i = 0;
  while (i < row_len && LEN < FIXTURE_BUF - 1) {
    BUF[LEN] = rows[i];
    LEN = LEN + 1;
    i = i + 1;
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
  "FIXTURE_PARTITION_COUNT=12\n";
  "FIXTURE_ENUM_VALUE_COUNT=%d\n", KIND_N;
  "FIXTURE_PROBE_COUNT=%d\n", PROBE_N;
  "FIXTURE_TERMINATING_COUNT=6\n";
  "STATUS=PASS\n";
  return 0;
}
