// tools/quality/parser-slice05-fixture-producer.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE05 C1.
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
// THE ROW COUNT IS NOT SLICE04's 322 ROWS.  SLICE05's partitions are
// DIFFERENT and are derived from the unary token set, so the counts are
// computed here, not copied.
//
// THE 64-BIT FORMATTER IS LOAD-BEARING
// =====================================
//
// The value columns are written with snprintf("%lld"), NOT with the
// runtime's "%d".  The runtime's "%d" is a 32-bit conversion: it
// prints INT64_MIN as 0 and INT64_MAX as -1.  That is EXACTLY the
// defect the predecessor's correction recorded as D1, and using "%d"
// here would silently destroy the U09 signed-I64 extremes.
//
// The formatter below is the ONE place where a fixture value is turned
// into text, so the conversion cannot be bypassed by accident.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice05-fixture-producer <output.tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAX_ROWS 1024
#define FIXTURE_BUF 524288

// The FROZEN accepted token values and their FROZEN enum values.
//
// These are the 10 mappings MEASURED by executing the REAL legacy
// function (see c1/token-to-enum.tsv).  The token values are the live
// src/lexer.h values; the enum values are the live src/ast.h values.
static I64 TOK_VALUE[10];
static I64 TOK_ENUM[10];

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

// The registry of DISTINCT invalid token values that the partitions
// have produced.  U11 (the failure-preservation partition) consumes it.
static I64 INV_VALUE[MAX_ROWS];
static I64 INV_N;

// The fixture id counter.
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

// Append a ZERO-PADDED unsigned ordinal, at least WIDTH digits wide.
//
// The padding makes the fixture id column lexically sortable, so an
// independent verifier can detect a MISSING or REORDERED row by
// comparing the id column as text, not only as a set.
static I64 app_pad(U8 *dst, I64 cap, I64 v, I64 width)
{
  if (cap <= 0) return 0;
  U8 tmp[32];
  I64 n = 0;
  I64 d = v;
  if (d == 0) { tmp[n] = '0'; n = n + 1; }
  while (d > 0) {
    I64 digit = '0' + (d % 10);
    tmp[n] = digit;
    n = n + 1;
    d = d / 10;
  }
  I64 total = 0;
  for (I64 i = n; i < width; i++) {
    dst[total] = '0'; total = total + 1;
  }
  for (I64 i = n - 1; i >= 0; i--) {
    dst[total] = tmp[i]; total = total + 1;
  }
  dst[total] = 0;
  return total;
}

// ---------------- The frozen table -----------------------------------------

static U0 InitFrozenTable()
{
  TOK_VALUE[0] = 816; TOK_ENUM[0] = 2;   // TK_PRE_PLUS_PLUS   -> PRE_INC
  TOK_VALUE[1] = 817; TOK_ENUM[1] = 3;   // TK_PRE_MINUS_MINUS -> PRE_DEC
  TOK_VALUE[2] = 773; TOK_ENUM[2] = 0;   // TK_PLUS_PLUS       -> POST_INC
  TOK_VALUE[3] = 774; TOK_ENUM[3] = 1;   // TK_MINUS_MINUS     -> POST_DEC
  TOK_VALUE[4] = 43;  TOK_ENUM[4] = 4;   // '+'                -> PLUS
  TOK_VALUE[5] = 45;  TOK_ENUM[5] = 5;   // '-'                -> MINUS
  TOK_VALUE[6] = 126; TOK_ENUM[6] = 7;   // '~'                -> BIT_NOT
  TOK_VALUE[7] = 33;  TOK_ENUM[7] = 6;   // '!'                -> LOG_NOT
  TOK_VALUE[8] = 38;  TOK_ENUM[8] = 8;   // '&'                -> ADDR_OF
  TOK_VALUE[9] = 42;  TOK_ENUM[9] = 9;   // '*'                -> DEREF
}

// Is the value one of the accepted tokens?
static I64 IsAccepted(I64 v)
{
  for (I64 i = 0; i < 10; i++) if (TOK_VALUE[i] == v) return 1;
  return 0;
}

// Register an invalid token value (if not already registered).
static U0 RegisterInvalid(I64 v)
{
  if (IsAccepted(v)) return;
  for (I64 i = 0; i < INV_N; i++) if (INV_VALUE[i] == v) return;
  if (INV_N < MAX_ROWS) { INV_VALUE[INV_N] = v; INV_N = INV_N + 1; }
}

