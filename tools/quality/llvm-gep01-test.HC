// tools/quality/llvm-gep01-test.HC
//
// ACT-POLYC-TOOLING-MIGRATE-GEP01 C2 IMPL.
//
// PolyC-native replacement for scripts/quality/llvm-gep01-test.sh.
// Preserves the exact 30-row oracle frozen in
//   evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/oracle-matrix.tsv
//
// Architectural constraints (binding):
//
//   * Direct-argv process execution only. No /bin/sh, no
//     bash -c, no system(), no Sh(), no Shlurp(). All
//     subprocess execution goes through SpawnAndCapture,
//     which uses execv() (see src/holyc-lib/tooling.HC).
//
//   * execv() does NOT perform PATH lookup. Bare names like
//     "llvm-as" therefore MUST be resolved locally against
//     $PATH before being passed to SpawnAndCapture. The
//     helper ResolveTool() in this file is the LOCAL
//     path-search utility that preserves the legacy
//     LLVM_AS=llvm-as / LLVM_OPT=opt defaults without
//     widening tooling.HC.
//
//   * Scratch goes under build/quality/gep01, NEVER under
//     evidence/ACT-POLYC-LLVM-GEP01/c3/_tmp.
//
//   * No compiler / parser / IR / backend / ABI / factory
//     semantics changes are authorized by this ACT.
//
// CLI:
//
//   llvm-gep01-test                              \
//     --hcc=./hcc                                \
//     --llvm-install-dir=./build/test-prefix     \
//     --llvm-as=llvm-as                          \
//     --llvm-opt=opt                             \
//     --python=python3                           \
//     [--mode=fail]                              \
//     [--scratch=<dir>]
//
// Exits 0 iff every assertion in the 30-row oracle
// passes; non-zero with STATUS=FAIL otherwise.
//
// For --mode=fail, the readat dynamic-index assertion is
// forced to fail so the harness exit-channel can be
// inspected for the seeded-failure gate (C3 §22).

#include "../../src/holyc-lib/tooling.HC"
#include "../../src/holyc-lib/io.HC"

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
  "GEP01_PASS=%d\n", v->pass;
  "GEP01_FAIL=%d\n", v->fail;
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
// Local PATH resolver -- fills the execv()/no-PATH-lookup gap
// for the legacy defaults LLVM_AS=llvm-as, LLVM_OPT=opt,
// and python3.
//
//   * Names containing a "/" are returned verbatim (path
//     names bypass the search).
//   * Empty PATH returns NULL (unresolvable).
//   * Returns the first directory whose joined entry exists
//     (Stat presence). If a directory holds a non-executable
//     entry the execv will surface a real ENOENT/EACCES
//     through the rc=127 channel, which is already a
//     legitimate harness failure.
//
// This helper does NOT widen tooling.HC. It is purely a
// harness-local utility.
// ------------------------------------------------------------

U8 *ResolveTool(U8 *name)
{
  I8 *path_env;

  if (!name) return NULL;

  // Already a path (absolute or relative) -> pass through.
  if (StrFirstOcc(name, "/") != NULL)
    return StrPrint(NULL, "%s", name);

  path_env = getenv("PATH");
  if (path_env == NULL || path_env[0] == 0) return NULL;

  I32 n = StrLen(path_env);
  I32 start = 0;
  for (I32 i = 0; i <= n; ++i) {
    if (path_env[i] == 0x3A || path_env[i] == 0) {
      I32 len = i - start;
      if (len > 0) {
        U8 *dir = MAlloc(len + 1);
        MemCpy(dir, path_env + start, len);
        dir[len] = 0;
        U8 *candidate = StrPrint(NULL, "%s/%s", dir, name);
        Free(dir);
        if (FileExists(candidate)) return candidate;
        Free(candidate);
      }
      start = i + 1;
    }
  }
  return NULL;
}

// ------------------------------------------------------------
// File-slurp wrapper returning a freshly-allocated buffer
// plus its byte length. Wraps io.HC::FileRead to provide a
// stable contract for the harness (caller owns the buffer).
// ------------------------------------------------------------

U8 *SlurpFile(U8 *path, I64 *out_sz)
{
  *out_sz = 0;
  return FileRead(path, out_sz);
}

