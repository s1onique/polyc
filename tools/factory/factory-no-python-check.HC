// tools/factory/factory-no-python-check.HC
//
// ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.1.1 IMPL.
//
// PolyC authoritative enforcement of F-NO-PYTHON
// (docs/factory/DOCTRINE.md §26).
//
// Mechanical prohibitions verified:
//   1. No tracked Python source (*.py *.pyw *.pyi
//      *.pyc *.pyo).
//   2. No tracked Python metadata (Pipfile, setup.py,
//      requirements*.txt, .python-version, etc.).
//   3. No Python shebang in any tracked file.
//   4. No executable command-surface invocation of
//      python|python3|pip|pip3|pytest|poetry, but
//      ONLY on classified executable command surfaces:
//        - *.sh, *.bash, *.zsh
//        - Makefile, *.mk, *.make, GNUmakefile
//        - CMakeLists.txt, *.cmake
//        - .githooks/, .git/hooks/, .husky/
//        - .github/workflows/, .gitlab-ci.yml, Jenkinsfile
//        - *.HC PolyC source (SpawnAndCapture edges)
//        - *.spec (PyInstaller / setuptools)
//      Non-command surfaces (docs/, evidence/, .md, .txt,
//      .tsv, .json, .yaml comments, source comments) are
//      EXEMPT — the doctrine explicitly allows historical
//      prose and source comments mentioning Python.
//
// Input: argv[1] is a file containing the output of
// `git ls-files -z` (NUL-delimited).
//
// Exit code:
//   0  no violations
//   1  violations found (FAIL lines printed)
//   2  misuse (bad invocation)
//   3  unreadable list file

#include "../../src/holyc-lib/tooling.HC"
#include "../../src/holyc-lib/strings.HC"

#define MAX_PATH 4096

// Substring search (HolyC has no StrStr).
U8 *SubStr(U8 *hay, U8 *needle)
{
  if (!hay || !needle) return NULL;
  I64 nlen = StrLen(needle);
  if (nlen == 0) return hay;
  U8 *p = hay;
  while (*p) {
    if (!StrNCmp(p, needle, nlen)) return p;
    p++;
  }
  return NULL;
}

Bool HasSuffix(U8 *s, U8 *suf)
{
  I64 slen = StrLen(s);
  I64 suflen = StrLen(suf);
  if (slen < suflen) return FALSE;
  return !StrCmp(s + slen - suflen, suf);
}

U8 *Basename(U8 *path)
{
  U8 *slash = NULL;
  U8 *p = path;
  while (*p) {
    if (*p == '/') slash = p;
    p++;
  }
  if (slash) return slash + 1;
  return path;
}

// Classification predicates.

Bool HasForbiddenSuffix(U8 *path)
{
  if (HasSuffix(path, ".py")) return TRUE;
  if (HasSuffix(path, ".pyw")) return TRUE;
  if (HasSuffix(path, ".pyi")) return TRUE;
  if (HasSuffix(path, ".pyc")) return TRUE;
  if (HasSuffix(path, ".pyo")) return TRUE;
  return FALSE;
}

Bool IsForbiddenMetadataBasename(U8 *path)
{
  U8 *base = Basename(path);
  if (!StrCmp(base, "Pipfile")) return TRUE;
  if (!StrCmp(base, "Pipfile.lock")) return TRUE;
  if (!StrCmp(base, "poetry.lock")) return TRUE;
  if (!StrCmp(base, "setup.py")) return TRUE;
  if (!StrCmp(base, "tox.ini")) return TRUE;
  if (!StrCmp(base, "pytest.ini")) return TRUE;
  if (!StrCmp(base, "requirements.txt")) return TRUE;
  if (!StrCmp(base, ".python-version")) return TRUE;
  if (!StrCmp(base, "pyproject.toml")) return TRUE;
  // requirements*.txt wildcard contract: any base that
  // begins with "requirements" followed by at least one
  // non-empty dash/underscore/dot/alphanumeric prefix
  // and ends in ".txt" is forbidden.
  I64 blen = StrLen(base);
  if (blen > 12 && !StrNCmp(base, "requirements", 12)) {
    U8 *tail = base + 12;
    if (*tail == '-' || *tail == '_' || *tail == '.') {
      tail++;
      while ((*tail >= 'a' && *tail <= 'z') ||
             (*tail >= 'A' && *tail <= 'Z') ||
             (*tail >= '0' && *tail <= '9') ||
             *tail == '-' || *tail == '_') tail++;
      if (!StrCmp(tail, ".txt")) return TRUE;
    }
    // Numeric-suffix form: requirements1.txt,
    // requirements2.txt, ... (legacy pip convention).
    U8 *num = base + 12;
    while (*num >= '0' && *num <= '9') num++;
    if (num > base + 12 && !StrCmp(num, ".txt")) return TRUE;
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
      // Allow /, end-of-string, or any non-/ char (the
      // first char of a file inside the dir).
      if (after == '/' || after == 0) return TRUE;
      // Also accept if the segment itself ends with / —
      // i.e. we're asking "is this path under dir X?".
    }
    p++;
  }
  // Also accept the path that BEGINS with the segment
  // (e.g. ".github/workflows/test.yml" begins with
  // ".github/workflows/").
  I64 plen = StrLen(path);
  if (plen >= seg_len && !StrNCmp(path, segment, seg_len)) return TRUE;
  return FALSE;
}

