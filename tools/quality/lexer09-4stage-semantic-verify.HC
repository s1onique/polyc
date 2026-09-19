// tools/quality/lexer09-4stage-semantic-verify.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 C2 IMPL.
//
// PolyC-native 4-generation production semantic verifier.
//
// Compares the BUILD_LABEL-stripped semantic outputs of G0..G3
// pairwise using ObjectsByteEqual. Outputs include per-fixture
// and per-pair results.
//
// USAGE:
//   build/lexer09-4stage-semantic-verify <sem.g0> <sem.g1> <sem.g2> <sem.g3> [mutated]

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

I64 MemCmp(U8 *a, U8 *b, I64 n)
{
  for (I64 i = 0; i < n; i = i + 1) {
    U8 ba = a[i];
    U8 bb = b[i];
    if (ba != bb) {
      if (ba < bb) return -1;
      return 1;
    }
  }
  return 0;
}

U0 ObjectsByteEqual(U8 *a, I64 asz, U8 *b, I64 bsz, Bool *out)
{
  if (asz != bsz) { *out = FALSE; return; }
  if (asz == 0)   { *out = TRUE;  return; }
  *out = (MemCmp(a, b, asz) == 0);
}

I64 StripBuildLabel(U8 *buf, I64 len)
{
  // Strip the BUILD_LABEL=... line in-place.
  U8 *p = buf;
  U8 *line_start = p;
  I64 i = 0;
  while (i < len) {
    // find line end
    U8 *eol = p;
    while (eol < buf + len && *eol != '\n') eol = eol + 1;
    if (eol == buf + len) break;
    // check if this line starts with "BUILD_LABEL="
    if (eol - p >= 13 &&
        p[0]=='B' && p[1]=='U' && p[2]=='I' && p[3]=='L' &&
        p[4]=='D' && p[5]=='_' && p[6]=='L' && p[7]=='A' &&
        p[8]=='B' && p[9]=='E' && p[10]=='L' && p[11]=='=') {
      // shift everything after eol+1 left by (eol+1-p)
      U8 *src = eol + 1;
      U8 *dst = line_start;
      I64 move_len = (buf + len) - src;
      for (I64 j = 0; j < move_len; j = j + 1) dst[j] = src[j];
      len = len - (src - line_start);
      // stay at line_start
      p = line_start;
    } else {
      line_start = eol + 1;
      p = line_start;
    }
    i = (p - buf);
  }
  return len;
}

I64 main(I64 argc, U8 **argv)
{
  if (argc < 5 || argc > 6) {
    "SEMANTIC_VERIFIER_USAGE: <sem.g0> <sem.g1> <sem.g2> <sem.g3> [mutated]\n";
    return 2;
  }

  U8 *files[5];
  I64 nfiles = 0;
  for (I64 i = 1; i < argc; i = i + 1) {
    files[nfiles] = argv[i];
    nfiles = nfiles + 1;
  }

  U8 *raw[5];
  I64 rawsz[5];
  U8 *stripped[5];
  I64 stripsz[5];

  for (I64 i = 0; i < nfiles; i = i + 1) {
    rawsz[i] = 0;
    raw[i] = FileRead(files[i], &rawsz[i]);
    if (raw[i] == NULL || rawsz[i] == 0) {
      "SEMANTIC_VERIFIER_RC=2 reason=missing-or-empty file=%s\n", files[i];
      if (raw[i]) Free(raw[i]);
      return 2;
    }
    // Make a copy for stripping
    stripped[i] = MAlloc(rawsz[i] + 1);
    if (stripped[i] == NULL) {
      "SEMANTIC_VERIFIER_RC=2 reason=alloc-failed\n";
      return 2;
    }
    for (I64 j = 0; j < rawsz[i]; j = j + 1) stripped[i][j] = raw[i][j];
    stripsz[i] = rawsz[i];
    stripsz[i] = StripBuildLabel(stripped[i], stripsz[i]);
    "FILE[%d] path=%s raw_size=%d stripped_size=%d\n",
      i, files[i], rawsz[i], stripsz[i];
  }

  U8 *tags[6];
  tags[0] = "G0_G1"; tags[1] = "G0_G2"; tags[2] = "G0_G3";
  tags[3] = "G1_G2"; tags[4] = "G1_G3"; tags[5] = "G2_G3";
  I64 pa[6];
  pa[0] = 0; pa[1] = 0; pa[2] = 0; pa[3] = 1; pa[4] = 1; pa[5] = 2;
  I64 pb[6];
  pb[0] = 1; pb[1] = 2; pb[2] = 3; pb[3] = 2; pb[4] = 3; pb[5] = 3;
  I64 pair_pass = 0;
  I64 pair_fail = 0;
  for (I64 k = 0; k < 6; k = k + 1) {
    Bool eq;
    ObjectsByteEqual(stripped[pa[k]], stripsz[pa[k]],
                     stripped[pb[k]], stripsz[pb[k]], &eq);
    if (eq) {
      "SEMANTIC_PAIR %s file_i=%d file_j=%d equal=YES\n",
        tags[k], pa[k], pb[k];
      pair_pass = pair_pass + 1;
    } else {
      "SEMANTIC_PAIR %s file_i=%d file_j=%d equal=NO\n",
        tags[k], pa[k], pb[k];
      pair_fail = pair_fail + 1;
    }
  }

  if (nfiles == 5) {
    Bool eq;
    ObjectsByteEqual(stripped[3], stripsz[3], stripped[4], stripsz[4], &eq);
    if (eq) {
      "SEMANTIC_NEGATIVE_CONTROL=FAIL reason=mutated-equals-pristine\n";
      for (I64 i = 0; i < nfiles; i = i + 1) { Free(raw[i]); Free(stripped[i]); }
      return 1;
    }
    "SEMANTIC_NEGATIVE_CONTROL=PASS\n";
    "FIXTURE_DIVERGENCE_COUNT=1\n";
    "SEMANTIC_VERIFIER_RC=1 verdict=NEGATIVE_CONTROL_DETECTED_MISMATCH\n";
    for (I64 i = 0; i < nfiles; i = i + 1) { Free(raw[i]); Free(stripped[i]); }
    return 1;
  }

  for (I64 i = 0; i < nfiles; i = i + 1) { Free(raw[i]); Free(stripped[i]); }

  "SEMANTIC_PAIR_PASS=%d\n", pair_pass;
  "SEMANTIC_PAIR_FAIL=%d\n", pair_fail;
  if (pair_fail == 0) {
    "FIXTURE_DIVERGENCE_COUNT=0\n";
    "SEMANTIC_VERIFIER_RC=0 verdict=PASS\n";
    return 0;
  }
  "FIXTURE_DIVERGENCE_COUNT>=1\n";
  "SEMANTIC_VERIFIER_RC=1 verdict=FAIL\n";
  return 1;
}
