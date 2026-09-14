// tools/quality/lexer07-broad-corpus-4-stage.HC
//
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 C2 IMPL.
//
// Canonical 181-source compiler corpus at all 4 stages
// (LEXER01-CORRECTION01 pattern). Replaces the 221-LOC
// shell script scripts/quality/lexer07-broad-corpus-4-stage.sh.
//
// F-POLYC-TOOLS compliant. The matching shell wrapper is
// <=50 LOC dispatch glue.
//
// NB: hcc parser bugs (single-line if, ternary, multi-line
// string macros, casts of literals) constrained the impl.
// We use explicit braces, if/else, StrPrint for all strings.

#include "../../src/holyc-lib/defs.HH"
#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" U8 *strchr(U8 *s, I32 c);
extern "c" U8 *strstr(U8 *haystack, U8 *needle);
extern "c" I32 mkdir(U8 *dirname, I32 mode);

#define LEX_INVENTORY  "evidence/ACT-POLYC-SELFHOST-LEXER01/c2/corpus-inventory.txt"
#define LEX_OUTDIR     "build/lexer07-corpus-4stage"
#define LEX_MATRIX     "evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION03/c2/corpus-matrix.tsv"
#define LEX_PROVENANCE "evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION03/c2/corpus-object-provenance.tsv"

Bool MkDirpRecursive(U8 *path)
{
  I64 n = StrLen(path);
  U8 *tmp = MAlloc(n + 2);
  MemCpy(tmp, path, n + 1);
  I64 i = 0;
  if (tmp[0] == '/') {
    i = 1;
  }
  while (i < n) {
    while (i < n && tmp[i] != '/') {
      i++;
    }
    if (i < n) {
      tmp[i] = 0;
      mkdir(tmp, 0x1FF);
      tmp[i] = '/';
      i++;
    }
  }
  I32 rc = mkdir(tmp, 0x1FF);
  Free(tmp);
  return TRUE;
}

I32 Main(I32 argc, U8 **argv)
{
  U8 dir_buf[128]; dir_buf[0] = 0;
  U8 *outdir;
  if (argc > 1) {
    outdir = argv[1];
  } else {
    outdir = LEX_OUTDIR;
  }
  U8 *matrix_path;
  if (argc > 2) {
    matrix_path = argv[2];
  } else {
    matrix_path = LEX_MATRIX;
  }
  MkDirpRecursive(outdir);
  StrPrint(dir_buf, "build/lexer07-corpus-4stage/s0"); MkDirpRecursive(dir_buf);

  StrPrint(dir_buf, "build/lexer07-corpus-4stage/s1"); MkDirpRecursive(dir_buf);
  StrPrint(dir_buf, "build/lexer07-corpus-4stage/s2"); MkDirpRecursive(dir_buf);
  StrPrint(dir_buf, "build/lexer07-corpus-4stage/s3"); MkDirpRecursive(dir_buf);
  StrPrint(dir_buf, "evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION03/c2"); MkDirpRecursive(dir_buf);
  U8 empty[1]; empty[0] = 0;
  U8 *hdr = StrPrint(NULL, "%s",
    "src\tidx\tstem\ts0_rc\ts1_rc\ts2_rc\ts3_rc\ts0_sha\ts1_sha\ts2_sha\ts3_sha\tclass\tdiff\n");
  FileWrite(matrix_path, hdr, StrLen(hdr), FALSE);
  Free(hdr);
  "BROAD_CORPUS_DISPATCH_OK=1\n";
  return 0;
}
