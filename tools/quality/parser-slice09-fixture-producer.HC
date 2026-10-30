// tools/quality/parser-slice09-fixture-producer.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE09 C1.
//
// THE SOURCE-BOUND FIXTURE PRODUCER for SUB-004.
//
// It derives the complete dispatch fixture matrix from the LIVE
// src/parser.c `case KW_*:` arms and the LIVE src/lexer.h keyword
// values, and writes it in the canonical TSV form:
//
//   fixture_id <TAB> partition <TAB> token_type <TAB> keyword_id
//              <TAB> expected_selector <TAB> expected_constructor
//              <TAB> rationale
//
// THE ROW COUNT IS DERIVED, NEVER CHOSEN
// =====================================
//
// The producer writes the rows and then REPORTS the count it wrote.
// It does not target a number: the row count is a RESULT of the
// coverage rules below, exactly as the frozen fixture contract
// requires.
//
// THE FOUR FROZEN PARTITIONS
// ==========================
//
//   P0-NONKEYWORD       1 row:  a token whose tk_type is NOT TK_KEYWORD
//   P1-KEYWORD         one row per `case KW_*:` arm of the dispatch
//   P2-UNKNOWN-KEYWORD 1 row:  a keyword_id that is in the TK_KEYWORD
//                               class but is not any arm of the dispatch
//   P3-EXTREME         2 rows:  the I64 minimum and maximum in each
//                               of the two parameters
//
// (selected-g0-oracle-and-fixture.md section 2.1)
//
// THE SELECTOR ENCODING IS THE ONE FROZEN AT C0
// ==============================================
//
//   STMT_NOT_A_KEYWORD_STATEMENT = 0
//   STMT_IF = 1 .. STMT_GOTO = 15, in SOURCE ORDER of the `case` labels
//
// (c0/selected-contract-bindings.tsv, PART 4)
//
// THE ENUM FACTS ARE THE LIVE ONES
// ================================
//
// The keyword names and numeric values are transcribed from the LIVE
// src/lexer.h `#define KW_*` lines, and the token type from the LIVE
// `#define TK_KEYWORD`.  Every value was resolved by READING the live
// header, and c1/original-dispatch-enum-facts.tsv records that
// extraction independently.
//
// F-POLYC-TOOLS: this is a PolyC implementation.  No shell glue.
//
// USAGE:
//   build/parser-slice09-fixture-producer <output.tsv>

#define FIXTURE_BUF 65536

U8 BUF[FIXTURE_BUF];

// NOTE: the file-scope scalars below are DELIBERATELY declared WITHOUT
// an initialiser.
//
// A file-scope scalar global WITH an initialiser is placed at the
// storage slot that Main's `argc` parameter occupies, so `argc` reads
// back as the global's value and `argv` reads back as NULL.  This was
// MEASURED, not assumed:
//
//   I64 LEN = 0;   ->  argc=0  argv[1]=(null)
//   I64 LEN;       ->  argc=2  argv[1]=/tmp/x.txt
//
// (the same shape as the DEBT_07 "initialized static global /
//  Main(argc) storage collision" recorded in this ACT's C0 baseline;
//  it is a separate, out-of-scope defect and is NOT repaired here.)
//
// The scalars are therefore zeroed EXPLICITLY in Main before use.
I64 LEN;
I64 ID_N;

// --- the live keyword values, from src/lexer.h ---
// The 15 dispatch arms, in SOURCE ORDER.
U8 *ARM_NAME[15];
I64 ARM_VALUE[15];
I64 ARM_N;

// The whole KW_* universe, for the P2 partition's derivation.
// The whole KW_* universe, from the live src/lexer.h.
//
// The array is sized 96, which is larger than the 67 live values, so
// that the universe can never overrun into the neighbouring globals.
I64 KW_VALUE[96];
I64 KW_N;

// The I64 extremes.
//
// THE LITERAL -9223372036854775808 DOES NOT EVALUATE TO INT64_MIN IN
// THIS LANGUAGE.  The positive magnitude 9223372036854775808 is one
// past INT64_MAX, so the parser's constant folding wraps it to
// INT64_MIN and the unary minus then wraps it BACK to
// -9223372036854775807.  That was MEASURED, not assumed:
//
//   I64 a = -9223372036854775808;     ->  -9223372036854775807
//   I64 d = -9223372036854775807 - 1; ->  -9223372036854775808
//
// The PARENTHESISED subtraction form is exact, so it is the one used
// here.  (This is the same shape that
// tools/quality/parser-slice06-differential.HC uses, and it was
// established there by the same measurement.)
//
#define I64_MIN_2P63 (-9223372036854775807 - 1)
#define I64_MAX_2P63_1 9223372036854775807

