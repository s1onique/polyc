// tools/quality/lexer09-fixedpoint-verify.HC
//
// ACT-POLYC-SELFHOST-LEXER04 C2 IMPL.
//
// Verifier for the 4-generation LEXER09 BootstrapLinkDirective
// component-object fixed point.
//
// Inputs (CLI):
//   <obj0> <obj1> <obj2> <obj3> [mutated-obj]
//
// Behavior:
//   1. Each path must exist and be non-empty.
//   2. Read each file into memory.
//   3. Pairwise MemCmp-based byte equality across the first four.
//   4. SHA-256 per file via ./build/lexer07-sha256 --file.
//   5. Emit structured per-pair and aggregate verdict lines.
//   6. If a 5th path is given, compare it against obj3 (G3)
//      and expect FAIL. This is the negative-control path.
//   7. Refuses to run against a closed-evidence path
//      (anything matching "/CORRECTION0X/c") unless
//      --allow-closed is passed.
//
// Exit code:
//   0  pristine run and all pairwise equalities PASS.
//   1  any pairwise equality FAILed.
//   2  bad usage / missing file / read error.
//   3  a closed-evidence path was targeted without --allow-closed.
//   4  SHA-256 subprocess errored.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

extern "c" U8 *strstr(U8 *haystack, U8 *needle);

#define SHA256_BIN "./build/lexer07-sha256"
#define MAX_FILES 5

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

U8 *ReadFileOrNull(U8 *path, I64 *out_size)
{
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (out_size) *out_size = size;
  return buf;
}

Bool Sha256File(U8 *path, U8 *out_hex)
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
    out_hex[i] = out[i];
    i = i + 1;
  }
  out_hex[i] = 0;
  Free(out);
  if (err) Free(err);
  return i == 64;
}

I64 GuardClosedEvidence(U8 *p, Bool allow_closed)
{
  if (allow_closed) return 0;
  if (strstr(p, "/CORRECTION0") != NULL &&
      strstr(p, "/c") != NULL) return 3;
  return 0;
}

U0 EmitBool(Bool b)
{
  if (b) "YES";
  else   "NO";
}

I32 Main(I32 argc, U8 **argv)
{
  Bool allow_closed = FALSE;
  U8 *files[MAX_FILES];
  I64 nfiles = 0;
  for (I64 i = 1; i < argc; i = i + 1) {
    if (StrNCmp(argv[i], "--allow-closed", 14) == 0) {
      allow_closed = TRUE;
      continue;
    }
    if (nfiles >= MAX_FILES) {
      "FIXEDPOINT_VERIFIER_RC=2 reason=too-many-files\n";
      return 2;
    }
    files[nfiles] = argv[i];
    nfiles = nfiles + 1;
  }

  if (nfiles != 4 && nfiles != 5) {
    "FIXEDPOINT_VERIFIER_USAGE: <obj0> <obj1> <obj2> <obj3> [mutated]\n";
    return 2;
  }

  for (I64 i = 0; i < nfiles; i = i + 1) {
    I64 rc = GuardClosedEvidence(files[i], allow_closed);
    if (rc != 0) {
      "FIXEDPOINT_VERIFIER_RC=%d reason=closed-evidence path=%s\n",
        rc, files[i];
      return rc;
    }
  }

  U8  *bufs[MAX_FILES];
  I64  sizes[MAX_FILES];
  U8  shas[MAX_FILES][65];

  for (I64 i = 0; i < nfiles; i = i + 1) {
    sizes[i] = 0;
    bufs[i] = ReadFileOrNull(files[i], &sizes[i]);
    if (bufs[i] == NULL || sizes[i] == 0) {
      "FIXEDPOINT_VERIFIER_RC=2 reason=missing-or-empty file=%s\n",
        files[i];
      if (bufs[i]) Free(bufs[i]);
      return 2;
    }
    if (!Sha256File(files[i], shas[i])) {
      "FIXEDPOINT_VERIFIER_RC=4 reason=sha256-error file=%s\n",
        files[i];
      Free(bufs[i]);
      return 4;
    }
    "FILE[%d] path=%s size=%d sha256=%s\n",
      i, files[i], sizes[i], shas[i];
  }

  U8 *pair_tags[6] = {"G0_G1", "G0_G2", "G0_G3",
                       "G1_G2", "G1_G3", "G2_G3"};
  I64 pair_a[6]    = {0, 0, 0, 1, 1, 2};
  I64 pair_b[6]    = {1, 2, 3, 2, 3, 3};
  Bool pair_eq[6];

  I64 all_eq = 1;
  for (I64 k = 0; k < 6; k = k + 1) {
    Bool eq = FALSE;
    ObjectsByteEqual(bufs[pair_a[k]], sizes[pair_a[k]],
                     bufs[pair_b[k]], sizes[pair_b[k]], &eq);
    pair_eq[k] = eq;
    "PAIR %s file_i=%d file_j=%d size_a=%d size_b=%d equal=",
      pair_tags[k], pair_a[k], pair_b[k],
      sizes[pair_a[k]], sizes[pair_b[k]];
    EmitBool(eq);
    "\n";
    if (!eq) all_eq = 0;
  }

  if (nfiles == 5) {
    Bool eq = FALSE;
    ObjectsByteEqual(bufs[3], sizes[3], bufs[4], sizes[4], &eq);
    "PAIR G3_VS_MUTATED file_i=3 file_j=4 equal=";
    EmitBool(eq);
    "\n";
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

  if (all_eq) {
    "FIXEDPOINT_VERIFIER_RC=0 verdict=PASS\n";
    "LEXER09_LINK_FIXED_POINT_4_GENERATIONS=PASS\n";
    for (I64 i = 0; i < nfiles; i = i + 1) Free(bufs[i]);
    return 0;
  }

  "FIXEDPOINT_VERIFIER_RC=1 verdict=FAIL\n";
  for (I64 i = 0; i < nfiles; i = i + 1) Free(bufs[i]);
  return 1;
}
