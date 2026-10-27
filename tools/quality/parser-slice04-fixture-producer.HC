// tools/quality/parser-slice04-fixture-producer.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE04 C2.
//
// THE FIXTURE PRODUCER.
//
// It derives the complete mandatory fixture matrix from the FROZEN
// accepted token values and the FROZEN enum mapping, and writes it in
// the canonical TSV form:
//
//   fixture_id <TAB> partition <TAB> token_value <TAB> expected_success
//              <TAB> expected_output <TAB> initial_output <TAB> rationale
//
// The canonical row count is DERIVED from the frozen values, never
// chosen in advance: the producer writes the rows and then reports the
// count it wrote.
//
// THE 64-BIT FORMATTER IS LOAD-BEARING
// =====================================
//
// The value columns are written with snprintf("%lld"), NOT with the
// runtime's "%d".  The runtime's "%d" is a 32-BIT conversion: it
// prints INT64_MIN as 0 and INT64_MAX as -1.  That is EXACTLY the
// defect the predecessor's correction recorded as D1, and using "%d"
// here would silently destroy the M06 signed-I64 extremes.
//
// The formatter below is the ONE place where a fixture value is turned
// into text, so the conversion cannot be bypassed by accident.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice04-fixture-producer <output.tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAX_ROWS 512
#define FIXTURE_BUF 262144

// The FROZEN accepted token values and their FROZEN enum values.
//
// These are the 19 mappings measured from the REAL legacy function (see
// c1/token-mapping.tsv).  The token values are the live src/lexer.h
// values; the enum values are the live src/ast.h values.
static I64 TOK_VALUE[19];
static I64 TOK_ENUM[19];

// The output buffer and its length.
static U8 BUF[FIXTURE_BUF];
static I64 LEN;

// The two DISTINCT initial output values used for the failure rows.
//
// They are deliberately different from each other AND from every real
// mapped enum value, so that a failure which overwrote the output with
// a hard-coded default would be detected.
#define INIT_A 12345
#define INIT_B 54321

static I64 ID_N;

// ---------------- The buffer appenders -------------------------------------

// Append a NUL-terminated string.  Returns the number of bytes appended.
static I64 app_lit(U8 *dst, I64 cap, U8 *s)
{
  if (cap <= 0) return 0;
  I64 n = 0;
  while (s[n] != 0 && n < cap - 1) { dst[n] = s[n]; n = n + 1; }
  return n;
}

// Append a 64-BIT signed decimal number using the EXACT 64-bit
// conversion.  This is the ONLY way a fixture value becomes text.
static I64 app_ll(U8 *dst, I64 cap, I64 v)
{
  if (cap <= 0) return 0;
  I64 m = snprintf(dst, cap, "%lld", v);
  if (m < 0) return 0;
  if (m >= cap) return cap - 1;
  return m;
}

// Append a NUL-terminated string.
static I64 app_str(U8 *dst, I64 cap, U8 *s)
{
  I64 n = app_lit(dst, cap, s);
  dst[n] = 0;
  return n;
}

// Append a 64-bit signed decimal number, NUL-terminated.
static I64 app_llz(U8 *dst, I64 cap, I64 v)
{
  I64 n = app_ll(dst, cap - 1, v);
  dst[n] = 0;
  return n;
}

// Append a TAB.
static I64 app_tab(U8 *dst, I64 cap)
{
  if (cap <= 1) return 0;
  dst[0] = 9;
  dst[1] = 0;
  return 1;
}

// ---------------- The frozen table -----------------------------------------

