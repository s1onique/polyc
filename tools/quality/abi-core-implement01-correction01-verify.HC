// ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01
//
// The substantive PolyC verifier for this correction ACT.
//
// It is NOT a general-purpose tool. It recomputes, from the committed
// Git objects and from the raw experiment artifacts of the correction
// ACT, exactly the joins that the correction has to certify:
//
//   1. the historical M-POLYC-RO attribution defect (the recorded
//      experiment physically mutated AbiCoreIsValidPointerOperator);
//   2. the site-isolation matrix (CA / PO / RO each bound to its OWN
//      physical execution id, source digest, object digest and witness);
//   3. the acceptance-ledger integrity (no missing, duplicate or
//      unexpected acceptance/control id; no forged PASS).
//
// The verifier is deliberately reason-specific: it prints a machine
// readable REASON token and returns a nonzero status for each distinct
// failure class, so an adverse control can be shown to fire for its OWN
// reason rather than merely "not green".
//
// BUILD:
//   $(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -c \
//     tools/quality/abi-core-implement01-correction01-verify.HC \
//     -o build/abi-core-implement01-correction01-verify.o
//   cc build/abi-core-implement01-correction01-verify.o \
//     -L$(TEST_PREFIX)/lib -ltos -o build/abi-core-implement01-correction01-verify
//
// MODES:
//   historical-ro <impl01-evidence-dir>
//        Re-derives, from the committed predecessor evidence, which
//        function the recorded M-POLYC-RO digests belong to, by
//        RECOMPUTING the candidate mutations and comparing digests.
//
//   join <c2-join-tsv>
//        Checks the source/object/witness/execution joins for site
//        misbinding, duplicate execution ids and forged PASS rows.
//
//   ledger <ac-tsv> <nc-tsv>
//        Checks an acceptance ledger and a negative-control ledger for
//        missing / duplicate / unknown ids and for forged PASS rows.
//
// Every mode prints exactly one FINAL= line: OK or FAIL, and on FAIL
// exactly one REASON= line.

#include "../../src/holyc-lib/strings.HC"
#include "../../src/holyc-lib/io.HC"
#include "../../src/holyc-lib/system.HC"

// ---------------------------------------------------------------------------
// Reporting. Every mode ends with exactly one FINAL= line and, on
// failure, exactly one REASON= line.
// ---------------------------------------------------------------------------

public U0 VFail(U8 *reason)
{
  Write(1,"FINAL=FAIL\n",11);
  Write(1,"REASON=",7);
  Write(1,reason,StrLen(reason));
  Write(1,"\n",1);
  Exit(1);
}

public U0 VOk()
{
  Write(1,"FINAL=OK\n",9);
  Exit(0);
}

public U0 VLine(U8 *fmt, U8 *a, U8 *b, U8 *c)
{
  U8 *s = StrPrint(NULL,fmt,a,b,c);
  Write(1,s,StrLen(s));
  Write(1,"\n",1);
}

public Bool StrEq(U8 *a, U8 *b)
{
  if (a == NULL || b == NULL) return FALSE;
  return StrCmp(a,b) == 0;
}

// ---------------------------------------------------------------------------
// SHA-256. Implemented here so the verifier has no external dependency and
// computes its own digests rather than trusting a recorded field.
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

// A 32-bit rotate. PolyC's `<<` is a 64-bit shift, so the left part
// must be masked back to 32 bits explicitly; in C an `I32` shift would
// truncate implicitly.
public U64 ShaRot(U64 x, I32 n)
{
  U64 lo = (x >> n) & 0xFFFFFFFF;
  U64 hi = (x << (32 - n)) & 0xFFFFFFFF;
  return (lo | hi) & 0xFFFFFFFF;
}

