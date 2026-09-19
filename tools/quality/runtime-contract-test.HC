// tools/quality/runtime-contract-test.HC
//
// ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01 C2-3: PolyC-native
// runtime contract test. Mechanically exercises the edge-case
// matrices required by AC06..AC11 (FREE, STRNCMP, MEMSET,
// STRLEN_FAST, SpawnAndCapture).
//
// Build (from repo root):
//   ./build/hcc-bootstrap04 --install-dir=./build/test-prefix \
//       -obj tools/quality/runtime-contract-test.HC \
//       -o build/runtime-contract-test.o
//   cc build/runtime-contract-test.o \
//      -L./build/test-prefix/lib -ltos -lpthread -lc -lm \
//      -o build/runtime-contract-test
//
// Invocation:
//   ./build/runtime-contract-test
//
// Exit code = number of FAIL cases.
//
// Output format:
//   PASS  <case_id>
//   FAIL  <case_id>  <reason>
//   ...
//   RUNTIME_CONTRACT_TEST_PASS=<n>
//   RUNTIME_CONTRACT_TEST_FAIL=<n>

// The canonical build invocation is:
//   ./hcc --install-dir=./build/test-prefix -c \
//       tools/quality/runtime-contract-test.HC -o build/runtime-contract-test.o
// hcc resolves includes relative to the SOURCE FILE's location,
// so ../../src/... is correct (going up from tools/quality/ to repo
// root, then into src/).
#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

extern "c" I8 *memcpy(U8 *dst, U8 *src, U64 len);

I64 g_pass = 0;
I64 g_fail = 0;

U0 ReportPass(U8 *id) {
  "PASS  %s\n", id;
  g_pass = g_pass + 1;
}

U0 ReportFail(U8 *id, U8 *reason) {
  "FAIL  %s  %s\n", id, reason;
  g_fail = g_fail + 1;
}

// AC06: FREE semantics
U0 TestFree() {
  // FREE_NULL_NOOP: Free(NULL) must not crash.
  Free(NULL);
  ReportPass("AC06_FREE_NULL_NOOP");

  // FREE_ALLOCATED_STORAGE: Free(p) where p was malloc'd.
  U8 *p = MAlloc(64);
  if (p == NULL) {
    ReportFail("AC06_FREE_ALLOCATED_STORAGE", "malloc returned NULL");
    return;
  }
  // Touch the allocation to ensure it's not optimized away.
  p[0] = 0xAB;
  p[63] = 0xCD;
  Free(p);
  ReportPass("AC06_FREE_ALLOCATED_STORAGE");
}

// AC07: STRNCMP semantics
U0 TestStrNCmp() {
  I64 r;

  // EQUAL
  r = StrNCmp("abc", "abc", 3);
  if (r != 0) ReportFail("AC07_STRNCMP_EQUAL", "expected 0");
  else ReportPass("AC07_STRNCMP_EQUAL");

  // LESS
  r = StrNCmp("abc", "abd", 3);
  if (r >= 0) ReportFail("AC07_STRNCMP_LESS", "expected <0");
  else ReportPass("AC07_STRNCMP_LESS");

  // GREATER
  r = StrNCmp("abd", "abc", 3);
  if (r <= 0) ReportFail("AC07_STRNCMP_GREATER", "expected >0");
  else ReportPass("AC07_STRNCMP_GREATER");

  // PREFIX (s1 is prefix of s2; only first n chars match)
  r = StrNCmp("ab", "abc", 2);
  if (r != 0) ReportFail("AC07_STRNCMP_PREFIX", "expected 0");
  else ReportPass("AC07_STRNCMP_PREFIX");

  // EMPTY (two empty strings, n=0)
  r = StrNCmp("", "", 0);
  if (r != 0) ReportFail("AC07_STRNCMP_EMPTY", "expected 0");
  else ReportPass("AC07_STRNCMP_EMPTY");
}

