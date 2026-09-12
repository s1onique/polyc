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
//     [--scratch=<dir>]                          \
//     [--predicate-selftest]
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
// Predicate helpers (C1.2 contract).
//
// Both helpers below are pure-local: they take a text
// buffer, return a Bool, perform no filesystem / process
// / state / dispatching operation, and depend only on
// the HolyC primitives already imported by the harness
// (StrNCmp, MemCpy, MAlloc, Free, Contains). They do NOT
// widen tooling.HC. tooling.HC delta = 0.
//
// Both helpers are also invoked by both:
//   - the normal 30-row run (rows 04/07/08/26/27/28)
//   - the --predicate-selftest mode (seven-case table)
//
// so a regression in one helper is caught by the
// selftest that the ACT-POLYC-TOOLING-MIGRATE-GEP01-
// CORRECTION01 §3.2 contract freezes.
//
// HALT_GEP_HELPER_WEAKER_THAN_LEGACY:
//   Any future helper whose acceptance set is a strict
//   superset of the legacy Bash regex
//   `getelementptr i8, ptr %[0-9]+, i64 %[0-9]+`
//   violates the frozen oracle and MUST halt. The three
//   negative cases (A constant-index, B symbolic-base) +
//   one positive case (C genuine) in --predicate-selftest
//   mechanically enforce this.
// ------------------------------------------------------------

// GepDynamicI8Shape(text) -> Bool
//
// Returns TRUE iff text contains, on the SAME line,
// exactly:
//
//     getelementptr i8, ptr %<base-digits>, i64 %<idx-digits>
//
// where:
//   - <base-digits> is one or more decimal digits (0x30..0x39);
//   - <idx-digits>  is one or more decimal digits;
//   - the literal "getelementptr i8, ptr %" prefix and the
//     literal ", i64 %" infix are required, on the same
//     line, with NO allowed characters between them.
//
// This is the smallest pure-local helper whose acceptance
// set equals the frozen legacy Bash ERE
// `getelementptr i8, ptr %[0-9]+, i64 %[0-9]+`:
//   - A constant-index fixture (e.g. `ptr %0, i64 2`)
//     is rejected because the ", i64 %" infix is absent.
//   - A symbolic-base fixture (e.g. `ptr %base, i64 %1`)
//     is rejected because the digits-after-% requirement
//     is not met on the base operand.
//   - A genuine dynamic-shape fixture (e.g.
//     `ptr %0, i64 %1`) is accepted.

Bool GepDynamicI8Shape(U8 *text)
{
  U8 *needle = "getelementptr i8, ptr %";
  I64 needle_len;
  I64 text_len;
  I64 i;

  if (text == NULL) return FALSE;

  needle_len = StrLen(needle);
  text_len   = StrLen(text);

  for (i = 0; i + needle_len <= text_len; ++i) {
    // Anchor the literal prefix on this line. The prefix
    // cannot span a newline.
    if (StrNCmp(text + i, needle, needle_len) != 0) continue;

    // After the prefix, on the SAME line, require at
    // least one decimal digit, then the literal
    // ", i64 %", then at least one decimal digit.
    I64 j = i + needle_len;

    // digits: base
    I64 base_start = j;
    while (j < text_len && text[j] >= 0x30 && text[j] <= 0x39) j++;
    if (j == base_start) continue;   // no base digits
    if (j >= text_len) return FALSE;

    // literal infix
    U8 *infix = ", i64 %";
    I64 infix_len = StrLen(infix);
    if (j + infix_len > text_len) return FALSE;
    if (StrNCmp(text + j, infix, infix_len) != 0) continue;
    j += infix_len;

    // digits: index
    I64 idx_start = j;
    while (j < text_len && text[j] >= 0x30 && text[j] <= 0x39) j++;
    if (j == idx_start) continue;    // no idx digits

    // Must not have any further non-newline character
    // before terminating the line -- the legacy regex
    // allows trailing text, but the actual emitted IR
    // stops at end-of-statement / newline. We do not
    // require end-of-line here; the helper is purely a
    // sub-line substring predicate.
    return TRUE;
  }
  return FALSE;
}

