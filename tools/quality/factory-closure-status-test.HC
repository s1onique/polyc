// tools/quality/factory-closure-status-test.HC
//
// ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02 P0-1:
// PolyC authoritative implementation of the 12-case regression
// matrix for scripts/quality/factory-closure-status-check.sh.
//
// This PolyC executable owns ALL test logic:
//   - parsing the static TSV fixture
//     (scripts/quality/factory-closure-status-test-cases.tsv)
//   - writing the per-case temp manifest file
//   - invoking the checker with FACTORY_ACT_HANDOFF_MAP set
//   - capturing stdout/stderr
//   - substring-search of the captured output for the
//     expected substring
//   - aggregating PASS / FAIL counters
//   - emitting the final summary line
//
// Build:
//   ./hcc --install-dir=./build/test-prefix -c \
//       tools/quality/factory-closure-status-test.HC \
//       -o build/factory-closure-status-test.o
//   cc build/factory-closure-status-test.o \
//       -L./build/test-prefix/lib -ltos -lpthread -lc -lm \
//       -o build/factory-closure-status-test
//
// Invocation:
//   ./build/factory-closure-status-test <checker_path> <cases_tsv_path>
//   Defaults:
//     checker_path = ./scripts/quality/factory-closure-status-check.sh
//     cases_path   = ./scripts/quality/factory-closure-status-test-cases.tsv
//
// F-POLYC-TOOLS compliance:
//   - The 12-case matrix is data in a TSV file (no executable
//     logic).
//   - All test execution and verdict logic lives in this
//     PolyC binary.
//   - The shell wrapper scripts/quality/factory-closure-status-
//     check-test.sh is a thin `exec` dispatch (15 LOC) and
//     contains no test logic of its own.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags);
extern "c" I8 *getenv(U8 *name);
extern "c" I64 getpid(U0);

U8 *g_checker = NULL;
U8 *g_cases = NULL;
I64 g_pid = 0;

// Append a single character to a heap buffer, growing as needed.
U8 *AppendChar(U8 *buf, I64 *cap, I64 *len, U8 c)
{
  if (*len + 1 >= *cap) {
    I64 newcap = *cap * 2;
    if (newcap < 64) newcap = 64;
    U8 *nb = MAlloc(newcap);
    if (buf != NULL) {
      I64 i = 0;
      while (i < *len) { nb[i] = buf[i]; i = i + 1; }
      Free(buf);
    }
    buf = nb;
    *cap = newcap;
  }
  buf[*len] = c;
  *len = *len + 1;
  buf[*len] = 0;
  return buf;
}

U8 *AppendStr(U8 *buf, I64 *cap, I64 *len, U8 *s)
{
  while (*s != 0) {
    buf = AppendChar(buf, cap, len, *s);
    s = s + 1;
  }
  return buf;
}

I32 StrEq(U8 *a, U8 *b)
{
  while (*a != 0 && *b != 0) {
    if (*a != *b) return 0;
    a = a + 1;
    b = b + 1;
  }
  return *a == 0 && *b == 0;
}

// Decode a manifest-content string with escape sequences:
//   \\n -> newline (0x0A)
//   \\t -> tab (0x09)
//   \\\\ -> single backslash
// Writes the decoded content into a fresh heap buffer;
// `*out_len` is set to the decoded byte count.
U8 *DecodeEscapes(U8 *src, I64 src_len, I64 *out_len)
{
  U8 *out = MAlloc(src_len + 1);
  I64 oi = 0;
  I64 si = 0;
  while (si < src_len) {
    U8 c = src[si];
    if (c == '\\' && si + 1 < src_len) {
      U8 n = src[si + 1];
      if (n == 'n') { out[oi] = '\n'; oi = oi + 1; si = si + 2; continue; }
      if (n == 't') { out[oi] = '\t'; oi = oi + 1; si = si + 2; continue; }
      if (n == '\\') { out[oi] = '\\'; oi = oi + 1; si = si + 2; continue; }
    }
    out[oi] = c;
    oi = oi + 1;
    si = si + 1;
  }
  out[oi] = 0;
  *out_len = oi;
  return out;
}

// Find substring `sub` in `s`. Returns 1 if found, 0 otherwise.
I32 FindSub(U8 *s, U8 *sub)
{
  if (sub[0] == 0) return 1;
  I64 si = 0;
  while (s[si] != 0) {
    I64 sj = 0;
    while (1) {
      if (sub[sj] == 0) return 1;
      if (s[si + sj] == 0) break;
      if (s[si + sj] != sub[sj]) break;
      sj = sj + 1;
    }
    si = si + 1;
  }
  return 0;
}

