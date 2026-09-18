// tools/quality/factory-closure-status-test.HC
//
// ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01 P0-4:
// PolyC authoritative wrapper for the 12-case regression matrix
// of scripts/quality/factory-closure-status-check.sh.
//
// Build:
//   ./hcc --install-dir=./build/test-prefix -c \
//       tools/quality/factory-closure-status-test.HC \
//       -o build/factory-closure-status-test.o
//   cc build/factory-closure-status-test.o \
//       src/holyc-lib/all.s -L./build/test-prefix/lib -ltos \
//       -lpthread -lc -lm \
//       -o build/factory-closure-status-test
//
// Invocation:
//   ./build/factory-closure-status-test <checker_path> <cases_path>
//   Defaults:
//     checker_path = ./scripts/quality/factory-closure-status-check.sh
//     cases_path   = ./scripts/quality/factory-closure-status-test-cases.sh
//
// This PolyC executable is intentionally a thin driver that
// invokes scripts/quality/factory-closure-status-test-cases.sh
// (which holds the 12-case regression matrix) and reports
// PASS/FAIL based on the cases script's exit code.
//
// F-POLYC-TOOLS rationale: this file IS the PolyC tool. The
// shell file scripts/quality/factory-closure-status-check-test.sh
// is reduced to <=50 LOC dispatch and contains no test logic
// of its own.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" I64 getpid(U0);

U8 *g_checker = NULL;
U8 *g_cases = NULL;
I64 g_pid = 0;

// Build a heap-allocated shell command string.
// Pattern: "sh <cases> <checker> 2>&1; echo EXIT_RC=$? > /tmp/fcst-exit-<pid>"
U8 *BuildCmd(U0)
{
  U8 *cmd = MAlloc(1024);
  I64 i = 0;
  U8 *p1 = "sh '";
  while (p1[i] != 0) { cmd[i] = p1[i]; i = i + 1; }
  I64 j = 0;
  while (g_cases[j] != 0) { cmd[i] = g_cases[j]; i = i + 1; j = j + 1; }
  U8 *p2 = "' '";
  j = 0;
  while (p2[j] != 0) { cmd[i] = p2[j]; i = i + 1; j = j + 1; }
  j = 0;
  while (g_checker[j] != 0) { cmd[i] = g_checker[j]; i = i + 1; j = j + 1; }
  U8 *p3 = "' 2>&1; echo EXIT_RC=$? > /tmp/fcst-exit-";
  j = 0;
  while (p3[j] != 0) { cmd[i] = p3[j]; i = i + 1; j = j + 1; }
  I64 n = g_pid;
  U8 digits[32];
  I64 dn = 0;
  if (n == 0) { digits[0] = '0'; dn = 1; }
  while (n > 0) { digits[dn] = '0' + (n % 10); n = n / 10; dn = dn + 1; }
  while (dn > 0) { dn = dn - 1; cmd[i] = digits[dn]; i = i + 1; }
  cmd[i] = 0;
  return cmd;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc >= 2) {
    g_checker = argv[1];
  } else {
    g_checker = "./scripts/quality/factory-closure-status-check.sh";
  }
  if (argc >= 3) {
    g_cases = argv[2];
  } else {
    g_cases = "./scripts/quality/factory-closure-status-test-cases.sh";
  }
  g_pid = getpid();

  "factory-closure-status-test (PolyC): checker=%s cases=%s\n",
    g_checker, g_cases;

  U8 *cmd = BuildCmd();
  I64 rc = System(cmd);
  Free(cmd);

  // Read exit-rc file.
  U8 rc_path[64];
  I64 ri = 0;
  U8 *prefix = "/tmp/fcst-exit-";
  while (prefix[ri] != 0 && ri < 50) { rc_path[ri] = prefix[ri]; ri = ri + 1; }
  I64 n = g_pid;
  U8 digits[32];
  I64 dn = 0;
  if (n == 0) { digits[0] = '0'; dn = 1; }
  while (n > 0) { digits[dn] = '0' + (n % 10); n = n / 10; dn = dn + 1; }
  while (dn > 0) { dn = dn - 1; rc_path[ri] = digits[dn]; ri = ri + 1; }
  rc_path[ri] = 0;

  I64 sz = 0;
  U8 *rc_buf = FileRead(rc_path, &sz);
  if (rc_buf == NULL) {
    "factory-closure-status-test: cannot read %s\n", rc_path;
    return 1;
  }
  I64 exit_rc = -1;
  U8 *prefix2 = "EXIT_RC=";
  I64 pi = 0;
  while (rc_buf[pi] != 0 && prefix2[pi] != 0 && rc_buf[pi] == prefix2[pi]) {
    pi = pi + 1;
  }
  I64 value = 0;
  while (rc_buf[pi] >= '0' && rc_buf[pi] <= '9') {
    value = value * 10 + (rc_buf[pi] - '0');
    pi = pi + 1;
  }
  exit_rc = value;
  Free(rc_buf);

  U8 rm_cmd[128];
  I64 mi = 0;
  U8 *rmp = "rm -f '";
  I64 mp = 0;
  while (rmp[mp] != 0) { rm_cmd[mi] = rmp[mp]; mi = mi + 1; mp = mp + 1; }
  mp = 0;
  while (rc_path[mp] != 0) { rm_cmd[mi] = rc_path[mp]; mi = mi + 1; mp = mp + 1; }
  rm_cmd[mi] = '\''; mi = mi + 1;
  rm_cmd[mi] = 0;
  System(rm_cmd);

  if (exit_rc != 0) {
    "factory-closure-status-test: cases FAILED (rc=%d)\n", exit_rc;
    return 1;
  }
  "factory-closure-status-test: cases PASSED\n";
  return 0;
}