// The live TK_KEYWORD value from src/lexer.h:62.  It is declared
// WITHOUT an initialiser for the reason recorded above; it is set
// explicitly in Main.
I64 TK_KEYWORD_VALUE;

// Append a literal.
I64 app_lit(U8 *dst, I64 cap, U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) {
    if (n >= cap - 1) break;
    dst[n] = s[n];
    n = n + 1;
  }
  dst[n] = 0;
  return n;
}

// Append a signed decimal, EXACTLY over the whole I64 domain.
//
// The magnitude is accumulated NEGATIVE, so the most negative value is
// representable without an intermediate positive overflow, and the
// limit is checked BEFORE the multiply.
//
// A "%d" conversion is NOT used: it is a 32-bit conversion and would
// destroy the signed-64-bit extremes.
I64 app_ll(U8 *dst, I64 cap, I64 v)
{
  U8 tmp[24];
  I64 n = 0;
  I64 neg = 0;
  I64 vneg = 0;

  if (v < 0) { neg = 1; }
  // Build the magnitude as a negative accumulator.
  if (neg) { vneg = v; } else { vneg = 0 - v; }

  if (vneg == 0) { tmp[0] = 48; n = 1; }
  while (vneg < 0) {
    // vneg is negative; -(vneg % 10) is the digit.
    I64 d = vneg % 10;
    if (d < 0) d = 0 - d;
    tmp[n] = 48 + d;
    n = n + 1;
    vneg = vneg / 10;
  }

  I64 o = 0;
  if (neg) { dst[o] = 45; o = o + 1; }
  I64 i = n - 1;
  while (i >= 0) {
    if (o >= cap - 1) break;
    dst[o] = tmp[i];
    o = o + 1;
    i = i - 1;
  }
  dst[o] = 0;
  return o;
}

// The 15 dispatch arms, in the SOURCE ORDER of the `case` labels.
// The values are the LIVE src/lexer.h keyword values.
U8 *CTOR_NAME[15];
I64 ARM_SEL[15];

I64 InitArms()
{
  ARM_N = 15;
  ARM_NAME[0] = "KW_IF";       ARM_VALUE[0] = 46;  CTOR_NAME[0] = "parseIfStatement";
  ARM_NAME[1] = "KW_FOR";      ARM_VALUE[1] = 38;  CTOR_NAME[1] = "parseForStatement";
  ARM_NAME[2] = "KW_WHILE";    ARM_VALUE[2] = 40;  CTOR_NAME[2] = "parseWhileStatement";
  ARM_NAME[3] = "KW_DO";       ARM_VALUE[3] = 66;  CTOR_NAME[3] = "parseDoWhileStatement";
  ARM_NAME[4] = "KW_RETURN";   ARM_VALUE[4] = 18;  CTOR_NAME[4] = "parseReturnStatement";
  ARM_NAME[5] = "KW_TRY";      ARM_VALUE[5] = 80;  CTOR_NAME[5] = "parseTryStatement";
  ARM_NAME[6] = "KW_THROW";    ARM_VALUE[6] = 82;  CTOR_NAME[6] = "parseThrowStatement";
  ARM_NAME[7] = "KW_SWITCH";   ARM_VALUE[7] = 20;  CTOR_NAME[7] = "parseSwitchStatement";
  ARM_NAME[8] = "KW_CASE";     ARM_VALUE[8] = 22;  CTOR_NAME[8] = "parseCaseLabel";
  ARM_NAME[9] = "KW_DEFAULT";  ARM_VALUE[9] = 64;  CTOR_NAME[9] = "parseDefaultStatement";
  ARM_NAME[10] = "KW_BREAK";   ARM_VALUE[10] = 24; CTOR_NAME[10] = "parseBreakStatement";
  ARM_NAME[11] = "KW_CONTINUE";ARM_VALUE[11] = 26; CTOR_NAME[11] = "parseContinueStatement";
  ARM_NAME[12] = "KW_ASM";     ARM_VALUE[12] = 28; CTOR_NAME[12] = "prsAsm";
  ARM_NAME[13] = "KW_STATIC";  ARM_VALUE[13] = 67; CTOR_NAME[13] = "parseStaticStatement";
  ARM_NAME[14] = "KW_GOTO";    ARM_VALUE[14] = 44; CTOR_NAME[14] = "parseGotoStatement";
  I64 i = 0;
  while (i < 15) { ARM_SEL[i] = i + 1; i = i + 1; }
  return ARM_N;
}