// Command surface classifier: returns TRUE iff a path
// represents an executable command surface where Python
// invocations would actually run.
//
// IMPORTANT ordering: CI workflow YAML must win over the
// generic .yml/.yaml exclusion. A path under
// .github/workflows/ is a CI step description; the YAML
// "run:" block executes shell commands on the runner.
Bool IsCommandSurface(U8 *path)
{
  // Pure data surfaces — never command surfaces.
  if (ContainsDirSegment(path, "docs/")) return FALSE;
  if (ContainsDirSegment(path, "evidence/")) return FALSE;
  if (HasSuffix(path, ".md")) return FALSE;
  if (HasSuffix(path, ".txt")) return FALSE;
  if (HasSuffix(path, ".tsv")) return FALSE;
  if (HasSuffix(path, ".json")) return FALSE;
  // Shell.
  if (HasSuffix(path, ".sh")) return TRUE;
  if (HasSuffix(path, ".bash")) return TRUE;
  if (HasSuffix(path, ".zsh")) return TRUE;
  // Make.
  if (!StrCmp(Basename(path), "Makefile")) return TRUE;
  if (!StrCmp(Basename(path), "GNUmakefile")) return TRUE;
  if (!StrCmp(Basename(path), "makefile")) return TRUE;
  if (HasSuffix(path, ".mk")) return TRUE;
  if (HasSuffix(path, ".make")) return TRUE;
  // CMake.
  if (!StrCmp(Basename(path), "CMakeLists.txt")) return TRUE;
  if (HasSuffix(path, ".cmake")) return TRUE;
  // Git hooks / CI — CHECK BEFORE generic YAML exclusion
  // so .github/workflows/*.yml and .gitlab-ci.yml remain
  // command surfaces.
  if (ContainsDirSegment(path, ".githooks/")) return TRUE;
  if (ContainsDirSegment(path, ".git/hooks/")) return TRUE;
  if (ContainsDirSegment(path, ".husky/")) return TRUE;
  if (ContainsDirSegment(path, ".github/workflows/")) return TRUE;
  if (!StrCmp(Basename(path), ".gitlab-ci.yml")) return TRUE;
  if (!StrCmp(Basename(path), "Jenkinsfile")) return TRUE;
  // PolyC source: only enforce SpawnAndCapture edges.
  if (HasSuffix(path, ".HC")) return TRUE;
  // Python spec files.
  if (HasSuffix(path, ".spec")) return TRUE;
  // Generic YAML exclusion AFTER CI classification above.
  if (HasSuffix(path, ".yaml")) return FALSE;
  if (HasSuffix(path, ".yml")) return FALSE;
  return FALSE;
}

// Reporting.

U0 Fail(U8 *path, U8 *reason, I64 *violations)
{
  "FAIL  %s  %s\n", path, reason;
  (*violations)++;
}

U0 Pass(U8 *path, I64 *passes)
{
  (*passes)++;
}

U0 EmitSummary(I64 violations, I64 passes, I64 inspected)
{
  "\n--- summary ---\n";
  "POLYC_TOOLS_TRACKED_PYTHON=%d\n", violations;
  "POLYC_TOOLS_TRACKED_INSPECTED=%d\n", inspected;
  "POLYC_TOOLS_TRACKED_PASSES=%d\n", passes;
  if (violations == 0) "STATUS=PASS\n";
  else                 "STATUS=FAIL\n";
}

