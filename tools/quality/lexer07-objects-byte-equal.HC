// tools/quality/lexer07-objects-byte-equal.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C2 IMPL.
//
// Executable self-tests for the ObjectsByteEqual predicate.
// Mirrors the C source in tools/quality/lexer07-broad-corpus-4-stage.HC
// (inline MemCmp + ObjectsByteEqual). The test driver emits
// OBJECTS_BYTE_EQUAL_TESTS=PASS iff all four cases below hold.
//
// Test matrix (per ACT §5.2):
//   1. same-size identical buffers       -> TRUE
//   2. same-size one-byte difference     -> FALSE
//   3. different-size same-prefix        -> FALSE
//   4. zero-length vs zero-length        -> TRUE
//
// Usage:
//   build/lexer07-objects-byte-equal

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

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

I32 Main(I32 argc, U8 **argv)
{
  I64 pass = 0;
  I64 fail = 0;

  // Test 1: same-size identical buffers -> TRUE.
  {
    U8 a[5] = {1, 2, 3, 4, 5};
    U8 b[5] = {1, 2, 3, 4, 5};
    Bool r = FALSE;
    ObjectsByteEqual(a, 5, b, 5, &r);
    if (r == TRUE) pass = pass + 1;
    else { fail = fail + 1; "FAIL test1 same-size identical r=%d\n", r; }
  }

  // Test 2: same-size one-byte difference -> FALSE.
  {
    U8 a[5] = {1, 2, 3, 4, 5};
    U8 b[5] = {1, 2, 3, 4, 6};
    Bool r = TRUE;
    ObjectsByteEqual(a, 5, b, 5, &r);
    if (r == FALSE) pass = pass + 1;
    else { fail = fail + 1; "FAIL test2 one-byte-diff r=%d\n", r; }
  }

  // Test 3: different-size same-prefix -> FALSE.
  {
    U8 a[3] = {1, 2, 3};
    U8 b[5] = {1, 2, 3, 4, 5};
    Bool r = TRUE;
    ObjectsByteEqual(a, 3, b, 5, &r);
    if (r == FALSE) pass = pass + 1;
    else { fail = fail + 1; "FAIL test3 diff-size-prefix r=%d\n", r; }
  }

  // Test 4: zero-length vs zero-length -> TRUE.
  {
    U8 a[1] = {0};
    U8 b[1] = {0};
    Bool r = FALSE;
    ObjectsByteEqual(a, 0, b, 0, &r);
    if (r == TRUE) pass = pass + 1;
    else { fail = fail + 1; "FAIL test4 zero-length r=%d\n", r; }
  }

  "OBJECTS_BYTE_EQUAL pass=%d fail=%d\n", pass, fail;
  if (fail == 0) {
    "OBJECTS_BYTE_EQUAL_TESTS=PASS\n";
    return 0;
  } else {
    "OBJECTS_BYTE_EQUAL_TESTS=FAIL\n";
    return 1;
  }
}