// ---------------- The row emitter ------------------------------------------

// Emit one fixture row.
//
//   fixture_id <TAB> partition <TAB> token_value <TAB> expected_success
//              <TAB> expected_output <TAB> initial_output <TAB> rationale
static U0 EmitRow(U8 *partition, I64 token_value, I64 expected_success,
                  I64 expected_output, I64 initial_output, U8 *rationale)
{
  if (ID_N >= MAX_ROWS) return;
  I64 n = 0;
  ID_N = ID_N + 1;

  // The fixture id is the canonical "F" + zero-padded ordinal, so the
  // id column is lexically sortable and unmistakably an id.
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "F"); LEN = LEN + n;
  n = app_pad(BUF + LEN, FIXTURE_BUF - LEN, ID_N, 3); LEN = LEN + n;
  n = app_tab(BUF + LEN, FIXTURE_BUF - LEN); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, partition); LEN = LEN + n;
  n = app_tab(BUF + LEN, FIXTURE_BUF - LEN); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, token_value); LEN = LEN + n;
  n = app_tab(BUF + LEN, FIXTURE_BUF - LEN); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, expected_success); LEN = LEN + n;
  n = app_tab(BUF + LEN, FIXTURE_BUF - LEN); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, expected_output); LEN = LEN + n;
  n = app_tab(BUF + LEN, FIXTURE_BUF - LEN); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, initial_output); LEN = LEN + n;
  n = app_tab(BUF + LEN, FIXTURE_BUF - LEN); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, rationale); LEN = LEN + n;
  n = app_str(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
}

// Emit an ACCEPTED row: the mapped enum is the expected output.
static U0 EmitAccepted(U8 *partition, I64 token_value, I64 enum_value,
                        I64 initial_output, U8 *rationale)
{
  EmitRow(partition, token_value, 1, enum_value, initial_output, rationale);
}

// Emit a REJECTED row: the output must be UNCHANGED.
static U0 EmitRejected(U8 *partition, I64 token_value, I64 initial_output,
                        U8 *rationale)
{
  RegisterInvalid(token_value);
  EmitRow(partition, token_value, 0, initial_output, initial_output, rationale);
}

// ---------------- The partitions -------------------------------------------
//
// U01  All ten accepted unary tokens.
// U02  Accepted tokens with alternate initialized outputs.
// U03  Rejected printable ASCII values.
// U04  Neighbors of accepted token constants.
// U05  Prefix/postfix distinction.
// U06  Unary plus/minus distinction.
// U07  Address-of/dereference distinction.
// U08  Lexer aliases and equal numeric values.
// U09  Signed 64-bit boundary values.
// U10  Unrecognized lexer tokens.
// U11  Failure preserves original output.
// U12  Real production caller behavior.

// U01 -- every accepted token mapped to its exact enum.
static U0 PartitionU01()
{
  for (I64 i = 0; i < 10; i++) {
    EmitAccepted("U01_ACCEPTED_TOKEN", TOK_VALUE[i], TOK_ENUM[i], INIT_A,
                 "an accepted unary token maps to its exact enum");
  }
}

// U02 -- the same mapping with a DIFFERENT initial output value.
static U0 PartitionU02()
{
  for (I64 i = 0; i < 10; i++) {
    EmitAccepted("U02_ALTERNATE_INITIAL_OUTPUT", TOK_VALUE[i], TOK_ENUM[i],
                 INIT_B,
                 "the same mapping with a different initial output value");
  }
}

// U03 -- every printable ASCII value that is NOT an accepted token.
static U0 PartitionU03()
{
  for (I64 v = 32; v <= 126; v++) {
    if (IsAccepted(v)) continue;
    EmitRejected("U03_REJECTED_PRINTABLE_ASCII", v, INIT_A,
                 "an unrecognized printable ASCII token value");
  }
}