// Per-path inspection.

U0 InspectTrackedPath(U8 *path, I64 *violations, I64 *passes)
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
  Pass(path, passes);
}

// Shebang inspection: classify by interpreter basename.
U0 InspectShebang(U8 *path, U8 *contents, I64 *violations)
{
  if (!contents) return;
  if (contents[0] != '#' || contents[1] != '!') return;
  U8 first[1024];
  I64 i = 0;
  while (i < 1023 && contents[i] && contents[i] != '\n') {
    first[i] = contents[i];
    i++;
  }
  first[i] = 0;
  // Pull out the interpreter basename.
  U8 *interp = first + 2;
  while (*interp == ' ') interp++;
  // Skip env-style: /usr/bin/env python3 -> python3.
  if (!StrNCmp(interp, "/usr/bin/env ", 13)) {
    interp += 13;
    while (*interp == ' ') interp++;
  } else if (!StrNCmp(interp, "/usr/local/bin/env ", 19)) {
    interp += 19;
    while (*interp == ' ') interp++;
  }
  // Take the basename (after the last '/').
  U8 *slash = NULL;
  U8 *q = interp;
  while (*q && *q != ' ' && *q != '\t') {
    if (*q == '/') slash = q;
    q++;
  }
  if (slash) interp = slash + 1;
  // Now interp is the interpreter name.
  // Per doctrine §26, any interpreter whose basename
  // begins with "python" (python, python3, python3.11,
  // pypy3, etc.) OR with "pip"/"pip3" is forbidden.
  // After the prefix, the next char (if any) MUST be a
  // digit (e.g. python3) OR a dot (e.g. python3.11) OR
  // end-of-string. Any other suffix means a different
  // interpreter (e.g. pythonista) and is allowed.
  if (!StrNCmp(interp, "python", 6)) {
    U8 next = interp[6];
    if (next == 0 || next == '.' ||
        (next >= '0' && next <= '9')) {
      Fail(path, "forbidden Python shebang", violations);
      return;
    }
  }
  if (!StrNCmp(interp, "pip", 3)) {
    U8 next = interp[3];
    if (next == 0 || next == '.' ||
        (next >= '0' && next <= '9')) {
      Fail(path, "forbidden Python shebang (pip)", violations);
      return;
    }
  }
}

// Surface-aware invocation inspection.
// Only scans command surfaces and respects line-level
// shell comments. Word-boundary aware.
// Known PolyC -> Python execution edges (bounded
// inventory derived from
// evidence/ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01/c1/
// python-callgraph.tsv, kind=polyc_harness_to_python).
// This is the finite current-tree execution-edge contract.
// When C2.4 removes llvm-gep01-test.HC's dynamic Python
// edge, this entry is deleted.
//
// Entries are PolyC source paths that contain a known
// Python execution edge that the literal-string scanner
// cannot detect (variable-resolved first argument).
U8 *KnownPolyCPythonEdges[] = {
  "tools/quality/llvm-gep01-test.HC",
  NULL
};

U0 InspectKnownPolyCEdge(U8 *path, I64 *violations)
{
  I64 i = 0;
  while (KnownPolyCPythonEdges[i]) {
    if (!StrCmp(path, KnownPolyCPythonEdges[i])) {
      Fail(path, "known PolyC -> Python execution edge (callgraph inventory)",
           violations);
      return;
    }
    i++;
  }
}

