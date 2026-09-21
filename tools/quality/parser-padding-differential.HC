// tools/quality/parser-padding-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
//
// PolyC-native direct differential verifier for CalcPadding.
//
// Streams the fixture file row by row (no full-file row materialization)
// to keep the HC stack frame small. Each row is parsed, both functions
// are called, and a pass/fail counter is updated in place.
//
// Architecture (ACT §22):
//   legacy C OracleCalcPadding   <-- tools/quality/parser-padding-oracle-impl.c
//   PolyC BootstrapCalcPadding   <-- tools/bootstrap/selfhost-parser-padding.HC
//   comparison layer             <-- THIS FILE (PolyC, terminal authority)
//
// USAGE:
//   build/parser-padding-differential <fixture.tsv>
//
// Fixture schema: case_id<TAB>classes<TAB>offset<TAB>size<TAB>expected_padding

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 BootstrapCalcPadding(I64 offset, I64 size);
extern "c" I64 OracleCalcPadding(I64 offset, I64 size);

#define LINE_CAP 512

I64 main(I64 argc, U8 **argv)
{
  if (argc != 2) {
    "PARSER_PADDING_DIFF_USAGE: %s <fixture.tsv>\n", argv[0];
    return 2;
  }

  I64 fsz = 0;
  U8 *ftxt = FileRead(argv[1], &fsz);
  if (ftxt == NULL) {
    "PARSER_PADDING_DIFF_RC=2 reason=missing-fixture path=%s\n", argv[1];
    return 2;
  }

  I64 pass = 0;
  I64 fail = 0;
  I64 total = 0;
  I64 first_fail_offset = 0;
  I64 first_fail_size = 0;
  I64 first_fail_poly = 0;
  I64 first_fail_oracle = 0;

  I64 i = 0;
  while (i < fsz) {
    // skip empty lines
    while (i < fsz && (ftxt[i] == '\n' || ftxt[i] == '\r')) i = i + 1;
    if (i >= fsz) break;

    // capture one row
    U8 line[LINE_CAP];
    I64 j = 0;
    while (i < fsz && ftxt[i] != '\n' && ftxt[i] != '\r' && j < LINE_CAP - 1) {
      line[j] = ftxt[i];
      j = j + 1;
      i = i + 1;
    }
    line[j] = 0;

    // skip header
    if (total == 0 && line[0] == 'c' && line[1] == 'a') continue;

    // parse case_id
    U8 *p = line;
    while (*p && *p != '\t') p = p + 1;
    if (*p == '\t') p = p + 1;
    // skip classes
    while (*p && *p != '\t') p = p + 1;
    if (*p == '\t') p = p + 1;
    // parse offset
    I64 off_v = 0;
    I64 neg = 0;
    if (*p == '-') { neg = 1; p = p + 1; }
    while (*p >= '0' && *p <= '9') {
      off_v = off_v * 10 + (*p - '0');
      p = p + 1;
    }
    if (neg) off_v = -off_v;
    if (*p == '\t') p = p + 1;
    // parse size
    I64 sz_v = 0;
    neg = 0;
    if (*p == '-') { neg = 1; p = p + 1; }
    while (*p >= '0' && *p <= '9') {
      sz_v = sz_v * 10 + (*p - '0');
      p = p + 1;
    }
    if (neg) sz_v = -sz_v;

    I64 pc = BootstrapCalcPadding(off_v, sz_v);
    I64 oc = OracleCalcPadding(off_v, sz_v);

    if (pc == oc) {
      pass = pass + 1;
    } else {
      fail = fail + 1;
      if (fail == 1) {
        first_fail_offset = off_v;
        first_fail_size = sz_v;
        first_fail_poly = pc;
        first_fail_oracle = oc;
      }
    }
    total = total + 1;
  }

  Free(ftxt);

  "DIRECT_DIFFERENTIAL_TOTAL=%d\n", total;
  "DIRECT_DIFFERENTIAL_PASS=%d\n", pass;
  "DIRECT_DIFFERENTIAL_FAIL=%d\n", fail;
  if (fail) {
    "first_fail_offset=%d\n", first_fail_offset;
    "first_fail_size=%d\n", first_fail_size;
    "first_fail_poly=%d\n", first_fail_poly;
    "first_fail_oracle=%d\n", first_fail_oracle;
    "STATUS=FAIL\n";
    return 1;
  }
  "STATUS=PASS\n";
  return 0;
}
