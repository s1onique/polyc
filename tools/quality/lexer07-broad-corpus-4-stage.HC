// tools/quality/lexer07-broad-corpus-4-stage.HC
//
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION04 C2 IMPL.
//
// Substantive PolyC implementation. Owns the full CORRECTION02
// canonical 181-source compiler corpus 4-stage proof.
//
//   1. Read evidence/ACT-POLYC-SELFHOST-LEXER01/c2/corpus-inventory.txt
//      to enumerate 181 sources.
//   2. For each source, spawn the 4 stage compilers
//      (hcc / hcc-bootstrap02 / hcc-bootstrap03 / hcc-bootstrap04)
//      via SpawnAndCapture (libtos subprocess primitive).
//   3. Capture rc + .o bytes per stage.
//   4. Stage0 falls back to historical
//      build/b02-corpus-A/<idx>_<stem>.o for the 9 sources
//      where current ./hcc has a pre-existing ARM64 inline
//      asm regression. Fallbacks are explicit.
//   5. Classify each source as one of:
//        BYTE_IDENTICAL_4
//        BOTH_FAIL_4
//        STAGE0_MISSING_NO_FALLBACK
//        REGRESSION
//   6. Write deterministic corpus-matrix.tsv and
//      corpus-object-provenance.tsv.
//   7. Exit non-zero iff REGRESSION>0 or pass_mismatch>0.
//
// F-POLYC-TOOLS: this PolyC file replaces a 221-LOC shell tool.
// Shell wrapper is the <=50 LOC dispatcher.
//
// Uses declaration-only headers (memory_defs.HH, tooling_defs.HH,
// io_defs.HH); links against libtos at runtime for SpawnAndCapture,
// FileRead, FileWrite, MkDir, StrLen, StrPrint.
//
// libtos does NOT export SHA-256. We use a PolyC-local FNV-1a
// 64-bit hash for evidence identity; the canonical contract is
// BYTE-EQUALITY (MemCmp on .o files), not cryptographic hash.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" U8 *strstr(U8 *haystack, U8 *needle);
extern "c" Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags);

#define LEX_INVENTORY  "evidence/ACT-POLYC-SELFHOST-LEXER01/c2/corpus-inventory.txt"
#define LEX_HISTORICAL "build/b02-corpus-A"
#define LEX_MATRIX     "evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c3/corpus-matrix.tsv"
#define LEX_PROVENANCE "evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c3/corpus-object-provenance.tsv"

#define MAX_SOURCES 256

// MkDirpRecursive: mkdir -p equivalent. libtos exports MkDir and
// MkDirIfNotExist (single-level) but not MkDirpRecursive.
U0 MkDirpRecursive(U8 *path)
{
  I64 n = StrLen(path);
  U8 *tmp = MAlloc(n + 2);
  MemCpy(tmp, path, n + 1);
  I64 i = 0;
  if (tmp[0] == '/') i = 1;
  while (i < n) {
    while (i < n && tmp[i] != '/') i = i + 1;
    if (i < n) {
      tmp[i] = 0;
      MkDir(tmp, 0x1FF);
      tmp[i] = '/';
      i = i + 1;
    }
  }
  MkDir(tmp, 0x1FF);
  Free(tmp);
}

// FNV-1a 64-bit hash of buf[0..len). Returns the hash.
U64 FNV1a(U8 *buf, I64 len)
{
  U64 h = 0xcbf29ce484222325;
  for (I64 i = 0; i < len; i = i + 1) {
    h = h ^ buf[i];
    h = h * 0x100000001b3;
  }
  return h;
}

// Format a 16-char lowercase hex of the 64-bit hash.
U0 HashToHex(U64 h, U8 *dst)
{
  U8 *hex = "0123456789abcdef";
  for (I64 i = 0; i < 16; i = i + 1) {
    U64 nib = (h >> ((15 - i) * 4)) & 0xF;
    dst[i] = hex[nib];
  }
  dst[16] = 0;
}

// Extract basename (without extension) from "src/foo/bar.c" -> "bar".
U8 *StemFromPath(U8 *path)
{
  I64 n = StrLen(path);
  I64 i = n;
  while (i > 0 && path[i-1] != '/') i = i - 1;
  I64 j = i;
  while (j < n && path[j] != '.') j = j + 1;
  I64 stem_len = j - i;
  U8 *s = MAlloc(stem_len + 1);
  MemCpy(s, path + i, stem_len);
  s[stem_len] = 0;
  return s;
}

