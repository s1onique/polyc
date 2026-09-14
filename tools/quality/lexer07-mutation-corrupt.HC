// tools/quality/lexer07-mutation-corrupt.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C2 IMPL.
//
// AC06 mutation experiment: corrupts one byte in a
// TEMPORARY COPY of a stage0-historical fallback .o file,
// computes SHA-256 of the original (canonical) and the
// corrupted copy, and emits a deterministic verdict.
//
// The canonical historical object in build/b02-corpus-A/
// is NEVER mutated. This binary operates only on a /tmp/
// copy. The driver (AC06 driver script) then invokes the
// independent verifier (lexer07-proof-verify.HC) against
// the resulting evidence and asserts verifier_rc != 0.
//
// Pipeline executed by THIS binary:
//   1. read canonical object at
//        build/b02-corpus-A/<idx>_<stem>.o
//   2. compute canonical_sha via ./build/lexer07-sha256 --file;
//   3. flip one byte in a /tmp/ copy at offset src_size/2;
//   4. compute corrupted_sha via ./build/lexer07-sha256 --file;
//   5. emit CANONICAL_SHA / CORRUPTED_SHA / MISMATCH tokens;
//   6. exit 0.
//
// Usage:
//   build/lexer07-mutation-corrupt <idx> <stem> <out_dir>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

extern "c" Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags);

U0 MkDirp(U8 *path)
{
  I64 n = StrLen(path);
  U8 *tmp = MAlloc(n + 2);
  MemCpy(tmp, path, n + 1);
  I64 i = 0;
  if (tmp[0] == '/') i = 1;
  while (i < n) {
    while (i < n && tmp[i] != '/') i = i + 1;
    if (i < n) {
      tmp[i] = 0;
      MkDir(tmp, 0x1FF);
      tmp[i] = '/';
      i = i + 1;
    }
  }
  MkDir(tmp, 0x1FF);
  Free(tmp);
}

// Inline memcmp (same rationale as in the broad-corpus tool).
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

// Run ./build/lexer07-sha256 --file <path> and capture
// the printed hex digest into out_hex (size 65). Returns
// rc of the subprocess.
I64 Sha256File(U8 *path, U8 *out_hex)
{
  U8 *args[4];
  args[0] = "./build/lexer07-sha256";
  args[1] = "--file";
  args[2] = path;
  args[3] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture("./build/lexer07-sha256", args, &out, &err);
  if (rc != 0) {
    if (out) Free(out);
    if (err) Free(err);
    return rc;
  }
  if (out == NULL) {
    if (err) Free(err);
    return 2;
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
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 4) {
    "MUTATION_CORRUPT usage: %s <idx> <stem> <out_dir>\n", argv[0];
    return 1;
  }
  U8 *idx = argv[1];
  U8 *stem = argv[2];
  U8 *outdir = argv[3];
  MkDirp(outdir);

  U8 *src_path = StrPrint(NULL, "build/b02-corpus-A/%s_%s.o", idx, stem);
  I64 src_size = 0;
  U8 *src = FileRead(src_path, &src_size);
  if (src == NULL) {
    "MUTATION_CORRUPT cannot-read src=%s\n", src_path;
    return 2;
  }

  // Compute SHA of canonical (read-only).
  U8 canonical_sha[65];
  if (Sha256File(src_path, canonical_sha) != 0) {
    Free(src);
    "MUTATION_CORRUPT cannot-sha256 src=%s\n", src_path;
    return 3;
  }
  "MUTATION_CORRUPT CANONICAL_SHA=%s src=%s size=%d\n",
    canonical_sha, src_path, src_size;

  // Flip one byte in a /tmp/ copy at offset src_size/2.
  I64 mid = src_size / 2;
  src[mid] = src[mid] ^ 0x01;
  U8 *dst_path = StrPrint(NULL, "%s/%s_%s.corrupt.o", outdir, idx, stem);
  if (!FileWrite(dst_path, src, src_size, 0x0202)) {
    Free(src);
    "MUTATION_CORRUPT cannot-write dst=%s\n", dst_path;
    return 4;
  }
  "MUTATION_CORRUPT CORRUPT_PATH=%s size=%d flipped_byte_offset=%d\n",
    dst_path, src_size, mid;

  // Compute SHA of corrupted copy.
  U8 corrupted_sha[65];
  if (Sha256File(dst_path, corrupted_sha) != 0) {
    Free(src);
    "MUTATION_CORRUPT cannot-sha256 dst=%s\n", dst_path;
    return 5;
  }
  "MUTATION_CORRUPT CORRUPTED_SHA=%s\n", corrupted_sha;

  // Compare.
  if (MemCmp(canonical_sha, corrupted_sha, 64) != 0) {
    "MUTATION_CORRUPT MISMATCH=YES\n";
  } else {
    "MUTATION_CORRUPT MISMATCH=NO\n";
    Free(src);
    return 6;
  }
  "MUTATION_CORRUPT EXPERIMENT=PASS\n";
  Free(src);
  return 0;
}