// LineContainsOpcodeMarker(text, opcode, marker) -> Bool
//
// Returns TRUE iff text contains, on the SAME line,
// the literal opcode (e.g. "IR_GEP") followed, anywhere
// later on that same line, by the literal marker
// (e.g. "(REJECTED)" or "(SUPPORTED)"). opcode MUST
// occur before marker; newlines between them reject.
//
// This binds the legacy Bash semantics that the
// (REJECTED)/(SUPPORTED) marker stays on the same line
// as the opcode name in the cap-verifier output. A
// malformed fixture where the marker is on a different
// line from the opcode is rejected.

Bool LineContainsOpcodeMarker(U8 *text, U8 *opcode, U8 *marker)
{
  I64 text_len, op_len, mk_len;
  I64 i;

  if (text == NULL || opcode == NULL || marker == NULL) return FALSE;

  text_len = StrLen(text);
  op_len   = StrLen(opcode);
  mk_len   = StrLen(marker);

  for (i = 0; i + op_len <= text_len; ++i) {
    if (StrNCmp(text + i, opcode, op_len) != 0) continue;
    // Found the opcode at position i. The marker must
    // occur AFTER i on the same line.
    I64 k = i + op_len;
    while (k + mk_len <= text_len) {
      // Bail out if we cross a newline before finding the marker.
      // A newline is any of 0x0A ('\n') or 0x0D ('\r').
      Bool crossed_newline = FALSE;
      for (I64 s = i + op_len; s < k; ++s) {
        if (text[s] == 0x0A || text[s] == 0x0D) {
          crossed_newline = TRUE;
          break;
        }
      }
      if (crossed_newline) break;
      if (StrNCmp(text + k, marker, mk_len) == 0) return TRUE;
      k++;
    }
  }
  return FALSE;
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
        && GepDynamicI8Shape(emitted)
        && Contains(emitted, "load i8, ptr %")) {
      // Row 04: uses the same GepDynamicI8Shape() helper as
      // --predicate-selftest case C. A constant-index fixture
      // (e.g. "ptr %0, i64 2") is now correctly rejected
      // because GepDynamicI8Shape requires the literal
      // ", i64 %" infix followed by digits.
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
    // Row 07: legacy regex was
    //   grep -qE 'getelementptr i8, ptr %[0-9]+, i64 %[0-9]+'
    // which is exactly the same acceptance set as
    // GepDynamicI8Shape(). Same helper used here and in
    // --predicate-selftest case C.
    if (GepDynamicI8Shape(emitted))
      VerdictPass(v, "ReadAt emitted getelementptr i8, ptr %base, i64 %index");
    else
      VerdictFail(v, "ReadAt emitted getelementptr i8, ptr %base, i64 %index",
                  "missing expected GEP shape");
    // Row 08: legacy regex was
    //   grep -qE 'load i8, ptr %gep_i8'
    // which requires the specific SSA-value name "%gep_i8"
    // (not just any SSA value). A helper that collapsed
    // this to "load i8, ptr %" would falsely accept
    // unrelated load patterns.
    if (Contains(emitted, "load i8, ptr %gep_i8"))
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

  // Rows 26 / 27 / 28: the legacy Bash semantics required
  // the (REJECTED) / (SUPPORTED) marker to be on the SAME
  // line as the opcode name in the cap-verifier output.
  // The whole-file Contains() pair used by the C1 harness
  // collapsed this binding and accepted fixtures where
  // the marker was on a different line.
  //
  // LineContainsOpcodeMarker() is the pure-local helper
  // that binds the legacy regex semantically: the marker
  // must occur after the opcode, on the same line, with
  // no intervening newline.
  if (LineContainsOpcodeMarker(cap_txt, "IR_GEP", "(REJECTED)")) {
    VerdictPass(v, "IR_GEP = REJECTED (sibling opcode still rejected)");
  } else {
    VerdictFail(v, "IR_GEP = REJECTED (sibling opcode still rejected)",
                "IR_GEP not REJECTED");
  }
  if (LineContainsOpcodeMarker(cap_txt, "IR_LEA", "(REJECTED)")) {
    VerdictPass(v, "IR_LEA = REJECTED (sibling opcode still rejected)");
  } else {
    VerdictFail(v, "IR_LEA = REJECTED (sibling opcode still rejected)",
                "IR_LEA not REJECTED");
  }
  if (LineContainsOpcodeMarker(cap_txt, "IR_IADD", "(SUPPORTED)")) {
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
// Option-B scratch lifecycle (C1.2 contract).
//
// Ownership model:
//   - The CALLER owns --scratch=<root>.
//   - The harness owns a unique per-run child directory
//     beneath <root>.
//   - The harness redirects every transient artifact
//     into <root>/<child>.
//   - The harness verifies, BEFORE any rm -rf, that the
//     child path satisfies the containment precondition
//     (see ContainmentVerify below). If the precondition
//     fails the harness halts with
//     HALT_P1_CONTAINMENT_UNVERIFIED and does NOT issue
//     rm -rf.
//   - The harness deletes <root>/<child> ONLY. The
//     caller's <root> survives.
// ------------------------------------------------------------

Bool ContainmentVerify(U8 *root, U8 *child)
{
  I64 rl, cl;
  if (root == NULL || child == NULL) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: root or child is NULL\n";
    return FALSE;
  }
  rl = StrLen(root);
  cl = StrLen(child);
  if (rl == 0) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: empty root\n";
    return FALSE;
  }
  if (cl == 0) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: empty child\n";
    return FALSE;
  }
  if (cl <= rl) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: child len <= root len (root=%s child=%s)\n",
      root, child;
    return FALSE;
  }
  if (StrNCmp(child, root, rl) != 0) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: child does not start with root (root=%s child=%s)\n",
      root, child;
    return FALSE;
  }
  if (child[rl] != '/') {
    "HALT_P1_CONTAINMENT_UNVERIFIED: missing '/' boundary (root=%s child=%s)\n",
      root, child;
    return FALSE;
  }
  if (child[rl + 1] == 0) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: empty suffix (root=%s child=%s)\n",
      root, child;
    return FALSE;
  }
  return TRUE;
}

