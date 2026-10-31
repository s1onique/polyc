// tools/quality/core-semantic-bundle-recon03-red.HC
//
// ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03
//
// The ACT-LOCAL PolyC RED detector for this reconnaissance ACT.
//
// It is NOT a general-purpose tool and it does NOT duplicate any
// canonical checker. It implements exactly the five RED detectors that
// the ACT's C0 phase requires, each one REASON-SPECIFIC: a detector
// prints a machine-readable REASON token and returns a nonzero status
// for each distinct failure class, so an adverse control can be shown
// to fire for its OWN reason rather than merely "not green".
//
// The detectors are:
//
//   red1-attribution <subject-file> <recorded-m-poly-ro-sha256>
//        RED 1. Recomputes, from the ACTUAL source bytes, the digest
//        of the file with the AST_BIN_OP_LT case removed from EACH
//        candidate function in turn, and checks which candidate
//        reproduces the recorded M-POLYC-RO digest. The historical
//        record claimed the RANGE site; the digest identity says
//        otherwise. Reason: MUTANT_SOURCE_OBJECT_MISATTRIBUTION.
//
//   red2-history <history-tsv>
//        RED 2. Reads a post-CLOSE history table and rejects a table
//        in which an ordinary post-CLOSE commit changed compiler
//        source, or in which the all-commit count was conflated with
//        the ACT-trailer count. Reason:
//        UNAUTHORIZED_POST_CLOSE_SOURCE_CHANGE /
//        POST_CLOSE_COUNT_CONFLATION.
//
//   red3-migrated <authority-symbol> <candidate-symbol>
//        RED 3. Rejects a candidate that offers an ALREADY PolyC-owned
//        authority as a new C authority. Reason:
//        ALREADY_MIGRATED_EXCLUSION.
//
//   red4-semantic <witness-ledger-tsv>
//        RED 4. Rejects a witness that carries no real
//        compilation-semantic channel (diagnostic-only, dormant, or
//        non-discriminating). Reason:
//        NON_SEMANTIC_OR_VACUOUS_WITNESS.
//
//   red5-graph <graph-ledger-tsv>
//        RED 5. Rejects a claimed graph cut / SCC reduction that rests
//        on an unimplemented ABI sketch or on the unsupported edge
//        E-MUT-0137. Reason: UNPROVEN_GRAPH_CUT.
//
// Every mode prints exactly one FINAL= line: OK or FAIL, and on FAIL
// exactly one REASON= line.
//
// BUILD:
//   $(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -c \
//     tools/quality/core-semantic-bundle-recon03-red.HC \
//     -o build/core-semantic-bundle-recon03-red.o
//   cc build/core-semantic-bundle-recon03-red.o \
//     -L$(TEST_PREFIX)/lib -ltos \
//     -o build/core-semantic-bundle-recon03-red

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

public Bool RedStrEq(U8 *a, U8 *b)
{
  if (a == NULL || b == NULL) return FALSE;
  return StrCmp(a,b) == 0;
}

// ---------------------------------------------------------------------------
// SHA-256 (FIPS 180-4). Implemented here so the detector has no external
// dependency and computes its own digests rather than trusting a recorded
// field.
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

public Bool ShaHexFile(U8 *path, U8 *out)
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

// ShaHexBytes hashes a byte range and writes 64 hex chars + NUL.
public U0 ShaHexBytes(U8 *p, I64 n, U8 *out)
{
  Sha256 s;
  ShaInit(&s);
  ShaUpdate(&s, p, n);
  ShaFinal(&s, out);
}