// U04 -- the immediate neighbour of every accepted token constant.
//
// Both directions are taken, so a classifier that wrongly accepted a
// neighbour (or wrongly rejected one) is detected.
//
// IMPORTANT: a neighbour of one accepted constant can ITSELF be an
// accepted constant.  TK_PRE_MINUS_MINUS is 817 and TK_PRE_PLUS_PLUS
// is 816, so 816 is the immediate predecessor of 817 AND an accepted
// token in its own right.  The partition therefore emits the neighbour
// as a REJECTION only when it is genuinely NOT accepted; otherwise it
// emits it as an ACCEPTED row with its own exact enum.  Emitting a
// rejection for an accepted value would make the fixture contradict
// the legacy function, which the oracle differential would (correctly)
// report as a mismatch.
static U0 PartitionU04()
{
  for (I64 i = 0; i < 10; i++) {
    I64 v = TOK_VALUE[i];
    for (I64 d = 0; d < 2; d++) {
      I64 n = v - 1 + d * 2;
      if (IsAccepted(n)) {
        // The neighbour is itself accepted: assert its exact mapping.
        I64 e = 0;
        for (I64 k = 0; k < 10; k++) if (TOK_VALUE[k] == n) e = TOK_ENUM[k];
        EmitAccepted("U04_NEIGHBOUR_ACCEPTED", n, e, INIT_A,
                     "the neighbour of an accepted constant is itself accepted");
      } else {
        EmitRejected("U04_NEIGHBOUR", n, INIT_A,
                     "the immediate neighbour of an accepted token constant");
      }
    }
  }
}

// U05 -- the prefix/postfix distinction.
//
// The four increment/decrement constants are close enough in value
// (773, 774, 816, 817) that a classifier that confuses the prefix and
// postfix forms must be detected.  Each of the four is asserted
// EXACTLY, and the neighbouring constants are present as rejections,
// so the distinction is exercised rather than assumed.
static U0 PartitionU05()
{
  EmitAccepted("U05_PREFIX_POSTFIX", 816, 2, INIT_A,
               "prefix increment maps to the prefix increment enum");
  EmitAccepted("U05_PREFIX_POSTFIX", 817, 3, INIT_A,
               "prefix decrement maps to the prefix decrement enum");
  EmitAccepted("U05_PREFIX_POSTFIX", 773, 0, INIT_A,
               "postfix increment maps to the postfix increment enum");
  EmitAccepted("U05_PREFIX_POSTFIX", 774, 1, INIT_A,
               "postfix decrement maps to the postfix decrement enum");
  EmitRejected("U05_PREFIX_POSTFIX", 772, INIT_A,
               "the neighbour of the postfix increment constant");
  EmitRejected("U05_PREFIX_POSTFIX", 818, INIT_A,
               "the neighbour of the prefix decrement constant");
}

// U06 -- the unary plus/minus distinction.
static U0 PartitionU06()
{
  EmitAccepted("U06_PLUS_MINUS", 43, 4, INIT_A,
               "unary plus maps to the unary plus enum");
  EmitAccepted("U06_PLUS_MINUS", 45, 5, INIT_A,
               "unary minus maps to the unary minus enum");
  EmitRejected("U06_PLUS_MINUS", 44, INIT_A,
               "the value between unary plus and unary minus");
}

// U07 -- the address-of/dereference distinction.
static U0 PartitionU07()
{
  EmitAccepted("U07_ADDR_OF_DEREF", 38, 8, INIT_A,
               "address-of maps to the address-of enum");
  EmitAccepted("U07_ADDR_OF_DEREF", 42, 9, INIT_A,
               "dereference maps to the dereference enum");
  EmitRejected("U07_ADDR_OF_DEREF", 39, INIT_A,
               "a punctuator between address-of and dereference");
  EmitRejected("U07_ADDR_OF_DEREF", 40, INIT_A,
               "a punctuator between address-of and dereference");
  EmitRejected("U07_ADDR_OF_DEREF", 41, INIT_A,
               "a punctuator between address-of and dereference");
}