// Find next line in buffer `p` of length `len`, starting at `*idx`.
// Returns pointer to the line and updates `*idx` to the next line.
// `llen` is set to the line length (excluding newline).
U8 *NextLine(U8 *p, I64 len, I64 *idx, I64 *llen)
{
  if (*idx >= len) return NULL;
  U8 *start = p + *idx;
  I64 i = 0;
  while (*idx < len && p[*idx] != '\n') {
    *idx = *idx + 1;
    i = i + 1;
  }
  *llen = i;
  if (*idx < len) *idx = *idx + 1; // skip the \n
  return start;
}

// Copy a substring of `src` (length `n`) into a new heap string.
U8 *StrNDup(U8 *src, I64 n)
{
  U8 *r = MAlloc(n + 1);
  I64 i = 0;
  while (i < n) { r[i] = src[i]; i = i + 1; }
  r[n] = 0;
  return r;
}

// Strip trailing \r from a heap string.
U8 *StripCR(U8 *s)
{
  I64 i = 0;
  while (s[i] != 0) i = i + 1;
  while (i > 0 && s[i - 1] == '\r') {
    s[i - 1] = 0;
    i = i - 1;
  }
  return s;
}

// Run one test case.
// Writes the manifest fixture, invokes the checker, captures output,
// runs substring match, and increments the PASS/FAIL counter.
U8 *g_capture_path = NULL;

U0 RunCase(U8 *case_id, I64 expected_rc, U8 *expected_sub,
             U8 *manifest_content, I64 manifest_len,
             I64 *pass, I64 *fail)
{
  // Write the manifest fixture to a temp file.
  U8 mpath[256];
  I64 mi = 0;
  U8 *p1 = "/tmp/fcst-";
  I64 j = 0;
  while (p1[j] != 0) { mpath[mi] = p1[j]; mi = mi + 1; j = j + 1; }
  U8 *p2 = case_id;
  j = 0;
  while (p2[j] != 0) { mpath[mi] = p2[j]; mi = mi + 1; j = j + 1; }
  mpath[mi] = 0;

  // Decode manifest content (escape \\n, \\t, \\\\).
  I64 decoded_len = 0;
  U8 *decoded = DecodeEscapes(manifest_content, manifest_len, &decoded_len);

  if (!FileWrite(mpath, decoded, decoded_len, 0x0202)) {
    "FAIL  %s  write-manifest-error\n", case_id;
    *fail = *fail + 1;
    Free(decoded);
    return;
  }
  Free(decoded);

  // Build the checker-invocation command:
  //   FACTORY_ACT_HANDOFF_MAP=<mpath> sh <checker> > <capture> 2>&1
  //   echo $? > <rcpath>
  U8 *cmd = NULL;
  I64 cap = 0, len = 0;
  cmd = AppendStr(cmd, &cap, &len, "FACTORY_ACT_HANDOFF_MAP='");
  cmd = AppendStr(cmd, &cap, &len, mpath);
  cmd = AppendStr(cmd, &cap, &len, "' sh '");
  cmd = AppendStr(cmd, &cap, &len, g_checker);
  cmd = AppendStr(cmd, &cap, &len, "' > '");
  cmd = AppendStr(cmd, &cap, &len, g_capture_path);
  cmd = AppendStr(cmd, &cap, &len, "' 2>&1; echo $? > '");
  cmd = AppendStr(cmd, &cap, &len, g_capture_path);
  cmd = AppendStr(cmd, &cap, &len, ".rc'");

  I64 rc = System(cmd);
  Free(cmd);

  // Read the RC file.
  U8 *rcpath = NULL;
  cap = 0; len = 0;
  rcpath = AppendStr(rcpath, &cap, &len, g_capture_path);
  rcpath = AppendStr(rcpath, &cap, &len, ".rc");
  I64 rsz = 0;
  U8 *rcbuf = FileRead(rcpath, &rsz);
  Free(rcpath);
  if (rcbuf == NULL) {
    "FAIL  %s  cannot-read-rc\n", case_id;
    *fail = *fail + 1;
    return;
  }
  I64 actual_rc = 0;
  I64 k = 0;
  while (rcbuf[k] >= '0' && rcbuf[k] <= '9') {
    actual_rc = actual_rc * 10 + (rcbuf[k] - '0');
    k = k + 1;
  }
  Free(rcbuf);

  // Read the capture file.
  I64 csz = 0;
  U8 *cbuf = FileRead(g_capture_path, &csz);
  if (cbuf == NULL) {
    "FAIL  %s  cannot-read-capture\n", case_id;
    *fail = *fail + 1;
    return;
  }

  I32 rc_ok;
  if (actual_rc == expected_rc) rc_ok = 1; else rc_ok = 0;
  I32 sub_ok;
  if (FindSub(cbuf, expected_sub)) sub_ok = 1; else sub_ok = 0;

  if (rc_ok && sub_ok) {
    "PASS  %s\n", case_id;
    *pass = *pass + 1;
  } else {
    "FAIL  %s  rc=%d exp=%d sub=%d\n",
      case_id, actual_rc, expected_rc, sub_ok;
    *fail = *fail + 1;
  }
  Free(cbuf);
}

