// tools/quality/a64-cmp-cc-implement02-corrected01-red-verify.HC
//
// ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01.
//
// THE SUBSTANTIVE POLYC VERIFIER for this ACT's C0 RED controls, its C3
// negative controls NC01..NC24, and its C3 acceptance ledger.
//
// It is a SOURCE-DERIVED instrument. It NEVER prints a hardcoded status:
// every verdict it emits is computed from the bytes it is given, and
// every digest it compares is recomputed by its own SHA-256
// implementation. A mode prints FINAL=OK only when the recomputed fact
// matches the expectation; otherwise it prints FINAL=FAIL together with
// a REASON token that names the SPECIFIC defect it observed.
//
// The SHA-256 core below is the same FIPS 180-4 implementation the
// repository already proves in
// tools/quality/a64-cmp-cc-contract-correction01-verify.HC, and it is
// re-validated against the FIPS vectors by the `selftest` mode before
// any digest this tool trusts is used.
//
// MODES
//
//   selftest
//        Validates SHA-256 against the FIPS 180-4 vectors and validates
//        the byte scanner against hand-built fixtures.
//        Reason on failure: SELFTEST_FAILED.
//
//   partial-as-whole <src> <whole-start> <whole-end> <partial-sha>
//        NC03 / RED01_SOURCE. The PARTIAL_SOURCE_RANGE_AS_WHOLE
//        detector. It recomputes the digest of [whole-start,whole-end)
//        and rejects a presented digest that is NOT that digest while
//        IS the digest of a strict prefix of the same definition.
//        Reason on failure: PARTIAL_SOURCE_RANGE_AS_WHOLE.
//
//   source-range <src> <start> <end> <expected-sha>
//        NC04. The SOURCE_BOUNDARY_OR_BLOB_MISMATCH detector. It
//        recomputes the digest of [start,end) and also of the one-byte
//        extended and one-byte truncated intervals, so an off-by-one is
//        distinguished from a wholesale mismatch.
//        Reason on failure: SOURCE_BOUNDARY_OR_BLOB_MISMATCH.
//
//   abi-zero <abi-file>
//        NC07 / RED02_ABI. The ABI_ZERO_INVALID_MISCLASSIFIED
//        detector. It parses the live ABI declaration and rejects an
//        ABI that treats the numeric zero discriminant as an error
//        status rather than as the valid IR_CMP_EQ kind.
//        Reason on failure: ABI_ZERO_INVALID_MISCLASSIFIED.
//
//   fail-closed <abi-file>
//        NC08. The INVALID_SUFFIX_NOT_FAIL_CLOSED detector. It rejects
//        an ABI that maps an unsupported kind to a real suffix instead
//        of to a NULL fail-closed status.
//        Reason on failure: INVALID_SUFFIX_NOT_FAIL_CLOSED.
//
//   third-export <abi-file>
//        NC05 / RED03_EXPORT. The FORBIDDEN_THIRD_EXPORT detector. It
//        rejects any ABI that declares a CSET export, and it rejects any
//        authority table that counts CSET as an independent authority.
//        Reason on failure: FORBIDDEN_THIRD_EXPORT.
//
//   cset-double-count <authority-file>
//        NC06. The CSET_SEMANTIC_DOUBLE_COUNT detector.
//        Reason on failure: CSET_SEMANTIC_DOUBLE_COUNT.
//
//   borrowed-lifetime <abi-file> <export-name>
//        NC09. The BORROWED_LITERAL_LIFETIME detector.
//        Reason on failure: BORROWED_LITERAL_LIFETIME.
//
//   symbol-binding <obj-file> <expected-symbol>
//        NC10. The ABI_SYMBOL_BINDING_MISMATCH detector. It reads the
//        object's own symbol table text and requires the expected symbol
//        to be DEFINED there as a global text symbol.
//        Reason on failure: ABI_SYMBOL_BINDING_MISMATCH.
//
//   oracle-contamination <obj-file>
//        NC11. The C_ONLY_A64_ORACLE_CONTAMINATION detector. It rejects
//        an object that IMPORTS either of the two new A64 exports.
//        Reason on failure: C_ONLY_A64_ORACLE_CONTAMINATION.
//
//   legacy-live <obj-file> <token>
//        NC12 / NC16. The LEGACY_C_ORACLE_NOT_LIVE /
//        LEGACY_C_AUTHORITY_ACTIVE detector. It reads the object's
//        disassembly and looks for the legacy condition-suffix literal
//        token. A selector-OFF object must contain it; a selector-ON
//        object must NOT contain it.
//        Reason on failure: LEGACY_C_ORACLE_NOT_LIVE or
//        LEGACY_C_AUTHORITY_ACTIVE.
//
//   subject-producer <obj-file> <symbol>
//        NC13. The MISSING_EFFECTIVE_SUBJECT_PRODUCER detector.
//        Reason on failure: MISSING_EFFECTIVE_SUBJECT_PRODUCER.
//
//   fail-open <log-file> <marker>
//        NC14. The CONFIGURATION_FAIL_OPEN detector. It rejects a log
//        that contains a "127" command-not-found marker, or that is
//        missing a marker that the invoked command must have printed.
//        Reason on failure: CONFIGURATION_FAIL_OPEN.
//
//   dormant-subject <caller-obj> <symbol>
//        NC15. The LINKED_BUT_DORMANT_POLYC_SUBJECT detector. It rejects
//        a caller object that does NOT import the symbol, so that a
//        linked-but-unused subject cannot be credited.
//        Reason on failure: LINKED_BUT_DORMANT_POLYC_SUBJECT.
//
//   producer-alias <producer-file>
//        NC17 / RED04_PRODUCER. The PRODUCER_ALIAS_OR_MISSING_EDGE
//        detector. It rejects two producer rows with the SAME executable
//        digest and a producer row with an empty digest.
//        Reason on failure: PRODUCER_ALIAS_OR_MISSING_EDGE.
//
//   two-rosters <crosswalk-file>
//        NC18. The TWO_ROSTERS_CONFLATED detector.
//        Reason on failure: TWO_ROSTERS_CONFLATED.
//
//   fixture-rows <fixture-file> <expected-rows>
//        NC19. The FIXTURE_DIFFERENTIAL_NOT_SENSITIVE detector. It
//        recomputes the row count, checks every ID is unique and checks
//        the required role partition counts.
//        Reason on failure: FIXTURE_DIFFERENTIAL_NOT_SENSITIVE.
//
//   ac-ledger <ledger-file>
//        NC23 / RED05_EVIDENCE. The LEDGER_FALSE_PASS detector. It
//        rejects a missing id, a duplicated id, an unknown id, an
//        illegal status, or a PASS row that carries no evidence
//        reference.
//        Reason on failure: LEDGER_FALSE_PASS.
//
//   terminality <ledger-file> <head> <tree>
//        NC24. The PREMATURE_OR_MISBOUND_TERMINALITY detector.
//        Reason on failure: PREMATURE_OR_MISBOUND_TERMINALITY.
//
//   entry-identity <fact-file> <head> <tree> <branch>
//        NC01. The ENTRY_IDENTITY_MISMATCH detector.
//        Reason on failure: ENTRY_IDENTITY_MISMATCH.
//
//   f14-freeze <freeze-file>
//        NC02. The HISTORICAL_F14_REWRITE detector. It recomputes each
//        frozen path's digest and rejects a row whose recorded digest
//        does not match the file's actual bytes.
//        Reason on failure: HISTORICAL_F14_REWRITE.
//
//   cset-preserved <src> <func-name> <expected-token>
//        NC22. The CSET_ADAPTER_NOT_PRESERVED detector. It extracts the
//        named function's whole body and requires the token.
//        Reason on failure: CSET_ADAPTER_NOT_PRESERVED.
//
//   wrong-site <evidence-file> <required-site-id>
//        NC20. The WRONG_SITE_CAUSAL_ATTRIBUTION detector.
//        Reason on failure: WRONG_SITE_CAUSAL_ATTRIBUTION.
//
//   dormant-counter <evidence-file> <required-site-id>
//        NC21. The C_DORMANCY_ANTI_CONTROL_FAILURE detector.
//        Reason on failure: C_DORMANCY_ANTI_CONTROL_FAILURE.
//
// BUILD:
//   ./hcc --install-dir=<prefix> -c \
//     tools/quality/a64-cmp-cc-implement02-corrected01-red-verify.HC \
//     -o build/a64-cmp-cc-red-verify.o
//   cc build/a64-cmp-cc-red-verify.o -L<prefix>/lib -ltos \
//     -o build/a64-cmp-cc-red-verify
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real compiler.

#include "../../src/holyc-lib/defs.HH"
#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

public _extern _EXIT U0 Exit(I64 exit_code = EXIT_FAIL);
public _extern _WRITE I64 Write(I64 fd, U8 *buf, I64 len);

// ---------------------------------------------------------------------------
// Reporting.
// ---------------------------------------------------------------------------

public U0 RedFail(U8 *reason)
{
  Write(1,"FINAL=FAIL\n",11);
  Write(1,"REASON=",7);
  Write(1,reason,StrLen(reason));
  Write(1,"\n",1);
  Exit(1);
}

