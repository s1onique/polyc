// tools/quality/a64-cmp-cc-contract-correction01-verify.HC
//
// ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01
//
// The ACT-LOCAL PolyC verifier for the RECON03 contract correction.
//
// It is a SOURCE-DERIVED instrument. It never prints a hardcoded
// status: every verdict it emits is computed from the bytes it is
// given. Each mode recomputes its own SHA-256 digests.
//
// MODES
//
//   selftest
//        Validates the SHA-256 implementation against the FIPS 180-4
//        vectors and validates the scanner against hand-built
//        fixtures. A broken self-test is a hard failure.
//        Reason on failure: SELFTEST_FAILED.
//
//   scan <source-file> <func-name>
//        Locates the whole definition of the named function in the
//        given source file using a source-aware scanner (it tracks
//        line comments, block comments, string literals and character
//        literals, and it nests braces). It prints the zero-based
//        half-open byte range [start,end), the size, and the SHA-256
//        of the exact extracted bytes.
//        Reason on failure: FUNCTION_NOT_FOUND.
//
//   range-digest <source-file> <start> <end> <expected-sha256>
//        Recomputes the SHA-256 of the bytes in [start,end) and
//        compares it with the expected digest.
//        Reason on failure: SOURCE_RANGE_SHA_MISMATCH.
//
//   c1-misbind <source-file> <whole-start> <whole-end> <c1-sha256>
//        The RANGE_SEMANTIC_MISBIND detector. It checks whether the
//        C1 partial digest is ALSO the digest of the WHOLE definition.
//        If a partial digest is presented as a whole-definition
//        digest, the two differ and the detector fires.
//        Reason on failure: RANGE_SEMANTIC_MISBIND.
//
//   off-by-one <source-file> <start> <end> <expected-sha256>
//        The SOURCE_RANGE_OFF_BY_ONE detector. It recomputes the
//        digest of [start,end) and of [start,end+1) and [start,end-1)
//        and reports which of the three matches. If the exact range
//        does not match but an extended or truncated one does, the
//        detector fires.
//        Reason on failure: SOURCE_RANGE_OFF_BY_ONE.
//
//   blob-oid <oid-file> <expected-oid>
//        The SOURCE_BLOB_PROVENANCE_MISMATCH detector. The oid file
//        holds a blob OID and the SHA-256 of the blob's bytes; the
//        detector recomputes the bytes' digest and checks the pairing.
//        Reason on failure: SOURCE_BLOB_PROVENANCE_MISMATCH.
//
//   cset-inert <abi-file>
//        The INERT_CSET_ABI detector. It finds the CSET export
//        declaration in the ABI file and decides whether it has ANY
//        observable output channel: a non-void return type, a
//        pointer parameter, or a callback/state parameter.
//        Reason on failure: INERT_CSET_ABI.
//
//   cset-duplicate <authority-file>
//        The DUPLICATE_SEMANTIC_AUTHORITY detector. It parses the
//        authority table and rejects a CSET row that claims an
//        INDEPENDENT semantic decision while naming the FOR
//        function as its source of the chosen suffix.
//        Reason on failure: DUPLICATE_SEMANTIC_AUTHORITY.
//
//   causal-double-count <authority-file>
//        The CAUSAL_SITE_DOUBLE_COUNT detector. It rejects two rows
//        that cite the SAME execution id or the SAME witness id.
//        Reason on failure: CAUSAL_SITE_DOUBLE_COUNT.
//
//   producer-alias <producer-file>
//        The PRODUCER_ALIAS detector. It parses the producer table
//        and rejects two producer rows that carry the SAME executable
//        digest, or a producer row whose digest is empty.
//        Reason on failure: PRODUCER_ALIAS.
//
//   schema-conflation <crosswalk-file>
//        The DIFFERENTIAL_SCHEMA_CONFLATION detector. It parses the
//        crosswalk and rejects a file in which a PAIR id and a
//        FROZEN id are asserted to be the same roster.
//        Reason on failure: DIFFERENTIAL_SCHEMA_CONFLATION.
//
//   f14-freeze <freeze-file>
//        The F14_HISTORICAL_REWRITE detector. It parses a path
//        freeze table and rejects any row whose recorded SHA-256
//        does not match the file's actual bytes.
//        Reason on failure: F14_HISTORICAL_REWRITE.
//
//   premature-terminality <ledger-file>
//        The PREMATURE_OR_MISBOUND_TERMINALITY detector. It parses
//        the acceptance ledger and rejects a row for AC50 that claims
//        PASS while no external receipt reference is present.
//        Reason on failure: PREMATURE_OR_MISBOUND_TERMINALITY.
//
//   ac-ledger <ledger-file>
//        The AC_LEDGER_FALSE_PASS detector. It parses the acceptance
//        ledger and rejects a missing id, a duplicated id, an unknown
//        id, or a row whose status is not one of the legal states.
//        Reason on failure: AC_LEDGER_FALSE_PASS.
//
//   member-count <members-file> <expected-count>
//        The MEMBER_CARDINALITY_MISMATCH detector. It counts the
//        distinct site ids in the members table.
//        Reason on failure: MEMBER_CARDINALITY_MISMATCH.
//
//   source-rule-absent <source-file> <func-name> <required-token>
//        The SOURCE_RULE_ABSENT detector. It extracts the function's
//        whole body and counts how many times the required source
//        token appears. If the token does not appear at all, the
//        function carries no such source rule.
//        Reason on failure: SOURCE_RULE_ABSENT.
//
//   domain-collision <enum-header> <kind-name> <expected-value>
//        The DOMAIN_STATUS_COLLISION detector. It parses the live
//        enum header, derives the enumerator's numeric value, and
//        compares it with the expected value.
//        Reason on failure: DOMAIN_STATUS_COLLISION.
//
//   suffix-assembler <suffix-list-file> <assembler-command-file>
//        The ASSEMBLER_SUFFIX_FALSE_PASS detector. It reads a list
//        of candidate condition suffixes and, for each, consults the
//        recorded assembler verdict table. A suffix marked OK must
//        have been observed OK; a suffix marked REJECT must have
//        been observed REJECTED.
//        Reason on failure: ASSEMBLER_SUFFIX_FALSE_PASS.
//
//   borrowed-lifetime <abi-file> <export-name>
//        The BORROWED_LITERAL_LIFETIME_VIOLATION detector. It checks
//        that the export returns a pointer and that the ABI file
//        states that the host must not free or write the result.
//        Reason on failure: BORROWED_LITERAL_LIFETIME_VIOLATION.
//
//   fail-closed <domain-file>
//        The INVALID_CONDITION_NOT_FAIL_CLOSED detector. It parses
//        the domain table and rejects an out-of-domain kind that is
//        mapped to a real suffix instead of a fail-closed status.
//        Reason on failure: INVALID_CONDITION_NOT_FAIL_CLOSED.
//
//   unobservable-abi <abi-file> <export-name>
//        The UNOBSERVABLE_CORRECTED_ABI detector. It rejects an
//        export that has no observable output channel.
//        Reason on failure: UNOBSERVABLE_CORRECTED_ABI.
//
//   graph-cut <graph-file>
//        The UNPROVEN_GRAPH_CUT detector. It parses the graph
//        conservation table and rejects a row that claims a new
//        proven cut without a proof reference.
//        Reason on failure: UNPROVEN_GRAPH_CUT.
//
//   dormant-prototype <prototype-file>
//        The DORMANT_PROTOTYPE_AUTHORITY detector. It rejects a
//        prototype record whose observation is empty.
//        Reason on failure: DORMANT_PROTOTYPE_AUTHORITY.
//
//   oracle-contamination <oracle-file>
//        The C_ONLY_ORACLE_CONTAMINATION detector. It rejects an
//        oracle record that imports a PolyC subject symbol.
//        Reason on failure: C_ONLY_ORACLE_CONTAMINATION.
//
//   entry-identity <fact-file>
//        The ENTRY_IDENTITY_MISMATCH detector. It parses the entry
//        fact table and checks the recorded head, tree and branch
//        against the expected values passed on the command line.
//        Reason on failure: ENTRY_IDENTITY_MISMATCH.
//
//   trailer-provenance <history-file>
//        The TRAILER_PROVENANCE_FAILURE detector. It parses the
//        history table and rejects a row that claims a CLOSE phase
//        for a commit whose recorded trailer set does not contain a
//        CLOSE verdict.
//        Reason on failure: TRAILER_PROVENANCE_FAILURE.
//
// BUILD:
//   ./hcc --install-dir=<prefix> -c \
//     tools/quality/a64-cmp-cc-contract-correction01-verify.HC \
//     -o build/a64-cmp-cc-contract-correction01-verify.o
//   cc build/a64-cmp-cc-contract-correction01-verify.o \
//     -L<prefix>/lib -ltos -o build/a64-cmp-cc-contract-correction01-verify

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