static U0 InitFrozenTable()
{
  TOK_VALUE[0] = 43;   TOK_ENUM[0] = 3;    // '+'  -> AST_BIN_OP_ADD
  TOK_VALUE[1] = 45;   TOK_ENUM[1] = 4;    // '-'  -> AST_BIN_OP_SUB
  TOK_VALUE[2] = 42;   TOK_ENUM[2] = 0;    // '*'  -> AST_BIN_OP_MUL
  TOK_VALUE[3] = 47;   TOK_ENUM[3] = 1;    // '/'  -> AST_BIN_OP_DIV
  TOK_VALUE[4] = 37;   TOK_ENUM[4] = 2;    // '%'  -> AST_BIN_OP_MOD
  TOK_VALUE[5] = 61;   TOK_ENUM[5] = 18;   // '='  -> AST_BIN_OP_ASSIGN
  TOK_VALUE[6] = 60;   TOK_ENUM[6] = 7;    // '<'  -> AST_BIN_OP_LT
  TOK_VALUE[7] = 62;   TOK_ENUM[7] = 9;    // '>'  -> AST_BIN_OP_GT
  TOK_VALUE[8] = 782;  TOK_ENUM[8] = 10;   // TK_GREATER_EQU -> GE
  TOK_VALUE[9] = 781;  TOK_ENUM[9] = 8;    // TK_LESS_EQU    -> LE
  TOK_VALUE[10] = 779; TOK_ENUM[10] = 11;  // TK_EQU_EQU     -> EQ
  TOK_VALUE[11] = 780; TOK_ENUM[11] = 12;  // TK_NOT_EQU     -> NE
  TOK_VALUE[12] = 783; TOK_ENUM[12] = 16;  // TK_AND_AND     -> LOG_AND
  TOK_VALUE[13] = 784; TOK_ENUM[13] = 17;  // TK_OR_OR       -> LOG_OR
  TOK_VALUE[14] = 94;  TOK_ENUM[14] = 14;  // '^'  -> AST_BIN_OP_BIT_XOR
  TOK_VALUE[15] = 38;  TOK_ENUM[15] = 13;  // '&'  -> AST_BIN_OP_BIT_AND
  TOK_VALUE[16] = 124; TOK_ENUM[16] = 15;  // '|'  -> AST_BIN_OP_BIT_OR
  TOK_VALUE[17] = 777; TOK_ENUM[17] = 5;   // TK_SHL -> AST_BIN_OP_SHL
  TOK_VALUE[18] = 778; TOK_ENUM[18] = 6;   // TK_SHR -> AST_BIN_OP_SHR
}

// Is the value one of the accepted tokens?
static I64 IsAccepted(I64 v)
{
  for (I64 i = 0; i < 19; i++) if (TOK_VALUE[i] == v) return 1;
  return 0;
}

// The enum value for an accepted token, or -1.
static I64 EnumOf(I64 v)
{
  for (I64 i = 0; i < 19; i++) if (TOK_VALUE[i] == v) return TOK_ENUM[i];
  return -1;
}

// ---------------- Row emission ---------------------------------------------

// The partition name of the row being emitted.
static U8 *CUR_PARTITION;

// Emit one fixture row:
//
//   fixture_id <TAB> partition <TAB> token_value <TAB> expected_success
//              <TAB> expected_output <TAB> initial_output <TAB> rationale
static U0 AddRow(I64 token_value, I64 expected_success,
                 I64 expected_output, I64 initial_output, U8 *rationale)
{
  if (LEN >= FIXTURE_BUF - 512) return;
  ID_N = ID_N + 1;
  U8 *dst = BUF + LEN;
  I64 cap = FIXTURE_BUF - LEN;

  // The fixture id.
  I64 n = snprintf(dst, cap, "F%03d", ID_N);
  LEN = LEN + n;
  dst = BUF + LEN;
  cap = FIXTURE_BUF - LEN;

  LEN = LEN + app_tab(dst, cap); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_str(dst, cap, CUR_PARTITION); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_tab(dst, cap); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_llz(dst, cap, token_value); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_tab(dst, cap); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_llz(dst, cap, expected_success); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_tab(dst, cap); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_llz(dst, cap, expected_output); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_tab(dst, cap); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_llz(dst, cap, initial_output); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_tab(dst, cap); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_str(dst, cap, rationale); dst = BUF + LEN; cap = FIXTURE_BUF - LEN;
  LEN = LEN + app_lit(dst, cap, "\n");
  BUF[LEN] = 0;
}

// ---------------- The invalid-token registry --------------------------------
//
// Every INVALID token value the fixture contains is registered here as
// it is emitted.  The M09 partition then re-emits each registered
// value with the SECOND distinct initial output value.  This keeps the
// two-partition relationship explicit.
static I64 INV_VALUE[MAX_ROWS];
static I64 INV_N;

static U0 RegisterInvalid(I64 v)
{
  for (I64 i = 0; i < INV_N; i++) if (INV_VALUE[i] == v) return;
  if (INV_N >= MAX_ROWS) return;
  INV_VALUE[INV_N] = v;
  INV_N = INV_N + 1;
}

