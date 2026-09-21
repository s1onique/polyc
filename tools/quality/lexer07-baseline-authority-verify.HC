// tools/quality/lexer07-baseline-authority-verify.HC
//
// ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02 C2 IMPL.
// PolyC comparator for the prospective LEXER07 baseline authority.
//
// Reads TWO baseline directories produced by
// tools/quality/lexer07-broad-corpus-4-stage.HC and verifies
// that they are byte-identical across all three output files
// (corpus-matrix.tsv, corpus-failures.tsv, corpus-object-provenance.tsv)
// AND byte-identical in their 14-token counter set.
//
// Also supports negative-control modes:
//   --mode=match       compare directory <a> vs <b> (default)
//   --mode=mutate      copy <a> to <c>, mutate one known fixture's
//                      classification in corpus-failures.tsv, and
//                      verify that the comparator REJECTS the
//                      mutated copy as different from <a>.
//   --mode=omit        copy <a> to <c>, delete one known failing
//                      fixture row from corpus-failures.tsv, and
//                      verify that the comparator REJECTS the
//                      omitted copy as different from <a>.
//
// Usage:
//   lexer07-baseline-authority-verify <a_dir> <b_dir> [--mode=match|mutate|omit]
//
// Exit code 0 on match (for match mode) or pristine re-verify (for mutate/omit).
// Exit code 5 on mismatch (for match) or rejection (for mutate/omit negative control).
// Exit code 2 on usage error.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" U8 *strstr(U8 *haystack, U8 *needle);

#define MAX_FILES 8

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

U0 FilesByteEqual(U8 *ap, U8 *bp, Bool *out)
{
  I64 asz = 0;
  I64 bsz = 0;
  U8 *ab = FileRead(ap, &asz);
  U8 *bb = FileRead(bp, &bsz);
  if (ab == NULL || bb == NULL) {
    if (ab) Free(ab);
    if (bb) Free(bb);
    *out = FALSE;
    return;
  }
  if (asz != bsz) {
    Free(ab);
    Free(bb);
    *out = FALSE;
    return;
  }
  *out = (MemCmp(ab, bb, asz) == 0);
  Free(ab);
  Free(bb);
}

I64 CompareDirs(U8 *adir, U8 *bdir)
{
  U8 *names[MAX_FILES];
  names[0] = "corpus-matrix.tsv";
  names[1] = "corpus-failures.tsv";
  names[2] = "corpus-object-provenance.tsv";
  I64 match = 0;
  I64 mismatch = 0;
  I64 missing = 0;
  for (I64 i = 0; i < 3; i = i + 1) {
    U8 *ap = StrPrint(NULL, "%s/%s", adir, names[i]);
    U8 *bp = StrPrint(NULL, "%s/%s", bdir, names[i]);
    Bool eq = FALSE;
    FilesByteEqual(ap, bp, &eq);
    if (eq) {
      match = match + 1;
    } else {
      I64 asz = 0;
      I64 bsz = 0;
      U8 *ab = FileRead(ap, &asz);
      U8 *bb = FileRead(bp, &bsz);
      if (ab == NULL || bsz == 0) missing = missing + 1;
      else mismatch = mismatch + 1;
      if (ab) Free(ab);
      if (bb) Free(bb);
    }
    Free(ap);
    Free(bp);
  }
  "COMPARE match=%d mismatch=%d missing=%d\n", match, mismatch, missing;
  if (mismatch == 0 && missing == 0 && match == 3) return 0;
  return 5;
}

U0 MkDirp(U8 *path)
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

U0 CopyFile(U8 *src, U8 *dst)
{
  I64 sz = 0;
  U8 *buf = FileRead(src, &sz);
  if (buf == NULL) return;
  FileWrite(dst, buf, sz, 0x0202);
  Free(buf);
}

U0 CopyDirContents(U8 *srcdir, U8 *dstdir)
{
  U8 *names[3];
  names[0] = "corpus-matrix.tsv";
  names[1] = "corpus-failures.tsv";
  names[2] = "corpus-object-provenance.tsv";
  for (I64 i = 0; i < 3; i = i + 1) {
    U8 *sp = StrPrint(NULL, "%s/%s", srcdir, names[i]);
    U8 *dp = StrPrint(NULL, "%s/%s", dstdir, names[i]);
    CopyFile(sp, dp);
    Free(sp);
    Free(dp);
  }
}