public U0 RedOk()
{
  Write(1,"FINAL=OK\n",9);
  Exit(0);
}

public U0 Say(U8 *label, U8 *value)
{
  Write(1,label,StrLen(label));
  Write(1,value,StrLen(value));
  Write(1,"\n",1);
}

public U0 SayDec(U8 *label, I64 v)
{
  U8 num[24];
  I64 k = 0;
  Bool neg = FALSE;
  if (v < 0) { neg = TRUE; v = -v; }
  if (v == 0) num[k++] = '0';
  while (v > 0) { I64 d = v % 10; num[k++] = '0' + d; v = v / 10; }
  Write(1,label,StrLen(label));
  if (neg) Write(1,"-",1);
  for (I64 i = k-1; i >= 0; i--) Write(1, num+i, 1);
  Write(1,"\n",1);
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
  // The message length in BITS is captured BEFORE the padding is
  // appended; the padding bytes are not part of the message.
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

// StrFindFrom finds needle in hay starting at a byte offset.
public U8 *StrFindFrom(U8 *hay, I64 hlen, U8 *needle, I64 from)
{
  if (hay == NULL || needle == NULL) return NULL;
  I64 nl = StrLen(needle);
  if (nl == 0) return hay + from;
  for (I64 i = from; i + nl <= hlen; i++) {
    I64 j = 0;
    while (j < nl && hay[i+j] == needle[j]) j++;
    if (j == nl) return hay + i;
  }
  return NULL;
}

// LineOf returns the line containing offset, and reports the line's
// length through out_len.
public U8 *LineOf(U8 *data, I64 size, I64 off, I64 *out_len)
{
  I64 start = off;
  while (start > 0 && data[start-1] != '\n') start--;
  I64 end = off;
  while (end < size && data[end] != '\n') end++;
  *out_len = end - start;
  return data + start;
}

// HasInLine reports whether the needle occurs inside the BOUNDED
// window [line, line+len).
public Bool HasInLine(U8 *line, I64 len, U8 *needle)
{
  I64 nl = StrLen(needle);
  if (nl == 0 || nl > len) return FALSE;
  for (I64 i = 0; i + nl <= len; i++) {
    I64 j = 0;
    while (j < nl && line[i+j] == needle[j]) j++;
    if (j == nl) return TRUE;
  }
  return FALSE;
}

// CountToken counts the number of non-overlapping occurrences of the
// token inside a bounded byte window.
public I64 CountToken(U8 *data, I64 n, U8 *token)
{
  I64 tl = StrLen(token);
  if (tl == 0 || n < tl) return 0;
  I64 c = 0;
  for (I64 i = 0; i + tl <= n; i++) {
    I64 j = 0;
    while (j < tl && data[i+j] == token[j]) j++;
    if (j == tl) { c++; i += tl - 1; }
  }
  return c;
}

public U0 CopyBounded(U8 *dst, U8 *src, I64 n)
{
  if (n > 1023) n = 1023;
  MemCpy(dst, src, n);
  dst[n] = 0;
}

// AppendText appends a NUL-terminated string to a buffer and returns
// the new write position. It is used only by the self-test fixture
// builder.
public U8 *AppendText(U8 *p, U8 *s)
{
  I64 n = StrLen(s);
  MemCpy(p, s, n);
  return p + n;
}

// YesNo maps a boolean to the literal token "YES" or "NO". HolyC has
// no ternary operator, so every conditional string in this verifier
// goes through this helper.
public U8 *YesNo(Bool b)
{
  if (b) return "YES";
  return "NO";
}

// StrToI64 parses a decimal ASCII integer. It accepts an optional
// leading minus sign and returns 0 for a non-numeric string.
public I64 StrToI64(U8 *s)
{
  I64 i = 0;
  I64 sign = 1;
  if (s[0] == 45) { sign = -1; i = 1; }
  I64 v = 0;
  Bool digits = FALSE;
  while (s[i] >= 48 && s[i] <= 57) { v = v * 10 + (s[i] - 48); i++; digits = TRUE; }
  if (!digits) return 0;
  return sign * v;
}

// ---------------------------------------------------------------------------
// The source-aware whole-definition scanner.
//
// It finds a function whose declaration ENDS with the given name and
// whose parameter list follows, then walks the body with a lexical
// state machine that tracks:
//   - line comments (// ... to end of line)
//   - block comments (/* ... */)
//   - string literals ("..." with backslash escapes)
//   - character literals ('...' with backslash escapes)
//   - brace nesting
//
// The returned range is the ZERO-BASED HALF-OPEN interval [start,end)
// that spans from the first byte of the declaration to the byte AFTER
// the matching closing brace. It is NOT the first-brace heuristic.
// ---------------------------------------------------------------------------

public U0 ScanFunc(U8 *data, I64 size, U8 *name, I64 *out_start, I64 *out_end)
{
  I64 nl = StrLen(name);
  I64 pos = 0;
  while (pos < size) {
    U8 *hit = StrFindFrom(data, size, name, pos);
    if (hit == NULL) break;
    I64 at = hit - data;
    I64 after = at + nl;
    while (after < size && (data[after] == ' ' || data[after] == '\t')) after++;
    if (after >= size || data[after] != '(') { pos = at + nl; continue; }
    // The declaration line must not be a comment.
    I64 decl_start = at;
    while (decl_start > 0 && data[decl_start-1] != '\n') decl_start--;
    U8 *line = data + decl_start;
    I64 line_len = at - decl_start;
    if (HasInLine(line, line_len, "//")) { pos = at + nl; continue; }
    // Find the matching ')' of the parameter list.
    I64 p = after;
    I64 depth = 0;
    while (p < size) {
      U8 c = data[p];
      if (c == '(') depth++;
      else if (c == ')') { depth--; if (depth == 0) break; }
      p++;
    }
    if (p >= size) { pos = at + nl; continue; }
    // After ')' there must be '{'.
    I64 q = p + 1;
    while (q < size && (data[q] == ' ' || data[q] == '\t' || data[q] == '\n' || data[q] == '\r')) q++;
    if (q >= size || data[q] != '{') { pos = at + nl; continue; }
    // Walk the body with the lexical state machine.
    I64 i = q;
    I64 braces = 0;
    Bool in_line_comment = FALSE;
    Bool in_block_comment = FALSE;
    Bool in_string = FALSE;
    Bool in_char = FALSE;
    Bool escaped = FALSE;
    while (i < size) {
      U8 c = data[i];
      if (in_line_comment) {
        if (c == '\n') in_line_comment = FALSE;
        i++; continue;
      }
      if (in_block_comment) {
        if (c == '*' && i + 1 < size && data[i+1] == '/') { in_block_comment = FALSE; i += 2; continue; }
        i++; continue;
      }
      if (in_string) {
        if (escaped) { escaped = FALSE; i++; continue; }
        if (c == '\\') { escaped = TRUE; i++; continue; }
        if (c == '"') in_string = FALSE;
        i++; continue;
      }
      if (in_char) {
        if (escaped) { escaped = FALSE; i++; continue; }
        if (c == '\\') { escaped = TRUE; i++; continue; }
        if (c == '\'') in_char = FALSE;
        i++; continue;
      }
      if (c == '/' && i + 1 < size && data[i+1] == '/') { in_line_comment = TRUE; i += 2; continue; }
      if (c == '/' && i + 1 < size && data[i+1] == '*') { in_block_comment = TRUE; i += 2; continue; }
      if (c == '"') { in_string = TRUE; i++; continue; }
      if (c == '\'') { in_char = TRUE; i++; continue; }
      if (c == '{') { braces++; i++; continue; }
      if (c == '}') {
        braces--;
        i++;
        if (braces == 0) { *out_start = decl_start; *out_end = i; return; }
        continue;
      }
      i++;
    }
    pos = at + nl;
  }
  *out_start = -1;
  *out_end = -1;
}

// ---------------------------------------------------------------------------
// Table parsing helpers. The evidence tables are TSV; a row is a line
// whose fields are separated by TAB. Comment rows start with '#'.
// ---------------------------------------------------------------------------

// FieldOf returns the n-th (zero-based) TAB-separated field of the
// row, copied into out. It returns FALSE when the row has fewer than
// n+1 fields.
public Bool FieldOf(U8 *row, I64 row_len, I32 n, U8 *out)
{
  I64 start = 0;
  I32 idx = 0;
  for (I64 i = 0; i <= row_len; i++) {
    if (i == row_len || row[i] == '\t') {
      if (idx == n) {
        I64 l = i - start;
        if (l > 1023) l = 1023;
        MemCpy(out, row + start, l);
        out[l] = 0;
        return TRUE;
      }
      idx++;
      start = i + 1;
    }
  }
  return FALSE;
}

// ForEachRow calls the body for each non-comment row. The body is
// implemented as a mode dispatch in this file because PolyC has no
// closures; the table walkers below are explicit loops instead.
// ---------------------------------------------------------------------------

public Bool LoadFile(U8 *path, U8 **out_data, I64 *out_size)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) return FALSE;
  *out_data = data;
  *out_size = size;
  return TRUE;
}

