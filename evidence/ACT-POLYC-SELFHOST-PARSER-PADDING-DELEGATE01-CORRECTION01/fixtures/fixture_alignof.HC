// evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01/fixtures/fixture_alignof.HC
//
// CORRECTION01 C1 -- regenerated production fixture (FIXTURE_ALIGNOF).
//
// PROVENANCE: the predecessor DELEGATE01 fixture contract named the
// ephemeral path /tmp/fixture_alignof.HC, which was never committed and
// did not survive the previous session. This file is the deterministic
// REGENERATION of that fixture.
//
// The class set and the expected sizeof/alignof values are pinned by two
// independent committed sources:
//   1. evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01/c1/
//      c1-production-fixture-contract.tsv  (observable description:
//      "sizeof+alignof values for 10 classes (Color, Rectangle, Mixed,
//      S2, S3, S5, Inner, Outer, Has8, OuterH)")
//   2. evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01/c3/
//      c3-n01-production-causal-control.txt  (exact output LINE FORMAT
//      and the pinned values, e.g. "Mixed=24 alignof=8",
//      "S3=8 alignof=4", "Has8=16 alignof=8", "OuterH=24 alignof=8")
//
// The class BODY DEFINITIONS are taken verbatim from the canonical
// committed parser-layout test src/tests/46_alignof.HC, which declares
// exactly these ten classes with identical member lists.
//
// Output format is the predecessor's canonical format recorded in
// evidence/.../DELEGATE01/c1/c1-production-output-schema.txt.
//
// This fixture exercises the CalcPadding production path at all five
// call-site classes via parseClassOffsets/parseUnionOffsets.

class Color     { U8 r; U8 g; U8 b; U8 a; };        /* size 4,  align 1 */
class Rectangle { F32 x; F32 y; F32 w; F32 h; };    /* size 16, align 4 */
class Mixed     { I8 a; I64 b; I8 c; };             /* size 24, align 8 */
class S2        { I16 x; I16 y; };                  /* size 4,  align 2 */
class S3        { I8 a; I32 b; };                   /* size 8,  align 4 */
class S5        { I8 a; I8 b; I8 c; };              /* size 3,  align 1 */
class Inner     { U8 a; U8 b; U8 c; U8 d; };        /* size 4,  align 1 */
class Outer     { U8 x; Inner i; };                /* size 5,  align 1 */
class Has8      { U8 x; I64 y; };                   /* size 16, align 8 */
class OuterH    { U8 x; Has8 h; };                 /* size 24, align 8 */

I32 Main()
{
  "FIXTURE_ALIGNOF\n";
  "Color=%d alignof=%d\n", sizeof(Color), alignof(Color);
  "Rectangle=%d alignof=%d\n", sizeof(Rectangle), alignof(Rectangle);
  "Mixed=%d alignof=%d\n", sizeof(Mixed), alignof(Mixed);
  "S2=%d alignof=%d\n", sizeof(S2), alignof(S2);
  "S3=%d alignof=%d\n", sizeof(S3), alignof(S3);
  "S5=%d alignof=%d\n", sizeof(S5), alignof(S5);
  "Inner=%d alignof=%d\n", sizeof(Inner), alignof(Inner);
  "Outer=%d alignof=%d\n", sizeof(Outer), alignof(Outer);
  "Has8=%d alignof=%d\n", sizeof(Has8), alignof(Has8);
  "OuterH=%d alignof=%d\n", sizeof(OuterH), alignof(OuterH);
  return 0;
}