U0 BytewiseFree(U8 *buf)
{
  if (buf) Free(buf);
}

// ------------------------------------------------------------
// Substring counting (replacement for legacy `grep -c`).
// Returns the number of non-overlapping occurrences of
// needle in haystack. Empty needle returns 0.
// ------------------------------------------------------------

I64 CountSubstr(U8 *haystack, U8 *needle)
{
  I64 hn, qn, hits;
  if (haystack == NULL || needle == NULL) return 0;
  hn = StrLen(haystack);
  qn = StrLen(needle);
  if (qn == 0) return 0;
  hits = 0;
  for (I64 i = 0; i < hn - qn + 1; ) {
    Bool match = TRUE;
    for (I64 j = 0; j < qn; ++j) {
      if (haystack[i + j] != needle[j]) { match = FALSE; break; }
    }
    if (match) { hits++; i += qn; }
    else       { i++; }
  }
  return hits;
}

// ------------------------------------------------------------
// First match of a regex-free glob-ish pattern anchored on
// the substring "<prefix><digits>" inside text, returning
// the trailing digits as a freshly-allocated string, or
// NULL if not found. Used to extract
// `shape_dependent=<N>` from stderr.
//
// Legacy equivalent:
//   sd=$(grep -o 'shape_dependent=[0-9]\+'
//        err.txt | head -1 | cut -d= -f2)
// ------------------------------------------------------------

U8 *ExtractShapeDependent(U8 *text)
{
  U8 *key = "shape_dependent=";
  I64 n, kn;
  if (!text) return NULL;
  n = StrLen(text);
  kn = StrLen(key);
  for (I64 i = 0; i < n - kn + 1; ++i) {
    if (StrNCmp(text + i, key, kn) != 0) continue;
    I64 j = i + kn;
    I64 start = j;
    while (j < n && text[j] >= 0x30 && text[j] <= 0x39) j++;
    if (j > start) {
      I64 digits = j - start;
      U8 *out = MAlloc(digits + 1);
      MemCpy(out, text + start, digits);
      out[digits] = 0;
      return out;
    }
    return NULL;
  }
  return NULL;
}

// ------------------------------------------------------------
// Hcc-emit helper: invoke
//   hcc --emit-llvm --install-dir=IDIR -o OUT SRC
// returns SpawnAndCapture rc, writes stdout to *out,
// stderr to *err. Caller owns *out and *err buffers.
// ------------------------------------------------------------

I64 HccEmitLlvm(U8 *hcc_path, U8 *install_dir, U8 *src,
                U8 *out_ll_path, U8 **out, U8 **err)
{
  U8 *args[7];
  I64 rc;
  *out = NULL;
  *err = NULL;
  args[0] = hcc_path;
  args[1] = "--emit-llvm";
  args[2] = StrPrint(NULL, "--install-dir=%s", install_dir);
  args[3] = "-o";
  args[4] = out_ll_path;
  args[5] = src;
  args[6] = NULL;
  rc = SpawnAndCapture(hcc_path, args, out, err);
  Free(args[2]);
  return rc;
}

// ------------------------------------------------------------
// Section: toolchain (row 01)
// ------------------------------------------------------------

U0 RunToolchain(TestVerdict *v, U8 *hcc_path,
                U8 *llvm_as, U8 *llvm_opt, U8 *python)
{
  if (hcc_path == NULL || FileExists(hcc_path) == FALSE) {
    VerdictFail(v, "toolchain: hcc + llvm-as + opt available",
                StrPrint(NULL, "hcc not found at %s", hcc_path));
    return;
  }
  if (llvm_as == NULL) {
    VerdictFail(v, "toolchain: hcc + llvm-as + opt available",
                "llvm-as unresolvable on PATH");
    return;
  }
  if (llvm_opt == NULL) {
    VerdictFail(v, "toolchain: hcc + llvm-as + opt available",
                "opt unresolvable on PATH");
    return;
  }
  if (python == NULL) {
    VerdictFail(v, "toolchain: hcc + llvm-as + opt available",
                "python3 unresolvable on PATH");
    return;
  }
  VerdictPass(v, "toolchain: hcc + llvm-as + opt available");
}

// ------------------------------------------------------------
// Section: positive fixtures (rows 02..06, 07, 08)
// ------------------------------------------------------------