Bool HaltIfNotContained(U8 *root, U8 *child)
{
  if (!ContainmentVerify(root, child)) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: refusing destructive op on %s (root=%s)\n",
      child, root;
    return FALSE;
  }
  return TRUE;
}

U8 *MakeOptionBScratchChild(U8 *root)
{
  I64 pid = getpid();
  I64 tick = 0;
  for (I64 i = 0; i < pid; ++i) tick = (tick * 1103515245 + 12345) & 0x7FFFFFFF;
  U8 *child = StrPrint(NULL, "%s/run-%d-%d", root, pid, tick & 0xFFFFFF);
  return child;
}

// MkDirpRecursive(path) -> Bool
//
// Implements `mkdir -p <path>` using direct libc mkdir(2)
// syscall only. Walks path byte by byte, creating each
// intermediate directory. If the final directory already
// exists this returns TRUE (idempotent). Returns FALSE on
// any underlying syscall failure.
//
// No subprocess is spawned. This avoids the (intermittent)
// SIGBUS observed under repeated SpawnAndCapture invocations
// on this hcc build, while keeping the harness on the
// direct-syscall / direct-argv path that the harness
// architecture already documents.

Bool MkDirpRecursive(U8 *path)
{
  I64 n, i;
  I8 *tmp;
  I32 rc;

  if (path == NULL) return FALSE;
  n = StrLen(path);
  if (n == 0) return FALSE;
  tmp = MAlloc(n + 1);
  for (i = 0; i < n; ++i) {
    tmp[i] = path[i];
    if (path[i] == '/' && i > 0) {
      tmp[i] = 0;
      mkdir(tmp, 0x1FF);
      tmp[i] = '/';
    }
  }
  tmp[n] = 0;
  rc = mkdir(tmp, 0x1FF);
  Free(tmp);
  // EEXIST is success for mkdir -p semantics.
  if (rc == 0) return TRUE;
  if (*Errno() == 17 /* EEXIST */) return TRUE;
  return FALSE;
}

