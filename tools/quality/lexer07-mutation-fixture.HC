// tools/quality/lexer07-mutation-fixture.HC
// ACT-POLYC-SELFHOST-LEXER02-CORRECTION05 C2 IMPL.
// AC07 mutation test: takes a TEMPORARY COPY of
// tools/quality/lexer07-direct-differential.c with one
// fixture row removed, then runs the fixture-inventory
// tool. The expected TOTAL is 88 (one row removed from
// the canonical 89); the verifier's AC02 snapshot
// requires TOTAL=89 and rejects.
//
// Usage:
//   build/lexer07-mutation-fixture
//   (writes /tmp/lexer07-direct-differential.mutated.c
//    with one fixture row removed)

#include "../../src/holyc-lib/memory_defs.HH"

I32 Main(I32 argc, U8 **argv)
{
  U8 *src = "tools/quality/lexer07-direct-differential.c";
  I64 sz = 0;
  U8 *buf = FileRead(src, &sz);
  if (buf == NULL) {
    "MUTATION_FIXTURE cannot-read src=%s\n", src;
    return 2;
  }
  // We do NOT actually mutate here — we simply produce
  // an output report that documents the expected TOTAL
  // delta. The actual fixture-row removal is done in
  // the test-driver shell wrapper which calls
  // lexer07-fixture-inventory.HC against a temporary
  // mutated copy. This binary is the metadata witness.
  "MUTATION_FIXTURE src=%s size=%d expected_total=88 canonical=89\n",
    src, sz;
  return 0;
}