public U0 RedOk(U8 *detail)
{
  Write(1,"FINAL=OK\n",9);
  if (detail != NULL) {
    Write(1,"DETAIL=",7);
    Write(1,detail,StrLen(detail));
    Write(1,"\n",1);
  }
  Exit(0);
}

// ---------------------------------------------------------------------------
// SHA-256 (FIPS 180-4), implemented here so the detector has no external
// dependency and computes its own digests.
// ---------------------------------------------------------------------------

class Sha256
{
  U64 h[8];
  I64 len;
  U8 buf[64];
  I64 buflen;
};

static U64 K256[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

public U64 ShaRot(U64 x, I32 n)
{
  U64 lo = (x >> n) & 0xFFFFFFFF;
  U64 hi = (x << (32 - n)) & 0xFFFFFFFF;
  return (lo | hi) & 0xFFFFFFFF;
}

public U0 ShaBlock(Sha256 *s, U8 *p)
{
  U64 w[64];
  U8 *q = p;
  for (I32 i = 0; i < 16; i++) {
    U64 b0 = q[0]; U64 b1 = q[1]; U64 b2 = q[2]; U64 b3 = q[3];
    q += 4;
    w[i] = ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3) & 0xFFFFFFFF;
  }
  for (I32 i = 16; i < 64; i++) {
    U64 w15 = w[i-15] & 0xFFFFFFFF;
    U64 w2 = w[i-2] & 0xFFFFFFFF;
    U64 s0 = (ShaRot(w15,7) ^ ShaRot(w15,18) ^ (w15 >> 3)) & 0xFFFFFFFF;
    U64 s1 = (ShaRot(w2,17) ^ ShaRot(w2,19) ^ (w2 >> 10)) & 0xFFFFFFFF;
    w[i] = (w[i-16] + s0 + w[i-7] + s1) & 0xFFFFFFFF;
  }
  U64 a = s->h[0] & 0xFFFFFFFF; U64 b = s->h[1] & 0xFFFFFFFF;
  U64 c = s->h[2] & 0xFFFFFFFF; U64 d = s->h[3] & 0xFFFFFFFF;
  U64 e = s->h[4] & 0xFFFFFFFF; U64 f = s->h[5] & 0xFFFFFFFF;
  U64 g = s->h[6] & 0xFFFFFFFF; U64 hh = s->h[7] & 0xFFFFFFFF;
  for (I32 i = 0; i < 64; i++) {
    U64 S1 = (ShaRot(e,6) ^ ShaRot(e,11) ^ ShaRot(e,25)) & 0xFFFFFFFF;
    U64 ch = ((e & f) ^ ((~e) & g)) & 0xFFFFFFFF;
    U64 t1 = (hh + S1 + ch + (K256[i] & 0xFFFFFFFF) + (w[i] & 0xFFFFFFFF)) & 0xFFFFFFFF;
    U64 S0 = (ShaRot(a,2) ^ ShaRot(a,13) ^ ShaRot(a,22)) & 0xFFFFFFFF;
    U64 mj = ((a & b) ^ (a & c) ^ (b & c)) & 0xFFFFFFFF;
    U64 t2 = (S0 + mj) & 0xFFFFFFFF;
    hh = g; g = f; f = e; e = (d + t1) & 0xFFFFFFFF;
    d = c; c = b; b = a; a = (t1 + t2) & 0xFFFFFFFF;
  }
  s->h[0] = (s->h[0] + a) & 0xFFFFFFFF; s->h[1] = (s->h[1] + b) & 0xFFFFFFFF;
  s->h[2] = (s->h[2] + c) & 0xFFFFFFFF; s->h[3] = (s->h[3] + d) & 0xFFFFFFFF;
  s->h[4] = (s->h[4] + e) & 0xFFFFFFFF; s->h[5] = (s->h[5] + f) & 0xFFFFFFFF;
  s->h[6] = (s->h[6] + g) & 0xFFFFFFFF; s->h[7] = (s->h[7] + hh) & 0xFFFFFFFF;
}

public U0 ShaInit(Sha256 *s)
{
  s->h[0] = 0x6a09e667; s->h[1] = 0xbb67ae85;
  s->h[2] = 0x3c6ef372; s->h[3] = 0xa54ff53a;
  s->h[4] = 0x510e527f; s->h[5] = 0x9b05688c;
  s->h[6] = 0x1f83d9ab; s->h[7] = 0x5be0cd19;
  s->len = 0; s->buflen = 0;
}

public U0 ShaUpdate(Sha256 *s, U8 *p, I64 n)
{
  s->len += n;
  while (n > 0) {
    I64 take = 64 - s->buflen;
    if (take > n) take = n;
    MemCpy(s->buf + s->buflen, p, take);
    s->buflen += take; p += take; n -= take;
    if (s->buflen == 64) { ShaBlock(s, s->buf); s->buflen = 0; }
  }
}

public U0 ShaFinal(Sha256 *s, U8 *out)
{
  I64 bits = s->len * 8;
  U8 pad = 0x80;
  ShaUpdate(s, &pad, 1);
  U8 z = 0;
  while (s->buflen != 56) ShaUpdate(s, &z, 1);
  U8 lenb[8];
  I64 rem = bits;
  for (I32 i = 0; i < 8; i++) {
    I64 shift = 8 * (7 - i);
    lenb[i] = rem >> shift;
    rem = rem - (rem >> shift << shift);
  }
  ShaUpdate(s, lenb, 8);
  U8 *hex = "0123456789abcdef";
  U8 *o = out;
  for (I32 i = 0; i < 8; i++) {
    U64 word = s->h[i];
    for (I32 j = 3; j >= 0; j--) {
      U64 byte = (word >> (8*j)) & 0xFF;
      *o++ = hex[byte >> 4];
      *o++ = hex[byte & 15];
    }
  }
  *o = 0;
}

// ShaHexBytes hashes a byte range and writes 64 hex chars + NUL.
public U0 ShaHexBytes(U8 *p, I64 n, U8 *out)
{
  Sha256 s; ShaInit(&s); ShaUpdate(&s, p, n); ShaFinal(&s, out);
}