// Emit an invalid row: success 0, and the output is unchanged.
static U0 AddInvalid(I64 v, I64 initial_output, U8 *rationale)
{
  AddRow(v, 0, initial_output, initial_output, rationale);
  RegisterInvalid(v);
}

// ---------------- The partitions -------------------------------------------

// M01: every accepted token mapped to its exact enum.
//
// The initial output value is INIT_A, so that a failure that wrote a
// hard-coded default would be visible.
static U0 PartitionM01()
{
  CUR_PARTITION = "M01_ACCEPTED_TOKEN";
  for (I64 i = 0; i < 19; i++) {
    AddRow(TOK_VALUE[i], 1, TOK_ENUM[i], INIT_A,
           "an accepted token maps to its exact enum");
  }
}

// M02: every accepted mapping repeated with a DIFFERENT initial output
// value.
//
// The value is the same token, but the caller's output storage starts at
// INIT_B instead of INIT_A, so the row proves that the mapped enum is
// written rather than merely left in place.
static U0 PartitionM02()
{
  CUR_PARTITION = "M02_REPEATED_INITIAL_OUTPUT";
  for (I64 i = 0; i < 19; i++) {
    AddRow(TOK_VALUE[i], 1, TOK_ENUM[i], INIT_B,
           "the same mapping with a different initial output value");
  }
}

// M03: unrecognized ASCII token values.
//
// Every printable ASCII value that is NOT an accepted token.
static U0 PartitionM03()
{
  CUR_PARTITION = "M03_UNRECOGNIZED_ASCII";
  for (I64 v = 32; v < 127; v++) {
    if (IsAccepted(v)) continue;
    AddInvalid(v, INIT_A, "an unrecognized printable ASCII token value");
  }
}

// M04: neighbouring values around every accepted token constant.
//
// The immediate predecessor and successor of every accepted token.  A
// neighbour that happens to be ITSELF an accepted token is emitted with
// its own correct expectation, because the mapping is defined on the
// value and the row records the value's real expectation.
static U0 PartitionM04()
{
  CUR_PARTITION = "M04_NEIGHBOUR";
  for (I64 i = 0; i < 19; i++) {
    I64 v = TOK_VALUE[i];
    I64 lo = v - 1;
    I64 hi = v + 1;
    I64 elo = EnumOf(lo);
    I64 ehi = EnumOf(hi);
    if (elo < 0) {
      AddInvalid(lo, INIT_A, "the immediate predecessor of an accepted token");
    } else {
      AddRow(lo, 1, elo, INIT_A,
             "the immediate predecessor of an accepted token, itself accepted");
    }
    if (ehi < 0) {
      AddInvalid(hi, INIT_A, "the immediate successor of an accepted token");
    } else {
      AddRow(hi, 1, ehi, INIT_A,
             "the immediate successor of an accepted token, itself accepted");
    }
  }
}

// M05: relevant lexer aliases.
//
// The numeric values that src/lexer.h defines under TWO names.  None of
// them is an accepted binary token, so every one of them is a failure
// case.  Each is emitted ONCE, because the mapping is defined on the
// numeric value and two spellings of one number are one case.
//
//   769  TK_STR / TK_SUPERSCRIPT
//   770  TK_I64 / TK_SUBSCRIPT
//   771  TK_CHAR_CONST / TK_NORMALSCRIPT
static U0 PartitionM05()
{
  CUR_PARTITION = "M05_LEXER_ALIAS";
  AddInvalid(769, INIT_A, "TK_STR and TK_SUPERSCRIPT are the same number 769");
  AddInvalid(770, INIT_A, "TK_I64 and TK_SUBSCRIPT are the same number 770");
  AddInvalid(771, INIT_A, "TK_CHAR_CONST and TK_NORMALSCRIPT are the same number 771");
}

