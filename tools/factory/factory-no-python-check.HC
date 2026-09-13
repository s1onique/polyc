// tools/factory/factory-no-python-check.HC
//
// ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.1 IMPL.
//
// PolyC authoritative enforcement of F-NO-PYTHON
// (docs/factory/DOCTRINE.md §26).
//
// Mechanical prohibitions verified:
//   1. No tracked Python source (*.py *.pyw *.pyi *.pyc).
//   2. No tracked Python runtime/cache artifacts
//      (__pycache__/, .python-version, Pipfile, etc.).
//   3. No Python interpreter shebang in any tracked file.
//   4. No executable build/tool/CI invocation of
//      python|python3|pip|pytest|tox|poetry inside Makefile
//      recipes or shell scripts under canonical tool roots.
//
// Input: argv[1] is a file containing the output of
// `git ls-files` (one path per line; NUL-stripped by the
// shell wrapper).
//
// Exit code:
//   0  no violations
//   1  violations found (FAIL lines printed)
//   2  misuse (bad invocation)
//   3  git failure / unreadable list file
//
// This checker is intentionally conservative: it
// inspects the live tree state via `git ls-files` and
// fails CLOSED on any violation. It does not walk
// historical commits.

#include "../../src/holyc-lib/tooling.HC"
#include "../../src/holyc-lib/strings.HC"

#define MAX_PATH 4096

U0 Fail(U8 *path, U8 *reason, I64 *violations)
{
  "FAIL  %s  %s\n", path, reason;
  (*violations)++;
}

U0 EmitSummary(I64 violations)
{
  "\n--- summary ---\n";
  "POLYC_TOOLS_TRACKED_PYTHON=%d\n", violations;
  if (violations == 0) {
    "STATUS=PASS\n";
  } else {
    "STATUS=FAIL\n";
  }
}

Bool HasForbiddenSuffix(U8 *path)
{
  I64 path_len = StrLen(path);
  if (path_len >= 3 && !StrCmp(path + path_len - 3, ".py")) return TRUE;
  if (path_len >= 4 && !StrCmp(path + path_len - 4, ".pyw")) return TRUE;
  if (path_len >= 4 && !StrCmp(path + path_len - 4, ".pyi")) return TRUE;
  if (path_len >= 4 && !StrCmp(path + path_len - 4, ".pyc")) return TRUE;
  return FALSE;
}

Bool IsForbiddenMetadataBasename(U8 *path)
{
  U8 *slash = NULL;
  U8 *p = path;
  while (*p) {
    if (*p == '/') slash = p;
    p++;
  }
  U8 *base;
  if (slash) base = slash + 1; else base = path;
  if (!StrCmp(base, "Pipfile")) return TRUE;
  if (!StrCmp(base, "Pipfile.lock")) return TRUE;
  if (!StrCmp(base, "poetry.lock")) return TRUE;
  if (!StrCmp(base, "setup.py")) return TRUE;
  if (!StrCmp(base, "tox.ini")) return TRUE;
  if (!StrCmp(base, "pytest.ini")) return TRUE;
  if (!StrCmp(base, "requirements.txt")) return TRUE;
  if (StrLen(base) > 12) {
    if (!StrNCmp(base, "requirements", 12)) {
      U8 *tail = base + 12;
      while (*tail >= '0' && *tail <= '9') tail++;
      if (!StrCmp(tail, ".txt")) return TRUE;
    }
  }
  return FALSE;
}

Bool ContainsDirSegment(U8 *path, U8 *segment)
{
  I64 seg_len = StrLen(segment);
  U8 *p = path;
  while (*p) {
    if (!StrNCmp(p, segment, seg_len)) {
      U8 after = p[seg_len];
      if (after == '/' || after == 0) return TRUE;
    }
    p++;
  }
  return FALSE;
}

U0 InspectTrackedPath(U8 *path, I64 *violations)
{
  if (HasForbiddenSuffix(path)) {
    Fail(path, "forbidden Python source suffix", violations);
    return;
  }
  if (IsForbiddenMetadataBasename(path)) {
    Fail(path, "forbidden Python metadata file", violations);
    return;
  }
  if (ContainsDirSegment(path, "__pycache__")) {
    Fail(path, "forbidden __pycache__ directory", violations);
    return;
  }
  if (!StrCmp(path, ".python-version")) {
    Fail(path, "forbidden .python-version", violations);
    return;
  }
}