public U0 ShaBlock(Sha256 *s, U8 *p)
{
  // The whole round is computed in U64 and masked back to 32 bits at
  // each step, because PolyC's shifts are 64-bit and its `>>` on a
  // signed value is an arithmetic shift.
  U64 w[64];
  U8 *q = p;
  for (I32 i = 0; i < 16; i++) {
    U64 b0 = q[0];
    U64 b1 = q[1];
    U64 b2 = q[2];
    U64 b3 = q[3];
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
  U64 a = s->h[0] & 0xFFFFFFFF;
  U64 b = s->h[1] & 0xFFFFFFFF;
  U64 c = s->h[2] & 0xFFFFFFFF;
  U64 d = s->h[3] & 0xFFFFFFFF;
  U64 e = s->h[4] & 0xFFFFFFFF;
  U64 f = s->h[5] & 0xFFFFFFFF;
  U64 g = s->h[6] & 0xFFFFFFFF;
  U64 hh = s->h[7] & 0xFFFFFFFF;
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
  s->h[0] = (s->h[0] + a) & 0xFFFFFFFF;
  s->h[1] = (s->h[1] + b) & 0xFFFFFFFF;
  s->h[2] = (s->h[2] + c) & 0xFFFFFFFF;
  s->h[3] = (s->h[3] + d) & 0xFFFFFFFF;
  s->h[4] = (s->h[4] + e) & 0xFFFFFFFF;
  s->h[5] = (s->h[5] + f) & 0xFFFFFFFF;
  s->h[6] = (s->h[6] + g) & 0xFFFFFFFF;
  s->h[7] = (s->h[7] + hh) & 0xFFFFFFFF;
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
    // The state word is read as UNSIGNED so that the byte extraction is
    // a logical shift, not an arithmetic one.
    U64 word = s->h[i];
    for (I32 j = 3; j >= 0; j--) {
      U64 byte = (word >> (8*j)) & 0xFF;
      *o++ = hex[byte >> 4];
      *o++ = hex[byte & 15];
    }
  }
  *o = 0;
}

// Digest of a whole file. Returns FALSE when the file cannot be read.
public Bool ShaFile(U8 *path, U8 *out)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) return FALSE;
  Sha256 s;
  ShaInit(&s);
  ShaUpdate(&s, data, size);
  ShaFinal(&s, out);
  return TRUE;
}

// Digest of a byte range.
public U0 ShaRange(U8 *src, I64 start, I64 end, U8 *out)
{
  Sha256 s;
  ShaInit(&s);
  ShaUpdate(&s, src + start, end - start);
  ShaFinal(&s, out);
}

// Digest of a byte range with every line containing `needle` removed.
public U0 ShaRangeWithoutLine(U8 *src, I64 start, I64 end, U8 *needle, U8 *out)
{
  Sha256 s;
  ShaInit(&s);
  I64 i = start;
  I64 nlen = StrLen(needle);
  while (i < end) {
    I64 lineend = i;
    while (lineend < end && src[lineend] != '\n') lineend++;
    I64 linelen = lineend - i;
    Bool hit = FALSE;
    if (linelen >= nlen && nlen > 0) {
      // The needle is searched with a moving pointer for the same
      // reason as in ShaBlock: the scaled-index byte-load form is not
      // assemblable on this arm64 host.
      U8 *line = src + i;
      for (I64 k = 0; k + nlen <= linelen; k++) {
        Bool same = TRUE;
        U8 *c = line + k;
        U8 *n = needle;
        for (I64 j = 0; j < nlen; j++) {
          if (c[j] != n[j]) { same = FALSE; break; }
        }
        if (same) { hit = TRUE; break; }
      }
    }
    if (!hit) ShaUpdate(&s, src + i, linelen + 1);
    i = lineend + 1;
  }
  ShaFinal(&s, out);
}



// HolyC has no StrStr. Substring search over a NUL-terminated buffer.
public U8 *FindStr(U8 *hay, U8 *needle)
{
  if (hay == NULL || needle == NULL) return NULL;
  I64 nlen = StrLen(needle);
  if (nlen == 0) return hay;
  U8 *p = hay;
  while (*p) {
    if (!StrNCmp(p, needle, nlen)) return p;
    p++;
  }
  return NULL;
}

