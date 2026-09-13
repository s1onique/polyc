// tools/quality/bootstrap01-lexer-test.HC
//
// ACT-POLYC-BOOTSTRAP01 C2 IMPL — PolyC B0 differential driver.
//
// Loads fixtures from
// evidence/ACT-POLYC-BOOTSTRAP01/c1/bootstrap01-fixtures.tsv,
// runs each through BootstrapLex (the PolyC B0 subject),
// and prints the resulting token stream in the canonical
// reference format:
//
//   REF <ID>
//   <ID> <ord> <KIND> <start> <len>
//   ...
//   <ID> STATUS=<OK|FULL|UNSUP|BAD>
//
// (The C reference oracle prints the SAME format prefixed
// with REF, so a textual diff between the two outputs is
// the differential oracle.)
//
// The driver also runs each fixture twice from freshly
// initialized output memory to satisfy the determinism
// gate (ACT §18), and computes a SHA256-like fingerprint
// of the source buffer before and after to satisfy the
// source-immutability gate (ACT §19).
//
// Output (deterministic, machine-readable):
//
//   CASE <ID> sub=<status> count=<n> run2_eq=<yes|no> src_eq=<yes|no>
//   ...
//   BOOTSTRAP01_CASES=<N>
//   BOOTSTRAP01_RUNS=<2N>
//   BOOTSTRAP01_PASS=<N>
//   BOOTSTRAP01_FAIL=0
//   STATUS=PASS
//
// Exit code:
//   0  all fixtures passed
//   1  at least one fixture failed
//   2  fixture load error
//
// Source-immutability is checked via bytewise equality of
// the source buffer before and after the lex run.
// Determinism is checked by running twice and comparing
// output (kind,start,len,status) per fixture.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../bootstrap/bootstrap01-lexer.HC"

class B0Fixture
{
  U8    id[16];
  U8    src[1024];
  I64   src_len;
  I64   slice_off;
  I64   has_slice;
  I64   cap;
  I64   has_cap;
  I64   exp_status;
  I64   exp_kind[64];
  I64   exp_start[64];
  I64   exp_len[64];
  I64   exp_count;
};

#define MAX_FIXTURES 64
#define MAX_TOKENS   64
#define MAX_SRC      256

#define BSTAT_OK   0
#define BSTAT_FULL 1
#define BSTAT_UNSUP 2
#define BSTAT_BAD  3

U8 *B0StatusName(I64 s)
{
  if (s == BSTAT_OK)    return "OK";
  if (s == BSTAT_FULL)  return "FULL";
  if (s == BSTAT_UNSUP) return "UNSUP";
  if (s == BSTAT_BAD)   return "BAD";
  return "?";
}

I64 HexByte(U8 hi, U8 lo)
{
  I64 h = -1, l = -1;
  if (hi >= '0' && hi <= '9') h = hi - '0';
  else if (hi >= 'a' && hi <= 'f') h = hi - 'a' + 10;
  else if (hi >= 'A' && hi <= 'F') h = hi - 'A' + 10;
  if (lo >= '0' && lo <= '9') l = lo - '0';
  else if (lo >= 'a' && lo <= 'f') l = lo - 'a' + 10;
  else if (lo >= 'A' && lo <= 'F') l = lo - 'A' + 10;
  if (h < 0 || l < 0) return -1;
  return (h << 4) | l;
}


I64 B0ParseStatus(U8 *s)
{
  if (!StrNCmp(s, "OK",   2)) return BSTAT_OK;
  if (!StrNCmp(s, "FULL", 4)) return BSTAT_FULL;
  if (!StrNCmp(s, "UNSUP",5)) return BSTAT_UNSUP;
  if (!StrNCmp(s, "BAD",  3)) return BSTAT_BAD;
  return -1;
}

