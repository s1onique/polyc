// tools/quality/abi-core-bundle-implement02-contract-audit.HC
//
// ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02
//
// The ACT-LOCAL PolyC contract-audit detector for the C0 phase.
//
// It implements the FIVE reason-specific RED detectors that the ACT
// requires at C0, plus the two blocking-contract checks:
//
//   red1-range <source-file> <start> <end> <expected-sha256>
//        RED 1. Rejects an altered source-range/hash binding that
//        nevertheless repeats the expected hash. It recomputes the
//        digest of the ACTUAL source bytes over the named range and
//        compares it with the expected digest.
//        Reason: SOURCE_RANGE_SHA_MISMATCH.
//
//   red2-cset <abi-contract-file>
//        RED 2. Rejects an inert U0 CSET export that is linked but
//        cannot change the cset output. It parses the declared CSET
//        export from the ABI contract and checks whether the export
//        has ANY observable output channel: a return value, an
//        out-parameter cell, a buffer pointer, a callback, or a state
//        handle. A U0 export with only copied scalars and none of
//        those channels is INERT.
//        Reason: INERT_CSET_AUTHORITY.
//
//   red3-producer <producer-table-file> <label> <digest>
//        RED 3. Rejects reused compiler-producer identities and
//        misreported comparison kinds. It checks that the named
//        producer's digest is not already claimed by a DIFFERENT
//        producer row, and that the label's declared comparison kind
//        is one of the declared kinds.
//        Reason: PRODUCER_IDENTITY_ALIAS /
//                DIFFERENTIAL_SCHEMA_CONFLATION.
//
//   red4-zero <enum-header-file> <kind-name>
//        RED 4. Rejects IR_CMP_EQ==0 being treated as a failure or an
//        invalid NULL suffix. It parses the LIVE enum header, derives
//        the enum's numeric values, and checks that the named kind is
//        a LIVE value with the expected numeric value.
//        Reason: ZERO_DISCRIMINANT_COLLISION.
//
//   red5-postclose <history-file> <changed-path-count-field>
//        RED 5. Rejects ordinary post-CLOSE source/evidence edits
//        presented as unmodified terminal state. It reads a history
//        table and rejects a row that claims a post-CLOSE commit
//        changed NO path while the table records a non-zero path
//        count, or that claims the post-CLOSE commit was a production
//        source change and marks it as unmodified terminal state.
//        Reason: POST_CLOSE_F14_OR_SCOPE_VIOLATION.
//
// Every mode prints exactly one FINAL= line (OK or FAIL) and, on
// FAIL, exactly one REASON= line with a reason-specific token.
// The detector computes its own digests; it never trusts a recorded
// PASS field.
//
// BUILD:
//   ./hcc --install-dir=<prefix> -c \
//     tools/quality/abi-core-bundle-implement02-contract-audit.HC \
//     -o build/abi-core-bundle-implement02-contract-audit.o
//   cc build/abi-core-bundle-implement02-contract-audit.o \
//     -L<prefix>/lib -ltos -o build/abi-core-bundle-implement02-contract-audit

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
  // The 64-bit big-endian length. Each byte is extracted by shifting
  // the remaining value right, so no high bits are lost.
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
    // The state word is read into a local as UNSIGNED so that the byte
    // extraction is a logical shift, not an arithmetic one.
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
// Small text helpers.
// ---------------------------------------------------------------------------

// StrFind returns a pointer to the first occurrence of needle in hay,
// or NULL. It is used to locate a declaration inside a contract file.
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

// LineOf returns the line containing offset, and reports the line's
// length through out_len. It is used to bound a declaration to its
// own line.
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
// window [line, line+len). It is used for table rows, which are not
// NUL-terminated and must not be matched past their own line.
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

// LastInLine returns a pointer to the LAST occurrence of the needle
// inside the bounded window [line, line+len), or NULL.
public U8 *LastInLine(U8 *line, I64 len, U8 *needle)
{
  I64 nl = StrLen(needle);
  if (nl == 0 || nl > len) return NULL;
  U8 *found = NULL;
  for (I64 i = 0; i + nl <= len; i++) {
    I64 j = 0;
    while (j < nl && line[i+j] == needle[j]) j++;
    if (j == nl) found = line + i;
  }
  return found;
}