// Locates the byte range of a function whose definition starts at the
// line containing `signature` and ends at the line containing the
// matching closing brace at column 0.
public Bool FuncRange(U8 *src, I64 srclen, U8 *signature, I64 *start_out, I64 *end_out)
{
  // The signature may also appear inside a COMMENT (the subject file
  // documents its own functions in prose). The DEFINITION is the
  // occurrence whose line ends with the opening brace.
  I64 search = 0;
  while (search < srclen) {
    U8 *p = FindStr(src + search, signature);
    if (p == NULL) return FALSE;
    I64 start = p - src;
    // A definition's signature line is not a comment line.
    I64 line_start = start;
    while (line_start > 0 && src[line_start-1] != '\n') line_start--;
    if (src[line_start] == '/' && src[line_start+1] == '/') {
      search = start + 1;
      continue;
    }
    // The opening brace is on the signature line or on the next line.
    I64 brace = start;
    while (brace < srclen && src[brace] != '{') {
      if (src[brace] == '\n') {
        // Only the immediately following line may hold the brace.
        I64 nl = brace + 1;
        while (nl < srclen && (src[nl] == ' ' || src[nl] == '\t')) nl++;
        if (nl < srclen && src[nl] == '{') { brace = nl; break; }
        break;
      }
      brace++;
    }
    if (brace >= srclen || src[brace] != '{') { search = start + 1; continue; }

    *start_out = start;
    *end_out = -1;
    // The body ends at the closing brace at column 0.
    I64 j = brace;
    while (j < srclen) {
      if (src[j] == '\n') {
        I64 k = j + 1;
        while (k < srclen && (src[k] == ' ' || src[k] == '\t')) k++;
        if (k < srclen && src[k] == '}') {
          I64 e2 = k + 1;
          while (e2 < srclen && src[e2] != '\n') e2++;
          *end_out = e2;
          return TRUE;
        }
      }
      j++;
    }
    return FALSE;
  }
  return FALSE;
}

// Digest of a whole file with every line inside [start,end) that
// contains `needle` removed. The historical record's mutant digest is
// the digest of the WHOLE subject source with the named case removed,
// so the comparison must be made at whole-file granularity.
public U0 ShaFileWithoutLineInRange(U8 *path, I64 start, I64 end,
                                     U8 *needle, U8 *out)
{
  I64 size = 0;
  U8 *src = FileRead(path, &size);
  if (src == NULL) { out[0] = 0; return; }
  I64 nlen = StrLen(needle);
  Sha256 s;
  ShaInit(&s);
  I64 i = 0;
  while (i < size) {
    I64 lineend = i;
    while (lineend < size && src[lineend] != '\n') lineend++;
    I64 linelen = lineend - i;
    Bool hit = FALSE;
    if (i >= start && i < end && linelen >= nlen && nlen > 0) {
      U8 *line = src + i;
      for (I64 k = 0; k + nlen <= linelen; k++) {
        Bool same = TRUE;
        U8 *c = line + k;
        U8 *n = needle;
        for (I64 j = 0; j < nlen; j++) {
          if (c[j] != n[j]) { same = FALSE; break; }
        }
        if (same) { hit = TRUE; break; }
      }
    }
    if (!hit) ShaUpdate(&s, src + i, linelen + 1);
    i = lineend + 1;
  }
  ShaFinal(&s, out);
}

// Extracts a "key<TAB>value" pair from an evidence file body. The key
// must start a line.
public Bool KvLookup(U8 *body, U8 *key, U8 *out, I64 cap)
{
  I64 blen = StrLen(body);
  I64 klen = StrLen(key);
  U8 *p = body;
  while (p != NULL) {
    p = FindStr(p, key);
    if (p == NULL) break;
    if (p == body || p[-1] == '\n') {
      U8 *q = p + klen;
      if (q < body + blen && *q == '\t') {
        q++;
        I64 n = 0;
        while (q[n] != '\n' && q[n] != 0 && n < cap - 1) n++;
        MemCpy(out, q, n);
        out[n] = 0;
        return TRUE;
      }
    }
    p += klen;
  }
  return FALSE;
}