// M06: signed-I64 extremes and their neighbours.
//
// The values are written with an EXACT 64-bit conversion (snprintf
// "%lld"), not with the runtime's 32-bit "%d".
static U0 PartitionM06()
{
  CUR_PARTITION = "M06_SIGNED_EXTREMES";
  I64 lo = -9223372036854775807 - 1;
  I64 hi = 9223372036854775807;
  AddInvalid(lo, INIT_A, "INT64_MIN, the most negative signed 64-bit value");
  AddInvalid(lo + 1, INIT_A, "INT64_MIN plus one");
  AddInvalid(lo + 2, INIT_A, "INT64_MIN plus two");
  AddInvalid(hi - 2, INIT_A, "INT64_MAX minus two");
  AddInvalid(hi - 1, INIT_A, "INT64_MAX minus one");
  AddInvalid(hi, INIT_A, "INT64_MAX, the most positive signed 64-bit value");
}

// M07: duplicate / ambiguous source spellings.
//
// The values that appear under more than one name in the live lexer.h
// are emitted once each: the legacy switch is written on the numeric
// value and cannot distinguish two spellings of one number.
//
// The accepted tokens whose source spelling could be confused with a
// neighbouring case are ALSO emitted here: '=' (61) versus '<' (60)
// and '>' (62), and '&' (38) versus "&&" (783) and '|' (124) versus
// "||" (784).  They are semantically DISTINCT tokens and must not be
// collapsed.
static U0 PartitionM07()
{
  CUR_PARTITION = "M07_AMBIGUOUS_SPELLING";
  AddInvalid(769, INIT_A, "TK_STR and TK_SUPERSCRIPT spell one number");
  AddInvalid(770, INIT_A, "TK_I64 and TK_SUBSCRIPT spell one number");
  AddInvalid(771, INIT_A, "TK_CHAR_CONST and TK_NORMALSCRIPT spell one number");
  AddRow(61, 1, 18, INIT_A, "'=' is distinct from '<' (60) and '>' (62)");
  AddRow(38, 1, 13, INIT_A, "'&' is distinct from '&&' (783)");
  AddRow(124, 1, 15, INIT_A, "'|' is distinct from '||' (784)");
}

// M08: invalid input values that are not recognized operators.
//
// A bounded set of values that are neither accepted tokens, nor their
// immediate neighbours, nor the extremes: the other lexer token
// constants, and a few values from the control-character range.
static U0 PartitionM08()
{
  CUR_PARTITION = "M08_INVALID_INPUT";
  AddInvalid(0, INIT_A, "TK_EOF");
  AddInvalid(768, INIT_A, "TK_IDENT");
  AddInvalid(775, INIT_A, "TK_DEREFERENCE");
  AddInvalid(776, INIT_A, "TK_DBL_COLON");
  AddInvalid(785, INIT_A, "TK_XOR_XOR");
  AddInvalid(786, INIT_A, "TK_SHL_EQU");
  AddInvalid(787, INIT_A, "TK_SHR_EQU");
  AddInvalid(788, INIT_A, "TK_MUL_EQU");
  AddInvalid(789, INIT_A, "TK_DIV_EQU");
  AddInvalid(790, INIT_A, "TK_AND_EQU");
  AddInvalid(791, INIT_A, "TK_XOR_EQU");
  AddInvalid(793, INIT_A, "TK_ADD_EQU");
  AddInvalid(794, INIT_A, "TK_SUB_EQU");
  AddInvalid(802, INIT_A, "TK_MOD_EQU");
  AddInvalid(803, INIT_A, "TK_DOT_DOT");
  AddInvalid(804, INIT_A, "TK_ELLIPSIS");
  AddInvalid(805, INIT_A, "TK_INS_BIN");
  AddInvalid(806, INIT_A, "TK_INS_BIN_SIZE");
  AddInvalid(807, INIT_A, "TK_TKS_NUM");
  AddInvalid(808, INIT_A, "TK_ARROW");
  AddInvalid(809, INIT_A, "TK_PUNCT");
  AddInvalid(816, INIT_A, "TK_PRE_PLUS_PLUS");
  AddInvalid(817, INIT_A, "TK_PRE_MINUS_MINUS");
  AddInvalid(818, INIT_A, "TK_KEYWORD");
  AddInvalid(819, INIT_A, "TK_COMMENT");
  AddInvalid(1, INIT_A, "a control character value");
  AddInvalid(31, INIT_A, "the last control character value");
}

