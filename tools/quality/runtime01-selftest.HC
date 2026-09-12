// tools/quality/runtime01-selftest.HC
//
// ACT-POLYC-TOOLING-RUNTIME01 C3 EVIDENCE — PolyC
// self-test for the new tooling-runtime substrate.
//
// Exercises every primitive in api-shape-freeze.txt:
//
//   Process matrix    P1..P5
//   Filesystem        P12..P15
//   Verdict channel   P17, P18
//   GEP dogfood slice P22, P23 (read-only slice of
//                              llvm-gep01-test.sh)
//
// Usage:
//   runtime01-selftest                            \
//       --child=/path/to/rt01-child               \
//       --hcc=/path/to/hcc                        \
//       --llvm-install-dir=/path/to/test-prefix   \
//       [--mode=fail]
//
// Exits 0 iff every assertion passed.

#include "../../src/holyc-lib/tooling.HC"

#define RT01_LL_SUFFIX ".ll"

// ------------------------------------------------------------
// TestVerdict aggregator
// ------------------------------------------------------------

class TestVerdict {
  I64 pass;
  I64 fail;
};

public TestVerdict *VerdictNew()
{
  TestVerdict *v = MAlloc(sizeof(TestVerdict));
  v->pass = 0;
  v->fail = 0;
  return v;
}

public U0 VerdictPass(TestVerdict *v, U8 *name)
{
  v->pass++;
  "PASS  %s\n", name;
}

public U0 VerdictFail(TestVerdict *v, U8 *name, U8 *msg)
{
  v->fail++;
  "FAIL  %s: %s\n", name, msg;
}

public I64 VerdictRc(TestVerdict *v)
{
  if (v->fail == 0) return 0;
  return 1;
}

public U0 VerdictSummary(TestVerdict *v)
{
  "----\n";
  "RT01_PASS=%d\n", v->pass;
  "RT01_FAIL=%d\n", v->fail;
  if (v->fail == 0) "STATUS=PASS\n";
  else              "STATUS=FAIL\n";
}

// ------------------------------------------------------------
// Argument helpers
// ------------------------------------------------------------

U8 *ArgValue(I32 argc, U8 **argv, U8 *flag, U8 *fallback)
{
  for (I32 i = 1; i < argc; ++i) {
    if (StrNCmp(argv[i], flag, StrLen(flag)) == 0) {
      U8 *eq = StrFirstOcc(argv[i], "=");
      if (eq != NULL) return eq + 1;
      if (i + 1 < argc) return argv[i + 1];
    }
  }
  return fallback;
}

Bool ArgFlag(I32 argc, U8 **argv, U8 *flag)
{
  for (I32 i = 1; i < argc; ++i) {
    if (!StrCmp(argv[i], flag)) return TRUE;
  }
  return FALSE;
}

// ------------------------------------------------------------
// Process evidence (P1..P5)
// ------------------------------------------------------------