// Splits a TSV row into fields. Returns the field count.
public I32 SplitTsv(U8 *row, U8 fields[][512], I32 maxfields)
{
  I32 n = 0;
  I64 i = 0;
  I64 len = StrLen(row);
  while (n < maxfields) {
    I64 start = i;
    while (i < len && row[i] != '\t') i++;
    I64 l = i - start;
    if (l > 511) l = 511;
    MemCpy(fields[n], row + start, l);
    fields[n][l] = 0;
    n++;
    if (i >= len) break;
    i++;
  }
  return n;
}


// ---------------------------------------------------------------------------
// MODE 1: historical-ro
//
// The question: WHICH function does the recorded M-POLYC-RO source digest
// belong to?
//
// The method is digest identity, never inference. The verifier takes the
// recorded digest of the historical M-POLYC-RO mutant SOURCE and the
// pristine subject source's bytes, and requires that the recorded digest
// be reachable by exactly one of the two candidate functions.
//
// The evidence directory must contain c3/mutant-ro.tsv, which carries the
// recorded mutant_source_sha256.
//
// The pristine subject source path is taken from the environment
// variable CORR01_PRISTINE_SOURCE, so that the verifier hashes the
// COMMITTED bytes rather than a copy that could have drifted.
//
// The point of the check is the NEGATIVE one: the recorded digest must
// NOT match the RO function's mutated bytes, and MUST match the PO
// function's mutated bytes. If an INTENDED .diff is substituted for the
// actual compiled bytes, the recomputation cannot reproduce the recorded
// digest from the RO function, and the verifier reports
// HISTORICAL_MUTATION_SUBJECT_MISMATCH instead of silently agreeing.
// ---------------------------------------------------------------------------

public U0 ModeHistoricalRo(U8 *evdir)
{
  U8 *path = StrPrint(NULL,"%s/c3/mutant-ro.tsv",evdir);
  I64 size = 0;
  U8 *body = FileRead(path, &size);
  if (body == NULL) VFail("EVIDENCE_FILE_MISSING");

  U8 recorded[128];
  if (!KvLookup(body, "mutant_source_sha256", recorded, 128))
    VFail("RECORDED_DIGEST_ABSENT");

  U8 *pristine_path = getenv("CORR01_PRISTINE_SOURCE");
  if (pristine_path == NULL) VFail("PRISTINE_SOURCE_NOT_SPECIFIED");
  U8 *src = FileRead(pristine_path, &size);
  if (src == NULL) VFail("PRISTINE_SOURCE_MISSING");

  U8 pristine_digest[80];
  if (!ShaFile(pristine_path, pristine_digest)) VFail("PRISTINE_SOURCE_MISSING");

  I64 ro_start = 0, ro_end = 0, po_start = 0, po_end = 0;
  if (!FuncRange(src, size, "I64 AbiCoreIsRangeOperator(I64 binary_operator)", &ro_start, &ro_end))
    VFail("RO_FUNCTION_NOT_FOUND");
  if (!FuncRange(src, size, "I64 AbiCoreIsValidPointerOperator(I64 binary_operator)", &po_start, &po_end))
    VFail("PO_FUNCTION_NOT_FOUND");

  // The two ranges must be DISJOINT.
  if (!(po_end <= ro_start || ro_end <= po_start))
    VFail("FUNCTION_RANGES_OVERLAP");

  U8 ro_mut[80], po_mut[80];
  ShaFileWithoutLineInRange(pristine_path, ro_start, ro_end, "AST_BIN_OP_LT", ro_mut);
  ShaFileWithoutLineInRange(pristine_path, po_start, po_end, "AST_BIN_OP_LT", po_mut);

  VLine("PRISTINE_SOURCE_SHA256=%s",pristine_digest,NULL,NULL);
  VLine("RECORDED_M_POLYC_RO_SOURCE_SHA256=%s",recorded,NULL,NULL);
  VLine("RO_FUNCTION_RANGE=%s",StrPrint(NULL,"%d..%d",ro_start,ro_end),NULL,NULL);
  VLine("PO_FUNCTION_RANGE=%s",StrPrint(NULL,"%d..%d",po_start,po_end),NULL,NULL);
  VLine("RO_FILE_WITHOUT_LT_SHA256=%s",ro_mut,NULL,NULL);
  VLine("PO_FILE_WITHOUT_LT_SHA256=%s",po_mut,NULL,NULL);

  Bool ro_matches = StrEq(recorded, ro_mut);
  Bool po_matches = StrEq(recorded, po_mut);

  U8 *ro_s = "NO";
  U8 *po_s = "NO";
  if (ro_matches) ro_s = "YES";
  if (po_matches) po_s = "YES";
  VLine("RECORDED_MATCHES_RO_FUNCTION=%s",ro_s,NULL,NULL);
  VLine("RECORDED_MATCHES_PO_FUNCTION=%s",po_s,NULL,NULL);

  if (po_matches && !ro_matches) {
    VLine("HISTORICAL_M_POLYC_RO_ACTUAL_SUBJECT=AbiCoreIsValidPointerOperator",NULL,NULL,NULL);
    VLine("HISTORICAL_RO_CAUSAL=UNPROVEN_AS_RECORDED",NULL,NULL,NULL);
    VOk();
  }
  VFail("HISTORICAL_MUTATION_SUBJECT_MISMATCH");
}