// M09: output storage unchanged on every failure.
//
// Every INVALID token value the fixture contains is re-emitted with the
// SECOND distinct initial output value.  A failure that overwrote the
// output with a hard-coded default would produce the same final value
// on both rows; the two distinct initial values make that visible.
static U0 PartitionM09()
{
  CUR_PARTITION = "M09_OUTPUT_UNCHANGED_ON_FAILURE";
  for (I64 i = 0; i < INV_N; i++) {
    AddRow(INV_VALUE[i], 0, INIT_B, INIT_B,
           "the same invalid token with the second initial output value");
  }
}

// ---------------- Assembly -------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  U8 *out_path = "evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c1/fixture.tsv";
  if (argc > 1) out_path = argv[1];

  LEN = 0;
  ID_N = 0;
  INV_N = 0;
  InitFrozenTable();

  // The partitions run in the canonical order.  M09 depends on the
  // invalid-token registry that the earlier partitions filled.
  PartitionM01();
  PartitionM02();
  PartitionM03();
  PartitionM04();
  PartitionM05();
  PartitionM06();
  PartitionM07();
  PartitionM08();
  PartitionM09();

  // The header block is written into the SAME buffer, BEFORE the rows.
  // The rows are therefore appended after it, so the buffer is built in
  // one pass and written once.
  //
  // To do that, the rows are built into a SECOND buffer and then
  // copied.  The copy is a plain byte move of LEN bytes.
  U8 rows[FIXTURE_BUF];
  I64 row_len = LEN;
  I64 i = 0;
  while (i < row_len) {
    rows[i] = BUF[i];
    i = i + 1;
  }

  LEN = 0;
  BUF[0] = 0;
  U8 *hdr = StrPrint(NULL, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE04\n");
  hdr = StrPrint(hdr, "ACT_PHASE=C2-IMPL\n");
  hdr = StrPrint(hdr, "EVIDENCE_KIND=fixture\n");
  hdr = StrPrint(hdr, "# The canonical fixture for the selected candidate\n");
  hdr = StrPrint(hdr, "# CAND-019 astBinOpFromToken.\n");
  hdr = StrPrint(hdr, "#\n");
  hdr = StrPrint(hdr, "# Schema:\n");
  hdr = StrPrint(hdr, "#   fixture_id <TAB> partition <TAB> token_value <TAB>\n");
  hdr = StrPrint(hdr, "#   expected_success <TAB> expected_output <TAB>\n");
  hdr = StrPrint(hdr, "#   initial_output <TAB> rationale\n");
  hdr = StrPrint(hdr, "#\n");
  hdr = StrPrint(hdr, "# expected_success is 1 for an accepted token and 0 for\n");
  hdr = StrPrint(hdr, "# every other value.  expected_output is the exact enum the\n");
  hdr = StrPrint(hdr, "# legacy function produces on success, and the INITIAL output\n");
  hdr = StrPrint(hdr, "# value on failure (the legacy function leaves it unchanged).\n");
  hdr = StrPrint(hdr, "# initial_output is the value the caller's storage holds\n");
  hdr = StrPrint(hdr, "# BEFORE the call; on failure the output after the call\n");
  hdr = StrPrint(hdr, "# must still equal it.\n");
  hdr = StrPrint(hdr, "#\n");
  hdr = StrPrint(hdr, "# FIXTURE_ROW_COUNT=%d\n", ID_N);
  hdr = StrPrint(hdr, "#\n");

  I64 hdr_len = 0;
  while (hdr[hdr_len] != 0) hdr_len = hdr_len + 1;

  i = 0;
  while (i < hdr_len && LEN < FIXTURE_BUF - 1) {
    BUF[LEN] = hdr[i];
    LEN = LEN + 1;
    i = i + 1;
  }
  i = 0;
  while (i < row_len && LEN < FIXTURE_BUF - 1) {
    BUF[LEN] = rows[i];
    LEN = LEN + 1;
    i = i + 1;
  }
  BUF[LEN] = 0;

  if (!FileWrite(out_path, BUF, LEN, 0x0202)) {
    "FIXTURE_WRITE_FAILED=%s\n", out_path;
    "STATUS=FAIL\n";
    return 1;
  }

  "FIXTURE_PATH=%s\n", out_path;
  "FIXTURE_ROW_COUNT=%d\n", ID_N;
  "FIXTURE_INVALID_TOKEN_COUNT=%d\n", INV_N;
  "FIXTURE_ACCEPTED_TOKEN_COUNT=19\n";
  "STATUS=PASS\n";
  return 0;
}