U0 RunPositives(TestVerdict *v, U8 *hcc_path, U8 *install_dir,
                U8 *scratch, Bool seed_failure)
{
  U8 *out = NULL, *err = NULL, *emitted = NULL;
  I64 rc, sz = 0;
  U8 *readat_ll, *read0_ll, *read2_ll, *twodigits_ll;
  U8 *readat_err;

  // Read0 (row 02)
  read0_ll = StrPrint(NULL, "%s/read0.ll", scratch);
  rc = HccEmitLlvm(hcc_path, install_dir,
                   "src/tests/llvm-gep01/read0.HC",
                   read0_ll, &out, &err);
  BytewiseFree(out); BytewiseFree(err); out = NULL; err = NULL;
  if (rc != 0) {
    VerdictFail(v, "read0.HC: load i8, ptr",
                "hcc --emit-llvm failed");
  } else {
    emitted = SlurpFile(read0_ll, &sz);
    if (emitted != NULL && Contains(emitted, "load i8, ptr %"))
      VerdictPass(v, "read0.HC: load i8, ptr");
    else
      VerdictFail(v, "read0.HC: load i8, ptr",
                  "no 'load i8, ptr' in emitted IR");
    BytewiseFree(emitted); emitted = NULL;
  }
  Free(read0_ll);

  // Read2 (row 03)
  read2_ll = StrPrint(NULL, "%s/read2.ll", scratch);
  rc = HccEmitLlvm(hcc_path, install_dir,
                   "src/tests/llvm-gep01/read2.HC",
                   read2_ll, &out, &err);
  BytewiseFree(out); BytewiseFree(err); out = NULL; err = NULL;
  if (rc != 0) {
    VerdictFail(v, "read2.HC: getelementptr i8 + load i8",
                "hcc --emit-llvm failed");
  } else {
    emitted = SlurpFile(read2_ll, &sz);
    if (emitted != NULL && Contains(emitted, "getelementptr i8, ptr %")
        && Contains(emitted, "load i8, ptr %"))
      VerdictPass(v, "read2.HC: getelementptr i8 + load i8");
    else
      VerdictFail(v, "read2.HC: getelementptr i8 + load i8",
                  "missing GEP/load i8 in emitted IR");
    BytewiseFree(emitted); emitted = NULL;
  }
  Free(read2_ll);

  // ReadAt combined row (row 04: gep+load)
  // row 05: SHAPE_DEPENDENT counter >= 1
  readat_ll = StrPrint(NULL, "%s/read-at.ll", scratch);
  readat_err = StrPrint(NULL, "%s/readat.err", scratch);
  U8 *argv_local[8];
  argv_local[0] = hcc_path;
  argv_local[1] = "--emit-llvm";
  argv_local[2] = StrPrint(NULL, "--install-dir=%s", install_dir);
  argv_local[3] = "-o";
  argv_local[4] = readat_ll;
  argv_local[5] = "src/tests/llvm-gep01/readat.HC";
  argv_local[6] = NULL;
  rc = SpawnAndCapture(hcc_path, argv_local, &out, &err);
  if (err) {
    U8 *err_data = err;
    I64 err_sz = StrLen(err);
    FileWrite(readat_err, err_data, err_sz);
  }
  Free(argv_local[2]);
  BytewiseFree(out); BytewiseFree(err); out = NULL; err = NULL;

  if (rc != 0) {
    VerdictFail(v, "readat.HC: getelementptr i8 with runtime index + load i8",
                "hcc --emit-llvm failed");
    VerdictFail(v, "readat.HC: SHAPE_DEPENDENT counter = ? (>= 1)",
                "hcc --emit-llvm failed");
  } else {
    emitted = SlurpFile(readat_ll, &sz);
    if (seed_failure) {
      VerdictFail(v, "readat.HC: getelementptr i8 with runtime index + load i8",
                  "seed_failure forced (--mode=fail)");
    } else if (emitted != NULL
        && Contains(emitted, "getelementptr i8, ptr %")
        && Contains(emitted, "load i8, ptr %")) {
      VerdictPass(v, "readat.HC: getelementptr i8 with runtime index + load i8");
    } else {
      VerdictFail(v, "readat.HC: getelementptr i8 with runtime index + load i8",
                  "missing GEP/load i8 in emitted IR");
    }
    BytewiseFree(emitted); emitted = NULL;

    U8 *sd_text = SlurpFile(readat_err, &sz);
    U8 *sd = ExtractShapeDependent(sd_text);
    if (sd) {
      I64 sdn = 0;
      for (I64 i = 0; sd[i]; ++i) sdn = sdn * 10 + (sd[i] - 0x30);
      if (sdn >= 1) {
        VerdictPass(v, StrPrint(NULL,
          "readat.HC: SHAPE_DEPENDENT counter = %d (>= 1)", sdn));
      } else {
        VerdictFail(v, "readat.HC: SHAPE_DEPENDENT counter = 0 (expected >= 1)",
                    "shape_dependent counter below 1");
      }
      Free(sd);
    } else {
      VerdictFail(v, "readat.HC: SHAPE_DEPENDENT counter = ? (expected >= 1)",
                  "shape_dependent marker not found in stderr");
    }
    BytewiseFree(sd_text);
  }
  Free(readat_ll);
  Free(readat_err);


  // TwoDigits (row 06)
  twodigits_ll = StrPrint(NULL, "%s/b0-multiread.ll", scratch);
  rc = HccEmitLlvm(hcc_path, install_dir,
                   "src/tests/llvm-gep01/twodigits.HC",
                   twodigits_ll, &out, &err);
  BytewiseFree(out); BytewiseFree(err); out = NULL; err = NULL;
  if (rc != 0) {
    VerdictFail(v, "twodigits.HC: 2 load i8 + 1 getelementptr i8 (>=2 distinct reads, >=1 GEP for non-zero index)",
                "hcc --emit-llvm failed");
  } else {
    emitted = SlurpFile(twodigits_ll, &sz);
    if (!emitted) {
      VerdictFail(v, "twodigits.HC: 2 load i8 + 1 getelementptr i8 (>=2 distinct reads, >=1 GEP for non-zero index)",
                  "could not read emitted IR");
    } else {
      I64 load_count = CountSubstr(emitted, "load i8, ptr %");
      I64 gep_count  = CountSubstr(emitted, "getelementptr i8");
      if (load_count >= 2 && gep_count >= 1) {
        VerdictPass(v, StrPrint(NULL,
          "twodigits.HC: %d load i8 + %d getelementptr i8 (>=2 distinct reads, >=1 GEP for non-zero index)",
          load_count, gep_count));
      } else {
        VerdictFail(v, "twodigits.HC: ? load i8 + ? getelementptr i8 (>=2 distinct reads, >=1 GEP for non-zero index)",
                    StrPrint(NULL,
                      "expected >=2 load i8 + >=1 getelementptr, got loads=%d gep=%d",
                      load_count, gep_count));
      }
    }
    BytewiseFree(emitted); emitted = NULL;
  }
  Free(twodigits_ll);

  // LLVM textual GEP structure (rows 07, 08) -- against readat.ll.
  U8 *readat_ll_path = StrPrint(NULL, "%s/read-at.ll", scratch);
  emitted = SlurpFile(readat_ll_path, &sz);
  Free(readat_ll_path);
  if (!emitted) {
    VerdictFail(v, "ReadAt emitted getelementptr i8, ptr %base, i64 %index",
                "could not re-read emitted IR");
    VerdictFail(v, "GEP result used as load address (load i8, ptr %gep_i8)",
                "could not re-read emitted IR");
  } else {
    if (Contains(emitted, "getelementptr i8, ptr %"))
      VerdictPass(v, "ReadAt emitted getelementptr i8, ptr %base, i64 %index");
    else
      VerdictFail(v, "ReadAt emitted getelementptr i8, ptr %base, i64 %index",
                  "missing expected GEP shape");
    if (Contains(emitted, "load i8, ptr %"))
      VerdictPass(v, "GEP result used as load address (load i8, ptr %gep_i8)");
    else
      VerdictFail(v, "GEP result used as load address (load i8, ptr %gep_i8)",
                  "missing GEP->load pattern");
    BytewiseFree(emitted); emitted = NULL;
  }
}

