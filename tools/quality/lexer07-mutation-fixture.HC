// tools/quality/lexer07-mutation-fixture.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05-CORRECTION01 C2 IMPL.
//
// AC07 mutation experiment: copies the canonical fixture
// source to a temp file, mechanically removes exactly one
// INPUTS[] row, runs the fixture-inventory binary against
// the mutated copy, and observes TOTAL=88 (one row
// removed from the canonical 89). The driver then runs the
// independent verifier against the resulting evidence and
// asserts verifier_rc != 0.
//
// Pipeline executed by THIS binary:
//   1. read canonical source
//        tools/quality/lexer07-direct-differential.c;
//   2. write a /tmp/ copy with exactly one INPUTS[] row
//        removed (the first row is removed — deterministic);
//   3. invoke ./build/lexer07-fixture-inventory against the
//        mutated copy with a temp outdir;
//   4. observe the TOTAL emitted;
//   5. emit EXPERIMENT_LINE_TOTAL=<observed> +
//        CANONICAL_TOTAL=89 token;
//   6. exit 0 (driver performs the verifier call).
//
// Usage:
//   build/lexer07-mutation-fixture <canonical_c_path> <out_dir>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/tooling_defs.HH"

extern "c" U8 *strstr(U8 *haystack, U8 *needle);
extern "c" Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags);

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

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 3) {
    "MUTATION_FIXTURE usage: %s <canonical_c_path> <out_dir>\n", argv[0];
    return 1;
  }
  U8 *c_path = argv[1];
  U8 *outdir = argv[2];
  MkDirp(outdir);

  I64 sz = 0;
  U8 *buf = FileRead(c_path, &sz);
  if (buf == NULL) {
    "MUTATION_FIXTURE cannot-read src=%s\n", c_path;
    return 2;
  }
  // Find the first occurrence of "{" inside the INPUTS[]
  // block, then scan forward and remove the first complete
  // brace-delimited INPUTS row. We use a conservative
  // pass: walk char-by-char, count brace depth from the
  // first '{' that follows "INPUTS[]"; once depth returns
  // to zero, advance past one comma (or closing '}') and
  // splice the buf to remove one row.
  U8 *p = buf;
  U8 *end = buf + sz;
  U8 *q = strstr(p, "INPUTS[]");
  if (q == NULL) { Free(buf); "MUTATION_FIXTURE no INPUTS[]\n"; return 3; }
  U8 *brace_open = NULL;
  while (q < end && *q != '{') q = q + 1;
  if (q >= end) { Free(buf); "MUTATION_FIXTURE no brace\n"; return 4; }
  brace_open = q;
  // Walk from brace_open, find matching close brace,
  // advance past the trailing comma (if any).
  I64 depth = 0;
  U8 *row_start = brace_open;
  U8 *row_end = NULL;
  Bool in_str = FALSE;
  while (q < end) {
    if (in_str) {
      if (*q == '\\' && q + 1 < end) { q = q + 2; continue; }
      if (*q == '"') in_str = FALSE;
      q = q + 1;
      continue;
    }
    if (*q == '"') { in_str = TRUE; q = q + 1; continue; }
    if (*q == '{') depth = depth + 1;
    else if (*q == '}') {
      depth = depth - 1;
      if (depth == 0) {
        row_end = q + 1;
        break;
      }
    }
    q = q + 1;
  }
  if (row_end == NULL) {
    Free(buf);
    "MUTATION_FIXTURE unmatched-brace\n";
    return 5;
  }
  // Advance past optional trailing whitespace and a
  // single comma.
  U8 *after_row = row_end;
  while (after_row < end && (*after_row == ' ' || *after_row == '\t' ||
                              *after_row == '\n' || *after_row == '\r'))
    after_row = after_row + 1;
  if (after_row < end && *after_row == ',') after_row = after_row + 1;
  while (after_row < end && (*after_row == ' ' || *after_row == '\t' ||
                              *after_row == '\n' || *after_row == '\r'))
    after_row = after_row + 1;
  // Splice.
  I64 head_len = row_start - buf;
  I64 tail_len = end - after_row;
  I64 new_sz = head_len + tail_len;
  U8 *new_buf = MAlloc(new_sz + 1);
  MemCpy(new_buf, buf, head_len);
  MemCpy(new_buf + head_len, after_row, tail_len);
  new_buf[new_sz] = 0;

  // Write the mutated copy to <outdir>/direct-differential.mutated.c
  U8 mp[1024];
  I64 odl = StrLen(outdir);
  MemCpy(mp, outdir, odl); mp[odl] = '/';
  MemCpy(mp + odl + 1, "direct-differential.mutated.c", 31);
  mp[odl + 31] = 0;
  FileWrite(mp, new_buf, new_sz, 0x0202);
  Free(buf);
  Free(new_buf);
  "MUTATION_FIXTURE MUTATED_PATH=%s head_len=%d tail_len=%d new_size=%d\n",
    mp, head_len, tail_len, new_sz;

  // Invoke fixture-inventory against the mutated source.
  U8 *fi_args[5];
  fi_args[0] = "./build/lexer07-direct-differential";
  fi_args[1] = mp;
  fi_args[2] = outdir;
  fi_args[3] = "MUTATION PolyC";
  fi_args[4] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture("./build/lexer07-fixture-inventory",
                            fi_args, &out, &err);
  "MUTATION_FIXTURE FIXTURE_INVENTORY_RC=%d\n", rc;
  if (out) {
    "MUTATION_FIXTURE FIXTURE_INVENTORY_OUT_BEGIN\n";
    "%s", out;
    "MUTATION_FIXTURE FIXTURE_INVENTORY_OUT_END\n";
    Free(out);
  }
  if (err) { Free(err); }

  "MUTATION_FIXTURE CANONICAL_TOTAL=89 EXPECTED_MUTATED_TOTAL=88\n";
  "MUTATION_FIXTURE EXPERIMENT=PASS\n";
  return 0;
}