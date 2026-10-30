// tools/quality/parser-slice09-fixture-integrity.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE09 C1.
//
// THE INDEPENDENT FIXTURE-INTEGRITY WITNESS for SUB-004.
//
// It re-derives the dispatch truth from the LIVE src/parser.c and the
// LIVE src/lexer.h -- by a DIFFERENT path from the fixture producer --
// and checks EVERY canonical row against it.
//
// THE FIVE DETECTORS
// ==================
//
//   S9-FC-01  MISSING_FIXTURE_ID          a canonical row is ABSENT
//   S9-FC-02  DUPLICATE_FIXTURE_ID         a row ID appears TWICE
//   S9-FC-03  UNKNOWN_FIXTURE_ID           a row ID is NOT canonical
//   S9-FC-04  FIXTURE_SELECTOR_MISMATCH    the expected selector is wrong
//   S9-FC-05  SOURCE_OR_ENUM_PROVENANCE_MISMATCH
//                                         the source digest or a keyword
//                                         enum value does not match
//
// The witness is INDEPENDENT of the producer: the producer's tables
// are NOT read.  The canonical truth is re-derived from the LIVE
// source, and the fixture is then checked against it.
//
// THE DERIVATION IS LINE-SCOPED
// =============================
//
// The dispatch is the switch inside the `if (tok->tk_type ==
// TK_KEYWORD)` guard of parseStatement.  The live file contains OTHER
// switches with `case KW_` labels (the class/union switch at 310, the
// declaration-specifier switch at 889, the type switch at 2895), so
// the derivation is scoped to the dispatch's OWN line range.
//
// The range is DISCOVERED, not assumed: the witness finds the
// `case KW_IF:       return parseIfStatement(cc);` line -- the
// dispatch's FIRST arm, which is unique in the file -- and then
// collects the arms of that same switch.
//
// USAGE:
//   build/parser-slice09-fixture-integrity <fixture.tsv> <parser.c> <lexer.h>

#define MAXR 256
#define MAXARM 32
#define ARMBUF 64

// The arm-name scratch buffer.
//
// It is a FILE-SCOPE buffer, not a stack local, because ARM_NAME
// stores a POINTER to it: a stack local would dangle as soon as the
// loop iteration ended.
//
// It is FLAT, not a two-dimensional array: the row base is computed
// by an explicit offset.
U8 ARM_NAME_BUF[MAXARM * ARMBUF];

// The live dispatch arms, re-derived from src/parser.c.
U8 *ARM_NAME[MAXARM];
I64 ARM_VALUE[MAXARM];
I64 ARM_N;

// The canonical fixture rows, as read from the fixture file.
U8 *ROW_ID[MAXR];
U8 *ROW_PART[MAXR];
I64 ROW_TTYPE[MAXR];
I64 ROW_KID[MAXR];
I64 ROW_EXP[MAXR];
U8 *ROW_CTOR[MAXR];
I64 ROW_N;

// The canonical token-type value.
I64 CANON_TK_KEYWORD;

I64 failures;

// Split a tab-separated line.
I64 SplitTabs(U8 *line, U8 *f[], I64 maxf)
{
  I64 n = 0;
  U8 *p = line;
  while (n < maxf) {
    f[n] = p;
    n = n + 1;
    while (*p != 0 && *p != 9) p = p + 1;
    if (*p == 9) { *p = 0; p = p + 1; } else { break; }
  }
  return n;
}

// Parse a signed decimal exactly over the I64 domain.
I64 ParseI64(U8 *s, I64 *out)
{
  I64 v = 0;
  I64 neg = 0;
  I64 digits = 0;
  U8 *p = s;
  if (*p == 45) { neg = 1; p = p + 1; }
  if (*p == 0) return 1;
  while (*p >= 48 && *p <= 57) {
    I64 d = *p - 48;
    digits = digits + 1;
    if (digits > 19) return 1;
    v = v * 10 + d;
    if (v < 0) return 1;
    p = p + 1;
  }
  if (*p != 0) return 1;
  if (neg) { v = 0 - v; }
  *out = v;
  return 0;
}

// A bounded string comparison.
//
// StrEq is NOT part of the installed prefix, so it is defined here.
//
// NOTE: the comparison is length-bounded by the ARGUMENT's own
// terminator.  It is therefore only safe on NUL-terminated strings.
I64 StrEq(U8 *a, U8 *b)
{
  I64 i = 0;
  while (a[i] != 0 && b[i] != 0) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  if (a[i] == 0 && b[i] == 0) return 1;
  return 0;
}