// CI workflow YAML scanner. Detects:
//   - `run: <shell command>` blocks (GitHub Actions)
//   - `script: <shell command>` blocks (GitLab CI)
//   - `shell: python*` defaults (executes Python)
//   - top-level `image: <py*>` containers
// Returns TRUE if a violation was found (early-exit
// signal for the caller).
// Helper: does the value (post-key) contain a Python
// invocation, with word boundaries?
U0 ScanValueForPython(U8 *path, U8 *v, U8 *eol, I64 *violations)
{
  if (v >= eol) return;
  U8 *m;
  m = SubStr(v, "python3");
  if (m && m + 7 <= eol &&
      !((m > v) && (*(m-1) >= 'a' && *(m-1) <= 'z'))) {
    U8 after;
    if (m + 7 < eol) after = m[7];
    else             after = 0;
    if (!(after >= 'a' && after <= 'z') &&
        !(after >= '0' && after <= '9') &&
        after != '_' && after != '-' && after != '.') {
      Fail(path, "forbidden Python invocation (CI workflow)",
           violations);
      return;
    }
  }
  m = SubStr(v, "python");
  if (m && m + 6 <= eol &&
      !((m > v) && (*(m-1) >= 'a' && *(m-1) <= 'z')) &&
      !(m + 6 <= eol && (m[6] >= '0' && m[6] <= '9'))) {
    U8 after;
    if (m + 6 < eol) after = m[6];
    else             after = 0;
    if (!(after >= 'a' && after <= 'z') &&
        !(after >= '0' && after <= '9') &&
        after != '_' && after != '-' && after != '.') {
      Fail(path, "forbidden Python invocation (CI workflow)",
           violations);
      return;
    }
  }
  m = SubStr(v, "pip");
  if (m && m + 3 <= eol &&
      !((m > v) && (*(m-1) >= 'a' && *(m-1) <= 'z'))) {
    U8 after;
    if (m + 3 < eol) after = m[3];
    else             after = 0;
    if (!(after >= 'a' && after <= 'z') &&
        !(after >= '0' && after <= '9') &&
        after != '_' && after != '-' && after != '.') {
      Fail(path, "forbidden Python invocation (CI workflow)",
           violations);
      return;
    }
  }
}

U0 InspectCIWorkflow(U8 *path, U8 *contents, I64 *violations)
{
  if (!contents) return;
  Bool is_gh = ContainsDirSegment(path, ".github/workflows/");
  Bool is_gl = !StrCmp(Basename(path), ".gitlab-ci.yml");
  if (!is_gh && !is_gl) return;
  // Track whether we are inside a multi-line `script:`
  // block (GitLab CI list form). A block starts on a
  // `script:` line whose value side is empty (or starts
  // with `-`), and continues while the next line is more
  // indented than the `script:` keyword column.
  I64 script_indent = -1;  // -1 = not in script block
  U8 *line = contents;
  while (*line) {
    U8 *eol = line;
    while (*eol && *eol != '\n') eol++;
    I64 llen = eol - line;
    // Compute leading-indent.
    I64 ind = 0;
    while (ind < llen && (line[ind] == ' ' || line[ind] == '\t')) ind++;
    Bool is_comment = (ind < llen && line[ind] == '#');
    Bool is_blank = (llen == 0);
    if (!is_comment && !is_blank) {
      U8 *run_key = SubStr(line, "run:");
      U8 *script_key = SubStr(line, "script:");
      U8 *shell_key = SubStr(line, "shell:");
      U8 *image_key = SubStr(line, "image:");
      // Single-line run: / script: with inline command.
      if (run_key || script_key) {
        U8 *key_end;
        if (run_key) key_end = run_key + 4;
        else         key_end = script_key + 7;
        U8 *v = key_end;
        while (v < eol && (*v == ' ' || *v == '\t')) v++;
                  run_key != NULL, script_key != NULL, ind, v;
        // If the value is empty or starts with '-' this is
        // a multi-line block opener — record the indent
        // and scan subsequent indented lines.
        if (v >= eol || *v == '-') {
          if (script_key) script_indent = ind;
        } else {
          ScanValueForPython(path, v, eol, violations);
          if (*violations > 0) return;
        }
      }
      // shell: python*   -> explicitly execute Python.
      if (shell_key) {
        U8 *v = shell_key + 6;
        while (v < eol && (*v == ' ' || *v == '\t')) v++;
        if (SubStr(v, "python")) {
          Fail(path, "forbidden Python shell (CI workflow)",
               violations);
          return;
        }
      }
      // image: python* or python:3.*   -> Python container.
      if (image_key) {
        U8 *v = image_key + 6;
        while (v < eol && (*v == ' ' || *v == '\t')) v++;
        if (SubStr(v, "python")) {
          Fail(path, "forbidden Python image (CI workflow)",
               violations);
          return;
        }
      }
      // Multi-line script: list items.
      if (script_indent >= 0 && ind > script_indent) {
                  ind, script_indent, line;
        // Strip leading "- " if present.
        U8 *v = line + ind;
        if (*v == '-') v++;
        if (*v == ' ' || *v == '\t') v++;
                ScanValueForPython(path, v, eol, violations);
        if (*violations > 0) return;
      } else if (script_indent >= 0 && ind < script_indent) {
        // Out of the script block (less indented or equal).
                script_indent = -1;
      }
    } else if (is_blank) {
      // Blank line ends the block (YAML convention).
      script_indent = -1;
    }
    line = eol;
    if (*line == '\n') line++;
  }
}