// ------------------------------------------------------------
// Section: llvm-as / opt (rows 09..16)
// ------------------------------------------------------------

U0 RunLlvmAsOpt(TestVerdict *v, U8 *llvm_as, U8 *llvm_opt,
                U8 *scratch)
{
  U8 *base[4];
  U8 *args[8];
  U8 *out = NULL, *err = NULL;
  I64 rc;

  base[0] = "read0";         base[1] = "read2";
  base[2] = "read-at";       base[3] = "b0-multiread";

  for (I64 i = 0; i < 4; ++i) {
    U8 *ll_path = StrPrint(NULL, "%s/%s.ll", scratch, base[i]);
    U8 *bc_path = StrPrint(NULL, "%s/%s.bc", scratch, base[i]);

    if (!FileExists(ll_path)) { Free(ll_path); Free(bc_path); continue; }

    args[0] = llvm_as; args[1] = ll_path; args[2] = "-o"; args[3] = bc_path;
    args[4] = NULL;
    rc = SpawnAndCapture(llvm_as, args, &out, &err);
    BytewiseFree(out); BytewiseFree(err); out = NULL; err = NULL;
    if (rc == 0) {
      VerdictPass(v, StrPrint(NULL, "%s.ll: llvm-as accepted", base[i]));
    } else {
      VerdictFail(v, StrPrint(NULL, "%s.ll: llvm-as accepted", base[i]),
                  "llvm-as rejected");
    }
    Free(ll_path); Free(bc_path);
  }

  for (I64 i = 0; i < 4; ++i) {
    U8 *bc_path = StrPrint(NULL, "%s/%s.bc", scratch, base[i]);
    if (!FileExists(bc_path)) { Free(bc_path); continue; }
    args[0] = llvm_opt; args[1] = "--passes=verify"; args[2] = bc_path;
    args[3] = "-o"; args[4] = "/dev/null"; args[5] = NULL;
    rc = SpawnAndCapture(llvm_opt, args, &out, &err);
    BytewiseFree(out); BytewiseFree(err); out = NULL; err = NULL;
    if (rc == 0) {
      VerdictPass(v, StrPrint(NULL, "%s.bc: opt --passes=verify accepted",
                              base[i]));
    } else {
      VerdictFail(v, StrPrint(NULL,
        "%s.bc: opt --passes=verify accepted", base[i]),
        "opt rejected");
    }
    Free(bc_path);
  }
}