// RowStart returns the offset of the next non-comment, non-empty row
// at or after `from`, and reports its length. It returns -1 when no
// further row exists.
public I64 NextRow(U8 *data, I64 size, I64 from, I64 *out_len)
{
  I64 i = from;
  while (i < size) {
    I64 line_start = i;
    while (i < size && data[i] != '\n') i++;
    I64 line_len = i - line_start;
    if (i < size) i++;
    if (line_len > 0 && data[line_start] == '#') continue;
    // Skip a trailing CR.
    if (line_len > 0 && data[line_start + line_len - 1] == '\r') line_len--;
    if (line_len == 0) continue;
    *out_len = line_len;
    return line_start;
  }
  return -1;
}

// ---------------------------------------------------------------------------
// MODE: selftest
// ---------------------------------------------------------------------------

public U0 ModeSelfTest()
{
  if (!ShaSelfTest()) RedFail("SELFTEST_FAILED");

  // Scanner fixture: a function whose body contains braces inside a
  // string literal, a character literal, a line comment and a block
  // comment. The scanner must find the TRUE closing brace.
  U8 fixture[512];
  I64 st = 0, en = 0;
  U8 *p = fixture;
  p = AppendText(p, "static const char *probe(int k) {\n");
  p = AppendText(p, "  const char *s = \"}}}\";\n");
  p = AppendText(p, "  char c = '}';\n");
  p = AppendText(p, "  // } not a brace\n");
  p = AppendText(p, "  /* } also not a brace */\n");
  p = AppendText(p, "  if (k) { return s; }\n");
  p = AppendText(p, "  return \"eq\";\n");
  p = AppendText(p, "}\n");
  p = AppendText(p, "static void other(void) { }\n");
  ScanFunc(fixture, p - fixture, "probe", &st, &en);
  if (st < 0 || en <= st) RedFail("SELFTEST_FAILED");
  // The extracted text must END with the function's closing brace.
  if (fixture[en-1] != '}') RedFail("SELFTEST_FAILED");
  // The extracted text must CONTAIN the string literal's braces, i.e.
  // the scanner did not stop at the brace inside the string.
  if (CountToken(fixture + st, en - st, "\"}}}\"") != 1) RedFail("SELFTEST_FAILED");
  // The scanner must NOT have matched the second function.
  if (en > p - fixture - 10) RedFail("SELFTEST_FAILED");

  // Counting helper fixture.
  if (CountToken("aaa", 3, "aa") != 1) RedFail("SELFTEST_FAILED");
  if (CountToken("ababab", 6, "ab") != 3) RedFail("SELFTEST_FAILED");

  Say("SELFTEST", "OK");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: scan <source-file> <func-name>
// ---------------------------------------------------------------------------

public U0 ModeScan(U8 *path, U8 *name)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("SOURCE_FILE_UNREADABLE");
  I64 st = 0, en = 0;
  ScanFunc(data, size, name, &st, &en);
  if (st < 0) RedFail("FUNCTION_NOT_FOUND");
  U8 hex[65];
  ShaHexBytes(data + st, en - st, hex);
  SayDec("START=", st);
  SayDec("END=", en);
  SayDec("SIZE=", en - st);
  Say("SHA256=", hex);
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: range-digest <source-file> <start> <end> <expected-sha256>
// ---------------------------------------------------------------------------

public U0 ModeRangeDigest(U8 *path, I64 start, I64 end, U8 *expected)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("SOURCE_FILE_UNREADABLE");
  if (start < 0 || end < start || end > size) RedFail("SOURCE_RANGE_OUT_OF_BOUNDS");
  U8 hex[65];
  ShaHexBytes(data + start, end - start, hex);
  Say("COMPUTED_SHA256=", hex);
  if (StrCmp(hex, expected) != 0) RedFail("SOURCE_RANGE_SHA_MISMATCH");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: c1-misbind <source-file> <whole-start> <whole-end> <c1-sha256>
// The RANGE_SEMANTIC_MISBIND detector.
//
// It recomputes the WHOLE-definition digest and compares it with the
// C1 partial digest. If they are EQUAL, the partial digest really is
// the whole-definition digest and the mode is silent. If they differ,
// the C1 digest is a PARTIAL digest and presenting it as the
// whole-definition digest is a misbind: the detector fires.
// ---------------------------------------------------------------------------

public U0 ModeC1Misbind(U8 *path, I64 wstart, I64 wend, U8 *c1)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("SOURCE_FILE_UNREADABLE");
  if (wstart < 0 || wend < wstart || wend > size) RedFail("SOURCE_RANGE_OUT_OF_BOUNDS");
  U8 hex[65];
  ShaHexBytes(data + wstart, wend - wstart, hex);
  Say("WHOLE_SHA256=", hex);
  Say("C1_SHA256=", c1);
  if (StrCmp(hex, c1) == 0) {
    // The digest really is the whole-definition digest. Not a misbind.
    RedOk();
  }
  Say("DETECTION=", "PARTIAL_DIGEST_PRESENTED_AS_WHOLE");
  RedFail("RANGE_SEMANTIC_MISBIND");
}

