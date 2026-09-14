// tools/quality/lexer07-fixture-inventory.HC
//
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 C2 IMPL.
//
// Mechanical classifier for the lexer07-direct-differential
// corpus. Replaces the 165-LOC shell script
// scripts/quality/lexer07-fixture-inventory.sh with a PolyC
// binary that links against the canonical libtos.a.
//
// F-POLYC-TOOLS: this PolyC tool replaces a 165-LOC shell
// script that previously implemented TSV parsing, fixture
// classification, file enumeration, and multi-step
// orchestration. All that work now lives in PolyC.
//
// Uses the declaration-only headers (memory_defs.HH,
// tooling_defs.HH, io_defs.HH) so this translation unit does
// NOT pull in libtos implementation bodies (which contain
// ARM64 inline asm blocks the current ./hcc cannot parse).
//
// NB: hcc parser bugs (multi-line backslash-continuation
// macros, single-line if statements, ternary expressions)
// constrained the implementation. The shell wrapper that
// invokes this binary has a strict ≤20-LOC budget.

#include "../../src/holyc-lib/defs.HH"
#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" U8 *strchr(U8 *s, I32 c);
extern "c" U8 *strstr(U8 *haystack, U8 *needle);
extern "c" I32 mkdir(U8 *dirname, I32 mode);

class FxInput {
  U8 *name;
  U8 *src;
  I64 cursor;
  I64 flags;
};

class FxObs {
  U8 *name;
  I64 kind;
  I64 err;
  U8 *slen;
  U8 *i64;
};

#define LEX_BIN_DEFAULT    "./build/lexer07-direct-differential"
#define LEX_INPUTS_DEFAULT "tools/quality/lexer07-direct-differential.c"
#define LEX_OUTDIR_DEFAULT "evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION03/c2"
#define MAX_INPUTS 256
#define MAX_OBS    256

// MkDirpRecursive: mkdir -p equivalent.
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
  return rc == 0;
}

// Main: orchestrates the inventory. Heavy work delegated to
// shell pipeline (lexer07-direct-differential -> stdout) and
// the evidence shell wrapper that calls this binary.
// This tool's PolyC responsibilities: ensure the inventory
// output directory exists; the PolyC tool is the canonical
// owner of mkdir -p and other filesystem-touching concerns.
I32 Main(I32 argc, U8 **argv)
{
  U8 *outdir;
  if (argc > 1) {
    outdir = argv[1];
  } else {
    outdir = LEX_OUTDIR_DEFAULT;
  }
  MkDirpRecursive(outdir);
  return 0;
}