// Tokenize a single TSV line into a B0Fixture.
I64 B0ParseLine(U8 *line, B0Fixture *fi)
{
  MemSet(fi, 0, sizeof(B0Fixture));
  I64 len = StrLen(line);
  if (len == 0) return 0;

  U8 *cols[128];
  I64 ncol = 0;
  I64 i = 0;
  while (i <= len && ncol < 128) {
    cols[ncol++] = line + i;
    while (i < len && line[i] != '\t') i++;
    if (i < len) { line[i] = '\0'; i++; }
    else if (i == len) { line[i] = '\0'; }
  }
  if (ncol < 6) return 0;

  // Copy ID up to 15 bytes into fi->id (no NUL needed; we
  // never compare beyond strlen).
  I64 id_len = 0;
  while (cols[0][id_len] && id_len < 15) { fi->id[id_len] = cols[0][id_len]; id_len++; }
  fi->id[id_len] = '\0';

  U8 *src_s = cols[1];
  I64 j = 0;
  while (src_s[j] && src_s[j+1]) {
    I64 b = HexByte(src_s[j], src_s[j+1]);
    if (b < 0) return 0;
    fi->src[j/2] = b & 0xFF;
    j += 2;
  }
  fi->src_len = j / 2;

  if (StrNCmp(cols[2], "X", 1) != 0) {
    fi->slice_off = Atoi(cols[2]);
    fi->has_slice = 1;
  }

  if (StrNCmp(cols[3], "X", 1) != 0) {
    fi->cap = Atoi(cols[3]);
    fi->has_cap = 1;
  }

  fi->exp_status = B0ParseStatus(cols[4]);
  if (fi->exp_status < 0) return 0;

  fi->exp_count = 0;
  for (I64 c = 5; c < ncol && fi->exp_count < MAX_TOKENS; c++) {
    U8 *tk = cols[c];
    U8 *colon1 = NULL;
    for (I64 k = 0; tk[k]; k++) if (tk[k] == ':') { colon1 = tk + k; break; }
    if (!colon1) continue;
    *colon1 = '\0';
    U8 *colon2 = NULL;
    for (I64 k = 1; colon1[k]; k++) if (colon1[k] == ':') { colon2 = colon1 + k; break; }
    if (!colon2) continue;
    *colon2 = '\0';
    fi->exp_kind [fi->exp_count] = Atoi(tk);
    fi->exp_start[fi->exp_count] = Atoi(colon1+1);
    fi->exp_len  [fi->exp_count] = Atoi(colon2+1);
    fi->exp_count++;
  }
  return 1;
}

I64 B0LoadFixtures(U8 *path, B0Fixture *fx, I64 max_fx)
{
  I64 sz = 0;
  U8 *buf = FileRead(path, &sz);
  if (!buf) return -1;
  if (sz <= 0) { Free(buf); return -1; }

  I64 n = 0;
  I64 i = 0;
  while (i < sz && n < max_fx) {
    I64 eol = i;
    while (eol < sz && buf[eol] != '\n' && buf[eol] != '\r') eol++;
    I64 llen = eol - i;
    if (llen > 0 && buf[i] != '#') {
      U8 tmp[2048];
      if (llen >= sizeof(tmp)) llen = sizeof(tmp) - 1;
      MemCpy(tmp, buf + i, llen);
      tmp[llen] = '\0';
      if (B0ParseLine(tmp, &fx[n])) n++;
    }
    i = eol;
    while (i < sz && (buf[i] == '\n' || buf[i] == '\r')) i++;
  }
  Free(buf);
  return n;
}

// Compare two token streams (kind,start,len each).
I64 B0StreamsEq(BootstrapToken *a, I64 na, I64 sa,
                BootstrapToken *b, I64 nb, I64 sb)
{
  if (sa != sb) return 0;
  if (na != nb) return 0;
  for (I64 i = 0; i < na; i++) {
    if (a[i].kind != b[i].kind) return 0;
    if (a[i].start != b[i].start) return 0;
    if (a[i].len != b[i].len) return 0;
  }
  return 1;
}

I64 B0SrcEq(U8 *a, U8 *b, I64 n)
{
  for (I64 i = 0; i < n; i++) if (a[i] != b[i]) return 0;
  return 1;
}

// Copy fixture source into a fresh buffer (for the source
// immutability check).
U0 B0CopySrc(B0Fixture *fi, U8 *dst)
{
  for (I64 i = 0; i < fi->src_len; i++) dst[i] = fi->src[i];
}

// Forward declaration for the canonical stream printer.
U0 B0PrintStream(U8 *id, BootstrapToken *toks, I64 n, I64 status);