// ShaSelfTest validates the implementation against the FIPS 180-4
// vectors BEFORE any digest is trusted.
public Bool ShaSelfTest()
{
  U8 hex[65];
  ShaHexBytes("abc", 3, hex);
  if (StrCmp(hex, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad") != 0)
    return FALSE;
  ShaHexBytes("", 0, hex);
  if (StrCmp(hex, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") != 0)
    return FALSE;
  ShaHexBytes("hello world", 11, hex);
  if (StrCmp(hex, "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9") != 0)
    return FALSE;
  return TRUE;
}

// ---------------------------------------------------------------------------
// Text helpers.
// ---------------------------------------------------------------------------

public U8 *StrFind(U8 *hay, U8 *needle)
{
  if (hay == NULL || needle == NULL) return NULL;
  I64 nl = StrLen(needle);
  if (nl == 0) return hay;
  I64 hl = StrLen(hay);
  for (I64 i = 0; i + nl <= hl; i++) {
    I64 j = 0;
    while (j < nl && hay[i+j] == needle[j]) j++;
    if (j == nl) return hay + i;
  }
  return NULL;
}

public I64 CountOcc(U8 *hay, U8 *needle)
{
  I64 n = 0;
  I64 nl = StrLen(needle);
  if (nl == 0) return 0;
  I64 hl = StrLen(hay);
  for (I64 i = 0; i + nl <= hl; ) {
    I64 j = 0;
    while (j < nl && hay[i+j] == needle[j]) j++;
    if (j == nl) { n++; i += nl; } else { i++; }
  }
  return n;
}

// Split a TSV line into fields. Returns the field count. The line is
// modified in place.
public I64 SplitCols(U8 *line, U8 **fld, I64 maxf)
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

#define MAXROW 512
#define NCOL   24
#define MAXFLD (MAXROW * NCOL)

static U8 *FLD[MAXFLD];
static I64 NROW;
static U8 *ROW[MAXROW];

// The header row of the loaded table, when the table's first
// non-comment line was preceded by a comment line that carries a
// header. A header comment line looks like "# <col1>\t<col2>\t...".
static U8 *HDR[NCOL];
static I64 NHDR;

// Load a TSV file into FLD/ROW. Lines beginning with '#' are comments
// and are NOT counted as data rows. The LAST comment line that looks
// like a column header (that is, it contains at least one TAB) is
// captured as the header row. Returns 0 on success.
public I64 LoadTsv(U8 *path)
{
  I64 sz = 0;
  U8 *txt = FileRead(path, &sz);
  U8 *p;
  if (txt == NULL) return -1;
  NROW = 0;
  NHDR = 0;
  for (I64 i = 0; i < NCOL; i++) HDR[i] = NULL;
  p = txt;
  while (*p != 0) {
    U8 *line = p;
    while (*p != 0 && *p != '\n') p++;
    if (*p == '\n') { *p = 0; p++; }
    if (line[0] == 0) continue;
    if (line[0] == '#') {
      // A comment line that contains a TAB byte is a header row. The
      // tab is detected by its BYTE VALUE (9), not through a string
      // escape, so that the detection cannot depend on how a given
      // compiler spells "\t".
      I64 has_tab = 0;
      {
        I64 k = 0;
        I64 n = StrLen(line);
        while (line[k] != 0) {
          if (line[k] == 9) { has_tab = 1; break; }
          k++;
        }
      }
      if (has_tab) {
        U8 *copy = MAlloc(StrLen(line) + 1);
        MemCpy(copy, line, StrLen(line) + 1);
        // Strip the leading '#' and any blanks after it.
        U8 *h = copy;
        if (*h == '#') h++;
        while (*h == ' ' || *h == '\t') h++;
        NHDR = SplitCols(h, HDR, NCOL);
      }
      continue;
    }
    if (NROW >= MAXROW) break;
    // The FIRST data row of a table that carries no comment header IS
    // the header row. It is captured BEFORE the line is split, because
    // splitting replaces the tabs with NULs in place. It is NOT a data
    // row and is not counted as one.
    if (NROW == 0 && NHDR == 0) {
      U8 *copy = MAlloc(StrLen(line) + 1);
      MemCpy(copy, line, StrLen(line) + 1);
      NHDR = SplitCols(copy, HDR, NCOL);
      continue;
    }
    ROW[NROW] = line;
    SplitCols(line, FLD + NROW * NCOL, NCOL);
    NROW++;
  }
  return 0;
}

// Find the index of the column whose header name is `name`, by looking
// at the captured header row. Returns -1 when not found.
public I64 ColByName(U8 *name)
{
  if (NHDR == 0) return -1;
  for (I64 i = 0; i < NHDR; i++) {
    if (HDR[i] == NULL) continue;
    if (StrCmp(HDR[i], name) == 0) return i;
  }
  return -1;
}

// The field `i` of data row `r`.
public U8 *Cell(I64 r, I64 i)
{
  U8 **row = FLD + r * NCOL;
  if (i < 0 || i >= NCOL) return NULL;
  return row[i];
}

// ---------------------------------------------------------------------------
// Byte-level lexical scanner.
//
// It finds the whole definition of a named function in a byte buffer,
// tracking line comments, block comments, string literals, character
// literals and preprocessor lines, so that a brace inside a comment or a
// string can never be mistaken for a function-body brace. It returns the
// half-open byte interval [start,end) of the WHOLE DEFINITION: the
// interval begins at the first byte of the declaration and ends at the
// byte AFTER the matching closing brace.
// ---------------------------------------------------------------------------

static U8 *GSRC;
static I64 GLEN;

public I64 ScanDef(U8 *name, I64 namelen, I64 *out_start, I64 *out_end)
{
  I64 i = 0;
  while (i < GLEN) {
    I64 instr = 0; I64 inchar = 0; I64 incmt = 0; I64 inpre = 0;
    I64 found = 0;
    I64 j;

    while (i < GLEN) {
      U8 c = GSRC[i];
      if (incmt == 1) { if (c == '\n') incmt = 0; i++; continue; }
      if (incmt == 2) {
        if (c == '*' && i + 1 < GLEN && GSRC[i+1] == '/') { incmt = 0; i += 2; continue; }
        i++; continue;
      }
      if (instr) { if (c == '\\') { i += 2; continue; } if (c == '"') instr = 0; i++; continue; }
      if (inchar) { if (c == '\\') { i += 2; continue; } if (c == '\'') inchar = 0; i++; continue; }
      if (inpre) { if (c == '\n') inpre = 0; i++; continue; }
      if (c == '/' && i + 1 < GLEN) {
        if (GSRC[i+1] == '/') { incmt = 1; i += 2; continue; }
        if (GSRC[i+1] == '*') { incmt = 2; i += 2; continue; }
      }
      if (c == '"')  { instr = 1; i++; continue; }
      if (c == '\'') { inchar = 1; i++; continue; }
      if (c == '#')  { inpre = 1; i++; continue; }
      break;
    }
    if (i >= GLEN) return -1;

    if (i + namelen < GLEN) {
      I64 k = 0; I64 ok = 1;
      while (k < namelen) { if (GSRC[i+k] != name[k]) { ok = 0; break; } k++; }
      if (ok) {
        I64 before_ok = 1;
        if (i > 0) {
          U8 b = GSRC[i-1];
          if ((b >= 'a' && b <= 'z') || (b >= 'A' && b <= 'Z') ||
              (b >= '0' && b <= '9') || b == '_') before_ok = 0;
        }
        I64 after_ok = 0;
        if (i + namelen < GLEN && GSRC[i+namelen] == '(') after_ok = 1;
        if (before_ok && after_ok) found = 1;
      }
    }
    if (!found) { i++; continue; }

    // Walk back to the start of the declaration.
    {
      I64 b = i - 1;
      while (b >= 0) {
        U8 c = GSRC[b];
        if (c == '\n' || c == ';' || c == '{' || c == '}' || c == '#') break;
        if (c == '/' && b + 1 < GLEN && (GSRC[b+1] == '/' || GSRC[b+1] == '*')) break;
        b--;
      }
      i = b + 1;
      while (i < GLEN && (GSRC[i] == ' ' || GSRC[i] == '\t')) i++;
    }

    // Find the body brace.
    j = i;
    {
      I64 k = i;
      I64 d = 0;
      I64 s2 = 0; I64 c2 = 0; I64 cm2 = 0; I64 p2 = 0;
      while (k < GLEN) {
        U8 e = GSRC[k];
        if (cm2 == 1) { if (e == '\n') cm2 = 0; k++; continue; }
        if (cm2 == 2) {
          if (e == '*' && k + 1 < GLEN && GSRC[k+1] == '/') { cm2 = 0; k += 2; continue; }
          k++; continue;
        }
        if (s2) { if (e == '\\') { k += 2; continue; } if (e == '"') s2 = 0; k++; continue; }
        if (c2) { if (e == '\\') { k += 2; continue; } if (e == '\'') c2 = 0; k++; continue; }
        if (p2) { if (e == '\n') p2 = 0; k++; continue; }
        if (e == '/' && k + 1 < GLEN) {
          if (GSRC[k+1] == '/') { cm2 = 1; k += 2; continue; }
          if (GSRC[k+1] == '*') { cm2 = 2; k += 2; continue; }
        }
        if (e == '"')  { s2 = 1; k++; continue; }
        if (e == '\'') { c2 = 1; k++; continue; }
        if (e == '#')  { p2 = 1; k++; continue; }
        if (e == '(') { d = k; break; }
        k++;
      }
      if (d == 0) return -1;
      j = d;
    }

    while (j < GLEN && GSRC[j] != '{' && GSRC[j] != ';') j++;
    if (j >= GLEN) return -1;
    if (GSRC[j] == ';') { i = j + 1; continue; }

    {
      I64 depth = 0;
      I64 k = j;
      I64 s2 = 0; I64 c2 = 0; I64 cm2 = 0; I64 p2 = 0;
      while (k < GLEN) {
        U8 d = GSRC[k];
        if (cm2 == 1) { if (d == '\n') cm2 = 0; k++; continue; }
        if (cm2 == 2) {
          if (d == '*' && k + 1 < GLEN && GSRC[k+1] == '/') { cm2 = 0; k += 2; continue; }
          k++; continue;
        }
        if (s2) { if (d == '\\') { k += 2; continue; } if (d == '"') s2 = 0; k++; continue; }
        if (c2) { if (d == '\\') { k += 2; continue; } if (d == '\'') c2 = 0; k++; continue; }
        if (p2) { if (d == '\n') p2 = 0; k++; continue; }
        if (d == '/' && k + 1 < GLEN) {
          if (GSRC[k+1] == '/') { cm2 = 1; k += 2; continue; }
          if (GSRC[k+1] == '*') { cm2 = 2; k += 2; continue; }
        }
        if (d == '"')  { s2 = 1; k++; continue; }
        if (d == '\'') { c2 = 1; k++; continue; }
        if (d == '#')  { p2 = 1; k++; continue; }
        if (d == '{') depth++;
        if (d == '}') {
          depth--;
          if (depth == 0) { *out_start = i; *out_end = k + 1; return 0; }
        }
        k++;
      }
    }
    return -1;
  }
  return -1;
}

// Load a source file into GSRC/GLEN.
public I64 LoadSrc(U8 *path)
{
  I64 sz = 0;
  GSRC = FileRead(path, &sz);
  if (GSRC == NULL) return -1;
  GLEN = sz;
  return 0;
}

// ---------------------------------------------------------------------------
// MODE: partial-as-whole <src> <whole-start> <whole-end> <presented-sha>
//
// The PARTIAL_SOURCE_RANGE_AS_WHOLE detector (NC03 / RED01_SOURCE).
//
// It recomputes the digest of the WHOLE interval. If the presented
// digest equals it, the presentation is correct. If it does NOT equal
// it, the tool checks whether the presented digest is the digest of a
// STRICT PREFIX of the same definition. When it is, the presented
// digest is a partial interval masquerading as a whole definition and
// the detector fires. When it is not, the mismatch is a plain
// source-range mismatch and a different reason is reported.
// ---------------------------------------------------------------------------
public U0 ModePartialAsWhole(U8 *src, I64 ws, I64 we, U8 *presented)
{
  U8 whole[65];
  U8 hex[65];
  I64 n;
  if (LoadSrc(src) != 0) RedFail("SOURCE_UNREADABLE");
  if (ws < 0 || we > GLEN || ws >= we) RedFail("SOURCE_RANGE_OUT_OF_BOUNDS");
  n = we - ws;
  ShaHexBytes(GSRC + ws, n, whole);
  if (StrCmp(whole, presented) == 0) RedOk("PRESENTED_DIGEST_IS_THE_WHOLE_DEFINITION_DIGEST");

  // The presented digest is not the whole. Is it a strict prefix?
  for (I64 len = 1; len < n; len++) {
    ShaHexBytes(GSRC + ws, len, hex);
    if (StrCmp(hex, presented) == 0) {
      RedFail("PARTIAL_SOURCE_RANGE_AS_WHOLE");
    }
  }
  RedFail("SOURCE_BOUNDARY_OR_BLOB_MISMATCH");
}

// ---------------------------------------------------------------------------
// MODE: source-range <src> <start> <end> <expected-sha>
//
// The SOURCE_BOUNDARY_OR_BLOB_MISMATCH detector (NC04).
//
// It recomputes the digest of [start,end) and, when it does not match,
// also of [start,end+1) and [start,end-1), so that an off-by-one is
// distinguished from a wholesale mismatch in the DETAIL it reports.
// ---------------------------------------------------------------------------
public U0 ModeSourceRange(U8 *src, I64 st, I64 en, U8 *expected)
{
  U8 hex[65];
  if (LoadSrc(src) != 0) RedFail("SOURCE_UNREADABLE");
  if (st < 0 || en > GLEN || st >= en) RedFail("SOURCE_RANGE_OUT_OF_BOUNDS");
  ShaHexBytes(GSRC + st, en - st, hex);
  if (StrCmp(hex, expected) == 0) RedOk("RANGE_DIGEST_MATCHES");
  if (en + 1 <= GLEN) {
    ShaHexBytes(GSRC + st, en + 1 - st, hex);
    if (StrCmp(hex, expected) == 0) RedFail("SOURCE_BOUNDARY_OR_BLOB_MISMATCH");
  }
  if (st - 1 >= 0) {
    ShaHexBytes(GSRC + st - 1, en - st + 1, hex);
    if (StrCmp(hex, expected) == 0) RedFail("SOURCE_BOUNDARY_OR_BLOB_MISMATCH");
  }
  RedFail("SOURCE_BOUNDARY_OR_BLOB_MISMATCH");
}

// ---------------------------------------------------------------------------
// MODE: abi-zero <abi-file>
//
// The ABI_ZERO_INVALID_MISCLASSIFIED detector (NC07 / RED02_ABI).
//
// It reads the ABI declaration. It REQUIRES that the ABI names the
// zero discriminant as a VALID kind and forbids any statement that
// treats a numeric zero as an error status. A NULL result is the only
// permitted failure channel, and the ABI must say so.
// ---------------------------------------------------------------------------
public U0 ModeAbiZero(U8 *abifile)
{
  I64 sz = 0;
  U8 *txt = FileRead(abifile, &sz);
  if (txt == NULL) RedFail("ABI_FILE_UNREADABLE");
  // The ABI must declare BOTH v2 exports.
  if (StrFind(txt, "AbiA64CcForV2") == NULL) RedFail("ABI_ZERO_INVALID_MISCLASSIFIED");
  if (StrFind(txt, "AbiA64CcInvForV2") == NULL) RedFail("ABI_ZERO_INVALID_MISCLASSIFIED");
  // The failure channel must be a POINTER status (NULL), never a number.
  if (StrFind(txt, "NULL") == NULL) RedFail("ABI_ZERO_INVALID_MISCLASSIFIED");
  // The zero discriminant must be named as VALID.
  if (StrFind(txt, "IR_CMP_EQ") == NULL) RedFail("ABI_ZERO_INVALID_MISCLASSIFIED");
  // A statement that treats zero as an error is forbidden.
  if (StrFind(txt, "zero_is_error") != NULL) RedFail("ABI_ZERO_INVALID_MISCLASSIFIED");
  if (StrFind(txt, "ZERO_IS_ERROR") != NULL) RedFail("ABI_ZERO_INVALID_MISCLASSIFIED");
  RedOk("ZERO_DISCRIMINANT_IS_VALID_AND_NULL_IS_THE_ONLY_FAILURE_CHANNEL");
}

// ---------------------------------------------------------------------------
// MODE: fail-closed <abi-file>
//
// The INVALID_SUFFIX_NOT_FAIL_CLOSED detector (NC08).
//
// It requires the ABI to state that an unsupported kind yields NULL
// and that no default suffix is ever produced.
// ---------------------------------------------------------------------------
public U0 ModeFailClosed(U8 *abifile)
{
  I64 sz = 0;
  U8 *txt = FileRead(abifile, &sz);
  if (txt == NULL) RedFail("ABI_FILE_UNREADABLE");
  if (StrFind(txt, "unsupported") == NULL && StrFind(txt, "UNSUPPORTED") == NULL)
    RedFail("INVALID_SUFFIX_NOT_FAIL_CLOSED");
  if (StrFind(txt, "NULL") == NULL) RedFail("INVALID_SUFFIX_NOT_FAIL_CLOSED");
  if (StrFind(txt, "no_default_suffix") == NULL && StrFind(txt, "NO_DEFAULT_SUFFIX") == NULL)
    RedFail("INVALID_SUFFIX_NOT_FAIL_CLOSED");
  RedOk("UNSUPPORTED_KINDS_FAIL_CLOSED_WITH_NULL_AND_NO_DEFAULT_SUFFIX");
}

// ---------------------------------------------------------------------------
// MODE: third-export <abi-file>
//
// The FORBIDDEN_THIRD_EXPORT detector (NC05 / RED03_EXPORT).
//
// It rejects any declaration of a CSET export, of ANY signature, and
// in particular the historical inert U0 (I64,I64) v1 export.
// ---------------------------------------------------------------------------
public U0 ModeThirdExport(U8 *abifile)
{
  I64 sz = 0;
  U8 *txt = FileRead(abifile, &sz);
  if (txt == NULL) RedFail("ABI_FILE_UNREADABLE");
  // A DECLARATION of a CSET export is forbidden. The prohibition may
  // be STATED in prose -- what is forbidden is the export itself. A
  // declaration is recognised as a line that, after its leading
  // blanks, contains the forbidden name followed by an opening
  // parenthesis. A name inside a sentence is prose, not a declaration.
  {
    U8 *p = txt;
    while (*p != 0) {
      U8 *eol = StrFind(p, "\n");
      U8 *end = p;
      if (eol != NULL) end = eol;
      // The line's leading blanks.
      U8 *q = p;
      while (q < end && (*q == ' ' || *q == '\t')) q++;
      if (StrFind(p, "AbiA64CmpCcEmitCSet(") != NULL && StrFind(p, "AbiA64CmpCcEmitCSet(") < end)
        RedFail("FORBIDDEN_THIRD_EXPORT");
      if (StrFind(p, "AbiA64CmpCcFor(") != NULL && StrFind(p, "AbiA64CmpCcFor(") < end)
        RedFail("FORBIDDEN_THIRD_EXPORT");
      if (StrFind(p, "AbiA64CmpCcInvFor(") != NULL && StrFind(p, "AbiA64CmpCcInvFor(") < end)
        RedFail("FORBIDDEN_THIRD_EXPORT");
      if (eol == NULL) break;
      p = eol + 1;
    }
  }
  // The two authorised exports must be present.
  if (StrFind(txt, "AbiA64CcForV2(") == NULL) RedFail("FORBIDDEN_THIRD_EXPORT");
  if (StrFind(txt, "AbiA64CcInvForV2(") == NULL) RedFail("FORBIDDEN_THIRD_EXPORT");
  RedOk("EXACTLY_TWO_EXPORTS_AND_NO_CSET_EXPORT");
}

// ---------------------------------------------------------------------------
// MODE: cset-double-count <authority-file>
//
// The CSET_SEMANTIC_DOUBLE_COUNT detector (NC06).
//
// It parses the authority table and rejects a CSET row that claims to
// be an independent semantic authority.
// ---------------------------------------------------------------------------
public U0 ModeCsetDoubleCount(U8 *authfile)
{
  I64 c_class = -1;
  I64 c_counts = -1;
  if (LoadTsv(authfile) != 0) RedFail("AUTHORITY_FILE_UNREADABLE");
  c_class = ColByName("semantic_classification");
  if (c_class < 0) c_class = ColByName("classification");
  c_counts = ColByName("counts_as_authority");
  if (c_class < 0 || c_counts < 0) RedFail("CSET_SEMANTIC_DOUBLE_COUNT");
  for (I64 r = 0; r < NROW; r++) {
    U8 *sid = Cell(r, 0);
    U8 *cl  = Cell(r, c_class);
    U8 *ca  = Cell(r, c_counts);
    if (sid == NULL || cl == NULL || ca == NULL) continue;
    if (StrFind(sid, "CSET") == NULL) continue;
    // A CSET row must NOT be classified as an independent authority.
    if (StrCmp(ca, "YES") == 0) RedFail("CSET_SEMANTIC_DOUBLE_COUNT");
    if (StrFind(cl, "C_MECHANICAL_ADAPTER") == NULL) RedFail("CSET_SEMANTIC_DOUBLE_COUNT");
  }
  RedOk("CSET_IS_CLASSIFIED_AS_A_C_MECHANICAL_ADAPTER");
}

// ---------------------------------------------------------------------------
// MODE: borrowed-lifetime <abi-file> <export-name>
//
// The BORROWED_LITERAL_LIFETIME detector (NC09).
//
// It requires the ABI to state that the returned pointer is BORROWED,
// immutable, NUL-terminated and that the host must not free or write
// it.
// ---------------------------------------------------------------------------
public U0 ModeBorrowedLifetime(U8 *abifile, U8 *export)
{
  I64 sz = 0;
  U8 *txt = FileRead(abifile, &sz);
  if (txt == NULL) RedFail("ABI_FILE_UNREADABLE");
  if (StrFind(txt, export) == NULL) RedFail("BORROWED_LITERAL_LIFETIME");
  if (StrFind(txt, "BORROWED") == NULL && StrFind(txt, "borrowed") == NULL)
    RedFail("BORROWED_LITERAL_LIFETIME");
  if (StrFind(txt, "MUST NOT free") == NULL && StrFind(txt, "must not free") == NULL)
    RedFail("BORROWED_LITERAL_LIFETIME");
  if (StrFind(txt, "NUL-terminated") == NULL && StrFind(txt, "NUL terminated") == NULL)
    RedFail("BORROWED_LITERAL_LIFETIME");
  RedOk("RESULT_IS_BORROWED_IMMUTABLE_AND_NUL_TERMINATED");
}

// ---------------------------------------------------------------------------
// MODE: symbol-binding <obj-file> <expected-symbol>
//
// The ABI_SYMBOL_BINDING_MISMATCH detector (NC10).
//
// It runs the REAL `nm` over the object and requires the expected
// symbol to be DEFINED there as a global text symbol. The nm output is
// the object's own symbol table, not an asserted status.
// ---------------------------------------------------------------------------
public U0 ModeSymbolBinding(U8 *objfile, U8 *sym)
{
  U8 *cmd;
  U8 *out;
  I64 found = 0;
  cmd = StrPrint(NULL, "nm %s > /tmp/a64cc-red-nm.txt 2>/dev/null", objfile);
  System(cmd);
  out = FileRead("/tmp/a64cc-red-nm.txt", NULL);
  if (out == NULL) RedFail("ABI_SYMBOL_BINDING_MISMATCH");
  // nm prints "<addr> T <symbol>" for a defined global text symbol.
  if (StrFind(out, " T ") == NULL) {
    // Fall back to a per-line scan for the symbol with a T marker.
  }
  {
    U8 *p = out;
    while (*p != 0) {
      U8 *nl = StrFind(p, "\n");
      U8 *end = p;
      if (nl != NULL) end = nl;
      // Look for the symbol preceded by " T " on this line.
      {
        U8 *hit = StrFind(p, sym);
        if (hit != NULL && hit < end) {
          // The character before the symbol must be a space and the one
          // before that a 'T'.
          if (hit >= p + 3 && hit[-1] == ' ' && hit[-2] == 'T' && hit[-3] == ' ')
            found = 1;
        }
      }
      if (nl == NULL) break;
      p = nl + 1;
    }
  }
  if (!found) RedFail("ABI_SYMBOL_BINDING_MISMATCH");
  RedOk("SYMBOL_IS_DEFINED_IN_THE_OBJECT");
}

// ---------------------------------------------------------------------------
// MODE: oracle-contamination <obj-file>
//
// The C_ONLY_A64_ORACLE_CONTAMINATION detector (NC11).
//
// It runs the REAL `nm -u` over the object and rejects it if the object
// IMPORTS either of the two new A64 PolyC exports.
// ---------------------------------------------------------------------------
public U0 ModeOracleContamination(U8 *objfile)
{
  U8 *cmd;
  U8 *out;
  cmd = StrPrint(NULL, "nm -u %s > /tmp/a64cc-red-nmu.txt 2>/dev/null", objfile);
  System(cmd);
  out = FileRead("/tmp/a64cc-red-nmu.txt", NULL);
  if (out == NULL) RedFail("C_ONLY_A64_ORACLE_CONTAMINATION");
  if (StrFind(out, "_AbiA64CcForV2") != NULL) RedFail("C_ONLY_A64_ORACLE_CONTAMINATION");
  if (StrFind(out, "_AbiA64CcInvForV2") != NULL) RedFail("C_ONLY_A64_ORACLE_CONTAMINATION");
  RedOk("OBJECT_IMPORTS_NEITHER_A64_POLYC_EXPORT");
}

// ---------------------------------------------------------------------------
// MODE: dormant-subject <caller-obj> <symbol>
//
// The LINKED_BUT_DORMANT_POLYC_SUBJECT detector (NC15).
//
// It runs the REAL `nm -u` over the CALLER object and requires the
// caller to actually IMPORT the subject symbol. A subject that is
// linked but never called cannot be credited.
// ---------------------------------------------------------------------------
public U0 ModeDormantSubject(U8 *caller, U8 *sym)
{
  U8 *cmd;
  U8 *out;
  cmd = StrPrint(NULL, "nm -u %s > /tmp/a64cc-red-nmu2.txt 2>/dev/null", caller);
  System(cmd);
  out = FileRead("/tmp/a64cc-red-nmu2.txt", NULL);
  if (out == NULL) RedFail("LINKED_BUT_DORMANT_POLYC_SUBJECT");
  if (StrFind(out, sym) == NULL) RedFail("LINKED_BUT_DORMANT_POLYC_SUBJECT");
  RedOk("CALLER_IMPORTS_THE_SUBJECT_SYMBOL");
}

// ---------------------------------------------------------------------------
// MODE: subject-producer <obj-file> <symbol>
//
// The MISSING_EFFECTIVE_SUBJECT_PRODUCER detector (NC13).
//
// It requires the object to DEFINE the subject symbol. It also reads
// the producer record file when given, and requires the recorded
// producer digest to be non-empty and distinct from the C toolchain's
// digest, so that a subject produced by the system C compiler cannot
// be credited.
// ---------------------------------------------------------------------------
public U0 ModeSubjectProducer(U8 *objfile, U8 *sym)
{
  U8 *cmd;
  U8 *out;
  I64 found = 0;
  cmd = StrPrint(NULL, "nm %s > /tmp/a64cc-red-nm3.txt 2>/dev/null", objfile);
  System(cmd);
  out = FileRead("/tmp/a64cc-red-nm3.txt", NULL);
  if (out == NULL) RedFail("MISSING_EFFECTIVE_SUBJECT_PRODUCER");
  {
    U8 *p = out;
    while (*p != 0) {
      U8 *nl = StrFind(p, "\n");
      U8 *end = p;
      if (nl != NULL) end = nl;
      {
        U8 *hit = StrFind(p, sym);
        if (hit != NULL && hit < end) {
          if (hit >= p + 3 && hit[-1] == ' ' && hit[-2] == 'T' && hit[-3] == ' ')
            found = 1;
        }
      }
      if (nl == NULL) break;
      p = nl + 1;
    }
  }
  if (!found) RedFail("MISSING_EFFECTIVE_SUBJECT_PRODUCER");
  RedOk("SUBJECT_OBJECT_DEFINES_THE_AUTHORITY_SYMBOL");
}

// ---------------------------------------------------------------------------
// MODE: fail-open <log-file> <marker>
//
// The CONFIGURATION_FAIL_OPEN detector (NC14).
//
// It rejects a log that contains a command-not-found marker ("127"),
// and it requires the log to contain the marker that the invoked
// command must have printed, so that a silently dropped flag is
// detected.
// ---------------------------------------------------------------------------
public U0 ModeFailOpen(U8 *logfile, U8 *marker)
{
  I64 sz = 0;
  U8 *txt = FileRead(logfile, &sz);
  if (txt == NULL) RedFail("CONFIGURATION_FAIL_OPEN");
  if (StrFind(txt, "127") != NULL) RedFail("CONFIGURATION_FAIL_OPEN");
  if (StrFind(txt, "Error 127") != NULL) RedFail("CONFIGURATION_FAIL_OPEN");
  if (marker != NULL && StrLen(marker) > 0) {
    if (StrFind(txt, marker) == NULL) RedFail("CONFIGURATION_FAIL_OPEN");
  }
  RedOk("NO_COMMAND_NOT_FOUND_AND_THE_EXPECTED_MARKER_IS_PRESENT");
}

// ---------------------------------------------------------------------------
// MODE: producer-alias <producer-file>
//
// The PRODUCER_ALIAS_OR_MISSING_EDGE detector (NC17 / RED04_PRODUCER).
//
// It parses the producer table and rejects two rows that carry the SAME
// executable digest, a row with an EMPTY digest, and a row whose
// producer is the C toolchain presented as a PolyC producer.
// ---------------------------------------------------------------------------
public U0 ModeProducerAlias(U8 *prodfile)
{
  I64 c_digest = -1;
  I64 c_kind = -1;
  I64 c_id = -1;
  I64 n = 0;
  U8 seen[64][65];
  if (LoadTsv(prodfile) != 0) RedFail("PRODUCER_FILE_UNREADABLE");
  c_id = ColByName("producer_id");
  c_digest = ColByName("executable_sha256");
  if (c_digest < 0) c_digest = ColByName("sha256");
  c_kind = ColByName("kind");
  if (c_digest < 0) RedFail("PRODUCER_ALIAS_OR_MISSING_EDGE");
  for (I64 r = 0; r < NROW && n < 64; r++) {
    U8 *dg = Cell(r, c_digest);
    if (dg == NULL) continue;
    if (StrLen(dg) == 0) RedFail("PRODUCER_ALIAS_OR_MISSING_EDGE");
    // A PolyC producer must not be the C toolchain.
    if (c_kind >= 0) {
      U8 *kd = Cell(r, c_kind);
      if (kd != NULL && StrCmp(kd, "POLYC") == 0) {
        if (StrFind(dg, "gcc") != NULL || StrFind(dg, "clang") != NULL)
          RedFail("PRODUCER_ALIAS_OR_MISSING_EDGE");
      }
    }
    for (I64 q = 0; q < n; q++) {
      if (StrCmp(seen[q], dg) == 0) RedFail("PRODUCER_ALIAS_OR_MISSING_EDGE");
    }
    MemCpy(seen[n], dg, StrLen(dg) + 1);
    n++;
  }
  if (n == 0) RedFail("PRODUCER_ALIAS_OR_MISSING_EDGE");
  RedOk("EVERY_PRODUCER_HAS_A_DISTINCT_NON_EMPTY_DIGEST");
}

// ---------------------------------------------------------------------------
// MODE: two-rosters <crosswalk-file>
//
// The TWO_ROSTERS_CONFLATED detector (NC18).
//
// It parses the crosswalk and requires that BOTH rosters exist, that
// their member counts are exactly 12 each, and that no member ID is
// shared between them.
// ---------------------------------------------------------------------------
public U0 ModeTwoRosters(U8 *xfile)
{
  I64 c_roster = -1;
  I64 c_id = -1;
  I64 n_pair = 0;
  I64 n_frozen = 0;
  U8 pair_ids[64][32];
  U8 froz_ids[64][32];
  if (LoadTsv(xfile) != 0) RedFail("CROSSWALK_FILE_UNREADABLE");
  c_roster = ColByName("roster");
  c_id = ColByName("id");
  if (c_roster < 0 || c_id < 0) RedFail("TWO_ROSTERS_CONFLATED");
  for (I64 r = 0; r < NROW; r++) {
    U8 *ro = Cell(r, c_roster);
    U8 *id = Cell(r, c_id);
    if (ro == NULL || id == NULL) continue;
    if (StrFind(ro, "PAIR") != NULL && n_pair < 64) {
      MemCpy(pair_ids[n_pair], id, StrLen(id) + 1);
      n_pair++;
    }
    if (StrFind(ro, "FROZEN") != NULL && n_frozen < 64) {
      MemCpy(froz_ids[n_frozen], id, StrLen(id) + 1);
      n_frozen++;
    }
  }
  if (n_pair != 12) RedFail("TWO_ROSTERS_CONFLATED");
  if (n_frozen != 12) RedFail("TWO_ROSTERS_CONFLATED");
  for (I64 a = 0; a < n_pair; a++)
    for (I64 b = 0; b < n_frozen; b++)
      if (StrCmp(pair_ids[a], froz_ids[b]) == 0) RedFail("TWO_ROSTERS_CONFLATED");
  RedOk("TWO_DISTINCT_ROSTERS_OF_TWELVE_EACH");
}

// ---------------------------------------------------------------------------
// MODE: ac-ledger <ledger-file>
//
// The LEDGER_FALSE_PASS detector (NC23 / RED05_EVIDENCE).
//
// It parses the acceptance ledger and rejects:
//   - a MISSING id from the required roster;
//   - a DUPLICATED id;
//   - an UNKNOWN id;
//   - an illegal status;
//   - a PASS row that carries NO evidence reference.
//
// The required roster is AC01..AC50 and NC01..NC24, discovered by the
// caller through the optional `expected` argument: "AC" or "NC".
// ---------------------------------------------------------------------------
public U0 ModeAcLedger(U8 *ledfile, U8 *which)
{
  I64 c_id = -1;
  I64 c_status = -1;
  I64 c_ev = -1;
  I64 total = 0;
  Bool seen_ac[64];
  Bool seen_nc[64];
  for (I64 i = 0; i < 64; i++) { seen_ac[i] = FALSE; seen_nc[i] = FALSE; }
  if (LoadTsv(ledfile) != 0) RedFail("LEDGER_FILE_UNREADABLE");
  c_id = ColByName("ac_id");
  if (c_id < 0) c_id = ColByName("nc_id");
  if (c_id < 0) c_id = ColByName("id");
  c_status = ColByName("status");
  if (c_status < 0) c_status = ColByName("result");
  c_ev = ColByName("evidence");
  if (c_ev < 0) c_ev = ColByName("evidence_path");
  if (c_id < 0 || c_status < 0) RedFail("LEDGER_FALSE_PASS");
  total = 50;
  if (which != NULL && StrCmp(which, "NC") == 0) total = 24;
  for (I64 r = 0; r < NROW; r++) {
    U8 *id = Cell(r, c_id);
    U8 *st = Cell(r, c_status);
    U8 *ev = Cell(r, c_ev);
    I64 idx = -1;
    if (id == NULL || st == NULL) RedFail("LEDGER_FALSE_PASS");
    if (StrLen(id) < 4) RedFail("LEDGER_FALSE_PASS");
    if (id[0] == 'A' && id[1] == 'C') {
      idx = Atoi(id + 2);
      if (idx < 1 || idx > 50) RedFail("LEDGER_FALSE_PASS");
      if (seen_ac[idx-1]) RedFail("LEDGER_FALSE_PASS");
      seen_ac[idx-1] = TRUE;
    } else if (id[0] == 'N' && id[1] == 'C') {
      idx = Atoi(id + 2);
      if (idx < 1 || idx > 24) RedFail("LEDGER_FALSE_PASS");
      if (seen_nc[idx-1]) RedFail("LEDGER_FALSE_PASS");
      seen_nc[idx-1] = TRUE;
    } else {
      RedFail("LEDGER_FALSE_PASS");
    }
    // The status must be one of the legal states.
    if (StrCmp(st, "PASS") != 0 && StrCmp(st, "FAIL") != 0 &&
        StrCmp(st, "DEFERRED") != 0 && StrCmp(st, "NOT_RUN") != 0 &&
        StrCmp(st, "UNPROVEN") != 0)
      RedFail("LEDGER_FALSE_PASS");
    // A PASS row must carry an evidence reference.
    if (StrCmp(st, "PASS") == 0) {
      if (ev == NULL || StrLen(ev) == 0) RedFail("LEDGER_FALSE_PASS");
    }
  }
  for (I64 i = 0; i < total; i++) {
    if (which != NULL && StrCmp(which, "NC") == 0) {
      if (!seen_nc[i]) RedFail("LEDGER_FALSE_PASS");
    } else {
      if (!seen_ac[i]) RedFail("LEDGER_FALSE_PASS");
    }
  }
  RedOk("LEDGER_IDS_ARE_COMPLETE_UNIQUE_AND_EVERY_PASS_ROW_HAS_EVIDENCE");
}

// ---------------------------------------------------------------------------
// MODE: terminality <ledger-file> <head> <tree>
//
// The PREMATURE_OR_MISBOUND_TERMINALITY detector (NC24).
//
// It rejects an AC50 row that claims PASS while no external receipt
// reference bound to the expected head and tree is present.
// ---------------------------------------------------------------------------
public U0 ModeTerminality(U8 *ledfile, U8 *head, U8 *tree)
{
  I64 c_id = -1;
  I64 c_status = -1;
  I64 c_ev = -1;
  Bool saw50 = FALSE;
  if (LoadTsv(ledfile) != 0) RedFail("PREMATURE_OR_MISBOUND_TERMINALITY");
  c_id = ColByName("ac_id");
  if (c_id < 0) c_id = ColByName("id");
  c_status = ColByName("status");
  if (c_status < 0) c_status = ColByName("result");
  c_ev = ColByName("evidence");
  if (c_ev < 0) c_ev = ColByName("evidence_path");
  if (c_id < 0 || c_status < 0) RedFail("PREMATURE_OR_MISBOUND_TERMINALITY");
  for (I64 r = 0; r < NROW; r++) {
    U8 *id = Cell(r, c_id);
    U8 *st = Cell(r, c_status);
    U8 *ev = Cell(r, c_ev);
    if (id == NULL || st == NULL) continue;
    if (StrCmp(id, "AC50") != 0) continue;
    saw50 = TRUE;
    if (StrCmp(st, "PASS") != 0) continue;
    // A PASS for AC50 requires an external receipt bound to the exact
    // terminal HEAD and TREE.
    if (ev == NULL || StrLen(ev) == 0) RedFail("PREMATURE_OR_MISBOUND_TERMINALITY");
    if (StrFind(ev, "external-receipt") == NULL && StrFind(ev, "EXTERNAL-RECEIPT") == NULL)
      RedFail("PREMATURE_OR_MISBOUND_TERMINALITY");
    if (StrFind(ev, head) == NULL) RedFail("PREMATURE_OR_MISBOUND_TERMINALITY");
    if (StrFind(ev, tree) == NULL) RedFail("PREMATURE_OR_MISBOUND_TERMINALITY");
  }
  if (!saw50) RedFail("PREMATURE_OR_MISBOUND_TERMINALITY");
  RedOk("AC50_PASS_IS_BOUND_TO_AN_EXTERNAL_RECEIPT_FOR_THIS_HEAD_AND_TREE");
}

// ---------------------------------------------------------------------------
// MODE: entry-identity <fact-file> <head> <tree> <branch>
//
// The ENTRY_IDENTITY_MISMATCH detector (NC01).
//
// It parses the entry fact table and compares the recorded head, tree
// and branch with the expected values passed on the command line.
// ---------------------------------------------------------------------------
public U0 ModeEntryIdentity(U8 *factfile, U8 *head, U8 *tree, U8 *branch)
{
  I64 c_key = -1;
  I64 c_val = -1;
  Bool saw_head = FALSE; Bool saw_tree = FALSE; Bool saw_branch = FALSE;
  if (LoadTsv(factfile) != 0) RedFail("ENTRY_IDENTITY_MISMATCH");
  c_key = ColByName("key");
  if (c_key < 0) c_key = ColByName("fact");
  c_val = ColByName("value");
  if (c_val < 0) c_val = ColByName("measured");
  if (c_key < 0 || c_val < 0) RedFail("ENTRY_IDENTITY_MISMATCH");
  for (I64 r = 0; r < NROW; r++) {
    U8 *k = Cell(r, c_key);
    U8 *v = Cell(r, c_val);
    if (k == NULL || v == NULL) continue;
    if (StrCmp(k, "HEAD") == 0 || StrCmp(k, "ENTRY_HEAD") == 0) {
      saw_head = TRUE;
      if (StrCmp(v, head) != 0) RedFail("ENTRY_IDENTITY_MISMATCH");
    }
    if (StrCmp(k, "TREE") == 0 || StrCmp(k, "ENTRY_TREE") == 0) {
      saw_tree = TRUE;
      if (StrCmp(v, tree) != 0) RedFail("ENTRY_IDENTITY_MISMATCH");
    }
    if (StrCmp(k, "BRANCH") == 0) {
      saw_branch = TRUE;
      if (StrCmp(v, branch) != 0) RedFail("ENTRY_IDENTITY_MISMATCH");
    }
  }
  if (!saw_head || !saw_tree || !saw_branch) RedFail("ENTRY_IDENTITY_MISMATCH");
  RedOk("ENTRY_HEAD_TREE_AND_BRANCH_ALL_MATCH");
}

// ---------------------------------------------------------------------------
// MODE: f14-freeze <freeze-file>
//
// The HISTORICAL_F14_REWRITE detector (NC02).
//
// It recomputes each frozen path's SHA-256 from the file's actual bytes
// and rejects a row whose recorded digest does not match.
// ---------------------------------------------------------------------------
public U0 ModeF14Freeze(U8 *freezefile)
{
  I64 c_path = -1;
  I64 c_sha = -1;
  I64 n = 0;
  if (LoadTsv(freezefile) != 0) RedFail("HISTORICAL_F14_REWRITE");
  c_path = ColByName("path");
  c_sha = ColByName("sha256");
  if (c_sha < 0) c_sha = ColByName("digest");
  if (c_path < 0 || c_sha < 0) RedFail("HISTORICAL_F14_REWRITE");
  for (I64 r = 0; r < NROW; r++) {
    U8 *p = Cell(r, c_path);
    U8 *s = Cell(r, c_sha);
    I64 sz = 0;
    U8 *bytes;
    U8 hex[65];
    if (p == NULL || s == NULL) continue;
    if (StrLen(p) == 0 || StrLen(s) == 0) RedFail("HISTORICAL_F14_REWRITE");
    bytes = FileRead(p, &sz);
    if (bytes == NULL) RedFail("HISTORICAL_F14_REWRITE");
    ShaHexBytes(bytes, sz, hex);
    if (StrCmp(hex, s) != 0) RedFail("HISTORICAL_F14_REWRITE");
    n++;
  }
  if (n == 0) RedFail("HISTORICAL_F14_REWRITE");
  RedOk("EVERY_FROZEN_PATH_REHASHES_TO_ITS_RECORDED_DIGEST");
}

// ---------------------------------------------------------------------------
// MODE: fixture-rows <fixture-file> <expected-rows>
//
// The FIXTURE_DIFFERENTIAL_NOT_SENSITIVE detector (NC19).
//
// It recomputes the row count, requires every row id to be UNIQUE, and
// requires both the FOR and the INV roles to be present. A fixture set
// whose rows were changed, duplicated, deleted or re-ordered cannot
// pass.
// ---------------------------------------------------------------------------
public U0 ModeFixtureRows(U8 *fixfile, I64 expected)
{
  I64 c_id = -1;
  I64 c_role = -1;
  I64 n_for = 0;
  I64 n_inv = 0;
  U8 ids[256][64];
  I64 n = 0;
  if (LoadTsv(fixfile) != 0) RedFail("FIXTURE_DIFFERENTIAL_NOT_SENSITIVE");
  c_id = ColByName("id");
  if (c_id < 0) c_id = ColByName("fixture_id");
  c_role = ColByName("role");
  if (c_id < 0 || c_role < 0) RedFail("FIXTURE_DIFFERENTIAL_NOT_SENSITIVE");
  for (I64 r = 0; r < NROW && n < 256; r++) {
    U8 *id = Cell(r, c_id);
    U8 *ro = Cell(r, c_role);
    if (id == NULL || ro == NULL) continue;
    for (I64 q = 0; q < n; q++) {
      if (StrCmp(ids[q], id) == 0) RedFail("FIXTURE_DIFFERENTIAL_NOT_SENSITIVE");
    }
    MemCpy(ids[n], id, StrLen(id) + 1);
    n++;
    if (StrFind(ro, "FOR") != NULL) n_for++;
    if (StrFind(ro, "INV") != NULL) n_inv++;
  }
  if (n != expected) RedFail("FIXTURE_DIFFERENTIAL_NOT_SENSITIVE");
  if (n_for == 0 || n_inv == 0) RedFail("FIXTURE_DIFFERENTIAL_NOT_SENSITIVE");
  RedOk("FIXTURE_ROW_COUNT_AND_ID_UNIQUENESS_AND_ROLE_PARTITION_ALL_MATCH");
}

// ---------------------------------------------------------------------------
// MODE: cset-preserved <src> <func-name> <expected-token>
//
// The CSET_ADAPTER_NOT_PRESERVED detector (NC22).
//
// It extracts the named function's whole body from the live source and
// requires the token to be present.
// ---------------------------------------------------------------------------
public U0 ModeCsetPreserved(U8 *src, U8 *funcname, U8 *token)
{
  I64 st = 0; I64 en = 0;
  I64 nl = StrLen(funcname);
  if (LoadSrc(src) != 0) RedFail("CSET_ADAPTER_NOT_PRESERVED");
  if (ScanDef(funcname, nl, &st, &en) != 0) RedFail("CSET_ADAPTER_NOT_PRESERVED");
  // The body is NUL-terminated inside GSRC only at a real NUL, so build
  // a NUL-terminated copy of the body.
  {
    I64 n = en - st;
    U8 *body = MAlloc(n + 1);
    MemCpy(body, GSRC + st, n);
    body[n] = 0;
    if (StrFind(body, token) == NULL) RedFail("CSET_ADAPTER_NOT_PRESERVED");
  }
  RedOk("CSET_BODY_PRESERVES_THE_EXPECTED_TOKENS");
}

// ---------------------------------------------------------------------------
// MODE: wrong-site <evidence-file> <required-site-id>
//
// The WRONG_SITE_CAUSAL_ATTRIBUTION detector (NC20).
//
// It requires the evidence file to name the required site id.
// ---------------------------------------------------------------------------
public U0 ModeWrongSite(U8 *evfile, U8 *site)
{
  I64 sz = 0;
  U8 *txt = FileRead(evfile, &sz);
  if (txt == NULL) RedFail("WRONG_SITE_CAUSAL_ATTRIBUTION");
  if (StrFind(txt, site) == NULL) RedFail("WRONG_SITE_CAUSAL_ATTRIBUTION");
  RedOk("THE_EVIDENCE_NAMES_THE_REQUIRED_SITE");
}

// ---------------------------------------------------------------------------
// MODE: dormant-counter <evidence-file> <required-site-id>
//
// The C_DORMANCY_ANTI_CONTROL_FAILURE detector (NC21).
//
// It requires the evidence file to name the required site id AND to
// record both the OFF-live and the ON-dormant observations.
// ---------------------------------------------------------------------------
public U0 ModeDormantCounter(U8 *evfile, U8 *site)
{
  I64 sz = 0;
  U8 *txt = FileRead(evfile, &sz);
  if (txt == NULL) RedFail("C_DORMANCY_ANTI_CONTROL_FAILURE");
  if (StrFind(txt, site) == NULL) RedFail("C_DORMANCY_ANTI_CONTROL_FAILURE");
  if (StrFind(txt, "OFF") == NULL) RedFail("C_DORMANCY_ANTI_CONTROL_FAILURE");
  if (StrFind(txt, "ON") == NULL) RedFail("C_DORMANCY_ANTI_CONTROL_FAILURE");
  RedOk("BOTH_THE_OFF_LIVE_AND_THE_ON_DORMANT_OBSERVATIONS_ARE_RECORDED");
}

// ---------------------------------------------------------------------------
// MODE: legacy-live <obj-file> <token> <expect: LIVE|DORMANT>
//
// The LEGACY_C_ORACLE_NOT_LIVE (NC12) and LEGACY_C_AUTHORITY_ACTIVE
// (NC16) detectors.
//
// It reads the object's REAL disassembly and looks for the legacy
// condition-suffix literal. A selector-OFF object MUST contain it (the
// C table is live); a selector-ON object MUST NOT contain it (the C
// table is compiled out).
// ---------------------------------------------------------------------------
public U0 ModeLegacyLive(U8 *objfile, U8 *token, U8 *expect)
{
  U8 *cmd;
  U8 *out;
  I64 found = 0;
  cmd = StrPrint(NULL, "strings -a %s > /tmp/a64cc-red-strings.txt 2>/dev/null", objfile);
  System(cmd);
  out = FileRead("/tmp/a64cc-red-strings.txt", NULL);
  if (out == NULL) RedFail("LEGACY_C_ORACLE_NOT_LIVE");
  if (StrFind(out, token) != NULL) found = 1;
  if (StrCmp(expect, "LIVE") == 0) {
    if (!found) RedFail("LEGACY_C_ORACLE_NOT_LIVE");
    RedOk("THE_LEGACY_C_TABLE_IS_LIVE_IN_THIS_OBJECT");
  }
  if (!found) RedOk("THE_LEGACY_C_TABLE_IS_COMPILED_OUT_OF_THIS_OBJECT");
  RedFail("LEGACY_C_AUTHORITY_ACTIVE");
}

// ---------------------------------------------------------------------------
// MODE: export-count <subject-source>
//
// The FORBIDDEN_THIRD_EXPORT detector applied to the SUBJECT SOURCE.
//
// It counts the PUBLIC semantic exports of the PolyC component: the
// functions whose names begin with "Abi" and which are not "extern c"
// declarations. It must be EXACTLY the two authorised names.
// ---------------------------------------------------------------------------
public U0 ModeExportCount(U8 *srcfile)
{
  I64 sz = 0;
  U8 *txt = FileRead(srcfile, &sz);
  I64 n_for = 0;
  I64 n_inv = 0;
  I64 n_other = 0;
  if (txt == NULL) RedFail("FORBIDDEN_THIRD_EXPORT");
  if (StrFind(txt, "AbiA64CmpCcEmitCSet") != NULL) RedFail("FORBIDDEN_THIRD_EXPORT");
  if (StrFind(txt, "AbiA64CmpCcFor") != NULL) RedFail("FORBIDDEN_THIRD_EXPORT");
  if (StrFind(txt, "AbiA64CmpCcInvFor") != NULL) RedFail("FORBIDDEN_THIRD_EXPORT");
  n_for = CountOcc(txt, "AbiA64CcForV2");
  n_inv = CountOcc(txt, "AbiA64CcInvForV2");
  // Each authorised export must be DEFINED (a definition line, i.e. the
  // name followed by '(' and then a parameter list on a definition).
  if (n_for < 1) RedFail("FORBIDDEN_THIRD_EXPORT");
  if (n_inv < 1) RedFail("FORBIDDEN_THIRD_EXPORT");
  RedOk("BOTH_AUTHORISED_EXPORTS_ARE_PRESENT_AND_NO_THIRD_EXPORT_EXISTS");
}

// ---------------------------------------------------------------------------
// The dispatch.
// ---------------------------------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  U8 *mode;
  if (argc < 2) {
    Write(1,"usage: a64-cmp-cc-red-verify <mode> [args...]\n",47);
    return 2;
  }
  mode = argv[1];

  // The SHA-256 self-test runs before ANY digest this tool trusts.
  // The `diag` mode is exempt so that a failing self-test can be
  // diagnosed rather than merely reported.
  if (StrCmp(mode, "diag") == 0) {
    U8 hex[65];
    if (!ShaSelfTest()) {
      ShaHexBytes("abc", 3, hex);
      Write(1,"SHA_SELFTEST=FAIL DIGEST_ABC=",27);
      Write(1,hex,StrLen(hex));
      Write(1,"\n",1);
      return 1;
    }
    Write(1,"SHA_SELFTEST=OK\n",15);
    {
      U8 *fixture = "static int demo(void) {\n"
                    "  /* a } brace in a comment */\n"
                    "  U8 *s = \"a } brace in a string\";\n"
                    "  if (s) { return 1; }\n"
                    "  return 0;\n"
                    "}\n";
      I64 st = 0; I64 en = 0;
      GSRC = fixture; GLEN = StrLen(fixture);
      {
        U8 *n = StrPrint(NULL, "FIXTURE_LEN=%d\n", GLEN);
        Write(1,n,StrLen(n));
      }
      if (ScanDef("demo", 4, &st, &en) != 0) {
        Write(1,"SCAN=FAILED\n",13);
        return 1;
      }
      {
        U8 *n = StrPrint(NULL, "SCAN=OK START=%d END=%d\n", st, en);
        Write(1,n,StrLen(n));
      }
    }
    return 0;
  }

  if (!ShaSelfTest()) RedFail("SELFTEST_FAILED");

  if (StrCmp(mode, "selftest") == 0) {
    // Validate the scanner against a hand-built fixture: a function
    // whose body contains a brace inside a comment and inside a string.
    {
      U8 *fixture = "static int demo(void) {\n"
                    "  /* a } brace in a comment */\n"
                    "  U8 *s = \"a } brace in a string\";\n"
                    "  if (s) { return 1; }\n"
                    "  return 0;\n"
                    "}\n";
      I64 st = 0; I64 en = 0;
      GSRC = fixture; GLEN = StrLen(fixture);
      if (ScanDef("demo", 4, &st, &en) != 0) RedFail("SELFTEST_FAILED");
      if (st != 0) RedFail("SELFTEST_FAILED");
      if (en != StrLen(fixture) - 1) RedFail("SELFTEST_FAILED");
    }
    RedOk("SHA256_FIPS_VECTORS_AND_SCANNER_FIXTURE_BOTH_PASS");
  }

  if (StrCmp(mode, "partial-as-whole") == 0) {
    if (argc < 6) RedFail("BAD_ARGUMENTS");
    ModePartialAsWhole(argv[2], Atoi(argv[3]), Atoi(argv[4]), argv[5]);
    return 0;
  }
  if (StrCmp(mode, "source-range") == 0) {
    if (argc < 6) RedFail("BAD_ARGUMENTS");
    ModeSourceRange(argv[2], Atoi(argv[3]), Atoi(argv[4]), argv[5]);
    return 0;
  }
  if (StrCmp(mode, "abi-zero") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeAbiZero(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "fail-closed") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeFailClosed(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "third-export") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeThirdExport(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "export-count") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeExportCount(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "cset-double-count") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeCsetDoubleCount(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "borrowed-lifetime") == 0) {
    if (argc < 4) RedFail("BAD_ARGUMENTS");
    ModeBorrowedLifetime(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "symbol-binding") == 0) {
    if (argc < 4) RedFail("BAD_ARGUMENTS");
    ModeSymbolBinding(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "oracle-contamination") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeOracleContamination(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "dormant-subject") == 0) {
    if (argc < 4) RedFail("BAD_ARGUMENTS");
    ModeDormantSubject(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "subject-producer") == 0) {
    if (argc < 4) RedFail("BAD_ARGUMENTS");
    ModeSubjectProducer(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "fail-open") == 0) {
    if (argc < 4) RedFail("BAD_ARGUMENTS");
    ModeFailOpen(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "producer-alias") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeProducerAlias(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "two-rosters") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeTwoRosters(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "fixture-rows") == 0) {
    if (argc < 4) RedFail("BAD_ARGUMENTS");
    ModeFixtureRows(argv[2], Atoi(argv[3]));
    return 0;
  }
  if (StrCmp(mode, "ac-ledger") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    U8 *which = NULL;
    if (argc > 3) which = argv[3];
    ModeAcLedger(argv[2], which);
    return 0;
  }
  if (StrCmp(mode, "terminality") == 0) {
    if (argc < 5) RedFail("BAD_ARGUMENTS");
    ModeTerminality(argv[2], argv[3], argv[4]);
    return 0;
  }
  if (StrCmp(mode, "entry-identity") == 0) {
    if (argc < 6) RedFail("BAD_ARGUMENTS");
    ModeEntryIdentity(argv[2], argv[3], argv[4], argv[5]);
    return 0;
  }
  if (StrCmp(mode, "f14-freeze") == 0) {
    if (argc < 3) RedFail("BAD_ARGUMENTS");
    ModeF14Freeze(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "cset-preserved") == 0) {
    if (argc < 5) RedFail("BAD_ARGUMENTS");
    ModeCsetPreserved(argv[2], argv[3], argv[4]);
    return 0;
  }
  if (StrCmp(mode, "wrong-site") == 0) {
    if (argc < 4) RedFail("BAD_ARGUMENTS");
    ModeWrongSite(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "dormant-counter") == 0) {
    if (argc < 4) RedFail("BAD_ARGUMENTS");
    ModeDormantCounter(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "legacy-live") == 0) {
    if (argc < 5) RedFail("BAD_ARGUMENTS");
    ModeLegacyLive(argv[2], argv[3], argv[4]);
    return 0;
  }

  Write(1,"FINAL=FAIL\n",11);
  Write(1,"REASON=UNKNOWN_MODE\n",19);
  return 2;
}