// ShaSelfTest validates the SHA-256 implementation against the NIST
// FIPS 180-4 test vectors BEFORE any digest is trusted. A detector
// that hashes wrongly must not be able to certify a wrong digest.
public Bool ShaSelfTest(U8 *out)
{
  U8 hex[65];

  // "abc" -> ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
  ShaHexBytes("abc", 3, hex);
  if (StrCmp(hex, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad") != 0)
    return FALSE;

  // the empty string -> e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  ShaHexBytes("", 0, hex);
  if (StrCmp(hex, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") != 0)
    return FALSE;

  // the 56-byte case exercises the padding boundary:
  // "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
  // -> 248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1
  U8 *v2 = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
  ShaHexBytes(v2, 56, hex);
  if (StrCmp(hex, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1") != 0)
    return FALSE;

  // a million 'a' would be slow; the 56-byte boundary plus the
  // empty and 3-byte vectors are sufficient to prove the padding
  // and the length encoding.
  MemCpy(out, hex, 65);
  return TRUE;
}

// ---------------------------------------------------------------------------
// RED 1 -- the historical M-POLYC-RO source/object misattribution.
//
// The detector recomputes the digest of the file with the AST_BIN_OP_LT
// case removed from EACH candidate function in turn. The candidate whose
// digest reproduces the RECORDED M-POLYC-RO digest is the function that
// the recorded experiment physically mutated. If that candidate is not
// the function the record CLAIMS, the record is misattributed.
//
// usage: red1-attribution <subject-file> <recorded-m-poly-ro-sha256>
// ---------------------------------------------------------------------------

// FnSpan finds the DEFINITION of the function whose signature is `sig`
// and returns the byte range [start,end) of that definition.
//
// The signature may also appear inside a COMMENT (the subject file
// documents its own functions in prose), so a comment occurrence is
// skipped. The definition's range starts AT THE SIGNATURE (not at the
// beginning of its line) and ends after the line that carries the
// matching closing brace at column 0.
//
// The exact start/end convention matters: the recorded historical
// mutant digests were produced with this convention, so a detector
// that used a different convention would recompute different digests
// and could not certify the attribution.
public Bool FnSpan(U8 *data, I64 size, U8 *sig, I64 *out_start, I64 *out_end)
{
  I64 siglen = StrLen(sig);
  I64 search = 0;
  while (search < size) {
    // find the next occurrence of the signature
    I64 p = -1;
    for (I64 k = search; k + siglen <= size; k++) {
      Bool hit = TRUE;
      for (I64 j = 0; j < siglen; j++) {
        if (data[k + j] != sig[j]) { hit = FALSE; break; }
      }
      if (hit) { p = k; break; }
    }
    if (p < 0) return FALSE;

    // a comment line is not a definition
    I64 ls = p;
    while (ls > 0 && data[ls-1] != '\n') ls--;
    if (data[ls] == '/' && data[ls+1] == '/') {
      search = p + 1;
      continue;
    }

    // the opening brace is on the signature line or on the next line
    I64 brace = p;
    Bool have_brace = FALSE;
    while (brace < size) {
      if (data[brace] == '{') { have_brace = TRUE; break; }
      if (data[brace] == '\n') {
        I64 nl = brace + 1;
        while (nl < size && (data[nl] == ' ' || data[nl] == '\t')) nl++;
        if (nl < size && data[nl] == '{') { brace = nl; have_brace = TRUE; }
        break;
      }
      brace++;
    }
    if (!have_brace) { search = p + 1; continue; }

    // the body ends at the closing brace at column 0
    I64 j = brace;
    while (j < size) {
      if (data[j] == '\n') {
        I64 k = j + 1;
        while (k < size && (data[k] == ' ' || data[k] == '\t')) k++;
        if (k < size && data[k] == '}') {
          I64 e2 = k + 1;
          while (e2 < size && data[e2] != '\n') e2++;
          *out_start = p;
          *out_end = e2;
          return TRUE;
        }
      }
      j++;
    }
    return FALSE;
  }
  return FALSE;
}

// HasTag reports whether the byte range contains the given literal.
public Bool HasTag(U8 *p, I64 n, U8 *tag)
{
  I64 tlen = StrLen(tag);
  if (n < tlen) return FALSE;
  for (I64 k = 0; k + tlen <= n; k++) {
    Bool m = TRUE;
    for (I64 t = 0; t < tlen; t++) {
      if (p[k + t] != tag[t]) { m = FALSE; break; }
    }
    if (m) return TRUE;
  }
  return FALSE;
}

// MutatedDigest removes every line of the definition that carries the
// AST_BIN_OP_LT marker -- the line AND its newline -- and hashes the
// WHOLE resulting file.
//
// The whole-file granularity matters: the recorded historical mutant
// digest is the digest of the WHOLE subject source with the named case
// removed, so the comparison must be made at whole-file granularity.
public Bool MutatedDigest(U8 *data, I64 size, U8 *sig, U8 *out)
{
  I64 s = 0;
  I64 e = 0;
  if (!FnSpan(data, size, sig, &s, &e)) return FALSE;

  Sha256 acc;
  ShaInit(&acc);

  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 linelen = le - i;
    Bool hit = FALSE;
    if (i >= s && i < e && linelen >= 12) {
      hit = HasTag(data + i, linelen, "AST_BIN_OP_LT");
    }
    if (!hit) ShaUpdate(&acc, data + i, linelen + 1);
    i = le + 1;
  }
  ShaFinal(&acc, out);
  return TRUE;
}

public U0 Red1Attribution(U8 *path, U8 *recorded)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("SUBJECT_SOURCE_UNREADABLE");

  U8 ro_hex[65];
  U8 po_hex[65];
  if (!MutatedDigest(data, size, "I64 AbiCoreIsRangeOperator", ro_hex))
    RedFail("CANDIDATE_FUNCTION_NOT_FOUND");
  if (!MutatedDigest(data, size, "I64 AbiCoreIsValidPointerOperator", po_hex))
    RedFail("CANDIDATE_FUNCTION_NOT_FOUND");

  Write(1,"RO_MUTANT_SHA256=",18); Write(1,ro_hex,64); Write(1,"\n",1);
  Write(1,"PO_MUTANT_SHA256=",18); Write(1,po_hex,64); Write(1,"\n",1);
  Write(1,"RECORDED_SHA256=",16); Write(1,recorded,64); Write(1,"\n",1);

  Bool ro_matches = RedStrEq(ro_hex, recorded);
  Bool po_matches = RedStrEq(po_hex, recorded);

  if (po_matches && !ro_matches) {
    // The recorded digest belongs to the POINTER site, not the range
    // site. The historical record is MISATTRIBUTED.
    RedFail("MUTANT_SOURCE_OBJECT_MISATTRIBUTION");
  }
  if (ro_matches && !po_matches) {
    // The record is correct: the digest belongs to the claimed site.
    RedOk();
  }
  RedFail("MUTANT_SOURCE_OBJECT_MISATTRIBUTION");
}

// ---------------------------------------------------------------------------
// RED 2 -- the post-CLOSE history detector.
//
// The history table is a TSV with KEY=VALUE facts followed by a
// descendant table. The detector rejects:
//   * an ordinary post-CLOSE commit whose TOUCHED_PATHS include a
//     production source path (src/**) or a gate -- reason
//     UNAUTHORIZED_POST_CLOSE_SOURCE_CHANGE;
//   * a table that reports POST_CLOSE_ALL_COMMITS as 0 while also
//     carrying descendant rows -- reason POST_CLOSE_COUNT_CONFLATION.
//
// usage: red2-history <history-tsv>
// ---------------------------------------------------------------------------

// FieldAt returns a copy of the nth tab-separated field of the line.
public U0 FieldAt(U8 *data, I64 ls, I64 le, I64 want, U8 *out, I64 cap)
{
  I64 field = 0;
  I64 fs = ls;
  for (I64 k = ls; k <= le; k++) {
    if (k == le || data[k] == '\t') {
      if (field == want) {
        I64 n = k - fs;
        if (n > cap - 1) n = cap - 1;
        MemCpy(out, data + fs, n);
        out[n] = 0;
        return;
      }
      field++;
      fs = k + 1;
    }
  }
  out[0] = 0;
}

public Bool IsHex40(U8 *p)
{
  for (I64 k = 0; k < 40; k++) {
    U8 c = p[k];
    Bool ok = (c>='0'&&c<='9')||(c>='a'&&c<='f');
    if (!ok) return FALSE;
  }
  return TRUE;
}

public U0 Red2History(U8 *path)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("HISTORY_TABLE_UNREADABLE");

  I64 all_commits_zero = 0;
  I64 descendant_rows = 0;

  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;

    if (len > 20) {
      // the KEY=VALUE facts
      U8 line[512];
      I64 n = len;
      if (n > 511) n = 511;
      MemCpy(line, data + i, n);
      line[n] = 0;
      if (StrCmp(line, "POST_CLOSE_ALL_COMMITS=0") == 0) all_commits_zero = 1;

      // a descendant row: it begins with a 40-hex commit id
      if (IsHex40(data + i)) {
        descendant_rows++;
        U8 paths[1024];
        FieldAt(data, i, le, 2, paths, 1024);
        if (HasTag(paths, StrLen(paths), "src/")) {
          RedFail("UNAUTHORIZED_POST_CLOSE_SOURCE_CHANGE");
        }
        if (HasTag(paths, StrLen(paths), "gate-")) {
          RedFail("UNAUTHORIZED_POST_CLOSE_SOURCE_CHANGE");
        }
      }
    }
    i = le + 1;
  }

  if (descendant_rows > 0 && all_commits_zero) {
    RedFail("POST_CLOSE_COUNT_CONFLATION");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// RED 3 -- the already-migrated exclusion.
//
// usage: red3-migrated <live-authority-symbol> <candidate-symbol>
// ---------------------------------------------------------------------------

public U0 Red3Migrated(U8 *live, U8 *candidate)
{
  if (RedStrEq(live, candidate)) {
    RedFail("ALREADY_MIGRATED_EXCLUSION");
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// RED 4 -- the non-semantic / vacuous witness detector.
//
// The witness ledger is a TSV with one row per witness:
//   witness_id <TAB> semantic_channel <TAB> discriminating <TAB> verdict
// The channel must be one of the REAL semantic channels
// (COMPILER_ACCEPTANCE, IR_ASSEMBLY_OBJECT, RUNTIME_BEHAVIOUR); the
// witness must be marked discriminating; and the verdict must be PASS.
// A DIAGNOSTIC_ONLY channel, a DORMANT channel, a non-discriminating
// witness, or a non-PASS verdict is rejected.
//
// usage: red4-semantic <witness-ledger-tsv>
// ---------------------------------------------------------------------------

public U0 Red4Semantic(U8 *path)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("WITNESS_LEDGER_UNREADABLE");

  I64 rows = 0;
  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;
    if (len > 4 && data[i] != '#') {
      U8 chan[64];
      U8 disc[32];
      U8 verd[32];
      FieldAt(data, i, le, 1, chan, 64);
      FieldAt(data, i, le, 2, disc, 32);
      FieldAt(data, i, le, 3, verd, 32);

      // a header row is not a data row
      if (!RedStrEq(chan, "semantic_channel")) {
        rows++;
        Bool real_channel =
          RedStrEq(chan,"COMPILER_ACCEPTANCE") ||
          RedStrEq(chan,"IR_ASSEMBLY_OBJECT") ||
          RedStrEq(chan,"RUNTIME_BEHAVIOUR");
        if (!real_channel) RedFail("NON_SEMANTIC_OR_VACUOUS_WITNESS");
        if (!RedStrEq(disc,"YES")) RedFail("NON_SEMANTIC_OR_VACUOUS_WITNESS");
        if (!RedStrEq(verd,"PASS")) RedFail("NON_SEMANTIC_OR_VACUOUS_WITNESS");
      }
    }
    i = le + 1;
  }
  if (rows == 0) RedFail("NON_SEMANTIC_OR_VACUOUS_WITNESS");
  RedOk();
}

// ---------------------------------------------------------------------------
// RED 5 -- the unproven-graph-cut detector.
//
// The graph ledger is a TSV with one row per claimed cut:
//   cut_edge_id <TAB> src <TAB> dst <TAB> basis <TAB> status
// A cut is accepted only when its basis is EXECUTED_CAUSAL_MUTATION and
// its status is CUT_PROVEN_BY_EXECUTION. A basis of ABI_SKETCH or
// PLANNED_ABI, or the edge id E-MUT-0137, is rejected.
//
// usage: red5-graph <graph-ledger-tsv>
// ---------------------------------------------------------------------------

public U0 Red5Graph(U8 *path)
{
  I64 size = 0;
  U8 *data = FileRead(path, &size);
  if (data == NULL) RedFail("GRAPH_LEDGER_UNREADABLE");

  I64 i = 0;
  while (i < size) {
    I64 le = i;
    while (le < size && data[le] != '\n') le++;
    I64 len = le - i;
    if (len > 4 && data[i] != '#') {
      U8 id[48];
      U8 basis[64];
      U8 status[64];
      FieldAt(data, i, le, 0, id, 48);
      FieldAt(data, i, le, 3, basis, 64);
      FieldAt(data, i, le, 4, status, 64);

      if (!RedStrEq(id, "cut_edge_id")) {
        if (RedStrEq(id, "E-MUT-0137")) {
          RedFail("UNPROVEN_GRAPH_CUT");
        }
        if (!RedStrEq(basis, "EXECUTED_CAUSAL_MUTATION")) {
          RedFail("UNPROVEN_GRAPH_CUT");
        }
        if (!RedStrEq(status, "CUT_PROVEN_BY_EXECUTION")) {
          RedFail("UNPROVEN_GRAPH_CUT");
        }
      }
    }
    i = le + 1;
  }
  RedOk();
}

// ---------------------------------------------------------------------------
// Dispatch.
// ---------------------------------------------------------------------------

public U0 Main(I64 argc, I8 **argv)
{
  if (argc < 2) {
    Write(1,"FINAL=FAIL\n",11);
    Write(1,"REASON=USAGE\n",13);
    Exit(2);
  }

  U8 *mode = argv[1];

  if (StrCmp(mode, "sha-selftest") == 0) {
    U8 hex[65];
    if (!ShaSelfTest(hex)) {
      RedFail("SHA256_SELFTEST_FAILED");
    }
    Write(1,"SHA_SELFTEST=PASS\n",18);
    RedOk();
  }

  if (StrCmp(mode, "red1-attribution") == 0) {
    if (argc < 4) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    // The digest implementation is validated FIRST, so that a detector
    // which hashes wrongly cannot certify a wrong attribution.
    U8 hex[65];
    if (!ShaSelfTest(hex)) RedFail("SHA256_SELFTEST_FAILED");
    Red1Attribution(argv[2], argv[3]);
    return;
  }
  if (StrCmp(mode, "red2-history") == 0) {
    if (argc < 3) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    Red2History(argv[2]);
    return;
  }
  if (StrCmp(mode, "red3-migrated") == 0) {
    if (argc < 4) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    Red3Migrated(argv[2], argv[3]);
    return;
  }
  if (StrCmp(mode, "red4-semantic") == 0) {
    if (argc < 3) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    Red4Semantic(argv[2]);
    return;
  }
  if (StrCmp(mode, "red5-graph") == 0) {
    if (argc < 3) { Write(1,"REASON=USAGE\n",13); Exit(2); }
    Red5Graph(argv[2]);
    return;
  }

  Write(1,"FINAL=FAIL\n",11);
  Write(1,"REASON=UNKNOWN_MODE\n",19);
  Exit(2);
}
