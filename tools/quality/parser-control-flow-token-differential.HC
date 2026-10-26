// tools/quality/parser-control-flow-token-differential.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE02 C2 IMPL.
//
// PolyC-native DIRECT DIFFERENTIAL verifier for the control-flow token
// decision.
//
// Streams the fixture file row by row (no full-file row materialization)
// to keep the HC stack frame small. Each row is parsed, both functions
// are called, and a pass/fail counter is updated in place.
//
// Architecture (ACT §7):
//   legacy C OracleValidPostControlFlowToken
//       <-- tools/quality/parser-control-flow-token-oracle-impl.c
//         (which calls the VERBATIM production body copied from
//          src/parser.c:832..864, bound to the LIVE src/lexer.h)
//   PolyC BootstrapValidPostControlFlowToken
//       <-- tools/bootstrap/selfhost-parser-control-flow-token.HC
//   comparison layer
//       <-- THIS FILE (PolyC, terminal authority)
//
// The comparison layer is PolyC. The Oracle is C. The two are compared
// on EVERY row, and the fixture's own `expected` column is checked
// against the oracle as well, so a disagreement between the PolyC
// subject and the production oracle cannot be masked by an equally
// wrong fixture.
//
// USAGE:
//   build/parser-control-flow-token-differential <fixture.tsv>
//
// Fixture schema (the CORRECTED matrix, 42 rows):
//   fixture_id <TAB> partition <TAB> present <TAB> kind <TAB> value
//             <TAB> expected <TAB> rationale <TAB> source_line
//
// `kind` may be decimal or 0x-prefixed hexadecimal.  `value` may be
// decimal, 0x-prefixed hexadecimal, or negative.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value);
extern "c" I64 OracleValidPostControlFlowToken(I64 present, I64 kind, I64 value);

#define LINE_CAP 1024

// Parse a signed decimal-or-hex integer at *pp. Advances *pp past the
// token. Returns 0 on success, 1 on a parse error.
I64 parse_int(U8 **pp, I64 *out)
{
  U8 *p = *pp;
  I64 neg = 0;
  I64 v = 0;
  I64 base = 10;
  I64 digits = 0;

  if (*p == '-') { neg = 1; p = p + 1; }
  else if (*p == '+') { p = p + 1; }

  if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
    base = 16;
    p = p + 2;
    while ((*p >= '0' && *p <= '9') ||
           (*p >= 'a' && *p <= 'f') ||
           (*p >= 'A' && *p <= 'F')) {
      I64 d = 0;
      if (*p >= '0' && *p <= '9') d = *p - '0';
      else if (*p >= 'a' && *p <= 'f') d = *p - 'a' + 10;
      else d = *p - 'A' + 10;
      v = v * base + d;
      p = p + 1;
      digits = digits + 1;
    }
  } else {
    while (*p >= '0' && *p <= '9') {
      v = v * 10 + (*p - '0');
      p = p + 1;
      digits = digits + 1;
    }
  }

  if (digits == 0) return 1;
  if (neg) v = -v;
  *out = v;
  *pp = p;
  return 0;
}

// Advance *pp past the next TAB-separated field.
I64 skip_field(U8 **pp)
{
  U8 *p = *pp;
  while (*p && *p != '\t') p = p + 1;
  if (*p == '\t') p = p + 1;
  *pp = p;
  return 0;
}

I64 main(I64 argc, U8 **argv)
{
  if (argc != 2) {
    "SLICE02_DIFF_USAGE: %s <fixture.tsv>\n", argv[0];
    return 2;
  }

  I64 fsz = 0;
  U8 *ftxt = FileRead(argv[1], &fsz);
  if (ftxt == NULL) {
    "SLICE02_DIFF_RC=2 reason=missing-fixture path=%s\n", argv[1];
    return 2;
  }

  I64 pass = 0;
  I64 fail = 0;
  I64 total = 0;
  I64 parse_errors = 0;
  I64 oracle_vs_expected_mismatch = 0;
  I64 first_fail_present = 0;
  I64 first_fail_kind = 0;
  I64 first_fail_value = 0;
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

    // Skip comment lines and the trailing counter block. Only a line
    // that starts with 'F' followed by a digit is a fixture row.
    if (line[0] != 'F') continue;
    if (line[1] < '0' || line[1] > '9') continue;

    U8 *p = line;
    // fixture_id
    skip_field(&p);
    // partition
    skip_field(&p);
    // present
    I64 present = 0;
    if (parse_int(&p, &present)) { parse_errors = parse_errors + 1; continue; }
    skip_field(&p);
    // kind
    I64 kind = 0;
    if (parse_int(&p, &kind)) { parse_errors = parse_errors + 1; continue; }
    skip_field(&p);
    // value
    I64 value = 0;
    if (parse_int(&p, &value)) { parse_errors = parse_errors + 1; continue; }
    skip_field(&p);
    // expected
    I64 expected = 0;
    if (parse_int(&p, &expected)) { parse_errors = parse_errors + 1; continue; }

    I64 pc = BootstrapValidPostControlFlowToken(present, kind, value);
    I64 oc = OracleValidPostControlFlowToken(present, kind, value);

    // The fixture's own expectation must agree with the production
    // oracle. A row where they disagree is a defect in the FIXTURE,
    // not in the subject, and is counted separately so it cannot be
    // confused with a subject/oracle disagreement.
    if (oc != expected) oracle_vs_expected_mismatch = oracle_vs_expected_mismatch + 1;

    if (pc == oc) {
      pass = pass + 1;
    } else {
      fail = fail + 1;
      if (fail == 1) {
        first_fail_present = present;
        first_fail_kind = kind;
        first_fail_value = value;
        first_fail_poly = pc;
        first_fail_oracle = oc;
      }
    }
    total = total + 1;
  }

  Free(ftxt);

  "SLICE02_DIFFERENTIAL_TOTAL=%d\n", total;
  "SLICE02_DIFFERENTIAL_PASS=%d\n", pass;
  "SLICE02_DIFFERENTIAL_FAIL=%d\n", fail;
  "SLICE02_DIFFERENTIAL_PARSE_ERRORS=%d\n", parse_errors;
  "SLICE02_DIFFERENTIAL_ORACLE_VS_EXPECTED_MISMATCH=%d\n", oracle_vs_expected_mismatch;
  if (fail) {
    "first_fail_present=%d\n", first_fail_present;
    "first_fail_kind=%d\n", first_fail_kind;
    "first_fail_value=%d\n", first_fail_value;
    "first_fail_poly=%d\n", first_fail_poly;
    "first_fail_oracle=%d\n", first_fail_oracle;
  }
  if (fail || parse_errors || oracle_vs_expected_mismatch) {
    "STATUS=FAIL\n";
    return 1;
  }
  "STATUS=PASS\n";
  return 0;
}