// AC08: MEMSET semantics
U0 TestMemSet() {
  U8 buf[16];

  // LEN_ZERO_NOOP
  MemSet(buf, 0xAB, 0);
  // Buffer contents should be unchanged (we don't know initial state
  // but the operation must not write anything; check by writing a
  // sentinel, then MemSet with len=0, then verify).
  buf[0] = 0x42;
  MemSet(buf, 0xAB, 0);
  if (buf[0] != 0x42) {
    ReportFail("AC08_MEMSET_LEN_ZERO_NOOP", "len=0 wrote bytes");
  } else {
    ReportPass("AC08_MEMSET_LEN_ZERO_NOOP");
  }

  // LEN_ONE
  buf[0] = 0x42;
  buf[1] = 0xCD;
  MemSet(buf, 0xAB, 1);
  if (buf[0] != 0xAB || buf[1] != 0xCD) {
    ReportFail("AC08_MEMSET_LEN_ONE", "len=1 wrote >1 byte");
  } else {
    ReportPass("AC08_MEMSET_LEN_ONE");
  }

  // NONZERO_FILL
  for (I64 i = 0; i < 16; i = i + 1) buf[i] = 0;
  MemSet(buf, 0x42, 16);
  I64 bad = 0;
  for (I64 i = 0; i < 16; i = i + 1) if (buf[i] != 0x42) bad = bad + 1;
  if (bad != 0) ReportFail("AC08_MEMSET_NONZERO_FILL", "some bytes wrong");
  else ReportPass("AC08_MEMSET_NONZERO_FILL");

  // ZERO_FILL
  for (I64 i = 0; i < 16; i = i + 1) buf[i] = 0xFF;
  MemSet(buf, 0, 16);
  bad = 0;
  for (I64 i = 0; i < 16; i = i + 1) if (buf[i] != 0) bad = bad + 1;
  if (bad != 0) ReportFail("AC08_MEMSET_ZERO_FILL", "some bytes wrong");
  else ReportPass("AC08_MEMSET_ZERO_FILL");

  // FF_FILL
  for (I64 i = 0; i < 16; i = i + 1) buf[i] = 0;
  MemSet(buf, 0xFF, 16);
  bad = 0;
  for (I64 i = 0; i < 16; i = i + 1) if (buf[i] != 0xFF) bad = bad + 1;
  if (bad != 0) ReportFail("AC08_MEMSET_FF_FILL", "some bytes wrong");
  else ReportPass("AC08_MEMSET_FF_FILL");
}

// AC09: STRLEN_FAST semantics (via StrLen)
U0 TestStrLen() {
  I64 r;

  // EMPTY
  r = StrLen("");
  if (r != 0) ReportFail("AC09_STRLEN_EMPTY", "expected 0");
  else ReportPass("AC09_STRLEN_EMPTY");

  // ASCII
  r = StrLen("hello");
  if (r != 5) ReportFail("AC09_STRLEN_ASCII", "expected 5");
  else ReportPass("AC09_STRLEN_ASCII");

  // NUL_TERMINATION (count up to NUL, ignore rest)
  r = StrLen("abc\0def");
  if (r != 3) ReportFail("AC09_STRLEN_NUL_TERMINATION", "expected 3");
  else ReportPass("AC09_STRLEN_NUL_TERMINATION");
}