// RmrRecursive(path) -> Bool
//
// Implements `rm -rf <path>` using direct libc opendir /
// readdir / unlink / rmdir syscalls. Walks the tree depth
// first; unlinks files, removes directories after their
// contents are gone. Returns FALSE only on a hard syscall
// failure; ENOENT (path does not exist) returns TRUE.
//
// No subprocess is spawned. See MkDirpRecursive for
// rationale.

Bool RmrRecursive(U8 *path)
{
  cDIR *d;
  Dirent *ent;
  U8 *child;
  I64 cl;

  if (path == NULL) return FALSE;
  d = opendir(path);
  if (d == NULL) {
    if (*Errno() == 2 /* ENOENT */) return TRUE;
    return FALSE;
  }
  while ((ent = readdir(d)) != NULL) {
    U8 *nm = ent->name;
    if (nm[0] == '.' && nm[1] == 0) continue;
    if (nm[0] == '.' && nm[1] == '.' && nm[2] == 0) continue;
    cl = StrLen(path) + 1 + StrLen(nm);
    child = MAlloc(cl + 1);
    StrPrint(child, "%s/%s", path, nm);
    Fstat st;
    if (Stat(&st, child) == 0) {
      if ((st.st_mode & 0xF000) == 0x4000) {
        if (!RmrRecursive(child)) {
          Free(child);
          closedir(d);
          return FALSE;
        }
      } else {
        if (unlink(child) != 0) {
          Free(child);
          closedir(d);
          return FALSE;
        }
      }
    }
    Free(child);
  }
  closedir(d);
  if (rmdir(path) != 0) {
    if (*Errno() == 2 /* ENOENT */) return TRUE;
    return FALSE;
  }
  return TRUE;
}

Bool DeleteOptionBChild(U8 *root, U8 *child)
{
  if (!HaltIfNotContained(root, child)) return FALSE;

  // Use direct libc unlink/rmdir in a recursive walk
  // instead of SpawnAndCapture("/bin/rm", ...). The
  // spawn path is exercised heavily by the rest of the
  // harness; keeping housekeeping (mkdir/rm) on direct
  // syscalls also avoids the (intermittent) SIGBUS
  // observed under repeated SpawnAndCapture invocations
  // on this hcc build. The direct-argv constraint is
  // unaffected because no subprocess is spawned here.
  if (!RmrRecursive(child)) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: recursive delete of %s failed\n",
      child;
    return FALSE;
  }
  return TRUE;
}

Bool EnsureOptionBParent(U8 *root)
{
  if (FileExists(root)) return TRUE;
  // Use direct libc mkdir(2) via MkDirpRecursive
  // instead of SpawnAndCapture("/bin/mkdir", ...). See
  // the rationale on DeleteOptionBChild above.
  if (!MkDirpRecursive(root)) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: mkdir -p %s failed\n",
      root;
    return FALSE;
  }
  return TRUE;
}

// ------------------------------------------------------------
// --predicate-selftest mode (C1.2 contract).
//
// Walks the seven committed RED fixtures through the SAME
// helpers used by the production 30-row run, and asserts
// the expected per-fixture verdict. Exits 0 if every
// case matches its expected verdict; non-zero with
// SELFTEST_FAIL line otherwise.
// ------------------------------------------------------------

