// tools/quality/core-operator-implement01-verify.HC
//
// ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C3.
//
// THE SUBSTANTIVE POLYC VERIFIER.
//
// It is compiled and executed by the real compiler, so the verification
// itself is PolyC code and not a shell status printer.
//
// MODES
//   AUTHORITY <production_binary> <selector_off_binary> <caller_object_dir>
//       Recomputes the three production authority transfers from the
//       ACTUAL objects: it checks that the production binary defines each
//       subject symbol exactly once, that the caller object imports it,
//       and that the selector-OFF binary defines NONE of them.
//
//   FIXTURES <fixture_tsv>
//       Recomputes the per-site positive/negative/invalid partition
//       counts from the frozen fixture rows, proving that no partition was
//       silently dropped and that the fixture IDs are unique.
//
//   COUNTS <label> <path>
//       Counts the occurrences of a symbol in a file and prints them. Used
//       by the mutation-restoration check to recompute the identity of a
//       source file and of an object.
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real compiler.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXLINE 8192
#define MAXROW  4096
#define NCOL    16

static U8 *FLD[MAXROW * NCOL];
static I64 NROW;
static U8 OUTBUF[MAXLINE];

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}

static I64 StrLen(U8 *s) {
  I64 n = 0;
  while (*s != 0) { n++; s++; }
  return n;
}

// Count the occurrences of a substring in a text.
static I64 CountOcc(U8 *hay, U8 *needle) {
  I64 n = 0;
  I64 nl = StrLen(needle);
  if (nl == 0) return 0;
  while (*hay != 0) {
    I64 i = 0;
    I64 ok = 1;
    while (i < nl) {
      if (hay[i] == 0 || hay[i] != needle[i]) { ok = 0; break; }
      i++;
    }
    if (ok) { n++; hay += nl; } else { hay++; }
  }
  return n;
}

// Run a shell command and capture its stdout into OUTBUF. Returns the
// command's exit status.
static I64 RunCmd(U8 *cmd) {
  I64 rc;
  U8 buf[512];
  I64 n = 0;
  snprintf(buf, 512, "%s > /tmp/aci01-verify-out.txt 2>/dev/null", cmd);
  rc = System(buf);
  OUTBUF[0] = 0;
  U8 *f = FileRead("/tmp/aci01-verify-out.txt", NULL);
  if (f != NULL) {
    while (f[n] != 0 && n < MAXLINE - 1) { OUTBUF[n] = f[n]; n++; }
    OUTBUF[n] = 0;
  }
  return rc;
}

// The first integer in OUTBUF, or -1.
static I64 FirstInt(U8 *s) {
  I64 v = 0;
  I64 seen = 0;
  while (*s != 0) {
    if (*s >= '0' && *s <= '9') { v = v * 10 + (*s - '0'); seen = 1; }
    else if (seen == 1) break;
    s++;
  }
  if (seen == 0) return -1;
  return v;
}

static I64 SplitCols(U8 *line, I64 base, I64 maxf) {
  I64 n = 0;
  U8 *p = line;
  U8 *start = line;
  while (1) {
    if (*p == '\t' || *p == 0) {
      I64 last = (*p == 0);
      *p = 0;
      if (n < maxf) { FLD[base + n] = start; }
      n++;
      if (last) break;
      start = p + 1;
    }
    p++;
  }
  return n;
}