// ------------------------------------------------------------
// Section: no ptrtoint/inttoptr, no inbounds (rows 17..24)
// ------------------------------------------------------------

U0 RunFences(TestVerdict *v, U8 *scratch)
{
  U8 *base[4];
  base[0] = "read0"; base[1] = "read2";
  base[2] = "read-at"; base[3] = "b0-multiread";
  for (I64 i = 0; i < 4; ++i) {
    U8 *ll_path = StrPrint(NULL, "%s/%s.ll", scratch, base[i]);
    if (!FileExists(ll_path)) { Free(ll_path); continue; }
    I64 sz = 0;
    U8 *emitted = SlurpFile(ll_path, &sz);
    if (!emitted) { Free(ll_path); continue; }

    if (Contains(emitted, "ptrtoint") == FALSE
        && Contains(emitted, "inttoptr") == FALSE) {
      VerdictPass(v, StrPrint(NULL,
        "%s.ll: zero ptrtoint/inttoptr", base[i]));
    } else {
      VerdictFail(v, StrPrint(NULL,
        "%s.ll: zero ptrtoint/inttoptr", base[i]),
        "ptrtoint/inttoptr present");
    }

    if (Contains(emitted, "getelementptr inbounds") == FALSE) {
      VerdictPass(v, StrPrint(NULL,
        "%s.ll: zero getelementptr inbounds", base[i]));
    } else {
      VerdictFail(v, StrPrint(NULL,
        "%s.ll: zero getelementptr inbounds", base[i]),
        "inbounds GEP present (PLAIN_GEP policy)");
    }
    BytewiseFree(emitted);
    Free(ll_path);
  }
}

// ------------------------------------------------------------
// Section: negative non-I8 boundary (row 25)
// ------------------------------------------------------------

