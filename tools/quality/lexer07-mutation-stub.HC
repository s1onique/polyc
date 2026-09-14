// tools/quality/lexer07-mutation-stub.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C2 IMPL.
//
// AC05 stub-generator: returns rc=0 with NO/invalid
// evidence (no corpus-matrix.tsv, no
// corpus-object-provenance.tsv). The independent
// verifier (lexer07-proof-verify.HC) MUST reject this
// stub with non-zero exit.
//
// This binary is invoked by the AC05 driver which spawns
// it in place of the real broad-corpus generator, runs
// the independent verifier against the resulting (empty)
// evidence dir, and asserts verifier_rc != 0.
//
// Pipeline executed by THIS binary:
//   1. mkf evidence dir (clean slate);
//   2. write empty / partial evidence;
//   3. exit 0.
//
// The driver performs the verifier invocation, not this
// binary — that is the architectural seam.
//
// Usage:
//   build/lexer07-mutation-stub <evidence_dir>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

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

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "MUTATION_STUB usage: %s <evidence_dir>\n", argv[0];
    return 1;
  }
  U8 *dir = argv[1];
  MkDirp(dir);
  U8 *empty_matrix =
    "src\tidx\tstem\ts0_rc\ts1_rc\ts2_rc\ts3_rc\t"
    "s0_sha256\ts1_sha256\ts2_sha256\ts3_sha256\tclass\tdiff\n";
  U8 mp[1024];
  I64 odl = StrLen(dir);
  MemCpy(mp, dir, odl); mp[odl] = '/';
  MemCpy(mp + odl + 1, "corpus-matrix.tsv", 18);
  mp[odl + 18] = 0;
  FileWrite(mp, empty_matrix, StrLen(empty_matrix), 0x0202);
  "MUTATION_STUB rc=0 evidence=partial emitted=%s\n", mp;
  return 0;
}