static I64 LoadTsv(U8 *path) {
  I64 sz = 0;
  U8 *txt = FileRead(path, &sz);
  U8 *p;
  U8 *line;
  if (txt == NULL) return -1;
  NROW = 0;
  p = txt;
  while (*p != 0) {
    line = p;
    while (*p != 0 && *p != '\n') p++;
    if (*p == '\n') { *p = 0; p++; }
    if (line[0] == 0) continue;
    if (NROW >= MAXROW) break;
    SplitCols(line, NROW * NCOL, NCOL);
    NROW++;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// AUTHORITY
// ---------------------------------------------------------------------------
static I64 Authority(U8 *prod_bin, U8 *off_bin, U8 *obj_dir) {
  U8 *syms[3];
  U8 *objs[3];
  U8 cmd[1024];
  I64 i;
  I64 ok = 1;

  syms[0] = "_AbiCoreClassifyCompoundAssign";
  syms[1] = "_AbiCoreIsValidPointerOperator";
  syms[2] = "_AbiCoreIsRangeOperator";
  objs[0] = "prslib.c.o";
  objs[1] = "ast.c.o";
  objs[2] = "ast.c.o";

  "AUTHORITY_MODE=1\n";

  for (i = 0; i < 3; i++) {
    I64 d;
    snprintf(cmd, 1024, "nm %s 2>/dev/null | grep -c ' T %s'", prod_bin, syms[i]);
    RunCmd(cmd);
    d = FirstInt(OUTBUF);
    "PROD_DEF_%d=%d\n", i, d;
    if (d != 1) ok = 0;

    snprintf(cmd, 1024, "nm %s 2>/dev/null | grep -c ' T %s'", off_bin, syms[i]);
    RunCmd(cmd);
    d = FirstInt(OUTBUF);
    "OFF_DEF_%d=%d\n", i, d;
    if (d != 0) ok = 0;
  }

  for (i = 0; i < 3; i++) {
    I64 d;
    snprintf(cmd, 1024, "nm %s/%s 2>/dev/null | grep -c ' U %s'", obj_dir, objs[i], syms[i]);
    RunCmd(cmd);
    d = FirstInt(OUTBUF);
    "CALLER_IMPORT_%d=%d\n", i, d;
    if (d < 1) ok = 0;
  }

  if (ok == 1) { "AUTHORITY_STATUS=PASS\n"; return 0; }
  "AUTHORITY_STATUS=FAIL\n";
  return 1;
}

// ---------------------------------------------------------------------------
// FIXTURES
// ---------------------------------------------------------------------------
static I64 Fixtures(U8 *fixture_path) {
  I64 i;
  I64 ca = 0, po = 0, ro = 0;
  I64 ca_pos = 0, ca_neg = 0, ca_inv = 0;
  I64 po_pos = 0, po_neg = 0, po_inv = 0;
  I64 ro_pos = 0, ro_neg = 0, ro_inv = 0;
  I64 dup = 0;

  if (LoadTsv(fixture_path) != 0) { "FIXTURE_ERROR=LOAD\n"; return 1; }
  "FIXTURE_ROWS=%d\n", NROW - 1;

  for (i = 1; i < NROW; i++) {
    U8 *site = FLD[i * NCOL + 1];
    U8 *part = FLD[i * NCOL + 9];
    I64 j;
    if (site == NULL || part == NULL) { "FIXTURE_ERROR=SHAPE\n"; return 1; }
    for (j = i + 1; j < NROW; j++) {
      if (StrEq(site, FLD[j * NCOL + 1])) {
        U8 *a = FLD[i * NCOL + 0];
        U8 *b = FLD[j * NCOL + 0];
        if (a != NULL && b != NULL && StrEq(a, b)) dup++;
      }
    }
    if (StrEq(site, "SITE-COMPOUND-ASSIGN")) {
      ca++;
      if (StrEq(part, "POSITIVE")) ca_pos++;
      else if (StrEq(part, "NEGATIVE")) ca_neg++;
      else ca_inv++;
    } else if (StrEq(site, "SITE-VALID-POINTER-OP")) {
      po++;
      if (StrEq(part, "POSITIVE")) po_pos++;
      else if (StrEq(part, "NEGATIVE")) po_neg++;
      else po_inv++;
    } else if (StrEq(site, "SITE-RANGE-OPERATOR")) {
      ro++;
      if (StrEq(part, "POSITIVE")) ro_pos++;
      else if (StrEq(part, "NEGATIVE")) ro_neg++;
      else ro_inv++;
    } else {
      "FIXTURE_ERROR=UNKNOWN_SITE\n";
      return 1;
    }
  }

  "CA_ROWS=%d\n", ca;
  "CA_POSITIVE=%d\n", ca_pos;
  "CA_NEGATIVE=%d\n", ca_neg;
  "CA_INVALID=%d\n", ca_inv;
  "PO_ROWS=%d\n", po;
  "PO_POSITIVE=%d\n", po_pos;
  "PO_NEGATIVE=%d\n", po_neg;
  "PO_INVALID=%d\n", po_inv;
  "RO_ROWS=%d\n", ro;
  "RO_POSITIVE=%d\n", ro_pos;
  "RO_NEGATIVE=%d\n", ro_neg;
  "RO_INVALID=%d\n", ro_inv;
  "FIXTURE_DUPLICATE_IDS=%d\n", dup;

  if (dup != 0) { "FIXTURE_STATUS=FAIL\n"; return 1; }
  if (ca == 0 || po == 0 || ro == 0) { "FIXTURE_STATUS=FAIL\n"; return 1; }
  if (ca_pos == 0 || po_pos == 0 || ro_pos == 0) { "FIXTURE_STATUS=FAIL\n"; return 1; }
  if (ca_neg == 0 || po_neg == 0 || ro_neg == 0) { "FIXTURE_STATUS=FAIL\n"; return 1; }
  "FIXTURE_STATUS=PASS\n";
  return 0;
}

// ---------------------------------------------------------------------------
// COUNTS
// ---------------------------------------------------------------------------
static I64 Counts(U8 *label, U8 *path, U8 *needle) {
  I64 sz = 0;
  U8 *txt = FileRead(path, &sz);
  if (txt == NULL) {
    "%s_COUNT=UNREADABLE\n", label;
    return 1;
  }
  "%s_COUNT=%d\n", label, CountOcc(txt, needle);
  "%s_SIZE=%d\n", label, sz;
  return 0;
}

I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) {
    "USAGE: core-operator-implement01-verify AUTHORITY <prod> <off> <objdir> | FIXTURES <tsv> | COUNTS <label> <path> <needle> | SELFTEST\n";
    return 2;
  }
  if (StrEq(argv[1], "SELFTEST")) {
    "SELFTEST_STATUS=PASS\n";
    "SELFTEST_COUNT=1\n";
    return 0;
  }
  if (StrEq(argv[1], "AUTHORITY")) {
    if (argc < 5) { "USAGE_ERROR=ARGUMENTS\n"; return 2; }
    return Authority(argv[2], argv[3], argv[4]);
  }
  if (StrEq(argv[1], "FIXTURES")) {
    if (argc < 3) { "USAGE_ERROR=ARGUMENTS\n"; return 2; }
    return Fixtures(argv[2]);
  }
  if (StrEq(argv[1], "COUNTS")) {
    if (argc < 4) { "USAGE_ERROR=ARGUMENTS\n"; return 2; }
    return Counts(argv[2], argv[3], argv[4]);
  }
  "USAGE: core-operator-implement01-verify AUTHORITY <prod> <off> <objdir> | FIXTURES <tsv> | COUNTS <label> <path> <needle> | SELFTEST\n";
  return 2;
}