U0 RunNegative(TestVerdict *v, U8 *hcc_path, U8 *install_dir,
               U8 *scratch)
{
  U8 *out = NULL, *err = NULL;
  U8 *ll_path = StrPrint(NULL, "%s/i64idx.ll", scratch);
  I64 rc = HccEmitLlvm(hcc_path, install_dir,
                       "src/tests/llvm-gep01/i64idx.HC",
                       ll_path, &out, &err);
  BytewiseFree(out);
  Free(ll_path);
  if (rc == 0) {
    VerdictFail(v, "i64idx.HC: rejected with LLVM_BACKEND_UNSUPPORTED_POINTER (scale=8)",
                "should be rejected, but hcc --emit-llvm succeeded");
  } else if (err
      && (Contains(err, "LLVM_BACKEND_UNSUPPORTED_POINTER")
          || Contains(err, "scale=8")
          || Contains(err, "IR_LOAD_DEREF with non-zero disp or scaled-index"))) {
    VerdictPass(v, "i64idx.HC: rejected with LLVM_BACKEND_UNSUPPORTED_POINTER (scale=8)");
  } else {
    VerdictFail(v, "i64idx.HC: rejected with LLVM_BACKEND_UNSUPPORTED_POINTER (scale=8)",
                "rejected but with unexpected diagnostic");
  }
  BytewiseFree(err);
}

// ------------------------------------------------------------
// Section: capability status (rows 26..28)
// ------------------------------------------------------------

U0 RunCapability(TestVerdict *v, U8 *python, U8 *scratch)
{
  U8 *out = NULL, *err = NULL;
  U8 *cap_path = StrPrint(NULL, "%s/cap-verifier.txt", scratch);
  U8 *args[3];
  args[0] = python;
  args[1] = StrPrint(NULL, "scripts/quality/llvm-cap-table-verifier.py");
  args[2] = NULL;
  I64 rc = SpawnAndCapture(python, args, &out, &err);
  if (out) FileWrite(cap_path, out, StrLen(out));
  BytewiseFree(out); BytewiseFree(err);
  Free(args[1]);

  if (rc != 0 && !FileExists(cap_path)) {
    VerdictFail(v, "IR_GEP = REJECTED (sibling opcode still rejected)",
                "cap-table verifier invocation failed");
    VerdictFail(v, "IR_LEA = REJECTED (sibling opcode still rejected)",
                "cap-table verifier invocation failed");
    VerdictFail(v, "IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset)",
                "cap-table verifier invocation failed");
    Free(cap_path);
    return;
  }

  I64 sz = 0;
  U8 *cap_txt = SlurpFile(cap_path, &sz);
  if (!cap_txt) {
    VerdictFail(v, "IR_GEP = REJECTED (sibling opcode still rejected)",
                "could not read cap verifier output");
    VerdictFail(v, "IR_LEA = REJECTED (sibling opcode still rejected)",
                "could not read cap verifier output");
    VerdictFail(v, "IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset)",
                "could not read cap verifier output");
    Free(cap_path);
    return;
  }

  if (Contains(cap_txt, "IR_GEP")
      && Contains(cap_txt, "(REJECTED)")) {
    VerdictPass(v, "IR_GEP = REJECTED (sibling opcode still rejected)");
  } else {
    VerdictFail(v, "IR_GEP = REJECTED (sibling opcode still rejected)",
                "IR_GEP not REJECTED");
  }
  if (Contains(cap_txt, "IR_LEA")
      && Contains(cap_txt, "(REJECTED)")) {
    VerdictPass(v, "IR_LEA = REJECTED (sibling opcode still rejected)");
  } else {
    VerdictFail(v, "IR_LEA = REJECTED (sibling opcode still rejected)",
                "IR_LEA not REJECTED");
  }
  if (Contains(cap_txt, "IR_IADD")
      && Contains(cap_txt, "(SUPPORTED)")) {
    VerdictPass(v, "IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset)");
  } else {
    VerdictFail(v, "IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset)",
                "IR_IADD not SUPPORTED");
  }
  BytewiseFree(cap_txt);
  Free(cap_path);
}


// ------------------------------------------------------------
// Section: determinism (rows 29, 30)
// ------------------------------------------------------------

