// tools/quality/libtos-n02-isolate.HC
//
// ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02 C2-3: PolyC-native
// N02 negative control isolator. Substantive archive-mutation,
// inspection, and link-check logic. The accompanying shell
// script (scripts/quality/libtos-n02-harness.sh) is <=50 LOC
// of dispatch glue.
//
// The shell harness already:
//   (a) compiled this tool against libtos.a (archive-only link)
//   (b) prepared a scratch dir with the pristine archive copied
//       to ./libtos-pristine.a
//
// This tool:
//   (1) extracts pristine members (ar x)
//   (2) verifies _SpawnAndCapture is in pristine (nm)
//   (3) runs llvm-objcopy --localize-symbol=_SpawnAndCapture
//   (4) verifies the symbol is now 't' (lowercase)
//   (5) re-ar's a corrupted archive
//   (6) writes a minimal consumer.HC (self-contained, no
//       external header deps) into build/tmp/ in the repo
//   (7) chdir's to repo root and invokes hcc to compile
//   (8) compiles + links against the corrupted archive
//   (9) verifies the link fails with only _SpawnAndCapture
//       as the undefined symbol
//
// Output format: KEY=VALUE lines.
//
// Exit code: 0 = N02 isolated correctly (only _SpawnAndCapture
// undefined when linked); nonzero = isolation failed.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

I64 g_pass;
I64 g_fail;

U0 ReportPass(U8 *id) {
  "N02_CASE=%s STATUS=PASS\n", id;
  g_pass = g_pass + 1;
}

U0 ReportFail(U8 *id, U8 *reason) {
  "N02_CASE=%s STATUS=FAIL REASON=%s\n", id, reason;
  g_fail = g_fail + 1;
}

I64 StrBufContains(U8 *buf, U8 *needle) {
  U8 *p, *q;
  if (!buf || !needle) return 0;
  p = buf;
  while (*p) {
    q = needle;
    while (*q && *p == *q) { p = p + 1; q = q + 1; }
    if (!*q) return 1;
    p = p + 1;
  }
  return 0;
}

// Extract repository root from hcc path
// (e.g. /x/y/z/build/hcc-bootstrap04 -> /x/y/z).
U8 *RepoRootFromHcc(U8 *hcc) {
  U8 buf[1024];
  U8 *p = hcc;
  U8 *end = p + StrLen(p);
  while (end > p && *(end - 1) != '/') end = end - 1;
  if (end > p) end = end - 1;
  while (end > p && *(end - 1) != '/') end = end - 1;
  if (end > p) end = end - 1;
  U64 i = 0;
  U8 *q;
  for (q = p; q < end; q++) buf[i++] = *q;
  buf[i] = 0;
  return StrNew(buf);
}

// Self-contained consumer source. We include the public header
// by an absolute path that the tool bakes in. The hcc binary
// path is supplied so we can derive the repo root and hence
// the absolute include path.
U8 *ConsumerSource(U8 *hcc) {
  // Compute the repo root from hcc.
  U8 *rr = RepoRootFromHcc(hcc);
  // Compute absolute include path: rr + /src/holyc-lib/tooling_defs.HH
  U8 *abs_inc = StrPrint(NULL, "%s/src/holyc-lib/tooling_defs.HH", rr);
  Free(rr);
  // Format the consumer source.
  U8 *src = StrPrint(NULL,
    "#include \"%s\"\n"
    "I64 main(I64 argc, U8 **argv) {\n"
    "  U8 *args[2];\n"
    "  args[0] = \"/usr/bin/true\";\n"
    "  args[1] = NULL;\n"
    "  U8 *out = NULL;\n"
    "  U8 *err = NULL;\n"
    "  I64 rc = SpawnAndCapture(args[0], args, &out, &err);\n"
    "  if (out) Free(out);\n"
    "  if (err) Free(err);\n"
    "  return rc;\n"
    "}\n",
    abs_inc);
  Free(abs_inc);
  return src;
}