U0 InspectInvocations(U8 *path, U8 *contents, I64 *violations)
{
  if (!contents) return;
  if (!IsCommandSurface(path)) return;
  Bool is_hc = HasSuffix(path, ".HC");
  U8 *needles[6];
  I64 nlen[6];
  needles[0] = "python";  nlen[0] = 6;
  needles[1] = "python3"; nlen[1] = 7;
  needles[2] = "pip";     nlen[2] = 3;
  needles[3] = "pip3";    nlen[3] = 4;
  needles[4] = "pytest";  nlen[4] = 6;
  needles[5] = "poetry";  nlen[5] = 6;
  U8 *line = contents;
  while (*line) {
    U8 *eol = line;
    while (*eol && *eol != '\n') eol++;
    I64 llen = eol - line;
    // Skip pure shell-comment lines. For *.HC also
    // skip C++/JS-style // line comments.
    Bool is_comment = FALSE;
    I64 k = 0;
    while (k < llen && (line[k] == ' ' || line[k] == '\t')) k++;
    if (k < llen) {
      if (line[k] == '#') is_comment = TRUE;
      if (is_hc && k + 1 < llen && line[k] == '/' && line[k+1] == '/')
        is_comment = TRUE;
    }
    if (!is_comment && llen > 0) {
      // For PolyC source, ONLY check SpawnAndCapture/Exec
      // edges where the FIRST string argument is a Python
      // interpreter invocation. A bare mention of "python"
      // in a SubStr() call, a comment, or a string literal
      // is NOT an invocation.
      if (is_hc) {
        U8 *pat = "SpawnAndCapture(\"";
        U8 *m1 = SubStr(line, pat);
        U8 *pat2 = "Exec(\"";
        U8 *m2 = SubStr(line, pat2);
        // Process both occurrences on this line.
        while (m1 || m2) {
          U8 *start;
          U8 *pname;
          if (m1 && (!m2 || m1 < m2)) {
            start = m1 + StrLen(pat);
            pname = "SpawnAndCapture";
            m1 = SubStr(m1 + 1, pat);
          } else {
            start = m2 + StrLen(pat2);
            pname = "Exec";
            m2 = SubStr(m2 + 1, pat2);
          }
          U8 *end = SubStr(start, "\"");
          if (end && end > start) {
            I64 alen = end - start;
            if (alen > 1023) alen = 1023;
            U8 argbuf[1024];
            MemCpy(argbuf, start, alen);
            argbuf[alen] = 0;
            // The first argument to SpawnAndCapture/Exec
            // IS the executable. If it starts with python|pip
            // (case-insensitive comparison via SubStr), that's
            // a Python invocation edge.
            if (SubStr(argbuf, "python") || SubStr(argbuf, "pip")) {
              Fail(path, "forbidden Python invocation (PolyC edge)",
                   violations);
              return;
            }
          }
        }
      } else {
        // Shell-style command surfaces: word-boundary scan
        // for python|python3|pip|pip3|pytest|poetry.
        I64 kk;
        for (kk = 0; kk < 6; kk++) {
          U8 *m = SubStr(line, needles[kk]);
          while (m && (m - line) + nlen[kk] <= llen) {
            I64 pos = m - line;
            U8 after;
            if (pos + nlen[kk] < llen) after = line[pos + nlen[kk]];
            else                     after = 0;
            Bool word_cont =
              (after >= 'a' && after <= 'z') ||
              (after >= 'A' && after <= 'Z') ||
              (after >= '0' && after <= '9') ||
              after == '_' || after == '-' || after == '.' ||
              after == '/';
            Bool prev_alpha = FALSE;
            if (pos > 0) {
              U8 prev = line[pos - 1];
              prev_alpha =
                (prev >= 'a' && prev <= 'z') ||
                (prev >= 'A' && prev <= 'Z') ||
                (prev >= '0' && prev <= '9') ||
                prev == '_' || prev == '-' || prev == '.' ||
                prev == '/';
            }
            if (!word_cont && !prev_alpha) {
              Fail(path, "forbidden Python invocation", violations);
              return;
            }
            m = SubStr(m + 1, needles[kk]);
          }
        }
      }
    }
    line = eol;
    if (*line == '\n') line++;
  }
}

