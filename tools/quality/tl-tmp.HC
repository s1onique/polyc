#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#define MAX_ROWS 4200
#define NCOL 40
static U8 *FLD[MAX_ROWS * NCOL];
static I64 NFD[MAX_ROWS];
static I64 NROW;
static I64 SplitTabs(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    FLD[base + n] = p; n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}
static I64 Load(U8 *path) {
  I64 sz = 0; U8 *buf = FileRead(path, &sz);
  if (buf == 0) return -1;
  I64 n = 0; U8 *p = buf; U8 *end = buf + sz; I64 first = 1;
  while (p < end && n < MAX_ROWS) {
    U8 *ls = p; while (p < end && *p != '\n') p++;
    U8 *le = p; if (p < end) p++;
    if (le > ls && *(le - 1) == '\r') le--;
    *le = 0;
    if (*ls == 0) continue;
    if (*ls == '#') continue;
    if (first) { first = 0; continue; }
    NFD[n] = SplitTabs(ls, n * NCOL, NCOL); n++;
  }
  NROW = n; return 0;
}
I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) { "ARGC\n"; return 2; }
  I64 rc = Load(argv[1]);
  "LOAD_RC=%d ROWS=%d NF0=%d ID=%s\n", rc, NROW, NFD[0], FLD[0];
  return 0;
}