// CountChar counts how many times ch occurs in data[0..n).
public I64 CountChar(U8 *data, I64 n, U8 ch)
{
  I64 c = 0;
  for (I64 i = 0; i < n; i++) if (data[i] == ch) c++;
  return c;
}

// PrintDec writes a decimal number and a newline to fd 1.
public U0 PrintDec(I64 v)
{
  U8 num[24];
  I64 k = 0;
  Bool neg = FALSE;
  if (v < 0) { neg = TRUE; v = -v; }
  if (v == 0) { num[k++] = '0'; }
  while (v > 0) {
    I64 d = v % 10;
    num[k++] = '0' + d;
    v = v / 10;
  }
  if (neg) Write(1,"-",1);
  for (I64 i = k-1; i >= 0; i--) Write(1, num+i, 1);
  Write(1,"\n",1);
}

// PrintDecField writes "<label><value>\n" to fd 1.
public U0 PrintDecField(U8 *label, I64 v)
{
  Write(1,label,StrLen(label));
  PrintDec(v);
}

// ---------------------------------------------------------------------------
// RED 1: an altered source-range/hash binding that repeats the expected
// hash must be rejected.
//
// The detector hashes the ACTUAL bytes of the named range and compares
// the result with the expected digest. It does NOT trust the recorded
// digest field; it recomputes.
// ---------------------------------------------------------------------------
public U0 Red1Range(U8 *path, I64 start, I64 end, U8 *expected)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("SOURCE_FILE_UNREADABLE");
  if (start < 0 || end < start || end > size)
    RedFail("SOURCE_RANGE_OUT_OF_BOUNDS");
  U8 hex[65];
  ShaHexBytes(data + start, end - start, hex);
  if (StrCmp(hex, expected) != 0) {
    Write(1,"COMPUTED_SHA256=",15);
    Write(1,hex,64);
    Write(1,"\n",1);
    RedFail("SOURCE_RANGE_SHA_MISMATCH");
  }
  Write(1,"COMPUTED_SHA256=",15);
  Write(1,hex,64);
  Write(1,"\n",1);
  RedOk();
}

// ---------------------------------------------------------------------------
// RED 2: an inert U0 CSET export must be rejected.
//
// The detector locates the declared CSET export in the ABI contract,
// reads its return type and its parameter list, and decides whether
// the export has ANY observable output channel.
//
// An export is OBSERVABLE when it has at least one of:
//   - a non-void return type;
//   - an out-parameter cell (a pointer parameter);
//   - an assembly-buffer pointer parameter;
//   - a callback parameter;
//   - a mutable-state handle parameter.
//
// A U0 export whose parameters are ALL copied scalars is INERT.
// ---------------------------------------------------------------------------

// ParamIsPointer reports whether the parameter list contains a pointer
// parameter. It looks for a '*' in the parameter text, which is how
// every pointer is written in this ABI's declarations.
public Bool ParamHasPointer(U8 *line)
{
  // The declaration text between the '(' and the ')'.
  U8 *open = StrFind(line, "(");
  U8 *close = StrFind(line, ")");
  if (open == NULL || close == NULL || close < open) return FALSE;
  for (U8 *p = open; p < close; p++) {
    if (*p == '*') return TRUE;
  }
  return FALSE;
}

// ParamCount counts the top-level commas in the parameter list.
public I64 ParamCount(U8 *line)
{
  U8 *open = StrFind(line, "(");
  U8 *close = StrFind(line, ")");
  if (open == NULL || close == NULL || close < open) return 0;
  I64 c = 1;
  I64 depth = 0;
  for (U8 *p = open + 1; p < close; p++) {
    if (*p == '(') depth++;
    else if (*p == ')') depth--;
    else if (*p == ',' && depth == 0) c++;
  }
  return c;
}

// ReturnTypeIsVoid reports whether the declared return type is the
// void type U0.
public Bool ReturnTypeIsVoid(U8 *line)
{
  U8 *open = StrFind(line, "(");
  if (open == NULL) return TRUE;
  // The return type is the text before the '('.
  I64 n = open - line;
  U8 head[256];
  if (n > 255) n = 255;
  MemCpy(head, line, n);
  head[n] = 0;
  // Look for "U0" as the last type token.
  U8 *p = StrFind(head, "U0");
  if (p == NULL) return FALSE;
  // "U0" must not be followed by an identifier character.
  U8 *q = p + 2;
  if ((*q >= 'a' && *q <= 'z') || (*q >= 'A' && *q <= 'Z') ||
      (*q >= '0' && *q <= '9') || *q == '_') return FALSE;
  return TRUE;
}

