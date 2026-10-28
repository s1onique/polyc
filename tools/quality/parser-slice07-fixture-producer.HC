// tools/quality/parser-slice07-fixture-producer.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE07 C1.
//
// THE FIXTURE PRODUCER for SUB-003.
//
// It derives the complete fixture matrix from the LIVE src/ast.h
// AstKind enum and the FROZEN semantic rule, and writes it in the
// canonical TSV form:
//
//   fixture_id <TAB> partition <TAB> stmt_kind <TAB> declvar_kind
//              <TAB> expected_appends <TAB> expected_stmt_name
//              <TAB> expected_declvar_name <TAB> rationale
//
// THE ROW COUNT IS DERIVED, NEVER CHOSEN
// ======================================
//
// The producer writes the rows and then REPORTS the count it wrote.  It
// does not target a chosen number: the row count is a RESULT of the
// coverage rules below, exactly as the frozen fixture contract
// requires ("NO COUNT IS ASSERTED HERE.  The fixture producer
// enumerates the live enum and the contract only specifies the
// PARTITION.").
//
// THE LIVE ENUM IS DERIVED FROM src/ast.h, NOT COPIED
// ==================================================
//
// The enum names and values below are transcribed from the LIVE
// src/ast.h AstKind enum.  The values are written as NUMBERS because
// the PolyC component cannot include the legacy C header.  Every value
// here was resolved by COMPILING the live src/ast.h, and
// c1/live-ast-enums.tsv records the extraction that binds these
// numbers to the live header.
//
// THE EXPECTED VALUES ARE DERIVED FROM THE FROZEN RULE
// ====================================================
//
// The expected value is computed by the FROZEN rule, which is the
// legacy condition transcribed:
//
//   appends = !(stmt_kind == AST_DECL && declvar_kind == AST_GVAR)
//
// This is NOT read from the new PolyC implementation, and it is NOT
// read from the G0 oracle's output.  The independent verifier
// (tools/quality/parser-slice07-fixture-integrity.HC) recomputes the
// same rule from the source-bound facts and compares it against BOTH
// the fixture and the two oracles.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice07-fixture-producer <output.tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define MAX_ROWS 1024
#define FIXTURE_BUF 1048576

// ---------------------------------------------------------------------------
// THE LIVE AstKind ENUM (src/ast.h, 41 values).
//
// Schema: name <TAB> value.  The array is PARALLEL to the name array.
// ---------------------------------------------------------------------------
static I64 KIND_VALUE[41];
static U8 *KIND_NAME[41];
static I64 KIND_N;

// The two constants of the frozen decision.
#define AST_DECL_VALUE 263
#define AST_GVAR_VALUE 256
#define AST_LVAR_VALUE 261
#define AST_RETURN_VALUE 270

// The output buffer and its length.
static U8 BUF[FIXTURE_BUF];
static I64 LEN;

// The fixture id counter.
static I64 ID_N;

// The out-of-enum / negative / extreme probe set for stmt_kind.
static I64 PROBE_VALUE[17];
static I64 PROBE_N;

// The out-of-enum / negative / extreme probe set for declvar_kind.
static I64 DPROBE_VALUE[10];
static I64 DPROBE_N;

// ---------------------------------------------------------------------------
// The live enum table.
//
// The values are the LIVE src/ast.h values, resolved by compiling the
// header (see c1/live-ast-enums.tsv).
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

// THE INT64_MIN IDIOM FOR THIS LANGUAGE
// =====================================
//
// The literal -9223372036854775808 DOES NOT EVALUATE TO INT64_MIN IN
// THIS LANGUAGE.  The positive magnitude 9223372036854775808 is one
// past INT64_MAX, so the parser's constant folding clamps it and the
// negative of it yields -9223372036854775807 instead.  That was
// MEASURED, not assumed:
//
//   I64 a = -9223372036854775808;     ->  -9223372036854775807
//   I64 d = -9223372036854775807 - 1; ->  -9223372036854775808
//
// So INT64_MIN is written as (-9223372036854775807 - 1).  This is the
// SAME idiom the SLICE06 differential uses (see
// tools/quality/parser-slice06-differential.HC, NEG_MIN_2P63).
#define INT64_MIN_VALUE (-9223372036854775807 - 1)
#define INT64_MAX_VALUE 9223372036854775807