// Built-in self-tests (F13). Run with --selftest.
I64 RunSelfTests()
{
  "--- selftests ---\n";
  I64 fails = 0;
  // Substring.
  if (SubStr("hello world", "world") == NULL) {
    "FAIL  selftest: SubStr basic\n"; fails++;
  }
  if (SubStr("hello", "xyz") != NULL) {
    "FAIL  selftest: SubStr miss\n"; fails++;
  }
  // Suffix.
  if (!HasSuffix("foo.py", ".py")) {
    "FAIL  selftest: HasSuffix basic\n"; fails++;
  }
  if (HasSuffix("foo.py", ".sh")) {
    "FAIL  selftest: HasSuffix miss\n"; fails++;
  }
  // Command surface.
  if (!IsCommandSurface("Makefile")) {
    "FAIL  selftest: IsCommandSurface Makefile\n"; fails++;
  }
  if (!IsCommandSurface("scripts/quality/gate-fast.sh")) {
    "FAIL  selftest: IsCommandSurface gate-fast.sh\n"; fails++;
  }
  if (IsCommandSurface("docs/CHARTER.md")) {
    "FAIL  selftest: IsCommandSurface CHARTER.md\n"; fails++;
  }
  if (IsCommandSurface("evidence/foo/bar.txt")) {
    "FAIL  selftest: IsCommandSurface evidence\n"; fails++;
  }
  if (!IsCommandSurface("tools/quality/llvm-gep01-test.HC")) {
    "FAIL  selftest: IsCommandSurface HC\n"; fails++;
  }
  // Shebang.
  U8 *fake_py = "#!/usr/bin/env python3\n";
  U8 *fake_sh = "#!/bin/sh\n";
  U8 *fake_bash = "#!/usr/bin/env bash\n";
  U8 *fake_pip = "#!/usr/bin/env pip3\n";
  I64 v = 0;
  InspectShebang("a.py", fake_py, &v);
  if (v != 1) { "FAIL  selftest: shebang python3\n"; fails++; }
  v = 0;
  InspectShebang("a.sh", fake_sh, &v);
  if (v != 0) { "FAIL  selftest: shebang sh false positive\n"; fails++; }
  v = 0;
  InspectShebang("a.sh", fake_bash, &v);
  if (v != 0) { "FAIL  selftest: shebang bash false positive\n"; fails++; }
  v = 0;
  InspectShebang("a.sh", fake_pip, &v);
  if (v != 1) { "FAIL  selftest: shebang pip3\n"; fails++; }
  // Invocations.
  U8 *fake_inv = "exec python3 foo.py\n";
  U8 *fake_comment = "# python3 in a comment\n";
  v = 0;
  InspectInvocations("script.sh", fake_inv, &v);
  if (v != 1) { "FAIL  selftest: invocations positive\n"; fails++; }
  v = 0;
  InspectInvocations("script.sh", fake_comment, &v);
  if (v != 0) { "FAIL  selftest: invocations comment skip\n"; fails++; }
  v = 0;
  InspectInvocations("docs/CHARTER.md", fake_inv, &v);
  if (v != 0) { "FAIL  selftest: invocations docs skip\n"; fails++; }
  v = 0;
  InspectInvocations("evidence/x/y.txt", fake_inv, &v);
  if (v != 0) { "FAIL  selftest: invocations evidence skip\n"; fails++; }
  U8 *fake_hc_inv =
    "  res = SpawnAndCapture(\"python3\", \"--version\");\n";
  U8 *fake_hc_comment = "  // python3 in a comment\n";
  U8 *fake_hc_strlit =
    "  if (SubStr(argbuf, \"python\")) {\n";
  v = 0;
  InspectInvocations("test.HC", fake_hc_inv, &v);
  if (v != 1) { "FAIL  selftest: HC positive\n"; fails++; }
  v = 0;
  InspectInvocations("test.HC", fake_hc_comment, &v);
  if (v != 0) { "FAIL  selftest: HC comment skip\n"; fails++; }
  v = 0;
  InspectInvocations("test.HC", fake_hc_strlit, &v);
  if (v != 0) { "FAIL  selftest: HC string literal skip\n"; fails++; }
  U8 *fake_word = "echo pythonista rules\n";
  v = 0;
  InspectInvocations("script.sh", fake_word, &v);
  if (v != 0) { "FAIL  selftest: word boundary pythonista\n"; fails++; }
  U8 *fake_word2 = "echo lispython rules\n";
  v = 0;
  InspectInvocations("script.sh", fake_word2, &v);
  if (v != 0) { "FAIL  selftest: word boundary lispython\n"; fails++; }
  // Word-boundary: "factory-no-python-check" — python is
  // followed by '-' which is a non-word-boundary, so this
  // should NOT flag.
  U8 *fake_dash = "echo factory-no-python-check failed\n";
  v = 0;
  InspectInvocations("script.sh", fake_dash, &v);
  if (v != 0) { "FAIL  selftest: word boundary dash\n"; fails++; }
  // Shebang python3.11 (numeric.dot suffix) MUST flag.
  U8 *fake_py311 = "#!/usr/bin/env python3.11\n";
  v = 0;
  InspectShebang("a.sh", fake_py311, &v);
    if (v != 1) { "FAIL  selftest: shebang python3.11\n"; fails++; }
  // Shebang pythonista (alpha suffix) MUST NOT flag.
  U8 *fake_pyista = "#!/usr/bin/env pythonista\n";
  v = 0;
  InspectShebang("a.sh", fake_pyista, &v);
  if (v != 0) { "FAIL  selftest: shebang pythonista false positive\n"; fails++; }
  // requirements*.txt wildcard — requirements-dev.txt
  // MUST flag; requirement.txt MUST NOT.
  if (!IsForbiddenMetadataBasename("requirements-dev.txt")) {
    "FAIL  selftest: requirements-dev.txt\n"; fails++;
  }
  if (!IsForbiddenMetadataBasename("requirements_test.txt")) {
    "FAIL  selftest: requirements_test.txt\n"; fails++;
  }
  if (IsForbiddenMetadataBasename("requirement.txt")) {
    "FAIL  selftest: requirement.txt false positive\n"; fails++;
  }
  if (!IsForbiddenMetadataBasename("requirements1.txt")) {
    "FAIL  selftest: requirements1.txt\n"; fails++;
  }
  if (IsForbiddenMetadataBasename("requirements.in")) {
    // requirements.in has .in suffix not .txt, so wildcard
    // does NOT apply. Document this.
    "FAIL  selftest: requirements.in false positive\n"; fails++;
  }
  // CI workflow YAML classification: .github/workflows/*
  // MUST be a command surface; generic docs/example.yml
  // MUST NOT.
  if (!IsCommandSurface(".github/workflows/test.yml")) {
    "FAIL  selftest: CI workflow classification\n"; fails++;
  }
  if (!IsCommandSurface(".gitlab-ci.yml")) {
    "FAIL  selftest: GitLab CI classification\n"; fails++;
  }
  if (IsCommandSurface("docs/example.yml")) {
    "FAIL  selftest: generic YAML false positive\n"; fails++;
  }
  // CI workflow scanner.
  U8 *gh_run = "      - run: python3 forbidden.py\n";
  v = 0;
  InspectCIWorkflow(".github/workflows/test.yml", gh_run, &v);
    if (v != 1) { "FAIL  selftest: CI run python3\n"; fails++; }
  U8 *gh_shell = "    shell: python\n";
  v = 0;
  InspectCIWorkflow(".github/workflows/test.yml", gh_shell, &v);
  if (v != 1) { "FAIL  selftest: CI shell python\n"; fails++; }
  U8 *gh_image = "    image: python:3.11\n";
  v = 0;
  InspectCIWorkflow(".github/workflows/test.yml", gh_image, &v);
  if (v != 1) { "FAIL  selftest: CI image python\n"; fails++; }
  U8 *gl_script = "script:\n  - python3 foo.py\n";
  v = 0;
  InspectCIWorkflow(".gitlab-ci.yml", gl_script, &v);
    if (v != 1) { "FAIL  selftest: GitLab script python3\n"; fails++; }
  U8 *gh_clean = "      - run: ./polyc-build\n";
  v = 0;
  InspectCIWorkflow(".github/workflows/test.yml", gh_clean, &v);
  if (v != 0) { "FAIL  selftest: CI clean run false positive\n"; fails++; }
  U8 *gh_yaml_comment = "      # python3 in a comment\n";
  v = 0;
  InspectCIWorkflow(".github/workflows/test.yml", gh_yaml_comment, &v);
  if (v != 0) { "FAIL  selftest: CI yaml comment skip\n"; fails++; }
  // Known PolyC edge inventory.
  v = 0;
  InspectKnownPolyCEdge("tools/quality/llvm-gep01-test.HC", &v);
  if (v != 1) { "FAIL  selftest: known PolyC edge\n"; fails++; }
  v = 0;
  InspectKnownPolyCEdge("tools/quality/unrelated.HC", &v);
  if (v != 0) { "FAIL  selftest: known PolyC edge negative\n"; fails++; }
  if (fails == 0) "SELFTEST=PASS\n";
  else            "SELFTEST=FAIL (%d failures)\n", fails;
  return fails;
}