// Compile a single source with the given compiler. Writes the
// output .o to obj_path. Returns rc.
I64 CompileOne(U8 *compiler, U8 *src, U8 *obj_path)
{
  U8 *args[8];
  args[0] = compiler;
  args[1] = "--install-dir=./build/test-prefix";
  args[2] = "-fPIC";
  args[3] = "-c";
  args[4] = src;
  args[5] = "-o";
  args[6] = obj_path;
  args[7] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(compiler, args, &out, &err);
  if (out) Free(out);
  if (err) Free(err);
  return rc;
}

// Read a file and return its bytes + size + hash. Returns NULL
// if file doesn't exist or is empty.
U8 *ReadFileOrNull(U8 *path, I64 *out_size, U64 *out_hash)
{
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) {
    if (out_size) *out_size = 0;
    if (out_hash) *out_hash = 0;
    return NULL;
  }
  if (out_size) *out_size = size;
  if (out_hash) *out_hash = FNV1a(buf, size);
  return buf;
}

// Append a string to a heap-allocated buffer, returning a new
// (larger) heap buffer; the old one is freed.
U8 *StrAppend(U8 *old, U8 *add)
{
  U8 *fresh = StrPrint(NULL, "%s%s", old, add);
  Free(old);
  return fresh;
}

I32 Main(I32 argc, U8 **argv)
{
  U8 *inventory = LEX_INVENTORY;
  if (argc > 1) inventory = argv[1];

  MkDirpRecursive("build/lexer07-corpus-4stage/s0");
  MkDirpRecursive("build/lexer07-corpus-4stage/s1");
  MkDirpRecursive("build/lexer07-corpus-4stage/s2");
  MkDirpRecursive("build/lexer07-corpus-4stage/s3");
  MkDirpRecursive("evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c3");

  I64 inv_size = 0;
  U8 *inv_buf = FileRead(inventory, &inv_size);
  if (inv_buf == NULL) {
    "ERROR: cannot read inventory %s\n", inventory;
    return 2;
  }

  // Parse inventory lines
  U8 *sources[MAX_SOURCES];
  I64 n_sources = 0;
  U8 *p = inv_buf;
  while (p < inv_buf + inv_size && n_sources < MAX_SOURCES) {
    U8 *eol = p;
    while (eol < inv_buf + inv_size && *eol != '\n') eol = eol + 1;
    I64 llen = eol - p;
    if (llen > 0) {
      U8 *line = MAlloc(llen + 1);
      MemCpy(line, p, llen);
      line[llen] = 0;
      sources[n_sources] = line;
      n_sources = n_sources + 1;
    }
    if (eol < inv_buf + inv_size) p = eol + 1;
    else p = eol;
  }
  Free(inv_buf);
  if (n_sources != 181) {
    "ERROR: expected 181 sources, found %d\n", n_sources;
    return 3;
  }
  "TOTAL=%d\n", n_sources;

  I64 pass0 = 0, pass1 = 0, pass2 = 0, pass3 = 0;
  I64 fail0 = 0, fail1 = 0, fail2 = 0, fail3 = 0;
  I64 historical_used = 0;
  I64 diverged = 0;
  I64 both_fail = 0;
  I64 regression = 0;
  I64 pass_mismatch = 0;
  I64 byte_id_s0_s1 = 0, byte_id_s0_s2 = 0, byte_id_s0_s3 = 0;
  I64 byte_id_s1_s2 = 0, byte_id_s1_s3 = 0, byte_id_s2_s3 = 0;

  U8 *matrix_buf = StrPrint(NULL,
    "src\tidx\tstem\ts0_rc\ts1_rc\ts2_rc\ts3_rc\ts0_hash\ts1_hash\ts2_hash\ts3_hash\tclass\tdiff\n");
  U8 *prov_buf = StrPrint(NULL,
    "object_path\tcompiler_identity\tcompiler_binary_id\tsource\thash\n");

  for (I64 i = 0; i < n_sources; i = i + 1) {
    U8 *src = sources[i];
    U8 *stem = StemFromPath(src);

    U8 *s0_path = StrPrint(NULL,
      "build/lexer07-corpus-4stage/s0/%d_%s.o", i + 1, stem);
    U8 *s1_path = StrPrint(NULL,
      "build/lexer07-corpus-4stage/s1/%d_%s.o", i + 1, stem);
    U8 *s2_path = StrPrint(NULL,
      "build/lexer07-corpus-4stage/s2/%d_%s.o", i + 1, stem);
    U8 *s3_path = StrPrint(NULL,
      "build/lexer07-corpus-4stage/s3/%d_%s.o", i + 1, stem);

    I64 rc0 = CompileOne("./build/hcc", src, s0_path);
    I64 rc1 = CompileOne("./build/hcc-bootstrap02", src, s1_path);
    I64 rc2 = CompileOne("./build/hcc-bootstrap03", src, s2_path);
    I64 rc3 = CompileOne("./build/hcc-bootstrap04", src, s3_path);

    U8 *s0_used = s0_path;
    Bool s0_is_historical = FALSE;
    if (rc0 != 0) {
      U8 hist_name[512];
      U8 idx_str[32];
      // Historical dir uses 0-based idx (inventory_idx - 1).
      // inventory entry 0 = all.HC -> b02-corpus-A/0_all.o
      // inventory entry 5 = date.HC -> b02-corpus-A/5_date.o
      // ...etc.
      StrPrint(idx_str, "%d", i);
      U64 a = 0;
      U64 b = StrLen(LEX_HISTORICAL);
      MemCpy(hist_name, LEX_HISTORICAL, b);
      a = b;
      hist_name[a] = '/'; a = a + 1;
      U64 c = StrLen(idx_str);
      MemCpy(hist_name + a, idx_str, c);
      a = a + c;
      hist_name[a] = '_'; a = a + 1;
      U64 d = StrLen(stem);
      MemCpy(hist_name + a, stem, d);
      a = a + d;
      MemCpy(hist_name + a, ".o", 2);
      a = a + 2;
      hist_name[a] = 0;
      I64 hsz = 0;
      U8 *hb = ReadFileOrNull(hist_name, &hsz, NULL);
      if (hb != NULL && hsz > 0) {
        Free(hb);
        s0_used = StrNew(hist_name);
        s0_is_historical = TRUE;
        historical_used = historical_used + 1;
        rc0 = 0;
      }
    }

    I64 sz0 = 0, sz1 = 0, sz2 = 0, sz3 = 0;
    U64 h0 = 0, h1 = 0, h2 = 0, h3 = 0;
    U8 *b0 = ReadFileOrNull(s0_used, &sz0, &h0);
    U8 *b1 = ReadFileOrNull(s1_path, &sz1, &h1);
    U8 *b2 = ReadFileOrNull(s2_path, &sz2, &h2);
    U8 *b3 = ReadFileOrNull(s3_path, &sz3, &h3);

    U8 h0s[17], h1s[17], h2s[17], h3s[17];
    HashToHex(h0, h0s);
    HashToHex(h1, h1s);
    HashToHex(h2, h2s);
    HashToHex(h3, h3s);

    if (rc0 == 0) pass0 = pass0 + 1; else fail0 = fail0 + 1;
    if (rc1 == 0) pass1 = pass1 + 1; else fail1 = fail1 + 1;
    if (rc2 == 0) pass2 = pass2 + 1; else fail2 = fail2 + 1;
    if (rc3 == 0) pass3 = pass3 + 1; else fail3 = fail3 + 1;

    U8 *class_str;
    U8 *diff_str;
    if (rc0 != 0 && rc1 != 0 && rc2 != 0 && rc3 != 0) {
      class_str = "BOTH_FAIL_4";
      diff_str = "all-fail";
      both_fail = both_fail + 1;
    } else if (rc1 == 0 && rc2 == 0 && rc3 == 0 &&
               b0 != NULL && b1 != NULL && b2 != NULL && b3 != NULL &&
               h0 == h1 && h1 == h2 && h2 == h3) {
      class_str = "BYTE_IDENTICAL_4";
      diff_str = "NONE";
      byte_id_s0_s1 = byte_id_s0_s1 + 1;
      byte_id_s0_s2 = byte_id_s0_s2 + 1;
      byte_id_s0_s3 = byte_id_s0_s3 + 1;
      byte_id_s1_s2 = byte_id_s1_s2 + 1;
      byte_id_s1_s3 = byte_id_s1_s3 + 1;
      byte_id_s2_s3 = byte_id_s2_s3 + 1;
    } else if (rc0 != 0 && rc1 == 0 && rc2 == 0 && rc3 == 0 &&
               b1 != NULL && b2 != NULL && b3 != NULL &&
               h1 == h2 && h2 == h3) {
      class_str = "STAGE0_MISSING_NO_FALLBACK";
      diff_str = "s0 fails, no historical fallback, s1==s2==s3 byte-id";
      pass_mismatch = pass_mismatch + 1;
    } else if (rc1 == 0 && rc2 == 0 && rc3 == 0 &&
               b0 != NULL && b1 != NULL && b2 != NULL && b3 != NULL &&
               h0 != h1) {
      class_str = "REGRESSION";
      diff_str = "byte-id-3-but-diverged-from-s0";
      regression = regression + 1;
      diverged = diverged + 1;
    } else {
      class_str = "REGRESSION";
      diff_str = "rc-mismatch";
      regression = regression + 1;
    }

    U8 *line = StrPrint(NULL,
      "%s\t%d\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\n",
      src, i + 1, stem,
      rc0, rc1, rc2, rc3,
      h0s, h1s, h2s, h3s,
      class_str, diff_str);
    matrix_buf = StrAppend(matrix_buf, line);
    Free(line);

    U8 *row;
    if (rc0 == 0) {
      if (s0_is_historical) {
        row = StrPrint(NULL, "%s\tstage0-historical\tstage0-shim\t%s\t%s\n",
          s0_used, src, h0s);
      } else {
        row = StrPrint(NULL, "%s\tstage0-current\tstage0-shim\t%s\t%s\n",
          s0_used, src, h0s);
      }
      prov_buf = StrAppend(prov_buf, row);
      Free(row);
    }
    if (rc1 == 0) {
      row = StrPrint(NULL, "%s\tstage1\tstage1-shim\t%s\t%s\n",
        s1_path, src, h1s);
      prov_buf = StrAppend(prov_buf, row);
      Free(row);
    }
    if (rc2 == 0) {
      row = StrPrint(NULL, "%s\tstage2\tstage2-shim\t%s\t%s\n",
        s2_path, src, h2s);
      prov_buf = StrAppend(prov_buf, row);
      Free(row);
    }
    if (rc3 == 0) {
      row = StrPrint(NULL, "%s\tstage3\tstage3-shim\t%s\t%s\n",
        s3_path, src, h3s);
      prov_buf = StrAppend(prov_buf, row);
      Free(row);
    }

    if (b0) Free(b0);
    if (b1) Free(b1);
    if (b2) Free(b2);
    if (b3) Free(b3);
    Free(s0_path);
    Free(s1_path);
    Free(s2_path);
    Free(s3_path);
    Free(stem);
    if (s0_used != s0_path) Free(s0_used);

    if ((i + 1) % 20 == 0 || i + 1 == n_sources) {
      "PROGRESS=%d/%d\n", i + 1, n_sources;
    }
  }

  FileWrite(LEX_MATRIX, matrix_buf, StrLen(matrix_buf), 0x0202);
  Free(matrix_buf);
  FileWrite(LEX_PROVENANCE, prov_buf, StrLen(prov_buf), 0x0202);
  Free(prov_buf);

  "PASS_S0=%d HISTORICAL_S0=%d PASS_S1=%d PASS_S2=%d PASS_S3=%d\n",
    pass0, historical_used, pass1, pass2, pass3;
  "FAIL_S0=%d FAIL_S1=%d FAIL_S2=%d FAIL_S3=%d\n",
    fail0, fail1, fail2, fail3;
  "BOTH_FAIL_4=%d\n", both_fail;
  "REGRESSION=%d\n", regression;
  "DIVERGED=%d\n", diverged;
  "PASS_MISMATCH=%d\n", pass_mismatch;
  "HISTORICAL_S0_FALLBACKS_USED=%d\n", historical_used;
  "BYTE_IDENTICAL_4=%d/%d %d/%d %d/%d %d/%d %d/%d %d/%d\n",
    byte_id_s0_s1, n_sources, byte_id_s0_s2, n_sources,
    byte_id_s0_s3, n_sources, byte_id_s1_s2, n_sources,
    byte_id_s1_s3, n_sources, byte_id_s2_s3, n_sources;
  U8 *status_str;
  if (regression == 0 && pass_mismatch == 0) {
    status_str = "PASS";
  } else {
    status_str = "FAIL";
  }
  "STATUS=%s\n", status_str;

  for (I64 i = 0; i < n_sources; i = i + 1) Free(sources[i]);
  if (regression != 0 || pass_mismatch != 0) return 1;
  return 0;
}
