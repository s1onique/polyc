// evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01/fixtures/fixture_u0_tail.HC
//
// CORRECTION01 C1 -- regenerated production fixture (FIXTURE_U0_TAIL).
//
// PROVENANCE: the predecessor DELEGATE01 fixture contract named the
// ephemeral path /tmp/fixture_u0_tail.HC, which was never committed and
// did not survive the previous session. This file is the deterministic
// REGENERATION of that fixture.
//
// Values pinned by the predecessor's committed evidence:
//   evidence/.../DELEGATE01/c1/c1-production-fixture-contract.tsv:
//     "sizeof(Hdr)=8; sizeof(HdrMixed)=16; body offsets 8 and 9"
//   evidence/.../DELEGATE01/c3/c3-n01-production-causal-control.txt:
//     "< Hdr=8 HdrMixed=16"   (exact line format and values)
//
// Class definitions are taken from the canonical committed test
// src/tests/42_class_u0_tail.HC (Hdr with a trailing U0 body, and
// HdrMixed with I64 a; U8 b; U0 body).
//
// This fixture exercises the CalcPadding production path at the
// tail-aligned-empty and tail-aligned-class call-site classes.

class Hdr
{
  I64 size;
  U0  body;
};

class HdrMixed
{
  I64 a;
  U8  b;
  U0  body;
};

I32 Main()
{
  "FIXTURE_U0_TAIL\n";
  "Hdr=%d HdrMixed=%d\n", sizeof(Hdr), sizeof(HdrMixed);
  Hdr *h = MAlloc(64);
  HdrMixed *m = MAlloc(64);
  "HdrBodyOffset=%d HdrMixedBodyOffset=%d\n",
    &h->body - h(U8 *), &m->body - m(U8 *);
  Free(h);
  Free(m);
  return 0;
}