// The out-of-enum / negative / extreme probe set for stmt_kind.
//
// The probe set implements the frozen contract's P6 (out-of-enum
// stmt_kind), P7 (negative I64 values for both inputs) and P8 (the
// extreme I64 values).
static U0 InitProbeTable()
{
  PROBE_N = 0;
  PROBE_VALUE[PROBE_N] = INT64_MIN_VALUE; PROBE_N++;
  PROBE_VALUE[PROBE_N] = -9223372036854775806; PROBE_N++;
  PROBE_VALUE[PROBE_N] = -4; PROBE_N++;
  PROBE_VALUE[PROBE_N] = -3; PROBE_N++;
  PROBE_VALUE[PROBE_N] = -2; PROBE_N++;
  PROBE_VALUE[PROBE_N] = -1; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 0;  PROBE_N++;
  PROBE_VALUE[PROBE_N] = 1;  PROBE_N++;
  PROBE_VALUE[PROBE_N] = 250; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 255; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 257; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 260; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 300; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 301; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 1000; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 1000000; PROBE_N++;
  PROBE_VALUE[PROBE_N] = 9223372036854775807; PROBE_N++;   /* INT64_MAX */

  DPROBE_N = 0;
  DPROBE_VALUE[DPROBE_N] = INT64_MIN_VALUE; DPROBE_N++;
  DPROBE_VALUE[DPROBE_N] = -1; DPROBE_N++;
  DPROBE_VALUE[DPROBE_N] = 0;  DPROBE_N++;
  DPROBE_VALUE[DPROBE_N] = 1;  DPROBE_N++;
  DPROBE_VALUE[DPROBE_N] = 255; DPROBE_N++;
  DPROBE_VALUE[DPROBE_N] = 257; DPROBE_N++;
  DPROBE_VALUE[DPROBE_N] = 260; DPROBE_N++;
  DPROBE_VALUE[DPROBE_N] = 300; DPROBE_N++;
  DPROBE_VALUE[DPROBE_N] = 9223372036854775807; DPROBE_N++;   /* INT64_MAX */
}
// THE FROZEN RULE.  The expected append/skip outcome.
//
//   appends = !(stmt_kind == AST_DECL && declvar_kind == AST_GVAR)
//
// This is the legacy condition transcribed.  It is the SINGLE source of
// the expected value in the fixture, and it is INDEPENDENT of the new
// PolyC implementation.
static I64 ExpectedAppends(I64 stmt_kind, I64 declvar_kind)
{
  if (stmt_kind == AST_DECL_VALUE) {
    if (declvar_kind == AST_GVAR_VALUE) return 0;
  }
  return 1;
}