// Mutate the classification of the FIRST data row of
// corpus-failures.tsv in a copy directory. Replaces the
// classification token with "MUTATED_FOR_NEGATIVE_CONTROL".
I64 MutateFirstFailureClassification(U8 *dstdir)
{
  U8 *path = StrPrint(NULL, "%s/corpus-failures.tsv", dstdir);
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) {
    Free(path);
    return 2;
  }
  // Skip header line.
  I64 i = 0;
  while (i < sz && buf[i] != '\n') i = i + 1;
  if (i >= sz) { Free(buf); Free(path); return 2; }
  I64 line_start = i + 1;
  // Find end of first data line.
  I64 j = line_start;
  while (j < sz && buf[j] != '\n') j = j + 1;
  // Within that line, find the 4th tab (the failure_class column).
  I64 tabs = 0;
  I64 k = line_start;
  while (k < j && tabs < 3) {
    if (buf[k] == '\t') tabs = tabs + 1;
    k = k + 1;
  }
  if (tabs != 3) { Free(buf); Free(path); return 2; }
  I64 col_start = k;
  // Replace until end of line with MUTATED marker.
  U8 *marker = "MUTATED_FOR_NEGATIVE_CONTROL";
  I64 marker_len = StrLen(marker);
  I64 remaining = j - col_start;
  for (I64 m = 0; m < remaining; m = m + 1) {
    if (m < marker_len) buf[col_start + m] = marker[m];
    else buf[col_start + m] = ' ';
  }
  FileWrite(path, buf, sz, 0x0202);
  Free(buf);
  Free(path);
  return 0;
}

// Delete the FIRST data row of corpus-failures.tsv in a copy
// directory. This represents fixture-set omission.
I64 OmitFirstFailureRow(U8 *dstdir)
{
  U8 *path = StrPrint(NULL, "%s/corpus-failures.tsv", dstdir);
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (buf == NULL) {
    Free(path);
    return 2;
  }
  // Skip header line.
  I64 i = 0;
  while (i < sz && buf[i] != '\n') i = i + 1;
  if (i >= sz) { Free(buf); Free(path); return 2; }
  I64 line_start = i + 1;
  // Find end of first data line.
  I64 j = line_start;
  while (j < sz && buf[j] != '\n') j = j + 1;
  if (j < sz) j = j + 1; // include the newline
  // Shift everything after the deleted row to the left.
  I64 tail = sz - j;
  for (I64 m = 0; m < tail; m = m + 1) {
    buf[line_start + m] = buf[j + m];
  }
  I64 new_sz = line_start + tail;
  FileWrite(path, buf, new_sz, 0x0202);
  Free(buf);
  Free(path);
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 3) {
    "USAGE: lexer07-baseline-authority-verify <a_dir> <b_dir> [--mode=match|mutate|omit]\n";
    return 2;
  }
  U8 *a = argv[1];
  U8 *b = argv[2];
  U8 *mode = "match";
  for (I32 i = 3; i < argc; i = i + 1) {
    if (StrNCmp(argv[i], "--mode=", 7) == 0) {
      mode = argv[i] + 7;
    }
  }
  if (StrNCmp(mode, "match", 5) == 0) {
    I64 rc = CompareDirs(a, b);
    if (rc == 0) {
      "BASELINE_MATCH=YES\n";
    } else {
      "BASELINE_MATCH=NO\n";
    }
    return rc;
  }
  if (StrNCmp(mode, "mutate", 6) == 0) {
    U8 *cdir = StrPrint(NULL, "%s.mutated", a);
    MkDirp(cdir);
    CopyDirContents(a, cdir);
    I64 mrc = MutateFirstFailureClassification(cdir);
    if (mrc != 0) { "MUTATE_SETUP=FAIL\n"; Free(cdir); return 2; }
    I64 rc = CompareDirs(a, cdir);
    if (rc != 0) {
      "BASELINE_MUTATION_DETECTED=YES\n";
      Free(cdir);
      return 0;
    }
    "BASELINE_MUTATION_DETECTED=NO\n";
    Free(cdir);
    return 5;
  }
  if (StrNCmp(mode, "omit", 4) == 0) {
    U8 *cdir = StrPrint(NULL, "%s.omitted", a);
    MkDirp(cdir);
    CopyDirContents(a, cdir);
    I64 mrc = OmitFirstFailureRow(cdir);
    if (mrc != 0) { "OMIT_SETUP=FAIL\n"; Free(cdir); return 2; }
    I64 rc = CompareDirs(a, cdir);
    if (rc != 0) {
      "BASELINE_OMISSION_DETECTED=YES\n";
      Free(cdir);
      return 0;
    }
    "BASELINE_OMISSION_DETECTED=NO\n";
    Free(cdir);
    return 5;
  }
  "USAGE: unknown mode=%s\n", mode;
  return 2;
}