I32 Main(I32 argc, U8 **argv) {
  U8 *pristine = NULL;
  U8 *scratch  = NULL;
  U8 *hcc      = NULL;
  U8 *objcopy  = NULL;
  I64 rc;

  g_pass = 0;
  g_fail = 0;

  // Parse args.
  I32 i;
  for (i = 1; i < argc; i++) {
    if ((StrCmp(argv[i], "--pristine") == 0 || StrCmp(argv[i], "-p") == 0)
        && i + 1 < argc) {
      pristine = StrNew(argv[i + 1]);
      i = i + 1;
    } else if ((StrCmp(argv[i], "--scratch") == 0 || StrCmp(argv[i], "-s") == 0)
        && i + 1 < argc) {
      scratch = StrNew(argv[i + 1]);
      i = i + 1;
    } else if ((StrCmp(argv[i], "--hcc") == 0 || StrCmp(argv[i], "-c") == 0)
        && i + 1 < argc) {
      hcc = StrNew(argv[i + 1]);
      i = i + 1;
    } else if ((StrCmp(argv[i], "--objcopy") == 0 || StrCmp(argv[i], "-o") == 0)
        && i + 1 < argc) {
      objcopy = StrNew(argv[i + 1]);
      i = i + 1;
    }
  }
  if (!pristine || !scratch || !hcc || !objcopy) {
    "N02_USAGE: --pristine <path> --scratch <dir> --hcc <path> --objcopy <path>\n";
    return 2;
  }

  U8 *repo_root = RepoRootFromHcc(hcc);

  // The absolute include path is built lazily inside
  // ConsumerSource (which is called late, after several
  // SpawnAndCapture calls that may have reallocated the heap).
  // We pass hcc directly; ConsumerSource derives everything.

  // chdir to scratch dir for steps 1-5 (archive mutation).
  if (chdir(scratch) != 0) {
    ReportFail("N02_CHDIR_SCRATCH", "chdir to scratch failed");
    return 3;
  }

  // (1) extract pristine members
  "N02_STEP=1/9: extract pristine members\n";
  {
    U8 *args[4];
    U8 *out = NULL, *err = NULL;
    args[0] = "/usr/bin/ar"; args[1] = "x"; args[2] = pristine; args[3] = NULL;
    rc = SpawnAndCapture("/usr/bin/ar", args, &out, &err);
    if (rc != 0) {
      if (out) { "N02_EXTRACT_ERR=%s\n", err; Free(out); Free(err); }
      ReportFail("N02_EXTRACT", "ar x failed");
      return 3;
    }
    if (out) Free(out); if (err) Free(err);
    ReportPass("N02_EXTRACT");
  }

  // (2) verify pristine has _SpawnAndCapture (T)
  "N02_STEP=2/9: verify pristine has T _SpawnAndCapture\n";
  {
    U8 *args[4];
    U8 *out = NULL, *err = NULL;
    args[0] = "/usr/bin/nm"; args[1] = pristine; args[2] = NULL; args[3] = NULL;
    rc = SpawnAndCapture("/usr/bin/nm", args, &out, &err);
    if (rc != 0 || !out || !StrBufContains(out, " T _SpawnAndCapture")) {
      ReportFail("N02_PRISTINE_HAS_SYMBOL", "T _SpawnAndCapture absent");
      if (out) Free(out); if (err) Free(err);
      return 3;
    }
    if (out) Free(out); if (err) Free(err);
    ReportPass("N02_PRISTINE_HAS_SYMBOL");
  }

  // (3) llvm-objcopy --localize-symbol=_SpawnAndCapture
  "N02_STEP=3/9: llvm-objcopy --localize-symbol=_SpawnAndCapture\n";
  {
    U8 *args[5];
    args[0] = objcopy;
    args[1] = "--localize-symbol=_SpawnAndCapture";
    args[2] = "all.o";
    args[3] = "all.o.localized";
    args[4] = NULL;
    rc = SpawnAndCapture(objcopy, args, NULL, NULL);
    if (rc != 0) {
      ReportFail("N02_OBJCOPY", "llvm-objcopy failed");
      return 3;
    }
    ReportPass("N02_OBJCOPY");
  }

  // (4) verify _SpawnAndCapture is now 't'
  "N02_STEP=4/9: verify _SpawnAndCapture now 't'\n";
  {
    U8 *args[4];
    U8 *out = NULL, *err = NULL;
    args[0] = "/usr/bin/nm"; args[1] = "all.o.localized"; args[2] = NULL; args[3] = NULL;
    rc = SpawnAndCapture("/usr/bin/nm", args, &out, &err);
    if (rc != 0 || !out || !StrBufContains(out, " t _SpawnAndCapture")) {
      ReportFail("N02_LOCALIZED_T", "_SpawnAndCapture not localized");
      if (out) Free(out); if (err) Free(err);
      return 3;
    }
    if (out) Free(out); if (err) Free(err);
    ReportPass("N02_LOCALIZED_T");
  }

  // (5) ar rcs libtos-corrupted.a all.o.localized errno_shim.o producer_id.o
  "N02_STEP=5/9: ar rcs libtos-corrupted.a\n";
  {
    U8 *args[8];
    args[0] = "/usr/bin/ar";
    args[1] = "rcs";
    args[2] = "libtos-corrupted.a";
    args[3] = "all.o.localized";
    args[4] = "errno_shim.o";
    args[5] = "producer_id.o";
    args[6] = NULL;
    rc = SpawnAndCapture("/usr/bin/ar", args, NULL, NULL);
    if (rc != 0) {
      ReportFail("N02_AR_CORRUPTED", "ar rcs failed");
      return 3;
    }
    ReportPass("N02_AR_CORRUPTED");
  }

  // (6) write consumer.HC into the repo's build/tmp/ so hcc can
  // find it via a relative path. Then chdir to repo root for
  // the compile + link.
  "N02_STEP=6/9: write consumer.HC into build/tmp/\n";
  {
    // Build abs_inc INSIDE ConsumerSource, derived from a
    // freshly-computed repo_root (computed from hcc, which is
    // a stable heap pointer). This avoids any cross-call
    // pointer/buffer aliasing issues.
    U8 *src = ConsumerSource(hcc);
    if (chdir(repo_root) != 0) {
      Free(src);
      ReportFail("N02_CHDIR_REPO", "chdir to repo root failed");
      return 3;
    }
    "N02_CWD=%s\n", repo_root;
    if (!FileWrite("build/tmp/consumer.HC", src, StrLen(src),
                   O_CREAT | O_RDWR)) {
      "N02_WRITE_ERR: build/tmp/consumer.HC write failed\n";
      Free(src);
      ReportFail("N02_WRITE_CONSUMER", "failed to write consumer.HC");
      return 3;
    }
    Free(src);
    ReportPass("N02_WRITE_CONSUMER");
  }

  // (7) compile consumer with hcc (in repo root, relative paths)
  "N02_STEP=7/9: compile consumer with hcc\n";
  {
    U8 *args[8];
    U8 *out = NULL, *err = NULL;
    args[0] = hcc;
    args[1] = "--install-dir=build/test-prefix";
    args[2] = "-c";
    args[3] = "build/tmp/consumer.HC";
    args[4] = "-o";
    args[5] = "build/tmp/consumer.o";
    args[6] = NULL;
    rc = SpawnAndCapture(hcc, args, &out, &err);
    if (rc != 0) {
      if (out) { "N02_COMPILE_OUT=%s\n", out; Free(out); }
      if (err) { "N02_COMPILE_ERR=%s\n", err; Free(err); }
      ReportFail("N02_COMPILE", "hcc compile failed");
      return 3;
    }
    if (out) Free(out); if (err) Free(err);
    ReportPass("N02_COMPILE");
  }

  // (8) link consumer against libtos-corrupted.a
  // We use cc to link directly: the consumer.o was built by hcc
  // and is at build/tmp/consumer.o. We pass the absolute path
  // to libtos-corrupted.a in the scratch dir.
  "N02_STEP=8/9: link consumer against libtos-corrupted.a\n";
  U8 *link_log = MAlloc(8192);
  link_log[0] = 0;
  {
    U8 *abs_corrupted = StrPrint(NULL, "%s/libtos-corrupted.a", scratch);

    U8 *args[10];
    U8 *out = NULL, *err = NULL;
    args[0] = "/usr/bin/cc";
    args[1] = "build/tmp/consumer.o";
    args[2] = abs_corrupted;
    args[3] = "-lpthread";
    args[4] = "-lc";
    args[5] = "-lm";
    args[6] = NULL;
    rc = SpawnAndCapture("/usr/bin/cc", args, &out, &err);
    Free(abs_corrupted);
    // Link is EXPECTED to fail.
    "N02_LINK_RC=%d\n", rc;
    if (rc == 0) {
      if (out) Free(out); if (err) Free(err);
      Free(link_log);
      ReportFail("N02_LINK_FAILED", "link unexpectedly succeeded");
      return 3;
    }
    ReportPass("N02_LINK_FAILED");
    // Save err for step 9.
    if (err) {
      StrCpy(link_log, err);
      Free(err);
    }
    if (out) Free(out);
  }

  // (9) inspect link stderr: only _SpawnAndCapture should be undefined
  "N02_STEP=9/9: verify only _SpawnAndCapture is undefined\n";
  {
    if (!StrBufContains(link_log, "Undefined")) {
      ReportFail("N02_UNDEFINED_BLOCK",
                 "no 'Undefined' marker in link stderr");
      Free(link_log);
      return 3;
    }
    if (!StrBufContains(link_log, "_SpawnAndCapture")) {
      ReportFail("N02_HAS_SPAWNANDCAPTURE_UNDEFINED",
                 "_SpawnAndCapture not in undefined list");
      Free(link_log);
      return 3;
    }
    ReportPass("N02_HAS_SPAWNANDCAPTURE_UNDEFINED");
    if (StrBufContains(link_log, "_FREE") ||
        StrBufContains(link_log, "_STRNCMP") ||
        StrBufContains(link_log, "_MEMSET") ||
        StrBufContains(link_log, "_STRLEN_FAST")) {
      ReportFail("N02_OTHER_REQUIRED_SYMBOLS_PRESENT",
                 "other required symbols also undefined");
      Free(link_log);
      return 3;
    }
    ReportPass("N02_OTHER_REQUIRED_SYMBOLS_PRESENT");
  }
  Free(link_log);

  "N02_PASS=%d\n", g_pass;
  "N02_FAIL=%d\n", g_fail;
  "N02_RESULT=PASS\n";
  return 0;
}