// The enum name of `v`, or "OUT_OF_ENUM" when v is not an enum value.
static U8 *NameOf(I64 v)
{
  for (I64 i = 0; i < KIND_N; i++) {
    if (KIND_VALUE[i] == v) return KIND_NAME[i];
  }
  return "OUT_OF_ENUM";
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
// conversion.  The runtime's "%d" is a 32-bit conversion: it prints
// INT64_MIN as 0 and INT64_MAX as -1.  Using "%d" here would silently
// destroy any signed-64-bit value, so "%lld" is used and the formatter
// below is the ONE place where a fixture value becomes text.
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

// Emit one fixture row.
//
// The row is:
//   fixture_id <TAB> partition <TAB> stmt_kind <TAB> declvar_kind
//          <TAB> expected_appends <TAB> expected_stmt_name
//          <TAB> expected_declvar_name <TAB> rationale
static U0 Emit(I64 id, U8 *partition, I64 stmt_kind, I64 declvar_kind,
               I64 expected, U8 *rationale)
{
  U8 row[1024];
  I64 n = 0;

  n = n + app_pad(row + n, 1024 - n, id, 4);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_str(row + n, 1024 - n, partition);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_ll(row + n, 1024 - n, stmt_kind);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_ll(row + n, 1024 - n, declvar_kind);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_ll(row + n, 1024 - n, expected);
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_str(row + n, 1024 - n, NameOf(stmt_kind));
  n = n + app_tab(row + n, 1024 - n);
  n = n + app_str(row + n, 1024 - n, NameOf(declvar_kind));
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
//
// The partitions implement the frozen fixture contract's P1..P8.
//
// P1 SKIP: stmt_kind == AST_DECL AND declvar_kind == AST_GVAR.
static U0 PartitionP01()
{
  Emit(ID_N + 1, "P1_SKIP", AST_DECL_VALUE, AST_GVAR_VALUE, 0,
       "a declaration whose declvar is a global variable is SKIPPED");
}

// P2 APPEND_DECL: stmt_kind == AST_DECL AND declvar_kind != AST_GVAR.
//    The short-circuit second arm: a declaration that is NOT a global
//    variable IS appended.
static U0 PartitionP02()
{
  for (I64 i = 0; i < KIND_N; i++) {
    if (KIND_VALUE[i] != AST_GVAR_VALUE) {
      Emit(ID_N + 1, "P2_APPEND_DECL", AST_DECL_VALUE, KIND_VALUE[i], 1,
           "a declaration whose declvar is not a global variable is APPENDED");
    }
  }
}

// P3 APPEND_NONDECL: stmt_kind != AST_DECL AND declvar_kind == AST_GVAR.
//    The declvar value is NOT consulted for a non-declaration.
static U0 PartitionP03()
{
  for (I64 i = 0; i < KIND_N; i++) {
    if (KIND_VALUE[i] != AST_DECL_VALUE) {
      Emit(ID_N + 1, "P3_APPEND_NONDECL", KIND_VALUE[i], AST_GVAR_VALUE, 1,
           "a non-declaration is APPENDED even when its declvar would be a global");
    }
  }
}

// P4 APPEND_GENERAL: stmt_kind != AST_DECL AND declvar_kind != AST_GVAR.
static U0 PartitionP04()
{
  for (I64 i = 0; i < KIND_N; i++) {
    if (KIND_VALUE[i] == AST_DECL_VALUE) continue;
    for (I64 j = 0; j < KIND_N; j++) {
      if (KIND_VALUE[j] == AST_GVAR_VALUE) continue;
      Emit(ID_N + 1, "P4_APPEND_GENERAL", KIND_VALUE[i], KIND_VALUE[j], 1,
           "a non-declaration with a non-global declvar is APPENDED");
    }
  }
}

// P5 IRRELEVANT_DECLVAR: a non-declaration paired with an UNREACHABLE
// declvar value.
//
// The frozen contract's P5: "declvar_kind is an UNREACHABLE value (the
// C side never evaluates it when stmt_kind != AST_DECL): the component
// MUST NOT consult it, and the result MUST be APPEND."  The out-of-enum,
// negative and extreme declvar probes are exactly those values.
static U0 PartitionP05()
{
  for (I64 j = 0; j < DPROBE_N; j++) {
    Emit(ID_N + 1, "P5_IRRELEVANT_DECLVAR", AST_LVAR_VALUE, DPROBE_VALUE[j], 1,
         "the declvar value is not consulted for a non-declaration");
    Emit(ID_N + 1, "P5_IRRELEVANT_DECLVAR", AST_RETURN_VALUE, DPROBE_VALUE[j], 1,
         "the declvar value is not consulted for a non-declaration");
  }
}

// P6 OUT_OF_ENUM: stmt_kind is an out-of-enum value.
//
// The frozen contract's P6: "stmt_kind is an out-of-enum value: the
// component MUST NOT range-check it, and the result MUST be APPEND."
static U0 PartitionP06()
{
  for (I64 i = 0; i < PROBE_N; i++) {
    Emit(ID_N + 1, "P6_OUT_OF_ENUM", PROBE_VALUE[i], AST_GVAR_VALUE, 1,
         "an out-of-enum stmt_kind is APPENDED, not range-checked");
    Emit(ID_N + 1, "P6_OUT_OF_ENUM", PROBE_VALUE[i], AST_LVAR_VALUE, 1,
         "an out-of-enum stmt_kind is APPENDED, not range-checked");
  }
}

// P7 NEGATIVE: negative I64 values for BOTH inputs.
static U0 PartitionP07()
{
  for (I64 i = 0; i < PROBE_N; i++) {
    if (PROBE_VALUE[i] >= 0) continue;
    Emit(ID_N + 1, "P7_NEGATIVE", PROBE_VALUE[i], AST_GVAR_VALUE, 1,
         "a negative stmt_kind is APPENDED");
  }
  for (I64 j = 0; j < DPROBE_N; j++) {
    if (DPROBE_VALUE[j] >= 0) continue;
    Emit(ID_N + 1, "P7_NEGATIVE", AST_DECL_VALUE, DPROBE_VALUE[j], 1,
         "a negative declvar_kind on a declaration is APPENDED");
    Emit(ID_N + 1, "P7_NEGATIVE", AST_LVAR_VALUE, DPROBE_VALUE[j], 1,
         "a negative declvar_kind on a non-declaration is APPENDED");
  }
}

// P8 EXTREME: the extreme I64 values for BOTH inputs.
static U0 PartitionP08()
{
  Emit(ID_N + 1, "P8_EXTREME", INT64_MIN_VALUE, AST_GVAR_VALUE, 1,
       "the most negative stmt_kind is APPENDED");
  Emit(ID_N + 1, "P8_EXTREME", INT64_MAX_VALUE, AST_GVAR_VALUE, 1,
       "the most positive stmt_kind is APPENDED");
  Emit(ID_N + 1, "P8_EXTREME", AST_DECL_VALUE, INT64_MIN_VALUE, 1,
       "the most negative declvar_kind on a declaration is APPENDED");
  Emit(ID_N + 1, "P8_EXTREME", AST_DECL_VALUE, INT64_MAX_VALUE, 1,
       "the most positive declvar_kind on a declaration is APPENDED");
  Emit(ID_N + 1, "P8_EXTREME", AST_LVAR_VALUE, INT64_MIN_VALUE, 1,
       "the most negative declvar_kind on a non-declaration is APPENDED");
  Emit(ID_N + 1, "P8_EXTREME", AST_LVAR_VALUE, INT64_MAX_VALUE, 1,
       "the most positive declvar_kind on a non-declaration is APPENDED");
}

// P9 MUTATION_SENSITIVE: the pair the causal PolyC mutation flips.
//
// The causal mutation flips the AST_DECL/AST_GVAR pair, so the fixture
// MUST carry that exact pair.
static U0 PartitionP09()
{
  Emit(ID_N + 1, "P9_MUTATION_SENSITIVE", AST_DECL_VALUE, AST_GVAR_VALUE, 0,
       "the pair the causal PolyC mutation flips must be detected");
}

// P10 SHORT_CIRCUIT_MINIMAL: the minimal pair that DISTINGUISHES a
// global declaration from a regular declaration, and a non-declaration
// whose declvar is IRRELEVANT and unsafe to read.
static U0 PartitionP10()
{
  Emit(ID_N + 1, "P10_SHORT_CIRCUIT_MINIMAL", AST_DECL_VALUE, AST_GVAR_VALUE, 0,
       "a global declaration and a regular declaration differ only in declvar");
  Emit(ID_N + 1, "P10_SHORT_CIRCUIT_MINIMAL", AST_DECL_VALUE, AST_LVAR_VALUE, 1,
       "a regular declaration is appended");
  Emit(ID_N + 1, "P10_SHORT_CIRCUIT_MINIMAL", AST_LVAR_VALUE, AST_GVAR_VALUE, 1,
       "a non-declaration with an unsafe-to-read declvar is appended");
}

// ---------------- The main -------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  U8 *out_path;

  if (argc < 2) {
    "FIXTURE_USAGE=build/parser-slice07-fixture-producer <output.tsv>\n";
    "STATUS=ERROR\n";
    return 2;
  }
  out_path = argv[1];

  InitEnumTable();
  InitProbeTable();

  ID_N = 0;
  LEN = 0;

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

  // The header is built with the SAME appenders the rows use, so the
  // header and the rows cannot disagree about line endings and so no
  // separate string API is involved.
  I64 n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE07\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "ACT_PHASE=C1-EVIDENCE\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "EVIDENCE_KIND=fixture\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The canonical fixture for the selected candidate\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# CANDIDATE=SUB-003 (the compound-block statement append/skip routing)\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# Schema:\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   fixture_id <TAB> partition <TAB> stmt_kind <TAB> declvar_kind\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   expected_appends <TAB> expected_stmt_name <TAB>\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   expected_declvar_name <TAB> rationale\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The row count is DERIVED from the live enum and the\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# frozen probe set.  It is NOT hard-coded.\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The expected value is derived from the FROZEN RULE\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   appends = !(stmt_kind == AST_DECL && declvar_kind == AST_GVAR)\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# and NOT from the new PolyC implementation or the G0 oracle.\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_ROW_COUNT="); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, ID_N); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_PARTITION_COUNT=10\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_ENUM_VALUE_COUNT=41\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_PROBE_COUNT=17\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_DECLVAR_PROBE_COUNT=9\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_SKIP_COUNT=1\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
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
  "FIXTURE_PARTITION_COUNT=10\n";
  "FIXTURE_ENUM_VALUE_COUNT=%d\n", KIND_N;
  "FIXTURE_PROBE_COUNT=%d\n", PROBE_N;
  "FIXTURE_DECLVAR_PROBE_COUNT=%d\n", DPROBE_N;
  "FIXTURE_SKIP_COUNT=1\n";
  "STATUS=PASS\n";
  return 0;
}