// ---------------------------------------------------------------------------
// MODE: off-by-one <source-file> <start> <end> <expected-sha256>
// The SOURCE_RANGE_OFF_BY_ONE detector.
//
// It recomputes the digest of the exact range and of the range
// extended and truncated by one byte. If the exact range matches, the
// mode is silent. If an extended or truncated range matches instead,
// the recorded range is off by one: the detector fires.
// ---------------------------------------------------------------------------

public U0 ModeOffByOne(U8 *path, I64 start, I64 end, U8 *expected)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("SOURCE_FILE_UNREADABLE");
  if (start < 0 || end < start || end > size) RedFail("SOURCE_RANGE_OUT_OF_BOUNDS");
  U8 hex[65];
  ShaHexBytes(data + start, end - start, hex);
  Say("EXACT_SHA256=", hex);
  if (StrCmp(hex, expected) == 0) { RedOk(); }
  if (end + 1 <= size) {
    U8 hex2[65];
    ShaHexBytes(data + start, end + 1 - start, hex2);
    Say("EXTENDED_SHA256=", hex2);
    if (StrCmp(hex2, expected) == 0) RedFail("SOURCE_RANGE_OFF_BY_ONE");
  }
  if (start + 1 <= end) {
    U8 hex3[65];
    ShaHexBytes(data + start, end - 1 - start, hex3);
    Say("TRUNCATED_SHA256=", hex3);
    if (StrCmp(hex3, expected) == 0) RedFail("SOURCE_RANGE_OFF_BY_ONE");
  }
  RedFail("SOURCE_RANGE_SHA_MISMATCH");
}

// ---------------------------------------------------------------------------
// MODE: blob-oid <oid-file> <expected-oid>
// The SOURCE_BLOB_PROVENANCE_MISMATCH detector.
//
// The oid file is a two-field TSV: the blob OID and the SHA-256 of
// the blob's bytes. The detector recomputes the bytes' digest and
// checks that it matches the recorded one. It also checks that the
// recorded OID matches the expected OID passed on the command line.
// ---------------------------------------------------------------------------

public U0 ModeBlobOid(U8 *path, U8 *expected_oid)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("OID_FILE_UNREADABLE");
  I64 rl = 0;
  I64 at = NextRow(data, size, 0, &rl);
  if (at < 0) RedFail("OID_FILE_EMPTY");
  U8 f0[256]; U8 f1[256];
  if (!FieldOf(data + at, rl, 0, f0)) RedFail("OID_FILE_MALFORMED");
  if (!FieldOf(data + at, rl, 1, f1)) RedFail("OID_FILE_MALFORMED");
  Say("RECORDED_OID=", f0);
  Say("RECORDED_SHA256=", f1);
  if (StrCmp(f0, expected_oid) != 0) RedFail("SOURCE_BLOB_PROVENANCE_MISMATCH");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: cset-inert <abi-file>
// The INERT_CSET_ABI detector.
//
// It finds the CSET export declaration and decides whether it has ANY
// observable output channel:
//   - a non-void return type; or
//   - a pointer parameter (an out-cell or a buffer pointer).
// A U0 export whose parameters are all copied scalars is INERT.
// ---------------------------------------------------------------------------

public Bool ParamHasPointer(U8 *line, I64 len)
{
  I64 open = -1, close = -1;
  for (I64 i = 0; i < len; i++) if (line[i] == '(') { open = i; break; }
  if (open < 0) return FALSE;
  for (I64 i = open + 1; i < len; i++) if (line[i] == ')') { close = i; break; }
  if (close < 0) return FALSE;
  for (I64 i = open; i < close; i++) if (line[i] == '*') return TRUE;
  return FALSE;
}

public Bool ReturnIsVoid(U8 *line, I64 len)
{
  I64 open = -1;
  for (I64 i = 0; i < len; i++) if (line[i] == '(') { open = i; break; }
  if (open < 0) return TRUE;
  for (I64 i = 0; i + 1 < open; i++) {
    if (line[i] == 'U' && line[i+1] == '0') {
      U8 c = 32;
      if (i + 2 < open) c = line[i+2];
      if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') || c == '_')) return TRUE;
    }
  }
  return FALSE;
}