// ---------------------------------------------------------------------------
// MODE 2: join
//
// Checks the source/object/witness/execution joins for site misbinding,
// duplicate execution ids and forged PASS rows.
//
// The join file is a TSV with a header row. Each data row binds:
//   site_id | execution_id | subject_symbol | source_sha256 |
//   object_sha256 | witness_id | witness_pristine_exit |
//   witness_mutant_exit | witness_restored_exit | causal_verdict
//
// The verifier requires:
//   - every site_id in {SITE-COMPOUND-ASSIGN, SITE-VALID-POINTER-OP,
//     SITE-RANGE-OPERATOR} appears exactly once;
//   - every execution_id is distinct;
//   - every source_sha256 is distinct;
//   - every object_sha256 is distinct;
//   - the RO row's witness exits are 0 (pristine), 1 (mutant), 0 (restored);
//   - the RO row's witness id is W-CORR-RO-DISCRIM;
//   - the PO row's witness is NOT the RO discriminator;
//   - every row's verdict is PASS.
// ---------------------------------------------------------------------------

#define MAXF 64

public U0 ModeJoin(U8 *join_path)
{
  I64 size = 0;
  U8 *body = FileRead(join_path, &size);
  if (body == NULL) VFail("JOIN_FILE_MISSING");

  U8 exec_ids[16][128];
  U8 src_ids[16][128];
  U8 obj_ids[16][128];
  I32 n_exec = 0, n_src = 0, n_obj = 0;
  I32 seen_ca = 0, seen_po = 0, seen_ro = 0;

  U8 *line = body;
  while (line != NULL && *line) {
    U8 *nl = strchr(line,'\n');
    if (nl) *nl = 0;
    if (line[0] != '#' && line[0] != 0) {
      U8 fields[MAXF][512];
      I32 nf = SplitTsv(line, fields, MAXF);
      if (nf >= 10 && !StrEq(fields[0],"site_id")) {
        U8 *site = fields[0];
        U8 *exe = fields[1];
        U8 *sym = fields[2];
        U8 *srcsha = fields[3];
        U8 *objsha = fields[4];
        U8 *wit = fields[5];
        U8 *pexit = fields[6];
        U8 *mexit = fields[7];
        U8 *rexit = fields[8];
        U8 *verdict = fields[9];

        // The subject symbol must match the site.
        if (StrEq(site,"SITE-RANGE-OPERATOR") && !StrEq(sym,"_AbiCoreIsRangeOperator"))
          VFail("SITE_ISOLATION_OR_WITNESS_MISBIND");
        if (StrEq(site,"SITE-VALID-POINTER-OP") && !StrEq(sym,"_AbiCoreIsValidPointerOperator"))
          VFail("SITE_ISOLATION_OR_WITNESS_MISBIND");
        if (StrEq(site,"SITE-COMPOUND-ASSIGN") && !StrEq(sym,"_AbiCoreClassifyCompoundAssign"))
          VFail("SITE_ISOLATION_OR_WITNESS_MISBIND");

        // Distinct execution ids.
        for (I32 i = 0; i < n_exec; i++)
          if (StrEq(exec_ids[i],exe)) VFail("DUPLICATE_PHYSICAL_EXECUTION_ID");
        if (n_exec < 16) { MemCpy(exec_ids[n_exec],exe,StrLen(exe)+1); n_exec++; }

        // Distinct source digests.
        for (I32 i = 0; i < n_src; i++)
          if (StrEq(src_ids[i],srcsha)) VFail("DUPLICATE_PHYSICAL_EXECUTION_ID");
        if (n_src < 16) { MemCpy(src_ids[n_src],srcsha,StrLen(srcsha)+1); n_src++; }

        // Distinct object digests.
        for (I32 i = 0; i < n_obj; i++)
          if (StrEq(obj_ids[i],objsha)) VFail("DUPLICATE_PHYSICAL_EXECUTION_ID");
        if (n_obj < 16) { MemCpy(obj_ids[n_obj],objsha,StrLen(objsha)+1); n_obj++; }

        if (StrEq(site,"SITE-COMPOUND-ASSIGN")) seen_ca++;
        else if (StrEq(site,"SITE-VALID-POINTER-OP")) seen_po++;
        else if (StrEq(site,"SITE-RANGE-OPERATOR")) seen_ro++;
        else VFail("UNKNOWN_SITE_ID");

        if (StrEq(site,"SITE-RANGE-OPERATOR")) {
          // The RO discriminator MUST change 0 -> 1 -> 0.
          if (!StrEq(pexit,"0") || !StrEq(mexit,"1") || !StrEq(rexit,"0"))
            VFail("RO_SEMANTIC_WITNESS_NONDISCRIMINATING");
          if (!StrEq(wit,"W-CORR-RO-DISCRIM"))
            VFail("RO_SEMANTIC_WITNESS_NONDISCRIMINATING");
        }
        if (StrEq(site,"SITE-VALID-POINTER-OP")) {
          // The PO witness is NOT the RO discriminator.
          if (StrEq(wit,"W-CORR-RO-DISCRIM"))
            VFail("SITE_ISOLATION_OR_WITNESS_MISBIND");
        }
        if (!StrEq(verdict,"PASS"))
          VFail("CAUSAL_RESTORATION_OR_EVIDENCE_MISSING");
      }
    }
    if (nl) line = nl + 1;
    else line = NULL;
  }

  if (seen_ca != 1 || seen_po != 1 || seen_ro != 1)
    VFail("CAUSAL_RESTORATION_OR_EVIDENCE_MISSING");

  VOk();
}

