// tools/quality/lexer07-fixture-inventory.HC
//
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION04 C2 IMPL.
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C2 IMPL:
//   - default outdir is now derived from argv[3] and
//     refuses to write into a closed evidence directory
//     unless explicitly opted in via --allow-closed path;
//   - summary header is parameterized via argv[4] (default
//     "CORRECTION05-CORRECTION01 PolyC"); this prevents
//     silent mislabeling of evidence.
// Substantive PolyC implementation. Owns the full CORRECTION02
// fixture-inventory contract.
//
// Pipeline:
//   1. Parse the static input_t INPUTS[] = { ... } block
//      from tools/quality/lexer07-direct-differential.c.
//      89 entries expected.
//   2. Spawn ./build/lexer07-direct-differential via
//      SpawnAndCapture (libtos subprocess primitive).
//   3. Parse stdout OK/FAIL lines, extract observed
//      kind/err/slen (left of "/" in the C binary's output).
//   4. Join inputs and observations by name. Compute
//      is_numeric/is_char/is_negative/is_edge from
//      OBSERVED values (this is the mechanical classifier
//      that CORRECTION02 introduced and CORRECTION03 erased).
//   5. Write fixture-inventory.tsv (89 rows + header) and
//      fixture-inventory-summary.txt (totals + floors).
//   6. Exit non-zero iff any floor is violated
//      (TOTAL<64 || is_char<24 || is_negative<16).
//
// F-POLYC-TOOLS: this PolyC file replaces a 165-LOC shell
// tool. The matching shell wrapper is the <=50 LOC dispatcher.
//
// Declaration-only headers (memory_defs.HH, tooling_defs.HH,
// io_defs.HH) so this TU does NOT pull in libtos bodies.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

extern "c" U8 *strstr(U8 *haystack, U8 *needle);

#define MAX_INPUTS 256

U0 SkipWs(U8 **pp) { while (**pp == ' ' || **pp == '\t') *pp = *pp + 1; }

U8 *ParseCString(U8 **pp)
{
  if (**pp != '"') return StrNew("");
  *pp = *pp + 1;
  I64 cap = 32;
  I64 len = 0;
  U8 *out = MAlloc(cap);
  while (**pp != 0 && **pp != '"') {
    if (**pp == '\\') {
      *pp = *pp + 1;
      U8 c;
      if (**pp == 'n') c = '\n'; else if (**pp == 't') c = '\t';
      else if (**pp == '\\') c = '\\'; else if (**pp == '"') c = '"';
      else c = **pp;
      if (len + 1 >= cap) { cap = cap * 2; out = ReAlloc(out, cap); }
      out[len] = c;
      len = len + 1;
      *pp = *pp + 1;
    } else {
      if (len + 1 >= cap) { cap = cap * 2; out = ReAlloc(out, cap); }
      out[len] = **pp;
      len = len + 1;
      *pp = *pp + 1;
    }
  }
  if (**pp == '"') *pp = *pp + 1;
  out[len] = 0;
  return out;
}

I64 ParseInputsTable(U8 *cpath, U8 *names[], U8 *srcs[],
                     I64 *cursors, I64 *flags, I64 *src_lens)
{
  I64 size = 0;
  U8 *contents = FileRead(cpath, &size);
  if (contents == NULL) return 0;
  U8 *end = contents + size;
  I64 n = 0;
  U8 *p = contents;
  U8 *q = strstr(p, "INPUTS[]");
  if (q == NULL) { Free(contents); return 0; }
  U8 *brace = StrFirstOcc(q, "{");
  if (brace == NULL) { Free(contents); return 0; }
  p = brace + 1;
  while (p < end) {
    SkipWs(&p);
    if (p >= end || *p == '}') break;
    if (*p != '{') {
      p = p + 1;
      continue;
    }
    p = p + 1;
    SkipWs(&p);
    if (*p != '"') {
      while (p < end && *p != '}') p = p + 1;
      if (p < end && *p == '}') p = p + 1;
      continue;
    }
    U8 *name = ParseCString(&p);
    SkipWs(&p);
    if (*p == ',') p = p + 1;
    SkipWs(&p);
    U8 *src = NULL;
    if (*p == '"') src = ParseCString(&p);
    else src = StrNew("");
    SkipWs(&p);
    I64 cursor = 0, fl = 0;
    Bool gc = FALSE, gf = FALSE;
    while (p < end && *p != '}' && *p != '\n') {
      if (*p == '-') {
        if (gc == FALSE) {
          p = p + 1;
          I64 v = 0;
          while (p < end && *p >= '0' && *p <= '9') {
            v = v * 10 + (*p - '0');
            p = p + 1;
          }
          cursor = -v;
          gc = TRUE;
        } else {
          p = p + 1;
        }
      } else if (*p >= '0' && *p <= '9') {
        I64 v = 0;
        while (*p >= '0' && *p <= '9') {
          v = v * 10 + (*p - '0');
          p = p + 1;
        }
        if (gc == FALSE) { cursor = v; gc = TRUE; }
        else if (gf == FALSE) { fl = v; gf = TRUE; }
      } else {
        p = p + 1;
      }
    }
    if (n < MAX_INPUTS) {
      names[n] = name; srcs[n] = src; cursors[n] = cursor;
      flags[n] = fl; src_lens[n] = StrLen(src); n = n + 1;
    }
    // Now p is at the entry's closing '}' or after the last digit.
    // Advance past the closing '}' and any trailing whitespace/comma.
    while (p < end && *p != '}') p = p + 1;
    if (p < end && *p == '}') p = p + 1;
    while (p < end && (*p == ' ' || *p == '\t' || *p == '\n' || *p == ',')) {
      p = p + 1;
    }
  }
  Free(contents);
  return n;
}