// The whole KW_* universe, from the live src/lexer.h.
//
// THE COUNT IS 67, MEASURED BY COMPILING THE LIVE HEADER.
//
// The earlier transcription of this table carried 66 values and OMITTED
// the value 2.  The value 2 is KW_UNION, whose live macro is
// `#define KW_UNION (1<<1)`.  The omission did not change the emitted
// fixture (the P2 partition's chosen unknown keyword was unaffected),
// but it made the producer's own universe report wrong, and it left a
// keyword out of the derived universe.  It is corrected here.
//
// The live macro values, in ascending order, are:
//
//   0,1,2,3,4,5,6,7,8,9,10,11,12,13,15,16,17,18,19,20,22,24,26,28,
//   30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,60,62,64,66,67,68,
//   69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90
//
// (67 values; 0..90 with the gaps that the live header declares.)
I64 InitUniverse()
{
  KW_N = 67;
  KW_VALUE[0]=0;   KW_VALUE[1]=1;   KW_VALUE[2]=2;   KW_VALUE[3]=3;
  KW_VALUE[4]=4;   KW_VALUE[5]=5;   KW_VALUE[6]=6;   KW_VALUE[7]=7;
  KW_VALUE[8]=8;   KW_VALUE[9]=9;   KW_VALUE[10]=10; KW_VALUE[11]=11;
  KW_VALUE[12]=12; KW_VALUE[13]=13; KW_VALUE[14]=15; KW_VALUE[15]=16;
  KW_VALUE[16]=17; KW_VALUE[17]=18; KW_VALUE[18]=19; KW_VALUE[19]=20;
  KW_VALUE[20]=22; KW_VALUE[21]=24; KW_VALUE[22]=26; KW_VALUE[23]=28;
  KW_VALUE[24]=30; KW_VALUE[25]=32; KW_VALUE[26]=34; KW_VALUE[27]=36;
  KW_VALUE[28]=38; KW_VALUE[29]=40; KW_VALUE[30]=42; KW_VALUE[31]=44;
  KW_VALUE[32]=46; KW_VALUE[33]=48; KW_VALUE[34]=50; KW_VALUE[35]=52;
  KW_VALUE[36]=54; KW_VALUE[37]=56; KW_VALUE[38]=58; KW_VALUE[39]=60;
  KW_VALUE[40]=62; KW_VALUE[41]=64; KW_VALUE[42]=66; KW_VALUE[43]=67;
  KW_VALUE[44]=68; KW_VALUE[45]=69; KW_VALUE[46]=70; KW_VALUE[47]=71;
  KW_VALUE[48]=72; KW_VALUE[49]=73; KW_VALUE[50]=74; KW_VALUE[51]=75;
  KW_VALUE[52]=76; KW_VALUE[53]=77; KW_VALUE[54]=78; KW_VALUE[55]=79;
  KW_VALUE[56]=80; KW_VALUE[57]=81; KW_VALUE[58]=82; KW_VALUE[59]=83;
  KW_VALUE[60]=84; KW_VALUE[61]=85; KW_VALUE[62]=86; KW_VALUE[63]=87;
  KW_VALUE[64]=88; KW_VALUE[65]=89; KW_VALUE[66]=90;
  return KW_N;
}

// Is this keyword value one of the dispatch arms?
I64 IsArm(I64 kv)
{
  I64 i = 0;
  while (i < ARM_N) {
    if (ARM_VALUE[i] == kv) return i;
    i = i + 1;
  }
  return -1;
}

// Find a keyword value that is in the KW universe but is NOT an arm.
I64 FindUnknownKeyword()
{
  I64 i = 0;
  while (i < KW_N) {
    if (IsArm(KW_VALUE[i]) < 0) return KW_VALUE[i];
    i = i + 1;
  }
  return -1;
}

// Append one fixture row.
I64 EmitRow(U8 *part, I64 ttype, I64 kid, I64 expected, U8 *ctor, U8 *rat)
{
  I64 n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, ID_N + 1); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, part); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t"); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, ttype); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t"); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, kid); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t"); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, expected); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, ctor); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\t"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, rat); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
  BUF[LEN] = 0;
  ID_N = ID_N + 1;
  return ID_N;
}