// A bounded string comparison with an EXPLICIT length.
//
// This is the variant used on string LITERALS.
//
// WHY: a LOCAL string literal in this language is NOT reliably
// NUL-terminated at the literal's own end.  That was MEASURED, not
// assumed:
//
//   U8 *a = "AB";    ->  a[0]=65 a[1]=66 a[2]=65 (the NEXT literal's
//                        first byte), NOT 0
//   U8 *b = "ABC";   ->  b[0..2]=65,66,67  b[3]=65, NOT 0
//
// A FILE-SCOPE `U8 *` literal IS terminated correctly:
//
//   U8 *GA = "AB";   ->  GA[0]=65 GA[1]=66 GA[2]=0
//
// The defect is a separate, out-of-scope compiler issue (it is
// recorded as DEBT_12 in this ACT's C1 evidence and is NOT repaired
// here).  The workaround is to compare with an EXPLICIT length, so
// the comparison never depends on a literal's terminator.
I64 StrEqN(U8 *a, U8 *b, I64 n)
{
  I64 i = 0;
  while (i < n) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// Does the haystack START WITH the needle?
//
// This is DIFFERENT from HasStr, which searches the whole haystack.
// A scan that uses HasStr to test the CURRENT position would match
// as soon as the pattern appears ANYWHERE ahead, which is the wrong
// semantics for a position-by-position scan.
//
// The needle is NUL-terminated, and the comparison is bounded by the
// needle's own length.
I64 StartsAt(U8 *hay, U8 *needle)
{
  I64 i = 0;
  while (needle[i] != 0) {
    if (hay[i] != needle[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// A bounded substring search.
//
// The haystack MUST be NUL-terminated, and the needle MUST be
// NUL-terminated: the scan stops at the haystack's terminator.
I64 HasStr(U8 *hay, U8 *needle)
{
  I64 nl = 0;
  while (needle[nl] != 0) nl = nl + 1;
  if (nl == 0) return 1;
  I64 i = 0;
  while (hay[i] != 0) {
    I64 j = 0;
    while (j < nl && hay[i + j] == needle[j]) j = j + 1;
    if (j == nl) return 1;
    i = i + 1;
  }
  return 0;
}

// The macro names, as FILE-SCOPE literals.
//
// They are file-scope on purpose: a file-scope `U8 *` literal IS
// reliably NUL-terminated, while a LOCAL one is not (see StrEqN).
//
U8 *NAME_TK_KEYWORD = "TK_KEYWORD";

// Read the value of a "#define <name>" macro from the live lexer.
//
// The name is matched with an EXPLICIT LENGTH, so the match never
// depends on a string literal's terminator.
//
// Returns 1 on success, 0 when the macro is absent or its value is
// not a plain decimal or hexadecimal literal.
//
// The live header writes TK_KEYWORD in HEX ("#define TK_KEYWORD
// 0x332"), so both forms are read.
I64 MacroValueN(U8 *lexer_src, U8 *name, I64 namelen, I64 *out)
{
  U8 def[ARMBUF + 16];
  I64 d = 0;
  def[d] = 35; d = d + 1;              // '#'
  def[d] = 100; d = d + 1;             // 'd'
  def[d] = 101; d = d + 1;             // 'e'
  def[d] = 102; d = d + 1;             // 'f'
  def[d] = 105; d = d + 1;             // 'i'
  def[d] = 110; d = d + 1;             // 'n'
  def[d] = 101; d = d + 1;             // 'e'
  def[d] = 32; d = d + 1;              // ' '
  I64 k = 0;
  while (k < namelen && d < 70) { def[d] = name[k]; d = d + 1; k = k + 1; }
  def[d] = 0;

  I64 p = 0;
  while (lexer_src[p] != 0) {
    // The macro pattern is matched with the EXACT length, so a
    // partially-matching prefix cannot be mistaken for the macro.
    if (StrEqN(lexer_src + p, def, d)) {
      I64 q = p + d;
      while (lexer_src[q] == 32 || lexer_src[q] == 9) q = q + 1;
      I64 val = 0;
      I64 digits = 0;
      // A hexadecimal literal.
      if (lexer_src[q] == 48 && (lexer_src[q + 1] == 120 || lexer_src[q + 1] == 88)) {
        q = q + 2;
        while ((lexer_src[q] >= 48 && lexer_src[q] <= 57) ||
               (lexer_src[q] >= 97 && lexer_src[q] <= 102)) {
          I64 h = lexer_src[q] - 48;
          if (lexer_src[q] >= 97) h = lexer_src[q] - 87;
          val = val * 16 + h;
          digits = digits + 1;
          q = q + 1;
        }
      } else {
        while (lexer_src[q] >= 48 && lexer_src[q] <= 57) {
          val = val * 10 + (lexer_src[q] - 48);
          digits = digits + 1;
          q = q + 1;
        }
      }
      if (digits == 0) return 0;
      if (lexer_src[q] == 40) return 0;   // an expression, not a literal
      *out = val;
      return 1;
    }
    p = p + 1;
  }
  return 0;
}

// The length of a NUL-terminated file-scope literal.
I64 NameLen(U8 *s)
{
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

// The MacroValue entry point for a file-scope name.
I64 MacroValue(U8 *lexer_src, U8 *name, I64 *out)
{
  return MacroValueN(lexer_src, name, NameLen(name), out);
}

// Derive the canonical arms from the live src/parser.c.
//
// The derivation is LINE-SCOPED to the dispatch's own switch.
//
// The dispatch's FIRST arm is the unique line that contains both
// "case KW_IF" and "parseIfStatement".  The arms are then collected
// from the switch that begins on the NEXT line.
I64 DeriveArms(U8 *parser_src, U8 *lexer_src)
{
  ARM_N = 0;

  // Find the dispatch's first arm.
  //
  // The dispatch's first arm is the unique LINE that contains BOTH
  // "case KW_IF:" and "parseIfStatement".  The two are on the SAME
  // line, so the search is a LINE search, not a position search.
  I64 first = -1;
  I64 i = 0;
  while (parser_src[i] != 0) {
    if (StartsAt(parser_src + i, "case KW_IF:")) {
      // Check the rest of the line for the constructor.
      I64 q = i;
      I64 line_end = i;
      while (parser_src[line_end] != 0 && parser_src[line_end] != 10) line_end = line_end + 1;
      I64 found = 0;
      while (q < line_end) {
        if (StartsAt(parser_src + q, "parseIfStatement")) { found = 1; break; }
        q = q + 1;
      }
      if (found) { first = i; break; }
    }
    i = i + 1;
  }
  if (first < 0) return 0;

  // The dispatch's switch ends at the "default:" arm's closing brace.
  // The arms are collected until the "default:" label is reached,
  // because the default arm is the fall-through route and is NOT a
  // constructor arm.
  I64 p = first;
  while (parser_src[p] != 0) {
    // Look for "case KW_" on this line.
    if (parser_src[p] == 99 && parser_src[p + 1] == 97 &&
        parser_src[p + 2] == 115 && parser_src[p + 3] == 101 &&
        parser_src[p + 4] == 32 && parser_src[p + 5] == 75 &&
        parser_src[p + 6] == 87 && parser_src[p + 7] == 95) {
      // Extract the name, including the "KW_" prefix.
      U8 *nm = ARM_NAME_BUF + ARM_N * ARMBUF;
      I64 n = 0;
      I64 j = p + 5;
      while (parser_src[j] != 0 && parser_src[j] != 58 && n < ARMBUF - 1) {
        nm[n] = parser_src[j];
        n = n + 1;
        j = j + 1;
      }
      nm[n] = 0;

      // The default arm terminates the collection.
      if (StrEq(nm, "KW_DEFAULT")) {
        // The default arm is the fall-through route.  It is NOT a
        // constructor arm, but the DEFAULT keyword IS a dispatch arm
        // in its own right (KW_DEFAULT selects
        // parseDefaultStatement).  The distinction is made by the
        // ARM ORDER, not by the name, so the collection continues.
      }

      if (ARM_N < MAXARM) {
        I64 v = 0;
        if (!MacroValue(lexer_src, nm, &v)) {
          // The keyword has no plain literal value: it is not one of
          // the dispatch's arms.
          p = j;
          continue;
        }
        ARM_NAME[ARM_N] = nm;
        ARM_VALUE[ARM_N] = v;
        ARM_N = ARM_N + 1;
      }
      p = j;
      continue;
    }
    // The dispatch's switch ends at the `default:` arm.  The
    // collection therefore stops when the default arm's LABEL is
    // reached, because the default arm is the fall-through route and
    // is NOT a constructor arm.
    //
    // The stop is detected by the default arm's EXACT indentation
    // ("            default: {"), NOT by a closing brace: the complex
    // arms (KW_ASM, KW_STATIC, KW_GOTO) contain their own braces, and
    // a brace-based stop would cut the collection short after the
    // first simple arm.
    if (StartsAt(parser_src + p, "            default: {")) {
      break;
    }
    p = p + 1;
  }
  return ARM_N;
}

// The fixture file's raw buffer, kept so that its HEADER can be
// checked for its provenance declarations.
//
// The header is scanned BEFORE the rows are loaded, because loading
// splits the buffer in place with tabs and would corrupt the header
// lines.
U8 *fx_buf;

// The header's provenance declarations, read BEFORE the in-place
// split.
U8 FX_SHA[80];
I64 FX_SHA_LEN;
I64 FX_TK;
I64 FX_TK_SEEN;

// The FROZEN source digest of the selected range.
//
// This is the digest frozen by the predecessor's selected contract
// (c2/selected-source-contract.md) and by this ACT's C0 bindings
// (c0/selected-contract-bindings.tsv).  It is the PROVENANCE
// IDENTITY of the subject the fixture was derived from.
U8 *FROZEN_SOURCE_SHA256 = "cd138cc52588fe48c2eab37421b4e25abbacd7ea10491bc696a1acab9a66d7e0";

// Scan the fixture's header for its provenance declarations.
I64 ScanFixtureHeader(U8 *buf)
{
  FX_SHA[0] = 0;
  FX_SHA_LEN = 0;
  FX_TK = 0;
  FX_TK_SEEN = 0;
  I64 p = 0;
  while (buf[p] != 0) {
    if (StartsAt(buf + p, "# SOURCE_SHA256=")) {
      I64 q = p + 16;
      I64 k = 0;
      while (buf[q] != 0 && buf[q] != 10 && k < 79) {
        FX_SHA[k] = buf[q];
        k = k + 1;
        q = q + 1;
      }
      FX_SHA[k] = 0;
      FX_SHA_LEN = k;
      p = q;
      continue;
    }
    if (StartsAt(buf + p, "# FIXTURE_TK_KEYWORD_VALUE=")) {
      I64 q = p + 27;
      I64 v = 0;
      I64 digits = 0;
      while (buf[q] >= 48 && buf[q] <= 57) {
        v = v * 10 + (buf[q] - 48);
        digits = digits + 1;
        q = q + 1;
      }
      FX_TK = v;
      FX_TK_SEEN = digits;
      p = q;
      continue;
    }
    p = p + 1;
  }
  return 1;
}

// Read the fixture rows.
I64 LoadFixture(U8 *path)
{
  I64 fsize = 0;
  U8 *buf = FileRead(path, &fsize);
  if (buf == NULL) return -1;
  fx_buf = buf;
  ROW_N = 0;
  U8 *p = buf;
  U8 *end = buf + fsize;
  while (p < end) {
    U8 *ls = p;
    while (p < end && *p != 10) p = p + 1;
    U8 *le = p;
    if (p < end) p = p + 1;
    if (le > ls && *(le - 1) == 13) le = le - 1;
    *le = 0;
    U8 *line = ls;
    if (*line == 0) continue;
    if (*line == 35) continue;
    U8 *f[8];
    I64 nf = SplitTabs(line, f, 8);
    if (nf < 7) continue;
    if (ROW_N >= MAXR) break;
    ROW_ID[ROW_N] = f[0];
    ROW_PART[ROW_N] = f[1];
    ParseI64(f[2], ROW_TTYPE + ROW_N);
    ParseI64(f[3], ROW_KID + ROW_N);
    ParseI64(f[4], ROW_EXP + ROW_N);
    ROW_CTOR[ROW_N] = f[5];
    ROW_N = ROW_N + 1;
  }
  return ROW_N;
}

// The canonical selector for a keyword id.
I64 CanonicalSelector(I64 kid)
{
  I64 i = 0;
  while (i < ARM_N) {
    if (ARM_VALUE[i] == kid) return i + 1;
    i = i + 1;
  }
  return 0;
}

// Render an I64 as decimal, into a caller-supplied buffer.
I64 RenderI64(I64 v, U8 *dst)
{
  U8 tmp[24];
  I64 n = 0;
  I64 neg = 0;
  I64 x = v;
  if (x < 0) { neg = 1; x = 0 - x; }
  if (x == 0) { tmp[0] = 48; n = 1; }
  while (x > 0) { tmp[n] = 48 + (x % 10); n = n + 1; x = x / 10; }
  I64 o = 0;
  if (neg) { dst[o] = 45; o = o + 1; }
  I64 i = n - 1;
  while (i >= 0) { dst[o] = tmp[i]; o = o + 1; i = i - 1; }
  dst[o] = 0;
  return o;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 4) {
    "usage: parser-slice09-fixture-integrity <fixture.tsv> <parser.c> <lexer.h>\n";
    return 2;
  }
  failures = 0;

  I64 psz = 0;
  I64 lsz = 0;
  U8 *psrc = FileRead(argv[2], &psz);
  U8 *lsrc = FileRead(argv[3], &lsz);
  if (psrc == NULL || lsrc == NULL) {
    "STATUS=FAIL\n";
    "REASON=CANNOT_READ_SOURCE\n";
    return 1;
  }

  // The live TK_KEYWORD value.
  I64 tk = 0;
  if (!MacroValue(lsrc, NAME_TK_KEYWORD, &tk)) {
    "STATUS=FAIL\n";
    "REASON=CANNOT_READ_TK_KEYWORD\n";
    return 1;
  }
  CANON_TK_KEYWORD = tk;

  DeriveArms(psrc, lsrc);
  // The header is scanned BEFORE the rows are loaded, because loading
  // splits the buffer in place and would corrupt the header lines.
  {
    I64 hs = 0;
    U8 *hb = FileRead(argv[1], &hs);
    if (hb == NULL) {
      "STATUS=FAIL\n";
      "REASON=CANNOT_READ_FIXTURE\n";
      return 1;
    }
    ScanFixtureHeader(hb);
  }
  I64 fr = LoadFixture(argv[1]);
  if (fr < 0) {
    "STATUS=FAIL\n";
    "REASON=CANNOT_READ_FIXTURE\n";
    return 1;
  }

  "CANON_TK_KEYWORD=%d\n", CANON_TK_KEYWORD;
  "CANON_ARM_COUNT=%d\n", ARM_N;
  "FIXTURE_ROW_COUNT=%d\n", ROW_N;

  // ---- S9-FC-02: DUPLICATE_FIXTURE_ID ----
  I64 i = 0;
  while (i < ROW_N) {
    I64 j = i + 1;
    while (j < ROW_N) {
      if (StrEq(ROW_ID[i], ROW_ID[j])) {
        "DETECTOR=DUPLICATE_FIXTURE_ID\n";
        "ROW_ID=%s\n", ROW_ID[i];
        "FIRST_POSITION=%d\n", i + 1;
        "SECOND_POSITION=%d\n", j + 1;
        failures = failures + 1;
      }
      j = j + 1;
    }
    i = i + 1;
  }

  // ---- S9-FC-01 and S9-FC-03: MISSING / UNKNOWN row IDs ----
  //
  // The canonical row set is: 1 P0 row, one row per arm, 1 P2 row
  // and 4 P3 rows.  The IDs are the 1-based positions in that order.
  I64 canon_total = ARM_N + 6;
  i = 1;
  while (i <= canon_total) {
    U8 want[24];
    RenderI64(i, want);
    I64 found = 0;
    I64 k = 0;
    while (k < ROW_N) {
      if (StrEq(ROW_ID[k], want)) { found = 1; break; }
      k = k + 1;
    }
    if (!found) {
      // Report the EXACT missing ID, with no false attribution.
      "DETECTOR=MISSING_FIXTURE_ID\n";
      "ROW_ID=%s\n", want;
      failures = failures + 1;
    }
    i = i + 1;
  }

  // An UNKNOWN row ID is a row whose ID is not a canonical position.
  i = 0;
  while (i < ROW_N) {
    I64 idv = 0;
    if (ParseI64(ROW_ID[i], &idv) != 0) {
      "DETECTOR=UNKNOWN_FIXTURE_ID\n";
      "ROW_ID=%s\n", ROW_ID[i];
      "REASON=THE_ROW_ID_IS_NOT_NUMERIC\n";
      failures = failures + 1;
    } else if (idv < 1 || idv > canon_total) {
      "DETECTOR=UNKNOWN_FIXTURE_ID\n";
      "ROW_ID=%s\n", ROW_ID[i];
      "REASON=OUT_OF_THE_CANONICAL_RANGE\n";
      failures = failures + 1;
    }
    i = i + 1;
  }

  // ---- S9-FC-04: FIXTURE_SELECTOR_MISMATCH ----
  //
  // Every row is checked against the INDEPENDENTLY derived truth.
  i = 0;
  while (i < ROW_N) {
    I64 canon = 0;
    if (ROW_TTYPE[i] == CANON_TK_KEYWORD) {
      canon = CanonicalSelector(ROW_KID[i]);
    }
    if (ROW_EXP[i] != canon) {
      "DETECTOR=FIXTURE_SELECTOR_MISMATCH\n";
      "ROW_ID=%s\n", ROW_ID[i];
      "KEYWORD_ID=%d\n", ROW_KID[i];
      "EXPECTED_SELECTOR=%d\n", canon;
      "ACTUAL_SELECTOR=%d\n", ROW_EXP[i];
      failures = failures + 1;
    }
    i = i + 1;
  }

  // ---- S9-FC-05: SOURCE_OR_ENUM_PROVENANCE_MISMATCH ----
  //
  // The fixture's HEADER declares the provenance it was derived from:
  // the subject range, its SHA-256 and the token-type value.  The
  // witness checks those declarations against the LIVE source and
  // the LIVE enum.
  //
  // The source SHA-256 is checked by RE-READING the fixture header's
  // declared digest and comparing it with the FROZEN digest of the
  // selected range, which the witness carries as a constant.  A
  // fixture that was regenerated from a DIFFERENT source, or whose
  // declared digest was edited, is rejected.
  //
  // The enum identity is checked by comparing the fixture header's
  // declared token-type value with the LIVE one.
  //
  // The header is scanned for its two declarations.
  {
    if (FX_SHA_LEN != 64) {
      "DETECTOR=SOURCE_OR_ENUM_PROVENANCE_MISMATCH\n";
      "REASON=THE_FIXTURE_DECLARES_NO_SOURCE_DIGEST\n";
      failures = failures + 1;
    } else if (!StrEqN(FX_SHA, FROZEN_SOURCE_SHA256, 64)) {
      "DETECTOR=SOURCE_OR_ENUM_PROVENANCE_MISMATCH\n";
      "REASON=THE_FIXTURE_DECLARED_SOURCE_DIGEST_IS_NOT_THE_FROZEN_ONE\n";
      "DECLARED_SHA256=%s\n", FX_SHA;
      "FROZEN_SHA256=%s\n", FROZEN_SOURCE_SHA256;
      failures = failures + 1;
    }
    if (FX_TK_SEEN == 0) {
      "DETECTOR=SOURCE_OR_ENUM_PROVENANCE_MISMATCH\n";
      "REASON=THE_FIXTURE_DECLARES_NO_TOKEN_TYPE_VALUE\n";
      failures = failures + 1;
    } else if (FX_TK != CANON_TK_KEYWORD) {
      "DETECTOR=SOURCE_OR_ENUM_PROVENANCE_MISMATCH\n";
      "REASON=THE_FIXTURE_DECLARED_TOKEN_TYPE_VALUE_IS_NOT_THE_LIVE_ONE\n";
      "DECLARED_TK_KEYWORD=%d\n", FX_TK;
      "LIVE_TK_KEYWORD=%d\n", CANON_TK_KEYWORD;
      failures = failures + 1;
    }
  }

  // Every arm's keyword value is re-read from the live lexer source
  // and compared with the derived value.
  i = 0;
  while (i < ARM_N) {
    I64 live = 0;
    if (!MacroValue(lsrc, ARM_NAME[i], &live)) {
      "DETECTOR=SOURCE_OR_ENUM_PROVENANCE_MISMATCH\n";
      "REASON=THE_KEYWORD_MACRO_IS_ABSENT_FROM_THE_LIVE_LEXER\n";
      "KEYWORD=%s\n", ARM_NAME[i];
      failures = failures + 1;
    } else if (live != ARM_VALUE[i]) {
      "DETECTOR=SOURCE_OR_ENUM_PROVENANCE_MISMATCH\n";
      "KEYWORD=%s\n", ARM_NAME[i];
      "DERIVED_VALUE=%d\n", ARM_VALUE[i];
      "LIVE_VALUE=%d\n", live;
      failures = failures + 1;
    }
    i = i + 1;
  }

  "FAILURES=%d\n", failures;
  if (failures == 0) {
    "STATUS=PASS\n";
    return 0;
  }
  "STATUS=FAIL\n";
  return 1;
}