I32 Main(I32 argc, U8 **argv)
{
  I64 violations = 0;
  I64 passes = 0;
  if (argc >= 2 && !StrCmp(argv[1], "--selftest")) {
    I64 f = RunSelfTests();
    if (f == 0) return 0;
    return 1;
  }
  if (argc < 2) {
    "USAGE: factory-no-python-check <path-list-file>\n";
    "  <path-list-file> is the output of: git ls-files -z\n";
    "OPTIONS:\n";
    "  --selftest   run built-in self-tests and exit\n";
    return 2;
  }
  U8 *list_path = argv[1];
  I64 total = 0;
  U8 *list_buf = FileRead(list_path, &total);
  if (!list_buf) {
    "ERROR: cannot read path-list file: %s\n", list_path;
    return 3;
  }
  // NOTE: do NOT use StrLen here; the buffer is NUL-
  // delimited and StrLen would truncate at the first NUL.
  I64 offset = 0;
  I64 inspected = 0;
  while (offset < total) {
    U8 line[MAX_PATH];
    I64 i = 0;
    // Walk the NUL record up to MAX_PATH-1; if we hit
    // MAX_PATH-1 before the NUL terminator, the record
    // is overlong — FAIL CLOSED with PATH_TOO_LONG.
    Bool overflow = FALSE;
    while (offset < total && list_buf[offset] != 0) {
      if (i >= MAX_PATH - 1) {
        overflow = TRUE;
        // consume the rest of the record so we advance
        // past it on the next loop iteration.
        while (offset < total && list_buf[offset] != 0) offset++;
        break;
      }
      line[i++] = list_buf[offset++];
    }
    line[i] = 0;
    if (offset < total && list_buf[offset] == 0) offset++;
    if (overflow) {
      "ERROR:  %s  path record exceeds MAX_PATH=%d (FAIL CLOSED)\n",
        line, MAX_PATH;
      violations++;
      inspected++;
      continue;
    }
    if (i == 0) continue;
    inspected++;
    InspectTrackedPath(line, &violations, &passes);
    // If the path is already a violation (Python source
    // suffix / metadata / __pycache__), do not run the
    // per-content checks — they would re-fire and inflate
    // the violation count without adding signal.
    if (HasForbiddenSuffix(line)) continue;
    if (IsForbiddenMetadataBasename(line)) continue;
    if (ContainsDirSegment(line, "__pycache__")) continue;
    U8 *body = FileRead(line);
    if (body) {
      InspectShebang(line, body, &violations);
      InspectCIWorkflow(line, body, &violations);
      InspectInvocations(line, body, &violations);
      Free(body);
    }
    // Known PolyC -> Python edges: checked even if body
    // read failed (the failure itself is not a python
    // issue, but the callgraph inventory applies).
    if (HasSuffix(line, ".HC")) {
      InspectKnownPolyCEdge(line, &violations);
    }
  }
  Free(list_buf);
  EmitSummary(violations, passes, inspected);
  if (violations > 0) return 1;
  return 0;
}