// ---------------------------------------------------------------------------
// MODE 3: ledger
//
// Checks an acceptance ledger and a negative-control ledger for missing,
// duplicate or unknown ids, and for forged PASS rows.
//
// The acceptance ledger TSV has a header and one row per acceptance id.
// The negative-control ledger TSV has one row per control id.
//
// The expected id sets are the ACT's frozen ones:
//   AC01 .. AC28
//   NC01 .. NC12
//
// A row whose status is PASS but which carries no evidence path is a
// FORGED PASS.
// ---------------------------------------------------------------------------

public U0 CheckIdSet(U8 *path, U8 *prefix, I32 expected_count, I32 want_pass, U8 *fail_reason)
{
  I64 size = 0;
  U8 *body = FileRead(path, &size);
  if (body == NULL) VFail(fail_reason);

  U8 seen[64][64];
  I32 nseen = 0;
  I64 prefix_len = StrLen(prefix);

  U8 *line = body;
  while (line != NULL && *line) {
    U8 *nl = strchr(line,'\n');
    if (nl) *nl = 0;
    if (line[0] != '#' && line[0] != 0) {
      U8 fields[MAXF][512];
      I32 nf = SplitTsv(line, fields, MAXF);
      I64 idlen = StrLen(fields[0]);
      if (nf >= 1 && idlen == prefix_len + 2 &&
          StrNCmp(fields[0], prefix, prefix_len) == 0) {
        U8 *id = fields[0];
        for (I32 i = 0; i < nseen; i++)
          if (StrEq(seen[i],id)) VFail(fail_reason);
        if (nseen < 64) { MemCpy(seen[nseen],id,StrLen(id)+1); nseen++; }

        // The id must be EXACTLY the expected one: the prefix followed
        // by the two-digit ordinal in 1..expected_count. An unknown id
        // (AC29 for a 28-id set) is rejected here, so a count-only
        // check cannot let an unknown id stand in for a missing one.
        I32 ord = (fields[0][prefix_len] - '0') * 10
                + (fields[0][prefix_len+1] - '0');
        if (ord < 1 || ord > expected_count) VFail(fail_reason);

        if (want_pass && nf >= 2) {
          // The status column is searched BY NAME, never by position,
          // so a reordered ledger cannot silently change the meaning of
          // a row.
          Bool has_pass = FALSE;
          Bool has_evidence = FALSE;
          for (I32 i = 1; i < nf; i++) {
            if (StrEq(fields[i],"PASS")) has_pass = TRUE;
            if (StrNCmp(fields[i],"evidence/",9) == 0) has_evidence = TRUE;
          }
          if (has_pass && !has_evidence) VFail(fail_reason);
        }
      }
    }
    if (nl) line = nl + 1;
    else line = NULL;
  }

  if (nseen != expected_count) VFail(fail_reason);

  // Every expected id must be PRESENT. Together with the ordinal
  // check above, this closes the set exactly: a missing id, a
  // duplicated id, an unknown id and a wrong total are all rejected.
  for (I32 ord = 1; ord <= expected_count; ord++) {
    U8 want[64];
    MemCpy(want, prefix, prefix_len);
    if (ord < 10) {
      want[prefix_len] = '0';
      want[prefix_len+1] = '0' + ord;
    } else {
      want[prefix_len] = '0' + (ord / 10);
      want[prefix_len+1] = '0' + (ord % 10);
    }
    want[prefix_len+2] = 0;
    Bool found = FALSE;
    for (I32 i = 0; i < nseen; i++) {
      if (StrEq(seen[i],want)) { found = TRUE; break; }
    }
    if (!found) VFail(fail_reason);
  }
}