// MkDirpRecursive: mkdir -p equivalent. libtos exports
// MkDir and MkDirIfNotExist (single-level) but not
// MkDirpRecursive. Implement here in PolyC.
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

// EscapeTsvCell: escape CR/LF/tab/backslash in fixture TSV
// cell so no physical line break can corrupt the row
// (this closes P1-5: the hex_0xff_no_semi row of the
// CORRECTION04 fixture-inventory.tsv was split across
// two physical lines by an embedded newline).
U0 EscapeTsvCell(U8 *src, U8 *dst)
{
  I64 i = 0;
  I64 j = 0;
  while (src[i] != 0) {
    U8 c = src[i];
    if (c == '\\') {
      dst[j] = '\\'; dst[j+1] = '\\'; j = j + 2;
    } else if (c == '\t') {
      dst[j] = '\\'; dst[j+1] = 't'; j = j + 2;
    } else if (c == '\n') {
      dst[j] = '\\'; dst[j+1] = 'n'; j = j + 2;
    } else if (c == '\r') {
      dst[j] = '\\'; dst[j+1] = 'r'; j = j + 2;
    } else {
      dst[j] = c; j = j + 1;
    }
    i = i + 1;
  }
  dst[j] = 0;
}

// ParseLeadingInt: read leading digits at *pp; advance *pp.
I64 ParseLeadingInt(U8 **pp)
{
  I64 v = 0;
  while (**pp >= '0' && **pp <= '9') {
    v = v * 10 + (**pp - '0');
    *pp = *pp + 1;
  }
  return v;
}

// Find the integer left of "/" in "kind=<n>/<rest>".
I64 ExtractKind(U8 *line)
{
  U8 *p = strstr(line, "kind=");
  if (p == NULL) return 0;
  p = p + 5;
  return ParseLeadingInt(&p);
}

// Find the integer left of "/" in "err=<n>/<rest>".
I64 ExtractErr(U8 *line)
{
  U8 *p = strstr(line, "err=");
  if (p == NULL) return 0;
  p = p + 4;
  return ParseLeadingInt(&p);
}

// Find the integer left of "/" in "slen=<n>/<rest>".
I64 ExtractSlen(U8 *line)
{
  U8 *p = strstr(line, "slen=");
  if (p == NULL) return 0;
  p = p + 5;
  return ParseLeadingInt(&p);
}