// The live src/lexer.h token constants, in their COMPILED numeric
// values.  Several of them share a numeric value with another
// constant; that aliasing is exactly what U08 exercises.
#define TK_EOF_V          0
#define TK_IDENT_V        768
#define TK_ALIAS_A_V      769
#define TK_ALIAS_B_V      770
#define TK_ALIAS_C_V      771
#define TK_F64_V          772
#define TK_PLUS_PLUS_V    773
#define TK_MINUS_MINUS_V  774
#define TK_DEREFERENCE_V  775
#define TK_DBL_COLON_V    776
#define TK_SHL_V          777
#define TK_SHR_V          778
#define TK_EQU_EQU_V      779
#define TK_NOT_EQU_V      780
#define TK_LESS_EQU_V     781
#define TK_GREATER_EQU_V  782
#define TK_AND_AND_V      783
#define TK_OR_OR_V        784
#define TK_XOR_XOR_V      785
#define TK_SHL_EQU_V      786
#define TK_SHR_EQU_V      787
#define TK_MUL_EQU_V      788
#define TK_DIV_EQU_V      789
#define TK_AND_EQU_V      790
#define TK_OR_EQU_V       791
#define TK_XOR_EQU_V      792
#define TK_ADD_EQU_V      793
#define TK_SUB_EQU_V      794
#define TK_IF_V           795
#define TK_IFDEF_V        796
#define TK_IFNDEF_V       797
#define TK_IFAOT_V        798
#define TK_IFJIT_V        799
#define TK_ENDIF_V        800
#define TK_ELSE_V         801
#define TK_MOD_EQU_V      802
#define TK_DOT_DOT_V      803
#define TK_ELLIPSIS_V     804
#define TK_INS_BIN_V      805
#define TK_INS_BIN_SIZE_V 806
#define TK_TKS_NUM_V      807
#define TK_ARROW_V        808
#define TK_PUNCT_V        809
#define TK_PRE_PLUS_PLUS_V   816
#define TK_PRE_MINUS_MINUS_V 817
#define TK_KEYWORD_V      818
#define TK_COMMENT_V      819

// U08 -- the lexer aliases: constants that share a numeric value.
//
// Each aliased numeric value is asserted ONCE (the classifier cannot
// distinguish two spellings of the same number -- it decides on the
// NUMBER alone), and every one of them is a REJECTED value, because
// none of them is an accepted unary token.
//
// The alias pairs are:
//   769 = TK_SUPERSCRIPT = TK_STR
//   770 = TK_SUBSCRIPT   = TK_I64
//   771 = TK_NORMALSCRIPT = TK_CHAR_CONST
static U0 PartitionU08()
{
  EmitRejected("U08_LEXER_ALIAS", TK_ALIAS_A_V, INIT_A,
               "an aliased lexer constant value (SUPERSCRIPT == STR)");
  EmitRejected("U08_LEXER_ALIAS", TK_ALIAS_B_V, INIT_A,
               "an aliased lexer constant value (SUBSCRIPT == I64)");
  EmitRejected("U08_LEXER_ALIAS", TK_ALIAS_C_V, INIT_A,
               "an aliased lexer constant value (NORMALSCRIPT == CHAR_CONST)");
}

// U09 -- the signed 64-bit extremes and their neighbours.
//
// THE VALUES ARE WRITTEN WITH THE EXACT 64-BIT FORMATTER, so INT64_MIN
// and INT64_MAX survive as themselves.
//
// THE MOST NEGATIVE VALUE IS REACHED BY SUBTRACTION, NOT BY A LITERAL.
// The direct literal -9223372036854775808 does NOT evaluate to
// INT64_MIN in this language: the positive magnitude 9223372036854775808
// is one past INT64_MAX, so the parser's constant folding wraps it to
// INT64_MIN and the unary minus then wraps it BACK to
// -9223372036854775807.  That was MEASURED, not assumed:
//
//   I64 a = -9223372036854775808;   ->  -9223372036854775807
//   I64 d = -9223372036854775807 - 1; ->  -9223372036854775808
//
// The subtraction form is exact, so it is the one used here.  This is
// exactly the class of defect the ACT forbids ("no numeric fragments
// extracted from symbolic identifiers" and no silent 64-bit
// truncation): the boundary values must be the REAL boundaries.
#define I64_MAX_V  9223372036854775807
#define I64_MIN_V  (-9223372036854775807 - 1)

static U0 PartitionU09()
{
  EmitRejected("U09_SIGNED_I64_BOUNDARY", I64_MIN_V, INIT_A,
               "the most negative signed 64-bit value");
  EmitRejected("U09_SIGNED_I64_BOUNDARY", I64_MIN_V + 1, INIT_A,
               "one above the most negative signed 64-bit value");
  EmitRejected("U09_SIGNED_I64_BOUNDARY", I64_MIN_V + 2, INIT_A,
               "two above the most negative signed 64-bit value");
  EmitRejected("U09_SIGNED_I64_BOUNDARY", I64_MAX_V - 2, INIT_A,
               "two below the most positive signed 64-bit value");
  EmitRejected("U09_SIGNED_I64_BOUNDARY", I64_MAX_V - 1, INIT_A,
               "one below the most positive signed 64-bit value");
  EmitRejected("U09_SIGNED_I64_BOUNDARY", I64_MAX_V, INIT_A,
               "the most positive signed 64-bit value");
}