U0 RunProcessMatrix(TestVerdict *v, U8 *child_path, Bool seed_failure)
{
  U8 *out = NULL, *err = NULL;
  U8 *args[4];
  I64 rc;

  // P1: deterministic successful child
  args[0] = child_path; args[1] = "stdout"; args[2] = NULL;
  rc = SpawnAndCapture(child_path, args, &out, &err);
  if (rc == 0 && out && Contains(out, "polyc-rt01-out")
      && (!err || err[0] == 0)) {
    VerdictPass(v, "P1 success-child");
  } else {
    VerdictFail(v, "P1 success-child",
                "rc or stdout/stderr mismatch");
  }
  Free(out); Free(err); out = NULL; err = NULL;

  // P2: non-zero child
  args[1] = "rc=42"; args[2] = NULL;
  rc = SpawnAndCapture(child_path, args, &out, &err);
  if (rc == 42) {
    VerdictPass(v, "P2 nonzero-exit");
  } else {
    VerdictFail(v, "P2 nonzero-exit",
                "expected rc=42");
  }
  Free(out); Free(err); out = NULL; err = NULL;

  // P3: stderr captured separately
  args[1] = "stderr"; args[2] = NULL;
  rc = SpawnAndCapture(child_path, args, &out, &err);
  if (rc == 0
      && out && out[0] == 0
      && err && Contains(err, "polyc-rt01-err")) {
    VerdictPass(v, "P3 stderr-separate");
  } else {
    VerdictFail(v, "P3 stderr-separate",
                "stderr not captured separately");
  }
  Free(out); Free(err); out = NULL; err = NULL;

  // P4: missing executable
  args[0] = "/does/not/exist/polyc-rt01-missing";
  args[1] = NULL;
  rc = SpawnAndCapture("/does/not/exist/polyc-rt01-missing",
                       args, &out, &err);
  if (rc != 0) {
    VerdictPass(v, "P4 missing-executable");
  } else {
    VerdictFail(v, "P4 missing-executable",
                "spawn failure did not surface");
  }
  Free(out); Free(err); out = NULL; err = NULL;

  // P5: literal argv with metacharacters
  args[0] = child_path; args[1] = "echo";
  args[2] = "a b c"; args[3] = NULL;
  rc = SpawnAndCapture(child_path, args, &out, &err);
  if (rc == 0 && out && Contains(out, "a b c"))
    VerdictPass(v, "P5-1 literal-spaces");
  else
    VerdictFail(v, "P5-1 literal-spaces",
                "spaces were tokenized or stripped");
  Free(out); Free(err); out = NULL; err = NULL;
  args[2] = "$HOME"; args[3] = NULL;
  rc = SpawnAndCapture(child_path, args, &out, &err);
  if (rc == 0 && out && Contains(out, "$HOME"))
    VerdictPass(v, "P5-2 literal-dollar");
  else
    VerdictFail(v, "P5-2 literal-dollar",
                "$HOME was expanded");
  Free(out); Free(err); out = NULL; err = NULL;
  args[2] = "*"; args[3] = NULL;
  rc = SpawnAndCapture(child_path, args, &out, &err);
  if (rc == 0 && out && Contains(out, "*"))
    VerdictPass(v, "P5-3 literal-star");
  else
    VerdictFail(v, "P5-3 literal-star",
                "* was globbed");
  Free(out); Free(err); out = NULL; err = NULL;
  args[2] = "; rm -rf /"; args[3] = NULL;
  rc = SpawnAndCapture(child_path, args, &out, &err);
  if (rc == 0 && out && Contains(out, "; rm -rf /"))
    VerdictPass(v, "P5-4 literal-semicolon");
  else
    VerdictFail(v, "P5-4 literal-semicolon",
                "; was interpreted by shell");
  Free(out); Free(err); out = NULL; err = NULL;

  // P17 seeded-failure control
  if (seed_failure) {
    VerdictFail(v, "P17 seeded-failure",
                "intentional (--mode=fail)");
  }
}

// ------------------------------------------------------------
// Filesystem + temp evidence (P12..P15)
// ------------------------------------------------------------

U0 RunFilesystemMatrix(TestVerdict *v)
{
  U8 *path = "/tmp/rt01-fs-test.txt";
  U8 *data = "polyc-runtime01-fs-data";
  U8 *readback;
  I64 sz = 0;

  if (FileWrite(path, data, StrLen(data))) {
    VerdictPass(v, "P13 file-write");
  } else {
    VerdictFail(v, "P13 file-write", "FileWrite returned FALSE");
    return;
  }
  if (FileExists(path)) {
    VerdictPass(v, "P12 file-exists");
  } else {
    VerdictFail(v, "P12 file-exists", "FileExists returned FALSE");
    return;
  }
  readback = FileRead(path, &sz);
  if (readback && StrCmp(readback, data) == 0) {
    VerdictPass(v, "P12 file-read");
  } else {
    VerdictFail(v, "P12 file-read",
                "FileRead contents do not match");
  }
  Free(readback);
  Rm(path);
  if (!FileExists(path)) {
    VerdictPass(v, "P15 cleanup");
  } else {
    VerdictFail(v, "P15 cleanup", "Rm did not remove file");
  }
}

U0 RunTempMatrix(TestVerdict *v)
{
  U8 *p1 = NULL, *p2 = NULL;
  I32 fd1, fd2;

  fd1 = TmpFile("/tmp", "rt01-", &p1);
  fd2 = TmpFile("/tmp", "rt01-", &p2);
  if (fd1 < 0 || fd2 < 0) {
    VerdictFail(v, "P14 temp-create", "TmpFile returned negative fd");
    return;
  }
  if (p1 && p2 && StrCmp(p1, p2) != 0
      && FileExists(p1) && FileExists(p2)) {
    VerdictPass(v, "P14 temp-unique");
  } else {
    VerdictFail(v, "P14 temp-unique",
                "two TmpFile calls collided");
  }
  close(fd1);
  close(fd2);
  Rm(p1);
  Rm(p2);
  Free(p1);
  Free(p2);
}