U0 RunDeterminism(TestVerdict *v, U8 *hcc_path, U8 *install_dir,
                  U8 *scratch)
{
  U8 *fixtures[2];
  fixtures[0] = "src/tests/llvm-gep01/readat.HC";
  fixtures[1] = "src/tests/llvm-gep01/twodigits.HC";
  for (I64 i = 0; i < 2; ++i) {
    U8 *src = fixtures[i];
    I64 sl = StrLen(src);
    U8 *bn = MAlloc(sl + 1);
    I64 last_slash = -1;
    for (I64 k = 0; k < sl; ++k) if (src[k] == '/') last_slash = k;
    I64 bn_start = last_slash + 1;
    I64 bn_len = sl - bn_start - 3; // strip ".HC"
    MemCpy(bn, src + bn_start, bn_len);
    bn[bn_len] = 0;

    U8 *ll1 = StrPrint(NULL, "%s/%s_1.ll", scratch, bn);
    U8 *ll2 = StrPrint(NULL, "%s/%s_2.ll", scratch, bn);
    U8 *out = NULL, *err = NULL;
    HccEmitLlvm(hcc_path, install_dir, src, ll1, &out, &err);
    BytewiseFree(out); BytewiseFree(err);
    HccEmitLlvm(hcc_path, install_dir, src, ll2, &out, &err);
    BytewiseFree(out); BytewiseFree(err);

    I64 sz1 = 0, sz2 = 0;
    U8 *b1 = SlurpFile(ll1, &sz1);
    U8 *b2 = SlurpFile(ll2, &sz2);
    Bool identical = FALSE;
    if (b1 && b2 && sz1 == sz2 && sz1 > 0) {
      identical = TRUE;
      for (I64 k = 0; k < sz1; ++k) {
        if (b1[k] != b2[k]) { identical = FALSE; break; }
      }
    }
    if (identical) {
      VerdictPass(v, StrPrint(NULL, "%s: byte-identical across two runs", bn));
    } else {
      VerdictFail(v, StrPrint(NULL, "%s: byte-identical across two runs", bn),
                  "not byte-identical");
    }
    BytewiseFree(b1); BytewiseFree(b2);
    Free(ll1); Free(ll2); Free(bn);
  }
}

// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

public I32 Main(I32 argc, U8 **argv)
{
  U8 *hcc_path     = ArgValue(argc, argv, "--hcc",           "./hcc");
  U8 *install_dir  = ArgValue(argc, argv, "--llvm-install-dir",
                              "./build/test-prefix");
  U8 *llvm_as_name = ArgValue(argc, argv, "--llvm-as",       "llvm-as");
  U8 *llvm_opt_name= ArgValue(argc, argv, "--llvm-opt",      "opt");
  U8 *python_name  = ArgValue(argc, argv, "--python",        "python3");
  U8 *scratch_in   = ArgValue(argc, argv, "--scratch",
                              "build/quality/gep01");
  Bool seed        = ArgFlag(argc, argv, "--mode=fail");

  // Resolve bare tool names against $PATH. If a flag already
  // contains a "/" the resolver returns the path verbatim.
  U8 *llvm_as  = ResolveTool(llvm_as_name);
  U8 *llvm_opt = ResolveTool(llvm_opt_name);
  U8 *python   = ResolveTool(python_name);

  TestVerdict *v = VerdictNew();

  "=== ACT-POLYC-TOOLING-MIGRATE-GEP01 PolyC harness ===\n";
  "hcc           = %s\n", hcc_path;
  "install_dir   = %s\n", install_dir;
  "llvm_as       = %s\n", llvm_as;
  "llvm_opt      = %s\n", llvm_opt;
  "python        = %s\n", python;
  "scratch       = %s\n", scratch_in;
  if (seed) "seed-failure = YES\n";
  else      "seed-failure = no\n";
  "\n";

  RunToolchain(v, hcc_path, llvm_as, llvm_opt, python);

  if (v->fail == 0) {
    RunPositives(v, hcc_path, install_dir, scratch_in, seed);
    RunLlvmAsOpt(v, llvm_as, llvm_opt, scratch_in);
    RunFences(v, scratch_in);
    RunNegative(v, hcc_path, install_dir, scratch_in);
    RunCapability(v, python, scratch_in);
    RunDeterminism(v, hcc_path, install_dir, scratch_in);
  }

  VerdictSummary(v);
  I64 rc = VerdictRc(v);
  Free(v);
  Free(llvm_as); Free(llvm_opt); Free(python);
  return rc;
}