I32 Main(I32 argc, U8 **argv)
{
  // PolyC's runtime here does not forward argv to Main, so
  // we read the checker and cases paths from environment
  // variables if set, otherwise use the repository-relative
  // defaults. The shell wrapper
  // scripts/quality/factory-closure-status-check-test.sh
  // passes these via the FACTORY_CLOSURE_STATUS_CHECKER and
  // FACTORY_CLOSURE_STATUS_CASES env vars.
  U8 *envc;
  I8 *envc_raw = getenv("FACTORY_CLOSURE_STATUS_CHECKER");
  if (envc_raw != NULL && envc_raw[0] != 0) {
    U8 *p = envc_raw;
    envc = p;
  } else {
    envc = "./scripts/quality/factory-closure-status-check.sh";
  }
  g_checker = envc;
  U8 *envs;
  I8 *envs_raw = getenv("FACTORY_CLOSURE_STATUS_CASES");
  if (envs_raw != NULL && envs_raw[0] != 0) {
    U8 *p = envs_raw;
    envs = p;
  } else {
    envs = "./scripts/quality/factory-closure-status-test-cases.tsv";
  }
  g_cases = envs;
  g_pid = getpid();

  // Compute the per-PID capture path.
  U8 *cap = NULL;
  I64 capcap = 0, caplen = 0;
  cap = AppendStr(cap, &capcap, &caplen, "/tmp/fcst-capture-");
  I64 n = g_pid;
  U8 digits[32];
  I64 dn = 0;
  if (n == 0) { digits[0] = '0'; dn = 1; }
  while (n > 0) { digits[dn] = '0' + (n % 10); n = n / 10; dn = dn + 1; }
  while (dn > 0) { dn = dn - 1; cap = AppendChar(cap, &capcap, &caplen, digits[dn]); }
  g_capture_path = cap;

  "factory-closure-status-test (PolyC): checker=%s cases=%s\n",
    g_checker, g_cases;

  // Read the TSV fixture.
  I64 sz = 0;
  U8 *buf = FileRead(g_cases, &sz);
  if (buf == NULL) {
    "factory-closure-status-test: cannot read fixture %s\n", g_cases;
    return 2;
  }

  I64 idx = 0;
  I64 pass = 0;
  I64 fail = 0;

  // Iterate the TSV fixture line by line.
  while (idx < sz) {
    I64 llen = 0;
    U8 *line = NextLine(buf, sz, &idx, &llen);
    if (line == NULL) break;
    if (llen == 0) continue;

    // Skip comment lines starting with '#'.
    if (line[0] == '#') continue;

    // Skip the header row by detecting the literal "case_id\t" prefix.
    if (llen >= 8 &&
        line[0] == 'c' && line[1] == 'a' && line[2] == 's' &&
        line[3] == 'e' && line[4] == '_' && line[5] == 'i' &&
        line[6] == 'd' && line[7] == '\t') {
      continue;
    }

    // Parse: case_id \t expected_rc \t expected_sub \t manifest
    // The manifest may contain embedded newlines and tabs (the
    // TSV record is single-line, but the manifest content is
    // passed verbatim to FileWrite).

    // Token 1: case_id.
    I64 i = 0;
    while (i < llen && line[i] != '\t') i = i + 1;
    if (i >= llen) continue;
    U8 *cid = StrNDup(line, i);

    // Token 2: expected_rc.
    I64 j = i + 1;
    I64 k = j;
    while (k < llen && line[k] != '\t') k = k + 1;
    if (k >= llen) { Free(cid); continue; }
    U8 *erc = StrNDup(line + j, k - j);
    I64 erc_val = 0;
    I64 ii = 0;
    while (erc[ii] >= '0' && erc[ii] <= '9') {
      erc_val = erc_val * 10 + (erc[ii] - '0');
      ii = ii + 1;
    }
    Free(erc);

    // Token 3: expected_sub.
    j = k + 1;
    k = j;
    while (k < llen && line[k] != '\t') k = k + 1;
    if (k >= llen) { Free(cid); continue; }
    U8 *esub = StrNDup(line + j, k - j);
    StripCR(esub);

    // Token 4: manifest content (rest of line).
    j = k + 1;
    U8 *mc = StrNDup(line + j, llen - j);
    I64 mlen = llen - j;
    // Strip a trailing \r if present.
    while (mlen > 0 && mc[mlen - 1] == '\r') {
      mc[mlen - 1] = 0;
      mlen = mlen - 1;
    }

    RunCase(cid, erc_val, esub, mc, mlen, &pass, &fail);

    Free(cid);
    Free(esub);
    Free(mc);
  }

  Free(buf);

  // Clean up.
  Free(g_capture_path);

  "FACTORY_CLOSURE_STATUS_TEST_PASS=%d\n", pass;
  "FACTORY_CLOSURE_STATUS_TEST_FAIL=%d\n", fail;
  if (fail != 0) return 1;
  return 0;
}