// ------------------------------------------------------------
// GEP dogfood slice (P22/P23)
// ------------------------------------------------------------
//
// Read-only assertion slice of llvm-gep01-test.sh:
// compile src/tests/llvm-gep01/readat.HC via hcc
// --emit-llvm, capture the emitted IR, and assert:
//   - hcc exit code == 0
//   - emitted IR contains "getelementptr i8"
//   - emitted IR does NOT contain "getelementptr inbounds"
//   - emitted IR does NOT contain "ptrtoint"
//   - emitted IR does NOT contain "inttoptr"
//
// The existing llvm-gep01-test.sh remains authoritative;
// this slice is the parity witness per ACT §23.

U0 RunGepDogfood(TestVerdict *v, U8 *hcc_path,
                 U8 *llvm_install_dir)
{
  U8 *out = NULL, *err = NULL;
  U8 *emitted = NULL;
  I64 rc;
  U8 *args[8];
  U8 *ll_path = "/tmp/rt01-gep-readat.ll";
  I64 sz = 0;

  args[0] = hcc_path;
  args[1] = "--emit-llvm";
  args[2] = StrPrint(NULL, "--install-dir=%s", llvm_install_dir);
  args[3] = "-o";
  args[4] = ll_path;
  args[5] = "src/tests/llvm-gep01/readat.HC";
  args[6] = NULL;

  rc = SpawnAndCapture(hcc_path, args, &out, &err);
  Free(args[2]);

  if (rc != 0) {
    U8 *errmsg = "";
    if (err) errmsg = err;
    VerdictFail(v, "GEP hcc-exit",
                StrPrint(NULL, "hcc rc=%d stderr=%s",
                         rc, errmsg));
    Free(out); Free(err);
    return;
  }
  VerdictPass(v, "GEP hcc-exit");

  emitted = FileRead(ll_path, &sz);
  if (!emitted) {
    VerdictFail(v, "GEP read-emit", "FileRead returned NULL");
    Free(out); Free(err);
    return;
  }

  if (Contains(emitted, "getelementptr i8"))
    VerdictPass(v, "GEP contains-gep-i8");
  else
    VerdictFail(v, "GEP contains-gep-i8",
                "emitted IR missing getelementptr i8");

  if (!Contains(emitted, "getelementptr inbounds"))
    VerdictPass(v, "GEP no-inbounds");
  else
    VerdictFail(v, "GEP no-inbounds",
                "emitted IR contains 'inbounds'");

  if (!Contains(emitted, "ptrtoint"))
    VerdictPass(v, "GEP no-ptrtoint");
  else
    VerdictFail(v, "GEP no-ptrtoint",
                "emitted IR contains 'ptrtoint'");

  if (!Contains(emitted, "inttoptr"))
    VerdictPass(v, "GEP no-inttoptr");
  else
    VerdictFail(v, "GEP no-inttoptr",
                "emitted IR contains 'inttoptr'");

  Rm(ll_path);
  Free(emitted);
  Free(out);
  Free(err);
}

// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

public I32 Main(I32 argc, U8 **argv)
{
  U8 *child     = ArgValue(argc, argv, "--child",
                           "/tmp/rt01-child");
  U8 *hcc       = ArgValue(argc, argv, "--hcc",       "./hcc");
  U8 *ll_install= ArgValue(argc, argv, "--llvm-install-dir",
                           "./build/test-prefix");
  Bool seed     = ArgFlag(argc, argv, "--mode=fail");

  TestVerdict *v = VerdictNew();

  "=== ACT-POLYC-TOOLING-RUNTIME01 C3 selftest ===\n";
  "child        = %s\n", child;
  "hcc          = %s\n", hcc;
  "llvm_install = %s\n", ll_install;
  if (seed)
    "seed-failure = YES\n";
  else
    "seed-failure = no\n";
  "\n";

  RunProcessMatrix(v, child, seed);
  RunFilesystemMatrix(v);
  RunTempMatrix(v);
  RunGepDogfood(v, hcc, ll_install);

  VerdictSummary(v);
  I64 rc = VerdictRc(v);
  Free(v);
  return rc;
}