// ParseDifferentialOutput: walk stdout lines; for each
// OK/FAIL line, find the matching input by name and fill
// observed_*. Returns number of OK/FAIL lines matched.
I64 ParseDifferentialOutput(U8 *out_buf, U8 *names[], I64 n_names,
                            I64 *obs_kind, I64 *obs_err,
                            I64 *obs_slen, I64 *obs_seen)
{
  for (I64 i = 0; i < n_names; i = i + 1) {
    obs_seen[i] = 0;
    obs_kind[i] = 0;
    obs_err[i] = 0;
    obs_slen[i] = 0;
  }
  if (out_buf == NULL) return 0;
  I64 parsed = 0;
  U8 *p = out_buf;
  while (*p != 0) {
    U8 *eol = p;
    while (*eol != 0 && *eol != '\n') eol = eol + 1;
    I64 llen = eol - p;
    if (llen >= 3) {
      Bool is_ok = (p[0] == 'O' && p[1] == 'K' && p[2] == ' ');
      Bool is_fail = (llen >= 5 && p[0] == 'F' && p[1] == 'A' &&
                       p[2] == 'I' && p[3] == 'L' && p[4] == ' ');
      if (is_ok || is_fail) {
        U8 *name_start;
        if (is_ok) name_start = p + 3;
        else name_start = p + 5;
        while (*name_start == ' ' || *name_start == '\t') {
          name_start = name_start + 1;
        }
        U8 *name_end = name_start;
        while (*name_end != 0 && *name_end != ' ' &&
               *name_end != '\t' && *name_end != '\n') {
          name_end = name_end + 1;
        }
        I64 nlen = name_end - name_start;
        for (I64 i = 0; i < n_names; i = i + 1) {
          if (StrLen(names[i]) == nlen &&
              StrNCmp(names[i], name_start, nlen) == 0) {
            obs_kind[i] = ExtractKind(p);
            obs_err[i] = ExtractErr(p);
            obs_slen[i] = ExtractSlen(p);
            obs_seen[i] = 1;
            parsed = parsed + 1;
            break;
          }
        }
      }
    }
    if (*eol == '\n') p = eol + 1;
    else p = eol;
  }
  return parsed;
}