public U0 ModeLedger(U8 *ac_path, U8 *nc_path)
{
  CheckIdSet(ac_path, "AC", 28, 1, "LEDGER_OR_TERMINALITY_FALSE_PASS");
  CheckIdSet(nc_path, "NC", 12, 0, "LEDGER_OR_TERMINALITY_FALSE_PASS");
  VOk();
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// MODE 0: sha <file>
//
// Prints the SHA-256 of a file. This mode exists so that the
// verifier's OWN digest implementation can be checked against an
// independent tool (shasum / sha256sum) on the same bytes. A verifier
// that hashes wrongly would otherwise be able to certify a wrong
// digest.
// ---------------------------------------------------------------------------

public U0 ModeSha(U8 *path)
{
  U8 digest[80];
  if (!ShaFile(path, digest)) VFail("EVIDENCE_FILE_MISSING");
  VLine("SHA256=%s",digest,NULL,NULL);
  VOk();
}

// ---------------------------------------------------------------------------

public I32 Main(I64 argc, U8 **argv)
{
  if (argc < 3) VFail("USAGE");
  U8 *mode = argv[1];
  if (StrEq(mode,"sha")) {
    ModeSha(argv[2]);
  } else if (StrEq(mode,"historical-ro")) {
    ModeHistoricalRo(argv[2]);
  } else if (StrEq(mode,"join")) {
    ModeJoin(argv[2]);
  } else if (StrEq(mode,"ledger")) {
    if (argc < 4) VFail("USAGE");
    ModeLedger(argv[2],argv[3]);
  } else {
    VFail("UNKNOWN_MODE");
  }
  return 0;
}
