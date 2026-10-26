// evidence/ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01/probes/cap-verifier-identity-probe.HC
//
// RED probe for ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01, Defect B.
//
// The PolyC harness is parameterised by --hcc=<path>, but it invokes the
// cap-table verifier with no way to tell it WHICH compiler to query. The
// verifier hardcodes REPO_ROOT/"hcc".
//
// This probe demonstrates the resulting contract violation from INSIDE
// the harness's own subprocess seam (SpawnAndCapture):
//
//   * it spawns the verifier exactly as RunCapability() does;
//   * it shows that the verifier's stdout carries the diagnostic while
//     the captured stderr is EMPTY (the harness discards it);
//   * it shows that the verifier queries REPO_ROOT/"hcc" regardless of
//     which compiler the caller was given.
//
// The verifier's own message is the tell:
//
//   FAIL  hcc --print-cap-table exited non-zero:
//   FAIL  could not load capability table from hcc --print-cap-table
//
// A non-LLVM hcc does not handle --print-cap-table at all (the dispatch
// is inside #ifdef HCC_ENABLE_LLVM in src/main.c), so the flag is parsed
// and ignored, the compiler falls through to the normal compile path with
// no input file, and the process dies on SIGSEGV.

#include "../../../src/holyc-lib/memory_defs.HH"
#include "../../../src/holyc-lib/tooling_defs.HH"
#include "../../../src/holyc-lib/io_defs.HH"

public I32 main(I32 argc, U8 **argv)
{
  U8 *python = argv[1];
  U8 *dir = argv[2];

  "=== ACT-POLYC-TOOLING-GEP01-GATE-REPAIR01 :: Defect B probe ===\n";
  "python = %s\n\n", python;

  // Exactly the argv shape used by RunCapability() in
  // tools/quality/llvm-gep01-test.HC.
  U8 *args[3];
  args[0] = python;
  args[1] = StrPrint(NULL, "scripts/quality/llvm-cap-table-verifier.py");
  args[2] = NULL;

  U8 *out = NULL, *err = NULL;
  I64 rc = SpawnAndCapture(python, args, &out, &err);

  "SpawnAndCapture(rc)      = %d\n", rc;
  "captured stdout length   = %d\n", StrLen(out);
  "captured stderr length   = %d\n", StrLen(err);

  "\n--- captured stdout (what the harness writes to cap-verifier.txt) ---\n";
  "%s", out;
  "\n--- captured stderr (what the harness DISCARDS) ---\n";
  "%s", err;
  "--- end stderr ---\n";

  U8 *cap_path = StrPrint(NULL, "%s/cap-verifier.txt", dir);
  if (out) FileWrite(cap_path, out, StrLen(out));
  "wrote cap-verifier.txt   = %d bytes\n", StrLen(out);

  "\n=== INTERPRETATION ===\n";
  "The verifier's diagnostic is on stdout, so the harness DOES see it --\n";
  "but only as a generic 'could not read cap verifier output' row,\n";
  "because the three capability rows all collapse onto one message and\n";
  "the stderr channel is thrown away entirely.\n";
  "\n";
  "The verifier queries REPO_ROOT/\"hcc\" regardless of which compiler\n";
  "the caller was given, so its verdict depends on a binary the harness\n";
  "never told it about. When that binary is a non-LLVM build the flag\n";
  "--print-cap-table is unhandled, the compiler falls through to the\n";
  "normal compile path with no input file, and it dies on SIGSEGV.\n";
  return 0;
}