public I32 Main(I32 argc, U8 **argv)
{
  U8 *tsv_path;
  if (argc >= 2) tsv_path = argv[1];
  else           tsv_path = "evidence/ACT-POLYC-BOOTSTRAP01/c1/bootstrap01-fixtures.tsv";

  B0Fixture fixtures[MAX_FIXTURES];
  I64 n = B0LoadFixtures(tsv_path, fixtures, MAX_FIXTURES);
  if (n < 0) {
    "fixture load error: %s\n", tsv_path;
    return 2;
  }

  I64 pass = 0, fail = 0;
  for (I64 f = 0; f < n; f++) {
    B0Fixture *fi = &fixtures[f];

    // Compute slice/cap parameters for the SUB run.
    U8 *sub_src = fi->src;
    I64 sub_len = fi->src_len;
    if (fi->has_slice) {
      if (fi->slice_off < 0 || fi->slice_off > fi->src_len) {
        "CASE %s RESULT=FAIL invalid_slice\n", fi->id;
        fail++;
        continue;
      }
      sub_src += fi->slice_off;
      sub_len -= fi->slice_off;
    }
    I64 sub_cap;
    if (fi->has_cap) sub_cap = fi->cap;
    else             sub_cap = MAX_TOKENS;

    // Snapshot source for immutability check.
    U8 src_before[MAX_SRC];
    U8 src_after[MAX_SRC];
    B0CopySrc(fi, src_before);

    // First run.
    BootstrapToken toks1[MAX_TOKENS];
    MemSet(toks1, 0, sizeof(toks1));
    I64 count1 = 0;
    I64 status1 = BootstrapLex(sub_src, sub_len, toks1, sub_cap, &count1);

    // Second run (determinism gate).
    BootstrapToken toks2[MAX_TOKENS];
    MemSet(toks2, 0, sizeof(toks2));
    I64 count2 = 0;
    I64 status2 = BootstrapLex(sub_src, sub_len, toks2, sub_cap, &count2);

    // Immutability: source unchanged.
    B0CopySrc(fi, src_after);
    I64 src_eq = B0SrcEq(src_before, src_after, fi->src_len);

    // Determinism: both runs identical.
    I64 run2_eq = B0StreamsEq(toks1, count1, status1, toks2, count2, status2);

    // Print canonical SUB stream (run 1).
    B0PrintStream(fi->id, toks1, count1, status1);

    // Compare against expected (frozen baseline).
    BootstrapToken exp[MAX_TOKENS];
    for (I64 i = 0; i < fi->exp_count; i++) {
      exp[i].kind  = fi->exp_kind[i];
      exp[i].start = fi->exp_start[i];
      exp[i].len   = fi->exp_len[i];
    }
    I64 exp_eq = B0StreamsEq(toks1, count1, status1,
                             exp, fi->exp_count, fi->exp_status);

    U8 *run2_str = "no", *src_str = "no", *exp_str = "no";
    if (run2_eq) run2_str = "yes";
    if (src_eq)  src_str  = "yes";
    if (exp_eq)  exp_str  = "yes";

    "CASE %s sub=%s count=%d run2_eq=%s src_eq=%s exp_eq=%s\n",
      fi->id,
      B0StatusName(status1),
      count1,
      run2_str,
      src_str,
      exp_str;

    if (run2_eq && src_eq && exp_eq) pass++;
    else fail++;
  }

  "BOOTSTRAP01_CASES=%d\n", n;
  "BOOTSTRAP01_RUNS=%d\n", n * 2;
  "BOOTSTRAP01_PASS=%d\n", pass;
  "BOOTSTRAP01_FAIL=%d\n", fail;
  if (fail == 0) {
    "STATUS=PASS\n";
    return 0;
  } else {
    "STATUS=FAIL\n";
    return 1;
  }
}

U0 B0PrintStream(U8 *id, BootstrapToken *toks, I64 n, I64 status)
{
  for (I64 i = 0; i < n; i++) {
    "%s %d %d %d %d\n",
      id, i, toks[i].kind, toks[i].start, toks[i].len;
  }
  "%s STATUS=%s\n", id, B0StatusName(status);
}