// U10 -- the lexer token constants that are NOT accepted unary tokens.
//
// The two accepted lexer constants (TK_PRE_PLUS_PLUS and
// TK_PRE_MINUS_MINUS) are excluded, because they ARE accepted.
static U0 PartitionU10()
{
  I64 toks[45];
  I64 n = 0;

  toks[n] = TK_EOF_V;           n = n + 1;
  toks[n] = TK_IDENT_V;         n = n + 1;
  toks[n] = TK_F64_V;           n = n + 1;
  toks[n] = TK_DEREFERENCE_V;   n = n + 1;
  toks[n] = TK_DBL_COLON_V;     n = n + 1;
  toks[n] = TK_SHL_V;           n = n + 1;
  toks[n] = TK_SHR_V;           n = n + 1;
  toks[n] = TK_EQU_EQU_V;       n = n + 1;
  toks[n] = TK_NOT_EQU_V;       n = n + 1;
  toks[n] = TK_LESS_EQU_V;      n = n + 1;
  toks[n] = TK_GREATER_EQU_V;   n = n + 1;
  toks[n] = TK_AND_AND_V;       n = n + 1;
  toks[n] = TK_OR_OR_V;         n = n + 1;
  toks[n] = TK_XOR_XOR_V;       n = n + 1;
  toks[n] = TK_SHL_EQU_V;       n = n + 1;
  toks[n] = TK_SHR_EQU_V;       n = n + 1;
  toks[n] = TK_MUL_EQU_V;       n = n + 1;
  toks[n] = TK_DIV_EQU_V;       n = n + 1;
  toks[n] = TK_AND_EQU_V;       n = n + 1;
  toks[n] = TK_OR_EQU_V;        n = n + 1;
  toks[n] = TK_XOR_EQU_V;       n = n + 1;
  toks[n] = TK_ADD_EQU_V;       n = n + 1;
  toks[n] = TK_SUB_EQU_V;       n = n + 1;
  toks[n] = TK_IF_V;            n = n + 1;
  toks[n] = TK_IFDEF_V;         n = n + 1;
  toks[n] = TK_IFNDEF_V;        n = n + 1;
  toks[n] = TK_IFAOT_V;         n = n + 1;
  toks[n] = TK_IFJIT_V;         n = n + 1;
  toks[n] = TK_ENDIF_V;         n = n + 1;
  toks[n] = TK_ELSE_V;          n = n + 1;
  toks[n] = TK_MOD_EQU_V;       n = n + 1;
  toks[n] = TK_DOT_DOT_V;       n = n + 1;
  toks[n] = TK_ELLIPSIS_V;      n = n + 1;
  toks[n] = TK_INS_BIN_V;       n = n + 1;
  toks[n] = TK_INS_BIN_SIZE_V;  n = n + 1;
  toks[n] = TK_TKS_NUM_V;       n = n + 1;
  toks[n] = TK_ARROW_V;         n = n + 1;
  toks[n] = TK_PUNCT_V;         n = n + 1;
  toks[n] = TK_KEYWORD_V;       n = n + 1;
  toks[n] = TK_COMMENT_V;       n = n + 1;

  for (I64 i = 0; i < n; i++) {
    EmitRejected("U10_UNRECOGNIZED_LEXER_TOKEN", toks[i], INIT_A,
                 "a lexer token constant that is not a unary operator");
  }
}

// U11 -- the output storage is UNCHANGED on every failure.
//
// One row per DISTINCT invalid token value that the earlier
// partitions produced, with the SECOND distinct initial output value.
// This is the partition that proves the "failure does not overwrite"
// property for EVERY rejected value, not only for a sample.
static U0 PartitionU11()
{
  for (I64 i = 0; i < INV_N; i++) {
    EmitRejected("U11_FAILURE_PRESERVES_OUTPUT", INV_VALUE[i], INIT_B,
                 "a rejected token with the second initial output value");
  }
}