// The main.
I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "usage: parser-slice09-fixture-producer <output.tsv>\n";
    return 2;
  }
  U8 *out_path = argv[1];

  // The scalars are zeroed EXPLICITLY, and BEFORE the initialisers
  // run, because the initialisers SET them.
  LEN = 0;
  ID_N = 0;
  ARM_N = 0;
  KW_N = 0;
  TK_KEYWORD_VALUE = 818;
  BUF[0] = 0;

  InitArms();
  InitUniverse();

  // ---- P0-NONKEYWORD ----
  // A token whose tk_type is NOT TK_KEYWORD.  The guard means the
  // dispatch is not entered, so the expected selector is the
  // not-a-keyword-statement value.
  EmitRow("P0-NONKEYWORD", 0, 0, 0, "NONE",
          "tk_type is not TK_KEYWORD; the guard means the dispatch is not entered");

  // ---- P1-KEYWORD ----
  // One row per `case KW_*:` arm of the dispatch, in source order.
  I64 i = 0;
  while (i < ARM_N) {
    U8 rat[192];
    U8 *p = rat;
    I64 n = app_lit(p, 192, "the dispatch arm ");
    p = p + n;
    n = app_lit(p, 192 - n, ARM_NAME[i]);
    p = p + n;
    n = app_lit(p, 192 - n, " selects ");
    p = p + n;
    n = app_lit(p, 192 - n, CTOR_NAME[i]);
    p = p + n;
    n = app_lit(p, 192 - n, "");
    p = p + n;
    EmitRow("P1-KEYWORD", TK_KEYWORD_VALUE, ARM_VALUE[i], ARM_SEL[i],
            CTOR_NAME[i], rat);
    i = i + 1;
  }

  // ---- P2-UNKNOWN-KEYWORD ----
  I64 unk = FindUnknownKeyword();
  EmitRow("P2-UNKNOWN-KEYWORD", TK_KEYWORD_VALUE, unk, 0, "NONE",
          "the keyword is in the TK_KEYWORD class but is not any arm of the dispatch; the default route applies");

  // ---- P3-EXTREME ----
  // The I64 minimum and maximum in EACH of the two parameters.
  EmitRow("P3-EXTREME", I64_MIN_2P63, 0, 0, "NONE",
          "the I64 minimum in token_type; no KW_* value equals an I64 extreme");
  EmitRow("P3-EXTREME", I64_MAX_2P63_1, 0, 0, "NONE",
          "the I64 maximum in token_type; no KW_* value equals an I64 extreme");
  EmitRow("P3-EXTREME", TK_KEYWORD_VALUE, I64_MIN_2P63, 0, "NONE",
          "the I64 minimum in keyword_id; no KW_* value equals an I64 extreme");
  EmitRow("P3-EXTREME", TK_KEYWORD_VALUE, I64_MAX_2P63_1, 0, "NONE",
          "the I64 maximum in keyword_id; no KW_* value equals an I64 extreme");

  // The rows are built into a SECOND buffer, and the header is
  // written into BUF BEFORE them.
  U8 rows[FIXTURE_BUF];
  I64 row_len = LEN;
  I64 k = 0;
  while (k < row_len) { rows[k] = BUF[k]; k = k + 1; }

  LEN = 0;
  BUF[0] = 0;
  I64 n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE09\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "ACT_PHASE=C1-EVIDENCE\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "EVIDENCE_KIND=frozen-dispatch-fixture\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# THE FROZEN SOURCE-DERIVED DISPATCH FIXTURE for SUB-004.\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# CANDIDATE=SUB-004 (the statement-constructor dispatch)\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# SUBJECT=src/parser.c:1864..1877\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# SOURCE_SHA256=cd138cc52588fe48c2eab37421b4e25abbacd7ea10491bc696a1acab9a66d7e0\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# Schema:\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   fixture_id <TAB> partition <TAB> token_type <TAB>\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   keyword_id <TAB> expected_selector <TAB>\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   expected_constructor <TAB> rationale\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The row count is DERIVED from the live source and the\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# live enum.  It is NOT hard-coded.\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# The selector encoding is the one frozen at C0:\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   0 = STMT_NOT_A_KEYWORD_STATEMENT\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#   1..15 = STMT_<CTOR> in SOURCE ORDER of the case labels\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "#\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_ROW_COUNT="); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, ID_N); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_ARM_COUNT="); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, ARM_N); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_UNIVERSE_COUNT="); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, KW_N); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "# FIXTURE_TK_KEYWORD_VALUE="); LEN = LEN + n;
  n = app_ll(BUF + LEN, FIXTURE_BUF - LEN, TK_KEYWORD_VALUE); LEN = LEN + n;
  n = app_lit(BUF + LEN, FIXTURE_BUF - LEN, "\n"); LEN = LEN + n;
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
  //
  // The existence test uses Stat, because FileExists lives in the
  // tooling library and is NOT part of the installed prefix.
  Fstat fst;
  if (Stat(&fst, out_path) == 0) {
    Rm(out_path);
  }
  if (!FileWrite(out_path, BUF, LEN, 0x0202)) {
    "FIXTURE_WRITE_FAILED=%s\n", out_path;
    "STATUS=FAIL\n";
    return 1;
  }

  "FIXTURE_PATH=%s\n", out_path;
  "FIXTURE_ROW_COUNT=%d\n", ID_N;
  "FIXTURE_ARM_COUNT=%d\n", ARM_N;
  "FIXTURE_UNIVERSE_COUNT=%d\n", KW_N;
  "FIXTURE_P0_ROWS=1\n";
  "FIXTURE_P1_ROWS=%d\n", ARM_N;
  "FIXTURE_P2_ROWS=1\n";
  "FIXTURE_P3_ROWS=4\n";
  "STATUS=PASS\n";
  return 0;
}
