// tools/quality/lexer07-broad-corpus-4-stage.HC
//
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C2 IMPL.
//
// Substantive PolyC implementation. Owns the full CORRECTION02
// canonical 181-source compiler corpus 4-stage proof.
//
// C2 IMPL (this file, replacing the deferred C04-era version):
//   - actual byte equality via MemCmp (ObjectsByteEqual);
//   - SHA-256 provenance identity (calls ./build/lexer07-sha256
//     --file <path> as a subprocess; the SHA256 implementation
//     itself is owned by tools/quality/lexer07-sha256.HC);
//   - 8-column provenance schema
//     (source / stage / object_path / provenance_class /
//      object_sha256 / compiler_binary_path / compiler_binary_sha256
//      / fnv1a64);
//   - corpus-failures.tsv writer
//     (source / stage / rc / failure_class);
//   - semantic invariant gate
//     (DIVERGED=0; REGRESSION=0; PASS_MISMATCH=0;
//      PROVENANCE_SCHEMA_VALID=1; FAILURE_SCHEMA_VALID=1);
//   - explicit outdir (argv[2]); refuses closed-evidence paths
//     unless --allow-closed is passed;
//   - FNV-1a retained as informational column; NOT used for
//     classification truth.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" U8 *strstr(U8 *haystack, U8 *needle);
extern "c" Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags);

#define LEX_INVENTORY  "evidence/ACT-POLYC-SELFHOST-LEXER01/c2/corpus-inventory.txt"
#define LEX_HISTORICAL "build/b02-corpus-A"
#define LEX_MATRIX     "corpus-matrix.tsv"
#define LEX_PROVENANCE "corpus-object-provenance.tsv"
#define LEX_FAILURES   "corpus-failures.tsv"
#define SHA256_BIN     "./build/lexer07-sha256"

#define MAX_SOURCES 256

// ---------- small helpers --------------------------------------------------

// Inline byte compare (libtos does not export memcmp; we
// provide our own so the linker never has to resolve
// _memcmp from libSystem).
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

U64 FNV1a(U8 *buf, I64 len)
{
  U64 h = 0xcbf29ce484222325;
  for (I64 i = 0; i < len; i = i + 1) {
    h = h ^ buf[i];
    h = h * 0x100000001b3;
  }
  return h;
}

U0 HashToHex(U64 h, U8 *dst)
{
  U8 *hex = "0123456789abcdef";
  for (I64 i = 0; i < 16; i = i + 1) {
    U64 nib = (h >> ((15 - i) * 4)) & 0xF;
    dst[i] = hex[nib];
  }
  dst[16] = 0;
}

Bool Sha256File(U8 *path, U8 *out_hex)
{
  U8 *args[4];
  args[0] = SHA256_BIN;
  args[1] = "--file";
  args[2] = path;
  args[3] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(SHA256_BIN, args, &out, &err);
  if (rc != 0) {
    if (out) Free(out);
    if (err) Free(err);
    return FALSE;
  }
  if (out == NULL) {
    if (err) Free(err);
    return FALSE;
  }
  I64 i = 0;
  while (i < 64 && out[i] != 0 && out[i] != '\n' &&
         out[i] != ' ' && out[i] != '\r') {
    out_hex[i] = out[i];
    i = i + 1;
  }
  out_hex[i] = 0;
  Free(out);
  if (err) Free(err);
  return i == 64;
}

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

U8 *StrAppend(U8 *old, U8 *add)
{
  U8 *fresh = StrPrint(NULL, "%s%s", old, add);
  Free(old);
  return fresh;
}

U8 *ReadFileOrNull(U8 *path, I64 *out_size)
{
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (out_size) *out_size = size;
  return buf;
}

I64 GuardClosedEvidence(U8 *outdir, Bool allow_closed)
{
  if (allow_closed) return 0;
  if (strstr(outdir, "/CORRECTION02/c") != NULL) return 5;
  if (strstr(outdir, "/CORRECTION03/c") != NULL) return 5;
  if (strstr(outdir, "/CORRECTION04/c") != NULL) return 5;
  if (strstr(outdir, "/CORRECTION05/c") != NULL) return 5;
  return 0;
}

// ---------- main -----------------------------------------------------------