// AC11: SpawnAndCapture semantics
U0 TestSpawnAndCapture() {
  U8 *out = NULL;
  U8 *err = NULL;
  U8 *args[4];
  I64 rc;

  // Choose platform-appropriate commands. macOS hosts ship /bin/echo
  // and /bin/sh, but /bin/true and /bin/false may be absent (sandbox
  // hosts); /usr/bin/{true,false} are the canonical macOS paths.
  U8 *cmd_true  = "/usr/bin/true";
  U8 *cmd_false = "/usr/bin/false";
  U8 *cmd_echo  = "/bin/echo";
  U8 *cmd_sh    = "/bin/sh";

  // SUCCESS: /bin/echo hello
  args[0] = cmd_echo;
  args[1] = "hello";
  args[2] = NULL;
  args[3] = NULL;
  out = NULL; err = NULL;
  rc = SpawnAndCapture(args[0], args, &out, &err);
  if (rc != 0) {
    ReportFail("AC11_SAC_SUCCESS", "expected rc=0");
  } else if (out == NULL || StrLen(out) == 0) {
    ReportFail("AC11_SAC_SUCCESS", "expected non-empty *out");
  } else {
    ReportPass("AC11_SAC_SUCCESS");
  }
  if (out) Free(out);
  if (err) Free(err);

  // NONZERO_EXIT: /usr/bin/false
  args[0] = cmd_false;
  args[1] = NULL;
  args[2] = NULL;
  args[3] = NULL;
  out = NULL; err = NULL;
  rc = SpawnAndCapture(args[0], args, &out, &err);
  if (rc == 0) {
    ReportFail("AC11_SAC_NONZERO_EXIT", "expected rc!=0");
  } else {
    ReportPass("AC11_SAC_NONZERO_EXIT");
  }
  if (out) Free(out);
  if (err) Free(err);

  // CMD_NOT_FOUND: /nonexistent_program_xyz
  args[0] = "/nonexistent_program_xyz";
  args[1] = NULL;
  args[2] = NULL;
  args[3] = NULL;
  out = NULL; err = NULL;
  rc = SpawnAndCapture(args[0], args, &out, &err);
  if (rc != 127) {
    ReportFail("AC11_SAC_CMD_NOT_FOUND", "expected rc=127");
  } else {
    ReportPass("AC11_SAC_CMD_NOT_FOUND");
  }
  if (out) Free(out);
  if (err) Free(err);

  // EMPTY_OUTPUT: /usr/bin/true (success, no stdout, no stderr)
  args[0] = cmd_true;
  args[1] = NULL;
  args[2] = NULL;
  args[3] = NULL;
  out = NULL; err = NULL;
  rc = SpawnAndCapture(args[0], args, &out, &err);
  if (rc != 0) {
    ReportFail("AC11_SAC_EMPTY_OUTPUT", "expected rc=0");
  } else if (out == NULL) {
    // NULL or 1-byte NUL buffer both acceptable per contract
    ReportPass("AC11_SAC_EMPTY_OUTPUT");
  } else if (StrLen(out) != 0) {
    ReportFail("AC11_SAC_EMPTY_OUTPUT", "expected empty *out");
  } else {
    ReportPass("AC11_SAC_EMPTY_OUTPUT");
  }
  if (out) Free(out);
  if (err) Free(err);

  // STDOUT_CAPTURE: verify *out actually contains the bytes
  args[0] = cmd_echo;
  args[1] = "marker_string_xyz";
  args[2] = NULL;
  args[3] = NULL;
  out = NULL; err = NULL;
  rc = SpawnAndCapture(args[0], args, &out, &err);
  if (rc != 0) {
    ReportFail("AC11_SAC_STDOUT_CAPTURE", "expected rc=0");
  } else if (out == NULL || StrLen(out) == 0) {
    ReportFail("AC11_SAC_STDOUT_CAPTURE", "expected *out to have content");
  } else {
    // Use StrNCmp: *out starts with the marker (echo adds a trailing
    // newline, so StrLen(out) >= StrLen(marker)). Compare the first
    // StrLen(marker) bytes; equality means the marker is present.
    if (StrNCmp(out, "marker_string_xyz", 17) == 0) {
      ReportPass("AC11_SAC_STDOUT_CAPTURE");
    } else {
      ReportFail("AC11_SAC_STDOUT_CAPTURE", "marker not in *out");
    }
  }
  if (out) Free(out);
  if (err) Free(err);

  // STDERR_CAPTURE: /bin/sh -c 'echo err_msg 1>&2'
  args[0] = cmd_sh;
  args[1] = "-c";
  args[2] = "echo err_marker_xyz 1>&2";
  args[3] = NULL;
  out = NULL; err = NULL;
  rc = SpawnAndCapture(args[0], args, &out, &err);
  if (rc != 0) {
    ReportFail("AC11_SAC_STDERR_CAPTURE", "expected rc=0");
  } else if (err == NULL || StrLen(err) == 0) {
    ReportFail("AC11_SAC_STDERR_CAPTURE", "expected *err to have content");
  } else {
    if (StrNCmp(err, "err_marker_xyz", 14) == 0) {
      ReportPass("AC11_SAC_STDERR_CAPTURE");
    } else {
      ReportFail("AC11_SAC_STDERR_CAPTURE", "marker not in *err");
    }
  }
  if (out) Free(out);
  if (err) Free(err);
}

// Entry point: top-level code (hcc generates a default main).
TestFree();
TestStrNCmp();
TestMemSet();
TestStrLen();
TestSpawnAndCapture();
"RUNTIME_CONTRACT_TEST_PASS=%d\n", g_pass;
"RUNTIME_CONTRACT_TEST_FAIL=%d\n", g_fail;
if (g_fail != 0) Exit(g_fail);
