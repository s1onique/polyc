// tools/quality/lexer09-4stage-fixedpoint-verify.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 C2 IMPL.
//
// PolyC-native 4-generation component fixed-point verifier.
// Replaces the deprecated tools/quality/lexer09-fixedpoint-verify.c
// (which was a substantive C verifier) under F-POLYC-TOOLS.
//
// Algorithm:
//   1. Read each of the 4 (or 5) input object files into memory.
//   2. Compute SHA-256 via subprocess: ./build/lexer07-sha256 --file <path>
//      (the PolyC-owned SHA-256 implementation:
//       tools/quality/lexer07-sha256.HC).
//   3. Compare each pair using ObjectsByteEqual (MemCmp-based).
//   4. Emit verifier output line-by-line matching the historical
//      C verifier's output schema so the Makefile recipes remain
//      stable:
//        FILE[i] path=... size=... sha256=...
//        PAIR Gx_Gy file_i=... file_j=... size_a=... size_b=... equal=YES|NO
//        FIXEDPOINT_VERIFIER_RC=0 verdict=PASS
//        LEXER09_LINK_FIXED_POINT_4_GENERATIONS=PASS
//      (or RC=1/2/3/4 + reason codes for the various failure modes).
//   5. If 5 files are passed, the 5th is treated as a mutation
//      and the verifier exits 1 if the mutation equals a pristine
//      file, or reports BYTE_MISMATCH_DETECTED=YES + RC=1.
//
// All SHA computation is delegated to the PolyC-owned
// ./build/lexer07-sha256 binary (tools/quality/lexer07-sha256.HC).

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

#define SHA256_BIN "./build/lexer07-sha256"

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

U0 EmitPairEq(U8 *tag, I64 fi, I64 fj, I64 sa, I64 sb, Bool eq)
{
  if (eq) {
    "PAIR %s file_i=%d file_j=%d size_a=%d size_b=%d equal=YES\n",
      tag, fi, fj, sa, sb;
  } else {
    "PAIR %s file_i=%d file_j=%d size_a=%d size_b=%d equal=NO\n",
      tag, fi, fj, sa, sb;
  }
}

// SHA-256 via subprocess to the PolyC-owned ./build/lexer07-sha256.
Bool GetFileSHA256(U8 *path, U8 *out_hex64)
{
  U8 *args[4];
  args[0] = SHA256_BIN;
  args[1] = "--file";
  args[2] = path;
  args[3] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(SHA256_BIN, args, &out, &err);
  if (rc != 0) {
    if (out) Free(out);
    if (err) Free(err);
    return FALSE;
  }
  if (out == NULL) {
    if (err) Free(err);
    return FALSE;
  }
  I64 i = 0;
  while (i < 64 && out[i] != 0 && out[i] != '\n' &&
         out[i] != ' ' && out[i] != '\r') {
    out_hex64[i] = out[i];
    i = i + 1;
  }
  out_hex64[i] = 0;
  if (out) Free(out);
  if (err) Free(err);
  return (i == 64);
}

I64 main(I64 argc, U8 **argv)
{
  if (argc < 5 || argc > 6) {
    "FIXEDPOINT_VERIFIER_USAGE: <obj0> <obj1> <obj2> <obj3> [mutated]\n";
    return 2;
  }

  U8 *files[5];
  I64 nfiles = 0;
  for (I64 i = 1; i < argc; i = i + 1) {
    files[nfiles] = argv[i];
    nfiles = nfiles + 1;
  }

  U8 *bufs[5];
  I64 sizes[5];
  U8 shas[5][65];

  for (I64 i = 0; i < nfiles; i = i + 1) {
    sizes[i] = 0;
    bufs[i] = FileRead(files[i], &sizes[i]);
    if (bufs[i] == NULL || sizes[i] == 0) {
      "FIXEDPOINT_VERIFIER_RC=2 reason=missing-or-empty file=%s\n", files[i];
      if (bufs[i]) Free(bufs[i]);
      return 2;
    }
    if (!GetFileSHA256(files[i], shas[i])) {
      "FIXEDPOINT_VERIFIER_RC=4 reason=sha256-error file=%s\n", files[i];
      Free(bufs[i]);
      return 4;
    }
    shas[i][64] = 0;
    "FILE[%d] path=%s size=%d sha256=%s\n", i, files[i], sizes[i], shas[i];
  }

  U8 *tags[6];
  tags[0] = "G0_G1"; tags[1] = "G0_G2"; tags[2] = "G0_G3";
  tags[3] = "G1_G2"; tags[4] = "G1_G3"; tags[5] = "G2_G3";
  I64 pa[6];
  pa[0] = 0; pa[1] = 0; pa[2] = 0; pa[3] = 1; pa[4] = 1; pa[5] = 2;
  I64 pb[6];
  pb[0] = 1; pb[1] = 2; pb[2] = 3; pb[3] = 2; pb[4] = 3; pb[5] = 3;
  Bool all_eq = TRUE;
  for (I64 k = 0; k < 6; k = k + 1) {
    Bool eq;
    ObjectsByteEqual(bufs[pa[k]], sizes[pa[k]],
                     bufs[pb[k]], sizes[pb[k]], &eq);
    EmitPairEq(tags[k], pa[k], pb[k], sizes[pa[k]], sizes[pb[k]], eq);
    if (!eq) all_eq = FALSE;
  }

  if (nfiles == 5) {
    Bool eq;
    ObjectsByteEqual(bufs[3], sizes[3], bufs[4], sizes[4], &eq);
    EmitPairEq("G3_VS_MUTATED", 3, 4, sizes[3], sizes[4], eq);
    if (eq) {
      "FIXEDPOINT_VERIFIER_RC=1 reason=mutated-equals-pristine\n";
      "NEGATIVE_CONTROL=FAIL reason=verifier-accepted-mutation\n";
      for (I64 i = 0; i < nfiles; i = i + 1) Free(bufs[i]);
      return 1;
    }
    "BYTE_MISMATCH_DETECTED=YES\n";
    "NEGATIVE_CONTROL=PASS\n";
    "FIXEDPOINT_VERIFIER_RC=1 verdict=NEGATIVE_CONTROL_DETECTED_MISMATCH\n";
    for (I64 i = 0; i < nfiles; i = i + 1) Free(bufs[i]);
    return 1;
  }

  for (I64 i = 0; i < nfiles; i = i + 1) Free(bufs[i]);

  if (all_eq) {
    "FIXEDPOINT_VERIFIER_RC=0 verdict=PASS\n";
    "LEXER09_LINK_FIXED_POINT_4_GENERATIONS=PASS\n";
    return 0;
  }
  "FIXEDPOINT_VERIFIER_RC=1 verdict=FAIL\n";
  return 1;
}