I32 RunPredicateSelfTest(U8 *evidence_dir)
{
  I32 fails = 0;
  U8 *fixed_dir = StrPrint(NULL,
    "%s/ACT-POLYC-TOOLING-MIGRATE-GEP01/correction01/red",
    evidence_dir);

  // Case A: GepDynamicI8Shape rejects constant-index.
  U8 *pathA = StrPrint(NULL, "%s/read-at-malformed.ll", fixed_dir);
  I64 szA = 0;
  U8 *txtA = SlurpFile(pathA, &szA);
  Bool expA = FALSE;
  Bool gotA = GepDynamicI8Shape(txtA);
  if (gotA != expA) {
    "SELFTEST_FAIL case=A fixture=read-at-malformed.ll expected=%d got=%d\n",
      expA, gotA;
    fails++;
  } else {
    "SELFTEST_PASS case=A fixture=read-at-malformed.ll expected=%d got=%d\n",
      expA, gotA;
  }
  BytewiseFree(txtA); Free(pathA);

  // Case B: GepDynamicI8Shape rejects symbolic-base.
  U8 *pathB = StrPrint(NULL, "%s/read-at-symbolic-base.ll", fixed_dir);
  I64 szB = 0;
  U8 *txtB = SlurpFile(pathB, &szB);
  Bool expB = FALSE;
  Bool gotB = GepDynamicI8Shape(txtB);
  if (gotB != expB) {
    "SELFTEST_FAIL case=B fixture=read-at-symbolic-base.ll expected=%d got=%d\n",
      expB, gotB;
    fails++;
  } else {
    "SELFTEST_PASS case=B fixture=read-at-symbolic-base.ll expected=%d got=%d\n",
      expB, gotB;
  }
  BytewiseFree(txtB); Free(pathB);

  // Case C: GepDynamicI8Shape accepts genuine.
  U8 *pathC = StrPrint(NULL, "%s/read-at-genuine.ll", fixed_dir);
  I64 szC = 0;
  U8 *txtC = SlurpFile(pathC, &szC);
  Bool expC = TRUE;
  Bool gotC = GepDynamicI8Shape(txtC);
  if (gotC != expC) {
    "SELFTEST_FAIL case=C fixture=read-at-genuine.ll expected=%d got=%d\n",
      expC, gotC;
    fails++;
  } else {
    "SELFTEST_PASS case=C fixture=read-at-genuine.ll expected=%d got=%d\n",
      expC, gotC;
  }
  BytewiseFree(txtC); Free(pathC);

  // Row 08 case: read-at-malformed.ll is the SAME malformed
  // fixture. The row-08 production predicate is
  //   Contains(t, "load i8, ptr %gep_i8")
  // and read-at-malformed.ll does NOT contain "%gep_i8"
  // (its load uses a different SSA name), so the
  // predicate MUST reject it. This case proves that the
  // row-08 helper is not collapsed to "load i8, ptr %".
  U8 *txtA2 = SlurpFile(StrPrint(NULL, "%s/read-at-malformed.ll", fixed_dir),
                        &szA);
  Bool expR08 = FALSE;
  Bool gotR08 = (txtA2 != NULL
                 && Contains(txtA2, "load i8, ptr %gep_i8"));
  if (gotR08 != expR08) {
    "SELFTEST_FAIL row=08 fixture=read-at-malformed.ll expected=%d got=%d\n",
      expR08, gotR08;
    fails++;
  } else {
    "SELFTEST_PASS row=08 fixture=read-at-malformed.ll expected=%d got=%d\n",
      expR08, gotR08;
  }
  BytewiseFree(txtA2);

  // Rows 26/27/28: cap-malformed.txt has opcode and
  // (REJECTED)/(SUPPORTED) markers on SEPARATE lines.
  // LineContainsOpcodeMarker MUST reject all three.
  U8 *pathCap = StrPrint(NULL, "%s/cap-malformed.txt", fixed_dir);
  I64 szCap = 0;
  U8 *txtCap = SlurpFile(pathCap, &szCap);
  Bool expR26 = FALSE;
  Bool gotR26 = LineContainsOpcodeMarker(txtCap, "IR_GEP", "(REJECTED)");
  if (gotR26 != expR26) {
    "SELFTEST_FAIL row=26 fixture=cap-malformed.txt expected=%d got=%d\n",
      expR26, gotR26;
    fails++;
  } else {
    "SELFTEST_PASS row=26 fixture=cap-malformed.txt expected=%d got=%d\n",
      expR26, gotR26;
  }
  Bool expR27 = FALSE;
  Bool gotR27 = LineContainsOpcodeMarker(txtCap, "IR_LEA", "(REJECTED)");
  if (gotR27 != expR27) {
    "SELFTEST_FAIL row=27 fixture=cap-malformed.txt expected=%d got=%d\n",
      expR27, gotR27;
    fails++;
  } else {
    "SELFTEST_PASS row=27 fixture=cap-malformed.txt expected=%d got=%d\n",
      expR27, gotR27;
  }
  Bool expR28 = FALSE;
  Bool gotR28 = LineContainsOpcodeMarker(txtCap, "IR_IADD", "(SUPPORTED)");
  if (gotR28 != expR28) {
    "SELFTEST_FAIL row=28 fixture=cap-malformed.txt expected=%d got=%d\n",
      expR28, gotR28;
    fails++;
  } else {
    "SELFTEST_PASS row=28 fixture=cap-malformed.txt expected=%d got=%d\n",
      expR28, gotR28;
  }
  BytewiseFree(txtCap); Free(pathCap);

  Free(fixed_dir);

  if (fails == 0) {
    "PREDICATE_SELFTEST_RC=0 (7 of 7 cases passed)\n";
    return 0;
  } else {
    "PREDICATE_SELFTEST_RC=%d (fails=%d)\n", 1, fails;
    return 1;
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
  U8 *scratch_root = ArgValue(argc, argv, "--scratch",
                              "build/quality/gep01");
  U8 *evidence_dir = ArgValue(argc, argv, "--evidence-dir",
                              "evidence");
  Bool seed        = ArgFlag(argc, argv, "--mode=fail");
  Bool selftest    = ArgFlag(argc, argv, "--predicate-selftest");

  // --predicate-selftest: run the seven-case selftest against
  // committed RED fixtures via the SAME helpers used by the
  // production 30-row run, and exit. No toolchain, no scratch,
  // no live run. Per ACT-POLYC-TOOLING-MIGRATE-GEP01-
  // CORRECTION01 §3.2 contract.
  if (selftest) {
    "=== predicate-selftest mode ===\n";
    return RunPredicateSelfTest(evidence_dir);
  }

  // Resolve bare tool names against $PATH. If a flag already
  // contains a "/" the resolver returns the path verbatim.
  U8 *llvm_as  = ResolveTool(llvm_as_name);
  U8 *llvm_opt = ResolveTool(llvm_opt_name);
  U8 *python   = ResolveTool(python_name);

  // Option-B scratch lifecycle: caller owns --scratch root;
  // harness owns a unique per-run child beneath it; only
  // the child is deleted at the end.
  if (!EnsureOptionBParent(scratch_root)) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: cannot prepare scratch root %s\n",
      scratch_root;
    return 2;
  }
  U8 *scratch_child = MakeOptionBScratchChild(scratch_root);
  if (!FileExists(scratch_child)) {
    MkDirpRecursive(scratch_child);
  }

  TestVerdict *v = VerdictNew();

  "=== ACT-POLYC-TOOLING-MIGRATE-GEP01 PolyC harness ===\n";
  "hcc           = %s\n", hcc_path;
  "install_dir   = %s\n", install_dir;
  "llvm_as       = %s\n", llvm_as;
  "llvm_opt      = %s\n", llvm_opt;
  "python        = %s\n", python;
  "scratch_root  = %s\n", scratch_root;
  "scratch_child = %s\n", scratch_child;
  if (seed) "seed-failure = YES\n";
  else      "seed-failure = no\n";
  "\n";

  RunToolchain(v, hcc_path, llvm_as, llvm_opt, python);

  if (v->fail == 0) {
    RunPositives(v, hcc_path, install_dir, scratch_child, seed);
    RunLlvmAsOpt(v, llvm_as, llvm_opt, scratch_child);
    RunFences(v, scratch_child);
    RunNegative(v, hcc_path, install_dir, scratch_child);
    RunCapability(v, python, scratch_child);
    RunDeterminism(v, hcc_path, install_dir, scratch_child);
  }

  VerdictSummary(v);
  I64 rc = VerdictRc(v);

  // Option-B teardown: delete the harness-owned child only.
  // Caller's scratch_root survives. ContainmentVerify is
  // enforced by DeleteOptionBChild before /bin/rm is invoked.
  if (!DeleteOptionBChild(scratch_root, scratch_child)) {
    "HALT_P1_CONTAINMENT_UNVERIFIED: cannot clean child %s\n",
      scratch_child;
    if (rc == 0) rc = 3;
  }

  Free(v);
  Free(llvm_as); Free(llvm_opt); Free(python);
  Free(scratch_child);
  return rc;
}
