// tools/quality/lexer07-mutation-corrupt.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05 C2 IMPL.
// AC06 mutation test: corrupts one byte in a TEMPORARY
// COPY of a stage0-historical fallback .o file.
// The expected SHA is taken from the compiled-in
// immutable baseline (HISTORICAL_BASELINE[] inside
// lexer07-proof-verify.HC); the corruption changes the
// runtime SHA, and the verifier must reject.
//
// The canonical historical object in build/b02-corpus-A/
// is NEVER mutated. This binary operates only on a
// /tmp/ copy.
//
// Usage:
//   build/lexer07-mutation-corrupt <idx> <stem>
//   (e.g. 0_all, 5_date, etc.)
// writes <tmp_dir>/<idx>_<stem>.corrupt.o with one
// byte flipped.

#include "../../src/holyc-lib/memory_defs.HH"

I32 Main(I32 argc, U8 **argv)
{
  if (argc < 3) {
    "MUTATION_CORRUPT usage: %s <idx> <stem>\n", argv[0];
    return 1;
  }
  U8 *idx = argv[1];
  U8 *stem = argv[2];

  U8 *src_path = StrPrint(NULL, "build/b02-corpus-A/%s_%s.o", idx, stem);
  I64 src_size = 0;
  U8 *src = FileRead(src_path, &src_size);
  if (src == NULL) {
    "MUTATION_CORRUPT cannot-read src=%s\n", src_path;
    return 2;
  }

  // Flip one byte in the middle of the file (offset
  // src_size / 2). The corrupted copy is written to
  // /tmp.
  I64 mid = src_size / 2;
  src[mid] = src[mid] ^ 0x01;

  U8 *dst_path = StrPrint(NULL, "/tmp/lexer07-mut-%s_%s.o", idx, stem);
  if (!FileWrite(dst_path, src, src_size, 0x0202)) {
    "MUTATION_CORRUPT cannot-write dst=%s\n", dst_path;
    return 3;
  }
  "MUTATION_CORRUPT ok dst=%s size=%d flipped_byte_offset=%d\n",
    dst_path, src_size, mid;
  return 0;
}