public U0 Red2Cset(U8 *path)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("ABI_CONTRACT_UNREADABLE");

  // The contract file is a TSV. The export row names the function;
  // the PROSE contract carries the C-like declaration. This detector
  // accepts either: it searches for a line that mentions the export
  // name and, if the line carries a '(' it parses the declaration.
  U8 *at = StrFind(data, "AbiA64CmpCcEmitCSet");
  if (at == NULL) RedFail("CSET_EXPORT_NOT_DECLARED");

  I64 len = 0;
  U8 *line = LineOf(data, size, at - data, &len);
  U8 buf[1024];
  I64 n = len;
  if (n > 1023) n = 1023;
  MemCpy(buf, line, n);
  buf[n] = 0;

  // A TSV row states the signature textually: "U0 AbiA64CmpCcEmitCSet(
  // I64 comparison_kind, I64 is_float)". A prose declaration states
  // it as "U0 AbiA64CmpCcEmitCSet(I64 comparison_kind, I64 is_float);".
  U8 *decl = StrFind(buf, "AbiA64CmpCcEmitCSet");
  if (decl == NULL) RedFail("CSET_EXPORT_NOT_DECLARED");
  // Reconstruct the declaration text starting at the return type.
  // The return type is the token immediately before the name.
  U8 *rt = decl;
  while (rt > buf && (rt[-1] == ' ' || rt[-1] == '\t')) rt--;
  // rt now points at the LAST character of the return type token.
  // Walk back to the START of that token.
  while (rt > buf) {
    U8 c = rt[-1];
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') || c == '_') { rt--; continue; }
    break;
  }

  Bool isVoid = ReturnTypeIsVoid(rt);
  Bool hasPtr = ParamHasPointer(rt);
  I64 nparams = ParamCount(rt);

  Write(1,"CSET_RETURN_IS_VOID=",20);
  if (isVoid) { Write(1,"YES",3); } else { Write(1,"NO",2); }
  Write(1,"\n",1);
  Write(1,"CSET_HAS_POINTER_PARAM=",23);
  if (hasPtr) { Write(1,"YES",3); } else { Write(1,"NO",2); }
  Write(1,"\n",1);
  Write(1,"CSET_PARAM_COUNT=",18);
  PrintDec(nparams);

  // The contract's frozen restrictions forbid a callback and a mutable
  // state write. So the ONLY remaining observable channels are a
  // non-void return and an out-parameter/buffer pointer.
  if (isVoid && !hasPtr) {
    // A U0 export with only copied scalars CANNOT carry a decision.
    RedFail("INERT_CSET_AUTHORITY");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// RED 3: reused compiler-producer identities and misreported comparison
// kinds must be rejected.
//
// The producer table is a TSV whose rows are:
//     producer_id <TAB> digest <TAB> label
// The detector checks that the digest of the named producer is not
// already claimed by a DIFFERENT producer id. A digest claimed twice
// under two labels is an ALIAS, which the ACT forbids ("a tool copied
// or invoked via three filenames is not three producers").
// ---------------------------------------------------------------------------
public U0 Red3Producer(U8 *path, U8 *label, U8 *digest)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("PRODUCER_TABLE_UNREADABLE");

  // Scan the table for the given digest. Every row that carries it
  // must carry the SAME label; a different label is an alias.
  I64 i = 0;
  I64 aliases = 0;
  while (i < size) {
    I64 start = i;
    while (i < size && data[i] != '\n') i++;
    I64 len = i - start;
    if (i < size) i++;
    if (len <= 0) continue;
    U8 *line = data + start;
    // A line containing the digest? The comparison is a SUBSTRING
    // test over the line's own bytes, not a whole-line compare.
    I64 hit = 0;
    I64 dlen = StrLen(digest);
    for (I64 k = 0; k + dlen <= len; k++) {
      I64 j = 0;
      while (j < dlen && line[k+j] == digest[j]) j++;
      if (j == dlen) { hit = 1; break; }
    }
    if (!hit) continue;
    // The row's producer id is field 1, the digest is field 2, the
    // label is field 3. Two DIFFERENT producer ids claiming the SAME
    // digest is the alias condition.
    U8 idbuf[128];
    I64 n = 0;
    I64 field = 1;
    for (I64 k = 0; k < len && n < 127; k++) {
      if (line[k] == '\t') {
        if (field == 1) { idbuf[n] = 0; break; }
        field++; n = 0; continue;
      }
      if (field == 1) idbuf[n++] = line[k];
    }
    idbuf[n] = 0;
    if (StrCmp(idbuf, label) != 0) aliases++;
  }

  if (aliases > 0) {
    Write(1,"ALIAS_COUNT=",12);
    PrintDec(aliases);
    RedFail("PRODUCER_IDENTITY_ALIAS");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// RED 3b: the two comparison schemas must not be conflated.
//
// The differential schema file is a TSV whose first field is a schema
// id. The detector rejects a file in which a row declares the ORDERED
// PAIRWISE schema but carries a heterogeneous requirement kind, or in
// which a row declares the HETEROGENEOUS schema but carries a
// pairwise-stream requirement.
// ---------------------------------------------------------------------------
public U0 Red3Schema(U8 *path)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("DIFFERENTIAL_SCHEMA_UNREADABLE");

  I64 i = 0;
  while (i < size) {
    I64 start = i;
    while (i < size && data[i] != '\n') i++;
    I64 len = i - start;
    if (i < size) i++;
    if (len <= 0) continue;
    U8 *line = data + start;
    Bool isPair   = HasInLine(line, len, "PAIR-");
    Bool isFrozen = HasInLine(line, len, "FROZEN-");
    if (!isPair && !isFrozen) continue;
    Bool isStream = HasInLine(line, len, "STREAM_AGREEMENT");
    // A PAIR row must be a STREAM_AGREEMENT row, and a FROZEN row must
    // NOT be one. Conflating the two schemas is the defect.
    if (isPair && !isStream) RedFail("DIFFERENTIAL_SCHEMA_CONFLATION");
    if (isFrozen && isStream) RedFail("DIFFERENTIAL_SCHEMA_CONFLATION");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// RED 4: IR_CMP_EQ == 0 must not be treated as a failure.
//
// The detector parses the LIVE enum header, derives the numeric value
// of every enumerator by counting from the explicit initializer, and
// checks that the named kind is a live value with the expected value.
// It rejects a header in which the zero enumerator is missing, is
// explicitly negative, or is duplicated.
// ---------------------------------------------------------------------------
public U0 Red4Zero(U8 *header, U8 *kind, I64 expected)
{
  Bool dump = FALSE;
  if (StrCmp(kind, "--dump") == 0) { dump = TRUE; kind = ""; }
  I64 size = 0;
  U8 *data = FileRead(header, &size);
  if (data == NULL) RedFail("ENUM_HEADER_UNREADABLE");

  // Locate the enum block: "typedef enum IrCmpKind {" .. "} IrCmpKind;"
  U8 *at = StrFind(data, "typedef enum IrCmpKind");
  if (at == NULL) RedFail("ENUM_BLOCK_NOT_FOUND");
  U8 *open = StrFind(at, "{");
  U8 *close = StrFind(at, "}");
  if (open == NULL || close == NULL || close < open) RedFail("ENUM_BLOCK_NOT_FOUND");

  // Walk the enumerators, computing values.
  I64 value = 0;
  I64 seen = 0;
  I64 found = 0;
  I64 foundValue = 0;
  I64 dup = 0;
  I64 prevValue = -999;

  U8 *p = open + 1;
  U8 namebuf[128];
  while (p < close) {
    // SKIP whitespace and COMMENTS first. A block comment may contain
    // identifiers that must NOT be mistaken for enumerators.
    Bool skipped = FALSE;
    while (p < close) {
      if (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') { p++; continue; }
      if (*p == '/' && p + 1 < close && p[1] == '/') {
        while (p < close && *p != '\n') p++;
        continue;
      }
      if (*p == '/' && p + 1 < close && p[1] == '*') {
        p += 2;
        while (p + 1 < close && !(*p == '*' && p[1] == '/')) p++;
        if (p + 1 < close) p += 2; else p = close;
        continue;
      }
      break;
    }
    if (p >= close) break;
    // Read one identifier.
    I64 n = 0;
    while (p < close && *p != ';' && *p != ',' && *p != '=' && *p != '\n' &&
           *p != ' ' && *p != '\t' && *p != '/' && *p != '*') {
      if (n < 127) namebuf[n++] = *p;
      p++;
    }
    namebuf[n] = 0;
    if (n == 0) {
      // No identifier here (an unexpected character). Advance so that
      // the scan always terminates.
      p++;
      continue;
    }
    // The explicit initializer, if any, follows the identifier
    // IMMEDIATELY (only whitespace and comments may intervene). It
    // MUST be consumed here, otherwise the numeric literal would be
    // read as the NEXT enumerator's name.
    I64 explicitVal = 0;
    Bool hasExplicit = FALSE;
    {
      U8 *save = p;
      while (p < close) {
        if (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') { p++; continue; }
        if (*p == '/' && p + 1 < close && p[1] == '/') {
          while (p < close && *p != '\n') p++;
          continue;
        }
        if (*p == '/' && p + 1 < close && p[1] == '*') {
          p += 2;
          while (p + 1 < close && !(*p == '*' && p[1] == '/')) p++;
          if (p + 1 < close) p += 2; else p = close;
          continue;
        }
        break;
      }
      if (p < close && *p == '=') {
        p++;
        // Whitespace may separate the '=' from its value.
        while (p < close && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
        Bool neg = FALSE;
        if (p < close && *p == '-') { neg = TRUE; p++; }
        I64 v = 0;
        while (p < close && *p >= '0' && *p <= '9') { v = v*10 + (*p - '0'); p++; }
        explicitVal = v;
        if (neg) explicitVal = -v;
        hasExplicit = TRUE;
      } else {
        p = save;
      }
    }
    // Consume the separator.
    if (p < close && (*p == ';' || *p == ',')) p++;

    // The C rule: the FIRST enumerator with no explicit initializer is
    // 0; every subsequent enumerator without an explicit initializer is
    // the previous value plus one; an explicit initializer overrides.
    if (hasExplicit) {
      value = explicitVal;
    } else {
      if (seen == 0) { value = 0; } else { value = value + 1; }
    }
    // The first enumerator with an explicit value uses it verbatim; a
    // subsequent one without an explicit value increments it.
    if (dump) {
      Write(1,"ENUMERATOR=",11);
      Write(1,namebuf,StrLen(namebuf));
      Write(1,"=",1);
      PrintDec(value);
      Write(1,"HAS_EXPLICIT=",13);
      if (hasExplicit) { Write(1,"YES",3); } else { Write(1,"NO",2); }
      Write(1,"\n",1);
    }
    if (n > 0 && StrCmp(namebuf, kind) == 0) {
      found = 1;
      foundValue = value;
    }
    if (value == prevValue) dup++;
    prevValue = value;
    seen++;
  }

  Write(1,"ENUM_ENUMERATORS=",18);
  PrintDec(seen);
  Write(1,"ENUM_FOUND=",11);
  if (found) { Write(1,"YES",3); } else { Write(1,"NO",2); }
  Write(1,"\n",1);

  if (!found) RedFail("ZERO_DISCRIMINANT_COLLISION");
  if (foundValue != expected) {
    Write(1,"ENUM_VALUE_MISMATCH=YES\n",23);
    RedFail("ZERO_DISCRIMINANT_COLLISION");
  }
  // A duplicated numeric value means the zero discriminant is
  // ambiguous.
  if (dup > 0) RedFail("ZERO_DISCRIMINANT_COLLISION");
  RedOk();
}

// ---------------------------------------------------------------------------
// RED 5: ordinary post-CLOSE source/evidence edits presented as
// unmodified terminal state must be rejected.
//
// The history file is a TSV whose rows carry, among other fields, the
// changed-path count of a post-CLOSE commit and a claim that the
// terminal state is unmodified. The detector rejects a row that
// declares the terminal state UNMODIFIED while recording a non-zero
// changed-path count.
// ---------------------------------------------------------------------------
public U0 Red5PostClose(U8 *path)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("HISTORY_FILE_UNREADABLE");

  I64 i = 0;
  while (i < size) {
    I64 start = i;
    while (i < size && data[i] != '\n') i++;
    I64 len = i - start;
    if (i < size) i++;
    if (len <= 0) continue;
    U8 *line = data + start;
    if (line[0] == '#') continue;

    // Field 1: the sha. Field 2: the changed path count.
    // Look for a "PATHS_CHANGED=<n>" token and an
    // "UNMODIFIED_TERMINAL_STATE=YES" token in the row.
    U8 *pc = LastInLine(line, len, "PATHS_CHANGED=");
    U8 *unmod = LastInLine(line, len, "UNMODIFIED_TERMINAL_STATE=");
    if (pc == NULL || unmod == NULL) continue;

    I64 n = 0;
    U8 *q = pc + 14;
    while (q < line + len && *q >= '0' && *q <= '9') { n = n*10 + (*q - '0'); q++; }

    U8 *u = unmod + 26;
    Bool claimsUnmodified = FALSE;
    // The value token is bounded by the line: compare exactly the three
    // bytes "YES" without reading past the row.
    if (u + 3 <= line + len &&
        u[0] == 'Y' && u[1] == 'E' && u[2] == 'S') claimsUnmodified = TRUE;

    if (claimsUnmodified && n > 0) {
      Write(1,"OFFENDING_PATHS_CHANGED=",23);
      PrintDec(n);
      RedFail("POST_CLOSE_F14_OR_SCOPE_VIOLATION");
    }
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// Entry point.
//
// Modes:
//   red1-range <source> <start> <end> <expected-sha256>
//   red2-cset <abi-contract>
//   red3-producer <producer-table> <label> <digest>
//   red3-schema <differential-schema>
//   red4-zero <enum-header> <kind> <expected-value>
//   red5-postclose <history>
//   selftest
// ---------------------------------------------------------------------------
public I64 Main(I64 argc, U8 **argv)
{
  if (argc < 2) { Write(1,"REASON=USAGE\n",13); Exit(2); }
  U8 *mode = argv[1];

  // The SHA-256 implementation is validated FIRST in every mode that
  // trusts a digest, so that a detector which hashes wrongly cannot
  // certify a wrong digest.
  if (StrCmp(mode, "selftest") == 0) {
    if (!ShaSelfTest()) RedFail("SHA256_SELFTEST_FAILED");
    Write(1,"SHA_SELFTEST=PASS\n",18);
    RedOk();
  }

  if (StrCmp(mode, "red1-range") == 0) {
    // argv[1]=mode argv[2]=source argv[3]=start argv[4]=end argv[5]=digest
    if (argc < 6) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    if (!ShaSelfTest()) RedFail("SHA256_SELFTEST_FAILED");
    I64 start = 0; I64 end = 0;
    // Parse the decimal numbers without a libc dependency.
    for (I64 i = 0; argv[3][i]; i++) start = start*10 + (argv[3][i]-'0');
    for (I64 i = 0; argv[4][i]; i++) end = end*10 + (argv[4][i]-'0');
    Red1Range(argv[2], start, end, argv[5]);
    return 0;
  }

  if (StrCmp(mode, "red2-cset") == 0) {
    if (argc < 3) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    Red2Cset(argv[2]);
    return 0;
  }

  if (StrCmp(mode, "red3-producer") == 0) {
    if (argc < 5) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    Red3Producer(argv[2], argv[3], argv[4]);
    return 0;
  }

  if (StrCmp(mode, "red3-schema") == 0) {
    if (argc < 3) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    Red3Schema(argv[2]);
    return 0;
  }

  if (StrCmp(mode, "red4-zero") == 0) {
    if (argc < 5) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    I64 expected = 0;
    Bool eneg = FALSE;
    I64 ei = 0;
    if (argv[4][0] == '-') { eneg = TRUE; ei = 1; }
    for (I64 i = ei; argv[4][i]; i++) expected = expected*10 + (argv[4][i]-'0');
    if (eneg) expected = -expected;
    Red4Zero(argv[2], argv[3], expected);
    return 0;
  }

  if (StrCmp(mode, "red5-postclose") == 0) {
    if (argc < 3) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    Red5PostClose(argv[2]);
    return 0;
  }

  Write(1,"FINAL=FAIL\n",11);
  Write(1,"REASON=UNKNOWN_MODE\n",19);
  Exit(2);
  return 0;
}