Bool StartsWithStr(U8 *haystack, U8 *needle)
{
  return StrNCmp(haystack, needle, StrLen(needle)) == 0;
}

U0 InspectShebangAndInvocations(U8 *path, U8 *contents, I64 *violations)
{
  if (!contents) return;
  U8 *nl = contents;
  while (*nl && *nl != '\n') nl++;
  I64 first_len = nl - contents;
  if (first_len > 2 && contents[0] == '#' && contents[1] == '!') {
    if (first_len < 1024) {
      U8 first[1024];
      MemCpy(first, contents, first_len);
      first[first_len] = 0;
      if (StrFirstOcc(first, "python") || StrFirstOcc(first, "python3") ||
          StrFirstOcc(first, "/usr/bin/env python")) {
        Fail(path, "forbidden Python shebang", violations);
        return;
      }
    }
  }
  Bool is_cmd_surface = FALSE;
  if (StrFirstOcc(path, "Makefile")) is_cmd_surface = TRUE;
  if (StrFirstOcc(path, ".mk")) is_cmd_surface = TRUE;
  if (!StrCmp(path, "CMakeLists.txt")) is_cmd_surface = TRUE;
  if (StrFirstOcc(path, ".cmake")) is_cmd_surface = TRUE;
  if (StrFirstOcc(path, ".sh")) is_cmd_surface = TRUE;
  if (StrFirstOcc(path, ".githooks/")) is_cmd_surface = TRUE;
  if (StrFirstOcc(path, ".github/workflows/")) is_cmd_surface = TRUE;
  if (!is_cmd_surface) return;
  U8 *needles[8];
  I64 nlen[8];
  needles[0] = "python";       nlen[0] = 6;
  needles[1] = "python3";      nlen[1] = 7;
  needles[2] = "pip";          nlen[2] = 3;
  needles[3] = "pip3";         nlen[3] = 4;
  needles[4] = "pytest";       nlen[4] = 6;
  needles[5] = "tox";          nlen[5] = 3;
  needles[6] = "poetry";       nlen[6] = 6;
  needles[7] = "/usr/bin/env python"; nlen[7] = 19;
  I64 k;
  for (k = 0; k < 8; k++) {
    U8 *p = contents;
    while (*p) {
      if (!StrNCmp(p, needles[k], nlen[k])) {
        U8 after = p[nlen[k]];
        if (after == ' ' || after == '\t' ||
            after == '\n' || after == 0) {
          U8 *ls = p;
          while (ls > contents && *(ls-1) != '\n') ls--;
          Bool comment = FALSE;
          U8 *c = ls;
          while (c < p) {
            if (*c == '#') { comment = TRUE; break; }
            c++;
          }
          if (!comment) {
            Fail(path, "forbidden Python invocation", violations);
            return;
          }
        }
      }
      p++;
    }
  }
}

public I32 Main(I32 argc, U8 **argv)
{
  I64 violations = 0;
  if (argc < 2) {
    "USAGE: factory-no-python-check.HC <path-list-file>\n";
    "  where <path-list-file> is the output of: git ls-files\n";
    "  (one path per line; NUL stripped by shell wrapper).\n";
    return 2;
  }
  U8 *list_path = argv[1];
  U8 *list_buf = FileRead(list_path);
  if (!list_buf) {
    "ERROR: cannot read path-list file: %s\n", list_path;
    return 3;
  }
  I64 offset = 0;
  I64 total = StrLen(list_buf);
  while (offset < total) {
    U8 line[MAX_PATH];
    I64 i = 0;
    while (offset < total && list_buf[offset] != '\n' &&
           i < MAX_PATH - 1) {
      line[i++] = list_buf[offset++];
    }
    line[i] = 0;
    if (list_buf[offset] == '\n') offset++;
    if (i == 0) continue;
    InspectTrackedPath(line, &violations);
    U8 *body = FileRead(line);
    if (body) {
      InspectShebangAndInvocations(line, body, &violations);
      Free(body);
    }
  }
  Free(list_buf);
  EmitSummary(violations);
  if (violations > 0) return 1;
  return 0;
}
