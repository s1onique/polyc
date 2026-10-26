// tools/quality/parser-control-flow-token-int-bounds.HC
//
// ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01 C2 IMPL.
//
// PolyC-native QUALIFICATION TEST for the signed-integer parser of
// tools/quality/parser-control-flow-token-differential.HC (defect D4).
//
// The integer parser is the QUALIFIER's INPUT parser. It is not part of
// the production PolyC component, whose ABI and logic are untouched by
// this ACT. This tool exists so that the parser's boundary behaviour is
// established by an EXECUTABLE witness rather than by inspection.
//
// THE parse_int UNDER TEST IS NOT A HAND-WRITTEN COPY. The Makefile
// assembles this tool by concatenating:
//     1. the parse_int function MECHANICALLY EXTRACTED from
//        tools/quality/parser-control-flow-token-differential.HC
//        (delimited there by explicit BEGIN/END VERBATIM COPY markers),
//     2. this file's test cases.
// so the two can never silently drift apart.
//
// USAGE:
//   build/parser-control-flow-token-int-bounds
//
// EXIT STATUS: 0 if every boundary case behaves as specified, 1
// otherwise.
//
// NOTE: the failure counter is passed by pointer rather than kept in a
// file-scope global, because a file-scope global with an initializer
// makes the current PolyC compiler emit _main twice (measured
// independently of this ACT).

#include "../../src/holyc-lib/memory_defs.HH"

extern "c" I64 printf(U8 *fmt, ...);

// Print the 64-bit value as hex, so the exact bit pattern is visible.
// The PolyC "%d" formatter truncates large values, so the value is
// rendered byte-wise instead.
U0 Hex64(I64 v, U8 *dst)
{
  U8 *hex = "0123456789abcdef";
  for (I64 i = 0; i < 16; i = i + 1) {
    U64 nib = (v >> ((15 - i) * 4)) & 0xF;
    dst[i] = hex[nib];
  }
  dst[16] = 0;
}

// Check that `input` parses to exactly the 64-bit pattern `expect_hex`.
I64 expect_value(U8 *input, U8 *expect_hex, I64 *failures)
{
  U8 *p = input;
  I64 v = 0;
  I64 rc = parse_int(&p, &v);
  if (rc != 0) {
    printf("FAIL %s: expected a value, got a parse error\n", input);
    *failures = *failures + 1;
    return 0;
  }
  U8 got[24];
  Hex64(v, got);
  if (StrCmp(got, expect_hex) != 0) {
    printf("FAIL %s: expected %s, got %s\n", input, expect_hex, got);
    *failures = *failures + 1;
    return 0;
  }
  printf("PASS %s = %s\n", input, got);
  return 1;
}

// Check that `input` is REJECTED.
I64 expect_reject(U8 *input, I64 *failures)
{
  U8 *p = input;
  I64 v = 0;
  I64 rc = parse_int(&p, &v);
  if (rc == 0) {
    U8 got[24];
    Hex64(v, got);
    printf("FAIL %s: expected a rejection, got the value %s\n", input, got);
    *failures = *failures + 1;
    return 0;
  }
  printf("PASS %s rejected\n", input);
  return 1;
}

I64 main(I64 argc, U8 **argv)
{
  I64 failures = 0;

  // ---- The signed I64 boundaries -----------------------------------
  // I64_MAX = 0x7fffffffffffffff
  expect_value("9223372036854775807", "7fffffffffffffff", &failures);
  // I64_MIN = 0x8000000000000000
  expect_value("-9223372036854775808", "8000000000000000", &failures);
  // an explicit plus sign
  expect_value("+9223372036854775807", "7fffffffffffffff", &failures);

  // ---- Out of range must be REJECTED -------------------------------
  expect_reject("9223372036854775808", &failures);
  expect_reject("-9223372036854775809", &failures);
  expect_reject("9223372036854775809", &failures);
  expect_reject("18446744073709551616", &failures);
  expect_reject("99999999999999999999", &failures);
  expect_reject("+9223372036854775808", &failures);

  // ---- The hexadecimal boundaries ----------------------------------
  expect_value("0x7fffffffffffffff", "7fffffffffffffff", &failures);
  expect_value("-0x8000000000000000", "8000000000000000", &failures);
  expect_value("0x0", "0000000000000000", &failures);
  expect_reject("0x8000000000000000", &failures);
  expect_reject("-0x8000000000000001", &failures);
  expect_reject("0x10000000000000000", &failures);

  // ---- Malformed input ---------------------------------------------
  expect_reject("123abc", &failures);
  expect_reject("abc", &failures);
  expect_reject("0x", &failures);
  expect_reject("-", &failures);
  expect_reject("+", &failures);

  // ---- Ordinary values ---------------------------------------------
  expect_value("0", "0000000000000000", &failures);
  expect_value("42", "000000000000002a", &failures);
  expect_value("-42", "ffffffffffffffd6", &failures);
  expect_value("0x301", "0000000000000301", &failures);
  expect_value("-1", "ffffffffffffffff", &failures);

  if (failures) {
    printf("INT_BOUNDARY_FAILURES=%d\n", failures);
    printf("STATUS=FAIL\n");
    return 1;
  }
  printf("INT_BOUNDARY_FAILURES=0\n");
  printf("STATUS=PASS\n");
  return 0;
}