I32 Main(I32 argc, U8 **argv)
{
  U8 *bin_path = "./build/lexer07-direct-differential";
  U8 *c_path = "tools/quality/lexer07-direct-differential.c";
  U8 *outdir = "./build/lexer07-fixture-inventory-out";
  U8 *header_label = "CORRECTION05-CORRECTION01 PolyC";
  I64 i = 1;
  Bool allow_closed = FALSE;
  // Optional leading flags.
  while (i < argc && argv[i][0] == '-' && argv[i][1] == '-') {
    if (StrNCmp(argv[i], "--allow-closed", 14) == 0) {
      allow_closed = TRUE;
      i = i + 1;
      continue;
    }
    break;
  }
  if (argc > i)     bin_path = argv[i];
  if (argc > i + 1) c_path = argv[i + 1];
  if (argc > i + 2) outdir = argv[i + 2];
  if (argc > i + 3) header_label = argv[i + 3];
  // Refuse to write into a closed evidence directory unless
  // --allow-closed is explicitly set. The substring check
  // covers every closed CORRECTION0X/c* path.
  if (!allow_closed) {
    if (strstr(outdir, "/CORRECTION02/c") != NULL ||
        strstr(outdir, "/CORRECTION03/c") != NULL ||
        strstr(outdir, "/CORRECTION04/c") != NULL ||
        strstr(outdir, "/CORRECTION05/c") != NULL) {
      "FIXTURE_INVENTORY_STATUS=ERROR reason=closed-evidence-dir outdir=%s\n", outdir;
      "FIXTURE_INVENTORY_HINT=pass --allow-closed to override\n";
      return 4;
    }
  }
  MkDirpRecursive(outdir);

  U8 *names[MAX_INPUTS]; U8 *srcs[MAX_INPUTS];
  I64 cursors[MAX_INPUTS]; I64 flags[MAX_INPUTS]; I64 src_lens[MAX_INPUTS];
  I64 n = ParseInputsTable(c_path, names, srcs,
                            cursors, flags, src_lens);
  if (n == 0) {
    "FIXTURE_INVENTORY_STATUS=ERROR reason=empty-inputs-table\n";
    return 2;
  }

  U8 *args[2];
  args[0] = bin_path;
  args[1] = NULL;
  U8 *out_buf = NULL;
  U8 *err_buf = NULL;
  I64 rc = SpawnAndCapture(bin_path, args, &out_buf, &err_buf);
  if (rc != 0) {
    "FIXTURE_INVENTORY_STATUS=ERROR reason=differential-rc=%d\n", rc;
    if (err_buf) "%s", err_buf;
    return 3;
  }
  if (err_buf) { Free(err_buf); err_buf = NULL; }

  I64 obs_kind[MAX_INPUTS]; I64 obs_err[MAX_INPUTS];
  I64 obs_slen[MAX_INPUTS]; I64 obs_seen[MAX_INPUTS];
  I64 n_obs = ParseDifferentialOutput(out_buf, names, n,
                                      obs_kind, obs_err,
                                      obs_slen, obs_seen);
  Free(out_buf);

  I64 n_num = 0, n_chr = 0, n_neg = 0, n_edge = 0;
  U8 tsv_path[512];
  I64 outdir_len = StrLen(outdir);
  MemCpy(tsv_path, outdir, outdir_len);
  tsv_path[outdir_len] = '/';
  MemCpy(tsv_path + outdir_len + 1, "fixture-inventory.tsv", 21);
  tsv_path[outdir_len + 22] = 0;
  U8 *tsv = StrPrint(NULL,
    "name\tsrc\tcursor\tflags\tobserved_kind\tobserved_err\tobserved_strlen\tsrc_len\tis_numeric\tis_char\tis_negative\tis_edge\n");
  for (I64 i = 0; i < n; i = i + 1) {
    I64 k, e, s, is_num, is_chr, is_neg, is_edg;
    if (obs_seen[i] != 0) { k = obs_kind[i]; } else { k = 0; }
    if (obs_seen[i] != 0) { e = obs_err[i]; } else { e = 0; }
    if (obs_seen[i] != 0) { s = obs_slen[i]; } else { s = 0; }
    if (k == 1 || k == 2) { is_num = 1; } else { is_num = 0; }
    if (k == 3) { is_chr = 1; } else { is_chr = 0; }
    if (e != 0) { is_neg = 1; } else { is_neg = 0; }
    if (cursors[i] < 0) { is_edg = 1; }
    else { is_edg = 0; }
    if (src_lens[i] >= 0) {
      if (cursors[i] >= src_lens[i]) { is_edg = 1; }
    }
    if (is_num != 0) n_num = n_num + 1;
    if (is_chr != 0) n_chr = n_chr + 1;
    if (is_neg != 0) n_neg = n_neg + 1;
    if (is_edg != 0) n_edge = n_edge + 1;
    U8 clean[1024];
    EscapeTsvCell(srcs[i], clean);
    U8 *line = StrPrint(NULL,
      "%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",
      names[i], clean, cursors[i], flags[i],
      k, e, s, src_lens[i],
      is_num, is_chr, is_neg, is_edg);
    U8 *old = tsv;
    tsv = StrPrint(NULL, "%s%s", tsv, line);
    Free(old);
    Free(line);
  }
  FileWrite(tsv_path, tsv, StrLen(tsv), 0x0202);
  Free(tsv);

  I64 f_total, f_chr, f_neg, f_pass;
  if (n >= 64) { f_total = 1; } else { f_total = 0; }
  if (n_chr >= 24) { f_chr = 1; } else { f_chr = 0; }
  if (n_neg >= 16) { f_neg = 1; } else { f_neg = 0; }
  if (f_total != 0 && f_chr != 0 && f_neg != 0) { f_pass = 1; }
  else { f_pass = 0; }
  U8 sum_path[512];
  I64 outdir_len2 = StrLen(outdir);
  MemCpy(sum_path, outdir, outdir_len2);
  sum_path[outdir_len2] = '/';
  MemCpy(sum_path + outdir_len2 + 1, "fixture-inventory-summary.txt", 29);
  sum_path[outdir_len2 + 30] = 0;
  U8 *pass_str, *pass_str2;
  if (f_pass != 0) { pass_str = "PASS"; pass_str2 = "PASS"; }
  else { pass_str = "FAIL"; pass_str2 = "FAIL"; }
  U8 *sum = StrPrint(NULL,
    "FIXTURE INVENTORY SUMMARY (%s)\n"
    "TOTAL=%d\nis_numeric=%d\nis_char=%d\nis_negative=%d\nis_edge=%d\n"
    "OBSERVED=%d/%d\n"
    "FIXTURE_INVENTORY_FLOORS=%s\nSTATUS=%s\n",
    header_label, n, n_num, n_chr, n_neg, n_edge, n_obs, n,
    pass_str, pass_str2);
  FileWrite(sum_path, sum, StrLen(sum), 0x0202);
  Free(sum);

  "TOTAL=%d is_numeric=%d is_char=%d is_negative=%d is_edge=%d\n",
    n, n_num, n_chr, n_neg, n_edge;
  "FIXTURE_INVENTORY_FLOORS=%s\n", pass_str;
  "STATUS=%s\n", pass_str2;

  for (I64 i = 0; i < n; i = i + 1) {
    if (names[i]) Free(names[i]);
    if (srcs[i])  Free(srcs[i]);
  }
  if (f_pass != 0) return 0;
  return 1;
}