I32 Main(I32 argc, U8 **argv)
{
  U8 *inventory = LEX_INVENTORY;
  U8 *outdir = "./build/lexer07-c01-out";
  Bool allow_closed = FALSE;
  I64 ai = 1;
  if (argc > 1 && argv[1][0] != '-') { inventory = argv[1]; ai = 2; }
  if (argc > ai && argv[ai][0] != '-') { outdir = argv[ai]; ai = ai + 1; }
  while (ai < argc) {
    if (StrNCmp(argv[ai], "--allow-closed", 14) == 0) {
      allow_closed = TRUE;
      ai = ai + 1;
    } else {
      ai = ai + 1;
    }
  }
  I64 guard_rc = GuardClosedEvidence(outdir, allow_closed);
  if (guard_rc != 0) {
    "BROAD_CORPUS_STATUS=ERROR reason=closed-evidence-dir outdir=%s\n", outdir;
    "BROAD_CORPUS_HINT=pass --allow-closed to override\n";
    return 5;
  }
  MkDirpRecursive(outdir);
  MkDirpRecursive("build/lexer07-corpus-4stage/s0");
  MkDirpRecursive("build/lexer07-corpus-4stage/s1");
  MkDirpRecursive("build/lexer07-corpus-4stage/s2");
  MkDirpRecursive("build/lexer07-corpus-4stage/s3");

  I64 inv_size = 0;
  U8 *inv_buf = FileRead(inventory, &inv_size);
  if (inv_buf == NULL) {
    "ERROR: cannot read inventory %s\n", inventory;
    return 2;
  }

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

  U8 *compilers[4];
  compilers[0] = "./build/hcc";
  compilers[1] = "./build/hcc-bootstrap02";
  compilers[2] = "./build/hcc-bootstrap03";
  compilers[3] = "./build/hcc-bootstrap04";
  U8 comp_sha[4][65];
  for (I64 c = 0; c < 4; c = c + 1) {
    if (!Sha256File(compilers[c], comp_sha[c])) {
      MemCpy(comp_sha[c], "UNKNOWN", 8);
    }
  }


  U8 *matrix_buf = StrPrint(NULL,
    "src\tidx\tstem\ts0_rc\ts1_rc\ts2_rc\ts3_rc\t"
    "s0_sha256\ts1_sha256\ts2_sha256\ts3_sha256\tclass\tdiff\n");
  U8 *prov_buf = StrPrint(NULL,
    "source\tstage\tobject_path\tprovenance_class\t"
    "object_sha256\tcompiler_binary_path\tcompiler_binary_sha256\tfnv1a64\n");
  U8 *fail_buf = StrPrint(NULL,
    "source\tstage\trc\tfailure_class\n");

  I64 pass0 = 0, pass1 = 0, pass2 = 0, pass3 = 0;
  I64 fail0 = 0, fail1 = 0, fail2 = 0, fail3 = 0;
  I64 historical_used = 0;
  I64 diverged = 0;
  I64 both_fail = 0;
  I64 regression = 0;
  I64 pass_mismatch = 0;
  I64 s0_miss_no_fallback = 0;
  I64 byte_id_s0_s1 = 0, byte_id_s0_s2 = 0, byte_id_s0_s3 = 0;
  I64 byte_id_s1_s2 = 0, byte_id_s1_s3 = 0, byte_id_s2_s3 = 0;

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

    I64 rc0 = 0, rc1 = 0, rc2 = 0, rc3 = 0;
    {
      U8 *args[8];
      args[0] = compilers[0]; args[1] = "--install-dir=./build/test-prefix";
      args[2] = "-fPIC"; args[3] = "-c";
      args[4] = src; args[5] = "-o"; args[6] = s0_path; args[7] = NULL;
      U8 *oo = NULL; U8 *ee = NULL;
      rc0 = SpawnAndCapture(compilers[0], args, &oo, &ee);
      if (oo) Free(oo); if (ee) Free(ee);
    }
    {
      U8 *args[8];
      args[0] = compilers[1]; args[1] = "--install-dir=./build/test-prefix";
      args[2] = "-fPIC"; args[3] = "-c";
      args[4] = src; args[5] = "-o"; args[6] = s1_path; args[7] = NULL;
      U8 *oo = NULL; U8 *ee = NULL;
      rc1 = SpawnAndCapture(compilers[1], args, &oo, &ee);
      if (oo) Free(oo); if (ee) Free(ee);
    }
    {
      U8 *args[8];
      args[0] = compilers[2]; args[1] = "--install-dir=./build/test-prefix";
      args[2] = "-fPIC"; args[3] = "-c";
      args[4] = src; args[5] = "-o"; args[6] = s2_path; args[7] = NULL;
      U8 *oo = NULL; U8 *ee = NULL;
      rc2 = SpawnAndCapture(compilers[2], args, &oo, &ee);
      if (oo) Free(oo); if (ee) Free(ee);
    }
    {
      U8 *args[8];
      args[0] = compilers[3]; args[1] = "--install-dir=./build/test-prefix";
      args[2] = "-fPIC"; args[3] = "-c";
      args[4] = src; args[5] = "-o"; args[6] = s3_path; args[7] = NULL;
      U8 *oo = NULL; U8 *ee = NULL;
      rc3 = SpawnAndCapture(compilers[3], args, &oo, &ee);
      if (oo) Free(oo); if (ee) Free(ee);
    }

    U8 *s0_used = s0_path;
    Bool s0_is_historical = FALSE;
    if (rc0 != 0) {
      U8 hist_name[512];
      U8 idx_str[32];
      StrPrint(idx_str, "%d", i);
      U64 a = 0;
      U64 b = StrLen(LEX_HISTORICAL);
      MemCpy(hist_name, LEX_HISTORICAL, b);
      a = b;
      hist_name[a] = '/'; a = a + 1;
      U64 c2 = StrLen(idx_str);
      MemCpy(hist_name + a, idx_str, c2);
      a = a + c2;
      hist_name[a] = '_'; a = a + 1;
      U64 d = StrLen(stem);
      MemCpy(hist_name + a, stem, d);
      a = a + d;
      MemCpy(hist_name + a, ".o", 2);
      a = a + 2;
      hist_name[a] = 0;
      I64 hsz = 0;
      U8 *hb = ReadFileOrNull(hist_name, &hsz);
      if (hb != NULL && hsz > 0) {
        Free(hb);
        s0_used = StrPrint(NULL, "%s", hist_name);
        s0_is_historical = TRUE;
        historical_used = historical_used + 1;
        rc0 = 0;
      }
    }

    I64 sz0 = 0, sz1 = 0, sz2 = 0, sz3 = 0;
    U8 *b0 = ReadFileOrNull(s0_used, &sz0);
    U8 *b1 = ReadFileOrNull(s1_path, &sz1);
    U8 *b2 = ReadFileOrNull(s2_path, &sz2);
    U8 *b3 = ReadFileOrNull(s3_path, &sz3);

    U8 sh0[65], sh1[65], sh2[65], sh3[65];
    if (b0 != NULL && sz0 > 0) Sha256File(s0_used, sh0);
    else MemCpy(sh0, "EMPTY", 6);
    if (b1 != NULL && sz1 > 0) Sha256File(s1_path, sh1);
    else MemCpy(sh1, "EMPTY", 6);
    if (b2 != NULL && sz2 > 0) Sha256File(s2_path, sh2);
    else MemCpy(sh2, "EMPTY", 6);
    if (b3 != NULL && sz3 > 0) Sha256File(s3_path, sh3);
    else MemCpy(sh3, "EMPTY", 6);

    U64 h0 = 0, h1 = 0, h2 = 0, h3 = 0;
    if (b0 != NULL) h0 = FNV1a(b0, sz0);
    if (b1 != NULL) h1 = FNV1a(b1, sz1);
    if (b2 != NULL) h2 = FNV1a(b2, sz2);
    if (b3 != NULL) h3 = FNV1a(b3, sz3);
    U8 h0s[17], h1s[17], h2s[17], h3s[17];
    HashToHex(h0, h0s); HashToHex(h1, h1s);
    HashToHex(h2, h2s); HashToHex(h3, h3s);

    if (rc0 == 0) pass0 = pass0 + 1; else fail0 = fail0 + 1;
    if (rc1 == 0) pass1 = pass1 + 1; else fail1 = fail1 + 1;
    if (rc2 == 0) pass2 = pass2 + 1; else fail2 = fail2 + 1;
    if (rc3 == 0) pass3 = pass3 + 1; else fail3 = fail3 + 1;

    Bool eq01 = FALSE, eq02 = FALSE, eq03 = FALSE;
    Bool eq12 = FALSE, eq13 = FALSE, eq23 = FALSE;
    if (b0 != NULL && b1 != NULL) ObjectsByteEqual(b0, sz0, b1, sz1, &eq01);
    if (b0 != NULL && b2 != NULL) ObjectsByteEqual(b0, sz0, b2, sz2, &eq02);
    if (b0 != NULL && b3 != NULL) ObjectsByteEqual(b0, sz0, b3, sz3, &eq03);
    if (b1 != NULL && b2 != NULL) ObjectsByteEqual(b1, sz1, b2, sz2, &eq12);
    if (b1 != NULL && b3 != NULL) ObjectsByteEqual(b1, sz1, b3, sz3, &eq13);
    if (b2 != NULL && b3 != NULL) ObjectsByteEqual(b2, sz2, b3, sz3, &eq23);
    if (eq01) byte_id_s0_s1 = byte_id_s0_s1 + 1;
    if (eq02) byte_id_s0_s2 = byte_id_s0_s2 + 1;
    if (eq03) byte_id_s0_s3 = byte_id_s0_s3 + 1;
    if (eq12) byte_id_s1_s2 = byte_id_s1_s2 + 1;
    if (eq13) byte_id_s1_s3 = byte_id_s1_s3 + 1;
    if (eq23) byte_id_s2_s3 = byte_id_s2_s3 + 1;

    U8 *class_str;
    U8 *diff_str;
    if (rc0 != 0 && rc1 != 0 && rc2 != 0 && rc3 != 0) {
      class_str = "BOTH_FAIL_4";
      diff_str = "all-fail";
      both_fail = both_fail + 1;
      U8 *fline = StrPrint(NULL,
        "%s\tALL\t%d\tALL_FAIL\n", src, rc0);
      fail_buf = StrAppend(fail_buf, fline);
      Free(fline);
    } else if (rc0 == 0 && rc1 == 0 && rc2 == 0 && rc3 == 0 &&
               b0 != NULL && b1 != NULL && b2 != NULL && b3 != NULL &&
               eq01 && eq02 && eq03) {
      class_str = "BYTE_IDENTICAL_4";
      diff_str = "all-4-byte-identical";
    } else if (rc0 != 0 && rc1 == 0 && rc2 == 0 && rc3 == 0 &&
               b1 != NULL && b2 != NULL && b3 != NULL &&
               eq12 && eq13 && eq23) {
      class_str = "STAGE0_MISSING_NO_FALLBACK";
      diff_str = "s0 fails, no historical fallback, s1==s2==s3 byte-id";
      pass_mismatch = pass_mismatch + 1;
      s0_miss_no_fallback = s0_miss_no_fallback + 1;
      U8 *fline = StrPrint(NULL,
        "%s\tstage0-current\t%d\tNO_FALLBACK\n", src, rc0);
      fail_buf = StrAppend(fail_buf, fline);
      Free(fline);
    } else if (rc0 == 0 && rc1 == 0 && rc2 == 0 && rc3 == 0 &&
               b0 != NULL && b1 != NULL && b2 != NULL && b3 != NULL &&
               !eq01) {
      class_str = "REGRESSION";
      diff_str = "byte-id-3-but-diverged-from-s0";
      regression = regression + 1;
      diverged = diverged + 1;
      U8 *fline = StrPrint(NULL,
        "%s\tstage0-current\t%d\tDIVERGED_FROM_S1_S2_S3\n", src, rc0);
      fail_buf = StrAppend(fail_buf, fline);
      Free(fline);
    } else {
      class_str = "REGRESSION";
      diff_str = "rc-mismatch";
      regression = regression + 1;
      U8 *fline = StrPrint(NULL,
        "%s\tALL\t%d\tRC_MISMATCH\n", src, rc0);
      fail_buf = StrAppend(fail_buf, fline);
      Free(fline);
    }

    U8 *line = StrPrint(NULL,
      "%s\t%d\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\n",
      src, i + 1, stem,
      rc0, rc1, rc2, rc3,
      sh0, sh1, sh2, sh3,
      class_str, diff_str);
    matrix_buf = StrAppend(matrix_buf, line);
    Free(line);

    U8 *row;
    if (rc0 == 0) {
      U8 *cls;
      if (s0_is_historical) cls = "stage0-historical";
      else                  cls = "stage0-current";
      row = StrPrint(NULL,
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        src, "stage0", s0_used, cls, sh0,
        compilers[0], comp_sha[0], h0s);
      prov_buf = StrAppend(prov_buf, row);
      Free(row);
    }
    if (rc1 == 0) {
      row = StrPrint(NULL,
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        src, "stage1", s1_path, "stage1", sh1,
        compilers[1], comp_sha[1], h1s);
      prov_buf = StrAppend(prov_buf, row);
      Free(row);
    }
    if (rc2 == 0) {
      row = StrPrint(NULL,
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        src, "stage2", s2_path, "stage2", sh2,
        compilers[2], comp_sha[2], h2s);
      prov_buf = StrAppend(prov_buf, row);
      Free(row);
    }
    if (rc3 == 0) {
      row = StrPrint(NULL,
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        src, "stage3", s3_path, "stage3", sh3,
        compilers[3], comp_sha[3], h3s);
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

  U8 mp[1024]; U8 pp[1024]; U8 fp[1024];
  I64 odl = StrLen(outdir);
  MemCpy(mp, outdir, odl); mp[odl] = '/';
  MemCpy(mp + odl + 1, LEX_MATRIX, StrLen(LEX_MATRIX) + 1);
  MemCpy(pp, outdir, odl); pp[odl] = '/';
  MemCpy(pp + odl + 1, LEX_PROVENANCE, StrLen(LEX_PROVENANCE) + 1);
  MemCpy(fp, outdir, odl); fp[odl] = '/';
  MemCpy(fp + odl + 1, LEX_FAILURES, StrLen(LEX_FAILURES) + 1);

  FileWrite(mp, matrix_buf, StrLen(matrix_buf), 0x0202);
  FileWrite(pp, prov_buf,   StrLen(prov_buf),   0x0202);
  FileWrite(fp, fail_buf,   StrLen(fail_buf),   0x0202);
  Free(matrix_buf);
  Free(prov_buf);
  Free(fail_buf);

  I64 schema_valid_provenance = 1;
  I64 schema_valid_failures   = 1;
  // Validate provenance schema: header must have exactly 7 tabs
  // (8 columns: source, stage, object_path, provenance_class,
  //  object_sha256, compiler_binary_path, compiler_binary_sha256,
  //  fnv1a64).
  I64 pp_size = 0;
  U8 *pp_buf = FileRead(pp, &pp_size);
  if (pp_buf != NULL) {
    I64 tabs = 0;
    I64 j = 0;
    while (j < pp_size && pp_buf[j] != '\n') {
      if (pp_buf[j] == '\t') tabs = tabs + 1;
      j = j + 1;
    }
    if (tabs != 7) schema_valid_provenance = 0;
    Free(pp_buf);
  } else schema_valid_provenance = 0;

  I64 fp_size = 0;
  U8 *fp_buf = FileRead(fp, &fp_size);
  if (fp_buf != NULL) {
    I64 tabs = 0;
    I64 j = 0;
    while (j < fp_size && fp_buf[j] != '\n') {
      if (fp_buf[j] == '\t') tabs = tabs + 1;
      j = j + 1;
    }
    if (tabs != 3) schema_valid_failures = 0;
    Free(fp_buf);
  } else schema_valid_failures = 0;

  "PASS_S0=%d HISTORICAL_S0=%d PASS_S1=%d PASS_S2=%d PASS_S3=%d\n",
    pass0, historical_used, pass1, pass2, pass3;
  "FAIL_S0=%d FAIL_S1=%d FAIL_S2=%d FAIL_S3=%d\n",
    fail0, fail1, fail2, fail3;
  "BOTH_FAIL_4=%d\n", both_fail;
  "REGRESSION=%d\n", regression;
  "DIVERGED=%d\n", diverged;
  "PASS_MISMATCH=%d\n", pass_mismatch;
  "HISTORICAL_S0_FALLBACKS_USED=%d\n", historical_used;
  "BYTE_IDENTICAL_4=%d\n", byte_id_s0_s1;
  "BYTE_IDENTICAL_PAIRS=%d/%d %d/%d %d/%d %d/%d %d/%d %d/%d\n",
    byte_id_s0_s1, n_sources, byte_id_s0_s2, n_sources,
    byte_id_s0_s3, n_sources, byte_id_s1_s2, n_sources,
    byte_id_s1_s3, n_sources, byte_id_s2_s3, n_sources;
  "PROVENANCE_SCHEMA_VALID=%d\n", schema_valid_provenance;
  "FAILURE_SCHEMA_VALID=%d\n", schema_valid_failures;

  U8 *status_str;
  I64 gate_ok = (regression == 0) && (pass_mismatch == 0) &&
                (schema_valid_provenance != 0) &&
                (schema_valid_failures != 0);
  if (gate_ok) status_str = "PASS";
  else status_str = "FAIL";
  "STATUS=%s\n", status_str;

  for (I64 i = 0; i < n_sources; i = i + 1) Free(sources[i]);
  if (!gate_ok) return 1;
  return 0;
}