// U12 -- the real production caller's behaviour.
//
// The production callers are src/prslib.c:1450 (_parseExpr, the
// postfix path) and src/prslib.c:1757 (_parseUnaryExpr, the prefix
// path).  Both call sites consume the return value as a success flag
// and both are exercised here with the tokens those call sites
// actually see, plus the tokens the callers must REJECT (a rejected
// token makes the prefix caller rewind and fall back to the postfix
// path, so the failure branch is load-bearing in the parser).
static U0 PartitionU12()
{
  // The postfix caller (prslib.c:1450) sees TK_PLUS_PLUS and
  // TK_MINUS_MINUS.
  EmitAccepted("U12_PRODUCTION_CALLER", TK_PLUS_PLUS_V, 0, INIT_A,
               "the postfix production caller receives the postfix increment");
  EmitAccepted("U12_PRODUCTION_CALLER", TK_MINUS_MINUS_V, 1, INIT_A,
               "the postfix production caller receives the postfix decrement");
  // The prefix caller (prslib.c:1757) sees the ordinary punctuators
  // and the prefix constants.
  EmitAccepted("U12_PRODUCTION_CALLER", 43, 4, INIT_A,
               "the prefix production caller receives unary plus");
  EmitAccepted("U12_PRODUCTION_CALLER", 45, 5, INIT_A,
               "the prefix production caller receives unary minus");
  EmitAccepted("U12_PRODUCTION_CALLER", 126, 7, INIT_A,
               "the prefix production caller receives bitwise not");
  EmitAccepted("U12_PRODUCTION_CALLER", 33, 6, INIT_A,
               "the prefix production caller receives logical not");
  EmitAccepted("U12_PRODUCTION_CALLER", 38, 8, INIT_A,
               "the prefix production caller receives address-of");
  EmitAccepted("U12_PRODUCTION_CALLER", 42, 9, INIT_A,
               "the prefix production caller receives dereference");
  EmitAccepted("U12_PRODUCTION_CALLER", TK_PRE_PLUS_PLUS_V, 2, INIT_A,
               "the prefix production caller receives the prefix increment");
  EmitAccepted("U12_PRODUCTION_CALLER", TK_PRE_MINUS_MINUS_V, 3, INIT_A,
               "the prefix production caller receives the prefix decrement");
  // The prefix caller must REJECT a punctuator that is not a unary
  // operator; on rejection it rewinds and falls back.
  EmitRejected("U12_PRODUCTION_CALLER", 40, INIT_A,
               "the prefix production caller rejects an opening parenthesis");
  EmitRejected("U12_PRODUCTION_CALLER", 41, INIT_A,
               "the prefix production caller rejects a closing parenthesis");
  EmitRejected("U12_PRODUCTION_CALLER", 91, INIT_A,
               "the prefix production caller rejects an opening bracket");
  EmitRejected("U12_PRODUCTION_CALLER", 93, INIT_A,
               "the prefix production caller rejects a closing bracket");
}

// ---------------- The main -------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "usage: parser-slice05-fixture-producer <output.tsv>\n";
    return 2;
  }
  U8 *out_path = argv[1];

  InitFrozenTable();
  ID_N = 0;
  INV_N = 0;
  LEN = 0;
  BUF[0] = 0;

  // The partitions run in the canonical order.  U11 depends on the
  // invalid-token registry that the earlier partitions filled.
  PartitionU01();
  PartitionU02();
  PartitionU03();
  PartitionU04();
  PartitionU05();
  PartitionU06();
  PartitionU07();
  PartitionU08();
  PartitionU09();
  PartitionU10();
  PartitionU11();
  PartitionU12();

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
  U8 *hdr = StrPrint(NULL, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE05\n");
  hdr = StrPrint(hdr, "ACT_PHASE=C1-EVIDENCE\n");
  hdr = StrPrint(hdr, "EVIDENCE_KIND=fixture\n");
  hdr = StrPrint(hdr, "# The canonical fixture for the selected candidate\n");
  hdr = StrPrint(hdr, "# CAND-020 astUnaryOpFromToken.\n");
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
  "FIXTURE_ACCEPTED_TOKEN_COUNT=10\n";
  "STATUS=PASS\n";
  return 0;
}