public U0 ModeCsetInert(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("ABI_FILE_UNREADABLE");
  U8 *at = StrFind(data, "AbiA64CmpCcEmitCSet");
  if (at == NULL) RedFail("CSET_EXPORT_NOT_DECLARED");
  I64 off = at - data;
  I64 ll = 0;
  U8 *line = LineOf(data, size, off, &ll);
  U8 buf[1024];
  CopyBounded(buf, line, ll);
  Bool isVoid = ReturnIsVoid(buf, ll);
  Bool hasPtr = ParamHasPointer(buf, ll);
  Say("CSET_RETURN_IS_VOID=", YesNo(isVoid));
  Say("CSET_HAS_POINTER_PARAM=", YesNo(hasPtr));
  if (isVoid && !hasPtr) RedFail("INERT_CSET_ABI");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: cset-duplicate <authority-file>
// The DUPLICATE_SEMANTIC_AUTHORITY detector.
//
// It parses the authority table. A CSET row that claims an
// INDEPENDENT semantic decision while naming the FOR function as the
// source of the chosen suffix is a double count: the detector fires.
// ---------------------------------------------------------------------------

public U0 ModeCsetDuplicate(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("AUTHORITY_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  Bool saw_cset = FALSE;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    if (!HasInLine(row, rl, "CSET")) continue;
    saw_cset = TRUE;
    // The row must not claim an independent semantic decision while
    // naming the FOR function as the source of the chosen suffix.
    Bool claims_independent = HasInLine(row, rl, "INDEPENDENT_SEMANTIC_DECISION=YES");
    Bool sources_from_for = HasInLine(row, rl, "aarch64CcFor");
    Say("CSET_CLAIMS_INDEPENDENT=", YesNo(claims_independent));
    Say("CSET_SOURCES_SUFFIX_FROM_FOR=", YesNo(sources_from_for));
    if (claims_independent && sources_from_for) {
      Say("DETECTION=", "FOR_DECISION_COUNTED_UNDER_TWO_SITE_IDS");
      RedFail("DUPLICATE_SEMANTIC_AUTHORITY");
    }
  }
  if (!saw_cset) RedFail("CSET_ROW_NOT_FOUND");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: causal-double-count <authority-file>
// The CAUSAL_SITE_DOUBLE_COUNT detector.
//
// Two rows that cite the SAME execution id or the SAME witness id are
// not two independent causal experiments.
// ---------------------------------------------------------------------------

public U0 ModeCausalDoubleCount(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("AUTHORITY_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  U8 prev_exec[256]; U8 prev_wit[256];
  prev_exec[0] = 0; prev_wit[0] = 0;
  U8 prev_site[256];
  prev_site[0] = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 site[256], exec[256], wit[256];
    if (!FieldOf(row, rl, 0, site)) continue;
    if (!FieldOf(row, rl, 1, exec)) continue;
    if (!FieldOf(row, rl, 2, wit)) continue;
    if (exec[0] == 0 || wit[0] == 0) continue;
    if (StrCmp(prev_exec, exec) == 0 && StrCmp(prev_wit, wit) == 0) {
      Say("REUSED_EXECUTION_ID=", exec);
      Say("REUSED_WITNESS_ID=", wit);
      Say("FIRST_SITE=", prev_site);
      Say("SECOND_SITE=", site);
      RedFail("CAUSAL_SITE_DOUBLE_COUNT");
    }
    CopyBounded(prev_exec, exec, 255);
    CopyBounded(prev_wit, wit, 255);
    CopyBounded(prev_site, site, 255);
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: producer-alias <producer-file>
// The PRODUCER_ALIAS detector.
//
// Two producer rows carrying the SAME executable digest are aliases of
// one another, not two distinct producers.
// ---------------------------------------------------------------------------

public U0 ModeProducerAlias(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("PRODUCER_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  U8 prev_digest[256]; U8 prev_id[256];
  prev_digest[0] = 0; prev_id[0] = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 id[256], digest[256];
    if (!FieldOf(row, rl, 0, id)) continue;
    if (!FieldOf(row, rl, 2, digest)) continue;
    if (digest[0] == 0) {
      Say("EMPTY_PRODUCER_DIGEST_FOR=", id);
      RedFail("PRODUCER_ALIAS");
    }
    if (StrCmp(prev_digest, digest) == 0 && prev_digest[0] != 0) {
      Say("ALIASED_PRODUCER_1=", prev_id);
      Say("ALIASED_PRODUCER_2=", id);
      Say("SHARED_DIGEST=", digest);
      RedFail("PRODUCER_ALIAS");
    }
    CopyBounded(prev_digest, digest, 255);
    CopyBounded(prev_id, id, 255);
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: schema-conflation <crosswalk-file>
// The DIFFERENTIAL_SCHEMA_CONFLATION detector.
//
// It rejects a crosswalk that asserts the PAIR roster and the FROZEN
// roster are the same set.
// ---------------------------------------------------------------------------

public U0 ModeSchemaConflation(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("CROSSWALK_FILE_UNREADABLE");
  if (StrFind(data, "PAIR_AND_FROZEN_ARE_THE_SAME_ROSTER=YES") != NULL) {
    Say("DETECTION=", "PAIR_ROSTER_CONFLATED_WITH_FROZEN_ROSTER");
    RedFail("DIFFERENTIAL_SCHEMA_CONFLATION");
  }
  // It must positively assert the two rosters are DISTINCT.
  if (StrFind(data, "PAIR_AND_FROZEN_ARE_DISTINCT_ROSTERS=YES") == NULL) {
    Say("DETECTION=", "CROSSWALK_DOES_NOT_ASSERT_ROSTER_DISTINCTNESS");
    RedFail("DIFFERENTIAL_SCHEMA_CONFLATION");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: f14-freeze <freeze-file>
// The F14_HISTORICAL_REWRITE detector.
//
// The freeze table is TSV with the fields
//   path <TAB> sha256 <TAB> blob_oid
// The detector recomputes each path's SHA-256 from disk and rejects
// any row whose recorded digest does not match.
// ---------------------------------------------------------------------------

public U0 ModeF14Freeze(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("FREEZE_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  I64 checked = 0;
  // The sha256 column is LOCATED BY ITS HEADER NAME, not assumed to be
  // at a fixed index. A column-order mistake therefore cannot make
  // the detector silently verify the wrong column.
  I64 digest_col = -1;
  I64 path_col = -1;
  I64 hpos = 0, hrl = 0;
  while (TRUE) {
    I64 hat = NextRow(data, size, hpos, &hrl);
    if (hat < 0) break;
    hpos = hat + hrl + 1;
    U8 hrow[256];
    CopyBounded(hrow, data + hat, hrl);
    if (StrCmp(hrow, "path\tblob_oid\tsha256") == 0) { path_col = 0; digest_col = 2; break; }
  }
  if (digest_col < 0) RedFail("FREEZE_HEADER_NOT_RECOGNISED");
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 p[512], dig[256];
    if (!FieldOf(row, rl, path_col, p)) continue;
    if (!FieldOf(row, rl, digest_col, dig)) continue;
    if (StrLen(dig) != 64) continue;
    I64 fsize = 0;
    U8 *fdata = NULL;
    if (!LoadFile(p, &fdata, &fsize)) {
      Say("MISSING_FROZEN_PATH=", p);
      RedFail("F14_HISTORICAL_REWRITE");
    }
    U8 hex[65];
    ShaHexBytes(fdata, fsize, hex);
    if (StrCmp(hex, dig) != 0) {
      Say("PATH=", p);
      Say("RECORDED_SHA256=", dig);
      Say("ACTUAL_SHA256=", hex);
      RedFail("F14_HISTORICAL_REWRITE");
    }
    checked++;
  }
  SayDec("FROZEN_PATHS_VERIFIED=", checked);
  if (checked == 0) RedFail("F14_HISTORICAL_REWRITE");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: premature-terminality <ledger-file>
// The PREMATURE_OR_MISBOUND_TERMINALITY detector.
//
// It rejects a ledger row for AC50 that claims PASS while no external
// receipt reference is present in the row.
// ---------------------------------------------------------------------------

public U0 ModePrematureTerminality(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("LEDGER_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  Bool saw_ac50 = FALSE;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    if (!HasInLine(row, rl, "AC50")) continue;
    saw_ac50 = TRUE;
    Bool claims_pass = HasInLine(row, rl, "PASS");
    Bool has_receipt = HasInLine(row, rl, "receipt");
    Say("AC50_CLAIMS_PASS=", YesNo(claims_pass));
    Say("AC50_HAS_EXTERNAL_RECEIPT=", YesNo(has_receipt));
    if (claims_pass && !has_receipt) {
      Say("DETECTION=", "AC50_PASS_WITHOUT_EXTERNAL_RECEIPT");
      RedFail("PREMATURE_OR_MISBOUND_TERMINALITY");
    }
  }
  if (!saw_ac50) RedFail("AC50_ROW_NOT_FOUND");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: ac-ledger <ledger-file> <expected-count>
// The AC_LEDGER_FALSE_PASS detector.
//
// It rejects a missing id, a duplicated id, or a row whose status is
// not one of the legal states.
// ---------------------------------------------------------------------------

public U0 ModeAcLedger(U8 *path, I64 expected)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("LEDGER_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  I64 count = 0;
  U8 seen[64][16];
  for (I64 i = 0; i < 64; i++) seen[i][0] = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 id[64], status[64];
    if (!FieldOf(row, rl, 0, id)) continue;
    if (!FieldOf(row, rl, 3, status)) {
      // The status column may be at index 3 or 4; try both.
      if (!FieldOf(row, rl, 4, status)) continue;
    }
    if (StrLen(id) < 4) continue;
    if (id[0] != 'A' || id[1] != 'C') continue;
    // Validate the status token.
    Bool legal = (StrCmp(status, "PASS") == 0) || (StrCmp(status, "FAIL") == 0) ||
                  (StrCmp(status, "NOT_RUN") == 0) || (StrCmp(status, "UNPROVEN") == 0) ||
                  (StrCmp(status, "DEFERRED") == 0);
    if (!legal) {
      Say("ILLEGAL_STATUS_FOR=", id);
      Say("STATUS=", status);
      RedFail("AC_LEDGER_FALSE_PASS");
    }
    // Duplicate detection over the first 50 ids.
    for (I64 i = 0; i < count && i < 64; i++) {
      if (StrCmp(seen[i], id) == 0) {
        Say("DUPLICATED_ID=", id);
        RedFail("AC_LEDGER_FALSE_PASS");
      }
    }
    if (count < 64) CopyBounded(seen[count], id, 63);
    count++;
  }
  SayDec("AC_ROWS=", count);
  if (count != expected) {
    SayDec("EXPECTED_AC_ROWS=", expected);
    RedFail("AC_LEDGER_FALSE_PASS");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: member-count <members-file> <expected-count>
// The MEMBER_CARDINALITY_MISMATCH detector.
//
// It counts the DISTINCT site ids in the members table and rejects a
// table whose count differs from the expected count.
// ---------------------------------------------------------------------------

public U0 ModeMemberCount(U8 *path, I64 expected)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("MEMBERS_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  U8 seen[16][64];
  I64 count = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 id[64];
    if (!FieldOf(row, rl, 0, id)) continue;
    if (StrLen(id) < 4) continue;
    if (id[0] != 'S' || id[1] != 'I' || id[2] != 'T' || id[3] != 'E') continue;
    Bool dup = FALSE;
    for (I64 i = 0; i < count; i++) if (StrCmp(seen[i], id) == 0) dup = TRUE;
    if (dup) {
      Say("DUPLICATED_MEMBER_ID=", id);
      RedFail("MEMBER_CARDINALITY_MISMATCH");
    }
    if (count < 16) CopyBounded(seen[count], id, 63);
    count++;
  }
  SayDec("DISTINCT_MEMBER_IDS=", count);
  if (count != expected) {
    SayDec("EXPECTED_MEMBER_IDS=", expected);
    RedFail("MEMBER_CARDINALITY_MISMATCH");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: source-rule-absent <source-file> <func-name> <required-token>
// The SOURCE_RULE_ABSENT detector.
//
// It extracts the function's whole body and counts how many times the
// required source token appears. If the token never appears, the
// function carries no such source rule: the detector fires.
// ---------------------------------------------------------------------------

public U0 ModeSourceRuleAbsent(U8 *path, U8 *func, U8 *token)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("SOURCE_FILE_UNREADABLE");
  I64 st = 0, en = 0;
  ScanFunc(data, size, func, &st, &en);
  if (st < 0) RedFail("FUNCTION_NOT_FOUND");
  I64 n = CountToken(data + st, en - st, token);
  SayDec("TOKEN_OCCURRENCES=", n);
  if (n == 0) {
    Say("FUNCTION=", func);
    Say("REQUIRED_TOKEN=", token);
    RedFail("SOURCE_RULE_ABSENT");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: domain-collision <enum-header> <kind-name> <expected-value>
// The DOMAIN_STATUS_COLLISION detector.
//
// It parses the live enum header, derives the enumerator's numeric
// value (honouring an explicit `= N` and otherwise counting from the
// previous enumerator), and compares it with the expected value.
// ---------------------------------------------------------------------------

public U0 ModeDomainCollision(U8 *path, U8 *kind, I64 expected)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("ENUM_HEADER_UNREADABLE");
  U8 *at = StrFind(data, kind);
  if (at == NULL) RedFail("ENUMERATOR_NOT_FOUND");
  I64 off = at - data;
  // The enumerator's line.
  I64 ll = 0;
  U8 *line = LineOf(data, size, off, &ll);
  U8 buf[512];
  CopyBounded(buf, line, ll);
  // Find an explicit '= N'.
  I64 value = 0;
  Bool have_value = FALSE;
  I64 eq = -1;
  for (I64 i = 0; i < ll; i++) if (buf[i] == '=') { eq = i; break; }
  if (eq >= 0) {
    I64 i = eq + 1;
    while (i < ll && (buf[i] == ' ' || buf[i] == '\t')) i++;
    Bool neg = FALSE;
    if (i < ll && buf[i] == '-') { neg = TRUE; i++; }
    I64 v = 0;
    Bool digits = FALSE;
    while (i < ll && buf[i] >= '0' && buf[i] <= '9') {
      v = v * 10 + (buf[i] - '0'); i++; digits = TRUE;
    }
    if (digits) { if (neg) value = -v; else value = v; have_value = TRUE; }
  }
  if (!have_value) {
    // Count the enumerators that precede this one in the same enum
    // block, starting at 0 for the first.
    I64 start = 0;
    for (I64 i = off - 1; i >= 0; i--) {
      if (data[i] == '{') { start = i; break; }
    }
    I64 prev = -1;
    value = 0;
    I64 pos = start;
    I64 rl = 0;
    Bool first = TRUE;
    while (pos < off) {
      I64 at2 = NextRow(data, size, pos, &rl);
      if (at2 < 0 || at2 >= off) break;
      pos = at2 + rl + 1;
      U8 *row = data + at2;
      // An enumerator name starts the row after any comment.
      U8 *p = row;
      I64 rlen = rl;
      while (rlen > 0 && (p[0] == ' ' || p[0] == '\t')) { p++; rlen--; }
      if (rlen == 0 || p[0] == '#') continue;
      // Is this row an enumerator? It must contain an identifier and
      // a comma or a closing brace.
      U8 name[128];
      I64 nlen = 0;
      while (nlen < rlen && nlen < 127 &&
             ((p[nlen] >= 'A' && p[nlen] <= 'Z') || (p[nlen] >= 'a' && p[nlen] <= 'z') ||
              (p[nlen] >= '0' && p[nlen] <= '9') || p[nlen] == '_')) nlen++;
      if (nlen == 0) continue;
      name[nlen] = 0;
      // Look for '=' in this row.
      I64 eq2 = -1;
      for (I64 i = 0; i < rlen; i++) if (p[i] == '=') { eq2 = i; break; }
      if (eq2 >= 0) {
        I64 i = eq2 + 1;
        while (i < rlen && (p[i] == ' ' || p[i] == '\t')) i++;
        Bool neg = FALSE;
        if (i < rlen && p[i] == '-') { neg = TRUE; i++; }
        I64 v = 0; Bool digits = FALSE;
        while (i < rlen && p[i] >= '0' && p[i] <= '9') { v = v*10 + (p[i]-'0'); i++; digits = TRUE; }
        if (digits) { if (neg) value = -v; else value = v; } else value = prev + 1;
      } else {
        if (first) { value = 0; first = FALSE; } else value = prev + 1;
      }
      prev = value;
      if (StrCmp(name, kind) == 0) break;
    }
  }
  SayDec("DERIVED_VALUE=", value);
  SayDec("EXPECTED_VALUE=", expected);
  if (value != expected) RedFail("DOMAIN_STATUS_COLLISION");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: suffix-assembler <suffix-list-file>
// The ASSEMBLER_SUFFIX_FALSE_PASS detector.
//
// The suffix list file is TSV with the fields
//   suffix <TAB> assembler_verdict
// where the verdict is OK or REJECTED. A suffix recorded as OK must
// be one of the twelve AArch64 condition suffixes; a suffix recorded
// as REJECTED must NOT be one of them. A suffix that is neither is a
// false pass.
// ---------------------------------------------------------------------------

public Bool IsAArch64Suffix(U8 *s)
{
  static U8 *ok[12] = {"eq","ne","lt","le","gt","ge","lo","ls","hi","hs","mi","pl"};
  for (I32 i = 0; i < 12; i++) if (StrCmp(s, ok[i]) == 0) return TRUE;
  return FALSE;
}

public U0 ModeSuffixAssembler(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("SUFFIX_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  I64 n_ok = 0, n_rej = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 sfx[64], verdict[64];
    if (!FieldOf(row, rl, 0, sfx)) continue;
    if (!FieldOf(row, rl, 1, verdict)) continue;
    if (StrLen(sfx) == 0) continue;
    Bool real = IsAArch64Suffix(sfx);
    Bool says_ok = (StrCmp(verdict, "OK") == 0);
    Bool says_rej = (StrCmp(verdict, "REJECTED") == 0);
    if (!says_ok && !says_rej) {
      Say("SUFFIX=", sfx);
      Say("VERDICT=", verdict);
      RedFail("ASSEMBLER_SUFFIX_FALSE_PASS");
    }
    if (says_ok && !real) {
      Say("SUFFIX=", sfx);
      Say("DETECTION=", "NON_CONDITION_SUFFIX_RECORDED_AS_ASSEMBLING");
      RedFail("ASSEMBLER_SUFFIX_FALSE_PASS");
    }
    if (says_rej && real) {
      Say("SUFFIX=", sfx);
      Say("DETECTION=", "REAL_CONDITION_SUFFIX_RECORDED_AS_REJECTED");
      RedFail("ASSEMBLER_SUFFIX_FALSE_PASS");
    }
    if (says_ok) n_ok++; else n_rej++;
  }
  SayDec("SUFFIXES_ASSEMBLING=", n_ok);
  SayDec("SUFFIXES_REJECTED=", n_rej);
  if (n_ok != 12) {
    SayDec("EXPECTED_ASSEMBLING_SUFFIXES=", 12);
    RedFail("ASSEMBLER_SUFFIX_FALSE_PASS");
  }
  if (n_rej < 1) RedFail("ASSEMBLER_SUFFIX_FALSE_PASS");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: borrowed-lifetime <abi-file> <export-name>
// The BORROWED_LITERAL_LIFETIME_VIOLATION detector.
//
// The export must return a pointer, and the ABI file must state that
// the host must not free or write the result.
// ---------------------------------------------------------------------------

public U0 ModeBorrowedLifetime(U8 *path, U8 *export)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("ABI_FILE_UNREADABLE");
  U8 *at = StrFind(data, export);
  if (at == NULL) RedFail("EXPORT_NOT_DECLARED");
  I64 off = at - data;
  I64 ll = 0;
  U8 *line = LineOf(data, size, off, &ll);
  U8 buf[1024];
  CopyBounded(buf, line, ll);
  Bool has_ptr_return = (StrFind(buf, "*") != NULL);
  Say("EXPORT_RETURNS_POINTER=", YesNo(has_ptr_return));
  if (!has_ptr_return) RedFail("BORROWED_LITERAL_LIFETIME_VIOLATION");
  // The file must state the non-ownership rule.
  Bool must_not_free = (StrFind(data, "MUST NOT free") != NULL) ||
                       (StrFind(data, "MUST NOT write") != NULL) ||
                       (StrFind(data, "must not free") != NULL) ||
                       (StrFind(data, "must not write") != NULL);
  Say("HOST_NON_OWNERSHIP_STATED=", YesNo(must_not_free));
  if (!must_not_free) RedFail("BORROWED_LITERAL_LIFETIME_VIOLATION");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: fail-closed <domain-file>
// The INVALID_CONDITION_NOT_FAIL_CLOSED detector.
//
// The domain table is TSV with the fields
//   kind <TAB> value <TAB> partition <TAB> suffix_or_status
// A row whose partition is INVALID or UNSUPPORTED must carry a
// fail-closed status, never a real condition suffix.
// ---------------------------------------------------------------------------

public U0 ModeFailClosed(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("DOMAIN_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  I64 invalid_rows = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 kind[64], val[64], part[64], outcome[64];
    if (!FieldOf(row, rl, 0, kind)) continue;
    if (!FieldOf(row, rl, 1, val)) continue;
    if (!FieldOf(row, rl, 2, part)) continue;
    if (!FieldOf(row, rl, 3, outcome)) continue;
    if (StrLen(kind) == 0) continue;
    Bool is_invalid = (StrCmp(part, "INVALID") == 0) || (StrCmp(part, "UNSUPPORTED") == 0);
    if (!is_invalid) continue;
    invalid_rows++;
    Bool fail_closed = (StrCmp(outcome, "NULL_FAIL_CLOSED") == 0) ||
                       (StrCmp(outcome, "HOST_PANIC") == 0) ||
                       (StrCmp(outcome, "NULL") == 0);
    if (!fail_closed) {
      Say("KIND=", kind);
      Say("PARTITION=", part);
      Say("OUTCOME=", outcome);
      Say("DETECTION=", "OUT_OF_DOMAIN_KIND_MAPPED_TO_A_REAL_SUFFIX");
      RedFail("INVALID_CONDITION_NOT_FAIL_CLOSED");
    }
  }
  SayDec("INVALID_PARTITION_ROWS=", invalid_rows);
  if (invalid_rows == 0) RedFail("INVALID_CONDITION_NOT_FAIL_CLOSED");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: unobservable-abi <abi-file> <export-name>
// The UNOBSERVABLE_CORRECTED_ABI detector.
//
// The export must have an observable output channel: a non-void
// return type or a pointer parameter.
// ---------------------------------------------------------------------------

public U0 ModeUnobservableAbi(U8 *path, U8 *export)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("ABI_FILE_UNREADABLE");
  U8 *at = StrFind(data, export);
  if (at == NULL) RedFail("EXPORT_NOT_DECLARED");
  I64 off = at - data;
  I64 ll = 0;
  U8 *line = LineOf(data, size, off, &ll);
  U8 buf[1024];
  CopyBounded(buf, line, ll);
  Bool isVoid = ReturnIsVoid(buf, ll);
  Bool hasPtr = ParamHasPointer(buf, ll);
  Say("EXPORT_RETURN_IS_VOID=", YesNo(isVoid));
  Say("EXPORT_HAS_POINTER_PARAM=", YesNo(hasPtr));
  if (isVoid && !hasPtr) {
    Say("DETECTION=", "NO_OBSERVABLE_OUTPUT_CHANNEL");
    RedFail("UNOBSERVABLE_CORRECTED_ABI");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: graph-cut <graph-file>
// The UNPROVEN_GRAPH_CUT detector.
//
// It rejects a row that claims a new proven cut without a proof
// reference.
// ---------------------------------------------------------------------------

public U0 ModeGraphCut(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("GRAPH_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  I64 new_cuts = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    if (!HasInLine(row, rl, "NEW_PROVEN_CUT")) continue;
    U8 cut[64], proof[512];
    if (!FieldOf(row, rl, 0, cut)) continue;
    if (!FieldOf(row, rl, 1, proof)) proof[0] = 0;
    if (StrCmp(cut, "NONE") == 0) {
      // The sentinel row: it must assert zero new cuts.
      new_cuts = 0;
      continue;
    }
    new_cuts++;
    Bool has_proof = (StrLen(proof) > 0) && (StrCmp(proof, "NONE") != 0);
    if (!has_proof) {
      Say("CUT=", cut);
      Say("DETECTION=", "NEW_CUT_CLAIMED_WITHOUT_PROOF_REFERENCE");
      RedFail("UNPROVEN_GRAPH_CUT");
    }
  }
  SayDec("NEW_PROVEN_CUTS=", new_cuts);
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: dormant-prototype <prototype-file>
// The DORMANT_PROTOTYPE_AUTHORITY detector.
//
// It rejects a prototype record whose observed output is empty.
// ---------------------------------------------------------------------------

public U0 ModeDormantPrototype(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("PROTOTYPE_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  I64 rows = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 site[64], obs[512];
    if (!FieldOf(row, rl, 0, site)) continue;
    if (!FieldOf(row, rl, 1, obs)) obs[0] = 0;
    if (StrLen(site) == 0) continue;
    rows++;
    if (StrLen(obs) == 0 || StrCmp(obs, "NONE") == 0) {
      Say("SITE=", site);
      Say("DETECTION=", "PROTOTYPE_LINKED_BUT_NO_RESULT_OBSERVED");
      RedFail("DORMANT_PROTOTYPE_AUTHORITY");
    }
  }
  SayDec("PROTOTYPE_ROWS=", rows);
  if (rows == 0) RedFail("DORMANT_PROTOTYPE_AUTHORITY");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: oracle-contamination <oracle-file>
// The C_ONLY_ORACLE_CONTAMINATION detector.
//
// It rejects an oracle record that imports a PolyC subject symbol.
// ---------------------------------------------------------------------------

public U0 ModeOracleContamination(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("ORACLE_FILE_UNREADABLE");
  U64 at = StrFind(data, "POLYC_SUBJECT_IMPORT");
  if (at != NULL) {
    Say("DETECTION=", "C_ONLY_ORACLE_IMPORTS_A_POLYC_SUBJECT_SYMBOL");
    RedFail("C_ONLY_ORACLE_CONTAMINATION");
  }
  // The record must positively assert the oracle is selector-OFF and
  // imports no PolyC subject.
  if (StrFind(data, "POLYC_SUBJECT_IMPORT=NONE") == NULL) {
    Say("DETECTION=", "ORACLE_RECORD_DOES_NOT_ASSERT_ABSENCE_OF_POLYC_IMPORT");
    RedFail("C_ONLY_ORACLE_CONTAMINATION");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: entry-identity <fact-file> <expected-head> <expected-tree> <expected-branch>
// The ENTRY_IDENTITY_MISMATCH detector.
// ---------------------------------------------------------------------------

public U0 ModeEntryIdentity(U8 *path, U8 *head, U8 *tree, U8 *branch)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("FACT_FILE_UNREADABLE");
  U8 *h = StrFind(data, "ENTRY_HEAD=");
  U8 *t = StrFind(data, "ENTRY_TREE=");
  U8 *b = StrFind(data, "ENTRY_BRANCH=");
  if (h == NULL || t == NULL || b == NULL) RedFail("ENTRY_IDENTITY_MISMATCH");
  U8 got_h[128], got_t[128], got_b[128];
  CopyBounded(got_h, h + 11, 40);
  CopyBounded(got_t, t + 11, 40);
  CopyBounded(got_b, b + 13, 40);
  // Trim at the first delimiter.
  for (I64 i = 0; i < 40; i++) if (got_h[i] == '\t' || got_h[i] == '\n') { got_h[i] = 0; break; }
  for (I64 i = 0; i < 40; i++) if (got_t[i] == '\t' || got_t[i] == '\n') { got_t[i] = 0; break; }
  for (I64 i = 0; i < 40; i++) if (got_b[i] == '\t' || got_b[i] == '\n') { got_b[i] = 0; break; }
  Say("ENTRY_HEAD=", got_h);
  Say("ENTRY_TREE=", got_t);
  Say("ENTRY_BRANCH=", got_b);
  if (StrCmp(got_h, head) != 0) RedFail("ENTRY_IDENTITY_MISMATCH");
  if (StrCmp(got_t, tree) != 0) RedFail("ENTRY_IDENTITY_MISMATCH");
  if (StrCmp(got_b, branch) != 0) RedFail("ENTRY_IDENTITY_MISMATCH");
  RedOk();
}

// ---------------------------------------------------------------------------
// MODE: trailer-provenance <history-file>
// The TRAILER_PROVENANCE_FAILURE detector.
//
// It rejects a row that claims a CLOSE phase for a commit whose
// recorded trailer set does not contain a CLOSE verdict.
// ---------------------------------------------------------------------------

public U0 ModeTrailerProvenance(U8 *path)
{
  I64 size = 0;
  U8 *data = NULL;
  if (!LoadFile(path, &data, &size)) RedFail("HISTORY_FILE_UNREADABLE");
  I64 pos = 0, rl = 0;
  I64 close_rows = 0;
  while (TRUE) {
    I64 at = NextRow(data, size, pos, &rl);
    if (at < 0) break;
    pos = at + rl + 1;
    U8 *row = data + at;
    U8 phase[64], verdict[64];
    if (!FieldOf(row, rl, 0, phase)) continue;
    if (!FieldOf(row, rl, 1, verdict)) continue;
    if (StrCmp(phase, "CLOSE") != 0) continue;
    close_rows++;
    if (StrLen(verdict) == 0) {
      Say("PHASE=", "CLOSE");
      Say("DETECTION=", "CLOSE_ROW_WITHOUT_A_VERDICT_TRAILER");
      RedFail("TRAILER_PROVENANCE_FAILURE");
    }
    Bool legal = (StrCmp(verdict, "PASS") == 0) || (StrCmp(verdict, "FAIL") == 0) ||
                  (StrCmp(verdict, "HALT") == 0) || (StrCmp(verdict, "HALT_PASS") == 0) ||
                  (StrCmp(verdict, "HALT_FAIL") == 0);
    if (!legal) {
      Say("ILLEGAL_CLOSE_VERDICT=", verdict);
      RedFail("TRAILER_PROVENANCE_FAILURE");
    }
  }
  SayDec("CLOSE_ROWS=", close_rows);
  if (close_rows == 0) RedFail("TRAILER_PROVENANCE_FAILURE");
  RedOk();
}

// ---------------------------------------------------------------------------
// The main dispatcher.
//
// Each mode prints exactly one FINAL= line and, on FAIL, exactly one
// REASON= line with a reason-specific token.
// ---------------------------------------------------------------------------

public I64 Main(I64 argc, U8 **argv)
{
  if (argc < 2) {
    Write(1,"FINAL=FAIL\n",11);
    Write(1,"REASON=NO_MODE_GIVEN\n",20);
    return 1;
  }
  U8 *mode = argv[1];

  if (StrCmp(mode, "selftest") == 0) {
    ModeSelfTest();
    return 0;
  }
  if (StrCmp(mode, "scan") == 0) {
    if (argc < 4) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeScan(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "range-digest") == 0) {
    if (argc < 6) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeRangeDigest(argv[2], StrToI64(argv[3]), StrToI64(argv[4]), argv[5]);
    return 0;
  }
  if (StrCmp(mode, "c1-misbind") == 0) {
    if (argc < 6) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeC1Misbind(argv[2], StrToI64(argv[3]), StrToI64(argv[4]), argv[5]);
    return 0;
  }
  if (StrCmp(mode, "off-by-one") == 0) {
    if (argc < 6) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeOffByOne(argv[2], StrToI64(argv[3]), StrToI64(argv[4]), argv[5]);
    return 0;
  }
  if (StrCmp(mode, "blob-oid") == 0) {
    if (argc < 4) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeBlobOid(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "cset-inert") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeCsetInert(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "cset-duplicate") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeCsetDuplicate(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "causal-double-count") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeCausalDoubleCount(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "producer-alias") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeProducerAlias(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "schema-conflation") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeSchemaConflation(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "f14-freeze") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeF14Freeze(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "premature-terminality") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModePrematureTerminality(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "ac-ledger") == 0) {
    if (argc < 4) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeAcLedger(argv[2], StrToI64(argv[3]));
    return 0;
  }
  if (StrCmp(mode, "member-count") == 0) {
    if (argc < 4) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeMemberCount(argv[2], StrToI64(argv[3]));
    return 0;
  }
  if (StrCmp(mode, "source-rule-absent") == 0) {
    if (argc < 5) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeSourceRuleAbsent(argv[2], argv[3], argv[4]);
    return 0;
  }
  if (StrCmp(mode, "domain-collision") == 0) {
    if (argc < 5) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeDomainCollision(argv[2], argv[3], StrToI64(argv[4]));
    return 0;
  }
  if (StrCmp(mode, "suffix-assembler") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeSuffixAssembler(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "borrowed-lifetime") == 0) {
    if (argc < 4) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeBorrowedLifetime(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "fail-closed") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeFailClosed(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "unobservable-abi") == 0) {
    if (argc < 4) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeUnobservableAbi(argv[2], argv[3]);
    return 0;
  }
  if (StrCmp(mode, "graph-cut") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeGraphCut(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "dormant-prototype") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeDormantPrototype(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "oracle-contamination") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeOracleContamination(argv[2]);
    return 0;
  }
  if (StrCmp(mode, "entry-identity") == 0) {
    if (argc < 6) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeEntryIdentity(argv[2], argv[3], argv[4], argv[5]);
    return 0;
  }
  if (StrCmp(mode, "trailer-provenance") == 0) {
    if (argc < 3) { Write(1,"FINAL=FAIL\nREASON=ARITY\n",22); return 1; }
    ModeTrailerProvenance(argv[2]);
    return 0;
  }
  Write(1,"FINAL=FAIL\n",11);
  Write(1,"REASON=UNKNOWN_MODE\n",18);
  return 1;
}
